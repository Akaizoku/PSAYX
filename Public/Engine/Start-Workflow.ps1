function Start-Workflow {
    <#
        .SYNOPSIS
        Run Alteryx workflow

        .DESCRIPTION
        Run an Alteryx workflow by command-line

        .NOTES
        File name:      Start-Workflow.ps1
        Author:         Florian Carrier
        Creation date:  2021-09-15
        Last modified:  2021-09-15
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
            Position    = 3,
            Mandatory   = $false,
            HelpMessage = "Version of the engine to use"
        )]
        [ValidateSet (
            "1",
            "2",
            "Original",
            "AMP"
        )]
        [System.String]
        $EngineVersion,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Path to the Alteryx engine command line utility"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("Path")]
        [System.IO.FileInfo]
        $EnginePath
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Engine path
        if (-Not $PSBoundParameters.ContainsKey("EnginePath")) {
            $EnginePath = Get-Utility -Utility "Engine"
        }
    }
    Process {
        # Parameters
        $Parameters = ([System.String]::Concat('"', $Workflow, '"', " ", $AppValues)).Trim()
        # Call engine
        if ($PSBoundParameters.ContainsKey("EngineVersion")) {
            $Output = Invoke-Engine -Path $EnginePath -Parameters $Parameters -EngineVersion $EngineVersion
        } else {
            $Output = Invoke-Engine -Path $EnginePath -Parameters $Parameters
        }
        return $Output
    }
}