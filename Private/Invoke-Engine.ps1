function Invoke-Engine {
    <#
        .SYNOPSIS
        Call Alteryx engine

        .DESCRIPTION
        Create commands and call Alteryx engine command-line utility

        .NOTES
        File name:      Invoke-Engine.ps1
        Author:         Florian Carrier
        Creation date:  2021-09-15
        Last modified:  2021-09-15

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/designer/run-workflows-command-line
    #>    
    [CmdletBinding (
        SupportsShouldProcess = $true
    )]
    # Inputs
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to Alteryx engine command-line utility"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.IO.FileInfo]
        $Path,
        [Parameter (
            Position    = 2,
            Mandatory   = $true,
            HelpMessage = "List of parameters"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("Parameter")]
        [System.String]
        $Parameters,
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
        $EngineVersion
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Check engine version
        if ($EngineVersion -in @("1", "Original")) {
            $EngineOption = "/e1"
        } elseif ($EngineVersion -in @("2", "AMP")) {
            $EngineOption = "/e2"
        }
    }
    Process {
        # Build command
        if ($PSBoundParameters.ContainsKey("EngineVersion")) {
            $Command = "& ""$Path"" $EngineOption $Parameters"
        } else {
            $Command = "& ""$Path"" $Parameters"
        }
        Write-Log -Type "DEBUG" -Message $Command
        # Call utility and return output
        if ($PSCmdlet.ShouldProcess($Path, $Operation)) {
            $Output = Invoke-Expression -Command $Command | Out-String
            return $Output
        } else {
            return $Command
        }
    }
}