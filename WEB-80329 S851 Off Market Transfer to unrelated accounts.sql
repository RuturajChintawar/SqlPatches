--File:Tables:dbo:RefAmlReport:DML
--START RC WEB-80329
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
	1284,
	'S851 Off Market Transfer To Unrelated Accounts',
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	1,
	'S851',
	@RefAlertRegisterCaseTypeId,
	1, 
	'S851OffMarketTransferToUnrelatedAccounts',
	1,
	@FrequencyFlagRefEnumValueId,
	851,
	'Single off market txn value =>',
	'Income Multiplier',
	'This scenario will help to identify the Clients doing off market transactions with reason as Gift, Donation, Off market sale to unrelated accounts.<br>
	Segments: CDSL, NSDL ; Frequency: Daily ; Period: 1 Day<br>
	<b>Thresholds:</b> <br>
	<b>1. Single off market transaction value:</b> This is the amount of single off market transaction value for the specific reason code done by the client on a particular day, in a particular ISIN. System will generate alert If this ''X'' Transaction value is greater than or equal to the set threshold.<br>
	<b>2. Income Multplier :</b> No of times of income, upto which single off market transaction value will be considered inline.  If the single off market transaction value breaches more than ''X'' no of times of income, an alert will be generated.<br>
	<b>3. Account Segment :</b>Account segment mapped to the DP account <br>
	<b>Note: </b><br>
	1. Only Debit Transactions will be considered for alert generation.<br>
	2. Reason Codes considered for this scenarios are Gift, Donation, Off Market sale.<br>
	3. Transfers made between accounts with same PAN, same Mobile number, same Email ID, same bank details and a family declaration will be excluded.<br> 
	4. Segment wise/scrip wise alert will be created<br> ')
GO
--END RC WEB-80329
--File:Tables:dbo:RefProcess:DML
--START RC WEB-80329
GO
DECLARE	 @EnumValueId INT, @RefAmlReportId INT
SELECT @EnumValueId = dbo.GetEnumValueId('ProcessType','Simple')
SELECT @RefAmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S851 Off Market Transfer To Unrelated Accounts'

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
	'S851 Off Market Transfer To Unrelated Accounts',
	'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S851OffMarketTransferToUnrelatedAccounts',
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
	'S851',
	1,
	'S851 Off Market Transfer To Unrelated Accounts',
	1000
)
GO
--END RC WEB-80329
--File:StoredProcedures:dbo:Aml_S851OffMarketTransfertToUnrelatedAccounts
--START RC WEB-80329
GO
CREATE PROCEDURE dbo.Aml_S851OffMarketTransfertToUnrelatedAccounts
(
	@Rundate DATETIME,
	@ReportId INT
)
AS
BEGIN
	DECLARE @RunDateInternal DATETIME,  @ReportIdInternal INT, @DayPrior7 DATETIME, @NsdlId INT, @CdslId INT, @BSEId INT, @NSEId INT,
			@CdslType2 INT, @CdslType3 INT, @CdslType5 INT, @CdslStatus305 INT, @CdslStatus511 INT, @NsdlType904 INT, @NsdlType925 INT,
			@DefaultIncome BIGINT, @RefIncomeGroupId INT, @DefaultAboveOneCr DECIMAL(28,2)

	SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)
	SET @DayPrior7 = DATEADD(DAY, -7, @RunDateInternal)
	SET @ReportIdInternal = @ReportId

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
		OtherDpid VARCHAR(16) COLLATE DATABASE_DEFAULT,   
		OtherClientId VARCHAR(MAX) COLLATE DATABASE_DEFAULT, 
		ReasonCode VARCHAR(20) COLLATE DATABASE_DEFAULT, 
	)
	CREATE TABLE #tempReasonCode
	(
		ReasonCodeId INT,
		SegmentId INT,
		ReasonCode VARCHAR(20) COLLATE DATABASE_DEFAULT, 
	)

	INSERT INTO  #tempReasonCode VALUES 
	( 1, @CdslId, '1 - Gift'), ( 2, @CdslId, '2 - Off Market Sale'),
	( 16, @CdslId, '16 - Donation'),( 1, @NsdlId, '1 -Off Market Sale'),
	( 92, @NsdlId, '92 - Gift'),( 93, @NsdlId, '93 - Donation')

	INSERT INTO #tradeData (TransactionId, RefClientId, RefSegmentId, RefIsinId, Quantity, OtherDpid, OtherClientId, ReasonCode)
	SELECT
		dp.CoreDpTransactionId,
		dp.RefClientId,
		dp.RefSegmentId,
		dp.RefIsinId,
		CONVERT(BIGINT, dp.Quantity) AS Quantity,
		CASE WHEN SUBSTRING(ISNULL(dp.CounterBOId,''),1,2) = 'IN'  THEN SUBSTRING(ISNULL(dp.CounterBOId,''), 3, 6) ELSE NULL  END,
		CASE WHEN SUBSTRING(ISNULL(dp.CounterBOId,''),1,2) = 'IN'  THEN SUBSTRING(ISNULL(dp.CounterBOId,''), 9, 8) ELSE ISNULL(dp.CounterBOId,'') END,
		trc.ReasonCode
	FROM dbo.CoreDpTransaction dp
	LEFT JOIN #tempReasonCode trc ON dp.ReasonForTrade = trc.ReasonCodeId AND trc.SegmentId = dp.RefSegmentId
	LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId
	WHERE clEx.RefClientId IS NULL
		  AND dp.RefSegmentId = @CdslId
		  AND ((dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3) AND dp.RefDpTransactionStatusId = @CdslStatus305)
		  	  OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))
		  AND (trc.ReasonCodeId IS NOT NULL OR dp.RefDpTransactionTypeId = @CdslType5 )	 
		  AND dp.BusinessDate = @RunDateInternal
		  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')      
		  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')     
		  AND (dp.BuySellFlag = 'D' OR dp.BuySellFlag = 'S') 

	INSERT INTO #tradeData (TransactionId, RefClientId, RefSegmentId, RefIsinId, Quantity ,OtherDpid ,OtherClientId ,  ReasonCode) 
	SELECT
		dp.CoreDPTransactionChangeHistoryId,
		dp.RefClientId,
		dp.RefSegmentId,
		dp.RefIsinId,
		CONVERT(BIGINT, dp.Quantity) AS Quantity,
		CASE WHEN dp.RefDpTransactionTypeId = @NsdlType904 AND SUBSTRING(ISNULL(dp.OtherDPId,''),1,2) = 'IN' THEN SUBSTRING(ISNULL(dp.OtherDPId,''), 3, 6) 
			 WHEN dp.RefDpTransactionTypeId = @NsdlType925 AND SUBSTRING(ISNULL(dp.OtherDPCode,''),1,2) = 'IN' THEN SUBSTRING(ISNULL(dp.OtherDPCode,''), 3, 6)	
			 ELSE NULL END,  
		CASE WHEN dp.RefDpTransactionTypeId = @NsdlType904 THEN CASE WHEN SUBSTRING(ISNULL(dp.OtherDPId,''),1,2) = 'IN' THEN CONVERT(VARCHAR(MAX), dp.OtherClientId) ELSE CONVERT(VARCHAR(20),ISNULL(dp.OtherDPId,'') ) + CONVERT(VARCHAR(MAX), dp.OtherClientId)END
		WHEN dp.RefDpTransactionTypeId = @NsdlType925 THEN CASE WHEN SUBSTRING(ISNULL(dp.OtherDPCode,''),1,2) = 'IN' THEN ISNULL(dp.OtherClientCode,'') ELSE ISNULL(dp.OtherDPCode,'')+ISNULL(dp.OtherClientCode,'') END   ELSE ISNULL(dp.OtherClientCode,'') END,
		trc.ReasonCode
	FROM dbo.CoreDPTransactionChangeHistory dp
	INNER JOIN #tempReasonCode trc ON CONVERT(INT,dp.TransferReasonCode) = trc.ReasonCodeId AND trc.SegmentId = dp.RefSegmentId 
	LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId
	WHERE  clEx.RefClientId IS NULL
		  AND dp.RefSegmentId = @NsdlId
		  AND dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType925 )
		  AND dp.ExecutionDate = @RunDateInternal
		  AND dp.OrderStatusTo = 51
		  AND (LTRIM(ISNULL(dp.SettlementNumber,'')) = '' AND (ISNULL(dp.OtherSettlementDetails, 0) = 0)) 
		  AND dp.TransferReasonCode IN( '1','92','93')
	
	DROP TABLE #clientsToExclude
	DROP TABLE #tempReasonCode

	SELECT DISTINCT t.RefIsinId 
	INTO #selectedIsin 
	FROM #tradeData t 

	SELECT t.RefIsinId, t.[Close]
	INTO #DpBhavCopyRate
	FROM
	(
		SELECT DISTINCT 
			bhav.RefIsinId,
			bhav.[Close],
			ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId ORDER BY bhav.[Date] DESC) AS RN
		FROM #selectedIsin isin
		INNER JOIN dbo.CoreDpBhavCopy bhav on isin.RefIsinId = bhav.RefIsinId
		WHERE bhav.[Date] >= @DayPrior7 AND bhav.[Date] <= @RunDateInternal
	) t
	WHERE t.RN = 1

	
	SELECT DISTINCT isin.RefIsinId
	INTO #isinids
	FROM #selectedIsin isin
	LEFT JOIN #DpBhavCopyRate ids ON isin.RefIsinId = ids.RefIsinId
	WHERE ids.RefIsinId IS NULL
	
	SELECT t.RefIsinId, t.[Close]
	INTO #NonDpBhavCopyRate
	FROM
	(
		SELECT DISTINCT
			ids.RefIsinId,
			bhav.[Close],
			ROW_NUMBER() OVER (PARTITION BY ids.RefIsinId ORDER BY bhav.[Date] DESC) AS RN
		FROM #isinids ids
		INNER JOIN dbo.RefIsin isin ON ids.RefIsinId = isin.RefIsinId
		INNER JOIN dbo.RefInstrument inst ON isin.[Name] = inst.Isin AND inst.RefSegmentId IN (@BSEId, @NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'
		INNER JOIN dbo.CoreBhavCopy bhav ON bhav.RefInstrumentId = inst.RefInstrumentId AND bhav.RefSegmentId = inst.RefSegmentId
		WHERE bhav.[Date] >= @DayPrior7 AND bhav.[Date] <= @RunDateInternal
	) t
	WHERE t.RN = 1

	DROP TABLE #selectedIsin

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

	SELECT	 @DefaultIncome = CONVERT(BIGINT ,reportSetting.[Value])
	FROM	dbo.RefAmlQueryProfile qp 		
	LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.[Name] = 'Client Purchase to Income'
	LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId
				AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId AND reportSetting.[Name] = 'Default_Income'
	WHERE	qp.[Name] = 'Default'
	
	SET @RefIncomeGroupId = (SELECT grp.RefIncomeGroupId FROM dbo.RefIncomeGroup grp WHERE grp.Code = 6)
	SET @DefaultAboveOneCr = (SELECT CONVERT(DECIMAL(28,2),syst.[Value]) FROM dbo.SysConfig syst WHERE syst.[Name] ='Income_Value_For_Above_One_Crore')

	SELECT 
		cl.RefClientId,
		CASE WHEN la.RefIncomeGroupId = @RefIncomeGroupId AND ISNULL(@DefaultAboveOneCr ,0) = 0 THEN  10000000 
		 WHEN la.RefIncomeGroupId = @RefIncomeGroupId THEN  @DefaultAboveOneCr ELSE
		COALESCE(la.Income,grp.IncomeTo , @DefaultIncome)
		END AS Income
	INTO #clientIncomeData
	FROM #distinctClient cl
	LEFT JOIN  dbo.LinkRefClientRefIncomeGroupLatest la ON la.RefClientId = cl.RefClientId
	LEFT JOIN dbo.RefIncomeGroup grp ON ISNULL(grp.RefIncomeGroupId,0) = ISNULL(la.RefIncomeGroupId,0)

	DROP TABLE #distinctClient
	
	
	SELECT
		rules.RefAmlScenarioRuleId,
		linkCS.RefCustomerSegmentId,
		rules.Threshold,
		rules.Threshold2
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule rules
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefCustomerSegment linkCS ON rules.RefAmlScenarioRuleId = linkCS.RefAmlScenarioRuleId
	WHERE rules.RefAmlReportId = @ReportIdInternal


	SELECT tr.*
	INTO #temptradeData
	FROM (SELECT 
				trade.TransactionId,
				trade.RefSegmentId,
				trade.RefIsinId,
				trade.RefClientId,
				trade.Quantity * ISNULL(dpBhav.[Close], nonDpBhav.[Close]) AS SingleOffMarketTrans,
				trade.OtherDpid,
				trade.OtherClientId,
				trade.ReasonCode
			FROM #tradeData trade
			LEFT JOIN #DpBhavCopyRate dpBhav ON dpBhav.RefIsinId= trade.RefIsinId
			LEFT JOIN #NonDpBhavCopyRate nonDpBhav on nonDpBhav.RefIsinId = trade.RefIsinId
			WHERE dpBhav.RefIsinId IS NOT NULL OR nonDpBhav.RefIsinId IS NOT NULL) tr
	INNER JOIN #clientIncomeData inc ON inc.RefClientId = tr.RefClientId
	LEFT JOIN #clientCSMapping ccsm ON ccsm.RefClientId = tr.RefClientId
	INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId, 0) = ISNULL(ccsm.RefCustomerSegmentId, 0)
	WHERE rules.Threshold <= tr.SingleOffMarketTrans AND rules.Threshold2 * inc.Income <= tr.SingleOffMarketTrans

	DROP TABLE #DpBhavCopyRate
	DROP TABLE #NonDpBhavCopyRate
	DROP TABLE #tradeData

	SELECT DISTINCT 
		pre.RefClientId,
		OtherClientId ,
		CONVERT(INT,OtherDpid) OtherDpid
	INTO #distinctClientopp
	FROM #temptradeData pre
	
	SELECT
		tr.RefClientId,
		oppcl.RefClientId AS oppRefClientId,
		CASE WHEN ISNULL(cl.IsFamilyDeclaration , 0)= 1 AND ISNULL(oppcl.IsFamilyDeclaration , 0) = 1 THEN 1
		ELSE 0
		END familydec,
		tr.OtherClientId,
		tr.OtherDpid,
		oppcl.[Name] AS OppClientName
	INTO #preClientData
	FROM #distinctClientopp tr
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = tr.RefClientId
	LEFT JOIN dbo.RefClient oppcl ON ISNULL(oppcl.DpId,0) = ISNULL(tr.OtherDpid,0) AND oppcl.ClientId = tr.OtherClientId
	WHERE oppcl.RefClientId IS NULL 
	OR( oppcl.PAN <> cl.PAN AND
			(
				(ISNULL(cl.IsFamilyDeclaration , 0)<> 1  AND ISNULL(oppcl.IsFamilyDeclaration , 0)<> 1) 
				OR (cl.Email <> oppcl.Email AND cl.Mobile <> oppcl.Mobile)
			)
		)

	SELECT DISTINCT cl.* 
	INTO #nonQualifyClientForbank
	FROM #preClientData cl
	LEFT JOIN dbo.LinkRefClientRefBankMicr link ON link.RefClientId = cl.RefClientId
	LEFT JOIN dbo.LinkRefClientRefBankMicr oplink ON oplink.RefClientId = cl.oppRefClientId
	WHERE familydec = 1 AND (ISNULL(link.IfscCode,'') = ISNULL(oplink.IfscCode,'') AND  ISNULL(link.BankAccNo,'') = ISNULL(oplink.BankAccNo,'') )

	SELECT cl.*
	INTO #finalClient
	FROM #preClientData cl
	LEFT JOIN #nonQualifyClientForbank ncl ON ncl.RefClientId = cl.RefClientId AND ncl.oppRefClientId = cl.oppRefClientId
	WHERE ncl.RefClientId IS NULL

	SELECT
		tr.TransactionId,
		tr.RefSegmentId,
		tr.RefIsinId,
		tr.RefClientId,
		tr.SingleOffMarketTrans,
		cl.oppRefClientId AS oppRefClientId,
		tr.ReasonCode,
		cl.OppClientName,
		cl.OtherClientId
	INTO #finalTradeData
	FROM #finalClient cl 
	INNER JOIN #temptradeData tr ON tr.RefClientId = cl.RefClientId AND ISNULL( cl.OtherDpid,0) = ISNULL(tr.OtherDpid,0) AND cl.OtherClientId = tr.OtherClientId 

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
		FROM ( SELECT DISTINCT RefIsinId FROM #finalTradeData ) alert
		INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = alert.RefIsinId
		LEFT JOIN dbo.RefInstrument inst ON inst.Isin = isin.[Name] AND inst.RefSegmentId in (@BSEId,@NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'
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
		'Dr' AS DebitCredit,
		CASE 
			WHEN cli.DpId IS NULL THEN ''
			ELSE 'IN' +  CONVERT(VARCHAR(MAX),cli.DpId) COLLATE DATABASE_DEFAULT
		END AS DpId,
		alert.SingleOffMarketTrans AS SingleTxnValue,
		custSeg.[Name] AS [AccountSegment],
		incData.Income AS Income,
		CONVERT(INT, rules.Threshold2) AS IncomeMultiplier,
		incData.Income * CONVERT(INT, rules.Threshold2) AS IncomeStrength,
		alert.OtherClientId AS OpCLientId,
		alert.OppClientName AS OppClientName,
		alert.TransactionId,
		alert.ReasonCode,
		alert.TransactionId
	FROM #finalTradeData alert
	INNER JOIN dbo.RefClient cli ON cli.RefClientId = alert.RefClientId
	INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = alert.RefSegmentId
	INNER JOIN #instrumentData inst ON inst.RefIsinId = alert.RefIsinId 
	INNER JOIN #clientIncomeData incData ON incData.RefClientId = cli.RefClientId
	LEFT JOIN #clientCSMapping ccsm ON ccsm.RefClientId = alert.RefClientId
	INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId, 0) = ISNULL(ccsm.RefCustomerSegmentId, 0)
	LEFT JOIN dbo.RefCustomerSegment custSeg ON custSeg.RefCustomerSegmentId = rules.RefCustomerSegmentId

END
GO
--END RC WEB-80329
--File:Tables:dbo:RefAmlScenarioRule:DML
--START RC WEB-80329
GO
DECLARE @S851Id INT

SET @S851Id = (SELECT RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S851 Off Market Transfer To Unrelated Accounts')

INSERT INTO dbo.RefAmlScenarioRule
(
	RuleNumber,
	RefAmlReportId,
	Threshold,
	Threshold2,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn
)
SELECT
	ISNULL((SELECT MAX(RuleNumber) FROM dbo.RefAmlScenarioRule)+1,1),
	@S851Id,
	2500000,
	5,
	'System',
	GETDATE(),
	'System',
	GETDATE()
GO
--END RC WEB-80329
--File:Tables:dbo:LinkRefAmlScenarioRuleRefCustomerSegment:DML
--START RC WEB-80329
GO
DECLARE @S851Id INT, @RuleId INT

SELECT @S851Id = RefAmlReportId FROM dbo.RefAmlReport
WHERE [Name] = 'S851 Off Market Transfer To Unrelated Accounts'

SELECT @RuleId = RefAmlScenarioRuleId FROM dbo.RefAmlScenarioRule WHERE RefAmlReportId = @S851Id

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
--END RC WEB-80329