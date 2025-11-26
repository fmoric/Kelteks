/// <summary>
/// Document Validator for BC27
/// Validates sales and purchase documents before sync
/// </summary>
codeunit 50154 "KLT Document Validator BC27"
{
    /// <summary>
    /// Validates Purchase Invoice before sending to BC17
    /// </summary>
    procedure ValidatePurchaseInvoice(var PurchHeader: Record "Purchase Header"; var ErrorText: Text): Boolean
    var
        Vendor: Record Vendor;
    begin
        ErrorText := '';
        
        if PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice then begin
            ErrorText := 'Document must be a Purchase Invoice';
            exit(false);
        end;
        
        // Validate vendor exists
        if not Vendor.Get(PurchHeader."Buy-from Vendor No.") then begin
            ErrorText := StrSubstNo('Vendor %1 does not exist', PurchHeader."Buy-from Vendor No.");
            exit(false);
        end;
        
        // Validate posting date
        if PurchHeader."Posting Date" = 0D then begin
            ErrorText := 'Posting Date is required';
            exit(false);
        end;
        
        // Validate document date
        if PurchHeader."Document Date" = 0D then begin
            ErrorText := 'Document Date is required';
            exit(false);
        end;
        
        // Validate currency if specified
        if PurchHeader."Currency Code" <> '' then begin
            if not ValidateCurrency(PurchHeader."Currency Code", ErrorText) then
                exit(false);
        end;
        
        exit(true);
    end;

    /// <summary>
    /// Validates Purchase Credit Memo before sending to BC17
    /// </summary>
    procedure ValidatePurchaseCreditMemo(var PurchHeader: Record "Purchase Header"; var ErrorText: Text): Boolean
    var
        Vendor: Record Vendor;
    begin
        ErrorText := '';
        
        if PurchHeader."Document Type" <> PurchHeader."Document Type"::"Credit Memo" then begin
            ErrorText := 'Document must be a Purchase Credit Memo';
            exit(false);
        end;
        
        // Validate vendor exists
        if not Vendor.Get(PurchHeader."Buy-from Vendor No.") then begin
            ErrorText := StrSubstNo('Vendor %1 does not exist', PurchHeader."Buy-from Vendor No.");
            exit(false);
        end;
        
        // Validate posting date
        if PurchHeader."Posting Date" = 0D then begin
            ErrorText := 'Posting Date is required';
            exit(false);
        end;
        
        // Validate document date
        if PurchHeader."Document Date" = 0D then begin
            ErrorText := 'Document Date is required';
            exit(false);
        end;
        
        // Validate currency if specified
        if PurchHeader."Currency Code" <> '' then begin
            if not ValidateCurrency(PurchHeader."Currency Code", ErrorText) then
                exit(false);
        end;
        
        exit(true);
    end;

    /// <summary>
    /// Validates Sales Invoice data received from BC17
    /// </summary>
    procedure ValidateSalesInvoiceData(JsonData: JsonObject; var ErrorText: Text): Boolean
    var
        APIHelper: Codeunit "KLT API Helper BC27";
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
            ErrorText := StrSubstNo('Customer %1 does not exist in BC27', CustomerNo);
            exit(false);
        end;
        
        // Validate dates
        PostingDate := APIHelper.GetJsonDate(JsonData, 'postingDate');
        if PostingDate = 0D then begin
            ErrorText := 'Posting Date is required';
            exit(false);
        end;
        
        DocumentDate := APIHelper.GetJsonDate(JsonData, 'invoiceDate');
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
    /// Validates Sales Credit Memo data received from BC17
    /// </summary>
    procedure ValidateSalesCreditMemoData(JsonData: JsonObject; var ErrorText: Text): Boolean
    var
        APIHelper: Codeunit "KLT API Helper BC27";
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
            ErrorText := StrSubstNo('Customer %1 does not exist in BC27', CustomerNo);
            exit(false);
        end;
        
        // Validate dates
        PostingDate := APIHelper.GetJsonDate(JsonData, 'postingDate');
        if PostingDate = 0D then begin
            ErrorText := 'Posting Date is required';
            exit(false);
        end;
        
        DocumentDate := APIHelper.GetJsonDate(JsonData, 'creditMemoDate');
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
        APIHelper: Codeunit "KLT API Helper BC27";
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
        ItemNo := CopyStr(APIHelper.GetJsonText(LineJson, 'lineObjectNumber'), 1, MaxStrLen(ItemNo));
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
            ErrorText := StrSubstNo('Duplicate: Posted invoice with External Document No. %1 already exists', ExternalDocNo);
            exit(false);
        end;
        
        // Check unposted invoices
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange("External Document No.", ExternalDocNo);
        if not SalesHeader.IsEmpty() then begin
            ErrorText := StrSubstNo('Duplicate: Unposted invoice with External Document No. %1 already exists', ExternalDocNo);
            exit(false);
        end;
        
        exit(true);
    end;

    /// <summary>
    /// Checks for duplicate credit memo using External Document No
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
            ErrorText := StrSubstNo('Duplicate: Posted credit memo with External Document No. %1 already exists', ExternalDocNo);
            exit(false);
        end;
        
        // Check unposted credit memos
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange("External Document No.", ExternalDocNo);
        if not SalesHeader.IsEmpty() then begin
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
    /// Validates customer posting group configuration
    /// </summary>
    procedure ValidateCustomerPostingSetup(CustomerNo: Code[20]; var ErrorText: Text): Boolean
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not Customer.Get(CustomerNo) then begin
            ErrorText := StrSubstNo('Customer %1 not found', CustomerNo);
            exit(false);
        end;
        
        if Customer."Customer Posting Group" = '' then begin
            ErrorText := StrSubstNo('Customer %1 has no posting group assigned', CustomerNo);
            exit(false);
        end;
        
        if not CustomerPostingGroup.Get(Customer."Customer Posting Group") then begin
            ErrorText := StrSubstNo('Customer Posting Group %1 not found', Customer."Customer Posting Group");
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
