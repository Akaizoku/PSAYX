function Get-ServicePath {
    <#
        .SYNOPSIS
        Returns Alteryx service path

        .DESCRIPTION
        Return the path to the Alteryx service executable from registry

        .NOTES
        File name:      Get-ServicePath.ps1
        Author:         Florian Carrier
        Creation date:  2024-03-06
        Last modified:  2024-03-06
    #>
    [CmdletBinding ()]
    Param (
        
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Alteryx service registry key
        $RegistryKey = "HKLM:HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\AlteryxService"
    }
    Process {
        $ServicePath = (Get-ItemProperty -Path $RegistryKey).ImagePath
        return $ServicePath
    }
}