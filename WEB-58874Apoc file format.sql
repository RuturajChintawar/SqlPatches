-----------------WEB-58874 -----RC Starts
GO
ALTER TABLE dbo.StagingClientRefresh ADD IncomeGroup INT NULL,NetWorth DECIMAL(28,2) NULL,NetWorthDate DATETIME NULL, StateCode INT NULL
GO
GO
ALTER TABLE dbo.StagingClientRefresh ADD IsPANValid BIT NULL ,IsNetWorthDateValid BIT NULL,IsSuspendedDateValid BIT NULL ,
IsMinorNomineeDateOfBirthValid BIT NULL, IsGuardianDOBValid BIT Null ,IsNomineeDOBValid BIT NULL ,IsDobValid BIT NULL ,IsAccountOpeningDateValid BIT NULL ,
IsAccountClosingDateValid BIT NULL  
GO
-----------------WEB-58874 -----RC Ends
-----------------WEB-58874 -----RC Starts
GO
ALTER PROCEDURE [dbo].[RefClient_NSDLAPOC_InsertFromStaging]    
(    
	@guid VARCHAR(5000)=NULL    
)    
AS    
    BEGIN     
    DECLARE @GuidInternal varchar(5000)    
	SET @GuidInternal=@guid   
	
    DECLARE @IncomeMultiplier VARCHAR(MAX)    
    SELECT @IncomeMultiplier = [Value] FROM dbo.sysconfig WHERE [Name] = 'Aml_Client_Income_Multiplier'    
          
    DECLARE @NetworthMultiplier VARCHAR(MAX)    
    SELECT @NetworthMultiplier = [Value] FROM dbo.sysconfig WHERE [Name] = 'Aml_Client_Networth_Multiplier'   
	
	DECLARE @ErrorString VARCHAR(50)
	SET @ErrorString='Error in Record at Line : '
  
	CREATE TABLE #ErrorListTable  
	(  
		LineNumber INT,  
		ErrorMessage VARCHAR(MAX) DEFAULT '' COLLATE DATABASE_DEFAULT  
	) 
	
	SELECT  
	ROW_NUMBER() OVER(ORDER BY stage.StagingClientRefreshId) AS LineNumber,  
	stage.IsPANValid,  
	stage.IsNetWorthDateValid,
	stage.IsSuspendedDateValid,
	stage.IsMinorNomineeDateOfBirthValid,
	stage.IsGuardianDOBValid, 
	stage.IsNomineeDOBValid, 
	stage.IsDobValid, 
	stage.IsAccountOpeningDateValid, 
	stage.IsAccountClosingDateValid,
	stage.AccountOpeningDate,
	stage.AccountClosingDate
	INTO #TempStaging  
	FROM dbo.StagingClientRefresh stage  
	WHERE stage.[GUID] = @GuidInternal  
  
	INSERT INTO #ErrorListTable  
	(  
		LineNumber  
	)  
	 SELECT  
	stage.LineNumber  
	FROM #TempStaging stage  
  
   SELECT  
	ts.LineNumber,  
	ts.IsPANValid  
   INTO #PANCHECK  
   FROM #TempStaging ts  
   WHERE ts.IsPANValid = 0  
    
  
  UPDATE #ErrorListTable  
  SET ErrorMessage = ErrorMessage + ', Invalid Pan no inserted'  
  FROM #PANCHECK ic  
  WHERE #ErrorListTable.LineNumber = ic.LineNumber  

  DROP TABLE #PANCHECK

  SELECT  
  ts.LineNumber,  
  ts.IsNomineeDOBValid
  INTO #NomineeCheck  
  FROM #TempStaging ts  
  WHERE ts.IsNomineeDOBValid=1
    
  
  UPDATE #ErrorListTable  
  SET ErrorMessage = ErrorMessage + ', Nominee DOB incorrect format'  
  FROM #NomineeCheck ic  
  WHERE #ErrorListTable.LineNumber = ic.LineNumber
  
  DROP TABLE #NomineeCheck
  
  SELECT  
  ts.LineNumber,  
  ts.IsGuardianDOBValid
  INTO #GuardianCheck  
  FROM #TempStaging ts  
  WHERE ts.IsGuardianDOBValid = 1
    
  
  UPDATE #ErrorListTable  
  SET ErrorMessage = ErrorMessage + ', Guardian DOB incorrect format'  
  FROM #GuardianCheck ic  
  WHERE #ErrorListTable.LineNumber = ic.LineNumber
  
  DROP TABLE #GuardianCheck
  
  SELECT  
  ts.LineNumber,  
  ts.IsMinorNomineeDateOfBirthValid
  INTO #MinorCheck  
  FROM #TempStaging ts  
  WHERE ts.IsMinorNomineeDateOfBirthValid = 1
    
  
  UPDATE #ErrorListTable  
  SET ErrorMessage = ErrorMessage + ', Minor Nominee DOB incorrect format'  
  FROM #MinorCheck ic  
  WHERE #ErrorListTable.LineNumber = ic.LineNumber
  
  DROP TABLE #MinorCheck

  SELECT  
  ts.LineNumber,  
  ts.IsSuspendedDateValid
  INTO #SuspendedCheck  
  FROM #TempStaging ts  
  WHERE ts.IsSuspendedDateValid = 1
    
  
  UPDATE #ErrorListTable  
  SET ErrorMessage = ErrorMessage + ', Suspended Date incorrect format'  
  FROM #SuspendedCheck ic  
  WHERE #ErrorListTable.LineNumber = ic.LineNumber
  
  DROP TABLE #SuspendedCheck

  SELECT  
  ts.LineNumber,  
  ts.IsDobValid
  INTO #DobCheck  
  FROM #TempStaging ts  
  WHERE ts.IsDobValid = 1
    
  
  UPDATE #ErrorListTable  
  SET ErrorMessage = ErrorMessage + ', DOB incorrect format'  
  FROM #DobCheck ic  
  WHERE #ErrorListTable.LineNumber = ic.LineNumber
  
  DROP TABLE #DobCheck

  SELECT  
  ts.LineNumber,  
  ts.IsAccountOpeningDateValid
  INTO #OpenCheck  
  FROM #TempStaging ts  
  WHERE ts.IsAccountOpeningDateValid = 1
    
  
  UPDATE #ErrorListTable  
  SET ErrorMessage = ErrorMessage + ', Account Opening Date incorrect format'  
  FROM #OpenCheck ic  
  WHERE #ErrorListTable.LineNumber = ic.LineNumber
  
  DROP TABLE #OpenCheck

  SELECT  
  ts.LineNumber,  
  ts.IsAccountClosingDateValid
  INTO #CloseCheck  
  FROM #TempStaging ts  
  WHERE ts.IsAccountClosingDateValid = 1
    
  
  UPDATE #ErrorListTable  
  SET ErrorMessage = ErrorMessage + ', Account closing date incorrect format'  
  FROM #CloseCheck ic  
  WHERE #ErrorListTable.LineNumber = ic.LineNumber
  
  DROP TABLE #CloseCheck

  SELECT  
  ts.LineNumber,  
  ts.AccountOpeningDate
  INTO #DateValidCheck  
  FROM #TempStaging ts  
  WHERE ts.AccountOpeningDate IS NOT NULL AND ts.AccountClosingDate IS NOT NULL AND ts.AccountClosingDate < ts.AccountOpeningDate
    
  
  UPDATE #ErrorListTable  
  SET ErrorMessage = ErrorMessage + ', Account Closing Date cannot be smaller than Account Opening Date.'  
  FROM #DateValidCheck ic  
  WHERE #ErrorListTable.LineNumber = ic.LineNumber
  
  DROP TABLE #DateValidCheck
  
  SELECT  
  ts.LineNumber,  
  ts.IsNetWorthDateValid
  INTO #NetDateCheck  
  FROM #TempStaging ts  
  WHERE ts.IsNetWorthDateValid=1
    
  
  UPDATE #ErrorListTable  
  SET ErrorMessage = ErrorMessage + ', NetWorth date not Correct or Manditory in this case'  
  FROM #NetDateCheck ic  
  WHERE #ErrorListTable.LineNumber = ic.LineNumber  

  DROP TABLE #NetDateCheck
  
    
    
    IF (SELECT TOP 1 1 FROM #ErrorListTable elt WHERE elt.ErrorMessage IS NOT NULL AND elt.ErrorMessage <> '') = 1
					BEGIN
					SELECT 
					@ErrorString + CONVERT(VARCHAR, elt.LineNumber) + ' ' + STUFF(elt.ErrorMessage,1,2,'') AS ErrorMessage
					FROM #ErrorListTable elt
					WHERE elt.ErrorMessage IS NOT NULL AND elt.ErrorMessage <> ''
					ORDER BY elt.LineNumber
					END
		ELSE
			BEGIN

      UPDATE stage    
  SET UpdateCorrespondenceAddress = CASE WHEN dbo.IsNotNullOrEmpty(stage.CAddressLine1) = 1 OR dbo.IsNotNullOrEmpty(stage.CAddressLine2) = 1 OR dbo.IsNotNullOrEmpty(stage.CAddressLine3) = 1 OR dbo.IsNotNullOrEmpty(stage.CAddressCity) = 1    
         THEN 1 ELSE 0 END,    
   UpdatePermanentAddress = CASE WHEN dbo.IsNotNullOrEmpty(stage.PAddressLine1) = 1 OR dbo.IsNotNullOrEmpty(stage.PAddressLine2) = 1 OR dbo.IsNotNullOrEmpty(stage.PAddressLine3) = 1 OR dbo.IsNotNullOrEmpty(stage.PAddressCity) = 1    
         THEN 1 ELSE 0 END,      
   UpdateNomineeAddress = CASE WHEN dbo.IsNotNullOrEmpty(stage.NomineeAddressLine1) = 1 OR dbo.IsNotNullOrEmpty(stage.NomineeAddressLine2) = 1 OR dbo.IsNotNullOrEmpty(stage.NomineeAddressLine3) = 1 OR dbo.IsNotNullOrEmpty(stage.NomineeAddressCity) = 1    
         THEN 1 ELSE 0 END,    
   UpdateGuardianAddress = CASE WHEN dbo.IsNotNullOrEmpty(stage.GuardianAddressLine1) = 1 OR dbo.IsNotNullOrEmpty(stage.GuardianAddressLine2) = 1 OR dbo.IsNotNullOrEmpty(stage.GuardianAddressLine3) = 1 OR dbo.IsNotNullOrEmpty(stage.GuardianAddressCity) = 
  
1    
         THEN 1 ELSE 0 END,      
   UpdateCorrespondenceLocalAddress = CASE WHEN dbo.IsNotNullOrEmpty(stage.CorrespondenceLocalAddressLine1) = 1 OR dbo.IsNotNullOrEmpty(stage.CorrespondenceLocalAddressLine2) = 1 OR dbo.IsNotNullOrEmpty(stage.CorrespondenceLocalAddressLine3) = 1 OR dbo.IsNotNullOrEmpty(stage.CorrespondenceLocalCity) = 1    
         THEN 1 ELSE 0 END,    
   UpdateTaxResidencyAddress = CASE WHEN dbo.IsNotNullOrEmpty(stage.TaxResidencyAddressLine1) = 1 OR dbo.IsNotNullOrEmpty(stage.TaxResidencyAddressLine2) = 1 OR dbo.IsNotNullOrEmpty(stage.TaxResidencyAddressLine3) = 1 OR dbo.IsNotNullOrEmpty(stage.TaxResidencyCity) = 1    
         THEN 1 ELSE 0 END                   
  FROM dbo.StagingClientRefresh stage  
	--WHERE Guid = @Guid  
 SELECT     
 client.RefClientId,    
 client.RefClientDatabaseEnumId,    
 client.ClientId,    
 IsNull(stg.FamilyCode,Client.FamilyCode) as FamilyCode,    
    IsNull(stg.Name,Client.Name) as Name,    
    IsNull(stg.Email,Client.Email) as Email,    
    CASE WHEN stg.UpdateCorrespondenceAddress = 1 THEN stg.CAddressLine1 ELSE Client.CAddressLine1 END as CAddressLine1,    
    CASE WHEN stg.UpdateCorrespondenceAddress = 1 THEN stg.CAddressLine2 ELSE Client.CAddressLine2 END as CAddressLine2,    
    CASE WHEN stg.UpdateCorrespondenceAddress = 1 THEN stg.CAddressLine3 ELSE Client.CAddressLine3 END as CAddressLine3,    
    CASE WHEN stg.UpdateCorrespondenceAddress = 1 THEN stg.CAddressCity ELSE Client.CAddressCity END as CAddressCity,    
    CASE WHEN stg.UpdateCorrespondenceAddress = 1 THEN stg.CAddressState ELSE Client.CAddressState END as CAddressState,    
    CASE WHEN stg.UpdateCorrespondenceAddress = 1 THEN stg.CAddressCountry ELSE Client.CAddressCountry END as CAddressCountry ,    
    CASE WHEN stg.UpdateCorrespondenceAddress = 1 THEN stg.CAddressPin ELSE Client.CAddressPin END as CAddressPin,    
    CASE WHEN stg.UpdatePermanentAddress = 1 THEN stg.PAddressLine1 ELSE Client.PAddressLine1 END as PAddressLine1,    
    CASE WHEN stg.UpdatePermanentAddress = 1 THEN stg.PAddressLine2 ELSE Client.PAddressLine2 END as PAddressLine2,    
    CASE WHEN stg.UpdatePermanentAddress = 1 THEN stg.PAddressLine3 ELSE Client.PAddressLine3 END as PAddressLine3,    
    CASE WHEN stg.UpdatePermanentAddress = 1 THEN stg.PAddressCity ELSE Client.PAddressCity END as PAddressCity,    
    CASE WHEN stg.UpdatePermanentAddress = 1 THEN stg.PAddressState ELSE Client.PAddressState END as PAddressState,    
    CASE WHEN stg.UpdatePermanentAddress = 1 THEN stg.PAddressCountry ELSE Client.PAddressCountry END as PAddressCountry,    
    CASE WHEN stg.UpdatePermanentAddress = 1 THEN stg.PAddressPin ELSE Client.PAddressPin END as PAddressPin,    
    IsNull(stg.Phone1,Client.Phone1) as Phone1,    
    IsNull(stg.Phone2,Client.Phone2) as Phone2,    
    IsNull(stg.Phone3,Client.Phone3) as Phone3,    
    IsNull(stg.Mobile,Client.Mobile) as Mobile,    
    IsNull(stg.TaxStatusType,Client.TaxStatusType) as TaxStatusType,    
    IsNull(stg.RefBseMfOccupationTypeId,Client.RefBseMfOccupationTypeId) as RefBseMfOccupationTypeId,    
    IsNull(stg.Dob,Client.Dob) as Dob,    
    IsNull(stg.Gender,Client.Gender) as Gender,    
    IsNull(stg.FatherName,Client.FatherName) as FatherName,    
    IsNull(stg.PAN,Client.PAN) as PAN,    
    IsNull(stg.GuradianPAN,Client.GuradianPAN) as GuradianPAN,    
    IsNull(stg.RefClientStatusId,Client.RefClientStatusId) as RefClientStatusId,    
    IsNull(stg.RefIntermediaryId,Client.RefIntermediaryId) as RefIntermediaryId,    
    IsNull(stg.RefConstitutionTypeId,Client.RefConstitutionTypeId) as RefConstitutionTypeId,    
    IsNull(stg.SecondHolderRefSalutationId,Client.SecondHolderRefSalutationId) as SecondHolderRefSalutationId,    
    IsNull(stg.SecondHolderFirstName,Client.SecondHolderFirstName) as SecondHolderFirstName,    
    IsNull(stg.SecondHolderMiddleName,Client.SecondHolderMiddleName) as SecondHolderMiddleName,    
    IsNull(stg.SecondHolderLastName,Client.SecondHolderLastName) as SecondHolderLastName,    
    IsNull(stg.SecondHolderGender,Client.SecondHolderGender) as SecondHolderGender,    
    IsNull(stg.SecondHolderDOB,Client.SecondHolderDOB) as SecondHolderDOB,    
    IsNull(stg.SecondHolderPAN,Client.SecondHolderPAN) as SecondHolderPAN,    
    IsNull(stg.SecondHolderFatherOrHusbandName,Client.SecondHolderFatherOrHusbandName) as SecondHolderFatherOrHusbandName,    
    IsNull(stg.SecondHolderRefConstitutionTypeId,Client.SecondHolderRefConstitutionTypeId) as SecondHolderRefConstitutionTypeId,    
    IsNull(stg.ThirdHolderSalutationId,Client.ThirdHolderSalutationId) as ThirdHolderSalutationId,    
    IsNull(stg.ThirdHolderFirstName,Client.ThirdHolderFirstName) as ThirdHolderFirstName,    
    IsNull(stg.ThirdHolderMiddleName,Client.ThirdHolderMiddleName) as ThirdHolderMiddleName,    
    IsNull(stg.ThirdHolderLastName,Client.ThirdHolderLastName) as ThirdHolderLastName,    
    IsNull(stg.ThirdHolderGender,Client.ThirdHolderGender) as ThirdHolderGender,    
    IsNull(stg.ThirdHolderDOB,Client.ThirdHolderDOB) as ThirdHolderDOB,    
    IsNull(stg.ThirdHolderPAN,Client.ThirdHolderPAN) as ThirdHolderPAN,    
    IsNull(stg.ThirdHolderFatherOrHusbandName,Client.ThirdHolderFatherOrHusbandName) as ThirdHolderFatherOrHusbandName,    
    IsNull(stg.ThirdHoldeRefConstitutionTypeId,Client.ThirdHoldeRefConstitutionTypeId) as ThirdHoldeRefConstitutionTypeId,    
    IsNull(stg.NomineeFirstName,Client.NomineeFirstName) as NomineeFirstName,    
    IsNull(stg.NomineeMiddleName,Client.NomineeMiddleName) as NomineeMiddleName,    
    IsNull(stg.NomineeLastName,Client.NomineeLastName) as NomineeLastName,    
    IsNull(stg.NomineeRelationshipWithFirstHolder,Client.NomineeRelationshipWithFirstHolder) as NomineeRelationshipWithFirstHolder,    
    IsNull(stg.NomineeRelationshipWithSecondHolder,Client.NomineeRelationshipWithSecondHolder) as NomineeRelationshipWithSecondHolder,    
    IsNull(stg.NomineeRelationshipWithThirdHolder,Client.NomineeRelationshipWithThirdHolder) as NomineeRelationshipWithThirdHolder,    
    CASE WHEN stg.UpdateNomineeAddress = 1 THEN stg.NomineeAddressLine1 ELSE Client.NomineeAddressLine1 END as NomineeAddressLine1,    
    CASE WHEN stg.UpdateNomineeAddress = 1 THEN stg.NomineeAddressLine2 ELSE Client.NomineeAddressLine2 END as NomineeAddressLine2,    
    CASE WHEN stg.UpdateNomineeAddress = 1 THEN stg.NomineeAddressLine3 ELSE Client.NomineeAddressLine3 END as NomineeAddressLine3,    
    CASE WHEN stg.UpdateNomineeAddress = 1 THEN stg.NomineeAddressCity ELSE Client.NomineeAddressCity END as NomineeAddressCity,    
    CASE WHEN stg.UpdateNomineeAddress = 1 THEN stg.NomineeAddressState ELSE Client.NomineeAddressState END as NomineeAddressState,    
    CASE WHEN stg.UpdateNomineeAddress = 1 THEN stg.NomineeAddressRefCountryId ELSE Client.NomineeAddressRefCountryId END as NomineeAddressRefCountryId,    
    CASE WHEN stg.UpdateNomineeAddress = 1 THEN stg.NomineeAddressPin ELSE Client.NomineeAddressPin END as NomineeAddressPin,    
    IsNull(stg.NomineePhone,Client.NomineePhone) as NomineePhone,    
    IsNull(stg.NomineeDOB,Client.NomineeDOB) as NomineeDOB,    
    IsNull(stg.GuardianFirstName,Client.GuardianFirstName) as GuardianFirstName,    
    IsNull(stg.GuardianMiddleName,Client.GuardianMiddleName) as GuardianMiddleName,    
    IsNull(stg.GuardianLastName,Client.GuardianLastName) as GuardianLastName,    
    IsNull(stg.GuardianRelationship,Client.GuardianRelationship) as GuardianRelationship,    
    CASE WHEN stg.UpdateGuardianAddress = 1 THEN stg.GuardianAddressLine1 ELSE Client.GuardianAddressLine1 END as GuardianAddressLine1 ,    
    CASE WHEN stg.UpdateGuardianAddress = 1 THEN stg.GuardianAddressLine2 ELSE Client.GuardianAddressLine2 END as GuardianAddressLine2,    
    CASE WHEN stg.UpdateGuardianAddress = 1 THEN stg.GuardianAddressLine3 ELSE Client.GuardianAddressLine3 END as GuardianAddressLine3,    
    CASE WHEN stg.UpdateGuardianAddress = 1 THEN stg.GuardianAddressCity ELSE Client.GuardianAddressCity END as GuardianAddressCity,    
    CASE WHEN stg.UpdateGuardianAddress = 1 THEN stg.GuardianAddressState ELSE Client.GuardianAddressState END as GuardianAddressState,    
    CASE WHEN stg.UpdateGuardianAddress = 1 THEN stg.GuardianAddressRefCountryId ELSE Client.GuardianAddressRefCountryId END as GuardianAddressRefCountryId,    
    CASE WHEN stg.UpdateGuardianAddress = 1 THEN stg.GuardianAddressPin ELSE Client.GuardianAddressPin END as GuardianAddressPin,    
    IsNull(stg.GuardianPhone,Client.GuardianPhone) as GuardianPhone,    
    IsNull(stg.EmployerName,Client.EmployerName) as EmployerName,    
    IsNull(stg.EmployerAddress,Client.EmployerAddress) as EmployerAddress,    
    IsNull(stg.EmployerBusinessNature,Client.EmployerBusinessNature) as EmployerBusinessNature,    
    IsNull(stg.EmployerPhone,Client.EmployerPhone) as EmployerPhone,    
    IsNull(stg.AccountOpeningDate,Client.AccountOpeningDate) as AccountOpeningDate,    
    IsNull(stg.AccountClosingDate,Client.AccountClosingDate) as AccountClosingDate,    
    IsNull(stg.Nationality,Client.Nationality) as Nationality,    
    IsNull(stg.RefCustomRiskId,Client.RefCustomRiskId) as RefCustomRiskId,    
    IsNull(stg.RefMaritalStatusId,Client.RefMaritalStatusId) as RefMaritalStatusId,    
    IsNull(stg.RefPEPId,Client.RefPEPId) as RefPEPId,    
    IsNull(stg.ISDCode1,Client.ISDCode1) as ISDCode1,    
    IsNull(stg.STDCode1,Client.STDCode1) as STDCode1,    
    IsNull(stg.ISDCode2,Client.ISDCode2) as ISDCode2,    
    IsNull(stg.STDCode2,Client.STDCode2) as STDCode2,    
    IsNull(stg.ISDCode3,Client.ISDCode3) as ISDCode3,    
    IsNull(stg.STDCode3,Client.STDCode3) as STDCode3,    
    IsNull(stg.Aadhar,Client.Aadhar) as Aadhar,    
    IsNull(stg.PlaceOfIncorporation,Client.PlaceOfIncorporation) as PlaceOfIncorporation,    
    IsNull(stg.RefProfileRatingMasterId,Client.RefProfileRatingMasterId) as RefProfileRatingMasterId,    
    IsNull(stg.DpId,Client.DpId) as DpId,    
    IsNull(stg.SecondHolderEmail,Client.SecondHolderEmail) as SecondHolderEmail,    
    IsNull(stg.SecondHolderMobile,Client.SecondHolderMobile) as SecondHolderMobile,    
    IsNull(stg.ThirdHolderEmail,Client.ThirdHolderEmail) as ThirdHolderEmail,    
    IsNull(stg.ThirdHolderMobile,Client.ThirdHolderMobile) as ThirdHolderMobile,    
    IsNull(stg.GuardianDOB,Client.GuardianDOB) as GuardianDOB,    
    IsNull(stg.SecondHolderRefCRMCustomerId,Client.SecondHolderRefCRMCustomerId) as SecondHolderRefCRMCustomerId,    
    IsNull(stg.ThirdHolderRefCRMCustomerId,Client.ThirdHolderRefCRMCustomerId) as ThirdHolderRefCRMCustomerId,    
    IsNull(stg.RefClientAccountStatusId,Client.RefClientAccountStatusId) as RefClientAccountStatusId,    
    IsNull(stg.FirstName,Client.FirstName) as FirstName,    
    IsNull(stg.MiddleName,Client.MiddleName) as MiddleName,    
    IsNull(stg.LastName,Client.LastName) as LastName,    
    IsNull(stg.KYCEmployeeCode,Client.KYCEmployeeCode) as KYCEmployeeCode,    
    IsNull(stg.KYCEmployeeDesignation,Client.KYCEmployeeDesignation) as KYCEmployeeDesignation,    
    IsNull(stg.KYCEmployeeName,Client.KYCEmployeeName) as KYCEmployeeName,    
    IsNull(stg.KYCDeclarationDate,Client.KYCDeclarationDate) as KYCDeclarationDate,    
    IsNull(stg.KYCVerificationDate,Client.KYCVerificationDate) as KYCVerificationDate,    
    IsNull(stg.KYCVerificationBranch,Client.KYCVerificationBranch) as KYCVerificationBranch,    
    IsNull(stg.MotherTitle,Client.MotherTitle) as MotherTitle,    
    IsNull(stg.MotherFirstName,Client.MotherFirstName) as MotherFirstName,    
    IsNull(stg.MotherMiddleName,Client.MotherMiddleName) as MotherMiddleName,    
    IsNull(stg.MotherLastName,Client.MotherLastName) as MotherLastName,    
    IsNull(stg.SpouseTitle,Client.SpouseTitle) as SpouseTitle,    
    IsNull(stg.SpouseFirstName,Client.SpouseFirstName) as SpouseFirstName,    
    IsNull(stg.SpouseMiddleName,Client.SpouseMiddleName) as SpouseMiddleName,    
    IsNull(stg.SpouseLastName,Client.SpouseLastName) as SpouseLastName,    
    IsNull(stg.FatherTitle,Client.FatherTitle) as FatherTitle,    
    IsNull(stg.FatherFirstName,Client.FatherFirstName) as FatherFirstName,    
    IsNull(stg.FatherMiddleName,Client.FatherMiddleName) as FatherMiddleName,    
    IsNull(stg.FatherLastName,Client.FatherLastName) as FatherLastName,    
    IsNull(stg.MaidenTitle,Client.MaidenTitle) as MaidenTitle,    
    IsNull(stg.MaidenFirstName,Client.MaidenFirstName) as MaidenFirstName,    
    IsNull(stg.MaidenMiddleName,Client.MaidenMiddleName) as MaidenMiddleName,    
    IsNull(stg.MaidenLastName,Client.MaidenLastName) as MaidenLastName,    
    IsNull(stg.CIN,Client.CIN) as CIN,    
    IsNull(stg.KYCPlaceOfDeclaration,Client.KYCPlaceOfDeclaration) as KYCPlaceOfDeclaration,    
    IsNull(stg.NomineePAN,Client.NomineePAN) as NomineePAN,    
    IsNull(stg.NomineeAadhar,Client.NomineeAadhar) as NomineeAadhar,    
    IsNull(stg.NomineeEmail,Client.NomineeEmail) as NomineeEmail,    
    IsNull(stg.NomineeISD,Client.NomineeISD) as NomineeISD,    
    IsNull(stg.TaxResidencyOutsideIndiaRefEnumValueId,Client.TaxResidencyOutsideIndiaRefEnumValueId) as TaxResidencyOutsideIndiaRefEnumValueId,    
    IsNull(stg.AutomaticCreditRefEnumValueId,Client.AutomaticCreditRefEnumValueId) as AutomaticCreditRefEnumValueId,    
    IsNull(stg.AccountStatementRefEnumValueId,Client.AccountStatementRefEnumValueId) as AccountStatementRefEnumValueId,    
    IsNull(stg.StatementByEmailRefEnumValueId,Client.StatementByEmailRefEnumValueId) as StatementByEmailRefEnumValueId,    
    IsNull(stg.ShareEmailWithRTARefEnumValueId,Client.ShareEmailWithRTARefEnumValueId) as ShareEmailWithRTARefEnumValueId,    
    IsNull(stg.ReceiveRTADocumentRefEnumValueId,Client.ReceiveRTADocumentRefEnumValueId) as ReceiveRTADocumentRefEnumValueId,    
    IsNull(stg.DividendCreditInBankRefEnumValueId,Client.DividendCreditInBankRefEnumValueId) as DividendCreditInBankRefEnumValueId,    
    IsNull(stg.SMSAlertFacilityRefEnumValueId,Client.SMSAlertFacilityRefEnumValueId) as SMSAlertFacilityRefEnumValueId,    
    IsNull(stg.DematFeesRefEnumValueId,Client.DematFeesRefEnumValueId) as DematFeesRefEnumValueId,    
    IsNull(stg.PanFirstName,Client.PanFirstName) as PanFirstName,    
    IsNull(stg.PanMiddleName,Client.PanMiddleName) as PanMiddleName,    
    IsNull(stg.PanLastName,Client.PanLastName) as PanLastName,    
    IsNull(stg.FirstHolderTitle,Client.FirstHolderTitle) as FirstHolderTitle,    
    IsNull(stg.ResidentialStatusRefEnumValueId,Client.ResidentialStatusRefEnumValueId) as ResidentialStatusRefEnumValueId,    
    IsNull(stg.CountryOfBirthRefCountryId,Client.CountryOfBirthRefCountryId) as CountryOfBirthRefCountryId,    
    IsNull(stg.JurisdictionOfResidenceRefCountryId,Client.JurisdictionOfResidenceRefCountryId) as JurisdictionOfResidenceRefCountryId,    
    IsNull(stg.TaxIdentificationNumber,Client.TaxIdentificationNumber) as TaxIdentificationNumber,    
    IsNull(stg.PermanentProofRefAttachmentId,Client.PermanentProofRefAttachmentId) as PermanentProofRefAttachmentId,    
    CASE WHEN stg.UpdateCorrespondenceLocalAddress = 1 THEN stg.CorrespondenceLocalAddressLine1 ELSE Client.CorrespondenceLocalAddressLine1 END as CorrespondenceLocalAddressLine1,    
    CASE WHEN stg.UpdateCorrespondenceLocalAddress = 1 THEN stg.CorrespondenceLocalAddressLine2 ELSE Client.CorrespondenceLocalAddressLine2 END as CorrespondenceLocalAddressLine2,    
    CASE WHEN stg.UpdateCorrespondenceLocalAddress = 1 THEN stg.CorrespondenceLocalAddressLine3 ELSE Client.CorrespondenceLocalAddressLine3 END as CorrespondenceLocalAddressLine3,     
    CASE WHEN stg.UpdateCorrespondenceLocalAddress = 1 THEN stg.CorrespondenceLocalPin ELSE Client.CorrespondenceLocalPin END as CorrespondenceLocalPin,    
    CASE WHEN stg.UpdateCorrespondenceLocalAddress = 1 THEN stg.CorrespondenceLocalDistrict ELSE Client.CorrespondenceLocalDistrict END as CorrespondenceLocalDistrict,    
    CASE WHEN stg.UpdateCorrespondenceLocalAddress = 1 THEN stg.CorrespondenceLocalCity ELSE Client.CorrespondenceLocalCity END as CorrespondenceLocalCity,    
    CASE WHEN stg.UpdateCorrespondenceLocalAddress = 1 THEN stg.CorrespondenceLocalState ELSE Client.CorrespondenceLocalState END as CorrespondenceLocalState,    
    CASE WHEN stg.UpdateCorrespondenceLocalAddress = 1 THEN stg.CorrespondenceLocalRefCountyId ELSE Client.CorrespondenceLocalRefCountyId END as CorrespondenceLocalRefCountyId,    
    CASE WHEN stg.UpdateTaxResidencyAddress = 1 THEN stg.TaxResidencyAddressLine1 ELSE Client.TaxResidencyAddressLine1 END as TaxResidencyAddressLine1,    
    CASE WHEN stg.UpdateTaxResidencyAddress = 1 THEN stg.TaxResidencyAddressLine2 ELSE Client.TaxResidencyAddressLine2 END as TaxResidencyAddressLine2,    
    CASE WHEN stg.UpdateTaxResidencyAddress = 1 THEN stg.TaxResidencyAddressLine3 ELSE Client.TaxResidencyAddressLine3 END as TaxResidencyAddressLine3,    
    CASE WHEN stg.UpdateTaxResidencyAddress = 1 THEN stg.TaxResidencyPin ELSE Client.TaxResidencyPin END as TaxResidencyPin,    
    CASE WHEN stg.UpdateTaxResidencyAddress = 1 THEN stg.TaxResidencyDistrict ELSE Client.TaxResidencyDistrict END as TaxResidencyDistrict,    
    CASE WHEN stg.UpdateTaxResidencyAddress = 1 THEN stg.TaxResidencyCity ELSE Client.TaxResidencyCity END as TaxResidencyCity,    
    CASE WHEN stg.UpdateTaxResidencyAddress = 1 THEN stg.TaxResidencyState ELSE Client.TaxResidencyState END as TaxResidencyState,    
    IsNull(stg.TaxResidencyRefCountryId,Client.TaxResidencyRefCountryId) as TaxResidencyRefCountryId,    
    IsNull(stg.ResidentialSTDCode,Client.ResidentialSTDCode) as ResidentialSTDCode,    
    IsNull(stg.ResidentialTelephoneNumber,Client.ResidentialTelephoneNumber) as ResidentialTelephoneNumber,    
    IsNull(stg.MobileISD,Client.MobileISD) as MobileISD,    
    IsNull(stg.FaxSTD,Client.FaxSTD) as FaxSTD,    
    IsNull(stg.FaxNumber,Client.FaxNumber) as FaxNumber,    
    IsNull(stg.POIRefIdentificationTypeId,Client.POIRefIdentificationTypeId) as POIRefIdentificationTypeId,    
    IsNull(stg.LastModifiedExternal,Client.LastModifiedExternal) as LastModifiedExternal,    
                IsNull(stg.AddedBy,'System') as LastEditedBy ,    
                GETDATE() as EditedOn,    
                CONVERT(DECIMAL(19, 6), @IncomeMultiplier) as IncomeMultiplier ,     
                CONVERT(DECIMAL(19, 6), @NetworthMultiplier) as NetworthMultiplier,    
    
    IsNull(stg.RefBOStatusId,client.RefBOStatusId) as RefBOStatusId,    
    IsNull(stg.SuspendedDate,client.SuspendedDate) as SuspendedDate,    
    IsNull(stg.IsNomineeMinor,client.IsNomineeMinor) as IsNomineeMinor,    
    IsNull(stg.MinorNomineeGuardianLastName,client.MinorNomineeGuardianLastName) as MinorNomineeGuardianLastName,    
    IsNull(stg.MinorNomineeGuardianAddress1,client.MinorNomineeGuardianAddress1) as MinorNomineeGuardianAddress1,    
    IsNull(stg.MinorNomineeGuardianAddress2,client.MinorNomineeGuardianAddress2) as MinorNomineeGuardianAddress2,    
    IsNull(stg.MinorNomineeGuardianAddress3,client.MinorNomineeGuardianAddress3) as MinorNomineeGuardianAddress3,    
    IsNull(stg.MinorNomineeGuardianAddress4,client.MinorNomineeGuardianAddress4) as MinorNomineeGuardianAddress4,    
    IsNull(stg.MinorNomineeGuardianMiddleName,client.MinorNomineeGuardianMiddleName ) as MinorNomineeGuardianMiddleName,    
    IsNull(stg.MinorNomineeGuardianFirstName,client.MinorNomineeGuardianFirstName ) as MinorNomineeGuardianFirstName,    
    IsNull(stg.MinorNomineeGuardianPin,client.MinorNomineeGuardianPin ) as MinorNomineeGuardianPin,    
    IsNull(stg.MinorNomineeDateOfBirth,client.MinorNomineeDateOfBirth ) as MinorNomineeDateOfBirth,    
    IsNull(stg.GuardianAddressLine4,client.GuardianAddressLine4) as GuardianAddressLine4,    
    IsNull(stg.NomineeAddressLine4,client.NomineeAddressLine4) as NomineeAddressLine4,    
    --isnull(stg. BseMfOccupationType,client. BseMfOccupationType )    
    IsNull(stg. AccountStatus,client.AccountStatus) as AccountStatus,    
    --isnull(stg. SpecialCategory,client.SpecialCategory)    
    IsNull(stg. RefBoSubstatusId,client.RefBoSubstatusId) as RefBoSubstatusId,    
    --stg.BseMfOccupationType as BseMfOccupationType,    
    stg.SpecialCategory as SpecialCategory,    
    IsNull(stg.ApplicationFormNumber,Client.ApplicationFormNumber) AS ApplicationFormNumber,    
                IsNull(stg.OnboardingRecordIdentifier,Client.OnboardingRecordIdentifier) AS OnboardingRecordIdentifier    
    
  INTO #finalRefclientInsertfromStaging    
  FROM dbo.StagingClientRefresh stg    
  INNER JOIN dbo.RefClient Client on client.RefClientDatabaseEnumId = stg.RefClientDatabaseEnumId AND client.ClientId = stg.ClientId    
        AND ISNULL(client.DpId,0) = ISNULL(stg.DpId,0)    
  AND (    
  Client.FamilyCode<>IsNull(stg.FamilyCode,Client.FamilyCode) OR    
    Client.Name<>IsNull(stg.Name,Client.Name) OR    
    isnull(Client.Email,'')<>IsNull(stg.Email,Client.Email) OR    
    isnull(Client.Phone1,'')<>IsNull(stg.Phone1,Client.Phone1) OR    
    isnull(Client.Phone2,'')<>IsNull(stg.Phone2,Client.Phone2) OR    
    isnull(Client.Phone3,'')<>IsNull(stg.Phone3,Client.Phone3) OR    
    isnull(Client.Mobile,'')<>IsNull(stg.Mobile,Client.Mobile) OR    
    isnull(Client.TaxStatusType,0)<>IsNull(stg.TaxStatusType,Client.TaxStatusType) OR    
    isnull(Client.RefBseMfOccupationTypeId,0)<>IsNull(stg.RefBseMfOccupationTypeId,Client.RefBseMfOccupationTypeId) OR   
    isnull(Client.Dob,getdate())<>IsNull(stg.Dob,Client.Dob) OR    
    isnull(Client.Gender,'')<>IsNull(stg.Gender,Client.Gender) OR    
    isnull(Client.FatherName,'')<>IsNull(stg.FatherName,Client.FatherName) OR    
    isnull(Client.PAN,'')<>IsNull(stg.PAN,Client.PAN) OR    
    isnull(Client.GuradianPAN,'')<>IsNull(stg.GuradianPAN,Client.GuradianPAN) OR    
    isnull(Client.RefClientStatusId,0)<>IsNull(stg.RefClientStatusId,Client.RefClientStatusId) OR    
    isnull(Client.RefIntermediaryId,0)<>IsNull(stg.RefIntermediaryId,Client.RefIntermediaryId) OR    
    isnull(Client.RefConstitutionTypeId,0)<>IsNull(stg.RefConstitutionTypeId,Client.RefConstitutionTypeId) OR    
    isnull(Client.SecondHolderRefSalutationId,0)<>IsNull(stg.SecondHolderRefSalutationId,Client.SecondHolderRefSalutationId) OR    
    isnull(Client.SecondHolderFirstName,'')<>IsNull(stg.SecondHolderFirstName,Client.SecondHolderFirstName) OR    
    isnull(Client.SecondHolderMiddleName,'')<>IsNull(stg.SecondHolderMiddleName,Client.SecondHolderMiddleName) OR    
    isnull(Client.SecondHolderLastName,'')<>IsNull(stg.SecondHolderLastName,Client.SecondHolderLastName) OR    
    isnull(Client.SecondHolderGender,'')<>IsNull(stg.SecondHolderGender,Client.SecondHolderGender) OR    
    isnull(Client.SecondHolderDOB,GETDATE())<>IsNull(stg.SecondHolderDOB,Client.SecondHolderDOB) OR    
    isnull(Client.SecondHolderPAN,'')<>IsNull(stg.SecondHolderPAN,Client.SecondHolderPAN) OR    
    isnull(Client.SecondHolderFatherOrHusbandName,'')<>IsNull(stg.SecondHolderFatherOrHusbandName,Client.SecondHolderFatherOrHusbandName) OR    
    isnull(Client.SecondHolderRefConstitutionTypeId,0)<>IsNull(stg.SecondHolderRefConstitutionTypeId,Client.SecondHolderRefConstitutionTypeId) OR    
    isnull(Client.ThirdHolderSalutationId,0)<>IsNull(stg.ThirdHolderSalutationId,Client.ThirdHolderSalutationId) OR    
    isnull(Client.ThirdHolderFirstName,'')<>IsNull(stg.ThirdHolderFirstName,Client.ThirdHolderFirstName) OR    
    isnull(Client.ThirdHolderMiddleName,'')<>IsNull(stg.ThirdHolderMiddleName,Client.ThirdHolderMiddleName) OR    
    isnull(Client.ThirdHolderLastName,'')<>IsNull(stg.ThirdHolderLastName,Client.ThirdHolderLastName) OR    
    isnull(Client.ThirdHolderGender,'')<>IsNull(stg.ThirdHolderGender,Client.ThirdHolderGender) OR    
    isnull(Client.ThirdHolderDOB,GETDATE())<>IsNull(stg.ThirdHolderDOB,Client.ThirdHolderDOB) OR    
    isnull(Client.ThirdHolderPAN,'')<>IsNull(stg.ThirdHolderPAN,Client.ThirdHolderPAN) OR    
    isnull(Client.ThirdHolderFatherOrHusbandName,'')<>IsNull(stg.ThirdHolderFatherOrHusbandName,Client.ThirdHolderFatherOrHusbandName) OR    
    isnull(Client.ThirdHoldeRefConstitutionTypeId,0)<>IsNull(stg.ThirdHoldeRefConstitutionTypeId,Client.ThirdHoldeRefConstitutionTypeId) OR    
    isnull(Client.NomineeFirstName,'')<>IsNull(stg.NomineeFirstName,Client.NomineeFirstName) OR    
    isnull(Client.NomineeMiddleName,'')<>IsNull(stg.NomineeMiddleName,Client.NomineeMiddleName) OR    
    isnull(Client.NomineeLastName,'')<>IsNull(stg.NomineeLastName,Client.NomineeLastName) OR    
    isnull(Client.NomineeRelationshipWithFirstHolder,'')<>IsNull(stg.NomineeRelationshipWithFirstHolder,Client.NomineeRelationshipWithFirstHolder) OR    
    isnull(Client.NomineeRelationshipWithSecondHolder,'')<>IsNull(stg.NomineeRelationshipWithSecondHolder,Client.NomineeRelationshipWithSecondHolder) OR    
    isnull(Client.NomineeRelationshipWithThirdHolder,'')<>IsNull(stg.NomineeRelationshipWithThirdHolder,Client.NomineeRelationshipWithThirdHolder) OR    
    isnull(Client.NomineePhone,'')<>IsNull(stg.NomineePhone,Client.NomineePhone) OR    
    isnull(Client.NomineeDOB,getdate())<>IsNull(stg.NomineeDOB,Client.NomineeDOB) OR    
    isnull(Client.GuardianFirstName,'')<>IsNull(stg.GuardianFirstName,Client.GuardianFirstName) OR    
    isnull(Client.GuardianMiddleName,'')<>IsNull(stg.GuardianMiddleName,Client.GuardianMiddleName) OR    
    isnull(Client.GuardianLastName,'')<>IsNull(stg.GuardianLastName,Client.GuardianLastName) OR    
    isnull(Client.GuardianRelationship,'')<>IsNull(stg.GuardianRelationship,Client.GuardianRelationship) OR    
    isnull(Client.GuardianPhone,'')<>IsNull(stg.GuardianPhone,Client.GuardianPhone) OR    
    isnull(Client.EmployerName,'')<>IsNull(stg.EmployerName,Client.EmployerName) OR    
    isnull(Client.EmployerAddress,'')<>IsNull(stg.EmployerAddress,Client.EmployerAddress) OR    
    isnull(Client.EmployerBusinessNature,'')<>IsNull(stg.EmployerBusinessNature,Client.EmployerBusinessNature) OR    
    isnull(Client.EmployerPhone,'')<>IsNull(stg.EmployerPhone,Client.EmployerPhone) OR    
    isnull(Client.AccountOpeningDate,getdate())<>IsNull(stg.AccountOpeningDate,Client.AccountOpeningDate) OR    
    isnull(Client.AccountClosingDate,getdate())<>IsNull(stg.AccountClosingDate,Client.AccountClosingDate) OR    
    isnull(Client.Nationality,0)<>IsNull(stg.Nationality,Client.Nationality) OR    
    isnull(Client.RefCustomRiskId,0)<>IsNull(stg.RefCustomRiskId,Client.RefCustomRiskId) OR    
    isnull(Client.RefMaritalStatusId,0)<>IsNull(stg.RefMaritalStatusId,Client.RefMaritalStatusId) OR    
    isnull(Client.RefPEPId,0)<>IsNull(stg.RefPEPId,Client.RefPEPId) OR    
    isnull(Client.ISDCode1,'')<>IsNull(stg.ISDCode1,Client.ISDCode1) OR    
    isnull(Client.STDCode1,'')<>IsNull(stg.STDCode1,Client.STDCode1) OR    
    isnull(Client.ISDCode2,'')<>IsNull(stg.ISDCode2,Client.ISDCode2) OR    
    isnull(Client.STDCode2,'')<>IsNull(stg.STDCode2,Client.STDCode2) OR    
    isnull(Client.ISDCode3,'')<>IsNull(stg.ISDCode3,Client.ISDCode3) OR    
    isnull(Client.STDCode3,'')<>IsNull(stg.STDCode3,Client.STDCode3) OR    
    isnull(Client.Aadhar,'')<>IsNull(stg.Aadhar,Client.Aadhar) OR    
    isnull(Client.PlaceOfIncorporation,'')<>IsNull(stg.PlaceOfIncorporation,Client.PlaceOfIncorporation) OR    
    isnull(Client.RefProfileRatingMasterId,0)<>IsNull(stg.RefProfileRatingMasterId,Client.RefProfileRatingMasterId) OR    
    --isnull(Client.DpId,0)<>IsNull(stg.DpId,Client.DpId) OR    
    isnull(Client.SecondHolderEmail,'')<>IsNull(stg.SecondHolderEmail,Client.SecondHolderEmail) OR    
    isnull(Client.SecondHolderMobile,'')<>IsNull(stg.SecondHolderMobile,Client.SecondHolderMobile) OR    
    isnull(Client.ThirdHolderEmail,'')<>IsNull(stg.ThirdHolderEmail,Client.ThirdHolderEmail) OR    
    isnull(Client.ThirdHolderMobile,'')<>IsNull(stg.ThirdHolderMobile,Client.ThirdHolderMobile) OR    
    isnull(Client.GuardianDOB,getdate())<>IsNull(stg.GuardianDOB,Client.GuardianDOB) OR    
    isnull(Client.SecondHolderRefCRMCustomerId,0)<>IsNull(stg.SecondHolderRefCRMCustomerId,Client.SecondHolderRefCRMCustomerId) OR    
    isnull(Client.ThirdHolderRefCRMCustomerId,0)<>IsNull(stg.ThirdHolderRefCRMCustomerId,Client.ThirdHolderRefCRMCustomerId) OR    
    isnull(Client.RefClientAccountStatusId,'')<>IsNull(stg.RefClientAccountStatusId,Client.RefClientAccountStatusId) OR    
    isnull(Client.FirstName,'')<>IsNull(stg.FirstName,Client.FirstName) OR    
    isnull(Client.MiddleName,'')<>IsNull(stg.MiddleName,Client.MiddleName) OR    
    isnull(Client.LastName,'')<>IsNull(stg.LastName,Client.LastName) OR    
    isnull(Client.KYCEmployeeCode,'')<>IsNull(stg.KYCEmployeeCode,Client.KYCEmployeeCode) OR    
    isnull(Client.KYCEmployeeDesignation,'')<>IsNull(stg.KYCEmployeeDesignation,Client.KYCEmployeeDesignation) OR    
    isnull(Client.KYCEmployeeName,'')<>IsNull(stg.KYCEmployeeName,Client.KYCEmployeeName) OR    
    isnull(Client.KYCDeclarationDate,'')<>IsNull(stg.KYCDeclarationDate,Client.KYCDeclarationDate) OR    
    isnull(Client.KYCVerificationDate,'')<>IsNull(stg.KYCVerificationDate,Client.KYCVerificationDate) OR    
    isnull(Client.KYCVerificationBranch,'')<>IsNull(stg.KYCVerificationBranch,Client.KYCVerificationBranch) OR    
    isnull(Client.MotherTitle,'')<>IsNull(stg.MotherTitle,Client.MotherTitle) OR    
    isnull(Client.MotherFirstName,'')<>IsNull(stg.MotherFirstName,Client.MotherFirstName) OR    
    isnull(Client.MotherMiddleName,'')<>IsNull(stg.MotherMiddleName,Client.MotherMiddleName) OR    
    isnull(Client.MotherLastName,'')<>IsNull(stg.MotherLastName,Client.MotherLastName) OR    
    isnull(Client.SpouseTitle,'')<>IsNull(stg.SpouseTitle,Client.SpouseTitle) OR    
    isnull(Client.SpouseFirstName,'')<>IsNull(stg.SpouseFirstName,Client.SpouseFirstName) OR    
    isnull(Client.SpouseMiddleName,'')<>IsNull(stg.SpouseMiddleName,Client.SpouseMiddleName) OR    
    isnull(Client.SpouseLastName,'')<>IsNull(stg.SpouseLastName,Client.SpouseLastName) OR    
    isnull(Client.FatherTitle,'')<>IsNull(stg.FatherTitle,Client.FatherTitle) OR    
    isnull(Client.FatherFirstName,'')<>IsNull(stg.FatherFirstName,Client.FatherFirstName) OR    
    isnull(Client.FatherMiddleName,'')<>IsNull(stg.FatherMiddleName,Client.FatherMiddleName) OR    
    isnull(Client.FatherLastName,'')<>IsNull(stg.FatherLastName,Client.FatherLastName) OR    
    isnull(Client.MaidenTitle,'')<>IsNull(stg.MaidenTitle,Client.MaidenTitle) Or    
    isnull(Client.MaidenFirstName,'')<>IsNull(stg.MaidenFirstName,Client.MaidenFirstName) OR    
    isnull(Client.MaidenMiddleName,'')<>IsNull(stg.MaidenMiddleName,Client.MaidenMiddleName) OR    
    isnull(Client.MaidenLastName,'')<>IsNull(stg.MaidenLastName,Client.MaidenLastName) OR    
    isnull(Client.CIN,'')<>IsNull(stg.CIN,Client.CIN) OR    
    isnull(Client.KYCPlaceOfDeclaration,'')<>IsNull(stg.KYCPlaceOfDeclaration,Client.KYCPlaceOfDeclaration) OR    
    isnull(Client.NomineePAN,'')<>IsNull(stg.NomineePAN,Client.NomineePAN) OR    
    isnull(Client.NomineeAadhar,'')<>IsNull(stg.NomineeAadhar,Client.NomineeAadhar) OR    
    isnull(Client.NomineeEmail,'')<>IsNull(stg.NomineeEmail,Client.NomineeEmail) OR    
    isnull(Client.NomineeISD,'')<>IsNull(stg.NomineeISD,Client.NomineeISD) OR    
    isnull(Client.TaxResidencyOutsideIndiaRefEnumValueId,0)<>IsNull(stg.TaxResidencyOutsideIndiaRefEnumValueId,Client.TaxResidencyOutsideIndiaRefEnumValueId)OR    
    isnull(Client.AutomaticCreditRefEnumValueId,0)<>IsNull(stg.AutomaticCreditRefEnumValueId,Client.AutomaticCreditRefEnumValueId) OR    
    isnull(Client.AccountStatementRefEnumValueId,0)<>IsNull(stg.AccountStatementRefEnumValueId,Client.AccountStatementRefEnumValueId) OR    
    isnull(Client.StatementByEmailRefEnumValueId,0)<>IsNull(stg.StatementByEmailRefEnumValueId,Client.StatementByEmailRefEnumValueId) OR    
    isnull(Client.ShareEmailWithRTARefEnumValueId,0)<>IsNull(stg.ShareEmailWithRTARefEnumValueId,Client.ShareEmailWithRTARefEnumValueId) OR    
    isnull(Client.ReceiveRTADocumentRefEnumValueId,0)<>IsNull(stg.ReceiveRTADocumentRefEnumValueId,Client.ReceiveRTADocumentRefEnumValueId) OR    
    isnull(Client.DividendCreditInBankRefEnumValueId,0)<>IsNull(stg.DividendCreditInBankRefEnumValueId,Client.DividendCreditInBankRefEnumValueId) OR    
    isnull(Client.SMSAlertFacilityRefEnumValueId,0)<>IsNull(stg.SMSAlertFacilityRefEnumValueId,Client.SMSAlertFacilityRefEnumValueId) OR    
    isnull(Client.DematFeesRefEnumValueId,0)<>IsNull(stg.DematFeesRefEnumValueId,Client.DematFeesRefEnumValueId) OR    
    isnull(Client.PanFirstName,'')<>IsNull(stg.PanFirstName,Client.PanFirstName) OR    
    isnull(Client.PanMiddleName,'')<>IsNull(stg.PanMiddleName,Client.PanMiddleName) oR    
    isnull(Client.PanLastName,'')<>IsNull(stg.PanLastName,Client.PanLastName) OR    
    isnull(Client.FirstHolderTitle,'')<>IsNull(stg.FirstHolderTitle,Client.FirstHolderTitle) OR    
    isnull(Client.ResidentialStatusRefEnumValueId,0)<>IsNull(stg.ResidentialStatusRefEnumValueId,Client.ResidentialStatusRefEnumValueId) OR    
    isnull(Client.CountryOfBirthRefCountryId,0)<>IsNull(stg.CountryOfBirthRefCountryId,Client.CountryOfBirthRefCountryId) OR    
    isnull(Client.JurisdictionOfResidenceRefCountryId,0)<>IsNull(stg.JurisdictionOfResidenceRefCountryId,Client.JurisdictionOfResidenceRefCountryId) OR    
    isnull(Client.TaxIdentificationNumber,'')<>IsNull(stg.TaxIdentificationNumber,Client.TaxIdentificationNumber) OR    
    isnull(Client.PermanentProofRefAttachmentId,0)<>IsNull(stg.PermanentProofRefAttachmentId,Client.PermanentProofRefAttachmentId) OR    
    isnull(Client.TaxResidencyRefCountryId,0)<>IsNull(stg.TaxResidencyRefCountryId,Client.TaxResidencyRefCountryId) OR    
    isnull(Client.ResidentialSTDCode,'')<>IsNull(stg.ResidentialSTDCode,Client.ResidentialSTDCode) Or    
    isnull(Client.ResidentialTelephoneNumber,'')<>IsNull(stg.ResidentialTelephoneNumber,Client.ResidentialTelephoneNumber) OR    
    isnull(Client.MobileISD,'')<>IsNull(stg.MobileISD,Client.MobileISD) OR    
    isnull(Client.FaxSTD,'')<>IsNull(stg.FaxSTD,Client.FaxSTD) OR    
    isnull(Client.FaxNumber,'')<>IsNull(stg.FaxNumber,Client.FaxNumber) OR    
    isnull(Client.POIRefIdentificationTypeId,0)<>IsNull(stg.POIRefIdentificationTypeId,Client.POIRefIdentificationTypeId) OR    
    isnull(Client.LastModifiedExternal,getdate())<>IsNull(stg.LastModifiedExternal,Client.LastModifiedExternal) OR    
                isnull(Client.IncomeMultiplier,0.000) <> CONVERT(DECIMAL(19, 6), @IncomeMultiplier) OR    
                isnull(Client.NetworthMultiplier,0.000) <> CONVERT(DECIMAL(19, 6), @NetworthMultiplier) OR    
    isnull(client.RefBOStatusId,0)<>isnull(stg.RefBOStatusId,Client.RefBOStatusId) OR    
    isnull(client.SuspendedDate,GETDATE())<>isnull(stg.SuspendedDate,Client.SuspendedDate) OR    
    isnull(client.IsNomineeMinor,0)<>isnull(stg.IsNomineeMinor,Client.IsNomineeMinor) OR    
    isnull(client.MinorNomineeGuardianLastName,'')<>IsNull(stg.MinorNomineeGuardianLastName,client.MinorNomineeGuardianLastName)OR    
    isnull(client.MinorNomineeGuardianAddress1,'')<>IsNull(stg.MinorNomineeGuardianAddress1,client.MinorNomineeGuardianAddress1)OR    
    isnull(client.MinorNomineeGuardianAddress2,'')<>IsNull(stg.MinorNomineeGuardianAddress2,client.MinorNomineeGuardianAddress2)OR    
    IsNull(client.MinorNomineeGuardianAddress3,'')<>IsNull(stg.MinorNomineeGuardianAddress3,client.MinorNomineeGuardianAddress3)OR    
    IsNull(client.MinorNomineeGuardianAddress4,'')<>IsNull(stg.MinorNomineeGuardianAddress4,client.MinorNomineeGuardianAddress4)OR    
    IsNull(client.MinorNomineeGuardianMiddleName,'')<>IsNull(stg.MinorNomineeGuardianMiddleName,client.MinorNomineeGuardianMiddleName)OR    
    IsNull(client.MinorNomineeGuardianFirstName,'')<>IsNull(stg.MinorNomineeGuardianFirstName,client.MinorNomineeGuardianFirstName)OR    
    IsNull(client.MinorNomineeGuardianPin,'')<>IsNull(stg.MinorNomineeGuardianPin,client.MinorNomineeGuardianPin)OR    
    IsNull(client.MinorNomineeDateOfBirth,GETDATE())<>IsNull(stg.MinorNomineeDateOfBirth,client.MinorNomineeDateOfBirth)OR    
    IsNull(client.GuardianAddressLine4,'')<>IsNull(stg.GuardianAddressLine4,client.GuardianAddressLine4)OR    
    IsNull(client.NomineeAddressLine4,'')<>IsNull(stg.NomineeAddressLine4,client.NomineeAddressLine4)OR    
    --isnull(client.BseMfOccupationType,'')<>isnull(stg.BseMfOccupationType ,)OR    
    IsNull(client.AccountStatus,0)<>isnull(stg.AccountStatus,Client.AccountStatus)OR    
    --isnull(client.SpecialCategory,)<>isnull(stg.SpecialCategory ,)OR    
    IsNull(client.RefBoSubstatusId,0)<>isnull(stg.RefBoSubstatusId,client.RefBoSubstatusId) OR     
    IsNull(Client.ApplicationFormNumber,'')<>IsNull(stg.ApplicationFormNumber,Client.ApplicationFormNumber) OR    
                IsNull(Client.OnboardingRecordIdentifier,'')<>IsNull(stg.OnboardingRecordIdentifier,Client.OnboardingRecordIdentifier)    
  )    
  AND (stg.GUID = @GuidInternal OR isnull(stg.GUID,'')='')    
    
      
	UPDATE  Client    
    SET        
    Client.FamilyCode=stg.FamilyCode,    
    Client.Name=stg.Name,    
    Client.Email=stg.Email,    
    Client.CAddressLine1=stg.CAddressLine1,    
    Client.CAddressLine2= stg.CAddressLine2,    
    Client.CAddressLine3= stg.CAddressLine3,    
    Client.CAddressCity = stg.CAddressCity,    
    Client.CAddressState= stg.CAddressState,    
    Client.CAddressCountry=stg.CAddressCountry ,    
    Client.CAddressPin = stg.CAddressPin,    
    Client.PAddressLine1=stg.PAddressLine1,    
    Client.PAddressLine2=stg.PAddressLine2,    
    Client.PAddressLine3=stg.PAddressLine3,    
    Client.PAddressCity=stg.PAddressCity,    
    Client.PAddressState=stg.PAddressState,    
    Client.PAddressCountry=stg.PAddressCountry,    
    Client.PAddressPin=stg.PAddressPin,    
    Client.Phone1=stg.Phone1,    
    Client.Phone2=stg.Phone2,    
    Client.Phone3=stg.Phone3,    
    Client.Mobile=stg.Mobile,    
    Client.TaxStatusType=stg.TaxStatusType,    
    Client.RefBseMfOccupationTypeId=stg.RefBseMfOccupationTypeId,    
    Client.Dob=stg.Dob,    
    Client.Gender=stg.Gender,    
    Client.FatherName=stg.FatherName,    
    Client.PAN=stg.PAN,    
    Client.GuradianPAN=stg.GuradianPAN,    
    Client.RefClientStatusId=stg.RefClientStatusId,    
    Client.RefIntermediaryId=stg.RefIntermediaryId,    
    Client.RefConstitutionTypeId=stg.RefConstitutionTypeId,    
    Client.SecondHolderRefSalutationId=stg.SecondHolderRefSalutationId,    
    Client.SecondHolderFirstName=stg.SecondHolderFirstName,    
    Client.SecondHolderMiddleName=stg.SecondHolderMiddleName,    
    Client.SecondHolderLastName=stg.SecondHolderLastName,    
    Client.SecondHolderGender=stg.SecondHolderGender,    
    Client.SecondHolderDOB=stg.SecondHolderDOB,    
    Client.SecondHolderPAN=stg.SecondHolderPAN,    
    Client.SecondHolderFatherOrHusbandName=stg.SecondHolderFatherOrHusbandName,    
    Client.SecondHolderRefConstitutionTypeId=stg.SecondHolderRefConstitutionTypeId,    
    Client.ThirdHolderSalutationId=stg.ThirdHolderSalutationId,    
    Client.ThirdHolderFirstName=stg.ThirdHolderFirstName,    
    Client.ThirdHolderMiddleName=stg.ThirdHolderMiddleName,    
    Client.ThirdHolderLastName=stg.ThirdHolderLastName,    
    Client.ThirdHolderGender=stg.ThirdHolderGender,    
    Client.ThirdHolderDOB=stg.ThirdHolderDOB,    
    Client.ThirdHolderPAN=stg.ThirdHolderPAN,    
    Client.ThirdHolderFatherOrHusbandName=stg.ThirdHolderFatherOrHusbandName,    
    Client.ThirdHoldeRefConstitutionTypeId=stg.ThirdHoldeRefConstitutionTypeId,    
    Client.NomineeFirstName=stg.NomineeFirstName,    
    Client.NomineeMiddleName=stg.NomineeMiddleName,    
    Client.NomineeLastName=stg.NomineeLastName,    
    Client.NomineeRelationshipWithFirstHolder=stg.NomineeRelationshipWithFirstHolder,    
    Client.NomineeRelationshipWithSecondHolder=stg.NomineeRelationshipWithSecondHolder,    
    Client.NomineeRelationshipWithThirdHolder=stg.NomineeRelationshipWithThirdHolder,    
    Client.NomineeAddressLine1=stg.NomineeAddressLine1,    
    Client.NomineeAddressLine2=stg.NomineeAddressLine2,    
    Client.NomineeAddressLine3=stg.NomineeAddressLine3,    
    Client.NomineeAddressCity= stg.NomineeAddressCity,    
    Client.NomineeAddressState=stg.NomineeAddressState,    
    Client.NomineeAddressRefCountryId=stg.NomineeAddressRefCountryId,    
    Client.NomineeAddressPin=stg.NomineeAddressPin,    
    Client.NomineePhone=stg.NomineePhone,    
    Client.NomineeDOB=stg.NomineeDOB,    
    Client.GuardianFirstName=stg.GuardianFirstName,    
    Client.GuardianMiddleName=stg.GuardianMiddleName,    
    Client.GuardianLastName=stg.GuardianLastName,    
    Client.GuardianRelationship=stg.GuardianRelationship,    
    Client.GuardianAddressLine1=stg.GuardianAddressLine1,    
    Client.GuardianAddressLine2=stg.GuardianAddressLine2,    
    Client.GuardianAddressLine3=stg.GuardianAddressLine3,    
    Client.GuardianAddressCity=stg.GuardianAddressCity,    
    Client.GuardianAddressState=stg.GuardianAddressState,    
    Client.GuardianAddressRefCountryId=stg.GuardianAddressRefCountryId,    
    Client.GuardianAddressPin=stg.GuardianAddressPin,    
    Client.GuardianPhone=stg.GuardianPhone,    
    Client.EmployerName=stg.EmployerName,    
    Client.EmployerAddress=stg.EmployerAddress,    
    Client.EmployerBusinessNature=stg.EmployerBusinessNature,    
    Client.EmployerPhone=stg.EmployerPhone,    
    Client.AccountOpeningDate=stg.AccountOpeningDate,    
    Client.AccountClosingDate=stg.AccountClosingDate,    
    Client.Nationality=stg.Nationality,    
    Client.RefCustomRiskId=stg.RefCustomRiskId,    
    Client.RefMaritalStatusId=stg.RefMaritalStatusId,    
    Client.RefPEPId=stg.RefPEPId,    
    Client.ISDCode1=stg.ISDCode1,    
    Client.STDCode1=stg.STDCode1,    
    Client.ISDCode2=stg.ISDCode2,    
    Client.STDCode2=stg.STDCode2,    
    Client.ISDCode3=stg.ISDCode3,    
    Client.STDCode3=stg.STDCode3,    
    Client.Aadhar=stg.Aadhar,    
    Client.PlaceOfIncorporation=stg.PlaceOfIncorporation,    
    Client.RefProfileRatingMasterId=stg.RefProfileRatingMasterId,    
    Client.DpId=stg.DpId,    
    Client.SecondHolderEmail=stg.SecondHolderEmail,    
    Client.SecondHolderMobile=stg.SecondHolderMobile,    
    Client.ThirdHolderEmail=stg.ThirdHolderEmail,    
    Client.ThirdHolderMobile=stg.ThirdHolderMobile,    
    Client.GuardianDOB=stg.GuardianDOB,    
    Client.SecondHolderRefCRMCustomerId=stg.SecondHolderRefCRMCustomerId,    
    Client.ThirdHolderRefCRMCustomerId=stg.ThirdHolderRefCRMCustomerId,    
    Client.RefClientAccountStatusId=stg.RefClientAccountStatusId,    
    Client.FirstName=stg.FirstName,    
    Client.MiddleName=stg.MiddleName,    
    Client.LastName=stg.LastName,    
    Client.KYCEmployeeCode=stg.KYCEmployeeCode,    
    Client.KYCEmployeeDesignation=stg.KYCEmployeeDesignation,    
    Client.KYCEmployeeName=stg.KYCEmployeeName,    
    Client.KYCDeclarationDate=stg.KYCDeclarationDate,    
    Client.KYCVerificationDate=stg.KYCVerificationDate,    
    Client.KYCVerificationBranch=stg.KYCVerificationBranch,    
    Client.MotherTitle=stg.MotherTitle,    
    Client.MotherFirstName=stg.MotherFirstName,    
    Client.MotherMiddleName=stg.MotherMiddleName,    
    Client.MotherLastName=stg.MotherLastName,    
    Client.SpouseTitle=stg.SpouseTitle,    
    Client.SpouseFirstName=stg.SpouseFirstName,    
    Client.SpouseMiddleName=stg.SpouseMiddleName,    
    Client.SpouseLastName=stg.SpouseLastName,    
    Client.FatherTitle=stg.FatherTitle,    
    Client.FatherFirstName=stg.FatherFirstName,    
    Client.FatherMiddleName=stg.FatherMiddleName,    
    Client.FatherLastName=stg.FatherLastName,    
    Client.MaidenTitle=stg.MaidenTitle,    
    Client.MaidenFirstName=stg.MaidenFirstName,    
    Client.MaidenMiddleName=stg.MaidenMiddleName,    
    Client.MaidenLastName=stg.MaidenLastName,    
    Client.CIN=stg.CIN,    
    Client.KYCPlaceOfDeclaration=stg.KYCPlaceOfDeclaration,    
    Client.NomineePAN=stg.NomineePAN,    
    Client.NomineeAadhar=stg.NomineeAadhar,    
    Client.NomineeEmail=stg.NomineeEmail,    
    Client.NomineeISD=stg.NomineeISD,    
    Client.TaxResidencyOutsideIndiaRefEnumValueId=stg.TaxResidencyOutsideIndiaRefEnumValueId,    
    Client.AutomaticCreditRefEnumValueId=stg.AutomaticCreditRefEnumValueId,    
    Client.AccountStatementRefEnumValueId=stg.AccountStatementRefEnumValueId,    
    Client.StatementByEmailRefEnumValueId=stg.StatementByEmailRefEnumValueId,    
    Client.ShareEmailWithRTARefEnumValueId=stg.ShareEmailWithRTARefEnumValueId,    
    Client.ReceiveRTADocumentRefEnumValueId=stg.ReceiveRTADocumentRefEnumValueId,    
    Client.DividendCreditInBankRefEnumValueId=stg.DividendCreditInBankRefEnumValueId,    
    Client.SMSAlertFacilityRefEnumValueId=stg.SMSAlertFacilityRefEnumValueId,    
    Client.DematFeesRefEnumValueId=stg.DematFeesRefEnumValueId,    
    Client.PanFirstName=stg.PanFirstName,    
    Client.PanMiddleName=stg.PanMiddleName,    
    Client.PanLastName=stg.PanLastName,    
    Client.FirstHolderTitle=stg.FirstHolderTitle,    
    Client.ResidentialStatusRefEnumValueId=stg.ResidentialStatusRefEnumValueId,    
    Client.CountryOfBirthRefCountryId=stg.CountryOfBirthRefCountryId,    
    Client.JurisdictionOfResidenceRefCountryId=stg.JurisdictionOfResidenceRefCountryId,    
    Client.TaxIdentificationNumber=stg.TaxIdentificationNumber,    
    Client.PermanentProofRefAttachmentId=stg.PermanentProofRefAttachmentId,    
    Client.CorrespondenceLocalAddressLine1=stg.CorrespondenceLocalAddressLine1,    
    Client.CorrespondenceLocalAddressLine2=stg.CorrespondenceLocalAddressLine2,    
    Client.CorrespondenceLocalAddressLine3=stg.CorrespondenceLocalAddressLine3,    
    Client.CorrespondenceLocalPin=stg.CorrespondenceLocalPin,    
    Client.CorrespondenceLocalDistrict=stg.CorrespondenceLocalDistrict,    
    Client.CorrespondenceLocalCity=stg.CorrespondenceLocalCity,    
    Client.CorrespondenceLocalState=stg.CorrespondenceLocalState,    
    Client.CorrespondenceLocalRefCountyId=stg.CorrespondenceLocalRefCountyId,    
    Client.TaxResidencyAddressLine1=stg.TaxResidencyAddressLine1,    
    Client.TaxResidencyAddressLine2=stg.TaxResidencyAddressLine2,    
    Client.TaxResidencyAddressLine3=stg.TaxResidencyAddressLine3,    
    Client.TaxResidencyPin=stg.TaxResidencyPin,    
    Client.TaxResidencyDistrict=stg.TaxResidencyDistrict,    
    Client.TaxResidencyCity=stg.TaxResidencyCity,    
    Client.TaxResidencyState=stg.TaxResidencyState,    
    Client.TaxResidencyRefCountryId=stg.TaxResidencyRefCountryId,    
    Client.ResidentialSTDCode=stg.ResidentialSTDCode,    
    Client.ResidentialTelephoneNumber=stg.ResidentialTelephoneNumber,    
    Client.MobileISD=stg.MobileISD,    
    Client.FaxSTD=stg.FaxSTD,    
    Client.FaxNumber=stg.FaxNumber,    
    Client.POIRefIdentificationTypeId=stg.POIRefIdentificationTypeId,    
    Client.LastModifiedExternal=stg.LastModifiedExternal,    
                Client.LastEditedBy = stg.LastEditedBy,    
                Client.EditedOn =stg.EditedOn,    
                Client.IncomeMultiplier = stg.IncomeMultiplier,     
                Client.NetworthMultiplier = stg.NetworthMultiplier,    
    
    client.RefBOStatusId=stg.RefBOStatusId,    
    client.SuspendedDate=stg.SuspendedDate,    
    client.IsNomineeMinor=stg.IsNomineeMinor,    
    client.MinorNomineeGuardianLastName=stg.MinorNomineeGuardianLastName,    
    client.MinorNomineeGuardianAddress1=stg.MinorNomineeGuardianAddress1,    
    client.MinorNomineeGuardianAddress2=stg.MinorNomineeGuardianAddress2,    
    client.MinorNomineeGuardianAddress3=stg.MinorNomineeGuardianAddress3,    
    client.MinorNomineeGuardianAddress4=stg.MinorNomineeGuardianAddress4,    
    client.MinorNomineeGuardianMiddleName=stg.MinorNomineeGuardianMiddleName,    
    client.MinorNomineeGuardianFirstName=stg.MinorNomineeGuardianFirstName,    
    client.MinorNomineeGuardianPin=stg.MinorNomineeGuardianPin,    
    client.MinorNomineeDateOfBirth=stg.MinorNomineeDateOfBirth,    
    client.GuardianAddressLine4=stg.GuardianAddressLine4,    
    client.NomineeAddressLine4=stg.NomineeAddressLine4,    
    client.AccountStatus=stg.AccountStatus,    
    client.RefBoSubstatusId=stg.RefBoSubstatusId,    
                Client.ApplicationFormNumber=stg.ApplicationFormNumber,    
                Client.OnboardingRecordIdentifier=stg.OnboardingRecordIdentifier    
                    
        FROM    dbo.RefClient Client    
        INNER JOIN #finalRefclientInsertfromStaging stg ON client.RefClientDatabaseEnumId = stg.RefClientDatabaseEnumId    
                                                             AND client.ClientId = stg.ClientId    
                                                             AND ISNULL(client.DpId,    
                                                              0) = ISNULL(stg.DpId,    
                                                              0);    
         
    
     INSERT INTO dbo.RefClient    
     (RefClientDatabaseEnumId,    
     ClientId,    
     FamilyCode,    
     Name,    
     Email,    
     CAddressLine1,    
     CAddressLine2,    
     CAddressLine3,    
     CAddressCity,    
     CAddressState,    
     CAddressCountry,    
     CAddressPin,    
     PAddressLine1,    
     PAddressLine2,    
     PAddressLine3,    
     PAddressCity,    
     PAddressState,    
     PAddressCountry,    
     PAddressPin,    
     Phone1,    
     Phone2,    
     Phone3,    
     Mobile,    
     TaxStatusType,    
     RefBseMfOccupationTypeId,    
     Dob,    
     Gender,    
     FatherName,    
     PAN,    
     GuradianPAN,    
     RefClientStatusId,    
     RefIntermediaryId,    
     RefConstitutionTypeId,    
     SecondHolderRefSalutationId,    
     SecondHolderFirstName,    
     SecondHolderMiddleName,    
     SecondHolderLastName,    
     SecondHolderGender,    
     SecondHolderDOB,    
     SecondHolderPAN,    
     SecondHolderFatherOrHusbandName,    
     SecondHolderRefConstitutionTypeId,    
     ThirdHolderSalutationId,    
     ThirdHolderFirstName,    
     ThirdHolderMiddleName,    
     ThirdHolderLastName,    
     ThirdHolderGender,    
     ThirdHolderDOB,    
     ThirdHolderPAN,    
     ThirdHolderFatherOrHusbandName,    
     ThirdHoldeRefConstitutionTypeId,    
     NomineeFirstName,    
     NomineeMiddleName,    
     NomineeLastName,    
     NomineeRelationshipWithFirstHolder,    
     NomineeRelationshipWithSecondHolder,    
     NomineeRelationshipWithThirdHolder,    
     NomineeAddressLine1,    
     NomineeAddressLine2,    
     NomineeAddressLine3,    
     NomineeAddressCity,    
     NomineeAddressState,    
     NomineeAddressRefCountryId,    
     NomineeAddressPin,    
     NomineePhone,    
     NomineeDOB,    
     GuardianFirstName,    
     GuardianMiddleName,    
     GuardianLastName,    
     GuardianRelationship,    
     GuardianAddressLine1,    
     GuardianAddressLine2,    
     GuardianAddressLine3,    
     GuardianAddressCity,    
     GuardianAddressState,    
     GuardianAddressRefCountryId,    
     GuardianAddressPin,    
     GuardianPhone,    
     EmployerName,    
     EmployerAddress,    
     EmployerBusinessNature,    
     EmployerPhone,    
     AccountOpeningDate,    
     AccountClosingDate,    
     Nationality,    
     RefCustomRiskId,    
     RefMaritalStatusId,    
     RefPEPId,    
     ISDCode1,    
     STDCode1,    
     ISDCode2,    
     STDCode2,    
     ISDCode3,    
     STDCode3,    
     Aadhar,    
     PlaceOfIncorporation,    
     RefProfileRatingMasterId,    
     DpId,    
     SecondHolderEmail,    
     SecondHolderMobile,    
     ThirdHolderEmail,    
     ThirdHolderMobile,    
     GuardianDOB,    
     SecondHolderRefCRMCustomerId,    
     ThirdHolderRefCRMCustomerId,    
     RefClientAccountStatusId,    
     FirstName,    
     MiddleName,    
     LastName,    
     KYCEmployeeCode,    
     KYCEmployeeDesignation,    
     KYCEmployeeName,    
     KYCDeclarationDate,    
     KYCVerificationDate,       KYCVerificationBranch,    
     MotherTitle,    
     MotherFirstName,    
     MotherMiddleName,    
     MotherLastName,    
     SpouseTitle,    
     SpouseFirstName,    
     SpouseMiddleName,    
     SpouseLastName,    
     FatherTitle,    
     FatherFirstName,    
     FatherMiddleName,    
     FatherLastName,    
     MaidenTitle,    
     MaidenFirstName,    
     MaidenMiddleName,    
     MaidenLastName,    
     CIN,    
     KYCPlaceOfDeclaration,    
     NomineePAN,    
     NomineeAadhar,    
     NomineeEmail,    
     NomineeISD,    
     TaxResidencyOutsideIndiaRefEnumValueId,    
     AutomaticCreditRefEnumValueId,    
     AccountStatementRefEnumValueId,    
     StatementByEmailRefEnumValueId,    
     ShareEmailWithRTARefEnumValueId,    
     ReceiveRTADocumentRefEnumValueId,    
     DividendCreditInBankRefEnumValueId,    
     SMSAlertFacilityRefEnumValueId,    
     DematFeesRefEnumValueId,    
     PanFirstName,    
     PanMiddleName,    
     PanLastName,    
     FirstHolderTitle,    
     ResidentialStatusRefEnumValueId,    
     CountryOfBirthRefCountryId,    
     JurisdictionOfResidenceRefCountryId,    
     TaxIdentificationNumber,    
     PermanentProofRefAttachmentId,    
     CorrespondenceLocalAddressLine1,    
     CorrespondenceLocalAddressLine2,    
     CorrespondenceLocalAddressLine3,    
     CorrespondenceLocalPin,    
     CorrespondenceLocalDistrict,    
     CorrespondenceLocalCity,    
     CorrespondenceLocalState,    
     CorrespondenceLocalRefCountyId,    
     TaxResidencyAddressLine1,    
     TaxResidencyAddressLine2,    
     TaxResidencyAddressLine3,    
     TaxResidencyPin,    
     TaxResidencyDistrict,    
     TaxResidencyCity,    
     TaxResidencyState,    
     TaxResidencyRefCountryId,    
     ResidentialSTDCode,    
     ResidentialTelephoneNumber,    
     MobileISD,    
     FaxSTD,    
     FaxNumber,    
     POIRefIdentificationTypeId,    
     LastModifiedExternal,    
     AddedBy ,    
     AddedOn ,    
     EditedOn ,    
     LastEditedBy,    
     IncomeMultiplier,    
     NetworthMultiplier,    
    
     RefBOStatusId,    
     SuspendedDate,    
     IsNomineeMinor,    
     MinorNomineeGuardianLastName,    
     MinorNomineeGuardianAddress1,    
     MinorNomineeGuardianAddress2,    
     MinorNomineeGuardianAddress3,    
     MinorNomineeGuardianAddress4,    
     MinorNomineeGuardianMiddleName,    
     MinorNomineeGuardianFirstName,    
     MinorNomineeGuardianPin,    
     MinorNomineeDateOfBirth,    
     GuardianAddressLine4,    
     NomineeAddressLine4,    
     AccountStatus,    
     RefBoSubstatusId,    
     ApplicationFormNumber,    
     OnboardingRecordIdentifier    
    
                )    
                SELECT  stg.RefClientDatabaseEnumId,    
      stg.ClientId,    
      stg.FamilyCode,    
      stg.Name,    
      stg.Email,    
      stg.CAddressLine1,    
      stg.CAddressLine2,    
      stg.CAddressLine3,    
      stg.CAddressCity,    
      stg.CAddressState,    
      stg.CAddressCountry,    
      stg.CAddressPin,    
      stg.PAddressLine1,    
      stg.PAddressLine2,    
      stg.PAddressLine3,    
      stg.PAddressCity,    
      stg.PAddressState,    
      stg.PAddressCountry,    
      stg.PAddressPin,    
      stg.Phone1,    
      stg.Phone2,    
      stg.Phone3,    
      stg.Mobile,    
      stg.TaxStatusType,    
      stg.RefBseMfOccupationTypeId,    
      stg.Dob,    
      stg.Gender,    
      stg.FatherName,    
      stg.PAN,    
      stg.GuradianPAN,    
      stg.RefClientStatusId,    
      stg.RefIntermediaryId,    
      stg.RefConstitutionTypeId,    
      stg.SecondHolderRefSalutationId,    
      stg.SecondHolderFirstName,    
      stg.SecondHolderMiddleName,    
      stg.SecondHolderLastName,    
      stg.SecondHolderGender,    
      stg.SecondHolderDOB,    
      stg.SecondHolderPAN,    
      stg.SecondHolderFatherOrHusbandName,    
      stg.SecondHolderRefConstitutionTypeId,    
      stg.ThirdHolderSalutationId,    
      stg.ThirdHolderFirstName,    
      stg.ThirdHolderMiddleName,    
      stg.ThirdHolderLastName,    
      stg.ThirdHolderGender,    
      stg.ThirdHolderDOB,    
      stg.ThirdHolderPAN,    
      stg.ThirdHolderFatherOrHusbandName,    
      stg.ThirdHoldeRefConstitutionTypeId,    
      stg.NomineeFirstName,    
      stg.NomineeMiddleName,    
      stg.NomineeLastName,    
      stg.NomineeRelationshipWithFirstHolder,    
      stg.NomineeRelationshipWithSecondHolder,    
      stg.NomineeRelationshipWithThirdHolder,    
      stg.NomineeAddressLine1,    
      stg.NomineeAddressLine2,    
      stg.NomineeAddressLine3,    
      stg.NomineeAddressCity,    
      stg.NomineeAddressState,    
      stg.NomineeAddressRefCountryId,    
      stg.NomineeAddressPin,    
      stg.NomineePhone,    
      stg.NomineeDOB,    
      stg.GuardianFirstName,    
      stg.GuardianMiddleName,    
      stg.GuardianLastName,    
      stg.GuardianRelationship,    
      stg.GuardianAddressLine1,    
      stg.GuardianAddressLine2,    
      stg.GuardianAddressLine3,    
      stg.GuardianAddressCity,    
      stg.GuardianAddressState,    
      stg.GuardianAddressRefCountryId,    
      stg.GuardianAddressPin,    
      stg.GuardianPhone,    
      stg.EmployerName,    
      stg.EmployerAddress,    
      stg.EmployerBusinessNature,    
      stg.EmployerPhone,    
      stg.AccountOpeningDate,    
      stg.AccountClosingDate,    
      stg.Nationality,    
      stg.RefCustomRiskId,    
      stg.RefMaritalStatusId,    
      stg.RefPEPId,    
      stg.ISDCode1,    
      stg.STDCode1,    
      stg.ISDCode2,    
      stg.STDCode2,    
      stg.ISDCode3,    
      stg.STDCode3,    
      stg.Aadhar,    
      stg.PlaceOfIncorporation,    
      stg.RefProfileRatingMasterId,    
      stg.DpId,    
      stg.SecondHolderEmail,    
      stg.SecondHolderMobile,    
      stg.ThirdHolderEmail,    
      stg.ThirdHolderMobile,    
      stg.GuardianDOB,    
      stg.SecondHolderRefCRMCustomerId,    
      stg.ThirdHolderRefCRMCustomerId,    
      stg.RefClientAccountStatusId,    
      stg.FirstName,    
      stg.MiddleName,    
      stg.LastName,    
      stg.KYCEmployeeCode,    
      stg.KYCEmployeeDesignation,    
      stg.KYCEmployeeName,    
      stg.KYCDeclarationDate,    
      stg.KYCVerificationDate,    
      stg.KYCVerificationBranch,    
      stg.MotherTitle,    
      stg.MotherFirstName,    
      stg.MotherMiddleName,    
      stg.MotherLastName,    
      stg.SpouseTitle,    
      stg.SpouseFirstName,    
      stg.SpouseMiddleName,    
      stg.SpouseLastName,    
      stg.FatherTitle,    
      stg.FatherFirstName,    
      stg.FatherMiddleName,    
      stg.FatherLastName,    
      stg.MaidenTitle,    
      stg.MaidenFirstName,    
      stg.MaidenMiddleName,    
      stg.MaidenLastName,    
      stg.CIN,    
      stg.KYCPlaceOfDeclaration,    
      stg.NomineePAN,    
      stg.NomineeAadhar,    
      stg.NomineeEmail,    
      stg.NomineeISD,    
      stg.TaxResidencyOutsideIndiaRefEnumValueId,    
      stg.AutomaticCreditRefEnumValueId,    
      stg.AccountStatementRefEnumValueId,    
      stg.StatementByEmailRefEnumValueId,    
      stg.ShareEmailWithRTARefEnumValueId,    
      stg.ReceiveRTADocumentRefEnumValueId,    
      stg.DividendCreditInBankRefEnumValueId,    
      stg.SMSAlertFacilityRefEnumValueId,    
      stg.DematFeesRefEnumValueId,    
      stg.PanFirstName,    
      stg.PanMiddleName,    
      stg.PanLastName,    
      stg.FirstHolderTitle,    
      stg.ResidentialStatusRefEnumValueId,    
      stg.CountryOfBirthRefCountryId,    
      stg.JurisdictionOfResidenceRefCountryId,    
      stg.TaxIdentificationNumber,    
      stg.PermanentProofRefAttachmentId,    
      stg.CorrespondenceLocalAddressLine1,    
      stg.CorrespondenceLocalAddressLine2,    
      stg.CorrespondenceLocalAddressLine3,    
      stg.CorrespondenceLocalPin,    
      stg.CorrespondenceLocalDistrict,    
      stg.CorrespondenceLocalCity,    
      stg.CorrespondenceLocalState,    
      stg.CorrespondenceLocalRefCountyId,    
      stg.TaxResidencyAddressLine1,    
      stg.TaxResidencyAddressLine2,    
      stg.TaxResidencyAddressLine3,    
      stg.TaxResidencyPin,    
      stg.TaxResidencyDistrict,    
      stg.TaxResidencyCity,    
      stg.TaxResidencyState,    
      stg.TaxResidencyRefCountryId,    
      stg.ResidentialSTDCode,    
      stg.ResidentialTelephoneNumber,    
      stg.MobileISD,    
      stg.FaxSTD,    
      stg.FaxNumber,    
      stg.POIRefIdentificationTypeId,    
      stg.LastModifiedExternal,    
                        isnull(stg.AddedBy ,'System' ),    
             GETDATE() ,    
                        GETDATE() ,    
                        isnull(stg.AddedBy ,'System' ),    
                        CONVERT(DECIMAL(19, 6), @IncomeMultiplier),    
                        CONVERT(DECIMAL(19, 6), @NetworthMultiplier),    
    
      stg.RefBOStatusId,    
      stg.SuspendedDate,    
      stg.IsNomineeMinor,    
      stg.MinorNomineeGuardianLastName,    
      stg.MinorNomineeGuardianAddress1,    
      stg.MinorNomineeGuardianAddress2,    
      stg.MinorNomineeGuardianAddress3,    
      stg.MinorNomineeGuardianAddress4,    
      stg.MinorNomineeGuardianMiddleName,    
      stg.MinorNomineeGuardianFirstName,    
      stg.MinorNomineeGuardianPin,    
      stg.MinorNomineeDateOfBirth,    
      stg.GuardianAddressLine4,    
      stg.NomineeAddressLine4,    
      stg.AccountStatus,    
      stg.RefBoSubstatusId,    
      stg.ApplicationFormNumber,    
                        stg.OnboardingRecordIdentifier    
                            
      FROM    dbo.StagingClientRefresh stg    
		LEFT JOIN dbo.RefClient DupCheck ON DupCheck.RefClientDatabaseEnumId = stg.RefClientDatabaseEnumId    
                                            AND DupCheck.ClientId = stg.ClientId    
                                            AND ISNULL(DupCheck.DpId, 0) = ISNULL(stg.DpId,0)  
      WHERE   (stg.GUID=@GuidInternal or ISNULL(stg.GUID,'')='' )  AND DupCheck.RefClientId IS NULL  
                  
   IF(ISNULL(@GuidInternal,'')<>'')    
	BEGIN    
		EXEC dbo.LinkRefClientRefIncomeGroup_insertFromStaging @GuidInternal  
  
		EXEC dbo.RefClient_InsertJurisdictionOfResidence @GuidInternal    
    
		EXEC dbo.RefClientDematAccount_insertFromStaging @GuidInternal    
    
		EXEC dbo.LinkRefClientRefRiskCategory_insertFromStaging @GuidInternal    
    
		EXEC dbo.LinkRefClientRefBankMicr_InsertFromStaging @GuidInternal    
	END  
   END
              
   DELETE FROM dbo.StagingClientRefresh  WHERE   [GUID] = @GuidInternal
    
END        
GO
-----------------WEB-58874 -----RC Ends
-----------------WEB-58874 -----RC Starts
GO
ALTER PROCEDURE [dbo].[LinkRefClientRefIncomeGroup_insertFromStaging]  
(  
@guid varchar(5000)  
)  
AS   
BEGIN  
  
DECLARE @GuidInternal VARCHAR(5000)  
SET @GuidInternal=@guid  
			
			UPDATE stage  
			SET NetWorth=NetWorth/100  
			FROM dbo.StagingClientRefresh stage  
			WHERE [Guid] = @GuidInternal

SELECT
client.RefClientId,
stage.NetWorthDate AS FromDate,
stage.NetWorth AS NetWorth,
stage.IncomeGroup AS IncomeGroupCode,
CASE WHEN stage.IncomeGroup=1 THEN 'Upto 1 lac'
 WHEN stage.IncomeGroup=2 THEN '1 - 5 lacs'
 WHEN stage.IncomeGroup=3 THEN '5 - 10 lacs'
 WHEN stage.IncomeGroup=4 THEN '10 - 25 lacs'
WHEN stage.IncomeGroup=5 THEN '25 lacs - 1 Crore'
END AS [NAME],
stage.AddedOn,
stage.AddedBy
INTO #temp
FROM dbo.StagingClientRefresh stage  
INNER JOIN dbo.RefClient client ON client.ClientId =stage.ClientId AND client.RefClientDatabaseEnumId=stage.RefClientDatabaseEnumId
 AND ISNULL(stage.DpId,0)=ISNULL(stage.dpid,0)
WHERE stage.[GUID]=@GuidInternal AND stage.GUID IS NOT NULL AND ISNUMERIC(stage.ClientId)=1 



SELECT tem.*,inc.RefIncomeGroupId
INTO #StageLinkIncomeGroup
FROM #temp tem
INNER JOIN dbo.RefIncomeGroup inc ON inc.[Name]=tem.[Name]


DROP TABLE #temp

UPDATE link
SET link.RefIncomeGroupId=stage.RefIncomeGroupId,
link.NetWorth=stage.NetWorth,
link.FromDate=stage.FromDate,
link.EditedOn=stage.AddedOn,  
link.LastEditedBy=stage.AddedBy 
From dbo.LinkRefClientRefIncomeGroup link
INNER JOIN #StageLinkIncomeGroup stage ON stage.RefClientId=link.RefClientId AND stage.FromDate=link.FromDate

  
INSERT INTO dbo.LinkRefClientRefIncomeGroup
(	RefClientId,
	RefIncomeGroupId,
	Networth,
	FromDate,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn
)
 SELECT
 stage.RefClientId,
	stage.RefIncomeGroupId,
	stage.Networth,
	stage.FromDate,
	stage.AddedBy,
	stage.AddedOn,
	stage.AddedBy,
	stage.AddedOn
 FROM #StageLinkIncomeGroup stage
 LEFT JOIN dbo.LinkRefClientRefIncomeGroup link ON link.RefClientId=stage.RefClientId AND link.FromDate=stage.FromDate
 WHERE LinkRefClientRefIncomeGroupId IS NULL
  
END
GO
-----------------WEB-58874 -----RC Ends




