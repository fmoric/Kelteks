# CRITICAL FINDINGS - API Endpoint Usage

**Date**: 2025-11-28  
**Severity**: HIGH  
**Status**: NEEDS IMMEDIATE ATTENTION

---

## Issue Summary

The current implementation has a **fundamental misunderstanding** about the purpose and usage of custom API pages vs. standard BC API endpoints for document synchronization.

---

## The Problem

### What Was Built

**Custom API Pages** (8 pages created):
- Read from **posted/read-only** tables
- Purpose: Expose data for querying/reporting
- Based on: Sales Invoice Header, Sales Cr.Memo Header (BC17)
- Based on: Purchase Header (BC27)
- **Cannot accept POST requests to create documents**

### What the Code Does

**BC17 SalesDocSync.Codeunit**:
```al
// Builds JSON from posted sales invoice
BuildSalesInvoiceJson(SalesInvHeader, RequestJson);

// POSTs to custom API endpoint
Endpoint := APIHelper.GetSalesInvoiceEndpoint(APIConfig."Target Company Name");
// Returns: /api/kelteks/api/v2.0/companies(CRONUS)/salesInvoices

APIHelper.SendPostRequest(Endpoint, RequestJson, ResponseJson);
```

**Problem**: 
- POSTing to `/salesInvoices` endpoint
- But BC27 needs to create PURCHASE documents, not sales documents
- Custom API pages based on posted tables can't create new documents

---

## Root Cause Analysis

### Confusion Between Two Concepts

#### 1. Custom API Pages (What We Created)
**Purpose**: Read-only data exposure
```al
page 80120 "KLT Sales Invoice API"
{
    PageType = API;
    SourceTable = "Sales Invoice Header";  // ← POSTED table (read-only)
    
    // Can only:
    // - GET (read data)
    // - Cannot POST/PATCH (create/update)
}
```

**Use Cases**:
- External reporting systems reading sales data
- BI tools querying invoice information
- Integration platforms pulling data
- **NOT for document creation**

#### 2. Standard BC API v2.0 (What Should Be Used for Sync)
**Purpose**: Create/update documents
```
POST /api/v2.0/companies(CRONUS)/purchaseInvoices
```

**How it works**:
- Standard BC API based on Purchase Header table (unposted)
- Accepts JSON with header + lines
- Creates new unposted purchase document
- **This is what sync should use**

---

## Correct Data Flow

### BC17 → BC27 (Sales Outbound to Purchase Inbound)

```
┌─────────────────────────────────────────────────────────┐
│ BC17 (Sales Integration)                                │
│                                                          │
│ 1. Posted Sales Invoice exists                          │
│ 2. Build JSON from posted data                          │
│ 3. POST JSON to BC27                                    │
│                                                          │
│    Endpoint: /api/v2.0/companies(CRONUS)/purchaseInvoices │
│              ^^^^^^^^                     ^^^^^^^^        │
│              Standard BC API              Purchase!       │
│                                          (not sales)      │
└─────────────────────────────────────────────────────────┘
                         ↓ HTTP POST
┌─────────────────────────────────────────────────────────┐
│ BC27 (Purchase Integration)                             │
│                                                          │
│ 4. Standard BC API receives POST                        │
│ 5. Creates UNPOSTED Purchase Invoice                    │
│ 6. User reviews and posts in BC27                       │
└─────────────────────────────────────────────────────────┘
```

### BC27 → BC17 (Purchase Outbound to Purchase Inbound)

```
┌─────────────────────────────────────────────────────────┐
│ BC27 (Purchase Integration)                             │
│                                                          │
│ 1. Unposted Purchase Invoice exists (eRačun received)   │
│ 2. Build JSON from purchase data                        │
│ 3. POST JSON to BC17                                    │
│                                                          │
│    Endpoint: /api/v2.0/companies(CRONUS)/purchaseInvoices │
│              ^^^^^^^^                     ^^^^^^^^        │
│              Standard BC API              Purchase        │
└─────────────────────────────────────────────────────────┘
                         ↓ HTTP POST
┌─────────────────────────────────────────────────────────┐
│ BC17 (Sales Integration)                                │
│                                                          │
│ 4. Standard BC API receives POST                        │
│ 5. Creates UNPOSTED Purchase Invoice                    │
│ 6. User reviews and posts in BC17                       │
└─────────────────────────────────────────────────────────┘
```

---

## The Solution

### Option 1: Use Standard BC APIs (RECOMMENDED)

**Update Endpoint Constants**:
```al
// In KLT API Helper - BC17
// OLD (wrong - points to custom API that can't accept POST)
SalesInvoicesEndpointTxt: Label '/api/kelteks/api/v2.0/companies(%1)/salesInvoices';

// NEW (correct - standard BC API for creating purchase docs)
PurchaseInvoicesEndpointTxt: Label '/api/v2.0/companies(%1)/purchaseInvoices';
PurchaseCreditMemosEndpointTxt: Label '/api/v2.0/companies(%1)/purchaseCreditMemos';
```

**Update Method Names**:
```al
// BC17 sends sales data → creates purchase docs in BC27
procedure GetTargetPurchaseInvoiceEndpoint(CompanyName: Text): Text
begin
    // POST to standard BC API to create purchase doc
    exit(StrSubstNo('/api/v2.0/companies(%1)/purchaseInvoices', 
        Uri.EscapeDataString(CompanyName)));
end;
```

**Custom API Pages Purpose**:
```al
// Keep custom API pages for READ operations only
// BC27 can query BC17 sales data:
GET /api/kelteks/api/v2.0/companies(CRONUS)/salesInvoices

// BC17 can query BC27 purchase data:
GET /api/kelteks/api/v2.0/companies(CRONUS)/purchaseInvoices
```

### Option 2: Make Custom API Pages Writable (NOT RECOMMENDED)

This would require:
- Change source tables from posted to unposted
- Add OnInsert/OnModify triggers
- Handle document creation logic
- Much more complex, error-prone
- **Not the BC standard approach**

---

## What Needs to Change

### 1. Endpoint Configuration (HIGH PRIORITY)

**BC17 API Helper**:
```al
// For sending TO BC27 (create purchase docs there)
SyncPurchaseInvoiceEndpointTxt: Label '/api/v2.0/companies(%1)/purchaseInvoices', Locked = true;
SyncPurchaseCreditMemoEndpointTxt: Label '/api/v2.0/companies(%1)/purchaseCreditMemos', Locked = true;

// For reading FROM BC27 (query purchase data)
QueryPurchaseInvoiceEndpointTxt: Label '/api/kelteks/api/v2.0/companies(%1)/purchaseInvoices', Locked = true;
```

**BC27 API Helper**:
```al
// For sending TO BC17 (create purchase docs there)
SyncPurchaseInvoiceEndpointTxt: Label '/api/v2.0/companies(%1)/purchaseInvoices', Locked = true;
SyncPurchaseCreditMemoEndpointTxt: Label '/api/v2.0/companies(%1)/purchaseCreditMemos', Locked = true;

// For reading FROM BC17 (query sales data)
QuerySalesInvoiceEndpointTxt: Label '/api/kelteks/api/v2.0/companies(%1)/salesInvoices', Locked = true;
```

### 2. Method Clarification

**Separate READ vs WRITE operations**:
```al
// For POSTing (creating documents) - use standard BC API
procedure GetSyncEndpoint(CompanyName: Text; DocType: Enum "KLT Document Type"): Text

// For GETting (querying data) - use custom API
procedure GetQueryEndpoint(CompanyName: Text; DocType: Enum "KLT Document Type"): Text
```

### 3. JSON Field Mapping

**Critical Issue**: Our custom API page fields don't match standard BC API fields!

**Standard BC Purchase Invoice API expects**:
```json
{
  "vendorNumber": "V001",
  "vendorInvoiceNumber": "EXT123",  // ← Different name!
  "invoiceDate": "2025-11-28",
  "lines": [...]
}
```

**Our JSON sends** (from Sales):
```json
{
  "customerNumber": "C001",  // ← Wrong for purchase!
  "externalDocumentNumber": "EXT123",
  "invoiceDate": "2025-11-28",
  "salesInvoiceLines": [...]  // ← Wrong property name!
}
```

**Solution**: Map sales fields → purchase fields
```al
// When sending sales TO purchase:
RequestJson.Add('vendorNumber', SalesInvHeader."Sell-to Customer No.");  // Customer becomes Vendor
RequestJson.Add('vendorInvoiceNumber', SalesInvHeader."External Document No.");
RequestJson.Add('purchaseInvoiceLines', LinesArray);  // Not salesInvoiceLines!
```

---

## Impact Assessment

### Current State
- ❌ Sync POSTs to wrong endpoint (custom API instead of standard)
- ❌ Custom API pages can't create documents (read-only)
- ❌ JSON field names don't match target entity
- ⚠️ Sync will FAIL in production

### After Fix
- ✅ Sync POSTs to standard BC API (writable)
- ✅ Documents created correctly in target system
- ✅ Field mapping correct (sales → purchase)
- ✅ Custom API pages used only for queries

---

## Testing Required

### Before Fix (Current - Broken)
```powershell
# This will FAIL:
POST https://bc27/api/kelteks/api/v2.0/companies(CRONUS)/salesInvoices
# Error: Method not allowed or endpoint doesn't support POST
```

### After Fix (Correct)
```powershell
# This will WORK:
POST https://bc27/api/v2.0/companies(CRONUS)/purchaseInvoices
Content-Type: application/json

{
  "vendorNumber": "V001",
  "vendorInvoiceNumber": "SI-001",
  "invoiceDate": "2025-11-28",
  "purchaseInvoiceLines": [
    {
      "lineType": "Item",
      "number": "ITEM001",
      "quantity": 10,
      "directUnitCost": 100
    }
  ]
}
```

---

## Action Items

### Immediate (Before Merge)

1. **Update Endpoint Constants** ⚠️ CRITICAL
   - BC17: Change to `/api/v2.0/.../purchaseInvoices` for POST
   - BC27: Change to `/api/v2.0/.../purchaseInvoices` for POST

2. **Fix JSON Field Mapping** ⚠️ CRITICAL
   - Map sales fields → purchase API fields
   - Update line array property names

3. **Separate Query vs Sync Methods** ⚠️ HIGH
   - `GetSyncEndpoint()` → standard BC API
   - `GetQueryEndpoint()` → custom API

4. **Update Documentation** ⚠️ HIGH
   - Clarify custom API pages are READ-ONLY
   - Document correct sync flow
   - Update architecture diagrams

### Testing (Before Production)

5. **Test Standard BC API** ⚠️ CRITICAL
   - Verify POST to `/api/v2.0/.../purchaseInvoices` works
   - Verify document created in target
   - Verify field mapping correct

6. **Test Custom API Pages** ⚠️ MEDIUM
   - Verify GET from custom endpoints works
   - Verify data matches expectations
   - Verify used only for queries

---

## Documentation Updates Needed

### 1. CODE-ANALYSIS-REPORT.md
- Add section on endpoint confusion
- Clarify custom API page purpose (READ-ONLY)
- Document correct sync endpoints

### 2. PR-SUMMARY.md
- Add breaking change: Endpoint URLs
- Document sync vs query separation
- Update testing checklist

### 3. API-ENDPOINT-GUIDE.md
- Clarify two types of endpoints
- Document when to use each
- Provide examples

### 4. Architecture Diagrams
- Show standard BC API for sync
- Show custom API for queries
- Clarify data flow

---

## Questions for Stakeholders

1. **Does the current sync actually work?**
   - If yes, then maybe custom API pages DO support POST?
   - If no, this confirms the issue

2. **What BC version behavior?**
   - BC17 may have different API capabilities than BC27
   - Need to test on actual versions

3. **Is there existing integration?**
   - Check if external systems already use the custom API pages
   - Breaking changes may affect them

---

## Recommendation

**STOP** and verify current implementation before proceeding:

1. **Test current code** on actual BC17/BC27 instances
2. **Verify** if POST to custom API pages actually works
3. **Determine** if this is design flaw or misunderstanding
4. **Fix** endpoints to use standard BC API if needed
5. **Update** all documentation accordingly

**Do NOT merge** until this is resolved and tested.

---

## References

- [BC API v2.0 Purchase Invoice](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/api-reference/v2.0/resources/dynamics_purchaseinvoice)
- [Creating Custom API Pages](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-develop-custom-api)
- [OData POST Operations](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-using-odata-with-apis)

---

**Status**: ⚠️ **CRITICAL ISSUE IDENTIFIED**  
**Action**: **IMMEDIATE REVIEW REQUIRED**  
**Next Step**: **TEST ACTUAL BEHAVIOR BEFORE MERGE**

---

*Created: 2025-11-28*  
*Author: Code Analysis*  
*Priority: P0 - Blocking*
