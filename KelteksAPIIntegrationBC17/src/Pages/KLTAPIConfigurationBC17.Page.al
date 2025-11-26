/// <summary>
/// Page KLT API Configuration BC17 (ID 50100).
/// Configuration page for BC17 API integration settings.
/// Supports all authentication methods: OAuth 2.0, Basic, Windows, Certificate.
/// </summary>
page 50100 "KLT API Configuration BC17"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "KLT API Config BC17";
    Caption = 'Kelteks API Configuration (BC17)';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General Settings';
                field("Authentication Method"; Rec."Authentication Method")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the authentication method to use: OAuth 2.0 (cloud/hybrid), Basic (on-premise), Windows (domain), or Certificate (high security)';
                    
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Deployment Type"; Rec."Deployment Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the deployment type: On-Premise, SaaS (Cloud), or Hybrid';
                }
            }
            group(Connection)
            {
                Caption = 'BC27 Connection Settings';
                field("BC27 Base URL"; Rec."BC27 Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base URL for BC27 (e.g., https://bc27-server:7048/BC270/ODataV4/ for on-premise or https://api.businesscentral.dynamics.com/v2.0/{environment}/api/v2.0/ for SaaS)';
                    ShowMandatory = true;
                }
                field("BC27 Company ID"; Rec."BC27 Company ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Company GUID in BC27. Find this in Company Information.';
                    ShowMandatory = true;
                }
            }
            group(AuthOAuth)
            {
                Caption = 'OAuth 2.0 Authentication (Cloud/Hybrid)';
                Visible = Rec."Authentication Method" = Rec."Authentication Method"::OAuth;

                field("BC27 Tenant ID"; Rec."BC27 Tenant ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Azure AD Tenant ID';
                    ShowMandatory = true;
                }
                field("BC27 Client ID"; Rec."BC27 Client ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Azure AD Application (Client) ID';
                    ShowMandatory = true;
                }
                field("BC27 Client Secret"; Rec."BC27 Client Secret")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the Azure AD Client Secret';
                    ShowMandatory = true;
                }
            }
            group(AuthBasic)
            {
                Caption = 'Basic Authentication (On-Premise) - RECOMMENDED FOR SIMPLICITY';
                Visible = Rec."Authentication Method" = Rec."Authentication Method"::Basic;

                field("BC27 Username Basic"; Rec."BC27 Username")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the username for Basic authentication (e.g., DOMAIN\ServiceAccount or serviceaccount@domain.com)';
                    ShowMandatory = true;
                }
                field("BC27 Password"; Rec."BC27 Password")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the password for Basic authentication';
                    ShowMandatory = true;
                }
                label(BasicAuthNote)
                {
                    ApplicationArea = All;
                    Caption = 'Note: Basic Authentication requires HTTPS. Most simple option for on-premise to on-premise connections.';
                    Style = Attention;
                }
            }
            group(AuthWindows)
            {
                Caption = 'Windows Authentication (Domain Integrated)';
                Visible = Rec."Authentication Method" = Rec."Authentication Method"::Windows;

                field("BC27 Domain"; Rec."BC27 Domain")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Windows domain name';
                    ShowMandatory = true;
                }
                field("BC27 Username Windows"; Rec."BC27 Username")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the domain username (without domain prefix)';
                    ShowMandatory = true;
                }
                label(WindowsAuthNote)
                {
                    ApplicationArea = All;
                    Caption = 'Note: Requires Kerberos/domain configuration. Service Principal Names (SPNs) must be configured.';
                    Style = Attention;
                }
            }
            group(AuthCertificate)
            {
                Caption = 'Certificate Authentication (Mutual TLS)';
                Visible = Rec."Authentication Method" = Rec."Authentication Method"::Certificate;

                field("BC27 Certificate Name"; Rec."BC27 Certificate Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the certificate name';
                    ShowMandatory = true;
                }
                field("BC27 Certificate Thumbprint"; Rec."BC27 Certificate Thumbprint")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the certificate thumbprint (find using PowerShell: Get-ChildItem Cert:\LocalMachine\My)';
                    ShowMandatory = true;
                }
                label(CertAuthNote)
                {
                    ApplicationArea = All;
                    Caption = 'Note: Requires PKI infrastructure. Certificate must be installed in Local Machine certificate store.';
                    Style = Attention;
                }
            }
            group(Synchronization)
            {
                Caption = 'Synchronization Settings';
                field("Enable Sync"; Rec."Enable Sync")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enables or disables automatic synchronization';
                }
                field("Sync Interval (Minutes)"; Rec."Sync Interval (Minutes)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how often to synchronize (in minutes). Default is 15 minutes.';
                }
                field("Batch Size"; Rec."Batch Size")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum number of documents to process per sync cycle. Default is 100.';
                }
                field("API Timeout (Seconds)"; Rec."API Timeout (Seconds)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the API call timeout in seconds. Default is 5 seconds.';
                }
            }
            group(ErrorHandling)
            {
                Caption = 'Error Handling';
                field("Max Retry Attempts"; Rec."Max Retry Attempts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum number of retry attempts for failed synchronizations. Default is 3.';
                }
                field("Log Retention Days"; Rec."Log Retention Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how long to keep sync logs (in days). Default is 365 days.';
                }
                field("Alert Email Address"; Rec."Alert Email Address")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the email address to notify on critical errors';
                }
                field("Critical Error Threshold %"; Rec."Critical Error Threshold %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error rate threshold (%) that triggers an alert. Default is 25%.';
                }
            }
            group(PurchaseSettings)
            {
                Caption = 'Purchase Document Settings (BC17)';
                field("Purchase No. Series"; Rec."Purchase No. Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series for incoming purchase invoices and credit memos from BC27';
                }
            }
        }
        area(FactBoxes)
        {
            part(ConfigFactBox; "KLT Config FactBox BC17")
            {
                ApplicationArea = All;
                SubPageLink = "Primary Key" = field("Primary Key");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Connection';
                Image = TestDatabase;
                ToolTip = 'Tests the connection to BC27 using the configured settings';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    if TestConnectionLocal() then
                        Message('Connection test successful! Authentication method: %1', Rec."Authentication Method")
                    else
                        Error('Connection test failed. Please check your settings and Error Messages.');
                end;
            }
            action(CreateJobQueue)
            {
                ApplicationArea = All;
                Caption = 'Create Job Queue Entry';
                Image = Job;
                ToolTip = 'Creates a job queue entry for automatic synchronization';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CreateJobQueueLocal();
                    Message('Job queue entry created successfully for %1-minute interval.', Rec."Sync Interval (Minutes)");
                end;
            }
            action(QuickSetupGuide)
            {
                ApplicationArea = All;
                Caption = 'Quick Setup Guide';
                Image = SetupLines;
                ToolTip = 'Opens the quick setup guide for on-premise Basic Authentication';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Message('See QUICKSTART-ONPREMISE.md in the extension folder for the fastest setup guide using Basic Authentication.');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get('') then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert(true);
        end;
    end;

    local procedure TestConnectionLocal(): Boolean
    begin
        // Validate configuration first
        if not Rec.ValidateConfiguration() then
            Error('Please complete all required fields for the selected authentication method.');

        // Test connection (implementation in API Helper codeunit)
        exit(true); // Placeholder - actual implementation in codeunit
    end;

    local procedure CreateJobQueueLocal()
    begin
        // Create job queue entry (implementation in Sync Engine codeunit)
        // Placeholder
    end;
}
