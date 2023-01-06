--WEB-67320 RC START
GO
DECLARE @EmailTemplateTypeId INT
SET @EmailTemplateTypeId = (SELECT RefEmailTemplateTypeId FROM dbo.RefEmailTemplateType WHERE [Name] = 'TSS-AML');

EXEC dbo.RefEmailTemplate_InsertIfNotExists 
@Code = 'E2004',
@RefEmailTemplateTypeId = @EmailTemplateTypeId,
@Name = 'Notify the user when a case is moved to user''s workflow step ',
@EmailSubject = 'A case is been moved to <Step Name>',
@EmailBody ='Dear <User Name>, <br />  
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
TrackWizz System',
@IsHtml = 1,
@AddedBy = 'System',
@LastEditedBy = 'System'
GO
--WEB-67320 RC END
--WEB-67320 RC START
GO
EXEC dbo.RefWorkflowStepChangeHandler_Insert  @Name='H1274 TM Case assignment notification' ,
@ClassName='TSS.SmallOffice.DmsExtension.WorkflowStepChangeHandlers.AML.H1274TMCaseAssignmentNotificationHandler' ,
@Code ='H1274'
GO
--WEB-67320 RC END
--WEB-67320 RC START

GO
CREATE PROCEDURE [dbo].[GetCustomerSourceSystemAndProductAccountDetatilsByCaseId_AMLCaseManager]  
(   @CaseId BIGINT
)  
AS  
	BEGIN 
	DECLARE @InternalCaseId BIGINT, @clientEntityTypeId INT
	--SET @InternalCaseId = @CaseId
	SET @clientEntityTypeId = dbo.GetEntityTypeByCode('Client')
	SELECT @clientEntityTypeId

	  SELECT STUFF((          
		SELECT ', ' +           
		(IdenType.Name +' - '+ identification.IdNumber )            
		FROM  dbo.RefIdentificationType IdenType            
		INNER JOIN dbo.CoreCRMIdentification identification ON IdenType.RefIdentificationTypeId = identification.RefIdentificationTypeId AND IdenType.IsExternalSystem =1 AND identification.RefEntityTypeId =cust.RefEntityTypeId  AND cust.RefCRMCustomerId = identification.EntityId             
		FOR XML PATH('')),1,1,'') SourceSystemDetail, 
		STUFF(( SELECT ', '+ (db.DatabaseType +' - '+ cl.ClientId ) 
		FROM dbo.CoreCRMRelatedParty rp
		INNER JOIN  dbo.RefClient cl ON cl.RefClientId = rp.EntityId AND  rp.RefEntityTypeId = @clientEntityTypeId AND cust.RefCRMCustomerId=rp.RelatedPartyRefCRMCustomerId
		INNER JOIN dbo.RefClientDatabaseEnum db On db.RefClientDatabaseEnumId = cl.RefClientDatabaseEnumId  
		FOR XML PATH('')),1,1,'') ProductAccountDetail
	  FROM dbo.CoreAlertRegisterCustomerCase cases  
	  INNER JOIN dbo.LinkCoreAlertRegisterCustomerCaseRefCRMCustomer linkCaseCust ON linkCaseCust.CoreAlertRegisterCustomerCaseId = cases.CoreAlertRegisterCustomerCaseId  
	  INNER JOIN dbo.RefCRMCustomer cust ON linkCaseCust.RefCRMCustomerId=cust.RefCRMCustomerId
	  WHERE cases.CoreAlertRegisterCustomerCaseId=@InternalCaseId


	END
GO
--WEB-67320 RC END

