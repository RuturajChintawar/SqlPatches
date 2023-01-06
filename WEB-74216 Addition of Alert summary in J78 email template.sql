
GO
UPDATE ref
SET ref.EmailBody ='
Dear Sir,  <br> <br> Please find the details below as per job J78 .  <br> <br>   
<br>Case manager activity (equity, derivatives & currency) for Date:<Date>  
<br>  <Table>  <br>  
<table>  <tr>  
<td colspan=2> How to read the table above </td>  
<tr>  <tr> <td>Opening</td>  <td> Opening Balance</td>  </tr>   
<tr>  <td> New Alloted</td>  <td>Assigned to that person (new or old)</td>  </tr>   
<tr>  <td> Viewed</td>  <td>Unique cases were viewed</td>  </tr>   
<tr>  <td>Acted</td>  <td>Did anything other than view.</td>  </tr>   
<tr>  <td>Assigned</td> <td>Assigned to someone else.</td>  </tr>   
<tr>  <td>StatusChange</td> <td>Case Status Change.</td>  </tr>   
<tr>  <td>Closed</td> <td>Cases closed</td>  </tr>    
<tr>  <td>To be reported / Reported</td> <td>case where the status changed to “To be reported” or    “Reported”</td>  </tr>   
<tr>  <td> Final Balance </td>  <td>Outstanding cases</td>  </tr> 
2) Summary of Alert Action by users for Date:<Date>  <br>
<AlertRelatedSummary><br>
<table>  <tr>  
<td colspan=2> How to read the table above </td>  
<tr>  <tr> <td>Closed:</td>  <td> Alerts closed on the run date</td>  </tr>   
<tr>  <td> Reported:</td>  <td>Alerts sent in the reported bucket on the run date</td>  </tr>   
</table>  <br>  <AlertSummaryTable> <br> <br> This is a system generated email. <br> Thanks,  
<br> TrackWizz System
'
FROM dbo.RefEmailTemplate ref
WHERE ref.Code = '329'
GO
dbo.GenerateAuditTrail
GO
CREATE PROCEDURE GetAlertStatusSummary_CoreAmlScenarioAlert_Audit(
	@EmployeeIds VARCHAR(MAX),
	@RunDate DATETIME
)

AS BEGIN 
	DECLARE @EmployeeIdsInternal VARCHAR(MAX),
	@RunDateInternal DATETIME

	SET @RunDateInternal = @RunDate
	SET @EmployeeIdsInternal = @EmployeeIds
	
	SELECT t.RefEmployeeId,
	ref.UserName
	INTO #EmployeeData
	FROM(
	SELECT CONVERT(INT,s.s) RefEmployeeId
	FROM dbo.ParseString(@EmployeeIdsInternal,',') s) t
	INNER JOIN dbo.RefEmployee ref ON ref.RefEmployeeId = t.RefEmployeeId
	select
	p.*
	into #tempData
	from
	(SELECT
		t.*,
		ROW_NUMBER () OVER (PARTITION BY t.CoreAmlScenarioAlertId ORDER BY t.AuditDateTime DESC) RN
	FROM
	(
	SELECT  e.RefEmployeeId,
	e.UserName,
	au.AuditDateTime,
	au.CoreAmlScenarioAlertId,[Status]

	FROM #EmployeeData e
	INNER JOIN dbo.CoreAmlScenarioAlert_Audit au ON au.LastEditedBy = e.UserName  AND AuditDMLAction ='Update' AND [Status] IN (2, 3)
		AND dbo.GetDateWithoutTime(au.AuditDateTime) = dbo.GetDateWithoutTime(@RunDateInternal) AND AuditDataState = 'New') t)p
			WHERE p.RN = 1

	select
	t.RefEmployeeId,
	COUNT(CASE WHEN t.[Status] = 2 THEN 1 else 0 end) cl,
	COUNT(CASE WHEN t.[Status] = 3 THEN 1 else 0 end) re
	INTO #finalData
	FROM #tempData t
	GROUP BY RefEmployeeId

	SELECT
	emp.[Name] AS  Employee,
	fd.cl AS Closed,
	fd.re AS Reported
	FROM #finalData fd
	INNER JOIN dbo.RefEmployee emp ON emp.RefEmployeeId = fd.RefEmployeeId

END
GO
 CREATE PROCEDURE dbo.GetAlertStatusSummary_CoreAmlScenarioAlert_Audit(  
 @RunDate DATETIME  
)  
  
AS BEGIN   
 DECLARE @RunDateInternal DATETIME  
  
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
   
  
 SELECT  
  audi.CoreAmlScenarioAlertId,  
  audi.[Status],  
  audi.LastEditedBy,  
  audi.AuditDateTime,  
  CASE WHEN audi.AuditDataState = 'New' THEN 1 ELSE 0 END AS AuditDataState  
 INTO #alertAudit  
 FROM dbo.CoreAmlScenarioAlert_Audit audi  
 WHERE audi.AuditDMLAction ='Update'  
 AND dbo.GetDateWithoutTime(audi.AuditDateTime) = @RunDateInternal  
   
 SELECT  
 p.*,  
 emp.RefEmployeeId  
 INTO #tempData  
 FROM  
 (  
 SELECT adNew.LastEditedBy AS UserName,  
 adNew.AuditDateTime,  
 adNew.CoreAmlScenarioAlertId,adNew.[Status],  
 ROW_NUMBER () OVER (PARTITION BY adNew.CoreAmlScenarioAlertId ORDER BY adNew.AuditDateTime DESC, adOld.AuditDateTime DESC) RN  
  
 FROM #alertAudit adNew  
 INNER JOIN #alertAudit adOld ON adOld.CoreAmlScenarioAlertId = adNew.CoreAmlScenarioAlertId  
  AND adOld.AuditDataState = 0 AND adOld.[Status] <> adNew.[Status]  
 WHERE adNew.AuditDataState = 1 AND adNew.[Status] IN (2, 3)   
  
   
 )p  
 INNER JOIN dbo.RefEmployee emp ON p.UserName = emp.UserName  
 WHERE p.RN = 1  
  
 select  
 t.RefEmployeeId,  
 SUM(CASE WHEN t.[Status] = 2 THEN 1 else 0 end) cl,  
 SUM(CASE WHEN t.[Status] = 3 THEN 1 else 0 end) re  
 INTO #finalData  
 FROM #tempData t  
 GROUP BY RefEmployeeId  
  
 SELECT  
 emp.[Name] AS  Employee,  
 fd.cl AS Closed,  
 fd.re AS Reported  
 FROM #finalData fd  
 INNER JOIN dbo.RefEmployee emp ON emp.RefEmployeeId = fd.RefEmployeeId  
  
END  