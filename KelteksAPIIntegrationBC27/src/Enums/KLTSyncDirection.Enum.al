/// <summary>
/// Direction of document synchronization
/// </summary>
enum 50153 "KLT Sync Direction"
{
    Extensible = true;

    value(0; "Outbound")
    {
        Caption = 'Outbound (BC17 → BC27)';
    }
    value(1; "Inbound")
    {
        Caption = 'Inbound (BC27 → BC17)';
    }
}
