# Kelteks API Integration - Fiskalizacija 2.0

## Overview

This Business Central extension enables electronic exchange of invoices (eRačun) between Microsoft Business Central environments for the requirements of Fiskalizacija 2.0. It provides automated two-way synchronization of sales and purchase documents between BC v17 and BC v27.

## Features

### Document Synchronization

#### Outbound (BC17 → BC27)
- Posted Sales Invoices
- Posted Sales Credit Memos
- Documents created as unposted in BC27
- Incremental sync based on modification timestamps

#### Inbound (BC27 → BC17)
- Purchase Invoices (unposted)
- Purchase Credit Memos (unposted)
- Documents created in BC17 for posting

### Key Capabilities

- **OAuth 2.0 Authentication**: Secure service-to-service authentication using Azure AD
- **Batch Processing**: Scheduled synchronization every 15 minutes (configurable)
- **Error Handling**: Automatic retry with exponential backoff for transient failures
- **Duplicate Prevention**: Uses External Document No. to prevent duplicate transfers
- **Comprehensive Logging**: All API operations logged with timestamps and status
- **Monitoring Dashboard**: Real-time statistics and error tracking
- **Alert System**: Email notifications for critical failures

## Installation

1. Install the extension from the Extension Management page
2. Assign the "KLT API Integration" permission set to users who need access
3. Configure API settings in the API Configuration page

## Configuration

### Prerequisites

Before using the integration, ensure:

1. **Master Data Migration**: All prerequisite master data has been migrated to both BC17 and BC27:
   - Chart of Accounts
   - Customers & Vendors
   - Items & Resources
   - Vendor Bank Accounts
   - Locations
   - Posting Setups (inventory, VAT, general, customer/vendor, prepayment)
   - Units of Measure
   - Payment Terms & Methods
   - Shipment Methods
   - Users & Company Information
   - Fiskalizacija 2.0 settings

2. **System Settings**:
   - Enable negative inventory
   - Disable exact cost reversal (storno točnog troška)
   - Allow manual numbering of sales invoices in BC27
   - Define dedicated number series for purchase documents in BC17

3. **Network Connectivity**:
   - HTTPS access between BC17 and BC27 environments
   - API endpoints enabled in both BC instances

### Setup Steps

1. **Open API Configuration Page**
   - Search for "API Configuration" in Business Central
   - Or navigate via Role Center → Kelteks API Integration

2. **Configure BC17 Settings**:
   - BC17 Base URL (e.g., https://api.businesscentral.dynamics.com/v2.0/[environment])
   - BC17 Company ID (GUID from company list)
   - BC17 Tenant ID (Azure AD tenant ID)
   - BC17 Client ID (OAuth application client ID)
   - BC17 Client Secret (OAuth application secret)

3. **Configure BC27 Settings**:
   - BC27 Base URL
   - BC27 Company ID
   - BC27 Tenant ID
   - BC27 Client ID
   - BC27 Client Secret

4. **Configure Synchronization Settings**:
   - Sync Interval: 15 minutes (recommended)
   - Batch Size: 100 documents (recommended)
   - API Timeout: 5 seconds
   - Max Retry Attempts: 3
   - Enable Sync: Check to activate

5. **Configure Alert Settings**:
   - Alert Email Address: Email for critical notifications
   - Critical Error Threshold: 25% (recommended)

6. **Test Configuration**:
   - Click "Test Connection" to verify API connectivity
   - Verify both BC17 and BC27 connections succeed

7. **Create Job Queue Entry**:
   - Click "Create Job Queue Entry" to schedule automatic sync
   - Verify job queue entry is created and active

## Usage

### Automatic Synchronization

Once configured and enabled, the system automatically:
- Runs every 15 minutes (or configured interval)
- Syncs new/modified documents from BC17 to BC27
- Syncs new/modified documents from BC27 to BC17
- Retries failed operations automatically
- Sends alerts on critical failures

### Manual Synchronization

To run synchronization manually:
1. Open API Configuration page
2. Click "Run Sync Now"
3. View results in Document Sync Log

### Monitoring

#### View Sync Log
- Navigate to "Document Sync Log" page
- Filter by status, document type, or date range
- View detailed transfer history

#### View Errors
- Navigate to "Document Sync Error" page
- Review error details and categories
- Mark errors as resolved when fixed
- Retry failed operations

#### Statistics
- Open Document Sync Log page
- Click "Statistics" to view overall metrics
- Monitor success rate and pending retries

## Document Flow

### Sales Documents (BC17 → BC27)

1. Posted Sales Invoice/Credit Memo created in BC17
2. Integration detects new document
3. Document data extracted via BC17 API
4. Duplicate check performed
5. Document created in BC27 as unposted
6. Sync log entry created
7. User in BC27 reviews and posts document
8. eRačun sent from BC27

### Purchase Documents (BC27 → BC17)

1. Incoming eRačun processed in BC27
2. Purchase Invoice/Credit Memo created (unposted)
3. Integration detects new document
4. Document data extracted via BC27 API
5. Duplicate check performed
6. Document created in BC17 as unposted
7. Sync log entry created
8. User in BC17 reviews, posts document
9. If goods receipt exists, lines cleared and reloaded via "Get Receipt Lines"

## Error Handling

### Error Categories

1. **API Communication**: Network timeouts, service unavailability
   - Automatic retry enabled
   - Exponential backoff (1, 2, 4, 8 minutes...)

2. **Authentication**: OAuth failures, expired tokens
   - Automatic retry enabled
   - Token cache automatically refreshed

3. **Data Validation**: Missing required fields, invalid values
   - Manual intervention required
   - Review error details and correct source data

4. **Business Logic**: Posting failures, VAT mismatches
   - Manual intervention required
   - Review business rules and master data

5. **Master Data Missing**: Customer/Vendor/Item not found
   - Manual intervention required
   - Create missing master data before retry

### Resolving Errors

1. Open Document Sync Error page
2. Review error message and category
3. For retryable errors:
   - Wait for automatic retry, or
   - Click "Retry Now" for immediate retry
4. For validation/business logic errors:
   - Correct the source data
   - Mark error as resolved
   - Re-create document if needed

## Performance

### Expected Volumes
- Daily sales invoices: 50-200
- Daily purchase invoices: 30-100
- Peak periods: Up to 3x normal volume (month-end)

### Performance SLAs
- API response time: < 5 seconds per document
- Batch processing: 100 documents per 15-minute cycle
- End-to-end latency: < 30 minutes under normal load

## Security

### Authentication
- OAuth 2.0 client credentials flow
- Service-to-service authentication
- Tokens cached for 55 minutes
- Automatic token refresh

### Data Protection
- TLS 1.2+ encryption for all API communications
- Credentials masked in UI
- No sensitive data in logs
- Permission-based access control

### Recommendations
- Store credentials in Azure Key Vault (production)
- Use dedicated service accounts with minimum permissions
- Regular credential rotation
- Monitor access logs

## Troubleshooting

### Connection Test Fails
- Verify Base URLs are correct
- Check Company IDs match actual companies
- Validate Azure AD Tenant IDs
- Ensure Client ID and Secret are correct
- Check network connectivity

### Documents Not Syncing
- Verify "Enable Sync" is checked
- Check Job Queue Entry is active
- Review Document Sync Log for errors
- Verify posting periods are open

### High Error Rate
- Check Document Sync Error page
- Review error categories
- Verify master data exists in both systems
- Check API availability

### Performance Issues
- Reduce batch size
- Increase sync interval
- Check network latency
- Review API call quotas

## Support

For issues or questions:
1. Review Document Sync Log and Error pages
2. Check error messages and categories
3. Verify configuration settings
4. Contact your Business Central partner

## Version History

### Version 1.0.0.0
- Initial release
- OAuth 2.0 authentication
- Sales document sync (BC17 → BC27)
- Purchase document sync (BC27 → BC17)
- Error handling and retry logic
- Comprehensive logging
- Monitoring dashboard
- Alert system

## Technical Details

### Object Ranges
- Tables: 50100-50149
- Pages: 50100-50149
- Codeunits: 50100-50149
- Enums: 50100-50149

### API Endpoints Used

#### BC17 (Source)
- GET /api/v2.0/companies({id})/salesInvoices
- GET /api/v2.0/companies({id})/salesCreditMemos

#### BC27 (Target for Sales)
- POST /api/v2.0/companies({id})/salesInvoices
- POST /api/v2.0/companies({id})/salesCreditMemos

#### BC17 (Target for Purchases)
- POST /api/v2.0/companies({id})/purchaseInvoices
- POST /api/v2.0/companies({id})/purchaseCreditMemos

#### BC27 (Source)
- GET /api/v2.0/companies({id})/purchaseInvoices
- GET /api/v2.0/companies({id})/purchaseCreditMemos

### Field Mappings

See technical specification document for complete field mapping details.

## Out of Scope

The following features are **not included** in this version:
- Item tracking (lot/serial numbers)
- Automatic posting in target systems
- Prepayment automation
- Historical document migration
- Real-time synchronization (< 15 minutes)
- Document attachments/files
- Approval workflow integration

## License

Copyright © Kelteks
All rights reserved.
