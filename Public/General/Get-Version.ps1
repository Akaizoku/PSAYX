function Get-Version {
    <#
        .SYNOPSIS
        Get Alteryx Server version

        .DESCRIPTION
        Retrieves the Alteryx Server version

        .NOTES
        File name:      Get-Version.ps1
        Author:         Florian Carrier
        Creation date:  2021-09-02
        Last modified:  2021-09-20
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
            $Path = Get-ServerProcess -Process "Service"
        }
    }
    Process {
        # Define operation
        $Operation = "getversion"
        # Call utility
        $Output = Invoke-Service -Path $Path -Operation $Operation -WhatIf:$WhatIfPreference
        return $Output
    }
}