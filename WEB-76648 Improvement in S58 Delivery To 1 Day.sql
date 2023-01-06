--File:StoredProcedures:dbo:Aml_GetDeliveryTurnover
--RC-WEB -76648 START
GO
ALTER PROCEDURE [dbo].[Aml_GetDeliveryTurnover]
(

	@RunDate DATETIME 
)
AS
BEGIN
	DECLARE @BseCashId INT,@NseCashId INT, @ExcludePro BIT,@ExcludeInstitution BIT,@DeliveryMultiplier INT,@ThresholdDeliveryTurnoverEquity DECIMAL(28,4),
		@RunDateInternal DATETIME, @RefAmlReportId INT, @ProRefClientStatusId INT, @InstitutionRefClientStatusId INT, @DefaultIncome VARCHAR (5000), @DefaultNetworth BIGINT
	
	SET @BseCashId = dbo.GetSegmentId('BSE_CASH')
	SET @NseCashId = dbo.GetSegmentId('NSE_CASH')
	SET @RunDateInternal = @RunDate
	SET @RefAmlReportId = (SELECT ref.RefAmlReportId FROM dbo.RefAmlReport ref WHERE ref.[Name] = 'S58 Delivery Turnover 1 Day' )

	SET @ThresholdDeliveryTurnoverEquity = (SELECT CONVERT(DECIMAL(28,2),syst.[Value] )FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @RefAmlReportId AND syst.[Name] = 'Delivery_Turnover_Equity')
	SET @DeliveryMultiplier = (SELECT CONVERT(INT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @RefAmlReportId AND syst.[Name] = 'Delivery_Multiplier')
	SET @ExcludePro = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @RefAmlReportId AND syst.[Name] = 'Exclude_Pro')
    SET @ExcludeInstitution = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @RefAmlReportId AND syst.[Name] = 'Exclude_Institution')
	
	SET @ProRefClientStatusId = (SELECT sta.RefClientStatusId FROM dbo.RefClientStatus sta WHERE sta.[Name] = 'Pro')
	SET @InstitutionRefClientStatusId = (SELECT sta.RefClientStatusId FROM dbo.RefClientStatus sta WHERE sta.[Name] = 'Institution')

	SELECT RefSegmentEnumId
	INTO #RequiredSegment
	FROM RefSegmentEnum 
	WHERE Segment IN ('BSE_CASH','NSE_CASH')

	 
	SELECT DISTINCT
		RefClientId
	INTO #clientsToExclude
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex
	WHERE (ex.RefAmlReportId = @RefAmlReportId OR ex.ExcludeAllScenarios = 1) 
		AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)

	SELECT
		tr.RefClientId,
		tr.RefSegmentId,
		tr.RefInstrumentId,
		CASE WHEN tr.BuySell = 'Buy' THEN 0 ELSE 1 END AS BuySellFlag,
		tr.Quantity,
		tr.Rate,
		(tr.Quantity * tr.Rate) AS TurnOver
	INTO #tradedata
	FROM dbo.CoreTrade tr
	INNER JOIN #RequiredSegment segment ON tr.RefSegmentId= segment.RefSegmentEnumId AND tr.TradeDate = @RunDateInternal
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = tr.RefClientId
															AND (@ExcludePro = 0 OR cl.RefClientStatusId <> @ProRefClientStatusId)
															AND	(@ExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstitutionRefClientStatusId)
	LEFT JOIN #clientsToExclude clTEx ON clTEx.RefClientId = tr.RefClientId
	WHERE clTEx.RefClientId IS NULL


	SELECT 
		t.RefClientId,
		t.RefSegmentId,
		SUM(ABS(t.BuyQty - t.SellQty) * (CASE WHEN t.BuyQty > t.SellQty THEN t.BuyTO/BuyQty  ELSE t.SellTO/SellQty  END)) DelTo
	INTO #tradeDataSegmentWise
	FROM
		(
			SELECT
				tr.RefClientId,
				tr.RefSegmentId,
				tr.RefInstrumentId,
				SUM(CASE WHEN tr.BuySellFlag = 0 THEN tr.Quantity ELSE 0 END) AS BuyQty,
				SUM(CASE WHEN tr.BuySellFlag = 1 THEN tr.Quantity ELSE 0 END) AS SellQty,
				SUM(CASE WHEN tr.BuySellFlag = 0 THEN tr.TurnOver ELSE 0 END) AS BuyTO,
				SUM(CASE WHEN tr.BuySellFlag = 1 THEN tr.TurnOver ELSE 0 END) AS SellTO
			FROM #tradedata tr
			GROUP BY tr.RefClientId, tr.RefInstrumentId, tr.RefSegmentId
		)t
	GROUP BY t.RefClientId, t.RefSegmentId

	SELECT 
		tr.RefClientId,
		SUM(CASE WHEN tr.RefSegmentId = @BseCashId THEN tr.DelTo ELSE 0 END) AS DelBseTo,
		SUM(CASE WHEN tr.RefSegmentId = @NseCashId THEN tr.DelTo ELSE 0 END) AS DelNseTo,
		SUM(tr.DelTo) AS DelTo
	INTO #finalTrade
	FROM #tradeDataSegmentWise tr
	GROUP BY tr.RefClientId


	
	--DefaultNetworth remains same for all segments
	SELECT	@DefaultNetworth = cliNetSellPoint.DefaultNetworth 
	FROM	dbo.RefAmlQueryProfile qp  	
			LEFT JOIN dbo.LinkRefAmlQueryProfileRefSegment qpSegment ON qpSegment.RefSegmentId = @BseCashId
						AND qpSegment.RefAmlQueryProfileId = qp.RefAmlQueryProfileId				  
			LEFT JOIN dbo.SysAmlClientNetSellPoints cliNetSellPoint ON cliNetSellPoint.LinkRefAmlQueryProfileRefSegmentId = qpSegment.LinkRefAmlQueryProfileRefSegmentId
	WHERE	qp.[Name] = 'Default'	
            
	SELECT	@DefaultIncome = reportSetting.[Value]
	FROM	dbo.RefAmlQueryProfile qp 		
	LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.[Name] = 'Client Purchase to Income'
	LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId
				AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId
				AND reportSetting.[Name] = 'Default_Income'
	WHERE	qp.[Name] = 'Default'
	DECLARE @RefIncomeGroupId INT, @DefaultAboveOneCr DECIMAL(28,2)
	SET @RefIncomeGroupId = (SELECT grp.RefIncomeGroupId FROM dbo.RefIncomeGroup grp WHERE grp.Code = 6)
	SET @DefaultAboveOneCr = (SELECT CONVERT(DECIMAL(28,2),syst.[Value]) FROM dbo.SysConfig syst WHERE syst.[Name] ='Income_Value_For_Above_One_Crore')
	SELECT  
		cni.RefClientId,
		client.RefIntermediaryId,
		(CASE WHEN client.DeliveryMultiplier IS NULL AND cni.DefaultAboveOneCr IS NULL THEN ((cni.Income + cni.Networth) * (@DeliveryMultiplier))
			WHEN  cni.DefaultAboveOneCr IS NULL THEN ((cni.Income + cni.Networth) * (client.DeliveryMultiplier))
			ELSE ((cni.DefaultAboveOneCr + cni.Networth) * (client.DeliveryMultiplier)) END) AS TradingStrength
	INTO #ClientTradingStrength
	FROM
		(SELECT DISTINCT
			COALESCE (clientIncomeGroup.Networth, cliIncomeGroupLatest.Networth, @DefaultNetworth, 0) AS Networth,
			COALESCE (clientIncomeGroup.Income, cliIncomeGroupLatest.Income, incomeGroup.IncomeTo, CONVERT(BIGINT , @DefaultIncome), 0) AS Income,
			trade.RefClientId,
			CASE WHEN ISNULL (clientIncomeGroup.RefIncomeGroupId ,cliIncomeGroupLatest.RefIncomeGroupId ) = @RefIncomeGroupId AND cliIncomeGroupLatest.Income IS NULL AND ISNULL(@DefaultAboveOneCr, 0) <> 0
				THEN @DefaultAboveOneCr
				WHEN ISNULL (clientIncomeGroup.RefIncomeGroupId ,cliIncomeGroupLatest.RefIncomeGroupId ) = @RefIncomeGroupId AND cliIncomeGroupLatest.Income IS NULL THEN 10000000 
				ELSE NULL
			END AS DefaultAboveOneCr
			FROM #finalTrade trade 
				 INNER JOIN dbo.RefClient rc ON rc.RefClientId = trade.RefClientId
				 LEFT JOIN dbo.LinkRefClientRefIncomeGroup clientIncomeGroup ON (clientIncomeGroup.RefClientId = trade.RefClientId)
							AND (@RunDateInternal >= clientIncomeGroup.FromDate OR clientIncomeGroup.FromDate IS NULL) 
							AND (@RunDateInternal <= clientIncomeGroup.ToDate OR clientIncomeGroup.ToDate IS NULL)
				 LEFT JOIN dbo.LinkRefClientRefIncomeGroupLatest cliIncomeGroupLatest ON cliIncomeGroupLatest.RefClientId = trade.RefClientId
				 LEFT JOIN dbo.RefIncomeGroup incomeGroup ON incomeGroup.RefIncomeGroupId = ISNULL(clientIncomeGroup.RefIncomeGroupId,cliIncomeGroupLatest.RefIncomeGroupId)
		)cni
		INNER JOIN dbo.RefClient client ON (client.RefClientId = cni.RefClientId)		
		
	SELECT 
		ft.RefClientId,
		client.ClientId,
		client.[Name] AS ClientName,
		cts.TradingStrength,
		ft.DelTo,
		ft.DelBseTo,
		ft.DelNseTo,
		CASE WHEN ft.DelBseTo > ft.DelNseTo THEN @BseCashId ELSE @NseCashId END AS RefSegmentId
	FROM
		#finalTrade ft
		INNER JOIN dbo.RefClient client ON client.RefClientId = ft.RefClientId
		INNER JOIN #ClientTradingStrength cts ON ft.RefClientId = cts.RefClientId
	WHERE
		ft.DelTo >= @ThresholdDeliveryTurnoverEquity AND ft.DelTo >= cts.TradingStrength
			
END
GO
--RC-WEB -76648 END
--File:StoredProcedures:dbo:CoreAmlDeliveryTurnoverScenarioAlert_Get
--RC-WEB -76648 START
GO
ALTER PROCEDURE [dbo].[CoreAmlDeliveryTurnoverScenarioAlert_Get]
(
	@CaseId INT,  
	@ReportId INT 
)
AS
BEGIN
	SELECT 
		alert.CoreAmlScenarioAlertId,
		alert.CoreAlertRegisterCaseId,
		alert.RefClientId,
		client.ClientId,
		client.Name AS ClientName,
		alert.RefAmlReportId,
		alert.Transactiondate,
		alert.DeliveryTurnover,
		alert.TradingStrength,
		alert.MoneyIn,
		alert.MoneyOut,
		alert.Status,
		alert.AddedOn,
		alert.AddedBy,
		alert.EditedOn,
		alert.LastEditedBy,
		alert.ReportDate,
		alert.Comments,
		alert.ClientExplanation
	FROM dbo.CoreAmlScenarioAlert alert
		INNER JOIN dbo.RefAmlReport report ON alert.RefAmlReportId = report.RefAmlReportid
		INNER JOIN dbo.RefClient client ON alert.RefClientId = client.RefClientId
		INNER JOIN dbo.CoreAlertRegisterCase c ON alert.CoreAlertRegisterCaseId = c.CoreAlertRegisterCaseId
	WHERE
		alert.CoreAlertRegisterCaseId = @CaseId AND report.RefAmlReportId = @ReportId
END
GO
--RC-WEB -76648 END

--File:StoredProcedures:dbo:CoreAmlDeliveryTurnoverScenarioAlert_Search
--RC-WEB -76648 START
GO
ALTER PROCEDURE dbo.CoreAmlDeliveryTurnoverScenarioAlert_Search 
(
	@ReportId INT,  
	@RefSegmentEnumId INT = NULL,
	@FromDate DATETIME = NULL,  
	@ToDate DATETIME = NULL,  
	@AddedOnFromDate DATETIME = NULL,  
	@AddedOnToDate DATETIME = NULL,
	@TxnFromDate DATETIME = NULL,  
	@TxnToDate DATETIME = NULL,  
	@EditedOnFromDate DATETIME = NULL,  
	@EditedOnToDate DATETIME = NULL, 
	@Client VARCHAR(500) = NULL,  
	@Status INT = NULL,  
	@Comments VARCHAR(500) = NULL,
	@Scrip VARCHAR(200) = NULL,
	@CaseId BIGINT = NULL,
	@PageNo INT = 1,
	@PageSize INT = 100
)
AS
BEGIN
	
	DECLARE @InternalScrip VARCHAR(200), @InternalPageNo INT, @InternalPageSize INT
	
	SET @InternalScrip = @Scrip
	SET @InternalPageNo = @PageNo
	SET @InternalPageSize = @PageSize

	CREATE TABLE #data	(CoreAmlScenarioAlertId BIGINT)
	INSERT INTO #data EXEC dbo.CoreAmlScenarioAlert_SearchCommon 
		@ReportId = @ReportId,
		@RefSegmentEnumId = @RefSegmentEnumId,
		@FromDate = @FromDate,
		@ToDate = @ToDate,
		@AddedOnFromDate = @AddedOnFromDate,
		@AddedOnToDate = @AddedOnToDate,  
		@EditedOnFromDate = @EditedOnFromDate,  
		@EditedOnToDate = @EditedOnToDate, 
		@TxnFromDate = @TxnFromDate,  
		@TxnToDate = @TxnToDate,
		@Client = @Client ,
		@Status = @Status,
		@Comments = @Comments,	
		@CaseId = @CaseId 

	SELECT 
		alert.CoreAmlScenarioAlertId,
		alert.CoreAlertRegisterCaseId, 
		alert.RefClientId,
		alert.RefAmlReportId,
		client.ClientId,
		client.[Name] AS ClientName,
		alert.MoneyIn,
		alert.MoneyOut,
		alert.DeliveryTurnover,
		alert.TradingStrength,
		alert.[Status],
		alert.AddedBy,
		alert.AddedOn,
		alert.LastEditedBy,
		alert.EditedOn,
		alert.ReportDate,
		alert.TransactionDate,
		alert.Comments,
		alert.ClientExplanation,
		ROW_NUMBER() OVER (ORDER BY alert.AddedOn DESC) AS RowNumber  
	INTO #temp
	FROM #data temp 
	INNER JOIN dbo.CoreAmlScenarioAlert alert  ON temp.CoreAmlScenarioAlertId = alert.CoreAmlScenarioAlertId 
	INNER JOIN dbo.RefClient client ON alert.RefClientId = client.RefClientId
	LEFT JOIN dbo.RefInstrument r ON alert.RefInstrumentId = r.RefInstrumentId
	WHERE (@InternalScrip IS NULL OR (r.[Name] LIKE '%' + @InternalScrip + '%' OR r.Code LIKE '%' + @InternalScrip + '%'))
	
	SELECT t.* FROM #temp t
	WHERE t.RowNumber 
	BETWEEN (((@InternalPageNo - 1) * @InternalPageSize) + 1) AND @InternalPageNo * @InternalPageSize
	ORDER BY t.CoreAmlScenarioAlertId DESC

	SELECT COUNT(1) FROM #temp
	
END
GO
--RC-WEB -76648 END

--File:Tables:dbo:RefAmlReport:DML
--RC-WEB -76648 START
GO
	UPDATE ref
	SET ref.[Description] ='This Scenario will detect the Delivery Turnover done by a clients in 1 day is greater than or equal to set threshold and above his delivery strength<br>
	Delivery strength = Income+ networth * Delivery multiplier. Segments covered : BSE_CASH & NSE_Cash, Period: 1 day <br>
	<b>Thresholds:</b><br>
	<b>Delivery TO :</b>Threshold can set for 1 day delivery TO of the client <br>
	<b>Delivery Multiplier :</b> Threshold can use for calculate Delivery strngth of the client'
	FROM  dbo.RefAmlReport ref
	WHERE ref.Code = 'S58'
GO
--RC-WEB -76648 END