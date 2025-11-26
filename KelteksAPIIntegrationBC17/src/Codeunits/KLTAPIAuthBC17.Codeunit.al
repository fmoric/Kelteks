/// <summary>
/// Handles OAuth 2.0 authentication for BC27 API access from BC17
/// </summary>
codeunit 50100 "KLT API Auth BC17"
{
    var
        TokenCache: Text;
        TokenExpiry: DateTime;

    procedure GetBC27AccessToken(): Text
    var
        APIConfig: Record "KLT API Config BC17";
    begin
        APIConfig.GetInstance();
        exit(GetAccessToken(APIConfig."BC27 Tenant ID", APIConfig."BC27 Client ID", APIConfig."BC27 Client Secret"));
    end;

    local procedure GetAccessToken(TenantId: Text; ClientId: Text; ClientSecret: Text): Text
    begin
        // Check if we have a valid cached token
        if (TokenCache <> '') and (TokenExpiry > CurrentDateTime()) then
            exit(TokenCache);

        // Get new token
        TokenCache := RequestAccessToken(TenantId, ClientId, ClientSecret);
        TokenExpiry := CurrentDateTime() + (55 * 60 * 1000); // 55 minutes
        
        exit(TokenCache);
    end;

    local procedure RequestAccessToken(TenantId: Text; ClientId: Text; ClientSecret: Text): Text
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        ResponseText: Text;
        AccessToken: Text;
        TokenUrl: Text;
        RequestBody: Text;
    begin
        TokenUrl := StrSubstNo('https://login.microsoftonline.com/%1/oauth2/v2.0/token', TenantId);
        RequestBody := StrSubstNo('grant_type=client_credentials&client_id=%1&client_secret=%2&scope=https://api.businesscentral.dynamics.com/.default',
            ClientId, ClientSecret);

        Content.WriteFrom(RequestBody);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(TokenUrl);
        RequestMessage.Content := Content;

        if not Client.Send(RequestMessage, ResponseMessage) then
            Error('Failed to connect to authentication service.');

        if not ResponseMessage.IsSuccessStatusCode() then
            Error('Authentication failed with status code: %1', ResponseMessage.HttpStatusCode());

        ResponseMessage.Content.ReadAs(ResponseText);
        AccessToken := ExtractAccessTokenFromJson(ResponseText);
        
        if AccessToken = '' then
            Error('Failed to extract access token from response.');

        exit(AccessToken);
    end;

    local procedure ExtractAccessTokenFromJson(JsonText: Text): Text
    var
        JsonObject: JsonObject;
        AccessTokenToken: JsonToken;
    begin
        if not JsonObject.ReadFrom(JsonText) then
            exit('');

        if not JsonObject.Get('access_token', AccessTokenToken) then
            exit('');

        exit(AccessTokenToken.AsValue().AsText());
    end;

    procedure ClearTokenCache()
    begin
        Clear(TokenCache);
        Clear(TokenExpiry);
    end;

    procedure ValidateAuthentication(): Boolean
    var
        Token: Text;
    begin
        Token := GetBC27AccessToken();
        exit(Token <> '');
    end;
}
