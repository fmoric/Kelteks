/// <summary>
/// Page KLT Sync Queue BC27 (ID 50152).
/// List page for managing the sync queue in BC27.
/// </summary>
page 50152 "KLT Sync Queue BC27"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "KLT API Sync Queue";
    Caption = 'API Sync Queue (BC27)';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of document';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number';
                }
                field("Sync Direction"; Rec."Sync Direction")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sync direction';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the queue item status';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the processing priority (1=highest, 10=lowest)';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the item was added to the queue';
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of retry attempts';
                }
                field("Last Error Message"; Rec."Last Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last error message if processing failed';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessQueue)
            {
                ApplicationArea = All;
                Caption = 'Process Queue';
                Image = Process;
                ToolTip = 'Processes pending items in the queue';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    SyncEngine: Codeunit "KLT Sync Engine";
                begin
                    SyncEngine.ProcessSyncQueue();
                    Message('Queue processing initiated.');
                end;
            }
            action(ClearCompleted)
            {
                ApplicationArea = All;
                Caption = 'Clear Completed';
                Image = ClearLog;
                ToolTip = 'Removes completed items from the queue';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    QueueRec: Record "KLT API Sync Queue";
                begin
                    QueueRec.SetRange(Status, QueueRec.Status::Completed);
                    if QueueRec.FindSet() then begin
                        QueueRec.DeleteAll();
                        Message('Completed items removed from queue.');
                    end else
                        Message('No completed items found.');
                end;
            }
            action(ResetFailed)
            {
                ApplicationArea = All;
                Caption = 'Reset Failed';
                Image = ResetStatus;
                ToolTip = 'Resets failed items to pending status for retry';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    QueueRec: Record "KLT API Sync Queue";
                begin
                    QueueRec.SetRange(Status, QueueRec.Status::Failed);
                    if QueueRec.FindSet() then begin
                        repeat
                            QueueRec.Status := QueueRec.Status::Pending;
                            QueueRec."Retry Count" := 0;
                            QueueRec.Modify();
                        until QueueRec.Next() = 0;
                        Message('Failed items reset to pending.');
                    end else
                        Message('No failed items found.');
                end;
            }
        }
    }
}
