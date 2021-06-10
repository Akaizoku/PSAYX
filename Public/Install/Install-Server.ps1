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
        Last modified:  2021-06-10

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/product-activation-and-licensing/use-command-line-options
    #>
    [CmdletBinding ()]
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
        # Check installer
        if (-Not (Test-Path -Path $Path)) {
            Write-Log -Type "ERROR" -Message "Path not found $Path"
            Write-Log -Type "ERROR" -Message "Alteryx Server installer cannot be located" -ErrorCode 1
        }
        # Define install parameters
        $Parameters = [System.Collections.ArrayList]::new()
    }
    Process {
        # Customer installation directory
        if ($PSBoundParameters.ContainsKey("InstallDirectory")) {
            $Parameters.Add("TARGETDIR='$InstallDirectory'")
            # if (Test-Path -Path $InstallDirectory) {
            #     $Parameters.Add("TARGETDIR='$InstallDirectory'")
            # } else {
            #     Write-Log -Type "ERROR" -Message "Path not found $InstallDirectory"
            #     Write-Log -Type "WARN"  -Message "Reverting to default installation path"
            # }
        }
        # Logs
        if ($PSBoundParameters.ContainsKey("Log")) {
            $Parameters.Add("/l='$Log'")
        }
        # Serial
        if ($PSBoundParameters.ContainsKey("Serial")) {
            $Parameters.Add("SERIAL_NUM='$Serial'")
        }
        # Language
        if ($PSBoundParameters.ContainsKey("Language")) {
            $Parameters.Add("CMD_LANGUAGE='$Language'")
        }
        # System installation
        if ($AllUsers -eq $true) {
            $Parameters.Add("ALLUSERS='TRUE'")
        } else {
            $Parameters.Add("ALLUSERS='FALSE'")
        }
        # Unattended
        if ($PSBoundParameters.ContainsKey("Unattended")) {
            $Parameters.Add("/s")
        }
        # Installation
        $Parameters.Add("REMOVE='FALSE'")
        # Build command
        $Arguments = $Parameters -join " "
        $Command = ("&", """$Path""", $Arguments) -join " "
        Write-Log -Type "DEBUG" -Message $Command
        # Call installer and return output
        $Output = Invoke-Expression -Command $Command | Out-String
        return $Output
    }
}