report 5912 "Service - Credit Memo"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ServiceCreditMemo.rdlc';
    Caption = 'Service - Credit Memo';
    Permissions = TableData "Sales Shipment Buffer" = rimd;

    dataset
    {
        dataitem("Service Cr.Memo Header"; "Service Cr.Memo Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Customer No.", "No. Printed";
            RequestFilterHeading = 'Posted Service Credit Memo';
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(CompanyInfoPicture; CompanyInfo.Picture)
                    {
                    }
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfo2Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(ServiceCrMemoCopy; StrSubstNo(Text005, CopyText))
                    {
                    }
                    column(CustAddr1; CustAddr[1])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(CustAddr2; CustAddr[2])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(CustAddr3; CustAddr[3])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(CustAddr4; CustAddr[4])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(CustAddr5; CustAddr[5])
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CustAddr6; CustAddr[6])
                    {
                    }
                    column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
                    {
                    }
                    column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfoBankName; CompanyInfo."Bank Name")
                    {
                    }
                    column(CompanyInfoBankAccNo; CompanyInfo."Bank Account No.")
                    {
                    }
                    column(BilltoCustNo_ServiceCrMemoHeader; "Service Cr.Memo Header"."Bill-to Customer No.")
                    {
                    }
                    column(BilltoCustNo_ServiceCrMemoHeaderCaption; "Service Cr.Memo Header".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(PostDt_ServiceCrMemoHeader; Format("Service Cr.Memo Header"."Posting Date"))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(VATRegNo_ServiceCrMemoHeader; "Service Cr.Memo Header"."VAT Registration No.")
                    {
                    }
                    column(No_ServiceCrMemoHeader; "Service Cr.Memo Header"."No.")
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(AppliedToText; AppliedToText)
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(YourRef_ServiceCrMemoHeader; "Service Cr.Memo Header"."Your Reference")
                    {
                    }
                    column(CustAddr7; CustAddr[7])
                    {
                    }
                    column(CustAddr8; CustAddr[8])
                    {
                    }
                    column(CompanyAddr5; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr6; CompanyAddr[6])
                    {
                    }
                    column(DocDate_ServiceCrMemoHeader; Format("Service Cr.Memo Header"."Document Date", 0, 4))
                    {
                    }
                    column(PricesIncVAT_ServiceCrMemoHeader; "Service Cr.Memo Header"."Prices Including VAT")
                    {
                    }
                    column(PricesIncVAT_ServiceCrMemoHeaderCaption; "Service Cr.Memo Header".FieldCaption("Prices Including VAT"))
                    {
                    }
                    column(PageCaption; StrSubstNo(Text006, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(Formatted_PricesIncVAT_ServiceCrMemoHeader; Format("Service Cr.Memo Header"."Prices Including VAT"))
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoFaxNoCaption; CompanyInfoFaxNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoVATRegistrationNoCaption; CompanyInfoVATRegistrationNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoGiroNoCaption; CompanyInfoGiroNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoBankNameCaption; CompanyInfoBankNameCaptionLbl)
                    {
                    }
                    column(CompanyInfoBankAccountNoCaption; CompanyInfoBankAccountNoCaptionLbl)
                    {
                    }
                    column(ServiceCrMemoHeaderNoCaption; ServiceCrMemoHeaderNoCaptionLbl)
                    {
                    }
                    column(ServiceCrMemoHeaderPostingDateCaption; ServiceCrMemoHeaderPostingDateCaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Service Cr.Memo Header";
                        DataItemTableView = SORTING(Number);
                        column(DimText; DimText)
                        {
                        }
                        column(Number_IntegerLine; DimensionLoop1.Number)
                        {
                        }
                        column(HeaderDimensionsCaption; HeaderDimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            DimText := DimTxtArr[Number];
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break;
                            FindDimTxt("Service Cr.Memo Header"."Dimension Set ID");
                            SetRange(Number, 1, DimTxtArrLength);
                        end;
                    }
                    dataitem("Service Cr.Memo Line"; "Service Cr.Memo Line")
                    {
                        DataItemLink = "Document No." = FIELD("No.");
                        DataItemLinkReference = "Service Cr.Memo Header";
                        DataItemTableView = SORTING("Document No.", "Line No.");
                        column(TypeInt; TypeInt)
                        {
                        }
                        column(TotalAmount; TotalAmount)
                        {
                        }
                        column(TotalAmountInclVAT; TotalAmountInclVAT)
                        {
                        }
                        column(TotalInvDiscAmount; TotalInvDiscAmount)
                        {
                        }
                        column(LineNo_ServCrMemoLine; "Service Cr.Memo Line"."Line No.")
                        {
                        }
                        column(VATBaseDisc_ServiceCrMemoHeader; "Service Cr.Memo Header"."VAT Base Discount %")
                        {
                        }
                        column(TotalLineAmount; TotalLineAmount)
                        {
                        }
                        column(LineAmt_ServiceCrMemoLine; "Line Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode;
                            AutoFormatType = 1;
                        }
                        column(Desc_ServCrMemoLine; Description)
                        {
                        }
                        column(No_ServiceCrMemoLine; "No.")
                        {
                        }
                        column(Quantity_ServCrMemoLine; Quantity)
                        {
                        }
                        column(UOM_ServiceCrMemoLine; "Unit of Measure")
                        {
                        }
                        column(No_ServiceCrMemoLineCaption; FieldCaption("No."))
                        {
                        }
                        column(Desc_ServiceCrMemoLineCaption; FieldCaption(Description))
                        {
                        }
                        column(Qty_ServiceCrMemoLineCaption; FieldCaption(Quantity))
                        {
                        }
                        column(UOM_ServiceCrMemoLineCaption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(UnitPrice_ServCrMemoLine; "Unit Price")
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode;
                            AutoFormatType = 2;
                        }
                        column(LineDisc_ServCrMemoLine; "Line Discount %")
                        {
                        }
                        column(VATIdentifier_ServCrMemoLine; "VAT Identifier")
                        {
                        }
                        column(VATIdentifier_ServiceCrMemoLineCaption; FieldCaption("VAT Identifier"))
                        {
                        }
                        column(PostedRcptDate; Format(PostedReceiptDate))
                        {
                        }
                        column(InvDiscAmt_ServiceCrMemoLine; -"Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode;
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(Amt_ServCrMemoLine; Amount)
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode;
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(AmtIncVAT_ServiceCrMemoLine; "Amount Including VAT")
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode;
                            AutoFormatType = 1;
                        }
                        column(AmtIncVATAmt_ServiceCrMemoLine; "Amount Including VAT" - Amount)
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode;
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmtText; VATAmountLine.VATAmountText)
                        {
                        }
                        column(LineAmtInvDiscAmtIncVAT_ServiceCrMemoLine; -("Line Amount" - "Inv. Discount Amount" - "Amount Including VAT"))
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATExemptionVATExemptNo; VATExemption.GetVATExemptNo())
                        {
                        }
                        column(VATExemptionVATExemptDate; Format(VATExemption."VAT Exempt. Date"))
                        {
                        }
                        column(VATExemptionCheck; VATExemptionCheck)
                        {
                        }
                        column(UnitPriceCaption; UnitPriceCaptionLbl)
                        {
                        }
                        column(ServiceCrMemoLineLineDiscountCaption; ServiceCrMemoLineLineDiscountCaptionLbl)
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(PostedReceiptDateCaption; PostedReceiptDateCaptionLbl)
                        {
                        }
                        column(InvDiscountAmountCaption; InvDiscountAmountCaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(LineAmountInvDiscountAmountAmountIncludingVATCaption; LineAmountInvDiscountAmountAmountIncludingVATCaptionLbl)
                        {
                        }
                        column(VATExemptionVATExemptNoCaption; VATExemptionVATExemptNoCaptionLbl)
                        {
                        }
                        column(VATExemptionVATExemptDateCaption; VATExemptionVATExemptDateCaptionLbl)
                        {
                        }
                        column(ServiceLineHidden; Format(ServiceLineHidden, 0, 2))
                        {
                        }
                        dataitem("Service Shipment Buffer"; "Integer")
                        {
                            DataItemTableView = SORTING(Number);
                            column(ServShptBufferPostDt; Format(ServiceShipmentBuffer."Posting Date"))
                            {
                            }
                            column(ServShptBufferQty; ServiceShipmentBuffer.Quantity)
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(ReturnReceiptCaption; ReturnReceiptCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then
                                    ServiceShipmentBuffer.Find('-')
                                else
                                    ServiceShipmentBuffer.Next;
                            end;

                            trigger OnPreDataItem()
                            begin
                                SetRange(Number, 1, ServiceShipmentBuffer.Count);
                            end;
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = SORTING(Number);
                            column(DimText_DimensionLoop2; DimText)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                DimText := DimTxtArr[Number];
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break;

                                FindDimTxt("Service Cr.Memo Line"."Dimension Set ID");
                                SetRange(Number, 1, DimTxtArrLength);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            ServiceShipmentBuffer.DeleteAll;
                            PostedReceiptDate := 0D;
                            if Quantity <> 0 then
                                PostedReceiptDate := FindPostedShipmentDate;

                            if (Type = Type::"G/L Account") and not ShowInternalInfo then
                                "No." := '';

                            VATAmountLine.Init;
                            VATAmountLine."VAT Identifier" := "VAT Identifier";
                            VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            VATAmountLine."Tax Group Code" := "Tax Group Code";
                            VATAmountLine."VAT %" := "VAT %";
                            VATAmountLine."VAT Base" := Amount;
                            VATAmountLine."Amount Including VAT" := "Amount Including VAT";
                            VATAmountLine."Line Amount" := "Line Amount";
                            if "Allow Invoice Disc." then
                                VATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                            VATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                            VATAmountLine."VAT Clause Code" := "VAT Clause Code";
                            VATAmountLine.InsertLine;

                            TotalAmount += Amount;
                            TotalAmountInclVAT += "Amount Including VAT";
                            TotalInvDiscAmount += "Inv. Discount Amount";
                            TotalLineAmount += "Line Amount";
                            TypeInt := Type;

                            ServiceLineHidden := (TypeInt = 0) or ((Quantity < 0) and ("Unit Price" > 0) and (Amount = 0));
                        end;

                        trigger OnPreDataItem()
                        begin
                            VATAmountLine.DeleteAll;
                            ServiceShipmentBuffer.Reset;
                            ServiceShipmentBuffer.DeleteAll;
                            FirstValueEntryNo := 0;
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) and (Amount = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break;
                            SetRange("Line No.", 0, "Line No.");

                            TotalAmount := 0;
                            TotalAmountInclVAT := 0;
                            TotalInvDiscAmount := 0;
                            TotalLineAmount := 0;
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VATAmtLineVATBase; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmt; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineLineAmt; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscBaseAmt; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscAmt; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVAT; VATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATIdent; VATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmountLineVATCaption; VATAmountLineVATCaptionLbl)
                        {
                        }
                        column(VATAmountLineVATBaseCaption; VATAmountLineVATBaseCaptionLbl)
                        {
                        }
                        column(VATAmountLineVATAmountCaption; VATAmountLineVATAmountCaptionLbl)
                        {
                        }
                        column(VATAmountSpecificationCaption; VATAmountSpecificationCaptionLbl)
                        {
                        }
                        column(VATAmountLineVATIdentifierCaption; VATAmountLineVATIdentifierCaptionLbl)
                        {
                        }
                        column(VATAmountLineInvDiscBaseAmountCaption; VATAmountLineInvDiscBaseAmountCaptionLbl)
                        {
                        }
                        column(VATAmountLineLineAmountCaption; VATAmountLineLineAmountCaptionLbl)
                        {
                        }
                        column(VATAmountLineInvoiceDiscountAmountCaption; VATAmountLineInvoiceDiscountAmountCaptionLbl)
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            VATAmountLine.GetLine(Number);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if VATAmountLine.Count = 0 then
                                CurrReport.Break;
                            SetRange(Number, 1, VATAmountLine.Count);
                            CleanAmountsInVATAmountLine;
                        end;
                    }
                    dataitem(VATClauseEntryCounter; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VATClauseVATIdentifier; VATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATClauseCode; VATAmountLine."VAT Clause Code")
                        {
                        }
                        column(VATClauseDescription; VATClause.Description)
                        {
                        }
                        column(VATClauseDescription2; VATClause."Description 2")
                        {
                        }
                        column(VATClauseAmount; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATClausesCaption; VATClausesCap)
                        {
                        }
                        column(VATClauseVATIdentifierCaption; VATAmountLineVATIdentifierCaptionLbl)
                        {
                        }
                        column(VATClauseVATAmtCaption; VATAmountLineVATAmountCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            VATAmountLine.GetLine(Number);
                            if not VATClause.Get(VATAmountLine."VAT Clause Code") then
                                CurrReport.Skip;
                            VATClause.GetDescription("Service Cr.Memo Header");
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(VATClause);
                            SetRange(Number, 1, VATAmountLine.Count);
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        column(CustNo_ServiceCrMemoHeader; "Service Cr.Memo Header"."Customer No.")
                        {
                        }
                        column(CustNo_ServiceCrMemoHeaderCaption; "Service Cr.Memo Header".FieldCaption("Customer No."))
                        {
                        }
                        column(ShipToAddr1; ShipToAddr[1])
                        {
                        }
                        column(ShipToAddr2; ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr3; ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr4; ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr5; ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr6; ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr7; ShipToAddr[7])
                        {
                        }
                        column(ShipToAddr8; ShipToAddr[8])
                        {
                        }
                        column(ShiptoAddressCaption; ShiptoAddressCaptionLbl)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break;
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := Text004;
                        OutputNo += 1;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode then
                        CODEUNIT.Run(CODEUNIT::"Service Cr. Memo-Printed", "Service Cr.Memo Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            var
                ServiceHeader: Record "Service Header";
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                FormatAddressFields("Service Cr.Memo Header");
                FormatDocumentFields("Service Cr.Memo Header");

                ServiceHeader.TransferFields("Service Cr.Memo Header");
                ServiceHeader.FindVATExemption(VATExemption, VATExemptionCheck, true);
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
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Service;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
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
    }

    trigger OnInitReport()
    begin
        GLSetup.Get;
        CompanyInfo.Get;
        ServiceSetup.Get;

        case ServiceSetup."Logo Position on Documents" of
            ServiceSetup."Logo Position on Documents"::"No Logo":
                ;
            ServiceSetup."Logo Position on Documents"::Left:
                begin
                    CompanyInfo.CalcFields(Picture);
                end;
            ServiceSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get;
                    CompanyInfo1.CalcFields(Picture);
                end;
            ServiceSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get;
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;
    end;

    var
        Text003: Label '(Applies to %1 %2)';
        Text004: Label 'COPY';
        Text005: Label 'Service - Credit Memo %1';
        Text006: Label 'Page %1';
        GLSetup: Record "General Ledger Setup";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        ServiceSetup: Record "Service Mgt. Setup";
        VATAmountLine: Record "VAT Amount Line" temporary;
        VATClause: Record "VAT Clause";
        DimSetEntry: Record "Dimension Set Entry";
        VATExemption: Record "VAT Exemption";
        ServiceShipmentBuffer: Record "Service Shipment Buffer" temporary;
        RespCenter: Record "Responsibility Center";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        SalesPersonText: Text[30];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        AppliedToText: Text;
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        TypeInt: Integer;
        CopyText: Text[30];
        ShowShippingAddr: Boolean;
        DimText: Text[120];
        ShowInternalInfo: Boolean;
        FirstValueEntryNo: Integer;
        PostedReceiptDate: Date;
        NextEntryNo: Integer;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalInvDiscAmount: Decimal;
        TotalLineAmount: Decimal;
        DimTxtArrLength: Integer;
        DimTxtArr: array[500] of Text[50];
        VATExemptionCheck: Boolean;
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoFaxNoCaptionLbl: Label 'Fax No.';
        CompanyInfoVATRegistrationNoCaptionLbl: Label 'VAT Reg. No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccountNoCaptionLbl: Label 'Account No.';
        ServiceCrMemoHeaderNoCaptionLbl: Label 'Credit Memo No.';
        ServiceCrMemoHeaderPostingDateCaptionLbl: Label 'Posting Date';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        UnitPriceCaptionLbl: Label 'Unit Price';
        ServiceCrMemoLineLineDiscountCaptionLbl: Label 'Disc. %';
        AmountCaptionLbl: Label 'Amount';
        PostedReceiptDateCaptionLbl: Label 'Posted Return Receipt Date';
        InvDiscountAmountCaptionLbl: Label 'Inv. Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        LineAmountInvDiscountAmountAmountIncludingVATCaptionLbl: Label 'Payment Discount on VAT';
        VATExemptionVATExemptNoCaptionLbl: Label 'Customer VAT Exemption No.';
        VATExemptionVATExemptDateCaptionLbl: Label 'Customer VAT Exemption Date';
        ReturnReceiptCaptionLbl: Label 'Return Receipt';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        VATClausesCap: Label 'VAT Clause';
        VATAmountLineVATCaptionLbl: Label 'VAT %';
        VATAmountLineVATBaseCaptionLbl: Label 'VAT Base';
        VATAmountLineVATAmountCaptionLbl: Label 'VAT Amount';
        VATAmountSpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATAmountLineVATIdentifierCaptionLbl: Label 'VAT Identifier';
        VATAmountLineInvDiscBaseAmountCaptionLbl: Label 'Inv. Disc. Base Amount';
        VATAmountLineLineAmountCaptionLbl: Label 'Line Amount';
        VATAmountLineInvoiceDiscountAmountCaptionLbl: Label 'Invoice Discount Amount';
        TotalCaptionLbl: Label 'Total';
        ShiptoAddressCaptionLbl: Label 'Ship-to Address';
        ServiceLineHidden: Boolean;

    procedure FindPostedShipmentDate(): Date
    var
        ServiceShipmentBuffer2: Record "Service Shipment Buffer" temporary;
    begin
        NextEntryNo := 1;

        case "Service Cr.Memo Line".Type of
            "Service Cr.Memo Line".Type::Item:
                GenerateBufferFromValueEntry("Service Cr.Memo Line");
            "Service Cr.Memo Line".Type::" ":
                exit(0D);
        end;

        ServiceShipmentBuffer.Reset;
        ServiceShipmentBuffer.SetRange("Document No.", "Service Cr.Memo Line"."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", "Service Cr.Memo Line"."Line No.");

        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer2 := ServiceShipmentBuffer;
            if ServiceShipmentBuffer.Next = 0 then begin
                ServiceShipmentBuffer.Get(ServiceShipmentBuffer2."Document No.", ServiceShipmentBuffer2."Line No.", ServiceShipmentBuffer2.
                  "Entry No.");
                ServiceShipmentBuffer.Delete;
                exit(ServiceShipmentBuffer2."Posting Date");
            end;
            ServiceShipmentBuffer.CalcSums(Quantity);
            if ServiceShipmentBuffer.Quantity <> "Service Cr.Memo Line".Quantity then begin
                ServiceShipmentBuffer.DeleteAll;
                exit("Service Cr.Memo Header"."Posting Date");
            end;
        end else
            exit("Service Cr.Memo Header"."Posting Date");
    end;

    procedure GenerateBufferFromValueEntry(ServiceCrMemoLine2: Record "Service Cr.Memo Line")
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalQuantity: Decimal;
        Quantity: Decimal;
    begin
        TotalQuantity := ServiceCrMemoLine2."Quantity (Base)";
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", ServiceCrMemoLine2."Document No.");
        ValueEntry.SetRange("Posting Date", "Service Cr.Memo Header"."Posting Date");
        ValueEntry.SetRange("Item Charge No.", '');
        ValueEntry.SetFilter("Entry No.", '%1..', FirstValueEntryNo);
        if ValueEntry.Find('-') then
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then begin
                    if ServiceCrMemoLine2."Qty. per Unit of Measure" <> 0 then
                        Quantity := ValueEntry."Invoiced Quantity" / ServiceCrMemoLine2."Qty. per Unit of Measure"
                    else
                        Quantity := ValueEntry."Invoiced Quantity";
                    AddBufferEntry(
                      ServiceCrMemoLine2,
                      -Quantity,
                      ItemLedgerEntry."Posting Date");
                    TotalQuantity := TotalQuantity - ValueEntry."Invoiced Quantity";
                end;
                FirstValueEntryNo := ValueEntry."Entry No." + 1;
            until (ValueEntry.Next = 0) or (TotalQuantity = 0);
    end;

    procedure AddBufferEntry(ServiceCrMemoLine: Record "Service Cr.Memo Line"; QtyOnShipment: Decimal; PostingDate: Date)
    begin
        ServiceShipmentBuffer.SetRange("Document No.", ServiceCrMemoLine."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", ServiceCrMemoLine."Line No.");
        ServiceShipmentBuffer.SetRange("Posting Date", PostingDate);
        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer.Quantity := ServiceShipmentBuffer.Quantity - QtyOnShipment;
            ServiceShipmentBuffer.Modify;
            exit;
        end;

        with ServiceShipmentBuffer do begin
            Init;
            "Document No." := ServiceCrMemoLine."Document No.";
            "Line No." := ServiceCrMemoLine."Line No.";
            "Entry No." := NextEntryNo;
            Type := ServiceCrMemoLine.Type;
            "No." := ServiceCrMemoLine."No.";
            Quantity := -QtyOnShipment;
            "Posting Date" := PostingDate;
            Insert;
            NextEntryNo := NextEntryNo + 1
        end;
    end;

    procedure FindDimTxt(DimSetID: Integer)
    var
        Separation: Text[5];
        i: Integer;
        TxtToAdd: Text[120];
        StartNewLine: Boolean;
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        DimTxtArrLength := 0;
        for i := 1 to ArrayLen(DimTxtArr) do
            DimTxtArr[i] := '';
        if not DimSetEntry.FindSet then
            exit;
        Separation := '; ';
        repeat
            TxtToAdd := DimSetEntry."Dimension Code" + ' - ' + DimSetEntry."Dimension Value Code";
            if DimTxtArrLength = 0 then
                StartNewLine := true
            else
                StartNewLine := StrLen(DimTxtArr[DimTxtArrLength]) + StrLen(Separation) + StrLen(TxtToAdd) > MaxStrLen(DimTxtArr[1]);
            if StartNewLine then begin
                DimTxtArrLength += 1;
                DimTxtArr[DimTxtArrLength] := TxtToAdd
            end else
                DimTxtArr[DimTxtArrLength] := DimTxtArr[DimTxtArrLength] + Separation + TxtToAdd;
        until DimSetEntry.Next = 0;
    end;

    procedure InitializeRequest(NewShowInternalInfo: Boolean)
    begin
        ShowInternalInfo := NewShowInternalInfo;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;

    local procedure FormatAddressFields(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        FormatAddr.GetCompanyAddr(ServiceCrMemoHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.ServiceCrMemoBillTo(CustAddr, ServiceCrMemoHeader);
        ShowShippingAddr := FormatAddr.ServiceCrMemoShipTo(ShipToAddr, CustAddr, ServiceCrMemoHeader);
    end;

    local procedure FormatDocumentFields(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        with ServiceCrMemoHeader do begin
            FormatDocument.SetTotalLabels("Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
            FormatDocument.SetSalesPerson(SalesPurchPerson, "Salesperson Code", SalesPersonText);

            ReferenceText := FormatDocument.SetText("Your Reference" <> '', FieldCaption("Your Reference"));
            VATNoText := FormatDocument.SetText("VAT Registration No." <> '', FieldCaption("VAT Registration No."));
            AppliedToText :=
              FormatDocument.SetText(
                "Applies-to Doc. No." <> '', Format(StrSubstNo(Text003, Format("Applies-to Doc. Type"), "Applies-to Doc. No.")));
        end;
    end;

    local procedure CleanAmountsInVATAmountLine()
    begin
        VATAmountLine.SetRange("VAT Calculation Type", VATAmountLine."VAT Calculation Type"::"Full VAT");
        VATAmountLine.ModifyAll("Line Amount", 0);
        VATAmountLine.ModifyAll("Inv. Disc. Base Amount", 0);
        VATAmountLine.SetRange("VAT Calculation Type");
    end;
}

