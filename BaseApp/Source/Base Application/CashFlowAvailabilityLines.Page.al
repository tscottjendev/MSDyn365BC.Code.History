page 866 "Cash Flow Availability Lines"
{
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = Date;

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                Editable = false;
                ShowCaption = false;
                field("Period Start"; "Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies on which date the period starts, such as the first day of March, if the period is Month.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the accounting period. it is a good idea to use descriptive names, such as Month01, 1st Month, 1st Month/2000, Month01-2000, M1-2001/2002, etc.';
                }
                field(Receivables; GetAmount(CashFlowForecastEntry."Source Type"::Receivables))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Receivables';
                    ToolTip = 'Specifies amounts related to receivables.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::Receivables);
                    end;
                }
                field(SalesOrders; GetAmount(CashFlowForecastEntry."Source Type"::"Sales Order"))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Sales Orders';
                    ToolTip = 'Specifies amounts related to sales orders.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::"Sales Order");
                    end;
                }
                field(ServiceOrders; GetAmount(CashFlowForecastEntry."Source Type"::"Service Orders"))
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Service Orders';
                    ToolTip = 'Specifies amounts related to service orders.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::"Service Orders");
                    end;
                }
                field(SalesofFixedAssets; GetAmount(CashFlowForecastEntry."Source Type"::"Fixed Assets Disposal"))
                {
                    ApplicationArea = FixedAssets;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Fixed Assets Disposal';
                    ToolTip = 'Specifies amounts related to fixed assets disposal.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::"Fixed Assets Disposal");
                    end;
                }
                field(ManualRevenues; GetAmount(CashFlowForecastEntry."Source Type"::"Cash Flow Manual Revenue"))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Cash Flow Manual Revenues';
                    ToolTip = 'Specifies amounts related to manual revenues.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::"Cash Flow Manual Revenue");
                    end;
                }
                field(Payables; GetAmount(CashFlowForecastEntry."Source Type"::Payables))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Payables';
                    ToolTip = 'Specifies amounts related to payables.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::Payables);
                    end;
                }
                field(PurchaseOrders; GetAmount(CashFlowForecastEntry."Source Type"::"Purchase Order"))
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Purchase Orders';
                    ToolTip = 'Specifies amounts related to purchase orders.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::"Purchase Order");
                    end;
                }
                field(BudgetedFixedAssets; GetAmount(CashFlowForecastEntry."Source Type"::"Fixed Assets Budget"))
                {
                    ApplicationArea = FixedAssets;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Fixed Assets Budget';
                    ToolTip = 'Specifies amounts related to fixed assets.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::"Fixed Assets Budget");
                    end;
                }
                field(ManualExpenses; GetAmount(CashFlowForecastEntry."Source Type"::"Cash Flow Manual Expense"))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Cash Flow Manual Expenses';
                    ToolTip = 'Specifies amounts related to manual expenses.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::"Cash Flow Manual Expense");
                    end;
                }
                field(Budget; GetAmount(CashFlowForecastEntry."Source Type"::"G/L Budget"))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'G/L Budget';
                    ToolTip = 'Specifies amounts related to the general ledger budget.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::"G/L Budget");
                    end;
                }
                field(Job; GetAmount(CashFlowForecastEntry."Source Type"::Job))
                {
                    ApplicationArea = Jobs;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Job';
                    ToolTip = 'Specifies amounts related to jobs.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::Job);
                    end;
                }
                field(Tax; GetAmount(CashFlowForecastEntry."Source Type"::Tax))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Tax';
                    ToolTip = 'Specifies amounts related to taxes.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::Tax);
                    end;
                }
                field(Total; GetAmount(0))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Total';
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies total amounts.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownEntriesFromSource(CashFlowForecast."Source Type Filter"::" ");
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        CashFlowForecast.SetCashFlowDateFilter("Period Start", "Period End");
    end;

    trigger OnAfterGetRecord()
    var
        SourceType: Option;
    begin
        case AmountType of
            AmountType::"Net Change":
                CashFlowForecast.SetCashFlowDateFilter("Period Start", "Period End");
            AmountType::"Balance at Date":
                CashFlowForecast.SetCashFlowDateFilter(0D, "Period End");
        end;

        for SourceType := 1 to ArrayLen(Amounts) do
            Amounts[SourceType] := MatrixMgt.RoundValue(Amounts[SourceType], RoundingFactor);

        CashFlowSum := MatrixMgt.RoundValue(CashFlowSum, RoundingFactor);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(PeriodFormManagement.FindDate(Which, Rec, PeriodType));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(PeriodFormManagement.NextDate(Steps, Rec, PeriodType));
    end;

    trigger OnOpenPage()
    begin
        Reset;
    end;

    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowForecast2: Record "Cash Flow Forecast";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        PeriodFormManagement: Codeunit PeriodFormManagement;
        MatrixMgt: Codeunit "Matrix Management";
        RoundingFactorFormatString: Text;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";
        RoundingFactor: Option "None","1","1000","1000000";
        CashFlowSum: Decimal;
        Amounts: array[15] of Decimal;

    procedure Set(var NewCashFlowForecast: Record "Cash Flow Forecast"; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date"; RoundingFactor2: Option "None","1","1000","1000000")
    begin
        CashFlowForecast.Copy(NewCashFlowForecast);
        CashFlowForecast2.Copy(NewCashFlowForecast);
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
        RoundingFactor := RoundingFactor2;
        RoundingFactorFormatString := MatrixMgt.GetFormatString(RoundingFactor, false);
    end;

    local procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;

    local procedure GetAmount(SourceType: Integer): Decimal
    begin
        exit(MatrixMgt.RoundValue(CashFlowForecast.CalcAmountFromSource(SourceType), RoundingFactor));
    end;
}

