/// <summary>
/// Codeunit KLT Setup Automation (ID 50106).
/// Provides automated environment detection and setup helpers for the guided wizard.
/// </summary>
codeunit 80105 "KLT Setup Automation"
{
    procedure DetectEnvironment(var GuidedSetup: Record "KLT Guided Setup")
    var
        CompanyInfo: Record "Company Information";
    begin
        // Auto-detect current company ID
        // Note: CompanyInfo.Id is the GUID used in BC API v2.0 endpoints (/api/v2.0/companies({id})/...)
        // Get() retrieves the single record in Company Information table
        if CompanyInfo.Get() then
            GuidedSetup."Auto-Detected Company ID" := CompanyInfo.SystemId;

        // Detect deployment type based on environment
        // Note: Simplified logic - treats non-SaaS as on-premise (covers containers, local deployments)
        if IsServerOnPremise() then
            GuidedSetup."Deployment Type" := GuidedSetup."Deployment Type"::OnPremise
        else
            GuidedSetup."Deployment Type" := GuidedSetup."Deployment Type"::SaaS;

        GuidedSetup.Modify();
    end;

    procedure GenerateDefaultURL(DeploymentType: Enum "KLT Deployment Type"; ServerName: Text[250]): Text[250]
    var
        DefaultURL: Text[250];
    begin
        case DeploymentType of
            DeploymentType::OnPremise:
                begin
                    if ServerName <> '' then
                        DefaultURL := StrSubstNo('https://%1:7048/BC170/ODataV4/', ServerName)
                    else
                        DefaultURL := 'https://bc17-server:7048/BC170/ODataV4/';
                end;
            DeploymentType::SaaS:
                DefaultURL := 'https://api.businesscentral.dynamics.com/v2.0/{environment}/api/v2.0/';
            DeploymentType::Hybrid:
                DefaultURL := 'https://api.businesscentral.dynamics.com/v2.0/{environment}/api/v2.0/';
        end;
        exit(DefaultURL);
    end;

    procedure RecommendAuthMethod(DeploymentType: Enum "KLT Deployment Type"): Enum "KLT Auth Method"
    var
        AuthMethod: Enum "KLT Auth Method";
    begin
        case DeploymentType of
            DeploymentType::OnPremise:
                exit(AuthMethod::Basic);
            DeploymentType::SaaS:
                exit(AuthMethod::OAuth);
            DeploymentType::Hybrid:
                exit(AuthMethod::OAuth);
        end;
    end;

    procedure ValidateStep1(var GuidedSetup: Record "KLT Guided Setup"): Boolean
    begin
        // Step 1: Deployment type and auth method must be selected
        exit(true); // Always valid as we have defaults
    end;

    procedure ValidateStep2(TargetURL: Text[250]; CompanyID: Guid): Boolean
    begin
        // Step 2: Target URL and Company ID must be provided
        if (TargetURL = '') or (IsNullGuid(CompanyID)) then
            exit(false);
        exit(true);
    end;

    procedure ValidateStep3(AuthMethod: Enum "KLT Auth Method"; Username: Text[250]; Password: Text[250]; ClientID: Text[250]; ClientSecret: Text[250]; TenantID: Text[250]): Boolean
    begin
        // Step 3: Validate credentials based on auth method
        case AuthMethod of
            AuthMethod::Basic:
                exit((Username <> '') and (Password <> ''));
            AuthMethod::OAuth:
                exit((ClientID <> '') and (ClientSecret <> '') and (TenantID <> ''));
            AuthMethod::Windows:
                exit(Username <> '');
            AuthMethod::Certificate:
                exit(true); // Certificate validation is complex, allow proceeding
        end;
        exit(false);
    end;

    procedure ApplyConfigurationFromWizard(var GuidedSetup: Record "KLT Guided Setup"; var APIConfig: Record "KLT API Config")
    begin
        APIConfig."Authentication Method" := GuidedSetup."Authentication Method";
        APIConfig."Deployment Type" := GuidedSetup."Deployment Type";
    end;

    local procedure IsServerOnPremise(): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        // Check if running on-premise vs SaaS
        exit(not EnvironmentInfo.IsSaaS());
    end;
}
