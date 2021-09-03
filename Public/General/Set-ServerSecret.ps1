function Set-ServerSecret {
    <#
        .SYNOPSIS
        Set Alteryx Server secret

        .DESCRIPTION
        Set the Alteryx Server controller token value

        .NOTES
        File name:      Set-ServerSecret.ps1
        Author:         Florian Carrier
        Creation date:  2021-08-27
        Last modified:  2021-08-27
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "New controller secret value"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("Token")]
        [String]
        $Secret,
        [Parameter (
            Position    = 2,
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
        $Operation = "setserversecret"
        # Escape parameter value
        $Parameter = """$Secret"""
    }
    Process {
        $Output = Invoke-Service -Path $Path -Operation $Operation -Parameter $Parameter -WhatIf:$WhatIfPreference
        return $Output
    }
}