/// <summary>
/// Enum KLT Deployment Type BC27 (ID 50155).
/// Deployment types for Business Central environments.
/// </summary>
enum 50155 "KLT Deployment Type BC27"
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
