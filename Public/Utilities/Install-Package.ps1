function Install-Package {
    <#
        .SYNOPSIS
        Install Alteryx Package

        .DESCRIPTION
        Install an Alteryx package (.YXI)

        .NOTES
        File name:      Install-Package.psm1
        Author:         Florian Carrier
        Creation date:  2022-08-02
        Last modified:  2022-08-02

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/developer-help/package-tool
    #>
    [CmdletBinding (
        SupportsShouldProcess = $true
    )]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to the Alteryx package"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("Package")]
        [System.String]
        $Path,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Type of installation"
        )]
        [ValidateSet (
            "Admin",
            "User"
        )]
        [System.String]
        $Type = "Admin",
        [Parameter (
          HelpMessage = "Switch to delete the package installer"
        )]
        [Switch]
        $Delete,
        [Parameter (
          HelpMessage = "Switch to enable non-interactive mode"
        )]
        [Switch]
        $Unattended
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Check package
        if (Test-Object -Path $Path -NotFound) {
            Write-Log -Type "DEBUG" -Message $Path
            Write-Log -Type "ERROR" -Message "Path not found ""$Path""" -ExitCode 1
        } else {
            $Package = Get-Item -Path $Path
            if ($Package -is [System.IO.FileInfo]) {
                $Extension  = [System.IO.Path]::GetExtension($Package)
                if ($Extension -ne ".YXI") {
                    Write-Log -Type "ERROR" -Message $Path
                    Write-Log -Type "ERROR" -Message "Unsupported file extension ($Extension)" -ExitCode 1
                }
            } else {
                Write-Log -Type "DEBUG" -Message $Package
                Write-Log -Type "ERROR" -Message "Path provided is not an Alteryx package"
            }
        }
        # Define target directory
        if ($Type -eq "User") {
            $Destination = "$($env:APPDATA)\Alteryx\Tools"
        } else {
            $Destination = "$($env:ALLUSERSPROFILE)\Alteryx\Tools"
        }
        # Define staging location
        $Staging = "C:\tmp\test"#Get-EnvironmentVariable -Name "TEMP"
    }
    Process {
        Write-Log -Type "DEBUG" -Message $Package
        Write-Log -Type "CHECK" -Message "Installation of package $($Package.BaseName)"
        # Copy file
        Copy-Object -Path $Path -Destination $Staging -Force
        # Change extension
        $NewName = [System.String]::Concat($Package.BaseName,".zip")
        $ZIP = Join-Path -Path $Staging -ChildPath $NewName
        if (Test-Object -Path $ZIP) {
            Write-Log -Type "DEBUG" -Message "Deleting duplicate temporary ZIP package $ZIP"
            Remove-Item -Path $ZIP -Force
        }
        Rename-Item -Path (Join-Path -Path $Staging -ChildPath $Package.Name) -NewName $NewName -Force
        # Unpack to temporary location
        $Folder = Join-Path -Path $Staging -ChildPath $Package.BaseName
        Expand-Archive -Path $ZIP -DestinationPath $Folder -Force
        # Exclude metadata files
        $Files = Get-ChildItem -Path $Folder
        foreach ($File in $Files) {
            $Metadata = @(
                "ayx_workspace.json",
                "Config.xml",
                "icon.png"
            )
            if ($File -in $Metadata) {
                Write-Log -Type "DEBUG" -Message "Excluding $($File.Name)"
                Remove-Item -Path $File.FullName -Force
            }
        }
        # Move to destination
        $Tools = Get-ChildItem -Path $Folder
        foreach ($Tool in $Tools) {
            Write-Log -Type "INFO" -Message "Installing tool $($Tool.BaseName)"
            $InstalledTool = Join-Path -Path $Destination -ChildPath $Tool.BaseName
            if (Test-Object -Path $InstalledTool) {
                Write-Log -Type "DEBUG" -Message $InstalledTool
                Write-Log -Type "WARN" -Message "The tool $($Tool.BaseName) is already installed"
                if (-Not $Unattended) {
                    $Confirm = Confirm-Prompt -Prompt "Overwrite existing version?"
                }
                if ($Unattended -Or $Confirm) {
                    Write-Log -Type "WARN" -Message "$($Tool.BaseName) tool has been overwritten"
                    Copy-Object -Path $Tool.FullName -Destination $Destination -Force
                } else {
                    Write-Log -Type "WARN" -Message "$($Tool.BaseName) tool installation skipped"
                }
            } else {
                Copy-Object -Path $Tool.FullName -Destination $Destination -Force
            }
        }
        # Clean-up
        Write-Log -Type "WARN" -Message "Cleaning-up temporary files"
        Remove-Object -Path $ZIP
        Remove-Object -Path $Folder
        if ($Delete) {
            Write-Log -Type "WARN" -Message "Removing package installer"
            Remove-Object -Path $Path -Force
        }
    }
    End {
        Write-Log -Type "CHECK" -Message "Installation of package $($Package.BaseName) completed successfully"
    }
}