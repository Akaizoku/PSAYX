function Install-Server {
    <#
        .SYNOPSIS
        Install Alteryx Server

        .DESCRIPTION
        Configure and install Alteryx Server via command-line

        .NOTES
        File name:      Install-Server.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-10
        Last modified:  2021-07-08

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
        [String]
        $Path,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Target installation path"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $InstallDirectory,
        [Parameter (
            Position    = 3,
            Mandatory   = $false,
            HelpMessage = "Installation log file path"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Log,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Serial number (email address)"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("Email")]
        [String]
        $Serial,
        [Parameter (
            Position    = 5,
            Mandatory   = $false,
            HelpMessage = "Language of the install"
        )]
        [ValidateSet (
            "Deutsch",
            "English",
            "Español",
            "Français",
            "Japanese",
            "Português"
        )]
        [Alias ("Locale")]
        [String]
        $Language,
        [Parameter (
            HelpMessage = "Switch to install for all users"
        )]
        [Switch]
        $AllUsers,
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
        $Parameters = [System.Collections.ArrayList]::New()
    }
    Process {
        # Customer installation directory
        if ($PSBoundParameters.ContainsKey("InstallDirectory")) {
            [Void]$Parameters.Add("TARGETDIR=""$InstallDirectory""")
            # TODO ensure installation path is accessible
            # if (Test-Path -Path $InstallDirectory) {
            #     [Void]$Parameters.Add("TARGETDIR=""$InstallDirectory""")
            # } else {
            #     Write-Log -Type "ERROR" -Message "Path not found $InstallDirectory"
            #     Write-Log -Type "WARN"  -Message "Reverting to default installation path"
            # }
        }
        # Logs
        if ($PSBoundParameters.ContainsKey("Log")) {
            [Void]$Parameters.Add("/l=""$Log""")
        }
        # Serial
        if ($PSBoundParameters.ContainsKey("Serial")) {
            [Void]$Parameters.Add("SERIAL_NUM=""$Serial""")
        }
        # Language
        if ($PSBoundParameters.ContainsKey("Language")) {
            [Void]$Parameters.Add("CMD_LANGUAGE=""$Language""")
        }
        # System installation
        if ($AllUsers -eq $true) {
            [Void]$Parameters.Add("ALLUSERS=""TRUE""")
        } else {
            [Void]$Parameters.Add("ALLUSERS=""FALSE""")
        }
        # Unattended
        if ($Unattended -eq $true) {
            [Void]$Parameters.Add("/s")
        }
        # Installation
        [Void]$Parameters.Add("REMOVE=""FALSE""")
        # Build argument list and command for debug
        $Arguments = $Parameters -join " "
        $Command = ("&", """$Path""", $Arguments) -join " "
        Write-Log -Type "DEBUG" -Message $Command
        # Call installer and return process
        if ($PSCmdlet.ShouldProcess($Path, "Install")) {
            $Process = Start-Process -FilePath $Path -ArgumentList $Arguments -Verb "RunAs" -PassThru -Wait
        } else {
            # Return dummy process
            $Process = New-Object -TypeName "System.Diagnostics.Process"
        }
        return $Process
    }
}