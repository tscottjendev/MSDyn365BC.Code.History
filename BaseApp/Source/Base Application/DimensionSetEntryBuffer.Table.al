table 5489 "Dimension Set Entry Buffer"
{
    Caption = 'Dimension Set Entry Buffer';
    ReplicateData = false;

    fields
    {
        field(1; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = Dimension;
        }
        field(3; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = "Dimension Value".Code WHERE("Dimension Code" = FIELD("Dimension Code"));
        }
        field(4; "Dimension Value ID"; Integer)
        {
            Caption = 'Dimension Value ID';
            DataClassification = SystemMetadata;
        }
        field(5; "Dimension Name"; Text[30])
        {
            CalcFormula = Lookup (Dimension.Name WHERE(Code = FIELD("Dimension Code")));
            Caption = 'Dimension Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Dimension Value Name"; Text[50])
        {
            CalcFormula = Lookup ("Dimension Value".Name WHERE("Dimension Code" = FIELD("Dimension Code"),
                                                               Code = FIELD("Dimension Value Code")));
            Caption = 'Dimension Value Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8000; "Dimension Id"; Guid)
        {
            Caption = 'Dimension Id';
            DataClassification = SystemMetadata;
        }
        field(8001; "Value Id"; Guid)
        {
            Caption = 'Value Id';
            DataClassification = SystemMetadata;
        }
        field(8002; "Parent Id"; Guid)
        {
            Caption = 'Parent Id';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Parent Id", "Dimension Id")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        UpdateIntegrationIds;
    end;

    trigger OnInsert()
    begin
        UpdateIntegrationIds;
    end;

    trigger OnModify()
    begin
        UpdateIntegrationIds;
    end;

    trigger OnRename()
    begin
        UpdateIntegrationIds;
    end;

    var
        IdOrCodeShouldBeFilledErr: Label 'The ID or Code field must be filled in.', Locked = true;
        ValueIdOrValueCodeShouldBeFilledErr: Label 'The valueID or valueCode field must be filled in.', Locked = true;

    local procedure UpdateIntegrationIds()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        if IsNullGuid("Dimension Id") then begin
            if "Dimension Code" = '' then
                Error(IdOrCodeShouldBeFilledErr);
            Dimension.Get("Dimension Code");
            "Dimension Id" := Dimension.Id;
        end;

        if IsNullGuid("Value Id") then begin
            if "Dimension Value Code" = '' then
                Error(ValueIdOrValueCodeShouldBeFilledErr);
            DimensionValue.Get("Dimension Code", "Dimension Value Code");
            "Value Id" := DimensionValue.Id;
        end;
    end;
}

