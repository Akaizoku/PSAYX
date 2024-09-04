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
        Last modified:  2024-08-22

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
    }
    Process {
        $Products = Invoke-AlteryxLicenseAPI -Token $AccessToken -Endpoint "v1/products" -AccountID $AccountID
        return ($Products | ConvertFrom-Json)
    }
}