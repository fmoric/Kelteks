/// <summary>
/// List page for viewing and managing synchronization errors
/// </summary>
page 50102 "KLT Document Sync Error"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "KLT Document Sync Error";
    Caption = 'Document Sync Errors';
    InsertAllowed = false;
    DeleteAllowed = true;

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
                field("Error Category"; Rec."Error Category")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error category';
                    StyleExpr = CategoryStyle;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document type';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the external document number';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message';
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of retry attempts';
                }
                field("Max Retry Attempts"; Rec."Max Retry Attempts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum number of retry attempts';
                }
                field("Can Retry"; Rec."Can Retry")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the error can be retried';
                }
                field("Next Retry DateTime"; Rec."Next Retry DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the next retry will occur';
                }
                field("Last Retry DateTime"; Rec."Last Retry DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the last retry occurred';
                }
                field(Resolved; Rec.Resolved)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the error has been resolved';
                    StyleExpr = ResolvedStyle;
                }
                field("Resolved By"; Rec."Resolved By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who resolved the error';
                }
                field("Resolved DateTime"; Rec."Resolved DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the error was resolved';
                }
                field("Resolution Notes"; Rec."Resolution Notes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies notes about the resolution';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the error was created';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who created the entry';
                }
            }
        }
        area(FactBoxes)
        {
            part(ErrorDetails; "KLT Error Details FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkAsResolved)
            {
                ApplicationArea = All;
                Caption = 'Mark as Resolved';
                ToolTip = 'Mark the error as resolved';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = not Rec.Resolved;

                trigger OnAction()
                var
                    ResolutionNote: Text[250];
                begin
                    ResolutionNote := CopyStr(
                        DelChr(
                            InputBox('Enter resolution notes:', 'Resolution', ''),
                            '<>', ' '),
                        1, 250);
                    
                    if ResolutionNote <> '' then begin
                        Rec.MarkAsResolved(ResolutionNote);
                        CurrPage.Update(false);
                        Message('Error marked as resolved.');
                    end;
                end;
            }
            
            action(RetryNow)
            {
                ApplicationArea = All;
                Caption = 'Retry Now';
                ToolTip = 'Retry the failed operation immediately';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = Rec."Can Retry" and not Rec.Resolved;

                trigger OnAction()
                begin
                    Message('Retry functionality will be implemented in future version.');
                    // In production, this would trigger the actual retry logic
                end;
            }
            
            action(ShowUnresolved)
            {
                ApplicationArea = All;
                Caption = 'Show Unresolved';
                ToolTip = 'Show only unresolved errors';
                Image = Filter;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.SetRange(Resolved, false);
                    CurrPage.Update(false);
                end;
            }
            
            action(ShowAll)
            {
                ApplicationArea = All;
                Caption = 'Show All';
                ToolTip = 'Show all errors';
                Image = ShowList;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.SetRange(Resolved);
                    CurrPage.Update(false);
                end;
            }
            
            action(ViewSyncLog)
            {
                ApplicationArea = All;
                Caption = 'View Sync Log';
                ToolTip = 'View related sync log entry';
                Image = Log;
                
                trigger OnAction()
                var
                    SyncLog: Record "KLT Document Sync Log";
                    SyncLogPage: Page "KLT Document Sync Log";
                begin
                    if SyncLog.Get(Rec."Sync Log Entry No.") then begin
                        SyncLogPage.SetRecord(SyncLog);
                        SyncLogPage.RunModal();
                    end else
                        Message('Related sync log entry not found.');
                end;
            }
            
            action(ViewErrorDetails)
            {
                ApplicationArea = All;
                Caption = 'View Full Error Details';
                ToolTip = 'View complete error details including stack trace';
                Image = ViewDetails;
                
                trigger OnAction()
                var
                    ErrorDetails: Text;
                begin
                    ErrorDetails := Rec.GetErrorDetails();
                    if ErrorDetails <> '' then
                        Message('Error Details:\n\n%1', ErrorDetails)
                    else
                        Message('Error Message: %1\n\nStack Trace: %2',
                                Rec."Error Message",
                                Rec."Stack Trace");
                end;
            }
        }
        area(Navigation)
        {
            action(Statistics)
            {
                ApplicationArea = All;
                Caption = 'Error Statistics';
                ToolTip = 'View error statistics by category';
                Image = Statistics;
                
                trigger OnAction()
                var
                    SyncError: Record "KLT Document Sync Error";
                    TotalErrors: Integer;
                    APICommErrors: Integer;
                    DataValErrors: Integer;
                    BusinessLogicErrors: Integer;
                    AuthErrors: Integer;
                    MasterDataErrors: Integer;
                begin
                    TotalErrors := SyncError.Count();
                    
                    SyncError.SetRange("Error Category", SyncError."Error Category"::"API Communication");
                    APICommErrors := SyncError.Count();
                    
                    SyncError.SetRange("Error Category", SyncError."Error Category"::"Data Validation");
                    DataValErrors := SyncError.Count();
                    
                    SyncError.SetRange("Error Category", SyncError."Error Category"::"Business Logic");
                    BusinessLogicErrors := SyncError.Count();
                    
                    SyncError.SetRange("Error Category", SyncError."Error Category"::Authentication);
                    AuthErrors := SyncError.Count();
                    
                    SyncError.SetRange("Error Category", SyncError."Error Category"::"Master Data Missing");
                    MasterDataErrors := SyncError.Count();
                    
                    Message('Error Statistics:\n\n' +
                           'Total Errors: %1\n\n' +
                           'By Category:\n' +
                           '- API Communication: %2\n' +
                           '- Data Validation: %3\n' +
                           '- Business Logic: %4\n' +
                           '- Authentication: %5\n' +
                           '- Master Data Missing: %6',
                           TotalErrors, APICommErrors, DataValErrors, BusinessLogicErrors, AuthErrors, MasterDataErrors);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStyles();
    end;

    local procedure SetStyles()
    begin
        // Set category style
        case Rec."Error Category" of
            Rec."Error Category"::"API Communication":
                CategoryStyle := 'Attention';
            Rec."Error Category"::Authentication:
                CategoryStyle := 'Unfavorable';
            Rec."Error Category"::"Data Validation":
                CategoryStyle := 'Ambiguous';
            Rec."Error Category"::"Master Data Missing":
                CategoryStyle := 'AttentionAccent';
            else
                CategoryStyle := 'Standard';
        end;

        // Set resolved style
        if Rec.Resolved then
            ResolvedStyle := 'Favorable'
        else
            ResolvedStyle := 'Standard';
    end;

    local procedure InputBox(Prompt: Text; Title: Text; DefaultValue: Text): Text
    var
        Result: Text;
    begin
        // Simple input box - in production, use a proper dialog page
        Result := DefaultValue;
        exit(Result);
    end;

    var
        CategoryStyle: Text;
        ResolvedStyle: Text;
}
