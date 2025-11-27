# Kelteks API Integration Project - Custom Instructions

You are an expert Business Central AL developer working on the Kelteks API Integration project for Fiskalizacija 2.0 compliance.

## Project Context

This is a **split-architecture** project with two companion AL extensions:
- **KelteksAPIIntegrationBC17** (app v1.0, BC Platform 17.0, Runtime 7.0): Sends posted sales docs → BC27; receives purchase docs ← BC27
- **KelteksAPIIntegrationBC27** (app v2.0, BC Platform 27.0, Runtime 14.0): Receives sales docs ← BC17; sends purchase docs → BC17

**Critical**: Both apps share the **same app ID** (`8a5e1b2c-3d4e-5f6a-7b8c-9d0e1f2a3b4c`) but different object ID ranges to enable BC17→BC27 upgrade path.

## Key Project Information

- **Client**: Kelteks
- **JIRA**: ZGBCSKELTE-54
- **Consultant**: Ana Šetka
- **Requestor**: Miroslav Gjurinski

## Object ID Ranges (NEVER overlap)

- **BC17 Extension**: 50100-50149 (app v1.0)
- **BC27 Extension**: 50150-50199 (app v2.0, upgradeable from BC17)

**When adding new objects, always check which project you're in** and use the correct range. Verify by checking `app.json` platform version.

## Technical Architecture

### Integration Pattern
- Point-to-point RESTful API integration using Business Central OData/API endpoints
- Scheduled batch processing (every 15 minutes) via Job Queue
- **4 authentication methods supported**: OAuth 2.0 (recommended), Basic, Windows, Certificate

### Authentication Architecture
Both apps support multiple auth methods via `KLT Auth Method` enum:
1. **OAuth 2.0**: Azure AD-based (cloud/hybrid), 55-minute token caching in `KLTAPIAuth.Codeunit.al`
2. **Basic**: Username/password for on-premise (**HTTPS required**)
3. **Windows**: Domain-based integrated auth (same domain only)
4. **Certificate**: Mutual TLS with certificate thumbprint

Implementation: `AddAuthenticationHeader()` method selects auth based on config. Credentials use `ExtendedDatatype = Masked` for security.

### API Endpoints
**BC17 reads from BC27 (for outbound sales):**
- BC17 calls BC27: `POST /api/v2.0/companies({id})/purchaseInvoices` (creates unposted purchase docs in BC27)
- BC17 calls BC27: `POST /api/v2.0/companies({id})/purchaseCreditMemos`

**BC27 reads from BC17 (for outbound purchase):**
- BC27 calls BC17: `POST /api/v2.0/companies({id})/purchaseInvoices` (creates unposted purchase docs in BC17)
- BC27 calls BC17: `POST /api/v2.0/companies({id})/purchaseCreditMemos`

Uses OData filters: `?$filter=lastModifiedDateTime gt {timestamp}` for incremental sync

## Document Flow

### Sales Documents (BC17 → BC27)
```
Posted Sales Invoice/Credit Memo (BC17)
  → KLT Sync Queue (table 50103) - queued with status tracking
  → KLT Sales Doc Sync (codeunit 50102) - HTTP POST with retry logic
  → BC27 API creates unposted Purchase Invoice/Credit Memo
  → KLT Document Sync Log (table 50101) - audit trail
```
1. Posted Sales Invoices and Credit Memos transferred from BC17
2. Created as **unposted** Purchase Invoices/Credit Memos in BC27
3. Users in BC27 review, post, and send eRačun documents
4. Item tracking is excluded

### Purchase Documents (BC27 → BC17)
```
Unposted Purchase Invoice/Credit Memo (BC27)
  → KLT Purchase Doc Sync (codeunit) - HTTP POST to BC17
  → BC17 API creates unposted Purchase Invoice/Credit Memo
  → KLT Document Sync Log (table 50151) - audit trail
```
1. Incoming eRačuni in BC27 created as Purchase Invoices
2. Documents **NOT posted** in BC27
3. Unposted documents transferred to BC17
4. If goods receipts exist: lines cleared and reloaded via "Get Receipt Lines"
5. Uses dedicated number series configured in `KLT API Config`

### Key Tables (identical structure across BC17/BC27)
- **KLT API Config** (50100/50150): Singleton table (one record, `Primary Key = ''`), stores auth, batch size, intervals. Use `GetInstance()` method.
- **KLT Document Sync Log** (50101/50151): Audit trail with status enum, error messages, duration tracking
- **KLT API Sync Queue** (50103/50153): Pending documents with retry logic, exponential backoff (2^n minutes, max 60)

## Coding Standards & Best Practices

### Naming Conventions (Strictly Enforced)
- **Prefix**: All objects start with `KLT` (Kelteks)
- **Tables**: `KLT<DescriptiveName>.Table.al` (e.g., `KLTAPIConfig.Table.al`)
- **Codeunits**: `KLT<Purpose>.Codeunit.al` (e.g., `KLTSyncEngine.Codeunit.al`)
- **Pages**: `KLT<Name>.Page.al` or `KLT<BaseObject>.PageExt.al` for extensions
- **Enums**: `KLT<Name>.Enum.al`

### Documentation Standard (Required)
All objects **must** include XML-style summary comments:
```al
/// <summary>
/// Brief description of purpose
/// Key responsibilities or usage notes
/// </summary>
```

### AL Development
- **Runtime versions**: BC17 uses runtime 7.0; BC27 uses runtime 14.0
- **Features**: `NoImplicitWith` enforced (always explicit record references)
- **Casing**: PascalCase for objects/procedures; camelCase for variables
- Use modern AL syntax and patterns
- Implement proper error handling with try-catch blocks
- Log all API operations with timestamp, status, and error details
- Use enums for document types and status values (`KLT Document Type`, `KLT Sync Status`, `KLT Error Category`)
- Implement retry logic for transient API failures (3 attempts, exponential backoff)
- **Critical**: Always use `Commit()` after database modifications in sync loops to prevent transaction rollback (see `KLTSyncEngine.Codeunit.al`)

### API Integration
- Always use TLS 1.2+ for communications
- Store credentials securely (Azure Key Vault or BC `ExtendedDatatype = Masked` fields)
- Implement timeout handling (default 5 seconds per document, configurable in `KLT API Config`)
- Use batch processing (default 100 documents per cycle, max 1000, configurable)
- Track document state with modification timestamps
- **OAuth token caching**: Tokens cached for 55 minutes (`TokenExpiry` in `KLTAPIAuth.Codeunit.al`); use `ClearTokenCache()` to force refresh
- **Error logging**: Uses standard BC Error Message table (not custom) with Context = "KLT Document Sync Log"

### Job Queue Integration
Sync runs via standard BC Job Queue:
- **BC17**: Object Type = Codeunit, Object ID = 50105 (`KLT Sync Engine`)
- **BC27**: Object Type = Codeunit, Object ID = 50154
- **Default interval**: 15 minutes (configurable via `Sync Interval (Minutes)` in config)
- Monitor via **Job Queue Entries** page

### Field Mapping Requirements
**Required Fields (fail if missing):**
- Customer/Vendor No.
- Posting Date (must be within allowed period)
- Document Date
- Line Type, No., Quantity, Unit Price

**Default Handling:**
- Payment Terms → customer/vendor default
- Currency → LCY if blank
- Location → blank or company default
- Dimensions → skip if missing

### Error Handling Categories
1. **API Communication Errors**: Network timeouts, auth failures, service unavailability
2. **Data Validation Errors**: Missing fields, invalid references, duplicates
3. **Business Logic Errors**: Posting failures, VAT mismatches, negative inventory
4. **Authentication**: Token expired, invalid credentials, unauthorized

**Error Response:**
- Log to **Error Message** table (standard BC table) with full context
- Auto-retry transient failures (up to `Max Retry Attempts` in config)
- Send email notifications for critical failures (if `Alert Email Address` configured)
- Never expose sensitive data in logs
- Error categories via `KLT Error Category` enum: API Communication, Data Validation, Business Logic, Authentication, Master Data Missing

### Common Pitfalls & Solutions

**Error: "Duplicate object ID"**  
Cause: Used BC17 range (50100-50149) in BC27 project or vice versa  
Fix: Check `app.json` platform version → BC17=17.0, BC27=27.0

**Error: "GetInstance() not found"**  
Cause: Configuration not initialized (singleton pattern)  
Fix: `KLT API Config` has `GetInstance()` method that auto-creates record with `Primary Key = ''`

**Sync hangs indefinitely**  
Cause: Missing `Commit()` after status updates  
Fix: Always call `Commit()` after `SyncQueue.Modify(true)` in loops

**Token refresh failures (OAuth)**  
Cause: Cached token expired  
Fix: `GetAccessToken()` checks `TokenExpiry > CurrentDateTime()`; use `ClearTokenCache()` action to force refresh

### Validation Rules
- Check for duplicates using External Document No.
- Validate all master data exists in target system
- Verify posting groups configuration
- Ensure VAT % matches posting group setup
- Confirm posting periods are open

## Development Workflows

### Building & Testing
This repo uses **AL-Go for GitHub** (v8.0). Scripts in `.AL-Go/`:
- **localDevEnv.ps1**: Creates Docker-based BC container (requires Docker Desktop with Windows containers)
- **cloudDevEnv.ps1**: Creates cloud sandbox via Microsoft
- **settings.json**: Defines `appFolders: ["KelteksAPIIntegrationBC17", "KelteksAPIIntegrationBC27"]`

**Do not modify AL-Go scripts** (auto-updated from template). Customize via user-specific scripts like `{username}-devenv.ps1`.

### Testing Changes
1. **Build**: Use AL extension build command or AL-Go workflows in `.github/workflows/`
2. **Publish**: To local Docker container via `localDevEnv.ps1` or cloud sandbox via `cloudDevEnv.ps1`
3. **Test sync**: Manually trigger via "Sync to BC27" action on Posted Sales Invoices list (BC17) or Purchase Invoices (BC27)
4. **Monitor**: Check **KLT Document Sync Log** for success/errors (filter by `Status` enum: Pending, Completed, Failed, Retrying)

### Version Upgrade Strategy
BC27 app (v2.0) is designed to **upgrade from BC17 app (v1.0)** when installed on BC27:
- `KLTUpgrade.Codeunit.al` (Subtype = Upgrade) handles migration
- Preserves API Config + Sync Log data
- Sync Queue is NOT migrated (environment-specific)
- Upgrade tag: `KLT-API-UPGRADE-V2.0-20251126`

When making schema changes, update upgrade codeunit to migrate data.

### Setup Documentation
Comprehensive setup guides exist for different auth scenarios:
- **SETUP-BASIC.md**: Basic Authentication (username/password)
- **SETUP-OAUTH.md**: OAuth 2.0 with Azure AD
- **SETUP-WINDOWS.md**: Windows Integrated Auth
- **SETUP-CERTIFICATE.md**: Certificate-based mutual TLS

Always reference these when troubleshooting connection issues.

### BC17 Settings
- Dedicated number series for purchase documents
- Allow negative inventory if needed

### BC27 Settings
- Enable negative inventory
- Disable exact cost reversal (storno točnog troška)
- Allow manual numbering of sales invoices
- Configure prepayment posting manually

## Master Data Prerequisites

Ensure these are migrated to both environments:
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
- Fiskalizacija 2.0 settings (KPD codes, tax categories, vendor code mappings)

## Performance Targets

- API response time: < 5 seconds per document
- Batch processing: 100 documents per 15-minute cycle
- End-to-end latency: < 30 minutes under normal load
- Expected volumes: 50-200 sales invoices/day, 30-100 purchase invoices/day
- Peak periods: 3x normal volume (month-end)

## Monitoring & Logging

### Required Logs
- DateTime, Source, Target, Document No., Status, Error Message
- All API requests/responses with timestamp and status
- Document transfer history (source ID, target ID, status)
- Retention: 12 months minimum

### Alerts
**Critical (immediate):**
- API authentication failures
- Sync process stopped/crashed
- Error rate > 25%

**Warning (hourly digest):**
- Individual document failures
- Performance degradation
- Queue backlog

## Out of Scope

- Item tracking (lot/serial numbers)
- Automatic posting in target systems
- Prepayment automation
- Historical document migration
- Real-time sync (< 15 minutes)
- Document attachments/files
- Approval workflow integration

## Key Files for Common Tasks

**Adding new auth method**: Edit `KLTAuthMethod.Enum.al` + `KLTAPIAuth.Codeunit.al` (AddAuthenticationHeader switch case)  
**Changing sync logic**: `KLTSyncEngine.Codeunit.al` (BC17) or equivalent in BC27  
**Field mappings**: `KLTSalesDocSync.Codeunit.al` / `KLTPurchaseDocSync.Codeunit.al`  
**Retry/queue logic**: `KLTSyncEngine.ProcessRetryQueue()` uses exponential backoff (2^n minutes, max 60)  
**Configuration UI**: `KLTAPIConfiguration.Page.al` with Test Connection action

## When Writing Code

1. **Always validate** master data existence before creating documents
2. **Implement proper error handling** with detailed logging
3. **Use transactions** to ensure data consistency
4. **Check for duplicates** before creating new records (use External Document No.)
5. **Respect performance limits** - batch operations appropriately
6. **Follow BC best practices** for API consumption and extension development
7. **Document your code** with XML-style `/// <summary>` comments
8. **Test error scenarios** thoroughly before deployment
9. **Use `Commit()` after DB modifications** in loops to prevent rollback
10. **Never hard-code values** - use configuration table fields

## Security Requirements

- Use OAuth 2.0 for all API calls
- Store credentials in Azure Key Vault
- Implement service accounts with minimum required permissions
- Never log sensitive data (credentials, personal information)
- Ensure TLS 1.2+ for all communications

## Testing Checklist

Before deployment, ensure:
- [ ] API connectivity tested (both directions)
- [ ] All document types transfer successfully
- [ ] Error handling works for all error categories
- [ ] Duplicate prevention functioning
- [ ] Master data validation working
- [ ] Performance meets SLAs
- [ ] Logging captures all required information
- [ ] Alerts trigger correctly
- [ ] Rollback procedure tested

---

**Reference**: Full technical specification in `Technical_Specification_Kelteks_API.md`
