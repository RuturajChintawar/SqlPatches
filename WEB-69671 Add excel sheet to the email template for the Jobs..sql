 --RC -WEB-69671-start
GO
ALTER PROCEDURE dbo.GetCustomerDetailsByRecordEntityId(
@RecordEntityIds Varchar(MAX)
)
AS    
 BEGIN   
	 DECLARE @InternalRecordEntityIds Varchar(MAX),@InternalRecordRefEntityTypeIds Varchar(MAX),@clientEntityTypeId INT  
	 SET @InternalRecordEntityIds = @RecordEntityIds
	 SET @clientEntityTypeId = dbo.GetEntityTypeByCode('Client')  

		SELECT CONVERT(BIGINT,items) AS RecordEntityId 
		INTO #RecordEntityIds  
		FROM [dbo].[Split](@InternalRecordEntityIds, ',')

	SELECT  
			ref.[Name] Company,
			cust.CustomerCode,
			STUFF(( SELECT ', '+ (ex.[Name] +' - '+ identification.IdNumber )        
				FROM dbo.CoreCRMIdentification identification              
				INNER JOIN dbo.RefIdentificationType IdenType on identification.EntityId= cust.RefCRMCustomerId AND identification.RefEntityTypeId = cust.RefEntityTypeId   
				AND IdenType.RefIdentificationTypeId = identification.RefIdentificationTypeId AND IdenType.IsExternalSystem =1
				INNER JOIN dbo.RefExternalSystem ex ON ex.RefIdentificationTypeId = IdenType.RefIdentificationTypeId  
				FOR XML PATH('')),1,1,'') SourceSystemDetail,
			STUFF(( SELECT ', '+ (db.DatabaseType +' - '+cl.ClientId)        
				FROM dbo.CoreCRMRelatedParty rp   
				INNER JOIN dbo.RefClient cl ON rp.RelatedPartyRefCRMCustomerId = cust.RefCRMCustomerId AND rp.RefEntityTypeId = @clientEntityTypeId  
				AND cl.RefClientId = rp.EntityId 
				INNER JOIN dbo.RefClientDatabaseEnum db On db.RefClientDatabaseEnumId = cl.RefClientDatabaseEnumId 
				FOR XML PATH('')),1,1,'') ProductAccountNumber 
	FROM #RecordEntityIds c
	INNER JOIN dbo.RefCRMCustomer cust ON cust.RefCRMCustomerId = c.RecordEntityId
	INNER JOIN dbo.RefEntityType ty ON ty.RefEntityTypeId = cust.RefEntityTypeId
	INNER JOIN dbo.RefParentCompany ref ON ref.RefParentCompanyId = ty.RefParentCompanyId

 END  
GO
 --RC -WEB-69671-END
--exec dbo.GetCustomerDetailsByRecordEntityId '3886104,3999636,3999963,4044107,4045026,4045120,4182926,4182927,4183091,4183094,4224058,4224432,4224433,4224434,4224435,4224436,4224439,4224448,4224486,4224487,4224488,4224489,4224490','240,240'
 --SELECT * FROM CoreScreeningCase cr where cr.CoreScreeningCaseId=36522
  --RC -WEB-69671-start
GO
ALTER PROCEDURE dbo.GetCompanieswithAtLeastOneMarkedCustomer(
@ParentCompanyIds Varchar(MAX),
@Code Varchar(40)
)
AS    
 BEGIN   
	 DECLARE @InternalParentCompanyIds Varchar(MAX),@ActionableEntityTypeId INT, @clientEntityTypeId INT,@EntityMarkedEnumValueId INT , @ScreeningType INT,@InternalCode Varchar(40)
	 SET @InternalCode = @Code
	 SET @InternalParentCompanyIds = @ParentCompanyIds
	 SET @clientEntityTypeId = dbo.GetEntityTypeByCode('Client')  
	 SET @EntityMarkedEnumValueId = dbo.GetEnumValueId('CustomerChangeLogActionableStatus','Pending')
	 SET @ScreeningType = dbo.GetEnumValueId('ChangeLogActionableActivity',@InternalCode)
	SET @ActionableEntityTypeId = dbo.GetEntityTypeByCode('ScreeningRuleClientCreation')  
	 
	 

		SELECT CONVERT(INT,items) AS RefParentCompanyId 
		INTO #ParentCompanyIds  
		FROM [dbo].[Split](@InternalParentCompanyIds, ',')

	SELECT  DISTINCT pc.RefParentCompanyId 
	FROM dbo.CoreCRMCustomerChangeLogActionable a
	INNER JOIN dbo.RefCRMCustomer crm ON a.RefCRMCustomerId = crm.RefCRMCustomerId
	INNER JOIN dbo.RefEntityType ty ON ty.RefEntityTypeId = crm.RefEntityTypeId AND a.CustomerChangeLogActionableStatusRefEnumValueId=@EntityMarkedEnumValueId AND a.ChangeLogActionableActivityRefEnumValueId = @ScreeningType
	INNER JOIN #ParentCompanyIds pc ON ty.RefParentCompanyId = pc.refparentcompanyID
	AND a.RefEntityTypeId = @ActionableEntityTypeId

 END  
GO
 --RC -WEB-69671-END
