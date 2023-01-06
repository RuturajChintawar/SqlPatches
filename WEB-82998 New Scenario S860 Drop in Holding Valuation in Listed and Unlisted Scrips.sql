--File:Tables:dbo:RefAmlReport:DML
--RC-WEB-82998 START
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
		Threshold2DisplayName,
		[Description]
	) VALUES (
		1296,
		'S860 Drop In Holding Valuation In Listed And Unlisted Scrips',
		'System',
		GETDATE(),
		'System',
		GETDATE(),
		1,
		'S860',
		@RefAlertRegisterCaseTypeId,
		1, 
		'S860DropInHoldingValuationInListedAndUnlistedScrips',
		1,
		@FrequencyFlagRefEnumValueId,
		860,
		'Listed Scrip Loss % =>',
		'Unlisted Scrip Loss % =>',
		'Client with significant history with the securities firm who abruptly liquidates all their assests in order to remove wealth from Jurisdiction<br>
		Segments: CDSL, NSDL ; Frequency: Daily ; Period: One day<br>
		Thresholds: <br>
		<b>1.Listed Scrip loss%</b> : It is the total parcentage loss done by the client in a particular listed scrip with resepct to its sell transaction value  <br>
		<b>2.Unlisted Scrip loss%</b>  : It is the total parcentage loss done by the client in a particular listed scrip with resepct to its sell transaction value<br>
		<b>3.Account Segment</b> : Account segment mapped to the DP account <br>
		Note: <br>
		1. Segment wise/scrip wise alert will be created<br> '
	)
GO
--RC-WEB-82998 END
--File:Tables:dbo:RefProcess:DML
--RC-WEB-82998 START
GO
	DECLARE	 @EnumValueId INT, @RefAmlReportId INT
	SELECT @EnumValueId = dbo.GetEnumValueId('ProcessType','Simple')
	SELECT @RefAmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S860 Drop In Holding Valuation In Listed And Unlisted Scrips'

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
		'S860 Drop In Holding Valuation In Listed And Unlisted Scrips',
		'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S860DropInHoldingValuationInListedAndUnlistedScrips',
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
		'S860',
		1,
		'S860 Drop In Holding Valuation In Listed And Unlisted Scrips',
		1000
	)
GO
--RC-WEB-82998 END
--File:StoredProcedures:dbo:AML_GetDropInHoldingValuationInListedAndUnlistedScrip
--RC-WEB-82998 START
GO
CREATE PROCEDURE dbo.AML_GetDropInHoldingValuationInListedAndUnlistedScrips

(        
	 @RunDate DATETIME,
	 @ReportId INT
)        
AS        
BEGIN     
	  
	DECLARE @ReportIdInternal INT, @RunDateInternal DATETIME, @NsdlId INT, @CdslId INT, @BSEId INT, @NSEId INT ,@DayPrior7 DATETIME, @NsdlType904 INT, @NsdlType925 INT,@CdslDBId INT,@NsdlDBId INT
		, @NsdlType921 INT, @NsdlType938 INT
    SET @ReportIdInternal = @ReportId 
	SET @RunDateInternal = @RunDate 
	SET @DayPrior7 = DATEADD(DAY, -7, @RunDateInternal)

	SET @CdslId = dbo.GetSegmentId('CDSL')
	SET @NsdlId = dbo.GetSegmentId('NSDL')
	SET @BSEId = dbo.GetSegmentId('BSE_CASH') 
	SET @NSEId = dbo.GetSegmentId('NSE_CASH') 
	
	SET @CdslDBId = (SELECT db.RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum db WHERE db.DatabaseType = 'CDSL')
	SET @NsdlDBId = (SELECT db.RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum db WHERE db.DatabaseType = 'NSDL')
	
	SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 904 AND [Name] = 'Delivery Free of Payment (Inter DP) Instruction'      
	SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'  
	SELECT @NsdlType921 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 921 AND [Name] = 'Corporate Action (Debit)'      
	SELECT @NsdlType938 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 938 AND [Name] = 'ACA Debit'  

	SELECT    
		RefClientId    
	INTO #clientsToExclude    
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
	WHERE (ExcludeAllScenarios = 1 OR RefAmlReportId = @ReportIdInternal)
		  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)

	CREATE TABLE #tradeData (      
	   RefClientId INT,          
	   RefSegmentId INT,          
	   RefIsinId INT,       
	   Quantity BIGINT, 
	  )    
  
   INSERT INTO #tradeData(RefClientId, RefSegmentId, RefIsinId, Quantity)  
	 SELECT      
	  dp.RefClientId,      
	  dp.RefSegmentId,  
	  dp.RefIsinId,  
	  dp.Quantity
	  FROM dbo.CoreDpTransaction dp    
	  LEFT JOIN #clientsToExclude clex ON clex.RefClientId = dp.RefClientId  
	  WHERE dp.RefSegmentId = @CdslId AND clex.RefClientId IS NULL  
	   AND dp.BusinessDate = @RunDateInternal               
	   AND (dp.BuySellFlag = 'D' OR dp.BuySellFlag = 'S') 
     
   INSERT INTO #tradeData(RefClientId,RefSegmentId,RefIsinId,Quantity)  
	   SELECT    
		dp.RefClientId,  
		dp.RefSegmentId,  
		dp.RefIsinId,  
		dp.Quantity
	  FROM   dbo.CoreDPTransactionChangeHistory dp   
	  LEFT JOIN #clientsToExclude clex ON clex.RefClientId = dp.RefClientId  
	  WHERE dp.RefSegmentId = @NsdlId AND clex.RefClientId IS NULL  
	   AND dp.ExecutionDate = @RunDateInternal   
	   AND dp.RefDpTransactionTypeId IN ( @NsdlType904, @NsdlType925,@NsdlType921,@NsdlType938)      
	   AND dp.OrderStatusTo = 51   

	SELECT DISTINCT 
		t.RefIsinId 
	INTO #selectedIsin 
	FROM #tradeData t 


	SELECT 
		isin.RefIsinId,
		CASE WHEN ref.RefSegmentId = @CdslId 
				THEN CASE 
					WHEN ref.CFICode = 2 
						THEN 0 
					WHEN ref.CFICode = 0 
						THEN 1 
					ELSE NULL 
					END	
			ELSE CASE
					WHEN inst.RefInstrumentId IS NULL 
					THEN 0 
					WHEN  LTRIM(RTRIM(inst.[Status])) = 'A'
					THEN 1 
					ELSE NULL
					END 
			END AS lisUnlisBit
	INTO #tempIsinInfo
	FROM #selectedIsin isin
	INNER JOIN dbo.RefIsin ref ON ref.RefIsinId = isin.RefIsinId AND ref.RefSegmentId IN (@CdslId, @NsdlId)
	LEFT JOIN dbo.RefInstrument inst ON ref.[Name] = inst.Isin AND inst.RefSegmentId IN (@BSEId, @NSEId) 

	SELECT 
		DISTINCT
		RefIsinId,
		lisUnlisBit
	INTO #ditinctIsin
	FROM #tempIsinInfo

	SELECT DISTINCT
		tr.RefClientId,
		tr.RefIsinId
	INTO #clientData
	FROM #tradeData tr
	INNER JOIN #ditinctIsin tem ON tem.RefIsinId = tr.RefIsinId
	WHERE tem.lisUnlisBit IS NOT NULL
	
	SELECT
		t.RefClientId,
		t.RefIsinId,
		t.Qty AS totalHoldQty
	INTO #tempClientHolding
	FROM (SELECT 
					ty.RefClientId,
					holding.RefIsinId,  
					holding.CurrentBalanceQuantity AS Qty,
					ROW_NUMBER()OVER(PARTITION BY ty.RefClientId,holding.RefIsinId ORDER BY holding.AsOfDate DESC) rn
         
			FROM dbo.CoreClientHolding holding    
			INNER JOIN dbo.RefClientDematAccount ty ON ty.RefClientDematAccountId = holding.RefClientDematAccountId
			INNER JOIN #clientData temp ON  temp.RefClientId = ty.RefClientId AND temp.RefIsinId = holding.RefIsinId
			WHERE holding.AsOfDate BETWEEN @DayPrior7 AND @RunDateInternal )t
	WHERE t.rn = 1

	SELECT
		tr.RefClientId,
		tr.RefIsinId,
		SUM(tr.Quantity) AS totalQty
	INTO #tempTradeData
	FROM #tradeData tr
	INNER JOIN #ditinctIsin tem ON tem.RefIsinId = tr.RefIsinId
	WHERE tem.lisUnlisBit IS NOT NULL
	GROUP BY tr.RefClientId, tr.RefIsinId

	SELECT DISTINCT
		cl.RefClientId
	INTO #tempDistinctClient
	FROM #clientData cl

	SELECT t.RefClientId, t.RefCustomerSegmentId
	INTO #clientCSMapping
	FROM
	(
		SELECT
			cl.RefClientId,
			linkClCs.RefCustomerSegmentId,
			ROW_NUMBER() OVER(PARTITION BY cl.RefClientId ORDER BY linkClCs.StartDate DESC) AS RN
		FROM #tempDistinctClient cl
		INNER JOIN dbo.LinkRefClientRefCustomerSegment linkClCs ON cl.RefClientId = linkClCs.RefClientId
	) t
	WHERE t.RN = 1

	SELECT
		linkCS.RefCustomerSegmentId,
		rules.Threshold,
		rules.Threshold2
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule rules
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefCustomerSegment linkCS ON rules.RefAmlScenarioRuleId = linkCS.RefAmlScenarioRuleId
	WHERE rules.RefAmlReportId = @ReportIdInternal

	SELECT
		t.RefClientId,t.RefIsinId,t.totalQty,t.totalHoldQty,t.lossPercentage,
		CASE WHEN isin.lisUnlisBit = 1 THEN rules.Threshold ELSE NULL END ListedThreshold,
		CASE WHEN isin.lisUnlisBit = 0 THEN rules.Threshold2 ELSE NULL END AS UnListedThreshold,
		csmap.RefCustomerSegmentId
	INTO #finalData
	FROM(SELECT
			tr.RefClientId,
			tr.RefIsinId,
			tr.totalQty,
			hol.totalHoldQty,
			(tr.totalQty/hol.totalHoldQty) * 100 lossPercentage
	
		FROM #tempTradeData tr
		INNER JOIN #tempClientHolding hol ON hol.RefClientId = tr.RefClientId  AND hol.RefIsinId = tr.RefIsinId
		WHERE hol.totalHoldQty <> 0) t
	INNER JOIN #ditinctIsin isin ON isin.RefIsinId = t.RefIsinId
	LEFT JOIN #clientCSMapping csmap ON csmap.RefClientId = t.RefClientId
	INNER JOIN #scenarioRules rules ON ISNULL(csmap.RefCustomerSegmentId,0) = ISNULL(rules.RefCustomerSegmentId, 0)
	WHERE (isin.lisUnlisBit = 1 AND t.lossPercentage >= rules.Threshold ) OR (isin.lisUnlisBit = 0 AND t.lossPercentage >= rules.Threshold2)

	
	SELECT t.RefIsinId, t.Isin, t.[Name],t.RefSegmentId,t.RefInstrumentId
	INTO #instrumentData
	FROM
	(
		SELECT 
			isin.RefIsinId,
			isin.[Name] AS Isin,
			CASE 
				WHEN (ISNULL(inst.[Name], '') ='') THEN isin.[IsinShortName]
				ELSE inst.[Name] 
			END AS [Name],
			ROW_NUMBER() OVER (PARTITION BY isin.[Name] ORDER BY inst.RefSegmentId DESC) AS RN,
			isin.RefSegmentId,
			inst.RefInstrumentId
		FROM #selectedIsin  ref
		INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = ref.RefIsinId
		LEFT JOIN dbo.RefInstrument inst ON inst.Isin = isin.[Name] AND inst.RefSegmentId in (@BSEId,@NSEId)  AND LTRIM(RTRIM(inst.[Status])) = 'A'
	)t
	WHERE t.RN = 1
	SELECT
		cl.RefClientId,
		inst.RefIsinId,
		inst.RefInstrumentId,
		CASE WHEN  cl.RefClientDatabaseEnumId = @CdslDBId THEN @CdslId WHEN cl.RefClientDatabaseEnumId = @NsdlDBId THEN @NsdlId ELSE NULL END  AS RefSegmentId,
		cl.ClientId,
		cl.[Name] AS ClientName,
		CASE  WHEN cl.RefClientDatabaseEnumId = @CdslDBId THEN 'CDSL' WHEN cl.RefClientDatabaseEnumId = @NsdlDBId THEN  'NSDL' ELSE NULL END  AS Depository,
		CASE 
			WHEN cl.DpId IS NULL THEN ''
			ELSE 'IN' +  CONVERT(VARCHAR(MAX),cl.DpId) COLLATE DATABASE_DEFAULT
		END AS DpId,
		@RunDateInternal AS TransactionDate,
		inst.Isin,
		inst.[Name] IsinName,
		fd.totalQty,
		fd.totalHoldQty,
		fd.lossPercentage,
		fd.ListedThreshold,
		fd.UnListedThreshold,
		accseg.[Name] AS AccountSegment
	FROM #finalData fd
	INNER JOIN dbo.RefClient cl  ON cl.RefClientId = fd.RefClientId
	INNER JOIN #instrumentData inst ON inst.RefIsinId = fd.RefIsinId
	LEFT JOIN dbo.RefCustomerSegment accseg ON accseg.RefCustomerSegmentId = fd.RefCustomerSegmentId
 END 
GO
--RC-WEB-82998 END