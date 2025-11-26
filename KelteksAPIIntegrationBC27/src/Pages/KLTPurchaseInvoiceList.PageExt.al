/// <summary>
/// PageExtension KLT Purchase Invoice List BC27 (ID 50150) extends Record Purchase Invoices.
/// Adds sync status indicators to Purchase Invoices list.
/// </summary>
pageextension 50106 "KLT Purchase Invoice List" extends "Purchase Invoices"
{
    layout
    {
        addlast(Control1)
        {
            field("KLT Sync Status"; GetSyncStatus())
            {
                ApplicationArea = All;
                Caption = 'Sync Status';
                ToolTip = 'Shows the synchronization status of this document';
                StyleExpr = SyncStatusStyle;
                Editable = false;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ViewSyncHistory)
            {
                ApplicationArea = All;
                Caption = 'View Sync History';
                Image = Log;
                ToolTip = 'Opens the sync log to view synchronization history for this document';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SyncLog: Record "KLT Document Sync Log";
                begin
                    SyncLog.SetRange("Target Document No.", Rec."No.");
                    SyncLog.SetRange("Document Type", SyncLog."Document Type"::"Purchase Invoice");
                    Page.Run(Page::"KLT Document Sync Log BC27", SyncLog);
                end;
            }
            action(ViewAllSyncLog)
            {
                ApplicationArea = All;
                Caption = 'View All Sync Logs';
                Image = Log;
                ToolTip = 'Opens the sync log to view all synchronization history';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Page.Run(Page::"KLT Document Sync Log BC27");
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetSyncStatusStyle();
    end;

    local procedure GetSyncStatus(): Text
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        SyncLog.SetRange("Target Document No.", Rec."No.");
        SyncLog.SetRange("Document Type", SyncLog."Document Type"::"Purchase Invoice");
        if SyncLog.FindLast() then
            exit(Format(SyncLog.Status))
        else
            exit('Not Synced');
    end;

    local procedure SetSyncStatusStyle()
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        SyncStatusStyle := '';
        SyncLog.SetRange("Target Document No.", Rec."No.");
        SyncLog.SetRange("Document Type", SyncLog."Document Type"::"Purchase Invoice");
        if SyncLog.FindLast() then begin
            case SyncLog.Status of
                SyncLog.Status::Completed:
                    SyncStatusStyle := 'Favorable';
                SyncLog.Status::Failed:
                    SyncStatusStyle := 'Unfavorable';
                SyncLog.Status::Retrying:
                    SyncStatusStyle := 'Attention';
            end;
        end;
    end;

    var
        SyncStatusStyle: Text;
}
