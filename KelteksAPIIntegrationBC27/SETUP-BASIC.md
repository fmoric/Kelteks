# BC27 Extension - Basic Authentication Setup Guide

## Overview

Setup guide for Kelteks API Integration BC27 extension using **Basic Authentication** (username/password) to connect to BC v17.

**Best for**: On-premise BC27 to on-premise BC17 where Azure AD is not available.

---

## Prerequisites

- BC v27 environment (Platform 27.0, Runtime 14.0)
- BC v17 environment accessible over HTTPS
- Service account with permissions
- Administrative rights in both environments

---

## Step 1: Configure BC17 for Basic Authentication

```powershell
# On BC17 server
Set-NAVServerConfiguration -ServerInstance BC170 `
    -KeyName "ClientServicesCredentialType" `
    -KeyValue "NavUserPassword"

Restart-NAVServerInstance -ServerInstance BC170
```

### Verify Web Services
```powershell
Get-NAVServerConfiguration -ServerInstance BC170 -KeyName "ODataServicesEnabled"
# Should return True
```

### Verify HTTPS
```powershell
Get-NAVServerConfiguration -ServerInstance BC170 -KeyName "PublicODataBaseUrl"
# Must start with https://
```

---

## Step 2: Create Service Account in BC17

### 2.1 Create Windows User
1. On BC17 server, open **Computer Management**
2. Create user: `KELTEKS_SYNC_SVC`
3. Set strong password
4. Check: "Password never expires"

### 2.2 Create BC User
1. Open BC17 Web Client
2. Navigate to **Users** > **New**
3. User Name: `KELTEKS_SYNC_SVC` or `DOMAIN\KELTEKS_SYNC_SVC`
4. Assign permissions:
   - Read/Write to Purchase Invoice (Table 38)
   - Read/Write to Purchase Credit Memo (Table 39)

### 2.3 Test Login
1. Open browser (incognito)
2. Navigate to BC17 Web Client
3. Login with service account credentials
4. Verify access

---

## Step 3: Get BC17 Connection Details

### Base URL Format
```
https://<server>:<port>/<instance>/ODataV4/
```

**Example**:
```
https://bc17-server.company.local:7048/BC170/ODataV4/
```

### Get Company ID
```sql
SELECT [ID], [Name] FROM [Company]
```

---

## Step 4: Install BC27 Extension

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

## Step 5: Assign Permissions in BC27

1. Navigate to **Users**
2. Select configuration user
3. Add permission set: `KLT API Integration BC27`

---

## Step 6: Configure BC27 Extension

### Open Configuration
Search: `KLT API Configuration`

### Enter Details

| Field | Value | Example |
|-------|-------|---------|
| **Base URL** | BC17 OData endpoint | `https://bc17-server:7048/BC170/ODataV4/` |
| **Company ID** | BC17 Company GUID | `{guid}` |
| **Authentication Method** | `Basic` | Basic |
| **Username** | Service account | `DOMAIN\KELTEKS_SYNC_SVC` |
| **Password** | Service password | `********` |
| **Enabled** | ☑ Yes | |
| **Batch Size** | 100 | |
| **Sync Interval** | 15 | |

---

## Step 7: Test Connection

Click **Actions** > **Test Connection**

✅ **Success**:
```
Connection successful!
BC17 Environment: Production
Company: Kelteks d.o.o.
Authentication: Basic (NavUserPassword)
```

---

## Step 8: Test with PowerShell

```powershell
$url = "https://bc17-server:7048/BC170/ODataV4/Company('guid')/purchaseInvoices"
$username = "DOMAIN\KELTEKS_SYNC_SVC"
$password = "Password123!"

$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

$response = Invoke-WebRequest -Uri $url -Credential $credential -Method GET
Write-Host "Success! Status: $($response.StatusCode)"
```

---

## Step 9: Configure Job Queue

1. Navigate to **Job Queue Entries** > **New**
2. Object ID to Run: `50155`
3. Description: Kelteks Document Sync
4. Minutes between Runs: `15`
5. Status: Ready

---

## Step 10: Test Synchronization

1. Create unposted Purchase Invoice in BC27
2. Wait 15 minutes or trigger manual sync
3. Verify in BC17 Purchase Invoices

---

## Troubleshooting

### "401 Unauthorized"
- Verify username format: `DOMAIN\USERNAME`
- Test password in BC17 Web Client
- Check account not locked

### "404 Not Found"
- Verify Base URL format
- Check Company ID

### "403 Forbidden"
- Check service account permissions in BC17

---

## Security Best Practices

1. **Always use HTTPS** (not HTTP)
2. Use dedicated service account
3. Strong passwords (12+ characters)
4. Rotate passwords every 90-180 days
5. Monitor failed login attempts

---

## Support

**Consultant**: Ana Šetka
**Client**: Kelteks
**JIRA**: ZGBCSKELTE-54

---

**Last Updated**: 2025-01-26
**Version**: 1.0.0
**Extension**: Kelteks API Integration BC27
