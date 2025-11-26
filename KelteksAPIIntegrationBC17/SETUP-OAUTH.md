# BC17 Extension - OAuth 2.0 Authentication Setup Guide

## Overview

This guide provides step-by-step instructions for setting up the Kelteks API Integration BC17 extension using **OAuth 2.0 authentication** to connect to BC v27.

**Best for**: Cloud or hybrid scenarios where BC27 is cloud-hosted or when maximum security is required.

---

## Prerequisites

- BC v17 environment installed and running
- BC v27 environment accessible
- Azure Active Directory access (to register applications)
- Administrative rights in both BC environments
- Network connectivity from BC17 to BC27 over HTTPS

---

## Step 1: Register Azure AD Application for BC27

### 1.1 Access Azure Portal
1. Go to https://portal.azure.com
2. Sign in with administrator credentials
3. Navigate to **Azure Active Directory** > **App registrations**

### 1.2 Create New App Registration
1. Click **New registration**
2. Enter application details:
   - **Name**: `Kelteks-BC27-API`
   - **Supported account types**: `Accounts in this organizational directory only (Single tenant)`
   - **Redirect URI**: Leave blank for service-to-service authentication
3. Click **Register**

### 1.3 Note Application (Client) ID
1. On the Overview page, copy the **Application (client) ID**
2. Save this value - you'll need it for BC17 configuration
3. Copy the **Directory (tenant) ID**
4. Save this value as well

### 1.4 Create Client Secret
1. Navigate to **Certificates & secrets** in the left menu
2. Click **New client secret**
3. Enter description: `BC17 Integration Secret`
4. Select expiration: `24 months` (recommended)
5. Click **Add**
6. **IMPORTANT**: Copy the secret **Value** immediately (it won't be shown again)
7. Save this secret securely

### 1.5 Configure API Permissions
1. Navigate to **API permissions** in the left menu
2. Click **Add a permission**
3. Select **Dynamics 365 Business Central**
4. Select **Application permissions**
5. Check: `Automation.ReadWrite.All` and `API.ReadWrite.All`
6. Click **Add permissions**
7. Click **Grant admin consent** for your organization
8. Confirm the consent

---

## Step 2: Configure BC27 to Accept OAuth Requests

### 2.1 Enable OAuth in BC27
1. Open **Business Central Administration Shell** on BC27 server
2. Run the following PowerShell commands:

```powershell
# Set the Azure AD tenant ID
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "AzureActiveDirectoryClientId" `
    -KeyValue "<Application-Client-ID-from-Step-1.3>"

# Set the Azure AD tenant domain
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "AzureActiveDirectoryTenantId" `
    -KeyValue "<Directory-Tenant-ID-from-Step-1.3>"

# Enable Azure AD authentication
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "ClientServicesCredentialType" `
    -KeyValue "NavUserPassword,AccessControlService"

# Restart the service instance
Restart-NAVServerInstance -ServerInstance BC270
```

### 2.2 Verify Web Services are Enabled
1. Open BC27 Administration Shell
2. Run:

```powershell
Get-NAVServerConfiguration -ServerInstance BC270 -KeyName "SOAPServicesEnabled"
Get-NAVServerConfiguration -ServerInstance BC270 -KeyName "ODataServicesEnabled"
```

3. Both should return `True`. If not, enable them:

```powershell
Set-NAVServerConfiguration -ServerInstance BC270 -KeyName "SOAPServicesEnabled" -KeyValue "True"
Set-NAVServerConfiguration -ServerInstance BC270 -KeyName "ODataServicesEnabled" -KeyValue "True"
Restart-NAVServerInstance -ServerInstance BC270
```

### 2.3 Get Target Company ID
1. Open BC27 Web Client
2. Navigate to **Companies**
3. Find your company and note the **ID** field (GUID format)
4. Alternatively, run this AL code or query:

```sql
SELECT "ID", "Name" FROM Company
```

---

## Step 3: Install BC17 Extension

### 3.1 Publish and Install Extension
1. Open **Business Central Administration Shell** on BC17 server
2. Navigate to the folder containing `KelteksAPIIntegrationBC17.app`
3. Run:

```powershell
# Publish the extension
Publish-NAVApp -ServerInstance BC170 `
    -Path ".\KelteksAPIIntegrationBC17.app" `
    -SkipVerification

# Synchronize the schema
Sync-NAVApp -ServerInstance BC170 `
    -Name "Kelteks API Integration BC17" `
    -Version "1.0.0.0"

# Install the extension
Install-NAVApp -ServerInstance BC170 `
    -Name "Kelteks API Integration BC17" `
    -Version "1.0.0.0"
```

### 3.2 Verify Installation
1. Open BC17 Web Client
2. Search for **Extension Management**
3. Verify `Kelteks API Integration BC17` is installed and enabled

---

## Step 4: Assign Permissions

### 4.1 Assign Permission Set to User
1. In BC17, search for **Users**
2. Select the user account that will run the synchronization
3. Click **User Permission Sets**
4. Add permission set: `KLT API Integration BC17`
5. Click **OK**

### 4.2 Create Service Account (Recommended)
For production use, create a dedicated service account:

1. In BC17, navigate to **Users**
2. Create new user: `KELTEKS-SYNC-SERVICE`
3. Assign permission set: `KLT API Integration BC17`
4. Do not assign any other permissions (principle of least privilege)

---

## Step 5: Configure BC17 Extension

### 5.1 Open Configuration Page
1. In BC17 Web Client, search for: `KLT API Configuration BC17`
2. Open the configuration page

### 5.2 Enter BC27 Connection Details

Fill in the following fields:

| Field | Value | Example |
|-------|-------|---------|
| **Base URL** | BC27 OData endpoint | `https://api.businesscentral.dynamics.com/v2.0/<tenant-id>/Production/ODataV4/` |
| **Company ID** | BC27 Company GUID | `{12345678-1234-1234-1234-123456789012}` |
| **Authentication Method** | Select: `OAuth 2.0` | OAuth 2.0 |
| **Tenant ID** | Azure AD Tenant ID | `{87654321-4321-4321-4321-210987654321}` |
| **Client ID** | Application (client) ID from Step 1.3 | `{11111111-2222-3333-4444-555555555555}` |
| **Client Secret** | Secret value from Step 1.4 | `abc123def456...` |
| **OAuth Authority** | Azure AD authority URL | `https://login.microsoftonline.com/` |
| **OAuth Resource** | BC API resource | `https://api.businesscentral.dynamics.com/` |

### 5.3 Additional Settings

| Field | Value | Notes |
|-------|-------|-------|
| **Enabled** | ☑ Yes | Enable synchronization |
| **Batch Size** | 100 | Documents per sync cycle |
| **Sync Interval (Minutes)** | 15 | How often to sync |
| **Max Retry Attempts** | 3 | Retry failed documents |
| **Enable Logging** | ☑ Yes | Log all sync operations |
| **Alert Email** | admin@kelteks.com | Email for critical alerts |

---

## Step 6: Test Connection

### 6.1 Run Connection Test
1. In the **KLT API Configuration BC17** page
2. Click **Actions** > **Test Connection**
3. Wait for the test to complete

### 6.2 Verify Test Results
✅ **Success**: You should see a message like:
```
Connection successful!
BC27 Environment: Production
API Version: v2.0
Company: Kelteks d.o.o.
```

❌ **Failure**: If the test fails, check:
- Base URL is correct and accessible
- Company ID matches BC27
- Azure AD app credentials are correct
- BC27 web services are enabled
- Network connectivity (firewall, ports)

---

## Step 7: Configure Job Queue for Automatic Sync

### 7.1 Create Job Queue Entry
1. In BC17, search for: `Job Queue Entries`
2. Click **New**
3. Fill in:
   - **Object Type to Run**: Codeunit
   - **Object ID to Run**: `50105` (KLT Sync Engine BC17)
   - **Object Caption to Run**: KLT Sync Engine BC17
   - **Description**: Kelteks Document Sync - BC17 to BC27
   - **Run on**: Select days (Monday-Friday recommended)
   - **Starting Time**: `08:00:00`
   - **Ending Time**: `18:00:00`
   - **No. of Minutes between Runs**: `15`
   - **Maximum No. of Attempts to Run**: `3`
4. Set **Status** to: `Ready`
5. Click **OK**

### 7.2 Verify Job Queue is Running
1. Wait 15 minutes for first run
2. Check **KLT Document Sync Log BC17** page
3. Verify sync entries appear

---

## Step 8: Test Manual Synchronization

### 8.1 Sync a Posted Sales Invoice
1. Navigate to **Posted Sales Invoices** in BC17
2. Find a posted invoice (or create and post one)
3. Select the invoice
4. Click **Actions** > **Sync to BC27**
5. Wait for synchronization to complete

### 8.2 Verify in BC27
1. Open BC27 Web Client
2. Navigate to **Sales Invoices** (unposted)
3. Verify the invoice appears
4. Check that all fields are populated correctly:
   - Customer information
   - Line items
   - Amounts
   - VAT

---

## Step 9: Monitor and Maintain

### 9.1 Daily Monitoring
1. Open **KLT Document Sync Log BC17**
2. Review recent sync operations
3. Check for failed syncs (Status = Failed)
4. Review error messages for any failures

### 9.2 Review Error Messages
1. For failed syncs, click **Navigate** > **Error Messages**
2. Review detailed error information
3. Resolve issues (e.g., missing customer in BC27)
4. Retry failed documents via sync log

### 9.3 Token Refresh
OAuth tokens are automatically refreshed every 55 minutes. No manual intervention required.

---

## Troubleshooting

### Issue: "Authentication Failed"
**Cause**: Invalid credentials or expired secret

**Solution**:
1. Verify Client ID and Secret in Azure AD
2. Check if Client Secret has expired
3. Create new secret if needed
4. Update configuration in BC17
5. Test connection again

### Issue: "Company Not Found"
**Cause**: Incorrect Company ID

**Solution**:
1. Verify Company ID in BC27 matches configuration
2. Ensure format is GUID with braces: `{guid}`
3. Update configuration
4. Test connection

### Issue: "Insufficient Permissions"
**Cause**: Azure AD app doesn't have required permissions

**Solution**:
1. Go to Azure AD app registration
2. Check API permissions
3. Ensure `Automation.ReadWrite.All` is granted
4. Grant admin consent if needed
5. Wait 5-10 minutes for permissions to propagate

### Issue: "Network Error" or "Timeout"
**Cause**: Network connectivity or firewall

**Solution**:
1. Verify BC17 can reach BC27 URL via HTTPS
2. Test with browser or PowerShell:
   ```powershell
   Invoke-WebRequest -Uri "https://bc27-url/api/v2.0/"
   ```
3. Check firewall rules
4. Ensure port 443 is open
5. Verify DNS resolution

---

## Security Best Practices

1. **Rotate Secrets Regularly**: Create new Client Secret every 12-24 months
2. **Use Dedicated Service Account**: Don't use personal user accounts
3. **Monitor Access**: Review Azure AD sign-in logs regularly
4. **Limit Permissions**: Only grant required API permissions
5. **Enable Audit Logging**: Track all sync operations
6. **Secure Configuration**: Restrict access to configuration page
7. **Alert on Failures**: Configure email alerts for critical errors
8. **Test in Non-Production**: Always test changes in dev/test environment first

---

## Performance Optimization

1. **Adjust Batch Size**: Increase to 200 if network is fast and reliable
2. **Tune Sync Interval**: Reduce to 10 minutes during business hours if needed
3. **Monitor Token Cache**: Verify tokens are being reused (check logs)
4. **Review Error Rate**: Should be < 5% under normal conditions
5. **Archive Old Logs**: Delete sync logs older than 90 days

---

## Support

**Consultant**: Ana Šetka
**Client**: Kelteks
**JIRA**: ZGBCSKELTE-54

For issues:
1. Check **KLT Document Sync Log BC17** for error details
2. Review **Error Messages** for specific failures
3. Consult troubleshooting section above
4. Contact support with error details and sync log entries

---

## Appendix: Configuration Checklist

Use this checklist to verify your setup:

- [ ] Azure AD app registered
- [ ] Client ID and Secret obtained
- [ ] API permissions granted and consented
- [ ] BC27 OAuth configured
- [ ] BC27 web services enabled
- [ ] Target Company ID obtained
- [ ] BC17 extension installed
- [ ] Permission set assigned
- [ ] Configuration page filled out
- [ ] Connection test successful
- [ ] Job queue entry created
- [ ] Manual sync tested
- [ ] Document appears in BC27
- [ ] Monitoring setup configured
- [ ] Error alerting enabled

---

**Last Updated**: 2025-01-26
**Version**: 1.0.0
**Extension**: Kelteks API Integration BC17
