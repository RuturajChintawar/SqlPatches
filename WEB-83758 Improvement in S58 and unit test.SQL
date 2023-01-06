--File:Tables:dbo:SysAmlReportSetting:DML
--WEB-83758-START RC
GO
	DECLARE @AmlReportId INT

	SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S58 Delivery Turnover 1 Day'

	INSERT INTO dbo.SysAmlReportSetting (
		RefAmlReportId,
		[Name],
		[Value],
		RefAmlQueryProfileId,
		DisplayName,
		DisplayOrder,
		AddedOn,
		AddedBy,
		EditedOn,
		LastEditedBy
	) VALUES (
		@AmlReportId,
		'Income',
		'True',
		1,
		'Income',
		5,
		GETDATE(),
		'System',
		GETDATE(),
		'System'
	),(
		@AmlReportId,
		'Networth',
		'True',
		1,
		'Networth',
		6,
		GETDATE(),
		'System',
		GETDATE(),
		'System'
	)
GO
--WEB-83758-END RC
--File:StoredProcedures:dbo:Aml_GetDeliveryTurnover
--WEB-83758-START RC
GO
ALTER PROCEDURE [dbo].[Aml_GetDeliveryTurnover]
(
	@RunDate DATETIME 
)
AS
BEGIN
	DECLARE @BseCashId INT, @NseCashId INT, @ExcludePro BIT, @ExcludeInstitution BIT, @DeliveryMultiplier INT, @ThresholdDeliveryTurnoverEquity DECIMAL(28,4),
		@RunDateInternal DATETIME, @RefAmlReportId INT, @ProRefClientStatusId INT, @InstitutionRefClientStatusId INT, @DefaultIncome BIGINT, @DefaultNetworth BIGINT,
		@IsNetworth BIT,@IsIncome BIT, @RefIncomeGroupIdAbove1cr INT, @DefaultAboveOneCr DECIMAL(28,2)
	
	SET @BseCashId = dbo.GetSegmentId('BSE_CASH')
	SET @NseCashId = dbo.GetSegmentId('NSE_CASH')
	SET @RunDateInternal = @RunDate
	SET @RefAmlReportId = (SELECT ref.RefAmlReportId FROM dbo.RefAmlReport ref WHERE ref.[Name] = 'S58 Delivery Turnover 1 Day' )

	SET @ThresholdDeliveryTurnoverEquity = (SELECT CONVERT(DECIMAL(28,2),syst.[Value] )FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @RefAmlReportId AND syst.[Name] = 'Delivery_Turnover_Equity')
	SET @DeliveryMultiplier = (SELECT CONVERT(INT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @RefAmlReportId AND syst.[Name] = 'Delivery_Multiplier')
	SET @ExcludePro = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @RefAmlReportId AND syst.[Name] = 'Exclude_Pro')
    SET @ExcludeInstitution = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @RefAmlReportId AND syst.[Name] = 'Exclude_Institution')
	SET @IsNetworth = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @RefAmlReportId AND syst.[Name] = 'Networth')
	SET @IsIncome = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @RefAmlReportId AND syst.[Name] = 'Income')

	SET @ProRefClientStatusId = (SELECT sta.RefClientStatusId FROM dbo.RefClientStatus sta WHERE sta.[Name] = 'Pro')
	SET @InstitutionRefClientStatusId = (SELECT sta.RefClientStatusId FROM dbo.RefClientStatus sta WHERE sta.[Name] = 'Institution')

	SET @RefIncomeGroupIdAbove1cr = (SELECT grp.RefIncomeGroupId FROM dbo.RefIncomeGroup grp WHERE grp.Code = 6)
	SET @DefaultAboveOneCr = (SELECT CONVERT(DECIMAL(28,2),syst.[Value]) FROM dbo.SysConfig syst WHERE syst.[Name] ='Income_Value_For_Above_One_Crore')

	
	SELECT	@DefaultNetworth = cliNetSellPoint.DefaultNetworth FROM	dbo.RefAmlQueryProfile qp  	
										LEFT JOIN dbo.LinkRefAmlQueryProfileRefSegment qpSegment ON qpSegment.RefSegmentId = @BseCashId AND qpSegment.RefAmlQueryProfileId = qp.RefAmlQueryProfileId				  
										LEFT JOIN dbo.SysAmlClientNetSellPoints cliNetSellPoint ON cliNetSellPoint.LinkRefAmlQueryProfileRefSegmentId = qpSegment.LinkRefAmlQueryProfileRefSegmentId
										WHERE qp.[Name] = 'Default'	
            
	SELECT	@DefaultIncome = CONVERT(BIGINT , reportSetting.[Value]) FROM	dbo.RefAmlQueryProfile qp 		
										LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.[Name] = 'Client Purchase to Income'
										LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId
													AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId
													AND reportSetting.[Name] = 'Default_Income'
										WHERE	qp.[Name] = 'Default'

	SELECT RefSegmentEnumId
	INTO #RequiredSegment
	FROM dbo.RefSegmentEnum 
	WHERE Segment IN ('BSE_CASH','NSE_CASH')

	SELECT DISTINCT
		RefClientId
	INTO #clientsToExclude
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex
	WHERE (ex.RefAmlReportId = @RefAmlReportId OR ex.ExcludeAllScenarios = 1) 
		AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)

	SELECT
		tr.RefClientId,
		tr.RefInstrumentId,
		CASE WHEN tr.BuySell = 'Buy' THEN 0 ELSE 1 END AS BuySellFlag,
		tr.Quantity,
		(tr.Quantity * tr.Rate) AS TurnOver
	INTO #tradedata
	FROM dbo.CoreTrade tr
	INNER JOIN #RequiredSegment segment ON tr.RefSegmentId = segment.RefSegmentEnumId AND tr.TradeDate = @RunDateInternal
	LEFT JOIN #clientsToExclude cltex ON cltex.RefClientId = tr.RefClientId
	WHERE cltex.RefClientId IS NULL

	SELECT
		DISTINCT tr.RefInstrumentId
	INTO #distinctInstrument
	FROM #tradedata tr

	;WITH instrument_CTE AS(
		SELECT
		 inst.RefInstrumentId,
		 DENSE_RANK() OVER(ORDER BY ref.Isin) dr
		FROM #distinctInstrument inst
		INNER JOIN dbo.RefInstrument ref ON ref.RefInstrumentId = inst.RefInstrumentId
	)

	SELECT
		t.RefClientId, t.BuyQty, t.BuyTO, t.SellQty, t.SellTO
	INTO #buySellData
	FROM(SELECT
			tr.RefClientId,
			inst.dr,
			SUM(CASE WHEN tr.BuySellFlag = 0 THEN tr.Quantity ELSE 0 END) AS BuyQty,
			SUM(CASE WHEN tr.BuySellFlag = 1 THEN tr.Quantity ELSE 0 END) AS SellQty,
			SUM(CASE WHEN tr.BuySellFlag = 0 THEN tr.TurnOver ELSE 0 END) AS BuyTO,
			SUM(CASE WHEN tr.BuySellFlag = 1 THEN tr.TurnOver ELSE 0 END) AS SellTO
		FROM #tradedata tr
		INNER JOIN instrument_CTE inst ON tr.RefInstrumentId = inst.RefInstrumentId
		GROUP BY tr.RefClientId, inst.dr)t
	WHERE t.BuyQty > 0 OR t.SellQty > 0

	SELECT t.RefClientId,
		t.DelTo
	INTO #finalData 
	FROM (SELECT 
			t.RefClientId,
			SUM((t.BuyTO + t.SellTO)-((t.BuyTO * t.SellQty + t.SellTO * t.BuyQty)/ dbo.GetMaximumValue(t.SellQty, t.BuyQty))) DelTo  --- refer logic sheet line no. 163
		FROM #buySellData t
		GROUP BY t.RefClientId)t
	WHERE t.DelTo >= @ThresholdDeliveryTurnoverEquity

	;WITH incomeAndTradeData_CTE AS(
		SELECT
			icl.RefClientId,
			icl.DelTo,
			COALESCE(linkInc.Networth, @DefaultNetworth, 0) AS Networth,
			CASE WHEN linkInc.RefIncomeGroupId = @RefIncomeGroupIdAbove1cr AND ISNULL(@DefaultAboveOneCr, 0) = 0 THEN 10000000
				WHEN linkInc.RefIncomeGroupId = @RefIncomeGroupIdAbove1cr THEN @DefaultAboveOneCr
				ELSE COALESCE(linkInc.Income, incGrp.IncomeTo, @DefaultIncome, 0) END AS Income,
			ROW_NUMBER() OVER(PARTITION BY icl.RefClientId ORDER BY ISNULL(linkInc.ToDate, '9999-12-31') DESC) AS RN
		FROM #finalData icl
		LEFT JOIN dbo.LinkRefClientRefIncomeGroup linkInc ON linkInc.RefClientId = icl.RefClientId
		LEFT JOIN dbo.RefIncomeGroup incGrp ON incGrp.RefIncomeGroupId = linkInc.RefIncomeGroupId
	)
	SELECT
		t.RefClientId,
		t.DelTo,
		(t.Income * @IsIncome  + t.Networth * @IsNetworth) * ISNULL(cl.DeliveryMultiplier, @DeliveryMultiplier) AS TradingStrength,
		cl.ClientId,
		cl.[Name] AS ClientName
	INTO #IncomeDetails
	FROM incomeAndTradeData_CTE t
	INNER JOIN dbo.RefClient cl ON  t.RN = 1 AND cl.RefClientId = t.RefClientId AND (@ExcludePro = 0 OR cl.RefClientStatusId <>  @ProRefClientStatusId) 											
							AND	(@ExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstitutionRefClientStatusId)

	SELECT 
		ft.RefClientId,
		ft.ClientId,
		ft.ClientName,
		ft.TradingStrength,
		ft.DelTo,
		@RunDateInternal AS TradeDate,
		@BseCashId AS RefSegmentId
	FROM #IncomeDetails ft
	WHERE ft.DelTo >= ft.TradingStrength
			
END
GO
--WEB-83758-END RC
--File:Tables:dbo:RefAmlReport:DML
--WEB-83758-START RC
GO
	UPDATE re
	SET re.[Description] = 'This Scenario will detect the Delivery Turnover done by a clients in 1 day is greater than or equal to set threshold and above his delivery strength<br>
				Segments covered : BSE_CASH & NSE_Cash, Period: 1 day <br>
				Thresholds:<br>
				1. Delivery TO : It is a total Delivery TO of the client in EQ BSE_CASH and NSE_CASH<br>
				2. Delivery Multiplier : It is the multiplier for calculating Delivery strength of the client. User can able to select Income or Networth or both<br>
				User have to select any one from Income or Networth or both below is the formula for calculating Delivery strength<br>
				If user select both Income & Networth =  (Income + Networth) * Delivery Multiplier<br>
				If user select only Income = Income * Delivery Multiplier<br>
				If user select only Networth = Networth * Delivery Multiplier<br>'
	FROM dbo.RefAmlReport re
	WHERE re.[Name] = 'S58 Delivery Turnover 1 Day'
GO
--WEB-83758-END RC



