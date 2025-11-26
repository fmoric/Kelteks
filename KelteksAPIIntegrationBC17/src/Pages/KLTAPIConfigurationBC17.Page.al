/// <summary>
/// Page KLT API Configuration BC17 (ID 50100).
/// Configuration page for BC17 API integration settings.
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
            group(Connection)
            {
                Caption = 'BC27 Connection Settings';
                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base URL for BC27 (e.g., https://bc27-server:7048/BC270/ODataV4/)';
                    ShowMandatory = true;
                }
                field("Company ID"; Rec."Company ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Company GUID in BC27';
                    ShowMandatory = true;
                }
                field("Tenant ID"; Rec."Tenant ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Azure AD Tenant ID (for OAuth authentication)';
                }
                field("Client ID"; Rec."Client ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Azure AD Application (Client) ID (for OAuth authentication)';
                }
                field("Client Secret"; Rec."Client Secret")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the Azure AD Client Secret (for OAuth authentication)';
                }
            }
            group(Synchronization)
            {
                Caption = 'Synchronization Settings';
                field(Enabled; Rec.Enabled)
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
            }
            group(ErrorHandling)
            {
                Caption = 'Error Handling';
                field("Max Retry Attempts"; Rec."Max Retry Attempts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum number of retry attempts for failed synchronizations. Default is 3.';
                }
                field("Retry Delay (Minutes)"; Rec."Retry Delay (Minutes)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the initial delay before retrying a failed sync (in minutes). Uses exponential backoff.';
                }
                field("Error Email"; Rec."Error Email")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the email address to notify on critical errors';
                }
            }
            group(PurchaseSettings)
            {
                Caption = 'Purchase Document Settings';
                field("Purch. Invoice No. Series"; Rec."Purch. Invoice No. Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series for incoming purchase invoices from BC27';
                }
                field("Purch. Cr. Memo No. Series"; Rec."Purch. Cr. Memo No. Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series for incoming purchase credit memos from BC27';
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
                var
                    APIHelper: Codeunit "KLT API Helper BC17";
                begin
                    if APIHelper.TestConnection() then
                        Message('Connection test successful!')
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
                var
                    SyncEngine: Codeunit "KLT Sync Engine BC17";
                begin
                    SyncEngine.CreateJobQueueEntry();
                    Message('Job queue entry created successfully.');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
