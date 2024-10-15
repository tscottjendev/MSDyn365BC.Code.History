codeunit 426 "Payment Tolerance Management"
{
    Permissions = TableData Currency = r,
                  TableData "Cust. Ledger Entry" = rim,
                  TableData "Vendor Ledger Entry" = rim,
                  TableData "Gen. Journal Line" = rim,
                  TableData "General Ledger Setup" = r;

    trigger OnRun()
    begin
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        AccTypeOrBalAccTypeIsIncorrectErr: Label 'The value in either the Account Type field or the Bal. Account Type field is wrong.\\ The value must be %1.', Comment = '%1 = Customer or Vendor';
        RefAccountType: Option Customer,Vendor;
        SuppressCommit: Boolean;

    procedure PmtTolCust(var CustLedgEntry: Record "Cust. Ledger Entry"): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        AppliedAmount: Decimal;
        OriginalAppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        AmounttoApply: Decimal;
        PmtDiscAmount: Decimal;
        MaxPmtTolAmount: Decimal;
        CustEntryApplId: Code[50];
        ApplnRoundingPrecision: Decimal;
    begin
        MaxPmtTolAmount := 0;
        PmtDiscAmount := 0;
        ApplyingAmount := 0;
        AmounttoApply := 0;
        AppliedAmount := 0;

        if Customer.Get(CustLedgEntry."Customer No.") then begin
            if Customer."Block Payment Tolerance" then
                exit(true);
        end else
            exit(false);

        GLSetup.Get;

        CustEntryApplId := UserId;
        if CustEntryApplId = '' then
            CustEntryApplId := '***';

        DelCustPmtTolAcc(CustLedgEntry, CustEntryApplId);
        CustLedgEntry.CalcFields("Remaining Amount");
        CalcCustApplnAmount(
          CustLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
          MaxPmtTolAmount, CustEntryApplId, ApplnRoundingPrecision);

        OriginalAppliedAmount := AppliedAmount;

        if GLSetup."Pmt. Disc. Tolerance Warning" then
            if not ManagePaymentDiscToleranceWarningCustomer(CustLedgEntry, CustEntryApplId, AppliedAmount, AmounttoApply, '') then
                exit(false);

        if Abs(AmounttoApply) >= Abs(AppliedAmount - PmtDiscAmount - MaxPmtTolAmount) then begin
            AppliedAmount := AppliedAmount - PmtDiscAmount;
            if (Abs(AppliedAmount) > Abs(AmounttoApply)) and (AppliedAmount * PmtDiscAmount >= 0) then
                AppliedAmount := AmounttoApply;

            if ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <= Abs(MaxPmtTolAmount)) and
               (MaxPmtTolAmount <> 0) and ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <> 0)
               and (Abs(AppliedAmount + ApplyingAmount) > ApplnRoundingPrecision)
            then begin
                if GLSetup."Payment Tolerance Warning" then begin
                    if CallPmtTolWarning(
                         CustLedgEntry."Posting Date", CustLedgEntry."Customer No.", CustLedgEntry."Document No.",
                         CustLedgEntry."Currency Code", ApplyingAmount, OriginalAppliedAmount, RefAccountType::Customer)
                    then begin
                        if ApplyingAmount <> 0 then
                            PutCustPmtTolAmount(CustLedgEntry, ApplyingAmount, AppliedAmount, CustEntryApplId)
                        else
                            DelCustPmtTolAcc2(CustLedgEntry, CustEntryApplId);
                    end else
                        exit(false);
                end else
                    PutCustPmtTolAmount(CustLedgEntry, ApplyingAmount, AppliedAmount, CustEntryApplId);
            end;
        end;
        exit(true);
    end;

    procedure PmtTolVend(var VendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        AppliedAmount: Decimal;
        OriginalAppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        AmounttoApply: Decimal;
        PmtDiscAmount: Decimal;
        MaxPmtTolAmount: Decimal;
        VendEntryApplID: Code[50];
        ApplnRoundingPrecision: Decimal;
    begin
        MaxPmtTolAmount := 0;
        PmtDiscAmount := 0;
        ApplyingAmount := 0;
        AmounttoApply := 0;
        AppliedAmount := 0;
        if Vendor.Get(VendLedgEntry."Vendor No.") then begin
            if Vendor."Block Payment Tolerance" then
                exit(true);
        end else
            exit(false);

        GLSetup.Get;
        VendEntryApplID := UserId;
        if VendEntryApplID = '' then
            VendEntryApplID := '***';

        DelVendPmtTolAcc(VendLedgEntry, VendEntryApplID);
        VendLedgEntry.CalcFields("Remaining Amount");
        CalcVendApplnAmount(
          VendLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
          MaxPmtTolAmount, VendEntryApplID, ApplnRoundingPrecision);

        OriginalAppliedAmount := AppliedAmount;

        if GLSetup."Pmt. Disc. Tolerance Warning" then
            if not ManagePaymentDiscToleranceWarningVendor(VendLedgEntry, VendEntryApplID, AppliedAmount, AmounttoApply, '') then
                exit(false);

        if Abs(AmounttoApply) >= Abs(AppliedAmount - PmtDiscAmount - MaxPmtTolAmount) then begin
            AppliedAmount := AppliedAmount - PmtDiscAmount;
            if (Abs(AppliedAmount) > Abs(AmounttoApply)) and (AppliedAmount * PmtDiscAmount >= 0) then
                AppliedAmount := AmounttoApply;

            if ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <= Abs(MaxPmtTolAmount)) and
               (MaxPmtTolAmount <> 0) and ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <> 0) and
               (Abs(AppliedAmount + ApplyingAmount) > ApplnRoundingPrecision)
            then begin
                if GLSetup."Payment Tolerance Warning" then begin
                    if CallPmtTolWarning(
                         VendLedgEntry."Posting Date", VendLedgEntry."Vendor No.", VendLedgEntry."Document No.",
                         VendLedgEntry."Currency Code", ApplyingAmount, OriginalAppliedAmount, RefAccountType::Vendor)
                    then begin
                        if ApplyingAmount <> 0 then
                            PutVendPmtTolAmount(VendLedgEntry, ApplyingAmount, AppliedAmount, VendEntryApplID)
                        else
                            DelVendPmtTolAcc2(VendLedgEntry, VendEntryApplID);
                    end else
                        exit(false);
                end else
                    PutVendPmtTolAmount(VendLedgEntry, ApplyingAmount, AppliedAmount, VendEntryApplID);
            end;
        end;
        exit(true);
    end;

    procedure PmtTolGenJnl(var NewGenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        GenJnlLine: Record "Gen. Journal Line" temporary;
    begin
        GenJnlLine := NewGenJnlLine;

        if GenJnlLine."Check Printed" then
            exit(true);

        if GenJnlLine."Financial Void" then
            exit(true);

        if (GenJnlLine."Applies-to Doc. No." = '') and (GenJnlLine."Applies-to ID" = '') then
            exit(true);

        case true of
            (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer) or
          (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer):
                exit(SalesPmtTolGenJnl(GenJnlLine));
            (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor) or
          (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor):
                exit(PurchPmtTolGenJnl(GenJnlLine));
        end;
    end;

    local procedure SalesPmtTolGenJnl(var GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        NewCustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        GenJnlLineApplID: Code[50];
    begin
        if IsCustBlockPmtToleranceInGenJnlLine(GenJnlLine) then
            exit(false);

        GenJnlLineApplID := GetAppliesToID(GenJnlLine);

        NewCustLedgEntry."Posting Date" := GenJnlLine."Posting Date";
        NewCustLedgEntry."Document No." := GenJnlLine."Document No.";
        NewCustLedgEntry."Customer No." := GenJnlLine."Account No.";
        NewCustLedgEntry."Currency Code" := GenJnlLine."Currency Code";
        if GenJnlLine."Applies-to Doc. No." <> '' then
            NewCustLedgEntry."Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
        if not GenJnlPostPreview.IsActive then
            DelCustPmtTolAcc(NewCustLedgEntry, GenJnlLineApplID);
        NewCustLedgEntry.Amount := GenJnlLine.Amount;
        NewCustLedgEntry."Remaining Amount" := GenJnlLine.Amount;
        NewCustLedgEntry."Document Type" := GenJnlLine."Document Type";
        exit(
          PmtTolCustLedgEntry(NewCustLedgEntry, GenJnlLine."Account No.", GenJnlLine."Posting Date",
            GenJnlLine."Document No.", GenJnlLineApplID, GenJnlLine."Applies-to Doc. No.",
            GenJnlLine."Currency Code"));
    end;

    local procedure PurchPmtTolGenJnl(var GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        NewVendLedgEntry: Record "Vendor Ledger Entry";
        GenJnlLineApplID: Code[50];
    begin
        if IsVendBlockPmtToleranceInGenJnlLine(GenJnlLine) then
            exit(false);

        GenJnlLineApplID := GetAppliesToID(GenJnlLine);

        NewVendLedgEntry."Posting Date" := GenJnlLine."Posting Date";
        NewVendLedgEntry."Document No." := GenJnlLine."Document No.";
        NewVendLedgEntry."Vendor No." := GenJnlLine."Account No.";
        NewVendLedgEntry."Currency Code" := GenJnlLine."Currency Code";
        if GenJnlLine."Applies-to Doc. No." <> '' then
            NewVendLedgEntry."Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
        DelVendPmtTolAcc(NewVendLedgEntry, GenJnlLineApplID);
        NewVendLedgEntry.Amount := GenJnlLine.Amount;
        NewVendLedgEntry."Remaining Amount" := GenJnlLine.Amount;
        NewVendLedgEntry."Document Type" := GenJnlLine."Document Type";
        exit(
          PmtTolVendLedgEntry(
            NewVendLedgEntry, GenJnlLine."Account No.", GenJnlLine."Posting Date",
            GenJnlLine."Document No.", GenJnlLineApplID, GenJnlLine."Applies-to Doc. No.",
            GenJnlLine."Currency Code"));
    end;

    procedure PmtTolPmtReconJnl(var NewBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Boolean
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine := NewBankAccReconciliationLine;

        case BankAccReconciliationLine."Account Type" of
            BankAccReconciliationLine."Account Type"::Customer:
                exit(SalesPmtTolPmtReconJnl(BankAccReconciliationLine));
            BankAccReconciliationLine."Account Type"::Vendor:
                exit(PurchPmtTolPmtReconJnl(BankAccReconciliationLine));
        end;
    end;

    local procedure SalesPmtTolPmtReconJnl(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Boolean
    var
        NewCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        BankAccReconciliationLine.TestField("Account Type", BankAccReconciliationLine."Account Type"::Customer);

        if IsCustBlockPmtTolerance(BankAccReconciliationLine."Account No.") then
            exit(false);

        NewCustLedgEntry."Posting Date" := BankAccReconciliationLine."Transaction Date";
        NewCustLedgEntry."Document No." := BankAccReconciliationLine."Document No.";
        NewCustLedgEntry."Customer No." := BankAccReconciliationLine."Account No.";
        DelCustPmtTolAcc(NewCustLedgEntry, BankAccReconciliationLine.GetAppliesToID);
        NewCustLedgEntry.Amount := -BankAccReconciliationLine."Statement Amount";
        NewCustLedgEntry."Remaining Amount" := -BankAccReconciliationLine."Statement Amount";
        NewCustLedgEntry."Document Type" := NewCustLedgEntry."Document Type"::Payment;

        exit(
          PmtTolCustLedgEntry(
            NewCustLedgEntry, BankAccReconciliationLine."Account No.", BankAccReconciliationLine."Transaction Date",
            BankAccReconciliationLine."Statement No.", BankAccReconciliationLine.GetAppliesToID, '',
            ''));
    end;

    local procedure PurchPmtTolPmtReconJnl(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Boolean
    var
        NewVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        BankAccReconciliationLine.TestField("Account Type", BankAccReconciliationLine."Account Type"::Vendor);

        if IsVendBlockPmtTolerance(BankAccReconciliationLine."Account No.") then
            exit(false);

        NewVendLedgEntry."Posting Date" := BankAccReconciliationLine."Transaction Date";
        NewVendLedgEntry."Document No." := BankAccReconciliationLine."Document No.";
        NewVendLedgEntry."Vendor No." := BankAccReconciliationLine."Account No.";
        DelVendPmtTolAcc(NewVendLedgEntry, BankAccReconciliationLine.GetAppliesToID);
        NewVendLedgEntry.Amount := -BankAccReconciliationLine."Statement Amount";
        NewVendLedgEntry."Remaining Amount" := -BankAccReconciliationLine."Statement Amount";
        NewVendLedgEntry."Document Type" := NewVendLedgEntry."Document Type"::Payment;

        exit(
          PmtTolVendLedgEntry(
            NewVendLedgEntry, BankAccReconciliationLine."Account No.", BankAccReconciliationLine."Transaction Date",
            BankAccReconciliationLine."Statement No.", BankAccReconciliationLine.GetAppliesToID, '',
            ''));
    end;

    local procedure PmtTolCustLedgEntry(var NewCustLedgEntry: Record "Cust. Ledger Entry"; AccountNo: Code[20]; PostingDate: Date; DocNo: Code[20]; AppliesToID: Code[50]; AppliesToDocNo: Code[20]; CurrencyCode: Code[10]): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        AppliedAmount: Decimal;
        OriginalAppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        AmounttoApply: Decimal;
        PmtDiscAmount: Decimal;
        MaxPmtTolAmount: Decimal;
        ApplnRoundingPrecision: Decimal;
    begin
        GLSetup.Get;
        CalcCustApplnAmount(
          NewCustLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
          MaxPmtTolAmount, AppliesToID, ApplnRoundingPrecision);

        OriginalAppliedAmount := AppliedAmount;

        if GLSetup."Pmt. Disc. Tolerance Warning" then
            if not ManagePaymentDiscToleranceWarningCustomer(NewCustLedgEntry, AppliesToID, AppliedAmount, AmounttoApply, AppliesToDocNo) then
                exit(false);

        if Abs(AmounttoApply) >= Abs(AppliedAmount - PmtDiscAmount - MaxPmtTolAmount) then begin
            AppliedAmount := AppliedAmount - PmtDiscAmount;
            if (Abs(AppliedAmount) > Abs(AmounttoApply)) and (AppliedAmount * PmtDiscAmount > 0) then
                AppliedAmount := AmounttoApply;

            if ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <= Abs(MaxPmtTolAmount)) and
               (MaxPmtTolAmount <> 0) and ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <> 0) and
               (Abs(AppliedAmount + ApplyingAmount) > ApplnRoundingPrecision)
            then
                if GLSetup."Payment Tolerance Warning" then
                    if CallPmtTolWarning(
                         PostingDate, AccountNo, DocNo,
                         CurrencyCode, ApplyingAmount, OriginalAppliedAmount, RefAccountType::Customer)
                    then begin
                        if ApplyingAmount <> 0 then
                            PutCustPmtTolAmount(NewCustLedgEntry, ApplyingAmount, AppliedAmount, AppliesToID)
                        else
                            DelCustPmtTolAcc(NewCustLedgEntry, AppliesToID);
                    end else begin
                        DelCustPmtTolAcc(NewCustLedgEntry, AppliesToID);
                        exit(false);
                    end
                else
                    PutCustPmtTolAmount(NewCustLedgEntry, ApplyingAmount, AppliedAmount, AppliesToID);
        end;
        exit(true);
    end;

    local procedure PmtTolVendLedgEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry"; AccountNo: Code[20]; PostingDate: Date; DocNo: Code[20]; AppliesToID: Code[50]; AppliesToDocNo: Code[20]; CurrencyCode: Code[10]): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        AppliedAmount: Decimal;
        OriginalAppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        AmounttoApply: Decimal;
        PmtDiscAmount: Decimal;
        MaxPmtTolAmount: Decimal;
        ApplnRoundingPrecision: Decimal;
    begin
        GLSetup.Get;
        CalcVendApplnAmount(
          NewVendLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
          MaxPmtTolAmount, AppliesToID, ApplnRoundingPrecision);

        OriginalAppliedAmount := AppliedAmount;

        if GLSetup."Pmt. Disc. Tolerance Warning" then
            if not ManagePaymentDiscToleranceWarningVendor(NewVendLedgEntry, AppliesToID, AppliedAmount, AmounttoApply, AppliesToDocNo) then
                exit(false);

        if Abs(AmounttoApply) >= Abs(AppliedAmount - PmtDiscAmount - MaxPmtTolAmount) then begin
            AppliedAmount := AppliedAmount - PmtDiscAmount;
            if (Abs(AppliedAmount) > Abs(AmounttoApply)) and (AppliedAmount * PmtDiscAmount > 0) then
                AppliedAmount := AmounttoApply;

            if ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <= Abs(MaxPmtTolAmount)) and
               (MaxPmtTolAmount <> 0) and ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <> 0) and
               (Abs(AppliedAmount + ApplyingAmount) > ApplnRoundingPrecision)
            then
                if GLSetup."Payment Tolerance Warning" then
                    if CallPmtTolWarning(
                         PostingDate, AccountNo, DocNo, CurrencyCode, ApplyingAmount, OriginalAppliedAmount, RefAccountType::Vendor)
                    then begin
                        if ApplyingAmount <> 0 then
                            PutVendPmtTolAmount(NewVendLedgEntry, ApplyingAmount, AppliedAmount, AppliesToID)
                        else
                            DelVendPmtTolAcc(NewVendLedgEntry, AppliesToID);
                    end else begin
                        DelVendPmtTolAcc(NewVendLedgEntry, AppliesToID);
                        exit(false);
                    end
                else
                    PutVendPmtTolAmount(NewVendLedgEntry, ApplyingAmount, AppliedAmount, AppliesToID);
        end;
        exit(true);
    end;

    local procedure CalcCustApplnAmount(CustledgEntry: Record "Cust. Ledger Entry"; GLSetup: Record "General Ledger Setup"; var AppliedAmount: Decimal; var ApplyingAmount: Decimal; var AmounttoApply: Decimal; var PmtDiscAmount: Decimal; var MaxPmtTolAmount: Decimal; CustEntryApplID: Code[50]; var ApplnRoundingPrecision: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        AppliedCustLedgEntryTemp: Record "Cust. Ledger Entry" temporary;
        CustLedgEntry2: Record "Cust. Ledger Entry";
        ApplnCurrencyCode: Code[10];
        ApplnDate: Date;
        AmountRoundingPrecision: Decimal;
        TempAmount: Decimal;
        i: Integer;
        PositiveFilter: Boolean;
        SetPositiveFilter: Boolean;
        ApplnInMultiCurrency: Boolean;
        UseDisc: Boolean;
        RemainingPmtDiscPossible: Decimal;
        AvailableAmount: Decimal;
    begin
        ApplnCurrencyCode := CustledgEntry."Currency Code";
        ApplnDate := CustledgEntry."Posting Date";
        ApplnRoundingPrecision := GLSetup."Appln. Rounding Precision";
        AmountRoundingPrecision := GLSetup."Amount Rounding Precision";

        if CustEntryApplID <> '' then begin
            AppliedCustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open, Positive);
            AppliedCustLedgEntry.SetRange("Customer No.", CustledgEntry."Customer No.");
            AppliedCustLedgEntry.SetRange("Applies-to ID", CustEntryApplID);
            AppliedCustLedgEntry.SetRange(Open, true);
            CustLedgEntry2 := CustledgEntry;
            PositiveFilter := CustledgEntry."Remaining Amount" < 0;
            AppliedCustLedgEntry.SetRange(Positive, PositiveFilter);
            if CustledgEntry."Entry No." <> 0 then
                AppliedCustLedgEntry.SetFilter("Entry No.", '<>%1', CustledgEntry."Entry No.");

            // Find Application Rounding Precision
            GetCustApplicationRoundingPrecisionForAppliesToID(
              AppliedCustLedgEntry, ApplnRoundingPrecision, AmountRoundingPrecision, ApplnInMultiCurrency, ApplnCurrencyCode);

            if AppliedCustLedgEntry.Find('-') then begin
                ApplyingAmount := CustledgEntry."Remaining Amount";
                TempAmount := CustledgEntry."Remaining Amount";
                AppliedCustLedgEntry.SetRange(Positive);
                AppliedCustLedgEntry.Find('-');
                repeat
                    UpdateCustAmountsForApplication(AppliedCustLedgEntry, CustledgEntry, AppliedCustLedgEntryTemp);
                    CheckCustPaymentAmountsForAppliesToID(
                      CustledgEntry, AppliedCustLedgEntry, AppliedCustLedgEntryTemp, MaxPmtTolAmount, AvailableAmount, TempAmount,
                      ApplnRoundingPrecision);
                until AppliedCustLedgEntry.Next = 0;

                TempAmount := TempAmount + MaxPmtTolAmount;

                PositiveFilter := GetCustPositiveFilter(CustledgEntry."Document Type", TempAmount);
                SetPositiveFilter := true;
                AppliedCustLedgEntry.SetRange(Positive, PositiveFilter);
            end else
                AppliedCustLedgEntry.SetRange(Positive);

            if CustledgEntry."Entry No." <> 0 then
                AppliedCustLedgEntry.SetRange("Entry No.");

            for i := 1 to 2 do begin
                if SetPositiveFilter then begin
                    if i = 2 then
                        AppliedCustLedgEntry.SetRange(Positive, not PositiveFilter);
                end else
                    i := 2;

                with AppliedCustLedgEntry do begin
                    if Find('-') then
                        repeat
                            CalcFields("Remaining Amount");
                            AppliedCustLedgEntryTemp := AppliedCustLedgEntry;
                            if "Currency Code" <> ApplnCurrencyCode then begin
                                "Remaining Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    ApplnDate, "Currency Code", ApplnCurrencyCode, "Remaining Amount");
                                "Remaining Pmt. Disc. Possible" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    ApplnDate, "Currency Code", ApplnCurrencyCode, "Remaining Pmt. Disc. Possible");
                                "Max. Payment Tolerance" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    ApplnDate, "Currency Code", ApplnCurrencyCode, "Max. Payment Tolerance");
                                "Amount to Apply" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    ApplnDate, "Currency Code", ApplnCurrencyCode, "Amount to Apply");
                            end;
                            // Check Payment Discount
                            UseDisc := false;
                            if CheckCalcPmtDiscCust(
                                 CustLedgEntry2, AppliedCustLedgEntry, ApplnRoundingPrecision, false, false) and
                               (((CustledgEntry.Amount > 0) and (i = 1)) or
                                (("Remaining Amount" < 0) and (i = 1)) or
                                (Abs(Abs(CustLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                                   Abs("Remaining Amount")) >= Abs("Remaining Pmt. Disc. Possible" + "Max. Payment Tolerance")) or
                                (Abs(Abs(CustLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                                   Abs("Remaining Amount")) <= Abs("Remaining Pmt. Disc. Possible" + MaxPmtTolAmount)))
                            then begin
                                PmtDiscAmount := PmtDiscAmount + "Remaining Pmt. Disc. Possible";
                                UseDisc := true;
                            end;

                            // Check Payment Discount Tolerance
                            if "Amount to Apply" = "Remaining Amount" then
                                AvailableAmount := CustLedgEntry2."Remaining Amount"
                            else
                                AvailableAmount := -"Amount to Apply";
                            if CheckPmtDiscTolCust(CustLedgEntry2."Posting Date",
                                 CustledgEntry."Document Type", AvailableAmount,
                                 AppliedCustLedgEntry, ApplnRoundingPrecision, MaxPmtTolAmount) and
                               (((CustledgEntry.Amount > 0) and (i = 1)) or
                                (("Remaining Amount" < 0) and (i = 1)) or
                                (Abs(Abs(CustLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                                   Abs("Remaining Amount")) >= Abs("Remaining Pmt. Disc. Possible" + "Max. Payment Tolerance")) or
                                (Abs(Abs(CustLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                                   Abs("Remaining Amount")) <= Abs("Remaining Pmt. Disc. Possible" + MaxPmtTolAmount)))
                            then begin
                                PmtDiscAmount := PmtDiscAmount + "Remaining Pmt. Disc. Possible";
                                UseDisc := true;
                                "Accepted Pmt. Disc. Tolerance" := true;
                                if CustledgEntry."Currency Code" <> "Currency Code" then begin
                                    RemainingPmtDiscPossible := "Remaining Pmt. Disc. Possible";
                                    "Remaining Pmt. Disc. Possible" := AppliedCustLedgEntryTemp."Remaining Pmt. Disc. Possible";
                                    "Max. Payment Tolerance" := AppliedCustLedgEntryTemp."Max. Payment Tolerance";
                                end;
                                Modify;
                                if CustledgEntry."Currency Code" <> "Currency Code" then
                                    "Remaining Pmt. Disc. Possible" := RemainingPmtDiscPossible;
                            end;

                            if CustledgEntry."Entry No." <> "Entry No." then begin
                                MaxPmtTolAmount := Round(MaxPmtTolAmount, AmountRoundingPrecision);
                                PmtDiscAmount := Round(PmtDiscAmount, AmountRoundingPrecision);
                                AppliedAmount := AppliedAmount + Round("Remaining Amount", AmountRoundingPrecision);
                                if UseDisc then begin
                                    AmounttoApply :=
                                      AmounttoApply +
                                      Round(
                                        ABSMinTol(
                                          "Remaining Amount" -
                                          "Remaining Pmt. Disc. Possible",
                                          "Amount to Apply",
                                          MaxPmtTolAmount),
                                        AmountRoundingPrecision);
                                    CustLedgEntry2."Remaining Amount" :=
                                      CustLedgEntry2."Remaining Amount" +
                                      Round("Remaining Amount" - "Remaining Pmt. Disc. Possible", AmountRoundingPrecision)
                                end else begin
                                    AmounttoApply := AmounttoApply + Round("Amount to Apply", AmountRoundingPrecision);
                                    CustLedgEntry2."Remaining Amount" :=
                                      CustLedgEntry2."Remaining Amount" + Round("Remaining Amount", AmountRoundingPrecision);
                                end;
                                if CustledgEntry."Remaining Amount" > 0 then begin
                                    CustledgEntry."Remaining Amount" := CustledgEntry."Remaining Amount" + "Remaining Amount";
                                    if CustledgEntry."Remaining Amount" < 0 then
                                        CustledgEntry."Remaining Amount" := 0;
                                end;
                                if CustledgEntry."Remaining Amount" < 0 then begin
                                    CustledgEntry."Remaining Amount" := CustledgEntry."Remaining Amount" + "Remaining Amount";
                                    if CustledgEntry."Remaining Amount" > 0 then
                                        CustledgEntry."Remaining Amount" := 0;
                                end;
                            end else
                                ApplyingAmount := "Remaining Amount";
                        until Next = 0;

                    if not SuppressCommit then
                        Commit;
                end;
            end;
        end else
            if CustledgEntry."Applies-to Doc. No." <> '' then begin
                AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open);
                AppliedCustLedgEntry.SetRange("Customer No.", CustledgEntry."Customer No.");
                AppliedCustLedgEntry.SetRange(Open, true);
                AppliedCustLedgEntry.SetRange("Document No.", CustledgEntry."Applies-to Doc. No.");
                if AppliedCustLedgEntry.Find('-') then begin
                    GetApplicationRoundingPrecisionForAppliesToDoc(
                      AppliedCustLedgEntry."Currency Code", ApplnRoundingPrecision, AmountRoundingPrecision, ApplnCurrencyCode);
                    UpdateCustAmountsForApplication(AppliedCustLedgEntry, CustledgEntry, AppliedCustLedgEntryTemp);
                    CheckCustPaymentAmountsForAppliesToDoc(
                      CustledgEntry, AppliedCustLedgEntry, AppliedCustLedgEntryTemp, MaxPmtTolAmount, ApplnRoundingPrecision, PmtDiscAmount,
                      ApplnCurrencyCode);
                    MaxPmtTolAmount := Round(MaxPmtTolAmount, AmountRoundingPrecision);
                    PmtDiscAmount := Round(PmtDiscAmount, AmountRoundingPrecision);
                    AppliedAmount := Round(AppliedCustLedgEntry."Remaining Amount", AmountRoundingPrecision);
                    AmounttoApply := Round(AppliedCustLedgEntry."Amount to Apply", AmountRoundingPrecision);
                end;
                ApplyingAmount := CustledgEntry.Amount;
            end;
    end;

    local procedure CalcVendApplnAmount(VendledgEntry: Record "Vendor Ledger Entry"; GLSetup: Record "General Ledger Setup"; var AppliedAmount: Decimal; var ApplyingAmount: Decimal; var AmounttoApply: Decimal; var PmtDiscAmount: Decimal; var MaxPmtTolAmount: Decimal; VendEntryApplID: Code[50]; var ApplnRoundingPrecision: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
        AppliedVendLedgEntryTemp: Record "Vendor Ledger Entry" temporary;
        VendLedgEntry2: Record "Vendor Ledger Entry";
        ApplnCurrencyCode: Code[10];
        ApplnDate: Date;
        AmountRoundingPrecision: Decimal;
        TempAmount: Decimal;
        i: Integer;
        PositiveFilter: Boolean;
        SetPositiveFilter: Boolean;
        ApplnInMultiCurrency: Boolean;
        RemainingPmtDiscPossible: Decimal;
        UseDisc: Boolean;
        AvailableAmount: Decimal;
    begin
        ApplnCurrencyCode := VendledgEntry."Currency Code";
        ApplnDate := VendledgEntry."Posting Date";
        ApplnRoundingPrecision := GLSetup."Appln. Rounding Precision";
        AmountRoundingPrecision := GLSetup."Amount Rounding Precision";

        if VendEntryApplID <> '' then begin
            AppliedVendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive);
            AppliedVendLedgEntry.SetRange("Vendor No.", VendledgEntry."Vendor No.");
            AppliedVendLedgEntry.SetRange("Applies-to ID", VendEntryApplID);
            AppliedVendLedgEntry.SetRange(Open, true);
            VendLedgEntry2 := VendledgEntry;
            PositiveFilter := VendledgEntry."Remaining Amount" > 0;
            AppliedVendLedgEntry.SetRange(Positive, not PositiveFilter);

            if VendledgEntry."Entry No." <> 0 then
                AppliedVendLedgEntry.SetFilter("Entry No.", '<>%1', VendledgEntry."Entry No.");
            GetVendApplicationRoundingPrecisionForAppliesToID(AppliedVendLedgEntry,
              ApplnRoundingPrecision, AmountRoundingPrecision, ApplnInMultiCurrency, ApplnCurrencyCode);
            if AppliedVendLedgEntry.Find('-') then begin
                ApplyingAmount := VendledgEntry."Remaining Amount";
                TempAmount := VendledgEntry."Remaining Amount";
                AppliedVendLedgEntry.SetRange(Positive);
                AppliedVendLedgEntry.Find('-');
                repeat
                    UpdateVendAmountsForApplication(AppliedVendLedgEntry, VendledgEntry, AppliedVendLedgEntryTemp);
                    CheckVendPaymentAmountsForAppliesToID(
                      VendledgEntry, AppliedVendLedgEntry, AppliedVendLedgEntryTemp, MaxPmtTolAmount, AvailableAmount, TempAmount,
                      ApplnRoundingPrecision);
                until AppliedVendLedgEntry.Next = 0;

                TempAmount := TempAmount + MaxPmtTolAmount;
                PositiveFilter := GetVendPositiveFilter(VendledgEntry."Document Type", TempAmount);
                SetPositiveFilter := true;
                AppliedVendLedgEntry.SetRange(Positive, not PositiveFilter);
            end else
                AppliedVendLedgEntry.SetRange(Positive);

            if VendledgEntry."Entry No." <> 0 then
                AppliedVendLedgEntry.SetRange("Entry No.");

            for i := 1 to 2 do begin
                if SetPositiveFilter then begin
                    if i = 2 then
                        AppliedVendLedgEntry.SetRange(Positive, PositiveFilter);
                end else
                    i := 2;

                with AppliedVendLedgEntry do begin
                    if Find('-') then
                        repeat
                            CalcFields("Remaining Amount");
                            AppliedVendLedgEntryTemp := AppliedVendLedgEntry;
                            if "Currency Code" <> ApplnCurrencyCode then begin
                                "Remaining Amount" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    ApplnDate, "Currency Code", ApplnCurrencyCode, "Remaining Amount");
                                "Remaining Pmt. Disc. Possible" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    ApplnDate, "Currency Code", ApplnCurrencyCode, "Remaining Pmt. Disc. Possible");
                                "Max. Payment Tolerance" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    ApplnDate, "Currency Code", ApplnCurrencyCode, "Max. Payment Tolerance");
                                "Amount to Apply" :=
                                  CurrExchRate.ExchangeAmtFCYToFCY(
                                    ApplnDate, "Currency Code", ApplnCurrencyCode, "Amount to Apply");
                            end;
                            // Check Payment Discount
                            UseDisc := false;
                            if CheckCalcPmtDiscVend(
                                 VendLedgEntry2, AppliedVendLedgEntry, ApplnRoundingPrecision, false, false) and
                               (((VendledgEntry.Amount < 0) and (i = 1)) or
                                (("Remaining Amount" > 0) and (i = 1)) or
                                (Abs(Abs(VendLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                                   Abs("Remaining Amount")) >= Abs("Remaining Pmt. Disc. Possible" + "Max. Payment Tolerance")) or
                                (Abs(Abs(VendLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                                   Abs("Remaining Amount")) <= Abs("Remaining Pmt. Disc. Possible" + MaxPmtTolAmount)))
                            then begin
                                PmtDiscAmount := PmtDiscAmount + "Remaining Pmt. Disc. Possible";
                                UseDisc := true;
                            end;

                            // Check Payment Discount Tolerance
                            if "Amount to Apply" = "Remaining Amount" then
                                AvailableAmount := VendLedgEntry2."Remaining Amount"
                            else
                                AvailableAmount := -"Amount to Apply";

                            if CheckPmtDiscTolVend(
                                 VendLedgEntry2."Posting Date", VendledgEntry."Document Type", AvailableAmount,
                                 AppliedVendLedgEntry, ApplnRoundingPrecision, MaxPmtTolAmount) and
                               (((VendledgEntry.Amount < 0) and (i = 1)) or
                                (("Remaining Amount" > 0) and (i = 1)) or
                                (Abs(Abs(VendLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                                   Abs("Remaining Amount")) >= Abs("Remaining Pmt. Disc. Possible" + "Max. Payment Tolerance")) or
                                (Abs(Abs(VendLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                                   Abs("Remaining Amount")) <= Abs("Remaining Pmt. Disc. Possible" + MaxPmtTolAmount)))
                            then begin
                                PmtDiscAmount := PmtDiscAmount + "Remaining Pmt. Disc. Possible";
                                UseDisc := true;
                                "Accepted Pmt. Disc. Tolerance" := true;
                                if VendledgEntry."Currency Code" <> "Currency Code" then begin
                                    RemainingPmtDiscPossible := "Remaining Pmt. Disc. Possible";
                                    "Remaining Pmt. Disc. Possible" := AppliedVendLedgEntryTemp."Remaining Pmt. Disc. Possible";
                                    "Max. Payment Tolerance" := AppliedVendLedgEntryTemp."Max. Payment Tolerance";
                                end;
                                Modify;
                                if VendledgEntry."Currency Code" <> "Currency Code" then
                                    "Remaining Pmt. Disc. Possible" := RemainingPmtDiscPossible;
                            end;

                            if VendledgEntry."Entry No." <> "Entry No." then begin
                                PmtDiscAmount := Round(PmtDiscAmount, AmountRoundingPrecision);
                                MaxPmtTolAmount := Round(MaxPmtTolAmount, AmountRoundingPrecision);
                                AppliedAmount := AppliedAmount + Round("Remaining Amount", AmountRoundingPrecision);
                                if UseDisc then begin
                                    AmounttoApply :=
                                      AmounttoApply +
                                      Round(
                                        ABSMinTol(
                                          "Remaining Amount" -
                                          "Remaining Pmt. Disc. Possible",
                                          "Amount to Apply",
                                          MaxPmtTolAmount),
                                        AmountRoundingPrecision);
                                    VendLedgEntry2."Remaining Amount" :=
                                      VendLedgEntry2."Remaining Amount" +
                                      Round("Remaining Amount" - "Remaining Pmt. Disc. Possible", AmountRoundingPrecision)
                                end else begin
                                    AmounttoApply := AmounttoApply + Round("Amount to Apply", AmountRoundingPrecision);
                                    VendLedgEntry2."Remaining Amount" :=
                                      VendLedgEntry2."Remaining Amount" + Round("Remaining Amount", AmountRoundingPrecision);
                                end;
                                if VendledgEntry."Remaining Amount" > 0 then begin
                                    VendledgEntry."Remaining Amount" := VendledgEntry."Remaining Amount" + "Remaining Amount";
                                    if VendledgEntry."Remaining Amount" < 0 then
                                        VendledgEntry."Remaining Amount" := 0;
                                end;
                                if VendledgEntry."Remaining Amount" < 0 then begin
                                    VendledgEntry."Remaining Amount" := VendledgEntry."Remaining Amount" + "Remaining Amount";
                                    if VendledgEntry."Remaining Amount" > 0 then
                                        VendledgEntry."Remaining Amount" := 0;
                                end;
                            end else
                                ApplyingAmount := "Remaining Amount";
                        until Next = 0;

                    if not SuppressCommit then
                        Commit;
                end;
            end;
        end else
            if VendledgEntry."Applies-to Doc. No." <> '' then begin
                AppliedVendLedgEntry.SetCurrentKey("Vendor No.", Open);
                AppliedVendLedgEntry.SetRange("Vendor No.", VendledgEntry."Vendor No.");
                AppliedVendLedgEntry.SetRange(Open, true);
                AppliedVendLedgEntry.SetRange("Document No.", VendledgEntry."Applies-to Doc. No.");
                if AppliedVendLedgEntry.Find('-') then begin
                    GetApplicationRoundingPrecisionForAppliesToDoc(
                      AppliedVendLedgEntry."Currency Code", ApplnRoundingPrecision, AmountRoundingPrecision, ApplnCurrencyCode);
                    UpdateVendAmountsForApplication(AppliedVendLedgEntry, VendledgEntry, AppliedVendLedgEntryTemp);
                    CheckVendPaymentAmountsForAppliesToDoc(VendledgEntry, AppliedVendLedgEntry, AppliedVendLedgEntryTemp, MaxPmtTolAmount,
                      ApplnRoundingPrecision, PmtDiscAmount);
                    PmtDiscAmount := Round(PmtDiscAmount, AmountRoundingPrecision);
                    MaxPmtTolAmount := Round(MaxPmtTolAmount, AmountRoundingPrecision);
                    AppliedAmount := Round(AppliedVendLedgEntry."Remaining Amount", AmountRoundingPrecision);
                    AmounttoApply := Round(AppliedVendLedgEntry."Amount to Apply", AmountRoundingPrecision);
                end;
                ApplyingAmount := VendledgEntry.Amount;
            end;
    end;

    local procedure CheckPmtDiscTolCust(NewPostingdate: Date; NewDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; NewAmount: Decimal; OldCustLedgEntry: Record "Cust. Ledger Entry"; ApplnRoundingPrecision: Decimal; MaxPmtTolAmount: Decimal): Boolean
    var
        ToleranceAmount: Decimal;
    begin
        if ((NewDocType = NewDocType::Payment) and
            ((OldCustLedgEntry."Document Type" in [OldCustLedgEntry."Document Type"::Invoice,
                                                   OldCustLedgEntry."Document Type"::"Credit Memo"]) and
             (NewPostingdate > OldCustLedgEntry."Pmt. Discount Date") and
             (NewPostingdate <= OldCustLedgEntry."Pmt. Disc. Tolerance Date"))) or
           ((NewDocType = NewDocType::Refund) and
            ((OldCustLedgEntry."Document Type" = OldCustLedgEntry."Document Type"::"Credit Memo") and
             (NewPostingdate > OldCustLedgEntry."Pmt. Discount Date") and
             (NewPostingdate <= OldCustLedgEntry."Pmt. Disc. Tolerance Date")))
        then begin
            ToleranceAmount := (Abs(NewAmount) + ApplnRoundingPrecision) -
              Abs(OldCustLedgEntry."Remaining Amount" - OldCustLedgEntry."Remaining Pmt. Disc. Possible");
            exit((ToleranceAmount >= 0) or (Abs(MaxPmtTolAmount) >= Abs(ToleranceAmount)));
        end;
        exit(false);
    end;

    local procedure CheckPmtTolCust(NewDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; OldCustLedgEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        if ((NewDocType = NewDocType::Payment) and
            (OldCustLedgEntry."Document Type" = OldCustLedgEntry."Document Type"::Invoice)) or
           ((NewDocType = NewDocType::Refund) and
            (OldCustLedgEntry."Document Type" = OldCustLedgEntry."Document Type"::"Credit Memo"))
        then
            exit(true);

        exit(false);
    end;

    local procedure CheckPmtDiscTolVend(NewPostingdate: Date; NewDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; NewAmount: Decimal; OldVendLedgEntry: Record "Vendor Ledger Entry"; ApplnRoundingPrecision: Decimal; MaxPmtTolAmount: Decimal): Boolean
    var
        ToleranceAmount: Decimal;
    begin
        if ((NewDocType = NewDocType::Payment) and
            ((OldVendLedgEntry."Document Type" in [OldVendLedgEntry."Document Type"::Invoice,
                                                   OldVendLedgEntry."Document Type"::"Credit Memo"]) and
             (NewPostingdate > OldVendLedgEntry."Pmt. Discount Date") and
             (NewPostingdate <= OldVendLedgEntry."Pmt. Disc. Tolerance Date"))) or
           ((NewDocType = NewDocType::Refund) and
            ((OldVendLedgEntry."Document Type" = OldVendLedgEntry."Document Type"::"Credit Memo") and
             (NewPostingdate > OldVendLedgEntry."Pmt. Discount Date") and
             (NewPostingdate <= OldVendLedgEntry."Pmt. Disc. Tolerance Date")))
        then begin
            ToleranceAmount := (Abs(NewAmount) + ApplnRoundingPrecision) -
              Abs(OldVendLedgEntry."Remaining Amount" - OldVendLedgEntry."Remaining Pmt. Disc. Possible");
            exit((ToleranceAmount >= 0) or (Abs(MaxPmtTolAmount) >= Abs(ToleranceAmount)));
        end;
        exit(false);
    end;

    local procedure CheckPmtTolVend(NewDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; OldVendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        if ((NewDocType = NewDocType::Payment) and
            (OldVendLedgEntry."Document Type" = OldVendLedgEntry."Document Type"::Invoice)) or
           ((NewDocType = NewDocType::Refund) and
            (OldVendLedgEntry."Document Type" = OldVendLedgEntry."Document Type"::"Credit Memo"))
        then
            exit(true);

        exit(false);
    end;

    local procedure CallPmtDiscTolWarning(PostingDate: Date; No: Code[20]; DocNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; AppliedAmount: Decimal; PmtDiscAmount: Decimal; var RemainingAmountTest: Boolean; AccountType: Option Customer,Vendor): Boolean
    var
        PmtDiscTolWarning: Page "Payment Disc Tolerance Warning";
        ActionType: Integer;
    begin
        if PmtDiscAmount = 0 then begin
            RemainingAmountTest := false;
            exit(true);
        end;
        if SuppressCommit then
            exit(true);

        PmtDiscTolWarning.SetValues(PostingDate, No, DocNo, CurrencyCode, Amount, AppliedAmount, PmtDiscAmount);
        PmtDiscTolWarning.SetAccountName(GetAccountName(AccountType, No));
        PmtDiscTolWarning.LookupMode(true);
        if ACTION::Yes = PmtDiscTolWarning.RunModal then begin
            PmtDiscTolWarning.GetValues(ActionType);
            if ActionType = 2 then
                RemainingAmountTest := true
            else
                RemainingAmountTest := false;
        end else
            exit(false);
        exit(true);
    end;

    local procedure CallPmtTolWarning(PostingDate: Date; No: Code[20]; DocNo: Code[20]; CurrencyCode: Code[10]; var Amount: Decimal; AppliedAmount: Decimal; AccountType: Option Customer,Vendor): Boolean
    var
        PmtTolWarning: Page "Payment Tolerance Warning";
        ActionType: Integer;
    begin
        if SuppressCommit then
            exit(true);

        PmtTolWarning.SetValues(PostingDate, No, DocNo, CurrencyCode, Amount, AppliedAmount, 0);
        PmtTolWarning.SetAccountName(GetAccountName(AccountType, No));
        PmtTolWarning.LookupMode(true);
        if ACTION::Yes = PmtTolWarning.RunModal then begin
            PmtTolWarning.GetValues(ActionType);
            if ActionType = 2 then
                Amount := 0;
        end else
            exit(false);
        exit(true);
    end;

    local procedure PutCustPmtTolAmount(CustledgEntry: Record "Cust. Ledger Entry"; Amount: Decimal; AppliedAmount: Decimal; CustEntryApplID: Code[50])
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        AppliedCustLedgEntryTemp: Record "Cust. Ledger Entry";
        Currency: Record Currency;
        Number: Integer;
        AcceptedTolAmount: Decimal;
        AcceptedEntryTolAmount: Decimal;
        TotalAmount: Decimal;
    begin
        AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
        AppliedCustLedgEntry.SetRange("Customer No.", CustledgEntry."Customer No.");
        AppliedCustLedgEntry.SetRange(Open, true);

        if CustledgEntry."Applies-to Doc. No." <> '' then
            AppliedCustLedgEntry.SetRange("Document No.", CustledgEntry."Applies-to Doc. No.")
        else
            AppliedCustLedgEntry.SetRange("Applies-to ID", CustEntryApplID);

        if CustledgEntry."Document Type" = CustledgEntry."Document Type"::Payment then
            AppliedCustLedgEntry.SetRange(Positive, true)
        else
            AppliedCustLedgEntry.SetRange(Positive, false);
        if AppliedCustLedgEntry.FindSet(false, false) then
            repeat
                if AppliedCustLedgEntry."Max. Payment Tolerance" <> 0 then begin
                    AppliedCustLedgEntry.CalcFields(Amount);
                    if CustledgEntry."Currency Code" <> AppliedCustLedgEntry."Currency Code" then
                        AppliedCustLedgEntry.Amount :=
                          CurrExchRate.ExchangeAmount(
                            AppliedCustLedgEntry.Amount,
                            AppliedCustLedgEntry."Currency Code",
                            CustledgEntry."Currency Code", CustledgEntry."Posting Date");
                    TotalAmount := TotalAmount + AppliedCustLedgEntry.Amount;
                end;
            until AppliedCustLedgEntry.Next = 0;

        AppliedCustLedgEntry.LockTable;

        AcceptedTolAmount := Amount + AppliedAmount;
        Number := AppliedCustLedgEntry.Count;

        if AppliedCustLedgEntry.Find('-') then
            repeat
                AppliedCustLedgEntry.CalcFields("Remaining Amount");
                AppliedCustLedgEntryTemp := AppliedCustLedgEntry;
                if AppliedCustLedgEntry."Currency Code" = '' then begin
                    Currency.Init;
                    Currency.Code := '';
                    Currency.InitRoundingPrecision;
                end else
                    if AppliedCustLedgEntry."Currency Code" <> Currency.Code then
                        Currency.Get(AppliedCustLedgEntry."Currency Code");
                if Number <> 1 then begin
                    AppliedCustLedgEntry.CalcFields(Amount);
                    if CustledgEntry."Currency Code" <> AppliedCustLedgEntry."Currency Code" then
                        AppliedCustLedgEntry.Amount :=
                          CurrExchRate.ExchangeAmount(
                            AppliedCustLedgEntry.Amount,
                            AppliedCustLedgEntry."Currency Code",
                            CustledgEntry."Currency Code", CustledgEntry."Posting Date");
                    AcceptedEntryTolAmount := Round((AppliedCustLedgEntry.Amount / TotalAmount) * AcceptedTolAmount);
                    TotalAmount := TotalAmount - AppliedCustLedgEntry.Amount;
                    AcceptedTolAmount := AcceptedTolAmount - AcceptedEntryTolAmount;
                    AppliedCustLedgEntry."Accepted Payment Tolerance" := AcceptedEntryTolAmount;
                end else begin
                    AcceptedEntryTolAmount := AcceptedTolAmount;
                    AppliedCustLedgEntry."Accepted Payment Tolerance" := AcceptedEntryTolAmount;
                end;
                AppliedCustLedgEntry."Max. Payment Tolerance" := AppliedCustLedgEntryTemp."Max. Payment Tolerance";
                AppliedCustLedgEntry."Amount to Apply" := AppliedCustLedgEntryTemp."Remaining Amount";
                AppliedCustLedgEntry.Modify;
                Number := Number - 1;
            until AppliedCustLedgEntry.Next = 0;

        if not SuppressCommit then
            Commit;
    end;

    local procedure PutVendPmtTolAmount(VendLedgEntry: Record "Vendor Ledger Entry"; Amount: Decimal; AppliedAmount: Decimal; VendEntryApplID: Code[50])
    var
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
        AppliedVendLedgEntryTemp: Record "Vendor Ledger Entry";
        Currency: Record Currency;
        Number: Integer;
        AcceptedTolAmount: Decimal;
        AcceptedEntryTolAmount: Decimal;
        TotalAmount: Decimal;
    begin
        AppliedVendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
        AppliedVendLedgEntry.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
        AppliedVendLedgEntry.SetRange(Open, true);

        if VendLedgEntry."Applies-to Doc. No." <> '' then
            AppliedVendLedgEntry.SetRange("Document No.", VendLedgEntry."Applies-to Doc. No.")
        else
            AppliedVendLedgEntry.SetRange("Applies-to ID", VendEntryApplID);

        if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Payment then
            AppliedVendLedgEntry.SetRange(Positive, false)
        else
            AppliedVendLedgEntry.SetRange(Positive, true);
        if AppliedVendLedgEntry.FindSet(false, false) then
            repeat
                if AppliedVendLedgEntry."Max. Payment Tolerance" <> 0 then begin
                    AppliedVendLedgEntry.CalcFields(Amount);
                    if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then
                        AppliedVendLedgEntry.Amount :=
                          CurrExchRate.ExchangeAmount(
                            AppliedVendLedgEntry.Amount,
                            AppliedVendLedgEntry."Currency Code",
                            VendLedgEntry."Currency Code", VendLedgEntry."Posting Date");
                    TotalAmount := TotalAmount + AppliedVendLedgEntry.Amount;
                end;
            until AppliedVendLedgEntry.Next = 0;

        AppliedVendLedgEntry.LockTable;

        AcceptedTolAmount := Amount + AppliedAmount;
        Number := AppliedVendLedgEntry.Count;

        if AppliedVendLedgEntry.Find('-') then
            repeat
                AppliedVendLedgEntry.CalcFields("Remaining Amount");
                AppliedVendLedgEntryTemp := AppliedVendLedgEntry;
                if AppliedVendLedgEntry."Currency Code" = '' then begin
                    Currency.Init;
                    Currency.Code := '';
                    Currency.InitRoundingPrecision;
                end else
                    if AppliedVendLedgEntry."Currency Code" <> Currency.Code then
                        Currency.Get(AppliedVendLedgEntry."Currency Code");
                if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then
                    AppliedVendLedgEntry."Max. Payment Tolerance" :=
                      CurrExchRate.ExchangeAmount(
                        AppliedVendLedgEntry."Max. Payment Tolerance",
                        AppliedVendLedgEntry."Currency Code",
                        VendLedgEntry."Currency Code", VendLedgEntry."Posting Date");
                if Number <> 1 then begin
                    AppliedVendLedgEntry.CalcFields(Amount);
                    if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then
                        AppliedVendLedgEntry.Amount :=
                          CurrExchRate.ExchangeAmount(
                            AppliedVendLedgEntry.Amount,
                            AppliedVendLedgEntry."Currency Code",
                            VendLedgEntry."Currency Code", VendLedgEntry."Posting Date");
                    AcceptedEntryTolAmount := Round((AppliedVendLedgEntry.Amount / TotalAmount) * AcceptedTolAmount);
                    TotalAmount := TotalAmount - AppliedVendLedgEntry.Amount;
                    AcceptedTolAmount := AcceptedTolAmount - AcceptedEntryTolAmount;
                    AppliedVendLedgEntry."Accepted Payment Tolerance" := AcceptedEntryTolAmount;
                end else begin
                    AcceptedEntryTolAmount := AcceptedTolAmount;
                    AppliedVendLedgEntry."Accepted Payment Tolerance" := AcceptedEntryTolAmount;
                end;
                AppliedVendLedgEntry."Max. Payment Tolerance" := AppliedVendLedgEntryTemp."Max. Payment Tolerance";
                AppliedVendLedgEntry."Amount to Apply" := AppliedVendLedgEntryTemp."Remaining Amount";
                AppliedVendLedgEntry.Modify;
                Number := Number - 1;
            until AppliedVendLedgEntry.Next = 0;

        if not SuppressCommit then
            Commit;
    end;

    local procedure DelCustPmtTolAcc(CustledgEntry: Record "Cust. Ledger Entry"; CustEntryApplID: Code[50])
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if CustledgEntry."Applies-to Doc. No." <> '' then begin
            AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
            AppliedCustLedgEntry.SetRange("Customer No.", CustledgEntry."Customer No.");
            AppliedCustLedgEntry.SetRange(Open, true);
            AppliedCustLedgEntry.SetRange("Document No.", CustledgEntry."Applies-to Doc. No.");
            AppliedCustLedgEntry.LockTable;
            if AppliedCustLedgEntry.Find('-') then begin
                AppliedCustLedgEntry."Accepted Payment Tolerance" := 0;
                AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                AppliedCustLedgEntry.Modify;
                if not SuppressCommit then
                    Commit;
            end;
        end;

        if CustEntryApplID <> '' then begin
            AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
            AppliedCustLedgEntry.SetRange("Customer No.", CustledgEntry."Customer No.");
            AppliedCustLedgEntry.SetRange(Open, true);
            AppliedCustLedgEntry.SetRange("Applies-to ID", CustEntryApplID);
            AppliedCustLedgEntry.LockTable;
            if AppliedCustLedgEntry.Find('-') then begin
                repeat
                    AppliedCustLedgEntry."Accepted Payment Tolerance" := 0;
                    AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                    AppliedCustLedgEntry.Modify;
                until AppliedCustLedgEntry.Next = 0;
                if not SuppressCommit then
                    Commit;
            end;
        end;
    end;

    local procedure DelVendPmtTolAcc(VendLedgEntry: Record "Vendor Ledger Entry"; VendEntryApplID: Code[50])
    var
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if VendLedgEntry."Applies-to Doc. No." <> '' then begin
            AppliedVendLedgEntry.SetCurrentKey("Document No.");
            AppliedVendLedgEntry.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
            AppliedVendLedgEntry.SetRange(Open, true);
            AppliedVendLedgEntry.SetRange("Document No.", VendLedgEntry."Applies-to Doc. No.");
            AppliedVendLedgEntry.LockTable;
            if AppliedVendLedgEntry.FindFirst then begin
                AppliedVendLedgEntry."Accepted Payment Tolerance" := 0;
                AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                AppliedVendLedgEntry.Modify;
                if not SuppressCommit then
                    Commit;
            end;
        end;

        if VendEntryApplID <> '' then begin
            AppliedVendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
            AppliedVendLedgEntry.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
            AppliedVendLedgEntry.SetRange(Open, true);
            AppliedVendLedgEntry.SetRange("Applies-to ID", VendEntryApplID);
            AppliedVendLedgEntry.LockTable;
            if not AppliedVendLedgEntry.IsEmpty then begin
                AppliedVendLedgEntry.ModifyAll("Accepted Payment Tolerance", 0);
                AppliedVendLedgEntry.ModifyAll("Accepted Pmt. Disc. Tolerance", false);
                if not SuppressCommit then
                    Commit;
            end;
        end;
    end;

    procedure CalcGracePeriodCVLedgEntry(PmtTolGracePeriode: DateFormula)
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        Customer.SetCurrentKey("No.");
        CustLedgEntry.LockTable;
        Customer.LockTable;
        if Customer.Find('-') then
            repeat
                if not Customer."Block Payment Tolerance" then begin
                    CustLedgEntry.SetCurrentKey("Customer No.", Open);
                    CustLedgEntry.SetRange("Customer No.", Customer."No.");
                    CustLedgEntry.SetRange(Open, true);
                    CustLedgEntry.SetFilter("Document Type", '%1|%2',
                      CustLedgEntry."Document Type"::Invoice,
                      CustLedgEntry."Document Type"::"Credit Memo");

                    if CustLedgEntry.Find('-') then
                        repeat
                            if CustLedgEntry."Pmt. Discount Date" <> 0D then begin
                                if CustLedgEntry."Pmt. Discount Date" <> CustLedgEntry."Document Date" then
                                    CustLedgEntry."Pmt. Disc. Tolerance Date" :=
                                      CalcDate(PmtTolGracePeriode, CustLedgEntry."Pmt. Discount Date")
                                else
                                    CustLedgEntry."Pmt. Disc. Tolerance Date" :=
                                      CustLedgEntry."Pmt. Discount Date";
                            end else
                                CustLedgEntry."Pmt. Disc. Tolerance Date" := 0D;
                            CustLedgEntry.Modify;
                        until CustLedgEntry.Next = 0;
                end;
            until Customer.Next = 0;

        Vendor.SetCurrentKey("No.");
        VendLedgEntry.LockTable;
        Vendor.LockTable;
        if Vendor.Find('-') then
            repeat
                if not Vendor."Block Payment Tolerance" then begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", Open);
                    VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
                    VendLedgEntry.SetRange(Open, true);
                    VendLedgEntry.SetFilter("Document Type", '%1|%2',
                      VendLedgEntry."Document Type"::Invoice,
                      VendLedgEntry."Document Type"::"Credit Memo");

                    if VendLedgEntry.Find('-') then
                        repeat
                            if VendLedgEntry."Pmt. Discount Date" <> 0D then begin
                                if VendLedgEntry."Pmt. Disc. Tolerance Date" <>
                                   VendLedgEntry."Document Date"
                                then
                                    VendLedgEntry."Pmt. Disc. Tolerance Date" :=
                                      CalcDate(PmtTolGracePeriode, VendLedgEntry."Pmt. Discount Date")
                                else
                                    VendLedgEntry."Pmt. Disc. Tolerance Date" :=
                                      VendLedgEntry."Pmt. Discount Date";
                            end else
                                VendLedgEntry."Pmt. Disc. Tolerance Date" := 0D;
                            VendLedgEntry.Modify;
                        until VendLedgEntry.Next = 0;
                end;
            until Vendor.Next = 0;
    end;

    procedure CalcTolCustLedgEntry(Customer: Record Customer)
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        GLSetup.Get;
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.LockTable;
        if not CustLedgEntry.Find('-') then
            exit;
        repeat
            if (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice) or
               (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo")
            then begin
                CustLedgEntry.CalcFields(Amount, "Amount (LCY)");
                if CustLedgEntry."Pmt. Discount Date" >= CustLedgEntry."Posting Date" then
                    CustLedgEntry."Pmt. Disc. Tolerance Date" :=
                      CalcDate(GLSetup."Payment Discount Grace Period", CustLedgEntry."Pmt. Discount Date");
                if CustLedgEntry."Currency Code" = '' then begin
                    if (GLSetup."Max. Payment Tolerance Amount" <
                        Abs(GLSetup."Payment Tolerance %" / 100 * CustLedgEntry."Amount (LCY)")) or (GLSetup."Payment Tolerance %" = 0)
                    then begin
                        if (GLSetup."Max. Payment Tolerance Amount" = 0) and (GLSetup."Payment Tolerance %" > 0) then
                            CustLedgEntry."Max. Payment Tolerance" :=
                              GLSetup."Payment Tolerance %" * CustLedgEntry."Amount (LCY)" / 100
                        else
                            if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo" then
                                CustLedgEntry."Max. Payment Tolerance" := -GLSetup."Max. Payment Tolerance Amount"
                            else
                                CustLedgEntry."Max. Payment Tolerance" := GLSetup."Max. Payment Tolerance Amount"
                    end else
                        CustLedgEntry."Max. Payment Tolerance" :=
                          GLSetup."Payment Tolerance %" * CustLedgEntry."Amount (LCY)" / 100
                end else begin
                    Currency.Get(CustLedgEntry."Currency Code");
                    if (Currency."Max. Payment Tolerance Amount" <
                        Abs(Currency."Payment Tolerance %" / 100 * CustLedgEntry.Amount)) or (Currency."Payment Tolerance %" = 0)
                    then begin
                        if (Currency."Max. Payment Tolerance Amount" = 0) and (Currency."Payment Tolerance %" > 0) then
                            CustLedgEntry."Max. Payment Tolerance" :=
                              Round(Currency."Payment Tolerance %" * CustLedgEntry.Amount / 100, Currency."Amount Rounding Precision")
                        else
                            if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo" then
                                CustLedgEntry."Max. Payment Tolerance" := -Currency."Max. Payment Tolerance Amount"
                            else
                                CustLedgEntry."Max. Payment Tolerance" := Currency."Max. Payment Tolerance Amount"
                    end else
                        CustLedgEntry."Max. Payment Tolerance" :=
                          Round(Currency."Payment Tolerance %" * CustLedgEntry.Amount / 100, Currency."Amount Rounding Precision");
                end;
            end;
            if Abs(CustLedgEntry.Amount) < Abs(CustLedgEntry."Max. Payment Tolerance") then
                CustLedgEntry."Max. Payment Tolerance" := CustLedgEntry.Amount;
            OnCalcTolCustLedgEntryOnBeforeModify(CustLedgEntry);
            CustLedgEntry.Modify;
        until CustLedgEntry.Next = 0;
    end;

    procedure DelTolCustLedgEntry(Customer: Record Customer)
    var
        GLSetup: Record "General Ledger Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        GLSetup.Get;
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.LockTable;
        if not CustLedgEntry.Find('-') then
            exit;
        repeat
            CustLedgEntry."Pmt. Disc. Tolerance Date" := 0D;
            CustLedgEntry."Max. Payment Tolerance" := 0;
            CustLedgEntry.Modify;
        until CustLedgEntry.Next = 0;
    end;

    procedure CalcTolVendLedgEntry(Vendor: Record Vendor)
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        GLSetup.Get;
        VendLedgEntry.SetCurrentKey("Vendor No.", Open);
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.LockTable;
        if not VendLedgEntry.Find('-') then
            exit;
        repeat
            if (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice) or
               (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo")
            then begin
                VendLedgEntry.CalcFields(Amount, "Amount (LCY)");
                if VendLedgEntry."Pmt. Discount Date" >= VendLedgEntry."Posting Date" then
                    VendLedgEntry."Pmt. Disc. Tolerance Date" :=
                      CalcDate(GLSetup."Payment Discount Grace Period", VendLedgEntry."Pmt. Discount Date");
                if VendLedgEntry."Currency Code" = '' then begin
                    if (GLSetup."Max. Payment Tolerance Amount" <
                        Abs(GLSetup."Payment Tolerance %" / 100 * VendLedgEntry."Amount (LCY)")) or (GLSetup."Payment Tolerance %" = 0)
                    then begin
                        if (GLSetup."Max. Payment Tolerance Amount" = 0) and (GLSetup."Payment Tolerance %" > 0) then
                            VendLedgEntry."Max. Payment Tolerance" :=
                              GLSetup."Payment Tolerance %" * VendLedgEntry."Amount (LCY)" / 100
                        else
                            if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo" then
                                VendLedgEntry."Max. Payment Tolerance" := GLSetup."Max. Payment Tolerance Amount"
                            else
                                VendLedgEntry."Max. Payment Tolerance" := -GLSetup."Max. Payment Tolerance Amount"
                    end else
                        VendLedgEntry."Max. Payment Tolerance" :=
                          GLSetup."Payment Tolerance %" * VendLedgEntry."Amount (LCY)" / 100
                end else begin
                    Currency.Get(VendLedgEntry."Currency Code");
                    if (Currency."Max. Payment Tolerance Amount" <
                        Abs(Currency."Payment Tolerance %" / 100 * VendLedgEntry.Amount)) or (Currency."Payment Tolerance %" = 0)
                    then begin
                        if (Currency."Max. Payment Tolerance Amount" = 0) and (Currency."Payment Tolerance %" > 0) then
                            VendLedgEntry."Max. Payment Tolerance" :=
                              Round(Currency."Payment Tolerance %" * VendLedgEntry.Amount / 100, Currency."Amount Rounding Precision")
                        else
                            if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo" then
                                VendLedgEntry."Max. Payment Tolerance" := Currency."Max. Payment Tolerance Amount"
                            else
                                VendLedgEntry."Max. Payment Tolerance" := -Currency."Max. Payment Tolerance Amount"
                    end else
                        VendLedgEntry."Max. Payment Tolerance" :=
                          Round(Currency."Payment Tolerance %" * VendLedgEntry.Amount / 100, Currency."Amount Rounding Precision");
                end;
            end;
            if Abs(VendLedgEntry.Amount) < Abs(VendLedgEntry."Max. Payment Tolerance") then
                VendLedgEntry."Max. Payment Tolerance" := VendLedgEntry.Amount;
            OnCalcTolVendLedgEntryOnBeforeModify(VendLedgEntry);
            VendLedgEntry.Modify;
        until VendLedgEntry.Next = 0;
    end;

    procedure DelTolVendLedgEntry(Vendor: Record Vendor)
    var
        GLSetup: Record "General Ledger Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        GLSetup.Get;
        VendLedgEntry.SetCurrentKey("Vendor No.", Open);
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.LockTable;
        if not VendLedgEntry.Find('-') then
            exit;
        repeat
            VendLedgEntry."Pmt. Disc. Tolerance Date" := 0D;
            VendLedgEntry."Max. Payment Tolerance" := 0;
            VendLedgEntry.Modify;
        until VendLedgEntry.Next = 0;
    end;

    procedure DelPmtTolApllnDocNo(GenJnlLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) or
           (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor)
        then
            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);

        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then begin
            AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
            AppliedCustLedgEntry.SetRange("Customer No.", GenJnlLine."Account No.");
            AppliedCustLedgEntry.SetRange(Open, true);
            AppliedCustLedgEntry.SetRange("Document No.", DocumentNo);
            AppliedCustLedgEntry.LockTable;
            if AppliedCustLedgEntry.FindSet then begin
                repeat
                    AppliedCustLedgEntry."Accepted Payment Tolerance" := 0;
                    AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                    AppliedCustLedgEntry.Modify;
                until AppliedCustLedgEntry.Next = 0;
                if not SuppressCommit then
                    Commit;
            end;
        end else
            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor then begin
                AppliedVendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
                AppliedVendLedgEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                AppliedVendLedgEntry.SetRange(Open, true);
                AppliedVendLedgEntry.SetRange("Document No.", DocumentNo);
                AppliedVendLedgEntry.LockTable;
                if AppliedVendLedgEntry.FindSet then begin
                    repeat
                        AppliedVendLedgEntry."Accepted Payment Tolerance" := 0;
                        AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                        AppliedVendLedgEntry.Modify;
                    until AppliedVendLedgEntry.Next = 0;
                    if not SuppressCommit then
                        Commit;
                end;
            end;
    end;

    local procedure ABSMinTol(Decimal1: Decimal; Decimal2: Decimal; Decimal1Tolerance: Decimal): Decimal
    begin
        if Abs(Decimal1) - Abs(Decimal1Tolerance) < Abs(Decimal2) then
            exit(Decimal1);
        exit(Decimal2);
    end;

    local procedure DelCustPmtTolAcc2(CustledgEntry: Record "Cust. Ledger Entry"; CustEntryApplID: Code[50])
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if CustEntryApplID <> '' then begin
            AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
            AppliedCustLedgEntry.SetRange("Customer No.", CustledgEntry."Customer No.");
            AppliedCustLedgEntry.SetRange(Open, true);
            AppliedCustLedgEntry.SetRange("Applies-to ID", CustEntryApplID);
            if CustledgEntry."Document Type" = CustledgEntry."Document Type"::Payment then
                AppliedCustLedgEntry.SetRange("Document Type", AppliedCustLedgEntry."Document Type"::Invoice);
            if CustledgEntry."Document Type" = CustledgEntry."Document Type"::Refund then
                AppliedCustLedgEntry.SetRange("Document Type", AppliedCustLedgEntry."Document Type"::"Credit Memo");

            AppliedCustLedgEntry.LockTable;

            if AppliedCustLedgEntry.FindLast then begin
                AppliedCustLedgEntry."Accepted Payment Tolerance" := 0;
                AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                AppliedCustLedgEntry.Modify;
                if not SuppressCommit then
                    Commit;
            end;
        end;
    end;

    local procedure DelVendPmtTolAcc2(VendLedgEntry: Record "Vendor Ledger Entry"; VendEntryApplID: Code[50])
    var
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if VendEntryApplID <> '' then begin
            AppliedVendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
            AppliedVendLedgEntry.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
            AppliedVendLedgEntry.SetRange(Open, true);
            AppliedVendLedgEntry.SetRange("Applies-to ID", VendEntryApplID);
            if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Payment then
                AppliedVendLedgEntry.SetRange("Document Type", AppliedVendLedgEntry."Document Type"::Invoice);
            if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Refund then
                AppliedVendLedgEntry.SetRange("Document Type", AppliedVendLedgEntry."Document Type"::"Credit Memo");

            AppliedVendLedgEntry.LockTable;

            if AppliedVendLedgEntry.FindLast then begin
                AppliedVendLedgEntry."Accepted Payment Tolerance" := 0;
                AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                AppliedVendLedgEntry.Modify;
                if not SuppressCommit then
                    Commit;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure PmtTolCBGJnl(var CBGStatementLine: Record "CBG Statement Line"): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        Vendor: Record Vendor;
        NewCustLedgEntry: Record "Cust. Ledger Entry";
        NewVendLedgEntry: Record "Vendor Ledger Entry";
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
        ExchAccGLJnlLine: Codeunit "Exchange Acc. G/L Journal Line";
        AppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        AmounttoApply: Decimal;
        PmtDiscAmount: Decimal;
        MaxPmtTolAmount: Decimal;
        CBGStatementLineApplID: Code[20];
        RemainingAmountTest: Boolean;
        ApplnRoundingPrecision: Decimal;
        CBGStatement: Record "CBG Statement";
        UseDocumentNo: Code[20];
    begin
        MaxPmtTolAmount := 0;
        PmtDiscAmount := 0;
        AppliedAmount := 0;
        ApplyingAmount := 0;
        AmounttoApply := 0;

        if CBGStatementLine."Account Type" = CBGStatementLine."Account Type"::Customer then begin
            Customer.Get(CBGStatementLine."Account No.");
            if Customer."Block Payment Tolerance" then
                exit(false);
        end else
            if CBGStatementLine."Account Type" = CBGStatementLine."Account Type"::Vendor then begin
                Vendor.Get(CBGStatementLine."Account No.");
                if Vendor."Block Payment Tolerance" then
                    exit(false);
            end;

        CBGStatement.Get(CBGStatementLine."Journal Template Name", CBGStatementLine."No.");
        GLSetup.Get;
        if CBGStatementLine."Applies-to Doc. No." = '' then
            if CBGStatementLine."Applies-to ID" <> '' then
                CBGStatementLineApplID := CBGStatementLine."Applies-to ID";

        if CBGStatementLine."Account Type" = CBGStatementLine."Account Type"::Customer then begin
            NewCustLedgEntry."Posting Date" := CBGStatementLine.Date;
            NewCustLedgEntry."Document No." := CBGStatementLine."Document No.";
            NewCustLedgEntry."Customer No." := CBGStatementLine."Account No.";
            NewCustLedgEntry."Currency Code" := CBGStatement.Currency;
            if CBGStatementLine."Applies-to Doc. No." <> '' then
                NewCustLedgEntry."Applies-to Doc. No." := CBGStatementLine."Applies-to Doc. No.";
            DelCustPmtTolAcc(NewCustLedgEntry, CBGStatementLineApplID);
            NewCustLedgEntry.Amount := CBGStatementLine.Amount;
            NewCustLedgEntry."Remaining Amount" := CBGStatementLine.Amount;
            case (CBGStatementLine.Amount >= 0) of
                true:
                    NewCustLedgEntry."Document Type" := NewCustLedgEntry."Document Type"::Refund;
                false:
                    NewCustLedgEntry."Document Type" := NewCustLedgEntry."Document Type"::Payment;
            end;
            CalcCustApplnAmount(
              NewCustLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
              MaxPmtTolAmount, CBGStatementLineApplID, ApplnRoundingPrecision);
        end else begin
            NewVendLedgEntry."Posting Date" := CBGStatementLine.Date;
            NewVendLedgEntry."Document No." := CBGStatementLine."Document No.";
            NewVendLedgEntry."Vendor No." := CBGStatementLine."Account No.";
            NewVendLedgEntry."Currency Code" := CBGStatement.Currency;
            if CBGStatementLine."Applies-to Doc. No." <> '' then
                NewVendLedgEntry."Applies-to Doc. No." := CBGStatementLine."Applies-to Doc. No.";
            DelVendPmtTolAcc(NewVendLedgEntry, CBGStatementLineApplID);
            NewVendLedgEntry.Amount := CBGStatementLine.Amount;
            NewVendLedgEntry."Remaining Amount" := CBGStatementLine.Amount;
            NewVendLedgEntry."Document Type" := NewVendLedgEntry."Document Type"::Payment;
            CalcVendApplnAmount(
              NewVendLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
              MaxPmtTolAmount, CBGStatementLineApplID, ApplnRoundingPrecision);
        end;

        if GLSetup."Pmt. Disc. Tolerance Warning" then begin
            case CBGStatementLine."Account Type" of
                CBGStatementLine."Account Type"::Customer:
                    if not ManagePaymentDiscToleranceWarningCustomer(
                         NewCustLedgEntry, CBGStatementLineApplID, AppliedAmount, AmounttoApply, CBGStatementLine."Applies-to Doc. No.")
                    then
                        exit(false);
                CBGStatementLine."Account Type"::Vendor:
                    if not ManagePaymentDiscToleranceWarningVendor(
                         NewVendLedgEntry, CBGStatementLineApplID, AppliedAmount, AmounttoApply, CBGStatementLine."Applies-to Doc. No.")
                    then
                        exit(false);
            end;
        end;

        if Abs(AmounttoApply) >= Abs(AppliedAmount - PmtDiscAmount - MaxPmtTolAmount) then begin
            AppliedAmount := AppliedAmount - PmtDiscAmount;
            if Abs(AppliedAmount) > Abs(AmounttoApply) then
                AppliedAmount := AmounttoApply;

            if ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <= Abs(MaxPmtTolAmount)) and
              (MaxPmtTolAmount <> 0) and ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <> 0) and
              ((Abs(AppliedAmount + ApplyingAmount) > ApplnRoundingPrecision))
            then begin
                if CBGStatement.Type = CBGStatement.Type::"Bank/Giro" then
                    UseDocumentNo := CBGStatement."Document No."
                else
                    UseDocumentNo := CBGStatementLine."Document No.";

                if CBGStatementLine."Account Type" = CBGStatementLine."Account Type"::Customer then begin
                    if GLSetup."Payment Tolerance Warning" then begin
                        if CallPmtTolWarning(
                             CBGStatementLine.Date, CBGStatementLine."Account No.", UseDocumentNo,
                             CBGStatement.Currency, AppliedAmount, ApplyingAmount, RefAccountType::Customer)
                        then begin
                            PutCustPmtTolAmount(NewCustLedgEntry, AppliedAmount, ApplyingAmount, CBGStatementLineApplID);
                        end else
                            exit(false);
                    end else
                        PutCustPmtTolAmount(NewCustLedgEntry, AppliedAmount, ApplyingAmount, CBGStatementLineApplID);
                end else begin
                    if GLSetup."Payment Tolerance Warning" then begin
                        if CallPmtTolWarning(
                             CBGStatementLine.Date, CBGStatementLine."Account No.", UseDocumentNo,
                             CBGStatement.Currency, AppliedAmount, ApplyingAmount, RefAccountType::Vendor)
                        then begin
                            if (AppliedAmount <> 0) and (ApplyingAmount <> 0) then
                                PutVendPmtTolAmount(NewVendLedgEntry, AppliedAmount, ApplyingAmount, CBGStatementLineApplID)
                            else
                                DelVendPmtTolAcc(NewVendLedgEntry, CBGStatementLineApplID);
                        end else
                            exit(false);
                    end else
                        PutVendPmtTolAmount(NewVendLedgEntry, AppliedAmount, ApplyingAmount, CBGStatementLineApplID);
                end;
            end;

        end;
        exit(true);
    end;

    local procedure GetCustApplicationRoundingPrecisionForAppliesToID(var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; var ApplnRoundingPrecision: Decimal; var AmountRoundingPrecision: Decimal; var ApplnInMultiCurrency: Boolean; ApplnCurrencyCode: Code[20])
    begin
        AppliedCustLedgEntry.SetFilter("Currency Code", '<>%1', ApplnCurrencyCode);
        ApplnInMultiCurrency := not AppliedCustLedgEntry.IsEmpty;
        AppliedCustLedgEntry.SetRange("Currency Code");

        GetAmountRoundingPrecision(ApplnRoundingPrecision, AmountRoundingPrecision, ApplnInMultiCurrency, ApplnCurrencyCode);
    end;

    local procedure GetVendApplicationRoundingPrecisionForAppliesToID(var AppliedVendLedgEntry: Record "Vendor Ledger Entry"; var ApplnRoundingPrecision: Decimal; var AmountRoundingPrecision: Decimal; var ApplnInMultiCurrency: Boolean; ApplnCurrencyCode: Code[20])
    begin
        AppliedVendLedgEntry.SetFilter("Currency Code", '<>%1', ApplnCurrencyCode);
        ApplnInMultiCurrency := not AppliedVendLedgEntry.IsEmpty;
        AppliedVendLedgEntry.SetRange("Currency Code");

        GetAmountRoundingPrecision(ApplnRoundingPrecision, AmountRoundingPrecision, ApplnInMultiCurrency, ApplnCurrencyCode);
    end;

    local procedure GetApplicationRoundingPrecisionForAppliesToDoc(AppliedEntryCurrencyCode: Code[10]; var ApplnRoundingPrecision: Decimal; var AmountRoundingPrecision: Decimal; ApplnCurrencyCode: Code[20])
    var
        Currency: Record Currency;
    begin
        if ApplnCurrencyCode = '' then begin
            Currency.Init;
            Currency.Code := '';
            Currency.InitRoundingPrecision;
            if AppliedEntryCurrencyCode = '' then
                ApplnRoundingPrecision := 0;
        end else begin
            if ApplnCurrencyCode <> AppliedEntryCurrencyCode then begin
                Currency.Get(ApplnCurrencyCode);
                ApplnRoundingPrecision := Currency."Appln. Rounding Precision";
            end else
                ApplnRoundingPrecision := 0;
        end;
        AmountRoundingPrecision := Currency."Amount Rounding Precision";
    end;

    local procedure UpdateCustAmountsForApplication(var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; var CustLedgEntry: Record "Cust. Ledger Entry"; var TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    begin
        AppliedCustLedgEntry.CalcFields("Remaining Amount");
        TempAppliedCustLedgEntry := AppliedCustLedgEntry;
        if CustLedgEntry."Currency Code" <> AppliedCustLedgEntry."Currency Code" then begin
            AppliedCustLedgEntry."Remaining Amount" :=
              CurrExchRate.ExchangeAmount(
                AppliedCustLedgEntry."Remaining Amount", AppliedCustLedgEntry."Currency Code",
                CustLedgEntry."Currency Code", CustLedgEntry."Posting Date");
            AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" :=
              CurrExchRate.ExchangeAmount(
                AppliedCustLedgEntry."Remaining Pmt. Disc. Possible",
                AppliedCustLedgEntry."Currency Code",
                CustLedgEntry."Currency Code", CustLedgEntry."Posting Date");
            AppliedCustLedgEntry."Max. Payment Tolerance" :=
              CurrExchRate.ExchangeAmount(
                AppliedCustLedgEntry."Max. Payment Tolerance",
                AppliedCustLedgEntry."Currency Code",
                CustLedgEntry."Currency Code", CustLedgEntry."Posting Date");
            AppliedCustLedgEntry."Amount to Apply" :=
              CurrExchRate.ExchangeAmount(
                AppliedCustLedgEntry."Amount to Apply",
                AppliedCustLedgEntry."Currency Code",
                CustLedgEntry."Currency Code", CustLedgEntry."Posting Date");
        end;
    end;

    local procedure UpdateVendAmountsForApplication(var AppliedVendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry: Record "Vendor Ledger Entry"; var TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary)
    begin
        AppliedVendLedgEntry.CalcFields("Remaining Amount");
        TempAppliedVendLedgEntry := AppliedVendLedgEntry;
        if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then begin
            AppliedVendLedgEntry."Remaining Amount" :=
              CurrExchRate.ExchangeAmount(
                AppliedVendLedgEntry."Remaining Amount", AppliedVendLedgEntry."Currency Code",
                VendLedgEntry."Currency Code", VendLedgEntry."Posting Date");
            AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" :=
              CurrExchRate.ExchangeAmount(
                AppliedVendLedgEntry."Remaining Pmt. Disc. Possible",
                AppliedVendLedgEntry."Currency Code",
                VendLedgEntry."Currency Code", VendLedgEntry."Posting Date");
            AppliedVendLedgEntry."Max. Payment Tolerance" :=
              CurrExchRate.ExchangeAmount(
                AppliedVendLedgEntry."Max. Payment Tolerance",
                AppliedVendLedgEntry."Currency Code",
                VendLedgEntry."Currency Code", VendLedgEntry."Posting Date");
            AppliedVendLedgEntry."Amount to Apply" :=
              CurrExchRate.ExchangeAmount(
                AppliedVendLedgEntry."Amount to Apply",
                AppliedVendLedgEntry."Currency Code",
                VendLedgEntry."Currency Code", VendLedgEntry."Posting Date");
        end;
    end;

    local procedure GetCustPositiveFilter(DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; TempAmount: Decimal) PositiveFilter: Boolean
    begin
        PositiveFilter := TempAmount <= 0;
        if ((TempAmount > 0) and (DocumentType = DocumentType::Refund) or (DocumentType = DocumentType::Invoice) or
            (DocumentType = DocumentType::"Credit Memo"))
        then
            PositiveFilter := true;
        exit(PositiveFilter);
    end;

    local procedure GetVendPositiveFilter(DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; TempAmount: Decimal) PositiveFilter: Boolean
    begin
        PositiveFilter := TempAmount >= 0;
        if ((TempAmount < 0) and (DocumentType = DocumentType::Refund) or (DocumentType = DocumentType::Invoice) or
            (DocumentType = DocumentType::"Credit Memo"))
        then
            PositiveFilter := true;
        exit(PositiveFilter);
    end;

    local procedure CheckCustPaymentAmountsForAppliesToID(CustLedgEntry: Record "Cust. Ledger Entry"; var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; var TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary; var MaxPmtTolAmount: Decimal; var AvailableAmount: Decimal; var TempAmount: Decimal; ApplnRoundingPrecision: Decimal)
    begin
        // Check Payment Tolerance
        if CheckPmtTolCust(CustLedgEntry."Document Type", AppliedCustLedgEntry) then
            MaxPmtTolAmount := MaxPmtTolAmount + AppliedCustLedgEntry."Max. Payment Tolerance";

        // Check Payment Discount
        if CheckCalcPmtDiscCust(CustLedgEntry, AppliedCustLedgEntry, 0, false, false) then
            AppliedCustLedgEntry."Remaining Amount" :=
              AppliedCustLedgEntry."Remaining Amount" - AppliedCustLedgEntry."Remaining Pmt. Disc. Possible";

        // Check Payment Discount Tolerance
        if AppliedCustLedgEntry."Amount to Apply" = AppliedCustLedgEntry."Remaining Amount" then
            AvailableAmount := TempAmount
        else
            AvailableAmount := -AppliedCustLedgEntry."Amount to Apply";
        if CheckPmtDiscTolCust(
             CustLedgEntry."Posting Date", CustLedgEntry."Document Type", AvailableAmount, AppliedCustLedgEntry, ApplnRoundingPrecision,
             MaxPmtTolAmount)
        then begin
            AppliedCustLedgEntry."Remaining Amount" :=
              AppliedCustLedgEntry."Remaining Amount" - AppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
            AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := true;
            if CustLedgEntry."Currency Code" <> AppliedCustLedgEntry."Currency Code" then begin
                AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" :=
                  TempAppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
                AppliedCustLedgEntry."Max. Payment Tolerance" :=
                  TempAppliedCustLedgEntry."Max. Payment Tolerance";
            end;
            AppliedCustLedgEntry.Modify;
        end;
        TempAmount :=
          TempAmount +
          ABSMinTol(
            AppliedCustLedgEntry."Remaining Amount",
            AppliedCustLedgEntry."Amount to Apply",
            MaxPmtTolAmount);
    end;

    local procedure CheckVendPaymentAmountsForAppliesToID(VendLedgEntry: Record "Vendor Ledger Entry"; var AppliedVendLedgEntry: Record "Vendor Ledger Entry"; var TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary; var MaxPmtTolAmount: Decimal; var AvailableAmount: Decimal; var TempAmount: Decimal; ApplnRoundingPrecision: Decimal)
    begin
        // Check Payment Tolerance
        if CheckPmtTolVend(VendLedgEntry."Document Type", AppliedVendLedgEntry) then
            MaxPmtTolAmount := MaxPmtTolAmount + AppliedVendLedgEntry."Max. Payment Tolerance";

        // Check Payment Discount
        if CheckCalcPmtDiscVend(VendLedgEntry, AppliedVendLedgEntry, 0, false, false) then
            AppliedVendLedgEntry."Remaining Amount" :=
              AppliedVendLedgEntry."Remaining Amount" - AppliedVendLedgEntry."Remaining Pmt. Disc. Possible";

        // Check Payment Discount Tolerance
        if AppliedVendLedgEntry."Amount to Apply" = AppliedVendLedgEntry."Remaining Amount" then
            AvailableAmount := TempAmount
        else
            AvailableAmount := -AppliedVendLedgEntry."Amount to Apply";
        if CheckPmtDiscTolVend(VendLedgEntry."Posting Date", VendLedgEntry."Document Type", AvailableAmount,
             AppliedVendLedgEntry, ApplnRoundingPrecision, MaxPmtTolAmount)
        then begin
            AppliedVendLedgEntry."Remaining Amount" :=
              AppliedVendLedgEntry."Remaining Amount" - AppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
            AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := true;
            if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then begin
                AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" :=
                  TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                AppliedVendLedgEntry."Max. Payment Tolerance" :=
                  TempAppliedVendLedgEntry."Max. Payment Tolerance";
            end;
            AppliedVendLedgEntry.Modify;
        end;
        TempAmount :=
          TempAmount +
          ABSMinTol(
            AppliedVendLedgEntry."Remaining Amount",
            AppliedVendLedgEntry."Amount to Apply",
            MaxPmtTolAmount);
    end;

    local procedure CheckCustPaymentAmountsForAppliesToDoc(CustLedgEntry: Record "Cust. Ledger Entry"; var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; var TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary; var MaxPmtTolAmount: Decimal; ApplnRoundingPrecision: Decimal; var PmtDiscAmount: Decimal; ApplnCurrencyCode: Code[20])
    begin
        // Check Payment Tolerance
        if CheckPmtTolCust(CustLedgEntry."Document Type", AppliedCustLedgEntry) and
           CheckCustLedgAmt(CustLedgEntry, AppliedCustLedgEntry, AppliedCustLedgEntry."Max. Payment Tolerance", ApplnRoundingPrecision)
        then
            MaxPmtTolAmount := MaxPmtTolAmount + AppliedCustLedgEntry."Max. Payment Tolerance";

        // Check Payment Discount
        if CheckCalcPmtDiscCust(CustLedgEntry, AppliedCustLedgEntry, 0, false, false) and
           CheckCustLedgAmt(CustLedgEntry, AppliedCustLedgEntry, MaxPmtTolAmount, ApplnRoundingPrecision)
        then
            PmtDiscAmount := PmtDiscAmount + AppliedCustLedgEntry."Remaining Pmt. Disc. Possible";

        // Check Payment Discount Tolerance
        if CheckPmtDiscTolCust(
             CustLedgEntry."Posting Date", CustLedgEntry."Document Type", CustLedgEntry.Amount, AppliedCustLedgEntry,
             ApplnRoundingPrecision, MaxPmtTolAmount) and CheckCustLedgAmt(
             CustLedgEntry, AppliedCustLedgEntry, MaxPmtTolAmount, ApplnRoundingPrecision)
        then begin
            PmtDiscAmount := PmtDiscAmount + AppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
            AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := true;
            if AppliedCustLedgEntry."Currency Code" <> ApplnCurrencyCode then begin
                AppliedCustLedgEntry."Max. Payment Tolerance" :=
                  TempAppliedCustLedgEntry."Max. Payment Tolerance";
                AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" :=
                  TempAppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
            end;
            AppliedCustLedgEntry.Modify;
            if not SuppressCommit then
                Commit;
        end;
    end;

    local procedure CheckVendPaymentAmountsForAppliesToDoc(VendLedgEntry: Record "Vendor Ledger Entry"; var AppliedVendLedgEntry: Record "Vendor Ledger Entry"; var TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary; var MaxPmtTolAmount: Decimal; ApplnRoundingPrecision: Decimal; var PmtDiscAmount: Decimal)
    begin
        // Check Payment Tolerance
        if CheckPmtTolVend(VendLedgEntry."Document Type", AppliedVendLedgEntry) and
           CheckVendLedgAmt(VendLedgEntry, AppliedVendLedgEntry, AppliedVendLedgEntry."Max. Payment Tolerance", ApplnRoundingPrecision)
        then
            MaxPmtTolAmount := MaxPmtTolAmount + AppliedVendLedgEntry."Max. Payment Tolerance";

        // Check Payment Discount
        if CheckCalcPmtDiscVend(
             VendLedgEntry, AppliedVendLedgEntry, 0, false, false) and
           CheckVendLedgAmt(VendLedgEntry, AppliedVendLedgEntry, MaxPmtTolAmount, ApplnRoundingPrecision)
        then
            PmtDiscAmount := PmtDiscAmount + AppliedVendLedgEntry."Remaining Pmt. Disc. Possible";

        // Check Payment Discount Tolerance
        if CheckPmtDiscTolVend(
             VendLedgEntry."Posting Date", VendLedgEntry."Document Type", VendLedgEntry.Amount,
             AppliedVendLedgEntry, ApplnRoundingPrecision, MaxPmtTolAmount) and
           CheckVendLedgAmt(VendLedgEntry, AppliedVendLedgEntry, MaxPmtTolAmount, ApplnRoundingPrecision)
        then begin
            PmtDiscAmount := PmtDiscAmount + AppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
            AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := true;
            if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then begin
                AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" := TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                AppliedVendLedgEntry."Max. Payment Tolerance" := TempAppliedVendLedgEntry."Max. Payment Tolerance";
            end;
            AppliedVendLedgEntry.Modify;
            if not SuppressCommit then
                Commit;
        end;
    end;

    local procedure CheckCustLedgAmt(CustLedgEntry: Record "Cust. Ledger Entry"; AppliedCustLedgEntry: Record "Cust. Ledger Entry"; MaxPmtTolAmount: Decimal; ApplnRoundingPrecision: Decimal): Boolean
    begin
        exit((Abs(CustLedgEntry.Amount) + ApplnRoundingPrecision >= Abs(AppliedCustLedgEntry."Remaining Amount" -
                AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" - MaxPmtTolAmount)));
    end;

    local procedure CheckVendLedgAmt(VendLedgEntry: Record "Vendor Ledger Entry"; AppliedVendLedgEntry: Record "Vendor Ledger Entry"; MaxPmtTolAmount: Decimal; ApplnRoundingPrecision: Decimal): Boolean
    begin
        exit((Abs(VendLedgEntry.Amount) + ApplnRoundingPrecision >= Abs(AppliedVendLedgEntry."Remaining Amount" -
                AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" - MaxPmtTolAmount)));
    end;

    local procedure GetAmountRoundingPrecision(var ApplnRoundingPrecision: Decimal; var AmountRoundingPrecision: Decimal; ApplnInMultiCurrency: Boolean; ApplnCurrencyCode: Code[20])
    var
        Currency: Record Currency;
    begin
        if ApplnCurrencyCode = '' then begin
            Currency.Init;
            Currency.Code := '';
            Currency.InitRoundingPrecision;
        end else begin
            if ApplnInMultiCurrency then
                Currency.Get(ApplnCurrencyCode)
            else
                Currency.Init;
        end;
        ApplnRoundingPrecision := Currency."Appln. Rounding Precision";
        AmountRoundingPrecision := Currency."Amount Rounding Precision";
    end;

    procedure CalcRemainingPmtDisc(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; GLSetup: Record "General Ledger Setup")
    var
        Handled: Boolean;
    begin
        OnBeforeCalcRemainingPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, GLSetup, Handled);
        if Handled then
            exit;

        if Abs(NewCVLedgEntryBuf."Max. Payment Tolerance") > Abs(NewCVLedgEntryBuf."Remaining Amount") then
            NewCVLedgEntryBuf."Max. Payment Tolerance" := NewCVLedgEntryBuf."Remaining Amount";
        if (((NewCVLedgEntryBuf."Document Type" in [NewCVLedgEntryBuf."Document Type"::"Credit Memo",
                                                    NewCVLedgEntryBuf."Document Type"::Invoice]) and
             (OldCVLedgEntryBuf."Document Type" in [OldCVLedgEntryBuf."Document Type"::Invoice,
                                                    OldCVLedgEntryBuf."Document Type"::"Credit Memo"])) and
            ((OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" <> 0) and
             (NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" <> 0)) or
            ((OldCVLedgEntryBuf."Document Type" = OldCVLedgEntryBuf."Document Type"::"Credit Memo") and
             (OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" <> 0) and
             (NewCVLedgEntryBuf."Document Type" <> NewCVLedgEntryBuf."Document Type"::Refund)))
        then begin
            if OldCVLedgEntryBuf."Remaining Amount" <> 0 then
                OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible" :=
                  Round(OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" -
                    (OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" *
                     (OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf."Remaining Amount") /
                     OldCVLedgEntryBuf2."Remaining Amount"), GLSetup."Amount Rounding Precision");
            NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" :=
              Round(NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" +
                (NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" *
                 (OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf."Remaining Amount") /
                 (NewCVLedgEntryBuf."Remaining Amount" -
                  OldCVLedgEntryBuf2."Remaining Amount" + OldCVLedgEntryBuf."Remaining Amount")),
                GLSetup."Amount Rounding Precision");

            if NewCVLedgEntryBuf."Currency Code" = OldCVLedgEntryBuf2."Currency Code" then
                OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible"
            else
                OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible";
        end;

        if OldCVLedgEntryBuf."Document Type" in [OldCVLedgEntryBuf."Document Type"::Invoice,
                                                 OldCVLedgEntryBuf."Document Type"::"Credit Memo"]
        then
            if Abs(OldCVLedgEntryBuf."Remaining Amount") < Abs(OldCVLedgEntryBuf."Max. Payment Tolerance") then
                OldCVLedgEntryBuf."Max. Payment Tolerance" := OldCVLedgEntryBuf."Remaining Amount";

        if not NewCVLedgEntryBuf.Open then begin
            NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := 0;
            NewCVLedgEntryBuf."Max. Payment Tolerance" := 0;
        end;

        if not OldCVLedgEntryBuf.Open then begin
            OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := 0;
            OldCVLedgEntryBuf."Max. Payment Tolerance" := 0;
        end;
    end;

    procedure CalcMaxPmtTolerance(DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal; Sign: Decimal; var MaxPaymentTolerance: Decimal)
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        MaxPaymentToleranceAmount: Decimal;
        PaymentTolerancePct: Decimal;
        PaymentAmount: Decimal;
        AmountRoundingPrecision: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcMaxPmtTolerance(DocumentType, CurrencyCode, Amount, AmountLCY, Sign, MaxPaymentTolerance, IsHandled);
        if IsHandled then
            exit;

        if CurrencyCode = '' then begin
            GLSetup.Get;
            MaxPaymentToleranceAmount := GLSetup."Max. Payment Tolerance Amount";
            PaymentTolerancePct := GLSetup."Payment Tolerance %";
            AmountRoundingPrecision := GLSetup."Amount Rounding Precision";
            PaymentAmount := AmountLCY;
        end else begin
            Currency.Get(CurrencyCode);
            MaxPaymentToleranceAmount := Currency."Max. Payment Tolerance Amount";
            PaymentTolerancePct := Currency."Payment Tolerance %";
            AmountRoundingPrecision := Currency."Amount Rounding Precision";
            PaymentAmount := Amount;
        end;

        if (MaxPaymentToleranceAmount <
            Abs(PaymentTolerancePct / 100 * PaymentAmount)) or (PaymentTolerancePct = 0)
        then begin
            if (MaxPaymentToleranceAmount = 0) and (PaymentTolerancePct > 0) then
                MaxPaymentTolerance :=
                  Round(PaymentTolerancePct * PaymentAmount / 100, AmountRoundingPrecision)
            else
                if DocumentType = DocumentType::"Credit Memo" then
                    MaxPaymentTolerance := -MaxPaymentToleranceAmount * Sign
                else
                    MaxPaymentTolerance := MaxPaymentToleranceAmount * Sign
        end else
            MaxPaymentTolerance :=
              Round(PaymentTolerancePct * PaymentAmount / 100, AmountRoundingPrecision);

        if Abs(MaxPaymentTolerance) > Abs(Amount) then
            MaxPaymentTolerance := Amount;

        OnAfterCalcMaxPmtTolerance(DocumentType, CurrencyCode, Amount, AmountLCY, Sign, MaxPaymentTolerance);
    end;

    procedure CheckCalcPmtDisc(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        Handled: Boolean;
        Result: Boolean;
    begin
        OnBeforeCheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount, Handled, Result);
        if Handled then
            exit(Result);

        if ((NewCVLedgEntryBuf."Document Type" in [NewCVLedgEntryBuf."Document Type"::Refund,
                                                   NewCVLedgEntryBuf."Document Type"::Payment]) and
            (((OldCVLedgEntryBuf2."Document Type" = OldCVLedgEntryBuf2."Document Type"::"Credit Memo") and
              (OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible" <> 0) and
              (NewCVLedgEntryBuf."Posting Date" <= OldCVLedgEntryBuf2."Pmt. Discount Date")) or
             ((OldCVLedgEntryBuf2."Document Type" = OldCVLedgEntryBuf2."Document Type"::Invoice) and
              (OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible" <> 0) and
              (NewCVLedgEntryBuf."Posting Date" <= OldCVLedgEntryBuf2."Pmt. Discount Date"))))
        then begin
            if CheckFilter then begin
                if CheckAmount then begin
                    if (OldCVLedgEntryBuf2.GetFilter(Positive) <> '') or
                       (Abs(NewCVLedgEntryBuf."Remaining Amount") + ApplnRoundingPrecision >=
                        Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible"))
                    then
                        exit(true);

                    exit(false);
                end;

                exit(OldCVLedgEntryBuf2.GetFilter(Positive) <> '');
            end;
            if CheckAmount then
                exit((Abs(NewCVLedgEntryBuf."Remaining Amount") + ApplnRoundingPrecision >=
                      Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible")));

            exit(true);
        end;
        exit(false);
    end;

    procedure CheckCalcPmtDiscCVCust(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCustLedgEntry2: Record "Cust. Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        OldCustLedgEntry2.CopyFilter(Positive, OldCVLedgEntryBuf2.Positive);
        OldCVLedgEntryBuf2.CopyFromCustLedgEntry(OldCustLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscCust(var NewCustLedgEntry: Record "Cust. Ledger Entry"; var OldCustLedgEntry2: Record "Cust. Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        NewCVLedgEntryBuf.CopyFromCustLedgEntry(NewCustLedgEntry);
        OldCustLedgEntry2.CopyFilter(Positive, OldCVLedgEntryBuf2.Positive);
        OldCVLedgEntryBuf2.CopyFromCustLedgEntry(OldCustLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscGenJnlCust(GenJnlLine: Record "Gen. Journal Line"; OldCustLedgEntry2: Record "Cust. Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        NewCVLedgEntryBuf."Document Type" := GenJnlLine."Document Type";
        NewCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
        NewCVLedgEntryBuf."Remaining Amount" := GenJnlLine.Amount;
        OldCVLedgEntryBuf2.CopyFromCustLedgEntry(OldCustLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, false, CheckAmount));
    end;

    procedure CheckCalcPmtDiscCVVend(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldVendLedgEntry2: Record "Vendor Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        OldVendLedgEntry2.CopyFilter(Positive, OldCVLedgEntryBuf2.Positive);
        OldCVLedgEntryBuf2.CopyFromVendLedgEntry(OldVendLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscVend(var NewVendLedgEntry: Record "Vendor Ledger Entry"; var OldVendLedgEntry2: Record "Vendor Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        NewCVLedgEntryBuf.CopyFromVendLedgEntry(NewVendLedgEntry);
        OldVendLedgEntry2.CopyFilter(Positive, OldCVLedgEntryBuf2.Positive);
        OldCVLedgEntryBuf2.CopyFromVendLedgEntry(OldVendLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscGenJnlVend(GenJnlLine: Record "Gen. Journal Line"; OldVendLedgEntry2: Record "Vendor Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        NewCVLedgEntryBuf."Document Type" := GenJnlLine."Document Type";
        NewCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
        NewCVLedgEntryBuf."Remaining Amount" := GenJnlLine.Amount;
        OldCVLedgEntryBuf2.CopyFromVendLedgEntry(OldVendLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, false, CheckAmount));
    end;

    local procedure ManagePaymentDiscToleranceWarningCustomer(var NewCustLedgEntry: Record "Cust. Ledger Entry"; GenJnlLineApplID: Code[50]; var AppliedAmount: Decimal; var AmountToApply: Decimal; AppliesToDocNo: Code[20]): Boolean
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        RemainingAmountTest: Boolean;
    begin
        with AppliedCustLedgEntry do begin
            SetCurrentKey("Customer No.", "Applies-to ID", Open, Positive);
            SetRange("Customer No.", NewCustLedgEntry."Customer No.");
            if AppliesToDocNo <> '' then
                SetRange("Document No.", AppliesToDocNo)
            else
                SetRange("Applies-to ID", GenJnlLineApplID);
            SetRange(Open, true);
            SetRange("Accepted Pmt. Disc. Tolerance", true);
            if FindSet then
                repeat
                    CalcFields("Remaining Amount");
                    if CallPmtDiscTolWarning(
                         "Posting Date", "Customer No.",
                         "Document No.", "Currency Code",
                         "Remaining Amount", 0,
                         "Remaining Pmt. Disc. Possible", RemainingAmountTest, RefAccountType::Customer)
                    then begin
                        if RemainingAmountTest then begin
                            "Accepted Pmt. Disc. Tolerance" := false;
                            "Amount to Apply" := "Remaining Amount";
                            Modify;
                            if not SuppressCommit then
                                Commit;
                            if NewCustLedgEntry."Currency Code" <> "Currency Code" then
                                "Remaining Pmt. Disc. Possible" :=
                                  CurrExchRate.ExchangeAmount(
                                    "Remaining Pmt. Disc. Possible",
                                    "Currency Code",
                                    NewCustLedgEntry."Currency Code",
                                    NewCustLedgEntry."Posting Date");
                            AppliedAmount := AppliedAmount + "Remaining Pmt. Disc. Possible";
                            AmountToApply := AmountToApply + "Remaining Pmt. Disc. Possible";
                        end
                    end else begin
                        DelCustPmtTolAcc(NewCustLedgEntry, GenJnlLineApplID);
                        exit(false);
                    end;
                until Next = 0;
        end;

        exit(true);
    end;

    local procedure ManagePaymentDiscToleranceWarningVendor(var NewVendLedgEntry: Record "Vendor Ledger Entry"; GenJnlLineApplID: Code[50]; var AppliedAmount: Decimal; var AmountToApply: Decimal; AppliesToDocNo: Code[20]): Boolean
    var
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
        RemainingAmountTest: Boolean;
    begin
        with AppliedVendLedgEntry do begin
            SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive);
            SetRange("Vendor No.", NewVendLedgEntry."Vendor No.");
            if AppliesToDocNo <> '' then
                SetRange("Document No.", AppliesToDocNo)
            else
                SetRange("Applies-to ID", GenJnlLineApplID);
            SetRange(Open, true);
            SetRange("Accepted Pmt. Disc. Tolerance", true);
            if FindSet then
                repeat
                    CalcFields("Remaining Amount");
                    if CallPmtDiscTolWarning(
                         "Posting Date", "Vendor No.",
                         "Document No.", "Currency Code",
                         "Remaining Amount", 0,
                         "Remaining Pmt. Disc. Possible", RemainingAmountTest, RefAccountType::Vendor)
                    then begin
                        if RemainingAmountTest then begin
                            "Accepted Pmt. Disc. Tolerance" := false;
                            "Amount to Apply" := "Remaining Amount";
                            Modify;
                            if not SuppressCommit then
                                Commit;
                            if NewVendLedgEntry."Currency Code" <> "Currency Code" then
                                "Remaining Pmt. Disc. Possible" :=
                                  CurrExchRate.ExchangeAmount(
                                    "Remaining Pmt. Disc. Possible",
                                    "Currency Code",
                                    NewVendLedgEntry."Currency Code", NewVendLedgEntry."Posting Date");
                            AppliedAmount := AppliedAmount + "Remaining Pmt. Disc. Possible";
                            AmountToApply := AmountToApply + "Remaining Pmt. Disc. Possible";
                        end
                    end else begin
                        DelVendPmtTolAcc(NewVendLedgEntry, GenJnlLineApplID);
                        exit(false);
                    end;
                until Next = 0;
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure IsCustBlockPmtToleranceInGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        CheckAccountType(GenJnlLine, GenJnlLine."Account Type"::Customer);

        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer then
            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);

        exit(IsCustBlockPmtTolerance(GenJnlLine."Account No."));
    end;

    local procedure IsVendBlockPmtToleranceInGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        CheckAccountType(GenJnlLine, GenJnlLine."Account Type"::Vendor);

        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor then
            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);

        exit(IsVendBlockPmtTolerance(GenJnlLine."Account No."));
    end;

    local procedure IsCustBlockPmtTolerance(AccountNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(AccountNo) then
            exit(false);
        if Customer."Block Payment Tolerance" then
            exit(false);
    end;

    local procedure IsVendBlockPmtTolerance(AccountNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(AccountNo) then
            exit(false);
        if Vendor."Block Payment Tolerance" then
            exit(false);
    end;

    local procedure CheckAccountType(GenJnlLine: Record "Gen. Journal Line"; AccountType: Option)
    var
        DummyGenJnlLine: Record "Gen. Journal Line";
    begin
        DummyGenJnlLine."Account Type" := AccountType;
        if not (AccountType in [GenJnlLine."Account Type", GenJnlLine."Bal. Account Type"]) then
            Error(AccTypeOrBalAccTypeIsIncorrectErr, DummyGenJnlLine."Account Type");
    end;

    local procedure GetAppliesToID(GenJnlLine: Record "Gen. Journal Line"): Code[50]
    begin
        if GenJnlLine."Applies-to Doc. No." = '' then
            if GenJnlLine."Applies-to ID" <> '' then
                exit(GenJnlLine."Applies-to ID");
    end;

    local procedure GetAccountName(AccountType: Option Customer,Vendor; AccountNo: Code[20]): Text
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case AccountType of
            AccountType::Customer:
                if Customer.Get(AccountNo) then
                    exit(Customer.Name);
            AccountType::Vendor:
                if Vendor.Get(AccountNo) then
                    exit(Vendor.Name);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcMaxPmtTolerance(DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal; Sign: Decimal; var MaxPaymentTolerance: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcMaxPmtTolerance(DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal; Sign: Decimal; var MaxPaymentTolerance: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRemainingPmtDisc(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; GLSetup: Record "General Ledger Setup"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCalcPmtDisc(NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean; var Handled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTolCustLedgEntryOnBeforeModify(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTolVendLedgEntryOnBeforeModify(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

