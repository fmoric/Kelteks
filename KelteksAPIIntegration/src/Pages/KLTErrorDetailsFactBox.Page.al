/// <summary>
/// FactBox page for displaying error details
/// </summary>
page 50103 "KLT Error Details FactBox"
{
    PageType = CardPart;
    SourceTable = "KLT Document Sync Error";
    Caption = 'Error Details';

    layout
    {
        area(Content)
        {
            group(Details)
            {
                Caption = 'Error Details';
                
                field("Error Category"; Rec."Error Category")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error category';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message';
                    MultiLine = true;
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the retry count';
                }
                field("Can Retry"; Rec."Can Retry")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if retry is possible';
                }
                field("Next Retry DateTime"; Rec."Next Retry DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies next retry time';
                    Visible = Rec."Can Retry";
                }
            }
        }
    }
}
