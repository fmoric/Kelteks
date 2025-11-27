/// <summary>
/// Configuration table - API connection to target environment
/// Stores connection details for target environment
/// </summary>
table 80100 "KLT API Config"
{
    Caption = 'API Configuration';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(5; "Authentication Method"; Enum "KLT Auth Method")
        {
            Caption = 'Authentication Method';
            DataClassification = CustomerContent;
            InitValue = Basic;
        }
        field(6; "Deployment Type"; Enum "KLT Deployment Type")
        {
            Caption = 'Deployment Type';
            DataClassification = CustomerContent;
            InitValue = OnPremise;
        }
        field(10; "Target Base URL"; Text[250])
        {
            Caption = 'Base URL';
            DataClassification = CustomerContent;
            ExtendedDatatype = URL;
        }
        field(11; "Target Company ID"; Guid)
        {
            Caption = 'Company ID';
            DataClassification = CustomerContent;
        }
        field(12; "Target Client ID"; Text[250])
        {
            Caption = 'Client ID (OAuth)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Target Client Secret"; Text[250])
        {
            Caption = 'Client Secret (OAuth)';
            DataClassification = EndUserPseudonymousIdentifiers;
            ExtendedDatatype = Masked;
        }
        field(14; "Target Tenant ID"; Text[250])
        {
            Caption = 'Tenant ID (OAuth)';
            DataClassification = CustomerContent;
        }
        field(15; "Target Username"; Text[250])
        {
            Caption = 'Username (Basic/Windows)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "Target Password"; Text[250])
        {
            Caption = 'Password (Basic)';
            DataClassification = EndUserPseudonymousIdentifiers;
            ExtendedDatatype = Masked;
        }
        field(17; "Target Domain"; Text[100])
        {
            Caption = 'Domain (Windows)';
            DataClassification = CustomerContent;
        }
        field(18; "Target Certificate Name"; Text[250])
        {
            Caption = 'Certificate Name';
            DataClassification = CustomerContent;
        }
        field(19; "Target Certificate Thumbprint"; Text[100])
        {
            Caption = 'Certificate Thumbprint';
            DataClassification = CustomerContent;
        }
        field(30; "Sync Interval (Minutes)"; Integer)
        {
            Caption = 'Sync Interval (Minutes)';
            DataClassification = CustomerContent;
            InitValue = 15;
            MinValue = 1;
            MaxValue = 1440;
        }
        field(31; "Batch Size"; Integer)
        {
            Caption = 'Batch Size';
            DataClassification = CustomerContent;
            InitValue = 100;
            MinValue = 1;
            MaxValue = 1000;
        }
        field(32; "API Timeout (Seconds)"; Integer)
        {
            Caption = 'API Timeout (Seconds)';
            DataClassification = CustomerContent;
            InitValue = 5;
            MinValue = 1;
            MaxValue = 300;
        }
        field(33; "Max Retry Attempts"; Integer)
        {
            Caption = 'Max Retry Attempts';
            DataClassification = CustomerContent;
            InitValue = 3;
            MinValue = 0;
            MaxValue = 10;
        }
        field(34; "Enable Sync"; Boolean)
        {
            Caption = 'Enable Sync';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(35; "Log Retention Days"; Integer)
        {
            Caption = 'Log Retention Days';
            DataClassification = CustomerContent;
            InitValue = 365;
            MinValue = 1;
        }
        field(40; "Alert Email Address"; Text[250])
        {
            Caption = 'Alert Email Address';
            DataClassification = EndUserIdentifiableInformation;
            ExtendedDatatype = EMail;
        }
        field(41; "Critical Error Threshold %"; Decimal)
        {
            Caption = 'Critical Error Threshold %';
            DataClassification = CustomerContent;
            InitValue = 25;
            MinValue = 0;
            MaxValue = 100;
        }
        field(50; "Purchase No. Series"; Code[20])
        {
            Caption = 'Purchase No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
            ObsoleteState = Pending;
            ObsoleteReason = 'Not used in BC27 - kept for upgrade compatibility from BC17';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetInstance()
    begin
        if not Get() then begin
            Init();
            "Primary Key" := '';
            Insert(true);
        end;
    end;

    procedure ValidateConfiguration(): Boolean
    var
        IsValid: Boolean;
    begin
        IsValid := true;

        if "Target Base URL" = '' then
            IsValid := false;
        if IsNullGuid("Target Company ID") then
            IsValid := false;

        exit(IsValid);
    end;
}
