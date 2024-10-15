codeunit 132501 "Sales Document Posting Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Error Message] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibrarySales: Codeunit "Library - Sales";
        PostingDateNotAllowedErr: Label 'Posting Date is not within your range of allowed posting dates.';
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        VATDateNotAllowedErr: Label 'VAT Date is not within your range of allowed posting dates.';
        NothingToPostErr: Label 'There is nothing to post.';
        DefaultDimErr: Label 'Select a Dimension Value Code for the Dimension Code %1 for Customer %2.';

    [Test]
    [Scope('OnPrem')]
    procedure T001_PostingDateIsInNotAllowedPeriodInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        GeneralLedgerSetupPage: TestPage "General Ledger Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in G/L Setup
        Initialize;
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.TestField("Posting Date", WorkDate);

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages;
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst;
        TempErrorMessage.TestField(Description, PostingDateNotAllowedErr);
        // [THEN] "Context" is 'Sales Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", SalesHeader.RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Sales Header");
        TempErrorMessage.TestField("Context Field Number", SalesHeader.FieldNo("Posting Date"));
        // [THEN] "Source" is 'G/L Setup', "Field Name" is 'Allow Posting From'
        GeneralLedgerSetup.Get();
        TempErrorMessage.TestField("Record ID", GeneralLedgerSetup.RecordId);
        TempErrorMessage.TestField("Table Number", DATABASE::"General Ledger Setup");
        TempErrorMessage.TestField("Field Number", GeneralLedgerSetup.FieldNo("Allow Posting From"));
        // [WHEN] DrillDown on "Source"
        GeneralLedgerSetupPage.Trap;
        LibraryErrorMessage.DrillDownOnSource;
        // [THEN] opens "General Ledger Setup" page.
        GeneralLedgerSetupPage."Allow Posting To".AssertEquals(WorkDate - 1);
        GeneralLedgerSetupPage.Close;

        // [WHEN] DrillDown on "Description"
        SalesInvoicePage.Trap;
        LibraryErrorMessage.DrillDownOnDescription;
        // [THEN] opens "Sales Invoice" page.
        SalesInvoicePage."Posting Date".AssertEquals(WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T002_PostingDateIsInNotAllowedPeriodInUserSetup()
    var
        SalesHeader: Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        UserSetup: Record "User Setup";
        UserSetupPage: TestPage "User Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in User Setup.
        Initialize;
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "User Setup"
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow Posting To" := WorkDate - 1;
        UserSetup.Modify();
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.TestField("Posting Date", WorkDate);

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages;
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst;
        TempErrorMessage.TestField(Description, PostingDateNotAllowedErr);
        // [THEN] "Context" is 'Sales Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", SalesHeader.RecordId);
        TempErrorMessage.TestField("Context Field Number", SalesHeader.FieldNo("Posting Date"));
        // [THEN]  "Source" is 'User Setup',  "Field Name" is 'Allow Posting From'
        TempErrorMessage.TestField("Record ID", UserSetup.RecordId);
        TempErrorMessage.TestField("Field Number", UserSetup.FieldNo("Allow Posting From"));
        // [WHEN] DrillDown on "Source"
        UserSetupPage.Trap;
        LibraryErrorMessage.DrillDownOnSource;
        // [THEN] opens "User Setup" page.
        UserSetupPage."Allow Posting To".AssertEquals(WorkDate - 1);
        UserSetupPage.Close;

        // [WHEN] DrillDown on "Description"
        SalesInvoicePage.Trap;
        LibraryErrorMessage.DrillDownOnDescription;
        // [THEN] opens "Sales Invoice" page.
        SalesInvoicePage."Posting Date".AssertEquals(WorkDate);

        // TearDown
        UserSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T1001_VATDateIsInNotAllowedPeriodInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        GeneralLedgerSetupPage: TestPage "General Ledger Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Country:CZ] [VAT Date]
        // [SCENARIO] Posting of document, where "VAT Date" is out of the allowed period, set in G/L Setup
        Initialize;
        // [GIVEN] "Allow VAT Posting To" is 31.12.2018 in "General Ledger Setup"
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow VAT Posting To" := WorkDate - 1;
        GeneralLedgerSetup."Use VAT Date" := true;
        GeneralLedgerSetup.Modify();
        // [GIVEN] Invoice '1001', where "VAT Date" is 01.01.2019
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.TestField("VAT Date", WorkDate);

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages;
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "VAT Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst;
        TempErrorMessage.TestField(Description, VATDateNotAllowedErr);
        // [THEN] "Context" is 'Sales Header: Invoice, 1001', "Field Name" is 'VAT Date',
        TempErrorMessage.TestField("Context Record ID", SalesHeader.RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Sales Header");
        TempErrorMessage.TestField("Context Field Number", SalesHeader.FieldNo("VAT Date"));
        // [THEN] "Source" is 'G/L Setup', "Field Name" is 'Allow VAT Posting From'
        GeneralLedgerSetup.Get();
        TempErrorMessage.TestField("Record ID", GeneralLedgerSetup.RecordId);
        TempErrorMessage.TestField("Table Number", DATABASE::"General Ledger Setup");
        TempErrorMessage.TestField("Field Number", GeneralLedgerSetup.FieldNo("Allow VAT Posting From"));
        // [WHEN] DrillDown on "Source"
        GeneralLedgerSetupPage.Trap;
        LibraryErrorMessage.DrillDownOnSource;
        // [THEN] opens "General Ledger Setup" page.
        GeneralLedgerSetupPage."Allow VAT Posting To".AssertEquals(WorkDate - 1);
        GeneralLedgerSetupPage.Close;

        // [WHEN] DrillDown on "Description"
        SalesInvoicePage.Trap;
        LibraryErrorMessage.DrillDownOnDescription;
        // [THEN] opens "Sales Invoice" page.
        SalesInvoicePage."VAT Date".AssertEquals(WorkDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T1002_VATDateIsInNotAllowedPeriodInUserSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        UserSetup: Record "User Setup";
        UserSetupPage: TestPage "User Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Country:CZ] [VAT Date]
        // [SCENARIO] Posting of document, where "VAT Date" is out of the allowed period, set in User Setup.
        Initialize;
        // [GIVEN] "Allow VAT Posting To" is 31.12.2018 in "User Setup"
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Use VAT Date" := true;
        GeneralLedgerSetup.Modify();
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow VAT Posting To" := WorkDate - 1;
        UserSetup.Modify();
        // [GIVEN] Invoice '1001', where "VAT Date" is 01.01.2019
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.TestField("VAT Date", WorkDate);

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages;
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "VAT Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst;
        TempErrorMessage.TestField(Description, VATDateNotAllowedErr);
        // [THEN] "Context" is 'Sales Header: Invoice, 1001', "Field Name" is 'VAT Date',
        TempErrorMessage.TestField("Context Record ID", SalesHeader.RecordId);
        TempErrorMessage.TestField("Context Field Number", SalesHeader.FieldNo("VAT Date"));
        // [THEN]  "Source" is 'User Setup',  "Field Name" is 'Allow VAT Posting From'
        TempErrorMessage.TestField("Record ID", UserSetup.RecordId);
        TempErrorMessage.TestField("Field Number", UserSetup.FieldNo("Allow VAT Posting From"));
        // [WHEN] DrillDown on "Source"
        UserSetupPage.Trap;
        LibraryErrorMessage.DrillDownOnSource;
        // [THEN] opens "User Setup" page.
        UserSetupPage."Allow VAT Posting To".AssertEquals(WorkDate - 1);
        UserSetupPage.Close;

        // [WHEN] DrillDown on "Description"
        SalesInvoicePage.Trap;
        LibraryErrorMessage.DrillDownOnDescription;
        // [THEN] opens "Sales Invoice" page.
        SalesInvoicePage."VAT Date".AssertEquals(WorkDate);

        // TearDown
        UserSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T900_PreviewWithOneLoggedAndOneDirectError()
    var
        TempErrorMessage: Record "Error Message" temporary;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Preview]
        // [SCENARIO] Failed posting preview opens "Error Messages" page that contains two lines: one logged and one directly thrown error.
        Initialize;

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Order '1002', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);

        // [WHEN] Preview posting of Order '1002'
        asserterror PreviewSalesDocument(SalesHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages" with two lines:
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 2);
        // [THEN] Second line, where Description is 'There is nothing to post', Context is 'Sales Header: Order, 1002'
        TempErrorMessage.FindLast;
        TempErrorMessage.TestField(Description, NothingToPostErr);
        TempErrorMessage.TestField("Context Record ID", SalesHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T940_BatchPostingWithOneLoggedAndOneDirectError()
    var
        SalesHeader: array[3] of Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        CustomerNo: Code[20];
        RegisterID: Guid;
    begin
        // [FEATURE] [Batch Posting]
        // [SCENARIO] Batch posting of two documents (in the current session) opens "Error Messages" page that contains two lines per document.
        Initialize;
        LibrarySales.SetPostWithJobQueue(false);

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Order '1002', where "Posting Date" is 01.01.2019, and nothing to post
        CustomerNo := LibrarySales.CreateCustomerNo;
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::Order, CustomerNo);
        SalesHeaderToPost(SalesHeader[1]);
        // [GIVEN] Invoice '1003', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[2], CustomerNo);

        // [WHEN] Post both documents as a batch
        LibraryErrorMessage.TrapErrorMessages;
        SalesHeader[3].SetRange("Sell-to Customer No.", CustomerNo);
        SalesBatchPostMgt.RunWithUI(SalesHeader[3], 2, '');

        // [THEN] Opened page "Error Messages" with 3 lines:
        // [THEN] 2 lines for Order '1002' and 1 line for Invoice '1003'
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Clear(RegisterID);
        TempErrorMessage.SetRange("Register ID", RegisterID);
        Assert.RecordCount(TempErrorMessage, 3);
        // [THEN] The first error for Order '1002' is 'Posting Date is not within your range of allowed posting dates.'

        TempErrorMessage.Get(1);
        Assert.ExpectedMessage(PostingDateNotAllowedErr, TempErrorMessage.Description);
        Assert.AreEqual(SalesHeader[1].RecordId, TempErrorMessage."Context Record ID", 'Context for 1st error');
        // [THEN] The second error for Order '1002' is 'There is nothing to post'
        TempErrorMessage.Get(2);
        Assert.ExpectedMessage(NothingToPostErr, TempErrorMessage.Description);
        Assert.AreEqual(SalesHeader[1].RecordId, TempErrorMessage."Context Record ID", 'Context for 2nd error');
        // [THEN] The Error for Invoice '1003' is 'Posting Date is not within your range of allowed posting dates.'
        TempErrorMessage.Get(3);
        Assert.ExpectedMessage(PostingDateNotAllowedErr, TempErrorMessage.Description);
        Assert.AreEqual(SalesHeader[2].RecordId, TempErrorMessage."Context Record ID", 'Context for 3rd error');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T950_BatchPostingWithOneLoggedAndOneDirectErrorBackground()
    var
        SalesHeader: array[3] of Record "Sales Header";
        ErrorMessage: Record "Error Message";
        JobQueueEntry: Record "Job Queue Entry";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryDimension: Codeunit "Library - Dimension";
        CustomerNo: Code[20];
        RegisterID: Guid;
    begin
        // [FEATURE] [Batch Posting] [Job Queue]
        // [SCENARIO] Batch posting of two documents (in background) verifies "Error Messages" that contains two lines per first document and one line for second document
        Initialize;
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate - 1);
        // [GIVEN] Invoice '1002', where "Posting Date" is 01.01.2019, and no mandatory dimension
        CustomerNo := LibrarySales.CreateCustomerNo;
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[1], CustomerNo);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();
        // [GIVEN] Invoice '1003', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[2], CustomerNo);

        // [WHEN] Post both documents as a batch via Job Queue
        JobQueueEntry.DeleteAll();
        SalesHeader[3].SetRange("Sell-to Customer No.", CustomerNo);
        SalesBatchPostMgt.RunWithUI(SalesHeader[3], 2, '');
        JobQueueEntry.FindSet();
        repeat
            JobQueueEntry.Status := JobQueueEntry.Status::Ready;
            JobQueueEntry.Modify();
            Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
        until JobQueueEntry.Next() = 0;

        // [THEN] "Error Message" table contains 3 lines:
        // [THEN] 2 lines for Invoice '1002' and 1 line for Invoice '1003'
        // [THEN] The first error for Invoice '1002' is 'Posting Date is not within your range of allowed posting dates.'
        ErrorMessage.SetRange("Context Record ID", SalesHeader[1].RecordId);
        Assert.RecordCount(ErrorMessage, 2);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(PostingDateNotAllowedErr, ErrorMessage.Description);
        // [THEN] The second error for Invoice '1002' is 'Select a Dimension Value Code for the Dimension Code %1 for Customer %2.'
        ErrorMessage.Next();
        Assert.ExpectedMessage(StrSubstNo(DefaultDimErr, DefaultDimension."Dimension Code", CustomerNo), ErrorMessage.Description);

        // [THEN] The Error for Invoice '1003' is 'Posting Date is not within your range of allowed posting dates.'
        ErrorMessage.SetRange("Context Record ID", SalesHeader[2].RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage(PostingDateNotAllowedErr, ErrorMessage.Description);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales Document Posting Errors");
        LibraryErrorMessage.Clear;
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales Document Posting Errors");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales Document Posting Errors");
    end;

    local procedure PreviewSalesDocument(SalesHeader: Record "Sales Header")
    var
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
    begin
        SalesHeaderToPost(SalesHeader);
        LibraryErrorMessage.TrapErrorMessages;
        SalesPostYesNo.Preview(SalesHeader);
    end;

    local procedure SalesHeaderToPost(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        SalesHeader.Modify();
        Commit();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

