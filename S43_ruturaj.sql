	DECLARE @RunDate DATETIME = '05-24-2022'

	DECLARE @RefAmlReportId INT, @RunDateInternal DATETIME, @ExcludePro BIT, @ExcludeInstitution BIT, 
			@ExcludeOppositePro BIT, @ExcludeOppositeInstitution BIT,@ExcludealgoTrade BIT,@OPTCUR INT,
			@FUTCUR INT,@OPTSTK INT,@OPTIDX INT,@OPTIRC INT,@OPTFUT INT,@FUTCOM INT,@ProRefClientStatusId INT,
			@InstitutionRefClientStatusId INT,@NCDEX_FNO INT,@NSE_FNO INT,@NSE_CDX INT,@MCXSX_CDX INT

	SELECT @RefAmlReportId = RefAmlReportId
    FROM dbo.RefAmlReport
    WHERE [Name] = 'S43 Synchronized Trading 1 Day FnO'
    
	SET @RunDateInternal = @RunDate

    SELECT @ExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportId AND [Name] = 'Exclude_Pro'

    SELECT @ExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportId AND [Name] = 'Exclude_Institution'

    SELECT @ExcludeOppositePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportId AND [Name] = 'Exclude_OppositePro'

    SELECT @ExcludeOppositeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportId AND [name] = 'Exclude_OppositeInstitution'

    SELECT @ExcludealgoTrade = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
    FROM dbo.SysAmlReportSetting
    WHERE RefAmlReportId = @RefAmlReportId AND [Name] = 'Exclude_AlgoTrade'

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

	SELECT @OPTFUT = RefInstrumentTypeId 
	FROM dbo.RefInstrumentType 
	WHERE InstrumentType = 'OPTFUT'

	SELECT @FUTCOM = RefInstrumentTypeId 
	FROM dbo.RefInstrumentType 
	WHERE InstrumentType = 'FUTCOM'

    SET @InstitutionRefClientStatusId = dbo.GetClientStatusId('Institution')
    
	SET @ProRefClientStatusId = dbo.GetClientStatusId('Pro')

    SELECT @NCDEX_FNO = RefSegmentEnumId
    FROM dbo.RefSegmentEnum
    WHERE CODE = 'NCDEX_FNO'
    
	SELECT @NSE_FNO = RefSegmentEnumId
    FROM dbo.RefSegmentEnum
    WHERE CODE = 'NSE_FNO'
    
	SELECT @NSE_CDX = RefSegmentEnumId
    FROM dbo.RefSegmentEnum
    WHERE CODE = 'NSE_CDX'
    
	SELECT @MCXSX_CDX = RefSegmentEnumId
    FROM dbo.RefSegmentEnum
    WHERE CODE = 'MCXSX_CDX'

    SELECT DISTINCT
        CoreTradeId,
        RefClientId,
        RefInstrumentId,
        TradeDate,
        TradeDateTime,
        TradeId,
        CASE WHEN BuySell = 'Buy' THEN 1  WHEN BuySell = 'Sell' THEN 0 ELSE 0 END AS IsBuy,
        Rate,
        Quantity,
        CtclId,
        RefSegmentId,
        RefSettlementId,
        TraderId,
        OrderTimeStamp,
        TradeIdAlphaNumeric
    INTO #reqTrades
    FROM dbo.CoreTrade tr
    WHERE tr.TradeDate = @RunDateInternal

    SELECT 
		trade.CoreTradeId,
        trade.RefClientId,
        trade.RefInstrumentId,
        trade.TradeDate,
        trade.TradeDateTime,
        trade.TradeId,
        trade.IsBuy ,
        trade.Rate,
        trade.Quantity,
        trade.CtclId,
        trade.RefSegmentId,
        trade.RefSettlementId,
        trade.TraderId,
        trade.OrderTimeStamp,
        CASE WHEN SUBSTRING(CONVERT(VARCHAR,trade.CtclId),13,1) IN ('0','2','4') THEN 1 ELSE 0 END AS IsAlgoTrade ,
        trade.TradeIdAlphaNumeric,
        CONVERT(VARCHAR(50),trade.TraderId) AS UserId
    INTO #FilteredTrade
    FROM #reqTrades trade
    WHERE  trade.RefSegmentId IN (@NSE_FNO, @NSE_CDX, @MCXSX_CDX) AND
        (  
			@ExcludealgoTrade = 0
			OR
			(
				@ExcludealgoTrade = 1 
				AND
				( 
					LEN(CONVERT(VARCHAR, trade.CtclId))=15
					AND
					SUBSTRING(CONVERT(VARCHAR, trade.CtclId),13,1) NOT IN ('0','2','4')
				)
			)
		)

    SELECT DISTINCT 
		fltr.RefClientId
    INTO #distinctClient
    FROM #FilteredTrade  fltr

	SELECT DISTINCT  
        RefClientId  
    INTO #clientsToExclude  
    FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex  
    WHERE (ex.RefAmlReportId = @RefAmlReportId OR ex.ExcludeAllScenarios = 1)  
        AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)  

    SELECT 
		client.RefClientId,
        client.RefIntermediaryId
    INTO #FilteredClient
    FROM #distinctClient tmpcl
		INNER JOIN dbo.RefClient client ON tmpcl.RefClientId = client.RefClientId
		LEFT JOIN #clientsToExclude clex ON clex.RefClientId =client.RefClientId
		WHERE clex.RefClientId IS NULL
			AND (@ExcludePro = 0 OR client.RefClientStatusId <> @ProRefClientStatusId)
			AND (@ExcludeInstitution = 0 OR client.RefClientStatusId <> @InstitutionRefClientStatusId)
	
	--drop TABLE #clientsToExclude

    SELECT 
		client.RefClientId
    INTO #FilteredOppositeClient
    FROM #distinctClient tmpcl
        INNER JOIN dbo.RefClient client ON tmpcl.RefClientId=client.RefClientId
            AND (@ExcludePro = 0 OR client.RefClientStatusId <> @ProRefClientStatusId)
            AND (@ExcludeInstitution = 0 OR client.RefClientStatusId <> @InstitutionRefClientStatusId)


    SELECT DISTINCT RefInstrumentId
    INTO #tmpInstruments
    FROM #reqTrades

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
	
	--drop TABLE #tmpInstruments

    SELECT
        client.RefClientId,
        trade.RefSegmentId,
        trade.RefSettlementId,
        trade.RefInstrumentId,
        TradeIdAlphaNumeric,
        IsBuy,
        Quantity,
        Rate,
        TradeDateTime,
        TradeId,
        CoreTradeId,
        TradeDate,
        CtclId,
        OrderTimeStamp,
        IsAlgoTrade,
        TraderId,
        UserId
    INTO #mainTradeDetails
    FROM #FilteredClient client
        INNER JOIN #FilteredTrade trade ON client.RefClientId = trade.RefClientId

	

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
     WHEN  inst.RefInstrumentTypeId IN (@OPTCUR) AND inst.Code ='JPYINR'
      THEN ROUND((maintrade.Rate + inst.StrikePrice)* (maintrade.Quantity * 1000),2) 
     
	 WHEN  inst.RefInstrumentTypeId IN (@OPTCUR)
      THEN ROUND((maintrade.Rate + inst.StrikePrice)* (maintrade.Quantity * inst.ContractSize),2) 
	 
	 WHEN  inst.RefInstrumentTypeId IN (@FUTCUR) AND inst.Code ='JPYINR'
      THEN ROUND(maintrade.Rate * maintrade.Quantity * 1000,2)   
     
	 WHEN  inst.RefInstrumentTypeId IN (@FUTCUR) 
      THEN ROUND(maintrade.Rate * maintrade.Quantity * inst.ContractSize,2)  

     WHEN inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)  
      THEN (inst.StrikePrice + maintrade.Rate) * maintrade.Quantity    

     WHEN  inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
      THEN  ROUND(maintrade.Rate * (inst.PriceNumerator/inst.PriceDenominator * maintrade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)   
       
     ELSE   
      maintrade.Rate * maintrade.Quantity   
     END   
    AS SyncTurnover,
        oppTrade.RefClientId AS OppClientId,
        oppTrade.IsBuy AS OppIsBuy,
        CASE WHEN maintrade.IsBuy = 1 THEN maintrade.CtclId ELSE oppTrade.CtclId END AS BuyCtslId,
        CASE WHEN maintrade.IsBuy = 0 THEN maintrade.CtclId ELSE oppTrade.CtclId END AS SellCtslId,
        CASE WHEN maintrade.IsBuy = 1 THEN ct.TerminalId ELSE oppCt.TerminalId END AS BuyTerminal,
        CASE WHEN maintrade.IsBuy = 0 THEN ct.TerminalId ELSE oppCt.TerminalId END AS SellTerminal,
        CASE WHEN maintrade.IsBuy = 1 THEN maintrade.OrderTimeStamp ELSE oppTrade.OrderTimeStamp END AS BuyOrdTime,
        CASE WHEN maintrade.IsBuy = 0 THEN maintrade.OrderTimeStamp ELSE oppTrade.OrderTimeStamp END AS SellOrdTime,
        maintrade.RefSegmentId,
        maintrade.IsAlgoTrade
    INTO #SyncTradesTemp
    FROM #mainTradeDetails maintrade
        INNER JOIN #FilteredTrade oppTrade ON maintrade.RefSegmentId = oppTrade.RefSegmentId
            AND maintrade.RefSettlementId = oppTrade.RefSettlementId
            AND maintrade.RefInstrumentId = oppTrade.RefInstrumentId
            AND maintrade.Quantity = oppTrade.Quantity
            AND maintrade.Rate = oppTrade.Rate
            AND maintrade.TradeDateTime = oppTrade.TradeDateTime
            AND maintrade.IsBuy <> oppTrade.IsBuy
            AND maintrade.RefClientId <> oppTrade.RefClientId
            AND maintrade.TradeId = oppTrade.TradeId
        INNER JOIN #instruments inst ON inst.RefInstrumentId = maintrade.RefInstrumentId
        LEFT JOIN dbo.CoreTerminal ct ON ct.UserId=maintrade.UserId
        LEFT JOIN dbo.CoreTerminal oppCt ON oppCt.UserId=oppTrade.UserId

	--drop TABLE #FilteredTrade

    SELECT st.RefClientId,
        st.RefInstrumentTypeId,
        st.TradeDate, st.RefInstrumentId ,
        CONVERT(DECIMAL(28,2),SUM (st.SyncTurnover)) AS DateWiseSyncTurnover
    INTO #SyncTurnoverDateWise
    FROM #SyncTradesTemp st
    GROUP BY st.RefClientId, st.RefInstrumentTypeId, st.TradeDate, st.RefInstrumentId
	
    SELECT linkInstrumentType.RefInstrumentTypeId ,
        CONVERT(DECIMAL(28,2),scenarioRule.Threshold) AS Threshold,
        CONVERT (INT,scenarioRule.Threshold2) AS Threshold2
    INTO #scenarioRules
    FROM dbo.RefAmlScenarioRule scenarioRule
    INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType linkInstrumentType ON scenarioRule.RefAmlScenarioRuleId = linkInstrumentType.RefAmlScenarioRuleId
    WHERE scenarioRule.RefAmlReportId = @RefAmlReportId


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

    SELECT DISTINCT
        trade.CoreTradeId,
        trade.RefClientId,
        trade.RefInstrumentId,
        trade.IsBuy,
        trade.Rate,
        trade.Quantity,
        trade.RefSegmentId
    INTO #finalClientTrade
    FROM #FinalClientId fc
        INNER JOIN #reqTrades trade ON fc.RefClientId = trade.RefClientId




    SELECT trade.RefClientId,
        trade.RefInstrumentId,
        SUM(CASE WHEN trade.IsBuy = 1 THEN   
      (  
       CASE   
        WHEN  inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2) 
      
        WHEN inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN  ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)    
		
		WHEN  inst.RefInstrumentTypeId IN (@OPTCUR) AND inst.Code = 'JPYINR'
         THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * 1000),2) 

        WHEN  inst.RefInstrumentTypeId IN (@OPTCUR) 
         THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * inst.ContractSize),2) 
	   
	    WHEN  inst.RefInstrumentTypeId IN (@FUTCUR)  AND inst.Code = 'JPYINR'
		  THEN ROUND(trade.Rate * trade.Quantity * 1000,2)    

		 WHEN  inst.RefInstrumentTypeId IN (@FUTCUR)  
		  THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)            
  
		 WHEN inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC) 
		  THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  

        WHEN  inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)  
       
        ELSE   
         trade.Rate * trade.Quantity   
        END   
        )   
        ELSE 0 END) AS BuyTurnover,
        SUM(CASE WHEN trade.IsBuy = 0 THEN  
      (  
       CASE   
        WHEN inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2)
      
        WHEN  inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN  ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)      
  
       
		 WHEN  inst.RefInstrumentTypeId IN (@OPTCUR) AND inst.Code = 'JPYINR'
         THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * 1000),2) 

        WHEN  inst.RefInstrumentTypeId IN (@OPTCUR) 
         THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * inst.ContractSize),2) 
	   
	    WHEN  inst.RefInstrumentTypeId IN (@FUTCUR)  AND inst.Code = 'JPYINR'
		  THEN ROUND(trade.Rate * trade.Quantity * 1000,2) 
	   
		 WHEN  inst.RefInstrumentTypeId IN (@FUTCUR) 
		  THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)            
  
        
		 WHEN  inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)
		  THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  

        WHEN  inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2) 
       
        ELSE   
         trade.Rate * trade.Quantity   
        END   
      )  
     ELSE 0 END) AS SellTurnover
    INTO #CliInstrumentWiseTurnover
    FROM #FinalClientId fc
        INNER JOIN #finalClientTrade trade ON fc.RefClientId = trade.RefClientId AND fc.RefInstrumentId=trade.RefInstrumentId
        INNER JOIN #instruments inst ON trade.RefInstrumentId = inst.RefInstrumentId
        INNER JOIN dbo.RefSegmentEnum segment ON trade.RefSegmentId = segment.RefSegmentEnumId
    GROUP BY trade.RefClientId, trade.RefInstrumentId


    SELECT DISTINCT st.OppClientId
    INTO #OppClients
    FROM #FinalClientId fc
        INNER JOIN #SyncTradesTemp st ON fc.RefClientId = st.RefClientId


    SELECT DISTINCT
        trade.CoreTradeId,
        trade.RefClientId,
        trade.RefInstrumentId,
        trade.IsBuy,
        trade.Rate,
        trade.Quantity,
        trade.RefSegmentId
    INTO #OppClientTrade
    FROM #OppClients oppCl
        INNER JOIN #reqTrades trade ON oppCl.OppClientId = trade.RefClientId
	
	--drop TABLE #reqTrades

    SELECT trade.RefClientId,
        trade.RefInstrumentId,
        SUM(CASE WHEN trade.IsBuy = 1 THEN   
      (  
       CASE   
        WHEN inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2)  
      
        WHEN  inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)       
  
		  WHEN  inst.RefInstrumentTypeId IN (@OPTCUR) AND inst.Code = 'JPYINR'
         THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * 1000),2) 

        WHEN  inst.RefInstrumentTypeId IN (@OPTCUR) 
         THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * inst.ContractSize),2) 
	   
	    WHEN  inst.RefInstrumentTypeId IN (@FUTCUR)  AND inst.Code = 'JPYINR'
		  THEN ROUND(trade.Rate * trade.Quantity * 1000,2) 
		 WHEN  inst.RefInstrumentTypeId IN (@FUTCUR)  
		  THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)            
  
		 WHEN   inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC)   
		  THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  

        WHEN  inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)  
       
        ELSE   
         trade.Rate * trade.Quantity   
        END   
      )   
     ELSE 0 END) AS BuyTurnover,
        SUM(CASE WHEN trade.IsBuy = 0 THEN   
      (  
       CASE   
        WHEN  inst.RefInstrumentTypeId IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN ROUND((trade.Rate + inst.StrikePrice) * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) * (inst.GeneralNumerator / inst.GeneralDenominator), 2) 
      
        WHEN  inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR) AND segment.RefSegmentEnumId = @NCDEX_FNO  
         THEN  ROUND(trade.Rate * (inst.PriceNumerator / inst.PriceDenominator * trade.Quantity) *(inst.GeneralNumerator / inst.GeneralDenominator), 2)       
  
		  WHEN  inst.RefInstrumentTypeId IN (@OPTCUR) AND inst.Code = 'JPYINR'
         THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * 1000),2) 

        WHEN  inst.RefInstrumentTypeId IN (@OPTCUR) 
         THEN ROUND((trade.Rate + inst.StrikePrice)* (trade.Quantity * inst.ContractSize),2) 
	   
	    WHEN  inst.RefInstrumentTypeId IN (@FUTCUR)  AND inst.Code = 'JPYINR'
		  THEN ROUND(trade.Rate * trade.Quantity * 1000,2) 

		 WHEN  inst.RefInstrumentTypeId IN (@FUTCUR)
		  THEN ROUND(trade.Rate * trade.Quantity * inst.ContractSize,2)            
  
		 WHEN  inst.RefInstrumentTypeId IN (@OPTSTK,@OPTIDX,@OPTIRC) 
		  THEN (inst.StrikePrice + trade.Rate) * trade.Quantity  

        WHEN  inst.RefInstrumentTypeId NOT IN (@OPTCUR,@FUTCUR,@OPTSTK,@OPTIDX,@OPTIRC)   
         THEN  ROUND(trade.Rate * (inst.PriceNumerator /inst.PriceDenominator * trade.Quantity) * inst.MarketLot * (inst.GeneralNumerator / inst.GeneralDenominator),2)   
       
        ELSE   
         trade.Rate * trade.Quantity   
        END   
      )   
     ELSE 0 END) AS SellTurnover
    INTO #OppCliInstrumentWiseTurnover
    FROM #OppClients FinalOppClients
        INNER JOIN #OppClientTrade trade ON FinalOppClients.OppClientId = trade.RefClientId
        INNER JOIN #instruments inst ON trade.RefInstrumentId = inst.RefInstrumentId
        INNER JOIN dbo.RefSegmentEnum segment ON segment.RefSegmentEnumId = trade.RefSegmentId
    GROUP BY trade.RefClientId, trade.RefInstrumentId

    SELECT client.RefClientId,
        client.ClientId,
        client.[Name]
    INTO #finalClientDet
    FROM #distinctClient tmpcl
        INNER JOIN dbo.RefClient client ON tmpcl.RefClientId = client.RefClientId
	
	--drop TABLE #distinctClient
	--drop TABLE #OppClients
	--drop TABLE #OppClientTrade

    IF OBJECT_ID('tempdb..#SynchronizedTrades') IS NULL 
	BEGIN

        CREATE TABLE #SynchronizedTrades
        (
            RefclientId INT,
            TradeDate DATETIME,
            TradeDateTime DATETIME,
            TradeId INT,
            IsBuy BIT,
            Rate DECIMAL(28,2),
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
        st.OppClientId ,
        st.OppIsBuy ,
        CONVERT(DECIMAL(28,2),cliInstWiseTurnover.BuyTurnover),
        CONVERT(DECIMAL(28,2),cliInstWiseTurnover.SellTurnover),
        CONVERT(DECIMAL(28,2),oppCliInstWiseTurnover.BuyTurnover) ,
        CONVERT(DECIMAL(28,2),oppCliInstWiseTurnover.SellTurnover),
        st.BuyCtslId,
        st.SellCtslId,
        BuyTerminal ,
        SellTerminal ,
        RefSegmentId ,
        st.BuyOrdTime ,
        st.SellOrdTime ,
        st.RefInstrumentId ,
        st.IsAlgoTrade ,
        inst.RefInstrumentTypeId
    FROM #FinalClientId fc
        INNER JOIN #SyncTradesTemp st ON fc.RefClientId = st.RefClientId AND fc.RefInstrumentTypeId = st.RefInstrumentTypeId and fc.RefInstrumentId=st.RefInstrumentId
        INNER JOIN #SyncTurnoverDateWise stdw ON fc.RefClientId = stdw.RefClientId AND fc.RefInstrumentTypeId = stdw.RefInstrumentTypeId AND stdw.TradeDate = st.TradeDate and stdw.RefInstrumentId=st.RefInstrumentId
        INNER JOIN #CliInstrumentWiseTurnover cliInstWiseTurnover ON st.RefClientId = cliInstWiseTurnover.RefClientId
            AND st.RefInstrumentId = cliInstWiseTurnover.RefInstrumentId
        INNER JOIN #OppCliInstrumentWiseTurnover oppCliInstWiseTurnover ON st.OppClientId = oppCliInstWiseTurnover.RefClientId
            AND st.RefInstrumentId = oppCliInstWiseTurnover.RefInstrumentId
        INNER JOIN #instruments inst ON st.RefInstrumentId = inst.RefInstrumentId

    SELECT *
    FROM(  
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
            CASE WHEN syncTrnovr.IsBuy  = 1THEN 'Buy' ELSE 'Sell' END AS BuySell,
            syncTrnovr.Rate,
            syncTrnovr.Quantity,
            syncTrnovr.SyncTurnover,
            syncTrnovr.DateWiseSyncTurnover,
            syncTrnovr.ClientSyncTurnover,
            oppClient.RefClientId AS OppRefClientId,
            oppClientDet.ClientId AS OppClientId,
            oppClientDet.[Name] AS OppClientName,
            CASE WHEN syncTrnovr.OppIsBuy  = 1 THEN 'Buy' ELSE 'Sell' END AS OppBuySell,
            syncTrnovr.ClientBuyTurnover,
            syncTrnovr.ClientSellTurnover,
            syncTrnovr.OppClientBuyTurnover,
            syncTrnovr.OppClientSellTurnover,
            syncTrnovr.BuyCtslId,
            syncTrnovr.SellCtslId,
            syncTrnovr.BuyTerminal,
            syncTrnovr.SellTerminal,
            seg.Segment,
            syncTrnovr.BuyOrdTime,
            syncTrnovr.SellOrdTime,
            bhavCopy.NetTurnOver AS ExchangeTurnover,
            bhavCopy.[High] AS DayHigh,
            bhavCopy.[Low] AS DayLow,
            inst.RefInstrumentId,
            rf.IntermediaryCode,
            rf.[Name] AS IntermediaryName,
            CASE WHEN syncTrnovr.IsAlgoTrade =1 then 'YES' else 'NO' end as AlgoTrade  ,
            inst.RefInstrumentTypeId,
            ABS((DATEPART(SECOND, ISNULL(syncTrnovr.BuyOrdTime,GETDATE())) + 60 * DATEPART(MINUTE,ISNULL(syncTrnovr.BuyOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(syncTrnovr.BuyOrdTime,getdate())))-(DATEPART(SECOND, isnull(syncTrnovr.SellOrdTime,getdate())) +60 * DATEPART(MINUTE, isnull(
			syncTrnovr.SellOrdTime,getdate())) +3600 * DATEPART(HOUR, isnull(syncTrnovr.SellOrdTime,getdate())))) as DifferenceInSeconds,
            rf.TradeName

        FROM #SynchronizedTrades syncTrnovr
            INNER JOIN #FilteredClient client ON syncTrnovr.RefClientId = client.RefClientId
            INNER JOIN #finalClientDet clientDet ON clientDet.RefClientId=syncTrnovr.RefClientId
            INNER JOIN #FilteredOppositeClient oppClient ON syncTrnovr.OppRefClientId = oppClient.RefClientId
            INNER JOIN #finalClientDet oppClientDet ON oppClientDet.RefClientId=oppClient.RefClientId
            INNER JOIN #instruments inst ON syncTrnovr.RefInstrumentId = inst.RefInstrumentId
            INNER JOIN dbo.RefSegmentEnum seg ON syncTrnovr.RefSegmentId = seg.RefSegmentEnumId
            LEFT JOIN dbo.CoreBhavCopy bhavCopy ON syncTrnovr.RefSegmentId = bhavCopy.RefSegmentId AND syncTrnovr.TradeDate = bhavCopy.Date AND syncTrnovr.RefInstrumentId = bhavCopy.RefInstrumentId
            LEFT JOIN dbo.RefIntermediary rf ON client.RefIntermediaryId = rf.RefIntermediaryId   
			)AS temp
        INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId =  temp.RefInstrumentTypeId AND temp.DifferenceInSeconds <= rules.Threshold2
