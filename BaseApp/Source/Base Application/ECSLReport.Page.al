page 321 "ECSL Report"
{
    Caption = 'EC Sales List Report';
    Description = 'EC Sales List Report';
    LinksAllowed = false;
    PageType = Document;
    ShowFilter = false;
    SourceTable = "VAT Report Header";
    SourceTableView = WHERE("VAT Report Config. Code" = FILTER(VIES));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("VAT Report Config. Code"; "VAT Report Config. Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the appropriate configuration code.';
                    Visible = false;
                }
                field("Original Report No."; "Original Report No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the original VAT report if the VAT Report Type field is set to a value other than Standard.';
                    Visible = false;
                }
                field(Status; Status)
                {
                    ApplicationArea = BasicEU;
                    DrillDown = false;
                    Enabled = false;
                    ToolTip = 'Specifies whether the report is in progress, is completed, or contains errors.';
                }
                field(ViewErrors; ViewErrors)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'View Errors';
                    Editable = false;
                    ToolTip = 'Specifies the link to a page where you can view errors that the tax authority found in the report.';
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates to use to filter the amounts.';
                    Visible = false;

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        // SETFILTER("Date Filter",DateFilter);
                        CurrPage.Update;
                    end;
                }
                field("Report Period No."; "Report Period No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the specific reporting period to use.';

                    trigger OnValidate()
                    var
                        ECSLVATReportLine: Record "ECSL VAT Report Line";
                    begin
                        ECSLVATReportLine.ClearLines(Rec);
                    end;
                }
                field(ReportPeriodType; "Report Period Type")
                {
                    ApplicationArea = BasicEU;
                    OptionCaption = ',Month,Quarter,,Bi-Monthly';
                    ToolTip = 'Specifies the length of the reporting period.';

                    trigger OnValidate()
                    var
                        ECSLVATReportLine: Record "ECSL VAT Report Line";
                    begin
                        ECSLVATReportLine.ClearLines(Rec);
                    end;
                }
                field("Report Year"; "Report Year")
                {
                    ApplicationArea = BasicEU;
                    LookupPageID = "Date Lookup";
                    ToolTip = 'Specifies the year of the reporting period.';

                    trigger OnValidate()
                    var
                        ECSLVATReportLine: Record "ECSL VAT Report Line";
                    begin
                        ECSLVATReportLine.ClearLines(Rec);
                    end;
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = BasicEU;
                    Importance = Additional;
                    ToolTip = 'Specifies the first date of the reporting period.';

                    trigger OnValidate()
                    begin
                        ClearPeriod;
                    end;
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = BasicEU;
                    Importance = Additional;
                    ToolTip = 'Specifies the last date of the reporting period.';

                    trigger OnValidate()
                    begin
                        ClearPeriod;
                    end;
                }
            }
            part(ECSLReportLines; "ECSL Report Subform")
            {
                ApplicationArea = BasicEU;
            }
            part(ErrorMessagesPart; "Error Messages Part")
            {
                ApplicationArea = BasicEU;
                Caption = 'Messages';
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SuggestLines)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Suggest Lines';
                    Image = SuggestLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Create EC Sales List entries based on information gathered from sales-related documents.';

                    trigger OnAction()
                    begin
                        UpdateSubForm;
                        // VATReportMediator.GetLines(Rec);
                    end;
                }
                action(Submit)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Submit';
                    Image = SendElectronicDocument;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Submits the EC Sales List report to the tax authority''s reporting service.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Export(Rec);
                        Message(ReportSubmittedMsg);
                    end;
                }
                action("Mark as Submitted")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Mark as Su&bmitted';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Indicate that the tax authority has approved and returned the report.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Submit(Rec);
                        Message(MarkAsSubmittedMsg);
                    end;
                }
                action("Cancel Submission")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Cancel Submission';
                    Image = Cancel;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Cancels previously submitted report.';

                    trigger OnAction()
                    begin
                        VATReportMediator.Reopen(Rec);
                        Message(CancelReportSentMsg);
                    end;
                }
                action("Log Entries")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Log Entries';
                    Image = ErrorLog;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'View a history of communications with the tax authority.';

                    trigger OnAction()
                    begin
                        // MESSAGE('Show errors');
                    end;
                }
                action(Release)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Verify that the report includes all of the required information, and prepare it for submission.';

                    trigger OnAction()
                    begin
                        // MESSAGE('Release');
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'Open the report again to make changes.';

                    trigger OnAction()
                    begin
                        // MESSAGE('Reopen');
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = BasicEU;
                Caption = '&Print';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare the report for printing by specifying the information it will include.';
                Visible = false;

                trigger OnAction()
                begin
                    VATReportMediator.Print(Rec);
                end;
            }
            action("Report Setup")
            {
                ApplicationArea = BasicEU;
                Caption = 'Report Setup';
                Image = Setup;
                RunObject = Page "VAT Report Setup";
                ToolTip = 'Specifies the setup that will be used for the VAT reports submission.';
            }
        }
    }

    var
        VATReportMediator: Codeunit "VAT Report Mediator";
        DateFilter: Text[30];
        ViewErrors: Text;
        ReportSubmittedMsg: Label 'The report has been successfully submitted.';
        CancelReportSentMsg: Label 'The cancel request has been sent.';
        MarkAsSubmittedMsg: Label 'The report has been marked as submitted.';

    local procedure UpdateSubForm()
    begin
        // VATStatementName.FINDFIRST;
        // VATStatementName.SETFILTER("Date Filter",DateFilter);
        // CurrPage.VATReportLines.PAGE.UpdateForm(VATStatementName,Selection,PeriodSelection,UseAmtsInAddCurr);

        // TO DO - Update ECSL
    end;

    local procedure ClearPeriod()
    begin
        // "Period No." := 0;
        // "Period Type" := "Period Type"::" ";
    end;
}

