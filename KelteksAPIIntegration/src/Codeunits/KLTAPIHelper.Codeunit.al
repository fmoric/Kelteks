/// <summary>
/// Common helper functions for API operations
/// Handles HTTP requests, error handling, and logging
/// </summary>
codeunit 50101 "KLT API Helper"
{
    var
        APIAuth: Codeunit "KLT API Authentication";

    /// <summary>
    /// Send GET request to API endpoint
    /// </summary>
    procedure SendGetRequest(Url: Text; Environment: Text; var ResponseText: Text): Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        AccessToken: Text;
        APIConfig: Record "KLT API Configuration";
    begin
        APIConfig.GetInstance();

        // Get access token
        if Environment = 'BC17' then
            AccessToken := APIAuth.GetBC17AccessToken()
        else
            AccessToken := APIAuth.GetBC27AccessToken();

        // Setup request
        RequestMessage.Method := 'GET';
        RequestMessage.SetRequestUri(Url);
        RequestMessage.GetHeaders(Headers);
        Headers.Add('Authorization', StrSubstNo('Bearer %1', AccessToken));
        Headers.Add('Accept', 'application/json');

        // Set timeout
        Client.Timeout(APIConfig."API Timeout (Seconds)" * 1000);

        // Send request
        if not Client.Send(RequestMessage, ResponseMessage) then begin
            ResponseText := 'Network error: Failed to connect to API endpoint.';
            exit(false);
        end;

        ResponseMessage.Content.ReadAs(ResponseText);
        exit(ResponseMessage.IsSuccessStatusCode());
    end;

    /// <summary>
    /// Send POST request to API endpoint
    /// </summary>
    procedure SendPostRequest(Url: Text; RequestBody: Text; Environment: Text; var ResponseText: Text): Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        AccessToken: Text;
        APIConfig: Record "KLT API Configuration";
    begin
        APIConfig.GetInstance();

        // Get access token
        if Environment = 'BC17' then
            AccessToken := APIAuth.GetBC17AccessToken()
        else
            AccessToken := APIAuth.GetBC27AccessToken();

        // Setup content
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        // Setup request
        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(Url);
        RequestMessage.Content := Content;
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', AccessToken));
        RequestHeaders.Add('Accept', 'application/json');

        // Set timeout
        Client.Timeout(APIConfig."API Timeout (Seconds)" * 1000);

        // Send request
        if not Client.Send(RequestMessage, ResponseMessage) then begin
            ResponseText := 'Network error: Failed to connect to API endpoint.';
            exit(false);
        end;

        ResponseMessage.Content.ReadAs(ResponseText);
        exit(ResponseMessage.IsSuccessStatusCode());
    end;

    /// <summary>
    /// Send PATCH request to API endpoint
    /// </summary>
    procedure SendPatchRequest(Url: Text; RequestBody: Text; Environment: Text; var ResponseText: Text): Boolean
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        AccessToken: Text;
        APIConfig: Record "KLT API Configuration";
    begin
        APIConfig.GetInstance();

        // Get access token
        if Environment = 'BC17' then
            AccessToken := APIAuth.GetBC17AccessToken()
        else
            AccessToken := APIAuth.GetBC27AccessToken();

        // Setup content
        Content.WriteFrom(RequestBody);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        // Setup request
        RequestMessage.Method := 'PATCH';
        RequestMessage.SetRequestUri(Url);
        RequestMessage.Content := Content;
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', StrSubstNo('Bearer %1', AccessToken));
        RequestHeaders.Add('Accept', 'application/json');
        RequestHeaders.Add('If-Match', '*'); // Required for OData updates

        // Set timeout
        Client.Timeout(APIConfig."API Timeout (Seconds)" * 1000);

        // Send request
        if not Client.Send(RequestMessage, ResponseMessage) then begin
            ResponseText := 'Network error: Failed to connect to API endpoint.';
            exit(false);
        end;

        ResponseMessage.Content.ReadAs(ResponseText);
        exit(ResponseMessage.IsSuccessStatusCode());
    end;

    /// <summary>
    /// Build API endpoint URL
    /// </summary>
    procedure BuildApiUrl(BaseUrl: Text; CompanyId: Guid; EntityName: Text): Text
    begin
        exit(StrSubstNo('%1/api/v2.0/companies(%2)/%3', BaseUrl, LowerCase(DelChr(Format(CompanyId), '=', '{}')), EntityName));
    end;

    /// <summary>
    /// Build API endpoint URL with filters
    /// </summary>
    procedure BuildApiUrlWithFilter(BaseUrl: Text; CompanyId: Guid; EntityName: Text; Filter: Text): Text
    var
        Url: Text;
    begin
        Url := BuildApiUrl(BaseUrl, CompanyId, EntityName);
        if Filter <> '' then
            Url := StrSubstNo('%1?$filter=%2', Url, Filter);
        exit(Url);
    end;

    /// <summary>
    /// Categorize error based on error message
    /// </summary>
    procedure CategorizeError(ErrorMessage: Text): Enum "KLT Error Category"
    begin
        ErrorMessage := LowerCase(ErrorMessage);

        // Authentication errors
        if (StrPos(ErrorMessage, 'unauthorized') > 0) or
           (StrPos(ErrorMessage, 'authentication') > 0) or
           (StrPos(ErrorMessage, 'token') > 0) then
            exit("KLT Error Category"::Authentication);

        // API Communication errors
        if (StrPos(ErrorMessage, 'network') > 0) or
           (StrPos(ErrorMessage, 'timeout') > 0) or
           (StrPos(ErrorMessage, 'connection') > 0) or
           (StrPos(ErrorMessage, 'unavailable') > 0) then
            exit("KLT Error Category"::"API Communication");

        // Master Data errors
        if (StrPos(ErrorMessage, 'does not exist') > 0) or
           (StrPos(ErrorMessage, 'not found') > 0) or
           (StrPos(ErrorMessage, 'invalid reference') > 0) then
            exit("KLT Error Category"::"Master Data Missing");

        // Data Validation errors
        if (StrPos(ErrorMessage, 'validation') > 0) or
           (StrPos(ErrorMessage, 'required') > 0) or
           (StrPos(ErrorMessage, 'invalid') > 0) then
            exit("KLT Error Category"::"Data Validation");

        // Default to Business Logic
        exit("KLT Error Category"::"Business Logic");
    end;

    /// <summary>
    /// Log API operation
    /// </summary>
    procedure LogApiOperation(Operation: Text; Url: Text; Success: Boolean; ResponseText: Text)
    var
        LogEntry: Text;
    begin
        LogEntry := StrSubstNo('[%1] %2 - %3 - Success: %4',
            CurrentDateTime(),
            Operation,
            Url,
            Success);
        
        if not Success then
            LogEntry += StrSubstNo(' - Error: %1', CopyStr(ResponseText, 1, 200));

        // In production, this should write to a proper log table or telemetry
        // For now, we'll use the error message field in sync log
        Message(LogEntry);
    end;

    /// <summary>
    /// Check if duplicate document exists in target system
    /// </summary>
    procedure CheckDuplicateExists(ExternalDocNo: Code[35]; Direction: Enum "KLT Sync Direction"): Boolean
    var
        SyncLog: Record "KLT Document Sync Log";
    begin
        if ExternalDocNo = '' then
            exit(false);

        SyncLog.SetRange("External Document No.", ExternalDocNo);
        SyncLog.SetRange("Sync Direction", Direction);
        SyncLog.SetRange(Status, SyncLog.Status::Completed);
        exit(not SyncLog.IsEmpty());
    end;

    /// <summary>
    /// Sanitize text for JSON
    /// </summary>
    procedure SanitizeForJson(InputText: Text): Text
    var
        SanitizedText: Text;
    begin
        SanitizedText := InputText;
        SanitizedText := ReplaceString(SanitizedText, '\', '\\');
        SanitizedText := ReplaceString(SanitizedText, '"', '\"');
        SanitizedText := ReplaceString(SanitizedText, Chr(13), '\r');
        SanitizedText := ReplaceString(SanitizedText, Chr(10), '\n');
        SanitizedText := ReplaceString(SanitizedText, Chr(9), '\t');
        exit(SanitizedText);
    end;

    local procedure ReplaceString(String: Text; FindWhat: Text; ReplaceWith: Text): Text
    begin
        exit(String.Replace(FindWhat, ReplaceWith));
    end;
}
