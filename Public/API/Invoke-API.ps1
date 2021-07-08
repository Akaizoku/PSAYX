function Invoke-API {
    <#
        .SYNOPSIS
        Call Alteryx API

        .DESCRIPTION
        Call Alteryx Server Gallery API

        .PARAMETER URL
        The URL parameter corresponds to the URL of the Alteryx Gallery to query.

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
        File name:      Invoke-API.ps1
        Author:         Florian Carrier
        Creation date:  2021-06-21
        Last modified:  2021-06-21

        .LINK
        https://help.alteryx.com/current/developer-help/gallery-api-overview

        .LINK
        https://documenter.getpostman.com/view/14766220/TzeUmTWD

        .LINK
        https://github.com/Akaizoku/alteryx-api-postman
    #>
    [CmdletBinding ()]
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
            "Admin V1",
            "Admin V2",
            "Subscription",
            "user V2"
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
        $Parameters
    )
    Begin {
        $Request = [System.String]::Concat($URL, $Endpoint, $Method, $Parameters)
    }
    Process {
        Invoke-WebRequest -URI $Request -Credential $Credentials
    }
}