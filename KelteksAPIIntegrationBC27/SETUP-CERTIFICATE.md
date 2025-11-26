# BC27 Extension - Certificate Authentication Setup Guide

## Overview

Setup guide for Kelteks API Integration BC27 extension using **Certificate Authentication** (mutual TLS) to connect to BC v17.

**Best for**: High-security environments requiring certificate-based authentication.

---

## Prerequisites

- PKI infrastructure or Certificate Authority
- Valid X.509 certificates
- Certificate management capability
- HTTPS mandatory on BC17

---

## Step 1: Obtain Client Certificate

### Option A: Request from Enterprise CA
```powershell
# On BC27 server
$cert = Get-Certificate -Template "Computer" `
    -SubjectName "CN=kelteks-sync-bc27.company.local" `
    -DnsName "kelteks-sync-bc27.company.local" `
    -CertStoreLocation "Cert:\LocalMachine\My"
```

### Option B: Self-Signed (Testing Only)
```powershell
$cert = New-SelfSignedCertificate `
    -Subject "CN=kelteks-sync-bc27" `
    -DnsName "kelteks-sync-bc27.company.local" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -KeyExportPolicy Exportable `
    -KeySpec Signature `
    -KeyLength 2048 `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears(2)

# Export
$password = ConvertTo-SecureString -String "P@ssw0rd123!" -Force -AsPlainText
$cert | Export-PfxCertificate -FilePath "C:\Temp\bc27-client.pfx" -Password $password
$cert | Export-Certificate -FilePath "C:\Temp\bc27-client.cer"
```

### Certificate Requirements
- Subject: CN matching client
- Key Usage: Digital Signature, Key Encipherment
- Enhanced Key Usage: Client Authentication
- Minimum 2048 bits (RSA)

---

## Step 2: Install Certificate on BC27

```powershell
# Import to Personal store
$password = ConvertTo-SecureString -String "P@ssw0rd123!" -Force -AsPlainText
Import-PfxCertificate `
    -FilePath "C:\Temp\bc27-client.pfx" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -Password $password

# Note thumbprint
$cert = Get-ChildItem "Cert:\LocalMachine\My" | Where-Object {
    $_.Subject -like "*kelteks-sync-bc27*"
}
Write-Host "Thumbprint: $($cert.Thumbprint)"
```

---

## Step 3: Configure BC17 for Certificate Authentication

### Import Client Certificate to BC17
```powershell
# Copy .cer file to BC17 server
Import-Certificate `
    -FilePath "C:\Temp\bc27-client.cer" `
    -CertStoreLocation "Cert:\LocalMachine\TrustedPeople"
```

### Enable Certificate Authentication
```powershell
Set-NAVServerConfiguration -ServerInstance BC170 `
    -KeyName "ClientCertificateEnabled" `
    -KeyValue "True"

Set-NAVServerConfiguration -ServerInstance BC170 `
    -KeyName "ClientCertificateValidationMode" `
    -KeyValue "ChainTrust"

Restart-NAVServerInstance -ServerInstance BC170
```

---

## Step 4: Create User in BC17

1. Open BC17 Web Client
2. Navigate to **Users** > **New**
3. User Name: `CERT-KELTEKS-SYNC`
4. Full Name: Kelteks Sync (Certificate Auth)
5. Assign permissions:
   - Read/Write Purchase Invoice tables

---

## Step 5: Configure HTTPS on BC17

Ensure BC17 has valid server certificate:

```powershell
# Request server certificate
$cert = Get-Certificate -Template "WebServer" `
    -SubjectName "CN=bc17-server.company.local" `
    -DnsName "bc17-server.company.local" `
    -CertStoreLocation "Cert:\LocalMachine\My"

# Update BC17 URLs
Set-NAVServerConfiguration -ServerInstance BC170 `
    -KeyName "PublicODataBaseUrl" `
    -KeyValue "https://bc17-server.company.local/BC170/ODataV4/"

Restart-NAVServerInstance -ServerInstance BC170
```

---

## Step 6: Install BC27 Extension

```powershell
Publish-NAVApp -ServerInstance BC270 `
    -Path ".\KelteksAPIIntegrationBC27.app" `
    -SkipVerification

Sync-NAVApp -ServerInstance BC270 `
    -Name "Kelteks API Integration BC27"

Install-NAVApp -ServerInstance BC270 `
    -Name "Kelteks API Integration BC27"
```

---

## Step 7: Grant Certificate Access

```powershell
# Get certificate
$cert = Get-ChildItem "Cert:\LocalMachine\My" | Where-Object {
    $_.Subject -like "*kelteks-sync-bc27*"
}

# Grant read permission to BC27 service account
$keyPath = "$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys\"
$keyFile = Get-ChildItem $keyPath | Where-Object {
    $_.Name -eq $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
}

$acl = Get-Acl -Path $keyFile.FullName
$permission = "NT AUTHORITY\NETWORK SERVICE", "Read", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.AddAccessRule($accessRule)
Set-Acl -Path $keyFile.FullName -AclObject $acl
```

---

## Step 8: Configure BC27 Extension

Search: `KLT API Configuration`

| Field | Value |
|-------|-------|
| **Base URL** | `https://bc17-server.company.local/BC170/ODataV4/` |
| **Company ID** | BC17 GUID |
| **Authentication Method** | `Certificate` |
| **Certificate Thumbprint** | `A1B2C3D4...` |
| **Certificate Store Location** | LocalMachine |
| **Certificate Store Name** | My |
| **Enabled** | ☑ Yes |

---

## Step 9: Test Connection

Click **Actions** > **Test Connection**

✅ **Success**:
```
Connection successful!
Authentication: Certificate
Certificate Subject: CN=kelteks-sync-bc27
Certificate Valid Until: 2026-01-26
```

---

## Step 10: Test with PowerShell

```powershell
$cert = Get-ChildItem "Cert:\LocalMachine\My" | Where-Object {
    $_.Thumbprint -eq "A1B2C3D4..."
}

$url = "https://bc17-server.company.local/BC170/ODataV4/Company('guid')/purchaseInvoices"
$response = Invoke-WebRequest -Uri $url -Certificate $cert -Method GET

Write-Host "Status: $($response.StatusCode)"
```

---

## Troubleshooting

### "Certificate Not Found"
```powershell
# List all certificates
Get-ChildItem "Cert:\LocalMachine\My" | Format-List Subject, Thumbprint
```

### "Access Denied to Private Key"
Re-run Step 7 to grant permissions.

### "Certificate Validation Failed"
Verify certificate in TrustedPeople on BC17:
```powershell
Get-ChildItem "Cert:\LocalMachine\TrustedPeople"
```

---

## Security Best Practices

1. **Monitor Expiration**: Renew 30 days before expiry
2. **Protect Private Key**: Use strong ACLs
3. **Enable CRL/OCSP**: Check revocation
4. **Backup Certificates**: Encrypted backups
5. **Use HSM**: For high security

---

## Certificate Renewal

1. **Request New** (30 days before expiry)
2. **Export and Import to BC17**
3. **Update Thumbprint** in configuration
4. **Test Connection**
5. **Remove Old** after 7 days

---

## Support

**Consultant**: Ana Šetka
**Client**: Kelteks
**JIRA**: ZGBCSKELTE-54

---

**Last Updated**: 2025-01-26
**Version**: 1.0.0
**Extension**: Kelteks API Integration BC27
