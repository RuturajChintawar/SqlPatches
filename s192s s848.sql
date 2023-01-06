--File:Tables:dbo:RefAmlReport:DML
--WEB-78787-BP-START
GO
DECLARE @RefAlertRegisterCaseTypeId INT, @FrequencyFlagRefEnumValueId INT, @RefAmlReportId INT

SELECT @RefAlertRegisterCaseTypeId = RefAlertRegisterCaseTypeId FROM dbo.RefAlertRegisterCaseType WHERE [Name] = 'AML'
SELECT @FrequencyFlagRefEnumValueId = dbo.GetEnumValueId('PeriodFrequency', 'Daily')



SET IDENTITY_INSERT dbo.RefAmlReport ON
INSERT INTO dbo.RefAmlReport (
	RefAmlReportId,
	[Name],
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn,
	RuleWritingEnabled,
	Code,
	RefAlertRegisterCaseTypeId,
	IsRuleRequired, 
	ClassName,
	IsLicensed,
	FrequencyFlagRefEnumValueId,
	ScenarioNo,
	[Description],
	Threshold1DisplayName,
	Threshold2DisplayName
) VALUES (
	1281,
	'S192 Unexecuted Order Based Surveillance',
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	1,
	'S192',
	@RefAlertRegisterCaseTypeId,
	1, 
	'S192UnexecutedOrderBasedSurveillance',
	1,
	@FrequencyFlagRefEnumValueId,
	192,
	'Objective : To identify clients who modified/cancelled orders more than X times and no order was executed in market
	<br> To identify clients whose order value is more than X amount',
	'No. of Modification orders',
	'Order value'
)
GO
--WEB-78787-BP-END

--File:Tables:dbo:RefProcess:DML
--WEB-78787-BP-START
GO
DECLARE	 @EnumValueId INT, @RefAmlReportId INT


SELECT @EnumValueId = dbo.GetEnumValueId('ProcessType','Simple')
SELECT @RefAmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S192 Unexecuted Order Based Surveillance'

INSERT INTO dbo.RefProcess (
	[Name],
	ClassName,
	AssemblyName,
	IsActive,
	IsScheduleEditable,
	AddedBy,
	AddedOn,
	EditedOn,
	LastEditedBy,
	RefAmlReportId,
	ProcessTypeRefEnumValueId,
	IsCompanyWise,
	Code,
	EnableRunDateSelection,
	DisplayName,
	LockingGroupId
) VALUES (
	'S192 Unexecuted Order Based Surveillance',
	'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S192UnexecutedOrderBasedSurveillance',
	'TSS.SmallOfficeWeb.ManageData',
	1,
	1,
	'System',
	GETDATE(),
	GETDATE(),
	'System',
	@RefAmlReportId,
	@EnumValueId,
	0,
	'S192',
	1,
	'S192 Unexecuted Order Based Surveillance',
	1000
)
GO
--WEB-78787-BP-END

--File:Tables:dbo:SysAmlReportSetting:DML
--WEB-78787 BP START
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S192 Unexecuted Order Based Surveillance'
INSERT INTO dbo.SysAmlReportSetting (
	RefAmlReportId,
	[Name],
	[Value],
	RefAmlQueryProfileId,
	DisplayName,
	DisplayOrder,
	AddedOn,
	AddedBy,
	EditedOn,
	LastEditedBy
) VALUES (
	@AmlReportId,
	'Exclude_Pro',
	'False',
	1,
	'Exclude Pro',
	1,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
),(
	@AmlReportId,
	'Exclude_Institution',
	'False',
	1,
	'Exclude Inst',
	2,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
),(
	@AmlReportId,
	'Exclude_AlgoTrade',
	'False',
	1,
	'Exclude Algo',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
--WEB-78787 BP END


--File:StoredProcedures:dbo:AML_GetUnexecutedOrderBasedSurveillance
--WEB-78787 BP START
GO
CREATE PROCEDURE [dbo].AML_GetUnexecutedOrderBasedSurveillance
(
    @RunDate DATETIME,
	@ReportId INT
)
AS
BEGIN


    DECLARE @RefAmlReportId INT, @RunDateInternal DATETIME, @ExcludePro BIT, @ExcludeInstitution BIT, 
			@ExcludeOppositePro BIT, @ExcludeOppositeInstitution BIT,@ExcludealgoTrade BIT,@ProRefClientStatusId INT,
			@InstitutionRefClientStatusId INT, @InstrumentRefEntityTypeId INT, 
			@EntityAttributeTypeRefEnumValueId INT ,@BSE_CASHId INT,@NSE_CASHId INT
	
	SET @RefAmlReportId = @ReportId
    
	SET @RunDateInternal = @RunDate
	
    
	SELECT @BSE_CASHId = dbo.GetSegmentId('BSE_CASH')
	
	SELECT @NSE_CASHId = dbo.GetSegmentId('NSE_CASH')

    SELECT @ExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportId AND [Name] = 'Exclude_Pro'

    SELECT @ExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportId AND [Name] = 'Exclude_Institution'


    SELECT @ExcludealgoTrade = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportId AND [Name] = 'Exclude_AlgoTrade'


    SET @InstitutionRefClientStatusId = dbo.GetClientStatusId('Institution')
    
	SET @ProRefClientStatusId = dbo.GetClientStatusId('Pro')

	
	SELECT DISTINCT  
        RefClientId  
    INTO #clientsToExclude  
    FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex  
    WHERE (ex.RefAmlReportId = @RefAmlReportId OR ex.ExcludeAllScenarios = 1)  
        AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)  


		SELECT	l.RefClientId,
				l.RefSegmentId,
				l.BuySell,
				l.OrderDate,
				l.Qty,
				l.Rate,
				l.Rate * l.Qty AS TurnOver,
				l.OrderId,
				l.CtclId,
				l.RefInstrumentId,
				cl.RefClientStatusId,
				l.AUD
		INTO #filteredOrders
		FROM dbo.CoreOrderLog l
		INNER JOIN dbo.RefClient cl ON cl.RefClientId =l.RefClientId  
		LEFT JOIN #clientsToExclude excl ON excl.RefClientId = l.RefClientId
		WHERE l.RefSegmentId IN (@BSE_CASHId,@NSE_CASHId) AND l.OrderDate=@RunDateInternal AND excl.RefClientId IS NULL AND
		( 
			(@ExcludePro = 0 OR cl.RefClientStatusId <> @ProRefClientStatusId)    
			AND 
			(@ExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstitutionRefClientStatusId) 
			AND 
			( @ExcludealgoTrade = 0 OR (@ExcludealgoTrade = 1 
				AND ( LEN(CONVERT(VARCHAR, l.CtclId)) <> 15     
				OR SUBSTRING(CONVERT(VARCHAR, l.CtclId), 13, 1) NOT IN ('0','2','4')))
			)
		)

		
		SELECT DISTINCT
				final.RefInstrumentId,
				final.RefSegmentId,
				ins.Isin,
				ins.GroupName
		INTO #instruments
		FROM #filteredOrders final
		INNER JOIN dbo.RefInstrument ins ON ins.RefInstrumentId = final.RefInstrumentId
										AND ins.RefSegmentId = final.RefSegmentId

SELECT DISTINCT    
  ids.Isin,    
  CASE WHEN inst.GroupName IS NOT NULL    
  THEN inst.GroupName    
  ELSE 'B' END AS GroupName,  
  inst.Code  
 INTO #allNseGroupData    
 FROM #instruments ids    
 LEFT JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @BSE_CASHId    
  AND ids.Isin = inst.Isin  AND inst.[Status]='A'   
 WHERE ids.RefSegmentId = @NSE_CASHId    
  
  
 SELECT Isin, COUNT(1) AS rcount  
 INTO #multipleGroups  
 FROM #allNseGroupData  
 GROUP BY Isin  
 HAVING COUNT(1) > 1  
  
 SELECT t.Isin, t.GroupName   
 INTO #nseGroupData  
 FROM   
 (  
  SELECT	grp.Isin, 
			grp.GroupName   
  FROM #allNseGroupData grp  
  WHERE NOT EXISTS  
  (  
   SELECT 1 FROM #multipleGroups mg   
   WHERE mg.Isin = grp.Isin  
  )  
  
  UNION  
  
  SELECT	mg.Isin, 
			grp.GroupName  
  FROM #multipleGroups mg  
  INNER JOIN #allNseGroupData grp ON grp.Isin=mg.Isin AND grp.Code like '5%'  
 )t  
  
 DROP TABLE #multipleGroups  
 DROP TABLE #allNseGroupData 
		
		
		SELECT DISTINCT 
				fo.OrderId,
				fo.RefSegmentId,
				fo.RefInstrumentId
		INTO #executedOrderIds
		FROM 
		( SELECT DISTINCT 
				OrderId,
				RefSegmentId,
				RefInstrumentId
		FROM #filteredOrders) fo
		INNER JOIN dbo.CoreTrade trade ON trade.OrderId = fo.OrderId AND trade.TradeDate = @RunDateInternal
										 AND trade.RefSegmentId=fo.RefSegmentId

		SELECT fo.RefClientId,
				fo.RefSegmentId,
				fo.RefInstrumentId,
				SUM(CASE WHEN trade.OrderId IS NULL AND (AUD = 'U' OR AUD ='D')   THEN 1 ELSE 0 END) ModifiedOrders,
				COUNT(1) TotalOrders,
				SUM(CASE WHEN trade.OrderId IS NULL THEN fo.TurnOver ELSE 0 END) TotalUnexecutedOrderValue
				--SUM(fo.TurnOver) TotalUnexecutedOrderValue
		INTO #totalOrderDetails
		FROM #filteredOrders fo
		LEFT JOIN #executedOrderIds trade ON trade.OrderId = fo.OrderId 
										 AND trade.RefSegmentId = fo.RefSegmentId
										 AND trade.RefInstrumentId=fo.RefInstrumentId
		GROUP BY fo.RefClientId,fo.RefSegmentId,fo.RefInstrumentId


		SELECT cl.RefClientId,
				cl.ClientId,
				cl.[Name] ClientName,
				instr.RefInstrumentId,
				instr.Code ScripCode,
				instr.[Name] As ScripName,
				forder.TotalOrders TotalNoOfOrd,
				forder.ModifiedOrders TotalNoOfModifyOrd,
				forder.TotalUnexecutedOrderValue AS UnexecutedOrderValue,
				scgrp.RefScripGroupId,
				cl.RefClientStatusId,
				forder.RefSegmentId,
				seg.Segment
		INTO #finalOrders
		FROM #totalOrderDetails forder
		INNER JOIN dbo.RefClient cl ON cl.RefClientId = forder.RefClientId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = forder.RefSegmentId
		INNER JOIN dbo.RefInstrument instr ON instr.RefInstrumentId = forder.RefInstrumentId
		LEFT JOIN #nseGroupData grp ON grp.Isin = instr.Isin AND forder.RefSegmentId = @NSE_CASHId 
		INNER JOIN dbo.RefScripGroup scgrp ON (scgrp.[Name] = instr.GroupName AND forder.RefSegmentId = @BSE_CASHId)
		OR (forder.RefSegmentId = @NSE_CASHId AND scgrp.[Name] = grp.GroupName)

		
    SELECT  linkScripGroup.RefScripGroupId ,
			linkStatus.RefClientStatusId,
			CONVERT(INT,scenarioRule.Threshold) AS Threshold,
			CONVERT (DECIMAL(28,3),scenarioRule.Threshold2) AS Threshold2
    INTO #scenarioRules
    FROM dbo.RefAmlScenarioRule scenarioRule
    INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup linkScripGroup ON  
					scenarioRule.RefAmlScenarioRuleId = linkScripGroup.RefAmlScenarioRuleId 
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus linkStatus ON 
					linkStatus.RefAmlScenarioRuleId=scenarioRule.RefAmlScenarioRuleId
    WHERE scenarioRule.RefAmlReportId = @RefAmlReportId

		SELECT fo.*
		FROM #finalOrders fo
		INNER JOIN #scenarioRules rules ON rules.RefClientStatusId = fo.RefClientStatusId 
				AND rules.RefScripGroupId = fo.RefScripGroupId
				AND rules.Threshold <= fo.TotalNoOfModifyOrd 
				AND rules.Threshold2 <= fo.UnexecutedOrderValue
		

END
GO
--WEB-78787 BP END

--File:StoredProcedures:dbo:AML_GetS192UnexecutedOrderBasedSurveillanceScenarioAlertsByCaseId
--WEB-78787-RC-START
GO
CREATE PROCEDURE dbo.AML_GetS192UnexecutedOrderBasedSurveillanceScenarioAlertsByCaseId     
(    
	 @CaseId INT,      
	 @ReportId INT      
)    
AS    
BEGIN    
     
  SELECT    
	c.CoreAmlScenarioAlertId,    
	c.CoreAlertRegisterCaseId,     
	c.RefClientId,     
	client.ClientId, --    
	client.[Name] AS [ClientName], --    
	c.RefAmlReportId,    
	c.RefSegmentEnumId AS SegmentId, --    
	seg.Segment,-- 
	c.ScripCode,--
	c.NetWorthDesc AS ScripName , --  
	c.MoneyInCount AS TotalNoOfOrd,--
	c.MoneyOutCount AS TotalNoOfModifyOrd,--
	c.NetMoneyIn AS UnexecutedOrderValue,--
	
	c.ReportDate,    
	c.[Status],    
	c.Comments,    
	report.[Name] AS [ReportName],    
	c.AddedBy,    
	c.AddedOn,    
	c.EditedOn,    
	c.LastEditedBy,    
	c.ClientExplanation    
  FROM dbo.CoreAmlScenarioAlert c       
  INNER JOIN dbo.RefAmlReport report ON report.RefAmlReportId = c.RefAmlReportId     
  INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId    
  INNER JOIN dbo.CoreAlertRegisterCase alert ON alert.CoreAlertRegisterCaseId = c.CoreAlertRegisterCaseId    
  INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = c.RefSegmentEnumId    
	WHERE c.CoreAlertRegisterCaseId = @CaseId AND report.RefAmlReportId = @ReportId      
    
END  
GO
--WEB-78787-RC-END

--File:StoredProcedures:dbo:CoreAmlScenarioUnexecutedOrderBasedSurveillanceAlert_Search
--WEB-78787-RC-START
GO
CREATE PROCEDURE dbo.CoreAmlScenarioUnexecutedOrderBasedSurveillanceAlert_Search     
(        
	 @ReportId INT,      
	 @RefSegmentEnumId INT = NULL,    
	 @FromDate DATETIME = NULL,      
	 @ToDate DATETIME = NULL,      
	 @AddedOnFromDate DATETIME = NULL,      
	 @AddedOnToDate DATETIME = NULL,    
	 @EditedOnFromDate DATETIME = NULL,      
	 @EditedOnToDate DATETIME = NULL,    
	 @TxnFromDate DATETIME = NULL,      
	 @TxnToDate DATETIME = NULL,      
	 @Client VARCHAR(500) = NULL,      
	 @Status INT = NULL,      
	 @Comments VARCHAR(500) = NULL,    
	 @Scrip VARCHAR(200) = NULL,    
	 @CaseId BIGINT = NULL,    
	 @PageNo INT = 1,    
	 @PageSize INT = 100    
)        
AS         
BEGIN    
    
 DECLARE @InternalScrip VARCHAR(200), @InternalPageNo INT, @InternalPageSize INT    
     
 SET @InternalScrip = @Scrip    
 SET @InternalPageNo = @PageNo    
 SET @InternalPageSize = @PageSize 
    
 CREATE TABLE #data (CoreAmlScenarioAlertId BIGINT )    
 INSERT INTO #data EXEC dbo.CoreAmlScenarioAlert_SearchCommon     
  @ReportId = @ReportId,    
  @RefSegmentEnumId = @RefSegmentEnumId,    
  @FromDate = @FromDate,    
  @ToDate = @ToDate,    
  @AddedOnFromDate = @AddedOnFromDate,    
  @AddedOnToDate = @AddedOnToDate,      
  @EditedOnFromDate = @EditedOnFromDate,      
  @EditedOnToDate = @EditedOnToDate,     
  @TxnFromDate = @TxnFromDate,      
  @TxnToDate = @TxnToDate,    
  @Client = @Client,    
  @Status = @Status,    
  @Comments = @Comments,     
  @CaseId = @CaseId    
    
    
 SELECT temp.CoreAmlScenarioAlertId, ROW_NUMBER() OVER (ORDER BY alert.AddedOn DESC) AS RowNumber INTO #filteredAlerts    
 FROM #data temp     
 INNER JOIN dbo.CoreAmlScenarioAlert alert ON temp.CoreAmlScenarioAlertId = alert.CoreAmlScenarioAlertId    
    
 SELECT t.CoreAmlScenarioAlertId INTO #alertids     
 FROM #filteredAlerts t    
 WHERE t.RowNumber    
 BETWEEN (((@InternalPageNo - 1) * @InternalPageSize) + 1) AND @InternalPageNo * @InternalPageSize    
 ORDER BY t.CoreAmlScenarioAlertId DESC    
           
    
 SELECT     
	c.CoreAmlScenarioAlertId,    
	c.CoreAlertRegisterCaseId,    
	c.RefClientId,    
	client.ClientId, --    
	client.[Name] AS ClientName, --     
	c.RefAmlReportId,    
	c.RefSegmentEnumId AS SegmentId, --    
	seg.Segment,--  
	c.ScripCode,--
	c.NetWorthDesc AS ScripName , --  
	c.MoneyInCount AS TotalNoOfOrd,--
	c.MoneyOutCount AS TotalNoOfModifyOrd,--
	c.NetMoneyIn AS UnexecutedOrderValue,--

	c.ReportDate,    
	c.AddedBy,    
	c.AddedOn,    
	c.LastEditedBy,    
	c.EditedOn,    
	c.Comments,    
	c.ClientExplanation,    
	c.[Status] ,
	c.TransactionDate
 FROM #alertids temp    
 INNER JOIN dbo.CoreAmlScenarioAlert c ON c.CoreAmlScenarioAlertId = temp.CoreAmlScenarioAlertId    
 INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId    
 INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = c.RefSegmentEnumId    
           
 SELECT COUNT(1) FROM #filteredAlerts    
END    
GO
--WEB-78787-RC-END

--848
--File:Tables:dbo:RefAmlReport:DML
--WEB-77553 SC START
GO
DECLARE @RefAlertRegisterCaseTypeId INT, @FrequencyFlagRefEnumValueId INT, @ScenarioTypeEnumId INT

SELECT @RefAlertRegisterCaseTypeId = RefAlertRegisterCaseTypeId 
FROM dbo.RefAlertRegisterCaseType 
WHERE [Name] = 'AML'

SET @FrequencyFlagRefEnumValueId = dbo.GetEnumValueId('PeriodFrequency', 'Daily')

SET IDENTITY_INSERT dbo.RefAmlReport ON
INSERT INTO dbo.RefAmlReport (
	RefAmlReportId,
	[Name],
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn,
	RuleWritingEnabled,
	Code,
	RefAlertRegisterCaseTypeId,
	IsRuleRequired, 
	ClassName,
	IsLicensed,
	FrequencyFlagRefEnumValueId,
	AmlReportTypeRefEnumValueId,
	ScenarioNo,
	Threshold1DisplayName,
	Threshold2DisplayName,
	Threshold3DisplayName,
	Threshold4DisplayName,
	Threshold5DisplayName,
	[Description]
) VALUES (
	1282,
	'S848 High value on market transactions in a specified period',
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	1,
	'S848',
	@RefAlertRegisterCaseTypeId,
	1, 
	'S848HighValueOnMarketTransactionsInASpecifiedPeriod',
	1,
	@FrequencyFlagRefEnumValueId,
	@ScenarioTypeEnumId,
	848,
	'Single on market transaction value =>',
	'No of On Market Transactions during period =>',
	'Day on market  transaction value=>',
	'No. of times for Day Txn during period =>',
	'Total  on market Txn Value during period',
	'This scenario will help us to identify the Clients doing Frequent On-Market transfers in a specified period.<br>   
	Segments: CDSL, NSDL ; Frequency = Daily ; ( Look back period X days )  
	<b>Thresholds:</b><br><br>   
	<b>Generic: Lookback period: No of days for which alert is to be generated.</b><br><br>   
	<b>Threshold grid:</b><br><br>    
	<b>1. Account segment:</b> Account segment mapped to the DP account<br>  
	<b>2.Single on market transaction value:</b> This is the amount of single value On Market Transaction done by the client in 1 particular scrip. System will generate alert If this ''X'' Txn value is greater than or equal to the set threshold.<br>  
	<b>3. No. of On Market Transactions :</b> These are the number of individual On Market Transactions as per the defined threshold of  single on market txn value for the client period.<br>  
	<b>4. On market day transaction value :</b>  This is the amount of High Value On Market Transaction done by the client in 1 day in 1 particular scrip. System will generate alert If this ''X'' Txn value is greater than or equal to the set threshold.<br>  
	<b>5. No. of Times for Day Txn:</b> These are the number of instances the client has breached the ''On market day transaction value'' in 1 days in past ''X'' period. It will generate alert if the Day Txn threshold is breached along with this No. of times threshold. <b>If the threshold is blank, then this will not be considered for alert generation.</b><br>  
	<b>6. Total On market Txn value:</b> Total Txn Value will be the sum of all On Market Transactions done by the client in 1 particular scrip, in past X days. System will generate alert If this ''X'' Txn value is greater than or equal to the set threshold.<br><br>   
	<b>Threshold Logic :</b>  System will work on below conditions if the thresholds are breaching.<br>  
	"Single on market Txn value AND No.of on Market Txns AND Lookback Period<br>  
	OR<br>  
	On market day Txn value AND No. of Times for Day Txns AND Lookback Period<br>  
	OR<br>  
	Total on market Txn value AND Lookback Period"<br><br>   
	<b>Note:</b><br>  
	1. System will generate alert if atleast one on market transaction is present on the run day.<br>  
	2. Two different alerts will be generated for CDSL & NSDL.<br>  
	3. The Alerts will be generated Including the Run Date and Look Back Period<br>  
	4. The Business Date from Transaction file will be considered for the Transaction Date<br>  
	5. System will add each of the single on market transactions, if the transaction is done in same DP, same scrip, same Debit/Credit type.
	'
)
SET IDENTITY_INSERT dbo.RefAmlReport OFF
GO
--WEB-77553 SC END
--File:Tables:dbo:RefProcess:DML
--WEB-77553 SC START
GO
DECLARE	@EnumTypeId INT, @EnumValueId INT, @RefAmlReportId INT

SELECT @EnumTypeId = RefEnumTypeId 
FROM dbo.RefEnumType 
WHERE [Name] = 'ProcessType'

SELECT @EnumValueId = RefEnumValueId 
FROM dbo.RefEnumValue 
WHERE RefEnumTypeId = @EnumTypeId AND Code = 'Simple'

SELECT @RefAmlReportId = RefAmlReportId 
FROM dbo.RefAmlReport 
WHERE [Name] = 'S848 High value on market transactions in a specified period'

INSERT INTO dbo.RefProcess (
	[Name],
	ClassName,
	AssemblyName,
	IsActive,
	IsScheduleEditable,
	AddedBy,
	AddedOn,
	EditedOn,
	LastEditedBy,
	RefAmlReportId,
	ProcessTypeRefEnumValueId,
	IsCompanyWise,
	Code,
	EnableRunDateSelection,
	DisplayName,
	LockingGroupId
) VALUES (
	'S848 High value on market transactions in a specified period',
	'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S848HighValueOnMarketTransactionsInASpecifiedPeriod',
	'TSS.SmallOfficeWeb.ManageData',
	1,
	1,
	'System',
	GETDATE(),
	GETDATE(),
	'System',
	@RefAmlReportId,
	@EnumValueId,
	0,
	'S848',
	1,
	'S848 High value on market transactions in a specified period',
	1000
)
GO
--WEB-77553 SC END
--File:Tables:dbo:SysAmlReportSetting:DML
--WEB-77553 SC START
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S848 High value on market transactions in a specified period'
INSERT INTO dbo.SysAmlReportSetting (
	RefAmlReportId,
	[Name],
	[Value],
	RefAmlQueryProfileId,
	DisplayName,
	DisplayOrder,
	AddedOn,
	AddedBy,
	EditedOn,
	LastEditedBy
) VALUES (
	@AmlReportId,
	'Number_Of_Days',
	1,
	1,
	'Lookback period',
	1,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
--WEB-77553 SC END

--File:StoredProcedures:dbo:AML_GetHighValueOnMarketTransactionsInASpecifiedPeriod
--WEB-77553 SC START
GO
CREATE PROCEDURE dbo.AML_GetHighValueOnMarketTransactionsInASpecifiedPeriod
(  
	 @RunDate DATETIME,  
	 @ReportId INT  
)    
AS    
BEGIN
	DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @NsdlId INT, @CdslId INT, 
		@ToDate DATETIME, @FromDate DATETIME, @CdslType2 INT, @CdslType3 INT, @CdslType5 INT, @CdslStatus305 INT, 
		@CdslStatus511 INT, @NsdlType904 INT, @NsdlType905 INT, @NsdlType925 INT, @NsdlType926 INT, 
		@BSEId INT, @NSEId INT, @LastBhavCopyDate DATETIME, @LookBackDays INT,
		@Threshold1Name VARCHAR(500), @Threshold2Name VARCHAR(500), @Threshold3Name VARCHAR(500),
		@Threshold4Name VARCHAR(500), @Threshold5Name VARCHAR(500)
   
	SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)    
	SET @ReportIdInternal = @ReportId    
	SELECT @LookBackDays = CONVERT(INT, [Value]) FROM dbo.SysAmlReportSetting 
		WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Days'  
	SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')    
	SET @FromDate = DATEADD(DAY, -@LookBackDays, @RunDateInternal)
 
	SELECT 
		@Threshold1Name = Threshold1DisplayName,
		@Threshold2Name = Threshold2DisplayName,
		@Threshold3Name = Threshold3DisplayName,
		@Threshold4Name = Threshold4DisplayName,
		@Threshold5Name = Threshold5DisplayName
	FROM dbo.RefAmlReport WHERE RefAmlReportId = @ReportIdInternal

	SELECT
		rules.RefAmlScenarioRuleId,
		linkCS.RefCustomerSegmentId,
		rules.Threshold,
		rules.Threshold2,
		rules.Threshold3,
		rules.Threshold4,
		rules.Threshold5
	 INTO #scenarioRules
	 FROM dbo.RefAmlScenarioRule rules
	 INNER JOIN dbo.LinkRefAmlScenarioRuleRefCustomerSegment linkCS ON rules.RefAmlScenarioRuleId = linkCS.RefAmlScenarioRuleId
	 WHERE rules.RefAmlReportId = @ReportIdInternal

	SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'CDSL'    
	SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSDL'    
	SELECT @BSEId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'BSE_CASH'    
	SELECT @NSEId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSE_CASH'    
	SELECT @CdslType2 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 2 AND [Name] = 'Transactions within DP'    
	SELECT @CdslType3 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 3 AND [Name] = 'Transactions across DPs'    
	SELECT @CdslType5 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 5 AND [Name] = 'Inter-depository'    
	SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 904 AND [Name] = 'Delivery Free of Payment (Inter DP) Instruction'    
	SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 905 AND [Name] = 'Receipt Free of Payment (Inter DP) Instruction'    
	SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
	SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)'    
	SELECT @CdslStatus305 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 305    
	SELECT @CdslStatus511 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 511  
	
	SELECT    
		RefClientId    
	INTO #clientsToExclude    
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
	WHERE (ExcludeAllScenarios = 1 OR RefAmlReportId = @ReportIdInternal)     
	 AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)

	SELECT DISTINCT  
		dp.RefClientId    
	INTO #runDateClientsCdsl    
	FROM dbo.CoreDpTransaction dp    
	LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId    
	WHERE dp.RefSegmentId = @CdslId    
	 AND dp.BusinessDate = @RunDateInternal    
	 AND clEx.RefClientId IS NULL    
	 AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))    
	  OR (dp.RefDpTransactionTypeId =  @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))    
	 AND NOT(LTRIM(ISNULL(dp.SettlementId,'')) = '' AND LTRIM(ISNULL(dp.CounterSettlementId,'')) = '')   
    
	SELECT DISTINCT    	
		dp.RefClientId    
	INTO #runDateClientsNsdl    
	FROM dbo.CoreDPTransactionChangeHistory dp    
	LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId    
	WHERE dp.RefSegmentId = @NsdlId    
	 AND dp.ExecutionDate = @RunDateInternal    
	 AND clEx.RefClientId IS NULL     
	 AND NOT (LTRIM(ISNULL(dp.SettlementNumber,'')) = '' AND (ISNULL(dp.OtherSettlementDetails, 0) = 0)) 
	 AND dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType905, @NsdlType925, @NsdlType926)    
	 AND dp.OrderStatusTo = 51    
    
	DROP TABLE #clientsToExclude    

	CREATE TABLE #tradeData (  
		TransactionId INT,  
		RefClientId INT,    
		RefSegmentId INT,    
		RefIsinId INT,    
		DC BIT,    
		Quantity BIGINT,    
		BusinessDate DATETIME,    
		RefDpTransactionTypeId INT    
	)    
    
	INSERT INTO #tradeData(TransactionId, RefClientId, RefSegmentId, RefIsinId, DC, Quantity, BusinessDate, RefDpTransactionTypeId)    
	SELECT    
		 dp.CoreDpTransactionId,  
		 dp.RefClientId,    
		 dp.RefSegmentId,    
		 dp.RefIsinId,    
		 CASE WHEN dp.BuySellFlag = 'C' OR dp.BuySellFlag = 'B' THEN 1 ELSE 0 END AS DC,    
		 dp.Quantity,    
		 dp.BusinessDate,    
		 dp.RefDpTransactionTypeId    
	FROM #runDateClientsCdsl cl    
	INNER JOIN dbo.CoreDpTransaction dp ON cl.RefClientId = dp.RefClientId    
	WHERE dp.RefSegmentId = @CdslId    
	 AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))    
	  OR (dp.RefDpTransactionTypeId =  @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))    
	 AND (dp.BusinessDate BETWEEN @FromDate AND @ToDate)    
	 AND NOT(LTRIM(ISNULL(dp.SettlementId,'')) = '' AND LTRIM(ISNULL(dp.CounterSettlementId,'')) = '') 
    
	DROP TABLE #runDateClientsCdsl    
    
	INSERT INTO #tradeData(TransactionId, RefClientId, RefSegmentId, RefIsinId, DC, Quantity, BusinessDate, RefDpTransactionTypeId)    
	SELECT     
		dp.CoreDPTransactionChangeHistoryId,  
	    dp.RefClientId,    
	    dp.RefSegmentId,    
	    dp.RefIsinId,    
	    CASE WHEN dp.RefDpTransactionTypeId IN (@NsdlType905, @NsdlType926)    
	    THEN 1     
	    WHEN dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType925)    
	    THEN 0 END AS DC,    
	    CONVERT(INT, dp.Quantity) AS Quantity,    
	    dp.ExecutionDate AS BusinessDate,    
	    dp.RefDpTransactionTypeId    
	FROM #runDateClientsNsdl cl    
    INNER JOIN dbo.CoreDPTransactionChangeHistory dp ON cl.RefClientId = dp.RefClientId    
    WHERE dp.RefSegmentId = @NsdlId    
    AND dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType905, @NsdlType925, @NsdlType926)  
    AND (dp.ExecutionDate BETWEEN @FromDate AND @ToDate)  
     AND NOT (LTRIM(ISNULL(dp.SettlementNumber,'')) = '' AND (ISNULL(dp.OtherSettlementDetails, 0) = 0))
    AND dp.OrderStatusTo = 51   
    
	DROP TABLE #runDateClientsNsdl

	SELECT DISTINCT    
		RefIsinId,    
	    BusinessDate    
	INTO #selectedIsins    
	FROM #tradeData
	
	;WITH #presentBhavIdsTemp_CTE AS
    (
		SELECT DISTINCT      
			bhav.RefIsinId,      
			bhav.[Close],    
			bhav.RefSegmentId,    
			isin.BusinessDate,    
			ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId , isin.BusinessDate ORDER BY bhav.RefSegmentId) AS RN      
		FROM #selectedIsins isin      
		INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = isin.RefIsinId     
		WHERE bhav.[Date] = isin.BusinessDate
	)
     
	SELECT     
		temp.RefIsinId,      
	    temp.[Close],    
	    temp.BusinessDate    
	INTO #presentBhavIds      
    FROM #presentBhavIdsTemp_CTE temp      
    WHERE (temp.RN = 1)    
    
	CREATE TABLE #selectedDates2 ([Date] DATETIME)  
	DECLARE @3DaysBack INT, @NoOfDatesAdded DATETIME  
  
	SET @3DaysBack = 1  
	SET @NoOfDatesAdded = 0  
  
	WHILE @NoOfDatesAdded < 3  
	BEGIN  
		DECLARE @newDate DATETIME 
		SET @newDate=DATEADD(DAY, -@3DaysBack, @FromDate)  
		IF NOT EXISTS (SELECT 1 FROM dbo.RefHoliday WHERE [Date] = @newDate)  
		BEGIN  
		 INSERT INTO #selectedDates2 VALUES (@newDate)  
		 SET @NoOfDatesAdded = @NoOfDatesAdded + 1  
		END  
		
		SET @3DaysBack = @3DaysBack + 1  
	END   
    
	SELECT @LastBhavCopyDate = MIN([Date]) FROM #selectedDates2    
    
	DROP TABLE #selectedDates2    
   
	CREATE TABLE #dates ([Date] DATETIME)  
	DECLARE @i DATETIME  
	SET @i = @LastBhavCopyDate   
  
	WHILE @i <= @ToDate  
	BEGIN  
		INSERT INTO #dates([Date]) VALUES (@i)  
		SET @i = DATEADD(DAY, 1, @i)  
	END  
  
	SELECT  	
		dt.[Date]  
	INTO #selectedDates  
	FROM #dates dt  
	LEFT JOIN dbo.RefHoliday hld ON dt.[Date] = hld.[Date]  
	WHERE hld.RefHolidayId IS NULL AND DATENAME(WEEKDAY, dt.[Date]) NOT IN ('Saturday', 'Sunday')  
	ORDER BY dt.[Date] DESC  
  
	DROP TABLE #dates
	
	SELECT DISTINCT    
		isin.RefIsinId,    
	    isin.BusinessDate    
	INTO #notPresentBhavIds    
	FROM #selectedIsins isin    
	LEFT JOIN #presentBhavIds ids ON isin.RefIsinId = ids.RefIsinId AND isin.BusinessDate = ids.BusinessDate    
	WHERE ids.RefIsinId IS NULL    
    
	DROP TABLE #selectedIsins    
     
	SELECT DISTINCT    
		ids.RefIsinId,    
	    ids.BusinessDate,    
	    inst.RefSegmentId,    
	    bhav.[Close],    
	    ROW_NUMBER() OVER (PARTITION BY ids.RefIsinId, ids.BusinessDate, inst.RefSegmentId ORDER BY bhav.[Date] DESC) AS RN    
	INTO #nonDpBhavRates    
	FROM #notPresentBhavIds ids    
	INNER JOIN dbo.RefIsin isin ON ids.RefIsinId = isin.RefIsinId    
	LEFT JOIN dbo.RefInstrument inst ON isin.[Name] = inst.Isin    
	 AND inst.RefSegmentId IN (@BSEId, @NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'    
	LEFT JOIN dbo.CoreBhavCopy bhav ON bhav.RefInstrumentId = inst.RefInstrumentId     
	 AND bhav.RefSegmentId = inst.RefSegmentId AND bhav.[Date] <= ids.BusinessDate    
	WHERE bhav.[Date] IN (SELECT TOP 4 [Date] FROM #selectedDates sD WHERE sd.[Date] <= ids.BusinessDate ORDER BY sd.[Date] DESC)    
    
	DROP TABLE #selectedDates    
	DROP TABLE #notPresentBhavIds    
	   
	SELECT DISTINCT
		RefClientId
	INTO #distinctClients
	FROM #tradeData
 
	SELECT
		t.RefClientId,
		t.RefCustomerSegmentId
	INTO #clientCSMapping
	FROM
	(
		SELECT
			cl.RefClientId,
		    linkClCs.RefCustomerSegmentId,
	        ROW_NUMBER() OVER(PARTITION BY cl.RefClientId ORDER BY linkClCs.StartDate DESC) AS RN
		FROM #distinctClients cl
		LEFT JOIN dbo.LinkRefClientRefCustomerSegment linkClCs ON cl.RefClientId = linkClCs.RefClientId
	) t WHERE t.RN = 1

	DROP TABLE #distinctClients

	;WITH #finalNonDpBhavRates_CTE AS 
	(
		SELECT DISTINCT    
			bhav1.RefIsinId,    
			bhav1.BusinessDate,    
			bhav1.[Close]    
		FROM #nonDpBhavRates bhav1    
		WHERE RN = 1 AND (bhav1.RefSegmentId = @BSEId OR NOT EXISTS (SELECT 1 FROM #nonDpBhavRates bhav2    
		 WHERE bhav1.RefIsinId = bhav2.RefIsinId AND bhav1.BusinessDate = bhav2.BusinessDate    
		  AND bhav2.RefSegmentId = @BSEId))
	)

	SELECT  
		td.*,  
	    (td.Quantity * COALESCE(pIds.[Close], nonDpRates.[Close])) AS TxnValue,  
	    COALESCE(pIds.[Close], nonDpRates.[Close]) AS Rate  
	INTO #SingleTxnData  
	FROM #tradeData td
	LEFT JOIN #presentBhavIds pIds ON td.RefIsinId = pIds.RefIsinId AND td.BusinessDate = pIds.BusinessDate  
	LEFT JOIN #finalNonDpBhavRates_CTE nonDpRates ON pIds.RefIsinId IS NULL    
	 AND td.RefIsinId = nonDpRates.RefIsinId AND td.BusinessDate = nonDpRates.BusinessDate

	DROP TABLE #presentBhavIds
	DROP TABLE #nonDpBhavRates

	SELECT  
		std.RefClientId,  
		std.RefSegmentId,  
		std.RefIsinId,  
		std.DC,  
		std.Rate,  
		std.TxnValue,  
		std.BusinessDate,
		ccsm.RefCustomerSegmentId  
	INTO #ClientsBreachingSingleValue  
	FROM #SingleTxnData std
	INNER JOIN #clientCSMapping ccsm ON std.RefClientId = ccsm.RefClientId
	INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)  
	WHERE rules.Threshold <> 0 AND std.TxnValue >= rules.Threshold

	SELECT  
		cbsv.RefClientId,  
		cbsv.RefSegmentId,  
		cbsv.RefIsinId,  
		cbsv.DC,  
		SUM(cbsv.TxnValue) AS BreachedTxnValue,  
		COUNT(1) AS SingleTxnCount,  
		cbsv.BusinessDate  
	INTO #SingleTxnBreachedOnRunDate  
	FROM #ClientsBreachingSingleValue cbsv  
	WHERE cbsv.BusinessDate = @RunDateInternal  
	GROUP BY cbsv.RefClientId, cbsv.RefSegmentId, cbsv.RefIsinId, cbsv.DC, cbsv.BusinessDate 

	SELECT     
		t1.RefClientId,    
		t1.RefSegmentId,    
		t1.RefIsinId,    
		t1.DC,    
		t1.BusinessDate,    
		SUM(t1.Quantity) AS Qty,  
		MAX(t1.Rate) AS Rate,  
		STUFF((SELECT DISTINCT ', ' + ty.[Name]     
			FROM #SingleTxnData t2    
			INNER JOIN dbo.RefDpTransactionType ty ON t2.RefDpTransactionTypeId = ty.RefDpTransactionTypeId    
			WHERE t1.RefClientId = t2.RefClientId AND t1.RefSegmentId = t2.RefSegmentId    
			 AND t1.RefIsinId = t2.RefIsinId AND t1.DC = t2.DC AND t1.BusinessDate = t2.BusinessDate    
			FOR XML PATH ('')), 1, 2, '') AS TxnTypes,  
		STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(100), t2.TransactionId) COLLATE DATABASE_DEFAULT     
			FROM #SingleTxnData t2  
			WHERE t1.RefClientId = t2.RefClientId AND t1.RefSegmentId = t2.RefSegmentId    
			 AND t1.RefIsinId = t2.RefIsinId AND t1.DC = t2.DC AND t1.BusinessDate = t2.BusinessDate    
			FOR XML PATH ('')), 1, 1, '') AS TxnIds,  
		COUNT(1) AS TxnCount,  
		SUM(t1.TxnValue) AS DayTxnValue  
	INTO #dateClientWiseData    
	FROM #SingleTxnData t1  
	GROUP BY t1.RefClientId, t1.RefSegmentId, t1.RefIsinId, t1.DC, t1.BusinessDate  
  
	SELECT  	
		dtd.*,	
		ccsm.RefCustomerSegmentId  
	INTO #ClientsBreachingDayValue  
	FROM #dateClientWiseData dtd
	INNER JOIN #clientCSMapping ccsm ON dtd.RefClientId = ccsm.RefClientId
	INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)  
	WHERE rules.Threshold3 <> 0 AND dtd.DayTxnValue >= rules.Threshold3

	SELECT  
		cbdv.RefClientId, cbdv.RefSegmentId, cbdv.RefIsinId, cbdv.DC,  
		COUNT(1) AS DayCount,  
		SUM( CASE WHEN cbdv.BusinessDate = @RunDateInternal THEN 1 ELSE 0 END ) AS IsRunDayBreached  
	INTO #DayValueCount  
	FROM #ClientsBreachingDayValue cbdv  
	GROUP BY cbdv.RefClientId, cbdv.RefSegmentId, cbdv.RefIsinId, cbdv.DC  
  
	SELECT  
		dtd.RefClientId, dtd.RefSegmentId, dtd.RefIsinId, dtd.DC,  
		SUM(dtd.DayTxnValue) AS TotalTxnValue  
	INTO #TotalTxnData  
	FROM #dateClientWiseData dtd  
	GROUP BY dtd.RefClientId, dtd.RefSegmentId, dtd.RefIsinId, dtd.DC

	SELECT  
		t1.RefClientId,  
	    t1.RefSegmentId,  
	    t1.RefIsinId,  
	    t1.DC,  
	    COUNT(1) AS TxnCount,  
	    STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(MAX),t2.TransactionId) COLLATE DATABASE_DEFAULT  
		   FROM #tradeData t2  
		   WHERE t1.RefClientId = t2.RefClientId AND t1.RefSegmentId = t2.RefSegmentId    
			AND t1.RefIsinId = t2.RefIsinId AND t1.DC = t2.DC  
		   FOR XML PATH ('')), 1, 1, '') AS TxnIds  
	INTO #countData    
	FROM #tradeData t1  
	GROUP BY t1.RefClientId, t1.RefSegmentId, t1.RefIsinId, t1.DC  
 
	CREATE TABLE #AlertsData
	(
		RefClientId INT,
		RefSegmentId INT, 
		RefIsinId INT,
		DC INT,
		ContidionBreached INT,
	)

	INSERT INTO #AlertsData
	(
		RefClientId,
		RefSegmentId,
		RefIsinId,
		DC,
		ContidionBreached
	)
	SELECT DISTINCT  
		cbsv.RefClientId, 
		cbsv.RefSegmentId, 
		cbsv.RefIsinId, 
		cbsv.DC, 
		1 AS ContidionBreached  
	FROM #SingleTxnBreachedOnRunDate stbrd  
	INNER JOIN #ClientsBreachingSingleValue cbsv ON stbrd.RefClientId = cbsv.RefClientId AND stbrd.RefIsinId = cbsv.RefIsinId AND stbrd.RefSegmentId = cbsv.RefSegmentId AND stbrd.DC = cbsv.DC  
	INNER JOIN #countData cd ON cd.RefClientId = cbsv.RefClientId AND cd.RefIsinId = cbsv.RefIsinId 
		AND cbsv.RefSegmentId = cd.RefSegmentId AND cd.DC = cbsv.DC
    INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(cbsv.RefCustomerSegmentId,-1)  
    WHERE rules.Threshold2 <> 0 AND cd.TxnCount >= rules.Threshold2

	DROP TABLE #ClientsBreachingSingleValue
	DROP TABLE #countData

	INSERT INTO #AlertsData
	(
		RefClientId,
		RefSegmentId,
		RefIsinId,
		DC,
		ContidionBreached
	)
	SELECT DISTINCT  
		cbdv.RefClientId, 
		cbdv.RefSegmentId, 
		cbdv.RefIsinId, 
		cbdv.DC, 
		2 AS ContidionBreached  
	FROM #ClientsBreachingDayValue cbdv  
	INNER JOIN #DayValueCount dvc ON dvc.RefClientId = cbdv.RefClientId 
	AND dvc.RefIsinId = cbdv.RefIsinId AND dvc.RefSegmentId = cbdv.RefSegmentId AND dvc.DC = cbdv.DC AND dvc.IsRunDayBreached<>0
	INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(cbdv.RefCustomerSegmentId,-1)
	LEFT JOIN #AlertsData ad ON ad.RefClientId = cbdv.RefClientId AND ad.RefSegmentId = cbdv.RefSegmentId
		AND ad.RefIsinId = cbdv.RefIsinId AND ad.DC = cbdv.DC
    WHERE ad.RefClientId IS NULL AND rules.Threshold4<>0 AND dvc.DayCount >= rules.Threshold4

	DROP TABLE #ClientsBreachingDayValue
	DROP TABLE #DayValueCount

	INSERT INTO #AlertsData
	(
		RefClientId,
		RefSegmentId,
		RefIsinId,
		DC,
		ContidionBreached
	)
	SELECT DISTINCT  
		ttd.RefClientId, 
		ttd.RefSegmentId, 
		ttd.RefIsinId, 
		ttd.DC, 
		3 AS ContidionBreached  
    FROM #TotalTxnData ttd
	INNER JOIN #clientCSMapping ccsm ON ttd.RefClientId = ccsm.RefClientId
    INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)
    LEFT JOIN #AlertsData ad ON ad.RefClientId = ttd.RefClientId AND ad.RefSegmentId = ttd.RefSegmentId
		AND ad.RefIsinId = ttd.RefIsinId AND ad.DC = ttd.DC
    WHERE ad.RefClientId IS NULL AND rules.Threshold5 <> 0 AND ttd.TotalTxnValue >= rules.Threshold5

	;WITH #instrumentData_CTE AS
	(
		SELECT
			t.RefIsinId,
			t.Isin,
			t.[NAME],
			t.RefInstrumentId
		FROM
		( 
			SELECT    
				isin.RefIsinId,    
				isin.[Name] AS Isin,    
				CASE WHEN (ISNULL(inst.[Name], '') ='') THEN isin.[IsinShortName]     
					ELSE inst.[Name] END AS [NAME],    
				inst.RefInstrumentId,    
				ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId ORDER BY inst.RefSegmentId) AS RN    
			FROM #AlertsData ad    
			INNER JOIN dbo.RefIsin isin ON ad.RefIsinId = isin.RefIsinId    
			LEFT JOIN dbo.RefInstrument inst ON isin.[Name] = inst.Isin    
				AND inst.RefSegmentId IN (@BSEId, @NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A' 
		) t WHERE t.RN = 1
	)
		
	SELECT  
		alerts.RefClientId,  
		cl.ClientId,  
		cl.[Name] AS ClientName,  
		@FromDate AS TransactionDateFrom,  
		@RunDateInternal AS TransactionDateTo,  
		alerts.RefSegmentId,  
		seg.Segment,  
		inst.RefInstrumentId,   
		inst.[Name] AS InstrumentName,   
		inst.Isin,  
		dcwd.TxnTypes AS TxnDesc,  
		CASE WHEN alerts.DC = 1 THEN 'Cr' ELSE 'Dr' END AS DebitCredit,  
		dcwd.Qty AS Quantity,  
		dcwd.Rate,  
		ISNULL(stbrd.BreachedTxnValue,0) AS TxnValue,  
		ISNULL(stbrd.SingleTxnCount,0) AS TxnCount,  
		dcwd.TxnCount AS TxnCountOnToDate,  
		ttd.TotalTxnValue,  
		STUFF((   
			SELECT DISTINCT ' ; ' + REPLACE(CONVERT(VARCHAR,istd.BusinessDate,106),' ','-') COLLATE DATABASE_DEFAULT FROM #SingleTxnData istd  
			WHERE istd.RefClientId = alerts.RefClientId AND istd.RefIsinId = alerts.RefIsinId   
			AND istd.RefSegmentId = alerts.RefSegmentId AND istd.DC = alerts.DC  
			FOR XML PATH ('')), 1, 3, '') AS [Description],  
		STUFF((  
			SELECT DISTINCT ',' + CONVERT(VARCHAR,TransactionId) COLLATE DATABASE_DEFAULT FROM #SingleTxnData istd  
			WHERE istd.RefClientId = alerts.RefClientId AND istd.RefIsinId = alerts.RefIsinId   
			AND istd.RefSegmentId = alerts.RefSegmentId AND istd.DC = alerts.DC  
			FOR XML PATH('')),1,1,'') AS TxnIds,
  
		CASE WHEN cl.DpId IS NULL THEN '' ELSE 'IN' + CONVERT(VARCHAR(MAX),ISNULL(cl.DpId,'')) COLLATE DATABASE_DEFAULT END AS DpId,
		custSeg.[Name] AS AccountSegment,
		CASE
			WHEN alerts.ContidionBreached = 1 THEN @Threshold1Name COLLATE DATABASE_DEFAULT 
				+ ' : '+ CONVERT(VARCHAR(8000),rules.Threshold) + ', '
				+ @Threshold2Name + ' : ' + CONVERT(VARCHAR(8000),rules.Threshold2)
			WHEN alerts.ContidionBreached = 2 THEN @Threshold3Name COLLATE DATABASE_DEFAULT 
				+ ' : '+ CONVERT(VARCHAR(8000),rules.Threshold3) + ', '
				+ @Threshold4Name + ' : ' + CONVERT(VARCHAR(8000),rules.Threshold4)
			WHEN alerts.ContidionBreached = 3 THEN @Threshold5Name COLLATE DATABASE_DEFAULT 
				+ ' : '+ CONVERT(VARCHAR(8000),rules.Threshold5)
		END AS Threshold
	FROM #AlertsData alerts  
	INNER JOIN #TotalTxnData ttd ON ttd.RefClientId = alerts.RefClientId 
		AND ttd.RefIsinId = alerts.RefIsinId AND ttd.RefSegmentId = alerts.RefSegmentId AND ttd.DC = alerts.DC  
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = alerts.RefClientId  
	INNER JOIN #instrumentData_CTE inst ON alerts.RefIsinId = inst.RefIsinId  
	INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = alerts.RefSegmentId  
	INNER JOIN #dateClientWiseData dcwd ON dcwd.RefClientId = alerts.RefClientId 
		AND dcwd.RefIsinId = alerts.RefIsinId AND dcwd.RefSegmentId = alerts.RefSegmentId 
		AND dcwd.DC = alerts.DC AND dcwd.BusinessDate = @RunDateInternal
	INNER JOIN #clientCSMapping ccsm ON ccsm.RefClientId = alerts.RefClientId
	INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)
	LEFT JOIN dbo.RefCustomerSegment custSeg ON custSeg.RefCustomerSegmentId = ccsm.RefCustomerSegmentId
	LEFT JOIN #SingleTxnBreachedOnRunDate stbrd ON stbrd.RefClientId = alerts.RefClientId AND stbrd.RefIsinId = alerts.RefIsinId 
		AND stbrd.RefSegmentId = alerts.RefSegmentId AND stbrd.DC = alerts.DC AND stbrd.BusinessDate = @RunDateInternal

END
GO
--WEB-77553 SC END

--File:StoredProcedures:dbo:AML_GetS848HighValueOnMarketTransactionsInASpecifiedPeriodScenarioAlertByCaseId
--WEB-77553-RC-START
GO
CREATE PROCEDURE dbo.AML_GetS848HighValueOnMarketTransactionsInASpecifiedPeriodScenarioAlertByCaseId  
(  
	 @CaseId INT,    
	 @ReportId INT    
)  
AS  
BEGIN  
   
  SELECT  
	  c.CoreAmlScenarioAlertId,  
	  c.CoreAlertRegisterCaseId,   
	  c.RefClientId,   
	  client.ClientId, --  
	  client.[Name] AS [ClientName], -- 
	  ISNULL('IN'+CONVERT(VARCHAR(MAX),client.DpId),'') COLLATE DATABASE_DEFAULT AS DpId,
	  c.RefAmlReportId,  
	  c.TransactionFromDate AS TransactionDateFrom, --  
	  c.TransactionToDate AS TransactionDateTo, --  
	  c.Symbol AS Segment, --  
	  c.InstrumentNo AS InstrumentName, --  
	  c.ISINName AS Isin, --  
	  c.TransactionType AS TxnDesc, --  
	  c.DebitCredit, --  
	  c.Quantity, --  
	  c.Amount AS Rate, --  
	  c.TotalMoneyInTransaction AS TransactionValue, --  
	  c.TxnCount AS TransactionCount, --  
	  c.MoneyOut AS TotalTxnValue,  
	  c.[Description], --  
	  ISNULL(seg.[Name],'') AS [AccountSegment], --
	  c.BuyTerminal AS [Threshold],
	  c.ReportDate,  
	  c.[Status],  
	  c.Comments,  
	  report.[Name] AS [ReportName],  
	  c.AddedBy,  
	  c.AddedOn,  
	  c.EditedOn,  
	  c.LastEditedBy,  
	  c.ClientExplanation,
	  ROW_NUMBER() OVER (PARTITION BY c.CoreAmlScenarioAlertId,client.RefClientId ORDER BY cusseg.StartDate DESC) AS rn
  INTO #TempData
  FROM dbo.CoreAmlScenarioAlert c     
  INNER JOIN dbo.RefAmlReport report ON report.RefAmlReportId = c.RefAmlReportId   
  INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId  
  INNER JOIN dbo.CoreAlertRegisterCase alert ON alert.CoreAlertRegisterCaseId = c.CoreAlertRegisterCaseId  
  INNER JOIN dbo.RefSegmentEnum enum ON enum.RefSegmentEnumId = c.RefSegmentEnumId
  LEFT JOIN dbo.LinkRefClientRefCustomerSegment cusseg ON client.RefClientId = cusseg.RefClientId
  LEFT JOIN dbo.RefCustomerSegment seg ON cusseg.RefCustomerSegmentId = seg.RefCustomerSegmentId
  WHERE c.CoreAlertRegisterCaseId = @CaseId AND report.RefAmlReportId = @ReportId
  
  SELECT
	tdata.*
  FROM #TempData tdata WHERE rn = 1
  
END  
GO
--WEB-77553-RC-END

--File:StoredProcedures:dbo:CoreAmlScenarioHighValueOnMarketTransactionsInASpecifiedPeriodAlert_Search
--WEB-77553-RC-START
GO
CREATE PROCEDURE dbo.CoreAmlScenarioHighValueOnMarketTransactionsInASpecifiedPeriodAlert_Search     
(        
  @ReportId INT,    
  @RefSegmentEnumId INT = NULL,    
  @FromDate DATETIME = NULL,      
  @ToDate DATETIME = NULL,      
  @AddedOnFromDate DATETIME = NULL,      
  @AddedOnToDate DATETIME = NULL,    
  @EditedOnFromDate DATETIME = NULL,      
  @EditedOnToDate DATETIME = NULL,    
  @TxnFromDate DATETIME = NULL,      
  @TxnToDate DATETIME = NULL,      
  @Client VARCHAR(500) = NULL,      
  @Status INT = NULL,      
  @Comments VARCHAR(500) = NULL,    
  @Scrip VARCHAR(200) = NULL,    
  @CaseId BIGINT = NULL,    
  @PageNo INT = 1,    
  @PageSize INT = 100    
)        
AS         
BEGIN    
    
 DECLARE @InternalScrip VARCHAR(200), @InternalPageNo INT, @InternalPageSize INT    
     
 SET @InternalScrip = @Scrip    
 SET @InternalPageNo = @PageNo    
 SET @InternalPageSize = @PageSize    
    
 CREATE TABLE #data (CoreAmlScenarioAlertId BIGINT )    
 INSERT INTO #data EXEC dbo.CoreAmlScenarioAlert_SearchCommon     
   @ReportId = @ReportId,    
   @RefSegmentEnumId = @RefSegmentEnumId,    
   @FromDate = @FromDate,    
   @ToDate = @ToDate,    
   @AddedOnFromDate = @AddedOnFromDate,    
   @AddedOnToDate = @AddedOnToDate,      
   @EditedOnFromDate = @EditedOnFromDate,      
   @EditedOnToDate = @EditedOnToDate,     
   @TxnFromDate = @TxnFromDate,      
   @TxnToDate = @TxnToDate,    
   @Client = @Client,    
   @Status = @Status,    
   @Comments = @Comments,    
   @CaseId = @CaseId    
    
    
  SELECT temp.CoreAmlScenarioAlertId,ROW_NUMBER() OVER (ORDER BY alert.AddedOn DESC) AS RowNumber INTO #filteredAlerts    
  FROM #data temp     
  INNER JOIN dbo.CoreAmlScenarioAlert alert ON temp.CoreAmlScenarioAlertId = alert.CoreAmlScenarioAlertId    
    
  SELECT t.CoreAmlScenarioAlertId INTO #alertids     
  FROM #filteredAlerts t    
  WHERE t.RowNumber    
  BETWEEN (((@InternalPageNo - 1) * @InternalPageSize) + 1) AND @InternalPageNo * @InternalPageSize    
  ORDER BY t.CoreAmlScenarioAlertId DESC    
           
    
 SELECT     
   c.CoreAmlScenarioAlertId,    
   c.CoreAlertRegisterCaseId,    
   c.RefClientId,    
   client.ClientId,    
   client.[Name] AS ClientName,    
   ISNULL('IN'+CONVERT(VARCHAR(MAX),client.DpId),'') COLLATE DATABASE_DEFAULT AS DpId,  
   c.RefAmlReportId,    
   c.TransactionFromDate,    
   c.TransactionToDate,    
   c.Symbol,    
   c.InstrumentNo,    
   c.ISINName,    
   c.TransactionType,    
   c.DebitCredit,    
   c.Quantity,    
   c.Amount,    
   c.TotalMoneyInTransaction,    
   c.TxnCount,    
   c.MoneyOut AS TotalTxnValue,    
   c.[Description],    
   ISNULL(seg.[Name],'') AS [AccountSegment], --  
   c.BuyTerminal AS [Threshold],  
   c.ReportDate,    
   c.AddedBy,    
   c.AddedOn,    
   c.LastEditedBy,    
   c.EditedOn,    
   c.Comments,    
   c.ClientExplanation,    
   c.[Status],  
   ROW_NUMBER() OVER (PARTITION BY c.CoreAmlScenarioAlertId,client.RefClientId ORDER BY cusseg.StartDate DESC) AS rn  
 INTO #TempData  
 FROM #alertids temp    
 INNER JOIN dbo.CoreAmlScenarioAlert c ON c.CoreAmlScenarioAlertId = temp.CoreAmlScenarioAlertId    
 INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId    
 INNER JOIN dbo.RefSegmentEnum enum ON enum.RefSegmentEnumId = c.RefSegmentEnumId  
 LEFT JOIN dbo.LinkRefClientRefCustomerSegment cusseg ON client.RefClientId = cusseg.RefClientId  
 LEFT JOIN dbo.RefCustomerSegment seg ON cusseg.RefCustomerSegmentId = seg.RefCustomerSegmentId  
  
 SELECT  
 tdata.*  
 FROM #TempData tdata   
 WHERE tdata.rn = 1  
  
 SELECT COUNT(1) FROM #filteredAlerts  
           
END    
GO
--WEB-77553-RC-END

--File:StoredProcedures:dbo:AML_GetS848HighValueOnMarketTransactionsInASpecifiedPeriodTxnDetails
--WEB-77553-RC-START
GO
CREATE PROCEDURE dbo.AML_GetS848HighValueOnMarketTransactionsInASpecifiedPeriodTxnDetails
(
	@AlertId BIGINT
)
AS
BEGIN
	DECLARE @AlertIdInternal BIGINT, @SegmentId INT, @CdslId INT, @NsdlId INT
			,@CdslDbId INT, @TradingDBId INT, @NSDLDbId INT,@NsdlType905 INT, @NsdlType925 INT, @NsdlType926 INT

	SET @AlertIdInternal = @AlertId

	SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'CDSL'
	SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'NSDL'

	SELECT @CdslDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'
	SELECT @NSDLDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'

	SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 905 AND [Name] = 'Receipt Free of Payment (Inter DP) Instruction'
	SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
	SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)' 

	SELECT @SegmentId = RefSegmentEnumId FROM dbo.CoreAmlScenarioAlert WHERE CoreAmlScenarioAlertId = @AlertIdInternal

	SELECT
		trans.TransactionId AS TxnId
	INTO #allTxnIds
	FROM dbo.CoreAmlScenarioAlertDetail trans
	WHERE trans.CoreAmlScenarioAlertId = @AlertIdInternal  
	

	IF (SELECT TOP 1 1 FROM #allTxnIds) IS NULL
	BEGIN
		RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;
		RETURN 50010
	END



	IF @SegmentId = @CdslId
	BEGIN
		---nsdl database
		SELECT 
		CASE WHEN SUBSTRING(txn.CounterBoId,1,2) ='IN' THEN 1
			ELSE 0
		END isIN,
		SUBSTRING(txn.CounterBoId,9,8) ClientId,
		SUBSTRING(txn.CounterBoId,3,6) dpid,
		txn.CoreDpTransactionId txnId
		INTO #oppTemp
		FROM dbo.CoreDpTransaction txn
		INNER JOIN #allTxnIds ids ON ids.TxnId = txn.CoreDpTransactionId

		SELECT
			tids.TxnId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),txn.BusinessDate,106),' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,
			isin.[Description] AS ISINName,
			CASE WHEN txn.BuySellFlag = 'D' OR txn.BuySellFlag = 'S' THEN 'Debit'
				ELSE 'Credit' END AS DebitCredit,
			txn.Quantity,
			ISNULL(oppCl.ClientId, '') AS OppClientId,
			ISNULL(oppCl.[Name],'') AS OppClientName,
			txn.TransactionId,
			txn.CounterBoId AS DpID,
			'' AS OppDpId,
			seg.Segment AS SegmentName
		FROM #allTxnIds tids
		INNER JOIN dbo.CoreDpTransaction txn ON txn.CoreDpTransactionId = tids.TxnId
		INNER JOIN dbo.RefClient cl ON cl.RefClientId = txn.RefClientId
		INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = txn.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = txn.RefSegmentId
		INNER JOIN #oppTemp opp ON opp.txnId = txn.CoreDpTransactionId
		LEFT JOIN dbo.RefClient oppCl ON (oppCl.RefClientDatabaseEnumId = @CdslDbId AND oppCl.ClientId = txn.CounterBoId)
		OR  (oppCl.RefClientDatabaseEnumId = @NSDLDbId AND opp.isIN = 1 AND  oppCl.ClientId = opp.ClientId AND CONVERT(VARCHAR(100),oppCl.DpId) = opp.dpid ) 
		ORDER BY txn.BusinessDate
	END

	ELSE IF @SegmentId = @NsdlId
	BEGIN
		SELECT
			txns.TxnId,
			CASE WHEN cl.DpId IS NOT NULL
				THEN 'IN' + CONVERT(VARCHAR(100), cl.DpId) COLLATE DATABASE_DEFAULT
				ELSE '' END AS DpId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),dpTxn.ExecutionDate,106) ,' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,	
			isin.[Description] AS ISINName,
			CASE WHEN dpTxn.RefDpTransactionTypeId IN(@NsdlType905, @NsdlType926) THEN 'Credit'
				ELSE 'Debit' END AS DebitCredit,
			dpTxn.Quantity,
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode
				ELSE dpTxn.OtherDPId END, '') AS OppDpId,
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode + dpTxn.OtherClientCode
				ELSE CONVERT(VARCHAR(100), dpTxn.OtherClientId) COLLATE DATABASE_DEFAULT END, '') AS OppClientId,
			ISNULL(cl1.[Name], '') AS OppClientName,
			dpTxn.BusinessPartnerInstructionId AS TransactionId,
			seg.Segment AS SegmentName
		FROM #allTxnIds txns
		INNER JOIN dbo.CoreDPTransactionChangeHistory dpTxn ON txns.TxnId = dpTxn.CoreDPTransactionChangeHistoryId
		INNER JOIN dbo.RefClient cl ON dpTxn.RefClientId = cl.RefClientId
		INNER JOIN dbo.RefIsin isin ON dpTxn.RefIsinId = isin.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = dpTxn.RefSegmentId
		LEFT JOIN dbo.RefClient cl1 ON (dpTxn.RefDpTransactionTypeId IN (@NsdlType925 , @NsdlType926) AND cl1.RefClientDatabaseEnumId = @NSDLDbId
				AND cl1.ClientId = dpTxn.OtherClientCode AND dpTxn.OtherDPCode = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) )
			OR (cl1.RefClientDatabaseEnumId = @NSDLDbId AND dpTxn.OtherDPId = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) 
				AND dpTxn.OtherClientId = cl1.ClientId)
			OR(cl1.RefClientDatabaseEnumId = @CdslDbId AND cl1.ClientId = dpTxn.OtherDPCode + dpTxn.OtherClientCode )
		ORDER BY dpTxn.ExecutionDate
	END
END
GO
--WEB-77553-RC-END

--File:StoredProcedures:dbo:CoreAmlScenarioAlert_GetStatistics
--WEB-77553 SC START
GO
ALTER PROCEDURE dbo.CoreAmlScenarioAlert_GetStatistics  
(      
 @Type VARCHAR(50), -- either 'SystemDate' OR 'RunDate'         
 @FromDate DATETIME,          
 @ToDate DATETIME          
)      
AS          
BEGIN          
      
 CREATE TABLE #Result          
 (          
  [Date] DATETIME,          
  S1 INT,      
  S2 INT,      
  S3 INT,      
  S4 INT,      
  S5 INT,      
  S6 INT,      
  S7 INT,          
  S8 INT,          
  S9 INT,          
  S10 INT,          
  S11 INT,          
  S12 INT,          
  S13 INT,          
  S14 INT,          
  S15 INT,          
  S16 INT,          
  S17 INT,          
  S18 INT,            
  S19 INT,          
  S20 INT,          
  S21 INT,          
  S22 INT,          
  S23 INT,          
  S24 INT,          
  S25 INT,          
  S26 INT,          
  S27 INT,          
  S28 INT,          
  S29 INT,          
  S30 INT,          
  S31 INT,          
  S32 INT,          
  S33 INT,          
  S34 INT,          
  S35 INT,          
  S36 INT,          
  S37 INT,          
  S38 INT,          
  S39 INT,          
  S40 INT,          
  S41 INT,          
  S42 INT,            
  S43 INT,          
  S44 INT,          
  S45 INT,          
  S46 INT,          
  S47 INT,          
  S48 INT,      
  S50 INT,          
  S51 INT,          
  S52 INT,          
  S53 INT,          
  S54 INT,            
  S55 INT,          
  S56 INT,          
  S57 INT,          
  S58 INT,            
  S59 INT,          
  S60 INT,            
  S62 INT,          
  S63 INT,          
  S64 INT,          
  S65 INT,          
  S66 INT,          
  S72 INT,          
  S73 INT,          
  S74 INT,          
  S75 INT,          
  S76 INT,          
  S77 INT,          
  S78 INT,          
  S79 INT,          
  S80 INT,          
  S82 INT,          
  S83 INT,          
  S84 INT,          
  S85 INT,          
  S88 INT,      
  S801 INT,          
  S802 INT,          
  S803 INT,          
  S806 INT,        
  S807 INT,        
  S90 INT,        
  S92 INT,        
  S511 INT,        
  S512 INT,        
  S701 INT,        
  S702 INT,        
  S703 INT,        
  S704 INT,        
  S705 INT,        
  S707 INT,        
  S708 INT,        
  S706 INT,        
  S402 INT,        
  S86 INT,        
  S87 INT,      
  S89 INT,      
  S95 INT,      
  S49 INT,      
  S513 Int ,      
  S401 INT,      
  S501 INT,      
  S502 INT,      
  S503 INT,      
  S504 INT,      
  S505 INT,      
  S506 INT,      
  S507 INT,      
  S508 INT,      
  S509 INT,      
  S510 INT,      
  S817 INT,      
  S91 INT,      
  S96 INT,      
  S97 INT,      
  S98 INT,      
  S808 INT,      
  S809 INT,      
  S810 INT,      
  S811 INT,      
  S812 INT,      
  S514 INT,      
  S515 INT,      
  S517 INT,      
  S516 INT,      
  S99 INT,      
  S520 Int,      
  S522 INT,      
  S101 INT,      
  S804 INT,      
  S103 INT,      
  S100 INT,      
  S521 INT,      
  S519 Int,      
  S108 int,      
  S107 int,      
  S105 int,      
  S106 int,      
  S102 int,      
  S110 int,      
  S104 int,      
  S814 int,      
  S815 int,      
  S111 int,      
  S518 int,      
  S112 int,      
  S114 int,      
  S115 int,      
  S113 int,      
  S116 int,      
  S118 int,      
  S117 int,      
  S119 int,      
  S523 int,      
  S120 int,      
  S122 int,      
  S121 INT,      
  S123 INT,      
  S525 INT,      
  S524 INT,      
  S126 INT,      
  S127 INT,      
  S526 INT,      
  S129 INT,      
  S124 INT,      
  S128 INT,      
  S125 INT,      
  S144 INT,      
  S145 INT,      
  S146 INT,      
  S147 INT,      
  S148 INT,      
  S149 INT,      
  S151 INT,      
  S152 INT,      
  S153 INT,      
  S154 INT,      
  S155 INT,      
  S157 INT,      
  S156 INT,      
  S158 INT,      
  S159 INT,      
  S160 INT,      
  S171 INT,      
  S832 INT,      
  S833 INT,      
  S834 INT,      
  S172 INT,      
  S161 INT,      
  S162 INT,      
  S836 INT,      
  S835 INT,      
  S173 INT,      
  S163 INT,      
  S164 INT,      
  S174 INT,      
  S166 INT,      
  S837 INT,      
  S165 INT,      
  S838 INT,      
  S839 INT,      
  S167 INT,        S840 INT,      
  S841 INT,      
  S527 INT,      
  S175 INT,      
  S176 INT,      
  S177 INT,      
  S180 INT,      
  S181 INT,      
  S179 INT,      
  S182 INT,      
  S183 INT,    
  S178 INT,      
  S184 INT,      
  S168 INT,  
  S169 INT,  
  S143 INT,  
  S185 INT,  
  S843 INT,  
  S844 INT,  
  S842 INT,
  S170 INT,
  S845 INT,
  S186 INT,
  S846 INT,
  S187 INT,
  S188 INT,
  S189 INT,
  S847 INT,
  S190 INT,
  S191 INT,
  S848 INT,
  S192 INT
 )      
      
-- populate all dates          
 DECLARE @Counter DATETIME          
 SET @Counter = @FromDate          
 WHILE(@Counter <= @ToDate)          
 BEGIN          
  INSERT INTO #Result (Date) VALUES(@Counter)          
  SET @Counter = @Counter + 1          
 END          
      
         
      
-- count the alerts for each scenario          
 SELECT CASE WHEN @Type = 'SystemDate' THEN dbo.GetDateWithoutTime(alert.AddedOn) ELSE dbo.GetDateWithoutTime(alert.ReportDate) END AS [Date],          
 SUM(CASE WHEN report.Code = 'S1' THEN 1 ELSE 0 END) S1,          
 SUM(CASE WHEN report.Code = 'S2' THEN 1 ELSE 0 END) S2,          
 SUM(CASE WHEN report.Code = 'S3' THEN 1 ELSE 0 END) S3,          
 SUM(CASE WHEN report.Code = 'S4' THEN 1 ELSE 0 END) S4,          
 SUM(CASE WHEN report.Code = 'S5' THEN 1 ELSE 0 END) S5,          
 SUM(CASE WHEN report.Code = 'S6' THEN 1 ELSE 0 END) S6,          
 SUM(CASE WHEN report.Code = 'S7' THEN 1 ELSE 0 END) S7,          
 SUM(CASE WHEN report.Code = 'S8' THEN 1 ELSE 0 END) S8,          
 SUM(CASE WHEN report.Code = 'S9' THEN 1 ELSE 0 END) S9,          
 SUM(CASE WHEN report.Code = 'S10' THEN 1 ELSE 0 END) S10,          
 SUM(CASE WHEN report.Code = 'S11' THEN 1 ELSE 0 END) S11,          
 SUM(CASE WHEN report.Code = 'S12' THEN 1 ELSE 0 END) S12,          
 SUM(CASE WHEN report.Code = 'S13' THEN 1 ELSE 0 END) S13,          
 SUM(CASE WHEN report.Code = 'S14' THEN 1 ELSE 0 END) S14,          
 SUM(CASE WHEN report.Code = 'S15' THEN 1 ELSE 0 END) S15,          
 SUM(CASE WHEN report.Code = 'S16' THEN 1 ELSE 0 END) S16,          
 SUM(CASE WHEN report.Code = 'S17' THEN 1 ELSE 0 END) S17,          
 SUM(CASE WHEN report.Code = 'S18' THEN 1 ELSE 0 END) S18,                
 SUM(CASE WHEN report.Code = 'S19' THEN 1 ELSE 0 END) S19,          
 SUM(CASE WHEN report.Code = 'S20' THEN 1 ELSE 0 END) S20,          
 SUM(CASE WHEN report.Code = 'S21' THEN 1 ELSE 0 END) S21,          
 SUM(CASE WHEN report.Code = 'S22' THEN 1 ELSE 0 END) S22,          
 SUM(CASE WHEN report.Code = 'S23' THEN 1 ELSE 0 END) S23,          
 SUM(CASE WHEN report.Code = 'S24' THEN 1 ELSE 0 END) S24,          
 SUM(CASE WHEN report.Code = 'S25' THEN 1 ELSE 0 END) S25,          
 SUM(CASE WHEN report.Code = 'S26' THEN 1 ELSE 0 END) S26,          
 SUM(CASE WHEN report.Code = 'S27' THEN 1 ELSE 0 END) S27,          
 SUM(CASE WHEN report.Code = 'S28' THEN 1 ELSE 0 END) S28,                
 SUM(CASE WHEN report.Code = 'S29' THEN 1 ELSE 0 END) S29,            
 SUM(CASE WHEN report.Code = 'S30' THEN 1 ELSE 0 END) S30,          
 SUM(CASE WHEN report.Code = 'S31' THEN 1 ELSE 0 END) S31,                
 SUM(CASE WHEN report.Code = 'S32' THEN 1 ELSE 0 END) S32,          
 SUM(CASE WHEN report.Code = 'S33' THEN 1 ELSE 0 END) S33,          
 SUM(CASE WHEN report.Code = 'S34' THEN 1 ELSE 0 END) S34,          
 SUM(CASE WHEN report.Code = 'S35' THEN 1 ELSE 0 END) S35,          
 SUM(CASE WHEN report.Code = 'S36' THEN 1 ELSE 0 END) S36,          
 SUM(CASE WHEN report.Code = 'S37' THEN 1 ELSE 0 END) S37,                
 SUM(CASE WHEN report.Code = 'S38' THEN 1 ELSE 0 END) S38,          
 SUM(CASE WHEN report.Code = 'S39' THEN 1 ELSE 0 END) S39,          
 SUM(CASE WHEN report.Code = 'S40' THEN 1 ELSE 0 END) S40,          
 SUM(CASE WHEN report.Code = 'S41' THEN 1 ELSE 0 END) S41,          
 SUM(CASE WHEN report.Code = 'S42' THEN 1 ELSE 0 END) S42,                
 SUM(CASE WHEN report.Code = 'S43' THEN 1 ELSE 0 END) S43,          
 SUM(CASE WHEN report.Code = 'S44' THEN 1 ELSE 0 END) S44,          
 SUM(CASE WHEN report.Code = 'S45' THEN 1 ELSE 0 END) S45,          
 SUM(CASE WHEN report.Code = 'S46' THEN 1 ELSE 0 END) S46,          
 SUM(CASE WHEN report.Code = 'S47' THEN 1 ELSE 0 END) S47,          
 SUM(CASE WHEN report.Code = 'S48' THEN 1 ELSE 0 END) S48,      
 SUM(CASE WHEN report.Code = 'S50' THEN 1 ELSE 0 END) S50,                
 SUM(CASE WHEN report.Code = 'S51' THEN 1 ELSE 0 END) S51,                
 SUM(CASE WHEN report.Code = 'S52' THEN 1 ELSE 0 END) S52,                
 SUM(CASE WHEN report.Code = 'S53' THEN 1 ELSE 0 END) S53,          
 SUM(CASE WHEN report.Code = 'S54' THEN 1 ELSE 0 END) S54,                
 SUM(CASE WHEN report.Code = 'S55' THEN 1 ELSE 0 END) S55,          
 SUM(CASE WHEN report.Code = 'S56' THEN 1 ELSE 0 END) S56,          
 SUM(CASE WHEN report.Code = 'S57' THEN 1 ELSE 0 END) S57,          
 SUM(CASE WHEN report.Code = 'S58' THEN 1 ELSE 0 END) S58,                
 SUM(CASE WHEN report.Code = 'S59' THEN 1 ELSE 0 END) S59,          
 SUM(CASE WHEN report.Code = 'S60' THEN 1 ELSE 0 END) S60,                
 SUM(CASE WHEN report.Code = 'S62' THEN 1 ELSE 0 END) S62,          
 SUM(CASE WHEN report.Code = 'S63' THEN 1 ELSE 0 END) S63,                
 SUM(CASE WHEN report.Code = 'S64' THEN 1 ELSE 0 END) S64,          
 SUM(CASE WHEN report.Code = 'S65' THEN 1 ELSE 0 END) S65,                
 SUM(CASE WHEN report.Code = 'S66' THEN 1 ELSE 0 END) S66,          
 SUM(CASE WHEN report.Code = 'S72' THEN 1 ELSE 0 END) S72,          
 SUM(CASE WHEN report.Code = 'S73' THEN 1 ELSE 0 END) S73,       SUM(CASE WHEN report.Code = 'S74' THEN 1 ELSE 0 END) S74,          
 SUM(CASE WHEN report.Code = 'S75' THEN 1 ELSE 0 END) S75,          
 SUM(CASE WHEN report.Code = 'S76' THEN 1 ELSE 0 END) S76,          
 SUM(CASE WHEN report.Code = 'S77' THEN 1 ELSE 0 END) S77,          
 SUM(CASE WHEN report.Code = 'S78' THEN 1 ELSE 0 END) S78,                
 SUM(CASE WHEN report.Code = 'S79' THEN 1 ELSE 0 END) S79,                
 SUM(CASE WHEN report.Code = 'S80' THEN 1 ELSE 0 END) S80,          
 SUM(CASE WHEN report.Code = 'S82' THEN 1 ELSE 0 END) S82,          
 SUM(CASE WHEN report.Code = 'S83' THEN 1 ELSE 0 END) S83,                
 SUM(CASE WHEN report.Code = 'S84' THEN 1 ELSE 0 END) S84,                
 SUM(CASE WHEN report.Code = 'S85' THEN 1 ELSE 0 END) S85,                
 SUM(CASE WHEN report.Code = 'S88' THEN 1 ELSE 0 END) S88,      
 SUM(CASE WHEN report.Code = 'S801' THEN 1 ELSE 0 END) S801,          
 SUM(CASE WHEN report.Code = 'S802' THEN 1 ELSE 0 END) S802,          
 SUM(CASE WHEN report.Code = 'S803' THEN 1 ELSE 0 END) S803,        
 SUM(CASE WHEN report.Code = 'S806' THEN 1 ELSE 0 END) S806,        
 SUM(CASE WHEN report.Code = 'S807' THEN 1 ELSE 0 END) S807,        
 SUM(CASE WHEN report.Code = 'S90' THEN 1 ELSE 0 END) S90,        
 SUM(CASE WHEN report.Code = 'S92' THEN 1 ELSE 0 END)S92,        
 SUM(CASE WHEN report.Code = 'S511' THEN 1 ELSE 0 END) S511,          
 SUM(CASE WHEN report.Code = 'S512' THEN 1 ELSE 0 END) S512,        
 SUM(CASE WHEN report.Code = 'S701' THEN 1 ELSE 0 END) S701,          
 SUM(CASE WHEN report.Code = 'S702' THEN 1 ELSE 0 END) S702,        
 SUM(CASE WHEN report.Code = 'S703' THEN 1 ELSE 0 END) S703,        
 SUM(CASE WHEN report.Code = 'S704' THEN 1 ELSE 0 END) S704,        
 SUM(CASE WHEN report.Code = 'S705' THEN 1 ELSE 0 END) S705,        
 SUM(CASE WHEN report.Code = 'S707' THEN 1 ELSE 0 END) S707,        
 SUM(CASE WHEN report.Code = 'S708' THEN 1 ELSE 0 END) S708,        
 SUM(CASE WHEN report.Code = 'S706' THEN 1 ELSE 0 END) S706,        
 SUM(CASE WHEN report.Code = 'S402' THEN 1 ELSE 0 END) S402,        
 SUM(CASE WHEN report.Code = 'S86' THEN 1 ELSE 0 END) S86,        
 SUM(CASE WHEN report.Code = 'S87' THEN 1 ELSE 0 END) S87,      
 SUM(CASE WHEN report.Code = 'S89' THEN 1 ELSE 0 END) S89,      
 SUM(CASE WHEN report.Code = 'S95' THEN 1 ELSE 0 END) S95 ,      
 SUM(CASE WHEN report.Code = 'S49' THEN 1 ELSE 0 END) S49 ,      
 SUM(CASE WHEN report.Code = 'S513' THEN 1 ELSE 0 END) S513 ,      
 SUM(CASE WHEN report.Code = 'S401' THEN 1 ELSE 0 END) S401,      
 SUM(CASE WHEN report.Code = 'S501' THEN 1 ELSE 0 END) S501,      
 SUM(CASE WHEN report.Code = 'S502' THEN 1 ELSE 0 END) S502,      
 SUM(CASE WHEN report.Code = 'S503' THEN 1 ELSE 0 END) S503,      
 SUM(CASE WHEN report.Code = 'S504' THEN 1 ELSE 0 END) S504,      
 SUM(CASE WHEN report.Code = 'S505' THEN 1 ELSE 0 END) S505,      
 SUM(CASE WHEN report.Code = 'S506' THEN 1 ELSE 0 END) S506,      
 SUM(CASE WHEN report.Code = 'S507' THEN 1 ELSE 0 END) S507,      
 SUM(CASE WHEN report.Code = 'S508' THEN 1 ELSE 0 END) S508,      
 SUM(CASE WHEN report.Code = 'S509' THEN 1 ELSE 0 END) S509,      
 SUM(CASE WHEN report.Code = 'S510' THEN 1 ELSE 0 END) S510 ,      
 SUM(CASE WHEN report.Code = 'S817' THEN 1 ELSE 0 END) S817   ,      
 SUM(CASE WHEN report.Code = 'S91' THEN 1 ELSE 0 END) S91 ,      
 SUM(CASE WHEN report.Code = 'S96' THEN 1 ELSE 0 END) S96 ,      
 SUM(CASE WHEN report.Code = 'S97' THEN 1 ELSE 0 END) S97 ,      
 SUM(CASE WHEN report.Code = 'S98' THEN 1 ELSE 0 END) S98 ,      
 SUM(CASE WHEN report.Code = 'S808' THEN 1 ELSE 0 END) S808 ,      
  SUM(CASE WHEN report.Code = 'S809' THEN 1 ELSE 0 END) S809,      
SUM(CASE WHEN report.Code = 'S810' THEN 1 ELSE 0 END) S810 ,      
SUM(CASE WHEN report.Code = 'S811' THEN 1 ELSE 0 END) S811,      
SUM(CASE WHEN report.Code = 'S812' THEN 1 ELSE 0 END) S812,      
SUM(CASE WHEN report.Code = 'S514' THEN 1 ELSE 0 END) S514,      
 SUM(CASE WHEN report.Code = 'S515' THEN 1 ELSE 0 END) S515,      
  SUM(CASE WHEN report.Code = 'S517' THEN 1 ELSE 0 END) S517,      
  SUM(CASE WHEN report.Code = 'S516' THEN 1 ELSE 0 END) S516,      
  SUM(CASE WHEN report.Code = 'S99' THEN 1 ELSE 0 END) S99,      
  SUM(CASE WHEN report.Code = 'S520' THEN 1 ELSE 0 END) S520,      
SUM(CASE WHEN report.Code = 'S522' THEN 1 ELSE 0 END) S522,      
SUM(CASE WHEN report.Code = 'S101' THEN 1 ELSE 0 END) S101,      
SUM(CASE WHEN report.Code = 'S804' THEN 1 ELSE 0 END) S804,      
SUM(CASE WHEN report.Code = 'S103' THEN 1 ELSE 0 END) S103,      
SUM(CASE WHEN report.Code = 'S100' THEN 1 ELSE 0 END) S100,      
SUM(CASE WHEN report.Code = 'S521' THEN 1 ELSE 0 END) S521,      
SUM(CASE WHEN report.Code = 'S519' THEN 1 ELSE 0 END) S519,      
 SUM(CASE WHEN report.Code = 'S108' THEN 1 ELSE 0 END) S108,      
 SUM(CASE WHEN report.Code = 'S107' THEN 1 ELSE 0 END) S107,      
 SUM(CASE WHEN report.Code = 'S105' THEN 1 ELSE 0 END) S105,      
 SUM(CASE WHEN report.Code = 'S106' THEN 1 ELSE 0 END) S106,      
  SUM(CASE WHEN report.Code = 'S110' THEN 1 ELSE 0 END) S110,      
  SUM(CASE WHEN report.Code = 'S102' THEN 1 ELSE 0 END) S102,      
  SUM(CASE WHEN report.Code = 'S104' THEN 1 ELSE 0 END) S104,      
  SUM(CASE WHEN report.Code = 'S814' THEN 1 ELSE 0 END) S814,      
  SUM(CASE WHEN report.Code = 'S815' THEN 1 ELSE 0 END) S815,      
SUM(CASE WHEN report.Code = 'S111' THEN 1 ELSE 0 END) S111,      
SUM(CASE WHEN report.Code = 'S518' THEN 1 ELSE 0 END) S518   ,      
SUM(CASE WHEN report.Code = 'S112' THEN 1 ELSE 0 END) S112 ,      
SUM(CASE WHEN report.Code = 'S114' THEN 1 ELSE 0 END) S114   ,      
SUM(CASE WHEN report.Code = 'S115' THEN 1 ELSE 0 END) S115 ,      
SUM(CASE WHEN report.Code = 'S113' THEN 1 ELSE 0 END) S113,                
SUM(CASE WHEN report.Code = 'S116' THEN 1 ELSE 0 END) S116,      
SUM(CASE WHEN report.Code = 'S118' THEN 1 ELSE 0 END) S118,      
SUM(CASE WHEN report.Code = 'S117' THEN 1 ELSE 0 END) S117,      
SUM(CASE WHEN report.Code = 'S119' THEN 1 ELSE 0 END) S119,      
SUM(CASE WHEN report.Code = 'S523' THEN 1 ELSE 0 END) S523,      
SUM(CASE WHEN report.Code = 'S120' THEN 1 ELSE 0 END) S120,      
SUM(CASE WHEN report.Code = 'S122' THEN 1 ELSE 0 END) S122,      
SUM(CASE WHEN report.Code = 'S121' THEN 1 ELSE 0 END) S121,      
SUM(CASE WHEN report.Code = 'S123' THEN 1 ELSE 0 END) S123,      
SUM(CASE WHEN report.Code = 'S525' THEN 1 ELSE 0 END) S525,      
SUM(CASE WHEN report.Code = 'S524' THEN 1 ELSE 0 END) S524,      
SUM(CASE WHEN report.Code = 'S126' THEN 1 ELSE 0 END) S126,      
SUM(CASE WHEN report.Code = 'S127' THEN 1 ELSE 0 END) S127,      
SUM(CASE WHEN report.Code = 'S526' THEN 1 ELSE 0 END) S526,      
SUM(CASE WHEN report.Code = 'S129' THEN 1 ELSE 0 END) S129,      
         SUM(CASE WHEN report.Code = 'S124' THEN 1 ELSE 0 END) S124 ,      
         SUM(CASE WHEN report.Code = 'S128' THEN 1 ELSE 0 END) S128 ,      
         SUM(CASE WHEN report.Code = 'S125' THEN 1 ELSE 0 END) S125 ,      
         SUM(CASE WHEN report.Code = 'S144' THEN 1 ELSE 0 END) S144,      
SUM(CASE WHEN report.Code = 'S145' THEN 1 ELSE 0 END) S145,      
SUM(CASE WHEN report.Code = 'S146' THEN 1 ELSE 0 END) S146,      
SUM(CASE WHEN report.Code = 'S147' THEN 1 ELSE 0 END) S147,      
SUM(CASE WHEN report.Code = 'S148' THEN 1 ELSE 0 END) S148,      
SUM(CASE WHEN report.Code = 'S149' THEN 1 ELSE 0 END) S149,      
SUM(CASE WHEN report.Code = 'S151' THEN 1 ELSE 0 END) S151,      
SUM(CASE WHEN report.Code = 'S152' THEN 1 ELSE 0 END) S152,      
SUM(CASE WHEN report.Code = 'S153' THEN 1 ELSE 0 END) S153,      
SUM(CASE WHEN report.Code = 'S154' THEN 1 ELSE 0 END) S154,      
SUM(CASE WHEN report.Code = 'S155' THEN 1 ELSE 0 END) S155,      
SUM(CASE WHEN report.Code = 'S157' THEN 1 ELSE 0 END) S157,      
SUM(CASE WHEN report.Code = 'S156' THEN 1 ELSE 0 END) S156,      
SUM(CASE WHEN report.Code = 'S158' THEN 1 ELSE 0 END) S158,      
SUM(CASE WHEN report.Code = 'S159' THEN 1 ELSE 0 END) S159,      
SUM(CASE WHEN report.Code = 'S160' THEN 1 ELSE 0 END) S160,      
SUM(CASE WHEN report.Code = 'S171' THEN 1 ELSE 0 END) S171,      
SUM(CASE WHEN report.Code = 'S832' THEN 1 ELSE 0 END) S832,      
SUM(CASE WHEN report.Code = 'S833' THEN 1 ELSE 0 END) S833,      
SUM(CASE WHEN report.Code = 'S834' THEN 1 ELSE 0 END) S834,      
SUM(CASE WHEN report.Code = 'S172' THEN 1 ELSE 0 END) S172,      
SUM(CASE WHEN report.Code = 'S161' THEN 1 ELSE 0 END) S161,      
SUM(CASE WHEN report.Code = 'S162' THEN 1 ELSE 0 END) S162,      
SUM(CASE WHEN report.Code = 'S836' THEN 1 ELSE 0 END) S836,      
SUM(CASE WHEN report.Code = 'S835' THEN 1 ELSE 0 END) S835,      
SUM(CASE WHEN report.Code = 'S173' THEN 1 ELSE 0 END) S173,      
SUM(CASE WHEN report.Code = 'S163' THEN 1 ELSE 0 END) S163,      
SUM(CASE WHEN report.Code = 'S164' THEN 1 ELSE 0 END) S164,      
SUM(CASE WHEN report.Code = 'S174' THEN 1 ELSE 0 END) S174,      
SUM(CASE WHEN report.Code = 'S166' THEN 1 ELSE 0 END) S166,      
SUM(CASE WHEN report.Code = 'S837' THEN 1 ELSE 0 END) S837,      
SUM(CASE WHEN report.Code = 'S165' THEN 1 ELSE 0 END) S165,      
SUM(CASE WHEN report.Code = 'S838' THEN 1 ELSE 0 END) S838,      
SUM(CASE WHEN report.Code = 'S839' THEN 1 ELSE 0 END) S839,      
SUM(CASE WHEN report.Code = 'S167' THEN 1 ELSE 0 END) S167,      
SUM(CASE WHEN report.Code = 'S840' THEN 1 ELSE 0 END) S840,      
SUM(CASE WHEN report.Code = 'S841' THEN 1 ELSE 0 END) S841,      
SUM(CASE WHEN report.Code = 'S527' THEN 1 ELSE 0 END) S527,      
SUM(CASE WHEN report.Code = 'S175' THEN 1 ELSE 0 END) S175,      
SUM(CASE WHEN report.Code = 'S176' THEN 1 ELSE 0 END) S176,      
SUM(CASE WHEN report.Code = 'S177' THEN 1 ELSE 0 END) S177,      
SUM(CASE WHEN report.Code = 'S180' THEN 1 ELSE 0 END) S180,      
SUM(CASE WHEN report.Code = 'S181' THEN 1 ELSE 0 END) S181,      
SUM(CASE WHEN report.Code = 'S179' THEN 1 ELSE 0 END) S179,      
SUM(CASE WHEN report.Code = 'S182' THEN 1 ELSE 0 END) S182,      
SUM(CASE WHEN report.Code = 'S183' THEN 1 ELSE 0 END) S183,    
SUM(CASE WHEN report.Code = 'S178' THEN 1 ELSE 0 END) S178,      
SUM(CASE WHEN report.Code = 'S184' THEN 1 ELSE 0 END) S184,    
SUM(CASE WHEN report.Code = 'S168' THEN 1 ELSE 0 END) S168,    
SUM(CASE WHEN report.Code = 'S169' THEN 1 ELSE 0 END) S169,    
SUM(CASE WHEN report.Code = 'S143' THEN 1 ELSE 0 END) S143,    
SUM(CASE WHEN report.Code = 'S185' THEN 1 ELSE 0 END) S185,  
SUM(CASE WHEN report.Code = 'S843' THEN 1 ELSE 0 END) S843,  
SUM(CASE WHEN report.Code = 'S844' THEN 1 ELSE 0 END) S844,  
SUM(CASE WHEN report.Code = 'S842' THEN 1 ELSE 0 END) S842, 
SUM(CASE WHEN report.Code = 'S170' THEN 1 ELSE 0 END) S170,
SUM(CASE WHEN report.Code = 'S845' THEN 1 ELSE 0 END) S845,
SUM(CASE WHEN report.Code = 'S186' THEN 1 ELSE 0 END) S186,
SUM(CASE WHEN report.Code = 'S846' THEN 1 ELSE 0 END) S846,
SUM(CASE WHEN report.Code = 'S187' THEN 1 ELSE 0 END) S187,
SUM(CASE WHEN report.Code = 'S188' THEN 1 ELSE 0 END) S188,
SUM(CASE WHEN report.Code = 'S189' THEN 1 ELSE 0 END) S189,
SUM(CASE WHEN report.Code = 'S847' THEN 1 ELSE 0 END) S847,
SUM(CASE WHEN report.Code = 'S190' THEN 1 ELSE 0 END) S190,
SUM(CASE WHEN report.Code = 'S191' THEN 1 ELSE 0 END) S191,
SUM(CASE WHEN report.Code = 'S848' THEN 1 ELSE 0 END) S848,
SUM(CASE WHEN report.Code = 'S192' THEN 1 ELSE 0 END) S192
 INTO #Temp          
 FROM dbo.CoreAmlScenarioAlert alert          
  INNER JOIN dbo.RefAmlReport report ON report.RefAmlReportId = alert.RefAmlReportId          
 GROUP BY      
CASE WHEN @Type = 'SystemDate' THEN dbo.GetDateWithoutTime(alert.AddedOn)      
ELSE dbo.GetDateWithoutTime(alert.ReportDate) END          
      
-- update the result          
 UPDATE r          
 SET S1 = CASE WHEN t.S1 = 0 THEN NULL ELSE t.S1 END,          
  S2 = CASE WHEN t.S2 = 0 THEN NULL ELSE t.S2 END,          
  S3 = CASE WHEN t.S3 = 0 THEN NULL ELSE t.S3 END,          
  S4 = CASE WHEN t.S4 = 0 THEN NULL ELSE t.S4 END,          
  S5 = CASE WHEN t.S5 = 0 THEN NULL ELSE t.S5 END,          
  S6 = CASE WHEN t.S6 = 0 THEN NULL ELSE t.S6 END,          
  S7 = CASE WHEN t.S7 = 0 THEN NULL ELSE t.S7 END,          
  S8 = CASE WHEN t.S8 = 0 THEN NULL ELSE t.S8 END,          
  S9 = CASE WHEN t.S9 = 0 THEN NULL ELSE t.S9 END,          
  S10 = CASE WHEN t.S10 = 0 THEN NULL ELSE t.S10 END,          
  S11 = CASE WHEN t.S11 = 0 THEN NULL ELSE t.S11 END,          
  S12 = CASE WHEN t.S12 = 0 THEN NULL ELSE t.S12 END,          
  S13 = CASE WHEN t.S13 = 0 THEN NULL ELSE t.S13 END,          
  S14 = CASE WHEN t.S14 = 0 THEN NULL ELSE t.S14 END,          
  S15 = CASE WHEN t.S15 = 0 THEN NULL ELSE t.S15 END,          
  S16 = CASE WHEN t.S16 = 0 THEN NULL ELSE t.S16 END,          
  S17 = CASE WHEN t.S17 = 0 THEN NULL ELSE t.S17 END,          
  S18 = CASE WHEN t.S18 = 0 THEN NULL ELSE t.S18 END,            
  S19 = CASE WHEN t.S19 = 0 THEN NULL ELSE t.S19 END,          
  S20 = CASE WHEN t.S20 = 0 THEN NULL ELSE t.S20 END,          
  S21 = CASE WHEN t.S21 = 0 THEN NULL ELSE t.S21 END,          
  S22 = CASE WHEN t.S22 = 0 THEN NULL ELSE t.S22 END,          
  S23 = CASE WHEN t.S23 = 0 THEN NULL ELSE t.S23 END,          
  S24 = CASE WHEN t.S24 = 0 THEN NULL ELSE t.S24 END,          
  S25 = CASE WHEN t.S25 = 0 THEN NULL ELSE t.S25 END,          
  S26 = CASE WHEN t.S26 = 0 THEN NULL ELSE t.S26 END,          
  S27 = CASE WHEN t.S27 = 0 THEN NULL ELSE t.S27 END,          
  S28 = CASE WHEN t.S28 = 0 THEN NULL ELSE t.S28 END,            
  S29 = CASE WHEN t.S29 = 0 THEN NULL ELSE t.S29 END,            
  S30 = CASE WHEN t.S30 = 0 THEN NULL ELSE t.S30 END,          
  S31 = CASE WHEN t.S31 = 0 THEN NULL ELSE t.S31 END,            
  S32 = CASE WHEN t.S32 = 0 THEN NULL ELSE t.S32 END,          
  S33 = CASE WHEN t.S33 = 0 THEN NULL ELSE t.S33 END,          
  S34 = CASE WHEN t.S34 = 0 THEN NULL ELSE t.S34 END,          
  S35 = CASE WHEN t.S35 = 0 THEN NULL ELSE t.S35 END,          
  S36 = CASE WHEN t.S36 = 0 THEN NULL ELSE t.S36 END,          
  S37 = CASE WHEN t.S37 = 0 THEN NULL ELSE t.S37 END,            
  S38 = CASE WHEN t.S38 = 0 THEN NULL ELSE t.S38 END,          
  S39 = CASE WHEN t.S39 = 0 THEN NULL ELSE t.S39 END,          
  S40 = CASE WHEN t.S40 = 0 THEN NULL ELSE t.S40 END,          
  S41 = CASE WHEN t.S41 = 0 THEN NULL ELSE t.S41 END,          
  S42 = CASE WHEN t.S42 = 0 THEN NULL ELSE t.S42 END,            
  S43 = CASE WHEN t.S43 = 0 THEN NULL ELSE t.S43 END,          
  S44 = CASE WHEN t.S44 = 0 THEN NULL ELSE t.S44 END,          
  S45 = CASE WHEN t.S45 = 0 THEN NULL ELSE t.S45 END,          
  S46 = CASE WHEN t.S46 = 0 THEN NULL ELSE t.S46 END,          
  S47 = CASE WHEN t.S47 = 0 THEN NULL ELSE t.S47 END,          
  S48 = CASE WHEN t.S48 = 0 THEN NULL ELSE t.S48 END,      
  S50 = CASE WHEN t.S50 = 0 THEN NULL ELSE t.S50 END,            
  S51 = CASE WHEN t.S51 = 0 THEN NULL ELSE t.S51 END,            
  S52 = CASE WHEN t.S52 = 0 THEN NULL ELSE t.S52 END,            
  S53 = CASE WHEN t.S53 = 0 THEN NULL ELSE t.S53 END,          
  S54 = CASE WHEN t.S54 = 0 THEN NULL ELSE t.S54 END,            
  S55 = CASE WHEN t.S55 = 0 THEN NULL ELSE t.S55 END,          
  S56 = CASE WHEN t.S56 = 0 THEN NULL ELSE t.S56 END,          
  S57 = CASE WHEN t.S57 = 0 THEN NULL ELSE t.S57 END,          
  S58 = CASE WHEN t.S58 = 0 THEN NULL ELSE t.S58 END,            
  S59 = CASE WHEN t.S59 = 0 THEN NULL ELSE t.S59 END,          
  S60 = CASE WHEN t.S60 = 0 THEN NULL ELSE t.S60 END,            
  S62 = CASE WHEN t.S62 = 0 THEN NULL ELSE t.S62 END,          
  S63 = CASE WHEN t.S63 = 0 THEN NULL ELSE t.S63 END,          
  S64 = CASE WHEN t.S64 = 0 THEN NULL ELSE t.S64 END,          
  S65 = CASE WHEN t.S65 = 0 THEN NULL ELSE t.S65 END,          
  S66 = CASE WHEN t.S66 = 0 THEN NULL ELSE t.S66 END,          
  S72 = CASE WHEN t.S72 = 0 THEN NULL ELSE t.S72 END,            
  S73 = CASE WHEN t.S73 = 0 THEN NULL ELSE t.S73 END,          
  S74 = CASE WHEN t.S74 = 0 THEN NULL ELSE t.S74 END,            
  S75 = CASE WHEN t.S75 = 0 THEN NULL ELSE t.S75 END,            
  S76 = CASE WHEN t.S76 = 0 THEN NULL ELSE t.S76 END,            
  S77 = CASE WHEN t.S77 = 0 THEN NULL ELSE t.S77 END,            
  S78 = CASE WHEN t.S78 = 0 THEN NULL ELSE t.S78 END,            
  S79 = CASE WHEN t.S79 = 0 THEN NULL ELSE t.S79 END,            
  S80 = CASE WHEN t.S80 = 0 THEN NULL ELSE t.S80 END,            
  S82 = CASE WHEN t.S82 = 0 THEN NULL ELSE t.S82 END,            
  S83 = CASE WHEN t.S83 = 0 THEN NULL ELSE t.S83 END,            
  S84 = CASE WHEN t.S84 = 0 THEN NULL ELSE t.S84 END,            
  S85 = CASE WHEN t.S85 = 0 THEN NULL ELSE t.S85 END,            
  S88 = CASE WHEN t.S88 = 0 THEN NULL ELSE t.S88 END,      
  S801 = CASE WHEN t.S801 = 0 THEN NULL ELSE t.S801 END,          
  S802 = CASE WHEN t.S802 = 0 THEN NULL ELSE t.S802 END,          
  S803 = CASE WHEN t.S803 = 0 THEN NULL ELSE t.S803 END,          
  S806 = CASE WHEN t.S806 = 0 THEN NULL ELSE t.S806 END,        
  S807 = CASE WHEN t.S807 = 0 THEN NULL ELSE t.S807 END,        
  S90 = CASE WHEN t.S90 = 0 THEN NULL ELSE t.S90 END,        
  S92 = CASE WHEN t.S92 = 0 THEN NULL ELSE t.S92 END,       
  S511 = CASE WHEN t.S511 = 0 THEN NULL ELSE t.S511 END,        
  S512 = CASE WHEN t.S512 = 0 THEN NULL ELSE t.S512 END,        
  S701 = CASE WHEN t.S701 = 0 THEN NULL ELSE t.S701 END,        
  S702 = CASE WHEN t.S702 = 0 THEN NULL ELSE t.S702 END,        
  S703 = CASE WHEN t.S703 = 0 THEN NULL ELSE t.S703 END,        
  S704 = CASE WHEN t.S704 = 0 THEN NULL ELSE t.S704 END,        
  S705 = CASE WHEN t.S705 = 0 THEN NULL ELSE t.S705 END,        
  S707 = CASE WHEN t.S707 = 0 THEN NULL ELSE t.S707 END,        
  S708 = CASE WHEN t.S708 = 0 THEN NULL ELSE t.S708 END,        
  S706 = CASE WHEN t.S706 = 0 THEN NULL ELSE t.S706 END,        
  S402 = CASE WHEN t.S402 = 0 THEN NULL ELSE t.S402 END,        
  S86 = CASE WHEN t.S86 = 0 THEN NULL ELSE t.S86 END,        
  S87 = CASE WHEN t.S87 = 0 THEN NULL ELSE t.S87 END ,      
  S89 = CASE WHEN t.S89 = 0 THEN NULL ELSE t.S89 END,      
  S95 = CASE WHEN t.S95 = 0 THEN NULL ELSE t.S95 END  ,      
  S49 = CASE WHEN t.S49 = 0 THEN NULL ELSE t.S49 END,      
  S513 = CASE WHEN t.S513 = 0 THEN NULL ELSE t.S513 END,      
  S401 = CASE WHEN t.S401 = 0 THEN NULL ELSE t.S401 END,      
  S501 = CASE WHEN t.S501 = 0 THEN NULL ELSE t.S501 END,      
  S502 = CASE WHEN t.S502 = 0 THEN NULL ELSE t.S502 END,      
  S503 = CASE WHEN t.S503 = 0 THEN NULL ELSE t.S503 END,      
  S504= CASE WHEN t.S504 = 0 THEN NULL  ELSE t.S504 END,      
  S505 = CASE WHEN t.S505 = 0 THEN NULL ELSE t.S505 END,      
  S506 = CASE WHEN t.S506 = 0 THEN NULL ELSE t.S506 END,      
  S507 = CASE WHEN t.S507 = 0 THEN NULL ELSE t.S507 END,      
  S508= CASE WHEN t.S508= 0 THEN NULL  ELSE t.S508 END,      
  S509= CASE WHEN t.S509 = 0 THEN NULL ELSE t.S509 END,      
  S510= CASE WHEN t.S510 = 0 THEN NULL ELSE t.S510 END,      
  S817 = CASE WHEN t.S817 = 0 THEN NULL ELSE t.S817 END,      
  S91 = CASE WHEN t.S91 = 0 THEN NULL ELSE t.S91 END,      
  S96 = CASE WHEN t.S96 = 0 THEN NULL ELSE t.S96 END,      
  S97 = CASE WHEN t.S97 = 0 THEN NULL ELSE t.S97 END,      
  S98 = CASE WHEN t.S98 = 0 THEN NULL ELSE t.S98 END,      
  S808 = CASE WHEN t.S808 = 0 THEN NULL ELSE t.S808 END,      
  S809 = CASE WHEN t.S809 = 0 THEN NULL ELSE t.S809 END,      
  S810 = CASE WHEN t.S810 = 0 THEN NULL ELSE t.S810 END,      
  S811 = CASE WHEN t.S811 = 0 THEN NULL ELSE t.S811 END,      
   S812 = CASE WHEN t.S812 = 0 THEN NULL ELSE t.S812 END,      
   S514 = CASE WHEN t.S514 = 0 THEN NULL ELSE t.S514 END,      
   S515 = CASE WHEN t.S515 = 0 THEN NULL ELSE t.S515 END,      
   S517 = CASE WHEN t.S517 = 0 THEN NULL ELSE t.S517 END,      
   S516 = CASE WHEN t.S516 = 0 THEN NULL ELSE t.S516 END,      
S99 = CASE WHEN t.S99 = 0 THEN NULL ELSE t.S99 END,      
S520 = CASE WHEN t.S520 = 0 THEN NULL ELSE t.S520 END,      
S522 = CASE WHEN t.S522 = 0 THEN NULL ELSE t.S522 END,      
S101 = CASE WHEN t.S101 = 0 THEN NULL ELSE t.S101 END,      
S804 = CASE WHEN t.S804 = 0 THEN NULL ELSE t.S804 END,      
S103 = CASE WHEN t.S103 = 0 THEN NULL ELSE t.S103 END,      
S100 = CASE WHEN t.S100 = 0 THEN NULL ELSE t.S100 END,      
S521 = CASE WHEN t.S521 = 0 THEN NULL ELSE t.S521 END,      
S519 = CASE WHEN t.S519 = 0 THEN NULL ELSE t.S519 END,      
S107 = CASE WHEN t.S107 = 0 THEN NULL ELSE t.S107 END,      
S108 = CASE WHEN t.S108 = 0 THEN NULL ELSE t.S108 END,      
S105 = CASE WHEN t.S105 = 0 THEN NULL ELSE t.S105 END,      
S106 = CASE WHEN t.S106 = 0 THEN NULL ELSE t.S106 END,      
S110 = CASE WHEN t.S110 = 0 THEN NULL ELSE t.S110 END,      
S102 = CASE WHEN t.S102 = 0 THEN NULL ELSE t.S102 END,      
S104 = CASE WHEN t.S104 = 0 THEN NULL ELSE t.S104 END,      
S814 = CASE WHEN t.S814 = 0 THEN NULL ELSE t.S814 END,      
S815 = CASE WHEN t.S815 = 0 THEN NULL ELSE t.S815 END,      
S111 = CASE WHEN t.S111 = 0 THEN NULL ELSE t.S111 END,      
S518 = CASE WHEN t.S518 = 0 THEN NULL ELSE t.S518 END,      
S112 = CASE WHEN t.S112 = 0 THEN NULL ELSE t.S112 END,      
S114 = CASE WHEN t.S114 = 0 THEN NULL ELSE t.S114 END,      
S115 = CASE WHEN t.S115 = 0 THEN NULL ELSE t.S115 END,      
S113 = CASE WHEN t.S113 = 0 THEN NULL ELSE t.S113 END,      
S116 = CASE WHEN t.S116 = 0 THEN NULL ELSE t.S116 END,      
S118 = CASE WHEN t.S118 = 0 THEN NULL ELSE t.S118 END,      
S117 = CASE WHEN t.S117 = 0 THEN NULL ELSE t.S117 END,      
S119 = CASE WHEN t.S119 = 0 THEN NULL ELSE t.S119 END,      
S523 = CASE WHEN t.S523 = 0 THEN NULL ELSE t.S523 END,      
S120 = CASE WHEN t.S120 = 0 THEN NULL ELSE t.S120 END,      
S122 = CASE WHEN t.S122 = 0 THEN NULL ELSE t.S122 END,      
S121 = CASE WHEN t.S121 = 0 THEN NULL ELSE t.S121 END,      
S123 = CASE WHEN t.S123 = 0 THEN NULL ELSE t.S123 END,      
S525 = CASE WHEN t.S525 = 0 THEN NULL ELSE t.S525 END,      
S524 = CASE WHEN t.S524 = 0 THEN NULL ELSE t.S524 END,      
S126 = CASE WHEN t.S126 = 0 THEN NULL ELSE t.S126 END,      
S127 = CASE WHEN t.S127 = 0 THEN NULL ELSE t.S127 END,      
S526 = CASE WHEN t.S526 = 0 THEN NULL ELSE t.S526 END,      
S129 = CASE WHEN t.S129 = 0 THEN NULL ELSE t.S129 END,      
    S124 = CASE WHEN t.S124 = 0 THEN NULL ELSE t.S124 END,      
    S128 = CASE WHEN t.S128 = 0 THEN NULL ELSE t.S128 END,      
    S125 = CASE WHEN t.S125 = 0 THEN NULL ELSE t.S125 END,      
    S144 = CASE WHEN t.S144 = 0 THEN NULL ELSE t.S144 END,      
S145 = CASE WHEN t.S145 = 0 THEN NULL ELSE t.S145 END,      
S146 = CASE WHEN t.S146 = 0 THEN NULL ELSE t.S146 END,      
S147 = CASE WHEN t.S147 = 0 THEN NULL ELSE t.S147 END,      
S148 = CASE WHEN t.S148 = 0 THEN NULL ELSE t.S148 END,      
S149 = CASE WHEN t.S149 = 0 THEN NULL ELSE t.S149 END,      
S151 = CASE WHEN t.S151 = 0 THEN NULL ELSE t.S151 END,      
S152 = CASE WHEN t.S152 = 0 THEN NULL ELSE t.S152 END,      
S153 = CASE WHEN t.S153 = 0 THEN NULL ELSE t.S153 END,      
S154 = CASE WHEN t.S154 = 0 THEN NULL ELSE t.S154 END,      
S155 = CASE WHEN t.S155 = 0 THEN NULL ELSE t.S155 END,      
S157 = CASE WHEN t.S157 = 0 THEN NULL ELSE t.S157 END,      
S156 = CASE WHEN t.S156 = 0 THEN NULL ELSE t.S156 END,      
S158 = CASE WHEN t.S158 = 0 THEN NULL ELSE t.S158 END,      
S159 = CASE WHEN t.S159 = 0 THEN NULL ELSE t.S159 END,      
S160 = CASE WHEN t.S160 = 0 THEN NULL ELSE t.S160 END,      
S171 = CASE WHEN t.S171 = 0 THEN NULL ELSE t.S171 END,      
S832 = CASE WHEN t.S832 = 0 THEN NULL ELSE t.S832 END,      
S833 = CASE WHEN t.S833 = 0 THEN NULL ELSE t.S833 END,      
S834 = CASE WHEN t.S834 = 0 THEN NULL ELSE t.S834 END,      
S172 = CASE WHEN t.S172 = 0 THEN NULL ELSE t.S172 END,      
S161 = CASE WHEN t.S161 = 0 THEN NULL ELSE t.S161 END,      
S162 = CASE WHEN t.S162 = 0 THEN NULL ELSE t.S162 END,      
S836 = CASE WHEN t.S836 = 0 THEN NULL ELSE t.S836 END,      
S835 = CASE WHEN t.S835 = 0 THEN NULL ELSE t.S835 END,      
S173 = CASE WHEN t.S173 = 0 THEN NULL ELSE t.S173 END,      
S163 = CASE WHEN t.S163 = 0 THEN NULL ELSE t.S163 END,      
S164 = CASE WHEN t.S164 = 0 THEN NULL ELSE t.S164 END,      
S174 = CASE WHEN t.S174 = 0 THEN NULL ELSE t.S174 END,      
S166 = CASE WHEN t.S166 = 0 THEN NULL ELSE t.S166 END,      
S837 = CASE WHEN t.S837 = 0 THEN NULL ELSE t.S837 END,      
S165 = CASE WHEN t.S165 = 0 THEN NULL ELSE t.S165 END,      
S838 = CASE WHEN t.S838 = 0 THEN NULL ELSE t.S838 END,      
S839 = CASE WHEN t.S839 = 0 THEN NULL ELSE t.S839 END,      
S167 = CASE WHEN t.S167 = 0 THEN NULL ELSE t.S167 END,      
S840 = CASE WHEN t.S840 = 0 THEN NULL ELSE t.S840 END,      
S841 = CASE WHEN t.S841 = 0 THEN NULL ELSE t.S841 END,      
S527 = CASE WHEN t.S527 = 0 THEN NULL ELSE t.S527 END,      
S175 = CASE WHEN t.S175 = 0 THEN NULL ELSE t.S175 END,      
S176 = CASE WHEN t.S176 = 0 THEN NULL ELSE t.S176 END,      
S177 = CASE WHEN t.S177 = 0 THEN NULL ELSE t.S177 END,      
S180 = CASE WHEN t.S180 = 0 THEN NULL ELSE t.S180 END,      
S181 = CASE WHEN t.S181 = 0 THEN NULL ELSE t.S181 END,      
S179 = CASE WHEN t.S179 = 0 THEN NULL ELSE t.S179 END,      
S182 = CASE WHEN t.S182 = 0 THEN NULL ELSE t.S182 END,      
S183 = CASE WHEN t.S183 = 0 THEN NULL ELSE t.S183 END,    
S178 = CASE WHEN t.S178 = 0 THEN NULL ELSE t.S178 END,      
S184 = CASE WHEN t.S184 = 0 THEN NULL ELSE t.S184 END,      
S168 = CASE WHEN t.S168 = 0 THEN NULL ELSE t.S168 END,      
S169 = CASE WHEN t.S169 = 0 THEN NULL ELSE t.S169 END,      
S143 = CASE WHEN t.S143 = 0 THEN NULL ELSE t.S143 END,      
S185 = CASE WHEN t.S185 = 0 THEN NULL ELSE t.S185 END,      
S843 = CASE WHEN t.S843 = 0 THEN NULL ELSE t.S843 END,      
S844 = CASE WHEN t.S844 = 0 THEN NULL ELSE t.S844 END,      
S842 = CASE WHEN t.S842 = 0 THEN NULL ELSE t.S842 END,
S170 = CASE WHEN t.S170 = 0 THEN NULL ELSE t.S170 END,
S845 = CASE WHEN t.S845 = 0 THEN NULL ELSE t.S845 END,
S186 = CASE WHEN t.S186 = 0 THEN NULL ELSE t.S186 END,
S846 = CASE WHEN t.S846 = 0 THEN NULL ELSE t.S846 END,
S187 = CASE WHEN t.S187 = 0 THEN NULL ELSE t.S187 END,
S188 = CASE WHEN t.S188 = 0 THEN NULL ELSE t.S188 END,
S189 = CASE WHEN t.S189 = 0 THEN NULL ELSE t.S189 END,
S847 = CASE WHEN t.S847 = 0 THEN NULL ELSE t.S847 END,
S190 = CASE WHEN t.S190 = 0 THEN NULL ELSE t.S190 END,
S191 = CASE WHEN t.S191 = 0 THEN NULL ELSE t.S191 END,  
S848 = CASE WHEN t.S848 = 0 THEN NULL ELSE t.S848 END,  
S192 = CASE WHEN t.S192 = 0 THEN NULL ELSE t.S192 END
 FROM #Result r      
 INNER JOIN #Temp t ON t.Date = r.Date          
       
-- get all the dates when the process was run          
SELECT  CASE WHEN @Type = 'SystemDate' THEN dbo.GetDateWithoutTime(run.ScheduledAt) ELSE dbo.GetDateWithoutTime(run.RunDate) END AS Date,          
   SUM(CASE WHEN report.Code = 'S1' THEN 0 ELSE NULL END) AS S1,          
   SUM(CASE WHEN report.Code = 'S2' THEN 0 ELSE NULL END) AS S2,          
   SUM(CASE WHEN report.Code = 'S3' THEN 0 ELSE NULL END) AS S3,          
   SUM(CASE WHEN report.Code = 'S4' THEN 0 ELSE NULL END) AS S4,          
   SUM(CASE WHEN report.Code = 'S5' THEN 0 ELSE NULL END) AS S5,          
   SUM(CASE WHEN report.Code = 'S6' THEN 0 ELSE NULL END) AS S6,          
   SUM(CASE WHEN report.Code = 'S7' THEN 0 ELSE NULL END) AS S7,          
   SUM(CASE WHEN report.Code = 'S8' THEN 0 ELSE NULL END) AS S8,          
   SUM(CASE WHEN report.Code = 'S9' THEN 0 ELSE NULL END) AS S9,          
   SUM(CASE WHEN report.Code = 'S10' THEN 0 ELSE NULL END) AS S10,          
   SUM(CASE WHEN report.Code = 'S11' THEN 0 ELSE NULL END) AS S11,          
   SUM(CASE WHEN report.Code = 'S12' THEN 0 ELSE NULL END) AS S12,          
   SUM(CASE WHEN report.Code = 'S13' THEN 0 ELSE NULL END) AS S13,          
   SUM(CASE WHEN report.Code = 'S14' THEN 0 ELSE NULL END) AS S14,          
   SUM(CASE WHEN report.Code = 'S15' THEN 0 ELSE NULL END) AS S15,          
   SUM(CASE WHEN report.Code = 'S16' THEN 0 ELSE NULL END) AS S16,          
   SUM(CASE WHEN report.Code = 'S17' THEN 0 ELSE NULL END) AS S17,          
   SUM(CASE WHEN report.Code = 'S18' THEN 0 ELSE NULL END) AS S18,            
   SUM(CASE WHEN report.Code = 'S19' THEN 0 ELSE NULL END) AS S19,          
   SUM(CASE WHEN report.Code = 'S20' THEN 0 ELSE NULL END) AS S20,          
   SUM(CASE WHEN report.Code = 'S21' THEN 0 ELSE NULL END) AS S21,          
   SUM(CASE WHEN report.Code = 'S22' THEN 0 ELSE NULL END) AS S22,          
   SUM(CASE WHEN report.Code = 'S23' THEN 0 ELSE NULL END) AS S23,       
   SUM(CASE WHEN report.Code = 'S24' THEN 0 ELSE NULL END) AS S24,          
   SUM(CASE WHEN report.Code = 'S25' THEN 0 ELSE NULL END) AS S25,          
   SUM(CASE WHEN report.Code = 'S26' THEN 0 ELSE NULL END) AS S26,          
   SUM(CASE WHEN report.Code = 'S27' THEN 0 ELSE NULL END) AS S27,          
   SUM(CASE WHEN report.Code = 'S28' THEN 0 ELSE NULL END) AS S28,            
   SUM(CASE WHEN report.Code = 'S29' THEN 0 ELSE NULL END) AS S29,            
   SUM(CASE WHEN report.Code = 'S30' THEN 0 ELSE NULL END) AS S30,          
   SUM(CASE WHEN report.Code = 'S31' THEN 0 ELSE NULL END) AS S31,                
   SUM(CASE WHEN report.Code = 'S32' THEN 0 ELSE NULL END) AS S32,          
   SUM(CASE WHEN report.Code = 'S33' THEN 0 ELSE NULL END) AS S33,          
   SUM(CASE WHEN report.Code = 'S34' THEN 0 ELSE NULL END) AS S34,          
   SUM(CASE WHEN report.Code = 'S35' THEN 0 ELSE NULL END) AS S35,          
   SUM(CASE WHEN report.Code = 'S36' THEN 0 ELSE NULL END) AS S36,          
   SUM(CASE WHEN report.Code = 'S37' THEN 0 ELSE NULL END) AS S37,            
   SUM(CASE WHEN report.Code = 'S38' THEN 0 ELSE NULL END) AS S38,          
   SUM(CASE WHEN report.Code = 'S39' THEN 0 ELSE NULL END) AS S39,          
   SUM(CASE WHEN report.Code = 'S40' THEN 0 ELSE NULL END) AS S40,          
   SUM(CASE WHEN report.Code = 'S41' THEN 0 ELSE NULL END) AS S41,          
   SUM(CASE WHEN report.Code = 'S42' THEN 0 ELSE NULL END) AS S42,            
   SUM(CASE WHEN report.Code = 'S43' THEN 0 ELSE NULL END) AS S43,          
   SUM(CASE WHEN report.Code = 'S44' THEN 0 ELSE NULL END) AS S44,          
   SUM(CASE WHEN report.Code = 'S45' THEN 0 ELSE NULL END) AS S45,          
   SUM(CASE WHEN report.Code = 'S46' THEN 0 ELSE NULL END) AS S46,          
   SUM(CASE WHEN report.Code = 'S47' THEN 0 ELSE NULL END) AS S47,          
   SUM(CASE WHEN report.Code = 'S48' THEN 0 ELSE NULL END) AS S48,      
   SUM(CASE WHEN report.Code = 'S50' THEN 0 ELSE NULL END) AS S50,            
   SUM(CASE WHEN report.Code = 'S51' THEN 0 ELSE NULL END) AS S51,            
   SUM(CASE WHEN report.Code = 'S52' THEN 0 ELSE NULL END) AS S52,            
   SUM(CASE WHEN report.Code = 'S53' THEN 0 ELSE NULL END) AS S53,          
   SUM(CASE WHEN report.Code = 'S54' THEN 0 ELSE NULL END) AS S54,       
   SUM(CASE WHEN report.Code = 'S55' THEN 0 ELSE NULL END) AS S55,          
   SUM(CASE WHEN report.Code = 'S56' THEN 0 ELSE NULL END) AS S56,          
   SUM(CASE WHEN report.Code = 'S57' THEn 0 ELSE NULL END) AS S57,          
   SUM(CASE WHEN report.Code = 'S58' THEN 0 ELSE NULL END) AS S58,            
   SUM(CASE WHEN report.Code = 'S59' THEn 0 ELSE NULL END) AS S59,          
   SUM(CASE WHEN report.Code = 'S60' THEN 0 ELSE NULL END) AS S60,            
  SUM(CASE WHEN report.Code = 'S62' THEN 0 ELSE NULL END) AS S62,          
   SUM(CASE WHEN report.Code = 'S63' THEN 0 ELSE NULL END) AS S63,          
   SUM(CASE WHEN report.Code = 'S64' THEN 0 ELSE NULL END) AS S64,          
   SUM(CASE WHEN report.Code = 'S65' THEN 0 ELSE NULL END) AS S65,          
   SUM(CASE WHEN report.Code = 'S66' THEN 0 ELSE NULL END) AS S66,          
   SUM(CASE WHEN report.Code = 'S72' THEN 0 ELSE NULL END) AS S72,          
   SUM(CASE WHEN report.Code = 'S73' THEN 0 ELSE NULL END) AS S73,          
   SUM(CASE WHEN report.Code = 'S74' THEN 0 ELSE NULL END) AS S74,          
   SUM(CASE WHEN report.Code = 'S75' THEN 0 ELSE NULL END) AS S75,          
   SUM(CASE WHEN report.Code = 'S76' THEN 0 ELSE NULL END) AS S76,          
   SUM(CASE WHEN report.Code = 'S77' THEN 0 ELSE NULL END) AS S77,          
   SUM(CASE WHEN report.Code = 'S78' THEN 0 ELSE NULL END) AS S78,          
   SUM(CASE WHEN report.Code = 'S79' THEN 0 ELSE NULL END) AS S79,          
   SUM(CASE WHEN report.Code = 'S80' THEN 0 ELSE NULL END) AS S80,          
   SUM(CASE WHEN report.Code = 'S82' THEN 0 ELSE NULL END) AS S82,          
   SUM(CASE WHEN report.Code = 'S83' THEN 0 ELSE NULL END) AS S83,          
   SUM(CASE WHEN report.Code = 'S84' THEN 0 ELSE NULL END) AS S84,          
   SUM(CASE WHEN report.Code = 'S85' THEN 0 ELSE NULL END) AS S85,          
   SUM(CASE WHEN report.Code = 'S88' THEN 0 ELSE NULL END) AS S88,      
   SUM(CASE WHEN report.Code = 'S801' THEN 0 ELSE NULL END) AS S801,          
   SUM(CASE WHEN report.Code = 'S802' THEN 0 ELSE NULL END) AS S802,          
   SUM(CASE WHEN report.Code = 'S803' THEN 0 ELSE NULL END) AS S803,          
   SUM(CASE WHEN report.Code = 'S806' THEN 0 ELSE NULL END) AS S806,        
   SUM(CASE WHEN report.Code = 'S807' THEN 0 ELSE NULL END) AS S807,        
   SUM(CASE WHEN report.Code = 'S90' THEN 0 ELSE NULL END) AS S90,        
   SUM(CASE WHEN report.Code = 'S92' THEN 0 ELSE NULL END) AS S92,        
   SUM(CASE WHEN report.Code = 'S511' THEN 0 ELSE NULL END) AS S511,        
   SUM(CASE WHEN report.Code = 'S512' THEN 0 ELSE NULL END) AS S512,        
   SUM(CASE WHEN report.Code = 'S701' THEN 0 ELSE NULL END) AS S701,          
   SUM(CASE WHEN report.Code = 'S702' THEN 0 ELSE NULL END) AS S702,        
   SUM(CASE WHEN report.Code = 'S703' THEN 0 ELSE NULL END) AS S703,        
   SUM(CASE WHEN report.Code = 'S704' THEN 0 ELSE NULL END) AS S704,        
   SUM(CASE WHEN report.Code = 'S705' THEN 0 ELSE NULL END) AS S705,        
   SUM(CASE WHEN report.Code = 'S707' THEN 0 ELSE NULL END) AS S707,        
   SUM(CASE WHEN report.Code = 'S708' THEN 0 ELSE NULL END) AS S708,        
   SUM(CASE WHEN report.Code = 'S706' THEN 0 ELSE NULL END) AS S706,        
   SUM(CASE WHEN report.Code = 'S402' THEN 0 ELSE NULL END) AS S402,        
   SUM(CASE WHEN report.Code = 'S86' THEN 0 ELSE NULL END) AS S86,        
   SUM(CASE WHEN report.Code = 'S87' THEN 0 ELSE NULL END) AS S87,      
   SUM(CASE WHEN report.Code = 'S89' THEN 0 ELSE NULL END) AS S89,      
   SUM(CASE WHEN report.Code = 'S95' THEN 0 ELSE NULL END) AS S95,      
   SUM(CASE WHEN report.Code = 'S49' THEN 0 ELSE NULL END) AS S49,      
SUM(CASE WHEN report.Code = 'S513' THEN 0 ELSE NULL END) AS S513,      
SUM(CASE WHEN report.Code = 'S401' THEN 0 ELSE NULL END) AS S401,      
SUM(CASE WHEN report.Code = 'S501' THEN 0 ELSE NULL END) AS S501,      
SUM(CASE WHEN report.Code = 'S502' THEN 0 ELSE NULL END) AS S502,      
SUM(CASE WHEN report.Code = 'S503' THEN 0 ELSE NULL END) AS S503,      
SUM(CASE WHEN report.Code = 'S504' THEN 0 ELSE NULL END) AS S504,      
SUM(CASE WHEN report.Code = 'S505' THEN 0 ELSE NULL END) AS S505,      
SUM(CASE WHEN report.Code = 'S506' THEN 0 ELSE NULL END) AS S506,      
SUM(CASE WHEN report.Code = 'S507' THEN 0 ELSE NULL END) AS S507,      
SUM(CASE WHEN report.Code = 'S508' THEN 0 ELSE NULL END) AS S508,      
SUM(CASE WHEN report.Code = 'S509' THEN 0 ELSE NULL END) AS S509,      
SUM(CASE WHEN report.Code = 'S510' THEN 0 ELSE NULL END) AS S510,      
SUM(CASE WHEN report.Code = 'S817' THEN 0 ELSE NULL END) AS S817,      
SUM(CASE WHEN report.Code = 'S91' THEN 0 ELSE NULL END) AS S91 ,      
SUM(CASE WHEN report.Code = 'S96' THEN 0 ELSE NULL END) AS S96,      
SUM(CASE WHEN report.Code = 'S97' THEN 0 ELSE NULL END) AS S97,      
SUM(CASE WHEN report.Code = 'S98' THEN 0 ELSE NULL END) AS S98,      
SUM(CASE WHEN report.Code = 'S808' THEN 0 ELSE NULL END) AS S808,      
SUM(CASE WHEN report.Code = 'S809' THEN 0 ELSE NULL END) AS S809,      
SUM(CASE WHEN report.Code = 'S810' THEN 0 ELSE NULL END) AS S810,      
SUM(CASE WHEN report.Code = 'S811' THEN 0 ELSE NULL END) AS S811,      
SUM(CASE WHEN report.Code = 'S812' THEN 0 ELSE NULL END) AS S812,      
SUM(CASE WHEN report.Code = 'S514' THEN 0 ELSE NULL END) AS S514,      
SUM(CASE WHEN report.Code = 'S515' THEN 0 ELSE NULL END) AS S515,      
SUM(CASE WHEN report.Code = 'S517' THEN 0 ELSE NULL END) AS S517,      
SUM(CASE WHEN report.Code = 'S516' THEN 0 ELSE NULL END) AS S516,      
SUM(CASE WHEN report.Code = 'S99' THEN 0 ELSE NULL END) AS S99,      
SUM(CASE WHEN report.Code = 'S520' THEN 0 ELSE NULL END) AS S520,      
SUM(CASE WHEN report.Code = 'S522' THEN 0 ELSE NULL END) AS S522,      
SUM(CASE WHEN report.Code = 'S101' THEN 0 ELSE NULL END) AS S101,      
SUM(CASE WHEN report.Code = 'S804' THEN 0 ELSE NULL END) AS S804,      
SUM(CASE WHEN report.Code = 'S103' THEN 0 ELSE NULL END) AS S103,      
SUM(CASE WHEN report.Code = 'S100' THEN 0 ELSE NULL END) AS S100,      
SUM(CASE WHEN report.Code = 'S521' THEN 0 ELSE NULL END) AS S521,      
SUM(CASE WHEN report.Code = 'S519' THEN 0 ELSE NULL END) AS S519,      
SUM(CASE WHEN report.Code = 'S107' THEN 0 ELSE NULL END) AS S107,      
SUM(CASE WHEN report.Code = 'S108' THEN 0 ELSE NULL END) AS S108,      
SUM(CASE WHEN report.Code = 'S105' THEN 0 ELSE NULL END) AS S105,      
SUM(CASE WHEN report.Code = 'S106' THEN 0 ELSE NULL END) AS S106,      
SUM(CASE WHEN report.Code = 'S110' THEN 0 ELSE NULL END) AS S110,      
SUM(CASE WHEN report.Code = 'S102' THEN 0 ELSE NULL END) AS S102,      
SUM(CASE WHEN report.Code = 'S104' THEN 0 ELSE NULL END) AS S104,      
SUM(CASE WHEN report.Code = 'S814' THEN 0 ELSE NULL END) AS S814,      
SUM(CASE WHEN report.Code = 'S815' THEN 0 ELSE NULL END) AS S815,      
SUM(CASE WHEN report.Code = 'S111' THEN 0 ELSE NULL END) AS S111,      
SUM(CASE WHEN report.Code = 'S518' THEN 0 ELSE NULL END) AS S518,      
SUM(CASE WHEN report.Code = 'S112' THEN 0 ELSE NULL END) AS S112,      
SUM(CASE WHEN report.Code = 'S114' THEN 0 ELSE NULL END) AS S114,      
SUM(CASE WHEN report.Code = 'S115' THEN 0 ELSE NULL END) AS S115,      
SUM(CASE WHEN report.Code = 'S113' THEN 0 ELSE NULL END) AS S113,      
SUM(CASE WHEN report.Code = 'S116' THEN 0 ELSE NULL END) AS S116,      
SUM(CASE WHEN report.Code = 'S118' THEN 0 ELSE NULL END) AS S118,      
SUM(CASE WHEN report.Code = 'S117' THEN 0 ELSE NULL END) AS S117,      
SUM(CASE WHEN report.Code = 'S119' THEN 0 ELSE NULL END) AS S119,      
SUM(CASE WHEN report.Code = 'S523' THEN 0 ELSE NULL END) AS S523,      
SUM(CASE WHEN report.Code = 'S120' THEN 0 ELSE NULL END) AS S120,      
SUM(CASE WHEN report.Code = 'S122' THEN 0 ELSE NULL END) AS S122,      
SUM(CASE WHEN report.Code = 'S121' THEN 0 ELSE NULL END) AS S121,      
SUM(CASE WHEN report.Code = 'S123' THEN 0 ELSE NULL END) AS S123,      
SUM(CASE WHEN report.Code = 'S525' THEN 0 ELSE NULL END) AS S525,      
SUM(CASE WHEN report.Code = 'S524' THEN 0 ELSE NULL END) AS S524,      
SUM(CASE WHEN report.Code = 'S126' THEN 0 ELSE NULL END) AS S126,      
SUM(CASE WHEN report.Code = 'S127' THEN 0 ELSE NULL END) AS S127,      
SUM(CASE WHEN report.Code = 'S526' THEN 0 ELSE NULL END) AS S526,      
SUM(CASE WHEN report.Code = 'S129' THEN 0 ELSE NULL END) AS S129,      
SUM(CASE WHEN report.Code = 'S124' THEN 0 ELSE NULL END) AS S124,      
SUM(CASE WHEN report.Code = 'S128' THEN 0 ELSE NULL END) AS S128,      
SUM(CASE WHEN report.Code = 'S125' THEN 0 ELSE NULL END) AS S125,      
SUM(CASE WHEN report.Code = 'S144' THEN 0 ELSE NULL END) AS S144,      
SUM(CASE WHEN report.Code = 'S145' THEN 0 ELSE NULL END) AS S145,      
SUM(CASE WHEN report.Code = 'S146' THEN 0 ELSE NULL END) AS S146,      
SUM(CASE WHEN report.Code = 'S147' THEN 0 ELSE NULL END) AS S147,      
SUM(CASE WHEN report.Code = 'S148' THEN 0 ELSE NULL END) AS S148,      
SUM(CASE WHEN report.Code = 'S149' THEN 0 ELSE NULL END) AS S149,      
SUM(CASE WHEN report.Code = 'S151' THEN 0 ELSE NULL END) AS S151,      
SUM(CASE WHEN report.Code = 'S152' THEN 0 ELSE NULL END) AS S152,      
SUM(CASE WHEN report.Code = 'S153' THEN 0 ELSE NULL END) AS S153,      
SUM(CASE WHEN report.Code = 'S154' THEN 0 ELSE NULL END) AS S154,      
SUM(CASE WHEN report.Code = 'S155' THEN 0 ELSE NULL END) AS S155,      
SUM(CASE WHEN report.Code = 'S157' THEN 0 ELSE NULL END) AS S157,      
SUM(CASE WHEN report.Code = 'S156' THEN 0 ELSE NULL END) AS S156,      
SUM(CASE WHEN report.Code = 'S158' THEN 0 ELSE NULL END) AS S158,      
SUM(CASE WHEN report.Code = 'S159' THEN 0 ELSE NULL END) AS S159,      
SUM(CASE WHEN report.Code = 'S160' THEN 0 ELSE NULL END) AS S160,      
SUM(CASE WHEN report.Code = 'S171' THEN 0 ELSE NULL END) AS S171,      
SUM(CASE WHEN report.Code = 'S832' THEN 0 ELSE NULL END) AS S832,      
SUM(CASE WHEN report.Code = 'S833' THEN 0 ELSE NULL END) AS S833,      
SUM(CASE WHEN report.Code = 'S834' THEN 0 ELSE NULL END) AS S834,      
SUM(CASE WHEN report.Code = 'S172' THEN 0 ELSE NULL END) AS S172,      
SUM(CASE WHEN report.Code = 'S161' THEN 0 ELSE NULL END) AS S161,      
SUM(CASE WHEN report.Code = 'S162' THEN 0 ELSE NULL END) AS S162,      
SUM(CASE WHEN report.Code = 'S836' THEN 0 ELSE NULL END) AS S836,      
SUM(CASE WHEN report.Code = 'S835' THEN 0 ELSE NULL END) AS S835,      
SUM(CASE WHEN report.Code = 'S173' THEN 0 ELSE NULL END) AS S173,      
SUM(CASE WHEN report.Code = 'S163' THEN 0 ELSE NULL END) AS S163,      
SUM(CASE WHEN report.Code = 'S164' THEN 0 ELSE NULL END) AS S164,      
SUM(CASE WHEN report.Code = 'S174' THEN 0 ELSE NULL END) AS S174,      
SUM(CASE WHEN report.Code = 'S166' THEN 0 ELSE NULL END) AS S166,      
SUM(CASE WHEN report.Code = 'S837' THEN 0 ELSE NULL END) AS S837,      
SUM(CASE WHEN report.Code = 'S165' THEN 0 ELSE NULL END) AS S165,      
SUM(CASE WHEN report.Code = 'S838' THEN 0 ELSE NULL END) AS S838,      
SUM(CASE WHEN report.Code = 'S839' THEN 0 ELSE NULL END) AS S839,      
SUM(CASE WHEN report.Code = 'S167' THEN 0 ELSE NULL END) AS S167,      
SUM(CASE WHEN report.Code = 'S840' THEN 0 ELSE NULL END) AS S840,      
SUM(CASE WHEN report.Code = 'S841' THEN 0 ELSE NULL END) AS S841,      
SUM(CASE WHEN report.Code = 'S527' THEN 0 ELSE NULL END) AS S527,      
SUM(CASE WHEN report.Code = 'S175' THEN 0 ELSE NULL END) AS S175,      
SUM(CASE WHEN report.Code = 'S176' THEN 0 ELSE NULL END) AS S176,      
SUM(CASE WHEN report.Code = 'S177' THEN 0 ELSE NULL END) AS S177,      
SUM(CASE WHEN report.Code = 'S180' THEN 0 ELSE NULL END) AS S180,      
SUM(CASE WHEN report.Code = 'S181' THEN 0 ELSE NULL END) AS S181,      
SUM(CASE WHEN report.Code = 'S179' THEN 0 ELSE NULL END) AS S179,      
SUM(CASE WHEN report.Code = 'S182' THEN 0 ELSE NULL END) AS S182,      
SUM(CASE WHEN report.Code = 'S183' THEN 0 ELSE NULL END) AS S183,    
SUM(CASE WHEN report.Code = 'S178' THEN 0 ELSE NULL END) AS S178,      
SUM(CASE WHEN report.Code = 'S184' THEN 0 ELSE NULL END) AS S184,      
SUM(CASE WHEN report.Code = 'S168' THEN 0 ELSE NULL END) AS S168,      
SUM(CASE WHEN report.Code = 'S169' THEN 0 ELSE NULL END) AS S169,      
SUM(CASE WHEN report.Code = 'S143' THEN 0 ELSE NULL END) AS S143,      
SUM(CASE WHEN report.Code = 'S185' THEN 0 ELSE NULL END) AS S185 ,      
SUM(CASE WHEN report.Code = 'S843' THEN 0 ELSE NULL END) AS S843,      
SUM(CASE WHEN report.Code = 'S844' THEN 0 ELSE NULL END) AS S844,      
SUM(CASE WHEN report.Code = 'S842' THEN 0 ELSE NULL END) AS S842,
SUM(CASE WHEN report.Code = 'S170' THEN 0 ELSE NULL END) AS S170,
SUM(CASE WHEN report.Code = 'S845' THEN 0 ELSE NULL END) AS S845,
SUM(CASE WHEN report.Code = 'S186' THEN 0 ELSE NULL END) AS S186,
SUM(CASE WHEN report.Code = 'S846' THEN 0 ELSE NULL END) AS S846,
SUM(CASE WHEN report.Code = 'S187' THEN 0 ELSE NULL END) AS S187,
SUM(CASE WHEN report.Code = 'S188' THEN 0 ELSE NULL END) AS S188,
SUM(CASE WHEN report.Code = 'S189' THEN 0 ELSE NULL END) AS S189,
SUM(CASE WHEN report.Code = 'S847' THEN 0 ELSE NULL END) AS S847,
SUM(CASE WHEN report.Code = 'S190' THEN 0 ELSE NULL END) AS S190,
SUM(CASE WHEN report.Code = 'S191' THEN 0 ELSE NULL END) AS S191,
SUM(CASE WHEN report.Code = 'S848' THEN 0 ELSE NULL END) AS S848,
SUM(CASE WHEN report.Code = 'S192' THEN 0 ELSE NULL END) AS S192
INTO    #Runs          
FROM    dbo.CoreProcessRun run          
INNER JOIN dbo.RefProcess process ON process.RefProcessId = run.RefProcessId          
INNER JOIN dbo.RefAmlReport report ON process.RefAmlReportId = report.RefAmlReportId          
WHERE   ( ( @Type = 'SystemDate'          
AND run.ScheduledAt BETWEEN @FromDate          
AND DATEADD(DAY, 1, @ToDate)          
 )          
 OR ( @Type = 'RunDate'          
  AND run.RunDate BETWEEN @FromDate AND @ToDate      
)          
)          
AND process.RefAmlReportId IS NOT NULL          
AND run.RunEventTypeId = 4 -- success          
 GROUP BY      
CASE WHEN @Type = 'SystemDate' THEN dbo.GetDateWithoutTime(run.ScheduledAt)      
ELSE dbo.GetDateWithoutTime(run.RunDate) END          
      
-- populate 0 for all those dates for which the process ran but there is no alert          
 UPDATE result          
 SET          
  S1 = CASE WHEN result.S1 IS NULL THEN run.S1 ELSE result.S1 END,          
  S2 = CASE WHEN result.S2 IS NULL THEN run.S2 ELSE result.S2 END,          
  S3 = CASE WHEN result.S3 IS NULL THEN run.S3 ELSE result.S3 END,          
  S4 = CASE WHEN result.S4 IS NULL THEN run.S4 ELSE result.S4 END,          
  S5 = CASE WHEN result.S5 IS NULL THEN run.S5 ELSE result.S5 END,          
  S6 = CASE WHEN result.S6 IS NULL THEN run.S6 ELSE result.S6 END,          
  S7 = CASE WHEN result.S7 IS NULL THEN run.S7 ELSE result.S7 END,          
  S8 = CASE WHEN result.S8 IS NULL THEN run.S8 ELSE result.S8 END,          
  S9 = CASE WHEN result.S9 IS NULL THEN run.S9 ELSE result.S9 END,          
  S10 = CASE WHEN result.S10 IS NULL THEN run.S10 ELSE result.S10 END,          
  S11 = CASE WHEN result.S11 IS NULL THEN run.S11 ELSE result.S11 END,          
  S12 = CASE WHEN result.S12 IS NULL THEN run.S12 ELSE result.S12 END,          
  S13 = CASE WHEN result.S13 IS NULL THEN run.S13 ELSE result.S13 END,          
  S14 = CASE WHEN result.S14 IS NULL THEN run.S14 ELSE result.S14 END,          
  S15 = CASE WHEN result.S15 IS NULL THEN run.S15 ELSE result.S15 END,          
  S16 = CASE WHEN result.S16 IS NULL THEN run.S16 ELSE result.S16 END,          
  S17 = CASE WHEN result.S17 IS NULL THEN run.S17 ELSE result.S17 END,          
  S18 = CASE WHEN result.S18 IS NULL THEN run.S18 ELSE result.S18 END,            
  S19 = CASE WHEN result.S19 IS NULL THEN run.S19 ELSE result.S19 END,          
  S20 = CASE WHEN result.S20 IS NULL THEN run.S20 ELSE result.S20 END,          
  S21 = CASE WHEN result.S21 IS NULL THEN run.S21 ELSE result.S21 END,          
  S22 = CASE WHEN result.S22 IS NULL THEN run.S22 ELSE result.S22 END,          
  S23 = CASE WHEN result.S23 IS NULL THEN run.S23 ELSE result.S23 END,          
  S24 = CASE WHEN result.S24 IS NULL THEN run.S24 ELSE result.S24 END,          
  S25 = CASE WHEN result.S25 IS NULL THEN run.S25 ELSE result.S25 END,          
  S26 = CASE WHEN result.S26 IS NULL THEN run.S26 ELSE result.S26 END,          
  S27 = CASE WHEN result.S27 IS NULL THEN run.S27 ELSE result.S27 END,          
  S28 = CASE WHEN result.S28 IS NULL THEN run.S28 ELSE result.S28 END,        
  S29 = CASE WHEN result.S29 IS NULL THEN run.S29 ELSE result.S29 END,            
  S30 = CASE WHEN result.S30 IS NULL THEN run.S30 ELSE result.S30 END,          
  S31 = CASE WHEN result.S31 IS NULL THEN run.S31 ELSE result.S31 END,              
  S32 = CASE WHEN result.S32 IS NULL THEN run.S32 ELSE result.S32 END,          
  S33 = CASE WHEN result.S33 IS NULL THEN run.S33 ELSE result.S33 END,          
  S34 = CASE WHEN result.S34 IS NULL THEN run.S34 ELSE result.S34 END,          
  S35 = CASE WHEN result.S35 IS NULL THEN run.S35 ELSE result.S35 END,          
  S36 = CASE WHEN result.S36 IS NULL THEN run.S36 ELSE result.S36 END,          
  S37 = CASE WHEN result.S37 IS NULL THEN run.S37 ELSE result.S37 END,            
  S38 = CASE WHEN result.S38 IS NULL THEN run.S38 ELSE result.S38 END,          
  S39 = CASE WHEN result.S39 IS NULL THEN run.S39 ELSE result.S39 END,          
  S40 = CASE WHEN result.S40 IS NULL THEN run.S40 ELSE result.S40 END,          
  S41 = CASE WHEN result.S41 IS NULL THEN run.S41 ELSE result.S41 END,          
  S42 = CASE WHEN result.S42 IS NULL THEN run.S42 ELSE result.S42 END,            
  S43 = CASE WHEN result.S43 IS NULL THEN run.S43 ELSE result.S43 END,          
  S44 = CASE WHEN result.S44 IS NULL THEN run.S44 ELSE result.S44 END,          
  S45 = CASE WHEN result.S45 IS NULL THEN run.S45 ELSE result.S45 END,          
  S46 = CASE WHEN result.S46 IS NULL THEN run.S46 ELSE result.S46 END,          
  S47 = CASE WHEN result.S47 IS NULL THEN run.S47 ELSE result.S47 END,          
  S48 = CASE WHEN result.S48 IS NULL THEN run.S48 ELSE result.S48 END,      
  S50 = CASE WHEN result.S50 IS NULL THEN run.S50 ELSE result.S50 END,            
  S51 = CASE WHEN result.S51 IS NULL THEN run.S50 ELSE result.S51 END,        
  S52 = CASE WHEN result.S52 IS NULL THEN run.S52 ELSE result.S52 END,            
  S53 = CASE WHEN result.S53 IS NULL THEN run.S53 ELSE result.S53 END,          
  S54 = CASE WHEN result.S54 IS NULL THEN run.S54 ELSE result.S54 END,            
  S55 = CASE WHEN result.S55 IS NULL THEN run.S55 ELSE result.S55 END,          
  S56 = CASE WHEN result.S56 IS NULL THEN run.S56 ELSE result.S56 END,          
  S57 = CASE WHEN result.S57 IS NULL THEN run.S57 ELSE result.S57 END,          
  S58 = CASE WHEN result.S58 IS NULL THEN run.S58 ELSE result.S58 END,            
  S59 = CASE WHEN result.S59 IS NULL THEN run.S59 ELSE result.S59 END,          
  S60 = CASE WHEN result.S60 IS NULL THEN run.S60 ELSE result.S60 END,              
  S62 = CASE WHEN result.S62 IS NULL THEN run.S62 ELSE result.S62 END,              
  S63 = CASE WHEN result.S63 IS NULL THEN run.S63 ELSE result.S63 END,          
  S64 = CASE WHEN result.S64 IS NULL THEN run.S64 ELSE result.S64 END,          
  S65 = CASE WHEN result.S65 IS NULL THEN run.S65 ELSE result.S65 END,          
  S66 = CASE WHEN result.S66 IS NULL THEN run.S66 ELSE result.S66 END,          
  S72 = CASE WHEN result.S72 IS NULL THEN run.S72 ELSE result.S72 END,          
  S73 = CASE WHEN result.S73 IS NULL THEN run.S73 ELSE result.S73 END,          
  S74 = CASE WHEN result.S74 IS NULL THEN run.S74 ELSE result.S74 END,          
  S75 = CASE WHEN result.S75 IS NULL THEN run.S75 ELSE result.S75 END,          
  S76 = CASE WHEN result.S76 IS NULL THEN run.S76 ELSE result.S76 END,          
  S77 = CASE WHEN result.S77 IS NULL THEN run.S77 ELSE result.S77 END,          
  S78 = CASE WHEN result.S78 IS NULL THEN run.S78 ELSE result.S78 END,          
  S79 = CASE WHEN result.S79 IS NULL THEN run.S79 ELSE result.S79 END,          
  S80 = CASE WHEN result.S80 IS NULL THEN run.S80 ELSE result.S80 END,          
  S82 = CASE WHEN result.S82 IS NULL THEN run.S82 ELSE result.S82 END,          
  S83 = CASE WHEN result.S83 IS NULL THEN run.S83 ELSE result.S83 END,          
  S84 = CASE WHEN result.S84 IS NULL THEN run.S84 ELSE result.S84 END,          
  S85 = CASE WHEN result.S85 IS NULL THEN run.S85 ELSE result.S85 END,          
  S88 = CASE WHEN result.S88 IS NULL THEN run.S88 ELSE result.S88 END,      
  S801 = CASE WHEN result.S801 IS NULL THEN run.S801 ELSE result.S801 END,          
  S802 = CASE WHEN result.S802 IS NULL THEN run.S802 ELSE result.S802 END,          
  S803 = CASE WHEN result.S803 IS NULL THEN run.S803 ELSE result.S803 END,          
  S806 = CASE WHEN result.S806 IS NULL THEN run.S806 ELSE result.S806 END,        
  S807 = CASE WHEN result.S807 IS NULL THEN run.S807 ELSE result.S807 END,        
  S90 = CASE WHEN result.S90 IS NULL THEN run.S90 ELSE result.S90 END,        
  S92 = CASE WHEN result.S92 IS NULL THEN run.S92 ELSE result.S92 END,        
  S511 = CASE WHEN result.S511 IS NULL THEN run.S511 ELSE result.S511 END,        
  S512 = CASE WHEN result.S512 IS NULL THEN run.S512 ELSE result.S512 END,        
  S701 = CASE WHEN result.S701 IS NULL THEN run.S701 ELSE result.S701 END,        
  S702 = CASE WHEN result.S702 IS NULL THEN run.S702 ELSE result.S702 END,        
  S703 = CASE WHEN result.S703 IS NULL THEN run.S703 ELSE result.S703 END,        
  S704 = CASE WHEN result.S704 IS NULL THEN run.S704 ELSE result.S704 END,            
  S705 = CASE WHEN result.S705 IS NULL THEN run.S705 ELSE result.S705 END,        
  S707 = CASE WHEN result.S707 IS NULL THEN run.S707 ELSE result.S707 END,        
  S708 = CASE WHEN result.S708 IS NULL THEN run.S708 ELSE result.S708 END,        
  S706 = CASE WHEN result.S706 IS NULL THEN run.S706 ELSE result.S706 END,        
  S402 = CASE WHEN result.S402 IS NULL THEN run.S402 ELSE result.S402 END,        
  S86 = CASE WHEN result.S86 IS NULL THEN run.S86 ELSE result.S86 END,        
  S87 = CASE WHEN result.S87 IS NULL THEN run.S87 ELSE result.S87 END ,      
  S89 = CASE WHEN result.S89 IS NULL THEN run.S89 ELSE result.S89 END,      
  S95 = CASE WHEN result.S95 IS NULL THEN run.S95 ELSE result.S95 END ,      
  S49 = CASE WHEN result.S49 IS NULL THEN run.S49 ELSE result.S49 END,      
  S513 = CASE WHEN result.S513 IS NULL THEN run.S513 ELSE result.S513 END,      
  S401 = CASE WHEN result.S401 IS NULL THEN run.S401 ELSE result.S401 END,      
  S501 = CASE WHEN result.S501 IS NULL THEN run.S501 ELSE result.S501 END,      
  S502 = CASE WHEN result.S502 IS NULL THEN run.S502 ELSE result.S502 END,      
  S503 = CASE WHEN result.S503 IS NULL THEN run.S503 ELSE result.S503 END,      
  S504 = CASE WHEN result.S504 IS NULL THEN run.S504 ELSE result.S504 END,      
  S505 = CASE WHEN result.S505 IS NULL THEN run.S505 ELSE result.S505 END,      
  S506 = CASE WHEN result.S506 IS NULL THEN run.S506 ELSE result.S506 END,      
  S507 = CASE WHEN result.S507 IS NULL THEN run.S507 ELSE result.S507 END,      
  S508 = CASE WHEN result.S508 IS NULL THEN run.S508 ELSE result.S508 END,      
  S509 = CASE WHEN result.S509 IS NULL THEN run.S509 ELSE result.S509 END,      
  S510 = CASE WHEN result.S510 IS NULL THEN run.S510 ELSE result.S510 END,      
  S817 = CASE WHEN result.S817 IS NULL THEN run.S817 ELSE result.S817 END,      
  S91 = CASE WHEN result.S91 IS NULL THEN run.S91 ELSE result.S91 END,      
  S96 = CASE WHEN result.S96 IS NULL THEN run.S96 ELSE result.S96 END,      
  S97 = CASE WHEN result.S97 IS NULL THEN run.S97 ELSE result.S97 END,      
  S98 = CASE WHEN result.S98 IS NULL THEN run.S98 ELSE result.S98 END,      
  S808 = CASE WHEN result.S808 IS NULL THEN run.S808 ELSE result.S808 END,      
  S809 = CASE WHEN result.S808 IS NULL THEN run.S809 ELSE result.S809 END,      
   S810 = CASE WHEN result.S810 IS NULL THEN run.S810 ELSE result.S810 END,      
   S811 = CASE WHEN result.S811 IS NULL THEN run.S811 ELSE result.S811 END,      
   S812 = CASE WHEN result.S812 IS NULL THEN run.S812 ELSE result.S812 END,      
   S514 = CASE WHEN result.S514 IS NULL THEN run.S514 ELSE result.S514 END,      
S515 = CASE WHEN result.S515 IS NULL THEN run.S515 ELSE result.S515 END,      
S517 = CASE WHEN result.S517 IS NULL THEN run.S517 ELSE result.S517 END,      
S516 = CASE WHEN result.S516 IS NULL THEN run.S516 ELSE result.S516 END,      
S99 = CASE WHEN result.S99 IS NULL THEN run.S99 ELSE result.S99 END,      
S520 = CASE WHEN result.S520 IS NULL THEN run.S520 ELSE result.S520 END,      
S522 = CASE WHEN result.S522 IS NULL THEN run.S522 ELSE result.S522 END,      
S101 = CASE WHEN result.S101 IS NULL THEN run.S101 ELSE result.S101 END,      
S804 = CASE WHEN result.S804 IS NULL THEN run.S804 ELSE result.S804 END,      
S103 = CASE WHEN result.S103 IS NULL THEN run.S103 ELSE result.S103 END,      
S100 = CASE WHEN result.S100 IS NULL THEN run.S100 ELSE result.S100 END,      
S521 = CASE WHEN result.S521 IS NULL THEN run.S521 ELSE result.S521 END,      
S519 = CASE WHEN result.S519 IS NULL THEN run.S521 ELSE result.S519 END,      
S107 = CASE WHEN result.S107 IS NULL THEN run.S107 ELSE result.S107 END,      
S108 = CASE WHEN result.S108 IS NULL THEN run.S108 ELSE result.S108 END,      
S105 = CASE WHEN result.S105 IS NULL THEN run.S105 ELSE result.S105 END,      
S106 = CASE WHEN result.S106 IS NULL THEN run.S106 ELSE result.S106 END,      
S110 = CASE WHEN result.S110 IS NULL THEN run.S110 ELSE result.S110 END,      
S102 = CASE WHEN result.S102 IS NULL THEN run.S102 ELSE result.S102 END,      
S104 = CASE WHEN result.S104 IS NULL THEN run.S104 ELSE result.S104 END,      
S814 = CASE WHEN result.S814 IS NULL THEN run.S814 ELSE result.S814 END,      
S815 = CASE WHEN result.S815 IS NULL THEN run.S815 ELSE result.S815 END,      
S111 = CASE WHEN result.S111 IS NULL THEN run.S111 ELSE result.S111 END,      
S518 = CASE WHEN result.S518 IS NULL THEN run.S518 ELSE result.S518 END,      
S112 = CASE WHEN result.S112 IS NULL THEN run.S112 ELSE result.S112 END,      
S114 = CASE WHEN result.S114 IS NULL THEN run.S114 ELSE result.S114 END,      
S115 = CASE WHEN result.S115 IS NULL THEN run.S115 ELSE result.S115 END,      
S113 = CASE WHEN result.S113 IS NULL THEN run.S113 ELSE result.S113 END,      
S116 = CASE WHEN result.S116 IS NULL THEN run.S116 ELSE result.S116 END,      
S118 = CASE WHEN result.S118 IS NULL THEN run.S118 ELSE result.S118 END,      
S117 = CASE WHEN result.S117 IS NULL THEN run.S117 ELSE result.S117 END,      
S119 = CASE WHEN result.S119 IS NULL THEN run.S119 ELSE result.S119 END,      
S523 = CASE WHEN result.S523 IS NULL THEN run.S523 ELSE result.S523 END,      
S120 = CASE WHEN result.S120 IS NULL THEN run.S120 ELSE result.S120 END,      
S122 = CASE WHEN result.S122 IS NULL THEN run.S122 ELSE result.S122 END,      
S121 = CASE WHEN result.S121 IS NULL THEN run.S121 ELSE result.S121 END,      
S123 = CASE WHEN result.S123 IS NULL THEN run.S123 ELSE result.S123 END,      
S525 = CASE WHEN result.S525 IS NULL THEN run.S525 ELSE result.S525 END,      
S524 = CASE WHEN result.S524 IS NULL THEN run.S524 ELSE result.S524 END,      
S126 = CASE WHEN result.S126 IS NULL THEN run.S126 ELSE result.S126 END,      
S127 = CASE WHEN result.S127 IS NULL THEN run.S127 ELSE result.S127 END,      
S526 = CASE WHEN result.S526 IS NULL THEN run.S526 ELSE result.S526 END,      
S129 = CASE WHEN result.S129 IS NULL THEN run.S129 ELSE result.S129 END,      
S124 = CASE WHEN result.S124 IS NULL THEN run.S124 ELSE result.S124 END,      
S128 = CASE WHEN result.S128 IS NULL THEN run.S128 ELSE result.S128 END,      
S125 = CASE WHEN result.S125 IS NULL THEN run.S125 ELSE result.S125 END,      
S144 = CASE WHEN result.S144 IS NULL THEN run.S144 ELSE result.S144 END,      
S145 = CASE WHEN result.S145 IS NULL THEN run.S145 ELSE result.S145 END,      
S146 = CASE WHEN result.S146 IS NULL THEN run.S146 ELSE result.S146 END,      
S147 = CASE WHEN result.S147 IS NULL THEN run.S147 ELSE result.S147 END,      
S148 = CASE WHEN result.S148 IS NULL THEN run.S148 ELSE result.S148 END,      
S149 = CASE WHEN result.S149 IS NULL THEN run.S149 ELSE result.S149 END,      
S151 = CASE WHEN result.S151 IS NULL THEN run.S151 ELSE result.S151 END,      
S152 = CASE WHEN result.S152 IS NULL THEN run.S152 ELSE result.S152 END,      
S153 = CASE WHEN result.S153 IS NULL THEN run.S153 ELSE result.S153 END,      
S154 = CASE WHEN result.S154 IS NULL THEN run.S154 ELSE result.S154 END,      
S155 = CASE WHEN result.S155 IS NULL THEN run.S155 ELSE result.S155 END,      
S157 = CASE WHEN result.S157 IS NULL THEN run.S157 ELSE result.S157 END,      
S156 = CASE WHEN result.S156 IS NULL THEN run.S156 ELSE result.S156 END,      
S158 = CASE WHEN result.S158 IS NULL THEN run.S158 ELSE result.S158 END,      
S159 = CASE WHEN result.S159 IS NULL THEN run.S159 ELSE result.S159 END,      
S160 = CASE WHEN result.S160 IS NULL THEN run.S160 ELSE result.S160 END,      
S171 = CASE WHEN result.S171 IS NULL THEN run.S171 ELSE result.S171 END,      
S832 = CASE WHEN result.S832 IS NULL THEN run.S832 ELSE result.S832 END,      
S833 = CASE WHEN result.S833 IS NULL THEN run.S833 ELSE result.S833 END,      
S834 = CASE WHEN result.S834 IS NULL THEN run.S834 ELSE result.S834 END,      
S172 = CASE WHEN result.S172 IS NULL THEN run.S172 ELSE result.S172 END,      
S161 = CASE WHEN result.S161 IS NULL THEN run.S161 ELSE result.S161 END,      
S162 = CASE WHEN result.S162 IS NULL THEN run.S162 ELSE result.S162 END,      
S836 = CASE WHEN result.S836 IS NULL THEN run.S836 ELSE result.S836 END,      
S835 = CASE WHEN result.S835 IS NULL THEN run.S835 ELSE result.S835 END,      
S173 = CASE WHEN result.S173 IS NULL THEN run.S173 ELSE result.S173 END,      
S163 = CASE WHEN result.S163 IS NULL THEN run.S163 ELSE result.S163 END,      
S164 = CASE WHEN result.S164 IS NULL THEN run.S164 ELSE result.S164 END,      
S174 = CASE WHEN result.S174 IS NULL THEN run.S174 ELSE result.S174 END,      
S166 = CASE WHEN result.S166 IS NULL THEN run.S166 ELSE result.S166 END,      
S837 = CASE WHEN result.S837 IS NULL THEN run.S837 ELSE result.S837 END,      
S165 = CASE WHEN result.S165 IS NULL THEN run.S165 ELSE result.S165 END,      
S838 = CASE WHEN result.S838 IS NULL THEN run.S838 ELSE result.S838 END,      
S839 = CASE WHEN result.S839 IS NULL THEN run.S839 ELSE result.S839 END,      
S167 = CASE WHEN result.S167 IS NULL THEN run.S167 ELSE result.S167 END,      
S840 = CASE WHEN result.S840 IS NULL THEN run.S840 ELSE result.S840 END,      
S841 = CASE WHEN result.S841 IS NULL THEN run.S841 ELSE result.S841 END,      
S527 = CASE WHEN result.S527 IS NULL THEN run.S527 ELSE result.S527 END,      
S175 = CASE WHEN result.S175 IS NULL THEN run.S175 ELSE result.S175 END,      
S176 = CASE WHEN result.S176 IS NULL THEN run.S176 ELSE result.S176 END,      
S177 = CASE WHEN result.S177 IS NULL THEN run.S177 ELSE result.S177 END,      
S180 = CASE WHEN result.S180 IS NULL THEN run.S180 ELSE result.S180 END,      
S181 = CASE WHEN result.S181 IS NULL THEN run.S181 ELSE result.S181 END,      
S179 = CASE WHEN result.S179 IS NULL THEN run.S179 ELSE result.S179 END,      
S182 = CASE WHEN result.S182 IS NULL THEN run.S182 ELSE result.S182 END,      
S183 = CASE WHEN result.S183 IS NULL THEN run.S183 ELSE result.S183 END,    
S178 = CASE WHEN result.S178 IS NULL THEN run.S178 ELSE result.S178 END,      
S184 = CASE WHEN result.S184 IS NULL THEN run.S184 ELSE result.S184 END,      
S168 = CASE WHEN result.S168 IS NULL THEN run.S168 ELSE result.S168 END,      
S169 = CASE WHEN result.S169 IS NULL THEN run.S169 ELSE result.S169 END,      
S143 = CASE WHEN result.S143 IS NULL THEN run.S169 ELSE result.S143 END,      
S185 = CASE WHEN result.S185 IS NULL THEN run.S169 ELSE result.S185 END,      
S843 = CASE WHEN result.S843 IS NULL THEN run.S169 ELSE result.S843 END,      
S844 = CASE WHEN result.S844 IS NULL THEN run.S169 ELSE result.S844 END,      
S842 = CASE WHEN result.S842 IS NULL THEN run.S169 ELSE result.S842 END,
S170 = CASE WHEN result.S170 IS NULL THEN run.S170 ELSE result.S170 END,
S845 = CASE WHEN result.S845 IS NULL THEN run.S845 ELSE result.S845 END,
S186 = CASE WHEN result.S186 IS NULL THEN run.S186 ELSE result.S186 END,
S846 = CASE WHEN result.S846 IS NULL THEN run.S846 ELSE result.S846 END,
S187 = CASE WHEN result.S187 IS NULL THEN run.S187 ELSE result.S187 END,
S188 = CASE WHEN result.S188 IS NULL THEN run.S188 ELSE result.S188 END,
S189 = CASE WHEN result.S189 IS NULL THEN run.S189 ELSE result.S189 END,
S847 = CASE WHEN result.S847 IS NULL THEN run.S847 ELSE result.S847 END,
S190 = CASE WHEN result.S190 IS NULL THEN run.S190 ELSE result.S190 END,
S191 = CASE WHEN result.S191 IS NULL THEN run.S191 ELSE result.S191 END,
S848 = CASE WHEN result.S848 IS NULL THEN run.S848 ELSE result.S848 END,
S192 = CASE WHEN result.S192 IS NULL THEN run.S192 ELSE result.S192 END
 FROM #Result result      
 INNER JOIN #Runs run ON result.Date = run.Date      
      
 SELECT      
  [Date],          
  S1,          
  S2,          
  S3,          
  S4,          
  S5,          
  S6,          
  S7,          
  S8,          
  S9,          
  S10,          
  S11,          
  S12,          
  S13,          
  S14,          
  S15,          
  S16,          
  S17,          
  S18,            
  S19,          
  S20,          
  S21,          
  S22,          
  S23,          
  S24,          
  S25,          
  S26,          
  S27,          
  S28,          
  S29,          
  S30,          
  S31,          
  S32,          
  S33,          
  S34,          
  S35,          
  S36,          
  S37,          
  S38,          
  S39,          
  S40,          
  S41,          
  S42,            
  S43,          
  S44,          
  S45,          
  S46,          
  S47,          
  S48,      
  S50,          
  S51,          
  S52,          
  S53,          
  S54,            
  S55,          
  S56,          
  S57,          
  S58,            
  S59,          
  S60,            
  S62,          
  S63,          
  S64,          
  S65,          
  S66,          
  S72,          
  S73,          
  S74,          
  S75,          
  S76,          
  S77,          
  S78,          
  S79,          
  S80,          
  S82,          
  S83,          
  S84,          
  S85,          
  S88,      
  S801,          
  S802,          
  S803,          
  S806,        
  S807,        
  S90,        
  S92,        
  S511,        
  S512,        
  S701,        
  S702,        
  S703,        
  S704,        
  S705,        
  S707,        
  S708,        
  S706,        
  S402,        
  S86,        
  S87,      
  S89,      
  S95,      
  S49,      
  S513,      
  S401,      
  S501,      
  S502,      
  S503,      
  S504,      
  S505,      
  S506,      
  S507,      
  S508,      
  S509,      
  S510,      
  S817,      
  S91,      
  S96,      
  S97,      
  S98,      
  S808,      
  S809,      
  S810,      
  S811,      
  S812,      
  S514,      
  S515,      
  S517,      
  S516,      
  S99,      
  S520,      
  S522,      
  S101,      
  S804,      
  S103,      
  S100,      
  S521,      
  S519,      
  S108,      
  S107,      
  S105,      
  S106,      
  S102,      
  S110,      
  S104,      
  S814,      
  S815,      
  S111,      
  S518,      
  S112,      
  S114,      
  S115,      
  S113,      
  S116,      
  S118,      
  S117,      
  S119,      
  S523,      
  S120,      
  S122,      
  S121,      
  S123,      
  S525,      
  S524,      
  S126,      
  S127,      
  S526,      
  S129,      
  S124,      
  S128,      
 S125,      
  S144,      
  S145,      
  S146,      
  S147,      
  s148,      
  S149,      
  S151,      
  S152,      
  S153,      
  S154,      
  S155,      
  S157,      
  S156,      
  S158,      
  S159,      
  S160,      
  S171,      
  S832,      
  S833,      
  S834,      
  S172,      
  S161,      
  S162,      
  S836,      
  S835,      
  S173,      
  S163,      
  S164,      
  S174,      
  S166,      
  S837,      
  S165,      
  S838,      
  S839,      
  S167,      
  S840,      
  S841,      
  S527,      
  S175,      
  S176,      
  S177,      
  S180,      
  S181,      
  S179,      
  S182,      
  S183,    
  S178,    
  S184,    
  S168,    
  S169,  
  S143,  
  S185,  
  S843,  
  S844,  
  S842,
  S170,
  S845,
  S186,
  S846,
  S187,
  S188,
  S189,
  S847,
  S190,
  S191,
  S848,
  S192
  FROM #Result              
END     
GO
--WEB-77553 SC END

  select * from CoreAmlScenarioAlert dd where 1228 = dd.RefAmlReportId
  select * from RefAmlReport where Code ='S832'