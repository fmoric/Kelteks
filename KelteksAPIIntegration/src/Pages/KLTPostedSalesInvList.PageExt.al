/// <summary>
/// Page extension for Posted Sales Invoice List
/// Adds action to sync to BC27
/// </summary>
pageextension 50100 "KLT Posted Sales Inv. List" extends "Posted Sales Invoices"
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
                    ToolTip = 'Synchronize this invoice to BC27';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        SyncQueue: Record "KLT API Sync Queue";
                    begin
                        SyncQueue.EnqueueDocument(
                            SyncQueue."Document Type"::"Sales Invoice",
                            Rec."No.",
                            Rec.SystemId,
                            SyncQueue."Sync Direction"::Outbound,
                            Rec."External Document No.");
                        
                        Message('Invoice %1 queued for synchronization to BC27.', Rec."No.");
                    end;
                }

                action(ViewSyncLog)
                {
                    ApplicationArea = All;
                    Caption = 'View Sync Log';
                    ToolTip = 'View synchronization history for this invoice';
                    Image = Log;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    var
                        SyncLog: Record "KLT Document Sync Log";
                        SyncLogPage: Page "KLT Document Sync Log";
                    begin
                        SyncLog.SetRange("Document Type", SyncLog."Document Type"::"Sales Invoice");
                        SyncLog.SetRange("Source Document No.", Rec."No.");
                        SyncLogPage.SetTableView(SyncLog);
                        SyncLogPage.RunModal();
                    end;
                }

                action(RunSyncNow)
                {
                    ApplicationArea = All;
                    Caption = 'Run All Sync Now';
                    ToolTip = 'Run synchronization for all sales invoices immediately';
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    var
                        SalesDocSync: Codeunit "KLT Sales Doc Sync";
                    begin
                        SalesDocSync.SyncSalesInvoices();
                    end;
                }
            }
        }
    }
}
