--File:Tables:dbo:SecPermission:DML
--WEB-77859-START-RC
GO
EXEC dbo.SecPermission_Insert @Name='P111631_R693', @Description='AML', @Code='P111631'
GO
--WEB-77859-END-RC

--File:Tables:dbo:RefReport:DML
--WEB-77859-START-RC
GO
EXEC dbo.RefReport_Insert @Code='R693',
						  @Name='Alert status statistics report day wise',
						  @ReportType = 'SP',
						  @URL = NULL,
						  @StoredProcedureName='dbo.GetAlertStatusStatisticsReportDayWise_R693',
						  @Permission='P111631_R693',
						  @CategoryCode='AML',
						  @SubCategoryCode='Alert/Case/STR Reports',
						  @Description='<b><u>Objective:</u></b>1.This report will provide user a consolidated output of alerts for the following alert status day wise on the basis of added on date :<br>             
										A.No of alerts generated<br>             
										B.No of alerts closed<br>              
										C.No of alerts to be reported<br>             
										D.No of alerts to reported<br>              
										E.No of Alert pending<br>              
										2. User can select maximum 31 days of time period between from and to date'

EXEC dbo.RefReport_AttachRefReportGeneratorType @ReportCode='R693',@ReportGegneratorTypeCode='1'
GO
--WEB-77859-END-RC

--File:Tables:dbo:LinkRefReportRefReportParameter:DML
--WEB-77859-START-RC
GO
EXEC dbo.LinkRefReportRefReportParameter_Insert @RefReportCode='R693',@IsColumnHide=0, @ColumnName='@FromDate', @IsRequired=1
GO
EXEC dbo.LinkRefReportRefReportParameter_Insert @RefReportCode='R693', @IsColumnHide=0 , @ColumnName='@ToDate', @IsRequired=1
GO
--WEB-77859-END-RC

--File:StoredProcedures:dbo:GetAlertStatusStatisticsReportDayWise_R693
--WEB-77859-START-RC
GO
CREATE PROCEDURE [dbo].[GetAlertStatusStatisticsReportDayWise_R693]  
 (  
	  @FromDate DATETIME,  
	  @ToDate DATETIME
 )  
   
 AS  
 BEGIN  
	 DECLARE @InternalFromDate DATETIME, @InternalToDate DATETIME,@ToDateWithoutTime DATETIME
    
	 SET @InternalFromDate = dbo.GetDateWithoutTime(@FromDate)     
	 SET @ToDateWithoutTime =  dbo.GetDateWithoutTime(@ToDate)
     SET @InternalToDate = DATEADD(DAY, 1,  @ToDateWithoutTime)

	 IF (DATEDIFF(DAY, @InternalFromDate, @InternalToDate)>31)    
	 BEGIN    
	  RAISERROR ('Please select the period for maximum 31 days',11,1) WITH SETERROR;    
	  RETURN 50010;    
	 END    
   
	 IF (DATEDIFF(DAY, @InternalFromDate, @InternalToDate)<0)    
	 BEGIN    
	  RAISERROR ('To Date should be greater than From Date',11,1) WITH SETERROR;    
	  RETURN 50010;    
	 END    
  
	SELECT
		alert.CoreAmlScenarioAlertId,
		dbo.GetDateWithoutTime(alert.AddedOn) AS AddedOn
	INTO #tempAlertInfo
	FROM dbo.CoreAmlScenarioAlert alert
	WHERE  alert.AddedOn >= @InternalFromDate AND alert.AddedOn < @InternalToDate

	SELECT 
		t.CoreAmlScenarioAlertId,
		t.[Status],
		t.AddedOn
	INTO #tempAuditStatusInfo
	FROM
		(SELECT
			temp.CoreAmlScenarioAlertId,
			aud.[Status],
			temp.AddedOn,
			ROW_NUMBER() OVER(PARTITION BY temp.CoreAmlScenarioAlertId ORDER BY aud.AuditDateTime DESC) AS RN
		FROM #tempAlertInfo temp
		LEFT JOIN dbo.CoreAmlScenarioAlert_Audit aud ON aud.CoreAmlScenarioAlertId  = temp.CoreAmlScenarioAlertId 
		AND aud.[Status] IN (2,3,4) 
		AND aud.AuditDataState = 'New' 
		AND aud.AuditDMLAction = 'Update' 
		AND dbo.GetDateWithoutTime(aud.AuditDateTime) = temp.AddedOn
		) t
	WHERE t.RN = 1

	;WITH dateData AS
	(
	  SELECT DATEADD(DAY, n, DATEADD(DAY, DATEDIFF(DAY, 0, @InternalFromDate), 0)) as DateInRange
		FROM ( SELECT TOP (DATEDIFF(DAY, @InternalFromDate, @ToDateWithoutTime) + 1)
				n = ROW_NUMBER() OVER (ORDER BY [object_id]) - 1
			   FROM sys.all_objects ) AS n
	)

	SELECT
		CONVERT(VARCHAR,temp.DateInRange,103) AS [Date],
		ISNULL(t.alerts, 0) AS [No of new alerts in generated],
		ISNULL(t.closed, 0) AS [No of alerts closed],
		ISNULL(t.tobereported, 0) AS [No of alerts to be reported],
		ISNULL(t.reported, 0) AS [No of Alerts reported],
		ISNULL((t.alerts - (t.closed + t.reported + t.tobereported)), 0) AS [No of Alerts Pending]
	FROM dateData temp
	LEFT JOIN
		(SELECT
			aud.AddedOn,
			COUNT(aud.CoreAmlScenarioAlertId) alerts,
			SUM(CASE WHEN ISNULL(aud.[Status],0) = 2 THEN 1 ELSE 0 END) closed,
			SUM(CASE WHEN ISNULL(aud.[Status],0) = 3 THEN 1 ELSE 0 END) reported,
			SUM(CASE WHEN ISNULL(aud.[Status],0) = 4 THEN 1 ELSE 0 END) tobereported
		FROM #tempAuditStatusInfo aud 
		GROUP BY aud.AddedOn) t ON t.AddedOn = temp.DateInRange
	

END  
GO
--WEB-77859-END-RC

--File:Tables:dbo:RefReportColumn:DML
--WEB-77859-START-RC
GO
EXEC dbo.RefReportColumn_Insert @Code='R693',@ReportColumnName='Date',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R693',@ReportColumnName='No of new alerts in generated',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R693',@ReportColumnName='No of alerts closed',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R693',@ReportColumnName='No of alerts to be reported',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R693',@ReportColumnName='No of Alerts reported',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R693',@ReportColumnName='No of Alerts Pending',@ColumnDataType='varchar'
GO
--WEB-77859-END-RC