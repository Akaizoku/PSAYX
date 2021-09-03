function Get-ServerSecret {
    <#
        .SYNOPSIS
        Get Alteryx Server secret

        .DESCRIPTION
        Retrieves the Alteryx Server controller token

        .NOTES
        File name:      Get-ServerSecret.ps1
        Author:         Florian Carrier
        Creation date:  2021-08-27
        Last modified:  2021-08-27
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx Service executable"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("ServicePath")]
        [String]
        $Path
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Define operation
        $Operation = "getserversecret"
    }
    Process {
        $Output = Invoke-Service -Path $Path -Operation $Operation -WhatIf:$WhatIfPreference
        return $Output
    }
}