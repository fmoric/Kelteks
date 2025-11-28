/// <summary>
/// Custom API Page for Unposted Sales Invoices - BC27
/// Exposes only the fields needed for sync to BC17
/// </summary>
page 80120 "KLT Sales Invoice API"
{
    PageType = API;
    APIPublisher = 'kelteks';
    APIGroup = 'api';
    APIVersion = 'v2.0';
    EntityName = 'salesInvoice';
    EntitySetName = 'salesInvoices';
    SourceTable = "Sales Header";
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
                field(customerNumber; Rec."Sell-to Customer No.")
                {
                    Caption = 'Customer Number';
                }
                field(externalDocumentNumber; Rec."External Document No.")
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
                part(salesInvoiceLines; "KLT Sales Invoice Line API")
                {
                    Caption = 'Sales Invoice Lines';
                    EntityName = 'salesInvoiceLine';
                    EntitySetName = 'salesInvoiceLines';
                    SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                }
            }
        }
    }
}
