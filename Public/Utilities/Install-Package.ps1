function Install-Package {
    <#
        .SYNOPSIS
        Install Alteryx Package

        .DESCRIPTION
        Install an Alteryx package (.YXI). The installer expands the package into a
        unique staging directory, reads package metadata, routes known package
        content to the matching Alteryx folder, and applies conflict handling.

        .NOTES
        File name:      Install-Package.psm1
        Author:         Florian Carrier
        Creation date:  2022-08-02
        Last modified:  2026-06-01

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/developer-help/package-tool
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to the Alteryx package"
        )]
        [ValidateNotNullOrEmpty()]
        [Alias("Package")]
        [System.String]
        $Path,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Type of installation"
        )]
        [ValidateSet(
            "Admin",
            "User"
        )]
        [System.String]
        $Type = "User",
        [Parameter (
            Mandatory   = $false,
            HelpMessage = "Action to take when an installed asset already exists"
        )]
        [ValidateSet(
            "Fail",
            "Overwrite",
            "Prompt",
            "Rename",
            "Skip"
        )]
        [System.String]
        $ConflictAction = "Prompt",
        [Parameter (
            Mandatory   = $false,
            HelpMessage = "Path to the Python executable or virtual environment used for package dependency installation"
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PythonEnvironmentPath,
        [Parameter (
            Mandatory   = $false,
            HelpMessage = "Path to the R library used for package dependency installation"
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RLibraryPath,
        [Parameter (
            HelpMessage = "Switch to delete the package installer"
        )]
        [Switch]
        $Delete,
        [Parameter (
            HelpMessage = "Switch to enable non-interactive mode"
        )]
        [Switch]
        $Unattended,
        [Parameter (
            HelpMessage = "Switch to install Python dependencies when a requirements.txt file is found"
        )]
        [Switch]
        $InstallPythonDependencies,
        [Parameter (
            HelpMessage = "Switch to install R package folders when found"
        )]
        [Switch]
        $InstallRPackages
    )

    Begin {
        # Get global preference variables.
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $Package = $null
        $Staging = $null
        $ExpandedFolder = $null
        $Successful = $false
        $ConflictState = [PSCustomObject]@{
            OverwriteAll = $false
        }

        $MetadataFileNames = @(
            "ayx_workspace.json",
            "Config.xml",
            "icon.png"
        )

        $SampleFolderNames = @(
            "Sample",
            "Samples"
        )

        $RPackageFolderNames = @(
            "R",
            "R-Library",
            "R-Libraries",
            "R-Packages",
            "RPackages"
        )

        function Get-YXIPackageMetadata {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $PackageRoot
            )

            $ConfigurationPath = Get-ChildItem -Path $PackageRoot -File -ErrorAction Stop |
                Where-Object { $PSItem.Name -ieq "Config.xml" } |
                Select-Object -First 1

            $Metadata = [Ordered]@{
                Author       = $null
                CategoryName = $null
                Description  = $null
                Icon         = $null
                Name         = $null
                ToolVersion  = $null
            }

            if ($null -eq $ConfigurationPath) {
                Write-Log -Type "WARN" -Message "Package configuration file Config.xml could not be found"
                return $Metadata
            }

            try {
                $ConfigurationContent = (Get-Content -LiteralPath $ConfigurationPath.FullName -Raw -ErrorAction Stop).TrimEnd([System.Char]13, [System.Char]10)
                Write-Debug -Message "Config.xml:`n${ConfigurationContent}"

                try {
                    $Configuration = [System.Xml.XmlDocument]::new()
                    $Configuration.LoadXml($ConfigurationContent)
                } catch [System.Xml.XmlException] {
                    $OriginalXmlException = $PSItem.Exception
                    Write-Log -Type "WARN" -Message "Package configuration file Config.xml is not valid XML. Attempting to repair raw ampersands."
                    Write-Debug -Message "XML parse error at line $($OriginalXmlException.LineNumber), position $($OriginalXmlException.LinePosition): $($OriginalXmlException.Message)"

                    $RepairedConfigurationContent = Repair-YXIConfigXmlContent -Content $ConfigurationContent
                    Write-Debug -Message "Repaired Config.xml:`n${RepairedConfigurationContent}"

                    try {
                        $Configuration = [System.Xml.XmlDocument]::new()
                        $Configuration.LoadXml($RepairedConfigurationContent)
                        $ConfigurationContent = $RepairedConfigurationContent
                        Write-Log -Type "WARN" -Message "Config.xml metadata was repaired in memory by escaping raw ampersands. Rebuild the YXI with valid XML when possible."
                    } catch [System.Xml.XmlException] {
                        Write-Log -Type "ERROR" -Message "Package configuration file Config.xml is not valid XML"
                        Write-Log -Type "ERROR" -Message "XML parse error at line $($OriginalXmlException.LineNumber), position $($OriginalXmlException.LinePosition): $($OriginalXmlException.Message)"
                        Write-Log -Type "ERROR" -Message "Repair attempt failed at line $($PSItem.Exception.LineNumber), position $($PSItem.Exception.LinePosition): $($PSItem.Exception.Message)"
                        Write-Log -Type "ERROR" -Message "Next step: fix Config.xml in the YXI package source, then rebuild the package. Escape literal ampersands as '&amp;' or wrap text containing special XML characters in CDATA."
                        throw "Config.xml is not valid XML: $($OriginalXmlException.Message)"
                    }
                }

                $ConfigurationMetaInfoPath = "/*[local-name()='Configuration']/*[local-name()='Properties']/*[local-name()='MetaInfo']"
                $AlteryxJavaScriptPluginMetaInfoPath = "/*[local-name()='AlteryxJavaScriptPlugin']/*[local-name()='Properties']/*[local-name()='MetaInfo']"

                $MetaInfo = $Configuration.SelectSingleNode($ConfigurationMetaInfoPath)

                if ($null -eq $MetaInfo) {
                    $MetaInfo = $Configuration.SelectSingleNode($AlteryxJavaScriptPluginMetaInfoPath)
                }

                if ($null -eq $MetaInfo) {
                    Write-Log -Type "WARN" -Message "Package configuration file does not contain Configuration/Properties/MetaInfo or AlteryxJavaScriptPlugin/Properties/MetaInfo"
                    return $Metadata
                }

                foreach ($Key in @($Metadata.Keys)) {
                    $Node = $MetaInfo.SelectSingleNode("*[local-name()='${Key}']")
                    if ($null -ne $Node) {
                        $Metadata[$Key] = $Node.InnerText
                    }
                }
            } catch {
                if ($PSItem.Exception.Message -notlike "Config.xml is not valid XML:*") {
                    Write-Log -Type "ERROR" -Message "Package configuration file could not be parsed"
                    Write-Log -Type "ERROR" -Message $PSItem.Exception.Message
                }
                throw
            }

            return $Metadata
        }

        function Resolve-PythonExecutable {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $EnvironmentPath
            )

            if (-Not (Test-Path -LiteralPath $EnvironmentPath)) {
                throw "Python environment path could not be found: ${EnvironmentPath}"
            }

            $ResolvedPath = (Resolve-Path -LiteralPath $EnvironmentPath -ErrorAction Stop).Path
            $Item = Get-Item -LiteralPath $ResolvedPath -ErrorAction Stop

            if ($Item -is [System.IO.FileInfo]) {
                return $Item.FullName
            }

            $CandidatePaths = @(
                (Join-Path -Path $Item.FullName -ChildPath "Scripts\python.exe"),
                (Join-Path -Path $Item.FullName -ChildPath "python.exe"),
                (Join-Path -Path $Item.FullName -ChildPath "bin\python")
            )

            foreach ($CandidatePath in $CandidatePaths) {
                if (Test-Path -LiteralPath $CandidatePath -PathType Leaf) {
                    return $CandidatePath
                }
            }

            throw "Python executable could not be resolved from path: ${EnvironmentPath}"
        }

        function Get-YXIInstallTarget {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                [System.IO.FileSystemInfo]
                $Item,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $RootPath,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $ToolsPath
            )

            if ($Item -is [System.IO.FileInfo]) {
                return $null
            }

            if ($SampleFolderNames -icontains $Item.Name) {
                return @{
                    AssetType       = "Samples"
                    CopyChildren    = $true
                    DestinationPath = Join-Path -Path $RootPath -ChildPath "Samples"
                    SourcePath      = $Item.FullName
                }
            }

            if ($RPackageFolderNames -icontains $Item.Name) {
                if ($InstallRPackages) {
                    if ([System.String]::IsNullOrWhiteSpace($RLibraryPath)) {
                        throw "R package content was found, but RLibraryPath was not provided"
                    }

                    return @{
                        AssetType       = "RPackages"
                        CopyChildren    = $true
                        DestinationPath = $RLibraryPath
                        SourcePath      = $Item.FullName
                    }
                }

                Write-Log -Type "WARN" -Message "R package content found in '$($Item.Name)' and skipped because InstallRPackages was not specified"
                return $null
            }

            return @{
                AssetType       = "Tool"
                CopyChildren    = $false
                DestinationPath = $ToolsPath
                SourcePath      = $Item.FullName
            }
        }

        function Resolve-YXISampleInstallScope {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                [System.IO.FileSystemInfo]
                $SourceItem,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $DestinationPath
            )

            $DestinationItemPath = Join-Path -Path $DestinationPath -ChildPath $SourceItem.Name

            if ($SourceItem -isnot [System.IO.DirectoryInfo]) {
                return @(
                    [PSCustomObject]@{
                        SourcePath      = $SourceItem.FullName
                        DestinationPath = $DestinationPath
                        DebugPath       = $DestinationItemPath
                    }
                )
            }

            $StarterKitsPath = Join-Path -Path $SourceItem.FullName -ChildPath "Starter Kits"
            if (-Not (Test-Path -LiteralPath $StarterKitsPath -PathType Container)) {
                return @(
                    [PSCustomObject]@{
                        SourcePath      = $SourceItem.FullName
                        DestinationPath = $DestinationPath
                        DebugPath       = $DestinationItemPath
                    }
                )
            }

            $StarterKitItems = Get-ChildItem -LiteralPath $StarterKitsPath -Directory -Force -ErrorAction Stop
            if ($null -eq $StarterKitItems) {
                return @(
                    [PSCustomObject]@{
                        SourcePath      = $SourceItem.FullName
                        DestinationPath = $DestinationPath
                        DebugPath       = $DestinationItemPath
                    }
                )
            }

            $StarterKitsDestinationPath = Join-Path -Path $DestinationItemPath -ChildPath "Starter Kits"
            $InstallScopes = foreach ($StarterKitItem in $StarterKitItems) {
                $RelativePath = [System.IO.Path]::GetRelativePath($SourceItem.FullName, $StarterKitItem.FullName)
                [PSCustomObject]@{
                    SourcePath      = $StarterKitItem.FullName
                    DestinationPath = $StarterKitsDestinationPath
                    DebugPath       = Join-Path -Path $DestinationItemPath -ChildPath $RelativePath
                }
            }

            return @($InstallScopes)
        }

        function Request-YXIOverwriteDecision {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $Prompt
            )

            do {
                $Response = Read-Host -Prompt "${Prompt} ([Y] Yes | [A] Yes to All | [N] No)"
            } until ($Response -in @("Y", "y", "A", "a", "N", "n"))

            switch ($Response) {
                { $PSItem -in @("Y", "y") } {
                    return "Overwrite"
                }
                { $PSItem -in @("A", "a") } {
                    return "OverwriteAll"
                }
                default {
                    return "Skip"
                }
            }
        }

        function Resolve-YXILanguageName {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $LanguageCode
            )

            try {
                return ([System.Globalization.CultureInfo]::GetCultureInfo($LanguageCode)).EnglishName
            } catch {
                return $LanguageCode
            }
        }

        function Resolve-YXIInstallDisplayPath {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $TargetPath
            )

            try {
                return [System.IO.Path]::GetRelativePath($InstallRoot, $TargetPath)
            } catch {
                return $TargetPath
            }
        }

        function Resolve-YXIOverwriteDescription {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $AssetType,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $TargetPath
            )

            $DisplayPath = Resolve-YXIInstallDisplayPath -TargetPath $TargetPath

            if ($AssetType -eq "Samples") {
                if ($DisplayPath -like "Samples\data\*") {
                    return "sample data for '${DisplayPath}'"
                }

                return "sample workflows for '${DisplayPath}'"
            }

            return "$($AssetType.ToLowerInvariant()) content for '${DisplayPath}'"
        }

        function Repair-YXIConfigXmlContent {
            [CmdletBinding()]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNull()]
                [System.String]
                $Content
            )

            return [System.Text.RegularExpressions.Regex]::Replace(
                $Content,
                "&(?!#\d+;|#x[0-9A-Fa-f]+;|[A-Za-z][A-Za-z0-9._:-]*;)",
                "&amp;"
            )
        }

        function Copy-YXIAsset {
            [CmdletBinding(SupportsShouldProcess = $true)]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $SourcePath,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $DestinationPath,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $AssetType,

                [Parameter(Mandatory = $false)]
                [Switch]
                $CopyChildren,

                [Parameter(Mandatory = $true)]
                [ValidateSet(
                    "Fail",
                    "Overwrite",
                    "Prompt",
                    "Rename",
                    "Skip"
                )]
                [System.String]
                $Action
            )

            $SourceItem = Get-Item -LiteralPath $SourcePath -ErrorAction Stop
            $DestinationItemPath = Join-Path -Path $DestinationPath -ChildPath $SourceItem.Name
            $EffectiveAction = $Action

            if ($Unattended -And $Action -eq "Prompt") {
                $EffectiveAction = "Overwrite"
            }

            if ($ConflictState.OverwriteAll -And $Action -eq "Prompt") {
                $EffectiveAction = "Overwrite"
            }

            if (-Not (Test-Path -LiteralPath $DestinationPath)) {
                if ($PSCmdlet.ShouldProcess($DestinationPath, "Create installation directory")) {
                    New-Item -Path $DestinationPath -ItemType "Directory" -Force -ErrorAction Stop | Out-Null
                }
            }

            if ($CopyChildren) {
                $ChildItems = Get-ChildItem -LiteralPath $SourceItem.FullName -Force -ErrorAction Stop

                if ($AssetType -eq "Samples") {
                    $SampleDataItems = $ChildItems | Where-Object { $PSItem.Name -ieq "data" }
                    $SampleWorkflowItems = $ChildItems | Where-Object { $PSItem.Name -ine "data" }
                    $SampleDataScopes = @()
                    $SampleWorkflowScopes = @()

                    if ($null -ne $SampleDataItems) {
                        foreach ($SampleDataItem in $SampleDataItems) {
                            $SampleDataScopes += Resolve-YXISampleInstallScope -SourceItem $SampleDataItem -DestinationPath $DestinationPath
                        }
                    }

                    if ($null -ne $SampleWorkflowItems) {
                        foreach ($SampleWorkflowItem in $SampleWorkflowItems) {
                            $SampleWorkflowScopes += Resolve-YXISampleInstallScope -SourceItem $SampleWorkflowItem -DestinationPath $DestinationPath
                        }
                    }

                    if ($SampleDataScopes.Count -gt 0) {
                        Write-Log -Type "INFO" -Message "Deploying sample data"
                        foreach ($SampleDataScope in $SampleDataScopes) {
                            Copy-YXIAsset -SourcePath $SampleDataScope.SourcePath -DestinationPath $SampleDataScope.DestinationPath -AssetType $AssetType -Action $Action -WhatIf:$WhatIfPreference
                        }
                    }

                    if ($SampleWorkflowScopes.Count -gt 0) {
                        $SampleWorkflowGroups = $SampleWorkflowScopes | Group-Object -Property {
                            Split-Path -Path (Split-Path -Path $PSItem.DestinationPath -Parent) -Leaf
                        }

                        foreach ($SampleWorkflowGroup in $SampleWorkflowGroups) {
                            $LanguageName = Resolve-YXILanguageName -LanguageCode $SampleWorkflowGroup.Name
                            Write-Log -Type "INFO" -Message "Copying ${LanguageName} language samples"

                            foreach ($SampleWorkflowScope in $SampleWorkflowGroup.Group) {
                                Copy-YXIAsset -SourcePath $SampleWorkflowScope.SourcePath -DestinationPath $SampleWorkflowScope.DestinationPath -AssetType $AssetType -Action $Action -WhatIf:$WhatIfPreference
                            }
                        }
                    }

                    return
                }

                foreach ($ChildItem in $ChildItems) {
                    Copy-YXIAsset -SourcePath $ChildItem.FullName -DestinationPath $DestinationPath -AssetType $AssetType -Action $Action -WhatIf:$WhatIfPreference
                }

                return
            }

            if ($SourceItem -is [System.IO.DirectoryInfo]) {
                if (Test-Path -LiteralPath $DestinationItemPath) {
                    if ($EffectiveAction -eq "Prompt") {
                        $OverwriteDescription = Resolve-YXIOverwriteDescription -AssetType $AssetType -TargetPath $DestinationItemPath
                        Write-Log -Type "WARN" -Message "Existing ${OverwriteDescription} found."
                        $ConflictDecision = Request-YXIOverwriteDecision -Prompt "Overwrite existing ${OverwriteDescription}?"
                        if ($ConflictDecision -eq "OverwriteAll") {
                            $ConflictState.OverwriteAll = $true
                            $EffectiveAction = "Overwrite"
                        } else {
                            $EffectiveAction = $ConflictDecision
                        }
                    }

                    switch ($EffectiveAction) {
                        "Fail" {
                            throw "${AssetType} package scope '$($SourceItem.Name)' is already installed at ${DestinationItemPath}"
                        }
                        "Rename" {
                            $VersionSuffix = Get-Date -Format "yyyyMMddHHmmss"
                            $RenamedItemName = [System.String]::Concat($SourceItem.Name, "_", $VersionSuffix)
                            $DestinationItemPath = Join-Path -Path $DestinationPath -ChildPath $RenamedItemName
                        }
                        "Skip" {
                            Write-Log -Type "WARN" -Message "${AssetType} package scope '$($SourceItem.Name)' installation skipped for '${DestinationItemPath}'"
                            return
                        }
                        "Overwrite" {
                        }
                    }
                }

                if (-Not (Test-Path -LiteralPath $DestinationItemPath)) {
                    if ($PSCmdlet.ShouldProcess($DestinationItemPath, "Create ${AssetType} directory")) {
                        New-Item -Path $DestinationItemPath -ItemType "Directory" -Force -ErrorAction Stop | Out-Null
                    }
                }

                $SourceDirectories = Get-ChildItem -LiteralPath $SourceItem.FullName -Directory -Recurse -Force -ErrorAction Stop
                foreach ($SourceDirectory in $SourceDirectories) {
                    $RelativeDirectoryPath = [System.IO.Path]::GetRelativePath($SourceItem.FullName, $SourceDirectory.FullName)
                    $DestinationDirectoryPath = Join-Path -Path $DestinationItemPath -ChildPath $RelativeDirectoryPath

                    if (-Not (Test-Path -LiteralPath $DestinationDirectoryPath)) {
                        if ($PSCmdlet.ShouldProcess($DestinationDirectoryPath, "Create ${AssetType} directory")) {
                            New-Item -Path $DestinationDirectoryPath -ItemType "Directory" -Force -ErrorAction Stop | Out-Null
                        }
                    }
                }

                $SourceFiles = Get-ChildItem -LiteralPath $SourceItem.FullName -File -Recurse -Force -ErrorAction Stop
                foreach ($SourceFile in $SourceFiles) {
                    $RelativePath = [System.IO.Path]::GetRelativePath($SourceItem.FullName, $SourceFile.FullName)
                    $DestinationFilePath = Join-Path -Path $DestinationItemPath -ChildPath $RelativePath
                    $DestinationFileDirectory = Split-Path -Path $DestinationFilePath -Parent

                    if (-Not (Test-Path -LiteralPath $DestinationFileDirectory)) {
                        if ($PSCmdlet.ShouldProcess($DestinationFileDirectory, "Create ${AssetType} directory")) {
                            New-Item -Path $DestinationFileDirectory -ItemType "Directory" -Force -ErrorAction Stop | Out-Null
                        }
                    }

                    Copy-YXIAsset -SourcePath $SourceFile.FullName -DestinationPath $DestinationFileDirectory -AssetType $AssetType -Action $EffectiveAction -WhatIf:$WhatIfPreference
                }
                return
            }

            if (Test-Path -LiteralPath $DestinationItemPath) {
                if ($EffectiveAction -eq "Prompt") {
                    $ConflictDecision = Request-YXIOverwriteDecision -Prompt "Overwrite ${AssetType} file '$($SourceItem.Name)' at '${DestinationItemPath}'?"
                    if ($ConflictDecision -eq "OverwriteAll") {
                        $ConflictState.OverwriteAll = $true
                        $EffectiveAction = "Overwrite"
                    } else {
                        $EffectiveAction = $ConflictDecision
                    }
                }

                switch ($EffectiveAction) {
                    "Fail" {
                        throw "${AssetType} file '$($SourceItem.Name)' is already installed at ${DestinationItemPath}"
                    }
                    "Rename" {
                        $VersionSuffix = Get-Date -Format "yyyyMMddHHmmss"
                        if ($SourceItem -is [System.IO.FileInfo]) {
                            $RenamedItemName = [System.String]::Concat($SourceItem.BaseName, "_", $VersionSuffix, $SourceItem.Extension)
                        }

                        $DestinationItemPath = Join-Path -Path $DestinationPath -ChildPath $RenamedItemName
                    }
                    "Skip" {
                        return
                    }
                    "Overwrite" {
                    }
                }
            }

            $CopyOperation = "Copy"
            if (Test-Path -LiteralPath $DestinationItemPath) {
                $CopyOperation = "Overwrite"
            }

            if ($PSCmdlet.ShouldProcess($DestinationItemPath, "Install ${AssetType} file")) {
                Copy-Item -LiteralPath $SourceItem.FullName -Destination $DestinationItemPath -Recurse -Force -ErrorAction Stop
                Write-Debug -Message "${CopyOperation}`t${DestinationItemPath}"
            }
        }

        function Install-YXIPythonDependencies {
            [CmdletBinding(SupportsShouldProcess = $true)]
            Param (
                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $ToolPath,

                [Parameter(Mandatory = $true)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $PythonPath
            )

            $RequirementsPath = Join-Path -Path $ToolPath -ChildPath "requirements.txt"
            if (-Not (Test-Path -LiteralPath $RequirementsPath -PathType Leaf)) {
                return
            }

            $PythonFiles = Get-ChildItem -Path $ToolPath -File -Filter "*.py" -ErrorAction SilentlyContinue
            if ($null -eq $PythonFiles) {
                return
            }

            if ($PSCmdlet.ShouldProcess($RequirementsPath, "Install Python dependencies")) {
                Write-Log -Type "INFO" -Message "Installing Python dependencies from '$RequirementsPath'"
                & $PythonPath -m pip install --requirement $RequirementsPath
                if ($LASTEXITCODE -ne 0) {
                    throw "Python dependency installation failed for '${RequirementsPath}'"
                }
            }
        }

        # Validate package before any installation work starts.
        if (Test-Object -Path $Path -NotFound) {
            Write-Verbose -Message $Path
            Write-Log -Type "ERROR" -Message "Path not found ""$Path""" -ExitCode 1
        }

        $Package = Get-Item -Path $Path -ErrorAction Stop
        if ($Package -isnot [System.IO.FileInfo]) {
            Write-Verbose -Message $Package
            Write-Log -Type "ERROR" -Message "Path provided is not an Alteryx package" -ExitCode 1
        }

        $Extension = [System.IO.Path]::GetExtension($Package.Name)
        if ($Extension -ine ".yxi") {
            Write-Log -Type "ERROR" -Message $Path
            Write-Log -Type "ERROR" -Message "Unsupported file extension (${Extension})" -ExitCode 1
        }

        if ($InstallPythonDependencies -And [System.String]::IsNullOrWhiteSpace($PythonEnvironmentPath)) {
            Write-Log -Type "ERROR" -Message "PythonEnvironmentPath is required when InstallPythonDependencies is specified" -ExitCode 1
        }

        if ($InstallRPackages -And [System.String]::IsNullOrWhiteSpace($RLibraryPath)) {
            Write-Log -Type "ERROR" -Message "RLibraryPath is required when InstallRPackages is specified" -ExitCode 1
        }

        # Define target directories.
        if ($Type -eq "User") {
            $InstallRoot = Join-Path -Path $env:APPDATA -ChildPath "Alteryx"
        } else {
            $InstallRoot = Join-Path -Path $env:ALLUSERSPROFILE -ChildPath "Alteryx"
        }

        $ToolsDestination = Join-Path -Path $InstallRoot -ChildPath "Tools"
        $Staging = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.String]::Concat("PSAYX-YXI-", [System.Guid]::NewGuid().ToString()))
        $ZipPath = Join-Path -Path $Staging -ChildPath ([System.String]::Concat($Package.BaseName, ".zip"))
        $ExpandedFolder = Join-Path -Path $Staging -ChildPath "Expanded"
    }

    Process {
        try {
            Write-Verbose -Message "Preparing temporary package staging directory"
            Write-Log -Type "NOTICE" -Message "Installing Alteryx package '$($Package.Name)'"
            Write-Verbose -Message $Package.FullName

            New-Item -Path $Staging -ItemType "Directory" -Force -ErrorAction Stop | Out-Null

            Copy-Item -LiteralPath $Package.FullName -Destination $ZipPath -Force -ErrorAction Stop

            Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExpandedFolder -Force -ErrorAction Stop

            $Metadata = Get-YXIPackageMetadata -PackageRoot $ExpandedFolder

            $PythonPath = $null
            if ($InstallPythonDependencies) {
                $PythonPath = Resolve-PythonExecutable -EnvironmentPath $PythonEnvironmentPath
                Write-Log -Type "INFO" -Message "Python environment: ${PythonPath}"
            }

            $InstallItems = Get-ChildItem -Path $ExpandedFolder -ErrorAction Stop
            foreach ($InstallItem in $InstallItems) {
                if ($MetadataFileNames -icontains $InstallItem.Name) {
                    Write-Verbose -Message "Excluding package metadata file '$($InstallItem.Name)'"
                    continue
                }

                if ($InstallItem -is [System.IO.FileInfo]) {
                    Write-Log -Type "WARN" -Message "Skipping root-level file '$($InstallItem.Name)'"
                    continue
                }

                $InstallTarget = Get-YXIInstallTarget -Item $InstallItem -RootPath $InstallRoot -ToolsPath $ToolsDestination
                if ($null -eq $InstallTarget) {
                    continue
                }

                if ($InstallTarget.AssetType -ne "Samples") {
                    Write-Log -Type "INFO" -Message "Planning $($InstallTarget.AssetType) installation for '$($InstallItem.Name)'"
                }

                if ($InstallTarget.AssetType -eq "Tool" -And $InstallPythonDependencies) {
                    Install-YXIPythonDependencies -ToolPath $InstallItem.FullName -PythonPath $PythonPath -WhatIf:$WhatIfPreference
                }

                Copy-YXIAsset -SourcePath $InstallTarget.SourcePath -DestinationPath $InstallTarget.DestinationPath -AssetType $InstallTarget.AssetType -Action $ConflictAction -CopyChildren:$InstallTarget.CopyChildren -WhatIf:$WhatIfPreference
            }

            if ($Delete) {
                Write-Log -Type "WARN" -Message "Removing package installer"
                if ($PSCmdlet.ShouldProcess($Package.FullName, "Remove package installer")) {
                    Remove-Item -LiteralPath $Package.FullName -Force -ErrorAction Stop
                }
            }

            $Successful = $true
        } catch {
            Write-Log -Type "ERROR" -Message "Installation of package '$($Package.BaseName)' failed"
            Write-Log -Type "ERROR" -Message $PSItem.Exception.Message
            throw
        } finally {
            if (-Not [System.String]::IsNullOrWhiteSpace($Staging) -And (Test-Path -LiteralPath $Staging)) {
                Write-Log -Type "INFO" -Message "Cleaning-up temporary files"
                Write-Debug -Message "Removing temporary package staging directory: ${Staging}"
                Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    End {
        if ($Successful) {
            Write-Log -Type "CHECK" -Message "Installation of package '$($Package.Name)' completed successfully"
        }
    }
}
