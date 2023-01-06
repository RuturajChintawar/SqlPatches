--WEB-69717-RC START
GO
CREATE PROCEDURE dbo.RefAmlReport_GetScenarioListForTradingAlertRegister
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
	 WHERE alertregistercase.[Name] IN ('AML','Surveillance','AMLCOM')

 END  
GO
--WEB-69717-RC END