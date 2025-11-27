/// <summary>
/// PageExtension KLT Posted Sales Inv List BC17 (ID 50100) extends Record Posted Sales Invoices.
/// Adds "Sync to target" action to Posted Sales Invoices list.
/// </summary>
pageextension 80101 "KLT Posted Sales Inv List" extends "Posted Sales Invoices"
{
    actions
    {
        addlast(Processing)
        {
            action(SyncToTarget)
            {
                ApplicationArea = All;
                Caption = 'Sync to target';
                Image = SendTo;
                ToolTip = 'Synchronizes the selected sales invoice(s) to target';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SalesInvHeader: Record "Sales Invoice Header";
                    SyncEngine: Codeunit "KLT Sync Engine";
                    SelectedCount: Integer;
                    QueuedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(SalesInvHeader);
                    SelectedCount := SalesInvHeader.Count();

                    if SelectedCount = 0 then
                        Error('Please select at least one invoice to sync.');

                    if not Confirm('Queue %1 invoice(s) for synchronization?', false, SelectedCount) then
                        exit;

                    // Queue each selected invoice
                    QueuedCount := 0;
                    if SalesInvHeader.FindSet() then begin
                        repeat
                            SyncEngine.QueueSalesInvoice(SalesInvHeader."No.");
                            QueuedCount += 1;
                        until SalesInvHeader.Next() = 0;
                    end;

                    Message('%1 invoice(s) queued for synchronization.', QueuedCount);
                end;
            }
            action(ViewSyncLog)
            {
                ApplicationArea = All;
                Caption = 'View Sync Log';
                Image = Log;
                ToolTip = 'Opens the sync log to view synchronization history';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Page.Run(Page::"KLT Document Sync Log");
                end;
            }
        }
    }
}
