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
        Last modified:  2024-09-04
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
        $Path,
        [Parameter (
            HelpMessage = "Return raw command output"
        )]
        [Switch]
        $Raw
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
        $Operation = "getversion"
        # Call utility
        $Output = Invoke-Service -Path $Path -Operation $Operation -WhatIf:$WhatIfPreference
        # Parse output if required
        if ($Raw) {
            $Version = $Output
        } else {
            $Version = Select-String -InputObject $Output -Pattern '(\d+\.\d+(?:\.\d+)?(?:\.\d+)?)' | ForEach-Object { $PSItem.Matches.Value }
        }
        return $Version
    }
}