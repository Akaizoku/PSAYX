function Get-InstallDirectory {
    <#
        .SYNOPSIS
        Retrieve Alteryx installation directory

        .DESCRIPTION
        Search registry for the path to Alteryx installation directory

        .NOTES
        File name:      Get-InstallDirectory.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-05
        Last modified:  2021-09-16

        .LINK
        https://www.powershellgallery.com/packages/PSAYX
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $false,
            HelpMessage = "Alteryx product"
        )]
        [ValidateSet (
            "Designer",
            "Server"
        )]
        [System.String]
        $Product,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Alteryx version"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.Version]
        $Version
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Registry keys
        $Registry = [Ordered]@{
            "Designer"  = "HKLM:HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Alteryx <Version> x64"
            "Server"    = "HKLM:HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Alteryx <Version> x64 Server"
        }
    }
    Process {
        # Version
        if ($PSBoundParameters.ContainsKey("Version")) {
            $Version = @($Version.Major, $Version.Minor) -join "."
        } else {
            $Version = Get-AlteryxRegistryVersion
        }
        # Restrict to specified product if applicable
        if ($PSBoundParameters.ContainsKey("Product")) {
            $TmpKey = $Registry.$Product
            $Registry.Clear()
            $Registry.Add($Product, $TmpKey)
        }
        # Loop through products
        foreach ($Key in $Registry.GetEnumerator()) {
            # Update version in registry address
            $RegistryKey = Set-Tags -String $Key.Value -Tags (Resolve-Tags -Tags ([Ordered]@{"Version"=$Version}) -Prefix "<" -Suffix ">")
            # Retrieve Alteryx installation directory from registry
            if (Test-Object -Path $RegistryKey) {
                $InstallDirectory = (Get-ItemProperty -Path $RegistryKey).InstallLocation
                if ($null -eq $InstallDirectory) {
                    Write-Log -Type "WARN"  -Message "InstallLocation registry entry is missing"
                } else {
                    return $InstallDirectory
                }
            }
        }
        Write-Log -Type "ERROR" -Message "Alteryx $($Key.Name) installation location could not be retrieved from registry" -ExitCode 1
    }
}
