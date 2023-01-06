--File:Tables:dbo:RefAmlReport:DML
--WEB-84980-START RC
GO
	DECLARE @RefAlertRegisterCaseTypeId INT, @FrequencyFlagRefEnumValueId INT

	SELECT @RefAlertRegisterCaseTypeId = RefAlertRegisterCaseTypeId FROM dbo.RefAlertRegisterCaseType WHERE [Name] = 'AML'
	SELECT @FrequencyFlagRefEnumValueId = dbo.GetEnumValueId('PeriodFrequency', 'Daily')

	SET IDENTITY_INSERT dbo.RefAmlReport ON
	INSERT INTO dbo.RefAmlReport (
		RefAmlReportId,
		[Name],
		AddedBy,
		AddedOn,
		LastEditedBy,
		EditedOn,
		RuleWritingEnabled,
		Code,
		RefAlertRegisterCaseTypeId,
		IsRuleRequired, 
		ClassName,
		IsLicensed,
		FrequencyFlagRefEnumValueId,
		ScenarioNo,
		Threshold1DisplayName,
		[Description]
	) VALUES (
		1302,
		'S199 Client Net Sell in a specified period',
		'System',
		GETDATE(),
		'System',
		GETDATE(),
		1,
		'S199',
		@RefAlertRegisterCaseTypeId,
		1, 
		'S199ClientNetSellInASpecificPeriod',
		1,
		@FrequencyFlagRefEnumValueId,
		199,
		'Client TO Net Sell',
		'This scenario will help to identify the whether Client''s net sell turnover is commensurating with the fair value</br>
		Segments:BSE Cash , NSE Cash ; Frequency: Daily ; Period: Lookback period</br>
		Thresholds: </br>
		<b>1. Client TO Net Sell : </b>Net Sell value of the client in a specified lookback period with respect to buy and sell value</br> 
		<b>2. Lookback Period (Days) : </b>Period for which Client TO net sell will be calculated</br>
		<b>3. Client Type : </b>Category of the client</br>'
	)
GO
--WEB-84980-END RC

--File:Tables:dbo:SysAmlReportSetting:DML
--WEB-84980-START RC
GO
	DECLARE @AmlReportId INT

	SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S199 Client Net Sell in a specified period'

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
		'Receipt_Transaction_Lookback_Period',
		'0',
		1,
		'Lookback period (Days)',
		1,
		GETDATE(),
		'System',
		GETDATE(),
		'System'
	)
GO
--WEB-84980-END RC

--File:Tables:dbo:RefProcess:DML
--WEB-84980-START RC
GO
	DECLARE	 @EnumValueId INT, @RefAmlReportId INT

	SELECT @EnumValueId = dbo.GetEnumValueId('ProcessType','Simple')
	SELECT @RefAmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S199 Client Net Sell in a specified period'

	INSERT INTO dbo.RefProcess (
		[Name],
		ClassName,
		AssemblyName,
		IsActive,
		IsScheduleEditable,
		AddedBy,
		AddedOn,
		EditedOn,
		LastEditedBy,
		RefAmlReportId,
		ProcessTypeRefEnumValueId,
		IsCompanyWise,
		Code,
		EnableRunDateSelection,
		DisplayName,
		LockingGroupId
	) VALUES (
		'S199 Client Net Sell in a specified period',
		'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S199ClientNetSellInASpecificPeriod',
		'TSS.SmallOfficeWeb.ManageData',
		1,
		1,
		'System',
		GETDATE(),
		GETDATE(),
		'System',
		@RefAmlReportId,
		@EnumValueId,
		0,
		'S199',
		1,
		'S199 Client Net Sell in a specified period',
		1000
	)
GO
--WEB-84980-END RC

--File:StoredProcedures:dbo:AML_GetClientNetSellInASpecifiedPeriod
--WEB-84980-START RC
GO
	CREATE PROCEDURE dbo.AML_GetClientNetSellInASpecifiedPeriod 
		(     
			@TradeDate DATETIME,      
			@RefAmlReportId INT
		)      
	AS 
	BEGIN 
      
		DECLARE @RefAmlReportIdInternal INT, @TradeDateInternal DATETIME, @FromDate DATETIME,  @BSECashId INT, @NSECashId INT,
			@LookBack INT, @ProfileDefault INT, @DefaultIncome DECIMAL(28, 2), @DefaultIncomeAbove1Cr DECIMAL(28, 2), 
			@ClientPurchaseToIncomeId INT, @DefaultIncomeMultiplier DECIMAL(28,2), @DefaultNetworthMultiplier DECIMAL(28,2),@DefaultNetworth DECIMAL(28,2)
       
		SET @RefAmlReportIdInternal = @RefAmlReportId 
		SET @TradeDateInternal = @TradeDate  
	
		SET @LookBack = (SELECT CONVERT(INT,syst.[Value]) FROM dbo.SysAmlReportSetting syst 
							WHERE syst.RefAmlReportId = @RefAmlReportIdInternal AND syst.[Name] = 'Receipt_Transaction_Lookback_Period')
	
		SET @FromDate = DATEADD(dd,- @LookBack , @TradeDateInternal)  
	   
		SET @BSECashId = dbo.GetSegmentId('BSE_CASH')
		SET @NSECashId = dbo.GetSegmentId('NSE_CASH')

		SELECT @DefaultIncomeMultiplier = CONVERT(DECIMAL(28,2),[Value])FROM dbo.SysConfig WHERE [Name] = 'Aml_Client_Income_Multiplier' 
		SELECT @DefaultNetworthMultiplier = CONVERT(DECIMAL(28,2),[Value])FROM dbo.SysConfig WHERE [Name] = 'Aml_Client_Networth_Multiplier' 
		SELECT @DefaultIncomeAbove1Cr = CONVERT(DECIMAL(28, 2), ISNULL([Value], 0)) FROM dbo.SysConfig WHERE [Name] = 'Income_Value_For_Above_One_Crore'    
		SELECT @DefaultNetworth = CONVERT(DECIMAL(28, 2), ISNULL([Value], 0)) FROM dbo.SysConfig WHERE [Name] = 'Aml_Client_Default_Networth' 
		
		SELECT @ProfileDefault = RefAmlQueryProfileId FROM dbo.RefAmlQueryProfile WHERE [Name] = 'Default'  
		SELECT @ClientPurchaseToIncomeId = amlReport.RefAmlReportId FROM dbo.RefAmlReport amlReport WHERE amlReport.[Name] = 'Client Purchase to Income'   
	
		SELECT @DefaultIncome = CONVERT(DECIMAL(28, 2), ISNULL([Value], 0)) FROM dbo.SysConfig WHERE [Name] = 'Aml_Client_Default_Income' 
		
		SELECT      
			RefClientId      
		INTO #clientsToExclude      
		FROM dbo.LinkRefAmlReportRefClientAlertExclusion      
		WHERE (ExcludeAllScenarios = 1 OR RefAmlReportId = @RefAmlReportIdInternal) AND @TradeDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @TradeDateInternal)

		SELECT DISTINCT
			tr.RefClientId
		INTO #DistinctClientid
		FROM dbo.CoreTrade tr
		LEFT JOIN #clientsToExclude clex ON clex.RefClientId = tr.RefClientId
		WHERE clex.RefClientId IS NULL AND tr.RefSegmentId IN (@BSECashId, @NSECashId) AND tr.TradeDate = @TradeDateInternal  

		SELECT 
			tr.RefClientId,
			tr.Rate * tr.Quantity AS Turnover,
			tr.RefSegmentId,
			CASE WHEN tr.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell
		INTO #tradeData
		FROM dbo.CoreTrade tr
		INNER JOIN #DistinctClientid ids ON ids.RefClientId = tr.RefClientId
		WHERE  tr.RefSegmentId IN (@BSECashId, @NSECashId) AND tr.TradeDate BETWEEN @FromDate AND @TradeDateInternal

		SELECT
			t.RefClientId, t.BSECashBuyValue, t.BSECashSellValue, t.NSECashBuyValue, t.NSECashSellValue,
			(t.BSECashSellValue + t.NSECashSellValue) - (t.BSECashBuyValue + t.NSECashBuyValue)  AS NetSell
		INTO #clientWiseData
		FROM(	SELECT
					RefClientId,
					SUM(CASE WHEN BuySell = 1 AND RefSegmentId = @BSECashId THEN Turnover ELSE 0 END) AS BSECashBuyValue,
					SUM(CASE WHEN BuySell = 0 AND RefSegmentId = @BSECashId THEN Turnover ELSE 0 END) AS BSECashSellValue,
					SUM(CASE WHEN BuySell = 1 AND RefSegmentId = @NSECashId THEN Turnover ELSE 0 END) AS NSECashBuyValue,
					SUM(CASE WHEN BuySell = 0 AND RefSegmentId = @NSECashId THEN Turnover ELSE 0 END) AS NSECashSellValue
				FROM #tradeData
				GROUP BY RefClientId )t

		SELECT 
			tr.RefClientId,
			CASE WHEN la.Income IS NOT NULL      
					THEN la.Income      
					WHEN incGroup.[Name] IS NOT NULL AND incGroup.IncomeTo > 10000000      
					THEN
						CASE WHEN ISNULL(@DefaultIncomeAbove1Cr, 0) <> 0
						THEN @DefaultIncomeAbove1Cr     
						ELSE 10000000
						END      
					WHEN incGroup.[Name] IS NOT NULL      
					THEN incGroup.IncomeTo      
					ELSE @DefaultIncome END AS Income,
			COALESCE(la.Networth, @DefaultNetworth, 0) AS Networth,
			cl.RefClientStatusId,
			cl.[Name] AS ClientName,
			cl.ClientId,
			COALESCE(CONVERT(VARCHAR,la.Income), incGroup.[Name],CONVERT(VARCHAR,@DefaultIncome)) AS IncomeGroup,
			CASE WHEN ISNULL( cl.IncomeMultiplier,0) <> 0 THEN cl.IncomeMultiplier WHEN ISNULL(@DefaultIncomeMultiplier, 0) <> 0 THEN @DefaultIncomeMultiplier ELSE 1 END AS IncomeMultiplier,
			CASE WHEN ISNULL( cl.NetworthMultiplier, 0) <> 0 THEN cl.NetworthMultiplier WHEN ISNULL(@DefaultNetWorthMultiplier, 0) <> 0 THEN @DefaultNetWorthMultiplier ELSE 1 END AS NetworthMultiplier
		INTO #IncomeData
		FROM #clientWiseData tr
		INNER JOIN dbo.RefClient cl ON tr.NetSell > 0 AND cl.RefClientId = tr.RefClientId 
		LEFT JOIN dbo.LinkRefClientRefIncomeGroupLatest la ON tr.RefClientId = la.RefClientId
		LEFT JOIN dbo.RefIncomeGroup incGroup ON ISNULL(la.RefIncomeGroupId ,0)= ISNULL(incGroup.RefIncomeGroupId,0)

		SELECT DISTINCT
			scenarioRule.RefAmlScenarioRuleId,
			scenarioRule.Threshold,
			linkClientStatus.RefClientStatusId
		INTO #scenarioRules
		FROM dbo.RefAmlScenarioRule scenarioRule      
		INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus linkClientStatus 
			ON scenarioRule.RefAmlScenarioRuleId = linkClientStatus.RefAmlScenarioRuleId      
		WHERE scenarioRule.RefAmlReportId = @RefAmlReportIdInternal

		SELECT 
			pti.RefClientId, 
			inc.ClientId,
			inc.ClientName,
			@FromDate AS TradeFromDate,
			@TradeDate AS TradeToDate,
			pti.NetSell AS NetSell,
			pti.BSECashBuyValue + pti.NSECashBuyValue AS TotalBuyValue,
			pti.BSECashSellValue + pti.NSECashSellValue AS TotalSellValue,      
			inc.IncomeGroup AS Income,
			inc.NetWorth AS Networth,
			inc.IncomeMultiplier,
			inc.NetworthMultiplier,
			(inc.Income * inc.IncomeMultiplier + inc.NetworthMultiplier * inc.Networth) AS FairValue,
			pti.BSECashBuyValue,
			pti.BSECashSellValue,
			pti.NSECashBuyValue,
			pti.NSECashSellValue,
			CASE WHEN (pti.BSECashBuyValue + pti.BSECashSellValue) > (pti.NSECashBuyValue + pti.NSECashSellValue ) THEN @BSECashId 
				ELSE @NSECashId
				END RefSegmentId
		FROM #clientWiseData pti  
		INNER JOIN #IncomeData inc ON pti.NetSell > 0 AND pti.RefClientId= inc.RefClientId
		INNER JOIN #scenarioRules rules ON inc.RefClientStatusId = rules.RefClientStatusId AND pti.NetSell >= rules.Threshold
		WHERE pti.NetSell >= (inc.Income * inc.IncomeMultiplier + inc.NetworthMultiplier * inc.Networth) 

	END     
GO
--WEB-84980-END RC
