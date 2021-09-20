function Test-SettingFile {
    <#
        .SYNOPSIS
        Verify Alteryx Server setting file

        .DESCRIPTION
        Reads and validates the Alteryx Server configuration setting file

        .NOTES
        File name:      Test-SettingFile.ps1
        Author:         Florian Carrier
        Creation date:  2021-08-30
        Last modified:  2021-09-20
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to the setting file to verify"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.IO.FileInfo]
        $SettingFile,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to the file to write the results to"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("ResultsPath")]
        [System.IO.FileInfo]
        $OutputPath,
        [Parameter (
            Position    = 3,
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
        $Operation = "verifysettingfile"
        # Define parameter values
        $Parameter = """$SettingFile"""
        if ($PSBoundParameters.ContainsKey("OutputPath")) {
            $Parameter = $Parameter + """,$OutputPath"""
        }
        # Call utility
        $Output = Invoke-Service -Path $Path -Operation $Operation -Parameter $Parameter -WhatIf:$WhatIfPreference
        return $Output
    }
}