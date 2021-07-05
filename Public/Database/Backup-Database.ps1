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
        Last modified:  2021-07-05

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
            HelpMessage = "Path to the backup file to generate"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $FileName,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx Service executable"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Path
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Define operation
        $Operation = "emongodump"
        # Escape filename
        $Parameter = """$FileName"""
    }
    Process {
        $Output = Invoke-Service -Path $Path -Operation $Operation -Parameter $Parameter
        return $Output
    }
}