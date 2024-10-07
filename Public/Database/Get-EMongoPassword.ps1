function Get-EMongoPassword {
    <#
        .SYNOPSIS
        Get embedded MongoDB password

        .DESCRIPTION
        Returns embedded MongoDB database user and admin passwords

        .NOTES
        File name:      Get-EMongoPassword.ps1
        Author:         Florian Carrier
        Creation date:  2022-01-21
        Last modified:  2022-01-31
        Comments:       - Requires Administrator-level access.
                        - Only works with embedded MongoDB instances.
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $false,
            HelpMessage = "Hostname or IP address"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $Hostname,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Port"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.Int16]
        $Port,
        [Parameter (
            Position    = 3,
            Mandatory   = $false,
            HelpMessage = "Secret"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $Secret,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx Service executable"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.IO.FileInfo]
        $ServicePath
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Utility path
        if ($PSBoundParameters.ContainsKey("ServicePath")) {
            if (Test-Object -Path $ServicePath -NotFound) {
                Write-Log -Type "ERROR" -Message "Path not found $ServicePath" -ExitCode 1
            }
        } else {
            $ServicePath = Get-Utility -Utility "Service"
        }
    }
    Process {
        # Define operation
        $Operation = "getemongopassword"
        # Define parameter
        $Parameter = $null
        if ($PSBoundParameters.ContainsKey("Hostname")) {
            $Parameter = $Hostname
            if ($PSBoundParameters.ContainsKey("Port")) {
                $Parameter += ":" + $Port
            }
            if ($PSBoundParameters.ContainsKey("Secret")) {
                $Parameter += "," + $Secret
            }
        }
        # Call utility
        if ($null -eq $Parameter) {
            $Output = Invoke-Service -Path $ServicePath -Operation $Operation -WhatIf:$WhatIfPreference
        } else {
            $Output = Invoke-Service -Path $ServicePath -Operation $Operation -Parameter $Parameter -WhatIf:$WhatIfPreference
        }
        return $Output
    }
}