/// <summary>
/// Custom API Page for Purchase Credit Memo Lines - BC27
/// Exposes only the fields needed for sync to BC17
/// </summary>
page 80123 "KLT Purchase Cr. Memo Line API"
{
    PageType = API;
    APIPublisher = 'kelteks';
    APIGroup = 'api';
    APIVersion = 'v2.0';
    EntityName = 'purchaseCreditMemoLine';
    EntitySetName = 'purchaseCreditMemoLines';
    SourceTable = "Purchase Line";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    SourceTableView = where("Document Type" = const("Credit Memo"));

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
                field(number; Rec."No.")
                {
                    Caption = 'Number';
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
                field(unitCost; Rec."Direct Unit Cost")
                {
                    Caption = 'Unit Cost';
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
            }
        }
    }
}
