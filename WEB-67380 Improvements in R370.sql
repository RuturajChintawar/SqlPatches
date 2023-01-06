--WEB-67380-START
GO
 ALTER PROCEDURE dbo.AML_GetHighTurnoverTradesFNO    
(    
 @TradeDate DATETIME,    
 @ReportType INT  
)    
AS    
BEGIN    
  DECLARE @NSEFNOSegmentId INT    
  DECLARE @NSECDXSegmentId INT     
  DECLARE @MCXSXCDXSegmentId INT      
  DECLARE @TradeDateInternal DATETIME    
  DECLARE @ReportTypeInternal INT    
    
  DECLARE @OPTSTK INT    
  DECLARE @OPTIDX INT    
  DECLARE @OPTCUR INT    
        DECLARE @OPTIRC INT    
        DECLARE @FUTIDX INT    
        DECLARE @FUTSTK INT    
        DECLARE @FUTIRD INT    
        DECLARE @FUTIRT INT    
        DECLARE @FUTCUR INT    
        DECLARE @FUTIRC INT    
        DECLARE @FUTIRF INT    
    
        SELECT @OPTSTK = RefInstrumentTypeId    
        FROM dbo.RefInstrumentType    
        WHERE InstrumentType = 'OPTSTK'    
            
        SELECT @OPTIDX = RefInstrumentTypeId    
        FROM dbo.RefInstrumentType    
        WHERE InstrumentType = 'OPTIDX'    
    
        SELECT @OPTCUR = RefInstrumentTypeId    
        FROM dbo.RefInstrumentType    
        WHERE InstrumentType = 'OPTCUR'    
    
        SELECT @OPTIRC = RefInstrumentTypeId    
        FROM dbo.RefInstrumentType    
        WHERE InstrumentType = 'OPTIRC'    
            
        SELECT @FUTIDX = RefInstrumentTypeId    
        FROM dbo.RefInstrumentType    
        WHERE InstrumentType = 'FUTIDX'    
    
        SELECT @FUTSTK = RefInstrumentTypeId    
        FROM dbo.RefInstrumentType    
        WHERE InstrumentType = 'FUTSTK'    
    
        SELECT @FUTIRD = RefInstrumentTypeId    
        FROM dbo.RefInstrumentType    
        WHERE InstrumentType = 'FUTIRD'    
    
        SELECT @FUTIRT = RefInstrumentTypeId    
        FROM dbo.RefInstrumentType    
        WHERE InstrumentType = 'FUTIRT'    
    
        SELECT @FUTCUR = RefInstrumentTypeId    
        FROM dbo.RefInstrumentType    
        WHERE InstrumentType = 'FUTCUR'    
    
        SELECT @FUTIRC = RefInstrumentTypeId    
        FROM dbo.RefInstrumentType    
        WHERE InstrumentType = 'FUTIRC'    
    
        SELECT @FUTIRF = RefInstrumentTypeId    
        FROM dbo.RefInstrumentType    
        WHERE InstrumentType = 'FUTIRF'    
      
  SET @NSEFNOSegmentId = dbo.GetSegmentId('NSE_FNO')    
  SET @NSECDXSegmentId = dbo.GetSegmentId('NSE_CDX')    
  SET @MCXSXCDXSegmentId = dbo.GetSegmentId('MCXSX_CDX')    
  SET @TradeDateInternal  = @TradeDate    
  SET @ReportTypeInternal  = @ReportType    
    
  SELECT    
   RefClientId    
  INTO #clientsToExclude    
  FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
  WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportTypeInternal)    
   AND @TradeDateInternal >= FromDate     
   AND (ToDate IS NULL OR ToDate >= @TradeDateInternal)    
      
  SELECT    
   rul.Threshold,    
   rul.Threshold2,    
   rul.Threshold3,    
   rul.Threshold4,    
   instType.RefInstrumentTypeId ,  
   clientStatus.RefClientStatusId  
  INTO #scenarioRules    
  FROM dbo.RefAmlScenarioRule rul    
  INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType instType    
  ON rul.RefAmlScenarioRuleId = instType.RefAmlScenarioRuleId    
  INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus clientStatus    
  ON rul.RefAmlScenarioRuleId = clientStatus.RefAmlScenarioRuleId    
  WHERE RefAmlReportId = @ReportTypeInternal    
    
  SELECT    
   trade.RefClientId,    
   trade.TradeDate,    
            trade.RefInstrumentId,    
            instType.RefInstrumentTypeId,    
   trade.RefSegmentId,    
   CASE WHEN trade.BuySell ='Buy' THEN 1 ELSE 0 END AS BuySell,    
   CASE    
                WHEN trade.RefSegmentId IN (@NSEFNOSegmentId,@NSECDXSegmentId,@MCXSXCDXSegmentId)     
                    AND instType.RefInstrumentTypeId IN (@OPTIDX, @OPTSTK, @OPTIRC)    
                THEN SUM((ISNULL(inst.StrikePrice,0) + trade.Rate) * trade.Quantity) / SUM(trade.Quantity)    
                    
                WHEN trade.RefSegmentId IN (@NSEFNOSegmentId,@NSECDXSegmentId,@MCXSXCDXSegmentId)     
                    AND instType.RefInstrumentTypeId IN(@OPTCUR)            
                THEN CONVERT(DECIMAL(28,2),ROUND(SUM((trade.Rate + ISNULL(inst.StrikePrice,0)) * (ISNULL(inst.PriceNumerator,1) /ISNULL(inst.PriceDenominator,1) * trade.Quantity) * ISNULL(inst.MarketLot,1)*(ISNULL(inst.GeneralNumerator,1)/ISNULL(inst.GeneralDenominator,1))) / SUM(trade.Quantity),2))    
                    
                WHEN trade.RefSegmentId IN (@NSEFNOSegmentId,@NSECDXSegmentId,@MCXSXCDXSegmentId)     
                    AND instType.RefInstrumentTypeId IN(@FUTCUR)            
                THEN CONVERT(DECIMAL(28,2),ROUND(SUM(trade.Rate * trade.Quantity) / SUM(trade.Quantity),2))         
    
                WHEN trade.RefSegmentId IN (@NSEFNOSegmentId,@NSECDXSegmentId,@MCXSXCDXSegmentId)     
                    AND instType.RefInstrumentTypeId NOT IN(@FUTCUR, @OPTCUR, @OPTIDX, @OPTSTK, @OPTIRC)    
                THEN CONVERT(DECIMAL(28,2),ROUND(SUM(trade.Rate * (ISNULL(inst.PriceNumerator,1) / ISNULL(inst.PriceDenominator,1) * trade.Quantity) * ISNULL(inst.MarketLot,1) * (ISNULL(inst.GeneralNumerator,1) / ISNULL(inst.GeneralDenominator,1))) / SUM(
trade.Quantity),2))    
                ELSE          
                    0    
            END AS Price,    
   COUNT(1) AS NumberofTrades,    
            SUM(trade.Rate * trade.Quantity) / SUM(trade.Quantity) AS Rate,    
            SUM(trade.Quantity) AS Quantity    
    
  INTO #tradeData    
  FROM dbo.CoreTrade trade    
  INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId    
        INNER JOIN dbo.RefInstrumentType instType ON inst.RefInstrumentTypeId = instType.RefInstrumentTypeId    
        LEFT JOIN #clientsToExclude exclude ON trade.RefClientId = exclude.RefClientId    
        WHERE     
            trade.TradeDate = @TradeDateInternal     
            AND trade.RefSegmentId IN(@NSEFNOSegmentId, @NSECDXSegmentId, @MCXSXCDXSegmentId)    
   AND exclude.RefClientId IS NULL    
        GROUP BY     
            trade.RefClientId,    
   trade.RefInstrumentId,    
            trade.TradeDate,    
            trade.BuySell,    
            instType.RefInstrumentTypeId,    
            trade.RefSegmentId    
            
  DROP TABLE #clientsToExclude    
    
        SELECT    
            trade.RefClientId,    
            trade.TradeDate,    
            trade.RefInstrumentId,    
            trade.RefInstrumentTypeId,    
   trade.RefSegmentId,    
            CASE WHEN trade.BuySell = 1 THEN trade.Quantity ELSE 0 END AS BuyQty,    
            CASE WHEN trade.BuySell = 0 THEN trade.Quantity ELSE 0 END AS SellQty,    
            CASE WHEN trade.BuySell = 1 THEN trade.NumberofTrades END AS BuyTrades,    
            CASE WHEN trade.BuySell = 0 THEN trade.NumberofTrades END AS SellTrades,    
            CASE     
    WHEN trade.BuySell = 1 THEN trade.Price ELSE 0 END     
            AS BuyPrice,    
            CASE     
    WHEN trade.BuySell = 0 THEN trade.Price ELSE 0 END     
            AS SellPrice,     
            CASE     
    WHEN trade.BuySell = 1 THEN trade.Rate ELSE 0 END     
            AS BuyRate,    
            CASE     
    WHEN trade.BuySell = 0 THEN trade.Rate ELSE 0 END     
            AS SellRate             
        INTO #Trade    
        FROM #tradeData trade    
            
  DROP TABLE #tradeData    
    
        SELECT    
   trade.RefClientId AS RefClientId,    
            trade.TradeDate AS TradeDate,    
   instType.RefInstrumentTypeId,    
   trade.RefSegmentId,    
            SUM(trade.BuyQty) AS BuyQty,        
            SUM(trade.SellQty) AS SellQty,        
            ISNULL(SUM(trade.BuyRate),0) AS BuyPrice,        
            ISNULL(SUM(trade.SellRate),0) AS SellPrice,    
            ISNULL(SUM(trade.BuyTrades),0) AS BuyTrade,    
            ISNULL(SUM(trade.SellTrades),0) AS SellTrade,    
            MAX(CASE WHEN bhavcopy.NetTurnOver IS NULL THEN 0 ELSE CONVERT(DECIMAL(28,2), ROUND(bhavcopy.NetTurnOver,2))END) AS ExchangeTurnover,    
            MAX(CASE WHEN bhavcopy.NumberOfShares IS NULL THEN 0 ELSE bhavcopy.NumberOfShares END) AS ExchangeQty,     
            MAX(CASE WHEN bhavcopy.NumberOfTrades IS NULL THEN 0 ELSE bhavcopy.NumberOfTrades END) AS ExchangeTrade,        
            trade.RefInstrumentId AS RefInstrumentId,                    
            CASE     
                WHEN instType.RefInstrumentTypeId IN (@FUTCUR, @OPTCUR)     
                THEN ISNULL(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.BuyPrice * trade.BuyQty * ISNULL(inst.ContractSize, 1)  ,2))),0)     
                ELSE ISNULL(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.BuyPrice * trade.BuyQty,2))),0)     
            END     
            AS BuyTurnover,    
            CASE     
                WHEN instType.RefInstrumentTypeId IN (@FUTCUR, @OPTCUR)     
                THEN ISNULL(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.SellPrice * trade.SellQty * ISNULL(inst.ContractSize, 1) ,2))),0)     
                ELSE ISNULL(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.SellPrice * trade.SellQty, 2))),0)     
            END     
            AS SellTurnover,    
                
            ISNULL(SUM(CASE WHEN bhavcopy.NetTurnOver IS NULL OR bhavcopy.NetTurnOver = 0 THEN 0    
                ELSE     
                    CASE     
                    WHEN instType.RefInstrumentTypeId IN (@FUTCUR, @OPTCUR)    
                        THEN CONVERT(DECIMAL(28,2), ROUND(((trade.BuyPrice  * trade.BuyQty * ISNULL(inst.ContractSize, 1)) / bhavcopy.NetTurnOver) * 100 ,2))    
                        ELSE CONVERT(DECIMAL(28,2), ROUND(((trade.BuyPrice  * trade.BuyQty) / bhavcopy.NetTurnOver) * 100 ,2))     
                    END           
                END),0)         
            AS BuyPercentage,      
                            
            ISNULL(SUM(CASE WHEN bhavcopy.NetTurnOver IS NULL OR bhavcopy.NetTurnOver = 0 THEN 0    
                ELSE     
                    CASE     
                    WHEN instType.RefInstrumentTypeId IN (@FUTCUR, @OPTCUR)    
                        THEN CONVERT(DECIMAL(28,2), ROUND(((trade.SellPrice  * trade.SellQty * ISNULL(inst.ContractSize, 1)) / bhavcopy.NetTurnOver) * 100 ,2))    
                        ELSE CONVERT(DECIMAL(28,2), ROUND(((trade.SellPrice  * trade.SellQty) / bhavcopy.NetTurnOver) * 100 ,2))    
                    END           
                END),0)    
            AS SellPercentage    
            
                
        INTO #highTurnoverTrade    
        FROM #Trade trade             
            INNER JOIN dbo.RefClient client ON trade.RefClientId = client.RefClientId    
            INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId    
            INNER JOIN dbo.RefInstrumentType instType ON inst.RefInstrumentTypeId = instType.RefInstrumentTypeId --added for type    
            INNER JOIN dbo.RefClientStatus clientStatus ON clientStatus.RefClientStatusId = client.RefClientStatusId    
            LEFT JOIN dbo.CoreBhavCopy bhavcopy On bhavcopy.Date = @TradeDateInternal AND trade.RefInstrumentId = bhavcopy.RefInstrumentId    
        GROUP BY     
            trade.RefClientId,    
            trade.RefInstrumentId,    
            trade.TradeDate,      
            instType.RefInstrumentTypeId,    
   trade.RefSegmentId    
      
  DROP TABLE #Trade    
        SELECT     
            htt.RefClientId,    
            client.ClientId AS ClientId,    
            client.[Name] AS ClientName,    
   client.RefClientStatusId,  
            htt.TradeDate,    
   htt.RefInstrumentTypeId,    
            instType.InstrumentType AS InstrumentType,    
            (ISNULL(inst.ScripId,'') +' - '+ ISNULL(instType.InstrumentType,'') +' - '+ ISNULL(CONVERT(VARCHAR,inst.ExpiryDate,106),'') +' - '+     
            ISNULL(inst.PutCall,'') +' - '+ ISNULL(CONVERT(VARCHAR,CONVERT (DECIMAL(19,2),inst.StrikePrice)),'')) AS ScripTypeExpDtPutCallStrikePrice,    
            htt.BuyQty,    
            htt.BuyTurnover,    
            htt.BuyPrice,    
            htt.SellQty,    
            htt.SellTurnover,    
            htt.SellPrice,    
            htt.BuyPercentage,    
            htt.SellPercentage,    
            htt.BuyTrade,    
            htt.SellTrade,    
            htt.ExchangeTurnover,    
            htt.ExchangeQty,    
            htt.ExchangeTrade,    
            htt.RefInstrumentId,    
            seg.Segment,    
            rf.IntermediaryCode,    
            rf.[Name] as IntermediaryName,    
            rf.TradeName,    
   CASE     
    WHEN instType.RefInstrumentTypeId IN (@OPTSTK, @OPTIDX, @OPTCUR, @OPTIRC)    
    THEN (htt.BuyQty*htt.BuyPrice) + (htt.SellQty*htt.SellPrice)    
    ELSE NULL    
   END    
   AS ClientPremiumTO,    
            client.Dob     
  INTO #FinalData    
  FROM     
            #highTurnoverTrade htt    
            INNER JOIN dbo.RefClient client ON htt.RefClientId = client.RefClientId    
            INNER JOIN dbo.RefInstrumentType instType ON htt.RefInstrumentTypeId = instType.RefInstrumentTypeId    
   INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = htt.RefInstrumentId    
            INNER JOIN dbo.RefSegmentEnum seg ON htt.RefSegmentId = seg.RefSegmentEnumId    
   INNER JOIN #scenarioRules rules ON instType.RefInstrumentTypeId = rules.RefInstrumentTypeId AND rules.RefClientStatusId=client.RefClientStatusId  
   LEFT JOIN dbo.RefIntermediary rf on client.RefIntermediaryId = rf.RefIntermediaryId    
  WHERE    
   (    
    rules.Threshold3  IS NULL     
    OR dbo.GetAge(client.Dob) > rules.Threshold3    
   )    
   AND     
   (    
     (htt.BuyTurnover >= rules.Threshold     
     AND htt.BuyPercentage >= rules.Threshold2)     
    OR    
     (htt.SellTurnover >= rules.Threshold     
     AND htt.SellPercentage >= rules.Threshold2)    
   )    
    
  SELECT    
   fd.RefClientId,    
            fd.ClientId,    
            fd.ClientName,    
            fd.TradeDate,    
   fd.RefInstrumentTypeId,    
            fd.InstrumentType,    
   fd.ScripTypeExpDtPutCallStrikePrice,    
   fd.BuyQty,    
            fd.BuyTurnover,    
            fd.BuyPrice,    
            fd.SellQty,    
            fd.SellTurnover,    
            fd.SellPrice,    
            fd.BuyPercentage,    
            fd.SellPercentage,    
            fd.BuyTrade,    
            fd.SellTrade,    
            fd.ExchangeTurnover,    
            fd.ExchangeQty,    
            fd.ExchangeTrade,    
            fd.RefInstrumentId,    
            fd.Segment,    
            fd.IntermediaryCode,    
            fd.IntermediaryName,    
            fd.TradeName,    
   fd.ClientPremiumTO,    
   fd.Dob    
  FROM #FinalData fd    
  INNER JOIN #scenarioRules rules ON fd.RefInstrumentTypeId = rules.RefInstrumentTypeId  AND rules.RefClientStatusId=fd.RefClientStatusId  
  WHERE    
    (    
     fd.ClientPremiumTO IS NULL    
     OR fd.ClientPremiumTO >= rules.Threshold4    
    )    
    
END    
GO
--WEB-67380-END
--WEB-67380-START
GO
DECLARE 
@SegmentId INT,@RefAmlReportId INT
SET @SegmentId=(SELECT ref.RefSegmentEnumId FROM dbo.RefSegmentEnum ref WHERE ref.Code='NSE_FNO')
SET @RefAmlReportId=(SELECT ref.RefAmlReportId FROM dbo.RefamlReport ref WHERE ref.[Name]='S49 High Turnover in 1 Day FnO')

UPDATE core
SET core.RefSegmentEnumId=@SegmentId
FROM dbo.CoreAmlScenarioAlert core
WHERE core.RefAmlReportId=@RefAmlReportId
GO
--WEB-67380-END