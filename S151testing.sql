GO
ALTER PROCEDURE dbo.AML_GetHighTurnoverTradesByGroupofClientsIn1Day  
(    
 @RunDate DATETIME,    
 @ReportId INT    
   
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @BSECashId INT, @NSECashId INT,  
   @IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT,  @IsGroupGreaterThanOneClient INT
    
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)    
 SET @ReportIdInternal = @ReportId    
 SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'    
 SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'  

 SELECT   
  @IsGroupGreaterThanOneClient = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Active_In_Report' 

 SELECT   
  @IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Exclude_Pro'  
   
 SELECT   
  @IsExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Exclude_Institution'  
   
 SELECT   
  @ProStatusId = RefClientStatusId   
 FROM dbo.RefClientStatus   
 WHERE [Name] = 'Pro'  
   
   
 SELECT   
  @InstituteStatusId = RefClientStatusId  
 FROM dbo.RefClientStatus WHERE [Name] = 'Institution'  
     
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
  scrip.[Name] AS ScripGroup,    
  scrip.RefScripGroupId    
 INTO #scenarioRules    
 FROM dbo.RefAmlScenarioRule rul    
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId    
 INNER JOIN dbo.RefScripGroup scrip ON scrip.RefScripGroupId = link.RefScripGroupId    
 WHERE RefAmlReportId = @ReportIdInternal    
    
 SELECT    
  trade.CoreTradeId,    
  inst.Isin,    
  inst.GroupName,    
  inst.RefSegmentId    
 INTO #tradeIds    
 FROM dbo.CoreTrade trade    
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
 INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId  
 WHERE trade.TradeDate = @RunDateInternal AND trade.RefSegmentId IN (@BSECashId, @NSECashId)  
 AND (@IsExcludePro = 0 OR cl.RefClientStatusId <> @ProStatusId)  
 AND (@IsExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstituteStatusId)  
 AND NOT EXISTS(SELECT 1 FROM #clientsToExclude clEx    
 WHERE clEx.RefClientId = trade.RefClientId)  
    
 DROP TABLE #clientsToExclude    
    
  SELECT DISTINCT    
  ids.Isin,    
  CASE WHEN inst.GroupName IS NOT NULL    
  THEN inst.GroupName    
  ELSE 'B' END AS GroupName,  
  inst.Code  
 INTO #allNseGroupData    
 FROM #tradeIds ids    
 LEFT JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @BSECashId    
  AND ids.Isin = inst.Isin  AND inst.[Status]='A'   
 WHERE ids.RefSegmentId = @NSECashId    
  
  
 SELECT Isin, COUNT(1) AS rcount  
 INTO #multipleGroups  
 FROM #allNseGroupData  
 GROUP BY Isin  
 HAVING COUNT(1)>1  
  
 SELECT t.Isin, t.GroupName   
 INTO #nseGroupData  
 FROM   
 (  
  SELECT grp.Isin, grp.GroupName   
  FROM #allNseGroupData grp  
  WHERE NOT EXISTS  
  (  
   SELECT 1 FROM #multipleGroups mg   
   WHERE mg.Isin=grp.Isin  
  )  
  
  UNION  
  
  SELECT  mg.Isin, grp.GroupName  
  FROM #multipleGroups mg  
  INNER JOIN #allNseGroupData grp ON grp.Isin=mg.Isin AND grp.Code like '5%'  
 )t  
  
 DROP TABLE #multipleGroups  
 DROP TABLE #allNseGroupData  
  
    
 SELECT     
  trade.RefClientId,    
  trade.RefInstrumentId,    
  CASE WHEN trade.BuySell = 'Buy'    
   THEN 1    
   ELSE 0 END BuySell,    
  trade.Rate,    
  trade.Quantity,    
  (trade.Rate * trade.Quantity) AS tradeTO,    
  rules.RefScripGroupId,    
  trade.RefSegmentId    
 INTO #tradeData    
 FROM #tradeIds ids    
 INNER JOIN dbo.CoreTrade trade ON ids.CoreTradeId = trade.CoreTradeId    
 LEFT JOIN #nseGroupData nse ON  ids.Isin = nse.Isin AND ids.RefSegmentId=@NSECashId  
 INNER JOIN #scenarioRules rules ON (ids.RefSegmentId = @BSECashId     
  AND rules.ScripGroup = ids.GroupName) OR (ids.RefSegmentId = @NSECashId    
  AND rules.ScripGroup = nse.GroupName)     
    
 DROP TABLE #tradeIds    
 DROP TABLE #nseGroupData    
    
 SELECT    
  RefClientId,    
  RefScripGroupId,    
  RefInstrumentId,    
  RefSegmentId,    
  BuySell,    
  SUM(tradeTO) AS ClientTO,    
  SUM(Quantity) AS ClientQT    
 INTO #clientTOs    
 FROM #tradeData    
 GROUP BY RefClientId, RefScripGroupId, RefInstrumentId, RefSegmentId, BuySell    
    
 DROP TABLE #tradeData    
    
 SELECT    
  t.RefInstrumentId,    
  t.RefSegmentId,    
  t.BuySell,    
  t.RefScripGroupId,    
  t.RefClientId,    
  t.ClientTO,    
  t.ClientQT    
 INTO #topClients    
 FROM (SELECT     
   RefInstrumentId,    
   RefSegmentId,    
   BuySell,    
   RefScripGroupId,    
   RefClientId,    
   ClientTO,    
   ClientQT,    
   DENSE_RANK() OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell ORDER BY ClientTO DESC) AS RN,
   COUNT(ClientTO) OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell) CRN
  FROM #clientTOs    
 ) t    
 INNER JOIN #scenarioRules rules ON t.RefScripGroupId = rules.RefScripGroupId    
 WHERE t.RN <= rules.Threshold3   AND @IsGroupGreaterThanOneClient<t.CRN 
    
 DROP TABLE #clientTOs    
    
 SELECT    
  RefScripGroupId,    
  RefInstrumentId,     
  RefSegmentId,     
  BuySell,    
  SUM(ClientTO) AS GroupTO    
 INTO #groupedSum    
 FROM #topClients    
 GROUP BY RefScripGroupId, RefInstrumentId, RefSegmentId, BuySell    
    
 SELECT    
  grp.RefScripGroupId,    
  grp.RefInstrumentId,    
  grp.BuySell,    
  grp.RefSegmentId,    
  grp.GroupTO,    
  bhav.NetTurnOver AS ExchangeTO,    
  (grp.GroupTO * 100 / bhav.NetTurnOver) AS GroupContributedPerc    
 INTO #selectedScrips    
 FROM #groupedSum grp    
 INNER JOIN dbo.CoreBhavCopy bhav ON grp.RefInstrumentId = bhav.RefInstrumentId    
 INNER JOIN #scenarioRules rules ON rules.RefScripGroupId = grp.RefScripGroupId    
 WHERE bhav.[Date] = @RunDateInternal AND grp.GroupTO >= rules.Threshold2    
  AND (grp.GroupTO * 100 / bhav.NetTurnOver) >= rules.Threshold    
    
 DROP TABLE #groupedSum    
    
 SELECT    
  cl.RefClientId,    
  client.ClientId,    
  client.[Name] AS ClientName,    
  seg.Segment,    
  @RunDateInternal AS TradeDate,    
  rules.ScripGroup AS GroupName,    
  instru.Code AS ScripCode,    
  instru.[Name] AS ScripName,    
  scrips.GroupTO,    
  scrips.GroupContributedPerc,    
  scrips.ExchangeTO,    
  cl.ClientQT AS ClientTradedQty,    
  (cl.ClientTO / cl.ClientQT) AS AvgRate,    
  cl.ClientTO,    
  (cl.ClientTO * 100 / scrips.ExchangeTO) AS ClientPerc,    
  (cl.ClientTO * 100 / scrips.GroupTO) AS GroupSharePerc,    
  rules.RefScripGroupId,    
  scrips.RefInstrumentId,    
  scrips.RefSegmentId,    
  scrips.BuySell    
 INTO #finalData    
 FROM #selectedScrips scrips    
 INNER JOIN #topClients cl ON scrips.RefInstrumentId = cl.RefInstrumentId     
  AND scrips.RefSegmentId = cl.RefSegmentId AND scrips.BuySell = cl.BuySell    
 INNER JOIN dbo.RefClient client ON cl.RefClientId = client.RefClientId    
 INNER JOIN dbo.RefSegmentEnum seg ON scrips.RefSegmentId = seg.RefSegmentEnumId    
 INNER JOIN #scenarioRules rules ON scrips.RefScripGroupId = rules.RefScripGroupId    
 INNER JOIN dbo.RefInstrument instru ON scrips.RefInstrumentId = instru.RefInstrumentId    
    
 DROP TABLE #topClients    
 DROP TABLE #selectedScrips    
    
 SELECT    
  final.RefClientId,    
  final.ClientId,    
  final.ClientName,    
  final.RefSegmentId,    
  final.Segment,    
  final.TradeDate,    
  final.GroupName,    
  CASE WHEN final.BuySell = 1    
   THEN 'Buy'    
   ELSE 'Sell' END AS BuySell,    
  final.ScripCode,    
  final.ScripName,    
  CONVERT(DECIMAL(28, 2), final.GroupTO) AS GroupTO,    
  CONVERT(DECIMAL(28, 2), final.GroupContributedPerc) AS GroupContributedPerc,    
  CONVERT(DECIMAL(28, 2), final.ExchangeTO) AS ExchangeTO,    
  CONVERT(DECIMAL(28, 2), final.ClientTradedQty) AS ClientTradedQty,    
  CONVERT(DECIMAL(28, 2), final.AvgRate) AS AvgRate,    
  CONVERT(DECIMAL(28, 2), final.ClientTO) AS ClientTO,    
  CONVERT(DECIMAL(28, 2), final.ClientPerc) AS ClientPerc,    
  CONVERT(DECIMAL(28, 2), final.GroupSharePerc) AS GroupSharePerc,    
  STUFF((SELECT ' ; ' + t.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) + '%'    
     FROM #finalData t    
     WHERE t.RefInstrumentId = final.RefInstrumentId AND t.RefSegmentId = final.RefSegmentId    
      AND t.BuySell = final.BuySell AND t.RefClientId <> final.RefClientId    
     ORDER BY t.ClientPerc DESC    
   FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc,    
  final.RefInstrumentId    
 FROM #finalData final    
 INNER JOIN #scenarioRules rules ON final.RefScripGroupId = rules.RefScripGroupId    
 WHERE final.GroupSharePerc >= rules.Threshold4    
 ORDER BY final.RefInstrumentId, final.RefSegmentId, final.BuySell, final.ClientPerc DESC    
  
END  
GO

