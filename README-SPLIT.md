# Kelteks API Integration - Fiskalizacija 2.0 (Split Architecture)

## Overview

This solution implements bidirectional document synchronization between BC v17 and BC v27 for Fiskalizacija 2.0 compliance. The implementation has been **split into two separate extensions**:

1. **KelteksAPIIntegrationBC17** - Installed on BC v17
2. **KelteksAPIIntegrationBC27** - Installed on BC v27

## Architecture

### Why Two Separate Apps?

The integration has been split to:
- **Simplify deployment**: Each environment only needs its own extension
- **Reduce complexity**: Each app contains only the functionality needed for that environment
- **Improve security**: Each environment only has outbound sync capabilities, not inbound
- **Enable independent updates**: Each app can be updated independently

### BC17 Extension (KelteksAPIIntegrationBC17)

**Install on**: BC v17 environment  
**Object ID Range**: 50100-50149  
**Functionality**:
- **Outbound**: Sends posted Sales Invoices and Credit Memos to BC27
- **Inbound**: Receives Purchase Invoices and Credit Memos from BC27
- **Configuration**: Connects to BC27 as target environment

**Key Components**:
- OAuth 2.0 authentication for BC27
- Sales document synchronization (BC17 → BC27)
- Purchase document reception (BC27 → BC17)
- Sync log and error tracking
- Page extensions on Posted Sales Invoice/Credit Memo lists

### BC27 Extension (KelteksAPIIntegrationBC27)

**Install on**: BC v27 environment  
**Object ID Range**: 50150-50199  
**Functionality**:
- **Inbound**: Receives Sales Invoices and Credit Memos from BC17
- **Outbound**: Sends Purchase Invoices and Credit Memos to BC17
- **Configuration**: Connects to BC17 as target environment

**Key Components**:
- OAuth 2.0 authentication for BC17
- Sales document reception (BC17 → BC27)
- Purchase document synchronization (BC27 → BC17)
- Sync log and error tracking
- Page extensions on Purchase Invoice/Credit Memo lists

## Document Flow

```
BC v17                                    BC v27
┌─────────────────────────┐              ┌─────────────────────────┐
│ Posted Sales Invoice    │──────────────>│ Sales Invoice (Unposted)│
│ Posted Sales Credit Memo│──────────────>│ Sales Cr. Memo (Unpost.)│
│                         │              │                         │
│ Purchase Invoice (Unp.) │<──────────────│ Purchase Invoice (Unp.) │
│ Purchase Cr. Memo (Unp.)│<──────────────│ Purchase Cr. Memo (Unp.)│
└─────────────────────────┘              └─────────────────────────┘
   KelteksAPIIntegrationBC17               KelteksAPIIntegrationBC27
```

## Installation

### Prerequisites

**Both Environments**:
- Master data must be synchronized (Customers, Vendors, Items, etc.)
- API endpoints must be enabled
- Azure AD app registrations configured
- OAuth credentials (Client ID, Client Secret, Tenant ID)

### Step 1: Install BC17 Extension

1. In BC v17, go to **Extension Management**
2. Upload and install **KelteksAPIIntegrationBC17**
3. Assign permission set **"KLT API Integration BC17"** to users
4. Open **KLT API Configuration BC17** page
5. Configure connection to BC27:
   - Target Base URL
   - Target Company ID
   - Target Tenant ID
   - Target Client ID and Secret
6. Test connection
7. Enable synchronization
8. Create job queue entry

### Step 2: Install BC27 Extension

1. In BC v27, go to **Extension Management**
2. Upload and install **KelteksAPIIntegrationBC27**
3. Assign permission set **"KLT API Integration BC27"** to users
4. Open **KLT API Configuration BC27** page
5. Configure connection to BC17:
   - BC17 Base URL
   - BC17 Company ID
   - BC17 Tenant ID
   - BC17 Client ID and Secret
6. Test connection
7. Enable synchronization
8. Create job queue entry

## Configuration

### BC17 Configuration

**Navigate to**: Search for "KLT API Configuration BC17"

**Required Settings**:
- **Target Base URL**: `https://api.businesscentral.dynamics.com/v2.0/[environment]`
- **Target Company ID**: GUID from BC27 company list
- **Target Tenant ID**: Azure AD tenant GUID
- **Target Client ID**: OAuth application client ID
- **Target Client Secret**: OAuth application secret

**Optional Settings**:
- Sync Interval: 15 minutes (default)
- Batch Size: 100 documents (default)
- API Timeout: 5 seconds (default)
- Max Retry Attempts: 3 (default)
- Alert Email Address: For critical notifications
- Purchase No. Series: Dedicated number series for received purchase documents

### BC27 Configuration

**Navigate to**: Search for "KLT API Configuration BC27"

**Required Settings**:
- **BC17 Base URL**: `https://api.businesscentral.dynamics.com/v2.0/[environment]`
- **BC17 Company ID**: GUID from BC17 company list
- **BC17 Tenant ID**: Azure AD tenant GUID
- **BC17 Client ID**: OAuth application client ID
- **BC17 Client Secret**: OAuth application secret

**Optional Settings**:
- Sync Interval: 15 minutes (default)
- Batch Size: 100 documents (default)
- API Timeout: 5 seconds (default)
- Max Retry Attempts: 3 (default)
- Alert Email Address: For critical notifications

## Usage

### In BC17

**Automatic Synchronization**:
- Posted Sales Invoices automatically sync to BC27 every 15 minutes
- Purchase Invoices from BC27 are automatically received every 15 minutes

**Manual Synchronization**:
- Open **Posted Sales Invoices** list
- Select invoice(s)
- Click **Kelteks Sync** → **Sync to BC27**

**Monitoring**:
- Open **Document Sync Log BC17** to view history
- Open **Document Sync Error BC17** to review and resolve errors

### In BC27

**Automatic Synchronization**:
- Purchase Invoices automatically sync to BC17 every 15 minutes
- Sales Invoices from BC17 are automatically received every 15 minutes

**Manual Synchronization**:
- Open **Purchase Invoices** list
- Select invoice(s)
- Click **Kelteks Sync** → **Sync to BC17**

**Monitoring**:
- Open **Document Sync Log BC27** to view history
- Open **Document Sync Error BC27** to review and resolve errors

## Key Features

✅ **Independent Deployment**: Each environment has its own extension  
✅ **OAuth 2.0 Authentication**: Secure authentication with token caching  
✅ **Incremental Sync**: Only new/modified documents synchronized  
✅ **Error Handling**: Automatic retry with exponential backoff  
✅ **Duplicate Prevention**: Using External Document No.  
✅ **Comprehensive Logging**: Full audit trail with performance metrics  
✅ **Monitoring**: Real-time statistics and error tracking  
✅ **Security**: Masked credentials, TLS 1.2+, permission-based access  

## Security

**BC17 Extension**:
- Connects to BC27 (outbound only for sales)
- Receives from BC27 (inbound only for purchases)
- OAuth credentials for BC27 stored securely

**BC27 Extension**:
- Connects to BC17 (outbound only for purchases)
- Receives from BC17 (inbound only for sales)
- OAuth credentials for BC17 stored securely

Both extensions use:
- TLS 1.2+ encryption
- Masked credential fields
- Permission-based access control
- No sensitive data in logs

## Troubleshooting

### Connection Test Fails

**In BC17**:
1. Verify Target Base URL is correct
2. Check Target Company ID (GUID format)
3. Validate BC27 OAuth credentials
4. Test network connectivity to BC27

**In BC27**:
1. Verify BC17 Base URL is correct
2. Check BC17 Company ID (GUID format)
3. Validate BC17 OAuth credentials
4. Test network connectivity to BC17

### Documents Not Syncing

1. Check "Enable Sync" is checked in configuration
2. Verify Job Queue Entry is active
3. Review Document Sync Log for errors
4. Check posting periods are open in target environment

### Authentication Errors

1. Regenerate OAuth credentials in Azure AD
2. Update credentials in configuration
3. Clear token cache (test connection again)
4. Verify API permissions are granted

## Support

**Documentation**:
- This README for architecture overview
- Original documentation in `KelteksAPIIntegration/` folder for detailed specifications
- TECHNICAL.md for API details
- TROUBLESHOOTING.md for common issues

**Built-in Tools**:
- Configuration pages with connection testing
- Sync log with statistics
- Error log with resolution tracking

## Migration from Single App

If you previously had the combined `KelteksAPIIntegration` extension installed:

1. **Backup** all configuration and sync logs
2. **Uninstall** the old combined extension
3. **Install** BC17 extension on BC v17
4. **Install** BC27 extension on BC v27
5. **Reconfigure** both extensions with their respective settings
6. **Test** connections in both environments
7. **Enable** synchronization

**Note**: Sync history from the old extension will not be migrated. The split extensions will start with fresh sync logs.

## Version History

### Version 1.0.0 (Split Architecture)
- Split into BC17 and BC27 specific extensions
- Simplified configuration (each environment only configures target)
- Independent deployment and updates
- Reduced object complexity per environment

---

**BC17 Extension ID**: 8a5e1b2c-3d4e-5f6a-7b8c-9d0e1f2a3b4c  
**BC27 Extension ID**: 9b6f2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d  
**License**: Copyright © Kelteks  
