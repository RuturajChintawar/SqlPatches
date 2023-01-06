---WEB- 71160 RC START
GO
 ALTER PROCEDURE dbo.AML_GetS169ClientTradingActivityComparedWithDealingOffAddressScenarioAlertByCaseId   
(  
 @CaseId INT,    
 @ReportId INT    
)  
AS  
BEGIN  
   
  SELECT  
  c.CoreAmlScenarioAlertId,  
  c.CoreAlertRegisterCaseId,   
  c.RefClientId,   
  client.ClientId, --  
  client.[Name] AS [ClientName], --  
  c.RefAmlReportId,  
  c.RefSegmentEnumId AS SegmentId, --  
  c.TurnOver AS ClientTO, --  
  c.Expiry AS FromDate,--
  c.TransactionDate AS TradeDate, --  
  c.Symbol AS Segment, -- 
  c.ScripCode AS ScripCode,--
  c.[Description] AS ScripDetails,--
  c.NetWorthDesc AS ClientPIN, --  
  c.BuyTerminal AS TradePin, --  
  
  c.ReportDate,  
  c.[Status],  
  c.Comments,  
  report.[Name] AS [ReportName],  
  c.AddedBy,  
  c.AddedOn,  
  c.EditedOn,  
  c.LastEditedBy,  
  c.ClientExplanation  
  FROM dbo.CoreAmlScenarioAlert c     
  INNER JOIN dbo.RefAmlReport report ON report.RefAmlReportId = c.RefAmlReportId   
  INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId  
  INNER JOIN dbo.CoreAlertRegisterCase alert ON alert.CoreAlertRegisterCaseId = c.CoreAlertRegisterCaseId  
  INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = c.RefSegmentEnumId  
  WHERE c.CoreAlertRegisterCaseId = @CaseId AND report.RefAmlReportId = @ReportId    
  
END  
GO
---WEB- 71160 RC END
---WEB- 71160 RC START
GO
 ALTER PROCEDURE dbo.CoreAmlScenarioClientTradingActivityComparedWithDealingOffAddressAlert_Search   
(      
 @ReportId INT,    
 @RefSegmentEnumId INT = NULL,  
 @FromDate DATETIME = NULL,    
 @ToDate DATETIME = NULL,    
 @AddedOnFromDate DATETIME = NULL,    
 @AddedOnToDate DATETIME = NULL,  
 @EditedOnFromDate DATETIME = NULL,    
 @EditedOnToDate DATETIME = NULL,  
 @TxnFromDate DATETIME = NULL,    
 @TxnToDate DATETIME = NULL,    
 @Client VARCHAR(500) = NULL,    
 @Status INT = NULL,    
 @Comments VARCHAR(500) = NULL,  
 @Scrip VARCHAR(200) = NULL,  
 @CaseId BIGINT = NULL,  
 @PageNo INT = 1,  
 @PageSize INT = 100  
)      
AS       
BEGIN  
  
 DECLARE @InternalScrip VARCHAR(200), @InternalPageNo INT, @InternalPageSize INT  
   
 SET @InternalScrip = @Scrip  
 SET @InternalPageNo = @PageNo  
 SET @InternalPageSize = @PageSize  
  
 CREATE TABLE #data (CoreAmlScenarioAlertId BIGINT )  
 INSERT INTO #data EXEC dbo.CoreAmlScenarioAlert_SearchCommon   
  @ReportId = @ReportId,  
  @RefSegmentEnumId = @RefSegmentEnumId,  
  @FromDate = @FromDate,  
  @ToDate = @ToDate,  
  @AddedOnFromDate = @AddedOnFromDate,  
  @AddedOnToDate = @AddedOnToDate,    
  @EditedOnFromDate = @EditedOnFromDate,    
  @EditedOnToDate = @EditedOnToDate,   
  @TxnFromDate = @TxnFromDate,    
  @TxnToDate = @TxnToDate,  
  @Client = @Client,  
  @Status = @Status,  
  @Comments = @Comments,   
  @CaseId = @CaseId  
  
  
 SELECT temp.CoreAmlScenarioAlertId, ROW_NUMBER() OVER (ORDER BY alert.AddedOn DESC) AS RowNumber INTO #filteredAlerts  
 FROM #data temp   
 INNER JOIN dbo.CoreAmlScenarioAlert alert ON temp.CoreAmlScenarioAlertId = alert.CoreAmlScenarioAlertId  
  
 SELECT t.CoreAmlScenarioAlertId INTO #alertids   
 FROM #filteredAlerts t  
 WHERE t.RowNumber  
 BETWEEN (((@InternalPageNo - 1) * @InternalPageSize) + 1) AND @InternalPageNo * @InternalPageSize  
 ORDER BY t.CoreAmlScenarioAlertId DESC  
         
  
 SELECT   
  c.CoreAmlScenarioAlertId,  
  c.CoreAlertRegisterCaseId,  
  c.RefClientId,  
  client.ClientId, --  
  client.[Name] AS ClientName, --   
  c.RefAmlReportId,  
  c.RefSegmentEnumId AS SegmentId, --  
  c.TurnOver AS ClientTO, --  
  c.Expiry AS FromDate,--
  c.TransactionDate AS TradeDate, --  
  c.Symbol AS Segment, --  
  c.ScripCode AS ScripCode,--
  c.[Description] AS ScripDetails,--
  c.NetWorthDesc AS ClientPIN, --  
  c.BuyTerminal AS TradePin, --  
  
  c.ReportDate,  
  c.AddedBy,  
  c.AddedOn,  
  c.LastEditedBy,  
  c.EditedOn,  
  c.Comments,  
  c.ClientExplanation,  
  c.[Status]  
 FROM #alertids temp  
 INNER JOIN dbo.CoreAmlScenarioAlert c ON c.CoreAmlScenarioAlertId = temp.CoreAmlScenarioAlertId  
 INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId  
 INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = c.RefSegmentEnumId  
         
 SELECT COUNT(1) FROM #filteredAlerts  
END  
GO
---WEB- 71160 RC END

---WEB- 71160 RC START
GO
 ALTER PROCEDURE dbo.AML_GetClientTradingActivityComparedWithDealingOffAddress (        
 @RunDate DATETIME,        
 @ReportId INT        
)        
AS        
BEGIN     
	  DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @ExcludePin VARCHAR(MAX), @ClientToThreshold DECIMAL(28,2), @UniquePinThreshold INT,    
	  @BSECashId INT, @NSECashId INT,@NSEFNOId INT, @NSECDXId INT, @Lookback INT,@LookBackDate DATETIME ,@ToDate DATETIME    
     
	  SET @ReportIdInternal = @ReportId       
	  SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)      
     
	  SELECT @Lookback = CONVERT(INT, [Value]) FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Days'        
	  SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')           
	  SET @LookBackDate = CONVERT(DATETIME, DATEDIFF(dd, @Lookback-1, @RunDateInternal))     
      
    
	  SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'    
	  SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'    
	  SELECT @NSEFNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_FNO'    
	  SELECT @NSECDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CDX'    
    
	  SELECT     
	   @ExcludePin = [Value]     
	  FROM dbo.SysAmlReportSetting     
	  WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Excluded_Groups'    
    
	  SELECT     
	   @UniquePinThreshold = CONVERT( INT , [Value])    
	  FROM dbo.SysAmlReportSetting     
	  WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Entity'    
    
	  SELECT    
		RTRIM(LTRIM(pins.items)) AS pin    
	  INTO #ExcludePin    
	  FROM dbo.Split(@ExcludePin,',') pins    
     
	  SELECT DISTINCT    
	  RefClientId    
	  INTO #clientsToExclude
	  FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex    
	  WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)     
	  AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)   

	  SELECT
	  trade.RefClientId,
	  trade.RefSegmentId,
	  trade.RefInstrumentId,
	  SUBSTRING (CONVERT(VARCHAR(MAX),trade.CtclId) ,1,6)AS Pin,
	  trade.Rate,
	  trade.Quantity
	  INTO #tradedetails
	  FROM dbo.CoreTrade trade
	  LEFT JOIN #clientsToExclude ex ON ex.RefClientId = trade.RefClientId    
	  WHERE ex.RefClientId IS NULL AND  
			trade.RefSegmentId IN ( @BSECashId, @NSECashId , @NSEFNOId , @NSECDXId)  AND 
			(trade.TradeDate BETWEEN @LookBackDate AND @ToDate) 
	 
	 DROP TABLE #clientsToExclude

	 SELECT     
	  trade.RefClientId,    
	  trade.RefSegmentId, 
	  trade.RefInstrumentId,
	  trade.Pin, 
	  CASE WHEN trade.RefSegmentId = @NSECDXId AND instru.Code='JPYINR' THEN COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.Rate * trade.Quantity * 1000,2))),0)
		   WHEN trade.RefSegmentId  = @NSECDXId THEN COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.Rate * trade.Quantity * instru.ContractSize,2))),0)
		   ELSE COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(trade.Rate * trade.Quantity,2))),0)
	  END
	   AS turnover    
	 INTO #tradeDetailsWitPin    
	 FROM #tradedetails trade    
	 INNER JOIN  dbo.RefClient ref ON ref.RefClientId = trade.RefClientId
	 INNER JOIN dbo.RefInstrument instru ON instru.RefInstrumentId = trade.RefInstrumentId
	 LEFT JOIN dbo.RefIntermediary inter ON inter.RefIntermediaryId = ref.RefIntermediaryId   
	 LEFT JOIN #ExcludePin pins ON pins.pin = trade.Pin  
	 WHERE  
	  pins.pin IS NULL AND       
	  trade.Pin NOT IN ('111111','333333', ISNULL(ref.CAddressPin,''), ISNULL(ref.PAddressPin,''), ISNULL(inter.Pin,''),ISNULL(inter.ResPin,''))
	 GROUP BY    
	  trade.RefClientId,    
	  trade.RefSegmentId, 
	  trade.RefInstrumentId,
	  trade.Pin ,
	  instru.Code
	  
    DROP TABLE #ExcludePin
	DROP TABLE #tradedetails
	 
	 SELECT     
	  trade.RefClientId,    
	  trade.RefSegmentId,  
	  trade.RefInstrumentId,
	  STUFF(( SELECT ', '+ pinforstuff.Pin          
	   FROM #tradeDetailsWitPin pinforstuff       
	   WHERE pinforstuff.RefClientId = trade.RefClientId AND    
	   pinforstuff.RefSegmentId = trade.RefSegmentId   AND
	   pinforstuff.RefInstrumentId = trade.RefInstrumentId
	   FOR XML PATH('')),1,1,'') AS tradepin,    
	  SUM(trade.turnover) AS totalto,    
	  COUNT(1) AS uniquepin    
	 INTO #tradewithcount    
	 FROM #tradeDetailsWitPin trade    
	 GROUP BY    
	  trade.RefClientId,     
	  trade.RefSegmentId,
	  trade.RefInstrumentId
    
     DROP TABLE #tradeDetailsWitPin
    
	  SELECT    
	  ref.RefClientId,   
	  ref.ClientId,    
	  ref.[Name] AS ClientName,  
	  trade.RefInstrumentId ,
	  @LookBackDate AS FromDate,
	  @RunDateInternal AS TradeDate,    
	  trade.RefSegmentId,    
	  seg.Segment,    
	  STUFF((ISNULL(', '+ref.CAddressPin,'')+ISNULL(', '+ref.PAddressPin,'')+ISNULL(', '+inter.Pin,'')+ISNULL(', '+inter.ResPin,'')),1,2,'') AS ClientPIN,  
	  trade.tradepin AS TradePin,    
	  trade.totalto AS ClientTO,
	  instru.Code AS ScripCode,
	  CASE WHEN trade.RefSegmentId IN ( @BSECashId, @NSECashId) THEN ISNULL(instru.[Name]+'----','')
			ELSE instru.[Name] +' - ' +ISNULL(instru.ScripType ,'')+ ' - ' + CONVERT(VARCHAR,instru.ExpiryDate,106)+' - ' + ISNULL(instru.PutCall,'') + ' - ' +CONVERT(VARCHAR , instru.StrikePrice) 
	   END AS ScripDetails
	  FROM #tradewithcount trade    
	  INNER JOIN dbo.RefClient ref ON ref.RefClientId = trade.RefClientId    
	  INNER JOIN dbo.RefSegmentEnum seg ON trade.RefSegmentId = seg.RefSegmentEnumId   
	  INNER JOIN dbo.RefInstrument instru ON trade.RefInstrumentId = instru.RefInstrumentId
	  LEFT JOIN dbo.RefIntermediary inter ON inter.RefIntermediaryId = ref.RefIntermediaryId    
	  WHERE trade.uniquepin > = @UniquePinThreshold    
      
	  DROP TABLE #tradewithcount
     
 END    
 
 
GO
---WEB- 71160 RC END
---WEB- 71160 RC START

GO
 UPDATE ref
 SET ref.[Description] = 'This Scenario will detect and alert if clients have done trades with diffrent PIN codes from KYC and dealing office PIN<br>
	Segments covered : BSE_CASH, NSE_CASH, NSE_FNO, NSE_CDX ; Period: 1 day ( Lookback period of Trades: 30 ) <br>
	<b>Thresholds:</b> <br>
	1. No. of Traded Unique PIN: These are the unique PIN codes that the client has traded on the run date in one particular scrip. It will work on greater than or equal to basis.  It will generate alerts If the these traded PIN are totally different from the PIN mentioned in the client KYC. (Correspondence, Permanent address pin of the client and Pins of all the intermediary as per intermediary master ). The Top ''X'' PIN''s will be shown in alert output as per the threshold.  <br>
	2. Lookback Period: This is the Lookback days that system will check the trades in past ''X'' days in  a particular scrip for alert generation. Lookback period is configurable but maximum of 30 days.<br>
	3. Exclude PIN: It is a Flat manual textbox threshold. User can add the PIN Codes which they want to exclude from alert generation. The PIN''s are to be entered comma seperated. ( e.g. 400101, 396235 )<br>
	<b>Note:</b><br>
	1. The number of Traded Unique PIN should be totally different from the Client PIN''s to generate alert. <br>'
 FROM dbo.RefAmlReport ref
 WHERE ref.[Name] = 'S169 Client Trading Activity Compared With Dealing Off Address'
 GO
 ---WEB- 71160 RC END
 ---WEB- 71160 RC START
 GO
 DECLARE 
 @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S169 Client Trading Activity Compared With Dealing Off Address'
 DELETE FROM dbo.SysAmlReportSetting WHERE RefAmlreportId=@AmlReportId and [Name]='Total_Turnover'
 GO
  ---WEB- 71160 RC END
 