-- WEB-69980-RC-START
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S145 High Turnover In 1 Day In Specific Scrip'

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
	'Number_Of_Days',
	'1',
	1,
	'No of Days',
	1,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
-- WEB-69980-RC-END
-- WEB-69980-RC-START
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S145 High Turnover In 1 Day In Specific Scrip'
UPDATE  ref
SET ref.Threshold3DisplayName = 'Cumulative TO',
ref.[Description] = '<b>Objective:</b> a. This scenario will monitor trades of scrips categorised with Internal Organisation groups <br> 
b. The percentage of scrip turnover buy or sell to the exchange turnover is greater than or equal to the set Scrip percent threshold <br> 
c. Client turnover in stock buy or sell is greater than or equal to set turnover threshold <br> 

<b>Period:</b> 1 Day ; LookBack = ''X'' Days <br>
<b>Segments:</b> BSE_cash, NSE_CASH<br>
<b>Thresholds:</b> <br>
<b>1. Internal Scrip Group:</b> These are the internally classified Groups, which can be assigned to any scrip for monitoring. Exchange provides 3 lists - Current , Information, Historical Watchlists. If the client trades in any of these Scrip & Internal groups , then alert will be generated if breaches the threshold. <br>
<b>2. Scrip % :</b> It is Turnover % contribution done in a stock by the client compared to the Exchange Turnover in 1 Day. It will generate alerts if the Scrip % is greater than or equal to the set threshold. <br>
<b>3. Client TO :</b> It is the sum of Individual Turnover of the client in the particular scrip in 1 Day.  It will generate alerts if the Client Turnover is greater than or equal to the set threshold. <br>
<b>4. Cummulative TO:</b> It is the sum of all trades of the client in the particular scrip in ''X'' Lookback Days. It will generate alerts if the Turnover is greater than or equal to the set threshold. <br>
<b>5. No. of Days :</b> These are the Lookback days system will check to calculate the Cummulative Turnover of the client in 1 scrip.<br> '

FROM dbo.RefAmlReport ref
WHERE ref.RefAmlReportId = @AmlReportId

GO
-- WEB-69980-RC-END
-- WEB-69980-RC-START
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S145 High Turnover In 1 Day In Specific Scrip'
UPDATE ref
SET ref.Threshold3 = 0
FROM dbo.RefAmlScenarioRule ref
WHERE ref.RefAmlReportId = @AmlReportId
GO
-- WEB-69980-RC-END


-- WEB-69980-RC-START
GO
 ALTER PROCEDURE [dbo].[AML_GetS145HighTurnoverIn1DayInSpecificScrip]  
(  
 @ReportId INT,  
 @RunDate DATETIME,  
 @InternalIsRuleDuplicationAllowed BIT=0  
)  
AS  
BEGIN  
   
   
 DECLARE   
 @BseSegmentId INT,  
 @NseSegmentId INT,    
 @RunDateInternal DATETIME,  
 @ReportIdInternal INT,  
 @InstrumentRefEntityTypeId INT,  
 @EntityAttributeTypeRefEnumValueId INT,
 @Lookback INT,
 @ToDate DATETIME,
 @LookBackDate DATETIME
  
    
 SET @BseSegmentId = dbo.GetSegmentId('BSE_CASH')  
 SET @NseSegmentId = dbo.GetSegmentId('NSE_CASH')  
 SET @RunDateInternal  = @RunDate  
 SET @ReportIdInternal  = @ReportId  
 SELECT @InstrumentRefEntityTypeId = RefEntityTypeId FROM dbo.RefEntityType WHERE Code='Instrument';  
 SET @EntityAttributeTypeRefEnumValueId = dbo.GetEnumValueId('EntityAttributeType','UserDefined')  
 
 SELECT @Lookback = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Days'       
 
 SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')  
 
 SET @LookBackDate = CONVERT(DATETIME, DATEDIFF(dd, @Lookback-1, @RunDateInternal))  
 
 SELECT   
   trade.RefClientId,  
   trade.TradeDate,  
   trade.RefInstrumentId,  
   SUM(CASE WHEN trade.BuySell = 'Buy' THEN trade.Quantity ELSE 0 END) AS BuyQty,  
   CASE WHEN trade.BuySell = 'Buy' THEN SUM(trade.Rate * trade.Quantity) / SUM(trade.Quantity)END AS BuyPrice,  
   SUM(CASE WHEN trade.BuySell = 'Sell' THEN trade.Quantity ELSE 0 END) AS SellQty,  
   CASE WHEN trade.BuySell = 'Sell' THEN SUM(trade.Rate * trade.Quantity) / SUM(trade.Quantity)END AS SellPrice,  
   CASE WHEN trade.BuySell = 'Buy' THEN COUNT(1) END AS BuyTrades,  
   CASE WHEN trade.BuySell = 'Sell' THEN COUNT(1) END AS SellTrades      
  INTO #Trade  
  FROM dbo.CoreTrade trade  
  WHERE trade.TradeDate = @RunDateInternal AND (trade.RefSegmentId = @NseSegmentId OR trade.RefSegmentId = @BseSegmentId)  
  GROUP BY   
   trade.RefClientId,  
   trade.RefInstrumentId,  
   trade.TradeDate,  
   trade.BuySell  

   SELECT   
   trade.RefClientId,   
   trade.RefInstrumentId,  
   COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.Rate * trade.Quantity,2))),0) AS  cumulativeTO  
   INTO #tradeLookback  
   FROM dbo.CoreTrade trade  
   WHERE ( trade.TradeDate BETWEEN @LookBackDate AND @ToDate ) AND ( trade.RefSegmentId = @NseSegmentId OR trade.RefSegmentId = @BseSegmentId )   
   GROUP BY   
   trade.RefClientId,  
   trade.RefInstrumentId
     
    
  --Internal & Sms Watchlist RefEntityAttribute  
  SELECT  
  sg.RefScripGroupId,  
  sg.[Name] AS ScripName,  
  attrVal.CoreEntityAttributeValueId,  
  attrDetail.ForEntityId AS RefInstrumentId  
  INTO #mappedInstruments  
  FROM dbo.RefScripGroup sg   
  INNER JOIN dbo.CoreEntityAttributeValue attrVal ON attrVal.UserDefinedValueName=sg.[Name]   
  INNER JOIN dbo.RefEntityAttribute attr ON attr.RefEntityAttributeId=attrVal.RefEntityAttributeId  
  INNER JOIN dbo.CoreEntityAttributeDetail attrDetail ON attrDetail.RefEntityAttributeId=attr.RefEntityAttributeId AND attrDetail.CoreEntityAttributeValueId=attrVal.CoreEntityAttributeValueId  
  WHERE attr.ForRefEntityTypeId=@InstrumentRefEntityTypeId  
  AND attr.EntityAttributeTypeRefEnumValueId=@EntityAttributeTypeRefEnumValueId  
  AND attr.Code IN ('TW01','TW02') -- Internal Scrip Group, SMS Scrip Watchlist  
  AND (attrDetail.EndDate IS NULL OR attrDetail.EndDate>@RunDateInternal)  
  
  SELECT   
  DISTINCT RefInstrumentId  
  INTO #finalInstuments  
  FROM #mappedInstruments  
      
  SELECT   
   trade.RefClientId AS RefClientId,  
   trade.TradeDate AS TradeDate,  
   SUM(trade.BuyQty) AS BuyQty,  
   COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.BuyPrice * trade.BuyQty,2))),0) AS BuyTurnover,  
   COALESCE(SUM(trade.BuyPrice),0) AS BuyPrice,  
   SUM(trade.SellQty) AS SellQty,  
   COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.SellPrice * trade.SellQty,2))),0) AS SellTurnover,  
   COALESCE(SUM(trade.SellPrice),0) AS SellPrice,  
   COALESCE(SUM(CASE WHEN bhavcopy.NetTurnOver IS NULL OR bhavcopy.NetTurnOver = 0 THEN 0  
    ELSE CONVERT(DECIMAL(28,2), ROUND(((trade.BuyPrice * trade.BuyQty) / bhavcopy.NetTurnOver) * 100 ,2)) END),0)  
    AS BuyPercentage,  
               COALESCE(SUM(CASE WHEN bhavcopy.NetTurnOver IS NULL OR bhavcopy.NetTurnOver = 0 THEN 0  
    ELSE CONVERT(DECIMAL(28,2), ROUND(((trade.SellPrice * trade.SellQty) / bhavcopy.NetTurnOver) * 100 ,2))END),0)   
    AS SellPercentage,  
   COALESCE(SUM(trade.BuyTrades),0) AS BuyTrade,  
   COALESCE(SUM(trade.SellTrades),0) AS SellTrade,  
   MAX(CASE WHEN bhavcopy.NetTurnOver IS NULL THEN 0 ELSE CONVERT(DECIMAL(28,2), ROUND(bhavcopy.NetTurnOver,2))END) AS ExchangeTurnover,  
   MAX(CASE WHEN bhavcopy.NumberOfShares IS NULL THEN 0 ELSE bhavcopy.NumberOfShares END) AS ExchangeQty,      
   MAX(CASE WHEN bhavcopy.NumberOfTrades IS NULL THEN 0 ELSE bhavcopy.NumberOfTrades END) AS ExchangeTrade,      
   trade.RefInstrumentId  
  INTO #highTurnoverTrade  
  FROM #Trade trade  
    INNER JOIN dbo.RefClient client ON trade.RefClientId = client.RefClientId  
    INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
    INNER JOIN dbo.RefClientStatus clientStatus ON clientStatus.RefClientStatusId = client.RefClientStatusId  
    INNER JOIN #finalInstuments mapInst ON mapInst.RefInstrumentId=inst.RefInstrumentId  
    LEFT JOIN dbo.CoreBhavCopy bhavcopy On bhavcopy.Date = @RunDateInternal AND trade.RefInstrumentId = bhavcopy.RefInstrumentId   
  GROUP BY trade.RefClientId,  
     trade.RefInstrumentId,  
     trade.TradeDate       
    
  
  SELECT    
  t1.RefInstrumentId,   
  t1.ScripName,   
  linkClientStatus.RefClientStatusId,  
   scenarioRule.Threshold,   
   scenarioRule.Threshold2,
   scenarioRule.Threshold3
   INTO #scenarioRule  
   FROM dbo.RefAmlScenarioRule scenarioRule  
   INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus linkClientStatus ON scenarioRule.RefAmlScenarioRuleId = linkClientStatus.RefAmlScenarioRuleId  
   INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup linkScripGroup ON scenarioRule.RefAmlScenarioRuleId = linkScripGroup.RefAmlScenarioRuleId  
   INNER JOIN #mappedInstruments t1 ON t1.RefScripGroupId=linkScripGroup.RefScripGroupId  
   WHERE scenarioRule.RefAmlReportId = @ReportIdInternal  
  
    
  SELECT   
   htt.RefClientId,  
   client.ClientId AS ClientId,  
   client.[Name] AS ClientName,  
   seg.Segment,  
   htt.TradeDate,  
   inst.Code AS ScripCode,  
   inst.[Name] AS ScripName,  
   incGrp.[Name] AS IncomeGroupName,  
   incLink.Income,  
   incLink.Networth,  
   htt.BuyQty,  
   CONVERT(DECIMAL(28,2),htt.BuyTurnover) AS BuyTurnover,  
   htt.BuyPrice,  
   htt.SellQty,  
   CONVERT(DECIMAL(28,2),htt.SellTurnover) AS SellTurnover,  
   htt.SellPrice,  
   CONVERT(DECIMAL(28,2),htt.BuyPercentage) AS BuyPercentage,  
   CONVERT(DECIMAL(28,2),htt.SellPercentage) AS SellPercentage,  
   htt.BuyTrade,  
   htt.SellTrade,  
   htt.ExchangeTurnover,  
   htt.ExchangeQty,  
   htt.ExchangeTrade,  
   htt.RefInstrumentId,  
   STUFF((SELECT ',' + t1.ScripName   
   FROM #scenarioRule t1  
   WHERE t1.RefInstrumentId = htt.RefInstrumentId  AND  
   clientStatus.RefClientStatusId = t1.RefClientStatusId AND  
   ((htt.BuyTurnover >= t1.Threshold AND htt.BuyPercentage >= t1.Threshold2) OR  
       (htt.SellTurnover >= t1.Threshold AND htt.SellPercentage >= t1.Threshold2)) AND look.cumulativeTO >= t1.Threshold3
    FOR  
    XML PATH('')  
    ), 1, 1, '') AS ScripGroupNames,  
    clientStatus.RefClientStatusId  
    INTO #alerts  
	FROM #highTurnoverTrade htt 
	INNER JOIN #tradeLookback look ON look.RefClientId = htt.RefClientId AND look.RefInstrumentId = htt.RefInstrumentId
    INNER JOIN dbo.RefClient client ON htt.RefClientId = client.RefClientId  
    INNER JOIN dbo.RefInstrument inst ON htt.RefInstrumentId = inst.RefInstrumentId  
    INNER JOIN dbo.RefClientStatus clientStatus ON clientStatus.RefClientStatusId = client.RefClientStatusId  
    INNER JOIN dbo.RefSegmentEnum seg ON inst.RefSegmentId = seg.RefSegmentEnumId  
    INNER JOIN dbo.LinkRefClientRefIncomeGroupLatest incLink ON incLink.RefClientId=client.RefClientId  
    INNER JOIN dbo.RefIncomeGroup incGrp ON incGrp.RefIncomeGroupId=incLink.RefIncomeGroupId  
  
  
  SELECT   
   @RunDateInternal AS ReportDate,  
   htt.RefClientId,  
   htt.ClientId,  
   htt.ClientName,  
   htt.Segment, 
   @LookBackDate AS FromDate, 
   htt.TradeDate,  
   htt.ScripCode,  
   htt.ScripName,  
   htt.IncomeGroupName,  
   CAST(htt.Income AS DECIMAL(18,0)) AS Income,  
   CAST(htt.Networth AS DECIMAL(18,0)) AS Networth,  
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
   htt.ScripGroupNames ,
   look.cumulativeTO
  FROM #alerts htt  
  INNER JOIN #tradeLookback look ON look.RefClientId = htt.RefClientId AND look.RefInstrumentId = htt.RefInstrumentId
  WHERE EXISTS  
    (  
     SELECT 1  
     FROM #scenarioRule scenarioRule  
     WHERE   htt.RefClientStatusId = scenarioRule.RefClientStatusId AND  
       htt.RefInstrumentId=scenarioRule.RefInstrumentId AND  
       ((htt.BuyTurnover >= scenarioRule.Threshold AND htt.BuyPercentage >= scenarioRule.Threshold2) OR  
       (htt.SellTurnover >= scenarioRule.Threshold AND htt.SellPercentage >= scenarioRule.Threshold2)) AND look.cumulativeTO >= scenarioRule.Threshold3
    )  
  
  AND NOT EXISTS  
  (  
  SELECT 1 FROM dbo.CoreAmlScenarioAlert alert  
  WHERE (@InternalIsRuleDuplicationAllowed = 0)  
  AND alert.RefAmlReportId=@ReportIdInternal  
  AND alert.ReportDate = @RunDateInternal  
  AND alert.RefClientId = htt.RefClientId  
  AND ISNULL(alert.RefInstrumentId,0) = ISNULL(htt.RefInstrumentId,0)  
  AND ISNULL(alert.ScripTypeExpDtPutCallStrikePrice,'') = ISNULL(htt.ScripGroupNames,'')  
  AND ISNULL(alert.ScripCode,'')=ISNULL(htt.ScripCode,'')  
  AND ISNULL(alert.InstrumentNo,'')=ISNULL(htt.ScripName,'')  
  AND ISNULL(alert.IncomeGroupName,'')=ISNULL(htt.IncomeGroupName,'')  
  AND ISNULL(alert.Income,0)=ISNULL(CAST(htt.Income AS DECIMAL(18,0)),0)  
  AND ISNULL(alert.Networth,0)=ISNULL(CAST(htt.Networth AS DECIMAL(18,0)),0)  
  AND ISNULL(alert.BuyQty,0)=ISNULL(htt.BuyQty,0)  
  AND ISNULL(alert.BuyTurnover,0)=ISNULL(CAST(htt.BuyTurnover AS DECIMAL(28,2)),0)  
  AND ISNULL(alert.BuyPrice,0)=ISNULL(CAST(htt.BuyPrice AS DECIMAL(28,2)),0)  
  AND ISNULL(alert.SellQty,0)=ISNULL(htt.SellQty,0)  
  AND ISNULL(alert.SellTurnover,0)=ISNULL(CAST(htt.SellTurnover AS DECIMAL(28,2)),0)  
  AND ISNULL(alert.SellPrice,0)=ISNULL(CAST(htt.SellPrice AS DECIMAL(28,2)),0)  
  AND ISNULL(alert.BuyPercentage,0)=ISNULL(CAST(htt.BuyPercentage AS DECIMAL(28,2)),0)  
  AND ISNULL(alert.SellPercentage,0)=ISNULL(CAST(htt.SellPercentage AS DECIMAL(28,2)),0)  
  AND ISNULL(alert.BuyTrade,0)=ISNULL(htt.BuyTrade,0)  
  AND ISNULL(alert.SellTrade,0)=ISNULL(htt.SellTrade,0)  
  AND ISNULL(alert.ExchangeTurnover,0)=ISNULL(CAST(htt.ExchangeTurnover AS DECIMAL(28,2)),0)  
  AND ISNULL(alert.ExchangeQty,0)=ISNULL(htt.ExchangeQty,0)  
  AND ISNULL(alert.ExchangeTrade,0)=ISNULL(htt.ExchangeTrade,0)  
  )  
END  
GO
-- WEB-69980-RC-END
-- WEB-69980-RC-START
GO
 ALTER PROCEDURE dbo.AML_GetS145HighTurnoverIn1DayInSpecificScripScenarioAlertsByCaseId  
(  
 @CaseId INT,    
 @ReportId INT    
)  
AS  
BEGIN  
   
  Select   
  c.CoreAmlScenarioAlertId ,  
  c.CoreAlertRegisterCaseId,   
  c.RefClientId,   
  client.ClientId ,  
  client.[Name] as ClientName,     
  c.RefAmlReportId,   
  c.RefSegmentEnumId,  
  c.ScripTypeExpDtPutCallStrikePrice AS [Group],  
  c.ScripCode,  
  c.InstrumentNo AS ScripName,  
  c.IncomeGroupName,  
  c.Income,  
  c.Networth,  
  c.BuyQty,  
  c.BuyTurnover,  
  c.BuyPrice,  
  c.SellQty,  
  c.SellTurnover,  
  c.SellPrice,  
  c.BuyPercentage,  
  c.SellPercentage,  
  c.BuyTrade,  
  c.SellTrade,  
  c.ExchangeTurnover,  
  c.ExchangeQty,  
  c.ExchangeTrade,  
  s.Segment,  
  c.ReportDate,  
  c.[Status],  
  c.Comments,  
  report.[Name] AS ReportName,  
  c.AddedBy,  
  c.AddedOn,  
  c.EditedOn,  
  c.LastEditedBy,  
  c.ClientExplanation,
  c.Amount,
  c.TransactionDate
  FROM dbo.CoreAmlScenarioAlert c     
  INNER JOIN dbo.RefAmlReport report ON report.RefAmlReportId = c.RefAmlReportId   
  INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId  
  INNER JOIN dbo.CoreAlertRegisterCase alert ON alert.CoreAlertRegisterCaseId = c.CoreAlertRegisterCaseId  
  LEFT JOIN dbo.RefInstrument r ON c.RefInstrumentId = r.RefInstrumentId  
  LEFT JOIN dbo.RefSegmentEnum s ON s.RefSegmentEnumId = r.RefSegmentId  
  WHERE c.CoreAlertRegisterCaseId = @CaseId and report.RefAmlReportId = @ReportId    
  
END  
GO
-- WEB-69980-RC-END

-- WEB-69980-RC-START
GO
 ALTER PROCEDURE [dbo].[AML_GetS145HighTurnoverIn1DayInSpecificScripScenarioAlert_Search]    
(    
 @ReportId INT,  
 @RefSegmentEnumId int =NULL,  
 @FromDate DateTime = NULL,  
 @ToDate DateTime = NULL,  
 @AddedOnFromDate DateTime = NULL,  
 @AddedOnToDate DateTime = NULL,  
 @TxnFromDate DateTime = NULL,    
 @TxnToDate DateTime = NULL,  
 @EditedOnFromDate DATETIME = NULL,    
 @EditedOnToDate DATETIME = NULL,   
 @Client VARCHAR(500) = NULL,  
 @Status INT = NULL,  
 @Comments VARCHAR(500) = NULL,  
 @Scrip VARCHAR(200) = NULL,  
 @CaseId BIGINT = NULL,  
 @PageNo INT = 1,  
 @PageSize INT = 100  
)    
AS     
  
 DECLARE @InternalReportId INT  
 SET @InternalReportId = @ReportId  
   
 DECLARE @InternalRefSegmentEnumId INT   
 SET @InternalRefSegmentEnumId = @RefSegmentEnumId  
   
 DECLARE @InternalFromDate DATETIME   
 SET @InternalFromDate = @FromDate  
   
 DECLARE @InternalToDate DATETIME   
 SET @InternalToDate = DATEADD(day,1,@ToDate)  
   
 DECLARE @InternalAddedOnFromDate DATETIME   
 SET @InternalAddedOnFromDate = @AddedOnFromDate  
   
 DECLARE @InternalAddedOnToDate DATETIME   
 SET @InternalAddedOnToDate =  DATEADD(day,1,@AddedOnToDate)  
   
 DECLARE @InternalTxnFromDate DATETIME   
 SET @InternalTxnFromDate = @TxnFromDate  
   
 DECLARE @InternalTxnToDate DATETIME   
 SET @InternalTxnToDate =   DATEADD(day,1,@TxnToDate)  
   
 DECLARE @InternalClient VARCHAR(500)   
 SET @InternalClient = @Client  
   
 DECLARE @InternalStatus INT   
 SET @InternalStatus = @Status  
   
 DECLARE @InternalComments VARCHAR(500)   
 SET @InternalComments = @Comments  
   
 DECLARE @InternalScrip VARCHAR(200)   
 SET @InternalScrip = @Scrip  
   
 DECLARE @InternalCaseId BIGINT  
 SET @InternalCaseId = @CaseId  
   
 DECLARE @InternalPageNo INT  
 SET @InternalPageNo = @PageNo  
   
 DECLARE @InternalPageSize INT  
 SET @InternalPageSize = @PageSize  
   
 DECLARE @InternalEditedOnFromDate DATETIME  
 SET @InternalEditedOnFromDate = dbo.GetDateWithoutTime(@EditedOnFromDate)  
   
 DECLARE @InternalEditedOnToDate DATETIME  
 SET @InternalEditedOnToDate = dbo.GetDateWithoutTime(DATEADD(DAY,1,@EditedOnToDate))  
  
BEGIN  
   
 SELECT   
  c.CoreAmlScenarioAlertId ,  
  c.CoreAlertRegisterCaseId,   
  report.[Name] AS ReportName,  
  c.RefClientId,   
  client.ClientId ,  
  client.[Name] AS ClientName,     
  c.RefAmlReportId,   
  c.RefInstrumentId,  
  c.RefSegmentEnumId,  
  s.Segment,  
  c.TransactionFromDate,  
  c.TransactionToDate,  
  c.TransactionDate,  
  c.ScripTypeExpDtPutCallStrikePrice AS [Group],  
  c.ScripCode,  
  c.InstrumentNo AS ScripName,  
  c.IncomeGroupName,  
  c.Income,  
  c.Networth,  
  c.BuyQty,  
  c.BuyTurnover,  
  c.BuyPrice,  
  c.SellQty,  
  c.SellTurnover,  
  c.SellPrice,  
  c.BuyPercentage,  
  c.SellPercentage,  
  c.BuyTrade,  
  c.SellTrade,  
  c.ExchangeTurnover,  
  c.ExchangeQty,  
  c.ExchangeTrade, 
  c.Amount,
  c.AddedBy,    
  c.AddedOn,    
  c.LastEditedBy,    
  c.EditedOn,     
  c.ReportDate,  
  c.Comments,  
  c.ClientExplanation,  
  c.[Status],
  ROW_NUMBER() OVER ( ORDER BY c.AddedOn DESC ) AS RowNumber    
 INTO #temp  
 FROM dbo.CoreAmlScenarioAlert c    
  INNER JOIN dbo.RefAmlReport report ON report.RefAmlReportId = c.RefAmlReportId    
  INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId  
  INNER JOIN dbo.CoreAlertRegisterCase alert ON alert.CoreAlertRegisterCaseId = c.CoreAlertRegisterCaseId  
  LEFT JOIN dbo.RefInstrument r ON c.RefInstrumentId = r.RefInstrumentId  
  LEFT JOIN dbo.RefSegmentEnum s ON s.RefSegmentEnumId = r.RefSegmentId  
 WHERE report.RefAmlReportId = @InternalReportId   and  
  (@InternalRefSegmentEnumId is null or s.RefSegmentEnumId=@InternalRefSegmentEnumId or c.RefSegmentEnumId=@InternalRefSegmentEnumId) and  
  ((@InternalFromDate IS NULL OR dbo.GetDateWithoutTime(c.ReportDate) >= @InternalFromDate) and (@InternalToDate IS NULL OR c.ReportDate < @InternalToDate)) and  
  ((@InternalAddedOnFromDate IS NULL OR dbo.GetDateWithoutTime(c.AddedOn) >= @InternalAddedOnFromDate) and (@InternalAddedOnToDate IS NULL OR c.AddedOn < @InternalAddedOnToDate)) and  
  ((@InternalTxnFromDate IS NULL OR dbo.GetDateWithoutTime(c.ReportDate) >= @InternalTxnFromDate) and (@InternalTxnToDate IS NULL OR c.ReportDate < @InternalTxnToDate)) and  
  (@InternalClient IS NULL OR (client.ClientId like '%' +  @InternalClient +'%' OR client.[Name] like '%' +  @InternalClient +'%')) and   
  (@InternalStatus IS NULL OR c.[Status] = @InternalStatus) and  
  (@InternalComments IS NULL OR c.Comments like '%' +  @InternalComments +'%')   
  AND (@InternalScrip IS NULL OR (r.[Name] like '%' + @InternalScrip + '%' OR r.Code like '%' + @InternalScrip + '%'))  
  AND (@InternalCaseId IS NULL OR alert.CoreAlertRegisterCaseId = @InternalCaseId)   
  AND (@InternalEditedOnFromDate IS NULL OR c.EditedOn >= @InternalEditedOnFromDate) AND (@InternalEditedOnToDate IS NULL OR c.EditedOn <= @InternalEditedOnToDate)  
   
 SELECT  t.*  
 FROM    #temp t  
 WHERE   t.RowNumber BETWEEN ( ( ( @InternalPageNo - 1 )  
                                    * @InternalPageSize ) + 1 )  
                        AND     @InternalPageNo * @InternalPageSize  
    ORDER BY t.CoreAmlScenarioAlertId DESC  
          
    SELECT  COUNT(1) FROM #temp  
END 
GO
-- WEB-69980-RC-END
