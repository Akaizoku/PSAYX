function Get-LicenseUtility {
    <#
        .SYNOPSIS
        Retrieve Alteryx license utility path

        .DESCRIPTION
        Search registry for the path to Alteryx license utility

        .NOTES
        File name:      Get-LicenseUtility.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-10
        Last modified:  2021-06-10

        .LINK
        https://www.powershellgallery.com/packages/PSAYX
    #>
    [CmdLetBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx installation directory"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Path
    )
    Begin {
        # Registry key
        $Executable = "AlteryxActivateLicenseKeyCmd.exe"
    }
    Process {
        # Check installation directory
        if ($PSBoundParameters.ContainsKey("Path")) {
            $InstallDirectory = $Path
        } else {
            # Retrieve Alteryx installation directory from registry
            $InstallDirectory = Get-AlteryxInstallDirectory
        }
        # Build and test path
        $LicenseUtility = Join-Path -Path $InstallDirectory -ChildPath $Executable
        if (Test-Path -Path $LicenseUtility) {
            return $LicenseUtility
        } else {
            Write-Log -Type "DEBUG" -Message $LicenseUtility
            Write-Log -Type "ERROR" -Message "Alteryx command-line license utility could not be found" -ErrorCode 1
        }
    }
}
