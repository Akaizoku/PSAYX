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
        Last modified:  2021-10-26

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/server/server-processes-reference
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
            "Designer"  = "AlteryxGui.exe"
            "Engine"    = "AlteryxEngineCmd.exe"
            "License"   = "AlteryxActivateLicenseKeyCmd.exe"
            "MongoDB"   = "mongod.exe"
            "Service"   = "AlteryxService.exe"
        }
    }
    Process {
        # Check installation directory
        if ($PSBoundParameters.ContainsKey("Path")) {
            $InstallDirectory = $Path
        } else {
            # Retrieve Alteryx installation directory from registry
            $InstallDirectory = Get-InstallDirectory
        }
        # Build and test path
        $LicenseUtility = Join-Path -Path $InstallDirectory -ChildPath "bin\$($Processes.$Utility)"
        if (Test-Object -Path $LicenseUtility) {
            return $LicenseUtility
        } else {
            Write-Log -Type "DEBUG" -Message $LicenseUtility
            Write-Log -Type "ERROR" -Message "Alteryx $Utility utility could not be located" -ErrorCode 1
        }
    }
}
