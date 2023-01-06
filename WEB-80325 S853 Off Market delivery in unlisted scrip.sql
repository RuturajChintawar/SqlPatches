--File:Tables:dbo:RefAmlReport:DML
--START RC WEB-80325
GO
DECLARE @RefAlertRegisterCaseTypeId INT, @FrequencyFlagRefEnumValueId INT

SELECT @RefAlertRegisterCaseTypeId = RefAlertRegisterCaseTypeId FROM dbo.RefAlertRegisterCaseType WHERE [Name] = 'AML'
SELECT @FrequencyFlagRefEnumValueId = dbo.GetEnumValueId('PeriodFrequency', 'Monthly')


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
	1285,
	'S853 Off Market Delivery In Unlisted Scrip',
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	1,
	'S853',
	@RefAlertRegisterCaseTypeId,
	1, 
	'S853OffMarketDeliveryInUnlistedScrip',
	1,
	@FrequencyFlagRefEnumValueId,
	853,
	'Unlisted share quantity =>',
	'This scenario will help to identify clients transferring multiple unlisted equity shares. <br>
	Segments: CDSL, NSDL ; Frequency: Monthly ; Period: 30 Day <br>
	<b>Thresholds:</b> <br>
	<b>1. Unlisted share quantity:</b> No of unlisted equity shares transferred by a client <br>
	<b>2. Account Segment :</b>  Account segment mapped to the DP account <br>
	<b>Note:</b>   <br>
	1. Only unlisted equity shares will be considered for this scenario<br>
	2.  Only Debit Transactions will be considered for alert generation. <br>
	3. Reason Codes considered for this scenarios are Gift, Donation, Off Market sale<br>
	4. Transfers made for account closure and own account will be excluded <br>
	5. Segment wise/scrip wise alert will be created<br> ')
GO
--END RC WEB-80325

--File:Tables:dbo:RefProcess:DML
--START RC WEB-80325
GO
DECLARE	 @EnumValueId INT, @RefAmlReportId INT
SELECT @EnumValueId = dbo.GetEnumValueId('ProcessType','Simple')
SELECT @RefAmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S853 Off Market Delivery In Unlisted Scrip'
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
	'S853 Off Market Delivery In Unlisted Scrip',
	'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S853OffMarketDeliveryInUnlistedScrip',
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
	'S853',
	1,
	'S853 Off Market Delivery In Unlisted Scrip',
	1000)
GO
--END RC WEB-80325

--File:StoredProcedures:dbo:Aml_GetOffMarketDeliveryInUnlistedScrip
--END RC WEB-80325
GO
CREATE PROCEDURE dbo.Aml_GetOffMarketDeliveryInUnlistedScrip
(
	@Rundate DATETIME,
	@ReportId INT,
	@IsAlertDulicationAllowed BIT = 1   
)
AS
BEGIN
	DECLARE @RunDateInternal DATETIME,  @ReportIdInternal INT, @NsdlId INT, @CdslId INT, @BSEId INT, @NSEId INT,
			@CdslType2 INT, @CdslType3 INT, @CdslType5 INT, @CdslStatus305 INT, @CdslStatus511 INT, @NsdlType904 INT, @NsdlType925 INT,
			@EndDate DATETIME , @StartDate DATETIME, @IsAlertDulicationAllowedInternal BIT

	SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)
	SET @ReportIdInternal = @ReportId

	SET @StartDate = DATEADD(mm, DATEDIFF(mm, 0, @RunDateInternal) - 1, 0)
	SET @EndDate = DATEADD(DAY, -(DAY(@RunDateInternal)), @RunDateInternal) + CONVERT(DATETIME, '23:59:59.000')  
	
	SET @IsAlertDulicationAllowedInternal = @IsAlertDulicationAllowed  

	SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'CDSL'
	SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSDL'

	SELECT @BSEId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'BSE_CASH'
	SELECT @NSEId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSE_CASH'

	SELECT @CdslType2 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 2 AND [Name] = 'Transactions within DP'
	SELECT @CdslType3 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 3 AND [Name] = 'Transactions across DPs'
	SELECT @CdslType5 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 5 AND [Name] = 'Inter-depository'

	SELECT @CdslStatus305 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 305
	SELECT @CdslStatus511 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 511  

	SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 904 AND [Name] = 'Delivery Free of Payment (Inter DP) Instruction'
	SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'

	
	SELECT RefClientId 
	INTO #clientsToExclude
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion
	WHERE (ExcludeAllScenarios = 1 OR RefAmlReportId = @ReportIdInternal)
		  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)

	CREATE TABLE #tradeData 
	(
		TransactionId BIGINT,
		RefClientId INT,
		RefSegmentId INT,
		RefIsinId INT,
		Quantity BIGINT,
		RefDpTransactionTypeId INT,
		BusinessDate DATETIME,
		OtherDpid VARCHAR(16) COLLATE DATABASE_DEFAULT,  
		OtherClientId VARCHAR(MAX) COLLATE DATABASE_DEFAULT,
		ReasonCode	VARCHAR(20) COLLATE DATABASE_DEFAULT,
		ReasonCodeId INT
	)
	CREATE TABLE #tempReasonCode
	(
		ReasonCodeId INT,
		SegmentId INT,
		ReasonCode VARCHAR(20) COLLATE DATABASE_DEFAULT
	)

	INSERT INTO  #tempReasonCode VALUES 
	( 1, @CdslId, 'Gift'),( 2, @CdslId, 'Off Market Sale'),
	( 16, @CdslId, 'Donation'),( 1, @NsdlId, 'Off Market Sale'),
	( 92, @NsdlId, 'Gift'),( 93, @NsdlId, 'Donation')

	INSERT INTO #tradeData (TransactionId, RefClientId, RefSegmentId, RefIsinId, Quantity, ReasonCode, RefDpTransactionTypeId ,BusinessDate, OtherDpid, OtherClientId,ReasonCodeId)
	SELECT
		dp.CoreDpTransactionId,
		dp.RefClientId,
		dp.RefSegmentId,
		dp.RefIsinId,
		CONVERT(BIGINT, dp.Quantity) AS Quantity,
		trc.ReasonCode,
		dp.RefDpTransactionTypeId,
		dp.BusinessDate,
		CASE WHEN SUBSTRING(ISNULL(dp.CounterBOId,''),1,2) = 'IN'  THEN SUBSTRING(ISNULL(dp.CounterBOId,''), 3, 6) ELSE NULL  END,
		CASE WHEN SUBSTRING(ISNULL(dp.CounterBOId,''),1,2) = 'IN'  THEN SUBSTRING(ISNULL(dp.CounterBOId,''), 9, 8) ELSE ISNULL(dp.CounterBOId,'') END,
		trc.ReasonCodeId
	FROM dbo.CoreDpTransaction dp
	INNER JOIN dbo.RefIsin isi ON isi.RefIsinId = dp.RefIsinId AND isi.CFICode = 2
	LEFT JOIN #tempReasonCode trc ON trc.SegmentId = dp.RefSegmentId AND dp.ReasonForTrade = trc.ReasonCodeId  
	LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId
	WHERE clEx.RefClientId IS NULL
		  AND dp.RefSegmentId = @CdslId
		  AND ((dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3) AND dp.RefDpTransactionStatusId = @CdslStatus305)
		  	  OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511)) 
		  AND (trc.ReasonCodeId IS NOT NULL OR dp.RefDpTransactionTypeId = @CdslType5 )
		  AND (dp.BusinessDate BETWEEN @StartDate AND @EndDate)
		  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')      
		  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')  
		  AND (dp.BuySellFlag = 'D' OR dp.BuySellFlag = 'S') 
		  
	INSERT INTO #tradeData (TransactionId, RefClientId, RefSegmentId, RefIsinId, Quantity ,ReasonCode,RefDpTransactionTypeId, BusinessDate,OtherDpid ,OtherClientId,ReasonCodeId) 
	SELECT DISTINCT
		dp.CoreDPTransactionChangeHistoryId,
		dp.RefClientId,
		dp.RefSegmentId,
		dp.RefIsinId,
		CONVERT(BIGINT, dp.Quantity) AS Quantity,
		trc.ReasonCode,
		dp.RefDpTransactionTypeId,
		dp.ExecutionDate,
		CASE WHEN dp.RefDpTransactionTypeId = @NsdlType904 AND SUBSTRING(ISNULL(dp.OtherDPId,''),1,2) = 'IN' THEN SUBSTRING(ISNULL(dp.OtherDPId,''), 3, 6) 
			 WHEN dp.RefDpTransactionTypeId = @NsdlType925 AND SUBSTRING(ISNULL(dp.OtherDPCode,''),1,2) = 'IN' THEN SUBSTRING(ISNULL(dp.OtherDPCode,''), 3, 6)	
			 ELSE NULL END,  
		CASE WHEN dp.RefDpTransactionTypeId = @NsdlType904 THEN CASE WHEN SUBSTRING(ISNULL(dp.OtherDPId,''),1,2) = 'IN' THEN CONVERT(VARCHAR(MAX), dp.OtherClientId) ELSE CONVERT(VARCHAR(20),ISNULL(dp.OtherDPId,'') ) + CONVERT(VARCHAR(MAX), dp.OtherClientId)END
		WHEN dp.RefDpTransactionTypeId = @NsdlType925 THEN CASE WHEN SUBSTRING(ISNULL(dp.OtherDPCode,''),1,2) = 'IN' THEN ISNULL(dp.OtherClientCode,'') ELSE ISNULL(dp.OtherDPCode,'')+ISNULL(dp.OtherClientCode,'') END   ELSE ISNULL(dp.OtherClientCode,'') END,
		trc.ReasonCodeId
	FROM dbo.CoreDPTransactionChangeHistory dp
	INNER JOIN #tempReasonCode trc ON CONVERT(INT,dp.TransferReasonCode) = trc.ReasonCodeId AND trc.SegmentId = dp.RefSegmentId 
	INNER JOIN  dbo.RefIsin isin ON isin.RefIsinId = dp.RefIsinId
	LEFT JOIN dbo.RefInstrument inst ON inst.Isin = isin.[Name] AND inst.RefSegmentId IN (@BSEId, @NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'
	
	LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId
	WHERE  clEx.RefClientId IS NULL
		  AND inst.RefInstrumentId IS NULL
		  AND dp.RefSegmentId = @NsdlId
		  AND dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType925 )
		  AND dp.OrderStatusTo = 51
		  AND (dp.ExecutionDate BETWEEN @StartDate AND @EndDate)  
		  AND (LTRIM(ISNULL(dp.SettlementNumber,'')) = '' AND (ISNULL(dp.OtherSettlementDetails, 0) = 0))  
		  
	DROP TABLE #clientsToExclude
	

	SELECT DISTINCT RefClientId 
	INTO #distinctClient
	FROM #tradeData

	SELECT t.RefClientId, t.RefCustomerSegmentId
	INTO #clientCSMapping
	FROM
	(
		SELECT
			cl.RefClientId,
			linkClCs.RefCustomerSegmentId,
			ROW_NUMBER() OVER(PARTITION BY cl.RefClientId ORDER BY linkClCs.StartDate DESC) AS RN
		FROM #distinctClient cl
		INNER JOIN dbo.LinkRefClientRefCustomerSegment linkClCs ON cl.RefClientId = linkClCs.RefClientId
	) t
	WHERE t.RN = 1

	DROP TABLE #distinctClient

	SELECT DISTINCT 
		RefClientId,
		OtherClientId ,
		CONVERT(INT,OtherDpid) OtherDpid
	INTO #distinctClientopp
	FROM #tradeData pre

	SELECT
		tr.RefClientId,
		tr.OtherClientId,
		tr.OtherDpid
	INTO #preClientData
	FROM #distinctClientopp tr
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = tr.RefClientId
	LEFT JOIN dbo.RefClient oppcl ON ISNULL(oppcl.DpId, 0) = ISNULL(tr.OtherDpid, 0) AND oppcl.ClientId = tr.OtherClientId  
	WHERE oppcl.RefClientId IS NULL OR oppcl.PAN <> cl.PAN 

	SELECT
	tr.*
	INTO #prefinalTrade
	FROM #tradeData tr
	INNER JOIN #preClientData oppcl ON oppcl.RefClientId = tr.RefClientId AND ISNULL(oppcl.OtherDpid, 0) = ISNULL(tr.OtherDpid, 0) AND oppcl.OtherClientId = tr.OtherClientId 
	
	DROP TABLE #tradeData
	
	SELECT
		linkCS.RefCustomerSegmentId,
		rules.Threshold
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule rules
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefCustomerSegment linkCS ON rules.RefAmlScenarioRuleId = linkCS.RefAmlScenarioRuleId
	WHERE rules.RefAmlReportId = @ReportIdInternal

	SELECT
	pre.RefClientId,
	pre.RefSegmentId,
	pre.RefIsinId,
	pre.ReasonCodeId,
	STUFF((SELECT DISTINCT ',' +CONVERT(VARCHAR, t2.BusinessDate, 106) COLLATE DATABASE_DEFAULT
					FROM #prefinalTrade t2  WHERE t2.RefClientId = pre.RefClientId AND      
				t2.RefSegmentId = pre.RefSegmentId  AND pre.RefIsinId = t2.RefIsinId  AND pre.ReasonCodeId = t2.ReasonCodeId   FOR XML PATH('')),1,1,'') AS Dates
	INTO #ReasonCodeData
	FROM #prefinalTrade pre
	GROUP BY pre.RefClientId,pre.RefSegmentId,pre.RefIsinId,pre.ReasonCodeId

	SELECT tr.*
	INTO #finalTradeData
	FROM (SELECT 
				trade.RefSegmentId,
				trade.RefIsinId,
				trade.RefClientId,
				SUM(trade.Quantity)AS UnlistedShareQuantity,
				STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(100), t2.TransactionId) COLLATE DATABASE_DEFAULT       
					FROM #prefinalTrade t2    
				WHERE trade.RefClientId = t2.RefClientId AND trade.RefSegmentId = t2.RefSegmentId  AND trade.RefIsinId = t2.RefIsinId
				FOR XML PATH ('')), 1, 1, '') AS TxnIds,
				STUFF((SELECT DISTINCT ',' +  ty.[Name] COLLATE DATABASE_DEFAULT       
					FROM #prefinalTrade t2  
					INNER JOIN dbo.RefDpTransactionType ty ON t2.RefDpTransactionTypeId = ty.RefDpTransactionTypeId
				WHERE trade.RefClientId = t2.RefClientId AND trade.RefSegmentId = t2.RefSegmentId  AND trade.RefIsinId = t2.RefIsinId
				FOR XML PATH ('')), 1, 1, '') AS TxnDesc,
				STUFF((SELECT DISTINCT ';' +  trc.ReasonCode +' : '+ t2.Dates COLLATE DATABASE_DEFAULT
					FROM #ReasonCodeData t2  
					INNER JOIN  #tempReasonCode trc ON t2.RefClientId = trade.RefClientId AND      
				t2.RefSegmentId = trade.RefSegmentId  AND trade.RefIsinId = t2.RefIsinId  AND trc.ReasonCodeId =t2.ReasonCodeId AND trc.SegmentId = t2.RefSegmentId
				FOR XML PATH('') ),1,1,'') AS ReasonCode
			FROM #prefinalTrade trade
			GROUP BY trade.RefClientId, trade.RefIsinId, trade.RefSegmentId) tr
	LEFT JOIN #clientCSMapping ccsm ON ccsm.RefClientId = tr.RefClientId
	INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId, 0) = ISNULL(ccsm.RefCustomerSegmentId, 0)
	WHERE rules.Threshold <= tr.UnlistedShareQuantity

	DROP TABLE #prefinalTrade

	SELECT DISTINCT tr.RefIsinId
	INTO #distinctIsin
	FROM #finalTradeData tr


	SELECT t.RefIsinId, t.Isin, t.[Name], t.RefInstrumentId
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
			inst.RefInstrumentId,
			ROW_NUMBER() OVER (PARTITION BY isin.[Name] ORDER BY inst.RefSegmentId DESC) AS RN
		FROM #distinctIsin alert
		INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = alert.RefIsinId
		LEFT JOIN dbo.RefInstrument inst ON inst.Isin = isin.[Name] AND inst.RefSegmentId IN (@BSEId,@NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'
	)t
	WHERE t.RN = 1
	
	SELECT
		inst.RefInstrumentId,
		alert.RefSegmentId,
		cli.RefClientId,
		cli.ClientId,
		cli.[Name] AS ClientName,
		inst.Isin AS Isin,
		inst.[Name] AS IsinName,
		@RunDateInternal AS TransactionDate,
		seg.Segment AS Depository,
		'Dr' AS Dr,
		CASE 
			WHEN cli.DpId IS NULL THEN ''
			ELSE 'IN' +  CONVERT(VARCHAR(MAX),cli.DpId) COLLATE DATABASE_DEFAULT
		END AS DpId,
		alert.UnlistedShareQuantity AS Quantity,
		custSeg.[Name] AS [AccountSegment],
		alert.TxnDesc AS TransactionDescription,
		alert.TxnIds,
		alert.ReasonCode AS ReasonCode,
		@StartDate AS TransactionFromDate,
		@EndDate AS TransactionToDate,
		alert.RefIsinId AS RefIsinId
	FROM #finalTradeData alert
	INNER JOIN dbo.RefClient cli ON cli.RefClientId = alert.RefClientId
	INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = alert.RefSegmentId
	INNER JOIN #instrumentData inst ON inst.RefIsinId = alert.RefIsinId 
	LEFT JOIN #clientCSMapping ccsm ON ccsm.RefClientId = alert.RefClientId
	INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId, 0) = ISNULL(ccsm.RefCustomerSegmentId, 0)
	LEFT JOIN dbo.RefCustomerSegment custSeg ON custSeg.RefCustomerSegmentId = rules.RefCustomerSegmentId
	LEFT JOIN dbo.CoreAmlScenarioAlert dupcheck ON dupcheck.RefClientId = alert.RefClientId AND dupcheck.RefSegmentEnumId = alert.RefSegmentId AND inst.RefIsinId = dupcheck.RefIsinId AND inst.RefInstrumentId = dupcheck.RefInstrumentId AND dupcheck.RefAmlReportId = @ReportIdInternal
							AND dupcheck.Quantity = alert.UnlistedShareQuantity AND dupcheck.TransactionToDate = @StartDate AND dupcheck.TransactionFromDate = @EndDate 
	WHERE dupcheck.CoreAmlScenarioAlertId IS NULL OR @IsAlertDulicationAllowedInternal  = 1  
END
GO
--END RC WEB-80325

--File:Tables:dbo:RefAmlScenarioRule:DML
--START RC WEB-80325
GO
DECLARE @S853Id INT

SET @S853Id = (SELECT RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S853 Off Market Delivery In Unlisted Scrip')

INSERT INTO dbo.RefAmlScenarioRule
(
	RuleNumber,
	RefAmlReportId,
	Threshold,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn
)
SELECT
	ISNULL((SELECT MAX(RuleNumber) FROM dbo.RefAmlScenarioRule)+1,1),
	@S853Id,
	500000,
	'System',
	GETDATE(),
	'System',
	GETDATE()
GO
--END RC WEB-80325

--File:Tables:dbo:LinkRefAmlScenarioRuleRefCustomerSegment:DML
--START RC WEB-80325
GO
DECLARE @S853Id INT, @RuleId INT

SELECT @S853Id = RefAmlReportId FROM dbo.RefAmlReport
WHERE [Name] = 'S853 Off Market Delivery In Unlisted Scrip'

SELECT @RuleId = RefAmlScenarioRuleId FROM dbo.RefAmlScenarioRule WHERE RefAmlReportId = @S853Id

INSERT INTO dbo.LinkRefAmlScenarioRuleRefCustomerSegment
(
	RefAmlScenarioRuleId,
	RefCustomerSegmentId,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn
)
SELECT
	ISNULL(@RuleId,1),
	NULL,
	'System',
	GETDATE(),
	'System',
	GETDATE()
GO
--END RC WEB-80325

