/// <summary>
/// Handles OAuth 2.0 authentication for API access
/// Implements service-to-service authentication using client credentials
/// </summary>
codeunit 50100 "KLT API Authentication"
{
    var
        TokenCache: Dictionary of [Text, Text]; // Cache for access tokens
        TokenExpiryCache: Dictionary of [Text, DateTime]; // Cache for token expiry times

    /// <summary>
    /// Get OAuth 2.0 access token for BC17
    /// </summary>
    procedure GetBC17AccessToken(): Text
    var
        APIConfig: Record "KLT API Configuration";
    begin
        APIConfig.GetInstance();
        exit(GetAccessToken(APIConfig."BC17 Tenant ID", APIConfig."BC17 Client ID", APIConfig."BC17 Client Secret", 'BC17'));
    end;

    /// <summary>
    /// Get OAuth 2.0 access token for BC27
    /// </summary>
    procedure GetBC27AccessToken(): Text
    var
        APIConfig: Record "KLT API Configuration";
    begin
        APIConfig.GetInstance();
        exit(GetAccessToken(APIConfig."BC27 Tenant ID", APIConfig."BC27 Client ID", APIConfig."BC27 Client Secret", 'BC27'));
    end;

    /// <summary>
    /// Get access token with caching
    /// </summary>
    local procedure GetAccessToken(TenantId: Text; ClientId: Text; ClientSecret: Text; CacheKey: Text): Text
    var
        CachedToken: Text;
        CachedExpiry: DateTime;
    begin
        // Check if we have a valid cached token
        if TokenCache.ContainsKey(CacheKey) then begin
            if TokenExpiryCache.Get(CacheKey, CachedExpiry) then begin
                if CachedExpiry > CurrentDateTime() then begin
                    TokenCache.Get(CacheKey, CachedToken);
                    exit(CachedToken);
                end;
            end;
        end;

        // Get new token
        CachedToken := RequestAccessToken(TenantId, ClientId, ClientSecret);
        
        // Cache token for 55 minutes (tokens typically valid for 60 minutes)
        if TokenCache.ContainsKey(CacheKey) then
            TokenCache.Set(CacheKey, CachedToken)
        else
            TokenCache.Add(CacheKey, CachedToken);

        CachedExpiry := CurrentDateTime() + (55 * 60 * 1000);
        if TokenExpiryCache.ContainsKey(CacheKey) then
            TokenExpiryCache.Set(CacheKey, CachedExpiry)
        else
            TokenExpiryCache.Add(CacheKey, CachedExpiry);

        exit(CachedToken);
    end;

    /// <summary>
    /// Request new access token from Azure AD
    /// </summary>
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
        // Build OAuth token endpoint URL
        TokenUrl := StrSubstNo('https://login.microsoftonline.com/%1/oauth2/v2.0/token', TenantId);

        // Build request body
        RequestBody := StrSubstNo('grant_type=client_credentials&client_id=%1&client_secret=%2&scope=https://api.businesscentral.dynamics.com/.default',
            ClientId, ClientSecret);

        Content.WriteFrom(RequestBody);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(TokenUrl);
        RequestMessage.Content := Content;

        // Send request
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

    /// <summary>
    /// Extract access token from JSON response
    /// </summary>
    local procedure ExtractAccessTokenFromJson(JsonText: Text): Text
    var
        JsonObject: JsonObject;
        AccessTokenToken: JsonToken;
        AccessToken: Text;
    begin
        if not JsonObject.ReadFrom(JsonText) then
            exit('');

        if not JsonObject.Get('access_token', AccessTokenToken) then
            exit('');

        AccessToken := AccessTokenToken.AsValue().AsText();
        exit(AccessToken);
    end;

    /// <summary>
    /// Clear token cache (useful for testing or when credentials change)
    /// </summary>
    procedure ClearTokenCache()
    begin
        Clear(TokenCache);
        Clear(TokenExpiryCache);
    end;

    /// <summary>
    /// Validate that authentication works for both environments
    /// </summary>
    procedure ValidateAuthentication(): Boolean
    var
        BC17Token: Text;
        BC27Token: Text;
    begin
        BC17Token := GetBC17AccessToken();
        BC27Token := GetBC27AccessToken();
        
        exit((BC17Token <> '') and (BC27Token <> ''));
    end;
}
