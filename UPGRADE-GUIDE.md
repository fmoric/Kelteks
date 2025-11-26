# Upgrade Guide: BC17 App (v1.0) to BC27 App (v2.0)

## Overview

This guide explains how to upgrade from the **Kelteks API Integration v1.0** (BC17 app) to **v2.0** (BC27 app).

**Important**: The apps have been aligned to support direct upgrade:
- ✅ Same App ID (GUID): `8a5e1b2c-3d4e-5f6a-7b8c-9d0e1f2a3b4c`
- ✅ Same Object IDs (50100-50149)
- ✅ Same Table Names
- ✅ Compatible Schema
- ✅ Version numbering: v1.0 → v2.0

---

## Prerequisites

Before starting the upgrade:

1. **Platform Upgrade Required**
   - Your Business Central server must be upgraded from v17 to v27
   - Runtime upgrade: 7.0 → 14.0
   - This is a **platform upgrade first, then app upgrade**

2. **Backup**
   - Full database backup
   - Export current API configuration settings
   - Export sync logs (optional, for reference)

3. **Stop Sync Jobs**
   - Disable sync in API Configuration
   - Ensure all sync queue items are processed
   - Wait for all running jobs to complete

---

## Upgrade Path

### Option 1: Platform + App Upgrade (Recommended)

**Scenario**: Upgrading entire BC environment from v17 to v27

```
Step 1: Upgrade BC Platform
├─ Upgrade Business Central from v17 to v27
├─ Follow Microsoft's upgrade documentation
└─ Verify platform is v27

Step 2: Upgrade App
├─ App v1.0 automatically upgrades to v2.0
├─ Upgrade codeunit handles data migration
├─ Configuration data is preserved
└─ Sync logs are preserved
```

**Commands**:
```powershell
# After platform upgrade to BC27
Sync-NAVApp -ServerInstance BC27 -Name "Kelteks API Integration" -Version 2.0.0.0
Start-NAVAppDataUpgrade -ServerInstance BC27 -Name "Kelteks API Integration" -Version 2.0.0.0
```

### Option 2: Side-by-Side (Not Recommended)

**Scenario**: Running v1.0 in BC17 and v2.0 in BC27 separately

This is the original architecture where both apps work together. If this is your case, you don't need to "upgrade" - both apps continue to run independently.

---

## What Gets Upgraded

### ✅ Automatically Migrated

| Data | Migration | Notes |
|------|-----------|-------|
| API Configuration | ✅ Preserved | All settings maintained |
| Document Sync Log | ✅ Preserved | Historical data maintained |
| Enums | ✅ Compatible | Same structure and values |
| Tables | ✅ Compatible | Identical schema |

### ⚠️ Requires Attention

| Item | Action Required |
|------|-----------------|
| **Sync Queue** | Clear before upgrade - entries are environment-specific |
| **API Endpoints** | Verify target system URLs after upgrade |
| **Auth Credentials** | Re-test authentication after upgrade |

### ❌ Not Migrated

| Data | Reason |
|------|--------|
| Pending Queue Items | Environment-specific, clear before upgrade |
| Active Jobs | Must be stopped before upgrade |

---

## Step-by-Step Upgrade Process

### Phase 1: Pre-Upgrade (in BC17)

1. **Document Current Settings**
   ```al
   // Open API Configuration page
   // Screenshot or note all settings:
   - Target Base URL
   - Authentication Method
   - Company ID
   - Sync Interval
   - Batch Size
   ```

2. **Stop Synchronization**
   ```al
   // In API Configuration:
   Enable Sync = false
   ```

3. **Clear Sync Queue**
   ```al
   // Open Sync Queue page
   // Delete or process all pending items
   // Verify queue is empty
   ```

4. **Export Logs (Optional)**
   ```al
   // Export Document Sync Log to Excel for reference
   ```

### Phase 2: Platform Upgrade

5. **Upgrade BC Server**
   - Follow Microsoft's technical upgrade process
   - Upgrade BC v17 → BC v27
   - This includes database schema upgrade

6. **Verify Platform**
   ```powershell
   Get-NAVServerInstance BC27
   # Verify version is 27.x
   ```

### Phase 3: App Upgrade

7. **Sync New App Version**
   ```powershell
   Sync-NAVApp -ServerInstance BC27 `
       -Name "Kelteks API Integration" `
       -Version 2.0.0.0
   ```

8. **Run Data Upgrade**
   ```powershell
   Start-NAVAppDataUpgrade -ServerInstance BC27 `
       -Name "Kelteks API Integration" `
       -Version 2.0.0.0
   ```

9. **Verify Upgrade**
   ```powershell
   Get-NAVAppInfo -ServerInstance BC27 `
       -Name "Kelteks API Integration"
   # Should show version 2.0.0.0
   ```

### Phase 4: Post-Upgrade Validation

10. **Verify Configuration**
    - Open API Configuration page
    - Verify all settings were preserved
    - Check authentication credentials

11. **Test API Connection**
    ```al
    // Use "Test Connection" action in API Configuration
    // Verify authentication works
    ```

12. **Review Sync Logs**
    ```al
    // Open Document Sync Log
    // Verify historical data is present
    // Check for any upgrade-related entries
    ```

13. **Re-enable Sync**
    ```al
    // In API Configuration:
    Enable Sync = true
    ```

14. **Monitor First Sync Cycle**
    - Watch for any errors
    - Verify documents sync correctly
    - Check both inbound and outbound flows

---

## Compatibility Matrix

| Feature | v1.0 (BC17) | v2.0 (BC27) | Compatible? |
|---------|-------------|-------------|-------------|
| Platform | BC v17 | BC v27 | ⚠️ Requires platform upgrade |
| Runtime | 7.0 | 14.0 | ⚠️ Auto-upgraded |
| App ID | Same GUID | Same GUID | ✅ Yes |
| Object IDs | 50100-50149 | 50100-50149 | ✅ Yes |
| Table Schema | Standard | Standard | ✅ Yes |
| Enums | Standard | Standard | ✅ Yes |
| Interfaces | ❌ Not supported | ✅ Supported (not yet used) | ✅ Yes* |

*Interfaces are defined in v2.0 but not yet implemented, so no breaking change

---

## Upgrade Codeunit Details

The upgrade is handled by codeunit 50106 "KLT Upgrade":

```al
codeunit 50106 "KLT Upgrade"
{
    Subtype = Upgrade;
    
    // Handles:
    // - Config data preservation
    // - Sync log preservation
    // - Upgrade tag management
}
```

**What it does**:
1. Preserves API Configuration settings
2. Maintains Document Sync Log history
3. Sets upgrade tag for tracking
4. Does NOT migrate Sync Queue (by design)

---

## Troubleshooting

### Issue: Upgrade Fails to Start

**Symptoms**: Data upgrade doesn't start after Sync-NAVApp

**Solution**:
```powershell
# Check app status
Get-NAVAppInfo -ServerInstance BC27 -Name "Kelteks API Integration"

# Force sync if needed
Sync-NAVApp -ServerInstance BC27 -Name "Kelteks API Integration" -Version 2.0.0.0 -Force

# Retry upgrade
Start-NAVAppDataUpgrade -ServerInstance BC27 -Name "Kelteks API Integration" -Version 2.0.0.0
```

### Issue: Configuration Lost

**Symptoms**: API Configuration is empty after upgrade

**Solution**:
1. Check if singleton record exists:
   ```sql
   SELECT * FROM [KLT API Config] WHERE [Primary Key] = ''
   ```
2. If missing, re-enter configuration manually
3. Use exported settings from pre-upgrade step

### Issue: Sync Not Working

**Symptoms**: Documents not syncing after upgrade

**Checklist**:
- [ ] Is "Enable Sync" turned on?
- [ ] Are authentication credentials correct?
- [ ] Is target system accessible?
- [ ] Test connection button works?
- [ ] Check sync log for errors

### Issue: Historical Logs Missing

**Symptoms**: Old sync log entries not visible

**Solution**:
```sql
-- Verify data is in table
SELECT COUNT(*) FROM [KLT Document Sync Log]

-- Check date filters on page
-- Ensure no filters are hiding old data
```

---

## Rollback Procedure

If upgrade fails and you need to rollback:

1. **Restore Database Backup**
   ```powershell
   # Restore BC17 database backup
   Restore-SqlDatabase -ServerInstance BC17 -Database "BC17-Backup"
   ```

2. **Reinstall v1.0**
   ```powershell
   # Publish v1.0 app
   Publish-NAVApp -ServerInstance BC17 -Path "Kelteks API Integration v1.0.app"
   
   # Install
   Install-NAVApp -ServerInstance BC17 -Name "Kelteks API Integration" -Version 1.0.0.0
   ```

3. **Restore Configuration**
   - Re-enter API settings from documentation
   - Re-enable sync

---

## Post-Upgrade Recommendations

1. **Monitor for 24-48 Hours**
   - Watch sync logs for errors
   - Check error threshold alerts
   - Verify document counts

2. **Update Documentation**
   - Update internal runbooks with v2.0
   - Note any configuration changes
   - Document upgrade date and team

3. **Train Users**
   - Notify users of upgrade
   - Highlight any UI changes (if any)
   - Provide support contact

---

## Additional Resources

- **Technical Details**: See `UPGRADE-TECHNICAL-ANALYSIS.md`
- **Architecture**: See `ARCHITECTURE.md`
- **Setup Guides**: See `SETUP-*.md` files in each app folder

---

## Support

For upgrade assistance:
- Technical issues: Check logs in Event Viewer
- Configuration help: Review `SETUP-OAUTH.md` or `SETUP-BASIC.md`
- Business logic: Consult Technical_Specification_Kelteks_API.md

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-26  
**Applies To**: Upgrade from v1.0 (BC17) to v2.0 (BC27)
