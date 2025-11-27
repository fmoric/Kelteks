/// <summary>
/// Enum KLT Deployment Type (ID 50105).
/// Deployment types for Business Central environments.
/// </summary>
enum 80101 "KLT Deployment Type"
{
    Extensible = true;

    value(0; OnPremise)
    {
        Caption = 'On-Premise';
    }
    value(1; SaaS)
    {
        Caption = 'SaaS (Cloud)';
    }
    value(2; Hybrid)
    {
        Caption = 'Hybrid';
    }
}
