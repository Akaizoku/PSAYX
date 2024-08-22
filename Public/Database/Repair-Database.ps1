function Repair-Database {
    <#
        .SYNOPSIS
        Rebuild database indexes

        .DESCRIPTION
        Run maintenance scripts to repair embedded MongoDB database

        .NOTES
        File name:      Repair-Database.ps1
        Author:         Florian Carrier
        Creation date:  2024-02-12
        Last modified:  2024-02-12
        Resources:      https://knowledge.alteryx.com/index/s/article/Checklist-Manual-Reindex
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $false,
            HelpMessage = "Embedded MongoDB database admin password"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.Security.SecureString]
        $Password,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to the backup location"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $Version
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Retrieve version
        if (-Not $PSBoundParameters.ContainsKey("Version")) {
            $Version = Get-RegistryVersion
        }
        # Get appropriate service path
        if (Compare-Version -Version $Version -Operator "ge" -Reference "2020.1 ") {
            $ServicePath = Get-Utility -Utility "ServerHost"
        } else {
            $ServicePath = Get-Utility -Utility "CloudCmd"
        }
        # Retrieve password
        if (-Not $PSBoundParameters.ContainsKey("Password")) {
            $Password = Get-EMongoPassword
        }
        $TextPassword = ConvertFrom-SecureString -SecureString $Password -AsPlainText
    }
    Process {
        # Define operation
        $Operation = "rebuild"
        # Build parameter string
        $Parameter = "-mongoconnection:mongodb://user:$TextPassword@localhost:27018/AlteryxGallery?connectTimeoutMS=25000 -luceneconnection:mongodb://user:$TextPassword@localhost:27018/AlteryxGallery_Lucene?connectTimeoutMS=25000 -searchProvider:Lucene"
        # Call utility
        $Output = Invoke-Service -Path $ServicePath -Operation $Operation -Parameter $Parameter -WhatIf:$WhatIfPreference
        return $Output
    }
}