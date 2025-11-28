/// <summary>
/// Base Sync Helper - Common sync log and error handling operations
/// Used by both Sales and Purchase sync codeunits
/// </summary>
codeunit 80108 "KLT Base Sync Helper"
{
    /// <summary>
    /// Creates a new sync log entry
    /// </summary>
    procedure CreateSyncLog(DocumentNo: Code[35]; DocumentDate: Date; DocType: Enum "KLT Document Type"; Direction: Enum "KLT Sync Direction"): Integer
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        SyncLog.Init();
        SyncLog."Entry No." := 0; // Auto-increment
        SyncLog."Document Type" := DocType;
        if Direction = Direction::Outbound then
            SyncLog."Source Document No." := DocumentNo
        else
            SyncLog."External Document No." := DocumentNo;
        SyncLog."Sync Direction" := Direction;
        SyncLog.Status := SyncLog.Status::"In Progress";
        SyncLog."Started DateTime" := CurrentDateTime();
        SyncLog."Created By" := CopyStr(UserId(), 1, MaxStrLen(SyncLog."Created By"));
        SyncLog.Insert(true);
        exit(SyncLog."Entry No.");
    end;

    /// <summary>
    /// Updates sync log as completed
    /// </summary>
    procedure UpdateSyncLogCompleted(EntryNo: Integer; TargetDocId: Text)
    var
        SyncLog: Record "KLT Document Sync Log";
        TargetGuid: Guid;
    begin
        if SyncLog.Get(EntryNo) then begin
            SyncLog.Status := SyncLog.Status::Completed;
            SyncLog."Completed DateTime" := CurrentDateTime();
            // Try to convert target doc ID to GUID if valid
            if Evaluate(TargetGuid, TargetDocId) then
                SyncLog."Target System ID" := TargetGuid
            else
                SyncLog."Target Document No." := CopyStr(TargetDocId, 1, MaxStrLen(SyncLog."Target Document No."));
            SyncLog."Error Message" := '';
            SyncLog.Modify(true);
        end;
    end;

    /// <summary>
    /// Updates sync log with error
    /// </summary>
    procedure UpdateSyncLogError(EntryNo: Integer; ErrorMsg: Text; ErrorCat: Enum "KLT Error Category")
    var
        SyncLog: Record "KLT Document Sync Log";
        ErrorMessage: Record "Error Message";
    begin
        if SyncLog.Get(EntryNo) then begin
            SyncLog.Status := SyncLog.Status::Failed;
            SyncLog."Completed DateTime" := CurrentDateTime();
            SyncLog."Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen(SyncLog."Error Message"));
            SyncLog."Retry Count" := SyncLog."Retry Count" + 1;
            SyncLog.Modify(true);

            // Log error to Error Message table
            ErrorMessage.LogMessage(
                SyncLog,
                SyncLog.FieldNo("Error Message"),
                ErrorMessage."Message Type"::Error,
                CopyStr(ErrorMsg, 1, 250));
        end;
    end;

    /// <summary>
    /// Gets the next line number for a document
    /// </summary>
    procedure GetNextSalesLineNo(var SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            exit(SalesLine."Line No." + 10000);
        exit(10000);
    end;

    /// <summary>
    /// Gets the next line number for a purchase document
    /// </summary>
    procedure GetNextPurchaseLineNo(var PurchHeader: Record "Purchase Header"): Integer
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindLast() then
            exit(PurchLine."Line No." + 10000);
        exit(10000);
    end;

    /// <summary>
    /// Parses line type from text to Sales Line Type enum
    /// </summary>
    procedure ParseSalesLineType(LineTypeText: Text; var LineType: Enum "Sales Line Type"): Boolean
    begin
        case LineTypeText of
            'Item':
                LineType := LineType::Item;
            'G/L Account', 'Account':
                LineType := LineType::"G/L Account";
            'Resource':
                LineType := LineType::Resource;
            'Fixed Asset':
                LineType := LineType::"Fixed Asset";
            'Charge (Item)':
                LineType := LineType::"Charge (Item)";
            'Comment', ' ':
                LineType := LineType::" ";
            else
                exit(false);
        end;
        exit(true);
    end;

    /// <summary>
    /// Parses line type from text to Purchase Line Type enum
    /// </summary>
    procedure ParsePurchaseLineType(LineTypeText: Text; var LineType: Enum "Purchase Line Type"): Boolean
    begin
        case LineTypeText of
            'Item':
                LineType := LineType::Item;
            'G/L Account', 'Account':
                LineType := LineType::"G/L Account";
            'Resource':
                LineType := LineType::Resource;
            'Fixed Asset':
                LineType := LineType::"Fixed Asset";
            'Charge (Item)':
                LineType := LineType::"Charge (Item)";
            'Comment', ' ':
                LineType := LineType::" ";
            else
                exit(false);
        end;
        exit(true);
    end;
}
