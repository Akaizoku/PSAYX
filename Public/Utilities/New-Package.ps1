function New-Package {
    <#
        .SYNOPSIS
        Package Alteryx tool(s)

        .DESCRIPTION
        Create an Alteryx installer package (.YXI) for a specified set of tools

        .NOTES
        File name:      New-Package.psm1
        Author:         Florian Carrier
        Creation date:  2021-06-15
        Last modified:  2021-06-17

        .LINK
        https://www.powershellgallery.com/packages/PSAYX

        .LINK
        https://help.alteryx.com/current/developer-help/package-tool
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
          HelpMessage = "Switch to enable non-interactive mode"
        )]
        [Switch]
        $Unattended
    )
    Begin {
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
                # ! Create dummy copy of list of propertis to prevent error "Collection was modified; enumeration operation may not execute."
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
        # Compress-Archive
        $ZIPFile            = [System.String]::Concat($Properties.Name, ".zip")
        $YXIPackage         = [System.String]::Concat($Properties.Name, ".yxi")
        $DestinationPath    = Join-Path -Path $ParentDirectory -ChildPath $ZIPFile
        Compress-Archive -Path (Join-Path -Path $Path -ChildPath "*") -DestinationPath $DestinationPath -CompressionLevel "Optimal" -Force -WhatIf:$WhatIfPreference
        # Rename package to YXI
        if ((Test-Path -Path $DestinationPath) -Or $WhatIfPreference) {
            $PackagePath = Join-Path -Path $ParentDirectory -ChildPath $YXIPackage
            if (Test-Path -Path $PackagePath) {
                Write-Log -Type "WARN" -Message "Path already exists $PackagePath"
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
            Write-Log -Type "CHECK" -Message "Package ""$YXIPackage"" created successfully"
        } else {
            Write-Log -Type "ERROR" -Message "Package creation failed"
        }
    }
}