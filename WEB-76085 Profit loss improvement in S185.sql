--WEB-76085 RC START
GO
ALTER PROCEDURE dbo.AML_GetConsistentIntradayProfitLossInACalendarMonth
(
	@RunDate DATETIME,
	@ReportId INT,
	@IsAlertDulicationAllowed BIT = 1
)
AS
BEGIN
	
	DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @IsAlertDulicationAllowedInternal BIT,
			@FirstDateOfMonth DATETIME, @LastDateOfMonth DATETIME, @Week1End DATETIME, @Week2End DATETIME, @Week3End DATETIME,
			@LastDateOfMonthWithOutTime DATETIME,
			@BSE_CASHId INT, @NSE_CASHId INT, @NSE_CDXId INT, @NSE_FNOId INT,
			@FUTIDX INT, @FUTSTK INT, @FUTIRD INT, @FUTIRT INT, @FUTCUR INT, @FUTIRC INT, @FUTIVX INT, @FUTIRF INT,
			@OPTIDX INT, @OPTSTK INT, @OPTCUR INT
			
	SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)
	SET @ReportIdInternal = @ReportId
	SET @IsAlertDulicationAllowedInternal = @IsAlertDulicationAllowed

	SET @FirstDateOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @RunDateInternal) -1, 0)
	SET @LastDateOfMonth = DATEADD(SECOND, -1, DATEADD(MONTH, 1,  DATEADD(MONTH, DATEDIFF(MONTH, 0, @RunDateInternal)-1 , 0)))
	SET @LastDateOfMonthWithOutTime = dbo.GetDateWithOutTime(@LastDateOfMonth)
	SET @Week1End = DATEADD(SECOND,-1,DATEADD(DAY, 7, @FirstDateOfMonth)) -- 7th date 23h 59m 59s
	SET @Week2End = DATEADD(DAY, 8, @Week1End) -- 15th date 23h 59m 59s
	SET @Week3End = DATEADD(DAY, 7, @Week2End) -- 22th date 23h 59m 59s

	SELECT @BSE_CASHId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code ='BSE_CASH'
	SELECT @NSE_CASHId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code ='NSE_CASH'
	SELECT @NSE_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code ='NSE_FNO'
	SELECT @NSE_CDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code ='NSE_CDX'

	SELECT @FUTIDX = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIDX'
	SELECT @FUTSTK = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTSTK'
	SELECT @FUTIRD = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRD'
	SELECT @FUTIRT = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRT'
	SELECT @FUTCUR = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR'
	SELECT @FUTIRC = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRC'
	SELECT @FUTIVX = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIVX'
	SELECT @FUTIRF = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRF'

	SELECT @OPTIDX = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'
	SELECT @OPTSTK = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'
	SELECT @OPTCUR = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'

	CREATE TABLE #EqSegments (RefSegmentId INT UNIQUE)
	INSERT INTO #EqSegments (RefSegmentId) VALUES(@BSE_CASHId), (@NSE_CASHId)

	SELECT DISTINCT
		RefClientId
	INTO #clientToExclude
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex
	WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1) 
		AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)

	SELECT
		trade.RefClientId,
		CASE WHEN trade.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell,
		(trade.Quantity * trade.Rate) AS TurnOver,
		trade.Quantity,
		trade.TradeDate,
		trade.RefSegmentId,
		trade.RefInstrumentId,
		trade.CoreTradeId
	INTO #tradeData
	FROM dbo.CoreTrade trade
	INNER JOIN #EqSegments eqSeg ON eqSeg.RefSegmentId = trade.RefSegmentId
	LEFT JOIN #clientToExclude clEx ON trade.RefClientId = clEx.RefClientId
	WHERE trade.TradeDate >= @FirstDateOfMonth AND trade.TradeDate <= @LastDateOfMonth
	AND clEx.RefClientId IS NULL

	DROP TABLE #EqSegments

	SELECT
		t.RefClientId,
		t.TradeDate,
		t.BuyQty,
		t.SellQty,
		t.BuyTO/BuyQty AS BuyAvgRate,
		t.SellTO/SellQty AS SellAvgRate,
		t.TxnIds
	INTO #BuySellData
	FROM
	(
		SELECT
			td.RefClientId,
			td.RefSegmentId,
			SUM(CASE WHEN td.BuySell = 1 THEN td.Quantity ELSE 0 END) AS BuyQty,
			SUM(CASE WHEN td.BuySell = 1 THEN td.TurnOver ELSE 0 END) AS BuyTO,
			SUM(CASE WHEN td.BuySell = 0 THEN td.Quantity ELSE 0 END) AS SellQty,
			SUM(CASE WHEN td.BuySell = 0 THEN td.TurnOver ELSE 0 END) AS SellTO,
			td.TradeDate,
			STUFF((
				SELECT ', ' + CONVERT(VARCHAR,td2.CoreTradeId)
				FROM #tradeData td2
				WHERE td2.RefClientId = td.RefClientId AND td2.RefSegmentId = td.RefSegmentId AND td2.RefInstrumentId = td.RefInstrumentId AND td2.TradeDate = td.TradeDate
				FOR XML PATH ('')
			)
			,1,2,'') AS TxnIds
		FROM #tradeData td
		GROUP BY td.RefClientId, td.TradeDate, td.RefSegmentId, RefInstrumentId
	) t
	WHERE t.BuyQty > 0 AND t.SellQty > 0

	DROP TABLE #tradeData

	CREATE TABLE #FullIntraDayData
	(
		RefClientId INT,
		TradeDate DATETIME,
		IntraDayProfitLoss DECIMAL(28,2),
		TxnIds VARCHAR(MAX),
		OptionTxnIds VARCHAR(MAX),
		FutureTxnIds VARCHAR(MAX),
	)

	---EqData
	INSERT INTO #FullIntraDayData
	(
		RefClientId,
		TradeDate,
		IntraDayProfitLoss,
		TxnIds
	)
	SELECT
		buy.RefClientId,
		buy.TradeDate,
		(buy.SellAvgRate - buy.BuyAvgRate) * (CASE WHEN buy.BuyQty < buy.SellQty THEN buy.BuyQty ELSE buy.SellQty END) AS IntraDayProfitLoss,
		buy.TxnIds
	FROM #BuySellData buy

	DROP TABLE #BuySellData

	
	CREATE TABLE #FnoSegments (RefSegmentId INT UNIQUE)
	INSERT INTO #FnoSegments (RefSegmentId) VALUES(@NSE_FNOId), (@NSE_CDXId)

	SELECT
		pos.RefClientId,
		pos.DailyMTMSettlementValue,
		pos.PositionDate,
		pos.DayBuyOpenQty,
		pos.DayBuyOpenValue,
		pos.DaySellOpenQty,
		pos.DaySellOpenValue,
		pos.RefSegmentId,
		inst.RefInstrumentTypeId,
		pos.RefInstrumentId,
		pos.CoreFnoPositionId
	INTO #FnoData
	FROM dbo.CoreFnoPosition pos
	INNER JOIN #FnoSegments fnoSegs ON fnoSegs.RefSegmentId = pos.RefSegmentId
	INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = pos.RefInstrumentId
	LEFT JOIN #clientToExclude clEx ON pos.RefClientId = clEx.RefClientId
	WHERE pos.PositionDate >= @FirstDateOfMonth AND pos.PositionDate <= @LastDateOfMonth
	AND clEx.RefClientId IS NULL

	DROP TABLE #clientToExclude
	DROP TABLE #FnoSegments

	CREATE TABLE #FutInstTypes (RefInstrumentTypeId INT UNIQUE)
	INSERT INTO #FutInstTypes (RefInstrumentTypeId)
	VALUES (@FUTIDX), (@FUTSTK), (@FUTIRD), (@FUTIRT), (@FUTCUR), (@FUTIRC), (@FUTIVX), (@FUTIRF)

	CREATE TABLE #OptInstTypes (RefInstrumentTypeId INT UNIQUE)
	INSERT INTO #OptInstTypes (RefInstrumentTypeId)
	VALUES (@OPTIDX), (@OPTSTK), (@OPTCUR)

	SELECT
		t.RefClientId,
		t.PositionDate,
		t.DayBuyOpenValue/t.DayBuyOpenQty AS BuyAvgRate,
		t.DaySellOpenValue/t.DaySellOpenQty AS SellAvgRate,
		t.DayBuyOpenQty,
		t.DaySellOpenQty,
		t.OptionTxnIds
	INTO #OptionsData
	FROM
	(
		SELECT
			fd.RefClientId,
			fd.RefSegmentId,
			fd.RefInstrumentId,
			fd.PositionDate,
			SUM(fd.DaySellOpenValue) AS DaySellOpenValue,
			SUM(fd.DaySellOpenQty) AS DaySellOpenQty,
			SUM(fd.DayBuyOpenValue) AS DayBuyOpenValue,
			SUM(fd.DayBuyOpenQty) AS DayBuyOpenQty,
			STUFF(
			(	SELECT ', ' + CONVERT(VARCHAR,fd2.CoreFnoPositionId) + ':' + CONVERT(VARCHAR,fd2.RefSegmentId)
				FROM #FnoData fd2
				WHERE fd2.RefClientId = fd.RefClientId AND fd2.RefSegmentId = fd.RefSegmentId AND fd2.RefInstrumentId = fd.RefInstrumentId AND fd2.PositionDate = fd.PositionDate
				FOR XML PATH ('')
			),1,2,'') AS OptionTxnIds
		FROM #FnoData fd
		INNER JOIN #OptInstTypes optInst ON optInst.RefInstrumentTypeId = fd.RefInstrumentTypeId
		GROUP BY fd.RefClientId, fd.RefSegmentId, fd.RefInstrumentId, fd.PositionDate
	)t
	WHERE t.DayBuyOpenQty > 0 AND t.DaySellOpenQty > 0

	DROP TABLE #OptInstTypes

	--OptionsData
	INSERT INTO #FullIntraDayData
	(
		RefClientId,
		TradeDate,
		IntraDayProfitLoss,
		OptionTxnIds
	)
	SELECT
		buy.RefClientId,
		buy.PositionDate,
		(buy.SellAvgRate - buy.BuyAvgRate) * (CASE WHEN buy.DayBuyOpenQty < buy.DaySellOpenQty THEN buy.DayBuyOpenQty ELSE buy.DaySellOpenQty END) AS IntraDayProfitLoss,
		buy.OptionTxnIds
	FROM #OptionsData buy

	--FutureData
	INSERT INTO #FullIntraDayData
	(
		RefClientId,
		TradeDate,
		IntraDayProfitLoss,
		FutureTxnIds
	)
	SELECT
		fd.RefClientId,
		fd.PositionDate,
		SUM(fd.DailyMTMSettlementValue) AS IntraDayProfitLoss,
		STUFF(
			(	SELECT ', ' + CONVERT(VARCHAR,fd2.CoreFnoPositionId) + ':' + CONVERT(VARCHAR,fd2.RefSegmentId)
				FROM #FnoData fd2
				WHERE fd2.RefClientId = fd.RefClientId AND fd2.RefSegmentId = fd.RefSegmentId AND fd2.RefInstrumentId = fd.RefInstrumentId AND fd2.PositionDate = fd.PositionDate
				FOR XML PATH ('')
			),1,2,'') 
	FROM #FnoData fd
	INNER JOIN #FutInstTypes futInst ON futInst.RefInstrumentTypeId = fd.RefInstrumentTypeId
	GROUP BY fd.RefClientId, fd.RefSegmentId, fd.RefInstrumentId, fd.PositionDate

	DROP TABLE #FnoData
	DROP TABLE #FutInstTypes

	SELECT
		t.RefClientId,
		CONVERT(DECIMAL(28,2),t.Week1PL) AS Week1PL,
		CONVERT(DECIMAL(28,2),t.Week2PL) AS Week2PL,
		CONVERT(DECIMAL(28,2),t.Week3PL) AS Week3PL,
		CONVERT(DECIMAL(28,2),t.Week4PL) AS Week4PL,
		CONVERT(DECIMAL(28,2),t.TotalPL) AS TotalPL,
		t.TxnIds,
		t.OptionTxnIds,
		t.FutureTxnIds
	INTO #WeekWiseData
	FROM
	(
		SELECT
			fidd.RefClientId,
			SUM(CASE WHEN fidd.TradeDate >= @FirstDateOfMonth AND fidd.TradeDate <= @Week1End THEN fidd.IntraDayProfitLoss ELSE 0 END) AS Week1PL,
			SUM(CASE WHEN fidd.TradeDate > @Week1End AND fidd.TradeDate <= @Week2End THEN fidd.IntraDayProfitLoss ELSE 0 END) AS Week2PL,
			SUM(CASE WHEN fidd.TradeDate > @Week2End AND fidd.TradeDate <= @Week3End THEN fidd.IntraDayProfitLoss ELSE 0 END) AS Week3PL,
			SUM(CASE WHEN fidd.TradeDate > @Week3End AND fidd.TradeDate <= @LastDateOfMonth THEN fidd.IntraDayProfitLoss ELSE 0 END) AS Week4PL,
			SUM(IntraDayProfitLoss) AS TotalPL,
			STUFF((
				SELECT ', ' + fidd2.TxnIds
				FROM #FullIntraDayData fidd2
				WHERE fidd2.RefClientId = fidd.RefClientId 
				FOR XML PATH ('')
				),1,2,'') AS TxnIds,
			STUFF((
				SELECT ', ' + fidd2.OptionTxnIds
				FROM #FullIntraDayData fidd2
				WHERE fidd2.RefClientId = fidd.RefClientId 
				FOR XML PATH ('')
				),1,2,'') AS OptionTxnIds,
			STUFF((
				SELECT ', ' + fidd2.FutureTxnIds
				FROM #FullIntraDayData fidd2
				WHERE fidd2.RefClientId = fidd.RefClientId 
				FOR XML PATH ('')
				),1,2,'') AS FutureTxnIds
		FROM #FullIntraDayData fidd
		GROUP BY RefClientId
	)t
	WHERE (t.Week1PL >= 0 AND t.Week2PL >= 0 AND t.Week3PL >= 0 AND t.Week4PL >= 0) 
		OR (t.Week1PL <= 0 AND t.Week2PL <= 0 AND t.Week3PL <= 0 AND t.Week4PL <= 0)

	DROP TABLE #FullIntraDayData

	SELECT
		rules.Threshold,
		linkCS.RefClientStatusId
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule rules
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus linkCS ON linkCS.RefAmlScenarioRuleId = rules.RefAmlScenarioRuleId
	WHERE rules.RefAmlReportId = @ReportIdInternal

	SELECT
		cl.RefClientId,
		cl.ClientId,
		cl.[Name] AS ClientName,
		@FirstDateOfMonth AS FromDate,
		@LastDateOfMonth AS ToDate,
		wwd.Week1PL,
		wwd.Week2PL,
		wwd.Week3PL,
		wwd.Week4PL,
		wwd.TotalPL,
		wwd.TxnIds,
		wwd.OptionTxnIds +', '+ wwd.FutureTxnIds AS OptionFutureTxnIds
	FROM #WeekWiseData wwd
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = wwd.RefClientId
	INNER JOIN #scenarioRules rules ON rules.RefClientStatusId = cl.RefClientStatusId AND Abs(wwd.TotalPL) >= rules.Threshold
	LEFT JOIN dbo.CoreAmlScenarioAlert alerts ON 
	(
		@IsAlertDulicationAllowedInternal = 0 AND alerts.RefAmlReportId = @ReportIdInternal 
		AND alerts.RefClientId = cl.RefClientId AND @FirstDateOfMonth = alerts.TransactionFromDate 
		AND @LastDateOfMonthWithOutTime = alerts.TransactionToDate AND wwd.Week1PL = alerts.MoneyIn 
		AND wwd.Week2PL = alerts.MoneyOut AND wwd.Week3PL = alerts.MoneyInOut AND wwd.Week4PL = alerts.IntradayProfitLoss
		AND wwd.TotalPL = alerts.NetMoneyIn
	)
	WHERE alerts.CoreAmlScenarioAlertId IS NULL
END
GO
--WEB-76085 RC END
--WEB-76085 RC START
GO
CREATE PROCEDURE dbo.AML_GetS185ConsistentIntradayProfitLossInACalendarMonthTxnDetails(
	@AlertId  BIGINT
)
AS 
BEGIN
	DECLARE @AlertIdInternal BIGINT,@FirstDateOfMonth DATETIME, @LastDateOfMonth DATETIME, 
			@Week1End DATETIME, @Week2End DATETIME, @Week3End DATETIME,
			@FUTIDX INT, @FUTSTK INT, @FUTIRD INT, @FUTIRT INT, @FUTCUR INT, @FUTIRC INT, @FUTIVX INT, @FUTIRF INT,
			@OPTIDX INT, @OPTSTK INT, @OPTCUR INT
			
	SET @AlertIdInternal = @AlertId
	SELECT @FirstDateOfMonth = alert.TransactionFromDate FROM dbo.CoreAmlScenarioAlert alert	WHERE alert.CoreAmlScenarioAlertId = @AlertIdInternal
	SELECT @LastDateOfMonth = alert.TransactionToDate FROM dbo.CoreAmlScenarioAlert alert	WHERE alert.CoreAmlScenarioAlertId = @AlertIdInternal
	
	SET @Week1End = DATEADD(SECOND,-1,DATEADD(DAY, 7, @FirstDateOfMonth))
	SET @Week2End = DATEADD(DAY, 8, @Week1End)
	SET @Week3End = DATEADD(DAY, 7, @Week2End)

	SELECT @FUTIDX = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIDX'
	SELECT @FUTSTK = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTSTK'
	SELECT @FUTIRD = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRD'
	SELECT @FUTIRT = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRT'
	SELECT @FUTCUR = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR'
	SELECT @FUTIRC = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRC'
	SELECT @FUTIVX = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIVX'
	SELECT @FUTIRF = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRF'

	SELECT @OPTIDX = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'
	SELECT @OPTSTK = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'
	SELECT @OPTCUR = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'

	SELECT
		trans.TransactionId AS TxnId,
		RefSegmentEnumId
	INTO #allTxnIds
	FROM dbo.CoreAmlScenarioAlertDetail trans
	WHERE trans.CoreAmlScenarioAlertId = @AlertIdInternal  
	

	IF (SELECT TOP 1 1 FROM #allTxnIds) IS NULL
	BEGIN
		RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;
		RETURN 50010
	END


	SELECT 
		trade.RefSegmentId,
		trade.RefInstrumentId,
		trade.TradeDate,
		CASE WHEN trade.BuySell='Buy' THEN 1 ELSE 0 END AS BuySell,
		trade.Rate,
		trade.Quantity,
		(trade.Quantity * trade.Rate) AS TurnOver
	INTO #tradeData	
	FROM dbo.CoreTrade trade
	INNER JOIN #allTxnIds txnid ON txnid.TxnId = trade.CoreTradeId AND ISNULL(txnid.RefSegmentEnumId ,0) = 0
	
	CREATE TABLE #BuySellData(
		TradeDate DATETIME,
		RefInstrumentId INT,
		RefSegmentId INT,
		BuyQuantity INT,
		BuyRate DECIMAL(28,2),
		BuyTurnover DECIMAL(28,2),
		SellQuantity INT,
		SellRate DECIMAL(28,2),
		SellTurnover DECIMAL(28,2),
		TotalProfit DECIMAL(28,2)
	)

	INSERT INTO #BuySellData(
		TradeDate ,
		RefInstrumentId,
		RefSegmentId ,
		BuyQuantity ,
		BuyRate,
		BuyTurnover ,
		SellQuantity ,
		SellRate ,
		SellTurnover ,
		TotalProfit 
	)
	SELECT
		z.TradeDate,
		z.RefInstrumentId,
		z.RefSegmentId,
		z.BuyQty,
		z.BuyAvgRate,
		z.BuyTO,
		z.SellQty,
		z.SellAvgRate,
		z.SellTO,
		(z.SellAvgRate - z.BuyAvgRate) * (CASE WHEN z.BuyQty < z.SellQty THEN z.BuyQty ELSE z.SellQty END) AS TotalProfit
	FROM(
		SELECT
			t.TradeDate,
			t.BuyQty,
			t.SellQty,
			t.BuyTO/BuyQty AS BuyAvgRate,
			t.SellTO/SellQty AS SellAvgRate,
			t.BuyTO,
			t.SellTO,
			t.RefSegmentId,
			t.RefInstrumentId
		FROM
		(
			SELECT
				td.RefSegmentId,
				SUM(CASE WHEN td.BuySell = 1 THEN td.Quantity ELSE 0 END) AS BuyQty,
				SUM(CASE WHEN td.BuySell = 1 THEN td.TurnOver ELSE 0 END) AS BuyTO,
				SUM(CASE WHEN td.BuySell = 0 THEN td.Quantity ELSE 0 END) AS SellQty,
				SUM(CASE WHEN td.BuySell = 0 THEN td.TurnOver ELSE 0 END) AS SellTO,
				td.TradeDate,
				td.RefInstrumentId
			FROM #tradeData td
			GROUP BY td.TradeDate, td.RefSegmentId, RefInstrumentId
		) t
		WHERE t.BuyQty > 0 AND t.SellQty > 0
	)z

	CREATE TABLE #FutInstTypes (RefInstrumentTypeId INT UNIQUE)
	INSERT INTO #FutInstTypes (RefInstrumentTypeId)
	VALUES (@FUTIDX), (@FUTSTK), (@FUTIRD), (@FUTIRT), (@FUTCUR), (@FUTIRC), (@FUTIVX), (@FUTIRF)

	CREATE TABLE #OptInstTypes (RefInstrumentTypeId INT UNIQUE)
	INSERT INTO #OptInstTypes (RefInstrumentTypeId)
	VALUES (@OPTIDX), (@OPTSTK), (@OPTCUR)

	SELECT
		pos.RefClientId,
		pos.DailyMTMSettlementValue,
		pos.PositionDate,
		pos.DayBuyOpenQty,
		pos.DayBuyOpenValue,
		pos.DaySellOpenQty,
		pos.DaySellOpenValue,
		pos.RefSegmentId,
		pos.RefInstrumentId
	INTO #FnoData
	FROM #allTxnIds txnid 
	INNER JOIN dbo.CoreFnoPosition pos ON txnId.RefSegmentEnumId IS NOT NULL AND pos.CoreFnoPositionId = txnid.TxnId 
	INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = pos.RefInstrumentId
	INNER JOIN #FutInstTypes ty ON ty.RefInstrumentTypeId = inst.RefInstrumentTypeId

	INSERT INTO #BuySellData(
		TradeDate ,
		RefInstrumentId,
		RefSegmentId ,
		BuyQuantity ,
		BuyRate,
		BuyTurnover ,
		SellQuantity ,
		SellRate ,
		SellTurnover ,
		TotalProfit 
	)
	SELECT
		z.TradeDate,
		z.RefInstrumentId,
		z.RefSegmentId,
		z.DayBuyOpenQty,
		z.BuyAvgRate,
		z.DayBuyOpenValue,
		z.DaySellOpenQty,
		z.SellAvgRate,
		z.DaySellOpenValue,
		(z.SellAvgRate - z.BuyAvgRate) * (CASE WHEN z.DayBuyOpenQty < z.DaySellOpenQty THEN z.DayBuyOpenQty ELSE z.DaySellOpenQty END) AS TotalProfit
	FROM(
		SELECT
			t.RefInstrumentId,
			t.RefSegmentId,
			t.PositionDate AS TradeDate,
			t.DayBuyOpenValue/t.DayBuyOpenQty AS BuyAvgRate,
			t.DaySellOpenValue/t.DaySellOpenQty AS SellAvgRate,
			t.DayBuyOpenQty,
			t.DaySellOpenQty,
			t.DayBuyOpenValue,
			t.DaySellOpenValue
		
		FROM
		(
			SELECT
				fd.RefClientId,
				fd.RefSegmentId,
				fd.RefInstrumentId,
				fd.PositionDate,
				SUM(fd.DaySellOpenValue) AS DaySellOpenValue,
				SUM(fd.DaySellOpenQty) AS DaySellOpenQty,
				SUM(fd.DayBuyOpenValue) AS DayBuyOpenValue,
				SUM(fd.DayBuyOpenQty) AS DayBuyOpenQty
			FROM #FnoData fd
			GROUP BY fd.RefClientId, fd.RefSegmentId, fd.RefInstrumentId, fd.PositionDate
		)t
		WHERE t.DayBuyOpenQty > 0 AND t.DaySellOpenQty > 0
	)z

	
	INSERT INTO #BuySellData(
		TradeDate ,
		RefInstrumentId,
		RefSegmentId ,
		TotalProfit 
		)
		SELECT
			pos.PositionDate,
			pos.RefInstrumentId,
			pos.RefSegmentId,
			SUM(pos.DailyMTMSettlementValue) AS TotalPl
		FROM #allTxnIds txnid 
		INNER JOIN dbo.CoreFnoPosition pos ON txnId.RefSegmentEnumId IS NOT NULL AND pos.CoreFnoPositionId = txnid.TxnId 
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = pos.RefInstrumentId
		INNER JOIN #OptInstTypes ty ON ty.RefInstrumentTypeId = inst.RefInstrumentTypeId
		GROUP BY pos.RefClientId,pos.RefSegmentId,pos.RefInstrumentId,pos.PositionDate
	

	CREATE TABLE #TempResult(
		SrNo INT,
		TradeDate VARCHAR(20),
		Script VARCHAR(100),
		SegmentName VARCHAR(20),
		BuyQuantity INT,
		BuyRate DECIMAL(28,2),
		BuyTurnover DECIMAL(28,2),
		SellQuantity INT,
		SellRate DECIMAL(28,2),
		SellTurnover DECIMAL(28,2),
		TotalProfit DECIMAL(28,2)
	)

	INSERT INTO #TempResult (SrNo,TradeDate)
	VALUES (1,'W1')

	DECLARE @MaxSrNo INT
	SET @MaxSrNo = 1
	INSERT INTO #TempResult(
		 SrNo,
		 TradeDate,
		 Script,
		 SegmentName,
		 BuyQuantity,
		 BuyRate,
		 BuyTurnover,
		 SellQuantity,
		 SellRate,
		 SellTurnover,
		 TotalProfit
	)
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY buySell.TradeDate ASC) + @MaxSrNo SrNo,
			CONVERT (VARCHAR, buySell.Tradedate,106),
			inst.[Name],
			seg.Segment,
			buySell.BuyQuantity,
			buySell.BuyRate,
			buySell.BuyTurnover,
			buySell.SellQuantity,
			buySell.SellRate,
			buySell.SellTurnover,
			buySell.TotalProfit
		FROM #BuySellData  AS buySell
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = buySell.RefInstrumentId  AND buySell.TradeDate >= @FirstDateOfMonth AND buySell.TradeDate <= @Week1End
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = buySell.RefSegmentId 
	)
	INSERT INTO #TempResult (SrNo,TradeDate)
	VALUES ((SELECT MAX(SrNo) FROM #TempResult)+1,'W2')

	SET @MaxSrNo = (SELECT MAX(SrNo) FROM #TempResult)

	INSERT INTO #TempResult(
		 SrNo,
		 TradeDate,
		 Script,
		 SegmentName,
		 BuyQuantity,
		 BuyRate,
		 BuyTurnover,
		 SellQuantity,
		 SellRate,
		 SellTurnover,
		 TotalProfit
	)
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY buySell.TradeDate ASC) + @MaxSrNo SrNo,
			CONVERT (VARCHAR, buySell.Tradedate,106),
			inst.[Name],
			seg.Segment,
			buySell.BuyQuantity,
			buySell.BuyRate,
			buySell.BuyTurnover,
			buySell.SellQuantity,
			buySell.SellRate,
			buySell.SellTurnover,
			buySell.TotalProfit
		FROM #BuySellData  AS buySell
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = buySell.RefInstrumentId  AND buySell.TradeDate > @Week1End AND buySell.TradeDate <= @Week2End
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = buySell.RefSegmentId 
	)
	
	INSERT INTO #TempResult (SrNo,TradeDate)
	VALUES ((SELECT MAX(SrNo) FROM #TempResult)+1,'W3')

	SET @MaxSrNo = (SELECT MAX(SrNo) FROM #TempResult)

	INSERT INTO #TempResult(
		 SrNo,
		 TradeDate,
		 Script,
		 SegmentName,
		 BuyQuantity,
		 BuyRate,
		 BuyTurnover,
		 SellQuantity,
		 SellRate,
		 SellTurnover,
		 TotalProfit
	)
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY buySell.TradeDate ASC) + @MaxSrNo SrNo,
			CONVERT (varchar, buySell.Tradedate,106),
			inst.[Name],
			seg.Segment,
			buySell.BuyQuantity,
			buySell.BuyRate,
			buySell.BuyTurnover,
			buySell.SellQuantity,
			buySell.SellRate,
			buySell.SellTurnover,
			buySell.TotalProfit
		FROM #BuySellData  AS buySell
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = buySell.RefInstrumentId   AND buySell.TradeDate > @Week2End AND buySell.TradeDate <= @Week3End
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = buySell.RefSegmentId 
	)
	INSERT INTO #TempResult (SrNo,TradeDate)
	VALUES ((SELECT MAX(SrNo) FROM #TempResult)+1,'W4')

	SET @MaxSrNo = (SELECT MAX(SrNo) FROM #TempResult)

	INSERT INTO #TempResult(
		 SrNo,
		 TradeDate,
		 Script,
		 SegmentName,
		 BuyQuantity,
		 BuyRate,
		 BuyTurnover,
		 SellQuantity,
		 SellRate,
		 SellTurnover,
		 TotalProfit
	)
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY buySell.TradeDate ASC) + @MaxSrNo SrNo,
			CONVERT (varchar, buySell.Tradedate,106),
			inst.[Name],
			seg.Segment,
			buySell.BuyQuantity,
			buySell.BuyRate,
			buySell.BuyTurnover,
			buySell.SellQuantity,
			buySell.SellRate,
			buySell.SellTurnover,
			buySell.TotalProfit
		FROM #BuySellData  AS buySell
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = buySell.RefInstrumentId   AND buySell.TradeDate > @Week3End AND buySell.TradeDate <= @LastDateOfMonth
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = buySell.RefSegmentId 
	)

	SELECT * FROM
	#TempResult te
	ORDER BY te.SrNo 

END
GO

--WEB-76085 RC END