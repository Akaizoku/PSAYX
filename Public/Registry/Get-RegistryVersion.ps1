function Get-RegistryVersion {
    <#
        .SYNOPSIS
        Retrieve Alteryx version from registry

        .DESCRIPTION
        Search the registry for the version of Alteryx

        .NOTES
        File name:      Get-RegistryVersion.ps1
        Author:         Florian Carrier
        Creation date:  2021-09-16
        Last modified:  2021-09-16

        .LINK
        https://www.powershellgallery.com/packages/PSAYX
    #>
    Begin {
        # Get global preference variables
        # Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Registry key
        $Registry = "HKLM:HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\SRC\Alteryx"
    }
    Process {
        # Retrieve Alteryx installation directory from registry
        if (Test-Object -Path $Registry) {
            $Version = (Get-ItemProperty -Path $Registry).LastVersion
            if ($null -eq $Version) {
                Write-Log -Type "WARN" -Message "LastVersion registry entry is missing"
                Write-Log -Type "ERROR" -Message "Alteryx version could not be retrieved from registry" -ExitCode 1
            } else {
                return $Version
            }
        } else {
            Write-Log -Type "DEBUG" -Message $Registry
            Write-Log -Type "ERROR" -Message "Alteryx version could not be retrieved from registry" -ExitCode 1
        }
    }
}
