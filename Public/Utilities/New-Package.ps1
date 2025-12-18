function New-Package {
    <#
        .SYNOPSIS
        Package Alteryx tool(s)

        .DESCRIPTION
        Create an Alteryx installer package (.YXI) for a specified set of tools.

        .NOTES
        File name:      New-Package.psm1
        Author:         Florian Carrier
        Creation date:  2021-06-15
        Last modified:  2025-12-18

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/en/developer-help/platform-sdk/legacy-sdks/package-a-tool.html
    #>
    [CmdletBinding (
        SupportsShouldProcess = $true
    )]
    Param (
        [Parameter (
            Position    = 1,
            Mandatory   = $true,
            HelpMessage = "Path to the directory containing the tool(s) to package"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Path,
        [Parameter (
            Position    = 2,
            Mandatory   = $false,
            HelpMessage = "Name of the package"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Name,
        [Parameter (
            Position    = 3,
            Mandatory   = $false,
            HelpMessage = "Author"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Author = [Environment]::UserName,
        [Parameter (
            Position    = 4,
            Mandatory   = $false,
            HelpMessage = "Version number"
        )]
        [ValidatePattern ("\d+\.\d+\.\d+")]
        [String]
        $Version,
        [Parameter (
            Position    = 5,
            Mandatory   = $false,
            HelpMessage = "Tool category"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $CategoryName,
        [Parameter (
            Position    = 6,
            Mandatory   = $false,
            HelpMessage = "Description"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Description,
        [Parameter (
            Position    = 7,
            Mandatory   = $false,
            HelpMessage = "Package icon"
        )]
        [ValidateNotNullOrEmpty ()]
        [String]
        $Icon,
        [Parameter (
            Position    = 8,
            Mandatory   = $false,
            HelpMessage = "Package compression level"
        )]
        [ValidateSet (
            "Fastest",
            "NoCompression",
            "Optimal"
        )]
        [String]
        $CompressionLevel = "Optimal",
        [Parameter (
          HelpMessage = "Switch to disable automated versioning of packaged macros"
        )]
        [Switch]
        $IgnoreVersioning,
        [Parameter (
          HelpMessage = "Switch to enable non-interactive mode"
        )]
        [Switch]
        $Unattended
    )
    Begin {
        # Get global preference variables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Define configuration values
        $Properties = [Ordered]@{
            "Author"        = $Author
            "CategoryName"  = $CategoryName
            "Description"   = $Description
            "Icon"          = $Icon
            "Name"          = $Name
            "ToolVersion"   = $Version
        }
        # Default version number
        $DefaultVersion = "1.0.0"
        # Parent directory
        $ParentDirectory = Split-Path -Path $Path -Parent
        # Default package name
        if (-Not $PSBoundParameters.ContainsKey("Name")) {
            $Properties.Name = Split-Path -Path $Path -Leaf
        }
        # Configuration file name
        $Configuration = "config.xml"
        # XML configuration template
        $Template = '<?xml version="1.0"?>
<Configuration>
    <Properties>
        <MetaInfo>
            <Icon></Icon>
            <Name></Name>
            <CategoryName></CategoryName>
            <ToolVersion></ToolVersion>
            <Author></Author>
            <Description></Description>
        </MetaInfo>
    </Properties>
</Configuration>'
    }
    Process {
        Write-Log -Type "CHECK" -Message "Start creation of package ""$($Properties.Name)"""
        # ------------------------------------------------------------------------------
        #region YXI configuration file
        # Check if XML file already exist
        $XML = New-Object -TypeName "System.XML.XMLDocument"
        $ConfigurationPath = Join-Path -Path $Path -ChildPath $Configuration
        if (Test-Path -Path $ConfigurationPath) {
            Write-Log -Type "DEBUG" -Message "Load existing configuration file"
            try {
                # Try to import content as XML
                $XML.Load($ConfigurationPath)
                Write-Log -Type "DEBUG" -Message $XML.OuterXml
                # TODO Validate schema
                # Retrieve existing values
                # ! Create dummy copy of list of properties to prevent error "Collection was modified; enumeration operation may not execute."
                $DummyProperties = Copy-OrderedHashtable -Hashtable $Properties
                foreach ($Key in $DummyProperties.Keys) {
                    if (-Not $PSBoundParameters.ContainsKey($Key)) {
                        $XPath  = "Configuration/Properties/MetaInfo/$Key"
                        $Node   = Select-XMLNode -XML $XML -XPath $XPath
                        $Properties.$Key = $Node.InnerText
                        Write-Log -Type "DEBUG" -Message "$Key=$($Properties.$Key)"
                        if ($Key -eq "Name") {
                            Write-Log -Type "INFO" -Message "Updating package name to ""$($Properties.$Key)"""
                        }
                    }
                }
            } catch [System.Management.Automation.RuntimeException] {
                Write-Log -Type "DEBUG" -Message $Configuration
                Write-Log -Type "ERROR" -Message "Configuration file could not be loaded"
                Write-Log -Type "DEBUG" -Message "Overwriting configuration from template"
                $XML.LoadXml($Template)
            }
        } else {
            Write-Log -Type "DEBUG" -Message "No configuration file found - loading template"
            $XML.LoadXml($Template)
        }
        # Check version
        if ($null -eq $Properties.ToolVersion) {
            Write-Log -Type "ERROR" -Message "Missing package version number"
            Write-Log -Type "WARN"  -Message "Initialising version $DefaultVersion"
            $Properties.ToolVersion = $DefaultVersion
        } elseif ($Properties.ToolVersion -notmatch "\d+\.\d+\.\d+") {
            Write-Log -Type "ERROR" -Message "Invalid package version number"
            Write-Log -Type "WARN"  -Message "Package version must match semantic versionning format (MAJOR.MINOR.PATCH)"
            Write-Log -Type "WARN"  -Message "Initialising version $DefaultVersion"
            $Properties.ToolVersion = $DefaultVersion
        }
        # Check icon file
        if ($PSBoundParameters.ContainsKey("Icon")) {
            $IconPath = Join-Path -Path $Path -ChildPath $Icon
            if (-Not (Test-Path -Path $IconPath)) {
                Write-Log -Type "DEBUG" -Message $IconPath
                Write-Log -Type "ERROR" -Message "Icon file could not be found"
                Write-Log -Type "WARN"  -Message "Removing invalid icon file reference"
                $Properties.Icon = ""
            }
        } else {
            Write-Log -Type "WARN" -Message "No icon file has been set"
        }
        # Set configuration
        Write-Log -Type "INFO" -Message "Set package configuration"
        foreach ($Value in $Properties.GetEnumerator()) {
            $XPath          = "Configuration/Properties/MetaInfo/$($Value.Name)"
            $Node           = Select-XMLNode -XML $XML -XPath $XPath
            Write-Log -Type "DEBUG" -Message "$($Value.Name)=$($Value.Value)"
            $Node.InnerText = $Value.Value
        }
        # (Over)write configuration file
        Write-Log -Type "DEBUG" -Message $XML.OuterXml
        if ($PSCmdlet.ShouldProcess($ConfigurationPath, "XML.Save")) {
            $XML.Save($ConfigurationPath)
        }
        #endregion YXI configuration file
        # ------------------------------------------------------------------------------
        #region Macro metadata
        if (-Not $IgnoreVersioning) {
            # List macro files
            $Macros = Get-ChildItem -Path $Path -Recurse -File -Filter "*.yxmc" | Where-Object { $PSItem.Directory.Name -notin @('Resources', 'Samples') }
            foreach ($Macro in $Macros) {
                Write-Log -Type "INFO" -Message "Updating '$($Macro.BaseName)' metadata"
                try {
                    [XML]$XML = Get-Content -LiteralPath $Macro.FullName -Raw
                    # Update version number
                    $ToolVersionNode = $XML.SelectSingleNode('/AlteryxDocument/Properties/MetaInfo/ToolVersion')
                    $CurrentVersion = $ToolVersionNode.InnerText
                    if ($CurrentVersion -eq $Properties.ToolVersion) {
                        Write-Log -Type "INFO" -Message "Macro version is already up-to-date ($CurrentVersion)"
                    } else {
                        Write-Log -Type "INFO" -Message "Updating macro version from $CurrentVersion to $($Properties.ToolVersion)"
                        $ToolVersionNode.InnerText = $Properties.ToolVersion
                    }
                    # Check author field
                    $AuthorNode = $XML.SelectSingleNode('/AlteryxDocument/Properties/MetaInfo/Author')
                    if ([String]::IsNullOrWhiteSpace($AuthorNode.InnerText)) {
                        Write-Log -Type "INFO" -Message "Setting macro author"
                        Write-Log -Type "DEBUG" -Message $Author
                        $AuthorNode.InnerText = $Author
                    }
                    # Check copyright field
                    $CopyrightNode = $XML.SelectSingleNode('/AlteryxDocument/Properties/MetaInfo/Copyright')
                    if ([String]::IsNullOrWhiteSpace($CopyrightNode.InnerText)) {
                        Write-Log -Type "INFO" -Message "Setting macro copyright information"
                        $CurrentYear = (Get-Date).Year
                        Write-Log -Type "DEBUG" -Message $CurrentYear
                        $CopyrightNode.InnerText = $CurrentYear
                    }
                    # Save YXMC file
                    Save-AlteryxXML -XML $XML -Path $Macro.FullName
                }
                catch {
                    Write-Warning "Failed to update macro metadata: $($PSItem.Exception.Message)"
                    continue
                }
            }
        }
        #endregion Macro metadata
        # ------------------------------------------------------------------------------
        #region Build YXI
        # Compress-Archive
        $ZIPFile            = [System.String]::Concat($Properties.Name, ".zip")
        $DestinationPath    = Join-Path -Path $ParentDirectory -ChildPath $ZIPFile
        Compress-Archive -Path (Join-Path -Path $Path -ChildPath "*") -DestinationPath $DestinationPath -CompressionLevel "Optimal" -Force -WhatIf:$WhatIfPreference
        # Set macro files version
        if (-Not $IgnoreVersioning) {
            Write-Log -Type "INFO" -Message "Set versioning of packaged macros"
            try {
                # Load compression assembly
                Add-Type -AssemblyName "System.IO.Compression.FileSystem"
                # Create temporary ZIP path
                $TempZipPath    = [System.IO.Path]::GetTempFileName()
                $SourceZip      = $null
                $DestinationZip = $null
                try {
                    # Open source ZIP file as read-only
                    $SourceZip = [System.IO.Compression.ZipFile]::OpenRead($DestinationPath)
                    # Open destination ZIP file
                    $DestinationZip = [System.IO.Compression.ZipFile]::Open(
                        $TempZipPath,
                        [System.IO.Compression.ZipArchiveMode]::Update
                    )
                    # Iterate through all macros of the source archive to map folders to apply versioning to
                    $TopLevelMap    = @{}
                    $RootMacroMap   = @{}
                    $FolderVersion  = $($Properties.ToolVersion).Replace(".", "_")
                    foreach ($MacroEntry in $SourceZip.Entries) {
                        if ($MacroEntry.FullName -like "*.yxmc") {
                            $Full = $MacroEntry.FullName -replace "\\", "/"
                            $Dir  = [System.IO.Path]::GetDirectoryName($Full)
                            if ($null -eq $Dir) { $Dir = "" }
                            $Dir = $Dir -replace "\\", "/"
                            if ([String]::IsNullOrEmpty($Dir)) {
                                # If a macro is located at ZIP root, create a folder from the macro name (only for the YXMC itself)
                                $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($MacroEntry.Name)
                                $RootMacroMap[$MacroEntry.Name] = [String]::Concat($BaseName, "_", $FolderVersion)
                                continue
                            }
                            # Only version top-level folder; ignore nested folder names (e.g., supporting macros)
                            $Top = ($Dir -split "/")[0]
                            if ($Top -and -not $TopLevelMap.ContainsKey($Top)) {
                                $TopLevelMap[$Top] = [String]::Concat($Top, "_", $FolderVersion)
                            }
                        }
                    }
                    # Iterate through all entries of the source archive
                    foreach ($Entry in $SourceZip.Entries) {
                        # Skip backup files
                        if ($Entry.FullName -like "*.bak") {
                            Write-Log -Type "DEBUG" -Message "Skipping backup file '$($Entry.Name)'"
                            continue
                        }
                        $Old = $Entry.FullName -replace "\\", "/"
                        $New = $Old
                        $Dir = [System.IO.Path]::GetDirectoryName($Old)
                        if ($null -eq $Dir) { $Dir = "" }
                        $Dir = $Dir -replace "\\", "/"
                        if ([String]::IsNullOrEmpty($Dir)) {
                            # Root-level items:
                            # - If macro at root; move into dedicated versioned folder 
                            # - Otherwise retain structure
                            if ($Old -like "*.yxmc" -and $RootMacroMap.ContainsKey($Entry.Name)) {
                                $RootFolder = $RootMacroMap[$Entry.Name]
                                $New = [String]::Concat($RootFolder, "/", $Entry.Name)
                            }
                        } else {
                            # Non-root items: version only the first (top-level) segment
                            $FirstSeg = ($Old -split "/")[0]
                            if ($TopLevelMap.ContainsKey($FirstSeg)) {
                                $VersionedTop = $TopLevelMap[$FirstSeg]
                                $New = $Old -replace ("^" + [regex]::Escape($FirstSeg) + "/"), ($VersionedTop + "/")
                            }
                        }
                        if ($Old -like "*.yxmc") {
                            Write-Log -Type "INFO"  -Message "Versioning macro folder '$([System.IO.Path]::GetFileNameWithoutExtension($Entry.Name))'"
                            Write-Log -Type "DEBUG" -Message "Copying macro as: ${New}"
                        } else {
                            Write-Log -Type "DEBUG" -Message "Copying file '$($Entry.Name)' as: ${New}"
                        }
                        $NewEntry = $DestinationZip.CreateEntry(
                            $New,
                            [System.IO.Compression.CompressionLevel]::Optimal
                        )
                        $SourceStream = $null
                        $TargetStream = $null
                        try {
                            $SourceStream = $Entry.Open()
                            $TargetStream = $NewEntry.Open()
                            $SourceStream.CopyTo($TargetStream)
                        }
                        finally {
                            if ($null -ne $SourceStream) { $SourceStream.Dispose() }
                            if ($null -ne $TargetStream) { $TargetStream.Dispose() }
                        }
                    }
                }
                finally {
                    # Ensure archives are closed to release file locks
                    if ($null -ne $SourceZip) {
                        $SourceZip.Dispose()
                    }
                    if ($null -ne $DestinationZip) {
                        $DestinationZip.Dispose()
                    }
                }
                # Replace original ZIP with updated ZIP
                Write-Log -Type "DEBUG" -Message "Overwriting original ZIP file"
                Move-Item -Path $TempZipPath -Destination $DestinationPath -Force
            }
            catch {
                Write-Error -Message "Failed to update macros in '${DestinationPath}': $($PSItem.Exception.Message)"
            }
        }
        # Rename package to YXI and append version number
        if ((Test-Path -Path $DestinationPath) -Or $WhatIfPreference) {
            $YXIPackage     = [System.String]::Concat($Properties.Name, ".", $Properties.ToolVersion, ".yxi")
            $PackagePath    = Join-Path -Path $ParentDirectory -ChildPath $YXIPackage
            if (Test-Path -Path $PackagePath) {
                Write-Log -Type "WARN" -Message "File already exists $PackagePath"
                if ($Unattended -Or (Confirm-Prompt -Prompt "Do you want to overwrite the existing package?")) {
                    Remove-Item -Path $PackagePath -WhatIf:$WhatIfPreference
                    Write-Log -Type "WARN" -Message "Overwritting existing package"
                } else {
                    Write-Log -Type "WARN" -Message "Script terminated by user"
                    Write-Log -Type "INFO" -Message "No package was generated" -ErrorCode 0
                }
            }
            if ($PSCmdlet.ShouldProcess($DestinationPath, "Rename-Item")) {
                Rename-Item -Path $DestinationPath -NewName $YXIPackage -Force
            }
            Write-Log -Type "DEBUG" -Message $PackagePath
            Write-Log -Type "CHECK" -Message "Package '$YXIPackage' created successfully"
        } else {
            Write-Log -Type "ERROR" -Message "Package creation failed"
        }
        #endregion Build YXI
    }
}