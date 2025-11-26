# Quick Start Guide - On-Premise Setup with Basic Authentication

**FASTEST AND SIMPLEST** way to set up Kelteks API Integration for on-premise BC v17 and BC v27 environments.

---

## Overview

This guide focuses on **Basic Authentication** - the simplest authentication method for on-premise to on-premise connections. Perfect for:
- ✅ Local server environments
- ✅ Low to medium security requirements
- ✅ Quick setup without Azure AD complexity
- ✅ Minimal infrastructure changes

**Time to Complete**: 15-20 minutes

---

## Prerequisites

Before you start, ensure you have:

1. ✅ BC v17 server running and accessible
2. ✅ BC v27 server running and accessible
3. ✅ **HTTPS enabled** on both servers (Basic Auth requires HTTPS for security)
4. ✅ Service account with permissions in both environments
5. ✅ Network connectivity between BC17 and BC27 servers
6. ✅ Both extensions installed:
   - `KelteksAPIIntegrationBC17.app` on BC v17
   - `KelteksAPIIntegrationBC27.app` on BC v27

---

## Step 1: Install Extensions (5 minutes)

### On BC v17 Server

```powershell
# Install BC17 extension
Publish-NAVApp -ServerInstance BC170 -Path "C:\Path\To\KelteksAPIIntegrationBC17.app"
Sync-NAVApp -ServerInstance BC170 -Name "Kelteks API Integration BC17"
Install-NAVApp -ServerInstance BC170 -Name "Kelteks API Integration BC17"

# Assign permissions to users
New-NAVAppPermissionSet -ServerInstance BC170 -AppName "Kelteks API Integration BC17" -PermissionSetId "KLT API INTEGRATION BC17"
```

### On BC v27 Server

```powershell
# Install BC27 extension
Publish-NAVApp -ServerInstance BC270 -Path "C:\Path\To\KelteksAPIIntegrationBC27.app"
Sync-NAVApp -ServerInstance BC270 -Name "Kelteks API Integration BC27"
Install-NAVApp -ServerInstance BC270 -Name "Kelteks API Integration BC27"

# Assign permissions to users
New-NAVAppPermissionSet -ServerInstance BC270 -AppName "Kelteks API Integration BC27" -PermissionSetId "KLT API INTEGRATION BC27"
```

---

## Step 2: Create Service Account (3 minutes)

Create a dedicated service account in both BC environments:

### Option A: Windows Domain Account (Recommended)
```
Username: DOMAIN\KelteksSyncService
Password: <SecurePassword123!>
```

### Option B: Local BC Account
```
Username: kelteks.sync@yourdomain.com
Password: <SecurePassword123!>
```

**Grant Permissions** in both BC17 and BC27:
- Purchase documents (create, modify)
- Sales documents (read)
- API access enabled

---

## Step 3: Configure BC17 (5 minutes)

1. Open Business Central v17
2. Search for "**KLT API Configuration BC17**"
3. Fill in the following fields:

### General Settings
- **Authentication Method**: Select `Basic Authentication`
- **Deployment Type**: Select `On-Premise`

### BC27 Connection Settings
- **BC27 Base URL**: `https://bc27-server:7048/BC270/ODataV4/`
  - Replace `bc27-server` with your BC27 server name or IP
  - Ensure port `7048` matches your BC27 web service port
  - Path must end with `/ODataV4/`

- **BC27 Company ID**: `{GUID}`
  - Find this in BC27: Company Information → ID field
  - Example: `3fa85f64-5717-4562-b3fc-2c963f66afa6`

### Basic Authentication (On-Premise)
- **BC27 Username**: `DOMAIN\KelteksSyncService` or `kelteks.sync@yourdomain.com`
- **BC27 Password**: `<SecurePassword123!>`

### Synchronization Settings
- **Enable Sync**: Leave **unchecked** for now (enable after testing)
- **Sync Interval (Minutes)**: `15` (default)
- **Batch Size**: `100` (default)
- **API Timeout (Seconds)**: `5` (default)

### Error Handling
- **Max Retry Attempts**: `3` (default)
- **Log Retention Days**: `365` (default)
- **Alert Email Address**: `admin@yourdomain.com` (optional)
- **Critical Error Threshold %**: `25` (default)

### Purchase Document Settings
- **Purchase No. Series**: Select your number series (e.g., `P-INV+` or create new)

4. Click **Test Connection** button
   - If successful: "Connection test successful! Authentication method: Basic Authentication"
   - If failed: Check Error Messages for details

5. Once test succeeds, check **Enable Sync**

6. Click **Create Job Queue Entry**
   - This creates automatic synchronization every 15 minutes

---

## Step 4: Configure BC27 (5 minutes)

1. Open Business Central v27
2. Search for "**KLT API Configuration BC27**"
3. Fill in the following fields:

### General Settings
- **Authentication Method**: Select `Basic Authentication`
- **Deployment Type**: Select `On-Premise`

### BC17 Connection Settings
- **Target Base URL**: `https://bc17-server:7048/BC170/ODataV4/`
  - Replace `bc17-server` with your BC17 server name or IP
  - Ensure port `7048` matches your BC17 web service port
  - Path must end with `/ODataV4/`

- **Target Company ID**: `{GUID}`
  - Find this in BC17: Company Information → ID field
  - Example: `5ea85f64-6818-5673-c4gd-3d074g77bgb7`

### Basic Authentication (On-Premise)
- **Target Username**: `DOMAIN\KelteksSyncService` or `kelteks.sync@yourdomain.com`
- **Target Password**: `<SecurePassword123!>`

### Synchronization Settings
- **Enable Sync**: Leave **unchecked** for now (enable after testing)
- **Sync Interval (Minutes)**: `15` (default)
- **Batch Size**: `100` (default)
- **API Timeout (Seconds)**: `5` (default)

### Error Handling
- **Max Retry Attempts**: `3` (default)
- **Log Retention Days**: `365` (default)
- **Alert Email Address**: `admin@yourdomain.com` (optional)
- **Critical Error Threshold %**: `25` (default)

4. Click **Test Connection** button
   - If successful: "Connection test successful! Authentication method: Basic Authentication"
   - If failed: Check Error Messages for details

5. Once test succeeds, check **Enable Sync**

6. Click **Create Job Queue Entry**
   - This creates automatic synchronization every 15 minutes

---

## Step 5: Verify Setup (2 minutes)

### Test Manual Sync from BC17

1. Go to **Posted Sales Invoices** in BC17
2. Select one or more posted invoices
3. Click **Actions** → **Sync to BC27**
4. Confirm the action
5. Check **KLT Document Sync Log BC17** page
   - Status should show "Completed" (green)
   - Duration should be < 5 seconds per document

### Verify in BC27

1. Go to **Sales Invoices** in BC27 (unposted)
2. You should see the synchronized invoice(s)
3. Documents will be in **unposted** state
4. Post and send eRačun as normal

### Check Sync Logs

**In BC17:**
- Open **KLT Document Sync Log BC17**
- View recent sync history
- Check FactBox for 24-hour statistics

**In BC27:**
- Open **KLT Document Sync Log BC27**
- View recent sync history
- Check FactBox for 24-hour statistics

---

## Troubleshooting

### Connection Test Fails

**Error**: "Connection test failed"

**Solutions**:
1. Verify HTTPS is enabled (Basic Auth requires HTTPS)
2. Check firewall allows port 7048 between servers
3. Verify service account has API access
4. Test URL in browser: `https://bc27-server:7048/BC270/ODataV4/`
5. Check BC web service is enabled: `Set-NAVServerConfiguration BC170 -KeyName "SOAPServicesEnabled" -KeyValue true`

### Documents Not Syncing

**Check**:
1. Is **Enable Sync** checked?
2. Is Job Queue Entry running? (Go to Job Queue Entries)
3. Check **KLT Document Sync Log** for errors
4. Verify **KLT API Sync Queue** has documents pending

### Authentication Errors

**Error**: "401 Unauthorized"

**Solutions**:
1. Verify username format: `DOMAIN\User` or `user@domain.com`
2. Re-enter password (it may have been encrypted incorrectly)
3. Check service account permissions in BC
4. Verify account is not locked

### Master Data Missing

**Error**: "Customer not found" or "Item not found"

**Solution**:
- Ensure master data exists in target environment
- Customers, Items, Posting Groups must be synchronized
- See technical specification section 3.2 for required master data

---

## Daily Operations

### Monitoring (5 minutes daily)

1. Check **Document Sync Log** for errors
2. Review FactBox statistics:
   - Success rate should be > 95%
   - Failed documents should be < 5%
3. If error rate > 25%, alert email is sent

### Manual Sync

**From BC17** (Sales Documents):
- Posted Sales Invoices → Select documents → **Sync to BC27**
- Posted Sales Credit Memos → Select documents → **Sync to BC27**

**From BC27** (Purchase Documents):
- Automatic sync only (no manual trigger needed)
- Documents appear in BC17 Purchase Invoices (unposted)

---

## Security Best Practices

### For On-Premise Basic Authentication

✅ **DO**:
- Use HTTPS (SSL/TLS) - **REQUIRED**
- Use dedicated service account
- Rotate passwords every 90 days
- Monitor sync logs daily
- Limit service account permissions to minimum required
- Use complex passwords (>12 characters, mixed case, numbers, symbols)

❌ **DON'T**:
- Use HTTP (unencrypted) - Basic Auth sends credentials in Base64
- Use admin accounts
- Share service account with other integrations
- Store passwords in plain text
- Grant unnecessary permissions

### Password Rotation (Quarterly)

1. Change service account password in Active Directory
2. Update BC17 Configuration: **BC27 Password** field
3. Update BC27 Configuration: **Target Password** field
4. Test Connection in both environments
5. Document change in change log

---

## Performance Tuning

### Default Settings (Good for most cases)
- Sync Interval: 15 minutes
- Batch Size: 100 documents
- API Timeout: 5 seconds

### High-Volume Scenarios (200+ invoices/day)
- Sync Interval: 10 minutes
- Batch Size: 200 documents
- API Timeout: 10 seconds

### Low-Volume Scenarios (<50 invoices/day)
- Sync Interval: 30 minutes
- Batch Size: 50 documents
- API Timeout: 5 seconds

---

## Maintenance Schedule

### Weekly
- [ ] Review sync logs for errors
- [ ] Check job queue is running
- [ ] Verify success rate > 95%

### Monthly
- [ ] Archive old sync logs (auto-cleaned after 365 days)
- [ ] Review performance metrics
- [ ] Update documentation if needed

### Quarterly
- [ ] Rotate service account passwords
- [ ] Review and update permissions
- [ ] Test failover procedures

### Annually
- [ ] Full security audit
- [ ] Review architecture for optimization
- [ ] Update to latest extension version

---

## Next Steps

After successful setup:

1. ✅ **Test with Production Data**: Sync a few real invoices
2. ✅ **Train Users**: Show BC27 users how to post synced documents
3. ✅ **Monitor Performance**: Track sync duration and success rate
4. ✅ **Document Your Setup**: Note any custom configurations
5. ✅ **Plan for Growth**: Review volume trends monthly

---

## Support

**Client**: Kelteks
**Consultant**: Ana Šetka
**JIRA**: ZGBCSKELTE-54

**For Issues**:
1. Check **Error Messages** in BC (Table 700)
2. Review **KLT Document Sync Log** for details
3. See `TROUBLESHOOTING.md` for common issues
4. Contact support with:
   - Error message text
   - Sync log entry ID
   - Screenshot of configuration

**Documentation**:
- `README.md` - Complete user guide
- `SETUP-BASIC.md` - Detailed Basic Auth setup (this guide is summary)
- `TECHNICAL.md` - Technical specifications
- `TROUBLESHOOTING.md` - Issue resolution guide

---

## Success Criteria

✅ Connection test passes in both BC17 and BC27
✅ Manual sync successfully transfers documents
✅ Job queue runs automatically every 15 minutes
✅ Success rate > 95% after first week
✅ Zero critical errors
✅ BC27 users can post and send eRačun documents

---

**Setup Complete!** You now have automatic bidirectional document synchronization between BC v17 and BC v27 using Basic Authentication.

**Remember**: Basic Authentication is simple but requires HTTPS. For maximum security in high-compliance environments, consider upgrading to Certificate Authentication (see `SETUP-CERTIFICATE.md`).
