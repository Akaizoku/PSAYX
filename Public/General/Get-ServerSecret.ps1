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
        Last modified:  2021-10-27
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
        [System.IO.FileInfo]
        $Path
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Utility path
        if ($PSBoundParameters.ContainsKey("Path")) {
            if (Test-Object -Path $Path -NotFound) {
                Write-Log -Type "ERROR" -Message "Path not found $Path" -ExitCode 1
            }
        } else {
            $Path = Get-Utility -Utility "Service"
        }
    }
    Process {
        # Define operation
        $Operation = "getserversecret"
        # Call utility
        $Output = Invoke-Service -Path $Path -Operation $Operation -WhatIf:$WhatIfPreference
        return $Output
    }
}