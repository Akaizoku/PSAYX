function Set-Setting {
    <#
        .SYNOPSIS
        Set Alteryx Server setting

        .DESCRIPTION
        Update a specific configuration value for Alteryx Server

        .NOTES
        File name:      Set-Setting.ps1
        Author:         Florian Carrier
        Creation date:  2021-09-20
        Last modified:  2021-09-20
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Root of the setting to update (XML node)"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $Root,
        [Parameter (
            Position    = 2,
            Mandatory   = $true,
            HelpMessage = "Name of the setting to update (XML node)"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $Name,
        [Parameter (
            Position    = 3,
            Mandatory   = $true,
            HelpMessage = "Value of the setting to update"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $Value,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx Service executable"
        )]
        [ValidateNotNullOrEmpty ()]
        [Alias ("ServicePath")]
        [String]
        $Path
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Utility path
        if ($PSBoundParameters.ContainsKey("Path")) {
            if (Test-Object -Path $Path -NotFound) {
                Write-Log -Type "ERROR" -Message "Path not found $Path" -ExitCode 1
            }
        } else {
            $Path = Get-Utility -Utility "Service"
        }
    }
    Process {
        # Define operation
        $Operation = "setting"
        # Build parameter string
        $Parameter = @($Root, $Name, $Value) -join ","
        # Call utility
        $Output = Invoke-Service -Path $Path -Operation $Operation -Parameter $Parameter -WhatIf:$WhatIfPreference
        return $Output
    }
}