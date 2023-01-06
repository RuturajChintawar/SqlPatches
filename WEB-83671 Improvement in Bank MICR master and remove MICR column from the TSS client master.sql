GO
	CREATE PROCEDURE dbo.AddOrUpdate_AddOrUpdateRefBankMicr(
		@RefBankMicrId INT,
		@Bank VARCHAR(100),
		@MicrNo VARCHAR(20) = NULL,
		@IfscCode VARCHAR(100),
		@NeftCode VARCHAR(100) = NULL,
		@BranchDetails VARCHAR(8000) = NULL,
		@Address VARCHAR(500) = NULL,
		@OtherCode VARCHAR(100) = NULL,
		@UserName VARCHAR(50) = NULL
	)
		AS
		BEGIN
			DECLARE @RefBankMicrIdInternal INT,@BankInternal VARCHAR(100),@MicrNoInternal VARCHAR(20),@IfscCodeInternal VARCHAR(100),
				@NeftCodeInternal VARCHAR(100), @BranchDetailsInternal VARCHAR(8000), @AddressInternal VARCHAR(500), @OtherCodeInternal VARCHAR(100),
				@UserNameInternal VARCHAR(50),@CurrDate DATETIME

		 SET @RefBankMicrIdInternal = @RefBankMicrId
		 SET @BankInternal = @Bank
		 SET @MicrNoInternal = @MicrNo
		 SET @IfscCodeInternal = @IfscCode
		 SET @NeftCodeInternal = @NeftCode
		 SET @BranchDetailsInternal = @BranchDetails
		 SET @AddressInternal = @Address
		 SET @OtherCodeInternal = @OtherCode
		 SET @UserNameInternal = @UserName
		 SET @CurrDate = GETDATE()
		 


		 IF ISNULL(@RefBankMicrIdInternal,0) <> 0
			BEGIN
				IF EXISTS(SELECT TOP 1 1 FROM dbo.RefBankMicr bank WHERE bank.IfscCode = @IfscCodeInternal AND bank.MicrNo = @MicrNoInternal AND bank.RefBankMicrId <>  @RefBankMicrIdInternal)
					BEGIN
						RAISERROR ('Duplicate record already present in Bank MICR Master.', 11, 1) WITH SETERROR;    
						RETURN 50010  
					END
				UPDATE bank
				SET bank.[Name] = @BankInternal,
				bank.MicrNo = @MicrNoInternal,
				bank.IfscCode = @IfscCodeInternal,
				bank.NeftCode = @NeftCodeInternal,
				bank.BranchDetails = @BranchDetailsInternal,
				bank.[Address] = @AddressInternal,
				bank.OtherCode = @OtherCodeInternal,
				bank.LastEditedBy = @UserName,
				bank.EditedOn = @CurrDate
				FROM dbo.RefBankMicr bank
				WHERE bank.RefBankMicrId = @RefBankMicrIdInternal
				AND (ISNULL(bank.[Name],'') <> ISNULL(@BankInternal,'') OR
					ISNULL(bank.MicrNo ,'') <> ISNULL(@MicrNoInternal,'') OR
					ISNULL(bank.IfscCode,'') <> ISNULL(@IfscCodeInternal,'') OR
					ISNULL(bank.NeftCode,'') <> ISNULL(@NeftCodeInternal,'') OR
					ISNULL(bank.BranchDetails,'') <> ISNULL(@BranchDetailsInternal,'') OR
					ISNULL(bank.[Address],'') <> ISNULL(@AddressInternal,'') OR
					ISNULL(bank.OtherCode,'') <> ISNULL(@OtherCodeInternal,''))
			END
		 ELSE
			BEGIN

				IF EXISTS(SELECT TOP 1 1 FROM dbo.RefBankMicr bank WHERE bank.IfscCode = @IfscCodeInternal AND bank.MicrNo = @MicrNoInternal )
					BEGIN
						RAISERROR ('Duplicate record already present in Bank MICR Master.', 11, 1) WITH SETERROR;    
						RETURN 50010  
					END
				IF(ISNULL(@MicrNoInternal,'') <> '' AND EXISTS(SELECT TOP 1 1 FROM dbo.RefBankMicr bank WHERE bank.MicrNo = @MicrNoInternal ))
					BEGIN
						   
						DECLARE @ErrorString1 VARCHAR(200) = 'MICR number ' + ISNULL(@MicrNoInternal,'')+' is already present in TrackWizz MICR master.'
						RAISERROR (@ErrorString1, 11, 1) WITH SETERROR;    
						RETURN 50010  
					END
				IF(EXISTS(SELECT TOP 1 1 FROM dbo.RefBankMicr bank WHERE bank.IfscCode = @IfscCodeInternal ))
					BEGIN
						DECLARE @ErrorString2 VARCHAR(200) = 'IFSC Code ' + @IfscCodeInternal +' is already present in TrackWizz MICR master.'
						
						RAISERROR (@ErrorString2, 11, 1) WITH SETERROR;    
						RETURN 50010
					END 
				INSERT INTO dbo.RefBankMicr(
					MicrNo,
					[Name],
					IfscCode,
					NeftCode,
					BranchDetails,
					[Address],
					OtherCode,
					AddedOn,
					AddedBy,
					EditedOn,
					LastEditedBy
				) VALUES(
					@MicrNoInternal,
					@BankInternal,
					@IfscCodeInternal,
					@NeftCodeInternal,
					@BranchDetailsInternal,
					@AddressInternal,
					@OtherCodeInternal,
					@CurrDate,
					@UserNameInternal,
					@CurrDate,
					@UserNameInternal
				)
			END
		END
GO

GO
	ALTER TABLE dbo.StagingTssClientFormat
	DROP COLUMN MicrNo
GO



--WEB-82457-AV-START--
--WEB-82457-AV-START--
GO
ALTER PROCEDURE dbo.RefClient_InsertFromStagingTSSClientFormat
(
	@Guid VARCHAR(500)
)
AS

BEGIN

    DECLARE @CINIndetificationTypeId INT,@DINIndetificationTypeId INT,
	@AadharIndetificationTypeId INT,@ClientTagType INT,@RefEnumTypeId INT,@InternalGuid VARCHAR(500),
	@ErrorString VARCHAR(50),@CdslId INT,@NsdlId INT,@TradingId INT,
	@BaseProductAccountMasterId INT, @SystemDate DATETIME,@AddedBy VARCHAR(MAX), @AddedOn DATETIME, @ColumnTypeId INT,
	@CKYCIndetificationTypeId INT, @ConstutionTypeNRI INT, @TAN INT, @GSTIN VARCHAR(100), @IEC VARCHAR(100), 
	@CompanyWebsite VARCHAR(100), @FCRAStatus VARCHAR(100), @FCRARegistrationState VARCHAR(100), @FCRARegistrationNumber VARCHAR(100)

	SET @ErrorString='Error in Record at Line : '
	SET @InternalGuid = @Guid
	SELECT @CINIndetificationTypeId = RefidentificationTypeId FROM dbo.RefIdentificationType idt WHERE idt.[Name] = 'ROC-MCA-CIN'
	SELECT @DINIndetificationTypeId = RefidentificationTypeId FROM dbo.RefIdentificationType idt WHERE idt.[Name] = 'Director Id Number'
	SELECT @AadharIndetificationTypeId = RefidentificationTypeId FROM dbo.RefIdentificationType idt WHERE idt.[Name] = 'Aadhaar Card'
	SELECT @CKYCIndetificationTypeId = RefidentificationTypeId FROM dbo.RefIdentificationType idt WHERE idt.[Name] = 'CKYC'
	SELECT @ClientTagType = RefEnumTypeId FROM dbo.RefEnumType WHERE [Name] ='ClientTags'
	SELECT @RefEnumTypeId = RefEnumTypeId from dbo.RefEnumType WHERE [Name]='ClientCustomerCategory'
	SELECT @CdslId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType='CDSL'
	SELECT @NsdlId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType='NSDL'
	SELECT @TradingId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType='Trading'
	SELECT @BaseProductAccountMasterId = RefEntityTypeId FROM dbo.RefEntityType WHERE Code = 'BaseProductAccountMaster'
	SELECT @AddedBy = AddedBy FROM dbo.StagingTssClientFormat WHERE [GUID] = @InternalGuid
	SELECT @AddedOn = AddedOn FROM dbo.StagingTssClientFormat WHERE [GUID] = @InternalGuid
	SELECT @ColumnTypeId = RefEnumTypeId FROM dbo.RefEnumType WHERE [Name] = 'ColumnType'
	SELECT @ConstutionTypeNRI = RefConstitutionTypeId FROM dbo.RefConstitutionType WHERE [Name] = 'NRI'
	SET @SystemDate = dbo.GetDateWithoutTime(GETDATE())
	SELECT @IEC = RefidentificationTypeId FROM dbo.RefIdentificationType idt WHERE idt.[Name] = 'IEC'
	SELECT @GSTIN = RefidentificationTypeId FROM dbo.RefIdentificationType idt WHERE idt.[Name] = 'GSTIN'
	SELECT @TAN = RefidentificationTypeId FROM dbo.RefIdentificationType idt WHERE idt.[Name] = 'TAN'


	UPDATE stage SET stage.RefClientDatabaseEnumId = dbenum.RefClientDatabaseEnumId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefClientDatabaseEnum dbenum ON stage.[Database] = dbenum.DatabaseType
    WHERE stage.[GUID] = @InternalGuid

	UPDATE stage SET stage.RefBseMfOccupationTypeId = typ.RefBseMfOccupationTypeId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefBseMfOccupationType typ ON typ.[Name] = stage.BseMfOccupationType
    WHERE stage.[GUID] = @InternalGuid
	
	UPDATE stage SET stage.RefIntermediaryId = inter.RefIntermediaryId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefIntermediary inter ON inter.IntermediaryCode = stage.Intermediary
    WHERE stage.[GUID] = @InternalGuid

	UPDATE stage SET stage.RefConstitutionTypeId = con.RefConstitutionTypeId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefConstitutionType con ON con.[Name] = stage.ConstitutionType
    WHERE stage.[GUID] = @InternalGuid

	UPDATE stage SET stage.RefCustomRiskId = risk.RefCustomRiskId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefCustomRisk risk ON risk.[Name] = stage.CustomRisk
    WHERE stage.[GUID] = @InternalGuid

	UPDATE stage SET stage.RefLocationId = loc.RefLocationId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefLocation loc ON loc.LocationCode = stage.Location
    WHERE stage.[GUID] = @InternalGuid

	UPDATE stage SET stage.RefCountryId = coun.RefCountryId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefCountry coun ON coun.[Name] = stage.Nationality
    WHERE stage.[GUID] = @InternalGuid

	UPDATE stage SET stage.RefClientStatusId = sta.RefClientStatusId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefClientStatus sta ON sta.[Name] = stage.[Status]
    WHERE stage.[GUID] = @InternalGuid

	UPDATE stage SET stage.RefClientAccountStatusId = sta.RefClientAccountStatusId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefClientAccountStatus sta ON sta.[Name] = stage.AccountStatus
	AND sta.RefClientDatabaseEnumId = stage.RefClientDatabaseEnumId
    WHERE stage.[GUID] = @InternalGuid

	UPDATE stage SET stage.RefClientSpecialCategoryId = cat.RefClientSpecialCategoryId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefClientSpecialCategory cat ON cat.[Name] = stage.SpecialCategory
    WHERE stage.[GUID] = @InternalGuid

	UPDATE stage SET stage.CustomerCategoryRefEnumValueId = val.RefEnumValueId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefEnumValue val ON val.[Name] = stage.CustomerCategory AND RefEnumTypeId = @RefEnumTypeId
    WHERE stage.[GUID] = @InternalGuid

	UPDATE stage SET stage.RefCustomerSegmentId = seg.RefCustomerSegmentId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefCustomerSegment seg ON seg.[Name] = stage.AccountSegment AND seg.RefEntityTypeId = @BaseProductAccountMasterId
    WHERE stage.[GUID] = @InternalGuid
	
	UPDATE stage SET stage.RefDesignationId = designation.RefDesignationId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefDesignation designation ON  designation.[Name] = stage.KeyPersonDesignation
	WHERE stage.[GUID] = @InternalGuid
	
	SELECT DISTINCT
		stage.IfscCode
	INTO #distinctIfsc
	FROM dbo.StagingTssClientFormat stage
	WHERE stage.[GUID] = @InternalGuid 

	SELECT
		t.RefBankMicrId, t.IfscCode
	INTO #bankData
	FROM (SELECT
			dis.IfscCode,
			micr.RefBankMicrId,
			ROW_NUMBER() OVER(PARTITION BY micr.IfscCode ORDER BY micr.AddedOn) rn
		FROM #distinctIfsc dis
		INNER JOIN dbo.RefBankMicr micr ON micr.IfscCode = dis.IfscCode
	)t
	WHERE t.rn = 1

	UPDATE stage SET stage.RefBankMicrId = bank.RefBankMicrId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN #bankData bank ON bank.IfscCode = stage.IfscCode
	WHERE stage.[GUID] = @InternalGuid 

	UPDATE stage SET stage.RefBankAccountTypeId = accType.RefBankAccountTypeId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefBankAccountType accType ON accType.Code = stage.AccountType OR  accType.[Name] = stage.AccountType
	WHERE stage.[GUID] = @InternalGuid 

	SELECT
		ROW_NUMBER() OVER(ORDER BY stage.StagingTssClientFormatId) AS LineNumber,
		stage.ClientId,
		stage.DpId,
		stage.Email,
		stage.[NAME],
		stage.CAddressPin,
		stage.PAddressPin,
		stage.RefClientDatabaseEnumId,
		stage.[Database],
		stage.RefBseMfOccupationTypeId,
		stage.BseMfOccupationType,
		stage.RefIntermediaryId,
		stage.Intermediary,
		stage.RefConstitutionTypeId,
		stage.ConstitutionType,
		stage.RefCustomRiskId,
		stage.CustomRisk,
		stage.RefLocationId,
		stage.[Location],
		stage.RefCountryId,
		stage.Nationality,
		stage.RefClientStatusId,
		stage.[Status],
		stage.RefClientAccountStatusId,
		stage.AccountStatus,
		stage.RefClientSpecialCategoryId,
		stage.SpecialCategory,
		stage.CustomerCategoryRefEnumValueId,
		stage.CustomerCategory,
		stage.RecordIdentifier,
		stage.StagingTssClientFormatId,
		stage.pan,
		stage.Phone1,
		stage.Phone2,
		stage.Phone3,
		stage.Mobile,
		stage.SecondHolderFirstName,
		stage.SecondHolderPAN,
		stage.ThirdHolderFirstName,
		stage.ThirdHolderPAN,
		stage.Aadhar,
		stage.CKYC,
		stage.AccountOpeningDate,
		stage.AccountClosingDate,
		stage.CIN,
		stage.DIN,
		stage.IncomeMultiplier,
		stage.NetworthMultiplier,
		stage.RefCustomerSegmentId,
		stage.AccountSegment,
		stage.IncomeGroup,
		stage.Income,
		CASE WHEN stage.Networth IS NULL THEN NULL
		ELSE stage.Networth*100000 END AS Networth,
		stage.FromDate,
		stage.IsFromDateValid,
		stage.IsIncomeValid,
		stage.IsNetworthValid,
		stage.RefBankMicrId,
		stage.IfscCode,
		stage.RefBankAccountTypeId,
		stage.AccountType,
		stage.AccountNo,
		CASE   
		WHEN (ISNULL(stage.IfscCode,'') <> '' AND ISNULL(stage.AccountType,'') <> '' AND ISNULL(stage.AccountNo,'') <> '')  THEN  2
		WHEN (ISNULL(stage.IfscCode,'') = '' AND ISNULL(stage.AccountType,'') = '' AND ISNULL(stage.AccountNo,'') = '')  THEN 0   
			ELSE 1   
		END AS IsBankRequired, 
		stage.KYCUpdationLastDate,
		stage.IsKYCUpdationLastDateValid,
		stage.KeyPersonFirstName,
		stage.KeyPersonMiddleName,
		stage.KeyPersonLastName,
		stage.KeyPersonDesignation,
		stage.RefDesignationId,
		stage.CustodialCode,
		stage.PCMLimit,
		cli.RefClientId,
		cli.RefConstitutionTypeId AS RefConstitutionTypeIdActual
	INTO #TempStaging
	FROM dbo.StagingTssClientFormat stage	
	LEFT JOIN dbo.RefClient cli ON cli.ClientId = stage.ClientId AND ISNULL(cli.DpId,0) = ISNULL(stage.DpId,0) AND cli.RefClientDatabaseEnumId = stage.RefClientDatabaseEnumId
	WHERE stage.[GUID] = @InternalGuid

	CREATE TABLE #ErrorListTable
	(
		LineNumber INT NOT NULL,
		ErrorMessage VARCHAR(MAX) COLLATE DATABASE_DEFAULT,
		StagingTssClientFormatId INT NOT NULL,
		CustodialCode VARCHAR(100),
		ClientId VARCHAR(100)
	)

	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Database - Database can not be blank'
	FROM #TempStaging temp
	WHERE temp.[Database] IS NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Client Id - Client Id can not be blank'
	FROM #TempStaging temp
	WHERE temp.ClientId IS NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Client Name - Client can not be blank'
	FROM #TempStaging temp
	WHERE temp.[Name] IS NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid PAN - PAN can not be blank'
	FROM #TempStaging temp
	WHERE temp.PAN IS NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Client ID - Client ID should be of 16 numeric characters for CDSL database.'
	FROM #TempStaging temp
	WHERE temp.RefClientDatabaseEnumId = @CdslId AND (ISNUMERIC(temp.ClientId) = 0 OR LEN(temp.ClientId) <> 16)
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'DPID should be passed only for NSDL Database.'
	FROM #TempStaging temp
	WHERE temp.RefClientDatabaseEnumId <> @NsdlId AND temp.DpId IS NOT NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'DPID should be present for NSDL database.'
	FROM #TempStaging temp
	WHERE temp.RefClientDatabaseEnumId = @NsdlId AND temp.DpId IS NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Client ID - Client ID should be of 8 numeric characters for NSDL database.'
	FROM #TempStaging temp
	WHERE temp.RefClientDatabaseEnumId = @NsdlId AND (ISNUMERIC(temp.ClientId) = 0 OR LEN(temp.ClientId) <> 8)
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Mobile - It should be 10 digits. '
	FROM #TempStaging temp
	WHERE temp.Mobile IS NOT NULL AND ISNULL(ISNULL(temp.RefConstitutionTypeId,temp.RefConstitutionTypeIdActual),0) <> @ConstutionTypeNRI AND (ISNUMERIC(temp.Mobile) = 0 OR LEN(temp.Mobile) <> 10)
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Mobile - It cannot be more than 15 digits.'
	FROM #TempStaging temp
	WHERE temp.Mobile IS NOT NULL AND ISNULL(temp.RefConstitutionTypeId,temp.RefConstitutionTypeIdActual) = @ConstutionTypeNRI AND ( LEN(temp.Mobile) NOT BETWEEN 0 AND 15)
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Account Closing Date cannot be smaller than Account Opening Date.'
	FROM #TempStaging temp
	WHERE temp.AccountOpeningDate IS NOT NULL
	AND temp.AccountClosingDate IS NOT NULL 
	AND CONVERT(DATETIME, temp.AccountOpeningDate) > CONVERT(DATETIME, temp.AccountClosingDate) 
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Aadhar must be a number. Invalid value - ' + temp.Aadhar
	FROM #TempStaging temp
	WHERE temp.Aadhar IS NOT NULL AND ISNUMERIC(temp.Aadhar) = 0
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'length must be exactly 12 characters. Invalid value - ' + temp.Aadhar
	FROM #TempStaging temp
	WHERE temp.Aadhar IS NOT NULL AND LEN(temp.Aadhar) <> 12
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'ROC-MCA-CIN should have only AlphaNumeric characters for ClientID : '+temp.ClientId
	FROM #TempStaging temp
	WHERE temp.CIN IS NOT NULL AND temp.CIN LIKE '%[^0-9A-Z]%'
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Director Id Number should have only AlphaNumeric characters for ClientID : '+temp.ClientId
	FROM #TempStaging temp
	WHERE temp.DIN IS NOT NULL AND temp.DIN LIKE '%[^0-9A-Z]%'
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Database - ' +temp.[Database]
	FROM #TempStaging temp
	WHERE temp.RefClientDatabaseEnumId IS NULL AND temp.[Database] IS NOT NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'DpId should be 6 digits.'
	FROM #TempStaging temp
	WHERE temp.DpId IS NOT NULL AND (ISNUMERIC(temp.DpId) = 0 OR LEN(REPLACE(temp.DpId,'IN','')) <> 6)
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Occupation - '+temp.BseMfOccupationType
	FROM #TempStaging temp
	WHERE temp.RefBseMfOccupationTypeId IS NULL AND temp.BseMfOccupationType IS NOT NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Constitution Type - '+temp.ConstitutionType
	FROM #TempStaging temp
	WHERE temp.RefConstitutionTypeId IS NULL AND temp.ConstitutionType IS NOT NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Intermediary Code - ' + temp.Intermediary
	FROM #TempStaging temp
	WHERE temp.RefIntermediaryId IS NULL AND temp.Intermediary IS NOT NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Nationality - ' + temp.Nationality
	FROM #TempStaging temp
	WHERE temp.RefCountryId IS NULL AND temp.Nationality IS NOT NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Location Code - ' + temp.[Location]
	FROM #TempStaging temp
	WHERE temp.RefLocationId IS NULL AND temp.[Location] IS NOT NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Custom Risk - ' + temp.CustomRisk
	FROM #TempStaging temp
	WHERE temp.RefCustomRiskId IS NULL AND temp.CustomRisk IS NOT NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Account Status - ' + temp.AccountStatus
	FROM #TempStaging temp
	WHERE temp.RefClientAccountStatusId IS NULL AND temp.AccountStatus IS NOT NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Special Category - ' + temp.SpecialCategory
	FROM #TempStaging temp
	WHERE temp.RefClientSpecialCategoryId IS NULL AND temp.SpecialCategory IS NOT NULL
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Wrong value passed in Account segment cloumn - ' + temp.AccountSegment
	FROM #TempStaging temp
	WHERE temp.RefCustomerSegmentId IS NULL AND ISNULL(temp.AccountSegment,'') <> ''
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid IFSC Code - IFSC Code is not as per TrackWizz Bank MICR master for ClientID : '+temp.ClientId
	FROM #TempStaging temp
	WHERE temp.IsBankRequired= 2 AND temp.RefBankMicrId IS NULL 
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Bank Account Type - Bank Account Type is not as per TrackWizz format for ClientID : '+temp.ClientId
	FROM #TempStaging temp
	WHERE temp.IsBankRequired= 2 AND temp.RefBankAccountTypeId IS NULL AND ISNULL(temp.AccountType,'') <> ''
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid value enterd - IFSC Code or Bank Account type or Bank Account No cannot be empty for ClientID : '+temp.ClientId
	FROM #TempStaging temp
	WHERE temp.IsBankRequired =  1
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT  
		temp.LineNumber,    
		temp.StagingTssClientFormatId,    
		'Record contains Invalid Date of Last KYC Updation'
	FROM #TempStaging temp
	WHERE temp.KYCUpdationLastDate IS NOT NULL  AND temp.IsKYCUpdationLastDateValid=0
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Keyperson Last Name - Keyperson Last Name cannot be empty for ClientID : '+temp.ClientId
	FROM #TempStaging temp
	WHERE ISNULL(temp.KeyPersonLastName,'') = '' AND ISNULL(temp.KeyPersonDesignation,'') <> ''
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Designation - Designation cannot be empty for ClientID : '+temp.ClientId
	FROM #TempStaging temp
	WHERE ISNULL(temp.KeyPersonDesignation,'') = '' AND ISNULL(temp.KeyPersonLastName,'') <> ''
	---------------------------------------------------------------------------------
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Invalid Designation - Designation is not as per TrackWizz format for ClientID : '+temp.ClientId
	FROM #TempStaging temp
	WHERE temp.RefDesignationId IS NULL AND ISNULL(temp.KeyPersonDesignation,'') <> ''
	---------------------------------------------------------------------------------
	 INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
		SELECT
			temp.LineNumber,
			temp.StagingTssClientFormatId,
			'Invalid Value entered : Character and special characters are not allowed in the PCM Limit field for ClientId :'+temp.ClientId
		FROM #TempStaging temp
		WHERE ISNULL(temp.PCMLimit,'')<>'' AND temp.PCMLimit like '%[^0-9./]%' --ISNUMERIC(temp.PCMLimit) =0 
   -------------------------------------------------------------------------------
   SELECT
	temp.CustodialCode,temp.StagingTssClientFormatId,
	ROW_NUMBER() OVER (PARTITION BY temp.CustodialCode ORDER BY temp.StagingTssClientFormatId) AS rownum
	INTO #tempDupCheck
	FROM #tempStaging temp

	SELECT DISTINCT 
	CustodialCode
	INTO #duplicateRecords
	FROM #tempDupCheck
	WHERE rownum>1

   INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage,CustodialCode)
	SELECT
		stage.LineNumber ,
		stage.StagingTssClientFormatId,
		'Duplicate Custodial code present in file',
		stage.CustodialCode
	FROM #TempStaging stage
	INNER JOIN #duplicateRecords dup ON dup.CustodialCode=stage.CustodialCode 
	WHERE stage.CustodialCode =stage.CustodialCode GROUP BY stage.LineNumber ,stage.StagingTssClientFormatId,stage.CustodialCode,stage.ClientId
  ---------------------------------------------------------------------------------
 --   INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage ,CustodialCode,ClientId)
	--SELECT
	--	stage.LineNumber ,
	--	stage.StagingTssClientFormatId,
	--	'Duplicate Custodial code present in file',
	--	stage.CustodialCode,
	--	stage.ClientId
	--FROM #TempStaging stage
	--WHERE stage.CustodialCode =stage.CustodialCode AND stage.ClientId !=stage.ClientId GROUP BY stage.LineNumber ,
	--	stage.StagingTssClientFormatId,stage.CustodialCode,stage.ClientId
	-----------------------------------------------------------------------------
	DECLARE @CustodialCodeRefClientKeyId INT
	SELECT @CustodialCodeRefClientKeyId=RefClientKeyId from dbo.RefClientKey WHERE Code='CustodialCode'

	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		tempstage.LineNumber,
		tempstage.StagingTssClientFormatId,
		 'Custodial Code '+tempstage.CustodialCode+' is already present in the database'
	FROM dbo.CoreClientKeyValueInfo temp 
	INNER JOIN #TempStaging tempstage ON tempstage.CustodialCode = temp.StringValue and temp.RefClientKeyId=@CustodialCodeRefClientKeyId
	--INNER JOIN dbo.StagingTssClientFormat keyValue ON keyValue.RefClientId != temp.RefClientId AND temp.StringValue=keyValue.CustodialCode AND keyValue.[GUID] = @InternalGuid 
	WHERE ISNULL(tempstage.CustodialCode,'')<>''

   ------------------------------------------------------------------------------------------
	SELECT
		temp.LineNumber,
		temp.RecordIdentifier,
		temp.StagingTssClientFormatId
	INTO #recidenCheck
	FROM #TempStaging temp
	WHERE temp.RefClientId IS NULL

	SELECT stg.RefClientId,
			stg.LineNumber,
			stg.StagingTssClientFormatId,
			ISNULL(stg.FromDate,@SystemDate) AS FromDate
	INTO #tempIncomeDetails
	FROM #TempStaging stg
	INNER JOIN dbo.RefIncomeGroup grp ON grp.Code=stg.IncomeGroup

	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'New From date must be greater than previous From date and To date '   
    FROM #tempIncomeDetails temp   
    INNER JOIN dbo.LinkRefClientRefIncomeGroupLatest link ON link.RefClientId = temp.RefClientId   
	WHERE link.FromDate >= temp.FromDate  OR ISNULL(link.ToDate,link.FromDate) >= temp.FromDate
 

	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Income group should be as per the enum list/ Values '
	FROM #TempStaging temp
	WHERE temp.IncomeGroup IS NOT NULL  AND temp.IncomeGroup NOT IN('1','2','3','4','5','6')

	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Record contains Invalid From Date '
	FROM #TempStaging temp
	WHERE temp.IncomeGroup IS NOT NULL  AND temp.IsFromDateValid=0
	
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Income should have an integer value '
	FROM #TempStaging temp
	INNER JOIN dbo.RefIncomeGroup grp ON grp.Code=temp.IncomeGroup
	WHERE temp.IncomeGroup IS NOT NULL AND temp.IsIncomeValid=0
	
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Income value should be with in the specified range '
	FROM #TempStaging temp
	INNER JOIN dbo.RefIncomeGroup grp ON temp.IsIncomeValid=1 AND grp.Code=temp.IncomeGroup 
	WHERE  (temp.Income < grp.IncomeFrom OR temp.Income > grp.IncomeTo) AND grp.Code IN('1','2','3','4','5','6')
	
	
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Networth should be a real number up to two-digit after the decimal (eg. 35.54) '
	FROM #TempStaging temp
	INNER JOIN dbo.RefIncomeGroup grp ON grp.Code=temp.IncomeGroup
	WHERE  temp.IsNetworthValid=0
	
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT
		temp.LineNumber,
		temp.StagingTssClientFormatId,
		'Clients details not merged as the income group was not present '
	FROM #TempStaging temp
	WHERE  temp.IncomeGroup IS NULL AND (Income IS NOT NULL OR Networth IS NOT NULL OR FromDate IS NOT NULL)
	
	DROP TABLE #TempStaging
	
	;WITH CTE(LineNumber,StagingTssClientFormatId,ClientId,RecordIdentifier)
	AS
	(
		SELECT
			temp.LineNumber,
			temp.StagingTssClientFormatId,
			client.ClientId,
			temp.RecordIdentifier
		FROM  #recidenCheck temp  
		INNER JOIN dbo.RefClient client ON ISNULL(temp.RecordIdentifier,'') <> '' AND ISNULL(client.OnboardingRecordIdentifier,'') = temp.RecordIdentifier
	)
	INSERT INTO #ErrorListTable(LineNumber,StagingTssClientFormatId,ErrorMessage)
	SELECT   
	t.LineNumber ,
	t.StagingTssClientFormatId,
	'Record Identifier already present for Client id - ' + ISNULL(STUFF((
            SELECT ',' + cte2.ClientId
            FROM CTE cte2 
			WHERE cte2.StagingTssClientFormatId = t.StagingTssClientFormatId
            FOR XML PATH('')
            ), 1, 1, '') ,'')
	FROM(
		SELECT DISTINCT LineNumber,StagingTssClientFormatId,RecordIdentifier
		FROM CTE cte1
	) t
	
	---------------------------------------------------------------------------------
	
	UPDATE client
	SET
		DpId = ISNULL(CONVERT(INT,REPLACE(UPPER(stage.Dpid),'IN','')),client.DpId),
		ClientId = ISNULL(stage.ClientId, client.ClientId),
		[Name] = ISNULL(stage.[Name], client.[Name]),
		Email = ISNULL(stage.Email, client.Email),
		RefClientDatabaseEnumId = ISNULL(stage.RefClientDatabaseEnumId,client.RefClientDatabaseEnumId),
		CAddressLine1 = ISNULL(stage.CAddressLine1, client.CAddressLine1),
		CAddressLine2 = ISNULL(stage.CAddressLine2, client.CAddressLine2),
		CAddressLine3 = ISNULL(stage.CAddressLine3, client.CAddressLine3),
		CAddressCity = ISNULL(stage.CAddressCity, client.CAddressCity),
		CAddressState = ISNULL(stage.CAddressState, client.CAddressState),
		CAddressCountry = ISNULL(stage.CAddressCountry, client.CAddressCountry),
		CAddressPin = ISNULL(stage.CAddressPin, client.CAddressPin),
		PAddressLine1 = ISNULL(stage.PAddressLine1, client.PAddressLine1),
		PAddressLine2 = ISNULL(stage.PAddressLine2, client.PAddressLine2),
		PAddressLine3 = ISNULL(stage.PAddressLine3, client.PAddressLine3),
		PAddressCity = ISNULL(stage.PAddressCity, client.PAddressCity),
		PAddressState = ISNULL(stage.PAddressState, client.PAddressState),
		PAddressCountry = ISNULL(stage.PAddressCountry, client.PAddressCountry),
		PAddressPin = ISNULL(stage.PAddressPin, client.PAddressPin),
		Mobile = ISNULL(stage.Mobile, client.Mobile),
		Phone1 = ISNULL(stage.Phone1, client.Phone1),
		Phone2 = ISNULL(stage.Phone2, client.Phone2),
		Phone3 = ISNULL(stage.Phone3, client.Phone3),
		PAN = ISNULL(stage.PAN, client.PAN),
		SecondHolderFirstName = ISNULL(stage.SecondHolderFirstName, client.SecondHolderFirstName),
		SecondHolderMiddleName = ISNULL(stage.SecondHolderMiddleName, client.SecondHolderMiddleName),
		SecondHolderLastName = ISNULL(stage.SecondHolderLastName, client.SecondHolderLastName),
		SecondHolderPAN = ISNULL(stage.SecondHolderPAN, client.SecondHolderPAN),
		ThirdHolderFirstName = ISNULL(stage.ThirdHolderFirstName, client.ThirdHolderFirstName),
		ThirdHolderMiddleName = ISNULL(stage.ThirdHolderMiddleName, client.ThirdHolderMiddleName),
		ThirdHolderLastName = ISNULL(stage.ThirdHolderLastName, client.ThirdHolderLastName),
		ThirdHolderPAN = ISNULL(stage.ThirdHolderPAN, client.ThirdHolderPAN),
		FIcustId = ISNULL(stage.FICustId, client.FIcustId),
		NetworthMultiplier = ISNULL(CONVERT(DECIMAL(20,2),stage.NetworthMultiplier), client.NetworthMultiplier),
		IncomeMultiplier = ISNULL(CONVERT(DECIMAL(20,2),stage.IncomeMultiplier), client.IncomeMultiplier),
		FatherName = ISNULL(stage.FatherName, client.FatherName),
		Nationality = ISNULL(stage.RefCountryId, client.Nationality),
		FamilyCode = ISNULL(stage.FamilyCode, client.FamilyCode),
		PlaceOfBirth = ISNULL(stage.PlaceOfBirth, client.PlaceOfBirth),
		CountryOfBirth = ISNULL(stage.CountryOfBirthText, client.CountryOfBirth),
		IsWhiteListed = ISNULL(stage.IsWhiteListed, client.IsWhiteListed),
		IsFamilyDeclaration = ISNULL(stage.IsFamilyDeclaration, client.IsFamilyDeclaration),
		RefClientStatusId = ISNULL(stage.RefClientStatusId,client.RefClientStatusId),
		RefClientAccountStatusId = ISNULL(stage.RefClientAccountStatusId,client.RefClientAccountStatusId),
		RefClientSpecialCategoryId = ISNULL(stage.RefClientSpecialCategoryId,client.RefClientSpecialCategoryId),
		SuspendedDate = ISNULL(stage.SuspendedDate, client.SuspendedDate),
		AccountClosingDate = ISNULL(stage.AccountClosingDate, client.AccountClosingDate),
		AccountOpeningDate = ISNULL(stage.AccountOpeningDate, client.AccountOpeningDate),
		Dob = ISNULL(stage.Dob, client.Dob),
		RefBseMfOccupationTypeId = ISNULL(stage.RefBseMfOccupationTypeId,client.RefBseMfOccupationTypeId),
		Gender = ISNULL(stage.Gender, client.Gender),
		RefIntermediaryId = ISNULL(stage.RefIntermediaryId,client.RefIntermediaryId),
		RefConstitutionTypeId = ISNULL(stage.RefConstitutionTypeId,client.RefConstitutionTypeId),
		EmployerName = ISNULL(stage.EmployerName, client.EmployerName),
		EmployerAddress = ISNULL(stage.EmployerAddress, client.EmployerAddress),
		EmployerBusinessNature = ISNULL(stage.EmployerBusinessNature, client.EmployerBusinessNature),
		RefCustomRiskId = ISNULL(stage.RefCustomRiskId,client.RefCustomRiskId),
		RefLocationId = ISNULL(stage.RefLocationId,client.RefLocationId),
		CustomerCategoryRefEnumValueId = ISNULL(stage.CustomerCategoryRefEnumValueId,client.CustomerCategoryRefEnumValueId),
		OnboardingRecordIdentifier = ISNULL(stage.RecordIdentifier,client.OnboardingRecordIdentifier),
		CIN = ISNULL(stage.CIN,client.CIN),
		Aadhar = ISNULL(stage.Aadhar,client.Aadhar),

		LastEditedBy = stage.AddedBy,
		EditedOn = stage.AddedOn
	FROM dbo.StagingTssClientFormat stage 
	INNER JOIN dbo.RefClient client ON client.ClientId = stage.ClientId
	AND ISNULL(client.DpId,0) = ISNULL(stage.DpId,0)
	AND client.RefClientDatabaseEnumId = stage.RefClientDatabaseEnumId
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid 
	AND ErrorTable.StagingTssClientFormatId IS NULL
	AND (
		   dbo.IsVarcharNotEqual(stage.ClientId, client.ClientId) = 1  
		OR dbo.IsVarcharNotEqual(stage.FamilyCode, client.FamilyCode) = 1  
		OR dbo.IsVarcharNotEqual(stage.[Name], client.[Name]) = 1  
		OR dbo.IsVarcharNotEqual(stage.Email, client.Email) = 1
		OR  dbo.IsVarcharNotEqual(stage.PAN, client.PAN) = 1  	
		OR dbo.IsVarcharNotEqual(stage.CAddressLine1, client.CAddressLine1) = 1  
	    OR dbo.IsVarcharNotEqual(stage.CAddressLine2, client.CAddressLine2) = 1  
	    OR dbo.IsVarcharNotEqual(stage.CAddressLine3, client.CAddressLine3) = 1  
	    OR dbo.IsVarcharNotEqual(stage.CAddressCity, client.CAddressCity) = 1  
	    OR dbo.IsVarcharNotEqual(stage.CAddressState, client.CAddressState) = 1  
		OR dbo.IsVarcharNotEqual(stage.CAddressCountry, client.CAddressCountry) = 1  
		OR dbo.IsVarcharNotEqual(stage.CAddressPin, client.CAddressPin) = 1  
	    OR dbo.IsVarcharNotEqual(stage.PAddressLine1, client.PAddressLine1)  = 1  
	    OR dbo.IsVarcharNotEqual(stage.PAddressLine2, client.PAddressLine2)  = 1  
	    OR dbo.IsVarcharNotEqual(stage.PAddressLine3, client.PAddressLine3)  = 1  
	    OR dbo.IsVarcharNotEqual(stage.PAddressCity, client.PAddressCity)  = 1  
	    OR dbo.IsVarcharNotEqual(stage.PAddressState, client.PAddressState)  = 1  
	    OR dbo.IsVarcharNotEqual(stage.PAddressCountry, client.PAddressCountry)= 1  
	    OR dbo.IsVarcharNotEqual(stage.PAddressPin, client.PAddressPin)   = 1  
	    OR dbo.IsVarcharNotEqual(stage.Phone1, client.Phone1) = 1  
	    OR dbo.IsVarcharNotEqual(stage.Phone2, client.Phone2) = 1  
	    OR dbo.IsVarcharNotEqual(stage.Phone3, client.Phone3) = 1  
	    OR dbo.IsVarcharNotEqual(stage.Mobile, client.Mobile) = 1
		OR dbo.IsVarcharNotEqual(stage.Gender, client.Gender) = 1  
		OR dbo.IsVarcharNotEqual(stage.SecondHolderFirstName, client.SecondHolderFirstName) = 1  
		OR dbo.IsVarcharNotEqual(stage.SecondHolderMiddleName, client.SecondHolderMiddleName) = 1  
		OR dbo.IsVarcharNotEqual(stage.SecondHolderLastName, client.SecondHolderLastName) = 1  
		OR dbo.IsVarcharNotEqual(stage.SecondHolderPan, client.SecondHolderPAN) = 1  
		OR dbo.IsVarcharNotEqual(stage.ThirdHolderFirstName, client.ThirdHolderFirstName) = 1  
		OR dbo.IsVarcharNotEqual(stage.ThirdHolderMiddleName, client.ThirdHolderMiddleName) = 1  
		OR dbo.IsVarcharNotEqual(stage.ThirdHolderLastName, client.ThirdHolderLastName) = 1  
		OR dbo.IsVarcharNotEqual(stage.ThirdHolderPan, client.ThirdHolderPAN) = 1  
		OR dbo.IsVarcharNotEqual(stage.EmployerName, client.EmployerName) = 1  
		OR dbo.IsVarcharNotEqual(stage.EmployerAddress, client.EmployerAddress) = 1  
		OR dbo.IsVarcharNotEqual(stage.EmployerBusinessNature, client.EmployerBusinessNature) = 1  
		OR dbo.IsVarcharNotEqual(stage.FatherName, client.FatherName) = 1 
		OR dbo.IsVarcharNotEqual(stage.CIN, client.CIN) = 1
		OR dbo.IsVarcharNotEqual(stage.Aadhar, client.Aadhar) = 1
		OR dbo.IsVarcharNotEqual(stage.PlaceOfBirth, client.PlaceOfBirth) = 1  
		OR dbo.IsVarcharNotEqual(stage.CountryOfBirthText, client.CountryOfBirth) = 1
		OR (stage.IncomeMultiplier IS NOT NULL AND stage.IncomeMultiplier <> client.IncomeMultiplier)  
		OR (stage.NetworthMultiplier IS NOT NULL AND stage.NetworthMultiplier <> client.NetworthMultiplier)  
		OR (stage.AccountOpeningDate IS NOT NULL AND stage.AccountOpeningDate <> client.AccountOpeningDate)  
		OR (stage.AccountClosingDate IS NOT NULL AND stage.AccountClosingDate <> client.AccountClosingDate)
		OR (stage.Dob IS NOT NULL AND stage.Dob <> client.Dob)
		OR (stage.SuspendedDate IS NOT NULL AND stage.SuspendedDate <> client.SuspendedDate)
		OR (stage.RefConstitutionTypeId IS NOT NULL AND stage.RefConstitutionTypeId <> client.RefConstitutionTypeId)
		OR (stage.RefCountryId IS NOT NULL AND stage.RefCountryId <> client.Nationality)  
        OR (stage.RefCustomRiskId IS NOT NULL AND stage.RefCustomRiskId <> client.RefCustomRiskId)
		OR (stage.DpId IS NOT NULL AND stage.DpId <> client.DpId)  
		OR (stage.RefLocationId IS NOT NULL AND stage.RefLocationId <> client.RefLocationId)
		OR (stage.RefClientAccountStatusId IS NOT NULL AND stage.RefClientAccountStatusId <> client.RefClientAccountStatusId)
		OR (stage.FICustId IS NOT NULL AND stage.FICustId <> client.FICustId)  
		OR (stage.RefClientStatusId IS NOT NULL AND stage.RefClientStatusId <> client.RefClientStatusId ) 
		OR  dbo.IsVarcharNotEqual(stage.RecordIdentifier, client.OnboardingRecordIdentifier) = 1
		OR (stage.RefIntermediaryId IS NOT NULL AND stage.RefIntermediaryId <> client.RefIntermediaryId)  
		OR (stage.RefClientSpecialCategoryId IS NOT NULL AND stage.RefClientSpecialCategoryId <> client.RefClientSpecialCategoryId)  
		OR (stage.RefClientDatabaseEnumId IS NOT NULL AND stage.RefClientDatabaseEnumId <> client.RefClientDatabaseEnumId)
		OR (stage.RefBseMfOccupationTypeId IS NOT NULL AND stage.RefBseMfOccupationTypeId <> client.RefBseMfOccupationTypeId)
		OR (stage.IsWhiteListed IS NOT NULL AND stage.IsWhiteListed <> client.IsWhiteListed)  
		OR (stage.IsFamilyDeclaration IS NOT NULL AND (stage.IsFamilyDeclaration <> client.IsFamilyDeclaration  OR client.IsFamilyDeclaration IS NULL))  
		OR (stage.CustomerCategoryRefEnumValueId IS NOT NULL AND stage.CustomerCategoryRefEnumValueId <> client.CustomerCategoryRefEnumValueId)
	)

	INSERT INTO dbo.RefClient(
	ClientId,
	[Name],
	DpId,
	RefClientDatabaseEnumId,
	Email,
	CAddressLine1,
	CAddressLine2,
	CAddressLine3,
	CAddressCity,
	CAddressCountry,
	CAddressState,
	PAddressLine1,
	PAddressLine2,
	PAddressLine3,
	PAddressCity,
	PAddressCountry,
	PAddressState,
	PAddressPin,
	CAddressPin,
	Phone1,
	Phone2,
	Phone3,
	PAN,
	Mobile,
	SecondHolderFirstName,
	SecondHolderMiddleName,
	SecondHolderLastName,
	SecondHolderPAN,
	ThirdHolderFirstName,
	ThirdHolderMiddleName,
	ThirdHolderLastName,
	ThirdHolderPAN,
	FIcustId,
	NetworthMultiplier,
	IncomeMultiplier,
	FatherName,
	Nationality,
	FamilyCode,
	PlaceOfBirth,
	CountryOfBirth,
	IsWhiteListed,
	SuspendedDate,
	IsFamilyDeclaration,
	RefClientStatusId,
	RefClientAccountStatusId,
	RefClientSpecialCategoryId,
	AccountClosingDate,
	AccountOpeningDate,
	Dob,
	RefBseMfOccupationTypeId,
	Gender,
	RefIntermediaryId,
	RefConstitutionTypeId,
	EmployerName,
	EmployerAddress,
	EmployerBusinessNature,
	RefCustomRiskId,
	RefLocationId,
	CustomerCategoryRefEnumValueId,
	OnboardingRecordIdentifier,
	CIN,
	Aadhar,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn
	)
	SELECT
		stage.ClientId,
		stage.[Name],
		CONVERT(INT,REPLACE(UPPER(stage.Dpid),'IN','')),
		stage.RefClientDatabaseEnumId,
		stage.Email,
		stage.CAddressLine1,
		stage.CAddressLine2,
		stage.CAddressLine3,
		stage.CAddressCity,
		stage.CAddressCountry,
		stage.CAddressState,
		stage.PAddressLine1,
		stage.PAddressLine2,
		stage.PAddressLine3,
		stage.PAddressCity,
		stage.PAddressCountry,
		stage.PAddressState,
		stage.PAddressPin,
		stage.CAddressPin,
		stage.Phone1,
		stage.Phone2,
		stage.Phone3,
		stage.PAN,
		stage.Mobile,
		stage.SecondHolderFirstName,
		stage.SecondHolderMiddleName,
		stage.SecondHolderLastName,
		stage.SecondHolderPAN,
		stage.ThirdHolderFirstName,
		stage.ThirdHolderMiddleName,
		stage.ThirdHolderLastName,
		stage.ThirdHolderPAN,
		stage.FIcustId,
		CONVERT(DECIMAL(20,2),stage.NetworthMultiplier),
		CONVERT(DECIMAL(20,2),stage.IncomeMultiplier),
		stage.FatherName,
		stage.RefCountryId,
		stage.FamilyCode,
		stage.PlaceOfBirth,
		stage.CountryOfBirthText,
		stage.IsWhiteListed,
		stage.SuspendedDate,
		stage.IsFamilyDeclaration,
		stage.RefClientStatusId,
		stage.RefClientAccountStatusId,
		stage.RefClientSpecialCategoryId,
		stage.AccountClosingDate,
		stage.AccountOpeningDate,
		stage.Dob,
		stage.RefBseMfOccupationTypeId,
		stage.Gender,
		stage.RefIntermediaryId,
		stage.RefConstitutionTypeId,
		stage.EmployerName,
		stage.EmployerAddress,
		stage.EmployerBusinessNature,
		stage.RefCustomRiskId,
		stage.RefLocationId,
		stage.CustomerCategoryRefEnumValueId,
		stage.RecordIdentifier,
		stage.CIN,
		stage.Aadhar,
		stage.AddedBy,
		stage.AddedOn,
		stage.AddedBy,
		stage.AddedOn
	FROM dbo.StagingTssClientFormat stage 
	LEFT JOIN dbo.RefClient client ON stage.ClientId = client.ClientId
	AND ISNULL(client.DpId,0) = ISNULL(stage.DpId,0)
	AND client.RefClientDatabaseEnumId = stage.RefClientDatabaseEnumId
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE client.RefClientId IS NULL AND stage.[GUID] = @InternalGuid
	AND errorTable.StagingTssClientFormatId IS NULL

	UPDATE stage
		SET RefClientId = client.RefClientId
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefClient client ON client.ClientId = stage.ClientId AND ISNULL(client.DpId,0) = ISNULL(stage.DpId,0)
		AND client.RefClientDatabaseEnumId = stage.RefClientDatabaseEnumId
	WHERE stage.[GUID] = @InternalGuid

	UPDATE clientidentification
		SET
			ExpiryDate = NULL,
			LastEditedBy = stage.AddedBy,
			EditedOn = stage.AddedOn
	FROM dbo.StagingTssClientFormat stage 
	INNER JOIN dbo.CoreClientIdentification clientidentification
		ON clientidentification.RefClientId = stage.RefClientId
		AND clientidentification.RefIdentificationTypeId = @CINIndetificationTypeId 
		AND clientidentification.IdValue = stage.CIN
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE 
	 stage.[GUID] = @InternalGuid
	AND errorTable.StagingTssClientFormatId IS NULL

	UPDATE clientidentification
		SET
			ExpiryDate = NULL,
			LastEditedBy = stage.AddedBy,
			EditedOn = stage.AddedOn
	FROM dbo.StagingTssClientFormat stage 
	INNER JOIN dbo.CoreClientIdentification clientidentification
		ON clientidentification.RefClientId = stage.RefClientId
		AND clientidentification.RefIdentificationTypeId = @DINIndetificationTypeId 
		AND clientidentification.IdValue = stage.DIN
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND
	errorTable.StagingTssClientFormatId IS NULL

	UPDATE clientidentification
		SET
			ExpiryDate = NULL,
			LastEditedBy = stage.AddedBy,
			EditedOn = stage.AddedOn
	FROM dbo.StagingTssClientFormat stage 
	INNER JOIN dbo.CoreClientIdentification clientidentification
		ON clientidentification.RefClientId = stage.RefClientId
		AND clientidentification.RefIdentificationTypeId = @AadharIndetificationTypeId 
		AND clientidentification.IdValue = stage.Aadhar
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE errorTable.StagingTssClientFormatId IS NULL 
		AND stage.[GUID] = @InternalGuid

		UPDATE clientidentification
		SET
			ExpiryDate = NULL,
			LastEditedBy = stage.AddedBy,
			EditedOn = stage.AddedOn,
			IdValue = stage.[TAN]
	FROM dbo.StagingTssClientFormat stage 
	INNER JOIN dbo.CoreClientIdentification clientidentification
		ON clientidentification.RefClientId = stage.RefClientId
		AND clientidentification.RefIdentificationTypeId = @TAN
		AND clientidentification.IdValue <> stage.[TAN]
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE errorTable.StagingTssClientFormatId IS NULL 
		AND stage.[GUID] = @InternalGuid

	UPDATE clientidentification
		SET
			ExpiryDate = NULL,
			LastEditedBy = stage.AddedBy,
			EditedOn = stage.AddedOn,
			IdValue = stage.GSTIN
	FROM dbo.StagingTssClientFormat stage 
	INNER JOIN dbo.CoreClientIdentification clientidentification
		ON clientidentification.RefClientId = stage.RefClientId
		AND clientidentification.RefIdentificationTypeId = @GSTIN 
		AND clientidentification.IdValue <> stage.GSTIN
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE errorTable.StagingTssClientFormatId IS NULL 
		AND stage.[GUID] = @InternalGuid

	UPDATE clientidentification
		SET
			ExpiryDate = NULL,
			LastEditedBy = stage.AddedBy,
			EditedOn = stage.AddedOn,
			IdValue = stage.IEC
	FROM dbo.StagingTssClientFormat stage 
	INNER JOIN dbo.CoreClientIdentification clientidentification
		ON clientidentification.RefClientId = stage.RefClientId
		AND clientidentification.RefIdentificationTypeId = @IEC 
		AND clientidentification.IdValue <> stage.IEC
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE errorTable.StagingTssClientFormatId IS NULL 
		AND stage.[GUID] = @InternalGuid

	INSERT INTO dbo.CoreClientIdentification(
			RefClientId,
			RefIdentificationTypeId,
			IdValue,
			ExpiryDate,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT 
			stage.RefClientId,
			@CINIndetificationTypeId,
			stage.CIN,
			NULL,
			stage.AddedBy,
			stage.AddedOn,
			stage.AddedBy,
			stage.AddedOn
		FROM dbo.StagingTssClientFormat stage 
		LEFT JOIN dbo.CoreClientIdentification clientidentification  ON clientidentification.RefClientId = stage.RefClientId
			AND clientidentification.RefIdentificationTypeId = @CINIndetificationTypeId
		LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
		WHERE
		clientidentification.RefClientId IS NULL 
		 AND errorTable.StagingTssClientFormatId IS NULL
		AND stage.CIN IS NOT NULL
		AND stage.[GUID] = @InternalGuid

	INSERT INTO dbo.CoreClientIdentification(
			RefClientId,
			RefIdentificationTypeId,
			IdValue,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT 
			stage.RefClientId,
			@DINIndetificationTypeId,
			stage.DIN,
			stage.AddedBy,
			stage.AddedOn,
			stage.AddedBy,
			stage.AddedOn
		FROM dbo.StagingTssClientFormat stage 
		LEFT JOIN dbo.CoreClientIdentification clientidentification ON clientidentification.RefClientId = stage.RefClientId
			AND clientidentification.RefIdentificationTypeId = @DINIndetificationTypeId
		LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
		WHERE clientidentification.RefClientId IS NULL 
		AND errorTable.StagingTssClientFormatId IS NULL
		AND stage.DIN IS NOT NULL
		AND stage.[GUID] = @InternalGuid

	INSERT INTO dbo.CoreClientIdentification(
			RefClientId,
			RefIdentificationTypeId,
			IdValue,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT 
			stage.RefClientId,
			@AadharIndetificationTypeId,
			stage.Aadhar,
			stage.AddedBy,
			stage.AddedOn,
			stage.AddedBy,
			stage.AddedOn
		FROM dbo.StagingTssClientFormat stage 
		LEFT JOIN dbo.CoreClientIdentification clientidentification  ON clientidentification.RefClientId = stage.RefClientId
			AND clientidentification.RefIdentificationTypeId = @AadharIndetificationTypeId
		LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
		WHERE clientidentification.RefClientId IS NULL 
		AND errorTable.StagingTssClientFormatId IS NULL
		AND stage.Aadhar IS NOT NULL
		AND stage.[GUID] = @InternalGuid

		INSERT INTO dbo.CoreClientIdentification(
			RefClientId,
			RefIdentificationTypeId,
			IdValue,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT 
			stage.RefClientId,
			@CKYCIndetificationTypeId,
			stage.CKYC,
			stage.AddedBy,
			stage.AddedOn,
			stage.AddedBy,
			stage.AddedOn
		FROM dbo.StagingTssClientFormat stage 
		LEFT JOIN dbo.CoreClientIdentification clientidentification  ON clientidentification.RefClientId = stage.RefClientId
			AND clientidentification.RefIdentificationTypeId = @CKYCIndetificationTypeId AND stage.CKYC = clientidentification.IdValue
		LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
		WHERE errorTable.StagingTssClientFormatId IS NULL
		AND isnull(stage.CKYC,'') <> '' AND isnull(clientidentification.IdValue,'') != stage.CKYC AND (ISNULL(clientidentification.RefClientId,0) <> stage.RefClientId OR clientidentification.CoreClientIdentificationId is null)
		AND stage.[GUID] = @InternalGuid

		INSERT INTO dbo.CoreClientIdentification(
			RefClientId,
			RefIdentificationTypeId,
			IdValue,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT 
			stage.RefClientId,
			@TAN,
			stage.[TAN],
			stage.AddedBy,
			stage.AddedOn,
			stage.AddedBy,
			stage.AddedOn
		FROM dbo.StagingTssClientFormat stage 
		LEFT JOIN dbo.CoreClientIdentification clientidentification  ON clientidentification.RefClientId = stage.RefClientId
			AND clientidentification.RefIdentificationTypeId = @TAN
		LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
		WHERE clientidentification.RefClientId IS NULL 
		AND errorTable.StagingTssClientFormatId IS NULL
		AND stage.[TAN] IS NOT NULL
		AND stage.[GUID] = @InternalGuid

		INSERT INTO dbo.CoreClientIdentification(
			RefClientId,
			RefIdentificationTypeId,
			IdValue,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT 
			stage.RefClientId,
			@GSTIN,
			stage.GSTIN,
			stage.AddedBy,
			stage.AddedOn,
			stage.AddedBy,
			stage.AddedOn
		FROM dbo.StagingTssClientFormat stage 
		LEFT JOIN dbo.CoreClientIdentification clientidentification  ON clientidentification.RefClientId = stage.RefClientId
			AND clientidentification.RefIdentificationTypeId = @GSTIN
		LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
		WHERE clientidentification.RefClientId IS NULL 
		AND errorTable.StagingTssClientFormatId IS NULL
		AND stage.GSTIN IS NOT NULL
		AND stage.[GUID] = @InternalGuid

		INSERT INTO dbo.CoreClientIdentification(
			RefClientId,
			RefIdentificationTypeId,
			IdValue,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT 
			stage.RefClientId,
			@IEC,
			stage.IEC,
			stage.AddedBy,
			stage.AddedOn,
			stage.AddedBy,
			stage.AddedOn
		FROM dbo.StagingTssClientFormat stage 
		LEFT JOIN dbo.CoreClientIdentification clientidentification  ON clientidentification.RefClientId = stage.RefClientId
			AND clientidentification.RefIdentificationTypeId = @IEC
		LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
		WHERE clientidentification.RefClientId IS NULL 
		AND errorTable.StagingTssClientFormatId IS NULL
		AND stage.IEC IS NOT NULL
		AND stage.[GUID] = @InternalGuid

	SELECT DISTINCT
		stage.RefClientId,
		t.items AS Tags
	INTO #tagdata
	FROM dbo.StagingTssClientFormat stage
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	CROSS APPLY dbo.Split(stage.Tags,',') t
	WHERE stage.[GUID] = @InternalGuid and errorTable.StagingTssClientFormatId IS NULL

	SELECT stg.RefClientId,
			stg.Income,
	   CASE WHEN stg.Networth IS NULL THEN NULL
		ELSE stg.Networth*100000 END Networth,
			ISNULL(stg.FromDate,@SystemDate) AS FromDate,
			grp.RefIncomeGroupId,
			stg.AddedBy,
			stg.AddedOn
	INTO #incomeDetails
	FROM dbo.StagingTssClientFormat stg
	INNER JOIN dbo.RefIncomeGroup grp ON grp.Code=stg.IncomeGroup
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stg.StagingTssClientFormatId
	WHERE  stg.[GUID] = @InternalGuid AND RefClientId IS NOT NULL AND  (IncomeGroup IS NOT NULL)
	AND errorTable.StagingTssClientFormatId IS NULL

   UPDATE link    
   SET link.ToDate =  DATEADD(DAY, -1,inc.FromDate) ,
		link.EditedOn=inc.AddedOn,
		link.LastEditedBy=inc.AddedBy
   FROM #incomeDetails inc    
   INNER JOIN dbo.LinkRefClientRefIncomeGroupLatest latest ON inc.RefClientId=latest.RefClientId
   INNER JOIN dbo.LinkRefClientRefIncomeGroup link ON latest.LinkRefClientRefIncomeGroupId = link.LinkRefClientRefIncomeGroupId
   WHERE ISNULL(inc.Income,0)<>ISNULL(link.Income,0) OR ISNULL(inc.Networth,0)<>ISNULL(link.Networth,0)
   OR ISNULL(inc.RefIncomeGroupId,0)<>ISNULL(link.RefIncomeGroupId,0) 

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
	   temp.RefClientId,    
	   temp.RefIncomeGroupId,    
	   temp.Income,    
	   temp.Networth,    
	   temp.FromDate,    
	   temp.AddedBy,    
	   temp.AddedOn,    
	   temp.AddedBy,    
	   temp.AddedOn    
	  FROM #incomeDetails temp
	  LEFT JOIN dbo.LinkRefClientRefIncomeGroup grp ON grp.RefClientId = temp.RefClientId 
	  AND (ISNULL(grp.Income,0) = ISNULL(temp.Income,0) AND ISNULL(grp.Networth,0) = ISNULL(temp.Networth,0)
		AND ISNULL(grp.RefIncomeGroupId,0) = ISNULL(temp.RefIncomeGroupId,0) )
	  WHERE grp.LinkRefClientRefIncomeGroupId IS NULL    

	SELECT DISTINCT
		td.RefClientId,
		eval.RefEnumValueId
	INTO #clientenumlink
	FROM #tagdata td
	INNER JOIN dbo.RefEnumValue eval ON eval.RefEnumTypeId = @ClientTagType 
	AND eval.Code = td.Tags

	DELETE link
	FROM dbo.LinkRefClientRefEnumValue link
	INNER JOIN #tagdata eli ON link.RefClientId = eli.RefClientId 
	LEFT JOIN #clientenumlink eli2 ON link.RefClientId = eli2.RefClientId 
	AND link.RefEnumTypeId = @ClientTagType
	AND link.RefEnumValueId = eli2.RefEnumValueId
	WHERE eli2.RefEnumValueId IS NULL

	DROP TABLE #tagdata

	INSERT INTO dbo.LinkRefClientRefEnumValue(
		RefClientId,
		RefEnumTypeId,
		RefEnumValueId,
		AddedBy,
		AddedOn,
		LastEditedBy,
		EditedOn
	)
	SELECT
		link.RefClientId,
		@ClientTagType,
		link.RefEnumValueId,
		stage.AddedBy,
		stage.AddedOn,
		stage.AddedBy,
		stage.AddedOn
	FROM #clientenumlink link
	INNER JOIN dbo.StagingTssClientFormat stage ON stage.RefClientId = link.RefClientId
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	LEFT JOIN dbo.LinkRefClientRefEnumValue cenum ON cenum.RefClientId = link.RefClientId
	AND cenum.RefEnumTypeId = @ClientTagType 
	AND cenum.RefEnumValueId = link.RefEnumValueId
	WHERE cenum.RefEnumValueId IS NULL AND stage.[GUID]=@InternalGuid
	AND errorTable.StagingTssClientFormatId is null
	
	DROP TABLE #clientenumlink
	
	SELECT
		link.LinkRefClientRefCustomerSegmentId,
		link.RefClientId,
		link.RefCustomerSegmentId
	INTO #NoChangeRecords
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.LinkRefClientRefCustomerSegment link ON link.RefCustomerSegmentId = stage.RefCustomerSegmentId AND link.RefClientId = stage.RefClientId
	WHERE stage.[GUID] = @InternalGuid

	SELECT DISTINCT RefClientId
	INTO #NoChangeRecordsClientIds
	FROM #NoChangeRecords

	DROP TABLE #NoChangeRecords

	DELETE link FROM dbo.LinkRefClientRefCustomerSegment link
	INNER JOIN dbo.StagingTssClientFormat stage ON stage.RefClientId = link.RefClientId AND stage.RefCustomerSegmentId <> link.RefCustomerSegmentId
	LEFT JOIN #NoChangeRecordsClientIds ncrc ON stage.RefClientId = ncrc.RefClientId
	WHERE ncrc.RefClientId IS NULL AND stage.RefCustomerSegmentId IS NOT NULL AND stage.[GUID] = @InternalGuid


	INSERT INTO dbo.LinkRefClientRefCustomerSegment
	(
		RefCustomerSegmentId,
		RefClientId,
		StartDate,
		AddedBy,
		AddedOn,
		LastEditedBy,
		EditedOn
	)
	SELECT
		stage.RefCustomerSegmentId,
		stage.RefClientId,
		@SystemDate,
		stage.AddedBy,
		stage.AddedOn,
		stage.AddedBy,
		stage.AddedOn
	FROM dbo.StagingTssClientFormat stage
	LEFT JOIN #NoChangeRecordsClientIds ncrc ON stage.RefClientId = ncrc.RefClientId
	WHERE ncrc.RefClientId IS NULL AND stage.RefCustomerSegmentId IS NOT NULL AND stage.[GUID] = @InternalGuid

	DROP TABLE #NoChangeRecordsClientIds	
	-----------------------------------------------------------------------------------------------------------------
	INSERT INTO dbo.LinkRefClientRefBankMicr
	(
		RefClientId,
		RefBankMicrId,
		RefBankAccountTypeId,
		BankAccNo,
		IfscCode,
		MicrCode,
		POA,
		AddedBy,
		AddedOn,
		LastEditedBy,
		EditedOn
	)
	SELECT 
		stage.RefClientId,
		stage.RefBankMicrId,
		stage.RefBankAccountTypeId,
		stage.AccountNo,
		stage.IfscCode,
		bank.MicrNo,
		0,
		stage.AddedBy,
		stage.AddedOn,
		stage.AddedBy,
		stage.AddedOn
	FROM dbo.StagingTssClientFormat stage
	INNER JOIN dbo.RefBankMicr bank ON stage.RefBankMicrId = bank.RefBankMicrId
	LEFT JOIN dbo.LinkRefClientRefBankMicr link ON link.RefClientId = stage.RefClientId AND 
												   link.RefBankMicrId = stage.RefBankMicrId AND 
												   link.RefBankAccountTypeId = stage.RefBankAccountTypeId AND 
												   link.BankAccNo = stage.AccountNo
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE link.LinkRefClientRefBankMicrId IS NULL AND errorTable.StagingTssClientFormatId IS NULL AND 
		  stage.RefBankMicrId IS NOT NULL AND stage.[GUID] = @InternalGuid
	-----------------------------------------------------------------------------------------------------------------
	INSERT INTO dbo.LinkVirtRefClientRefKeyPerson 
	(
		RefClientId,
		FirstName,
		MiddleName,
		LastName,
		RefDesignationId,
		AddedBy,
		AddedOn,
		LastEditedBy,
		EditedOn
	)
	SELECT 
		stage.RefClientId, 
		stage.KeyPersonFirstName, 
		stage.KeyPersonMiddleName, 
		stage.KeyPersonLastName, 
		stage.RefDesignationId, 
		stage.AddedBy, 
		stage.AddedOn,
		stage.AddedBy, 
		stage.AddedOn
	FROM dbo.StagingTssClientFormat stage
	LEFT JOIN dbo.LinkVirtRefClientRefKeyPerson link ON link.RefClientId = stage.RefClientId AND 
													    ISNULL(link.FirstName,'') = ISNULL(stage.KeyPersonFirstName,'') AND
													    ISNULL(link.MiddleName,'') = ISNULL(stage.KeyPersonMiddleName,'') AND
													    ISNULL(link.LastName,'') = ISNULL(stage.KeyPersonLastName,'') AND
													    link.RefDesignationId = stage.RefDesignationId
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE link.LinkVirtRefClientRefKeyPersonId IS NULL AND errorTable.StagingTssClientFormatId IS NULL AND
		  stage.RefDesignationId IS NOT NULL AND stage.[GUID] = @InternalGuid  
	
	----------------------------------------Insert Update CoreClientKeyValueInfo Start----------------------------------------------------
	CREATE TABLE #tempClientKeyValue 
	(
		CoreClientKeyValueInfoId INT,
		RefClientId INT,
		RefClientKeyId INT, 
		ColumnName NVARCHAR(200) COLLATE DATABASE_DEFAULT,
		ColumnDataType VARCHAR(100) COLLATE DATABASE_DEFAULT,
		NewValueString NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
		NewValueDouble DECIMAL,
		NewValueInt INT,
		NewValueDateTime DATETIME
	)
	-----------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueString)
	SELECT 
		stage.RefClientId,
		'CustodialCode',
		ISNULL(stage.CustodialCode,'') AS NewValueString
	FROM dbo.StagingTssClientFormat stage 
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL --AND stage.CustodialCode IS NOT NULL
	-------------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueDouble)
	SELECT 
		stage.RefClientId,
		'PCMLimit',
		CASE WHEN ISNULL(stage.PCMLimit,'')<>'' THEN CONVERT(decimal(28,2),stage.PCMLimit) ELSE 0 END AS NewValueDouble 
	FROM dbo.StagingTssClientFormat stage 
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL --AND stage.PCMLimit IS NOT NULL
	-------------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueString)
	SELECT 
		stage.RefClientId,
		'FPIGroupCode',
		stage.FPIGroupCode AS NewValueString
	FROM dbo.StagingTssClientFormat stage 
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.FPIGroupCode,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueString)
	SELECT 
		stage.RefClientId,
		'KYCComplianceStatus',
		stage.KYCComplianceStatus AS NewValueString
	FROM dbo.StagingTssClientFormat stage 
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.KYCComplianceStatus,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueDateTime)
	SELECT 
		stage.RefClientId,
		'KYCUpdationLastDate',
		stage.KYCUpdationLastDate AS NewValueDateTime
	FROM dbo.StagingTssClientFormat stage 
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.KYCUpdationLastDate,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueString)
	SELECT 
		stage.RefClientId,
		'EmployerAddressState',
		stage.EmployerAddressState AS NewValueString
	FROM dbo.StagingTssClientFormat stage 
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.EmployerAddressState,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueString)
	SELECT 
		stage.RefClientId,
		'EmployerAddressDistrict',
		stage.EmployerAddressDistrict AS NewValueString
	FROM dbo.StagingTssClientFormat stage 
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.EmployerAddressDistrict,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueString)
	SELECT 
		stage.RefClientId,
		'EmployerAddressCity',
		stage.EmployerAddressCity AS NewValueString
	FROM dbo.StagingTssClientFormat stage 
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.EmployerAddressCity,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueString)
	SELECT 
		stage.RefClientId,
		'EmployerAddressPinCode',
		stage.EmployerAddressPinCode AS NewValueString
	FROM dbo.StagingTssClientFormat stage 
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.EmployerAddressPinCode,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------
		INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueInt)
	SELECT 
		stage.RefClientId,
		'EmployerAddressCountry',
		rc.RefCountryId AS NewValueInt
	FROM dbo.StagingTssClientFormat stage 
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	INNER JOIN dbo.RefCountry rc ON rc.Name = stage.EmployerAddressCountry  OR rc.Iso2DigitCode = stage.EmployerAddressCountry OR rc.Iso3DigitCode = stage.EmployerAddressCountry
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.EmployerAddressCountry,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------

	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueString)
	SELECT 
		stage.RefClientId,
		'COMPANYWEBSITE',
		stage.COMPANYWEBSITE AS NewValueString
	FROM dbo.StagingTssClientFormat stage
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.COMPANYWEBSITE,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueString)
	SELECT 
		stage.RefClientId,
		'FCRASTATUS',
		stage.FCRASTATUS AS NewValueString
	FROM dbo.StagingTssClientFormat stage
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.FCRASTATUS,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueInt)
	SELECT 
		stage.RefClientId,
		'FCRAREGISTRATIONSTATE',
		rs.RefStateId AS NewValueInt
	FROM dbo.StagingTssClientFormat stage
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	INNER JOIN dbo.RefState rs ON rs.[Name] = stage.FCRAREGISTRATIONSTATE  OR rs.Code = stage.FCRAREGISTRATIONSTATE OR rs.Code2 = stage.FCRAREGISTRATIONSTATE
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.FCRAREGISTRATIONSTATE,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO #tempClientKeyValue (RefClientId, ColumnName, NewValueString)
	SELECT 
		stage.RefClientId,
		'FCRAREGISTRATIONNUMBER',
		stage.FCRAREGISTRATIONNUMBER AS NewValueString
	FROM dbo.StagingTssClientFormat stage
	LEFT JOIN #ErrorListTable errorTable ON errorTable.StagingTssClientFormatId = stage.StagingTssClientFormatId
	WHERE stage.[GUID] = @InternalGuid AND errorTable.StagingTssClientFormatId IS NULL AND ISNULL(stage.FCRAREGISTRATIONNUMBER,'') <> ''
	-----------------------------------------------------------------------------------------------------------------------------------------


	UPDATE temp
	SET temp.RefClientKeyId = clientKey.RefClientKeyId,
		temp.ColumnDataType = enumVal.[Code]
	FROM #tempClientKeyValue temp
	INNER JOIN dbo.RefClientKey clientKey ON temp.ColumnName = clientKey.Code
	INNER JOIN dbo.RefEnumValue enumVal ON enumVal.RefEnumValueId = clientKey.ColumnTypeRefEnumValueId AND enumVal.RefEnumTypeId = @ColumnTypeId

	UPDATE temp
	SET temp.CoreClientKeyValueInfoId = keyValue.CoreClientKeyValueInfoId
	FROM #tempClientKeyValue temp
	INNER JOIN dbo.CoreClientKeyValueInfo keyValue ON keyValue.RefClientId = temp.RefClientId AND keyValue.RefClientKeyId = temp.RefClientKeyId
	-----------------------------------------------------------------------------------------------------------------------------------------
	IF EXISTS (SELECT TOP 1 1 FROM #tempClientKeyValue WHERE ColumnDataType ='String')
	BEGIN 
		UPDATE keyValue
		SET StringValue = NewValueString,
			LastEditedBy = @AddedBy,
			EditedOn = @AddedOn
		FROM #tempClientKeyValue temp
		INNER JOIN dbo.CoreClientKeyValueInfo keyValue  ON keyValue.CoreClientKeyValueInfoId = temp.CoreClientKeyValueInfoId
		WHERE temp.NewValueString <> ISNULL(keyValue.StringValue,'') 

		INSERT INTO dbo.CoreClientKeyValueInfo 
		(
			RefClientKeyId,
			RefClientId,   
			StringValue,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT
			temp.RefClientKeyId,
			temp.RefClientId,
			temp.NewValueString,
			@AddedBy,
			@AddedOn,
			@AddedBy,
			@AddedOn
		FROM #tempClientKeyValue temp
		WHERE temp.CoreClientKeyValueInfoId IS NULL AND NewValueString IS NOT NULL
	END 
	IF EXISTS (SELECT TOP 1 1 FROM #tempClientKeyValue WHERE ColumnDataType ='DateTime')
	BEGIN 
		UPDATE keyValue
		SET DateTimeValue = NewValueDateTime,
			LastEditedBy = @AddedBy,
			EditedOn = @AddedOn
		FROM #tempClientKeyValue temp
		INNER JOIN dbo.CoreClientKeyValueInfo keyValue  ON keyValue.CoreClientKeyValueInfoId = temp.CoreClientKeyValueInfoId
		WHERE temp.NewValueDateTime <> keyValue.DateTimeValue

		INSERT INTO dbo.CoreClientKeyValueInfo 
		(
			RefClientKeyId,
			RefClientId,   
			DateTimeValue,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT
			temp.RefClientKeyId,
			temp.RefClientId,
			temp.NewValueDateTime,
			@AddedBy,
			@AddedOn,
			@AddedBy,
			@AddedOn
		FROM #tempClientKeyValue temp
		WHERE temp.CoreClientKeyValueInfoId IS NULL AND NewValueDateTime IS NOT NULL
	END 
	IF EXISTS (SELECT TOP 1 1 FROM #tempClientKeyValue WHERE ColumnDataType ='Double')
	BEGIN 
		UPDATE keyValue
		SET DoubleValue = NewValueDouble,
			LastEditedBy = @AddedBy,
			EditedOn = @AddedOn
		FROM #tempClientKeyValue temp
		INNER JOIN dbo.CoreClientKeyValueInfo keyValue  ON keyValue.CoreClientKeyValueInfoId = temp.CoreClientKeyValueInfoId
		--WHERE temp.NewValueDouble <> ISNULL(keyValue.DoubleValue,'') 

		INSERT INTO dbo.CoreClientKeyValueInfo 
		(
			RefClientKeyId,
			RefClientId,  
			DoubleValue,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT
			temp.RefClientKeyId,
			temp.RefClientId,
			temp.NewValueDouble,
			@AddedBy,
			@AddedOn,
			@AddedBy,
			@AddedOn
		FROM #tempClientKeyValue temp
		WHERE temp.CoreClientKeyValueInfoId IS NULL AND NewValueDouble IS NOT NULL
	END 
	IF EXISTS (SELECT TOP 1 1 FROM #tempClientKeyValue WHERE ColumnDataType ='Int')
	BEGIN 
		UPDATE keyValue
		SET IntValue = NewValueInt,
			LastEditedBy = @AddedBy,
			EditedOn = @AddedOn
		FROM #tempClientKeyValue temp
		INNER JOIN dbo.CoreClientKeyValueInfo keyValue  ON keyValue.CoreClientKeyValueInfoId = temp.CoreClientKeyValueInfoId
		WHERE temp.NewValueInt <> ISNULL(keyValue.IntValue,'') 

		INSERT INTO dbo.CoreClientKeyValueInfo 
		(
			RefClientKeyId,
			RefClientId,  
			IntValue,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT
			temp.RefClientKeyId,
			temp.RefClientId,
			temp.NewValueInt,
			@AddedBy,
			@AddedOn,
			@AddedBy,
			@AddedOn
		FROM #tempClientKeyValue temp
		WHERE temp.CoreClientKeyValueInfoId IS NULL AND NewValueInt IS NOT NULL
	END 

	DROP TABLE #tempClientKeyValue
	----------------------------------------Insert Update CoreClientKeyValueInfo End----------------------------------------------------

	DELETE FROM dbo.StagingTssClientFormat WHERE [GUID] = @InternalGuid

	SELECT 
		@ErrorString + CONVERT(VARCHAR,elt.LineNumber) +' '+ ISNULL(STUFF((
            SELECT ',' + lt.ErrorMessage
            FROM #ErrorListTable lt 
			WHERE lt.StagingTssClientFormatId = elt.StagingTssClientFormatId
            FOR XML PATH('')
            ), 1, 1, ''),'') as ErrorMessage
	FROM (
		SELECT  DISTINCT LineNumber,StagingTssClientFormatId
		FROM #ErrorListTable t
		WHERE t.ErrorMessage IS NOT NULL AND t.ErrorMessage <> ''
	) elt
	ORDER BY elt.LineNumber
END
GO
--WEB-82457-AV-START--
--WEB-82457-AV-START--