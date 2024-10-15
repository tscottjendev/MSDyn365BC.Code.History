codeunit 408 DimensionManagement
{
    Permissions = TableData "Gen. Journal Template" = imd,
                  TableData "Gen. Journal Batch" = imd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Dimensions %1 and %2 can''t be used concurrently.';
        Text001: Label 'Dimension combinations %1 - %2 and %3 - %4 can''t be used concurrently.';
        Text002: Label 'This Shortcut Dimension is not defined in the %1.';
        Text003: Label '%1 is not an available %2 for that dimension.';
        DefaultDimensionsValueCodeEmptyTxt: Label 'The %1 dimension is the default dimension, and it must have a value. You can set the value on the %2 page.', Comment = '%1 = the value of Dimension Code; %2 = page caption of Default Dimensions';
        Text005: Label 'Select a %1 for the %2 %3 for %4 %5.';
        Text006: Label 'Select %1 %2 for the %3 %4.';
        Text007: Label 'Select %1 %2 for the %3 %4 for %5 %6.';
        Text008: Label '%1 %2 must be blank.';
        Text009: Label '%1 %2 must be blank for %3 %4.';
        Text010: Label '%1 %2 must not be mentioned.';
        Text011: Label '%1 %2 must not be mentioned for %3 %4.';
        Text012: Label 'A %1 used in %2 has not been used in %3.';
        Text013: Label '%1 for %2 %3 is not the same in %4 and %5.';
        Text014: Label '%1 %2 is blocked.';
        Text015: Label '%1 %2 can''t be found.';
        DimValueBlockedErr: Label '%1 %2 - %3 is blocked.', Comment = '%1 = Dimension Value table caption, %2 = Dim Code, %3 = Dim Value';
        DimValueMustNotBeErr: Label 'Dimension Value Type for %1 %2 - %3 must not be %4.', Comment = '%1 = Dimension Value table caption, %2 = Dim Code, %3 = Dim Value, %4 = Dimension Value Type value';
        DimValueMissingErr: Label '%1 for %2 is missing.', Comment = '%1 = Dimension Value table caption, %2 = Dim Code';
        Text019: Label 'You have changed a dimension.\\Do you want to update the lines?';
        LastErrorMessage: Record "Error Message";
        TempJobTaskDimBuffer: Record "Job Task Dimension" temporary;
        TempDimSetEntryBuffer: Record "Dimension Set Entry" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        TempDimCombInitialized: Boolean;
        TempDimCombEmpty: Boolean;
        HasGotGLSetup: Boolean;
        GLSetupShortcutDimCode: array[8] of Code[20];
        DimSetFilterCtr: Integer;
        IsCollectErrorsMode: Boolean;
        SourceCode: Code[10];

    procedure SetCollectErrorsMode()
    begin
        IsCollectErrorsMode := true;
    end;

    procedure SetSourceCode(TableID: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        case TableID of
            DATABASE::"Sales Header",
            DATABASE::"Sales Line":
                SourceCode := SourceCodeSetup.Sales;
            DATABASE::"Purchase Header",
            DATABASE::"Purchase Line",
            DATABASE::"Requisition Line":
                SourceCode := SourceCodeSetup.Purchases;
            DATABASE::"Bank Acc. Reconciliation",
            DATABASE::"Bank Acc. Reconciliation Line":
                SourceCode := SourceCodeSetup."Payment Reconciliation Journal";
            DATABASE::"Reminder Header":
                SourceCode := SourceCodeSetup.Reminder;
            DATABASE::"Finance Charge Memo Header":
                SourceCode := SourceCodeSetup."Finance Charge Memo";
            DATABASE::"Assembly Header",
            DATABASE::"Assembly Line":
                SourceCode := SourceCodeSetup.Assembly;
            DATABASE::"Transfer Line":
                SourceCode := SourceCodeSetup.Transfer;
            DATABASE::"Service Header",
            DATABASE::"Service Item Line",
            DATABASE::"Service Line",
            DATABASE::"Service Contract Header",
            DATABASE::"Standard Service Line":
                SourceCode := SourceCodeSetup."Service Management";
        end;
    end;

    procedure SetSourceCode(TableID: Integer; RecordVar: Variant)
    var
        RecRef: RecordRef;
    begin
        SetSourceCode(TableID);

        OnAfterSetSourceCodeWithVar(TableID, RecordVar, SourceCode);
    end;

    procedure GetSourceCode(): Code[10]
    begin
        exit(SourceCode);
    end;

    procedure GetDimensionSetID(var DimSetEntry2: Record "Dimension Set Entry"): Integer
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        exit(DimSetEntry.GetDimensionSetID(DimSetEntry2));
    end;

    procedure GetDimensionSet(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimSetID: Integer)
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        OnBeforeGetDimensionSet(TempDimSetEntry);

        TempDimSetEntry.DeleteAll();
        with DimSetEntry do begin
            SetRange("Dimension Set ID", DimSetID);
            if FindSet then
                repeat
                    TempDimSetEntry := DimSetEntry;
                    TempDimSetEntry.Insert();
                until Next = 0;
        end;
    end;

    procedure ShowDimensionSet(DimSetID: Integer; NewCaption: Text[250])
    var
        DimSetEntry: Record "Dimension Set Entry";
        DimSetEntries: Page "Dimension Set Entries";
    begin
        DimSetEntry.Reset();
        DimSetEntry.FilterGroup(2);
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        DimSetEntry.FilterGroup(0);
        DimSetEntries.SetTableView(DimSetEntry);
        DimSetEntries.SetFormCaption(NewCaption);
        DimSetEntries.RunModal;
    end;

    procedure EditDimensionSet(DimSetID: Integer; NewCaption: Text[250]): Integer
    var
        DimSetEntry: Record "Dimension Set Entry";
        EditDimSetEntries: Page "Edit Dimension Set Entries";
        NewDimSetID: Integer;
    begin
        NewDimSetID := DimSetID;
        DimSetEntry.Reset();
        DimSetEntry.FilterGroup(2);
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        DimSetEntry.FilterGroup(0);
        EditDimSetEntries.SetTableView(DimSetEntry);
        EditDimSetEntries.SetFormCaption(NewCaption);
        EditDimSetEntries.RunModal;
        NewDimSetID := EditDimSetEntries.GetDimensionID;
        exit(NewDimSetID);
    end;

    procedure EditDimensionSet(DimSetID: Integer; NewCaption: Text[250]; var GlobalDimVal1: Code[20]; var GlobalDimVal2: Code[20]): Integer
    var
        DimSetEntry: Record "Dimension Set Entry";
        EditDimSetEntries: Page "Edit Dimension Set Entries";
        NewDimSetID: Integer;
    begin
        NewDimSetID := DimSetID;
        DimSetEntry.Reset();
        DimSetEntry.FilterGroup(2);
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        DimSetEntry.FilterGroup(0);
        EditDimSetEntries.SetTableView(DimSetEntry);
        EditDimSetEntries.SetFormCaption(NewCaption);
        EditDimSetEntries.RunModal;
        NewDimSetID := EditDimSetEntries.GetDimensionID;
        UpdateGlobalDimFromDimSetID(NewDimSetID, GlobalDimVal1, GlobalDimVal2);
        OnAfterEditDimensionSet2(NewDimSetID, GlobalDimVal1, GlobalDimVal2);
        exit(NewDimSetID);
    end;

    procedure EditReclasDimensionSet(var DimSetID: Integer; var NewDimSetID: Integer; NewCaption: Text[250]; var GlobalDimVal1: Code[20]; var GlobalDimVal2: Code[20]; var NewGlobalDimVal1: Code[20]; var NewGlobalDimVal2: Code[20])
    var
        EditReclasDimensions: Page "Edit Reclas. Dimensions";
    begin
        EditReclasDimensions.SetDimensionIDs(DimSetID, NewDimSetID);
        EditReclasDimensions.SetFormCaption(NewCaption);
        EditReclasDimensions.RunModal;
        EditReclasDimensions.GetDimensionIDs(DimSetID, NewDimSetID);
        UpdateGlobalDimFromDimSetID(DimSetID, GlobalDimVal1, GlobalDimVal2);
        UpdateGlobalDimFromDimSetID(NewDimSetID, NewGlobalDimVal1, NewGlobalDimVal2);
    end;

    procedure UpdateGlobalDimFromDimSetID(DimSetID: Integer; var GlobalDimVal1: Code[20]; var GlobalDimVal2: Code[20])
    var
        ShortcutDimCode: array[8] of Code[20];
    begin
        GetShortcutDimensions(DimSetID, ShortcutDimCode);
        GlobalDimVal1 := ShortcutDimCode[1];
        GlobalDimVal2 := ShortcutDimCode[2];
    end;

    procedure GetCombinedDimensionSetID(DimensionSetIDArr: array[10] of Integer; var GlobalDimVal1: Code[20]; var GlobalDimVal2: Code[20]): Integer
    var
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        i: Integer;
    begin
        GetGLSetup;
        GlobalDimVal1 := '';
        GlobalDimVal2 := '';
        DimSetEntry.Reset();
        for i := 1 to 10 do
            if DimensionSetIDArr[i] <> 0 then begin
                DimSetEntry.SetRange("Dimension Set ID", DimensionSetIDArr[i]);
                if DimSetEntry.FindSet then
                    repeat
                        if TempDimSetEntry.Get(0, DimSetEntry."Dimension Code") then
                            TempDimSetEntry.Delete();
                        TempDimSetEntry := DimSetEntry;
                        TempDimSetEntry."Dimension Set ID" := 0;
                        TempDimSetEntry.Insert();
                        if GLSetupShortcutDimCode[1] = TempDimSetEntry."Dimension Code" then
                            GlobalDimVal1 := TempDimSetEntry."Dimension Value Code";
                        if GLSetupShortcutDimCode[2] = TempDimSetEntry."Dimension Code" then
                            GlobalDimVal2 := TempDimSetEntry."Dimension Value Code";
                    until DimSetEntry.Next = 0;
            end;
        exit(GetDimensionSetID(TempDimSetEntry));
    end;

    procedure GetDeltaDimSetID(DimSetID: Integer; NewParentDimSetID: Integer; OldParentDimSetID: Integer): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        TempDimSetEntryNew: Record "Dimension Set Entry" temporary;
        TempDimSetEntryDeleted: Record "Dimension Set Entry" temporary;
    begin
        // Returns an updated DimSetID based on parent's old and new DimSetID
        if NewParentDimSetID = OldParentDimSetID then
            exit(DimSetID);
        GetDimensionSet(TempDimSetEntry, DimSetID);
        GetDimensionSet(TempDimSetEntryNew, NewParentDimSetID);
        GetDimensionSet(TempDimSetEntryDeleted, OldParentDimSetID);
        if TempDimSetEntryDeleted.FindSet then
            repeat
                if TempDimSetEntryNew.Get(NewParentDimSetID, TempDimSetEntryDeleted."Dimension Code") then begin
                    if TempDimSetEntryNew."Dimension Value Code" = TempDimSetEntryDeleted."Dimension Value Code" then
                        TempDimSetEntryNew.Delete();
                    TempDimSetEntryDeleted.Delete();
                end;
            until TempDimSetEntryDeleted.Next = 0;

        if TempDimSetEntryDeleted.FindSet then
            repeat
                if TempDimSetEntry.Get(DimSetID, TempDimSetEntryDeleted."Dimension Code") then
                    TempDimSetEntry.Delete();
            until TempDimSetEntryDeleted.Next = 0;

        if TempDimSetEntryNew.FindSet then
            repeat
                if TempDimSetEntry.Get(DimSetID, TempDimSetEntryNew."Dimension Code") then begin
                    if TempDimSetEntry."Dimension Value Code" <> TempDimSetEntryNew."Dimension Value Code" then begin
                        TempDimSetEntry."Dimension Value Code" := TempDimSetEntryNew."Dimension Value Code";
                        TempDimSetEntry."Dimension Value ID" := TempDimSetEntryNew."Dimension Value ID";
                        TempDimSetEntry.Modify();
                    end;
                end else begin
                    TempDimSetEntry := TempDimSetEntryNew;
                    TempDimSetEntry."Dimension Set ID" := DimSetID;
                    TempDimSetEntry.Insert();
                end;
            until TempDimSetEntryNew.Next = 0;

        exit(GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure GetGLSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not HasGotGLSetup then begin
            GLSetup.Get();
            GLSetupShortcutDimCode[1] := GLSetup."Shortcut Dimension 1 Code";
            GLSetupShortcutDimCode[2] := GLSetup."Shortcut Dimension 2 Code";
            GLSetupShortcutDimCode[3] := GLSetup."Shortcut Dimension 3 Code";
            GLSetupShortcutDimCode[4] := GLSetup."Shortcut Dimension 4 Code";
            GLSetupShortcutDimCode[5] := GLSetup."Shortcut Dimension 5 Code";
            GLSetupShortcutDimCode[6] := GLSetup."Shortcut Dimension 6 Code";
            GLSetupShortcutDimCode[7] := GLSetup."Shortcut Dimension 7 Code";
            GLSetupShortcutDimCode[8] := GLSetup."Shortcut Dimension 8 Code";
            HasGotGLSetup := true;
        end;
    end;

    local procedure GetLastDimErrorID(): Integer
    begin
        if ErrorMessageMgt.IsActive then
            exit(ErrorMessageMgt.GetLastErrorID);
        exit(LastErrorMessage.ID);
    end;

    local procedure FindLastErrorMessage(var Message: Text[250])
    begin
        if ErrorMessageMgt.IsActive then
            ErrorMessageMgt.GetLastError(Message)
        else
            Message := LastErrorMessage.Description;
    end;

    local procedure GetDimBufForDimSetID(DimSetID: Integer; var TempDimBuf: Record "Dimension Buffer" temporary)
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        DimSetEntry.Reset();
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.FindSet then
            repeat
                TempDimBuf.Init();
                TempDimBuf."Table ID" := DATABASE::"Dimension Buffer";
                TempDimBuf."Entry No." := 0;
                TempDimBuf."Dimension Code" := DimSetEntry."Dimension Code";
                TempDimBuf."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                TempDimBuf.Insert();
            until DimSetEntry.Next = 0;
    end;

    procedure CheckDimIDComb(DimSetID: Integer): Boolean
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
    begin
        GetDimBufForDimSetID(DimSetID, TempDimBuf);
        exit(CheckDimComb(TempDimBuf));
    end;

    procedure CheckDimValuePosting(TableID: array[10] of Integer; No: array[10] of Code[20]; DimSetID: Integer): Boolean
    var
        DimSetEntry: Record "Dimension Set Entry";
        TempDefaultDim: Record "Default Dimension" temporary;
        IsHandled: Boolean;
        IsChecked: Boolean;
        LastErrorID: Integer;
    begin
        IsChecked := false;
        IsHandled := false;
        OnBeforeCheckDimValuePosting(TableID, No, DimSetID, IsChecked, IsHandled);
        if IsHandled then
            exit(IsChecked);

        if not CheckBlockedDimAndValues(DimSetID) then
            if not IsCollectErrorsMode then
                exit(false);

        LastErrorID := GetLastDimErrorID;
        DimSetEntry.Reset();
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        CollectDefaultDimsToCheck(TableID, No, TempDefaultDim);
        with TempDefaultDim do begin
            Reset;
            if FindSet then
                repeat
                    DimSetEntry.SetRange("Dimension Code", "Dimension Code");
                    case "Value Posting" of
                        "Value Posting"::"Code Mandatory":
                            if not DimSetEntry.FindFirst or (DimSetEntry."Dimension Value Code" = '') then
                                LogError(RecordId, FieldNo("Value Posting"), GetMissedMandatoryDimErr(TempDefaultDim), '');
                        "Value Posting"::"Same Code":
                            if "Dimension Value Code" <> '' then begin
                                if not DimSetEntry.FindFirst or
                                   ("Dimension Value Code" <> DimSetEntry."Dimension Value Code")
                                then
                                    LogError(RecordId, FieldNo("Value Posting"), GetSameCodeWrongDimErr(TempDefaultDim), '');
                            end else
                                if DimSetEntry.FindFirst then
                                    LogError(RecordId, FieldNo("Value Posting"), GetSameCodeBlankDimErr(TempDefaultDim), '');
                        "Value Posting"::"No Code":
                            if DimSetEntry.FindFirst then
                                LogError(RecordId, FieldNo("Value Posting"), GetNoCodeFilledDimErr(TempDefaultDim), '');
                    end;
                    if not IsCollectErrorsMode then
                        if LastErrorID <> GetLastDimErrorID then
                            exit(false);
                until Next = 0;
        end;
        exit(GetLastDimErrorID = LastErrorID);
    end;

    procedure CheckDimBuffer(var DimBuffer: Record "Dimension Buffer"): Boolean
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        i: Integer;
    begin
        if DimBuffer.FindSet then begin
            i := 1;
            repeat
                TempDimBuf.Init();
                TempDimBuf."Table ID" := DATABASE::"Dimension Buffer";
                TempDimBuf."Entry No." := i;
                TempDimBuf."Dimension Code" := DimBuffer."Dimension Code";
                TempDimBuf."Dimension Value Code" := DimBuffer."Dimension Value Code";
                TempDimBuf.Insert();
                i := i + 1;
            until DimBuffer.Next = 0;
        end;
        exit(CheckDimComb(TempDimBuf));
    end;

    local procedure CheckDimComb(var TempDimBuf: Record "Dimension Buffer" temporary): Boolean
    var
        DimComb: Record "Dimension Combination";
        CurrentDimCode: Code[20];
        CurrentDimValCode: Code[20];
        DimFilter: Text;
        Separator: Text;
        LastErrorID: Integer;
    begin
        if not TempDimCombInitialized then begin
            TempDimCombInitialized := true;
            if DimComb.IsEmpty then
                TempDimCombEmpty := true;
        end;

        if TempDimCombEmpty then
            exit(true);

        if not TempDimBuf.FindSet then
            exit(true);

        repeat
            DimFilter += Separator + TempDimBuf."Dimension Code";
            Separator := '|';
        until TempDimBuf.Next = 0;

        LastErrorID := GetLastDimErrorID;
        DimComb.SetFilter("Dimension 1 Code", DimFilter);
        DimComb.SetFilter("Dimension 2 Code", DimFilter);
        if DimComb.FindSet then
            repeat
                if DimComb."Combination Restriction" = DimComb."Combination Restriction"::Blocked then
                    LogError(
                      DimComb.RecordId, DimComb.FieldNo("Combination Restriction"),
                      StrSubstNo(Text000, DimComb."Dimension 1 Code", DimComb."Dimension 2 Code"), '')
                else begin
                    TempDimBuf.SetRange("Dimension Code", DimComb."Dimension 1 Code");
                    TempDimBuf.FindFirst;
                    CurrentDimCode := TempDimBuf."Dimension Code";
                    CurrentDimValCode := TempDimBuf."Dimension Value Code";
                    TempDimBuf.SetRange("Dimension Code", DimComb."Dimension 2 Code");
                    TempDimBuf.FindFirst;
                    CheckDimValueComb(
                      TempDimBuf."Dimension Code", TempDimBuf."Dimension Value Code",
                      CurrentDimCode, CurrentDimValCode);
                    CheckDimValueComb(
                      CurrentDimCode, CurrentDimValCode,
                      TempDimBuf."Dimension Code", TempDimBuf."Dimension Value Code");
                end;
                if not IsCollectErrorsMode then
                    if LastErrorID <> GetLastDimErrorID then
                        exit(false);
            until DimComb.Next = 0;
        exit(GetLastDimErrorID = LastErrorID);
    end;

    local procedure CheckDimValueComb(Dim1: Code[20]; Dim1Value: Code[20]; Dim2: Code[20]; Dim2Value: Code[20]): Boolean
    var
        DimValueCombination: Record "Dimension Value Combination";
    begin
        if DimValueCombination.Get(Dim1, Dim1Value, Dim2, Dim2Value) then begin
            LogError(
              DimValueCombination.RecordId, 0, StrSubstNo(Text001, Dim1, Dim1Value, Dim2, Dim2Value), '');
            exit(false);
        end;
        exit(true);
    end;

    local procedure CollectDefaultDimsToCheck(TableID: array[10] of Integer; No: array[10] of Code[20]; var TempDefaultDim: Record "Default Dimension" temporary)
    var
        DefaultDim: Record "Default Dimension";
        NoFilter: array[2] of Code[20];
        i: Integer;
        j: Integer;
        Priority: array[2] of Integer;
    begin
        NoFilter[2] := '';
        for i := 1 to ArrayLen(TableID) do
            if (TableID[i] <> 0) and (No[i] <> '') then begin
                DefaultDim.SetFilter("Value Posting", '<>%1', DefaultDim."Value Posting"::" ");
                DefaultDim.SetRange("Table ID", TableID[i]);
                NoFilter[1] := No[i];
                for j := 1 to 2 do begin
                    DefaultDim.SetRange("No.", NoFilter[j]);
                    if DefaultDim.FindSet then
                        repeat
                            TempDefaultDim.SetRange("Dimension Code", DefaultDim."Dimension Code");
                            if not TempDefaultDim.FindFirst then begin
                                TempDefaultDim := DefaultDim;
                                TempDefaultDim.Insert();
                            end else begin
                                Priority[1] := GetDimensionPriorityForTable(TempDefaultDim."Table ID");
                                Priority[2] := GetDimensionPriorityForTable(DefaultDim."Table ID");
                                if not PriorityGreaterThan(Priority[1], Priority[2]) then begin
                                    if PriorityGreaterThan(Priority[2], Priority[1]) then
                                        TempDefaultDim.DeleteAll();
                                    TempDefaultDim := DefaultDim;
                                    if TempDefaultDim.Insert() then;
                                end;
                            end;
                        until DefaultDim.Next = 0;
                end;
            end;
        OnAfterCheckDimValuePosting(TableID, No, TempDefaultDim);
    end;

    local procedure PriorityGreaterThan(Priority1: Integer; Priority2: Integer): Boolean
    begin
        exit((Priority1 > 0) AND ((Priority2 = 0) or (Priority1 < Priority2)));
    end;

    local procedure GetDimensionPriorityForTable(TableID: Integer): Integer
    var
        DefaultDimPriority: Record "Default Dimension Priority";
    begin
        if DefaultDimPriority.GET(SourceCode, TableID) then
            exit(DefaultDimPriority.Priority);
        exit(0);
    end;

    local procedure GetMissedMandatoryDimErr(DefaultDim: Record "Default Dimension"): Text
    var
        ObjectTranslation: Record "Object Translation";
        DefaultDimensions: Page "Default Dimensions";
    begin
        if DefaultDim."No." = '' then
            exit(
              StrSubstNo(
                DefaultDimensionsValueCodeEmptyTxt, DefaultDim."Dimension Code", DefaultDimensions.Caption));
        exit(
          StrSubstNo(
            Text005,
            DefaultDim.FieldCaption("Dimension Value Code"),
            DefaultDim.FieldCaption("Dimension Code"),
            DefaultDim."Dimension Code",
            ObjectTranslation.TranslateTable(DefaultDim."Table ID"),
            DefaultDim."No."));
    end;

    local procedure GetNoCodeFilledDimErr(DefaultDim: Record "Default Dimension"): Text
    var
        ObjectTranslation: Record "Object Translation";
    begin
        if DefaultDim."No." = '' then
            exit(
              StrSubstNo(
                Text010,
                DefaultDim.FieldCaption("Dimension Code"), DefaultDim."Dimension Code"));
        exit(
          StrSubstNo(
            Text011,
            DefaultDim.FieldCaption("Dimension Code"),
            DefaultDim."Dimension Code",
            ObjectTranslation.TranslateTable(DefaultDim."Table ID"),
            DefaultDim."No."));
    end;

    local procedure GetSameCodeBlankDimErr(DefaultDim: Record "Default Dimension"): Text
    var
        ObjectTranslation: Record "Object Translation";
    begin
        if DefaultDim."No." = '' then
            exit(
              StrSubstNo(
                Text008,
                DefaultDim.FieldCaption("Dimension Code"), DefaultDim."Dimension Code"));
        exit(
          StrSubstNo(
            Text009,
            DefaultDim.FieldCaption("Dimension Code"),
            DefaultDim."Dimension Code",
            ObjectTranslation.TranslateTable(DefaultDim."Table ID"),
            DefaultDim."No."));
    end;

    local procedure GetSameCodeWrongDimErr(DefaultDim: Record "Default Dimension"): Text
    var
        ObjectTranslation: Record "Object Translation";
    begin
        if DefaultDim."No." = '' then
            exit(
              StrSubstNo(
                Text006,
                DefaultDim.FieldCaption("Dimension Value Code"), DefaultDim."Dimension Value Code",
                DefaultDim.FieldCaption("Dimension Code"), DefaultDim."Dimension Code"));
        exit(
          StrSubstNo(
            Text007,
            DefaultDim.FieldCaption("Dimension Value Code"),
            DefaultDim."Dimension Value Code",
            DefaultDim.FieldCaption("Dimension Code"),
            DefaultDim."Dimension Code",
            ObjectTranslation.TranslateTable(DefaultDim."Table ID"),
            DefaultDim."No."));
    end;

    procedure GetDimCombErr() ErrorMessage: Text[250]
    begin
        FindLastErrorMessage(ErrorMessage);
    end;

    procedure UpdateDefaultDim(TableID: Integer; No: Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        DefaultDim: Record "Default Dimension";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDefaultDim(TableID, No, GlobalDim1Code, GlobalDim2Code, IsHandled);
        if IsHandled then
            exit;

        GetGLSetup;
        if DefaultDim.Get(TableID, No, GLSetupShortcutDimCode[1]) then
            GlobalDim1Code := DefaultDim."Dimension Value Code"
        else
            GlobalDim1Code := '';
        if DefaultDim.Get(TableID, No, GLSetupShortcutDimCode[2]) then
            GlobalDim2Code := DefaultDim."Dimension Value Code"
        else
            GlobalDim2Code := '';
    end;

    procedure GetDefaultDimID(TableID: array[10] of Integer; No: array[10] of Code[20]; SourceCode: Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20]; InheritFromDimSetID: Integer; InheritFromTableNo: Integer): Integer
    var
        DimVal: Record "Dimension Value";
        DefaultDimPriority1: Record "Default Dimension Priority";
        DefaultDimPriority2: Record "Default Dimension Priority";
        DefaultDim: Record "Default Dimension";
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        TempDimSetEntry0: Record "Dimension Set Entry" temporary;
        i: Integer;
        j: Integer;
        NoFilter: array[2] of Code[20];
        NewDimSetID: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeGetDefaultDimID(TableID, No, SourceCode, GlobalDim1Code, GlobalDim2Code, InheritFromDimSetID, InheritFromTableNo);

        GetGLSetup;
        if InheritFromDimSetID > 0 then
            GetDimensionSet(TempDimSetEntry0, InheritFromDimSetID);
        if TempDimSetEntry0.FindSet then
            repeat
                TempDimBuf.Init();
                TempDimBuf."Table ID" := InheritFromTableNo;
                TempDimBuf."Entry No." := 0;
                TempDimBuf."Dimension Code" := TempDimSetEntry0."Dimension Code";
                TempDimBuf."Dimension Value Code" := TempDimSetEntry0."Dimension Value Code";
                TempDimBuf.Insert();
            until TempDimSetEntry0.Next = 0;

        NoFilter[2] := '';
        for i := 1 to ArrayLen(TableID) do
            if (TableID[i] <> 0) and (No[i] <> '') then begin
                IsHandled := false;
                OnGetDefaultDimOnBeforeCreate(
                  TempDimBuf, TableID[i], No[i], GLSetupShortcutDimCode, GlobalDim1Code, GlobalDim2Code, IsHandled, SourceCode);
                if not IsHandled then begin
                    DefaultDim.SetRange("Table ID", TableID[i]);
                    NoFilter[1] := No[i];
                    for j := 1 to 2 do begin
                        DefaultDim.SetRange("No.", NoFilter[j]);
                        if DefaultDim.FindSet then
                            repeat
                                if DefaultDim."Dimension Value Code" <> '' then begin
                                    TempDimBuf.SetRange("Dimension Code", DefaultDim."Dimension Code");
                                    if not TempDimBuf.FindFirst then begin
                                        TempDimBuf.Init();
                                        TempDimBuf."Table ID" := DefaultDim."Table ID";
                                        TempDimBuf."Entry No." := 0;
                                        TempDimBuf."Dimension Code" := DefaultDim."Dimension Code";
                                        TempDimBuf."Dimension Value Code" := DefaultDim."Dimension Value Code";
                                        TempDimBuf.Insert();
                                    end else
                                        if DefaultDimPriority1.Get(SourceCode, DefaultDim."Table ID") then
                                            if DefaultDimPriority2.Get(SourceCode, TempDimBuf."Table ID") then begin
                                                if DefaultDimPriority1.Priority < DefaultDimPriority2.Priority then begin
                                                    TempDimBuf.Delete();
                                                    TempDimBuf."Table ID" := DefaultDim."Table ID";
                                                    TempDimBuf."Entry No." := 0;
                                                    TempDimBuf."Dimension Value Code" := DefaultDim."Dimension Value Code";
                                                    TempDimBuf.Insert();
                                                end;
                                            end else begin
                                                TempDimBuf.Delete();
                                                TempDimBuf."Table ID" := DefaultDim."Table ID";
                                                TempDimBuf."Entry No." := 0;
                                                TempDimBuf."Dimension Value Code" := DefaultDim."Dimension Value Code";
                                                TempDimBuf.Insert();
                                            end;
                                    if GLSetupShortcutDimCode[1] = TempDimBuf."Dimension Code" then
                                        GlobalDim1Code := TempDimBuf."Dimension Value Code";
                                    if GLSetupShortcutDimCode[2] = TempDimBuf."Dimension Code" then
                                        GlobalDim2Code := TempDimBuf."Dimension Value Code";
                                end;
                            until DefaultDim.Next = 0;
                    end;
                end;
            end;

        OnGetDefaultDimIDOnBeforeFindNewDimSetID(TempDimBuf, TableID, No, GlobalDim1Code, GlobalDim2Code);

        TempDimBuf.Reset();
        if TempDimBuf.FindSet then begin
            repeat
                DimVal.Get(TempDimBuf."Dimension Code", TempDimBuf."Dimension Value Code");
                TempDimSetEntry."Dimension Code" := TempDimBuf."Dimension Code";
                TempDimSetEntry."Dimension Value Code" := TempDimBuf."Dimension Value Code";
                TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
                OnGetDefaultDimIDOnBeforeTempDimSetEntryInsert(TempDimSetEntry, TempDimBuf);
                TempDimSetEntry.Insert();
            until TempDimBuf.Next = 0;
            NewDimSetID := GetDimensionSetID(TempDimSetEntry);
        end;
        exit(NewDimSetID);
    end;

    procedure GetRecDefaultDimID(RecVariant: Variant; CurrFieldNo: Integer; TableID: array[10] of Integer; No: array[10] of Code[20]; SourceCode: Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20]; InheritFromDimSetID: Integer; InheritFromTableNo: Integer): Integer
    var
        DefaultDimID: Integer;
    begin
        OnGetRecDefaultDimID(RecVariant, CurrFieldNo, TableID, No, SourceCode, InheritFromDimSetID, InheritFromTableNo);
        DefaultDimID := GetDefaultDimID(TableID, No, SourceCode, GlobalDim1Code, GlobalDim2Code, InheritFromDimSetID, InheritFromTableNo);
        OnAfterGetRecDefaultDimID(
          RecVariant, CurrFieldNo, TableID, No, SourceCode, InheritFromDimSetID, InheritFromTableNo,
          GlobalDim1Code, GlobalDim2Code, DefaultDimID);
        exit(DefaultDimID);
    end;

    procedure AddFirstToTableIdArray(var TableID: array[10] of Integer; var No: array[10] of Code[20]; NewTableId: Integer; NewNo: Code[20])
    var
        Index: Integer;
    begin
        if NewNo = '' then
            exit;
        for Index := ArrayLen(TableID) downto 2 do begin
            TableID[Index] := TableID[Index - 1];
            No[Index] := No[Index - 1];
        end;
        TableID[1] := NewTableId;
        No[1] := NewNo;
    end;

    procedure AddLastToTableIdArray(var TableID: array[10] of Integer; var No: array[10] of Code[20]; NewTableId: Integer; NewNo: Code[20])
    var
        Index: Integer;
    begin
        if NewNo = '' then
            exit;
        for Index := 1 to ArrayLen(TableID) do
            if (No[Index] = '') or (Index = ArrayLen(TableID)) then begin
                TableID[Index] := NewTableId;
                No[Index] := NewNo;
                exit;
            end;
    end;

    procedure TypeToTableID1(Type: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner",Employee) TableId: Integer
    begin
        case Type of
            Type::"G/L Account":
                exit(DATABASE::"G/L Account");
            Type::Customer:
                exit(DATABASE::Customer);
            Type::Vendor:
                exit(DATABASE::Vendor);
            Type::Employee:
                exit(DATABASE::Employee);
            Type::"Bank Account":
                exit(DATABASE::"Bank Account");
            Type::"Fixed Asset":
                exit(DATABASE::"Fixed Asset");
            Type::"IC Partner":
                exit(DATABASE::"IC Partner");
        end;

        OnAfterTypeToTableID1(Type, TableId);
    end;

    procedure TypeToTableID2(Type: Option Resource,Item,"G/L Account"): Integer
    var
        TableID: Integer;
    begin
        case Type of
            Type::Resource:
                exit(DATABASE::Resource);
            Type::Item:
                exit(DATABASE::Item);
            Type::"G/L Account":
                exit(DATABASE::"G/L Account");
            else begin
                    OnTypeToTableID2(TableID, Type);
                    exit(TableID);
                end;
        end;
    end;

    procedure TypeToTableID3(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)") TableId: Integer
    begin
        case Type of
            Type::" ":
                exit(0);
            Type::"G/L Account":
                exit(DATABASE::"G/L Account");
            Type::Item:
                exit(DATABASE::Item);
            Type::Resource:
                exit(DATABASE::Resource);
            Type::"Fixed Asset":
                exit(DATABASE::"Fixed Asset");
            Type::"Charge (Item)":
                exit(DATABASE::"Item Charge");
        end;

        OnAfterTypeToTableID3(Type, TableId);
    end;

    procedure TypeToTableID4(Type: Option " ",Item,Resource) TableId: Integer
    begin
        case Type of
            Type::" ":
                exit(0);
            Type::Item:
                exit(DATABASE::Item);
            Type::Resource:
                exit(DATABASE::Resource);
        end;

        OnAfterTypeToTableID4(Type, TableId);
    end;

    procedure TypeToTableID5(Type: Option " ",Item,Resource,Cost,"G/L Account") TableId: Integer
    begin
        case Type of
            Type::" ":
                exit(0);
            Type::Item:
                exit(DATABASE::Item);
            Type::Resource:
                exit(DATABASE::Resource);
            Type::Cost:
                exit(DATABASE::"Service Cost");
            Type::"G/L Account":
                exit(DATABASE::"G/L Account");
        end;

        OnAfterTypeToTableID5(Type, TableId);
    end;

    procedure DeleteDefaultDim(TableID: Integer; No: Code[20])
    var
        DefaultDim: Record "Default Dimension";
    begin
        DefaultDim.SetRange("Table ID", TableID);
        DefaultDim.SetRange("No.", No);
        if not DefaultDim.IsEmpty then
            DefaultDim.DeleteAll();
    end;

    procedure RenameDefaultDim(TableID: Integer; OldNo: Code[20]; NewNo: Code[20])
    var
        DefaultDim: Record "Default Dimension";
        DefaultDimToRename: Record "Default Dimension";
    begin
        DefaultDim.SetRange("Table ID", TableID);
        DefaultDim.SetRange("No.", OldNo);
        if DefaultDim.FindSet(true) then
            repeat
                DefaultDimToRename := DefaultDim;
                DefaultDimToRename.Rename(DefaultDim."Table ID", NewNo, DefaultDim."Dimension Code");
            until DefaultDim.Next = 0;
    end;

    procedure LookupDimValueCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimVal: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
    begin
        OnBeforeLookupDimValueCode(FieldNumber, ShortcutDimCode);

        GetGLSetup;
        if GLSetupShortcutDimCode[FieldNumber] = '' then
            Error(Text002, GLSetup.TableCaption);
        DimVal.SetRange("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
        DimVal."Dimension Code" := GLSetupShortcutDimCode[FieldNumber];
        DimVal.Code := ShortcutDimCode;
        if PAGE.RunModal(0, DimVal) = ACTION::LookupOK then begin
            CheckDim(DimVal."Dimension Code");
            CheckDimValue(DimVal."Dimension Code", DimVal.Code);
            ShortcutDimCode := DimVal.Code;
        end;
    end;

    procedure ValidateDimValueCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimVal: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
    begin
        OnBeforeValidateDimValueCode(FieldNumber, ShortcutDimCode);

        GetGLSetup;
        if (GLSetupShortcutDimCode[FieldNumber] = '') and (ShortcutDimCode <> '') then
            Error(Text002, GLSetup.TableCaption);
        DimVal.SetRange("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
        if ShortcutDimCode <> '' then begin
            DimVal.SetRange(Code, ShortcutDimCode);
            if not DimVal.FindFirst then begin
                DimVal.SetFilter(Code, StrSubstNo('%1*', ShortcutDimCode));
                if DimVal.FindFirst then
                    ShortcutDimCode := DimVal.Code
                else
                    Error(
                      Text003,
                      ShortcutDimCode, DimVal.FieldCaption(Code));
            end;
        end;
    end;

    procedure ValidateShortcutDimValues(FieldNumber: Integer; var ShortcutDimCode: Code[20]; var DimSetID: Integer)
    var
        DimVal: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        DimVal."Dimension Code" := GLSetupShortcutDimCode[FieldNumber];
        if ShortcutDimCode <> '' then begin
            DimVal.Get(DimVal."Dimension Code", ShortcutDimCode);
            if not CheckDim(DimVal."Dimension Code") then
                Error(GetDimErr);
            if not CheckDimValue(DimVal."Dimension Code", ShortcutDimCode) then
                Error(GetDimErr);
        end;
        GetDimensionSet(TempDimSetEntry, DimSetID);
        if TempDimSetEntry.Get(TempDimSetEntry."Dimension Set ID", DimVal."Dimension Code") then
            if TempDimSetEntry."Dimension Value Code" <> ShortcutDimCode then
                TempDimSetEntry.Delete();
        if ShortcutDimCode <> '' then begin
            TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
            TempDimSetEntry."Dimension Value Code" := DimVal.Code;
            TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
            if TempDimSetEntry.Insert() then;
        end;
        DimSetID := GetDimensionSetID(TempDimSetEntry);

        OnAfterValidateShortcutDimValues(FieldNumber, ShortcutDimCode, DimSetID);
    end;

    procedure SaveDefaultDim(TableID: Integer; No: Code[20]; FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        DefaultDim: Record "Default Dimension";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveDefaultDim(TableID, No, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        GetGLSetup;
        if ShortcutDimCode <> '' then begin
            if DefaultDim.Get(TableID, No, GLSetupShortcutDimCode[FieldNumber])
            then begin
                DefaultDim.Validate("Dimension Value Code", ShortcutDimCode);
                DefaultDim.Modify();
            end else begin
                DefaultDim.Init();
                DefaultDim.Validate("Table ID", TableID);
                DefaultDim.Validate("No.", No);
                DefaultDim.Validate("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
                DefaultDim.Validate("Dimension Value Code", ShortcutDimCode);
                DefaultDim.Insert();
            end;
        end else
            if DefaultDim.Get(TableID, No, GLSetupShortcutDimCode[FieldNumber]) then
                DefaultDim.Delete();
    end;

    procedure GetShortcutDimensions(DimSetID: Integer; var ShortcutDimCode: array[8] of Code[20])
    var
        GetShortcutDimensionValues: Codeunit "Get Shortcut Dimension Values";
    begin
        GetShortcutDimensionValues.GetShortcutDimensions(DimSetID, ShortcutDimCode);
    end;

    procedure CheckDimBufferValuePosting(var DimBuffer: Record "Dimension Buffer"; TableID: array[10] of Integer; No: array[10] of Code[20]): Boolean
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        i: Integer;
    begin
        if DimBuffer.FindSet then begin
            i := 1;
            repeat
                if (not CheckDimValue(
                      DimBuffer."Dimension Code", DimBuffer."Dimension Value Code")) or
                   (not CheckDim(DimBuffer."Dimension Code"))
                then
                    exit(false);

                TempDimBuf.Init();
                TempDimBuf."Entry No." := i;
                TempDimBuf."Dimension Code" := DimBuffer."Dimension Code";
                TempDimBuf."Dimension Value Code" := DimBuffer."Dimension Value Code";
                TempDimBuf.Insert();
                i := i + 1;
            until DimBuffer.Next = 0;
        end;
        exit(CheckValuePosting(TableID, No, TempDimBuf));
    end;

    local procedure CheckValuePosting(TableID: array[10] of Integer; No: array[10] of Code[20]; var TempDimBuf: Record "Dimension Buffer" temporary): Boolean
    var
        DefaultDim: Record "Default Dimension";
        i: Integer;
        j: Integer;
        NoFilter: array[2] of Text[250];
        IsChecked: Boolean;
        IsHandled: Boolean;
    begin
        IsChecked := false;
        IsHandled := false;
        OnBeforeCheckValuePosting(TableID, No, TempDimBuf, IsChecked, IsHandled);
        if IsHandled then
            exit(IsChecked);

        DefaultDim.SetFilter("Value Posting", '<>%1', DefaultDim."Value Posting"::" ");
        NoFilter[2] := '';
        for i := 1 to ArrayLen(TableID) do
            if (TableID[i] <> 0) and (No[i] <> '') then begin
                DefaultDim.SetRange("Table ID", TableID[i]);
                NoFilter[1] := No[i];
                for j := 1 to 2 do begin
                    DefaultDim.SetRange("No.", NoFilter[j]);
                    if DefaultDim.FindSet then begin
                        repeat
                            TempDimBuf.SetRange("Dimension Code", DefaultDim."Dimension Code");
                            case DefaultDim."Value Posting" of
                                DefaultDim."Value Posting"::"Code Mandatory":
                                    if (not TempDimBuf.FindFirst) or (TempDimBuf."Dimension Value Code" = '') then begin
                                        LogError(
                                          DefaultDim.RecordId, DefaultDim.FieldNo("Value Posting"), GetMissedMandatoryDimErr(DefaultDim), '');
                                        exit(false);
                                    end;
                                DefaultDim."Value Posting"::"Same Code":
                                    if DefaultDim."Dimension Value Code" <> '' then begin
                                        if (not TempDimBuf.FindFirst) or
                                           (DefaultDim."Dimension Value Code" <> TempDimBuf."Dimension Value Code")
                                        then begin
                                            LogError(
                                              DefaultDim.RecordId, DefaultDim.FieldNo("Value Posting"), GetSameCodeWrongDimErr(DefaultDim), '');
                                            exit(false);
                                        end
                                    end else
                                        if TempDimBuf.FindFirst then begin
                                            LogError(
                                              DefaultDim.RecordId, DefaultDim.FieldNo("Value Posting"), GetSameCodeBlankDimErr(DefaultDim), '');
                                            exit(false);
                                        end;
                                DefaultDim."Value Posting"::"No Code":
                                    if TempDimBuf.FindFirst then begin
                                        LogError(
                                          DefaultDim.RecordId, DefaultDim.FieldNo("Value Posting"), GetNoCodeFilledDimErr(DefaultDim), '');
                                        exit(false);
                                    end;
                            end;
                        until DefaultDim.Next = 0;
                        TempDimBuf.Reset();
                    end;
                end;
            end;
        exit(true);
    end;

    procedure GetDimValuePostingErr() ErrorMessage: Text[250]
    begin
        FindLastErrorMessage(ErrorMessage);
    end;

    procedure DefaultDimObjectNoList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
        DefaultDimObjectNoWithoutGlobalDimsList(TempAllObjWithCaption);
        DefaultDimObjectNoWithGlobalDimsList(TempAllObjWithCaption);
    end;

    procedure DefaultDimObjectNoWithGlobalDimsList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    var
        TempDimField: Record "Field" temporary;
        TempDimSetIDField: Record "Field" temporary;
    begin
        TempDimField.SetFilter(
          TableNo, '<>%1&<>%2&<>%3',
          DATABASE::"General Ledger Setup", DATABASE::"Job Task", DATABASE::"Change Global Dim. Header");
        TempDimField.SetFilter(ObsoleteState, '<>%1', TempDimField.ObsoleteState::Removed);
        TempDimField.SetFilter(FieldName, '*Global Dimension*');
        TempDimField.SetRange(Type, TempDimField.Type::Code);
        TempDimField.SetRange(Len, 20);
        FillNormalFieldBuffer(TempDimField);
        TempDimSetIDField.SetRange(RelationTableNo, DATABASE::"Dimension Set Entry");
        FillNormalFieldBuffer(TempDimSetIDField);
        OnBeforeSetupObjectNoList(TempDimField);
        if TempDimField.FindSet then
            repeat
                TempDimSetIDField.SetRange(TableNo, TempDimField.TableNo);
                if TempDimSetIDField.IsEmpty then
                    DefaultDimInsertTempObject(TempAllObjWithCaption, TempDimField.TableNo);
            until TempDimField.Next = 0;
        OnAfterSetupObjectNoList(TempAllObjWithCaption);
    end;

    local procedure DefaultDimObjectNoWithoutGlobalDimsList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
        DefaultDimInsertTempObject(TempAllObjWithCaption, DATABASE::"IC Partner");
        DefaultDimInsertTempObject(TempAllObjWithCaption, DATABASE::"Service Order Type");
        DefaultDimInsertTempObject(TempAllObjWithCaption, DATABASE::"Service Item Group");
        DefaultDimInsertTempObject(TempAllObjWithCaption, DATABASE::"Service Item");
        DefaultDimInsertTempObject(TempAllObjWithCaption, DATABASE::"Service Contract Template");

        OnAfterDefaultDimObjectNoWithoutGlobalDimsList(TempAllObjWithCaption);
    end;

    local procedure DefaultDimInsertTempObject(var TempAllObjWithCaption: Record AllObjWithCaption temporary; TableID: Integer)
    begin
        if IsObsolete(TableID) then
            exit;
        if KeyContainsOneCodeField(TableID) or IsDefaultDimTable(TableID) then
            InsertObject(TempAllObjWithCaption, TableID);
    end;

    local procedure IsDefaultDimTable(TableID: Integer): Boolean
    begin
        // Local versions should add exceptions here
        exit(TableID = 0);
    end;

    local procedure KeyContainsOneCodeField(TableID: Integer) Result: Boolean
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        Result := (KeyRef.FieldCount = 1) and (FieldRef.Type = FieldType::Code);
        RecRef.Close;
    end;

    procedure GlobalDimObjectNoList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    var
        "Field": Record "Field";
        TempDimField: Record "Field" temporary;
        TempDimSetIDField: Record "Field" temporary;
        LastTableNo: Integer;
    begin
        TempDimSetIDField.SetRange(RelationTableNo, DATABASE::"Dimension Set Entry");
        FillNormalFieldBuffer(TempDimSetIDField);
        TempDimField.SetFilter(FieldName, '*Global Dimension*|*Shortcut Dimension*|*Global Dim.*');
        TempDimField.SetFilter(ObsoleteState, '<>%1', TempDimField.ObsoleteState::Removed);
        TempDimField.SetRange(Type, TempDimField.Type::Code);
        TempDimField.SetRange(Len, 20);
        FillNormalFieldBuffer(TempDimField);
        TempDimField.Reset();
        if TempDimSetIDField.FindSet then
            repeat
                TempDimField.SetRange(TableNo, TempDimSetIDField.TableNo);
                if not TempDimField.IsEmpty then begin
                    InsertObject(TempAllObjWithCaption, TempDimSetIDField.TableNo);
                    TempDimField.DeleteAll();
                end;
            until TempDimSetIDField.Next = 0;

        TempDimField.Reset();
        TempDimField.SetFilter(ObsoleteState, '<>%1', TempDimField.ObsoleteState::Removed);
        TempDimField.SetFilter(FieldName, '*Global Dim.*');
        if TempDimField.FindSet then
            repeat
                if LastTableNo <> TempDimField.TableNo then begin
                    LastTableNo := TempDimField.TableNo;
                    // Field No. 2 must relate to a table with Dim Set ID
                    if Field.Get(TempDimField.TableNo, 2) then begin
                        TempDimSetIDField.SetRange(TableNo, Field.RelationTableNo);
                        if not TempDimSetIDField.IsEmpty then
                            InsertObject(TempAllObjWithCaption, TempDimField.TableNo);
                    end;
                end;
            until TempDimField.Next = 0;
    end;

    procedure JobTaskDimObjectNoList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
        // Table 1001 "Job Task" is an exception
        // it has Table 1002 "Job Task Dimension" that implements default dimension behavior
        InsertObject(TempAllObjWithCaption, DATABASE::"Job Task");
    end;

    procedure FindDimFieldInTable(TableNo: Integer; FieldNameFilter: Text; var "Field": Record "Field"): Boolean
    begin
        if IsObsolete(TableNo) then
            exit(false);
        Field.SetRange(TableNo, TableNo);
        Field.SetFilter(FieldName, '*' + FieldNameFilter + '*');
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(Type, Field.Type::Code);
        Field.SetRange(Len, 20);
        if Field.FindFirst then
            exit(true);
    end;

    local procedure FillNormalFieldBuffer(var TempField: Record "Field")
    var
        "Field": Record "Field";
    begin
        Field.CopyFilters(TempField);
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        if Field.FindSet then
            repeat
                if not IsObsolete(Field.TableNo) then begin
                    TempField := Field;
                    TempField.Insert();
                end;
            until Field.Next = 0;
    end;

    procedure GetDocDimConsistencyErr() ErrorMessage: Text[250]
    begin
        FindLastErrorMessage(ErrorMessage);
    end;

    procedure CheckDim(DimCode: Code[20]): Boolean
    var
        Dim: Record Dimension;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDim(DimCode, Result, IsHandled);
        if IsHandled then
            EXIT(Result);

        if Dim.Get(DimCode) then begin
            if Dim.Blocked then begin
                LogError(
                  Dim.RecordId, Dim.FieldNo(Blocked), StrSubstNo(Text014, Dim.TableCaption, DimCode), '');
                exit(false);
            end;
        end else begin
            LogError(
              DATABASE::Dimension, 0, StrSubstNo(Text015, Dim.TableCaption, DimCode), '');
            exit(false);
        end;
        exit(true);
    end;

    procedure CheckDimValue(DimCode: Code[20]; DimValCode: Code[20]): Boolean
    var
        DimVal: Record "Dimension Value";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDimValue(DimCode, DimValCode, Result, IsHandled);
        if IsHandled then
            exit;

        if (DimCode <> '') and (DimValCode <> '') then
            if DimVal.Get(DimCode, DimValCode) then begin
                if DimVal.Blocked then begin
                    LogError(
                      DimVal.RecordId, DimVal.FieldNo(Blocked),
                      StrSubstNo(DimValueBlockedErr, DimVal.TableCaption, DimCode, DimValCode), '');
                    exit(false);
                end;
                if not CheckDimValueAllowed(DimVal) then
                    exit(false);
            end else begin
                LogError(
                  DATABASE::"Dimension Value", 0,
                  StrSubstNo(DimValueMissingErr, DimVal.TableCaption, DimCode), '');
                exit(false);
            end;
        exit(true);
    end;

    local procedure CheckDimValueAllowed(DimVal: Record "Dimension Value"): Boolean
    var
        DimValueAllowed: Boolean;
        DimErr: Text[250];
    begin
        DimValueAllowed :=
          (DimVal."Dimension Value Type" in [DimVal."Dimension Value Type"::Standard, DimVal."Dimension Value Type"::"Begin-Total"]);
        if not DimValueAllowed then
            DimErr :=
              StrSubstNo(
                DimValueMustNotBeErr, DimVal.TableCaption, DimVal."Dimension Code", DimVal.Code, Format(DimVal."Dimension Value Type"))
        else
            OnCheckDimValueAllowed(DimVal, DimValueAllowed, DimErr);

        if not DimValueAllowed then
            LogError(DimVal.RecordId, DimVal.FieldNo("Dimension Value Type"), DimErr, '');
        exit(DimValueAllowed);
    end;

    local procedure CheckBlockedDimAndValues(DimSetID: Integer): Boolean
    var
        DimSetEntry: Record "Dimension Set Entry";
        LastErrorID: Integer;
    begin
        if DimSetID = 0 then
            exit(true);
        LastErrorID := GetLastDimErrorID;
        DimSetEntry.Reset();
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.FindSet then
            repeat
                if not CheckDim(DimSetEntry."Dimension Code") or
                   not CheckDimValue(DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                then
                    if not IsCollectErrorsMode then
                        exit(false);
            until DimSetEntry.Next = 0;
        exit(GetLastDimErrorID = LastErrorID);
    end;

    procedure GetDimErr() ErrorMessage: Text[250]
    begin
        FindLastErrorMessage(ErrorMessage);
    end;

    local procedure LogError(SourceRecVariant: Variant; SourceFieldNo: Integer; Message: Text; HelpArticleCode: Code[30]) IsLogged: Boolean
    var
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
    begin
        if ErrorMessageMgt.IsActive then begin
            if HelpArticleCode = '' then
                HelpArticleCode := ForwardLinkMgt.GetHelpCodeForWorkingWithDimensions;
            ErrorMessageMgt.LogContextFieldError(0, Message, SourceRecVariant, SourceFieldNo, HelpArticleCode);
            IsLogged := true;
        end else begin
            LastErrorMessage.Init();
            LastErrorMessage.ID += 1;
            LastErrorMessage.Description := CopyStr(Message, 1, MaxStrLen(LastErrorMessage.Description));
            IsLogged := false;
        end;
    end;

    procedure LookupDimValueCodeNoUpdate(FieldNumber: Integer)
    var
        DimVal: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
    begin
        OnBeforeLookupDimValueCodeNoUpdate(FieldNumber);

        GetGLSetup;
        if GLSetupShortcutDimCode[FieldNumber] = '' then
            Error(Text002, GLSetup.TableCaption);
        DimVal.SetRange("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
        if PAGE.RunModal(0, DimVal) = ACTION::LookupOK then;
    end;

    procedure CopyJnlLineDimToICJnlDim(TableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Option; LineNo: Integer; DimSetID: Integer)
    var
        InOutBoxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        DimSetEntry: Record "Dimension Set Entry";
        ICDim: Code[20];
        ICDimValue: Code[20];
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.FindSet then
            repeat
                ICDim := ConvertDimtoICDim(DimSetEntry."Dimension Code");
                ICDimValue := ConvertDimValuetoICDimVal(DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                if (ICDim <> '') and (ICDimValue <> '') then begin
                    InOutBoxJnlLineDim.Init();
                    InOutBoxJnlLineDim."Table ID" := TableID;
                    InOutBoxJnlLineDim."IC Partner Code" := PartnerCode;
                    InOutBoxJnlLineDim."Transaction No." := TransactionNo;
                    InOutBoxJnlLineDim."Transaction Source" := TransactionSource;
                    InOutBoxJnlLineDim."Line No." := LineNo;
                    InOutBoxJnlLineDim."Dimension Code" := ICDim;
                    InOutBoxJnlLineDim."Dimension Value Code" := ICDimValue;
                    InOutBoxJnlLineDim.Insert();
                end;
            until DimSetEntry.Next = 0;
    end;

    procedure DefaultDimOnInsert(DefaultDimension: Record "Default Dimension")
    var
        CallingTrigger: Option OnInsert,OnModify,OnDelete;
    begin
        if DefaultDimension."Table ID" = DATABASE::Job then
            UpdateJobTaskDim(DefaultDimension, false);

        UpdateCostType(DefaultDimension, CallingTrigger::OnInsert);
    end;

    procedure DefaultDimOnModify(DefaultDimension: Record "Default Dimension")
    var
        CallingTrigger: Option OnInsert,OnModify,OnDelete;
    begin
        if DefaultDimension."Table ID" = DATABASE::Job then
            UpdateJobTaskDim(DefaultDimension, false);

        UpdateCostType(DefaultDimension, CallingTrigger::OnModify);
    end;

    procedure DefaultDimOnDelete(DefaultDimension: Record "Default Dimension")
    var
        CallingTrigger: Option OnInsert,OnModify,OnDelete;
    begin
        if DefaultDimension."Table ID" = DATABASE::Job then
            UpdateJobTaskDim(DefaultDimension, true);

        UpdateCostType(DefaultDimension, CallingTrigger::OnDelete);
    end;

    procedure CopyICJnlDimToICJnlDim(var FromInOutBoxLineDim: Record "IC Inbox/Outbox Jnl. Line Dim."; var ToInOutBoxlineDim: Record "IC Inbox/Outbox Jnl. Line Dim.")
    begin
        if FromInOutBoxLineDim.FindSet then
            repeat
                ToInOutBoxlineDim := FromInOutBoxLineDim;
                ToInOutBoxlineDim.Insert();
            until FromInOutBoxLineDim.Next = 0;
    end;

    procedure CopyDocDimtoICDocDim(TableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Option; LineNo: Integer; DimSetEntryID: Integer)
    var
        InOutBoxDocDim: Record "IC Document Dimension";
        DimSetEntry: Record "Dimension Set Entry";
        ICDim: Code[20];
        ICDimValue: Code[20];
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetEntryID);
        if DimSetEntry.FindSet then
            repeat
                ICDim := ConvertDimtoICDim(DimSetEntry."Dimension Code");
                ICDimValue := ConvertDimValuetoICDimVal(DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                if (ICDim <> '') and (ICDimValue <> '') then begin
                    InOutBoxDocDim.Init();
                    InOutBoxDocDim."Table ID" := TableID;
                    InOutBoxDocDim."IC Partner Code" := PartnerCode;
                    InOutBoxDocDim."Transaction No." := TransactionNo;
                    InOutBoxDocDim."Transaction Source" := TransactionSource;
                    InOutBoxDocDim."Line No." := LineNo;
                    InOutBoxDocDim."Dimension Code" := ICDim;
                    InOutBoxDocDim."Dimension Value Code" := ICDimValue;
                    InOutBoxDocDim.Insert();
                end;
            until DimSetEntry.Next = 0;
    end;

    procedure CopyICDocDimtoICDocDim(FromSourceICDocDim: Record "IC Document Dimension"; var ToSourceICDocDim: Record "IC Document Dimension"; ToTableID: Integer; ToTransactionSource: Integer)
    begin
        with FromSourceICDocDim do begin
            SetICDocDimFilters(FromSourceICDocDim, "Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
            if FindSet then
                repeat
                    ToSourceICDocDim := FromSourceICDocDim;
                    ToSourceICDocDim."Table ID" := ToTableID;
                    ToSourceICDocDim."Transaction Source" := ToTransactionSource;
                    ToSourceICDocDim.Insert();
                until Next = 0;
        end;
    end;

    procedure MoveICDocDimtoICDocDim(FromSourceICDocDim: Record "IC Document Dimension"; var ToSourceICDocDim: Record "IC Document Dimension"; ToTableID: Integer; ToTransactionSource: Integer)
    begin
        with FromSourceICDocDim do begin
            SetICDocDimFilters(FromSourceICDocDim, "Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
            if FindSet then
                repeat
                    ToSourceICDocDim := FromSourceICDocDim;
                    ToSourceICDocDim."Table ID" := ToTableID;
                    ToSourceICDocDim."Transaction Source" := ToTransactionSource;
                    ToSourceICDocDim.Insert();
                    Delete;
                until Next = 0;
        end;
    end;

    procedure SetICDocDimFilters(var ICDocDim: Record "IC Document Dimension"; TableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Integer; LineNo: Integer)
    begin
        ICDocDim.Reset();
        ICDocDim.SetRange("Table ID", TableID);
        ICDocDim.SetRange("Transaction No.", TransactionNo);
        ICDocDim.SetRange("IC Partner Code", PartnerCode);
        ICDocDim.SetRange("Transaction Source", TransactionSource);
        ICDocDim.SetRange("Line No.", LineNo);
    end;

    procedure DeleteICDocDim(TableID: Integer; ICTransactionNo: Integer; ICPartnerCode: Code[20]; TransactionSource: Option; LineNo: Integer)
    var
        ICDocDim: Record "IC Document Dimension";
    begin
        SetICDocDimFilters(ICDocDim, TableID, ICTransactionNo, ICPartnerCode, TransactionSource, LineNo);
        if not ICDocDim.IsEmpty then
            ICDocDim.DeleteAll();
    end;

    procedure DeleteICJnlDim(TableID: Integer; ICTransactionNo: Integer; ICPartnerCode: Code[20]; TransactionSource: Option; LineNo: Integer)
    var
        ICJnlDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
    begin
        ICJnlDim.SetRange("Table ID", TableID);
        ICJnlDim.SetRange("Transaction No.", ICTransactionNo);
        ICJnlDim.SetRange("IC Partner Code", ICPartnerCode);
        ICJnlDim.SetRange("Transaction Source", TransactionSource);
        ICJnlDim.SetRange("Line No.", LineNo);
        if not ICJnlDim.IsEmpty then
            ICJnlDim.DeleteAll();
    end;

    local procedure ConvertICDimtoDim(FromICDimCode: Code[20]) DimCode: Code[20]
    var
        ICDim: Record "IC Dimension";
    begin
        if ICDim.Get(FromICDimCode) then
            DimCode := ICDim."Map-to Dimension Code";

        OnAfterConvertICDimtoDim(FromICDimCode, DimCode);
    end;

    local procedure ConvertICDimValuetoDimValue(FromICDimCode: Code[20]; FromICDimValue: Code[20]) DimValueCode: Code[20]
    var
        ICDimValue: Record "IC Dimension Value";
    begin
        if ICDimValue.Get(FromICDimCode, FromICDimValue) then
            DimValueCode := ICDimValue."Map-to Dimension Value Code";

        OnAfterConvertICDimValuetoDimValue(FromICDimCode, FromICDimValue, DimValueCode);
    end;

    procedure ConvertDimtoICDim(FromDim: Code[20]) ICDimCode: Code[20]
    var
        Dim: Record Dimension;
    begin
        if Dim.Get(FromDim) then
            ICDimCode := Dim."Map-to IC Dimension Code";

        OnAfterConvertDimtoICDim(FromDim, ICDimCode);
    end;

    procedure ConvertDimValuetoICDimVal(FromDim: Code[20]; FromDimValue: Code[20]) ICDimValueCode: Code[20]
    var
        DimValue: Record "Dimension Value";
    begin
        if DimValue.Get(FromDim, FromDimValue) then
            ICDimValueCode := DimValue."Map-to IC Dimension Value Code";

        OnAfterConvertDimValuetoICDimVal(FromDim, FromDimValue, ICDimValueCode);
    end;

    procedure CheckICDimValue(ICDimCode: Code[20]; ICDimValCode: Code[20]): Boolean
    var
        ICDimVal: Record "IC Dimension Value";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeCheckICDimValue(ICDimCode, ICDimValCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if (ICDimCode <> '') and (ICDimValCode <> '') then
            if ICDimVal.Get(ICDimCode, ICDimValCode) then begin
                if ICDimVal.Blocked then begin
                    LogError(
                      ICDimVal.RecordId, ICDimVal.FieldNo(Blocked),
                      StrSubstNo(DimValueBlockedErr, ICDimVal.TableCaption, ICDimCode, ICDimValCode), '');
                    exit(false);
                end;
                if not CheckICDimValueAllowed(ICDimVal) then begin
                    LogError(
                      ICDimVal.RecordId, ICDimVal.FieldNo("Dimension Value Type"),
                      StrSubstNo(
                        DimValueMustNotBeErr, ICDimVal.TableCaption, ICDimCode, ICDimValCode,
                        Format(ICDimVal."Dimension Value Type")),
                      '');
                    exit(false);
                end;
            end else begin
                LogError(
                  DATABASE::"IC Dimension Value", 0,
                  StrSubstNo(DimValueMissingErr, ICDimVal.TableCaption, ICDimCode), '');
                exit(false);
            end;
        exit(true);
    end;

    local procedure CheckICDimValueAllowed(ICDimVal: Record "IC Dimension Value"): Boolean
    var
        DimValueAllowed: Boolean;
    begin
        DimValueAllowed :=
          ICDimVal."Dimension Value Type" in [ICDimVal."Dimension Value Type"::Standard, ICDimVal."Dimension Value Type"::"Begin-Total"];

        OnCheckICDimValueAllowed(ICDimVal, DimValueAllowed);

        exit(DimValueAllowed);
    end;

    procedure CheckICDim(ICDimCode: Code[20]): Boolean
    var
        ICDim: Record "IC Dimension";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        Result := false;
        IsHandled := false;
        OnBeforeCheckICDim(ICDimCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ICDim.Get(ICDimCode) then begin
            if ICDim.Blocked then begin
                LogError(
                  ICDim.RecordId, ICDim.FieldNo(Blocked), StrSubstNo(Text014, ICDim.TableCaption, ICDimCode), '');
                exit(false);
            end;
        end else begin
            LogError(
              DATABASE::"IC Dimension", 0, StrSubstNo(Text015, ICDim.TableCaption, ICDimCode), '');
            exit(false);
        end;
        exit(true);
    end;

    procedure SaveJobTaskDim(JobNo: Code[20]; JobTaskNo: Code[20]; FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        JobTaskDim: Record "Job Task Dimension";
    begin
        GetGLSetup;
        if ShortcutDimCode <> '' then begin
            if JobTaskDim.Get(JobNo, JobTaskNo, GLSetupShortcutDimCode[FieldNumber])
            then begin
                JobTaskDim.Validate("Dimension Value Code", ShortcutDimCode);
                JobTaskDim.Modify();
            end else begin
                JobTaskDim.Init();
                JobTaskDim.Validate("Job No.", JobNo);
                JobTaskDim.Validate("Job Task No.", JobTaskNo);
                JobTaskDim.Validate("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
                JobTaskDim.Validate("Dimension Value Code", ShortcutDimCode);
                JobTaskDim.Insert();
            end;
        end else
            if JobTaskDim.Get(JobNo, JobTaskNo, GLSetupShortcutDimCode[FieldNumber]) then
                JobTaskDim.Delete();
    end;

    procedure SaveJobTaskTempDim(FieldNumber: Integer; ShortcutDimCode: Code[20])
    begin
        GetGLSetup;
        if ShortcutDimCode <> '' then begin
            if TempJobTaskDimBuffer.Get('', '', GLSetupShortcutDimCode[FieldNumber])
            then begin
                TempJobTaskDimBuffer."Dimension Value Code" := ShortcutDimCode;
                TempJobTaskDimBuffer.Modify();
            end else begin
                TempJobTaskDimBuffer.Init();
                TempJobTaskDimBuffer."Dimension Code" := GLSetupShortcutDimCode[FieldNumber];
                TempJobTaskDimBuffer."Dimension Value Code" := ShortcutDimCode;
                TempJobTaskDimBuffer.Insert();
            end;
        end else
            if TempJobTaskDimBuffer.Get('', '', GLSetupShortcutDimCode[FieldNumber]) then
                TempJobTaskDimBuffer.Delete();
    end;

    procedure InsertJobTaskDim(JobNo: Code[20]; JobTaskNo: Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        DefaultDim: Record "Default Dimension";
        JobTaskDim: Record "Job Task Dimension";
    begin
        GetGLSetup;
        DefaultDim.SetRange("Table ID", DATABASE::Job);
        DefaultDim.SetRange("No.", JobNo);
        if DefaultDim.FindSet(false, false) then
            repeat
                if DefaultDim."Dimension Value Code" <> '' then begin
                    JobTaskDim.Init();
                    JobTaskDim."Job No." := JobNo;
                    JobTaskDim."Job Task No." := JobTaskNo;
                    JobTaskDim."Dimension Code" := DefaultDim."Dimension Code";
                    JobTaskDim."Dimension Value Code" := DefaultDim."Dimension Value Code";
                    JobTaskDim.Insert();
                    if JobTaskDim."Dimension Code" = GLSetupShortcutDimCode[1] then
                        GlobalDim1Code := JobTaskDim."Dimension Value Code";
                    if JobTaskDim."Dimension Code" = GLSetupShortcutDimCode[2] then
                        GlobalDim2Code := JobTaskDim."Dimension Value Code";
                end;
            until DefaultDim.Next = 0;

        TempJobTaskDimBuffer.Reset();
        if TempJobTaskDimBuffer.FindSet then
            repeat
                if not JobTaskDim.Get(JobNo, JobTaskNo, TempJobTaskDimBuffer."Dimension Code") then begin
                    JobTaskDim.Init();
                    JobTaskDim."Job No." := JobNo;
                    JobTaskDim."Job Task No." := JobTaskNo;
                    JobTaskDim."Dimension Code" := TempJobTaskDimBuffer."Dimension Code";
                    JobTaskDim."Dimension Value Code" := TempJobTaskDimBuffer."Dimension Value Code";
                    JobTaskDim.Insert();
                    if JobTaskDim."Dimension Code" = GLSetupShortcutDimCode[1] then
                        GlobalDim1Code := JobTaskDim."Dimension Value Code";
                    if JobTaskDim."Dimension Code" = GLSetupShortcutDimCode[2] then
                        GlobalDim2Code := JobTaskDim."Dimension Value Code";
                end;
            until TempJobTaskDimBuffer.Next = 0;
        TempJobTaskDimBuffer.DeleteAll();
    end;

    local procedure UpdateJobTaskDim(DefaultDimension: Record "Default Dimension"; FromOnDelete: Boolean)
    var
        JobTaskDimension: Record "Job Task Dimension";
        JobTask: Record "Job Task";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        if DefaultDimension."Table ID" <> DATABASE::Job then
            exit;

        JobTask.SetRange("Job No.", DefaultDimension."No.");
        if JobTask.IsEmpty() then
            exit;

        IsHandled := false;
        OnUpdateJobTaskDimOnBeforConfirm(DefaultDimension, IsHandled);
        if not IsHandled then
            if not ConfirmManagement.GetResponseOrDefault(Text019, true) then
                exit;

        JobTaskDimension.SetRange("Job No.", DefaultDimension."No.");
        JobTaskDimension.SetRange("Dimension Code", DefaultDimension."Dimension Code");
        JobTaskDimension.DeleteAll(true);

        if FromOnDelete or
           (DefaultDimension."Value Posting" = DefaultDimension."Value Posting"::"No Code") or
           (DefaultDimension."Dimension Value Code" = '')
        then
            exit;

        if JobTask.FindSet() then
            repeat
                Clear(JobTaskDimension);
                JobTaskDimension."Job No." := JobTask."Job No.";
                JobTaskDimension."Job Task No." := JobTask."Job Task No.";
                JobTaskDimension."Dimension Code" := DefaultDimension."Dimension Code";
                JobTaskDimension."Dimension Value Code" := DefaultDimension."Dimension Value Code";
                JobTaskDimension.Insert(true);
            until JobTask.Next() = 0;
    end;

    procedure DeleteJobTaskTempDim()
    begin
        TempJobTaskDimBuffer.Reset();
        TempJobTaskDimBuffer.DeleteAll();
    end;

    procedure CopyJobTaskDimToJobTaskDim(JobNo: Code[20]; JobTaskNo: Code[20]; NewJobNo: Code[20]; NewJobTaskNo: Code[20])
    var
        JobTaskDimension: Record "Job Task Dimension";
        JobTaskDimension2: Record "Job Task Dimension";
    begin
        JobTaskDimension.Reset();
        JobTaskDimension.SetRange("Job No.", JobNo);
        JobTaskDimension.SetRange("Job Task No.", JobTaskNo);
        if JobTaskDimension.FindSet then
            repeat
                if not JobTaskDimension2.Get(NewJobNo, NewJobTaskNo, JobTaskDimension."Dimension Code") then begin
                    JobTaskDimension2.Init();
                    JobTaskDimension2."Job No." := NewJobNo;
                    JobTaskDimension2."Job Task No." := NewJobTaskNo;
                    JobTaskDimension2."Dimension Code" := JobTaskDimension."Dimension Code";
                    JobTaskDimension2."Dimension Value Code" := JobTaskDimension."Dimension Value Code";
                    JobTaskDimension2.Insert(true);
                end else begin
                    JobTaskDimension2."Dimension Value Code" := JobTaskDimension."Dimension Value Code";
                    JobTaskDimension2.Modify(true);
                end;
            until JobTaskDimension.Next = 0;

        JobTaskDimension2.Reset();
        JobTaskDimension2.SetRange("Job No.", NewJobNo);
        JobTaskDimension2.SetRange("Job Task No.", NewJobTaskNo);
        if JobTaskDimension2.FindSet then
            repeat
                if not JobTaskDimension.Get(JobNo, JobTaskNo, JobTaskDimension2."Dimension Code") then
                    JobTaskDimension2.Delete(true);
            until JobTaskDimension2.Next = 0;
    end;

    procedure CheckDimIDConsistency(var DimSetEntry: Record "Dimension Set Entry"; var PostedDimSetEntry: Record "Dimension Set Entry"; DocTableID: Integer; PostedDocTableID: Integer): Boolean
    var
        ObjectTranslation: Record "Object Translation";
    begin
        if DimSetEntry.FindSet then;
        if PostedDimSetEntry.FindSet then;
        repeat
            case true of
                DimSetEntry."Dimension Code" > PostedDimSetEntry."Dimension Code":
                    begin
                        LogError(
                          DimSetEntry.RecordId, 0,
                          StrSubstNo(
                            Text012,
                            DimSetEntry.FieldCaption("Dimension Code"),
                            ObjectTranslation.TranslateTable(DocTableID),
                            ObjectTranslation.TranslateTable(PostedDocTableID)),
                          '');
                        exit(false);
                    end;
                DimSetEntry."Dimension Code" < PostedDimSetEntry."Dimension Code":
                    begin
                        LogError(
                          DimSetEntry.RecordId, 0,
                          StrSubstNo(
                            Text012,
                            PostedDimSetEntry.FieldCaption("Dimension Code"),
                            ObjectTranslation.TranslateTable(PostedDocTableID),
                            ObjectTranslation.TranslateTable(DocTableID))
                          , '');
                        exit(false);
                    end;
                DimSetEntry."Dimension Code" = PostedDimSetEntry."Dimension Code":
                    if DimSetEntry."Dimension Value Code" <> PostedDimSetEntry."Dimension Value Code" then begin
                        LogError(
                          DimSetEntry.RecordId, 0,
                          StrSubstNo(
                            Text013,
                            DimSetEntry.FieldCaption("Dimension Value Code"),
                            DimSetEntry.FieldCaption("Dimension Code"),
                            DimSetEntry."Dimension Code",
                            ObjectTranslation.TranslateTable(DocTableID),
                            ObjectTranslation.TranslateTable(PostedDocTableID)),
                          '');
                        exit(false);
                    end;
            end;
        until (DimSetEntry.Next = 0) and (PostedDimSetEntry.Next = 0);
        exit(true);
    end;

    local procedure CreateDimSetEntryFromDimValue(DimValue: Record "Dimension Value"; var TempDimSetEntry: Record "Dimension Set Entry" temporary)
    begin
        TempDimSetEntry."Dimension Code" := DimValue."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimValue.Code;
        TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
        TempDimSetEntry.Insert();
    end;

    procedure CreateDimSetIDFromICDocDim(var ICDocDim: Record "IC Document Dimension"): Integer
    var
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        if ICDocDim.Find('-') then
            repeat
                DimValue.Get(
                  ConvertICDimtoDim(ICDocDim."Dimension Code"),
                  ConvertICDimValuetoDimValue(ICDocDim."Dimension Code", ICDocDim."Dimension Value Code"));
                CreateDimSetEntryFromDimValue(DimValue, TempDimSetEntry);
            until ICDocDim.Next = 0;
        exit(GetDimensionSetID(TempDimSetEntry));
    end;

    procedure CreateDimSetIDFromICJnlLineDim(var ICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim."): Integer
    var
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        if ICInboxOutboxJnlLineDim.Find('-') then
            repeat
                DimValue.Get(
                  ConvertICDimtoDim(ICInboxOutboxJnlLineDim."Dimension Code"),
                  ConvertICDimValuetoDimValue(
                    ICInboxOutboxJnlLineDim."Dimension Code", ICInboxOutboxJnlLineDim."Dimension Value Code"));
                CreateDimSetEntryFromDimValue(DimValue, TempDimSetEntry);
            until ICInboxOutboxJnlLineDim.Next = 0;
        exit(GetDimensionSetID(TempDimSetEntry));
    end;

    procedure CopyDimBufToDimSetEntry(var FromDimBuf: Record "Dimension Buffer"; var DimSetEntry: Record "Dimension Set Entry")
    var
        DimValue: Record "Dimension Value";
    begin
        with FromDimBuf do
            if FindSet then
                repeat
                    DimValue.Get("Dimension Code", "Dimension Value Code");
                    DimSetEntry."Dimension Code" := "Dimension Code";
                    DimSetEntry."Dimension Value Code" := "Dimension Value Code";
                    DimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
                    DimSetEntry.Insert();
                until Next = 0;
    end;

    procedure CreateDimSetIDFromDimBuf(var DimBuf: Record "Dimension Buffer"): Integer
    var
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        if DimBuf.FindSet then
            repeat
                DimValue.Get(DimBuf."Dimension Code", DimBuf."Dimension Value Code");
                CreateDimSetEntryFromDimValue(DimValue, TempDimSetEntry);
            until DimBuf.Next = 0;
        exit(GetDimensionSetID(TempDimSetEntry));
    end;

    procedure CreateDimForPurchLineWithHigherPriorities(PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; var DimensionSetID: Integer; var DimValue1: Code[20]; var DimValue2: Code[20]; SourceCode: Code[10]; PriorityTableID: Integer)
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        HighPriorityTableID: array[10] of Integer;
        HighPriorityNo: array[10] of Code[20];
    begin
        TableID[1] := DATABASE::Job;
        TableID[2] := TypeToTableID3(PurchaseLine.Type);
        No[1] := PurchaseLine."Job No.";
        No[2] := PurchaseLine."No.";

        OnBeforeGetTableIDsForHigherPriorities(DATABASE::"Purchase Line", PurchaseLine, CurrFieldNo, TableID, No);
        if GetTableIDsForHigherPriorities(
             TableID, No, HighPriorityTableID, HighPriorityNo, SourceCode, PriorityTableID)
        then
            DimensionSetID :=
              GetRecDefaultDimID(
                PurchaseLine, CurrFieldNo, HighPriorityTableID, HighPriorityNo, SourceCode, DimValue1, DimValue2, 0, 0);
    end;

    procedure CreateDimForSalesLineWithHigherPriorities(SalesLine: Record "Sales Line"; CurrFieldNo: Integer; var DimensionSetID: Integer; var DimValue1: Code[20]; var DimValue2: Code[20]; SourceCode: Code[10]; PriorityTableID: Integer)
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        HighPriorityTableID: array[10] of Integer;
        HighPriorityNo: array[10] of Code[20];
    begin
        TableID[1] := DATABASE::Job;
        TableID[2] := TypeToTableID3(SalesLine.Type);
        No[1] := SalesLine."Job No.";
        No[2] := SalesLine."No.";

        OnBeforeGetTableIDsForHigherPriorities(DATABASE::"Sales Line", SalesLine, CurrFieldNo, TableID, No);
        if GetTableIDsForHigherPriorities(
             TableID, No, HighPriorityTableID, HighPriorityNo, SourceCode, PriorityTableID)
        then
            DimensionSetID :=
              GetRecDefaultDimID(
                SalesLine, CurrFieldNo, HighPriorityTableID, HighPriorityNo, SourceCode, DimValue1, DimValue2, 0, 0);
    end;

    procedure CreateDimForJobJournalLineWithHigherPriorities(JobJournalLine: Record "Job Journal Line"; CurrFieldNo: Integer; var DimensionSetID: Integer; var DimValue1: Code[20]; var DimValue2: Code[20]; SourceCode: Code[10]; PriorityTableID: Integer)
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        HighPriorityTableID: array[10] of Integer;
        HighPriorityNo: array[10] of Code[20];
    begin
        TableID[1] := DATABASE::Job;
        TableID[2] := TypeToTableID2(JobJournalLine.Type);
        TableID[3] := DATABASE::"Resource Group";
        No[1] := JobJournalLine."Job No.";
        No[2] := JobJournalLine."No.";
        No[3] := JobJournalLine."Resource Group No.";

        OnBeforeGetTableIDsForHigherPriorities(DATABASE::"Job Journal Line", JobJournalLine, CurrFieldNo, TableID, No);
        if GetTableIDsForHigherPriorities(
             TableID, No, HighPriorityTableID, HighPriorityNo, SourceCode, PriorityTableID)
        then
            DimensionSetID :=
              GetRecDefaultDimID(
                JobJournalLine, CurrFieldNo, HighPriorityTableID, HighPriorityNo, SourceCode, DimValue1, DimValue2, 0, 0);
    end;

    local procedure GetTableIDsForHigherPriorities(TableID: array[10] of Integer; No: array[10] of Code[20]; var HighPriorityTableID: array[10] of Integer; var HighPriorityNo: array[10] of Code[20]; SourceCode: Code[10]; PriorityTableID: Integer) Result: Boolean
    var
        DefaultDimensionPriority: Record "Default Dimension Priority";
        InitialPriority: Integer;
        i: Integer;
        j: Integer;
    begin
        Clear(HighPriorityTableID);
        Clear(HighPriorityNo);
        if DefaultDimensionPriority.Get(SourceCode, PriorityTableID) then
            InitialPriority := DefaultDimensionPriority.Priority;
        DefaultDimensionPriority.SetRange("Source Code", SourceCode);
        DefaultDimensionPriority.SetFilter(Priority, '<=%1', InitialPriority);
        i := 1;
        for j := 1 to ArrayLen(TableID) do begin
            if TableID[j] = 0 then
                break;
            DefaultDimensionPriority.Priority := 0;
            DefaultDimensionPriority.SetRange("Table ID", TableID[j]);
            if ((InitialPriority = 0) or DefaultDimensionPriority.FindFirst) and
               ((DefaultDimensionPriority.Priority < InitialPriority) or
                ((DefaultDimensionPriority.Priority = InitialPriority) and (TableID[j] < PriorityTableID)))
            then begin
                Result := true;
                HighPriorityTableID[i] := TableID[j];
                HighPriorityNo[i] := No[j];
                i += 1;
            end;
        end;
        exit(Result);
    end;

    procedure GetDimSetIDsForFilter(DimCode: Code[20]; DimValueFilter: Text)
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        DimSetEntry.SetCurrentKey("Dimension Code", "Dimension Value Code", "Dimension Set ID");
        DimSetEntry.SetFilter("Dimension Code", '%1', DimCode);
        DimSetEntry.SetFilter("Dimension Value Code", DimValueFilter);
        if DimSetEntry.FindSet then
            repeat
                AddDimSetIDtoTempEntry(TempDimSetEntryBuffer, DimSetEntry."Dimension Set ID");
            until DimSetEntry.Next = 0;
        if FilterIncludesBlank(DimCode, DimValueFilter) then
            GetDimSetIDsForBlank(DimCode);
        DimSetFilterCtr += 1;
    end;

    local procedure GetDimSetIDsForBlank(DimCode: Code[20])
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        PrevDimSetID: Integer;
        i: Integer;
    begin
        AddDimSetIDtoTempEntry(TempDimSetEntry, 0);
        for i := 1 to 2 do begin
            if i = 2 then
                DimSetEntry.SetFilter("Dimension Code", '%1', DimCode);
            if DimSetEntry.FindSet then begin
                PrevDimSetID := 0;
                repeat
                    if DimSetEntry."Dimension Set ID" <> PrevDimSetID then begin
                        AddDimSetIDtoTempEntry(TempDimSetEntry, DimSetEntry."Dimension Set ID");
                        PrevDimSetID := DimSetEntry."Dimension Set ID";
                    end;
                until DimSetEntry.Next = 0;
            end;
        end;
        TempDimSetEntry.SetFilter("Dimension Value ID", '%1', 1);
        if TempDimSetEntry.FindSet then
            repeat
                AddDimSetIDtoTempEntry(TempDimSetEntryBuffer, TempDimSetEntry."Dimension Set ID");
            until TempDimSetEntry.Next = 0;
    end;

    procedure GetDimSetFilter() DimSetFilter: Text
    begin
        TempDimSetEntryBuffer.SetFilter("Dimension Value ID", '%1', DimSetFilterCtr);
        if TempDimSetEntryBuffer.FindSet then begin
            DimSetFilter := Format(TempDimSetEntryBuffer."Dimension Set ID");
            if TempDimSetEntryBuffer.Next <> 0 then
                repeat
                    DimSetFilter += '|' + Format(TempDimSetEntryBuffer."Dimension Set ID");
                until TempDimSetEntryBuffer.Next = 0;
        end;
    end;

    local procedure FilterIncludesBlank(DimCode: Code[20]; DimValueFilter: Text): Boolean
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        TempDimSetEntry."Dimension Code" := DimCode;
        TempDimSetEntry.Insert();
        TempDimSetEntry.SetFilter("Dimension Value Code", DimValueFilter);
        exit(not TempDimSetEntry.IsEmpty);
    end;

    local procedure AddDimSetIDtoTempEntry(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimSetID: Integer)
    begin
        if TempDimSetEntry.Get(DimSetID, '') then begin
            TempDimSetEntry."Dimension Value ID" += 1;
            TempDimSetEntry.Modify();
        end else begin
            TempDimSetEntry."Dimension Set ID" := DimSetID;
            TempDimSetEntry."Dimension Value ID" := 1;
            TempDimSetEntry.Insert
        end;
    end;

    procedure ClearDimSetFilter()
    begin
        TempDimSetEntryBuffer.Reset();
        TempDimSetEntryBuffer.DeleteAll();
        DimSetFilterCtr := 0;
    end;

    procedure GetTempDimSetEntry(var TempDimSetEntry: Record "Dimension Set Entry" temporary)
    begin
        TempDimSetEntry.Copy(TempDimSetEntryBuffer, true);
    end;

    local procedure UpdateCostType(DefaultDimension: Record "Default Dimension"; CallingTrigger: Option OnInsert,OnModify,OnDelete)
    var
        GLAcc: Record "G/L Account";
        CostAccSetup: Record "Cost Accounting Setup";
        CostAccMgt: Codeunit "Cost Account Mgt";
    begin
        if CostAccSetup.Get and (DefaultDimension."Table ID" = DATABASE::"G/L Account") then
            if GLAcc.Get(DefaultDimension."No.") then
                CostAccMgt.UpdateCostTypeFromDefaultDimension(DefaultDimension, GLAcc, CallingTrigger);
    end;

    procedure CreateDimSetFromJobTaskDim(JobNo: Code[20]; JobTaskNo: Code[20]; var GlobalDimVal1: Code[20]; var GlobalDimVal2: Code[20]) NewDimSetID: Integer
    var
        JobTaskDimension: Record "Job Task Dimension";
        DimValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        with JobTaskDimension do begin
            SetRange("Job No.", JobNo);
            SetRange("Job Task No.", JobTaskNo);
            if FindSet then begin
                repeat
                    DimValue.Get("Dimension Code", "Dimension Value Code");
                    TempDimSetEntry."Dimension Code" := "Dimension Code";
                    TempDimSetEntry."Dimension Value Code" := "Dimension Value Code";
                    TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
                    TempDimSetEntry.Insert(true);
                until Next = 0;
                NewDimSetID := GetDimensionSetID(TempDimSetEntry);
                UpdateGlobalDimFromDimSetID(NewDimSetID, GlobalDimVal1, GlobalDimVal2);
            end;
        end;
    end;

    procedure UpdateGenJnlLineDim(var GenJnlLine: Record "Gen. Journal Line"; DimSetID: Integer)
    begin
        GenJnlLine."Dimension Set ID" := DimSetID;
        UpdateGlobalDimFromDimSetID(
          GenJnlLine."Dimension Set ID",
          GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code");
    end;

    procedure UpdateGenJnlLineDimFromCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if DtldCustLedgEntry."Cust. Ledger Entry No." <> 0 then begin
            CustLedgEntry.Get(DtldCustLedgEntry."Cust. Ledger Entry No.");
            UpdateGenJnlLineDim(GenJnlLine, CustLedgEntry."Dimension Set ID");
        end;
    end;

    procedure UpdateGenJnlLineDimFromVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if DtldVendLedgEntry."Vendor Ledger Entry No." <> 0 then begin
            VendLedgEntry.Get(DtldVendLedgEntry."Vendor Ledger Entry No.");
            UpdateGenJnlLineDim(GenJnlLine, VendLedgEntry."Dimension Set ID");
        end;
    end;

    procedure GetDimSetEntryDefaultDim(var DimSetEntry: Record "Dimension Set Entry")
    begin
        // Obsolete method
        DimSetEntry.DeleteAll();
    end;

    procedure InsertObject(var TempAllObjWithCaption: Record AllObjWithCaption temporary; TableID: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if IsObsolete(TableID) then
            exit;
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableID) then begin
            TempAllObjWithCaption := AllObjWithCaption;
            if TempAllObjWithCaption.Insert() then;
        end;
    end;

    local procedure IsObsolete(TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableID) then
            exit(TableMetadata.ObsoleteState <> TableMetadata.ObsoleteState::No);
    end;

    procedure GetConsolidatedDimFilterByDimFilter(var Dimension: Record Dimension; DimFilter: Text) ConsolidatedDimFilter: Text
    begin
        Dimension.SetFilter("Consolidation Code", DimFilter);
        ConsolidatedDimFilter += DimFilter;
        if Dimension.FindSet then
            repeat
                ConsolidatedDimFilter += '|' + Dimension.Code;
            until Dimension.Next = 0;
    end;

    procedure ResolveDimValueFilter(var DimValueFilter: Text; DimensionCode: Code[20])
    begin
        DimValueFilter := GetDimValuesWithTotalings(DimValueFilter, DimensionCode);
    end;

    local procedure GetDimValuesWithTotalings(DimValueFilter: Text; DimensionCode: Code[20]) ResultTxt: Text
    var
        FilterChars: Text;
        DimParam: Text;
        CharTxt: Text;
        NextCharTxt: Text;
        SingleQuoteCharTxt: Text;
        DimFilterLen: Integer;
        i: Integer;
    begin
        if DimensionCode = '' then
            exit(DimValueFilter);
        if DimValueFilter = '' then
            exit(DimValueFilter);

        FilterChars := '()|"&@<>=.';
        SingleQuoteCharTxt := '''';
        DimValueFilter := UpperCase(DimValueFilter);
        DimFilterLen := StrLen(DimValueFilter);
        i := 1;
        repeat
            DimParam := '';
            CharTxt := Format(DimValueFilter[i]);

            while (StrPos(FilterChars, CharTxt) > 0) and (i <= DimFilterLen) do begin
                ResultTxt += CharTxt;
                i += 1;
                CharTxt := Format(DimValueFilter[i]);
            end;

            if CharTxt = SingleQuoteCharTxt then begin
                repeat
                    DimParam += CharTxt;
                    i += 1;
                    CharTxt := Format(DimValueFilter[i]);
                    NextCharTxt := Format(DimValueFilter[i + 1]);
                until ((CharTxt = SingleQuoteCharTxt) and (NextCharTxt <> SingleQuoteCharTxt)) or (i > DimFilterLen);
                DimParam += CharTxt;
                i += 1;
            end else
                while (StrPos(FilterChars, CharTxt) = 0) and (i <= DimFilterLen) do begin
                    DimParam += CharTxt;
                    i += 1;
                    CharTxt := Format(DimValueFilter[i]);
                end;

            if DimParam <> '' then
                ResultTxt += ParseDimParam(DimParam, DimensionCode);
        until i > DimFilterLen;
    end;

    local procedure ParseDimParam(DimValueFilter: Text; DimensionCode: Code[20]) ResultTxt: Text
    var
        DimensionValue: Record "Dimension Value";
        TempDimensionValue: Record "Dimension Value" temporary;
        CheckStr: Text;
    begin
        // Possible input values: blank filter, code or code with *
        if DelChr(DimValueFilter) = '' then
            exit(DimValueFilter);

        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetFilter(Code, DimValueFilter);
        DimensionValue.SetFilter(Totaling, '<>%1', '');
        if DimensionValue.IsEmpty then
            exit(DimValueFilter);

        AddTempDimValueFromTotaling(TempDimensionValue, CheckStr, DimensionCode, DimValueFilter);

        if TempDimensionValue.FindSet then
            repeat
                ResultTxt += TempDimensionValue.Code + '|'
            until TempDimensionValue.Next = 0;
        if ResultTxt <> '' then
            ResultTxt := '(' + CopyStr(ResultTxt, 1, StrLen(ResultTxt) - 1) + ')';
    end;

    local procedure AddTempDimValueFromTotaling(var TempDimensionValue: Record "Dimension Value" temporary; var CheckStr: Text; DimensionCode: Code[20]; Totaling: Text)
    var
        DimensionValue: Record "Dimension Value";
    begin
        if StrPos(CheckStr, '(' + Totaling + ')') > 0 then
            exit;
        CheckStr += '(' + Totaling + ')';
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetFilter(Code, Totaling);
        if DimensionValue.FindSet then
            repeat
                if DimensionValue.Totaling <> '' then
                    AddTempDimValueFromTotaling(TempDimensionValue, CheckStr, DimensionCode, DimensionValue.Totaling)
                else begin
                    TempDimensionValue := DimensionValue;
                    if TempDimensionValue.Insert() then;
                end;
            until DimensionValue.Next = 0;
    end;

    procedure UseShortcutDims(var DimVisible1: Boolean; var DimVisible2: Boolean; var DimVisible3: Boolean; var DimVisible4: Boolean; var DimVisible5: Boolean; var DimVisible6: Boolean; var DimVisible7: Boolean; var DimVisible8: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        DimVisible1 := GLSetup."Shortcut Dimension 1 Code" <> '';
        DimVisible2 := GLSetup."Shortcut Dimension 2 Code" <> '';
        DimVisible3 := GLSetup."Shortcut Dimension 3 Code" <> '';
        DimVisible4 := GLSetup."Shortcut Dimension 4 Code" <> '';
        DimVisible5 := GLSetup."Shortcut Dimension 5 Code" <> '';
        DimVisible6 := GLSetup."Shortcut Dimension 6 Code" <> '';
        DimVisible7 := GLSetup."Shortcut Dimension 7 Code" <> '';
        DimVisible8 := GLSetup."Shortcut Dimension 8 Code" <> '';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDimValuePosting(TableID: array[10] of Integer; No: array[10] of Code[20]; var TempDefaultDim: Record "Default Dimension" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertDimtoICDim(FromDim: Code[20]; var ICDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertDimValuetoICDimVal(FromDimCode: Code[20]; FromDimValue: Code[20]; var ICDimValueCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertICDimtoDim(FromICDimCode: Code[20]; var DimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertICDimValuetoDimValue(FromICDimCode: Code[20]; FromICDimValue: Code[20]; var DimValueCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEditDimensionSet2(var DimSetID: Integer; var GlobalDimVal1: Code[20]; var GlobalDimVal2: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecDefaultDimID(RecVariant: Variant; CurrFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20]; var SourceCode: Code[20]; var InheritFromDimSetID: Integer; var InheritFromTableNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20]; var DefaultDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupObjectNoList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDefaultDimObjectNoWithoutGlobalDimsList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceCodeWithVar(TableID: Integer; RecordVar: Variant; var SourceCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimValues(FieldNumber: Integer; var ShortcutDimCode: Code[20]; var DimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDim(DimCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValue(DimCode: Code[20]; DimValCode: Code[20]; var Result: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePosting(TableID: array[10] of Integer; No: array[10] of Code[20]; DimSetID: Integer; var IsChecked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICDim(ICDimCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckICDimValue(ICDimCode: Code[20]; ICDimValCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckValuePosting(TableID: array[10] of Integer; No: array[10] of Code[20]; var TempDimBuf: Record "Dimension Buffer" temporary; var IsChecked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultDimID(var TableID: array[10] of Integer; var No: array[10] of Code[20]; SourceCode: Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20]; InheritFromDimSetID: Integer; InheritFromTableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDimensionSet(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTableIDsForHigherPriorities(TableNo: Integer; RecVar: Variant; var FieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDimValueCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDimValueCodeNoUpdate(FieldNumber: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveDefaultDim(TableID: Integer; No: Code[20]; FieldNumber: Integer; ShortcutDimCode: Code[20]; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupObjectNoList(var TempDimField: Record Field temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDefaultDim(TableID: Integer; No: Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20]; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDimValueCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRecDefaultDimID(RecVariant: Variant; CurrFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20]; var SourceCode: Code[20]; var InheritFromDimSetID: Integer; var InheritFromTableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTypeToTableID2(var TableID: Integer; Type: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDimValueAllowed(DimVal: Record "Dimension Value"; var DimValueAllowed: Boolean; var DimErr: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckICDimValueAllowed(ICDimVal: Record "IC Dimension Value"; var DimValueAllowed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultDimOnBeforeCreate(var TempDimBuf: Record "Dimension Buffer" temporary; TableID: Integer; No: Code[20]; GLSetupShortcutDimCode: array[8] of Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20]; var IsHandled: Boolean; SourceCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultDimIDOnBeforeFindNewDimSetID(var TempDimensionBuffer: Record "Dimension Buffer" temporary; TableID: array[10] of Integer; No: array[10] of Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateJobTaskDimOnBeforConfirm(DefaultDimension: Record "Default Dimension"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultDimIDOnBeforeTempDimSetEntryInsert(var DimensionSetEntry: Record "Dimension Set Entry"; var DimensionBuffer: Record "Dimension Buffer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTypeToTableID1(Type: Integer; var TableId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTypeToTableID3(Type: Integer; var TableId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTypeToTableID4(Type: Integer; var TableId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTypeToTableID5(Type: Integer; var TableId: Integer)
    begin
    end;
}

