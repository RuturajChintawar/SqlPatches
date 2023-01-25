/************************* BM WEB-83781 STARTS	*************************/
GO
EXEC dbo.Sys_DropIfExists 'AML_GetSynchronizedTrading1DayFOPremiumTO_CoreSyncTradeSegregation','P'
GO
GO
CREATE PROCEDURE dbo.AML_GetSynchronizedTrading1DayFOPremiumTO_CoreSyncTradeSegregation
(
	@RunDate DATETIME,
	@ReportId INT
)
AS
BEGIN

	DECLARE @RefAmlReportIdInternal INT, @RunDateInternal DATETIME, @ExcludePro BIT,@ExcludeAlgoTrade BIT,
		@ExcludeInstitution BIT,@ExcludeOppositePro BIT, @ExcludeOppositeInstitution BIT,@OPTCUR INT,
		@FUTCUR INT,@OPTSTK INT,@OPTIDX INT,@OPTIRC INT, @ProRefClientStatusId INT,
		@InstitutionRefClientStatusId INT, @NSE_FNO INT,@NSE_CDX INT,@MCXSX_CDX INT

	SET @RefAmlReportIdInternal = @ReportId
   
	SET @RunDateInternal = @RunDate

    SELECT @ExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportIdInternal AND [Name] = 'Exclude_Pro'

	SELECT @ExcludeAlgoTrade = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportIdInternal AND [Name] = 'Exclude_AlgoTrade'

    SELECT @ExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportIdInternal AND [Name] = 'Exclude_Institution'

    SELECT @ExcludeOppositePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportIdInternal AND [Name] = 'Exclude_OppositePro'

    SELECT @ExcludeOppositeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportIdInternal AND [name] = 'Exclude_OppositeInstitution'

	SELECT @OPTCUR = RefInstrumentTypeId
	FROM dbo.RefInstrumentType
	WHERE InstrumentType = 'OPTCUR'

	SELECT @FUTCUR = RefInstrumentTypeId
	FROM dbo.RefInstrumentType
	WHERE InstrumentType = 'FUTCUR'

	SELECT @OPTSTK = RefInstrumentTypeId
	FROM dbo.RefInstrumentType
	WHERE InstrumentType = 'OPTSTK'

	SELECT @OPTIDX = RefInstrumentTypeId
	FROM dbo.RefInstrumentType
	WHERE InstrumentType = 'OPTIDX'

	SELECT @OPTIRC = RefInstrumentTypeId
	FROM dbo.RefInstrumentType
	WHERE InstrumentType = 'OPTIRC'

	SET @InstitutionRefClientStatusId = dbo.GetClientStatusId('Institution')
   
	SET @ProRefClientStatusId = dbo.GetClientStatusId('Pro')

   
	SELECT @NSE_FNO = RefSegmentEnumId
		FROM dbo.RefSegmentEnum
		WHERE CODE = 'NSE_FNO'
   
	SELECT @NSE_CDX = RefSegmentEnumId
		FROM dbo.RefSegmentEnum
		WHERE CODE = 'NSE_CDX'

	SELECT @MCXSX_CDX = RefSegmentEnumId
		FROM dbo.RefSegmentEnum
		WHERE CODE = 'MCXSX_CDX'

   ;WITH clientsToExclude_CTE AS
	(
		SELECT DISTINCT RefClientId
		FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex
		WHERE (ex.RefAmlReportId = @RefAmlReportIdInternal OR ex.ExcludeAllScenarios = 1) 
			AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)
	)

	SELECT
		trade.CoreSyncTradeSegregationId,
		trade.RefClientId,
		trade.RefInstrumentId,
		trade.TradeDate,
		trade.TradeDateTime,
		trade.TradeId,
		CASE WHEN BuySell = 'Buy' THEN 1  ELSE 0 END AS IsBuy,
		CASE WHEN trade.RefSegmentId = @NSE_CDX THEN ROUND(trade.Rate, 3) ELSE trade.Rate END AS Rate ,
		trade.Quantity,
		trade.BuyCtslId,
		trade.SellCtslId,
		trade.RefSegmentId,
		trade.BuyOrdTime,
		trade.SellOrdTime,
		CASE WHEN SUBSTRING(CONVERT(VARCHAR(MAX), trade.BuyCtslId), 13, 1) NOT IN ('0', '2', '4')
					AND SUBSTRING(CONVERT(VARCHAR(MAX), trade.SellCtslId), 13, 1) NOT IN ('0', '2', '4') THEN 0
			ELSE 1 END AS IsAlgoTrade,
		trade.BuyTerminal,
		trade.SellTerminal,
		trade.OppRefClientId
	INTO #FilteredTrade
	FROM dbo.CoreSyncTradeSegregation trade
	LEFT JOIN clientsToExclude_CTE clEx ON clEx.RefClientId = trade.RefClientId
	WHERE trade.TradeDate = @RunDateInternal
	AND trade.RefSegmentId IN (@NSE_FNO, @NSE_CDX, @MCXSX_CDX)
	AND (@ExcludeAlgoTrade = 0
			OR (
					SUBSTRING(CONVERT(VARCHAR(MAX), trade.BuyCtslId), 13, 1) NOT IN ('0', '2', '4')
					AND SUBSTRING(CONVERT(VARCHAR(MAX), trade.SellCtslId), 13, 1) NOT IN ('0', '2', '4')
				)
		)
	AND clEx.RefClientId IS NULL

    SELECT DISTINCT
		fltr.RefClientId
    INTO #distinctClient
    FROM #FilteredTrade  fltr

    SELECT DISTINCT RefInstrumentId
    INTO #tmpInstruments
    FROM #FilteredTrade

    SELECT ins.RefInstrumentId,
        ins.RefInstrumentTypeId,
        ISNULL(ins.StrikePrice,0) AS StrikePrice,
        ISNULL(ins.PriceNumerator,1) AS PriceNumerator,
        ISNULL(ins.ContractSize, 1) AS ContractSize,
        ISNULL(ins.PriceDenominator, 1) AS PriceDenominator,
        ISNULL(ins.GeneralNumerator, 1) AS GeneralNumerator,
        ISNULL(ins.GeneralDenominator, 1) AS GeneralDenominator,
        ISNULL(ins.MarketLot, 1) AS MarketLot,
        COALESCE(instType.InstrumentType,'') AS InstrumentType,
        ins.Code,
        COALESCE(ins.ScripId,'') AS ScripId,
        COALESCE(CONVERT(VARCHAR,ins.ExpiryDate,106),'') AS ExpiryDate,
        COALESCE(ins.PutCall,'') AS PutCall
    INTO #instruments
    FROM #tmpInstruments tmpInst
        INNER JOIN dbo.RefInstrument ins ON ins.RefInstrumentId=tmpInst.RefInstrumentId
        INNER JOIN dbo.RefInstrumentType instType ON ins.RefInstrumentTypeId = instType.RefInstrumentTypeId

DROP TABLE #tmpInstruments

 SELECT DISTINCT
        maintrade.CoreTradeId,
        maintrade.RefClientId,
        maintrade.RefInstrumentId,
        inst.RefInstrumentTypeId,
        maintrade.TradeDate,
        maintrade.TradeDateTime,
        maintrade.TradeId,
        maintrade.IsBuy,
        maintrade.Rate,
        maintrade.Quantity,
        CASE  
     WHEN  inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND inst.Code ='JPYINR'
      THEN ROUND((maintrade.Rate)* (maintrade.Quantity * 1000),2)
     
WHEN  inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR)
     THEN ROUND((maintrade.Rate)* (maintrade.Quantity * inst.ContractSize),2)
	 
     ELSE  
      maintrade.Rate * maintrade.Quantity  
     END  
    AS SyncTurnover,
        maintrade.OppRefClientId OppClientId,
        ABS( maintrade.IsBuy - 1) AS OppIsBuy,
        maintrade.BuyCtslId,
        maintrade.SellCtslId,
        maintrade.BuyTerminal,
        maintrade.SellTerminal,
        maintrade.BuyOrdTime,
        maintrade.SellOrdTime,
        maintrade.RefSegmentId,
        maintrade.IsAlgoTrade
    INTO #SyncTradesTemp
    FROM #FilteredTrade maintrade
        
        INNER JOIN #instruments inst ON inst.RefInstrumentId = maintrade.RefInstrumentId

		-----
    SELECT st.RefClientId,
        st.RefInstrumentTypeId,
        st.TradeDate, st.RefInstrumentId ,
        CONVERT(DECIMAL(28,3),SUM (st.SyncTurnover)) AS DateWiseSyncTurnover
    INTO #SyncTurnoverDateWise
    FROM #SyncTradesTemp st
    GROUP BY st.RefClientId, st.RefInstrumentTypeId, st.TradeDate, st.RefInstrumentId

    SELECT linkInstrumentType.RefInstrumentTypeId ,
        CONVERT(DECIMAL(28,3),scenarioRule.Threshold) AS Threshold,
        CONVERT (INT,scenarioRule.Threshold2) AS Threshold2,
		ISNULL(Threshold3,0) AS Threshold3
    INTO #scenarioRules
    FROM dbo.RefAmlScenarioRule scenarioRule
    INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType linkInstrumentType ON scenarioRule.RefAmlScenarioRuleId = linkInstrumentType.RefAmlScenarioRuleId
    WHERE scenarioRule.RefAmlReportId = @RefAmlReportIdInternal


    SELECT t.RefClientId,
        t.RefInstrumentId,
        t.RefInstrumentTypeId,
        t.ClientSyncTurnover	
    INTO #FinalClientId
    FROM(
		SELECT stdw.RefClientId,
            stdw.RefInstrumentTypeId,
            stdw.RefInstrumentId,
            SUM(stdw.DateWiseSyncTurnover) AS ClientSyncTurnover
        FROM #SyncTurnoverDateWise stdw
            INNER JOIN dbo.RefInstrumentType instrumentType ON instrumentType.RefInstrumentTypeId = stdw.RefInstrumentTypeId
        GROUP BY stdw.RefClientId,stdw.RefInstrumentTypeId ,stdw.RefInstrumentId )t
        INNER JOIN #scenarioRules rules ON t.RefInstrumentTypeId = rules.RefInstrumentTypeId AND t.ClientSyncTurnover >= rules.Threshold 
 


    SELECT trade.RefClientId,
        trade.RefInstrumentId,
        SUM(CASE WHEN trade.IsBuy = 1 THEN  
      (  
       CASE
	   WHEN  inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND inst.Code = 'JPYINR'
         THEN ROUND((trade.Rate)* (trade.Quantity * 1000),2)

        WHEN  inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR)
        THEN ROUND((trade.Rate)* (trade.Quantity * inst.ContractSize),2)
         
        ELSE  
         trade.Rate * trade.Quantity  
        END  
        )  
        ELSE 0 END) AS BuyTurnover,
        SUM(CASE WHEN trade.IsBuy = 0 THEN  
      (  
       CASE  
        WHEN  inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND inst.Code = 'JPYINR'
        THEN ROUND((trade.Rate)* (trade.Quantity * 1000),2)

        WHEN  inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR)
        THEN ROUND((trade.Rate)* (trade.Quantity * inst.ContractSize),2)

        ELSE  
         trade.Rate * trade.Quantity  
        END  
      )  
     ELSE 0 END) AS SellTurnover
    INTO #CliInstrumentWiseTurnover
    FROM #FinalClientId fc
        INNER JOIN #FilteredTrade trade ON fc.RefClientId = trade.RefClientId AND fc.RefInstrumentId=trade.RefInstrumentId
        INNER JOIN #instruments inst ON trade.RefInstrumentId = inst.RefInstrumentId
    GROUP BY trade.RefClientId, trade.RefInstrumentId

	DROP TABLE #FilteredTrade

    SELECT client.RefClientId,
        client.ClientId,
        client.[Name],
	client.RefClientStatusId,
	client.RefIntermediaryId
    INTO #finalClientDet
    FROM #distinctClient tmpcl
        INNER JOIN dbo.RefClient client ON tmpcl.RefClientId = client.RefClientId


	DROP TABLE #distinctClient

	SELECT DISTINCT  
        RefClientId  
    INTO #clientsToExclude  
    FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex  
    WHERE (ex.RefAmlReportId = @RefAmlReportIdInternal OR ex.ExcludeAllScenarios = 1)  
        AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)  

    IF OBJECT_ID('tempdb..#SynchronizedTrades') IS NULL
	BEGIN

        CREATE TABLE #SynchronizedTrades
        (
            RefclientId INT,
            TradeDate DATETIME,
            TradeDateTime DATETIME,
            TradeId INT,
            IsBuy BIT,
            Rate DECIMAL(28,3),
            Quantity DECIMAL(28,2),
            SyncTurnover DECIMAL(28,2),
            DateWiseSyncTurnover DECIMAL(28,2),
            ClientSyncTurnover DECIMAL(28,2),
            OppRefClientId INT,
            OppIsBuy BIT,
            ClientBuyTurnover DECIMAL(28,2),
            ClientSellTurnover DECIMAL(28,2),
            OppClientBuyTurnover DECIMAL(28,2),
            OppClientSellTurnover DECIMAL(28,2),
            BuyCtslId VARCHAR(300) COLLATE DATABASE_DEFAULT,
            SellCtslId VARCHAR(300) COLLATE DATABASE_DEFAULT,
            BuyTerminal VARCHAR(200) COLLATE DATABASE_DEFAULT,
            SellTerminal VARCHAR(200) COLLATE DATABASE_DEFAULT,
            RefSegmentId INT,
            BuyOrdTime DATETIME,
            SellOrdTime DATETIME,
            RefInstrumentId INT,
            IsAlgoTrade BIT,
			DifferenceInSeconds INT,
            RefInstrumentTypeId INT
        )

    END
    INSERT INTO #SynchronizedTrades
        (
        RefclientId ,
        TradeDate ,
        TradeDateTime ,
        TradeId ,
        IsBuy ,
        Rate ,
        Quantity ,
        SyncTurnover ,
        DateWiseSyncTurnover ,
        ClientSyncTurnover ,
        OppRefClientId ,
        OppIsBuy ,
        ClientBuyTurnover ,
        ClientSellTurnover ,
        OppClientBuyTurnover ,
        OppClientSellTurnover ,
        BuyCtslId ,
        SellCtslId ,
        BuyTerminal ,
        SellTerminal ,
        RefSegmentId ,
        BuyOrdTime ,
        SellOrdTime ,
        RefInstrumentId ,
        IsAlgoTrade ,
		DifferenceInSeconds,
        RefInstrumentTypeId
        )

    SELECT
        fc.RefclientId ,
        st.TradeDate ,
        st.TradeDateTime ,
        st.TradeId ,
        st.IsBuy ,
        st.Rate ,
        st.Quantity ,
        st.SyncTurnover ,
        stdw.DateWiseSyncTurnover ,
        fc.ClientSyncTurnover ,
        st.OppClientId AS OppRefClientId,
        st.OppIsBuy ,
        CONVERT(DECIMAL(28,2),cliInstWiseTurnover.BuyTurnover)AS ClientBuyTurnover,
        CONVERT(DECIMAL(28,2),cliInstWiseTurnover.SellTurnover)AS ClientSellTurnover,
        CONVERT(DECIMAL(28,2),oppCliInstWiseTurnover.BuyTurnover)AS OppClientBuyTurnover,
        CONVERT(DECIMAL(28,2),oppCliInstWiseTurnover.SellTurnover)AS OppClientSellTurnover,
        st.BuyCtslId,
        st.SellCtslId,
        BuyTerminal ,
        SellTerminal ,
        RefSegmentId ,
        st.BuyOrdTime ,
        st.SellOrdTime ,
        st.RefInstrumentId ,
        st.IsAlgoTrade ,ABS((DATEPART(SECOND, ISNULL(st.BuyOrdTime,GETDATE())) + 60 * DATEPART(MINUTE,ISNULL(st.BuyOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(st.BuyOrdTime,getdate())))-(DATEPART(SECOND, isnull(st.SellOrdTime,getdate())) +60 * DATEPART(MINUTE, isnull(
st.SellOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(st.SellOrdTime,getdate())))) as DifferenceInSeconds,
        inst.RefInstrumentTypeId
    FROM #FinalClientId fc
        INNER JOIN #SyncTradesTemp st ON fc.RefClientId = st.RefClientId AND fc.RefInstrumentTypeId = st.RefInstrumentTypeId and fc.RefInstrumentId=st.RefInstrumentId
        INNER JOIN #SyncTurnoverDateWise stdw ON fc.RefClientId = stdw.RefClientId AND fc.RefInstrumentTypeId = stdw.RefInstrumentTypeId AND stdw.TradeDate = st.TradeDate and stdw.RefInstrumentId=st.RefInstrumentId
        INNER JOIN #CliInstrumentWiseTurnover cliInstWiseTurnover ON st.RefClientId = cliInstWiseTurnover.RefClientId
            AND st.RefInstrumentId = cliInstWiseTurnover.RefInstrumentId
        INNER JOIN #CliInstrumentWiseTurnover oppCliInstWiseTurnover ON st.OppClientId = oppCliInstWiseTurnover.RefClientId
            AND st.RefInstrumentId = oppCliInstWiseTurnover.RefInstrumentId
        INNER JOIN #instruments inst ON st.RefInstrumentId = inst.RefInstrumentId


		SELECT * FROM
  (
  SELECT
            syncTrnovr.RefClientId,
            clientDet.ClientId,
            clientDet.[Name] AS ClientName,
            inst.Code AS ScripCode,
            inst.InstrumentType,
            (inst.ScripId +' - '+ inst.InstrumentType +' - '+ inst.ExpiryDate +' - '+ inst.PutCall +' - '+ COALESCE(CONVERT(VARCHAR,CONVERT (DECIMAL(19,2),inst.StrikePrice)),'')) AS ScripTypeExpDtPutCallStrikePrice,
            syncTrnovr.TradeDate,
            syncTrnovr.TradeDateTime,
            syncTrnovr.TradeId,
            CASE WHEN syncTrnovr.IsBuy  = 1 THEN 'Buy' ELSE 'Sell' END AS BuySell,
            syncTrnovr.Rate,
            syncTrnovr.Quantity,
            syncTrnovr.SyncTurnover,
            syncTrnovr.ClientSyncTurnover AS ClientSyncTODay,
            syncTrnovr.OppRefClientId,
            oppClientDet.ClientId AS OppClientId,
            oppClientDet.[Name] AS OppClientName,
            CASE WHEN syncTrnovr.OppIsBuy  = 1 THEN 'Buy' ELSE 'Sell' END AS OppBuySell,
            syncTrnovr.ClientBuyTurnover,
            syncTrnovr.ClientSellTurnover,
            syncTrnovr.BuyCtslId,
            syncTrnovr.SellCtslId,
            seg.Segment,
            syncTrnovr.BuyOrdTime,
            syncTrnovr.SellOrdTime,
            bhavCopy.NetTurnOver AS ExchangeTurnover,
            bhavCopy.[High] AS DayHigh,
            bhavCopy.[Low] AS DayLow,
            inst.RefInstrumentId,
            CASE WHEN syncTrnovr.IsAlgoTrade =1 then 'YES' else 'NO' end as AlgoTrade  ,
            DifferenceInSeconds,
			rules.Threshold3,
			syncTrnovr.RefSegmentId,
			CASE WHEN syncTrnovr.RefInstrumentTypeId IN (@OPTCUR, @OPTSTK , @OPTIDX , @OPTIRC )THEN bhavCopy.PreviousClose ELSE NULL END AS PreviousDayFutureClose,
			CASE WHEN syncTrnovr.RefInstrumentTypeId IN (@OPTCUR, @OPTSTK , @OPTIDX , @OPTIRC )
			THEN 
				CASE WHEN ISNULL (bhavCopy.PreviousClose, 0) = 0		
				THEN NULL 
				ELSE (ABS(inst.StrikePrice-bhavCopy.PreviousClose)*100/bhavCopy.PreviousClose)
				END
			ELSE
				NULL
			END AS PercentOfStrikePriceAway
        FROM #SynchronizedTrades syncTrnovr
			INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId =  syncTrnovr.RefInstrumentTypeId AND syncTrnovr.DifferenceInSeconds <= rules.Threshold2
            INNER JOIN #finalClientDet clientDet ON clientDet.RefClientId=syncTrnovr.RefClientId
            INNER JOIN #finalClientDet oppClientDet ON oppClientDet.RefClientId=syncTrnovr.OppRefClientId
            INNER JOIN #instruments inst ON syncTrnovr.RefInstrumentId = inst.RefInstrumentId
            INNER JOIN dbo.RefSegmentEnum seg ON syncTrnovr.RefSegmentId = seg.RefSegmentEnumId
            LEFT JOIN dbo.CoreBhavCopy bhavCopy ON syncTrnovr.RefSegmentId = bhavCopy.RefSegmentId AND syncTrnovr.TradeDate = bhavCopy.[Date] AND syncTrnovr.RefInstrumentId = bhavCopy.RefInstrumentId
		LEFT JOIN #clientsToExclude clex ON clex.RefClientId =clientDet.RefClientId
		WHERE clex.RefClientId IS NULL 
		AND (@ExcludePro = 0 OR clientDet.RefClientStatusId <> @ProRefClientStatusId)
		AND (@ExcludeInstitution = 0 OR clientDet.RefClientStatusId <> @InstitutionRefClientStatusId)
		AND (@ExcludeOppositeInstitution = 0 OR oppClientDet.RefClientStatusId <> @InstitutionRefClientStatusId)
		AND (@ExcludeOppositePro = 0 OR oppClientDet.RefClientStatusId <> @ProRefClientStatusId)
		) tout
		WHERE ( Threshold3 = 0 OR  tout.PercentOfStrikePriceAway >= Threshold3)
		ORDER BY TradeId
	END
GO