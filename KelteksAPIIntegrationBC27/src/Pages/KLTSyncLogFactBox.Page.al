/// <summary>
/// Page KLT Sync Log FactBox BC27 (ID 50154).
/// FactBox showing sync statistics for BC27.
/// </summary>
page 80103 "KLT Sync Log FactBox"
{
    PageType = CardPart;
    SourceTable = "KLT Document Sync Log";
    Caption = 'Sync Statistics (Last 24 Hours)';

    layout
    {
        area(Content)
        {
            field(TotalSynced; TotalSynced)
            {
                ApplicationArea = All;
                Caption = 'Total Synced';
                ToolTip = 'Shows the total number of documents synced in the last 24 hours';
                Style = Strong;
            }
            field(Successful; Successful)
            {
                ApplicationArea = All;
                Caption = 'Successful';
                ToolTip = 'Shows the number of successful synchronizations';
                Style = Favorable;
            }
            field(Failed; Failed)
            {
                ApplicationArea = All;
                Caption = 'Failed';
                ToolTip = 'Shows the number of failed synchronizations';
                Style = Unfavorable;
            }
            field(SuccessRate; SuccessRateText)
            {
                ApplicationArea = All;
                Caption = 'Success Rate';
                ToolTip = 'Shows the success rate percentage';
                StyleExpr = SuccessRateStyle;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CalculateStatistics();
    end;

    trigger OnAfterGetRecord()
    begin
        CalculateStatistics();
    end;

    local procedure CalculateStatistics()
    var
        SyncLog: Record "KLT Document Sync Log";
        Last24Hours: DateTime;
    begin
        Last24Hours := CreateDateTime(CalcDate('<-1D>', Today()), Time());

        SyncLog.SetFilter("Started DateTime", '>=%1', Last24Hours);
        TotalSynced := SyncLog.Count();

        SyncLog.SetRange(Status, SyncLog.Status::Completed);
        Successful := SyncLog.Count();

        SyncLog.SetRange(Status, SyncLog.Status::Failed);
        Failed := SyncLog.Count();

        if TotalSynced > 0 then begin
            SuccessRateText := Format(Round(Successful / TotalSynced * 100, 1)) + '%';
            if (Successful / TotalSynced) >= 0.95 then
                SuccessRateStyle := 'Favorable'
            else if (Successful / TotalSynced) >= 0.75 then
                SuccessRateStyle := 'Attention'
            else
                SuccessRateStyle := 'Unfavorable';
        end else begin
            SuccessRateText := 'N/A';
            SuccessRateStyle := '';
        end;
    end;

    var
        TotalSynced: Integer;
        Successful: Integer;
        Failed: Integer;
        SuccessRateText: Text;
        SuccessRateStyle: Text;
}
