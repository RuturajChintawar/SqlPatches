--RC -START-WEB-77837
GO
CREATE PROCEDURE dbo.Aml_GetSynchronizedTradeXDaysEQ  
(     
	 
	 @ReportId INT ,    
	 @FromDate DATETIME ,    
	 @ToDate DATETIME 
)    
AS    
BEGIN    
     
	 DECLARE @ReportIdInternal INT, @FromDateInternal DATETIME, @ToDateInternal DATETIME, @ToDateWithoutTime DATETIME,    
	   @ExcludePro BIT, @ExcludeInstitution BIT, @ExcludeOppositePro BIT,@ExcludeOppositeInstitution BIT, @ExcludealgoTrade BIT, 
	   @BSE_CASHId INT, @NSE_CASHId INT, @ProId INT, @InstitutionId INT,    
	   @VerticalInternalId INT, @InstrumentRefEntityTypeId INT, @EntityAttributeTypeRefEnumValueId INT,
	   @InstitutionalClientDefaultNetworth BIGINT, @InstitutionStatus INT, @DefaultIncomeAbove1Cr DECIMAL(28, 2),
	   @ProfileDefault INT, @DefaultIncome DECIMAL(28, 2), @DefaultNetworth BIGINT,@ProRefClientStatusId INT,
			@InstitutionRefClientStatusId INT

	SELECT @ProfileDefault = RefAmlQueryProfileId FROM dbo.RefAmlQueryProfile WHERE [Name] = 'Default' 
	SELECT @InstitutionalClientDefaultNetworth = CONVERT(BIGINT, [Value]) FROM dbo.SysConfig WHERE [Name] = 'Institutional_Client_Default_Networth'    
	SELECT @DefaultIncomeAbove1Cr = CONVERT(DECIMAL(28, 2), ISNULL([Value], 0)) FROM dbo.SysConfig WHERE [Name] = 'Income_Value_For_Above_One_Crore'    
	SET @DefaultIncomeAbove1Cr = CASE WHEN @DefaultIncomeAbove1Cr <> 0 THEN @DefaultIncomeAbove1Cr ELSE 10000000 END    
	SELECT @InstitutionStatus = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'  
	
	
	SELECT @BSE_CASHId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'    
	SELECT @NSE_CASHId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH' 
	
	SET @InstitutionRefClientStatusId = dbo.GetClientStatusId('Institution')
    SET @ProRefClientStatusId = dbo.GetClientStatusId('Pro')

	SELECT @DefaultIncome = CONVERT(DECIMAL(28, 2), reportSetting.[Value])    
	FROM dbo.RefAmlQueryProfile qp       
	LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.[Name] = 'Client Purchase to Income'    
	LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId    
		AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId    
		AND reportSetting.[Name] = 'Default_Income'    
	WHERE qp.RefAmlQueryProfileId = @ProfileDefault    

	SELECT @DefaultNetworth = cliNetSellPoint.DefaultNetworth     
	FROM dbo.RefAmlQueryProfile qp       
	LEFT JOIN dbo.LinkRefAmlQueryProfileRefSegment qpSegment ON qpSegment.RefSegmentId = @BSE_CASHId    
		AND qpSegment.RefAmlQueryProfileId = qp.RefAmlQueryProfileId          
	LEFT JOIN dbo.SysAmlClientNetSellPoints cliNetSellPoint ON     
		cliNetSellPoint.LinkRefAmlQueryProfileRefSegmentId = qpSegment.LinkRefAmlQueryProfileRefSegmentId    
	WHERE qp.RefAmlQueryProfileId = @ProfileDefault
     
    
   SET @ReportIdInternal = @ReportId    
   SET @FromDateInternal = dbo.GetDateWithoutTime(@FromDate)    
   SET @ToDateInternal = dbo.GetDateWithoutTime(@ToDate)
   
   SELECT @ExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_Pro'   
   SELECT @ExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_Institution'
   SELECT @ExcludeOppositePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_OppositePro'    
   SELECT @ExcludeOppositeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_OppositeInstitution'   
   SELECT @ExcludealgoTrade = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_AlgoTrade'   

   SELECT @InstrumentRefEntityTypeId = RefEntityTypeId FROM dbo.RefEntityType WHERE Code='Instrument'
   
   SET @EntityAttributeTypeRefEnumValueId = dbo.GetEnumValueId('EntityAttributeType', 'UserDefined')
        
  SELECT @ProId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Pro'    
  SELECT @InstitutionId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'    
    
  SELECT    
   RefSegmentEnumId    
  INTO #RequiredSegment    
  FROM dbo.RefSegmentEnum    
  WHERE RefSegmentEnumId IN (@BSE_CASHId, @NSE_CASHId)     
    
  SELECT trade.CoreTradeId, trade.RefInstrumentId    
  INTO #tradeIds    
  FROM dbo.CoreTrade trade    
  INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId     
  WHERE trade.TradeDate BETWEEN @FromDateInternal AND @ToDateInternal AND(    
  @ExcludealgoTrade = 0 OR (@ExcludealgoTrade = 1 
	AND ( LEN(CONVERT(VARCHAR, trade.CtclId)) <> 15     
    OR SUBSTRING(CONVERT(VARCHAR, trade.CtclId), 13, 1) NOT IN ('0','2','4')))
	) 
   SELECT DISTINCT
		trade.CoreTradeId,
		inst.RefInstrumentId,
		inst.Isin,  
		inst.GroupName,  
		inst.RefSegmentId
	INTO #FilteredTradeIds
	FROM #tradeIds trade
	INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId

	SELECT DISTINCT
		grp.RefScripGroupId,
		grp.[Name] AS ScripGroup,
		attrVal.CoreEntityAttributeValueId,
		attrDetail.ForEntityId AS RefInstrumentId
	INTO #internalCodes
	FROM #FilteredTradeIds trade
	INNER JOIN dbo.CoreEntityAttributeDetail attrDetail ON attrDetail.ForEntityId = trade.RefInstrumentId
	INNER JOIN dbo.RefEntityAttribute attr ON attrDetail.RefEntityAttributeId = attr.RefEntityAttributeId 
	INNER JOIN dbo.CoreEntityAttributeValue attrVal ON attr.RefEntityAttributeId = attrVal.RefEntityAttributeId
		AND attrDetail.CoreEntityAttributeValueId = attrVal.CoreEntityAttributeValueId
	INNER JOIN dbo.RefScripGroup grp ON grp.[Name] = attrVal.UserDefinedValueName
	WHERE attr.ForRefEntityTypeId = @InstrumentRefEntityTypeId
	AND attr.EntityAttributeTypeRefEnumValueId = @EntityAttributeTypeRefEnumValueId
	AND attr.Code IN ('TW01','TW02')
	AND @ToDateInternal >= attrDetail.StartDate
	AND (attrDetail.EndDate IS NULL OR attrDetail.EndDate > @ToDateInternal)

	SELECT DISTINCT 
		ids.Isin,  
		COALESCE(inst2.GroupName, inter.ScripGroup, 'B') AS GroupName,
		COALESCE(inst2.Code, inst1.Code) AS Code
	INTO #allNseGroupData
	FROM #FilteredTradeIds ids
	INNER JOIN dbo.RefInstrument inst1 ON ids.RefInstrumentId = inst1.RefInstrumentId
	LEFT JOIN dbo.RefInstrument inst2 ON inst2.RefSegmentId = @BSE_CASHId  
		AND ids.Isin = inst2.Isin AND inst2.[Status] = 'A'
	LEFT JOIN #internalCodes inter ON ids.RefInstrumentId = inter.RefInstrumentId
	WHERE ids.RefSegmentId = @NSE_CASHId

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
   trade.CoreTradeId,    
   trade.RefClientId,    
   trade.RefInstrumentId,    
   trade.TradeDate,    
   trade.TradeDateTime,    
   trade.TradeId,    
   CASE WHEN trade.BuySell = 'Buy'    
    THEN 1    
    WHEN trade.BuySell = 'Sell'    
    THEN 0 END AS BuySell,    
   trade.BuySell AS VBuySell,    
   ISNULL(trade.Rate, 0) AS Rate,    
   trade.Quantity,    
   trade.CtclId,    
   trade.RefSegmentId,    
   trade.RefSettlementId,    
   trade.TraderId,    
   trade.OrderTimeStamp,    
   trade.TradeIdAlphaNumeric,    
   inst.RefInstrumentTypeId,    
   inst.Code,    
   CASE WHEN inst.RefSegmentId = @NSE_CASHId THEN nse.GroupName ELSE inst.GroupName END AS GroupName,  
   inst.ScripId,
   (trade.Rate * trade.Quantity) AS ScripTo 
  INTO #FilteredTrade    
  FROM #FilteredTradeIds ids    
  INNER JOIN dbo.CoreTrade trade ON ids.CoreTradeId = trade.CoreTradeId    
  INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId       
        INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId    
  INNER JOIN dbo.RefInstrumentType instType ON inst.RefInstrumentTypeId = instType.RefInstrumentTypeId 
  LEFT JOIN #nseGroupData nse ON inst.Isin = nse.Isin AND inst.RefSegmentId = @NSE_CASHId    
    
   
  SELECT DISTINCT RefClientId    
  INTO #FilteredClient    
  FROM #FilteredTrade tempClient     
   
  SELECT      
	   trade.CoreTradeId,    
	   trade.RefClientId,    
	   trade.RefInstrumentId,    
	   trade.Code,    
	   trade.GroupName,    
	   trade.ScripId,    
	   trade.TradeDate,    
	   trade.TradeDateTime,    
	   trade.TradeId,    
	   trade.VBuySell AS BuySell,    
	   trade.Rate,    
	   trade.Quantity,    
	   trade.ScripTo,      
	   oppTrade.RefClientId AS OppClientId,    
	   oppTrade.VBuySell AS OppBuySell,    
	   trade.RefInstrumentTypeId,    
	   CASE WHEN trade.BuySell = 1 THEN trade.CtclId ELSE oppTrade.CtclId END AS BuyCtslId,    
	   CASE WHEN trade.BuySell = 0 THEN trade.CtclId ELSE oppTrade.CtclId END AS SellCtslId,        
	   CASE WHEN trade.BuySell = 1 THEN trade.OrderTimeStamp ELSE oppTrade.OrderTimeStamp END AS BuyOrdTime,    
	   CASE WHEN trade.BuySell = 0 THEN trade.OrderTimeStamp ELSE oppTrade.OrderTimeStamp END AS SellOrdTime,    
	   trade.RefSegmentId
  INTO #SyncTrades      
  FROM #FilteredTrade trade    
  INNER JOIN #FilteredClient client ON client.RefClientId = trade.RefClientId                    
  INNER JOIN #FilteredTrade oppTrade ON trade.RefSegmentId = oppTrade.RefSegmentId  AND trade.RefSettlementId = oppTrade.RefSettlementId   AND trade.RefInstrumentId = oppTrade.RefInstrumentId           
  INNER JOIN #FilteredClient oppClient ON oppClient.RefClientId = oppTrade.RefClientId                  
  WHERE  trade.Quantity = oppTrade.Quantity    
	   AND trade.Rate = oppTrade.Rate    
	   AND trade.TradeDateTime = oppTrade.TradeDateTime    
	   AND trade.BuySell <> oppTrade.BuySell    
	   AND trade.RefClientId <> oppTrade.RefClientId    
	   AND trade.TradeId = oppTrade.TradeId  
                    
	  SELECT     
		   st.RefClientId,    
		   st.GroupName,    
		   st.TradeDate,        
		   SUM (st.ScripTo) AS DateWiseSyncTurnover,    
		   st.RefInstrumentTypeId,
		   st.RefInstrumentId
	  INTO #SyncTurnoverDateWise    
	  FROM #SyncTrades st    
			GROUP BY st.RefClientId,st.RefInstrumentId, st.GroupName, st.TradeDate, st.RefInstrumentTypeId   
    
    SELECT linkScripGroup.RefScripGroupId  ,
        CONVERT(DECIMAL(28,2),scenarioRule.Threshold) AS Threshold
    INTO #scenarioRules
    FROM dbo.RefAmlScenarioRule scenarioRule
    INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup linkScripGroup ON scenarioRule.RefAmlScenarioRuleId = linkScripGroup.RefAmlScenarioRuleId
    WHERE scenarioRule.RefAmlReportId = @ReportIdInternal
	
   SELECT temp.*
   INTO #FinalClientId	
   FROM
	   (SELECT     
		stdw.RefClientId,    
		stdw.GroupName,
		scripGroup.RefScripGroupId,
		SUM(stdw.DateWiseSyncTurnover) AS ClientSyncTurnover,
		stdw.RefInstrumentId
	   FROM #SyncTurnoverDateWise stdw    
	   INNER JOIN dbo.RefScripGroup scripGroup ON scripGroup.[Name] = stdw.GroupName    
	   GROUP BY stdw.RefClientId,stdw.RefInstrumentId, stdw.GroupName, scripGroup.RefScripGroupId ) temp
   INNER JOIN #scenarioRules scenarioRule ON  scenarioRule.RefScripGroupId = temp.RefScripGroupId 
   WHERE temp.ClientSyncTurnover >= scenarioRule.Threshold 
   
  SELECT
	DISTINCT fc.RefClientId
  INTO #tempDistinctiClientId
  FROM #FinalClientId fc

    
  SELECT     
   trade.RefClientId,    
   trade.RefInstrumentId,    
   SUM(CASE  WHEN trade.BuySell = 1  THEN trade.ScripTo ELSE 0 END) AS BuyTurnover,        
   SUM(CASE  WHEN trade.BuySell = 0  THEN trade.ScripTo ELSE 0 END) AS SellTurnover        
  INTO #CliInstrumentWiseTurnover    
  FROM #tempDistinctiClientId fc    
  INNER JOIN dbo.#FilteredTrade trade ON fc.RefClientId = trade.RefClientId      
  GROUP BY trade.RefClientId, trade.RefInstrumentId    
      
    SELECT    
		t.RefClientId,    
		t.Income,    
		t.Networth,
		t.IncomeGroupName
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
			CASE WHEN cl.RefClientStatusId = @InstitutionStatus AND @InstitutionalClientDefaultNetworth > 0    
				THEN COALESCE (inc.Networth, @InstitutionalClientDefaultNetworth)    
				ELSE COALESCE (inc.Networth, @DefaultNetworth, 0) END AS Networth,  
			incGroup.[Name] AS IncomeGroupName,
			ROW_NUMBER() OVER (PARTITION BY fd.RefClientId ORDER BY inc.FromDate DESC) AS RN    
		FROM #FinalClientId fd 
		INNER JOIN dbo.RefClient cl ON cl.RefClientId = fd.RefClientId    
		LEFT JOIN dbo.LinkRefClientRefIncomeGroup inc ON fd.RefClientId = inc.RefClientId    
		LEFT JOIN dbo.RefIncomeGroup incGroup ON inc.RefIncomeGroupId = incGroup.RefIncomeGroupId    
	) t    
	WHERE t.Rn = 1 
    
	SELECT DISTINCT  
        RefClientId  
    INTO #clientsToExclude  
    FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex  
    WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)  
        AND @ToDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @ToDateInternal)  
     
   SELECT     
		fc.RefClientId,    
		client.ClientId,    
		client.[Name] AS ClientName,    
		st.Code AS ScripCode,    
		inst.[Name] AS Scrip,
		inc.IncomeGroupName,
		CONVERT(DECIMAL(28, 2), inc.Income) AS Income,
		CONVERT(DECIMAL(28, 2), inc.Networth) AS Networth,
		st.GroupName,    
		st.TradeDate,
		st.TradeId,
		st.BuySell,    
		st.Rate,    
		st.Quantity,    
		st.ScripTo AS SyncTurnover, 
		stdw.DateWiseSyncTurnover,    
		fc.ClientSyncTurnover,    
		oppClient.RefClientId AS OppRefClientId,    
		oppClient.ClientId AS OppClientId,    
		oppClient.[Name] AS OppClientName,    
		st.OppBuySell,    
		cliInstWiseTurnover.BuyTurnover AS ClientBuyTurnover,    
		cliInstWiseTurnover.SellTurnover AS ClientSellTurnover,       
		st.BuyCtslId,    
		st.SellCtslId,    
		seg.Segment,    
		st.BuyOrdTime,    
		st.SellOrdTime,    
		bhavCopy.NetTurnOver AS ExchangeTurnover,    
		st.RefInstrumentId 
   FROM #FinalClientId fc 
   INNER JOIN #SyncTrades st ON fc.RefClientId = st.RefClientId AND fc.RefInstrumentId = st.RefInstrumentId AND fc.GroupName = st.GroupName  AND  st.TradeDate = @ToDateInternal     
   INNER JOIN #SyncTurnoverDateWise stdw ON fc.RefClientId = stdw.RefClientId AND stdw.RefInstrumentId = fc.RefInstrumentId  AND stdw.TradeDate = st.TradeDate AND fc.GroupName = stdw.GroupName       
   INNER JOIN dbo.RefClient client ON fc.RefClientId = client.RefClientId    
   INNER JOIN dbo.RefClient oppClient ON st.OppClientId = oppClient.RefClientId    
   INNER JOIN dbo.RefSegmentEnum seg ON st.RefSegmentId = seg.RefSegmentEnumId    
   INNER JOIN #CliInstrumentWiseTurnover cliInstWiseTurnover ON st.RefClientId = cliInstWiseTurnover.RefClientId    
    AND st.RefInstrumentId = cliInstWiseTurnover.RefInstrumentId    
   LEFT JOIN dbo.CoreBhavCopy bhavCopy ON st.RefInstrumentId = bhavCopy.RefInstrumentId AND st.RefSegmentId = bhavCopy.RefSegmentId     
    AND st.TradeDate = bhavCopy.[Date]            
   INNER JOIN dbo.RefInstrument inst ON st.RefInstrumentId = inst.RefInstrumentId   
   LEFT JOIN #IncomeData inc ON fc.RefClientId = inc.RefClientId
   LEFT JOIN #clientsToExclude clex ON clex.RefClientId = fc.RefClientId
   WHERE clex.RefClientId IS NULL  
	AND (@ExcludePro = 0 OR client.RefClientStatusId <> @ProRefClientStatusId)
			AND (@ExcludeInstitution = 0 OR client.RefClientStatusId <> @InstitutionRefClientStatusId)
			AND (@ExcludeOppositeInstitution = 0 OR oppClient.RefClientStatusId <> @InstitutionRefClientStatusId)
			AND (@ExcludeOppositePro = 0 OR oppClient.RefClientStatusId <> @ProRefClientStatusId)
  
END    
GO
--RC -END-WEB-77837
Select * from RefAmlReport where RefAmlReportId in (1280,1281,1282)