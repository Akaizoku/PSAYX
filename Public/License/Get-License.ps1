function Get-License {
    <#
        .SYNOPSIS
        Retrieve Alteryx license

        .DESCRIPTION
        Retrieve the license(s) for Alteryx Designer via the command line utility

        .NOTES
        File name:      Get-License.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-09
        Last modified:  2021-00-20

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
            HelpMessage = "Switch to suppress log generation"
        )]
        [Switch]
        $Silent
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Utility path
        if ($PSBoundParameters.ContainsKey("Path")) {
            if (Test-Object -Path $Path -NotFound) {
                Write-Log -Type "ERROR" -Message "Path not found $Path" -ExitCode 1
            }
        } else {
            $Path = Get-Utility -Utility "License"
        }
    }
    Process {
        # Define operation
        $Operation = "list"
        # Call licensing utility
        $Output = Invoke-LicenseUtility -Path $Path -Operation $Operation -Silent:$Silent
        # Return output
        return $Output
    }
}