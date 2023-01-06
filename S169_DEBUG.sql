-- S169-debug
GO
EXEC dbo.Sys_DropIfExists 'AML_GetClientTradingActivityComparedWithDealingOffAddress_S169_Custom','P'
GO
GO
 CREATE PROCEDURE dbo.AML_GetClientTradingActivityComparedWithDealingOffAddress_S169_Custom (        
 @RunDate DATETIME,
 @LookBackInternal INT,
 @ExcludePinInternal VARCHAR(MAX),
 @NumberOfUniquePin   INT  ,
 @TotalTO DECIMAL(28,2),
 @IsExcludePro INT,
 @IsExcludeInstitution INT
)        
AS        
BEGIN     
	  DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @ExcludePin VARCHAR(MAX), @ClientToThreshold DECIMAL(28,2), @UniquePinThreshold INT,    
	  @BSECashId INT, @NSECashId INT,@NSEFNOId INT, @NSECDXId INT, @Lookback INT,@LookBackDate DATETIME ,@ToDate DATETIME, @ProStatusId INT, @InstituteStatusId INT      
     
	        
	  SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)      
      SELECT @ReportIdInternal = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S169 Client Trading Activity Compared With Dealing Off Address'
	  SET @Lookback = @LookBackInternal     
	  SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')           
	  SET @LookBackDate = CONVERT(DATETIME, DATEDIFF(dd, @Lookback-1, @RunDateInternal))     
      
    
	  SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'    
	  SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'    
	  SELECT @NSEFNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_FNO'    
	  SELECT @NSECDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CDX'  
	  SELECT @ProStatusId = RefClientStatusId  FROM dbo.RefClientStatus WHERE [Name] = 'Pro'  
	  SELECT  @InstituteStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'  
                                                    
	  SET     
	   @ExcludePin = @ExcludePinInternal   
    
	  SET    
	   @UniquePinThreshold = @NumberOfUniquePin    
    
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
   INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
   LEFT JOIN #clientsToExclude ex ON ex.RefClientId = trade.RefClientId      
   WHERE ex.RefClientId IS NULL AND    
   trade.RefSegmentId IN ( @BSECashId, @NSECashId , @NSEFNOId , @NSECDXId)  AND   
   (trade.TradeDate BETWEEN @LookBackDate AND @ToDate)   AND
   (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)  
	AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)  

    
  DROP TABLE #clientsToExclude  
  
  SELECT       
   trade.RefClientId,      
   trade.RefSegmentId, 
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
   trade.Pin NOT IN ('111111','333333', '0',ISNULL(ref.CAddressPin,''), ISNULL(ref.PAddressPin,''), ISNULL(inter.Pin,''),ISNULL(inter.ResPin,''))  
   
  GROUP BY      
   trade.RefClientId,      
   trade.RefSegmentId,  
   trade.Pin ,  
   instru.Code  
     
    DROP TABLE #ExcludePin  
	DROP TABLE #tradedetails  
    
  SELECT       
   trade.RefClientId, 
   STUFF(( SELECT ', '+ pinforstuff.Pin            
    FROM #tradeDetailsWitPin pinforstuff         
    WHERE pinforstuff.RefClientId = trade.RefClientId
    FOR XML PATH('')),1,1,'') AS tradepin, 
	SUM(CASE WHEN trade.RefSegmentId = @BSECashId  THEN trade.turnover ELSE 0 END) BSEcash,
	SUM(CASE WHEN trade.RefSegmentId = @NSECashId  THEN trade.turnover ELSE 0 END) NSEcash,
	SUM(CASE WHEN trade.RefSegmentId = @NSEFNOId   THEN trade.turnover ELSE 0 END) NSEfno,
	SUM(CASE WHEN trade.RefSegmentId = @NSECDXId   THEN trade.turnover ELSE 0 END) NSEcdx,
   SUM(trade.turnover) AS totalto,      
   COUNT(1) AS uniquepin      
  INTO #tradewithcount      
  FROM #tradeDetailsWitPin trade      
  GROUP BY      
   trade.RefClientId 
      
     DROP TABLE #tradeDetailsWitPin  
      
   SELECT      
   ref.RefClientId,     
   ref.ClientId,      
   ref.[Name] AS ClientName,
   @LookBackDate AS FromDate,  
   @RunDateInternal AS TradeDate, 
   STUFF((ISNULL(', '+ref.CAddressPin,'')+ISNULL(', '+ref.PAddressPin,'')+ISNULL(', '+inter.Pin,'')+ISNULL(', '+inter.ResPin,'')),1,2,'') AS ClientPIN,    
   trade.tradepin AS TradePin,     
   trade.BSEcash AS BseCash,
   trade.NSEcash AS NseCash,
   trade.NSEfno AS NseFno,
   trade.NSEcdx AS NseCdx,
   trade.totalto AS TotalTO

   FROM #tradewithcount trade      
   INNER JOIN dbo.RefClient ref ON ref.RefClientId = trade.RefClientId
   LEFT JOIN dbo.RefIntermediary inter ON inter.RefIntermediaryId = ref.RefIntermediaryId      
   WHERE trade.uniquepin > = @UniquePinThreshold  AND trade.totalto >=  @TotalTO
     
 END    
 
 
GO
GO
EXEC dbo.AML_GetClientTradingActivityComparedWithDealingOffAddress_S169_Custom
	@RunDate = '2022-04-04', -- rundate (yyyy-MM-dd),
    @LookBackInternal = 30, -- lookback period
   @ExcludePinInternal = '445204,400074', --exclude these trade with this pin
   @NumberOfUniquePin   =  3,-- unique pin threshold,
   @TotalTO =11.11, --combine threshold,
   @IsExcludeInstitution =1,-- true 1, else 0
   @IsExcludePro = 0 -- true 1, else 0
	
GO
GO
EXEC dbo.Sys_DropIfExists 'AML_GetClientTradingActivityComparedWithDealingOffAddress_S169_Custom','P'
GO