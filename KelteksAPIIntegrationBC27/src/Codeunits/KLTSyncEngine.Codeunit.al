/// <summary>
/// Sync Engine for BC27
/// Orchestrates document synchronization with job queue, retry logic, and batch processing
/// </summary>
codeunit 50105 "KLT Sync Engine"
{
    var
        SalesDocSync: Codeunit "KLT Sales Doc Sync";
        PurchaseDocSync: Codeunit "KLT Purchase Doc Sync";

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
        
        // Sync outbound documents (Purchase to target)
        SyncPurchaseDocuments();
        
        // Sync inbound documents (Sales from target)
        SyncSalesDocuments();
        
        // Process retry queue
        ProcessRetryQueue();
    end;

    /// <summary>
    /// Synchronizes purchase documents to target
    /// </summary>
    procedure SyncPurchaseDocuments()
    var
        APIConfig: Record "KLT API Config";
        SyncQueue: Record "KLT API Sync Queue";
        ProcessedCount: Integer;
    begin
        APIConfig.GetInstance();
        ProcessedCount := 0;
        
        // Get pending purchase invoices from queue
        SyncQueue.SetRange("Document Type", SyncQueue."Document Type"::PurchaseInvoice);
        SyncQueue.SetRange(Status, SyncQueue.Status::Pending);
        SyncQueue.SetRange("Sync Direction", SyncQueue."Sync Direction"::Outbound);
        
        if SyncQueue.FindSet() then begin
            repeat
                if ProcessedCount >= APIConfig."Batch Size" then
                    break;
                
                if ProcessPurchaseInvoiceQueue(SyncQueue) then
                    ProcessedCount += 1;
                
                Commit();
            until SyncQueue.Next() = 0;
        end;
        
        // Get pending purchase credit memos from queue
        ProcessedCount := 0;
        SyncQueue.Reset();
        SyncQueue.SetRange("Document Type", SyncQueue."Document Type"::PurchaseCreditMemo);
        SyncQueue.SetRange(Status, SyncQueue.Status::Pending);
        SyncQueue.SetRange("Sync Direction", SyncQueue."Sync Direction"::Outbound);
        
        if SyncQueue.FindSet() then begin
            repeat
                if ProcessedCount >= APIConfig."Batch Size" then
                    break;
                
                if ProcessPurchaseCreditMemoQueue(SyncQueue) then
                    ProcessedCount += 1;
                
                Commit();
            until SyncQueue.Next() = 0;
        end;
    end;

    /// <summary>
    /// Synchronizes sales documents from target
    /// </summary>
    procedure SyncSalesDocuments()
    var
        DocumentsCreated: Integer;
    begin
        // Sync sales invoices
        DocumentsCreated := SalesDocSync.SyncSalesInvoicesFromTarget();
        
        // Sync sales credit memos
        DocumentsCreated += SalesDocSync.SyncSalesCreditMemosFromTarget();
    end;

    /// <summary>
    /// Adds a Purchase Invoice to sync queue
    /// </summary>
    procedure QueuePurchaseInvoice(PurchInvNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
        SyncQueue: Record "KLT API Sync Queue";
    begin
        if not PurchHeader.Get(PurchHeader."Document Type"::Invoice, PurchInvNo) then
            exit;
        
        // Check if already in queue
        SyncQueue.SetRange("Document Type", SyncQueue."Document Type"::PurchaseInvoice);
        SyncQueue.SetRange("Source Document No.", PurchInvNo);
        if not SyncQueue.IsEmpty() then
            exit; // Already queued
        
        // Add to queue
        SyncQueue.Init();
        SyncQueue."Entry No." := 0;
        SyncQueue."Document Type" := SyncQueue."Document Type"::PurchaseInvoice;
        SyncQueue."Source Document No." := PurchInvNo;
        SyncQueue."Document Date" := PurchHeader."Posting Date";
        SyncQueue."Sync Direction" := SyncQueue."Sync Direction"::Outbound;
        SyncQueue.Status := SyncQueue.Status::Pending;
        SyncQueue."Created DateTime" := CurrentDateTime();
        SyncQueue."Created By" := CopyStr(UserId(), 1, MaxStrLen(SyncQueue."Created By"));
        SyncQueue.Priority := 5; // Normal priority
        SyncQueue.Insert(true);
    end;

    /// <summary>
    /// Adds a Purchase Credit Memo to sync queue
    /// </summary>
    procedure QueuePurchaseCreditMemo(PurchCrMemoNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
        SyncQueue: Record "KLT API Sync Queue";
    begin
        if not PurchHeader.Get(PurchHeader."Document Type"::"Credit Memo", PurchCrMemoNo) then
            exit;
        
        // Check if already in queue
        SyncQueue.SetRange("Document Type", SyncQueue."Document Type"::PurchaseCreditMemo);
        SyncQueue.SetRange("Source Document No.", PurchCrMemoNo);
        if not SyncQueue.IsEmpty() then
            exit; // Already queued
        
        // Add to queue
        SyncQueue.Init();
        SyncQueue."Entry No." := 0;
        SyncQueue."Document Type" := SyncQueue."Document Type"::PurchaseCreditMemo;
        SyncQueue."Source Document No." := PurchCrMemoNo;
        SyncQueue."Document Date" := PurchHeader."Posting Date";
        SyncQueue."Sync Direction" := SyncQueue."Sync Direction"::Outbound;
        SyncQueue.Status := SyncQueue.Status::Pending;
        SyncQueue."Created DateTime" := CurrentDateTime();
        SyncQueue."Created By" := CopyStr(UserId(), 1, MaxStrLen(SyncQueue."Created By"));
        SyncQueue.Priority := 5; // Normal priority
        SyncQueue.Insert(true);
    end;

    local procedure ProcessPurchaseInvoiceQueue(var SyncQueue: Record "KLT API Sync Queue"): Boolean
    var
        PurchHeader: Record "Purchase Header";
    begin
        if not PurchHeader.Get(PurchHeader."Document Type"::Invoice, SyncQueue."Source Document No.") then begin
            MarkQueueItemFailed(SyncQueue, 'Source document not found');
            exit(false);
        end;
        
        // Update status to in progress
        SyncQueue.Status := SyncQueue.Status::InProgress;
        SyncQueue."Processing Start Time" := CurrentDateTime();
        SyncQueue.Modify(true);
        Commit();
        
        // Sync document
        if PurchaseDocSync.SyncPurchaseInvoice(PurchHeader) then begin
            MarkQueueItemCompleted(SyncQueue);
            exit(true);
        end else begin
            MarkQueueItemFailed(SyncQueue, 'Sync failed');
            exit(false);
        end;
    end;

    local procedure ProcessPurchaseCreditMemoQueue(var SyncQueue: Record "KLT API Sync Queue"): Boolean
    var
        PurchHeader: Record "Purchase Header";
    begin
        if not PurchHeader.Get(PurchHeader."Document Type"::"Credit Memo", SyncQueue."Source Document No.") then begin
            MarkQueueItemFailed(SyncQueue, 'Source document not found');
            exit(false);
        end;
        
        // Update status to in progress
        SyncQueue.Status := SyncQueue.Status::InProgress;
        SyncQueue."Processing Start Time" := CurrentDateTime();
        SyncQueue.Modify(true);
        Commit();
        
        // Sync document
        if PurchaseDocSync.SyncPurchaseCreditMemo(PurchHeader) then begin
            MarkQueueItemCompleted(SyncQueue);
            exit(true);
        end else begin
            MarkQueueItemFailed(SyncQueue, 'Sync failed');
            exit(false);
        end;
    end;

    local procedure MarkQueueItemCompleted(var SyncQueue: Record "KLT API Sync Queue")
    begin
        SyncQueue.Status := SyncQueue.Status::Completed;
        SyncQueue."Processing End Time" := CurrentDateTime();
        SyncQueue."Last Error Message" := '';
        SyncQueue.Modify(true);
    end;

    local procedure MarkQueueItemFailed(var SyncQueue: Record "KLT API Sync Queue"; ErrorMsg: Text)
    begin
        SyncQueue.Status := SyncQueue.Status::Failed;
        SyncQueue."Processing End Time" := CurrentDateTime();
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
                    SyncQueue."Document Type"::PurchaseInvoice:
                        ProcessPurchaseInvoiceQueue(SyncQueue);
                    SyncQueue."Document Type"::PurchaseCreditMemo:
                        ProcessPurchaseCreditMemoQueue(SyncQueue);
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
        SyncQueue.SetFilter("Processing End Time", '<%1', CutoffDateTime);
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
        
        SyncQueue.SetRange(Status, SyncQueue.Status::InProgress);
        TotalInProgress := SyncQueue.Count();
        
        SyncQueue.SetRange(Status, SyncQueue.Status::Failed);
        TotalFailed := SyncQueue.Count();
        
        SyncQueue.SetRange(Status, SyncQueue.Status::Retrying);
        TotalRetrying := SyncQueue.Count();
    end;

    /// <summary>
    /// Manual sync trigger for a single purchase invoice
    /// </summary>
    procedure SyncPurchaseInvoiceNow(PurchInvNo: Code[20]): Boolean
    var
        PurchHeader: Record "Purchase Header";
    begin
        if not PurchHeader.Get(PurchHeader."Document Type"::Invoice, PurchInvNo) then
            exit(false);
        
        exit(PurchaseDocSync.SyncPurchaseInvoice(PurchHeader));
    end;

    /// <summary>
    /// Manual sync trigger for a single purchase credit memo
    /// </summary>
    procedure SyncPurchaseCreditMemoNow(PurchCrMemoNo: Code[20]): Boolean
    var
        PurchHeader: Record "Purchase Header";
    begin
        if not PurchHeader.Get(PurchHeader."Document Type"::"Credit Memo", PurchCrMemoNo) then
            exit(false);
        
        exit(PurchaseDocSync.SyncPurchaseCreditMemo(PurchHeader));
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
}
