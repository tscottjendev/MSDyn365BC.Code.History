codeunit 412 "SMTP Test Mail"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Use "Email Test Mail" codeunit from "System Application" to send out test emails.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        Mail: Codeunit Mail;
        AddressChoice: Text;
        ChosenAddress: Option ,ADMail,BasicAuthMail,UserTableMail,OtherMail;
        Address: Text;
    begin
        Mail.CollectCurrentUserEmailAddresses(TempNameValueBuffer);
        TempNameValueBuffer.Reset();
        if TempNameValueBuffer.FindSet then
            repeat
                if AddressChoice <> '' then
                    AddressChoice := AddressChoice + ',';
                AddressChoice := AddressChoice + TempNameValueBuffer.Value;
            until TempNameValueBuffer.Next = 0;

        AddressChoice := StrSubstNo('%1,%2', AddressChoice, TestMailOtherTxt);

        if AddressChoice = ',' + TestMailOtherTxt then
            PromptAndSendEmail
        else begin
            ChosenAddress := StrMenu(AddressChoice, TempNameValueBuffer.Count + 1, TestMailChoiceTxt);
            if ChosenAddress = 0 then
                exit;
            if ChosenAddress < TempNameValueBuffer.Count + 1 then begin
                Address := SelectStr(ChosenAddress, AddressChoice);
                if SendTestMail(Address) then
                    Message(TestMailSuccessMsg, Address);
            end else
                PromptAndSendEmail;
        end;
    end;

    var
        TestMailChoiceTxt: Label 'Choose the email address that should receive a test email message:';
        TestMailTitleTxt: Label 'SMTP Test Email Message';
        TestMailBodyTxt: Label '<p style="font-family:Verdana,Arial;font-size:10pt"><b>This mail message has been generated by the user %1 for test purposes.</b></p><p style="font-family:Verdana,Arial;font-size:9pt"><b>Sent through SMTP Server:</b> %2<BR><b>SMTP Port:</b> %3<BR><b>Authentication:</b> %4<BR><b>Using Secure Connection:</b> %5<BR><b>Server Instance ID:</b> %6<BR><b>Tenant ID:</b> %7</p>', Comment = '{Locked="p style=","font-family:","font-size","pt","<b>","</b>","</p>","<BR>","SMTP"} %1 is an email address, such as user@domain.com; %2 is the name of a mail server, such as mail.live.com; %3 is the TCP port number, such as 25; %4 is the authentication method, such as Basic Authentication; %5 is a boolean value, such as True; %6 is a numeric ID such as 12; %7 is the name identifier of a tenant instance, such as ''MyTenant1'';';
        TestMailSuccessMsg: Label 'Test email has been sent to %1.\Check your email for messages to make sure that the email was delivered successfully.', Comment = '%1 is an email address.';
        TestMailOtherTxt: Label 'Other...';

    [TryFunction]
    [Scope('OnPrem')]
    procedure SendTestMail(EmailAddress: Text)
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        SMTPMail: Codeunit "SMTP Mail";
        MailManagement: Codeunit "Mail Management";
        SendToList: List of [Text];
        SenderEmail: Text;
    begin
        SMTPMailSetup.GetSetup;

        MailManagement.RecipientStringToList(EmailAddress, SendToList);

        if SMTPMailSetup.Authentication = SMTPMailSetup.Authentication::Anonymous then
            SenderEmail := EmailAddress
        else
            SenderEmail := MailManagement.GetSenderEmailAddress;

        SMTPMail.CreateMessage(
          '',
          SenderEmail,
          SendToList,
          TestMailTitleTxt,
          StrSubstNo(
            TestMailBodyTxt,
            UserId,
            SMTPMailSetup."SMTP Server",
            Format(SMTPMailSetup."SMTP Server Port"),
            SMTPMailSetup.Authentication,
            SMTPMailSetup."Secure Connection",
            ServiceInstanceId,
            TenantId),
            true);

        SMTPMail.SendShowError();
    end;

    local procedure PromptAndSendEmail()
    var
        SMTPUserSpecifiedAddress: Page "SMTP User-Specified Address";
        Address: Text;
    begin
        if SMTPUserSpecifiedAddress.RunModal = ACTION::OK then begin
            Address := SMTPUserSpecifiedAddress.GetEmailAddress;
            if Address = '' then
                exit;
            SendTestMail(Address);
            Message(TestMailSuccessMsg, Address);
        end;
    end;
}
