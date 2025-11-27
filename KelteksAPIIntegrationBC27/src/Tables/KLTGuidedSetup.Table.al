/// <summary>
/// Table KLT Guided Setup (ID 50103).
/// Stores wizard state and configuration during guided setup process.
/// </summary>
table 50103 "KLT Guided Setup"
{
    Caption = 'Guided Setup';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Current Step"; Integer)
        {
            Caption = 'Current Step';
            DataClassification = SystemMetadata;
            InitValue = 1;
        }
        field(3; "Setup Complete"; Boolean)
        {
            Caption = 'Setup Complete';
            DataClassification = SystemMetadata;
        }
        field(10; "Deployment Type"; Enum "KLT Deployment Type")
        {
            Caption = 'Deployment Type';
            DataClassification = CustomerContent;
            InitValue = OnPremise;
        }
        field(11; "Authentication Method"; Enum "KLT Auth Method")
        {
            Caption = 'Authentication Method';
            DataClassification = CustomerContent;
            InitValue = Basic;
        }
        field(20; "Auto-Detected Server Name"; Text[250])
        {
            Caption = 'Auto-Detected Server Name';
            DataClassification = SystemMetadata;
        }
        field(21; "Auto-Detected Company ID"; Guid)
        {
            Caption = 'Auto-Detected Company ID';
            DataClassification = SystemMetadata;
        }
        field(22; "Auto-Detected Base URL"; Text[250])
        {
            Caption = 'Auto-Detected Base URL';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetOrCreate()
    begin
        Reset();
        if not Get('') then begin
            Init();
            "Primary Key" := '';
            Insert();
        end;
    end;

    procedure ResetWizard()
    begin
        GetOrCreate();
        "Current Step" := 1;
        "Setup Complete" := false;
        Modify();
    end;

    procedure CompleteSetup()
    begin
        GetOrCreate();
        "Setup Complete" := true;
        "Current Step" := 0;
        Modify();
    end;
}
