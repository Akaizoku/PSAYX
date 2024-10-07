function Uninstall-Server {
    <#
        .SYNOPSIS
        Uninstall Alteryx Server

        .DESCRIPTION
        Uninstall Alteryx Server and its components via command-line

        .NOTES
        File name:      Uninstall-Server.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-10
        Last modified:  2023-01-17

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/product-activation-and-licensing/use-command-line-options
    #>
    [CmdletBinding (
        SupportsShouldProcess = $true
    )]
    # Inputs
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to Alteryx Server installer"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.IO.FileInfo]
        $Path,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Uninstallation log file path"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Log,
        [Parameter (
            Position    = 3,
            Mandatory   = $false,
            HelpMessage = "Version to install"
        )]
        [String]
        $Version,
        [Parameter (
            HelpMessage = "Switch to suppress all dialogs"
        )]
        [Switch]
        $Unattended,
        [Parameter (
            HelpMessage = "Switch to suppress non-critical messages"
        )]
        [Switch]
        $Silent
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Check installer
        if (-Not (Test-Path -Path $Path)) {
            Write-Log -Type "ERROR" -Message "Path not found $Path"
            Write-Log -Type "ERROR" -Message "Alteryx Server installer cannot be located" -ErrorCode 1
        }
        # Define install parameters
        $Parameters = [System.Collections.ArrayList]::new()
    }
    Process {
        # TODO addd check for previous installation
        if (Compare-Version -Version $Version -Operator "ge" -Reference "2022.3") { # New command-line parameters
            # Uninstallation
            [Void]$Parameters.Add("-x")
            # Custom installation directory
            if ($PSBoundParameters.ContainsKey("InstallDirectory")) {
                [Void]$Parameters.Add("-d ""$InstallDirectory""")
            }
            # Logs
            if ($PSBoundParameters.ContainsKey("Log")) {
                [Void]$Parameters.Add("-l ""$Log""")
                # MSI log file
                # [Void]$Parameters.Add("-m ""$Log""")
            }
            # Unattended
            if ($Unattended -eq $true) {
                [Void]$Parameters.Add("-s")
            }
        } else { # Legacy command-line parameters
            # Uninstallation
            [Void]$Parameters.Add("REMOVE=""TRUE""")
            # Logs
            if ($PSBoundParameters.ContainsKey("Log")) {
                [Void]$Parameters.Add("/l=""$Log""")
            }
            # Unattended
            if ($Unattended -eq $true) {
                [Void]$Parameters.Add("/s")
            }
        }
        # Build argument list and command for debug
        $Arguments = $Parameters -join " "
        $Command = ("&", """$Path""", $Arguments) -join " "
        Write-Log -Type "DEBUG" -Message $Command
        # Call installer and return process
        if ($PSCmdlet.ShouldProcess($Path, "Uninstall")) {
            $Process = Start-Process -FilePath $Path -ArgumentList $Arguments -Verb "RunAs" -PassThru -Wait
            # Prevent missing exit code in output
            $Process.WaitForExit()
        } else {
            # Return dummy process
            $Process = New-Object -TypeName "System.Diagnostics.Process"
        }
        return $Process
    }
}