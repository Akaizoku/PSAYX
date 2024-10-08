function Get-LicensedProducts {
    <#
        .SYNOPSIS
        Fetch list of licensed products

        .DESCRIPTION
        Retrieves the list of products associated with a specified account from Alteryx License Portal

        .NOTES
        File name:      Get-LicensedProducts.ps1
        Author:         Florian Carrier
        Creation date:  2024-08-22
        Last modified:  2024-10-08

        .LINK
        https://us1.alteryxcloud.com/license-portal/api/swagger-ui/index.html
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Alteryx Account ID"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("Account")]
        $AccountID,
        [Parameter (
            Position    = 2,
            Mandatory   = $true,
            HelpMessage = "Access token"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("AccessToken")]
        $Token
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Log function call
        Write-Log -Type "DEBUG" -Message $MyInvocation.MyCommand.Name
    }
    Process {
        $Products = Invoke-AlteryxLicenseAPI -Token $Token -Endpoint "v1/products" -AccountID $AccountID
        return ($Products | ConvertFrom-Json)
    }
}