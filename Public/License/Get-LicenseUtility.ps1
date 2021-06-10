function Get-LicenseUtility {
    <#
        .SYNOPSIS
        Retrieve Alteryx license utility path directory

        .DESCRIPTION
        Search registry for the path to Alteryx license utility path

        .NOTES
        File name:      Get-LicenseUtility.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-10
        Last modified:  2021-06-10

        .LINK
        https://www.powershellgallery.com/packages/PSAYX
    #>
    Begin {
        # Registry key
        $Executable = "AlteryxActivateLicenseKeyCmd.exe"
    }
    Process {
        # Retrieve Alteryx installation directory from registry
        $InstallDirectory = Get-AlteryxInstallDirectory
        # Build and test path
        $Path = Join-Path -Path $InstallDirectory -ChildPath $Executable
        if (Test-Path -Path $Path) {
            return $Path
        } else {
            Write-Log -Type "DEBUG" -Message $Path
            Write-Log -Type "ERROR" -Message "Alteryx command-line license utility could not be found" -ErrorCode 1
        }
    }
}
