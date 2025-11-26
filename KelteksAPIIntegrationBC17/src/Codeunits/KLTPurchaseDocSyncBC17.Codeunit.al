/// <summary>
/// Purchase Document Synchronization for BC17
/// Receives Purchase Invoices and Credit Memos from BC27
/// </summary>
codeunit 50103 "KLT Purchase Doc Sync BC17"
{
    var
        APIHelper: Codeunit "KLT API Helper BC17";
        Validator: Codeunit "KLT Document Validator BC17";

    /// <summary>
    /// Retrieves and creates Purchase Invoices from BC27
    /// </summary>
    procedure SyncPurchaseInvoicesFromBC27(): Integer
    var
        APIConfig: Record "KLT API Config BC17";
        ResponseJson: JsonObject;
        ValueArray: JsonArray;
        Endpoint: Text;
        DocumentsCreated: Integer;
        i: Integer;
    begin
        APIConfig.GetInstance();
        DocumentsCreated := 0;
        
        // Get purchase invoices from BC27
        Endpoint := APIHelper.GetPurchaseInvoiceEndpoint(APIConfig."BC27 Company ID");
        if not APIHelper.SendGetRequest(Endpoint, ResponseJson) then
            exit(0);
        
        // Extract value array
        if not APIHelper.GetValueArray(ResponseJson, ValueArray) then
            exit(0);
        
        // Process each document
        for i := 0 to ValueArray.Count() - 1 do begin
            if CreatePurchaseInvoiceFromJson(ValueArray, i) then
                DocumentsCreated += 1;
            Commit(); // Commit after each document
        end;
        
        exit(DocumentsCreated);
    end;

    /// <summary>
    /// Retrieves and creates Purchase Credit Memos from BC27
    /// </summary>
    procedure SyncPurchaseCreditMemosFromBC27(): Integer
    var
        APIConfig: Record "KLT API Config BC17";
        ResponseJson: JsonObject;
        ValueArray: JsonArray;
        Endpoint: Text;
        DocumentsCreated: Integer;
        i: Integer;
    begin
        APIConfig.GetInstance();
        DocumentsCreated := 0;
        
        // Get purchase credit memos from BC27
        Endpoint := APIHelper.GetPurchaseCreditMemoEndpoint(APIConfig."BC27 Company ID");
        if not APIHelper.SendGetRequest(Endpoint, ResponseJson) then
            exit(0);
        
        // Extract value array
        if not APIHelper.GetValueArray(ResponseJson, ValueArray) then
            exit(0);
        
        // Process each document
        for i := 0 to ValueArray.Count() - 1 do begin
            if CreatePurchaseCreditMemoFromJson(ValueArray, i) then
                DocumentsCreated += 1;
            Commit(); // Commit after each document
        end;
        
        exit(DocumentsCreated);
    end;

    local procedure CreatePurchaseInvoiceFromJson(var ValueArray: JsonArray; Index: Integer): Boolean
    var
        PurchHeader: Record "Purchase Header";
        DocJson: JsonObject;
        DocToken: JsonToken;
        VendorNo: Code[20];
        ExternalDocNo: Code[35];
        ErrorText: Text;
        SyncLogEntryNo: Integer;
    begin
        // Get document JSON
        ValueArray.Get(Index, DocToken);
        DocJson := DocToken.AsObject();
        
        // Get vendor and external doc no for duplicate check
        VendorNo := CopyStr(APIHelper.GetJsonText(DocJson, 'vendorNumber'), 1, MaxStrLen(VendorNo));
        ExternalDocNo := CopyStr(APIHelper.GetJsonText(DocJson, 'externalDocumentNumber'), 1, MaxStrLen(ExternalDocNo));
        
        // Create sync log
        SyncLogEntryNo := CreateSyncLog(ExternalDocNo, APIHelper.GetJsonDate(DocJson, 'invoiceDate'),
            "KLT Document Type"::PurchaseInvoice, "KLT Sync Direction"::Inbound);
        
        // Validate data
        if not Validator.ValidatePurchaseInvoiceData(DocJson, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Check for duplicates
        if not Validator.CheckDuplicatePurchaseInvoice(ExternalDocNo, VendorNo, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Create purchase invoice header
        if not CreatePurchaseInvoiceHeader(DocJson, PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::BusinessLogic);
            exit(false);
        end;
        
        // Create purchase invoice lines
        if not CreatePurchaseInvoiceLines(DocJson, PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::BusinessLogic);
            exit(false);
        end;
        
        // Update sync log as completed
        UpdateSyncLogCompleted(SyncLogEntryNo, PurchHeader."No.");
        exit(true);
    end;

    local procedure CreatePurchaseCreditMemoFromJson(var ValueArray: JsonArray; Index: Integer): Boolean
    var
        PurchHeader: Record "Purchase Header";
        DocJson: JsonObject;
        DocToken: JsonToken;
        VendorNo: Code[20];
        ExternalDocNo: Code[35];
        ErrorText: Text;
        SyncLogEntryNo: Integer;
    begin
        // Get document JSON
        ValueArray.Get(Index, DocToken);
        DocJson := DocToken.AsObject();
        
        // Get vendor and external doc no for duplicate check
        VendorNo := CopyStr(APIHelper.GetJsonText(DocJson, 'vendorNumber'), 1, MaxStrLen(VendorNo));
        ExternalDocNo := CopyStr(APIHelper.GetJsonText(DocJson, 'externalDocumentNumber'), 1, MaxStrLen(ExternalDocNo));
        
        // Create sync log
        SyncLogEntryNo := CreateSyncLog(ExternalDocNo, APIHelper.GetJsonDate(DocJson, 'creditMemoDate'),
            "KLT Document Type"::PurchaseCreditMemo, "KLT Sync Direction"::Inbound);
        
        // Validate data
        if not Validator.ValidatePurchaseCreditMemoData(DocJson, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Check for duplicates
        if not Validator.CheckDuplicatePurchaseCreditMemo(ExternalDocNo, VendorNo, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Create purchase credit memo header
        if not CreatePurchaseCreditMemoHeader(DocJson, PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::BusinessLogic);
            exit(false);
        end;
        
        // Create purchase credit memo lines
        if not CreatePurchaseCreditMemoLines(DocJson, PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::BusinessLogic);
            exit(false);
        end;
        
        // Update sync log as completed
        UpdateSyncLogCompleted(SyncLogEntryNo, PurchHeader."No.");
        exit(true);
    end;

    local procedure CreatePurchaseInvoiceHeader(DocJson: JsonObject; var PurchHeader: Record "Purchase Header"; var ErrorText: Text): Boolean
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        VendorNo := CopyStr(APIHelper.GetJsonText(DocJson, 'vendorNumber'), 1, MaxStrLen(VendorNo));
        
        if not Vendor.Get(VendorNo) then begin
            ErrorText := StrSubstNo('Vendor %1 not found', VendorNo);
            exit(false);
        end;
        
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        PurchHeader.Insert(true);
        
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Validate("Posting Date", APIHelper.GetJsonDate(DocJson, 'postingDate'));
        PurchHeader.Validate("Document Date", APIHelper.GetJsonDate(DocJson, 'invoiceDate'));
        PurchHeader.Validate("Due Date", APIHelper.GetJsonDate(DocJson, 'dueDate'));
        PurchHeader.Validate("Vendor Invoice No.", CopyStr(APIHelper.GetJsonText(DocJson, 'externalDocumentNumber'), 1, MaxStrLen(PurchHeader."Vendor Invoice No.")));
        
        // Currency
        if APIHelper.GetJsonText(DocJson, 'currencyCode') <> '' then
            PurchHeader.Validate("Currency Code", CopyStr(APIHelper.GetJsonText(DocJson, 'currencyCode'), 1, MaxStrLen(PurchHeader."Currency Code")));
        
        // Payment terms
        if APIHelper.GetJsonText(DocJson, 'paymentTermsCode') <> '' then
            PurchHeader.Validate("Payment Terms Code", CopyStr(APIHelper.GetJsonText(DocJson, 'paymentTermsCode'), 1, MaxStrLen(PurchHeader."Payment Terms Code")));
        
        PurchHeader.Modify(true);
        exit(true);
    end;

    local procedure CreatePurchaseCreditMemoHeader(DocJson: JsonObject; var PurchHeader: Record "Purchase Header"; var ErrorText: Text): Boolean
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        VendorNo := CopyStr(APIHelper.GetJsonText(DocJson, 'vendorNumber'), 1, MaxStrLen(VendorNo));
        
        if not Vendor.Get(VendorNo) then begin
            ErrorText := StrSubstNo('Vendor %1 not found', VendorNo);
            exit(false);
        end;
        
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::"Credit Memo";
        PurchHeader.Insert(true);
        
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Validate("Posting Date", APIHelper.GetJsonDate(DocJson, 'postingDate'));
        PurchHeader.Validate("Document Date", APIHelper.GetJsonDate(DocJson, 'creditMemoDate'));
        PurchHeader.Validate("Due Date", APIHelper.GetJsonDate(DocJson, 'dueDate'));
        PurchHeader.Validate("Vendor Cr. Memo No.", CopyStr(APIHelper.GetJsonText(DocJson, 'externalDocumentNumber'), 1, MaxStrLen(PurchHeader."Vendor Cr. Memo No.")));
        
        // Currency
        if APIHelper.GetJsonText(DocJson, 'currencyCode') <> '' then
            PurchHeader.Validate("Currency Code", CopyStr(APIHelper.GetJsonText(DocJson, 'currencyCode'), 1, MaxStrLen(PurchHeader."Currency Code")));
        
        // Payment terms
        if APIHelper.GetJsonText(DocJson, 'paymentTermsCode') <> '' then
            PurchHeader.Validate("Payment Terms Code", CopyStr(APIHelper.GetJsonText(DocJson, 'paymentTermsCode'), 1, MaxStrLen(PurchHeader."Payment Terms Code")));
        
        PurchHeader.Modify(true);
        exit(true);
    end;

    local procedure CreatePurchaseInvoiceLines(DocJson: JsonObject; var PurchHeader: Record "Purchase Header"; var ErrorText: Text): Boolean
    var
        PurchLine: Record "Purchase Line";
        LinesToken: JsonToken;
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineJson: JsonObject;
        i: Integer;
    begin
        // Get lines array
        if not DocJson.Get('purchaseInvoiceLines', LinesToken) then
            exit(true); // No lines is valid
        
        if not LinesToken.IsArray() then begin
            ErrorText := 'Purchase invoice lines is not an array';
            exit(false);
        end;
        
        LinesArray := LinesToken.AsArray();
        
        for i := 0 to LinesArray.Count() - 1 do begin
            LinesArray.Get(i, LineToken);
            LineJson := LineToken.AsObject();
            
            // Validate line
            if not Validator.ValidateLineData(LineJson, ErrorText) then
                exit(false);
            
            // Create line
            if not CreatePurchaseLine(PurchHeader, LineJson, PurchLine, ErrorText) then
                exit(false);
        end;
        
        exit(true);
    end;

    local procedure CreatePurchaseCreditMemoLines(DocJson: JsonObject; var PurchHeader: Record "Purchase Header"; var ErrorText: Text): Boolean
    var
        PurchLine: Record "Purchase Line";
        LinesToken: JsonToken;
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineJson: JsonObject;
        i: Integer;
    begin
        // Get lines array
        if not DocJson.Get('purchaseCreditMemoLines', LinesToken) then
            exit(true); // No lines is valid
        
        if not LinesToken.IsArray() then begin
            ErrorText := 'Purchase credit memo lines is not an array';
            exit(false);
        end;
        
        LinesArray := LinesToken.AsArray();
        
        for i := 0 to LinesArray.Count() - 1 do begin
            LinesArray.Get(i, LineToken);
            LineJson := LineToken.AsObject();
            
            // Validate line
            if not Validator.ValidateLineData(LineJson, ErrorText) then
                exit(false);
            
            // Create line
            if not CreatePurchaseLine(PurchHeader, LineJson, PurchLine, ErrorText) then
                exit(false);
        end;
        
        exit(true);
    end;

    local procedure CreatePurchaseLine(var PurchHeader: Record "Purchase Header"; LineJson: JsonObject; var PurchLine: Record "Purchase Line"; var ErrorText: Text): Boolean
    var
        LineTypeText: Text;
        LineType: Enum "Purchase Line Type";
    begin
        PurchLine.Init();
        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := GetNextLineNo(PurchHeader);
        
        // Parse line type
        LineTypeText := APIHelper.GetJsonText(LineJson, 'lineType');
        if not ParseLineType(LineTypeText, LineType) then begin
            ErrorText := StrSubstNo('Invalid line type: %1', LineTypeText);
            exit(false);
        end;
        
        PurchLine.Insert(true);
        PurchLine.Validate(Type, LineType);
        
        // Only set No. for non-comment lines
        if LineType <> LineType::" " then
            PurchLine.Validate("No.", CopyStr(APIHelper.GetJsonText(LineJson, 'number'), 1, MaxStrLen(PurchLine."No.")));
        
        PurchLine.Validate(Description, CopyStr(APIHelper.GetJsonText(LineJson, 'description'), 1, MaxStrLen(PurchLine.Description)));
        PurchLine.Validate(Quantity, APIHelper.GetJsonDecimal(LineJson, 'quantity'));
        PurchLine.Validate("Direct Unit Cost", APIHelper.GetJsonDecimal(LineJson, 'unitCost'));
        PurchLine.Validate("Line Discount %", APIHelper.GetJsonDecimal(LineJson, 'lineDiscount'));
        
        PurchLine.Modify(true);
        exit(true);
    end;

    local procedure GetNextLineNo(var PurchHeader: Record "Purchase Header"): Integer
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindLast() then
            exit(PurchLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure ParseLineType(LineTypeText: Text; var LineType: Enum "Purchase Line Type"): Boolean
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

    local procedure CreateSyncLog(DocumentNo: Code[20]; DocumentDate: Date; DocType: Enum "KLT Document Type"; Direction: Enum "KLT Sync Direction"): Integer
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        SyncLog.Init();
        SyncLog."Entry No." := 0;
        SyncLog."Document Type" := DocType;
        SyncLog."Source Document No." := DocumentNo;
        SyncLog."Document Date" := DocumentDate;
        SyncLog."Sync Direction" := Direction;
        SyncLog.Status := SyncLog.Status::InProgress;
        SyncLog."Sync Start Time" := CurrentDateTime();
        SyncLog."User ID" := CopyStr(UserId(), 1, MaxStrLen(SyncLog."User ID"));
        SyncLog.Insert(true);
        exit(SyncLog."Entry No.");
    end;

    local procedure UpdateSyncLogCompleted(EntryNo: Integer; TargetDocNo: Code[20])
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        if SyncLog.Get(EntryNo) then begin
            SyncLog.Status := SyncLog.Status::Completed;
            SyncLog."Sync End Time" := CurrentDateTime();
            SyncLog."Target Document No." := TargetDocNo;
            SyncLog."Last Error Message" := '';
            SyncLog."Error Category" := SyncLog."Error Category"::" ";
            SyncLog.Modify(true);
        end;
    end;

    local procedure UpdateSyncLogError(EntryNo: Integer; ErrorMsg: Text; ErrorCat: Enum "KLT Error Category")
    var
        SyncLog: Record "KLT Document Sync Log";
        ErrorMessage: Record "Error Message";
    begin
        if SyncLog.Get(EntryNo) then begin
            SyncLog.Status := SyncLog.Status::Failed;
            SyncLog."Sync End Time" := CurrentDateTime();
            SyncLog."Last Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen(SyncLog."Last Error Message"));
            SyncLog."Error Category" := ErrorCat;
            SyncLog."Retry Count" := SyncLog."Retry Count" + 1;
            SyncLog.Modify(true);
            
            // Log to Error Message table
            ErrorMessage.Init();
            ErrorMessage."Context Record ID" := SyncLog.RecordId;
            ErrorMessage.Description := CopyStr(ErrorMsg, 1, MaxStrLen(ErrorMessage.Description));
            ErrorMessage."Message" := CopyStr(ErrorMsg, 1, MaxStrLen(ErrorMessage."Message"));
            ErrorMessage."Created On" := CurrentDateTime();
            if ErrorMessage.Insert() then;
        end;
    end;
}
