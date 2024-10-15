table 324 "VAT Product Posting Group"
{
    Caption = 'VAT Product Posting Group';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "VAT Product Posting Groups";
    LookupPageID = "VAT Product Posting Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
        }
        field(8005; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; Description)
        {
        }
    }

    trigger OnInsert()
    begin
        SetLastModifiedDateTime;
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime;
    end;

    trigger OnRename()
    begin
        SetLastModifiedDateTime;
    end;

    [Scope('OnPrem')]
    procedure LookupVATProductPostingGroupFilter(var FilterString: Text): Boolean
    var
        VATProductPostingGroups: Page "VAT Product Posting Groups";
    begin
        VATProductPostingGroups.LookupMode(true);
        if VATProductPostingGroups.RunModal = ACTION::LookupOK then begin
            FilterString := VATProductPostingGroups.GetSelectionFilter;
            exit(true);
        end;
        exit(false)
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;
}

