/// <summary>
/// Purchase Document Synchronization for BC27
/// Sends Purchase Invoices and Credit Memos to BC17
/// </summary>
codeunit 50152 "KLT Purchase Doc Sync BC27"
{
    var
        APIHelper: Codeunit "KLT API Helper BC27";
        Validator: Codeunit "KLT Document Validator BC27";

    /// <summary>
    /// Synchronizes a Purchase Invoice to BC17
    /// </summary>
    procedure SyncPurchaseInvoice(var PurchHeader: Record "Purchase Header"): Boolean
    var
        APIConfig: Record "KLT API Config BC27";
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
            "KLT Document Type"::PurchaseInvoice, "KLT Sync Direction"::Outbound);
        
        // Validate document
        if not Validator.ValidatePurchaseInvoice(PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Build JSON request
        if not BuildPurchaseInvoiceJson(PurchHeader, RequestJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'Failed to build JSON request', "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Send to BC17
        Endpoint := APIHelper.GetPurchaseInvoiceEndpoint(APIConfig."BC17 Company ID");
        if not APIHelper.SendPostRequest(Endpoint, RequestJson, ResponseJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'API request failed', "KLT Error Category"::APICommunication);
            exit(false);
        end;
        
        // Update sync log as completed
        UpdateSyncLogCompleted(SyncLogEntryNo, APIHelper.GetJsonText(ResponseJson, 'id'));
        exit(true);
    end;

    /// <summary>
    /// Synchronizes a Purchase Credit Memo to BC17
    /// </summary>
    procedure SyncPurchaseCreditMemo(var PurchHeader: Record "Purchase Header"): Boolean
    var
        APIConfig: Record "KLT API Config BC27";
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
            "KLT Document Type"::PurchaseCreditMemo, "KLT Sync Direction"::Outbound);
        
        // Validate document
        if not Validator.ValidatePurchaseCreditMemo(PurchHeader, ErrorText) then begin
            UpdateSyncLogError(SyncLogEntryNo, ErrorText, "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Build JSON request
        if not BuildPurchaseCreditMemoJson(PurchHeader, RequestJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'Failed to build JSON request', "KLT Error Category"::DataValidation);
            exit(false);
        end;
        
        // Send to BC17
        Endpoint := APIHelper.GetPurchaseCreditMemoEndpoint(APIConfig."BC17 Company ID");
        if not APIHelper.SendPostRequest(Endpoint, RequestJson, ResponseJson) then begin
            UpdateSyncLogError(SyncLogEntryNo, 'API request failed', "KLT Error Category"::APICommunication);
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
}
