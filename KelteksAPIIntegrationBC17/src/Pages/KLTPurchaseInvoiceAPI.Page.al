/// <summary>
/// Custom API Page for Unposted Purchase Invoices - BC17
/// Exposes only the fields needed for sync from BC27
/// </summary>
page 80124 "KLT Purchase Invoice API"
{
    PageType = API;
    APIPublisher = 'kelteks';
    APIGroup = 'api';
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
