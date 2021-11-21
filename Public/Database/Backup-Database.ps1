function Backup-Database {
    <#
        .SYNOPSIS
        Backup Alteryx Server database

        .DESCRIPTION
        Create a backup of the MongoDB underlying database for Alteryx Server

        .NOTES
        File name:      Backup-Database.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-10
        Last modified:  2021-10-27

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/server/alteryxservice-commands
    #>
    [CmdletBinding ()]
    # Inputs
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to the backup location"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $Path,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx Service executable"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.IO.FileInfo]
        $ServicePath
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Utility path
        if ($PSBoundParameters.ContainsKey("ServicePath")) {
            if (Test-Object -Path $ServicePath -NotFound) {
                Write-Log -Type "ERROR" -Message "Path not found $ServicePath" -ExitCode 1
            }
        } else {
            $ServicePath = Get-Utility -Utility "MongoDB"
        }
    }
    Process {
        # Define operation
        $Operation = "emongodump"
        # Escape filename
        $Parameter = """$Path"""
        # Call utility
        $Output = Invoke-Service -Path $ServicePath -Operation $Operation -Parameter $Parameter -WhatIf:$WhatIfPreference
        return $Output
    }
}