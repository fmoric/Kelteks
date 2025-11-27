/// <summary>
/// Sync Engine for BC17
/// Orchestrates document synchronization with job queue, retry logic, and batch processing
/// </summary>
codeunit 80106 "KLT Sync Engine"
{
    var
        SalesDocSync: Codeunit "KLT Sales Doc Sync";
        PurchaseDocSync: Codeunit "KLT Purchase Doc Sync";
        SourceDocNotFoundErr: Label 'Source document not found';
        SyncFailedErr: Label 'Sync failed';

    /// <summary>
    /// Main entry point for scheduled synchronization
    /// Called by Job Queue
    /// </summary>
    procedure RunScheduledSync()
    var
        APIConfig: Record "KLT API Config";
    begin
        APIConfig.GetInstance();

        if not APIConfig."Enable Sync" then
            exit;

        // Sync outbound documents (Sales to target)
        SyncSalesDocuments();

        // Sync inbound documents (Purchase from target)
        SyncPurchaseDocuments();

        // Process retry queue
        ProcessRetryQueue();
    end;

    /// <summary>
    /// Synchronizes sales documents to target
    /// </summary>
    procedure SyncSalesDocuments()
    var
        APIConfig: Record "KLT API Config";
        SyncQueue: Record "KLT API Sync Queue";
        ProcessedCount: Integer;
    begin
        APIConfig.GetInstance();
        ProcessedCount := 0;

        // Get pending sales invoices from queue
        SyncQueue.SetRange("Document Type", SyncQueue."Document Type"::"Sales Invoice");
        SyncQueue.SetRange(Status, SyncQueue.Status::Pending);
        SyncQueue.SetRange("Sync Direction", SyncQueue."Sync Direction"::Outbound);

        if SyncQueue.FindSet() then begin
            repeat
                if ProcessedCount >= APIConfig."Batch Size" then
                    break;

                if ProcessSalesInvoiceQueue(SyncQueue) then
                    ProcessedCount += 1;

                Commit();
            until SyncQueue.Next() = 0;
        end;

        // Get pending sales credit memos from queue
        ProcessedCount := 0;
        SyncQueue.Reset();
        SyncQueue.SetRange("Document Type", SyncQueue."Document Type"::"Sales Credit Memo");
        SyncQueue.SetRange(Status, SyncQueue.Status::Pending);
        SyncQueue.SetRange("Sync Direction", SyncQueue."Sync Direction"::Outbound);

        if SyncQueue.FindSet() then begin
            repeat
                if ProcessedCount >= APIConfig."Batch Size" then
                    break;

                if ProcessSalesCreditMemoQueue(SyncQueue) then
                    ProcessedCount += 1;

                Commit();
            until SyncQueue.Next() = 0;
        end;
    end;

    /// <summary>
    /// Synchronizes purchase documents from target
    /// </summary>
    procedure SyncPurchaseDocuments()
    var
        DocumentsCreated: Integer;
    begin
        // Sync purchase invoices
        DocumentsCreated := PurchaseDocSync.SyncPurchaseInvoicesFromTarget();

        // Sync purchase credit memos
        DocumentsCreated += PurchaseDocSync.SyncPurchaseCreditMemosFromTarget();
    end;

    /// <summary>
    /// Adds a Posted Sales Invoice to sync queue
    /// </summary>
    procedure QueueSalesInvoice(SalesInvNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SyncQueue: Record "KLT API Sync Queue";
    begin
        if not SalesInvHeader.Get(SalesInvNo) then
            exit;

        // Check if already queued
        SyncQueue.SetRange("Document Type", SyncQueue."Document Type"::"Sales Invoice");
        SyncQueue.SetRange("Document No.", SalesInvNo);
        if not SyncQueue.IsEmpty() then
            exit; // Already queued

        // Add to queue
        SyncQueue.Init();
        SyncQueue."Entry No." := 0;
        SyncQueue."Document Type" := SyncQueue."Document Type"::"Sales Invoice";
        SyncQueue."Document No." := SalesInvNo;
        SyncQueue."Document System ID" := SalesInvHeader.SystemId;
        SyncQueue."Sync Direction" := SyncQueue."Sync Direction"::Outbound;
        SyncQueue.Status := SyncQueue.Status::Pending;
        SyncQueue."Created DateTime" := CurrentDateTime();
        SyncQueue."Created By" := CopyStr(UserId(), 1, MaxStrLen(SyncQueue."Created By"));
        SyncQueue.Priority := 5; // Normal priority
        SyncQueue.Insert(true);
    end;

    /// <summary>
    /// Adds a Posted Sales Credit Memo to sync queue
    /// </summary>
    procedure QueueSalesCreditMemo(SalesCrMemoNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SyncQueue: Record "KLT API Sync Queue";
    begin
        if not SalesCrMemoHeader.Get(SalesCrMemoNo) then
            exit;

        // Check if already queued
        SyncQueue.SetRange("Document Type", SyncQueue."Document Type"::"Sales Credit Memo");
        SyncQueue.SetRange("Document No.", SalesCrMemoNo);
        if not SyncQueue.IsEmpty() then
            exit; // Already queued

        // Add to queue
        SyncQueue.Init();
        SyncQueue."Entry No." := 0;
        SyncQueue."Document Type" := SyncQueue."Document Type"::"Sales Credit Memo";
        SyncQueue."Document No." := SalesCrMemoNo;
        SyncQueue."Document System ID" := SalesCrMemoHeader.SystemId;
        SyncQueue."Sync Direction" := SyncQueue."Sync Direction"::Outbound;
        SyncQueue.Status := SyncQueue.Status::Pending;
        SyncQueue."Created DateTime" := CurrentDateTime();
        SyncQueue."Created By" := CopyStr(UserId(), 1, MaxStrLen(SyncQueue."Created By"));
        SyncQueue.Priority := 5; // Normal priority
        SyncQueue.Insert(true);
    end;

    local procedure ProcessSalesInvoiceQueue(var SyncQueue: Record "KLT API Sync Queue"): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        if not SalesInvHeader.Get(SyncQueue."Document No.") then begin
            MarkQueueItemFailed(SyncQueue, SourceDocNotFoundErr);
            exit(false);
        end;

        // Update status to in progress
        SyncQueue.Status := SyncQueue.Status::"In Progress";
        SyncQueue."Processing Started" := CurrentDateTime();
        SyncQueue.Modify(true);
        Commit();

        // Sync document
        if SalesDocSync.SyncPostedSalesInvoice(SalesInvHeader) then begin
            MarkQueueItemCompleted(SyncQueue);
            exit(true);
        end else begin
            MarkQueueItemFailed(SyncQueue, SyncFailedErr);
            exit(false);
        end;
    end;

    local procedure ProcessSalesCreditMemoQueue(var SyncQueue: Record "KLT API Sync Queue"): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if not SalesCrMemoHeader.Get(SyncQueue."Document No.") then begin
            MarkQueueItemFailed(SyncQueue, SourceDocNotFoundErr);
            exit(false);
        end;

        // Update status to in progress
        SyncQueue.Status := SyncQueue.Status::"In Progress";
        SyncQueue."Processing Started" := CurrentDateTime();
        SyncQueue.Modify(true);
        Commit();

        // Sync document
        if SalesDocSync.SyncPostedSalesCreditMemo(SalesCrMemoHeader) then begin
            MarkQueueItemCompleted(SyncQueue);
            exit(true);
        end else begin
            MarkQueueItemFailed(SyncQueue, SyncFailedErr);
            exit(false);
        end;
    end;

    local procedure MarkQueueItemCompleted(var SyncQueue: Record "KLT API Sync Queue")
    begin
        SyncQueue.Status := SyncQueue.Status::Completed;
        SyncQueue."Processing Ended" := CurrentDateTime();
        SyncQueue."Last Error Message" := '';
        SyncQueue.Modify(true);
    end;

    local procedure MarkQueueItemFailed(var SyncQueue: Record "KLT API Sync Queue"; ErrorMsg: Text)
    begin
        SyncQueue.Status := SyncQueue.Status::Failed;
        SyncQueue."Processing Ended" := CurrentDateTime();
        SyncQueue."Last Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen(SyncQueue."Last Error Message"));
        SyncQueue."Retry Count" := SyncQueue."Retry Count" + 1;

        // Calculate next retry time with exponential backoff
        if SyncQueue."Retry Count" <= 3 then begin
            SyncQueue."Next Retry Time" := CalculateNextRetryTime(SyncQueue."Retry Count");
            SyncQueue.Status := SyncQueue.Status::Retrying;
        end;

        SyncQueue.Modify(true);
    end;

    /// <summary>
    /// Processes items in retry queue
    /// </summary>
    procedure ProcessRetryQueue()
    var
        SyncQueue: Record "KLT API Sync Queue";
        ProcessedCount: Integer;
        APIConfig: Record "KLT API Config";
    begin
        APIConfig.GetInstance();
        ProcessedCount := 0;

        // Get items ready for retry
        SyncQueue.SetRange(Status, SyncQueue.Status::Retrying);
        SyncQueue.SetFilter("Next Retry Time", '<=%1', CurrentDateTime());

        if SyncQueue.FindSet() then begin
            repeat
                if ProcessedCount >= APIConfig."Batch Size" then
                    break;

                // Reset status to pending and reprocess
                SyncQueue.Status := SyncQueue.Status::Pending;
                SyncQueue.Modify(true);
                Commit();

                // Process based on document type
                case SyncQueue."Document Type" of
                    SyncQueue."Document Type"::"Sales Invoice":
                        ProcessSalesInvoiceQueue(SyncQueue);
                    SyncQueue."Document Type"::"Sales Credit Memo":
                        ProcessSalesCreditMemoQueue(SyncQueue);
                end;

                ProcessedCount += 1;
                Commit();
            until SyncQueue.Next() = 0;
        end;
    end;

    local procedure CalculateNextRetryTime(RetryAttempt: Integer): DateTime
    var
        DelayMinutes: Integer;
        MaxDelayMinutes: Integer;
    begin
        MaxDelayMinutes := 60; // Max 60 minutes delay

        // Exponential backoff: 1, 2, 4, 8, ... minutes
        DelayMinutes := Power(2, RetryAttempt - 1);

        if DelayMinutes > MaxDelayMinutes then
            DelayMinutes := MaxDelayMinutes;

        exit(CurrentDateTime() + (DelayMinutes * 60 * 1000)); // Convert to milliseconds
    end;

    /// <summary>
    /// Clears completed queue items older than specified days
    /// </summary>
    procedure CleanupCompletedQueue(DaysToKeep: Integer)
    var
        SyncQueue: Record "KLT API Sync Queue";
        CutoffDateTime: DateTime;
    begin
        CutoffDateTime := CurrentDateTime() - (DaysToKeep * 24 * 60 * 60 * 1000);

        SyncQueue.SetRange(Status, SyncQueue.Status::Completed);
        SyncQueue.SetFilter("Processing Ended", '<%1', CutoffDateTime);
        SyncQueue.DeleteAll(true);
    end;

    /// <summary>
    /// Gets sync statistics for monitoring
    /// </summary>
    procedure GetSyncStatistics(var TotalPending: Integer; var TotalInProgress: Integer; var TotalFailed: Integer; var TotalRetrying: Integer)
    var
        SyncQueue: Record "KLT API Sync Queue";
    begin
        SyncQueue.SetRange(Status, SyncQueue.Status::Pending);
        TotalPending := SyncQueue.Count();

        SyncQueue.SetRange(Status, SyncQueue.Status::"In Progress");
        TotalInProgress := SyncQueue.Count();

        SyncQueue.SetRange(Status, SyncQueue.Status::Failed);
        TotalFailed := SyncQueue.Count();

        SyncQueue.SetRange(Status, SyncQueue.Status::Retrying);
        TotalRetrying := SyncQueue.Count();
    end;

    /// <summary>
    /// Manual sync trigger for a single sales invoice
    /// </summary>
    procedure SyncSalesInvoiceNow(SalesInvNo: Code[20]): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        if not SalesInvHeader.Get(SalesInvNo) then
            exit(false);

        exit(SalesDocSync.SyncPostedSalesInvoice(SalesInvHeader));
    end;

    /// <summary>
    /// Manual sync trigger for a single sales credit memo
    /// </summary>
    procedure SyncSalesCreditMemoNow(SalesCrMemoNo: Code[20]): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if not SalesCrMemoHeader.Get(SalesCrMemoNo) then
            exit(false);

        exit(SalesDocSync.SyncPostedSalesCreditMemo(SalesCrMemoHeader));
    end;

    /// <summary>
    /// Resets failed queue items for retry
    /// </summary>
    procedure ResetFailedQueueItems()
    var
        SyncQueue: Record "KLT API Sync Queue";
    begin
        SyncQueue.SetRange(Status, SyncQueue.Status::Failed);
        if SyncQueue.FindSet() then begin
            repeat
                SyncQueue.Status := SyncQueue.Status::Pending;
                SyncQueue."Retry Count" := 0;
                SyncQueue."Last Error Message" := '';
                SyncQueue."Next Retry Time" := 0DT;
                SyncQueue.Modify(true);
            until SyncQueue.Next() = 0;
        end;
    end;

    /// <summary>
    /// Processes all pending items in the sync queue
    /// </summary>
    procedure ProcessSyncQueue()
    var
        SyncQueue: Record "KLT API Sync Queue";
        APIConfig: Record "KLT API Config";
        ProcessedCount: Integer;
    begin
        APIConfig.GetInstance();
        ProcessedCount := 0;

        // Process pending items
        SyncQueue.SetRange(Status, SyncQueue.Status::Pending);
        SyncQueue.SetCurrentKey(Priority, "Created DateTime");

        if SyncQueue.FindSet() then begin
            repeat
                if ProcessedCount >= APIConfig."Batch Size" then
                    break;

                // Process based on document type
                case SyncQueue."Document Type" of
                    SyncQueue."Document Type"::"Sales Invoice":
                        begin
                            if ProcessSalesInvoiceQueue(SyncQueue) then
                                ProcessedCount += 1;
                        end;
                    SyncQueue."Document Type"::"Sales Credit Memo":
                        begin
                            if ProcessSalesCreditMemoQueue(SyncQueue) then
                                ProcessedCount += 1;
                        end;
                end;

                Commit();
            until SyncQueue.Next() = 0;
        end;
    end;

    /// <summary>
    /// Retry a failed sync from the sync log
    /// </summary>
    procedure RetryFailedSync(var SyncLog: Record "KLT Document Sync Log"): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Increment retry count
        SyncLog.IncrementRetryCount();
        Commit();

        // Retry based on document type and direction
        if SyncLog."Sync Direction" = SyncLog."Sync Direction"::Outbound then begin
            case SyncLog."Document Type" of
                SyncLog."Document Type"::"Sales Invoice":
                    begin
                        if SalesInvHeader.Get(SyncLog."Source Document No.") then
                            exit(SalesDocSync.SyncPostedSalesInvoice(SalesInvHeader));
                    end;
                SyncLog."Document Type"::"Sales Credit Memo":
                    begin
                        if SalesCrMemoHeader.Get(SyncLog."Source Document No.") then
                            exit(SalesDocSync.SyncPostedSalesCreditMemo(SalesCrMemoHeader));
                    end;
            end;
        end;

        exit(false);
    end;
}
