------WEB-65188 RC START
GO
DECLARE @EmailTemplateTypeId INT
SET @EmailTemplateTypeId = (SELECT RefEmailTemplateTypeId FROM dbo.RefEmailTemplateType WHERE [Name] = 'TSS-Screening');

EXEC dbo.RefEmailTemplate_InsertIfNotExists 
@Code = 'E1955',
@RefEmailTemplateTypeId = @EmailTemplateTypeId,
@Name = 'To send screening status email to RMs of the customers through H1269',
@EmailSubject = 'Screening has been completed for Customer <CustomerName>.',
@EmailBody ='Dear Team, <br />
This is to inform you that Screening process has been completed for Customer <CustomerName>.
Case Id: <CaseId>
Final decision: <WorkflowStep>
Comment: <CommentStep><br />
Instance Name: <InstanceName> / Version No:<Version> 
Do not reply to this email as this is system generated.<br/>
Thanks.
TrackWizz System',
@IsHtml = 1,
@AddedBy = 'System',
@LastEditedBy = 'System'
GO
------WEB-65188 RC END
------WEB-65188 RC START
GO
EXEC dbo.RefWorkflowStepChangeHandler_Insert  @Name='H1269 - To send screening status email to RMs of the customer' ,
@ClassName='TSS.SmallOffice.DmsExtension.WorkflowStepChangeHandlers.AML.H1269ToSendScreeningStatusEmailToRMsOfTheCustomer' ,
@Code ='H1269 '
GO
------WEB-65188 RC END
------WEB-65188 RC START
GO
CREATE PROCEDURE [dbo].[CoreScreeningRMDetailHistory_GetCustomerAndRMDetailsByCaseId]  
(   @CaseId BIGINT,
	@EmailTemplateId INT
)  
AS  
BEGIN  
	DECLARE @InternalCaseId BIGINT,@InternalEmailTemplateId INT ,@RefAmlEntityTypeId  INT,@RefEnumTypeId INT
	SET @InternalCaseId = @CaseId 
	SET @InternalEmailTemplateId=@EmailTemplateId
	SET @RefAmlEntityTypeId = (SELECT RefAmlEntityTypeId FROM dbo.RefAmlEntityType WHERE [NAME]='Relationship_Manager')
	
	SELECT 
		RTRIM(LTRIM(ISNULL(cust.FirstName, '') + ' ' + ISNULL(cust.MiddleName, '') + ' ' + ISNULL(cust.LastName, ''))) [CustomerName]
	FROM dbo.CoreScreeningCase scase  
	INNER JOIN dbo.RefCRMCustomer cust ON cust.RefCRMCustomerId = scase.RecordEntityId
	WHERE scase.CoreScreeningCaseId = @InternalCaseId

	IF EXISTS(SELECT LinkRefEmailTemplateRefAmlEntityTypeId FROM dbo.LinkRefEmailTemplateRefAmlEntityType WHERE RefEmailTemplateId=@InternalEmailTemplateId AND RefAmlEntityTypeId=@RefAmlEntityTypeId)
		BEGIN
			SELECT
			employeeRm.Email,
			employeeRm.[Name]
			FROM dbo.CoreScreeningCase cas  
			INNER JOIN dbo.CoreScreeningRequestHistory hist ON cas.CoreScreeningCaseId=@InternalCaseId AND cas.CoreScreeningCaseId=hist.CoreScreeningCaseId 
			INNER JOIN dbo.CoreScreeningRMDetailHistory custRm ON custRm.CoreScreeningRequestHistoryId=hist.CoreScreeningRequestHistoryId 
			INNER JOIN dbo.RefEmployee employeeRm on employeeRm.RefEmployeeId = custRm.UserCodeRefEmployeeId
			INNER JOIN dbo.RefEnumValue ref ON ref.RefEnumValueId=custRm.CustomerRMTypeRefEnumValueId

		END
	END
GO
------WEB-65188 RC END
