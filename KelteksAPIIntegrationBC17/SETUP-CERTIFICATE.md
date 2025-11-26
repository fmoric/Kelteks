# BC17 Extension - Certificate Authentication Setup Guide

## Overview

This guide provides step-by-step instructions for setting up the Kelteks API Integration BC17 extension using **Certificate Authentication** (mutual TLS) to connect to BC v27.

**Best for**: High-security environments requiring certificate-based authentication and non-repudiation.

**Advantages**:
- Highest security level
- No password transmission
- Certificate-based trust
- Non-repudiation (audit trail)
- Suitable for compliance requirements

**Requirements**:
- Public Key Infrastructure (PKI) or Certificate Authority
- Valid X.509 certificates
- Certificate management capability
- HTTPS mandatory

---

## Prerequisites

- BC v17 environment installed and running
- BC v27 environment with HTTPS enabled
- Certificate Authority (enterprise CA or commercial CA)
- Administrative rights on both servers
- Understanding of PKI concepts
- Certificate management tools

---

## Step 1: Obtain or Create Certificates

### 1.1 Option A: Request from Enterprise CA

If you have an enterprise Certificate Authority:

```powershell
# On BC17 server, request client certificate
$cert = Get-Certificate -Template "Computer" `
    -SubjectName "CN=kelteks-sync-bc17.company.local" `
    -DnsName "kelteks-sync-bc17.company.local" `
    -CertStoreLocation "Cert:\LocalMachine\My"
```

### 1.2 Option B: Create Self-Signed Certificate (Testing Only)

**Warning**: Self-signed certificates are for testing only!

```powershell
# Create self-signed certificate on BC17
$cert = New-SelfSignedCertificate `
    -Subject "CN=kelteks-sync-bc17" `
    -DnsName "kelteks-sync-bc17.company.local" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -KeyExportPolicy Exportable `
    -KeySpec Signature `
    -KeyLength 2048 `
    -KeyAlgorithm RSA `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears(2)

# Export certificate (with private key)
$password = ConvertTo-SecureString -String "P@ssw0rd123!" -Force -AsPlainText
$cert | Export-PfxCertificate `
    -FilePath "C:\Temp\kelteks-sync-bc17.pfx" `
    -Password $password

# Export public key only
$cert | Export-Certificate `
    -FilePath "C:\Temp\kelteks-sync-bc17.cer"
```

### 1.3 Certificate Requirements

The certificate must have:
- **Subject**: CN matching client identity
- **Key Usage**: Digital Signature, Key Encipherment
- **Enhanced Key Usage**: Client Authentication (1.3.6.1.5.5.7.3.2)
- **Validity**: At least 1 year
- **Key Length**: Minimum 2048 bits (RSA) or 256 bits (ECC)
- **Private Key**: Exportable (for backup)

---

## Step 2: Install Certificate on BC17

### 2.1 Import Certificate to Personal Store
```powershell
# Import PFX with private key
$password = ConvertTo-SecureString -String "P@ssw0rd123!" -Force -AsPlainText
Import-PfxCertificate `
    -FilePath "C:\Temp\kelteks-sync-bc17.pfx" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -Password $password
```

### 2.2 Verify Certificate Installation
```powershell
# List certificates in Personal store
Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {
    $_.Subject -like "*kelteks-sync-bc17*"
} | Format-List Subject, Thumbprint, NotAfter, EnhancedKeyUsageList
```

### 2.3 Note Certificate Thumbprint
```powershell
$cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {
    $_.Subject -like "*kelteks-sync-bc17*"
}
Write-Host "Thumbprint: $($cert.Thumbprint)"
```

Example thumbprint: `A1B2C3D4E5F6...`

---

## Step 3: Configure BC27 for Certificate Authentication

### 3.1 Import Client Certificate to BC27

Copy the public certificate (`.cer` file) to BC27 server and import:

```powershell
# On BC27 server, import to Trusted People
Import-Certificate `
    -FilePath "C:\Temp\kelteks-sync-bc17.cer" `
    -CertStoreLocation "Cert:\LocalMachine\TrustedPeople"
```

### 3.2 Configure BC27 for Client Certificate Authentication
```powershell
# Enable certificate authentication
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "ClientServicesCredentialType" `
    -KeyValue "NavUserPassword,AccessControlService"

# Configure client certificate validation
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "ClientCertificateEnabled" `
    -KeyValue "True"

# Require valid client certificate
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "ClientCertificateValidationMode" `
    -KeyValue "ChainTrust"

# Restart service
Restart-NAVServerInstance -ServerInstance BC270
```

### 3.3 Configure IIS for Client Certificates (if using IIS)

If BC27 is hosted in IIS:

1. Open **IIS Manager**
2. Navigate to BC27 website
3. Double-click **SSL Settings**
4. Check: **Require SSL**
5. Set **Client certificates**: Accept or Require
6. Click **Apply**
7. Restart website

---

## Step 4: Map Certificate to BC27 User

### 4.1 Get Certificate Subject
```powershell
$cert = Get-ChildItem -Path "Cert:\LocalMachine\TrustedPeople" | Where-Object {
    $_.Subject -like "*kelteks-sync-bc17*"
}
Write-Host "Subject: $($cert.Subject)"
Write-Host "Thumbprint: $($cert.Thumbprint)"
```

### 4.2 Create User in BC27
1. Open BC27 Web Client
2. Navigate to **Users**
3. Click **New**
4. Enter:
   - **User Name**: `CERT-KELTEKS-SYNC`
   - **Full Name**: `Kelteks Sync Service (Certificate Auth)`
5. Click **OK**

### 4.3 Map Certificate to User

In BC27, create a certificate mapping:

```al
// This is typically done via configuration or custom table
// Consult BC27 documentation for exact method
```

**Alternative**: Use certificate thumbprint in authentication headers.

### 4.4 Assign Permissions
1. Open the user
2. Click **User Permission Sets**
3. Add required permissions:
   - Read/Write to Sales Invoice tables
   - Read/Write to Sales Credit Memo tables
4. Click **OK**

---

## Step 5: Configure HTTPS on BC27 (if not already done)

### 5.1 Obtain Server Certificate for BC27

Request or create server certificate for BC27:

```powershell
# Request from enterprise CA
$cert = Get-Certificate -Template "WebServer" `
    -SubjectName "CN=bc27-server.company.local" `
    -DnsName "bc27-server.company.local","bc27-server" `
    -CertStoreLocation "Cert:\LocalMachine\My"
```

### 5.2 Bind Certificate to BC27

```powershell
# Get certificate thumbprint
$cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {
    $_.Subject -like "*bc27-server*"
}

# Create HTTPS binding
New-WebBinding -Name "Microsoft Dynamics 365 Business Central Web Client" `
    -Protocol https -Port 443

# Bind certificate
$binding = Get-WebBinding -Name "Microsoft Dynamics 365 Business Central Web Client" `
    -Protocol https
$binding.AddSslCertificate($cert.Thumbprint, "my")
```

### 5.3 Update BC27 URLs
```powershell
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "PublicODataBaseUrl" `
    -KeyValue "https://bc27-server.company.local/BC270/ODataV4/"
    
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "PublicWebBaseUrl" `
    -KeyValue "https://bc27-server.company.local/BC270/"
    
Restart-NAVServerInstance -ServerInstance BC270
```

---

## Step 6: Install BC17 Extension

```powershell
Publish-NAVApp -ServerInstance BC170 `
    -Path ".\KelteksAPIIntegrationBC17.app" `
    -SkipVerification

Sync-NAVApp -ServerInstance BC170 `
    -Name "Kelteks API Integration BC17"

Install-NAVApp -ServerInstance BC170 `
    -Name "Kelteks API Integration BC17"
```

---

## Step 7: Grant Certificate Access to BC17 Service Account

### 7.1 Get BC17 Service Account
```powershell
$service = Get-WmiObject Win32_Service | Where-Object {
    $_.Name -like "*BC170*"
}
Write-Host "Service Account: $($service.StartName)"
```

### 7.2 Grant Read Access to Private Key
```powershell
# Get certificate
$cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {
    $_.Subject -like "*kelteks-sync-bc17*"
}

# Get private key file
$keyPath = "$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys\"
$keyFile = Get-ChildItem $keyPath | Where-Object {
    $_.Name -eq $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
}

# Grant read permission
$acl = Get-Acl -Path $keyFile.FullName
$permission = "NT AUTHORITY\NETWORK SERVICE", "Read", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.AddAccessRule($accessRule)
Set-Acl -Path $keyFile.FullName -AclObject $acl
```

---

## Step 8: Configure BC17 Extension

### 8.1 Open Configuration
Search for: `KLT API Configuration`

### 8.2 Enter Connection Details

| Field | Value | Example |
|-------|-------|---------|
| **Base URL** | BC27 HTTPS endpoint | `https://bc27-server.company.local/BC270/ODataV4/` |
| **Company ID** | BC27 Company GUID | `{guid}` |
| **Authentication Method** | Select: `Certificate` | Certificate |
| **Certificate Thumbprint** | Client cert thumbprint | `A1B2C3D4E5F6...` |
| **Certificate Store Location** | LocalMachine | LocalMachine |
| **Certificate Store Name** | My | My |

### 8.3 Additional Settings

| Field | Value |
|-------|-------|
| **Enabled** | ☑ Yes |
| **Batch Size** | 100 |
| **Sync Interval (Minutes)** | 15 |
| **Max Retry Attempts** | 3 |
| **Enable Logging** | ☑ Yes |
| **Alert Email** | admin@kelteks.com |

---

## Step 9: Test Connection

### 9.1 Run Test
Click **Actions** > **Test Connection**

### 9.2 Expected Result
✅ **Success**:
```
Connection successful!
BC27 Environment: Production
Company: Kelteks d.o.o.
Authentication: Certificate
Certificate Subject: CN=kelteks-sync-bc17
Certificate Valid Until: 2026-01-26
```

❌ **Failure - Check**:
- Certificate is in correct store
- Thumbprint is correct
- BC17 service has access to private key
- Client certificate trusted on BC27
- HTTPS configured on BC27
- Server certificate valid

---

## Step 10: Test with PowerShell

```powershell
# Load client certificate
$cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {
    $_.Thumbprint -eq "A1B2C3D4E5F6..."
}

# Make request with certificate
$url = "https://bc27-server.company.local/BC270/ODataV4/Company('guid')/salesInvoices"
$response = Invoke-WebRequest -Uri $url -Certificate $cert -Method GET

Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
Write-Host "Content Type: $($response.Headers['Content-Type'])" -ForegroundColor Green
```

---

## Step 11: Create Job Queue and Test

Follow standard job queue creation (see main README).

Test manual synchronization from Posted Sales Invoices.

---

## Troubleshooting

### Issue: "Certificate Not Found"
**Cause**: Thumbprint incorrect or certificate not in store

**Solution**:
```powershell
# List all certificates
Get-ChildItem -Path "Cert:\LocalMachine\My" | Format-List Subject, Thumbprint

# Verify thumbprint matches configuration
```

### Issue: "Access Denied to Private Key"
**Cause**: BC17 service account doesn't have permission

**Solution**:
Re-run Step 7.2 to grant private key access.

### Issue: "Certificate Validation Failed"
**Cause**: Client certificate not trusted on BC27

**Solution**:
1. Verify certificate in `Cert:\LocalMachine\TrustedPeople` on BC27
2. Check certificate chain validity
3. Ensure CA certificate is in `Cert:\LocalMachine\Root`

### Issue: "SSL/TLS Handshake Failed"
**Cause**: Protocol mismatch or cipher suite incompatible

**Solution**:
```powershell
# Ensure TLS 1.2 is enabled on both servers
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check with openssl (from Linux/WSL)
openssl s_client -connect bc27-server.company.local:443 -cert client.crt -key client.key
```

---

## Security Best Practices

1. **Certificate Lifecycle**:
   - Monitor expiration dates
   - Renew certificates 30 days before expiry
   - Keep private keys secure
   - Use hardware security modules (HSM) for high security

2. **Private Key Protection**:
   - Mark as non-exportable in production
   - Use strong ACLs on private key files
   - Consider using ECC instead of RSA for better security

3. **Certificate Revocation**:
   - Enable CRL or OCSP checking
   - Maintain revocation lists
   - Have revocation procedures documented

4. **Monitoring**:
   - Log all certificate authentications
   - Alert on certificate validation failures
   - Track certificate usage

5. **Backup**:
   - Backup certificates (with private keys) to secure location
   - Encrypt backups
   - Test restore procedures

---

## Maintenance

### Monthly
- [ ] Check certificate expiration dates
- [ ] Review authentication logs
- [ ] Verify certificate still trusted on BC27

### Quarterly
- [ ] Test certificate restoration from backup
- [ ] Review CRL/OCSP configuration
- [ ] Audit certificate access permissions

### Annually
- [ ] Renew certificates
- [ ] Review and update certificate policies
- [ ] Security audit

### Before Expiration (30 days)
- [ ] Request new certificate
- [ ] Test new certificate in dev/test
- [ ] Update production configuration
- [ ] Verify sync continues working
- [ ] Archive old certificate

---

## Certificate Renewal Procedure

1. **Request New Certificate** (30 days before expiry):
   ```powershell
   $newCert = Get-Certificate -Template "Computer" `
       -SubjectName "CN=kelteks-sync-bc17.company.local" `
       -DnsName "kelteks-sync-bc17.company.local" `
       -CertStoreLocation "Cert:\LocalMachine\My"
   ```

2. **Export and Import to BC27**:
   ```powershell
   $newCert | Export-Certificate -FilePath "C:\Temp\new-cert.cer"
   # Copy to BC27 and import to TrustedPeople
   ```

3. **Update BC17 Configuration**:
   - Update Thumbprint field
   - Test connection

4. **Monitor**:
   - Verify sync continues
   - Check for errors

5. **Remove Old Certificate** (after 7 days):
   ```powershell
   Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {
       $_.Thumbprint -eq "OLD_THUMBPRINT"
   } | Remove-Item
   ```

---

## Support

**Consultant**: Ana Šetka
**Client**: Kelteks
**JIRA**: ZGBCSKELTE-54

For certificate issues:
1. Verify certificate with `certlm.msc` (Local Machine certificates)
2. Check private key permissions
3. Review Windows Event Viewer > Security log
4. Test with `Test-Certificate` PowerShell cmdlet
5. Contact PKI administrator if CA-related issues

---

## Configuration Checklist

- [ ] Client certificate requested/created
- [ ] Certificate installed on BC17 (LocalMachine\My)
- [ ] Certificate thumbprint noted
- [ ] Public certificate exported
- [ ] Public certificate imported to BC27 (TrustedPeople)
- [ ] BC27 configured for certificate authentication
- [ ] HTTPS configured on BC27
- [ ] Server certificate valid on BC27
- [ ] User created in BC27
- [ ] Permissions assigned
- [ ] BC17 extension installed
- [ ] Permissions assigned in BC17
- [ ] Private key access granted to BC17 service
- [ ] Configuration completed with thumbprint
- [ ] Connection test successful
- [ ] PowerShell test successful
- [ ] Job queue created
- [ ] Manual sync tested
- [ ] Document verified in BC27
- [ ] Certificate renewal procedure documented

---

**Last Updated**: 2025-01-26
**Version**: 1.0.0
**Extension**: Kelteks API Integration BC17
