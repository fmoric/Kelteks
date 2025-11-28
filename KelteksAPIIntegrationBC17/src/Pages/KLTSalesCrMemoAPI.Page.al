/// <summary>
/// Custom API Page for Sales Credit Memos - BC17
/// Exposes only the fields needed for sync to BC27
/// </summary>
page 80122 "KLT Sales Cr. Memo API"
{
    PageType = API;
    APIPublisher = 'kelteks';
    APIGroup = 'fiskalizacija';
    APIVersion = 'v2.0';
    EntityName = 'salesCreditMemo';
    EntitySetName = 'salesCreditMemos';
    SourceTable = "Sales Cr.Memo Header";
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
                field(customerNumber; Rec."Sell-to Customer No.")
                {
                    Caption = 'Customer Number';
                }
                field(externalDocumentNumber; Rec."External Document No.")
                {
                    Caption = 'External Document Number';
                }
                field(creditMemoDate; Rec."Document Date")
                {
                    Caption = 'Credit Memo Date';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(dueDate; Rec."Due Date")
                {
                    Caption = 'Due Date';
                }
                field(customerName; Rec."Sell-to Customer Name")
                {
                    Caption = 'Customer Name';
                }
                field(billToName; Rec."Bill-to Name")
                {
                    Caption = 'Bill-to Name';
                }
                field(billToCustomerNumber; Rec."Bill-to Customer No.")
                {
                    Caption = 'Bill-to Customer Number';
                }
                field(sellingAddress; Rec."Sell-to Address")
                {
                    Caption = 'Selling Address';
                }
                field(sellingAddress2; Rec."Sell-to Address 2")
                {
                    Caption = 'Selling Address 2';
                }
                field(sellingCity; Rec."Sell-to City")
                {
                    Caption = 'Selling City';
                }
                field(sellingPostCode; Rec."Sell-to Post Code")
                {
                    Caption = 'Selling Post Code';
                }
                field(sellingState; Rec."Sell-to County")
                {
                    Caption = 'Selling State';
                }
                field(sellingCountryCode; Rec."Sell-to Country/Region Code")
                {
                    Caption = 'Selling Country Code';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(paymentTermsCode; Rec."Payment Terms Code")
                {
                    Caption = 'Payment Terms Code';
                }
                field(totalAmountExcludingTax; Rec.Amount)
                {
                    Caption = 'Total Amount Excluding Tax';
                }
                field(totalTaxAmount; TotalTaxAmount)
                {
                    Caption = 'Total Tax Amount';
                    Editable = false;
                }
                field(totalAmountIncludingTax; Rec."Amount Including VAT")
                {
                    Caption = 'Total Amount Including Tax';
                }
                part(salesCreditMemoLines; "KLT Sales Cr. Memo Line API")
                {
                    Caption = 'Sales Credit Memo Lines';
                    EntityName = 'salesCreditMemoLine';
                    EntitySetName = 'salesCreditMemoLines';
                    SubPageLink = "Document No." = field("No.");
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TotalTaxAmount := Rec."Amount Including VAT" - Rec.Amount;
    end;

    var
        TotalTaxAmount: Decimal;
}
