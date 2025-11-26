/// <summary>
/// Error categories for API integration failures
/// </summary>
enum 50152 "KLT Error Category"
{
    Extensible = true;

    value(0; "API Communication")
    {
        Caption = 'API Communication';
    }
    value(1; "Data Validation")
    {
        Caption = 'Data Validation';
    }
    value(2; "Business Logic")
    {
        Caption = 'Business Logic';
    }
    value(3; Authentication)
    {
        Caption = 'Authentication';
    }
    value(4; "Master Data Missing")
    {
        Caption = 'Master Data Missing';
    }
}
