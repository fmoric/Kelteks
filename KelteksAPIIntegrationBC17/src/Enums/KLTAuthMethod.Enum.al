/// <summary>
/// Enum KLT Auth Method (ID 50104).
/// Authentication methods for API connections.
/// </summary>
enum 80100 "KLT Auth Method"
{
    Extensible = true;

    value(0; OAuth)
    {
        Caption = 'OAuth 2.0';
    }
    value(1; Basic)
    {
        Caption = 'Basic Authentication';
    }
    value(2; Windows)
    {
        Caption = 'Windows Authentication';
    }
    value(3; Certificate)
    {
        Caption = 'Certificate Authentication';
    }
}
