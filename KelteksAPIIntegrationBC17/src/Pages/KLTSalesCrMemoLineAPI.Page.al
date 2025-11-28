/// <summary>
/// Custom API Page for Sales Credit Memo Lines - BC17
/// Exposes only the fields needed for sync to BC27
/// </summary>
page 80123 "KLT Sales Cr. Memo Line API"
{
    PageType = API;
    APIPublisher = 'kelteks';
    APIGroup = 'fiskalizacija';
    APIVersion = 'v2.0';
    EntityName = 'salesCreditMemoLine';
    EntitySetName = 'salesCreditMemoLines';
    SourceTable = "Sales Cr.Memo Line";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(lineType; Rec.Type)
                {
                    Caption = 'Line Type';
                }
                field(lineObjectNumber; Rec."No.")
                {
                    Caption = 'Line Object Number';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(description2; Rec."Description 2")
                {
                    Caption = 'Description 2';
                }
                field(quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    Caption = 'Unit Price';
                }
                field(lineDiscount; Rec."Line Discount %")
                {
                    Caption = 'Line Discount %';
                }
                field(lineDiscountAmount; Rec."Line Discount Amount")
                {
                    Caption = 'Line Discount Amount';
                }
                field(taxPercent; Rec."VAT %")
                {
                    Caption = 'Tax Percent';
                }
                field(amountExcludingTax; Rec.Amount)
                {
                    Caption = 'Amount Excluding Tax';
                }
                field(taxAmount; TaxAmount)
                {
                    Caption = 'Tax Amount';
                    Editable = false;
                }
                field(amountIncludingTax; Rec."Amount Including VAT")
                {
                    Caption = 'Amount Including Tax';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TaxAmount := Rec."Amount Including VAT" - Rec.Amount;
    end;

    var
        TaxAmount: Decimal;
}
