--File:Tables:dbo:RefAmlReport:DML
--RC-WEB-82996 START
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
		[Description]
	) VALUES (
		1298,
		'S862 PCM Transactions Not Commensurate With The Margin Money Of The Clients',
		'System',
		GETDATE(),
		'System',
		GETDATE(),
		1,
		'S862',
		@RefAlertRegisterCaseTypeId,
		1, 
		'S862PCMTransactionsNotCommensurateWithTheMarginMoneyOfTheClients',
		1,
		@FrequencyFlagRefEnumValueId,
		862,
		'Margin money of the PCMs is not in line with the limit assigned to the PCM <br>
		Segments: CDSL, NSDL ; Frequency: Daily ; Period : 1 Day<br>
		Thresholds: <br>
		<b>1.PCM Limit:</b> PCM limit in assigned to each client in the client master which will be considered as client level threshold.  System will generate alert If this ''X'' Total Margin Value is greater than or equal to the PCM Limit assigned to particular Client. <br>

		Note:<br>
		Alert will get generated based on Client Wise<br>'
	)
GO
--RC-WEB-82996 END
--File:Tables:dbo:RefProcess:DML
--RC-WEB-82996 START
GO
	DECLARE	 @EnumValueId INT, @RefAmlReportId INT
	SELECT @EnumValueId = dbo.GetEnumValueId('ProcessType','Simple')
	SELECT @RefAmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S862 PCM Transactions Not Commensurate With The Margin Money Of The Clients'

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
		'S862 PCM Transactions Not Commensurate With The Margin Money Of The Clients',
		'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S862PCMTransactionsNotCommensurateWithTheMarginMoneyOfTheClients',
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
		'S862',
		1,
		'S862 PCM Transactions Not Commensurate With The Margin Money Of The Clients',
		1000
	)
GO
--RC-WEB-82996 END
--File:StoredProcedures:dbo:AML_GetPCMTransactionsNotCommensurateWithTheMarginMoneyOfTheClients
--RC-WEB-82996 START
GO
CREATE PROCEDURE dbo.AML_GetPCMTransactionsNotCommensurateWithTheMarginMoneyOfTheClients(        
	 @RunDate DATETIME,
	 @ReportId INT
)        
	AS        
	BEGIN     

		DECLARE @PcmLimitRefClientKeyId INT,@NseFnoId INT,@RunDateInternal DATETIME,@ReportIdInternal INT, @CdslId INT,@NsdlId INT,@CdslDBId INT,@NsdlDBId INT

		SET @RunDateInternal = @RunDate
		SET @ReportIdInternal = @ReportId
		SET @NseFnoId = dbo.GetSegmentId('NSE_FNO')
		SET @CdslId = dbo.GetSegmentId('CDSL')
		SET @NsdlId = dbo.GetSegmentId('NSDL')
		SET @CdslDBId = (SELECT db.RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum db WHERE db.DatabaseType = 'CDSL')
		SET @NsdlDBId = (SELECT db.RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum db WHERE db.DatabaseType = 'NSDL')

		SELECT @PcmLimitRefClientKeyId = ke.RefClientKeyId FROM dbo.RefClientKey ke WHERE ke.Code = 'PCMLimit'

		SELECT    
			RefClientId    
		INTO #clientsToExclude    
		FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
		WHERE (ExcludeAllScenarios = 1 OR RefAmlReportId = @ReportIdInternal)
			  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)

		SELECT
			info.RefClientId,
			info.DoubleValue AS PCMLimit
		INTO #tempRules
		FROM dbo.CoreClientKeyValueInfo info
		LEFT JOIN #clientsToExclude clex ON clex.RefClientId = info.RefClientId
		WHERE  clex.RefClientId IS NULL AND info.RefClientKeyId = @PcmLimitRefClientKeyId AND ISNULL(info.DoubleValue , 0) <> 0

		SELECT
			mar.RefClientId,
			temp.PCMLimit,
			mar.TotalMargin
		INTO #finalData
		FROM dbo.CoreFnoMargin mar
		INNER JOIN #tempRules  temp ON mar.RefClientId = temp.RefClientId AND mar.RefSegmentId = @NseFnoId AND mar.TradeDate = @RunDateInternal
		WHERE mar.TotalMargin >= temp.PCMLimit

		SELECT DISTINCT
			cl.RefClientId
		INTO #tempDistinctClient
		FROM #tempRules cl

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
			cl.RefClientId,
			CASE WHEN  cl.RefClientDatabaseEnumId = @CdslDBId THEN @CdslId WHEN cl.RefClientDatabaseEnumId = @NsdlDBId THEN @NsdlId ELSE NULL END  AS RefSegmentId,
			cl.ClientId,
			cl.[Name] ClientName,
			CASE  WHEN cl.RefClientDatabaseEnumId = @CdslDBId THEN 'CDSL' WHEN cl.RefClientDatabaseEnumId = @NsdlDBId THEN  'NSDL' ELSE NULL END  AS Depository,
			CASE 
				WHEN cl.DpId IS NULL THEN ''
				ELSE 'IN' +  CONVERT(VARCHAR(MAX),cl.DpId) COLLATE DATABASE_DEFAULT
			END AS DpId,
			@RunDateInternal AS TransactionDate,
			fd.TotalMargin,
			fd.PCMLimit,
			accseg.[Name] AS AccountSegment
		FROM #finalData fd
		INNER JOIN dbo.RefClient cl ON cl.RefClientId = fd.RefClientId
		LEFT JOIN #clientCSMapping csmap ON csmap.RefClientId = cl.RefClientId
		LEFT JOIN dbo.RefCustomerSegment accseg ON csmap.RefCustomerSegmentId = accseg.RefCustomerSegmentId

	END 
GO
--RC-WEB-82996 END



GO
	DECLARE @PcmLimitRefClientKeyId INT
	
	SELECT @PcmLimitRefClientKeyId = ke.RefClientKeyId FROM dbo.RefClientKey ke WHERE ke.Code = 'PCMLimit'
	UPDATE core
	SET core.DoubleValue = CONVERT(DECIMAL(26,8),core.StringValue)
	FROM dbo.CoreClientKeyValueInfo core
	WHERE core.RefClientKeyId = @PcmLimitRefClientKeyId AND core.DoubleValue IS NULL AND ISNUMERIC(core.StringValue) = 1

GO