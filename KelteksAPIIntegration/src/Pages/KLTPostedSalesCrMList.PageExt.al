/// <summary>
/// Page extension for Posted Sales Credit Memo List
/// Adds action to sync to BC27
/// </summary>
pageextension 50101 "KLT Posted Sales Cr.M. List" extends "Posted Sales Credit Memos"
{
    actions
    {
        addlast(Processing)
        {
            group(KelteksSync)
            {
                Caption = 'Kelteks Sync';
                Image = DataEntry;

                action(SyncToBC27)
                {
                    ApplicationArea = All;
                    Caption = 'Sync to BC27';
                    ToolTip = 'Synchronize this credit memo to BC27';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        SyncQueue: Record "KLT API Sync Queue";
                    begin
                        SyncQueue.EnqueueDocument(
                            SyncQueue."Document Type"::"Sales Credit Memo",
                            Rec."No.",
                            Rec.SystemId,
                            SyncQueue."Sync Direction"::Outbound,
                            Rec."External Document No.");
                        
                        Message('Credit Memo %1 queued for synchronization to BC27.', Rec."No.");
                    end;
                }

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
                        SyncLog.SetRange("Document Type", SyncLog."Document Type"::"Sales Credit Memo");
                        SyncLog.SetRange("Source Document No.", Rec."No.");
                        SyncLogPage.SetTableView(SyncLog);
                        SyncLogPage.RunModal();
                    end;
                }

                action(RunSyncNow)
                {
                    ApplicationArea = All;
                    Caption = 'Run All Sync Now';
                    ToolTip = 'Run synchronization for all sales credit memos immediately';
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    var
                        SalesDocSync: Codeunit "KLT Sales Doc Sync";
                    begin
                        SalesDocSync.SyncSalesCreditMemos();
                    end;
                }
            }
        }
    }
}
