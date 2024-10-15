report 742 "VAT Report Request Page"
{
    Caption = 'VAT Report Request Page';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Report Header"; "VAT Report Header")
        {
        }
    }

    requestpage
    {
        SaveValues = true;
        ShowFilter = false;

        layout
        {
            area(content)
            {
                field(Selection; Selection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include VAT entries';
                    OptionCaption = 'Open,Closed,Open and Closed';
                    ToolTip = 'Specifies whether to include VAT entries based on their status. For example, Open is useful when submitting for the first time, Open and Closed is useful when resubmitting.';
                }
                field(PeriodSelection; PeriodSelection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include VAT entries';
                    OptionCaption = 'Before and Within Period,Within Period';
                    ToolTip = 'Specifies whether to include VAT entries only from the specified period, or also from previous periods within the specified year.';
                }
                field("Period Year"; "VAT Report Header"."Report Year")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Year';
                    ToolTip = 'Specifies the year of the reporting period.';
                }
                field("""VAT Report Header"".""Report Period Type"""; "VAT Report Header"."Report Period Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Type';
                    ToolTip = 'Specifies the length of the reporting period.';
                }
                field("""VAT Report Header"".""Report Period No."""; "VAT Report Header"."Report Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period No.';
                    ToolTip = 'Specifies the specific reporting period to use.';
                }
                field("""VAT Report Header"".""Start Date"""; "VAT Report Header"."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start Date';
                    Importance = Additional;
                    ToolTip = 'Specifies the first date of the reporting period.';
                }
                field("""VAT Report Header"".""End Date"""; "VAT Report Header"."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'End Date';
                    Importance = Additional;
                    ToolTip = 'Specifies the last date of the reporting period.';
                }
                field("Amounts in ACY"; "VAT Report Header"."Amounts in Add. Rep. Currency")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amounts in Add. Reporting Currency';
                    Importance = Additional;
                    ToolTip = 'Specifies if you want to report amounts in the additional reporting currency.';
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            "VAT Report Header".FindFirst;
        end;
    }

    labels
    {
    }

    var
        Selection: Option Open,Closed,"Open and Closed";
        PeriodSelection: Option "Before and Within Period","Within Period";
}

