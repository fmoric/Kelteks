/// <summary>
/// Page KLT API Configuration BC27 (ID 50150).
/// Configuration page for BC27 API integration settings.
/// </summary>
page 50150 "KLT API Configuration BC27"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "KLT API Config BC27";
    Caption = 'Kelteks API Configuration (BC27)';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Connection)
            {
                Caption = 'BC17 Connection Settings';
                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base URL for BC17 (e.g., https://bc17-server:7048/BC170/ODataV4/)';
                    ShowMandatory = true;
                }
                field("Company ID"; Rec."Company ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Company GUID in BC17';
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
        }
        area(FactBoxes)
        {
            part(ConfigFactBox; "KLT Config FactBox BC27")
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
                ToolTip = 'Tests the connection to BC17 using the configured settings';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    APIHelper: Codeunit "KLT API Helper BC27";
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
                    SyncEngine: Codeunit "KLT Sync Engine BC27";
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
