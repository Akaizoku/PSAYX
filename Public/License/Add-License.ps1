function Add-License {
    <#
        .SYNOPSIS
        Activate Alteryx license

        .DESCRIPTION
        Activate a license for Alteryx via the command line utility

        .NOTES
        File name:      Add-License.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-05
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
            HelpMessage = "License key(s)"
        )]
        [ValidatePattern ("^\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}(\s\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4})*$")]
        [Alias (
            "License",
            "Keys"
        )]
        [String]
        $Key,
        [Parameter (
            Position    = 2,
            Mandatory   = $true,
            HelpMessage = "Email address"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Email,
        [Parameter (
            Position    = 3,
            Mandatory   = $false,
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
        # Define operation
        $Operation = "add"
    }
    Process {
        # Call licensing utility
        $Output = Invoke-LicenseUtility -Path $Path -Operation $Operation -Parameters "$Key $Email" -Silent:$Silent
        # Return output
        return $Output
    }
}