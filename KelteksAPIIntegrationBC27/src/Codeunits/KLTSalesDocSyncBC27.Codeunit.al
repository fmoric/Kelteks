/// <summary>
/// Sales Document Synchronization for BC27
/// Receives Sales Invoices and Credit Memos from BC17
/// </summary>
codeunit 50153 "KLT Sales Doc Sync"
{
    var
        APIHelper: Codeunit "KLT API Helper";
        Validator: Codeunit "KLT Document Validator";

    /// <summary>
    /// Retrieves and creates Sales Invoices from BC17
    /// </summary>
    procedure SyncSalesInvoicesFromBC17(): Integer
    var
        APIConfig: Record "KLT API Config BC27";
        ResponseJson: JsonObject;
        ValueArray: JsonArray;
        Endpoint: Text;
        DocumentsCreated: Integer;
        i: Integer;
    begin
        APIConfig.GetInstance();
        DocumentsCreated := 0;
        
        // Get sales invoices from BC17
        Endpoint := APIHelper.GetSalesInvoiceEndpoint(APIConfig."BC17 Company ID");
        if not APIHelper.SendGetRequest(Endpoint, ResponseJson) then
            exit(0);
        
        // Extract value array
        if not APIHelper.GetValueArray(ResponseJson, ValueArray) then
            exit(0);
        
        // Process each document
        for i := 0 to ValueArray.Count() - 1 do begin
            if CreateSalesInvoiceFromJson(ValueArray, i) then
                DocumentsCreated += 1;
            Commit(); // Commit after each document
        end;
        
        exit(DocumentsCreated);
    end;

    /// <summary>
    /// Retrieves and creates Sales Credit Memos from BC17
    /// </summary>
    procedure SyncSalesCreditMemosFromBC17(): Integer
    var
        APIConfig: Record "KLT API Config BC27";
        ResponseJson: JsonObject;
        ValueArray: JsonArray;
        Endpoint: Text;
        DocumentsCreated: Integer;
        i: Integer;
    begin
        APIConfig.GetInstance();
        DocumentsCreated := 0;
        
        // Get sales credit memos from BC17
        Endpoint := APIHelper.GetSalesCreditMemoEndpoint(APIConfig."BC17 Company ID");
        if not APIHelper.SendGetRequest(Endpoint, ResponseJson) then
            exit(0);
        
        // Extract value array
        if not APIHelper.GetValueArray(ResponseJson, ValueArray) then
            exit(0);
        
        // Process each document
        for i := 0 to ValueArray.Count() - 1 do begin
            if CreateSalesCreditMemoFromJson(ValueArray, i) then
                DocumentsCreated += 1;
            Commit(); // Commit after each document
        end;
        
        exit(DocumentsCreated);
    end;

    local procedure CreateSalesInvoiceFromJson(var ValueArray: JsonArray; Index: Integer): Boolean
    var
        SalesHeader: Record "Sales Header";
        DocJson: JsonObject;
        DocToken: JsonToken;
        CustomerNo: Code[20];
        ExternalDocNo: Code[35];
        ErrorText: Text;
        SyncLogEntryNo: Integer;
    begin
        // Get document JSON
        ValueArray.Get(Index, DocToken);
        DocJson := DocToken.AsObject();
        
        // Get customer and external doc no for duplicate check
        CustomerNo := CopyStr(APIHelper.GetJsonText(DocJson, 'customerNumber'), 1, MaxStrLen(CustomerNo));
        ExternalDocNo := CopyStr(APIHelper.GetJsonText(DocJson, 'externalDocumentNumber'), 1, MaxStrLen(ExternalDocNo));
        
        // Create sync log
        SyncLogEntryNo := CreateSyncLog(ExternalDocNo, APIHelper.GetJsonDate(DocJson, 'invoiceDate'),
            "KLT Document Type"::SalesInvoice, "KLT Sync Direction"::Inbound);
        
        // Validate data
        if not Validator.ValidateSalesInvoiceData(DocJson, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Check for duplicates
        if not Validator.CheckDuplicateSalesInvoice(ExternalDocNo, CustomerNo, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Create sales invoice header
        if not CreateSalesInvoiceHeader(DocJson, SalesHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::BusinessLogic);
            exit(false);
        end;
        
        // Create sales invoice lines
        if not CreateSalesInvoiceLines(DocJson, SalesHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::BusinessLogic);
            exit(false);
        end;
        
        // Update sync log as completed
        UpdateSyncLogCompleted(SyncLogEntryNo, SalesHeader."No.");
        exit(true);
    end;

    local procedure CreateSalesCreditMemoFromJson(var ValueArray: JsonArray; Index: Integer): Boolean
    var
        SalesHeader: Record "Sales Header";
        DocJson: JsonObject;
        DocToken: JsonToken;
        CustomerNo: Code[20];
        ExternalDocNo: Code[35];
        ErrorText: Text;
        SyncLogEntryNo: Integer;
    begin
        // Get document JSON
        ValueArray.Get(Index, DocToken);
        DocJson := DocToken.AsObject();
        
        // Get customer and external doc no for duplicate check
        CustomerNo := CopyStr(APIHelper.GetJsonText(DocJson, 'customerNumber'), 1, MaxStrLen(CustomerNo));
        ExternalDocNo := CopyStr(APIHelper.GetJsonText(DocJson, 'externalDocumentNumber'), 1, MaxStrLen(ExternalDocNo));
        
        // Create sync log
        SyncLogEntryNo := CreateSyncLog(ExternalDocNo, APIHelper.GetJsonDate(DocJson, 'creditMemoDate'),
            "KLT Document Type"::SalesCreditMemo, "KLT Sync Direction"::Inbound);
        
        // Validate data
        if not Validator.ValidateSalesCreditMemoData(DocJson, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Check for duplicates
        if not Validator.CheckDuplicateSalesCreditMemo(ExternalDocNo, CustomerNo, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Create sales credit memo header
        if not CreateSalesCreditMemoHeader(DocJson, SalesHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::BusinessLogic);
            exit(false);
        end;
        
        // Create sales credit memo lines
        if not CreateSalesCreditMemoLines(DocJson, SalesHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::BusinessLogic);
            exit(false);
        end;
        
        // Update sync log as completed
        UpdateSyncLogCompleted(SyncLogEntryNo, SalesHeader."No.");
        exit(true);
    end;

    local procedure CreateSalesInvoiceHeader(DocJson: JsonObject; var SalesHeader: Record "Sales Header"; var ErrorText: Text): Boolean
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        CustomerNo := CopyStr(APIHelper.GetJsonText(DocJson, 'customerNumber'), 1, MaxStrLen(CustomerNo));
        
        if not Customer.Get(CustomerNo) then begin
            ErrorText := StrSubstNo('Customer %1 not found', CustomerNo);
            exit(false);
        end;
        
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Insert(true);
        
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Validate("Posting Date", APIHelper.GetJsonDate(DocJson, 'postingDate'));
        SalesHeader.Validate("Document Date", APIHelper.GetJsonDate(DocJson, 'invoiceDate'));
        SalesHeader.Validate("Due Date", APIHelper.GetJsonDate(DocJson, 'dueDate'));
        SalesHeader.Validate("External Document No.", CopyStr(APIHelper.GetJsonText(DocJson, 'externalDocumentNumber'), 1, MaxStrLen(SalesHeader."External Document No.")));
        
        // Currency
        if APIHelper.GetJsonText(DocJson, 'currencyCode') <> '' then
            SalesHeader.Validate("Currency Code", CopyStr(APIHelper.GetJsonText(DocJson, 'currencyCode'), 1, MaxStrLen(SalesHeader."Currency Code")));
        
        // Payment terms
        if APIHelper.GetJsonText(DocJson, 'paymentTermsCode') <> '' then
            SalesHeader.Validate("Payment Terms Code", CopyStr(APIHelper.GetJsonText(DocJson, 'paymentTermsCode'), 1, MaxStrLen(SalesHeader."Payment Terms Code")));
        
        SalesHeader.Modify(true);
        exit(true);
    end;

    local procedure CreateSalesCreditMemoHeader(DocJson: JsonObject; var SalesHeader: Record "Sales Header"; var ErrorText: Text): Boolean
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        CustomerNo := CopyStr(APIHelper.GetJsonText(DocJson, 'customerNumber'), 1, MaxStrLen(CustomerNo));
        
        if not Customer.Get(CustomerNo) then begin
            ErrorText := StrSubstNo('Customer %1 not found', CustomerNo);
            exit(false);
        end;
        
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader.Insert(true);
        
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Validate("Posting Date", APIHelper.GetJsonDate(DocJson, 'postingDate'));
        SalesHeader.Validate("Document Date", APIHelper.GetJsonDate(DocJson, 'creditMemoDate'));
        SalesHeader.Validate("Due Date", APIHelper.GetJsonDate(DocJson, 'dueDate'));
        SalesHeader.Validate("External Document No.", CopyStr(APIHelper.GetJsonText(DocJson, 'externalDocumentNumber'), 1, MaxStrLen(SalesHeader."External Document No.")));
        
        // Currency
        if APIHelper.GetJsonText(DocJson, 'currencyCode') <> '' then
            SalesHeader.Validate("Currency Code", CopyStr(APIHelper.GetJsonText(DocJson, 'currencyCode'), 1, MaxStrLen(SalesHeader."Currency Code")));
        
        // Payment terms
        if APIHelper.GetJsonText(DocJson, 'paymentTermsCode') <> '' then
            SalesHeader.Validate("Payment Terms Code", CopyStr(APIHelper.GetJsonText(DocJson, 'paymentTermsCode'), 1, MaxStrLen(SalesHeader."Payment Terms Code")));
        
        SalesHeader.Modify(true);
        exit(true);
    end;

    local procedure CreateSalesInvoiceLines(DocJson: JsonObject; var SalesHeader: Record "Sales Header"; var ErrorText: Text): Boolean
    var
        SalesLine: Record "Sales Line";
        LinesToken: JsonToken;
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineJson: JsonObject;
        i: Integer;
    begin
        // Get lines array
        if not DocJson.Get('salesInvoiceLines', LinesToken) then
            exit(true); // No lines is valid
        
        if not LinesToken.IsArray() then begin
            ErrorText := 'Sales invoice lines is not an array';
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
            if not CreateSalesLine(SalesHeader, LineJson, SalesLine, ErrorText) then
                exit(false);
        end;
        
        exit(true);
    end;

    local procedure CreateSalesCreditMemoLines(DocJson: JsonObject; var SalesHeader: Record "Sales Header"; var ErrorText: Text): Boolean
    var
        SalesLine: Record "Sales Line";
        LinesToken: JsonToken;
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineJson: JsonObject;
        i: Integer;
    begin
        // Get lines array
        if not DocJson.Get('salesCreditMemoLines', LinesToken) then
            exit(true); // No lines is valid
        
        if not LinesToken.IsArray() then begin
            ErrorText := 'Sales credit memo lines is not an array';
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
            if not CreateSalesLine(SalesHeader, LineJson, SalesLine, ErrorText) then
                exit(false);
        end;
        
        exit(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; LineJson: JsonObject; var SalesLine: Record "Sales Line"; var ErrorText: Text): Boolean
    var
        LineTypeText: Text;
        LineType: Enum "Sales Line Type";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := GetNextLineNo(SalesHeader);
        
        // Parse line type
        LineTypeText := APIHelper.GetJsonText(LineJson, 'lineType');
        if not ParseLineType(LineTypeText, LineType) then begin
            ErrorText := StrSubstNo('Invalid line type: %1', LineTypeText);
            exit(false);
        end;
        
        SalesLine.Insert(true);
        SalesLine.Validate(Type, LineType);
        
        // Only set No. for non-comment lines
        if LineType <> LineType::" " then
            SalesLine.Validate("No.", CopyStr(APIHelper.GetJsonText(LineJson, 'lineObjectNumber'), 1, MaxStrLen(SalesLine."No.")));
        
        SalesLine.Validate(Description, CopyStr(APIHelper.GetJsonText(LineJson, 'description'), 1, MaxStrLen(SalesLine.Description)));
        SalesLine.Validate(Quantity, APIHelper.GetJsonDecimal(LineJson, 'quantity'));
        SalesLine.Validate("Unit Price", APIHelper.GetJsonDecimal(LineJson, 'unitPrice'));
        SalesLine.Validate("Line Discount %", APIHelper.GetJsonDecimal(LineJson, 'lineDiscount'));
        
        SalesLine.Modify(true);
        exit(true);
    end;

    local procedure GetNextLineNo(var SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            exit(SalesLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure ParseLineType(LineTypeText: Text; var LineType: Enum "Sales Line Type"): Boolean
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
