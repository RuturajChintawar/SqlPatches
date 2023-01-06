--File:Tables:dbo:RefAmlReport:DML
--RC-WEB-77973 START
GO
	UPDATE re
	SET re.[Name] = 'S64 Trades in Dormant Account EqFoCu',
		re.[Description] = 'This Scenario will detect the Trades in dormant account by a client <br>
		It will generate alert if,<br>
		1. Client have done TO greater than set Threshold and last traded date is beyond no of days Threshold<br>
		Threshold:<br>
		A. Total TO : It is a total turnover dine by a client for across the segments<br>
		B. No of Days : It is a last traded date from the run date<br>
		C. Exclude Pro/Inst : User can able to exclude Pro/Inst for Alert generation<br>'
	FROM dbo.RefAmlReport re
	WHERE re.[Name] = 'S64 Trades In Dormant Account 180Days EqFoCu'
GO
--RC-WEB-77973 END
--File:Tables:dbo:RefProcess:DML
--RC-WEB-77973 START
GO
	UPDATE pro
	SET pro.[Name] ='S64 Trades in Dormant Account EqFoCu',
	pro.[DisplayName] = 'S64 Trades in Dormant Account EqFoCu'
	FROM dbo.RefProcess pro WHERE pro.Code ='S64'
GO
--RC-WEB-77973 END
--File:Tables:dbo:SysAmlReportSetting:DML
--RC-WEB-77973 START
GO
	DECLARE @AmlReportId INT

	SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S64 Trades in Dormant Account EqFoCu'

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
		'Number_Of_Entity',
		'180',
		1,
		'No of Days',
		3,
		GETDATE(),
		'System',
		GETDATE(),
		'System'
	),
	(
		@AmlReportId,
		'Exclude_Pro',
		'False',
		1,
		'Exclude Pro',
		4,
		GETDATE(),
		'System',
		GETDATE(),
		'System'
	)
GO
--RC-WEB-77973 END
--File:StoredProcedures:dbo:Aml_GetS64TradesInDormantAccountEqFoCu
--RC-WEB-77973 START
GO
CREATE PROCEDURE dbo.Aml_GetS64TradesInDormantAccountEqFoCu
(
	@RunDate DATETIME,      
	@ReportId INT
)
AS
BEGIN
		
		DECLARE	@RunDateInternal DATETIME, @ReportIdInternal INT,@IsExcludeInstitution BIT,@IsExcludePro BIT, @NoOfDays INT,
			@ThresholdTurnover DECIMAL(28,2), @DormancyDate DATETIME, @InstitutionClientStatusId INT,@ProClientStatusId INT,
			@ActiveStatusId INT, @BSE_CASHId INT, @NSE_CASHId INT, @NSE_FNOId INT, @NSE_CDXId INT, @MCXSX_CDXId INT, 
			@OPTCURId INT ,@FUTCURId INT

		SET	@RunDateInternal = @RunDate
		SET @ReportIdInternal = @ReportId

		SELECT @ThresholdTurnover = CONVERT( INT , [Value])  
		FROM dbo.SysAmlReportSetting   
     	WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Threshold_Turnover' 
			  
		SELECT @IsExcludeInstitution = CASE WHEN   se.[VAlue] ='True' THEN 1 ELSE 0 END
		FROM dbo.SysAmlReportSetting  se
		WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_Institution' 

		SELECT @IsExcludePro = CASE WHEN   se.[VAlue] ='True' THEN 1 ELSE 0 END
		FROM dbo.SysAmlReportSetting  se
		WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_Pro'
		
		SELECT @NoOfDays = CONVERT( INT , [Value])  
		FROM dbo.SysAmlReportSetting   
     	WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Entity' 
		
		
		SET @DormancyDate = DATEADD(Day, - (@NoOfDays - 1),@RunDateInternal)

		SELECT @InstitutionClientStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'
		SELECT @ProClientStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Pro'
		SELECT @ActiveStatusId = RefClientActivationStatusId FROM dbo.RefClientActivationStatus WHERE [Name] = 'Active'

		SELECT @BSE_CASHId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH' 
		SELECT @NSE_CASHId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH' 
		SELECT @NSE_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_FNO' 
		SELECT @NSE_CDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CDX' 
		SELECT @MCXSX_CDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'MCXSX_CDX' 
		
		SELECT @OPTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'
		SELECT @FUTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR' 

		SELECT	
			RefSegmentEnumId,
			Segment
		INTO #RequiredSegment
		FROM dbo.RefSegmentEnum
		WHERE RefSegmentEnumId IN (@BSE_CASHId, @NSE_CASHId, @NSE_FNOId, @NSE_CDXId, @MCXSX_CDXId)

		SELECT    
		  RefClientId    
		INTO #clientsToExclude    
		FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
		WHERE (ExcludeAllScenarios = 1 OR RefAmlReportId = @ReportIdInternal)
		  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal) 

		SELECT 
			trade.RefClientId,
			trade.TradeDate,
			trade.RefInstrumentId,
			(ISNULL(trade.Rate,0) * trade.Quantity) AS RateQuantity,
			seg.RefSegmentEnumId
		INTO #tradesOnReportdate
		FROM dbo.CoreTrade trade
		INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId
		LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = trade.RefClientId 
		WHERE clEx.RefClientId IS NULL AND trade.TradeDate = @RunDateInternal 
		
		DROP TABLE #clientsToExclude

		;WITH tradeData_CTE AS(
			SELECT	
				trade.RefClientId,
				SUM(CASE WHEN trade.RefSegmentEnumId = @BSE_CASHId THEN RateQuantity ELSE 0 END) AS BseCashTurnover,
				SUM(CASE WHEN trade.RefSegmentEnumId = @NSE_CASHId THEN RateQuantity ELSE 0 END) AS NseCashTurnover,
				SUM(CASE WHEN trade.RefSegmentEnumId = @NSE_FNOId THEN RateQuantity ELSE 0 END) AS NseFnoTurnover,
				SUM(CASE WHEN trade.RefSegmentEnumId = @MCXSX_CDXId THEN RateQuantity ELSE 0 END) AS McxsxCdxTurnover,
				SUM(CASE WHEN trade.RefSegmentEnumId = @NSE_CDXId THEN
						CASE WHEN  inst.RefInstrumentTypeId = @OPTCURId OR inst.RefInstrumentTypeId = @FUTCURId THEN
							CASE WHEN inst.[Name] ='JPYINR' THEN RateQuantity * 1000 
								ELSE RateQuantity * inst.ContractSize END
						ELSE RateQuantity END
						ELSE 0 END) AS NseCdxTurnover,
				SUM(CASE WHEN trade.RefSegmentEnumId = @NSE_CDXId AND  (inst.RefInstrumentTypeId = @OPTCURId OR inst.RefInstrumentTypeId = @FUTCURId )THEN
							CASE WHEN inst.[Name] ='JPYINR' THEN RateQuantity * 1000 
								ELSE RateQuantity * inst.ContractSize END
						ELSE RateQuantity END)
				AS TotalTurnover
		
			FROM #tradesOnReportdate trade
			INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId
			GROUP BY trade.RefClientId, trade.TradeDate
		)

		SELECT tr.*
		INTO #Result
		FROM  tradeData_CTE tr
		WHERE tr.TotalTurnover >= @ThresholdTurnover
		
		DROP TABLE #tradesOnReportdate
		
		
		--taking distinct clients to process
		SELECT  Distinct RefClientId 
		INTO #filteredClients 
		FROM #Result result

		SELECT DISTINCT 
			client.RefClientId 
		INTO #clientsToRemove
		FROM #filteredClients client 
		INNER JOIN dbo.CoreTrade trades  ON client.RefClientId = trades.RefClientId
		INNER JOIN #RequiredSegment segment ON segment.RefSegmentEnumId = trades.RefSegmentId
		WHERE trades.TradeDate > @DormancyDate AND trades.TradeDate < @RunDateInternal  
		
		--removing the not applicable clients
		DELETE t
		FROM #filteredClients t
		INNER JOIN #clientsToRemove r ON r.RefClientId = t.RefClientId

		DROP TABLE #clientsToRemove

		--getting MAX trade date before dormancy period
		SELECT trades.RefClientId, 
			MAX(TradeDate) AS MaxTradeDate
		INTO #clientWiseMaxTradedate
		FROM #filteredClients client 
		INNER JOIN dbo.CoreTrade trades  ON client.RefClientId = trades.RefClientId
		INNER JOIN #RequiredSegment segment ON segment.RefSegmentEnumId = trades.RefSegmentId
		WHERE trades.TradeDate <= @DormancyDate
		GROUP BY trades.RefClientId

		-- REMOVE BASED ON SEGACTIVATION AND ACCOUNT OPENING DATE
		SELECT	
			temp.RefClientId,
			MAX(temp.EffectiveDate) AS LatestEffectiveDate
		INTO #dormantClientFromSegmentActivation
		FROM (SELECT
					cliSegLink.RefClientId, 
					RefClientActivationStatusId, 
					EffectiveDate,
					ROW_NUMBER() OVER (PARTITION BY cliSegLink.RefClientId, RefSegmentId ORDER BY EffectiveDate DESC, AddedOn DESC ) AS RowNumber
				FROM #filteredClients r
				INNER JOIN dbo.LinkRefClientRefSegment cliSegLink ON cliSegLink.RefClientId = r.RefClientId
				INNER JOIN #RequiredSegment seg ON cliSegLink.RefSegmentId = seg.RefSegmentEnumId
				LEFT JOIN #clientWiseMaxTradedate clWMT ON clWMT.RefClientId = r.RefClientId
				WHERE cliSegLink.EffectiveDate < @RunDateInternal AND clWMT.RefClientId IS NULL) temp
		WHERE (temp.RowNumber = 1 AND temp.RefClientActivationStatusId = @ActiveStatusId) OR temp.EffectiveDate IS NULL
		GROUP BY temp.RefClientId
		
		
		;WITH remove_BasedOnActivation AS(
			SELECT DISTINCT fc.RefClientId 
			FROM #filteredClients fc
			INNER JOIN dbo.RefClient cl ON cl.RefClientId = fc.RefClientId
			LEFT JOIN #dormantClientFromSegmentActivation seg ON seg.RefClientId = fc.RefClientId
			LEFT JOIN #clientWiseMaxTradedate clWMT ON clWMT.RefClientId = fc.RefClientId
			WHERE clWMT.RefClientId IS NULL  AND (seg.LatestEffectiveDate IS NOT NULL AND seg.LatestEffectiveDate > @DormancyDate) OR (cl.AccountOpeningDate IS NOT NULL AND cl.AccountOpeningDate > @DormancyDate)
		)
		DELETE t
		FROM #filteredClients t INNER JOIN remove_BasedOnActivation rba ON rba.RefClientId = t.RefClientId		

		SELECT  
			tr.RefClientId,
			RefSegmentId,
			tr.TradeDate
		INTO #dormantClientFromLastTrade
		FROM  #clientWiseMaxTradedate clWMT
		INNER JOIN dbo.CoreTrade tr ON clWMT.RefClientId = tr.RefClientId AND tr.TradeDate = clWMT.MaxTradeDate 
		INNER JOIN #RequiredSegment segment ON segment.RefSegmentEnumId = tr.RefSegmentId

		SELECT	
			r.RefClientId,				
			client.ClientId,
			client.[Name] AS ClientName,				
			@RunDateInternal AS TradeDate,
			TotalTurnover,
			BseCashTurnover,
			NseCashTurnover,
			NseFnoTurnover,
			NseCdxTurnover,
			McxsxCdxTurnover,
			dTrade.MaxTradeDate AS LastTradeDate,
			STUFF((SELECT DISTINCT ',' +  seg.Segment     
					FROM #dormantClientFromLastTrade t2 
					INNER JOIN  #RequiredSegment seg ON t2.RefClientId = r.RefClientId  AND seg.RefSegmentEnumId = t2.RefSegmentId
				FOR XML PATH ('')), 1, 1, '') AS LastTrdSeg,
			(DATEDIFF(DAY, COALESCE(dTrade.MaxTradeDate,seg.LatestEffectiveDate,client.AccountOpeningDate), @RunDateInternal ) + 1) AS NoOfDays,
			CASE WHEN r.BseCashTurnover > r.NseCashTurnover AND r.BseCashTurnover > r.NseFnoTurnover AND r.BseCashTurnover > r.NseCdxTurnover AND r.BseCashTurnover > r.McxsxCdxTurnover THEN @BSE_CASHId
			 WHEN  r.NseCashTurnover > r.NseFnoTurnover AND r.NseCashTurnover > r.NseCdxTurnover AND r.NseCashTurnover > r.McxsxCdxTurnover THEN @NSE_CASHId
			 WHEN r.NseFnoTurnover > r.NseCdxTurnover AND r.NseFnoTurnover> r.McxsxCdxTurnover THEN @NSE_FNOId
			 WHEN  r.NseCdxTurnover> r.McxsxCdxTurnover THEN @NSE_CDXId
			 ELSE @MCXSX_CDXId
			 END AS RefSegmentId
		FROM #filteredClients fc
		INNER JOIN #Result r ON fc.RefClientId = r.RefClientId
		INNER JOIN dbo.RefClient client ON client.RefClientId = r.RefClientId
		LEFT JOIN #clientWiseMaxTradedate dTrade ON r.RefClientId = dTrade.RefClientId
		LEFT JOIN #dormantClientFromSegmentActivation seg ON seg.RefClientId = r.RefClientId
		WHERE (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstitutionClientStatusId)  AND 
			(@IsExcludePro = 0 OR client.RefClientStatusId <> @ProClientStatusId)
	END
GO
--RC-WEB-77973 END
--File:Tables:dbo:CoreAmlScenarioAlert:DML
--RC-WEB-77973 START
GO
		DECLARE
		@RefReportId INT
		SET @RefReportId = (SELECT re.RefAmlReportId FROM dbo.RefAmlReport re WHERE re.[Name] = 'S64 Trades in Dormant Account EqFoCu')
		UPDATE al
		SET al.VoucherNo = CONVERT(VARCHAR(100),Segment)
		FROM dbo.CoreAmlScenarioAlert al  
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = al.RefSegmentEnumId  AND al.RefAmlReportId = @RefReportId
GO
--RC-WEB-77973 END
