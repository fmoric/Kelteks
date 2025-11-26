# Kelteks API Integration BC27

**Version:** 1.0.0.0  
**For:** Microsoft Dynamics 365 Business Central v27 (On-Premise/Cloud)  
**Purpose:** Fiskalizacija 2.0 Compliance - Document Synchronization

## Overview

This extension enables **inbound** receipt of posted sales documents from BC v17 and **outbound** synchronization of purchase documents to BC v17. It is part of a split architecture designed specifically for Fiskalizacija 2.0 compliance and eRačun (electronic invoice) exchange.

### What This Extension Does

**Inbound from BC17:**
- Sales Invoices ← BC17 (created as unposted Sales Invoices)
- Sales Credit Memos ← BC17 (created as unposted Sales Credit Memos)

**Outbound to BC17:**
- Purchase Invoices → BC17 (from unposted Purchase Invoices)
- Purchase Credit Memos → BC17 (from unposted Purchase Credit Memos)

### Companion Extension

This extension **requires** the companion extension **KelteksAPIIntegrationBC17** to be installed on your BC v17 environment for bidirectional synchronization.

### eRačun Workflow

1. Receive sales documents from BC17 (created as unposted)
2. Users review and post sales invoices/credit memos
3. Generate and send eRačun to customers
4. Incoming eRačuni from vendors are created as purchase documents
5. Purchase documents are synchronized to BC17 for processing

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Authentication Options](#authentication-options)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Usage](#usage)
6. [Monitoring](#monitoring)
7. [Troubleshooting](#troubleshooting)
8. [Support](#support)

---

## System Requirements

### Business Central Version
- **Microsoft Dynamics 365 Business Central v27** (On-Premise or Cloud)
- Platform: 27.0.0.0
- Runtime: 14.0

### Prerequisites

#### Master Data (Must exist in both BC17 and BC27)
- Customers & Vendors
- Items & Resources
- Chart of Accounts
- Posting Groups (Inventory, VAT, General, Customer/Vendor, Prepayment)
- Payment Terms & Payment Methods
- Currency Codes
- Units of Measure
- Shipment Methods
- Locations
- Vendor Bank Accounts
- Company Information
- Fiskalizacija 2.0 settings (KPD codes, tax categories, vendor code mappings)

#### Network Requirements
- HTTPS connectivity to BC v17 environment
- TLS 1.2 or higher support
- Outbound firewall rules allowing HTTPS traffic to BC v17

#### BC27 Configuration
- **Enable negative inventory** (required)
- **Disable exact cost reversal** (storno točnog troška)
- **Allow manual numbering** of sales invoices
- Configure prepayment posting (manual process)

---

## Authentication Options

This extension supports multiple authentication methods for on-premise installations:

### 1. OAuth 2.0 (Recommended)

**Best for:** Cloud or hybrid scenarios, BC v17 in Azure

**Requirements:**
- Azure AD tenant
- App registration in Azure AD for BC v17
- Client ID and Client Secret
- Tenant ID

**Advantages:**
- Industry-standard authentication
- Token-based security
- Automatic token refresh (55-minute cache)
- No password storage
- Best security practices

**Configuration:**
```
Target Base URL: https://api.businesscentral.dynamics.com/v2.0/{tenant}/Production
Company ID: {GUID}
Tenant ID: {tenant-guid}
Client ID: {app-id}
Client Secret: {app-secret}
```

**Setup Steps:**
1. Register app in Azure AD
2. Grant API permissions: `Dynamics 365 Business Central` → `API.ReadWrite.All`
3. Create client secret
4. Copy Client ID, Tenant ID, and Client Secret to configuration

### 2. Basic Authentication (On-Premise)

**Best for:** Both BC v17 and BC v27 are on-premise

**Requirements:**
- BC v17 configured for Basic Authentication
- Service account credentials
- Web services enabled in BC v17

**Advantages:**
- Simpler setup for on-premise
- No Azure AD dependency
- Direct credential authentication
- Works with NAV authentication

**Configuration:**
```
Target Base URL: https://bc17-server:7048/BC170/ODataV4/Company('{company-name}')
Authentication Type: Basic
Username: DOMAIN\ServiceAccount
Password: {service-account-password}
```

**Important Notes:**
- Create a dedicated service account (not a user account)
- Grant minimum required permissions (read posted sales docs, write purchase docs)
- **Always use HTTPS** (not HTTP) to protect credentials in transit
- Rotate service account password regularly (e.g., every 90 days)
- Audit service account activity

### 3. Windows Authentication (On-Premise)

**Best for:** Both environments in the same Windows domain

**Requirements:**
- BC v17 configured for Windows Authentication
- Service account in Windows domain
- Both servers in same domain or trusted domains
- Kerberos delegation configured (for cross-server access)

**Advantages:**
- Single sign-on capability
- No password stored in BC27
- Leverages Windows domain security
- Integrated with Active Directory

**Configuration:**
```
Target Base URL: https://bc17-server:7048/BC170/ODataV4/Company('{company-name}')
Authentication Type: Windows
Service Account: DOMAIN\ServiceAccount
```

**Setup Requirements:**
1. Create service account in Active Directory
2. Grant service account permissions to BC v17
3. Configure SPN (Service Principal Name) for BC v17 service
4. Enable Kerberos delegation if needed
5. Test authentication from BC27 server

### 4. Certificate Authentication (Advanced)

**Best for:** High-security on-premise environments

**Requirements:**
- SSL/TLS certificates
- Certificate installed in BC v17 and BC27
- Certificate-based authentication enabled

**Advantages:**
- No password transmission
- Certificate-based trust
- High security
- Non-repudiation

**Configuration:**
```
Target Base URL: https://bc17-server:7048/BC170/ODataV4/
Authentication Type: Certificate
Certificate Thumbprint: {thumbprint}
```

### Authentication Comparison

| Method | On-Premise | Cloud | Security | Setup Complexity |
|--------|-----------|-------|----------|------------------|
| OAuth 2.0 | ✓ | ✓✓ | ✓✓✓ | Medium |
| Basic Auth | ✓✓ | ✗ | ✓ | Low |
| Windows Auth | ✓✓ | ✗ | ✓✓ | Medium |
| Certificate | ✓✓ | ✓ | ✓✓✓ | High |

**Recommendation:**
- **On-Premise to On-Premise**: Use Windows or Basic Authentication
- **Cloud to On-Premise**: Use OAuth 2.0
- **Cloud to Cloud**: Use OAuth 2.0
- **High Security**: Use OAuth 2.0 or Certificate Authentication

---

## Installation

### Step 1: Verify Prerequisites

1. Ensure all master data is synchronized between BC17 and BC27
2. Verify network connectivity to BC v17
3. Prepare authentication credentials (OAuth, Basic, or Windows)
4. Configure BC27 system settings (negative inventory, exact cost reversal)

### Step 2: Install Extension

#### For On-Premise BC27

1. Download **KelteksAPIIntegrationBC27.app**
2. Open Business Central v27 Administration Shell (Run as Administrator)
3. Install the extension:

```powershell
# Install extension
Publish-NAVApp -ServerInstance BC270 -Path "C:\Path\To\KelteksAPIIntegrationBC27.app" -SkipVerification

# Sync extension
Sync-NAVApp -ServerInstance BC270 -Name "Kelteks API Integration BC27" -Version 1.0.0.0

# Install for all tenants or specific tenant
Install-NAVApp -ServerInstance BC270 -Name "Kelteks API Integration BC27" -Version 1.0.0.0

# Verify installation
Get-NAVAppInfo -ServerInstance BC270 -Name "Kelteks API Integration BC27"
```

#### For Cloud BC27

1. Go to **Extension Management**
2. Click **Upload Extension**
3. Select **KelteksAPIIntegrationBC27.app**
4. Click **Deploy** → **Install**
5. Wait for installation to complete

### Step 3: Assign Permissions

Assign the **KLT API Integration BC27** permission set to users who will:
- Configure the integration
- Monitor synchronization
- Post sales documents
- Review incoming purchase documents
- Resolve synchronization errors

**Role Centers:**
- Order Processor
- Sales & Relationship Manager
- Purchasing Agent
- Accountant

---

## Configuration

### Using the Configuration Page

1. Search for **KLT API Configuration BC27**
2. Click **New** (only one record allowed - singleton pattern)
3. Configure the following settings:

#### General Settings
- **Target Environment Name**: BC17 (descriptive name)
- **Base URL**: Full URL to BC v17 API endpoint
  - Cloud: `https://api.businesscentral.dynamics.com/v2.0/{tenant}/Production`
  - On-Prem: `https://bc17-server:7048/BC170/ODataV4/`
- **Company ID**: GUID of target company in BC v17
- **Enabled**: Check to enable synchronization

#### Authentication Settings

**For OAuth 2.0:**
- **Authentication Type**: OAuth 2.0
- **Tenant ID**: Azure AD tenant GUID
- **Client ID**: Azure AD app registration client ID  
- **Client Secret**: Azure AD app registration client secret

**For Basic Authentication:**
- **Authentication Type**: Basic
- **Username**: DOMAIN\ServiceAccount or email
- **Password**: Service account password (encrypted)

**For Windows Authentication:**
- **Authentication Type**: Windows
- **Service Account**: DOMAIN\ServiceAccount
- (Password managed by Windows)

#### Synchronization Settings
- **Batch Size**: Documents per sync cycle (default: 100, max: 200)
- **Sync Interval (Minutes)**: Frequency of sync (default: 15, min: 5)
- **Max Retry Attempts**: Retry count for failures (default: 3, max: 5)
- **Enable Auto Retry**: Auto-retry transient failures
- **Retry Interval Base (Minutes)**: Starting interval for retry (default: 1)

#### Data Mapping
- **Default Location Code**: Location for incoming documents (if not specified)
- **Default Payment Terms**: Payment terms if missing from source
- **Create Missing Items**: Auto-create items if not found (not recommended)

4. Click **Test Connection** to verify configuration
5. Review test results
6. If successful, click **Enable Synchronization**

### System Settings Validation

The extension validates required BC27 settings:

**Required:**
- ✓ Negative inventory enabled
- ✓ Exact cost reversal disabled
- ✓ Manual sales invoice numbering allowed

**Warnings (Optional):**
- △ Purchase number series configured
- △ Job queue running

Use the **Validate Settings** action to check configuration.

---

## Usage

### Automatic Synchronization

Once configured and enabled:

**Inbound (Sales Documents from BC17):**
1. BC17 extension POSTs sales documents to BC27
2. Documents created as unposted Sales Invoices/Credit Memos
3. Users review documents in BC27
4. Users post documents (manually)
5. Generate and send eRačun to customers

**Outbound (Purchase Documents to BC17):**
1. Every 15 minutes, extension queries unposted Purchase Invoices/Credit Memos
2. Only documents marked for sync are sent
3. Documents POSTed to BC17 purchaseInvoices/purchaseCreditMemos API
4. Documents created in BC17 as unposted
5. BC17 users review and post

### Manual Synchronization

**For Incoming Sales Documents:**
1. Open **Sales Invoices** or **Sales Credit Memos**
2. Review documents received from BC17
3. Verify all data is correct (customer, items, amounts)
4. Post documents normally
5. Send eRačun using Fiskalizacija 2.0 functionality

**For Outgoing Purchase Documents:**
1. Open **Purchase Invoices** or **Purchase Credit Memos**
2. Select documents to sync
3. Click **Actions → Functions → Sync to BC17**
4. Review sync status in **KLT Document Sync Log**

### Job Queue Management

The extension creates a job queue entry automatically:

- **Object Type**: Codeunit
- **Object ID**: 50154 (KLT Sync Engine BC27)
- **Status**: Ready
- **Recurrence**: Every 15 minutes (configurable)
- **Job Queue Category**: KLT API Sync

**To manage:**
1. Search for **Job Queue Entries**
2. Filter on **Object ID** = 50154
3. Use actions: Start, Stop, Reschedule, Delete

---

## Monitoring

### Sync Log

Monitor all synchronization activity:

1. Search for **KLT Document Sync Log**
2. View columns:
   - **Entry No.**: Unique log ID
   - **Sync Direction**: Inbound (from BC17) or Outbound (to BC17)
   - **Document Type**: Sales Invoice, Sales Credit Memo, Purchase Invoice, Purchase Credit Memo
   - **Source Document No.**: Document number in source system
   - **Target Document No.**: Created document number
   - **Status**: Pending, Completed, Failed, Retrying
   - **Duration (ms)**: Sync processing time
   - **Created DateTime**: When sync started
   - **Completed DateTime**: When sync finished
   - **Error Message**: Error details if failed

**Filters:**
- By sync direction
- By document type
- By date range
- By status
- By external document number

**Actions:**
- Retry Failed: Manually retry a failed sync
- View Document: Navigate to source/target document
- View Errors: See detailed error messages

### Error Management

Errors are logged to Business Central's standard **Error Message** table:

1. Search for **Error Messages**
2. Filter by **Context**: "KLT Document Sync Log"
3. Review error details:
   - **Message**: Error description
   - **Context Table**: KLT Document Sync Log
   - **Context Record ID**: Link to sync log entry
   - **Created At**: Error timestamp

**Error Categories:**
- **API Communication**: Network, timeout, service unavailable
- **Data Validation**: Missing fields, invalid values, format errors
- **Business Logic**: Posting period closed, negative inventory, VAT mismatch
- **Authentication**: Credentials invalid, token expired, unauthorized
- **Master Data Missing**: Customer, vendor, item, account not found

### Statistics Dashboard

View sync statistics on **KLT API Configuration BC27** page:

**Metrics:**
- Total Documents Synced
- Successful Syncs
- Failed Syncs
- Success Rate (%)
- Last Sync DateTime
- Average Duration (ms)
- Documents in Queue

**Charts (if available):**
- Sync volume by day
- Success rate trend
- Error rate by category
- Performance metrics

---

## Troubleshooting

### Connection Test Fails

**Error**: "Unable to connect to BC17"

**Checks:**
1. Verify Base URL is correct
2. Test network connectivity: `Test-NetConnection bc17-server -Port 7048`
3. Check firewall rules (outbound HTTPS allowed)
4. Verify BC v17 web services are enabled
5. Test authentication credentials separately

**For OAuth:**
- Verify Client ID, Secret, Tenant ID
- Check app permissions in Azure AD
- Ensure app secret hasn't expired

**For Basic:**
- Verify username/password correct
- Check account isn't locked
- Ensure account has permissions

### Sales Documents Not Appearing

**Symptom**: BC17 shows synced but documents missing in BC27

**Solutions:**
1. Check **KLT Document Sync Log** for entries
2. Verify sync status (should be "Completed")
3. Search **Sales Invoices** / **Sales Credit Memos**
4. Check document filters (clear all filters)
5. Verify posting date is valid
6. Review error messages if status is "Failed"

### Purchase Documents Not Syncing to BC17

**Symptom**: Purchase documents created but not sent to BC17

**Solutions:**
1. Verify documents are marked for sync
2. Check job queue is running: **Job Queue Entries**
3. Review **KLT Document Sync Log** for errors
4. Verify BC17 API is accessible from BC27
5. Check master data exists in BC17 (vendors, items)
6. Ensure posting periods open in BC17

### Authentication Errors

**Error**: "401 Unauthorized" or "Authentication failed"

**For OAuth:**
1. Verify token hasn't expired (auto-refresh should work)
2. Check Client Secret is still valid
3. Verify app permissions in Azure AD
4. Clear token cache and retry: **Clear Auth Cache** action

**For Basic:**
1. Verify username format: `DOMAIN\Username`
2. Check password hasn't expired
3. Use **Change Password** action to update
4. Verify service account isn't locked

**For Windows:**
1. Check service account has permissions
2. Verify SPN configuration
3. Test from BC27 server command line
4. Review Kerberos delegation settings

### Duplicate Documents

**Symptom**: Same document created multiple times

**Prevention:**
- Extension uses **External Document No.** for duplicate detection
- Automatic check before creating document

**If duplicates exist:**
1. Check **External Document No.** is populated
2. Review sync log for duplicate entries
3. Delete duplicate documents manually
4. Verify duplicate check is enabled in configuration

### Performance Issues

**Symptom**: Sync takes too long or times out

**Solutions:**
1. Reduce batch size (try 50 instead of 100)
2. Increase sync interval (20-30 minutes)
3. Check network latency: `Test-Connection bc17-server`
4. Review BC17 server performance
5. Optimize master data lookups
6. Consider off-peak sync schedule

### Master Data Errors

**Error**: "Customer/Vendor/Item not found"

**Solutions:**
1. Ensure master data synchronized between environments
2. Check exact spelling and codes match
3. Use master data migration tool
4. Enable **Create Missing Items** (if appropriate)
5. Update item cross-references

---

## Support

### Documentation Files

- **README.md** (this file): Complete usage guide
- **README-SPLIT.md**: Split architecture overview
- **SPLIT-ARCHITECTURE.md**: Technical architecture details
- **BC17 Extension README**: Companion extension documentation

### Built-in Help

- **Field tooltips**: Hover over fields for descriptions
- **Action tooltips**: Hover over actions for help
- **Error Message**: Click for detailed error information

### Error Message Integration

This extension integrates with Business Central's standard error management:

- All errors logged to **Error Message** table
- View using **Error Messages** page
- Supports error filtering and categorization
- Links to related records
- Supports resolution tracking

### Logging and Diagnostics

**Log Retention:**
- Sync logs: 365 days (configurable)
- Error messages: 90 days (BC standard)
- Authentication logs: 30 days

**Diagnostic Actions:**
- **Test Connection**: Verify API connectivity
- **Validate Settings**: Check BC27 configuration
- **Clear Auth Cache**: Force token refresh
- **Export Log**: Export sync log to Excel
- **View Statistics**: Real-time metrics

### Contact Information

- **Client**: Kelteks
- **Consultant**: Ana Šetka
- **JIRA**: ZGBCSKELTE-54
- **Area**: Sales & Procurement
- **Purpose**: Fiskalizacija 2.0 Compliance

---

## Technical Details

### Object ID Range
50150-50199

### Key Objects

**Tables:**
- 50150: KLT API Configuration BC27
- 50151: KLT Document Sync Log
- 50153: KLT API Sync Queue

**Enums:**
- 50150: KLT Document Type
- 50151: KLT Sync Status
- 50152: KLT Error Category
- 50153: KLT Sync Direction

**Codeunits:**
- 50150: KLT API Auth BC27 (Authentication)
- 50154: KLT Sync Engine BC27 (Orchestration)

**Pages:**
- 50150: KLT API Configuration BC27
- 50151: KLT Document Sync Log

### Security Features

- **Encrypted Credentials**: All passwords encrypted in database
- **Masked Fields**: Credentials hidden in UI (ExtendedDatatype = Masked)
- **TLS 1.2+**: Required for all API communications
- **Token Caching**: OAuth tokens cached for 55 minutes
- **Permission Sets**: Granular access control
- **Audit Trail**: All sync operations logged

### API Endpoints

**Read from BC17 (inbound to BC27):**
- Received via POST from BC17 extension
- BC17 POSTs to BC27 API endpoints

**Write to BC17 (outbound from BC27):**
- POST `/api/v2.0/companies({id})/purchaseInvoices`
- POST `/api/v2.0/companies({id})/purchaseCreditMemos`

**Read from BC27 (for BC17 to pull sales):**
- GET `/api/v2.0/companies({id})/salesInvoices`
- GET `/api/v2.0/companies({id})/salesCreditMemos`

### Field Mappings

**Sales Invoice Header:**
- Customer → Sell-to Customer No.
- Invoice Date → Document Date
- Due Date → Due Date
- Currency → Currency Code
- Payment Terms → Payment Terms Code

**Purchase Invoice Header:**
- Vendor → Buy-from Vendor No.
- Invoice Date → Document Date
- Due Date → Due Date
- Currency → Currency Code
- Payment Terms → Payment Terms Code

**Line Items:**
- Type (Item, G/L Account, Resource)
- No. (Item No., Account No., Resource No.)
- Quantity
- Unit Price
- Line Amount
- VAT %
- VAT Amount

---

## Fiskalizacija 2.0 Integration

### eRačun Workflow

1. **Receive Sales Documents**:
   - Sales invoices synced from BC17
   - Created as unposted in BC27
   - Review and validate data

2. **Post and Send eRačun**:
   - Post sales invoices in BC27
   - Use Fiskalizacija 2.0 functionality to generate eRačun
   - Send eRačun to customers via eInvoicing system

3. **Receive eRačuni from Vendors**:
   - Incoming eRačuni imported as purchase invoices
   - Mark for sync to BC17
   - BC17 processes and posts

### Required Setup

- KPD codes configured
- Tax categories mapped
- Vendor codes configured
- eInvoicing integration active

---

## Out of Scope

The following features are **not included**:

- Item tracking (lot/serial numbers)
- Automatic posting (documents created as unposted)
- Prepayment automation (manual posting required)
- Historical document migration
- Real-time sync (minimum 15-minute interval)
- Document attachments/files
- Approval workflow integration
- "Get Receipt Lines" automation

---

## License

© 2025 Kelteks. All rights reserved.

---

**Version History:**

- **1.0.0.0** (2025-01-15): Initial release
  - Split architecture from combined extension
  - Multiple authentication methods (OAuth, Basic, Windows, Certificate)
  - BC v27 compatibility (Platform 27.0, Runtime 14.0)
  - Standard Error Message integration
  - Fiskalizacija 2.0 compliance ready
  - On-premise and cloud support
