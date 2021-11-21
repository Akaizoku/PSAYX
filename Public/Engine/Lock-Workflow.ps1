function Lock-Workflow {
    <#
        .SYNOPSIS
        Lock Alteryx workflow

        .DESCRIPTION
        Lock an Alteryx workflow from command-line

        .NOTES
        File name:      Lock-Workflow.ps1
        Author:         Florian Carrier
        Creation date:  2021-11-20
        Last modified:  2021-11-20

        .LINK
        https://help.alteryx.com/current/designer/lock-your-workflow
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to the workflow to lock"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.IO.FileInfo]
        $Workflow,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to the locked workflow"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.IO.FileInfo]
        $LockedWorkflow,
        [Parameter (
            Position    = 3,
            Mandatory   = $false,
            HelpMessage = "List of serial numbers for the locked workflow to work on"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("CommaSeparatedSerialNumbers")]
        [System.String[]]
        $SerialNumbers,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Expiration date of the locked workflow"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.DateTime]
        $ExpirationDate,
        [Parameter (
            Position    = 5,
            Mandatory   = $false,
            HelpMessage = "Path to the Alteryx engine command line utility"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("EnginePath")]
        [System.IO.FileInfo]
        $AlteryxEngine
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Engine path
        if (-Not $PSBoundParameters.ContainsKey("AlteryxEngine")) {
            $AlteryxEngine = Get-Utility -Utility "Engine"
        }
        # Target location
        if (-Not $PSBoundParameters.ContainsKey("LockedWorkflow")) {
            $TargetDirectory = Split-Path -Path $Workflow -Parent
            $LockedWorkflow = Join-Path -Path $TargetDirectory -ChildPath ([System.String]::Concat($Workflow.BaseName, "_Locked", $Workflow.Extension))
        }
        # Optional parameters
        if ((-Not $PSBoundParameters.ContainsKey("SerialNumbers")) -And ($PSBoundParameters.ContainsKey("ExpirationDate"))) {
            $OptionalParameters = ' "" ' + $ExpirationDate.ToString("yyyy-MM-dd")
        } elseif ($PSBoundParameters.ContainsKey("SerialNumbers")) {
            $OptionalParameters = ($SerialNumbers -join ",") + " " + $ExpirationDate.ToString("yyyy-MM-dd")
        }
    }
    Process {
        # Define command parameters
        $Parameters = ([System.String]::Concat('/Lock "', $Workflow, '" "', $LockedWorkflow, '" ', $OptionalParameters)).Trim()
        # Call engine
        $Output = Invoke-Engine -Path $AlteryxEngine -Parameters $Parameters
        return $Output
    }
}