/// <summary>
/// Document Validator for BC17
/// Validates sales and purchase documents before sync
/// </summary>
codeunit 50104 "KLT Document Validator BC17"
{
    /// <summary>
    /// Validates Posted Sales Invoice before sending to BC27
    /// </summary>
    procedure ValidatePostedSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"; var ErrorText: Text): Boolean
    var
        Customer: Record Customer;
    begin
        ErrorText := '';
        
        // Validate customer exists
        if not Customer.Get(SalesInvHeader."Sell-to Customer No.") then begin
            ErrorText := StrSubstNo('Customer %1 does not exist', SalesInvHeader."Sell-to Customer No.");
            exit(false);
        end;
        
        // Validate posting date
        if SalesInvHeader."Posting Date" = 0D then begin
            ErrorText := 'Posting Date is required';
            exit(false);
        end;
        
        // Validate document date
        if SalesInvHeader."Document Date" = 0D then begin
            ErrorText := 'Document Date is required';
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
    /// Validates Posted Sales Credit Memo before sending to BC27
    /// </summary>
    procedure ValidatePostedSalesCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ErrorText: Text): Boolean
    var
        Customer: Record Customer;
    begin
        ErrorText := '';
        
        // Validate customer exists
        if not Customer.Get(SalesCrMemoHeader."Sell-to Customer No.") then begin
            ErrorText := StrSubstNo('Customer %1 does not exist', SalesCrMemoHeader."Sell-to Customer No.");
            exit(false);
        end;
        
        // Validate posting date
        if SalesCrMemoHeader."Posting Date" = 0D then begin
            ErrorText := 'Posting Date is required';
            exit(false);
        end;
        
        // Validate document date
        if SalesCrMemoHeader."Document Date" = 0D then begin
            ErrorText := 'Document Date is required';
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
    /// Validates Purchase Invoice data received from BC27
    /// </summary>
    procedure ValidatePurchaseInvoiceData(JsonData: JsonObject; var ErrorText: Text): Boolean
    var
        APIHelper: Codeunit "KLT API Helper BC17";
        VendorNo: Code[20];
        Vendor: Record Vendor;
        PostingDate: Date;
        DocumentDate: Date;
    begin
        ErrorText := '';
        
        // Validate vendor
        VendorNo := CopyStr(APIHelper.GetJsonText(JsonData, 'vendorNumber'), 1, MaxStrLen(VendorNo));
        if VendorNo = '' then begin
            ErrorText := 'Vendor Number is required';
            exit(false);
        end;
        
        if not Vendor.Get(VendorNo) then begin
            ErrorText := StrSubstNo('Vendor %1 does not exist in BC17', VendorNo);
            exit(false);
        end;
        
        // Validate dates
        PostingDate := APIHelper.GetJsonDate(JsonData, 'postingDate');
        if PostingDate = 0D then begin
            ErrorText := 'Posting Date is required';
            exit(false);
        end;
        
        DocumentDate := APIHelper.GetJsonDate(JsonData, 'documentDate');
        if DocumentDate = 0D then begin
            ErrorText := 'Document Date is required';
            exit(false);
        end;
        
        // Validate posting period is open
        if not IsPostingPeriodOpen(PostingDate, ErrorText) then
            exit(false);
        
        exit(true);
    end;

    /// <summary>
    /// Validates Purchase Credit Memo data received from BC27
    /// </summary>
    procedure ValidatePurchaseCreditMemoData(JsonData: JsonObject; var ErrorText: Text): Boolean
    var
        APIHelper: Codeunit "KLT API Helper BC17";
        VendorNo: Code[20];
        Vendor: Record Vendor;
        PostingDate: Date;
        DocumentDate: Date;
    begin
        ErrorText := '';
        
        // Validate vendor
        VendorNo := CopyStr(APIHelper.GetJsonText(JsonData, 'vendorNumber'), 1, MaxStrLen(VendorNo));
        if VendorNo = '' then begin
            ErrorText := 'Vendor Number is required';
            exit(false);
        end;
        
        if not Vendor.Get(VendorNo) then begin
            ErrorText := StrSubstNo('Vendor %1 does not exist in BC17', VendorNo);
            exit(false);
        end;
        
        // Validate dates
        PostingDate := APIHelper.GetJsonDate(JsonData, 'postingDate');
        if PostingDate = 0D then begin
            ErrorText := 'Posting Date is required';
            exit(false);
        end;
        
        DocumentDate := APIHelper.GetJsonDate(JsonData, 'documentDate');
        if DocumentDate = 0D then begin
            ErrorText := 'Document Date is required';
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
        APIHelper: Codeunit "KLT API Helper BC17";
        LineType: Text;
        ItemNo: Code[20];
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        ErrorText := '';
        
        // Validate type
        LineType := APIHelper.GetJsonText(LineJson, 'lineType');
        if LineType = '' then begin
            ErrorText := 'Line Type is required';
            exit(false);
        end;
        
        // Validate number based on type
        ItemNo := CopyStr(APIHelper.GetJsonText(LineJson, 'number'), 1, MaxStrLen(ItemNo));
        if (LineType <> 'Comment') and (ItemNo = '') then begin
            ErrorText := 'Number is required for non-comment lines';
            exit(false);
        end;
        
        // Validate quantity
        Quantity := APIHelper.GetJsonDecimal(LineJson, 'quantity');
        if Quantity <= 0 then begin
            ErrorText := 'Quantity must be greater than zero';
            exit(false);
        end;
        
        // Validate unit price
        UnitPrice := APIHelper.GetJsonDecimal(LineJson, 'unitPrice');
        if UnitPrice < 0 then begin
            ErrorText := 'Unit Price cannot be negative';
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
            ErrorText := StrSubstNo('Duplicate: Posted invoice with External Document No. %1 already exists', ExternalDocNo);
            exit(false);
        end;
        
        // Check unposted invoices
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
        PurchHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchHeader.SetRange("Vendor Invoice No.", ExternalDocNo);
        if not PurchHeader.IsEmpty() then begin
            ErrorText := StrSubstNo('Duplicate: Unposted invoice with External Document No. %1 already exists', ExternalDocNo);
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
            ErrorText := StrSubstNo('Duplicate: Posted credit memo with External Document No. %1 already exists', ExternalDocNo);
            exit(false);
        end;
        
        // Check unposted credit memos
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::"Credit Memo");
        PurchHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchHeader.SetRange("Vendor Cr. Memo No.", ExternalDocNo);
        if not PurchHeader.IsEmpty() then begin
            ErrorText := StrSubstNo('Duplicate: Unposted credit memo with External Document No. %1 already exists', ExternalDocNo);
            exit(false);
        end;
        
        exit(true);
    end;

    local procedure ValidateCurrency(CurrencyCode: Code[10]; var ErrorText: Text): Boolean
    var
        Currency: Record Currency;
    begin
        if not Currency.Get(CurrencyCode) then begin
            ErrorText := StrSubstNo('Currency %1 does not exist', CurrencyCode);
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
            ErrorText := StrSubstNo('Posting Date %1 is before allowed posting from date %2', PostingDate, GLSetup."Allow Posting From");
            exit(false);
        end;
        
        if (GLSetup."Allow Posting To" <> 0D) and (PostingDate > GLSetup."Allow Posting To") then begin
            ErrorText := StrSubstNo('Posting Date %1 is after allowed posting to date %2', PostingDate, GLSetup."Allow Posting To");
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
            ErrorText := StrSubstNo('Vendor %1 not found', VendorNo);
            exit(false);
        end;
        
        if Vendor."Vendor Posting Group" = '' then begin
            ErrorText := StrSubstNo('Vendor %1 has no posting group assigned', VendorNo);
            exit(false);
        end;
        
        if not VendorPostingGroup.Get(Vendor."Vendor Posting Group") then begin
            ErrorText := StrSubstNo('Vendor Posting Group %1 not found', Vendor."Vendor Posting Group");
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
            ErrorText := StrSubstNo('Item %1 does not exist', ItemNo);
            exit(false);
        end;
        
        if Item.Blocked then begin
            ErrorText := StrSubstNo('Item %1 is blocked', ItemNo);
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
            ErrorText := StrSubstNo('G/L Account %1 does not exist', AccountNo);
            exit(false);
        end;
        
        if GLAccount.Blocked then begin
            ErrorText := StrSubstNo('G/L Account %1 is blocked', AccountNo);
            exit(false);
        end;
        
        if GLAccount."Account Type" <> GLAccount."Account Type"::Posting then begin
            ErrorText := StrSubstNo('G/L Account %1 is not a posting account', AccountNo);
            exit(false);
        end;
        
        exit(true);
    end;
}
