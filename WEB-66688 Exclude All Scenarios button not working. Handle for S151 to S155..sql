------RC-WEB-66688 START
GO
ALTER PROCEDURE dbo.AML_GetHighTurnoverTradesByGroupofClientsIn1Day  
(    
 @RunDate DATETIME,    
 @ReportId INT    
)    
AS    
BEGIN    
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
 WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportIdInternal)     
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
  t.ClientQT,
  COUNT(t.RefClientId) OVER (PARTITION BY t.RefInstrumentId, t.RefSegmentId, t.BuySell) CRN    
 INTO #topClients    
 FROM (SELECT     
   RefInstrumentId,    
   RefSegmentId,    
   BuySell,    
   RefScripGroupId,    
   RefClientId,    
   ClientTO,    
   ClientQT,    
   DENSE_RANK() OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell ORDER BY ClientTO DESC) AS RN
  FROM #clientTOs    
 ) t    
 INNER JOIN #scenarioRules rules ON t.RefScripGroupId = rules.RefScripGroupId    
 WHERE t.RN <= rules.Threshold3     
    
 DROP TABLE #clientTOs    
    
 SELECT    
  RefScripGroupId,    
  RefInstrumentId,     
  RefSegmentId,     
  BuySell,    
  SUM(ClientTO) AS GroupTO    
 INTO #groupedSum    
 FROM #topClients  
 WHERE @IsGroupGreaterThanOneClient<CRN
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
------RC-WEB-66688 END

------RC-WEB-66688 START
GO
ALTER PROCEDURE dbo.AML_GetHighTurnoverbyGroupofClientsin1DayFNO
(
	@RunDate DATETIME,
	@ReportId INT
)
AS
BEGIN
	DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @OPTSTKId INT, @OPTIDXId INT, @OPTCURId INT,
			@OPTIRCId INT, @FUTIDXId INT, @FUTSTKId INT, @FUTIRDId INT, @FUTIRTId INT, @FUTCURId INT,
			@FUTIRCId INT, @FUTIVXId INT, @FUTIRFId INT, @IsGroupGreaterThanOneClient INT,
			@IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT

	SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)
	SET @ReportIdInternal = @ReportId
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
		RefSegmentEnumId,
		Segment
	INTO #segments
	FROM dbo.RefSegmentEnum WHERE Code IN ('NSE_FNO', 'NSE_CDX')

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
		instType.InstrumentType,
		instType.RefInstrumentTypeId
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule rul
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId
	INNER JOIN dbo.RefInstrumentType instType ON instType.RefInstrumentTypeId = link.RefInstrumentTypeId
	WHERE RefAmlReportId = @ReportIdInternal 
		AND instType.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTCURId, @OPTIRCId, @FUTIDXId, @FUTSTKId,
			@FUTIRDId, @FUTIRTId, @FUTCURId, @FUTIRCId, @FUTIVXId, @FUTIRFId)
	
	SELECT 									 
		trade.RefClientId,					 
		trade.RefInstrumentId,				 
		CASE WHEN trade.BuySell = 'Buy'		 
			THEN 1							 
			ELSE 0 END BuySell,
		CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)
		THEN trade.Quantity * ISNULL(inst.ContractSize, 1)
		ELSE trade.Quantity END AS Quantity,
		CASE WHEN inst.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId)
			THEN (ISNULL(inst.StrikePrice, 0) + trade.Rate) * trade.Quantity
			WHEN inst.RefInstrumentTypeId = @OPTCURId
			THEN (ISNULL(inst.StrikePrice, 0) + trade.Rate) * trade.Quantity * ISNULL(inst.ContractSize, 1)
			WHEN inst.RefInstrumentTypeId = @FUTCURId
			THEN trade.Rate * trade.Quantity * ISNULL(inst.ContractSize, 1)
			ELSE trade.Rate * trade.Quantity END AS tradeTO,
		rules.RefInstrumentTypeId,
		trade.RefSegmentId
	INTO #tradeData
	FROM dbo.CoreTrade trade
	INNER JOIN #segments seg ON trade.RefSegmentId = RefSegmentEnumId
	INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId
	INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = inst.RefInstrumentTypeId
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId
	WHERE trade.TradeDate = @RunDateInternal
		AND (@IsExcludePro = 0 OR cl.RefClientStatusId <> @ProStatusId)
		AND (@IsExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstituteStatusId)
		AND NOT EXISTS(SELECT 1 FROM #clientsToExclude clEx
			WHERE clEx.RefClientId = trade.RefClientId)

	SELECT
		RefClientId,
		RefInstrumentTypeId,
		RefInstrumentId,
		RefSegmentId,
		BuySell,
		SUM(tradeTO) AS ClientTO,
		SUM(Quantity) AS ClientQT
	INTO #clientTOs
	FROM #tradeData
	GROUP BY RefClientId, RefInstrumentTypeId, RefInstrumentId, RefSegmentId, BuySell

	DROP TABLE #tradeData

	SELECT
		t.RefInstrumentId,
		t.RefSegmentId,
		t.BuySell,
		t.RefInstrumentTypeId,
		t.RefClientId,
		t.ClientTO,
		t.ClientQT,
		COUNT(t.RefClientId) OVER (PARTITION BY t.RefInstrumentId, t.RefSegmentId, t.BuySell) CRN
	INTO #topClients
	FROM (SELECT 
			RefInstrumentId,
			RefSegmentId,
			BuySell,
			RefInstrumentTypeId,
			RefClientId,
			ClientTO,
			ClientQT,
			DENSE_RANK() OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell ORDER BY ClientTO DESC) AS RN

		FROM #clientTOs
	) t
	INNER JOIN #scenarioRules rules ON t.RefInstrumentTypeId = rules.RefInstrumentTypeId
	WHERE t.RN <= rules.Threshold3  

	DROP TABLE #clientTOs

	SELECT
		RefInstrumentTypeId,
		RefInstrumentId, 
		RefSegmentId, 
		BuySell,
		SUM(ClientTO) AS GroupTO
	INTO #groupedSum
	FROM #topClients
	WHERE @IsGroupGreaterThanOneClient< CRN
	GROUP BY RefInstrumentTypeId, RefInstrumentId, RefSegmentId, BuySell

	SELECT
		grp.RefInstrumentTypeId,
		grp.RefInstrumentId,
		grp.BuySell,
		grp.RefSegmentId,
		grp.GroupTO,
		bhav.NetTurnOver AS ExchangeTO,
		(grp.GroupTO * 100 / bhav.NetTurnOver) AS GroupContributedPerc
	INTO #selectedScrips
	FROM #groupedSum grp
	INNER JOIN dbo.CoreBhavCopy bhav ON grp.RefInstrumentId = bhav.RefInstrumentId
	INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = grp.RefInstrumentTypeId
	WHERE bhav.[Date] = @RunDateInternal AND grp.GroupTO >= rules.Threshold2
		AND (grp.GroupTO * 100 / bhav.NetTurnOver) >= rules.Threshold

	DROP TABLE #groupedSum

	SELECT
		cl.RefClientId,
		client.ClientId,
		client.[Name] AS ClientName,
		seg.Segment,
		rules.InstrumentType,
		inst.[Name] + '-' + ISNULL(rules.InstrumentType, '') + 
			'-' + 							 
			CASE WHEN inst.ExpiryDate IS NULL THEN ''
			ELSE CONVERT(varchar, inst.ExpiryDate, 106) END + '-' + 
			ISNULL(inst.PutCall, '') + '-' + ISNULL(CONVERT(VARCHAR(100), inst.StrikePrice), '') AS ScripTypeExpDtPutCallStrikePrice,
		scrips.GroupTO,
		scrips.GroupContributedPerc,
		scrips.ExchangeTO,
		cl.ClientQT AS ClientTradedQty,
		(cl.ClientTO / cl.ClientQT) AS AvgRate,
		cl.ClientTO,
		(cl.ClientTO * 100 / scrips.ExchangeTO) AS ClientPerc,
		(cl.ClientTO * 100 / scrips.GroupTO) AS GroupSharePerc,
		rules.RefInstrumentTypeId,
		scrips.RefInstrumentId,
		scrips.RefSegmentId,
		scrips.BuySell
	INTO #finalData
	FROM #selectedScrips scrips
	INNER JOIN #topClients cl ON scrips.RefInstrumentId = cl.RefInstrumentId 
		AND scrips.RefSegmentId = cl.RefSegmentId AND scrips.BuySell = cl.BuySell
	INNER JOIN dbo.RefClient client ON cl.RefClientId = client.RefClientId
	INNER JOIN #segments seg ON scrips.RefSegmentId = seg.RefSegmentEnumId
	INNER JOIN #scenarioRules rules ON scrips.RefInstrumentTypeId = rules.RefInstrumentTypeId
	INNER JOIN dbo.RefInstrument inst ON scrips.RefInstrumentId = inst.RefInstrumentId

	SELECT
		final.RefClientId,
		final.ClientId,
		final.ClientName,
		final.RefSegmentId AS SegmentId,
		final.Segment,
		@RunDateInternal AS TradeDate,
		final.InstrumentType,
		final.ScripTypeExpDtPutCallStrikePrice AS InstrumentInfo,
		CASE WHEN final.BuySell = 1
			THEN 'Buy'
			ELSE 'Sell' END AS BuySell,
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
	INNER JOIN #scenarioRules rules ON final.RefInstrumentTypeId = rules.RefInstrumentTypeId
	WHERE final.GroupSharePerc >= rules.Threshold4
	ORDER BY final.RefInstrumentId, final.RefSegmentId, final.BuySell, final.ClientPerc DESC

END
GO
------RC-WEB-66688 END
---S153
------RC-WEB-66688 START
GO
  ALTER PROCEDURE dbo.AML_GetHighTurnoverbyNewClientin1DayEQ (    
 @RunDate DATETIME,    
 @ReportId INT    
)    
AS    
BEGIN    
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @FromDate DATETIME,     
  @DormantDays INT, @BSECashId INT, @NSECashId INT    
    
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)    
 SET @ReportIdInternal = @ReportId    
 SELECT @DormantDays = CONVERT(INT, [Value]) FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal    
 SET @FromDate = DATEADD(d, -@DormantDays, @RunDateInternal)    
 SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'    
 SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'    
    
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
  scrip.[Name] AS ScripGroup,    
  scrip.RefScripGroupId    
 INTO #scenarioRules    
 FROM dbo.RefAmlScenarioRule rul    
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId    
 INNER JOIN dbo.RefScripGroup scrip ON scrip.RefScripGroupId = link.RefScripGroupId    
 WHERE RefAmlReportId = @ReportIdInternal    
    
 SELECT    
  clStatus.[Name] AS ClientStatus,    
  clStatus.RefClientStatusId    
 INTO #clientStatus    
 FROM dbo.RefAmlScenarioRule rul    
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus clLink ON clLink.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId    
 INNER JOIN dbo.RefClientStatus clStatus ON clStatus.RefClientStatusId = clLink.RefClientStatusId    
 WHERE RefAmlReportId = @ReportIdInternal    
    
 SELECT    
  trade.CoreTradeId,    
  inst.Isin,    
  inst.GroupName,    
  inst.RefSegmentId,    
  cl.AccountOpeningDate,    
  trade.RefClientId    
 INTO #tradeIds    
 FROM dbo.CoreTrade trade    
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId    
 INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId    
 INNER JOIN #clientStatus stat ON cl.RefClientStatusId = stat.RefClientStatusId    
 WHERE trade.TradeDate = @RunDateInternal AND trade.RefSegmentId IN (@BSECashId, @NSECashId)    
  AND NOT EXISTS(SELECT 1 FROM #clientsToExclude clEx    
   WHERE clEx.RefClientId = trade.RefClientId)    
    
 DROP TABLE #clientsToExclude    
 DROP TABLE #clientStatus    
    
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
  ids.*,    
  rules.RefScripGroupId    
 INTO #finalIds    
 FROM #tradeIds ids    
 LEFT JOIN #nseGroupData nse ON ids.Isin = nse.Isin AND ids.RefSegmentId=@NSECashId  
 INNER JOIN #scenarioRules rules ON (ids.RefSegmentId = @BSECashId     
  AND rules.ScripGroup = ids.GroupName) OR (ids.RefSegmentId = @NSECashId    
  AND rules.ScripGroup = nse.GroupName)     
    
 DROP TABLE #tradeIds    
 DROP TABLE #nseGroupData    
    
 SELECT DISTINCT    
  RefClientId,    
  AccountOpeningDate    
 INTO #allClients    
 FROM #finalIds    
    
 SELECT    
  RefClientId,    
  DATEDIFF(DAY, TradeDate, @RunDateInternal) AS NoOfDays    
 INTO #lastTrade    
 FROM (SELECT     
   trade.RefClientId,    
   trade.TradeDate,    
   ROW_NUMBER() OVER (PARTITION BY trade.RefClientId ORDER BY trade.TradeDate DESC) AS RN    
  FROM #allClients cl    
  INNER JOIN dbo.CoreTrade trade ON cl.RefClientId = trade.RefClientId    
  WHERE trade.TradeDate < @RunDateInternal    
 ) t    
 WHERE t.RN = 1    
    
 SELECT    
  al.RefClientId,    
  CASE WHEN lt.NoOfDays IS NULL    
  THEN 0    
  ELSE lt.NoOfDays END AS NoOfDays    
 INTO #finalClients    
 FROM #allClients al    
 LEFT JOIN #lastTrade lt ON al.RefClientId = lt.RefClientId    
 WHERE lt.NoOfDays IS NULL OR lt.NoOfDays > @DormantDays    
  OR (al.AccountOpeningDate IS NOT NULL AND al.AccountOpeningDate >= @FromDate)    
    
    
 DROP TABLE #allClients    
 DROP TABLE #lastTrade    
    
 SELECT    
  cl.RefClientId,    
  ids.RefScripGroupId,    
  trade.RefInstrumentId,    
  CASE WHEN trade.BuySell = 'Buy'    
  THEN 1 ELSE 0 END AS BuySell,    
  trade.RefSegmentId,    
  trade.Quantity,    
  (trade.Rate * trade.Quantity) AS TurnOver    
 INTO #tradeData    
 FROM #finalClients cl    
 INNER JOIN #finalIds ids ON cl.RefClientId = ids.RefClientId    
 INNER JOIN dbo.CoreTrade trade ON ids.CoreTradeId = trade.CoreTradeId    
    
 DROP TABLE #finalIds    
    
 SELECT    
  RefClientId,    
  RefScripGroupId,    
  RefInstrumentId,    
  RefSegmentId,    
  SUM(TurnOver) AS BuyTO,    
  SUM(Quantity) AS BuyQty    
 INTO #BuyData    
 FROM #tradeData    
 WHERE BuySell = 1    
 GROUP BY RefClientId, RefScripGroupId, RefInstrumentId, RefSegmentId    
    
 SELECT    
  RefClientId,    
  RefScripGroupId,    
  RefInstrumentId,    
  RefSegmentId,    
  SUM(TurnOver) AS SellTO,    
  SUM(Quantity) AS SellQty    
 INTO #SellData    
 FROM #tradeData    
 WHERE BuySell = 0    
 GROUP BY RefClientId, RefScripGroupId, RefInstrumentId, RefSegmentId    
    
 DROP TABLE #tradeData    
    
 SELECT    
  COALESCE(cl.RefClientId, scl.RefClientId) AS RefClientId,    
  COALESCE(buy.RefSegmentId, sell.RefSegmentId) AS RefSegmentId,    
  CASE WHEN ISNULL(sell.SellQty, 0) > ISNULL(buy.BuyQty, 0)    
   THEN 'Sell'    
   ELSE 'Buy' END AS BuySell,    
  inst.Code AS ScripCode,    
  inst.[Name] AS ScripName,    
  ISNULL(buy.BuyQty, 0) AS BuyQty,    
  CASE WHEN buy.BuyQty IS NULL OR buy.BuyQty = 0 OR buy.BuyTO IS NULL    
   THEN 0    
   ELSE buy.BuyTO / buy.BuyQty END AS BuyAvgRate,    
  ISNULL(buy.BuyTO, 0) AS BuyTO,    
  ISNULL(sell.SellQty, 0) AS SellQty,    
  CASE WHEN sell.SellQty IS NULL OR sell.SellQty = 0 OR sell.SellTO IS NULL    
   THEN 0    
   ELSE sell.SellTO / sell.SellQty END AS SellAvgRate,    
  ISNULL(sell.SellTO, 0) AS SellTO,    
  (ISNULL(sell.SellTO, 0) + ISNULL(buy.BuyTO, 0)) AS TotalTO,    
  CASE WHEN ISNULL(sell.SellQty, 0) > ISNULL(buy.BuyQty, 0)    
  THEN sell.SellQty * 100 / bhav.NumberOfShares    
  ELSE buy.BuyQty * 100 / bhav.NumberOfShares END AS ScripPercvizExchQty,    
  CASE WHEN ISNULL(sell.SellTO, 0) > ISNULL(buy.BuyTO, 0)    
  THEN sell.SellTO * 100 / bhav.NetTurnOver     
  ELSE buy.BuyTO * 100 / bhav.NetTurnOver END AS ScripPercvizExchTO,    
  COALESCE(cl.NoOfDays, scl.NoOfDays) AS NoOfDays,    
  bhav.NumberOfShares AS ExchangeQty,    
  bhav.NetTurnOver AS ExchangeTO,    
  COALESCE(buy.RefScripGroupId, sell.RefScripGroupId) AS RefScripGroupId,    
  inst.RefInstrumentId    
 INTO #finalData    
 FROM #finalClients cl    
 LEFT JOIN #BuyData buy ON cl.RefClientId = buy.RefClientId    
 FULL JOIN #SellData sell ON sell.RefClientId = buy.RefClientId     
  AND buy.RefInstrumentId = sell.RefInstrumentId AND buy.RefSegmentId = sell.RefSegmentId    
 LEFT JOIN #finalClients scl ON buy.RefClientId IS NULL AND scl.RefClientId = sell.RefClientId    
 INNER JOIN dbo.RefInstrument inst ON COALESCE(buy.RefInstrumentId, sell.RefInstrumentId) = inst.RefInstrumentId    
 INNER JOIN dbo.CoreBhavCopy bhav ON inst.RefInstrumentId = bhav.RefInstrumentId    
 WHERE bhav.[Date] = @RunDateInternal    
   
 DROP TABLE #finalClients    
 DROP TABLE #BuyData    
 DROP TABLE #SellData    
    
 SELECT    
  fd.RefClientId,    
  cl.ClientId,    
  cl.[Name] AS ClientName,    
  seg.RefSegmentEnumId AS SegmentId,    
  seg.Segment,    
  @RunDateInternal AS TradeDate,    
  rules.ScripGroup AS GroupName,    
  fd.BuySell,    
  fd.ScripCode,    
  fd.ScripName,    
  fd.BuyQty,    
  CONVERT(DECIMAL(28, 2), fd.BuyAvgRate) AS BuyAvgRate,    
  CONVERT(DECIMAL(28, 2), fd.BuyTO) AS BuyTO,    
  fd.SellQty,    
  CONVERT(DECIMAL(28, 2), fd.SellAvgRate) AS SellAvgRate,    
  CONVERT(DECIMAL(28, 2), fd.SellTO) AS SellTO,    
  CONVERT(DECIMAL(28, 2), fd.TotalTO) AS TotalTO,    
  CONVERT(DECIMAL(28, 2), fd.ScripPercvizExchQty) AS ScripPercvizExchQty,    
  CONVERT(DECIMAL(28, 2), fd.ScripPercvizExchTO) AS ScripPercvizExchTO,    
  fd.NoOfDays,    
  fd.ExchangeQty,    
  CONVERT(DECIMAL(28, 2), fd.ExchangeTO) AS ExchangeTO,    
  fd.RefInstrumentId    
 FROM #finalData fd    
 INNER JOIN dbo.RefClient cl ON fd.RefClientId = cl.RefClientId    
 INNER JOIN dbo.RefSegmentEnum seg ON fd.RefSegmentId = seg.RefSegmentEnumId    
 INNER JOIN #scenarioRules rules ON rules.RefScripGroupId = fd.RefScripGroupId    
 WHERE fd.ScripPercvizExchQty >= rules.Threshold    
  AND fd.ScripPercvizExchTO >= rules.Threshold2    
  AND fd.TotalTO >= rules.Threshold3    
 ORDER BY fd.RefClientId, fd.RefSegmentId, fd.RefScripGroupId    
    
END    
GO
------RC-WEB-66688 END
--s154
------RC-WEB-66688 START
GO
 AlTER PROCEDURE dbo.AML_GetHighTurnoverbyGroupofNewClientsin1DayEQ    
(      
 @RunDate DATETIME,      
 @ReportId INT      
)      
AS      
BEGIN      
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @FromDate DATETIME,       
   @DormantDays INT, @BSECashId INT, @NSECashId INT, @IsGroupGreaterThanOneClient INT,    
   @IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT    
      
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)      
 SET @ReportIdInternal = @ReportId      
 SELECT @DormantDays = CONVERT(INT, [Value]) FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal  AND [Name]='New_Not_traded_Days'    
 SET @FromDate = DATEADD(d, -@DormantDays, @RunDateInternal)      
    
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
 WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportIdInternal)       
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
 WHERE rul.RefAmlReportId = @ReportIdInternal      
      
 SELECT      
  trade.CoreTradeId,      
  inst.Isin,      
  inst.GroupName,      
  inst.RefSegmentId,      
  cl.AccountOpeningDate,      
  trade.RefClientId      
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
  ids.*,      
  rules.RefScripGroupId      
 INTO #finalIds      
 FROM #tradeIds ids      
 LEFT JOIN #nseGroupData nse ON ids.Isin = nse.Isin AND ids.RefSegmentId=@NSECashId    
 INNER JOIN #scenarioRules rules ON (ids.RefSegmentId = @BSECashId       
  AND rules.ScripGroup = ids.GroupName) OR (ids.RefSegmentId = @NSECashId      
  AND rules.ScripGroup = nse.GroupName)       
      
 DROP TABLE #tradeIds      
 DROP TABLE #nseGroupData      
      
 SELECT DISTINCT      
  RefClientId,      
  AccountOpeningDate      
 INTO #allClients      
 FROM #finalIds      
      
 SELECT      
  RefClientId,      
  DATEDIFF(DAY, TradeDate, @RunDateInternal) AS NoOfDays      
 INTO #lastTrade      
 FROM (SELECT       
   trade.RefClientId,      
   trade.TradeDate,      
   ROW_NUMBER() OVER (PARTITION BY trade.RefClientId ORDER BY trade.TradeDate DESC) AS RN      
  FROM #allClients cl      
  INNER JOIN dbo.CoreTrade trade ON cl.RefClientId = trade.RefClientId      
  WHERE trade.TradeDate < @RunDateInternal      
 ) t      
 WHERE t.RN = 1      
      
 SELECT      
  al.RefClientId,      
  CASE WHEN lt.NoOfDays IS NULL      
  THEN 0      
  ELSE lt.NoOfDays END AS NoOfDays      
 INTO #finalClients      
 FROM #allClients al      
 LEFT JOIN #lastTrade lt ON al.RefClientId = lt.RefClientId      
 WHERE lt.NoOfDays IS NULL OR lt.NoOfDays > @DormantDays      
  OR (al.AccountOpeningDate IS NOT NULL AND al.AccountOpeningDate >= @FromDate)      
      
 DROP TABLE #allClients      
 DROP TABLE #lastTrade      
      
 SELECT      
  trade.RefClientId,      
  trade.RefInstrumentId,      
  CASE WHEN trade.BuySell = 'Buy'      
   THEN 1      
   ELSE 0 END BuySell,      
  trade.Quantity,      
  (trade.Rate * trade.Quantity) AS tradeTO,      
  ids.RefScripGroupId,      
  trade.RefSegmentId      
 INTO #tradeData      
 FROM #finalClients cl      
 INNER JOIN #finalIds ids ON cl.RefClientId = ids.RefClientId      
 INNER JOIN dbo.CoreTrade trade ON ids.CoreTradeId = trade.CoreTradeId      
      
 DROP TABLE #finalIds      
      
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
  t.ClientQT,
   COUNT(RefClientId) OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell ) AS CRN     
 INTO #topClients      
 FROM (SELECT       
   RefInstrumentId,      
   RefSegmentId,      
   BuySell,      
   RefScripGroupId,      
   RefClientId,      
   ClientTO,      
   ClientQT,      
   DENSE_RANK() OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell ORDER BY ClientTO DESC) AS RN      
  FROM #clientTOs      
 ) t      
 INNER JOIN #scenarioRules rules ON t.RefScripGroupId = rules.RefScripGroupId      
 WHERE t.RN <= rules.Threshold3      
      
 DROP TABLE #clientTOs      
      
 SELECT      
  RefScripGroupId,      
  RefInstrumentId,       
  RefSegmentId,       
  BuySell,      
  SUM(ClientTO) AS GroupTO      
 INTO #groupedSum      
 FROM #topClients 
 WHERE  @IsGroupGreaterThanOneClient < CRN
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
  scrips.BuySell,      
  fl.NoOfDays      
 INTO #finalData      
 FROM #selectedScrips scrips      
 INNER JOIN #topClients cl ON scrips.RefInstrumentId = cl.RefInstrumentId       
  AND scrips.RefSegmentId = cl.RefSegmentId AND scrips.BuySell = cl.BuySell      
 INNER JOIN #finalClients fl ON fl.RefClientId = cl.RefClientId      
 INNER JOIN dbo.RefClient client ON cl.RefClientId = client.RefClientId      
 INNER JOIN dbo.RefSegmentEnum seg ON scrips.RefSegmentId = seg.RefSegmentEnumId      
 INNER JOIN #scenarioRules rules ON scrips.RefScripGroupId = rules.RefScripGroupId      
 INNER JOIN dbo.RefInstrument instru ON scrips.RefInstrumentId = instru.RefInstrumentId      
      
 DROP TABLE #topClients      
 DROP TABLE #finalClients      
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
  final.NoOfDays,      
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
------RC-WEB-66688 END
------RC-WEB-66688 START
GO
 ALTER PROCEDURE [dbo].[AML_GetHighTurnoverbyNewClientin1DayFNO] (  
 @RunDate DATETIME,  
 @ReportId INT  
)  
AS  
BEGIN  
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @FromDate DATETIME,   
  @DormantDays INT, @OPTSTKId INT, @OPTIDXId INT, @OPTCURId INT, @OPTIRCId INT,   
  @FUTIDXId INT, @FUTSTKId INT, @FUTIRDId INT, @FUTIRTId INT, @FUTCURId INT,  
  @FUTIRCId INT, @FUTIVXId INT, @FUTIRFId INT  
  
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
 SET @ReportIdInternal = @ReportId  
 SELECT @DormantDays = CONVERT(INT, [Value]) FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal  
 SET @FromDate = DATEADD(d, -@DormantDays, @RunDateInternal)  
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
  
 SELECT   
  RefSegmentEnumId,  
  Segment  
 INTO #segments  
 FROM dbo.RefSegmentEnum WHERE Code IN ('NSE_FNO', 'NSE_CDX')  
  
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
  instType.InstrumentType,  
  instType.RefInstrumentTypeId  
 INTO #scenarioRules  
 FROM dbo.RefAmlScenarioRule rul  
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId  
 INNER JOIN dbo.RefInstrumentType instType ON instType.RefInstrumentTypeId = link.RefInstrumentTypeId  
 WHERE rul.RefAmlReportId = @ReportIdInternal   
  AND instType.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTCURId, @OPTIRCId, @FUTIDXId, @FUTSTKId,  
   @FUTIRDId, @FUTIRTId, @FUTCURId, @FUTIRCId, @FUTIVXId, @FUTIRFId)  
  
 SELECT  
  clStatus.[Name] AS ClientStatus,  
  clStatus.RefClientStatusId  
 INTO #clientStatus  
 FROM dbo.RefAmlScenarioRule rul  
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus clLink ON clLink.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId  
 INNER JOIN dbo.RefClientStatus clStatus ON clStatus.RefClientStatusId = clLink.RefClientStatusId  
 WHERE RefAmlReportId = @ReportIdInternal  
  
 SELECT DISTINCT  
  trade.RefClientId,  
  cl.AccountOpeningDate  
 INTO #allClients  
 FROM dbo.CoreTrade trade  
 INNER JOIN #segments seg ON trade.RefSegmentId = RefSegmentEnumId  
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
 INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = inst.RefInstrumentTypeId  
 INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId  
 INNER JOIN #clientStatus stat ON cl.RefClientStatusId = stat.RefClientStatusId  
 WHERE trade.TradeDate = @RunDateInternal   
  AND NOT EXISTS(SELECT 1 FROM #clientsToExclude clEx  
   WHERE clEx.RefClientId = trade.RefClientId)  
  
  
 SELECT  
  RefClientId,  
  DATEDIFF(DAY, TradeDate, @RunDateInternal) AS NoOfDays  
 INTO #lastTrade  
 FROM (SELECT   
   trade.RefClientId,  
   trade.TradeDate,  
   ROW_NUMBER() OVER (PARTITION BY trade.RefClientId ORDER BY trade.TradeDate DESC) AS RN  
  FROM #allClients cl  
  INNER JOIN dbo.CoreTrade trade ON cl.RefClientId = trade.RefClientId  
  WHERE trade.TradeDate < @RunDateInternal  
 ) t  
 WHERE t.RN = 1  
  
 SELECT  
  al.RefClientId,  
  CASE WHEN lt.NoOfDays IS NULL  
  THEN 0  
  ELSE lt.NoOfDays END AS NoOfDays  
 INTO #finalClients  
 FROM #allClients al  
 LEFT JOIN #lastTrade lt ON al.RefClientId = lt.RefClientId  
 WHERE lt.NoOfDays IS NULL OR lt.NoOfDays > @DormantDays  
  OR (al.AccountOpeningDate IS NOT NULL AND al.AccountOpeningDate >= @FromDate)  
  
  
 DROP TABLE #allClients  
 DROP TABLE #lastTrade  
  
 SELECT  
  cl.RefClientId,  
  rules.RefInstrumentTypeId,  
  trade.RefInstrumentId,  
  CASE WHEN trade.BuySell = 'Buy'  
  THEN 1 ELSE 0 END AS BuySell,  
  trade.RefSegmentId,  
  CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)  
  THEN trade.Quantity * ISNULL(inst.ContractSize, 1)  
  ELSE trade.Quantity END AS Quantity,  
  CASE WHEN inst.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId)  
   THEN (ISNULL(inst.StrikePrice, 0) + trade.Rate) * trade.Quantity  
   WHEN inst.RefInstrumentTypeId = @OPTCURId  
   THEN (ISNULL(inst.StrikePrice, 0) + trade.Rate) * trade.Quantity * ISNULL(inst.ContractSize, 1)  
   WHEN inst.RefInstrumentTypeId = @FUTCURId  
   THEN trade.Rate * trade.Quantity * ISNULL(inst.ContractSize, 1)  
   ELSE trade.Rate * trade.Quantity END AS TurnOver  
 INTO #tradeData  
 FROM #finalClients cl  
 INNER JOIN dbo.CoreTrade trade ON cl.RefClientId = trade.RefClientId  
 INNER JOIN #segments seg ON trade.RefSegmentId = RefSegmentEnumId  
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
 INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = inst.RefInstrumentTypeId  
 WHERE trade.TradeDate = @RunDateInternal  
  AND inst.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTCURId, @OPTIRCId, @FUTIDXId, @FUTSTKId,  
   @FUTIRDId, @FUTIRTId, @FUTCURId, @FUTIRCId, @FUTIVXId, @FUTIRFId)  
  
 SELECT  
  RefClientId,  
  RefInstrumentTypeId,  
  RefInstrumentId,  
  RefSegmentId,  
  SUM(TurnOver) AS BuyTO,  
  SUM(Quantity) AS BuyQty  
 INTO #BuyData  
 FROM #tradeData  
 WHERE BuySell = 1  
 GROUP BY RefClientId, RefInstrumentTypeId, RefInstrumentId, RefSegmentId  
  
 SELECT  
  RefClientId,  
  RefInstrumentTypeId,  
  RefInstrumentId,  
  RefSegmentId,  
  SUM(TurnOver) AS SellTO,  
  SUM(Quantity) AS SellQty  
 INTO #SellData  
 FROM #tradeData  
 WHERE BuySell = 0  
 GROUP BY RefClientId, RefInstrumentTypeId, RefInstrumentId, RefSegmentId  
  
 DROP TABLE #tradeData  
  
 SELECT  
  COALESCE(cl.RefClientId, scl.RefClientId) AS RefClientId,  
  COALESCE(buy.RefSegmentId, sell.RefSegmentId) AS RefSegmentId,  
  inst.[Name] + '-'  + '<IT>-' +           
   CASE WHEN inst.ExpiryDate IS NULL THEN ''  
   ELSE CONVERT(VARCHAR(100), inst.ExpiryDate, 106) END + '-' +   
   ISNULL(inst.PutCall, '') + '-' +   
   ISNULL(CONVERT(VARCHAR(100), inst.StrikePrice), '') AS ScripTypeExpDtPutCallStrikePrice,  
  CASE WHEN ISNULL(sell.SellQty, 0) > ISNULL(buy.BuyQty, 0)  
   THEN 'Sell'  
   ELSE 'Buy' END AS BuySell,  
  ISNULL(buy.BuyQty, 0) AS BuyQty,  
  CASE WHEN buy.BuyQty IS NULL OR buy.BuyQty = 0 OR buy.BuyTO IS NULL  
   THEN 0  
   ELSE buy.BuyTO / buy.BuyQty END AS BuyAvgRate,  
  ISNULL(buy.BuyTO, 0) AS BuyTO,  
  ISNULL(sell.SellQty, 0) AS SellQty,  
  CASE WHEN sell.SellQty IS NULL OR sell.SellQty = 0 OR sell.SellTO IS NULL  
   THEN 0  
   ELSE sell.SellTO / sell.SellQty END AS SellAvgRate,  
  ISNULL(sell.SellTO, 0) AS SellTO,  
  (ISNULL(sell.SellTO, 0) + ISNULL(buy.BuyTO, 0)) AS TotalTO,  
  CASE WHEN ISNULL(sell.SellQty, 0) > ISNULL(buy.BuyQty, 0)  
  THEN (sell.SellQty * 100) / (bhav.NumberOfShares * inst.ContractSize)  
  ELSE (buy.BuyQty * 100) / (bhav.NumberOfShares * inst.ContractSize) END AS ScripPercvizExchQty,  
  CASE WHEN ISNULL(sell.SellTO, 0) > ISNULL(buy.BuyTO, 0)  
  THEN sell.SellTO * 100 / bhav.NetTurnOver   
  ELSE buy.BuyTO * 100 / bhav.NetTurnOver END AS ScripPercvizExchTO,  
  COALESCE(cl.NoOfDays, scl.NoOfDays) AS NoOfDays,  
  (bhav.NumberOfShares * inst.ContractSize) AS ExchangeQty,  
  bhav.NetTurnOver AS ExchangeTO,  
  COALESCE(buy.RefInstrumentTypeId, sell.RefInstrumentTypeId) AS RefInstrumentTypeId,  
  inst.RefInstrumentId  
 INTO #finalData  
 FROM #finalClients cl   
 LEFT JOIN #BuyData buy ON cl.RefClientId = buy.RefClientId  
 FULL JOIN #SellData sell ON sell.RefClientId = buy.RefClientId   
  AND buy.RefInstrumentId = sell.RefInstrumentId AND buy.RefSegmentId = sell.RefSegmentId  
 LEFT JOIN #finalClients scl ON buy.RefClientId IS NULL AND scl.RefClientId = sell.RefClientId  
 INNER JOIN dbo.RefInstrument inst ON COALESCE(buy.RefInstrumentId, sell.RefInstrumentId) = inst.RefInstrumentId  
 INNER JOIN dbo.CoreBhavCopy bhav ON inst.RefInstrumentId = bhav.RefInstrumentId  
 WHERE bhav.[Date] = @RunDateInternal  
  
 DROP TABLE #finalClients  
 DROP TABLE #BuyData  
 DROP TABLE #SellData  
  
 SELECT  
  fd.RefClientId,  
  cl.ClientId,  
  cl.[Name] AS ClientName,  
  seg.RefSegmentEnumId AS SegmentId,  
  seg.Segment,  
  @RunDateInternal AS TradeDate,  
  fd.BuySell,  
  rules.InstrumentType,  
  REPLACE(fd.ScripTypeExpDtPutCallStrikePrice, '<IT>', ISNULL(rules.InstrumentType, '')) AS InstrumentInfo,  
  fd.BuyQty,  
  CONVERT(DECIMAL(28, 2), fd.BuyAvgRate) AS BuyAvgRate,  
  CONVERT(DECIMAL(28, 2), fd.BuyTO) AS BuyTO,  
  fd.SellQty,  
  CONVERT(DECIMAL(28, 2), fd.SellAvgRate) AS SellAvgRate,  
  CONVERT(DECIMAL(28, 2), fd.SellTO) AS SellTO,  
  CONVERT(DECIMAL(28, 2), fd.TotalTO) AS TotalTO,  
  CONVERT(DECIMAL(28, 2), fd.ScripPercvizExchQty) AS ScripPercvizExchQty,  
  CONVERT(DECIMAL(28, 2), fd.ScripPercvizExchTO) AS ScripPercvizExchTO,  
  fd.NoOfDays,  
  fd.ExchangeQty,  
  CONVERT(DECIMAL(28, 2), fd.ExchangeTO) AS ExchangeTO,  
  fd.RefInstrumentId  
 FROM #finalData fd  
 INNER JOIN dbo.RefClient cl ON fd.RefClientId = cl.RefClientId  
 INNER JOIN #segments seg ON fd.RefSegmentId = seg.RefSegmentEnumId  
 INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = fd.RefInstrumentTypeId  
 WHERE fd.ScripPercvizExchQty >= rules.Threshold  
  AND fd.ScripPercvizExchTO >= rules.Threshold2  
  AND fd.TotalTO >= rules.Threshold3  
 ORDER BY fd.RefClientId, fd.RefSegmentId, fd.RefInstrumentTypeId  
  
END  
GO
------RC-WEB-66688 END

GO
ALTER PROCEDURE [dbo].[AML_GetHighTurnoverbyNewClientin1DayFNO] (
	@RunDate DATETIME,
	@ReportId INT
)
AS
BEGIN
	DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @FromDate DATETIME, 
		@DormantDays INT, @OPTSTKId INT, @OPTIDXId INT, @OPTCURId INT, @OPTIRCId INT, 
		@FUTIDXId INT, @FUTSTKId INT, @FUTIRDId INT, @FUTIRTId INT, @FUTCURId INT,
		@FUTIRCId INT, @FUTIVXId INT, @FUTIRFId INT

	SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)
	SET @ReportIdInternal = @ReportId
	SELECT @DormantDays = CONVERT(INT, [Value]) FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal
	SET @FromDate = DATEADD(d, -@DormantDays, @RunDateInternal)
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

	SELECT 
		RefSegmentEnumId,
		Segment
	INTO #segments
	FROM dbo.RefSegmentEnum WHERE Code IN ('NSE_FNO', 'NSE_CDX')

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
		instType.InstrumentType,
		instType.RefInstrumentTypeId
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule rul
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId
	INNER JOIN dbo.RefInstrumentType instType ON instType.RefInstrumentTypeId = link.RefInstrumentTypeId
	WHERE rul.RefAmlReportId = @ReportIdInternal 
		AND instType.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTCURId, @OPTIRCId, @FUTIDXId, @FUTSTKId,
			@FUTIRDId, @FUTIRTId, @FUTCURId, @FUTIRCId, @FUTIVXId, @FUTIRFId)

	SELECT
		clStatus.[Name] AS ClientStatus,
		clStatus.RefClientStatusId
	INTO #clientStatus
	FROM dbo.RefAmlScenarioRule rul
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus clLink ON clLink.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId
	INNER JOIN dbo.RefClientStatus clStatus ON clStatus.RefClientStatusId = clLink.RefClientStatusId
	WHERE RefAmlReportId = @ReportIdInternal

	SELECT DISTINCT
		trade.RefClientId,
		cl.AccountOpeningDate
	INTO #allClients
	FROM dbo.CoreTrade trade
	INNER JOIN #segments seg ON trade.RefSegmentId = RefSegmentEnumId
	INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId
	INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = inst.RefInstrumentTypeId
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId
	INNER JOIN #clientStatus stat ON cl.RefClientStatusId = stat.RefClientStatusId
	WHERE trade.TradeDate = @RunDateInternal 
		AND NOT EXISTS(SELECT 1 FROM #clientsToExclude clEx
			WHERE clEx.RefClientId = trade.RefClientId)


	SELECT
		RefClientId,
		DATEDIFF(DAY, TradeDate, @RunDateInternal) AS NoOfDays
	INTO #lastTrade
	FROM (SELECT 
			trade.RefClientId,
			trade.TradeDate,
			ROW_NUMBER() OVER (PARTITION BY trade.RefClientId ORDER BY trade.TradeDate DESC) AS RN
		FROM #allClients cl
		INNER JOIN dbo.CoreTrade trade ON cl.RefClientId = trade.RefClientId
		WHERE trade.TradeDate < @RunDateInternal
	) t
	WHERE t.RN = 1

	SELECT
		al.RefClientId,
		CASE WHEN lt.NoOfDays IS NULL
		THEN 0
		ELSE lt.NoOfDays END AS NoOfDays
	INTO #finalClients
	FROM #allClients al
	LEFT JOIN #lastTrade lt ON al.RefClientId = lt.RefClientId
	WHERE lt.NoOfDays IS NULL OR lt.NoOfDays > @DormantDays
		OR (al.AccountOpeningDate IS NOT NULL AND al.AccountOpeningDate >= @FromDate)


	DROP TABLE #allClients
	DROP TABLE #lastTrade

	SELECT
		cl.RefClientId,
		rules.RefInstrumentTypeId,
		trade.RefInstrumentId,
		CASE WHEN trade.BuySell = 'Buy'
		THEN 1 ELSE 0 END AS BuySell,
		trade.RefSegmentId,
		CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)
		THEN trade.Quantity * ISNULL(inst.ContractSize, 1)
		ELSE trade.Quantity END AS Quantity,
		CASE WHEN inst.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId)
			THEN (ISNULL(inst.StrikePrice, 0) + trade.Rate) * trade.Quantity
			WHEN inst.RefInstrumentTypeId = @OPTCURId
			THEN (ISNULL(inst.StrikePrice, 0) + trade.Rate) * trade.Quantity * ISNULL(inst.ContractSize, 1)
			WHEN inst.RefInstrumentTypeId = @FUTCURId
			THEN trade.Rate * trade.Quantity * ISNULL(inst.ContractSize, 1)
			ELSE trade.Rate * trade.Quantity END AS TurnOver
	INTO #tradeData
	FROM #finalClients cl
	INNER JOIN dbo.CoreTrade trade ON cl.RefClientId = trade.RefClientId
	INNER JOIN #segments seg ON trade.RefSegmentId = RefSegmentEnumId
	INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId
	INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = inst.RefInstrumentTypeId
	WHERE trade.TradeDate = @RunDateInternal
		AND inst.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTCURId, @OPTIRCId, @FUTIDXId, @FUTSTKId,
			@FUTIRDId, @FUTIRTId, @FUTCURId, @FUTIRCId, @FUTIVXId, @FUTIRFId)

	SELECT
		RefClientId,
		RefInstrumentTypeId,
		RefInstrumentId,
		RefSegmentId,
		SUM(TurnOver) AS BuyTO,
		SUM(Quantity) AS BuyQty
	INTO #BuyData
	FROM #tradeData
	WHERE BuySell = 1
	GROUP BY RefClientId, RefInstrumentTypeId, RefInstrumentId, RefSegmentId

	SELECT
		RefClientId,
		RefInstrumentTypeId,
		RefInstrumentId,
		RefSegmentId,
		SUM(TurnOver) AS SellTO,
		SUM(Quantity) AS SellQty
	INTO #SellData
	FROM #tradeData
	WHERE BuySell = 0
	GROUP BY RefClientId, RefInstrumentTypeId, RefInstrumentId, RefSegmentId

	DROP TABLE #tradeData

	SELECT
		COALESCE(cl.RefClientId, scl.RefClientId) AS RefClientId,
		COALESCE(buy.RefSegmentId, sell.RefSegmentId) AS RefSegmentId,
		inst.[Name] + '-'  + '<IT>-' + 							 
			CASE WHEN inst.ExpiryDate IS NULL THEN ''
			ELSE CONVERT(VARCHAR(100), inst.ExpiryDate, 106) END + '-' + 
			ISNULL(inst.PutCall, '') + '-' + 
			ISNULL(CONVERT(VARCHAR(100), inst.StrikePrice), '') AS ScripTypeExpDtPutCallStrikePrice,
		CASE WHEN ISNULL(sell.SellQty, 0) > ISNULL(buy.BuyQty, 0)
			THEN 'Sell'
			ELSE 'Buy' END AS BuySell,
		ISNULL(buy.BuyQty, 0) AS BuyQty,
		CASE WHEN buy.BuyQty IS NULL OR buy.BuyQty = 0 OR buy.BuyTO IS NULL
			THEN 0
			ELSE buy.BuyTO / buy.BuyQty END AS BuyAvgRate,
		ISNULL(buy.BuyTO, 0) AS BuyTO,
		ISNULL(sell.SellQty, 0) AS SellQty,
		CASE WHEN sell.SellQty IS NULL OR sell.SellQty = 0 OR sell.SellTO IS NULL
			THEN 0
			ELSE sell.SellTO / sell.SellQty END AS SellAvgRate,
		ISNULL(sell.SellTO, 0) AS SellTO,
		(ISNULL(sell.SellTO, 0) + ISNULL(buy.BuyTO, 0)) AS TotalTO,
		CASE WHEN ISNULL(sell.SellQty, 0) > ISNULL(buy.BuyQty, 0)
		THEN (sell.SellQty * 100) / (bhav.NumberOfShares * inst.ContractSize)
		ELSE (buy.BuyQty * 100) / (bhav.NumberOfShares * inst.ContractSize) END AS ScripPercvizExchQty,
		CASE WHEN ISNULL(sell.SellTO, 0) > ISNULL(buy.BuyTO, 0)
		THEN sell.SellTO * 100 / bhav.NetTurnOver 
		ELSE buy.BuyTO * 100 / bhav.NetTurnOver END AS ScripPercvizExchTO,
		COALESCE(cl.NoOfDays, scl.NoOfDays) AS NoOfDays,
		(bhav.NumberOfShares * inst.ContractSize) AS ExchangeQty,
		bhav.NetTurnOver AS ExchangeTO,
		COALESCE(buy.RefInstrumentTypeId, sell.RefInstrumentTypeId) AS RefInstrumentTypeId,
		inst.RefInstrumentId
	INTO #finalData
	FROM #finalClients cl 
	LEFT JOIN #BuyData buy ON cl.RefClientId = buy.RefClientId
	FULL JOIN #SellData sell ON sell.RefClientId = buy.RefClientId 
		AND buy.RefInstrumentId = sell.RefInstrumentId AND buy.RefSegmentId = sell.RefSegmentId
	LEFT JOIN #finalClients scl ON buy.RefClientId IS NULL AND scl.RefClientId = sell.RefClientId
	INNER JOIN dbo.RefInstrument inst ON COALESCE(buy.RefInstrumentId, sell.RefInstrumentId) = inst.RefInstrumentId
	INNER JOIN dbo.CoreBhavCopy bhav ON inst.RefInstrumentId = bhav.RefInstrumentId
	WHERE bhav.[Date] = @RunDateInternal

	DROP TABLE #finalClients
	DROP TABLE #BuyData
	DROP TABLE #SellData

	SELECT
		fd.RefClientId,
		cl.ClientId,
		cl.[Name] AS ClientName,
		seg.RefSegmentEnumId AS SegmentId,
		seg.Segment,
		@RunDateInternal AS TradeDate,
		fd.BuySell,
		rules.InstrumentType,
		REPLACE(fd.ScripTypeExpDtPutCallStrikePrice, '<IT>', ISNULL(rules.InstrumentType, '')) AS InstrumentInfo,
		fd.BuyQty,
		CONVERT(DECIMAL(28, 2), fd.BuyAvgRate) AS BuyAvgRate,
		CONVERT(DECIMAL(28, 2), fd.BuyTO) AS BuyTO,
		fd.SellQty,
		CONVERT(DECIMAL(28, 2), fd.SellAvgRate) AS SellAvgRate,
		CONVERT(DECIMAL(28, 2), fd.SellTO) AS SellTO,
		CONVERT(DECIMAL(28, 2), fd.TotalTO) AS TotalTO,
		CONVERT(DECIMAL(28, 2), fd.ScripPercvizExchQty) AS ScripPercvizExchQty,
		CONVERT(DECIMAL(28, 2), fd.ScripPercvizExchTO) AS ScripPercvizExchTO,
		fd.NoOfDays,
		fd.ExchangeQty,
		CONVERT(DECIMAL(28, 2), fd.ExchangeTO) AS ExchangeTO,
		fd.RefInstrumentId
	FROM #finalData fd
	INNER JOIN dbo.RefClient cl ON fd.RefClientId = cl.RefClientId
	INNER JOIN #segments seg ON fd.RefSegmentId = seg.RefSegmentEnumId
	INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = fd.RefInstrumentTypeId
	WHERE fd.ScripPercvizExchQty >= rules.Threshold
		AND fd.ScripPercvizExchTO >= rules.Threshold2
		AND fd.TotalTO >= rules.Threshold3
	ORDER BY fd.RefClientId, fd.RefSegmentId, fd.RefInstrumentTypeId

END
GO