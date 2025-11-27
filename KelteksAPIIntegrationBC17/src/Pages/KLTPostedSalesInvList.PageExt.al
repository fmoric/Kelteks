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
                    SalesDocSync: Codeunit "KLT Sales Doc Sync";
                    SelectedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(SalesInvHeader);
                    SelectedCount := SalesInvHeader.Count();

                    if SelectedCount = 0 then
                        Error('Please select at least one invoice to sync.');

                    if not Confirm('Sync %1 invoice(s) to target?', false, SelectedCount) then
                        exit;

                    SalesDocSync.SyncSalesInvoices(SalesInvHeader);
                    Message('%1 invoice(s) queued for synchronization.', SelectedCount);
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
