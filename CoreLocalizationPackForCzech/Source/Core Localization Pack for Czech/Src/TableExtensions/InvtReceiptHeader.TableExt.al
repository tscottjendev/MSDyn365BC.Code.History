tableextension 31035 "Invt. Receipt Header CZL" extends "Invt. Receipt Header"
{
    fields
    {
        field(11700; "Invt. Movement Template CZL"; Code[10])
        {
            Caption = 'Inventory Movement Template';
            TableRelation = "Invt. Movement Template CZL" where("Entry Type" = const("Positive Adjmt."));
            Editable = false;
            DataClassification = CustomerContent;
        }
    }
}