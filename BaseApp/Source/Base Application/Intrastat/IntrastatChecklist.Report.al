report 502 "Intrastat - Checklist"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Intrastat/IntrastatChecklist.rdlc';
    ApplicationArea = BasicEU;
    Caption = 'Intrastat - Checklist';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(JnlTmplName_IntrastatJnlBatch; "Journal Template Name")
            {
            }
            column(Name_IntrastatJnlBatch; Name)
            {
            }
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
                column(StatPer_IntrastatJnlBatch; StrSubstNo(Text001, "Intrastat Jnl. Batch"."Statistics Period"))
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName)
                {
                }
                column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
                {
                }
                column(HeaderLine; HeaderLine)
                {
                }
                column(PrintJnlLines; PrintJnlLines)
                {
                }
                column(NoOfRecordsRTC; NoOfRecordsRTC)
                {
                }
                column(Type_IntrastatJnlLine; Type)
                {
                    IncludeCaption = true;
                }
                column(TariffNo_IntrastatJnlLine; "Tariff No.")
                {
                    IncludeCaption = true;
                }
                column(CountryIntrastatCode; Country."Intrastat Code")
                {
                }
                column(CountryName; Country.Name)
                {
                }
                column(TransType_IntrastatJnlLine; "Transaction Type")
                {
                    IncludeCaption = true;
                }
                column(TransMethod_IntrastatJnlLine; "Transport Method")
                {
                    IncludeCaption = true;
                }
                column(ItemDesc_IntrastatJnlLine; "Item Description")
                {
                    IncludeCaption = true;
                }
                column(TotalWt_IntrastatJnlLine; "Total Weight")
                {
                    IncludeCaption = true;
                }
                column(Quantity_IntrastatJnlLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(StatVal_IntrastatJnlLine; "Statistical Value")
                {
                    IncludeCaption = true;
                }
                column(IntRefNo_IntrastatJnlLine; "Internal Ref. No.")
                {
                    IncludeCaption = true;
                }
                column(SubTotalWeight; SubTotalWeight)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(TotalWeight; TotalWeight)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(NoOfRecords; NoOfRecords)
                {
                }
                column(JnlTmplName_IntrastatJnlLine; "Journal Template Name")
                {
                }
                column(LineNo_IntrastatJnlLine; "Line No.")
                {
                }
                column(IntrastatChecklistCaption; IntrastatChecklistCaptionLbl)
                {
                }
                column(PageCaption; PageCaptionLbl)
                {
                }
                column(VATRegNoCaption; VATRegNoCaptionLbl)
                {
                }
                column(TariffNoCaption; TariffNoCaptionLbl)
                {
                }
                column(CountryRegionCodeCaption; CountryRegionCodeCaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(NoofEntriesCaption; NoofEntriesCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

#if CLEAN19
                    IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Checklist", false);
#else
                    if IntrastatSetup."Use Advanced Checklist" then
                        IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Checklist", false)
                    else
                        IntraJnlManagement.ValidateChecklistReport("Intrastat Jnl. Line");
#endif

                    if Country.Get("Country/Region Code") then;
                    IntrastatJnlLineTemp.Reset();
                    IntrastatJnlLineTemp.SetRange(Type, Type);
                    IntrastatJnlLineTemp.SetRange("Tariff No.", "Tariff No.");
                    IntrastatJnlLineTemp.SetRange("Country/Region Code", "Country/Region Code");
                    IntrastatJnlLineTemp.SetRange("Transaction Type", "Transaction Type");
                    IntrastatJnlLineTemp.SetRange("Transport Method", "Transport Method");
                    if not IntrastatJnlLineTemp.FindFirst then begin
                        IntrastatJnlLineTemp := "Intrastat Jnl. Line";
                        IntrastatJnlLineTemp.Insert();
                        NoOfRecordsRTC += 1;
                    end;
                    if (PrevIntrastatJnlLine.Type <> Type) or
                       (PrevIntrastatJnlLine."Tariff No." <> "Tariff No.") or
                       (PrevIntrastatJnlLine."Country/Region Code" <> "Country/Region Code") or
                       (PrevIntrastatJnlLine."Transaction Type" <> "Transaction Type") or
                       (PrevIntrastatJnlLine."Transport Method" <> "Transport Method")
                    then begin
                        SubTotalWeight := 0;
                        PrevIntrastatJnlLine.SetCurrentKey(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
                        PrevIntrastatJnlLine.SetRange(Type, Type);
                        PrevIntrastatJnlLine.SetRange("Country/Region Code", "Country/Region Code");
                        PrevIntrastatJnlLine.SetRange("Tariff No.", "Tariff No.");
                        PrevIntrastatJnlLine.SetRange("Transaction Type", "Transaction Type");
                        PrevIntrastatJnlLine.SetRange("Transport Method", "Transport Method");
                        PrevIntrastatJnlLine.FindFirst;
                    end;

                    SubTotalWeight := SubTotalWeight + Round("Total Weight", 1);
                    TotalWeight := TotalWeight + Round("Total Weight", 1);
                end;

                trigger OnPreDataItem()
                begin
                    IntrastatJnlLineTemp.DeleteAll();
                    NoOfRecordsRTC := 0;

                    if GetFilter(Type) <> '' then
                        exit;

                    if not IntrastatSetup.Get then
                        exit;

                    if IntrastatSetup."Report Receipts" and IntrastatSetup."Report Shipments" then
                        SetRange(Type)
                    else
                        if IntrastatSetup."Report Receipts" then
                            SetRange(Type, Type::Receipt)
                        else
                            if IntrastatSetup."Report Shipments" then
                                SetRange(Type, Type::Shipment)
                            else
                                Error(NoValuesErr);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");

                GLSetup.Get();
                if "Amounts in Add. Currency" then begin
                    GLSetup.TestField("Additional Reporting Currency");
                    HeaderLine := StrSubstNo(Text002, GLSetup."Additional Reporting Currency");
                end else begin
                    GLSetup.TestField("LCY Code");
                    HeaderLine := StrSubstNo(Text002, GLSetup."LCY Code");
                end;
            end;

            trigger OnPreDataItem()
            begin
                if "Intrastat Jnl. Line".GetFilter("Journal Template Name") <> '' then
                    SetFilter("Journal Template Name", "Intrastat Jnl. Line".GetFilter("Journal Template Name"));
                if "Intrastat Jnl. Line".GetFilter("Journal Batch Name") <> '' then
                    SetFilter(Name, "Intrastat Jnl. Line".GetFilter("Journal Batch Name"));
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowIntrastatJournalLines; PrintJnlLines)
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Show Intrastat Journal Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies if the report will show detailed information from the journal lines. If you do not select this field, it shows only the information that must be reported to the tax authorities and not the lines in the journal.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        SubTotalWeightCaption = 'Sub Total Weight';
    }

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        CompanyInfo."VAT Registration No." := ConvertStr(CompanyInfo."VAT Registration No.", Text000, '    ');
    end;

    var
        Text000: Label 'WwWw';
        Text001: Label 'Statistics Period: %1';
        Text002: Label 'All amounts are in %1.';
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        GLSetup: Record "General Ledger Setup";
        IntrastatJnlLineTemp: Record "Intrastat Jnl. Line" temporary;
        PrevIntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        NoOfRecords: Integer;
        NoOfRecordsRTC: Integer;
        PrintJnlLines: Boolean;
        Heading: Boolean;
        HeaderText: Text;
        HeaderLine: Text;
        SubTotalWeight: Decimal;
        TotalWeight: Decimal;
        IntrastatChecklistCaptionLbl: Label 'Intrastat - Checklist';
        PageCaptionLbl: Label 'Page';
        VATRegNoCaptionLbl: Label 'VAT Reg. No.';
        TariffNoCaptionLbl: Label 'Tariff No.';
        CountryRegionCodeCaptionLbl: Label 'Country/Region Code';
        TotalCaptionLbl: Label 'Total';
        NoofEntriesCaptionLbl: Label 'No. of Entries';
        NoValuesErr: Label 'There are no values to report as per Intrastat Setup.';
}

