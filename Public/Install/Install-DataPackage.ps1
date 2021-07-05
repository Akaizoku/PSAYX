function Install-DataPackage {
    <#
        .SYNOPSIS
        Install Alteryx data package

        .DESCRIPTION
        Configure and install Alteryx Server via command-line

        .NOTES
        File name:      Install-DataPackage.ps1
        Author:         Florian Carrier
        Creation date:  2021-07-01
        Last modified:  2021-07-05

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
            Mandatory   = $false,
            HelpMessage = "Action to perform"
        )]
        [ValidateSet (
            "Install",
            "RegisterNetwork",
            "Replace",
            "Uninstall"
        )]
        [String]
        $Action,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx data package installer"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Path,
        [Parameter (
            Position    = 3,
            Mandatory   = $false,
            HelpMessage = "Target installation path"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $InstallDirectory,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Installation log file path"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Log,
        [Parameter (
            HelpMessage = "Switch to prepare a network install"
        )]
        [Switch]
        $PrepareNetwork,
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
            Write-Log -Type "ERROR" -Message "Alteryx data package installer could not be located" -ErrorCode 1
        }
        # Define install parameters
        $Parameters = [System.Collections.ArrayList]::New()
    }
    Process {
        # Action
        if ($PSBoundParameters.ContainsKey("Action")) {
            if ($Action -eq "RegisterNetwork") {
                [Void]$Parameters.Add("/RegisterNetwork")
            } else {
                if ($PSBoundParameters.ContainsKey("Path")) {
                    # TODO add paramtrisation <product>:<dataset name>
                    [Void]$Parameters.Add("/$Action all")
                } else {
                    Write-Log -Type "ERROR" -Message "The path parameter must be provided for the action ""$Action""" -ErrorCode 1
                }
            }
        }
        # Customer installation directory
        if ($PSBoundParameters.ContainsKey("InstallDirectory")) {
            [Void]$Parameters.Add("/Path=""$InstallDirectory""")
            # if (Test-Path -Path $InstallDirectory) {
            #     $Parameters.Add("TARGETDIR='$InstallDirectory'")
            # } else {
            #     Write-Log -Type "ERROR" -Message "Path not found $InstallDirectory"
            #     Write-Log -Type "WARN"  -Message "Reverting to default installation path"
            # }
        }
        # Logs
        if ($PSBoundParameters.ContainsKey("Log")) {
            [Void]$Parameters.Add("/Log=""$Log""")
        }
        # Prepare network
        if ($PrepareNetwork -eq $true) {
            [Void]$Parameters.Add("/PrepareNetwork")
        }
        # Unattended
        if ($PSBoundParameters.ContainsKey("Unattended")) {
            [Void]$Parameters.Add("/s")
        }
        # Build command
        $Arguments = $Parameters -join " "
        $Command = ("&", """$Path""", $Arguments) -join " "
        Write-Log -Type "DEBUG" -Message $Command
        # Call installer and return output
        if ($PSCmdlet.ShouldProcess($Path, $Action)) {
            $Output = Invoke-Expression -Command $Command | Out-String
            # $Output = Start-Process -FilePath $Path -ArgumentList $Arguments -Verb "RunAs" -PassThru -Wait
        } else {
            # Start-Process does not support WhatIf in PowerShell 5.1
            $Output = $Command
        }
        return $Output
    }
}