codeunit 28 "Error Message Management"
{

    trigger OnRun()
    begin
    end;

    var
        JoinedErr: Label '%1 %2.', Locked = true;
        JobQueueErrMsgProcessingTxt: Label 'Job Queue Error Message Processing.', Locked = true;
        NullJSONTxt: Label 'null', Locked = true;
        TestFieldEmptyValueErr: Label '%1 must not be empty.', Comment = '%1 - field caption';
        TestFieldValueErr: Label '%1 must be equal to %2.', Comment = '%1 - field caption, %2 - field value';
        FieldErrorErr: Label '%1 %2', Comment = '%1 - field name, %2 - error message';
        FieldMustNotBeErr: Label '%1 must not be %2', Comment = '%1 - field name, %2 - field value';
        MessageType: Option Error,Warning,Information;

    procedure Activate(var ErrorMessageHandler: Codeunit "Error Message Handler"): Boolean
    begin
        if not IsActive then begin
            ClearLastError;
            exit(ErrorMessageHandler.Activate(ErrorMessageHandler));
        end;
        exit(false);
    end;

    procedure IsActive() IsFound: Boolean
    begin
        OnFindActiveSubscriber(IsFound);
    end;

    procedure Finish(ContextVariant: Variant)
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        if GetErrorsInContext(ContextVariant, TempErrorMessage) then begin
            if not GuiAllowed then
                Session.LogMessage('000097V', TempErrorMessage.Description, Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', JobQueueErrMsgProcessingTxt);
            StopTransaction;
        end;
    end;

    local procedure StopTransaction()
    begin
        Error('')
    end;

    procedure IsTransactionStopped(): Boolean
    begin
        exit(StrPos(GetCallStackTop, '(CodeUnit 28).StopTransaction') > 0);
    end;

    local procedure GetCallStackTop(): Text[250]
    var
        CallStack: Text[250];
        DividerPos: Integer;
    begin
        CallStack := CopyStr(GetLastErrorCallstack, 1, 250);
        if CallStack = '' then
            exit('');
        DividerPos := StrPos(CallStack, '\');
        if DividerPos > 0 then
            exit(CopyStr(CallStack, 1, DividerPos - 1));
        exit(CallStack);
    end;

    local procedure GetContextRecID(ContextVariant: Variant; var ContextRecID: RecordID)
    var
        RecRef: RecordRef;
        TableNo: Integer;
    begin
        Clear(ContextRecID);
        case true of
            ContextVariant.IsRecord:
                begin
                    RecRef.GetTable(ContextVariant);
                    ContextRecID := RecRef.RecordId;
                end;
            ContextVariant.IsRecordId:
                ContextRecID := ContextVariant;
            ContextVariant.IsInteger:
                begin
                    TableNo := ContextVariant;
                    if TableNo > 0 then
                        if GetBlankRecID(ContextVariant, ContextRecID) then;
                end;
        end;
    end;

    [TryFunction]
    local procedure GetBlankRecID(TableNo: Integer; var RecID: RecordID)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        RecID := RecRef.RecordId;
        RecRef.Close;
    end;

    [Scope('OnPrem')]
    procedure ShowErrors(Notification: Notification)
    var
        RegisterID: Guid;
    begin
        if not Evaluate(RegisterID, Notification.GetData('RegisterID')) then
            Clear(RegisterID);

        ShowErrors(RegisterID);
    end;

    [Scope('OnPrem')]
    procedure ShowErrors(RegisterID: Guid)
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ErrorMessage.FilterGroup(2);
        ErrorMessage.SetRange("Register ID", RegisterID);
        ErrorMessage.FilterGroup(0);
        if ErrorMessage.FindSet then begin
            repeat
                TempErrorMessage := ErrorMessage;
                TempErrorMessage.Insert();
            until ErrorMessage.Next() = 0;
            TempErrorMessage.ShowErrors;
        end;
    end;

    procedure ThrowError(ContextErrorMessage: Text; DetailedErrorMessage: Text)
    begin
        if not IsActive then
            Error(JoinedErr, ContextErrorMessage, DetailedErrorMessage);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindActiveSubscriber(var IsFound: Boolean)
    begin
    end;

    procedure GetFieldNo(TableNo: Integer; FieldName: Text): Integer
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TableNo);
        Field.SetRange(FieldName, FieldName);
        if Field.FindFirst then
            exit(Field."No.");
    end;

    procedure FindFirstErrorMessage(var ErrorMessage: Text[250]): Boolean
    begin
        exit(GetLastError(ErrorMessage) > 0);
    end;

    local procedure GetFirstContextID(ContextRecordID: RecordID) ContextID: Integer
    begin
        if ContextRecordID.TableNo = 0 then
            exit(0);
        OnGetFirstContextID(ContextRecordID, ContextID);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFirstContextID(ContextRecordID: RecordID; var ContextID: Integer)
    begin
    end;

    procedure GetErrors(var TempErrorMessage: Record "Error Message" temporary): Boolean
    begin
        TempErrorMessage.SetRange(Context, false);
        OnGetErrors(TempErrorMessage);
        exit(TempErrorMessage.FindFirst);
    end;

    procedure GetErrorsInContext(ContextVariant: Variant; var TempErrorMessage: Record "Error Message" temporary): Boolean
    var
        ContextRecID: RecordID;
    begin
        GetContextRecID(ContextVariant, ContextRecID);
        TempErrorMessage.SetFilter(ID, '>%1', GetFirstContextID(ContextRecID));
        TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Error);
        exit(GetErrors(TempErrorMessage));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetErrors(var TempErrorMessageResult: Record "Error Message" temporary)
    begin
    end;

    procedure GetLastError(var ErrorMessage: Text[250]) ID: Integer
    begin
        OnGetLastErrorID(ID, ErrorMessage);
    end;

    procedure GetLastErrorID() ID: Integer
    var
        ErrorMessage: Text[250];
    begin
        OnGetLastErrorID(ID, ErrorMessage);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetLastErrorID(var ID: Integer; var ErrorMessage: Text[250])
    begin
    end;

    procedure LogError(SourceVariant: Variant; ErrorMessage: Text; HelpArticleCode: Code[30])
    var
        ContextErrorMessage: Record "Error Message";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        if not GetTopContext(ContextErrorMessage) then
            PushContext(ErrorContextElement, 0, 0, GetCallStackTop);
        LogErrorMessage(ContextErrorMessage."Context Field Number", ErrorMessage, SourceVariant, 0, HelpArticleCode);
    end;

    procedure LogContextFieldError(ContextFieldNo: Integer; ErrorMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30])
    begin
        LogErrorMessage(ContextFieldNo, ErrorMessage, SourceVariant, SourceFieldNo, HelpArticleCode);
    end;

    procedure LogMessage(NewMessageType: Option; ContextFieldNo: Integer; InformationMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30]): Boolean
    begin
        case NewMessageType of
            MessageType::Error:
                exit(LogErrorMessage(ContextFieldNo, InformationMessage, SourceVariant, SourceFieldNo, HelpArticleCode));
            MessageType::Warning:
                exit(LogWarning(ContextFieldNo, InformationMessage, SourceVariant, SourceFieldNo, HelpArticleCode));
            MessageType::Information:
                exit(LogInformation(ContextFieldNo, InformationMessage, SourceVariant, SourceFieldNo, HelpArticleCode));
        end;
    end;

    procedure LogErrorMessage(ContextFieldNo: Integer; ErrorMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30]) IsLogged: Boolean
    begin
        OnLogError(MessageType::Error, ContextFieldNo, ErrorMessage, SourceVariant, SourceFieldNo, HelpArticleCode, IsLogged);
        if not IsLogged then
            Error(ErrorMessage);
    end;

    procedure LogSimpleErrorMessage(ErrorMessage: Text) IsLogged: Boolean
    begin
        OnLogSimpleError(ErrorMessage, IsLogged);
        if not IsLogged then
            Error(ErrorMessage);
    end;

    procedure LogTestField(SourceVariant: Variant; SourceFieldNo: Integer) IsLogged: Boolean
    var
        TempErrorMessage: Record "Error Message" temporary;
        RecRef: RecordRef;
        FldRef: FieldRef;
        ErrorMessage: Text;
    begin
        RecRef.GetTable(SourceVariant);
        FldRef := RecRef.Field(SourceFieldNo);

        if not IsActive() then begin
            FldRef.TestField();
            exit;
        end;

        if FldRefHasValue(FldRef) then
            exit;

        if FldRef.Type = FldRef.Type::Option then
            exit(LogFieldError(SourceVariant, SourceFieldNo, ''));

        ErrorMessage := StrSubstNo(TestFieldEmptyValueErr, FldRef.Caption);

        GetTopContext(TempErrorMessage);
        OnLogError(MessageType::Error, TempErrorMessage."Context Field Number", ErrorMessage, SourceVariant, SourceFieldNo, '', IsLogged);
        if not IsLogged then
            FldRef.TestField();
    end;

    procedure LogTestField(SourceVariant: Variant; SourceFieldNo: Integer; ExpectedValue: Variant) IsLogged: Boolean
    var
        TempErrorMessage: Record "Error Message" temporary;
        RecRef: RecordRef;
        FldRef: FieldRef;
        ErrorMessage: Text;
        FieldValue: Variant;
        IntValue: Integer;
    begin
        RecRef.GetTable(SourceVariant);
        FldRef := RecRef.Field(SourceFieldNo);

        if not IsActive() then begin
            FldRef.TestField(ExpectedValue);
            exit;
        end;

        FieldValue := FldRef.Value();
        if CompareValues(ExpectedValue, FieldValue) then
            exit;

        if FldRef.Type() = FieldType::Option then begin
            IntValue := ExpectedValue;
            ExpectedValue := SelectStr(IntValue + 1, FldRef.OptionCaption());
        end;
        if Format(ExpectedValue) = '' then
            ExpectedValue := '''''';
        ErrorMessage := StrSubstNo(TestFieldValueErr, FldRef.Caption, Format(ExpectedValue));
        GetTopContext(TempErrorMessage);
        OnLogError(MessageType::Error, TempErrorMessage."Context Field Number", ErrorMessage, SourceVariant, SourceFieldNo, '', IsLogged);
        if not IsLogged then
            FldRef.TestField(ExpectedValue);
    end;

    procedure LogFieldError(SourceVariant: Variant; SourceFieldNo: Integer; ErrorMessage: Text) IsLogged: Boolean
    var
        TempErrorMessage: Record "Error Message" temporary;
        RecRef: RecordRef;
        FldRef: FieldRef;
        ErrorMessageText: Text;
    begin
        RecRef.GetTable(SourceVariant);
        FldRef := RecRef.Field(SourceFieldNo);

        if not IsActive() then
            FldRef.FieldError(ErrorMessage);

        if ErrorMessage <> '' then
            ErrorMessageText := StrSubstNo(FieldErrorErr, FldRef.Caption, ErrorMessage)
        else
            ErrorMessageText := StrSubstNo(FieldMustNotBeErr, FldRef.Caption, FldRef.Value());

        GetTopContext(TempErrorMessage);
        OnLogError(MessageType::Error, TempErrorMessage."Context Field Number", ErrorMessageText, SourceVariant, SourceFieldNo, '', IsLogged);
        if not IsLogged then
            FldRef.FieldError(ErrorMessage);
    end;

    procedure LogLastError()
    begin
        OnLogLastError();
    end;

    local procedure CompareValues(xValue: Variant; Value: Variant): Boolean
    begin
        if Value.IsInteger or Value.IsBigInteger or Value.IsDecimal or Value.IsDuration then
            exit(CompareNumbers(xValue, Value));

        if Value.IsDate then
            exit(CompareDates(xValue, Value));

        if Value.IsTime then
            exit(CompareTimes(xValue, Value));

        if Value.IsDateTime then
            exit(CompareDateTimes(xValue, Value));

        exit(CompareText(Format(xValue, 0, 2), Format(Value, 0, 2)));
    end;

    local procedure CompareNumbers(xValue: Decimal; Value: Decimal): Boolean
    begin
        exit(xValue = Value);
    end;

    local procedure CompareDates(xValue: Date; Value: Date): Boolean
    begin
        exit(CompareDateTimes(CreateDateTime(xValue, 0T), CreateDateTime(Value, 0T)));
    end;

    local procedure CompareTimes(xValue: Time; Value: Time): Boolean
    var
        ReferenceDate: Date;
    begin
        ReferenceDate := Today;
        exit(CompareDateTimes(CreateDateTime(ReferenceDate, xValue), CreateDateTime(ReferenceDate, Value)));
    end;

    local procedure CompareDateTimes(xValue: DateTime; Value: DateTime): Boolean
    begin
        exit(xValue = Value);
    end;

    local procedure CompareText(xValue: Text; Value: Text): Boolean
    begin
        exit(xValue = Value);
    end;

    local procedure FldRefHasValue(FldRef: FieldRef): Boolean
    var
        HasValue: Boolean;
        Int: Integer;
        Dec: Decimal;
        D: Date;
        T: Time;
    begin
        case FldRef.Type of
            FieldType::Boolean:
                HasValue := FldRef.Value;
            FieldType::Option,
            FieldType::Integer:
                begin
                    Int := FldRef.Value;
                    HasValue := Int <> 0;
                end;
            FieldType::Decimal:
                begin
                    Dec := FldRef.Value;
                    HasValue := Dec <> 0;
                end;
            FieldType::Date:
                begin
                    D := FldRef.Value;
                    HasValue := D <> 0D;
                end;
            FieldType::Time:
                begin
                    T := FldRef.Value;
                    HasValue := T <> 0T;
                end;
            FieldType::BLOB:
                HasValue := false;
            else
                HasValue := Format(FldRef.Value) <> '';
        end;

        exit(HasValue);
    end;

    procedure GetErrorsFromResultValues(Values: List of [Text]; var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorText: Text;
    begin
        foreach ErrorText in Values do
            ParseErrorText(ErrorText, TempErrorMessage);
    end;

    procedure ParseErrorText(JSON: Text; var TempErrorMessage: Record "Error Message" temporary)
    var
        RecordIDText: Text;
        FieldNumberText: Text;
        TableNumberText: Text;
        Description: Text;
        ContextRecordIDText: Text;
        ContextFieldNumberText: Text;
        ContextTableNumberText: Text;
        DuplicateText: Text;
        NextID: Integer;
        JObject: JsonObject;
    begin
        if NullJSONTxt <> JSON then begin
            JObject.ReadFrom(JSON);
            RecordIDText := GetJsonKeyValue(JObject, 'RecordId');
            FieldNumberText := GetJsonKeyValue(JObject, 'FieldNumber');
            TableNumberText := GetJsonKeyValue(JObject, 'TableNumber');
            Description := GetJsonKeyValue(JObject, 'Description');
            ContextRecordIDText := GetJsonKeyValue(JObject, 'ContextRecordId');
            ContextFieldNumberText := GetJsonKeyValue(JObject, 'ContextFieldNumber');
            ContextTableNumberText := GetJsonKeyValue(JObject, 'ContextTableNumber');
            DuplicateText := GetJsonKeyValue(JObject, 'Duplicate');

            NextID := TempErrorMessage.FindLastID() + 1;
            TempErrorMessage.Init();
            TempErrorMessage.ID := NextID;
            Evaluate(TempErrorMessage."Record ID", RecordIDText);
            Evaluate(TempErrorMessage."Field Number", FieldNumberText);
            Evaluate(TempErrorMessage."Table Number", TableNumberText);
            Evaluate(TempErrorMessage."Context Record ID", ContextRecordIDText);
            Evaluate(TempErrorMessage."Context Field Number", ContextFieldNumberText);
            Evaluate(TempErrorMessage."Context Table Number", ContextTableNumberText);
            Evaluate(TempErrorMessage.Duplicate, DuplicateText);
            TempErrorMessage.Description := CopyStr(Description, 1, MaxStrLen(TempErrorMessage.Description));
            TempErrorMessage.Insert();
        end;
    end;

    local procedure GetJsonKeyValue(var JObject: JsonObject; KeyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.Get(KeyName, JToken) then
            exit(JToken.AsValue().AsText());
    end;

    procedure ErrorMessage2JSON(ErrorMessage: Record "Error Message") JSON: Text
    var
        JObject: JsonObject;
    begin
        JObject.Add('RecordId', format(ErrorMessage."Record ID"));
        JObject.Add('FieldNumber', ErrorMessage."Field Number");
        JObject.Add('TableNumber', ErrorMessage."Table Number");
        JObject.Add('Description', ErrorMessage.Description);
        JObject.Add('ContextRecordId', format(ErrorMessage."Context Record ID"));
        JObject.Add('ContextFieldNumber', ErrorMessage."Context Field Number");
        JObject.Add('ContextTableNumber', ErrorMessage."Context Table Number");
        JObject.Add('Duplicate', ErrorMessage.Duplicate);
        JObject.WriteTo(JSON);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogSimpleError(ErrorMessage: Text; var IsLogged: Boolean)
    begin
    end;

    procedure LogWarning(ContextFieldNo: Integer; WarningMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30]) IsLogged: Boolean
    begin
        OnLogError(MessageType::Warning, ContextFieldNo, WarningMessage, SourceVariant, SourceFieldNo, HelpArticleCode, IsLogged);
    end;

    procedure LogWarning(WarningMessage: Text) IsLogged: Boolean
    begin
        OnLogError(MessageType::Warning, 0, WarningMessage, 0, 0, '', IsLogged);
    end;

    procedure LogInformation(ContextFieldNo: Integer; InformationMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30]) IsLogged: Boolean
    begin
        OnLogError(MessageType::Information, ContextFieldNo, InformationMessage, SourceVariant, SourceFieldNo, HelpArticleCode, IsLogged);
    end;

    procedure LogInformation(InformationMessage: Text) IsLogged: Boolean
    begin
        OnLogError(MessageType::Information, 0, InformationMessage, 0, 0, '', IsLogged);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogError(MessageType: Option; ContextFieldNo: Integer; ErrorMessage: Text; SourceVariant: Variant; SourceFieldNo: Integer; HelpArticleCode: Code[30]; var IsLogged: Boolean)
    begin
    end;

    procedure PushContext(var ErrorContextElement: Codeunit "Error Context Element"; ContextVariant: Variant; ContextFieldNo: Integer; AdditionalInfo: Text[250]) ID: Integer
    var
        RecID: RecordID;
    begin
        if IsActive then begin
            ID := ErrorContextElement.GetID;
            if ID = 0 then begin
                OnGetTopElement(ID);
                ID += 1;
                BindSubscription(ErrorContextElement);
            end;
            GetContextRecID(ContextVariant, RecID);
            ErrorContextElement.Set(ID, RecID, ContextFieldNo, AdditionalInfo);
            OnPushContext;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPushContext()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTopElement(var TopElementID: Integer)
    begin
    end;

    procedure GetTopContext(var ErrorMessage: Record "Error Message"): Boolean
    begin
        OnGetTopContext(ErrorMessage);
        exit(ErrorMessage.ID > 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTopContext(var ErrorMessage: Record "Error Message")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogLastError()
    begin
    end;
}

