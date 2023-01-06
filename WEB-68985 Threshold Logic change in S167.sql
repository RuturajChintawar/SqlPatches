--RC-WEB-67107-START
GO
ALTER PROCEDURE dbo.AML_GetClientTradingActivtyvisPledgeSignificantHoldingOffMkt (    
 @RunDate DATETIME,    
 @ReportId INT    
)    
AS    
BEGIN 
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @NSDLId INT, @CDSLId INT, @S166Id INT, @S837Id INT,    
  @NsdlType908 INT, @DefaultIncome BIGINT, @DefaultNetworth BIGINT,    
  @BSECashId INT, @NSECashId INT,@Lookback INT,@LookBackDate DATETIME,@LookBack7Date DATETIME,    
  @NsdlType904 INT, @NsdlType925 INT,@NsdlType905 INT, @NsdlType926 INT, @CdslType2 INT, @CdslType3 INT, @CdslType5 INT,     
  @CdslStatus305 INT, @CdslStatus511 INT,@ToDate DATETIME,@thres3 Decimal(28,2),@thres4 Decimal(28,2),@thres5 Decimal(28,2),@cdsl INT,@nsdl INT    
 SET @ReportIdInternal = @ReportId   
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
 SELECT @Lookback = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Days'    
     
 SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')    
   
 SET @LookBack7Date = CONVERT(DATETIME, DATEDIFF(dd, 6, @RunDateInternal))    
 SET @LookBackDate = CONVERT(DATETIME, DATEDIFF(dd, @Lookback-1, @RunDateInternal))   

 SELECT @cdsl= RefSegmentEnumId from  RefSegmentEnum where Segment='CDSL'
 SELECT @nsdl= RefSegmentEnumId from  RefSegmentEnum where Segment='NSDL'
 SELECT @CdslId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'    
 SELECT @NsdlId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'    
 SELECT @NsdlType908 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 908 AND [Name] = 'Pledge initiation'    

     
 SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'BSE_CASH'    
 SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSE_CASH'    
     
 SELECT @CdslType2 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 2 AND [Name] = 'Transactions within DP'    
 SELECT @CdslType3 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 3 AND [Name] = 'Transactions across DPs'    
 SELECT @CdslType5 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 5 AND [Name] = 'Inter-depository'    
     
 SELECT @CdslStatus305 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 305    
 SELECT @CdslStatus511 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 511    
    
 SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 904 AND [Name] = 'Delivery Free of Payment (Inter DP) Instruction'    
 SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 905 AND [Name] = 'Receipt Free of Payment (Inter DP) Instruction'    
 SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
 SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)'    
    
     
    
 SELECT    
  RefClientId    
 INTO #clientsToExclude    
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
 WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportIdInternal)    
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)    
    
 SELECT      
  rul.Threshold,      
  rul.Threshold2,      
  rul.Threshold3,    
  rul.Threshold4,    
  rul.Threshold5,    
  scrip.[Name] AS ScripGroup,      
  scrip.RefScripGroupId,    
  stat.RefClientStatusId    
 INTO #scenarioRules      
 FROM dbo.RefAmlScenarioRule rul      
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId      
 INNER JOIN dbo.RefScripGroup scrip ON scrip.RefScripGroupId = link.RefScripGroupId    
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus stat ON rul.RefAmlScenarioRuleId = stat.RefAmlScenarioRuleId    
 WHERE rul.RefAmlReportId = @ReportIdInternal AND (rul.Threshold3<>0 OR rul.Threshold4<>0 OR rul.Threshold5<>0)   
    
 SELECT      
  trade.CoreTradeId,      
  inst.Isin,      
  inst.GroupName,      
  inst.RefSegmentId      
 INTO #tradeIds      
 FROM dbo.CoreTrade trade      
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId    
 LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = trade.RefClientId    
 WHERE trade.TradeDate = @RunDateInternal AND trade.RefSegmentId IN (@BSECashId, @NSECashId)      
  AND clEx.RefClientId IS NULL    
      
 DROP TABLE #clientsToExclude     
    
 SELECT DISTINCT      
  ids.Isin,      
  CASE WHEN inst.GroupName IS NOT NULL      
  THEN inst.GroupName      
  ELSE 'B' END AS GroupName,    
  inst.Code    
 INTO #allNseGroupData      
 FROM #tradeIds ids      
 LEFT JOIN dbo.RefInstrument inst ON inst.RefSegmentId IN (@BSECashId, @NSECashId)      
  AND ids.Isin = inst.Isin AND inst.[Status] = 'A'     
 WHERE ids.RefSegmentId = @NSECashId    
    
 SELECT Isin, COUNT(1) AS rcount    
 INTO #multipleGroups    
 FROM #allNseGroupData    
 GROUP BY Isin HAVING COUNT(1) > 1    
    
 SELECT t.Isin, t.GroupName     
 INTO #nseGroupData    
 FROM (SELECT grp.Isin, grp.GroupName     
   FROM #allNseGroupData grp    
   WHERE NOT EXISTS (SELECT 1 FROM #multipleGroups mg     
    WHERE mg.Isin = grp.Isin    
   )    
    
   UNION    
    
   SELECT mg.Isin, grp.GroupName    
   FROM #multipleGroups mg    
   INNER JOIN #allNseGroupData grp ON grp.Isin = mg.Isin AND grp.Code like '5%'    
 )t    
    
 DROP TABLE #multipleGroups    
 DROP TABLE #allNseGroupData    
    
 SELECT       
  trade.RefClientId,      
  trade.RefInstrumentId,     
  trade.Quantity,      
  (trade.Rate * trade.Quantity) AS TradeTO,      
  rules.RefScripGroupId,    
  rules.RefClientStatusId,    
  trade.RefSegmentId    
 INTO #tradeData      
 FROM #tradeIds ids      
 INNER JOIN dbo.CoreTrade trade ON ids.CoreTradeId = trade.CoreTradeId    
 INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId    
 LEFT JOIN #nseGroupData nse ON ids.Isin = nse.Isin AND ids.RefSegmentId = @NSECashId    
 INNER JOIN #scenarioRules rules ON ((ids.RefSegmentId = @BSECashId       
  AND rules.ScripGroup = ids.GroupName) OR (ids.RefSegmentId = @NSECashId      
  AND rules.ScripGroup = nse.GroupName))    
  AND cl.RefClientStatusId = rules.RefClientStatusId    
      
 DROP TABLE #tradeIds      
 DROP TABLE #nseGroupData     
    
 SELECT    
  RefClientId,    
  RefInstrumentId,    
  RefClientStatusId,    
  RefScripGroupId,    
  RefSegmentId,    
  SUM(Quantity) AS TotalQty,    
  SUM(TradeTO) AS TotalTo    
 INTO #clientWiseData    
 FROM #tradeData    
 GROUP BY RefClientId, RefInstrumentId, RefClientStatusId, RefScripGroupId, RefSegmentId    
    
 DROP TABLE #tradeData    
    
 SELECT    
  cl.RefClientId,    
  cl.RefInstrumentId,    
  cl.RefClientStatusId,    
  cl.RefScripGroupId,    
  cl.RefSegmentId,    
  cl.TotalTo,    
  cl.TotalQty,    
  (cl.TotalTo / bhav.NetTurnOver * 100) AS TotalPrec,    
  bhav.NetTurnOver AS ExchangeTO,    
  bhav.NumberOfShares AS ExchangeQty,    
  isin.RefIsinId,
  bhav.[Close]    
 INTO #filteredData    
 FROM #clientWiseData cl    
 INNER JOIN dbo.CoreBhavCopy bhav ON bhav.RefInstrumentId = cl.RefInstrumentId    
  AND [Date] = @RunDateInternal    
 INNER JOIN #scenarioRules rules ON cl.RefClientStatusId = rules.RefClientStatusId    
  AND cl.RefScripGroupId = rules.RefScripGroupId    
 INNER JOIN dbo.RefInstrument inst ON cl.RefInstrumentId = inst.RefInstrumentId    
 INNER JOIN dbo.RefIsin isin ON inst.Isin = isin.[Name]    
 WHERE (cl.TotalTo / bhav.NetTurnOver * 100)  >= rules.Threshold2    
  AND (cl.TotalTo) >= rules.Threshold    
    
DROP TABLE #clientWiseData    
    
 SELECT DISTINCT    
  fd.RefClientId,    
  cl2.RefClientId AS HoldingId,    
  fd.RefIsinId ,
  cl2.RefClientDatabaseEnumId,
  CASE WHEN cl2.RefClientDatabaseEnumId = @NSDLId THEN @nsdl ELSE @cdsl END RefSegmentId
 INTO #holdingIds    
 FROM #filteredData fd    
 INNER JOIN dbo.RefClient cl1 ON fd.RefClientId = cl1.RefClientId    
 INNER JOIN dbo.RefClient cl2 ON cl1.PAN = cl2.PAN    
 WHERE LTRIM(ISNULL(cl1.PAN, '')) <> '' AND cl2.RefClientDatabaseEnumId IN (@NSDLId, @CDSLId)    
    
 CREATE TABLE #OffMarket (    
  RefClientId INT,    
  RefSegmentId INT,
  RefIsinId INT,
  OffMarketCount INT    
 )    
    
 SELECT    
  cl.RefClientId,    
  dp.RefSegmentId,
	cl.RefIsinId
 INTO #TempOffMarket    
 FROM #holdingIds cl    
 INNER JOIN dbo.CoreDpTransaction dp ON cl.HoldingId = dp.RefClientId AND cl.RefIsinId=dp.RefIsinId   
 WHERE dp.RefSegmentId = @cdsl   
  AND (dp.BusinessDate BETWEEN @LookBackDate AND @ToDate)    
  AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))    
   OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))    
  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')    
  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')   
  AND (dp.BuySellFlag = 'D' OR dp.BuySellFlag = 'S'OR dp.BuySellFlag = 'C')    
    
     
     
 INSERT INTO #OffMarket(RefClientId,RefSegmentId,RefIsinId, OffMarketCount)    
 SELECT    
  temp.RefClientId,    
  temp.RefSegmentId,
  temp.RefIsinId,
  COUNT(1) AS OffMarketCount    
 FROM #TempOffMarket temp    
 GROUP BY temp.RefClientId,temp.RefSegmentId ,temp.RefIsinId
    
 DROP TABLE #TempOffMarket    
     
    
 SELECT    
  cl.RefClientId,    
  dp.RefSegmentId,
  cl.RefIsinId
 INTO #TempOffMarket1    
 FROM #holdingIds cl    
 INNER JOIN dbo.CoreDPTransactionChangeHistory dp ON cl.HoldingId = dp.RefClientId   AND cl.RefIsinId=dp.RefIsinId
 WHERE dp.RefSegmentId = @nsdl
  AND (dp.ExecutionDate BETWEEN @LookBackDate AND @ToDate)    
  AND (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')    
  AND dp.RefDpTransactionTypeId IN (@NsdlType904,@NsdlType905,@NsdlType926, @NsdlType925)    
  AND dp.OrderStatusTo = 51    
    
     
 INSERT INTO #OffMarket(RefClientId,RefSegmentId,RefIsinId, OffMarketCount)    
 SELECT    
  temp.RefClientId,    
  temp.RefSegmentId,
  temp.ReFIsinId,
  COUNT(1) AS OffMarketCount    
 FROM #TempOffMarket1 temp    
 GROUP BY temp.RefClientId,temp.RefSegmentId, temp.ReFIsinId   
     
 DROP TABLE #TempOffMarket1    
    
 SELECT     
 mar.RefClientId,    
 mar.RefSegmentId, 
 mar.RefIsinId,
 SUM(mar.OffMarketCount)AS OffMarketCount    
 INTO #offMarketCount    
 FROM #OffMarket AS mar    
 GROUP BY mar.RefClientId,mar.RefSegmentId,mar.RefIsinId  
 
DROP TABLE #OffMarket
    
	CREATE TABLE #HoldingData(RefClientId INT, HoldingId INT, RefIsinId INT, Quantity INT,HoldingQuantity DECIMAL(28,2) NUll)    
    
	INSERT INTO #HoldingData(RefClientId, HoldingId, RefIsinId, Quantity,HoldingQuantity)    
	 SELECT    
	cl.RefClientId,    
	cl.HoldingId,    
	cl.RefIsinId,    
	case when cl.RefClientDatabaseEnumId=@CDSLId THEN hold.PledgedBalanceQuantity
	 ELSE 0 END AS Quantity,    
	hold.CurrentBalanceQuantity AS HoldingQuantity    
	FROM #holdingIds cl    
	 INNER JOIN dbo.RefClientDematAccount acc ON acc.RefClientId = cl.HoldingId    
	INNER JOIN dbo.CoreClientHolding hold ON hold.RefClientDematAccountId = acc.RefClientDematAccountId    
	 AND cl.RefIsinId = hold.RefIsinId    
	 WHERE hold.AsOfDate = @RunDateInternal   
 
	INSERT INTO #HoldingData(RefClientId, HoldingId, RefIsinId, Quantity,HoldingQuantity)
	SELECT
		cl.RefClientId,
		cl.HoldingId,
		cl.RefIsinId,
		case when cl.RefClientDatabaseEnumId=@NSDLId THEN hist.Quantity
		ELSE 0 END AS Quantity,
		0
	FROM #holdingIds cl
	INNER JOIN dbo.CoreDpTransactionChangeHistory hist ON hist.RefClientId = cl.HoldingId
		AND cl.RefIsinId = hist.RefIsinId
	WHERE hist.OrderStatusTo = 51 AND hist.RefDpTransactionTypeId = @NsdlType908
		AND hist.ExecutionDate = @RunDateInternal
    
 SELECT    
  RefClientId,    
  RefIsinId,
  HoldingId,
  SUM(Quantity) AS PledgeQty,    
  SUM(HoldingQuantity) AS HoldingQuantity    
 INTO #PledgeData    
 FROM #HoldingData    
 GROUP BY RefClientId, RefIsinId ,HoldingId  
    
     
 CREATE TABLE #OffMarketSeven (    
  RefClientId INT,    
  RefSegmentId INT,
  RefIsinId INT,
  OffMarketCount INT    
 )    
    
 SELECT    
  cl.RefClientId,    
  dp.RefSegmentId,
  cl.RefIsinId
 INTO #TempOffMarket2    
 FROM #holdingIds cl    
 INNER JOIN dbo.CoreDpTransaction dp ON cl.HoldingId = dp.RefClientId AND  cl.RefIsinId=dp.RefIsinId
 WHERE dp.RefSegmentId = @Cdsl    
  AND (dp.BusinessDate BETWEEN @LookBack7Date AND @ToDate)    
  AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))    
   OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))    
  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')
  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '') 
  AND (dp.BuySellFlag = 'D' OR dp.BuySellFlag = 'S'OR dp.BuySellFlag = 'C')    
     
     
     
 INSERT INTO #OffMarketSeven(RefClientId,RefSegmentId,RefIsinId, OffMarketCount)    
 SELECT    
  temp.RefClientId,    
  temp.RefSegmentId, 
  temp.RefIsinId,
  COUNT(1) AS OffMarketCount    
 FROM #TempOffMarket2 temp    
 GROUP BY temp.RefClientId,temp.RefSegmentId ,temp.RefIsinId   
    
Drop table #TempOffMarket2    
    
 SELECT    
  cl.RefClientId,    
  dp.RefSegmentId,
  cl.RefIsinId
 INTO #TempOffMarket3    
 FROM #holdingIds cl    
 INNER JOIN dbo.CoreDPTransactionChangeHistory dp ON cl.HoldingId = dp.RefClientId    AND cl.RefIsinId=dp.RefIsinId
 WHERE dp.RefSegmentId = @nsdl
  AND (dp.ExecutionDate BETWEEN @LookBack7Date AND @ToDate)    
  AND (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')    
  AND dp.RefDpTransactionTypeId IN (@NsdlType904,@NsdlType905,@NsdlType926, @NsdlType925)    
  AND dp.OrderStatusTo = 51    
      
     
 INSERT INTO #OffMarketSeven(RefClientId,RefSegmentId,RefIsinId, OffMarketCount)    
 SELECT    
  temp.RefClientId,    
  temp.RefSegmentId,  
  temp.RefIsinId,
  COUNT(1) AS OffMarketCount    
 FROM #TempOffMarket3 temp    
 GROUP BY temp.RefClientId,temp.RefSegmentId,temp.RefIsinId    
 
 DROP TABLE #TempOffMarket3

 SELECT     
 mar.RefClientId,    
 mar.RefSegmentId, 
 mar.RefIsinId,
 SUM(mar.OffMarketCount)AS OffMarketCount    
 INTO #offMarketCountSeven    
 FROM #OffMarketSeven AS mar    
 GROUP BY mar.RefClientId,mar.RefSegmentId ,mar.RefIsinId
     
DROP TABLE #OffMarketSeven

SELECT DISTINCT 
hi.RefIsinId,
dpBhav.CoreDpBhavCopyId,
dpBhav.RefSegmentId
INTO #temp
FROM #holdingIds hi
LEFT JOIN dbo.CoreDpBhavCopy dpBhav ON dpBhav.RefIsinId=hi.RefIsinId 
AND [Date] = @RunDateInternal



 SELECT    
  fd.RefClientId,    
  cl.ClientId,    
  cl.[Name] AS ClientName,    
  fd.RefInstrumentId,    
  fd.RefSegmentId,    
  seg.Segment,    
  @RunDateInternal AS TradeDate,    
  rules.ScripGroup AS GroupName,    
  inst.Code AS ScripCode,    
  inst.[Name] AS ScripName,    
  CONVERT(DECIMAL(28,2), fd.TotalTO) AS TotalTO,    
  CONVERT(DECIMAL(28,2), fd.TotalPrec) AS TotalPrec,    
  pledge.PledgeQty,    
  CONVERT(DECIMAL(28,2), (pledge.PledgeQty * COALESCE(dpBhav.[Close], fd.[Close], 0))) AS PledgeValue,    
  CONVERT(DECIMAL(28,2), (pledge.HoldingQuantity * COALESCE(dpBhav.[Close], fd.[Close], 0))) AS DPHoldingValue,    
  pledge.HoldingQuantity AS HoldingQty,    
  ISNULL(seven.OffMarketCount,0) AS OffMktTransaction,    
  CONVERT(DECIMAL(28,2), fd.ExchangeTO) AS ExchangeTO,
  CASE 
  WHEN rules.Threshold3 = 0 THEN ''
  WHEN (pledge.PledgeQty * COALESCE(dpBhav.[Close], fd.[Close], 0)) >= rules.Threshold3 THEN 'Pledge Value, '
  ELSE ''
  END thres3,
  CASE
  WHEN rules.Threshold4 = 0 THEN ''
  WHEN (pledge.HoldingQuantity * COALESCE(dpBhav.[Close], fd.[Close], 0)) >= rules.Threshold4  THEN 'DP Holding Value, '
  ELSE ''
  END thres4,
  CASE
	WHEN rules.Threshold5 = 0 THEN ''  
	WHEN ISNULL(mar.OffMarketCount,0)>=rules.Threshold5  THEN 'No of Off Mkt Transaction'
  ELSE ''
  END thres5
  
  
 FROM #filteredData fd    
 INNER JOIN dbo.RefClient cl ON fd.RefClientId = cl.RefClientId 
 INNER JOIN #holdingIds hi ON  fd.RefClientId = hi.RefClientId
 LEFT JOIN #temp tNSDL ON tNSDL.RefIsinId=fd.RefIsinId AND tNSDL.RefSegmentId = @nsdl
 LEFT JOIN #temp tCDSL ON tCDSL.RefIsinId=fd.RefIsinId AND tCDSL.RefSegmentId = @cdsl
 INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = fd.RefSegmentId    
 INNER JOIN #scenarioRules rules ON fd.RefClientStatusId = rules.RefClientStatusId    
  AND fd.RefScripGroupId = rules.RefScripGroupId    
 INNER JOIN dbo.RefInstrument inst ON fd.RefInstrumentId = inst.RefInstrumentId    
 INNER JOIN #PledgeData pledge ON pledge.RefClientId = fd.RefClientId     
  AND pledge.RefIsinId = fd.RefIsinId    
 LEFT  JOIN #offMarketCountSeven seven ON seven.RefClientId = fd.RefClientId AND seven.RefIsinId=fd.RefIsinId    
 LEFT  JOIN #offMarketCount mar ON mar.RefClientId = fd.RefClientId  AND mar.RefIsinId=fd.RefIsinId   
 INNER JOIN dbo.CoreDpBhavCopy dpBhav ON [Date] = @RunDateInternal    
						AND dpBhav.CoreDPBhavCopyId=(CASE WHEN hi.RefSegmentId= @CdslId THEN ISNULL(tCDSL.CoreDPBhavCopyId, tNSDL.CoreDPBhavCopyId)
												ELSE ISNULL(tNSDL.CoreDPBhavCopyId, tCDSL.CoreDPBhavCopyId) END)
 WHERE COALESCE(dpBhav.[Close], fd.[Close], 0) > 0    
  AND ((rules.Threshold3 <> 0 AND (pledge.PledgeQty * COALESCE(dpBhav.[Close], fd.[Close], 0)) >= rules.Threshold3 )  
  OR (rules.Threshold4 <> 0 AND (pledge.HoldingQuantity * COALESCE(dpBhav.[Close], fd.[Close], 0)) >= rules.Threshold4 )
  OR (rules.Threshold5 <> 0 AND ISNULL(mar.OffMarketCount,0)>=rules.Threshold5)  )
  AND (tCDSL.CoreDPBhavCopyId IS NOT NULL OR tNSDL.CoreDPBhavCopyId IS NOT NULL)
 
 DROP TABLE #PledgeData
 DROP TABLE #temp
 DROP TABLE #scenarioRules 
 DROP TABLE #filteredData 
 END 
GO
--RC-WEB-67107-END
--RC-WEB-67107-START
GO
DECLARE @AmlReportId INT
SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S167 Client Trading Activity vis Pledge/SignificantHolding/Off Mkt'
UPDATE dbo.RefAmlReport
SET [Description]='This Scenario will detect clients and generate alert if,<br>
	1. The percentage of scrip turnover buy or sell to the exchange turnover is greater than or equal to the set Scrip percent threshold<br>
	2. Client turnover in stock buy or sell is greater than or equal to set turnover threshold compared to the Exchange TO<br>
	3. Client Pledge value or Holding value or off market transaction is greater than or equal to set threshold<br>
	Segments covered : BSE_CASH, NSE_CASH ; Period: 1 day<br>
	<b>Thresholds:</b> <br>
	<b>1. Client Turnover :</b> It is the Total Client Turnover done in the same day in same scrip. It will generate alerts if the Client Turnover is greater than or equal to the set threshold.  ( =>)<br>
	<b>2. Scrip Group:</b> Threshold can be set Scrip group wise. ( e.g. A, B, T )<br>
	<b>3. Scrip Total TO % :</b>  It is Scrip Turnover % contribution done in a stock by a client compared to the Exchange Turnover. It will generate alerts if the Scrip Turnover % is greater than or equal to the set threshold.<br>  
	<b>4. Pledge Value :</b> It is the turnover done by the Pledge Quantity and Closing price of DP. It helps us detect the volume contribution done in the pledged shares. It will generate alerts if the Pledge Value is greater than or equal to the set threshold.<br>  
	<b>5. DP Holding value :</b> The current Holding present for the client in a particular scrip on the run date will be considered as the Holding value of the client. It is the turnover value done by the Holding Quantity and Closing price of DP.  It will generate alerts if the Holding Value is greater than or equal to the set threshold.<br>  
	<b>6. LookBack Period :</b> This is the number of days system will consider to find the total transactions of the client. It is configurable. ( Maximum Look back period can be marked for 95 Days only )<br>
	<b>7. No of Off Mkt Transactions in X days :</b> These are the number of off Market Transactions considered for alert generation in the specified number of days in ''X''Lookback period. It will generate alerts if the No. of Off market txns is greater than or equal to the set threshold.<br>  
	<b>Note:</b><br>
	1. For generating the alerts DP Holding files, Transaction , COD file should be merged.<br> 
	2.  Criteria: These are the threshold conditions available for the user to set multiple combinations of threshold criterias. At least one threshold field is to be set in one rule condition. A single rule condition will work on following conditions: Client TO and Scrip Total % TO will work on AND condition & it is mandatory for alert generation and for remaining 3 thresholds, it will work on OR condition. For an alert to be generated threshold should be breach from client TO and scrip total TO% and any one threshold from Pledge Value/DP Holding Value/No of Off Mkt Transactions in X days<br>
	System will check the conditions sequentially for one client , one scrip and for a particular run date.<br>
	If alert gets generated through Condition 1, system will not check other conditions for same client, same scrip and same trade date.<br>
	If alert doesn’t get generated for Condition 1, system will proceed and check for the other conditions as per the set threshold.'
WHERE RefAmlReportId=@AmlReportId
GO
--RC-WEB-67107-END
--RC-WEB-67107-START
GO
 ALTER PROCEDURE dbo.AML_GetS167ClientTradingActivtyvisPledgeSignificantHoldingOffMktScenarioAlertByCaseId  
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
  c.[Description], --  
  seg.Segment, --  
  c.TransactionDate AS TradeDate, --  
  c.ISINName AS GroupName, --  
  c.BuyTerminal AS ScripCode, --  
  c.SellTerminal AS ScripName, --  
  c.TurnOver AS TotalTO, --  
  c.QuantityPercentage AS TotalPrec, --  
  c.Quantity AS PledgeQty, --  
  c.Amount AS PledgeValue, --  
  c.MoneyInOutSum AS DPHoldingValue,--  
  c.MoneyInCount AS HoldingQty,--  
  c.BuyQty AS OffMktTransaction,  
  c.ExchangeTurnover AS ExchangeTO, --
  c.Description AS ThresholdDesc,
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
  INNER JOIN dbo.RefSegmentEnum seg ON c.RefSegmentEnumId = seg.RefSegmentEnumId  
  WHERE c.CoreAlertRegisterCaseId = @CaseId AND report.RefAmlReportId = @ReportId    
  
END  
GO
--RC-WEB-67107-END
--RC-WEB-67107-START
GO
 ALTER PROCEDURE dbo.CoreAmlScenarioClientTradingActivtyvisPledgeSignificantHoldingOffMktAlert_Search   
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
  c.RefAmlReportId,  
    
  seg.Segment,--  
  c.TransactionDate,--  
  c.ISINName,--  
  c.BuyTerminal,--  
  c.SellTerminal,--  
  c.TurnOver,--  
  c.QuantityPercentage,--  
  c.Quantity,--  
  c.Amount,--  
  c.MoneyInOutSum,--  
  c.MoneyInCount,--  
  c.BuyQty,--  
  c.ExchangeTurnover,--  
  c.[Description] AS ThresholdDesc,
  c.ReportDate,  
  c.AddedBy,  
  c.AddedOn,  
  c.LastEditedBy,  
  c.EditedOn,  
  c.Comments,  
  c.ClientExplanation,  
  c.[Status]  
 FROM #alertids temp  
 INNER JOIN dbo.CoreAmlScenarioAlert c ON c.CoreAmlScenarioAlertId = temp.CoreAmlScenarioAlertId  
 INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId  
 INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = c.RefSegmentEnumId  
         
 SELECT COUNT(1) FROM #filteredAlerts  
END  
GO
--RC-WEB-67107-END