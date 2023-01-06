--File:StoredProcedures:dbo:Aml_GetIntradayTurnover1DayEQ
--WEB-83762-RC START
GO
ALTER PROCEDURE dbo.Aml_GetIntradayTurnover1DayEQ
(
	@RunDate DATETIME,
	@ReportId INT
)
AS
BEGIN
	
	DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @IntraDayTO DECIMAL(28, 2), @TradingMultiplier DECIMAL(28, 2), 
			@ExcludePro BIT, @ExcludeInstitution BIT, @IncomeCheck INT, @NetworthCheck INT, @ProStatusId INT, @InstituteStatusId INT, 
			@BseCashId INT, @NseCashId INT, @DefaultIncome BIGINT, @DefaultNetworth BIGINT, @Above1Cr INT, @DefaultAboveOneCr DECIMAL(28,2)

	SET @ReportIdInternal = @ReportId
	SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)
	
	SET @BseCashId = dbo.GetSegmentId('BSE_CASH')
	SET @NseCashId = dbo.GetSegmentId('NSE_CASH')

	
	SET @Above1Cr = (SELECT grp.RefIncomeGroupId FROM dbo.RefIncomeGroup grp WHERE grp.[Name] = 'Above 1 Crore')
	SET @DefaultAboveOneCr = (SELECT CONVERT(DECIMAL(28,2),syst.[Value]) FROM dbo.SysConfig syst WHERE syst.[Name] ='Income_Value_For_Above_One_Crore')

	SELECT @ProStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Pro'
	SELECT @InstituteStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'

	SELECT @ExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
	FROM dbo.SysAmlReportSetting 
	WHERE RefAmlReportId = @ReportIdInternal  AND [Name] = 'Exclude_Pro'
	
	SELECT @ExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
	FROM dbo.SysAmlReportSetting
	WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_Institution'

	SELECT @IncomeCheck = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
	FROM dbo.SysAmlReportSetting
	WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Income'

	SELECT @NetworthCheck = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
	FROM dbo.SysAmlReportSetting
	WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Networth'

	SELECT @IntraDayTO = CONVERT(DECIMAL(28,2), [Value])
	FROM dbo.SysAmlReportSetting
	WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Trading_Turnover'

	SELECT @TradingMultiplier = CONVERT(DECIMAL(28,2), [Value])
	FROM dbo.SysAmlReportSetting
	WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Trading_Multiplier'

	SELECT @DefaultIncome = CONVERT(BIGINT, reportSetting.[Value])
	FROM dbo.RefAmlQueryProfile qp
	LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.[Name] = 'Client Purchase to Income'
	LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId
		AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId
		AND reportSetting.[Name] = 'Default_Income'
	WHERE	qp.[Name] = 'Default'

	SELECT @DefaultNetworth = cliNetSellPoint.DefaultNetworth
	FROM	dbo.RefAmlQueryProfile qp
	LEFT JOIN dbo.LinkRefAmlQueryProfileRefSegment qpSegment ON qpSegment.RefSegmentId = @BseCashId
		AND qpSegment.RefAmlQueryProfileId = qp.RefAmlQueryProfileId
	LEFT JOIN dbo.SysAmlClientNetSellPoints cliNetSellPoint ON cliNetSellPoint.LinkRefAmlQueryProfileRefSegmentId = qpSegment.LinkRefAmlQueryProfileRefSegmentId
	WHERE qp.[Name] = 'Default'	

	;WITH clientsToExclude_CTE AS
	(
		SELECT DISTINCT RefClientId
		FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex
		WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1) 
			AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)
	)

	SELECT
		td.RefClientId,
		td.RefInstrumentId,
		td.Quantity,
		td.Rate * td.Quantity AS TurnOver,
		CASE WHEN td.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell
	INTO #tradeData
	FROM dbo.CoreTrade td
	LEFT JOIN clientsToExclude_CTE clEx ON clEx.RefClientId = td.RefClientId
	WHERE td.RefSegmentId IN (@NseCashId, @BseCashId)
		AND td.TradeDate = @RunDateInternal AND clEx.RefClientId IS NULL

	SELECT
		DISTINCT tr.RefInstrumentId
	INTO #distinctInstrument
	FROM #tradeData tr

	;WITH instrument_CTE AS(
		SELECT inst.RefInstrumentId,
		 DENSE_RANK() OVER(ORDER BY ref.Isin) dr
		FROM #distinctInstrument inst
		INNER JOIN dbo.RefInstrument ref ON ref.RefInstrumentId = inst.RefInstrumentId
	)
	SELECT
		t.RefClientId, t.BuyQty, t.BuyTO, t.SellQty, t.SellTO
	INTO #buySellData
	FROM(
		SELECT
			tr.RefClientId,
			SUM(CASE WHEN tr.BuySell = 1 THEN tr.TurnOver ELSE 0 END) AS BuyTO,
			SUM(CASE WHEN tr.BuySell = 1 THEN tr.Quantity ELSE 0 END) AS BuyQty,
			SUM(CASE WHEN tr.BuySell = 0 THEN tr.TurnOver ELSE 0 END) AS SellTO,
			SUM(CASE WHEN tr.BuySell = 0 THEN tr.Quantity ELSE 0 END) AS SellQty
		FROM #tradeData tr
		INNER JOIN instrument_CTE  inst ON inst.RefInstrumentId = tr.RefInstrumentId
		GROUP BY RefClientId, inst.dr)t
	WHERE t.BuyQty > 0 AND t.SellQty > 0

	SELECT
		t.RefClientId,
		t.TotalIntraTO
	INTO #finalTradeData
	FROM (SELECT
					RefClientId,
					SUM((t.BuyQty * t.SellTO + t.SellQty * t.BuyTO) /dbo.GetMaximumValue(t.SellQty, t.BuyQty)) TotalIntraTO
			FROM #buySellData t
			GROUP BY t.RefClientId
		)t
	WHERE t.TotalIntraTO >= @IntraDayTO
	
	;WITH incomeAndTradeData_CTE AS(
		SELECT
			icl.RefClientId,
			icl.TotalIntraTO,
			COALESCE(linkInc.Networth, @DefaultNetworth, 0) AS Networth,
			CASE WHEN linkInc.RefIncomeGroupId = @Above1Cr AND ISNULL(@DefaultAboveOneCr, 0) = 0 THEN 10000000
				WHEN linkInc.RefIncomeGroupId = @Above1Cr THEN @DefaultAboveOneCr
				ELSE COALESCE(linkInc.Income, incGrp.IncomeTo, @DefaultIncome, 0) END AS Income,
			ROW_NUMBER() OVER(PARTITION BY icl.RefClientId ORDER BY ISNULL(linkInc.ToDate, '9999-12-31') DESC) AS RN
		FROM #finalTradeData icl
		LEFT JOIN dbo.LinkRefClientRefIncomeGroup linkInc ON linkInc.RefClientId = icl.RefClientId
		LEFT JOIN dbo.RefIncomeGroup incGrp ON incGrp.RefIncomeGroupId = linkInc.RefIncomeGroupId
	)

	SELECT
		t.RefClientId,
		t.TotalIntraTO,
		(t.Income * @IncomeCheck  + t.Networth * @NetworthCheck) * ISNULL(cl.TradingMultiplier, @TradingMultiplier) AS TradingStrength,
		cl.ClientId,
		cl.[Name] AS ClientName
	INTO #IncomeDetails
	FROM incomeAndTradeData_CTE t
	INNER JOIN dbo.RefClient cl ON  t.RN = 1 AND cl.RefClientId = t.RefClientId AND (@ExcludePro = 0 OR cl.RefClientStatusId <> @ProStatusId) 											
							AND	(@ExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstituteStatusId)

	SELECT
		inc.RefClientId,
		inc.ClientId,
		inc.ClientName,
		inc.TotalIntraTO AS TotalIntrdayTo,
		inc.TradingStrength,
		@BseCashId AS RefSegmentId 
	FROM #IncomeDetails inc
	WHERE inc.TotalIntraTO >= inc.TradingStrength

END
GO
--WEB-83762-RC END
--File:Tables:dbo:RefAmlReport:DML
--WEB-83762-RC START
GO
	UPDATE re
	SET re.[Description] = 'This scenario will detect the Intraday TO for 1 Day<br>
			It will generate alert if,<br>
			1.The Intraday TO of the client is greater than or equal to the set threshold<br>
			2. Trading strength of the client is greater than or equal to the set threshold<br>
			Threshold:<br>
			1. Intraday TO : It is a total Intraday TO of the client in EQ BSE_CASH and NSE_CASH combine For e.g<br>
			If user buy 100 Reliance in BSE and Sell in NSE it is a Intraday Trade<br>
			2. Trading Multiplier : It is the multiplier for calculating trading strength of the client. User can able to select Income or Networth or both<br>
			User have to select any one from Income or Networth or both below is the formula for calculating Trading strength<br>
			If user select both Income & Networth =  (Income + Networth) * Trading Multiplier<br>
			If user select only Income = Income * Trading Multiplier<br>
			If user select only Networth = Networth * Trading Multiplier<br>'
	FROM dbo.RefAmlReport re
	WHERE re.[Name] = 'S86 Intraday Turnover 1 Day EQ'
GO
--WEB-83762-RC END
--File:Tables:dbo:RefAmlReport:DML
--WEB-83762-RC START
GO
	DECLARE @RefAmlReportId INT,@BseCashId INT
	SET @RefAmlReportId = (SELECT RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S86 Intraday Turnover 1 Day EQ')
	
	SET @BseCashId = dbo.GetSegmentId('BSE_CASH')
	UPDATE core
	SET core.RefSegmentEnumId = @BseCashId
	FROM dbo.CoreAmlScenarioAlert core WHERE core.RefAmlReportId = @RefAmlReportId AND core.RefSegmentEnumId IS NULL
GO
--WEB-83762-RC END