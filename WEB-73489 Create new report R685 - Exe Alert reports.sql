--WEB -73489 -RC START
GO
ALTER PROCEDURE dbo.RefAmlReport_GetScenarioListForTradingAlertRegister
AS    
 BEGIN   
	 SELECT    amlreport.RefAmlReportId AS ReportId,
	 amlreport.Name as ReportName,
	 amlreport.ClassName,
	 0 as PendingCount,
	 0 as TotalCount,
	 alertregistercase.[Name] as CaseType
	 FROM dbo.RefAmlReport amlreport
	 INNER JOIN dbo.RefAlertRegisterCaseType alertregistercase on alertregistercase.RefAlertRegisterCaseTypeId=amlreport.RefAlertRegisterCaseTypeId  
	 WHERE alertregistercase.[Name] IN ('AML','Surveillance','AMLCOM') AND amlreport.Code NOT IN('1','2','3','4','5','7','8','9','10','12','833','834','835','836','837','838','900','901')

 END  
GO
---WEB -73489 RC END
--WEB -73489 -RC START
GO
    CREATE PROCEDURE [dbo].[RefAmlReport_GetTrackwizzAlertRelatedData]      
(      
      
  @ReportFromDate DATETIME = NULL,        
  @ReportToDate DATETIME = NULL,        
  @TxnFromDate DATETIME = NULL,        
  @TxnToDate DATETIME = NULL,        
  @AddedOnFromDate DATETIME = NULL,        
  @AddedOnToDate DATETIME = NULL,        
  @EditedOnFromDate DATETIME = NULL,        
  @EditedOnToDate DATETIME = NULL,      
  @ClientId VARCHAR(500) = NULL,        
  @Status INT = NULL,      
  @Scrip VARCHAR(200) = NULL,      
  @SegmentId INT = NULL,      
  @CaseId BIGINT = NULL      
)      
AS      
      
BEGIN      
      
DECLARE @InternalReportFromDate DATETIME      
SET @InternalReportFromDate = dbo.GetDateWithoutTime(@ReportFromDate)      
      
DECLARE @InternalReportToDate DATETIME      
SET @InternalReportToDate = DATEADD(second,-1,dbo.GetDateWithoutTime(DATEADD(day,1,@ReportToDate)))       
      
DECLARE @InternalTxnFromDate DATETIME      
SET @InternalTxnFromDate = dbo.GetDateWithoutTime(@TxnFromDate)      
      
DECLARE @InternalTxnToDate DATETIME      
SET @InternalTxnToDate = DATEADD(second,-1,dbo.GetDateWithoutTime(DATEADD(day,1,@TxnToDate)))      
      
DECLARE @InternalAddedOnFromDate DATETIME      
SET @InternalAddedOnFromDate = dbo.GetDateWithoutTime(@AddedOnFromDate)      
      
DECLARE @InternalAddedOnToDate DATETIME      
SET @InternalAddedOnToDate = DATEADD(second,-1,dbo.GetDateWithoutTime(DATEADD(day,1,@AddedOnToDate)))       
      
DECLARE @InternalEditedOnFromDate DATETIME      
SET @InternalEditedOnFromDate = dbo.GetDateWithoutTime(@EditedOnFromDate)      
      
DECLARE @InternalEditedOnToDate DATETIME      
SET @InternalEditedOnToDate = DATEADD(second,-1,dbo.GetDateWithoutTime(DATEADD(day,1,@EditedOnToDate)))       
      
DECLARE @InternalClientId VARCHAR(500)      
SET @InternalClientId = @ClientId      
      
DECLARE @InternalStatus INT      
SET @InternalStatus = @Status      
      
DECLARE @InternalScrip VARCHAR(200)      
SET @InternalScrip = @Scrip      
      
DECLARE @InternalSegmentId INT      
SET @InternalSegmentId = @SegmentId      
      
DECLARE @InternalCaseId INT      
SET @InternalCaseId = @CaseId      
      
DECLARE @TotalCount INT      
      
DECLARE @InternalStatusForCoalesce INT      
SET @InternalStatusForCoalesce =COALESCE(@InternalStatus, 1)      
      
 CREATE TABLE #tempTWAlertData      
 (      
  ReportId INT,      
  [Status] INT,      
  RefClientId INT NOT NULL,      
  RefSegmentId INT,      
  CoreAlertRegisterCaseId BIGINT NOT NULL,      
  RefInstrumentId INT ,      
  ClassName VARCHAR(500) COLLATE DATABASE_DEFAULT,      
  ReportName VARCHAR(200) COLLATE DATABASE_DEFAULT      
 )      
       
       
  INSERT INTO #tempTWAlertData(ReportId,ReportName,[Status],RefClientId,RefInstrumentId,RefSegmentId,CoreAlertRegisterCaseId,ClassName)      
  SELECT report.RefAmlReportId AS ReportId,      
  report.Name as ReportName,      
  alert.[Status],      
  alert.RefClientId,      
  alert.RefInstrumentId,      
  alert.RefSegmentEnumId AS RefSegmentId,      
  alert.CoreAlertRegisterCaseId,      
  report.ClassName      
  FROM dbo.CoreAmlScenarioAlert alert      
  INNER JOIN dbo.RefAmlReport report ON alert.RefAmlReportId = report.RefAmlReportId      
  --LEFT JOIN dbo.RefProcess process ON alert.RefAmlReportId = process.RefAmlReportId       
  WHERE report.ClassName IS NOT NULL   AND (@InternalCaseId IS NULL OR alert.CoreAlertRegisterCaseId =  @InternalCaseId)      
  AND alert.CoreAlertRegisterCaseId IS NOT NULL      
  AND       
  (@InternalReportFromDate IS NULL OR alert.ReportDate>=@InternalReportFromDate)      
  AND       
  (@InternalReportToDate IS NULL OR alert.ReportDate<=@InternalReportToDate)      
  AND       
  (@InternalAddedOnFromDate IS NULL OR alert.AddedOn>=@InternalAddedOnFromDate)      
  AND       
  (@InternalAddedOnToDate IS NULL OR alert.AddedOn<=@InternalAddedOnToDate)      
  AND       
  (@InternalEditedOnFromDate IS NULL OR alert.EditedOn>=@InternalEditedOnFromDate)      
  AND       
  (@InternalEditedOnToDate IS NULL OR alert.EditedOn<=@InternalEditedOnToDate)      
  AND      
  ((@InternalTxnFromDate IS NULL OR (alert.TransactionDate IS NOT NULL AND alert.TransactionDate >= @InternalTxnFromDate) OR (alert.TransactionDate IS NULL AND alert.TransactionFromDate >= @InternalTxnFromDate))       
   AND (@InternalTxnToDate IS NULL OR (alert.TransactionDate IS NOT NULL AND alert.TransactionDate <= @InternalTxnToDate) OR (alert.TransactionDate IS NULL AND alert.TransactionToDate <= @InternalTxnToDate)))       
        
  
      
 CREATE INDEX IX_#tempTWAlertData_idx_refcl_repor_refin_refse_class_repor on #tempTWAlertData(RefClientId,ReportName,RefInstrumentId,RefSegmentId,ClassName,ReportId)      
 SELECT temp.ReportId      
 ,temp.ReportName      
 ,ISNULL(ISNULL(SUM(CASE WHEN temp.[Status] = @InternalStatusForCoalesce THEN 1 ELSE 0 END),0),0) AS PendingCount      
 ,COUNT(1) AS TotalCount,      
 temp.ClassName,      
 alertregistercase.Name as CaseType      
 FROM #tempTWAlertData temp      
 INNER JOIN RefClient client on client.RefClientId=temp.RefClientId      
 inner join RefAmlReport amlreport on amlreport.Name=temp.ReportName      
 inner join RefAlertRegisterCaseType alertregistercase on alertregistercase.RefAlertRegisterCaseTypeId=amlreport.RefAlertRegisterCaseTypeId      
 LEFT JOIN RefInstrument inst on temp.RefInstrumentId=inst.RefInstrumentId      
 --LEFT JOIN dbo.RefSegmentEnum s on  (temp.ReportId is null and  s.RefSegmentEnumId=temp.RefSegmentId) or      
 --temp.ReportId is not null and s.RefSegmentEnumId = ISNULL(temp.RefSegmentId,inst.RefSegmentId)      
 WHERE      
 (      
  @InternalSegmentId IS NULL       
  OR EXISTS      
  (      
   SELECT 1 FROM dbo.RefSegmentEnum s      
   WHERE       
   (temp.ReportId is null and  s.RefSegmentEnumId=temp.RefSegmentId)      
   OR temp.ReportId is not null and s.RefSegmentEnumId = ISNULL(temp.RefSegmentId,inst.RefSegmentId)     
   AND s.RefSegmentEnumId = @InternalSegmentId      
  )      
 )      
 AND      
 (      
  @InternalClientId IS NULL       
  OR      
  (@InternalClientId is not null and (client.ClientId LIKE '%' +  @InternalClientId +'%' OR client.Name LIKE '%' +  @InternalClientId +'%'))      
 )      
 AND       
 (      
  @InternalScrip IS NULL       
  OR        
  (@InternalScrip is not null and (inst.Code LIKE '%' +  @InternalScrip +'%' OR inst.Name LIKE '%' +  @InternalScrip +'%'))      
 )      
 AND (@InternalCaseId IS NULL OR temp.CoreAlertRegisterCaseId = @InternalCaseId)      
 --AND (@InternalStatus IS NULL OR temp.[Status] = @InternalStatus)      
 GROUP BY temp.ReportName,temp.ClassName,temp.ReportId,alertregistercase.Name      
 ORDER BY temp.ReportName      
      
end   
GO
---WEB -73489 RC END