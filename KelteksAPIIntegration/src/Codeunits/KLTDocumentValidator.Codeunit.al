/// <summary>
/// Validation logic for document synchronization
/// Validates headers, lines, master data, and business rules
/// </summary>
codeunit 50105 "KLT Document Validator"
{
    /// <summary>
    /// Validate sales document header before sync
    /// </summary>
    procedure ValidateSalesDocumentHeader(DocumentJson: JsonObject; var ErrorMsg: Text): Boolean
    var
        CustomerNo: Code[20];
        PostingDate: Date;
        DocumentDate: Date;
        Customer: Record Customer;
    begin
        ErrorMsg := '';

        // Validate Customer No.
        CustomerNo := CopyStr(GetJsonValueAsText(DocumentJson, 'customerNumber'), 1, 20);
        if CustomerNo = '' then begin
            ErrorMsg := 'Customer No. is required';
            exit(false);
        end;

        if not Customer.Get(CustomerNo) then begin
            ErrorMsg := StrSubstNo('Customer %1 does not exist in target system', CustomerNo);
            exit(false);
        end;

        if Customer.Blocked <> Customer.Blocked::" " then begin
            ErrorMsg := StrSubstNo('Customer %1 is blocked', CustomerNo);
            exit(false);
        end;

        // Validate Posting Date
        PostingDate := GetJsonValueAsDate(DocumentJson, 'postingDate');
        if PostingDate = 0D then begin
            ErrorMsg := 'Posting Date is required';
            exit(false);
        end;

        if not ValidatePostingPeriod(PostingDate) then begin
            ErrorMsg := StrSubstNo('Posting Date %1 is not within allowed posting period', PostingDate);
            exit(false);
        end;

        // Validate Document Date
        DocumentDate := GetJsonValueAsDate(DocumentJson, 'documentDate');
        if DocumentDate = 0D then begin
            ErrorMsg := 'Document Date is required';
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validate purchase document header before sync
    /// </summary>
    procedure ValidatePurchaseDocumentHeader(DocumentJson: JsonObject; var ErrorMsg: Text): Boolean
    var
        VendorNo: Code[20];
        PostingDate: Date;
        DocumentDate: Date;
        Vendor: Record Vendor;
    begin
        ErrorMsg := '';

        // Validate Vendor No.
        VendorNo := CopyStr(GetJsonValueAsText(DocumentJson, 'vendorNumber'), 1, 20);
        if VendorNo = '' then begin
            ErrorMsg := 'Vendor No. is required';
            exit(false);
        end;

        if not Vendor.Get(VendorNo) then begin
            ErrorMsg := StrSubstNo('Vendor %1 does not exist in target system', VendorNo);
            exit(false);
        end;

        if Vendor.Blocked <> Vendor.Blocked::" " then begin
            ErrorMsg := StrSubstNo('Vendor %1 is blocked', VendorNo);
            exit(false);
        end;

        // Validate Posting Date
        PostingDate := GetJsonValueAsDate(DocumentJson, 'postingDate');
        if PostingDate = 0D then begin
            ErrorMsg := 'Posting Date is required';
            exit(false);
        end;

        if not ValidatePostingPeriod(PostingDate) then begin
            ErrorMsg := StrSubstNo('Posting Date %1 is not within allowed posting period', PostingDate);
            exit(false);
        end;

        // Validate Document Date
        DocumentDate := GetJsonValueAsDate(DocumentJson, 'documentDate');
        if DocumentDate = 0D then begin
            ErrorMsg := 'Document Date is required';
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validate document line
    /// </summary>
    procedure ValidateDocumentLine(LineJson: JsonObject; var ErrorMsg: Text): Boolean
    var
        LineType: Text;
        No: Code[20];
        Quantity: Decimal;
        UnitPrice: Decimal;
        Item: Record Item;
        GLAccount: Record "G/L Account";
        Resource: Record Resource;
    begin
        ErrorMsg := '';

        // Validate Type
        LineType := GetJsonValueAsText(LineJson, 'lineType');
        if LineType = '' then begin
            ErrorMsg := 'Line Type is required';
            exit(false);
        end;

        // Validate No.
        No := CopyStr(GetJsonValueAsText(LineJson, 'number'), 1, 20);
        if No = '' then begin
            ErrorMsg := 'Line No. is required';
            exit(false);
        end;

        // Validate based on type
        case LineType of
            'Item':
                if not Item.Get(No) then begin
                    ErrorMsg := StrSubstNo('Item %1 does not exist', No);
                    exit(false);
                end;
            'Account':
                if not GLAccount.Get(No) then begin
                    ErrorMsg := StrSubstNo('G/L Account %1 does not exist', No);
                    exit(false);
                end;
            'Resource':
                if not Resource.Get(No) then begin
                    ErrorMsg := StrSubstNo('Resource %1 does not exist', No);
                    exit(false);
                end;
        end;

        // Validate Quantity
        Quantity := GetJsonValueAsDecimal(LineJson, 'quantity');
        if Quantity <= 0 then begin
            ErrorMsg := 'Quantity must be greater than 0';
            exit(false);
        end;

        // Validate Unit Price
        UnitPrice := GetJsonValueAsDecimal(LineJson, 'unitPrice');
        if UnitPrice < 0 then begin
            ErrorMsg := 'Unit Price cannot be negative';
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validate posting period
    /// </summary>
    local procedure ValidatePostingPeriod(PostingDate: Date): Boolean
    var
        UserSetup: Record "User Setup";
        GLSetup: Record "General Ledger Setup";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
    begin
        if UserSetup.Get(UserId()) then begin
            AllowPostingFrom := UserSetup."Allow Posting From";
            AllowPostingTo := UserSetup."Allow Posting To";
        end;

        if AllowPostingFrom = 0D then begin
            GLSetup.Get();
            AllowPostingFrom := GLSetup."Allow Posting From";
            AllowPostingTo := GLSetup."Allow Posting To";
        end;

        if AllowPostingFrom = 0D then
            exit(true);

        if (PostingDate < AllowPostingFrom) or (PostingDate > AllowPostingTo) then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Validate currency code exists
    /// </summary>
    procedure ValidateCurrency(CurrencyCode: Code[10]; var ErrorMsg: Text): Boolean
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            exit(true); // LCY is allowed

        if not Currency.Get(CurrencyCode) then begin
            ErrorMsg := StrSubstNo('Currency %1 does not exist', CurrencyCode);
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validate payment terms exist
    /// </summary>
    procedure ValidatePaymentTerms(PaymentTermsCode: Code[10]; var ErrorMsg: Text): Boolean
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTermsCode = '' then
            exit(true); // Will use default

        if not PaymentTerms.Get(PaymentTermsCode) then begin
            ErrorMsg := StrSubstNo('Payment Terms %1 does not exist', PaymentTermsCode);
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Validate posting groups
    /// </summary>
    procedure ValidatePostingGroups(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; var ErrorMsg: Text): Boolean
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        if (GenBusPostingGroup = '') or (GenProdPostingGroup = '') then
            exit(true);

        if not GenPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup) then begin
            ErrorMsg := StrSubstNo('Posting Setup does not exist for Gen. Bus. Posting Group %1 and Gen. Prod. Posting Group %2',
                                   GenBusPostingGroup, GenProdPostingGroup);
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Check system settings
    /// </summary>
    procedure ValidateSystemSettings(var Warnings: List of [Text]): Boolean
    var
        InvtSetup: Record "Inventory Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        Clear(Warnings);

        // Check inventory settings
        if InvtSetup.Get() then begin
            if not InvtSetup."Prevent Negative Inventory" then
                Warnings.Add('WARNING: Negative inventory is not prevented. This may cause issues with synchronization.');
        end;

        // Check sales setup
        if SalesSetup.Get() then begin
            if SalesSetup."Exact Cost Reversing Mandatory" then
                Warnings.Add('WARNING: Exact Cost Reversing is mandatory. This should be disabled for BC27.');
        end;

        exit(Warnings.Count = 0);
    end;

    // Helper functions for JSON parsing
    local procedure GetJsonValueAsText(JsonObj: JsonObject; Key: Text): Text
    var
        Token: JsonToken;
    begin
        if JsonObj.Get(Key, Token) then
            if not Token.AsValue().IsNull() then
                exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure GetJsonValueAsDate(JsonObj: JsonObject; Key: Text): Date
    var
        Token: JsonToken;
        DateValue: Date;
    begin
        if JsonObj.Get(Key, Token) then
            if not Token.AsValue().IsNull() then
                if Evaluate(DateValue, Token.AsValue().AsText()) then
                    exit(DateValue);
        exit(DateValue);
    end;

    local procedure GetJsonValueAsDecimal(JsonObj: JsonObject; Key: Text): Decimal
    var
        Token: JsonToken;
        DecimalValue: Decimal;
    begin
        if JsonObj.Get(Key, Token) then
            if not Token.AsValue().IsNull() then
                if Evaluate(DecimalValue, Token.AsValue().AsText()) then
                    exit(DecimalValue);
        exit(DecimalValue);
    end;
}
