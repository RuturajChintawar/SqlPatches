--RC Start WEB-66295
GO
 PROCEDURE [dbo].[GetCustomerSourceSystemAndProductAccountDetatilsByCaseId]    
(   @CaseId BIGINT  
)    
AS    
 BEGIN   
	DECLARE @InternalCaseId BIGINT,@RefCRMCustomerId INT, @custEntityTypeId INT, @clientEntityTypeId INT  
	SET @InternalCaseId = @CaseId  
	SELECT @RefCRMCustomerId = RecordEntityId,@custEntityTypeId = RecordRefEntityTypeId FROM dbo.CoreScreeningCase WHERE CoreScreeningCaseId=36521 
	SET @clientEntityTypeId = dbo.GetEntityTypeByCode('Client')  
  
  SELECT identification.IdNumber,
	IdenType.RefIdentificationTypeId  
  INTO #CustSource  
  FROM dbo.CoreCRMIdentification identification              
  INNER JOIN dbo.RefIdentificationType IdenType ON identification.EntityId = @RefCRMCustomerId AND identification.RefEntityTypeId = @custEntityTypeId   
  AND IdenType.RefIdentificationTypeId = identification.RefIdentificationTypeId AND IdenType.IsExternalSystem = 1   
     
   
  
   SELECT db.DatabaseType +' - '+ cl.ClientId AS ProductAccountDetail  
   INTO #ProductAccountDetail  
   FROM dbo.CoreCRMRelatedParty rp   
   INNER JOIN dbo.RefClient cl ON rp.RelatedPartyRefCRMCustomerId = @RefCRMCustomerId AND rp.RefEntityTypeId = @clientEntityTypeId  
        AND cl.RefClientId = rp.EntityId   
   INNER JOIN dbo.RefClientDatabaseEnum db On db.RefClientDatabaseEnumId = cl.RefClientDatabaseEnumId  
  
   SELECT STUFF(( SELECT ', '+ (ex.[Name] +' - '+ s.IdNumber )        
  FROM #CustSource s   
  INNER JOIN dbo.RefExternalSystem ex ON ex.RefIdentificationTypeId = s.RefIdentificationTypeId  
  FOR XML PATH('')),1,1,'') SourceSystemDetail,  
  STUFF(( SELECT ', '+ (ProductAccountDetail)        
  FROM #ProductAccountDetail  
  FOR XML PATH('')),1,1,'') ProductAccountDetail  
 END  
 GO
---RC End WEB-66295
--exec GetCustomerSourceSystemAndProductAccountDetatilsByCaseId 36521
---RC Start WEB-66295
GO
UPDATE dbo.RefEmailTemplate 
SET EmailBody='Dear <User Name>, <br />  
Below case is been moved to <Step Name><br />  
Case Id : <Case Id><br />  
Total Alerts : <Alerts Count><br /> 
Source System Name and code: <SourceSystemDetail><br /> 
Product Account Type and Numbers: <ProductAccountDetail><br/>
Case URL : <Case Url><br />  
Received On : <Date and Time><br />  
Instance Name : <Instance Name><br />  
Do not reply to this email as this is system generated. <br />  
Thanks, <br />
TrackWizz System'
WHERE CODE='E1551'
GO
---RC End WEB-66295

--exec GetCustomerSourceSystemAndProductAccountDetatilsByCaseId 36488