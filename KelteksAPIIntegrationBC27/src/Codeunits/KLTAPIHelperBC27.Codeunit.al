/// <summary>
/// HTTP Helper for BC27 - Handles API communication with BC17
/// Provides GET/POST methods with authentication, JSON parsing, and error handling
/// </summary>
codeunit 50151 "KLT API Helper BC27"
{
    var
        APIAuth: Codeunit "KLT API Auth BC27";

    /// <summary>
    /// Sends HTTP GET request to BC17 API
    /// </summary>
    procedure SendGetRequest(Endpoint: Text; var ResponseJson: JsonObject): Boolean
    var
        APIConfig: Record "KLT API Config BC27";
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
        FullUrl: Text;
    begin
        APIConfig.GetInstance();
        
        // Build full URL
        FullUrl := BuildUrl(APIConfig."BC17 Base URL", Endpoint);
        
        // Configure HTTP client
        ConfigureHttpClient(Client, APIConfig);
        
        // Add authentication
        APIAuth.AddAuthenticationHeader(Client, APIConfig);
        
        // Send request
        if not Client.Get(FullUrl, Response) then begin
            LogError('HTTP GET request failed: Connection error', Endpoint);
            exit(false);
        end;
        
        // Check status
        if not Response.IsSuccessStatusCode() then begin
            LogError(StrSubstNo('HTTP GET failed with status %1', Response.HttpStatusCode()), Endpoint);
            exit(false);
        end;
        
        // Parse response
        Response.Content.ReadAs(ResponseText);
        if not ResponseJson.ReadFrom(ResponseText) then begin
            LogError('Failed to parse JSON response', Endpoint);
            exit(false);
        end;
        
        exit(true);
    end;

    /// <summary>
    /// Sends HTTP POST request to BC17 API
    /// </summary>
    procedure SendPostRequest(Endpoint: Text; RequestJson: JsonObject; var ResponseJson: JsonObject): Boolean
    var
        APIConfig: Record "KLT API Config BC27";
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
        FullUrl := BuildUrl(APIConfig."BC17 Base URL", Endpoint);
        
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
            LogError('HTTP POST request failed: Connection error', Endpoint);
            exit(false);
        end;
        
        // Check status
        if not Response.IsSuccessStatusCode() then begin
            Response.Content.ReadAs(ResponseText);
            LogError(StrSubstNo('HTTP POST failed with status %1: %2', Response.HttpStatusCode(), ResponseText), Endpoint);
            exit(false);
        end;
        
        // Parse response
        Response.Content.ReadAs(ResponseText);
        if ResponseText <> '' then begin
            if not ResponseJson.ReadFrom(ResponseText) then begin
                LogError('Failed to parse JSON response', Endpoint);
                exit(false);
            end;
        end;
        
        exit(true);
    end;

    /// <summary>
    /// Sends HTTP PATCH request to BC17 API (for updates)
    /// </summary>
    procedure SendPatchRequest(Endpoint: Text; RequestJson: JsonObject; var ResponseJson: JsonObject): Boolean
    var
        APIConfig: Record "KLT API Config BC27";
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
        FullUrl := BuildUrl(APIConfig."BC17 Base URL", Endpoint);
        
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
            LogError('HTTP PATCH request failed: Connection error', Endpoint);
            exit(false);
        end;
        
        // Check status
        if not Response.IsSuccessStatusCode() then begin
            Response.Content.ReadAs(ResponseText);
            LogError(StrSubstNo('HTTP PATCH failed with status %1: %2', Response.HttpStatusCode(), ResponseText), Endpoint);
            exit(false);
        end;
        
        // Parse response
        Response.Content.ReadAs(ResponseText);
        if ResponseText <> '' then begin
            if not ResponseJson.ReadFrom(ResponseText) then begin
                LogError('Failed to parse JSON response', Endpoint);
                exit(false);
            end;
        end;
        
        exit(true);
    end;

    local procedure ConfigureHttpClient(var Client: HttpClient; APIConfig: Record "KLT API Config BC27")
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
        exit(StrSubstNo('/api/v2.0/companies(%1)/salesInvoices', GetGuidText(CompanyId)));
    end;

    /// <summary>
    /// Builds Sales Credit Memo API endpoint
    /// </summary>
    procedure GetSalesCreditMemoEndpoint(CompanyId: Guid): Text
    begin
        exit(StrSubstNo('/api/v2.0/companies(%1)/salesCreditMemos', GetGuidText(CompanyId)));
    end;

    /// <summary>
    /// Builds Purchase Invoice API endpoint
    /// </summary>
    procedure GetPurchaseInvoiceEndpoint(CompanyId: Guid): Text
    begin
        exit(StrSubstNo('/api/v2.0/companies(%1)/purchaseInvoices', GetGuidText(CompanyId)));
    end;

    /// <summary>
    /// Builds Purchase Credit Memo API endpoint
    /// </summary>
    procedure GetPurchaseCreditMemoEndpoint(CompanyId: Guid): Text
    begin
        exit(StrSubstNo('/api/v2.0/companies(%1)/purchaseCreditMemos', GetGuidText(CompanyId)));
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
        SyncLog: Record "KLT Document Sync Log";
        ErrorMessage: Record "Error Message";
    begin
        // Log to Error Message table
        ErrorMessage.Init();
        ErrorMessage.Description := CopyStr(ErrorText, 1, MaxStrLen(ErrorMessage.Description));
        ErrorMessage."Message" := CopyStr(StrSubstNo('%1 - Context: %2', ErrorText, Context), 1, MaxStrLen(ErrorMessage."Message"));
        ErrorMessage."Created On" := CurrentDateTime();
        if ErrorMessage.Insert() then;
    end;

    /// <summary>
    /// Tests API connectivity
    /// </summary>
    procedure TestConnection(): Boolean
    var
        APIConfig: Record "KLT API Config BC27";
        ResponseJson: JsonObject;
        Endpoint: Text;
    begin
        APIConfig.GetInstance();
        Endpoint := '/api/v2.0/companies';
        exit(SendGetRequest(Endpoint, ResponseJson));
    end;
}
