--File:Tables:dbo:RefAmlReport:DML
--RC-WEB-77090--START
GO
DECLARE @RefAlertRegisterCaseTypeId INT, @FrequencyFlagRefEnumValueId INT,@ExchangeRefEnumvalueId INT

SELECT @RefAlertRegisterCaseTypeId = RefAlertRegisterCaseTypeId FROM dbo.RefAlertRegisterCaseType WHERE [Name] = 'AML'
SELECT @FrequencyFlagRefEnumValueId = dbo.GetEnumValueId('PeriodFrequency', 'Daily')

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
	ScenarioNo,
	[Description]
) VALUES (
	1278,
	'S847 High value one side off market transaction',
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	1,
	'S847',
	@RefAlertRegisterCaseTypeId,
	0, 
	'S847HighValueOneSideOffMarketTransaction',
	1,
	@FrequencyFlagRefEnumValueId,
	847,
	'The objective of the scenario is:<br>
	a. To identify customers buying shares on market and selling it offmarket or vice versa AND, <br>
	b. The percentage of Off market transactions compared to the market transactions is greater than or equal to the set threshold.<br>'
)
GO
--RC-WEB-77090--END

--File:Tables:dbo:SysAmlReportSetting:DML
--RC-WEB-77090--START
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S847 High value one side off market transaction'

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
	'30',
	1,
	'Lookback period',
	1,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
),(
	@AmlReportId,
	'Transaction_Value',
	'500000',
	1,
	'Transaction value',
	1,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)

GO
--RC-WEB-77090--END

--File:StoredProcedures:dbo:AML_GetHighValueOneSideOffMarketTransaction
--RC-WEB-77090--START
GO
CREATE PROCEDURE dbo.AML_GetHighValueOneSideOffMarketTransaction (    
	 @RunDate DATETIME,    
	 @ReportId INT    
)    
AS    
BEGIN 
  DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @StartDate DATETIME , 
	 @NsdlType904 INT, @NsdlType925 INT, @NsdlType905 INT,  @NsdlType926 INT,
	 @CdslType2 INT, @CdslType3 INT, @CdslType5 INT,@CdslStatus305 INT, @CdslStatus511 INT ,
	 @cdsl INT,@nsdl INT , @BSEId INT, @NSEId INT, @LookBackPeriod INT, @TxnValue DECIMAL(28,2), @CDSLClientDatabaseId INT , @NSDLClientDatabaseId INT
   
  SET @ReportIdInternal = @ReportId     
  SET @RunDateInternal = @RunDate  

  SELECT @CdslType2 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 2 AND [Name] = 'Transactions within DP'      
  SELECT @CdslType3 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 3 AND [Name] = 'Transactions across DPs'      
  SELECT @CdslType5 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 5 AND [Name] = 'Inter-depository'      
        
  SELECT @CdslStatus305 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 305      
  SELECT @CdslStatus511 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 511      
    
  SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 904 AND [Name] = 'Delivery Free of Payment (Inter DP) Instruction'      
  SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
  
  SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 905 AND [Name] = 'Receipt Free of Payment (Inter DP) Instruction'    
  SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)'    

  SELECT @cdsl= RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'CDSL'  
  SELECT @nsdl= RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSDL' 
  
  SET @CDSLClientDatabaseId = (SELECT enum.RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum enum WHERE enum.DatabaseType = 'CDSL')
  SET @NSDLClientDatabaseId = (SELECT enum.RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum enum WHERE enum.DatabaseType = 'NSDL')

  SELECT @BSEId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'BSE_CASH'    
  SELECT @NSEId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSE_CASH'  

  SELECT   
   @LookBackPeriod = CONVERT( INT , [Value])  
  FROM dbo.SysAmlReportSetting  syst
  WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Number_Of_Days'  
  
  SELECT   
   @TxnValue = CONVERT( DECIMAL(28,2) , [Value])  
  FROM dbo.SysAmlReportSetting  syst 
  WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Transaction_Value'  

  SET @StartDate = DATEADD( DAY, -(@LookBackPeriod-1), @RunDateInternal)  
  
  
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
	AND dp.BusinessDate BETWEEN @StartDate AND  @RunDateInternal  
	AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))      
	OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))  
	
	 INSERT INTO #tradeData(RefClientId,RefSegmentId,RefIsinId,Quantity,BusinessDate,OnOffMarketFlag,BuySellFlag)  
	   SELECT     
		dp.RefClientId,  
		dp.RefSegmentId,  
		dp.RefIsinId,  
		dp.Quantity,
		dp.ExecutionDate,
		CASE WHEN (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')  THEN 1
		ELSE 0 END,
		CASE WHEN dp.RefDpTransactionTypeId IN ( @NsdlType904, @NsdlType925) THEN 0
		ELSE 1 END
	  FROM   dbo.CoreDPTransactionChangeHistory dp   
	  LEFT JOIN #clientsToExclude clex ON clex.RefClientId = dp.RefClientId  
	  WHERE dp.RefSegmentId = @nsdl AND clex.RefClientId IS NULL  
	   AND dp.ExecutionDate BETWEEN @StartDate AND  @RunDateInternal    
	   AND dp.RefDpTransactionTypeId IN ( @NsdlType904, @NsdlType925,@NsdlType905,@NsdlType926)      
	   AND dp.OrderStatusTo = 51  
	
	SELECT
		tr.RefClientId, 
		tr.RefSegmentId, 
		tr.RefIsinId, 
		tr.OnOffMarketFlag, 
		tr.BuySellFlag,
		SUM(tr.Quantity) AS Quantity
	INTO #tempData
	FROM #tradeData tr
	WHERE tr.BusinessDate = @RunDateInternal
	GROUP BY tr.RefClientId, tr.RefSegmentId, tr.RefIsinId, tr.OnOffMarketFlag, tr.BuySellFlag

	SELECT
		tr.RefClientId, 
		tr.RefSegmentId, 
		tr.RefIsinId, 
		tr.OnOffMarketFlag, 
		tr.BuySellFlag,
		tr.BusinessDate,
		SUM(tr.Quantity) AS Quantity
    INTO #tempoppData
	FROM #tradeData tr
	GROUP BY tr.RefClientId, tr.RefSegmentId, tr.RefIsinId, tr.OnOffMarketFlag, tr.BuySellFlag, tr.BusinessDate

	SELECT
		t.*
	INTO #oppData
	FROM(SELECT
				tr.RefClientId, 
				tr.RefSegmentId, 
				tr.RefIsinId, 
				tr.OnOffMarketFlag, 
				tr.BuySellFlag,
				tr.BusinessDate,
				tr.Quantity,
				ROW_NUMBER() OVER(PARTITION BY tr.RefClientId,tr.RefSegmentId, tr.RefIsinId, tr.OnOffMarketFlag,tr.BuySellFlag ORDER BY tr.BusinessDate DESC) RN
				FROM #tempoppData tr) t
	WHERE t.RN = 1

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
		DISTINCT
		ids.RefIsinId
	INTO #tempIsindata
	FROM #presentBhavIds ids

	SELECT
		z.*
	INTO #tempInstrumentData
	FROM (
		SELECT
		 t.*,
		 ROW_NUMBER() OVER(PARTITION BY t.RefIsinId ORDER BY t.rn DESC) tempN
		FROM (SELECT 
			ids.RefIsinId,
			inst.RefInstrumentId,
			inst.[Name] AS instName,
			CASE WHEN inst.RefSegmentId = @NSEId THEN 0 ELSE 1 END rn
		FROM #tempIsindata ids
		INNER JOIN dbo.RefIsin isin  ON isin.RefIsinId = ids.RefIsinId
		LEFT JOIN dbo.RefInstrument inst ON inst.Isin = isin.[Name] AND inst.RefSegmentId IN ( @BSEId, @NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A' 
			AND isin.BSEInstrumentId IS NOT NULL AND isin.NSEInstrumentId IS NOT NULL ) t
			) z WHERE z.tempN = 1
		
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
		oop.Quantity AS OppTxnQty,
		oopBhavIds.[Close] AS OppTxnRate,
		oop.Quantity * oopBhavIds.[Close] AS OppTxnTO,
		inst.RefInstrumentId,
		ISNULL(inst.instName,isin.IsinShortName) AS Insturment
	FROM #tempData temp
	INNER JOIN #oppData oop ON oop.RefClientId = temp.RefClientId AND oop.RefIsinId = temp.RefIsinId AND oop.RefSegmentId = temp.RefSegmentId AND oop.OnOffMarketFlag + temp.OnOffMarketFlag = 1 
			AND oop.BuySellFlag + temp.BuySellFlag = 1
	INNER JOIN #presentBhavIds tempBhavIds ON tempBhavIds.RefIsinId = temp.RefIsinId AND tempBhavIds.BusinessDate = @RunDateInternal AND temp.Quantity * tempBhavIds.[Close] >= @TxnValue
	INNER JOIN #presentBhavIds oopBhavIds ON oopBhavIds.RefIsinId = oop.RefIsinId AND oopBhavIds.BusinessDate = oop.BusinessDate
	INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = temp.RefIsinId
	INNER JOIN dbo.RefClient cli ON cli.RefClientId = temp.RefClientId
	INNER JOIN dbo.RefSegmentEnum enum ON enum.RefSegmentEnumId = oop.RefSegmentId
	INNER JOIN #tempInstrumentData inst ON inst.RefIsinId = isin.RefIsinId 
END
GO
--RC-WEB-77090--END

--File:Tables:dbo:RefProcess:DML
--RC-WEB-77090--START
GO
DECLARE	 @EnumValueId INT, @RefAmlReportId INT


SELECT @EnumValueId = dbo.GetEnumValueId('ProcessType','Simple')
SELECT @RefAmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S847 High value one side off market transaction'

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
	'S847 High value one side off market transaction',
	'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S847HighValueOneSideOffMarketTransaction',
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
	'S847',
	1,
	'S847 High value one side off market transaction',
	1000
)
GO
--RC-WEB-77090--END