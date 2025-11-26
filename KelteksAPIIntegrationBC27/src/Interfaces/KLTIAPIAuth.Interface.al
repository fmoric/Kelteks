/// <summary>
/// Interface for API authentication operations
/// Supports OAuth 2.0, Basic, Windows, and Certificate authentication
/// </summary>
interface "KLT IAPI Auth"
{
    /// <summary>
    /// Gets access token for the target environment
    /// </summary>
    procedure GetAccessToken(): Text;

    /// <summary>
    /// Adds authentication header to HttpClient
    /// </summary>
    procedure AddAuthenticationHeader(var Client: HttpClient);

    /// <summary>
    /// Validates authentication configuration and tests connection
    /// </summary>
    procedure ValidateAuthentication(): Boolean;

    /// <summary>
    /// Clears cached token (for OAuth)
    /// </summary>
    procedure ClearTokenCache();

    /// <summary>
    /// Gets the current authentication method name
    /// </summary>
    procedure GetAuthMethodName(): Text;
}
