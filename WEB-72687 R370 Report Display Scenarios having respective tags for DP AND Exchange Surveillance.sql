--WEB-72687-RC START
GO
 ALTER PROCEDURE [dbo].[R370_GetAllScenarioNamesWithDate]    
(    
 @AlertType VARCHAR(2000)    
)    
AS    
    
BEGIN    
    
DECLARE @InternalAlertType VARCHAR(2000)    
SET @InternalAlertType=@AlertType    
 
    
SELECT     
NULL AS ReportId,    
dptype.Name AS ReportName,    
trans.AddedOn,    
NULL AS RefInstrumentId,    
batch.RefSegmentId,    
@InternalAlertType AS AlertType    
INTO #DpAlertTypes    
FROM  dbo.CoreDpSuspiciousTransaction trans    
INNER JOIN dbo.CoreDpSuspiciousTransactionBatch batch ON trans.CoreDpSuspiciousTransactionBatchId = batch.CoreDpSuspiciousTransactionBatchId AND (@InternalAlertType='NSDL' OR @InternalAlertType='CDSL')    
INNER JOIN dbo.RefDpSuspiciousTransactionType dptype ON batch.RefDpSuspiciousTransactionTypeId=dptype.RefDpSuspiciousTransactionTypeId    
    
    
select     
NULL AS ReportId,    
segment.segment AS ReportName,    
alr.AddedOn,    
NULL AS RefInstrumentId,    
alr.RefSegmentId,    
@InternalAlertType AS AlertType    
INTO #ExchangeAlertType    
FROM dbo.CoreAlert alr    
INNER JOIN dbo.RefSegmentEnum segment ON segment.RefSegmentEnumId=alr.RefSegmentId    
WHERE @InternalAlertType='EXCHANGE'    
    
CREATE TABLE #tempDataForScenarios    
(    
ReportId INT ,    
ReportName VARCHAR(2000) COLLATE Database_default,    
CaseType VARCHAR(2000) COLLATE Database_default,    
segment VARCHAR(2000) COLLATE Database_default,    
AlertType VARCHAR(2000) COLLATE Database_default,     
)    
    
--insert into #tempDataForScenarios    
SELECT *    
FROM(    
SELECT amlreport.RefAmlReportId ReportId    ,
amlreport.[Name] ReportName,    
alertregistercase.[Name] AS CaseType,    
NULL AS segment,    
@InternalAlertType AS AlertType    
FROM dbo.RefAmlReport amlreport    
INNER JOIN dbo.RefAlertRegisterCaseType alertregistercase ON @InternalAlertType = 'TRACKWIZZ' AND 
alertregistercase.RefAlertRegisterCaseTypeId=amlreport.RefAlertRegisterCaseTypeId  AND amlreport.ClassName IS NOT NULL AND  alertregistercase.[Name] IN ('AML','Surveillance','AMLCOM')
  
   
UNION     
    
SELECT temp.ReportId    
,temp.ReportName,    
NULL AS CaseType,    
segment.Segment AS segment,    
CASE    
WHEN segment.Segment='NSDL' THEN 'NSDL'     
WHEN segment.Segment='NSDL' THEN 'CDSL'      
ELSE NULL END AS AlertType    
FROM #DpAlertTypes temp     
INNER JOIN dbo.RefSegmentEnum segment  ON segment.RefSegmentEnumId=temp.RefSegmentId    
AND  segment.Segment=@InternalAlertType    
    
    
UNION     
SELECT temp.ReportId    
,temp.ReportName,    
NULL AS CaseType,    
NULL AS segment,    
temp.AlertType    
FROM #ExchangeAlertType temp     
    
) temp    
GROUP BY temp.ReportName,temp.ReportId,temp.Segment,temp.CaseType,temp.AlertType    
ORDER BY temp.ReportName    
    
    
SELECT * FROM #tempDataForScenarios    
  
END  
GO
--WEB-72687-RC END
--WEB-72687-RC START
GO
 ALTER PROCEDURE dbo.Alerts_GetMonthlyMisReportGridData   
(  
 @DateType VARCHAR(MAX),  
 @FromDate DATETIME,  
 @ToDate DATETIME,  
 @AlertType VARCHAR(200),  
 @ScenarioNames VARCHAR(MAX),  
 @Segments VARCHAR(MAX) = NULL,  
 @RowsPerPage INT = NULL,  
 @PageNo INT = 1,  
 @DpId INT = NULL  
)  
AS  
BEGIN  

  DECLARE @FromDateInternal DATETIME,  
  @ToDateInternal DATETIME,  
  @InternalAlertType VARCHAR(200),  
  @InternalScenarioNames VARCHAR(MAX),  
  @InternalSegments VARCHAR(MAX),  
  @ScenarioAlertsId INT,  
  @ExchangeAlertsId INT,  
  @DpSuspiciousTransactionAlertsId INT,  
  @PendingStatus INT,  
  @ClosedStatus INT,  
  @ReportedStatus INT,  
  @ToBeReportedStatus INT,  
  @InternalDateType VARCHAR(MAX),  
  @ParamDefinition VARCHAR(MAX),  
  @ReferredToExchange INT,  
  @ReferredToDepository INT,  
  @InternalDpId INT,  
  @CDSLid INT,  
  @NSDLid INT  
  
 SET @InternalDateType = @DateType  
 SET @FromDateInternal = dbo.GetDateWithoutTime(@FromDate)  
 SET @ToDateInternal = DATEADD(DAY, 1, dbo.GetDateWithoutTime(@ToDate))  
 SET @InternalAlertType = @AlertType  
 SET @InternalScenarioNames = @ScenarioNames  
 SET @InternalSegments = @Segments  
 SET @InternalDpId = @DpId  
 SET @ScenarioAlertsId = dbo.GetEntityTypeByCode('ScenarioAlerts')  
 SET @ExchangeAlertsId = dbo.GetEntityTypeByCode('ExchangeAlerts')  
 SET @DpSuspiciousTransactionAlertsId = dbo.GetEntityTypeByCode('DpSuspiciousTransactionAlerts')  
 SET @ReferredToExchange = dbo.GetEnumValueId('AmlAlertTag', 'ReferredToExchange')  
 SET @ReferredToDepository = dbo.GetEnumValueId('AmlAlertTag', 'ReferredToDepository')  
 SET @PendingStatus = 1  
 SET @ClosedStatus = 2  
 SET @ReportedStatus = 3  
 SET @ToBeReportedStatus = 4  
 SELECT @CDSLid = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'CDSL'  
 SELECT @NSDLid = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSDL'  
  
 -- Pagination --  
 DECLARE @InternalRowsPerPage INT  
  
 SET @InternalRowsPerPage = @RowsPerPage  
  
 DECLARE @InternalPageNo INT  
  
 SET @InternalPageNo = @PageNo  
  
 IF (@InternalRowsPerPage IS NULL)  
  SET @InternalRowsPerPage = 20  

  SELECT s.items AS ReportName, r.RefAmlReportId, r.ScenarioNo
  INTO #refamlreport
  FROM dbo.Split(@InternalScenarioNames, ',') s
  LEFT JOIN dbo.RefAmlReport r ON r.[Name] = s.items
  
 -- Intermediary Table | To get bifurcated data from three tables based on filter selected --  
 CREATE TABLE #IntermediaryTable (  
  ReportName VARCHAR(MAX) COLLATE DATABASE_DEFAULT,  
  AddedOn DATETIME,  
  FilterDate DATETIME,  
  AlertClosedDate DATETIME,  
  AlertStatus INT,  
  AlertTagId INT,  
  ScenarioCode INT NULL,  
  RefClientId INT,  
  RefSegmentEnumId INT,
  CoreAmlScenarioAlertId BIGINT NULL
  )  
  
 IF @InternalAlertType = 'TrackWizz'  
 BEGIN  
  INSERT INTO #IntermediaryTable (  
   ReportName,  
   AddedOn,  
   FilterDate,  
   AlertClosedDate,  
   AlertStatus,  
   AlertTagId,  
   ScenarioCode,  
   alert.RefClientId,  
   alert.RefSegmentEnumId ,
   CoreAmlScenarioAlertId
   )  
  SELECT DISTINCT s.ReportName,  
   alert.AddedOn AS AddedOn,  
   CASE   
    WHEN @InternalDateType = 'AddedOn'  
     THEN alert.AddedOn  
    WHEN @InternalDateType = 'ReportDate'  
     THEN alert.ReportDate  
    WHEN @InternalDateType = 'TransactionDate'  
     THEN ISNULL(alert.TransactionDate, alert.ReportDate)  
    END AS FilterDate,  
   alert.AlertClosedDate AS AlertClosedDate,  
   alert.[Status] AS AlertStatus,  
   linkTag.AlertTagRefEnumValueId AS AlertTagId,  
   amlreport.ScenarioNo AS ScenarioCode,  
   alert.RefClientId,  
   alert.RefSegmentEnumId,
   alert.CoreAmlScenarioAlertId
  FROM dbo.CoreAmlScenarioAlert alert  
  INNER JOIN dbo.RefAmlReport amlreport ON amlreport.RefAmlReportId = alert.RefAmlReportId  
  INNER JOIN #refamlreport s ON s.ReportName = amlreport.[Name]  
  LEFT JOIN dbo.LinkAlertRegisterAlertTagRefEnumValue linkTag ON alert.CoreAmlScenarioAlertId = linkTag.EntityId  
   AND linkTag.RefEntityTypeId = @ScenarioAlertsId  
   AND linkTag.AlertTagRefEnumValueId = @ReferredToExchange  
  Left join dbo.RefInstrument r on alert.RefInstrumentId = r.RefInstrumentId    
  LEFT JOIN dbo.Split(@InternalSegments, ',') seg ON CONVERT(INT, seg.items) = r.RefSegmentId OR alert.RefSegmentEnumId=CONVERT(INT, seg.items)  
  WHERE   
  (  
   @InternalSegments is null or   
   (  
    (  
     alert.RefSegmentEnumId IS NULL AND r.RefSegmentId IS NULL  
    )  
    OR  
    (   
     alert.RefSegmentEnumId=CONVERT(INT, seg.items)) OR r.RefSegmentId = CONVERT(INT, seg.items)  
    )  
  )    

 END  
 ELSE IF @InternalAlertType = 'Exchange'  
 BEGIN  
  INSERT INTO #IntermediaryTable (  
   ReportName,  
   AddedOn,  
   FilterDate,  
   AlertClosedDate,  
   AlertStatus,  
   AlertTagId,  
   alert.RefClientId,  
   alert.RefSegmentEnumId  
   )  
  SELECT s.ReportName,  
   alert.AddedOn AS AddedOn,  
   CASE   
    WHEN @InternalDateType = 'AddedOn'  
     THEN alert.AddedOn  
    WHEN @InternalDateType = 'ReportDate'  
     THEN alert.AlertDate  
    WHEN @InternalDateType = 'TransactionDate'  
     THEN ISNULL(alert.TradeDate, alert.AlertDate)  
    END AS FilterDate,  
   alert.AlertClosedDate AS AlertClosedDate,  
   alert.[Status] AS AlertStatus,  
   linkTag.AlertTagRefEnumValueId AS AlertTagId,  
   alert.RefClientId,  
   segment.RefSegmentEnumId  
  FROM dbo.CoreAlert Alert  
  INNER JOIN dbo.RefSegmentEnum segment ON Alert.RefSegmentId = segment.RefSegmentEnumId  
  INNER JOIN #refamlreport s ON s.ReportName = segment.segment  
  LEFT JOIN dbo.LinkAlertRegisterAlertTagRefEnumValue linkTag ON alert.CoreAlertId = linkTag.EntityId  
   AND linkTag.RefEntityTypeId = @ExchangeAlertsId  
   AND linkTag.AlertTagRefEnumValueId = @ReferredToExchange  
 END  
 ELSE IF @InternalAlertType = 'NSDL'  
  OR @InternalAlertType = 'CDSL'  
 BEGIN  
  INSERT INTO #IntermediaryTable (  
   ReportName,  
   AddedOn,  
   FilterDate,  
   AlertClosedDate,  
   AlertStatus,  
   AlertTagId,  
   alert.RefClientId,  
   alert.RefSegmentEnumId  
   )  
  SELECT s.ReportName,  
   alert.AddedOn AS AddedOn,  
   CASE   
    WHEN @InternalDateType = 'AddedOn'  
     THEN alert.AddedOn  
    WHEN @InternalDateType = 'ReportDate'  
     OR @InternalDateType = 'TransactionDate'  
     THEN alert.TransactionDate  
    END AS FilterDate,  
   alert.AlertClosedDate AS AlertClosedDate,  
   alert.[Status] AS AlertStatus,  
   linkTag.AlertTagRefEnumValueId AS AlertTagId,  
   alert.RefClientId,  
   segment.RefSegmentEnumId  
  FROM dbo.CoreDpSuspiciousTransaction alert  
  INNER JOIN dbo.CoreDpSuspiciousTransactionBatch batch ON alert.CoreDpSuspiciousTransactionBatchId = batch.CoreDpSuspiciousTransactionBatchId  
  INNER JOIN dbo.RefDpSuspiciousTransactionType dptype ON batch.RefDpSuspiciousTransactionTypeId = dptype.RefDpSuspiciousTransactionTypeId  
  INNER JOIN #refamlreport s ON s.ReportName = dptype.[Name]  
  INNER JOIN dbo.RefSegmentEnum segment ON segment.RefSegmentEnumId = batch.RefSegmentId  
  LEFT JOIN dbo.LinkAlertRegisterAlertTagRefEnumValue linkTag ON alert.CoreDpSuspiciousTransactionId = linkTag.EntityId  
   AND linkTag.RefEntityTypeId = @DpSuspiciousTransactionAlertsId  
   AND linkTag.AlertTagRefEnumValueId = @ReferredToDepository  
 END  
  
 CREATE TABLE #FilteredData (  
  ReportName VARCHAR(MAX) COLLATE DATABASE_DEFAULT,  
  AddedOn DATETIME,  
  FilterDate DATETIME,  
  AlertClosedDate DATETIME,  
  AlertStatus INT,  
  AlertTagId INT,  
  ScenarioCode INT NULL,  
  RefClientId INT,  
  RefSegmentEnumId INT ,
  CoreAmlScenarioAlertId BIGINT NULL
  )  
  
 IF(@InternalDpid IS NOT NULL AND @InternalAlertType = 'TrackWizz')  
    BEGIN  
     INSERT  
     INTO #FilteredData  
     SELECT inter.*  
     FROM #IntermediaryTable inter   
     INNER JOIN dbo.RefClient client ON inter.RefClientId = client.RefClientId  
     WHERE (inter.RefSegmentEnumId = @NSDLid OR inter.RefSegmentEnumId = @CDSLid)  
     AND (@InternalDpid = client.DpId OR @InternalDpid = CONVERT(INT,SUBSTRING(client.ClientId,1,LEN(@InternalDpid))))  
    END  
   ELSE  
   BEGIN  
    INSERT    
    INTO #FilteredData  
    SELECT t.*  
    FROM #IntermediaryTable t  
   END  
  
 -- Final Table | To get everything ready for the show --  
 CREATE TABLE #FinalTable (  
  ReportName VARCHAR(MAX) COLLATE DATABASE_DEFAULT,  
  CreatedDuringPeriod INT,  
  PendingBeforePeriod INT,  
  ClosedDuringPeriod INT,  
  ReferredToExchange INT
  )  
  
 INSERT INTO #FinalTable  
 SELECT ReportName,  
  SUM(CASE   
    WHEN @FromDateInternal <= Filterdate  
     AND @ToDateInternal > Filterdate  
     THEN 1  
    ELSE 0  
    END) AS CreatedDuringPeriod,  
  SUM(CASE   
    WHEN (  
      @FromDateInternal > Filterdate  
      AND (  
       AlertStatus IN (@PendingStatus, @ToBeReportedStatus)  
       OR (  
        AlertStatus IN (@ClosedStatus, @ReportedStatus)  
        AND AlertClosedDate > @FromDateInternal  
        )  
       )  
      )  
     THEN 1  
    ELSE 0  
    END) AS PendingBeforePeriod,  
  SUM(CASE   
    WHEN @FromDateInternal <= AlertClosedDate  
     AND @ToDateInternal > AlertClosedDate  
     AND AlertStatus = @ClosedStatus  
     THEN 1  
    ELSE 0  
    END) AS ClosedDuringPeriod,  
  SUM(CASE   
    WHEN @FromDateInternal <= FilterDate  
     AND @ToDateInternal > FilterDate  
     AND (  
      AlertTagId = @ReferredToExchange  
      OR AlertTagId = @ReferredToDepository  
      )  
     THEN 1  
    ELSE 0  
    END) AS ReferredToExchange
 FROM #FilteredData  
 GROUP BY ReportName, ScenarioCode  
  
 -- Select | For Report --  
 SELECT re.ReportName AS NameOfAlert,  
  ISNULL(PendingBeforePeriod, 0) AS  PendingBeforePeriod,
  ISNULL(CreatedDuringPeriod, 0) AS  CreatedDuringPeriod,
  ISNULL(ClosedDuringPeriod,  0) AS ClosedDuringPeriod,
  ISNULL(ReferredToExchange,  0) AS ReferredToExchange,
  ((ISNULL(PendingBeforePeriod,0) + ISNULL(CreatedDuringPeriod,0)) - ISNULL(ClosedDuringPeriod,0)) AS PendingAfterEndOfPeriod  ,  
  ROW_NUMBER() OVER (  
   ORDER BY re.RefAMlReportId  
   ) AS RowNumber
   INTO #FinalReport
 FROM #refamlreport re
 LEFT JOIN #FinalTable  f ON f.ReportName = re.ReportName


 SELECT *
  FROM #FinalReport
 WHERE RowNumber BETWEEN (((@InternalPageNo - 1) * @InternalRowsPerPage) + 1)  
   AND @InternalPageNo * @InternalRowsPerPage  
  
 SELECT COUNT(1)  
 FROM #FinalReport  
END  
GO
--WEB-72687-RC END

