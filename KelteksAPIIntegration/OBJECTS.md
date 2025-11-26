# Kelteks API Integration - Object Reference

## Overview
This document provides a complete reference of all objects in the Kelteks API Integration extension for Business Central.

## Extension Metadata
- **ID**: 8a5e1b2c-3d4e-5f6a-7b8c-9d0e1f2a3b4c
- **Name**: Kelteks API Integration
- **Publisher**: Kelteks
- **Version**: 1.0.0.0
- **Platform**: BC v17.0+
- **Runtime**: 7.0

## Object ID Ranges
- **Tables**: 50100-50149
- **Pages**: 50100-50149
- **Codeunits**: 50100-50149
- **Enums**: 50100-50149
- **Page Extensions**: 50100-50103
- **Permission Sets**: 50100

## Tables

### Table 50100 - KLT API Configuration
**Purpose**: Singleton configuration table for API endpoints and settings

**Key Fields**:
- Primary Key (Code[10])
- BC17/BC27 Connection Settings (URLs, Tenant IDs, OAuth credentials)
- Synchronization Settings (interval, batch size, timeout, retry)
- Alert Settings (email, thresholds)
- Other Settings (log retention, number series)

**Methods**:
- `GetInstance()`: Get or create singleton
- `ValidateConfiguration()`: Check completeness

**File**: `src/Tables/KLTAPIConfiguration.Table.al`

---

### Table 50101 - KLT Document Sync Log
**Purpose**: Historical log of all document synchronization operations

**Key Fields**:
- Entry No. (Integer) - Auto-increment
- Sync Direction, Document Type
- Source/Target Document No. & System ID
- External Document No.
- Status, DateTime fields, Duration
- Customer/Vendor details
- Error Message, Retry information

**Methods**:
- `MarkAsCompleted()`: Update to completed
- `MarkAsFailed()`: Update to failed
- `IncrementRetryCount()`: Increment retry

**File**: `src/Tables/KLTDocumentSyncLog.Table.al`

---

### Table 50102 - KLT Document Sync Error
**Purpose**: Detailed error tracking with retry logic

**Key Fields**:
- Entry No. (Integer) - Auto-increment
- Sync Log Entry No., Error Category
- Error Message, Details (Blob), Stack Trace
- Document identification
- Retry fields (count, max, next time, can retry)
- Resolution fields

**Methods**:
- `MarkAsResolved()`: Mark as resolved
- `IncrementRetryCount()`: Update retry
- `SetErrorDetails()`: Store JSON error
- `GetErrorDetails()`: Retrieve JSON error
- `CalculateCanRetry()`: Check if retryable
- `CalculateNextRetryTime()`: Exponential backoff

**File**: `src/Tables/KLTDocumentSyncError.Table.al`

---

### Table 50103 - KLT API Sync Queue
**Purpose**: Queue for batch document synchronization

**Key Fields**:
- Entry No. (Integer) - Auto-increment
- Sync Direction, Document Type
- Document No. & System ID
- Status, Priority
- Processing Started, Sync Log Entry No.

**Methods**:
- `EnqueueDocument()`: Add to queue
- `MarkAsInProgress()`: Update status
- `MarkAsCompleted()`: Remove from queue
- `MarkAsFailed()`: Mark for retry

**File**: `src/Tables/KLTAPISyncQueue.Table.al`

## Enums

### Enum 50100 - KLT Document Type
**Values**:
- Sales Invoice
- Sales Credit Memo
- Purchase Invoice
- Purchase Credit Memo

**File**: `src/Enums/KLTDocumentType.Enum.al`

---

### Enum 50101 - KLT Sync Status
**Values**:
- Pending
- In Progress
- Completed
- Failed
- Retrying

**File**: `src/Enums/KLTSyncStatus.Enum.al`

---

### Enum 50102 - KLT Error Category
**Values**:
- API Communication
- Data Validation
- Business Logic
- Authentication
- Master Data Missing

**File**: `src/Enums/KLTErrorCategory.Enum.al`

---

### Enum 50103 - KLT Sync Direction
**Values**:
- Outbound (BC17 → BC27)
- Inbound (BC27 → BC17)

**File**: `src/Enums/KLTSyncDirection.Enum.al`

## Codeunits

### Codeunit 50100 - KLT API Authentication
**Purpose**: OAuth 2.0 authentication with token caching

**Key Methods**:
- `GetBC17AccessToken()`: Get token for BC17
- `GetBC27AccessToken()`: Get token for BC27
- `ClearTokenCache()`: Clear cache
- `ValidateAuthentication()`: Test connections

**Features**:
- Token caching (55 minutes)
- Automatic refresh
- Azure AD integration

**File**: `src/Codeunits/KLTAPIAuthentication.Codeunit.al`

---

### Codeunit 50101 - KLT API Helper
**Purpose**: Common HTTP operations and utilities

**Key Methods**:
- `SendGetRequest()`: HTTP GET with auth
- `SendPostRequest()`: HTTP POST with auth
- `SendPatchRequest()`: HTTP PATCH with auth
- `BuildApiUrl()`: Construct API URL
- `BuildApiUrlWithFilter()`: URL with OData filter
- `CategorizeError()`: Classify error
- `CheckDuplicateExists()`: Check for duplicates
- `SanitizeForJson()`: Escape JSON

**File**: `src/Codeunits/KLTAPIHelper.Codeunit.al`

---

### Codeunit 50102 - KLT Sales Doc Sync
**Purpose**: Outbound sales document synchronization (BC17 → BC27)

**Key Methods**:
- `SyncSalesInvoices()`: Sync sales invoices
- `SyncSalesCreditMemos()`: Sync credit memos
- `ProcessSalesDocuments()`: Process JSON array
- `ProcessSingleDocument()`: Process one document
- `CreateDocumentInBC27()`: POST to BC27

**File**: `src/Codeunits/KLTSalesDocSync.Codeunit.al`

---

### Codeunit 50103 - KLT Purchase Doc Sync
**Purpose**: Inbound purchase document synchronization (BC27 → BC17)

**Key Methods**:
- `SyncPurchaseInvoices()`: Sync purchase invoices
- `SyncPurchaseCreditMemos()`: Sync credit memos
- `ProcessPurchaseDocuments()`: Process JSON array
- `ProcessSingleDocument()`: Process one document
- `CreateDocumentInBC17()`: POST to BC17

**File**: `src/Codeunits/KLTPurchaseDocSync.Codeunit.al`

---

### Codeunit 50104 - KLT Sync Engine
**Purpose**: Main orchestration engine

**Key Methods**:
- `RunScheduledSync()`: Main entry point
- `RunSalesInvoiceSync()`: Sync sales invoices only
- `RunSalesCreditMemoSync()`: Sync sales credit memos only
- `RunPurchaseInvoiceSync()`: Sync purchase invoices only
- `RunPurchaseCreditMemoSync()`: Sync purchase credit memos only
- `ProcessRetryQueue()`: Retry failed docs
- `CreateJobQueueEntry()`: Create scheduled job
- `GetSyncStatistics()`: Get metrics

**File**: `src/Codeunits/KLTSyncEngine.Codeunit.al`

---

### Codeunit 50105 - KLT Document Validator
**Purpose**: Document validation before synchronization

**Key Methods**:
- `ValidateSalesDocumentHeader()`: Validate sales header
- `ValidatePurchaseDocumentHeader()`: Validate purchase header
- `ValidateDocumentLine()`: Validate line
- `ValidateCurrency()`: Check currency
- `ValidatePaymentTerms()`: Check payment terms
- `ValidatePostingGroups()`: Check posting setup
- `ValidateSystemSettings()`: Check system config

**File**: `src/Codeunits/KLTDocumentValidator.Codeunit.al`

## Pages

### Page 50100 - KLT API Configuration
**Type**: Card
**Source Table**: KLT API Configuration
**Purpose**: Configure API settings

**Key Actions**:
- Test Connection
- Create Job Queue Entry
- Run Sync Now
- View Sync Log
- View Errors

**File**: `src/Pages/KLTAPIConfiguration.Page.al`

---

### Page 50101 - KLT Document Sync Log
**Type**: List
**Source Table**: KLT Document Sync Log
**Purpose**: View synchronization history

**Key Actions**:
- Refresh
- Show Errors
- Show All
- View Error Details
- Statistics

**File**: `src/Pages/KLTDocumentSyncLog.Page.al`

---

### Page 50102 - KLT Document Sync Error
**Type**: List
**Source Table**: KLT Document Sync Error
**Purpose**: Manage synchronization errors

**Key Actions**:
- Mark as Resolved
- Retry Now
- Show Unresolved
- Show All
- View Sync Log
- View Error Details
- Statistics

**File**: `src/Pages/KLTDocumentSyncError.Page.al`

---

### Page 50103 - KLT Error Details FactBox
**Type**: CardPart
**Source Table**: KLT Document Sync Error
**Purpose**: Display error details in FactBox

**File**: `src/Pages/KLTErrorDetailsFactBox.Page.al`

---

### Page 50104 - KLT API Setup Wizard
**Type**: NavigatePage
**Purpose**: Guided setup wizard

**Steps**:
1. Welcome
2. BC17 Configuration
3. BC27 Configuration
4. Synchronization Settings
5. Test Connection
6. Finish

**File**: `src/Pages/KLTAPISetupWizard.Page.al`

## Page Extensions

### PageExtension 50100 - KLT Posted Sales Inv. List
**Extends**: Posted Sales Invoices
**Purpose**: Add sync actions to posted sales invoices

**Actions**:
- Sync to BC27 (queue single document)
- View Sync Log
- Run All Sync Now

**File**: `src/Pages/KLTPostedSalesInvList.PageExt.al`

---

### PageExtension 50101 - KLT Posted Sales Cr.M. List
**Extends**: Posted Sales Credit Memos
**Purpose**: Add sync actions to posted sales credit memos

**Actions**:
- Sync to BC27 (queue single document)
- View Sync Log
- Run All Sync Now

**File**: `src/Pages/KLTPostedSalesCrMList.PageExt.al`

---

### PageExtension 50102 - KLT Purchase Invoice List
**Extends**: Purchase Invoices
**Purpose**: Add sync status to purchase invoices

**Actions**:
- View Sync Log
- Run Sync from BC27
- Check Sync Status

**File**: `src/Pages/KLTPurchaseInvoiceList.PageExt.al`

---

### PageExtension 50103 - KLT Purch. Cr. Memo List
**Extends**: Purchase Credit Memos
**Purpose**: Add sync status to purchase credit memos

**Actions**:
- View Sync Log
- Run Sync from BC27
- Check Sync Status

**File**: `src/Pages/KLTPurchCrMemoList.PageExt.al`

## Permission Sets

### PermissionSet 50100 - KLT API Integration
**Purpose**: Full access to all extension objects

**Permissions**:
- All tables (RIMD - Read, Insert, Modify, Delete)
- All codeunits (Execute)
- All pages (Execute)
- All page extensions (Execute)

**File**: `src/KLTAPIIntegration.PermissionSet.al`

## Documentation Files

### README.md
**Purpose**: User guide and installation instructions
**Size**: ~9.4 KB
**Sections**:
- Overview and features
- Installation and configuration
- Usage and monitoring
- Document flow
- Error handling
- Troubleshooting basics
- Support information

---

### TECHNICAL.md
**Purpose**: Technical specification for developers
**Size**: ~16.7 KB
**Sections**:
- Architecture overview
- Object ID ranges
- Data model details
- Business logic flows
- API integration details
- Field mapping specifications
- Error handling strategies
- Performance optimization
- Security implementation
- Deployment procedures
- Monitoring and maintenance

---

### TROUBLESHOOTING.md
**Purpose**: Comprehensive troubleshooting guide
**Size**: ~11.6 KB
**Sections**:
- Quick diagnostics
- Common issues and solutions
- Diagnostic queries
- Preventive maintenance
- Emergency procedures
- Advanced troubleshooting
- Contact information

## File Structure

```
KelteksAPIIntegration/
├── app.json
├── README.md
├── TECHNICAL.md
├── TROUBLESHOOTING.md
└── src/
    ├── Enums/
    │   ├── KLTDocumentType.Enum.al
    │   ├── KLTSyncStatus.Enum.al
    │   ├── KLTErrorCategory.Enum.al
    │   └── KLTSyncDirection.Enum.al
    ├── Tables/
    │   ├── KLTAPIConfiguration.Table.al
    │   ├── KLTDocumentSyncLog.Table.al
    │   ├── KLTDocumentSyncError.Table.al
    │   └── KLTAPISyncQueue.Table.al
    ├── Codeunits/
    │   ├── KLTAPIAuthentication.Codeunit.al
    │   ├── KLTAPIHelper.Codeunit.al
    │   ├── KLTSalesDocSync.Codeunit.al
    │   ├── KLTPurchaseDocSync.Codeunit.al
    │   ├── KLTSyncEngine.Codeunit.al
    │   └── KLTDocumentValidator.Codeunit.al
    ├── Pages/
    │   ├── KLTAPIConfiguration.Page.al
    │   ├── KLTDocumentSyncLog.Page.al
    │   ├── KLTDocumentSyncError.Page.al
    │   ├── KLTErrorDetailsFactBox.Page.al
    │   ├── KLTAPISetupWizard.Page.al
    │   ├── KLTPostedSalesInvList.PageExt.al
    │   ├── KLTPostedSalesCrMList.PageExt.al
    │   ├── KLTPurchaseInvoiceList.PageExt.al
    │   └── KLTPurchCrMemoList.PageExt.al
    └── KLTAPIIntegration.PermissionSet.al
```

## Total Object Count

| Object Type | Count |
|-------------|-------|
| Tables | 4 |
| Enums | 4 |
| Codeunits | 6 |
| Pages | 5 |
| Page Extensions | 4 |
| Permission Sets | 1 |
| **Total AL Objects** | **24** |
| Documentation Files | 3 |
| **Grand Total** | **27** |

## Dependencies

**External Dependencies**: None
**System Tables Referenced**:
- Customer
- Vendor
- Item
- G/L Account
- Resource
- Currency
- Payment Terms
- General Posting Setup
- User Setup
- General Ledger Setup
- Job Queue Entry
- No. Series

## Version History

### Version 1.0.0.0 (Initial Release)
- Complete API integration framework
- OAuth 2.0 authentication
- Bidirectional document synchronization
- Error handling and retry logic
- Comprehensive logging and monitoring
- Setup wizard and configuration UI
- Page extensions for easy access
- Complete documentation

---

**Last Updated**: 2025-01-15
**Maintained By**: Kelteks Development Team
