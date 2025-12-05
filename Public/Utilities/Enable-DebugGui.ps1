function Enable-DebugGui {
    <#
        .SYNOPSIS
        Enable Designer debug menu.

        .DESCRIPTION
        Add or modify the required registry key to enable the display of the debug menu in Designer Desktop 2025.2 and later.

        .NOTES
        File name:      Enable-DebugGui.ps1
        Author:         Florian Carrier
        Creation date:  2025-12-04
        Last modified:  2025-12-05

        .LINK
        https://help.alteryx.com/current/en/developer-help/platform-sdk/legacy-sdks/html-gui-sdk/html-developer-tools.html#id687013
    #>
    [CmdletBinding ()]
    Param (
        [Parameter(
            HelpMessage = "Switch to disable debug menu"
        )]
        [Switch]
        $Disable
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Key value
        if ($Disable) {
            $VerbPast           = "disabled"
            $VerbGerund         = "disabling"
            $RegistryKeyValue   = "0"
        } else {
            $VerbPast           = "enabled"
            $VerbGerund         = "enabling"
            $RegistryKeyValue   = "1"
        }
    } 
    Process {
        try {
            # Define registry root and path
            $RegistryRoot       = [Microsoft.Win32.Registry]::CurrentUser
            $RegistryPath       = "Software\SRC\Alteryx\DebugGui"
            $FullRegistryPath   = [String]::Concat("HKCU:", $RegistryPath)
            # Create or open the key
            $RegistryKey = $RegistryRoot.CreateSubKey(
                $RegistryPath,
                [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree
            )
            Write-Log -Type "INFO"  -Message "$(([System.Globalization.CultureInfo]::CurrentCulture.TextInfo).ToTitleCase($VerbGerund)) debug registry key"
            # Check if key is already set appropriately
            $CurrentValue = $RegistryKey.GetValue(
                $null,  # null = (Default)
                $null   # if missing, return null
            )
            if ($CurrentValue -eq $RegistryKeyValue) {
                Write-Log -Type "WARN"  -Message "Designer debug menu is already $VerbPast"
                Write-Log -Type "DEBUG" -Message "$FullRegistryPath=$CurrentValue"
            } else {
                # Set registry key value
                Write-Log -Type "DEBUG" -Message "$FullRegistryPath=$RegistryKeyValue"
                $RegistryKey.SetValue(
                    $null,                                      # (Default)
                    $RegistryKeyValue,                          # 1 to enable, 0 to disable
                    [Microsoft.Win32.RegistryValueKind]::String # = REG_SZ
                )
                $RegistryKey.Close()
                Write-Log -Type "CHECK" -Message "Designer debug menu successfully $VerbPast"
            }
        }
        catch {
            Write-Error -Message "An error occurred while modifying the registry: $($PSItem.ErrorDetails.Message)"
        }
    }
}