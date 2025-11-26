/// <summary>
/// Handles outbound sales document synchronization from BC17 to BC27
/// Transfers posted sales invoices and credit memos
/// </summary>
codeunit 50102 "KLT Sales Doc Sync"
{
    var
        APIHelper: Codeunit "KLT API Helper";

    /// <summary>
    /// Synchronize posted sales invoices from BC17 to BC27
    /// </summary>
    procedure SyncSalesInvoices()
    var
        APIConfig: Record "KLT API Configuration";
        ResponseText: Text;
        Url: Text;
        Filter: Text;
        LastSyncDateTime: DateTime;
    begin
        APIConfig.GetInstance();
        
        if not APIConfig.ValidateConfiguration() then
            Error('API Configuration is not complete. Please configure the API settings first.');

        // Get documents modified since last sync
        LastSyncDateTime := GetLastSyncDateTime("KLT Document Type"::"Sales Invoice", "KLT Sync Direction"::Outbound);
        if LastSyncDateTime <> 0DT then
            Filter := StrSubstNo('lastModifiedDateTime gt %1', Format(LastSyncDateTime, 0, 9));

        Url := APIHelper.BuildApiUrlWithFilter(
            APIConfig."BC17 Base URL",
            APIConfig."BC17 Company ID",
            'salesInvoices',
            Filter);

        if APIHelper.SendGetRequest(Url, 'BC17', ResponseText) then
            ProcessSalesDocuments(ResponseText, "KLT Document Type"::"Sales Invoice")
        else
            Error('Failed to retrieve sales invoices from BC17: %1', ResponseText);
    end;

    /// <summary>
    /// Synchronize posted sales credit memos from BC17 to BC27
    /// </summary>
    procedure SyncSalesCreditMemos()
    var
        APIConfig: Record "KLT API Configuration";
        ResponseText: Text;
        Url: Text;
        Filter: Text;
        LastSyncDateTime: DateTime;
    begin
        APIConfig.GetInstance();
        
        if not APIConfig.ValidateConfiguration() then
            Error('API Configuration is not complete. Please configure the API settings first.');

        // Get documents modified since last sync
        LastSyncDateTime := GetLastSyncDateTime("KLT Document Type"::"Sales Credit Memo", "KLT Sync Direction"::Outbound);
        if LastSyncDateTime <> 0DT then
            Filter := StrSubstNo('lastModifiedDateTime gt %1', Format(LastSyncDateTime, 0, 9));

        Url := APIHelper.BuildApiUrlWithFilter(
            APIConfig."BC17 Base URL",
            APIConfig."BC17 Company ID",
            'salesCreditMemos',
            Filter);

        if APIHelper.SendGetRequest(Url, 'BC17', ResponseText) then
            ProcessSalesDocuments(ResponseText, "KLT Document Type"::"Sales Credit Memo")
        else
            Error('Failed to retrieve sales credit memos from BC17: %1', ResponseText);
    end;

    /// <summary>
    /// Process sales documents from API response
    /// </summary>
    local procedure ProcessSalesDocuments(JsonResponse: Text; DocType: Enum "KLT Document Type")
    var
        JsonObject: JsonObject;
        ValueToken: JsonToken;
        DocumentArray: JsonArray;
        DocumentToken: JsonToken;
        ProcessedCount: Integer;
    begin
        if not JsonObject.ReadFrom(JsonResponse) then
            Error('Failed to parse JSON response.');

        if not JsonObject.Get('value', ValueToken) then
            exit; // No documents found

        DocumentArray := ValueToken.AsArray();
        
        foreach DocumentToken in DocumentArray do begin
            if ProcessSingleDocument(DocumentToken, DocType) then
                ProcessedCount += 1;
        end;

        Message('Processed %1 %2(s).', ProcessedCount, DocType);
    end;

    /// <summary>
    /// Process a single sales document
    /// </summary>
    local procedure ProcessSingleDocument(DocumentToken: JsonToken; DocType: Enum "KLT Document Type"): Boolean
    var
        SyncLog: Record "KLT Document Sync Log";
        SyncError: Record "KLT Document Sync Error";
        DocumentObject: JsonObject;
        SourceDocNo: Code[20];
        ExternalDocNo: Code[35];
        SystemId: Guid;
        TargetDocNo: Code[20];
        TargetSystemId: Guid;
        ErrorMsg: Text;
    begin
        DocumentObject := DocumentToken.AsObject();
        
        // Extract key fields
        SourceDocNo := CopyStr(GetJsonValueAsText(DocumentObject, 'number'), 1, 20);
        ExternalDocNo := CopyStr(GetJsonValueAsText(DocumentObject, 'externalDocumentNumber'), 1, 35);
        SystemId := GetJsonValueAsGuid(DocumentObject, 'id');

        // Check for duplicates
        if APIHelper.CheckDuplicateExists(ExternalDocNo, "KLT Sync Direction"::Outbound) then begin
            Message('Document %1 already synchronized (External Doc No: %2). Skipping.', SourceDocNo, ExternalDocNo);
            exit(false);
        end;

        // Create sync log entry
        SyncLog.Init();
        SyncLog."Sync Direction" := "KLT Sync Direction"::Outbound;
        SyncLog."Document Type" := DocType;
        SyncLog."Source Document No." := SourceDocNo;
        SyncLog."Source System ID" := SystemId;
        SyncLog."External Document No." := ExternalDocNo;
        SyncLog.Status := SyncLog.Status::"In Progress";
        SyncLog.Insert(true);

        // Create document in BC27
        if CreateDocumentInBC27(DocumentObject, DocType, TargetDocNo, TargetSystemId, ErrorMsg) then begin
            SyncLog.MarkAsCompleted(TargetDocNo, TargetSystemId);
            exit(true);
        end else begin
            SyncLog.MarkAsFailed(ErrorMsg);
            
            // Create error entry
            SyncError.Init();
            SyncError."Sync Log Entry No." := SyncLog."Entry No.";
            SyncError."Error Category" := APIHelper.CategorizeError(ErrorMsg);
            SyncError."Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen(SyncError."Error Message"));
            SyncError."Document Type" := DocType;
            SyncError."Document No." := SourceDocNo;
            SyncError."External Document No." := ExternalDocNo;
            SyncError."Max Retry Attempts" := 3;
            SyncError.Insert(true);
            
            exit(false);
        end;
    end;

    /// <summary>
    /// Create sales document in BC27
    /// </summary>
    local procedure CreateDocumentInBC27(SourceDocument: JsonObject; DocType: Enum "KLT Document Type"; var TargetDocNo: Code[20]; var TargetSystemId: Guid; var ErrorMsg: Text): Boolean
    var
        APIConfig: Record "KLT API Configuration";
        RequestBody: Text;
        ResponseText: Text;
        Url: Text;
        EntityName: Text;
    begin
        APIConfig.GetInstance();

        // Determine API endpoint based on document type
        if DocType = DocType::"Sales Invoice" then
            EntityName := 'salesInvoices'
        else
            EntityName := 'salesCreditMemos';

        Url := APIHelper.BuildApiUrl(
            APIConfig."BC27 Base URL",
            APIConfig."BC27 Company ID",
            EntityName);

        // Build request body
        RequestBody := BuildSalesDocumentJson(SourceDocument);

        // Send POST request to create document
        if APIHelper.SendPostRequest(Url, RequestBody, 'BC27', ResponseText) then begin
            // Extract created document details
            if ExtractDocumentDetails(ResponseText, TargetDocNo, TargetSystemId) then
                exit(true)
            else begin
                ErrorMsg := 'Failed to extract created document details from response.';
                exit(false);
            end;
        end else begin
            ErrorMsg := ResponseText;
            exit(false);
        end;
    end;

    /// <summary>
    /// Build JSON for sales document creation
    /// </summary>
    local procedure BuildSalesDocumentJson(SourceDocument: JsonObject): Text
    var
        RequestJson: JsonObject;
        CustomerNo: Text;
        PostingDate: Date;
        DocumentDate: Date;
    begin
        // Extract header fields
        CustomerNo := GetJsonValueAsText(SourceDocument, 'customerNumber');
        PostingDate := GetJsonValueAsDate(SourceDocument, 'postingDate');
        DocumentDate := GetJsonValueAsDate(SourceDocument, 'documentDate');

        // Build minimal request JSON for document creation
        // Note: In BC27, the document will be created as unposted
        RequestJson.Add('customerNumber', CustomerNo);
        RequestJson.Add('postingDate', Format(PostingDate, 0, 9));
        RequestJson.Add('documentDate', Format(DocumentDate, 0, 9));
        
        // Add optional fields
        AddOptionalField(RequestJson, SourceDocument, 'externalDocumentNumber');
        AddOptionalField(RequestJson, SourceDocument, 'currencyCode');
        AddOptionalField(RequestJson, SourceDocument, 'paymentTermsCode');
        AddOptionalField(RequestJson, SourceDocument, 'shipmentMethodCode');
        AddOptionalField(RequestJson, SourceDocument, 'salespersonCode');
        
        // Write to text
        exit(Format(RequestJson));
    end;

    /// <summary>
    /// Add optional field to JSON if it exists in source
    /// </summary>
    local procedure AddOptionalField(var TargetJson: JsonObject; SourceJson: JsonObject; FieldName: Text)
    var
        FieldValue: Text;
    begin
        FieldValue := GetJsonValueAsText(SourceJson, FieldName);
        if FieldValue <> '' then
            TargetJson.Add(FieldName, FieldValue);
    end;

    /// <summary>
    /// Extract document details from response
    /// </summary>
    local procedure ExtractDocumentDetails(ResponseText: Text; var DocNo: Code[20]; var SysId: Guid): Boolean
    var
        ResponseJson: JsonObject;
    begin
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);

        DocNo := CopyStr(GetJsonValueAsText(ResponseJson, 'number'), 1, 20);
        SysId := GetJsonValueAsGuid(ResponseJson, 'id');
        
        exit((DocNo <> '') and (not IsNullGuid(SysId)));
    end;

    /// <summary>
    /// Get last sync date/time for incremental sync
    /// </summary>
    local procedure GetLastSyncDateTime(DocType: Enum "KLT Document Type"; Direction: Enum "KLT Sync Direction"): DateTime
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        SyncLog.SetRange("Document Type", DocType);
        SyncLog.SetRange("Sync Direction", Direction);
        SyncLog.SetRange(Status, SyncLog.Status::Completed);
        if SyncLog.FindLast() then
            exit(SyncLog."Completed DateTime");
        exit(0DT);
    end;

    // Helper functions for JSON parsing
    local procedure GetJsonValueAsText(JsonObj: JsonObject; Key: Text): Text
    var
        Token: JsonToken;
    begin
        if JsonObj.Get(Key, Token) then
            if not Token.AsValue().IsNull() then
                exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure GetJsonValueAsGuid(JsonObj: JsonObject; Key: Text): Guid
    var
        Token: JsonToken;
        GuidValue: Guid;
    begin
        if JsonObj.Get(Key, Token) then
            if not Token.AsValue().IsNull() then
                if Evaluate(GuidValue, Token.AsValue().AsText()) then
                    exit(GuidValue);
        exit(GuidValue);
    end;

    local procedure GetJsonValueAsDate(JsonObj: JsonObject; Key: Text): Date
    var
        Token: JsonToken;
        DateValue: Date;
    begin
        if JsonObj.Get(Key, Token) then
            if not Token.AsValue().IsNull() then
                if Evaluate(DateValue, Token.AsValue().AsText()) then
                    exit(DateValue);
        exit(DateValue);
    end;
}
