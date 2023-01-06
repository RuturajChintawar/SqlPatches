--WEB- 72655- RC START -S607
GO
 ALTER PROCEDURE [dbo].[CoreAlert_InsertFromStagingCircularTrading]   
(   
 @Guid VARCHAR(50)   
)  
AS   
  BEGIN  
 DECLARE @InternalGuid VARCHAR(50)  
  
 SET @InternalGuid = @Guid  
  
 INSERT INTO dbo.CoreAlert  
         (   
    RefSegmentId ,  
          RefAlertTypeId ,  
          AlertDate ,  
          RefClientId ,  
          Symbol ,  
          ClientName ,          
          CoreAlertRegisterCaseId ,  
          AddedBy ,  
          AddedOn ,  
          LastEditedBy ,  
          EditedOn ,           
          CommReferenceNo ,  
          [FileName] ,  
          MemberId,  
    TMID,  
    ClientPan,  
    ClientBuyQuantity,  
    ClientSellQuantity,  
    PercentClientMarketConcentation,  
    PercentClientMemberConcentration ,  
    CcdCategory  ,
	TradeDate,
	RefInstrumentId
          )  
    SELECT  seg.RefSegmentEnumId ,  
            alertType.RefAlertTypeId ,  
            stage.AlertDate ,  
            stage.RefClientId ,  
            stage.Symbol,  
            stage.ClientName ,            
            stage.CaseId,  
            stage.AddedBy ,  
            stage.AddedOn ,  
            stage.AddedBy,  
            stage.AddedOn,        
            stage.CommunicationReferenceNo ,  
            stage.[FileName] ,  
            stage.MemberId ,  
            stage.TmCode,  
      stage.Pan,  
      stage.ClientBuyQuantity,  
      stage.ClientSellQuantity,  
      stage.ClientConcentrationMarket,  
      stage.PercentageMemberConcentrationScrip ,  
      stage.CcdCategory,
	  stage.AlertDate,
	  ref.RefInstrumentId
  FROM dbo.StagingCircularTrading stage   
   INNER JOIN dbo.RefAlertType alertType ON stage.AlertType = alertType.Code   
   INNER JOIN dbo.RefSegmentEnum seg ON stage.Segment = seg.Code
   LEFT JOIN dbo.RefInstrument ref ON ref.RefSegmentId = seg.RefSegmentEnumId AND ref.Code = stage.Symbol AND ref.[Status] = 'A'

  WHERE stage.Guid = @InternalGuid AND NOT EXISTS  
  (  
   SELECT 1 FROM   
   dbo.CoreAlert al   
   WHERE al.RefSegmentId = seg.RefSegmentEnumId   
   AND al.RefAlertTypeId = alertType.RefAlertTypeId   
   AND al.AlertDate = stage.AlertDate   
   AND al.RefClientId = stage.RefClientId   
   AND al.Symbol = stage.Symbol  
  )  
  
  DELETE FROM dbo.StagingCircularTrading    
     
 END  
GO
--WEB 72655 RC END

--WEB=70872-RC START
GO
ALTER PROCEDURE [dbo].[CoreAlert_GetTradingInfo] ( @Ids VARCHAR(MAX) )  
AS   
    BEGIN  
  
DECLARE @InternalIds VARCHAR(MAX)  ,@nse_cdxid INT
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
 core.RefInstrumentId  ,
 core.CurrentPeriod
 INTO #TradeData  
 FROM #TempCoreAlertIds temp  
 INNER JOIN dbo.CoreAlert core ON core.CoreAlertId = temp.CoreAlertId  
 INNER JOIN dbo.CoreTrade trade ON core.RefClientId = trade.RefClientId AND core.RefSegmentId = trade.RefSegmentId AND
 ( 
	(
		(core.CurrentPeriod IS NOT  NULL AND trade.TradeDate BETWEEN core.CurrentPeriod AND EOMONTH(core.CurrentPeriod))
		AND (core.RefInstrumentId IS NULL OR core.RefInstrumentId = trade.RefInstrumentId)
	) OR (core.TradeDate = trade.TradeDate AND core.RefInstrumentId = trade.RefInstrumentId)
)
 GROUP BY temp.CoreAlertId , trade.BuySell,  
 core.TradeDate,  
 core.RefInstrumentId  ,
 core.CurrentPeriod


 
 DROP TABLE #TempCoreAlertIds  
  
 SELECT   
 trade.CoreAlertId,  
 SUM(trade.BuyQty) AS BuyQty,  
 SUM(trade.SellQty) AS SellQty,  
 SUM(CONVERT(DECIMAL(28,2),trade.BuyRate)) AS AVGBuyRate,  
 SUM(CONVERT(DECIMAL(28,2),trade.SellRate)) AS AVGSellRate 
 INTO #finalTradeData  
 FROM #TradeData trade  

 GROUP BY trade.CoreAlertId 


 SELECT trade.CoreAlertId,  
 MAX(CASE WHEN bhavcopy.NetTurnOver IS NULL THEN 0 ELSE CONVERT(DECIMAL(28,2), bhavcopy.NetTurnOver)END) AS ExchangeTurnover,    
  MAX(CASE WHEN bhavcopy.NumberOfShares IS NULL THEN 0 ELSE bhavcopy.NumberOfShares END) AS ExchangeQty  
  INTO #bhavcopydata
 FROM #TradeData  trade
  LEFT JOIN dbo.CoreBhavCopy bhavcopy ON (trade.TradeDate IS NOT NULL AND bhavcopy.[Date] = trade.TradeDate AND trade.RefInstrumentId = bhavcopy.RefInstrumentId) OR
 (  trade.CurrentPeriod IS NOT NULL AND bhavcopy.[Date] BETWEEN trade.CurrentPeriod AND EOMONTH(trade.CurrentPeriod)AND (trade.RefInstrumentId IS NULL OR trade.RefInstrumentId = bhavcopy.RefInstrumentId)) 
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
 bhav.ExchangeQty,  
 bhav.ExchangeTurnover  
 FROM #finalTradeData trade 
 INNER JOIN #bhavcopydata bhav ON bhav.CoreAlertId = trade.CoreAlertId
END
GO
--WEB=70872-RC END

GO
 ALTER PROCEDURE [dbo].[CoreAlert_InsertNseFromStagingNseDormantNotTraded]  
(  
  @Guid VARCHAR(50)  
)  
AS   
BEGIN  
  
DECLARE @InternalGuid VARCHAR(50)  
  
 SET @InternalGuid = @Guid  
  
 INSERT INTO dbo.CoreAlert  
         (   
    RefSegmentId ,  
          RefAlertTypeId ,  
          AlertDate ,  
          RefClientId ,  
          ClientName ,  
    MemberId,  
    MemberName,          
          CoreAlertRegisterCaseId ,  
    TradeDate,  
          AddedBy ,  
          AddedOn ,  
          LastEditedBy ,  
          EditedOn ,           
          CommReferenceNo ,  
          [FileName] ,  
    ClientPan  ,
	RefInstrumentId
          )  
    SELECT  seg.RefSegmentEnumId ,  
            alertType.RefAlertTypeId ,  
            stage.AlertDate ,  
            stage.RefClientId ,  
            stage.ClientName ,  
      stage.MemberCode,  
      stage.MemberName,            
            stage.CaseId,  
      stage.ClientLastTradeDate,  
            stage.AddedBy ,  
            stage.AddedOn ,  
            stage.AddedBy,  
            stage.AddedOn,        
            stage.CommunicationReferenceNo ,  
            stage.[FileName] ,  
      stage.ClientPan,
	  ref.RefInstrumentId
  FROM dbo.StagingNseDormantNotTraded stage   
   INNER JOIN dbo.RefAlertType alertType ON stage.AlertType = alertType.Code   
   INNER JOIN dbo.RefSegmentEnum seg ON stage.Segment = seg.Code  
   LEFT JOIN RefInstrument  ref ON ref.[Name] = stage.MemberName AND ref.[Status] = 'A' AND ref.RefSegmentId = seg.RefSegmentEnumId 
  WHERE stage.Guid = @InternalGuid AND NOT EXISTS  
  (  
   SELECT 1 FROM   
   dbo.CoreAlert al   
   WHERE al.RefSegmentId = seg.RefSegmentEnumId   
   AND al.RefAlertTypeId = alertType.RefAlertTypeId   
   AND al.AlertDate = stage.AlertDate   
   AND al.RefClientId = stage.RefClientId   
   AND al.Symbol = stage.Symbol  
  )  
  
 DELETE FROM dbo.StagingNseDormantNotTraded   
  
  
END  
GO
go
  ALTER PROCEDURE [dbo].[CoreAlert_InsertNcdexFnoFromStaging] ( @Guid VARCHAR(50) )          
 AS           
    BEGIN          
    
  INSERT  INTO dbo.CoreAlert(       
   RefSegmentId ,          
   RefAlertTypeId ,          
   AlertDate ,          
   RefClientId ,          
   CoreAlertRegisterCaseId ,          
   RefInstrumentId,          
   TMID,          
   CurrentMonth,          
   TradeDate,          
   MemberName,          
   ClientName,          
   ClientPan,          
   CurrentMonthAdtv,          
   AdtvOfThreeMonths,          
   NoOfTimes,                            
   ClientBuyQuantity,          
   ClientSellQuantity,          
   ClientBuyValue,          
   ClientSellValue,                
   ClientGrossValue,          
   PercentClientMarketConcentation,          
   LongOI,        
   ShortOI,        
   LongOIPer,        
   ShortOIPer,                     
   AddedBy ,          
   AddedOn ,          
   LastEditedBy ,          
   EditedOn   ,        
   Symbol   ,        
   TimeDifference ,        
   TradeNoAlphaNumeric ,        
   ExpiryDate,        
   TradeTime ,        
   TradePrice  ,        
   BuyTradingMemberName,      
   SellTradingMemberId,      
   OriginalTime,           
   SellOrderEnts,      
   LimitPrice,      
   SellOrderNumber,      
   BuySell,      
   TransactionCode,      
   OrderType,      
   StartLastTradedPrice,      
   OriginalVolume,      
   AdtvOfSixMonths ,  
   UOrLAsset,  
   EndTime,  
   Ex32TMID,  
   EX32ExpiryDate,  
   EX32TransactionCode,  
   EX32TradeTime,  
   EX32OrderType,  
   EX32TradePrice,  
   EX32ClientSellQuantity,  
   EX32MemberName,  
   EX32StartLastTradedPrice,  
   EX32EndTime              
           )          
                SELECT  seg.RefSegmentEnumId ,          
                        stage.AlertTypeId ,          
                        stage.AlertDate ,          
                        stage.RefClientId ,          
                        stage.CaseId ,          
                        stage.RefInstrumentId,          
                        stage.TMID ,          
                        stage.CurrentMonth ,          
                        stage.TradeDate,          
                        stage.MemberName ,          
                        stage.ClientName ,          
                        stage.PanNo ,          
                        stage.CurrentMonthAdtv ,          
                        stage.AdtvOfThreeMonths ,          
                        stage.NoOfTimes ,           
                        stage.BuyVolume,          
                        stage.SellVolume,          
                        stage.BuyValue,          
                        stage.SellValue,          
                        stage.GrossValue,          
                        stage.PerToMarket,          
                        stage.LongOI,        
                        stage.ShortOI,        
                        stage.LongOIPer,        
                        stage.ShortOIPer,        
                        stage.AddedBy ,          
                        stage.AddedOn ,          
                        stage.AddedBy ,          
                        stage.AddedOn  ,        
      stage.Symbol,        
      stage.TimeDifference,        
      stage.TradeNoAlphaNumeric,        
      stage.ExpiryDate,        
      stage.TradeTime,        
      stage.TradePrice,        
      stage.BuyTradingMemberName,      
      stage.SellMemberId,      
      stage.OriginalTime,      
      stage.SellOrderEnts,      
      stage.SellLimitPrice,      
      stage.SellOrderNumber,      
      stage.BuySell,      
      stage.TransactionCode,      
      stage.OrderType,      
      stage.StartLastTradedPrice,      
      stage.EndLastTradedPrice,      
      stage.AdtvOfSixMonths,  
      stage.UOrLAsset,  
      stage.EndTime,  
      CASE WHEN alertType.Code = 'EX32' THEN stage.TMID ELSE NULL END,  
      CASE WHEN alertType.Code = 'EX32' THEN stage.ExpiryDate ELSE NULL END,  
      CASE WHEN alertType.Code = 'EX32' THEN stage.TransactionCode ELSE NULL END,  
      CASE WHEN alertType.Code = 'EX32' THEN stage.TradeTime ELSE NULL END,  
      CASE WHEN alertType.Code = 'EX32' THEN stage.OrderType ELSE NULL END,  
      CASE WHEN alertType.Code = 'EX32' THEN stage.TradePrice ELSE NULL END,  
      CASE WHEN alertType.Code = 'EX32' THEN stage.SellVolume ELSE NULL END,  
      CASE WHEN alertType.Code = 'EX32' THEN stage.MemberName ELSE NULL END,  
      CASE WHEN alertType.Code = 'EX32' THEN stage.StartLastTradedPrice ELSE NULL END,  
      CASE WHEN alertType.Code = 'EX32' THEN stage.EndTime ELSE NULL END  
                         
                FROM    dbo.StagingNcdexAlert stage    
      INNER JOIN dbo.RefAlertType alertType ON alertType.RefAlertTypeId=stage.AlertTypeId        
                        INNER JOIN dbo.RefSegmentEnum seg ON stage.Segment = seg.Segment                                                          
                WHERE   stage.GUID = @Guid          
                        AND NOT EXISTS ( SELECT 1          
                                         FROM   dbo.CoreAlert al          
                                         WHERE  al.RefSegmentId = seg.RefSegmentEnumId          
            AND al.RefClientId = stage.RefClientId          
            AND al.AlertDate = stage.AlertDate          
            AND al.RefAlertTypeId = stage.AlertTypeId          
            AND ISNULL(al.Symbol, '') = ISNULL(stage.Symbol, '')     
            AND (    
               alertType.Code!='EX31'     
               OR    
               (    
               alertType.Code='EX31'   
               AND al.BuySell=stage.BuySell    
               AND al.LimitPrice=stage.SellLimitPrice  
               AND al.UOrLAsset=stage.UOrLAsset  
               )    
             )      
            AND (    
               alertType.Code!='EX32'     
               OR    
               (    
               alertType.Code='EX32'   
               AND al.BuySell=stage.BuySell    
               AND al.UOrLAsset=stage.UOrLAsset  
               AND al.LimitPrice=stage.SellLimitPrice  
               AND al.OriginalVolume=stage.EndLastTradedPrice  
               )    
             )            
           )    
        DELETE  FROM dbo.StagingNcdexAlert where GUID = @Guid         
 END       
go
exec CoreAlert_GetTradingInfo '2190'