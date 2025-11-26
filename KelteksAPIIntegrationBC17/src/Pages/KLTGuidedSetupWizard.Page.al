/// <summary>
/// Page KLT Guided Setup Wizard (ID 50103).
/// Step-by-step wizard for quick and easy multi-application setup.
/// Automates environment detection and provides sensible defaults.
/// </summary>
page 50103 "KLT Guided Setup Wizard"
{
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Kelteks API Setup Wizard (BC17)';

    layout
    {
        area(Content)
        {
            group(BannerGroup)
            {
                Editable = false;
                Visible = TopBannerVisible;
                field(MediaResourcesStandard; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                }
            }

            group(Step1)
            {
                Caption = '';
                Visible = Step = 1;

                group(Step1Intro)
                {
                    Caption = 'Welcome to Kelteks API Integration Setup';
                    InstructionalText = 'This wizard will guide you through setting up the API integration between BC17 and BC27 for Fiskalizacija 2.0 compliance. The wizard will auto-detect your environment and pre-fill settings with sensible defaults.';
                }

                group(Step1Content)
                {
                    Caption = 'Step 1: Choose Deployment Type';

                    field("Deployment Type"; DeploymentType)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Select your deployment type. Auto-detected based on your environment.';
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            UpdateRecommendedAuth();
                            UpdateDefaultURL();
                        end;
                    }

                    field("Authentication Method"; AuthMethod)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Select authentication method. Recommended based on deployment type.';
                        ShowMandatory = true;
                    }

                    group(DeploymentInfo)
                    {
                        Caption = 'Deployment Information';
                        InstructionalText = '';

                        field(DeploymentInfoText; DeploymentInfoTxt)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            ShowCaption = false;
                            MultiLine = true;
                            Style = Favorable;
                        }
                    }
                }
            }

            group(Step2)
            {
                Caption = '';
                Visible = Step = 2;

                group(Step2Intro)
                {
                    Caption = 'Step 2: Configure Target BC27 Connection';
                    InstructionalText = 'Specify the connection details for your BC27 environment. The wizard has pre-filled default values based on your deployment type.';
                }

                group(Step2Content)
                {
                    Caption = 'BC27 Connection Settings';

                    field("Target Base URL"; TargetBaseURL)
                    {
                        ApplicationArea = All;
                        Caption = 'BC27 Base URL';
                        ToolTip = 'Specifies the base URL for BC27. Pre-filled with recommended default.';
                        ShowMandatory = true;
                        ExtendedDatatype = URL;
                    }

                    field("Target Company ID"; TargetCompanyID)
                    {
                        ApplicationArea = All;
                        Caption = 'BC27 Company ID';
                        ToolTip = 'Specifies the Company GUID in BC27. Find this in Company Information.';
                        ShowMandatory = true;
                    }

                    field("Server Name Hint"; ServerNameHint)
                    {
                        ApplicationArea = All;
                        Caption = 'Server Name/IP (optional)';
                        ToolTip = 'For on-premise: Enter BC27 server name or IP to auto-generate URL';
                        Visible = DeploymentType = DeploymentType::OnPremise;

                        trigger OnValidate()
                        begin
                            UpdateDefaultURL();
                        end;
                    }

                    group(URLExamples)
                    {
                        Caption = 'URL Format Examples';
                        InstructionalText = '';

                        field(URLExamplesText; URLExamplesTxt)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            ShowCaption = false;
                            MultiLine = true;
                            Style = Subordinate;
                        }
                    }
                }
            }

            group(Step3)
            {
                Caption = '';
                Visible = Step = 3;

                group(Step3Intro)
                {
                    Caption = 'Step 3: Configure Authentication';
                    InstructionalText = 'Enter the credentials for connecting to BC27. Ensure you have a service account with appropriate permissions.';
                }

                group(Step3BasicAuth)
                {
                    Caption = 'Basic Authentication (On-Premise)';
                    Visible = AuthMethod = AuthMethod::Basic;

                    field("Basic Username"; BasicUsername)
                    {
                        ApplicationArea = All;
                        Caption = 'Username';
                        ToolTip = 'Service account username (e.g., DOMAIN\ServiceAccount or serviceaccount@domain.com)';
                        ShowMandatory = true;
                    }

                    field("Basic Password"; BasicPassword)
                    {
                        ApplicationArea = All;
                        Caption = 'Password';
                        ToolTip = 'Service account password';
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                    }
                }

                group(Step3OAuth)
                {
                    Caption = 'OAuth 2.0 Authentication (Cloud/SaaS)';
                    Visible = AuthMethod = AuthMethod::OAuth;

                    field("OAuth Tenant ID"; OAuthTenantID)
                    {
                        ApplicationArea = All;
                        Caption = 'Azure AD Tenant ID';
                        ToolTip = 'Your Azure AD Tenant ID';
                        ShowMandatory = true;
                    }

                    field("OAuth Client ID"; OAuthClientID)
                    {
                        ApplicationArea = All;
                        Caption = 'Azure AD Client ID';
                        ToolTip = 'Application (Client) ID from Azure AD app registration';
                        ShowMandatory = true;
                    }

                    field("OAuth Client Secret"; OAuthClientSecret)
                    {
                        ApplicationArea = All;
                        Caption = 'Client Secret';
                        ToolTip = 'Client secret from Azure AD app registration';
                        ShowMandatory = true;
                        ExtendedDatatype = Masked;
                    }
                }

                group(Step3Windows)
                {
                    Caption = 'Windows Authentication';
                    Visible = AuthMethod = AuthMethod::Windows;

                    field("Windows Username"; WindowsUsername)
                    {
                        ApplicationArea = All;
                        Caption = 'Username';
                        ToolTip = 'Domain username (e.g., DOMAIN\ServiceAccount)';
                        ShowMandatory = true;
                    }

                    field("Windows Domain"; WindowsDomain)
                    {
                        ApplicationArea = All;
                        Caption = 'Domain';
                        ToolTip = 'Windows domain name';
                    }
                }

                group(Step3Certificate)
                {
                    Caption = 'Certificate Authentication';
                    Visible = AuthMethod = AuthMethod::Certificate;

                    field("Certificate Name"; CertificateName)
                    {
                        ApplicationArea = All;
                        Caption = 'Certificate Name';
                        ToolTip = 'Name of the certificate for authentication';
                    }

                    field("Certificate Thumbprint"; CertificateThumbprint)
                    {
                        ApplicationArea = All;
                        Caption = 'Certificate Thumbprint';
                        ToolTip = 'Thumbprint of the certificate';
                    }

                    group(CertInfo)
                    {
                        Caption = 'Certificate Setup';
                        InstructionalText = 'Ensure the certificate is installed on the BC27 server and configured for mutual TLS authentication.';
                    }
                }
            }

            group(Step4)
            {
                Caption = '';
                Visible = Step = 4;

                group(Step4Intro)
                {
                    Caption = 'Step 4: Review and Test Configuration';
                    InstructionalText = 'Review your configuration settings and test the connection before completing the setup.';
                }

                group(Step4Review)
                {
                    Caption = 'Configuration Summary';

                    field("Review Deployment"; DeploymentType)
                    {
                        ApplicationArea = All;
                        Caption = 'Deployment Type';
                        Editable = false;
                    }

                    field("Review Auth"; AuthMethod)
                    {
                        ApplicationArea = All;
                        Caption = 'Authentication Method';
                        Editable = false;
                    }

                    field("Review URL"; TargetBaseURL)
                    {
                        ApplicationArea = All;
                        Caption = 'BC27 Base URL';
                        Editable = false;
                    }

                    field("Review Company"; TargetCompanyID)
                    {
                        ApplicationArea = All;
                        Caption = 'BC27 Company ID';
                        Editable = false;
                    }
                }

                group(Step4Actions)
                {
                    Caption = 'Test Connection';

                    field(ConnectionTestResult; ConnectionTestResultTxt)
                    {
                        ApplicationArea = All;
                        Caption = 'Connection Status';
                        Editable = false;
                        ShowCaption = false;
                        Style = Favorable;
                        StyleExpr = ConnectionTestSuccess;
                    }
                }
            }

            group(Step5)
            {
                Caption = '';
                Visible = Step = 5;

                group(Step5Intro)
                {
                    Caption = 'Setup Complete!';
                    InstructionalText = 'Your Kelteks API Integration is now configured. You can enable synchronization and configure the job queue for automatic sync.';
                }

                group(Step5Content)
                {
                    Caption = 'Next Steps';

                    field(NextStepsInfo; NextStepsTxt)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        MultiLine = true;
                        Style = Favorable;
                    }
                }

                group(Step5Options)
                {
                    Caption = 'Configuration Options';

                    field(EnableSync; EnableSyncOnCompletion)
                    {
                        ApplicationArea = All;
                        Caption = 'Enable Sync Immediately';
                        ToolTip = 'Enable synchronization after setup completion';
                    }

                    field(ConfigureJobQueue; ConfigureJobQueueOnCompletion)
                    {
                        ApplicationArea = All;
                        Caption = 'Configure Job Queue (15-minute interval)';
                        ToolTip = 'Automatically configure job queue for scheduled synchronization';
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Image = PreviousRecord;
                InFooterBar = true;
                Enabled = BackEnabled;

                trigger OnAction()
                begin
                    GoToStep(Step - 1);
                end;
            }

            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Image = NextRecord;
                InFooterBar = true;
                Enabled = NextEnabled;

                trigger OnAction()
                begin
                    if ValidateCurrentStep() then
                        GoToStep(Step + 1);
                end;
            }

            action(ActionTestConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Connection';
                Image = TestDatabase;
                InFooterBar = true;
                Visible = Step = 4;

                trigger OnAction()
                begin
                    TestConnection();
                end;
            }

            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                Image = Approve;
                InFooterBar = true;
                Enabled = FinishEnabled;

                trigger OnAction()
                begin
                    FinishSetup();
                end;
            }

            action(ActionCancel)
            {
                ApplicationArea = All;
                Caption = 'Cancel';
                Image = Cancel;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if Confirm('Are you sure you want to cancel the setup wizard?', false) then
                        CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    begin
        GuidedSetupRec.GetOrCreate();
        if GuidedSetupRec."Setup Complete" then
            GuidedSetupRec.ResetWizard();
        
        Step := GuidedSetupRec."Current Step";
        if Step = 0 then
            Step := 1;

        SetupAutomation.DetectEnvironment(GuidedSetupRec);
        DeploymentType := GuidedSetupRec."Deployment Type";
        AuthMethod := GuidedSetupRec."Authentication Method";
        
        UpdateRecommendedAuth();
        UpdateDefaultURL();
        UpdateButtonState();
        UpdateInfoTexts();
    end;

    var
        GuidedSetupRec: Record "KLT Guided Setup";
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        SetupAutomation: Codeunit "KLT Setup Automation";
        Step: Integer;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        TopBannerVisible: Boolean;
        DeploymentType: Enum "KLT Deployment Type";
        AuthMethod: Enum "KLT Auth Method";
        TargetBaseURL: Text[250];
        TargetCompanyID: Guid;
        ServerNameHint: Text[250];
        BasicUsername: Text[250];
        BasicPassword: Text[250];
        OAuthTenantID: Text[250];
        OAuthClientID: Text[250];
        OAuthClientSecret: Text[250];
        WindowsUsername: Text[250];
        WindowsDomain: Text[100];
        CertificateName: Text[250];
        CertificateThumbprint: Text[100];
        EnableSyncOnCompletion: Boolean;
        ConfigureJobQueueOnCompletion: Boolean;
        ConnectionTestSuccess: Boolean;
        DeploymentInfoTxt: Text;
        URLExamplesTxt: Text;
        ConnectionTestResultTxt: Text;
        NextStepsTxt: Text;

    local procedure GoToStep(NewStep: Integer)
    begin
        if (NewStep < 1) or (NewStep > 5) then
            exit;

        Step := NewStep;
        GuidedSetupRec."Current Step" := Step;
        GuidedSetupRec.Modify();

        UpdateButtonState();
        UpdateInfoTexts();
        CurrPage.Update(false);
    end;

    local procedure UpdateButtonState()
    begin
        BackEnabled := Step > 1;
        NextEnabled := Step < 5;
        FinishEnabled := Step = 5;
    end;

    local procedure UpdateRecommendedAuth()
    var
        RecommendedAuth: Enum "KLT Auth Method";
    begin
        RecommendedAuth := SetupAutomation.RecommendAuthMethod(DeploymentType);
        if AuthMethod <> RecommendedAuth then
            AuthMethod := RecommendedAuth;
        
        GuidedSetupRec."Authentication Method" := AuthMethod;
    end;

    local procedure UpdateDefaultURL()
    begin
        if TargetBaseURL = '' then
            TargetBaseURL := SetupAutomation.GenerateDefaultURL(DeploymentType, ServerNameHint)
        else if ServerNameHint <> '' then
            TargetBaseURL := SetupAutomation.GenerateDefaultURL(DeploymentType, ServerNameHint);

        GuidedSetupRec."Auto-Detected Base URL" := TargetBaseURL;
    end;

    local procedure UpdateInfoTexts()
    begin
        case DeploymentType of
            DeploymentType::OnPremise:
                DeploymentInfoTxt := 'On-Premise deployment detected. Recommended: Basic Authentication for simplicity and security on local networks.';
            DeploymentType::SaaS:
                DeploymentInfoTxt := 'SaaS (Cloud) deployment detected. Required: OAuth 2.0 authentication with Azure AD.';
            DeploymentType::Hybrid:
                DeploymentInfoTxt := 'Hybrid deployment detected. Recommended: OAuth 2.0 authentication for cloud connectivity.';
        end;

        case DeploymentType of
            DeploymentType::OnPremise:
                URLExamplesTxt := 'On-Premise: https://bc27-server:7048/BC270/ODataV4/\n\nReplace "bc27-server" with your actual server name or IP address.';
            DeploymentType::SaaS:
                URLExamplesTxt := 'SaaS: https://api.businesscentral.dynamics.com/v2.0/{environment}/api/v2.0/\n\nReplace {environment} with your environment name (e.g., "production", "sandbox").';
            DeploymentType::Hybrid:
                URLExamplesTxt := 'Hybrid typically uses SaaS URL format with Azure AD authentication.';
        end;

        NextStepsTxt := '✓ Configuration saved to API Configuration\n' +
                       '✓ You can now test the connection\n' +
                       '✓ Enable sync to start document synchronization\n' +
                       '✓ Configure job queue for automatic sync every 15 minutes\n' +
                       '✓ Monitor sync status in KLT Document Sync Log\n\n' +
                       'Advanced users can customize settings in KLT API Configuration page.';
    end;

    local procedure ValidateCurrentStep(): Boolean
    var
        IsValid: Boolean;
    begin
        IsValid := true;

        case Step of
            1:
                IsValid := SetupAutomation.ValidateStep1(GuidedSetupRec);
            2:
                IsValid := SetupAutomation.ValidateStep2(TargetBaseURL, TargetCompanyID);
            3:
                IsValid := SetupAutomation.ValidateStep3(
                    AuthMethod,
                    BasicUsername, BasicPassword,
                    OAuthClientID, OAuthClientSecret, OAuthTenantID);
            4:
                IsValid := true; // Review step, always valid
            5:
                IsValid := true; // Final step
        end;

        if not IsValid then
            Error('Please fill in all required fields before proceeding.');

        exit(IsValid);
    end;

    local procedure TestConnection()
    var
        APIConfig: Record "KLT API Config";
    begin
        // Create temporary config for testing
        if not APIConfig.Get('') then begin
            APIConfig.Init();
            APIConfig."Primary Key" := '';
            APIConfig.Insert();
        end;

        ApplyWizardSettingsToConfig(APIConfig);

        // Simple validation - actual connection test would require API Helper
        ConnectionTestSuccess := (TargetBaseURL <> '') and (not IsNullGuid(TargetCompanyID));

        if ConnectionTestSuccess then
            ConnectionTestResultTxt := '✓ Configuration appears valid. Connection will be tested when sync is enabled.'
        else
            ConnectionTestResultTxt := '✗ Configuration validation failed. Please check your settings.';

        CurrPage.Update(false);
    end;

    local procedure FinishSetup()
    var
        APIConfig: Record "KLT API Config";
    begin
        // Get or create API config
        if not APIConfig.Get('') then begin
            APIConfig.Init();
            APIConfig."Primary Key" := '';
            APIConfig.Insert();
        end;

        // Apply wizard settings to actual configuration
        ApplyWizardSettingsToConfig(APIConfig);
        APIConfig.Modify();

        // Mark setup as complete
        GuidedSetupRec.CompleteSetup();

        Message('Setup completed successfully!\n\nYour API configuration has been saved.\n\nNext steps:\n- Open KLT API Configuration to enable sync\n- Configure job queue for automatic synchronization\n- Monitor sync status in KLT Document Sync Log');
        
        CurrPage.Close();
    end;

    local procedure ApplyWizardSettingsToConfig(var APIConfig: Record "KLT API Config")
    begin
        SetupAutomation.ApplyConfigurationFromWizard(GuidedSetupRec, APIConfig);
        
        APIConfig."Target Base URL" := TargetBaseURL;
        APIConfig."Target Company ID" := TargetCompanyID;

        case AuthMethod of
            AuthMethod::Basic:
                begin
                    APIConfig."Target Username" := BasicUsername;
                    APIConfig."Target Password" := BasicPassword;
                end;
            AuthMethod::OAuth:
                begin
                    APIConfig."Target Tenant ID" := OAuthTenantID;
                    APIConfig."Target Client ID" := OAuthClientID;
                    APIConfig."Target Client Secret" := OAuthClientSecret;
                end;
            AuthMethod::Windows:
                begin
                    APIConfig."Target Username" := WindowsUsername;
                    APIConfig."Target Domain" := WindowsDomain;
                end;
            AuthMethod::Certificate:
                begin
                    APIConfig."Target Certificate Name" := CertificateName;
                    APIConfig."Target Certificate Thumbprint" := CertificateThumbprint;
                end;
        end;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") then
                TopBannerVisible := MediaResourcesStandard."Media Reference".HasValue();
    end;
}
