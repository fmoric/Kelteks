/// <summary>
/// Sales Document Synchronization for BC17
/// Sends Posted Sales Invoices and Credit Memos to target system
/// </summary>
codeunit 80104 "KLT Sales Doc Sync"
{
    var
        APIHelper: Codeunit "KLT API Helper";
        Validator: Codeunit "KLT Document Validator";
        BaseSyncHelper: Codeunit "KLT Base Sync Helper";
        FailedBuildJSONErr: Label 'Failed to build JSON request';
        APIRequestFailedErr: Label 'API request failed';
        SyncedInvoicesMsgLbl: Label 'Synced %1 of %2 sales invoices.';
        SyncedCreditMemosMsgLbl: Label 'Synced %1 of %2 sales credit memos.';
        CustomerNumberLbl: Label 'customerNumber', Locked = true;
        ExternalDocNumberLbl: Label 'externalDocumentNumber', Locked = true;
        InvoiceDateLbl: Label 'invoiceDate', Locked = true;
        PostingDateLbl: Label 'postingDate', Locked = true;
        DueDateLbl: Label 'dueDate', Locked = true;
        CustomerNameLbl: Label 'customerName', Locked = true;
        BillToNameLbl: Label 'billToName', Locked = true;
        BillToCustomerNumberLbl: Label 'billToCustomerNumber', Locked = true;
        CurrencyCodeLbl: Label 'currencyCode', Locked = true;
        PaymentTermsCodeLbl: Label 'paymentTermsCode', Locked = true;
        TotalAmountExcludingTaxLbl: Label 'totalAmountExcludingTax', Locked = true;
        TotalTaxAmountLbl: Label 'totalTaxAmount', Locked = true;
        TotalAmountIncludingTaxLbl: Label 'totalAmountIncludingTax', Locked = true;
        SalesInvoiceLinesLbl: Label 'salesInvoiceLines', Locked = true;
        CreditMemoDateLbl: Label 'creditMemoDate', Locked = true;
        SalesCreditMemoLinesLbl: Label 'salesCreditMemoLines', Locked = true;
        LineTypeLbl: Label 'lineType', Locked = true;
        LineObjectNumberLbl: Label 'lineObjectNumber', Locked = true;
        DescriptionLbl: Label 'description', Locked = true;
        Description2Lbl: Label 'description2', Locked = true;
        QuantityLbl: Label 'quantity', Locked = true;
        UnitOfMeasureCodeLbl: Label 'unitOfMeasureCode', Locked = true;
        UnitPriceLbl: Label 'unitPrice', Locked = true;
        LineDiscountLbl: Label 'lineDiscount', Locked = true;
        LineDiscountAmountLbl: Label 'lineDiscountAmount', Locked = true;
        TaxPercentLbl: Label 'taxPercent', Locked = true;
        AmountExcludingTaxLbl: Label 'amountExcludingTax', Locked = true;
        TaxAmountLbl: Label 'taxAmount', Locked = true;
        AmountIncludingTaxLbl: Label 'amountIncludingTax', Locked = true;
        SellingAddressLbl: Label 'sellingAddress', Locked = true;
        SellingAddress2Lbl: Label 'sellingAddress2', Locked = true;
        SellingCityLbl: Label 'sellingCity', Locked = true;
        SellingPostCodeLbl: Label 'sellingPostCode', Locked = true;
        SellingStateLbl: Label 'sellingState', Locked = true;
        SellingCountryCodeLbl: Label 'sellingCountryCode', Locked = true;
        IdLbl: Label 'id', Locked = true;

    /// <summary>
    /// Synchronizes a Posted Sales Invoice to target
    /// </summary>
    procedure SyncPostedSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"): Boolean
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
        SyncLogEntryNo := CreateSyncLog(SalesInvHeader."No.", SalesInvHeader."Posting Date",
            "KLT Document Type"::"Sales Invoice", "KLT Sync Direction"::Outbound);

        // Validate document
        if not Validator.ValidatePostedSalesInvoice(SalesInvHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Build JSON request
        if not BuildSalesInvoiceJson(SalesInvHeader, RequestJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, FailedBuildJSONErr, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Send to target
        Endpoint := APIHelper.GetSalesInvoiceEndpoint(APIConfig."Target Company ID");
        if not APIHelper.SendPostRequest(Endpoint, RequestJson, ResponseJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, APIRequestFailedErr, "KLT Error Category"::"API Communication");
            exit(false);
        end;

        // Update sync log as completed
        UpdateSyncLogCompleted(SyncLogEntryNo, APIHelper.GetJsonText(ResponseJson, IdLbl));
        exit(true);
    end;

    /// <summary>
    /// Synchronizes a Posted Sales Credit Memo to target
    /// </summary>
    procedure SyncPostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
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
        SyncLogEntryNo := CreateSyncLog(SalesCrMemoHeader."No.", SalesCrMemoHeader."Posting Date",
            "KLT Document Type"::"Sales Credit Memo", "KLT Sync Direction"::Outbound);

        // Validate document
        if not Validator.ValidatePostedSalesCreditMemo(SalesCrMemoHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Build JSON request
        if not BuildSalesCreditMemoJson(SalesCrMemoHeader, RequestJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, FailedBuildJSONErr, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Send to target
        Endpoint := APIHelper.GetSalesCreditMemoEndpoint(APIConfig."Target Company ID");
        if not APIHelper.SendPostRequest(Endpoint, RequestJson, ResponseJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, APIRequestFailedErr, "KLT Error Category"::"API Communication");
            exit(false);
        end;

        // Update sync log as completed
        UpdateSyncLogCompleted(SyncLogEntryNo, APIHelper.GetJsonText(ResponseJson, IdLbl));
        exit(true);
    end;

    local procedure BuildSalesInvoiceJson(var SalesInvHeader: Record "Sales Invoice Header"; var RequestJson: JsonObject): Boolean
    var
        SalesInvLine: Record "Sales Invoice Line";
        LinesArray: JsonArray;
    begin
        // Header fields
        RequestJson.Add(CustomerNumberLbl, SalesInvHeader."Sell-to Customer No.");
        RequestJson.Add(ExternalDocNumberLbl, SalesInvHeader."External Document No.");
        RequestJson.Add(InvoiceDateLbl, SalesInvHeader."Document Date");
        RequestJson.Add(PostingDateLbl, SalesInvHeader."Posting Date");
        RequestJson.Add(DueDateLbl, SalesInvHeader."Due Date");

        // Customer details
        RequestJson.Add(CustomerNameLbl, SalesInvHeader."Sell-to Customer Name");
        RequestJson.Add(BillToNameLbl, SalesInvHeader."Bill-to Name");
        RequestJson.Add(BillToCustomerNumberLbl, SalesInvHeader."Bill-to Customer No.");

        // Addresses
        AddAddressFields(RequestJson, SalesInvHeader."Sell-to Address", SalesInvHeader."Sell-to Address 2",
            SalesInvHeader."Sell-to City", SalesInvHeader."Sell-to Post Code", SalesInvHeader."Sell-to County",
            SalesInvHeader."Sell-to Country/Region Code");

        // Currency
        if SalesInvHeader."Currency Code" <> '' then
            RequestJson.Add(CurrencyCodeLbl, SalesInvHeader."Currency Code");

        // Payment terms
        if SalesInvHeader."Payment Terms Code" <> '' then
            RequestJson.Add(PaymentTermsCodeLbl, SalesInvHeader."Payment Terms Code");

        // Amounts
        RequestJson.Add(TotalAmountExcludingTaxLbl, SalesInvHeader.Amount);
        RequestJson.Add(TotalTaxAmountLbl, SalesInvHeader."Amount Including VAT" - SalesInvHeader.Amount);
        RequestJson.Add(TotalAmountIncludingTaxLbl, SalesInvHeader."Amount Including VAT");

        // Lines
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        if SalesInvLine.FindSet() then begin
            repeat
                AddSalesInvoiceLine(LinesArray, SalesInvLine);
            until SalesInvLine.Next() = 0;
        end;
        RequestJson.Add(SalesInvoiceLinesLbl, LinesArray);

        exit(true);
    end;

    local procedure BuildSalesCreditMemoJson(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var RequestJson: JsonObject): Boolean
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        LinesArray: JsonArray;
    begin
        // Header fields
        RequestJson.Add(CustomerNumberLbl, SalesCrMemoHeader."Sell-to Customer No.");
        RequestJson.Add(ExternalDocNumberLbl, SalesCrMemoHeader."External Document No.");
        RequestJson.Add(CreditMemoDateLbl, SalesCrMemoHeader."Document Date");
        RequestJson.Add(PostingDateLbl, SalesCrMemoHeader."Posting Date");
        RequestJson.Add(DueDateLbl, SalesCrMemoHeader."Due Date");

        // Customer details
        RequestJson.Add(CustomerNameLbl, SalesCrMemoHeader."Sell-to Customer Name");
        RequestJson.Add(BillToNameLbl, SalesCrMemoHeader."Bill-to Name");
        RequestJson.Add(BillToCustomerNumberLbl, SalesCrMemoHeader."Bill-to Customer No.");

        // Addresses
        AddAddressFields(RequestJson, SalesCrMemoHeader."Sell-to Address", SalesCrMemoHeader."Sell-to Address 2",
            SalesCrMemoHeader."Sell-to City", SalesCrMemoHeader."Sell-to Post Code", SalesCrMemoHeader."Sell-to County",
            SalesCrMemoHeader."Sell-to Country/Region Code");

        // Currency
        if SalesCrMemoHeader."Currency Code" <> '' then
            RequestJson.Add(CurrencyCodeLbl, SalesCrMemoHeader."Currency Code");

        // Payment terms
        if SalesCrMemoHeader."Payment Terms Code" <> '' then
            RequestJson.Add(PaymentTermsCodeLbl, SalesCrMemoHeader."Payment Terms Code");

        // Amounts
        RequestJson.Add(TotalAmountExcludingTaxLbl, SalesCrMemoHeader.Amount);
        RequestJson.Add(TotalTaxAmountLbl, SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount);
        RequestJson.Add(TotalAmountIncludingTaxLbl, SalesCrMemoHeader."Amount Including VAT");

        // Lines
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindSet() then begin
            repeat
                AddSalesCreditMemoLine(LinesArray, SalesCrMemoLine);
            until SalesCrMemoLine.Next() = 0;
        end;
        RequestJson.Add(SalesCreditMemoLinesLbl, LinesArray);

        exit(true);
    end;

    local procedure AddSalesInvoiceLine(var LinesArray: JsonArray; var SalesInvLine: Record "Sales Invoice Line")
    var
        LineJson: JsonObject;
    begin
        LineJson.Add(LineTypeLbl, Format(SalesInvLine.Type));
        LineJson.Add(LineObjectNumberLbl, SalesInvLine."No.");
        LineJson.Add(DescriptionLbl, SalesInvLine.Description);
        LineJson.Add(Description2Lbl, SalesInvLine."Description 2");
        LineJson.Add(QuantityLbl, SalesInvLine.Quantity);
        LineJson.Add(UnitOfMeasureCodeLbl, SalesInvLine."Unit of Measure Code");
        LineJson.Add(UnitPriceLbl, SalesInvLine."Unit Price");
        LineJson.Add(LineDiscountLbl, SalesInvLine."Line Discount %");
        LineJson.Add(LineDiscountAmountLbl, SalesInvLine."Line Discount Amount");
        LineJson.Add(TaxPercentLbl, SalesInvLine."VAT %");
        LineJson.Add(AmountExcludingTaxLbl, SalesInvLine.Amount);
        LineJson.Add(TaxAmountLbl, SalesInvLine."Amount Including VAT" - SalesInvLine.Amount);
        LineJson.Add(AmountIncludingTaxLbl, SalesInvLine."Amount Including VAT");

        LinesArray.Add(LineJson);
    end;

    local procedure AddSalesCreditMemoLine(var LinesArray: JsonArray; var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        LineJson: JsonObject;
    begin
        LineJson.Add(LineTypeLbl, Format(SalesCrMemoLine.Type));
        LineJson.Add(LineObjectNumberLbl, SalesCrMemoLine."No.");
        LineJson.Add(DescriptionLbl, SalesCrMemoLine.Description);
        LineJson.Add(Description2Lbl, SalesCrMemoLine."Description 2");
        LineJson.Add(QuantityLbl, SalesCrMemoLine.Quantity);
        LineJson.Add(UnitOfMeasureCodeLbl, SalesCrMemoLine."Unit of Measure Code");
        LineJson.Add(UnitPriceLbl, SalesCrMemoLine."Unit Price");
        LineJson.Add(LineDiscountLbl, SalesCrMemoLine."Line Discount %");
        LineJson.Add(LineDiscountAmountLbl, SalesCrMemoLine."Line Discount Amount");
        LineJson.Add(TaxPercentLbl, SalesCrMemoLine."VAT %");
        LineJson.Add(AmountExcludingTaxLbl, SalesCrMemoLine.Amount);
        LineJson.Add(TaxAmountLbl, SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount);
        LineJson.Add(AmountIncludingTaxLbl, SalesCrMemoLine."Amount Including VAT");

        LinesArray.Add(LineJson);
    end;

    local procedure AddAddressFields(var JsonObj: JsonObject; Address: Text[100]; Address2: Text[50]; City: Text[30]; PostCode: Code[20]; County: Text[30]; CountryCode: Code[10])
    begin
        if Address <> '' then
            JsonObj.Add(SellingAddressLbl, Address);
        if Address2 <> '' then
            JsonObj.Add(SellingAddress2Lbl, Address2);
        if City <> '' then
            JsonObj.Add(SellingCityLbl, City);
        if PostCode <> '' then
            JsonObj.Add(SellingPostCodeLbl, PostCode);
        if County <> '' then
            JsonObj.Add(SellingStateLbl, County);
        if CountryCode <> '' then
            JsonObj.Add(SellingCountryCodeLbl, CountryCode);
    end;

    local procedure CreateSyncLog(DocumentNo: Code[20]; DocumentDate: Date; DocType: Enum "KLT Document Type"; Direction: Enum "KLT Sync Direction"): Integer
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        SyncLog.Init();
        SyncLog."Entry No." := 0; // Auto-increment
        SyncLog."Document Type" := DocType;
        SyncLog."Source Document No." := DocumentNo;
        SyncLog."Sync Direction" := Direction;
        SyncLog.Status := SyncLog.Status::"In Progress";
        SyncLog."Started DateTime" := CurrentDateTime();
        SyncLog."Created By" := CopyStr(UserId(), 1, MaxStrLen(SyncLog."Created By"));
        SyncLog.Insert(true);
        exit(SyncLog."Entry No.");
    end;

    local procedure UpdateSyncLogCompleted(EntryNo: Integer; TargetDocId: Text)
    var
        SyncLog: Record "KLT Document Sync Log";
        TargetGuid: Guid;
    begin
        if SyncLog.Get(EntryNo) then begin
            SyncLog.Status := SyncLog.Status::Completed;
            SyncLog."Completed DateTime" := CurrentDateTime();
            // Try to convert target doc ID to GUID if valid
            if Evaluate(TargetGuid, TargetDocId) then
                SyncLog."Target System ID" := TargetGuid;
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
    /// Batch sync multiple Posted Sales Invoices
    /// </summary>
    procedure BatchSyncSalesInvoices(var SalesInvHeader: Record "Sales Invoice Header"): Integer
    var
        SuccessCount: Integer;
    begin
        SuccessCount := 0;
        if SalesInvHeader.FindSet() then begin
            repeat
                if SyncPostedSalesInvoice(SalesInvHeader) then
                    SuccessCount += 1;
                Commit(); // Commit after each document
            until SalesInvHeader.Next() = 0;
        end;
        exit(SuccessCount);
    end;

    /// <summary>
    /// Batch sync multiple Posted Sales Credit Memos
    /// </summary>
    procedure BatchSyncSalesCreditMemos(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Integer
    var
        SuccessCount: Integer;
    begin
        SuccessCount := 0;
        if SalesCrMemoHeader.FindSet() then begin
            repeat
                if SyncPostedSalesCreditMemo(SalesCrMemoHeader) then
                    SuccessCount += 1;
                Commit(); // Commit after each document
            until SalesCrMemoHeader.Next() = 0;
        end;
        exit(SuccessCount);
    end;

    /// <summary>
    /// Sync Sales Invoices from list page
    /// </summary>
    procedure SyncSalesInvoices(var SalesInvHeader: Record "Sales Invoice Header")
    var
        SuccessCount: Integer;
        TotalCount: Integer;
    begin
        TotalCount := SalesInvHeader.Count();
        SuccessCount := BatchSyncSalesInvoices(SalesInvHeader);
        Message(SyncedInvoicesMsgLbl, SuccessCount, TotalCount);
    end;

    /// <summary>
    /// Sync Sales Credit Memos from list page
    /// </summary>
    procedure SyncSalesCreditMemos(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SuccessCount: Integer;
        TotalCount: Integer;
    begin
        TotalCount := SalesCrMemoHeader.Count();
        SuccessCount := BatchSyncSalesCreditMemos(SalesCrMemoHeader);
        Message(SyncedCreditMemosMsgLbl, SuccessCount, TotalCount);
    end;

    /// <summary>
    /// Retrieves and creates Sales Invoices from target
    /// </summary>
    procedure SyncSalesInvoicesFromTarget(): Integer
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

        // Get sales invoices from target
        Endpoint := APIHelper.GetSalesInvoiceEndpoint(APIConfig."Target Company ID");
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
    /// Retrieves and creates Sales Credit Memos from target
    /// </summary>
    procedure SyncSalesCreditMemosFromTarget(): Integer
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

        // Get sales credit memos from target
        Endpoint := APIHelper.GetSalesCreditMemoEndpoint(APIConfig."Target Company ID");
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
            "KLT Document Type"::"Sales Invoice", "KLT Sync Direction"::Inbound);

        // Validate data
        if not Validator.ValidateSalesInvoiceData(DocJson, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Check for duplicates
        if not Validator.CheckDuplicateSalesInvoice(ExternalDocNo, CustomerNo, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Create sales invoice header
        if not CreateSalesInvoiceHeader(DocJson, SalesHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Business Logic");
            exit(false);
        end;

        // Create sales invoice lines
        if not CreateSalesInvoiceLines(DocJson, SalesHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Business Logic");
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
            "KLT Document Type"::"Sales Credit Memo", "KLT Sync Direction"::Inbound);

        // Validate data
        if not Validator.ValidateSalesCreditMemoData(DocJson, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Check for duplicates
        if not Validator.CheckDuplicateSalesCreditMemo(ExternalDocNo, CustomerNo, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Data Validation");
            exit(false);
        end;

        // Create sales credit memo header
        if not CreateSalesCreditMemoHeader(DocJson, SalesHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Business Logic");
            exit(false);
        end;

        // Create sales credit memo lines
        if not CreateSalesCreditMemoLines(DocJson, SalesHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::"Business Logic");
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
}
