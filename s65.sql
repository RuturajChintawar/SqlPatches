select * from RefAmlReport where RefAmlReportId=96

select * from CoreAmlScenarioAlert where RefAmlReportId=96 and ReportDate='2016-05-21 00:00:00.000'
select * from RefClient where RefClientId In (312992,
300779,
748101,
746627,
313039,
201173,
31043,
313070,
743677,
741134,
1338543,
1338564,
312982,
312983,
772352,
797952,
797806,
1338567)

------WEB-55705 KA START
GO
ALTER PROCEDURE dbo.Aml_GetTradesInDormantAccountEqFoCu
(
	@ReportDate DATETIME,
	@DormantDays INT,
	@ThresholdTurnover DECIMAL(28,2),
	@Vertical VARCHAR(20),
	@IsExcludeInstitution bit
)
AS
BEGIN
		
		DECLARE	@ReportDateInternal DATETIME, @IsExcludeInstitutionInternal BIT, @DormantDaysInternal INT, 
			@ThresholdTurnoverInternal DECIMAL(28,2), @VerticalInternal VARCHAR(20),
			@DormancyDate DATETIME, @InstitutionClientStatusId INT, @ActiveStatusId INT, @BSE_CASHId INT,
			@NSE_CASHId INT, @NSE_FNOId INT, @NSE_CDXId INT, @MCXSX_CDXId INT, @NCDEX_FNOId INT, @MCX_FNOId INT,
			@OPTIDXId INT, @OPTSTKId INT, @OPTCURId INT, @OPTFUTId INT

		SET @IsExcludeInstitutionInternal= @IsExcludeInstitution
		SET	@ReportDateInternal = @ReportDate
		SET	@DormantDaysInternal = @DormantDays
		SET @ThresholdTurnoverInternal = @ThresholdTurnover
		SET @VerticalInternal = @Vertical
		SET @DormancyDate = DATEADD(Day, -@DormantDays, @ReportDateInternal)
		SELECT @InstitutionClientStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'
		SELECT @ActiveStatusId = RefClientActivationStatusId FROM dbo.RefClientActivationStatus WHERE [Name] = 'Active'
		SELECT @BSE_CASHId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH' 
		SELECT @NSE_CASHId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH' 
		SELECT @NSE_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_FNO' 
		SELECT @NSE_CDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CDX' 
		SELECT @MCXSX_CDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'MCXSX_CDX' 
		SELECT @NCDEX_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NCDEX_FNO' 
		SELECT @MCX_FNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'MCX_FNO'
		SELECT @OPTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'
		SELECT @OPTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'
		SELECT @OPTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'
		SELECT @OPTFUTId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTFUT' 

		SELECT	
			RefSegmentEnumId,
			Segment
		INTO #RequiredSegment
		FROM dbo.RefSegmentEnum
		WHERE (@VerticalInternal = 'NonCommodity' AND RefSegmentEnumId IN (@BSE_CASHId, @NSE_CASHId, @NSE_FNOId, @NSE_CDXId, @MCXSX_CDXId))
		     OR (@VerticalInternal = 'Commodity' AND RefSegmentEnumId IN (@NCDEX_FNOId, @MCX_FNOId))

		SELECT 
			trade.RefClientId,
			trade.TradeDate,
			trade.RefInstrumentId,
			(trade.Rate * trade.Quantity) AS RateQuantity,
			ISNULL(trade.Rate, 0) AS Rate,
			trade.Quantity,
			seg.RefSegmentEnumId
		INTO #trades
		FROM dbo.CoreTrade trade
		INNER JOIN #RequiredSegment seg ON trade.RefSegmentId = seg.RefSegmentEnumId
		WHERE trade.TradeDate BETWEEN @DormancyDate AND @ReportDateInternal

		SELECT DISTINCT
			RefInstrumentId
		INTO #instrumentIds
		FROM #trades

		SELECT
			trade.RefInstrumentId,
			ISNULL(inst.ContractSize, 1) AS ContractSize,
			ISNULL(inst.StrikePrice, 0) AS StrikePrice,
			(ISNULL(inst.PriceNumerator, 1) / ISNULL(inst.PriceDenominator, 1)) AS PPQ,
			ISNULL(inst.GeneralNumerator, 1) / ISNULL(inst.GeneralDenominator, 1) AS GG,
			ISNULL(inst.MarketLot, 1) AS MarketLot,
			inst.RefInstrumentTypeId
		INTO #instrumentData
		FROM #instrumentIds trade
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId
		
		SELECT	
			trade.RefClientId,
			trade.TradeDate,
			SUM(CASE WHEN trade.RefSegmentEnumId = @BSE_CASHId THEN RateQuantity ELSE 0 END) AS BseCashTurnover,
			SUM(CASE WHEN trade.RefSegmentEnumId = @NSE_CASHId THEN RateQuantity ELSE 0 END) AS NseCashTurnover,
			SUM(CASE WHEN trade.RefSegmentEnumId = @NSE_FNOId THEN RateQuantity ELSE 0 END) AS NseFnoTurnover,
			SUM(CASE WHEN trade.RefSegmentEnumId = @NSE_CDXId THEN
					CASE WHEN  inst.RefInstrumentTypeId = @OPTCURId
					THEN RateQuantity * inst.ContractSize
					ELSE RateQuantity END
					ELSE 0 END) AS NseCdxTurnover,
			SUM(CASE WHEN trade.RefSegmentEnumId = @MCXSX_CDXId THEN RateQuantity ELSE 0 END) AS McxsxCdxTurnover,
			SUM(
				CASE 
					WHEN trade.RefSegmentEnumId = @NCDEX_FNOId AND inst.RefInstrumentTypeId in (@OPTIDXId,@OPTSTKId,@OPTCURId,@OPTFUTId) 
						THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + inst.StrikePrice) * inst.PPQ * trade.Quantity * inst.GG, 2))
					WHEN trade.RefSegmentEnumId = @NCDEX_FNOId AND inst.RefInstrumentTypeId NOT in (@OPTIDXId,@OPTSTKId,@OPTCURId,@OPTFUTId) 
						THEN CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * inst.PPQ * trade.Quantity * inst.GG, 2))
					ELSE 0 
				END) 
			AS NcdexFnoTurnover,
			SUM(
				CASE 
					WHEN trade.RefSegmentEnumId = @MCX_FNOId AND inst.RefInstrumentTypeId in (@OPTIDXId,@OPTSTKId,@OPTCURId,@OPTFUTId) 
						THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + inst.StrikePrice) * inst.PPQ * trade.Quantity * inst.MarketLot * inst.GG * 
							inst.ContractSize, 2))
					WHEN trade.RefSegmentEnumId = @MCX_FNOId AND inst.RefInstrumentTypeId NOT IN (@OPTIDXId,@OPTSTKId,@OPTCURId,@OPTFUTId)
						THEN CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * inst.PPQ * trade.Quantity * inst.MarketLot * inst.GG * 
							inst.ContractSize, 2))
					ELSE 0 
				END) 
			AS McxFnoTurnover,
			SUM(
				CASE 
					WHEN trade.RefSegmentEnumId = @MCX_FNOId AND inst.RefInstrumentTypeId IN (@OPTIDXId,@OPTSTKId,@OPTCURId,@OPTFUTId) 
						THEN CONVERT(DECIMAL(28, 2), ROUND((trade.Rate + inst.StrikePrice) * inst.PPQ * trade.Quantity * inst.MarketLot * 
							inst.GG, 2))
					WHEN trade.RefSegmentEnumId = @MCX_FNOId AND inst.RefInstrumentTypeId NOT IN (@OPTIDXId,@OPTSTKId,@OPTCURId,@OPTFUTId)
						THEN CONVERT(DECIMAL(28, 2), ROUND(trade.Rate * inst.PPQ * trade.Quantity * inst.MarketLot * inst.GG, 2))  
					WHEN trade.RefSegmentEnumId = @NSE_CDXId AND inst.RefInstrumentTypeId = @OPTCURId
						THEN RateQuantity * inst.ContractSize
					ELSE RateQuantity
				END)
			AS TotalTurnover
		INTO #Result
		FROM #trades trade
		INNER JOIN #instrumentData inst ON inst.RefInstrumentId = trade.RefInstrumentId
		WHERE trade.TradeDate = @ReportDateInternal
		GROUP BY trade.RefClientId, trade.TradeDate
		HAVING SUM(RateQuantity) >= @ThresholdTurnoverInternal
		
		CREATE INDEX IX_#Result_RefClientId On #Result(RefClientId)
		
		SELECT	
			temp.RefClientId,
			MAX(temp.EffectiveDate) AS LatestDate
		INTO #DormantClientFromSegmentActivation
		FROM (SELECT
			cliSegLink.RefClientId, 
			RefSegmentId, 
			RefClientActivationStatusId, 
			EffectiveDate,
			ROW_NUMBER() OVER (PARTITION BY cliSegLink.RefClientId, RefSegmentId 
				ORDER BY EffectiveDate DESC, AddedOn DESC ) AS RowNumber
			FROM #Result r
			INNER JOIN dbo.LinkRefClientRefSegment cliSegLink ON cliSegLink.RefClientId = r.RefClientId
			INNER JOIN #RequiredSegment seg ON cliSegLink.RefSegmentId = seg.RefSegmentEnumId
			WHERE cliSegLink.EffectiveDate < @ReportDateInternal) temp
		WHERE (temp.RowNumber = 1 AND temp.RefClientActivationStatusId = @ActiveStatusId) 
			OR temp.EffectiveDate IS NULL
		GROUP BY temp.RefClientId
		
		SELECT  
			RefClientId,
			RefSegmentId,
			TradeDate
		INTO #DormantClientFromLastTrade
		FROM (SELECT 
				trade.RefClientId,
				trade.RefSegmentId,
				trade.TradeDate,
				ROW_NUMBER() OVER(PARTITION BY trade.RefClientId ORDER BY trade.TradeDate DESC) AS RowNumber
			FROM #Result r
			INNER JOIN dbo.CoreTrade trade ON trade.RefClientId = r.RefClientId
			WHERE NOT EXISTS (SELECT 1 FROM #trades tr WHERE tr.RefClientId = r.RefClientId AND tr.TradeDate < @ReportDateInternal AND
				tr.TradeDate > @DormancyDate) AND trade.TradeDate <= @DormancyDate) temp
		WHERE temp.RowNumber = 1	
		
		SELECT 
			client.RefClientId,
			client.AccountOpeningDate,
			client.ClientId,
			client.[Name],
			client.RefIntermediaryId
		INTO #clients
		FROM #Result r
		INNER JOIN dbo.RefClient client ON r.RefClientId = client.RefClientId
		WHERE client.RefClientStatusId IS NOT NULL AND (@IsExcludeInstitutionInternal = 0
			OR client.RefClientStatusId <> @InstitutionClientStatusId)

		SELECT	
			client.RefClientId,
			client.AccountOpeningDate
		INTO #DormantClientFromAccountOpeningDate
		FROM #clients client
		WHERE (client.AccountOpeningDate IS NULL 
				 OR client.AccountOpeningDate <= @DormancyDate)
		
		SELECT	
			t.RefClientId,
			t.LatestDate AS PreviousDate,
			t.DateType AS PreviousDateType,
			ROW_NUMBER() OVER( PARTITION BY t.RefClientId ORDER BY t.LatestDate DESC) AS RowNumber
		INTO #PreviousDate
		FROM (SELECT RefClientId, LatestDate, 'Latest Segment Activation Date' AS DateType 
			FROM #DormantClientFromSegmentActivation
			WHERE LatestDate IS NOT NULL
			UNION
			SELECT RefClientId, TradeDate AS LatestDate, 'Last Trade Date' AS DateType 
			FROM #DormantClientFromLastTrade
			WHERE TradeDate IS NOT NULL
			UNION
			SELECT RefClientId, AccountOpeningDate AS LatestDate, 'Account Opening Date' AS DateType 
			FROM #DormantClientFromAccountOpeningDate
			WHERE AccountOpeningDate IS NOT NULL
		) t
		
		SELECT	
			r.RefClientId,				
			client.ClientId,
			client.[Name] AS ClientName,				
			r.TradeDate,
			TotalTurnover,
			BseCashTurnover,
			NseCashTurnover,
			NseFnoTurnover,
			NseCdxTurnover,
			McxsxCdxTurnover,
			NcdexFnoTurnover,
			McxFnoTurnover,
			dTrade.TradeDate AS LastTradeDate,
			seg.Segment AS LastTradeSegment,
			pd.PreviousDate,
			pd.PreviousDateType,
			rf.IntermediaryCode,
			rf.[Name] as IntermediaryName,
			rf.TradeName 
		FROM #Result r
		INNER JOIN #DormantClientFromLastTrade dTrade ON r.RefClientId = dTrade.RefClientId
		INNER JOIN #RequiredSegment seg ON dtrade.RefSegmentId = seg.RefSegmentEnumId
		INNER JOIN #DormantClientFromAccountOpeningDate dAccDate ON r.RefClientId = dAccDate.RefClientId
		INNER JOIN #clients client ON r.RefClientId = client.RefClientId
		LEFT JOIN #DormantClientFromSegmentActivation dSegActive ON r.RefClientId = dSegActive.RefClientId
		LEFT JOIN #PreviousDate pd ON r.RefClientId = pd.RefClientId AND pd.RowNumber = 1
		LEFT JOIN dbo.RefIntermediary rf on client.RefIntermediaryId = rf.RefIntermediaryId
		WHERE dSegActive.RefClientId IS NOT NULL OR
			(dSegActive.LatestDate IS NULL OR
				(dSegActive.LatestDate <= @DormancyDate))
END
GO
------WEB-55705 KA END