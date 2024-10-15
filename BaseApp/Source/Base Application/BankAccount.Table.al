table 270 "Bank Account"
{
    Caption = 'Bank Account';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Bank Account List";
    LookupPageID = "Bank Account List";
    Permissions = TableData "Bank Account Ledger Entry" = r;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GLSetup.Get;
                    NoSeriesMgt.TestManual(GLSetup."Bank Account Nos.");
                    "No. Series" := '';
                    "Operation Fees Code" := "No.";
                end;
            end;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                if ("Search Name" = UpperCase(xRec.Name)) or ("Search Name" = '') then
                    "Search Name" := Name;
            end;
        }
        field(3; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(10; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        field(13; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';

            trigger OnValidate()
            begin
                TestField("CCC Bank Account No.", '');
            end;
        }
        field(14; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
        }
        field(15; "Territory Code"; Code[10])
        {
            Caption = 'Territory Code';
            TableRelation = Territory;
        }
        field(16; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(17; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(18; "Chain Name"; Code[10])
        {
            Caption = 'Chain Name';
        }
        field(20; "Min. Balance"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Min. Balance';
        }
        field(21; "Bank Acc. Posting Group"; Code[20])
        {
            Caption = 'Bank Acc. Posting Group';
            TableRelation = "Bank Account Posting Group";
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" = xRec."Currency Code" then
                    exit;

                BankAcc.Reset;
                BankAcc := Rec;
                BankAcc.CalcFields(Balance, "Balance (LCY)");
                BankAcc.TestField(Balance, 0);
                BankAcc.TestField("Balance (LCY)", 0);

                if not BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open) then
                    BankAccLedgEntry.SetCurrentKey("Bank Account No.");
                BankAccLedgEntry.SetRange("Bank Account No.", "No.");
                BankAccLedgEntry.SetRange(Open, true);
                if BankAccLedgEntry.FindLast then
                    Error(
                      Text000,
                      FieldCaption("Currency Code"));

                if CarteraSetup.ReadPermission then begin
                    PostedBillGr.SetCurrentKey("Bank Account No.");
                    PostedBillGr.SetRange("Bank Account No.", "No.");
                    if PostedBillGr.Find('+') then
                        Error(Text1100000, FieldCaption("Currency Code"));
                    PostedPmtOrd.SetCurrentKey("Bank Account No.");
                    PostedPmtOrd.SetRange("Bank Account No.", "No.");
                    if PostedPmtOrd.Find('+') then
                        Error(Text1100001, FieldCaption("Currency Code"));
                end;
            end;
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(26; "Statistics Group"; Integer)
        {
            Caption = 'Statistics Group';
        }
        field(29; "Our Contact Code"; Code[20])
        {
            Caption = 'Our Contact Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(37; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(38; Comment; Boolean)
        {
            CalcFormula = Exist ("Comment Line" WHERE("Table Name" = CONST("Bank Account"),
                                                      "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(39; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(41; "Last Statement No."; Code[20])
        {
            Caption = 'Last Statement No.';
        }
        field(42; "Last Payment Statement No."; Code[20])
        {
            Caption = 'Last Payment Statement No.';

            trigger OnValidate()
            begin
                if IncStr("Last Payment Statement No.") = '' then
                    Error(StrSubstNo(UnincrementableStringErr, FieldCaption("Last Payment Statement No.")));
            end;
        }
        field(54; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(55; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(56; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(57; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(58; Balance; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Bank Account Ledger Entry".Amount WHERE("Bank Account No." = FIELD("No."),
                                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter")));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Balance (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Bank Account Ledger Entry"."Amount (LCY)" WHERE("Bank Account No." = FIELD("No."),
                                                                                "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter")));
            Caption = 'Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Net Change"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Bank Account Ledger Entry".Amount WHERE("Bank Account No." = FIELD("No."),
                                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                        "Posting Date" = FIELD("Date Filter")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Net Change (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Bank Account Ledger Entry"."Amount (LCY)" WHERE("Bank Account No." = FIELD("No."),
                                                                                "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                "Posting Date" = FIELD("Date Filter")));
            Caption = 'Net Change (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Total on Checks"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Check Ledger Entry".Amount WHERE("Bank Account No." = FIELD("No."),
                                                                 "Entry Status" = FILTER(Posted),
                                                                 "Statement Status" = FILTER(<> Closed)));
            Caption = 'Total on Checks';
            Editable = false;
            FieldClass = FlowField;
        }
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(89; Picture; BLOB)
        {
            Caption = 'Picture';
            ObsoleteReason = 'Replaced by Image field';
            ObsoleteState = Pending;
            SubType = Bitmap;
        }
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(93; "Last Check No."; Code[20])
        {
            AccessByPermission = TableData "Check Ledger Entry" = R;
            Caption = 'Last Check No.';
        }
        field(94; "Balance Last Statement"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Balance Last Statement';
        }
        field(95; "Balance at Date"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Bank Account Ledger Entry".Amount WHERE("Bank Account No." = FIELD("No."),
                                                                        "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                        "Posting Date" = FIELD(UPPERLIMIT("Date Filter"))));
            Caption = 'Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(96; "Balance at Date (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Bank Account Ledger Entry"."Amount (LCY)" WHERE("Bank Account No." = FIELD("No."),
                                                                                "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                "Posting Date" = FIELD(UPPERLIMIT("Date Filter"))));
            Caption = 'Balance at Date (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(97; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Bank Account Ledger Entry"."Debit Amount" WHERE("Bank Account No." = FIELD("No."),
                                                                                "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                "Posting Date" = FIELD("Date Filter")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(98; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Bank Account Ledger Entry"."Credit Amount" WHERE("Bank Account No." = FIELD("No."),
                                                                                 "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                 "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                 "Posting Date" = FIELD("Date Filter")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(99; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Bank Account Ledger Entry"."Debit Amount (LCY)" WHERE("Bank Account No." = FIELD("No."),
                                                                                      "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                      "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                      "Posting Date" = FIELD("Date Filter")));
            Caption = 'Debit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(100; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum ("Bank Account Ledger Entry"."Credit Amount (LCY)" WHERE("Bank Account No." = FIELD("No."),
                                                                                       "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                       "Posting Date" = FIELD("Date Filter")));
            Caption = 'Credit Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(101; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(103; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(108; "Check Report ID"; Integer)
        {
            Caption = 'Check Report ID';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = CONST(Report));
        }
        field(109; "Check Report Name"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Name" WHERE("Object Type" = CONST(Report),
                                                                        "Object ID" = FIELD("Check Report ID")));
            Caption = 'Check Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(110; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        field(111; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        field(113; "Bank Statement Import Format"; Code[20])
        {
            Caption = 'Bank Statement Import Format';
            TableRelation = "Bank Export/Import Setup".Code WHERE(Direction = CONST(Import));
        }
        field(115; "Credit Transfer Msg. Nos."; Code[20])
        {
            Caption = 'Credit Transfer Msg. Nos.';
            TableRelation = "No. Series";
        }
        field(116; "Direct Debit Msg. Nos."; Code[20])
        {
            Caption = 'Direct Debit Msg. Nos.';
            TableRelation = "No. Series";
        }
        field(117; "SEPA Direct Debit Exp. Format"; Code[20])
        {
            Caption = 'SEPA Direct Debit Exp. Format';
            TableRelation = "Bank Export/Import Setup".Code WHERE(Direction = CONST(Export));
        }
        field(121; "Bank Stmt. Service Record ID"; RecordID)
        {
            Caption = 'Bank Stmt. Service Record ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                Handled: Boolean;
            begin
                if Format("Bank Stmt. Service Record ID") = '' then
                    OnUnlinkStatementProviderEvent(Rec, Handled);
            end;
        }
        field(123; "Transaction Import Timespan"; Integer)
        {
            Caption = 'Transaction Import Timespan';
        }
        field(124; "Automatic Stmt. Import Enabled"; Boolean)
        {
            Caption = 'Automatic Stmt. Import Enabled';

            trigger OnValidate()
            begin
                if "Automatic Stmt. Import Enabled" then begin
                    if not IsAutoLogonPossible then
                        Error(MFANotSupportedErr);

                    if not ("Transaction Import Timespan" in [0 .. 9999]) then
                        Error(TransactionImportTimespanMustBePositiveErr);
                    ScheduleBankStatementDownload
                end else
                    UnscheduleBankStatementDownload;
            end;
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
        }
        field(170; "Creditor No."; Code[35])
        {
            Caption = 'Creditor No.';
        }
        field(1210; "Payment Export Format"; Code[20])
        {
            Caption = 'Payment Export Format';
            TableRelation = "Bank Export/Import Setup".Code WHERE(Direction = CONST(Export));
        }
        field(1211; "Bank Clearing Code"; Text[50])
        {
            Caption = 'Bank Clearing Code';
        }
        field(1212; "Bank Clearing Standard"; Text[50])
        {
            Caption = 'Bank Clearing Standard';
            TableRelation = "Bank Clearing Standard";
        }
        field(1213; "Bank Name - Data Conversion"; Text[50])
        {
            Caption = 'Bank Name - Data Conversion';
            ObsoleteState = Removed;
            ObsoleteReason = 'Changed to AMC Banking 365 Fundamentals Extension';
        }
        field(1250; "Match Tolerance Type"; Option)
        {
            Caption = 'Match Tolerance Type';
            OptionCaption = 'Percentage,Amount';
            OptionMembers = Percentage,Amount;

            trigger OnValidate()
            begin
                if "Match Tolerance Type" <> xRec."Match Tolerance Type" then
                    "Match Tolerance Value" := 0;
            end;
        }
        field(1251; "Match Tolerance Value"; Decimal)
        {
            Caption = 'Match Tolerance Value';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Match Tolerance Value" < 0 then
                    Error(InvalidValueErr);

                if "Match Tolerance Type" = "Match Tolerance Type"::Percentage then
                    if "Match Tolerance Value" > 99 then
                        Error(InvalidPercentageValueErr, FieldCaption("Match Tolerance Type"),
                          Format("Match Tolerance Type"::Percentage));
            end;
        }
        field(1260; "Positive Pay Export Code"; Code[20])
        {
            Caption = 'Positive Pay Export Code';
            TableRelation = "Bank Export/Import Setup".Code WHERE(Direction = CONST("Export-Positive Pay"));
        }
        field(10700; "CCC Bank No."; Text[4])
        {
            Caption = 'CCC Bank No.';
            Numeric = true;

            trigger OnValidate()
            begin
                "CCC Bank No." := PrePadString("CCC Bank No.", MaxStrLen("CCC Bank No."));
                BuildCCC;
            end;
        }
        field(10701; "CCC Bank Branch No."; Text[4])
        {
            Caption = 'CCC Bank Branch No.';
            Numeric = true;

            trigger OnValidate()
            begin
                "CCC Bank Branch No." := PrePadString("CCC Bank Branch No.", MaxStrLen("CCC Bank Branch No."));
                BuildCCC;
            end;
        }
        field(10702; "CCC Control Digits"; Text[2])
        {
            Caption = 'CCC Control Digits';
            Numeric = true;

            trigger OnValidate()
            begin
                "CCC Control Digits" := PrePadString("CCC Control Digits", MaxStrLen("CCC Control Digits"));
                BuildCCC;
            end;
        }
        field(10703; "CCC Bank Account No."; Text[10])
        {
            Caption = 'CCC Bank Account No.';
            Numeric = true;

            trigger OnValidate()
            begin
                "CCC Bank Account No." := PrePadString("CCC Bank Account No.", MaxStrLen("CCC Bank Account No."));
                BuildCCC;
            end;
        }
        field(10704; "CCC No."; Text[20])
        {
            Caption = 'CCC No.';
            Numeric = true;

            trigger OnValidate()
            begin
                "CCC Bank No." := CopyStr("CCC No.", 1, 4);
                "CCC Bank Branch No." := CopyStr("CCC No.", 5, 4);
                "CCC Control Digits" := CopyStr("CCC No.", 9, 2);
                "CCC Bank Account No." := CopyStr("CCC No.", 11, 23);
            end;
        }
        field(10705; "E-Pay Export File Path"; Text[100])
        {
            Caption = 'E-Pay Export File Path';
        }
        field(10706; "Last E-Pay Export File Name"; Text[50])
        {
            Caption = 'Last E-Pay Export File Name';
        }
        field(10707; "Last Remittance Advice No."; Code[20])
        {
            Caption = 'Last Remittance Advice No.';
        }
        field(10708; "Las E-Pay File Creation No."; Integer)
        {
            Caption = 'Las E-Pay File Creation No.';
        }
        field(7000000; "Delay for Notices"; Integer)
        {
            Caption = 'Delay for Notices';
            MinValue = 0;
        }
        field(7000001; "Credit Limit for Discount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Credit Limit for Discount';
            MinValue = 0;
        }
        field(7000002; "Last Bill Gr. No."; Code[20])
        {
            Caption = 'Last Bill Gr. No.';
            Editable = false;
        }
        field(7000003; "Date of Last Post. Bill Gr."; Date)
        {
            Caption = 'Date of Last Post. Bill Gr.';
            Editable = false;
        }
        field(7000004; "Operation Fees Code"; Code[20])
        {
            Caption = 'Operation Fees Code';
            TableRelation = "Bank Account" WHERE("Currency Code" = FIELD("Currency Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = true;
        }
        field(7000005; "Posted Receiv. Bills Rmg. Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Remaining Amount" WHERE("Bank Account No." = FIELD("No."),
                                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                              "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                              Status = FIELD("Status Filter"),
                                                                              "Category Code" = FIELD("Category Filter"),
                                                                              "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                              "Due Date" = FIELD("Due Date Filter"),
                                                                              Type = CONST(Receivable),
                                                                              "Document Type" = CONST(Bill)));
            Caption = 'Posted Receiv. Bills Rmg. Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000006; "Posted Receiv. Bills Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Amount for Collection" WHERE("Bank Account No." = FIELD("No."),
                                                                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                                   Status = FIELD("Status Filter"),
                                                                                   "Category Code" = FIELD("Category Filter"),
                                                                                   "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = FIELD("Due Date Filter"),
                                                                                   Type = CONST(Receivable),
                                                                                   "Document Type" = CONST(Bill)));
            Caption = 'Posted Receiv. Bills Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000007; "Closed Receiv. Bills Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Closed Cartera Doc."."Amount for Collection" WHERE("Bank Account No." = FIELD("No."),
                                                                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   Status = FIELD("Status Filter"),
                                                                                   "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = FIELD("Due Date Filter"),
                                                                                   Type = CONST(Receivable),
                                                                                   "Document Type" = CONST(Bill)));
            Caption = 'Closed Receiv. Bills Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000008; "Dealing Type Filter"; Option)
        {
            Caption = 'Dealing Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Collection,Discount';
            OptionMembers = Collection,Discount;
        }
        field(7000009; "Status Filter"; Option)
        {
            Caption = 'Status Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Open,Honored,Rejected';
            OptionMembers = Open,Honored,Rejected;
        }
        field(7000010; "Category Filter"; Code[10])
        {
            Caption = 'Category Filter';
            FieldClass = FlowFilter;
            TableRelation = "Category Code";
        }
        field(7000011; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            FieldClass = FlowFilter;
        }
        field(7000012; "Honored/Rejtd. at Date Filter"; Date)
        {
            Caption = 'Honored/Rejtd. at Date Filter';
            FieldClass = FlowFilter;
        }
        field(7000013; "Posted R.Bills Rmg. Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Remaining Amt. (LCY)" WHERE("Bank Account No." = FIELD("No."),
                                                                                  "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                  "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                  "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                                  Status = FIELD("Status Filter"),
                                                                                  "Category Code" = FIELD("Category Filter"),
                                                                                  "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                  "Due Date" = FIELD("Due Date Filter"),
                                                                                  Type = CONST(Receivable),
                                                                                  "Document Type" = CONST(Bill)));
            Caption = 'Posted R.Bills Rmg. Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000014; "Posted Receiv Bills Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Amt. for Collection (LCY)" WHERE("Bank Account No." = FIELD("No."),
                                                                                       "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                       "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                                       Status = FIELD("Status Filter"),
                                                                                       "Category Code" = FIELD("Category Filter"),
                                                                                       "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                       "Due Date" = FIELD("Due Date Filter"),
                                                                                       Type = CONST(Receivable),
                                                                                       "Document Type" = CONST(Bill)));
            Caption = 'Posted Receiv Bills Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000015; "Closed Receiv Bills Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Closed Cartera Doc."."Amt. for Collection (LCY)" WHERE("Bank Account No." = FIELD("No."),
                                                                                       "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                       Status = FIELD("Status Filter"),
                                                                                       "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                       "Due Date" = FIELD("Due Date Filter"),
                                                                                       Type = CONST(Receivable),
                                                                                       "Document Type" = CONST(Bill)));
            Caption = 'Closed Receiv Bills Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000016; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(7000017; "Customer Ratings Code"; Code[20])
        {
            Caption = 'Customer Ratings Code';
            TableRelation = "Bank Account" WHERE("Currency Code" = FIELD("Currency Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = true;
        }
        field(7000018; "Posted Pay. Bills Rmg. Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Remaining Amount" WHERE("Bank Account No." = FIELD("No."),
                                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                              "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                              Status = FIELD("Status Filter"),
                                                                              "Category Code" = FIELD("Category Filter"),
                                                                              "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                              "Due Date" = FIELD("Due Date Filter"),
                                                                              Type = CONST(Payable),
                                                                              "Document Type" = CONST(Bill)));
            Caption = 'Posted Pay. Bills Rmg. Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000019; "Posted Pay. Bills Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Amount for Collection" WHERE("Bank Account No." = FIELD("No."),
                                                                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                                   Status = FIELD("Status Filter"),
                                                                                   "Category Code" = FIELD("Category Filter"),
                                                                                   "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = FIELD("Due Date Filter"),
                                                                                   Type = CONST(Payable),
                                                                                   "Document Type" = CONST(Bill)));
            Caption = 'Posted Pay. Bills Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000020; "Closed Pay. Bills Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Closed Cartera Doc."."Amount for Collection" WHERE("Bank Account No." = FIELD("No."),
                                                                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   Status = FIELD("Status Filter"),
                                                                                   "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = FIELD("Due Date Filter"),
                                                                                   Type = CONST(Payable),
                                                                                   "Document Type" = CONST(Bill)));
            Caption = 'Closed Pay. Bills Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000021; "Posted P.Bills Rmg. Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Remaining Amt. (LCY)" WHERE("Bank Account No." = FIELD("No."),
                                                                                  "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                  "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                  "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                                  Status = FIELD("Status Filter"),
                                                                                  "Category Code" = FIELD("Category Filter"),
                                                                                  "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                  "Due Date" = FIELD("Due Date Filter"),
                                                                                  "Document Type" = CONST(Bill),
                                                                                  Type = CONST(Payable)));
            Caption = 'Posted P.Bills Rmg. Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000022; "Posted Pay. Bills Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Amt. for Collection (LCY)" WHERE("Bank Account No." = FIELD("No."),
                                                                                       "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                       "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                                       Status = FIELD("Status Filter"),
                                                                                       "Category Code" = FIELD("Category Filter"),
                                                                                       "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                       "Due Date" = FIELD("Due Date Filter"),
                                                                                       Type = CONST(Payable),
                                                                                       "Document Type" = CONST(Bill)));
            Caption = 'Posted Pay. Bills Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000023; "Closed Pay. Bills Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Closed Cartera Doc."."Amt. for Collection (LCY)" WHERE("Bank Account No." = FIELD("No."),
                                                                                       "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                       Status = FIELD("Status Filter"),
                                                                                       "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                       "Due Date" = FIELD("Due Date Filter"),
                                                                                       Type = CONST(Payable),
                                                                                       "Document Type" = CONST(Bill)));
            Caption = 'Closed Pay. Bills Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000024; "Post. Receivable Inv. Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Amount for Collection" WHERE("Bank Account No." = FIELD("No."),
                                                                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                                   Status = FIELD("Status Filter"),
                                                                                   "Category Code" = FIELD("Category Filter"),
                                                                                   "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = FIELD("Due Date Filter"),
                                                                                   Type = CONST(Receivable),
                                                                                   "Document Type" = CONST(Invoice)));
            Caption = 'Post. Receivable Inv. Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000025; "Clos. Receivable Inv. Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Closed Cartera Doc."."Amount for Collection" WHERE("Bank Account No." = FIELD("No."),
                                                                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   Status = FIELD("Status Filter"),
                                                                                   "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = FIELD("Due Date Filter"),
                                                                                   Type = CONST(Receivable),
                                                                                   "Document Type" = CONST(Invoice)));
            Caption = 'Clos. Receivable Inv. Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000026; "Posted Pay. Invoices Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Amount for Collection" WHERE("Bank Account No." = FIELD("No."),
                                                                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                                   Status = FIELD("Status Filter"),
                                                                                   "Category Code" = FIELD("Category Filter"),
                                                                                   "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = FIELD("Due Date Filter"),
                                                                                   Type = CONST(Payable),
                                                                                   "Document Type" = CONST(Invoice)));
            Caption = 'Posted Pay. Invoices Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000027; "Closed Pay. Invoices Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Closed Cartera Doc."."Amount for Collection" WHERE("Bank Account No." = FIELD("No."),
                                                                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   Status = FIELD("Status Filter"),
                                                                                   "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = FIELD("Due Date Filter"),
                                                                                   Type = CONST(Payable),
                                                                                   "Document Type" = CONST(Invoice)));
            Caption = 'Closed Pay. Invoices Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000028; "Posted Pay. Inv. Rmg. Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Remaining Amount" WHERE("Bank Account No." = FIELD("No."),
                                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                              "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                              Status = FIELD("Status Filter"),
                                                                              "Category Code" = FIELD("Category Filter"),
                                                                              "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                              "Due Date" = FIELD("Due Date Filter"),
                                                                              Type = CONST(Payable),
                                                                              "Document Type" = CONST(Invoice)));
            Caption = 'Posted Pay. Inv. Rmg. Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000029; "Posted Pay. Documents Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Amount for Collection" WHERE("Bank Account No." = FIELD("No."),
                                                                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   "Dealing Type" = FIELD("Dealing Type Filter"),
                                                                                   Status = FIELD("Status Filter"),
                                                                                   "Category Code" = FIELD("Category Filter"),
                                                                                   "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = FIELD("Due Date Filter"),
                                                                                   Type = CONST(Payable)));
            Caption = 'Posted Pay. Documents Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000030; "Closed Pay. Documents Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Closed Cartera Doc."."Amount for Collection" WHERE("Bank Account No." = FIELD("No."),
                                                                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   Status = FIELD("Status Filter"),
                                                                                   "Honored/Rejtd. at Date" = FIELD("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = FIELD("Due Date Filter"),
                                                                                   Type = CONST(Payable)));
            Caption = 'Closed Pay. Documents Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; "Bank Acc. Posting Group")
        {
        }
        key(Key4; "Currency Code")
        {
        }
        key(Key5; "Country/Region Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, "Bank Account No.", "Currency Code")
        {
        }
        fieldgroup(Brick; "No.", Name, "Bank Account No.", "Currency Code", Image)
        {
        }
    }

    trigger OnDelete()
    var
        DocumentMove: Codeunit "Document-Move";
    begin
        CheckDeleteBalancingBankAccount;

        MoveEntries.MoveBankAccEntries(Rec);
        DocumentMove.MoveBankAccDocs(Rec);

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::"Bank Account");
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll;

        if CarteraSetup.ReadPermission then begin
            Suffix.SetRange("Bank Acc. Code", "No.");
            Suffix.DeleteAll;
        end;

        UpdateContFromBank.OnDelete(Rec);

        DimMgt.DeleteDefaultDim(DATABASE::"Bank Account", "No.");
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            GLSetup.Get;
            GLSetup.TestField("Bank Account Nos.");
            NoSeriesMgt.InitSeries(GLSetup."Bank Account Nos.", xRec."No. Series", 0D, "No.", "No. Series");
            "Operation Fees Code" := "No.";
            "Customer Ratings Code" := "No.";
        end;

        if not InsertFromContact then
            UpdateContFromBank.OnInsert(Rec);

        DimMgt.UpdateDefaultDim(
          DATABASE::"Bank Account", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;

        if IsContactUpdateNeeded then begin
            Modify;
            UpdateContFromBank.OnModify(Rec);
            if not Find then begin
                Reset;
                if Find then;
            end;
        end;
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::"Bank Account", xRec."No.", "No.");
        "Last Date Modified" := Today;
    end;

    var
        Text000: Label 'You cannot change %1 because there are one or more open ledger entries for this bank account.';
        Text003: Label 'Do you wish to create a contact for %1 %2?';
        GLSetup: Record "General Ledger Setup";
        BankAcc: Record "Bank Account";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CommentLine: Record "Comment Line";
        PostCode: Record "Post Code";
        CarteraSetup: Record "Cartera Setup";
        PostedBillGr: Record "Posted Bill Group";
        ClosedBillGr: Record "Closed Bill Group";
        PostedPmtOrd: Record "Posted Payment Order";
        ClosedPmtOrd: Record "Closed Payment Order";
        Suffix: Record Suffix;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        MoveEntries: Codeunit MoveEntries;
        UpdateContFromBank: Codeunit "BankCont-Update";
        DimMgt: Codeunit DimensionManagement;
        InsertFromContact: Boolean;
        Text004: Label 'Before you can use Online Map, you must fill in the Online Map Setup window.\See Setting Up Online Map in Help.';
        Text1100000: Label 'You cannot change %1 because there are one or more posted bill groups for this bank account.';
        Text1100001: Label 'You cannot change %1 because there are one or more posted payment orders for this bank account.';
        BankAccIdentifierIsEmptyErr: Label 'You must specify either a %1 or an %2.';
        InvalidPercentageValueErr: Label 'If %1 is %2, then the value must be between 0 and 99.', Comment = '%1 is "field caption and %2 is "Percentage"';
        InvalidValueErr: Label 'The value must be positive.';
        DataExchNotSetErr: Label 'The Data Exchange Code field must be filled.';
        BankStmtScheduledDownloadDescTxt: Label '%1 Bank Statement Import', Comment = '%1 - Bank Account name';
        JobQEntriesCreatedQst: Label 'A job queue entry for import of bank statements has been created.\\Do you want to open the Job Queue Entry window?';
        TransactionImportTimespanMustBePositiveErr: Label 'The value in the Number of Days Included field must be a positive number not greater than 9999.';
        MFANotSupportedErr: Label 'Cannot setup automatic bank statement import because the selected bank requires multi-factor authentication.';
        BankAccNotLinkedErr: Label 'This bank account is not linked to an online bank account.';
        AutoLogonNotPossibleErr: Label 'Automatic logon is not possible for this bank account.';
        CancelTxt: Label 'Cancel';
        OnlineFeedStatementStatus: Option "Not Linked",Linked,"Linked and Auto. Bank Statement Enabled";
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = caption of field (Last Payment Statement No.)';
        CannotDeleteBalancingBankAccountErr: Label 'You cannot delete bank account that is used as balancing account in the Payment Registration Setup.', Locked = true;
        ConfirmDeleteBalancingBankAccountQst: Label 'This bank account is used as balancing account on the Payment Registration Setup page.\\Are you sure you want to delete it?';

    procedure AssistEdit(OldBankAcc: Record "Bank Account"): Boolean
    begin
        with BankAcc do begin
            BankAcc := Rec;
            GLSetup.Get;
            GLSetup.TestField("Bank Account Nos.");
            if NoSeriesMgt.SelectSeries(GLSetup."Bank Account Nos.", OldBankAcc."No. Series", "No. Series") then begin
                GLSetup.Get;
                GLSetup.TestField("Bank Account Nos.");
                NoSeriesMgt.SetSeries("No.");
                Rec := BankAcc;
                exit(true);
            end;
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Bank Account", "No.", FieldNumber, ShortcutDimCode);
            Modify;
        end;
	
        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowContact()
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
    begin
        if "No." = '' then
            exit;

        ContBusRel.SetCurrentKey("Link to Table", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::"Bank Account");
        ContBusRel.SetRange("No.", "No.");
        if not ContBusRel.FindFirst then begin
            if not Confirm(Text003, false, TableCaption, "No.") then
                exit;
            UpdateContFromBank.InsertNewContact(Rec, false);
            ContBusRel.FindFirst;
        end;
        Commit;

        Cont.FilterGroup(2);
        Cont.SetCurrentKey("Company Name", "Company No.", Type, Name);
        Cont.SetRange("Company No.", ContBusRel."Contact No.");
        PAGE.Run(PAGE::"Contact List", Cont);
    end;

    procedure SetInsertFromContact(FromContact: Boolean)
    begin
        InsertFromContact := FromContact;
    end;

    procedure GetPaymentExportCodeunitID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetBankExportImportSetup(BankExportImportSetup);
        exit(BankExportImportSetup."Processing Codeunit ID");
    end;

    procedure GetPaymentExportXMLPortID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetBankExportImportSetup(BankExportImportSetup);
        BankExportImportSetup.TestField("Processing XMLport ID");
        exit(BankExportImportSetup."Processing XMLport ID");
    end;

    procedure GetDDExportCodeunitID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetDDExportImportSetup(BankExportImportSetup);
        BankExportImportSetup.TestField("Processing Codeunit ID");
        exit(BankExportImportSetup."Processing Codeunit ID");
    end;

    procedure GetDDExportXMLPortID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GetDDExportImportSetup(BankExportImportSetup);
        BankExportImportSetup.TestField("Processing XMLport ID");
        exit(BankExportImportSetup."Processing XMLport ID");
    end;

    procedure GetBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup")
    begin
        TestField("Payment Export Format");
        BankExportImportSetup.Get("Payment Export Format");
    end;

    procedure GetDDExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup")
    begin
        TestField("SEPA Direct Debit Exp. Format");
        BankExportImportSetup.Get("SEPA Direct Debit Exp. Format");
    end;

    procedure GetCreditTransferMessageNo(): Code[20]
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        TestField("Credit Transfer Msg. Nos.");
        exit(NoSeriesManagement.GetNextNo("Credit Transfer Msg. Nos.", Today, true));
    end;

    procedure GetDirectDebitMessageNo(): Code[20]
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        TestField("Direct Debit Msg. Nos.");
        exit(NoSeriesManagement.GetNextNo("Direct Debit Msg. Nos.", Today, true));
    end;

    procedure DisplayMap()
    var
        MapPoint: Record "Online Map Setup";
        MapMgt: Codeunit "Online Map Management";
    begin
        if MapPoint.FindFirst then
            MapMgt.MakeSelection(DATABASE::"Bank Account", GetPosition)
        else
            Message(Text004);
    end;

    [Scope('OnPrem')]
    procedure BuildCCC()
    begin
        "CCC No." := "CCC Bank No." + "CCC Bank Branch No." + "CCC Control Digits" + "CCC Bank Account No.";
        if "CCC No." <> '' then
            TestField("Bank Account No.", '');
    end;

    [Scope('OnPrem')]
    procedure PrePadString(InString: Text[250]; MaxLen: Integer): Text[250]
    begin
        exit(PadStr('', MaxLen - StrLen(InString), '0') + InString);
    end;

    [Scope('OnPrem')]
    procedure DiscInterestsTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Discount Interests Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Discount Interests Amt.");
            exit(PostedBillGr."Discount Interests Amt." + ClosedBillGr."Discount Interests Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure ServicesFeesTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Discount Expenses Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Discount Expenses Amt.");
            exit(PostedBillGr."Discount Expenses Amt." + ClosedBillGr."Discount Expenses Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure CollectionFeesTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Collection Expenses Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Collection Expenses Amt.");
            exit(PostedBillGr."Collection Expenses Amt." + ClosedBillGr."Collection Expenses Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure RejExpensesAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Rejection Expenses Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Rejection Expenses Amt.");
            exit(PostedBillGr."Rejection Expenses Amt." + ClosedBillGr."Rejection Expenses Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure RiskFactFeesTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Risked Factoring Exp. Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Risked Factoring Exp. Amt.");
            exit(PostedBillGr."Risked Factoring Exp. Amt." + ClosedBillGr."Risked Factoring Exp. Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure UnriskFactFeesTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Collection Expenses Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Unrisked Factoring Exp. Amt.");
            exit(PostedBillGr."Unrisked Factoring Exp. Amt." + ClosedBillGr."Unrisked Factoring Exp. Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure DiscInterestFactTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter(Factoring, '<>%1', PostedBillGr.Factoring::" ");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Discount Interests Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter(Factoring, '<>%1', ClosedBillGr.Factoring::" ");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Discount Interests Amt.");
            PostedBillGr.SetRange(Factoring);
            ClosedBillGr.SetRange(Factoring);
            exit(PostedBillGr."Discount Interests Amt." + ClosedBillGr."Discount Interests Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure PaymentOrderFeesTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedPmtOrd.SetCurrentKey("Bank Account No.", "Posting Date");
            PostedPmtOrd.SetRange("Bank Account No.", "No.");
            PostedPmtOrd.SetFilter("Posting Date", PostDateFilter);
            PostedPmtOrd.CalcSums("Payment Order Expenses Amt.");
            ClosedPmtOrd.SetCurrentKey("Bank Account No.", "Posting Date");
            ClosedPmtOrd.SetRange("Bank Account No.", "No.");
            ClosedPmtOrd.SetFilter("Posting Date", PostDateFilter);
            ClosedPmtOrd.CalcSums("Payment Order Expenses Amt.");
            exit(PostedPmtOrd."Payment Order Expenses Amt." + ClosedPmtOrd."Payment Order Expenses Amt.");
        end;
    end;

    procedure GetDataExchDef(var DataExchDef: Record "Data Exch. Def")
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDefCodeResponse: Code[20];
        Handled: Boolean;
    begin
        OnGetDataExchangeDefinitionEvent(DataExchDefCodeResponse, Handled);
        if not Handled then begin
            TestField("Bank Statement Import Format");
            DataExchDefCodeResponse := "Bank Statement Import Format";
        end;

        if DataExchDefCodeResponse = '' then
            Error(DataExchNotSetErr);

        BankExportImportSetup.Get(DataExchDefCodeResponse);
        BankExportImportSetup.TestField("Data Exch. Def. Code");

        DataExchDef.Get(BankExportImportSetup."Data Exch. Def. Code");
        DataExchDef.TestField(Type, DataExchDef.Type::"Bank Statement Import");
    end;

    procedure GetDataExchDefPaymentExport(var DataExchDef: Record "Data Exch. Def")
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        TestField("Payment Export Format");
        BankExportImportSetup.Get("Payment Export Format");
        BankExportImportSetup.TestField("Data Exch. Def. Code");
        DataExchDef.Get(BankExportImportSetup."Data Exch. Def. Code");
        DataExchDef.TestField(Type, DataExchDef.Type::"Payment Export");
    end;

    procedure GetBankAccountNoWithCheck() AccountNo: Text
    begin
        AccountNo := GetBankAccountNo;
        if AccountNo = '' then
            Error(BankAccIdentifierIsEmptyErr, FieldCaption("Bank Account No."), FieldCaption(IBAN));
    end;

    procedure GetBankAccountNo(): Text
    begin
        if IBAN <> '' then
            exit(DelChr(IBAN, '=<>'));

        if "Bank Account No." <> '' then
            exit("Bank Account No.");
    end;

    procedure IsInLocalCurrency(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if "Currency Code" = '' then
            exit(true);

        GeneralLedgerSetup.Get;
        exit("Currency Code" = GeneralLedgerSetup.GetCurrencyCode(''));
    end;

    procedure GetPosPayExportCodeunitID(): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        TestField("Positive Pay Export Code");
        BankExportImportSetup.Get("Positive Pay Export Code");
        exit(BankExportImportSetup."Processing Codeunit ID");
    end;

    procedure IsLinkedToBankStatementServiceProvider(): Boolean
    var
        IsBankAccountLinked: Boolean;
    begin
        OnCheckLinkedToStatementProviderEvent(Rec, IsBankAccountLinked);
        exit(IsBankAccountLinked);
    end;

    procedure StatementProvidersExist(): Boolean
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        OnGetStatementProvidersEvent(TempNameValueBuffer);
        exit(not TempNameValueBuffer.IsEmpty);
    end;

    procedure LinkStatementProvider(var BankAccount: Record "Bank Account")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService;

        if StatementProvider <> '' then
            OnLinkStatementProviderEvent(BankAccount, StatementProvider);
    end;

    procedure SimpleLinkStatementProvider(var OnlineBankAccLink: Record "Online Bank Acc. Link")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService;

        if StatementProvider <> '' then
            OnSimpleLinkStatementProviderEvent(OnlineBankAccLink, StatementProvider);
    end;

    procedure UnlinkStatementProvider()
    var
        Handled: Boolean;
    begin
        OnUnlinkStatementProviderEvent(Rec, Handled);
    end;

    procedure RefreshStatementProvider(var BankAccount: Record "Bank Account")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService;

        if StatementProvider <> '' then
            OnRefreshStatementProviderEvent(BankAccount, StatementProvider);
    end;

    procedure RenewAccessConsentStatementProvider(var BankAccount: Record "Bank Account")
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService;

        if StatementProvider <> '' then
            OnRenewAccessConsentStatementProviderEvent(BankAccount, StatementProvider);
    end;

    procedure UpdateBankAccountLinking()
    var
        StatementProvider: Text;
    begin
        StatementProvider := SelectBankLinkingService;

        if StatementProvider <> '' then
            OnUpdateBankAccountLinkingEvent(Rec, StatementProvider);
    end;

    procedure GetUnlinkedBankAccounts(var TempUnlinkedBankAccount: Record "Bank Account" temporary)
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.FindSet then
            repeat
                if not BankAccount.IsLinkedToBankStatementServiceProvider then begin
                    TempUnlinkedBankAccount := BankAccount;
                    TempUnlinkedBankAccount.Insert;
                end;
            until BankAccount.Next = 0;
    end;

    procedure GetLinkedBankAccounts(var TempUnlinkedBankAccount: Record "Bank Account" temporary)
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.FindSet then
            repeat
                if BankAccount.IsLinkedToBankStatementServiceProvider then begin
                    TempUnlinkedBankAccount := BankAccount;
                    TempUnlinkedBankAccount.Insert;
                end;
            until BankAccount.Next = 0;
    end;

    local procedure SelectBankLinkingService(): Text
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        OptionStr: Text;
        OptionNo: Integer;
    begin
        OnGetStatementProvidersEvent(TempNameValueBuffer);

        if TempNameValueBuffer.IsEmpty then
            exit(''); // Action should not be visible in this case so should not occur

        if (TempNameValueBuffer.Count = 1) or (not GuiAllowed) then
            exit(TempNameValueBuffer.Name);

        TempNameValueBuffer.FindSet;
        repeat
            OptionStr += StrSubstNo('%1,', TempNameValueBuffer.Value);
        until TempNameValueBuffer.Next = 0;
        OptionStr += CancelTxt;

        OptionNo := StrMenu(OptionStr);
        if (OptionNo = 0) or (OptionNo = TempNameValueBuffer.Count + 1) then
            exit;

        TempNameValueBuffer.SetRange(Value, SelectStr(OptionNo, OptionStr));
        TempNameValueBuffer.FindFirst;

        exit(TempNameValueBuffer.Name);
    end;

    procedure IsAutoLogonPossible(): Boolean
    var
        AutoLogonPossible: Boolean;
    begin
        AutoLogonPossible := true;
        OnCheckAutoLogonPossibleEvent(Rec, AutoLogonPossible);
        exit(AutoLogonPossible)
    end;

    local procedure ScheduleBankStatementDownload()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not IsLinkedToBankStatementServiceProvider then
            Error(BankAccNotLinkedErr);
        if not IsAutoLogonPossible then
            Error(AutoLogonNotPossibleErr);

        JobQueueEntry.ScheduleRecurrentJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Automatic Import of Bank Stmt.", RecordId);
        JobQueueEntry.Description :=
          CopyStr(StrSubstNo(BankStmtScheduledDownloadDescTxt, Name), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Notify On Success" := false;
        JobQueueEntry."No. of Minutes between Runs" := 121;
        JobQueueEntry.Modify;
        if Confirm(JobQEntriesCreatedQst) then
            ShowBankStatementDownloadJobQueueEntry;
    end;

    local procedure UnscheduleBankStatementDownload()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SetAutomaticImportJobQueueEntryFilters(JobQueueEntry);
        if not JobQueueEntry.IsEmpty then
            JobQueueEntry.DeleteAll;
    end;

    procedure CreateNewAccount(OnlineBankAccLink: Record "Online Bank Acc. Link")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        GeneralLedgerSetup.Get;
        Init;
        Validate("Bank Account No.", OnlineBankAccLink."Bank Account No.");
        Validate(Name, OnlineBankAccLink.Name);
        if OnlineBankAccLink."Currency Code" <> '' then
            CurrencyCode := GeneralLedgerSetup.GetCurrencyCode(OnlineBankAccLink."Currency Code");
        Validate("Currency Code", CurrencyCode);
        Validate(Contact, OnlineBankAccLink.Contact);
    end;

    local procedure ShowBankStatementDownloadJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SetAutomaticImportJobQueueEntryFilters(JobQueueEntry);
        if JobQueueEntry.FindFirst then
            PAGE.Run(PAGE::"Job Queue Entry Card", JobQueueEntry);
    end;

    local procedure SetAutomaticImportJobQueueEntryFilters(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Automatic Import of Bank Stmt.");
        JobQueueEntry.SetRange("Record ID to Process", RecordId);
    end;

    local procedure CheckDeleteBalancingBankAccount()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.SetRange("Bal. Account Type", PaymentRegistrationSetup."Bal. Account Type"::"Bank Account");
        PaymentRegistrationSetup.SetRange("Bal. Account No.", "No.");
        if PaymentRegistrationSetup.IsEmpty then
            exit;

        if not GuiAllowed then
            Error(CannotDeleteBalancingBankAccountErr);

        if not Confirm(ConfirmDeleteBalancingBankAccountQst) then
            Error('');
    end;

    procedure GetOnlineFeedStatementStatus(var OnlineFeedStatus: Option; var Linked: Boolean)
    begin
        Linked := false;
        OnlineFeedStatus := OnlineFeedStatementStatus::"Not Linked";
        if IsLinkedToBankStatementServiceProvider then begin
            Linked := true;
            OnlineFeedStatus := OnlineFeedStatementStatus::Linked;
            if IsScheduledBankStatement then
                OnlineFeedStatus := OnlineFeedStatementStatus::"Linked and Auto. Bank Statement Enabled";
        end;
    end;

    local procedure IsScheduledBankStatement(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Record ID to Process", RecordId);
        exit(JobQueueEntry.FindFirst);
    end;

    procedure DisableStatementProviders()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
    begin
        OnGetStatementProvidersEvent(TempNameValueBuffer);
        if TempNameValueBuffer.FindSet then
            repeat
                OnDisableStatementProviderEvent(TempNameValueBuffer.Name);
            until TempNameValueBuffer.Next = 0;
    end;

    local procedure IsContactUpdateNeeded(): Boolean
    var
        BankContUpdate: Codeunit "BankCont-Update";
        UpdateNeeded: Boolean;
    begin
        UpdateNeeded :=
          (Name <> xRec.Name) or
          ("Search Name" <> xRec."Search Name") or
          ("Name 2" <> xRec."Name 2") or
          (Address <> xRec.Address) or
          ("Address 2" <> xRec."Address 2") or
          (City <> xRec.City) or
          ("Phone No." <> xRec."Phone No.") or
          ("Telex No." <> xRec."Telex No.") or
          ("Territory Code" <> xRec."Territory Code") or
          ("Currency Code" <> xRec."Currency Code") or
          ("Language Code" <> xRec."Language Code") or
          ("Our Contact Code" <> xRec."Our Contact Code") or
          ("Country/Region Code" <> xRec."Country/Region Code") or
          ("Fax No." <> xRec."Fax No.") or
          ("Telex Answer Back" <> xRec."Telex Answer Back") or
          ("Post Code" <> xRec."Post Code") or
          (County <> xRec.County) or
          ("E-Mail" <> xRec."E-Mail") or
          ("Home Page" <> xRec."Home Page");

        if not UpdateNeeded and not IsTemporary then
            UpdateNeeded := BankContUpdate.ContactNameIsBlank("No.");

        OnAfterIsUpdateNeeded(xRec, Rec, UpdateNeeded);
        exit(UpdateNeeded);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsUpdateNeeded(BankAccount: Record "Bank Account"; xBankAccount: Record "Bank Account"; var UpdateNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var BankAccount: Record "Bank Account"; var xBankAccount: Record "Bank Account"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var BankAccount: Record "Bank Account"; var xBankAccount: Record "Bank Account"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckLinkedToStatementProviderEvent(var BankAccount: Record "Bank Account"; var IsLinked: Boolean)
    begin
        // The subscriber of this event should answer whether the bank account is linked to a bank statement provider service
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAutoLogonPossibleEvent(var BankAccount: Record "Bank Account"; var AutoLogonPossible: Boolean)
    begin
        // The subscriber of this event should answer whether the bank account can be logged on to without multi-factor authentication
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnlinkStatementProviderEvent(var BankAccount: Record "Bank Account"; var Handled: Boolean)
    begin
        // The subscriber of this event should unlink the bank account from a bank statement provider service
    end;

    [IntegrationEvent(false, false)]
    procedure OnMarkAccountLinkedEvent(var OnlineBankAccLink: Record "Online Bank Acc. Link"; var BankAccount: Record "Bank Account")
    begin
        // The subscriber of this event should Mark the account linked to a bank statement provider service
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSimpleLinkStatementProviderEvent(var OnlineBankAccLink: Record "Online Bank Acc. Link"; var StatementProvider: Text)
    begin
        // The subscriber of this event should link the bank account to a bank statement provider service
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkStatementProviderEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // The subscriber of this event should link the bank account to a bank statement provider service
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRefreshStatementProviderEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // The subscriber of this event should refresh the bank account linked to a bank statement provider service
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnGetDataExchangeDefinitionEvent(var DataExchDefCodeResponse: Code[20]; var Handled: Boolean)
    begin
        // This event should retrieve the data exchange definition format for processing the online feeds
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBankAccountLinkingEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // This event should handle updating of the single or multiple bank accounts
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetStatementProvidersEvent(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        // The subscriber of this event should insert a unique identifier (Name) and friendly name of the provider (Value)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisableStatementProviderEvent(ProviderName: Text)
    begin
        // The subscriber of this event should disable the statement provider with the given name
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRenewAccessConsentStatementProviderEvent(var BankAccount: Record "Bank Account"; var StatementProvider: Text)
    begin
        // The subscriber of this event should provide the UI for renewing access consent to the linked open banking bank account
    end;


}

