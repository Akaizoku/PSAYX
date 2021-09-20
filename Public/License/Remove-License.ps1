function Remove-License {
    <#
        .SYNOPSIS
        Deactivate Alteryx license

        .DESCRIPTION
        Deactivate a license for Alteryx via the command line utility

        .NOTES
        File name:      Remove-License.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-09
        Last modified:  2021-09-20

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
            HelpMessage = "License key(s)"
        )]
        [ValidatePattern ("^\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}$")]
        [Alias (
            "License",
            "Keys"
        )]
        [String]
        $Key,
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
        $Operation = "delete"
        # Call licensing utility
        if ($PSBoundParameters.ContainsKey("Key")) {
            # Remove specified license key
            $Output = Invoke-LicenseUtility -Path $Path -Operation $Operation -Parameters $Key -Silent:$Silent
        } else {
            # Remove all license keys
            $Output = Invoke-LicenseUtility -Path $Path -Operation $Operation -Silent:$Silent
        }
        # Return output
        return $Output
    }
}