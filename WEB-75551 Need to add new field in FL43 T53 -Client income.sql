--File:Tables:dbo:StagingClientFlat:ALTER
/*WEB-75551**RC**START*/
GO
ALTER TABLE dbo.StagingClientFlat
ADD IncomeGroup	 VARCHAR(100),
	Income VARCHAR(100),
	Networth VARCHAR(100),
	FromDate VARCHAR(25)
GO
/*WEB-75551**RC**END*/


--File:Tables:dbo:StagingClientIncomeDetails:CREATE
/*WEB-75551**RC**START*/
GO
CREATE TABLE dbo.StagingClientIncomeDetails(
	StagingClientIncomeDetailsId INT IDENTITY(1,1) NOT NULL,
	StagingClientDetailId INT,
	[GUID]   VARCHAR(100) NOT NULL,
	ReferenceNumber INT NOT NULL,
	IncomeGroup	 VARCHAR(100),
	Income VARCHAR(100),
	Networth VARCHAR(100),
	FromDate VARCHAR(25),
	AddedBy VARCHAR(50) NOT NULL,
	AddedOn DATETIME NOT NULL

)

ALTER TABLE dbo.StagingClientIncomeDetails
ADD CONSTRAINT [PK_StagingClientIncomeDetails] PRIMARY KEY (StagingClientIncomeDetailsId);

ALTER TABLE dbo.StagingClientIncomeDetails  ADD  CONSTRAINT [FK_StagingClientIncomeDetails_StagingClientDetailId] FOREIGN KEY(StagingClientDetailId)
REFERENCES dbo.StagingClientDetail (StagingClientDetailId);
GO
/*WEB-75551**RC**END*/

--File:StoredProcedures:dbo:StagingClientIncomeDetails_InsertFromStagingClientFlat
/*WEB-75551**RC**START*/
GO
ALTER PROCEDURE [dbo].[StagingClientIncomeDetails_InsertFromStagingClientFlat]
(
	@AddedBy VARCHAR(100),
	@CurrentDate DATETIME
)
AS
BEGIN
	 INSERT INTO dbo.StagingClientIncomeDetails
	 ( 
	    StagingClientDetailId
	   ,[GUID]
	   ,ReferenceNumber
	   ,IncomeGroup
	   ,Income
	   ,Networth
	   ,FromDate
	   ,AddedBy
	   ,AddedOn
	 )
	SELECT 
		cd.StagingClientDetailId
		,cd.[GUID]
		,cd.ReferenceNumber
        ,cf.IncomeGroup
		,cf.Income
		,cf.Networth
		,cf.FromDate
		,@AddedBy
		,@CurrentDate
	FROM #StagingClientDetail cd
	INNER JOIN dbo.StagingClientFlat cf on cd.[GUID] = cf.[GUID] AND cd.ReferenceNumber = cf.ReferenceNumber
END
GO
/*WEB-75551**RC**END*/

--File:StoredProcedures:dbo:StagingClientDetail_InsertFromStagingClientFlat
/*WEB-75551**RC**START*/
GO
ALTER PROCEDURE dbo.StagingClientDetail_InsertFromStagingClientFlat
( 
    @Guid varchar(50),
	@UserName VARCHAR(100)  
)
AS  
BEGIN  
 
 DECLARE @InternalGuid VARCHAR(50),@InternalUserName VARCHAR(100), @CurrentDate DATETIME
 SET @InternalGuid =  @Guid
 SET @InternalUserName = @UserName
 SET @CurrentDate = GETDATE()

 CREATE TABLE #StagingClientDetail
 (
	StagingClientDetailId INT,
	GUID VARCHAR(50) COLLATE DATABASE_DEFAULT,
	TransactionId VARCHAR(400) COLLATE DATABASE_DEFAULT,
	ReferenceNumber INT
 )

 INSERT INTO dbo.StagingClientDetail
 (
   [GUID],
   TransactionId,
   ReferenceNumber,
   ParentCompany,
   ProductAccountType,
   ProductAccountNumber,
   ApplicationNumber,
   ProductAccountOpeningDate,
   ProductAccountStatus,
   ProductAccountStatusEffectiveDate,
   ProductAccountStatusDescription,
   ProductAccountReasonCodeDescription,
   Remarks,
   Channel,
   IntermediaryCode,
   IntroducerEmployeeCode,
   Currency,
   ProductApplicationDate,
   ApplicationSignedDate,
   RiskCommencementDate,
   FirstPremiumReceiptDate,
   LoginDate,
   UnderwritingDate,
   BranchReceiptDate,
   InsurancePurpose,
   SumAssured,
   GrossAnnualPremiumwithTax,
   GrossAnnualPremiumwithoutTax,
   ModalPremium,
   PolicyType,
   PolicyTerm,
   PayTerm,
   PolicyEndDate,
   NatureofCredit,
   LendingArrangement,
   DebtSubtype,
   CoreFileProcessLogId,
   AddedBy,
   AddedOn,
   AccountSegment,
   AccountSegmentEffectiveDate,
   AccountRisk,
   AccountRiskEffectiveDate,
   AccountRiskNextReviewDate,
   PreferredTransactionMode,
   DPID,
   ClientStatus,
   IncomeMultiplier,
   NetworthMultiplier,
   SecondHolderFirstname,
   SecondHolderMiddlename,
   SecondHolderLastname,
   SecondHolderPan,
   ThirdHolderFirstname,
   ThirdHolderMiddlename,
   ThirdHolderLastname,
   ThirdHolderPan,
   IsWhiteListed,
   IsFamilyDeclaration,
   RBIAssetClassification,
   SanctionReferenceNumber,
   RBISMACategory,
   LoanSecured
 ) OUTPUT INSERTED.StagingClientDetailId,INSERTED.GUID, INSERTED.TransactionId, INSERTED.ReferenceNumber INTO #StagingClientDetail
 SELECT 
	@InternalGuid,
     CASE WHEN sc.TransactionId IS NULL OR sc.TransactionId = '' THEN CAST(sc.StagingClientFlatId AS VARCHAR(400)) ELSE sc.TransactionId END,
	 ReferenceNumber,
	 ParentCompany,
	 ProductAccountType,
	 ProductAccountNumber,
	 ApplicationNumber,
	 ProductAccountOpeningDate,
	 ProductAccountStatus,
	 ProductAccountStatusEffectiveDate,
	 ProductAccountStatusDescription,
	 ProductAccountReasonCodeDescription,
	 Remarks,
	 Channel,
	 IntermediaryCode,
	 IntroducerEmployeeCode,
	 Currency,
	 ProductApplicationDate,
	 ApplicationSignedDate,
	 RiskCommencementDate,
	 FirstPremiumReceiptDate,
	 LoginDate,
	 UnderwritingDate,
	 BranchReceiptDate,
	 InsurancePurpose,
	 SumAssured,
	 GrossAnnualPremiumwithTax,
	 GrossAnnualPremiumwithoutTax,
	 ModalPremium,
	 PolicyType,
	 PolicyTerm,
	 PayTerm,
	 PolicyEndDate,
	 NatureofCredit,
	 LendingArrangement,
	 DebtSubtype,
	 CoreFileProcessLogId,
	 @InternalUserName,
	 @CurrentDate,
	 AccountSegment,
	 AccountSegmentEffectiveDate,
	 AccountRisk,
	 AccountRiskEffectiveDate,
	 AccountRiskNextReviewDate,
	 PreferredTransactionMode,
	 DPID,
     ClientStatus,
     IncomeMultiplier,
     NetworthMultiplier,
     SecondHolderFirstname,
     SecondHolderMiddlename,
     SecondHolderLastname,
     SecondHolderPan,
     ThirdHolderFirstname,
     ThirdHolderMiddlename,
     ThirdHolderLastname,
     ThirdHolderPan,
     IsWhiteListed,
     IsFamilyDeclaration,
	 RBIAssetClassification,
	 SanctionReferenceNumber,
	 RBISMACategory,
	 LoanSecured
 FROM dbo.StagingClientFlat sc
 WHERE sc.GUID = @InternalGuid

	EXEC dbo.StagingClientProductDetail_InsertFromStagingClientFlat @AddedBy=@InternalUserName,@CurrentDate=@CurrentDate
	EXEC dbo.StagingClientTagDetail_InsertFromStagingClientFlat @AddedBy=@InternalUserName,@CurrentDate=@CurrentDate
	EXEC dbo.StagingClientBankDetail_InsertFromStagingClientFlat @AddedBy=@InternalUserName,@CurrentDate=@CurrentDate
	EXEC dbo.StagingClientLoanDetail_InsertFromStagingClientFlat @AddedBy=@InternalUserName,@CurrentDate=@CurrentDate
	EXEC dbo.StagingClientAccountStatusReasonCodeDetail_InsertFromStagingClientFlat @AddedBy=@InternalUserName,@CurrentDate=@CurrentDate
	EXEC dbo.StagingClientModuleDetail_InsertFromStagingClientFlat @AddedBy=@InternalUserName,@CurrentDate=@CurrentDate
	EXEC dbo.StagingClientRelationshipManager_InsertFromStagingClientFlat @AddedBy=@InternalUserName,@CurrentDate=@CurrentDate
	EXEC dbo.StagingClientRelationDetail_InsertFromStagingClientFlat @AddedBy=@InternalUserName,@CurrentDate=@CurrentDate
	EXEC dbo.StagingClientProductCommunicationDetails_InsertFromStagingClientFlat @AddedBy=@InternalUserName,@CurrentDate=@CurrentDate
	EXEC dbo.StagingClientIncomeDetails_InsertFromStagingClientFlat @AddedBy=@InternalUserName,@CurrentDate=@CurrentDate

	SELECT COUNT(StagingClientFlatId) AS RecordCount 
	FROM dbo.StagingClientFlat 
	WHERE  GUID = @Guid
END
GO
/*WEB-75551**RC**END*/

--File:StoredProcedures:dbo:StagingClientDetail_GetDataByGuid
/*WEB-75551**RC**START*/
GO
ALTER PROCEDURE dbo.StagingClientDetail_GetDataByGuid
(
	@Guid VARCHAR(200)
)
AS
BEGIN
	DECLARE @InternalGuid VARCHAR(200)

	SET @InternalGuid = @Guid

	SELECT
	   StagingClientDetailId,
	   [GUID],
	   ReferenceNumber,
	   TransactionId,
	   ParentCompany,
	   ProductAccountType,
	   ProductAccountNumber,
	   ApplicationNumber,
	   ProductAccountOpeningDate,
	   ProductAccountStatus,
	   ProductAccountStatusEffectiveDate,
	   ProductAccountStatusDescription,
	   ProductAccountReasonCodeDescription,
	   Remarks,
	   Channel,
	   IntermediaryCode,
	   IntroducerEmployeeCode,
	   Currency,
	   ProductApplicationDate,
	   ApplicationSignedDate,
	   RiskCommencementDate,
	   FirstPremiumReceiptDate,
	   LoginDate,
	   UnderwritingDate,
	   BranchReceiptDate,
	   InsurancePurpose,
	   SumAssured,
	   GrossAnnualPremiumwithTax,
	   GrossAnnualPremiumwithoutTax,
	   ModalPremium,
	   PolicyType,
	   PolicyTerm,
	   PayTerm,
	   PolicyEndDate,
	   NatureofCredit,
	   LendingArrangement,
	   DebtSubtype,
	   CoreFileProcessLogId,
	   AccountSegment,
	   AccountSegmentEffectiveDate,
	   AccountRisk,
	   AccountRiskEffectiveDate,
	   AccountRiskNextReviewDate,
	   PreferredTransactionMode,
	   DPID,
	   ClientStatus,
	   IncomeMultiplier,
	   NetworthMultiplier,
	   SecondHolderFirstname,
	   SecondHolderMiddlename,
	   SecondHolderLastname,
	   SecondHolderPan,
	   ThirdHolderFirstname,
	   ThirdHolderMiddlename,
	   ThirdHolderLastname,
	   ThirdHolderPan,
	   IsWhiteListed,
	   IsFamilyDeclaration,
	 RBIAssetClassification,
	 SanctionReferenceNumber,
	 RBISMACategory,
	 LoanSecured
	FROM dbo.StagingClientDetail WHERE [Guid] = @InternalGuid

	SELECT
	  StagingClientRelationDetailId,
	  StagingClientDetailId,
	  [GUID],
	  ReferenceNumber,
      FirstHolderRelation,
	  FirstHolderRecordIdentifier,
	  FirstHolderSourceSystemName,
	  FirstHolderSourceSystemCustomerCode
	FROM dbo.StagingClientRelationDetail WHERE [Guid] = @InternalGuid

	SELECT
		StagingClientProductDetailId,
		StagingClientDetailId,
		[Guid],
		ReferenceNumber,
		ProductSegment
	FROM dbo.StagingClientProductDetail WHERE [Guid] = @InternalGuid


	SELECT
		StagingClientTagDetailId,
		StagingClientDetailId,
		[Guid] ,
		ReferenceNumber,
		Tag
	FROM dbo.StagingClientTagDetail WHERE [Guid] = @InternalGuid


	SELECT
		StagingClientBankDetailId,
		StagingClientDetailId,
		[Guid] ,
		ReferenceNumber,
		BankCode,
		MICRCode,
		BankName,
		BankBranchName,
		AccountNumber,
		AccountType,
		IFSCCode
	FROM dbo.StagingClientBankDetail WHERE [Guid] = @InternalGuid


	SELECT
		StagingClientLoanDetailId,
		StagingClientDetailId,
		[Guid] ,
		ReferenceNumber,
	    OldProductAccountNumber,
	    RelatedPartyCount,
	    AsOfDate,
	    SanctionDate,
	    DisbursementDate,
	    SanctionedAmount,
	    RateofInterest,
	    TotalOutstandingAmount,
	    AmountOverdue,
	    DaysPastDue,
	    SecurityCount,
	    FinalEMIDate,
	    TenureInMonths,
	    EMIAmount,
	    BorrowerDetails,
	    SecurityDetails,
	    ISDefaulted,
	    DefaultDate,
	    DefaultAmount,
	    LastRepaymentAmount,
	    DateofLastRepayment,
	    DateofFilingofSuit,
	    FundedType,
	    CreditorBusinessUnit,
	    InterestOutstanding,
	    OtherChargesOutstanding,
		RepaymentFrequency,
	    DrawingPower,
	    CreditorRMEmail,
	    DefaultRemarks
	FROM dbo.StagingClientLoanDetail WHERE [Guid] = @InternalGuid
	
	
	SELECT
		StagingClientAccountStatusDetailId,
		StagingClientDetailId,
		[Guid] ,
		ReferenceNumber,
        ProductAccountStatusReasonCode
	FROM dbo.StagingClientAccountStatusReasonCodeDetail WHERE [Guid] = @InternalGuid


	SELECT
		StagingClientModuleDetailId,
		StagingClientDetailId,
		[Guid] ,
		ReferenceNumber,
        ModuleApplicable
	FROM dbo.StagingClientModuleDetail WHERE [Guid] = @InternalGuid


	SELECT
		StagingClientRelationshipManagerId,
		StagingClientDetailId,
		[Guid] ,
		ReferenceNumber,
        RmType,
        RMCode
	FROM dbo.StagingClientRelationshipManager WHERE [Guid] = @InternalGuid

	SELECT 
		StagingClientProductCommunicationDetailsId,
		StagingClientDetailId,
	    [GUID],
	    ReferenceNumber,
	    PermanentCKYCAddressType	 
	   ,PlotnoSurveynoHouseFlatno	 
	   ,PermanentAddressCountry	 
	   ,PermanentAddressPinCode	 
	   ,PermanentAddressLine1	 
	   ,PermanentAddressLine2	 
	   ,PermanentAddressLine3	 
	   ,PermanentAddressDistrict	 
	   ,PermanentAddressCity	 
	   ,PermanentAddressState	 
	   ,PermanentAddressProof	 
	   ,CorrespondenceAddressCountry
	   ,CorrespondenceAddressPinCode
	   ,CorrespondenceAddressLine1	 
	   ,CorrespondenceAddressLine2	 
	   ,CorrespondenceAddressLine3	 
	   ,CorrespondenceAddressDistrict
	   ,CorrespondenceAddressCity	 
	   ,CorrespondenceAddressState	 
	   ,CorrespondenceAddressProof	 
	   ,PersonalMobileISD	 
	   ,PersonalMobileNumber	 
	   ,PersonalEmail
	   FROM dbo.StagingClientProductCommunicationDetails WHERE [Guid] = @InternalGuid

	SELECT 
		StagingClientIncomeDetailsId
		,StagingClientDetailId
		,[GUID]
		,ReferenceNumber
		,IncomeGroup
		,Income
		,Networth
		,FromDate
	   FROM dbo.StagingClientIncomeDetails  WHERE [Guid] = @InternalGuid

END
GO
/*WEB-75551**RC**END*/

--File:Tables:dbo:CoreClientIncomeDetailsHistory:CREATE
/*WEB-75551**RC**START*/
GO
CREATE TABLE dbo.CoreClientIncomeDetailsHistory(
	CoreClientIncomeDetailsHistoryId INT IDENTITY(1,1) NOT NULL,
	[Guid] VARCHAR(100),
	ReferenceNumber INT,
	CoreClientHistoryId BIGINT,
	IncomeGroup	 VARCHAR(100),
	RefIncomeGroupId INT,
	IncomeString VARCHAR(100),
	Income BIGINT,
	NetworthString VARCHAR(100),
	Networth DECIMAL(28,2),
	FromDateString VARCHAR(25),
	FromDate DATETIME,
	AddedBy VARCHAR(50) NOT NULL,
	AddedOn DATETIME NOT NULL,
	LastEditedBy VARCHAR(50) NOT NULL,
	EditedOn DATETIME NOT NULL
	)
GO
	ALTER TABLE dbo.CoreClientIncomeDetailsHistory
	ADD CONSTRAINT [PK_CoreClientIncomeDetailsHistory] PRIMARY KEY (CoreClientIncomeDetailsHistoryId);
GO
	ALTER TABLE dbo.CoreClientIncomeDetailsHistory  ADD  CONSTRAINT [FK_CoreClientIncomeDetailsHistory_CoreClientHistoryId] FOREIGN KEY(CoreClientHistoryId)
	REFERENCES dbo.CoreClientHistory (CoreClientHistoryId);
GO
	ALTER TABLE dbo.CoreClientIncomeDetailsHistory  ADD  CONSTRAINT [FK_CoreClientIncomeDetailsHistory_RefIncomeGroupId] FOREIGN KEY(RefIncomeGroupId)
	REFERENCES dbo.RefIncomeGroup (RefIncomeGroupId);
GO
/*WEB-75551**RC**END*/

--File:Tables:dbo:StagingCustom222ProductAccFlat:ALTER
/*WEB-75551**RC**START*/
GO
ALTER TABLE dbo.StagingCustom222ProductAccFlat
ADD IncomeGroup	 VARCHAR(100),
	Income VARCHAR(100),
	Networth VARCHAR(100),
	FromDate VARCHAR(25)
GO
/*WEB-75551**RC**END*/

--File:StoredProcedures:dbo:StagingCustom222ProductAccFlat_InsertFromStagingClientFlat
/*WEB-75551**RC**START*/
GO
ALTER PROCEDURE dbo.StagingCustom222ProductAccFlat_InsertFromStagingClientFlat
(
	@CompanyName VARCHAR(500)=NULL,
	@SourceSystemName VARCHAR(500)=NULL,
	@BatchSize INT=NULL ,
	@IdentityColumnValue BIGINT = NULL,
	@UserName VARCHAR(100)
)
AS
BEGIN
		
		DECLARE @InternalBatchSize INT, @InternalIdentityColumnValue INT,@InternalGuid VARCHAR(50)
		SET @InternalBatchSize=@BatchSize
		SET @InternalIdentityColumnValue=@IdentityColumnValue
		SET @InternalGuid = NEWID()

		DECLARE @CurrentDateTime DATETIME
		SET @CurrentDateTime=GETDATE()

		DECLARE @AddedBy VARCHAR(200)
		SET @AddedBy = @UserName

		CREATE TABLE #StagingCustom222ProductAccFlat (StagingCustom222ProductAccFlatId BIGINT PRIMARY KEY)

		IF (ISNULL(@InternalBatchSize,'')='')
		BEGIN
				INSERT INTO #StagingCustom222ProductAccFlat(StagingCustom222ProductAccFlatId)
				SELECT StagingCustom222ProductAccFlatId 
				FROM dbo.StagingCustom222ProductAccFlat
				WHERE (@InternalIdentityColumnValue IS NULL OR StagingCustom222ProductAccFlatId>@InternalIdentityColumnValue) AND (@CompanyName IS NULL OR ParentCompany = @CompanyName)
				ORDER BY StagingCustom222ProductAccFlatId
		END
		ELSE 
		BEGIN
				INSERT INTO #StagingCustom222ProductAccFlat(StagingCustom222ProductAccFlatId)
				SELECT TOP (@InternalBatchSize) StagingCustom222ProductAccFlatId 
				FROM dbo.StagingCustom222ProductAccFlat
				WHERE (@InternalIdentityColumnValue IS NULL OR StagingCustom222ProductAccFlatId>@InternalIdentityColumnValue) AND (@CompanyName IS NULL OR ParentCompany = @CompanyName)
				ORDER BY StagingCustom222ProductAccFlatId
		END

		DECLARE @IdentityColumnId BIGINT,@RecordsPushed BIGINT

		INSERT INTO dbo.StagingClientFlat
		(
			[GUID],
			ReferenceNumber,
			TransactionId,
			ParentCompany,
			ProductAccountType,
			ProductAccountNumber,
			ProductSegments,
			ApplicationNumber,
			FirstHolderRelation,
			FirstHolderRecordIdentifier,
			FirstHolderSourceSystemName,
			FirstHolderSourceSystemCustomerCode,
			ProductAccountOpeningDate,
			ProductAccountStatus,
			ProductAccountStatusEffectiveDate,
			ProductAccountStatusDescription,
			ProductAccountStatusReasonCode,
			ProductAccountReasonCodeDescription,
			Remarks,
			OldProductAccountNumber,
			Channel,
			IntermediaryCode,
			IntroducerEmployeeCode,
			RelatedPartyCount,
			Currency,
			ProductApplicationDate,
			ApplicationSignedDate,
			AsOfDate,
			BankCode,
			MICRCode,
			BankName,
			BankBranchName,
			AccountNumber,
			AccountType,
			IFSCCode,
			Tags,
			RiskCommencementDate,
			FirstPremiumReceiptDate,
			LoginDate,
			UnderwritingDate,
			BranchReceiptDate,
			InsurancePurpose,
			SumAssured,
			GrossAnnualPremiumwithTax,
			GrossAnnualPremiumwithoutTax,
			ModalPremium,
			PolicyTerm,
			PayTerm,
			RepaymentFrequency,
			PolicyEndDate,
			SanctionDate,
			DisbursementDate,
			SanctionedAmount,
			NatureofCredit,
			RateofInterest,
			LendingArrangement,
			TotalOutstandingAmount,
			AmountOverdue,
			DaysPastDue,
			SecurityCount,
			FinalEMIDate,
			TenureInMonths,
			EMIAmount,
			BorrowerDetails,
			SecurityDetails,
			ISDefaulted,
			DefaultDate,
			DefaultAmount,
			LastRepaymentAmount,
			DateOfLastRepayment,
			DateOfFilingOfSuit,
			DebtSubtype,
			FundedType,
			CreditorBusinessunit,
			InterestOutstanding,
			OtherChargesOutstanding,
			DrawingPower,
			CreditOrRMEmail,
			DefaultRemarks,
			ModuleApplicable,
			PolicyType,
			RMType,
			RMCode,
			AddedBy,
			AddedOn
			,PermanentCKYCAddressType	 
			,PlotnoSurveynoHouseFlatno	 
			,PermanentAddressCountry	 
			,PermanentAddressPinCode	 
			,PermanentAddressLine1	 
			,PermanentAddressLine2	 
			,PermanentAddressLine3	 
			,PermanentAddressDistrict	 
			,PermanentAddressCity	 
			,PermanentAddressState	 
			,PermanentAddressProof	 
			,CorrespondenceAddressCountry
			,CorrespondenceAddressPinCode
			,CorrespondenceAddressLine1	 
			,CorrespondenceAddressLine2	 
			,CorrespondenceAddressLine3	 
			,CorrespondenceAddressDistrict
			,CorrespondenceAddressCity	 
			,CorrespondenceAddressState	 
			,CorrespondenceAddressProof	 
			,PersonalMobileISD	 
			,PersonalMobileNumber	 
			,PersonalEmail	 
			,AccountSegment
			,AccountSegmentEffectiveDate
			,AccountRisk
			,AccountRiskEffectiveDate
			,AccountRiskNextReviewDate,
			PreferredTransactionMode,
			DPID,
			ClientStatus,
			IncomeMultiplier,
			NetworthMultiplier,
			SecondHolderFirstname,
			SecondHolderMiddlename,
			SecondHolderLastname,
			SecondHolderPan,
			ThirdHolderFirstname,
			ThirdHolderMiddlename,
			ThirdHolderLastname,
			ThirdHolderPan,
			IsWhiteListed,
			IsFamilyDeclaration,
			IncomeGroup, 
			Income,
			Networth, 
			FromDate 
		)
		SELECT
			@InternalGuid,
			ROW_NUMBER() OVER( ORDER BY stag222flat.StagingCustom222ProductAccFlatId) AS ReferenceNumber,
			stag222flat.TransactionId,
			stag222flat.ParentCompany,
			stag222flat.ProductAccountType,
			stag222flat.ProductAccountNumber,
			stag222flat.ProductSegments,
			stag222flat.ApplicationNumber,
			stag222flat.FirstHolderRelation,
			stag222flat.FirstHolderRecordIdentifier,
			stag222flat.FirstHolderSourceSystemName,
			stag222flat.FirstHolderSourceSystemCustomerCode,
			stag222flat.ProductAccountOpeningDate,
			stag222flat.ProductAccountStatus,
			stag222flat.ProductAccountStatusEffectiveDate,
			stag222flat.ProductAccountStatusDescription,
			stag222flat.ProductAccountStatusReasonCode,
			stag222flat.ProductAccountReasonCodeDescription,
			stag222flat.Remarks,
			stag222flat.OldProductAccountNumber,
			stag222flat.Channel,
			stag222flat.IntermediaryCode,
			stag222flat.IntroducerEmployeeCode,
			stag222flat.RelatedPartyCount,
			stag222flat.Currency,
			stag222flat.ProductApplicationDate,
			stag222flat.ApplicationSignedDate,
			stag222flat.AsOfDate,
			stag222flat.BankCode,
			stag222flat.MICRCode,
			stag222flat.BankName,
			stag222flat.BankBranchName,
			stag222flat.AccountNumber,
			stag222flat.AccountType,
			stag222flat.IFSCCode,
			stag222flat.Tags,
			stag222flat.RiskCommencementDate,
			stag222flat.FirstPremiumReceiptDate,
			stag222flat.LoginDate,
			stag222flat.UnderwritingDate,
			stag222flat.BranchReceiptDate,
			stag222flat.InsurancePurpose,
			stag222flat.SumAssured,
			stag222flat.GrossAnnualPremiumwithTax,
			stag222flat.GrossAnnualPremiumwithoutTax,
			stag222flat.ModalPremium,
			stag222flat.PolicyTerm,
			stag222flat.PayTerm,
			stag222flat.RepaymentFrequency,
			stag222flat.PolicyEndDate,
			stag222flat.SanctionDate,
			stag222flat.DisbursementDate,
			stag222flat.SanctionedAmount,
			stag222flat.NatureofCredit,
			stag222flat.RateofInterest,
			stag222flat.LendingArrangement,
			stag222flat.TotalOutstandingAmount,
			stag222flat.AmountOverdue,
			stag222flat.DaysPastDue,
			stag222flat.SecurityCount,
			stag222flat.FinalEMIDate,
			stag222flat.TenureInMonths,
			stag222flat.EMIAmount,
			stag222flat.BorrowerDetails,
			stag222flat.SecurityDetails,
			stag222flat.ISDefaulted,
			stag222flat.DefaultDate,
			stag222flat.DefaultAmount,
			stag222flat.LastRepaymentAmount,
			stag222flat.DateOfLastRepayment,
			stag222flat.DateOfFilingOfSuit,
			stag222flat.DebtSubtype,
			stag222flat.FundedType,
			stag222flat.CreditorBusinessunit,
			stag222flat.InterestOutstanding,
			stag222flat.OtherChargesOutstanding,
			stag222flat.DrawingPower,
			stag222flat.CreditOrRMEmail,
			stag222flat.DefaultRemarks,
			stag222flat.ModuleApplicable,
			stag222flat.PolicyType,
			stag222flat.RMType,
			stag222flat.RMCode,
			@AddedBy,
			@CurrentDateTime
			,stag222flat.PermanentCKYCAddressType	 
			,stag222flat.PlotnoSurveynoHouseFlatno	 
			,stag222flat.PermanentAddressCountry	 
			,stag222flat.PermanentAddressPinCode	 
			,stag222flat.PermanentAddressLine1	 
			,stag222flat.PermanentAddressLine2	 
			,stag222flat.PermanentAddressLine3	 
			,stag222flat.PermanentAddressDistrict	 
			,stag222flat.PermanentAddressCity	 
			,stag222flat.PermanentAddressState	 
			,stag222flat.PermanentAddressProof	 
			,stag222flat.CorrespondenceAddressCountry
			,stag222flat.CorrespondenceAddressPinCode
			,stag222flat.CorrespondenceAddressLine1	 
			,stag222flat.CorrespondenceAddressLine2	 
			,stag222flat.CorrespondenceAddressLine3	 
			,stag222flat.CorrespondenceAddressDistrict
			,stag222flat.CorrespondenceAddressCity	 
			,stag222flat.CorrespondenceAddressState	 
			,stag222flat.CorrespondenceAddressProof	 
			,stag222flat.PersonalMobileISD	 
			,stag222flat.PersonalMobileNumber	 
			,stag222flat.PersonalEmail	
			,stag222flat.AccountSegment
			,stag222flat.AccountSegmentEffectiveDate
			,stag222flat.AccountRisk
			,stag222flat.AccountRiskEffectiveDate
			,stag222flat.AccountRiskNextReviewDate,
			stag222flat.PreferredTransactionMode,
			stag222flat.DPID,
			stag222flat.ClientStatus,
			stag222flat.IncomeMultiplier,
			stag222flat.NetworthMultiplier,
			stag222flat.SecondHolderFirstname,
			stag222flat.SecondHolderMiddlename,
			stag222flat.SecondHolderLastname,
			stag222flat.SecondHolderPan,
			stag222flat.ThirdHolderFirstname,
			stag222flat.ThirdHolderMiddlename,
			stag222flat.ThirdHolderLastname,
			stag222flat.ThirdHolderPan,
			stag222flat.IsWhiteListed,
			stag222flat.IsFamilyDeclaration,
			stag222flat.IncomeGroup,
			stag222flat.Income,
			stag222flat.Networth,
			stag222flat.FromDate
		FROM dbo.StagingCustom222ProductAccFlat stag222flat
		INNER JOIN #StagingCustom222ProductAccFlat tempstag ON stag222flat.StagingCustom222ProductAccFlatId=tempstag.StagingCustom222ProductAccFlatId
		
		SELECT 
		MAX(StagingCustom222ProductAccFlatId) AS IdentityColumnId,
		COUNT(StagingCustom222ProductAccFlatId) AS RecordsPushed
		FROM #StagingCustom222ProductAccFlat
END
GO
/*WEB-75551**RC**END*/


--File:StoredProcedures:dbo:StagingClientDetailTables_DeleteByGuid
/*WEB-75551**RC**START*/
GO
ALTER PROCEDURE [dbo].[StagingClientDetailTables_DeleteByGuid]
(
	@GUID VARCHAR(50)
)
AS
BEGIN
	DECLARE @InternalGUID VARCHAR(50)
	SET @InternalGUID = @GUID

	DELETE FROM dbo.StagingClientProductDetail WHERE [GUID] = @InternalGUID
	DELETE FROM dbo.StagingClientTagDetail WHERE [GUID] = @InternalGUID
	DELETE FROM dbo.StagingClientBankDetail WHERE [GUID] = @InternalGUID
	DELETE FROM dbo.StagingClientLoanDetail WHERE [GUID] = @InternalGUID
	DELETE FROM dbo.StagingClientAccountStatusReasonCodeDetail WHERE [GUID] = @InternalGUID
	DELETE FROM dbo.StagingClientModuleDetail WHERE [GUID] = @InternalGUID
	DELETE FROM dbo.StagingClientRelationshipManager WHERE [GUID] = @InternalGUID
	DELETE FROM dbo.StagingCRMCustomerIdentificationDetail WHERE [GUID] = @InternalGUID
	DELETE FROM dbo.StagingClientRelationDetail WHERE [GUID] = @InternalGUID
	DELETE FROM dbo.StagingClientProductCommunicationDetails WHERE [GUID] = @InternalGUID
	DELETE FROM dbo.StagingClientIncomeDetails WHERE [GUID] = @InternalGUID
	DELETE FROM dbo.StagingClientDetail WHERE [GUID] = @InternalGUID
	
END
GO
/*WEB-75551**RC**END*/

--File:StoredProcedures:dbo:IncomeDetails_InsertFromCoreClientIncomeDetailsHistory
/*WEB-75551**RC**START*/
GO
ALTER PROCEDURE [dbo].[IncomeDetails_InsertFromCoreClientIncomeDetailsHistory]            
(           
 @Guid VARCHAR(100),            
 @AddedBy VARCHAR(100)        
)            
AS              
BEGIN            
   DECLARE @InternalGuid VARCHAR(50),@InternalAddedBy VARCHAR(100), @CurrentDate DATETIME                
   SET @InternalGuid =  @Guid            
   SET @InternalAddedBy = @AddedBy            
   SET @CurrentDate = GETDATE()   
   
   INSERT INTO dbo.LinkRefClientRefIncomeGroup  
	(
		RefClientId,
		RefIncomeGroupId,
		Income,
		Networth,
		FromDate,
		AddedBy,
		AddedOn,
		LastEditedBy,
		EditedOn
	)(
	SELECT 
		ids.RefClientId,
		his.RefIncomeGroupId,
		his.Income,
		his.Networth * 100000,
		ISNULL(his.FromDate,@CurrentDate),
		@InternalAddedBy,
		@CurrentDate,
		@InternalAddedBy,
		@CurrentDate
	FROM #CoreClientHistoryIds ids
	INNER JOIN dbo.CoreClientIncomeDetailsHistory his ON ids.CoreClientHistoryId = his.CoreClientHistoryId AND his.[Guid] = @InternalGuid AND ISNULL(his.RefIncomeGroupId, 0) <> 0
	)
END    
GO
/*WEB-75551**RC**END*/

--File:StoredProcedures:dbo:IncomeDetails_UpdateFromCoreClientIncomeDetailsHistory
/*WEB-75551**RC**START*/
GO
ALTER PROCEDURE [dbo].[IncomeDetails_UpdateFromCoreClientIncomeDetailsHistory]                
(               
	 @Guid VARCHAR(100),                
	 @AddedBy VARCHAR(100)            
)                
AS                  
BEGIN                
   DECLARE @InternalGuid VARCHAR(50),@InternalAddedBy VARCHAR(100), @CurrentDate DATETIME                
                
   SET @InternalGuid =  @Guid                
   SET @InternalAddedBy = @AddedBy                
   SET @CurrentDate = GETDATE()      
    
   SELECT    
	t.*    
   INTO #latestRefIncomeUpdate    
   FROM     
    (
		SELECT    
			  link.LinkRefClientRefIncomeGroupId,    
			  his.FromDate,    
			  ROW_NUMBER() OVER(PARTITION BY link.RefClientId ORDER BY link.FromDate DESC) RN    
		FROM #CoreClientHistoryIds tempHis    
		INNER JOIN dbo.CoreClientIncomeDetailsHistory his  ON tempHis.CoreClientHistoryId = his.CoreClientHistoryId  AND his.[Guid] = @InternalGuid    
		INNER JOIN dbo.LinkRefClientRefIncomeGroup link ON link.RefClientId = tempHis.RefClientId    AND link.FromDate < his.FromDate
	) t    
   WHERE t.RN = 1    
    
   UPDATE link    
   SET link.ToDate =  DATEADD(DAY, -1, ISNULL(latest.FromDate,@CurrentDate))   
   FROM dbo.LinkRefClientRefIncomeGroup link    
   INNER JOIN #latestRefIncomeUpdate latest ON latest.LinkRefClientRefIncomeGroupId = link.LinkRefClientRefIncomeGroupId
   WHERE link.ToDate IS NULL

	   UPDATE income      
		  SET       
		   income.RefIncomeGroupId = his.RefIncomeGroupId,    
		   income.Income = his.Income,    
		   income.Networth = his.Networth * 100000,    
		   income.LastEditedBy = @InternalAddedBy,      
		   income.EditedOn = @CurrentDate      
	  FROM dbo.CoreClientIncomeDetailsHistory his      
	  INNER JOIN #CoreClientHistoryIds tempHis ON tempHis.CoreClientHistoryId = his.CoreClientHistoryId  AND his.[Guid] = @InternalGuid AND ISNULL(his.RefIncomeGroupId, 0) <> 0     
	  INNER JOIN dbo.LinkRefClientRefIncomeGroup income ON income.RefClientId = tempHis.RefClientId AND income.FromDate = his.FromDate     
	  WHERE (income.Income <> his.Income OR income.RefIncomeGroupId <> his.RefIncomeGroupId OR income.Networth <> his.Networth* 100000)      
       
	  INSERT INTO dbo.LinkRefClientRefIncomeGroup      
		 (    
		  RefClientId,    
		  RefIncomeGroupId,    
		  Income,    
		  Networth,    
		  FromDate,    
		  AddedBy,    
		  AddedOn,    
		  LastEditedBy,    
		  EditedOn    
		 )    
	  SELECT     
		   ids.RefClientId,    
		   his.RefIncomeGroupId,    
		   his.Income,    
		   his.Networth* 100000,    
		   ISNULL(his.FromDate, @CurrentDate),    
		   @InternalAddedBy,    
		   @CurrentDate,    
		   @InternalAddedBy,    
		   @CurrentDate    
	  FROM #CoreClientHistoryIds ids    
	  INNER JOIN dbo.CoreClientIncomeDetailsHistory his ON ids.CoreClientHistoryId = his.CoreClientHistoryId AND his.[Guid] = @InternalGuid AND ISNULL(his.RefIncomeGroupId, 0) <> 0   
	  LEFT JOIN dbo.LinkRefClientRefIncomeGroup grp ON grp.RefClientId = ids.RefClientId AND ISNULL(his.FromDate,@CurrentDate) = grp.FromDate    
	  WHERE grp.LinkRefClientRefIncomeGroupId IS NULL     
END 
GO
/*WEB-75551**RC**END*/  


--File:StoredProcedures:dbo:RefClient_InsertFromCoreClientHistoryTables
/*WEB-75551**RC**START*/
GO
ALTER PROCEDURE [dbo].[RefClient_InsertFromCoreClientHistoryTables]
(   
    @Guid varchar(100),  
 @AddedBy VARCHAR(100)    
)  
AS    
BEGIN  
 DECLARE @InternalGuid VARCHAR(50), @InternalAddedBy VARCHAR(100), @ToBeInsertedRefEnumValueId INT, @RecordCreatedRefEnumValueId INT, @PartialAcceptedRefEnumValueId INT, @AccptedRefEnumValueId INT, @RefEntityTypeId INT  
 SET @InternalGuid=@Guid  
 SET @RefEntityTypeId = dbo.GetEntityTypeByCode('Client')  
 SET @InternalAddedBy=@AddedBy  
 SET @ToBeInsertedRefEnumValueId= dbo.GetIntegrationStatusIdByEntityTypeCode('Client','ToBeCreated')  
 SET @RecordCreatedRefEnumValueId= dbo.GetIntegrationStatusIdByEntityTypeCode('Client','RecordCreated')  
 SET @PartialAcceptedRefEnumValueId= dbo.GetIntegrationStatusIdByEntityTypeCode('Client','PartialAcceptedByTrackWizz')  
 SET @AccptedRefEnumValueId= dbo.GetIntegrationStatusIdByEntityTypeCode('Client','AcceptedByTrackWizz')  
  
 CREATE TABLE #CoreClientHistoryIds(CoreClientHistoryId BIGINT, RefClientId INT)  
   
 INSERT INTO #CoreClientHistoryIds(CoreClientHistoryId)  
 SELECT CoreClientHistoryId  
 FROM dbo.CoreClientHistory  
 WHERE [Guid]=@InternalGuid AND  
    RecordStatusRefEntityIntegrationStatusId=@ToBeInsertedRefEnumValueId AND   
    (CreateUpdateResponseStatusRefEntityIntegrationStatusId=@PartialAcceptedRefEnumValueId OR CreateUpdateResponseStatusRefEntityIntegrationStatusId=@AccptedRefEnumValueId)  
  
 IF EXISTS(SELECT TOP 1 * FROM #CoreClientHistoryIds)  
  BEGIN  
  
  CREATE INDEX IX_#CoreClientHistoryIds_CoreClientHistoryId ON #CoreClientHistoryIds(CoreClientHistoryId)  
  
  EXEC dbo.RefClient_InsertFromCoreClientHistoryTable @Guid=@InternalGuid, @AddedBy=@InternalAddedBy  
  
     UPDATE temp  
  SET temp.RefClientId=his.RefClientId   
  FROM #CoreClientHistoryIds temp  
  INNER JOIN dbo.CoreClientHistory his ON his.CoreClientHistoryId=temp.CoreClientHistoryId 
  
	EXEC dbo.LinkRefClientRefSegment_InsertFromCoreClientProductDetailHistoryTable @Guid=@InternalGuid, @AddedBy=@InternalAddedBy  
	EXEC dbo.CoreCRMRelatedParty_InsertFromCoreClientHistoryTable @Guid=@InternalGuid, @AddedBy=@InternalAddedBy  
    EXEC dbo.CoreCRMEntityStatus_InsertFromCoreClientHistoryTable @Guid=@InternalGuid, @AddedBy=@InternalAddedBy  
	EXEC dbo.CoreClientLoanDetail_InsertFromCoreClientLoanDetailHistory @Guid=@InternalGuid, @AddedBy=@InternalAddedBy  
    EXEC dbo.CoreCRMBankAccount_InsertFromCoreClientBankDetailHistory @Guid=@InternalGuid, @AddedBy=@InternalAddedBy       
	EXEC dbo.LinkRefClientRefEnumValue_InsertFromCoreClientTagDetailHistory @Guid=@InternalGuid, @AddedBy=@InternalAddedBy    
	EXEC dbo.CoreClientRelationshipManager_InsertFromCoreClientRelationshipManagerHistory @Guid=@InternalGuid, @AddedBy=@InternalAddedBy    
	EXEC dbo.LinkRefClientSecModule_InsertFromCoreClientModuleDetailHistory @Guid=@InternalGuid, @AddedBy=@InternalAddedBy  
    EXEC dbo.CoreClientAsOndateBalance_InsertFromCoreClientLoanDetailHistory @Guid=@InternalGuid, @AddedBy=@InternalAddedBy
    EXEC dbo.CommunicationDetails_InsertAndUpdateFromCoreClientProductCommunicationDetailsHistory @Guid=@InternalGuid, @AddedBy=@InternalAddedBy
	EXEC dbo.LinkRefClientRefCustomerSegment_InsertUpdateFromCoreClientHistoryTable @Guid=@InternalGuid, @AddedBy=@InternalAddedBy
	EXEC dbo.CoreCRMCDDClassification_InsertAndUpdateFromCoreClientHistoryTable @Guid=@InternalGuid, @AddedBy=@InternalAddedBy
	EXEC dbo.LinkRefClientKeyValueInfo_InsertAndUpdateFromCoreClientProductDetailHistoryTable @Guid=@InternalGuid, @AddedBy=@InternalAddedBy
	EXEC dbo.IncomeDetails_InsertFromCoreClientIncomeDetailsHistory @Guid=@InternalGuid, @AddedBy=@InternalAddedBy
  UPDATE his   
  SET his.RecordStatusRefEntityIntegrationStatusId=@RecordCreatedRefEnumValueId   
  FROM #CoreClientHistoryIds temp  
  INNER JOIN dbo.CoreClientHistory his ON his.CoreClientHistoryId =temp.CoreClientHistoryId  
 END   
END
GO
/*WEB-75551**RC**END*/

--File:StoredProcedures:dbo:RefClient_UpdateFromCoreClientHistoryTables
/*WEB-75551**RC**START*/
GO
ALTER PROCEDURE [dbo].[RefClient_UpdateFromCoreClientHistoryTables]
(   
    @Guid varchar(100),  
	@AddedBy VARCHAR(100)    
)  
AS    
BEGIN  
 DECLARE @InternalGuid VARCHAR(50), @InternalAddedBy VARCHAR(100), @ToBeUpdatedRefEnumValueId INT, @RecordUpdatedRefEnumValueId INT, @PartialAcceptedRefEnumValueId INT, @AccptedRefEnumValueId INT, @RefEntityTypeId INT  
 SET @InternalGuid=@Guid  
 SET @RefEntityTypeId = dbo.GetEntityTypeByCode('Client')  
 SET @InternalAddedBy=@AddedBy  
 SET @ToBeUpdatedRefEnumValueId = dbo.GetIntegrationStatusIdByEntityTypeCode('Client','ToBeUpdated')  
 SET @RecordUpdatedRefEnumValueId = dbo.GetIntegrationStatusIdByEntityTypeCode('Client','RecordUpdated')  
 SET @PartialAcceptedRefEnumValueId = dbo.GetIntegrationStatusIdByEntityTypeCode('Client','PartialAcceptedByTrackWizz')  
 SET @AccptedRefEnumValueId = dbo.GetIntegrationStatusIdByEntityTypeCode('Client','AcceptedByTrackWizz')  
  
 CREATE TABLE #CoreClientHistoryIds(CoreClientHistoryId BIGINT, RefClientId INT, RefEntityTypeId INT, RelatedPartyRefCRMCustomerId INT)  
   
 INSERT INTO #CoreClientHistoryIds(CoreClientHistoryId, RefClientId, RefEntityTypeId)  
 SELECT his.CoreClientHistoryId,  
        his.MatchingWithRefClientId,  
     his.RefEntityTypeId  
 FROM dbo.CoreClientHistory his  
 WHERE [Guid]=@InternalGuid AND  
    RecordStatusRefEntityIntegrationStatusId=@ToBeUpdatedRefEnumValueId AND   
    CreateUpdateResponseStatusRefEntityIntegrationStatusId=@AccptedRefEnumValueId  
  
 IF EXISTS(SELECT TOP 1 * FROM #CoreClientHistoryIds)  
  BEGIN  
  
  UPDATE temp  
  SET temp.RelatedPartyRefCRMCustomerId=Rhis.RelatedPartyRefCRMCustomerId   
  FROM #CoreClientHistoryIds temp  
  INNER JOIN dbo.CoreClientRelationHistory Rhis ON Rhis.CoreClientHistoryId = temp.CoreClientHistoryId  
  
  CREATE INDEX IX_#CoreClientHistoryIds_CoreClientHistoryId ON #CoreClientHistoryIds(CoreClientHistoryId)  
  
  EXEC dbo.RefClient_UpdateFromCoreClientHistoryTable @AddedBy=@InternalAddedBy   
  EXEC dbo.LinkRefClientRefSegment_UpdateFromCoreClientProductDetailHistoryTable @AddedBy=@InternalAddedBy   
  EXEC dbo.CoreCRMEntityStatus_UpdateFromCoreClientHistoryTable @AddedBy=@InternalAddedBy, @GUID = @InternalGuid   
  EXEC dbo.LinkRefClientRefEnumValue_UpdateFromCoreClientTagDetailHistoryTable @AddedBy=@InternalAddedBy   
  EXEC dbo.CoreClientRelationshipManager_UpdateFromCoreClientRelationshipManagerHistoryTable @AddedBy=@InternalAddedBy   
  EXEC dbo.LinkRefClientSecModule_InsertFromCoreClientModuleDetailHistoryTable @AddedBy=@InternalAddedBy   
  EXEC dbo.CoreClientLoanDetail_UpdateFromCoreClientLoanDetailHistoryTable @AddedBy=@InternalAddedBy   
  EXEC dbo.CoreCRMBankAccount_UpdateFromCoreClientProductDetailHistoryTable @AddedBy=@InternalAddedBy   
  EXEC dbo.CoreCRMRelatedParty_UpdateFromCoreClientHistoryTable @AddedBy=@InternalAddedBy  
  EXEC dbo.CoreClientAsOndateBalance_UpdateFromCoreClientLoanDetailHistory @AddedBy=@InternalAddedBy 
  EXEC dbo.CommunicationDetails_InsertAndUpdateFromCoreClientProductCommunicationDetailsHistory @Guid=@InternalGuid, @AddedBy=@InternalAddedBy
  EXEC dbo.LinkRefClientRefCustomerSegment_InsertUpdateFromCoreClientHistoryTable @Guid=@InternalGuid, @AddedBy=@InternalAddedBy
  EXEC dbo.CoreCRMCDDClassification_InsertAndUpdateFromCoreClientHistoryTable @Guid=@InternalGuid, @AddedBy=@InternalAddedBy
  EXEC dbo.LinkRefClientKeyValueInfo_InsertAndUpdateFromCoreClientProductDetailHistoryTable @Guid=@InternalGuid, @AddedBy=@InternalAddedBy
  EXEC dbo.IncomeDetails_UpdateFromCoreClientIncomeDetailsHistory @Guid=@InternalGuid, @AddedBy=@InternalAddedBy

  UPDATE his   
  SET his.RecordStatusRefEntityIntegrationStatusId=@RecordUpdatedRefEnumValueId   
  FROM #CoreClientHistoryIds temp  
  INNER JOIN dbo.CoreClientHistory his ON his.CoreClientHistoryId =temp.CoreClientHistoryId  
 
 END   
END
GO
/*WEB-75551**RC**END*/

--File:StoredProcedures:dbo:CoreClientHistory_GetClientIdAndReferenceNumberAndUpdateHistoryId
/*WEB-75551**RC**START*/
GO
ALTER PROCEDURE [dbo].[CoreClientHistory_GetClientIdAndReferenceNumberAndUpdateHistoryId]
(
    @Guid VARCHAR(50)
)
AS
BEGIN
    DECLARE @InternalGuid VARCHAR(50)
	SET @InternalGuid = @Guid

    UPDATE his
	SET his.CoreFileProcessLogId=fileLog.CoreFileProcessLogId
	FROM dbo.CoreClientHistory his
	INNER JOIN dbo.CoreFileProcessLog fileLog ON fileLog.[Guid]=his.[Guid]
	WHERE his.[Guid]=@InternalGuid

	UPDATE child SET child.CoreClientHistoryId=parent.CoreClientHistoryId 
	FROM dbo.CoreClientProductDetailHistory child 
	INNER JOIN dbo.CoreClientHistory parent ON parent.[GUID]=child.[GUID] AND parent.ReferenceNumber=child.ReferenceNumber
	WHERE child.[GUID] = @InternalGuid

	UPDATE child SET child.CoreClientHistoryId=parent.CoreClientHistoryId 
	FROM dbo.CoreClientRelationHistory child 
	INNER JOIN dbo.CoreClientHistory parent ON parent.[GUID]=child.[GUID] AND parent.ReferenceNumber=child.ReferenceNumber
	WHERE child.[GUID] = @InternalGuid

	UPDATE child SET child.CoreClientHistoryId=parent.CoreClientHistoryId 
	FROM dbo.CoreClientTagDetailHistory child 
	INNER JOIN dbo.CoreClientHistory parent ON parent.[GUID]=child.[GUID] AND parent.ReferenceNumber=child.ReferenceNumber
	WHERE child.[GUID] = @InternalGuid

	UPDATE child SET child.CoreClientHistoryId=parent.CoreClientHistoryId 
	FROM dbo.CoreClientBankDetailHistory child 
	INNER JOIN dbo.CoreClientHistory parent ON parent.[GUID]=child.[GUID] AND parent.ReferenceNumber=child.ReferenceNumber
	WHERE child.[GUID] = @InternalGuid

	UPDATE child SET child.CoreClientHistoryId=parent.CoreClientHistoryId 
	FROM dbo.CoreClientLoanDetailHistory child 
	INNER JOIN dbo.CoreClientHistory parent ON parent.[GUID]=child.[GUID] AND parent.ReferenceNumber=child.ReferenceNumber
	WHERE child.[GUID] = @InternalGuid

	UPDATE child SET child.CoreClientHistoryId=parent.CoreClientHistoryId 
	FROM dbo.CoreClientAccountStatusReasonCodeDetailHistory child 
	INNER JOIN dbo.CoreClientHistory parent ON parent.[GUID]=child.[GUID] AND parent.ReferenceNumber=child.ReferenceNumber
	WHERE child.[GUID] = @InternalGuid

	UPDATE child SET child.CoreClientHistoryId=parent.CoreClientHistoryId 
	FROM dbo.CoreClientModuleDetailHistory child 
	INNER JOIN dbo.CoreClientHistory parent ON parent.[GUID]=child.[GUID] AND parent.ReferenceNumber=child.ReferenceNumber
	WHERE child.[GUID] = @InternalGuid

	UPDATE child SET child.CoreClientHistoryId=parent.CoreClientHistoryId 
	FROM dbo.CoreClientRelationshipManagerHistory child 
	INNER JOIN dbo.CoreClientHistory parent ON parent.[GUID]=child.[GUID] AND parent.ReferenceNumber=child.ReferenceNumber
	WHERE child.[GUID] = @InternalGuid

	UPDATE child SET child.CoreClientHistoryId=parent.CoreClientHistoryId 
	FROM dbo.CoreClientProductCommunicationDetailsHistory child 
	INNER JOIN dbo.CoreClientHistory parent ON parent.[GUID]=child.[GUID] AND parent.ReferenceNumber=child.ReferenceNumber
	WHERE child.[GUID] = @InternalGuid

	UPDATE child SET child.CoreClientHistoryId=parent.CoreClientHistoryId 
	FROM dbo.CoreClientIncomeDetailsHistory child 
	INNER JOIN dbo.CoreClientHistory parent ON parent.[GUID]=child.[GUID] AND parent.ReferenceNumber=child.ReferenceNumber
	WHERE child.[GUID] = @InternalGuid

	SELECT CoreClientHistoryId,
		   ReferenceNumber
	FROM dbo.CoreClientHistory WHERE [Guid]=@InternalGuid
END
GO
/*WEB-75551**RC**END*/

--File:Tables:dbo:RefRejectionValidator:DML
/*WEB-75551**RC**START*/
GO
EXEC dbo.RefRejectionValidator_InsertIfNotExists 
@Name = 'Length After Decimal Point Validation',
@Code = 'V148',
@RejectionDataCollectionTypeCode = 'Single'
GO
/*WEB-75551**RC**END*/

--File:Tables:dbo:RefRejectionCode:DML
/*WEB-75551**RC**START*/
GO
EXEC dbo.RefRejectionCode_Insert @Code = 'EC4103', @Name = 'IncomeGroup' , @FieldName = 'IncomeGroup', @Description = 'Income group is mandatory.', @CodeType = 'DataIntegration', @IsActive = 0
GO
EXEC dbo.RefRejectionCode_Insert @Code = 'EC4104', @Name = 'IncomeGroup', @FieldName = 'IncomeGroup', @Description = 'Income group should be as per the enum list/ Values', @CodeType = 'DataIntegration', @IsActive = 0
GO
EXEC dbo.RefRejectionCode_Insert @Code = 'EC4105', @Name = 'Income', @FieldName = 'Income', @Description = 'Income value should be with in the specified range.', @CodeType = 'DataIntegration', @IsActive = 0
GO
EXEC dbo.RefRejectionCode_Insert @Code = 'EC4106', @Name = 'Income', @FieldName = 'IncomeString', @Description = 'Income should have numeric value', @CodeType = 'DataIntegration', @IsActive = 0
GO
EXEC dbo.RefRejectionCode_Insert @Code = 'EC4107', @Name = 'NetWorth', @FieldName = 'NetworthString', @Description = 'Networth should be real number upto two digit after decimal (eg. 35.54)', @CodeType = 'DataIntegration', @IsActive = 0
GO
EXEC dbo.RefRejectionCode_Insert @Code = 'EC4108', @Name = 'FromDate', @FieldName = 'FromDate', @Description = 'New From date must be greater than previous From date and To date ', @CodeType = 'DataIntegration', @IsActive = 0
GO
EXEC dbo.RefRejectionCode_Insert @Code = 'EC4109', @Name = 'FromDate' , @FieldName = 'FromDateString', @Description = 'From date should be in this format only : DD/MM/YYYY', @CodeType = 'DataIntegration', @IsActive = 0
GO
/*WEB-75551**RC**END*/


--File:Tables:dbo:LinkRefRejectionCodeRefRejectionValidator:DML
/*WEB-75551**RC**START*/
GO
EXEC dbo.LinkRefRejectionCodeRefRejectionValidator_InsertIfNotExists @RejectionCode ='EC4103',@RejectionValidatorCode = 'V1'
GO
EXEC dbo.LinkRefRejectionCodeRefRejectionValidator_InsertIfNotExists @RejectionCode = 'EC4104',@RejectionValidatorCode = 'V4',@MappingPropertyName='RefIncomeGroupId',@MatchingReferenceDataPropertyNames='Code',@ReferenceDataStoredProcedureName='dbo.RefRejectionValidator_GetIncomeRangeData'
GO   
EXEC dbo.LinkRefRejectionCodeRefRejectionValidator_InsertIfNotExists @RejectionCode = 'EC4105' ,@RejectionValidatorCode = 'V82'
GO
EXEC dbo.LinkRefRejectionCodeRefRejectionValidator_InsertIfNotExists @RejectionCode =  'EC4106', @RejectionValidatorCode = 'V5',@MappingPropertyName='Income'
GO
EXEC dbo.LinkRefRejectionCodeRefRejectionValidator_InsertIfNotExists @RejectionCode = 'EC4107',@RejectionValidatorCode = 'V148' , @PropertyValueLength = 2 , @ValidationComparisonTypeCode = 'LessThanEqualTo',@MappingPropertyName ='Networth'
GO
EXEC dbo.LinkRefRejectionCodeRefRejectionValidator_InsertIfNotExists @RejectionCode = 'EC4108' ,@RejectionValidatorCode = 'V82'
GO
EXEC dbo.LinkRefRejectionCodeRefRejectionValidator_InsertIfNotExists @RejectionCode  = 'EC4109',@RejectionValidatorCode = 'V23',@DateFormat = 'dd/MM/yyyy',@MappingPropertyName='FromDate'
GO
/*WEB-75551**RC**END*/

--File:Tables:dbo:LinkRefRejectionCodeRefRejectionTag:DML
/*WEB-75551**RC**START*/
GO
EXEC dbo.LinkRejectionCodeRefRejectionTag_InsertIfNoExists @ErrorCode = 'EC4103', @RejectionTagCodes = 'ProductAccountCreateUpdate', @IsMapped = 1
GO
EXEC dbo.LinkRejectionCodeRefRejectionTag_InsertIfNoExists @ErrorCode = 'EC4104', @RejectionTagCodes = 'ProductAccountCreateUpdate', @IsMapped = 1
GO
EXEC dbo.LinkRejectionCodeRefRejectionTag_InsertIfNoExists @ErrorCode = 'EC4105', @RejectionTagCodes = 'ProductAccountCreateUpdate', @IsMapped = 1
GO
EXEC dbo.LinkRejectionCodeRefRejectionTag_InsertIfNoExists @ErrorCode = 'EC4106', @RejectionTagCodes = 'ProductAccountCreateUpdate', @IsMapped = 1
GO
EXEC dbo.LinkRejectionCodeRefRejectionTag_InsertIfNoExists @ErrorCode = 'EC4107', @RejectionTagCodes = 'ProductAccountCreateUpdate', @IsMapped = 1
GO
EXEC dbo.LinkRejectionCodeRefRejectionTag_InsertIfNoExists @ErrorCode = 'EC4108', @RejectionTagCodes = 'ProductAccountCreateUpdate', @IsMapped = 1
GO
EXEC dbo.LinkRejectionCodeRefRejectionTag_InsertIfNoExists @ErrorCode = 'EC4109', @RejectionTagCodes = 'ProductAccountCreateUpdate', @IsMapped = 1
GO
/*WEB-75551**RC**END*/     
select * from RefRejectionTag where Name like'%product%'

--File:StoredProcedures:dbo:RefRejectionValidator_GetIncomeRangeData
/*WEB-75551**RC**START*/
GO
CREATE PROCEDURE dbo.RefRejectionValidator_GetIncomeRangeData  
(  
 @RejectionCodeRejectionValidatorLinkId INT  
)  
AS  
BEGIN  
  
	 SELECT ref.RefIncomeGroupId AS Id,Name,Code  
	 FROM dbo.RefIncomeGroup ref  
	 WHERE ref.Code BETWEEN 1 AND 6
	 END  
GO
/*WEB-75551**RC**END*/   


--File:StoredProcedures:dbo:StagingClientDetails_Validate
/*WEB-75551**RC**START*/
GO
ALTER PROCEDURE dbo.StagingClientDetails_Validate    
(    
	 @Guid VARCHAR(50),    
	 @ErrorTags VARCHAR(MAX)    
)    
AS    
BEGIN    
   DECLARE @InternalGuid VARCHAR(50), @InternalErrorTags VARCHAR(MAX), @RefEntityTypeId INT, @ParentComapnyId INT ,@DebtsubTypeEnumTypeId INT ,  
   @RefClientEntityTypeId INT  
 SET @InternalGuid=@Guid    
 SET @InternalErrorTags=@ErrorTags  
 SET @RefClientEntityTypeId = dbo.GetEntityTypeByCode('Client')    
 SELECT  @DebtsubTypeEnumTypeId = ref.RefEnumTypeId FROM dbo.RefEnumType ref WHERE ref.[Name] = 'ClientDebtSubType'  
    
 DECLARE @YesEumValueId INT,@NoEumValueId INT    
    SET @YesEumValueId= dbo.GetEnumValueId('YesNoOption','Yes')    
    
 SELECT @ParentComapnyId = RefParentCompanyId FROM dbo.RefParentCompany     
 WHERE UniqueId=(Select top(1) ParentCompany from dbo.StagingClientDetail WHERE GUID = @InternalGuid);    
    
    SET @RefEntityTypeId = dbo.GetEntityTypeByParentCompanyIdAndParentEntityTypeCode(@ParentComapnyId,'BaseCustomer');    
    
 DECLARE @BankCodeandBankNameCombinationEC1705 INT, @FirstHolderSourceSystemNameandFirstHolderSourceSystemCustomerCodeCombinationEC2281 INT, @ModuleApplicableIsMandatoryEC1730 INT,    
 @DefaultAmountMandatoryEC2320 INT, @DefaultDateIsMandatoryEC2280 INT,@UniqueKeyValidationEC2996 INT, @DPIdValidationEC2848 INT ,@DebtSubTypeValidationEC4050 INT,@IncomeRangeValidationEC4105 INT,   
 @IncomeFromdateValidationEC4108 INT  
  
 SELECT @BankCodeandBankNameCombinationEC1705 = dbo.GetActiveRefRejectionCodeIdByTags('EC1705',@InternalErrorTags)    
 SELECT @FirstHolderSourceSystemNameandFirstHolderSourceSystemCustomerCodeCombinationEC2281 = dbo.GetActiveRefRejectionCodeIdByTags('EC2281',@InternalErrorTags)    
 SELECT @ModuleApplicableIsMandatoryEC1730  = dbo.GetActiveRefRejectionCodeIdByTags('EC1730',@InternalErrorTags)    
 SELECT @DefaultAmountMandatoryEC2320  = dbo.GetActiveRefRejectionCodeIdByTags('EC2320',@InternalErrorTags)    
 SELECT @DefaultDateIsMandatoryEC2280 = dbo.GetActiveRefRejectionCodeIdByTags('EC2280',@InternalErrorTags)    
 SELECT @UniqueKeyValidationEC2996 = dbo.GetActiveRefRejectionCodeIdByTags('EC2996',@InternalErrorTags)    
 SELECT @DPIdValidationEC2848 = dbo.GetActiveRefRejectionCodeIdByTags('EC2848',@InternalErrorTags)    
 SELECT @DebtSubTypeValidationEC4050 = dbo.GetActiveRefRejectionCodeIdByTags('EC4050',@InternalErrorTags)    
 SELECT @IncomeRangeValidationEC4105 = dbo.GetActiveRefRejectionCodeIdByTags('EC4105',@InternalErrorTags)    
 SELECT @IncomeFromdateValidationEC4108 = dbo.GetActiveRefRejectionCodeIdByTags('EC4108',@InternalErrorTags)  
     
  SELECT  history.ProductAccountType,history.ProductAccountNumber    
  INTO #RepeatedClientIntegrationId        
  FROM dbo.StagingClientDetail history    
  WHERE history.GUID = @InternalGuid    
  GROUP BY history.ProductAccountType,history.ProductAccountNumber    
  HAVING COUNT(1)>1    
    
  SELECT staging.StagingClientDetailId,  
   ty.CustomerTypeCategoryRefEnumValueId  
  INTO #temp  
  FROM dbo.StagingClientRelationDetail staging    
  INNER JOIN dbo.RefExternalSystem externalSystem ON externalSystem.[Name] = staging.FirstHolderSourceSystemName  AND @DebtSubTypeValidationEC4050 IS NOT NULL AND staging.[GUID] = @InternalGuid  
  INNER JOIN dbo.CoreCRMIdentification custIdent ON custIdent.RefEntityTypeId = @RefEntityTypeId AND custIdent.RefIdentificationTypeId = externalSystem.RefIdentificationTypeId AND custIdent.IdNumber = staging.FirstHolderSourceSystemCustomerCode    
  INNER JOIN dbo.RefCRMCustomer ref ON ref.RefCRMCustomerId = custIdent.EntityId  
  INNER JOIN dbo.RefCustomerType ty ON ty.RefCustomerTypeId = ref.RefCustomerTypeId   
  
  SELECT   
   t.StagingClientDetailId,  
   t.FromDate,
   t.ToDate
  INTO #templatestIncomeFromDate  
	 FROM (SELECT   
		  staging.StagingClientDetailId,  
		  link.FromDate,  
		  link.ToDate,  
		  ROW_NUMBER() OVER (PARTITION BY link.RefClientId ORDER BY link.FromDate DESC) RN   
	   FROM dbo.StagingClientDetail staging   
	   INNER JOIN dbo.RefClientDatabaseEnum en ON @IncomeFromdateValidationEC4108 IS NOT NULL AND staging.[GUID] = @InternalGuid AND  en.DatabaseType = staging.ProductAccountType
	   INNER JOIN dbo.RefClient ref ON staging.ProductAccountNumber = ref.ClientId AND ref.RefClientDatabaseEnumId = en.RefClientDatabaseEnumId
	   INNER JOIN dbo.LinkRefClientRefIncomeGroup link ON link.RefClientId = ref.RefClientId)t  
  WHERE t.RN = 1  
   
 SELECT t.ReferenceNumber,    
        t.RefRejectionCodeId    
 FROM     
 (    
  SELECT staging.ReferenceNumber,      
   @BankCodeandBankNameCombinationEC1705 AS RefRejectionCodeId    
  FROM dbo.StagingClientDetail staging    
  INNER JOIN dbo.StagingClientBankDetail bank ON staging.[Guid]=bank.[Guid] AND staging.ReferenceNumber=bank.ReferenceNumber AND bank.BankName <> dbo.GetBankName(bank.BankCode)    
  WHERE @BankCodeandBankNameCombinationEC1705 IS NOT NULL AND    
     staging.[GUID]=@InternalGuid    
    
  UNION    
    
   SELECT staging.ReferenceNumber,      
   @FirstHolderSourceSystemNameandFirstHolderSourceSystemCustomerCodeCombinationEC2281 AS RefRejectionCodeId    
  FROM dbo.StagingClientRelationDetail staging    
  LEFT JOIN dbo.RefExternalSystem externalSystem ON externalSystem.Name = staging.FirstHolderSourceSystemName    
  LEFT JOIN dbo.CoreCRMIdentification custIdent ON custIdent.RefEntityTypeId = @RefEntityTypeId AND custIdent.RefIdentificationTypeId = externalSystem.RefIdentificationTypeId AND custIdent.IdNumber = staging.FirstHolderSourceSystemCustomerCode    
  WHERE @FirstHolderSourceSystemNameandFirstHolderSourceSystemCustomerCodeCombinationEC2281 IS NOT NULL    
     AND custIdent.CoreCRMIdentificationId IS NULL AND    
     staging.[GUID]=@InternalGuid    
    
  UNION    
    
  SELECT staging.ReferenceNumber,      
   @ModuleApplicableIsMandatoryEC1730 AS RefRejectionCodeId    
  FROM dbo.StagingClientDetail staging    
  LEFT JOIN dbo.StagingClientModuleDetail module ON staging.[Guid]=module.[Guid] AND staging.ReferenceNumber=module.ReferenceNumber     
  WHERE @ModuleApplicableIsMandatoryEC1730 IS NOT NULL AND    
        module.ModuleApplicable IS NULL AND    
     staging.[GUID]=@InternalGuid    
    
  UNION    
    
  SELECT staging.ReferenceNumber,      
  CASE WHEN (ISNULL(loan.DefaultAmount,0)=0)    
   THEN @DefaultAmountMandatoryEC2320    
   ELSE NULL     
   END AS RefRejectionCodeId       
  FROM dbo.StagingClientDetail staging    
  INNER JOIN dbo.StagingClientLoanDetail loan ON staging.[Guid]=loan.[Guid] AND staging.ReferenceNumber=loan.ReferenceNumber AND loan.ISDefaulted = 'Yes'    
  WHERE @DefaultAmountMandatoryEC2320 IS NOT NULL AND            
     staging.[GUID]=@InternalGuid    
    
  UNION    
    
  SELECT staging.ReferenceNumber,      
   CASE WHEN ISNULL(stagingloan.DefaultDate,'') = '' AND stagingloan.ISDefaulted='Yes'     
    THEN @DefaultDateIsMandatoryEC2280    
    ELSE NULL    
   END    
   AS RefRejectionCodeId    
  FROM  dbo.StagingClientDetail staging    
  INNER JOIN dbo.StagingClientLoanDetail stagingloan ON staging.[Guid]=stagingloan.[Guid] AND staging.ReferenceNumber=stagingloan.ReferenceNumber     
  WHERE @DefaultDateIsMandatoryEC2280 IS NOT NULL AND staging.[GUID]=@InternalGuid    
    
  UNION    
    
  SELECT history.ReferenceNumber,@UniqueKeyValidationEC2996 AS RefRejectionCodeId    
  FROM dbo.StagingClientDetail history    
  INNER JOIN #RepeatedClientIntegrationId temp ON temp.ProductAccountType = history.ProductAccountType AND temp.ProductAccountNumber = history.ProductAccountNumber    
  WHERE history.GUID = @InternalGuid    
    
  UNION    
    
  SELECT history.ReferenceNumber,@DPIdValidationEC2848 AS RefRejectionCodeId    
  FROM dbo.StagingClientDetail history    
  WHERE @DPIdValidationEC2848 IS NOT NULL    
  AND history.GUID = @InternalGuid    
  AND (    
   (history.ProductAccountType = 'NSDL' OR history.ProductAccountType = 'CDSL')     
   AND     
   ISNULL(history.DPID,'') = ''    
  )    
  
  UNION  
  SELECT staging.ReferenceNumber , @DebtSubTypeValidationEC4050 AS RefRejectionCodeId  
  FROM dbo.StagingClientDetail staging  
  INNER JOIN dbo.RefEnumValue ref ON ref.[Code]=staging.DebtSubtype AND ref.RefEnumTypeId = @DebtsubTypeEnumTypeId  
  INNER JOIN #temp te ON te.StagingClientDetailId = staging.StagingClientDetailId  
  WHERE  @DebtSubTypeValidationEC4050 IS NOT NULL  
  AND staging.[GUID] = @InternalGuid  
  AND ref.ParentRefEnumValueId <> te.CustomerTypeCategoryRefEnumValueId  
  
  UNION  
  SELECT   
  staging.ReferenceNumber,@IncomeRangeValidationEC4105 AS RefRejectionCodeId  
  FROM dbo.StagingClientIncomeDetails staging  
  INNER JOIN  dbo.RefIncomeGroup ref ON @IncomeRangeValidationEC4105 IS NOT NULL  
   AND staging.[GUID] = @InternalGuid AND   
   staging.IncomeGroup = ref.Code AND (ISNULL(staging.Income,'') <> '' AND(TRY_CAST( staging.Income AS BIGINT) < ref.IncomeFrom OR TRY_CAST( staging.Income AS BIGINT) >ref.IncomeTo))  
     
    
  UNION  
    
  SELECT   
	staging.ReferenceNumber,
	@IncomeFromdateValidationEC4108 AS RefRejectionCodeId  
  FROM dbo.StagingClientIncomeDetails staging  
  INNER JOIN #templatestIncomeFromDate temp ON staging.StagingClientDetailId = temp.StagingClientDetailId AND @IncomeFromdateValidationEC4108 IS NOT NULL  
   AND staging.[GUID] = @InternalGuid   
   AND  (TRY_CAST(SUBSTRING(staging.FromDate,4,2)+'/'+SUBSTRING(staging.FromDate,1,2)+'/'+SUBSTRING(staging.FromDate,7,4) AS DATETIME) IS NOT NULL AND(temp.FromDate > CONVERT(DATETIME,staging.FromDate,103) OR  temp.ToDate > CONVERT(DATETIME,staging.FromDate,103)))
    
 )t    
    
END  
GO
/*WEB-75551**RC**END*/  

