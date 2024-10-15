page 5005272 "Delivery Reminder List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Delivery Reminder';
    CardPageID = "Delivery Reminder";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Delivery Reminder Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the delivery reminder header you are setting up.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor who you want to post a delivery reminder for.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the vendor who the delivery reminder is for.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the address.';
                    Visible = false;
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the address.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Reminder")
            {
                Caption = '&Reminder';
                Image = Reminder;
                action("V&endor")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'V&endor';
                    Image = Vendor;
                    RunObject = Page "Vendor List";
                    RunPageLink = "No." = FIELD("Vendor No.");
                    ToolTip = 'View detailed information for the vendor.';
                }
                action("Co&mment")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mment';
                    Image = ViewComments;
                    RunObject = Page "Delivery Reminder Comment Line";
                    RunPageLink = "No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "No.", "Line No.")
                                  WHERE("Document Type" = CONST("Delivery Reminder"));
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(reporting)
        {
            action("Delivery Reminder - Test")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delivery Reminder - Test';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Delivery Reminder - Test";
                ToolTip = 'Preview the delivery reminders before you issue them. The program checks whether there are any posting dates and/or document dates missing, whether there is anything to issue, and so on. ';
            }
        }
    }
}

