/// <summary>
/// Purchase Document Synchronization for BC27
/// Sends Purchase Invoices and Credit Memos to target system
/// </summary>
codeunit 80103 "KLT Purchase Doc Sync"
{
    var
        APIHelper: Codeunit "KLT API Helper";
        Validator: Codeunit "KLT Document Validator";

    /// <summary>
    /// Synchronizes a Purchase Invoice to target
    /// </summary>
    procedure SyncPurchaseInvoice(var PurchHeader: Record "Purchase Header"): Boolean
    var
        APIConfig: Record "KLT API Config";
        SyncLog: Record "KLT Document Sync Log";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Endpoint: Text;
        ErrorText: Text;
        SyncLogEntryNo: Integer;
    begin
        APIConfig.GetInstance();

        // Create sync log entry
        SyncLogEntryNo := CreateSyncLog(PurchHeader."No.", PurchHeader."Posting Date",
            "KLT Document Type"::"Purchase Invoice", "KLT Sync Direction"::Outbound);

        // Validate document
        if not Validator.ValidatePurchaseInvoice(PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Build JSON request
        if not BuildPurchaseInvoiceJson(PurchHeader, RequestJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'Failed to build JSON request', "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Send to target
        Endpoint := APIHelper.GetPurchaseInvoiceEndpoint(APIConfig."Target Company Name");
        if not APIHelper.SendPostRequest(Endpoint, RequestJson, ResponseJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'API request failed', "KLT Error Category"::"API Communication");
            exit(false);
        end;

        // Update sync log as completed
        UpdateSyncLogCompleted(SyncLogEntryNo, APIHelper.GetJsonText(ResponseJson, 'id'));
        exit(true);
    end;

    /// <summary>
    /// Synchronizes a Purchase Credit Memo to target
    /// </summary>
    procedure SyncPurchaseCreditMemo(var PurchHeader: Record "Purchase Header"): Boolean
    var
        APIConfig: Record "KLT API Config";
        SyncLog: Record "KLT Document Sync Log";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Endpoint: Text;
        ErrorText: Text;
        SyncLogEntryNo: Integer;
    begin
        APIConfig.GetInstance();

        // Create sync log entry
        SyncLogEntryNo := CreateSyncLog(PurchHeader."No.", PurchHeader."Posting Date",
            "KLT Document Type"::"Purchase Credit Memo", "KLT Sync Direction"::Outbound);

        // Validate document
        if not Validator.ValidatePurchaseCreditMemo(PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Build JSON request
        if not BuildPurchaseCreditMemoJson(PurchHeader, RequestJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'Failed to build JSON request', "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Send to target
        Endpoint := APIHelper.GetPurchaseCreditMemoEndpoint(APIConfig."Target Company Name");
        if not APIHelper.SendPostRequest(Endpoint, RequestJson, ResponseJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'API request failed', "KLT Error Category"::"API Communication");
            exit(false);
        end;

        // Update sync log as completed
        UpdateSyncLogCompleted(SyncLogEntryNo, APIHelper.GetJsonText(ResponseJson, 'id'));
        exit(true);
    end;

    local procedure BuildPurchaseInvoiceJson(var PurchHeader: Record "Purchase Header"; var RequestJson: JsonObject): Boolean
    var
        PurchLine: Record "Purchase Line";
        LinesArray: JsonArray;
    begin
        // Header fields
        RequestJson.Add('vendorNumber', PurchHeader."Buy-from Vendor No.");
        RequestJson.Add('externalDocumentNumber', PurchHeader."Vendor Invoice No.");
        RequestJson.Add('invoiceDate', PurchHeader."Document Date");
        RequestJson.Add('postingDate', PurchHeader."Posting Date");
        RequestJson.Add('dueDate', PurchHeader."Due Date");

        // Vendor details
        RequestJson.Add('vendorName', PurchHeader."Buy-from Vendor Name");
        RequestJson.Add('payToName', PurchHeader."Pay-to Name");
        RequestJson.Add('payToVendorNumber', PurchHeader."Pay-to Vendor No.");

        // Addresses
        AddAddressFields(RequestJson, PurchHeader."Buy-from Address", PurchHeader."Buy-from Address 2",
            PurchHeader."Buy-from City", PurchHeader."Buy-from Post Code", PurchHeader."Buy-from County",
            PurchHeader."Buy-from Country/Region Code");

        // Currency
        if PurchHeader."Currency Code" <> '' then
            RequestJson.Add('currencyCode', PurchHeader."Currency Code");

        // Payment terms
        if PurchHeader."Payment Terms Code" <> '' then
            RequestJson.Add('paymentTermsCode', PurchHeader."Payment Terms Code");

        // Lines
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindSet() then begin
            repeat
                AddPurchaseInvoiceLine(LinesArray, PurchLine);
            until PurchLine.Next() = 0;
        end;
        RequestJson.Add('purchaseInvoiceLines', LinesArray);

        exit(true);
    end;

    local procedure BuildPurchaseCreditMemoJson(var PurchHeader: Record "Purchase Header"; var RequestJson: JsonObject): Boolean
    var
        PurchLine: Record "Purchase Line";
        LinesArray: JsonArray;
    begin
        // Header fields
        RequestJson.Add('vendorNumber', PurchHeader."Buy-from Vendor No.");
        RequestJson.Add('externalDocumentNumber', PurchHeader."Vendor Cr. Memo No.");
        RequestJson.Add('creditMemoDate', PurchHeader."Document Date");
        RequestJson.Add('postingDate', PurchHeader."Posting Date");
        RequestJson.Add('dueDate', PurchHeader."Due Date");

        // Vendor details
        RequestJson.Add('vendorName', PurchHeader."Buy-from Vendor Name");
        RequestJson.Add('payToName', PurchHeader."Pay-to Name");
        RequestJson.Add('payToVendorNumber', PurchHeader."Pay-to Vendor No.");

        // Addresses
        AddAddressFields(RequestJson, PurchHeader."Buy-from Address", PurchHeader."Buy-from Address 2",
            PurchHeader."Buy-from City", PurchHeader."Buy-from Post Code", PurchHeader."Buy-from County",
            PurchHeader."Buy-from Country/Region Code");

        // Currency
        if PurchHeader."Currency Code" <> '' then
            RequestJson.Add('currencyCode', PurchHeader."Currency Code");

        // Payment terms
        if PurchHeader."Payment Terms Code" <> '' then
            RequestJson.Add('paymentTermsCode', PurchHeader."Payment Terms Code");

        // Lines
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindSet() then begin
            repeat
                AddPurchaseCreditMemoLine(LinesArray, PurchLine);
            until PurchLine.Next() = 0;
        end;
        RequestJson.Add('purchaseCreditMemoLines', LinesArray);

        exit(true);
    end;

    local procedure AddPurchaseInvoiceLine(var LinesArray: JsonArray; var PurchLine: Record "Purchase Line")
    var
        LineJson: JsonObject;
    begin
        LineJson.Add('lineType', Format(PurchLine.Type));
        LineJson.Add('number', PurchLine."No.");
        LineJson.Add('description', PurchLine.Description);
        LineJson.Add('description2', PurchLine."Description 2");
        LineJson.Add('quantity', PurchLine.Quantity);
        LineJson.Add('unitOfMeasureCode', PurchLine."Unit of Measure Code");
        LineJson.Add('unitCost', PurchLine."Direct Unit Cost");
        LineJson.Add('lineDiscount', PurchLine."Line Discount %");
        LineJson.Add('lineDiscountAmount', PurchLine."Line Discount Amount");
        LineJson.Add('taxPercent', PurchLine."VAT %");

        LinesArray.Add(LineJson);
    end;

    local procedure AddPurchaseCreditMemoLine(var LinesArray: JsonArray; var PurchLine: Record "Purchase Line")
    var
        LineJson: JsonObject;
    begin
        LineJson.Add('lineType', Format(PurchLine.Type));
        LineJson.Add('number', PurchLine."No.");
        LineJson.Add('description', PurchLine.Description);
        LineJson.Add('description2', PurchLine."Description 2");
        LineJson.Add('quantity', PurchLine.Quantity);
        LineJson.Add('unitOfMeasureCode', PurchLine."Unit of Measure Code");
        LineJson.Add('unitCost', PurchLine."Direct Unit Cost");
        LineJson.Add('lineDiscount', PurchLine."Line Discount %");
        LineJson.Add('lineDiscountAmount', PurchLine."Line Discount Amount");
        LineJson.Add('taxPercent', PurchLine."VAT %");

        LinesArray.Add(LineJson);
    end;

    local procedure AddAddressFields(var JsonObj: JsonObject; Address: Text[100]; Address2: Text[50]; City: Text[30]; PostCode: Code[20]; County: Text[30]; CountryCode: Code[10])
    begin
        if Address <> '' then
            JsonObj.Add('buyingAddress', Address);
        if Address2 <> '' then
            JsonObj.Add('buyingAddress2', Address2);
        if City <> '' then
            JsonObj.Add('buyingCity', City);
        if PostCode <> '' then
            JsonObj.Add('buyingPostCode', PostCode);
        if County <> '' then
            JsonObj.Add('buyingState', County);
        if CountryCode <> '' then
            JsonObj.Add('buyingCountryCode', CountryCode);
    end;

    local procedure CreateSyncLog(DocumentNo: Code[20]; DocumentDate: Date; DocType: Enum "KLT Document Type"; Direction: Enum "KLT Sync Direction"): Integer
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        SyncLog.Init();
        SyncLog."Entry No." := 0;
        SyncLog."Document Type" := DocType;
        SyncLog."External Document No." := DocumentNo;
        SyncLog."Sync Direction" := Direction;
        SyncLog.Status := SyncLog.Status::"In Progress";
        SyncLog."Started DateTime" := CurrentDateTime();
        SyncLog."Created By" := CopyStr(UserId(), 1, MaxStrLen(SyncLog."Created By"));
        SyncLog.Insert(true);
        exit(SyncLog."Entry No.");
    end;

    local procedure UpdateSyncLogCompleted(EntryNo: Integer; TargetDocNo: Text)
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        if SyncLog.Get(EntryNo) then begin
            SyncLog.Status := SyncLog.Status::Completed;
            SyncLog."Completed DateTime" := CurrentDateTime();
            SyncLog."Target Document No." := TargetDocNo;
            SyncLog."Error Message" := '';
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
    /// Batch sync multiple Purchase Invoices
    /// </summary>
    procedure BatchSyncPurchaseInvoices(var PurchHeader: Record "Purchase Header"): Integer
    var
        SuccessCount: Integer;
    begin
        SuccessCount := 0;
        if PurchHeader.FindSet() then begin
            repeat
                if SyncPurchaseInvoice(PurchHeader) then
                    SuccessCount += 1;
                Commit(); // Commit after each document
            until PurchHeader.Next() = 0;
        end;
        exit(SuccessCount);
    end;

    /// <summary>
    /// Batch sync multiple Purchase Credit Memos
    /// </summary>
    procedure BatchSyncPurchaseCreditMemos(var PurchHeader: Record "Purchase Header"): Integer
    var
        SuccessCount: Integer;
    begin
        SuccessCount := 0;
        if PurchHeader.FindSet() then begin
            repeat
                if SyncPurchaseCreditMemo(PurchHeader) then
                    SuccessCount += 1;
                Commit(); // Commit after each document
            until PurchHeader.Next() = 0;
        end;
        exit(SuccessCount);
    end;

    /// <summary>
    /// Retrieves and creates Purchase Invoices from target
    /// </summary>
    procedure SyncPurchaseInvoicesFromTarget(): Integer
    var
        APIConfig: Record "KLT API Config";
        ResponseJson: JsonObject;
        ValueArray: JsonArray;
        Endpoint: Text;
        DocumentsCreated: Integer;
        i: Integer;
    begin
        APIConfig.GetInstance();
        DocumentsCreated := 0;

        // Get purchase invoices from target
        Endpoint := APIHelper.GetPurchaseInvoiceEndpoint(APIConfig."Target Company Name");
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
    /// Retrieves and creates Purchase Credit Memos from target
    /// </summary>
    procedure SyncPurchaseCreditMemosFromTarget(): Integer
    var
        APIConfig: Record "KLT API Config";
        ResponseJson: JsonObject;
        ValueArray: JsonArray;
        Endpoint: Text;
        DocumentsCreated: Integer;
        i: Integer;
    begin
        APIConfig.GetInstance();
        DocumentsCreated := 0;

        // Get purchase credit memos from target
        Endpoint := APIHelper.GetPurchaseCreditMemoEndpoint(APIConfig."Target Company Name");
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
            "KLT Document Type"::"Purchase Invoice", "KLT Sync Direction"::Inbound);

        // Validate data
        if not Validator.ValidatePurchaseInvoiceData(DocJson, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Check for duplicates
        if not Validator.CheckDuplicatePurchaseInvoice(ExternalDocNo, VendorNo, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Create purchase invoice header
        if not CreatePurchaseInvoiceHeader(DocJson, PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Business Logic");
            exit(false);
        end;

        // Create purchase invoice lines
        if not CreatePurchaseInvoiceLines(DocJson, PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Business Logic");
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
            "KLT Document Type"::"Purchase Credit Memo", "KLT Sync Direction"::Inbound);

        // Validate data
        if not Validator.ValidatePurchaseCreditMemoData(DocJson, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Check for duplicates
        if not Validator.CheckDuplicatePurchaseCreditMemo(ExternalDocNo, VendorNo, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Create purchase credit memo header
        if not CreatePurchaseCreditMemoHeader(DocJson, PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Business Logic");
            exit(false);
        end;

        // Create purchase credit memo lines
        if not CreatePurchaseCreditMemoLines(DocJson, PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Business Logic");
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
}
