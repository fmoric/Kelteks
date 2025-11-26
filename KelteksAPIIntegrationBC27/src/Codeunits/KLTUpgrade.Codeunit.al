/// <summary>
/// Upgrade codeunit for migrating from v1.0 (BC17) to v2.0 (BC27)
/// Handles data migration and schema synchronization
/// </summary>
codeunit 50106 "KLT Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    begin
        // No database-level changes needed
    end;

    trigger OnUpgradePerCompany()
    begin
        UpgradeAPIConfig();
        UpgradeSyncLog();
        // Note: Sync Queue is NOT migrated as entries are environment-specific
    end;

    local procedure UpgradeAPIConfig()
    var
        APIConfig: Record "KLT API Config";
    begin
        // Configuration data will be preserved automatically during upgrade
        // The "Purchase No. Series" field exists in both versions (with ObsoleteState in v2.0)
        // so no manual migration needed
        
        if APIConfig.Get('') then begin
            // Ensure default values for new version
            if APIConfig."Enable Sync" then begin
                // User had sync enabled, keep it enabled
                APIConfig.Modify(false);
            end;
        end;
    end;

    local procedure UpgradeSyncLog()
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        // Sync log data will be preserved automatically
        // Table structure is identical between v1.0 and v2.0
        
        // Optional: Clean up old logs if needed
        SyncLog.SetFilter("Created DateTime", '<%1', CalcDate('<-1Y>', Today()));
        if not SyncLog.IsEmpty() then begin
            // Option to archive or delete old logs
            // For now, we keep all logs for historical reference
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure OnGetPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetKLTUpgradeTag());
    end;

    local procedure GetKLTUpgradeTag(): Code[250]
    begin
        exit('KLT-API-UPGRADE-V2.0-20251126');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure OnGetPerDatabaseUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        // No database-level upgrade tags needed
    end;
}
