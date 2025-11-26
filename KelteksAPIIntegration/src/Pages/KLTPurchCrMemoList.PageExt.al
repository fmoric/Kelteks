/// <summary>
/// Page extension for Purchase Credit Memo List
/// Adds action to view sync status from BC27
/// </summary>
pageextension 50103 "KLT Purch. Cr. Memo List" extends "Purchase Credit Memos"
{
    actions
    {
        addlast(Processing)
        {
            group(KelteksSync)
            {
                Caption = 'Kelteks Sync';
                Image = DataEntry;

                action(ViewSyncLog)
                {
                    ApplicationArea = All;
                    Caption = 'View Sync Log';
                    ToolTip = 'View synchronization history for this credit memo';
                    Image = Log;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    var
                        SyncLog: Record "KLT Document Sync Log";
                        SyncLogPage: Page "KLT Document Sync Log";
                    begin
                        SyncLog.SetRange("Document Type", SyncLog."Document Type"::"Purchase Credit Memo");
                        SyncLog.SetRange("Target Document No.", Rec."No.");
                        SyncLogPage.SetTableView(SyncLog);
                        SyncLogPage.RunModal();
                    end;
                }

                action(RunSyncNow)
                {
                    ApplicationArea = All;
                    Caption = 'Run Sync from BC27';
                    ToolTip = 'Synchronize purchase credit memos from BC27 immediately';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        PurchaseDocSync: Codeunit "KLT Purchase Doc Sync";
                    begin
                        PurchaseDocSync.SyncPurchaseCreditMemos();
                    end;
                }

                action(CheckSyncStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Check Sync Status';
                    ToolTip = 'Check if this credit memo was synchronized from BC27';
                    Image = Status;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    var
                        SyncLog: Record "KLT Document Sync Log";
                    begin
                        SyncLog.SetRange("Document Type", SyncLog."Document Type"::"Purchase Credit Memo");
                        SyncLog.SetRange("Target Document No.", Rec."No.");
                        if SyncLog.FindFirst() then
                            Message('This credit memo was synchronized from BC27.\n\n' +
                                   'Source Document: %1\n' +
                                   'Sync Date: %2\n' +
                                   'Status: %3',
                                   SyncLog."Source Document No.",
                                   SyncLog."Completed DateTime",
                                   SyncLog.Status)
                        else
                            Message('This credit memo was not synchronized from BC27.');
                    end;
                }
            }
        }
    }
}
