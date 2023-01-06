--WEB-74148 RC START
GO
 ALTER PROCEDURE  [dbo].[CoreProcessLog_J1455GetSuccessEmailStatus]    
(    
 @CoreProcessRunId  BIGINT    
)    
AS     
BEGIN    
 DECLARE @InternalCoreProcessRunId INT,@TotalAlertCount INT,    
 @Count INT,  @J1455RefProcessId INT,  
 @TotalRunTime DECIMAL(28,2), @Started INT ,@ParentCompositeJobCoreProcessRunId INT, @ParentCompositeJobProcessId INT
 SET @InternalCoreProcessRunId= @CoreProcessRunId    
     
 DECLARE @Success INT,    
  @Failure INT    
 -- Hardcoded as Enums in c#    
 -- Reference TSS.SmallOffice.Common.Model.Enums.RunEventType    
 SET @Success = 4    
 SET @Failure = 5    
 SET @Started = 2   
 SELECT @J1455RefProcessId = RefProcessId FROM dbo.RefProcess ref WHERE Code='J1455'
 SELECT @ParentCompositeJobProcessId = ParentProcessId FROM dbo.CoreProcessLog core WHERE core.CoreProcessRunId = @InternalCoreProcessRunId AND core.RunEventTypeId = @Started AND core.RefProcessId = @J1455RefProcessId
 SELECT @ParentCompositeJobCoreProcessRunId = run.CoreProcessRunId FROM dbo.CoreProcessRun run WHERE run.RefProcessId = @ParentCompositeJobProcessId AND run.RunEventTypeId = @Started
 
 SELECT RefProcessId,    
   CONVERT(DECIMAL(28,2),CONVERT(DECIMAL(28,2),DATEDIFF(ss, MIN(logs.AddedOn), MAX(logs.EditedOn)))/60)   [RunTime]    
 INTO #timeInSecTemp    
 FROM dbo.CoreProcessLog logs    
 WHERE logs.CoreProcessRunId = ISNULL(@ParentCompositeJobCoreProcessRunId, 0)AND    
 logs.RunEventTypeId IN (@Success,@Failure, @Started) AND logs.ParentProcessId IS NOT NULL    
 GROUP BY RefProcessId    
     
    
 SELECT ROW_NUMBER()OVER(order by logs.CoreProcessLogId) AS SrNo,ref.[Name] AS ScenarioName,    
 CASE     
  WHEN logs.RunEventTypeId = @Success THEN 'Success'    
  WHEN logs.RunEventTypeId = @Failure THEN 'Failed'    
 END AS [Status],    
 [AlertCount],    
 ISNULL(logs.[Message],'') AS [Message],  
 CASE WHEN logs.TimeInSeconds IS NOT NULL THEN logs.TimeInSeconds ELSE  tis.[RunTime] END [RunTime]    
 INTO #result    
 FROM dbo.CoreProcessLog  logs    
 INNER JOIN #timeInSecTemp tis On tis.RefProcessId = logs.RefProcessId    
 INNER JOIN dbo.RefProcess ref ON ref.RefProcessId=logs.RefProcessId    
 WHERE logs.CoreProcessRunId = ISNULL(@ParentCompositeJobCoreProcessRunId,0) AND    
 logs.RunEventTypeId IN (@Success ,@Failure )    
     
 SELECT @Count=COUNT(SrNo)    
 FROM #result    
     
 SELECT    
 @TotalAlertCount = SUM(ALertCount),    
 @TotalRunTime = SUM(RunTime)    
 FROM #result    
 WHERE @Count>0    
    
     
 IF(@Count>0)    
  BEGIN    
  INSERT INTO #result    
 (    
  SrNo,    
  ScenarioName,    
  [Status],  
  [Message],  
  AlertCount,    
  RunTime    
 )VALUES    
 (    
 @Count+1,    
 '<b>Total</b>',    
 '',    
 '',  
 @TotalAlertCount,    
 @TotalRunTime    
 )     
  END    
 SELECT *    
 FROM #result    
 ORDER BY SrNo   

 SELECT Code FROM dbo.RefProcess ref WHERE ref.RefProcessId = @ParentCompositeJobProcessId
 SELECT CONVERT(VARCHAR,addedOn) FROM dbo.CoreProcessRun run WHERE run.CoreProcessRunId = @ParentCompositeJobCoreProcessRunId
    
END    
GO
--WEB-74148 RC END
