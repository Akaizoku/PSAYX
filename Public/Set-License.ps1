function Set-License {
    <#
        .SYNOPSIS
        Activate Alteryx license

        .DESCRIPTION
        Activate the license for Alteryx Designer via the command line utility

        .NOTES
        File name:      Set-License.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-05
        Last modified:  2021-06-07

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
            HelpMessage = "License key"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("License")]
        [String]
        $Key,
        [Parameter (
            Position    = 2,
            Mandatory   = $true,
            HelpMessage = "Email address of the user"
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
        # Define expected successful result
        $ExpectedResult = "License seat was successfully moved to this computer"
    }
    Process {
        # Define and execute command
        $Command = "& $Path $Key $Email"
        $Output = Invoke-Expression -Command $Command | Out-String
        # Check output
        If ($Output.StartsWith($ExpectedResult)) {
            $Success    = $true
            $Type       = "CHECK"
        } else {
            $Success    = $false
            $Type       = "ERROR"
        }
        # Output
        Write-Log -Type $Type -Message $Output -Silent:$Silent
        return $Success
    }
}