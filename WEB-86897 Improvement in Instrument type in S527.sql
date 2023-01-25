--File:StoredProcedures:dbo:AML_GetIntraDayProfitOrLossCompareToExchangeIn1DayCommodity
--START RC WEB-86897
GO
ALTER PROCEDURE dbo.AML_GetIntraDayProfitOrLossCompareToExchangeIn1DayCommodity
(
	@RunDate DATETIME,
	@ReportId INT
)
AS
BEGIN
	DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @NCDEX_FNOId INT, @MCX_FNOId INT,
			@FUTCOM VARCHAR(20), @OPTCOM VARCHAR(20), @FUTCOMId INT, @OPTCOMId INT,
			@Threshold1DisplayName VARCHAR(MAX), @Threshold2DisplayName VARCHAR(MAX), @Threshold3DisplayName VARCHAR(MAX),
			@Threshold4DisplayName VARCHAR(MAX), @Threshold5DisplayName VARCHAR(MAX), @OPTFUTId INT, @FUTIDXId INT


	SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)
	SET @ReportIdInternal = @ReportId

	SELECT @MCX_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'MCX_FNO'
	SELECT @NCDEX_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NCDEX_FNO'

	SELECT @Threshold1DisplayName  = Threshold1DisplayName FROM dbo.RefAmlReport WHERE RefAmlReportId = @ReportIdInternal
	SELECT @Threshold2DisplayName  = Threshold2DisplayName FROM dbo.RefAmlReport WHERE RefAmlReportId = @ReportIdInternal
	SELECT @Threshold3DisplayName  = Threshold3DisplayName FROM dbo.RefAmlReport WHERE RefAmlReportId = @ReportIdInternal
	SELECT @Threshold4DisplayName  = Threshold4DisplayName FROM dbo.RefAmlReport WHERE RefAmlReportId = @ReportIdInternal
	SELECT @Threshold5DisplayName  = Threshold5DisplayName FROM dbo.RefAmlReport WHERE RefAmlReportId = @ReportIdInternal

	SET @FUTCOM = 'FUTCOM'
	SET @OPTCOM = 'OPTCOM'

	SELECT @FUTCOMId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = @FUTCOM
	SELECT @OPTCOMId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = @OPTCOM
	SELECT @OPTFUTId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTFUT'
	SELECT @FUTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIDX'
	

	SELECT
		DISTINCT
		RefClientId
	INTO #clientsToExclude
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion
	WHERE (RefAmlReportId = @ReportIdInternal OR ExcludeAllScenarios=1)
		AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)


	SELECT
		trade.RefClientId,
		trade.RefSegmentId,
		trade.RefInstrumentId,
		CASE WHEN trade.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell,
		trade.Quantity,
		trade.Rate,
		inst.ContractSize,
		CASE 
			WHEN trade.RefSegmentId = @MCX_FNOId THEN trade.Quantity*trade.Rate*ISNULL(inst.ContractSize,1) 
			ELSE trade.Quantity*trade.Rate END 
		AS TurnOver,
		trade.TradeId,				-- for sync
		trade.TradeIdAlphaNumeric,	-- for sync
		inst.RefInstrumentTypeId
	INTO #TradeData
	FROM dbo.CoreTrade trade
	INNER JOIN dbo.RefInstrument inst ON (inst.RefInstrumentId = trade.RefInstrumentId 
		AND inst.RefInstrumentTypeId IN (@OPTCOMId, @FUTCOMId, @OPTFUTId, @FUTIDXId))
	LEFT JOIN #clientsToExclude exclude ON exclude.RefClientId = trade.RefClientId
	WHERE (trade.RefSegmentId = @NCDEX_FNOId OR trade.RefSegmentId = @MCX_FNOId) AND trade.TradeDate = @RunDateInternal
	AND exclude.RefClientId IS NULL

	-- Intraday and Non-intraday combine
	SELECT
		trade.RefClientId,
		trade.RefSegmentId,
		trade.RefInstrumentId,
		CASE WHEN trade.BuySell = 1 THEN SUM(trade.Quantity) ELSE 0 END AS BuyQty,
		CASE WHEN trade.BuySell = 0 THEN SUM(trade.Quantity) ELSE 0 END AS SellQty,
		CASE WHEN trade.BuySell = 1 THEN SUM(trade.TurnOver) ELSE 0 END AS BuyTo,
		CASE WHEN trade.BuySell = 0 THEN SUM(trade.TurnOver) ELSE 0 END AS SellTo,
		CASE WHEN trade.RefInstrumentTypeId IN (@OPTCOMId, @OPTFUTId) THEN SUM(trade.TurnOver) ELSE 0 END AS OptTo,
		CASE WHEN trade.RefInstrumentTypeId IN (@FUTCOMId, @FUTIDXId) THEN SUM(trade.TurnOver) ELSE 0 END AS FutTo
	INTO #BuySellData
	FROM #TradeData trade
	GROUP BY trade.RefClientId, trade.RefSegmentId, trade.RefInstrumentId, trade.BuySell, trade.RefInstrumentTypeId

	SELECT
		bs.RefClientId,
		bs.RefSegmentId,
		bs.RefInstrumentId,
		SUM(bs.BuyQty) AS BuyQty,
		SUM(bs.SellQty) AS SellQty,
		SUM(bs.BuyTo) AS BuyTo,
		SUM(bs.SellTo) AS SellTo,
		SUM(bs.OptTO) AS OptTo,
		SUM(bs.FutTo) AS FutTo
	INTO #ClientWiseData
	FROM #BuySellData bs
	GROUP BY bs.RefClientId, bs.RefSegmentId, bs.RefInstrumentId

	DROP TABLE #BuySellData

	SELECT
		cd.*,
		CASE WHEN ISNULL(cd.BuyQty,0) = 0 THEN 0 ELSE(cd.BuyTo/cd.BuyQty) END AS BuyAvgRate,
		CASE WHEN ISNULL(cd.SellQty,0) = 0 THEN 0 ELSE(cd.SellTo/cd.SellQty) END AS SellAvgRate,
		CASE
			WHEN cd.SellQty = 0 OR cd.BuyQty = 0 THEN NULL
			WHEN cd.BuyQty < cd.SellQty THEN cd.BuyQty
			ELSE cd.SellQty END AS IntraDayQty
	INTO #DataWithIntraDay
	FROM #ClientWiseData cd

	DROP TABLE #ClientWiseData

	SELECT
		intra.*,
		CASE 
			WHEN intra.IntraDayQty IS NOT NULL THEN intra.IntraDayQty*intra.BuyAvgRate + intra.IntraDayQty*intra.SellAvgRate
			ELSE NULL
		END AS IntraDayTO,
		bhav.NumberOfShares AS ExchangeQty,
		bhav.NetTurnOver AS ExchangeTO,
		bhav.[Open],
		bhav.High,
		bhav.Low,
		bhav.[Close],
		CASE 
			WHEN intra.BuyQty = 0 THEN (intra.SellQty*100)/bhav.NumberOfShares
			WHEN intra.SellQty = 0 THEN (intra.BuyQty*100)/bhav.NumberOfShares
			WHEN (intra.BuyQty < intra.SellQty) THEN (intra.BuyQty*100)/bhav.NumberOfShares
			ELSE (intra.SellQty*100)/bhav.NumberOfShares
		END AS ClientToExchange,
		CASE 
			WHEN intra.IntraDayQty IS NOT NULL THEN(intra.IntraDayQty*intra.SellAvgRate - intra.IntraDayQty*intra.BuyAvgRate) 
			ELSE NULL
		END AS ProfitLoss
	INTO #FinalData
	FROM #DataWithIntraDay intra
	INNER JOIN dbo.CoreBhavCopy bhav ON bhav.RefInstrumentId = intra.RefInstrumentId 
		AND bhav.RefSegmentId = intra.RefSegmentId AND bhav.[Date] = @RunDateInternal
	
	DROP TABLE #DataWithIntraDay

	SELECT
		rules.Threshold,
		rules.Threshold2,
		rules.Threshold3,
		rules.Threshold4,
		rules.Threshold5,
		rules.Threshold6
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule rules
	WHERE rules.RefAmlReportId = @ReportIdInternal


	CREATE TABLE #AlertData
	(
		RefClientId INT NOT NULL,
		RefInstrumentId INT NOT NULL,
		RefSegmentId INT NOT NULL,
		OppositeRefClientId INT,
		BuyQty INT,
		BuyTo DECIMAL(28, 2),
		BuyAvgRate DECIMAL(28, 2),
		SellQty INT,
		SellTo DECIMAL(28, 2),
		SellAvgRate DECIMAL(28, 2),
		IntraDayTo DECIMAL(28, 2),
		IntraDayQty INT,
		ProfitLoss DECIMAL(28, 2),
		Threshold VARCHAR(MAX) COLLATE DATABASE_DEFAULT,
		OPTTo DECIMAL(28, 2),
		FUTTo DECIMAL(28, 2),
		ExchangePercentage DECIMAL(28, 2),
		[Open] DECIMAL(28, 2),
		High DECIMAL(28, 2),
		Low DECIMAL(28, 2),
		[Close] DECIMAL(28, 2),
		ExchangeTO DECIMAL(28, 2),
		ExchangeQty BIGINT,
		SyncTo DECIMAL(28, 2)

	)

	INSERT INTO #AlertData
	(
		RefClientId,
		RefInstrumentId,
		RefSegmentId,
		BuyQty,
		BuyTo,
		BuyAvgRate,
		SellQty,
		SellTo,
		SellAvgRate,
		IntraDayTo,
		IntraDayQty,
		ProfitLoss,
		Threshold,
		OPTTo,
		FUTTo,
		ExchangePercentage,
		[Open],
		High,
		Low,
		[Close],
		ExchangeQty,
		ExchangeTO
	)
	SELECT
		fd.RefClientId,
		fd.RefInstrumentId,
		fd.RefSegmentId,
		fd.BuyQty,
		fd.BuyTo,
		fd.BuyAvgRate,
		fd.SellQty,
		fd.SellTo,
		fd.SellAvgRate,
		fd.IntraDayTO,
		fd.IntraDayQty,
		fd.ProfitLoss,
		CASE WHEN rules.Threshold <> 0  THEN ', '+@Threshold1DisplayName + ' - '+ CONVERT(VARCHAR(MAX),rules.Threshold) ELSE '' END
		+ CASE WHEN rules.Threshold2 <> 0  THEN ', '+@Threshold2DisplayName + ' - '+ CONVERT(VARCHAR(MAX),rules.Threshold2) ELSE '' END 
		+ CASE WHEN rules.Threshold3 <> 0  THEN ', '+@Threshold3DisplayName + ' - '+ CONVERT(VARCHAR(MAX),rules.Threshold3) ELSE '' END
		+ CASE WHEN rules.Threshold4 <> 0  THEN ', '+@Threshold4DisplayName + ' - '+ CONVERT(VARCHAR(MAX),rules.Threshold4) ELSE '' END,
		fd.OptTo,
		fd.FutTo,
		fd.ClientToExchange,
		fd.[Open],
		fd.High,
		fd.Low,
		fd.[Close],
		fd.ExchangeQty,
		fd.ExchangeTO
	FROM #FinalData fd
	INNER JOIN #scenarioRules rules ON rules.Threshold6 LIKE '%1' OR rules.Threshold6 like '%2'		-- Rules for intraday
	WHERE (rules.Threshold <> 0 OR rules.Threshold2 <> 0 OR rules.Threshold3 <> 0 OR rules.Threshold4<>0) 
		AND fd.OptTo >= rules.Threshold2 AND fd.FutTo >= rules.Threshold AND ABS(fd.ProfitLoss) >=  rules.Threshold3 
		AND fd.ClientToExchange >= rules.Threshold4
	

	INSERT INTO #AlertData
	(
		RefClientId,
		RefInstrumentId,
		RefSegmentId,
		BuyQty,
		BuyTo,
		BuyAvgRate,
		SellQty,
		SellTo,
		SellAvgRate,
		Threshold,
		OPTTo,
		FUTTo,
		ExchangePercentage,
		[Open],
		High,
		Low,
		[Close],
		ExchangeQty,
		ExchangeTO
	)
	SELECT
		fd.RefClientId,
		fd.RefInstrumentId,
		fd.RefSegmentId,
		fd.BuyQty,
		fd.BuyTo,
		fd.BuyAvgRate,
		fd.SellQty,
		fd.SellTo,
		fd.SellAvgRate,
		CASE WHEN rules.Threshold <> 0  THEN ', '+@Threshold1DisplayName + ' - '+ CONVERT(VARCHAR(MAX),rules.Threshold) ELSE '' END
		+ CASE WHEN rules.Threshold2 <> 0  THEN ', '+@Threshold2DisplayName + ' - '+ CONVERT(VARCHAR(MAX),rules.Threshold2) ELSE '' END
		+ CASE WHEN rules.Threshold4 <> 0  THEN ', '+@Threshold4DisplayName + ' - '+ CONVERT(VARCHAR(MAX),rules.Threshold4) ELSE '' END,
		fd.OptTo,
		fd.FutTo,
		fd.ClientToExchange,
		fd.[Open],
		fd.High,
		fd.Low,
		fd.[Close],
		fd.ExchangeQty,
		fd.ExchangeTO
	FROM #FinalData fd
	INNER JOIN #scenarioRules rules ON rules.Threshold6 LIKE '%3' OR rules.Threshold6 like '%4'		-- Rules for non intraday
	WHERE 
		(rules.Threshold <> 0 OR rules.Threshold2 <> 0 OR rules.Threshold4<>0)
		 AND fd.OptTo >= rules.Threshold2 AND fd.FutTo >= rules.Threshold AND fd.ClientToExchange >= rules.Threshold4

	DROP TABLE #FinalData

	/*****************		SYNC LOGIC		*****************/
	SELECT
		td.RefClientId,
		td.RefSegmentId,
		td.RefInstrumentId,
		CASE WHEN td.BuySell = 1 THEN td.Quantity ELSE 0 END AS BuyQty,
		CASE WHEN td.BuySell = 0 THEN td.Quantity ELSE 0 END AS SellQty,
		CASE WHEN td.BuySell = 1 THEN td.TurnOver ELSE 0 END AS BuyTo,
		CASE WHEN td.BuySell = 0 THEN td.TurnOver ELSE 0 END AS SellTo,
		td2.RefClientId AS OppRefClientId
	INTO #SyncBuySell
	FROM #TradeData td
	INNER JOIN #TradeData td2 ON td2.RefInstrumentId = td.RefInstrumentId AND td2.RefSegmentId = td.RefSegmentId 
		AND ( (td.RefSegmentId = @NCDEX_FNOId AND td2.TradeIdAlphaNumeric = td.TradeIdAlphaNumeric) OR (td.RefSegmentId <> @NCDEX_FNOId AND td2.TradeId = td.TradeId))
		AND td2.BuySell <> td.BuySell

	DROP TABLE #TradeData

	SELECT
		bs.RefClientId,
		bs.RefSegmentId,
		bs.RefInstrumentId,
		bs.OppRefClientId,
		SUM(bs.BuyQty) AS BuyQty,
		SUM(bs.SellQty) AS SellQty,
		SUM(bs.BuyTo) AS BuyTo,
		SUM(bs.SellTo) AS SellTo
		/*bs.BuyQty,
		bs.SellQty,
		bs.BuyTo,
		bs.SellTo*/
	INTO #SyncClientWiseData
	FROM #SyncBuySell bs
	GROUP BY bs.RefClientId, bs.RefSegmentId, bs.RefInstrumentId,
		bs.OppRefClientId
	
	DROP TABLE #SyncBuySell

	INSERT INTO #AlertData
	(
		RefClientId,
		RefInstrumentId,
		RefSegmentId,
		OppositeRefClientId,
		BuyQty,
		BuyTo ,
		BuyAvgRate,
		SellQty,
		SellTo,
		SellAvgRate,
		Threshold,
		ExchangePercentage,
		[Open],
		High,
		Low,
		[Close],
		ExchangeTO,
		ExchangeQty,
		SyncTo
	)
	SELECT
		client.RefClientId,
		client.RefInstrumentId,
		client.RefSegmentId,
		client.OppRefClientId,
		client.BuyQty,
		client.BuyTo,
		CASE WHEN ISNULL(client.BuyQty,0) = 0 THEN 0 ELSE (client.BuyTo/client.BuyQty) END AS BuyAvgRate,
		client.SellQty,
		client.SellTo,
		CASE WHEN ISNULL(client.SellQty,0) = 0 THEN 0 ELSE (client.SellTo/client.SellQty) END AS SellAvgRate,
		CASE WHEN rules.Threshold5 <> 0  THEN ', '+@Threshold5DisplayName + ' - '+ CONVERT(VARCHAR(MAX),rules.Threshold5) ELSE '' END,
		CASE 
			WHEN client.BuyQty = 0 THEN (client.SellQty*100)/bhav.NumberOfShares
			WHEN client.SellQty = 0 THEN (client.BuyQty*100)/bhav.NumberOfShares
			WHEN (client.BuyQty < client.SellQty) THEN (client.BuyQty*100)/bhav.NumberOfShares
			ELSE (client.SellQty*100)/bhav.NumberOfShares END,
		bhav.[Open],
		bhav.High,
		bhav.Low,
		bhav.[Close],
		bhav.NumberOfShares,
		bhav.NetTurnOver,
		client.BuyTo + client.SellTo
	FROM #SyncClientWiseData client
	INNER JOIN dbo.CoreBhavCopy bhav ON bhav.RefInstrumentId = client.RefInstrumentId
		AND bhav.RefSegmentId = client.RefSegmentId AND bhav.[Date] = @RunDateInternal
	INNER JOIN #scenarioRules rules ON rules.Threshold6 like '%5'
	WHERE rules.Threshold5 > 0 AND  (client.BuyTo + client.SellTo) >= rules.Threshold5

	DROP TABLE #SyncClientWiseData



	SELECT
		alerts.RefClientId,
		client.ClientId,
		client.[Name] AS ClientName,
		alerts.RefInstrumentId,
		alerts.RefSegmentId AS SegmentId,
		seg.Segment,
		@RunDateInternal AS TradeDate,
		inst.[Name] + ' - ' + instType.InstrumentType+ ' - '
			+ ISNULL(CONVERT(VARCHAR(MAX), inst.ExpiryDate, 106), ' ' )+ ' - ' + ISNULL(inst.PutCall,' ') + ' - '
			+ ISNULL(CONVERT(VARCHAR(MAX), CONVERT(INT,inst.StrikePrice)),' ') AS ScripDetails,
		alerts.BuyQty,
		CONVERT(DECIMAL(28, 2),alerts.BuyTo) AS BuyTo,
		CONVERT(DECIMAL(28, 2),alerts.BuyAvgRate) AS BuyAvgRate,
		alerts.SellQty,
		CONVERT(DECIMAL(28, 2), alerts.SellTo) AS SellTo,
		CONVERT(DECIMAL(28, 2), alerts.SellAvgRate) AS SellAvgRate,
		CASE WHEN alerts.IntraDayTo IS NOT NULL THEN CONVERT(DECIMAL(28, 2),alerts.IntraDayTo) ELSE NULL END AS IntraDayTo,
		alerts.IntraDayQty,
		CONVERT(DECIMAL(28, 2), alerts.ProfitLoss) AS ProfitLoss,
		CASE WHEN alerts.SyncTo IS NOT NULL THEN CONVERT(DECIMAL(28, 2),alerts.SyncTo) ELSE NULL END AS SyncTo,
		CONVERT(DECIMAL(28, 2), alerts.ExchangeTo) AS ExchangeTo,
		alerts.ExchangeQty,
		CONVERT(DECIMAL(28, 2),alerts.ExchangePercentage) AS ExchangePercentage,
		alerts.OppositeRefClientId,
		oppClient.ClientId AS OppClientId,
		oppClient.[Name] AS OppClientName,
		CONVERT(DECIMAL(28, 2), alerts.[Open]) AS [Open],
		CONVERT(DECIMAL(28, 2), alerts.High) AS High,
		CONVERT(DECIMAL(28, 2), alerts.Low) AS Low,
		CONVERT(DECIMAL(28, 2), alerts.[Close]) AS [Close],
		STUFF(alerts.Threshold,1,2,'' )AS [Description]
	FROM #AlertData alerts
	INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = alerts.RefInstrumentId
	INNER JOIN dbo.RefInstrumentType instType ON instType.RefInstrumentTypeId = inst.RefInstrumentTypeId
	INNER JOIN dbo.RefClient client ON client.RefClientId = alerts.RefClientId
	INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = alerts.RefSegmentId
	LEFT JOIN dbo.RefClient oppClient ON oppClient.RefClientId = alerts.OppositeRefClientId


END
GO
--END RC WEB-86897