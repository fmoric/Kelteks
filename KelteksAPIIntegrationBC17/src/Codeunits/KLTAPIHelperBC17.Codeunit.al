/// <summary>
/// HTTP Helper for BC17 - Handles API communication with BC27
/// Provides GET/POST methods with authentication, JSON parsing, and error handling
/// </summary>
codeunit 50101 "KLT API Helper BC17"
{
    var
        APIAuth: Codeunit "KLT API Auth BC17";
        HTTPGetFailedConnErr: Label 'HTTP GET request failed: Connection error';
        HTTPGetFailedStatusErr: Label 'HTTP GET failed with status %1';
        FailedParseJSONErr: Label 'Failed to parse JSON response';
        HTTPPostFailedConnErr: Label 'HTTP POST request failed: Connection error';
        HTTPPostFailedStatusErr: Label 'HTTP POST failed with status %1: %2';
        HTTPPatchFailedConnErr: Label 'HTTP PATCH request failed: Connection error';
        HTTPPatchFailedStatusErr: Label 'HTTP PATCH failed with status %1: %2';
        SalesInvoicesEndpointTxt: Label '/api/v2.0/companies(%1)/salesInvoices', Locked = true;
        SalesCreditMemosEndpointTxt: Label '/api/v2.0/companies(%1)/salesCreditMemos', Locked = true;
        PurchaseInvoicesEndpointTxt: Label '/api/v2.0/companies(%1)/purchaseInvoices', Locked = true;
        PurchaseCreditMemosEndpointTxt: Label '/api/v2.0/companies(%1)/purchaseCreditMemos', Locked = true;
        CompaniesEndpointTxt: Label '/api/v2.0/companies', Locked = true;
        ErrorContextTxt: Label '%1 - Context: %2', Locked = true;

    /// <summary>
    /// Sends HTTP GET request to BC27 API
    /// </summary>
    procedure SendGetRequest(Endpoint: Text; var ResponseJson: JsonObject): Boolean
    var
        APIConfig: Record "KLT API Config BC17";
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
        FullUrl: Text;
    begin
        APIConfig.GetInstance();
        
        // Build full URL
        FullUrl := BuildUrl(APIConfig."BC27 Base URL", Endpoint);
        
        // Configure HTTP client
        ConfigureHttpClient(Client, APIConfig);
        
        // Add authentication
        APIAuth.AddAuthenticationHeader(Client, APIConfig);
        
        // Send request
        if not Client.Get(FullUrl, Response) then begin
            LogError(HTTPGetFailedConnErr, Endpoint);
            exit(false);
        end;
        
        // Check status
        if not Response.IsSuccessStatusCode() then begin
            LogError(StrSubstNo(HTTPGetFailedStatusErr, Response.HttpStatusCode()), Endpoint);
            exit(false);
        end;
        
        // Parse response
        Response.Content.ReadAs(ResponseText);
        if not ResponseJson.ReadFrom(ResponseText) then begin
            LogError(FailedParseJSONErr, Endpoint);
            exit(false);
        end;
        
        exit(true);
    end;

    /// <summary>
    /// Sends HTTP POST request to BC27 API
    /// </summary>
    procedure SendPostRequest(Endpoint: Text; RequestJson: JsonObject; var ResponseJson: JsonObject): Boolean
    var
        APIConfig: Record "KLT API Config BC17";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        RequestText: Text;
        ResponseText: Text;
        FullUrl: Text;
    begin
        APIConfig.GetInstance();
        
        // Build full URL
        FullUrl := BuildUrl(APIConfig."BC27 Base URL", Endpoint);
        
        // Configure HTTP client
        ConfigureHttpClient(Client, APIConfig);
        
        // Add authentication
        APIAuth.AddAuthenticationHeader(Client, APIConfig);
        
        // Prepare request
        RequestJson.WriteTo(RequestText);
        Content.WriteFrom(RequestText);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        
        Request.Method := 'POST';
        Request.SetRequestUri(FullUrl);
        Request.Content := Content;
        
        // Send request
        if not Client.Send(Request, Response) then begin
            LogError(HTTPPostFailedConnErr, Endpoint);
            exit(false);
        end;
        
        // Check status
        if not Response.IsSuccessStatusCode() then begin
            Response.Content.ReadAs(ResponseText);
            LogError(StrSubstNo(HTTPPostFailedStatusErr, Response.HttpStatusCode(), ResponseText), Endpoint);
            exit(false);
        end;
        
        // Parse response
        Response.Content.ReadAs(ResponseText);
        if ResponseText <> '' then begin
            if not ResponseJson.ReadFrom(ResponseText) then begin
                LogError(FailedParseJSONErr, Endpoint);
                exit(false);
            end;
        end;
        
        exit(true);
    end;

    /// <summary>
    /// Sends HTTP PATCH request to BC27 API (for updates)
    /// </summary>
    procedure SendPatchRequest(Endpoint: Text; RequestJson: JsonObject; var ResponseJson: JsonObject): Boolean
    var
        APIConfig: Record "KLT API Config BC17";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        RequestText: Text;
        ResponseText: Text;
        FullUrl: Text;
    begin
        APIConfig.GetInstance();
        
        // Build full URL
        FullUrl := BuildUrl(APIConfig."BC27 Base URL", Endpoint);
        
        // Configure HTTP client
        ConfigureHttpClient(Client, APIConfig);
        
        // Add authentication
        APIAuth.AddAuthenticationHeader(Client, APIConfig);
        
        // Prepare request
        RequestJson.WriteTo(RequestText);
        Content.WriteFrom(RequestText);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        
        Request.Method := 'PATCH';
        Request.SetRequestUri(FullUrl);
        Request.Content := Content;
        
        // Send request
        if not Client.Send(Request, Response) then begin
            LogError(HTTPPatchFailedConnErr, Endpoint);
            exit(false);
        end;
        
        // Check status
        if not Response.IsSuccessStatusCode() then begin
            Response.Content.ReadAs(ResponseText);
            LogError(StrSubstNo(HTTPPatchFailedStatusErr, Response.HttpStatusCode(), ResponseText), Endpoint);
            exit(false);
        end;
        
        // Parse response
        Response.Content.ReadAs(ResponseText);
        if ResponseText <> '' then begin
            if not ResponseJson.ReadFrom(ResponseText) then begin
                LogError(FailedParseJSONErr, Endpoint);
                exit(false);
            end;
        end;
        
        exit(true);
    end;

    local procedure ConfigureHttpClient(var Client: HttpClient; APIConfig: Record "KLT API Config BC17")
    begin
        Client.Timeout := APIConfig."API Timeout (Seconds)" * 1000; // Convert to milliseconds
        Client.DefaultRequestHeaders.Add('Accept', 'application/json');
    end;

    local procedure BuildUrl(BaseUrl: Text; Endpoint: Text): Text
    begin
        // Remove trailing slash from base URL
        if BaseUrl.EndsWith('/') then
            BaseUrl := CopyStr(BaseUrl, 1, StrLen(BaseUrl) - 1);
        
        // Ensure endpoint starts with /
        if not Endpoint.StartsWith('/') then
            Endpoint := '/' + Endpoint;
        
        exit(BaseUrl + Endpoint);
    end;

    /// <summary>
    /// Builds Sales Invoice API endpoint
    /// </summary>
    procedure GetSalesInvoiceEndpoint(CompanyId: Guid): Text
    begin
        exit(StrSubstNo(SalesInvoicesEndpointTxt, GetGuidText(CompanyId)));
    end;

    /// <summary>
    /// Builds Sales Credit Memo API endpoint
    /// </summary>
    procedure GetSalesCreditMemoEndpoint(CompanyId: Guid): Text
    begin
        exit(StrSubstNo(SalesCreditMemosEndpointTxt, GetGuidText(CompanyId)));
    end;

    /// <summary>
    /// Builds Purchase Invoice API endpoint
    /// </summary>
    procedure GetPurchaseInvoiceEndpoint(CompanyId: Guid): Text
    begin
        exit(StrSubstNo(PurchaseInvoicesEndpointTxt, GetGuidText(CompanyId)));
    end;

    /// <summary>
    /// Builds Purchase Credit Memo API endpoint
    /// </summary>
    procedure GetPurchaseCreditMemoEndpoint(CompanyId: Guid): Text
    begin
        exit(StrSubstNo(PurchaseCreditMemosEndpointTxt, GetGuidText(CompanyId)));
    end;

    local procedure GetGuidText(GuidValue: Guid): Text
    var
        GuidText: Text;
    begin
        GuidText := Format(GuidValue);
        GuidText := DelChr(GuidText, '=', '{}'); // Remove curly braces
        exit(GuidText);
    end;

    /// <summary>
    /// Extracts value array from OData response
    /// </summary>
    procedure GetValueArray(ResponseJson: JsonObject; var ValueArray: JsonArray): Boolean
    var
        ValueToken: JsonToken;
    begin
        if not ResponseJson.Get('value', ValueToken) then
            exit(false);
        
        if not ValueToken.IsArray() then
            exit(false);
        
        ValueArray := ValueToken.AsArray();
        exit(true);
    end;

    /// <summary>
    /// Gets text value from JSON object
    /// </summary>
    procedure GetJsonText(JObject: JsonObject; KeyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit('');
        
        if JToken.IsValue() then
            exit(JToken.AsValue().AsText());
        
        exit('');
    end;

    /// <summary>
    /// Gets decimal value from JSON object
    /// </summary>
    procedure GetJsonDecimal(JObject: JsonObject; KeyName: Text): Decimal
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit(0);
        
        if JToken.IsValue() then
            exit(JToken.AsValue().AsDecimal());
        
        exit(0);
    end;

    /// <summary>
    /// Gets integer value from JSON object
    /// </summary>
    procedure GetJsonInteger(JObject: JsonObject; KeyName: Text): Integer
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit(0);
        
        if JToken.IsValue() then
            exit(JToken.AsValue().AsInteger());
        
        exit(0);
    end;

    /// <summary>
    /// Gets date value from JSON object
    /// </summary>
    procedure GetJsonDate(JObject: JsonObject; KeyName: Text): Date
    var
        JToken: JsonToken;
        DateText: Text;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit(0D);
        
        if JToken.IsValue() then begin
            DateText := JToken.AsValue().AsText();
            exit(ParseDate(DateText));
        end;
        
        exit(0D);
    end;

    local procedure ParseDate(DateText: Text): Date
    var
        DateVar: Date;
    begin
        if Evaluate(DateVar, DateText) then
            exit(DateVar);
        exit(0D);
    end;

    /// <summary>
    /// Gets GUID value from JSON object
    /// </summary>
    procedure GetJsonGuid(JObject: JsonObject; KeyName: Text): Guid
    var
        JToken: JsonToken;
        GuidText: Text;
        GuidVar: Guid;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit(GuidVar);
        
        if JToken.IsValue() then begin
            GuidText := JToken.AsValue().AsText();
            if Evaluate(GuidVar, GuidText) then
                exit(GuidVar);
        end;
        
        exit(GuidVar);
    end;

    local procedure LogError(ErrorText: Text; Context: Text)
    var
        ErrorMessage: Record "Error Message";
    begin
        // Use Error Message built-in procedure
        ErrorMessage.LogMessage(0, StrSubstNo(ErrorContextTxt, ErrorText, Context), ErrorText, Enum::"Error Msg. Fix Implementation"::None);
    end;

    /// <summary>
    /// Tests API connectivity
    /// </summary>
    procedure TestConnection(): Boolean
    var
        APIConfig: Record "KLT API Config BC17";
        ResponseJson: JsonObject;
        Endpoint: Text;
    begin
        APIConfig.GetInstance();
        Endpoint := CompaniesEndpointTxt;
        exit(SendGetRequest(Endpoint, ResponseJson));
    end;
}
