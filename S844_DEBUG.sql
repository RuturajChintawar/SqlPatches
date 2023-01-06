-- S844-debug
GO
EXEC dbo.Sys_DropIfExists 'AML_GetDPTransactionManyToOneCDSLAndNSDL_S844_Custom','P'
GO
GO
 CREATE PROCEDURE dbo.AML_GetDPTransactionManyToOneCDSLAndNSDL_S844_Custom (        
 @RunDate DATETIME,      
 @NoOfOOPClientInternal  INT,  
 @NoOfInTxnInternal  INT,
 @TotalTxnValueInternal Decimal(28,2),
 @IsAlertDulicationAllowed BIT = 1
)        
AS        
BEGIN     
	   DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT,  @EndDate DATETIME , @StartDate DATETIME , @NsdlType905 INT, @NsdlType926 INT, @CdslType2 INT, @CdslType3 INT, @CdslType5 INT,     
     @CdslStatus305 INT, @CdslStatus511 INT ,@cdsl INT,@nsdl INT  ,@NoOfOOPClient INT, @NoOfInTxn INT, @TotalTxnValue DECIMAL(28,2) , @IsAlertDulicationAllowedInternal BIT
 
	 SELECT @ReportIdInternal = RefAmlReportId FROM dbo.RefAmlReport WHERE [Code] = 'S844' 
	 SET @RunDateInternal = @RunDate

	 SET @IsAlertDulicationAllowedInternal = @IsAlertDulicationAllowed

	 SET @EndDate = DATEADD(DAY, -(DAY(@RunDateInternal)), @RunDateInternal) + CONVERT(DATETIME, '23:59:59.000')
	 SET @StartDate = DATEADD(mm, DATEDIFF(mm, 0, @RunDateInternal) - 1, 0) 

	 SELECT @CdslType2 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 2 AND [Name] = 'Transactions within DP'    
	 SELECT @CdslType3 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 3 AND [Name] = 'Transactions across DPs'    
	 SELECT @CdslType5 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 5 AND [Name] = 'Inter-depository'    
      
	 SELECT @CdslStatus305 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 305    
	 SELECT @CdslStatus511 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 511    
	 
	 
	 SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 905 AND [Name] = 'Receipt Free of Payment (Inter DP) Instruction'    
	 SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)'  

	 SELECT @cdsl= RefSegmentEnumId FROM  dbo.RefSegmentEnum where Segment='CDSL'
	 SELECT @nsdl= RefSegmentEnumId FROM  dbo.RefSegmentEnum where Segment='NSDL' 

	 SELECT 
			@NoOfOOPClient = @NoOfOOPClientInternal

	 SELECT 
			@NoOfInTxn = @NoOfInTxnInternal

	 SELECT 
			@TotalTxnValue = @TotalTxnValueInternal

	
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
	  OtherClientId VARCHAR(MAX),
	  BusinessDate DATETIME,
	  RefOppSegmentId INT --1 FOR OPP 0 FOR SAME
	 )  

	 INSERT INTO #tradeData(TransactionId,RefClientId,RefSegmentId,RefIsinId,Quantity,CounterBOId,OtherClientId,BusinessDate, RefOppSegmentId)
	SELECT    
		dp.CoreDpTransactionId AS TransactionId,
		dp.RefClientId,    
		dp.RefSegmentId,
		dp.RefIsinId,
		dp.Quantity,
		dp.CounterBOId,
		'0',
		dp.BusinessDate ,
		 CASE WHEN SUBSTRING(ISNULL(dp.CounterBOId,''),1,2)='IN' THEN 1 ELSE 0 END     
	 FROM dbo.CoreDpTransaction dp  
	 LEFT JOIN #clientsToExclude clex ON clex.RefClientId = dp.RefClientId
	 WHERE dp.RefSegmentId = @cdsl AND clex.RefClientId IS NULL
	  AND (dp.BusinessDate BETWEEN @StartDate AND @EndDate)    
	  AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))    
	   OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))    
	  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')    
	  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')   
	  AND (dp.BuySellFlag = 'C' OR dp.BuySellFlag = 'B')
	  
	  INSERT INTO #tradeData(TransactionId,RefClientId,RefSegmentId,RefIsinId,Quantity,CounterBOId,OtherClientId,BusinessDate, RefOppSegmentId)
	  SELECT  
		  dp.CoreDPTransactionChangeHistoryId,
		  dp.RefClientId,
		  dp.RefSegmentId,
		  dp.RefIsinId,
		  dp.Quantity,
			CASE WHEN dp.RefDpTransactionTypeId = @NsdlType905 THEN ISNULL(dp.OtherDPId,'') ELSE ISNULL(dp.OtherDPCode,'') END,  
			CASE WHEN dp.RefDpTransactionTypeId = @NsdlType905 THEN CONVERT(VARCHAR(MAX),dp.OtherClientId) ELSE ISNULL(dp.OtherClientCode,'') END,  
		  
		  dp.ExecutionDate ,
			CASE WHEN dp.RefDpTransactionTypeId = @NsdlType926 AND SUBSTRING(ISNULL(dp.OtherDPCode,''),1,2) ='IN' THEN 0
				 WHEN dp.RefDpTransactionTypeId = @NsdlType905 AND SUBSTRING(ISNULL(dp.OtherDPId,''),1,2) = 'IN' THEN 0
				ELSE 1
			END 
	 FROM   dbo.CoreDPTransactionChangeHistory dp 
	 LEFT JOIN #clientsToExclude clex ON clex.RefClientId = dp.RefClientId
	 WHERE dp.RefSegmentId = @nsdl AND clex.RefClientId IS NULL
	  AND (dp.ExecutionDate BETWEEN @StartDate AND @EndDate)    
	  AND (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')    
	  AND dp.RefDpTransactionTypeId IN ( @NsdlType905, @NsdlType926)    
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
				COUNT(1) AS InTxn,
				STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(100), t2.TransactionId) COLLATE DATABASE_DEFAULT       
					FROM #tradeData t2    
				WHERE t1.RefClientId = t2.RefClientId AND t1.RefSegmentId = t2.RefSegmentId  AND t1.RefOppSegmentId = t2.RefOppSegmentId
				FOR XML PATH ('')), 1, 1, '') AS TxnIds,
				COUNT(DISTINCT (CHECKSUM(t1.CounterBOId, ISNULL(t1.OtherClientId,'')))) InAccount
		INTO #finaldata
		FROM #tradeData t1
		INNER JOIN #presentBhavIds pIds ON t1.RefIsinId = pIds.RefIsinId AND t1.BusinessDate = pIds.BusinessDate
		GROUP BY t1.RefClientId, t1.RefSegmentId, t1.RefOppSegmentId

		DROP TABLE #tradeData

		SELECT
		ISNULL('IN'+CONVERT(VARCHAR(MAX),ref.DpId),'') DpId,
		ref.RefClientId,
		ref.[Name] AS ClientName,
		ref.ClientId AS ClientId,
		fd.RefSegmentId,
		@StartDate AS FromDate,
		@EndDate AS ToDate,
		fd.InTxn AS InTxn,
		fd.TxnValue AS InValue,
		fd.InAccount AS InAccounts,
		fd.TxnIds
		FROM #finaldata fd
		INNER JOIN dbo.RefClient ref ON  fd.TxnValue >= @TotalTxnValue AND fd.InTxn >= @NoOfInTxn AND fd.InAccount >= @NoOfOOPClient AND ref.RefClientId = fd.RefClientId
		LEFT JOIN dbo.CoreAmlScenarioAlert alerts ON 
		(
			@IsAlertDulicationAllowedInternal = 0 AND alerts.RefAmlReportId = @ReportIdInternal 
			AND alerts.RefClientId = ref.RefClientId AND alerts.TransactionFromDate = @StartDate
			AND alerts.TransactionToDate = dbo.GetDateWithoutTime(@EndDate) AND alerts.MoneyIn = fd.TxnValue 
			AND alerts.MoneyInCount = fd.InTxn AND alerts.MoneyOutCount = fd.InAccount AND alerts.[Description] = fd.TxnIds 
			AND alerts.RefSegmentEnumId = fd.RefSegmentId
		)
		WHERE alerts.CoreAmlScenarioAlertId IS NULL

 END    
 CoreClientKeyValueInfo
 
GO
GO
EXEC dbo.AML_GetDPTransactionManyToOneCDSLAndNSDL_S844_Custom
	@RunDate = '2022-04-01', -- rundate (yyyy-MM-dd),
    @NoOfOOPClientInternal = 1, -- No of Opp Client Id =>
   @NoOfInTxnInternal = 1, --No of In transactions during the month = >
   @TotalTxnValueInternal   =  1 -- Total In Transactions Value during the month = >
	
GO
GO
EXEC dbo.Sys_DropIfExists 'AML_GetDPTransactionManyToOneCDSLAndNSDL_S844_Custom','P'
GO