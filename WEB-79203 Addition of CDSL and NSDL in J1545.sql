--File:StoredProcedures:dbo:CoreWorkflowProgress_GetAssignedCaseStats
--START RC WEB-79203
GO
ALTER PROCEDURE [dbo].[CoreWorkflowProgress_GetAssignedCaseStats]  
(  
	 @Expression VARCHAR(MAX),  
	 @StepCode VARCHAR(50),  
	 @AssignorId INT  
)   
 AS  
 BEGIN  
  DECLARE  
  @InternalExpression VARCHAR(MAX), @InternalStepCode VARCHAR(50), @InternalAssignorId INT, @AlertRegisterCaseEntityTypeId INT,  
  @InternalUpdateUser VARCHAR(100), @currentDate DATETIME  
  
  SET @InternalExpression = @Expression  
  SET @InternalStepCode = @StepCode  
  SET @InternalAssignorId = @AssignorId  
  SET @AlertRegisterCaseEntityTypeId = dbo.GetEntityTypeByCode('AlertRegisterCase')    
  SET @InternalUpdateUser =  (SELECT UserName FROM dbo.RefEmployee  WHERE RefEmployeeId = @AssignorId)
  SET @currentDate = GETDATE()    
    
  SELECT    
	ex.s AS Exps  
  INTO #expression  
  FROM dbo.ParseString(@InternalExpression,'|') ex;  
  
  WITH C AS(  
	  SELECT Exps  
		 ,s AS SU  
		 ,ROW_NUMBER() OVER(PARTITION BY Exps ORDER BY (SELECT NULL)) AS RN  
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
  
  SELECT 
	ISNULL(report.RefAmlReportId, 0) AS RefAmlReportId
	,ISNULL(dptype.RefDpSuspiciousTransactionTypeId, 0) AS RefDpSuspiciousTransactionTypeId
	,emp.RefEmployeeId
  INTO #FinalUserScenario  
  FROM #splitScenarioAndUser temp  
  CROSS APPLY dbo.ParseString(temp.Scenario, ',') AS BK
  INNER JOIN dbo.RefEmployee emp ON emp.UserName = temp.UserName
  LEFT JOIN dbo.RefAmlReport report ON report.Code = BK.s
  LEFT JOIN dbo.RefDpSuspiciousTransactionType dptype ON dptype.[Name] = BK.s
  
  SELECT   
   t.CoreAlertRegisterCaseId
   ,t.RefEmployeeId
   ,t.AddedOn
  INTO #caseSideData  
  FROM (  
	   SELECT   
		   alert.CoreAlertRegisterCaseId  
		   ,us.RefEmployeeId
		   ,alert.AddedOn
		   ,ROW_NUMBER() OVER(PARTITION BY alert.CoreAlertRegisterCaseId, us.RefAmlReportId ORDER BY alert.AddedOn) AS rn
	   FROM #FinalUserScenario us 
	   INNER JOIN dbo.CoreAmlScenarioAlert alert ON alert.RefAmlReportId = us.RefAmlReportId 

	   UNION 
	   
	   SELECT   
		   dpalert.CoreAlertRegisterCaseId  
		   ,us.RefEmployeeId
		   ,dpalert.AddedOn
		   ,ROW_NUMBER() OVER(PARTITION BY dpalert.CoreAlertRegisterCaseId,us.RefDpSuspiciousTransactionTypeId ORDER BY dpalert.AddedOn) AS rn
	   FROM #FinalUserScenario us
	   INNER JOIN dbo.CoreDpSuspiciousTransactionBatch batch ON batch.RefDpSuspiciousTransactionTypeId = us.RefDpSuspiciousTransactionTypeId
	   INNER JOIN dbo.CoreDpSuspiciousTransaction dpalert ON batch.CoreDpSuspiciousTransactionBatchId =  dpalert.CoreDpSuspiciousTransactionBatchId 
	   
	   ) t  
  WHERE t.rn = 1  
  
  SELECT  
   ca.CoreAlertRegisterCaseId,  
   ca.RefEmployeeId    
  INTO #FinalCaseWithScenario  
  FROM  
   (
	   SELECT   
		t.CoreAlertRegisterCaseId,  
		ROW_NUMBER() OVER (PARTITION BY t.CoreAlertRegisterCaseId ORDER BY t.ma DESC, t.minAddedOn ASC) rn,  
		t.RefEmployeeId    
	   FROM   
		(
			SELECT   
			 t.CoreAlertRegisterCaseId,  
			 COUNT(t.CoreAlertRegisterCaseId) ma,
			 MIN(t.AddedOn) minAddedOn,
			 t.RefEmployeeId  
			FROM #caseSideData t  
			GROUP BY t.CoreAlertRegisterCaseId, t.RefEmployeeId
			 ) t) ca  
  WHERE ca.rn = 1  
  
  
  SELECT DISTINCT  
   wpLatest.CoreWorkflowProgressId  
   ,fcws.CoreAlertRegisterCaseId  
   ,fcws.RefEmployeeId
  INTO #FinalWorfFlowData  
  FROM #FinalCaseWithScenario fcws  
  INNER JOIN dbo.CoreAlertRegisterCase cases ON cases.CoreAlertRegisterCaseId = fcws.CoreAlertRegisterCaseId  
  INNER JOIN dbo.CoreWorkflowProgressLatest wpLatest ON wpLatest.EntityId = cases.CoreAlertRegisterCaseId AND wpLatest.RefEntityTypeId = @AlertRegisterCaseEntityTypeId  
  INNER JOIN dbo.RefWorkflowStep workflowStep ON workflowStep.RefWorkflowStepId = wpLatest.RefWorkflowStepId   
  WHERE wpLatest.AssignedRefEmployeeId IS NULL AND   workflowStep.Code = @InternalStepCode  
    
  UPDATE wf  
   SET wf.AssignedRefEmployeeId = fs.RefEmployeeId  
   ,wf.LastEditedBy = @InternalUpdateUser  
   ,wf.EditedOn = @currentDate  
   ,wf.AssignorRefEmployeeId = @InternalAssignorId  
  FROM dbo.CoreWorkflowProgress wf  
  INNER JOIN #FinalWorfFlowData fs ON fs.CoreWorkflowProgressId = wf.CoreWorkflowProgressId  
   
    
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
	   fl.RefEmployeeId,  
	   @InternalUpdateUser,  
	   @currentDate,  
	   @InternalUpdateUser,  
	   @currentDate  
  FROM #FinalWorfFlowData fl   
  
  SELECT   
   emp.UserName AS [User]  
   ,COUNT(fs.CoreWorkflowProgressId) AS CaseCount  
  INTO #FinalCount  
  FROM   #FinalWorfFlowData fs 
  INNER JOIN  dbo.RefEmployee emp ON emp.RefEmployeeId = fs.RefEmployeeId
  GROUP BY fs.RefEmployeeId ,emp.UserName
  
  IF EXISTS (SELECT TOP 1 1 from #FinalCount)  
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
--END RC WEB-79203
--File:Tables:dbo:RefProcessSetting:DML
--START RC WEB-79203
GO
	DECLARE @RefProcessId INT
	SELECT @RefProcessId = pr.RefProcessId FROM dbo.RefProcess pr WHERE pr.Code = 'J1545'
	UPDATE sett
	SET sett.[Description] = 'Mapping Expression : ScenarioCode:UserName|'
	FROM dbo.RefProcessSetting sett
	WHERE sett.RefProcessId = @RefProcessId  AND sett.Code = 'Expression'
GO
--END RC WEB-79203
