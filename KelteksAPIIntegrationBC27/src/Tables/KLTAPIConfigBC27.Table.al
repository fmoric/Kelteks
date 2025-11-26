/// <summary>
/// Configuration table for BC27 - API connection to BC17
/// Stores connection details for BC17 target environment
/// </summary>
table 50150 "KLT API Config BC27"
{
    Caption = 'API Configuration BC27';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(5; "Authentication Method"; Enum "KLT Auth Method BC27")
        {
            Caption = 'Authentication Method';
            DataClassification = CustomerContent;
            InitValue = Basic;
        }
        field(6; "Deployment Type"; Enum "KLT Deployment Type BC27")
        {
            Caption = 'Deployment Type';
            DataClassification = CustomerContent;
            InitValue = OnPremise;
        }
        field(10; "BC17 Base URL"; Text[250])
        {
            Caption = 'BC17 Base URL';
            DataClassification = CustomerContent;
            ExtendedDatatype = URL;
        }
        field(11; "BC17 Company ID"; Guid)
        {
            Caption = 'BC17 Company ID';
            DataClassification = CustomerContent;
        }
        field(12; "BC17 Client ID"; Text[250])
        {
            Caption = 'BC17 Client ID (OAuth)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "BC17 Client Secret"; Text[250])
        {
            Caption = 'BC17 Client Secret (OAuth)';
            DataClassification = EndUserPseudonymousIdentifiers;
            ExtendedDatatype = Masked;
        }
        field(14; "BC17 Tenant ID"; Text[250])
        {
            Caption = 'BC17 Tenant ID (OAuth)';
            DataClassification = CustomerContent;
        }
        field(15; "BC17 Username"; Text[250])
        {
            Caption = 'BC17 Username (Basic/Windows)';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "BC17 Password"; Text[250])
        {
            Caption = 'BC17 Password (Basic)';
            DataClassification = EndUserPseudonymousIdentifiers;
            ExtendedDatatype = Masked;
        }
        field(17; "BC17 Domain"; Text[100])
        {
            Caption = 'BC17 Domain (Windows)';
            DataClassification = CustomerContent;
        }
        field(18; "BC17 Certificate Name"; Text[250])
        {
            Caption = 'BC17 Certificate Name';
            DataClassification = CustomerContent;
        }
        field(19; "BC17 Certificate Thumbprint"; Text[100])
        {
            Caption = 'BC17 Certificate Thumbprint';
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
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetInstance(): Record "KLT API Config BC27"
    begin
        if not Get('') then begin
            Init();
            "Primary Key" := '';
            Insert(true);
        end;
        exit(Rec);
    end;

    procedure ValidateConfiguration(): Boolean
    var
        IsValid: Boolean;
    begin
        IsValid := true;

        if "BC17 Base URL" = '' then
            IsValid := false;
        if IsNullGuid("BC17 Company ID") then
            IsValid := false;

        exit(IsValid);
    end;
}
