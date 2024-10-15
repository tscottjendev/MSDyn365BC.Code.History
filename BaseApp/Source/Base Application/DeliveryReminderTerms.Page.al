page 5005279 "Delivery Reminder Terms"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Delivery Reminder Terms';
    PageType = List;
    SourceTable = "Delivery Reminder Term";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code to identify this set of delivery reminder terms.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the delivery reminder terms.';
                }
                field("Max. No. of Delivery Reminders"; "Max. No. of Delivery Reminders")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum number of delivery reminders that can be created for an order.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Levels")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Levels';
                Image = ReminderTerms;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Delivery Reminder Levels";
                RunPageLink = "Reminder Terms Code" = FIELD(Code);
                ToolTip = 'View the reminder levels that are used to define when reminders can be created and what charges and texts they must include.';
            }
        }
    }
}

