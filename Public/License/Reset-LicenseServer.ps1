function Reset-LicenseServer {
    <#
        .SYNOPSIS
        Set the license system to standard

        .DESCRIPTION
        Reset the licensing server for Alteryx via the command line utility

        .NOTES
        File name:      Reset-LicenseServer.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-09
        Last modified:  2021-10-27
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
            HelpMessage = "Path to Alteryx licensing utility"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.IO.FileInfo]
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
        $Operation = "setStandardLicenseSystem"
        # Call licensing utility
        $Output = Invoke-LicenseUtility -Path $Path -Operation $Operation -Silent:$Silent
        # Return output
        return $Output
    }
}