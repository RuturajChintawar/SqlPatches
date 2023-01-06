DECLARE
	@RunDate DATETIME ='2-1-2022',    
	 @ReportId INT    
DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @EndDate DATETIME , @StartDate DATETIME , 
	 @NsdlType904 INT, @NsdlType925 INT, @CdslType2 INT, @CdslType3 INT, @CdslType5 INT,       
     @CdslStatus305 INT, @CdslStatus511 INT ,@cdsl INT,@nsdl INT , @LookBackPeriod INT, @TxnValue DECIMAL(28,2),
	 @OtherDate DATETIME, @CDSLClientDatabaseId INT , @NSDLClientDatabaseId INT 
   
      
  SET @RunDateInternal = @RunDate  
  
  SET @EndDate = DATEADD( DAY, -(DAY(@RunDateInternal)), @RunDateInternal) + CONVERT(DATETIME, '23:59:59.000')  
  SET @StartDate = DATEADD(mm, DATEDIFF(mm, 0, @RunDateInternal) - 1, 0)   
  SET @OtherDate =  DATEADD( DAY, -1, @RunDateInternal)

  SELECT @CdslType2 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 2 AND [Name] = 'Transactions within DP'      
  SELECT @CdslType3 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 3 AND [Name] = 'Transactions across DPs'      
  SELECT @CdslType5 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 5 AND [Name] = 'Inter-depository'      
        
  SELECT @CdslStatus305 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 305      
  SELECT @CdslStatus511 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 511      
    
  SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 904 AND [Name] = 'Delivery Free of Payment (Inter DP) Instruction'      
  SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
  
  SELECT @cdsl= RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'CDSL'  
  SELECT @nsdl= RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSDL' 
  
  SET @CDSLClientDatabaseId = (SELECT enum.RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum enum WHERE enum.DatabaseType = 'CDSL')
  SET @NSDLClientDatabaseId = (SELECT enum.RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum enum WHERE enum.DatabaseType = 'NSDL')

  SELECT   
   @LookBackPeriod = 30 
  
  SELECT   
   @TxnValue = 500000
  
	 SELECT DISTINCT  
		RefClientId  
	 INTO #clientsToExclude  
	 FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex  
	 WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)   
	  AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)  
  
	CREATE TABLE #tradeData (        
	   TransactionId BIGINT,      
	   RefClientId INT,          
	   RefSegmentId INT,          
	   RefIsinId INT,       
	   Quantity INT, 
	   BusinessDate DATETIME ,
	   OnOffMarketFlag INT, --0 for on 1 for off
	   BuySellFlag INT -- 0 SELL 1 BUY
	)    
  
	INSERT INTO #tradeData( RefClientId, RefSegmentId, RefIsinId, Quantity, BusinessDate, OnOffMarketFlag, BuySellFlag)  
	  SELECT        
		  dp.RefClientId,      
		  dp.RefSegmentId,  
		  dp.RefIsinId,  
		  dp.Quantity, 
		  dp.BusinessDate,
		  CASE WHEN (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '') AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')  THEN 1
		  ELSE 0 END,
		  CASE WHEN (dp.BuySellFlag = 'D' OR dp.BuySellFlag = 'S') THEN 0
		  ELSE 1 END
	  FROM dbo.CoreDpTransaction dp    
	  LEFT JOIN #clientsToExclude clex ON clex.RefClientId = dp.RefClientId  
	  WHERE dp.RefSegmentId = @cdsl AND clex.RefClientId IS NULL  
	   AND (dp.BusinessDate BETWEEN @STARTdATE and @RunDateInternal  )
	   AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))      
		OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))  
	
	SELECT
		tr.RefClientId, 
		tr.RefSegmentId, 
		tr.RefIsinId, 
		tr.OnOffMarketFlag, 
		tr.BuySellFlag,
		tr.BusinessDate,
		SUM(tr.Quantity) AS Quantity
	INTO #tempData
	FROM #tradeData tr
	WHERE tr.BusinessDate = @RunDateInternal
	GROUP BY tr.RefClientId, tr.RefSegmentId, tr.RefIsinId, tr.OnOffMarketFlag, tr.BuySellFlag, tr.BusinessDate

	SELECT
		tr.RefClientId, 
		tr.RefSegmentId, 
		tr.RefIsinId, 
		tr.OnOffMarketFlag, 
		tr.BuySellFlag,
		tr.BusinessDate,
		SUM(tr.Quantity) AS Quantity
    INTO #oppData
	FROM #tradeData tr
	GROUP BY tr.RefClientId, tr.RefSegmentId, tr.RefIsinId, tr.OnOffMarketFlag, tr.BuySellFlag, tr.BusinessDate
	
   SELECT DISTINCT        
     RefIsinId,        
     BusinessDate        
   INTO #selectedIsins        
   FROM #tradeData        
        
   SELECT DISTINCT          
     bhav.RefIsinId,          
     bhav.[Close],        
     bhav.RefSegmentId,        
     isin.BusinessDate,        
     ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId, isin.BusinessDate ORDER BY bhav.RefSegmentId) AS RN          
   INTO #presentBhavIdsTemp          
   FROM #selectedIsins isin          
   INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = isin.RefIsinId         
   WHERE bhav.[Date] = isin.BusinessDate     
    
	SELECT         
		temp.RefIsinId,          
		temp.[Close]  ,
		temp.BusinessDate       
	INTO #presentBhavIds          
	FROM #presentBhavIdsTemp temp          
	WHERE (temp.RN = 1)     
    
	SELECT
		cli.RefClientId,
		cli.ClientId AS ClientId,
		cli.[Name] AS ClientName,
		temp.RefSegmentId,
		@RunDateInternal AS TradeDate,
		temp.RefIsinId,
		enum.Segment AS Depository,
		CASE WHEN cli.RefClientDatabaseEnumId = @NSDLClientDatabaseId THEN cli.Dpid ELSE NULL END DpId,
		isin.[Name] AS ISIN,
		CASE WHEN temp.OnOffMarketFlag = 0 THEN 'On Market' ELSE 'Off Market' END AS RunDateTxnDesc,
		CASE WHEN temp.BuySellFlag = 0 THEN 'Cr' ELSE 'Dr' END AS DrCr,
		temp.Quantity AS TxnQty,
		tempBhavIds.[Close] AS TxnRate,
		temp.Quantity * tempBhavIds.[Close] AS TxnTO,
		oop.BusinessDate AS OppTxnDate,
		CASE WHEN oop.OnOffMarketFlag = 0 THEN 'On Market' ELSE 'Off Market' END AS OppTxnDesc,
		CASE WHEN oop.BuySellFlag = 0 THEN 'Cr' ELSE 'Dr' END AS OppTxnDrCr,
		oop.Quantity AS TxnQty,
		oopBhavIds.[Close] AS TxnRate,
		oop.Quantity * oopBhavIds.[Close] AS TxnTO
		
	FROM #tempData temp
	INNER JOIN #oppData oop ON oop.RefClientId = temp.RefClientId AND oop.RefIsinId = temp.RefIsinId AND oop.RefSegmentId = temp.RefSegmentId AND oop.OnOffMarketFlag + temp.OnOffMarketFlag = 1 AND oop.BuySellFlag + temp.BuySellFlag = 1
	INNER JOIN #presentBhavIds tempBhavIds ON tempBhavIds.RefIsinId = temp.RefIsinId AND tempBhavIds.BusinessDate = temp.BusinessDate
	INNER JOIN #presentBhavIds oopBhavIds ON oopBhavIds.RefIsinId = temp.RefIsinId AND oopBhavIds.BusinessDate = temp.BusinessDate
	INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = temp.RefIsinId
	INNER JOIN dbo.RefClient cli ON cli.RefClientId = temp.RefClientId
	INNER JOIN dbo.RefSegmentEnum enum ON enum.RefSegmentEnumId = oop.RefSegmentId