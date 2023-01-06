-----------WEB-63014 RC STARTS---
GO
EXEC dbo.SecPermission_Insert @Name = 'P111399_J1455_Run', @Description = 'AML', @Code ='P111399'
GO
EXEC dbo.SecPermission_Insert @Name = 'P111400_J1455_Modify', @Description = 'AML', @Code ='P111400'
GO
--------------RC ENDS----
-----------WEB-63014 RC STARTS---
GO
DECLARE @ProcessTypeId INT,
		@RunPermissionId INT,
		@ModifyPermissionId INT,
		@SuccesEmailTemplateId INT
SET @ProcessTypeId = dbo.GetEnumValueId('ProcessType','Simple')
SET @RunPermissionId = dbo.GetSecPermissionIdByName('P111399_J1455_Run')
SET @ModifyPermissionId = dbo.GetSecPermissionIdByName('P111400_J1455_Modify')
SELECT @SuccesEmailTemplateId = RefEmailTemplateId FROM dbo.RefEmailTemplate WHERE Code = 'E1948'

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
	RefEmailTemplateId
	)
VALUES 
(
	'J1455 Status Email for Alert generation of Composite Job',
	'TSS.SmallOfficeWeb.ManageData.Processes.AML.J1455StatusEmailForAlertGenerationOfCompositeJob',
	1,
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	1,
	'TSS.SmallOfficeWeb.ManageData',
	@ProcessTypeId,
	1,
	0,
	@RunPermissionId,
	@ModifyPermissionId,
	'J1455 Status Email for Alert generation of Composite Job',
	'J1455',
	@SuccesEmailTemplateId
)
	
GO
--------------RC ENDS----

-----------WEB-63014 RC STARTS---
GO
CREATE PROCEDURE  [dbo].[CoreProcessLog_J1455GetSuccessEmailStatus]
(
	@CoreProcessRunId  BIGINT
)
AS 
BEGIN
	DECLARE @InternalCoreProcessRunId INT,@TotalAlertCount INT,
	@Count INT,
	@TotalRunTime DECIMAL(28,2), @Started INT
	SET @InternalCoreProcessRunId= @CoreProcessRunId
	
	DECLARE @Success INT,
		@Failure INT
	-- Hardcoded as Enums in c#
	-- Reference TSS.SmallOffice.Common.Model.Enums.RunEventType
	SET @Success = 4
	SET @Failure = 5
	SET @Started = 2
		
	SELECT RefProcessId,
			CONVERT(DECIMAL(28,2),CONVERT(DECIMAL(28,2),DATEDIFF(ss, MIN(logs.AddedOn), MAX(logs.EditedOn)))/60)   [RunTime]
	INTO #timeInSecTemp
	FROM dbo.CoreProcessLog logs
	WHERE logs.CoreProcessRunId =@InternalCoreProcessRunId AND
	logs.RunEventTypeId IN (@Success,@Failure, @Started) AND logs.ParentProcessId IS NOT NULL
	GROUP BY RefProcessId
	

	SELECT ROW_NUMBER()OVER(order by logs.CoreProcessLogId) AS SrNo,ref.[Name] AS ScenarioName,
	CASE 
		WHEN logs.RunEventTypeId = @Success THEN 'Success'
		WHEN logs.RunEventTypeId = @Failure THEN 'Failed'
	END AS [Status],
	[AlertCount],
	CASE WHEN logs.TimeInSeconds IS NOT NULL THEN logs.TimeInSeconds ELSE  tis.[RunTime] END [RunTime]
	INTO #result
	FROM dbo.CoreProcessLog  logs
	INNER JOIN #timeInSecTemp tis On tis.RefProcessId = logs.RefProcessId
	INNER JOIN dbo.RefProcess ref ON ref.RefProcessId=logs.RefProcessId
	WHERE logs.CoreProcessRunId =@InternalCoreProcessRunId AND
	logs.RunEventTypeId IN (@Success,@Failure)
	
	SELECT @Count=COUNT(SrNo)
	FROM #result
	
	SELECT
	@TotalAlertCount=SUM(ALertCount),
	@TotalRunTime=SUM(RunTime)
	FROM #result
	WHERE @Count>0

	
	IF(@Count>0)
		BEGIN
		INSERT INTO #result
	(
		SrNo,
		ScenarioName,
		[Status],
		AlertCount,
		RunTime
	)VALUES
	(
	@Count+1,
	'<b>Total</b>',
	'',
	@TotalAlertCount,
	@TotalRunTime
	) 
		END
	SELECT *
	FROM #result
	ORDER BY SrNo

END
GO
--------------RC ENDS----
------exec dbo.CoreProcessLog_J1455GetSuccessEmailStatus 996917

-----------WEB-63014 RC STARTS---
GO
DECLARE @EmailTemplateTypeId INT
SELECT @EmailTemplateTypeId = RefEmailTemplateTypeId FROM dbo.RefEmailTemplateType WHERE Name = 'TSS-AML'

EXEC dbo.RefEmailTemplate_InsertIfNotExists 
@Code = 'E1948',
@RefEmailTemplateTypeId = @EmailTemplateTypeId,
@Name = 'Success email for J1455 Status of Composite Job',
@EmailSubject = 'Status of Alert generation Composite Job on <SystemDate>',
@EmailBody =  'Dear Sir/Madam,<br/>

The Job J1455 Status Email for Alert generation of Composite Job <JobCode> <IsAddedOn> <AddedOn> has run successfully as on Run Date <SystemDate><br/>

Below is the summary of Composite Job: <br/>

<SuccessStatusTable><br/>

Instance Name : <InstanceName> / Version : <Version><br />

Do not reply to this email as this is system generated.<br />Thanks, <br />TrackWizz System.',
@IsHtml = 1,
@AddedBy = 'System',
@LastEditedBy = 'System'
GO
--------------RC ENDS----

-----------WEB-63014 RC STARTS---
GO
CREATE PROCEDURE  [dbo].[CoreProcessRun_GetCompositeJobInfoFromJobCode]
(
	@RunDate DATETIME,
	@JobCode VARCHAR(20)
)
AS 
BEGIN
	DECLARE @InternalJobCode VARCHAR(20),@RunDateInternal DATETIME
	SET @InternalJobCode = @JobCode
	SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)
	DECLARE @Success INT,
		@Failure INT
	-- Hardcoded as Enums in c#
	-- Reference TSS.SmallOffice.Common.Model.Enums.RunEventType
	SET @Success = 4
	SET @Failure = 5
	

	SELECT RefProcessId
	INTO #temp
	FROM dbo.RefProcess
	WHERE Code=@JobCode

	SELECT process.CoreProcessRunId AS CoreProcessRunId,
	process.AddedOn AS AddedOn
	FROM dbo.CoreProcessRun process
	INNER JOIN #temp tem ON tem.RefProcessId=process.RefProcessId
	AND RUNDATE=@RunDateInternal AND RunEventTypeId IN (@Success,@Failure)


END
GO
--------------RC ENDS----
