function Get-ServerProcess {
    <#
        .SYNOPSIS
        Retrieve Alteryx Server process path

        .DESCRIPTION
        Retrieve path to Alteryx Server processes

        .NOTES
        File name:      Get-ServerProcess.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-10
        Last modified:  2021-09-20

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/server/server-processes-reference
    #>
    [CmdletBinding ()]
    # Inputs
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Process"
        )]
        [ValidateSet (
            "Gui",
            "EngineCmd",
            "CEFRenderer",
            "Service",
            "ServerHost",
            "AuthHost",
            "MapRenderWorker",
            "MongoController",
            "WebInterface",
            "Metrics",
            "Database"
        )]
        [String]
        $Process,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx install directory"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $InstallDirectory
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Processes
        switch ($Process) {
            "Gui"               { $Executable = "AlteryxGui.exe"                        }
            "EngineCmd"         { $Executable = "AlteryxEngineCmd.exe"                  }
            "CEFRenderer"       { $Executable = "AlteryxCEFRenderer.exe"                }
            "Service"           { $Executable = "AlteryxService.exe"                    }
            "ServerHost"        { $Executable = "AlteryxServerHost.exe"                 }
            "AuthHost"          { $Executable = "AlteryxAuthHost.exe"                   }
            "MapRenderWorker"   { $Executable = "AlteryxService_MapRenderWorker.exe"    }
            "MongoController"   { $Executable = "AlteryxService_MongoController.exe"    }
            "WebInterface"      { $Executable = "AlteryxService_WebInterface.exe"       }
            "Metrics"           { $Executable = "AlteryxMetrics.exe"                    }
            "Database"          { $Executable = "mongod.exe"                            }
        }
    }
    Process {
        # Retrieve Alteryx installation directory
        if ($PSBoundParameters.ContainsKey("InstallDirectory")) {
            if (Test-Object -Path $InstallDirectory -NotFound) {
                Write-Log -Type "ERROR" -Message "Path not found $InstallDirectory"
                Write-Log -Type "WARN"  -Message "Reverting to installation directory from registry"
                $InstallDirectory = Get-InstallDirectory
            }
        } else {
            $InstallDirectory = Get-InstallDirectory
        }
        # Build and validate path
        if ($InstallDirectory -match "\\bin\\?$") {
            $Path = Join-Path -Path $InstallDirectory -ChildPath $Executable
        } else {
            $Path = Join-Path -Path $InstallDirectory -ChildPath "bin\$Executable"
        }
        if (Test-Object -Path $Path) {
            return $Path
        } else {
            Write-Log -Type "DEBUG" -Message $Path
            Write-Log -Type "ERROR" -Message "Alteryx $Process process could not be found" -ErrorCode 1
        }
    }
}