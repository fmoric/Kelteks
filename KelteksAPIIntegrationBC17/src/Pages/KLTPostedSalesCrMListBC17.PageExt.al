/// <summary>
/// PageExtension KLT Posted Sales Cr.M List BC17 (ID 50101) extends Record Posted Sales Credit Memos.
/// Adds "Sync to target" action to Posted Sales Credit Memos list.
/// </summary>
pageextension 50101 "KLT Posted Sales Cr.M List" extends "Posted Sales Credit Memos"
{
    actions
    {
        addlast(Processing)
        {
            action(SyncToBC27)
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
                    SalesDocSync: Codeunit "KLT Sales Doc Sync";
                    SelectedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                    SelectedCount := SalesCrMemoHeader.Count();
                    
                    if SelectedCount = 0 then
                        Error('Please select at least one credit memo to sync.');

                    if not Confirm('Sync %1 credit memo(s) to target?', false, SelectedCount) then
                        exit;

                    SalesDocSync.SyncSalesCreditMemos(SalesCrMemoHeader);
                    Message('%1 credit memo(s) queued for synchronization.', SelectedCount);
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
                    Page.Run(Page::"KLT Document Sync Log BC17");
                end;
            }
        }
    }
}
