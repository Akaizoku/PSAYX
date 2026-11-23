function Disable-SSL {
    <#
        .SYNOPSIS
        Disable SSL configuration for Alteryx Server.

        .DESCRIPTION
        Disables SSL configuration for Alteryx Server by removing HTTPS bindings and reverts RuntimeSettings.xml.
        
        .NOTES
        File name:      Disable-SSL.ps1
        Author:         Florian Carrier
        Creation date:  2025-07-14
        Last modified:  2025-07-14
    #>
    [CmdletBinding ()]
    Param (
        
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        
    }
    Process {
        # 3. Remove certificate binding ------------------------------------------------
        $binding = (netsh http show sslcert) -match "0\.0\.0\.0:$Port"
        if ($binding) {
            & netsh http delete sslcert ipport=0.0.0.0:$Port
            Write-Host "Binding on port $Port removed."
        } else {
            Write-Host "No binding to remove on port $Port."
        }

        # 4. Revert RuntimeSettings.xml ------------------------------------------------
        Backup-RunTimeSettings -Path $XmlPath
        [xml]$xml = Get-Content $XmlPath

        $xml.SystemSettings.Gallery.SslEnabled            = 'False'
        $xml.SystemSettings.Controller.TLSEnabled         = 'False'
        $xml.SystemSettings.Environment.TLSEnabled        = 'False'
        $xml.SystemSettings.Controller.ServicePort        = 80

        foreach ($tag in @('BaseAddress','WebApiBaseAddress')) {
            $old = $xml.SystemSettings.Gallery.$tag
            if ($old) {
                $uri = [uri]$old
                # strip https + port
                $new = "http://$($uri.Host)/$($uri.Segments -join '')"
                $xml.SystemSettings.Gallery.$tag = $new
            }
        }
        # Save the modified XML back to the file
        $xml.Save($XmlPath)
    }
}
