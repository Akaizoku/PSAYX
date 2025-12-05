function Get-Drivers {
    <#
        .SYNOPSIS
        List Alteryx supported drivers.

        .DESCRIPTION
        Queries the Alteryx License Portal API to retrieve a list of supported drivers.

        .NOTES
        File name:      Get-Drivers.ps1
        Author:         Florian Carrier
        Creation date:  2025-07-07
        Last modified:  2025-11-05
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Alteryx Account ID"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("Account")]
        $AccountID,
        [Parameter (
            Position    = 2,
            Mandatory   = $true,
            HelpMessage = "Access token"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("AccessToken")]
        $Token,
        [Parameter (
            Position    = 3,
            Mandatory   = $false,
            HelpMessage = "Driver technology name"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("Driver", "Technology")]
        $Name,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Target download path"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("Folder", "Directory")]
        $Path,
        [Parameter (
            HelpMessage = "Switch to download the latest driver version"
        )]
        [Switch]
        $Download
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Log function call
        Write-Log -Type "DEBUG" -Message $MyInvocation.MyCommand.Name
        # Define parameters
        $Parameters = [Ordered]@{
            "productLineId" = "Drivers"
        }
    }
    Process {
        # Fetch list of drivers
        $Drivers = Invoke-AlteryxLicenseAPI -Token $Token -Endpoint "v1/products/-/releases" -AccountID $AccountID -Parameters $Parameters
        # Sort drivers by name
        $Drivers = ($Drivers | ConvertFrom-Json) | Sort-Object -Property "name"
        if ($PSBoundParameters.ContainsKey("Name")) {
            # Check if specified driver is available
            $Drivers = $Drivers | Where-Object -Property "id" -like -Value "*${Name}*"
            if ($null -eq $Drivers) {
                Write-Log -Type "ERROR" -Message "No drivers found matching '$Name'"
                return $null
            }
        }
        # If download switch is set, fetch latest driver release
        if ($Download) {
            # Response object
            $Response = New-Object -TypeName "System.Collections.Specialized.OrderedDictionary"
            # Exclude old driver versions
            $Drivers = $Drivers | Where-Object -Property "version" -notlike -Value "*Previous*"
            foreach ($Driver in $Drivers) {
                Write-Log -Type "NOTICE" -Message "Downloading latest version of driver $($Driver.name)"
                $Installers = Get-AlteryxProductEditions -AccountID $AccountID -Token $Token -ReleaseID $Driver.id
                Write-Log -Type "DEBUG" -Message "Number of files: $($Installers.Count)"
                foreach ($Installer in $Installers) {
                    $Package = @{
                        "Name"      = $Installer.description
                        "Driver"    = $Driver.name
                    }
                    Write-Log -Type "NOTICE" -Message "Downloading $($Package.Name)"
                    # Parse file name
                    try {
                        $URL        = $Installer.downloadLink
                        $FileName   = [System.Uri]::UnescapeDataString([System.IO.Path]::GetFileName(([System.Uri]$URL).AbsolutePath))
                        $Extension  = [System.IO.Path]::GetExtension(([System.Uri]$URL).AbsolutePath)
                        $Package.Add("FileName", $FileName)
                        # Check if file is an installer
                        if ($Extension -notin @(".exe", ".msi")) {
                            Write-Log -Type "WARN" -Message "File is not an installer: $FileName"
                        }
                        # Parse version number
                        if (($FileName -match '(\d+\.\d+(\.\d+)?(\.\d+)?(\.\d+)?).*?') -Or ($Installer.description -match '(\d+\.\d+(\.\d+)?(\.\d+)?(\.\d+)?)')) {
                            $ParsedVersion = $matches[1]
                            # Hotfix for messed up patch version formatting
                            if ($Patch) {
                                $PatchVersion = Select-String -InputObject $ParsedVersion -Pattern '(\d+\.\d+\.\d+)(?:\.\d+)(\.\d+)' -AllMatches
                                $Version = [System.String]::Concat($PatchVersion.Matches.Groups[1].Value, $PatchVersion.Matches.Groups[2].Value)
                            } else {
                                $Version = $ParsedVersion
                            }
                        } else {
                            Write-Log -Type "WARN" -Message "Could not identify version number for file: $FileName"
                            $Version = $null
                        }
                        $Package.Add("Version", $Version)
                        # Store direct download link and checksum
                        $Package.Add("URL", $URL)
                        $Package.Add("Checksum", $Installer.md5CheckSum)
                        # Download driver
                        $FilePath = $FileName
                        if ($PSBoundParameters.ContainsKey("Path") -and (Test-Path -Path $Path)) {
                            $FilePath = Join-Path -Path $Path -ChildPath $FileName
                        } elseif ($PSBoundParameters.ContainsKey("Path")) {
                            Write-Log -Type "WARN" -Message "Specified path does not exist. Downloading to current directory." 
                        }
                        Invoke-WebRequest -Uri $URL -OutFile $FilePath
                        # Verify checksum
                        $DownloadedChecksum = Get-FileHash -Path $FilePath -Algorithm MD5 | Select-Object -ExpandProperty Hash
                        Write-Log -Type "DEBUG" -Message "Expected Checksum:`t$($Package.Checksum)"
                        Write-Log -Type "DEBUG" -Message "Downloaded Checksum:`t$DownloadedChecksum"
                        if ($DownloadedChecksum -ieq $Package.Checksum) {
                            Write-Log -Type "CHECK" -Message "File downloaded successfully: $FileName"
                        } else {
                            Write-Log -Type "ERROR" -Message "An error occurred during the download of $FileName. Checksum does not match."
                        }
                        $Package.Add("FilePath", $FilePath)
                        $Package.Add("Status", "Downloaded")
                    }
                    catch {
                        # Delete corrupted file
                        Remove-Object -Path $FilePath -ErrorAction "SilentlyContinue"
                        # Report error
                        $Package.Add("Status", "Error")
                        Write-Log -Type "DEBUG" -Message $Package
                        Write-Log -Type "ERROR" -Message "Failed to download $($Package.Driver) driver $($Package.Name): $($PSItem.Exception.Message)"
                        
                    }
                }
                # Store package information
                Write-Log -Type "DEBUG" -Message $Package
                $Response.Add($Package.Name, $Package)
            }
            # Return list of downloaded drivers
            return $Response
        } else {
            # Return list of drivers
            return $Drivers
        }
    }
}