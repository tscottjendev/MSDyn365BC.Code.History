// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 1461 "SignedXml Impl."
{
    Access = Internal;

    var
        DotNetAsymmetricAlgorithm: DotNet AsymmetricAlgorithm;
        DotNetKeyInfo: DotNet KeyInfo;
        DotNetReference: DotNet Reference;
        DotNetSignedXml: DotNet SignedXml;


    #region Constructors
    procedure InitializeSignedXml(SigningXmlDocument: XmlDocument)
    var
        XmlDotNetConvert: Codeunit "Xml DotNet Convert";
        DotNetXmlDocument: DotNet XmlDocument;
    begin
        XmlDotNetConvert.ToDotNet(SigningXmlDocument, DotNetXmlDocument);
        DotNetSignedXml := DotNetSignedXml.SignedXml(DotNetXmlDocument);
    end;

    procedure InitializeSignedXml(SigningXmlElement: XmlElement)
    var
        XmlDotNetConvert: Codeunit "Xml DotNet Convert";
        DotNetXmlElement: DotNet XmlElement;
    begin
        XmlDotNetConvert.ToDotNet(SigningXmlElement, DotNetXmlElement);
        DotNetSignedXml := DotNetSignedXml.SignedXml(DotNetXmlElement);
    end;
    #endregion

    #region Reference
    procedure InitializeReference(Uri: Text)
    begin
        DotNetReference := DotNetReference.Reference(Uri);
    end;

    procedure SetDigestMethod(DigestMethod: Text)
    begin
        DotNetReference.DigestMethod := DigestMethod;
    end;

    procedure AddXmlDsigExcC14NTransformToReference(InclusiveNamespacesPrefixList: Text)
    var
        DotNetXmlDsigExcC14NTransform: DotNet XmlDsigExcC14NTransform;
    begin
        DotNetXmlDsigExcC14NTransform := DotNetXmlDsigExcC14NTransform.XmlDsigExcC14NTransform(InclusiveNamespacesPrefixList);
        DotNetReference.AddTransform(DotNetXmlDsigExcC14NTransform);
    end;

    procedure AddXmlDsigExcC14NTransformToReference()
    var
        DotNetXmlDsigExcC14NTransform: DotNet XmlDsigExcC14NTransform;
    begin
        DotNetXmlDsigExcC14NTransform := DotNetXmlDsigExcC14NTransform.XmlDsigExcC14NTransform();
        DotNetReference.AddTransform(DotNetXmlDsigExcC14NTransform);
    end;

    procedure AddXmlDsigEnvelopedSignatureTransform()
    var
        DotNetXmlDsigEnvelopedSignatureTransform: DotNet XmlDsigEnvelopedSignatureTransform;
    begin
        DotNetXmlDsigEnvelopedSignatureTransform := DotNetXmlDsigEnvelopedSignatureTransform.XmlDsigEnvelopedSignatureTransform();
        DotNetReference.AddTransform(DotNetXmlDsigEnvelopedSignatureTransform);
    end;
    #endregion

    #region SignedInfo
    procedure SetCanonicalizationMethod(CanonicalizationMethod: Text)
    begin
        DotNetSignedXml.SignedInfo.CanonicalizationMethod := CanonicalizationMethod;
    end;

    procedure SetXmlDsigExcC14NTransformAsCanonicalizationMethod(InclusiveNamespacesPrefixList: Text)
    var
        DotNetXmlDsigExcC14NTransform: DotNet XmlDsigExcC14NTransform;
    begin
        SetCanonicalizationMethod(GetXmlDsigExcC14NTransformUrl());
        DotNetXmlDsigExcC14NTransform := DotNetSignedXml.SignedInfo.CanonicalizationMethodObject;
        DotNetXmlDsigExcC14NTransform.InclusiveNamespacesPrefixList := InclusiveNamespacesPrefixList;
    end;

    procedure SetSignatureMethod(SignatureMethod: Text)
    begin
        DotNetSignedXml.SignedInfo.SignatureMethod := SignatureMethod;
    end;
    #endregion

    #region KeyInfo
    procedure InitializeKeyInfo()
    begin
        DotNetKeyInfo := DotNetKeyInfo.KeyInfo();
    end;

    procedure AddClause(KeyInfoNodeXmlElement: XmlElement)
    var
        XmlDotNetConvert: Codeunit "Xml DotNet Convert";
        DotNetKeyInfoNode: DotNet KeyInfoNode;
        DotNetXmlElement: DotNet XmlElement;
    begin
        XmlDotNetConvert.ToDotNet(KeyInfoNodeXmlElement, DotNetXmlElement);
        DotNetKeyInfoNode := DotNetKeyInfoNode.KeyInfoNode(DotNetXmlElement);
        AddClause(DotNetKeyInfoNode);
    end;

    local procedure AddClause(DotNetKeyInfoClause: DotNet KeyInfoClause)
    begin
        DotNetKeyInfo.AddClause(DotNetKeyInfoClause);
    end;
    #endregion

    procedure SetSigningKey(var SignatureKey: Record "Signature Key")
    begin
        if SignatureKey.TryGetInstance(DotNetAsymmetricAlgorithm) then
            DotNetSignedXml.SigningKey := DotNetAsymmetricAlgorithm;
    end;

    procedure ComputeSignature()
    begin
        if not IsNull(DotNetReference) then
            DotNetSignedXml.AddReference(DotNetReference);
        if not IsNull(DotNetKeyInfo) then
            DotNetSignedXml.KeyInfo := DotNetKeyInfo;
        DotNetSignedXml.ComputeSignature();
    end;

    procedure GetXml() SignedXmlElement: XmlElement
    var
        XmlDotNetConvert: Codeunit "Xml DotNet Convert";
    begin
        XmlDotNetConvert.FromDotNet(DotNetSignedXml.GetXml(), SignedXmlElement);
    end;

    #region Static Fields
    procedure GetXmlDsigDSAUrl(): Text[250]
    var
        XmlDsigDSAUrlTok: Label 'XmlDsigDSAUrl', Locked = true;
    begin
        exit(GetFieldValue(XmlDsigDSAUrlTok));
    end;

    procedure GetXmlDsigExcC14NTransformUrl(): Text[250]
    var
        XmlDsigExcC14NTransformUrlTok: Label 'XmlDsigExcC14NTransformUrl', Locked = true;
    begin
        exit(GetFieldValue(XmlDsigExcC14NTransformUrlTok));
    end;

    procedure GetXmlDsigHMACSHA1Url(): Text[250]
    var
        XmlDsigHMACSHA1UrlTok: Label 'XmlDsigHMACSHA1Url', Locked = true;
    begin
        exit(GetFieldValue(XmlDsigHMACSHA1UrlTok));
    end;

    procedure GetXmlDsigRSASHA1Url(): Text[250]
    var
        XmlDsigRSASHA1UrlTok: Label 'XmlDsigRSASHA1Url', Locked = true;
    begin
        exit(GetFieldValue(XmlDsigRSASHA1UrlTok));
    end;

    procedure GetXmlDsigRSASHA256Url(): Text[250]
    var
        XmlDsigRSASHA256UrlTok: Label 'XmlDsigRSASHA256Url', Locked = true;
    begin
        exit(GetFieldValue(XmlDsigRSASHA256UrlTok));
    end;

    procedure GetXmlDsigRSASHA384Url(): Text[250]
    var
        XmlDsigRSASHA384UrlTok: Label 'XmlDsigRSASHA384Url', Locked = true;
    begin
        exit(GetFieldValue(XmlDsigRSASHA384UrlTok));
    end;

    procedure GetXmlDsigRSASHA512Url(): Text[250]
    var
        XmlDsigRSASHA512UrlTok: Label 'XmlDsigRSASHA512Url', Locked = true;
    begin
        exit(GetFieldValue(XmlDsigRSASHA512UrlTok));
    end;

    procedure GetXmlDsigSHA1Url(): Text[250]
    var
        XmlDsigSHA1UrlTok: Label 'XmlDsigSHA1Url', Locked = true;
    begin
        exit(GetFieldValue(XmlDsigSHA1UrlTok));
    end;

    procedure GetXmlDsigSHA256Url(): Text[250]
    var
        XmlDsigSHA256UrlTok: Label 'XmlDsigSHA256Url', Locked = true;
    begin
        exit(GetFieldValue(XmlDsigSHA256UrlTok));
    end;

    procedure GetXmlDsigSHA384Url(): Text[250]
    var
        XmlDsigSHA384UrlTok: Label 'XmlDsigSHA384Url', Locked = true;
    begin
        exit(GetFieldValue(XmlDsigSHA384UrlTok));
    end;

    procedure GetXmlDsigSHA512Url(): Text[250]
    var
        XmlDsigSHA512UrlTok: Label 'XmlDsigSHA512Url', Locked = true;
    begin
        exit(GetFieldValue(XmlDsigSHA512UrlTok));
    end;
    #endregion

    local procedure GetFieldValue(FieldName: Text): Text[250]
    var
        SignedXmlType: DotNet Type;
    begin
        SignedXmlType := GetDotNetType(DotNetSignedXml);
        exit(CopyStr(SignedXmlType.GetField(FieldName).GetValue(GetDotNetType(DotNetSignedXml)), 1, 250));
    end;
}