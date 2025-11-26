/// <summary>
/// Permission set for Kelteks API Integration
/// </summary>
permissionset 50100 "KLT API Integration"
{
    Assignable = true;
    Caption = 'Kelteks API Integration';
    
    Permissions =
        tabledata "KLT API Configuration" = RIMD,
        tabledata "KLT Document Sync Log" = RIMD,
        tabledata "KLT Document Sync Error" = RIMD,
        tabledata "KLT API Sync Queue" = RIMD,
        table "KLT API Configuration" = X,
        table "KLT Document Sync Log" = X,
        table "KLT Document Sync Error" = X,
        table "KLT API Sync Queue" = X,
        codeunit "KLT API Authentication" = X,
        codeunit "KLT API Helper" = X,
        codeunit "KLT Sales Doc Sync" = X,
        codeunit "KLT Purchase Doc Sync" = X,
        codeunit "KLT Sync Engine" = X,
        page "KLT API Configuration" = X,
        page "KLT Document Sync Log" = X,
        page "KLT Document Sync Error" = X,
        page "KLT Error Details FactBox" = X;
}
