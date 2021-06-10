function Get-InstallDirectory {
    <#
        .SYNOPSIS
        Retrieve Alteryx installation directory

        .DESCRIPTION
        Search registry for the path to Alteryx installation directory

        .NOTES
        File name:      Get-InstallDirectory.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-05
        Last modified:  2021-06-10

        .LINK
        https://www.powershellgallery.com/packages/PSAYX
    #>
    Begin {
        # Registry key
        $Registry = "HKLM:HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\SRC\Alteryx"
    }
    Process {
        # Retrieve Alteryx installation directory from registry
        if (Test-Object -Path $Registry) {
            $InstallDirectory = (Get-ItemProperty -Path $Registry).InstallDir64
            if ($null -eq $InstallDirectory) {
                Write-Log -Type "ERROR" -Message "Alteryx installation path could not be found" -ExitCode 1
            } else {
                return $InstallDirectory
            }
        } else {
            Write-Log -Type "ERROR" -Message "Alteryx installation path could not be found" -ExitCode 1
        }
    }
}
