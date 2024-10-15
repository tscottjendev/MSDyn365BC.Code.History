codeunit 315 "Sales Inv.-Printed"
{
    Permissions = TableData "Sales Invoice Header" = rimd;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec, SuppressCommit);
        Find;
        "No. Printed" := "No. Printed" + 1;
        OnBeforeModify(Rec);
        Modify;
        if not SuppressCommit then
            Commit();
    end;

    var
        SuppressCommit: Boolean;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SuppressCommit: Boolean)
    begin
    end;
}

