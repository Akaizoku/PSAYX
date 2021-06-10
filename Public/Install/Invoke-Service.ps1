function Invoke-Service {
    <#
        .SYNOPSIS
        Call Alteryx Server Service

        .DESCRIPTION
        Create commands and call Alteryx Server Service executable file

        .NOTES
        File name:      Invoke-Service.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-10
        Last modified:  2021-06-10

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/server/alteryxservice-commands
    #>    
    [CmdletBinding ()]
    # Inputs
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to Alteryx Service executable"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Path,
        [Parameter (
            Position    = 2,
            Mandatory   = $true,
            HelpMessage = "Operation to perform"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Operation,
        [Parameter (
            Position    = 3,
            Mandatory   = $false,
            HelpMessage = "List of parameters"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("Parameter")]
        [String]
        $Parameters,
        [Parameter (
            HelpMessage = "Switch to suppress log generation"
        )]
        [Switch]
        $Silent
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }
    Process {
        # Define command
        switch ($Operation) {
            default {
                # Build syntax for parameters
                if ($PSBoundParameters.ContainsKey("Parameters")) {
                    $Command = "& ""$Path"" $Operation=$Parameters"
                } else {
                    $Command = "& ""$Path"" $Operation"
                }
            }
        }
        Write-Log -Type "DEBUG" -Message $Command
        # Call utility and return output
        $Output = Invoke-Expression -Command $Command | Out-String
        return $Output
    }
}