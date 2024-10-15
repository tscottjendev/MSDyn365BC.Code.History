codeunit 134045 "ERM VAT Sales/Purchase"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        VATAmountErr: Label '%1 must not exceed %2 = 0', Comment = '.';
        CurrVATAmountErr: Label '%1 for %2 must not exceed %3 = 0', Comment = '.';
        VATDifferenceErr: Label 'VAT Difference must be %1 in %2.', Comment = '.';
        AmountErr: Label '%1 must be %2 in %3.', Comment = '.';
        VATDateErr: Label 'VAT date on document do not mach VAT Entry', Comment = '.';
        VATDateOnRecordErr: Label 'VAT date was not correctly updated on record', Comment = '.';
        VatDateComparisonErr: Label 'VAT Date is not correct based on GL setup', Comment = '.';
        MustNotBeNegativeErr: Label '%1 must not be negative.', Comment = '.';
        PostingGroupErr: Label '%1 must be %2 in %3: %4.', Comment = '.';
        VATAmountMsg: Label '%1 must not be editable.', Comment = '.';
        RoundingEntryErr: Label 'Rounding Entry must exist for Sales Document No.: %1.', Comment = '.';
        TooManyValuableSalesEntriesErr: Label 'Too many valuable Sales Lines found.', Comment = '.';
        TooManyValuablePurchaseEntriesErr: Label 'Too many valuable Purchase Lines found.', Comment = '.';
        VATDateNotChangedErr: Label 'VAT Return Period is closed for the selected date. Please select another date.';

    [Test]
    [Scope('OnPrem')]
    procedure ErrorVATAmountOnSalesOrder()
    var
        VATAmountLine: Record "VAT Amount Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check that VAT Amount Difference Error raised on VAT Amount Line with Sales Order.

        // Setup: Take Zero for Max VAT Allow Difference in Sales and Receivable Setup.
        Initialize();
        ModifyAllowVATDifferenceSales(false);
        SetupForSalesOrderAndVAT(VATAmountLine);

        // Exercise: Validate VAT Amount Line for Random Value and Check VAT Difference Error.
        VATAmountLine.Validate("VAT Amount", LibraryRandom.RandDec(10, 2));
        asserterror VATAmountLine.CheckVATDifference('', true);

        // Verify: Verify Error Raised on Validation of VAT Amount on VAT Amount Line.
        Assert.ExpectedError(
          StrSubstNo(
            VATAmountErr, VATAmountLine.FieldCaption("VAT Difference"), GeneralLedgerSetup.FieldCaption("Max. VAT Difference Allowed")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorVATAmountOnPurchaseOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATAmountLine: Record "VAT Amount Line";
        CurrencyCode: Code[10];
    begin
        // Check that VAT Amount Difference Error raised on VAT Amount Line with Purchase Order.

        // Setup: Take Zero for Max VAT Allow Difference in Purchase and Payable Setup.
        Initialize();
        ModifyAllowVATDifferencePurchases(false);
        CurrencyCode := SetupForPurchaseOrderAndVAT(VATAmountLine);

        // Exercise: Validate VAT Amount Line for Random Value and Check VAT Difference Error.
        VATAmountLine.Validate("VAT Amount", LibraryRandom.RandDec(10, 2));
        asserterror VATAmountLine.CheckVATDifference(CurrencyCode, true);

        // Verify: Verify Error Raised on Validation of VAT Amount on VAT Amount Line.
        Assert.ExpectedError(
          StrSubstNo(
            CurrVATAmountErr, VATAmountLine.FieldCaption("VAT Difference"), CurrencyCode,
            GeneralLedgerSetup.FieldCaption("Max. VAT Difference Allowed")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATDifferenceOnSalesOrder()
    var
        VATAmountLine: Record "VAT Amount Line";
    begin
        // Check VAT Difference field value on VAT Amount Line with Sales Order.

        // Setup: Take Random Value for Max VAT Allow Difference in Sales and Receivable Setup.
        Initialize();
        ModifyAllowVATDifferenceSales(true);
        SetupForSalesOrderAndVAT(VATAmountLine);

        // Validate VAT Amount Line for VAT Difference and Verify it.
        ValidateAndVerifyVATAmount(VATAmountLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATDifferenceOnPurchaseOrder()
    var
        VATAmountLine: Record "VAT Amount Line";
    begin
        // Check VAT Difference field value on VAT Amount Line with Purchase Order.

        // Setup: Take Random for Max VAT Allow Difference in Purchase and Payable Setup.
        Initialize();
        ModifyAllowVATDifferencePurchases(true);
        SetupForPurchaseOrderAndVAT(VATAmountLine);

        // Validate VAT Amount Line for VAT Difference and Verify it.
        ValidateAndVerifyVATAmount(VATAmountLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSalesOrderShipAndInvoice()
    var
        VATEntry: Record "VAT Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BaseAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check Base Amount on VAT Entry after Posting Ship and Invoice Sales Order.

        // Setup.
        Initialize();

        // Take 1 Fix value to Create 1 Sales Line.
        BaseAmount := CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Order);

        // Exercise: Post Sales Order with Ship and Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify VAT Entry for Base Amount.
        VerifyVATBase(DocumentNo, -BaseAmount, VATEntry.Type::Sale);
        VerifyVATDate(DocumentNo, VATEntry.Type::Sale, SalesHeader."VAT Reporting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSalesOrderInvoiceAfterShip()
    var
        VATEntry: Record "VAT Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BaseAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check Base Amount on VAT Entry after Posting Sales Order as Ship then Change Qty. to Invoice then Post as Invoice.

        // Setup. Create Sales Order and Ship it and Change Qty. to Invoice.
        Initialize();

        // Take 1 Fix value to Create 1 Sales Line.
        BaseAmount := CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Order);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Invoice", SalesLine."Quantity Shipped");
        SalesLine.Modify(true);

        // Exercise: Post Sales Order with Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Verify: Verify VAT Entry for Base Amount.
        VerifyVATBase(DocumentNo, -BaseAmount, VATEntry.Type::Sale);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPurchOrderReceiveAndInvoice()
    var
        VATEntry: Record "VAT Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        BaseAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check Base Amount on VAT Entry after Posting with Receive and Invoice Purchase Order.

        // Setup.
        Initialize();

        // Take 1 Fix value to Create 1 Purchase Line.
        BaseAmount := CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, PurchaseHeader."Document Type"::Order);
        DocumentNo := NoSeriesManagement.GetNextNo(PurchaseHeader."Posting No. Series", WorkDate(), false);

        // Exercise: Post Purchase Order with Receive and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify VAT Entry for Base Amount.
        VerifyVATBase(DocumentNo, BaseAmount, VATEntry.Type::Purchase);
        VerifyVATDate(DocumentNo, VATEntry.Type::Purchase, PurchaseHeader."VAT Reporting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPurchOrderInvAfterReceive()
    var
        VATEntry: Record "VAT Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        BaseAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check Base Amount on VAT Entry after Posting Purchase Order as Receive then Change Qyt. to Invoice then Post as Invoice.

        // Setup: Create Purchase Order and Receive it and Change Qty. to Invoice.
        Initialize();

        // Take 1 Fix value to Create 1 Purchase Line.
        BaseAmount := CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, PurchaseHeader."Document Type"::Order);
        DocumentNo := NoSeriesManagement.GetNextNo(PurchaseHeader."Posting No. Series", WorkDate(), false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Quantity Received");
        PurchaseLine.Modify(true);

        // Exercise: Post Purchase Order with Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Verify: Verify VAT Entry for Base Amount.
        VerifyVATBase(DocumentNo, BaseAmount, VATEntry.Type::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderVATAmountError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Taken Zero for Max VAT Allow Difference in Purchase and Payable Setup.
        // Verify Negative VAT Amount error after creating Purchase Order.
        Initialize();
        PurchaseDocumentVATAmountError(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoVATAmountError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Taken Zero for Max VAT Allow Difference in Purchase and Payable Setup.
        // Verify Negative VAT Amount error after creating Purchase Credit Memo.
        Initialize();
        PurchaseDocumentVATAmountError(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    local procedure PurchaseDocumentVATAmountError(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // Create Purchase Document and verify Negative VAT Amount Error using Random Values, Values are not important for test.
        ModifyAllowVATDifferencePurchases(false);
        CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, DocumentType);
        CalcPurchaseVATAmountLines(VATAmountLine, PurchaseHeader, PurchaseLine);

        // Exercise: Validate Purchase Document for Negative Random VAT Amount.
        asserterror VATAmountLine.Validate("VAT Amount", -LibraryRandom.RandDec(10, 2));

        // Verify: Verify VAT Amount Error On Negative Value.
        Assert.ExpectedError(StrSubstNo(MustNotBeNegativeErr, VATAmountLine.FieldCaption("VAT Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderVATAmountError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Taken Zero for Max VAT Allow Difference in Sales and Receivables Setup.
        // Verify Negative VAT Amount error after creating Sales Order.
        Initialize();
        SalesDocumentVATAmountError(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoVATAmountError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Taken Zero for Max VAT Allow Difference in Sales and Receivables Setup.
        // Verify Negative VAT Amount error after creating Sales Credit Memo.
        Initialize();
        SalesDocumentVATAmountError(SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure SalesDocumentVATAmountError(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // Create Sales Document and verify Negative VAT Amount Error using Random Values, Values are not important for test.
        ModifyAllowVATDifferenceSales(false);
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, DocumentType);
        CalcSalesVATAmountLines(VATAmountLine, SalesHeader, SalesLine);

        // Exercise: Validate Sales Document for Negative Random VAT Amount.
        asserterror VATAmountLine.Validate("VAT Amount", -LibraryRandom.RandDec(10, 2));

        // Verify: Verify VAT Amount Error On Negative Value.
        Assert.ExpectedError(StrSubstNo(MustNotBeNegativeErr, VATAmountLine.FieldCaption("VAT Amount")));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeCustomerOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        VATDifference: Decimal;
    begin
        // Check VAT Difference on VAT Amount Line for Sales Invoice after changing Customer on Sales Header.

        // Setup: Create Sales Invoice and calculate VAT Amount.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId);
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId);
        VATDifference := ModifyAllowVATDifferenceSales(true);
        CreateSalesDocumentAndCalcVAT(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, VATDifference);

        // Exercise: Change Customer No. on Sales Header and Calculate VAT Amount Lines.
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo);
        SalesHeader.Modify(true);
        CalcSalesVATAmountLines(VATAmountLine, SalesHeader, SalesLine);

        // Verify: Verify VAT Amount Line for VAT Difference.
        Assert.AreEqual(0, VATAmountLine."VAT Difference", StrSubstNo(VATDifferenceErr, 0, VATAmountLine.TableCaption()));

        // Tear Down: Delete Sales Header.
        SalesHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeCurrencyOnSalesOrder()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        VATDifference: Decimal;
    begin
        // Check VAT Difference on VAT Amount Line for Sales Order after changing Currency on Sales Header.

        // Setup: Create Sales Order and calculate VAT Amount.
        Initialize();
        VATDifference := ModifyAllowVATDifferenceSales(true);
        CreateSalesDocumentAndCalcVAT(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, VATDifference);

        // Exercise: Change Currency on Sales Header and Calculate VAT Amount Lines.
        LibraryERM.FindCurrency(Currency);
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Modify(true);
        CalcSalesVATAmountLines(VATAmountLine, SalesHeader, SalesLine);

        // Verify: Verify VAT Amount Line for VAT Difference.
        Assert.AreEqual(0, VATAmountLine."VAT Difference", StrSubstNo(VATDifferenceErr, 0, VATAmountLine.TableCaption()));

        // Tear Down: Delete Sales Header.
        SalesHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeCurrencyOnPurchaseOrder()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        VATDifference: Decimal;
    begin
        // Check VAT Difference on VAT Amount Line for Purchase Order after changing Currency on Purchase Header.

        // Setup: Create Purchase Order and calculate VAT Amount.
        Initialize();
        VATDifference := ModifyAllowVATDifferencePurchases(true);
        CreatePurchDocumentAndCalcVAT(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, VATDifference);

        // Exercise: Change Currency on Purchase Header and Calculate VAT Amount Lines.
        LibraryERM.FindCurrency(Currency);
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Modify(true);
        CalcPurchaseVATAmountLines(VATAmountLine, PurchaseHeader, PurchaseLine);

        // Verify: Verify VAT Amount Line for VAT Difference.
        Assert.AreEqual(0, VATAmountLine."VAT Difference", StrSubstNo(VATDifferenceErr, 0, VATAmountLine.TableCaption()));

        // Tear Down: Delete Purchase Header.
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeVendorOnPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        VATDifference: Decimal;
    begin
        // Check VAT Difference on VAT Amount Line for Purchase Invoice after changing Vendor on Purchase Header.

        // Setup: Create Purchase Invoice and calculate VAT Amount.
        Initialize();
        VATDifference := ModifyAllowVATDifferencePurchases(true);
        CreatePurchDocumentAndCalcVAT(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, VATDifference);

        // Exercise: Change Vendor on Purchase Header and Calculate VAT Amount Lines.
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo);
        PurchaseHeader.Modify(true);
        CalcPurchaseVATAmountLines(VATAmountLine, PurchaseHeader, PurchaseLine);

        // Verify: Verify VAT Amount Line for VAT Difference.
        Assert.AreEqual(0, VATAmountLine."VAT Difference", StrSubstNo(VATDifferenceErr, 0, VATAmountLine.TableCaption()));

        // Tear Down: Delete Purchase Header.
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderVATDifference()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        VATDifference: Decimal;
        PostedDocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Check VAT Amount on GL Entry after taking VAT Difference amount on Purchase Line.

        // Setup: Modify General Ledger Setup and Purchase Payable Setup for VAT Difference, Create Purchase Order, Calculate and Modify
        // Purchase Line for VAT Difference with Random Amount.
        Initialize();
        VATDifference := ModifyAllowVATDifferencePurchases(true);
        CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, PurchaseHeader."Document Type"::Order);
        PurchaseLine.Validate("VAT Difference", VATDifference);
        PurchaseLine.Modify(true);
        VATAmount :=
          Round(PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost" * PurchaseLine."VAT %" / 100) + VATDifference;
        PostedDocumentNo := NoSeriesManagement.GetNextNo(PurchaseHeader."Posting No. Series", WorkDate(), false);

        // Exercise: Post Purchase Order with Ship and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry for VAT Amount with Correct VAT Difference
        VerifyGLEntry(PostedDocumentNo, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderVATDifference()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATDifference: Decimal;
        PostedDocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Check VAT Amount on GL Entry after taking VAT Difference amount on Sales Line.

        // Setup: Modify General Ledger Setup and Sales And Receivable Setup for VAT Difference, Create Sales Order and Modify
        // Sales Line for VAT Difference with Random Amount.
        Initialize();
        VATDifference := ModifyAllowVATDifferenceSales(true);
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Order);
        SalesLine.Validate("VAT Difference", VATDifference);
        SalesLine.Modify(true);
        VATAmount := Round(SalesLine."Qty. to Invoice" * SalesLine."Unit Price" * SalesLine."VAT %" / 100) + VATDifference;

        // Exercise: Post Sales Order with Ship and Invoice.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify GL Entry for VAT Amount with Correct VAT Difference
        VerifyGLEntry(PostedDocumentNo, -VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutStandingSalesBeforeRelease()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OutstandingAmount: Decimal;
    begin
        // Check Outstanding Amount on Sales Line and Customer after Creating Sales Order.

        // Setup.
        Initialize();
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Order);

        // Exercise: Calculate Outstanding Amount on Sales Line.
        OutstandingAmount := Round(SalesLine."Line Amount" * SalesLine."VAT %" / 100 + SalesLine."Line Amount");

        // Verify: Verify Customer and Sales Line for Correct Outstanding Order (LCY) and Outstanding Amount respectively.
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.CalcFields("Outstanding Orders (LCY)");
        Customer.TestField("Outstanding Orders (LCY)", OutstandingAmount);
        SalesLine.TestField("Outstanding Amount", OutstandingAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutStandingSalesAfterRelease()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OutstandingAmount: Decimal;
    begin
        // Check Outstanding Amount on Sales Line and Customer after Creating Sales Order and Release.

        // Setup: Create Sales Order and Calculate Outstanding amount.
        Initialize();
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Order);
        OutstandingAmount := Round(SalesLine."Line Amount" * SalesLine."VAT %" / 100 + SalesLine."Line Amount");

        // Exercise: Release Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Verify: Verify Sales Line for Correct Outstanding Amount after Release.
        SalesLine.TestField("Outstanding Amount", OutstandingAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutStandingPurchBeforeRelease()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        OutstandingAmount: Decimal;
    begin
        // Check Outstanding Amount on Purchase Line and Vendor after Creating Purchase Order.

        // Setup.
        Initialize();
        CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, PurchaseHeader."Document Type"::Order);

        // Exercise: Calculate Outstanding Amount on Purchase Line.
        OutstandingAmount := Round(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100 + PurchaseLine."Line Amount");

        // Verify: Verify Vendor and Purchase Line for Correct Outstanding Order (LCY) and Outstanding Amount respectively.
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.CalcFields("Outstanding Orders (LCY)");
        Vendor.TestField("Outstanding Orders (LCY)", OutstandingAmount);
        PurchaseLine.TestField("Outstanding Amount", OutstandingAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutStandingPurchAfterRelease()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OutstandingAmount: Decimal;
    begin
        // Check Outstanding Amount on Purchase Line and Vendor after Creating Purchase Order and Release.

        // Setup: Create Purchase Order and Calculate Outstanding amount.
        Initialize();
        CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, PurchaseHeader."Document Type"::Order);
        OutstandingAmount := Round(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100 + PurchaseLine."Line Amount");

        // Exercise: Release Purchase order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Verify: Verify Purchase Line for Correct Outstanding Amount after Release.
        PurchaseLine.TestField("Outstanding Amount", OutstandingAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATDifferenceOnCopySalesDoc()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATAmountLine: Record "VAT Amount Line";
        VATDifference: Decimal;
    begin
        // Check VAT Amount on VAT Amount line after run Copy Sales Document Report which should be same with first Sales Invoice.

        // Setup: Modify Setup, Create Sales Invoice and Calculate VAT Amount Line with Random Values.
        Initialize();
        ModifyAllowVATDifferenceSales(true);
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Invoice); // Take 1 for Single Sales Line.
        GeneralLedgerSetup.Get();
        SalesLine.Validate("VAT Difference", GeneralLedgerSetup."Max. VAT Difference Allowed");
        SalesLine.Modify(true);
        VATDifference := SalesLine."VAT Difference";
        CalcSalesVATAmountLines(VATAmountLine, SalesHeader, SalesLine);

        // Exercise: Create Sales Header and Run Copy Sales Document Report and Calculate VAT Amount Line.
        SalesHeader2.Init();
        SalesHeader2.Validate("Document Type", SalesHeader2."Document Type"::Invoice);
        SalesHeader2.Insert(true);
        RunCopySalesDocument(SalesHeader2, SalesHeader."No.", "Sales Document Type From"::Invoice, true, false);
        SalesLine.Get(SalesHeader2."Document Type", SalesHeader2."No.", SalesLine."Line No.");
        CalcSalesVATAmountLines(VATAmountLine, SalesHeader, SalesLine);

        // Verify: Verify VAT Amount on VAT Amount line which should be same after Copy Sales Document for First Sales Invoice.
        Assert.AreEqual(
          VATDifference, VATAmountLine."VAT Difference",
          StrSubstNo(VATDifferenceErr, GeneralLedgerSetup."Max. VAT Difference Allowed", VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATDifferenceOnCopyPurchDoc()
    var
        VATAmountLine: Record "VAT Amount Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATDifference: Decimal;
    begin
        // Check VAT Amount on VAT Amount line after run Copy Purchase Document Report which should be same with first Purchase Invoice.

        // Setup: Modify Setup, Create Purchase Invoice with 1 Purchase Line and Calculate VAT Amount Line.
        Initialize();
        VATDifference := ModifyAllowVATDifferencePurchases(true);
        CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, PurchaseHeader."Document Type"::Invoice);
        PurchaseLine.Validate("VAT Difference", VATDifference);
        PurchaseLine.Modify(true);
        CalcPurchaseVATAmountLines(VATAmountLine, PurchaseHeader, PurchaseLine);

        // Exercise: Create Purchase Header and Run Copy Purchase Document Report and Calculate VAT Amount Line.
        PurchaseHeader2.Init();
        PurchaseHeader2.Validate("Document Type", PurchaseHeader2."Document Type"::Invoice);
        PurchaseHeader2.Insert(true);
        RunCopyPurchaseDocument(PurchaseHeader2, PurchaseHeader."No.");
        PurchaseLine.Get(PurchaseHeader2."Document Type", PurchaseHeader2."No.", PurchaseLine."Line No.");
        CalcPurchaseVATAmountLines(VATAmountLine, PurchaseHeader, PurchaseLine);

        // Verify: Verify VAT Amount on VAT Amount line which should be same after Copy Purchase Document for First Purchase Invoice.
        Assert.AreEqual(
          VATDifference, VATAmountLine."VAT Difference",
          StrSubstNo(VATDifferenceErr, VATDifference, VATAmountLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATPostingGroupBillToPayToNo()
    var
        SalesHeader: Record "Sales Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check that correct VAT Bus. Posting Group and Gen. Bus. Posting Group updated on Sales Header and VAT Entry when Bill To Sell To VAT Calc is Bill To Pay To No.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId);
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId);
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        SetupBillToSellToVATCalc(SalesHeader, GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // Verify: Verify Correct VAT Bus Posting Group updated on Sales Header.
        VerifyCustomerVATPostingGroup(SalesHeader."Bill-to Customer No.", SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATPostingGroupSellToBuyFromNo()
    var
        SalesHeader: Record "Sales Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check that correct VAT Bus. Posting Group and Gen. Bus. Posting Group updated on Sales Header and VAT Entry when Bill To Sell To VAT Calc is Sell To Buy From No.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId);
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId);
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        SetupBillToSellToVATCalc(SalesHeader, GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // Verify: Verify Correct VAT Bus Posting Group updated on Sales Header.
        VerifyCustomerVATPostingGroup(SalesHeader."Sell-to Customer No.", SalesHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceVATFieldCheck()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        VatAmount: Decimal;
        BaseAmount: Decimal;
    begin
        // Check specified fields on VAT Entry after Posting Invoice.

        // Setup.
        Initialize();

        // Take 1 Fix value to Create 1 Purchase Line and calculate VAT Entry Amount.
        BaseAmount := CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, PurchaseHeader."Document Type"::Order);
        VatAmount := BaseAmount * (PurchaseLine."VAT %" / 100);

        // Exercise: Post Purchase Order with Receive and Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify specified fields in VAT Entry.
        VerifyVATEntry(PurchaseLine, DocumentNo, VatAmount);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler,CheckValuesOnVATAmountLinesMPH')]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsVATAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check VAT Amount field value on VAT Amount Line using Sales Order Statistics page.

        // Setup: Create Sales Order with Random Quantity and Unit Price.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, false);

        // Exercise: Open Sales Order Statistics page.
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount" * SalesLine."VAT %" / 100);
        OpenSalesOrderStatistics(SalesHeader."No.");

        // Verify: Verify VAT Amount on VAT Amount Lines page.
        // Verification done in handler.
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsHandler,CheckValuesOnVATAmountLinesMPH')]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsVATAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check whether VAT Amount field is editable on VAT Amount Line using Purchase Order Statistics page.

        // Setup.
        Initialize();
        ModifyAllowVATDifferencePurchases(false);

        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseLine."Document Type"::Order, false);

        // Exercise: Open Sales Order Statistics page.
        LibraryVariableStorage.Enqueue(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);
        OpenPurchaseOrderStatistics(PurchaseHeader."No.");

        // Verify: Verify VAT Amount field on VAT Amount Lines page.
        // Verification done in handler.
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsHandler,EditSalesVATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderDocTotalsAfterVATUpdatedOnStatsPage()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchOrderPage: TestPage "Purchase Order";
        ExpectedVATAmount: Decimal;
        MaxVATDiffAmt: Decimal;
    begin
        // [FEATURE] [Document Totals] [Statistics] [UI] [Purchase]
        Initialize();
        // [GIVEN] VAT Difference is allowed for Purch
        MaxVATDiffAmt := ModifyAllowVATDifferencePurchases(true);

        // [GIVEN] Purch Order with one line, where Document Totals show "Base" is 100, "VAT Amount" is 20;
        CreatePurchaseDocument(PurchHeader, PurchLine, PurchLine."Document Type"::Order, false);

        // [GIVEN] Open "Purch Order" page
        PurchOrderPage.Trap;
        PAGE.Run(PAGE::"Purchase Order", PurchHeader);
        PurchOrderPage.PurchLines.First;
        PurchOrderPage.PurchLines."Line Amount".SetValue(PurchOrderPage.PurchLines."Line Amount".AsDEcimal); // to trigger totals calculation
        ExpectedVATAmount := PurchOrderPage.PurchLines."Total VAT Amount".AsDEcimal + MaxVATDiffAmt;
        LibraryVariableStorage.Enqueue(ExpectedVATAmount);

        // [GIVEN] "Purch Order Statistics" page is open from "Purch Order" page
        PurchOrderPage.Statistics.Invoke; // handled by PurchOrderStatisticsChangeVATHandler

        // [GIVEN] "VAT Amount" is changed to 21 in the line on the "Invoice" tab
        // Executed in VATAmountLinesHandler

        // [WHEN] Statistics page is closed

        // [THEN] Document Totals on "Purch Order" page are updated: "VAT Amount" is 21.
        PurchOrderPage.PurchLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler,EditSalesVATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderDocTotalsAfterVATUpdatedOnStatsPage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderPage: TestPage "Sales Order";
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [Document Totals] [Statistics] [UI] [Sales]
        Initialize();

        // [GIVEN] Sales Order with one line, where Document Totals show "Base" is 100, "VAT Amount" is 20;
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, true);

        // [GIVEN] Open "Sales Order" page
        SalesOrderPage.Trap;
        PAGE.Run(PAGE::"Sales Order", SalesHeader);
        SalesOrderPage.SalesLines.First;
        SalesOrderPage.SalesLines."Line Amount".SetValue(SalesOrderPage.SalesLines."Line Amount".AsDEcimal); // to trigger totals calculation
        ExpectedVATAmount := SalesOrderPage.SalesLines."Total VAT Amount".AsDEcimal;
        LibraryVariableStorage.Enqueue(ExpectedVATAmount);

        // [GIVEN] "Sales Order Statistics" page is open from "Sales Order" page
        SalesOrderPage.Statistics.Invoke; // handled by SalesOrderStatisticsChangeVATHandler

        // [GIVEN] "VAT Amount" is changed to 21 in the line on the "Invoice" tab
        // Executed in VATAmountLinesHandler

        // [WHEN] Statistics page is closed

        // [THEN] Document Totals on "Sales Order" page are updated: "VAT Amount" is 21.
        SalesOrderPage.SalesLines."Total VAT Amount".AssertEquals(ExpectedVATAmount);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler,EditSalesVATAmountLinesHandler')]
    [Scope('OnPrem')]
    procedure VATDifferenceOnSalesLine()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        MaxVATDifference: Decimal;
        GLAccountNo: Code[20];
    begin
        // Check VAT Difference field value on Sales Line when second line is entered after editing VAT Amount on first Sales Line using Statistics page.

        // Setup: Update General Ledger and Sales & Receivable Setup,Create Sales Order.
        // Take Random value for Max. VAT Difference.
        Initialize();
        MaxVATDifference := ModifyAllowVATDifferenceSales(true);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, true);

        // Exercise: Edit VAT Amount on VAT Amount Lines page and create new Sales Line.
        CalcSalesVATAmountLines(VATAmountLine, SalesHeader, SalesLine);
        LibraryVariableStorage.Enqueue(VATAmountLine."VAT Amount" - MaxVATDifference);
        OpenSalesOrderStatistics(SalesHeader."No.");
        VATPostingSetup.Get(SalesHeader."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        GLAccountNo := CreateSalesLineThroughPage(VATPostingSetup, SalesHeader."No.");

        // Verify: Verify VAT Difference on Sales Lines.
        VerifyVATDifference(SalesHeader."Document Type", SalesHeader."No.", SalesLine."No.", -MaxVATDifference);
        VerifyVATDifference(SalesHeader."Document Type", SalesHeader."No.", GLAccountNo, 0); // VAT Difference must be zero because we have not edit the VAT Amount for this line.
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler,VATAmountLineHandler')]
    [Scope('OnPrem')]
    procedure VATAmtFromSalesOrderStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check that field VAT Amount must not be editable on VAT Amount Line Page of Sales Order Statistics Page.

        // Setup: Create Sales Order and take 1 for No of Sales Lines.
        Initialize();
        ModifyAllowVATDifferenceSales(false);
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Order);

        // Exercise: Open Statistics page from Sales Order.
        OpenSalesOrderStatistics(SalesHeader."No.");

        // Verify: Verification is done for VAT Amount in 'VATAmountLineHandler' handler method.
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsHandler,VATAmountLineHandler')]
    [Scope('OnPrem')]
    procedure VATAmtFromPurchOrderStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check that field VAT Amount must not be editable on VAT Amount Line Page of Purchase Order Statistics Page.

        // Setup: Create Purchase Order and take 1 for No of Purchase Lines.
        Initialize();
        ModifyAllowVATDifferencePurchases(false);
        CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, PurchaseHeader."Document Type"::Order);

        // Exercise: Open Statistics page from Purchase Order.
        OpenPurchaseOrderStatistics(PurchaseHeader."No.");

        // Verify: Verification is done for VAT Amount in 'VATAmountLineHandler' handler method.
    end;

    [Test]
    [HandlerFunctions('SalesQuoteStatisticsHandler')]
    [Scope('OnPrem')]
    procedure VATAmtFromSalesQuoteStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check that field VAT Amount must not be editable on VAT Amount Line Page of Sales Quotes Statistics page.

        // Setup: Create Sales Quote and take 1 for No of Sales Lines.
        Initialize();
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Quote);

        // Exercise: Open Statistics page from Sales Quote.
        OpenSalesQuoteStatistics(SalesHeader."No.");

        // Verify: Verification is done for VAT Amount in 'VATAmountLineHandler' handler method.
    end;

    [Test]
    [HandlerFunctions('BlanketOrderStatisticsHandler,VATAmountLineHandler')]
    [Scope('OnPrem')]
    procedure VATAmtFromSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check that field VAT Amount must not be editable on VAT Amount Line Page of Sales Blanket Order Statistics page.

        // Setup: Create Sales Blanket Order and take 1 for No of Sales Lines.
        Initialize();
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::"Blanket Order");

        // Exercise: Open Statistics page from Blanket Sales Order.
        OpenBlanketSalesOrderStatistics(SalesHeader."No.");

        // Verify: Verification is done for VAT Amount in 'VATAmountLineHandler' handler method.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,PurchaseStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Total Incl. VAT field on Purchase Invoice Statistics before posting Invoice.

        // Setup: Create Purchase Invoice and take 1 for No. of Purchase Line.
        Initialize();
        CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, PurchaseHeader."Document Type"::Invoice);
        ModifyPurchaseHeaderPricesInclVAT(PurchaseHeader, true);

        // Exercise: Open Statistics page from Purchase Invoice.
        LibraryVariableStorage.Enqueue(PurchaseLine."Amount Including VAT");
        OpenPurchaseInvoiceStatistics(PurchaseHeader."No.");

        // Verify: Verification for Total Incl. VAT on Purchase Invoice Statistics page.
        // Verification done in PurchaseStatisticsHandler.
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Total Incl. VAT field on Sales Invoice Statistics before posting Invoice.

        // Setup: Create Sales Invoice and take 1 for No. of Sales Line.
        Initialize();
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);

        // Exercise: Open Statistics page from Sales Invoice.
        LibraryVariableStorage.Enqueue(SalesLine."Amount Including VAT");
        OpenSalesInvoiceStatistics(SalesHeader."No.");

        // Verify: Verification for Total Incl. VAT on Sales Invoice Statistics page.
        // Verification done in SalesStatisticsHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceRounding()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OldInvRoundingPrecision: Decimal;
        DocumentNo: Code[20];
    begin
        // Check Rounding Entries are created after posting Invoice.

        // Setup: Create Sales Invoice.
        Initialize();
        SalesReceivablesSetup.Get();
        OldInvRoundingPrecision := ModifyInvRoundingInGLSetup(LibraryRandom.RandDec(0, 1));
        ModifyInvRoundingInSalesSetup(true, SalesReceivablesSetup."Credit Warnings"::"Both Warnings");
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, true); // Prices Including VAT TRUE to make sure that VAT Amount is not added to the line amount.
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100) + LibraryERM.GetInvoiceRoundingPrecisionLCY / 2); // Make sure invoice rounding entry is needed.
        SalesLine.Validate(Quantity, 2 * LibraryRandom.RandInt(10) + 1); // Make sure quantity is odd so rounding entry is needed.
        SalesLine.Modify(true);
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that Rounding Entry is created after Posting.
        VerifyRoundingEntry(DocumentNo, CustomerPostingGroup."Invoice Rounding Account");

        // Tear Down: Set Default Value in General Ledger Setup, Sales and Receivables Setup for Invoice Rounding.
        ModifyInvRoundingInGLSetup(OldInvRoundingPrecision);
        ModifyInvRoundingInSalesSetup(SalesReceivablesSetup."Invoice Rounding", SalesReceivablesSetup."Credit Warnings");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceCopyDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        BaseAmount: Decimal;
        OldInvRoundingPrecision: Decimal;
        VATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check VAT Entries after posting Sales Invoice which is created using Copy Document report.

        // Setup: Create Sales Invoice and create another Sales Invoice using Copy Document Functionality.
        Initialize();
        SalesReceivablesSetup.Get();
        OldInvRoundingPrecision := ModifyInvRoundingInGLSetup(LibraryRandom.RandDec(0, 1));
        ModifyInvRoundingInSalesSetup(true, SalesReceivablesSetup."Credit Warnings"::"Both Warnings");
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, false);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader2, SalesHeader2."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        RunCopySalesDocument(SalesHeader2, DocumentNo, "Sales Document Type From"::"Posted Invoice", false, true);
        VATAmount := VATAmountCalculation(BaseAmount, SalesHeader2);

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Verify: Verify that VAT Entries are created after Posting.
        VerifyVATAndBaseAmount(
          DocumentNo, SalesLine."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          BaseAmount, VATAmount, VATEntry.Type::Sale);

        // Tear Down: Set Default Value in General Ledger Setup, Sales and Receivables Setup for Invoice Rounding.
        ModifyInvRoundingInGLSetup(OldInvRoundingPrecision);
        ModifyInvRoundingInSalesSetup(SalesReceivablesSetup."Invoice Rounding", SalesReceivablesSetup."Credit Warnings");
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerVatRegistrationNoOnVATEntry()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // Check VAT Registration No. on Vat Entry after posting Sales Invoice.

        // Setup: Find Customer with VAT Registration no. and create sales invoice.
        Initialize();
        CreateSalesInvoiceWithVATRegNo(SalesHeader, Customer);

        // Exercise: Post the sales invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Vat Registration no. on vat entry after posting sales invoice.
        FindVATEntry(VATEntry, DocumentNo, VATEntry.Type::Sale);
        VATEntry.TestField("VAT Registration No.", Customer."VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorVatRegistrationNoOnVATEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // Check VAT Registration No. on Vat Entry after posting Purchase Invoice.

        // Setup: Find Vendor with VAT Registration no. and create purchase invoice.
        Initialize();
        CreatePurchInvoiceWithVATRegNo(PurchaseHeader, Vendor);

        // Exercise: Post the purchase invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Vat Registration no. on vat entry after posting purchase invoice.
        FindVATEntry(VATEntry, DocumentNo, VATEntry.Type::Purchase);
        VATEntry.TestField("VAT Registration No.", Vendor."VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceCopyDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VATEntry: Record "VAT Entry";
        BaseAmount: Decimal;
        VATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check VAT Entries after posting Purchase Invoice which is created using Copy Document report.

        // Setup: Create Purchase Invoice and create another Purchase Invoice using Copy Document Functionality.
        Initialize();
        GeneralLedgerSetup.Get();
        PurchasesPayablesSetup.Get();
        ModifyInvRoundingInGLSetup(LibraryRandom.RandDec(0, 1));
        ModifyInvRoundingInPurchSetup(true);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseLine."Document Type"::Invoice, false);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Another Purchase Invoice created for Copy Document.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader2, PurchaseHeader2."Document Type"::Invoice, PurchaseLine."Buy-from Vendor No.");
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader2, "Purchase Document Type From"::"Posted Invoice", DocumentNo, false, true);
        PurchaseVATAmountCalculation(PurchaseLine, PurchaseHeader2);
        BaseAmount := Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost");
        VATAmount := PurchaseLine."VAT %" * BaseAmount / 100;

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Verify: Verify that VAT Entries are created after Posting.
        VerifyVATAndBaseAmount(
          DocumentNo, PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group",
          BaseAmount, VATAmount, VATEntry.Type::Purchase);

        // Tear Down: Set Default Value in General Ledger Setup, Purchases & Paybles Setup for Invoice Rounding.
        ModifyInvRoundingInGLSetup(GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        ModifyInvRoundingInPurchSetup(PurchasesPayablesSetup."Invoice Rounding");
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchaseHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceCopyDocumentUsingGLAccount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        BaseAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Check VAT Entries after posting Sales Invoice which is created using Copy Document report.

        // Setup: Create Sales Invoice and create another Sales Invoice using Copy Document Functionality.
        Initialize();
        GeneralLedgerSetup.Get();
        SalesReceivablesSetup.Get();
        ModifyInvRoundingInGLSetup(LibraryRandom.RandDec(0, 1));
        ModifyInvRoundingInSalesSetup(true, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, false);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Another Sales Invoice created for Copy Document.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        LibrarySales.CopySalesDocument(SalesHeader2, "Sales Document Type From"::"Posted Invoice", DocumentNo, false, true);
        VATAmount := VATAmountCalculation(BaseAmount, SalesHeader2);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Verify: Verify that VAT Entries are created after Posting.
        VerifyVATAndBaseAmount(
          DocumentNo, SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group", BaseAmount,
          VATAmount, VATEntry.Type::Sale);

        // Tear Down: Set Default Value in General Ledger Setup, Saels & Receivables Setup for Invoice Rounding.
        ModifyInvRoundingInGLSetup(GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        ModifyInvRoundingInSalesSetup(SalesReceivablesSetup."Invoice Rounding", SalesReceivablesSetup."Credit Warnings");
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader2);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckGenBusPostingGroupOnVatEntry()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check that correct Gen. Bus. Posting Group updated on Purchase Header and VAT Entry when Bill To Sell To VAT Calc is Bill To Pay To No.
        Initialize();
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        SetupBillToPayToVATCalc;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckAmountOnCustomerLedgerEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] Payment Customer Ledger Entry is closed and has discounted Invoice Amount Including VAT in case of discount and overdue apply
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Sales Invoice: Amount Including VAT="A", Payment Term Code='1M8D' (Discount Amount = "B"), "Posting Date" = "Document Date" + 40 Days
        // [WHEN] Post Sales Invoice
        PostedInvoiceNo := CreateAndPostSalesInvoiceWithPaymentTermCode(VATPostingSetup, CustomerNo);

        // [THEN] Payment Customer Ledger Entry is Closed and has "Amount (LCY)" = "A" - "B"
        VerifyAmountOnCustomerLedgerEntry(PostedInvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckAmountOnVendLedgerEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Discount]
        // [SCENARIO] Payment Vendor Ledger Entry is closed and has discounted Invoice Amount Including VAT in case of discount and overdue apply
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Purchase Invoice: Amount Including VAT="A", Payment Term Code='1M8D' (Discount Amount = "B"), "Posting Date" = "Document Date" + 40 Days
        // [WHEN] Post Purchase Invoice
        PostedInvoiceNo := CreateAndPostPurchaseInvoiceWithPaymentTermCode(VATPostingSetup, VendorNo);

        // [THEN] Payment Customer Ledger Entry is Closed and has "Amount (LCY)" = "A" - "B"
        VerifyAmountOnVendorLedgerEntry(PostedInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesPricesInclVATtoExclVATWithoutRecalc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewAmount: Decimal;
        NewAmountInclVAT: Decimal;
    begin
        // [FEATURE] [Sales] [Prices Incl. VAT]
        // [SCENARIO 375125] Sales Line has correct Outstanding and Line amounts after switching off "Prices Incl. VAT" without recalculation confirm
        Initialize();

        // [GIVEN] Sales Order with "Prices Incl. VAT" = TRUE, Line Amount = "A", Amount Including VAT = "B"
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, true);
        NewAmount := SalesLine."Amount Including VAT";
        NewAmountInclVAT := Round(NewAmount * (1 + SalesLine."VAT %" / 100));

        // [WHEN] Modify "Prices Incl. VAT" = FALSE without recalculation confirm
        ModifySalesHeaderPricesInclVAT(SalesHeader, false);

        // [THEN] Line Amount = "B"
        // [THEN] Outstanding Amount = Amount Including VAT = "B" * (1 + VAT / 100)
        VerifySalesLineAmounts(SalesLine, NewAmount, NewAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesPricesInclVATtoExclVATWithRecalc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewAmount: Decimal;
        NewAmountInclVAT: Decimal;
    begin
        // [FEATURE] [Sales] [Prices Incl. VAT]
        // [SCENARIO 375125] Sales Line has correct Outstanding and Line amounts after switching off "Prices Incl. VAT" with recalculation confirm
        Initialize();

        // [GIVEN] Sales Order with "Prices Incl. VAT" = TRUE, Line Amount = "A", Amount Including VAT = "B"
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, true);
        NewAmount := SalesLine.Amount;
        NewAmountInclVAT := SalesLine."Amount Including VAT";

        // [WHEN] Modify "Prices Incl. VAT" = FALSE with recalculation confirm
        ModifySalesHeaderPricesInclVAT(SalesHeader, false);

        // [THEN] Line Amount = "A"
        // [THEN] Outstanding Amount = Amount Including VAT = "B"
        VerifySalesLineAmounts(SalesLine, NewAmount, NewAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesPricesExclVATtoInclVATWithoutRecalc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewAmount: Decimal;
        NewAmountInclVAT: Decimal;
    begin
        // [FEATURE] [Sales] [Prices Incl. VAT]
        // [SCENARIO 375125] Sales Line has correct Outstanding and Line amounts after switching on "Prices Incl. VAT" without recalculation confirm
        Initialize();

        // [GIVEN] Sales Order with "Prices Incl. VAT" = FALSE, Line Amount = "A", Amount Including VAT = "B"
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, false);
        NewAmountInclVAT := SalesLine.Amount;
        NewAmount := Round(NewAmountInclVAT / (1 + SalesLine."VAT %" / 100));

        // [WHEN] Modify "Prices Incl. VAT" = TRUE without recalculation confirm
        ModifySalesHeaderPricesInclVAT(SalesHeader, true);

        // [THEN] Line Amount = "A" / (1 + VAT / 100)
        // [THEN] Outstanding Amount = Amount Including VAT = "A"
        VerifySalesLineAmounts(SalesLine, NewAmount, NewAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesPricesExclVATtoInclVATWithRecalc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewAmount: Decimal;
        NewAmountInclVAT: Decimal;
    begin
        // [FEATURE] [Sales] [Prices Incl. VAT]
        // [SCENARIO 375125] Sales Line has correct Outstanding and Line amounts after switching on "Prices Incl. VAT" with recalculation confirm
        Initialize();

        // [GIVEN] Sales Order with "Prices Incl. VAT" = FALSE, Line Amount = "A", Amount Including VAT = "B"
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, false);
        NewAmount := SalesLine.Amount;
        NewAmountInclVAT := SalesLine."Amount Including VAT";

        // [WHEN] Modify "Prices Incl. VAT" = TRUE with recalculation confirm
        ModifySalesHeaderPricesInclVAT(SalesHeader, true);

        // [THEN] Line Amount = "A"
        // [THEN] Outstanding Amount = Amount Including VAT = "B"
        VerifySalesLineAmounts(SalesLine, NewAmount, NewAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchPricesInclVATtoExclVATWithoutRecalc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewAmount: Decimal;
        NewAmountInclVAT: Decimal;
    begin
        // [FEATURE] [Purchases] [Prices Incl. VAT]
        // [SCENARIO 375125] Purchase Line has correct Outstanding and Line amounts after switching off "Prices Incl. VAT" without recalculation confirm
        Initialize();

        // [GIVEN] Purchase Order with "Prices Incl. VAT" = TRUE, Line Amount = "A", Amount Including VAT = "B"
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, true);
        NewAmount := PurchaseLine."Amount Including VAT";
        NewAmountInclVAT := Round(NewAmount * (1 + PurchaseLine."VAT %" / 100));

        // [WHEN] Modify "Prices Incl. VAT" = FALSE without recalculation confirm
        ModifyPurchaseHeaderPricesInclVAT(PurchaseHeader, false);

        // [THEN] Line Amount = "B"
        // [THEN] Outstanding Amount = Amount Including VAT = "B" * (1 + VAT / 100)
        VerifyPurchLineAmounts(PurchaseLine, NewAmount, NewAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchPricesInclVATtoExclVATWithRecalc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewAmount: Decimal;
        NewAmountInclVAT: Decimal;
    begin
        // [FEATURE] [Purchases] [Prices Incl. VAT]
        // [SCENARIO 375125] Purchase Line has correct Outstanding and Line amounts after switching off "Prices Incl. VAT" with recalculation confirm
        Initialize();

        // [GIVEN] Purchase Order with "Prices Incl. VAT" = TRUE, Line Amount = "A", Amount Including VAT = "B"
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, true);
        NewAmount := PurchaseLine.Amount;
        NewAmountInclVAT := PurchaseLine."Amount Including VAT";

        // [WHEN] Modify "Prices Incl. VAT" = FALSE with recalculation confirm
        ModifyPurchaseHeaderPricesInclVAT(PurchaseHeader, false);

        // [THEN] Line Amount = "A"
        // [THEN] Outstanding Amount = Amount Including VAT = "B"
        VerifyPurchLineAmounts(PurchaseLine, NewAmount, NewAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchPricesExclVATtoInclVATWithoutRecalc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewAmount: Decimal;
        NewAmountInclVAT: Decimal;
    begin
        // [FEATURE] [Purchases] [Prices Incl. VAT]
        // [SCENARIO 375125] Purchase Line has correct Outstanding and Line amounts after switching on "Prices Incl. VAT" without recalculation confirm
        Initialize();

        // [GIVEN] Purchase Order with "Prices Incl. VAT" = FALSE, Line Amount = "A", Amount Including VAT = "B"
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, false);
        NewAmountInclVAT := PurchaseLine.Amount;
        NewAmount := Round(NewAmountInclVAT / (1 + PurchaseLine."VAT %" / 100));

        // [WHEN] Modify "Prices Incl. VAT" = TRUE without recalculation confirm
        ModifyPurchaseHeaderPricesInclVAT(PurchaseHeader, true);

        // [THEN] Line Amount = "A" / (1 + VAT / 100)
        // [THEN] Outstanding Amount = Amount Including VAT = "A"
        VerifyPurchLineAmounts(PurchaseLine, NewAmount, NewAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchPricesExclVATtoInclVATWithRecalc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewAmount: Decimal;
        NewAmountInclVAT: Decimal;
    begin
        // [FEATURE] [Purchases] [Prices Incl. VAT]
        // [SCENARIO 375125] Purchase Line has correct Outstanding and Line amounts after switching on "Prices Incl. VAT" with recalculation confirm
        Initialize();

        // [GIVEN] Purchase Order with "Prices Incl. VAT" = FALSE, Line Amount = "A", Amount Including VAT = "B"
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, false);
        NewAmount := PurchaseLine.Amount;
        NewAmountInclVAT := PurchaseLine."Amount Including VAT";

        // [WHEN] Modify "Prices Incl. VAT" = TRUE with recalculation confirm
        ModifyPurchaseHeaderPricesInclVAT(PurchaseHeader, true);

        // [THEN] Line Amount = "A"
        // [THEN] Outstanding Amount = Amount Including VAT = "B"
        VerifyPurchLineAmounts(PurchaseLine, NewAmount, NewAmountInclVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithSevLinesAndRounding()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Rounding]
        // [SCENARIO 375125] Sales Line's Outstanding Amount has correct value in case of several lines rounding
        Initialize();

        // [GIVEN] Sales Order with several lines:
        CreateSalesHeader(SalesHeader, VATPostingSetup, SalesHeader."Document Type"::Order, false);
        LibraryERM.UpdateVATPostingSetup(VATPostingSetup, 25);

        // [GIVEN] VAT = 25%, Quantity = 1, Unit Price = 74.75, Line Discount = 30%
        CreateSalesLineWithCustomAmounts(SalesLine, SalesHeader, VATPostingSetup, 1, 74.75, 30);
        // [GIVEN] VAT = 25%, Quantity = 5, Unit Price = 10.93, Line Discount = 30%
        CreateSalesLineWithCustomAmounts(SalesLine, SalesHeader, VATPostingSetup, 5, 10.93, 30);

        // [WHEN] Add 3rd Sales Line: VAT = 25%, Quantity = 1, Unit Price = 65.16, Line Discount = 30%
        CreateSalesLineWithCustomAmounts(SalesLine, SalesHeader, VATPostingSetup, 1, 65.16, 30);

        // [THEN] 3rd Line Amount = 45.61
        // [THEN] 3rd Line Amount Including VAT = Outstanding Amount = 57.02
        VerifySalesLineAmounts(SalesLine, 45.61, 57.02);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithSevLinesAndRouhding()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchases] [Rounding]
        // [SCENARIO 375125] Purchase Line's Outstanding Amount has correct value in case of several lines rounding
        Initialize();

        // [GIVEN] Sales Order with several lines:
        CreatePurchaseHeader(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Order, false);
        LibraryERM.UpdateVATPostingSetup(VATPostingSetup, 25);

        // [GIVEN] VAT = 25%, Quantity = 1, Direct Unit Cost = 74.75, Line Discount = 30%
        CreatePurchaseLineWithCustomAmounts(PurchaseLine, PurchaseHeader, VATPostingSetup, 1, 74.75, 30);
        // [GIVEN] VAT = 25%, Quantity = 5, Direct Unit Cost = 10.93, Line Discount = 30%
        CreatePurchaseLineWithCustomAmounts(PurchaseLine, PurchaseHeader, VATPostingSetup, 5, 10.93, 30);

        // [WHEN] Add 3rd Sales Line: VAT = 25%, Quantity = 1, Direct Unit Cost = 65.16, Line Discount = 30%
        CreatePurchaseLineWithCustomAmounts(PurchaseLine, PurchaseHeader, VATPostingSetup, 1, 65.16, 30);

        // [THEN] 3rd Line Amount = 45.61
        // [THEN] 3rd Line Amount Including VAT = Outstanding Amount = 57.02
        VerifyPurchLineAmounts(PurchaseLine, 45.61, 57.02);
    end;

    [Test]
    [HandlerFunctions('InvoicingVATAmountSalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure VATAmountOnInvoiceTabSalesOrderPartShipAndInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Statistics]
        // [SCENARIO 376292] VAT Amount should be calculated on Sales order statistics /Invoicing fasttab for remaining quantity when post Sales Order partially Ship then Invoice
        Initialize();

        // [GIVEN] Sales Order with Quantity = 10, Line Amount = 10.000, VAT Amount = 2.500
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Order);

        // [GIVEN] Partially posted Sales Invoice as Ship with QtyToShip = 1, then posted separately as Invoice with QtyToInvoice = 1
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] Open Sales Order Statistics
        LibraryVariableStorage.Enqueue(
          SalesLine."Line Amount" * SalesLine."VAT %" / 100 * SalesLine."Qty. to Ship" / SalesLine.Quantity);
        OpenSalesOrderStatistics(SalesHeader."No.");

        // [THEN] Invoicing tab has VAT Amount for remaining quantity = 2.250 (2.500 * (10 - 1))
        // verification is done in InvoicingVATAmountSalesOrderStatisticsHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCheckNumbersOfLinesLimitNeg()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        RecRef: RecordRef;
        i: Integer;
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 378179] It should be possible to add up too 100 Sales Lines with filled Type and No. and any number of other lines without a "Totals or discounts may not be up-to-date." message

        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        for i := 1 to 110 do begin
            SalesLine.Init();
            SalesLine.Validate("Document Type", SalesHeader."Document Type");
            SalesLine.Validate("Document No.", SalesHeader."No.");
            RecRef.GetTable(SalesLine);
            SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
            SalesLine.Insert(true);
        end;

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);

        Assert.IsTrue(DocumentTotals.SalesCheckNumberOfLinesLimit(SalesHeader), TooManyValuableSalesEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCheckNumbersOfLinesLimitPos()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        i: Integer;
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 378179] It should not be possible to add more than 100 Sales Lines with filled Type and No. without a "Totals or discounts may not be up-to-date." message

        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        for i := 1 to 110 do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);

        Assert.IsFalse(DocumentTotals.SalesCheckNumberOfLinesLimit(SalesHeader), TooManyValuableSalesEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCheckNumbersOfLinesLimitNeg()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        RecRef: RecordRef;
        i: Integer;
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 378179] It should be possible to add up too 100 Purchase Lines with filled Type and No. and any number of other lines without a "Totals or discounts may not be up-to-date." message

        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        for i := 1 to 110 do begin
            PurchaseLine.Init();
            PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
            PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
            RecRef.GetTable(PurchaseLine);
            PurchaseLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PurchaseLine.FieldNo("Line No.")));
            PurchaseLine.Insert(true);
        end;

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, 1);

        Assert.IsTrue(DocumentTotals.PurchaseCheckNumberOfLinesLimit(PurchaseHeader), TooManyValuablePurchaseEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCheckNumbersOfLinesLimitPos()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        i: Integer;
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 378179] It should not be possible to add more than 100 Purchase Lines with filled Type and No. without a "Totals or discounts may not be up-to-date." message

        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        for i := 1 to 110 do
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, 1);

        Assert.IsFalse(DocumentTotals.PurchaseCheckNumberOfLinesLimit(PurchaseHeader), TooManyValuablePurchaseEntriesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingDiffConsideredOnGetTotalVATDiscountOfVATAmountLinePricesExclVAT()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATIdentifier: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255818] TotalVATDiscount calculates with rounding difference by function GetTotalVATDiscount in VAT Amount Line table when "Prices Excluding VAT"

        Initialize();
        VATIdentifier := LibraryUtility.GenerateGUID();
        MockVATAmountLine(TempVATAmountLine, VATIdentifier, 0, 0, 2650.08, 19, 503.51);
        MockVATAmountLine(TempVATAmountLine, VATIdentifier, 0, 0, -93.75, 19, -17.81);

        Assert.AreEqual(0, TempVATAmountLine.GetTotalVATDiscount('', false), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingDiffConsideredOnGetTotalVATDiscountOfVATAmountLinePricesInclVAT()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATIdentifier: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255818] TotalVATDiscount calculates with rounding difference by function GetTotalVATDiscount in VAT Amount Line table when "Prices Including VAT"

        Initialize();
        VATIdentifier := LibraryUtility.GenerateGUID();
        MockVATAmountLine(TempVATAmountLine, VATIdentifier, 2650.08, 230.99, 0, 19, 386.24);
        MockVATAmountLine(TempVATAmountLine, VATIdentifier, -93.75, -2.36, 0, 19, -14.59);

        Assert.AreEqual(0, TempVATAmountLine.GetTotalVATDiscount('', true), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATAmountLinesWithInvoiceRounding()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesPost: Codeunit "Sales-Post";
        InvRoundingAmt: Decimal;
        SalesAmount: Decimal;
        VATPct: Decimal;
        AmountInclVAT: Decimal;
        AmountInclVATRnd: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice Rounding]
        // [SCENARIO 280384] Sales Order with negative and positive VAT amount lines for the same VAT generated with Invoice Rounding
        Initialize();

        // [GIVEN] Invoice Rounging Amount = 0.05
        InvRoundingAmt := 0.05;
        SalesAmount := 3408;
        VATPct := 7.7;
        LibrarySales.SetInvoiceRounding(true);
        UpdateInvoiceRoundingInGLSetup(InvRoundingAmt);

        // [GIVEN] Sales Order of amount = 3408 with VAT % = 7.7 and the same VAT is used in Invoice Rounding G/L Account
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPct);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        UpdateInvoiceRoundingAccCustomer(SalesHeader."Sell-to Customer No.", VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), 1);
        SalesLine.Validate("Unit Price", SalesAmount);
        SalesLine.Modify(true);

        // [GIVEN] Amount Including VAT is 3640.42 = 3408 + 262.42, rounded to 3640.40
        AmountInclVAT := Round(SalesAmount * (1 + VATPct / 100));
        AmountInclVATRnd := Round(SalesAmount * (1 + VATPct / 100), InvRoundingAmt);

        // [WHEN] Calculate VAT Amount Lines
        SalesPost.GetSalesLines(SalesHeader, TempSalesLine, 0);
        SalesLine.CalcVATAmountLines(0, SalesHeader, TempSalesLine, TempVATAmountLine);

        // [THEN] Negative VAT Amount line is created for invoice rounding with VAT Base = -0.02 and VAT Amount = 0
        VerifyVATAmountLine(TempVATAmountLine, false, AmountInclVATRnd - AmountInclVAT, 0);
        // [THEN] Positive VAT Amount is created for the order with VAT Base = 3408 and VAT Amount = 262.42
        VerifyVATAmountLine(TempVATAmountLine, true, SalesAmount, AmountInclVAT - SalesAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseVATAmountLinesWithInvoiceRounding()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PurchPost: Codeunit "Purch.-Post";
        InvRoundingAmt: Decimal;
        PurchaseAmount: Decimal;
        VATPct: Decimal;
        AmountInclVAT: Decimal;
        AmountInclVATRnd: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice Rounding]
        // [SCENARIO 280384] Purchase Order with negative and positive VAT amount lines for the same VAT generated with Invoice Rounding
        Initialize();

        // [GIVEN] Invoice Rounging Amount = 0.05
        InvRoundingAmt := 0.05;
        PurchaseAmount := 3408;
        VATPct := 7.7;
        LibraryPurchase.SetInvoiceRounding(true);
        UpdateInvoiceRoundingInGLSetup(InvRoundingAmt);

        // [GIVEN] Purchase Order of amount = 3408 with VAT % = 7.7 and the same VAT is used in Invoice Rounding G/L Account
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPct);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        UpdateInvoiceRoundingAccVendor(PurchaseHeader."Buy-from Vendor No.", VATPostingSetup."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), 1);
        PurchaseLine.Validate("Direct Unit Cost", PurchaseAmount);
        PurchaseLine.Modify(true);

        // [GIVEN] Amount Including VAT is 3640.42 = 3408 + 262.42, rounded to 3640.40
        AmountInclVAT := Round(PurchaseAmount * (1 + VATPct / 100));
        AmountInclVATRnd := Round(PurchaseAmount * (1 + VATPct / 100), InvRoundingAmt);

        // [WHEN] Calculate VAT Amount Lines
        PurchPost.GetPurchLines(PurchaseHeader, TempPurchaseLine, 0);
        PurchaseLine.CalcVATAmountLines(0, PurchaseHeader, TempPurchaseLine, TempVATAmountLine);

        // [THEN] Negative VAT Amount line is created for invoice rounding with VAT Base = -0.02 and VAT Amount = 0
        VerifyVATAmountLine(TempVATAmountLine, false, AmountInclVATRnd - AmountInclVAT, 0);
        // [THEN] Positive VAT Amount is created for the order with VAT Base = 3408 and VAT Amount = 262.42
        VerifyVATAmountLine(TempVATAmountLine, true, PurchaseAmount, AmountInclVAT - PurchaseAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetQuantityToZeroForNonInsertedSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 294439] Stan changes Quantity from 10 to 0 for Sales Line, that is not inserted yet.
        Initialize();

        // [GIVEN] Sales Invoice with Sales Line "SL". Sales Line is not inserted and has non-zero Quantity.
        LibrarySales.CreateSalesInvoice(SalesHeader);
        CreateSalesLineWithoutInsert(SalesLine, SalesHeader);

        // [WHEN] Set Quantity to 0.
        SalesLine.Validate(Quantity, 0);

        // [THEN] MODIFY is not invoked for "SL". Quantity is changed to 0.
        SalesLine.TestField(Quantity, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetQuantityToZeroForInsertedSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 294439] Stan changes Quantity from 10 to 0 for inserted Sales Line.
        Initialize();

        // [GIVEN] Sales Invoice with Sales Line "SL". Sales Line is inserted and has non-zero Quantity.
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        // [WHEN] Set Quantity to 0.
        SalesLine.Validate(Quantity, 0);

        // [THEN] Quantity is modified for "SL".
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField(Quantity, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetQuantityToZeroForNonInsertedPurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 294439] Stan changes Quantity from 10 to 0 for Purchase Line, that is not inserted yet.
        Initialize();

        // [GIVEN] Purchase Invoice with Purchase Line "PL". Purchase Line is not inserted and has non-zero Quantity.
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        CreatePurchaseLineWithoutInsert(PurchaseLine, PurchaseHeader);

        // [WHEN] Set Quantity to 0.
        PurchaseLine.Validate(Quantity, 0);

        // [THEN] MODIFY is not invoked for "PL". Quantity is changed to 0.
        PurchaseLine.TestField(Quantity, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetQuantityToZeroForInsertedPurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 294439] Stan changes Quantity from 10 to 0 for inserted Purchase Line.
        Initialize();

        // [GIVEN] Purchase Invoice with Purchase Line "PL". Purchase Line is inserted and has non-zero Quantity.
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);

        // [WHEN] Set Quantity to 0.
        PurchaseLine.Validate(Quantity, 0);

        // [THEN] Quantity is modified for "PL".
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.TestField(Quantity, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineAmountIncludingVATWithDifferentVATCalculationTypes()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: array[2] of Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPercent: Decimal;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 328781] "Amount Including VAT" is calculated correctly when there's two VAT Posting Setups with the same "VAT Identifier" but different VAT Calculation Types.
        Initialize();

        // [GIVEN] VAT Posting Setups "V1"/"V2" with different VAT Prod. Post. Groups, "VAT %" = 10, "VAT Identifier" = "VAT10" and VAT Calculation Type = "Normal VAT"/"Reverse Charge VAT".
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[1]);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[2]);
        VATPercent := LibraryRandom.RandIntInRange(10, 20);
        CreateVATPostingSetup(
          VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup[1].Code,
          VATPercent, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateVATPostingSetup(
          VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup[2].Code,
          VATPercent, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] G/L Account.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup[1].Code);
        GLAccount.Modify(true);

        // [GIVEN] Sales Order with two Sales Lines "S1"/"S2" with "Unit Price" = "100"/"200", "VAT Prod. Post. Group" = "V1"/"V2".
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusinessPostingGroup.Code));
        CreateSalesLineWithUnitPriceAndVATProdPstGroup(
          SalesLine[1], SalesHeader, VATProductPostingGroup[1].Code,
          SalesLine[1].Type::"G/L Account", GLAccount."No.", 0, LibraryRandom.RandIntInRange(1000, 1500));
        CreateSalesLineWithUnitPriceAndVATProdPstGroup(
          SalesLine[2], SalesHeader, VATProductPostingGroup[2].Code,
          SalesLine[2].Type::"G/L Account", GLAccount."No.", 1, LibraryRandom.RandIntInRange(1000, 1500));

        // [WHEN] Sales Line "S1" Quantity is validated with 1.
        SalesLine[1].Validate(Quantity, 1);

        // [THEN] "S1" "Amount Including VAT" is equal to 100 * (1 + 10 / 100) = 110.
        Assert.AreEqual(SalesLine[1]."Unit Price" * (1 + VATPercent / 100), SalesLine[1]."Amount Including VAT", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineAmountIncludingVATWithDifferentVATCalculationTypes()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: array[2] of Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPercent: Decimal;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 328781] "Amount Including VAT" is calculated correctly when there's two VAT Posting Setups with the same "VAT Identifier" but different VAT Calculation Types.
        Initialize();

        // [GIVEN] VAT Posting Setups "V1"/"V2" with different VAT Prod. Post. Groups, "VAT %" = 10, "VAT Identifier" = "VAT10" and VAT Calculation Type = "Normal VAT"/"Reverse Charge VAT".
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[1]);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup[2]);
        VATPercent := LibraryRandom.RandIntInRange(10, 20);
        CreateVATPostingSetup(
          VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup[1].Code,
          VATPercent, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateVATPostingSetup(
          VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup[2].Code,
          VATPercent, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] G/L Account.
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup[1].Code);
        GLAccount.Modify(true);

        // [GIVEN] Purchase Order with two Purchase Lines "P1"/"P2" with "Unit Price" = "100"/"200", "VAT Prod. Post. Group" = "V1"/"V2".
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup.Code));
        CreatePurchaseLineWithUnitPriceAndVATProdPstGroup(
          PurchaseLine[1], PurchaseHeader, VATProductPostingGroup[1].Code,
          PurchaseLine[1].Type::"G/L Account", GLAccount."No.", 0, LibraryRandom.RandIntInRange(1000, 1500));
        CreatePurchaseLineWithUnitPriceAndVATProdPstGroup(
          PurchaseLine[2], PurchaseHeader, VATProductPostingGroup[2].Code,
          PurchaseLine[2].Type::"G/L Account", GLAccount."No.", 1, LibraryRandom.RandIntInRange(1000, 1500));

        // [WHEN] Purchase Line "P1" Quantity is validated with 1.
        PurchaseLine[1].Validate(Quantity, 1);

        // [THEN] "S1" "Amount Including VAT" is equal to 100 * (1 + 10 / 100) = 110.
        Assert.AreEqual(PurchaseLine[1]."Direct Unit Cost" * (1 + VATPercent / 100), PurchaseLine[1]."Amount Including VAT", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATAmountLinesWithInvoiceRounding_PartialInvoicing()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        InvoiceRoundingGLAccount: Record "G/L Account";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesPost: Codeunit "Sales-Post";
        InvRoundingAmt: Decimal;
        LineAmount: array[2] of Decimal;
        VATPct: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Invoice Rounding]
        // [SCENARIO 330283] Sales Order with partial invoicing and manually added line with invoice rounding account shows correct statistics.
        Initialize();

        InvRoundingAmt := 0.01;
        LineAmount[1] := 221;
        LineAmount[2] := 0.45;
        VATPct[1] := 25;
        VATPct[2] := 10;

        LibrarySales.SetInvoiceRounding(true);
        UpdateInvoiceRoundingInGLSetup(InvRoundingAmt);

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", VATPct[1]);

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup[2] := VATPostingSetup[1];
        VATPostingSetup[2]."VAT Identifier" := LibraryUtility.GenerateGUID();
        VATPostingSetup[2]."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup[2]."VAT %" := VATPct[2];
        VATPostingSetup[2].Insert();

        InvoiceRoundingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup);
        InvoiceRoundingGLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup[2]."VAT Prod. Posting Group");
        InvoiceRoundingGLAccount.Modify(true);

        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group"));
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate("Invoice Rounding Account", InvoiceRoundingGLAccount."No.");
        CustomerPostingGroup.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        LibrarySales.CreateSalesLine(
          SalesLine[1], SalesHeader, SalesLine[1].Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup[1]."VAT Prod. Posting Group"), 2);
        SalesLine[1].Validate("Unit Price", LineAmount[1]);
        SalesLine[1].Validate("Qty. to Ship", 1);
        SalesLine[1].Modify(true);

        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::"G/L Account", InvoiceRoundingGLAccount."No.", 1);
        SalesLine[2].Validate("Unit Price", LineAmount[2]);
        SalesLine[2].Modify(true);

        SalesPost.GetSalesLines(SalesHeader, TempSalesLine, 0);
        SalesLine[1].CalcVATAmountLines(1, SalesHeader, TempSalesLine, TempVATAmountLine);

        VerifyVATAmountLinePerGroup(
          TempVATAmountLine,
          VATPostingSetup[1]."VAT Identifier",
          LineAmount[1],
          Round(LineAmount[1] * VATPct[1] / 100));
        VerifyVATAmountLinePerGroup(
          TempVATAmountLine,
          VATPostingSetup[2]."VAT Identifier",
          LineAmount[2],
          Round(LineAmount[2] * VATPct[2] / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseVATAmountLinesWithInvoiceRounding_PartialInvoicing()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        InvoiceRoundingGLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PurchPost: Codeunit "Purch.-Post";
        InvRoundingAmt: Decimal;
        LineAmount: array[2] of Decimal;
        VATPct: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice Rounding]
        // [SCENARIO 330283] Purchase Order with partial invoicing and manually added line with invoice rounding account shows correct statistics.
        Initialize();

        InvRoundingAmt := 0.01;
        LineAmount[1] := 221;
        LineAmount[2] := 0.45;
        VATPct[1] := 25;
        VATPct[2] := 10;

        LibrarySales.SetInvoiceRounding(true);
        UpdateInvoiceRoundingInGLSetup(InvRoundingAmt);

        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", VATPct[1]);

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup[2] := VATPostingSetup[1];
        VATPostingSetup[2]."VAT Identifier" := LibraryUtility.GenerateGUID();
        VATPostingSetup[2]."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup[2]."VAT %" := VATPct[2];
        VATPostingSetup[2].Insert();

        InvoiceRoundingGLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup);
        InvoiceRoundingGLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup[2]."VAT Prod. Posting Group");
        InvoiceRoundingGLAccount.Modify(true);

        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group"));
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VendorPostingGroup.Validate("Invoice Rounding Account", InvoiceRoundingGLAccount."No.");
        VendorPostingGroup.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup[1]."VAT Prod. Posting Group"), 4);
        PurchaseLine[1].Validate("Direct Unit Cost", LineAmount[1]);
        PurchaseLine[1].Validate("Qty. to Receive", 2);
        PurchaseLine[1].Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::"G/L Account", InvoiceRoundingGLAccount."No.", 1);
        PurchaseLine[2].Validate("Direct Unit Cost", LineAmount[2]);
        PurchaseLine[2].Modify(true);

        PurchPost.GetPurchLines(PurchaseHeader, TempPurchaseLine, 0);
        PurchaseLine[1].CalcVATAmountLines(1, PurchaseHeader, TempPurchaseLine, TempVATAmountLine);

        VerifyVATAmountLinePerGroup(
          TempVATAmountLine,
          VATPostingSetup[1]."VAT Identifier",
          LineAmount[1] * 2,
          Round(LineAmount[1] * 2 * VATPct[1] / 100));
        VerifyVATAmountLinePerGroup(
          TempVATAmountLine,
          VATPostingSetup[2]."VAT Identifier",
          LineAmount[2],
          Round(LineAmount[2] * VATPct[2] / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReverseChargeVATEntriesAmounts()
    var
        GLAccount: array[2] of Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT]
        // [SCENARIO 377909] Posting Purchase Order with Reverse Charge VAT creates VAT entries with expected amounts.
        Initialize();

        // [GIVEN] VAT Posting Setups "V" with "VAT %" = 23 and VAT Calculation Type = "Reverse Charge VAT".
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        // [GIVEN] G/L Accounts "G1"/"G2".
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount[1]);
        GLAccount[1].Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount[1].Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount[1].Modify(true);
        LibraryERM.CreateGLAccount(GLAccount[2]);
        GLAccount[2].Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount[2].Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount[2].Modify(true);

        // [GIVEN] Purchase Order with two Purchase Lines with "Unit Price" = "25.8"/"25.8", "VAT Prod. Post. Group" = "V", "No." = "G1"/"G2".
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorWithBusPostingGroups(
                GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchaseLineWithUnitPriceAndVATProdPstGroup(
            PurchaseLine, PurchaseHeader,
            VATPostingSetup."VAT Prod. Posting Group", PurchaseLine.Type::"G/L Account", GLAccount[1]."No.", 1, 25.8);
        CreatePurchaseLineWithUnitPriceAndVATProdPstGroup(
            PurchaseLine, PurchaseHeader,
            VATPostingSetup."VAT Prod. Posting Group", PurchaseLine.Type::"G/L Account", GLAccount[2]."No.", 1, 25.8);

        // [WHEN] Purchase Order is posted.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Two VAT entries created with Amount = "5.93"/"5.94".
        VATEntry.SetRange("Bill-to/Pay-to No.", PurchaseHeader."Buy-from Vendor No.");
        VATEntry.SetFilter(Amount, '5.93');
        Assert.RecordIsNotEmpty(VATEntry);
        VATEntry.SetFilter(Amount, '5.94');
        Assert.RecordIsNotEmpty(VATEntry);
    end;

    [Test]
    procedure VATDateReturnsCorrectBasedOnGLSetup()
    var
        GLSetup: Record "General Ledger Setup";
        PostingDate, DocumentDate, VATDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 431931] GL Setup returns correct date based on GL Setup setting
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();
        PostingDate := WorkDate();
        DocumentDate := WorkDate() + 1;

        // [Then] VAT Date equal to posting date 
        VATDate := GLSetup.GetVATDate(PostingDate, DocumentDate);
        Assert.AreEqual(PostingDate, VATDate, VatDateComparisonErr);
        Assert.AreNotEqual(DocumentDate, VATDate, VatDateComparisonErr);
    end;

    [Test]
    procedure VATDateReturnsCorrectBasedOnGLSetup2()
    var
        GLSetup: Record "General Ledger Setup";
        PostingDate, DocumentDate, VATDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 431931] GL Setup returns correct date based on GL Setup setting
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] VAT Date is updated to be equal to posting date 
        PostingDate := WorkDate();
        GLSetup.UpdateVATDate(PostingDate, Enum::"VAT Reporting Date"::"Posting Date", VATDate);
        Assert.AreEqual(VATDate, PostingDate, VatDateComparisonErr);

        // [Then] VAT Date is not updated to be equal to document date 
        DocumentDate := 0D;
        GLSetup.UpdateVATDate(DocumentDate, Enum::"VAT Reporting Date"::"Document Date", VATDate);
        Assert.AreNotEqual(VATDate, DocumentDate, VatDateComparisonErr);
        Assert.AreEqual(0D, DocumentDate, VatDateComparisonErr);
    end;

    [Test]
    procedure TestVATDateChangesOnSalesInvoice()
    var
        GLSetup: Record "General Ledger Setup";
        SalesInvoice: TestPage "Sales Invoice";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        SalesInvoice.OpenEdit();
        SalesInvoice."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        SalesInvoice."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, SalesInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        SalesInvoice."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        SalesInvoice."Posting Date".SetValue(WorkDate());
        SalesInvoice."Document Date".SetValue(WorkDate() + 1);
        SalesInvoice."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, SalesInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        SalesInvoice.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        SalesInvoice.OpenEdit();
        SalesInvoice."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date, due to Posting Date -> Document Date -> VAT date
        SalesInvoice."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, SalesInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        SalesInvoice."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        SalesInvoice."Posting Date".SetValue(WorkDate());
        SalesInvoice."Document Date".SetValue(WorkDate() + 1);
        SalesInvoice."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, SalesInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        SalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestVATDateChangesOnPurchaseInvoice()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseInvoice: TestPage "Purchase Invoice";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        PurchaseInvoice."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, PurchaseInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        PurchaseInvoice."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        PurchaseInvoice."Posting Date".SetValue(WorkDate());
        PurchaseInvoice."Document Date".SetValue(WorkDate() + 1);
        PurchaseInvoice."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, PurchaseInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        PurchaseInvoice.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date, due to Posting Date -> Document Date -> VAT date
        PurchaseInvoice."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, PurchaseInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        PurchaseInvoice."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        PurchaseInvoice."Posting Date".SetValue(WorkDate());
        PurchaseInvoice."Document Date".SetValue(WorkDate() + 1);
        PurchaseInvoice."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, PurchaseInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        PurchaseInvoice.Close();
    end;

    [Test]
    procedure TestVATDateChangesOnServiceInvoice()
    var
        GLSetup: Record "General Ledger Setup";
        ServiceInvoice: TestPage "Service Invoice";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        ServiceInvoice.OpenEdit();
        ServiceInvoice."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        ServiceInvoice."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, ServiceInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        ServiceInvoice."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        ServiceInvoice."Posting Date".SetValue(WorkDate());
        ServiceInvoice."Document Date".SetValue(WorkDate() + 1);
        ServiceInvoice."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, ServiceInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        ServiceInvoice.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        ServiceInvoice.OpenEdit();
        ServiceInvoice."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date, due to Posting Date -> Document Date -> VAT date
        ServiceInvoice."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, ServiceInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        ServiceInvoice."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        ServiceInvoice."Posting Date".SetValue(WorkDate());
        ServiceInvoice."Document Date".SetValue(WorkDate() + 1);
        ServiceInvoice."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, ServiceInvoice."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        ServiceInvoice.Close();
    end;

    [Test]
    procedure TestVATDateChangesOnFinanceChargeMemo()
    var
        GLSetup: Record "General Ledger Setup";
        FinanceChargeMemo: TestPage "Finance Charge Memo";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        FinanceChargeMemo.OpenNew();
        FinanceChargeMemo."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, FinanceChargeMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        FinanceChargeMemo."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, FinanceChargeMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        FinanceChargeMemo."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, FinanceChargeMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        FinanceChargeMemo."Posting Date".SetValue(WorkDate());
        FinanceChargeMemo."Document Date".SetValue(WorkDate() + 1);
        FinanceChargeMemo."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, FinanceChargeMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        FinanceChargeMemo.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        FinanceChargeMemo.OpenNew();
        FinanceChargeMemo."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, FinanceChargeMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, but VAT Date is not
        FinanceChargeMemo."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, FinanceChargeMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        FinanceChargeMemo."Document Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, FinanceChargeMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        FinanceChargeMemo."Posting Date".SetValue(WorkDate());
        FinanceChargeMemo."Document Date".SetValue(WorkDate() + 1);
        FinanceChargeMemo."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, FinanceChargeMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        FinanceChargeMemo.Close();
    end;

    [Test]
    procedure TestVATDateChangesOnPurchaseCreditMemo()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice    
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        PurchaseCreditMemo."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, PurchaseCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        PurchaseCreditMemo."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        PurchaseCreditMemo."Posting Date".SetValue(WorkDate());
        PurchaseCreditMemo."Document Date".SetValue(WorkDate() + 1);
        PurchaseCreditMemo."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, PurchaseCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        PurchaseCreditMemo.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, then VAT date is also, due to Posting Date -> Document Date -> VAT date
        PurchaseCreditMemo."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, PurchaseCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        PurchaseCreditMemo."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        PurchaseCreditMemo."Posting Date".SetValue(WorkDate());
        PurchaseCreditMemo."Document Date".SetValue(WorkDate() + 1);
        PurchaseCreditMemo."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, PurchaseCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        PurchaseCreditMemo.Close();
    end;

    [Test]
    procedure TestVATDateChangesOnPurchaseOrder()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseOrder: TestPage "Purchase Order";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        PurchaseOrder.OpenEdit();
        PurchaseOrder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        PurchaseOrder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, PurchaseOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        PurchaseOrder."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        PurchaseOrder."Posting Date".SetValue(WorkDate());
        PurchaseOrder."Document Date".SetValue(WorkDate() + 1);
        PurchaseOrder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, PurchaseOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        PurchaseOrder.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        PurchaseOrder.OpenEdit();
        PurchaseOrder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, then VAT date is also, due to Posting Date -> Document Date -> VAT date
        PurchaseOrder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, PurchaseOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        PurchaseOrder."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        PurchaseOrder."Posting Date".SetValue(WorkDate());
        PurchaseOrder."Document Date".SetValue(WorkDate() + 1);
        PurchaseOrder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, PurchaseOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        PurchaseOrder.Close();
    end;

    [Test]
    procedure TestVATDateChangesOnPurchaseReturnOrder()
    var
        GLSetup: Record "General Ledger Setup";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        PurchaseReturnOrder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, PurchaseReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        PurchaseReturnOrder."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        PurchaseReturnOrder."Posting Date".SetValue(WorkDate());
        PurchaseReturnOrder."Document Date".SetValue(WorkDate() + 1);
        PurchaseReturnOrder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, PurchaseReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        PurchaseReturnOrder.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date, due to Posting Date -> Document Date -> VAT date
        PurchaseReturnOrder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, PurchaseReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        PurchaseReturnOrder."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, PurchaseReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        PurchaseReturnOrder."Posting Date".SetValue(WorkDate());
        PurchaseReturnOrder."Document Date".SetValue(WorkDate() + 1);
        PurchaseReturnOrder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, PurchaseReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        PurchaseReturnOrder.Close();
    end;

    [Test]
    procedure TestVATDateChangesOnRecurringGeneralJournal()
    var
        GLSetup: Record "General Ledger Setup";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        RecurringGeneralJournal.OpenEdit();
        RecurringGeneralJournal."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, RecurringGeneralJournal."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        RecurringGeneralJournal."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, RecurringGeneralJournal."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        RecurringGeneralJournal."Posting Date".SetValue(WorkDate());
        RecurringGeneralJournal."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is set to posting date
        Evaluate(FieldDate, RecurringGeneralJournal."VAT Reporting Date".Value);
        Assert.AreEqual(WorkDate(), FieldDate, VatDateComparisonErr);
        RecurringGeneralJournal.Close();
    end;

    [Test]
    procedure TestVATDateChangesOnReminder()
    var
        GLSetup: Record "General Ledger Setup";
        Reminder: TestPage "Reminder";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        Reminder.OpenNew();
        Reminder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, Reminder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        Reminder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, Reminder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        Reminder."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, Reminder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        Reminder."Posting Date".SetValue(WorkDate());
        Reminder."Document Date".SetValue(WorkDate() + 1);
        Reminder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, Reminder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        Reminder.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        Reminder.OpenNew();
        Reminder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, Reminder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, VAT Date is not
        Reminder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, Reminder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        Reminder."Document Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, Reminder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        Reminder."Posting Date".SetValue(WorkDate());
        Reminder."Document Date".SetValue(WorkDate() + 1);
        Reminder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, Reminder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        Reminder.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestVATDateChangesOnSalesCreditMemo()
    var
        GLSetup: Record "General Ledger Setup";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        SalesCreditMemo."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, SalesCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        SalesCreditMemo."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        SalesCreditMemo."Posting Date".SetValue(WorkDate());
        SalesCreditMemo."Document Date".SetValue(WorkDate() + 1);
        SalesCreditMemo."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, SalesCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        SalesCreditMemo.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date, due to Posting Date -> Document Date -> VAT date
        SalesCreditMemo."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, SalesCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        SalesCreditMemo."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        SalesCreditMemo."Posting Date".SetValue(WorkDate());
        SalesCreditMemo."Document Date".SetValue(WorkDate() + 1);
        SalesCreditMemo."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, SalesCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        SalesCreditMemo.Close();
    end;

    [Test]
    procedure TestVATDateChangesOnSalesOrder()
    var
        GLSetup: Record "General Ledger Setup";
        SalesOrder: TestPage "Sales Order";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        SalesOrder.OpenEdit();
        SalesOrder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        SalesOrder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, SalesOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        SalesOrder."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        SalesOrder."Posting Date".SetValue(WorkDate());
        SalesOrder."Document Date".SetValue(WorkDate() + 1);
        SalesOrder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, SalesOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        SalesOrder.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        SalesOrder.OpenEdit();
        SalesOrder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date, due to Posting Date -> Document Date -> VAT date
        SalesOrder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, SalesOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        SalesOrder."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        SalesOrder."Posting Date".SetValue(WorkDate());
        SalesOrder."Document Date".SetValue(WorkDate() + 1);
        SalesOrder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, SalesOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        SalesOrder.Close();
    end;

    [Test]
    procedure TestVATDateChangesOnSalesReturnOrder()
    var
        GLSetup: Record "General Ledger Setup";
        SalesReturnOrder: TestPage "Sales Return Order";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        SalesReturnOrder.OpenNew();
        SalesReturnOrder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        SalesReturnOrder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, SalesReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        SalesReturnOrder."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        SalesReturnOrder."Posting Date".SetValue(WorkDate());
        SalesReturnOrder."Document Date".SetValue(WorkDate() + 1);
        SalesReturnOrder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, SalesReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        SalesReturnOrder.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        SalesReturnOrder.OpenNew();
        SalesReturnOrder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date, due to Posting Date -> Document Date -> VAT date
        SalesReturnOrder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, SalesReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        SalesReturnOrder."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, SalesReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        SalesReturnOrder."Posting Date".SetValue(WorkDate());
        SalesReturnOrder."Document Date".SetValue(WorkDate() + 1);
        SalesReturnOrder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, SalesReturnOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        SalesReturnOrder.Close();
    end;

    [Test]
    procedure TestVATDateChangesOnServiceCreditMemo()
    var
        GLSetup: Record "General Ledger Setup";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        ServiceCreditMemo.OpenNew();
        ServiceCreditMemo."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        ServiceCreditMemo."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, ServiceCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        ServiceCreditMemo."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        ServiceCreditMemo."Posting Date".SetValue(WorkDate());
        ServiceCreditMemo."Document Date".SetValue(WorkDate() + 1);
        ServiceCreditMemo."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, ServiceCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        ServiceCreditMemo.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        ServiceCreditMemo.OpenNew();
        ServiceCreditMemo."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date, due to Posting Date -> Document Date -> VAT date
        ServiceCreditMemo."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, ServiceCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        ServiceCreditMemo."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        ServiceCreditMemo."Posting Date".SetValue(WorkDate());
        ServiceCreditMemo."Document Date".SetValue(WorkDate() + 1);
        ServiceCreditMemo."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, ServiceCreditMemo."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        ServiceCreditMemo.Close();
    end;

    [Test]
    procedure TestVATDateChangesOnServiceOrder()
    var
        GLSetup: Record "General Ledger Setup";
        ServiceOrder: TestPage "Service Order";
        FieldDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445587] VAT Date should reflect Document date or Posting Date
        Initialize();

        // [When] Setting GL Setup to use posting date
        GLSetup.Get();
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Posting Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        ServiceOrder.OpenEdit();
        ServiceOrder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date
        ServiceOrder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, ServiceOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is not
        ServiceOrder."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        ServiceOrder."Posting Date".SetValue(WorkDate());
        ServiceOrder."Document Date".SetValue(WorkDate() + 1);
        ServiceOrder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to posting date
        Evaluate(FieldDate, ServiceOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);
        ServiceOrder.Close();

        // [When] Setting GL Setup to use posting date
        GLSetup."VAT Reporting Date" := GLSetup."VAT Reporting Date"::"Document Date";
        GLSetup.Modify();

        // [Then] Open Sales invoice
        ServiceOrder.OpenEdit();
        ServiceOrder."VAT Reporting Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [Then] Posting Date is changed, so should VAT Date, due to Posting Date -> Document Date -> VAT date
        ServiceOrder."Posting Date".SetValue(WorkDate() + 1);
        Evaluate(FieldDate, ServiceOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);

        // [Then] Document Date is changed, VAT Date is changed
        ServiceOrder."Document Date".SetValue(WorkDate());
        Evaluate(FieldDate, ServiceOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate(), VatDateComparisonErr);

        // [When] VAT date value is cleared in UI
        ServiceOrder."Posting Date".SetValue(WorkDate());
        ServiceOrder."Document Date".SetValue(WorkDate() + 1);
        ServiceOrder."VAT Reporting Date".SetValue(0D);

        // [Then] VAT Date is to document date
        Evaluate(FieldDate, ServiceOrder."VAT Reporting Date".Value);
        Assert.AreEqual(FieldDate, WorkDate() + 1, VatDateComparisonErr);
        ServiceOrder.Close();
    end;

    [Test]
    procedure TestVATDateAdjustedOnVATEntryOnSalesInvHeader()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        DocNo: Code[20];
        VATDate, NewVATDate: Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445818] When adjusting VAT Date, it should reflect in related documents
        Initialize();

        // [WHEN] Posting sales invoice 
        DocType := Enum::"Gen. Journal Document Type"::Invoice;
        PostType := Enum::"General Posting Type"::Sale;
        DocNo := CreateAndPostSalesDoc(0D, DocType);
        SalesInvHeader.Get(DocNo);

        // [THEN] Verify that VAT is set on related docs
        VATDate := SalesInvHeader."VAT Reporting Date";
        VATEntryNo := VerifyVATEntry(DocNo, DocType, PostType, VATDate);
        VerifyGLEntry(DocNo, DocType, PostType, VATDate);

        // [WHEN] Adjusting VAT Date
        NewVATDate := VATDate + 1;
        CorrectVATDateAndVerifyChange(VATEntryNo, NewVATDate);

        // [THEN] Verify Update on related docs
        VerifyVATEntry(DocNo, DocType, PostType, NewVATDate);
        VerifyGLEntry(DocNo, DocType, PostType, NewVATDate);
        SalesInvHeader.Get(DocNo);
        Assert.AreEqual(NewVATDate, SalesInvHeader."VAT Reporting Date", VATDateOnRecordErr);
    end;

    [Test]
    procedure TestVATDateAdjustedOnVATEntryOnPurchInvHeader()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        DocNo: Code[20];
        VATDate, NewVATDate: Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445818] When adjusting VAT Date, it should reflect in related documents
        Initialize();

        // [WHEN] Posting purchase invoice 
        DocType := Enum::"Gen. Journal Document Type"::Invoice;
        PostType := Enum::"General Posting Type"::Purchase;
        DocNo := CreateAndPostPurchDoc(0D, DocType);
        PurchInvHeader.Get(DocNo);

        // [THEN] Verify that VAT is set on related docs
        VATDate := PurchInvHeader."VAT Reporting Date";
        VATEntryNo := VerifyVATEntry(DocNo, DocType, PostType, VATDate);
        VerifyGLEntry(DocNo, DocType, PostType, VATDate);

        // [WHEN] Adjusting VAT Date
        NewVATDate := VATDate + 1;
        CorrectVATDateAndVerifyChange(VATEntryNo, NewVATDate);

        // [THEN] Verify Update on related docs
        VerifyVATEntry(DocNo, DocType, PostType, NewVATDate);
        VerifyGLEntry(DocNo, DocType, PostType, NewVATDate);
        PurchInvHeader.Get(DocNo);
        Assert.AreEqual(NewVATDate, PurchInvHeader."VAT Reporting Date", VATDateOnRecordErr);
    end;

    [Test]
    procedure TestVATDateAdjustedOnVATEntryOnSalesCreditMemoInvHeader()
    var
        DocHeader: Record "Sales Cr.Memo Header";
        DocNo: Code[20];
        VATDate, NewVATDate: Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445818] When adjusting VAT Date, it should reflect in related documents
        Initialize();

        // [WHEN] Posting Sales Credit Memo  
        DocType := Enum::"Gen. Journal Document Type"::"Credit Memo";
        PostType := Enum::"General Posting Type"::Sale;
        DocNo := CreateAndPostSalesDoc(0D, DocType);
        DocHeader.Get(DocNo);

        // [THEN] Verify that VAT is set on related docs
        VATDate := DocHeader."VAT Reporting Date";
        VATEntryNo := VerifyVATEntry(DocNo, DocType, PostType, VATDate);
        VerifyGLEntry(DocNo, DocType, PostType, VATDate);

        // [WHEN] Adjusting VAT Date
        NewVATDate := VATDate + 1;
        CorrectVATDateAndVerifyChange(VATEntryNo, NewVATDate);

        // [THEN] Verify Update on related docs
        VerifyVATEntry(DocNo, DocType, PostType, NewVATDate);
        VerifyGLEntry(DocNo, DocType, PostType, NewVATDate);
        DocHeader.Get(DocNo);
        Assert.AreEqual(NewVATDate, DocHeader."VAT Reporting Date", VATDateOnRecordErr);
    end;

    [Test]
    procedure TestVATDateAdjustedOnVATEntryOnPurchCreditMemoInvHeader()
    var
        DocHeader: Record "Purch. Cr. Memo Hdr.";
        DocNo: Code[20];
        VATDate, NewVATDate: Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 445818] When adjusting VAT Date, it should reflect in related documents
        Initialize();

        // [WHEN] Posting Purchase Credit memo  
        DocType := Enum::"Gen. Journal Document Type"::"Credit Memo";
        PostType := Enum::"General Posting Type"::Purchase;
        DocNo := CreateAndPostPurchDoc(0D, DocType);
        DocHeader.Get(DocNo);

        // [THEN] Verify that VAT is set on related docs
        VATDate := DocHeader."VAT Reporting Date";
        VATEntryNo := VerifyVATEntry(DocNo, DocType, PostType, VATDate);
        VerifyGLEntry(DocNo, DocType, PostType, VATDate);

        // [WHEN] Adjusting VAT Date
        NewVATDate := VATDate + 1;
        CorrectVATDateAndVerifyChange(VATEntryNo, NewVATDate);

        // [THEN] Verify Update on related docs
        VerifyVATEntry(DocNo, DocType, PostType, NewVATDate);
        VerifyGLEntry(DocNo, DocType, PostType, NewVATDate);
        DocHeader.Get(DocNo);
        Assert.AreEqual(NewVATDate, DocHeader."VAT Reporting Date", VATDateOnRecordErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,MessageHandler')]
    procedure TestVATDateWhenArchiveSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 126493] When adjusting VAT Date, it should reflect in related documents
        Initialize();

        // [GIVEN] Create sales order
        CreateSalesDocument(SalesHeader, SalesLine, Enum::"Sales Document Type"::Order, false);
        SalesHeader."VAT Reporting Date" := WorkDate() + 1;
        SalesHeader.Modify();

        // [WHEN] Document is archived
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst();

        // [THEN] Archived date is equal to sales header
        Assert.AreEqual(SalesHeader."VAT Reporting Date", SalesHeaderArchive."VAT Reporting Date", VATDateErr);

        // [GIVEN] VAT date is changed on Sales Header
        SalesHeader."VAT Reporting Date" := WorkDate();
        SalesHeader.Modify();

        // [WHEN] Document is restored
        ArchiveManagement.RestoreSalesDocument(SalesHeaderArchive);
        SalesHeader.SetRange("Document Type", SalesHeaderArchive."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesHeaderArchive."No.");
        SalesHeader.FindFirst();

        // [THEN] VAT Date is set to VAT date on archived version
        Assert.AreEqual(SalesHeaderArchive."VAT Reporting Date", SalesHeader."VAT Reporting Date", VATDateErr);
    end;

    [Test]
    procedure TestVATEntryAdjustDateWithEmptyDocType()
    var
        DocHeader: Record "Sales Invoice Header";
        VATEntry: Record "VAT Entry";
        DocNo: Code[20];
        VATDate, NewVATDate : Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 448377] Adjusting VAT Date with no doc type 
        Initialize();

        // [WHEN] Posting with Sales Invoice to generate VAT entry
        DocType := Enum::"Gen. Journal Document Type"::Invoice;
        PostType := Enum::"General Posting Type"::Sale;
        DocNo := CreateAndPostSalesDoc(0D, DocType);
        DocHeader.Get(DocNo);

        // [THEN] Get VAT entry and change VAT doc type
        VATEntry.Reset();
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange(Type, PostType);
        VATEntry.FindFirst();
        VATEntry.Validate("Document Type", Enum::"Gen. Journal Document Type"::" ");
        VATEntry.Modify();

        // [THEN] No errors happen when adjusting dates
        CorrectVATDateAndVerifyChange(VATEntry."Entry No.", VATEntry."VAT Reporting Date" + 1);
    end;

    [Test]
    procedure TestVATEntryAdjustDateWithEmptyPostType()
    var
        DocHeader: Record "Sales Invoice Header";
        VATEntry: Record "VAT Entry";
        DocNo: Code[20];
        VATDate, NewVATDate : Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 448377] Adjusting VAT Date with no post type 
        Initialize();

        // [WHEN] Posting with Sales Invoice to generate VAT entry
        DocType := Enum::"Gen. Journal Document Type"::Invoice;
        PostType := Enum::"General Posting Type"::Sale;
        DocNo := CreateAndPostSalesDoc(0D, DocType);
        DocHeader.Get(DocNo);

        // [THEN] Get VAT entry and change VAT posting type
        VATEntry.Reset();
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange(Type, PostType);
        VATEntry.FindFirst();
        VATEntry.Validate("Type", Enum::"General Posting Type"::" ");
        VATEntry.Modify();

        // [THEN] No errors happen when adjusting dates
        CorrectVATDateAndVerifyChange(VATEntry."Entry No.", VATEntry."VAT Reporting Date" + 1);
    end;

    [Test]
    procedure VATPostingDateChangeSuccessful()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATEntryPage: TestPage "VAT Entries";
        DocNo: Code[20];
        VATDate, NewVATDate : Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 448198] Restricting VAT Date change
        Initialize();

        // [WHEN] Posting sales invoice
        DocType := Enum::"Gen. Journal Document Type"::Invoice;
        PostType := Enum::"General Posting Type"::Sale;
        DocNo := CreateAndPostSalesDoc(WorkDate(), DocType);
        SalesInvHeader.Get(DocNo);

        // [WHEN] Adding VAT Return period that is Open with VAT Return Status Open
        CreateVATReturnPeriod(VATReturnPeriod.Status::Open, VATReportHeader.Status::Open, WorkDate(), WorkDate() + 1);

        // [THEN] Get VAT Entry for document
        VATEntryNo := VerifyVATEntry(DocNo, DocType, PostType, SalesInvHeader."VAT Reporting Date");
        NewVATDate := WorkDate() + 1;

        // [WHEN] Change VAT Date to date within VAT period there is no warnings
        VATEntryPage.OpenEdit();
        VATEntryPage.Filter.SetFilter("Entry No.", Format(VATEntryNo));
        VATEntryPage.First();
        VATEntryPage."VAT Reporting Date".SetValue(NewVATDate);

        Assert.AreEqual(NewVATDate, VATEntryPage."VAT Reporting Date".AsDate(), VATDateOnRecordErr);        
    end;

    [Test]
    procedure VATPostingDateChangeFailure()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATEntryPage: TestPage "VAT Entries";
        DocNo: Code[20];
        VATDate, NewVATDate : Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 448198] Restricting VAT Date change
        Initialize();

        // [WHEN] Posting sales invoice
        DocType := Enum::"Gen. Journal Document Type"::Invoice;
        PostType := Enum::"General Posting Type"::Sale;
        DocNo := CreateAndPostSalesDoc(WorkDate(), DocType);
        SalesInvHeader.Get(DocNo);

        // [WHEN] Adding VAT Return period that is Closed with VAT Return Status Open
        CreateVATReturnPeriod(VATReturnPeriod.Status::Closed, VATReportHeader.Status::Open, WorkDate(), WorkDate() + 1);

        // [THEN] Get VAT Entry for document
        VATEntryNo := VerifyVATEntry(DocNo, DocType, PostType, SalesInvHeader."VAT Reporting Date");
        NewVATDate := WorkDate() + 1;

        // [WHEN] Change VAT Date to date within VAT period there is no warnings
        VATEntryPage.OpenEdit();
        VATEntryPage.Filter.SetFilter("Entry No.", Format(VATEntryNo));
        VATEntryPage.First();
        asserterror VATEntryPage."VAT Reporting Date".SetValue(NewVATDate);
        Assert.ExpectedError(VATDateNotChangedErr);

        Assert.AreEqual(WorkDate(), VATEntryPage."VAT Reporting Date".AsDate(), VATDateOnRecordErr);        
    end;
    
    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure VATPostingDateChangeWarning()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATEntryPage: TestPage "VAT Entries";
        DocNo: Code[20];
        VATDate, NewVATDate : Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 448198] Restricting VAT Date change
        Initialize();

        // [WHEN] Posting sales invoice
        DocType := Enum::"Gen. Journal Document Type"::Invoice;
        PostType := Enum::"General Posting Type"::Sale;
        DocNo := CreateAndPostSalesDoc(WorkDate(), DocType);
        SalesInvHeader.Get(DocNo);

        // [WHEN] Adding VAT Return period that is Open with VAT Return Status Submitted
        CreateVATReturnPeriod(VATReturnPeriod.Status::Open, VATReportHeader.Status::Submitted, WorkDate(), WorkDate() + 1);

        // [THEN] Get VAT Entry for document
        VATEntryNo := VerifyVATEntry(DocNo, DocType, PostType, SalesInvHeader."VAT Reporting Date");
        NewVATDate := WorkDate() + 1;

        // [WHEN] Change VAT Date to date within VAT period there is warnings
        VATEntryPage.OpenEdit();
        VATEntryPage.Filter.SetFilter("Entry No.", Format(VATEntryNo));
        VATEntryPage.First();
        VATEntryPage."VAT Reporting Date".SetValue(NewVATDate);
      
        Assert.AreEqual(WorkDate() + 1, VATEntryPage."VAT Reporting Date".AsDate(), VATDateOnRecordErr);        
    end;

    

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure VATPostingDateChangeWarning2()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATEntryPage: TestPage "VAT Entries";
        DocNo: Code[20];
        VATDate, NewVATDate : Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 448198] Restricting VAT Date change
        Initialize();

        // [WHEN] Posting sales invoice
        DocType := Enum::"Gen. Journal Document Type"::Invoice;
        PostType := Enum::"General Posting Type"::Sale;
        DocNo := CreateAndPostSalesDoc(WorkDate(), DocType);
        SalesInvHeader.Get(DocNo);

        // [WHEN] Adding VAT Return period that is Open with VAT Return Status Released
        CreateVATReturnPeriod(VATReturnPeriod.Status::Open, VATReportHeader.Status::Released, WorkDate(), WorkDate() + 1);

        // [THEN] Get VAT Entry for document
        VATEntryNo := VerifyVATEntry(DocNo, DocType, PostType, SalesInvHeader."VAT Reporting Date");
        NewVATDate := WorkDate() + 1;

        // [WHEN] Change VAT Date to date within VAT period there is warnings
        VATEntryPage.OpenEdit();
        VATEntryPage.Filter.SetFilter("Entry No.", Format(VATEntryNo));
        VATEntryPage.First();
        VATEntryPage."VAT Reporting Date".SetValue(NewVATDate);
      
        Assert.AreEqual(WorkDate() + 1, VATEntryPage."VAT Reporting Date".AsDate(), VATDateOnRecordErr);        
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure VATPostingDateChangeWarning3()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATEntryPage: TestPage "VAT Entries";
        DocNo: Code[20];
        VATDate, NewVATDate : Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 448198] Restricting VAT Date change
        Initialize();

        // [WHEN] Posting sales invoice
        DocType := Enum::"Gen. Journal Document Type"::Invoice;
        PostType := Enum::"General Posting Type"::Sale;
        DocNo := CreateAndPostSalesDoc(WorkDate(), DocType);
        SalesInvHeader.Get(DocNo);

        // [WHEN] Adding VAT Return period that is Open with VAT Return Status Released
        CreateVATReturnPeriod(VATReturnPeriod.Status::Open, VATReportHeader.Status::Released, WorkDate(), WorkDate() + 1);

        // [THEN] Get VAT Entry for document
        VATEntryNo := VerifyVATEntry(DocNo, DocType, PostType, SalesInvHeader."VAT Reporting Date");
        NewVATDate := WorkDate() + 1;

        // [WHEN] Change VAT Date to date within VAT period there is warnings
        VATEntryPage.OpenEdit();
        VATEntryPage.Filter.SetFilter("Entry No.", Format(VATEntryNo));
        VATEntryPage.First();
        VATEntryPage."VAT Reporting Date".SetValue(NewVATDate);
      
        Assert.AreEqual(WorkDate(), VATEntryPage."VAT Reporting Date".AsDate(), VATDateOnRecordErr);        
    end;

    [Test]
    procedure VATPostingDateChangeMultiPeriodSuccessful()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
        VATEntryPage: TestPage "VAT Entries";
        DocNo: Code[20];
        VATDate, NewVATDate : Date;
        VATEntryNo: Integer;
        DocType: Enum "Gen. Journal Document Type";
        PostType: Enum "General Posting Type";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 448198] Restricting VAT Date change
        Initialize();

        // [WHEN] Posting sales invoice
        DocType := Enum::"Gen. Journal Document Type"::Invoice;
        PostType := Enum::"General Posting Type"::Sale;
        DocNo := CreateAndPostSalesDoc(WorkDate(), DocType);
        SalesInvHeader.Get(DocNo);

        // [WHEN] Adding VAT Return period that is Open with VAT Return Status Open
        CreateVATReturnPeriod(VATReturnPeriod.Status::Open, VATReportHeader.Status::Open, WorkDate(), WorkDate() + 1);
        CreateVATReturnPeriod(VATReturnPeriod.Status::Open, VATReportHeader.Status::Closed, WorkDate() + 2, WorkDate() + 3);

        // [THEN] Get VAT Entry for document
        VATEntryNo := VerifyVATEntry(DocNo, DocType, PostType, SalesInvHeader."VAT Reporting Date");
        NewVATDate := WorkDate() + 1;

        // [WHEN] Change VAT Date to date within VAT period there is no warnings
        VATEntryPage.OpenEdit();
        VATEntryPage.Filter.SetFilter("Entry No.", Format(VATEntryNo));
        VATEntryPage.First();
        VATEntryPage."VAT Reporting Date".SetValue(NewVATDate);
      
        Assert.AreEqual(WorkDate() + 1, VATEntryPage."VAT Reporting Date".AsDate(), VATDateOnRecordErr);        
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM VAT Sales/Purchase");
        LibrarySetupStorage.Restore();
        LibraryRandom.SetSeed(1);  // Generate Random Seed using Random Number Generator.
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId);
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId);

        // Lazy Setup.
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM VAT Sales/Purchase");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM VAT Sales/Purchase");
    end;

    local procedure CreateVATReturnPeriod(VATReturnPeriodStatus: Option; VATReportHeaderStatus: Option; StartDate: Date; EndDate: Date) 
    var
        VATReturnPeriod: Record "VAT Return Period";
        VATReportHeader: Record "VAT Report Header";
    begin
        VATReportHeader.DeleteAll();
        VATReportHeader."No." := 'TEST';
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader.Status := VATReportHeaderStatus;
        VATReportHeader.Insert();

        VATReturnPeriod.DeleteAll();
        VATReturnPeriod.Init();
        VATReturnPeriod."No." := 'TEST';
        VATReturnPeriod."VAT Return No." := 'TEST';
        VATReturnPeriod."Start Date" := StartDate;
        VATReturnPeriod."End Date" := EndDate;
        VATReturnPeriod.Status := VATReturnPeriodStatus;
        VATReturnPeriod.Insert();
    end;

    local procedure CorrectVATDateAndVerifyChange(VATEntryNo: Integer; VATDate: Date)
    var
        VATEntryPage: TestPage "VAT Entries";
    begin
        VATEntryPage.OpenEdit();
        VATEntryPage.Filter.SetFilter("Entry No.", Format(VATEntryNo));
        VATEntryPage.First();
        VATEntryPage."VAT Reporting Date".SetValue(VATDate);
        Assert.AreEqual(VATDate, VATEntryPage."VAT Reporting Date".AsDate(), VATDateOnRecordErr);
    end;

    local procedure VerifyVATEntry(DocNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; Type: Enum "General Posting Type"; VATDate: Date) : Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Reset();
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange(Type, Type);
        VATEntry.FindFirst();
        Assert.AreEqual(VATDate, VATEntry."VAT Reporting Date", VATDateOnRecordErr);
        exit(VATEntry."Entry No.");
    end;

    local procedure VerifyGLEntry(DocNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; Type: Enum "General Posting Type"; VATDate: Date)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("Document Type", DocType);
        GLEntry.SetRange("Gen. Posting Type", Type);
        GLEntry.FindSet();
        repeat
            Assert.AreEqual(VATDate, GLEntry."VAT Reporting Date", VATDateOnRecordErr);
        until GLEntry.Next() = 0;
    end;

    local procedure SetupForSalesOrderAndVAT(var VATAmountLine: Record "VAT Amount Line")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Take Random for Multiple Sales Line.
        CreateSalesDocWithPartQtyToShip(
          SalesHeader, SalesLine, LibraryRandom.RandIntInRange(2, 10), SalesHeader."Document Type"::Order);
        CalcSalesVATAmountLines(VATAmountLine, SalesHeader, SalesLine);
    end;

    local procedure SetupForPurchaseOrderAndVAT(var VATAmountLine: Record "VAT Amount Line") CurrencyCode: Code[10]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Currency: Record Currency;
    begin
        Currency.FindFirst();

        // Take Random for Multiple Purchase Line.
        CreatePurchDocWithPartQtyToRcpt(
          PurchaseHeader, PurchaseLine, Currency.Code, LibraryRandom.RandIntInRange(2, 10), PurchaseHeader."Document Type"::Order);
        CurrencyCode := PurchaseHeader."Currency Code";
        CalcPurchaseVATAmountLines(VATAmountLine, PurchaseHeader, PurchaseLine);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; PricesInclVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateSalesHeader(SalesHeader, VATPostingSetup, DocumentType, PricesInclVAT);
        CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
    end;

    local procedure CreateSalesInvoiceWithVATRegNo(var SalesHeader: Record "Sales Header"; var Customer: Record Customer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateCustomerWithVATRegNo(Customer, VATPostingSetup."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
    end;

    local procedure CreatePurchInvoiceWithVATRegNo(var PurchaseHeader: Record "Purchase Header"; var Vendor: Record Vendor)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateVendorWithVATRegNo(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
    end;

    local procedure CreateSalesDocWithPartQtyToShip(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; NoOfLine: Integer; DocumentType: Enum "Sales Document Type") TotalAmount: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Counter: Integer;
    begin
        // Take Random Quantity and Unit Price.
        CreateSalesHeader(SalesHeader, VATPostingSetup, DocumentType, false);
        for Counter := 1 to NoOfLine do begin  // Create Multiple Sales Line.
            CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
            SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);
            SalesLine.Modify(true);
            TotalAmount += SalesLine."Qty. to Ship" * SalesLine."Unit Price";
        end;
    end;

    local procedure CreateSalesDocumentAndCalcVAT(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; VATDifference: Decimal)
    var
        VATAmountLine: Record "VAT Amount Line";
    begin
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, DocumentType);
        CalcSalesVATAmountLines(VATAmountLine, SalesHeader, SalesLine);
        UpdateVATDiffInVATAmountLine(VATAmountLine, VATDifference);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; var VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type"; PricesInclVAT: Boolean)
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        ModifySalesHeaderPricesInclVAT(SalesHeader, PricesInclVAT);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale),
          LibraryRandom.RandInt(10) * 2); // need to have even Quantity
        SalesLine.Validate("Unit Price", (1 + VATPostingSetup."VAT %" / 100) * LibraryRandom.RandIntInRange(100, 200)); // need to prevent rounding issues
        SalesLine.Modify();
    end;

    local procedure CreateSalesLineWithCustomAmounts(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; Quantity: Decimal; UnitPrice: Decimal; DiscountPct: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale),
          Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", DiscountPct);
        SalesLine.Modify();
    end;

    local procedure CreateSalesLineWithUnitPriceAndVATProdPstGroup(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATProdPstGroupCode: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPstGroupCode);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithoutInsert(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate(Type, SalesLine.Type::Item);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate("No.", Item."No.");
        SalesLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));
    end;

    local procedure CreatePurchDocWithPartQtyToRcpt(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10]; NoOfLine: Integer; DocumentType: Enum "Purchase Document Type") TotalAmount: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Counter: Integer;
    begin
        // Take Random Quantity and Direct Unit Cost.
        CreatePurchaseHeader(PurchaseHeader, VATPostingSetup, DocumentType, false);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        for Counter := 1 to NoOfLine do begin  // Create Multiple Purchase Line.
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
            PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);
            PurchaseLine.Modify(true);
            TotalAmount += PurchaseLine."Qty. to Receive" * PurchaseLine."Direct Unit Cost";
        end;
    end;

    local procedure CreatePurchDocumentAndCalcVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VATDifference: Decimal)
    var
        VATAmountLine: Record "VAT Amount Line";
    begin
        CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, DocumentType);
        CalcPurchaseVATAmountLines(VATAmountLine, PurchaseHeader, PurchaseLine);
        UpdateVATDiffInVATAmountLine(VATAmountLine, VATDifference);
    end;

    local procedure CreateCustomerAndUpdateVAT(SalesLine: Record "Sales Line"): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        with VATPostingSetup do begin
            SetFilter("VAT Bus. Posting Group", '<>%1 & <>%2', '', SalesLine."VAT Bus. Posting Group");
            SetRange("VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
            SetFilter("VAT %", '>%1', 0);
            FindFirst();
            exit(LibrarySales.CreateCustomerWithVATBusPostingGroup("VAT Bus. Posting Group"));
        end;
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; PricesInclVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreatePurchaseHeader(PurchaseHeader, VATPostingSetup, DocumentType, PricesInclVAT);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type"; PricesInclVAT: Boolean)
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocumentType,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        ModifyPurchaseHeaderPricesInclVAT(PurchaseHeader, PricesInclVAT);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase),
          LibraryRandom.RandInt(10) * 2); // need to have even Quantity
        PurchaseLine.Validate("Direct Unit Cost", (1 + VATPostingSetup."VAT %" / 100) * LibraryRandom.RandIntInRange(100, 200)); // need to prevent rounding issues
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithCustomAmounts(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; Quantity: Decimal; DirectUnitCost: Decimal; LineDiscountPct: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase),
          Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Line Discount %", LineDiscountPct);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithUnitPriceAndVATProdPstGroup(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATProdPstGroupCode: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATProdPstGroupCode);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithoutInsert(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
    begin
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Validate("No.", Item."No.");
        PurchaseLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));
    end;

    local procedure CreateSalesLineThroughPage(VATPostingSetup: Record "VAT Posting Setup"; No: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        SalesOrder: TestPage "Sales Order";
    begin
        // Create new Sales Line with Random Unit Price and Quantity.
        SalesOrder.OpenEdit;
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesLines.First;
        SalesOrder.SalesLines.Next();
        SalesOrder.SalesLines.Type.SetValue(Format(SalesOrder.SalesLines.Type));
        SalesOrder.SalesLines."No.".SetValue(
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        SalesOrder.SalesLines."Unit Price".SetValue(LibraryRandom.RandDec(100, 2));
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        exit(SalesOrder.SalesLines."No.".Value);
    end;

    local procedure CreateAndPostSalesDoc(VATDate: Date; DocType: Enum "Gen. Journal Document Type"): Code[20]
    var
        SalesLine: Record "Sales Line";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        with SalesHeader do begin
            LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
            Validate("Document Date", CalcDate(Format(-LibraryRandom.RandIntInRange(50, 100)) + '<D>', WorkDate()));
            if VATDate <> 0D then
                Validate("VAT Reporting Date", VATDate)
            else
                Validate("VAT Reporting Date");
            Modify(true);
            CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
            exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        end;
    end;

    local procedure CreateAndPostPurchDoc(VATDate: Date; DocType: Enum "Gen. Journal Document Type"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        with PurchaseHeader do begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
            Validate("Document Date", CalcDate(Format(-LibraryRandom.RandIntInRange(50, 100)) + '<D>', WorkDate()));
            if VATDate <> 0D then
                Validate("VAT Reporting Date", VATDate)
            else
                Validate("VAT Reporting Date");
            Modify(true);
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
            exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        end;
    end;

    local procedure CreateAndPostSalesInvoiceWithPaymentTermCode(VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo);
        PaymentMethod.Modify(true);
        with SalesHeader do begin
            LibrarySales.CreateSalesHeader(SalesHeader, "Document Type"::Invoice, CustomerNo);
            Validate("Payment Terms Code", PaymentTerms.Code);
            Validate("Document Date", CalcDate(Format(-LibraryRandom.RandIntInRange(50, 100)) + '<D>', WorkDate()));
            Validate("Payment Method Code", PaymentMethod.Code);
            Modify(true);
            CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
            exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        end;
    end;

    local procedure CreateAndPostPurchaseInvoiceWithPaymentTermCode(VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo);
        PaymentMethod.Modify(true);
        with PurchaseHeader do begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Document Type"::Invoice, VendorNo);
            Validate("Payment Terms Code", PaymentTerms.Code);
            Validate("Document Date", CalcDate(Format(-LibraryRandom.RandIntInRange(50, 100)) + '<D>', WorkDate()));
            Validate("Payment Method Code", PaymentMethod.Code);
            Modify(true);
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup);
            exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        end;
    end;

    local procedure CreateCustomerWithVATRegNo(var Customer: Record Customer; VATBusPostingGroup: Code[20])
    begin
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify();
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroupCode: Code[20]; VATProductPostingGroupCode: Code[20]; VATPercent: Decimal; VATCalculationType: Enum "Tax Calculation Type")
    begin
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroupCode);
        VATPostingSetup.Validate("VAT Identifier", VATBusinessPostingGroupCode);
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendorWithVATRegNo(var Vendor: Record Vendor; VATBusPostingGroup: Code[20])
    begin
        LibraryPurchase.CreateVendorWithVATRegNo(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify();
    end;

    local procedure MockVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; VATIdentifier: Code[20]; LineAmount: Decimal; InvDiscAmount: Decimal; VATBase: Decimal; VATPct: Decimal; VATAmount: Decimal)
    begin
        VATAmountLine.Init();
        VATAmountLine."VAT Identifier" := VATIdentifier;
        VATAmountLine."Line Amount" := LineAmount;
        VATAmountLine."Invoice Discount Amount" := InvDiscAmount;
        VATAmountLine."VAT Base" := VATBase;
        VATAmountLine."VAT %" := VATPct;
        VATAmountLine."VAT Amount" := VATAmount;
        VATAmountLine.Positive := VATAmountLine."VAT Amount" > 0;
        VATAmountLine.Insert();
    end;

    local procedure CalcSalesVATAmountLines(var VATAmountLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        QtyType: Option General,Invoicing,Shipping;
    begin
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
    end;

    local procedure CalcPurchaseVATAmountLines(var VATAmountLine: Record "VAT Amount Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        QtyType: Option General,Invoicing,Shipping;
    begin
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; Type: Enum "General Posting Type")
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange(Type, Type);
        VATEntry.FindFirst();
    end;

    local procedure ModifyAllowVATDifferencePurchases(AllowVATDifference: Boolean): Decimal
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        PurchasesPayablesSetup.Modify(true);
        exit(SetMaxAllowedVATDifference(AllowVATDifference));
    end;

    local procedure ModifyAllowVATDifferenceSales(AllowVATDifference: Boolean): Decimal
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        SalesReceivablesSetup.Modify(true);
        exit(SetMaxAllowedVATDifference(AllowVATDifference));
    end;

    local procedure SetMaxAllowedVATDifference(AllowVATDifference: Boolean) MaxVATDifference: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if AllowVATDifference then
            MaxVATDifference := LibraryRandom.RandDec(2, 2)
        else
            MaxVATDifference := 0;

        with GeneralLedgerSetup do begin
            Get();
            Validate("Max. VAT Difference Allowed", MaxVATDifference);
            Modify();
        end;
        exit(MaxVATDifference);
    end;

    local procedure ModifyInvRoundingInSalesSetup(InvoiceRounding: Boolean; CreditWarnings: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ModifyInvRoundingInGLSetup(InvRoundingPrecisionLCY: Decimal) OldInvRoundingPrecision: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldInvRoundingPrecision := GeneralLedgerSetup."Inv. Rounding Precision (LCY)";
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", InvRoundingPrecisionLCY);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure ModifyInvRoundingInPurchSetup(InvoiceRounding: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ModifySalesHeaderPricesInclVAT(var SalesHeader: Record "Sales Header"; NewPricesInclVAT: Boolean)
    begin
        SalesHeader.Validate("Prices Including VAT", NewPricesInclVAT);
        SalesHeader.Modify();
    end;

    local procedure ModifyPurchaseHeaderPricesInclVAT(var PurchaseHeader: Record "Purchase Header"; NewPricesInclVAT: Boolean)
    begin
        PurchaseHeader.Validate("Prices Including VAT", NewPricesInclVAT);
        PurchaseHeader.Modify();
    end;

    local procedure OpenSalesOrderStatistics(DocumentNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit;
        SalesOrder.FILTER.SetFilter("No.", DocumentNo);
        SalesOrder.Statistics.Invoke;
    end;

    local procedure OpenSalesQuoteStatistics(DocumentNo: Code[20])
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit;
        SalesQuote.FILTER.SetFilter("No.", DocumentNo);
        SalesQuote.Statistics.Invoke;
    end;

    local procedure OpenBlanketSalesOrderStatistics(DocumentNo: Code[20])
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenEdit;
        BlanketSalesOrder.FILTER.SetFilter("No.", DocumentNo);
        BlanketSalesOrder.Statistics.Invoke;
    end;

    local procedure OpenSalesInvoiceStatistics(DocumentNo: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit;
        SalesInvoice.FILTER.SetFilter("No.", DocumentNo);
        SalesInvoice.Statistics.Invoke;
    end;

    local procedure OpenPurchaseOrderStatistics(DocumentNo: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit;
        PurchaseOrder.FILTER.SetFilter("No.", DocumentNo);
        PurchaseOrder.Statistics.Invoke;
    end;

    local procedure OpenPurchaseInvoiceStatistics(DocumentNo: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit;
        PurchaseInvoice.FILTER.SetFilter("No.", DocumentNo);
        PurchaseInvoice.Statistics.Invoke;
    end;

    local procedure PurchaseVATAmountCalculation(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter("No.", '<>''''');
        PurchaseLine.FindFirst();
    end;

    local procedure RunCopySalesDocument(SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type From"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        Clear(CopySalesDocument);
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(DocumentType, DocumentNo, IncludeHeader, RecalculateLines);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();
    end;

    local procedure RunCopyPurchaseDocument(PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20])
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        Clear(CopyPurchaseDocument);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters("Purchase Document Type From"::Invoice, DocumentNo, true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();
    end;

    local procedure SetupBillToSellToVATCalc(var SalesHeader: Record "Sales Header"; GLSetupBillToPayToCalc: Enum "G/L Setup VAt Calculation")
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // Setup: Update General Ledger Setup, Create Sales Order.
        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Order);  // Using 1 for creating one Sales Line.
        CustomerNo := CreateCustomerAndUpdateVAT(SalesLine);
        SalesHeader.Validate("Bill-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);

        // Exercise: Post Sales Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        if GLSetupBillToPayToCalc = GLSetupBillToPayToCalc::"Bill-to/Pay-to No." then
            Customer.Get(SalesHeader."Bill-to Customer No.")
        else
            Customer.Get(SalesHeader."Sell-to Customer No.");

        // Verify: Verify Correct VAT Bus. Posting Group and Gen. Bus. Posting Group updated on VAT Entry.
        VerifyVATBusAndGenBusGroupOnVATEntry(DocumentNo, Customer."VAT Bus. Posting Group", Customer."Gen. Bus. Posting Group");
    end;

    local procedure SetupBillToPayToVATCalc()
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup and Create Purchase Order.
        CreatePurchDocWithPartQtyToRcpt(PurchaseHeader, PurchaseLine, '', 1, PurchaseHeader."Document Type"::Order);
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Validate("Pay-to Vendor No.", LibraryPurchase.CreateVendorWithVATBusPostingGroup(Vendor."VAT Bus. Posting Group"));
        PurchaseHeader.Modify(true);

        // Exercise: Post Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Vendor.Get(PurchaseHeader."Pay-to Vendor No.");

        // Verify: Verify Correct Gen. Bus. Posting Group updated on VAT Entry.
        VerifyVATBusAndGenBusGroupOnVATEntry(DocumentNo, Vendor."VAT Bus. Posting Group", Vendor."Gen. Bus. Posting Group");
    end;

    local procedure UpdateVATDiffInVATAmountLine(VATAmountLine: Record "VAT Amount Line"; VATDifference: Decimal)
    begin
        VATAmountLine.Validate("VAT Amount", VATAmountLine."VAT Amount" + VATDifference);
        VATAmountLine.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(BilltoSelltoVATCalc: Enum "G/L Setup VAt Calculation")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", BilltoSelltoVATCalc);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateInvoiceRoundingInGLSetup(InvoiceRounding: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", InvoiceRounding);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateInvoiceRoundingAccCustomer(CustomerNo: Code[20]; VATProdPostGroup: Code[20])
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostGroup);
        GLAccount.Modify(true);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate("Invoice Rounding Account", GLAccount."No.");
        CustomerPostingGroup.Modify(true);
    end;

    local procedure UpdateInvoiceRoundingAccVendor(VendorNo: Code[20]; VATProdPostGroup: Code[20])
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostGroup);
        GLAccount.Modify(true);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VendorPostingGroup.Validate("Invoice Rounding Account", GLAccount."No.");
        VendorPostingGroup.Modify(true);
    end;

    local procedure VATAmountCalculation(var BaseAmount: Decimal; SalesHeader: Record "Sales Header") VATAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.FindFirst();
        BaseAmount := -SalesLine.Quantity * SalesLine."Unit Price";
        VATAmount := SalesLine."VAT %" * BaseAmount / 100;
    end;

    local procedure ValidateAndVerifyVATAmount(VATAmountLine: Record "VAT Amount Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Exercise: Validate VAT Amount with VAT Difference.
        GeneralLedgerSetup.Get();
        VATAmountLine.Validate("VAT Amount", VATAmountLine."VAT Amount" + GeneralLedgerSetup."Max. VAT Difference Allowed");

        // Verify: Verify VAT Difference field on VAT Amount Line.
        Assert.AreEqual(
          GeneralLedgerSetup."Max. VAT Difference Allowed", VATAmountLine."VAT Difference",
          StrSubstNo(VATDifferenceErr, GeneralLedgerSetup."Max. VAT Difference Allowed", VATAmountLine.TableCaption()));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; VATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          VATAmount, GLEntry."VAT Amount", LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AmountErr, GLEntry.FieldCaption("VAT Amount"), VATAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATBase(DocumentNo: Code[20]; Base: Decimal; Type: Enum "General Posting Type")
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocumentNo, Type);
        Assert.AreNearlyEqual(
          Base, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Base), Base, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATDate(DocumentNo: Code[20]; Type: Enum "General Posting Type"; VATDate: Date)
    var
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
    begin
        FindVATEntry(VATEntry, DocumentNo, Type);
        GLEntryVATEntryLink.SetFilter("VAT Entry No.", Format(VATEntry."Entry No."));
        GLEntryVATEntryLink.FindFirst();
        GLEntry.SetFilter("Entry No.", Format(GLEntryVATEntryLink."G/L Entry No."));
        GLEntry.FindFirst();

        Assert.AreEqual(VATDate, VATEntry."VAT Reporting Date", VATDateErr);
        Assert.AreEqual(VATDate, GLEntry."VAT Reporting Date", VATDateErr);
    end;

    local procedure VerifyVATBusAndGenBusGroupOnVATEntry(DocumentNo: Code[20]; VATBusPostingGroup: Code[20]; GenBusPostingGroup: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        with VATEntry do begin
            SetRange("Document No.", DocumentNo);
            FindFirst();
            TestField("VAT Bus. Posting Group", VATBusPostingGroup);
            TestField("Gen. Bus. Posting Group", GenBusPostingGroup);
        end;
    end;

    local procedure VerifyCustomerVATPostingGroup(CustomerNo: Code[20]; VATBusPostingGroup: Code[20])
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        Customer.Get(CustomerNo);
        Assert.AreEqual(
          Customer."VAT Bus. Posting Group", VATBusPostingGroup, StrSubstNo(PostingGroupErr,
            SalesHeader.FieldCaption("VAT Bus. Posting Group"),
            Customer."VAT Bus. Posting Group", SalesHeader.TableCaption(), SalesHeader."No."));
    end;

    local procedure VerifyVATDifference(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; No: Code[20]; VATDifference: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
        Assert.AreNearlyEqual(
          VATDifference, SalesLine."VAT Difference", LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AmountErr, SalesLine.FieldCaption("VAT Difference"), VATDifference, SalesLine.TableCaption()));
    end;

    local procedure VerifyVATEntry(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        // Verifying VAT Entry fields.
        FindVATEntry(VATEntry, DocumentNo, VATEntry.Type::Purchase);
        VATEntry.TestField("VAT Bus. Posting Group", PurchaseLine."VAT Bus. Posting Group");
        VATEntry.TestField("VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VATEntry.TestField("Posting Date", WorkDate());
        VATEntry.TestField("Bill-to/Pay-to No.", PurchaseLine."Buy-from Vendor No.");
        VATEntry.TestField("EU 3-Party Trade", false);
        Assert.AreNearlyEqual(
          Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), Amount, VATEntry.TableCaption()));
    end;

    local procedure VerifyRoundingEntry(DocumentNo: Code[20]; No: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // Verify Rounding Entries
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("No.", No);
        Assert.IsTrue(SalesInvoiceLine.FindFirst, StrSubstNo(RoundingEntryErr, DocumentNo));
    end;

    local procedure VerifyVATAndBaseAmount(DocumentNo: Code[20]; GenProductPostingGroup: Code[20]; VATProductPostingGroup: Code[20]; BaseAmount: Decimal; VATAmount: Decimal; Type: Enum "General Posting Type")
    var
        VATEntry: Record "VAT Entry";
    begin
        // Verifying VAT Entry fields.
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange(Type, Type);
        VATEntry.SetRange("VAT Prod. Posting Group", VATProductPostingGroup);
        VATEntry.SetRange("Gen. Prod. Posting Group", GenProductPostingGroup);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          BaseAmount, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Base), BaseAmount, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATAmount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), VATAmount, VATEntry.TableCaption()));
    end;

    local procedure VerifyAmountOnCustomerLedgerEntry(PostedInvoiceNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ExpectedPmtAmount: Decimal;
    begin
        with CustLedgerEntry do begin
            SetRange("Document No.", PostedInvoiceNo);
            SetRange("Document Type", "Document Type"::Invoice);
            FindFirst();
            CalcFields("Amount (LCY)");
            ExpectedPmtAmount := -("Amount (LCY)" - "Original Pmt. Disc. Possible");

            SetRange("Document Type", "Document Type"::Payment);
            FindFirst();
            CalcFields("Amount (LCY)");
            TestField("Amount (LCY)", ExpectedPmtAmount);
            TestField(Open, false);
        end;
    end;

    local procedure VerifyAmountOnVendorLedgerEntry(PostedInvoiceNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpectedPmtAmount: Decimal;
    begin
        with VendorLedgerEntry do begin
            SetRange("Document No.", PostedInvoiceNo);
            SetRange("Document Type", "Document Type"::Invoice);
            FindFirst();
            CalcFields("Amount (LCY)");
            ExpectedPmtAmount := -("Amount (LCY)" - "Original Pmt. Disc. Possible");

            SetRange("Document Type", "Document Type"::Payment);
            FindFirst();
            CalcFields("Amount (LCY)");
            TestField("Amount (LCY)", ExpectedPmtAmount);
            TestField(Open, false);
        end;
    end;

    local procedure VerifySalesLineAmounts(SalesLine: Record "Sales Line"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        with SalesLine do begin
            Find();
            SalesHeader.Get("Document Type", "Document No.");
            Assert.AreEqual(ExpectedAmount, Amount, FieldCaption(Amount));
            Assert.AreEqual(ExpectedAmountInclVAT, "Amount Including VAT", FieldCaption("Amount Including VAT"));
            Assert.AreEqual(ExpectedAmountInclVAT, "Outstanding Amount", FieldCaption("Outstanding Amount"));
            if SalesHeader."Prices Including VAT" then
                Assert.AreEqual("Line Amount", GetLineAmountInclVAT, 'Line Amount Incl. VAT')
            else
                Assert.AreEqual("Line Amount", GetLineAmountExclVAT, 'Line Amount Excl. VAT');
        end;
    end;

    local procedure VerifyPurchLineAmounts(PurchaseLine: Record "Purchase Line"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    begin
        with PurchaseLine do begin
            Find();
            Assert.AreEqual(ExpectedAmount, Amount, FieldCaption(Amount));
            Assert.AreEqual(ExpectedAmountInclVAT, "Amount Including VAT", FieldCaption("Amount Including VAT"));
            Assert.AreEqual(ExpectedAmountInclVAT, "Outstanding Amount", FieldCaption("Outstanding Amount"));
        end;
    end;

    local procedure VerifyVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; Positive: Boolean; VATBase: Decimal; VATAmount: Decimal)
    begin
        VATAmountLine.SetRange(Positive, Positive);
        VATAmountLine.FindFirst();
        VATAmountLine.TestField("Line Amount", VATBase);
        VATAmountLine.TestField("VAT Base", VATBase);
        VATAmountLine.TestField("VAT Amount", VATAmount);
    end;

    local procedure VerifyVATAmountLinePerGroup(var VATAmountLine: Record "VAT Amount Line"; VATIdentifier: Code[20]; VATBase: Decimal; VATAmount: Decimal)
    begin
        VATAmountLine.SetRange("VAT Identifier", VATIdentifier);
        VATAmountLine.FindFirst();
        VATAmountLine.TestField("Line Amount", VATBase);
        VATAmountLine.TestField("VAT Base", VATBase);
        VATAmountLine.TestField("VAT Amount", VATAmount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        // Modal Page Handler.
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        // Modal Page Handler.
        PurchaseOrderStatistics.NoOfVATLines_Invoicing.DrillDown;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        // Modal Page Handler.
        PurchaseStatistics.TotalAmount1.AssertEquals(LibraryVariableStorage.DequeueDecimal);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsHandler(var SalesStatistics: TestPage "Sales Statistics")
    begin
        // Modal Page Handler.
        SalesStatistics.TotalAmount1.AssertEquals(LibraryVariableStorage.DequeueDecimal);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckValuesOnVATAmountLinesMPH(var VATAmountLines: TestPage "VAT Amount Lines")
    begin
        VATAmountLines."VAT Amount".AssertEquals(LibraryVariableStorage.DequeueDecimal);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditSalesVATAmountLinesHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    begin
        // Modal Page Handler.
        VATAmountLines."VAT Amount".SetValue(LibraryVariableStorage.DequeueDecimal);
        VATAmountLines.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BlanketOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.NoOfVATLines_General.DrillDown;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteStatisticsHandler(var SalesStatistics: TestPage "Sales Statistics")
    begin
        Assert.IsFalse(SalesStatistics.VATAmount.Editable, StrSubstNo(VATAmountMsg, SalesStatistics.VATAmount.Caption));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATAmountLineHandler(var VATAmountLines: TestPage "VAT Amount Lines")
    begin
        Assert.IsFalse(VATAmountLines."VAT Amount".Editable, StrSubstNo(VATAmountMsg, VATAmountLines."VAT Amount".Caption));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InvoicingVATAmountSalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.VATAmount_Invoicing.AssertEquals(LibraryVariableStorage.DequeueDecimal);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
    
    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

