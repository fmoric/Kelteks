/// <summary>
/// PageExtension KLT Posted Sales Cr.M List BC17 (ID 50101) extends Record Posted Sales Credit Memos.
/// Adds "Sync to target" action to Posted Sales Credit Memos list.
/// </summary>
pageextension 80100 "KLT Posted Sales Cr.M List" extends "Posted Sales Credit Memos"
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
                ToolTip = 'Synchronizes the selected sales credit memo(s) to target';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    SyncEngine: Codeunit "KLT Sync Engine";
                    SelectedCount: Integer;
                    QueuedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                    SelectedCount := SalesCrMemoHeader.Count();

                    if SelectedCount = 0 then
                        Error('Please select at least one credit memo to sync.');

                    if not Confirm('Queue %1 credit memo(s) for synchronization?', false, SelectedCount) then
                        exit;

                    // Queue each selected credit memo
                    QueuedCount := 0;
                    if SalesCrMemoHeader.FindSet() then begin
                        repeat
                            SyncEngine.QueueSalesCreditMemo(SalesCrMemoHeader."No.");
                            QueuedCount += 1;
                        until SalesCrMemoHeader.Next() = 0;
                    end;

                    Message('%1 credit memo(s) queued for synchronization.', QueuedCount);
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
