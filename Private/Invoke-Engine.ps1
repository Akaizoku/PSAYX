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
        Last modified:  2021-10-27

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/designer/run-workflows-command-line

        .LINK
        https://help.alteryx.com/current/designer/alteryx-amp-engine
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
            HelpMessage = "Switch to force the use of the AMP engine"
        )]
        [Switch]
        $AMP
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }
    Process {
        # Build command
        if ($AMP) {
            $Command = "& ""$Path"" /amp $Parameters"
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