/// <summary>
/// Queue table for managing batch document synchronization
/// Implements FIFO processing with priority support
/// </summary>
table 80101 "KLT API Sync Queue"
{
    Caption = 'API Sync Queue';
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
        field(12; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(13; "Document System ID"; Guid)
        {
            Caption = 'Document System ID';
            DataClassification = CustomerContent;
        }
        field(14; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
        }
        field(20; Status; Enum "KLT Sync Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            InitValue = Pending;
        }
        field(21; Priority; Integer)
        {
            Caption = 'Priority';
            DataClassification = CustomerContent;
            InitValue = 5;
            MinValue = 1;
            MaxValue = 10;
        }
        field(22; "Processing Started"; DateTime)
        {
            Caption = 'Processing Started';
            DataClassification = CustomerContent;
        }
        field(23; "Processing Ended"; DateTime)
        {
            Caption = 'Processing Ended';
            DataClassification = CustomerContent;
        }
        field(30; "Sync Log Entry No."; Integer)
        {
            Caption = 'Sync Log Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "KLT Document Sync Log";
        }
        field(31; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
            DataClassification = CustomerContent;
        }
        field(40; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(41; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(50; "Last Error Message"; Text[50])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Last Error Message';
        }
        field(60; "Next Retry Time"; DateTime)
        {
            Caption = 'Next Retry Time';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ProcessingKey; Status, Priority, "Created DateTime")
        {
        }
        key(DocumentKey; "Document Type", "Document No.")
        {
        }
    }

    trigger OnInsert()
    begin
        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        "Created DateTime" := CurrentDateTime();
    end;

    /// <summary>
    /// Add document to sync queue
    /// </summary>
    procedure EnqueueDocument(DocType: Enum "KLT Document Type"; DocNo: Code[20]; SysId: Guid; Direction: Enum "KLT Sync Direction"; ExternalDocNo: Code[35])
    begin
        Init();
        "Document Type" := DocType;
        "Document No." := DocNo;
        "Document System ID" := SysId;
        "Sync Direction" := Direction;
        "External Document No." := ExternalDocNo;
        Status := Status::Pending;
        Insert(true);
    end;

    /// <summary>
    /// Mark queue entry as in progress
    /// </summary>
    procedure MarkAsInProgress()
    begin
        Status := Status::"In Progress";
        "Processing Started" := CurrentDateTime();
        Modify(true);
    end;

    /// <summary>
    /// Mark queue entry as completed and remove from queue
    /// </summary>
    procedure MarkAsCompleted()
    begin
        Delete(true);
    end;

    /// <summary>
    /// Mark queue entry as failed for retry
    /// </summary>
    procedure MarkAsFailed()
    begin
        Status := Status::Failed;
        "Retry Count" += 1;
        Modify(true);
    end;
}
