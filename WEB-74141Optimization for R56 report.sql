--RC START 74141
GO
ALTER PROCEDURE [dbo].[CoreAlert_GetTradingInfo] ( @Ids VARCHAR(MAX) )  
AS   
BEGIN  
  
     DECLARE @InternalIds VARCHAR(MAX)  
     SET @InternalIds = @Ids  
  
     SELECT CONVERT(BIGINT,s.s) AS CoreAlertId      
     INTO #TempCoreAlertIds       
     FROM  dbo.ParseString(@InternalIds, ',') s   
 
     SELECT 
     core.CoreAlertId,  
     core.TradeDate,  
     core.RefInstrumentId,
     core.RefClientId,
     core.RefSegmentId
     INTO #alertDetails
     FROM  #TempCoreAlertIds t
     INNER JOIN dbo.CoreAlert core ON core.CoreAlertId = t.CoreAlertId  
 
     DROP TABLE #TempCoreAlertIds 

     SELECT DISTINCT RefClientId, TradeDate, RefSegmentId
     INTO #clientTrade
     FROM #alertDetails

     SELECT trade.CoreTradeId
     INTO #tradeIds
     FROM #clientTrade t
     INNER JOIN dbo.CoreTrade trade ON t.RefClientId = trade.RefClientId AND t.TradeDate = trade.TradeDate AND t.RefSegmentId = trade.RefSegmentId 
 

     SELECT 
     al.CoreAlertId,
     tr.CoreTradeId,
     CASE WHEN tr.BuySell='Buy' THEN 1 ELSE 0 END AS BuySell,
     tr.Quantity,
     tr.TradeDate,
     tr.RefInstrumentId,
     tr.Rate
     INTO #tradeDetails
     FROM #tradeIds temp
     INNER JOIN dbo.CoreTrade tr ON tr.CoreTradeId=temp.CoreTradeId
     INNER JOIN #alertDetails al ON al.RefClientId = tr.RefClientId AND al.TradeDate = tr.TradeDate AND al.RefSegmentId = tr.RefSegmentId and al.RefInstrumentId=tr.RefInstrumentId


     SELECT  
     tr.CoreAlertId,  
     SUM(CASE WHEN tr.BuySell = 1 THEN tr.Quantity ELSE 0 END) AS BuyQty,  
     SUM(CASE WHEN tr.BuySell = 0 THEN tr.Quantity ELSE 0 END) AS SellQty,  
     CASE WHEN tr.BuySell = 1 THEN SUM(tr.Rate * tr.Quantity) / SUM(tr.Quantity) ELSE 0 END AS BuyRate,  
     CASE WHEN tr.BuySell = 0 THEN SUM(tr.Rate * tr.Quantity) / SUM(tr.Quantity) ELSE 0 END AS SellRate,  
     tr.BuySell,  
     tr.TradeDate,  
     tr.RefInstrumentId  
     INTO #TradeData  
     FROM #tradeDetails tr  
     GROUP BY 
     tr.CoreAlertId, 
     tr.BuySell,  
     tr.TradeDate,  
     tr.RefInstrumentId  
  
     DROP TABLE #tradeDetails
	 
	SELECT DISTINCT
		trade.TradeDate,
		trade.RefInstrumentId
	INTO #InstData
	FROM #TradeData trade

	 SELECT
		MAX(CASE WHEN bhavcopy.NetTurnOver IS NULL THEN 0 ELSE CONVERT(DECIMAL(28,2), bhavcopy.NetTurnOver)END) AS ExchangeTurnover,    
		MAX(CASE WHEN bhavcopy.NumberOfShares IS NULL THEN 0 ELSE bhavcopy.NumberOfShares END) AS ExchangeQty,
		trade.TradeDate,
		trade.RefInstrumentId
	 INTO #bhvaData
	 FROM #InstData trade 
	 LEFT JOIN dbo.CoreBhavCopy bhavcopy On bhavcopy.[Date] = trade.TradeDate AND trade.RefInstrumentId = bhavcopy.RefInstrumentId  
     GROUP BY trade.TradeDate,
		trade.RefInstrumentId

     SELECT   
     trade.CoreAlertId,  
     SUM(trade.BuyQty) AS BuyQty,  
     SUM(trade.SellQty) AS SellQty,  
     SUM(CONVERT(DECIMAL(28,2),trade.BuyRate)) AS AVGBuyRate,  
     SUM(CONVERT(DECIMAL(28,2),trade.SellRate)) AS AVGSellRate,
	 trade.TradeDate,
	 trade.RefInstrumentId
     INTO #finalTradeData  
     FROM #TradeData trade 
     GROUP BY trade.CoreAlertId,
		trade.TradeDate,
		trade.RefInstrumentId
  
     DROP TABLE #TradeData  
   
     SELECT   
     trade.CoreAlertId,  
     trade.BuyQty,  
     trade.SellQty,  
     trade.AVGBuyRate,  
     trade.AVGSellRate,  
     CONVERT(DECIMAL(28,2),(trade.BuyQty * trade.AVGBuyRate)) AS BuyTo,  
     CONVERT(DECIMAL(28,2),(trade.SellQty * trade.AVGSellRate)) AS SellTo,  
     CONVERT(DECIMAL(28,2),(trade.BuyQty * trade.AVGBuyRate)+ (trade.SellQty*trade.AVGSellRate)) AS TotalTo,  
     bhav.ExchangeQty,  
     bhav.ExchangeTurnover  
     FROM #finalTradeData trade
	 LEFT JOIN #bhvaData  bhav ON bhav.TradeDate = trade.TradeDate AND bhav.RefInstrumentId = trade.RefInstrumentId
END
GO
--RC END 74141