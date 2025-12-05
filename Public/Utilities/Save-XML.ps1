function Save-XML {
    <#
        .SYNOPSIS
        Save XML content as Alteryx-compatible.

        .DESCRIPTION
        Save XML content using UTF-8 encoding without byte-order mark (BOM) to ensure compatibility with Alteryx.

        .NOTES
        File name:      Save-XML.ps1
        Author:         Florian Carrier
        Creation date:  2025-12-03
        Last modified:  2025-12-03
    #>
    [CmdletBinding ()]
    Param (
        [Parameter(
            Mandatory   = $true,
            Position    = 0,
            HelpMessage = "XML content to save"
        )]
        [XML]$XML,
        [Parameter(
            Mandatory   = $true,
            Position    = 1,
            HelpMessage = "Path to the XML file"
        )]
        [String]
        $Path
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Check target directory for new files
        $Directory = Split-Path -Path $Path -Parent
        if ($Directory -and -not (Test-Path -LiteralPath $Directory)) {
            New-Item -Path $Directory -ItemType "Directory" -Force | Out-Null
        }
    }
    Process {
        # Define XML settings
        $Encoding                   = New-Object -TypeName System.Text.UTF8Encoding($false)
        $Settings                   = New-Object -TypeName System.Xml.XmlWriterSettings
        $Settings.Encoding          = $Encoding
        $Settings.Indent            = $true
        $Settings.NewLineHandling   = [System.Xml.NewLineHandling]::Entitize
        $Writer                     = [System.Xml.XmlWriter]::Create($Path, $Settings)
        try {
            # Save file
            $XML.Save($Writer)
        }
        catch {
            Write-Log -Type "WARN"  -Message "Failed to save XML file $($Path.Name)"
            Write-Log -Type "ERROR" -Message $PSItem.Exception.Message
        }
        finally {
            $Writer.Close()
        }
    }
}