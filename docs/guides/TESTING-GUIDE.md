# Kelteks API Integration - Testing Guide

## Overview

This guide provides comprehensive testing procedures for the Kelteks API Integration project. All features are fully implemented and ready for testing.

## Pre-Testing Checklist

### BC17 Environment
- [ ] Extension installed and published
- [ ] Company Information configured
- [ ] Master data synchronized (Customers, Vendors, Items, etc.)
- [ ] Number series configured for purchase documents
- [ ] User permissions assigned (KELTEKS-API permission set)

### BC27 Environment
- [ ] Extension installed and published
- [ ] Company Information configured
- [ ] Master data synchronized
- [ ] Number series configured for purchase documents (if different from BC17)
- [ ] User permissions assigned

## Authentication Testing

### Test 1: OAuth 2.0 Authentication (Cloud/SaaS)

**Prerequisites:**
- Azure AD tenant access
- Registered application with Business Central API permissions
- Client ID and Client Secret available

**Steps:**
1. Open **KLT API Configuration** page
2. Set **Authentication Method** to `OAuth`
3. Fill in:
   - Target Tenant ID
   - Target Client ID
   - Target Client Secret
   - Target Base URL (cloud API endpoint)
   - Target Company ID
4. Click **Test Connection** action
5. Verify connection succeeds

**Expected Result:** ✅ Connection successful, token acquired and cached

**Common Issues:**
- Invalid Client Secret → Check Azure AD app registration
- Permissions missing → Grant API.ReadWrite.All permission
- Tenant ID wrong → Verify from Azure Portal

### Test 2: Basic Authentication (On-Premise)

**Prerequisites:**
- BC27 on-premise installation
- Service account with web services access
- HTTPS enabled on BC27

**Steps:**
1. Open **KLT API Configuration** page
2. Set **Authentication Method** to `Basic`
3. Fill in:
   - Target Username (e.g., `DOMAIN\ServiceAccount`)
   - Target Password
   - Target Base URL (on-premise URL with port 7048)
   - Target Company ID
4. Click **Test Connection** action
5. Verify connection succeeds

**Expected Result:** ✅ Connection successful with Basic auth header

**Common Issues:**
- HTTP instead of HTTPS → Error: Basic auth requires HTTPS
- Invalid credentials → Verify username/password
- Web Services Access not enabled → Check user permissions

### Test 3: Windows Authentication (On-Premise)

**Prerequisites:**
- Both BC17 and BC27 in same Windows domain
- Service account with domain permissions

**Steps:**
1. Open **KLT API Configuration** page
2. Set **Authentication Method** to `Windows`
3. Attempt to configure

**Expected Result:** ⚠️ Error message stating Windows auth not supported in BC17 runtime

**Note:** Windows authentication is not available in BC17 due to runtime limitations. Use OAuth or Basic instead.

### Test 4: Certificate Authentication (On-Premise)

**Prerequisites:**
- Client certificate installed on BC17 server
- Certificate thumbprint available

**Steps:**
1. Open **KLT API Configuration** page
2. Set **Authentication Method** to `Certificate`
3. Fill in Certificate Thumbprint
4. Attempt to test connection

**Expected Result:** ⚠️ Error message requesting manual certificate configuration

**Note:** Certificate authentication requires manual setup in BC17. Contact your administrator.

## Document Synchronization Testing

### Test 5: Sales Invoice Sync (BC17 → BC27)

**Setup:**
1. Create and post a sales invoice in BC17
2. Note the document number

**Steps:**
1. In BC17, open **Posted Sales Invoices**
2. Select the invoice
3. Click **Sync to BC27** action (or wait for scheduled sync)
4. Open **KLT Document Sync Log** page
5. Filter by document number
6. Verify status is **Completed**

**Verification in BC27:**
1. Open **Purchase Invoices** (unposted)
2. Search for invoice with matching External Document No.
3. Verify:
   - Vendor matches customer from BC17
   - Amounts match
   - Lines match
   - Document is **unposted**

**Expected Result:** ✅ Document created in BC27 as unposted purchase invoice

### Test 6: Sales Credit Memo Sync (BC17 → BC27)

**Setup:**
1. Create and post a sales credit memo in BC17
2. Note the document number

**Steps:**
1. In BC17, open **Posted Sales Credit Memos**
2. Select the credit memo
3. Click **Sync to BC27** action
4. Open **KLT Document Sync Log**
5. Verify status is **Completed**

**Verification in BC27:**
1. Open **Purchase Credit Memos** (unposted)
2. Find credit memo with matching External Document No.
3. Verify all fields match

**Expected Result:** ✅ Document created in BC27 as unposted purchase credit memo

### Test 7: Purchase Invoice Sync (BC27 → BC17)

**Setup:**
1. Create an unposted purchase invoice in BC27 (simulating incoming eRačun)
2. Fill in all required fields
3. Note the Vendor Invoice No.

**Steps:**
1. Run scheduled sync or trigger manually
2. In BC17, open **Purchase Invoices** (unposted)
3. Search for invoice with matching Vendor Invoice No.
4. Verify:
   - Vendor matches
   - Amounts match
   - Lines match
   - Document is **unposted**

**Expected Result:** ✅ Document created in BC17 as unposted purchase invoice

### Test 8: Purchase Credit Memo Sync (BC27 → BC17)

**Setup:**
1. Create an unposted purchase credit memo in BC27
2. Note the Vendor Cr. Memo No.

**Steps:**
1. Run scheduled sync
2. In BC17, open **Purchase Credit Memos** (unposted)
3. Find credit memo with matching Vendor Cr. Memo No.
4. Verify all fields match

**Expected Result:** ✅ Document created in BC17 as unposted purchase credit memo

## Error Handling Testing

### Test 9: Duplicate Detection

**Setup:**
1. Create and post a sales invoice in BC17
2. Sync it to BC27 successfully
3. Try to sync the same invoice again

**Steps:**
1. Select the already-synced invoice
2. Click **Sync to BC27**
3. Check **KLT Document Sync Log**

**Expected Result:** ✅ Error logged with "Duplicate" message, status = Failed

### Test 10: Missing Master Data

**Setup:**
1. Create a sales invoice in BC17 with customer "CUST001"
2. Ensure "CUST001" does NOT exist as a vendor in BC27

**Steps:**
1. Sync the invoice
2. Check sync log

**Expected Result:** ✅ Error logged with "Vendor CUST001 not found", status = Failed

### Test 11: Invalid Posting Period

**Setup:**
1. In BC27, set **Allow Posting From** to a future date in GL Setup
2. Create a purchase invoice in BC27 with posting date = today

**Steps:**
1. Sync to BC17
2. Check sync log

**Expected Result:** ✅ Error logged with "Posting Date is before allowed posting from date", status = Failed

## Retry Logic Testing

### Test 12: Automatic Retry with Exponential Backoff

**Setup:**
1. Create a scenario that will fail temporarily (e.g., temporarily block vendor)
2. Queue a sales invoice for sync

**Steps:**
1. Initial sync fails (status = Failed, Retry Count = 1)
2. Wait 1 minute (2^0 = 1 minute delay)
3. Retry occurs automatically
4. If still fails, Retry Count = 2, Next Retry Time = +2 minutes
5. Continue up to 3 retries

**Expected Result:** ✅ Retry logic executes with delays: 1m, 2m, 4m (then stops at 3 retries)

## Batch Processing Testing

### Test 13: Large Batch Sync

**Setup:**
1. Create and post 150 sales invoices in BC17
2. Set batch size to 100 in **KLT API Configuration**

**Steps:**
1. Queue all invoices for sync
2. Run scheduled sync
3. Check **KLT API Sync Queue** page

**Expected Result:** 
✅ First sync processes 100 invoices
✅ Second sync processes remaining 50 invoices

### Test 14: Priority Queue Processing

**Setup:**
1. Create sync queue entries with different priorities
   - Priority 1 (Highest)
   - Priority 5 (Normal)
   - Priority 10 (Lowest)

**Steps:**
1. Process sync queue
2. Observe processing order in sync log

**Expected Result:** ✅ Documents processed in priority order (1, then 5, then 10)

## Performance Testing

### Test 15: Single Document Sync Performance

**Setup:**
1. Create a typical sales invoice (5-10 lines)

**Steps:**
1. Record start time
2. Sync invoice
3. Record end time from sync log

**Expected Result:** ✅ Sync completes in < 5 seconds

### Test 16: Batch Performance

**Setup:**
1. Queue 100 sales invoices

**Steps:**
1. Run scheduled sync
2. Check total duration

**Expected Result:** ✅ 100 documents sync in < 10 minutes (average < 6 seconds each)

## Job Queue Testing

### Test 17: Scheduled Sync Execution

**Setup:**
1. Configure job queue entry:
   - Object Type = Codeunit
   - Object ID = 80106 (BC17) or 80154 (BC27)
   - Recurrence = Every 15 minutes

**Steps:**
1. Set job queue to Ready status
2. Wait for scheduled run
3. Check job queue log history
4. Verify sync executed

**Expected Result:** ✅ Job runs every 15 minutes, sync log shows automatic runs

## Guided Setup Wizard Testing

### Test 18: Complete Wizard Flow (On-Premise)

**Steps:**
1. Open **KLT Guided Setup Wizard**
2. **Step 1**: Verify Deployment Type auto-detected as "On-Premise"
3. Verify Auth Method recommended as "Basic"
4. Click **Next**
5. **Step 2**: Enter BC27 server name or use pre-filled URL
6. Enter Company ID
7. Click **Next**
8. **Step 3**: Enter username and password for Basic auth
9. Click **Next**
10. **Step 4**: Review configuration
11. Click **Test Connection**
12. Verify success message
13. Click **Next**
14. **Step 5**: Check "Enable Sync Immediately"
15. Click **Finish**

**Expected Result:** ✅ Configuration saved, wizard completes successfully

### Test 19: Wizard Validation

**Steps:**
1. Open wizard
2. Try to proceed from Step 2 without entering required fields
3. Verify error message

**Expected Result:** ✅ "Please fill in all required fields" error shown

## Monitoring and Logging Testing

### Test 20: Sync Log Review

**Steps:**
1. Open **KLT Document Sync Log** page
2. Filter by:
   - Status = Failed
   - Date range = Last 7 days
   - Document Type = Sales Invoice
3. Review error messages
4. Click **Retry** action on a failed entry

**Expected Result:** ✅ Failed entries visible, retry action works

### Test 21: Sync Statistics

**Steps:**
1. Open **KLT API Configuration** page
2. View FactBox showing sync statistics
3. Verify counts:
   - Total Pending
   - Total In Progress
   - Total Failed
   - Total Retrying

**Expected Result:** ✅ Statistics display correctly

## Edge Case Testing

### Test 22: Empty Lines Handling

**Setup:**
1. Create invoice with comment lines (Type = " ")

**Steps:**
1. Sync invoice
2. Verify comment lines transferred

**Expected Result:** ✅ Comment lines included in sync

### Test 23: Currency Handling

**Setup:**
1. Create invoice with non-LCY currency (EUR)

**Steps:**
1. Sync invoice
2. Verify currency code transferred

**Expected Result:** ✅ Currency code preserved in target document

### Test 24: Null/Empty Field Handling

**Setup:**
1. Create invoice with optional fields left blank

**Steps:**
1. Sync invoice
2. Verify no errors for blank optional fields

**Expected Result:** ✅ Optional fields handled correctly (blanks allowed)

## Regression Testing Checklist

After any code changes, run these critical tests:

- [ ] OAuth authentication still works
- [ ] Basic authentication still works
- [ ] Sales invoice sync (BC17 → BC27)
- [ ] Purchase invoice sync (BC27 → BC17)
- [ ] Duplicate detection prevents re-sync
- [ ] Retry logic executes correctly
- [ ] Job queue runs on schedule
- [ ] Error logging to Error Message table
- [ ] Guided Setup Wizard completes

## Test Results Template

```
Test #: _____
Test Name: ________________________________
Tester: __________________
Date: ___________
Environment: BC17 / BC27
Result: PASS / FAIL
Notes: _________________________________________
_________________________________________
```

## Known Limitations

1. **Windows Authentication**: Not supported in BC17 due to runtime limitations
2. **Certificate Authentication**: Requires manual certificate configuration in BC17
3. **Item Tracking**: Lot/Serial numbers are excluded from sync (per specification)
4. **Automatic Posting**: Documents created as unposted (manual review required)
5. **Attachments**: Document attachments not synchronized

## Support Contacts

- **Consultant**: Ana Šetka
- **Requestor**: Miroslav Gjurinski
- **JIRA Project**: ZGBCSKELTE-54

---

**Version**: 1.0  
**Last Updated**: 2025-11-27  
**Status**: Production Ready
