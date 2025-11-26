# Kelteks API Integration BC17

**Version:** 1.0.0.0  
**For:** Microsoft Dynamics 365 Business Central v17 (On-Premise)  
**Purpose:** Fiskalizacija 2.0 Compliance - Document Synchronization

## Overview

This extension enables **outbound** synchronization of posted sales documents from BC v17 to BC v27 and **inbound** receipt of purchase documents from BC v27 to BC v17. It is part of a split architecture designed specifically for Fiskalizacija 2.0 compliance and eRačun (electronic invoice) exchange.

### What This Extension Does

**Outbound to BC27:**
- Posted Sales Invoices → BC27 (created as unposted Sales Invoices)
- Posted Sales Credit Memos → BC27 (created as unposted Sales Credit Memos)

**Inbound from BC27:**
- Purchase Invoices ← BC27 (created as unposted Purchase Invoices)
- Purchase Credit Memos ← BC27 (created as unposted Purchase Credit Memos)

### Companion Extension

This extension **requires** the companion extension **KelteksAPIIntegrationBC27** to be installed on your BC v27 environment for bidirectional synchronization.

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
- **Microsoft Dynamics 365 Business Central v17** (On-Premise)
- Platform: 17.0.0.0
- Runtime: 7.0

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
- HTTPS connectivity to BC v27 environment
- TLS 1.2 or higher support
- Outbound firewall rules allowing HTTPS traffic to BC v27

#### BC17 Configuration
- Dedicated number series for Purchase Invoices from BC27
- Dedicated number series for Purchase Credit Memos from BC27
- (Optional) Allow negative inventory

---

## Authentication Options

This extension supports multiple authentication methods for on-premise installations:

### 1. OAuth 2.0 (Recommended for Cloud/Hybrid)

**Best for:** BC v27 hosted in Azure or hybrid scenarios

**Requirements:**
- Azure AD tenant
- App registration in Azure AD for BC v27
- Client ID and Client Secret
- Tenant ID

**Advantages:**
- Industry-standard authentication
- Token-based security
- Automatic token refresh (55-minute cache)
- No password storage

**Configuration:**
```
Target Base URL: https://api.businesscentral.dynamics.com/v2.0/{tenant}/Production
Company ID: {GUID}
Tenant ID: {tenant-guid}
Client ID: {app-id}
Client Secret: {app-secret}
```

### 2. Basic Authentication (On-Premise)

**Best for:** Both BC v17 and BC v27 are on-premise

**Requirements:**
- BC v27 configured for Basic Authentication
- Service account credentials
- Web services enabled

**Advantages:**
- Simpler setup for on-premise
- No Azure AD dependency
- Direct credential authentication

**Configuration:**
```
Target Base URL: https://bc27-server:7048/BC270/ODataV4/Company('{company-name}')
Authentication Type: Basic
Username: DOMAIN\ServiceAccount
Password: {service-account-password}
```

**Important Notes:**
- Use a dedicated service account (not a user account)
- Grant minimum required permissions
- Use HTTPS (not HTTP) to protect credentials
- Change service account password regularly

### 3. Windows Authentication (On-Premise)

**Best for:** Both environments in the same Windows domain

**Requirements:**
- BC v27 configured for Windows Authentication
- Service account with appropriate permissions
- Both servers in same domain or trusted domains

**Advantages:**
- Single sign-on capability
- No password stored in BC17
- Uses Windows domain security

**Configuration:**
```
Target Base URL: https://bc27-server:7048/BC270/ODataV4/Company('{company-name}')
Authentication Type: Windows
Service Account: DOMAIN\ServiceAccount
```

**Important Notes:**
- Service must run under account with permissions to BC v27
- Requires appropriate SPNs configured
- Best for tightly integrated environments

### 4. Web Services Access Key (Legacy - Not Recommended)

**Best for:** Legacy on-premise installations

**Requirements:**
- Web Services Access Key generated in BC v27
- User account in BC v27

**Disadvantages:**
- Less secure than other methods
- Keys don't expire automatically
- Deprecated in newer BC versions

---

## Installation

### Step 1: Verify Prerequisites

1. Ensure all master data is synchronized between BC17 and BC27
2. Verify network connectivity to BC v27
3. Prepare authentication credentials (OAuth or Basic)
4. Create dedicated number series for purchase documents

### Step 2: Install Extension

1. Download **KelteksAPIIntegrationBC17.app**
2. Open Business Central v17 Administration Shell (Run as Administrator)
3. Install the extension:

```powershell
# Install extension
Publish-NAVApp -ServerInstance BC170 -Path "C:\Path\To\KelteksAPIIntegrationBC17.app" -SkipVerification

# Sync extension
Sync-NAVApp -ServerInstance BC170 -Name "Kelteks API Integration BC17" -Version 1.0.0.0

# Install for all tenants or specific tenant
Install-NAVApp -ServerInstance BC170 -Name "Kelteks API Integration BC17" -Version 1.0.0.0
```

### Step 3: Assign Permissions

Assign the **KLT API Integration BC17** permission set to users who will:
- Configure the integration
- Monitor synchronization
- Resolve errors

```al
// Permission set is automatically included
// Assign via User Setup or Permission Sets page
```

---

## Configuration

### Option 1: Using the Configuration Page

1. Search for **KLT API Configuration**
2. Click **New** (if not exists, only one record allowed)
3. Fill in the fields:

#### General Settings
- **Target Environment Name**: BC27 (descriptive name)
- **Base URL**: Full URL to BC v27 API endpoint
- **Company ID**: GUID of target company in BC v27
- **Enabled**: Toggle to enable/disable sync

#### Authentication Settings (OAuth)
- **Tenant ID**: Azure AD tenant GUID
- **Client ID**: Azure AD app registration client ID
- **Client Secret**: Azure AD app registration client secret

#### Authentication Settings (Basic)
- **Username**: DOMAIN\ServiceAccount
- **Password**: Service account password

#### Synchronization Settings
- **Batch Size**: Number of documents per sync cycle (default: 100)
- **Sync Interval (Minutes)**: How often to sync (default: 15)
- **Max Retry Attempts**: Maximum retries for failed syncs (default: 3)
- **Enable Auto Retry**: Automatically retry failed syncs

#### Number Series
- **Purchase Invoice Nos.**: Number series for incoming purchase invoices
- **Purchase Cr. Memo Nos.**: Number series for incoming credit memos

4. Click **Test Connection** to verify configuration
5. If successful, click **Enable Synchronization**

### Option 2: Manual Table Entry

```al
// Direct table manipulation (advanced users only)
KLTAPIConfigBC17.Init();
KLTAPIConfigBC17."Target Environment" := 'BC27';
KLTAPIConfigBC17."Base URL" := 'https://bc27-server:7048/BC270/ODataV4/';
KLTAPIConfigBC17."Company ID" := '{company-guid}';
KLTAPIConfigBC17."Authentication Type" := KLTAPIConfigBC17."Authentication Type"::Basic;
KLTAPIConfigBC17.Username := 'DOMAIN\ServiceAccount';
KLTAPIConfigBC17.SetPassword('password'); // Encrypted storage
KLTAPIConfigBC17.Enabled := true;
KLTAPIConfigBC17.Insert(true);
```

---

## Usage

### Automatic Synchronization

Once configured and enabled, synchronization runs automatically based on the configured interval:

**Outbound (Sales Documents):**
1. Every 15 minutes (configurable), the extension queries BC v27 for modified posted sales documents
2. Documents are filtered by `lastModifiedDateTime` to get only new/changed documents
3. Each document is transformed and sent to BC v27 via POST to `purchaseInvoices` or `purchaseCreditMemos` API
4. Success/failure is logged to **KLT Document Sync Log**

**Inbound (Purchase Documents):**
1. BC v27 extension queries BC v17 for unposted purchase documents
2. Documents are created in BC v17 via POST API
3. Documents appear in BC v17 as unposted Purchase Invoices/Credit Memos
4. Users review and post documents in BC v17

### Manual Synchronization

You can trigger manual synchronization from:

**Posted Sales Invoice List:**
1. Open **Posted Sales Invoices**
2. Select one or more invoices
3. Click **Actions → Functions → Sync to BC27**

**Posted Sales Credit Memo List:**
1. Open **Posted Sales Credit Memos**
2. Select one or more credit memos
3. Click **Actions → Functions → Sync to BC27**

### Job Queue Integration

The extension automatically creates a job queue entry when you enable synchronization:

- **Object Type**: Codeunit
- **Object ID**: 50104 (KLT Sync Engine BC17)
- **Status**: Ready
- **Run**: Every 15 minutes (configurable)

You can manage the job queue entry from **Job Queue Entries** page.

---

## Monitoring

### Sync Log

View all synchronization history:

1. Search for **KLT Document Sync Log**
2. Filter by:
   - **Sync Direction**: Outbound (to BC27) or Inbound (from BC27)
   - **Document Type**: Sales Invoice, Sales Credit Memo, Purchase Invoice, Purchase Credit Memo
   - **Status**: Pending, Completed, Failed, Retrying
   - **Created DateTime**: Date range

**Key Fields:**
- **Entry No.**: Unique log entry number
- **Source Document No.**: Document number in source system
- **Target Document No.**: Document number in target system (if created)
- **Status**: Current sync status
- **Duration (ms)**: Time taken to sync (milliseconds)
- **Error Message**: Error details (if failed)
- **Retry Count**: Number of retry attempts

### Error Management

View and resolve synchronization errors:

1. Search for **Error Messages**
2. Filter by **Context**: KLT Document Sync Log
3. Review error details
4. Take corrective action (fix master data, etc.)
5. Retry from sync log if needed

**Common Error Categories:**
- **API Communication**: Network issues, timeouts, service unavailable
- **Data Validation**: Missing master data, invalid values
- **Business Logic**: Posting period closed, negative inventory
- **Authentication**: Invalid credentials, token expired
- **Master Data Missing**: Customer/vendor/item not found

### Statistics

View real-time statistics on the **KLT API Configuration** page:

- **Total Synced Documents**: All-time count
- **Successful Syncs**: Success count
- **Failed Syncs**: Failure count
- **Success Rate**: Percentage
- **Last Sync**: Timestamp of last sync run
- **Avg Duration**: Average sync time per document

---

## Troubleshooting

### Connection Test Fails

**Symptoms:** "Connection test failed" message

**Solutions:**
1. Verify Base URL is correct and accessible
2. Check network connectivity: `Test-NetConnection bc27-server -Port 7048`
3. Verify authentication credentials
4. Check BC v27 web services are enabled
5. Review firewall rules

### Documents Not Syncing

**Symptoms:** Documents remain in source but don't appear in target

**Solutions:**
1. Check **Enabled** is true on configuration page
2. Verify job queue entry is running: Search **Job Queue Entries**
3. Check sync log for errors: **KLT Document Sync Log**
4. Verify master data exists in BC v27 (customer, items, etc.)
5. Check posting periods are open in BC v27

### Authentication Errors

**Symptoms:** "Authentication failed" or "401 Unauthorized"

**Solutions:**

**For OAuth:**
1. Verify Client ID and Client Secret are correct
2. Check Tenant ID matches Azure AD tenant
3. Ensure app registration has appropriate permissions
4. Verify API permissions granted in Azure AD

**For Basic Authentication:**
1. Verify username format: DOMAIN\Username
2. Check password is correct (use **Change Password** action)
3. Ensure service account has permissions to BC v27
4. Verify Basic Authentication is enabled in BC v27

### Performance Issues

**Symptoms:** Sync takes too long or times out

**Solutions:**
1. Reduce **Batch Size** (try 50 instead of 100)
2. Increase **Sync Interval** to reduce frequency
3. Check network latency to BC v27
4. Review BC v27 server performance
5. Optimize master data queries

### Duplicate Documents

**Symptoms:** Same document created multiple times in target

**Solutions:**
1. Extension uses **External Document No.** for duplicate prevention
2. Check External Document No. is populated on source documents
3. Review sync log for duplicate entries
4. Manually delete duplicate documents in target system

---

## Support

### Documentation

- **README-SPLIT.md**: Overview of split architecture
- **SPLIT-ARCHITECTURE.md**: Technical architecture details
- **BC27 Extension README**: Companion extension documentation

### Error Message Integration

This extension uses Business Central's standard **Error Message** table for logging. All sync errors are automatically logged and can be viewed using the built-in **Error Messages** page.

### Logging

All API operations are logged with:
- Timestamp
- Operation type
- Request/response details (credentials masked)
- Duration
- Success/failure status

Logs are retained for 365 days by default (configurable).

### Contact

- **Client**: Kelteks
- **Consultant**: Ana Šetka
- **JIRA**: ZGBCSKELTE-54
- **Area**: Sales & Procurement

---

## Technical Details

### Object ID Range
50100-50149

### Key Objects

**Tables:**
- 50100: KLT API Configuration
- 50101: KLT Document Sync Log
- 50103: KLT API Sync Queue

**Enums:**
- 50100: KLT Document Type
- 50101: KLT Sync Status
- 50102: KLT Error Category
- 50103: KLT Sync Direction

**Codeunits:**
- 50100: KLT API Auth BC17 (OAuth & Basic authentication)

**Pages:**
- 50100: KLT API Configuration

### Security

- Credentials stored with ExtendedDatatype = Masked
- Passwords encrypted in database
- TLS 1.2+ required for API communication
- Token caching (55-minute lifetime for OAuth)
- Permission-based access control

### API Endpoints Used

**Read from BC v17 (for BC27 to pull):**
- GET `/api/v2.0/companies({id})/salesInvoices`
- GET `/api/v2.0/companies({id})/salesCreditMemos`

**Write to BC v27:**
- POST `/api/v2.0/companies({id})/purchaseInvoices`
- POST `/api/v2.0/companies({id})/purchaseCreditMemos`

---

## Out of Scope

The following features are **not included** in this extension:

- Item tracking (lot/serial numbers)
- Automatic posting of documents
- Prepayment automation
- Historical document migration
- Real-time synchronization (< 15 minutes)
- Document attachments/files
- Approval workflows
- "Get Receipt Lines" logic (requires custom business process)

---

## License

© 2025 Kelteks. All rights reserved.

---

**Version History:**

- **1.0.0.0** (2025-01-15): Initial release
  - Split architecture from combined extension
  - OAuth 2.0 and Basic Authentication support
  - Standard Error Message table integration
  - BC v17 on-premise compatibility
