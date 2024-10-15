page 7306 "Bin Types"
{
    ApplicationArea = Warehouse;
    Caption = 'Bin Types';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Bin Type";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a unique code for the bin type.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the bin type.';
                }
                field(Receive; Receive)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies to use the bin for items that have just arrived at the warehouse.';
                }
                field(Ship; Ship)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies to use the bin for items that are about to be shipped out of the warehouse.';
                }
                field("Put Away"; "Put Away")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies to use the bin for items that are being put away, such as receipts and internal put-always.';
                }
                field(Pick; Pick)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies to use the bin for items that can be picked for shipment, internal picks, and production.';
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

