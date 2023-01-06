 Declare
 @RunDate DATETIME ='03-22-2022',    
 @ReportId INT =1268,
 @IsAlertDulicationAllowed BIT = 1    
  DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT,  @EndDate DATETIME , @StartDate DATETIME , @NsdlType904 INT, @NsdlType925 INT, @CdslType2 INT, @CdslType3 INT, @CdslType5 INT,       
     @CdslStatus305 INT, @CdslStatus511 INT ,@cdsl INT,@nsdl INT  ,@NoOfOOPClient INT, @NoOfInTxn INT, @TotalTxnValue DECIMAL(28,2) , @IsAlertDulicationAllowedInternal BIT  
   
  SET @ReportIdInternal = @ReportId     
  SET @RunDateInternal = @RunDate  
  
  SET @IsAlertDulicationAllowedInternal = @IsAlertDulicationAllowed  
  
  SET @EndDate = DATEADD(DAY, -(DAY(@RunDateInternal)), @RunDateInternal) + CONVERT(DATETIME, '23:59:59.000')  
  SET @StartDate = DATEADD(mm, DATEDIFF(mm, 0, @RunDateInternal) - 1, 0)   
  
  SELECT @CdslType2 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 2 AND [Name] = 'Transactions within DP'      
  SELECT @CdslType3 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 3 AND [Name] = 'Transactions across DPs'      
  SELECT @CdslType5 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 5 AND [Name] = 'Inter-depository'      
        
  SELECT @CdslStatus305 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 305      
  SELECT @CdslStatus511 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 511      
    
    
  SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 904 AND [Name] = 'Delivery Free of Payment (Inter DP) Instruction'      
  SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
  
  SELECT @cdsl= RefSegmentEnumId FROM  dbo.RefSegmentEnum WHERE Segment = 'CDSL'  
  SELECT @nsdl= RefSegmentEnumId FROM  dbo.RefSegmentEnum WHERE Segment = 'NSDL'   
  
  SELECT   
   @NoOfOOPClient = CONVERT( INT , [Value])  
  FROM dbo.SysAmlReportSetting   
  WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Entity'  
  
  SELECT   
   @NoOfInTxn = CONVERT( INT , [Value])  
  FROM dbo.SysAmlReportSetting   
  WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Days'  
  
  SELECT   
   @TotalTxnValue = CONVERT(DECIMAL(28,2),[Value])   
  FROM dbo.SysAmlReportSetting   
  WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Total_Turnover'  
  
   
 SELECT DISTINCT  
  RefClientId  
 INTO #clientsToExclude  
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex  
 WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)   
  AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)  
  
 CREATE TABLE #tradeData (        
   TransactionId INT,      
   RefClientId INT,          
   RefSegmentId INT,          
   RefIsinId INT,       
   Quantity INT,          
   CounterBOId VARCHAR(16),  
   OtherClientId INT,  
   BusinessDate DATETIME  
  )    
  
  INSERT INTO #tradeData(TransactionId,RefClientId,RefSegmentId,RefIsinId,Quantity,CounterBOId,OtherClientId,BusinessDate)  
 SELECT      
  dp.CoreDpTransactionId AS TransactionId,  
  dp.RefClientId,      
  dp.RefSegmentId,  
  dp.RefIsinId,  
  dp.Quantity,  
  dp.CounterBOId,  
  0,  
  dp.BusinessDate       
  FROM dbo.CoreDpTransaction dp    
  LEFT JOIN #clientsToExclude clex ON clex.RefClientId = dp.RefClientId  
  WHERE clex.RefClientId IS NULL  
   AND (dp.BusinessDate BETWEEN @StartDate AND @EndDate)      
   AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))      
    OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))      
   AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')      
   AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')     
   AND (dp.BuySellFlag = 'D' OR dp.BuySellFlag = 'S') 
     
   INSERT INTO #tradeData(TransactionId,RefClientId,RefSegmentId,RefIsinId,Quantity,CounterBOId,OtherClientId,BusinessDate)  
   SELECT    
    dp.CoreDPTransactionChangeHistoryId,  
    dp.RefClientId,  
    dp.RefSegmentId,  
    dp.RefIsinId,  
    dp.Quantity,  
    dp.OtherDPId,  
    dp.OtherClientId,  
    dp.ExecutionDate    
  FROM   dbo.CoreDPTransactionChangeHistory dp   
  LEFT JOIN #clientsToExclude clex ON clex.RefClientId = dp.RefClientId  
  WHERE clex.RefClientId IS NULL  
   AND (dp.ExecutionDate BETWEEN @StartDate AND @EndDate)      
   AND (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')      
   AND dp.RefDpTransactionTypeId IN ( @NsdlType904, @NsdlType925)      
   AND dp.OrderStatusTo = 51   
    
  DROP TABLE #clientsToExclude  
    
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
     ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId , isin.BusinessDate ORDER BY bhav.RefSegmentId) AS RN          
   INTO #presentBhavIdsTemp          
   FROM #selectedIsins isin          
   INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = isin.RefIsinId         
   WHERE bhav.[Date] = isin.BusinessDate     
    
  SELECT         
   temp.RefIsinId,          
   temp.[Close] ,
   temp.BusinessDate
  INTO #presentBhavIds          
  FROM #presentBhavIdsTemp temp          
  WHERE (temp.RN = 1)  
    
  DROP TABLE #presentBhavIdsTemp  
  DROP TABLE #selectedIsins  
  
	SELECT
		t1.RefClientId,
		t1.RefSegmentId,
		COALESCE(SUM(CONVERT(DECIMAL(28,2), ROUND(t1.Quantity * pIds.[Close],2))),0) AS TxnValue ,
		COUNT(t1.TransactionId) AS OutTxn,
		STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(100), t2.TransactionId) COLLATE DATABASE_DEFAULT       
			FROM #tradeData t2    
		WHERE t1.RefClientId = t2.RefClientId AND t1.RefSegmentId = t2.RefSegmentId  
		FOR XML PATH ('')), 1, 1, '') AS TxnIds
		,
		COUNT(DISTINCT (CHECKSUM(t1.CounterBOId,ISnull(convert(varchar(max),t1.OtherClientId),''))) + CHECKSUM(REVERSE(t1.CounterBOId),REVERSE(convert(varchar(max),isnull(t1.OtherClientId,'')))) ) OutAccount
	INTO #finaldata
	FROM #tradeData t1
	INNER JOIN #presentBhavIds pIds ON t1.RefIsinId = pIds.RefIsinId
	GROUP BY t1.RefClientId, t1.RefSegmentId
  
  --DROP TABLE #tradeData  
  select
  count(*)
  from #tradeData t1
  	GROUP BY t1.RefClientId, t1.RefSegmentId
  
  SELECT  
  ISNULL('IN'+CONVERT(VARCHAR(MAX),ref.DpId),'') AS DpId,  
  ref.RefClientId,  
  ref.[Name] AS ClientName,  
  ref.ClientId AS ClientId,  
  fd.RefSegmentId,  
  @StartDate AS FromDate,  
  @EndDate AS ToDate,  
  fd.OutTxn AS OutTxn,  
  fd.TxnValue AS OutValue,  
  fd.OutAccount AS OutAccounts,  
  fd.TxnIds  
  FROM #finaldata fd
  INNER JOIN dbo.RefClient ref ON  fd.TxnValue >= @TotalTxnValue AND fd.OutTxn >= @NoOfInTxn AND fd.OutAccount >= @NoOfOOPClient AND ref.RefClientId = fd.RefClientId  
  LEFT JOIN dbo.CoreAmlScenarioAlert alerts ON   
  (  
   @IsAlertDulicationAllowedInternal = 0 AND alerts.RefAmlReportId = @ReportIdInternal   
   AND alerts.RefClientId = ref.RefClientId AND alerts.TransactionFromDate = @StartDate  
   AND alerts.TransactionToDate = @EndDate AND alerts.MoneyIn = fd.TxnValue   
   AND alerts.MoneyInCount = fd.OutTxn AND alerts.MoneyOutCount = fd.OutAccount AND alerts.[Description] = fd.TxnIds   
   AND alerts.RefSegmentEnumId = fd.RefSegmentId  
  )  
  WHERE alerts.CoreAmlScenarioAlertId IS NULL  
  
  --DROP TABLE #presentBhavIds  
  --DROP TABLE #finaldata  
		--DROP TABLE #presentBhavIds
		--DROP TABLE #tradeDataWithUniqueOpposite
	--	insert into #tradeData values(4,156,2,1,2,2,2,'2022-03-01 00:00:00.000')

	--	select refclientid,refsegmentid, COUNT(DISTINCT (CHECKSUM(T1.CounterBOId,T1.OtherClientId)) + CHECKSUM(REVERSE(CounterBOId),REVERSE(OtherClientId)) )
 --counts
	--	from #tradeData t1
	--	group by refclientid,refsegmentid

	--	select distinct CounterBOId,OtherClientId
	--	from #tradeData
	--	group by refclientid,refsegmentid




