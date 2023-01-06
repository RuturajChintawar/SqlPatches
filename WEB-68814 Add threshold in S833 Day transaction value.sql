GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S833 High Value Off Market Transaction in a Specified Period (CDSL & NSDL)'

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
	'Transaction_Value',
	'True',
	0,
	'Day Transaction Value =>',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S836 Client High Value Off Market Transaction vis-a-vis Modification in Demat Account (CDSL & NSDL)'

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
	'Transaction_Value',
	'True',
	0,
	'No. of clients in a group >1',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO

 ALTER PROCEDURE dbo.AML_GetHighValueOffMarketTransactioninaSpecifiedPeriod (    
 @RunDate DATETIME,    
 @ReportId INT    
)    
AS    
BEGIN    
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @SingleValue DECIMAL(28, 2), @OffMarketTrans INT,     
  @NsdlId INT, @CdslId INT, @ToDate DATETIME, @30DayDate DATETIME, @CdslType2 INT, @CdslType3 INT,    
  @CdslType5 INT, @CdslStatus305 INT, @CdslStatus511 INT, @NsdlType904 INT,    
  @NsdlType905 INT, @NsdlType925 INT, @NsdlType926 INT, @BSEId INT, @NSEId INT,    
  @LastBhavCopyDate DATETIME , @DayTranaction DECIMAL(28, 2)   
    
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)    
 SET @ReportIdInternal = @ReportId    
 SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')    
 SET @30DayDate = CONVERT(DATETIME, DATEDIFF(dd, 30, @RunDateInternal))    
 SELECT @SingleValue = CONVERT(DECIMAL(28, 2), [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Threshold_Quantity'    
    
 SELECT @OffMarketTrans = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Quantity'  

 SELECT @DayTranaction = CONVERT(DECIMAL(28, 2), [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Transaction_Value' 
    
 SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'CDSL'    
 SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSDL'    
 SELECT @BSEId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'BSE_CASH'    
 SELECT @NSEId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSE_CASH'    
 SELECT @CdslType2 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 2 AND [Name] = 'Transactions within DP'    
 SELECT @CdslType3 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 3 AND [Name] = 'Transactions across DPs'    
 SELECT @CdslType5 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE CdslCode = 5 AND [Name] = 'Inter-depository'    
 SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 904 AND [Name] = 'Delivery Free of Payment (Inter DP) Instruction'    
 SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 905 AND [Name] = 'Receipt Free of Payment (Inter DP) Instruction'    
 SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
 SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)'    
 SELECT @CdslStatus305 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 305    
 SELECT @CdslStatus511 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 511    
    
 SELECT    
  RefClientId    
 INTO #clientsToExclude    
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
 WHERE (ExcludeAllScenarios = 1 OR RefAmlReportId = @ReportIdInternal)     
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)    
    
 SELECT DISTINCT    
  dp.RefClientId    
 INTO #runDateClientsCdsl    
 FROM dbo.CoreDpTransaction dp    
 LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId    
 WHERE dp.RefSegmentId = @CdslId    
  AND dp.BusinessDate = @RunDateInternal    
  AND clEx.RefClientId IS NULL    
  AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))    
   OR (dp.RefDpTransactionTypeId =  @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))    
  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')    
  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')    
    
 SELECT DISTINCT    
  dp.RefClientId    
 INTO #runDateClientsNsdl    
 FROM dbo.CoreDPTransactionChangeHistory dp    
 LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId    
 WHERE dp.RefSegmentId = @NsdlId    
  AND dp.ExecutionDate = @RunDateInternal    
  AND clEx.RefClientId IS NULL     
  AND (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')    
  AND dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType905, @NsdlType925, @NsdlType926)    
  AND dp.OrderStatusTo = 51    
    
 DROP TABLE #clientsToExclude    
    
 CREATE TABLE #tradeData (  
  TransactionId INT,  
  RefClientId INT,    
  RefSegmentId INT,    
  RefIsinId INT,    
  DC INT,    
  Quantity INT,    
  BusinessDate DATETIME,    
  RefDpTransactionTypeId INT    
 )    
    
 INSERT INTO #tradeData(TransactionId, RefClientId, RefSegmentId, RefIsinId, DC, Quantity, BusinessDate, RefDpTransactionTypeId)    
 SELECT    
  dp.CoreDpTransactionId,  
  dp.RefClientId,    
  dp.RefSegmentId,    
  dp.RefIsinId,    
  CASE WHEN dp.BuySellFlag = 'C' OR dp.BuySellFlag = 'B' THEN 1 ELSE 0 END AS DC,    
  dp.Quantity,    
  dp.BusinessDate,    
  dp.RefDpTransactionTypeId    
 FROM #runDateClientsCdsl cl    
 INNER JOIN dbo.CoreDpTransaction dp ON cl.RefClientId = dp.RefClientId    
 WHERE dp.RefSegmentId = @CdslId    
  AND (dp.BusinessDate BETWEEN @30DayDate AND @ToDate)    
  AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))    
   OR (dp.RefDpTransactionTypeId =  @CdslType5 AND dp.RefDpTransactionStatusId = @CdslStatus511))    
  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')    
  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')    
    
 DROP TABLE #runDateClientsCdsl    
    
 INSERT INTO #tradeData(TransactionId, RefClientId, RefSegmentId, RefIsinId, DC, Quantity, BusinessDate, RefDpTransactionTypeId)    
 SELECT     
  dp.CoreDPTransactionChangeHistoryId,  
  dp.RefClientId,    
  dp.RefSegmentId,    
  dp.RefIsinId,    
  CASE WHEN dp.RefDpTransactionTypeId IN (@NsdlType905, @NsdlType926)    
  THEN 1     
  WHEN dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType925)    
  THEN 0 END AS DC,    
  CONVERT(INT, dp.Quantity) AS Quantity,    
  dp.ExecutionDate AS BusinessDate,    
  dp.RefDpTransactionTypeId    
 FROM #runDateClientsNsdl cl    
 INNER JOIN dbo.CoreDPTransactionChangeHistory dp ON cl.RefClientId = dp.RefClientId    
 WHERE dp.RefSegmentId = @NsdlId    
  AND (dp.ExecutionDate BETWEEN @30DayDate AND @ToDate)    
  AND (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')    
  AND dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType905, @NsdlType925, @NsdlType926)    
  AND dp.OrderStatusTo = 51    
    
 DROP TABLE #runDateClientsNsdl    
    
 SELECT     
  t1.RefClientId,    
  t1.RefSegmentId,    
  t1.RefIsinId,    
  t1.DC,    
  t1.BusinessDate,    
  SUM(t1.Quantity) AS Qty,    
  STUFF((SELECT DISTINCT ', ' + ty.[Name]     
   FROM #tradeData t2    
   INNER JOIN dbo.RefDpTransactionType ty ON t2.RefDpTransactionTypeId = ty.RefDpTransactionTypeId    
   WHERE t1.RefClientId = t2.RefClientId AND t1.RefSegmentId = t2.RefSegmentId    
    AND t1.RefIsinId = t2.RefIsinId AND t1.DC = t2.DC AND t1.BusinessDate = t2.BusinessDate    
   FOR XML PATH ('')), 1, 2, '') AS TxnTypes,  
  STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(100), t2.TransactionId) COLLATE DATABASE_DEFAULT     
   FROM #tradeData t2  
   WHERE t1.RefClientId = t2.RefClientId AND t1.RefSegmentId = t2.RefSegmentId    
    AND t1.RefIsinId = t2.RefIsinId AND t1.DC = t2.DC AND t1.BusinessDate = t2.BusinessDate    
   FOR XML PATH ('')), 1, 1, '') AS TxnIds  
 INTO #dateClientWiseData    
 FROM #tradeData t1    
 GROUP BY t1.RefClientId, t1.RefSegmentId, t1.RefIsinId, t1.DC, t1.BusinessDate    
    
 DROP TABLE #tradeData    
    
 SELECT DISTINCT    
  RefIsinId,    
  BusinessDate    
 INTO #selectedIsins    
 FROM #dateClientWiseData    
    
 SELECT DISTINCT      
  bhav.RefIsinId,      
  bhav.[Close],    
  bhav.RefSegmentId,    
  isin.BusinessDate,    
  ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId ORDER BY bhav.RefSegmentId) AS RN      
 INTO #presentBhavIdsTemp      
 FROM #selectedIsins isin      
 INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = isin.RefIsinId     
 WHERE bhav.[Date] = @RunDateInternal and isin.BusinessDate = @RunDateInternal    
     
 SELECT     
  temp.RefIsinId,      
  temp.[Close],    
  temp.BusinessDate    
 INTO #presentBhavIds      
 FROM #presentBhavIdsTemp temp      
 WHERE (temp.RN = 1)    
    
 CREATE TABLE #selectedDates2 ([Date] DATETIME)  
 DECLARE @3DaysBack INT, @NoOfDatesAdded DATETIME  
  
 SET @3DaysBack = 1  
 SET @NoOfDatesAdded = 0  
  
 WHILE @NoOfDatesAdded < 3  
 BEGIN  
  DECLARE @newDate DATETIME = DATEADD(DAY, -@3DaysBack, @30DayDate)  
  IF NOT EXISTS (SELECT 1 FROM dbo.RefHoliday WHERE [Date] = @newDate)  
  BEGIN  
   INSERT INTO #selectedDates2 VALUES (@newDate)  
   SET @NoOfDatesAdded = @NoOfDatesAdded + 1  
  END  
  
  SET @3DaysBack = @3DaysBack + 1  
 END   
    
 SELECT @LastBhavCopyDate = MIN([Date]) FROM #selectedDates2    
    
 DROP TABLE #selectedDates2    
   
 CREATE TABLE #dates ([Date] DATETIME)  
 DECLARE @i DATETIME  
 SET @i = @LastBhavCopyDate   
  
 WHILE @i <= @ToDate  
 BEGIN  
  INSERT INTO #dates([Date]) VALUES (@i)  
  SET @i = DATEADD(DAY, 1, @i)  
 END  
  
 SELECT  
  dt.[Date]  
 INTO #selectedDates  
 FROM #dates dt  
 LEFT JOIN dbo.RefHoliday hld ON dt.[Date] = hld.[Date]  
 WHERE hld.RefHolidayId IS NULL AND DATENAME(WEEKDAY, dt.[Date]) NOT IN ('Saturday', 'Sunday')  
 ORDER BY dt.[Date] DESC  
  
 DROP TABLE #dates  
    
 SELECT DISTINCT    
  isin.RefIsinId,    
  isin.BusinessDate    
 INTO #notPresentBhavIds    
 FROM #selectedIsins isin    
 LEFT JOIN #presentBhavIds ids ON isin.RefIsinId = ids.RefIsinId    
  AND isin.BusinessDate = ids.BusinessDate    
 WHERE ids.RefIsinId IS NULL    
    
 DROP TABLE #selectedIsins    
     
 SELECT DISTINCT    
  ids.RefIsinId,    
  ids.BusinessDate,    
  inst.RefSegmentId,    
  bhav.[Close],    
  ROW_NUMBER() OVER (PARTITION BY ids.RefIsinId, ids.BusinessDate, inst.RefSegmentId ORDER BY bhav.[Date] DESC) AS RN    
 INTO #nonDpBhavRates    
 FROM #notPresentBhavIds ids    
 INNER JOIN dbo.RefIsin isin ON ids.RefIsinId = isin.RefIsinId    
 LEFT JOIN dbo.RefInstrument inst ON isin.[Name] = inst.Isin    
  AND inst.RefSegmentId IN (@BSEId, @NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'    
 LEFT JOIN dbo.CoreBhavCopy bhav ON bhav.RefInstrumentId = inst.RefInstrumentId     
  AND bhav.RefSegmentId = inst.RefSegmentId AND bhav.[Date] <= ids.BusinessDate    
 WHERE bhav.[Date] IN (SELECT TOP 4 [Date] FROM #selectedDates sD WHERE sd.[Date] <= ids.BusinessDate ORDER BY sd.[Date] DESC)    
    
 DROP TABLE #selectedDates    
 DROP TABLE #notPresentBhavIds    
    
 SELECT DISTINCT    
  bhav1.RefIsinId,    
  bhav1.BusinessDate,    
  bhav1.[Close]    
 INTO #finalNonDpBhavRates    
 FROM #nonDpBhavRates bhav1    
 WHERE RN = 1 AND (bhav1.RefSegmentId = @BSEId OR NOT EXISTS (SELECT 1 FROM #nonDpBhavRates bhav2    
  WHERE bhav1.RefIsinId = bhav2.RefIsinId AND bhav1.BusinessDate = bhav2.BusinessDate    
   AND bhav2.RefSegmentId = @BSEId))    
    
 DROP TABLE #nonDpBhavRates    
    
 SELECT    
  cl.RefClientId,    
  cl.RefSegmentId,    
  cl.RefIsinId,    
  cl.Qty,    
  cl.BusinessDate,    
  cl.DC,    
  COALESCE(pIds.[Close], nonDpRates.[Close]) AS Rate,    
  (cl.Qty * COALESCE(pIds.[Close], nonDpRates.[Close])) AS TxnValue,    
  cl.TxnTypes,  
  cl.TxnIds  
 INTO #finalData    
 FROM #dateClientWiseData cl    
 LEFT JOIN #presentBhavIds pIds ON cl.RefIsinId = pIds.RefIsinId    
  AND cl.BusinessDate = pIds.BusinessDate    
 LEFT JOIN #finalNonDpBhavRates nonDpRates ON pIds.RefIsinId IS NULL    
  AND cl.RefIsinId = nonDpRates.RefIsinId AND cl.BusinessDate = nonDpRates.BusinessDate    
 WHERE (pIds.RefIsinId IS NOT NULL OR nonDpRates.RefIsinId IS NOT NULL)    
  AND (cl.Qty * COALESCE(pIds.[Close], nonDpRates.[Close])) >= @SingleValue    
    
 DROP TABLE #dateClientWiseData    
 DROP TABLE #presentBhavIds    
 DROP TABLE #finalNonDpBhavRates    
    
 SELECT    
  t1.RefClientId,    
  t1.RefSegmentId,    
  t1.RefIsinId,    
  t1.DC,    
  COUNT(1) AS TxnCount,  
  STUFF((SELECT DISTINCT ',' + t2.TxnIds     
   FROM #finalData t2  
   WHERE t1.RefClientId = t2.RefClientId AND t1.RefSegmentId = t2.RefSegmentId    
    AND t1.RefIsinId = t2.RefIsinId AND t1.DC = t2.DC  
   FOR XML PATH ('')), 1, 1, '') AS TxnIds  
 INTO #countData    
 FROM #finalData t1  
 GROUP BY t1.RefClientId, t1.RefSegmentId, t1.RefIsinId, t1.DC    
    
 SELECT    
  isin.RefIsinId,    
  isin.[Name] AS Isin,    
  CASE WHEN (ISNULL(inst.[Name], '') ='') THEN isin.[IsinShortName]     
   ELSE inst.[Name] END AS [NAME],    
  inst.RefInstrumentId,    
  ROW_NUMBER() OVER (PARTITION BY isin.[Name] ORDER BY inst.RefSegmentId) AS RN    
 INTO #instrumentData    
 FROM #finalData fd    
 INNER JOIN dbo.RefIsin isin ON fd.RefIsinId = isin.RefIsinId    
 LEFT JOIN dbo.RefInstrument inst ON isin.[Name] = inst.Isin    
  AND inst.RefSegmentId IN (@BSEId, @NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'    
    
 SELECT DISTINCT    
  fd.RefClientId,    
  cl.ClientId,    
  cl.[Name] AS ClientName,    
  inst.RefInstrumentId,    
  fd.RefSegmentId,    
  @30DayDate AS TransactionDateFrom,    
  @RunDateInternal AS TransactionDateTo,    
  seg.Segment,    
  inst.[Name] AS InstrumentName,    
  inst.Isin,    
  fd.TxnTypes AS TxnDesc,    
  CASE WHEN fd.DC = 1 THEN 'Cr' ELSE 'Dr' END AS DebitCredit,    
  CONVERT(INT, fd.Qty) AS Quantity,    
  CONVERT(DECIMAL(28, 2), fd.Rate) AS Rate,    
  CONVERT(DECIMAL(28, 2), fd.TxnValue) AS TxnValue,    
  CONVERT(INT, cd.TxnCount) AS TxnCount,    
  STUFF((SELECT ' ; ' + REPLACE(CONVERT(varchar, t.BusinessDate, 106), ' ', '-')     
   FROM #finalData t     
   WHERE t.RefClientId = fd.RefClientId AND t.RefIsinId = fd.RefIsinId    
    AND t.RefSegmentId = fd.RefSegmentId AND t.DC = fd.DC    
   ORDER BY t.BusinessDate DESC     
   FOR XML PATH ('')), 1, 3, '') AS [Description],  
  cd.TxnIds  
 FROM #finalData fd    
 INNER JOIN dbo.RefClient cl ON fd.RefClientId = cl.RefClientId    
 INNER JOIN #instrumentData inst ON fd.RefIsinId = inst.RefIsinId    
 INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = fd.RefSegmentId    
 INNER JOIN #countData cd ON fd.RefClientId = cd.RefClientId    
  AND fd.RefIsinId = cd.RefIsinId AND fd.RefSegmentId = cd.RefSegmentId    
  AND fd.DC = cd.DC    
 WHERE inst.RN = 1 AND fd.BusinessDate = @RunDateInternal    
  AND cd.TxnCount >= @OffMarketTrans    
    
END    