# Kelteks API Integration - Deployment Checklist

## Pre-Deployment Preparation

### Environment Verification

#### BC17 Environment
- [ ] Business Central version 17.0 or later installed
- [ ] Platform version 17.0 or later
- [ ] Runtime version 6.0 or later
- [ ] HTTPS enabled (required for Basic auth)
- [ ] Web services enabled
- [ ] Sufficient disk space for logs (minimum 1 GB)
- [ ] Network connectivity to BC27 environment verified

#### BC27 Environment
- [ ] Business Central version 27.0 or later installed
- [ ] Platform version 27.0 or later
- [ ] Runtime version 14.0 or later
- [ ] HTTPS enabled
- [ ] Web services enabled
- [ ] Sufficient disk space for logs (minimum 1 GB)
- [ ] Network connectivity to BC17 environment verified

### Master Data Preparation

#### Both Environments
- [ ] Chart of Accounts synchronized
- [ ] Customers synchronized (BC17 customers = BC27 vendors)
- [ ] Vendors synchronized (BC17 vendors = BC27 customers)
- [ ] Items synchronized
- [ ] Resources synchronized (if used)
- [ ] Locations synchronized
- [ ] Units of Measure synchronized
- [ ] Payment Terms synchronized
- [ ] Payment Methods synchronized
- [ ] Shipment Methods synchronized
- [ ] VAT Posting Groups synchronized
- [ ] General Posting Setup synchronized
- [ ] Customer Posting Groups synchronized
- [ ] Vendor Posting Groups synchronized
- [ ] Inventory Posting Setup synchronized

#### BC17 Specific
- [ ] Number Series configured for purchase documents
  - Purchase Invoice Nos.
  - Purchase Credit Memo Nos.
- [ ] Company Information complete
  - Company Name
  - Address
  - Registration details

#### BC27 Specific
- [ ] Number Series configured for purchase documents (if different)
- [ ] Fiskalizacija 2.0 settings configured
  - KPD codes
  - Tax categories
  - Vendor code mappings
- [ ] eRačun integration enabled
- [ ] Negative inventory allowed (if needed)
- [ ] Exact cost reversal disabled (per requirements)
- [ ] Manual numbering of sales invoices allowed (if needed)

### Security and Access

#### BC17 Users
- [ ] Service account created for API access
- [ ] Permission set "KELTEKS-API" assigned to service account
- [ ] Web services access enabled for service account
- [ ] User has access to all required companies

#### BC27 Users
- [ ] Service account created for API access
- [ ] API permissions configured (API.ReadWrite.All)
- [ ] User has access to all required companies

#### Authentication Setup

**For OAuth 2.0 (Cloud/SaaS):**
- [ ] Azure AD tenant identified
- [ ] App registration created in Azure AD
- [ ] Client ID noted
- [ ] Client Secret created and secured
- [ ] API permissions granted:
  - Dynamics 365 Business Central
  - Application permissions: API.ReadWrite.All
- [ ] Admin consent granted
- [ ] Tenant ID documented

**For Basic Authentication (On-Premise):**
- [ ] Service account username documented
- [ ] Service account password secured
- [ ] HTTPS verified on both environments
- [ ] Domain/FQDN documented

**For Windows Authentication (On-Premise):**
- [ ] ⚠️ **NOT SUPPORTED** in BC17 - Use OAuth or Basic instead

**For Certificate Authentication:**
- [ ] ⚠️ **REQUIRES MANUAL SETUP** in BC17 - Contact administrator
- [ ] Client certificate obtained
- [ ] Certificate installed on BC17 server
- [ ] Certificate thumbprint documented
- [ ] BC27 configured to accept certificate

## Extension Deployment

### BC17 Extension Installation

- [ ] Download/build KelteksAPIIntegrationBC17.app
- [ ] Verify app.json configuration:
  - App ID: `8a5e1b2c-3d4e-5f6a-7b8c-9d0e1f2a3b4c`
  - Version: `1.0.0.0`
  - Platform: `1.0.0.0` (BC17)
  - Runtime: `6.0`
- [ ] Install extension via Extension Management:
  ```
  Install-NAVApp -ServerInstance BC170 -Name "Kelteks API Integration BC17" -Version 1.0.0.0
  ```
- [ ] Verify installation successful
- [ ] Check for compilation errors
- [ ] Verify all objects deployed:
  - 7 Codeunits (50100-50106)
  - 3 Tables (50100-50103)
  - 6 Enums
  - 7 Pages
  - 1 Permission Set

### BC27 Extension Installation

- [ ] Download/build KelteksAPIIntegrationBC27.app
- [ ] Verify app.json configuration:
  - App ID: `8a5e1b2c-3d4e-5f6a-7b8c-9d0e1f2a3b4c` (same as BC17)
  - Version: `2.0.0.0`
  - Platform: `27.0.0.0` (BC27)
  - Runtime: `14.0`
- [ ] Install extension via Extension Management:
  ```
  Install-NAVApp -ServerInstance BC270 -Name "Kelteks API Integration BC27" -Version 2.0.0.0
  ```
- [ ] Verify installation successful
- [ ] Check for compilation errors
- [ ] Verify all objects deployed:
  - 7 Codeunits (50150-50156 + 50107 upgrade)
  - 3 Tables (50150-50153)
  - 6 Enums
  - 7 Pages
  - 1 Permission Set

## Initial Configuration

### Option 1: Guided Setup Wizard (Recommended - 5-10 minutes)

#### BC17 Configuration
- [ ] Open **KLT Guided Setup Wizard** page
- [ ] Complete Step 1: Deployment Type & Auth Method
  - Verify auto-detection
  - Select authentication method
- [ ] Complete Step 2: BC27 Connection
  - Enter BC27 Base URL
  - Enter BC27 Company ID
- [ ] Complete Step 3: Authentication
  - Enter credentials based on chosen method
- [ ] Complete Step 4: Review & Test
  - Review configuration
  - Test connection
- [ ] Complete Step 5: Finish
  - Optionally enable sync immediately
  - Optionally configure job queue

#### BC27 Configuration
- [ ] Open **KLT Guided Setup Wizard** page
- [ ] Complete Step 1: Deployment Type & Auth Method
  - Verify auto-detection
  - Select authentication method
- [ ] Complete Step 2: BC17 Connection
  - Enter BC17 Base URL
  - Enter BC17 Company ID
- [ ] Complete Step 3: Authentication
  - Enter credentials based on chosen method
- [ ] Complete Step 4: Review & Test
  - Review configuration
  - Test connection
- [ ] Complete Step 5: Finish
  - Optionally enable sync immediately
  - Optionally configure job queue

### Option 2: Manual Configuration (15-20 minutes)

#### BC17 Manual Setup
- [ ] Open **KLT API Configuration** page
- [ ] Fill in basic settings:
  - Deployment Type: `OnPremise` or `SaaS`
  - Authentication Method: Choose from 4 options
  - Target Base URL: BC27 API endpoint
  - Target Company ID: BC27 company GUID
- [ ] Fill in authentication details:
  - **OAuth**: Tenant ID, Client ID, Client Secret
  - **Basic**: Username, Password
  - **Windows**: Not supported
  - **Certificate**: Not supported without manual setup
- [ ] Configure sync settings:
  - Sync Interval (Minutes): `15` (default)
  - Batch Size: `100` (default)
  - Max Retry Attempts: `3` (default)
  - API Timeout (Seconds): `5` (default)
- [ ] Save configuration

#### BC27 Manual Setup
- [ ] Open **KLT API Configuration** page
- [ ] Fill in basic settings (pointing to BC17)
- [ ] Fill in authentication details
- [ ] Configure sync settings
- [ ] Save configuration

## Connection Testing

### BC17 → BC27 Connection
- [ ] Open **KLT API Configuration** in BC17
- [ ] Click **Test Connection** action
- [ ] Verify success message: "Connection successful"
- [ ] If failed, review error message and check:
  - Base URL correct
  - Company ID correct
  - Credentials valid
  - Network connectivity
  - Firewall rules

### BC27 → BC17 Connection
- [ ] Open **KLT API Configuration** in BC27
- [ ] Click **Test Connection** action
- [ ] Verify success message
- [ ] If failed, troubleshoot as above

## Job Queue Configuration

### BC17 Job Queue Entry
- [ ] Open **Job Queue Entries** page
- [ ] Create new entry:
  - Description: "Kelteks API Sync - BC17"
  - Object Type to Run: `Codeunit`
  - Object ID to Run: `80106`
  - Parameter String: (leave blank)
  - Recurrence Pattern: Every `15` minutes
  - Starting Time: `00:00:00`
  - Ending Time: `23:59:59`
  - Run on Mondays: ☑
  - Run on Tuesdays: ☑
  - Run on Wednesdays: ☑
  - Run on Thursdays: ☑
  - Run on Fridays: ☑
  - Run on Saturdays: ☑ (if needed)
  - Run on Sundays: ☑ (if needed)
- [ ] Set status to **Ready**
- [ ] Wait for first scheduled run
- [ ] Verify execution in Job Queue Log Entries

### BC27 Job Queue Entry
- [ ] Open **Job Queue Entries** page
- [ ] Create new entry:
  - Description: "Kelteks API Sync - BC27"
  - Object Type to Run: `Codeunit`
  - Object ID to Run: `80154`
  - Configure recurrence same as BC17
- [ ] Set status to **Ready**
- [ ] Verify execution

## Smoke Testing

### Test 1: Manual Sales Invoice Sync (BC17 → BC27)
- [ ] In BC17, create and post a test sales invoice
  - Customer: Use test customer that exists as vendor in BC27
  - Amount: Small test amount
- [ ] Open **Posted Sales Invoices**
- [ ] Select the test invoice
- [ ] Click **Sync to BC27** action
- [ ] Open **KLT Document Sync Log**
- [ ] Verify status = **Completed**
- [ ] In BC27, open **Purchase Invoices** (unposted)
- [ ] Find the synced document
- [ ] Verify:
  - Vendor correct
  - Amounts match
  - Lines match
  - Document unposted

### Test 2: Manual Purchase Invoice Sync (BC27 → BC17)
- [ ] In BC27, create unposted purchase invoice
  - Vendor: Use test vendor that exists as customer in BC17
  - Amount: Small test amount
- [ ] Run sync manually or wait for scheduled sync
- [ ] In BC17, open **Purchase Invoices** (unposted)
- [ ] Find the synced document
- [ ] Verify all fields match

### Test 3: Scheduled Sync Verification
- [ ] Wait for next scheduled job queue run (max 15 minutes)
- [ ] Check **Job Queue Log Entries** for successful execution
- [ ] Check **KLT Document Sync Log** for any new syncs
- [ ] Verify no errors in log

## Monitoring Setup

### Email Notifications (Optional)
- [ ] Configure Alert Email Address in **KLT API Configuration**
- [ ] Test email by triggering an error scenario
- [ ] Verify email received

### Performance Monitoring
- [ ] Open **KLT API Configuration** page
- [ ] View Sync Statistics FactBox
- [ ] Verify statistics updating correctly:
  - Total Pending
  - Total In Progress
  - Total Failed
  - Total Retrying

### Log Retention
- [ ] Configure log cleanup schedule (recommended: keep 12 months)
- [ ] Schedule cleanup job:
  - Object: Cleanup procedure (manual task)
  - Frequency: Monthly

## User Training

### Key Users Training
- [ ] Train on manual sync procedures
  - How to sync individual documents
  - How to batch sync multiple documents
- [ ] Train on monitoring sync logs
  - How to filter sync log
  - How to interpret error messages
  - How to retry failed syncs
- [ ] Train on queue management
  - How to view sync queue
  - How to prioritize documents
  - How to reset failed items
- [ ] Provide troubleshooting guide
- [ ] Document escalation procedures

## Post-Deployment Validation

### Day 1 Checks
- [ ] Verify scheduled sync executed at least once
- [ ] Review all sync log entries for errors
- [ ] Verify no critical errors in Event Log
- [ ] Check performance (< 5 seconds per document)
- [ ] Verify disk space still adequate

### Week 1 Checks
- [ ] Review sync success rate (target: > 95%)
- [ ] Review average sync duration
- [ ] Review any recurring errors
- [ ] Verify job queue running consistently
- [ ] Check with users for any issues

### Month 1 Checks
- [ ] Review total documents synced
- [ ] Review error patterns
- [ ] Review performance trends
- [ ] Consider adjusting batch size if needed
- [ ] Review and archive old logs

## Rollback Plan

### If Critical Issues Found
1. [ ] Disable sync immediately:
   - Set **Enable Sync** = No in both environments
2. [ ] Stop job queue entries:
   - Set status to **On Hold**
3. [ ] Review sync logs for partial syncs
4. [ ] Document all issues found
5. [ ] Uninstall extensions if needed:
   ```
   Uninstall-NAVApp -ServerInstance BC170 -Name "Kelteks API Integration BC17" -Version 1.0.0.0
   Uninstall-NAVApp -ServerInstance BC270 -Name "Kelteks API Integration BC27" -Version 2.0.0.0
   ```
6. [ ] Clean up any partial data:
   - Review unposted documents created
   - Delete if test data only
7. [ ] Schedule remediation plan

## Support and Escalation

### Level 1 Support (Key Users)
- Review sync logs
- Retry failed syncs
- Verify master data exists
- Check posting periods open

### Level 2 Support (IT)
- Review authentication settings
- Check network connectivity
- Review firewall rules
- Check web services enabled

### Level 3 Support (Developer/Consultant)
- **Consultant**: Ana Šetka
- **Email**: (to be filled in)
- **Phone**: (to be filled in)
- **JIRA Project**: ZGBCSKELTE-54

## Documentation Handover

### Provided Documentation
- [ ] README.md (project overview)
- [ ] TESTING-GUIDE.md (comprehensive testing procedures)
- [ ] DEPLOYMENT-CHECKLIST.md (this document)
- [ ] SETUP-OAUTH.md (OAuth setup guide)
- [ ] SETUP-BASIC.md (Basic auth setup guide)
- [ ] SETUP-WINDOWS.md (Windows auth info)
- [ ] SETUP-CERTIFICATE.md (Certificate auth info)
- [ ] GUIDED-SETUP-WIZARD.md (wizard user guide)
- [ ] TROUBLESHOOTING.md (troubleshooting guide - to be created)
- [ ] API-REFERENCE.md (API documentation - to be created)

### Custom Documentation Needed
- [ ] Environment-specific URLs documented
- [ ] Service account credentials documented (securely)
- [ ] Contact list for support
- [ ] Company-specific business rules
- [ ] Escalation procedures

## Sign-Off

### Technical Sign-Off
- [ ] IT Manager: ___________________ Date: _______
- [ ] DBA: __________________________ Date: _______
- [ ] Network Admin: ________________ Date: _______

### Business Sign-Off
- [ ] Finance Manager: ______________ Date: _______
- [ ] Key User: _____________________ Date: _______

### Project Sign-Off
- [ ] Project Manager: ______________ Date: _______
- [ ] Consultant: Ana Šetka _________ Date: _______

---

**Deployment Version**: 1.0  
**BC17 Extension**: v1.0.0.0  
**BC27 Extension**: v2.0.0.0  
**Deployment Date**: ___________  
**Go-Live Date**: ___________  
**Status**: ☐ Planned ☐ In Progress ☐ Completed ☐ Production
