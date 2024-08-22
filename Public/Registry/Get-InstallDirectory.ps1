function Get-InstallDirectory {
    <#
        .SYNOPSIS
        Retrieve Alteryx installation directory

        .DESCRIPTION
        Search registry for the path to the last Alteryx installation directory

        .NOTES
        File name:      Get-InstallDirectory.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-05
        Last modified:  2024-03-06
        Comments:       Version parameter is deprecated but kept for back-ward compatibility

        .LINK
        https://www.powershellgallery.com/packages/PSAYX
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $false,
            HelpMessage = "Alteryx product"
        )]
        [ValidateSet (
            "Designer",
            "Server"
        )]
        [System.String]
        $Product,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Alteryx version"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.Version]
        $Version
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Alteryx registry key
        $RegistryKey = "HKLM:HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\SRC\Alteryx"
    }
    Process {
        # Retrieve Alteryx installation directory from registry
        if (Test-Object -Path $RegistryKey) {
            Write-Log -Type "DEBUG" -Message $RegistryKey
            $InstallDirectory = (Get-ItemProperty -Path $RegistryKey).LastInstallDir
            if ($null -eq $InstallDirectory) {
                Write-Log -Type "DEBUG" -Message $RegistryKey
                Write-Log -Type "WARN"  -Message "LastInstallDir registry entry is missing"
                Write-Log -Type "ERROR" -Message "Alteryx installation location could not be retrieved from registry" -ExitCode 1
            } else {
                return $InstallDirectory
            }
        } else {
            Write-Log -Type "WARN"  -Message "Alteryx installation registry entry is missing"
            Write-Log -Type "ERROR" -Message "Alteryx installation location could not be retrieved from registry" -ExitCode 1
        }
    }
}
