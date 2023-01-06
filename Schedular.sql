sp_helptext CoreProcessRun_GetSchedulerStatus

 CREATE PROCEDURE [dbo].[CoreProcessRun_GetSchedulerStatus]    
 (    
  @FromDate DATETIME,    
  @ToDate DATETIME,    
  @ExcludeCancelledRecords BIT,    
  @RowsPerPage INT = null,    
  @PageNo INT = 1,    
  @ReportId INT = NULL,    
  @EventTypeId INT = NULL    
 )    
AS    
BEGIN    
     
 DECLARE @InternalFromDate DATETIME    
  SET @InternalFromDate = @FromDate    
 DECLARE @InternalToDate DATETIME    
  SET @InternalToDate = @ToDate    
 DECLARE @InternalExcludeCancelledRecords INT    
  SET @InternalExcludeCancelledRecords = @ExcludeCancelledRecords    
 DECLARE @InternalRowsPerPage INT    
  SET @InternalRowsPerPage = @RowsPerPage    
 DECLARE @InternalPageNo INT    
  SET @InternalPageNo = @PageNo    
 DECLARE @InternalProcessId INT    
  SET @InternalProcessId = @ReportId    
 DECLARE @InternalEventTypeId INT    
  SET @InternalEventTypeId = @EventTypeId    
    
      
 IF ( @InternalRowsPerPage is null )     
           SET @InternalRowsPerPage = 9999999    
        
    CREATE TABLE #CoreProcessRunIds    
    (    
  CoreProcessRunId INT    
    )    
        
    CREATE TABLE #temp    
    (    
   CoreProcessRunId INT,    
   RowNumber INT    
    )    
        
 INSERT INTO #temp    
 SELECT process.CoreProcessRunId,    
   ROW_NUMBER() OVER ( ORDER BY process.CoreProcessRunId DESC ) AS RowNumber    
 FROM CoreProcessRun process    
 WHERE ( @InternalExcludeCancelledRecords = 0 OR process.RunEventTypeId != 6 )    
 AND DATEADD(dd, 0, DATEDIFF(dd, 0, process.ScheduledAt)) BETWEEN @FromDate AND @ToDate    
 AND (@InternalProcessId is null or process.RefProcessId=@InternalProcessId)    
 AND (@InternalEventTypeId IS NULL OR process.RunEventTypeId = @InternalEventTypeId)    
     
 OPTION(RECOMPILE)    
     
  INSERT INTO #CoreProcessRunIds    
  SELECT t.CoreProcessRunId    
  FROM #temp t    
  WHERE t.RowNumber BETWEEN ( ( ( @InternalPageNo-1 )    
   *@InternalRowsPerPage )+1)    
    AND @InternalPageNo * @InternalRowsPerPage    
  ORDER BY t.CoreProcessRunId DESC    
     
        
    
  select     
  logs.CoreProcessLogId,    
  logs.CoreProcessRunId,    
  logs.[Message],    
  logs.RunEventTypeId,  
  logs.AddedOn,  
  logs.RefProcessId,  
  logs.ParentProcessId,  
  ROW_NUMBER() over(partition by logs.CoreProcessRunId order by logs.CoreProcessLogId desc) as RowNumber    
 into #CoreProcessLog    
 from dbo.CoreProcessLog logs    
 inner join #CoreProcessRunIds run on logs.CoreProcessRunId=run.CoreProcessRunId    
  
 SELECT    
  logs.CoreProcessLogId,    
  logs.CoreProcessRunId,    
  logs.[Message],    
  logs.RunEventTypeId,  
  logs.AddedOn,  
  ROW_NUMBER() over(partition by logs.CoreProcessRunId order by logs.CoreProcessLogId desc) as RowNumber    
 INTO #startedProcesslog  
 FROM #CoreProcessLog  logs  
 WHERE logs.RunEventTypeId = 2  and logs.ParentProcessId IS NULL-- this is for the started status of main process which will also consider the composite jobs with Parent processid as NULL  
           
    SELECT     
   process.RefProcessId,    
   process.RunEventTypeId,    
   process.ApplicationServerName,    
   process.Description,    
   process.ScheduledAt,    
   process.EmailRecipients,    
   process.Info1,    
   process.Info2,    
   process.Info3,    
   process.RunDate,    
   process.CoreProcessRunId,    
   process.EntityId,    
   process.AddedBy,    
   process.AddedOn,    
   process.LastEditedBy,    
   process.EditedOn,    
   dbo.GetDateTimeDifferenceInText (ISNULL(startedLog.AddedOn,process.AddedOn),process.EditedOn) as TotalTimeTaken,    
   logs.Message    
       
    FROM dbo.CoreProcessRun process    
    INNER JOIN #CoreProcessRunIds rpi ON process.CoreProcessRunId = rpi.CoreProcessRunId    
    inner join #CoreProcessLog logs on process.CoreProcessRunId=logs.CoreProcessRunId and logs.RowNumber=1      
    inner join dbo.RefProcess rp on rp.RefProcessId=process.RefProcessId    
 LEFT JOIN #startedProcesslog startedLog On process.CoreProcessRunId=startedLog.CoreProcessRunId and startedLog.RowNumber=1  
    ORDER BY ScheduledAt DESC    
       
 SELECT COUNT(1)    
  FROM #temp    
      
END  