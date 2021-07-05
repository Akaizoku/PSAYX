function New-LicenseFile {
    <#
        .SYNOPSIS
        Generate Alteryx license request file

        .DESCRIPTION
        Generate a license request file for Alteryx via the command line utility

        .NOTES
        File name:      New-LicenseFile.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-09
        Last modified:  2021-07-05

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
            HelpMessage = "License key(s)"
        )]
        [ValidatePattern ("^\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}(\s\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4}-\w{4})*$")]
        [Alias (
            "License",
            "Keys"
        )]
        [String]
        $Key,
        [Parameter (
            Position    = 2,
            Mandatory   = $true,
            HelpMessage = "Email address"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.Net.Mail.MailAddress]
        $Email,
        [Parameter (
            Position    = 3,
            Mandatory   = $false,
            HelpMessage = "Path to Alteryx licensing utility"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Path,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Path to license request (.req) file to generate"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $FileName,
        [Parameter (
            HelpMessage = "Switch to suppress log generation"
        )]
        [Switch]
        $Silent
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Define operation
        $Operation = "createRequest"
        # Define parameters
        $Parameters = [System.String]::Concat($Key, ' ', $Email)
        # Check filename
        if ($PSBoundParameters.ContainsKey("FileName")) {
            $Directory = Split-Path -Path $FileName -Parent
            if (Test-Path -Path $Directory) {
                $Parameters = [System.String]::Concat($Parameters, ' "', $FileName, '"')
            } else {
                Write-Log -Type "ERROR" -Message "Directory does not exist: $Directory"
                $DefaultPath = Resolve-Path -Path "$Email.req"
                Write-Log -Type "WARN"  -Message "Reverting to default output path: $DefaultPath"
            }
        }
    }
    Process {
        # Call licensing utility
        $Output = Invoke-LicenseUtility -Path $Path -Operation $Operation -Parameters $Parameters -Silent:$Silent
        # Return output
        return $Output
    }
}