---------------RC STARTS WEB-62251 ------------
GO
ALTER PROCEDURE [dbo].[R370_GetAllScenarioNamesWithDate]  
(  
 @AlertType VARCHAR(2000)  
)  
AS  
  
BEGIN  
  
DECLARE @InternalAlertType VARCHAR(2000)  
SET @InternalAlertType=@AlertType  
  
  
SELECT report.RefAmlReportId AS ReportId,  
report.Name AS ReportName,  
alert.AddedOn,   
alert.RefInstrumentId,  
alert.RefSegmentEnumId AS RefSegmentId,   
@InternalAlertType as AlertType  
INTO #testdata  
FROM dbo.CoreAmlScenarioAlert alert  
INNER JOIN dbo.RefAmlReport report ON alert.RefAmlReportId = report.RefAmlReportId  AND @InternalAlertType='TRACKWIZZ'  
INNER JOIN dbo.RefProcess process ON process.RefAmlReportId = report.RefAmlReportId
INNER JOIN dbo.RefAlertRegisterCaseType alertregistercase on alertregistercase.RefAlertRegisterCaseTypeId=report.RefAlertRegisterCaseTypeId  
WHERE report.ClassName IS NOT NULL AND alert.CoreAlertRegisterCaseId IS NOT NULL 
  
  
  
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
SELECT temp.ReportId  
,temp.ReportName,  
alertregistercase.Name AS CaseType,  
NULL AS segment,  
temp.AlertType  
FROM #testdata temp  
INNER JOIN dbo.RefAmlReport amlreport ON amlreport.Name=temp.ReportName  
INNER JOIN dbo.RefAlertRegisterCaseType alertregistercase ON alertregistercase.RefAlertRegisterCaseTypeId=amlreport.RefAlertRegisterCaseTypeId  
LEFT JOIN dbo.RefInstrument inst ON temp.RefInstrumentId=inst.RefInstrumentId  
LEFT JOIN dbo.RefSegmentEnum s ON  (temp.ReportId IS NULL AND  s.RefSegmentEnumId=temp.RefSegmentId) OR  
temp.ReportId IS NOT NULL AND s.RefSegmentEnumId = ISNULL(temp.RefSegmentId,inst.RefSegmentId)  
 
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
 ---------------RC ENDS WEB-62251 ------------
