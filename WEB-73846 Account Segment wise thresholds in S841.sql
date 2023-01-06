--WEB-73846 RC START
GO
DECLARE @S841Id INT, @IncreaseInTOValue DECIMAL(28,2), @HoldingTxnValue DECIMAL(28,2), @CurrentMonthTxnValue DECIMAL(28,2)

SELECT @S841Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S841 Sudden Increase in Transactions and Holding Decrease Significantly'

SELECT @IncreaseInTOValue = CONVERT(DECIMAL(28,2),[Value])
FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S841Id AND [Name] = 'Threshold_Percentage'

SELECT @HoldingTxnValue = CONVERT(DECIMAL(28,2),[Value])
FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S841Id AND [Name] = 'Transaction_Value'

SELECT @CurrentMonthTxnValue = CONVERT(DECIMAL(28,2),[Value])
FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S841Id AND [Name] = 'Quantity'

INSERT INTO dbo.RefAmlScenarioRule
(
	RuleNumber,
	RefAmlReportId,
	Threshold,
	Threshold2,
	Threshold3,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn
)
SELECT
	ISNULL((SELECT MAX(RuleNumber) FROM dbo.RefAmlScenarioRule)+1,1),
	@S841Id,
	ISNULL( @IncreaseInTOValue ,0),
	ISNULL( @HoldingTxnValue ,0),
	ISNULL( @CurrentMonthTxnValue ,0),
	'System',
	GETDATE(),
	'System',
	GETDATE()
GO
--WEB-73846 RC END
--WEB-73846 RC START
GO
DECLARE @S841Id INT, @RuleId INT

SELECT @S841Id = RefAmlReportId FROM dbo.RefAmlReport
WHERE [Name] = 'S841 Sudden Increase in Transactions and Holding Decrease Significantly'

SELECT @RuleId = RefAmlScenarioRuleId FROM dbo.RefAmlScenarioRule WHERE RefAmlReportId = @S841Id

INSERT INTO dbo.LinkRefAmlScenarioRuleRefCustomerSegment
(
	RefAmlScenarioRuleId,
	RefCustomerSegmentId,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn
)
SELECT
	ISNULL(@RuleId,1),
	NULL,
	'System',
	GETDATE(),
	'System',
	GETDATE()
GO
--WEB-73846 RC END
--WEB-73846 RC START
GO
UPDATE dbo.RefAmlReport
SET
	Threshold1DisplayName = '% of Increse in TO from previous calendar month',
	Threshold2DisplayName = 'Holding % vis Txn value<=',
	Threshold3DisplayName = 'Current month Txn value =>',
	[Description] = 
	'This scenario will help us to identify the Client who does sudden increase in transactions activity and after some time holding decreases significantly <br>    
	Segments: CDSL, NSDL; <br>    
	Period = Calendar month. This scenario will run for past 2 months from the run date. ( E.g. If the scenario is run for rundate 5 Nov, then it will be consider Txn, Holding data and generate alerts for the months of Oct and Sept. ) <br>    
	<b>Thresholds:</b> <br>    
	1. <b>Current month transaction value:</b> This is the total amount of High Value Transactions done by the client in the last previous month compared to the run date in all the scrips. System will generate alert If this ''X'' Transaction value is greater than or equal to the set threshold. <br>    
	2. <b>% of Increase in Txn value:</b> It is the increase in the % of the total transaction value compared from the current month Txn value to the previous calendar month transaction value. System will generate alert If this ''X'' % of increase in Transaction value is greater than or equal to the set threshold. <br>    
	3. <b>Holding % vis Txn value:</b> It is the decrease in % of the total transaction value compared to the Holding value as on last day of the current month. System will generate alert If this ''X'' % of decrease in Holding value is less than or equal to the set threshold. <br>    
	4. <b>No. of days from A/C open:</b> This is the number of days system will consider to find the total transactions and Holding of the client from the Account Opening Date.  The difference of Acc Opening Date and ''Txn To'' Date will be less than the No. of Days Acc open threshold. System will generate alert If this ''X'' No. of days is less than or equal to the set threshold. <br>    
	5. <b>Account Segment:</b> Account segment mapped to the DP account<br>    
	<b>Note: </b><br>    1. Files considered for this scenario are as follows: <br>    <b>CDSL</b> = Transaction file, CD03, Closing Price file <br>    <b>NSDL</b> =  Sec Master, Closing Price file, COD file <br>    
	2. Two different alerts will be generated for CDSL & NSDL. <br>    
	3. The Total Transaction value will be the sum of both Debit & Credit Transactions.'
WHERE [Name] = 'S841 Sudden Increase in Transactions and Holding Decrease Significantly'
GO
--WEB-73846 RC END
--WEB-73846 RC START
GO
DECLARE @S841Id INT

SELECT @S841Id = RefAmlReportId FROM dbo.RefAmlReport
WHERE [Name] = 'S841 Sudden Increase in Transactions and Holding Decrease Significantly'

DELETE makerChecker FROM
dbo.CoreAmlScenarioRuleMakerChecker makerChecker
INNER JOIN dbo.SysAmlReportSetting sett ON makerChecker.SysAmlReportSettingId = sett.SysAmlReportSettingId
AND sett.RefAmlReportId = @S841Id AND sett.[Name] <> 'Number_Of_Days'

DELETE FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S841Id AND [Name] <>'Number_Of_Days'
GO
--WEB-73846 RC END
--WEB-73846 RC START
GO
  ALTER PROCEDURE dbo.AML_GetSuddenIncreaseinTransactionsandHoldingDecreaseSignificantly (  
 @RunDate DATETIME,    
 @ReportId INT,  
 @IsDuplicateAllowed BIT=0  
)    
AS    
BEGIN    
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @NsdlId INT, @CdslId INT, @CurFromDate DATETIME,     
  @CurToDate DATETIME, @CurToDateWOTime DATETIME, @PreFromDate DATETIME, @PreToDate DATETIME, @HolCurDate DATETIME, @HolPreDate DATETIME,  
  @NoOfDays INT,@DBCdslId INT, @DBNsdlId INT  ,@HoldingDate DATETIME  
    
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)    
 SET @ReportIdInternal = @ReportId    
 SET @CurFromDate = DATEADD(mm, DATEDIFF(mm, 0, @RunDateInternal) - 1, 0)    
 SET @CurToDate = DATEADD(DAY, -(DAY(@RunDateInternal)), @RunDateInternal) + CONVERT(DATETIME, '23:59:59.000')    
 SET @CurToDateWOTime = dbo.GetDateWithoutTime(@CurToDate)    
 SET @PreFromDate = DATEADD(mm, DATEDIFF(mm, 0, @CurFromDate) - 1, 0)    
 SET @PreToDate = DATEADD(DAY, -(DAY(@CurFromDate)), @CurFromDate) + CONVERT(DATETIME, '23:59:59.000')    
  
 SET @HolCurDate = DATEADD(DAY, -3, @CurToDateWOTime)  
 SET @HolPreDate = DATEADD(DAY, -3, dbo.GetDateWithoutTime(@PreToDate))  
 SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'CDSL'    
 SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSDL'    
 SELECT @DBCdslId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'    
 SELECT @DBNsdlId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'    
    
 SELECT @NoOfDays = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Days'    
 

 SELECT
	rules.RefAmlScenarioRuleId,
	linkCS.RefCustomerSegmentId,
	CONVERT(DECIMAL(28, 2), rules.Threshold) AS Threshold,
	CONVERT(DECIMAL(28, 2), rules.Threshold2) AS Threshold2,
	CONVERT(DECIMAL(28, 2), rules.Threshold3) AS Threshold3
 INTO #scenarioRules
 FROM dbo.RefAmlScenarioRule rules
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefCustomerSegment linkCS ON rules.RefAmlScenarioRuleId = linkCS.RefAmlScenarioRuleId
 WHERE rules.RefAmlReportId = @ReportIdInternal 
    
 SELECT    
  RefClientId    
 INTO #clientsToExclude    
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
 WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportIdInternal)   
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)    
    
 SELECT    
  cl.RefClientId    
 INTO #clients    
 FROM dbo.RefClient cl    
 LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = cl.RefClientId    
 WHERE cl.RefClientDatabaseEnumId IN (@DBCdslId, @DBNsdlId) AND clEx.RefClientId IS NULL    
  AND DATEDIFF(DAY, cl.AccountOpeningDate, @CurToDateWOTime) <= @NoOfDays    
    
 DROP TABLE #clientsToExclude    
  
 CREATE TABLE #curTradeData (    
  RefClientId INT,    
  RefSegmentId INT,    
  RefIsinId INT,    
  Quantity INT,    
  BusinessDate DATETIME    
 )   
   
 CREATE TABLE #CdslTypeStatus (        
  CdslType INT,        
  CdslCode INT,  
 )  
  
 INSERT INTO #CdslTypeStatus VALUES (2,305),(3,305),(5,511),(1,109),(4,408),(6,605),(7,702),(8,810),(9,913),(10,1002),  
 (11,1103),(12,1201),(12,1203),(15,1503),(16,1603),(17,1701),(17,1707),(18,1801),(18,1807),(20,2001),(20,2002),(21,2101),(21,2102),  
 (21,2103),(21,2104),(22,2205),(23,2302),(24,2402),(26,2603),(27,2703),(28,2803),(29,2903),(30,3001),(32,3203),(33,3301),  
 (34,3401),(35,3502),(36,3602)  
  
 SELECT   
 dpt.RefDpTransactionTypeId,  
 dps.RefDpTransactionStatusId  
 INTO #FilteredCdslType  
 FROM dbo.RefDpTransactionType dpt   
 INNER JOIN #CdslTypeStatus cts ON dpt.CdslCode = cts.CdslType   
 LEFT JOIN dbo.RefDpTransactionStatus dps ON cts.CdslCode = dps.CdslCode  
  
 DROP TABLE #CdslTypeStatus  
  
 CREATE TABLE #NsdlTypeStatus (        
  NsdlType INT,     
  OrderStatusTo INT,  
 )  
  
 Declare @var51 INT,@var32 INT ,@var33 INT  
  SET @var51 = 51  
  SET @var32 = 32  
  SET @var33 = 33  
  
 INSERT INTO #NsdlTypeStatus VALUES (801,@var51),(901,@var32),(902,@var32),(904,@var51),(905,@var51),(906,@var51),(912,@var51),(927,@var51)  
 ,(907,@var51),(908,@var51),(909,@var51),(910,@var51),(911,@var51),(916,@var51),(917,@var51),(918,@var51),(919,@var51),(920,@var51)  
 ,(921,@var51),(922,@var51),(923,@var51),(925,@var51),(926,@var51),(934,@var51),(935,@var51),(936,@var51),(937,@var51)  
 ,(940,@var33),(941,@var33),(942,@var51),(949,@var51),(950,@var51),(951,@var51),(952,@var51)  
  
 SELECT dx.RefDpTransactionTypeId,  
 nts.OrderStatusTo   
 INTO #FilteredNsdlType  
 FROM #NsdlTypeStatus nts LEFT JOIN dbo.RefDpTransactionType dx ON nts.NsdlType = dx.NsdlCode AND ISNUMERIC(dx.NsdlCode) = 1  
 WHERE dx.RefDpTransactionTypeId IS NOT NULL  
  
 DROP TABLE #NsdlTypeStatus  
  
 INSERT INTO #curTradeData(RefClientId, RefSegmentId, RefIsinId, Quantity, BusinessDate)    
 SELECT    
  dp.RefClientId,    
  dp.RefSegmentId,    
  dp.RefIsinId,    
  dp.Quantity,    
  dp.BusinessDate    
 FROM #clients cl    
 INNER JOIN dbo.CoreDpTransaction dp ON cl.RefClientId = dp.RefClientId  
 INNER JOIN #FilteredCdslType cdslst ON dp.RefDpTransactionStatusId = cdslst.RefDpTransactionStatusId   
 AND dp.RefDpTransactionTypeId = cdslst.RefDpTransactionTypeId    
 WHERE dp.RefSegmentId = @CdslId    
  AND dp.BusinessDate BETWEEN @CurFromDate AND @CurToDate  
    
 INSERT INTO #curTradeData(RefClientId, RefSegmentId, RefIsinId, Quantity, BusinessDate)    
 SELECT     
  dp.RefClientId,    
  dp.RefSegmentId,    
  dp.RefIsinId,    
  CONVERT(INT, dp.Quantity) AS Quantity,    
  dp.ExecutionDate AS BusinessDate    
 FROM #clients cl    
 INNER JOIN dbo.CoreDPTransactionChangeHistory dp ON cl.RefClientId = dp.RefClientId  
 INNER JOIN #FilteredNsdlType nsdt ON dp.RefDpTransactionTypeId = nsdt.RefDpTransactionTypeId AND dp.OrderStatusTo = nsdt.OrderStatusTo  
 WHERE dp.RefSegmentId = @NsdlId    
  AND dp.ExecutionDate BETWEEN @CurFromDate AND @CurToDate    
    
 DROP TABLE #clients    
    
  
  
 SELECT DISTINCT  
  td.RefClientId,    
  td.RefSegmentId,    
  td.RefIsinId  
 INTO #DisClientData  
 FROM #curTradeData td    
  
  
  SELECT TOP 1 holding.AsOfDate   
 INTO #HoldingDate  
 FROM dbo.CoreClientHolding holding   
 WHERE holding.AsOfDate >= @HolCurDate AND holding.AsOfDate <=@CurToDate  
 GROUP BY holding.AsOfDate  
 ORDER BY holding.AsOfDate DESC  
  
  SELECT @HoldingDate=AsOfDate  
 FROM #HoldingDate  
  
  SELECT DISTINCT    
  td.RefClientId,    
  td.RefSegmentId,    
  td.RefIsinId,    
  holding.CoreClientHoldingId,    
  (holding.CurrentBalanceQuantity * ISNULL(cdslBhav.[Close], nsdlBhav.[Close]))  AS HoldingValue  
 INTO #holdingTempData    
 FROM #DisClientData td    
 INNER JOIN dbo.RefClientDematAccount demat ON td.RefClientId = demat.RefClientId    
 LEFT JOIN dbo.CoreClientHolding holding ON demat.RefClientDematAccountId = holding.RefClientDematAccountId    
  AND td.RefIsinId = holding.RefIsinId AND holding.AsOfDate=@HoldingDate  
 LEFT JOIN dbo.CoreDpBhavCopy cdslBhav ON td.RefIsinId = cdslBhav.RefIsinId    
  AND cdslBhav.[Date] = holding.AsOfDate AND cdslBhav.RefSegmentId = @CdslId    
 LEFT JOIN dbo.CoreDpBhavCopy nsdlBhav ON td.RefIsinId = nsdlBhav.RefIsinId    
  AND nsdlBhav.[Date] = holding.AsOfDate AND nsdlBhav.RefSegmentId = @NsdlId    
 WHERE cdslBhav.RefSegmentId IS NOT NULL OR nsdlBhav.RefSegmentId IS NOT NULL  
   
 SELECT   
 temp.RefClientId,  
 temp.RefSegmentId,  
 temp.RefIsinId,  
 hotemp.CoreClientHoldingId,  
 hotemp.HoldingValue  
 INTO #holdingData  
 FROM #DisClientData temp LEFT JOIN #holdingTempData hotemp ON temp.RefClientId = hotemp.RefClientId  
 AND temp.RefSegmentId = hotemp.RefSegmentId AND temp.RefIsinId = hotemp.RefIsinId  
   
 DROP TABLE #DisClientData  
 
 SELECT DISTINCT
	RefClientId
 INTO #distinctClients
 FROM #holdingData

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
 ) t
 WHERE t.RN = 1

 DROP TABLE #distinctClients
    
 SELECT    
  RefClientId,    
  RefSegmentId,    
  SUM(HoldingValue) AS TotalHoldingValue    
 INTO #finalHoldingData    
 FROM #holdingData   
 GROUP BY RefClientId, RefSegmentId    
    
 DROP TABLE #holdingData    
    
 SELECT    
  td.RefClientId,     
  td.RefSegmentId,      
  SUM(td.Quantity * ISNULL(cdslBhav.[Close], nsdlBhav.[Close])) AS TransactionValue    
 INTO #clientWiseData    
 FROM #curTradeData td    
 LEFT JOIN dbo.CoreDpBhavCopy cdslBhav ON td.RefIsinId = cdslBhav.RefIsinId    
  AND cdslBhav.[Date] = td.BusinessDate AND cdslBhav.RefSegmentId = @CdslId    
 LEFT JOIN dbo.CoreDpBhavCopy nsdlBhav ON td.RefIsinId = nsdlBhav.RefIsinId    
  AND nsdlBhav.[Date] = td.BusinessDate AND nsdlBhav.RefSegmentId = @NsdlId    
 WHERE cdslBhav.RefSegmentId IS NOT NULL OR nsdlBhav.RefSegmentId IS NOT NULL    
 GROUP BY td.RefClientId, td.RefSegmentId    
    
 DROP TABLE #curTradeData    
    
 SELECT    
  cl.RefClientId,    
  cl.RefSegmentId,    
  cl.TransactionValue,    
  hold.TotalHoldingValue    
 INTO #curClientWiseData    
 FROM #clientWiseData cl    
 INNER JOIN #finalHoldingData hold ON cl.RefClientId = hold.RefClientId    
  AND cl.RefSegmentId = hold.RefSegmentId    
    
 DROP TABLE #clientWiseData    
 DROP TABLE #finalHoldingData    
    
 SELECT    
  ccsm.RefClientId,    
  RefSegmentId,    
  TransactionValue,    
  TotalHoldingValue,    
  (TotalHoldingValue * 100) / TransactionValue AS [Percentage]    
 INTO #curFilteredData    
 FROM #curClientWiseData cl
 INNER JOIN #clientCSMapping ccsm ON ccsm.RefClientId = cl.RefClientId
 INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1) 
 WHERE (rules.Threshold3 = 0 OR  TransactionValue >= rules.Threshold3 )   
  AND (rules.Threshold2 = 0 OR (TotalHoldingValue * 100) / TransactionValue <= rules.Threshold2 )
    
 DROP TABLE #curClientWiseData    
    
 CREATE TABLE #preTradeData (    
  RefClientId INT,    
  RefSegmentId INT,    
  RefIsinId INT,    
  Quantity INT,    
  BusinessDate DATETIME    
 )    
    
 INSERT INTO #preTradeData(RefClientId, RefSegmentId, RefIsinId, Quantity, BusinessDate)    
 SELECT    
  dp.RefClientId,    
  dp.RefSegmentId,    
  dp.RefIsinId,    
  dp.Quantity,    
  dp.BusinessDate    
 FROM #curFilteredData cl    
 INNER JOIN dbo.CoreDpTransaction dp ON cl.RefClientId = dp.RefClientId  
 INNER JOIN #FilteredCdslType cdslst ON dp.RefDpTransactionStatusId = cdslst.RefDpTransactionStatusId   
 AND dp.RefDpTransactionTypeId = cdslst.RefDpTransactionTypeId  
 WHERE dp.RefSegmentId = @CdslId    
 AND dp.BusinessDate BETWEEN @PreFromDate AND @PreToDate  
    
 INSERT INTO #preTradeData(RefClientId, RefSegmentId, RefIsinId, Quantity, BusinessDate)    
 SELECT     
  dp.RefClientId,    
  dp.RefSegmentId,    
  dp.RefIsinId,    
  CONVERT(INT, dp.Quantity) AS Quantity,    
  dp.ExecutionDate AS BusinessDate    
 FROM #curFilteredData cl    
 INNER JOIN dbo.CoreDPTransactionChangeHistory dp ON cl.RefClientId = dp.RefClientId  
 INNER JOIN #FilteredNsdlType nsdt ON dp.RefDpTransactionTypeId = nsdt.RefDpTransactionTypeId AND dp.OrderStatusTo = nsdt.OrderStatusTo  
 WHERE dp.RefSegmentId = @NsdlId    
  AND dp.ExecutionDate BETWEEN @PreFromDate AND @PreToDate    
    
 SELECT    
  td.RefClientId,     
  td.RefSegmentId,    
  SUM(td.Quantity * ISNULL(cdslBhav.[Close], nsdlBhav.[Close])) AS PreviousMonthTxnValue    
 INTO #preClientWiseData    
 FROM #preTradeData td    
 LEFT JOIN dbo.CoreDpBhavCopy cdslBhav ON td.RefIsinId = cdslBhav.RefIsinId    
  AND cdslBhav.[Date] = td.BusinessDate AND cdslBhav.RefSegmentId = @CdslId    
 LEFT JOIN dbo.CoreDpBhavCopy nsdlBhav ON td.RefIsinId = nsdlBhav.RefIsinId    
  AND nsdlBhav.[Date] = td.BusinessDate AND nsdlBhav.RefSegmentId = @NsdlId    
 WHERE cdslBhav.RefSegmentId IS NOT NULL OR nsdlBhav.RefSegmentId IS NOT NULL    
 GROUP BY td.RefClientId, td.RefSegmentId    
    
 DROP TABLE #preTradeData    
    
 SELECT    
  cur.RefClientId,    
  cl.ClientId,    
  cl.[Name] AS ClientName,    
  cur.RefSegmentId,    
  @CurFromDate AS TransactionDateFrom,    
  @CurToDateWOTime AS TransactionDateTo,    
  seg.Segment,    
  CASE WHEN cl.DpId IS NULL THEN ''
	ELSE 'IN' +  CONVERT(VARCHAR(MAX),cl.DpId) COLLATE DATABASE_DEFAULT
	END AS DpId,    
  CONVERT(DECIMAL(28, 2), ISNULL(pre.PreviousMonthTxnValue, 0)) AS PreviousMonthTxnValue,    
  CONVERT(DECIMAL(28, 2), cur.TransactionValue) AS TransactionValue,    
  CONVERT(DECIMAL(28, 2), CASE WHEN pre.RefClientId IS NULL OR pre.PreviousMonthTxnValue = 0    
   THEN 100    
   ELSE (cur.TransactionValue - pre.PreviousMonthTxnValue) * 100 / pre.PreviousMonthTxnValue    
   END) AS PercentageIncrease,    
  CONVERT(DECIMAL(28, 2), ISNULL(cur.TotalHoldingValue,0)) AS TotalHoldingValue,  
  @HoldingDate HoldingDate,  
  CONVERT(DECIMAL(28, 2), ISNULL(cur.[Percentage],0)) AS [Percentage],    
  DATEDIFF(DAY, cl.AccountOpeningDate, @CurToDateWOTime) AS NoOfDays,  
  cl.AccountOpeningDate,
  custSeg.[Name] AS AccountSegment  
 INTO #FinalOutput  
 FROM #curFilteredData cur    
 LEFT JOIN #preClientWiseData pre ON cur.RefClientId = pre.RefClientId AND cur.RefSegmentId = pre.RefSegmentId    
 INNER JOIN dbo.RefClient cl ON cur.RefClientId = cl.RefClientId 
 INNER JOIN #clientCSMapping ccsm ON ccsm.RefClientId = cl.RefClientId
 INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1) 
 LEFT JOIN dbo.RefCustomerSegment custSeg ON custSeg.RefCustomerSegmentId = ccsm.RefCustomerSegmentId 
 INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = cur.RefSegmentId    
 WHERE pre.RefClientId IS NULL OR pre.PreviousMonthTxnValue = 0    
  OR ( rules.Threshold = 0 OR (cur.TransactionValue - pre.PreviousMonthTxnValue) * 100 / pre.PreviousMonthTxnValue >= rules.Threshold)  
    
  SELECT  
 t.*  
  FROM #FinalOutput t  
  INNER JOIN #clientCSMapping ccsm ON ccsm.RefClientId = t.RefClientId
  INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1) 
  WHERE ( rules.Threshold = 0 OR PercentageIncrease >= rules.Threshold )  
  AND NOT EXISTS   
  (  
  SELECT 1   
  FROM dbo.CoreAmlScenarioAlert a  
  WHERE @IsDuplicateAllowed=0  
	 AND a.RefAmlReportId=@ReportIdInternal  
	 AND a.RefClientId=t.RefClientId  
	 AND a.RefSegmentEnumId=t.RefSegmentId  
	 AND a.TransactionFromDate=t.TransactionDateFrom  
	 AND a.TransactionToDate=t.TransactionDateTo  
	 AND a.NetMoneyIn=t.PreviousMonthTxnValue  
	 AND a.NetMoneyOut=t.TotalHoldingValue  
	 AND a.Amount=t.TransactionValue  
	 AND a.AccountOpeningDate=AccountOpeningDate  
	 AND MONTH(a.ReportDate)=MONTH(@RunDateInternal)  
	 AND YEAR(a.ReportDate)=YEAR(@RunDateInternal)  
  )  
  END    
GO
--WEB-73846 RC END
