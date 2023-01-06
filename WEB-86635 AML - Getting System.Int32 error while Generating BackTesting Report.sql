GO
	EXEC dbo.Sys_DropIfExists 'AML_GetMoneyFlowScenarioReportData','P'
GO
GO
	CREATE PROCEDURE dbo.AML_GetMoneyFlowScenarioReportData
(
	@StartDate DATETIME,  
	@EndDate DATETIME ,  
	@IsMoneyIn BIT,  
	@Vertical VARCHAR(20) ,  
	@ReportId INT,
	@RunDateCheckRequired BIT = 0
)
AS   
BEGIN  
   
	DECLARE @StartDateInternal DATETIME, @EndDateInternal DATETIME, @IsMoneyInInternal BIT, @VerticalInternal VARCHAR(20),  
		@InternalRunDateCheckRequired BIT, @Receipt INT, @Payment INT, @ProfileDefault INT, @InstitutionStatus INT,  
		@BseCashSegmentId INT, @ReceiptOrPayment INT, @DefaultNetworth BIGINT, @DefaultIncome VARCHAR(5000),  
		@VerticalInternalId INT, @TransactionDate DATETIME  , @DefaultIncomeAbove1Cr DECIMAL(28, 2),@VerticalNoSegmentInternal BIT,
		@DefaultIncomeMultiplier DECIMAL(28,2) , @DefaultNetworthMultiplier DECIMAL(28,2), @ReportIdInternal INT, @IsFairValueMultiplier BIT

    SET @ReportIdInternal = @ReportId
  
	SET @IsFairValueMultiplier = CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.RefAmlReport WHERE RefAmlReportId = @ReportIdInternal AND
											 [Name] IN ('S115 Net Money Out 1 Day MF','S114 Net Money In 1 Day MF') ) THEN 1 ELSE 0 END
	SELECT @Receipt = RefVoucherTypeId FROM dbo.RefVoucherType WHERE [Name] = 'Receipt'  
	SELECT @Payment = RefVoucherTypeId FROM dbo.RefVoucherType WHERE [Name] = 'Payment'  
	SELECT @ProfileDefault = RefAmlQueryProfileId FROM dbo.RefAmlQueryProfile WHERE [Name] = 'Default'  
    SELECT @InstitutionStatus = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'  
    SET @StartDateInternal = dbo.GetDateWithoutTime(@StartDate)  
    SET @EndDateInternal = CONVERT(DATETIME,DATEDIFF(dd, 0, dbo.GetDateWithoutTime(@EndDate))) + CONVERT(DATETIME,'23:59:59.000')  
	SET @TransactionDate = dbo.GetDateWithoutTime(@EndDateInternal)  
    SET @IsMoneyInInternal = @IsMoneyIn  
    SET @VerticalInternal = @Vertical 
	SET @VerticalNoSegmentInternal = CASE WHEN @VerticalInternal = 'NoSegment' THEN 1 ELSE 0 END
    SET @InternalRunDateCheckRequired = @RunDateCheckRequired  
    SELECT @BseCashSegmentId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'  
	SET @VerticalInternalId = CASE WHEN @VerticalInternal = 'NonCommodity' THEN 1  
		WHEN @VerticalInternal = 'Commodity' THEN 2  
		WHEN @VerticalInternal = 'MutualFund' THEN 3 ELSE 0 END  
	SELECT @DefaultIncomeAbove1Cr = CONVERT(DECIMAL(28, 2), ISNULL([Value], 0)) FROM dbo.SysConfig WHERE [Name] = 'Income_Value_For_Above_One_Crore'
	SET @DefaultIncomeAbove1Cr = CASE WHEN @DefaultIncomeAbove1Cr <> 0 THEN @DefaultIncomeAbove1Cr ELSE 10000000 END
      
	SELECT @DefaultIncomeMultiplier = ISNULL(CONVERT( DECIMAL(28,2),[Value]),1) FROM dbo.SysConfig WHERE [Name] = 'Aml_Client_Income_Multiplier'
	SELECT @DefaultNetworthMultiplier = ISNULL(CONVERT( DECIMAL(28,2),[Value]),1) FROM dbo.SysConfig WHERE [Name] = 'Aml_Client_Networth_Multiplier'
         
	SELECT
		rul.Threshold,
		rul.Threshold2,
		link.RefConstitutionTypeId
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule rul
	LEFT JOIN dbo.LinkRefAmlScenarioRuleRefConstitutionType link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId
	WHERE rul.RefAmlReportId = @ReportIdInternal 


    IF (@IsMoneyInInternal = 1)  
		SET @ReceiptOrPayment = @Receipt  
    ELSE  
        SET @ReceiptOrPayment = @Payment  
          
    SELECT   
		seg.RefSegmentEnumId,  
		seg.Segment  
	INTO #RequiredSegment  
	FROM dbo.RefSegmentEnum seg  
	WHERE (@VerticalInternalId = 1 AND seg.Code IN ('BSE_CASH','NSE_CASH','NSE_FNO','BSE_FNO','NSE_CDX','MCXSX_CDX','BSE_CDX','NSE_INT','MCXSX_CASH','MCXSX_FNO'))  
		OR (@VerticalInternalId = 2 AND seg.Code IN ('NCDEX_FNO', 'MCX_FNO', 'ACE', 'NMCE', 'NSEL', 'ICEX'))  
		OR (@VerticalInternalId = 3 AND seg.Code IN ('BSE_MF', 'NSE_MF'))  
      

		SELECT  
			RefClientId  
		INTO #clientsToExclude_CTE
		FROM dbo.LinkRefAmlReportRefClientAlertExclusion  
		WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportIdInternal)   
		AND @TransactionDate >= FromDate AND (ToDate IS NULL OR ToDate >= @TransactionDate)
	

    SELECT DISTINCT cft.RefClientId   
    INTO #clients  
    FROM dbo.CoreFinancialTransaction cft   
	LEFT JOIN #RequiredSegment sg On sg.RefSegmentEnumId = cft.RefSegmentId
	LEFT JOIN #clientsToExclude_CTE clEx ON clEx.RefClientId = cft.RefClientId
	WHERE clEx.RefClientId IS NULL
		AND (sg.RefSegmentEnumId IS NOT NULL OR @VerticalNoSegmentInternal = 1)
	 --   AND cft.RefVoucherTypeId = @ReceiptOrPayment   
		--AND cft.TransactionDate = @TransactionDate
       AND (@InternalRunDateCheckRequired = 0 AND cft.RefVoucherTypeId = @ReceiptOrPayment   
			AND cft.TransactionDate BETWEEN @StartDateInternal AND @EndDateInternal)   
		OR (@InternalRunDateCheckRequired = 1 AND cft.RefVoucherTypeId = @ReceiptOrPayment   
			AND cft.TransactionDate = @TransactionDate)      


	SELECT    
		t.RefClientId,  
		SUM(CASE WHEN t.RefVoucherTypeId = @Payment   
			THEN t.Amount  
			ELSE 0 END) AS Payment,  
		SUM(CASE WHEN t.RefVoucherTypeId = @Receipt  
			THEN t.Amount  
			ELSE 0 END) AS Receipt
	INTO #FT
	FROM #clients clients  
	INNER JOIN dbo.CoreFinancialTransaction t ON clients.RefClientId = t.RefClientId  
	LEFT JOIN #RequiredSegment seg ON seg.RefSegmentEnumId = t.RefSegmentId  
	WHERE t.RefVoucherTypeId IN (@Receipt, @Payment)  
		AND (seg.RefSegmentEnumId IS NOT NULL OR @VerticalNoSegmentInternal = 1)
		AND t.TransactionDate BETWEEN @StartDateInternal AND @EndDateInternal  
	GROUP BY t.RefClientId

	--drop TABLE #clients

	
	SELECT ft.RefClientId, 
			ft.Payment, 
			ft.Receipt, 
			ft.NetMoneyOut,
			ft.NetMoneyIn,
			ABS(ft.NetMoneyIn) AS AbsoluteNetMoney
	INTO #FinalFT
	FROM(
			SELECT ft.RefClientId, 
					ft.Payment, 
					ft.Receipt, 
					ft.Payment - ft.Receipt AS NetMoneyOut,
					ft.Receipt - ft.Payment AS NetMoneyIn
			FROM #FT ft 
			WHERE EXISTS(SELECT TOP 1 1 FROM #scenarioRules r WHERE r.Threshold <= ABS(ft.Payment - ft.Receipt) )
		) ft
	WHERE (ft.NetMoneyIn > 0 AND @IsMoneyInInternal = 1 OR  @IsMoneyInInternal = 0 AND ft.NetMoneyOut > 0)
		
		
	--drop TABLE  #FT
  
	SELECT @DefaultNetworth = cliNetSellPoint.DefaultNetworth   
	FROM dbo.RefAmlQueryProfile qp     
	LEFT JOIN dbo.LinkRefAmlQueryProfileRefSegment qpSegment ON qpSegment.RefSegmentId = @BseCashSegmentId  
		AND qpSegment.RefAmlQueryProfileId = qp.RefAmlQueryProfileId        
	LEFT JOIN dbo.SysAmlClientNetSellPoints cliNetSellPoint ON   
		cliNetSellPoint.LinkRefAmlQueryProfileRefSegmentId = qpSegment.LinkRefAmlQueryProfileRefSegmentId  
	WHERE qp.RefAmlQueryProfileId = @ProfileDefault   
  
	SELECT @DefaultIncome = reportSetting.[Value]  
		FROM dbo.RefAmlQueryProfile qp     
		LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.[Name] = 'Client Purchase to Income'  
		LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId  
			AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId  
			AND reportSetting.[Name] = 'Default_Income'  
		WHERE qp.RefAmlQueryProfileId = @ProfileDefault  
  
	DECLARE @InstitutionalClientDefaultIncome VARCHAR(5000), @InstitutionalClientDefaultNetworth BIGINT,  
		@results VARCHAR(MAX)  
  
	SELECT @InstitutionalClientDefaultIncome = [Value] FROM dbo.SysConfig WHERE [Name] = 'Institutional_Client_Default_Income'  
	SELECT @InstitutionalClientDefaultNetworth = [Value] FROM dbo.SysConfig WHERE [Name] = 'Institutional_Client_Default_Networth'
	  
	CREATE TABLE #TempLinkRefClientRefIncomeGroup (  
		LinkRefClientRefIncomeGroupId INT,  
		RefClientId INT,  
		RefIncomeGroupId INT,  
		Income BIGINT,  
		Networth BIGINT
	)  

	INSERT INTO #TempLinkRefClientRefIncomeGroup(  
		LinkRefClientRefIncomeGroupId,  
		RefClientId,  
		RefIncomeGroupId,  
		Income,  
		Networth
	)  
    select 
		link.LinkRefClientRefIncomeGroupId,
		link.RefClientId,
		link.RefIncomeGroupId,
		ISNULL(CASE WHEN link.Income IS NOT NULL
				THEN link.Income
				WHEN rig.[Name] IS NOT NULL AND rig.IncomeTo > 10000000
				THEN @DefaultIncomeAbove1Cr
				WHEN rig.[Name] IS NOT NULL
				THEN rig.IncomeTo
				ELSE @DefaultIncome END,0) AS Income,
		ISNULL(link.Networth,1)
		FROM (
		select 
		link.LinkRefClientRefIncomeGroupId,
		client.RefClientId,
		link.RefIncomeGroupId,
		link.Income,
		link.Networth,
		ROW_NUMBER() over(partition by link.RefClientId order by isnull(FromDate,'01/01/1900') desc) as RowNumber
		from #FinalFT client
		LEFT JOIN dbo.LinkRefClientRefIncomeGroup link on client.RefClientId=link.RefClientId
		) link 
		LEFT JOIN dbo.RefIncomeGroup rig on  rig.RefIncomeGroupId=link.RefIncomeGroupId
		where RowNumber=1




	SELECT 
		CASE WHEN ISNULL(cl.IncomeMultiplier,0) <> 0 THEN cl.IncomeMultiplier
			ELSE @DefaultIncomeMultiplier END AS IncomeMultiplier,

		CASE WHEN ISNULL(cl.NetworthMultiplier,0) <> 0 THEN cl.NetworthMultiplier
			ELSE @DefaultNetworthMultiplier END AS NetworthMultiplier,
		ft.Payment, 
		ft.Receipt, 
		ft.NetMoneyOut, 
		ft.NetMoneyIn,
		(clientIncomeGroup.Income * (CASE WHEN ISNULL(cl.IncomeMultiplier,0) <> 0 THEN cl.IncomeMultiplier ELSE @DefaultIncomeMultiplier END) +
		clientIncomeGroup.Networth * (CASE WHEN ISNULL(cl.NetworthMultiplier,0) <> 0 THEN cl.NetworthMultiplier ELSE @DefaultNetworthMultiplier END)) AS FairValue,
		CASE WHEN clientIncomeGroup.Networth IS NULL THEN 'Default' ELSE '' END AS NetworthDesc,
		 incomeGroup.[Name]  AS IncomeDesc,
		CASE WHEN cl.RefClientStatusId = @InstitutionStatus AND @InstitutionalClientDefaultNetworth > 0  
			THEN COALESCE (clientIncomeGroup.Networth, @InstitutionalClientDefaultNetworth)  
			ELSE COALESCE (clientIncomeGroup.Networth, @DefaultNetworth, 0) END AS Networth,
		cl.RefConstitutionTypeId,
		cl.[Name] AS ClientName,  
		cl.ClientId AS ClientId ,
		cl.RefClientId,
		RefClientStatusId,
		RefIntermediaryId,
		RefClientSpecialCategoryId,
		clientIncomeGroup.Income,
		AbsoluteNetMoney
	INTO #clientDetails
	FROM #FinalFT ft 
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = ft.RefClientId
	LEFT JOIN #TempLinkRefClientRefIncomeGroup clientIncomeGroup ON clientIncomeGroup.RefClientId = cl.RefClientId  
	LEFT JOIN dbo.RefIncomeGroup incomeGroup ON incomeGroup.RefIncomeGroupId = clientIncomeGroup.RefIncomeGroupId

	--drop TABLE #FinalFT

	SELECT   
		ft.RefClientId,  
		ft.ClientName,  
		ft.ClientId, 
		ft.Networth,  
		ft.Income,     
		ft.NetworthDesc,  
		ft.IncomeDesc,      
		ft.IncomeMultiplier,
		ft.NetworthMultiplier,
		ri.IntermediaryCode,  
		ri.[Name] AS IntermediaryName,  
		ri.TradeName,
		csc.[Name] AS CSC, 
		ft.Payment, 
		ft.Receipt, 
		ft.NetMoneyOut, 
		ft.NetMoneyIn,
		constitution.[Name] AS ConstitutionName,
		ft.FairValue,
		ft.FairValue * rul.Threshold2 AS NetFairValue,
		rul.Threshold2 AS FairValueMultiplier,
		ft.RefConstitutionTypeId
	FROM #clientDetails ft  
	INNER JOIN #scenarioRules rul ON ISNULL(rul.RefConstitutionTypeId,0) = ISNULL(ft.RefConstitutionTypeId,0)
				AND AbsoluteNetMoney >= rul.Threshold
				AND (@IsFairValueMultiplier = 0 AND  AbsoluteNetMoney >= FairValue
					OR @IsFairValueMultiplier = 1 AND AbsoluteNetMoney >= FairValue * rul.Threshold2)
	LEFT JOIN dbo.RefConstitutionType constitution ON ft.RefConstitutionTypeId = constitution.RefConstitutionTypeId   
	LEFT JOIN dbo.RefIntermediary ri ON ft.RefIntermediaryId = ri.RefIntermediaryId      
	LEFT JOIN #TempLinkRefClientRefIncomeGroup clientIncomeGroup ON clientIncomeGroup.RefClientId = ft.RefClientId  
	LEFT JOIN dbo.RefIncomeGroup incomeGroup ON incomeGroup.RefIncomeGroupId = clientIncomeGroup.RefIncomeGroupId
	LEFT JOIN dbo.RefClientSpecialCategory csc ON ft.RefClientSpecialCategoryId = csc.RefClientSpecialCategoryId 
END  
GO
