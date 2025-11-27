/// <summary>
/// Document Validator for BC17
/// Validates sales and purchase documents before sync
/// </summary>
codeunit 80102 "KLT Document Validator"
{
    var
        CustomerNotExistErr: Label 'Customer %1 does not exist';
        VendorNotExistErr: Label 'Vendor %1 does not exist in BC17';
        PostingDateRequiredErr: Label 'Posting Date is required';
        DocumentDateRequiredErr: Label 'Document Date is required';
        CurrencyNotExistErr: Label 'Currency %1 does not exist';
        VendorNumberRequiredErr: Label 'Vendor Number is required';
        PostingPeriodBeforeErr: Label 'Posting Date %1 is before allowed posting from date %2';
        PostingPeriodAfterErr: Label 'Posting Date %1 is after allowed posting to date %2';
        LineTypeRequiredErr: Label 'Line Type is required';
        NumberRequiredErr: Label 'Number is required for non-comment lines';
        QuantityMustBePositiveErr: Label 'Quantity must be greater than zero';
        UnitPriceNegativeErr: Label 'Unit Price cannot be negative';
        DuplicatePostedInvoiceErr: Label 'Duplicate: Posted invoice with External Document No. %1 already exists';
        DuplicateUnpostedInvoiceErr: Label 'Duplicate: Unposted invoice with External Document No. %1 already exists';
        DuplicatePostedCreditMemoErr: Label 'Duplicate: Posted credit memo with External Document No. %1 already exists';
        DuplicateUnpostedCreditMemoErr: Label 'Duplicate: Unposted credit memo with External Document No. %1 already exists';
        VendorNotFoundErr: Label 'Vendor %1 not found';
        VendorNoPostingGroupErr: Label 'Vendor %1 has no posting group assigned';
        VendorPostingGroupNotFoundErr: Label 'Vendor Posting Group %1 not found';
        ItemNotExistErr: Label 'Item %1 does not exist';
        ItemBlockedErr: Label 'Item %1 is blocked';
        GLAccountNotExistErr: Label 'G/L Account %1 does not exist';
        GLAccountBlockedErr: Label 'G/L Account %1 is blocked';
        GLAccountNotPostingErr: Label 'G/L Account %1 is not a posting account';

    /// <summary>
    /// Validates Posted Sales Invoice before sending to target
    /// </summary>
    procedure ValidatePostedSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"; var ErrorText: Text): Boolean
    var
        Customer: Record Customer;
    begin
        ErrorText := '';

        // Validate customer exists
        if not Customer.Get(SalesInvHeader."Sell-to Customer No.") then begin
            ErrorText := StrSubstNo(CustomerNotExistErr, SalesInvHeader."Sell-to Customer No.");
            exit(false);
        end;

        // Validate posting date
        if SalesInvHeader."Posting Date" = 0D then begin
            ErrorText := PostingDateRequiredErr;
            exit(false);
        end;

        // Validate document date
        if SalesInvHeader."Document Date" = 0D then begin
            ErrorText := DocumentDateRequiredErr;
            exit(false);
        end;

        // Validate currency if specified
        if SalesInvHeader."Currency Code" <> '' then begin
            if not ValidateCurrency(SalesInvHeader."Currency Code", ErrorText) then
                exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validates Posted Sales Credit Memo before sending to target
    /// </summary>
    procedure ValidatePostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ErrorText: Text): Boolean
    var
        Customer: Record Customer;
    begin
        ErrorText := '';

        // Validate customer exists
        if not Customer.Get(SalesCrMemoHeader."Sell-to Customer No.") then begin
            ErrorText := StrSubstNo(CustomerNotExistErr, SalesCrMemoHeader."Sell-to Customer No.");
            exit(false);
        end;

        // Validate posting date
        if SalesCrMemoHeader."Posting Date" = 0D then begin
            ErrorText := PostingDateRequiredErr;
            exit(false);
        end;

        // Validate document date
        if SalesCrMemoHeader."Document Date" = 0D then begin
            ErrorText := DocumentDateRequiredErr;
            exit(false);
        end;

        // Validate currency if specified
        if SalesCrMemoHeader."Currency Code" <> '' then begin
            if not ValidateCurrency(SalesCrMemoHeader."Currency Code", ErrorText) then
                exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validates Purchase Invoice data received from target
    /// </summary>
    procedure ValidatePurchaseInvoiceData(JsonData: JsonObject; var ErrorText: Text): Boolean
    var
        APIHelper: Codeunit "KLT API Helper";
        VendorNo: Code[20];
        Vendor: Record Vendor;
        PostingDate: Date;
        DocumentDate: Date;
    begin
        ErrorText := '';

        // Validate vendor
        VendorNo := CopyStr(APIHelper.GetJsonText(JsonData, 'vendorNumber'), 1, MaxStrLen(VendorNo));
        if VendorNo = '' then begin
            ErrorText := VendorNumberRequiredErr;
            exit(false);
        end;

        if not Vendor.Get(VendorNo) then begin
            ErrorText := StrSubstNo(VendorNotExistErr, VendorNo);
            exit(false);
        end;

        // Validate dates
        PostingDate := APIHelper.GetJsonDate(JsonData, 'postingDate');
        if PostingDate = 0D then begin
            ErrorText := PostingDateRequiredErr;
            exit(false);
        end;

        DocumentDate := APIHelper.GetJsonDate(JsonData, 'documentDate');
        if DocumentDate = 0D then begin
            ErrorText := DocumentDateRequiredErr;
            exit(false);
        end;

        // Validate posting period is open
        if not IsPostingPeriodOpen(PostingDate, ErrorText) then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Validates Purchase Credit Memo data received from target
    /// </summary>
    procedure ValidatePurchaseCreditMemoData(JsonData: JsonObject; var ErrorText: Text): Boolean
    var
        APIHelper: Codeunit "KLT API Helper";
        VendorNo: Code[20];
        Vendor: Record Vendor;
        PostingDate: Date;
        DocumentDate: Date;
    begin
        ErrorText := '';

        // Validate vendor
        VendorNo := CopyStr(APIHelper.GetJsonText(JsonData, 'vendorNumber'), 1, MaxStrLen(VendorNo));
        if VendorNo = '' then begin
            ErrorText := VendorNumberRequiredErr;
            exit(false);
        end;

        if not Vendor.Get(VendorNo) then begin
            ErrorText := StrSubstNo(VendorNotExistErr, VendorNo);
            exit(false);
        end;

        // Validate dates
        PostingDate := APIHelper.GetJsonDate(JsonData, 'postingDate');
        if PostingDate = 0D then begin
            ErrorText := PostingDateRequiredErr;
            exit(false);
        end;

        DocumentDate := APIHelper.GetJsonDate(JsonData, 'documentDate');
        if DocumentDate = 0D then begin
            ErrorText := DocumentDateRequiredErr;
            exit(false);
        end;

        // Validate posting period is open
        if not IsPostingPeriodOpen(PostingDate, ErrorText) then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Validates line data from JSON
    /// </summary>
    procedure ValidateLineData(LineJson: JsonObject; var ErrorText: Text): Boolean
    var
        APIHelper: Codeunit "KLT API Helper";
        LineType: Text;
        ItemNo: Code[20];
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        ErrorText := '';

        // Validate type
        LineType := APIHelper.GetJsonText(LineJson, 'lineType');
        if LineType = '' then begin
            ErrorText := LineTypeRequiredErr;
            exit(false);
        end;

        // Validate number based on type
        ItemNo := CopyStr(APIHelper.GetJsonText(LineJson, 'number'), 1, MaxStrLen(ItemNo));
        if (LineType <> 'Comment') and (ItemNo = '') then begin
            ErrorText := NumberRequiredErr;
            exit(false);
        end;

        // Validate quantity
        Quantity := APIHelper.GetJsonDecimal(LineJson, 'quantity');
        if Quantity <= 0 then begin
            ErrorText := QuantityMustBePositiveErr;
            exit(false);
        end;

        // Validate unit price
        UnitPrice := APIHelper.GetJsonDecimal(LineJson, 'unitPrice');
        if UnitPrice < 0 then begin
            ErrorText := UnitPriceNegativeErr;
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Checks for duplicate document using External Document No
    /// </summary>
    procedure CheckDuplicatePurchaseInvoice(ExternalDocNo: Code[35]; VendorNo: Code[20]; var ErrorText: Text): Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeader: Record "Purchase Header";
    begin
        ErrorText := '';

        // Check posted invoices
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.SetRange("Vendor Invoice No.", ExternalDocNo);
        if not PurchInvHeader.IsEmpty() then begin
            ErrorText := StrSubstNo(DuplicatePostedInvoiceErr, ExternalDocNo);
            exit(false);
        end;

        // Check unposted invoices
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
        PurchHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchHeader.SetRange("Vendor Invoice No.", ExternalDocNo);
        if not PurchHeader.IsEmpty() then begin
            ErrorText := StrSubstNo(DuplicateUnpostedInvoiceErr, ExternalDocNo);
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Checks for duplicate credit memo using External Document No
    /// </summary>
    procedure CheckDuplicatePurchaseCreditMemo(ExternalDocNo: Code[35]; VendorNo: Code[20]; var ErrorText: Text): Boolean
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchHeader: Record "Purchase Header";
    begin
        ErrorText := '';

        // Check posted credit memos
        PurchCrMemoHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchCrMemoHeader.SetRange("Vendor Cr. Memo No.", ExternalDocNo);
        if not PurchCrMemoHeader.IsEmpty() then begin
            ErrorText := StrSubstNo(DuplicatePostedCreditMemoErr, ExternalDocNo);
            exit(false);
        end;

        // Check unposted credit memos
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::"Credit Memo");
        PurchHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchHeader.SetRange("Vendor Cr. Memo No.", ExternalDocNo);
        if not PurchHeader.IsEmpty() then begin
            ErrorText := StrSubstNo(DuplicateUnpostedCreditMemoErr, ExternalDocNo);
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validates Sales Invoice data received from target
    /// </summary>
    procedure ValidateSalesInvoiceData(JsonData: JsonObject; var ErrorText: Text): Boolean
    var
        APIHelper: Codeunit "KLT API Helper";
        CustomerNo: Code[20];
        Customer: Record Customer;
        PostingDate: Date;
        DocumentDate: Date;
    begin
        ErrorText := '';

        // Validate customer
        CustomerNo := CopyStr(APIHelper.GetJsonText(JsonData, 'customerNumber'), 1, MaxStrLen(CustomerNo));
        if CustomerNo = '' then begin
            ErrorText := 'Customer Number is required';
            exit(false);
        end;

        if not Customer.Get(CustomerNo) then begin
            ErrorText := StrSubstNo(CustomerNotExistErr, CustomerNo);
            exit(false);
        end;

        // Validate dates
        PostingDate := APIHelper.GetJsonDate(JsonData, 'postingDate');
        if PostingDate = 0D then begin
            ErrorText := PostingDateRequiredErr;
            exit(false);
        end;

        DocumentDate := APIHelper.GetJsonDate(JsonData, 'invoiceDate');
        if DocumentDate = 0D then begin
            ErrorText := DocumentDateRequiredErr;
            exit(false);
        end;

        // Validate posting period is open
        if not IsPostingPeriodOpen(PostingDate, ErrorText) then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Validates Sales Credit Memo data received from target
    /// </summary>
    procedure ValidateSalesCreditMemoData(JsonData: JsonObject; var ErrorText: Text): Boolean
    var
        APIHelper: Codeunit "KLT API Helper";
        CustomerNo: Code[20];
        Customer: Record Customer;
        PostingDate: Date;
        DocumentDate: Date;
    begin
        ErrorText := '';

        // Validate customer
        CustomerNo := CopyStr(APIHelper.GetJsonText(JsonData, 'customerNumber'), 1, MaxStrLen(CustomerNo));
        if CustomerNo = '' then begin
            ErrorText := 'Customer Number is required';
            exit(false);
        end;

        if not Customer.Get(CustomerNo) then begin
            ErrorText := StrSubstNo(CustomerNotExistErr, CustomerNo);
            exit(false);
        end;

        // Validate dates
        PostingDate := APIHelper.GetJsonDate(JsonData, 'postingDate');
        if PostingDate = 0D then begin
            ErrorText := PostingDateRequiredErr;
            exit(false);
        end;

        DocumentDate := APIHelper.GetJsonDate(JsonData, 'creditMemoDate');
        if DocumentDate = 0D then begin
            ErrorText := DocumentDateRequiredErr;
            exit(false);
        end;

        // Validate posting period is open
        if not IsPostingPeriodOpen(PostingDate, ErrorText) then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Checks for duplicate sales invoice using External Document No
    /// </summary>
    procedure CheckDuplicateSalesInvoice(ExternalDocNo: Code[35]; CustomerNo: Code[20]; var ErrorText: Text): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
    begin
        ErrorText := '';

        // Check posted invoices
        SalesInvHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvHeader.SetRange("External Document No.", ExternalDocNo);
        if not SalesInvHeader.IsEmpty() then begin
            ErrorText := StrSubstNo(DuplicatePostedInvoiceErr, ExternalDocNo);
            exit(false);
        end;

        // Check unposted invoices
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange("External Document No.", ExternalDocNo);
        if not SalesHeader.IsEmpty() then begin
            ErrorText := StrSubstNo(DuplicateUnpostedInvoiceErr, ExternalDocNo);
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Checks for duplicate sales credit memo using External Document No
    /// </summary>
    procedure CheckDuplicateSalesCreditMemo(ExternalDocNo: Code[35]; CustomerNo: Code[20]; var ErrorText: Text): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
    begin
        ErrorText := '';

        // Check posted credit memos
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesCrMemoHeader.SetRange("External Document No.", ExternalDocNo);
        if not SalesCrMemoHeader.IsEmpty() then begin
            ErrorText := StrSubstNo(DuplicatePostedCreditMemoErr, ExternalDocNo);
            exit(false);
        end;

        // Check unposted credit memos
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange("External Document No.", ExternalDocNo);
        if not SalesHeader.IsEmpty() then begin
            ErrorText := StrSubstNo(DuplicateUnpostedCreditMemoErr, ExternalDocNo);
            exit(false);
        end;

        exit(true);
    end;

    local procedure ValidateCurrency(CurrencyCode: Code[10]; var ErrorText: Text): Boolean
    var
        Currency: Record Currency;
    begin
        if not Currency.Get(CurrencyCode) then begin
            ErrorText := StrSubstNo(CurrencyNotExistErr, CurrencyCode);
            exit(false);
        end;
        exit(true);
    end;

    local procedure IsPostingPeriodOpen(PostingDate: Date; var ErrorText: Text): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();

        // Check if posting is allowed
        if PostingDate < GLSetup."Allow Posting From" then begin
            ErrorText := StrSubstNo(PostingPeriodBeforeErr, PostingDate, GLSetup."Allow Posting From");
            exit(false);
        end;

        if (GLSetup."Allow Posting To" <> 0D) and (PostingDate > GLSetup."Allow Posting To") then begin
            ErrorText := StrSubstNo(PostingPeriodAfterErr, PostingDate, GLSetup."Allow Posting To");
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validates vendor posting group configuration
    /// </summary>
    procedure ValidateVendorPostingSetup(VendorNo: Code[20]; var ErrorText: Text): Boolean
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not Vendor.Get(VendorNo) then begin
            ErrorText := StrSubstNo(VendorNotFoundErr, VendorNo);
            exit(false);
        end;

        if Vendor."Vendor Posting Group" = '' then begin
            ErrorText := StrSubstNo(VendorNoPostingGroupErr, VendorNo);
            exit(false);
        end;

        if not VendorPostingGroup.Get(Vendor."Vendor Posting Group") then begin
            ErrorText := StrSubstNo(VendorPostingGroupNotFoundErr, Vendor."Vendor Posting Group");
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validates item exists and has proper setup
    /// </summary>
    procedure ValidateItem(ItemNo: Code[20]; var ErrorText: Text): Boolean
    var
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then begin
            ErrorText := StrSubstNo(ItemNotExistErr, ItemNo);
            exit(false);
        end;

        if Item.Blocked then begin
            ErrorText := StrSubstNo(ItemBlockedErr, ItemNo);
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validates G/L Account exists and is not blocked
    /// </summary>
    procedure ValidateGLAccount(AccountNo: Code[20]; var ErrorText: Text): Boolean
    var
        GLAccount: Record "G/L Account";
    begin
        if not GLAccount.Get(AccountNo) then begin
            ErrorText := StrSubstNo(GLAccountNotExistErr, AccountNo);
            exit(false);
        end;

        if GLAccount.Blocked then begin
            ErrorText := StrSubstNo(GLAccountBlockedErr, AccountNo);
            exit(false);
        end;

        if GLAccount."Account Type" <> GLAccount."Account Type"::Posting then begin
            ErrorText := StrSubstNo(GLAccountNotPostingErr, AccountNo);
            exit(false);
        end;

        exit(true);
    end;
}
