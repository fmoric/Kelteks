/// <summary>
/// Document types supported for API synchronization
/// </summary>
enum 50100 "KLT Document Type"
{
    Extensible = true;

    value(0; "Sales Invoice")
    {
        Caption = 'Sales Invoice';
    }
    value(1; "Sales Credit Memo")
    {
        Caption = 'Sales Credit Memo';
    }
    value(2; "Purchase Invoice")
    {
        Caption = 'Purchase Invoice';
    }
    value(3; "Purchase Credit Memo")
    {
        Caption = 'Purchase Credit Memo';
    }
}
