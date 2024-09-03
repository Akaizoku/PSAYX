function Get-ProductReleases {
    <#
        .SYNOPSIS
        Find all releases for the provided product line.

        .DESCRIPTION
        Find all releases for the provided product line that the current authenticated user can access under the account whose ID is accountId.
        
        .NOTES
        File name:      Get-ProductReleases.ps1
        Author:         Florian Carrier
        Creation date:  2024-09-03
        Last modified:  2024-09-03

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
        $Token,
        [Parameter (
            Position    = 3,
            Mandatory   = $true,
            HelpMessage = "Alteryx product ID"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("Product", "ProductLineID")]
        $ProductID
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Define parameters
        $Parameters = [Ordered]@{
            "productLineId" = $ProductID
        }
    }
    Process {
        # Fetch list of releases
        $Releases = Invoke-AlteryxLicenseAPI -Token $AccessToken -Endpoint "v1/products/-/releases" -AccountID $AccountID -Parameters $Parameters
        # Sort releases by version number
        $SortedReleases = ($Releases | ConvertFrom-Json) | Sort-Object -Property "version" -Descending
        # Return ordered list of releases
        return $SortedReleases
    }
}