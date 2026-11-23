function Get-StarterKits {
    <#
        .SYNOPSIS
        Discover and download Alteryx Starter Kits.

        .DESCRIPTION
        Lists Alteryx Starter Kits from the public Starter Kit library and, unless
        ListOnly is specified, downloads each kit to a target folder. The function
        follows the library pagination, reads each kit detail page, and resolves the
        direct YXI download URL when available.

        .PARAMETER Path
        Target folder where Starter Kit YXI files will be downloaded. Required
        unless ListOnly is specified.

        .PARAMETER Uri
        Starter Kit library URL.

        .PARAMETER ListOnly
        Return available Starter Kits without downloading files.

        .PARAMETER Force
        Overwrite existing downloaded files.

        .PARAMETER TimeoutSec
        Web request timeout in seconds.

        .PARAMETER ThrottleMilliseconds
        Delay between web requests in milliseconds.

        .EXAMPLE
        Get-AlteryxStarterKits -ListOnly

        Lists available Starter Kits and their download URLs.

        .EXAMPLE
        Get-AlteryxStarterKits -Path "C:\StarterKits"

        Downloads all available Starter Kits to C:\StarterKits.

        .NOTES
        File name:      Get-StarterKits.ps1
        Author:         Florian Carrier
        Creation date:  2026-06-01
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $false,
            HelpMessage = "Target folder where Starter Kit YXI files will be downloaded"
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter (
            Mandatory   = $false,
            HelpMessage = "Starter Kit library URL"
        )]
        [ValidateNotNullOrEmpty()]
        [System.Uri]
        $Uri = "https://www.alteryx.com/starter-kit",

        [Parameter (
            Mandatory   = $false,
            HelpMessage = "Web request timeout in seconds"
        )]
        [ValidateRange(1, 600)]
        [System.Int32]
        $TimeoutSec = 60,

        [Parameter (
            Mandatory   = $false,
            HelpMessage = "Delay between web requests in milliseconds"
        )]
        [ValidateRange(0, 60000)]
        [System.Int32]
        $ThrottleMilliseconds = 250,

        [Parameter (
            HelpMessage = "Return available Starter Kits without downloading files"
        )]
        [Switch]
        $ListOnly,

        [Parameter (
            HelpMessage = "Overwrite existing downloaded files"
        )]
        [Switch]
        $Force
    )

    Begin {
        # Get global preference variables.
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        Write-Log -Type "NOTICE" -Message "Get-StarterKits: discover and download Alteryx Starter Kits"

        $UserAgent = "PSAYX Starter Kit Downloader"
        $Results = [System.Collections.Generic.List[System.Object]]::new()
        $VisitedPages = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $SeenKitPages = [System.Collections.Generic.HashSet[System.String]]::new([System.StringComparer]::OrdinalIgnoreCase)

        function Get-WordForm {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [System.Int32]
                $Count,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $Singular,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $Plural
            )

            if ($Count -eq 1) {
                return $Singular
            }

            return $Plural
        }

        function ConvertTo-SafeFileName {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $Name
            )

            $InvalidCharacters = [System.IO.Path]::GetInvalidFileNameChars()
            $SafeName = $Name
            foreach ($InvalidCharacter in $InvalidCharacters) {
                $SafeName = $SafeName.Replace($InvalidCharacter, "-")
            }

            $SafeName = $SafeName -replace "\s+", " "
            $SafeName = $SafeName.Trim(" .-")

            if ([System.String]::IsNullOrWhiteSpace($SafeName)) {
                return "starter-kit"
            }

            return $SafeName
        }

        function Resolve-StarterKitUri {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                [System.Uri]
                $BaseUri,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $Link
            )

            $DecodedLink = [System.Net.WebUtility]::HtmlDecode($Link)
            return [System.Uri]::new($BaseUri, $DecodedLink).AbsoluteUri
        }

        function Invoke-StarterKitWebRequest {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $RequestUri,

                [Parameter(Mandatory = $false)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $OutFile
            )

            $Parameters = @{
                ErrorAction = "Stop"
                Headers     = @{
                    "User-Agent" = $UserAgent
                }
                TimeoutSec  = $TimeoutSec
                Uri         = $RequestUri
                Debug       = $false
                Verbose     = $false
            }

            if ($PSBoundParameters.ContainsKey("OutFile")) {
                $Parameters.OutFile = $OutFile
            } else {
                $Parameters.UseBasicParsing = $true
            }

            return Invoke-WebRequest @Parameters
        }

        function Get-StarterKitArchiveLinks {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $Html
            )

            $Pattern = '<a\b(?=[^>]*\bclass="[^"]*\blink\b[^"]*")(?=[^>]*\bhref="([^"]+/starter-kit/[^"]+)")(?=[^>]*\baria-label="click to visit ([^"]+)")[^>]*>'
            $Matches = [System.Text.RegularExpressions.Regex]::Matches(
                $Html,
                $Pattern,
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )

            foreach ($Match in $Matches) {
                $PageUri = [System.Net.WebUtility]::HtmlDecode($Match.Groups[1].Value)
                $Name = [System.Net.WebUtility]::HtmlDecode($Match.Groups[2].Value)
                $Name = $Name -replace "^click to visit\s+", ""

                [PSCustomObject]@{
                    Name    = $Name.Trim()
                    PageUri = $PageUri
                }
            }
        }

        function Get-StarterKitNextPageUri {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $Html,

                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                [System.Uri]
                $CurrentUri
            )

            $Pattern = '<a[^>]+href="([^"]+)"[^>]*>\s*Load More\s*</a>'
            $Match = [System.Text.RegularExpressions.Regex]::Match(
                $Html,
                $Pattern,
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )

            if (-Not $Match.Success) {
                return $null
            }

            return Resolve-StarterKitUri -BaseUri $CurrentUri -Link $Match.Groups[1].Value
        }

        function Get-StarterKitDownloadUri {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $Html,

                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                [System.Uri]
                $PageUri
            )

            $DirectPattern = '<a[^>]+href="([^"]+\.yxi(?:\?[^"]*)?)"[^>]*>'
            $DirectMatch = [System.Text.RegularExpressions.Regex]::Match(
                $Html,
                $DirectPattern,
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )

            if ($DirectMatch.Success) {
                return Resolve-StarterKitUri -BaseUri $PageUri -Link $DirectMatch.Groups[1].Value
            }

            $BridgePattern = "downloadBridgeUrl\s*=\s*['""]([^'""]*starter_kit_download=[^'""]+)['""]"
            $BridgeMatch = [System.Text.RegularExpressions.Regex]::Match(
                $Html,
                $BridgePattern,
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )

            if ($BridgeMatch.Success) {
                return Resolve-StarterKitUri -BaseUri $PageUri -Link $BridgeMatch.Groups[1].Value
            }

            $HrefPattern = '<a[^>]+href="([^"]*starter_kit_download=[^"]+)"[^>]*>'
            $HrefMatch = [System.Text.RegularExpressions.Regex]::Match(
                $Html,
                $HrefPattern,
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )

            if ($HrefMatch.Success) {
                return Resolve-StarterKitUri -BaseUri $PageUri -Link $HrefMatch.Groups[1].Value
            }

            return $null
        }

        function Get-StarterKitFileName {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $Name,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $DownloadUri
            )

            $DownloadUriObject = [System.Uri]$DownloadUri
            $Leaf = [System.IO.Path]::GetFileName($DownloadUriObject.AbsolutePath)

            if (-Not [System.String]::IsNullOrWhiteSpace($Leaf) -And $Leaf -like "*.yxi") {
                return [System.Net.WebUtility]::UrlDecode($Leaf)
            }

            return [System.String]::Concat((ConvertTo-SafeFileName -Name $Name), ".yxi")
        }

        if (-Not $ListOnly -And -Not $PSBoundParameters.ContainsKey("Path")) {
            Write-Log -Type "ERROR" -Message "Path is required unless ListOnly is specified"
            throw "Path is required unless ListOnly is specified."
        }

        if (-Not $ListOnly) {
            if ((Test-Path -LiteralPath $Path) -And -Not (Test-Path -LiteralPath $Path -PathType Container)) {
                Write-Log -Type "ERROR" -Message "Path exists but is not a directory: ${Path}"
                throw "Path exists but is not a directory: ${Path}"
            }

            if (-Not (Test-Path -LiteralPath $Path)) {
                if ($PSCmdlet.ShouldProcess($Path, "Create Starter Kit download directory")) {
                    New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction Stop | Out-Null
                }
            }

            if (Test-Path -LiteralPath $Path) {
                $ResolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
            } else {
                $ResolvedPath = [System.IO.Path]::GetFullPath($Path)
            }
        } else {
            $ResolvedPath = $null
        }

        $ListedCount = 0
        $DownloadedCount = 0
        $Pagination = 0
    }

    Process {
        try {
            $NextPageUri = $Uri.AbsoluteUri

            while (-Not [System.String]::IsNullOrWhiteSpace($NextPageUri) -And $VisitedPages.Add($NextPageUri)) {
                $Pagination++
                Write-Log -Type "INFO" -Message "Discovering Starter Kits page ${Pagination}"
                $ArchiveResponse = Invoke-StarterKitWebRequest -RequestUri $NextPageUri
                $ArchiveLinks = Get-StarterKitArchiveLinks -Html $ArchiveResponse.Content

                foreach ($ArchiveLink in $ArchiveLinks) {
                    if ($SeenKitPages.Add($ArchiveLink.PageUri)) {
                        $Status = "Discovered"
                        $DownloadUri = $null
                        $FilePath = $null

                        try {
                            $DetailResponse = Invoke-StarterKitWebRequest -RequestUri $ArchiveLink.PageUri
                            $DownloadUri = Get-StarterKitDownloadUri -Html $DetailResponse.Content -PageUri ([System.Uri]$ArchiveLink.PageUri)

                            if ([System.String]::IsNullOrWhiteSpace($DownloadUri)) {
                                Write-Log -Type "WARN" -Message "Download URL could not be found for '$($ArchiveLink.Name)'"
                                $Status = "MissingDownloadUrl"
                            } elseif (-Not $ListOnly) {
                                $FileName = Get-StarterKitFileName -Name $ArchiveLink.Name -DownloadUri $DownloadUri
                                $FilePath = Join-Path -Path $ResolvedPath -ChildPath $FileName

                                if ((Test-Path -LiteralPath $FilePath) -And -Not $Force) {
                                    Write-Log -Type "WARN" -Message "Skipping existing file '${FilePath}'"
                                    $Status = "SkippedExisting"
                                } elseif ($PSCmdlet.ShouldProcess($FilePath, "Download Starter Kit '$($ArchiveLink.Name)'")) {
                                    Write-Log -Type "INFO" -Message "Downloading '$($ArchiveLink.Name)'"
                                    Invoke-StarterKitWebRequest -RequestUri $DownloadUri -OutFile $FilePath | Out-Null
                                    $Status = "Downloaded"
                                    $DownloadedCount++
                                } else {
                                    $Status = "Planned"
                                }
                            }
                        } catch {
                            Write-Log -Type "ERROR" -Message "Failed to process Starter Kit '$($ArchiveLink.Name)'"
                            Write-Log -Type "ERROR" -Message $PSItem.Exception.Message
                            $Status = "Error"
                        }

                        $ListedCount++
                        Write-Debug -Message "${ListedCount}, ${Pagination}, $($ArchiveLink.Name), $($ArchiveLink.PageUri), ${DownloadUri}"

                        $Results.Add(
                            [PSCustomObject]@{
                                Name        = $ArchiveLink.Name
                                URL         = $ArchiveLink.PageUri
                                DownloadURL = $DownloadUri
                                Path        = $FilePath
                                Status      = $Status
                            }
                        )
                    }
                }

                $NextPageUri = Get-StarterKitNextPageUri -Html $ArchiveResponse.Content -CurrentUri ([System.Uri]$NextPageUri)

                if ($ThrottleMilliseconds -gt 0) {
                    Start-Sleep -Milliseconds $ThrottleMilliseconds
                }
            }

            $SortedResults = $Results | Sort-Object -Property "Name"
            $ListedCount = $SortedResults.Count
            $SortedResults | Format-Table -Property "Name", "URL", "DownloadURL", "Path", "Status" -AutoSize

            if ($ListOnly) {
                $ListedNoun = Get-WordForm -Count $ListedCount -Singular "Starter Kit" -Plural "Starter Kits"
                Write-Log -Type "CHECK" -Message "Starter Kit discovery completed: ${ListedCount} ${ListedNoun} listed"
            } else {
                $DownloadedNoun = Get-WordForm -Count $DownloadedCount -Singular "Starter Kit" -Plural "Starter Kits"
                $ListedNoun = Get-WordForm -Count $ListedCount -Singular "Starter Kit" -Plural "Starter Kits"
                Write-Log -Type "CHECK" -Message "Starter Kit download completed: ${DownloadedCount} ${DownloadedNoun} downloaded, ${ListedCount} ${ListedNoun} listed"
            }
        } catch {
            Write-Log -Type "ERROR" -Message "Starter Kit processing failed"
            Write-Log -Type "ERROR" -Message $PSItem.Exception.Message
            if ($ListOnly) {
                $ListedNoun = Get-WordForm -Count $ListedCount -Singular "Starter Kit" -Plural "Starter Kits"
                Write-Log -Type "ERROR" -Message "Starter Kit discovery failed: ${ListedCount} ${ListedNoun} listed"
            } else {
                $DownloadedNoun = Get-WordForm -Count $DownloadedCount -Singular "Starter Kit" -Plural "Starter Kits"
                $ListedNoun = Get-WordForm -Count $ListedCount -Singular "Starter Kit" -Plural "Starter Kits"
                Write-Log -Type "ERROR" -Message "Starter Kit download failed: ${DownloadedCount} ${DownloadedNoun} downloaded, ${ListedCount} ${ListedNoun} listed"
            }
            throw
        }
    }
}
