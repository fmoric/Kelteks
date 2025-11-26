/// <summary>
/// Configuration page for API endpoints and settings
/// </summary>
page 50100 "KLT API Configuration"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "KLT API Configuration";
    Caption = 'API Configuration';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(BC17Settings)
            {
                Caption = 'BC17 Settings (Source for Sales)';
                
                field("BC17 Base URL"; Rec."BC17 Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base URL for BC17 API endpoint';
                }
                field("BC17 Company ID"; Rec."BC17 Company ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company GUID for BC17';
                }
                field("BC17 Tenant ID"; Rec."BC17 Tenant ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Azure AD tenant ID for BC17';
                }
                field("BC17 Client ID"; Rec."BC17 Client ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the OAuth client ID for BC17';
                }
                field("BC17 Client Secret"; Rec."BC17 Client Secret")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the OAuth client secret for BC17';
                    ExtendedDatatype = Masked;
                }
            }
            
            group(BC27Settings)
            {
                Caption = 'BC27 Settings (Target for Sales)';
                
                field("BC27 Base URL"; Rec."BC27 Base URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the base URL for BC27 API endpoint';
                }
                field("BC27 Company ID"; Rec."BC27 Company ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company GUID for BC27';
                }
                field("BC27 Tenant ID"; Rec."BC27 Tenant ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Azure AD tenant ID for BC27';
                }
                field("BC27 Client ID"; Rec."BC27 Client ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the OAuth client ID for BC27';
                }
                field("BC27 Client Secret"; Rec."BC27 Client Secret")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the OAuth client secret for BC27';
                    ExtendedDatatype = Masked;
                }
            }
            
            group(SyncSettings)
            {
                Caption = 'Synchronization Settings';
                
                field("Enable Sync"; Rec."Enable Sync")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable or disable automatic synchronization';
                }
                field("Sync Interval (Minutes)"; Rec."Sync Interval (Minutes)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the interval in minutes between sync operations';
                }
                field("Batch Size"; Rec."Batch Size")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum number of documents to process per batch';
                }
                field("API Timeout (Seconds)"; Rec."API Timeout (Seconds)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the timeout in seconds for API requests';
                }
                field("Max Retry Attempts"; Rec."Max Retry Attempts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum number of retry attempts for failed operations';
                }
            }
            
            group(AlertSettings)
            {
                Caption = 'Alert Settings';
                
                field("Alert Email Address"; Rec."Alert Email Address")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the email address for critical alerts';
                }
                field("Critical Error Threshold %"; Rec."Critical Error Threshold %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error rate percentage that triggers critical alerts';
                }
            }
            
            group(OtherSettings)
            {
                Caption = 'Other Settings';
                
                field("Log Retention Days"; Rec."Log Retention Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of days to retain log entries';
                }
                field("Purchase No. Series BC17"; Rec."Purchase No. Series BC17")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series for purchase documents in BC17';
                }
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
                ToolTip = 'Test API connection and authentication';
                Image = TestDatabase;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    APIAuth: Codeunit "KLT API Authentication";
                begin
                    if APIAuth.ValidateAuthentication() then
                        Message('Connection test successful!')
                    else
                        Error('Connection test failed. Please check your configuration.');
                end;
            }
            
            action(CreateJobQueue)
            {
                ApplicationArea = All;
                Caption = 'Create Job Queue Entry';
                ToolTip = 'Create job queue entry for scheduled synchronization';
                Image = JobTimeSheet;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SyncEngine: Codeunit "KLT Sync Engine";
                begin
                    SyncEngine.CreateJobQueueEntry();
                end;
            }
            
            action(RunSyncNow)
            {
                ApplicationArea = All;
                Caption = 'Run Sync Now';
                ToolTip = 'Run synchronization immediately';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SyncEngine: Codeunit "KLT Sync Engine";
                begin
                    SyncEngine.RunScheduledSync();
                    Message('Synchronization completed.');
                end;
            }
            
            action(ViewSyncLog)
            {
                ApplicationArea = All;
                Caption = 'View Sync Log';
                ToolTip = 'View document synchronization log';
                Image = Log;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "KLT Document Sync Log";
            }
            
            action(ViewErrors)
            {
                ApplicationArea = All;
                Caption = 'View Errors';
                ToolTip = 'View synchronization errors';
                Image = ErrorLog;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "KLT Document Sync Error";
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
}
