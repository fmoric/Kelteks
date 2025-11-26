# BC17 Extension - Basic Authentication Setup Guide

## Overview

This guide provides step-by-step instructions for setting up the Kelteks API Integration BC17 extension using **Basic Authentication** (username and password) to connect to BC v27.

**Best for**: On-premise BC17 to on-premise BC27 installations where Azure AD is not available.

**Advantages**:
- Simple setup, no Azure AD required
- Works well for on-premise environments
- Easy to troubleshoot

**Requirements**:
- HTTPS must be enabled (never use HTTP for Basic Auth)
- Service account with proper permissions
- BC27 must support Basic Authentication

---

## Prerequisites

- BC v17 environment installed and running
- BC v27 environment accessible over HTTPS
- Service account created in BC27
- Administrative rights in both BC environments
- Network connectivity from BC17 to BC27 over HTTPS (port 443)

---

## Step 1: Configure BC27 for Basic Authentication

### 1.1 Enable NavUserPassword Authentication
1. Open **Business Central Administration Shell** on BC27 server
2. Run the following PowerShell commands:

```powershell
# Enable NavUserPassword authentication
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "ClientServicesCredentialType" `
    -KeyValue "NavUserPassword"

# Restart the service
Restart-NAVServerInstance -ServerInstance BC270
```

### 1.2 Verify Web Services are Enabled
```powershell
# Check if web services are enabled
Get-NAVServerConfiguration -ServerInstance BC270 -KeyName "SOAPServicesEnabled"
Get-NAVServerConfiguration -ServerInstance BC270 -KeyName "ODataServicesEnabled"
```

Both should return `True`. If not, enable them:

```powershell
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "SOAPServicesEnabled" -KeyValue "True"
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "ODataServicesEnabled" -KeyValue "True"
Restart-NAVServerInstance -ServerInstance BC270
```

### 1.3 Verify HTTPS is Enabled
```powershell
# Check HTTPS binding
Get-NAVServerConfiguration -ServerInstance BC270 -KeyName "PublicODataBaseUrl"
Get-NAVServerConfiguration -ServerInstance BC270 -KeyName "PublicWebBaseUrl"
```

URLs must start with `https://`. If not configured:

```powershell
# Configure HTTPS (requires SSL certificate)
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "PublicODataBaseUrl" `
    -KeyValue "https://bc27-server:7048/BC270/ODataV4/"
    
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "PublicWebBaseUrl" `
    -KeyValue "https://bc27-server:7048/BC270/"
    
Restart-NAVServerInstance -ServerInstance BC270
```

---

## Step 2: Create Service Account in BC27

### 2.1 Create Windows User (if using Windows accounts)
1. On BC27 server, open **Computer Management**
2. Navigate to **Local Users and Groups** > **Users**
3. Right-click and select **New User**
4. Enter:
   - **User name**: `KELTEKS_SYNC_SVC`
   - **Full name**: `Kelteks Sync Service Account`
   - **Password**: Enter a strong password
   - Uncheck: "User must change password at next logon"
   - Check: "Password never expires" (for service accounts)
5. Click **Create**

### 2.2 Create BC User
1. Open BC27 Web Client
2. Navigate to **Users**
3. Click **New**
4. Enter:
   - **User Name**: `KELTEKS_SYNC_SVC` (or domain format: `DOMAIN\KELTEKS_SYNC_SVC`)
   - **Full Name**: `Kelteks Sync Service Account`
   - **Authentication Email**: Leave blank for Windows accounts
5. Click **OK**

### 2.3 Assign Permissions in BC27
1. Open the newly created user
2. Click **User Permission Sets**
3. Add the following permission sets (minimum required):
   - `D365 BUS FULL ACCESS` (or create custom permission set with):
     - Read/Write access to Sales Invoice (Table 36)
     - Read/Write access to Sales Credit Memo (Table 37)
     - Read/Write access to Sales Invoice Line (Table 37)
     - Read/Write access to Sales Cr.Memo Line (Table 38)
4. Click **OK**

### 2.4 Test Service Account Login
1. Open a browser in incognito/private mode
2. Navigate to BC27 Web Client URL
3. Log in with service account credentials:
   - Username: `DOMAIN\KELTEKS_SYNC_SVC` or `KELTEKS_SYNC_SVC`
   - Password: (the password you set)
4. Verify you can access BC27
5. Log out

---

## Step 3: Get BC27 Connection Details

### 3.1 Determine Base URL
The Base URL format for BC27 OData endpoint:
```
https://<server>:<port>/<instance>/ODataV4/
```

**Examples**:
- On-premise: `https://bc27-server.company.local:7048/BC270/ODataV4/`
- On-premise (custom port): `https://bc27.kelteks.hr:8443/BC270/ODataV4/`

### 3.2 Get Company ID
1. In BC27, navigate to **Companies**
2. Find your company name
3. Note the **ID** field (GUID format)

Or run this SQL query on BC27 database:
```sql
SELECT [ID], [Name] FROM [Company]
```

Example Company ID: `{a1b2c3d4-e5f6-7890-abcd-ef1234567890}`

---

## Step 4: Install BC17 Extension

### 4.1 Publish and Install
1. Open **Business Central Administration Shell** on BC17 server
2. Navigate to extension folder
3. Run:

```powershell
# Publish the extension
Publish-NAVApp -ServerInstance BC170 `
    -Path ".\KelteksAPIIntegrationBC17.app" `
    -SkipVerification

# Synchronize schema
Sync-NAVApp -ServerInstance BC170 `
    -Name "Kelteks API Integration BC17" `
    -Version "1.0.0.0"

# Install extension
Install-NAVApp -ServerInstance BC170 `
    -Name "Kelteks API Integration BC17" `
    -Version "1.0.0.0"
```

### 4.2 Verify Installation
1. Open BC17 Web Client
2. Search for **Extension Management**
3. Verify `Kelteks API Integration BC17` is listed and enabled

---

## Step 5: Assign Permissions in BC17

### 5.1 Assign Permission Set
1. In BC17, navigate to **Users**
2. Select the user who will configure the integration
3. Click **User Permission Sets**
4. Add: `KLT API Integration BC17`
5. Click **OK**

---

## Step 6: Configure BC17 Extension

### 6.1 Open Configuration Page
1. In BC17 Web Client, search for: `KLT API Configuration BC17`
2. Open the configuration page

### 6.2 Enter Connection Details

| Field | Value | Example |
|-------|-------|---------|
| **Base URL** | BC27 OData endpoint | `https://bc27-server:7048/BC270/ODataV4/` |
| **Company ID** | BC27 Company GUID | `{a1b2c3d4-e5f6-7890-abcd-ef1234567890}` |
| **Authentication Method** | Select: `Basic` | Basic |
| **Username** | Service account username | `DOMAIN\KELTEKS_SYNC_SVC` |
| **Password** | Service account password | `YourStrongPassword123!` |

**Important Notes**:
- Username format for domain accounts: `DOMAIN\USERNAME`
- Username format for local accounts: `USERNAME`
- Password will be masked after saving
- Do NOT use personal user accounts

### 6.3 Additional Settings

| Field | Value | Notes |
|-------|-------|-------|
| **Enabled** | ☑ Yes | Enable synchronization |
| **Batch Size** | 100 | Documents per sync cycle |
| **Sync Interval (Minutes)** | 15 | Sync frequency |
| **Max Retry Attempts** | 3 | Retry on failure |
| **Enable Logging** | ☑ Yes | Log all operations |
| **Alert Email** | admin@kelteks.com | Critical alerts |

---

## Step 7: Test Connection

### 7.1 Run Connection Test
1. In **KLT API Configuration BC17** page
2. Click **Actions** > **Test Connection**
3. Wait for the test to complete

### 7.2 Expected Results

✅ **Success**:
```
Connection successful!
BC27 Environment: Production
Company: Kelteks d.o.o.
Authentication: Basic (NavUserPassword)
```

❌ **Failure - Check**:
- Base URL is correct and ends with `/ODataV4/`
- HTTPS is used (not HTTP)
- Company ID matches BC27
- Username and password are correct
- Service account has permissions in BC27
- BC27 web services are enabled
- Firewall allows HTTPS traffic

---

## Step 8: Test with PowerShell (Optional)

Before proceeding, verify connectivity using PowerShell:

```powershell
# Test HTTPS connection
$url = "https://bc27-server:7048/BC270/ODataV4/Company('a1b2c3d4-e5f6-7890-abcd-ef1234567890')/salesInvoices"
$username = "DOMAIN\KELTEKS_SYNC_SVC"
$password = "YourStrongPassword123!"

# Create credentials
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

# Test connection
try {
    $response = Invoke-WebRequest -Uri $url -Credential $credential -Method GET
    Write-Host "Success! Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Content Type: $($response.Headers['Content-Type'])" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
```

Expected output:
```
Success! Status Code: 200
Content Type: application/json;odata.metadata=minimal;odata.streaming=true
```

---

## Step 9: Configure Automatic Synchronization

### 9.1 Create Job Queue Entry
1. In BC17, search for: `Job Queue Entries`
2. Click **New**
3. Fill in:
   - **Object Type to Run**: Codeunit
   - **Object ID to Run**: `50105`
   - **Object Caption to Run**: KLT Sync Engine BC17
   - **Description**: Kelteks Document Sync - BC17 to BC27
   - **Run on**: Monday, Tuesday, Wednesday, Thursday, Friday
   - **Starting Time**: `08:00:00`
   - **Ending Time**: `18:00:00`
   - **No. of Minutes between Runs**: `15`
   - **Status**: Ready
4. Click **OK**

### 9.2 Verify Job Queue
1. Wait 15 minutes
2. Check **Job Queue Log Entries**
3. Verify job ran successfully

---

## Step 10: Test Manual Synchronization

### 10.1 Create Test Invoice
1. In BC17, create and post a Sales Invoice
2. Navigate to **Posted Sales Invoices**
3. Find the invoice you just posted

### 10.2 Trigger Manual Sync
1. Select the invoice
2. Click **Actions** > **Sync to BC27**
3. Wait for confirmation message

### 10.3 Verify in BC27
1. Open BC27 Web Client
2. Navigate to **Sales Invoices** (unposted)
3. Verify the invoice appears with correct data

---

## Step 11: Monitor Synchronization

### 11.1 Check Sync Log
1. In BC17, search for: `KLT Document Sync Log BC17`
2. Review sync operations
3. Check Status column:
   - ✅ **Completed**: Successful
   - ❌ **Failed**: Error occurred
   - ⏳ **Pending**: Queued
   - 🔄 **Retrying**: Automatic retry in progress

### 11.2 Review Errors
For failed syncs:
1. Click on the failed entry
2. Click **Navigate** > **Error Messages**
3. Review error details
4. Fix the issue (e.g., missing customer in BC27)
5. Retry the sync

---

## Troubleshooting

### Issue: "401 Unauthorized"
**Cause**: Invalid credentials

**Solution**:
1. Verify username format (DOMAIN\USERNAME for domain accounts)
2. Test password by logging into BC27 Web Client
3. Ensure service account is not locked
4. Check if password has expired
5. Update credentials in configuration

### Issue: "404 Not Found"
**Cause**: Incorrect URL or Company ID

**Solution**:
1. Verify Base URL format: `https://server:port/instance/ODataV4/`
2. Test URL in browser (should prompt for login)
3. Verify Company ID in BC27
4. Ensure URL ends with `/ODataV4/` (with trailing slash)

### Issue: "403 Forbidden"
**Cause**: Insufficient permissions

**Solution**:
1. Check service account permissions in BC27
2. Ensure account has access to Sales Invoices
3. Verify account is not disabled
4. Check permission sets assigned to user

### Issue: "SSL/TLS Error"
**Cause**: Certificate issues

**Solution**:
1. Verify BC27 has valid SSL certificate
2. Check certificate is trusted on BC17 server
3. Import BC27 certificate to BC17 Trusted Root if self-signed
4. Verify TLS 1.2 is enabled on both servers

### Issue: "Connection Timeout"
**Cause**: Network or firewall

**Solution**:
1. Verify BC17 can ping BC27 server
2. Check firewall rules allow HTTPS (port 443 or 7048)
3. Test with telnet: `telnet bc27-server 7048`
4. Verify BC27 web service is running
5. Check proxy settings if applicable

---

## Security Best Practices

### 1. Strong Passwords
- Use passwords with minimum 12 characters
- Include uppercase, lowercase, numbers, symbols
- Change password every 90-180 days
- Never share service account password

### 2. Account Security
- Use dedicated service account (not personal account)
- Set "Password never expires" for service accounts
- Disable interactive logon for service account
- Monitor failed login attempts

### 3. Network Security
- **Always use HTTPS** - never HTTP for Basic Auth
- Use firewall to restrict access to BC27
- Consider VPN for cross-site connections
- Enable TLS 1.2 or higher only

### 4. Permission Security
- Grant minimum required permissions
- Do not use SUPER permission set
- Create custom permission set if needed
- Review permissions quarterly

### 5. Monitoring
- Enable audit logging in BC27
- Review sync logs daily
- Alert on repeated failures
- Monitor for unauthorized access attempts

---

## Performance Tuning

### Optimize Batch Size
- Start with 100 documents
- Increase to 200 if network is stable
- Decrease to 50 if timeouts occur

### Adjust Sync Interval
- Default: 15 minutes
- Peak hours: 10 minutes
- Off-peak: 30 minutes
- Overnight: 60 minutes

### Connection Pooling
Basic Authentication maintains connections. Monitor connection count:

```powershell
# On BC27 server - check active sessions
Get-NAVServerSession -ServerInstance BC270 | Where-Object {$_.ClientType -eq "ODataV4"}
```

---

## Maintenance Tasks

### Weekly
- [ ] Review sync log for errors
- [ ] Check success rate (should be > 95%)
- [ ] Verify job queue is running
- [ ] Monitor disk space for logs

### Monthly
- [ ] Test manual sync
- [ ] Verify service account is not locked
- [ ] Review error trends
- [ ] Archive old sync logs (> 90 days)

### Quarterly
- [ ] Review and update documentation
- [ ] Test failover scenarios
- [ ] Audit service account permissions
- [ ] Update passwords

### Annually
- [ ] Review SSL certificate expiration
- [ ] Update service account password
- [ ] Perform security audit
- [ ] Update extension if new version available

---

## Migration from OAuth to Basic

If migrating from OAuth:

1. Keep OAuth configuration as backup
2. Create new service account
3. Test Basic Auth in test environment
4. Update production configuration during maintenance window
5. Verify first sync completes successfully
6. Monitor for 24 hours before removing OAuth config

---

## Support

**Consultant**: Ana Šetka
**Client**: Kelteks
**JIRA**: ZGBCSKELTE-54

For issues:
1. Check sync log for specific errors
2. Review troubleshooting section
3. Test connectivity with PowerShell
4. Contact support with:
   - Error message from sync log
   - Error Message record details
   - Network configuration details

---

## Configuration Checklist

- [ ] BC27 Basic Auth enabled
- [ ] BC27 HTTPS configured
- [ ] BC27 web services enabled
- [ ] Service account created in Windows
- [ ] Service account created in BC27
- [ ] Permissions assigned in BC27
- [ ] Test login to BC27 successful
- [ ] Base URL determined
- [ ] Company ID obtained
- [ ] BC17 extension installed
- [ ] Permissions assigned in BC17
- [ ] Configuration completed
- [ ] Connection test successful
- [ ] PowerShell test successful (optional)
- [ ] Job queue created
- [ ] Manual sync tested
- [ ] Document verified in BC27
- [ ] Monitoring configured

---

**Last Updated**: 2025-01-26
**Version**: 1.0.0
**Extension**: Kelteks API Integration BC17
