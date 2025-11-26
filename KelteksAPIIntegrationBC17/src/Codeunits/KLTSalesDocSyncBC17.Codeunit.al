/// <summary>
/// Sales Document Synchronization for BC17
/// Sends Posted Sales Invoices and Credit Memos to BC27
/// </summary>
codeunit 50102 "KLT Sales Doc Sync BC17"
{
    var
        APIHelper: Codeunit "KLT API Helper BC17";
        Validator: Codeunit "KLT Document Validator BC17";

    /// <summary>
    /// Synchronizes a Posted Sales Invoice to BC27
    /// </summary>
    procedure SyncPostedSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"): Boolean
    var
        APIConfig: Record "KLT API Config BC17";
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
            "KLT Document Type"::SalesInvoice, "KLT Sync Direction"::Outbound);
        
        // Validate document
        if not Validator.ValidatePostedSalesInvoice(SalesInvHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Build JSON request
        if not BuildSalesInvoiceJson(SalesInvHeader, RequestJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'Failed to build JSON request', "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Send to BC27
        Endpoint := APIHelper.GetSalesInvoiceEndpoint(APIConfig."BC27 Company ID");
        if not APIHelper.SendPostRequest(Endpoint, RequestJson, ResponseJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'API request failed', "KLT Error Category"::APICommunication);
            exit(false);
        end;
        
        // Update sync log as completed
        UpdateSyncLogCompleted(SyncLogEntryNo, APIHelper.GetJsonText(ResponseJson, 'id'));
        exit(true);
    end;

    /// <summary>
    /// Synchronizes a Posted Sales Credit Memo to BC27
    /// </summary>
    procedure SyncPostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
    var
        APIConfig: Record "KLT API Config BC17";
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
            "KLT Document Type"::SalesCreditMemo, "KLT Sync Direction"::Outbound);
        
        // Validate document
        if not Validator.ValidatePostedSalesCreditMemo(SalesCrMemoHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Build JSON request
        if not BuildSalesCreditMemoJson(SalesCrMemoHeader, RequestJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'Failed to build JSON request', "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Send to BC27
        Endpoint := APIHelper.GetSalesCreditMemoEndpoint(APIConfig."BC27 Company ID");
        if not APIHelper.SendPostRequest(Endpoint, RequestJson, ResponseJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'API request failed', "KLT Error Category"::APICommunication);
            exit(false);
        end;
        
        // Update sync log as completed
        UpdateSyncLogCompleted(SyncLogEntryNo, APIHelper.GetJsonText(ResponseJson, 'id'));
        exit(true);
    end;

    local procedure BuildSalesInvoiceJson(var SalesInvHeader: Record "Sales Invoice Header"; var RequestJson: JsonObject): Boolean
    var
        SalesInvLine: Record "Sales Invoice Line";
        LinesArray: JsonArray;
    begin
        // Header fields
        RequestJson.Add('customerNumber', SalesInvHeader."Sell-to Customer No.");
        RequestJson.Add('externalDocumentNumber', SalesInvHeader."External Document No.");
        RequestJson.Add('invoiceDate', SalesInvHeader."Document Date");
        RequestJson.Add('postingDate', SalesInvHeader."Posting Date");
        RequestJson.Add('dueDate', SalesInvHeader."Due Date");
        
        // Customer details
        RequestJson.Add('customerName', SalesInvHeader."Sell-to Customer Name");
        RequestJson.Add('billToName', SalesInvHeader."Bill-to Name");
        RequestJson.Add('billToCustomerNumber', SalesInvHeader."Bill-to Customer No.");
        
        // Addresses
        AddAddressFields(RequestJson, SalesInvHeader."Sell-to Address", SalesInvHeader."Sell-to Address 2",
            SalesInvHeader."Sell-to City", SalesInvHeader."Sell-to Post Code", SalesInvHeader."Sell-to County",
            SalesInvHeader."Sell-to Country/Region Code");
        
        // Currency
        if SalesInvHeader."Currency Code" <> '' then
            RequestJson.Add('currencyCode', SalesInvHeader."Currency Code");
        
        // Payment terms
        if SalesInvHeader."Payment Terms Code" <> '' then
            RequestJson.Add('paymentTermsCode', SalesInvHeader."Payment Terms Code");
        
        // Amounts
        RequestJson.Add('totalAmountExcludingTax', SalesInvHeader.Amount);
        RequestJson.Add('totalTaxAmount', SalesInvHeader."Amount Including VAT" - SalesInvHeader.Amount);
        RequestJson.Add('totalAmountIncludingTax', SalesInvHeader."Amount Including VAT");
        
        // Lines
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        if SalesInvLine.FindSet() then begin
            repeat
                AddSalesInvoiceLine(LinesArray, SalesInvLine);
            until SalesInvLine.Next() = 0;
        end;
        RequestJson.Add('salesInvoiceLines', LinesArray);
        
        exit(true);
    end;

    local procedure BuildSalesCreditMemoJson(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var RequestJson: JsonObject): Boolean
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        LinesArray: JsonArray;
    begin
        // Header fields
        RequestJson.Add('customerNumber', SalesCrMemoHeader."Sell-to Customer No.");
        RequestJson.Add('externalDocumentNumber', SalesCrMemoHeader."External Document No.");
        RequestJson.Add('creditMemoDate', SalesCrMemoHeader."Document Date");
        RequestJson.Add('postingDate', SalesCrMemoHeader."Posting Date");
        RequestJson.Add('dueDate', SalesCrMemoHeader."Due Date");
        
        // Customer details
        RequestJson.Add('customerName', SalesCrMemoHeader."Sell-to Customer Name");
        RequestJson.Add('billToName', SalesCrMemoHeader."Bill-to Name");
        RequestJson.Add('billToCustomerNumber', SalesCrMemoHeader."Bill-to Customer No.");
        
        // Addresses
        AddAddressFields(RequestJson, SalesCrMemoHeader."Sell-to Address", SalesCrMemoHeader."Sell-to Address 2",
            SalesCrMemoHeader."Sell-to City", SalesCrMemoHeader."Sell-to Post Code", SalesCrMemoHeader."Sell-to County",
            SalesCrMemoHeader."Sell-to Country/Region Code");
        
        // Currency
        if SalesCrMemoHeader."Currency Code" <> '' then
            RequestJson.Add('currencyCode', SalesCrMemoHeader."Currency Code");
        
        // Payment terms
        if SalesCrMemoHeader."Payment Terms Code" <> '' then
            RequestJson.Add('paymentTermsCode', SalesCrMemoHeader."Payment Terms Code");
        
        // Amounts
        RequestJson.Add('totalAmountExcludingTax', SalesCrMemoHeader.Amount);
        RequestJson.Add('totalTaxAmount', SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount);
        RequestJson.Add('totalAmountIncludingTax', SalesCrMemoHeader."Amount Including VAT");
        
        // Lines
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        if SalesCrMemoLine.FindSet() then begin
            repeat
                AddSalesCreditMemoLine(LinesArray, SalesCrMemoLine);
            until SalesCrMemoLine.Next() = 0;
        end;
        RequestJson.Add('salesCreditMemoLines', LinesArray);
        
        exit(true);
    end;

    local procedure AddSalesInvoiceLine(var LinesArray: JsonArray; var SalesInvLine: Record "Sales Invoice Line")
    var
        LineJson: JsonObject;
    begin
        LineJson.Add('lineType', Format(SalesInvLine.Type));
        LineJson.Add('lineObjectNumber', SalesInvLine."No.");
        LineJson.Add('description', SalesInvLine.Description);
        LineJson.Add('description2', SalesInvLine."Description 2");
        LineJson.Add('quantity', SalesInvLine.Quantity);
        LineJson.Add('unitOfMeasureCode', SalesInvLine."Unit of Measure Code");
        LineJson.Add('unitPrice', SalesInvLine."Unit Price");
        LineJson.Add('lineDiscount', SalesInvLine."Line Discount %");
        LineJson.Add('lineDiscountAmount', SalesInvLine."Line Discount Amount");
        LineJson.Add('taxPercent', SalesInvLine."VAT %");
        LineJson.Add('amountExcludingTax', SalesInvLine.Amount);
        LineJson.Add('taxAmount', SalesInvLine."Amount Including VAT" - SalesInvLine.Amount);
        LineJson.Add('amountIncludingTax', SalesInvLine."Amount Including VAT");
        
        LinesArray.Add(LineJson);
    end;

    local procedure AddSalesCreditMemoLine(var LinesArray: JsonArray; var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        LineJson: JsonObject;
    begin
        LineJson.Add('lineType', Format(SalesCrMemoLine.Type));
        LineJson.Add('lineObjectNumber', SalesCrMemoLine."No.");
        LineJson.Add('description', SalesCrMemoLine.Description);
        LineJson.Add('description2', SalesCrMemoLine."Description 2");
        LineJson.Add('quantity', SalesCrMemoLine.Quantity);
        LineJson.Add('unitOfMeasureCode', SalesCrMemoLine."Unit of Measure Code");
        LineJson.Add('unitPrice', SalesCrMemoLine."Unit Price");
        LineJson.Add('lineDiscount', SalesCrMemoLine."Line Discount %");
        LineJson.Add('lineDiscountAmount', SalesCrMemoLine."Line Discount Amount");
        LineJson.Add('taxPercent', SalesCrMemoLine."VAT %");
        LineJson.Add('amountExcludingTax', SalesCrMemoLine.Amount);
        LineJson.Add('taxAmount', SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount);
        LineJson.Add('amountIncludingTax', SalesCrMemoLine."Amount Including VAT");
        
        LinesArray.Add(LineJson);
    end;

    local procedure AddAddressFields(var JsonObj: JsonObject; Address: Text[100]; Address2: Text[50]; City: Text[30]; PostCode: Code[20]; County: Text[30]; CountryCode: Code[10])
    begin
        if Address <> '' then
            JsonObj.Add('sellingAddress', Address);
        if Address2 <> '' then
            JsonObj.Add('sellingAddress2', Address2);
        if City <> '' then
            JsonObj.Add('sellingCity', City);
        if PostCode <> '' then
            JsonObj.Add('sellingPostCode', PostCode);
        if County <> '' then
            JsonObj.Add('sellingState', County);
        if CountryCode <> '' then
            JsonObj.Add('sellingCountryCode', CountryCode);
    end;

    local procedure CreateSyncLog(DocumentNo: Code[20]; DocumentDate: Date; DocType: Enum "KLT Document Type"; Direction: Enum "KLT Sync Direction"): Integer
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        SyncLog.Init();
        SyncLog."Entry No." := 0; // Auto-increment
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

    local procedure UpdateSyncLogCompleted(EntryNo: Integer; TargetDocId: Text)
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        if SyncLog.Get(EntryNo) then begin
            SyncLog.Status := SyncLog.Status::Completed;
            SyncLog."Sync End Time" := CurrentDateTime();
            SyncLog."Target Document ID" := CopyStr(TargetDocId, 1, MaxStrLen(SyncLog."Target Document ID"));
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
}
