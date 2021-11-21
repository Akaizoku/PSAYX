function Get-Utility {
    <#
        .SYNOPSIS
        Retrieve Alteryx utility path

        .DESCRIPTION
        Search registry for the path to a specified Alteryx utility

        .NOTES
        File name:      Get-Utility.ps1
        Author:         Florian Carrier
        Creation date:  2021-09-16
        Last modified:  2021-11-20

        .LINK
        https://www.powershellgallery.com/packages/PSAYX
    #>
    [CmdLetBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Utility name"
        )]
        [ValidateSet (
            "Designer",
            "Engine",
            "License",
            "MongoDB",
            "Service"
        )]
        [Alias ("Name")]
        [System.String]
        $Utility,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx installation directory"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $Path
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Processes
        $Processes = [Ordered]@{
            "Designer"  = "Gui"
            "Engine"    = "EngineCmd"
            "License"   = "License"
            "MongoDB"   = "Database"
            "Service"   = "Service"
        }
    }
    Process {
        if ($PSBoundParameters.ContainsKey("Path")) {
            Get-ServerProcess -Process $Processes.$Utility -InstallDirectory $Path
        } else {
            Get-ServerProcess -Process $Processes.$Utility
        }
    }
}
