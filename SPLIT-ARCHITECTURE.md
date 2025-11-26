# Split Architecture Implementation

## Overview

The Kelteks API Integration has been **split into two separate Business Central extensions** as requested:

1. **KelteksAPIIntegrationBC17** (Object IDs: 50100-50149)
2. **KelteksAPIIntegrationBC27** (Object IDs: 50150-50199)

## Why Split?

### Benefits
- **Simplified Deployment**: Each environment only installs the extension it needs
- **Reduced Complexity**: Each app contains only relevant functionality
- **Better Security**: Each environment only has outbound sync capabilities
- **Independent Updates**: Extensions can be updated independently
- **Clear Separation**: BC17 doesn't need BC27 sync logic and vice versa

### Architecture Before (Single App)
```
KelteksAPIIntegration (50100-50149)
├── Connects to both BC17 and BC27
├── Contains all sync logic (bidirectional)
├── Installed on both environments
└── Complex configuration with both endpoints
```

### Architecture After (Split Apps)
```
BC17 Environment:                      BC27 Environment:
KelteksAPIIntegrationBC17             KelteksAPIIntegrationBC27
├── Object IDs: 50100-50149           ├── Object IDs: 50150-50199
├── Connects to: BC27 only            ├── Connects to: BC17 only
├── Outbound: Sales docs → BC27       ├── Inbound: Sales docs ← BC17
├── Inbound: Purchase docs ← BC27     ├── Outbound: Purchase docs → BC17
└── Simple config (BC27 endpoint)     └── Simple config (BC17 endpoint)
```

## What Changed

### BC17 Extension
**File**: `KelteksAPIIntegrationBC17/`
- **Configuration Table** (50100): Stores BC27 connection details only
- **Enums** (50100-50103): Document types, sync status, error categories, direction
- **Sync Tables** (50101-50103): Sync log, errors, queue
- **Authentication** (Codeunit 50100): OAuth for BC27 only
- **Functionality**: 
  - Send sales invoices/credit memos to BC27
  - Receive purchase invoices/credit memos from BC27

### BC27 Extension
**File**: `KelteksAPIIntegrationBC27/`
- **Configuration Table** (50150): Stores BC17 connection details only
- **Enums** (50150-50153): Document types, sync status, error categories, direction
- **Sync Tables** (50151-50153): Sync log, errors, queue
- **Authentication** (Codeunit 50150): OAuth for BC17 only
- **Functionality**:
  - Receive sales invoices/credit memos from BC17
  - Send purchase invoices/credit memos to BC17

### Object ID Allocation

| Component | BC17 Range | BC27 Range |
|-----------|-----------|-----------|
| Tables | 50100-50149 | 50150-50199 |
| Codeunits | 50100-50149 | 50150-50199 |
| Pages | 50100-50149 | 50150-50199 |
| Enums | 50100-50103 | 50150-50153 |

## Installation

### BC17 Environment
1. Install **KelteksAPIIntegrationBC17.app**
2. Configure BC27 connection details
3. Enable synchronization

### BC27 Environment
1. Install **KelteksAPIIntegrationBC27.app**
2. Configure BC17 connection details
3. Enable synchronization

## Configuration Simplified

### Before (Complex - Both Endpoints in One App)
```
API Configuration:
├── BC17 Base URL
├── BC17 Company ID
├── BC17 OAuth Credentials
├── BC27 Base URL
├── BC27 Company ID
└── BC27 OAuth Credentials
```

### After (Simple - One Endpoint Per App)

**In BC17**:
```
API Configuration BC17:
├── BC27 Base URL
├── BC27 Company ID
└── BC27 OAuth Credentials
```

**In BC27**:
```
API Configuration BC27:
├── BC17 Base URL
├── BC17 Company ID
└── BC17 OAuth Credentials
```

## Document Flow Remains the Same

```
BC v17 (KelteksAPIIntegrationBC17)    BC v27 (KelteksAPIIntegrationBC27)
┌──────────────────────────┐          ┌──────────────────────────┐
│ Posted Sales Invoice     │─────────>│ Sales Invoice (Unposted) │
│ Posted Sales Credit Memo │─────────>│ Sales Cr. Memo (Unposted)│
│                          │          │                          │
│ Purchase Invoice (Unp.)  │<─────────│ Purchase Invoice (Unp.)  │
│ Purchase Cr. Memo (Unp.) │<─────────│ Purchase Cr. Memo (Unp.) │
└──────────────────────────┘          └──────────────────────────┘
```

## Key Features Maintained

✅ OAuth 2.0 authentication (simplified - one target per app)  
✅ Incremental sync (modification timestamps)  
✅ Error handling with retry (exponential backoff)  
✅ Duplicate prevention (External Document No.)  
✅ Comprehensive logging (per environment)  
✅ Monitoring and statistics  
✅ Security (masked credentials, TLS 1.2+)  

## Migration Path

If upgrading from the combined extension:

1. **Export** configuration from old extension
2. **Uninstall** old `KelteksAPIIntegration` from both environments
3. **Install** `KelteksAPIIntegrationBC17` on BC v17
4. **Install** `KelteksAPIIntegrationBC27` on BC v27
5. **Configure** each extension with appropriate target endpoint
6. **Test** connections in both environments
7. **Enable** synchronization

**Note**: Sync history will not be migrated. Fresh start recommended.

## Benefits Realized

### For BC17
- **Smaller App**: Only contains sales outbound + purchase inbound logic
- **Simpler Config**: Only needs to know about BC27
- **Faster Deployment**: Fewer objects to install
- **Clearer Purpose**: Sales exporter, Purchase importer

### For BC27
- **Smaller App**: Only contains purchase outbound + sales inbound logic
- **Simpler Config**: Only needs to know about BC17
- **Faster Deployment**: Fewer objects to install
- **Clearer Purpose**: Purchase exporter, Sales importer

### For Administrators
- **Easier Troubleshooting**: Clear separation of concerns
- **Independent Updates**: Update BC17 or BC27 extension separately
- **Better Monitoring**: Environment-specific logs
- **Simpler Permissions**: Environment-specific permission sets

## Status

✅ **BC17 Extension Created** - Basic structure with config and auth  
✅ **BC27 Extension Created** - Basic structure with config and auth  
✅ **Object ID Ranges Allocated** - No conflicts  
✅ **AL-Go Settings Updated** - Both apps registered  
✅ **Documentation Created** - README-SPLIT.md with full details  

**Next Steps**: Complete the codeunits, pages, and page extensions for both apps

---

**Created**: 2025-11-26  
**Reason**: User request to split into two apps (BC17 and BC27)  
**Benefits**: Simplified deployment, clearer separation, independent updates
