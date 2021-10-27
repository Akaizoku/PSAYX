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
        Last modified:  2021-10-27
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to the configuration settings file"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.IO.FileInfo]
        $SettingFile,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx Service executable"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("ServicePath")]
        [System.IO.FileInfo]
        $Path
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Utility path
        if ($PSBoundParameters.ContainsKey("Path")) {
            if (Test-Object -Path $Path -NotFound) {
                Write-Log -Type "ERROR" -Message "Path not found $Path" -ExitCode 1
            }
        } else {
            $Path = Get-Utility -Utility "Service"
        }
    }
    Process {
        # Define operation
        $Operation = "settingfile"
        # Build parameter string
        $Parameter = """$SettingFile"""
        # Call utility
        $Output = Invoke-Service -Path $Path -Operation $Operation -Parameter $Parameter -WhatIf:$WhatIfPreference
        return $Output
    }
}