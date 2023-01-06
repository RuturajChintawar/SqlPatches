--RC-WEB-70022 START
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Gold' ,@EnumValueCode= '1',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Credit Cards' ,@EnumValueCode= '2',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Loan against Property (LAP)' ,@EnumValueCode= '3',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Home loans' ,@EnumValueCode= '4',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Vehicle loans' ,@EnumValueCode= '5',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Personal Loans' ,@EnumValueCode= '6',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Micro Finance Loans' ,@EnumValueCode= '7',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Agricultural Loans' ,@EnumValueCode= '8',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Joint Lending Group Loans' ,@EnumValueCode= '9',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Self Help Group Loans' ,@EnumValueCode= '10',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Others' ,@EnumValueCode= '11',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Ind'
GO
--non
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Cash credit/Overdraft' ,@EnumValueCode= '12',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Demand loan' ,@EnumValueCode= '13',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Term loans' ,@EnumValueCode= '14',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Inland bills' ,@EnumValueCode= '15',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Packing credit' ,@EnumValueCode= '16',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Export bills' ,@EnumValueCode= '17',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Bills discounted' ,@EnumValueCode= '18',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Letter of credit' ,@EnumValueCode= '19',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Guarantees' ,@EnumValueCode= '20',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Co-acceptance of bills' ,@EnumValueCode= '21',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Foreign exchange contracts' ,@EnumValueCode= '22',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Interest rate derivatives' ,@EnumValueCode= '23',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Financial Leasing' ,@EnumValueCode= '24',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Other Derivatives' ,@EnumValueCode= '25',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Factoring with Recourse' ,@EnumValueCode= '26',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Debentures/ Bonds' ,@EnumValueCode= '27',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Commercial papers' ,@EnumValueCode= '28',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Public Deposits' ,@EnumValueCode= '29',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName = 'ClientDebtSubType',@EnumValueName = 'Real Estate Allottee (u/s 5(8)(f))' ,@EnumValueCode= '30',@ParentEnumTypeName='CustomerTypeCategory' ,@ParentEnumValueCode='Non Ind'
GO
--RC-WEB-70022 END
--RC-WEB-70022 START
GO
EXEC dbo.RefRejectionCode_Insert @Code='EC4050', @Name='DebtSubtype'   ,@FieldName='DebtSubtype' , @Description='Invalid Customer Type or DebtSubtype value.' , @CodeType='DataIntegration' , @IsActive=1
GO
--RC-WEB-70022 END
--RC-WEB-70022 START
GO
EXEC dbo.LinkRejectionCodeRefRejectionTag_InsertIfNoExists @ErrorCode = 'EC4050', @RejectionTagCodes = 'IULoan', @IsMapped = 1 
GO
--RC-WEB-70022 END
--RC-WEB-70022 START
GO    

EXEC dbo.LinkRefRejectionCodeRefRejectionValidator_InsertIfNotExists
    @RejectionCode = 'EC4050' ,
    @RejectionValidatorCode = 'V82'
GO    
--RC-WEB-70022 END
--RC-WEB-70022 START
GO
 ALTER PROCEDURE dbo.StagingClientDetails_Validate  
(  
 @Guid VARCHAR(50),  
 @ErrorTags VARCHAR(MAX)  
)  
AS  
BEGIN  
   DECLARE @InternalGuid VARCHAR(50), @InternalErrorTags VARCHAR(MAX), @RefEntityTypeId INT, @ParentComapnyId INT ,@DebtsubTypeEnumTypeId INT 
 SET @InternalGuid=@Guid  
 SET @InternalErrorTags=@ErrorTags 
 SELECT  @DebtsubTypeEnumTypeId = ref.RefEnumTypeId FROM dbo.RefEnumType ref WHERE ref.[Name] = 'ClientDebtSubType'
  
 DECLARE @YesEumValueId INT,@NoEumValueId INT  
    SET @YesEumValueId= dbo.GetEnumValueId('YesNoOption','Yes')  
  
 SELECT @ParentComapnyId = RefParentCompanyId FROM dbo.RefParentCompany   
 WHERE UniqueId=(Select top(1) ParentCompany from dbo.StagingClientDetail WHERE GUID = @InternalGuid);  
  
    SET @RefEntityTypeId = dbo.GetEntityTypeByParentCompanyIdAndParentEntityTypeCode(@ParentComapnyId,'BaseCustomer');  
  
 DECLARE @BankCodeandBankNameCombinationEC1705 INT, @FirstHolderSourceSystemNameandFirstHolderSourceSystemCustomerCodeCombinationEC2281 INT, @ModuleApplicableIsMandatoryEC1730 INT,  
 @DefaultAmountMandatoryEC2320 INT, @DefaultDateIsMandatoryEC2280 INT,@UniqueKeyValidationEC2996 INT, @DPIdValidationEC2848 INT ,@DebtSubTypeValidationEC4050 INT 
  
 SELECT @BankCodeandBankNameCombinationEC1705 = dbo.GetActiveRefRejectionCodeIdByTags('EC1705',@InternalErrorTags)  
 SELECT @FirstHolderSourceSystemNameandFirstHolderSourceSystemCustomerCodeCombinationEC2281 = dbo.GetActiveRefRejectionCodeIdByTags('EC2281',@InternalErrorTags)  
 SELECT @ModuleApplicableIsMandatoryEC1730  = dbo.GetActiveRefRejectionCodeIdByTags('EC1730',@InternalErrorTags)  
 SELECT @DefaultAmountMandatoryEC2320  = dbo.GetActiveRefRejectionCodeIdByTags('EC2320',@InternalErrorTags)  
 SELECT @DefaultDateIsMandatoryEC2280 = dbo.GetActiveRefRejectionCodeIdByTags('EC2280',@InternalErrorTags)  
 SELECT @UniqueKeyValidationEC2996 = dbo.GetActiveRefRejectionCodeIdByTags('EC2996',@InternalErrorTags)  
 SELECT @DPIdValidationEC2848 = dbo.GetActiveRefRejectionCodeIdByTags('EC2848',@InternalErrorTags)  
 SELECT @DebtSubTypeValidationEC4050 = dbo.GetActiveRefRejectionCodeIdByTags('EC4050',@InternalErrorTags)  
   
 SELECT  history.ProductAccountType,history.ProductAccountNumber  
  INTO #RepeatedClientIntegrationId      
  FROM dbo.StagingClientDetail history  
  WHERE history.GUID = @InternalGuid  
  GROUP BY history.ProductAccountType,history.ProductAccountNumber  
  HAVING COUNT(1)>1  
  
  SELECT staging.StagingClientDetailId,
  ty.CustomerTypeCategoryRefEnumValueId
  INTO #DebtSubTypeTemp
  FROM dbo.StagingClientRelationDetail staging  
  INNER JOIN dbo.RefExternalSystem externalSystem ON externalSystem.[Name] = staging.FirstHolderSourceSystemName  AND @DebtSubTypeValidationEC4050 IS NOT NULL AND staging.[GUID] = @InternalGuid
  INNER JOIN dbo.CoreCRMIdentification custIdent ON custIdent.RefEntityTypeId = @RefEntityTypeId AND custIdent.RefIdentificationTypeId = externalSystem.RefIdentificationTypeId AND custIdent.IdNumber = staging.FirstHolderSourceSystemCustomerCode  
  INNER JOIN dbo.RefCRMCustomer ref ON ref.RefCRMCustomerId = custIdent.EntityId
  INNER JOIN dbo.RefCustomerType ty ON ty.RefCustomerTypeId = ref.RefCustomerTypeId 
    

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
  INNER JOIN dbo.RefEnumValue ref ON ref.[Name]=staging.DebtSubtype AND ref.RefEnumTypeId = @DebtsubTypeEnumTypeId
  INNER JOIN #DebtSubTypeTemp te ON te.StagingClientDetailId = staging.StagingClientDetailId
  WHERE  @DebtSubTypeValidationEC4050 IS NOT NULL
  AND staging.[GUID] = @InternalGuid AND ref.ParentRefEnumValueId IS NOT NULL
  AND ref.ParentRefEnumValueId <> te.CustomerTypeCategoryRefEnumValueId
  
 )t  
  
END 
GO 
--RC-WEB-70022 END


