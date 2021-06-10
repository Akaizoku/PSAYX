function Import-LicenseFile {
    <#
        .SYNOPSIS
        Load Alteryx license request file

        .DESCRIPTION
        Load a license file for Alteryx via the command line utility

        .NOTES
        File name:      Import-LicenseFile.ps1
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
            Mandatory   = $true,
            HelpMessage = "Path to the license activation (.bin) file"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $FileName,
        [Parameter (
            Position    = 2,
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
        $Operation = "load"
    }
    Process {
        # Call licensing utility
        $Output = Invoke-LicenseUtility -Path $Path -Operation $Operation -Parameters $FileName -Silent:$Silent
        # Return output
        return $Output
    }
}