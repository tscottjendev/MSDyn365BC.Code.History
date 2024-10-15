page 5958 "Standard Service Codes"
{
    ApplicationArea = Service;
    Caption = 'Standard Service Codes';
    CardPageID = "Standard Service Code Card";
    Editable = false;
    PageType = List;
    SourceTable = "Standard Service Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a standard service code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service the standard service code represents.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the currency on the standard service lines linked to the standard service code.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

