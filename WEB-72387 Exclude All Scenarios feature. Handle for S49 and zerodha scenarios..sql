--RC WEB-72387-START
GO
  ALTER PROCEDURE [dbo].[AML_GetS145HighTurnoverIn1DayInSpecificScrip]      
(      
 @ReportId INT,      
 @RunDate DATETIME,      
 @InternalIsRuleDuplicationAllowed BIT=0      
)      
AS      
BEGIN      
       
       
 DECLARE       
 @BseSegmentId INT,      
 @NseSegmentId INT,        
 @RunDateInternal DATETIME,      
 @ReportIdInternal INT,      
 @InstrumentRefEntityTypeId INT,      
 @EntityAttributeTypeRefEnumValueId INT,    
 @Lookback INT,    
 @ToDate DATETIME,    
 @LookBackDate DATETIME    
      
        
 SET @BseSegmentId = dbo.GetSegmentId('BSE_CASH')      
 SET @NseSegmentId = dbo.GetSegmentId('NSE_CASH')      
 SET @RunDateInternal  = @RunDate      
 SET @ReportIdInternal  = @ReportId      
 SELECT @InstrumentRefEntityTypeId = RefEntityTypeId FROM dbo.RefEntityType WHERE Code='Instrument';      
 SET @EntityAttributeTypeRefEnumValueId = dbo.GetEnumValueId('EntityAttributeType','UserDefined')      
     
 SELECT @Lookback = CONVERT(INT, [Value])        
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Days'           
     
 SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')      
     
 SET @LookBackDate = CONVERT(DATETIME, DATEDIFF(dd, @Lookback-1, @RunDateInternal))      
  
  SELECT DISTINCT    
	  RefClientId    
	  INTO #clientsToExclude
	  FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex    
	  WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)     
	  AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal) 
	  
 SELECT       
   trade.RefClientId,      
   trade.TradeDate,      
   trade.RefInstrumentId,      
   SUM(CASE WHEN trade.BuySell = 'Buy' THEN trade.Quantity ELSE 0 END) AS BuyQty,      
   CASE WHEN trade.BuySell = 'Buy' THEN SUM(trade.Rate * trade.Quantity) / SUM(trade.Quantity)END AS BuyPrice,      
   SUM(CASE WHEN trade.BuySell = 'Sell' THEN trade.Quantity ELSE 0 END) AS SellQty,      
   CASE WHEN trade.BuySell = 'Sell' THEN SUM(trade.Rate * trade.Quantity) / SUM(trade.Quantity)END AS SellPrice,      
   CASE WHEN trade.BuySell = 'Buy' THEN COUNT(1) END AS BuyTrades,      
   CASE WHEN trade.BuySell = 'Sell' THEN COUNT(1) END AS SellTrades          
  INTO #Trade      
  FROM dbo.CoreTrade trade    
  LEFT JOIN #clientsToExclude ex ON ex.RefClientId = trade.RefClientId  
  WHERE ex.RefClientId IS NULL AND trade.TradeDate = @RunDateInternal AND (trade.RefSegmentId = @NseSegmentId OR trade.RefSegmentId = @BseSegmentId)      
  GROUP BY       
   trade.RefClientId,      
   trade.RefInstrumentId,      
   trade.TradeDate,      
   trade.BuySell      
    
   SELECT       
   trade.RefClientId,       
   trade.RefInstrumentId,      
   COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.Rate * trade.Quantity,2))),0) AS  cumulativeTO      
   INTO #tradeLookback      
   FROM dbo.CoreTrade trade   
   LEFT JOIN #clientsToExclude ex ON ex.RefClientId = trade.RefClientId 
   WHERE ex.RefClientId IS NULL AND ( trade.TradeDate BETWEEN @LookBackDate AND @ToDate ) AND ( trade.RefSegmentId = @NseSegmentId OR trade.RefSegmentId = @BseSegmentId )       
   GROUP BY       
   trade.RefClientId,      
   trade.RefInstrumentId    
        
	DROP TABLE 	#clientsToExclude
        
  --Internal & Sms Watchlist RefEntityAttribute      
  SELECT      
  sg.RefScripGroupId,      
  sg.[Name] AS ScripName,      
  attrVal.CoreEntityAttributeValueId,      
  attrDetail.ForEntityId AS RefInstrumentId      
  INTO #mappedInstruments      
  FROM dbo.RefScripGroup sg       
  INNER JOIN dbo.CoreEntityAttributeValue attrVal ON attrVal.UserDefinedValueName=sg.[Name]       
  INNER JOIN dbo.RefEntityAttribute attr ON attr.RefEntityAttributeId=attrVal.RefEntityAttributeId      
  INNER JOIN dbo.CoreEntityAttributeDetail attrDetail ON attrDetail.RefEntityAttributeId=attr.RefEntityAttributeId AND attrDetail.CoreEntityAttributeValueId=attrVal.CoreEntityAttributeValueId      
  WHERE attr.ForRefEntityTypeId=@InstrumentRefEntityTypeId      
  AND attr.EntityAttributeTypeRefEnumValueId=@EntityAttributeTypeRefEnumValueId      
  AND attr.Code IN ('TW01','TW02') -- Internal Scrip Group, SMS Scrip Watchlist      
  AND (attrDetail.EndDate IS NULL OR attrDetail.EndDate>@RunDateInternal)      
      
  SELECT       
  DISTINCT RefInstrumentId      
  INTO #finalInstuments      
  FROM #mappedInstruments      
          
  SELECT       
   trade.RefClientId AS RefClientId,      
   trade.TradeDate AS TradeDate,      
   SUM(trade.BuyQty) AS BuyQty,      
   COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.BuyPrice * trade.BuyQty,2))),0) AS BuyTurnover,      
   COALESCE(SUM(trade.BuyPrice),0) AS BuyPrice,      
   SUM(trade.SellQty) AS SellQty,      
   COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.SellPrice * trade.SellQty,2))),0) AS SellTurnover,      
   COALESCE(SUM(trade.SellPrice),0) AS SellPrice,      
   COALESCE(SUM(CASE WHEN bhavcopy.NetTurnOver IS NULL OR bhavcopy.NetTurnOver = 0 THEN 0      
    ELSE CONVERT(DECIMAL(28,2), ROUND(((trade.BuyPrice * trade.BuyQty) / bhavcopy.NetTurnOver) * 100 ,2)) END),0)      
    AS BuyPercentage,      
               COALESCE(SUM(CASE WHEN bhavcopy.NetTurnOver IS NULL OR bhavcopy.NetTurnOver = 0 THEN 0      
    ELSE CONVERT(DECIMAL(28,2), ROUND(((trade.SellPrice * trade.SellQty) / bhavcopy.NetTurnOver) * 100 ,2))END),0)       
    AS SellPercentage,      
   COALESCE(SUM(trade.BuyTrades),0) AS BuyTrade,      
   COALESCE(SUM(trade.SellTrades),0) AS SellTrade,      
   MAX(CASE WHEN bhavcopy.NetTurnOver IS NULL THEN 0 ELSE CONVERT(DECIMAL(28,2), ROUND(bhavcopy.NetTurnOver,2))END) AS ExchangeTurnover,      
   MAX(CASE WHEN bhavcopy.NumberOfShares IS NULL THEN 0 ELSE bhavcopy.NumberOfShares END) AS ExchangeQty,          
   MAX(CASE WHEN bhavcopy.NumberOfTrades IS NULL THEN 0 ELSE bhavcopy.NumberOfTrades END) AS ExchangeTrade,          
   trade.RefInstrumentId      
  INTO #highTurnoverTrade      
  FROM #Trade trade      
    INNER JOIN dbo.RefClient client ON trade.RefClientId = client.RefClientId      
    INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId      
    INNER JOIN dbo.RefClientStatus clientStatus ON clientStatus.RefClientStatusId = client.RefClientStatusId      
    INNER JOIN #finalInstuments mapInst ON mapInst.RefInstrumentId=inst.RefInstrumentId      
    LEFT JOIN dbo.CoreBhavCopy bhavcopy On bhavcopy.Date = @RunDateInternal AND trade.RefInstrumentId = bhavcopy.RefInstrumentId       
  GROUP BY trade.RefClientId,      
     trade.RefInstrumentId,      
     trade.TradeDate           
        
      
  SELECT        
  t1.RefInstrumentId,       
  t1.ScripName,       
  linkClientStatus.RefClientStatusId,      
   scenarioRule.Threshold,       
   scenarioRule.Threshold2,    
   scenarioRule.Threshold3    
   INTO #scenarioRule      
   FROM dbo.RefAmlScenarioRule scenarioRule      
   INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus linkClientStatus ON scenarioRule.RefAmlScenarioRuleId = linkClientStatus.RefAmlScenarioRuleId      
   INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup linkScripGroup ON scenarioRule.RefAmlScenarioRuleId = linkScripGroup.RefAmlScenarioRuleId      
   INNER JOIN #mappedInstruments t1 ON t1.RefScripGroupId=linkScripGroup.RefScripGroupId      
   WHERE scenarioRule.RefAmlReportId = @ReportIdInternal      
      
 -- --default income    
  DECLARE @DefaultIncome VARCHAR (5000)  ,  
  @DefaultNetworth VARCHAR (5000)  
  SELECT @DefaultIncome = reportSetting.Value    
  FROM dbo.RefAmlQueryProfile qp       
  LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.Name = 'Client Purchase to Income'    
  LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId    
      AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId    
      AND reportSetting.Name = 'Default_Income'    
  WHERE qp.Name = 'Default'    
    
  SELECT @DefaultNetworth =  syst.[Value] FROM dbo.SysConfig syst WHERE syst.[Name] = 'Aml_Client_Default_Networth'  
        
  SELECT       
   htt.RefClientId,      
   client.ClientId AS ClientId,      
   client.[Name] AS ClientName,      
   seg.Segment,      
   htt.TradeDate,      
   inst.Code AS ScripCode,      
   inst.[Name] AS ScripName,      
   incGrp.[Name] AS IncomeGroupName,      
   COALESCE(incLink.Income,incGrp.IncomeTo, @DefaultIncome) AS Income,      
   ISNULL(incLink.Networth,@DefaultNetworth) AS Networth,      
   htt.BuyQty,      
   CONVERT(DECIMAL(28,2),htt.BuyTurnover) AS BuyTurnover,      
   htt.BuyPrice,      
   htt.SellQty,      
   CONVERT(DECIMAL(28,2),htt.SellTurnover) AS SellTurnover,      
   htt.SellPrice,      
   CONVERT(DECIMAL(28,2),htt.BuyPercentage) AS BuyPercentage,      
   CONVERT(DECIMAL(28,2),htt.SellPercentage) AS SellPercentage,      
   htt.BuyTrade,      
   htt.SellTrade,      
   htt.ExchangeTurnover,      
   htt.ExchangeQty,      
   htt.ExchangeTrade,      
   htt.RefInstrumentId,      
   STUFF((SELECT ',' + t1.ScripName       
   FROM #scenarioRule t1      
   WHERE t1.RefInstrumentId = htt.RefInstrumentId  AND      
   clientStatus.RefClientStatusId = t1.RefClientStatusId AND      
   ((htt.BuyTurnover >= t1.Threshold AND htt.BuyPercentage >= t1.Threshold2) OR      
       (htt.SellTurnover >= t1.Threshold AND htt.SellPercentage >= t1.Threshold2)) AND look.cumulativeTO >= t1.Threshold3    
    FOR      
    XML PATH('')      
    ), 1, 1, '') AS ScripGroupNames,      
    clientStatus.RefClientStatusId      
    INTO #alerts      
 FROM #highTurnoverTrade htt     
 INNER JOIN #tradeLookback look ON look.RefClientId = htt.RefClientId AND look.RefInstrumentId = htt.RefInstrumentId    
    INNER JOIN dbo.RefClient client ON htt.RefClientId = client.RefClientId      
    INNER JOIN dbo.RefInstrument inst ON htt.RefInstrumentId = inst.RefInstrumentId      
    INNER JOIN dbo.RefClientStatus clientStatus ON clientStatus.RefClientStatusId = client.RefClientStatusId      
    INNER JOIN dbo.RefSegmentEnum seg ON inst.RefSegmentId = seg.RefSegmentEnumId      
    LEFT JOIN dbo.LinkRefClientRefIncomeGroupLatest incLink ON incLink.RefClientId=client.RefClientId      
    LEFT JOIN dbo.RefIncomeGroup incGrp ON incGrp.RefIncomeGroupId=incLink.RefIncomeGroupId      
      
      
  SELECT       
   @RunDateInternal AS ReportDate,      
   htt.RefClientId,      
   htt.ClientId,      
   htt.ClientName,      
   htt.Segment,     
   @LookBackDate AS FromDate,     
   htt.TradeDate,      
   htt.ScripCode,      
   htt.ScripName,      
   htt.IncomeGroupName,      
   CAST(htt.Income AS DECIMAL(18,0)) AS Income,      
   CAST(htt.Networth AS DECIMAL(18,0)) AS Networth,      
   htt.BuyQty,      
   htt.BuyTurnover,      
   htt.BuyPrice,      
   htt.SellQty,      
   htt.SellTurnover,      
   htt.SellPrice,      
   htt.BuyPercentage,      
   htt.SellPercentage,      
   htt.BuyTrade,      
   htt.SellTrade,      
   htt.ExchangeTurnover,      
   htt.ExchangeQty,      
   htt.ExchangeTrade,      
   htt.RefInstrumentId,      
   htt.ScripGroupNames ,    
   look.cumulativeTO    
  FROM #alerts htt      
  INNER JOIN #tradeLookback look ON look.RefClientId = htt.RefClientId AND look.RefInstrumentId = htt.RefInstrumentId    
  WHERE EXISTS      
    (      
     SELECT 1      
     FROM #scenarioRule scenarioRule      
     WHERE   htt.RefClientStatusId = scenarioRule.RefClientStatusId AND      
       htt.RefInstrumentId=scenarioRule.RefInstrumentId AND      
       ((htt.BuyTurnover >= scenarioRule.Threshold AND htt.BuyPercentage >= scenarioRule.Threshold2) OR      
       (htt.SellTurnover >= scenarioRule.Threshold AND htt.SellPercentage >= scenarioRule.Threshold2)) AND look.cumulativeTO >= scenarioRule.Threshold3    
    )      
      
  AND NOT EXISTS      
  (      
  SELECT 1 FROM dbo.CoreAmlScenarioAlert alert      
  WHERE (@InternalIsRuleDuplicationAllowed = 0)      
  AND alert.RefAmlReportId=@ReportIdInternal      
  AND alert.ReportDate = @RunDateInternal      
  AND alert.RefClientId = htt.RefClientId      
  AND ISNULL(alert.RefInstrumentId,0) = ISNULL(htt.RefInstrumentId,0)      
  AND ISNULL(alert.ScripTypeExpDtPutCallStrikePrice,'') = ISNULL(htt.ScripGroupNames,'')      
  AND ISNULL(alert.ScripCode,'')=ISNULL(htt.ScripCode,'')      
  AND ISNULL(alert.InstrumentNo,'')=ISNULL(htt.ScripName,'')      
  AND ISNULL(alert.IncomeGroupName,'')=ISNULL(htt.IncomeGroupName,'')      
  AND ISNULL(alert.Income,0)=ISNULL(CAST(htt.Income AS DECIMAL(18,0)),0)      
  AND ISNULL(alert.Networth,0)=ISNULL(CAST(htt.Networth AS DECIMAL(18,0)),0)      
  AND ISNULL(alert.BuyQty,0)=ISNULL(htt.BuyQty,0)      
  AND ISNULL(alert.BuyTurnover,0)=ISNULL(CAST(htt.BuyTurnover AS DECIMAL(28,2)),0)      
  AND ISNULL(alert.BuyPrice,0)=ISNULL(CAST(htt.BuyPrice AS DECIMAL(28,2)),0)      
  AND ISNULL(alert.SellQty,0)=ISNULL(htt.SellQty,0)      
  AND ISNULL(alert.SellTurnover,0)=ISNULL(CAST(htt.SellTurnover AS DECIMAL(28,2)),0)      
  AND ISNULL(alert.SellPrice,0)=ISNULL(CAST(htt.SellPrice AS DECIMAL(28,2)),0)      
  AND ISNULL(alert.BuyPercentage,0)=ISNULL(CAST(htt.BuyPercentage AS DECIMAL(28,2)),0)      
  AND ISNULL(alert.SellPercentage,0)=ISNULL(CAST(htt.SellPercentage AS DECIMAL(28,2)),0)      
  AND ISNULL(alert.BuyTrade,0)=ISNULL(htt.BuyTrade,0)      
  AND ISNULL(alert.SellTrade,0)=ISNULL(htt.SellTrade,0)      
  AND ISNULL(alert.ExchangeTurnover,0)=ISNULL(CAST(htt.ExchangeTurnover AS DECIMAL(28,2)),0)      
  AND ISNULL(alert.ExchangeQty,0)=ISNULL(htt.ExchangeQty,0)      
  AND ISNULL(alert.ExchangeTrade,0)=ISNULL(htt.ExchangeTrade,0)      
  )      
END      
GO
--RC-WEB -72387 -END
--sync start
--RC WEB-72387-START
GO
 ALTER PROCEDURE dbo.CoreSyncTradeSegregation_GetReversalSynchronizedFnOTradeForScenarios 
 (  
  @ReportId INT,  
  @FromDate DATETIME,  
  @ToDate DATETIME,  
  @ExcludePro BIT,  
  @ExcludeInstitution BIT,  
  @ExcludeOppositePro BIT,  
  @ExcludeOppositeInstitution BIT,  
  @ExcludealgoTrade BIT,  
  @Vertical VARCHAR(20)  
 )  
AS  
 BEGIN  
  
  DECLARE @ReportIdInternal INT  
  DECLARE @FromDateInternal DATETIME  
  DECLARE @ToDateInternal DATETIME  
  DECLARE @ExcludeProInternal BIT  
  DECLARE @ExcludeInstitutionInternal BIT    
  DECLARE @ExcludeOppositeProInternal BIT  
  DECLARE @ExcludeOppositeInstitutionInternal BIT  
  DECLARE @ExcludealgoTradeInternal BIT  
  DECLARE @VerticalInternal VARCHAR(20),@VerticalInternalId INT
  DECLARE @FromDateWithoutTime DATETIME, @ToDateWithoutTime DATETIME
  DECLARE @OPTCUR INT,
	@FUTCUR INT,
	@OPTSTK INT, 
	@OPTIDX INT,
	@OPTIRC INT,
	@OPTFUT INT,
	@FUTCOM INT,   
	  @ProRefClientStatusId INT,    
	  @InstitutionRefClientStatusId INT,    
	  @MCX_FNO INT,    
	  @NCDEX_FNO INT,    
	  @NSE_FNO INT,    
	  @NSE_CDX INT,    
	  @MCXSX_CDX INT,
 @S118 INT,@S119 INT,@S113 INT

 SELECT @S113=RefAmlReportId FROM dbo.RefAmlReport WHERE Code='S113'
 SELECT @S118=RefAmlReportId FROM dbo.RefAmlReport WHERE Code='S118'
 SELECT @S119=RefAmlReportId FROM dbo.RefAmlReport WHERE Code='S119'

   SELECT RefInstrumentTypeId,InstrumentType 
	INTO #instrumentType
	FROM dbo.RefInstrumentType 

  SELECT @OPTCUR=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='OPTCUR'
  SELECT @FUTCUR=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='FUTCUR'
  SELECT @OPTSTK=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='OPTSTK'
  SELECT @OPTIDX=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='OPTIDX'
  SELECT @OPTIRC=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='OPTIRC'
  SELECT @OPTFUT=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='OPTFUT'
  SELECT @FUTCOM=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='FUTCOM'
  
  SET @ReportIdInternal = @ReportId  
        SET @FromDateInternal =  @FromDate  
        SET @ToDateInternal = @ToDate 
		SET @FromDateWithoutTime =  dbo.GetDateWithoutTime(@FromDate)  
        SET @ToDateWithoutTime = dbo.GetDateWithoutTime(@ToDate)   
        SET @ExcludeProInternal = @ExcludePro  
        SET @ExcludeInstitutionInternal = @ExcludeInstitution          
        SET @ExcludeOppositeProInternal = @ExcludeOppositePro  
        SET @ExcludeOppositeInstitutionInternal = @ExcludeOppositeInstitution  
  SET @ExcludealgoTradeInternal=@ExcludealgoTrade  
  SET @VerticalInternal = @Vertical   
  SET @VerticalInternalId =  CASE WHEN @VerticalInternal = 'NonCommodity' THEN 1 ELSE 0 END   

	 SET @InstitutionRefClientStatusId= dbo.GetClientStatusId('Institution')    
	 SET @ProRefClientStatusId=dbo.GetClientStatusId('Pro')    
    
	 SELECT   
	  RefSegmentEnumId, Code     
	 INTO #Segments    
	 FROM dbo.RefSegmentEnum    
    
	 SELECT @MCX_FNO=RefSegmentEnumId FROM #Segments WHERE CODE='MCX_FNO'    
	 SELECT @NCDEX_FNO=RefSegmentEnumId FROM #Segments WHERE CODE='NCDEX_FNO'    
	 SELECT @NSE_FNO=RefSegmentEnumId FROM #Segments WHERE CODE='NSE_FNO'    
	 SELECT @NSE_CDX=RefSegmentEnumId FROM #Segments WHERE CODE='NSE_CDX'    
	 SELECT @MCXSX_CDX=RefSegmentEnumId FROM #Segments WHERE CODE='MCXSX_CDX' 

	 SELECT DISTINCT    
	  RefClientId    
	  INTO #clientsToExclude
	  FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex    
	  WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)     
	  AND @ToDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @ToDateInternal) 

	SELECT seg.RefSegmentEnumId,      
		seg.Segment      
	 INTO #RequiredSegment     
	 FROM dbo.RefSegmentEnum Seg    
	 WHERE   
	 (  
	  @VerticalInternalId = 1 AND seg.RefSegmentEnumId IN (@NSE_FNO,@NSE_CDX,@MCXSX_CDX)  
	 )      
	 or      
	 (  
	  @VerticalInternalId = 0 AND seg.RefSegmentEnumId IN (@NCDEX_FNO, @MCX_FNO)  
	 )      
	 SELECT trade.CoreSyncTradeSegregationId ,trade.RefClientId,trade.OppRefClientId  
	 INTO #tradeSyncIds    
	 FROM dbo.CoreSyncTradeSegregation trade  
	 INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
	 INNER JOIN dbo.RefClient oppClient ON oppClient.RefClientId = trade.OppRefClientId  
	 INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId  
	 LEFT JOIN #clientsToExclude ex ON ex.RefClientId = trade.RefClientId 
	 WHERE   ex.RefClientId IS NULL AND
	  trade.TradeDate BETWEEN @FromDateInternal AND @ToDateInternal  
	  AND (    
	   @ExcludealgoTradeInternal = 0 OR   
	   (  
		@ExcludealgoTradeInternal = 1   
		AND     
		 ISNULL(trade.IsAlgoTrade,0) = 0  
	   )  
	  )  
	
	SELECT Distinct RefClientId 
	INTO #distinctClient 
	FROM #tradeSyncIds  
	
	SELECT client.RefClientId, client.RefClientStatusId,client.RefIntermediaryId   
	 INTO #TempClient    
	 FROM #distinctClient trade    
	 INNER JOIN dbo.RefClient client ON trade.RefClientId = client.RefClientId    
      
	 SELECT RefClientId,RefIntermediaryId    
	 INTO #FilteredClient    
	 FROM #TempClient    
	 WHERE (@ExcludeProInternal = 0 OR RefClientStatusId != @ProRefClientStatusId)    
	 AND (@ExcludeInstitutionInternal = 0 OR RefClientStatusId != @InstitutionRefClientStatusId)     
      
	 SELECT Distinct OppRefClientId INTO #distinctOppClient FROM #tradeSyncIds  
	 SELECT client.RefClientId, client.RefClientStatusId   
	 INTO #TempOppClient    
	 FROM #distinctOppClient trade    
	 INNER JOIN dbo.RefClient client ON trade.OppRefClientId = client.RefClientId   
  
	 SELECT RefClientId    
	 INTO #FilteredOppositeClient    
	 FROM #TempOppClient    
	 WHERE (@ExcludeOppositeProInternal = 0 OR RefClientStatusId != @ProRefClientStatusId)    
	 AND (@ExcludeOppositeInstitutionInternal = 0 OR RefClientStatusId != @InstitutionRefClientStatusId)  


	 SELECT      
	  -- trade.CoreTradeId,    
	  trade.RefClientId,    
	  trade.RefInstrumentId,    
	  trade.RefInstrumentTypeId,   
	  trade.TradeDate,    
	  trade.TradeDateTime,    
	  trade.TradeId,    
	  CASE WHEN trade.BuySell  = 1 THEN 1 ELSE 0 END AS IsBuy,    
	  trade.Rate,    
	  trade.Quantity,        
	  CASE     
	   WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCUR  AND @ReportIdInternal NOT IN(@S113,@S118,@S119)      
		THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + inst.StrikePrice) * (ISNULL(inst.GeneralNumerator,1) / ISNULL(inst.GeneralDenominator,1)) * inst.MarketLot * inst.ContractSize, 2))          
	   WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@FUTCUR,@OPTCUR)    
		THEN CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.Quantity * inst.ContractSize, 2))          
	   WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTK, @OPTIDX, @OPTIRC)    AND @ReportIdInternal NOT IN(@S113,@S118,@S119)     
		THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + inst.StrikePrice) * (ISNULL(inst.GeneralNumerator,1) / ISNULL(inst.GeneralDenominator,1)) * inst.MarketLot, 2))     
	   WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCUR, @FUTCUR, @OPTSTK, @OPTIDX, @OPTIRC)       
		THEN  CONVERT(DECIMAL(28, 2), ROUND(trade.Rate *(ISNULL(inst.GeneralNumerator,1) / ISNULL(inst.GeneralDenominator,1)) * inst.MarketLot, 2))     
	   WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTIDX, @OPTSTK, @OPTCUR)       
		THEN (inst.StrikePrice + trade.Rate) * trade.Quantity     
	  ELSE    trade.Rate * trade.Quantity     
	  END AS SyncTurnover,        
	  oppClient.RefClientId AS OppRefClientId,    
	  CASE WHEN trade.BuySell  = 1 THEN 0 ELSE 1 END AS OppIsBuy,      
	  trade.RefSegmentId,    
	  trade.IsAlgoTrade  
	 INTO #SynchronizedTrades      
	 FROM #tradeSyncIds temp  
	 INNER JOIN dbo.CoreSyncTradeSegregation trade   ON temp.CoreSyncTradeSegregationId = trade.CoreSyncTradeSegregationId  
	 INNER JOIN #FilteredClient client ON client.RefClientId = trade.RefClientId                    
	 INNER JOIN #FilteredOppositeClient oppClient ON oppClient.RefClientId = trade.OppRefClientId                                                     
	 INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId  
  

	----------------------------  
	SELECT  
	 sync.RefclientId ,
	 sync.IsBuy ,
	 sync.Rate ,
	 sync.Quantity ,
	 sync.SyncTurnover ,
	 sync.OppRefClientId,
	 sync.OppIsBuy ,
	 sync.TradeId ,
	 sync.TradeDate,
	 sync.TradeDateTime ,
	 sync.RefInstrumentId,
	 sync.RefInstrumentTypeId ,
	 sync.RefSegmentId 
	INTO #reversalTrades 
	FROM #SynchronizedTrades sync WHERE TradeDate = @ToDateInternal  
  
	CREATE NONCLUSTERED INDEX [IX_#SynchronizedTrades_TradeDate]
	ON #SynchronizedTrades (RefclientId,OppRefClientId,IsBuy,RefSegmentId,RefInstrumentId)
	CREATE NONCLUSTERED INDEX [IX_#reversalTrades_TradeDate]
	ON #reversalTrades (RefclientId,OppRefClientId,IsBuy,RefSegmentId,RefInstrumentId)
	---------------------------  
	SELECT   
	 sync.RefclientId,   
	 sync.IsBuy,  
	 sync.Rate,  
	 sync.Quantity,  
	 sync.SyncTurnover,  
	 sync.OppRefClientId AS OppRefClientId,  
	 sync.OppIsBuy AS OppIsBuy,  
	 sync.TradeId,  
	 sync.TradeDate,  
	 sync.TradeDateTime,  
	 sync.RefInstrumentId,  
	 sync.RefInstrumentTypeId,  
	 sync.RefSegmentId,  
	 reversal.RefclientId AS OppTrdRefClientId,  
	 reversal.IsBuy AS OppTrdIsBuy,  
	 reversal.Rate AS OppTrdRate,  
	 reversal.Quantity AS OppTrdQuantity,  
	 reversal.SyncTurnover AS OppTrdSyncTurnover,  
	 reversal.OppRefClientId AS OppTrdOppRefClientId,  
	 reversal.OppIsBuy AS oppTrdOppIsBuy,  
	 reversal.TradeId AS OppTrdTradeId,  
	 reversal.TradeDate AS OppTrdTradeDate,  
	 reversal.TradeDateTime AS OppTrdTradeDateTime,  
	 reversal.RefInstrumentId AS OppTrdRefInstrumentId,  
	 reversal.RefInstrumentTypeId AS OppTrdInstrumentTypeId,  
	 reversal.RefSegmentId AS OppTrdSegmentId,  
	 ROW_NUMBER() OVER(PARTITION BY reversal.RefclientId, reversal.TradeId, sync.TradeDate, sync.RefInstrumentId, sync.RefSegmentId ORDER BY sync.TradeDateTime DESC) AS RowNumber  
  
	INTO   
	 #tempReversal   
	FROM   
	 #reversalTrades reversal   
	 INNER JOIN  #SynchronizedTrades sync ON sync.RefclientId = reversal.OppRefClientId  
			  AND sync.OppRefClientId = reversal.RefclientId  
			  AND sync.IsBuy = reversal.IsBuy  
			  AND sync.RefInstrumentId = reversal.RefInstrumentId  
			  AND sync.RefSegmentId = reversal.RefSegmentId  
	WHERE   
	 sync.TradeDateTime < reversal.TradeDateTime  
  

-----------------------------  
SELECT   
 reversal.*,  
 (SELECT SUM(Quantity) FROM #tempReversal temp WHERE temp.RefclientId = reversal.RefclientId  
             AND temp.OppTrdSegmentId = reversal.OppTrdSegmentId  
             AND temp.RefInstrumentId = reversal.RefInstrumentId  
             AND temp.OppTrdTradeDateTime = reversal.OppTrdTradeDateTime  
             AND temp.OppTrdTradeId = reversal.OppTrdTradeId  
             AND temp.RowNumber <= reversal.RowNumber  
 ) AS CumulativeQuantity,  
 (SELECT AVG(Rate) FROM #tempReversal temp WHERE temp.RefclientId = reversal.RefclientId   
             AND temp.OppTrdSegmentId = reversal.OppTrdSegmentId  
             AND temp.RefInstrumentId = reversal.RefInstrumentId  
             AND temp.OppTrdTradeDateTime = reversal.OppTrdTradeDateTime  
             AND temp.OppTrdTradeId = reversal.OppTrdTradeId  
             AND temp.RowNumber <= reversal.RowNumber  
 ) AS CumulativeAverageRate  
  
INTO  
  #tempConsolidatedpReversal  
FROM  
 #tempReversal reversal  
  
-------------------------------  
  
SELECT   
 temp2.*   
INTO   
 #finalConsolidatedReversal  
FROM  
 (  
  SELECT   
   temp1.*,  
   ROW_NUMBER() OVER(PARTITION BY OppTrdRefClientId, OppTrdTradeId, OppTrdTradeDate, OppTrdRefInstrumentId,OppTrdSegmentId ORDER BY TradeDateTime DESC) AS NewRowNumber  
  FROM   
   (  
    SELECT * FROM #tempConsolidatedpReversal WHERE (Quantity - CumulativeQuantity) <= 0  
   ) AS temp1  
 ) AS temp2   
WHERE   
 temp2.NewRowNumber = 1  
  
--------------------------------  
  
SELECT  
 f.OppTrdRefClientId AS ReversalRefClientId,  
 client.ClientId AS ReversalClientId,  
 client.Name AS ReversalClientName,  
	(CASE WHEN OppTrdRate > Rate  THEN OppTrdRate
	WHEN Rate > CumulativeAverageRate THEN Rate 
	ELSE CumulativeAverageRate END) AS ReversalRate,  
	(CASE WHEN OppTrdQuantity< Quantity  THEN OppTrdQuantity
	WHEN Quantity < CumulativeQuantity THEN Quantity
	 ELSE CumulativeQuantity END) AS ReversalQuantity, 
 CASE WHEN f.OppTrdIsBuy = 1 THEN 'Buy' ELSE 'Sell' END AS ReversalBuySell,  
 OppInst.Code  AS ReversalScripCode,  
 f.OppTrdRefInstrumentId AS ReversalRefInstrumentId,  
 instType.InstrumentType AS ReversalInstrumentType,  
 f.OppTrdOppRefClientId AS ReversalOppRefClientId,  
 OppClient.ClientId AS ReversalOppClientId,  
 OppClient.Name AS ReversalOppClientName,  
 f.OppTrdTradeDate AS ReversalTradeDate,  
 f.OppTrdTradeId AS ReversalTradeId,  
 f.OppTrdSegmentId,  
 (COALESCE(OppInst.ScripId,'') +' - '+ COALESCE(instType.InstrumentType,'')  +' - '+ COALESCE(CONVERT(VARCHAR,OppInst.ExpiryDate,106),'') +' - '+ COALESCE(OppInst.PutCall,'') +' - '+ COALESCE(CONVERT(VARCHAR,CONVERT (DECIMAL(19,2),OppInst.StrikePrice)),'')) AS ReversalScripTypeExpDtPutCallStrikePrice,  
 STUFF(( SELECT ', ' + (CONVERT(VARCHAR(200),t.TradeId) + '-' + CONVERT(VARCHAR(200),t.TradeDate, 111))  
     FROM #tempReversal t  
     WHERE t.RefclientId = f.RefclientId  
         AND t.OppTrdTradeId = f.OppTrdTradeId   
      AND t.OppTrdTradeDate = f.OppTrdTradeDate  
      AND t.OppTrdRefInstrumentId = f.OppTrdRefInstrumentId
      AND t.OppTrdSegmentId = f.OppTrdSegmentId  
      AND t.RowNumber <= f.RowNumber  
    FOR  
    XML PATH('')  
    ), 1, 1, '') AS SyncTrades  
  
 INTO #finalReversal  
 FROM #finalConsolidatedReversal f
 INNER JOIN dbo.RefClient client ON client.RefClientId = f.OppTrdRefClientId
 INNER JOIN dbo.RefClient OppClient ON OppClient.RefClientId = f.OppTrdOppRefClientId 
 LEFT JOIN dbo.RefInstrument OppInst ON OppInst.RefInstrumentId = OppTrdRefInstrumentId
 LEFT JOIN dbo.RefInstrumentType instType ON instType.RefInstrumentTypeId =  f.OppTrdInstrumentTypeId 
  

  SELECT DISTINCT ReversalRefInstrumentId
  INTO #distinctInstruments
  FROM #FinalReversal


  SELECT ins.RefInstrumentId,
	  ins.RefInstrumentTypeId,
	  instType.InstrumentType AS InstrumentType,
	ISNULL(ins.StrikePrice,0) AS StrikePrice, 
	ISNULL(ins.PriceNumerator,1) AS PriceNumerator,
	ISNULL(ins.ContractSize, 1) AS ContractSize,
	ISNULL(ins.PriceDenominator, 1) AS PriceDenominator,
	ISNULL(ins.GeneralNumerator, 1) AS GeneralNumerator, 
	ISNULL(ins.GeneralDenominator, 1) AS GeneralDenominator,
	ISNULL(ins.MarketLot, 1) AS MarketLot 
	INTO #instrumentDet
	FROM #distinctInstruments tmpInst
	INNER JOIN dbo.RefInstrument ins ON ins.RefInstrumentId=tmpInst.ReversalRefInstrumentId
	INNER JOIN #instrumentType instType ON ins.RefInstrumentTypeId = instType.RefInstrumentTypeId   
   

  
    SELECT   
  ReversalRefClientId AS RefclientId,  
  ReversalClientId AS ClientId,  
     ReversalClientName AS ClientName,  
  ReversalScripCode AS ScripCode,  
  temp.ReversalRefInstrumentId AS RefInstrumentId,  
  temp.ReversalInstrumentType AS InstrumentType,  
  ReversalScripTypeExpDtPutCallStrikePrice AS ScripTypeExpDtPutCallStrikePrice,  
  ReversalBuySell AS BuySell,  
     ReversalOppRefClientId AS OppRefClientId,  
        ReversalOppClientId as OppClientId,  
        ReversalOppClientName AS OppClientName,  
	@FromDateWithoutTime AS FromDate,  
     @ToDateWithoutTime AS ToDate,  
        ReversalQuantity as ReversalQty,  
     ReversalRate AS ReversalRate,  
   (  
   CASE  
    WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR)   AND @ReportIdInternal NOT IN(@S113,@S118,@S119) 
    THEN CONVERT(DECIMAL(28,2),ROUND((temp.ReversalRate + inst.StrikePrice) * (inst.PriceNumerator /inst.PriceDenominator * temp.ReversalQuantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator) * inst.ContractSize,2))       
       
  WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCUR,@OPTCUR)  
    THEN CONVERT(DECIMAL(28,2),ROUND(temp.ReversalRate * temp.ReversalQuantity * inst.ContractSize,2))       
  
  WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)   AND @ReportIdInternal NOT IN(@S113,@S118,@S119)  
    THEN CONVERT(DECIMAL(28,2),ROUND((temp.ReversalRate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * temp.ReversalQuantity) * inst.MarketLot * (inst.GeneralNumerator/inst.GeneralDenominator),2))  
       
  WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
    THEN  CONVERT(DECIMAL(28,2),ROUND(temp.ReversalRate * (inst.PriceNumerator /inst.PriceDenominator * temp.ReversalQuantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2))   
       
  WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR)   
    THEN (inst.StrikePrice + temp.ReversalRate) * temp.ReversalQuantity  
  ELSE   
   temp.ReversalRate * temp.ReversalQuantity     
  END       
   ) AS ReversalSyncTO,  
   ReversalTradeId,  
   ReversalTradeDate,   
   SyncTrades  
  
   FROM #FinalReversal temp  
   INNER JOIN #instrumentDet inst ON inst.RefInstrumentId = temp.ReversalRefInstrumentId                  
   WHERE EXISTS(  
  select 1    
  FROM dbo.RefAmlScenarioRule rules   
  INNER JOIN LinkRefAmlScenarioRuleRefInstrumentType linkInstType on linkInstType.RefAmlScenarioRuleId = rules.RefAmlScenarioRuleId   
  AND linkInstType.RefInstrumentTypeId= inst.RefInstrumentTypeId  
  WHERE rules.RefAmlReportId=@ReportIdInternal  
  AND (ReversalQuantity * ReversalRate) >= rules.Threshold  
 )  
  
END  
GO

GO
ALTER PROCEDURE dbo.CoreSyncTradeSegregation_GetSynchronizedFnOTradeForScenarios    
 (    
  @ReportId INT,    
  @FromDate DATETIME,    
  @ToDate DATETIME,    
  @ExcludePro BIT,    
  @ExcludeInstitution BIT,    
  @ExcludeOppositePro BIT,    
  @ExcludeOppositeInstitution BIT,    
  @ExcludealgoTrade BIT,    
  @Vertical VARCHAR(20),    
  @ApplyScenarioRule BIT = 1    
 )    
AS    
 BEGIN    
	DECLARE @ReportIdInternal INT    
	DECLARE @FromDateInternal DATETIME    
	DECLARE @ToDateInternal DATETIME,@ToDateWithoutTime DATETIME    
	DECLARE @ExcludeProInternal BIT    
	DECLARE @ExcludeInstitutionInternal BIT      
	DECLARE @ExcludeOppositeProInternal BIT    
	DECLARE @ExcludeOppositeInstitutionInternal BIT    
	DECLARE @ExcludealgoTradeInternal BIT,@ApplyScenarioRuleInternal BIT    
	DECLARE @VerticalInternal VARCHAR(20),@VerticalInternalId INT      
        
	SET @ReportIdInternal = @ReportId    
	SET @FromDateInternal = @FromDate    
	SET @ToDateInternal = @ToDate    
	SET @ToDateWithoutTime = dbo.GetDateWithoutTime(@ToDate)    
	SET @ExcludeProInternal = @ExcludePro    
	SET @ExcludeInstitutionInternal = @ExcludeInstitution            
	SET @ExcludeOppositeProInternal = @ExcludeOppositePro    
	SET @ExcludeOppositeInstitutionInternal = @ExcludeOppositeInstitution    
	SET @ExcludealgoTradeInternal=@ExcludealgoTrade    
	SET @VerticalInternal = @Vertical    
	SET @ApplyScenarioRuleInternal = @ApplyScenarioRule    
	SET @VerticalInternalId =  CASE WHEN @VerticalInternal = 'NonCommodity' THEN 1 ELSE 0 END 

	DECLARE @OPTCUR INT,  
		@FUTCUR INT,  
		@OPTSTK INT,   
		@OPTIDX INT,  
		@OPTIRC INT,  
		@OPTFUT INT,  
		@FUTCOM INT,  
		@ProRefClientStatusId INT,  
		@InstitutionRefClientStatusId INT,  
		@MCX_FNO INT,  
		@NCDEX_FNO INT,  
		@NSE_FNO INT,  
		@NSE_CDX INT,  
		@MCXSX_CDX INT  
  
	SELECT 
		RefInstrumentTypeId,[Name]   
	INTO #instrumentType  
	FROM dbo.RefInstrumentType   
  
	SELECT @OPTCUR=RefInstrumentTypeId FROM #instrumentType WHERE [Name]='OPTCUR'  
	SELECT @FUTCUR=RefInstrumentTypeId FROM #instrumentType WHERE [Name]='FUTCUR'  
	SELECT @OPTSTK=RefInstrumentTypeId FROM #instrumentType WHERE [Name]='OPTSTK'  
	SELECT @OPTIDX=RefInstrumentTypeId FROM #instrumentType WHERE [Name]='OPTIDX'  
	SELECT @OPTIRC=RefInstrumentTypeId FROM #instrumentType WHERE [Name]='OPTIRC'  
	SELECT @OPTFUT=RefInstrumentTypeId FROM #instrumentType WHERE [Name]='OPTFUT'  
	SELECT @FUTCOM=RefInstrumentTypeId FROM #instrumentType WHERE [Name]='FUTCOM'  
  
	SET @InstitutionRefClientStatusId= dbo.GetClientStatusId('Institution')  
	SET @ProRefClientStatusId=dbo.GetClientStatusId('Pro')  
  
	SELECT 
		RefSegmentEnumId, Code   
	INTO #Segments  
	FROM dbo.RefSegmentEnum  
  
	SELECT @MCX_FNO=RefSegmentEnumId FROM #Segments WHERE CODE='MCX_FNO'  
	SELECT @NCDEX_FNO=RefSegmentEnumId FROM #Segments WHERE CODE='NCDEX_FNO'  
	SELECT @NSE_FNO=RefSegmentEnumId FROM #Segments WHERE CODE='NSE_FNO'  
	SELECT @NSE_CDX=RefSegmentEnumId FROM #Segments WHERE CODE='NSE_CDX'  
	SELECT @MCXSX_CDX=RefSegmentEnumId FROM #Segments WHERE CODE='MCXSX_CDX'  
    
	SELECT DISTINCT    
	  RefClientId    
	  INTO #clientsToExclude
	  FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex    
	  WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)     
	  AND @ToDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @ToDateInternal) 
  
	SELECT seg.RefSegmentEnumId,    
	  seg.Segment    
	INTO #RequiredSegment   
	FROM dbo.RefSegmentEnum Seg  
	WHERE 
	(
		@VerticalInternalId = 1 AND seg.RefSegmentEnumId IN (@NSE_FNO,@NSE_CDX,@MCXSX_CDX)
	)    
	or    
	(
		@VerticalInternal = 'Commodity' AND seg.RefSegmentEnumId IN (@NCDEX_FNO, @MCX_FNO)
	)    
	SELECT trade.CoreSyncTradeSegregationId ,trade.RefClientId,trade.OppRefClientId
	INTO #tradeSyncIds  
	FROM dbo.CoreSyncTradeSegregation trade
	INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId
	INNER JOIN dbo.RefClient oppClient ON oppClient.RefClientId = trade.OppRefClientId
	INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId 
	LEFT JOIN #clientsToExclude ex ON ex.RefClientId = trade.RefClientId 
	 WHERE   ex.RefClientId IS NULL AND
	 
		trade.TradeDate BETWEEN @FromDateInternal AND @ToDateInternal
		AND (    
				(@ApplyScenarioRuleInternal  = 0)     
				OR     
				(@ApplyScenarioRuleInternal = 1 AND  trade.TradeDate = @ToDateWithoutTime)    
		) 
		AND (  
			@ExcludealgoTradeInternal = 0 OR 
			(
				@ExcludealgoTradeInternal = 1 
				AND   
					ISNULL(trade.IsAlgoTrade,0) = 0
			)
		)
  SELECT Distinct RefClientId INTO #distinctClient FROM #tradeSyncIds
	SELECT client.RefClientId, client.RefClientStatusId,client.RefIntermediaryId 
	INTO #TempClient  
	FROM #distinctClient trade  
	INNER JOIN dbo.RefClient client ON trade.RefClientId = client.RefClientId  
    
	SELECT RefClientId,RefIntermediaryId  
	INTO #FilteredClient  
	FROM #TempClient  
	WHERE (@ExcludeProInternal = 0 OR RefClientStatusId != @ProRefClientStatusId)  
	AND (@ExcludeInstitutionInternal = 0 OR RefClientStatusId != @InstitutionRefClientStatusId)   
    
	SELECT Distinct OppRefClientId INTO #distinctOppClient FROM #tradeSyncIds
	SELECT client.RefClientId, client.RefClientStatusId 
	INTO #TempOppClient  
	FROM #distinctOppClient trade  
	INNER JOIN dbo.RefClient client ON trade.OppRefClientId = client.RefClientId 

	SELECT RefClientId  
	INTO #FilteredOppositeClient  
	FROM #TempOppClient  
	WHERE (@ExcludeOppositeProInternal = 0 OR RefClientStatusId != @ProRefClientStatusId)  
	AND (@ExcludeOppositeInstitutionInternal = 0 OR RefClientStatusId != @InstitutionRefClientStatusId) 

	SELECT    
		-- trade.CoreTradeId,  
		trade.RefClientId,  
		trade.RefInstrumentId,  
		trade.RefInstrumentTypeId, 
		trade.TradeDate,  
		trade.TradeDateTime,  
		trade.TradeId,  
		CASE WHEN trade.BuySell  = 1 THEN 1 ELSE 0 END AS BuySell,  
		trade.Rate,  
		trade.Quantity,      
		CASE  	
			WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCUR  		
				THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + inst.StrikePrice) * (ISNULL(inst.GeneralNumerator,1) / ISNULL(inst.GeneralDenominator,1)) * inst.MarketLot * inst.ContractSize, 2))       	
			WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @FUTCUR  		
				THEN CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.Quantity * inst.ContractSize, 2))       	
			WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTK, @OPTIDX, @OPTIRC)   		
				THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + inst.StrikePrice) * (ISNULL(inst.GeneralNumerator,1) / ISNULL(inst.GeneralDenominator,1)) * inst.MarketLot, 2))  	
			WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCUR, @FUTCUR, @OPTSTK, @OPTIDX, @OPTIRC)   		
				THEN  CONVERT(DECIMAL(28, 2), ROUND(trade.Rate *(ISNULL(inst.GeneralNumerator,1) / ISNULL(inst.GeneralDenominator,1)) * inst.MarketLot, 2))  	
			WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTIDX, @OPTSTK, @OPTCUR)   		
				THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  	
		ELSE   	trade.Rate * trade.Quantity   
		END AS SyncTurnover,      
		oppClient.RefClientId AS OppClientId,  
		CASE WHEN trade.BuySell  = 1 THEN 0 ELSE 1 END AS OppBuySell,  
		trade.BuyCtslId,  
		trade.SellCtslId,      
		trade.BuyTerminal,  
		trade.SellTerminal,      
		trade.BuyOrdTime,  
		trade.SellOrdTime,  
		trade.RefSegmentId,  
		trade.IsAlgoTrade
	INTO #SyncTradesTemp    
	FROM #tradeSyncIds temp
	INNER JOIN dbo.CoreSyncTradeSegregation trade   ON temp.CoreSyncTradeSegregationId = trade.CoreSyncTradeSegregationId
	INNER JOIN #FilteredClient client ON client.RefClientId = trade.RefClientId                  
	INNER JOIN #FilteredOppositeClient oppClient ON oppClient.RefClientId = trade.OppRefClientId                                                   
	INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId


   --SELECT   
	  -- RefClientId,    
	  -- RefInstrumentId,    
	  -- TradeId,    
	  -- CASE WHEN BuySell = 'Buy' THEN 1  ELSE 0 END AS IsBuy,     
	  -- Rate,    
	  -- Quantity,    
	  -- RefSegmentId,        
	  -- RefSettlementId,    
	  -- TraderId,    
	  -- OrderTimeStamp,  
	  -- TradeIdAlphaNumeric  
   ----INTO #reqTrades  
   --FROM #reqTradesIds rid  
   --INNER JOIN dbo.CoreTrade tr ON tr.CoreTradeId=rid.CoreTradeId  

 --    select
	--	trade.RefClientId,    
	--	trade.RefInstrumentId,    
	--	trade.TradeId,    
	--	trade.IsBuy ,    
	--	trade.Rate,    
	--	trade.Quantity,    
	--	trade.RefSegmentId,        
	--	trade.RefSettlementId,    
	--	trade.TraderId,    
	--	trade.OrderTimeStamp,    
	--	CASE WHEN SUBSTRING(CONVERT(varchar,trade.CtclId),13,1) IN ('0','2','4') then 1 else 0 end as IsAlgoTrade ,   
	--	trade.TradeIdAlphaNumeric,    
	--	convert(varchar(50),trade.TraderId) AS UserId    
	----INTO #FilteredTrade    
	--FROM #reqTrades trade    
	--INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId    
	--where   
	--(  
	--	(@ExcludealgoTradeInternal=0)  
	--	OR  
	--	(@ExcludealgoTradeInternal=1 AND (len(convert(varchar,trade.CtclId))=15 AND 
	--	substring(convert(varchar,trade.CtclId),13,1) NOT IN ('0','2','4')))  
	--)    
    
  
      
  
    
         
   
    SELECT st.RefClientId,    
    st.RefInstrumentTypeId,    
    st.TradeDate,        
    CONVERT(DECIMAL(28,2),SUM (st.SyncTurnover)) AS DateWiseSyncTurnover        
  INTO #SyncTurnoverDateWise    
        FROM #SyncTradesTemp st    
        GROUP BY st.RefClientId, st.RefInstrumentTypeId, st.TradeDate    
            
            
        SELECT stdw.RefClientId,    
    stdw.RefInstrumentTypeId,    
    SUM(stdw.DateWiseSyncTurnover) AS ClientSyncTurnover            
        INTO #FinalDateWiseTuruover    
        FROM #SyncTurnoverDateWise stdw    
    INNER JOIN dbo.RefInstrumentType instrumentType ON instrumentType.RefInstrumentTypeId = stdw.RefInstrumentTypeId    
        GROUP BY stdw.RefClientId,stdw.RefInstrumentTypeId    
         HAVING (@ApplyScenarioRuleInternal = 0 ) OR ( @ApplyScenarioRuleInternal = 1 AND EXISTS     
    (    
     SELECT 1    
     FROM dbo.RefAmlScenarioRule scenarioRule    
     INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType linkInstrumentType ON scenarioRule.RefAmlScenarioRuleId = linkInstrumentType.RefAmlScenarioRuleId    
     WHERE scenarioRule.RefAmlReportId = @ReportIdInternal AND stdw.RefInstrumentTypeId = linkInstrumentType.RefInstrumentTypeId    
       AND SUM(stdw.DateWiseSyncTurnover) >= scenarioRule.Threshold    
    )    
  )    
  
	
	SELECT   t.RefClientId
	INTO #tradeClients
	FROM (
		SELECT  RefClientId
		FROM #FilteredClient

		UNION

		SELECT  RefClientId
		FROM #FilteredOppositeClient
	) t

   SELECT   
	 CoreTradeId  
   INTO #tradeIds  
   FROM #Segments seg  
   inner join dbo.CoreTrade tr ON tr.RefSegmentId=seg.RefSegmentEnumId 
   INNER JOIN #tradeClients client ON client.RefClientId =  tr.RefClientId
   where TradeDate BETWEEN @FromDateInternal AND @ToDateInternal    
	
	SELECT   
		trade.RefClientId,  
		trade.RefInstrumentId, 
		trade.RefSegmentId,
		CASE WHEN trade.BuySell = 'Buy'  
		THEN 1  
		WHEN trade.BuySell = 'Sell'  
		THEN 0 END AS BuySell,   
		trade.Rate,  
		trade.Quantity,  
		inst.RefInstrumentTypeId,  
		ISNULL(inst.StrikePrice, 0) AS StrikePrice,  
		ISNULL(inst.MarketLot, 1) AS MarketLot,  
		ISNULL(inst.ContractSize, 1) AS ContractSize,  
		(ISNULL(inst.PriceNumerator,1) /ISNULL(inst.PriceDenominator,1) * trade.Quantity) *   
		(ISNULL(inst.GeneralNumerator,1) / ISNULL(inst.GeneralDenominator,1)) AS NDQ  
	INTO #FilteredTrade  
	FROM #tradeIds ids  
	INNER JOIN dbo.CoreTrade trade ON trade.CoreTradeId = ids.CoreTradeId          
	INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId 

     SELECT Distinct RefInstrumentId   
	 INTO #tmpInstruments   
	 FROM #FilteredTrade  
  
  
	 SELECT ins.RefInstrumentId,  
	   ins.RefInstrumentTypeId,  
	 ISNULL(ins.StrikePrice,0) AS StrikePrice,    
	 ISNULL(ins.PriceNumerator,1) AS PriceNumerator,  
	 ISNULL(ins.ContractSize, 1) AS ContractSize,  
	 ISNULL(ins.PriceDenominator, 1) AS PriceDenominator,  
	 ISNULL(ins.GeneralNumerator, 1) AS GeneralNumerator,   
	 ISNULL(ins.GeneralDenominator, 1) AS GeneralDenominator,  
	 ISNULL(ins.MarketLot, 1) AS MarketLot,   
	 COALESCE(instType.[Name],'') AS InstrumentType,  
	 ins.Code,  
	 COALESCE(ins.ScripId,'') AS ScripId,  
	 COALESCE(CONVERT(VARCHAR,ins.ExpiryDate,106),'') AS ExpiryDate,  
	 COALESCE(ins.PutCall,'') AS PutCall  
	 INTO #instruments  
	 FROM #tmpInstruments tmpInst  
	 INNER JOIN dbo.RefInstrument ins ON ins.RefInstrumentId=tmpInst.RefInstrumentId  
	 INNER JOIN #instrumentType instType ON ins.RefInstrumentTypeId = instType.RefInstrumentTypeId   
  
  
SELECT trade.RefClientId,    
    trade.RefInstrumentId,        
    SUM(CASE WHEN trade.BuySell = 1 THEN     
      (    
       CASE     
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO    
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2)   
        
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO    
         THEN  ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)      
    
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTCUR)    
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator) * inst.ContractSize,2)         
         
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@FUTCUR)    
         THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)         
    
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)     
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator/inst.GeneralDenominator),2)    
         
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)     
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)    
         
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT) AND segment.RefSegmentEnumId = @MCX_FNO    
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity * inst.ContractSize    
    
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@FUTCOM) AND segment.RefSegmentEnumId = @MCX_FNO    
         THEN  trade.Rate * trade.Quantity * inst.ContractSize    
         
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT)    
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity    
        ELSE     
         trade.Rate * trade.Quantity     
        END     
        )     
        ELSE 0 END) AS BuyTurnover,    
    SUM(CASE WHEN trade.BuySell = 0 THEN    
      (    
       CASE     
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO    
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2)  
        
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO    
         THEN  ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)        
    
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTCUR)    
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator) * inst.ContractSize,2)         
         
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@FUTCUR)    
         THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)        
    
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)     
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator/inst.GeneralDenominator),2)   
         
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)     
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)   
         
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT) AND segment.RefSegmentEnumId = @MCX_FNO    
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity * inst.ContractSize    
    
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@FUTCOM) AND segment.RefSegmentEnumId = @MCX_FNO    
         THEN  trade.Rate * trade.Quantity * inst.ContractSize    
         
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT)    
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity    
        ELSE     
         trade.Rate * trade.Quantity     
        END     
      )    
     ELSE 0 END) AS SellTurnover  
  INTO #CliInstrumentWiseTurnover    
  FROM #FinalDateWiseTuruover fc    
    INNER JOIN #FilteredTrade trade ON fc.RefClientId = trade.RefClientId  
    INNER JOIN #instruments inst ON trade.RefInstrumentId = inst.RefInstrumentId         
    INNER JOIN dbo.RefSegmentEnum segment ON trade.RefSegmentId = segment.RefSegmentEnumId    
  GROUP BY trade.RefClientId, trade.RefInstrumentId    
      
   
 SELECT DISTINCT st.OppClientId   
 INTO #OppClients    
 FROM #FinalDateWiseTuruover fc    
 INNER JOIN #SyncTradesTemp st ON fc.RefClientId = st.RefClientId    
  
  
  --SELECT   
  --trade.RefClientId,  
  --trade.RefInstrumentId,  
  --trade.IsBuy,  
  --trade.Rate,  
  --trade.Quantity,  
  --trade.RefSegmentId  
  --INTO #OppClientTrade  
  --FROM #OppClients oppCl    
  --INNER JOIN #reqTrades trade ON oppCl.OppClientId = trade.RefClientId   
   
    
  SELECT trade.RefClientId,    
    trade.RefInstrumentId,    
    SUM(CASE WHEN trade.BuySell = 1 THEN     
      (    
       CASE     
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND trade.RefSegmentId = @NCDEX_FNO    
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2)    
        
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND trade.RefSegmentId = @NCDEX_FNO    
         THEN ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)         
    
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTCUR)    
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator) * inst.ContractSize,2)         
         
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@FUTCUR)    
         THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)         
    
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)     
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator/inst.GeneralDenominator),2)   
         
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)     
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)    
         
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT) AND trade.RefSegmentId = @MCX_FNO    
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity * inst.ContractSize    
    
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@FUTCOM) AND trade.RefSegmentId = @MCX_FNO    
         THEN  trade.Rate * trade.Quantity * inst.ContractSize    
         
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT)    
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity    
        ELSE     
         trade.Rate * trade.Quantity     
        END     
      )     
     ELSE 0 END) AS BuyTurnover,         
    SUM(CASE WHEN trade.BuySell = 0 THEN     
      (    
       CASE     
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND trade.RefSegmentId = @NCDEX_FNO    
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2)   
        
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND trade.RefSegmentId = @NCDEX_FNO    
         THEN  ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)         
    
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTCUR)    
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator) * inst.ContractSize,2)         
         
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@FUTCUR)    
         THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)        
    
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)     
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator/inst.GeneralDenominator),2)    
         
        WHEN @VerticalInternalId = 1 AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)     
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)     
         
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT) AND trade.RefSegmentId = @MCX_FNO    
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity * inst.ContractSize    
    
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@FUTCOM) AND trade.RefSegmentId = @MCX_FNO    
         THEN  trade.Rate * trade.Quantity * inst.ContractSize    
         
        WHEN @VerticalInternalId = 0 AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT)    
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity    
        ELSE     
         trade.Rate * trade.Quantity     
        END     
      )     
     ELSE 0 END) AS SellTurnover    
  INTO #OppCliInstrumentWiseTurnover    
  FROM #OppClients FinalOppClients    
    INNER JOIN #FilteredTrade trade ON FinalOppClients.OppClientId = trade.RefClientId  
    INNER JOIN #instruments inst ON trade.RefInstrumentId = inst.RefInstrumentId        
   -- INNER JOIN dbo.RefSegmentEnum segment ON segment.RefSegmentEnumId = trade.RefSegmentId    
  GROUP BY trade.RefClientId, trade.RefInstrumentId    
      
   SELECT client.RefClientId,  
  client.ClientId,  
  client.[Name]  
  INTO #finalClientDet  
  FROM #tradeClients tmpcl  
  INNER JOIN dbo.RefClient client ON tmpcl.RefClientId = client.RefClientId    
    
    
  IF OBJECT_ID('tempdb..#SynchronizedTrades') IS NULL   
  BEGIN   
     
 CREATE TABLE #SynchronizedTrades    
  (    
   RefclientId INT,    
   TradeDate DATETIME,    
   TradeDateTime DATETIME,    
   TradeId INT,
   AlphaNumericTradeId VARCHAR(100) COLLATE DATABASE_DEFAULT, 
   IsBuy BIT,  
   Rate DECIMAL(28,2),    
   Quantity DECIMAL(28,2),     
   SyncTurnover DECIMAL(28,2),    
   DateWiseSyncTurnover DECIMAL(28,2),    
   ClientSyncTurnover DECIMAL(28,2),    
   OppRefClientId INT,    
   OppIsBuy BIT,  
   ClientBuyTurnover DECIMAL(28,2),    
   ClientSellTurnover DECIMAL(28,2),    
   OppClientBuyTurnover DECIMAL(28,2),    
   OppClientSellTurnover DECIMAL(28,2),    
   BuyCtslId VARCHAR(300) COLLATE DATABASE_DEFAULT,    
   SellCtslId VARCHAR(300) COLLATE DATABASE_DEFAULT,    
   BuyTerminal VARCHAR(200) COLLATE DATABASE_DEFAULT,    
   SellTerminal VARCHAR(200) COLLATE DATABASE_DEFAULT,    
   RefSegmentId INT,  
   BuyOrdTime DATETIME,    
   SellOrdTime DATETIME,    
   RefInstrumentId INT,     
   IsAlgoTrade BIT,  
   RefInstrumentTypeId INT    
 )    
    
  END   
    INSERT INTO #SynchronizedTrades  
 (  
  RefclientId ,   
   TradeDate ,    
   TradeDateTime ,    
   TradeId ,
   AlphaNumericTradeId,    
   IsBuy ,  
   Rate ,  
   Quantity ,   
   SyncTurnover ,  
   DateWiseSyncTurnover ,  
   ClientSyncTurnover ,  
   OppRefClientId ,    
   OppIsBuy ,  
   ClientBuyTurnover ,  
   ClientSellTurnover ,  
   OppClientBuyTurnover ,  
   OppClientSellTurnover ,  
   BuyCtslId ,   
   SellCtslId ,   
   BuyTerminal ,  
   SellTerminal ,  
   RefSegmentId ,  
   BuyOrdTime ,    
   SellOrdTime ,    
   RefInstrumentId ,     
   IsAlgoTrade ,  
   RefInstrumentTypeId     
 )  
  
 SELECT   
  fc.RefclientId ,     
   st.TradeDate ,    
   st.TradeDateTime ,    
   CASE WHEN st.RefSegmentId = @NCDEX_FNO THEN 0
		ELSE st.TradeId END
	AS TradeId,
	CASE WHEN st.RefSegmentId <> @NCDEX_FNO THEN ''
		ELSE st.TradeId END
	AS AlphaNumericTradeId,   
   st.BuySell as IsBuy ,  
   st.Rate ,  
   st.Quantity ,   
   st.SyncTurnover ,  
   stdw.DateWiseSyncTurnover ,  
   fc.ClientSyncTurnover ,  
   st.OppClientId ,    
   st.OppBuySell as OppIsBuy ,  
  CONVERT(DECIMAL(28,2),cliInstWiseTurnover.BuyTurnover),    
  CONVERT(DECIMAL(28,2),cliInstWiseTurnover.SellTurnover),    
  CONVERT(DECIMAL(28,2),oppCliInstWiseTurnover.BuyTurnover) ,    
  CONVERT(DECIMAL(28,2),oppCliInstWiseTurnover.SellTurnover),    
   st.BuyCtslId,    
  st.SellCtslId,    
   BuyTerminal ,  
   SellTerminal ,  
   RefSegmentId ,  
   st.BuyOrdTime ,    
   st.SellOrdTime ,    
   st.RefInstrumentId ,     
   st.IsAlgoTrade ,  
   inst.RefInstrumentTypeId   
 FROM #FinalDateWiseTuruover fc  
 INNER JOIN #SyncTradesTemp st ON fc.RefClientId = st.RefClientId AND fc.RefInstrumentTypeId = st.RefInstrumentTypeId  
 INNER JOIN #SyncTurnoverDateWise stdw ON fc.RefClientId = stdw.RefClientId AND fc.RefInstrumentTypeId = stdw.RefInstrumentTypeId  AND stdw.TradeDate = st.TradeDate     
 INNER JOIN #CliInstrumentWiseTurnover cliInstWiseTurnover ON st.RefClientId = cliInstWiseTurnover.RefClientId    
                     AND st.RefInstrumentId = cliInstWiseTurnover.RefInstrumentId    
     INNER JOIN #OppCliInstrumentWiseTurnover oppCliInstWiseTurnover ON st.OppClientId = oppCliInstWiseTurnover.RefClientId    
                     AND st.RefInstrumentId = oppCliInstWiseTurnover.RefInstrumentId  
 INNER JOIN #instruments inst ON st.RefInstrumentId = inst.RefInstrumentId    
  
 if(@ApplyScenarioRuleInternal= 1)  
 BEGIN  
    
    SELECT *     
    FROM(    
     SELECT   
   syncTrnovr.RefClientId,    
    clientDet.ClientId,    
    clientDet.[Name] AS ClientName,    
    inst.Code AS ScripCode,    
    inst.InstrumentType,    
    (inst.ScripId +' - '+ inst.InstrumentType +' - '+ inst.ExpiryDate +' - '+ inst.PutCall +' - '+ COALESCE(CONVERT(VARCHAR,CONVERT (DECIMAL(19,2),inst.StrikePrice)),'')) AS ScripTypeExpDtPutCallStrikePrice,    
    syncTrnovr.TradeDate,    
    syncTrnovr.TradeDateTime,
	syncTrnovr.TradeId,
	syncTrnovr.AlphaNumericTradeId,
    CASE WHEN syncTrnovr.IsBuy  = 1THEN 'Buy' ELSE 'Sell' END AS BuySell,    
    syncTrnovr.Rate,    
    syncTrnovr.Quantity,    
    syncTrnovr.SyncTurnover,    
    syncTrnovr.DateWiseSyncTurnover,    
    syncTrnovr.ClientSyncTurnover,    
    oppClient.RefClientId AS OppRefClientId,    
    oppClientDet.ClientId AS OppClientId,    
    oppClientDet.[Name] AS OppClientName,    
    CASE WHEN syncTrnovr.OppIsBuy  = 1 THEN 'Buy' ELSE 'Sell' END AS OppBuySell,    
    syncTrnovr.ClientBuyTurnover,    
    syncTrnovr.ClientSellTurnover,    
    syncTrnovr.OppClientBuyTurnover,    
    syncTrnovr.OppClientSellTurnover,    
    syncTrnovr.BuyCtslId,    
    syncTrnovr.SellCtslId,    
    syncTrnovr.BuyTerminal,    
    syncTrnovr.SellTerminal,    
    seg.Segment,    
    syncTrnovr.BuyOrdTime,    
    syncTrnovr.SellOrdTime,    
    bhavCopy.NetTurnOver AS ExchangeTurnover,    
    bhavCopy.high AS DayHigh,    
    bhavCopy.Low AS DayLow,    
    inst.RefInstrumentId,    
    rf.IntermediaryCode,    
    rf.[Name] AS IntermediaryName,    
     case when syncTrnovr.IsAlgoTrade =1 then 'YES' else 'NO' end as AlgoTrade  ,  
    inst.RefInstrumentTypeId,      
    ABS((DATEPART(SECOND, ISNULL(syncTrnovr.BuyOrdTime,GETDATE())) + 60 * DATEPART(MINUTE,ISNULL(syncTrnovr.BuyOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(syncTrnovr.BuyOrdTime,getdate())))-(DATEPART(SECOND, isnull(syncTrnovr.SellOrdTime,getdate()))
	+60 * DATEPART(MINUTE, isnull( syncTrnovr.SellOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(syncTrnovr.SellOrdTime,getdate())))) as DifferenceInSeconds,    
    rf.TradeName    
     FROM #SynchronizedTrades syncTrnovr    
    INNER JOIN #FilteredClient client ON syncTrnovr.RefClientId = client.RefClientId  
    INNER JOIN #finalClientDet clientDet ON clientDet.RefClientId=syncTrnovr.RefClientId    
    INNER JOIN #FilteredOppositeClient oppClient ON syncTrnovr.OppRefClientId = oppClient.RefClientId    
     INNER JOIN #finalClientDet oppClientDet ON oppClientDet.RefClientId=oppClient.RefClientId  
    INNER JOIN #instruments inst ON syncTrnovr.RefInstrumentId = inst.RefInstrumentId        
    INNER JOIN dbo.RefSegmentEnum seg ON syncTrnovr.RefSegmentId = seg.RefSegmentEnumId    
    LEFT JOIN dbo.CoreBhavCopy bhavCopy ON syncTrnovr.RefSegmentId = bhavCopy.RefSegmentId AND syncTrnovr.TradeDate = bhavCopy.Date AND syncTrnovr.RefInstrumentId = bhavCopy.RefInstrumentId    
    LEFT JOIN dbo.RefIntermediary rf on client.RefIntermediaryId = rf.RefIntermediaryId     
   )as temp    
   where   
    EXISTS(   
     select 1      
     from dbo.RefAmlScenarioRule rules     
     Inner join dbo.LinkRefAmlScenarioRuleRefInstrumentType linkInstType on linkInstType.RefAmlScenarioRuleId = rules.RefAmlScenarioRuleId     
     AND linkInstType.RefInstrumentTypeId= temp.RefInstrumentTypeId    
     where rules.RefAmlReportId=@ReportIdInternal    
     AND ((rules.Threshold2 is null)    
     OR (CONVERT(INT,rules.Threshold2)<>0 and CONVERT(INT,rules.Threshold2)>=temp.DifferenceInSeconds) OR CONVERT(INT,rules.Threshold2)=0)    
    )    
   --)    
 END  
  
    
----ANY CHANGES MADE THIS SELECT SHOULD ALSO CHANGED IN dbo.CoreSyncTradeSegregation_GetReversalSynchronizedFnOTradeForScenarios    
END   
GO
GO
  EXEC dbo.Sys_DropIfExists @ObjectName='Aml_GetReversalSynchronizedFnOTradeForScenarios',@XType='P'
GO
  GO
 CREATE PROCEDURE [dbo].[Aml_GetReversalSynchronizedFnOTradeForScenarios]  
 (  
  @ReportId INT,  
  @FromDate DATETIME,  
  @ToDate DATETIME,  
  @ExcludePro BIT,  
  @ExcludeInstitution BIT,  
  @ExcludeOppositePro BIT,  
  @ExcludeOppositeInstitution BIT,  
  @ExcludealgoTrade BIT,  
  @Vertical VARCHAR(20)  
 )  
AS  
 BEGIN  
  
  DECLARE @ReportIdInternal INT  
  DECLARE @FromDateInternal DATETIME  
  DECLARE @ToDateInternal DATETIME  
  DECLARE @ExcludeProInternal BIT  
  DECLARE @ExcludeInstitutionInternal BIT    
  DECLARE @ExcludeOppositeProInternal BIT  
  DECLARE @ExcludeOppositeInstitutionInternal BIT  
  DECLARE @ExcludealgoTradeInternal BIT  
  DECLARE @VerticalInternal VARCHAR(20)
  DECLARE @FromDateWithoutTime DATETIME, @ToDateWithoutTime DATETIME
  DECLARE @OPTCUR INT,
  @FUTCUR INT,
  @OPTSTK INT, 
  @OPTIDX INT,
  @OPTIRC INT,
  @OPTFUT INT,
  @FUTCOM INT,
 @S118 INT,@S119 INT,@S113 INT

 SELECT @S113=RefAmlReportId FROM dbo.RefAmlReport WHERE Code='S113'
 SELECT @S118=RefAmlReportId FROM dbo.RefAmlReport WHERE Code='S118'
 SELECT @S119=RefAmlReportId FROM dbo.RefAmlReport WHERE Code='S119'

   SELECT RefInstrumentTypeId,InstrumentType 
	INTO #instrumentType
	FROM dbo.RefInstrumentType 

  SELECT @OPTCUR=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='OPTCUR'
  SELECT @FUTCUR=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='FUTCUR'
  SELECT @OPTSTK=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='OPTSTK'
  SELECT @OPTIDX=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='OPTIDX'
  SELECT @OPTIRC=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='OPTIRC'
  SELECT @OPTFUT=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='OPTFUT'
  SELECT @FUTCOM=RefInstrumentTypeId FROM #instrumentType WHERE InstrumentType='FUTCOM'
  
  SET @ReportIdInternal = @ReportId  
        SET @FromDateInternal =  @FromDate  
        SET @ToDateInternal = @ToDate 
		SET @FromDateWithoutTime =  dbo.GetDateWithoutTime(@FromDate)  
        SET @ToDateWithoutTime = dbo.GetDateWithoutTime(@ToDate)   
        SET @ExcludeProInternal = @ExcludePro  
        SET @ExcludeInstitutionInternal = @ExcludeInstitution          
        SET @ExcludeOppositeProInternal = @ExcludeOppositePro  
        SET @ExcludeOppositeInstitutionInternal = @ExcludeOppositeInstitution  
  SET @ExcludealgoTradeInternal=@ExcludealgoTrade  
  SET @VerticalInternal = @Vertical   
  
   CREATE TABLE #SynchronizedTrades  
		(  
		 RefclientId INT,  
		-- ScripTypeExpDtPutCallStrikePrice VARCHAR(200) COLLATE DATABASE_DEFAULT,  
		 TradeDate DATETIME,  
		 TradeDateTime DATETIME,  
		 TradeId INT,  
		 IsBuy BIT,
		 Rate DECIMAL(28,2),  
		 Quantity DECIMAL(28,2),   
		 SyncTurnover DECIMAL(28,2),  
		 DateWiseSyncTurnover DECIMAL(28,2),  
		 ClientSyncTurnover DECIMAL(28,2),  
		 OppRefClientId INT,  
		 OppIsBuy BIT,
		 ClientBuyTurnover DECIMAL(28,2),  
		 ClientSellTurnover DECIMAL(28,2),  
		 OppClientBuyTurnover DECIMAL(28,2),  
		 OppClientSellTurnover DECIMAL(28,2),  
		 BuyCtslId VARCHAR(300) COLLATE DATABASE_DEFAULT,  
		 SellCtslId VARCHAR(300) COLLATE DATABASE_DEFAULT,  
		 BuyTerminal VARCHAR(200) COLLATE DATABASE_DEFAULT,  
		 SellTerminal VARCHAR(200) COLLATE DATABASE_DEFAULT,  
		 RefSegmentId INT,
		 BuyOrdTime DATETIME,  
		 SellOrdTime DATETIME,  
		 RefInstrumentId INT,   
		 IsAlgoTrade BIT,
		 RefInstrumentTypeId INT  
	)  
----------------------------  
EXEC dbo.Aml_GetSynchronizedFnOTradeForScenarios @ReportId,@FromDateInternal,@ToDateInternal,@ExcludeProInternal,@ExcludeInstitutionInternal  
,@ExcludeOppositeProInternal,@ExcludeOppositeInstitutionInternal,@ExcludealgoTradeInternal,@VerticalInternal,0  
  
  
----------------------------  
SELECT *  INTO #reversalTrades FROM #SynchronizedTrades WHERE TradeDate = @ToDateInternal  
  
---------------------------  
SELECT   
 sync.RefclientId,   
 sync.IsBuy,  
 sync.Rate,  
 sync.Quantity,  
 sync.SyncTurnover,  
 sync.OppRefClientId AS OppRefClientId,  
 sync.OppIsBuy AS OppIsBuy,  
 sync.TradeId,  
 sync.TradeDate,  
 sync.TradeDateTime,  
 sync.RefInstrumentId,  
 sync.RefInstrumentTypeId,  
 sync.RefSegmentId,  
 reversal.RefclientId AS OppTrdRefClientId,  
 reversal.IsBuy AS OppTrdIsBuy,  
 reversal.Rate AS OppTrdRate,  
 reversal.Quantity AS OppTrdQuantity,  
 reversal.SyncTurnover AS OppTrdSyncTurnover,  
 reversal.OppRefClientId AS OppTrdOppRefClientId,  
 reversal.OppIsBuy AS oppTrdOppIsBuy,  
 reversal.TradeId AS OppTrdTradeId,  
 reversal.TradeDate AS OppTrdTradeDate,  
 reversal.TradeDateTime AS OppTrdTradeDateTime,  
 reversal.RefInstrumentId AS OppTrdRefInstrumentId,  
 reversal.RefInstrumentTypeId AS OppTrdInstrumentTypeId,  
 reversal.RefSegmentId AS OppTrdSegmentId,  
 ROW_NUMBER() OVER(PARTITION BY reversal.RefclientId, reversal.TradeId, reversal.TradeDate, reversal.RefInstrumentId, reversal.RefSegmentId ORDER BY sync.TradeDateTime DESC) AS RowNumber  
  
INTO   
 #tempReversal   
FROM   
 #reversalTrades reversal   
 INNER JOIN  #SynchronizedTrades sync ON sync.RefclientId = reversal.OppRefClientId  
          AND sync.OppRefClientId = reversal.RefclientId  
          AND sync.IsBuy = reversal.IsBuy  
          AND sync.RefInstrumentId = reversal.RefInstrumentId  
          AND sync.RefSegmentId = reversal.RefSegmentId  
WHERE   
 sync.TradeDateTime < reversal.TradeDateTime  
  
-----------------------------  
SELECT   
 reversal.*,  
 (SELECT SUM(Quantity) FROM #tempReversal temp WHERE temp.RefclientId = reversal.RefclientId  
             AND temp.OppTrdSegmentId = reversal.OppTrdSegmentId  
             AND temp.RefInstrumentId = reversal.RefInstrumentId  
             AND temp.OppTrdTradeDateTime = reversal.OppTrdTradeDateTime  
             AND temp.OppTrdTradeId = reversal.OppTrdTradeId  
             AND temp.RowNumber <= reversal.RowNumber  
 ) AS CumulativeQuantity,  
 (SELECT AVG(Rate) FROM #tempReversal temp WHERE temp.RefclientId = reversal.RefclientId   
             AND temp.OppTrdSegmentId = reversal.OppTrdSegmentId  
             AND temp.RefInstrumentId = reversal.RefInstrumentId  
             AND temp.OppTrdTradeDateTime = reversal.OppTrdTradeDateTime  
             AND temp.OppTrdTradeId = reversal.OppTrdTradeId  
             AND temp.RowNumber <= reversal.RowNumber  
 ) AS CumulativeAverageRate  
  
INTO  
  #tempConsolidatedpReversal  
FROM  
 #tempReversal reversal  
  
-------------------------------  
  
SELECT   
 temp2.*   
INTO   
 #finalConsolidatedReversal  
FROM  
 (  
  SELECT   
   temp1.*,  
   ROW_NUMBER() OVER(PARTITION BY OppTrdRefClientId, OppTrdTradeId, OppTrdTradeDate, OppTrdRefInstrumentId,OppTrdSegmentId ORDER BY TradeDateTime DESC) AS NewRowNumber  
  FROM   
   (  
    SELECT * FROM #tempConsolidatedpReversal WHERE (Quantity - CumulativeQuantity) <= 0  
   ) AS temp1  
 ) AS temp2   
WHERE   
 temp2.NewRowNumber = 1  
  
--------------------------------  
--exclude scenario
	SELECT DISTINCT    
	  RefClientId    
	  INTO #clientsToExclude
	  FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex    
	  WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)     
	  AND @ToDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @ToDateInternal) 

  
SELECT  
 f.OppTrdRefClientId AS ReversalRefClientId,  
 client.ClientId AS ReversalClientId,  
 client.Name AS ReversalClientName,  
	(CASE WHEN OppTrdRate > Rate  THEN OppTrdRate
	WHEN Rate > CumulativeAverageRate THEN Rate 
	ELSE CumulativeAverageRate END) AS ReversalRate,
	(CASE WHEN OppTrdQuantity< Quantity  THEN OppTrdQuantity
	WHEN Quantity < CumulativeQuantity THEN Quantity
	 ELSE CumulativeQuantity END) AS ReversalQuantity,  
 CASE WHEN f.OppTrdIsBuy = 1 THEN 'Buy' ELSE 'Sell' END AS ReversalBuySell,  
 OppInst.Code  AS ReversalScripCode,  
 f.OppTrdRefInstrumentId AS ReversalRefInstrumentId,  
 instType.InstrumentType AS ReversalInstrumentType,  
 f.OppTrdOppRefClientId AS ReversalOppRefClientId,  
 OppClient.ClientId AS ReversalOppClientId,  
 OppClient.Name AS ReversalOppClientName,  
 f.OppTrdTradeDate AS ReversalTradeDate,  
 f.OppTrdTradeId AS ReversalTradeId,  
 f.OppTrdSegmentId,  
 (COALESCE(OppInst.ScripId,'') +' - '+ COALESCE(instType.InstrumentType,'')  +' - '+ COALESCE(CONVERT(VARCHAR,OppInst.ExpiryDate,106),'') +' - '+ COALESCE(OppInst.PutCall,'') +' - '+ COALESCE(CONVERT(VARCHAR,CONVERT (DECIMAL(19,2),OppInst.StrikePrice)),'')) AS ReversalScripTypeExpDtPutCallStrikePrice,  
 STUFF(( SELECT ', ' + (CONVERT(VARCHAR(200),t.TradeId) + '-' + CONVERT(VARCHAR(200),t.TradeDate, 111))  
     FROM #tempReversal t  
     WHERE t.RefclientId = f.RefclientId  
         AND t.OppTrdTradeId = f.OppTrdTradeId   
      AND t.OppTrdTradeDate = f.OppTrdTradeDate  
      AND t.OppTrdRefInstrumentId = f.OppTrdRefInstrumentId
      AND t.OppTrdSegmentId = f.OppTrdSegmentId  
      AND t.RowNumber <= f.RowNumber  
    FOR  
    XML PATH('')  
    ), 1, 1, '') AS SyncTrades  
  
 INTO #finalReversal  
 FROM #finalConsolidatedReversal f
 INNER JOIN dbo.RefClient client ON client.RefClientId = f.OppTrdRefClientId
 INNER JOIN dbo.RefClient OppClient ON OppClient.RefClientId = f.OppTrdOppRefClientId 
 LEFT JOIN dbo.RefInstrument OppInst ON OppInst.RefInstrumentId = OppTrdRefInstrumentId
 LEFT JOIN dbo.RefInstrumentType instType ON instType.RefInstrumentTypeId =  f.OppTrdInstrumentTypeId 
 LEFT JOIN #clientsToExclude ex ON ex.RefClientId = client.RefClientId 
	 WHERE   ex.RefClientId IS NULL 

  SELECT DISTINCT ReversalRefInstrumentId
  INTO #distinctInstruments
  FROM #FinalReversal


  SELECT ins.RefInstrumentId,
	  ins.RefInstrumentTypeId,
	  instType.InstrumentType AS InstrumentType,
	ISNULL(ins.StrikePrice,0) AS StrikePrice, 
	ISNULL(ins.PriceNumerator,1) AS PriceNumerator,
	ISNULL(ins.ContractSize, 1) AS ContractSize,
	ISNULL(ins.PriceDenominator, 1) AS PriceDenominator,
	ISNULL(ins.GeneralNumerator, 1) AS GeneralNumerator, 
	ISNULL(ins.GeneralDenominator, 1) AS GeneralDenominator,
	ISNULL(ins.MarketLot, 1) AS MarketLot 
	INTO #instrumentDet
	FROM #distinctInstruments tmpInst
	INNER JOIN dbo.RefInstrument ins ON ins.RefInstrumentId=tmpInst.ReversalRefInstrumentId
	INNER JOIN #instrumentType instType ON ins.RefInstrumentTypeId = instType.RefInstrumentTypeId   
   

  
    SELECT   
  ReversalRefClientId AS RefclientId,  
  ReversalClientId AS ClientId,  
     ReversalClientName AS ClientName,  
  ReversalScripCode AS ScripCode,  
  temp.ReversalRefInstrumentId AS RefInstrumentId,  
  temp.ReversalInstrumentType AS InstrumentType,  
  ReversalScripTypeExpDtPutCallStrikePrice AS ScripTypeExpDtPutCallStrikePrice,  
  ReversalBuySell AS BuySell,  
     ReversalOppRefClientId AS OppRefClientId,  
        ReversalOppClientId as OppClientId,  
        ReversalOppClientName AS OppClientName,  
	@FromDateWithoutTime AS FromDate,  
     @ToDateWithoutTime AS ToDate,  
        ReversalQuantity as ReversalQty,  
     ReversalRate AS ReversalRate,  
   (  
   CASE  
    WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR)  AND @ReportIdInternal NOT IN(@S113,@S118,@S119) 
    THEN CONVERT(DECIMAL(28,2),ROUND((temp.ReversalRate + inst.StrikePrice) * (inst.PriceNumerator /inst.PriceDenominator * temp.ReversalQuantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator) * inst.ContractSize,2))       
       
  WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCUR,@OPTCUR)  
    THEN CONVERT(DECIMAL(28,2),ROUND(temp.ReversalRate * temp.ReversalQuantity * inst.ContractSize,2))       
  
  WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)    AND @ReportIdInternal NOT IN(@S113,@S118,@S119) 
    THEN CONVERT(DECIMAL(28,2),ROUND((temp.ReversalRate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * temp.ReversalQuantity) * inst.MarketLot * (inst.GeneralNumerator/inst.GeneralDenominator),2))  
       
  WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
    THEN  CONVERT(DECIMAL(28,2),ROUND(temp.ReversalRate * (inst.PriceNumerator /inst.PriceDenominator * temp.ReversalQuantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2))   
       
  WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR)   
    THEN (inst.StrikePrice + temp.ReversalRate) * temp.ReversalQuantity  
  ELSE   
   temp.ReversalRate * temp.ReversalQuantity     
  END       
   ) AS ReversalSyncTO,  
   ReversalTradeId,  
   ReversalTradeDate,   
   SyncTrades  
  
   FROM #FinalReversal temp  
   INNER JOIN #instrumentDet inst ON inst.RefInstrumentId = temp.ReversalRefInstrumentId                  
   WHERE EXISTS(  
  select 1    
  FROM dbo.RefAmlScenarioRule rules   
  INNER JOIN LinkRefAmlScenarioRuleRefInstrumentType linkInstType on linkInstType.RefAmlScenarioRuleId = rules.RefAmlScenarioRuleId   
  AND linkInstType.RefInstrumentTypeId= inst.RefInstrumentTypeId  
  WHERE rules.RefAmlReportId=@ReportIdInternal  
  AND (ReversalQuantity * ReversalRate) >= rules.Threshold  
 )  
--ANY CHANGES MADE THIS SELECT SHOULD ALSO CHANGED IN dbo.Aml_GetSynchronizedFnOTradeForScenarios  
  
END  
GO
GO
 ALTER PROCEDURE [dbo].[Aml_GetSynchronizedFnOTradeForScenarios]  
 (  
  @ReportId INT,  
  @FromDate DATETIME,  
  @ToDate DATETIME,  
  @ExcludePro BIT,  
  @ExcludeInstitution BIT,  
  @ExcludeOppositePro BIT,  
  @ExcludeOppositeInstitution BIT,  
  @ExcludealgoTrade BIT,  
  @Vertical VARCHAR(20),  
  @ApplyScenarioRule BIT = 1  
 )  
AS  
 BEGIN  
  
  DECLARE @ReportIdInternal INT  
  DECLARE @FromDateInternal DATETIME  
  DECLARE @ToDateInternal DATETIME,  
   @ToDateWithoutTime DATETIME  
  DECLARE @ExcludeProInternal BIT  
  DECLARE @ExcludeInstitutionInternal BIT    
  DECLARE @ExcludeOppositeProInternal BIT  
  DECLARE @ExcludeOppositeInstitutionInternal BIT  
  DECLARE @ExcludealgoTradeInternal BIT,  
    @ApplyScenarioRuleInternal BIT  
  DECLARE @VerticalInternal VARCHAR(20)  
      
        SET @ReportIdInternal = @ReportId  
        SET @FromDateInternal = @FromDate  
        SET @ToDateInternal = @ToDate  
  SET @ToDateWithoutTime = dbo.GetDateWithoutTime(@ToDate)  
        SET @ExcludeProInternal = @ExcludePro  
        SET @ExcludeInstitutionInternal = @ExcludeInstitution          
        SET @ExcludeOppositeProInternal = @ExcludeOppositePro  
        SET @ExcludeOppositeInstitutionInternal = @ExcludeOppositeInstitution  
  SET @ExcludealgoTradeInternal=@ExcludealgoTrade  
  SET @VerticalInternal = @Vertical  
  SET @ApplyScenarioRuleInternal = @ApplyScenarioRule  

  DECLARE @OPTCUR INT,
  @FUTCUR INT,
  @OPTSTK INT, 
  @OPTIDX INT,
  @OPTIRC INT,
  @OPTFUT INT,
  @FUTCOM INT,
  @ProRefClientStatusId INT,
  @InstitutionRefClientStatusId INT,
  @MCX_FNO INT,
  @NCDEX_FNO INT,
 @NSE_FNO INT,
 @NSE_CDX INT,
 @MCXSX_CDX INT,
 @S118 INT,@S119 INT,@S113 INT,@S43 INT, @S518 INT
 
 SELECT @S43=RefAmlReportId FROM dbo.RefAmlReport WHERE Code='S43'
 SELECT @S113=RefAmlReportId FROM dbo.RefAmlReport WHERE Code='S113'
 SELECT @S118=RefAmlReportId FROM dbo.RefAmlReport WHERE Code='S118'
 SELECT @S119=RefAmlReportId FROM dbo.RefAmlReport WHERE Code='S119'
 SELECT @S518=RefAmlReportId FROM dbo.RefAmlReport WHERE Code='S518'

  SELECT RefInstrumentTypeId,InstrumentType 
	INTO #instrumentTypes
	FROM dbo.RefInstrumentType 

  SELECT @OPTCUR=RefInstrumentTypeId FROM #instrumentTypes WHERE InstrumentType='OPTCUR'
  SELECT @FUTCUR=RefInstrumentTypeId FROM #instrumentTypes WHERE InstrumentType='FUTCUR'
  SELECT @OPTSTK=RefInstrumentTypeId FROM #instrumentTypes WHERE InstrumentType='OPTSTK'
  SELECT @OPTIDX=RefInstrumentTypeId FROM #instrumentTypes WHERE InstrumentType='OPTIDX'
  SELECT @OPTIRC=RefInstrumentTypeId FROM #instrumentTypes WHERE InstrumentType='OPTIRC'
  SELECT @OPTFUT=RefInstrumentTypeId FROM #instrumentTypes WHERE InstrumentType='OPTFUT'
  SELECT @FUTCOM=RefInstrumentTypeId FROM #instrumentTypes WHERE InstrumentType='FUTCOM'

  SET @InstitutionRefClientStatusId= dbo.GetClientStatusId('Institution')
  SET @ProRefClientStatusId=dbo.GetClientStatusId('Pro')

    SELECT RefSegmentEnumId, Code 
  INTO #Segments
  FROM dbo.RefSegmentEnum

  SELECT @MCX_FNO=RefSegmentEnumId FROM #Segments WHERE CODE='MCX_FNO'
  SELECT @NCDEX_FNO=RefSegmentEnumId FROM #Segments WHERE CODE='NCDEX_FNO'
  SELECT @NSE_FNO=RefSegmentEnumId FROM #Segments WHERE CODE='NSE_FNO'
  SELECT @NSE_CDX=RefSegmentEnumId FROM #Segments WHERE CODE='NSE_CDX'
  SELECT @MCXSX_CDX=RefSegmentEnumId FROM #Segments WHERE CODE='MCXSX_CDX'
  


  SELECT seg.RefSegmentEnumId,  
    seg.Segment  
  INTO #RequiredSegment 
  FROM dbo.RefSegmentEnum Seg
  WHERE (@VerticalInternal = 'NonCommodity' AND seg.RefSegmentEnumId IN (@NSE_FNO,@NSE_CDX,@MCXSX_CDX))  
         or  
       (@VerticalInternal = 'Commodity' AND seg.RefSegmentEnumId IN (@NCDEX_FNO, @MCX_FNO))  
	  
	  SELECT DISTINCT    
	  RefClientId    
	  INTO #clientsToExclude
	  FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex    
	  WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)     
	  AND @ToDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @ToDateInternal) 

   SELECT 
   CoreTradeId
   INTO #reqTradesIds
   FROM #Segments seg
   inner join dbo.CoreTrade tr ON tr.RefSegmentId=seg.RefSegmentEnumId
   LEFT JOIN #clientsToExclude ex ON ex.RefClientId = tr.RefClientId     
   where ex.RefClientId IS NULL AND TradeDate BETWEEN @FromDateInternal AND @ToDateInternal  

   SELECT distinct
   rid.CoreTradeId,
   RefClientId,  
   RefInstrumentId,  
   TradeDate,  
   TradeDateTime,  
   TradeId,  
   CASE WHEN BuySell = 'Buy' THEN 1  WHEN BuySell = 'Sell' THEN 0 ELSE 0 END AS IsBuy,   
   Rate,  
   Quantity,  
   CtclId,  
   RefSegmentId,      
   RefSettlementId,  
   TraderId,  
   OrderTimeStamp,
   TradeIdAlphaNumeric
   INTO #reqTrades
   FROM #reqTradesIds rid
   INNER JOIN dbo.CoreTrade tr ON tr.CoreTradeId=rid.CoreTradeId
    
  SELECT trade.CoreTradeId,  
    trade.RefClientId,  
    trade.RefInstrumentId,  
    trade.TradeDate,  
    trade.TradeDateTime,  
    trade.TradeId,  
    trade.IsBuy ,  
    trade.Rate,  
    trade.Quantity,  
    trade.CtclId,  
    trade.RefSegmentId,      
    trade.RefSettlementId,  
    trade.TraderId,  
    trade.OrderTimeStamp,  
    CASE WHEN SUBSTRING(CONVERT(varchar,trade.CtclId),13,1) IN ('0','2','4') then 1 else 0 end as IsAlgoTrade , 
    trade.TradeIdAlphaNumeric,  
	convert(varchar(50),trade.TraderId) AS UserId  
  INTO #FilteredTrade  
  FROM #reqTrades trade  
  INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId  
  where 
  (
  (@ExcludealgoTradeInternal=0)
	 OR
  (@ExcludealgoTradeInternal=1 AND (len(convert(varchar,trade.CtclId))=15 AND substring(convert(varchar,trade.CtclId),13,1) NOT IN ('0','2','4')))
  )  
  
  SELECT DISTINCT RefClientId
  INTO #distinctClient 
  FROM #FilteredTrade


  SELECT client.RefClientId,
  client.RefClientStatusId,
  client.RefIntermediaryId 
  INTO #clientDet
  FROM #distinctClient tmpcl
  INNER JOIN dbo.RefClient client ON tmpcl.RefClientId = client.RefClientId  


  SELECT DISTINCT RefClientId
  INTO #mainClient 
  FROM #FilteredTrade
  WHERE TradeDate =  @ToDateInternal 


  SELECT client.RefClientId,
  client.RefIntermediaryId  
  INTO #FilteredClient  
  FROM #mainClient tmpcl  
    INNER JOIN #clientDet client ON tmpcl.RefClientId = client.RefClientId  
               AND (@ExcludeProInternal = 0 OR client.RefClientStatusId != @ProRefClientStatusId)  
               AND (@ExcludeInstitutionInternal = 0 OR client.RefClientStatusId != @InstitutionRefClientStatusId)   

  

    
  SELECT client.RefClientId  
  INTO #FilteredOppositeClient  
  FROM #distinctClient tmpcl
  INNER JOIN #clientDet client ON tmpcl.RefClientId=client.RefClientId  
               AND (@ExcludeOppositeProInternal = 0 OR client.RefClientStatusId != @ProRefClientStatusId)  
               AND (@ExcludeOppositeInstitutionInternal = 0 OR client.RefClientStatusId != @InstitutionRefClientStatusId)  
    
	SELECT Distinct RefInstrumentId 
	INTO #tmpInstruments 
	FROM #reqTrades


	SELECT ins.RefInstrumentId,
	  ins.RefInstrumentTypeId,
	ISNULL(ins.StrikePrice,0) AS StrikePrice,  
	ISNULL(ins.PriceNumerator,1) AS PriceNumerator,
	ISNULL(ins.ContractSize, 1) AS ContractSize,
	ISNULL(ins.PriceDenominator, 1) AS PriceDenominator,
	ISNULL(ins.GeneralNumerator, 1) AS GeneralNumerator, 
	ISNULL(ins.GeneralDenominator, 1) AS GeneralDenominator,
	ISNULL(ins.MarketLot, 1) AS MarketLot, 
	COALESCE(instType.InstrumentType,'') AS InstrumentType,
	ins.Code,
	COALESCE(ins.ScripId,'') AS ScripId,
	COALESCE(CONVERT(VARCHAR,ins.ExpiryDate,106),'') AS ExpiryDate,
	COALESCE(ins.PutCall,'') AS PutCall
	INTO #instruments
	FROM #tmpInstruments tmpInst
	INNER JOIN dbo.RefInstrument ins ON ins.RefInstrumentId=tmpInst.RefInstrumentId
	INNER JOIN #instrumentTypes instType ON ins.RefInstrumentTypeId = instType.RefInstrumentTypeId   
   
   SELECT
   client.RefClientId,
   trade.RefSegmentId,
   trade.RefSettlementId,
   trade.RefInstrumentId,
    TradeIdAlphaNumeric,
	IsBuy,
	Quantity,
	Rate,
	TradeDateTime,
	TradeId,
	CoreTradeId,
	TradeDate,
	CtclId,
	OrderTimeStamp,
	IsAlgoTrade,
	TraderId,
	UserId
   into #mainTradeDetails
   FROM #FilteredClient client
    INNER JOIN #FilteredTrade trade ON client.RefClientId = trade.RefClientId  
	WHERE (  
     (@ApplyScenarioRuleInternal  = 0)   
     OR   
     (@ApplyScenarioRuleInternal = 1 AND  trade.TradeDate = @ToDateWithoutTime)  
    )    

	SELECT distinct
	 maintrade.CoreTradeId,  
    maintrade.RefClientId,  
    maintrade.RefInstrumentId,  
    inst.RefInstrumentTypeId,  
    maintrade.TradeDate,  
    maintrade.TradeDateTime,  
    maintrade.TradeId,  
    maintrade.IsBuy,  
    maintrade.Rate,  
    maintrade.Quantity,      
    CASE   
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND maintrade.RefSegmentId = @NCDEX_FNO  
      THEN ROUND((maintrade.Rate + inst.StrikePrice * (inst.PriceNumerator / inst.PriceDenominator * maintrade.Quantity) * inst.GeneralNumerator / inst.GeneralDenominator), 2)  
      
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND maintrade.RefSegmentId = @NCDEX_FNO  
      THEN  ROUND(maintrade.Rate * (inst.PriceNumerator / inst.PriceDenominator * maintrade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)      
  
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCUR,@OPTCUR)   AND @ReportIdInternal NOT IN(@S113,@S118,@S119,@S43)
      THEN ROUND((maintrade.Rate + inst.StrikePrice * (inst.PriceNumerator /inst.PriceDenominator * maintrade.Quantity) * inst.MarketLot * inst.GeneralNumerator / inst.GeneralDenominator) * inst.ContractSize,2)      
       
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR)  AND @ReportIdInternal  IN (@S43)
      THEN ROUND((maintrade.Rate + inst.StrikePrice)* (maintrade.Quantity * inst.ContractSize),2) 
	   
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCUR)  AND @ReportIdInternal  IN (@S43)
      THEN ROUND(maintrade.Rate * maintrade.Quantity * inst.ContractSize,2)          
  
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)  AND @ReportIdInternal NOT IN(@S113,@S118,@S119,@S43)
      THEN ROUND((maintrade.Rate + inst.StrikePrice * (inst.PriceNumerator / inst.PriceDenominator * maintrade.Quantity) * inst.MarketLot * inst.GeneralNumerator/inst.GeneralDenominator),2)
         
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)   AND @ReportIdInternal =@S43
      THEN (inst.StrikePrice + maintrade.Rate) * maintrade.Quantity    

     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
      THEN  ROUND(maintrade.Rate * (inst.PriceNumerator/inst.PriceDenominator * maintrade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)   
       
     WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT) AND maintrade.RefSegmentId = @MCX_FNO  
      THEN (inst.StrikePrice + maintrade.Rate) * maintrade.Quantity * inst.ContractSize  
  
     WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCOM) AND maintrade.RefSegmentId = @MCX_FNO  
      THEN  maintrade.Rate * maintrade.Quantity * inst.ContractSize  
       
     WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT)  
      THEN (inst.StrikePrice + maintrade.Rate) * maintrade.Quantity  
     ELSE   
      maintrade.Rate * maintrade.Quantity   
     END   
    AS SyncTurnover,      
    oppTrade.RefClientId AS OppClientId,  
    oppTrade.IsBuy AS OppIsBuy,  
    CASE WHEN maintrade.IsBuy = 1 THEN maintrade.CtclId ELSE oppTrade.CtclId END AS BuyCtslId,  
    CASE WHEN maintrade.IsBuy = 0 THEN maintrade.CtclId ELSE oppTrade.CtclId END AS SellCtslId,      
    CASE WHEN maintrade.IsBuy = 1 THEN ct.TerminalId ELSE oppCt.TerminalId END AS BuyTerminal,  
    CASE WHEN maintrade.IsBuy = 0 THEN ct.TerminalId ELSE oppCt.TerminalId END AS SellTerminal,      
    CASE WHEN maintrade.IsBuy = 1 THEN maintrade.OrderTimeStamp ELSE oppTrade.OrderTimeStamp END AS BuyOrdTime,  
    CASE WHEN maintrade.IsBuy = 0 THEN maintrade.OrderTimeStamp ELSE oppTrade.OrderTimeStamp END AS SellOrdTime,  
    maintrade.RefSegmentId,  
    maintrade.IsAlgoTrade
     INTO #SyncTradesTemp    
	FROM #mainTradeDetails maintrade
	INNER JOIN #FilteredTrade oppTrade ON maintrade.RefSegmentId = oppTrade.RefSegmentId  
                    AND maintrade.RefSettlementId = oppTrade.RefSettlementId  
                                             AND maintrade.RefInstrumentId = oppTrade.RefInstrumentId 
											 AND maintrade.Quantity = oppTrade.Quantity  
                AND maintrade.Rate = oppTrade.Rate  
                AND maintrade.TradeDateTime = oppTrade.TradeDateTime  
                AND maintrade.IsBuy <> oppTrade.IsBuy  
                AND maintrade.RefClientId <> oppTrade.RefClientId         
				AND((maintrade.RefSegmentId = @NCDEX_FNO AND maintrade.TradeIdAlphaNumeric<>'' AND  maintrade.TradeIdAlphaNumeric = oppTrade.TradeIdAlphaNumeric) OR (maintrade.TradeId = oppTrade.TradeId))         
	 INNER JOIN #instruments inst ON inst.RefInstrumentId = maintrade.RefInstrumentId  
	LEFT JOIN dbo.CoreTerminal ct ON ct.UserId=maintrade.UserId  
    LEFT JOIN dbo.CoreTerminal oppCt ON oppCt.UserId=oppTrade.UserId   

       
	
        SELECT st.RefClientId,  
    st.RefInstrumentTypeId,  
    st.TradeDate,st.RefInstrumentId ,      
    CONVERT(DECIMAL(28,2),SUM (st.SyncTurnover)) AS DateWiseSyncTurnover      
  INTO #SyncTurnoverDateWise  
        FROM #SyncTradesTemp st  
        GROUP BY st.RefClientId, st.RefInstrumentTypeId, st.TradeDate, st.RefInstrumentId  
          
          
        SELECT stdw.RefClientId,  
    stdw.RefInstrumentTypeId,  
    SUM(stdw.DateWiseSyncTurnover) AS ClientSyncTurnover ,stdw.RefInstrumentId           
        INTO #FinalClientId  
        FROM #SyncTurnoverDateWise stdw  
    INNER JOIN dbo.RefInstrumentType instrumentType ON instrumentType.RefInstrumentTypeId = stdw.RefInstrumentTypeId  
        GROUP BY stdw.RefClientId,stdw.RefInstrumentTypeId ,stdw.RefInstrumentId  
         HAVING (@ApplyScenarioRuleInternal = 0 ) OR ( @ApplyScenarioRuleInternal = 1 AND EXISTS   
    (  
     SELECT 1  
     FROM dbo.RefAmlScenarioRule scenarioRule  
     INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType linkInstrumentType ON scenarioRule.RefAmlScenarioRuleId = linkInstrumentType.RefAmlScenarioRuleId  
     WHERE scenarioRule.RefAmlReportId = @ReportIdInternal AND stdw.RefInstrumentTypeId = linkInstrumentType.RefInstrumentTypeId  
       AND SUM(stdw.DateWiseSyncTurnover) >= scenarioRule.Threshold  
    )  
  )  
  
  SELECT DISTINCT
  trade.CoreTradeId,
  trade.RefClientId,
  trade.RefInstrumentId,
  trade.IsBuy,
  trade.Rate,
  trade.Quantity,
  trade.RefSegmentId
  INTO #finalClientTrade
  FROM #FinalClientId fc  
  INNER JOIN #reqTrades trade ON fc.RefClientId = trade.RefClientId 

  


SELECT trade.RefClientId,  
    trade.RefInstrumentId,      
    SUM(CASE WHEN trade.IsBuy = 1 THEN   
      (  
       CASE   
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2) 
      
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN  ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)    
  
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR)     AND @ReportIdInternal NOT IN(@S113,@S118,@S119,@S43) 
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator) * inst.ContractSize,2)       
       
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR)  AND @ReportIdInternal  IN (@S43)
      THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * inst.ContractSize),2) 
	   
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCUR)  AND @ReportIdInternal  IN (@S43)
      THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)            
  
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)    AND @ReportIdInternal NOT IN(@S113,@S118,@S119) 
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator/inst.GeneralDenominator),2)  
       
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)   AND @ReportIdInternal =@S43
      THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  

        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)  
       
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT) AND segment.RefSegmentEnumId = @MCX_FNO  
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity * inst.ContractSize  
  
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCOM) AND segment.RefSegmentEnumId = @MCX_FNO  
         THEN  trade.Rate * trade.Quantity * inst.ContractSize  
       
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT)  
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  
        ELSE   
         trade.Rate * trade.Quantity   
        END   
        )   
        ELSE 0 END) AS BuyTurnover,  
    SUM(CASE WHEN trade.IsBuy = 0 THEN  
      (  
       CASE   
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2)
      
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN  ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)      
  
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR)     AND @ReportIdInternal NOT IN(@S113,@S118,@S119,@S43) 
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator) * inst.ContractSize,2)       
       
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR)  AND @ReportIdInternal  IN (@S43)
      THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * inst.ContractSize),2) 
	   
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCUR)  AND @ReportIdInternal  IN (@S43)
      THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)            
  
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)    AND @ReportIdInternal NOT IN(@S113,@S118,@S119) 
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator/inst.GeneralDenominator),2)  
       
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)   AND @ReportIdInternal =@S43
      THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  

        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2) 
       
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT) AND segment.RefSegmentEnumId = @MCX_FNO  
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity * inst.ContractSize  
  
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCOM) AND segment.RefSegmentEnumId = @MCX_FNO  
         THEN  trade.Rate * trade.Quantity * inst.ContractSize  
       
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT)  
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  
        ELSE   
         trade.Rate * trade.Quantity   
        END   
      )  
     ELSE 0 END) AS SellTurnover
  INTO #CliInstrumentWiseTurnover  
  FROM #FinalClientId fc  
    INNER JOIN #finalClientTrade trade ON fc.RefClientId = trade.RefClientId  AND fc.RefInstrumentId=trade.RefInstrumentId
    INNER JOIN #instruments inst ON trade.RefInstrumentId = inst.RefInstrumentId       
    INNER JOIN dbo.RefSegmentEnum segment ON trade.RefSegmentId = segment.RefSegmentEnumId  
  GROUP BY trade.RefClientId, trade.RefInstrumentId  
    
	
	SELECT DISTINCT st.OppClientId 
	INTO #OppClients  
	FROM #FinalClientId fc  
	INNER JOIN #SyncTradesTemp st ON fc.RefClientId = st.RefClientId  


  SELECT DISTINCT
  trade.CoreTradeId,
  trade.RefClientId,
  trade.RefInstrumentId,
  trade.IsBuy,
  trade.Rate,
  trade.Quantity,
  trade.RefSegmentId
  INTO #OppClientTrade
  FROM #OppClients oppCl  
  INNER JOIN #reqTrades trade ON oppCl.OppClientId = trade.RefClientId 
 
  
  SELECT trade.RefClientId,  
    trade.RefInstrumentId,  
    SUM(CASE WHEN trade.IsBuy = 1 THEN   
      (  
       CASE   
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2)  
      
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)       
  
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR)     AND @ReportIdInternal NOT IN(@S113,@S118,@S119,@S43) 
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator) * inst.ContractSize,2)       
       
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR)  AND @ReportIdInternal  IN (@S43)
      THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * inst.ContractSize),2) 
	   
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCUR)  AND @ReportIdInternal  IN (@S43)
      THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)            
  
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)    AND @ReportIdInternal NOT IN(@S113,@S118,@S119) 
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator/inst.GeneralDenominator),2)  
       
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)   AND @ReportIdInternal =@S43
      THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  

        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)  
       
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT) AND segment.RefSegmentEnumId = @MCX_FNO  
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity * inst.ContractSize  
  
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCOM) AND segment.RefSegmentEnumId = @MCX_FNO  
         THEN  trade.Rate * trade.Quantity * inst.ContractSize  
       
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT)  
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  
        ELSE   
         trade.Rate * trade.Quantity   
        END   
      )   
     ELSE 0 END) AS BuyTurnover,       
    SUM(CASE WHEN trade.IsBuy = 0 THEN   
      (  
       CASE   
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2) 
      
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN  ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)       
  
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR)     AND @ReportIdInternal NOT IN(@S113,@S118,@S119,@S43) 
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator) * inst.ContractSize,2)       
       
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTCUR)  AND @ReportIdInternal  IN (@S43)
      THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * inst.ContractSize),2) 
	   
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCUR)  AND @ReportIdInternal  IN (@S43)
      THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)            
  
        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)    AND @ReportIdInternal NOT IN(@S113,@S118,@S119) 
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator/inst.GeneralDenominator),2)  
       
     WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)   AND @ReportIdInternal =@S43
      THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  

        WHEN @VerticalInternal = 'NonCommodity' AND inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)   
       
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT) AND segment.RefSegmentEnumId = @MCX_FNO  
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity * inst.ContractSize  
  
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@FUTCOM) AND segment.RefSegmentEnumId = @MCX_FNO  
         THEN  trade.Rate * trade.Quantity * inst.ContractSize  
       
        WHEN @VerticalInternal <> 'NonCommodity' AND inst.RefInstrumentTypeId IN (@OPTIDX,@OPTSTK,@OPTCUR,@OPTFUT)  
         THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  
        ELSE   
         trade.Rate * trade.Quantity   
        END   
      )   
     ELSE 0 END) AS SellTurnover  
  INTO #OppCliInstrumentWiseTurnover  
  FROM #OppClients FinalOppClients  
    INNER JOIN #OppClientTrade trade ON FinalOppClients.OppClientId = trade.RefClientId
    INNER JOIN #instruments inst ON trade.RefInstrumentId = inst.RefInstrumentId      
    INNER JOIN dbo.RefSegmentEnum segment ON segment.RefSegmentEnumId = trade.RefSegmentId  
  GROUP BY trade.RefClientId, trade.RefInstrumentId  
    
	  SELECT client.RefClientId,
  client.ClientId,
  client.[Name]
  INTO #finalClientDet
  FROM #distinctClient tmpcl
  INNER JOIN dbo.RefClient client ON tmpcl.RefClientId = client.RefClientId  
  
  
  IF OBJECT_ID('tempdb..#SynchronizedTrades') IS NULL 
  BEGIN 
   
	CREATE TABLE #SynchronizedTrades  
		(  
		 RefclientId INT,  
		 TradeDate DATETIME,  
		 TradeDateTime DATETIME,  
		 TradeId INT,  
		 IsBuy BIT,
		 Rate DECIMAL(28,2),  
		 Quantity DECIMAL(28,2),   
		 SyncTurnover DECIMAL(28,2),  
		 DateWiseSyncTurnover DECIMAL(28,2),  
		 ClientSyncTurnover DECIMAL(28,2),  
		 OppRefClientId INT,  
		 OppIsBuy BIT,
		 ClientBuyTurnover DECIMAL(28,2),  
		 ClientSellTurnover DECIMAL(28,2),  
		 OppClientBuyTurnover DECIMAL(28,2),  
		 OppClientSellTurnover DECIMAL(28,2),  
		 BuyCtslId VARCHAR(300) COLLATE DATABASE_DEFAULT,  
		 SellCtslId VARCHAR(300) COLLATE DATABASE_DEFAULT,  
		 BuyTerminal VARCHAR(200) COLLATE DATABASE_DEFAULT,  
		 SellTerminal VARCHAR(200) COLLATE DATABASE_DEFAULT,  
		 RefSegmentId INT,
		 BuyOrdTime DATETIME,  
		 SellOrdTime DATETIME,  
		 RefInstrumentId INT,   
		 IsAlgoTrade BIT,
		 RefInstrumentTypeId INT  
	)  
  
  END 
    INSERT INTO #SynchronizedTrades
	(
		RefclientId , 
		 TradeDate ,  
		 TradeDateTime ,  
		 TradeId ,  
		 IsBuy ,
		 Rate ,
		 Quantity , 
		 SyncTurnover ,
		 DateWiseSyncTurnover ,
		 ClientSyncTurnover ,
		 OppRefClientId ,  
		 OppIsBuy ,
		 ClientBuyTurnover ,
		 ClientSellTurnover ,
		 OppClientBuyTurnover ,
		 OppClientSellTurnover ,
		 BuyCtslId , 
		 SellCtslId , 
		 BuyTerminal ,
		 SellTerminal ,
		 RefSegmentId ,
		 BuyOrdTime ,  
		 SellOrdTime ,  
		 RefInstrumentId ,   
		 IsAlgoTrade ,
		 RefInstrumentTypeId   
	)

	SELECT 
		fc.RefclientId ,   
		 st.TradeDate ,  
		 st.TradeDateTime ,  
		 st.TradeId ,  
		 st.IsBuy ,
		 st.Rate ,
		 st.Quantity , 
		 st.SyncTurnover ,
		 stdw.DateWiseSyncTurnover ,
		 fc.ClientSyncTurnover ,
		 st.OppClientId ,  
		 st.OppIsBuy ,
		CONVERT(DECIMAL(28,2),cliInstWiseTurnover.BuyTurnover),  
		CONVERT(DECIMAL(28,2),cliInstWiseTurnover.SellTurnover),  
		CONVERT(DECIMAL(28,2),oppCliInstWiseTurnover.BuyTurnover) ,  
		CONVERT(DECIMAL(28,2),oppCliInstWiseTurnover.SellTurnover),  
		 st.BuyCtslId,  
		st.SellCtslId,  
		 BuyTerminal ,
		 SellTerminal ,
		 RefSegmentId ,
		 st.BuyOrdTime ,  
		 st.SellOrdTime ,  
		 st.RefInstrumentId ,   
		 st.IsAlgoTrade ,
		 inst.RefInstrumentTypeId 
	FROM #FinalClientId fc
	INNER JOIN #SyncTradesTemp st ON fc.RefClientId = st.RefClientId AND fc.RefInstrumentTypeId = st.RefInstrumentTypeId and fc.RefInstrumentId=st.RefInstrumentId
	INNER JOIN #SyncTurnoverDateWise stdw ON fc.RefClientId = stdw.RefClientId AND fc.RefInstrumentTypeId = stdw.RefInstrumentTypeId  AND stdw.TradeDate = st.TradeDate and   stdw.RefInstrumentId=st.RefInstrumentId    
	INNER JOIN #CliInstrumentWiseTurnover cliInstWiseTurnover ON st.RefClientId = cliInstWiseTurnover.RefClientId  
                     AND st.RefInstrumentId = cliInstWiseTurnover.RefInstrumentId  
     INNER JOIN #OppCliInstrumentWiseTurnover oppCliInstWiseTurnover ON st.OppClientId = oppCliInstWiseTurnover.RefClientId  
                     AND st.RefInstrumentId = oppCliInstWiseTurnover.RefInstrumentId
	INNER JOIN #instruments inst ON st.RefInstrumentId = inst.RefInstrumentId  

	if(@ApplyScenarioRuleInternal= 1)
	BEGIN
		
		  SELECT *   
		  FROM(  
		   SELECT 
			syncTrnovr.RefClientId,  
			 clientDet.ClientId,  
			 clientDet.[Name] AS ClientName,  
			 inst.Code AS ScripCode,  
			 inst.InstrumentType,  
			 (inst.ScripId +' - '+ inst.InstrumentType +' - '+ inst.ExpiryDate +' - '+ inst.PutCall +' - '+ COALESCE(CONVERT(VARCHAR,CONVERT (DECIMAL(19,2),inst.StrikePrice)),'')) AS ScripTypeExpDtPutCallStrikePrice,  
			 syncTrnovr.TradeDate,  
			 syncTrnovr.TradeDateTime,  
			 syncTrnovr.TradeId,  
			 CASE WHEN syncTrnovr.IsBuy  = 1THEN 'Buy' ELSE 'Sell' END AS BuySell,  
			 syncTrnovr.Rate,  
			 syncTrnovr.Quantity,  
			 syncTrnovr.SyncTurnover,  
			 syncTrnovr.DateWiseSyncTurnover,  
			 syncTrnovr.ClientSyncTurnover,  
			 oppClient.RefClientId AS OppRefClientId,  
			 oppClientDet.ClientId AS OppClientId,  
			 oppClientDet.[Name] AS OppClientName,  
			 CASE WHEN syncTrnovr.OppIsBuy  = 1 THEN 'Buy' ELSE 'Sell' END AS OppBuySell,  
			 syncTrnovr.ClientBuyTurnover,  
			 syncTrnovr.ClientSellTurnover,  
			 syncTrnovr.OppClientBuyTurnover,  
			 syncTrnovr.OppClientSellTurnover,  
			 syncTrnovr.BuyCtslId,  
			 syncTrnovr.SellCtslId,  
			 syncTrnovr.BuyTerminal,  
			 syncTrnovr.SellTerminal,  
			 seg.Segment,  
			 syncTrnovr.BuyOrdTime,  
			 syncTrnovr.SellOrdTime,  
			 bhavCopy.NetTurnOver AS ExchangeTurnover,  
			 bhavCopy.high AS DayHigh,  
			 bhavCopy.Low AS DayLow,  
			 inst.RefInstrumentId,  
			 rf.IntermediaryCode,  
			 rf.[Name] AS IntermediaryName,  
			  case when syncTrnovr.IsAlgoTrade =1 then 'YES' else 'NO' end as AlgoTrade  ,
			 inst.RefInstrumentTypeId,    
			 ABS((DATEPART(SECOND, ISNULL(syncTrnovr.BuyOrdTime,GETDATE())) + 60 * DATEPART(MINUTE,ISNULL(syncTrnovr.BuyOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(syncTrnovr.BuyOrdTime,getdate())))-(DATEPART(SECOND, isnull(syncTrnovr.SellOrdTime,getdate())) +60 * DATEPART(MINUTE, isnull(
			syncTrnovr.SellOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(syncTrnovr.SellOrdTime,getdate())))) as DifferenceInSeconds,  
			 rf.TradeName  
      
		   FROM #SynchronizedTrades syncTrnovr  
			 INNER JOIN #FilteredClient client ON syncTrnovr.RefClientId = client.RefClientId
			 INNER JOIN #finalClientDet clientDet ON clientDet.RefClientId=syncTrnovr.RefClientId  
			 INNER JOIN #FilteredOppositeClient oppClient ON syncTrnovr.OppRefClientId = oppClient.RefClientId  
			  INNER JOIN #finalClientDet oppClientDet ON oppClientDet.RefClientId=oppClient.RefClientId
			 INNER JOIN #instruments inst ON syncTrnovr.RefInstrumentId = inst.RefInstrumentId      
			 INNER JOIN dbo.RefSegmentEnum seg ON syncTrnovr.RefSegmentId = seg.RefSegmentEnumId  
			 LEFT JOIN dbo.CoreBhavCopy bhavCopy ON syncTrnovr.RefSegmentId = bhavCopy.RefSegmentId AND syncTrnovr.TradeDate = bhavCopy.Date AND syncTrnovr.RefInstrumentId = bhavCopy.RefInstrumentId  
			 LEFT JOIN dbo.RefIntermediary rf on client.RefIntermediaryId = rf.RefIntermediaryId   
			)as temp  
			where 
			 EXISTS( 
			  select 1    
			  from dbo.RefAmlScenarioRule rules   
			  Inner join dbo.LinkRefAmlScenarioRuleRefInstrumentType linkInstType on linkInstType.RefAmlScenarioRuleId = rules.RefAmlScenarioRuleId   
			  AND linkInstType.RefInstrumentTypeId= temp.RefInstrumentTypeId  
			  where rules.RefAmlReportId=@ReportIdInternal    
			  AND (
					rules.RefAmlReportId NOT IN (@S43, @S518)
			  OR 
				  (rules.Threshold2 IS NOT NULL AND CONVERT(INT,rules.Threshold2)>=temp.DifferenceInSeconds)
				)  
			 )  
			--)  
	END

  
----ANY CHANGES MADE THIS SELECT SHOULD ALSO CHANGED IN dbo.Aml_GetReversalSynchronizedFnOTradeForScenarios  
 END
GO
--RC-WEB -72387 -END
--sync end
--S122
GO
--replacement of CoreTrade_GetSynchronizedFnOTradeAlerts
ALTER PROCEDURE dbo.CoreSyncTradeSegregation_GetSynchronizedFnOTradeAlerts
(  
 @ReportId INT,  
 @FromDate DATETIME,  
 @ToDate DATETIME,  
 @ExcludePro BIT,  
 @ExcludeInstitution BIT,  
 @ExcludeOppositePro BIT,  
 @ExcludeOppositeInstitution BIT,  
 @ExcludealgoTrade BIT,  
 @Vertical VARCHAR(20)  
)  
AS  
BEGIN  
  
	DECLARE 
		@ReportIdInternal INT, 
		@FromDateInternal DATETIME,
		@ToDateInternal DATETIME, 
		@ExcludeProInternal BIT,  
		@ExcludeInstitutionInternal BIT, 
		@ExcludeOppositeProInternal BIT, 
		@ExcludeOppositeInstitutionInternal BIT,  
		@ExcludealgoTradeInternal BIT, 
		@VerticalInternal VARCHAR(20)
	DECLARE 
		@NSE_FNOId INT, @NSE_CDXId INT, @MCXSX_CDXId INT, 
		@NCDEX_FNOId INT, @MCX_FNOId INT, @InstitutionId INT, @ProId INT,  
		@OPTCURId INT, @FUTCURId INT, @OPTSTKId INT, @OPTIDXId INT, @OPTIRCId INT, 
		@VerticalInternalId INT  
      
		SET @ReportIdInternal = @ReportId  
		SET @FromDateInternal = dbo.GetDateWithoutTime(@FromDate)  
		SET @ToDateInternal = dbo.GetDateWithoutTime(@ToDate)  
		SET @ExcludeProInternal = @ExcludePro  
		SET @ExcludeInstitutionInternal = @ExcludeInstitution          
		SET @ExcludeOppositeProInternal = @ExcludeOppositePro  
		SET @ExcludeOppositeInstitutionInternal = @ExcludeOppositeInstitution  
		SET @ExcludealgoTradeInternal = @ExcludealgoTrade  
		SET @VerticalInternal = @Vertical  
		SET @VerticalInternalId = CASE WHEN @VerticalInternal = 'NonCommodity' THEN 1 ELSE 0 END  
		SELECT @NSE_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_FNO'  
		SELECT @NSE_CDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CDX'  
		SELECT @MCXSX_CDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'MCXSX_CDX'  
		SELECT @NCDEX_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NCDEX_FNO'  
		SELECT @MCX_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'MCX_FNO'  
		SELECT @ProId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Pro'  
		SELECT @InstitutionId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'  
		SELECT @OPTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'  
		SELECT @FUTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR'  
		SELECT @OPTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'  
		SELECT @OPTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'  
		SELECT @OPTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIRC'  
  
	SELECT   
		RefSegmentEnumId  
	INTO #RequiredSegment  
	FROM dbo.RefSegmentEnum  
	WHERE 
	(
		@VerticalInternalId = 1 AND RefSegmentEnumId IN (@NSE_FNOId, @NSE_CDXId, @MCXSX_CDXId)
	)  
	OR (
		@VerticalInternalId = 0 AND RefSegmentEnumId IN (@NCDEX_FNOId, @MCX_FNOId)
	)  
  SELECT DISTINCT    
	  RefClientId    
	  INTO #clientsToExclude
	  FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex    
	  WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)     
	  AND @ToDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @ToDateInternal) 

	SELECT 
	trade.CoreSyncTradeSegregationId ,
	trade.RefClientId,trade.OppRefClientId,
	ISNULL(inst.StrikePrice, 0) AS StrikePrice,
	ISNULL(inst.MarketLot, 1) AS MarketLot,
	ISNULL(inst.ContractSize, 1) AS ContractSize,
	(ISNULL(inst.PriceNumerator,1) /ISNULL(inst.PriceDenominator,1) * trade.Quantity) * 
	(ISNULL(inst.GeneralNumerator,1) / ISNULL(inst.GeneralDenominator,1)) AS NDQ
	INTO #tradeSyncIds  
	FROM dbo.CoreSyncTradeSegregation trade
	INNER JOIN dbo.RefInstrument inst on inst.RefInstrumentId = trade.RefInstrumentId 
	INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId   
	LEFT JOIN #clientsToExclude ex ON ex.RefClientId = trade.RefClientId 
	 WHERE   ex.RefClientId IS NULL AND 
		trade.TradeDate BETWEEN @FromDateInternal AND @ToDateInternal 
		AND (  
			@ExcludealgoTradeInternal = 0 OR 
			(
				@ExcludealgoTradeInternal = 1 
				AND   
					ISNULL(trade.IsAlgoTrade,0) = 0
			)
		) 
	SELECT Distinct RefClientId INTO #distinctClient FROM #tradeSyncIds
	SELECT client.RefClientId, client.RefClientStatusId 
	INTO #TempClient  
	FROM #distinctClient trade  
	INNER JOIN dbo.RefClient client ON trade.RefClientId = client.RefClientId  
    
	SELECT  RefClientId  
	INTO #FilteredClient  
	FROM #TempClient  
	WHERE (@ExcludeProInternal = 0 OR RefClientStatusId != @ProId)  
	AND (@ExcludeInstitutionInternal = 0 OR RefClientStatusId != @InstitutionId)   
    
	SELECT Distinct OppRefClientId INTO #distinctOppClient FROM #tradeSyncIds
	SELECT  client.RefClientId, client.RefClientStatusId 
	INTO #TempOppClient  
	FROM #distinctOppClient trade  
	INNER JOIN dbo.RefClient client ON trade.OppRefClientId = client.RefClientId 

	SELECT  RefClientId  
	INTO #FilteredOppositeClient  
	FROM #TempOppClient  
	WHERE (@ExcludeOppositeProInternal = 0 OR RefClientStatusId != @ProId)  
	AND (@ExcludeOppositeInstitutionInternal = 0 OR RefClientStatusId != @InstitutionId) 

	SELECT    
		-- trade.CoreTradeId,  
		trade.RefClientId,  
		trade.RefInstrumentId,  
		trade.RefInstrumentTypeId,  
		trade.TradeDate,  
		trade.TradeDateTime,  
		trade.TradeId,  
		CASE WHEN trade.BuySell  = 1 THEN 'BUY' ELSE 'SELL' END AS BuySell,  
		trade.Rate,  
		trade.Quantity,      
		CASE
			WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCURId
				THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + temp.StrikePrice) * temp.NDQ * temp.MarketLot * 
					temp.ContractSize, 2))					
			WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @FUTCURId
				THEN CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.Quantity * temp.ContractSize, 2))					
			WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId) 
				THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + temp.StrikePrice) * temp.NDQ * temp.MarketLot, 2))
			WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCURId, @FUTCURId, @OPTSTKId, @OPTIDXId, @OPTIRCId) 
				THEN  CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * temp.NDQ * temp.MarketLot, 2))
			WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTIDXId, @OPTSTKId, @OPTCURId) 
				THEN (temp.StrikePrice + trade.Rate) * trade.Quantity
			ELSE 
				trade.Rate * trade.Quantity 
		END AS SyncTurnover,     
		oppClient.RefClientId AS OppClientId,  
		CASE WHEN trade.BuySell  = 1 THEN 'Sell' ELSE 'Buy' END AS OppBuySell,  
		trade.BuyCtslId,  
		trade.SellCtslId,      
		trade.BuyTerminal,  
		trade.SellTerminal,      
		trade.BuyOrdTime,  
		trade.SellOrdTime,  
		trade.RefSegmentId,  
		CASE WHEN trade.IsAlgoTrade = 1 THEN 'YES' ELSE 'NO' END AS AlgoTrade
	INTO #SyncTrades    
	FROM #tradeSyncIds temp
	INNER JOIN dbo.CoreSyncTradeSegregation trade   ON temp.CoreSyncTradeSegregationId = trade.CoreSyncTradeSegregationId
	INNER JOIN #FilteredClient client ON client.RefClientId = trade.RefClientId                  
	INNER JOIN #FilteredOppositeClient oppClient ON oppClient.RefClientId = trade.OppRefClientId                                                   
	--INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId      
                  

  SELECT   
  st.RefClientId,  
  st.RefInstrumentId,  
  st.TradeDate,      
  SUM(st.SyncTurnover) AS DateWiseSyncTurnover ,  
  st.RefInstrumentTypeId,  
  st.TradeId     
  INTO #SyncTurnoverDateWise  
        FROM #SyncTrades st  
        GROUP BY st.RefClientId, st.RefInstrumentId, st.TradeDate, st.SyncTurnover, st.RefInstrumentTypeId, st.TradeId  
        HAVING EXISTS (SELECT 1 FROM dbo.RefAmlScenarioRule scenarioRule  
  INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType linkInstrumentType ON   
  scenarioRule.RefAmlScenarioRuleId = linkInstrumentType.RefAmlScenarioRuleId  
  WHERE scenarioRule.RefAmlReportId = @ReportIdInternal AND st.RefInstrumentTypeId = linkInstrumentType.RefInstrumentTypeId  
    AND SUM(st.SyncTurnover) >= scenarioRule.Threshold  
  )  
    
	SELECT   t.RefClientId
	INTO #tradeClients
	FROM (
		SELECT  RefClientId
		FROM #FilteredClient

		UNION

		SELECT  RefClientId
		FROM #FilteredOppositeClient
	) t

	SELECT trade.CoreTradeId  
	INTO #tradeIds  
	FROM dbo.CoreTrade trade  
	INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId
	INNER JOIN #tradeClients client ON client.RefClientId =  trade.RefClientId
	WHERE trade.TradeDate BETWEEN @FromDateInternal AND @ToDateInternal 
	AND 
	(  
		@ExcludealgoTradeInternal = 0 OR 
		(
			@ExcludealgoTradeInternal = 1 AND   
			LEN(CONVERT(VARCHAR, trade.CtclId)) = 15   
			AND SUBSTRING(CONVERT(VARCHAR, trade.CtclId), 13, 1) NOT IN ('0','2','4')
		)
	)

	SELECT   
	trade.RefClientId,  
	trade.RefInstrumentId,  
	CASE WHEN trade.BuySell = 'Buy'  
	THEN 1  
	WHEN trade.BuySell = 'Sell'  
	THEN 0 END AS BuySell,   
	trade.Rate,  
	trade.Quantity,  
	inst.RefInstrumentTypeId,  
	ISNULL(inst.StrikePrice, 0) AS StrikePrice,  
	ISNULL(inst.MarketLot, 1) AS MarketLot,  
	ISNULL(inst.ContractSize, 1) AS ContractSize,  
	(ISNULL(inst.PriceNumerator,1) /ISNULL(inst.PriceDenominator,1) * trade.Quantity) *   
	(ISNULL(inst.GeneralNumerator,1) / ISNULL(inst.GeneralDenominator,1)) AS NDQ  
	INTO #FilteredTrade  
	FROM #tradeIds ids  
	INNER JOIN dbo.CoreTrade trade ON trade.CoreTradeId = ids.CoreTradeId          
	INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId  

  SELECT   
   trade.RefClientId,  
   trade.RefInstrumentId,      
   SUM(CASE WHEN trade.BuySell = 1 THEN   
    (CASE  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCURId  
       THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot * trade.ContractSize, 2))  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @FUTCURId  
       THEN CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.Quantity * trade.ContractSize, 2))  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId)   
       THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot, 2))  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCURId, @FUTCURId, @OPTSTKId, @OPTIDXId, @OPTIRCId)   
       THEN  CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.NDQ * trade.MarketLot, 2))   
     WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTIDXId, @OPTSTKId, @OPTCURId)   
       THEN (trade.StrikePrice + trade.Rate) * trade.Quantity  
     ELSE trade.Rate * trade.Quantity   
    END)   
   ELSE 0 END) AS BuyTurnover,  
   SUM(CASE WHEN trade.BuySell = 0 THEN   
    (CASE   
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCURId  
       THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot * trade.ContractSize,2))  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @FUTCURId  
       THEN CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.Quantity * trade.ContractSize, 2))   
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId)   
       THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot, 2))  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCURId, @FUTCURId, @OPTSTKId, @OPTIDXId, @OPTIRCId)   
       THEN  CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.NDQ * trade.MarketLot, 2))   
     WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTIDXId, @OPTSTKId, @OPTCURId)   
       THEN (trade.StrikePrice + trade.Rate) * trade.Quantity  
     ELSE trade.Rate * trade.Quantity END)   
   ELSE 0 END) AS SellTurnover  
  INTO #CliInstrumentWiseTurnover  
  FROM #SyncTurnoverDateWise fc  
  INNER JOIN #FilteredTrade trade ON fc.RefClientId = trade.RefClientId     
  GROUP BY trade.RefClientId, trade.RefInstrumentId  
    
  SELECT   
   trade.RefClientId,  
   trade.RefInstrumentId,  
   SUM(CASE WHEN trade.BuySell = 1 THEN   
    (CASE  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCURId  
       THEN CONVERT(DECIMAL(28,2),ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot * trade.ContractSize, 2))  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @FUTCURId  
       THEN CONVERT(DECIMAL(28,2),ROUND(trade.Rate * trade.Quantity * trade.ContractSize, 2))  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId)   
       THEN CONVERT(DECIMAL(28,2),ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot, 2))  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCURId, @FUTCURId, @OPTSTKId, @OPTIDXId, @OPTIRCId)   
       THEN  CONVERT(DECIMAL(28,2),ROUND(trade.Rate * trade.NDQ * trade.MarketLot, 2))  
     WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTIDXId, @OPTSTKId, @OPTCURId)   
       THEN (trade.StrikePrice + trade.Rate) * trade.Quantity  
     ELSE trade.Rate * trade.Quantity END)   
    ELSE 0 END) AS BuyTurnover,   
   SUM(CASE WHEN trade.BuySell = 0 THEN   
    (CASE  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCURId  
       THEN CONVERT(DECIMAL(28,2),ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot * trade.ContractSize, 2))  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @FUTCURId  
       THEN CONVERT(DECIMAL(28,2),ROUND(trade.Rate * trade.Quantity * trade.ContractSize, 2))  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId)   
       THEN CONVERT(DECIMAL(28,2),ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot, 2))  
     WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCURId, @FUTCURId, @OPTSTKId, @OPTIDXId, @OPTIRCId)   
       THEN  CONVERT(DECIMAL(28,2),ROUND(trade.Rate * trade.NDQ * trade.MarketLot, 2))  
     WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTCURId)  
       THEN (trade.StrikePrice + trade.Rate) * trade.Quantity  
     ELSE trade.Rate * trade.Quantity END)   
    ELSE 0 END) AS SellTurnover  
  INTO #OppCliInstrumentWiseTurnover  
  FROM (SELECT DISTINCT st.OppClientId FROM #SyncTurnoverDateWise fc  
   INNER JOIN #SyncTrades st ON fc.RefClientId = st.RefClientId  
   GROUP BY st.OppClientId  
  ) AS FinalOppClients  
  INNER JOIN #FilteredTrade trade ON FinalOppClients.OppClientId = trade.RefClientId     
  GROUP BY trade.RefClientId, trade.RefInstrumentId  
    
  SELECT   
   fc.RefClientId,  
   client.ClientId,  
   client.[Name] AS ClientName,  
   inst.Code AS ScripCode,  
   instType.InstrumentType,  
   (COALESCE(inst.ScripId,'') +' - '+ COALESCE(instType.InstrumentType,'') +' - '+ COALESCE(CONVERT(VARCHAR,inst.ExpiryDate,106),'') +' - '+ COALESCE(inst.PutCall,'') +' - '+ COALESCE(CONVERT(VARCHAR,CONVERT (DECIMAL(19,2),inst.StrikePrice)),'')) AS ScripTypeExpDtPutCallStrikePrice,  
   st.TradeDate,  
   st.TradeDateTime,  
   st.TradeId,  
   st.BuySell,  
   st.Rate,  
   st.Quantity,  
   st.SyncTurnover,  
   fc.DateWiseSyncTurnover,  
   fc.DateWiseSyncTurnover AS ClientSyncTurnover,  
   oppClient.RefClientId AS OppRefClientId,  
   oppClient.ClientId AS OppClientId,  
   oppClient.[Name] AS OppClientName,  
   st.OppBuySell,  
   cliInstWiseTurnover.BuyTurnover AS ClientBuyTurnover,  
   cliInstWiseTurnover.SellTurnover AS ClientSellTurnover,  
   oppCliInstWiseTurnover.BuyTurnover AS OppClientBuyTurnover,  
   oppCliInstWiseTurnover.SellTurnover AS OppClientSellTurnover,  
   st.BuyCtslId,  
   st.SellCtslId,  
   st.BuyTerminal,  
   st.SellTerminal,  
   seg.Segment,  
   st.BuyOrdTime,  
   st.SellOrdTime,  
   bhavCopy.NetTurnOver AS ExchangeTurnover,  
   bhavCopy.high AS DayHigh,  
   bhavCopy.Low AS DayLow,  
   inst.RefInstrumentId,  
   rf.IntermediaryCode,  
   rf.[Name] AS IntermediaryName,  
   st.AlgoTrade,  
   instType.RefInstrumentTypeId,  
   ABS((DATEPART(SECOND, ISNULL(st.BuyOrdTime,GETDATE())) + 60 * DATEPART(MINUTE,ISNULL(st.BuyOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(st.BuyOrdTime,getdate())))-(DATEPART(SECOND, isnull(st.SellOrdTime,getdate())) +60 * DATEPART(MINUTE, isnull(st
.SellOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(st.SellOrdTime,getdate())))) as DifferenceInSeconds,  
   rf.TradeName,  
   linkClientIncomeLatest.Networth,      
   linkClientIncomeLatest.Income,   
   igrp.[Name] AS 'IncomeGroupName'  
   INTO #finalResult  
   FROM #SyncTurnoverDateWise fc  
   INNER JOIN #SyncTrades st ON fc.RefClientId = st.RefClientId AND fc.RefInstrumentTypeId = st.RefInstrumentTypeId   
    AND st.RefInstrumentId = fc.RefInstrumentId AND fc.TradeDate = st.TradeDate AND st.TradeId = fc.TradeId  
   INNER JOIN dbo.RefClient client ON fc.RefClientId = client.RefClientId  
   INNER JOIN dbo.RefClient oppClient ON st.OppClientId = oppClient.RefClientId  
   INNER JOIN dbo.RefInstrument inst ON st.RefInstrumentId = inst.RefInstrumentId      
   INNER JOIN dbo.RefInstrumentType instType ON inst.RefInstrumentTypeId = instType.RefInstrumentTypeId      
   INNER JOIN dbo.RefSegmentEnum seg ON st.RefSegmentId = seg.RefSegmentEnumId  
   INNER JOIN #CliInstrumentWiseTurnover cliInstWiseTurnover ON st.RefClientId = cliInstWiseTurnover.RefClientId  
    AND st.RefInstrumentId = cliInstWiseTurnover.RefInstrumentId  
   INNER JOIN #OppCliInstrumentWiseTurnover oppCliInstWiseTurnover ON st.OppClientId = oppCliInstWiseTurnover.RefClientId  
    AND st.RefInstrumentId = oppCliInstWiseTurnover.RefInstrumentId  
   LEFT JOIN dbo.LinkRefClientRefIncomeGroupLatest linkClientIncomeLatest ON linkClientIncomeLatest.RefClientId = client.RefClientId  
   LEFT JOIN RefIncomeGroup igrp ON linkClientIncomeLatest.RefIncomeGroupId=igrp.RefIncomeGroupId  
   LEFT JOIN dbo.CoreBhavCopy bhavCopy ON st.RefSegmentId = bhavCopy.RefSegmentId AND st.TradeDate = bhavCopy.[Date]  
    AND st.RefInstrumentId = bhavCopy.RefInstrumentId  
   LEFT JOIN dbo.RefIntermediary rf ON client.RefIntermediaryId = rf.RefIntermediaryId   
      
   SELECT   
    temp.RefClientId,  
    temp.ClientId,  
    temp.ClientName,  
    temp.ScripCode,  
    temp.InstrumentType,  
    temp.ScripTypeExpDtPutCallStrikePrice,  
    temp.TradeDate,  
    temp.TradeDateTime,  
    temp.TradeId,  
    temp.BuySell,  
    temp.Rate,  
    temp.Quantity,  
    temp.SyncTurnover,  
    temp.DateWiseSyncTurnover,  
    temp.ClientSyncTurnover,  
    temp.OppRefClientId,  
    temp.OppClientId,  
    temp.OppClientName,  
    temp.OppBuySell,  
    temp.ClientBuyTurnover,  
    temp.ClientSellTurnover,  
    temp.OppClientBuyTurnover,  
    temp.OppClientSellTurnover,  
    temp.BuyCtslId,  
    temp.SellCtslId,  
    temp.BuyTerminal,  
    temp.SellTerminal,  
    temp.Segment,  
    temp.BuyOrdTime,  
    temp.SellOrdTime,  
    temp.ExchangeTurnover,  
    temp.DayHigh,  
    temp.DayLow,  
    temp.RefInstrumentId,  
    temp.IntermediaryCode,  
    temp.IntermediaryName,  
    temp.AlgoTrade,  
    temp.RefInstrumentTypeId,  
    temp.DifferenceInSeconds,  
    temp.TradeName,  
    temp.IncomeGroupName,  
    temp.Income,  
    temp.Networth  
   FROM #finalResult temp  
   WHERE EXISTS (SELECT 1 FROM dbo.RefAmlScenarioRule rules   
    INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType linkInstType   
     ON linkInstType.RefAmlScenarioRuleId = rules.RefAmlScenarioRuleId   
     AND linkInstType.RefInstrumentTypeId= temp.RefInstrumentTypeId  
    WHERE rules.RefAmlReportId = @ReportIdInternal AND (  
      (rules.Threshold2 IS NOT null) --AND (CONVERT(INT,rules.Threshold2) <> 0  
      AND (CONVERT(INT,rules.Threshold2) >= temp.DifferenceInSeconds)   
      --OR CONVERT(INT,rules.Threshold2) = 0  
    )  
   )  


END  
GO
GO
ALTER PROCEDURE dbo.CoreTrade_GetSynchronizedFnOTradeAlerts
(
	@ReportId INT,
	@FromDate DATETIME,
	@ToDate DATETIME,
	@ExcludePro BIT,
	@ExcludeInstitution BIT,
	@ExcludeOppositePro BIT,
	@ExcludeOppositeInstitution BIT,
	@ExcludealgoTrade BIT,
	@Vertical VARCHAR(20)
)
AS
BEGIN

		DECLARE @ReportIdInternal INT, @FromDateInternal DATETIME, @ToDateInternal DATETIME, @ExcludeProInternal BIT,
			@ExcludeInstitutionInternal BIT, @ExcludeOppositeProInternal BIT, @ExcludeOppositeInstitutionInternal BIT,
			@ExcludealgoTradeInternal BIT, @VerticalInternal VARCHAR(20), @NSE_FNOId INT, @NSE_CDXId INT,
			@MCXSX_CDXId INT, @NCDEX_FNOId INT, @MCX_FNOId INT, @InstitutionId INT, @ProId INT,
			@OPTCURId INT, @FUTCURId INT, @OPTSTKId INT, @OPTIDXId INT, @OPTIRCId INT, @VerticalInternalId INT
    
        SET	@ReportIdInternal = @ReportId
        SET @FromDateInternal = dbo.GetDateWithoutTime(@FromDate)
        SET @ToDateInternal = dbo.GetDateWithoutTime(@ToDate)
        SET @ExcludeProInternal = @ExcludePro
        SET @ExcludeInstitutionInternal = @ExcludeInstitution        
        SET @ExcludeOppositeProInternal = @ExcludeOppositePro
        SET @ExcludeOppositeInstitutionInternal = @ExcludeOppositeInstitution
		SET @ExcludealgoTradeInternal = @ExcludealgoTrade
		SET @VerticalInternal = @Vertical
		SET @VerticalInternalId = CASE WHEN @VerticalInternal = 'NonCommodity' THEN 1 ELSE 0 END
		SELECT @NSE_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_FNO'
		SELECT @NSE_CDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CDX'
		SELECT @MCXSX_CDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'MCXSX_CDX'
		SELECT @NCDEX_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NCDEX_FNO'
		SELECT @MCX_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'MCX_FNO'
		SELECT @ProId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Pro'
		SELECT @InstitutionId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'
		SELECT @OPTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'
		SELECT @FUTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR'
		SELECT @OPTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'
		SELECT @OPTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'
		SELECT @OPTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIRC'

		SELECT	
			RefSegmentEnumId
		INTO #RequiredSegment
		FROM dbo.RefSegmentEnum
		WHERE (@VerticalInternalId = 1 AND RefSegmentEnumId IN (@NSE_FNOId, @NSE_CDXId, @MCXSX_CDXId))
			OR (@VerticalInternalId = 0 AND RefSegmentEnumId IN (@NCDEX_FNOId, @MCX_FNOId))
		
		SELECT DISTINCT    
		  RefClientId    
		  INTO #clientsToExclude
		  FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex    
		  WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)     
		  AND @ToDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @ToDateInternal) 

		SELECT trade.CoreTradeId
		INTO #tradeIds
		FROM dbo.CoreTrade trade
		INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId 
		LEFT JOIN #clientsToExclude ex ON ex.RefClientId = trade.RefClientId 
		WHERE   ex.RefClientId IS NULL AND trade.TradeDate BETWEEN @FromDateInternal AND @ToDateInternal AND (
		@ExcludealgoTradeInternal = 0 OR (@ExcludealgoTradeInternal = 1 AND 
				LEN(CONVERT(VARCHAR, trade.CtclId)) = 15 
				AND SUBSTRING(CONVERT(VARCHAR, trade.CtclId), 13, 1) NOT IN ('0','2','4')))
		
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
			trade.Rate,
			trade.Quantity,
			trade.CtclId,
			trade.RefSegmentId,
			trade.RefSettlementId,
			trade.TraderId,
			trade.OrderTimeStamp,
			trade.TradeIdAlphaNumeric,
			CASE WHEN @ExcludealgoTradeInternal = 0 AND SUBSTRING(CONVERT(VARCHAR, trade.CtclId), 13, 1) IN ('0', '2', '4') THEN 'YES' ELSE 'NO' END AS AlgoTrade,
			inst.RefInstrumentTypeId,
			ISNULL(inst.StrikePrice, 0) AS StrikePrice,
			ISNULL(inst.MarketLot, 1) AS MarketLot,
			ISNULL(inst.ContractSize, 1) AS ContractSize,
			(ISNULL(inst.PriceNumerator,1) /ISNULL(inst.PriceDenominator,1) * trade.Quantity) * 
			(ISNULL(inst.GeneralNumerator,1) / ISNULL(inst.GeneralDenominator,1)) AS NDQ
		INTO #FilteredTrade
		FROM #tradeIds ids
		INNER JOIN dbo.CoreTrade trade ON trade.CoreTradeId = ids.CoreTradeId
		INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId      
        INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId
        INNER JOIN dbo.RefInstrumentType instType ON inst.RefInstrumentTypeId = instType.RefInstrumentTypeId

		SELECT trade.RefClientId, client.RefClientStatusId
		INTO #TempClient
		FROM #FilteredTrade trade
		INNER JOIN dbo.RefClient client ON trade.RefClientId = client.RefClientId
		
		SELECT DISTINCT RefClientId
		INTO #FilteredClient
		FROM #TempClient
		WHERE (@ExcludeProInternal = 0 OR RefClientStatusId != @ProId)
			AND	(@ExcludeInstitutionInternal = 0 OR RefClientStatusId != @InstitutionId)	
		
		SELECT DISTINCT RefClientId
		INTO #FilteredOppositeClient
		FROM #TempClient
		WHERE (@ExcludeOppositeProInternal = 0 OR RefClientStatusId != @ProId)
			AND	(@ExcludeOppositeInstitutionInternal = 0 OR RefClientStatusId != @InstitutionId)
		
		SELECT  
			trade.CoreTradeId,
			trade.RefClientId,
			trade.RefInstrumentId,
			trade.RefInstrumentTypeId,
			trade.TradeDate,
			trade.TradeDateTime,
			trade.TradeId,
			trade.VBuySell AS BuySell,
			trade.Rate,
			trade.Quantity,				
			CASE
				WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCURId
					THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot * 
						trade.ContractSize, 2))					
				WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @FUTCURId
					THEN CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.Quantity * trade.ContractSize, 2))					
				WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId) 
					THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot, 2))
				WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCURId, @FUTCURId, @OPTSTKId, @OPTIDXId, @OPTIRCId) 
					THEN  CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.NDQ * trade.MarketLot, 2))
				WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTIDXId, @OPTSTKId, @OPTCURId) 
					THEN (trade.StrikePrice + trade.Rate) * trade.Quantity
				ELSE 
					trade.Rate * trade.Quantity 
			END AS SyncTurnover,				
			oppTrade.RefClientId AS OppClientId,
			oppTrade.VBuySell AS OppBuySell,
			CASE WHEN trade.BuySell = 1 THEN trade.CtclId ELSE oppTrade.CtclId END AS BuyCtslId,
			CASE WHEN trade.BuySell = 0 THEN trade.CtclId ELSE oppTrade.CtclId END AS SellCtslId,				
			CASE WHEN trade.BuySell = 1 THEN ct.TerminalId ELSE oppCt.TerminalId END AS BuyTerminal,
			CASE WHEN trade.BuySell = 0 THEN ct.TerminalId ELSE oppCt.TerminalId END AS SellTerminal,				
			CASE WHEN trade.BuySell = 1 THEN trade.OrderTimeStamp ELSE oppTrade.OrderTimeStamp END AS BuyOrdTime,
			CASE WHEN trade.BuySell = 0 THEN trade.OrderTimeStamp ELSE oppTrade.OrderTimeStamp END AS SellOrdTime,
			trade.RefSegmentId,
			trade.AlgoTrade
		INTO #SyncTrades		
		FROM #FilteredTrade trade
		INNER JOIN #FilteredClient client ON client.RefClientId = trade.RefClientId                
		INNER JOIN #FilteredTrade oppTrade ON trade.RefSegmentId = oppTrade.RefSegmentId
            AND trade.RefSettlementId = oppTrade.RefSettlementId
            AND trade.RefInstrumentId = oppTrade.RefInstrumentId              
        INNER JOIN #FilteredOppositeClient oppClient ON oppClient.RefClientId = oppTrade.RefClientId               
        LEFT JOIN dbo.CoreTerminal ct ON ct.UserId = CONVERT(VARCHAR(50), trade.TraderId)
        LEFT JOIN dbo.CoreTerminal oppCt ON oppCt.UserId = CONVERT(VARCHAR(50), oppTrade.TraderId )                                                
        WHERE ((trade.TradeId = oppTrade.TradeId) OR (trade.RefSegmentId = @NCDEX_FNOId 
				AND (ISNULL(trade.TradeIdAlphaNumeric,'') <> '' AND ISNULL(oppTrade.TradeIdAlphaNumeric, '') <> '')
				AND  trade.TradeIdAlphaNumeric = oppTrade.TradeIdAlphaNumeric))
			AND trade.Quantity = oppTrade.Quantity
            AND trade.Rate = oppTrade.Rate
            AND trade.TradeDateTime = oppTrade.TradeDateTime
            AND trade.BuySell <> oppTrade.BuySell
            AND trade.RefClientId <> oppTrade.RefClientId
                
        SELECT	
			st.RefClientId,
			st.RefInstrumentId,
			st.TradeDate,				
			SUM(st.SyncTurnover) AS DateWiseSyncTurnover	,
			st.RefInstrumentTypeId,
			st.TradeId			
		INTO #SyncTurnoverDateWise
        FROM #SyncTrades st
        GROUP BY st.RefClientId, st.RefInstrumentId, st.TradeDate, st.SyncTurnover, st.RefInstrumentTypeId, st.TradeId
        HAVING EXISTS (SELECT 1 FROM dbo.RefAmlScenarioRule scenarioRule
			INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType linkInstrumentType ON 
				scenarioRule.RefAmlScenarioRuleId = linkInstrumentType.RefAmlScenarioRuleId
			WHERE scenarioRule.RefAmlReportId = @ReportIdInternal AND st.RefInstrumentTypeId = linkInstrumentType.RefInstrumentTypeId
				AND SUM(st.SyncTurnover) >= scenarioRule.Threshold
		)
        
		SELECT	
			trade.RefClientId,
			trade.RefInstrumentId,				
			SUM(CASE WHEN trade.BuySell = 1 THEN 
				(CASE
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCURId
							THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot * trade.ContractSize, 2))
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @FUTCURId
							THEN CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.Quantity * trade.ContractSize, 2))
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId) 
							THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot, 2))
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCURId, @FUTCURId, @OPTSTKId, @OPTIDXId, @OPTIRCId) 
							THEN  CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.NDQ * trade.MarketLot, 2)) 
					WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTIDXId, @OPTSTKId, @OPTCURId) 
							THEN (trade.StrikePrice + trade.Rate) * trade.Quantity
					ELSE trade.Rate * trade.Quantity 
				END) 
			ELSE 0 END) AS BuyTurnover,
			SUM(CASE WHEN trade.BuySell = 0 THEN 
				(CASE 
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCURId
							THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot * trade.ContractSize,2))
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @FUTCURId
							THEN CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.Quantity * trade.ContractSize, 2))	
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId) 
							THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot, 2))
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCURId, @FUTCURId, @OPTSTKId, @OPTIDXId, @OPTIRCId) 
							THEN  CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * trade.NDQ * trade.MarketLot, 2)) 
					WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTIDXId, @OPTSTKId, @OPTCURId) 
							THEN (trade.StrikePrice + trade.Rate) * trade.Quantity
					ELSE trade.Rate * trade.Quantity END) 
			ELSE 0 END) AS SellTurnover
		INTO #CliInstrumentWiseTurnover
		FROM #SyncTurnoverDateWise fc
		INNER JOIN #FilteredTrade trade ON fc.RefClientId = trade.RefClientId			
		GROUP BY trade.RefClientId, trade.RefInstrumentId
		
		SELECT	
			trade.RefClientId,
			trade.RefInstrumentId,
			SUM(CASE WHEN trade.BuySell = 1 THEN 
				(CASE
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCURId
							THEN CONVERT(DECIMAL(28,2),ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot * trade.ContractSize, 2))
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @FUTCURId
							THEN CONVERT(DECIMAL(28,2),ROUND(trade.Rate * trade.Quantity * trade.ContractSize, 2))
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId) 
							THEN CONVERT(DECIMAL(28,2),ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot, 2))
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCURId, @FUTCURId, @OPTSTKId, @OPTIDXId, @OPTIRCId) 
							THEN  CONVERT(DECIMAL(28,2),ROUND(trade.Rate * trade.NDQ * trade.MarketLot, 2))
					WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTIDXId, @OPTSTKId, @OPTCURId) 
							THEN (trade.StrikePrice + trade.Rate) * trade.Quantity
					ELSE trade.Rate * trade.Quantity END) 
				ELSE 0 END) AS BuyTurnover, 
			SUM(CASE WHEN trade.BuySell = 0 THEN 
				(CASE
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @OPTCURId
							THEN CONVERT(DECIMAL(28,2),ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot * trade.ContractSize, 2))
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId = @FUTCURId
							THEN CONVERT(DECIMAL(28,2),ROUND(trade.Rate * trade.Quantity * trade.ContractSize, 2))
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId) 
							THEN CONVERT(DECIMAL(28,2),ROUND((trade.Rate + trade.StrikePrice) * trade.NDQ * trade.MarketLot, 2))
					WHEN @VerticalInternalId = 1 AND trade.RefInstrumentTypeId NOT IN (@OPTCURId, @FUTCURId, @OPTSTKId, @OPTIDXId, @OPTIRCId) 
							THEN  CONVERT(DECIMAL(28,2),ROUND(trade.Rate * trade.NDQ * trade.MarketLot, 2))
					WHEN @VerticalInternalId <> 1 AND trade.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTCURId)
							THEN (trade.StrikePrice + trade.Rate) * trade.Quantity
					ELSE trade.Rate * trade.Quantity END) 
				ELSE 0 END) AS SellTurnover
		INTO #OppCliInstrumentWiseTurnover
		FROM (SELECT DISTINCT st.OppClientId FROM #SyncTurnoverDateWise fc
			INNER JOIN #SyncTrades st ON fc.RefClientId = st.RefClientId
			GROUP BY st.OppClientId
		) AS FinalOppClients
		INNER JOIN #FilteredTrade trade ON FinalOppClients.OppClientId = trade.RefClientId			
		GROUP BY trade.RefClientId, trade.RefInstrumentId
		
		SELECT	
			fc.RefClientId,
			client.ClientId,
			client.[Name] AS ClientName,
			inst.Code AS ScripCode,
			instType.InstrumentType,
			(COALESCE(inst.ScripId,'') +' - '+ COALESCE(instType.InstrumentType,'') +' - '+ COALESCE(CONVERT(VARCHAR,inst.ExpiryDate,106),'') +' - '+ COALESCE(inst.PutCall,'') +' - '+ COALESCE(CONVERT(VARCHAR,CONVERT (DECIMAL(19,2),inst.StrikePrice)),'')) AS ScripTypeExpDtPutCallStrikePrice,
			st.TradeDate,
			st.TradeDateTime,
			st.TradeId,
			st.BuySell,
			st.Rate,
			st.Quantity,
			st.SyncTurnover,
			fc.DateWiseSyncTurnover,
			fc.DateWiseSyncTurnover AS ClientSyncTurnover,
			oppClient.RefClientId AS OppRefClientId,
			oppClient.ClientId AS OppClientId,
			oppClient.[Name] AS OppClientName,
			st.OppBuySell,
			cliInstWiseTurnover.BuyTurnover AS ClientBuyTurnover,
			cliInstWiseTurnover.SellTurnover AS ClientSellTurnover,
			oppCliInstWiseTurnover.BuyTurnover AS OppClientBuyTurnover,
			oppCliInstWiseTurnover.SellTurnover AS OppClientSellTurnover,
			st.BuyCtslId,
			st.SellCtslId,
			st.BuyTerminal,
			st.SellTerminal,
			seg.Segment,
			st.BuyOrdTime,
			st.SellOrdTime,
			bhavCopy.NetTurnOver AS ExchangeTurnover,
			bhavCopy.high AS DayHigh,
			bhavCopy.Low AS DayLow,
			inst.RefInstrumentId,
			rf.IntermediaryCode,
			rf.[Name] AS IntermediaryName,
			st.AlgoTrade,
			instType.RefInstrumentTypeId,
			ABS((DATEPART(SECOND, ISNULL(st.BuyOrdTime,GETDATE())) + 60 * DATEPART(MINUTE,ISNULL(st.BuyOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(st.BuyOrdTime,getdate())))-(DATEPART(SECOND, isnull(st.SellOrdTime,getdate())) +60 * DATEPART(MINUTE, isnull(st.SellOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(st.SellOrdTime,getdate())))) as DifferenceInSeconds,
			rf.TradeName,
			linkClientIncomeLatest.Networth,    
			linkClientIncomeLatest.Income, 
			igrp.[Name] AS 'IncomeGroupName'
			INTO #finalResult
			FROM #SyncTurnoverDateWise fc
			INNER JOIN #SyncTrades st ON fc.RefClientId = st.RefClientId AND fc.RefInstrumentTypeId = st.RefInstrumentTypeId 
				AND st.RefInstrumentId = fc.RefInstrumentId AND fc.TradeDate = st.TradeDate AND st.TradeId = fc.TradeId
			INNER JOIN dbo.RefClient client ON fc.RefClientId = client.RefClientId
			INNER JOIN dbo.RefClient oppClient ON st.OppClientId = oppClient.RefClientId
			INNER JOIN dbo.RefInstrument inst ON st.RefInstrumentId = inst.RefInstrumentId				
			INNER JOIN dbo.RefInstrumentType instType ON inst.RefInstrumentTypeId = instType.RefInstrumentTypeId				
			INNER JOIN dbo.RefSegmentEnum seg ON st.RefSegmentId = seg.RefSegmentEnumId
			INNER JOIN #CliInstrumentWiseTurnover cliInstWiseTurnover ON st.RefClientId = cliInstWiseTurnover.RefClientId
				AND st.RefInstrumentId = cliInstWiseTurnover.RefInstrumentId
			INNER JOIN #OppCliInstrumentWiseTurnover oppCliInstWiseTurnover ON st.OppClientId = oppCliInstWiseTurnover.RefClientId
				AND st.RefInstrumentId = oppCliInstWiseTurnover.RefInstrumentId
			LEFT JOIN dbo.LinkRefClientRefIncomeGroupLatest linkClientIncomeLatest ON linkClientIncomeLatest.RefClientId = client.RefClientId
			LEFT JOIN RefIncomeGroup igrp ON linkClientIncomeLatest.RefIncomeGroupId=igrp.RefIncomeGroupId
			LEFT JOIN dbo.CoreBhavCopy bhavCopy ON st.RefSegmentId = bhavCopy.RefSegmentId AND st.TradeDate = bhavCopy.[Date]
				AND st.RefInstrumentId = bhavCopy.RefInstrumentId
			LEFT JOIN dbo.RefIntermediary rf ON client.RefIntermediaryId = rf.RefIntermediaryId	
				
			SELECT	
				temp.RefClientId,
				temp.ClientId,
				temp.ClientName,
				temp.ScripCode,
				temp.InstrumentType,
				temp.ScripTypeExpDtPutCallStrikePrice,
				temp.TradeDate,
				temp.TradeDateTime,
				temp.TradeId,
				temp.BuySell,
				temp.Rate,
				temp.Quantity,
				temp.SyncTurnover,
				temp.DateWiseSyncTurnover,
				temp.ClientSyncTurnover,
				temp.OppRefClientId,
				temp.OppClientId,
				temp.OppClientName,
				temp.OppBuySell,
				temp.ClientBuyTurnover,
				temp.ClientSellTurnover,
				temp.OppClientBuyTurnover,
				temp.OppClientSellTurnover,
				temp.BuyCtslId,
				temp.SellCtslId,
				temp.BuyTerminal,
				temp.SellTerminal,
				temp.Segment,
				temp.BuyOrdTime,
				temp.SellOrdTime,
				temp.ExchangeTurnover,
				temp.DayHigh,
				temp.DayLow,
				temp.RefInstrumentId,
				temp.IntermediaryCode,
				temp.IntermediaryName,
				temp.AlgoTrade,
				temp.RefInstrumentTypeId,
				temp.DifferenceInSeconds,
				temp.TradeName,
				temp.IncomeGroupName,
				temp.Income,
				temp.Networth
			FROM #finalResult temp
			WHERE EXISTS (SELECT 1 FROM dbo.RefAmlScenarioRule rules 
				INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType linkInstType 
					ON linkInstType.RefAmlScenarioRuleId = rules.RefAmlScenarioRuleId 
					AND linkInstType.RefInstrumentTypeId= temp.RefInstrumentTypeId
				WHERE rules.RefAmlReportId = @ReportIdInternal AND (
						(rules.Threshold2 is null) OR (CONVERT(INT,rules.Threshold2) <> 0
						AND CONVERT(INT,rules.Threshold2) >= temp.DifferenceInSeconds) 
						OR CONVERT(INT,rules.Threshold2) = 0
				)
			)
END
GO
