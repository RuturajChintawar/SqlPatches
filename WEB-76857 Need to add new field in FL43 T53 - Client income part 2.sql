--File:StoredProcedures:dbo:StagingClientDetails_Validate
--WEB-76857--RC-START
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
   AND (temp.FromDate > TRY_CAST(staging.FromDate AS DATETIME) OR  temp.ToDate > TRY_CAST(staging.FromDate AS DATETIME))
    
 )t    
    
END  
GO
--WEB-76857--RC-END

--File:Tables:dbo:RefRejectionCode:DML
--WEB-76857--RC-START	
GO
	UPDATE link
		SET link.[Description] ='From date should be in this format only : DD-MMM-YYYY'
	FROM dbo.RefRejectionCode link
	WHERE Code = 'EC4109'

	EXEC dbo.RefRejectionCode_Insert @Code = 'EC4122', @Name = 'NetWorth', @FieldName = 'NetworthString', @Description = 'Networth should be a Numeric value. should not enter character or letters (eg. 35.54)', @CodeType = 'DataIntegration', @IsActive = 0

GO
--WEB-76857--RC-END

--File:Tables:dbo:LinkRefRejectionCodeRefRejectionValidator:DML
--WEB-76857--RC-START
GO
	DECLARE 
		@RejectionCodeId INT
	SELECT @RejectionCodeId =  RefRejectionCodeId FROM dbo.RefRejectionCode WHERE code ='EC4109' 
	UPDATE link
		SET link.[DateFormat] ='dd-MMM-yyyy'
	FROM dbo.LinkRefRejectionCodeRefRejectionValidator link
	WHERE link.RefRejectionCodeId = @RejectionCodeId 

	GO
	EXEC dbo.LinkRefRejectionCodeRefRejectionValidator_InsertIfNotExists @RejectionCode =  'EC4122', @RejectionValidatorCode = 'V42', @PropertyValueLength = 0, @ValidationComparisonTypeCode='GreaterThan'
	GO
GO
--WEB-76857--RC-END

--File:Tables:dbo:LinkRefRejectionCodeRefRejectionTag:DML
--WEB-76857--RC-START
GO
	EXEC dbo.LinkRejectionCodeRefRejectionTag_InsertIfNoExists @ErrorCode = 'EC4122', @RejectionTagCodes = 'ProductAccountCreateUpdate', @IsMapped = 1
GO
--WEB-76857--RC-END
GO
	DECLARE @RejctionCodeId INT
	SET @RejctionCodeId = (SELECT ref.RefRejectionCodeId FROM dbo.RefRejectionCode ref WHERE ref.[Code] = 'EC4122')

	DELETE  FROM dbo.LinkRefRejectionCodeRefRejectionTag   WHERE RefRejectionCodeId  = @RejctionCodeId

	DELETE  FROM dbo.LinkRefRejectionCodeRefRejectionValidator   WHERE RefRejectionCodeId  = @RejctionCodeId
	
	DELETE  FROM dbo.LinkCoreClientHistoryRefRejectionCode   WHERE RefRejectionCodeId  = @RejctionCodeId
	
	DELETE  FROM dbo.RefRejectionCode   WHERE RefRejectionCodeId  = @RejctionCodeId

GO
