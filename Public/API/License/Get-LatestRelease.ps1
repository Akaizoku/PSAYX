function Get-LatestRelease {
    <#
        .SYNOPSIS
        Fetch latest product release

        .DESCRIPTION
        Retrieves the latest version available for a specified product and provides the direct download link
        
        .NOTES
        File name:      Get-LatestRelease.ps1
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
        # Response object
        $Response = New-Object -TypeName "System.Collections.Specialized.OrderedDictionary"
        $Response.Add("Product", $ProductID)
    }
    Process {
        # Fetch latest release version
        $Release = Get-AlteryxProductReleases -AccountID $AccountID -Token $AccessToken -ProductID $ProductID | Select-Object -First 1
        # Parse release date
        $Response.Add("Date", $Release.releaseDate)
        # Fetch corresponding product installer download URL
        $Installer = Get-AlteryxProductEditions -AccountID $AccountID -Token $AccessToken -ReleaseID $Release.id | Where-Object -Property "description" -EQ -Value $ProductID
        # Parse complete version number
        if ($Installer.downloadLink -match '_(\d+\.\d+(\.\d+)?(\.\d+)?(\.\d+)?)\.exe') {
            $Version = $matches[1]
        } else {
            $Version = $Release.version
        }
        $Response.Add("Version", $Version)
        # Expose direct download link
        $Response.Add("URL", $Installer.downloadLink)
        # Return formatted response object
        return $Response
    }
}