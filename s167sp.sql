GO
ALTER PROCEDURE dbo.AML_GetClientTradingActivtyvisPledgeSignificantHoldingOffMkt (    
 @RunDate DATETIME,    
 @ReportId INT    
)    
AS    
BEGIN  
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @NSDLId INT, @CDSLId INT, @S166Id INT, @S837Id INT,    
  @NsdlType908 INT, @ProfileDefault INT, @DefaultIncome BIGINT, @DefaultNetworth BIGINT,    
  @InstitutionalClientDefaultIncome VARCHAR(5000), @InstitutionalClientDefaultNetworth BIGINT,    
  @InstitutionStatus INT, @BSECashId INT, @NSECashId INT,@Lookback INT,@LookBackDate DATETIME,@LookBack7Date DATETIME,    
  @NsdlType904 INT, @NsdlType925 INT,@NsdlType905 INT, @NsdlType926 INT, @CdslType2 INT, @CdslType3 INT, @CdslType5 INT,     
  @CdslStatus305 INT, @CdslStatus511 INT,@ToDate DATETIME,@thres3 Decimal(28,2),@thres4 Decimal(28,2),@thres5 Decimal(28,2)    
 SET @ReportIdInternal = @ReportId   
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
 SELECT @Lookback = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Days'    
     
 SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')    
   
 SET @LookBack7Date = CONVERT(DATETIME, DATEDIFF(dd, @Lookback, @RunDateInternal))    
 SET @LookBackDate = DATEADD(DAY,-@Lookback,@RunDateInternal)    
   
 SELECT @CdslId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'    
 SELECT @NsdlId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'    
 SELECT @NsdlType908 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 908 AND [Name] = 'Pledge initiation'    
 SELECT @ProfileDefault = RefAmlQueryProfileId FROM dbo.RefAmlQueryProfile WHERE [Name] = 'Default'    
 SELECT @InstitutionalClientDefaultIncome = [Value] FROM dbo.SysConfig WHERE [Name] = 'Institutional_Client_Default_Income'    
 SELECT @InstitutionalClientDefaultNetworth = [Value] FROM dbo.SysConfig WHERE [Name] = 'Institutional_Client_Default_Networth'    
 SELECT @InstitutionStatus = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'    
    
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
 WHERE RefAmlReportId = @ReportIdInternal    
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
 WHERE rul.RefAmlReportId = @ReportIdInternal    
    
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
 LEFT JOIN dbo.RefInstrument inst ON inst.RefSegmentId in (@BSECashId, @NSECashId)      
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
  (cl.TotalTo / NetTurnOver * 100) AS TotalPrec,    
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
  fd.RefIsinId    
 INTO #holdingIds    
 FROM #filteredData fd    
 INNER JOIN dbo.RefClient cl1 ON fd.RefClientId = cl1.RefClientId    
 INNER JOIN dbo.RefClient cl2 ON cl1.PAN = cl2.PAN    
 WHERE LTRIM(ISNULL(cl1.PAN, '')) <> '' AND cl2.RefClientDatabaseEnumId IN (@NSDLId, @CDSLId)    
    
 CREATE TABLE #OffMarket (    
  RefClientId INT,    
  RefSegmentId INT,    
  OffMarketCount INT    
 )    
    
 SELECT    
  cl.RefClientId,    
  dp.RefSegmentId    
 INTO #TempOffMarket    
 FROM #holdingIds cl    
 INNER JOIN dbo.CoreDpTransaction dp ON cl.HoldingId = dp.RefClientId    
 WHERE dp.RefSegmentId = @CdslId    
  AND (dp.BusinessDate BETWEEN @LookBackDate AND @ToDate)    
  AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))    
   OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))    
  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')    
  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')   
  AND (dp.BuySellFlag = 'D' OR dp.BuySellFlag = 'S'OR dp.BuySellFlag = 'C')    
    
     
     
 INSERT INTO #OffMarket(RefClientId,RefSegmentId, OffMarketCount)    
 SELECT    
  temp.RefClientId,    
  temp.RefSegmentId,    
  COUNT(1) AS OffMarketCount    
 FROM #TempOffMarket temp    
 GROUP BY temp.RefClientId,temp.RefSegmentId    
    
 DROP TABLE #TempOffMarket    
     
    
 SELECT    
  cl.RefClientId,    
  dp.RefSegmentId    
 INTO #TempOffMarket1    
 FROM #holdingIds cl    
 INNER JOIN dbo.CoreDPTransactionChangeHistory dp ON cl.HoldingId = dp.RefClientId    
 WHERE dp.RefSegmentId = @NsdlId    
  AND (dp.ExecutionDate BETWEEN @LookBackDate AND @ToDate)    
  AND (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')    
  AND dp.RefDpTransactionTypeId IN (@NsdlType904,@NsdlType905,@NsdlType926, @NsdlType925)    
  AND dp.OrderStatusTo = 51    
    
     
     
 INSERT INTO #OffMarket(RefClientId,RefSegmentId, OffMarketCount)    
 SELECT    
  temp.RefClientId,    
  temp.RefSegmentId,    
  COUNT(1) AS OffMarketCount    
 FROM #TempOffMarket1 temp    
 GROUP BY temp.RefClientId,temp.RefSegmentId    
     
 DROP TABLE #TempOffMarket1    
    
 SELECT     
 mar.RefClientId,    
 mar.RefSegmentId,    
 SUM(mar.OffMarketCount)AS OffMarketCount    
 INTO #offMarketCount    
 FROM #OffMarket AS mar    
 GROUP BY mar.RefClientId,mar.RefSegmentId  
 
 DROP TABLE #OffMarket
    
 CREATE TABLE #HoldingData(RefClientId INT, HoldingId INT, RefIsinId INT, Quantity INT,HoldingQuantity DECIMAL(28,2))    
    
 INSERT INTO #HoldingData(RefClientId, HoldingId, RefIsinId, Quantity,HoldingQuantity)    
 SELECT    
  cl.RefClientId,    
  cl.HoldingId,    
  cl.RefIsinId,    
  hold.PledgedBalanceQuantity AS Quantity,    
  hold.CurrentBalanceQuantity AS HoldingQuantity    
 FROM #holdingIds cl    
 INNER JOIN dbo.RefClientDematAccount acc ON acc.RefClientId = cl.HoldingId    
 INNER JOIN dbo.CoreClientHolding hold ON hold.RefClientDematAccountId = acc.RefClientDematAccountId    
  AND cl.RefIsinId = hold.RefIsinId    
 WHERE hold.AsOfDate = @RunDateInternal    
    
 SELECT    
  RefClientId,    
  RefIsinId,    
  SUM(Quantity) AS PledgeQty,    
  SUM(HoldingQuantity) AS HoldingQuantity    
 INTO #PledgeData    
 FROM #HoldingData    
 GROUP BY RefClientId, RefIsinId    
    
     
 CREATE TABLE #OffMarketSeven (    
  RefClientId INT,    
  RefSegmentId INT,    
  OffMarketCount INT    
 )    
    
 SELECT    
  cl.RefClientId,    
  dp.RefSegmentId    
 INTO #TempOffMarket2    
 FROM #holdingIds cl    
 INNER JOIN dbo.CoreDpTransaction dp ON cl.HoldingId = dp.RefClientId    
 WHERE dp.RefSegmentId = @CdslId    
  AND (dp.BusinessDate BETWEEN @LookBack7Date AND @ToDate)    
  AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))    
   OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))    
  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')
  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '') 
  AND (dp.BuySellFlag = 'D' OR dp.BuySellFlag = 'S'OR dp.BuySellFlag = 'C')    
     
     
     
 INSERT INTO #OffMarketSeven(RefClientId,RefSegmentId, OffMarketCount)    
 SELECT    
  temp.RefClientId,    
  temp.RefSegmentId,    
  COUNT(1) AS OffMarketCount    
 FROM #TempOffMarket2 temp    
 GROUP BY temp.RefClientId,temp.RefSegmentId    
    
Drop table #TempOffMarket2    
    
 SELECT    
  cl.RefClientId,    
  dp.RefSegmentId    
 INTO #TempOffMarket3    
 FROM #holdingIds cl    
 INNER JOIN dbo.CoreDPTransactionChangeHistory dp ON cl.HoldingId = dp.RefClientId    
 WHERE dp.RefSegmentId = @NsdlId    
  AND (dp.ExecutionDate BETWEEN @LookBack7Date AND @ToDate)    
  AND (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')    
  AND dp.RefDpTransactionTypeId IN (@NsdlType904,@NsdlType905,@NsdlType926, @NsdlType925)    
  AND dp.OrderStatusTo = 51    
      
     
 INSERT INTO #OffMarketSeven(RefClientId,RefSegmentId, OffMarketCount)    
 SELECT    
  temp.RefClientId,    
  temp.RefSegmentId,    
  COUNT(1) AS OffMarketCount    
 FROM #TempOffMarket3 temp    
 GROUP BY temp.RefClientId,temp.RefSegmentId    
 
 DROP TABLE #TempOffMarket3

 SELECT     
 mar.RefClientId,    
 mar.RefSegmentId,    
 SUM(mar.OffMarketCount)AS OffMarketCount    
 INTO #offMarketCountSeven    
 FROM #OffMarketSeven AS mar    
 GROUP BY mar.RefClientId,mar.RefSegmentId    
     
	DROP TABLE #OffMarketSeven
    
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
  seven.OffMarketCount AS OffMktTransaction,    
  CONVERT(DECIMAL(28,2), fd.ExchangeTO) AS ExchangeTO    
 FROM #filteredData fd    
 INNER JOIN dbo.RefClient cl ON fd.RefClientId = cl.RefClientId    
 INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = fd.RefSegmentId    
 INNER JOIN #scenarioRules rules ON fd.RefClientStatusId = rules.RefClientStatusId    
  AND fd.RefScripGroupId = rules.RefScripGroupId    
 INNER JOIN dbo.RefInstrument inst ON fd.RefInstrumentId = inst.RefInstrumentId    
 INNER JOIN #PledgeData pledge ON pledge.RefClientId = fd.RefClientId     
  AND pledge.RefIsinId = fd.RefIsinId    
 INNER JOIN #offMarketCountSeven seven ON seven.RefClientId = fd.RefClientId     
 INNER JOIN #offMarketCount mar ON mar.RefClientId = fd.RefClientId     
 INNER JOIN dbo.CoreDpBhavCopy dpBhav ON dpBhav.RefIsinId = fd.RefIsinId    
  AND [Date] = @RunDateInternal    
 WHERE COALESCE(dpBhav.[Close], fd.[Close], 0) > 0    
  AND (pledge.PledgeQty * COALESCE(dpBhav.[Close], fd.[Close], 0)) >= rules.Threshold3    
  AND (pledge.HoldingQuantity * COALESCE(dpBhav.[Close], fd.[Close], 0)) >= rules.Threshold4    
 AND(mar.OffMarketCount)>=rules.Threshold5    
END
GO
sp_whoisactive