/// <summary>
/// Custom API Page for Unposted Sales Invoice Lines - BC27
/// Exposes only the fields needed for sync to BC17
/// </summary>
page 80121 "KLT Sales Invoice Line API"
{
    PageType = API;
    APIPublisher = 'kelteks';
    APIGroup = 'api';
    APIVersion = 'v2.0';
    EntityName = 'salesInvoiceLine';
    EntitySetName = 'salesInvoiceLines';
    SourceTable = "Sales Line";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    SourceTableView = where("Document Type" = const(Invoice));

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
            }
        }
    }
}
