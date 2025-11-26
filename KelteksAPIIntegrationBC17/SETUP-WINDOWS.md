# BC17 Extension - Windows Authentication Setup Guide

## Overview

This guide provides step-by-step instructions for setting up the Kelteks API Integration BC17 extension using **Windows Authentication** (domain integrated security) to connect to BC v27.

**Best for**: On-premise BC17 and BC27 in the same Windows domain where single sign-on is preferred.

**Advantages**:
- No password storage required
- Domain integrated security (Kerberos)
- Single sign-on capability
- Automatic authentication using Windows credentials

**Requirements**:
- Both BC17 and BC27 must be in the same Windows domain
- Service Principal Names (SPNs) must be configured
- Kerberos delegation may be required

---

## Prerequisites

- BC v17 environment installed and running
- BC v27 environment accessible in the same Windows domain
- Active Directory domain membership for both servers
- Administrative rights on both servers
- Domain Administrator rights (for SPN configuration)
- Network connectivity between BC17 and BC27

---

## Step 1: Configure BC27 for Windows Authentication

### 1.1 Enable Windows Authentication
1. Open **Business Central Administration Shell** on BC27 server
2. Run:

```powershell
# Set credential type to Windows
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "ClientServicesCredentialType" `
    -KeyValue "Windows"

# Restart the service
Restart-NAVServerInstance -ServerInstance BC270
```

### 1.2 Enable Web Services
```powershell
# Enable OData and SOAP services
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "SOAPServicesEnabled" -KeyValue "True"
    
Set-NAVServerConfiguration -ServerInstance BC270 `
    -KeyName "ODataServicesEnabled" -KeyValue "True"
    
# Restart service
Restart-NAVServerInstance -ServerInstance BC270
```

### 1.3 Configure Service Account for BC27 Service
1. Open **Services** (services.msc) on BC27 server
2. Find **Microsoft Dynamics 365 Business Central Server [BC270]**
3. Right-click > **Properties**
4. Go to **Log On** tab
5. Select **This account**
6. Enter domain service account: `DOMAIN\BC27Service`
7. Enter password
8. Click **OK**
9. Restart the service

---

## Step 2: Configure Service Principal Names (SPNs)

SPNs are required for Kerberos authentication.

### 2.1 Register SPN for BC27 Service
On a domain controller or with domain admin rights, run:

```powershell
# Register HTTP SPN for BC27 server
setspn -S HTTP/bc27-server.company.local DOMAIN\BC27Service
setspn -S HTTP/bc27-server DOMAIN\BC27Service

# Register DynamicsNAV SPN
setspn -S DynamicsNAV/bc27-server.company.local DOMAIN\BC27Service
setspn -S DynamicsNAV/bc27-server DOMAIN\BC27Service

# Verify SPNs
setspn -L DOMAIN\BC27Service
```

Expected output:
```
Registered ServicePrincipalNames for CN=BC27Service,CN=Users,DC=company,DC=local:
        HTTP/bc27-server.company.local
        HTTP/bc27-server
        DynamicsNAV/bc27-server.company.local
        DynamicsNAV/bc27-server
```

---

## Step 3: Configure Kerberos Delegation (if required)

If BC17 and BC27 are on different servers, configure constrained delegation.

### 3.1 Configure Delegation for BC17 Service Account
1. Open **Active Directory Users and Computers**
2. Find the BC17 service account (e.g., `BC17Service`)
3. Right-click > **Properties**
4. Go to **Delegation** tab
5. Select **Trust this user for delegation to specified services only**
6. Select **Use any authentication protocol**
7. Click **Add** > **Users or Computers**
8. Enter: `BC27Service`
9. Click **OK**
10. Select the SPNs:
    - `HTTP/bc27-server.company.local`
    - `DynamicsNAV/bc27-server.company.local`
11. Click **OK**

---

## Step 4: Create Service Account for Synchronization

### 4.1 Create Domain User
1. Open **Active Directory Users and Computers**
2. Navigate to appropriate OU
3. Right-click > **New** > **User**
4. Enter:
   - **First name**: Kelteks
   - **Last name**: Sync Service
   - **User logon name**: `kelteks-sync-svc`
5. Click **Next**
6. Set strong password
7. Check: **Password never expires**
8. Uncheck: **User must change password at next logon**
9. Click **Next** > **Finish**

### 4.2 Add to Required Groups
Add the service account to:
- Domain Users (automatic)
- Any groups required for network access

### 4.3 Grant "Log on as a Service" Right
1. On BC17 server, open **Local Security Policy** (secpol.msc)
2. Navigate to: **Local Policies** > **User Rights Assignment**
3. Double-click **Log on as a service**
4. Click **Add User or Group**
5. Enter: `DOMAIN\kelteks-sync-svc`
6. Click **OK**

---

## Step 5: Create BC User in BC27

### 5.1 Create User
1. Open BC27 Web Client
2. Navigate to **Users**
3. Click **New**
4. Enter:
   - **User Name**: `DOMAIN\kelteks-sync-svc`
   - **Full Name**: `Kelteks Sync Service`
   - **Windows Security ID**: Click **...** and select the domain account
5. Click **OK**

### 5.2 Assign Permissions
1. Open the user record
2. Click **User Permission Sets**
3. Add minimum required permissions:
   - Read/Write to Table 36 (Sales Header)
   - Read/Write to Table 37 (Sales Line)
   - Read/Write to Table 114 (Sales Cr.Memo Header)
   - Read/Write to Table 115 (Sales Cr.Memo Line)
4. Or use permission set: `D365 BUS FULL ACCESS` (or custom)
5. Click **OK**

### 5.3 Test User Login
1. On BC17 server, run Command Prompt as `DOMAIN\kelteks-sync-svc`:
   ```cmd
   runas /user:DOMAIN\kelteks-sync-svc cmd
   ```
2. In the new command prompt, open browser
3. Navigate to BC27 Web Client
4. Should automatically log in (no password prompt)
5. Verify access to Sales Invoices

---

## Step 6: Get BC27 Connection Details

### 6.1 Determine Base URL
Format: `http://<server>:<port>/<instance>/ODataV4/`

**Note**: Windows Authentication can use HTTP on internal network (but HTTPS is still recommended)

Examples:
- HTTP: `http://bc27-server.company.local:7048/BC270/ODataV4/`
- HTTPS: `https://bc27-server.company.local:7048/BC270/ODataV4/`

### 6.2 Get Company ID
```sql
SELECT [ID], [Name] FROM [Company]
```

Example: `{a1b2c3d4-e5f6-7890-abcd-ef1234567890}`

---

## Step 7: Install BC17 Extension

### 7.1 Publish and Install
```powershell
# Open Business Central Administration Shell on BC17
Publish-NAVApp -ServerInstance BC170 `
    -Path ".\KelteksAPIIntegrationBC17.app" `
    -SkipVerification

Sync-NAVApp -ServerInstance BC170 `
    -Name "Kelteks API Integration BC17" `
    -Version "1.0.0.0"

Install-NAVApp -ServerInstance BC170 `
    -Name "Kelteks API Integration BC17" `
    -Version "1.0.0.0"
```

### 7.2 Verify Installation
1. Open BC17 Web Client
2. Search: **Extension Management**
3. Verify extension is installed

---

## Step 8: Assign Permissions in BC17

1. Navigate to **Users**
2. Select configuration user
3. Click **User Permission Sets**
4. Add: `KLT API Integration BC17`
5. Click **OK**

---

## Step 9: Configure BC17 Extension

### 9.1 Open Configuration
Search for: `KLT API Configuration BC17`

### 9.2 Enter Connection Details

| Field | Value | Example |
|-------|-------|---------|
| **Base URL** | BC27 OData endpoint | `http://bc27-server.company.local:7048/BC270/ODataV4/` |
| **Company ID** | BC27 Company GUID | `{a1b2c3d4-e5f6-7890-abcd-ef1234567890}` |
| **Authentication Method** | Select: `Windows` | Windows |
| **Use Default Credentials** | ☑ Yes | Use current Windows user |

**OR** (if running under specific account):

| Field | Value |
|-------|-------|
| **Use Default Credentials** | ☐ No |
| **Domain** | COMPANY |
| **Username** | kelteks-sync-svc |
| **Password** | (service account password) |

### 9.3 Additional Settings

| Field | Value |
|-------|-------|
| **Enabled** | ☑ Yes |
| **Batch Size** | 100 |
| **Sync Interval (Minutes)** | 15 |
| **Max Retry Attempts** | 3 |
| **Enable Logging** | ☑ Yes |
| **Alert Email** | admin@kelteks.com |

---

## Step 10: Test Connection

### 10.1 Run Test
1. Click **Actions** > **Test Connection**
2. Wait for result

### 10.2 Expected Result
✅ **Success**:
```
Connection successful!
BC27 Environment: Production
Company: Kelteks d.o.o.
Authentication: Windows (Negotiate/Kerberos)
User: DOMAIN\kelteks-sync-svc
```

❌ **Failure - Troubleshoot**:
- Verify SPNs are registered correctly
- Check delegation is configured
- Ensure service account has permissions
- Verify network connectivity
- Check Windows event logs for Kerberos errors

---

## Step 11: Test with PowerShell

```powershell
# Test Windows Authentication
$url = "http://bc27-server.company.local:7048/BC270/ODataV4/Company('guid')/salesInvoices"

# Use current Windows credentials
$response = Invoke-WebRequest -Uri $url -UseDefaultCredentials -Method GET

# Or use specific credentials
$username = "DOMAIN\kelteks-sync-svc"
$password = ConvertTo-SecureString "Password123!" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)
$response = Invoke-WebRequest -Uri $url -Credential $credential -Method GET

Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
```

---

## Step 12: Configure Job Queue

### 12.1 Set Service Account for BC17 Service
1. Open **Services** on BC17 server
2. Find **Microsoft Dynamics 365 Business Central Server [BC170]**
3. Right-click > **Properties** > **Log On** tab
4. Select **This account**: `DOMAIN\kelteks-sync-svc`
5. Enter password
6. Click **OK**
7. Restart BC17 service

### 12.2 Create Job Queue Entry
1. In BC17, navigate to **Job Queue Entries**
2. Click **New**
3. Fill in:
   - **Object Type to Run**: Codeunit
   - **Object ID to Run**: `50105`
   - **Description**: Kelteks Document Sync
   - **No. of Minutes between Runs**: `15`
   - **Status**: Ready
4. Save

---

## Step 13: Test Synchronization

### 13.1 Manual Sync
1. Go to **Posted Sales Invoices**
2. Select an invoice
3. Click **Actions** > **Sync to BC27**

### 13.2 Verify in BC27
1. Open BC27
2. Navigate to **Sales Invoices**
3. Verify document appears

---

## Troubleshooting

### Issue: "401 Unauthorized" with Windows Auth
**Cause**: Kerberos authentication failure

**Solution**:
1. Verify SPNs:
   ```powershell
   setspn -L DOMAIN\BC27Service
   ```
2. Check Event Viewer on BC17 server:
   - Windows Logs > Security
   - Look for Event ID 4625 (failed logon)
   - Look for Event ID 4768/4769 (Kerberos errors)
3. Verify service account in BC27 Users
4. Test with `klist` command:
   ```cmd
   klist get HTTP/bc27-server.company.local
   ```

### Issue: "The target principal name is incorrect"
**Cause**: SPN not registered or incorrect

**Solution**:
1. Re-register SPNs:
   ```powershell
   # Remove existing
   setspn -D HTTP/bc27-server.company.local DOMAIN\BC27Service
   # Add correct SPN
   setspn -A HTTP/bc27-server.company.local DOMAIN\BC27Service
   ```
2. Restart BC27 service
3. Clear Kerberos ticket cache on BC17:
   ```cmd
   klist purge
   ```

### Issue: "Delegation Failed"
**Cause**: Constrained delegation not configured

**Solution**:
1. Verify delegation settings in AD
2. Ensure "Use any authentication protocol" is selected
3. Verify SPNs are listed
4. Wait 15 minutes for AD replication
5. Restart both BC services

### Issue: NTLM Used Instead of Kerberos
**Cause**: SPN not found, falling back to NTLM

**Solution**:
1. Verify SPNs with `setspn -L`
2. Check DNS resolution of BC27 server
3. Verify using FQDN in Base URL
4. Force Kerberos by using FQDN:
   ```
   http://bc27-server.company.local:7048/BC270/ODataV4/
   ```
   (not just `http://bc27-server:7048/...`)

---

## Security Best Practices

1. **Use HTTPS**: Even with Windows Auth, encrypt traffic
2. **Least Privilege**: Grant minimum permissions to service account
3. **Constrained Delegation**: Use constrained (not unconstrained) delegation
4. **Monitor**: Review Kerberos authentication logs regularly
5. **Service Account**: Use dedicated account (not administrator)
6. **Password Policy**: Enforce strong password even if rarely used
7. **Audit**: Enable audit logging for the service account

---

## Performance Considerations

Windows Authentication is efficient because:
- No password transmission
- Ticket reuse (5-10 hours)
- Minimal overhead after initial authentication

Monitor:
- Kerberos ticket renewal
- Network latency for authentication
- Domain controller load

---

## Maintenance

### Weekly
- [ ] Check Windows event logs for authentication errors
- [ ] Verify service accounts not locked
- [ ] Review sync log

### Monthly
- [ ] Verify SPNs still registered
- [ ] Check delegation settings unchanged
- [ ] Test failover scenarios

### Quarterly
- [ ] Review service account permissions
- [ ] Audit Active Directory changes
- [ ] Update documentation

### Annually
- [ ] Rotate service account password
- [ ] Review and update delegation settings
- [ ] Security audit

---

## Support

**Consultant**: Ana Šetka
**Client**: Kelteks
**JIRA**: ZGBCSKELTE-54

For Kerberos issues:
1. Check Windows Security event log
2. Verify SPNs with `setspn -L`
3. Test Kerberos with `klist get`
4. Contact AD administrator if delegation issues
5. Provide event log entries with support request

---

## Configuration Checklist

- [ ] BC27 configured for Windows Authentication
- [ ] BC27 web services enabled
- [ ] BC27 service running under domain account
- [ ] SPNs registered for BC27 service
- [ ] Delegation configured (if multi-server)
- [ ] Service account created in AD
- [ ] Service account added to BC27 Users
- [ ] Permissions assigned in BC27
- [ ] Test login successful
- [ ] Base URL (with FQDN) obtained
- [ ] Company ID obtained
- [ ] BC17 extension installed
- [ ] Permissions assigned in BC17
- [ ] Configuration completed
- [ ] Connection test successful
- [ ] PowerShell test successful
- [ ] BC17 service using service account
- [ ] Job queue created
- [ ] Manual sync tested
- [ ] Document verified in BC27

---

**Last Updated**: 2025-01-26
**Version**: 1.0.0
**Extension**: Kelteks API Integration BC17
