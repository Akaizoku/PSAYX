function Invoke-LicenseAPI {
    <#
        .SYNOPSIS
        Call Alteryx licenses API

        .DESCRIPTION
        This function handles API calls to Alteryx license portal

        .NOTES
        File name:      Invoke-LicenseAPI.ps1
        Author:         Florian Carrier
        Creation date:  2024-08-20
        Last modified:  2024-09-04

        .LINK
        https://us1.alteryxcloud.com/license-portal/api/swagger-ui/index.html
    #>
    [CmdletBinding ()]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Access token"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("AccessToken")]
        $Token,
        [Parameter (
            Position    = 2,
            Mandatory   = $true,
            HelpMessage = "API endpoint"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $Endpoint,
        [Parameter (
            Position    = 3,
            Mandatory   = $true,
            HelpMessage = "Alteryx Account ID"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        [Alias ("Account")]
        $AccountID,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Optional endpoint parameters"
        )]
        # [ValidateNotNullOrEmpty ()]
        [System.Collections.Specialized.OrderedDictionary]
        $Parameters
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # API base URL
        $API = "https://us1.alteryxcloud.com/license-portal/api"
        # API call headers
        $Headers = [Ordered]@{
            "accept"        = "application/json"
            "Authorization" = "Bearer " + $Token
        }
        Write-Log -Type "DEBUG" -Message $Headers
        # Parameters
        if ($PSBoundParameters.ContainsKey("Parameters")) {
            if ($Parameters.Contains("AccountID")) {
                if ($Parameters.("accountId") -ne $AccountID) {
                    Write-Log -Type "WARN" -Message "Specified account does not match the value specified in the parameters"
                    # Overwrite account value
                    Write-Log -Type "WARN" -Message "Overriding parameter with account $Account"
                    $Parameters.("accountId") = $AccountID
                }
            } else {
                $Parameters.Add("accountId", $AccountID)
            }
        } else {
            $Parameters = [Ordered]@{
                "accountId" = $AccountID
            }
        }
    }
    Process {
        # Encode parameters
        $EncodedParameters = ($Parameters.GetEnumerator() | ForEach-Object { "$($PSItem.Name)=$([URI]::EscapeDataString($PSItem.Value))"}) -join "&"
        # Build full URI
        $URI = [String]::Concat($API, "/", $Endpoint, "?", $EncodedParameters)
        Write-Log -Type "DEBUG" -Message $URI
        # Make API call
        $Response = Invoke-RestMethod -Method "GET" -URI $URI -Headers $Headers
        # Parse and return output
        $JSON = $Response.data | ConvertTo-Json
        Write-Log -Type "DEBUG" -Message $JSON
        return $JSON
    }
}