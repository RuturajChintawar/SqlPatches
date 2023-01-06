
--WEB=70872-RC START
GO
CREATE PROCEDURE [dbo].[CoreAlert_GetTradingInfo] ( @Ids VARCHAR(MAX) )  
AS   
    BEGIN  
  
 DECLARE @InternalIds VARCHAR(MAX)  
 SET @InternalIds = @Ids  
  
 SELECT CONVERT(BIGINT,s.s) AS CoreAlertId      
 INTO #TempCoreAlertIds       
 FROM  dbo.ParseString(@InternalIds, ',') s   
  
  
 SELECT  
 temp.CoreAlertId,  
 SUM(CASE WHEN trade.BuySell = 'Buy' THEN trade.Quantity ELSE 0 END) AS BuyQty,  
 SUM(CASE WHEN trade.BuySell = 'Sell' THEN trade.Quantity ELSE 0 END) AS SellQty,  
 CASE WHEN trade.BuySell = 'Buy' THEN SUM(trade.Rate * trade.Quantity) / SUM(trade.Quantity) ELSE 0 END AS BuyRate,  
 CASE WHEN trade.BuySell = 'Sell' THEN SUM(trade.Rate * trade.Quantity) / SUM(trade.Quantity) ELSE 0 END AS SellRate,  
 trade.BuySell,  
 core.TradeDate,  
 core.RefInstrumentId  
 INTO #TradeData  
 FROM #TempCoreAlertIds temp  
 INNER JOIN dbo.CoreAlert core ON core.CoreAlertId = temp.CoreAlertId  
 INNER JOIN dbo.CoreTrade trade ON core.RefClientId = trade.RefClientId AND core.TradeDate = trade.TradeDate AND core.RefSegmentId = trade.RefSegmentId AND core.RefInstrumentId = trade.RefInstrumentId   
 GROUP BY temp.CoreAlertId , trade.BuySell,  
 core.TradeDate,  
 core.RefInstrumentId  
  
 DROP TABLE #TempCoreAlertIds  
  
 SELECT   
 trade.CoreAlertId,  
 SUM(trade.BuyQty) AS BuyQty,  
 SUM(trade.SellQty) AS SellQty,  
 SUM(CONVERT(DECIMAL(28,2),trade.BuyRate)) AS AVGBuyRate,  
 SUM(CONVERT(DECIMAL(28,2),trade.SellRate)) AS AVGSellRate,  
 MAX(CASE WHEN bhavcopy.NetTurnOver IS NULL THEN 0 ELSE CONVERT(DECIMAL(28,2), bhavcopy.NetTurnOver)END) AS ExchangeTurnover,    
    MAX(CASE WHEN bhavcopy.NumberOfShares IS NULL THEN 0 ELSE bhavcopy.NumberOfShares END) AS ExchangeQty  
 INTO #finalTradeData  
 FROM #TradeData trade  
 LEFT JOIN dbo.CoreBhavCopy bhavcopy On bhavcopy.[Date] = trade.TradeDate AND trade.RefInstrumentId = bhavcopy.RefInstrumentId  
 GROUP BY trade.CoreAlertId  
  
 DROP TABLE #TradeData  
   
 SELECT   
 trade.CoreAlertId,  
 trade.BuyQty,  
 trade.SellQty,  
 trade.AVGBuyRate,  
 trade.AVGSellRate,  
 CONVERT(DECIMAL(28,2),(trade.BuyQty*trade.AVGBuyRate)) AS BuyTo,  
 CONVERT(DECIMAL(28,2),(trade.SellQty*trade.AVGSellRate)) AS SellTo,  
 CONVERT(DECIMAL(28,2),(trade.BuyQty*trade.AVGBuyRate)+ (trade.SellQty*trade.AVGSellRate)) AS TotalTo,  
 trade.ExchangeQty,  
 trade.ExchangeTurnover  
 FROM #finalTradeData trade   
END
GO
--WEB=70872-RC END
