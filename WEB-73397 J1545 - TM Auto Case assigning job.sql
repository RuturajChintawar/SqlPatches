--START RC WEB-73397
GO
EXEC dbo.SecPermission_Insert @Name = 'P111587_J1545_Run', @Description = 'AML', @Code ='P111587'
GO
EXEC dbo.SecPermission_Insert @Name = 'P111588_J1545_Modify', @Description = 'AML', @Code ='P111588'
GO
--END RC WEB-73397
--START RC WEB-73397
GO
DECLARE @EmailTemplateTypeId INT
SELECT @EmailTemplateTypeId = RefEmailTemplateTypeId FROM dbo.RefEmailTemplateType WHERE Name = 'TSS-AML'

EXEC dbo.RefEmailTemplate_InsertIfNotExists 
@Code = 'E2103',
@RefEmailTemplateTypeId = @EmailTemplateTypeId,
@Name = 'Success Email for J1545',
@EmailSubject = 'Success email for J1545 - TM Auto Case assigning job',
@EmailBody =  'Dear User,<br/>

Job J1545 - TM Auto Case assigning job is processed successfully<br/>

Please find the below stats<br/>

<SuccessStatusTable><br/>
',
@IsHtml = 1,
@AddedBy = 'System',
@LastEditedBy = 'System'

EXEC dbo.RefEmailTemplate_InsertIfNotExists 
@Code = 'E2104',
@RefEmailTemplateTypeId = @EmailTemplateTypeId,
@Name = 'Failure Email for J1545',
@EmailSubject = 'Failure email for J1545 - TM Auto Case assigning job',
@EmailBody =  'Dear User,<br/>

Job J1545 - TM Auto Case assigning job is failed to process successfully<br/>
Failure Reason:- <FailureReason><br/>',
@IsHtml = 1,
@AddedBy = 'System',
@LastEditedBy = 'System'
GO

--END RC WEB-73397

--START RC WEB-73397
GO
DECLARE @ProcessTypeId INT,
		@RunPermissionId INT,
		@ModifyPermissionId INT,
		@SuccesEmailTemplateId INT,
		@FailureEmailTemplateId INT

SET @ProcessTypeId = dbo.GetEnumValueId('ProcessType','Simple')
SET @RunPermissionId = dbo.GetSecPermissionIdByName('P111587_J1545_Run')
SET @ModifyPermissionId = dbo.GetSecPermissionIdByName('P111588_J1545_Modify')
SELECT @SuccesEmailTemplateId = RefEmailTemplateId FROM dbo.RefEmailTemplate WHERE Code = 'E2103'
SELECT @FailureEmailTemplateId = RefEmailTemplateId FROM dbo.RefEmailTemplate WHERE Code = 'E2104'

INSERT INTO dbo.RefProcess 
(
	[Name],
	ClassName,
	IsActive,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn,
	IsScheduleEditable,
	AssemblyName,
	ProcessTypeRefEnumValueId,
	EnableRunDateSelection,
	IsCompanyWise,
	RunSecPermissionId,
	ModifySecPermissionId,
	DisplayName,
	Code,
	RefEmailTemplateId,
	FailureRefEmailTemplateId
)
VALUES 
(
	'J1545 - TM Auto Case assigning job',
	'TSS.SmallOfficeWeb.ManageData.Processes.AML.J1545TMAutoCaseAssigningJob',
	1,
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	1,
	'TSS.SmallOfficeWeb.ManageData',
	@ProcessTypeId,
	0,
	0,
	@RunPermissionId,
	@ModifyPermissionId,
	'J1545 - TM Auto Case assigning job',
	'J1545',
	@SuccesEmailTemplateId,
	@FailureEmailTemplateId
)
GO
--END RC WEB-73397
--START RC WEB-73397
GO
EXEC dbo.RefProcessSetting_Insert @ProcessName = 'J1545 - TM Auto Case assigning job',
		@ProcessSettingName = 'Step Code', 
		@ProcessSettingCode = 'Step_Code',
		@ProcessSettingValue = NULL,
		@TemplateCode = 'TextBox' 
GO
GO
EXEC dbo.RefProcessSetting_Insert @ProcessName = 'J1545 - TM Auto Case assigning job',
		@ProcessSettingName = 'Mapping Expression', 
		@ProcessSettingCode = 'Expression',
		@ProcessSettingValue = NULL,
		@TemplateCode = 'TextBox' 
GO
--END RC WEB-73397
--START RC WEB-73397
GO
CREATE PROCEDURE [dbo].[CoreWorkflowProgress_GetAssignedCaseStats]  
(  
 @Expression VARCHAR(MAX),  
 @StepCode VARCHAR(50),  
 @AssignorId INT  
)   
 AS  
 BEGIN  
  DECLARE  
  @InternalExpression VARCHAR(MAX),@InternalStepCode VARCHAR(50),@InternalAssignorId INT,@AlertRegisterCaseEntityTypeId INT,  
  @InternalUpdateUser VARCHAR(100),@currentDate DATETIME  
  
  SET @InternalExpression = @Expression  
  SET @InternalStepCode = @StepCode  
  SET @InternalAssignorId = @AssignorId  
  SET @AlertRegisterCaseEntityTypeId = dbo.GetEntityTypeByCode('AlertRegisterCase')    
  SELECT @InternalUpdateUser =  UserName FROM dbo.RefEmployee  WHERE RefEmployeeId = @AssignorId  
  SET @currentDate = GETDATE()    
    
  SELECT    
  ex.s AS Exps  
  INTO #expression  
  FROM dbo.ParseString(@InternalExpression,'|') ex;  
  
  WITH C AS(  
  SELECT Exps  
     ,s AS SU  
     ,ROW_NUMBER() OVER(PARTITION BY Exps ORDER BY (SELECT NULL)) as rn  
  FROM #expression ex  
   CROSS APPLY dbo.ParseString(Exps, ':') AS BK  
  )  
  SELECT [1] AS Scenario  
     ,[2] AS UserName  
  INTO #splitScenarioAndUser  
  FROM C  
  PIVOT(  
   MAX(SU)  
   FOR RN IN([1],[2])    
  ) as PVT;  
  
  SELECT UserName  
    ,BK.s AS Code  
  INTO #FinalUserScenario  
  FROM #splitScenarioAndUser temp  
  CROSS APPLY dbo.ParseString(temp.Scenario, ',') AS BK  
  
    
  SELECT DISTINCT  
   t.CoreAlertRegisterCaseId,  
   t.Code,  
   t.AddedOn  
  INTO #caseSideData  
  FROM (  
   SELECT   
   cases.CoreAlertRegisterCaseId  
   ,report.Code  
   ,ROW_NUMBER() OVER(PARTITION BY cases.CoreAlertRegisterCaseId,report.code ORDER BY alert.AddedOn) AS rn,  
   alert.AddedOn  
   FROM dbo.CoreAlertRegisterCase cases  
   INNER JOIN dbo.CoreAmlScenarioAlert alert ON alert.CoreAlertRegisterCaseId = cases.CoreAlertRegisterCaseId  
   INNER JOIN dbo.RefAmlReport report ON report.RefAmlReportId=alert.RefAmlReportId  
   INNER JOIN #FinalUserScenario us ON us.Code = report.Code ) t  
  WHERE t.rn = 1  
  
  SELECT  
   ca.CoreAlertRegisterCaseId,  
   ca.UserName  
  INTO #FinalCaseWithScenario  
  FROM  
   (SELECT   
    t.CoreAlertRegisterCaseId,  
    ROW_NUMBER() OVER (PARTITION BY t.CoreAlertRegisterCaseId ORDER BY t.ma DESC) rn,  
    t.UserName  
   FROM   
    (SELECT   
     t.CoreAlertRegisterCaseId,  
     COUNT(t.CoreAlertRegisterCaseId) ma,  
     us.UserName  
    FROM #caseSideData t  
    INNER JOIN #FinalUserScenario us ON us.Code = t.Code  
    GROUP BY us.UserName,  
    t.CoreAlertRegisterCaseId ) t) ca  
  WHERE ca.rn = 1  
  
  
  SELECT DISTINCT  
   wpLatest.CoreWorkflowProgressId  
   ,fcws.CoreAlertRegisterCaseId  
   ,fcws.UserName  
  INTO #FinalWorfFlowData  
  FROM #FinalCaseWithScenario fcws  
  INNER JOIN dbo.CoreAlertRegisterCase cases ON cases.CoreAlertRegisterCaseId = fcws.CoreAlertRegisterCaseId  
  INNER JOIN dbo.CoreWorkflowProgressLatest wpLatest ON wpLatest.EntityId = cases.CoreAlertRegisterCaseId AND wpLatest.RefEntityTypeId = @AlertRegisterCaseEntityTypeId  
  INNER JOIN dbo.RefWorkflowStep workflowStep ON workflowStep.RefWorkflowStepId = wpLatest.RefWorkflowStepId   
  WHERE wpLatest.AssignedRefEmployeeId IS NULL AND   workflowStep.Code=@InternalStepCode  
    
  UPDATE wf  
   SET wf.AssignedRefEmployeeId=emp.RefEmployeeId  
   ,wf.LastEditedBy=@InternalUpdateUser  
   ,wf.EditedOn=@currentDate  
   ,wf.AssignorRefEmployeeId = @InternalAssignorId  
  FROM dbo.CoreWorkflowProgress wf  
  INNER JOIN #FinalWorfFlowData fs ON fs.CoreWorkflowProgressId=wf.CoreWorkflowProgressId  
  INNER JOIN dbo.RefEmployee emp ON emp.UserName=fs.UserName  
    
  INSERT INTO dbo.CoreAlertRegisterCaseAssignmentHistory(  
	   CoreAlertRegisterCaseId,  
	   AssignorRefEmployeeId,  
	   AssigneeRefEmployeeId,  
	   AddedBy,  
	   AddedOn,  
	   LastEditedBy,  
	   EditedOn  
  )SELECT   
	   fl.CoreAlertRegisterCaseId,  
	   @InternalAssignorId,  
	   emp.RefEmployeeId,  
	   @InternalUpdateUser,  
	   @currentDate,  
	   @InternalUpdateUser,  
	   @currentDate  
  FROM #FinalWorfFlowData fl  
  INNER JOIN dbo.RefEmployee emp ON emp.UserName=fl.UserName  
  
  SELECT   
   fs.UserName AS [User]  
   ,COUNT(fs.CoreWorkflowProgressId) AS CaseCount  
  INTO #FinalCount  
  FROM   
   #FinalWorfFlowData fs  
   GROUP BY fs.UserName  
  
  IF EXISTS (SELECT  1 from #FinalCount)  
  BEGIN  
   SELECT   
    [User]   
    ,CaseCount  
   FROM #FinalCount  
  END  
  ELSE BEGIN  
    RAISERROR ('No Record Found.', 11, 1) WITH SETERROR;              
    RETURN 50010;    
  END  
  
 END  
GO
--END RC WEB-73397

