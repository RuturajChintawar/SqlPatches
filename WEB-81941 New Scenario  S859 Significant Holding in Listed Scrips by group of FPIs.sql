--File:Tables:dbo:RefAmlReport:DML
--RC-WEB-77 START
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
		Threshold6DisplayName,
		[Description]

	) VALUES (
		1295,
		'S859 Significant Holding in Listed Scrips by group of FPIs',
		'System',
		GETDATE(),
		'System',
		GETDATE(),
		1,
		'S859',
		@RefAlertRegisterCaseTypeId,
		1, 
		'S859SignificantHoldingInListedScripsByGroupOfFPIs',
		1,
		@FrequencyFlagRefEnumValueId,
		859,
		'Holding % =>',
		'This scenario will help to identify significant holding in the listed scrips by group of FPIs<br>
		Segments: CDSL, NSDL ; Frequency: Daily ; Period: 1 Day<br>
		Thresholds: <br>
		<b>1.Indiviudual Holding % :</b> It is the Client holding percentage of the listed scrip with respect to the issued capital of that scrip <br>
		<b>2.Group Holding % :</b> It is the Group holding percentage of the listed scrip with respect to the issued capital of that scrip where the particular FPI group code is assigned to clients <br>
		<b>3. Account Segment :</b> Account segment mapped to the DP account <br>
		<b>Note: </b><br>
		1. Alert will be generated for the clients where constitution type mapped is FPI Individual and non individual<br>
		2. FPI Groups will be considered according to FPI group code mapped in the client master<br>
		3. Segment wise/scrip wise alert will be created <br>
		4. only listed Scrips will be considered for the alert generation<br>
		'
	)
GO
--RC-WEB-81941 END
--File:Tables:dbo:RefProcess:DML
--RC-WEB-81941 START
GO
	DECLARE	 @EnumValueId INT, @RefAmlReportId INT
	SELECT @EnumValueId = dbo.GetEnumValueId('ProcessType','Simple')
	SELECT @RefAmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S859 Significant Holding in Listed Scrips by group of FPIs'

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
		'S859 Significant Holding in Listed Scrips by group of FPIs',
		'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S859SignificantHoldingInListedScripsByGroupOfFPIs',
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
		'S859',
		1,
		'S859 Significant Holding in Listed Scrips by group of FPIs',
		1000
	)
GO
--RC-WEB-81941 END
--File:Tables:dbo:SysAmlReportSetting:DML
--RC-WEB-81941 START
GO
	DECLARE @AmlReportId INT

	SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S859 Significant Holding in Listed Scrips by group of FPIs'

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
		'Holding_Percentage_Value',
		'',
		1,
		'Group Holding % => ',
		1,
		GETDATE(),
		'System',
		GETDATE(),
		'System'
	)
GO
--RC-WEB-81941 END
--File:StoredProcedures:dbo:AML_GetSignificantHoldingInListedScripsByGroupOfFPIs
--RC-WEB-81941 START
GO
CREATE PROCEDURE dbo.AML_GetSignificantHoldingInListedScripsByGroupOfFPIs (        
	 @RunDate DATETIME,
	 @ReportId INT
)        
AS        
BEGIN     
	  
	DECLARE @ReportIdInternal INT, @RunDateInternal DATETIME, @NsdlId INT, @CdslId INT, @BSEId INT, @NSEId INT ,@DayPrior7 DATETIME, 
          @FpiRefClientKeyId INT, @GrpHoldingThreshold VARCHAR(MAX)

    SET @ReportIdInternal = @ReportId 
	SET @RunDateInternal = @RunDate 
	SET @DayPrior7 = DATEADD(DAY, -7, @RunDateInternal)

	SET @CdslId = dbo.GetSegmentId('CDSL')
	SET @NsdlId = dbo.GetSegmentId('NSDL')
	SET @BSEId = dbo.GetSegmentId('BSE_CASH') 
	SET @NSEId = dbo.GetSegmentId('NSE_CASH') 

	SET @FpiRefClientKeyId = (SELECT ke.RefClientKeyId FROM dbo.RefClientKey ke WHERE ke.Code ='FPIGroupCode') 	
	SET @GrpHoldingThreshold = (SELECT syss.[Value] FROM dbo.SysAmlReportSetting syss WHERE syss.RefAmlReportId = @ReportIdInternal AND syss.[Name] = 'Holding_Percentage_Value')

	SELECT    
		RefClientId    
	INTO #clientsToExclude    
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
	WHERE (ExcludeAllScenarios = 1 OR RefAmlReportId = @ReportIdInternal)
		  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)

	SELECT 
		const.RefConstitutionTypeId
	INTO #tempConstType
	FROM dbo.RefConstitutionType const
	WHERE const.[Name] LIKE 'FPI%'

	SELECT 
		cl.RefClientId
	INTO #tempFPIClient
	FROM dbo.RefClient cl
	INNER JOIN #tempConstType const ON const.RefConstitutionTypeId = cl.RefConstitutionTypeId
	LEFT JOIN #clientsToExclude clex ON clex.RefClientId = cl.RefClientId
	WHERE clex.RefClientId IS NULL

	DROP TABLE #tempConstType
	DROP TABLE #clientsToExclude

	SELECT 
			ty.RefClientId,
			holding.RefIsinId,  
			holding.CurrentBalanceQuantity AS Qty
    INTO #clientDematAccountTotalHolding    
    FROM dbo.CoreClientHolding holding    
	INNER JOIN dbo.RefClientDematAccount ty ON ty.RefClientDematAccountId = holding.RefClientDematAccountId
	INNER JOIN #tempFPIClient temp ON  temp.RefClientId = ty.RefClientId
	WHERE holding.AsOfDate = @RunDateInternal 
	
	SELECT DISTINCT 
		t.RefIsinId 
	INTO #selectedIsin 
	FROM #clientDematAccountTotalHolding t 
	
	SELECT 
		isin.RefIsinId
	INTO #unlistedIsinCTE
	FROM #selectedIsin isin
	INNER JOIN dbo.RefIsin ref ON ref.RefIsinId = isin.RefIsinId
	LEFT JOIN dbo.RefInstrument inst ON ref.[Name] = inst.Isin AND inst.RefSegmentId IN (@BSEId,@NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'
	WHERE ref.RefSegmentId NOT IN (@CdslId, @NsdlId) OR (ref.RefSegmentId = @CdslId AND ref.CFICode <> 0) OR (ref.RefSegmentId = @NsdlId AND inst.RefInstrumentId IS  NULL)
	
	SELECT t.Qty,t.RefClientId,t.RefIsinId 
	INTO #clientListedHolding 
	FROM #clientDematAccountTotalHolding t 
	LEFT JOIN #unlistedIsinCTE un ON un.RefIsinId = t.RefIsinId 
	WHERE un.RefIsinId IS NULL
	
	DELETE t 
	FROM #selectedIsin t 
	INNER JOIN #unlistedIsinCTE un ON un.RefIsinId = t.RefIsinId 

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
	
	SELECT
		t.RefIsinId,t.RN,t.CapitalIssued
	INTO #capitalIssueData
	FROM(
		SELECT  bhav.CapitalIssued,
				ROW_NUMBER()OVER( PARTITION BY  bhav.RefInstrumentId ORDER BY bhav.[Date] DESC) AS RN,
				ids.RefIsinId
		FROM #selectedIsin ids
		INNER JOIN dbo.RefIsin isin ON ids.RefIsinId = isin.RefIsinId
		INNER JOIN dbo.RefInstrument inst ON isin.[Name] = inst.Isin AND inst.RefSegmentId IN (@BSEId, @NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A' 
		INNER JOIN dbo.CoreBhavCopy bhav ON bhav.RefInstrumentId = inst.RefInstrumentId AND bhav.RefSegmentId = inst.RefSegmentId
		WHERE    bhav.CapitalIssued IS NOT NULL AND bhav.CapitalIssued > 0 AND bhav.[Date] =  @RunDateInternal
		)t
	WHERE t.RN = 1

	SELECT
		ISNULL(dpBhav.[Close], nonDpBhav.[Close] )AS [Close],
		isin.RefIsinId
	INTO #tempCloseData
	FROM #selectedIsin isin
	LEFT JOIN #DpBhavCopyRate dpBhav ON dpBhav.RefIsinId= isin.RefIsinId
	LEFT JOIN #NonDpBhavCopyRate nonDpBhav on nonDpBhav.RefIsinId = isin.RefIsinId
    WHERE dpBhav.RefIsinId IS NOT NULL OR nonDpBhav.RefIsinId IS NOT NULL

	SELECT 
		cl.[Close] * cap.CapitalIssued AS TotalMCap,
		cap.RefIsinId
	INTO #capitalMarketData
	FROM #capitalIssueData cap
	INNER JOIN #tempCloseData cl ON cap.RefisinId = cl.RefIsinId
	

	;WITH tempClientHolding AS(
		SELECT
			cda.RefClientId,
			cda.RefIsinId,
			SUM(cda.Qty) SumQuantity
		FROM #clientListedHolding cda
		GROUP BY cda.RefClientId, cda.RefIsinId
	)
	SELECT
		hol.RefClientId,
		hol.RefIsinId,
		hol.SumQuantity,
		(hol.SumQuantity *  ISNULL(dpBhav.[Close], nonDpBhav.[Close]) * 100) / cap.TotalMCap AS holdPercentage,
		cap.TotalMCap,
		ISNULL(dpBhav.[Close], nonDpBhav.[Close]) Rate
	INTO #tempClientMarketCap
	FROM tempClientHolding hol 
	INNER JOIN #capitalMarketData cap ON cap.RefIsinId = hol.RefIsinId
	LEFT JOIN #DpBhavCopyRate dpBhav ON dpBhav.RefIsinId= hol.RefIsinId
	LEFT JOIN #NonDpBhavCopyRate nonDpBhav on nonDpBhav.RefIsinId = hol.RefIsinId
    WHERE dpBhav.RefIsinId IS NOT NULL OR nonDpBhav.RefIsinId IS NOT NULL

	SELECT
		cl.RefClientId,
		ke.StringValue AS FPIgrpCode,
		DENSE_RANK() OVER ( ORDER BY StringValue ) AS dr
	INTO #fpigrpData
	FROM #tempFPIClient cl
	INNER JOIN dbo.CoreClientKeyValueInfo ke  ON ke.RefClientKeyId = @FpiRefClientKeyId AND cl.RefClientId =  ke.RefClientId
	WHERE  ISNULL(ke.StringValue,'') <> ''

	SELECT
		fpi.dr,
		cap.RefIsinId,
		SUM(cap.holdPercentage) AS grpHoldingPercentage
	INTO #tempGrpHoldingValue
	FROM #tempClientMarketCap cap
	INNER JOIN #fpigrpData fpi ON fpi.RefClientId = cap.RefClientId
	GROUP BY fpi.dr,cap.RefIsinId

	SELECT CONVERT(DECIMAL(28,6),s.items) AS thershold
	INTO  #tempgrpThreshold 
	FROM dbo.Split(@grpHoldingThreshold,',') s
	ORDER BY CONVERT(DECIMAL(28,6),s.items)

	SELECT
		temp.dr,
		temp.RefIsinId,
		MAX(thr.thershold) AS breachedThreshold
	INTO #breachedGrpData
	FROM #tempGrpHoldingValue temp
	CROSS JOIN #tempgrpThreshold thr
	WHERE temp.grpHoldingPercentage >= thr.thershold
	GROUP BY temp.dr,temp.RefIsinId

	DROP TABLE #tempgrpThreshold

	SELECT    
	  linkCS.RefCustomerSegmentId,    
	  rules.Threshold6   
	INTO #scenarioRules    
	FROM dbo.RefAmlScenarioRule rules    
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefCustomerSegment linkCS ON rules.RefAmlScenarioRuleId = linkCS.RefAmlScenarioRuleId 
	WHERE rules.RefAmlReportId = @ReportIdInternal 

	SELECT
		rules.RefCustomerSegmentId,
		CONVERT(DECIMAL(28,2),LTRIM(RTRIM(S.items))) AS Threshold6
	INTO #tempscenarioRules
	FROM #scenarioRules rules
	CROSS APPLY dbo.Split(rules.Threshold6,',') s 

	SELECT t.RefClientId, t.RefCustomerSegmentId
	INTO #clientCSMapping
	FROM
	(
		SELECT
			cl.RefClientId,
			linkClCs.RefCustomerSegmentId,
			ROW_NUMBER() OVER(PARTITION BY cl.RefClientId ORDER BY linkClCs.StartDate DESC) AS RN
		FROM #tempFPIClient cl
		INNER JOIN dbo.LinkRefClientRefCustomerSegment linkClCs ON cl.RefClientId = linkClCs.RefClientId
	) t
	WHERE t.RN = 1

	SELECT
		cap.RefClientId,
		cap.RefIsinId,
		cap.holdPercentage
	INTO #tempNotGrp
	FROM #tempClientMarketCap cap
	LEFT JOIN #fpigrpData fpi ON fpi.RefClientId = cap.RefClientId
	LEFT JOIN #breachedGrpData grp ON grp.dr = fpi.dr AND grp.RefIsinId = cap.RefIsinId
	WHERE  grp.dr IS NULL

	SELECT
		ngrp.RefClientId,
		ngrp.RefIsinId,
		MAX(rules.Threshold6) breachedThreshold
	INTO #breachedNotGrp
	FROM #tempNotGrp ngrp
	LEFT JOIN #clientCSMapping ccsm ON ccsm.RefCLientId = ngrp.RefClientId
	INNER JOIN #tempscenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,0) = ISNULL(ccsm.RefCustomerSegmentId, 0)
	WHERE ngrp.holdPercentage >= rules.Threshold6
	GROUP BY  ngrp.RefClientId, ngrp.RefIsinId

	SELECT
	 t.RefClientId,t.RefIsinId,t.ngrpThreshold,t.grpThreshold,t.dr,t.FPIgrpCode
	INTO #tempbreached
	FROM(
		SELECT
			ngrp.RefClientId,
			ngrp.RefIsinId, 
			ngrp.breachedThreshold AS ngrpThreshold,
			NULL AS grpThreshold,
			fpi.dr,
			CASE WHEN br.dr IS NULL THEN NULL ELSE fpi.FPIgrpCode END FPIgrpCode
		FROM #breachedNotGrp ngrp
		LEFT JOIN #fpigrpData fpi ON fpi.RefClientId = ngrp.RefClientId
		LEFT JOIN #breachedGrpData br ON br.dr = fpi.dr AND br.RefIsinId = ngrp.RefIsinId

		UNION

		SELECT
			cap.RefClientId,
			cap.RefIsinId,
			NULL AS ngrpThreshold,
			grp.breachedThreshold AS grpThreshold,
			fpi.dr,
			fpi.FPIgrpCode
		FROM #tempClientMarketCap cap
		INNER JOIN #fpigrpData fpi ON fpi.RefClientId = cap.RefClientId
		INNER JOIN #breachedGrpData grp ON grp.dr = fpi.dr AND grp.RefIsinId = cap.RefIsinId
	) t

	SELECT
		fpi.dr,
		STUFF((SELECT DISTINCT ',' +  cl.ClientId     
					FROM #fpigrpData fpi2
					INNER JOIN  dbo.RefClient cl ON fpi2.dr = fpi.dr AND cl.RefClientId = fpi2.RefClientId
				FOR XML PATH ('')), 1, 1, '') AS FPIGroupClients 

	INTO #tempgrpClientIds
	FROM #breachedGrpData fpi
	GROUP BY fpi.dr
	

	SELECT t.RefIsinId, t.Isin, t.[Name], t.RefInstrumentId, t.RefSegmentId
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
			ROW_NUMBER() OVER (PARTITION BY isin.[Name] ORDER BY inst.RefSegmentId DESC) AS RN,
			isin.RefSegmentId
		FROM #selectedIsin  alert
		INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = alert.RefIsinId
		LEFT JOIN dbo.RefInstrument inst ON inst.Isin = isin.[Name] AND inst.RefSegmentId IN (@BSEId,@NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'
	)t
	WHERE t.RN = 1

	SELECT
		cap.RefClientId,
		cl.ClientId,
		cl.[Name] ClientName,
		@RunDateInternal HoldingDate,
		inst.[Name] AS Instrument,
		inst.Isin  AS ISIN,
		cap.SumQuantity AS Qty,
		(cap.SumQuantity * cap.Rate)/1000000 AS [Value],
		cap.holdPercentage AS IndividualHolding,
		hol.grpHoldingPercentage AS GroupHolding ,
		temp.ngrpThreshold  AS IndividualThreshold,
		temp.grpThreshold AS GroupThreshold,
		cap.TotalMCap/1000000 AS TotalMarketCapital,
		temp.FPIgrpCode AS FPIGroupCode,
		ids.FPIGroupClients ,
		inst.RefSegmentId,
		inst.RefIsinId,
		seg.Segment AS Depository,
		CASE 
			WHEN cl.DpId IS NULL THEN ''
			ELSE 'IN' +  CONVERT(VARCHAR(MAX),cl.DpId) COLLATE DATABASE_DEFAULT
		END AS DPID,
		cap.Rate AS Rate,
		custSeg.[Name] AS AccountSegment,
		inst.RefInstrumentId
	FROM #tempbreached temp
	INNER JOIN #tempClientMarketCap cap  ON temp.RefClientId = cap.RefClientId  AND temp.RefIsinId = cap.RefIsinId
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = cap.RefClientId
	INNER JOIN #instrumentData inst ON inst.RefIsinId = cap.RefIsinId 
	INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = inst.RefSegmentId
	LEFT JOIN #tempgrpClientIds ids ON ids.dr = temp.dr
	LEFT JOIN dbo.CoreAmlScenarioAlert alert ON alert.RefAmlReportId = @ReportIdInternal AND alert.RefClientId = temp.RefClientId AND alert.RefIsinId = alert.RefIsinId AND (ISNULL(alert.NetMoneyIn,-1) > temp.ngrpThreshold OR ISNULL(alert.NetMoneyOut,-1) > temp.grpThreshold )
	LEFT JOIN #tempGrpHoldingValue hol ON hol.dr = temp.dr AND inst.RefIsinId = hol.RefIsinId
	LEFT JOIN #clientCSMapping ccsm ON ccsm.RefClientId = cap.RefClientId
	LEFT JOIN dbo.RefCustomerSegment custSeg ON custSeg.RefCustomerSegmentId = ccsm.RefCustomerSegmentId
	WHERE alert.CoreAmlScenarioAlertId IS NULL

 END 
GO
--RC-WEB-81941 END