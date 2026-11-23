function Enable-SSL {
    <#
        .SYNOPSIS
        Enable SSL for Alteryx using either a self-signed or CA-signed certificate.

        .DESCRIPTION
        This script creates a self-signed certificate or imports a provided PFX certificate, binds it to the specified port, and optionally adds it to the Trusted Root Certification Authorities store.

        .EXAMPLE
        Enable-SSL -DnsName "alteryx.local" -Alias "localhost" -Port 443

        .EXAMPLE
        Enable-SSL -CertificatePath "C:\ssl\alteryx.pfx" -CertificatePassword (Read-Host "Password" -AsSecureString) -Port 443
        
        .NOTES
        File name:      Enable-SSL.ps1
        Author:         Florian Carrier
        Creation date:  2025-07-04
        Last modified:  2025-12-09
        Comment:        This function requires the public key infrastructure (PKI) client module.

        .LINK
        https://learn.microsoft.com/en-us/powershell/module/pki
    #>
    [CmdletBinding(DefaultParameterSetName = 'SelfSigned')]
    Param (
        [Parameter(
            Mandatory           = $false,
            Position            = 1,
            HelpMessage         = "SSL/TLS port to bind the certificate to. Default is 443.",
            ParameterSetName    = 'SelfSigned'
        )]
        [Parameter(
            Mandatory           = $false,
            ParameterSetName    = 'CA'
        )]
        [Int32]
        $Port                   = 443,
        [Parameter(
            Mandatory           = $false,
            Position            = 2,
            HelpMessage         = "DNS names for the self-signed certificate.",
            ParameterSetName    = 'SelfSigned'
        )]
        [String[]]
        $DnsName                = "localhost",
        [Parameter(
            Mandatory           = $true,
            HelpMessage         = "Path to the CA-signed certificate in PFX format.",
            ParameterSetName    = 'CA'
        )]
        [String]
        [Alias ("Certificate")]
        $CertificatePath,
        [Parameter(
            Mandatory           = $false,
            HelpMessage         = "Secure password for the CA-signed certificate.",
            ParameterSetName    = 'CA'
        )]
        [SecureString]
        [Alias ("Password")]
        $CertificatePassword
    )
    Begin {
        # Get global preference vrariables
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        # Alteryx application ID
        $AppId = "{eea9431a-a3d4-4c9b-9f9a-b83916c11c67}"
        # Initialize result tracking object
        $Result = [PSCustomObject]@{
            CertificateCreation = $false
            CertificateBinding  = $false
            TrustRegistration   = $false
        }
        # Variables
        $Utility    = "netsh"
        $IpPort     = "0.0.0.0:$Port"
    }
    Process {
        # ------------------------------------------------------------------------------
        #region CA certificate
        # ------------------------------------------------------------------------------
        if ($PSCmdlet.ParameterSetName -eq "CA") {
            try {
                Write-Log -Type "INFO" -Message "Importing CA certificate from $CertificatePath"
                $Certificate = Import-PfxCertificate            `
                    -FilePath           $CertificatePath        `
                    -CertStoreLocation  "Cert:\LocalMachine\My" `
                    -Password           $CertificatePassword
                if ($Certificate -is [System.Collections.ObjectModel.Collection[System.Security.Cryptography.X509Certificates.X509Certificate2]]) {
                    $Certificate = $Certificate[0]
                }
                # Log CA certificate binding result
                $Result.CertificateCreation = $true
                $Result.TrustRegistration   = $true
            } catch {
                Write-Log -Type "ERROR" -Object "Failed to import CA certificate: $($PSItem.Exception.Message)"
                return $false
            }
        }
        #endregion CA certificate
        # ------------------------------------------------------------------------------
        #region Self-Signed certificate
        # ------------------------------------------------------------------------------
        elseif ($PSCmdlet.ParameterSetName -eq "SelfSigned") {
            $CertificateName    = "AlteryxSelfSigned"
            $KeyLength          = 2048
            $CertValidityYears  = 5
            # Check for existing certificates
            $Certificates = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $PSItem.FriendlyName -eq $CertificateName }
            # Identify deprecated certificates
            $DeprecatedCertificates = $Certificates | Where-Object -Property "NotAfter" -lt -Value (Get-Date)
            foreach ($DeprecatedCertificate in $DeprecatedCertificates) {
                Write-Log -Type "INFO" -Message "Removing expired self-signed certificate ${$DeprecatedCertificate.FriendlyName}"
                try {
                    Write-Log -Type "DEBUG" -Message $DeprecatedCertificate
                    Remove-Item -Path "Cert:\LocalMachine\My\$($DeprecatedCertificate.Thumbprint)" -Force
                    # Remove this cert from the AllMatching list
                    $Certificates = $Certificates | Where-Object { $PSItem.Thumbprint -ne $DeprecatedCertificate.Thumbprint }   
                }
                catch {
                    Write-Log -Type "ERROR" -Message Get-PowerShellError
                    Write-Log -Type "WARN"  -Message "Could not remove self-signed certificate ${$DeprecatedCertificate.FriendlyName}"
                }
            }
            # If valid certificates remain
            if ($Certificates) {
                foreach ($ValidCertificate in $Certificates) {
                    Write-Log -Type "WARN" -Message "A valid certificate with the name '$CertificateName' already exists."
                    Write-Log -Type "DEBUG" -Message $ValidCertificate
                    $Confirm = Confirm-Prompt -Prompt "Do you want to delete and replace it?"
                    if ($Confirm) {
                        Write-Log -Type "WARN"  -Message "Removing old certificate ${$ValidCertificate.FriendlyName}"
                        Write-Log -Type "DEBUG" -Message $ValidCertificate.Thumbprint
                        Remove-Item -Path "Cert:\LocalMachine\My\$($ValidCertificate.Thumbprint)" -Force
                    } else {
                        Write-Log -Type "INFO" -Message "New self-signed certificate creation skipped."
                        $Certificate = $ValidCertificate
                        $Result.CertificateCreation = $true
                    }
                }
            }
            # Generate a new certificate
            if (-not $Result.CertificateCreation) {
                # DNS names for the self-signed certificate
                $DnsName += @([System.Net.Dns]::GetHostName())
                $DnsName += @([System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName)
                $DnsName = $DnsName | Sort-Object -Unique
                try {
                    Write-Log -Type "INFO" -Object "Generating self-signed certificate"
                    $Certificate = New-SelfSignedCertificate                        `
                        -DnsName            $DnsName                                `
                        -Subject            "CN=$DnsName"                           `
                        -CertStoreLocation  "Cert:\LocalMachine\My"                 `
                        -FriendlyName       $CertificateName                        `
                        -NotAfter           (Get-Date).AddYears($CertValidityYears) `
                        -KeyLength          $KeyLength                              `
                        -KeyExportPolicy    Exportable                              `
                        -HashAlgorithm      "SHA256"
                    # Test certificate
                    Test-Certificate -Cert $Certificate -Policy "SSL" -DNSName $DnsName
                    Write-Log -Type "CHECK" -Message "Self-signed certificate successfully created"
                    $Result.CertificateCreation = $true
                } catch {
                    Write-Log -Type "ERROR" -Object "Failed to generate self-signed certificate: $($PSItem.Exception.Message)"
                    return $false
                }
            }
        }
        #endregion Self-Signed certificate
        # ------------------------------------------------------------------------------
        #region Certificate binding
        # ------------------------------------------------------------------------------
        # Retrieve certificate thumbprint
        $Thumbprint = ($Certificate.Thumbprint).Replace(" ", "").Replace("\s", "")
        Write-Log -Type "DEBUG" -Object "Certificate Thumbprint: $Thumbprint"
        # TODO Check for existing bindings
        
        # Bind certificate
        try {
            Write-Log -Type "INFO" -Object "Binding certificate to port $Port"
            $Arguments = @(
                "http", "add", "sslcert",
                "ipport=$IpPort",
                "certhash=$Thumbprint",
                "appid=$AppId"
            ) -join " "
            $Command = ("&", $Utility, $Arguments) -join " "
            Write-Log -Type "DEBUG" -Message $Command
            Start-Process -FilePath $Utility -ArgumentList $Arguments -Verb "RunAs" -Wait -NoNewWindow
            $Result.CertificateBinding = $true
        } catch {
            Write-Log -Type "ERROR" -Object "Failed to bind certificate to port: $($PSItem.Exception.Message)"
            return $false
        }
        #endregion Certificate binding
        # ------------------------------------------------------------------------------
        #region Add certificate to trusted root store
        # ------------------------------------------------------------------------------
        try {
            Write-Log -Type "INFO" -Object "Adding certificate to Trusted Root Certification Authorities"
            $TrustedRootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
            $TrustedRootStore.Open("ReadWrite")
            $TrustedRootStore.Add($Certificate)
            $TrustedRootStore.Close()
            $Result.TrustRegistration = $true
        } catch {
            Write-Log -Type "WARN" -Object "Could not add certificate to trusted root store: $($PSItem.Exception.Message)"
        }
        #endregion Add certificate to trusted root store
        # ------------------------------------------------------------------------------
        #region Configure Server
        # ------------------------------------------------------------------------------
        Write-Log -Type "INFO" -Object "Updating Alteryx Server system settings"
        # TODO set SSL/TLS settings in Alteryx RunTimeSettings.xml
        $ProgramData = Get-EnvironmentVariable -Name "ProgramData"
        $RunTimeSettingsPath = Join-Path -Path $ProgramData -ChildPath "Alteryx\RuntimeSettings.xml"
        Write-Log -Type "DEBUG" -Message $RunTimeSettingsPath
        if (-not (Test-Path -Path $RunTimeSettingsPath)) {  
            Write-Log -Type "ERROR" -Object "RuntimeSettings.xml could not be located"
            Write-Log -Type "WARN"  -Object "Configure SSL manually through Alteryx Server System Settings"
            return $false
        } else {
            try {
                [xml]$RunTimeSettings = Get-Content -Path $RunTimeSettingsPath
                # Ensure the SSL/TLS settings node exists
                if (-not $RunTimeSettings.AlteryxServer.SSL) {
                    $SSLNode = $RunTimeSettings.CreateElement("SSL")
                    $RunTimeSettings.AlteryxServer.AppendChild($SSLNode)
                } else {
                    $SSLNode = $RunTimeSettings.AlteryxServer.SSL
                }
                # Set the SSL/TLS port
                $SSLNode.Port = $Port
                # Save the updated settings
                $RunTimeSettings.Save($RunTimeSettingsPath)
                Write-Log -Type "CHECK" -Object "Alteryx Server system settings updated successfully"
            } catch {
                Write-Log -Type "ERROR" -Object "Failed to update Alteryx Server system settings: $($PSItem.Exception.Message)"
                return $false
            }
        }
        #endregion Configure Server
    }
    End {
        # ------------------------------------------------------------------------------
        # * Check outcome
        # ------------------------------------------------------------------------------
        if (-not $Result.CertificateCreation -or -not $Result.CertificateBinding) {
            Write-Log -Type "ERROR" -Object "Critical failure during SSL setup. Check logs for details."
            return $false
        } elseif (-not $Result.TrustRegistration) {
            Write-Log -Type "WARN" -Object "Certificate installed and bound, but not added to the trusted root store."
        } else {
            Write-Log -Type "CHECK" -Object "SSL setup completed. Please ensure Alteryx is configured to use HTTPS."
        }
        return $true
    }
}
