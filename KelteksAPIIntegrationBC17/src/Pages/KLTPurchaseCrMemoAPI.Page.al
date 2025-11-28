/// <summary>
/// Custom API Page for Unposted Purchase Credit Memos - BC17
/// Exposes only the fields needed for sync from BC27
/// </summary>
page 80126 "KLT Purchase Cr. Memo API"
{
    PageType = API;
    APIPublisher = 'kelteks';
    APIGroup = 'api';
    APIVersion = 'v2.0';
    EntityName = 'purchaseCreditMemo';
    EntitySetName = 'purchaseCreditMemos';
    SourceTable = "Purchase Header";
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
                field(vendorNumber; Rec."Buy-from Vendor No.")
                {
                    Caption = 'Vendor Number';
                }
                field(externalDocumentNumber; Rec."Vendor Cr. Memo No.")
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
                field(vendorName; Rec."Buy-from Vendor Name")
                {
                    Caption = 'Vendor Name';
                }
                field(payToName; Rec."Pay-to Name")
                {
                    Caption = 'Pay-to Name';
                }
                field(payToVendorNumber; Rec."Pay-to Vendor No.")
                {
                    Caption = 'Pay-to Vendor Number';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(paymentTermsCode; Rec."Payment Terms Code")
                {
                    Caption = 'Payment Terms Code';
                }
                part(purchaseCreditMemoLines; "KLT Purchase Cr. Memo Line API")
                {
                    Caption = 'Purchase Credit Memo Lines';
                    EntityName = 'purchaseCreditMemoLine';
                    EntitySetName = 'purchaseCreditMemoLines';
                    SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                }
            }
        }
    }
}
