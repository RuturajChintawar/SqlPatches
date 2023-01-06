--WEB-73843 RC START
GO
DECLARE @S840Id INT, @ReasonGiftValue DECIMAL(28,2), @ReasonDonationValue DECIMAL(28,2), @ReasonOffMarketSaleValue DECIMAL(28,2)

SELECT @S840Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S840 Client Off Market Transfer Of Specific Reason Consolidate Vis Fair Value'

SELECT @ReasonGiftValue = CONVERT(DECIMAL(28,2),[Value])
FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S840Id AND [Name] = 'Transaction_Value'

SELECT @ReasonDonationValue = CONVERT(DECIMAL(28,2),[Value])
FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S840Id AND [Name] = 'Threshold_Quantity'

SELECT @ReasonOffMarketSaleValue = CONVERT(DECIMAL(28,2),[Value])
FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S840Id AND [Name] = 'Quantity'

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
	@S840Id,
	ISNULL(@ReasonGiftValue,0),
	ISNULL(@ReasonDonationValue,0),
	ISNULL(@ReasonOffMarketSaleValue,0),
	'System',
	GETDATE(),
	'System',
	GETDATE()
GO
--WEB-73843 RC END
--WEB-73843 RC START
GO
DECLARE @S840Id INT, @RuleId INT

SELECT @S840Id = RefAmlReportId FROM dbo.RefAmlReport
WHERE [Name] = 'S840 Client Off Market Transfer Of Specific Reason Consolidate Vis Fair Value'

SELECT @RuleId = RefAmlScenarioRuleId FROM dbo.RefAmlScenarioRule WHERE RefAmlReportId = @S840Id

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
--WEB-73843 RC END
--WEB-73843 RC START
GO
UPDATE dbo.RefAmlReport
SET
	Threshold1DisplayName = 'Reason Gift',
	Threshold2DisplayName = 'Reason Donation',
	Threshold3DisplayName = 'Reason Off Market Sale',
	[Description] = 
	'This scenario will help us to identify the Clients who transfer off market with specific reason & does not match with Fair Value of Client. <br>    
	Segments: CDSL, NSDL ; Period = 1 Day  ( Look back period Maximum 95 Days ) <br>    
	<b>Thresholds: </b> <br>    
	1. <b>Total transaction value:</b> This is the total amount of High Value Off Market Transactions for the specific reason codes done by the client in specified Look back period in all the scrips. System will generate alert If this ''X'' Transaction value is greater than or equal to the set threshold. <br>     
	2. <b>Reason Codes</b> considered for this scenarios are <b>Gift, Donation, Off Market sale.</b> Seperate txn value thresholds can be set for each Reason code. <br>    
	3. <b>Fair Value :</b> Income* Income multiplier + Networth* Networth Multiplier <br>    
	4. <b>LookBack Period =</b> This is the number of days system will consider to find the total transactions of the client. It is configurable. ( Maximum Look back period can be marked for <b>95 Days only</b> ) <br>    
	5. <b>Account Segment =</b> Account segment mapped to the DP account <br>
	<b>Note: </b> <br>    
	1. System will generate alert if atleast one off market transaction is present on the run day. <br>    
	2. Two different alerts will be generated for CDSL & NSDL. <br>    
	3. Only Debit Transactions will be considered for alert generation.'
WHERE [Name] = 'S840 Client Off Market Transfer Of Specific Reason Consolidate Vis Fair Value'
GO
--WEB-73843 RC END
--WEB-73843 RC START
GO
DECLARE @S840Id INT

SELECT @S840Id = RefAmlReportId FROM dbo.RefAmlReport
WHERE [Name] = 'S840 Client Off Market Transfer Of Specific Reason Consolidate Vis Fair Value'

DELETE makerChecker FROM
dbo.CoreAmlScenarioRuleMakerChecker makerChecker
INNER JOIN dbo.SysAmlReportSetting sett ON makerChecker.SysAmlReportSettingId = sett.SysAmlReportSettingId
AND sett.RefAmlReportId = @S840Id AND sett.[Name] <> 'Number_Of_Days'

DELETE FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S840Id AND [Name] <>'Number_Of_Days'
GO
--WEB-73843 RC END
--WEB-73843 RC START
GO
 ALTER PROCEDURE dbo.AML_GetClientOffMarketTransferOfSpecificReasonConsolidateVisFairValue (    
 @RunDate DATETIME,          
 @ReportId INT    
)          
AS              
BEGIN          
 DECLARE @RunDateInternal DATETIME,@ReportIdInternal INT, @Lookback INT,          
           
  @NoOfDis INT, @ToDate DATETIME, @NsdlId INT, @CdslId INT, @LookBackDate DATETIME, @LastBhavCopyDate DATETIME,          
  @NsdlType904 INT, @NsdlType925 INT, @CdslType2 INT, @CdslType3 INT, @CdslType5 INT,          
  @CdslStatus305 INT, @CdslStatus511 INT, @BSEId INT, @NSEId INT,          
  @InstitutionalClientDefaultIncome DECIMAL(28, 2), @ProfileDefault INT,          
  @InstitutionalClientDefaultNetworth BIGINT, @InstitutionStatus INT,          
  @DefaultIncomeAbove1Cr DECIMAL(28, 2), @DefaultIncome DECIMAL(28, 2),@DefaultNetworth BIGINT ,    
  @DefaultIncomeMultiplier DECIMAL(28,2) , @DefaultNetworthMultiplier DECIMAL(28,2),  
  @DayPrior7 DATETIME     
              
         
 SELECT @DefaultIncomeMultiplier = CONVERT( DECIMAL(28,2),[Value]) FROM dbo.SysConfig WHERE [Name] = 'Aml_Client_Income_Multiplier'    
 SELECT @DefaultNetworthMultiplier = CONVERT( DECIMAL(28,2),[Value]) FROM dbo.SysConfig WHERE [Name] = 'Aml_Client_Networth_Multiplier'    
        
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)          
 SET @ReportIdInternal = @ReportId          
 SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')          
 SET @DayPrior7 = DATEADD(DAY, -7, @RunDateInternal)    
   
 SELECT @InstitutionStatus = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'          
 SELECT @ProfileDefault = RefAmlQueryProfileId FROM dbo.RefAmlQueryProfile WHERE [Name] = 'Default'          
 SELECT @InstitutionalClientDefaultIncome = CONVERT(DECIMAL(28, 2), [Value])FROM dbo.SysConfig WHERE [Name] = 'Institutional_Client_Default_Income'          
 SELECT @InstitutionalClientDefaultNetworth = CONVERT(BIGINT, [Value]) FROM dbo.SysConfig WHERE [Name] = 'Institutional_Client_Default_Networth'          
 SELECT @DefaultIncomeAbove1Cr = CONVERT(DECIMAL(28, 2), ISNULL([Value], 0)) FROM dbo.SysConfig WHERE [Name] = 'Income_Value_For_Above_One_Crore'          
 SET @DefaultIncomeAbove1Cr = CASE WHEN @DefaultIncomeAbove1Cr <> 0 THEN @DefaultIncomeAbove1Cr ELSE 10000000 END          
  SELECT          
  @DefaultIncome = CONVERT(DECIMAL(28, 2), reportSetting.[Value])          
 FROM dbo.RefAmlQueryProfile qp            
 LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.[Name] = 'Client Purchase to Income'          
 LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId          
  AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId          
  AND reportSetting.[Name] = 'Default_Income'          
 WHERE qp.RefAmlQueryProfileId = @ProfileDefault    
     
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
    
  SELECT @Lookback = CONVERT(INT, [Value]) - 1          
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Days'          
           
 SET @LookBackDate = CONVERT(DATETIME, DATEDIFF(dd, @Lookback, @RunDateInternal))          
 SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'CDSL'          
 SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSDL'          
 SELECT @BSEId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'BSE_CASH'          
 SELECT @NSEId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSE_CASH'          
 SELECT @CdslType2 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 2 AND [Name] = 'Transactions within DP'          
 SELECT @CdslType3 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 3 AND [Name] = 'Transactions across DPs'          
 SELECT @CdslType5 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 5 AND [Name] = 'Inter-depository'          
 SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 904 AND [Name] = 'Delivery Free of Payment (Inter DP) Instruction'          
 SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'          
 SELECT @CdslStatus305 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 305          
 SELECT @CdslStatus511 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 511     
     
 SELECT          
  @DefaultNetworth = cliNetSellPoint.DefaultNetworth          
 FROM dbo.RefAmlQueryProfile qp            
 LEFT JOIN dbo.LinkRefAmlQueryProfileRefSegment qpSegment ON qpSegment.RefSegmentId = @BSEId          
  AND qpSegment.RefAmlQueryProfileId = qp.RefAmlQueryProfileId                
 LEFT JOIN dbo.SysAmlClientNetSellPoints cliNetSellPoint ON          
  cliNetSellPoint.LinkRefAmlQueryProfileRefSegmentId = qpSegment.LinkRefAmlQueryProfileRefSegmentId          
 WHERE qp.RefAmlQueryProfileId = @ProfileDefault          
         
 SELECT          
  RefClientId          
 INTO #clientsToExclude          
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion          
 WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportIdInternal)        
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)    
      
 CREATE TABLE #reasonData (          
  RefSegmentId INT,          
  ReasonCode INT,    
  [Description] VARCHAR(100) COLLATE DATABASE_DEFAULT    
 )    
    
 INSERT INTO #reasonData VALUES (@CdslId,1,'Gift')    
 INSERT INTO #reasonData VALUES (@CdslId,2,'Off Market Sale')    
 INSERT INTO #reasonData VALUES (@CdslId,16,'Donation')    
 INSERT INTO #reasonData VALUES (@NsdlId,1,'Off Market Sale')    
 INSERT INTO #reasonData VALUES (@NsdlId,92,'Gift')    
 INSERT INTO #reasonData VALUES (@NsdlId,93,'Donation')    
         
 SELECT DISTINCT          
  dp.RefClientId          
 INTO #runDateClientsCdsl          
 FROM dbo.CoreDpTransaction dp    
 INNER JOIN #reasonData reason ON dp.RefSegmentId = reason.RefSegmentId AND dp.ReasonForTrade = reason.ReasonCode    
 LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId          
 WHERE dp.RefSegmentId = @CdslId          
  AND dp.BusinessDate = @RunDateInternal          
  AND clEx.RefClientId IS NULL          
  AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))          
   OR (dp.RefDpTransactionStatusId = @CdslStatus511 AND dp.RefDpTransactionTypeId =  @CdslType5))          
  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')          
  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')          
         
 SELECT DISTINCT          
  dp.RefClientId          
 INTO #runDateClientsNsdl          
 FROM dbo.CoreDPTransactionChangeHistory dp          
 LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId          
 WHERE dp.RefSegmentId = @NsdlId          
  AND dp.ExecutionDate = @RunDateInternal          
  AND clEx.RefClientId IS NULL          
  AND (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')          
  AND dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType925)          
  AND dp.OrderStatusTo = 51          
  AND (dp.TransferReasonCode in ('1','92','93'))          
         
         
 DROP TABLE #clientsToExclude          
         
 CREATE TABLE #tradeData (          
  TradeId BIGINT,    
  RefClientId INT,          
  RefSegmentId INT,          
  RefIsinId INT,          
  Quantity INT,          
  BusinessDate DATETIME,          
  ReasonCode INT          
 )          
         
 INSERT INTO #tradeData(TradeId, RefClientId, RefSegmentId,RefIsinId, Quantity, BusinessDate,ReasonCode)          
 SELECT          
  dp.CoreDpTransactionId,    
  dp.RefClientId,          
  dp.RefSegmentId,          
  dp.RefIsinId,          
  dp.Quantity,          
  dp.BusinessDate,          
  dp.ReasonForTrade          
 FROM #runDateClientsCdsl cl          
 INNER JOIN dbo.CoreDpTransaction dp ON cl.RefClientId = dp.RefClientId    
 INNER JOIN #reasonData reason ON dp.RefSegmentId = reason.RefSegmentId AND dp.ReasonForTrade = reason.ReasonCode    
 WHERE dp.RefSegmentId = @CdslId          
  AND (dp.BusinessDate BETWEEN @LookBackDate AND @ToDate)          
  AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))          
   OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))          
  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')          
  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')          
  AND (dp.BuySellFlag = 'D' OR dp.BuySellFlag = 'S')          
         
 DROP TABLE #runDateClientsCdsl      
         
 INSERT INTO #tradeData(TradeId, RefClientId, RefSegmentId,RefIsinId, Quantity, BusinessDate,ReasonCode)          
 SELECT          
  dp.CoreDPTransactionChangeHistoryId,    
  dp.RefClientId,          
  dp.RefSegmentId,          
  dp.RefIsinId,          
  CONVERT(INT, dp.Quantity) AS Quantity,          
  dp.ExecutionDate AS BusinessDate,          
  CONVERT(INT,dp.TransferReasonCode) AS ReasonCode          
 FROM #runDateClientsNsdl cl          
 INNER JOIN dbo.CoreDPTransactionChangeHistory dp ON cl.RefClientId = dp.RefClientId          
 WHERE dp.RefSegmentId = @NsdlId          
  AND (dp.ExecutionDate BETWEEN @LookBackDate AND @ToDate)          
  AND (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')          
  AND dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType925)          
  AND dp.OrderStatusTo = 51        
   AND (dp.TransferReasonCode in ('1','92','93'))        
         
 DROP TABLE #runDateClientsNsdl          
         
 SELECT DISTINCT          
  RefIsinId,          
  BusinessDate          
 INTO #selectedIsins          
 FROM #tradeData          
         
 SELECT DISTINCT            
 bhav.RefIsinId,            
 bhav.[Close],          
 bhav.RefSegmentId,          
 isin.BusinessDate,          
 ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId, isin.BusinessDate ORDER BY bhav.RefSegmentId) AS RN            
 INTO #presentBhavIdsTemp            
 FROM #selectedIsins isin            
 INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = isin.RefIsinId          
 WHERE bhav.[Date] = isin.BusinessDate          
         
 SELECT          
  RefIsinId,          
  [Close],          
  BusinessDate          
 INTO #presentBhavIds          
 FROM #presentBhavIdsTemp temp            
 WHERE temp.RN = 1          
         
 DROP TABLE #presentBhavIdsTemp          
         
 SELECT DISTINCT TOP 7          
  bhav.[Date]          
 INTO #selectedDates2          
 FROM dbo.CoreBhavCopy bhav          
 WHERE bhav.[Date] >= @DayPrior7 AND bhav.[Date] <= @RunDateInternal            
 ORDER BY bhav.[Date] DESC          
         
 SELECT @LastBhavCopyDate = MIN([Date]) FROM #selectedDates2          
           
    DROP TABLE #selectedDates2          
         
 SELECT DISTINCT          
  [Date]          
 INTO #selectedDates          
 FROM dbo.CoreBhavCopy          
 WHERE [Date] BETWEEN @LastBhavCopyDate AND @ToDate          
 ORDER BY [Date] DESC          
         
 SELECT DISTINCT          
  isin.RefIsinId,          
  isin.BusinessDate          
 INTO #notPresentBhavIds          
 FROM #selectedIsins isin          
 LEFT JOIN #presentBhavIds ids ON isin.RefIsinId = ids.RefIsinId          
  AND isin.BusinessDate = ids.BusinessDate          
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
 INNER JOIN dbo.RefInstrument inst ON isin.[Name] = inst.Isin          
  AND inst.RefSegmentId IN (@BSEId, @NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'          
 INNER JOIN dbo.CoreBhavCopy bhav ON bhav.RefInstrumentId = inst.RefInstrumentId AND bhav.RefSegmentId = inst.RefSegmentId          
  AND bhav.[Date] <= ids.BusinessDate          
 WHERE bhav.[Date] IN (SELECT TOP 7 [Date] FROM #selectedDates sD WHERE sd.[Date] <= ids.BusinessDate ORDER BY sd.[Date] DESC)          
         
 DROP TABLE #selectedDates          
 DROP TABLE #notPresentBhavIds          
         
 SELECT DISTINCT          
  bhav1.RefIsinId,          
  bhav1.BusinessDate,          
  bhav1.[Close]          
 INTO #finalNonDpBhavRates          
 FROM #nonDpBhavRates bhav1          
 WHERE RN = 1 AND (bhav1.RefSegmentId = @BSEId OR NOT EXISTS (SELECT 1 FROM #nonDpBhavRates bhav2          
  WHERE bhav1.RefIsinId = bhav2.RefIsinId AND bhav1.BusinessDate = bhav2.BusinessDate          
   AND bhav2.RefSegmentId = @BSEId))          
         
 DROP TABLE #nonDpBhavRates          
         
 SELECT          
  tdata.RefClientId,          
  tdata.RefSegmentId,          
  tdata.RefIsinId,          
  tdata.BusinessDate,          
  (tdata.Quantity * COALESCE(pIds.[Close], nonDpRates.[Close])) AS TxnValue,          
  tdata.ReasonCode          
 INTO #transactionData          
 FROM #tradeData tdata          
 LEFT JOIN #presentBhavIds pIds ON tdata.RefIsinId = pIds.RefIsinId          
  AND tdata.BusinessDate = pIds.BusinessDate          
 LEFT JOIN #finalNonDpBhavRates nonDpRates ON pIds.RefIsinId IS NULL          
  AND tdata.RefIsinId = nonDpRates.RefIsinId AND tdata.BusinessDate = nonDpRates.BusinessDate          
 WHERE pIds.RefIsinId IS NOT NULL OR nonDpRates.RefIsinId IS NOT NULL          
         
 DROP TABLE #presentBhavIds          
 DROP TABLE #finalNonDpBhavRates   
   
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
 ) t  
 WHERE t.RN = 1  
  
 DROP TABLE #distinctClients  
      
         
 SELECT          
  t.RefClientId,          
  t.Income,          
  t.Networth,          
  t.IncomeMultiplier,          
  t.NetworthMultiplier          
 INTO #incomeData          
 FROM (SELECT          
   fd.RefClientId,          
   CASE WHEN inc.Income IS NOT NULL          
    THEN inc.Income          
    WHEN incGroup.[Name] IS NOT NULL AND incGroup.IncomeTo > 10000000          
    THEN @DefaultIncomeAbove1Cr          
    WHEN incGroup.[Name] IS NOT NULL          
    THEN incGroup.IncomeTo          
    ELSE @DefaultIncome END AS Income,          
   CASE WHEN cl.RefClientStatusId = @InstitutionStatus AND @InstitutionalClientDefaultNetworth > 0          
    THEN COALESCE (inc.Networth, @InstitutionalClientDefaultNetworth)          
    ELSE COALESCE (inc.Networth, @DefaultNetworth, 0) END AS Networth,          
   ROW_NUMBER() OVER (PARTITION BY fd.RefClientId ORDER BY inc.FromDate DESC) AS RN,     
  CASE WHEN ISNULL(cl.IncomeMultiplier,0)<>0 THEN CONVERT(DECIMAL(28, 2),cl.IncomeMultiplier)    
  ELSE CONVERT(DECIMAL(28, 2),ISNULL(@DefaultIncomeMultiplier,1)) END AS IncomeMultiplier,    
  CASE WHEN ISNULL(cl.NetworthMultiplier,0)<>0 THEN CONVERT(DECIMAL(28, 2),cl.NetworthMultiplier)    
  ELSE CONVERT(DECIMAL(28, 2),ISNULL(@DefaultNetworthMultiplier,1)) END AS NetworthMultiplier    
  FROM #transactionData fd          
  INNER JOIN dbo.RefClient cl ON cl.RefClientId = fd.RefClientId          
  LEFT JOIN dbo.LinkRefClientRefIncomeGroup inc ON fd.RefClientId = inc.RefClientId          
  LEFT JOIN dbo.RefIncomeGroup incGroup ON inc.RefIncomeGroupId = incGroup.RefIncomeGroupId          
 ) t          
 WHERE t.Rn = 1          
         
 --Code Wise Total          
 SELECT          
  RefClientId,          
  RefSegmentId,          
  ReasonCode,          
  SUM(TxnValue) AS TotalValue      
 INTO #CodeWiseData          
 FROM #transactionData      
 GROUP BY RefClientId,RefSegmentId,ReasonCode    
     
  SELECT    
    DISTINCT    
 RefClientId,          
 td.RefSegmentId,          
 td.ReasonCode,    
 STUFF((select DISTINCT ',' +  REPLACE(CONVERT(varchar, t.BusinessDate, 106), ' ', '-') from #tradeData t where t.RefClientId = td.RefClientId AND      
  t.RefSegmentId = td.RefSegmentId AND t.ReasonCode = td.ReasonCode FOR XML PATH('') ),1,1,'') AS reasons    
 INTO #DatesAndReason    
FROM #transactionData td INNER JOIN #reasonData re ON td.RefSegmentId = re.RefSegmentId AND td.ReasonCode = re.ReasonCode    
 GROUP BY RefClientId,td.RefSegmentId,td.ReasonCode    
         
 DROP TABLE #transactionData          
         
 --flat thresholds applied          
 SELECT          
  code.RefClientId,          
  code.RefSegmentId,          
  code.ReasonCode,          
  code.TotalValue          
 INTO #filtereddata          
 FROM #CodeWiseData code  
 INNER JOIN #clientCSMapping ccsm ON code.RefClientId = ccsm.RefClientId  
 INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)   
 WHERE (RefSegmentId=@CdslId AND          
 (rules.Threshold <> 0 AND ReasonCode=1 AND TotalValue >= rules.Threshold) OR          
 (rules.Threshold3 <> 0 AND ReasonCode=2 AND TotalValue >= rules.Threshold3) OR          
 (rules.Threshold2 <> 0 AND ReasonCode=16 AND TotalValue >= rules.Threshold2)) OR          
 (RefSegmentId=@NsdlId AND          
 (rules.Threshold3 <> 0 AND ReasonCode=1 AND TotalValue >= rules.Threshold3) OR          
 (rules.Threshold <> 0 AND ReasonCode=92 AND TotalValue >= rules.Threshold) OR          
 (rules.Threshold2 <> 0 AND ReasonCode=93 AND TotalValue >= rules.Threshold2))          
    
  SELECT          
  fd.RefClientId,          
  fd.RefSegmentId,          
  fd.TotalValue,          
  CONVERT(DECIMAL(28, 2), ((inc.Income * ISNULL(cl.IncomeMultiplier, 1)) + (inc.Networth * ISNULL(cl.NetworthMultiplier, 1)))) AS FairValue      
 INTO #fvaldata          
 FROM #filtereddata fd          
 INNER JOIN dbo.RefClient cl ON cl.RefClientId = fd.RefClientId    
 LEFT JOIN #IncomeData inc ON fd.RefClientId = inc.RefClientId    
         
        
 DROP TABLE #filtereddata      
  --DROP TABLE #tradeData          
         
 SELECT          
  RefClientId,          
  RefSegmentId,          
  TotalValue,          
  FairValue     
 INTO #finaldata          
 FROM #fvaldata          
 WHERE TotalValue >= FairValue      
     
 DROP TABLE #fvaldata    
         
 SELECT          
  RefClientId,          
  RefSegmentId,          
  SUM(TotalValue) AS TxnValue          
 INTO #output          
 FROM #CodeWiseData          
 GROUP BY RefClientId,RefSegmentId          
         
 DROP TABLE #CodeWiseData        
     
 SELECT      
 td.RefClientId,    
 td.RefSegmentId,    
 COUNT(DISTINCT td.TradeId) AS TrasactionCount,    
 STUFF(    
   (SELECT DISTINCT ','+ CONVERT(VARCHAR(MAX),td.TradeId)    
 FROM #tradeData td    
 WHERE td.RefClientId = fd.RefClientId AND td.RefSegmentId = fd.RefSegmentId    
 FOR XML PATH('')    
 ),    
  1,1,'') AS TxnIds     
 INTO #TaxnIds    
 FROM #tradeData td    
 INNER JOIN  #finaldata fd ON td.RefClientId = fd.RefClientId AND td.RefSegmentId = fd.RefSegmentId      
 GROUP BY td.RefClientId,td.RefSegmentId,fd.RefClientId,fd.RefSegmentId     
         
    
    
 SELECT DISTINCT         
  fd.RefClientId,          
  cl.ClientId,          
  cl.[Name] AS ClientName,          
  fd.RefSegmentId,          
  @LookBackDate AS TransactionDateFrom,          
  @RunDateInternal AS TransactionDateTo,          
  seg.Segment,      
  temp.TxnValue,          
  fd.FairValue,      
  inc.Income,      
  inc.IncomeMultiplier,      
  inc.Networth,      
  inc.NetworthMultiplier,      
  STUFF((SELECT DISTINCT ';'+ dr.reasons +':'+ res.[Description]     
  from #DatesAndReason dr     
  INNER JOIN #reasonData res ON res.ReasonCode = dr.ReasonCode and dr.RefSegmentId=res.RefSegmentId    
  where dr.RefClientId=fd.RefClientId     
  FOR XML PATH('')      
  ),1,1,'') AS [Description],    
  CASE WHEN LEN(taxnid.TxnIds)<8000 THEN taxnid.TxnIds ELSE 'Total Transaction Is Very Large. Total Transaction Count Is '+CONVERT(VARCHAR(MAX),taxnid.TrasactionCount) END AS TxnIds  ,  
  CASE WHEN cl.DpId IS NULL THEN ''  
 ELSE 'IN' +  CONVERT(VARCHAR(MAX),cl.DpId) COLLATE DATABASE_DEFAULT  
 END AS DpId,  
  custSeg.[Name] AS AccountSegment  
 FROM #finaldata fd          
 INNER JOIN #output temp ON temp.RefClientId = fd.RefClientId AND temp.RefSegmentId = fd.RefSegmentId          
 INNER JOIN dbo.RefClient cl ON fd.RefClientId = cl.RefClientId    
 INNER JOIN #clientCSMapping ccsm ON cl.RefClientId = ccsm.RefClientId  
 INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)  
 LEFT JOIN dbo.RefCustomerSegment custSeg ON custSeg.RefCustomerSegmentId = ccsm.RefCustomerSegmentId    
 INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = fd.RefSegmentId      
 LEFT JOIN #incomeData inc ON inc.RefClientId = fd.RefClientId     
 LEFT JOIN #TaxnIds taxnid ON taxnid.RefClientId=fd.RefClientId AND taxnid.RefSegmentId=fd.RefSegmentId    
    
    
END          
GO
--WEB-73843 RC END
--WEB-73843 RC START
GO
 ALTER PROCEDURE dbo.AML_GetS840ClientOffMarketTransferOfSpecificReasonConsolidateVisFairValueTxnDetails    
(    
 @AlertId BIGINT    
)    
AS    
BEGIN    
 DECLARE @AlertIdInternal BIGINT, @SegmentId INT, @CdslId INT, @NsdlId INT, @TxnIds VARCHAR(MAX),    
   @CdslDbId INT, @TradingDBId INT, @NSDLDbId INT, @NsdlType925 INT, @NsdlType926 INT    
    
 SET @AlertIdInternal = @AlertId    
    
 SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'CDSL'    
 SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'NSDL'    
    
 SELECT @CdslDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'    
 SELECT @TradingDBId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'Trading'    
 SELECT @NSDLDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'    
    
 SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'        
 SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)'     
    
 SELECT @SegmentId = RefSegmentEnumId, @TxnIds = TransactionProfileRevisedJustification FROM dbo.CoreAmlScenarioAlert WHERE CoreAmlScenarioAlertId = @AlertIdInternal    
    
 SET @TxnIds = LTRIM(RTRIM(@TxnIds))    
    
  
 IF ISNULL(@TxnIds,'') = ''    
 BEGIN    
  RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;    
  RETURN 50010    
 END    
    
 IF  @TxnIds LIKE '%Total Transaction Is Very Large. Total Transaction Count Is%'  
 BEGIN    
  RAISERROR (@TxnIds, 11, 1) WITH SETERROR;    
  RETURN 50010    
 END  
  
 CREATE TABLE #reasonData    
 (          
  RefSegmentId INT,          
  ReasonCode INT,    
  [Description] VARCHAR(100) COLLATE DATABASE_DEFAULT    
 )    
    
 INSERT INTO #reasonData VALUES (@CdslId,1,'Gift')    
 INSERT INTO #reasonData VALUES (@CdslId,2,'Off Market Sale')    
 INSERT INTO #reasonData VALUES (@CdslId,16,'Donation')    
 INSERT INTO #reasonData VALUES (@NsdlId,1,'Off Market Sale')    
 INSERT INTO #reasonData VALUES (@NsdlId,92,'Gift')    
 INSERT INTO #reasonData VALUES (@NsdlId,93,'Donation')    
    
 SELECT    
  CONVERT(BIGINT,t.items) AS TxnId    
 INTO #allTxnIds    
 FROM dbo.Split(@TxnIds,',') t    
    
 IF @SegmentId = @CdslId    
 BEGIN    
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
   rd.[Description] AS ReasonCode,    
   '' AS DpID,    
   '' AS OppDpId,    
   ISNULL(tradingClient.ClientId,'') AS TradingCode,    
   seg.Segment AS SegmentName    
  FROM #allTxnIds tids    
  INNER JOIN dbo.CoreDpTransaction txn ON txn.CoreDpTransactionId = tids.TxnId    
  INNER JOIN dbo.RefClient cl ON cl.RefClientId = txn.RefClientId    
  INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = txn.RefIsinId    
  INNER JOIN #reasonData rd ON rd.RefSegmentId = txn.RefSegmentId AND rd.ReasonCode = txn.ReasonForTrade    
  INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = txn.RefSegmentId    
  LEFT JOIN dbo.RefClient oppCl ON oppCl.RefClientDatabaseEnumId = @CdslDbId AND oppCl.ClientId = txn.CounterBOId    
  LEFT JOIN dbo.RefClient tradingClient ON tradingClient.RefClientDatabaseEnumId = @TradingDBId AND tradingClient.PAN = cl.PAN    
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
   CASE WHEN dpTxn.RefDpTransactionTypeId = @NsdlType926 THEN 'Credit'    
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
   rd.[Description] AS ReasonCode,    
   ISNULL(tradingClient.ClientId,'') AS TradingCode,    
   seg.Segment AS SegmentName    
  FROM #allTxnIds txns    
  INNER JOIN dbo.CoreDPTransactionChangeHistory dpTxn ON txns.TxnId = dpTxn.CoreDPTransactionChangeHistoryId    
  INNER JOIN dbo.RefClient cl ON dpTxn.RefClientId = cl.RefClientId    
  INNER JOIN dbo.RefIsin isin ON dpTxn.RefIsinId = isin.RefIsinId    
  INNER JOIN #reasonData rd ON rd.RefSegmentId = dpTxn.RefSegmentId AND CONVERT(VARCHAR(500), rd.ReasonCode) = dpTxn.TransferReasonCode    
  INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = dpTxn.RefSegmentId    
  LEFT JOIN dbo.RefClient cl1 ON (dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926) AND cl1.RefClientDatabaseEnumId = @NSDLDbId    
    AND cl1.ClientId = (dpTxn.OtherDPCode + dpTxn.OtherClientCode))    
   OR (cl1.RefClientDatabaseEnumId = @NSDLDbId AND dpTxn.OtherDPId = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT)     
    AND dpTxn.OtherClientId = cl1.ClientId)    
  LEFT JOIN dbo.RefClient tradingClient ON tradingClient.RefClientDatabaseEnumId = @TradingDBId AND tradingClient.PAN = cl.PAN    
  ORDER BY dpTxn.ExecutionDate    
 END    
END    
GO
--WEB-73843 RC END
