function Start-Workflow {
    <#
        .SYNOPSIS
        Run Alteryx workflow

        .DESCRIPTION
        Run an Alteryx workflow from command-line

        .NOTES
        File name:      Start-Workflow.ps1
        Author:         Florian Carrier
        Creation date:  2021-09-15
        Last modified:  2021-11-20
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to the workflow to execute"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.IO.FileInfo]
        $Workflow,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to the XML file containing the analytic application parameters"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("Parameters")]
        [System.IO.FileInfo]
        $AppValues,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Path to the Alteryx engine command line utility"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("AlteryxEngine")]
        [System.IO.FileInfo]
        $AlteryxEngine,
        [Parameter (
            HelpMessage = "Switch to force the use of the AMP engine"
        )]
        [Switch]
        $AMP
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Engine path
        if (-Not $PSBoundParameters.ContainsKey("AlteryxEngine")) {
            $AlteryxEngine = Get-Utility -Utility "Engine"
        }
    }
    Process {
        # Parameters
        $Parameters = ([System.String]::Concat('"', $Workflow, '"', " ", $AppValues)).Trim()
        # Run workflow
        $Output = Invoke-Engine -Path $AlteryxEngine -Parameters $Parameters -AMP:$AMP
        return $Output
    }
}