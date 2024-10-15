page 741 "VAT Report Subform"
{
    Caption = 'Lines';
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Report Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line Type"; "Line Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the type of the line in the VAT report.';
                }
                field(Base; Base)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT amount for the report line. This is calculated based on the value of the Base field.';

                    trigger OnAssistEdit()
                    var
                        VATReportLineRelation: Record "VAT Report Line Relation";
                        VATEntry: Record "VAT Entry";
                        FilterText: Text[1024];
                        TableNo: Integer;
                    begin
                        ShowVATReportEntries("VAT Report No.", "Line No.");
                    end;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT registration number of the customer or vendor that the VAT entry is linked to.';
                }
                field("EU 3-Party Trade"; "EU 3-Party Trade")
                {
                    ApplicationArea = VAT;
                }
                field("EU Service"; "EU Service")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Indicates whether the line is associated with a EU Service.';
                }
            }
        }
    }

    actions
    {
    }

    local procedure ShowVATReportEntries(VATReportNo: Code[20]; VATReportLineNo: Integer)
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
        VATEntry: Record "VAT Entry";
        VATEntryTmp: Record "VAT Entry" temporary;
    begin
        VATReportLineRelation.SetRange("VAT Report No.", VATReportNo);
        VATReportLineRelation.SetRange("VAT Report Line No.", VATReportLineNo);
        VATReportLineRelation.SetRange("Table No.", DATABASE::"VAT Entry");
        if VATReportLineRelation.FindSet then begin
            repeat
                VATEntry.Get(VATReportLineRelation."Entry No.");
                VATEntryTmp.TransferFields(VATEntry, true);
                VATEntryTmp.Insert;
            until VATReportLineRelation.Next = 0;
            PAGE.RunModal(0, VATEntryTmp);
        end;
    end;
}

