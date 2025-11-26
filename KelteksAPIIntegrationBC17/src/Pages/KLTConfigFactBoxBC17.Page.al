/// <summary>
/// Page KLT Config FactBox BC17 (ID 50103).
/// FactBox showing configuration status for BC17.
/// </summary>
page 50103 "KLT Config FactBox"
{
    PageType = CardPart;
    SourceTable = "KLT API Config BC17";
    Caption = 'Configuration Status';

    layout
    {
        area(Content)
        {
            field(Enabled; Rec.Enabled)
            {
                ApplicationArea = All;
                Caption = 'Sync Enabled';
                ToolTip = 'Indicates whether synchronization is enabled';
                Style = Favorable;
                StyleExpr = Rec.Enabled;
            }
            field("Sync Interval (Minutes)"; Rec."Sync Interval (Minutes)")
            {
                ApplicationArea = All;
                Caption = 'Sync Interval';
                ToolTip = 'Shows the synchronization interval in minutes';
            }
            field("Batch Size"; Rec."Batch Size")
            {
                ApplicationArea = All;
                Caption = 'Batch Size';
                ToolTip = 'Shows the batch size for processing';
            }
            field(ConnectionStatus; ConnectionStatusText)
            {
                ApplicationArea = All;
                Caption = 'Connection Status';
                ToolTip = 'Shows the current connection status';
                StyleExpr = ConnectionStatusStyle;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateConnectionStatus();
    end;

    local procedure UpdateConnectionStatus()
    var
        APIHelper: Codeunit "KLT API Helper";
    begin
        if Rec."Base URL" = '' then begin
            ConnectionStatusText := 'Not Configured';
            ConnectionStatusStyle := 'Unfavorable';
        end else if APIHelper.TestConnection() then begin
            ConnectionStatusText := 'Connected';
            ConnectionStatusStyle := 'Favorable';
        end else begin
            ConnectionStatusText := 'Connection Failed';
            ConnectionStatusStyle := 'Unfavorable';
        end;
    end;

    var
        ConnectionStatusText: Text;
        ConnectionStatusStyle: Text;
}
