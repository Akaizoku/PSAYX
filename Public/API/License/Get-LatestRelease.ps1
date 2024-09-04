function Get-LatestRelease {
    <#
        .SYNOPSIS
        Fetch latest product release

        .DESCRIPTION
        Retrieves the latest version available for a specified product and provides the direct download link
        
        .NOTES
        File name:      Get-LatestRelease.ps1
        Author:         Florian Carrier
        Creation date:  2024-09-03
        Last modified:  2024-09-04

        .LINK
        https://us1.alteryxcloud.com/license-portal/api/swagger-ui/index.html

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
            Mandatory   = $true,
            HelpMessage = "Alteryx product ID"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("Product", "ProductLineID")]
        $ProductID,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Alteryx product version"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.Version]
        $Version,
        [Parameter (
            HelpMessage = "Switch to select patch releases"
        )]
        [Switch]
        $Patch
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Response object
        $Response = New-Object -TypeName "System.Collections.Specialized.OrderedDictionary"
        $Response.Add("Product", $ProductID)
    }
    Process {
        # Fetch releases
        $Releases = Get-AlteryxProductReleases -AccountID $AccountID -Token $AccessToken -ProductID $ProductID
        if ($Version) {
            # Fetch latest release for specified version
            $Release = $Releases | Where-Object -Property "Version" -EQ -Value $Version
        } else {
            # Fecth latest release
            $Release = $Releases | Select-Object -First 1
        }
        # Parse release date
        $Response.Add("Date", $Release.releaseDate)
        # Fetch corresponding product installer download URL
        if ($Patch) {
            $Product = "$ProductID Patch"
        } else {
            $Product = $ProductID
        }
        $Installer = Get-AlteryxProductEditions -AccountID $AccountID -Token $AccessToken -ReleaseID $Release.id | Where-Object -Property "description" -EQ -Value $Product
        # Parse file name
        if ((Split-Path -Path $Installer.downloadLink -Leaf) -match '(.+?\.exe)') {
            $FileName = $matches[1]
        } else {
            Write-Log -Type "WARN" -Message "Unable to parse file name"
            $FileName = $Null
        }
        $Response.Add("FileName", $FileName)
        # Parse complete version number
        if ($Installer.downloadLink -match '_(\d+\.\d+(\.\d+)?(\.\d+)?(\.\d+)?)\.exe') {
            $ParsedVersion = $matches[1]
            # Hotfix for messed up patch version formatting
            if ($Patch) {
                $PatchVersion = Select-String -InputObject $ParsedVersion -Pattern '(\d+\.\d+\.\d+)(?:\.\d+)(\.\d+)' -AllMatches
                $Version = [System.String]::Concat($PatchVersion.Matches.Groups[1].Value, $PatchVersion.Matches.Groups[2].Value)
            } else {
                $Version = $ParsedVersion
            }
        } else {
            $Version = $Release.version
        }
        $Response.Add("Version", $Version)
        # Expose direct download link
        $Response.Add("URL", $Installer.downloadLink)
        # Return formatted response object
        Write-Log -Type "DEBUG" -Message $Response
        return $Response
    }
}