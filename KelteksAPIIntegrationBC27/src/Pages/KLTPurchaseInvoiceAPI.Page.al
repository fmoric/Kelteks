/// <summary>
/// Custom API Page for Purchase Invoices - BC27
/// Exposes only the fields needed for sync to BC17
/// </summary>
page 80120 "KLT Purchase Invoice API"
{
    PageType = API;
    APIPublisher = 'kelteks';
    APIGroup = 'fiskalizacija';
    APIVersion = 'v2.0';
    EntityName = 'purchaseInvoice';
    EntitySetName = 'purchaseInvoices';
    SourceTable = "Purchase Header";
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
                field(vendorNumber; Rec."Buy-from Vendor No.")
                {
                    Caption = 'Vendor Number';
                }
                field(externalDocumentNumber; Rec."Vendor Invoice No.")
                {
                    Caption = 'External Document Number';
                }
                field(invoiceDate; Rec."Document Date")
                {
                    Caption = 'Invoice Date';
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
                field(buyingAddress; Rec."Buy-from Address")
                {
                    Caption = 'Buying Address';
                }
                field(buyingAddress2; Rec."Buy-from Address 2")
                {
                    Caption = 'Buying Address 2';
                }
                field(buyingCity; Rec."Buy-from City")
                {
                    Caption = 'Buying City';
                }
                field(buyingPostCode; Rec."Buy-from Post Code")
                {
                    Caption = 'Buying Post Code';
                }
                field(buyingState; Rec."Buy-from County")
                {
                    Caption = 'Buying State';
                }
                field(buyingCountryCode; Rec."Buy-from Country/Region Code")
                {
                    Caption = 'Buying Country Code';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(paymentTermsCode; Rec."Payment Terms Code")
                {
                    Caption = 'Payment Terms Code';
                }
                part(purchaseInvoiceLines; "KLT Purchase Invoice Line API")
                {
                    Caption = 'Purchase Invoice Lines';
                    EntityName = 'purchaseInvoiceLine';
                    EntitySetName = 'purchaseInvoiceLines';
                    SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                }
            }
        }
    }
}
