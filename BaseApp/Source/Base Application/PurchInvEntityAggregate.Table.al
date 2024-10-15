table 5477 "Purch. Inv. Entity Aggregate"
{
    Caption = 'Purch. Inv. Entity Aggregate';

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                UpdateBuyFromVendorId;
            end;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                UpdatePayToVendorId;
            end;
        }
        field(5; "Pay-to Name"; Text[100])
        {
            Caption = 'Pay-to Name';
            DataClassification = CustomerContent;
            TableRelation = Vendor;
            ValidateTableRelation = false;
        }
        field(7; "Pay-to Address"; Text[100])
        {
            Caption = 'Pay-to Address';
            DataClassification = CustomerContent;
        }
        field(8; "Pay-to Address 2"; Text[50])
        {
            Caption = 'Pay-to Address 2';
            DataClassification = CustomerContent;
        }
        field(9; "Pay-to City"; Text[30])
        {
            Caption = 'Pay-to City';
            DataClassification = CustomerContent;
            TableRelation = IF ("Pay-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Pay-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Pay-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(10; "Pay-to Contact"; Text[100])
        {
            Caption = 'Pay-to Contact';
            DataClassification = CustomerContent;
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            DataClassification = CustomerContent;
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            DataClassification = CustomerContent;
        }
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            DataClassification = CustomerContent;
        }
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            DataClassification = CustomerContent;
        }
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            DataClassification = CustomerContent;
        }
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            DataClassification = CustomerContent;
            TableRelation = IF ("Ship-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Ship-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Ship-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
            DataClassification = CustomerContent;
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            DataClassification = CustomerContent;
            TableRelation = "Payment Terms";
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = CustomerContent;
        }
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            DataClassification = CustomerContent;
            TableRelation = "Shipment Method";
        }
        field(31; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Posting Group";
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                UpdateCurrencyId;
            end;
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
            DataClassification = CustomerContent;
        }
        field(43; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            DataClassification = CustomerContent;
            TableRelation = "Salesperson/Purchaser";
        }
        field(44; "Order No."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Order No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UpdateOrderId;
            end;
        }
        field(56; "Recalculate Invoice Disc."; Boolean)
        {
            CalcFormula = Exist ("Purchase Line" WHERE("Document Type" = FIELD("Document Type"),
                                                       "Document No." = FIELD("No."),
                                                       "Recalculate Invoice Disc." = CONST(true)));
            Caption = 'Recalculate Invoice Disc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = CustomerContent;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            DataClassification = CustomerContent;
        }
        field(68; "Vendor Invoice No."; Code[35])
        {
            Caption = 'Vendor Invoice No.';
            DataClassification = CustomerContent;
        }
        field(79; "Buy-from Vendor Name"; Text[100])
        {
            Caption = 'Buy-from Vendor Name';
            DataClassification = CustomerContent;
            TableRelation = Vendor.Name;
            ValidateTableRelation = false;
        }
        field(81; "Buy-from Address"; Text[100])
        {
            Caption = 'Buy-from Address';
            DataClassification = CustomerContent;
        }
        field(82; "Buy-from Address 2"; Text[50])
        {
            Caption = 'Buy-from Address 2';
            DataClassification = CustomerContent;
        }
        field(83; "Buy-from City"; Text[30])
        {
            Caption = 'Buy-from City';
            DataClassification = CustomerContent;
            TableRelation = IF ("Buy-from Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Buy-from Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Buy-from Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(84; "Buy-from Contact"; Text[100])
        {
            Caption = 'Buy-from Contact';
            DataClassification = CustomerContent;
        }
        field(85; "Pay-to Post Code"; Code[20])
        {
            Caption = 'Pay-to Post Code';
            DataClassification = CustomerContent;
            TableRelation = IF ("Pay-to Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Pay-to Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Pay-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(86; "Pay-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Pay-to Country/Region Code";
            Caption = 'Pay-to County';
            DataClassification = CustomerContent;
        }
        field(87; "Pay-to Country/Region Code"; Code[10])
        {
            Caption = 'Pay-to Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(88; "Buy-from Post Code"; Code[20])
        {
            Caption = 'Buy-from Post Code';
            DataClassification = CustomerContent;
            TableRelation = IF ("Buy-from Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Buy-from Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Buy-from Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(89; "Buy-from County"; Text[30])
        {
            CaptionClass = '5,1,' + "Buy-from Country/Region Code";
            Caption = 'Buy-from County';
            DataClassification = CustomerContent;
        }
        field(90; "Buy-from Country/Region Code"; Code[10])
        {
            Caption = 'Buy-from Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            DataClassification = CustomerContent;
            TableRelation = IF ("Ship-to Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Ship-to Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Ship-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
            DataClassification = CustomerContent;
        }
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = SystemMetadata;
        }
        field(1304; "Vendor Ledger Entry No."; Integer)
        {
            Caption = 'Vendor Ledger Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Ledger Entry"."Entry No.";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Invoice Discount Amount';
            DataClassification = CustomerContent;
        }
        field(5052; "Buy-from Contact No."; Code[20])
        {
            Caption = 'Buy-from Contact No.';
            DataClassification = CustomerContent;
            TableRelation = Contact;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(9600; "Total Tax Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Tax Amount';
            DataClassification = CustomerContent;
        }
        field(9601; Status; Option)
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Draft,In Review,Open,Paid,Canceled,Corrective', Locked = true;
            OptionMembers = " ",Draft,"In Review",Open,Paid,Canceled,Corrective;
        }
        field(9602; Posted; Boolean)
        {
            Caption = 'Posted';
            DataClassification = CustomerContent;
        }
        field(9624; "Discount Applied Before Tax"; Boolean)
        {
            Caption = 'Discount Applied Before Tax';
            DataClassification = CustomerContent;
        }
        field(9630; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(9631; "Vendor Id"; Guid)
        {
            Caption = 'Vendor Id';
            DataClassification = SystemMetadata;
            TableRelation = Vendor.Id;

            trigger OnValidate()
            begin
                UpdateBuyFromVendorNo;
            end;
        }
        field(9632; "Order Id"; Guid)
        {
            Caption = 'Order Id';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                UpdateOrderNo;
            end;
        }
        field(9634; "Currency Id"; Guid)
        {
            Caption = 'Currency Id';
            DataClassification = SystemMetadata;
            TableRelation = Currency.Id;

            trigger OnValidate()
            begin
                UpdateCurrencyCode;
            end;
        }
        field(9638; "Pay-to Vendor Id"; Guid)
        {
            Caption = 'Pay-to Vendor Id';
            DataClassification = SystemMetadata;
            TableRelation = Vendor.Id;

            trigger OnValidate()
            begin
                UpdatePayToVendorNo;
            end;
        }
    }

    keys
    {
        key(Key1; "No.", Posted)
        {
            Clustered = true;
        }
        key(Key2; Id)
        {
        }
        key(Key3; "Vendor Ledger Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        UpdateReferencedRecordIds;
    end;

    trigger OnModify()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        UpdateReferencedRecordIds;
    end;

    trigger OnRename()
    begin
        if not Posted then
            Error(CannotChangeNumberOnNonPostedErr);

        if Posted and (not IsRenameAllowed) then
            Error(CannotModifyPostedInvioceErr);

        "Last Modified Date Time" := CurrentDateTime;
        UpdateReferencedRecordIds;
    end;

    var
        CannotChangeNumberOnNonPostedErr: Label 'The number of the invoice can not be changed.';
        CannotModifyPostedInvioceErr: Label 'The invoice has been posted and can no longer be modified.', Locked = true;
        IsRenameAllowed: Boolean;

    local procedure UpdateBuyFromVendorNo()
    var
        Vendor: Record Vendor;
    begin
        if IsNullGuid("Vendor Id") then
            exit;

        Vendor.SetRange(Id, "Vendor Id");
        if not Vendor.FindFirst then
            exit;

        "Buy-from Vendor No." := Vendor."No.";
    end;

    local procedure UpdatePayToVendorNo()
    var
        Vendor: Record Vendor;
    begin
        if IsNullGuid("Pay-to Vendor Id") then
            exit;

        Vendor.SetRange(Id, "Pay-to Vendor Id");
        if not Vendor.FindFirst then
            exit;

        "Pay-to Vendor No." := Vendor."No.";
    end;

    local procedure UpdateBuyFromVendorId()
    var
        Vendor: Record Vendor;
    begin
        if "Buy-from Vendor No." = '' then begin
            Clear("Vendor Id");
            exit;
        end;

        if not Vendor.Get("Buy-from Vendor No.") then
            exit;

        "Vendor Id" := Vendor.Id;
    end;

    local procedure UpdatePayToVendorId()
    var
        Vendor: Record Vendor;
    begin
        if "Pay-to Vendor No." = '' then begin
            Clear("Pay-to Vendor Id");
            exit;
        end;

        if not Vendor.Get("Pay-to Vendor No.") then
            exit;

        "Pay-to Vendor Id" := Vendor.Id;
    end;

    local procedure UpdateOrderNo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if IsNullGuid("Order Id") then
            exit;

        PurchaseHeader.SetRange(Id, "Order Id");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        if not PurchaseHeader.FindFirst then
            exit;

        "Order No." := PurchaseHeader."No.";
    end;

    local procedure UpdateOrderId()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, "Order No.") then
            exit;

        "Order Id" := PurchaseHeader.Id;
    end;

    local procedure UpdateCurrencyCode()
    var
        Currency: Record Currency;
    begin
        if not IsNullGuid("Currency Id") then begin
            Currency.SetRange(Id, "Currency Id");
            Currency.FindFirst;
        end;

        Validate("Currency Code", Currency.Code);
    end;

    procedure UpdateCurrencyId()
    var
        Currency: Record Currency;
    begin
        if "Currency Code" = '' then begin
            Clear("Currency Id");
            exit;
        end;

        if not Currency.Get("Currency Code") then
            exit;

        "Currency Id" := Currency.Id;
    end;

    procedure UpdateReferencedRecordIds()
    begin
        UpdateBuyFromVendorId;
        UpdatePayToVendorId;
        UpdateCurrencyId;

        if ("Order No." <> '') and IsNullGuid("Order Id") then
            UpdateOrderId;
    end;

    procedure GetIsRenameAllowed(): Boolean
    begin
        exit(IsRenameAllowed);
    end;

    procedure SetIsRenameAllowed(RenameAllowed: Boolean)
    begin
        IsRenameAllowed := RenameAllowed;
    end;
}

