/// <summary>
/// Main synchronization engine that orchestrates document transfers
/// Manages scheduled batch processing and error handling
/// </summary>
codeunit 50104 "KLT Sync Engine"
{
    var
        SalesDocSync: Codeunit "KLT Sales Doc Sync";
        PurchaseDocSync: Codeunit "KLT Purchase Doc Sync";

    /// <summary>
    /// Main entry point for scheduled synchronization
    /// Called by job queue entry
    /// </summary>
    procedure RunScheduledSync()
    var
        APIConfig: Record "KLT API Configuration";
        StartTime: DateTime;
        ErrorCount: Integer;
    begin
        APIConfig.GetInstance();
        
        if not APIConfig."Enable Sync" then
            exit;

        StartTime := CurrentDateTime();
        
        // Run all sync operations
        ErrorCount := 0;
        ErrorCount += RunSyncWithErrorHandling(SyncOperation::SalesInvoices);
        ErrorCount += RunSyncWithErrorHandling(SyncOperation::SalesCreditMemos);
        ErrorCount += RunSyncWithErrorHandling(SyncOperation::PurchaseInvoices);
        ErrorCount += RunSyncWithErrorHandling(SyncOperation::PurchaseCreditMemos);

        // Check error threshold
        CheckErrorThreshold(ErrorCount);

        // Process retry queue
        ProcessRetryQueue();

        // Clean up old logs
        CleanupOldLogs();
    end;

    /// <summary>
    /// Run synchronization for sales invoices only
    /// </summary>
    procedure RunSalesInvoiceSync()
    begin
        SalesDocSync.SyncSalesInvoices();
    end;

    /// <summary>
    /// Run synchronization for sales credit memos only
    /// </summary>
    procedure RunSalesCreditMemoSync()
    begin
        SalesDocSync.SyncSalesCreditMemos();
    end;

    /// <summary>
    /// Run synchronization for purchase invoices only
    /// </summary>
    procedure RunPurchaseInvoiceSync()
    begin
        PurchaseDocSync.SyncPurchaseInvoices();
    end;

    /// <summary>
    /// Run synchronization for purchase credit memos only
    /// </summary>
    procedure RunPurchaseCreditMemoSync()
    begin
        PurchaseDocSync.SyncPurchaseCreditMemos();
    end;

    /// <summary>
    /// Run sync operation with error handling
    /// </summary>
    local procedure RunSyncWithErrorHandling(Operation: Option SalesInvoices,SalesCreditMemos,PurchaseInvoices,PurchaseCreditMemos): Integer
    begin
        if not TryRunSync(Operation) then
            exit(1);
        exit(0);
    end;

    [TryFunction]
    local procedure TryRunSync(Operation: Option SalesInvoices,SalesCreditMemos,PurchaseInvoices,PurchaseCreditMemos)
    begin
        case Operation of
            SyncOperation::SalesInvoices:
                SalesDocSync.SyncSalesInvoices();
            SyncOperation::SalesCreditMemos:
                SalesDocSync.SyncSalesCreditMemos();
            SyncOperation::PurchaseInvoices:
                PurchaseDocSync.SyncPurchaseInvoices();
            SyncOperation::PurchaseCreditMemos:
                PurchaseDocSync.SyncPurchaseCreditMemos();
        end;
    end;

    /// <summary>
    /// Process documents in retry queue
    /// </summary>
    local procedure ProcessRetryQueue()
    var
        SyncError: Record "KLT Document Sync Error";
    begin
        SyncError.SetRange("Can Retry", true);
        SyncError.SetRange(Resolved, false);
        SyncError.SetFilter("Next Retry DateTime", '<=%1', CurrentDateTime());
        
        if SyncError.FindSet() then
            repeat
                RetryDocument(SyncError);
            until SyncError.Next() = 0;
    end;

    /// <summary>
    /// Retry a failed document
    /// </summary>
    local procedure RetryDocument(var SyncError: Record "KLT Document Sync Error")
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        if not SyncLog.Get(SyncError."Sync Log Entry No.") then
            exit;

        SyncError.IncrementRetryCount();

        // Retry logic would go here
        // For now, we just increment the retry count
        // In a full implementation, this would re-execute the sync operation
    end;

    /// <summary>
    /// Check if error rate exceeds threshold and send alert
    /// </summary>
    local procedure CheckErrorThreshold(ErrorCount: Integer)
    var
        APIConfig: Record "KLT API Configuration";
        SyncLog: Record "KLT Document Sync Log";
        TotalCount: Integer;
        ErrorRate: Decimal;
        TimeThreshold: DateTime;
    begin
        APIConfig.GetInstance();
        
        // Calculate error rate for last hour
        TimeThreshold := CurrentDateTime() - (60 * 60 * 1000);
        
        SyncLog.SetFilter("Created DateTime", '>%1', TimeThreshold);
        TotalCount := SyncLog.Count();
        
        if TotalCount = 0 then
            exit;

        SyncLog.SetRange(Status, SyncLog.Status::Failed);
        ErrorRate := (SyncLog.Count() / TotalCount) * 100;

        if ErrorRate > APIConfig."Critical Error Threshold %" then
            SendCriticalAlert(ErrorRate);
    end;

    /// <summary>
    /// Send critical error alert
    /// </summary>
    local procedure SendCriticalAlert(ErrorRate: Decimal)
    var
        APIConfig: Record "KLT API Configuration";
        EmailSubject: Text;
        EmailBody: Text;
    begin
        APIConfig.GetInstance();
        
        if APIConfig."Alert Email Address" = '' then
            exit;

        EmailSubject := 'Critical: Kelteks API Integration Error Rate Exceeded';
        EmailBody := StrSubstNo('The error rate for API synchronization has exceeded the threshold.\n\n' +
                                'Current error rate: %1%\n' +
                                'Threshold: %2%\n\n' +
                                'Please review the Document Sync Error log for details.',
                                Round(ErrorRate, 0.01),
                                APIConfig."Critical Error Threshold %");

        // In production, this would use email functionality
        // For now, we'll just log it
        Message('ALERT: %1\n\n%2', EmailSubject, EmailBody);
    end;

    /// <summary>
    /// Clean up old log entries based on retention policy
    /// </summary>
    local procedure CleanupOldLogs()
    var
        APIConfig: Record "KLT API Configuration";
        SyncLog: Record "KLT Document Sync Log";
        SyncError: Record "KLT Document Sync Error";
        CutoffDate: DateTime;
    begin
        APIConfig.GetInstance();
        
        CutoffDate := CurrentDateTime() - (APIConfig."Log Retention Days" * 24 * 60 * 60 * 1000);

        // Delete old sync logs
        SyncLog.SetFilter("Created DateTime", '<%1', CutoffDate);
        SyncLog.SetRange(Status, SyncLog.Status::Completed);
        SyncLog.DeleteAll(true);

        // Delete old resolved errors
        SyncError.SetFilter("Created DateTime", '<%1', CutoffDate);
        SyncError.SetRange(Resolved, true);
        SyncError.DeleteAll(true);
    end;

    /// <summary>
    /// Create job queue entry for scheduled sync
    /// </summary>
    procedure CreateJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        APIConfig: Record "KLT API Configuration";
    begin
        APIConfig.GetInstance();

        // Check if job queue entry already exists
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"KLT Sync Engine");
        if not JobQueueEntry.IsEmpty() then
            exit;

        // Create new job queue entry
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"KLT Sync Engine";
        JobQueueEntry."Run in User Session" := false;
        JobQueueEntry.Description := 'Kelteks API Document Synchronization';
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."No. of Minutes between Runs" := APIConfig."Sync Interval (Minutes)";
        JobQueueEntry.Insert(true);
        
        Message('Job queue entry created successfully.');
    end;

    /// <summary>
    /// Get synchronization statistics
    /// </summary>
    procedure GetSyncStatistics(var TotalDocs: Integer; var SuccessDocs: Integer; var FailedDocs: Integer; var PendingRetries: Integer)
    var
        SyncLog: Record "KLT Document Sync Log";
        SyncError: Record "KLT Document Sync Error";
    begin
        TotalDocs := SyncLog.Count();
        
        SyncLog.SetRange(Status, SyncLog.Status::Completed);
        SuccessDocs := SyncLog.Count();
        
        SyncLog.Reset();
        SyncLog.SetRange(Status, SyncLog.Status::Failed);
        FailedDocs := SyncLog.Count();
        
        SyncError.SetRange("Can Retry", true);
        SyncError.SetRange(Resolved, false);
        PendingRetries := SyncError.Count();
    end;

    var
        SyncOperation: Option SalesInvoices,SalesCreditMemos,PurchaseInvoices,PurchaseCreditMemos;
}
