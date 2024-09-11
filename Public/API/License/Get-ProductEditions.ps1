function Get-ProductEditions {
    <#
        .SYNOPSIS
        Find all download editions for the provided product line's release.

        .DESCRIPTION
        Find all download editions for the provided product line's release that the current authenticated user can access under the account whose ID is accountId. 
        
        .NOTES
        File name:      Get-ProductEditions.ps1
        Author:         Florian Carrier
        Creation date:  2024-09-03
        Last modified:  2024-09-04

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
            HelpMessage = "Alteryx product release ID"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("Release", "productLineReleaseId")]
        $ReleaseID
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Log function call
        Write-Log -Type "DEBUG" -Message $MyInvocation.MyCommand.Name
        # Define parameters
        $Parameters = [Ordered]@{
            "productLineReleaseId" = $ReleaseID
        }
    }
    Process {
        # Fetch list of releases
        $Editions = Invoke-AlteryxLicenseAPI -Token $Token -Endpoint "v1/products/-/releases/-/editions" -AccountID $AccountID -Parameters $Parameters
        # Sort editions in alphabetic order
        $SortedEditions = ($Editions | ConvertFrom-Json) | Sort-Object -Property "description"
        # Return list of editions
        return $SortedEditions
    }
}