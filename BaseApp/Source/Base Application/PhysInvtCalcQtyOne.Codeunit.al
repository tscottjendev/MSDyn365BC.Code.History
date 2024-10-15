codeunit 5888 "Phys. Invt.-Calc. Qty. One"
{
    TableNo = "Phys. Invt. Order Line";

    trigger OnRun()
    begin
        PhysInvtOrderLine.Get("Document No.", "Line No.");

        if not Confirm(
             StrSubstNo(ConfirmCalculationQst, FieldCaption("Qty. Expected (Base)")), false)
        then
            exit;

        if not PhysInvtOrderLine.EmptyLine then begin
            PhysInvtOrderLine.TestField("Item No.");
            PhysInvtOrderLine.CalcQtyAndTrackLinesExpected;
            PhysInvtOrderLine.Modify;
        end;

        Rec := PhysInvtOrderLine;
    end;

    var
        ConfirmCalculationQst: Label 'Do you want to calculate %1 for this line?', Comment = '%1 = field caption';
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
}

