--File:Tables:dbo:RefEmailTemplate:DML
--WEB-77862-RC START
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
Summary of Alert Action by users for Date:<Date>  <br>
<AlertRelatedSummary><br>
<table>  <tr>  
<td colspan=2> How to read the table above </td>  
<tr>  <tr> <td>Closed:</td>  <td> Alerts closed on the run date</td>  </tr>   
<tr>  <td> Reported:</td>  <td>Alerts sent in the reported bucket on the run date</td>  </tr>   
</table>  <br> 
Summary of Alert Action by users on external Alerts(DP & Exchange alerts) for Date: <Date>
<DpAndExchangeAlertSummary><br>
<AlertSummaryTable> <br>
This is a system generated email. <br> 
Thanks,  <br>
TrackWizz System
'
FROM dbo.RefEmailTemplate ref
WHERE ref.Code = '155'
GO
GO
UPDATE dbo.RefEmailTemplate
SET EmailBody =
	'Dear Sir/Madam,<br/>

The Job J1455 Status Email for Alert generation of Composite Job <JobCode> <IsAddedOn> <AddedOn> has run successfully as on Run Date <SystemDate><br/>

1.Below is the summary of Composite Job: <br/>

<SuccessStatusTable><br/>

2.Case manager activity(AML) for date <SystemDate>: <br/>

<CaseManagerActivityTable><br/>

<table>  <tr>  <td colspan=2> How to read the table above </td>  <tr>  <tr>
<td>Opening</td>  <td> Opening Balance</td>  </tr>   
<tr>  <td> New Alloted</td>  <td>Assigned to that person (new or old)</td>  </tr>   
<tr>  <td> Viewed</td>  <td>Unique cases were viewed</td>  </tr>   
<tr>  <td>Acted</td>  <td>Did anything other than view.</td>  </tr>   
<tr>  <td>Assigned</td> <td>Assigned to someone else.</td>  </tr>   
<tr>  <td>StatusChange</td> <td>Case Status Change.</td>  </tr>   
<tr>  <td>Closed</td> <td>Cases closed</td>  </tr>    
<tr>  <td>To be reported / Reported</td> <td>case where the status changed to “To be reported” or    “Reported”</td>  </tr>   
<tr>  <td> Final Balance </td>  <td>Outstanding cases</td>  </tr> </table> 

3. Summary of Alert Action by users for Date:<SystemDate>  <br>
<AlertRelatedSummary><br>
<table>  <tr>  
<td colspan=2> How to read the table above </td>  
<tr>  <tr> <td>Closed:</td>  <td> Alerts closed on the run date</td>  </tr>   
<tr>  <td> Reported:</td>  <td>Alerts sent in the reported bucket on the run date</td>  </tr>   
</table>  <br> 
4.Summary of Alert Action by users on external Alerts(DP & Exchange alerts) for Date: <SystemDate>
<DpAndExchangeAlertSummary><br>

5.Consolidated email for pending/ to be reported alerts of Trackwizz For X no. of days. <br/>
<AlertData> <br>

Instance Name : <InstanceName> / Version : <Version><br />

Do not reply to this email as this is system generated.<br />Thanks, <br />TrackWizz System.'
WHERE Code = 'E1948'
GO
--WEB-77862-RC END

--File:StoredProcedures:dbo:GetAlertStatusSummary_CoreAmlScenarioAlert_Audit
--WEB-77862-RC START
GO
ALTER PROCEDURE dbo.GetAlertStatusSummary_CoreAmlScenarioAlert_Audit
(  
	@RunDate DATETIME  
)  
  
AS
BEGIN   
	 DECLARE @RunDateInternal DATETIME  
	 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
   
	 SELECT  
		  audi.CoreAmlScenarioAlertId,  
		  audi.[Status],  
		  audi.LastEditedBy,  
		  audi.AuditDateTime,  
		  CASE WHEN audi.AuditDataState = 'New' THEN 1 ELSE 0 END AS AuditDataState ,
		  audi.RefClientId
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
			 adNew.CoreAmlScenarioAlertId,
			 adNew.[Status], 
			 adNew.RefClientId,
			 ROW_NUMBER () OVER (PARTITION BY adNew.CoreAmlScenarioAlertId ORDER BY adNew.AuditDateTime DESC, adOld.AuditDateTime DESC) RN  
		 FROM #alertAudit adNew  
		 INNER JOIN #alertAudit adOld ON adOld.CoreAmlScenarioAlertId = adNew.CoreAmlScenarioAlertId  
		  AND adOld.AuditDataState = 0 AND adOld.[Status] <> adNew.[Status]  
		 WHERE adNew.AuditDataState = 1 AND adNew.[Status] IN (2, 3, 4) 
	 )p  
	 INNER JOIN dbo.RefEmployee emp ON p.UserName = emp.UserName  
	 WHERE p.RN = 1  
  
	 SELECT  
		 t.RefEmployeeId,  
		 SUM(CASE WHEN t.[Status] = 2 THEN 1 ELSE 0 END) cl,  
		 SUM(CASE WHEN t.[Status] = 3 THEN 1 ELSE 0 END) re,
		 SUM(CASE WHEN t.[Status] = 4 THEN 1 ELSE 0 END) tobereported,
		 COUNT(DISTINCT(t.RefClientId)) UniqueClient
	 INTO #finalData  
	 FROM #tempData t  
	 GROUP BY RefEmployeeId  
  
	 SELECT  
		 emp.[Name] AS  Employee,  
		 fd.cl AS Closed,  
		 fd.re AS Reported,
		 fd.UniqueClient AS UniqueClients,
		 fd.tobereported AS ToBeReported
	 FROM #finalData fd  
	 INNER JOIN dbo.RefEmployee emp ON emp.RefEmployeeId = fd.RefEmployeeId 
 
	 CREATE TABLE #tempAlertCount(
		TablePrimaryKeyId BIGINT,
		[Status] INT,
		LastEditedBy VARCHAR(50),
		AuditDateTime DATETIME,
		AuditDataState INT,
		TableKey BIT -- 1 for CoreAlert 0 for CoreDPSuspicousTransaction 
	 )

  INSERT INTO #tempAlertCount 
  SELECT
	aud.CoreAlertId,
	aud.[Status],
	aud.LastEditedBy,
	aud.AuditDateTime,
	CASE WHEN aud.AuditDataState = 'New' THEN 1 ELSE 0 END AS AuditDataState ,
	1 
  FROM dbo.CoreAlert_Audit aud
	WHERE aud.AuditDMLAction ='Update'  
	AND dbo.GetDateWithoutTime(aud.AuditDateTime) = @RunDateInternal  

  INSERT INTO #tempAlertCount 
  SELECT
	aud.CoreDpSuspiciousTransactionId,
	aud.[Status],
	aud.LastEditedBy,
	aud.AuditDateTime,
	CASE WHEN aud.AuditDataState = 'New' THEN 1 ELSE 0 END AS AuditDataState ,
	0
  FROM dbo.CoreDpSuspiciousTransaction_Audit aud
	WHERE aud.AuditDMLAction ='Update'  
	AND dbo.GetDateWithoutTime(aud.AuditDateTime) = @RunDateInternal  
	
	 SELECT  
		 p.*,  
		 emp.RefEmployeeId
	 INTO #tempDataDpAndExchange  
	 FROM  
	 (  
		 SELECT adNew.LastEditedBy AS UserName,  
			 adNew.AuditDateTime,  
			 adNew.TablePrimaryKeyId,
			 adNew.[Status],
			 ROW_NUMBER () OVER (PARTITION BY adNew.TablePrimaryKeyId, adNew.TableKey ORDER BY adNew.AuditDateTime DESC, adOld.AuditDateTime DESC) RN  
		 FROM #tempAlertCount adNew  
		 INNER JOIN #tempAlertCount adOld ON adOld.TablePrimaryKeyId = adNew.TablePrimaryKeyId  AND adNew.TableKey = adOld.TableKey 
		  AND adOld.AuditDataState = 0 AND adOld.[Status] <> adNew.[Status]  
		 WHERE adNew.AuditDataState = 1 AND adNew.[Status] IN (2, 3) 
	 )p  
	 INNER JOIN dbo.RefEmployee emp ON p.UserName = emp.UserName  
	 WHERE p.RN = 1  
  
  SELECT  
	 t.RefEmployeeId,  
	 SUM(CASE WHEN t.[Status] = 2 THEN 1 ELSE 0 END) cl,  
	 SUM(CASE WHEN t.[Status] = 3 THEN 1 ELSE 0 END) re
 INTO #alertRelatedData 
 FROM #tempDataDpAndExchange t  
 GROUP BY RefEmployeeId  
  
 SELECT  
	 emp.[Name] AS  Employee,  
	 fd.cl AS Closed,  
	 fd.re AS Reported
 FROM #alertRelatedData fd  
 INNER JOIN dbo.RefEmployee emp ON emp.RefEmployeeId = fd.RefEmployeeId 
END  
GO
--WEB-77862-RC END
