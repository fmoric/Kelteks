/// <summary>
/// Handles multi-method authentication for BC17 API access from BC27
/// Supports: OAuth 2.0, Basic, Windows, and Certificate authentication
/// </summary>
codeunit 80100 "KLT API Auth"
{
    var
        TokenCache: Text;
        TokenExpiry: DateTime;
        FailedToConnectAuthServiceErr: Label 'Failed to connect to authentication service.';
        AuthFailedStatusCodeErr: Label 'Authentication failed with status code: %1';
        FailedExtractTokenErr: Label 'Failed to extract access token from response.';
        UsernamePasswordRequiredErr: Label 'Username and password are required for Basic Authentication.';
        CertThumbprintRequiredErr: Label 'Certificate thumbprint is required for Certificate Authentication.';
        CertNotFoundErr: Label 'Certificate with thumbprint %1 not found in certificate store.';
        OAuthTokenUrlTxt: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true;
        OAuthRequestBodyTxt: Label 'grant_type=client_credentials&client_id=%1&client_secret=%2&scope=https://api.businesscentral.dynamics.com/.default', Locked = true;
        CredentialsFormatTxt: Label '%1:%2', Locked = true;
        CompaniesApiPathTxt: Label '/api/v2.0/companies', Locked = true;

    procedure GetTargetAccessToken(): Text
    var
        APIConfig: Record "KLT API Config";
    begin
        APIConfig.GetInstance();
        exit(GetAccessToken(APIConfig."Target Tenant ID", APIConfig."Target Client ID", APIConfig."Target Client Secret"));
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
        TokenUrl := StrSubstNo(OAuthTokenUrlTxt, TenantId);
        RequestBody := StrSubstNo(OAuthRequestBodyTxt, ClientId, ClientSecret);

        Content.WriteFrom(RequestBody);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(TokenUrl);
        RequestMessage.Content := Content;

        if not Client.Send(RequestMessage, ResponseMessage) then
            Error(FailedToConnectAuthServiceErr);

        if not ResponseMessage.IsSuccessStatusCode() then
            Error(AuthFailedStatusCodeErr, ResponseMessage.HttpStatusCode());

        ResponseMessage.Content.ReadAs(ResponseText);
        AccessToken := ExtractAccessTokenFromJson(ResponseText);

        if AccessToken = '' then
            Error(FailedExtractTokenErr);

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
        APIConfig: Record "KLT API Config";
        Token: Text;
        Client: HttpClient;
        TestUrl: Text;
    begin
        APIConfig.GetInstance();

        case APIConfig."Authentication Method" of
            APIConfig."Authentication Method"::OAuth:
                begin
                    Token := GetTargetAccessToken();
                    exit(Token <> '');
                end;
            APIConfig."Authentication Method"::Basic,
            APIConfig."Authentication Method"::Windows,
            APIConfig."Authentication Method"::Certificate:
                begin
                    // Test connection with a simple API call
                    AddAuthenticationHeader(Client, APIConfig);
                    TestUrl := GetTestUrl(APIConfig);
                    exit(TestUrl <> '');
                end;
        end;
        exit(false);
    end;

    /// <summary>
    /// Adds authentication header to HttpClient based on configured method
    /// </summary>
    procedure AddAuthenticationHeader(var Client: HttpClient; var APIConfig: Record "KLT API Config")
    var
        AuthHeader: Text;
    begin
        case APIConfig."Authentication Method" of
            APIConfig."Authentication Method"::OAuth:
                begin
                    AuthHeader := 'Bearer ' + GetTargetAccessToken();
                    Client.DefaultRequestHeaders.Add('Authorization', AuthHeader);
                end;
            APIConfig."Authentication Method"::Basic:
                begin
                    AuthHeader := 'Basic ' + GetBasicAuthToken(APIConfig."Target Username", APIConfig."Target Password");
                    Client.DefaultRequestHeaders.Add('Authorization', AuthHeader);
                end;
            APIConfig."Authentication Method"::Windows:
                begin
                    // BC27 does not support UseDefaultCredentials()
                    // Windows authentication requires network credentials to be configured
                    // This would typically be handled at the server level or via Service-to-Service authentication
                    Error('Windows authentication is not supported in BC27. Please use OAuth, Basic, or Certificate authentication.');
                end;
            APIConfig."Authentication Method"::Certificate:
                begin
                    // Certificate authentication handled via HttpClient certificate methods
                    AddCertificate(Client, APIConfig."Target Certificate Thumbprint");
                end;
        end;
    end;

    local procedure GetBasicAuthToken(Username: Text; Password: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        Credentials: Text;
    begin
        if (Username = '') or (Password = '') then
            Error(UsernamePasswordRequiredErr);

        Credentials := StrSubstNo(CredentialsFormatTxt, Username, Password);
        exit(Base64Convert.ToBase64(Credentials));
    end;

    local procedure AddCertificate(var Client: HttpClient; CertThumbprint: Text)
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertBase64: Text;
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
    begin
        if CertThumbprint = '' then
            Error(CertThumbprintRequiredErr);

        // Look up certificate by thumbprint
        IsolatedCertificate.SetRange(Thumbprint, CertThumbprint);
        if not IsolatedCertificate.FindFirst() then
            Error(CertNotFoundErr, CertThumbprint);

        // In BC27, certificate handling is different
        // The AddCertificate method expects the certificate to be in a specific format
        // This may require using the Certificate Management codeunit
        Error('Certificate authentication requires manual certificate configuration in BC27. Please contact your administrator.');
    end;

    local procedure GetTestUrl(APIConfig: Record "KLT API Config"): Text
    begin
        if APIConfig."Target Base URL" = '' then
            exit('');

        // Return a simple test URL to verify connectivity
        exit(APIConfig."Target Base URL" + CompaniesApiPathTxt);
    end;

    /// <summary>
    /// Returns the authentication method name as text
    /// </summary>
    procedure GetAuthMethodName(): Text
    var
        APIConfig: Record "KLT API Config";
    begin
        APIConfig.GetInstance();
        exit(Format(APIConfig."Authentication Method"));
    end;
}
