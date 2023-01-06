GO
ALTER PROCEDURE dbo.AML_GetHighProfitLossbyGroupofClientsin1Day   
(  
 @RunDate DATETIME,  
 @ReportId INT  
)  
AS  
BEGIN  
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @BSECashId INT, @NSECashId INT, @OPTSTKId INT,   
  @OPTIDXId INT, @OPTCURId INT, @OPTIRCId INT, @FUTIDXId INT, @FUTSTKId INT, @FUTIRDId INT,   
  @FUTIRTId INT, @FUTCURId INT, @FUTIRCId INT, @FUTIVXId INT, @FUTIRFId INT, @NSEFNOId INT,   
  @NSECDXId INT, @GrpPLThresh DECIMAL(28, 2), @GrpTOThresh DECIMAL(28, 2), @NoOfClThresh INT,  
  @ClSharePercThresh DECIMAL(28, 2), @S163Id INT, @S164Id INT,  
  @IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT  ,  @IsGroupGreaterThanOneClient INT
  
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
 SET @ReportIdInternal = @ReportId  
 SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'  
 SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'  
 SELECT @NSEFNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_FNO'  
 SELECT @NSECDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CDX'  
 SELECT @OPTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'  
 SELECT @OPTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'  
 SELECT @OPTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'  
 SELECT @OPTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIRC'  
 SELECT @FUTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIDX'  
 SELECT @FUTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTSTK'  
 SELECT @FUTIRDId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRD'  
 SELECT @FUTIRTId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRT'  
 SELECT @FUTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR'  
 SELECT @FUTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRC'  
 SELECT @FUTIVXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIVX'  
 SELECT @FUTIRFId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRF'  
 SELECT @GrpPLThresh = CONVERT(DECIMAL(28, 2), [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Profit_Loss'  
 SELECT @GrpTOThresh = CONVERT(DECIMAL(28, 2), [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Threshold_Quantity'  
 SELECT @NoOfClThresh = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Quantity'  
 SELECT @ClSharePercThresh = CONVERT(DECIMAL(28, 2), [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Client_Turnover_Percentage'  
 SELECT @S163Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S163 High Profit or Loss by Group of Clients in 1 Day EQ'  
 SELECT @S164Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S164 High Profit or Loss by Group of Clients in 1 Day FNO'  
  SELECT   
  @IsGroupGreaterThanOneClient = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Active_In_Report' 
 
 SELECT   
  @IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Exclude_Pro'  
   
 SELECT   
  @IsExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Exclude_Institution'  
   
 SELECT   
  @ProStatusId = RefClientStatusId   
 FROM dbo.RefClientStatus   
 WHERE [Name] = 'Pro'  
   
   
 SELECT   
  @InstituteStatusId = RefClientStatusId  
 FROM dbo.RefClientStatus WHERE [Name] = 'Institution'  
  
 SELECT  
  RefClientId  
 INTO #clientsToExclude  
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion  
 WHERE RefAmlReportId = @ReportIdInternal  
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)  
  
 CREATE TABLE #scrnarioDataMapping(  
  RefSegmentId INT NOT NULL,  
  RefAmlReportId INT NOT NULL,  
 -- RefInstrumentTypeId INT NULL,  
  TradeDate DATETIME NOT NULL  
 )  
 --for S163 there is no instrumentType filter  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@BSECashId,@S163Id,@RunDateInternal)  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@NSECashId,@S163Id,@RunDateInternal)  
  
 --for S164 there is instrumentType filter  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@NSEFNOId,@S164Id,@RunDateInternal)  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@NSECDXId,@S163Id,@RunDateInternal)  
  
 CREATE TABLE #trades (RefClientId INT, Quantity INT, Turnover DECIMAL(28, 2), BuySell INT, RefSegmentId INT, RefInstrumentId INT)  
  
 INSERT INTO #trades (RefClientId, BuySell, RefSegmentId, RefInstrumentId,Turnover,Quantity)  
 SELECT    
  trade.RefClientId,  
  CASE WHEN trade.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell,  
  trade.RefSegmentId,  
  trade.RefInstrumentId,  
  CASE   
   WHEN (INST.RefInstrumentTypeId = @OPTCURId or INST.RefInstrumentTypeId = @FUTCURId  )  
    THEN trade.Quantity * ISNULL(inst.ContractSize, 1)  
   ELSE   
    trade.Quantity * trade.Rate  
  END AS Turnover,  
  CASE   
   WHEN (INST.RefInstrumentTypeId = @OPTCURId or INST.RefInstrumentTypeId = @FUTCURId  )  
    THEN trade.Quantity * ISNULL(inst.ContractSize, 1)  
   ELSE  
    trade.Quantity   
  END AS Quantity  
      
 FROM #scrnarioDataMapping mapping  
 INNER JOIN dbo.CoreTrade trade ON trade.TradeDate = mapping.TradeDate AND trade.RefSegmentId = mapping.RefSegmentId   
  AND mapping.RefAmlReportId = @ReportIdInternal --report filter   
 INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
 INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId  
 --LEFT JOIN dbo.RefInstrumentType instType ON  instType.RefInstrumentTypeId = inst.RefInstrumentTypeId   
 --  AND (mapping.RefInstrumentTypeId IS NOT NULL AND instType.RefInstrumentTypeId = mapping.RefInstrumentTypeId)-- for instrument type case condition  
 LEFT JOIN #clientsToExclude cl ON trade.RefClientId = cl.RefClientId  
 WHERE cl.RefClientId IS NULL  
 AND (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)  
 AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)  
  
 --IF @ReportIdInternal = @S163Id  
 --BEGIN  
 -- INSERT INTO #trades (RefClientId, Quantity, Turnover, BuySell, RefSegmentId, RefInstrumentId)  
 -- SELECT  
 --  trade.RefClientId,  
 --  trade.Quantity,  
 --  (trade.Quantity * trade.Rate) AS Turnover,  
 --  CASE WHEN trade.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell,  
 --  trade.RefSegmentId,  
 --  trade.RefInstrumentId  
 -- FROM dbo.CoreTrade trade  
 -- INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
 -- LEFT JOIN #clientsToExclude cl ON trade.RefClientId = cl.RefClientId  
 -- WHERE cl.RefClientId IS NULL  
 -- AND (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)  
 -- AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)  
 -- AND trade.RefSegmentId IN (@BSECashId, @NSECashId)  
 -- AND trade.TradeDate = @RunDateInternal  
  
 --END   
 --ELSE IF @ReportIdInternal = @S164Id  
 --BEGIN  
 -- INSERT INTO #trades (RefClientId, Quantity, Turnover, BuySell, RefSegmentId, RefInstrumentId)  
 -- SELECT  
 --  trade.RefClientId,  
 --  CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)  
 --   THEN trade.Quantity * ISNULL(inst.ContractSize, 1)  
 --   ELSE trade.Quantity END AS Quantity,  
 --  CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)  
 --   THEN trade.Quantity * trade.Rate * ISNULL(inst.ContractSize, 1)  
 --   ELSE trade.Quantity * trade.Rate END AS Turnover,  
 --  CASE WHEN trade.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell,  
 --  trade.RefSegmentId,  
 --  trade.RefInstrumentId  
 -- FROM dbo.CoreTrade trade  
 -- INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
 -- LEFT JOIN #clientsToExclude cl ON trade.RefClientId = cl.RefClientId  
 -- INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
 -- WHERE cl.RefClientId IS NULL  
 -- AND (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)  
 -- AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)  
 -- AND trade.RefSegmentId IN (@NSEFNOId, @NSECDXId)  
 -- AND trade.TradeDate = @RunDateInternal  
 --END  
  
 DROP TABLE #clientsToExclude  
  
 SELECT  
  RefClientId,  
  RefSegmentId,  
  RefInstrumentId,  
  SUM(CASE WHEN BuySell = 1 THEN Quantity ELSE 0 END) AS BuyQty,  
  SUM(CASE WHEN BuySell = 0 THEN Quantity ELSE 0 END) AS SellQty,  
  SUM(CASE WHEN BuySell = 1 THEN Turnover ELSE 0 END) AS BuyTurnover,  
  SUM(CASE WHEN BuySell = 0 THEN Turnover ELSE 0 END) AS SellTurnover  
 INTO #clientWiseTrades  
 FROM #trades  
 GROUP BY RefClientId, RefSegmentId, RefInstrumentId  
  
 DROP TABLE #trades  
  
 --SELECT  
 -- RefClientId,  
 -- RefSegmentId,  
 -- RefInstrumentId,  
 -- CASE   
 --  WHEN BuyQty <= SellQty  
 --   THEN BuyQty   
 --  ELSE   
 --   SellQty   
 -- END AS Qty,  
 -- (BuyTurnover / BuyQty) AS BuyRate,  
 -- (SellTurnover / SellQty) AS SellRate  
 --INTO #intradayData  
 --FROM #clientWiseTrades  
 --WHERE SellQty > 0 AND BuyQty > 0  
  
-- DROP TABLE #clientWiseTrades  
  
 SELECT  
  RefClientId,  
  SUM(  
   (  
    (CASE WHEN BuyQty <= SellQty THEN BuyQty ELSE SellQty END) * ((BuyTurnover / BuyQty) + (SellTurnover / SellQty))  
   )  
  ) AS ClientTO,  
  SUM(  
   (  
    (CASE WHEN BuyQty <= SellQty THEN BuyQty ELSE SellQty END) * ((SellTurnover / SellQty) - (BuyTurnover / BuyQty))  
   )  
  ) AS ClientPL  
 INTO #clientFinalData  
 FROM #clientWiseTrades  
 WHERE SellQty <> 0 AND BuyQty <> 0     
 GROUP BY RefClientId  
  
 DROP TABLE #clientWiseTrades  
 --DROP TABLE #intradayData  
  
 --SELECT  
 -- RefClientId,  
 -- SUM(ClientTO) AS ClientTO,  
 -- SUM(ClientPL) AS ClientPL  
 --INTO #clientFinalData  
 --FROM #clientFinalDataInter  
 --GROUP BY RefClientId  
  
 --DROP TABLE #clientFinalDataInter  
  
 SELECT  
  t.RefClientId,  
  t.ClientTO,  
  t.ClientPL  
 INTO #group1  
 FROM (SELECT   
   RefClientId,  
   ClientTO,  
   ClientPL,  
   DENSE_RANK() OVER (ORDER BY ClientTO DESC) AS RN,
   COUNT(ClientTO)OVER() AS CRN
  FROM #clientFinalData  
  WHERE ClientPL > 0  
 ) t WHERE t.RN <= @NoOfClThresh AND @IsGroupGreaterThanOneClient<t.CRN
  
 SELECT  
  t.RefClientId,  
  t.ClientTO,  
  t.ClientPL  
 INTO #group2  
 FROM (SELECT   
   RefClientId,  
   ClientTO,  
   ClientPL,  
   DENSE_RANK() OVER (ORDER BY ClientTO DESC) AS RN,
   COUNT(ClientTO)OVER() AS CRN
  FROM #clientFinalData  
  WHERE ClientPL < 0  
 ) t WHERE t.RN <= @NoOfClThresh AND @IsGroupGreaterThanOneClient<t.CRN
  
 DROP TABLE #clientFinalData  
  
 SELECT  
  SUM(ClientTO) AS GroupTO,  
  SUM(ClientPL) AS GroupPL  
 INTO #group1Total  
 FROM #group1  
  
 SELECT  
  SUM(ClientTO) AS GroupTO,  
  SUM(ClientPL) AS GroupPL  
 INTO #group2Total  
 FROM #group2  
   
   
 Declare @Grp1PL DECIMAL(28,2),@Grp1TO DECIMAL(28,2),@Grp2PL DECIMAL(28,2),@Grp2TO DECIMAL(28,2)
 SELECT  @Grp2PL = GroupPL, @Grp2TO = GroupTO FROM #group2Total  
 SELECT  @Grp1PL = GroupPL, @Grp1TO = GroupTO FROM #group1Total  
  
 CREATE TABLE #data(   
  RefClientId INT,  
  ClientTO DECIMAL(28, 2),   
  ClientPL DECIMAL(28, 2),   
  GroupPL DECIMAL(28, 2),   
  GroupTO DECIMAL(28, 2),   
  ClientPerc DECIMAL(28, 2),  
  DataType INT NOT NULL  
 )  
 IF(ABS(@Grp1PL)>=@GrpPLThresh AND @Grp1TO >= @GrpTOThresh)  
  
 BEGIN    
 INSERT INTO #data(RefClientId, ClientTO, ClientPL, GroupPL, GroupTO, ClientPerc,DataType)  
  SELECT  
   grp.RefClientId,  
   --cl.ClientId,  
   --cl.[Name] AS ClientName,  
   grp.ClientTO,  
   grp.ClientPL,  
   @Grp1PL,  
   @Grp1TO,  
   (ABS(grp.ClientPL) * 100 / ABS(@Grp1PL)) AS ClientPerc,  
   1  
  FROM #group1 grp  
  WHERE (ABS(grp.ClientPL) * 100 / ABS(@Grp1PL))>=@ClSharePercThresh  
 END  
  
 DROP TABLE #group1  
 DROP TABLE #group1Total  
  
  
 IF(ABS(@Grp2PL)>=@GrpPLThresh AND @Grp2TO >= @GrpTOThresh)  
  
 BEGIN    
 INSERT INTO #data(RefClientId, ClientTO, ClientPL, GroupPL, GroupTO, ClientPerc,DataType)  
  SELECT  
   grp.RefClientId,  
   grp.ClientTO,  
   grp.ClientPL,  
   @Grp2PL,  
   @Grp2TO,  
   (ABS(grp.ClientPL) * 100 / ABS(@Grp2PL)) AS ClientPerc,  
   2  
  FROM #group2 grp  
  WHERE (ABS(grp.ClientPL) * 100 / ABS(@Grp2PL)) >= @ClSharePercThresh  
 END  
  
 DROP TABLE #group2  
 DROP TABLE #group2Total 
 
  SELECT  
  t.*  
 INTO #data2  
 FROM (SELECT   
   dat.*,
   COUNT(dat.ClientTO) OVER( partition by dat.ClientTO  ) c
  FROM #data  dat
  
 ) t WHERE @IsGroupGreaterThanOneClient<t.c
  
 SELECT  t.RefClientId,    
   cl.ClientId,  
   cl.[Name] AS ClientName,   
   t.ClientTO,    
   t.ClientPL,    
   t.GroupPL,    
   t.GroupTO,    
   t.ClientPerc,   
   t.DescriptionClientPerc,  
   @RunDateInternal AS TradeDate   
 FROM (  
  
  SELECT  
   fd.RefClientId,  
     
   fd.ClientTO,  
   fd.ClientPL,  
   fd.GroupPL,  
   fd.GroupTO,  
   fd.ClientPerc,  
   STUFF((SELECT ' ; ' + client.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) COLLATE DATABASE_DEFAULT + '%'  
    FROM #data t  
    INNER JOIN dbo.RefClient client ON client.RefClientId = t.RefClientId   
    WHERE DataType = 1 AND fd.RefClientId <> t.RefClientId  
    FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc  
  FROM #data fd  
  WHERE DataType = 1   
  
  UNION ALL  
  
  SELECT  
   fd.RefClientId,  
   fd.ClientTO,  
   fd.ClientPL,  
   fd.GroupPL,  
   fd.GroupTO,  
   fd.ClientPerc,  
   STUFF((SELECT ' ; ' + client.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) COLLATE DATABASE_DEFAULT + '%'  
    FROM #data t   
    INNER JOIN dbo.RefClient client ON client.RefClientId = t.RefClientId   
    WHERE DataType = 2 AND fd.RefClientId <> t.RefClientId  
    FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc  
  FROM #data fd  
  WHERE DataType = 2  
 ) t  
 INNER JOIN dbo.RefClient cl On cl.RefClientId = t.RefClientId  
END  
GO