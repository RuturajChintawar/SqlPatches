--WEB-70761-START-RC
GO
DECLARE @RefAlertRegisterCaseTypeId INT, @FrequencyFlagRefEnumValueId INT

SELECT @RefAlertRegisterCaseTypeId = RefAlertRegisterCaseTypeId FROM dbo.RefAlertRegisterCaseType WHERE [Name] = 'AML'
SELECT @FrequencyFlagRefEnumValueId = dbo.GetEnumValueId('PeriodFrequency', 'Monthly')


SET IDENTITY_INSERT dbo.RefAmlReport ON
INSERT INTO dbo.RefAmlReport (
	RefAmlReportId,
	[Name],
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn,
	RuleWritingEnabled,
	Code,
	RefAlertRegisterCaseTypeId,
	IsRuleRequired, 
	ClassName,
	IsLicensed,
	FrequencyFlagRefEnumValueId,
	ScenarioNo
) VALUES (
	1267,
	'S843 DP Transaction One to Many - CDSL & NSDL',
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	1,
	'S843',
	@RefAlertRegisterCaseTypeId,
	0, 
	'S843DPTransactionOneToManyCDSLAndNSDL',
	1,
	@FrequencyFlagRefEnumValueId,
	843
)
GO
--WEB-70761-END-RC
--WEB-70761-START-RC
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S843 DP Transaction One to Many - CDSL & NSDL'

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
	'Number_Of_Entity',
	'0',
	1,
	'No of Opp Client Id  =>',
	1,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
),(
	@AmlReportId,
	'Number_Of_Days',
	'0',
	1,
	'No of Out transactions during the month =>',
	2,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
),(
	@AmlReportId,
	'Total_Turnover',
	'0',
	1,
	'Total Out Transactions Value during the month  =>',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
--WEB-70761-END-RC
--WEB-70761-START-RC
GO
DECLARE	 @EnumValueId INT, @RefAmlReportId INT


SELECT @EnumValueId = dbo.GetEnumValueId('ProcessType','Simple')
SELECT @RefAmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S843 DP Transaction One to Many - CDSL & NSDL'

INSERT INTO dbo.RefProcess (
	[Name],
	ClassName,
	AssemblyName,
	IsActive,
	IsScheduleEditable,
	AddedBy,
	AddedOn,
	EditedOn,
	LastEditedBy,
	RefAmlReportId,
	ProcessTypeRefEnumValueId,
	IsCompanyWise,
	Code,
	EnableRunDateSelection,
	DisplayName,
	LockingGroupId
) VALUES (
	'S843 DP Transaction One to Many - CDSL & NSDL',
	'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S843DPTransactionOneToManyCDSLAndNSDL',
	'TSS.SmallOfficeWeb.ManageData',
	1,
	1,
	'System',
	GETDATE(),
	GETDATE(),
	'System',
	@RefAmlReportId,
	@EnumValueId,
	0,
	'S843',
	1,
	'S843 DP Transaction One to Many - CDSL & NSDL',
	1000
)
GO
--WEB-70761-END-RC
--WEB-70761-START-RC
GO
ALTER PROCEDURE dbo.AML_GetDPTransactionOneToManyCDSLAndNSDL (      
 @RunDate DATETIME,      
 @ReportId INT,  
 @IsAlertDulicationAllowed BIT = 1      
)      
AS      
BEGIN   
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
   OtherClientId VARCHAR(Max),  
   BusinessDate DATETIME ,
   RefOppSegmentId INT --1 FOR OPP 0 FOR SAME
  )    
  
  INSERT INTO #tradeData(TransactionId,RefClientId,RefSegmentId,RefIsinId,Quantity,CounterBOId,OtherClientId,BusinessDate, RefOppSegmentId)  
 SELECT      
	  dp.CoreDpTransactionId AS TransactionId,  
	  dp.RefClientId,      
	  dp.RefSegmentId,  
	  dp.RefIsinId,  
	  dp.Quantity,  
	  ISNULL(dp.CounterBOId,''),  
	  '0',  
	  dp.BusinessDate  ,
	  CASE WHEN SUBSTRING(ISNULL(dp.CounterBOId,''),1,2)='IN' THEN 1 ELSE 0 END

  FROM dbo.CoreDpTransaction dp    
  LEFT JOIN #clientsToExclude clex ON clex.RefClientId = dp.RefClientId  
  WHERE dp.RefSegmentId = @cdsl AND clex.RefClientId IS NULL  
   AND (dp.BusinessDate BETWEEN @StartDate AND @EndDate)      
   AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))      
    OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))      
   AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')      
   AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')     
   AND (dp.BuySellFlag = 'D' OR dp.BuySellFlag = 'S') 
     
   INSERT INTO #tradeData(TransactionId,RefClientId,RefSegmentId,RefIsinId,Quantity,CounterBOId,OtherClientId,BusinessDate, RefOppSegmentId)  
   SELECT    
		dp.CoreDPTransactionChangeHistoryId,  
		dp.RefClientId,  
		dp.RefSegmentId,  
		dp.RefIsinId,  
		dp.Quantity,  
		CASE WHEN dp.RefDpTransactionTypeId = @NsdlType904 THEN ISNULL(dp.OtherDPId,'') ELSE ISNULL(dp.OtherDPCode,'') END,  
		CASE WHEN dp.RefDpTransactionTypeId = @NsdlType904 THEN CONVERT(VARCHAR(MAX),dp.OtherClientId) ELSE ISNULL(dp.OtherClientCode,'') END,  
		dp.ExecutionDate  ,
		CASE WHEN dp.RefDpTransactionTypeId = @NsdlType925 AND SUBSTRING(ISNULL(dp.OtherDPCode,''),1,2) ='IN' THEN 0
			 WHEN dp.RefDpTransactionTypeId = @NsdlType904 AND SUBSTRING(ISNULL(dp.OtherDPId,''),1,2) = 'IN' THEN 0
			ELSE 1
		END
  FROM   dbo.CoreDPTransactionChangeHistory dp   
  LEFT JOIN #clientsToExclude clex ON clex.RefClientId = dp.RefClientId  
  WHERE dp.RefSegmentId = @nsdl AND clex.RefClientId IS NULL  
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
   temp.[Close]  ,
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
		COUNT(1) AS OutTxn,
		STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(100), t2.TransactionId) COLLATE DATABASE_DEFAULT       
			FROM #tradeData t2    
		WHERE t1.RefClientId = t2.RefClientId AND t1.RefSegmentId = t2.RefSegmentId  AND t1.RefOppSegmentId = t2.RefOppSegmentId
		FOR XML PATH ('')), 1, 1, '') AS TxnIds,
		COUNT(DISTINCT (CHECKSUM(t1.CounterBOId, ISNULL(t1.OtherClientId,'')))) OutAccount
	INTO #finaldata
	FROM #tradeData t1
	INNER JOIN #presentBhavIds pIds ON t1.RefIsinId = pIds.RefIsinId and pIds.BusinessDate = t1.BusinessDate
	GROUP BY t1.RefClientId, t1.RefSegmentId ,t1.RefOppSegmentId
  
  DROP TABLE #tradeData  
  
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
   AND alerts.TransactionToDate = dbo.GetDateWithoutTime(@EndDate) AND alerts.MoneyIn = fd.TxnValue   
   AND alerts.MoneyInCount = fd.OutTxn AND alerts.MoneyOutCount = fd.OutAccount AND alerts.[Description] = fd.TxnIds   
   AND alerts.RefSegmentEnumId = fd.RefSegmentId  
  )  
  WHERE alerts.CoreAmlScenarioAlertId IS NULL 
 END  
GO
--WEB-70761-END-RC
--exec AML_GetDPTransactionOneToManyCDSLAndNSDL '03-22-2022',1267
Ref