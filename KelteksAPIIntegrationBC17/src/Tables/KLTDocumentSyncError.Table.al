/// <summary>
/// Error tracking table for failed document synchronizations
/// Supports automatic retry and error categorization
/// </summary>
table 50102 "KLT Document Sync Error"
{
    Caption = 'Document Sync Error';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(10; "Sync Log Entry No."; Integer)
        {
            Caption = 'Sync Log Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "KLT Document Sync Log";
        }
        field(11; "Error Category"; Enum "KLT Error Category")
        {
            Caption = 'Error Category';
            DataClassification = CustomerContent;
        }
        field(12; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(13; "Error Details"; Blob)
        {
            Caption = 'Error Details';
            DataClassification = CustomerContent;
        }
        field(14; "Stack Trace"; Text[2048])
        {
            Caption = 'Stack Trace';
            DataClassification = CustomerContent;
        }
        field(20; "Document Type"; Enum "KLT Document Type")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }
        field(21; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(22; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
        }
        field(30; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
            DataClassification = CustomerContent;
        }
        field(31; "Max Retry Attempts"; Integer)
        {
            Caption = 'Max Retry Attempts';
            DataClassification = CustomerContent;
        }
        field(32; "Last Retry DateTime"; DateTime)
        {
            Caption = 'Last Retry DateTime';
            DataClassification = CustomerContent;
        }
        field(33; "Next Retry DateTime"; DateTime)
        {
            Caption = 'Next Retry DateTime';
            DataClassification = CustomerContent;
        }
        field(34; "Can Retry"; Boolean)
        {
            Caption = 'Can Retry';
            DataClassification = CustomerContent;
        }
        field(40; Resolved; Boolean)
        {
            Caption = 'Resolved';
            DataClassification = CustomerContent;
        }
        field(41; "Resolved DateTime"; DateTime)
        {
            Caption = 'Resolved DateTime';
            DataClassification = CustomerContent;
        }
        field(42; "Resolved By"; Code[50])
        {
            Caption = 'Resolved By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(43; "Resolution Notes"; Text[250])
        {
            Caption = 'Resolution Notes';
            DataClassification = CustomerContent;
        }
        field(50; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(DocumentKey; "Document Type", "Document No.")
        {
        }
        key(RetryKey; "Can Retry", "Next Retry DateTime")
        {
        }
        key(CategoryKey; "Error Category", Resolved)
        {
        }
    }

    trigger OnInsert()
    begin
        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        "Created DateTime" := CurrentDateTime();
        CalculateCanRetry();
    end;

    /// <summary>
    /// Calculate if error can be retried based on category and retry count
    /// </summary>
    local procedure CalculateCanRetry()
    begin
        // API Communication and Authentication errors can be retried
        if "Error Category" in ["Error Category"::"API Communication", "Error Category"::Authentication] then begin
            "Can Retry" := "Retry Count" < "Max Retry Attempts";
            if "Can Retry" then
                CalculateNextRetryTime();
        end else
            "Can Retry" := false;
    end;

    /// <summary>
    /// Calculate next retry time using exponential backoff
    /// </summary>
    local procedure CalculateNextRetryTime()
    var
        BackoffMinutes: Integer;
        MaxBackoffMinutes: Integer;
        MillisecondsPerMinute: Integer;
    begin
        MaxBackoffMinutes := 60; // Cap at 1 hour
        MillisecondsPerMinute := 60000; // 60 seconds * 1000 milliseconds
        
        // Exponential backoff: 1, 2, 4, 8, 16... minutes
        // Use Min to prevent overflow from Power function
        if "Retry Count" >= 10 then
            BackoffMinutes := MaxBackoffMinutes
        else begin
            BackoffMinutes := Power(2, "Retry Count");
            if BackoffMinutes > MaxBackoffMinutes then
                BackoffMinutes := MaxBackoffMinutes;
        end;
        
        "Next Retry DateTime" := CurrentDateTime() + (BackoffMinutes * MillisecondsPerMinute);
    end;

    /// <summary>
    /// Mark error as resolved
    /// </summary>
    procedure MarkAsResolved(ResolutionNote: Text[250])
    begin
        Resolved := true;
        "Resolved DateTime" := CurrentDateTime();
        "Resolved By" := CopyStr(UserId(), 1, MaxStrLen("Resolved By"));
        "Resolution Notes" := ResolutionNote;
        Modify(true);
    end;

    /// <summary>
    /// Increment retry count and update timestamps
    /// </summary>
    procedure IncrementRetryCount()
    begin
        "Retry Count" += 1;
        "Last Retry DateTime" := CurrentDateTime();
        CalculateCanRetry();
        Modify(true);
    end;

    /// <summary>
    /// Set error details from JSON
    /// </summary>
    procedure SetErrorDetails(JsonText: Text)
    var
        OutStr: OutStream;
    begin
        "Error Details".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(JsonText);
    end;

    /// <summary>
    /// Get error details as text
    /// </summary>
    procedure GetErrorDetails(): Text
    var
        InStr: InStream;
        ErrorText: Text;
    begin
        CalcFields("Error Details");
        if not "Error Details".HasValue() then
            exit('');
        
        "Error Details".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(ErrorText);
        exit(ErrorText);
    end;
}
