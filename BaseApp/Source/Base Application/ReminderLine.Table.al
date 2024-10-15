table 296 "Reminder Line"
{
    Caption = 'Reminder Line';

    fields
    {
        field(1; "Reminder No."; Code[20])
        {
            Caption = 'Reminder No.';
            TableRelation = "Reminder Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(3; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
            TableRelation = "Reminder Line"."Line No." WHERE("Reminder No." = FIELD("Reminder No."));
        }
        field(4; Type; Enum "Reminder Source Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                CustPostingGr: Record "Customer Posting Group";
            begin
                if Type <> xRec.Type then begin
                    ReminderLine := Rec;
                    Init;
                    Type := ReminderLine.Type;
                    GetReminderHeader;
                    if Type = Type::"Line Fee" then begin
                        "Line Type" := "Line Type"::"Line Fee";
                        CustPostingGr.Get(ReminderHeader."Customer Posting Group");
                        if CustPostingGr."Add. Fee per Line Account" <> '' then
                            Validate("No.", CustPostingGr."Add. Fee per Line Account");
                    end;
                    DeleteDtldReminderLine; // NAVCZ
                end;
            end;
        }
        field(5; "Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Entry No.';
            TableRelation = "Cust. Ledger Entry";

            trigger OnLookup()
            begin
                if Type <> Type::"Customer Ledger Entry" then
                    exit;
                SetCustLedgEntryView;
                if CustLedgEntry.Get("Entry No.") then;
                LookupCustLedgEntry;
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateEntryNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField(Type, Type::"Customer Ledger Entry");
                GetReminderHeader;
                CustLedgEntry.Get("Entry No.");
                CustLedgEntry.TestField(Open, true);
                CustLedgEntry.TestField("Customer No.", ReminderHeader."Customer No.");
                if CustLedgEntry."Currency Code" <> ReminderHeader."Currency Code" then
                    Error(
                      MustBeSameErr,
                      ReminderHeader.FieldCaption("Currency Code"),
                      ReminderHeader.TableCaption, CustLedgEntry.TableCaption);
                "Posting Date" := CustLedgEntry."Posting Date";
                "Document Date" := CustLedgEntry."Document Date";
                "Due Date" := CustLedgEntry."Due Date";
                "Document Type" := CustLedgEntry."Document Type";
                "Document No." := CustLedgEntry."Document No.";
                Description := CustLedgEntry.Description;
                CustLedgEntry.CalcFields(Amount, "Remaining Amount");
                "Original Amount" := CustLedgEntry.Amount;
                "Remaining Amount" := CustLedgEntry."Remaining Amount";
                OnAfterCopyFromCustLedgEntry(Rec, CustLedgEntry);

                "No. of Reminders" := GetNoOfReminderForCustLedgEntry("Entry No.");

                CalcFinChrg;
            end;
        }
        field(6; "No. of Reminders"; Integer)
        {
            Caption = 'No. of Reminders';

            trigger OnValidate()
            begin
                if Type = Type::"Line Fee" then
                    Validate("Applies-to Document No.");
            end;
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        field(9; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        field(10; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';

            trigger OnValidate()
            begin
                TestField(Type, Type::"Customer Ledger Entry");
                Validate("Document No.");
            end;
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnLookup()
            begin
                LookupDocNo;
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDocumentNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField(Type, Type::"Customer Ledger Entry");
                "Entry No." := 0;
                DeleteDtldReminderLine; // NAVCZ
                if "Document No." <> '' then begin
                    SetCustLedgEntryView;
                    if "Document Type" <> "Document Type"::" " then
                        CustLedgEntry.SetRange("Document Type", "Document Type");
                    CustLedgEntry.SetRange("Document No.", "Document No.");
                    if CustLedgEntry.FindFirst then
                        Validate("Entry No.", CustLedgEntry."Entry No.")
                    else
                        Error(NoOpenEntriesErr, Format(Type), FieldCaption("Document No."), "Document No.");
                end;
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Original Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Original Amount';
            Editable = false;
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Remaining Amount';
            Editable = false;
        }
        field(15; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST(" ")) "Standard Text"
            ELSE
            IF (Type = CONST("G/L Account")) "G/L Account"
            ELSE
            IF (Type = CONST("Line Fee")) "G/L Account";

            trigger OnValidate()
            begin
                if "No." <> '' then
                    case Type of
                        Type::" ":
                            begin
                                StdTxt.Get("No.");
                                Description := StdTxt.Description;
                            end;
                        Type::"Customer Ledger Entry":
                            begin
                                ReminderLine.Type := ReminderLine.Type::" ";
                                ReminderLine2.Type := ReminderLine2.Type::"G/L Account";
                                Error(
                                  MustBeErr,
                                  FieldCaption(Type), ReminderLine.Type, ReminderLine2.Type);
                            end;
                        Type::"G/L Account":
                            FillLineWithGLAccountData("No.");
                        Type::"Line Fee":
                            FillLineWithGLAccountData("No.");
                    end;
            end;
        }
        field(16; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if Type = Type::" " then begin
                    ReminderLine.Type := ReminderLine.Type::"G/L Account";
                    ReminderLine2.Type := ReminderLine.Type::"Customer Ledger Entry";
                    Error(
                      MustBeErr,
                      FieldCaption(Type), ReminderLine.Type, ReminderLine2.Type);
                end;
                if (Type = Type::"Line Fee") and (Amount < 0) then
                    Error(MustBePositiveErr, FieldCaption(Amount));

                GetReminderHeader;
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT",
                    "VAT Calculation Type"::"Full VAT":
                        "VAT Amount" := Amount * ("VAT %" / 100);
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            "VAT Amount" :=
                              SalesTaxCalculate.CalculateTax(
                                ReminderHeader."Tax Area Code", "Tax Group Code", ReminderHeader."Tax Liable",
                                ReminderHeader."Posting Date", Amount, 0, 0);
                            if Amount - "VAT Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / Amount, 0.00001)
                            else
                                "VAT %" := 0;
                        end;
                end;
                "VAT Amount" := Round("VAT Amount", Currency."Amount Rounding Precision");
            end;
        }
        field(17; "Interest Rate"; Decimal)
        {
            Caption = 'Interest Rate';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField(Type, Type::"Customer Ledger Entry");
                TestField("Entry No.");
                CalcFinChrg;
            end;
        }
        field(18; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(19; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(20; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(21; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromHeader;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'VAT Amount';
            Editable = false;
        }
        field(22; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(23; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                GetReminderHeader;
                VATPostingSetup.Get(ReminderHeader."VAT Bus. Posting Group", "VAT Prod. Posting Group");
                OnValidateVATProdPostingGroupOnAfterVATPostingSetupGet(VATPostingSetup, Rec);
                "VAT %" := VATPostingSetup."VAT %";
                "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                "VAT Identifier" := VATPostingSetup."VAT Identifier";
                "VAT Clause Code" := VATPostingSetup."VAT Clause Code";
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        "VAT %" := 0;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            TestField(Type, Type::"G/L Account");
                            TestField("No.", VATPostingSetup.GetSalesAccount(false));
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            "VAT Amount" :=
                              SalesTaxCalculate.CalculateTax(
                                ReminderHeader."Tax Area Code", "Tax Group Code", ReminderHeader."Tax Liable",
                                ReminderHeader."Posting Date", Amount, 0, 0);
                            if Amount - "VAT Amount" <> 0 then
                                "VAT %" := Round(100 * "VAT Amount" / Amount, 0.00001)
                            else
                                "VAT %" := 0;
                            "VAT Amount" := Round("VAT Amount", Currency."Amount Rounding Precision");
                        end;
                end;
                Validate(Amount);
            end;
        }
        field(24; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(25; "Line Type"; Enum "Reminder Line Type")
        {
            Caption = 'Line Type';
        }
        field(26; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(27; "Applies-to Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Document Type';

            trigger OnValidate()
            begin
                TestField(Type, Type::"Line Fee");
                Validate("Applies-to Document No.");
            end;
        }
        field(28; "Applies-to Document No."; Code[20])
        {
            Caption = 'Applies-to Document No.';

            trigger OnLookup()
            begin
                if Type <> Type::"Line Fee" then
                    exit;
                SetCustLedgEntryView;
                if "Applies-to Document Type" <> "Applies-to Document Type"::" " then
                    CustLedgEntry.SetRange("Document Type", "Applies-to Document Type");
                if "Applies-to Document No." <> '' then
                    CustLedgEntry.SetRange("Document No.", "Applies-to Document No.");
                if CustLedgEntry.FindFirst then;
                CustLedgEntry.SetRange("Document Type");
                CustLedgEntry.SetRange("Document No.");
                LookupCustLedgEntry;
            end;

            trigger OnValidate()
            var
                NextLineFeeLevel: Integer;
            begin
                TestField(Type, Type::"Line Fee");
                "Entry No." := 0;
                if "Applies-to Document No." <> '' then begin
                    SetCustLedgEntryView;
                    if "Applies-to Document Type" <> "Applies-to Document Type"::" " then
                        CustLedgEntry.SetRange("Document Type", "Applies-to Document Type");
                    CustLedgEntry.SetRange("Document No.", "Applies-to Document No.");
                    if not CustLedgEntry.FindFirst then
                        Error(NoOpenEntriesErr, CustLedgEntry.TableName, FieldCaption("Document No."), "Applies-to Document No.");
                    "Applies-to Document Type" := CustLedgEntry."Document Type";

                    if CustLedgEntry."Due Date" >= ReminderHeader."Document Date" then
                        Error(EntryNotOverdueErr, CustLedgEntry.FieldCaption("Document No."), "Applies-to Document No.", CustLedgEntry.TableName);

                    if "No. of Reminders" <> 0 then
                        NextLineFeeLevel := "No. of Reminders"
                    else
                        NextLineFeeLevel := GetNoOfReminderForCustLedgEntry(CustLedgEntry."Entry No.");

                    if LineFeeIssuedForReminderLevel(CustLedgEntry, NextLineFeeLevel) then
                        Error(LineFeeAlreadyIssuedErr, "Applies-to Document Type", "Applies-to Document No.", NextLineFeeLevel);

                    GetReminderHeader;
                    if CustLedgEntry."Currency Code" <> ReminderHeader."Currency Code" then
                        Error(
                          MustBeSameErr,
                          ReminderHeader.FieldCaption("Currency Code"),
                          ReminderHeader.TableCaption, CustLedgEntry.TableCaption);

                    GetReminderLevel(ReminderLevel, NextLineFeeLevel, NextLineFeeLevel);
                    "Posting Date" := ReminderHeader."Posting Date";
                    "Document Date" := ReminderHeader."Document Date";
                    "Due Date" := ReminderHeader."Due Date";
                    "No. of Reminders" := NextLineFeeLevel;

                    CustLedgEntry.CalcFields("Remaining Amount");
                    Validate(Amount, ReminderLevel.GetAdditionalFee(
                        CustLedgEntry."Remaining Amount",
                        ReminderHeader."Currency Code",
                        true,
                        ReminderHeader."Posting Date"));

                    Description := '';
                    if (Amount <> 0) and (ReminderLevel."Add. Fee per Line Description" <> '') then
                        Description := StrSubstNo(ReminderLevel."Add. Fee per Line Description",
                            "Reminder No.",
                            "No. of Reminders",
                            "Document Date",
                            "Posting Date",
                            "No.",
                            Amount,
                            "Applies-to Document Type",
                            "Applies-to Document No.",
                            ReminderLevel."No.")
                    else
                        if GLAcc.Get("No.") then
                            Description := GLAcc.Name;
                end;
            end;
        }
        field(30; "Detailed Interest Rates Entry"; Boolean)
        {
            Caption = 'Detailed Interest Rates Entry';
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(11761; Days; Integer)
        {
            Caption = 'Days';
        }
        field(11762; "Multiple Interest Rate"; Decimal)
        {
            Caption = 'Multiple Interest Rate';
        }
        field(11763; "Interest Amount"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum ("Detailed Reminder Line"."Interest Amount" WHERE("Reminder No." = FIELD("Reminder No."),
                                                                                "Reminder Line No." = FIELD("Line No.")));
            Caption = 'Interest Amount';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Reminder No.", "Line No.")
        {
            Clustered = true;
            MaintainSIFTIndex = false;
        }
        key(Key2; "Reminder No.", Type, "Line Type", "Detailed Interest Rates Entry")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key3; "Reminder No.", "Detailed Interest Rates Entry")
        {
            SumIndexFields = Amount, "VAT Amount", "Remaining Amount";
        }
        key(Key4; "Reminder No.", Type)
        {
            SumIndexFields = "VAT Amount";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Reminder No.", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        ReminderLine.SetRange("Reminder No.", "Reminder No.");
        ReminderLine.SetRange("Attached to Line No.", "Line No.");
        ReminderLine.DeleteAll();

        // NAVCZ
        DtldReminderLine.Reset();
        DtldReminderLine.SetRange("Reminder No.", "Reminder No.");
        DtldReminderLine.SetRange("Reminder Line No.", "Line No.");
        DtldReminderLine.DeleteAll();
        // NAVCZ
    end;

    trigger OnInsert()
    begin
        ReminderHeader.Get("Reminder No.");
        "Attached to Line No." := 0;
    end;

    trigger OnModify()
    begin
        TestField("System-Created Entry", false);
    end;

    var
        MustBeSameErr: Label 'The %1 on the %2 and the %3 must be the same.';
        MustBeErr: Label '%1 must be %2 or %3.';
        FinChrgTerms: Record "Finance Charge Terms";
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderLine2: Record "Reminder Line";
        ReminderEntry: Record "Reminder/Fin. Charge Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
        VATPostingSetup: Record "VAT Posting Setup";
        CustPostingGr: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
        StdTxt: Record "Standard Text";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        DtldReminderLine: Record "Detailed Reminder Line";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        InterestCalcDate: Date;
        NoOpenEntriesErr: Label 'There is no open %1 with %2 %3.', Comment = '%1 = Table name, %2 = Document Type, %3 = Document No.';
        EntryNotOverdueErr: Label '%1 %2 in %3 is not overdue.', Comment = '%1 = Document Type, %2 = Document No., %3 = Table name';
        LineFeeAlreadyIssuedErr: Label 'The line fee for %1 %2 on reminder level %3 has already been issued.', Comment = '%1 = Document TYpe, %2 = Document No, %3 = Level number';
        MustBePositiveErr: Label '%1 must be positive.';
        DtldLineNo: Integer;

    local procedure CalcFinChrg()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        OriginalInterestRate: Record "Multiple Interest Rate";
        MultipleInterestCalcLine: Record "Multiple Interest Calc. Line" temporary;
        InterestStartDate: Date;
        LineFee: Decimal;
        IsHandled: Boolean;
        ShouldSkipCalcFinChrg: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcFinChrg(Rec, ReminderHeader, IsHandled);
        if IsHandled then
            exit;

        GetReminderHeader;
        "Interest Rate" := 0;
        Amount := 0;
        "VAT Amount" := 0;
        "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
        "Gen. Prod. Posting Group" := '';
        "VAT Prod. Posting Group" := '';
        CustLedgEntry.Get("Entry No.");
        DeleteDtldReminderLine;
        ShouldSkipCalcFinChrg := (CustLedgEntry."On Hold" <> '') or ("Due Date" >= ReminderHeader."Document Date");
        OnCalcFinChrgOnAfterCalcShouldSkipCalcFinChrg(Rec, ReminderHeader, CustLedgEntry, ShouldSkipCalcFinChrg);
        if ShouldSkipCalcFinChrg then
            exit;

        ReminderLevel.SetRange("Reminder Terms Code", ReminderHeader."Reminder Terms Code");
        if ReminderHeader."Use Header Level" then
            ReminderLevel.SetRange("No.", 1, ReminderHeader."Reminder Level")
        else
            ReminderLevel.SetRange("No.", 1, "No. of Reminders");
        if not ReminderLevel.FindLast then
            ReminderLevel.Init();
        if (not ReminderLevel."Calculate Interest") or (ReminderHeader."Fin. Charge Terms Code" = '') then
            exit;
        FinChrgTerms.Get(ReminderHeader."Fin. Charge Terms Code");
        "Interest Rate" := FinChrgTerms."Interest Rate";
        case FinChrgTerms."Interest Calculation Method" of
            FinChrgTerms."Interest Calculation Method"::"Average Daily Balance":
                begin
                    FinChrgTerms.TestField("Interest Period (Days)");
                    InterestCalcDate := CustLedgEntry."Due Date";
                    ReminderEntry.SetCurrentKey("Customer Entry No.");
                    ReminderEntry.SetRange("Customer Entry No.", "Entry No.");
                    ReminderEntry.SetRange(Type, ReminderEntry.Type::Reminder);
                    ReminderEntry.SetRange("Interest Posted", true);
                    if ReminderEntry.FindLast then
                        InterestCalcDate := ReminderEntry."Document Date";
                    ReminderEntry.SetRange(Type, ReminderEntry.Type::"Finance Charge Memo");
                    ReminderEntry.SetRange("Interest Posted");
                    if ReminderEntry.FindLast then
                        if ReminderEntry."Document Date" > InterestCalcDate then
                            InterestCalcDate := ReminderEntry."Document Date";
                    if InterestCalcDate < ReminderHeader."Document Date" then begin
                        DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
                        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
                        DetailedCustLedgEntry.SetFilter("Entry Type", '%1|%2|%3|%4|%5',
                          DetailedCustLedgEntry."Entry Type"::"Initial Entry",
                          DetailedCustLedgEntry."Entry Type"::Application,
                          DetailedCustLedgEntry."Entry Type"::"Payment Tolerance",
                          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance (VAT Excl.)",
                          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)");
                        DetailedCustLedgEntry.SetRange("Posting Date", 0D, ReminderHeader."Document Date");
                        if DetailedCustLedgEntry.Find('-') then begin
                            FinChrgTerms.FindMultipleInterestRate(CustLedgEntry."Due Date", OriginalInterestRate); // NAVCZ
                            repeat
                                if DetailedCustLedgEntry."Entry Type" = DetailedCustLedgEntry."Entry Type"::"Initial Entry" then
                                    InterestStartDate := CustLedgEntry."Due Date"
                                else
                                    InterestStartDate := DetailedCustLedgEntry."Posting Date";
                                if InterestCalcDate > InterestStartDate then
                                    InterestStartDate := InterestCalcDate;
                                // NAVCZ
                                DtldLineNo := 0;
                                MultipleInterestCalcLine.DeleteAll();
                                FinChrgTerms.SetRatesForCalc(InterestStartDate, ReminderHeader."Document Date", MultipleInterestCalcLine);
                                if MultipleInterestCalcLine.Find('-') then begin
                                    repeat
                                        DtldLineNo := DtldLineNo + 1;
                                        DtldReminderLine.Init();
                                        DtldReminderLine."Reminder No." := ReminderHeader."No.";
                                        DtldReminderLine."Reminder Line No." := "Line No.";
                                        DtldReminderLine."Detailed Customer Entry No." := DetailedCustLedgEntry."Entry No.";
                                        DtldReminderLine."Line No." := DtldLineNo;
                                        DtldReminderLine.Days := MultipleInterestCalcLine.Days;
                                        if OriginalInterestRate."Use Due Date Interest Rate" then
                                            DtldReminderLine."Interest Rate" := OriginalInterestRate."Interest Rate"
                                        else
                                            DtldReminderLine."Interest Rate" := MultipleInterestCalcLine."Interest Rate";
                                        if MultipleInterestCalcLine."Rate Factor" <> 0 then
                                            DtldReminderLine."Interest Amount" :=
                                              Round(
                                                DetailedCustLedgEntry.Amount * DtldReminderLine."Interest Rate" *
                                                MultipleInterestCalcLine.Days / MultipleInterestCalcLine."Rate Factor",
                                                Currency."Amount Rounding Precision")
                                        else
                                            DtldReminderLine."Interest Amount" := 0;
                                        DtldReminderLine."Interest Base Amount" := DetailedCustLedgEntry.Amount;
                                        if DtldReminderLine."Interest Amount" <> 0 then
                                            DtldReminderLine.Insert();
                                    until MultipleInterestCalcLine.Next() = 0
                                end;
                                Amount += DetailedCustLedgEntry.Amount * (ReminderHeader."Document Date" - InterestStartDate); // NAVCZ
                            until DetailedCustLedgEntry.Next() = 0;
                        end;
                        if not FinChrgTerms."Add. Line Fee in Interest" then
                            if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Reminder then
                                if IssuedReminderHeader.Get(CustLedgEntry."Document No.") then begin
                                    IssuedReminderHeader.CalcFields("Add. Fee per Line");
                                    LineFee := IssuedReminderHeader."Add. Fee per Line" + IssuedReminderHeader.CalculateLineFeeVATAmount;
                                    Amount := Amount - LineFee * (ReminderHeader."Document Date" - InterestStartDate);
                                    if Amount < 0 then
                                        Amount := 0;
                                end;
                    end;
                    // NAVCZ
                    DtldReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
                    DtldReminderLine.SetRange("Reminder Line No.", "Line No.");
                    DtldReminderLine.CalcSums("Interest Amount");
                    Amount := DtldReminderLine."Interest Amount";
                    // NAVCZ
                end;
            FinChrgTerms."Interest Calculation Method"::"Balance Due":
                if "Due Date" < ReminderHeader."Document Date" then
                    Amount := "Remaining Amount" * "Interest Rate" / 100;
        end;

        OnCalcFinChrgOnBeforeValidatePostingGroups(Rec, ReminderHeader, Amount);
        if Amount <> 0 then begin
            CustPostingGr.Get(ReminderHeader."Customer Posting Group");
            GLAcc.Get(CustPostingGr.GetInterestAccount);
            GLAcc.TestField("Gen. Prod. Posting Group");
            "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
            Validate("VAT Prod. Posting Group", GLAcc."VAT Prod. Posting Group");
        end;

        OnAfterCalcFinChrg(Rec, ReminderHeader);
    end;

    local procedure SetCustLedgEntryView()
    begin
        GetReminderHeader;
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange("Customer No.", ReminderHeader."Customer No.");
        CustLedgEntry.SetRange(Open, true);

        OnAfterSetCustLedgEntryView(ReminderHeader, Rec, CustLedgEntry);
    end;

    local procedure LookupCustLedgEntry()
    begin
        if PAGE.RunModal(0, CustLedgEntry) = ACTION::LookupOK then
            if Type = Type::"Line Fee" then begin
                Validate("Applies-to Document Type", CustLedgEntry."Document Type");
                Validate("Applies-to Document No.", CustLedgEntry."Document No.");
            end else
                Validate("Entry No.", CustLedgEntry."Entry No.");
    end;

    procedure GetReminderHeader()
    begin
        if "Reminder No." <> ReminderHeader."No." then begin
            ReminderHeader.Get("Reminder No.");
            ProcessReminderHeader;
        end;
    end;

    local procedure ProcessReminderHeader()
    begin
        ReminderHeader.TestField("Customer No.");
        ReminderHeader.TestField("Document Date");
        ReminderHeader.TestField("Customer Posting Group");
        ReminderHeader.TestField("Reminder Terms Code");
        ReminderTerms.Get(ReminderHeader."Reminder Terms Code");
        if ReminderHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else begin
            Currency.Get(ReminderHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure GetCurrencyCodeFromHeader(): Code[10]
    var
        ReminderHeader: Record "Reminder Header";
    begin
        if "Reminder No." = ReminderHeader."No." then
            exit(ReminderHeader."Currency Code");

        if ReminderHeader.Get("Reminder No.") then
            exit(ReminderHeader."Currency Code");

        exit('');
    end;

    local procedure FillLineWithGLAccountData(GLAccountNo: Code[20])
    begin
        GLAcc.Get(GLAccountNo);
        GLAcc.CheckGLAcc;
        if not "System-Created Entry" then
            GLAcc.TestField("Direct Posting", true);
        GLAcc.TestField("Gen. Prod. Posting Group");
        if Description = '' then
            Description := GLAcc.Name;
        GetReminderHeader;
        "Tax Group Code" := GLAcc."Tax Group Code";
        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        Validate("VAT Prod. Posting Group", GLAcc."VAT Prod. Posting Group");

        OnAfterFillLineWithGLAccountData(Rec, ReminderHeader, GLAcc);
    end;

    procedure GetNoOfReminderForCustLedgEntry(EntryNo: Integer): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        NoOfReminders: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNoOfReminderForCustLedgEntry(Rec, NoOfReminders, EntryNo, IsHandled);
        if IsHandled then
            exit(NoOfReminders);

        CustLedgerEntry.Get(EntryNo);
        NoOfReminders := 0;
        ReminderEntry.Reset();
        ReminderEntry.SetCurrentKey("Customer Entry No.");
        ReminderEntry.SetRange("Customer Entry No.", EntryNo);
        ReminderEntry.SetRange(Type, ReminderEntry.Type::Reminder);
        OnGetNoOfReminderForCustLedgEntryOnAfterReminderEntrySetFilters(ReminderEntry);
        if ReminderEntry.FindLast then
            NoOfReminders := ReminderEntry."Reminder Level";
        if (CustLedgerEntry."On Hold" = '') and (CustLedgerEntry."Due Date" < ReminderHeader."Document Date") then
            NoOfReminders := NoOfReminders + 1;

        exit(NoOfReminders);
    end;

    local procedure LineFeeIssuedForReminderLevel(var CustLedgEntry: Record "Cust. Ledger Entry"; IssuedNoOfReminders: Integer): Boolean
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetRange("Applies-To Document Type", CustLedgEntry."Document Type");
        IssuedReminderLine.SetRange("Applies-To Document No.", CustLedgEntry."Document No.");
        IssuedReminderLine.SetRange(Type, IssuedReminderLine.Type::"Line Fee");
        IssuedReminderLine.SetRange("No. of Reminders", IssuedNoOfReminders);
        IssuedReminderLine.SetRange(Canceled, false);
        exit(IssuedReminderLine.FindFirst);
    end;

    local procedure GetReminderLevel(var ReminderLevel: Record "Reminder Level"; LevelStart: Integer; LevelEnd: Integer)
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderHeader."Reminder Terms Code");
        if ReminderHeader."Use Header Level" then
            ReminderLevel.SetRange("No.", LevelStart, ReminderHeader."Reminder Level")
        else
            ReminderLevel.SetRange("No.", LevelStart, LevelEnd);
        if not ReminderLevel.FindLast then
            ReminderLevel.Init();
    end;

    procedure LookupDocNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupDocNo(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type <> Type::"Customer Ledger Entry" then
            exit;

        SetCustLedgEntryView();
        if "Document Type" <> "Document Type"::" " then
            CustLedgEntry.SetRange("Document Type", "Document Type");
        if "Document No." <> '' then
            CustLedgEntry.SetRange("Document No.", "Document No.");
        if CustLedgEntry.FindFirst then;
        CustLedgEntry.SetRange("Document Type");
        CustLedgEntry.SetRange("Document No.");
        LookupCustLedgEntry();
    end;

    [Scope('OnPrem')]
    procedure DeleteDtldReminderLine()
    begin
        // NAVCZ
        DtldReminderLine.Reset();
        DtldReminderLine.SetRange("Reminder No.", "Reminder No.");
        DtldReminderLine.SetRange("Reminder Line No.", "Line No.");
        DtldReminderLine.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromCustLedgEntry(var ReminderLine: Record "Reminder Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcFinChrg(var ReminderLine: Record "Reminder Line"; var ReminderHeader: Record "Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillLineWithGLAccountData(var ReminderLine: Record "Reminder Line"; ReminderHeader: Record "Reminder Header"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCustLedgEntryView(ReminderHeader: Record "Reminder Header"; ReminderLine: Record "Reminder Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcFinChrg(var ReminderLine: Record "Reminder Line"; var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocNo(var ReminderLine: Record "Reminder Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDocumentNo(var ReminderLine: Record "Reminder Line"; var xReminderLine: Record "Reminder Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEntryNo(var ReminderLine: Record "Reminder Line"; var xReminderLine: Record "Reminder Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcFinChrgOnAfterCalcShouldSkipCalcFinChrg(var ReminderLine: Record "Reminder Line"; var ReminderHeader: Record "Reminder Header"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var ShouldSkipCalcFinChrg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcFinChrgOnBeforeValidatePostingGroups(var ReminderLine: Record "Reminder Line"; var ReminderHeader: Record "Reminder Header"; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup"; ReminderLine: Record "Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNoOfReminderForCustLedgEntryOnAfterReminderEntrySetFilters(var ReminderEntry: Record "Reminder/Fin. Charge Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoOfReminderForCustLedgEntry(var ReminderLine: Record "Reminder Line"; var NoOfReminders: Integer; EntryNo: Integer; var IsHandled: Boolean)
    begin
    end;
}

