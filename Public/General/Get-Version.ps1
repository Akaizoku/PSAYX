function Get-Version {
    <#
        .SYNOPSIS
        Get Alteryx Server version

        .DESCRIPTION
        Retrieves the Alteryx Server version

        .NOTES
        File name:      Get-Version.ps1
        Author:         Florian Carrier
        Creation date:  2021-09-02
        Last modified:  2021-09-02
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
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
        # Define operation
        $Operation = "getversion"
    }
    Process {
        $Output = Invoke-Service -Path $Path -Operation $Operation -WhatIf:$WhatIfPreference
        return $Output
    }
}