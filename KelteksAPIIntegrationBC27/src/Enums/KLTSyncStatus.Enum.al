/// <summary>
/// Synchronization status for document transfer
/// </summary>
enum 50101 "KLT Sync Status"
{
    Extensible = true;

    value(0; Pending)
    {
        Caption = 'Pending';
    }
    value(1; "In Progress")
    {
        Caption = 'In Progress';
    }
    value(2; Completed)
    {
        Caption = 'Completed';
    }
    value(3; Failed)
    {
        Caption = 'Failed';
    }
    value(4; Retrying)
    {
        Caption = 'Retrying';
    }
}
