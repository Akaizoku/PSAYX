function Invoke-ServerAPI {
    <#
        .SYNOPSIS
        Call Alteryx Server API

        .DESCRIPTION
        Call Alteryx Server Gallery API

        .PARAMETER URL
        The URL parameter corresponds to the URL of the Alteryx Gallery to query.


        .NOTES
        File name:      Invoke-API.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-21
        Last modified:  2023-03-23

        .LINK
        https://help.alteryx.com/current/developer-help/gallery-api-overview

        .LINK
        https://documenter.getpostman.com/view/14766220/TzeUmTWD

        .LINK
        https://github.com/Akaizoku/alteryx-api-postman
    #>
    [CmdletBinding (
        SupportsShouldProcess = $true
    )]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "URL of the Alteryx Gallery"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $URL,
        [Parameter (
            Position    = 2,
            Mandatory   = $true,
            HelpMessage = "API endpoint to query"
        )]
        [ValidateSet (
            "Admin",
            "Subscription",
            "User"
        )]
        [Alias ("Endpoint")]
        [System.String]
        $API,
        [Parameter (
            Position    = 3,
            Mandatory   = $true,
            HelpMessage = "Method to call"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $Method,
        [Parameter (
            Position    = 4,
            Mandatory   = $true,
            HelpMessage = "Credentials (API key and secret)"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.Management.Automation.PSCredential]
        $Credentials,
        [Parameter (
            Position    = 5,
            Mandatory   = $false,
            HelpMessage = "Request parameters"
        )]
        [ValidateNotNullOrEmpty ()]
        [System.String]
        $Parameters,
        [Parameter (
            Position    = 6,
            Mandatory   = $false,
            HelpMessage = "API endpoint version"
        )]
        [ValidateNotNullOrEmpty ()]
        [Int32]
        $Version
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Endpoint versions
        $Versions = [Ordered]@{
            "Admin"         = 1,2
            "Subscriptions" = 1
            "User"          = 1
        }
        if ($Version -in $Versions.$Endpoint) {
            $APIEndpoint = "api/$($Endpoint.ToLower())/v$Version"
        }
    }
    Process {
        # Generate request
        $Request = [System.String]::Concat($URL, $APIEndpoint, $Method, $Parameters)
        Write-Log -Type "DEBUG" -Message $Request
        # Call API
        if ($PSCmdlet.ShouldProcess("API", "Call")) {
            $Response = Invoke-WebRequest -URI $Request -Credential $Credentials
            return $Response
        }
    }
}