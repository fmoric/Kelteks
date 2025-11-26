/// <summary>
/// Page KLT Document Sync Log BC17 (ID 50101).
/// List page showing sync history for BC17.
/// </summary>
page 50101 "KLT Document Sync Log BC17"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "KLT Document Sync Log";
    Caption = 'Document Sync Log (BC17)';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = true;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of document being synchronized';
                }
                field("Source Document No."; Rec."Source Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number in the source system';
                }
                field("Target Document No."; Rec."Target Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number created in the target system';
                }
                field("Sync Direction"; Rec."Sync Direction")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the direction of synchronization';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current status of the synchronization';
                    StyleExpr = StatusStyle;
                }
                field("Start DateTime"; Rec."Start DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the synchronization started';
                }
                field("End DateTime"; Rec."End DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the synchronization completed';
                }
                field("Duration (ms)"; Rec."Duration (ms)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how long the synchronization took in milliseconds';
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of retry attempts';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message if sync failed';
                }
            }
        }
        area(FactBoxes)
        {
            part(SyncStats; "KLT Sync Log FactBox BC17")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewErrorDetails)
            {
                ApplicationArea = All;
                Caption = 'View Error Details';
                Image = ErrorLog;
                ToolTip = 'Opens the Error Messages page to view detailed error information';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ErrorMessage: Record "Error Message";
                begin
                    ErrorMessage.SetRange("Context Record ID", Rec.RecordId);
                    Page.Run(Page::"Error Messages", ErrorMessage);
                end;
            }
            action(RetrySync)
            {
                ApplicationArea = All;
                Caption = 'Retry Sync';
                Image = Refresh;
                ToolTip = 'Retries the synchronization for the selected document';
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::Failed;

                trigger OnAction()
                var
                    SyncEngine: Codeunit "KLT Sync Engine BC17";
                begin
                    SyncEngine.RetryFailedSync(Rec);
                    Message('Retry initiated.');
                end;
            }
            action(DeleteOldLogs)
            {
                ApplicationArea = All;
                Caption = 'Delete Old Logs';
                Image = Delete;
                ToolTip = 'Deletes log entries older than the retention period';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    APIConfig: Record "KLT API Config BC17";
                    SyncLog: Record "KLT Document Sync Log";
                begin
                    if not Confirm('Delete logs older than %1 days?', false, 365) then
                        exit;

                    SyncLog.SetFilter("Start DateTime", '<%1', CreateDateTime(CalcDate('<-365D>', Today()), 0T));
                    SyncLog.DeleteAll(true);
                    Message('Old logs deleted successfully.');
                end;
            }
        }
        area(Navigation)
        {
            action(ViewSourceDocument)
            {
                ApplicationArea = All;
                Caption = 'View Source Document';
                Image = Document;
                ToolTip = 'Opens the source document in the source system';

                trigger OnAction()
                begin
                    Rec.ShowSourceDocument();
                end;
            }
            action(ViewTargetDocument)
            {
                ApplicationArea = All;
                Caption = 'View Target Document';
                Image = Document;
                ToolTip = 'Opens the target document in the target system';

                trigger OnAction()
                begin
                    Rec.ShowTargetDocument();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStatusStyle();
    end;

    local procedure SetStatusStyle()
    begin
        StatusStyle := '';
        case Rec.Status of
            Rec.Status::Completed:
                StatusStyle := 'Favorable';
            Rec.Status::Failed:
                StatusStyle := 'Unfavorable';
            Rec.Status::Retrying:
                StatusStyle := 'Attention';
            Rec.Status::"In Progress":
                StatusStyle := 'Strong';
        end;
    end;

    var
        StatusStyle: Text;
}
