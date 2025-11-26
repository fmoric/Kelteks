# BC27 Extension - OAuth 2.0 Authentication Setup Guide

## Overview

This guide provides step-by-step instructions for setting up the Kelteks API Integration BC27 extension using **OAuth 2.0 authentication** to connect to BC v17.

**Best for**: Cloud or hybrid scenarios, or when BC v17 is cloud-hosted and maximum security is required.

---

## Prerequisites

- BC v27 environment installed and running (Platform 27.0, Runtime 14.0)
- BC v17 environment accessible
- Azure Active Directory access (to register applications)
- Administrative rights in both BC environments
- Network connectivity from BC27 to BC17 over HTTPS

---

## Step 1: Register Azure AD Application for BC17

### 1.1 Access Azure Portal
1. Go to https://portal.azure.com
2. Sign in with administrator credentials
3. Navigate to **Azure Active Directory** > **App registrations**

### 1.2 Create New App Registration
1. Click **New registration**
2. Enter application details:
   - **Name**: `Kelteks-BC17-API`
   - **Supported account types**: `Accounts in this organizational directory only (Single tenant)`
   - **Redirect URI**: Leave blank for service-to-service
3. Click **Register**

### 1.3 Note Application (Client) ID
1. Copy the **Application (client) ID**
2. Copy the **Directory (tenant) ID**
3. Save both values

### 1.4 Create Client Secret
1. Navigate to **Certificates & secrets**
2. Click **New client secret**
3. Enter description: `BC27 Integration Secret`
4. Select expiration: `24 months`
5. Click **Add**
6. **IMPORTANT**: Copy the secret **Value** immediately
7. Save securely

### 1.5 Configure API Permissions
1. Navigate to **API permissions**
2. Click **Add a permission**
3. Select **Dynamics 365 Business Central**
4. Select **Application permissions**
5. Check: `Automation.ReadWrite.All` and `API.ReadWrite.All`
6. Click **Add permissions**
7. Click **Grant admin consent**

---

## Step 2: Configure BC17 to Accept OAuth Requests

### 2.1 Enable OAuth in BC17
```powershell
# On BC17 server - Business Central Administration Shell
Set-NAVServerConfiguration -ServerInstance BC170 `
    -KeyName "AzureActiveDirectoryClientId" `
    -KeyValue "<Application-Client-ID>"

Set-NAVServerConfiguration -ServerInstance BC170 `
    -KeyName "AzureActiveDirectoryTenantId" `
    -KeyValue "<Directory-Tenant-ID>"

Set-NAVServerConfiguration -ServerInstance BC170 `
    -KeyName "ClientServicesCredentialType" `
    -KeyValue "NavUserPassword,AccessControlService"

Restart-NAVServerInstance -ServerInstance BC170
```

### 2.2 Verify Web Services
```powershell
Get-NAVServerConfiguration -ServerInstance BC170 -KeyName "SOAPServicesEnabled"
Get-NAVServerConfiguration -ServerInstance BC170 -KeyName "ODataServicesEnabled"
```

Both should be `True`.

### 2.3 Get BC17 Company ID
```sql
SELECT "ID", "Name" FROM Company
```

---

## Step 3: Install BC27 Extension

### 3.1 Publish and Install
```powershell
# On BC27 server - Business Central Administration Shell
Publish-NAVApp -ServerInstance BC270 `
    -Path ".\KelteksAPIIntegrationBC27.app" `
    -SkipVerification

Sync-NAVApp -ServerInstance BC270 `
    -Name "Kelteks API Integration BC27" `
    -Version "1.0.0.0"

Install-NAVApp -ServerInstance BC270 `
    -Name "Kelteks API Integration BC27" `
    -Version "1.0.0.0"
```

### 3.2 Verify Installation
1. Open BC27 Web Client
2. Search: **Extension Management**
3. Verify extension is installed

---

## Step 4: Assign Permissions

### 4.1 Assign Permission Set
1. In BC27, navigate to **Users**
2. Select the user
3. Click **User Permission Sets**
4. Add: `KLT API Integration BC27`
5. Click **OK**

---

## Step 5: Configure BC27 Extension

### 5.1 Open Configuration
Search for: `KLT API Configuration BC27`

### 5.2 Enter BC17 Connection Details

| Field | Value | Example |
|-------|-------|---------|
| **Base URL** | BC17 OData endpoint | `https://api.businesscentral.dynamics.com/v2.0/<tenant-id>/Production/ODataV4/` |
| **Company ID** | BC17 Company GUID | `{12345678-1234-1234-1234-123456789012}` |
| **Authentication Method** | `OAuth 2.0` | OAuth 2.0 |
| **Tenant ID** | Azure AD Tenant ID | `{87654321-4321-4321-4321-210987654321}` |
| **Client ID** | Application (client) ID | `{11111111-2222-3333-4444-555555555555}` |
| **Client Secret** | Secret value | `abc123def456...` |
| **OAuth Authority** | Azure AD authority URL | `https://login.microsoftonline.com/` |
| **OAuth Resource** | BC API resource | `https://api.businesscentral.dynamics.com/` |

### 5.3 Additional Settings

| Field | Value |
|-------|-------|
| **Enabled** | ☑ Yes |
| **Batch Size** | 100 |
| **Sync Interval (Minutes)** | 15 |
| **Max Retry Attempts** | 3 |
| **Enable Logging** | ☑ Yes |
| **Alert Email** | admin@kelteks.com |

---

## Step 6: Test Connection

### 6.1 Run Test
1. Click **Actions** > **Test Connection**
2. Wait for result

### 6.2 Expected Result
✅ **Success**:
```
Connection successful!
BC17 Environment: Production
API Version: v2.0
Company: Kelteks d.o.o.
```

---

## Step 7: Configure Job Queue

### 7.1 Create Job Queue Entry
1. Navigate to **Job Queue Entries**
2. Click **New**
3. Fill in:
   - **Object Type to Run**: Codeunit
   - **Object ID to Run**: `50155` (KLT Sync Engine BC27)
   - **Description**: Kelteks Document Sync - BC27 to BC17
   - **No. of Minutes between Runs**: `15`
   - **Status**: Ready

---

## Step 8: Test Synchronization

### 8.1 Create Test Purchase Invoice
1. In BC27, create an unposted Purchase Invoice
2. Navigate to **Purchase Invoices**
3. Select the invoice

### 8.2 Verify Sync
1. Wait for automatic sync (15 minutes)
2. Or trigger manually via Sync Engine
3. Check **KLT Document Sync Log BC27**
4. Verify document appears in BC17 Purchase Invoices

---

## Troubleshooting

### Issue: "Authentication Failed"
**Solution**:
1. Verify Client ID and Secret in Azure AD
2. Check if secret has expired
3. Create new secret if needed
4. Update configuration

### Issue: "Company Not Found"
**Solution**:
1. Verify Company ID matches BC17
2. Ensure GUID format with braces

### Issue: "Insufficient Permissions"
**Solution**:
1. Check API permissions in Azure AD
2. Ensure `Automation.ReadWrite.All` is granted
3. Grant admin consent
4. Wait 5-10 minutes for propagation

---

## Security Best Practices

1. **Rotate Secrets**: Every 12-24 months
2. **Use Service Account**: Not personal accounts
3. **Monitor Access**: Review Azure AD sign-in logs
4. **Limit Permissions**: Only required permissions
5. **Enable Audit Logging**: Track all operations
6. **Alert on Failures**: Configure email alerts

---

## Support

**Consultant**: Ana Šetka
**Client**: Kelteks
**JIRA**: ZGBCSKELTE-54

---

**Last Updated**: 2025-01-26
**Version**: 1.0.0
**Extension**: Kelteks API Integration BC27
