--File:StoredProcedures:dbo:CoreAmlScenarioAlert_DeleteTrackWizzScenarioAlerts
--RC-END-WEB 77025  
GO
ALTER PROCEDURE [dbo].[CoreAmlScenarioAlert_DeleteTrackWizzScenarioAlerts]
(
@ReportIds VARCHAR(MAX),
@FromDate DATETIME,
@ToDate DATETIME
)
AS

DECLARE @InternalFromDate DATETIME, @MaxCount INT
SET @InternalFromDate = @FromDate

DECLARE @InternalToDate DATETIME
SET @InternalToDate = @ToDate

BEGIN

SELECT items AS ReportId
INTO #tempReportIds
FROM dbo.Split(@ReportIds,',')


SELECT 
CoreAmlScenarioAlertId
INTO #tempAlertIds
FROM 
dbo.CoreAmlScenarioAlert alert
INNER JOIN dbo.RefAmlReport report ON alert.RefAmlReportId = report.RefAmlReportId
INNER JOIN #tempReportIds ids ON report.RefAmlReportId = ids.ReportId
WHERE dbo.IsDateBetween(alert.ReportDate, @InternalFromDate, @InternalToDate) = 1

SELECT
DISTINCT alert.CoreAlertRegisterCaseId
INTO #CoreAlertRegisterEmptyCase
FROM dbo.CoreAmlScenarioAlert alert
INNER JOIN #tempAlertIds ids ON alert.CoreAmlScenarioAlertId = ids.CoreAmlScenarioAlertId

DELETE alertDetail
FROM dbo.CoreAmlScenarioAlertDetail alertDetail
INNER JOIN #tempAlertIds alerts ON alerts.CoreAmlScenarioAlertId = alertDetail.CoreAmlScenarioAlertId

DELETE alert
FROM dbo.CoreAmlScenarioAlert alert
INNER JOIN #tempAlertIds alerts ON alerts.CoreAmlScenarioAlertId = alert.CoreAmlScenarioAlertId

SELECT 
	cas.CoreAlertRegisterCaseId
INTO #tempTradingCaseIdToDelete
FROM #CoreAlertRegisterEmptyCase cas
LEFT JOIN dbo.CoreAmlScenarioAlert alert ON alert.CoreAlertRegisterCaseId = cas.CoreAlertRegisterCaseId
WHERE alert.CoreAlertRegisterCaseId IS NULL

DELETE FROM CoreAlertRegisterCasePan 
WHERE CoreAlertRegisterCaseId IN (
				SELECT CoreAlertRegisterCaseId FROM #tempTradingCaseIdToDelete)
				
DELETE FROM CoreAlertRegisterCaseAssignmentHistory
WHERE CoreAlertRegisterCaseId IN (
				SELECT CoreAlertRegisterCaseId FROM #tempTradingCaseIdToDelete)				

DELETE FROM CoreAlertRegisterCaseComment
WHERE CoreAlertRegisterCaseId IN (
				SELECT CoreAlertRegisterCaseId FROM #tempTradingCaseIdToDelete)	
							
DELETE FROM CoreAlertRegisterCaseAttachment
WHERE CoreAlertRegisterCaseId IN (
				SELECT CoreAlertRegisterCaseId FROM #tempTradingCaseIdToDelete)				
									
DELETE FROM CoreAlertRegisterCase
WHERE CoreAlertRegisterCaseId IN (
				SELECT CoreAlertRegisterCaseId FROM #tempTradingCaseIdToDelete)
				
SELECT  @MaxCount = COUNT(*) FROM #tempAlertIds	

DROP TABLE #tempAlertIds

SELECT 
alert.CoreAlertRegisterCustomerCaseAlertId
INTO #tempCoreAlertRegisterCustomerCaseAlertIds
FROM dbo.CoreAlertRegisterCustomerCaseAlert alert
INNER JOIN dbo.RefAmlReport report ON alert.RefAmlReportId = report.RefAmlReportId
INNER JOIN #tempReportIds ids ON report.RefAmlReportId = ids.ReportId
WHERE dbo.IsDateBetween(dbo.GetDateWithoutTime(alert.AlertGenerationDate), @InternalFromDate, @InternalToDate) = 1

SELECT
DISTINCT alert.CoreAlertRegisterCustomerCaseId
INTO #tempCoreAlertRegisterCustomerCaseIds
FROM dbo.CoreAlertRegisterCustomerCaseAlert alert
INNER JOIN #tempCoreAlertRegisterCustomerCaseAlertIds ids ON ids.CoreAlertRegisterCustomerCaseAlertId = alert.CoreAlertRegisterCustomerCaseAlertId

DELETE alert
FROM dbo.CoreAlertRegisterCustomerCaseAlert alert
INNER JOIN #tempCoreAlertRegisterCustomerCaseAlertIds temp ON temp.CoreAlertRegisterCustomerCaseAlertId = alert.CoreAlertRegisterCustomerCaseAlertId

SELECT
DISTINCT cas.CoreAlertRegisterCustomerCaseId
INTO #caseIdsToDelete
FROM #tempCoreAlertRegisterCustomerCaseIds cas
LEFT JOIN dbo.CoreAlertRegisterCustomerCaseAlert alert ON alert.CoreAlertRegisterCustomerCaseId = cas.CoreAlertRegisterCustomerCaseId
WHERE alert.CoreAlertRegisterCustomerCaseId IS NULL


DELETE comment FROM dbo.CoreAlertRegisterCustomerCaseComment comment
WHERE  comment.CoreAlertRegisterCustomerCaseId IN (
				SELECT CoreAlertRegisterCustomerCaseId FROM #caseIdsToDelete)

DELETE link FROM dbo.LinkCoreAlertRegisterCustomerCaseRefCRMCustomer link
WHERE  link.CoreAlertRegisterCustomerCaseId IN (
				SELECT CoreAlertRegisterCustomerCaseId FROM #caseIdsToDelete)

DELETE cas FROM dbo.CoreAlertRegisterCustomerCase cas
WHERE cas.CoreAlertRegisterCustomerCaseId IN (
				SELECT CoreAlertRegisterCustomerCaseId FROM #caseIdsToDelete)

SET  @MaxCount = @MaxCount + (SELECT COUNT(*) FROM #tempCoreAlertRegisterCustomerCaseAlertIds)

SELECT @MaxCount
END
GO
--RC-END-WEB 77025  