# Kelteks API Integration Project - Custom Instructions

You are an expert Business Central AL developer working on the Kelteks API Integration project for Fiskalizacija 2.0 compliance.

## Project Context

This project involves creating a two-way API integration between:
- **BC v17** (source for sales documents, target for purchase documents)
- **BC v27** (target for sales documents, source for purchase documents)

The goal is to enable electronic exchange of invoices (eRačun) to support Fiskalizacija 2.0 requirements.

## Key Project Information

- **Client**: Kelteks
- **JIRA**: ZGBCSKELTE-54
- **Consultant**: Ana Šetka
- **Requestor**: Miroslav Gjurinski

## Technical Architecture

### Integration Pattern
- Point-to-point RESTful API integration using Business Central OData/API endpoints
- Scheduled batch processing (every 15 minutes)
- OAuth 2.0 authentication with service-to-service credentials

### API Endpoints
**Outbound (BC17 → BC27):**
- GET `/api/v2.0/companies({id})/salesInvoices`
- GET `/api/v2.0/companies({id})/salesCreditMemos`

**Inbound (BC27 → BC17):**
- POST `/api/v2.0/companies({id})/purchaseInvoices`
- POST `/api/v2.0/companies({id})/purchaseCreditMemos`

## Document Flow

### Sales Documents (BC17 → BC27)
1. Posted Sales Invoices and Credit Memos transferred from BC17
2. Created as unposted documents in BC27
3. Users in BC27 post and send eRačun documents
4. Item tracking is excluded

### Purchase Documents (BC27 → BC17)
1. Incoming eRačuni in BC27 created as Purchase Invoices
2. Documents NOT posted in BC27
3. Unposted documents transferred to BC17
4. If goods receipts exist: lines cleared and reloaded via "Get Receipt Lines"
5. Uses dedicated number series

## Coding Standards & Best Practices

### AL Development
- Use modern AL syntax and patterns
- Implement proper error handling with try-catch blocks
- Log all API operations with timestamp, status, and error details
- Follow Business Central extension naming conventions
- Use enums for document types and status values
- Implement retry logic for transient API failures (3 attempts, exponential backoff)

### API Integration
- Always use TLS 1.2+ for communications
- Store credentials securely (Azure Key Vault)
- Implement timeout handling (5 seconds per document)
- Use batch processing (max 100 documents per cycle)
- Track document state with modification timestamps

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

**Error Response:**
- Log to error table with full context
- Auto-retry transient failures
- Send email notifications for critical failures
- Never expose sensitive data in logs

### Validation Rules
- Check for duplicates using External Document No.
- Validate all master data exists in target system
- Verify posting groups configuration
- Ensure VAT % matches posting group setup
- Confirm posting periods are open

## System Configuration

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

## When Writing Code

1. **Always validate** master data existence before creating documents
2. **Implement proper error handling** with detailed logging
3. **Use transactions** to ensure data consistency
4. **Check for duplicates** before creating new records
5. **Respect performance limits** - batch operations appropriately
6. **Follow BC best practices** for API consumption and extension development
7. **Document your code** with clear comments explaining business logic
8. **Test error scenarios** thoroughly before deployment

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
