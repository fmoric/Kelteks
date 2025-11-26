/// <summary>
/// Configuration table for API endpoints and authentication settings
/// Stores connection details for both BC17 and BC27 environments
/// </summary>
table 50100 "KLT API Configuration"
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
            Caption = 'BC17 Client ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "BC17 Client Secret"; Text[250])
        {
            Caption = 'BC17 Client Secret';
            DataClassification = EndUserPseudonymousIdentifiers;
            ExtendedDatatype = Masked;
        }
        field(14; "BC17 Tenant ID"; Text[250])
        {
            Caption = 'BC17 Tenant ID';
            DataClassification = CustomerContent;
        }
        field(20; "BC27 Base URL"; Text[250])
        {
            Caption = 'BC27 Base URL';
            DataClassification = CustomerContent;
            ExtendedDatatype = URL;
        }
        field(21; "BC27 Company ID"; Guid)
        {
            Caption = 'BC27 Company ID';
            DataClassification = CustomerContent;
        }
        field(22; "BC27 Client ID"; Text[250])
        {
            Caption = 'BC27 Client ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "BC27 Client Secret"; Text[250])
        {
            Caption = 'BC27 Client Secret';
            DataClassification = EndUserPseudonymousIdentifiers;
            ExtendedDatatype = Masked;
        }
        field(24; "BC27 Tenant ID"; Text[250])
        {
            Caption = 'BC27 Tenant ID';
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
        field(50; "Purchase No. Series BC17"; Code[20])
        {
            Caption = 'Purchase No. Series (BC17)';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Get or create the singleton configuration record
    /// </summary>
    procedure GetInstance(): Record "KLT API Configuration"
    begin
        if not Get('') then begin
            Init();
            "Primary Key" := '';
            Insert(true);
        end;
        exit(Rec);
    end;

    /// <summary>
    /// Validate that all required configuration is set
    /// </summary>
    procedure ValidateConfiguration(): Boolean
    var
        IsValid: Boolean;
    begin
        IsValid := true;

        if "BC17 Base URL" = '' then
            IsValid := false;
        if "BC27 Base URL" = '' then
            IsValid := false;
        if IsNullGuid("BC17 Company ID") then
            IsValid := false;
        if IsNullGuid("BC27 Company ID") then
            IsValid := false;

        exit(IsValid);
    end;
}
