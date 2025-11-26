# Copilot Working Guide - Kelteks API Integration Project

## Project Overview

**Client**: Kelteks  
**Purpose**: Bidirectional document synchronization between BC v17 and BC v27 for Fiskalizacija 2.0 (eRačun) compliance  
**Architecture**: Split into two separate AL extensions (one per BC version)  

## Quick Reference

### Object ID Ranges
- **BC17 Extension**: 50100-50149  
- **BC27 Extension**: 50150-50199  

### Document Flow
```
BC v17 (Source)          →  BC v27 (Target)
Posted Sales Invoice     →  Sales Invoice (Unposted)
Posted Sales Credit Memo →  Sales Credit Memo (Unposted)

BC v27 (Source)          →  BC v17 (Target)
Purchase Invoice (Unp.)  →  Purchase Invoice (Unposted)
Purchase Credit Memo     →  Purchase Credit Memo (Unposted)
```

### Authentication Methods Supported
1. **Basic Authentication** (Default/Recommended for on-premise) - Username/Password over HTTPS
2. **OAuth 2.0** (Cloud/Hybrid) - Azure AD token-based
3. **Windows Authentication** (Same domain) - NTLM/Kerberos integrated
4. **Certificate Authentication** (High security) - Mutual TLS with client certificates

## Project Structure

### BC17 Extension (`KelteksAPIIntegrationBC17/`)
```
src/
├── Tables/              (3) Config, Sync Log, Queue
├── Enums/               (6) Doc Type, Status, Error Category, Direction, Auth Method, Deployment Type
├── Codeunits/           (6) Auth, Helper, Sales Sync, Purchase Sync, Validator, Engine
├── Pages/               (7) Config, Log, Queue, 2 FactBoxes, 2 Extensions
└── PermissionSet        (1) Full access control
```

### BC27 Extension (`KelteksAPIIntegrationBC27/`)
Same structure with mirrored object IDs (50150-50199)

## Key Technical Details

### API Endpoints (Standard BC v2.0 - Built-in)
- `POST /api/v2.0/companies({id})/salesInvoices`
- `POST /api/v2.0/companies({id})/salesCreditMemos`
- `POST /api/v2.0/companies({id})/purchaseInvoices`
- `POST /api/v2.0/companies({id})/purchaseCreditMemos`

### Error Handling
- Uses standard BC **Error Message** table (Table 700) - NOT custom error tables
- 5 error categories: API, Validation, Business, Auth, Master Data
- Retry logic: Exponential backoff (1→2→4→8 min, max 3 attempts)
- Email notifications for critical failures (>25% error rate)

### Performance Targets
- < 5 seconds per document
- 100 documents per 15-minute cycle
- < 30 minutes end-to-end latency
- Token caching: 55 minutes (OAuth 2.0)

## Common Tasks

### Adding New Features
1. Determine which extension(s) need changes (BC17, BC27, or both)
2. Use correct object ID range
3. Update permission set if adding new objects
4. Document changes in relevant MD files
5. Test in both directions if bidirectional feature

### Modifying Authentication
- **Codeunit 50100 (BC17)** or **50150 (BC27)** handles all auth methods
- Configuration table stores credentials with proper masking
- Pages show/hide fields dynamically based on auth method enum
- Always validate HTTPS requirement for Basic Auth

### Troubleshooting Steps
1. Check **KLT Document Sync Log** page for sync history
2. Drill down to **Error Messages** (Table 700) for details
3. Review **KLT API Configuration** for connection settings
4. Use **Test Connection** action to verify setup
5. Check **KLT Sync Queue** for pending/failed items

## Documentation Files

### User-Facing
- `QUICKSTART-ONPREMISE.md` - **START HERE** - 15-20 min Basic Auth setup
- `README.md` (per extension) - Complete user guides
- `SETUP-*.md` (4 per extension) - Auth-specific detailed guides

### Technical
- `TECHNICAL.md` - Architecture and API specs
- `TROUBLESHOOTING.md` - Common issues and solutions
- `OBJECTS.md` - Object inventory
- `ARCHITECTURE.md` - Why split, how it works

### Internal (this file)
- `COPILOT-GUIDE.md` - Quick reference for Copilot agents

## Code Patterns

### Singleton Configuration
```al
procedure GetInstance()
begin
    if not Get() then begin
        Init();
        Insert();
    end;
end;
```

### Authentication Header Injection
```al
case "Authentication Method" of
    "Authentication Method"::OAuth:
        Headers.Add('Authorization', 'Bearer ' + GetAccessToken());
    "Authentication Method"::Basic:
        Headers.Add('Authorization', 'Basic ' + Base64Encode(Username + ':' + Password));
    "Authentication Method"::Windows:
        Client.UseDefaultCredentials(true);
    "Authentication Method"::Certificate:
        Client.AddCertificate(GetCertificate());
end;
```

### Error Logging Pattern
```al
SyncLog.Init();
SyncLog."Entry No." := GetNextEntryNo();
Sync Log."Document Type" := DocType;
SyncLog.Status := SyncLog.Status::Failed;
SyncLog."Error Message" := GetLastErrorText();
SyncLog.Insert();

// Also log to Error Message table (Table 700)
ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, GetLastErrorText());
```

## Important Constraints

### What NOT to Change
- Object ID ranges (already allocated)
- Standard BC API endpoints (built-in, don't customize)
- Error Message table structure (standard BC table)
- Core document flow direction

### Security Requirements
- HTTPS mandatory for Basic Auth
- Credentials always masked (ExtendedDatatype::Masked)
- No sensitive data in logs
- TLS 1.2+ for all communications

### Business Rules
- Item tracking NOT supported (out of scope)
- No automatic posting in target systems
- Prepayments handled manually
- No historical document migration
- 15-minute minimum sync interval

## Testing Checklist

Before marking as complete:
- [ ] Connection test passes for all 4 auth methods
- [ ] Manual sync works (BC17 sales → BC27, BC27 purchase → BC17)
- [ ] Automatic sync via job queue functional
- [ ] Error logging to Error Message table works
- [ ] Retry logic triggers correctly
- [ ] FactBoxes display statistics accurately
- [ ] Page extensions show correct status
- [ ] All documentation files updated
- [ ] No placeholders or TODOs remain in code

## Current Status

**Phase**: ✅ Complete implementation in progress  
**Authentication**: All 4 methods need full implementation  
**Codeunits**: BC17 has OAuth only, BC27 has none - need all 12 codeunits  
**Pages**: ✅ Complete (14 total)  
**Documentation**: ✅ Comprehensive (118 KB)  
**Next Steps**: Implement remaining auth methods + create all missing codeunits  

## Quick Commands

```bash
# Find all AL files
find . -name "*.al" -type f

# Find TODOs/placeholders
grep -r "TODO\|PLACEHOLDER" --include="*.al"

# Count objects by type
find KelteksAPIIntegrationBC17/src -name "*.al" | wc -l
find KelteksAPIIntegrationBC27/src -name "*.al" | wc -l

# Check documentation files
ls -lh *.md Kelteks*/**.md

# View specific codeunit
cat KelteksAPIIntegrationBC17/src/Codeunits/KLTAPIAuthBC17.Codeunit.al
```

## Notes for Future Copilot Agents

1. **Always check object ID range** before creating new objects
2. **Both extensions need parallel changes** for bidirectional features
3. **Test connection before enabling sync** - use Test Connection action
4. **Error Message table (700) is standard BC** - don't try to modify it
5. **Basic Auth is default** for on-premise (simplest setup)
6. **OAuth token caching is critical** for performance (55 min lifetime)
7. **Batch size default is 100** - configurable but tested at this level
8. **15-minute sync interval** is minimum recommended (performance)
9. **Master data must exist** in both environments before sync
10. **No force push** - AL-Go deployment handles versioning

## Contact Information

**Consultant**: Ana Šetka  
**Client**: Kelteks  
**JIRA**: ZGBCSKELTE-54  
**Requestor**: Miroslav Gjurinski  

---

*This guide is for Copilot agents working on this project. Keep it updated as the project evolves.*
