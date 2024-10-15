page 386 "Extended Text"
{
    Caption = 'Extended Text';
    DataCaptionExpression = GetCaption;
    PageType = ListPlus;
    PopulateAllFields = true;
    SourceTable = "Extended Text Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field("All Language Codes"; "All Language Codes")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text should be used for all language codes. If a language code has been chosen in the Language Code field, it will be overruled by this function.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the content of the extended item description.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a date from which the text will be used on the item, account, resource or standard text.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a date on which the text will no longer be used on the item, account, resource or standard text.';
                }
            }
            part(Control25; "Extended Text Lines")
            {
                ApplicationArea = Suite;
                SubPageLink = "Table Name" = FIELD("Table Name"),
                              "No." = FIELD("No."),
                              "Language Code" = FIELD("Language Code"),
                              "Text No." = FIELD("Text No.");
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Sales Quote"; "Sales Quote")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the text will be available on sales quotes.';
                }
                field("Sales Blanket Order"; "Sales Blanket Order")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the text will be available on sales blanket orders.';
                }
                field("Sales Order"; "Sales Order")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the text will be available on sales orders.';
                }
                field("Sales Invoice"; "Sales Invoice")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on sales invoices.';
                }
                field("Sales Return Order"; "Sales Return Order")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the text will be available on sales return orders.';
                }
                field("Sales Credit Memo"; "Sales Credit Memo")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on sales credit memos.';
                }
                field(Reminder; Reminder)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the extended text will be available on reminders.';
                }
                field("Finance Charge Memo"; "Finance Charge Memo")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the extended text will be available on finance charge memos.';
                }
                field("Prepmt. Sales Invoice"; "Prepmt. Sales Invoice")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the text will be available on prepayment sales invoices.';
                }
                field("Prepmt. Sales Credit Memo"; "Prepmt. Sales Credit Memo")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the text will be available on prepayment sales credit memos.';
                }
            }
            group(Purchases)
            {
                Caption = 'Purchases';
                field("Purchase Quote"; "Purchase Quote")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase quotes.';
                }
                field("Purchase Blanket Order"; "Purchase Blanket Order")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase blanket orders.';
                }
                field("Purchase Order"; "Purchase Order")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase orders.';
                }
                field("Purchase Invoice"; "Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase invoices.';
                }
                field("Purchase Return Order"; "Purchase Return Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase return orders.';
                }
                field("Purchase Credit Memo"; "Purchase Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on purchase credit memos.';
                }
                field("Prepmt. Purchase Invoice"; "Prepmt. Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on prepayment purchase invoices.';
                }
                field("Prepmt. Purchase Credit Memo"; "Prepmt. Purchase Credit Memo")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the text will be available on prepayment purchase credit memos.';
                }
                field("Delivery Reminder"; "Delivery Reminder")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the extended text will be available on delivery reminders.';
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field("Service Quote"; "Service Quote")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the extended text for an item, account or other factor will be available on service lines in service orders.';
                }
                field("Service Order"; "Service Order")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the extended text for an item, account or other factor will be available on service lines in service orders.';
                }
                field("Service Invoice"; "Service Invoice")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the extended text for an item, account or other factor will be available on service lines in service orders.';
                }
                field("Service Credit Memo"; "Service Credit Memo")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the extended text for an item, account or other factor will be available on service lines in service orders.';
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

