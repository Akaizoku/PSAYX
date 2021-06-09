function Set-LicenseServer {
    <#
        .SYNOPSIS
        Change Alteryx license

        .DESCRIPTION
        Change the licensing server for Alteryx via the command line utility

        .NOTES
        File name:      Set-LicenseServer.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-09
        Last modified:  2021-06-09
        Comment:        **Untested**

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
            Mandatory   = $false,
            HelpMessage = "Local license server URL"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("Server")]
        [String]
        $URL,
        [Parameter (
            Position    = 2,
            Mandatory   = $true,
            HelpMessage = "Email address or serial number associated with the machine."
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("Serial")]
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
        $Operation = "setLicenseServerSystem"
    }
    Process {
        # Call licensing utility
        if ($PSBoundParameters.ContainsKey("Email")) {
            # Set the URL for the local license server (LLS)
            $Output = Invoke-LicenseUtility -Path $Path -Operation $Operation -Parameters "$URL $Email" -Silent:$Silent
        } else {
            # Remove value for LLS
            $Output = Invoke-LicenseUtility -Path $Path -Operation $Operation -Parameters $Email -Silent:$Silent
        }
        # Return output
        return $Output
    }
}