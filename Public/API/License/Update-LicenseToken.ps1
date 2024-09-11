function Update-LicenseToken {
    <#
        .SYNOPSIS
        Refresh access token

        .DESCRIPTION
        Get a new access tokens using the refresh token

        .NOTES
        File name:      Update-Token.ps1
        Author:         Florian Carrier
        Creation date:  2023-03-23
        Last modified:  2024-08-22

        .LINK
        https://us1.alteryxcloud.com/license-portal/api/swagger-ui/index.html
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Refresh token"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("RefreshToken")]
        $Token,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Requested token type"
        )]
        [ValidateSet(
            "Access",
            "Token"
        )]
        [System.String]
        $Type
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Log function call
        Write-Log -Type "DEBUG" -Message $MyInvocation.MyCommand.Name
        # Configuration
        $URI = "https://myalteryxsso.b2clogin.com/myalteryxsso.onmicrosoft.com/b2c_1a_signup_signin_flexera_cli/oauth2/v2.0/token"
        $Headers = [Ordered]@{
            "Content-Type"  = "application/x-www-form-urlencoded"
        }
        $Body = [Ordered]@{
            "grant_type"    = "refresh_token"
        }
    }
    Process {
        # Add refresh token to body
        $Body.Add("refresh_token", $Token)
        # Make API call
        $Tokens = Invoke-RestMethod -Method "POST" -URI $URI -Headers $Headers -Body $Body
        # Write-Log -Type "DEBUG" -Message $Tokens
        # Return requested tokens
        switch ($Type) {
            "Access"    { $Output = $Tokens.access_token    }
            "Refresh"   { $Output = $Tokens.refresh_token   }
            default     { $Output = $Tokens                 }
        }
        return $Output
    }
}