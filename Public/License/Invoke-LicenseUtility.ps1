function Invoke-LicenseUtility {
    <#
        .SYNOPSIS
        Call Alteryx license command-line utility

        .DESCRIPTION
        Retrieve the license(s) for Alteryx Designer via the command line utility

        .NOTES
        File name:      Invoke-LicenseUtility.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-09
        Last modified:  2021-06-09

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/product-activation-and-licensing/use-command-line-options
    #>    
    [CmdletBinding ()]
    # Inputs
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to Alteryx licensing utility"
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
            "add" {
                # Activation does not require operation parameter
                $Command = "& ""$Path"" $Parameters"
            }
            "delete" {
                # Deactivation requires the delete keyword at the end
                if ($PSBoundParameters.ContainsKey("Parameters")) {
                    $Command = "& ""$Path"" $Parameters $Operation"
                } else {
                    # Deactivation fails if there is an extra space in the command
                    $Command = "& ""$Path"" $Operation"
                }
                
            }
            default {
                # Standard command structure
                $Command = "& ""$Path"" $Operation $Parameters"
            }
        }
        Write-Log -Type "DEBUG" -Message $Command
        # Call utility and return output
        $Output = Invoke-Expression -Command $Command | Out-String
        return $Output
    }
}