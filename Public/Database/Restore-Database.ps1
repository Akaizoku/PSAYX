function Restore-Database {
    <#
        .SYNOPSIS
        Restore Alteryx Server database

        .DESCRIPTION
        Restore a backup of the MongoDB underlying database for Alteryx Server

        .NOTES
        File name:      Restore-Database.ps1
        Author:         Florian Carrier
        Creation date:  2021-08-26
        Last modified:  2021-09-20

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
        [System.IO.DirectoryInfo]
        $SourcePath,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx Server database location"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.IO.DirectoryInfo]
        $TargetPath,
        [Parameter (
            Position    = 3,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx Service executable"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
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
        $Operation = "emongorestore"
        # Escape paths
        $Parameter = """$SourcePath"",""$TargetPath"""
        # Call utility
        $Output = Invoke-Service -Path $ServicePath -Operation $Operation -Parameter $Parameter -WhatIf:$WhatIfPreference
        return $Output
    }
}