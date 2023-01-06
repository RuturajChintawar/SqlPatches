--WEB-76060 START RC
GO
ALTER PROCEDURE dbo.AML_GetCoreAmlClientPurchaseToIncome 
(     
	@TradeDate DATETIME,      
	@ReportType INT,  
	@isRuleDuplicationAllowed BIT = 0  
)      
AS 
BEGIN 
      
	DECLARE @ReportTypeInternal INT, @InnerTradeDate DATETIME, @FirstDate DATETIME, @LastDate DATETIME,    
		@ThresholdIncomeMultiplier INT, @isRuleDuplicationAllowedInternal BIT, @BSECashId INT,
		@NSECashId INT, @ProfileDefault INT, @DefaultIncome DECIMAL(28, 2), @InstitutionalClientDefaultIncome DECIMAL(28, 2),
		@DefaultIncomeAbove1Cr DECIMAL(28, 2)
       
	SET @ReportTypeInternal = @ReportType      
	SET @InnerTradeDate = @TradeDate      
	SET @FirstDate = DATEADD(mm, DATEDIFF(mm, 0, @InnerTradeDate) - 1, 0)      
	SET @LastDate = DATEADD(DAY, -(DAY(@InnerTradeDate)), @InnerTradeDate)      
	SELECT @ThresholdIncomeMultiplier = Threshold2 FROM dbo.RefAmlScenarioRule WHERE RefAmlReportId = @ReportTypeInternal    
	SET @isRuleDuplicationAllowedInternal = @isRuleDuplicationAllowed     
	SET @BSECashId = dbo.GetSegmentId('BSE_CASH')
	SET @NSECashId = dbo.GetSegmentId('NSE_CASH')
	SELECT @ProfileDefault = RefAmlQueryProfileId FROM dbo.RefAmlQueryProfile WHERE [Name] = 'Default'  
	SELECT @InstitutionalClientDefaultIncome = CONVERT(DECIMAL(28, 2), [Value])FROM dbo.SysConfig WHERE [Name] = 'Institutional_Client_Default_Income'
	SELECT @DefaultIncomeAbove1Cr = CONVERT(DECIMAL(28, 2), ISNULL([Value], 0)) FROM dbo.SysConfig WHERE [Name] = 'Income_Value_For_Above_One_Crore'    
	SELECT @DefaultIncome = CONVERT(DECIMAL(28, 2), reportSetting.[Value])      
	FROM dbo.RefAmlQueryProfile qp         
	LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.[Name] = 'Client Purchase to Income'      
	LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId      
		AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId      
		AND reportSetting.[Name] = 'Default_Income'
	WHERE qp.RefAmlQueryProfileId = @ProfileDefault

	SELECT DISTINCT
		CoreTradeId
	INTO #tradeIds
	FROM dbo.CoreTrade
	WHERE TradeDate BETWEEN @FirstDate AND @LastDate
		AND RefSegmentId IN (@BSECashId, @NSECashId)

	 SELECT      
		RefClientId      
	 INTO #clientsToExclude      
	 FROM dbo.LinkRefAmlReportRefClientAlertExclusion      
	 WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportTypeInternal)    
	  AND @InnerTradeDate >= FromDate AND (ToDate IS NULL OR ToDate >= @InnerTradeDate)
       
	SELECT 
		trd.RefClientId,
		trd.Rate * trd.Quantity AS Turnover,
		trd.RefSegmentId,
		CASE WHEN trd.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell
	INTO #trades      
	FROM #tradeIds ids
	INNER JOIN dbo.CoreTrade trd ON ids.CoreTradeId = trd.CoreTradeId
	LEFT JOIN #clientsToExclude clex ON trd.RefClientId = clex.RefClientId
	WHERE clex.RefClientId IS NULL

	DROP TABLE #tradeIds
      
	SELECT
		RefClientId,
		SUM(CASE WHEN BuySell = 1 AND RefSegmentId = @BSECashId THEN Turnover ELSE 0 END) AS BSECashBuyValue,
		SUM(CASE WHEN BuySell = 0 AND RefSegmentId = @BSECashId THEN Turnover ELSE 0 END) AS BSECashSellValue,
		SUM(CASE WHEN BuySell = 1 AND RefSegmentId = @NSECashId THEN Turnover ELSE 0 END) AS NSECashBuyValue,
		SUM(CASE WHEN BuySell = 0 AND RefSegmentId = @NSECashId THEN Turnover ELSE 0 END) AS NSECashSellValue
	INTO #clientWiseData
	FROM #trades
	GROUP BY RefClientId 

	DROP TABLE #trades
	      
	SELECT DISTINCT 
		RefClientId, 
		(BSECashBuyValue + NSECashBuyValue) - (BSECashSellValue + NSECashSellValue) AS NetBuy,      
		BSECashBuyValue + NSECashBuyValue AS TotalBuyValue,      
		BSECashSellValue + NSECashSellValue AS TotalSellValue,
		BSECashBuyValue,
		BSECashSellValue,
		NSECashBuyValue,
		NSECashSellValue      
	INTO #ClientPurchaseToIncome 
	FROM #clientWiseData

	DROP TABLE #clientWiseData

	SELECT DISTINCT
		scenarioRule.RefAmlScenarioRuleId,
		scenarioRule.Threshold,
		scenarioRule.Threshold2,
		linkClientStatus.RefClientStatusId
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule scenarioRule      
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus linkClientStatus 
		ON scenarioRule.RefAmlScenarioRuleId = linkClientStatus.RefAmlScenarioRuleId      
	WHERE scenarioRule.RefAmlReportId = @ReportTypeInternal

	SELECT      
		t.RefClientId,      
		t.Income     
	INTO #IncomeData      
	FROM (SELECT       
			fd.RefClientId,      
			CASE WHEN inc.Income IS NOT NULL      
				THEN inc.Income      
				WHEN incGroup.[Name] IS NOT NULL AND incGroup.IncomeTo > 10000000      
				THEN @DefaultIncomeAbove1Cr      
				WHEN incGroup.[Name] IS NOT NULL      
				THEN incGroup.IncomeTo      
				ELSE @DefaultIncome END AS Income,     
			ROW_NUMBER() OVER (PARTITION BY fd.RefClientId ORDER BY inc.FromDate DESC) AS RN      
		FROM #ClientPurchaseToIncome fd      
		INNER JOIN dbo.RefClient cl ON cl.RefClientId = fd.RefClientId      
		LEFT JOIN dbo.LinkRefClientRefIncomeGroup inc ON fd.RefClientId = inc.RefClientId      
		LEFT JOIN dbo.RefIncomeGroup incGroup ON inc.RefIncomeGroupId = incGroup.RefIncomeGroupId      
	) t      
	WHERE t.Rn = 1 
      
	SELECT 
		pti.RefClientId, 
		cl.ClientId,
		cl.[Name] AS ClientName,
		@FirstDate AS TradeFromDate,
		@LastDate AS TradeToDate,
		CONVERT(DECIMAL(28, 2), pti.NetBuy) AS NetBuy,
		CONVERT(DECIMAL(28, 2), pti.TotalBuyValue) AS TotalBuyValue,
		CONVERT(DECIMAL(28, 2), pti.TotalSellValue) AS TotalSellValue,      
		CONVERT(DECIMAL(28, 2), inc.Income) AS Income,
		CONVERT(DECIMAL(28, 2), rules.Threshold2) AS IncomeMultiplier,
		CONVERT(DECIMAL(28, 2), (inc.Income * rules.Threshold2)) AS IncomeStrength,
		CONVERT(DECIMAL(28, 2), pti.BSECashBuyValue) AS BSECashBuyValue,
		CONVERT(DECIMAL(28, 2), pti.BSECashSellValue) AS BSECashSellValue,
		CONVERT(DECIMAL(28, 2), pti.NSECashBuyValue) AS NSECashBuyValue,
		CONVERT(DECIMAL(28, 2), pti.NSECashSellValue) AS NSECashSellValue,
		CASE WHEN (pti.BSECashBuyValue + pti.BSECashSellValue) > (pti.NSECashBuyValue + pti.NSECashSellValue ) THEN @BSECashId 
			ELSE @NSECashId
			END RefSegmentId
	INTO #finalData
	FROM #ClientPurchaseToIncome pti  
	INNER JOIN dbo.RefClient cl ON pti.RefClientId = cl.RefClientId
	INNER JOIN #scenarioRules rules ON cl.RefClientStatusId = rules.RefClientStatusId
		AND pti.NetBuy >= rules.Threshold
	INNER JOIN #IncomeData inc ON pti.RefClientId= inc.RefClientId
	WHERE pti.NetBuy >= (inc.Income * rules.Threshold2) 

	DROP TABLE #ClientPurchaseToIncome
	DROP TABLE #scenarioRules
	DROP TABLE #IncomeData

	IF @isRuleDuplicationAllowedInternal = 1
		SELECT DISTINCT fd.* FROM #finalData fd

	ELSE
		SELECT DISTINCT fd.* 
		FROM #finalData fd
		LEFT JOIN dbo.CoreAmlScenarioAlert dup ON dup.RefAmlReportId = @ReportTypeInternal  
			AND dup.RefClientId = fd.RefClientId
			AND dup.TransactionFromDate = @FirstDate  
			AND dup.TransactionToDate = @LastDate  
			AND ISNULL(dup.NetBuyValue, 0) = ISNULL(fd.NetBuy, 0)
			AND ISNULL(dup.BuyTurnover, 0) = ISNULL(fd.TotalBuyValue, 0)
			AND ISNULL(dup.SellTurnover, 0) = ISNULL(fd.TotalSellValue, 0)
			AND ISNULL(dup.IncomeGroupName, '') = ISNULL(CONVERT(VARCHAR(50), fd.Income) COLLATE DATABASE_DEFAULT, '')
			AND ISNULL(dup.IncomeMultiplier, 0) = ISNULL(fd.IncomeMultiplier, 0) 
			AND ISNULL(dup.IncomeStrength, 0) = ISNULL(fd.IncomeStrength, 0)
			AND ISNULL(dup.BseCashBuyValue, 0) = ISNULL(fd.BSECashBuyValue, 0)
			AND ISNULL(dup.BseCashSellValue, 0) = ISNULL(fd.BseCashSellValue, 0)
			AND ISNULL(dup.NseCashBuyValue, 0) = ISNULL(fd.NseCashBuyValue, 0) 
			AND ISNULL(dup.NseCashSellValue, 0) = ISNULL(fd.NseCashSellValue, 0)
			AND ISNULL(dup.RefSegmentEnumId, 0) = ISNULL(fd.RefSegmentId,0)
		WHERE dup.CoreAmlScenarioAlertId IS NULl

END     
GO
--WEB-76060 END RC
--WEB-76060  START RC
GO
	DECLARE @BSECashId INT,
		@NSECashId INT, @ReportId INT
	SET @BSECashId = dbo.GetSegmentId('BSE_CASH')
	SET @NSECashId = dbo.GetSegmentId('NSE_CASH')
	SELECT @ReportId = ref.RefAmlReportId FROM dbo.RefAmlReport ref WHERE ref.[Name] ='S102 Client Purchase to Income'

	UPDATE re
	SET Re.RefSegmentEnumId = CASE WHEN (re.BseCashBuyValue+re.BseCashSellValue)>(re.NseCashBuyValue+re.NseCashSellValue) THEN @BSECashId
								ELSE @NSECashId
								END
	FROM dbo.CoreAmlScenarioAlert re WHERE re.RefAmlReportId = @ReportId
GO
--WEB-76060 END RC
--WEB-76060 START RC
--S104 PATCH
GO
ALTER PROCEDURE [dbo].[Aml_GetClientNetSellScenarioData]      
(  
@fromdate datetime,      
@todate datetime,  
@isRuleDuplicationAllowed BIT=0  
)      
AS      
 BEGIN      
      
 declare @FromDateInternal datetime      
 declare @ToDateInternal datetime, @isRuleDuplicationAllowedInternal BIT , @BSECashId INT,
		@NSECashId INT     
      
 set @FromDateInternal=dbo.GetDateWithoutTime(@fromdate)      
 set @ToDateInternal=dbo.GetDateWithoutTime(@todate)      
 SET @isRuleDuplicationAllowedInternal=@isRuleDuplicationAllowed  
      
 DECLARE @ReportIdInternal INT      
SELECT @ReportIdInternal = RefAmlReportId      
FROM dbo.RefAmlReport      
WHERE Name = 'S104 Client Net Sell'      
      
 SELECT seg.RefSegmentEnumId,      
    seg.Segment      
  INTO #RequiredSegment      
  FROM dbo.RefSegmentEnum seg      
  WHERE (seg.Segment IN ('BSE_CASH','NSE_CASH'))  
  
  SET @BSECashId = dbo.GetSegmentId('BSE_CASH')
  SET @NSECashId = dbo.GetSegmentId('NSE_CASH')
  
  
 -- client to exclude  
 SELECT  
  RefClientId  
 INTO #clientsToExclude  
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion  
 WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportIdInternal)     
 AND @FromDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @ToDateInternal)  
      
    SELECT trade.RefClientId,      
    trade.TradeDate,      
    SUM(CASE WHEN seg.Segment = 'BSE_CASH' and trade.BuySell='Sell' THEN (trade.Rate * trade.Quantity) ELSE 0 END) AS BseCashSellValue,      
    SUM(CASE WHEN seg.Segment = 'NSE_CASH' and trade.BuySell='Sell' THEN (trade.Rate * trade.Quantity) ELSE 0 END) AS NseCashSellValue,      
    SUM(CASE WHEN seg.Segment = 'BSE_CASH' and trade.BuySell='Buy' THEN (trade.Rate * trade.Quantity) ELSE 0 END) AS BseCashBuyValue,      
    SUM(CASE WHEN seg.Segment = 'NSE_CASH' and trade.BuySell='Buy' THEN (trade.Rate * trade.Quantity) ELSE 0 END) AS NseCashBuyValue,      
    SUM(CASE WHEN trade.BuySell='Buy' THEN (trade.Rate * trade.Quantity) ELSE 0 END) AS TotalBuyValue,      
    SUM(CASE WHEN trade.BuySell='Sell' THEN (trade.Rate * trade.Quantity) ELSE 0 END) AS TotalSellValue      
  INTO #FilteredTrade      
  FROM dbo.CoreTrade trade      
  INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId  
  LEFT JOIN #clientsToExclude ex ON ex.RefClientId=trade.RefClientId
  where (trade.TradeDate BETWEEN @FromDateInternal AND @ToDateInternal ) and ex.RefClientId IS NULL     
  Group by trade.RefClientId,      
     trade.TradeDate,      
     trade.BuySell      
                
   SELECT DISTINCT RefClientId    
   into #clientIds    
   FROM #FilteredTrade    
      
      --get default income      
      
 DECLARE @DefaultIncome VARCHAR (5000) ,@IncomeMultiplier DECIMAL(28,2) ,@NetworthMultiplier DECIMAL(28,2)     
  SELECT @DefaultIncome = reportSetting.Value      
  FROM dbo.RefAmlQueryProfile qp         
  LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.Name = 'Client Purchase to Income'      
  LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId      
      AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId      
      AND reportSetting.Name = 'Default_Income'      
  WHERE qp.Name = 'Default'      

  SELECT @IncomeMultiplier=CONVERT(DECIMAL(28,2),[Value]) FROM dbo.SysConfig WHERE [Name] ='Aml_Client_Income_Multiplier' AND [Value] <>''
  SELECT @NetworthMultiplier=CONVERT(DECIMAL(28,2),[Value]) FROM dbo.SysConfig WHERE [Name] ='Aml_Client_Networth_Multiplier' AND [Value]<>''
        
      
    --get client income group      
     select RefClientId,      
 LinkRefClientRefIncomeGroupId       
 into #LinkRefClientRefIncomeGroup      
 from (      
 select clientIncomeGroup.RefClientId,      
 LinkRefClientRefIncomeGroupId,      
 ROW_NUMBER() over(partition by clientIncomeGroup.RefClientId order by AddedOn desc) as RowIndex       
 from dbo.LinkRefClientRefIncomeGroup clientIncomeGroup       
 inner join  #clientIds trade  on      
     (clientIncomeGroup.RefClientId = trade.RefClientId)      
     and       
    (clientIncomeGroup.FromDate IS NULL or @FromDateInternal >= clientIncomeGroup.FromDate)      
    and       
    (clientIncomeGroup.ToDate IS NULL or @ToDateInternal <= clientIncomeGroup.ToDate)      
    --where clientIncomeGroup.RefClientId=14324      
    ) temp       
    where temp.RowIndex=1      
      
    --GET DEFAULT NETWORTH      
           DECLARE @BseCashSegmentId INT      
        SET @BseCashSegmentId = dbo.GetSegmentId('BSE_CASH')      
     DECLARE @DefaultNetworth BIGINT      
  SELECT @DefaultNetworth = cliNetSellPoint.DefaultNetworth       
  FROM dbo.RefAmlQueryProfile qp         
    LEFT JOIN dbo.LinkRefAmlQueryProfileRefSegment qpSegment ON qpSegment.RefSegmentId = @BseCashSegmentId       
        AND qpSegment.RefAmlQueryProfileId = qp.RefAmlQueryProfileId            
    LEFT JOIN dbo.SysAmlClientNetSellPoints cliNetSellPoint ON cliNetSellPoint.LinkRefAmlQueryProfileRefSegmentId = qpSegment.LinkRefAmlQueryProfileRefSegmentId      
  WHERE qp.Name = 'Default'       
    --get client Income strength      
SELECT       
  cni.RefClientId,      
  client.RefIntermediaryId,      
  CASE WHEN  (client.IncomeMultiplier IS NULL and @IncomeMultiplier IS NULL) OR (client.NetworthMultiplier IS NULL and @NetworthMultiplier IS NULL) 
			THEN (cni.Income+cni.Networth)
  ELSE(((cni.Networth) * COALESCE(client.NetworthMultiplier,ISNULL(@NetworthMultiplier,1)))+((cni.Income) * COALESCE(client.IncomeMultiplier,ISNULL(@IncomeMultiplier,1)))) END AS FairValue,      
  cni.Networth,      
  COALESCE(client.NetworthMultiplier,ISNULL(@NetworthMultiplier,1)) as NetworthMultiplier,
  COALESCE(client.IncomeMultiplier,ISNULL(@IncomeMultiplier,1)) as IncomeMultiplier,      
  cni.Income      
 INTO #ClientIncomeStrength      
 FROM      
  (SELECT      
   COALESCE (clientIncomeGroup.Networth, cliIncomeGroupLatest.Networth, @DefaultNetworth, 0) AS Networth,      
   COALESCE (clientIncomeGroup.Income, cliIncomeGroupLatest.Income, incomeGroup.IncomeTo, CAST(@DefaultIncome AS BIGINT), 0) AS Income,      
   trade.RefClientId      
   FROM #clientIds trade  
     Left join #LinkRefClientRefIncomeGroup templink on templink.RefClientId=trade.RefClientId      
     LEFT JOIN dbo.LinkRefClientRefIncomeGroup clientIncomeGroup on clientIncomeGroup.LinkRefClientRefIncomeGroupId=templink.LinkRefClientRefIncomeGroupId      
     LEFT JOIN dbo.LinkRefClientRefIncomeGroupLatest cliIncomeGroupLatest ON cliIncomeGroupLatest.RefClientId = trade.RefClientId      
     LEFT JOIN dbo.RefIncomeGroup incomeGroup       
     ON incomeGroup.RefIncomeGroupId = ISNULL(clientIncomeGroup.RefIncomeGroupId,cliIncomeGroupLatest.RefIncomeGroupId)        
  )cni      
  INNER JOIN dbo.RefClient client ON (client.RefClientId=cni.RefClientId)      
      
      
  select RefClientId,      
   SUM(BSECashBuyValue) as BSECashBuyValue,      
   SUM(BSECashSellValue) as BSECashSellValue,      
   SUM(NSECashBuyValue) as NSECashBuyValue,      
   SUM(NSECashSellValue) as NSECashSellValue      
  Into #FilteredTradeData      
 from #FilteredTrade      
 GROUP BY RefClientId      
      
      
  select * into #finalTrade from(select       
  DISTINCT      
  @FromDateInternal as TradeFromDate,      
  @ToDateInternal as TradeToDate,      
  filtrade.RefClientId,       
  filtrade.TradeDate,      
  CAST(fil.BseCashBuyValue AS DECIMAL(28,2)) AS BseCashBuyValue,      
  CAST(fil.BseCashSellValue AS DECIMAL(28,2)) AS BseCashSellValue,      
  CAST(fil.NseCashBuyValue AS DECIMAL(28,2)) AS NseCashBuyValue,      
  CAST(fil.NseCashSellValue AS DECIMAL(28,2)) AS NseCashSellValue,      
  CAST((fil.BseCashBuyValue+fil.NseCashBuyValue) AS DECIMAL(28,2)) as TotalBuyValue,      
  CAST((fil.BseCashSellValue+fil.NseCashSellValue) AS DECIMAL(28,2)) as TotalSellValue,      
  CAST(((fil.BseCashSellValue+fil.NseCashSellValue)-(fil.NseCashBuyValue+fil.BseCashBuyValue)) AS DECIMAL(28,2)) as NetSell,      
  cni.FairValue,      
  cni.Networth,      
  cni.NetworthMultiplier      
  from #FilteredTrade filtrade      
  INNER JOIN #FilteredTradeData fil ON fil.RefClientId=filtrade.RefClientId      
  INNER JOIN #ClientIncomeStrength cni ON filtrade.RefClientId=cni.RefClientId)as temp      
  where temp.NetSell>=temp.FairValue      
       
      
       
select * from(      
  select      
  finaltrade.TradeFromDate,      
  finaltrade.TradeToDate,       
  finaltrade.RefClientId,       
  finaltrade.TradeDate,      
  finaltrade.BseCashBuyValue,      
  finaltrade.BseCashSellValue,      
  finaltrade.NseCashBuyValue,      
  finaltrade.NseCashSellValue,      
  finaltrade.TotalBuyValue,      
  finaltrade.TotalSellValue,      
  cni.FairValue,      
  cni.Networth,      
  cni.NetworthMultiplier,      
  income.[Name] as Income,      
  client.ClientId,      
  client.[Name] as ClientName,      
  cni.IncomeMultiplier,      
  finaltrade.NetSell,      
  ROW_NUMBER() over(partition by finaltrade.RefClientId order by finaltrade.TradeDate ) as RowIndex,
  CASE WHEN (finaltrade.BseCashBuyValue + finaltrade.BseCashSellValue) > (finaltrade.NseCashBuyValue + finaltrade.NseCashSellValue ) THEN @BSECashId 
			ELSE @NSECashId
			END RefSegmentId
   from #finalTrade finaltrade      
  INNER JOIN dbo.RefClient client ON finaltrade.RefClientId = client.RefClientId      
  INNER JOIN #ClientIncomeStrength cni ON finaltrade.RefClientId=cni.RefClientId      
  INNER JOIN dbo.RefClientStatus clientStatus ON clientStatus.RefClientStatusId = client.RefClientStatusId      
  --LEFT JOIN dbo.CoreBhavCopy bhavcopy On [Date]=finaltrade.TradeDate      
  INNER JOIN dbo.LinkRefClientRefIncomeGroupLatest latestIncome ON client.RefClientId = latestIncome.RefClientId      
  INNER JOIN dbo.RefIncomeGroup income ON latestIncome.RefIncomeGroupId = income.RefIncomeGroupId      
  WHERE EXISTS      
    (      
     SELECT 1      
     FROM dbo.RefAmlScenarioRule scenarioRule      
     INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus linkClientStatus ON scenarioRule.RefAmlScenarioRuleId = linkClientStatus.RefAmlScenarioRuleId      
     WHERE scenarioRule.RefAmlReportId = @ReportIdInternal AND      
       clientStatus.RefClientStatusId = linkClientStatus.RefClientStatusId AND      
       finaltrade.NetSell>=scenarioRule.Threshold       
    ))as final       
    where final.RowIndex=1      
 AND NOT EXISTS   
 (  
  SELECT 1 FROM dbo.CoreAmlScenarioAlert dup  
  WHERE @isRuleDuplicationAllowedInternal=0  
  AND dup.RefClientId=final.RefClientId  
  AND ISNULL(dup.NetSellValue,0)=ISNULL(final.NetSell,0)
  AND ISNULL(dup.BuyTurnover,0)=ISNULL(final.TotalBuyValue,0) 
  AND ISNULL(dup.SellTurnover,0)=ISNULL(final.TotalSellValue,0) 
  AND ISNULL(dup.IncomeGroupName,'')=ISNULL(final.Income,'')  
  AND ISNULL(dup.IncomeMultiplier,0)=ISNULL(final.IncomeMultiplier,0)  
  AND ISNULL(dup.FairValue,0)=ISNULL(final.FairValue,0)  
  AND ISNULL(dup.NetWorth,0)=ISNULL(final.Networth,0)  
  AND ISNULL(dup.NetworthMultiplier,0)=ISNULL(final.NetworthMultiplier,0)  
  AND ISNULL(dup.BseCashBuyValue,0)=ISNULL(final.BseCashBuyValue,0)   
  AND ISNULL(dup.BseCashSellValue,0)=ISNULL(final.BseCashSellValue,0)    
  AND ISNULL(dup.NseCashBuyValue,0)=ISNULL(final.NseCashBuyValue,0)    
  AND ISNULL(dup.NseCashSellValue,0)=ISNULL(final.NseCashSellValue,0) 
  AND ISNULL(dup.RefSegmentEnumId,0 ) = ISNULL(final.RefSegmentId,0)
  AND dup.TransactionFromDate=final.TradeFromDate  
  AND dup.TransactionToDate=final.TradeToDate  
 )  
 END
GO
--WEB-76060 END RC

--WEB-76060 START RC
--S104 PATCH old alerts
GO
	DECLARE @BSECashId INT,
		@NSECashId INT, @ReportId INT
	SET @BSECashId = dbo.GetSegmentId('BSE_CASH')
	SET @NSECashId = dbo.GetSegmentId('NSE_CASH')
	SELECT @ReportId = ref.RefAmlReportId FROM dbo.RefAmlReport ref WHERE ref.[Name] ='S104 Client Net Sell'

	UPDATE re
	SET Re.RefSegmentEnumId = CASE WHEN (re.BseCashBuyValue+re.BseCashSellValue)>(re.NseCashBuyValue+re.NseCashSellValue) THEN @BSECashId
								ELSE @NSECashId
								END
	FROM dbo.CoreAmlScenarioAlert re WHERE re.RefAmlReportId = @ReportId
GO
--WEB-76060 END RC
--WEB-76060 START RC
--S126 PATCH
GO
 ALTER PROCEDURE dbo.AML_GetProfitCompareWithExchangeTORecords  
(  
 @ReportId INT,  
 @RunDate DATETIME,  
 @Days INT  
)  
AS  
BEGIN  
 DECLARE @RunDateInternal DATETIME, @DaysInternal INT, @NSE_CASH INT, @BSE_CASH INT,  
  @ReportIdInternal INT, @FromDateInternal DATETIME, @InstrumentRefEntityTypeId INT,   
  @EntityAttributeTypeRefEnumValueId INT  
  
 SET @RunDateInternal = @RunDate  
 SET @ReportIdInternal = @ReportId  
 SET @DaysInternal = @Days  
 SET @FromDateInternal = DATEADD(DD, -@DaysInternal, @RunDateInternal)  
 SELECT @NSE_CASH = seg.RefSegmentEnumId FROM dbo.RefSegmentEnum seg WHERE seg.Segment = 'NSE_CASH'  
 SELECT @BSE_CASH = seg.RefSegmentEnumId FROM dbo.RefSegmentEnum seg WHERE seg.Segment = 'BSE_CASH'  
 SELECT @InstrumentRefEntityTypeId = RefEntityTypeId FROM dbo.RefEntityType WHERE Code = 'Instrument'  
 SET @EntityAttributeTypeRefEnumValueId = dbo.GetEnumValueId('EntityAttributeType', 'UserDefined')  
  
  
 SELECT  segment.RefSegmentEnumId   
 INTO #requiredSegment  
 FROM dbo.RefSegmentEnum segment   
 WHERE segment.Segment IN ('NSE_CASH','BSE_CASH')  
  
 --getting ScenarioRules in start  
 SELECT  
  linkClientStatus.RefClientStatusId,  
  rul.RefAmlScenarioRuleId,  
  rul.RuleNumber,  
  rul.Threshold,  
  rul.Threshold2,  
  rul.Threshold3,  
  scrip.[Name] AS ScripGroup,  
  scrip.RefScripGroupId  
 INTO #scenarioRules  
 FROM dbo.RefAmlScenarioRule rul  
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId  
 INNER JOIN dbo.RefScripGroup scrip ON scrip.RefScripGroupId = link.RefScripGroupId  
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus linkClientStatus ON rul.RefAmlScenarioRuleId = linkClientStatus.RefAmlScenarioRuleId  
 WHERE rul.RefAmlReportId = @ReportIdInternal  
  
 SELECT    
  RefClientId    
 INTO #clientsToExclude    
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
 WHERE (RefAmlReportId IS NULL OR RefAmlReportId = @ReportIdInternal)  
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)  
  
   
  
 --pulling sell trade first on rundate to identify instrument and client ids  
 SELECT  
  ROW_NUMBER() OVER (ORDER BY t.TradeDate) AS RowNum,  
  t.RefClientId,  
  TradeDate,   
  t.RefInstrumentId,  
  0 AS BuySell,--for 'Sell' keeping the BIT 0  
  SUM(t.Quantity) AS Quantity,  
  SUM(t.Quantity*t.Rate)/SUM(t.Quantity) AS Rate,   
  (SUM(t.Quantity) * SUM(t.Quantity*t.Rate)/SUM(t.Quantity)) AS Turnover  
 INTO #sellTrade  
 FROM dbo.CoreTrade t  
 INNER JOIN #requiredSegment segment ON segment.RefSegmentEnumId = t.RefSegmentId  
 LEFT JOIN #clientsToExclude excludeClient  ON t.RefClientId = excludeClient.RefClientId  
 WHERE t.TradeDate =@RunDateInternal   
 AND excludeClient.RefClientId IS NULL AND t.BuySell='Sell'  
 GROUP BY t.RefClientId, TradeDate, t.RefInstrumentId, t.BuySell  
 ORDER BY t.TradeDate, t.RefClientId, t.RefInstrumentId  
   
 DROP TABLE #clientsToExclude  
  
 CREATE INDEX IX_#sellTrade_RefClientId_RefInstrumentId On #sellTrade(RefClientId,RefInstrumentId)  
  
 --DROP TABLE #coretrade  
  
 --SELECT *  
 --INTO #sellTrade   
 --FROM #trade   
 --WHERE BuySell = 0 AND TradeDate = @RunDateInternal  
  
 --distinct client and instrument from sell trade to pull buy trades  
 SELECT DISTINCT RefClientId,RefInstrumentId   
 INTO #filteredInstAndClient    
 FROM #sellTrade  
  
   
 --pulling buy trades for required Instruments and Client  
 SELECT  
  ROW_NUMBER() OVER (ORDER BY trade.TradeDate) AS RowNum,  
  trade.RefClientId,  
  TradeDate,   
  trade.RefInstrumentId,  
  1 AS BuySell, --for 'Buy' keeping the BIT 1  
  SUM(trade.Quantity) AS Quantity,  
  SUM(trade.Quantity*trade.Rate)/SUM(trade.Quantity) AS Rate
 INTO #Buytrade  
 FROM dbo.CoreTrade trade  
 INNER JOIN #requiredSegment segment ON segment.RefSegmentEnumId = trade.RefSegmentId  
 INNER JOIN #filteredInstAndClient client ON trade.RefClientId = client.RefClientId AND trade.RefInstrumentId = client.RefInstrumentId  
 WHERE trade.TradeDate BETWEEN @FromDateInternal AND @RunDateInternal AND trade.BuySell ='Buy'  
 GROUP BY trade.RefClientId, TradeDate, trade.RefInstrumentId, trade.BuySell  
 ORDER BY trade.TradeDate, trade.RefClientId, trade.RefInstrumentId  
  
 CREATE INDEX IX_#Buytrade_RefClientId_RefInstrumentId On #Buytrade(RefClientId,RefInstrumentId)  
 --trying to filter alterType1 & 2 in the same  
 SELECT   
  sellTrade.TradeDate,   
  t1.RefClientId,   
  t1.RefInstrumentId,   
  selltrade.Quantity AS SellTradeBuyQty,  
  SUM(t2.Quantity) AS BuyTradeBuyQty,  
  SUM(t2.Quantity*t2.Rate)/SUM(t2.Quantity) AS BuyRate,  
  (selltrade.Quantity * (SUM(t2.Quantity*t2.Rate)/SUM(t2.Quantity))) AS BuyTurnover,  
  selltrade.Quantity AS SellQty,  
  selltrade.Rate AS SellRate,  
  selltrade.Turnover AS SellTurnover  
 INTO #consolidateAlert1And2  
 FROM #Buytrade t1   
 INNER JOIN #filteredInstAndClient filInstClnt ON t1.RefClientId=filInstClnt.RefClientId   
  AND t1.RefInstrumentId = filInstClnt.RefInstrumentId  
 INNER JOIN #sellTrade sellTrade ON t1.RefInstrumentId = selltrade.RefInstrumentId   
  AND selltrade.RefClientId = t1.RefClientId  
 INNER JOIN #Buytrade t2 ON t1.RefClientId=t2.RefClientId   
  AND t1.RefInstrumentId = t2.RefInstrumentId AND t1.RowNum <= t2.RowNum   
 GROUP BY sellTrade.TradeDate,t1.TradeDate, t1.RefClientId, t1.RefInstrumentId, selltrade.Quantity, selltrade.Rate, selltrade.Turnover  
  --,t1.BuySell,t1.Quantity, t1.Rate, t1.Turnover  
 HAVING SUM(t2.Quantity) >= selltrade.Quantity  
 ORDER BY t1.TradeDate DESC  
   
 DROP TABLE #sellTrade  
  
 DROP TABLE #Buytrade  
  
 SELECT  *   
 INTO #FinalAlerts  
 FROM (  
 --alertType1  
  SELECT    
   TradeDate,   
   RefClientId,   
   RefInstrumentId,   
   BuyTradeBuyQty AS BuyQty,  
   BuyRate,  
   BuyTurnover,  
   SellQty,  
   SellRate,  
   SellTurnover   
  FROM #consolidateAlert1And2  
  WHERE BuyTradeBuyQty = SellQty  
  
  UNION  
  
  --alertType 2  
  SELECT  
   TradeDate,   
   RefClientId,   
   RefInstrumentId,   
   SellTradeBuyQty AS BuyQty,  
   BuyRate,  
   BuyTurnover,  
   SellQty,  
   SellRate,  
   SellTurnover  
  FROM(  
   SELECT  * ,  
   ROW_NUMBER() OVER (PARTITION BY RefInstrumentId,RefClientId ORDER BY BuyTradeBuyQty) AS finalRowNUm  
   --partition by BuyTradeBuyQty  
   FROM #consolidateAlert1And2   
   WHERE BuyTradeBuyQty > SellQty  
  ) t WHERE t.finalRowNUm = 1 AND NOT EXISTS (SELECT 1 FROM #consolidateAlert1And2 FA1  
    WHERE BuyTradeBuyQty = SellQty AND t.RefClientId=FA1.RefClientId AND t.RefInstrumentId=FA1.RefInstrumentId)  
 ) alert  
  
   
  
   
  
 SELECT DISTINCT RefClientId   
 INTO #DistinctClients  
 FROM #FinalAlerts  
  
 SELECT   
  cl.RefClientId,  
  client.ClientId,  
  client.[Name],  
  inc.Income,  
  client.RefClientStatusId  
 INTO #ClientDetails  
 FROM #DistinctClients cl  
 INNER JOIN dbo.RefClient client ON client.RefClientId = cl.RefClientId  
 LEFT JOIN dbo.LinkRefClientRefIncomeGroupLatest inc ON inc.RefClientId=client.RefClientId  
  
   
 SELECT DISTINCT   
  inst.RefInstrumentId,  
  inst.Isin,    
  inst.GroupName,    
  inst.RefSegmentId  
 INTO #tradeIds    
 FROM #FinalAlerts trade  
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId   
  
 SELECT DISTINCT  
  grp.RefScripGroupId,  
  grp.[Name] AS ScripGroup,  
  attrVal.CoreEntityAttributeValueId,  
  attrDetail.ForEntityId AS RefInstrumentId  
 INTO #internalCodes  
 FROM #tradeIds trade  
 INNER JOIN dbo.CoreEntityAttributeDetail attrDetail ON attrDetail.ForEntityId = trade.RefInstrumentId  
 INNER JOIN dbo.RefEntityAttribute attr ON attrDetail.RefEntityAttributeId = attr.RefEntityAttributeId   
 INNER JOIN dbo.CoreEntityAttributeValue attrVal ON attr.RefEntityAttributeId = attrVal.RefEntityAttributeId  
  AND attrDetail.CoreEntityAttributeValueId = attrVal.CoreEntityAttributeValueId  
 INNER JOIN dbo.RefScripGroup grp ON grp.[Name] = attrVal.UserDefinedValueName  
 WHERE attr.ForRefEntityTypeId = @InstrumentRefEntityTypeId  
 AND attr.EntityAttributeTypeRefEnumValueId = @EntityAttributeTypeRefEnumValueId  
 AND attr.Code IN ('TW01','TW02')  
 AND @RunDateInternal >= attrDetail.StartDate  
 AND (attrDetail.EndDate IS NULL OR attrDetail.EndDate > @RunDateInternal)  
  
 SELECT DISTINCT   
  ids.Isin,    
  COALESCE(inst2.GroupName, inter.ScripGroup, 'B') AS GroupName,  
  COALESCE(inst2.Code, inst1.Code) AS Code  
 INTO #allNseGroupData  
 FROM #tradeIds ids  
 INNER JOIN dbo.RefInstrument inst1 ON ids.RefInstrumentId = inst1.RefInstrumentId  
 LEFT JOIN dbo.RefInstrument inst2 ON inst2.RefSegmentId = @BSE_CASH    
  AND ids.Isin = inst2.Isin AND inst2.[Status] = 'A'  
 LEFT JOIN #internalCodes inter ON ids.RefInstrumentId = inter.RefInstrumentId  
 WHERE ids.RefSegmentId = @NSE_CASH  
  
 DROP TABLE #internalCodes  
 DROP TABLE #tradeIds  
   
 SELECT Isin, COUNT(1) AS rcount  
 INTO #multipleGroups  
 FROM #allNseGroupData  
 GROUP BY Isin  
 HAVING COUNT(1) > 1  
  
 SELECT DISTINCT t.Isin, t.GroupName   
 INTO #nseGroupData  
 FROM (SELECT grp.Isin, grp.GroupName   
  FROM #allNseGroupData grp  
  WHERE NOT EXISTS (SELECT 1 FROM #multipleGroups mg   
   WHERE mg.Isin = grp.Isin)  
    
  UNION  
    
  SELECT mg.Isin, grp.GroupName  
  FROM #multipleGroups mg  
   INNER JOIN #allNseGroupData grp ON grp.Isin = mg.Isin AND grp.Code like '5%'  
 ) t  
  
 DROP TABLE #multipleGroups  
 DROP TABLE #allNseGroupData  
  
 SELECT  
  alert.RefClientId,  
  client.ClientId,  
  client.[Name] AS ClientName,  
  alert.TradeDate,  
  CASE WHEN inst.RefSegmentId = @NSE_CASH   
   THEN nse.GroupName   
   ELSE inst.GroupName END AS GroupName,  
  inst.Code AS ScripCode,  
  inst.[Name] AS Scrip,  
  alert.RefInstrumentId,  
  client.Income,  
  alert.BuyQty,  
  alert.BuyRate,  
  alert.BuyTurnover,  
  alert.SellQty,  
  alert.SellRate,  
  alert.SellTurnover,  
  (alert.SellTurnover * 100) / bhav.NetTurnOver AS SellPercentage,  
  bhav.NetTurnOver ExchangeTO,  
  (alert.SellTurnover  - alert.BuyTurnover) AS TotalProfit,  
  (((alert.SellTurnover - alert.BuyTurnover) * 100) / alert.BuyTurnover) AS PercentProfit,
  inst.RefSegmentId
 FROM #FinalAlerts alert  
 INNER JOIN #ClientDetails client ON client.RefClientId = alert.RefClientId  
 INNER JOIN dbo.RefInstrument inst ON alert.RefInstrumentId = inst.RefInstrumentId  
 LEFT JOIN dbo.CoreBhavCopy bhav ON alert.TradeDate = bhav.[Date]  
  AND alert.RefInstrumentId = bhav.RefInstrumentId  
 LEFT JOIN #nseGroupData nse ON inst.Isin = nse.Isin AND inst.RefSegmentId = @NSE_CASH  
 INNER JOIN #scenarioRules rules ON ((inst.RefSegmentId = @BSE_CASH   
  AND rules.ScripGroup = inst.GroupName) OR (inst.RefSegmentId = @NSE_CASH    
  AND rules.ScripGroup = nse.GroupName))  
  AND rules.RefClientStatusId = client.RefClientStatusId  
  AND ((alert.SellTurnover * 100) / bhav.NetTurnOver) >= rules.Threshold  
  AND (((alert.SellTurnover - alert.BuyTurnover) * 100) / alert.BuyTurnover) >= rules.Threshold2  
  AND (alert.SellTurnover - alert.BuyTurnover) >= rules.Threshold3  
 WHERE alert.TradeDate = @RunDateInternal  
  
END  
GO
--WEB-76060 END RC

--WEB-76060 START RC
--S126 PATCH old alerts
GO
	DECLARE  @ReportId INT
	
	SELECT @ReportId = ref.RefAmlReportId FROM dbo.RefAmlReport ref WHERE ref.[Name] ='S126 Profit compare with Exchange T/o'

	UPDATE re
	SET Re.RefSegmentEnumId = inst.RefSegmentId
	FROM dbo.CoreAmlScenarioAlert re 
	INNER JOIN dbo.RefInstrument inst ON re.RefAmlReportId = @ReportId AND inst.RefInstrumentId = re.RefInstrumentId  
GO
--WEB-76060 END RC

--WEB-76060 START RC
--S127 PATCH
GO
ALTER PROCEDURE dbo.Aml_getlosscomparewithexchangetorecords (@ReportId INT,
                                                             @RunDate  DATETIME,
                                                             @Days     INT)
AS
  BEGIN
      DECLARE @RunDateInternal                   DATETIME,
              @DaysInternal                      INT,
              @NSE_CASH                          INT,
              @BSE_CASH                          INT,
              @ReportIdInternal                  INT,
              @FromDateInternal                  DATETIME,
              @InstrumentRefEntityTypeId         INT,
              @EntityAttributeTypeRefEnumValueId INT

      SET @RunDateInternal = @RunDate
      SET @ReportIdInternal = @ReportId
      SET @DaysInternal = @Days
      SET @FromDateInternal = Dateadd(dd, -@DaysInternal, @RunDateInternal)

      SELECT @NSE_CASH = seg.RefSegmentEnumId
      FROM   dbo.RefSegmentEnum seg
      WHERE  seg.Segment = 'NSE_CASH'

      SELECT @BSE_CASH = seg.RefSegmentEnumId
      FROM   dbo.RefSegmentEnum seg
      WHERE  seg.Segment = 'BSE_CASH'

      SELECT @InstrumentRefEntityTypeId = RefEntityTypeId
      FROM   dbo.RefEntityType
      WHERE  Code = 'Instrument'

      SET @EntityAttributeTypeRefEnumValueId =
      dbo.Getenumvalueid('EntityAttributeType', 'UserDefined')

      SELECT segment.RefSegmentEnumId
      INTO   #requiredsegment
      FROM   dbo.RefSegmentEnum segment
      WHERE  segment.Segment IN ( 'NSE_CASH', 'BSE_CASH' )

      --getting ScenarioRules in start    
      SELECT linkClientStatus.RefClientStatusId,
             rul.RefAmlScenarioRuleId,
             rul.RuleNumber,
             rul.Threshold,
             rul.Threshold2,
             rul.Threshold3,
             scrip.[Name] AS ScripGroup,
             scrip.RefScripGroupId
      INTO   #scenariorules
      FROM   dbo.RefAmlScenarioRule rul
             INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup link
                     ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId
             INNER JOIN dbo.RefScripGroup scrip
                     ON scrip.RefScripGroupId = link.RefScripGroupId
             INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus
                        linkClientStatus
                     ON rul.RefAmlScenarioRuleId =
                        linkClientStatus.RefAmlScenarioRuleId
      WHERE  rul.RefAmlReportId = @ReportIdInternal

      SELECT RefClientId
      INTO   #clientstoexclude
      FROM   dbo.LinkRefAmlReportRefClientAlertExclusion
      WHERE  ( ExcludeAllScenarios = 1
                OR RefAmlReportId = @ReportIdInternal )
             AND @RunDateInternal >= FromDate
             AND ( ToDate IS NULL
                    OR ToDate >= @RunDateInternal )

      -- extracting required Clients from all the clients    
      SELECT Row_number()
               OVER (
                 ORDER BY t.TradeDate)                  AS RowNum,
             t.RefClientId,
             TradeDate,
             t.RefInstrumentId,
             0                                          AS BuySell,
             --for 'Sell' keeping the BIT 0    
             Sum(t.Quantity)                            AS Quantity,
             Sum(t.Quantity * t.Rate) / Sum(t.Quantity) AS Rate,
             ( Sum(t.Quantity) * (Sum(t.Quantity * t.Rate) / Sum(t.Quantity)) )          AS Turnover
      INTO   #selltrade
      FROM   dbo.CoreTrade t
             INNER JOIN #requiredsegment segment
                     ON segment.RefSegmentEnumId = t.RefSegmentId
             LEFT JOIN #clientstoexclude excludeClient
                    ON t.RefClientId = excludeClient.RefClientId
      WHERE  t.TradeDate = @RunDateInternal
             AND excludeClient.RefClientId IS NULL
             AND t.BuySell = 'Sell'
      GROUP  BY t.RefClientId,
                TradeDate,
                t.RefInstrumentId,
                t.BuySell
      ORDER  BY t.TradeDate,
                t.RefClientId,
                t.RefInstrumentId

      DROP TABLE #clientstoexclude

      CREATE INDEX ix_#selltrade_refclientid_refinstrumentid
        ON #selltrade(RefClientId, RefInstrumentId)

      SELECT DISTINCT RefClientId,
                      RefInstrumentId
      INTO   #filteredinstandclient
      FROM   #selltrade

      SELECT Row_number()
               OVER (
                 ORDER BY trade.TradeDate)                          AS RowNum,
             trade.RefClientId,
             TradeDate,
             trade.RefInstrumentId,
             1                                                      AS BuySell,
             --for 'Buy' keeping the BIT 1    
             Sum(trade.Quantity)                                    AS Quantity,
             Sum(trade.Quantity * trade.Rate) / Sum(trade.Quantity) AS Rate
      INTO   #buytrade
      FROM   dbo.CoreTrade trade
             INNER JOIN #requiredsegment segment
                     ON segment.RefSegmentEnumId = trade.RefSegmentId
             INNER JOIN #filteredinstandclient client
                     ON trade.RefClientId = client.RefClientId
                        AND trade.RefInstrumentId = client.RefInstrumentId
      WHERE  trade.TradeDate BETWEEN @FromDateInternal AND @RunDateInternal
             AND trade.BuySell = 'Buy'
      GROUP  BY trade.RefClientId,
                TradeDate,
                trade.RefInstrumentId,
                trade.BuySell
      ORDER  BY trade.TradeDate,
                trade.RefClientId,
                trade.RefInstrumentId

      CREATE INDEX ix_#buytrade_refclientid_refinstrumentid
        ON #buytrade(RefClientId, RefInstrumentId)

      --trying to filter alterType1 & 2 in the same    
      SELECT sellTrade.TradeDate,
             t1.RefClientId,
             t1.RefInstrumentId,
             selltrade.Quantity                            AS SellTradeBuyQty,
             Sum(t2.Quantity)                              AS BuyTradeBuyQty,
             Sum(t2.Quantity * t2.Rate) / Sum(t2.Quantity) AS BuyRate,
             ( selltrade.Quantity * (Sum(t2.Quantity * t2.Rate) / Sum(t2.Quantity)))         AS BuyTurnover,
             selltrade.Quantity                            AS SellQty,
             selltrade.Rate                                AS SellRate,
             selltrade.Turnover                            AS SellTurnover
      INTO   #consolidatealert1and2
      FROM   #buytrade t1
             INNER JOIN #filteredinstandclient filInstClnt
                     ON t1.RefClientId = filInstClnt.RefClientId
                        AND t1.RefInstrumentId = filInstClnt.RefInstrumentId
             INNER JOIN #selltrade sellTrade
                     ON t1.RefInstrumentId = selltrade.RefInstrumentId
                        AND selltrade.RefClientId = t1.RefClientId
             INNER JOIN #buytrade t2
                     ON t1.RefClientId = t2.RefClientId
                        AND t1.RefInstrumentId = t2.RefInstrumentId
                        AND t1.RowNum <= t2.RowNum
      GROUP  BY sellTrade.TradeDate,
                t1.TradeDate,
                t1.RefClientId,
                t1.RefInstrumentId,
                selltrade.Quantity,
                selltrade.Rate,
                selltrade.Turnover
      --,t1.BuySell,t1.Quantity, t1.Rate, t1.Turnover    
      HAVING Sum(t2.Quantity) >= selltrade.Quantity
      ORDER  BY t1.TradeDate DESC

      DROP TABLE #selltrade

      DROP TABLE #buytrade

      SELECT *
      INTO   #finalalerts
      FROM   (
             --alertType1    
             SELECT TradeDate,
                    RefClientId,
                    RefInstrumentId,
                    BuyTradeBuyQty AS BuyQty,
                    BuyRate,
                    BuyTurnover,
                    SellQty,
                    SellRate,
                    SellTurnover
             FROM   #consolidatealert1and2
             WHERE  BuyTradeBuyQty = SellQty
              UNION
              --alertType 2    
              SELECT TradeDate,
                     RefClientId,
                     RefInstrumentId,
                     SellTradeBuyQty AS BuyQty,
                     BuyRate,
                     BuyTurnover,
                     SellQty,
                     SellRate,
                     SellTurnover
              FROM  (SELECT *,
                            Row_number()
                              OVER (
                                partition BY RefInstrumentId, RefClientId
                                ORDER BY BuyTradeBuyQty) AS finalRowNUm
                     --partition by BuyTradeBuyQty    
                     FROM   #consolidatealert1and2
                     WHERE  BuyTradeBuyQty > SellQty) t
              WHERE  t.finalRowNUm = 1
                     AND NOT EXISTS (SELECT 1
                                     FROM   #consolidatealert1and2 FA1
                                     WHERE  BuyTradeBuyQty = SellQty
                                            AND t.RefClientId = FA1.RefClientId
                                            AND
                                    t.RefInstrumentId = FA1.RefInstrumentId))
             alert

      SELECT DISTINCT RefClientId
      INTO   #distinctclients
      FROM   #finalalerts

      SELECT cl.RefClientId,
             client.ClientId,
             client.[Name],
             inc.Income,
             client.RefClientStatusId
      INTO   #clientdetails
      FROM   #distinctclients cl
             INNER JOIN dbo.RefClient client
                     ON client.RefClientId = cl.RefClientId
             LEFT JOIN dbo.LinkRefClientRefIncomeGroupLatest inc
                    ON inc.RefClientId = client.RefClientId

      SELECT DISTINCT inst.RefInstrumentId,
                      inst.Isin,
                      inst.GroupName,
                      inst.RefSegmentId
      INTO   #tradeids
      FROM   #finalalerts trade
             INNER JOIN dbo.RefInstrument inst
                     ON trade.RefInstrumentId = inst.RefInstrumentId

      SELECT DISTINCT grp.RefScripGroupId,
                      grp.[Name]             AS ScripGroup,
                      attrVal.CoreEntityAttributeValueId,
                      attrDetail.ForEntityId AS RefInstrumentId
      INTO   #internalcodes
      FROM   #tradeids trade
             INNER JOIN dbo.CoreEntityAttributeDetail attrDetail
                     ON attrDetail.ForEntityId = trade.RefInstrumentId
             INNER JOIN dbo.RefEntityAttribute attr
                     ON attrDetail.RefEntityAttributeId =
                        attr.RefEntityAttributeId
             INNER JOIN dbo.CoreEntityAttributeValue attrVal
                     ON attr.RefEntityAttributeId = attrVal.RefEntityAttributeId
                        AND attrDetail.CoreEntityAttributeValueId =
                            attrVal.CoreEntityAttributeValueId
             INNER JOIN dbo.RefScripGroup grp
                     ON grp.[Name] = attrVal.UserDefinedValueName
      WHERE  attr.ForRefEntityTypeId = @InstrumentRefEntityTypeId
             AND attr.EntityAttributeTypeRefEnumValueId =
                 @EntityAttributeTypeRefEnumValueId
             AND attr.Code IN ( 'TW01', 'TW02' )
             AND @RunDateInternal >= attrDetail.StartDate
             AND ( attrDetail.EndDate IS NULL
                    OR attrDetail.EndDate > @RunDateInternal )

      SELECT DISTINCT ids.Isin,
                      COALESCE(inst2.GroupName, inter.ScripGroup, 'B') AS
                      GroupName,
                      COALESCE(inst2.Code, inst1.Code)                 AS Code
      INTO   #allnsegroupdata
      FROM   #tradeids ids
             INNER JOIN dbo.RefInstrument inst1
                     ON ids.RefInstrumentId = inst1.RefInstrumentId
             LEFT JOIN dbo.RefInstrument inst2
                    ON inst2.RefSegmentId = @BSE_CASH
                       AND ids.Isin = inst2.Isin
                       AND inst2.[Status] = 'A'
             LEFT JOIN #internalcodes inter
                    ON ids.RefInstrumentId = inter.RefInstrumentId
      WHERE  ids.RefSegmentId = @NSE_CASH

      DROP TABLE #internalcodes

      DROP TABLE #tradeids

      SELECT Isin,
             Count(1) AS rcount
      INTO   #multiplegroups
      FROM   #allnsegroupdata
      GROUP  BY Isin
      HAVING Count(1) > 1

      SELECT DISTINCT t.Isin,
                      t.GroupName
      INTO   #nsegroupdata
      FROM   (SELECT grp.Isin,
                     grp.GroupName
              FROM   #allnsegroupdata grp
              WHERE  NOT EXISTS (SELECT 1
                                 FROM   #multiplegroups mg
                                 WHERE  mg.Isin = grp.Isin)
              UNION
              SELECT mg.Isin,
                     grp.GroupName
              FROM   #multiplegroups mg
                     INNER JOIN #allnsegroupdata grp
                             ON grp.Isin = mg.Isin
                                AND grp.Code LIKE '5%') t

      DROP TABLE #multiplegroups

      DROP TABLE #allnsegroupdata

      SELECT alert.RefClientId,
             client.ClientId,
             client.[Name]
             AS ClientName,
             alert.TradeDate,
             CASE
               WHEN inst.RefSegmentId = @NSE_CASH THEN nse.GroupName
               ELSE inst.GroupName
             END
             AS GroupName,
             inst.Code
             AS ScripCode,
             inst.[Name]
             AS Scrip,
             alert.RefInstrumentId,
             client.Income,
             alert.BuyQty,
             alert.BuyRate,
             alert.BuyTurnover,
             alert.SellQty,
             alert.SellRate,
             alert.SellTurnover,
             ( alert.SellTurnover * 100 ) / bhav.NetTurnOver
             AS SellPercentage,
             bhav.NetTurnOver
             ExchangeTO,
             Abs(alert.BuyTurnover - alert.SellTurnover)
             AS TotalLoss,
             Abs(( ( alert.BuyTurnover - alert.SellTurnover ) * 100 ) /
                 alert.BuyTurnover) AS
             PercentLoss,
			 inst.RefSegmentId
      FROM   #finalalerts alert
             INNER JOIN #clientdetails client
                     ON client.RefClientId = alert.RefClientId
             INNER JOIN dbo.RefInstrument inst
                     ON alert.RefInstrumentId = inst.RefInstrumentId
             LEFT JOIN dbo.CoreBhavCopy bhav
                    ON alert.TradeDate = bhav.[Date]
                       AND alert.RefInstrumentId = bhav.RefInstrumentId
             LEFT JOIN #nsegroupdata nse
                    ON inst.Isin = nse.Isin
                       AND inst.RefSegmentId = @NSE_CASH
             INNER JOIN #scenariorules rules
                     ON ( ( inst.RefSegmentId = @BSE_CASH
                            AND rules.ScripGroup = inst.GroupName )
                           OR ( inst.RefSegmentId = @NSE_CASH
                                AND rules.ScripGroup = nse.GroupName ) )
                        AND rules.RefClientStatusId = client.RefClientStatusId
                        AND ( ( alert.SellTurnover * 100 ) / bhav.NetTurnOver )
                            >=
                            rules.Threshold
                        AND ( ( ( alert.BuyTurnover - alert.SellTurnover ) * 100
                              )
                              /
                              alert.BuyTurnover )
                            >=
                            rules.Threshold2
                        AND ( alert.BuyTurnover - alert.SellTurnover ) >=
                            rules.Threshold3
      WHERE  alert.TradeDate = @RunDateInternal
  END

GO
--WEB-76060 END RC

--WEB-76060 START RC
--S127 PATCH old alerts
GO
	DECLARE  @ReportId INT
	
	SELECT @ReportId = ref.RefAmlReportId FROM dbo.RefAmlReport ref WHERE ref.[Name] ='S127 Loss compare with Exchange T/o'

	UPDATE re
	SET Re.RefSegmentEnumId = inst.RefSegmentId
	FROM dbo.CoreAmlScenarioAlert re 
	INNER JOIN dbo.RefInstrument inst ON re.RefAmlReportId = @ReportId AND inst.RefInstrumentId = re.RefInstrumentId  
GO
--WEB-76060 END RC

--WEB-76060 START RC
--S163 and S164 PATCH
GO
 ALTER PROCEDURE dbo.AML_GetHighProfitLossbyGroupofClientsin1Day   
(  
 @RunDate DATETIME,  
 @ReportId INT  
)  
AS  
BEGIN  
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @BSECashId INT, @NSECashId INT, @OPTSTKId INT,   
  @OPTIDXId INT, @OPTCURId INT, @OPTIRCId INT, @FUTIDXId INT, @FUTSTKId INT, @FUTIRDId INT,   
  @FUTIRTId INT, @FUTCURId INT, @FUTIRCId INT, @FUTIVXId INT, @FUTIRFId INT, @NSEFNOId INT,   
  @NSECDXId INT, @GrpPLThresh DECIMAL(28, 2), @GrpTOThresh DECIMAL(28, 2), @NoOfClThresh INT,  
  @ClSharePercThresh DECIMAL(28, 2), @S163Id INT, @S164Id INT, @IsGroupGreaterThanOneClient INT,  
  @IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT  
  
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
 SET @ReportIdInternal = @ReportId  
 SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'  
 SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'  
 SELECT @NSEFNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_FNO'  
 SELECT @NSECDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CDX'  
 SELECT @OPTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'  
 SELECT @OPTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'  
 SELECT @OPTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'  
 SELECT @OPTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIRC'  
 SELECT @FUTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIDX'  
 SELECT @FUTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTSTK'  
 SELECT @FUTIRDId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRD'  
 SELECT @FUTIRTId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRT'  
 SELECT @FUTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR'  
 SELECT @FUTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRC'  
 SELECT @FUTIVXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIVX'  
 SELECT @FUTIRFId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRF'  
 SELECT @GrpPLThresh = CONVERT(DECIMAL(28, 2), [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Profit_Loss'  
 SELECT @GrpTOThresh = CONVERT(DECIMAL(28, 2), [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Threshold_Quantity'  
 SELECT @NoOfClThresh = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Quantity'  
 SELECT @ClSharePercThresh = CONVERT(DECIMAL(28, 2), [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Client_Turnover_Percentage'  
 SELECT @S163Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S163 High Profit or Loss by Group of Clients in 1 Day EQ'  
 SELECT @S164Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S164 High Profit or Loss by Group of Clients in 1 Day FNO'  
  
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
 WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportIdInternal)  
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)  
  
 CREATE TABLE #scrnarioDataMapping(  
  RefSegmentId INT NOT NULL,  
  RefAmlReportId INT NOT NULL,  
 -- RefInstrumentTypeId INT NULL,  
  TradeDate DATETIME NOT NULL  
 )  
 --for S163 there is no instrumentType filter  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@BSECashId,@S163Id,@RunDateInternal)  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@NSECashId,@S163Id,@RunDateInternal)  
  
 --for S164 there is instrumentType filter  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@NSEFNOId,@S164Id,@RunDateInternal)  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@NSECDXId,@S164Id,@RunDateInternal)  
  
 CREATE TABLE #trades (RefClientId INT, Quantity INT, Turnover DECIMAL(28, 2), BuySell INT, RefSegmentId INT, RefInstrumentId INT)  
  
 INSERT INTO #trades (RefClientId, BuySell, RefSegmentId, RefInstrumentId,Turnover,Quantity)  
 SELECT    
  trade.RefClientId,  
  CASE WHEN trade.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell,  
  trade.RefSegmentId,  
  trade.RefInstrumentId,  
  CASE   
   WHEN (INST.RefInstrumentTypeId = @OPTCURId or INST.RefInstrumentTypeId = @FUTCURId  )  
    THEN trade.Rate*( trade.Quantity * ISNULL(inst.ContractSize, 1) )   
   ELSE   
    trade.Quantity * trade.Rate  
  END AS Turnover,  
  CASE   
   WHEN (INST.RefInstrumentTypeId = @OPTCURId or INST.RefInstrumentTypeId = @FUTCURId  )  
    THEN trade.Quantity * ISNULL(inst.ContractSize, 1)  
   ELSE  
    trade.Quantity   
  END AS Quantity  
      
 FROM #scrnarioDataMapping mapping  
 INNER JOIN dbo.CoreTrade trade ON trade.TradeDate = mapping.TradeDate AND trade.RefSegmentId = mapping.RefSegmentId   
  AND mapping.RefAmlReportId = @ReportIdInternal --report filter   
 INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
 INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId  
 --LEFT JOIN dbo.RefInstrumentType instType ON  instType.RefInstrumentTypeId = inst.RefInstrumentTypeId   
 --  AND (mapping.RefInstrumentTypeId IS NOT NULL AND instType.RefInstrumentTypeId = mapping.RefInstrumentTypeId)-- for instrument type case condition  
 LEFT JOIN #clientsToExclude cl ON trade.RefClientId = cl.RefClientId  
 WHERE cl.RefClientId IS NULL  
 AND (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)  
 AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)  
  
 --IF @ReportIdInternal = @S163Id  
 --BEGIN  
 -- INSERT INTO #trades (RefClientId, Quantity, Turnover, BuySell, RefSegmentId, RefInstrumentId)  
 -- SELECT  
 --  trade.RefClientId,  
 --  trade.Quantity,  
 --  (trade.Quantity * trade.Rate) AS Turnover,  
 --  CASE WHEN trade.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell,  
 --  trade.RefSegmentId,  
 --  trade.RefInstrumentId  
 -- FROM dbo.CoreTrade trade  
 -- INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
 -- LEFT JOIN #clientsToExclude cl ON trade.RefClientId = cl.RefClientId  
 -- WHERE cl.RefClientId IS NULL  
 -- AND (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)  
 -- AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)  
 -- AND trade.RefSegmentId IN (@BSECashId, @NSECashId)  
 -- AND trade.TradeDate = @RunDateInternal  
  
 --END   
 --ELSE IF @ReportIdInternal = @S164Id  
 --BEGIN  
 -- INSERT INTO #trades (RefClientId, Quantity, Turnover, BuySell, RefSegmentId, RefInstrumentId)  
 -- SELECT  
 --  trade.RefClientId,  
 --  CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)  
 --   THEN trade.Quantity * ISNULL(inst.ContractSize, 1)  
 --   ELSE trade.Quantity END AS Quantity,  
 --  CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)  
 --   THEN trade.Quantity * trade.Rate * ISNULL(inst.ContractSize, 1)  
 --   ELSE trade.Quantity * trade.Rate END AS Turnover,  
 --  CASE WHEN trade.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell,  
 --  trade.RefSegmentId,  
 --  trade.RefInstrumentId  
 -- FROM dbo.CoreTrade trade  
 -- INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
 -- LEFT JOIN #clientsToExclude cl ON trade.RefClientId = cl.RefClientId  
 -- INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
 -- WHERE cl.RefClientId IS NULL  
 -- AND (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)  
 -- AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)  
 -- AND trade.RefSegmentId IN (@NSEFNOId, @NSECDXId)  
 -- AND trade.TradeDate = @RunDateInternal  
 --END  
  
 DROP TABLE #clientsToExclude  
  
 SELECT  
  RefClientId,  
  RefSegmentId,  
  RefInstrumentId,  
  SUM(CASE WHEN BuySell = 1 THEN Quantity ELSE 0 END) AS BuyQty,  
  SUM(CASE WHEN BuySell = 0 THEN Quantity ELSE 0 END) AS SellQty,  
  SUM(CASE WHEN BuySell = 1 THEN Turnover ELSE 0 END) AS BuyTurnover,  
  SUM(CASE WHEN BuySell = 0 THEN Turnover ELSE 0 END) AS SellTurnover  
 INTO #clientWiseTrades  
 FROM #trades  
 GROUP BY RefClientId, RefSegmentId, RefInstrumentId  


 SELECT
	z.RefClientId,
	z.RefSegmentId
 INTO #tempSegmentData
 FROM(
	SELECT
		t.RefClientId,
		t.RefSegmentId,
		ROW_NUMBER() OVER(PARTITION BY t.RefClientId ORDER BY t.turnover DESC) RN
	FROM(SELECT
		clwitr.RefClientId,
		clwitr.RefSegmentId,
		SUM(clwitr.SellTurnover+clwitr.BuyTurnover) AS turnover
		
	FROM #clientWiseTrades clwitr
	GROUP BY clwitr.RefClientId,clwitr.RefSegmentId)t
	)z
 WHERE z.RN =1
  
 DROP TABLE #trades  
  
 --SELECT  
 -- RefClientId,  
 -- RefSegmentId,  
 -- RefInstrumentId,  
 -- CASE   
 --  WHEN BuyQty <= SellQty  
 --   THEN BuyQty   
 --  ELSE   
 --   SellQty   
 -- END AS Qty,  
 -- (BuyTurnover / BuyQty) AS BuyRate,  
 -- (SellTurnover / SellQty) AS SellRate  
 --INTO #intradayData  
 --FROM #clientWiseTrades  
 --WHERE SellQty > 0 AND BuyQty > 0  
  
-- DROP TABLE #clientWiseTrades  
  
 SELECT  
  RefClientId,  
  SUM(  
   (  
    (CASE WHEN BuyQty <= SellQty THEN BuyQty ELSE SellQty END) * ((BuyTurnover / BuyQty) + (SellTurnover / SellQty))  
   )  
  ) AS ClientTO,  
  SUM(  
   (  
    (CASE WHEN BuyQty <= SellQty THEN BuyQty ELSE SellQty END) * ((SellTurnover / SellQty) - (BuyTurnover / BuyQty))  
   )  
  ) AS ClientPL  
 INTO #clientFinalData  
 FROM #clientWiseTrades  
 WHERE SellQty <> 0 AND BuyQty <> 0     
 GROUP BY RefClientId  
  
 DROP TABLE #clientWiseTrades  
 --DROP TABLE #intradayData  
  
 --SELECT  
 -- RefClientId,  
 -- SUM(ClientTO) AS ClientTO,  
 -- SUM(ClientPL) AS ClientPL  
 --INTO #clientFinalData  
 --FROM #clientFinalDataInter  
 --GROUP BY RefClientId  
  
 --DROP TABLE #clientFinalDataInter  
  
 SELECT  
  t.RefClientId,  
  t.ClientTO,  
  t.ClientPL,
  COUNT(t.RefClientId) OVER() CRN  
 INTO #group1  
 FROM (SELECT   
   RefClientId,  
   ClientTO,  
   ClientPL,  
   DENSE_RANK() OVER ( ORDER BY ClientTO DESC) AS RN  
  FROM #clientFinalData  
  WHERE ClientPL > 0  
 ) t WHERE t.RN <= @NoOfClThresh  
  
 SELECT  
  t.RefClientId,  
  t.ClientTO,  
  t.ClientPL,
  COUNT(t.RefClientId) OVER() CRN
 INTO #group2  
 FROM (SELECT   
   RefClientId,  
   ClientTO,  
   ClientPL,  
   DENSE_RANK() OVER ( ORDER BY ClientTO DESC) AS RN  
  FROM #clientFinalData  
  WHERE ClientPL < 0  
 ) t WHERE t.RN <= @NoOfClThresh  
  
 DROP TABLE #clientFinalData  


  
 SELECT  
  SUM(ClientTO) AS GroupTO,  
  SUM(ClientPL) AS GroupPL  
 INTO #group1Total  
 FROM #group1  
  
 SELECT  
  SUM(ClientTO) AS GroupTO,  
  SUM(ClientPL) AS GroupPL  
 INTO #group2Total  
 FROM #group2  
   
   
 Declare @Grp1PL DECIMAL(28,2),@Grp1TO DECIMAL(28,2),@Grp2PL DECIMAL(28,2),@Grp2TO DECIMAL(28,2)  
 SELECT  @Grp2PL = GroupPL, @Grp2TO = GroupTO FROM #group2Total  
 SELECT  @Grp1PL = GroupPL, @Grp1TO = GroupTO FROM #group1Total  
  
 CREATE TABLE #data(   
  RefClientId INT,  
  ClientTO DECIMAL(28, 2),   
  ClientPL DECIMAL(28, 2),   
  GroupPL DECIMAL(28, 2),   
  GroupTO DECIMAL(28, 2),   
  ClientPerc DECIMAL(28, 2),  
  DataType INT NOT NULL  
 )  
 IF(ABS(@Grp1PL)>=@GrpPLThresh AND @Grp1TO >= @GrpTOThresh)  
  
 BEGIN    
 INSERT INTO #data(RefClientId, ClientTO, ClientPL, GroupPL, GroupTO, ClientPerc,DataType)  
  SELECT  
   grp.RefClientId,  
   --cl.ClientId,  
   --cl.[Name] AS ClientName,  
   grp.ClientTO,  
   grp.ClientPL,  
   @Grp1PL,  
   @Grp1TO,  
   (ABS(grp.ClientPL) * 100 / ABS(@Grp1PL)) AS ClientPerc,  
   1  
  FROM #group1 grp  
  WHERE (ABS(grp.ClientPL) * 100 / ABS(@Grp1PL))>=@ClSharePercThresh  AND @IsGroupGreaterThanOneClient < CRN
 END  
  
 DROP TABLE #group1  
 DROP TABLE #group1Total  
  
  
 IF(ABS(@Grp2PL)>=@GrpPLThresh AND @Grp2TO >= @GrpTOThresh)  
  
 BEGIN    
 INSERT INTO #data(RefClientId, ClientTO, ClientPL, GroupPL, GroupTO, ClientPerc,DataType)  
  SELECT  
   grp.RefClientId,  
   grp.ClientTO,  
   grp.ClientPL,  
   @Grp2PL,  
   @Grp2TO,  
   (ABS(grp.ClientPL) * 100 / ABS(@Grp2PL)) AS ClientPerc,  
   2  
  FROM #group2 grp  
  WHERE (ABS(grp.ClientPL) * 100 / ABS(@Grp2PL)) >= @ClSharePercThresh AND @IsGroupGreaterThanOneClient < CRN  
 END  
  
 DROP TABLE #group2  
 DROP TABLE #group2Total  
  
  
 SELECT  t.RefClientId,    
   cl.ClientId,  
   cl.[Name] AS ClientName,   
   t.ClientTO,    
   t.ClientPL,    
   t.GroupPL,    
   t.GroupTO,    
   t.ClientPerc,   
   t.DescriptionClientPerc,  
   @RunDateInternal AS TradeDate  ,
   temp.RefSegmentId AS RefSegmentId
 FROM (  
  
  SELECT  
   fd.RefClientId,  
     
   fd.ClientTO,  
   fd.ClientPL,  
   fd.GroupPL,  
   fd.GroupTO,  
   fd.ClientPerc,  
   STUFF((SELECT ' ; ' + client.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) COLLATE DATABASE_DEFAULT + '%'  
    FROM #data t  
    INNER JOIN dbo.RefClient client ON client.RefClientId = t.RefClientId   
    WHERE DataType = 1 AND fd.RefClientId <> t.RefClientId  
    FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc  
  FROM #data fd  
  WHERE DataType = 1   
  
  UNION ALL  
  
  SELECT  
   fd.RefClientId,  
   fd.ClientTO,  
   fd.ClientPL,  
   fd.GroupPL,  
   fd.GroupTO,  
   fd.ClientPerc,  
   STUFF((SELECT ' ; ' + client.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) COLLATE DATABASE_DEFAULT + '%'  
    FROM #data t   
    INNER JOIN dbo.RefClient client ON client.RefClientId = t.RefClientId   
    WHERE DataType = 2 AND fd.RefClientId <> t.RefClientId  
    FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc  
  FROM #data fd  
  WHERE DataType = 2  
 ) t  
 INNER JOIN dbo.RefClient cl On cl.RefClientId = t.RefClientId 
 INNER JOIN #tempSegmentData temp ON temp.RefClientId = t.RefClientId
  
END  
GO
--WEB-76060 END RC

--WEB-76060 START RC
--S169 PATCH
GO
   ALTER PROCEDURE dbo.AML_GetClientTradingActivityComparedWithDealingOffAddress (            
 @RunDate DATETIME,            
 @ReportId INT            
)            
AS            
BEGIN         
   DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @ExcludePin VARCHAR(MAX), @ClientToThreshold DECIMAL(28,2), @UniquePinThreshold INT,        
   @BSECashId INT, @NSECashId INT,@NSEFNOId INT, @NSECDXId INT, @Lookback INT,@LookBackDate DATETIME ,@ToDate DATETIME ,@TotalTO DECIMAL(28,2) ,  
   @IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT    
         
   SET @ReportIdInternal = @ReportId           
   SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)          
         
   SELECT @Lookback = CONVERT(INT, [Value]) FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Days'            
   SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')               
   SET @LookBackDate = CONVERT(DATETIME, DATEDIFF(dd, @Lookback-1, @RunDateInternal))         
          
        
   SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'        
   SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'        
   SELECT @NSEFNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_FNO'        
   SELECT @NSECDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CDX'    
   SELECT @ProStatusId = RefClientStatusId  FROM dbo.RefClientStatus WHERE [Name] = 'Pro'    
   SELECT  @InstituteStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'    
      
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
   @ExcludePin = [Value]         
   FROM dbo.SysAmlReportSetting         
   WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Excluded_Groups'        
        
   SELECT         
   @UniquePinThreshold = CONVERT( INT , [Value])        
   FROM dbo.SysAmlReportSetting         
   WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Entity'     
     
   SELECT         
   @TotalTO = CONVERT( DECIMAL(28,2)   , [Value])        
   FROM dbo.SysAmlReportSetting         
   WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Turnover'    
        
   SELECT        
   RTRIM(LTRIM(pins.items)) AS pin        
   INTO #ExcludePin        
   FROM dbo.Split(@ExcludePin,',') pins        
         
   SELECT DISTINCT        
   RefClientId        
   INTO #clientsToExclude    
   FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex        
   WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)         
   AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)       
    
   SELECT    
   trade.RefClientId,    
   trade.RefSegmentId,    
   trade.RefInstrumentId,    
   SUBSTRING (CONVERT(VARCHAR(MAX),trade.CtclId) ,1,6)AS Pin,    
   trade.Rate,    
   trade.Quantity    
   INTO #tradedetails    
   FROM dbo.CoreTrade trade    
   INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId    
   LEFT JOIN #clientsToExclude ex ON ex.RefClientId = trade.RefClientId        
   WHERE ex.RefClientId IS NULL AND      
   trade.RefSegmentId IN ( @BSECashId, @NSECashId , @NSEFNOId , @NSECDXId)  AND     
   (trade.TradeDate BETWEEN @LookBackDate AND @ToDate)   AND  
   (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)    
 AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)    
  
      
  DROP TABLE #clientsToExclude    
    
  SELECT         
   trade.RefClientId,        
   trade.RefSegmentId,   
   trade.Pin,     
   CASE WHEN trade.RefSegmentId = @NSECDXId AND instru.Code='JPYINR' THEN COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.Rate * trade.Quantity * 1000,2))),0)    
     WHEN trade.RefSegmentId  = @NSECDXId THEN COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.Rate * trade.Quantity * instru.ContractSize,2))),0)    
     ELSE COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.Rate * trade.Quantity,2))),0)    
   END    
    AS turnover        
  INTO #tradeDetailsWitPin        
  FROM #tradedetails trade        
  INNER JOIN  dbo.RefClient ref ON ref.RefClientId = trade.RefClientId    
  INNER JOIN dbo.RefInstrument instru ON instru.RefInstrumentId = trade.RefInstrumentId    
  LEFT JOIN dbo.RefIntermediary inter ON inter.RefIntermediaryId = ref.RefIntermediaryId       
  LEFT JOIN #ExcludePin pins ON pins.pin = trade.Pin      
  WHERE      
   pins.pin IS NULL AND           
   trade.Pin NOT IN ('111111','333333', '0',ISNULL(ref.CAddressPin,''), ISNULL(ref.PAddressPin,''), ISNULL(inter.Pin,''),ISNULL(inter.ResPin,''))    
     
  GROUP BY        
   trade.RefClientId,        
   trade.RefSegmentId,    
   trade.Pin ,    
   instru.Code    
       
    DROP TABLE #ExcludePin    
	DROP TABLE #tradedetails    
      
  SELECT 
	SUM(CASE WHEN trade.RefSegmentId = @BSECashId  THEN trade.turnover ELSE 0 END) BSEcash,
	SUM(CASE WHEN trade.RefSegmentId = @NSECashId  THEN trade.turnover ELSE 0 END) NSEcash,
	SUM(CASE WHEN trade.RefSegmentId = @NSEFNOId   THEN trade.turnover ELSE 0 END) NSEfno,
	SUM(CASE WHEN trade.RefSegmentId = @NSECDXId   THEN trade.turnover ELSE 0 END) NSEcdx,
	SUM(trade.turnover) AS totalto,
	trade.RefClientId 
	INTO #finalTradeData
	FROM #tradeDetailsWitPin trade      
	  GROUP BY      
	   trade.RefClientId 
    
 

   SELECT 
	DISTINCT
	trade.RefClientId,
	trade.Pin
   INTO #uniquePinDetails
   FROM #tradeDetailsWitPin trade

   SELECT 
   trade.RefClientId,
   COUNT(1) AS uniquepin, 
   STUFF(( SELECT ', '+ pinforstuff.Pin            
    FROM #uniquePinDetails pinforstuff         
    WHERE pinforstuff.RefClientId = trade.RefClientId
    FOR XML PATH('')),1,1,'') AS tradepin
   INTO #tradewithcount
   FROM #uniquePinDetails trade
   GROUP BY trade.RefClientId 

      
     DROP TABLE #tradeDetailsWitPin  
      
   SELECT      
	   ref.RefClientId,     
	   ref.ClientId,      
	   ref.[Name] AS ClientName,
	   @LookBackDate AS FromDate,  
	   @RunDateInternal AS TradeDate, 
	   STUFF((ISNULL(', '+ref.CAddressPin,'')+ISNULL(', '+ref.PAddressPin,'')+ISNULL(', '+inter.Pin,'')+ISNULL(', '+inter.ResPin,'')),1,2,'') AS ClientPIN,    
	   pin.tradepin AS TradePin,     
	   trade.BSEcash AS BseCash,
	   trade.NSEcash AS NseCash,
	   trade.NSEfno AS NseFno,
	   trade.NSEcdx AS NseCdx,
	   trade.totalto AS TotalTO,
	   CASE WHEN trade.BSEcash > trade.NSEcash AND trade.BSEcash > trade.NSEfno AND trade.BSEcash > trade.NSEcdx THEN @BSECashId
		   WHEN trade.NSEcash > trade.BSEcash AND trade.NSEcash > trade.NSEfno AND trade.NSEcash > trade.NSEcdx THEN @NSECashId
		   WHEN trade.NSEfno > trade.BSEcash AND trade.NSEfno> trade.NSEcash AND trade.NSEfno > trade.NSEcdx THEN @NSEFNOId
		   ELSE @NSECDXId
	   END AS RefSegmentId
   FROM #tradewithcount pin  
   INNER JOIN #finalTradeData trade ON pin.RefClientId = trade.RefClientId
   INNER JOIN dbo.RefClient ref ON ref.RefClientId = trade.RefClientId
   LEFT JOIN dbo.RefIntermediary inter ON inter.RefIntermediaryId = ref.RefIntermediaryId      
   WHERE pin.uniquepin > = @UniquePinThreshold  AND trade.totalto >=  @TotalTO
          
    
 END        
GO
--WEB-76060 END RC

--WEB-76060 START RC
--S169 old alerts
GO
   DECLARE @BSECashId INT,@NSECashId INT,@NSEFNOId INT,@NSECDXId INT, @ReportId INT
   
   SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'        
   SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'        
   SELECT @NSEFNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_FNO'        
   SELECT @NSECDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CDX' 
   SELECT @ReportId = ref.RefAmlReportId FROM dbo.RefAmlReport ref WHERE ref.[Name] ='S169 Client Trading Activity Compared With Dealing Off Address'

	UPDATE re
	SET Re.RefSegmentEnumId = CASE WHEN re.BseCashTurnover > re.NseCashTurnover AND re.BseCashTurnover > re.NseFnoTurnover AND re.BseCashTurnover > re.MoneyIn THEN @BSECashId
		   WHEN re.NseCashTurnover > re.BseCashTurnover AND re.NseCashTurnover > re.NseFnoTurnover AND re.NseCashTurnover > re.MoneyIn THEN @NSECashId
		   WHEN re.NseFnoTurnover > re.BseCashTurnover AND re.NseFnoTurnover> re.NseCashTurnover AND re.NseFnoTurnover > re.MoneyIn THEN @NSEFNOId
		   ELSE @NSECDXId
	   END 
	FROM dbo.CoreAmlScenarioAlert re WHERE re.RefAmlReportId = @ReportId

GO
--WEB-76060 END RC

--WEB-76060 START RC
GO
ALTER PROCEDURE dbo.CoreAmlScenarioHighProfitLossbyGroupofClientsin1DayAlert_Search 
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
	@CaseId BIGINT = NULL,
	@PageNo INT = 1,
	@PageSize INT = 100
)    
AS     
BEGIN

	DECLARE @InternalPageNo INT, @InternalPageSize INT,
		@InternalReportId INT, @InternalFromDate DATETIME, @InternalToDate DATETIME,
		@InternalAddedOnFromDate DATETIME, @InternalAddedOnToDate DATETIME,
		@InternalEditedOnFromDate DATETIME, @InternalEditedOnToDate DATETIME,
		@InternalClient VARCHAR(500), @InternalStatus INT, @InternalComments VARCHAR(500),
		@InternalCaseId BIGINT, @InternalTxnFromDate DATETIME, @InternalTxnToDate DATETIME, @InternalRefSegmentEnumId INT
	
	SET @InternalPageNo = @PageNo
	SET @InternalPageSize = @PageSize
	SET @InternalReportId = @ReportId
	SET @InternalFromDate = dbo.GetDateWithoutTime(@FromDate) 
	SET @InternalToDate =  CONVERT(DATETIME,DATEDIFF(dd, 0,dbo.GetDateWithoutTime(@ToDate))) + CONVERT(DATETIME,'23:59:59.000') 
	SET @InternalAddedOnFromDate =  dbo.GetDateWithoutTime(@AddedOnFromDate)
	SET @InternalAddedOnToDate = CONVERT(DATETIME,DATEDIFF(dd, 0,dbo.GetDateWithoutTime(@AddedOnToDate))) + CONVERT(DATETIME,'23:59:59.000')
	SET @InternalEditedOnFromDate = dbo.GetDateWithoutTime(@EditedOnFromDate)
	SET @InternalEditedOnToDate = CONVERT(DATETIME,DATEDIFF(dd, 0,dbo.GetDateWithoutTime(@EditedOnToDate))) + CONVERT(DATETIME,'23:59:59.000')
	SET @InternalClient = @Client
	SET @InternalStatus = @Status
	SET @InternalComments = @Comments
	SET @InternalCaseId = @CaseId
	SET @InternalTxnFromDate = dbo.GetDateWithoutTime(@TxnFromDate)
	SET @InternalTxnToDate = CONVERT(DATETIME,DATEDIFF(dd, 0,dbo.GetDateWithoutTime(@TxnToDate))) + CONVERT(DATETIME,'23:59:59.000')
	SET @InternalRefSegmentEnumId = @RefSegmentEnumId

	SELECT alert.CoreAmlScenarioAlertId 
	INTO #data
	FROM dbo.CoreAmlScenarioAlert alert
	INNER JOIN dbo.RefClient client ON alert.RefClientId = client.RefClientId
	LEFT JOIN dbo.RefInstrument r on alert.RefInstrumentId = r.RefInstrumentId  
	WHERE alert.RefAmlReportId = @InternalReportId
		AND ((@InternalFromDate IS NULL OR alert.ReportDate >= @InternalFromDate) AND (@InternalToDate IS NULL OR alert.ReportDate <= @InternalToDate))
		AND ((@InternalAddedOnFromDate IS NULL OR alert.AddedOn >= @InternalAddedOnFromDate) AND (@InternalAddedOnToDate IS NULL OR alert.AddedOn <= @InternalAddedOnToDate)) 
		AND ((@InternalEditedOnFromDate IS NULL OR alert.EditedOn >= @InternalEditedOnFromDate) AND (@InternalEditedOnToDate IS NULL OR alert.EditedOn <= @InternalEditedOnToDate)) 
		AND	((@InternalTxnFromDate IS NULL OR (alert.TransactionDate IS NOT NULL AND alert.TransactionDate >= @InternalTxnFromDate) OR (alert.TransactionDate IS NULL AND alert.TransactionFromDate >= @InternalTxnFromDate))
			AND (@InternalTxnToDate IS NULL OR (alert.TransactionDate IS NOT NULL AND alert.TransactionDate <= @InternalTxnToDate) OR (alert.TransactionDate IS NULL AND alert.TransactionToDate <= @InternalTxnToDate)))
		AND (@InternalStatus IS NULL OR alert.[Status] = @InternalStatus)
		AND (@InternalCaseId IS NULL OR alert.CoreAlertRegisterCaseId = @InternalCaseId)
		AND (@InternalComments IS NULL OR alert.Comments = @InternalComments)
		AND (@InternalClient IS NULL OR (client.ClientId like '%' + @InternalClient + '%' OR client.[Name] LIKE '%' + @InternalClient + '%'))
		AND (@InternalRefSegmentEnumId IS NULL OR(alert.RefSegmentEnumId = @InternalRefSegmentEnumId))


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
		c.TransactionDate,
		c.TurnOver,
		c.ScripPercent,
		c.Amount,
		c.QuantityPercentage,
		c.BuyPercentage,
		c.[Description],
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
       
	SELECT COUNT(1) FROM #filteredAlerts
END
GO
--WEB-76060 START RC
