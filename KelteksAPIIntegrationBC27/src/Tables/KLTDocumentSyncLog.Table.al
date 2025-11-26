/// <summary>
/// Log table for document synchronization history
/// Tracks all document transfers between BC17 and BC27
/// </summary>
table 50151 "KLT Document Sync Log"
{
    Caption = 'Document Sync Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(10; "Sync Direction"; Enum "KLT Sync Direction")
        {
            Caption = 'Sync Direction';
            DataClassification = CustomerContent;
        }
        field(11; "Document Type"; Enum "KLT Document Type")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }
        field(12; "Source Document No."; Code[20])
        {
            Caption = 'Source Document No.';
            DataClassification = CustomerContent;
        }
        field(13; "Source System ID"; Guid)
        {
            Caption = 'Source System ID';
            DataClassification = CustomerContent;
        }
        field(14; "Target Document No."; Code[20])
        {
            Caption = 'Target Document No.';
            DataClassification = CustomerContent;
        }
        field(15; "Target System ID"; Guid)
        {
            Caption = 'Target System ID';
            DataClassification = CustomerContent;
        }
        field(16; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
        }
        field(20; Status; Enum "KLT Sync Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(21; "Started DateTime"; DateTime)
        {
            Caption = 'Started DateTime';
            DataClassification = CustomerContent;
        }
        field(22; "Completed DateTime"; DateTime)
        {
            Caption = 'Completed DateTime';
            DataClassification = CustomerContent;
        }
        field(23; "Duration (ms)"; Integer)
        {
            Caption = 'Duration (ms)';
            DataClassification = CustomerContent;
        }
        field(30; "Customer/Vendor No."; Code[20])
        {
            Caption = 'Customer/Vendor No.';
            DataClassification = CustomerContent;
        }
        field(31; "Customer/Vendor Name"; Text[100])
        {
            Caption = 'Customer/Vendor Name';
            DataClassification = CustomerContent;
        }
        field(32; "Amount Including VAT"; Decimal)
        {
            Caption = 'Amount Including VAT';
            DataClassification = CustomerContent;
        }
        field(33; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
        }
        field(40; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(41; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
            DataClassification = CustomerContent;
        }
        field(42; "Last Retry DateTime"; DateTime)
        {
            Caption = 'Last Retry DateTime';
            DataClassification = CustomerContent;
        }
        field(50; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(51; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(DocumentKey; "Document Type", "Source Document No.", "Sync Direction")
        {
        }
        key(StatusKey; Status, "Created DateTime")
        {
        }
        key(ExternalDocKey; "External Document No.")
        {
        }
    }

    trigger OnInsert()
    begin
        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        "Created DateTime" := CurrentDateTime();
        if "Started DateTime" = 0DT then
            "Started DateTime" := CurrentDateTime();
    end;

    /// <summary>
    /// Update the log entry status to completed
    /// </summary>
    procedure MarkAsCompleted(TargetDocNo: Code[20]; TargetSysId: Guid)
    var
        DurationMilliseconds: BigInteger;
    begin
        Status := Status::Completed;
        "Completed DateTime" := CurrentDateTime();
        "Target Document No." := TargetDocNo;
        "Target System ID" := TargetSysId;
        if "Started DateTime" <> 0DT then begin
            DurationMilliseconds := CurrentDateTime() - "Started DateTime";
            // Cap duration at max integer value for safety
            if DurationMilliseconds > 2147483647 then
                "Duration (ms)" := 2147483647
            else
                "Duration (ms)" := DurationMilliseconds;
        end;
        Modify(true);
    end;

    /// <summary>
    /// Update the log entry status to failed
    /// </summary>
    procedure MarkAsFailed(ErrorMsg: Text)
    var
        DurationMilliseconds: BigInteger;
    begin
        Status := Status::Failed;
        "Completed DateTime" := CurrentDateTime();
        "Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen("Error Message"));
        if "Started DateTime" <> 0DT then begin
            DurationMilliseconds := CurrentDateTime() - "Started DateTime";
            // Cap duration at max integer value for safety
            if DurationMilliseconds > 2147483647 then
                "Duration (ms)" := 2147483647
            else
                "Duration (ms)" := DurationMilliseconds;
        end;
        Modify(true);
    end;

    /// <summary>
    /// Increment retry count
    /// </summary>
    procedure IncrementRetryCount()
    begin
        "Retry Count" += 1;
        "Last Retry DateTime" := CurrentDateTime();
        Status := Status::Retrying;
        Modify(true);
    end;
}
