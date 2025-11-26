# Technical Specification - Kelteks API Integration

## Architecture Overview

### Integration Pattern
The Kelteks API Integration implements a point-to-point RESTful API integration between:
- **BC v17** (source for sales documents, target for purchase documents)
- **BC v27** (target for sales documents, source for purchase documents)

### Technology Stack
- **Language**: AL (Application Language)
- **Runtime**: Business Central Runtime 7.0
- **Platform**: Business Central v17.0 and higher
- **Authentication**: OAuth 2.0 (Client Credentials Flow)
- **API**: Business Central OData v2.0 API
- **Protocol**: HTTPS with TLS 1.2+

## Object ID Ranges

| Object Type | Range | Usage |
|------------|-------|-------|
| Tables | 50100-50149 | Core data tables |
| Pages | 50100-50149 | User interface |
| Codeunits | 50100-50149 | Business logic |
| Enums | 50100-50149 | Enumerations |
| Reports | 50100-50149 | Reports (future use) |

## Data Model

### Tables

#### KLT API Configuration (50100)
Singleton configuration table for API settings.

**Fields:**
- Primary Key (Code[10]): Singleton key ('')
- BC17/BC27 Connection Settings:
  - Base URL (Text[250])
  - Company ID (Guid)
  - Tenant ID (Text[250])
  - Client ID (Text[250])
  - Client Secret (Text[250]) - Masked
- Synchronization Settings:
  - Sync Interval (Minutes) - Default: 15
  - Batch Size - Default: 100
  - API Timeout (Seconds) - Default: 5
  - Max Retry Attempts - Default: 3
  - Enable Sync (Boolean)
- Alert Settings:
  - Alert Email Address (Text[250])
  - Critical Error Threshold % - Default: 25
- Other Settings:
  - Log Retention Days - Default: 365
  - Purchase No. Series BC17 (Code[20])

**Methods:**
- `GetInstance()`: Get or create singleton record
- `ValidateConfiguration()`: Check all required fields are set

#### KLT Document Sync Log (50101)
Historical log of all document synchronization operations.

**Fields:**
- Entry No. (Integer): Auto-increment primary key
- Sync Direction (Enum): Outbound/Inbound
- Document Type (Enum): Sales/Purchase Invoice/Credit Memo
- Source/Target Document No. & System ID
- External Document No. (Code[35])
- Status (Enum): Pending/In Progress/Completed/Failed/Retrying
- DateTime fields: Started, Completed, Duration
- Customer/Vendor details for filtering
- Error Message (Text[2048])
- Retry information
- Audit fields: Created By, Created DateTime

**Methods:**
- `MarkAsCompleted()`: Update status to completed
- `MarkAsFailed()`: Update status to failed
- `IncrementRetryCount()`: Increment retry counter

**Keys:**
- Primary: Entry No.
- Document: Document Type, Source Document No., Sync Direction
- Status: Status, Created DateTime
- External Doc: External Document No.

#### KLT Document Sync Error (50102)
Detailed error tracking with retry logic.

**Fields:**
- Entry No. (Integer): Auto-increment primary key
- Sync Log Entry No. (Integer): Link to sync log
- Error Category (Enum): API/Validation/Business/Auth/Master Data
- Error Message & Details
- Error Details (Blob): Extended JSON error information
- Stack Trace (Text[2048])
- Document identification fields
- Retry logic fields:
  - Retry Count
  - Max Retry Attempts
  - Last/Next Retry DateTime
  - Can Retry (Boolean)
- Resolution fields:
  - Resolved (Boolean)
  - Resolved By/DateTime
  - Resolution Notes
- Audit fields

**Methods:**
- `MarkAsResolved()`: Mark error as resolved
- `IncrementRetryCount()`: Update retry counter
- `SetErrorDetails()`: Store JSON error details
- `GetErrorDetails()`: Retrieve JSON error details
- `CalculateCanRetry()`: Determine if retry is possible
- `CalculateNextRetryTime()`: Exponential backoff calculation

**Keys:**
- Primary: Entry No.
- Document: Document Type, Document No.
- Retry: Can Retry, Next Retry DateTime
- Category: Error Category, Resolved

#### KLT API Sync Queue (50103)
Queue for managing batch document synchronization.

**Fields:**
- Entry No. (Integer): Auto-increment primary key
- Sync Direction & Document Type
- Document No. & System ID
- External Document No.
- Status (Enum): Pending/In Progress/Completed/Failed
- Priority (1-10): Default 5
- Processing Started (DateTime)
- Sync Log Entry No. link
- Retry Count
- Audit fields

**Methods:**
- `EnqueueDocument()`: Add document to queue
- `MarkAsInProgress()`: Update to in progress
- `MarkAsCompleted()`: Remove from queue
- `MarkAsFailed()`: Mark for retry

**Keys:**
- Primary: Entry No.
- Processing: Status, Priority, Created DateTime
- Document: Document Type, Document No.

### Enums

#### KLT Document Type (50100)
- Sales Invoice
- Sales Credit Memo
- Purchase Invoice
- Purchase Credit Memo

#### KLT Sync Status (50101)
- Pending
- In Progress
- Completed
- Failed
- Retrying

#### KLT Error Category (50102)
- API Communication
- Data Validation
- Business Logic
- Authentication
- Master Data Missing

#### KLT Sync Direction (50103)
- Outbound (BC17 → BC27)
- Inbound (BC27 → BC17)

## Business Logic

### Codeunits

#### KLT API Authentication (50100)
Handles OAuth 2.0 authentication for both BC17 and BC27.

**Features:**
- Token caching (55-minute lifetime)
- Automatic token refresh
- Separate tokens for BC17 and BC27
- Azure AD integration

**Methods:**
- `GetBC17AccessToken()`: Get cached or new token for BC17
- `GetBC27AccessToken()`: Get cached or new token for BC27
- `ClearTokenCache()`: Clear all cached tokens
- `ValidateAuthentication()`: Test both connections

**Token Flow:**
1. Check cache for valid token
2. If expired/missing, request from Azure AD
3. Cache token with 55-minute expiry
4. Return token to caller

#### KLT API Helper (50101)
Common HTTP operations and utility functions.

**Methods:**
- `SendGetRequest()`: HTTP GET with auth
- `SendPostRequest()`: HTTP POST with auth
- `SendPatchRequest()`: HTTP PATCH with auth
- `BuildApiUrl()`: Construct API endpoint URL
- `BuildApiUrlWithFilter()`: URL with OData filter
- `CategorizeError()`: Classify error message
- `LogApiOperation()`: Log API call
- `CheckDuplicateExists()`: Check for duplicate docs
- `SanitizeForJson()`: Escape JSON special characters

**HTTP Request Pattern:**
1. Get access token from authentication codeunit
2. Set authorization header with Bearer token
3. Set timeout from configuration
4. Send request and capture response
5. Return success/failure with response text

#### KLT Sales Doc Sync (50102)
Synchronizes sales documents from BC17 to BC27.

**Methods:**
- `SyncSalesInvoices()`: Sync all new/modified sales invoices
- `SyncSalesCreditMemos()`: Sync all new/modified credit memos
- `ProcessSalesDocuments()`: Process JSON array of documents
- `ProcessSingleDocument()`: Process individual document
- `CreateDocumentInBC27()`: POST to BC27 API

**Synchronization Flow:**
1. Get last sync timestamp from log
2. Build OData filter for modified documents
3. GET documents from BC17 API
4. Parse JSON response
5. For each document:
   - Check for duplicates
   - Create sync log entry
   - Validate document data
   - POST to BC27 API
   - Update sync log (success/failure)
   - Create error entry if failed

#### KLT Purchase Doc Sync (50103)
Synchronizes purchase documents from BC27 to BC17.

**Methods:**
- `SyncPurchaseInvoices()`: Sync all new/modified purchase invoices
- `SyncPurchaseCreditMemos()`: Sync all new/modified credit memos
- `ProcessPurchaseDocuments()`: Process JSON array
- `ProcessSingleDocument()`: Process individual document
- `CreateDocumentInBC17()`: POST to BC17 API

**Synchronization Flow:**
Same as sales sync but in reverse direction.

#### KLT Sync Engine (50104)
Main orchestration engine for all synchronization operations.

**Methods:**
- `RunScheduledSync()`: Main entry point for job queue
- `RunSalesInvoiceSync()`: Sync sales invoices only
- `RunSalesCreditMemoSync()`: Sync sales credit memos only
- `RunPurchaseInvoiceSync()`: Sync purchase invoices only
- `RunPurchaseCreditMemoSync()`: Sync purchase credit memos only
- `ProcessRetryQueue()`: Retry failed documents
- `CreateJobQueueEntry()`: Create scheduled job
- `GetSyncStatistics()`: Get performance metrics

**Scheduled Sync Flow:**
1. Check if sync is enabled
2. Run all sync operations with error handling:
   - Sales Invoices (BC17 → BC27)
   - Sales Credit Memos (BC17 → BC27)
   - Purchase Invoices (BC27 → BC17)
   - Purchase Credit Memos (BC27 → BC17)
3. Process retry queue for failed documents
4. Check error threshold and send alerts
5. Clean up old logs

#### KLT Document Validator (50105)
Validation logic for documents before synchronization.

**Methods:**
- `ValidateSalesDocumentHeader()`: Validate sales header
- `ValidatePurchaseDocumentHeader()`: Validate purchase header
- `ValidateDocumentLine()`: Validate line data
- `ValidateCurrency()`: Check currency exists
- `ValidatePaymentTerms()`: Check payment terms exist
- `ValidatePostingGroups()`: Validate posting setup
- `ValidateSystemSettings()`: Check system configuration

**Validation Rules:**
- **Header**: Customer/Vendor must exist and not blocked
- **Dates**: Posting date within allowed period
- **Currency**: Must exist or be blank (LCY)
- **Master Data**: All references must exist in target
- **Lines**: Type, No., Quantity, Unit Price required
- **Posting Groups**: Setup must exist

## API Integration

### Authentication Flow

```
1. Application requests access token
   ↓
2. POST to Azure AD token endpoint
   - grant_type=client_credentials
   - client_id={clientId}
   - client_secret={clientSecret}
   - scope=https://api.businesscentral.dynamics.com/.default
   ↓
3. Azure AD validates credentials
   ↓
4. Returns access token (valid 60 minutes)
   ↓
5. Cache token for 55 minutes
   ↓
6. Use token in Authorization header: Bearer {token}
```

### API Endpoints

#### Sales Documents (Outbound)

**Get Sales Invoices:**
```
GET {bc17BaseUrl}/api/v2.0/companies({companyId})/salesInvoices
?$filter=lastModifiedDateTime gt {timestamp}
```

**Get Sales Credit Memos:**
```
GET {bc17BaseUrl}/api/v2.0/companies({companyId})/salesCreditMemos
?$filter=lastModifiedDateTime gt {timestamp}
```

**Create Sales Invoice in BC27:**
```
POST {bc27BaseUrl}/api/v2.0/companies({companyId})/salesInvoices
Content-Type: application/json
Authorization: Bearer {token}

{
  "customerNumber": "C001",
  "postingDate": "2025-01-15",
  "documentDate": "2025-01-15",
  "externalDocumentNumber": "EXT-001",
  "currencyCode": "EUR",
  "paymentTermsCode": "30DAYS"
}
```

#### Purchase Documents (Inbound)

**Get Purchase Invoices:**
```
GET {bc27BaseUrl}/api/v2.0/companies({companyId})/purchaseInvoices
?$filter=lastModifiedDateTime gt {timestamp}
```

**Create Purchase Invoice in BC17:**
```
POST {bc17BaseUrl}/api/v2.0/companies({companyId})/purchaseInvoices
Content-Type: application/json
Authorization: Bearer {token}

{
  "vendorNumber": "V001",
  "postingDate": "2025-01-15",
  "documentDate": "2025-01-15",
  "vendorInvoiceNumber": "VINV-001",
  "currencyCode": "EUR"
}
```

### Field Mapping

#### Sales Invoice/Credit Memo

| BC17 Field | BC27 Field | Required | Notes |
|-----------|-----------|----------|-------|
| customerNumber | customerNumber | Yes | Must exist in BC27 |
| postingDate | postingDate | Yes | Within allowed period |
| documentDate | documentDate | Yes | |
| externalDocumentNumber | externalDocumentNumber | No | Used for duplicate check |
| currencyCode | currencyCode | No | Default: LCY |
| paymentTermsCode | paymentTermsCode | No | Default: Customer default |
| shipmentMethodCode | shipmentMethodCode | No | |
| salespersonCode | salespersonCode | No | |

#### Purchase Invoice/Credit Memo

| BC27 Field | BC17 Field | Required | Notes |
|-----------|-----------|----------|-------|
| vendorNumber | vendorNumber | Yes | Must exist in BC17 |
| postingDate | postingDate | Yes | Within allowed period |
| documentDate | documentDate | Yes | |
| vendorInvoiceNumber | vendorInvoiceNumber | Yes | External doc no. |
| currencyCode | currencyCode | No | Default: LCY |
| paymentTermsCode | paymentTermsCode | No | Default: Vendor default |

## Error Handling

### Error Categories and Retry Logic

| Category | Retryable | Retry Strategy | Manual Action |
|----------|-----------|----------------|---------------|
| API Communication | Yes | Exponential backoff | Wait or check network |
| Authentication | Yes | Exponential backoff | Check credentials |
| Data Validation | No | - | Fix source data |
| Business Logic | No | - | Review business rules |
| Master Data Missing | No | - | Create master data |

### Retry Strategy

**Exponential Backoff:**
- Attempt 1: Wait 1 minute
- Attempt 2: Wait 2 minutes
- Attempt 3: Wait 4 minutes
- Max wait: 60 minutes

**Max Attempts:** 3 (configurable)

**Retry Conditions:**
- API Communication errors
- Authentication failures
- Timeout errors
- Service unavailable (503)

### Error Logging

All errors logged with:
- Timestamp
- Error category
- Error message
- Stack trace (if available)
- Document details
- JSON error details (extended)
- Retry status

## Performance

### Optimization Strategies

1. **Token Caching**: Reduces auth overhead
2. **Incremental Sync**: Only modified documents
3. **Batch Processing**: Up to 100 docs per cycle
4. **Parallel Processing**: Independent document processing
5. **Connection Pooling**: Reuse HTTP connections

### Performance Metrics

**Target SLAs:**
- API call: < 5 seconds
- Document creation: < 3 seconds
- Batch of 100: < 15 minutes
- End-to-end: < 30 minutes

**Monitoring:**
- Duration (ms) logged per document
- Statistics available in UI
- Error rate tracking
- Alert on > 25% error rate

## Security

### Authentication
- OAuth 2.0 Client Credentials
- Azure AD integration
- Service principals
- Dedicated service accounts

### Data Protection
- TLS 1.2+ encryption
- Credentials masked in UI
- Extended datatype: Masked
- No sensitive data in logs

### Access Control
- Permission set: KLT API Integration (50100)
- User-level permissions
- Read-only on source
- Write-only on target

### Recommendations
- Azure Key Vault for credentials (production)
- Regular credential rotation
- Least privilege principle
- Audit log monitoring

## Deployment

### Installation Steps

1. Import AL extension
2. Assign permissions
3. Run Setup Wizard
4. Test connections
5. Create job queue entry
6. Enable synchronization

### Prerequisites

**Master Data (must exist in both BC17 and BC27):**
- Customers & Vendors
- Items, Resources, G/L Accounts
- Posting Groups
- Payment Terms
- Currency Codes
- Number Series

**System Configuration:**
- API enabled in both environments
- Service accounts created
- Azure AD app registrations
- OAuth credentials obtained

### Configuration Checklist

- [ ] BC17 Base URL configured
- [ ] BC17 Company ID set
- [ ] BC17 OAuth credentials entered
- [ ] BC27 Base URL configured
- [ ] BC27 Company ID set
- [ ] BC27 OAuth credentials entered
- [ ] Sync interval set (15 min)
- [ ] Batch size configured (100)
- [ ] Alert email entered
- [ ] Connection test successful
- [ ] Job queue entry created
- [ ] Sync enabled

## Monitoring & Maintenance

### Daily Monitoring

1. Check Document Sync Log for failures
2. Review error count and categories
3. Monitor success rate (target > 95%)
4. Check pending retry queue
5. Verify job queue entry is running

### Weekly Maintenance

1. Review error trends
2. Check system performance
3. Validate master data sync
4. Review log retention
5. Test connection

### Monthly Maintenance

1. Review and archive logs
2. Update credentials if needed
3. Performance analysis
4. Capacity planning
5. User feedback review

## Troubleshooting Guide

### Common Issues

**1. Connection Test Fails**
- Check Base URL format
- Verify Company GUID
- Validate Tenant ID
- Test OAuth credentials
- Check network connectivity

**2. Documents Not Syncing**
- Verify "Enable Sync" is checked
- Check Job Queue Entry status
- Review sync log for errors
- Validate posting periods

**3. Authentication Errors**
- Regenerate OAuth credentials
- Check Azure AD app permissions
- Verify Tenant ID
- Clear token cache

**4. Master Data Errors**
- Compare master data between systems
- Create missing records
- Validate posting groups
- Check blocked records

**5. Performance Issues**
- Reduce batch size
- Increase sync interval
- Check network latency
- Review API quotas

## Version Information

**Version:** 1.0.0.0  
**Runtime:** 7.0  
**Platform:** BC v17.0+  
**AL Language:** Latest  
**Dependencies:** None

## Future Enhancements

Potential future features:
- Document line synchronization
- Item tracking support
- Document attachments
- Real-time sync
- Approval workflow integration
- Advanced field mapping
- Custom transformations
- Multi-company support
- Historical data migration
