# Document Flow Clarification
## Posted vs Unposted Documents

**Date**: 2025-11-28  
**Status**: ✅ VERIFIED CORRECT

---

## Summary

The implementation is **ALREADY CORRECT** for the intended document flow:
- **BC17**: Posted sales documents → Unposted purchase documents in BC27
- **BC27**: Unposted purchase documents → Unposted purchase documents in BC17

---

## Detailed Flow

### BC17 → BC27 (Sales to Purchase)

```
┌─────────────────────────────────────────────────────────┐
│ BC17 - Sales Integration                                │
│                                                          │
│ Source Documents: POSTED Sales Invoices                 │
│ ├─ Sales Invoice Header (posted table)                  │
│ ├─ Sales Cr.Memo Header (posted table)                  │
│ └─ Already reviewed and posted by users                 │
│                                                          │
│ Custom API Page (READ-ONLY):                            │
│ GET /api/kelteks/v2.0/companies(...)/salesInvoices      │
│ ├─ Based on: "Sales Invoice Header" (posted)            │
│ └─ Purpose: External systems can query posted sales     │
│                                                          │
│ Sync Process:                                           │
│ ├─ Reads posted sales invoice                           │
│ ├─ Builds JSON with sales data                          │
│ ├─ POSTs to BC27 standard API                           │
│ └─ Endpoint: /api/v2.0/companies(...)/purchaseInvoices  │
└─────────────────────────────────────────────────────────┘
                         ↓
                    HTTP POST
                         ↓
┌─────────────────────────────────────────────────────────┐
│ BC27 - Purchase Integration                             │
│                                                          │
│ Standard BC API Receives POST:                          │
│ ├─ Validates JSON                                       │
│ ├─ Creates UNPOSTED Purchase Invoice                    │
│ └─ Document ready for review                            │
│                                                          │
│ Target Documents: UNPOSTED Purchase Invoices            │
│ ├─ Purchase Header (unposted, Document Type=Invoice)    │
│ ├─ Purchase Line                                        │
│ └─ Users review, modify, then post                      │
│                                                          │
│ Custom API Page (READ-ONLY):                            │
│ GET /api/kelteks/v2.0/companies(...)/purchaseInvoices   │
│ ├─ Based on: "Purchase Header" (UNPOSTED)              │
│ ├─ Filtered: Document Type = Invoice                    │
│ └─ Purpose: External systems can query unposted docs    │
└─────────────────────────────────────────────────────────┘
```

### BC27 → BC17 (Purchase to Purchase)

```
┌─────────────────────────────────────────────────────────┐
│ BC27 - Purchase Integration                             │
│                                                          │
│ Source Documents: UNPOSTED Purchase Invoices            │
│ ├─ Purchase Header (unposted, from eRačun)              │
│ ├─ Purchase Line                                        │
│ └─ NOT posted in BC27                                   │
│                                                          │
│ Custom API Page (READ-ONLY):                            │
│ GET /api/kelteks/v2.0/companies(...)/purchaseInvoices   │
│ ├─ Based on: "Purchase Header" (UNPOSTED)              │
│ └─ BC17 can query these if needed                       │
│                                                          │
│ Sync Process:                                           │
│ ├─ Reads unposted purchase invoice                      │
│ ├─ Builds JSON with purchase data                       │
│ ├─ POSTs to BC17 standard API                           │
│ └─ Endpoint: /api/v2.0/companies(...)/purchaseInvoices  │
└─────────────────────────────────────────────────────────┘
                         ↓
                    HTTP POST
                         ↓
┌─────────────────────────────────────────────────────────┐
│ BC17 - Sales Integration                                │
│                                                          │
│ Standard BC API Receives POST:                          │
│ ├─ Validates JSON                                       │
│ ├─ Creates UNPOSTED Purchase Invoice                    │
│ └─ Document ready for review                            │
│                                                          │
│ Target Documents: UNPOSTED Purchase Invoices            │
│ ├─ Purchase Header (unposted, Document Type=Invoice)    │
│ ├─ Purchase Line                                        │
│ ├─ Users review                                         │
│ ├─ Get receipt lines if goods already received          │
│ ├─ Modify if needed                                     │
│ └─ Post document                                        │
└─────────────────────────────────────────────────────────┘
```

---

## Table Sources - Verification

### BC17 Custom API Pages ✅ CORRECT

**Sales Invoice API** (Page 80120):
```al
SourceTable = "Sales Invoice Header";  // ← POSTED table (correct)
```
- Posted documents only
- Read-only by nature
- Source data is final/reviewed

**Sales Credit Memo API** (Page 80122):
```al
SourceTable = "Sales Cr.Memo Header";  // ← POSTED table (correct)
```
- Posted documents only
- Read-only by nature
- Source data is final/reviewed

### BC27 Custom API Pages ✅ CORRECT

**Purchase Invoice API** (Page 80120):
```al
SourceTable = "Purchase Header";
SourceTableView = where("Document Type" = const(Invoice));  // ← UNPOSTED (correct)
```
- Unposted purchase documents
- Working documents from eRačun
- NOT posted in BC27

**Purchase Credit Memo API** (Page 80122):
```al
SourceTable = "Purchase Header";
SourceTableView = where("Document Type" = const("Credit Memo"));  // ← UNPOSTED (correct)
```
- Unposted purchase documents
- Working documents
- NOT posted in BC27

---

## Document States Summary

| System | Document Type | State in Source | API Page Source | State in Target |
|--------|---------------|-----------------|-----------------|-----------------|
| **BC17 → BC27** |
| BC17 | Sales Invoice | **Posted** | Sales Invoice Header (posted) | N/A (doesn't stay) |
| BC27 | Purchase Invoice | N/A (newly created) | Purchase Header (unposted) | **Unposted** |
| **BC27 → BC17** |
| BC27 | Purchase Invoice | **Unposted** | Purchase Header (unposted) | N/A (doesn't stay) |
| BC17 | Purchase Invoice | N/A (newly created) | N/A (BC17 has no purchase API) | **Unposted** |

---

## Key Points

### ✅ Already Correct

1. **BC17 sends POSTED sales documents**
   - Source: Posted tables
   - Already final/reviewed
   - Data is accurate

2. **BC27 works with UNPOSTED purchase documents**
   - Custom API pages expose unposted Purchase Header
   - Documents from eRačun are unposted
   - Ready for transfer to BC17

3. **All target documents are UNPOSTED**
   - Standard BC API creates unposted documents
   - Users review before posting
   - Maintains control and audit trail

4. **No posting happens during sync**
   - Sync only creates documents
   - Users post manually after review
   - Proper workflow maintained

### What This Means

**BC17 Users**:
- Create and post sales invoices normally
- Sync automatically sends to BC27
- BC27 receives as unposted purchase docs
- BC27 users review and post there

**BC27 Users**:
- Receive eRačun as unposted purchase invoice
- Review in BC27 (but don't post there)
- Sync sends to BC17
- BC17 users review and post there

---

## Code Verification

### BC27 Purchase Doc Sync (Sending Unposted Docs)

**Source**: `KelteksAPIIntegrationBC27/src/Codeunits/KLTPurchaseDocSync.Codeunit.al`

```al
procedure SyncPurchaseInvoice(var PurchHeader: Record "Purchase Header"): Boolean
```

**Input**: `Purchase Header` record (unposted document type = Invoice)
**Builds JSON**: From unposted purchase data
**POSTs to**: `/api/v2.0/companies(...)/purchaseInvoices` (BC17)
**Result**: Creates unposted purchase invoice in BC17

✅ **Verified**: Works with unposted documents

### BC17 Sales Doc Sync (Sending Posted Docs)

**Source**: `KelteksAPIIntegrationBC17/src/Codeunits/KLTSalesDocSync.Codeunit.al`

```al
procedure SyncPostedSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"): Boolean
```

**Input**: `Sales Invoice Header` record (posted)
**Builds JSON**: From posted sales data
**POSTs to**: `/api/v2.0/companies(...)/purchaseInvoices` (BC27)
**Result**: Creates unposted purchase invoice in BC27

✅ **Verified**: Works with posted documents

---

## Workflow Examples

### Example 1: BC17 Sales → BC27 Purchase

1. **BC17**: User creates sales invoice, posts it
2. **BC17**: Sync picks up posted sales invoice (SI-001)
3. **BC17**: Builds JSON, POSTs to BC27
4. **BC27**: Receives JSON, creates unposted purchase invoice (PI-BC17-001)
5. **BC27**: User reviews PI-BC17-001
6. **BC27**: User posts if correct
7. **BC27**: User sends eRačun to customer

### Example 2: BC27 eRačun → BC17 Purchase

1. **BC27**: Receives eRačun from vendor (unposted PI-ER-001)
2. **BC27**: User reviews but does NOT post
3. **BC27**: Sync picks up unposted purchase invoice (PI-ER-001)
4. **BC27**: Builds JSON, POSTs to BC17
5. **BC17**: Receives JSON, creates unposted purchase invoice (PI-BC27-001)
6. **BC17**: User reviews PI-BC27-001
7. **BC17**: User gets receipt lines if goods received
8. **BC17**: User posts purchase invoice

---

## No Changes Needed ✅

The current implementation is **100% CORRECT** for the described workflow:

1. ✅ BC17 API pages expose posted sales documents
2. ✅ BC27 API pages expose unposted purchase documents
3. ✅ Sync creates unposted documents in target
4. ✅ Users review and post manually
5. ✅ Proper separation of concerns
6. ✅ Audit trail maintained

---

## Summary Table

| Aspect | BC17 | BC27 |
|--------|------|------|
| **Source Data** | Posted sales documents | Unposted purchase documents |
| **API Page Source** | Sales Invoice Header (posted) | Purchase Header (unposted) |
| **Sync Reads** | Posted tables | Unposted tables |
| **Target Creates** | Unposted purchase docs in BC27 | Unposted purchase docs in BC17 |
| **User Action** | Review & post in BC27 | Review & post in BC17 |
| **eRačun** | N/A | Sent after posting in BC27 |

---

## Conclusion

✅ **Implementation is CORRECT** as-is for the described workflow.

No code changes needed - the implementation already:
- Reads posted sales documents from BC17
- Reads unposted purchase documents from BC27
- Creates unposted purchase documents in target
- Maintains proper review workflow

**Status**: ✅ VERIFIED AND APPROVED

---

*Document created: 2025-11-28*  
*Verification: Complete*  
*Action required: None - implementation correct*
