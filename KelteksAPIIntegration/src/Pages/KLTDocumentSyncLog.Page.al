/// <summary>
/// List page for viewing document synchronization history
/// </summary>
page 50101 "KLT Document Sync Log"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "KLT Document Sync Log";
    Caption = 'Document Sync Log';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
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
                    ToolTip = 'Specifies the entry number';
                }
                field("Sync Direction"; Rec."Sync Direction")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the synchronization direction';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document type';
                }
                field("Source Document No."; Rec."Source Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source document number';
                }
                field("Target Document No."; Rec."Target Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the target document number';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the external document number';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the synchronization status';
                    StyleExpr = StatusStyle;
                }
                field("Customer/Vendor No."; Rec."Customer/Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer or vendor number';
                }
                field("Customer/Vendor Name"; Rec."Customer/Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer or vendor name';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount including VAT';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency code';
                }
                field("Started DateTime"; Rec."Started DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the synchronization started';
                }
                field("Completed DateTime"; Rec."Completed DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the synchronization completed';
                }
                field("Duration (ms)"; Rec."Duration (ms)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the duration in milliseconds';
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of retry attempts';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message if failed';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who created the entry';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the entry was created';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = All;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                ToolTip = 'Refresh the list';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
            
            action(ShowErrors)
            {
                ApplicationArea = All;
                Caption = 'Show Errors';
                ToolTip = 'Show only failed synchronizations';
                Image = ErrorLog;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.SetRange(Status, Rec.Status::Failed);
                    CurrPage.Update(false);
                end;
            }
            
            action(ShowAll)
            {
                ApplicationArea = All;
                Caption = 'Show All';
                ToolTip = 'Show all synchronizations';
                Image = ShowList;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.SetRange(Status);
                    CurrPage.Update(false);
                end;
            }
            
            action(ViewErrorDetails)
            {
                ApplicationArea = All;
                Caption = 'View Error Details';
                ToolTip = 'View detailed error information';
                Image = ErrorLog;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec.Status = Rec.Status::Failed;

                trigger OnAction()
                var
                    SyncError: Record "KLT Document Sync Error";
                    ErrorPage: Page "KLT Document Sync Error";
                begin
                    SyncError.SetRange("Sync Log Entry No.", Rec."Entry No.");
                    if SyncError.FindFirst() then begin
                        ErrorPage.SetRecord(SyncError);
                        ErrorPage.RunModal();
                    end else
                        Message('No error details found for this entry.');
                end;
            }
        }
        area(Navigation)
        {
            action(Statistics)
            {
                ApplicationArea = All;
                Caption = 'Statistics';
                ToolTip = 'View synchronization statistics';
                Image = Statistics;
                
                trigger OnAction()
                var
                    SyncEngine: Codeunit "KLT Sync Engine";
                    TotalDocs: Integer;
                    SuccessDocs: Integer;
                    FailedDocs: Integer;
                    PendingRetries: Integer;
                    SuccessRate: Decimal;
                begin
                    SyncEngine.GetSyncStatistics(TotalDocs, SuccessDocs, FailedDocs, PendingRetries);
                    
                    if TotalDocs > 0 then
                        SuccessRate := (SuccessDocs / TotalDocs) * 100
                    else
                        SuccessRate := 0;
                    
                    Message('Synchronization Statistics:\n\n' +
                           'Total Documents: %1\n' +
                           'Successful: %2\n' +
                           'Failed: %3\n' +
                           'Success Rate: %4%\n' +
                           'Pending Retries: %5',
                           TotalDocs, SuccessDocs, FailedDocs, Round(SuccessRate, 0.01), PendingRetries);
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
        case Rec.Status of
            Rec.Status::Completed:
                StatusStyle := 'Favorable';
            Rec.Status::Failed:
                StatusStyle := 'Unfavorable';
            Rec.Status::"In Progress":
                StatusStyle := 'Ambiguous';
            Rec.Status::Retrying:
                StatusStyle := 'Attention';
            else
                StatusStyle := 'Standard';
        end;
    end;

    var
        StatusStyle: Text;
}
