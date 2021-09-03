function Set-SettingFile {
    <#
        .SYNOPSIS
        Set Alteryx Server setting file

        .DESCRIPTION
        Update the configuration file for Alteryx Server

        .NOTES
        File name:      Set-SettingFile.ps1
        Author:         Florian Carrier
        Creation date:  2021-08-27
        Last modified:  2021-08-27
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to the configuration settings file"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $SettingFile,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx Service executable"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("ServicePath")]
        [String]
        $Path
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Define operation
        $Operation = "settingfile"
        # Escape parameter value
        $Parameter = """$SettingFile"""
    }
    Process {
        $Output = Invoke-Service -Path $Path -Operation $Operation -Parameter $Parameter -WhatIf:$WhatIfPreference
        return $Output
    }
}