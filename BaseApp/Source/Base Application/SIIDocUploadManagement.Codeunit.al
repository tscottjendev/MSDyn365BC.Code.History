codeunit 10752 "SII Doc. Upload Management"
{

    trigger OnRun()
    begin
    end;

    var
        SIISetup: Record "SII Setup";
        SIIXMLCreator: Codeunit "SII XML Creator";
        X509Certificate2: DotNet X509Certificate2;
        RequestType: Option InvoiceIssuedRegistration,InvoiceReceivedRegistration,PaymentSentRegistration,PaymentReceivedRegistration,CollectionInCashRegistration;
        NoCertificateErr: Label 'Could not get certificate.';
        NoConnectionErr: Label 'Could not establish connection.';
        NoResponseErr: Label 'Could not get response.';
        NoCustLedgerEntryErr: Label 'Customer Ledger Entry could not be found.';
        NoDetailedCustLedgerEntryErr: Label 'Detailed Customer Ledger Entry could not be found.';
        NoVendLedgerEntryErr: Label 'Vendor Ledger Entry could not be found.';
        NoDetailedVendLedgerEntryErr: Label 'Detailed Vendor Ledger Entry could not be found.';
        CommunicationErr: Label 'Communication error: %1.', Comment = '@1 is the error message.';
        ParseMatchDocumentErr: Label 'Parse error: couldn''t match the documents.';

    local procedure InvokeBatchSoapRequest(SIISession: Record "SII Session"; var TempSIIHistoryBuffer: Record "SII History" temporary; RequestText: Text; RequestType: Option InvoiceIssuedRegistration,InvoiceReceivedRegistration,PaymentSentRegistration,PaymentReceivedRegistration,CollectionInCashRegistration; var ResponseText: Text): Boolean
    var
        WebRequest: DotNet WebRequest;
        HttpWebRequest: DotNet HttpWebRequest;
        RequestStream: DotNet Stream;
        Encoding: DotNet Encoding;
        ByteArray: DotNet Array;
        Uri: DotNet Uri;
        HttpWebResponse: DotNet HttpWebResponse;
        StatusCode: DotNet HttpStatusCode;
        WebServiceUrl: Text;
        StatusDescription: Text[250];
    begin
        if not GetCertificate then begin
            ProcessBatchResponseCommunicationError(TempSIIHistoryBuffer, NoCertificateErr);
            exit(false);
        end;

        case RequestType of
            RequestType::InvoiceIssuedRegistration:
                WebServiceUrl := SIISetup.InvoicesIssuedEndpointUrl;
            RequestType::InvoiceReceivedRegistration:
                WebServiceUrl := SIISetup.InvoicesReceivedEndpointUrl;
            RequestType::PaymentReceivedRegistration:
                WebServiceUrl := SIISetup.PaymentsReceivedEndpointUrl;
            RequestType::PaymentSentRegistration:
                WebServiceUrl := SIISetup.PaymentsIssuedEndpointUrl;
            RequestType::CollectionInCashRegistration:
                WebServiceUrl := SIISetup.CollectionInCashEndpointUrl;
        end;

        OnInvokeBatchSoapRequestOnBeforeStoreRequestXML(RequestText);

        SIISession.StoreRequestXml(RequestText);

        HttpWebRequest := WebRequest.Create(Uri.Uri(WebServiceUrl));
        HttpWebRequest.ClientCertificates.Add(X509Certificate2);
        HttpWebRequest.Method := 'POST';
        HttpWebRequest.ContentType := 'application/xml';

        ByteArray := Encoding.UTF8.GetBytes(RequestText);
        HttpWebRequest.ContentLength := ByteArray.Length;
        if not TryCreateRequestStream(HttpWebRequest, RequestStream) then begin
            ProcessBatchResponseCommunicationError(TempSIIHistoryBuffer, NoConnectionErr);
            exit(false);
        end;

        RequestStream.Write(ByteArray, 0, ByteArray.Length);

        if not TryGetWebResponse(HttpWebRequest, HttpWebResponse) then begin
            ProcessBatchResponseCommunicationError(TempSIIHistoryBuffer, NoResponseErr);
            exit(false);
        end;

        StatusCode := HttpWebResponse.StatusCode;
        StatusDescription := HttpWebResponse.StatusDescription;
        ResponseText := ReadHttpResponseAsText(HttpWebResponse);
        SIISession.StoreResponseXml(ResponseText);
        if not StatusCode.Equals(StatusCode.Accepted) and not StatusCode.Equals(StatusCode.OK) then begin
            ProcessBatchResponseCommunicationError(
              TempSIIHistoryBuffer, StrSubstNo(CommunicationErr, StatusDescription));
            exit(false);
        end;

        exit(true);
    end;

    [TryFunction]
    local procedure TryCreateRequestStream(HttpWebRequest: DotNet HttpWebRequest; var RequestStream: DotNet Stream)
    begin
        RequestStream := HttpWebRequest.GetRequestStream;
    end;

    [TryFunction]
    local procedure TryGetWebResponse(HttpWebRequest: DotNet HttpWebRequest; var HttpWebResponse: DotNet HttpWebResponse)
    var
        Task: DotNet Task1;
    begin
        Task := HttpWebRequest.GetResponseAsync;
        HttpWebResponse := Task.Result;
    end;

    local procedure GetCertificate(): Boolean
    begin
        exit(SIISetup.LoadCertificateFromBlob(X509Certificate2));
    end;

    local procedure ReadHttpResponseAsText(HttpWebResponse: DotNet HttpWebResponse) ResponseText: Text
    var
        StreamReader: DotNet StreamReader;
    begin
        StreamReader := StreamReader.StreamReader(HttpWebResponse.GetResponseStream);
        ResponseText := StreamReader.ReadToEnd;
    end;

    local procedure ExecutePendingRequests(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; BatchSubmissions: Boolean)
    var
        SIISession: Record "SII Session";
        XMLDoc: DotNet XmlDocument;
        IsInvokeSoapRequest: Boolean;
    begin
        SIIDocUploadState.FindSet(true);
        PreExecutePendingRequests(SIISession, IsInvokeSoapRequest, not BatchSubmissions);
        repeat
            PreExecutePendingRequests(SIISession, IsInvokeSoapRequest, BatchSubmissions);
            ExecutePendingRequestsPerDocument(SIIDocUploadState, TempSIIHistoryBuffer, XMLDoc, IsInvokeSoapRequest, SIISession.Id);
            PostExecutePendingRequests(SIIDocUploadState, TempSIIHistoryBuffer, SIISession, XMLDoc, IsInvokeSoapRequest, BatchSubmissions);
        until SIIDocUploadState.Next = 0;
        PostExecutePendingRequests(SIIDocUploadState, TempSIIHistoryBuffer, SIISession, XMLDoc, IsInvokeSoapRequest, not BatchSubmissions);
    end;

    local procedure ExecutePendingRequestsPerDocument(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; var XMLDoc: DotNet XmlDocument; var IsInvokeSoapRequest: Boolean; SIISessionId: Integer)
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        IsSupported: Boolean;
        Message: Text;
    begin
        TempSIIHistoryBuffer.SetRange("Document State Id", SIIDocUploadState.Id);
        if TempSIIHistoryBuffer.FindSet then
            repeat
                TempSIIHistoryBuffer."Session Id" := SIISessionId;
                if not TryGenerateXml(SIIDocUploadState, TempSIIHistoryBuffer, XMLDoc, IsSupported, Message) then begin
                    DotNetExceptionHandler.Collect;
                    TempSIIHistoryBuffer.Status := TempSIIHistoryBuffer.Status::Failed;
                    TempSIIHistoryBuffer."Error Message" :=
                      CopyStr(DotNetExceptionHandler.GetMessage, 1, MaxStrLen(TempSIIHistoryBuffer."Error Message"));
                    SIIDocUploadState.Status := SIIDocUploadState.Status::Failed;
                    SIIDocUploadState.Modify;
                end else
                    if not IsSupported then begin
                        TempSIIHistoryBuffer.Status := TempSIIHistoryBuffer.Status::"Not Supported";
                        SIIDocUploadState.Status := SIIDocUploadState.Status::"Not Supported";
                        TempSIIHistoryBuffer."Error Message" := CopyStr(Message, 1, MaxStrLen(TempSIIHistoryBuffer."Error Message"));
                        SIIDocUploadState.Modify;
                    end else
                        IsInvokeSoapRequest := true or IsInvokeSoapRequest;
                TempSIIHistoryBuffer.Modify;
            until TempSIIHistoryBuffer.Next = 0;
    end;

    local procedure PreExecutePendingRequests(var SIISession: Record "SII Session"; var IsInvokeSoapRequest: Boolean; SkipPrePost: Boolean)
    begin
        if SkipPrePost then
            exit;

        SIIXMLCreator.Reset;
        CreateNewSessionRecord(SIISession);
        IsInvokeSoapRequest := false;
    end;

    local procedure PostExecutePendingRequests(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; SIISession: Record "SII Session"; XMLDoc: DotNet XmlDocument; IsInvokeSoapRequest: Boolean; SkipPrePost: Boolean)
    var
        ResponseText: Text;
    begin
        if SkipPrePost then
            exit;

        TempSIIHistoryBuffer.SetRange("Document State Id");
        TempSIIHistoryBuffer.SetRange("Session Id", SIISession.Id);
        TempSIIHistoryBuffer.SetRange(Status, TempSIIHistoryBuffer.Status::Pending);
        if IsInvokeSoapRequest then
            if InvokeBatchSoapRequest(SIISession, TempSIIHistoryBuffer, XMLDoc.OuterXml, RequestType, ResponseText) then
                ParseBatchResponse(SIIDocUploadState, TempSIIHistoryBuffer, ResponseText);

        TempSIIHistoryBuffer.SetRange("Session Id");
        TempSIIHistoryBuffer.SetRange(Status);
    end;

    [Scope('OnPrem')]
    procedure UploadPendingDocuments()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        if not GetAndCheckSetup then
            exit;

        if SIISetup."Enable Batch Submissions" and (SIISetup."Job Batch Submission Threshold" > 0) then begin
            SetDocStateFilters(SIIDocUploadState, false);
            if SIIDocUploadState.Count < SIISetup."Job Batch Submission Threshold" then
                exit;
        end;

        // Process only automatically-created documents
        UploadDocuments(false);
    end;

    [Scope('OnPrem')]
    procedure UploadManualDocument()
    begin
        if not GetAndCheckSetup then
            exit;

        // Process only manually-created documents
        UploadDocuments(true);
    end;

    local procedure UploadDocuments(IsManual: Boolean)
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        TempSIIHistoryBuffer: Record "SII History" temporary;
    begin
        with SIIDocUploadState do begin
            SetDocStateFilters(SIIDocUploadState, IsManual);
            if not IsEmpty then begin
                CreateHistoryPendingBuffer(TempSIIHistoryBuffer, IsManual);

                // Customer Invoice
                UploadDocumentsPerTransactionFilter(
                  SIIDocUploadState, TempSIIHistoryBuffer, "Document Source"::"Customer Ledger", "Document Type"::Invoice, '');
                // Customer Credit Memo
                UploadDocumentsPerTransactionFilter(
                  SIIDocUploadState, TempSIIHistoryBuffer, "Document Source"::"Customer Ledger", "Document Type"::"Credit Memo", '0');
                // Customer Credit Memo Removal
                UploadDocumentsPerTransactionFilter(
                  SIIDocUploadState, TempSIIHistoryBuffer, "Document Source"::"Customer Ledger", "Document Type"::"Credit Memo", '1');
                // Customer Payment
                UploadDocumentsPerTransactionFilter(
                  SIIDocUploadState, TempSIIHistoryBuffer, "Document Source"::"Detailed Customer Ledger", "Document Type"::Payment, '');
                // Vendor Invoice
                UploadDocumentsPerTransactionFilter(
                  SIIDocUploadState, TempSIIHistoryBuffer, "Document Source"::"Vendor Ledger", "Document Type"::Invoice, '');
                // Vendor Credit Memo
                UploadDocumentsPerTransactionFilter(
                  SIIDocUploadState, TempSIIHistoryBuffer, "Document Source"::"Vendor Ledger", "Document Type"::"Credit Memo", '0');
                // Vendor Credit Memo Removal
                UploadDocumentsPerTransactionFilter(
                  SIIDocUploadState, TempSIIHistoryBuffer, "Document Source"::"Vendor Ledger", "Document Type"::"Credit Memo", '1');
                // Vendor Payment
                UploadDocumentsPerTransactionFilter(
                  SIIDocUploadState, TempSIIHistoryBuffer, "Document Source"::"Detailed Vendor Ledger", "Document Type"::Payment, '');

                Reset;
                SetDocStateFilters(SIIDocUploadState, IsManual);
                // Collection in cash
                UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, "Transaction Type"::"Collection In Cash", false);
                UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, "Transaction Type"::"Collection In Cash", true);

                SaveHistoryPendingBuffer(TempSIIHistoryBuffer, IsManual);
            end;
        end;
    end;

    local procedure UploadDocumentsPerTransactionFilter(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; DocumentSource: Option; DocumentType: Option; IsCreditMemoRemovalFilter: Text)
    begin
        with SIIDocUploadState do begin
            SetRange("Document Source", DocumentSource);
            SetRange("Document Type", DocumentType);
            SetFilter("Is Credit Memo Removal", IsCreditMemoRemovalFilter);
            UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, "Transaction Type"::Regular, false);
            UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, "Transaction Type"::Regular, true);
            UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, "Transaction Type"::RetryAccepted, false);
            UploadDocumentsPerFilter(SIIDocUploadState, TempSIIHistoryBuffer, "Transaction Type"::RetryAccepted, true);
        end;
    end;

    local procedure UploadDocumentsPerFilter(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; TransactionType: Option; RetryAccepted: Boolean)
    begin
        with SIIDocUploadState do begin
            SetRange("Transaction Type", TransactionType);
            SetRange("Retry Accepted", RetryAccepted);
            if not IsEmpty then
                ExecutePendingRequests(
                  SIIDocUploadState, TempSIIHistoryBuffer, SIISetup."Enable Batch Submissions");
        end;
    end;

    [TryFunction]
    local procedure TryGenerateXml(SIIDocUploadState: Record "SII Doc. Upload State"; SIIHistory: Record "SII History"; var XMLDoc: DotNet XmlDocument; var IsSupported: Boolean; var Message: Text)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No.");
        SIIXMLCreator.SetIsRetryAccepted(SIIDocUploadState."Retry Accepted");
        case SIIDocUploadState."Document Source" of
            SIIDocUploadState."Document Source"::"Customer Ledger":
                begin
                    if SIIDocUploadState."Transaction Type" = SIIDocUploadState."Transaction Type"::"Collection In Cash" then begin
                        CustLedgerEntry.Init;
                        CustLedgerEntry."Customer No." := SIIDocUploadState."CV No.";
                        CustLedgerEntry."Posting Date" := SIIDocUploadState."Posting Date";
                        CustLedgerEntry."Sales (LCY)" := SIIDocUploadState."Total Amount In Cash";
                        RequestType := RequestType::CollectionInCashRegistration;
                    end else begin
                        CustLedgerEntry.SetRange("Entry No.", SIIDocUploadState."Entry No");
                        if not CustLedgerEntry.FindFirst then
                            Error(NoCustLedgerEntryErr);
                        RequestType := RequestType::InvoiceIssuedRegistration;
                    end;
                    IsSupported :=
                      SIIXMLCreator.GenerateXml(
                        CustLedgerEntry, XMLDoc, SIIHistory."Upload Type", SIIDocUploadState."Is Credit Memo Removal");
                end;
            SIIDocUploadState."Document Source"::"Vendor Ledger":
                begin
                    VendorLedgerEntry.SetRange("Entry No.", SIIDocUploadState."Entry No");
                    if VendorLedgerEntry.FindFirst then begin
                        RequestType := RequestType::InvoiceReceivedRegistration;
                        IsSupported :=
                          SIIXMLCreator.GenerateXml(
                            VendorLedgerEntry, XMLDoc, SIIHistory."Upload Type", SIIDocUploadState."Is Credit Memo Removal");
                    end else
                        Error(NoVendLedgerEntryErr);
                end;
            SIIDocUploadState."Document Source"::"Detailed Customer Ledger":
                begin
                    DetailedCustLedgEntry.SetRange("Entry No.", SIIDocUploadState."Entry No");
                    if DetailedCustLedgEntry.FindFirst then begin
                        RequestType := RequestType::PaymentReceivedRegistration;
                        IsSupported :=
                          SIIXMLCreator.GenerateXml(
                            DetailedCustLedgEntry, XMLDoc, SIIHistory."Upload Type", SIIDocUploadState."Is Credit Memo Removal");
                    end else
                        Error(NoDetailedCustLedgerEntryErr);
                end;
            SIIDocUploadState."Document Source"::"Detailed Vendor Ledger":
                begin
                    DetailedVendorLedgEntry.SetRange("Entry No.", SIIDocUploadState."Entry No");
                    if DetailedVendorLedgEntry.FindFirst then begin
                        RequestType := RequestType::PaymentSentRegistration;
                        IsSupported :=
                          SIIXMLCreator.GenerateXml(
                            DetailedVendorLedgEntry, XMLDoc, SIIHistory."Upload Type", SIIDocUploadState."Is Credit Memo Removal");
                    end else
                        Error(NoDetailedVendLedgerEntryErr);
                end;
        end;

        if not IsSupported then
            Message := SIIXMLCreator.GetLastErrorMsg;
    end;

    local procedure CreateHistoryPendingBuffer(var TempSIIHistoryBuffer: Record "SII History" temporary; IsManual: Boolean)
    var
        SIIHistory: Record "SII History";
    begin
        with SIIHistory do begin
            SetCurrentKey(Status, "Is Manual");
            SetHistoryFilters(SIIHistory, IsManual);
            if FindSet then
                repeat
                    TempSIIHistoryBuffer := SIIHistory;
                    TempSIIHistoryBuffer.Insert;
                until Next = 0;
        end;
    end;

    local procedure SaveHistoryPendingBuffer(var TempSIIHistoryBuffer: Record "SII History" temporary; IsManual: Boolean)
    var
        SIIHistory: Record "SII History";
    begin
        TempSIIHistoryBuffer.Reset;
        if TempSIIHistoryBuffer.FindSet then begin
            SetHistoryFilters(SIIHistory, IsManual);
            if SIIHistory.FindSet(true) then
                repeat
                    SIIHistory := TempSIIHistoryBuffer;
                    SIIHistory.Modify;
                until (SIIHistory.Next = 0) or (TempSIIHistoryBuffer.Next = 0);
        end;
    end;

    local procedure SetHistoryFilters(var SIIHistory: Record "SII History"; IsManual: Boolean)
    begin
        SIIHistory.SetRange(Status, SIIHistory.Status::Pending);
        SIIHistory.SetRange("Is Manual", IsManual);
    end;

    local procedure SetDocStateFilters(var SIIDocUploadState: Record "SII Doc. Upload State"; IsManual: Boolean)
    begin
        SIIDocUploadState.SetCurrentKey(Status, "Is Manual");
        SIIDocUploadState.SetRange(Status, SIIDocUploadState.Status::Pending);
        SIIDocUploadState.SetRange("Is Manual", IsManual);

        OnAfterSetDocStateFilters(SIIDocUploadState);
    end;

    local procedure CreateNewSessionRecord(var SIISession: Record "SII Session")
    begin
        Clear(SIISession);
        SIISession.Insert;
    end;

    local procedure ProcessBatchResponseCommunicationError(var TempSIIHistoryBuffer: Record "SII History" temporary; ErrorMessage: Text[250])
    begin
        if TempSIIHistoryBuffer.FindSet then
            repeat
                TempSIIHistoryBuffer.ProcessResponseCommunicationError(ErrorMessage);
            until TempSIIHistoryBuffer.Next = 0;
    end;

    local procedure ProcessBatchResponse(var TempSIIHistoryBuffer: Record "SII History" temporary)
    begin
        if TempSIIHistoryBuffer.FindSet then
            repeat
                TempSIIHistoryBuffer.ProcessResponse;
            until TempSIIHistoryBuffer.Next = 0;
    end;

    local procedure ParseBatchResponse(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; ResponseText: Text)
    var
        TempXMLBuffer: array[2] of Record "XML Buffer" temporary;
        TempSIIHistory: Record "SII History" temporary;
    begin
        TempXMLBuffer[1].LoadFromText(ResponseText);
        TempXMLBuffer[1].SetFilter(Name, 'RespuestaLinea');
        if TempXMLBuffer[1].FindSet then
            repeat
                if SIIDocUploadState."Transaction Type" = SIIDocUploadState."Transaction Type"::"Collection In Cash" then
                    ProcessResponseCollectionInCash(SIIDocUploadState, TempSIIHistoryBuffer, TempXMLBuffer[2], TempXMLBuffer[1]."Entry No.")
                else
                    ProcessResponseDocNo(SIIDocUploadState, TempSIIHistoryBuffer, TempXMLBuffer[2], TempXMLBuffer[1]."Entry No.");
            until TempXMLBuffer[1].Next = 0
        else begin
            XMLParseErrorCode(TempXMLBuffer[2], TempSIIHistory);
            TempSIIHistoryBuffer.ModifyAll("Error Message", TempSIIHistory."Error Message");
            TempSIIHistoryBuffer.ModifyAll(Status, TempSIIHistory.Status);
            TempSIIHistoryBuffer.SetRange(Status, TempSIIHistory.Status);
            ProcessBatchResponse(TempSIIHistoryBuffer);
        end;
        TempSIIHistoryBuffer.SetRange("Document State Id");

        // update remaining Pending (not matched within XML)
        TempSIIHistoryBuffer.SetRange(Status, TempSIIHistory.Status::Pending);
        if not TempSIIHistoryBuffer.IsEmpty then begin
            TempSIIHistoryBuffer.ModifyAll("Error Message", ParseMatchDocumentErr);
            TempSIIHistoryBuffer.ModifyAll(Status, TempSIIHistory.Status::Failed);
            ProcessBatchResponse(TempSIIHistoryBuffer);
        end;
    end;

    local procedure ProcessResponseDocNo(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; var TempXMLBuffer: Record "XML Buffer" temporary; ParentEntryNo: Integer)
    var
        DocumentNo: Code[35];
        Found: Boolean;
    begin
        // Use TempXMLBuffer[2] to point the same temporary buffer and not to break TempXMLBuffer[1] cursor position
        DocumentNo := XMLParseDocumentNo(TempXMLBuffer, ParentEntryNo);
        if DocumentNo <> '' then begin
            if SIIDocUploadState."Document Source" = SIIDocUploadState."Document Source"::"Vendor Ledger" then
                SIIDocUploadState.SetRange("External Document No.", DocumentNo)
            else
                SIIDocUploadState.SetRange("Document No.", DocumentNo);
            Found := SIIDocUploadState.FindFirst;
            if (not Found) and
               (SIIDocUploadState."Document Source" in [SIIDocUploadState."Document Source"::"Customer Ledger",
                                                        SIIDocUploadState."Document Source"::"Vendor Ledger"])
            then begin
                SIIDocUploadState.SetRange("External Document No.");
                SIIDocUploadState.SetRange("Document No.");
                SIIDocUploadState.SetRange("Corrected Doc. No.", DocumentNo);
                Found := SIIDocUploadState.FindFirst;
            end;
            if Found then begin
                TempSIIHistoryBuffer.SetRange("Document State Id", SIIDocUploadState.Id);
                if TempSIIHistoryBuffer.FindFirst then begin
                    XMLParseDocumentResponse(TempXMLBuffer, TempSIIHistoryBuffer, ParentEntryNo);
                    TempSIIHistoryBuffer.ProcessResponse;
                end;
            end;
            SIIDocUploadState.SetRange("External Document No.");
            SIIDocUploadState.SetRange("Document No.");
        end;
    end;

    local procedure ProcessResponseCollectionInCash(var SIIDocUploadState: Record "SII Doc. Upload State"; var TempSIIHistoryBuffer: Record "SII History" temporary; var TempXMLBuffer: Record "XML Buffer" temporary; ParentEntryNo: Integer)
    begin
        if XMLParseCustData(TempXMLBuffer, SIIDocUploadState, ParentEntryNo) then begin
            TempSIIHistoryBuffer.SetRange("Document State Id", SIIDocUploadState.Id);
            if TempSIIHistoryBuffer.FindFirst then begin
                XMLParseDocumentResponse(TempXMLBuffer, TempSIIHistoryBuffer, ParentEntryNo);
                TempSIIHistoryBuffer.ProcessResponse;
            end;
            SIIDocUploadState.SetRange("Posting Date");
            SIIDocUploadState.SetRange("VAT Registration No.");
            SIIDocUploadState.SetRange("CV Name");
        end;
    end;

    local procedure XMLParseDocumentNo(var XMLBuffer: Record "XML Buffer"; ParentEntryNo: Integer): Code[35]
    begin
        with XMLBuffer do begin
            SetRange("Parent Entry No.", ParentEntryNo);
            SetRange(Name, 'IDFactura');
            if FindFirst then begin
                SetRange("Parent Entry No.", "Entry No.");
                SetRange(Name, 'NumSerieFacturaEmisor');
                if FindFirst then
                    exit(CopyStr(Value, 1, 35));
            end;
        end;
    end;

    local procedure XMLParseDocumentResponse(var XMLBuffer: Record "XML Buffer"; var SIIHistory: Record "SII History"; ParentEntryNo: Integer)
    begin
        XMLBuffer.SetRange("Parent Entry No.", ParentEntryNo);
        XMLBuffer.SetFilter(Name, 'EstadoRegistro');
        if XMLBuffer.FindFirst then
            case XMLBuffer.Value of
                'Incorrecto':
                    begin
                        SIIHistory.Status := SIIHistory.Status::Incorrect;
                        XMLBuffer.SetFilter(Name, 'DescripcionErrorRegistro');
                        if XMLBuffer.FindFirst then
                            SIIHistory."Error Message" := CopyStr(XMLBuffer.Value, 1, MaxStrLen(SIIHistory."Error Message"));
                    end;
                'Correcto':
                    SIIHistory.Status := SIIHistory.Status::Accepted;
                'AceptadoConErrores':
                    begin
                        SIIHistory.Status := SIIHistory.Status::"Accepted With Errors";
                        XMLBuffer.SetFilter(Name, 'DescripcionErrorRegistro');
                        if XMLBuffer.FindFirst then
                            SIIHistory."Error Message" := CopyStr(XMLBuffer.Value, 1, MaxStrLen(SIIHistory."Error Message"));
                    end;
                else
                    // something is wrong with the response
                    SIIHistory.Status := SIIHistory.Status::Failed;
            end
        else
            XMLParseErrorCode(XMLBuffer, SIIHistory);
    end;

    local procedure XMLParseCustData(var XMLBuffer: Record "XML Buffer"; var SIIDocUploadState: Record "SII Doc. Upload State"; ParentEntryNo: Integer): Boolean
    var
        Year: Integer;
        VATRegistrationNo: Text;
        CountryRegionCode: Text;
    begin
        with XMLBuffer do begin
            if FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'PeriodoLiquidacion') then begin
                if not FindXMLBufferByParentEntryAndName(XMLBuffer, "Entry No.", 'Ejercicio') then
                    exit(false);
                Evaluate(Year, CopyStr(Value, 1, 20));
                SIIDocUploadState.SetRange("Posting Date", DMY2Date(1, 1, Year));
            end;
            if FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'Contraparte') then begin
                ParentEntryNo := "Entry No.";
                if FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'NIF') then begin
                    VATRegistrationNo := Value;
                    if not FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'NombreRazon') then
                        exit(false);
                    SIIDocUploadState.SetRange("VAT Registration No.", VATRegistrationNo);
                    SIIDocUploadState.SetRange("CV Name", Value);
                    exit(SIIDocUploadState.FindFirst);
                end;
                if not FindXMLBufferByParentEntryAndName(XMLBuffer, "Entry No.", 'IDOtro') then
                    exit(false);
                ParentEntryNo := "Entry No.";
                if not FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'CodigoPais') then
                    exit(false);
                CountryRegionCode := Value;
                if not FindXMLBufferByParentEntryAndName(XMLBuffer, ParentEntryNo, 'ID') then
                    exit(false);
                SIIDocUploadState.SetRange("VAT Registration No.", Value);
                SIIDocUploadState.SetRange("Country/Region Code", CountryRegionCode);
                exit(SIIDocUploadState.FindFirst);
            end;
        end;
    end;

    local procedure XMLParseErrorCode(var XMLBuffer: Record "XML Buffer"; var SIIHistory: Record "SII History")
    begin
        XMLBuffer.SetFilter(Name, 'faultcode');
        if XMLBuffer.FindFirst then
            if StrPos(XMLBuffer.Value, 'Server') > 0 then
                // error is probably on the SII website side
                SIIHistory.Status := SIIHistory.Status::Failed
            else
                // error is probably on our side (XML schema incorrect...)
                SIIHistory.Status := SIIHistory.Status::Incorrect
        else
            // couldn't find the faultcode in the response, assume error on our side
            SIIHistory.Status := SIIHistory.Status::Failed;

        XMLBuffer.SetFilter(Name, 'faultstring');
        if XMLBuffer.FindFirst then
            SIIHistory."Error Message" := CopyStr(XMLBuffer.Value, 1, MaxStrLen(SIIHistory."Error Message"))
    end;

    local procedure FindXMLBufferByParentEntryAndName(var XMLBuffer: Record "XML Buffer"; ParentEntryNo: Integer; NodeName: Text): Boolean
    begin
        with XMLBuffer do begin
            SetRange("Parent Entry No.", ParentEntryNo);
            SetRange(Name, NodeName);
            exit(FindFirst);
        end;
    end;

    local procedure GetAndCheckSetup(): Boolean
    begin
        SIISetup.Get;
        exit(SIISetup.Enabled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDocStateFilters(var SIIDocUploadState: Record "SII Doc. Upload State")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvokeBatchSoapRequestOnBeforeStoreRequestXML(var RequestText: Text);
    begin
    end;
}

