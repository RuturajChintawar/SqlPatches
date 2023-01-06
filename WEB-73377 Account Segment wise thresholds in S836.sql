--WEB-73377 RC START
GO
DECLARE @S836Id INT, @DayTransactionValue DECIMAL(28,2), @Quantity DECIMAL(28,2), @ThresholdQuantity DECIMAL(28,2)

SELECT @S836Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S836 Client High Value Off Market Transaction vis-a-vis Modification in Demat Account (CDSL & NSDL)'

SELECT @DayTransactionValue = CONVERT(DECIMAL(28,2),[Value])
FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S836Id AND [Name] = 'Day_Transaction_Value'

SELECT @Quantity = CONVERT(DECIMAL(28,2),[Value])
FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S836Id AND [Name] = 'Quantity'

SELECT @ThresholdQuantity = CONVERT(DECIMAL(28,2),[Value])
FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S836Id AND [Name] = 'Threshold_Quantity'

INSERT INTO dbo.RefAmlScenarioRule
(
	RuleNumber,
	RefAmlReportId,
	Threshold,
	Threshold2,
	Threshold3,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn
)
SELECT
	(SELECT MAX(RuleNumber) FROM dbo.RefAmlScenarioRule)+1,
	@S836Id,
	@ThresholdQuantity,
	@DayTransactionValue,
	@Quantity,
	'System',
	GETDATE(),
	'System',
	GETDATE()
GO
--WEB-73377 RC END
--WEB-73377 RC START
GO
DECLARE @S836Id INT, @RuleId INT

SELECT @S836Id = RefAmlReportId FROM dbo.RefAmlReport
WHERE [Name] = 'S836 Client High Value Off Market Transaction vis-a-vis Modification in Demat Account (CDSL & NSDL)'

SELECT @RuleId = RefAmlScenarioRuleId FROM dbo.RefAmlScenarioRule WHERE RefAmlReportId = @S836Id

INSERT INTO dbo.LinkRefAmlScenarioRuleRefCustomerSegment
(
	RefAmlScenarioRuleId,
	RefCustomerSegmentId,

	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn
)
SELECT
	@RuleId,
	NULL,

	'System',
	GETDATE(),
	'System',
	GETDATE()
GO
--WEB-73377 RC END
--WEB-73377 RC START
GO
UPDATE dbo.RefAmlReport
SET
	Threshold1DisplayName = 'Single off market transaction value =>',
	Threshold2DisplayName = 'Day off market  transaction value=>',
	Threshold3DisplayName = 'Last modification days <= ',
	[Description] = 
	'"This scenario will help us to identify the Client accounts doing High Value OFF Market Transactions with modifications in demographic details such as common PAN /mobile number / email id/ bank account no. / address.<br/>  
		Segments: CDSL, NSDL ; Period = 1 Day<br/>  
		<b>Thresholds:</b> <br/>
		<b>1.Account segment:</b> Account segment mapped to the DP account   <br/> 
		<b>2. Last modification days <=</b> The clients for which the PAN /mobile number / email id/ bank account no. / Address is being modified in the past X days will be considered. System will generate an alert if any modifications are found in the Last few days within ''X'' or less than ''X'' number of previous days.<br/>  
		<b>3. Single Off Market transaction value =>:</b> This is the amount of High Value Off Market Transaction done by the client in 1 day in 1 particular scrip. System will generate alert If this ''X'' Txn value is greater than or equal to the set threshold.<br/>  
		<b>4. Day Off Market transaction value :</b> This is the sum amount of all High Value Off Market Transaction done by the client in 1 day in 1 particular scrip. System will generate alert If this ''X'' Txn value is greater than or equal to the set threshold.<br/><br/>   
		<b>Threshold Logic condition:</b><br/>  "Single Txn value AND Last modification days<br/>  OR<br/>  Day Txn value AND Last modification days <br/><br/>  
		<b>Note:</b><br/>  1. System will consider the Client Audit table data to check the modifications in KYC.'
WHERE [Name] = 'S836 Client High Value Off Market Transaction vis-a-vis Modification in Demat Account (CDSL & NSDL)'
GO
--WEB-73377 RC END
--WEB-73377 RC START
GO
DECLARE @S836Id INT

SELECT @S836Id = RefAmlReportId FROM dbo.RefAmlReport
WHERE [Name] = 'S836 Client High Value Off Market Transaction vis-a-vis Modification in Demat Account (CDSL & NSDL)'

DELETE makerChecker FROM
dbo.CoreAmlScenarioRuleMakerChecker makerChecker
INNER JOIN dbo.SysAmlReportSetting sett ON makerChecker.SysAmlReportSettingId = sett.SysAmlReportSettingId
AND sett.RefAmlReportId = @S836Id

DELETE FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S836Id
GO
--WEB-73377 RC END
--WEB-73377 RC START
GO
 ALTER PROCEDURE dbo.AML_GetClientHighValueOffMarketTransactionvisavisModificationinDematAccount (    
 @RunDate DATETIME,    
 @ReportId INT    
)    
AS    
BEGIN    
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @NsdlId INT, @CdslId INT, @ToDate DATETIME, @CdslType2 INT, @CdslType3 INT,    
  @CdslType5 INT, @CdslStatus305 INT, @CdslStatus511 INT, @CdslStatus521 INT, @NsdlType904 INT,    
  @NsdlType905 INT, @NsdlType925 INT, @NsdlType926 INT, @NsdlType940 INT, @BSEId INT, @NSEId INT,    
  @RefEntityTyepId INT, @DayValue DECIMAL(28,2)  ,
  @DayPrior7 DATETIME   
    
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)    
 SET @ReportIdInternal = @ReportId    
 SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')    
 SET @DayPrior7 = DATEADD(DAY, -7, @RunDateInternal)
  
 
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
 --SELECT @NsdlType940 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 940 AND [Name] = 'Account Transmission'    
 SELECT @CdslStatus305 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 305    
 SELECT @CdslStatus511 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 511    
 SELECT @CdslStatus521 = RefDpTransactionStatusId FROM dbo.RefDpTransactionStatus WHERE CdslCode = 521    
 SELECT @RefEntityTyepId = RefEntityTypeId FROM dbo.RefEntityType WHERE Code = 'Client'    
    
 SELECT    
  RefClientId    
 INTO #clientsToExclude    
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
 WHERE (ExcludeAllScenarios = 1 OR RefAmlReportId = @ReportIdInternal)     
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)    

  SELECT
	rules.RefAmlScenarioRuleId,
	linkCS.RefCustomerSegmentId,
	CONVERT(DECIMAL(28, 2), rules.Threshold) AS Threshold,
	CONVERT(DECIMAL(28, 2), rules.Threshold2) AS Threshold2,
	CONVERT(DATETIME, DATEDIFF(dd, CONVERT(DECIMAL(28, 2), rules.Threshold3), @RunDateInternal)) AS Threshold3,
	rules.Threshold3 AS lastModificationDate
 INTO #scenarioRules
 FROM dbo.RefAmlScenarioRule rules
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefCustomerSegment linkCS ON rules.RefAmlScenarioRuleId = linkCS.RefAmlScenarioRuleId
 WHERE rules.RefAmlReportId = @ReportIdInternal
    
 CREATE TABLE #tradeData (  
  TransactionId INT,  
  RefClientId INT,    
  RefSegmentId INT,    
  RefIsinId INT,    
  DC INT,    
  Quantity INT,    
  RefDpTransactionTypeId INT    
 )    
    
 INSERT INTO #tradeData(TransactionId, RefClientId, RefSegmentId, RefIsinId, DC, Quantity, RefDpTransactionTypeId)    
 SELECT     
  dp.CoreDpTransactionId,  
  dp.RefClientId,    
  dp.RefSegmentId,    
  dp.RefIsinId,    
  CASE WHEN dp.BuySellFlag = 'C' OR dp.BuySellFlag = 'B' THEN 1 ELSE 0 END AS DC,    
  CONVERT(INT, dp.Quantity) AS Quantity,    
  dp.RefDpTransactionTypeId    
 FROM dbo.CoreDpTransaction dp    
 LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId    
 WHERE dp.RefSegmentId = @CdslId    
  AND dp.BusinessDate = @RunDateInternal    
  AND clEx.RefClientId IS NULL    
  AND ((dp.RefDpTransactionStatusId = @CdslStatus305 AND dp.RefDpTransactionTypeId IN (@CdslType2, @CdslType3))    
   OR (dp.RefDpTransactionTypeId = @CdslType5 AND dp.RefDpTransactionStatusId IN (@CdslStatus511, @CdslStatus521)))    
  AND (dp.SettlementId IS NULL OR LTRIM(dp.SettlementId) = '')    
  AND (dp.CounterSettlementId IS NULL OR LTRIM(dp.CounterSettlementId) = '')    
    
 INSERT INTO #tradeData(TransactionId, RefClientId, RefSegmentId, RefIsinId, DC, Quantity, RefDpTransactionTypeId)    
 SELECT     
  dp.CoreDPTransactionChangeHistoryId,  
  dp.RefClientId,    
  dp.RefSegmentId,    
  dp.RefIsinId,    
  CASE WHEN dp.RefDpTransactionTypeId IN (@NsdlType905, @NsdlType926)    
  THEN 1     
  WHEN dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType925)--, @NsdlType940)    
  THEN 0 END AS DC,    
  CONVERT(INT, dp.Quantity) AS Quantity,    
  dp.RefDpTransactionTypeId    
 FROM dbo.CoreDPTransactionChangeHistory dp    
 LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = dp.RefClientId    
 WHERE dp.RefSegmentId = @NsdlId    
  AND dp.ExecutionDate = @RunDateInternal    
  AND clEx.RefClientId IS NULL     
  AND (dp.SettlementNumber IS NULL OR LTRIM(dp.SettlementNumber) = '')    
  AND dp.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType905, @NsdlType925, @NsdlType926)--, @NsdlType940)    
  AND dp.OrderStatusTo = 51    
    
 SELECT DISTINCT    
  RefIsinId    
 INTO #selectedIsins    
 FROM #tradeData    
    
 SELECT DISTINCT      
  bhav.RefIsinId,      
  bhav.[Close],    
  bhav.RefSegmentId,    
  ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId ORDER BY bhav.RefSegmentId) AS RN      
 INTO #presentBhavIdsTemp      
 FROM #selectedIsins isin      
 INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = isin.RefIsinId     
 WHERE bhav.[Date] = @RunDateInternal    
    
 SELECT     
  temp.RefIsinId,      
  temp.[Close]    
 INTO #presentBhavIds      
 FROM #presentBhavIdsTemp temp      
 WHERE (temp.RN = 1)    
    
 SELECT DISTINCT TOP 7    
  bhav.[Date]    
 INTO #selectedDates    
 FROM dbo.CoreBhavCopy bhav    
 WHERE bhav.[Date] >= @DayPrior7 AND bhav.[Date] <= @RunDateInternal    
 ORDER BY bhav.[Date] DESC    
    
 SELECT DISTINCT    
  isin.RefIsinId    
 INTO #notPresentBhavIds    
 FROM #selectedIsins isin    
 LEFT JOIN #presentBhavIds ids ON isin.RefIsinId = ids.RefIsinId    
 WHERE ids.RefIsinId IS NULL    
    
 DROP TABLE #selectedIsins    
    
 SELECT DISTINCT    
  ids.RefIsinId,    
  inst.RefSegmentId,    
  bhav.[Close],    
  ROW_NUMBER() OVER (PARTITION BY ids.RefIsinId, inst.RefSegmentId ORDER BY bhav.[Date] DESC) AS RN    
 INTO #nonDpBhavRates    
 FROM #notPresentBhavIds ids    
 INNER JOIN dbo.RefIsin isin ON ids.RefIsinId = isin.RefIsinId    
 INNER JOIN dbo.RefInstrument inst ON isin.[Name] = inst.Isin    
  AND inst.RefSegmentId IN (@BSEId, @NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'    
 INNER JOIN dbo.CoreBhavCopy bhav ON bhav.RefInstrumentId = inst.RefInstrumentId AND bhav.RefSegmentId = inst.RefSegmentId    
 INNER JOIN #selectedDates dates ON bhav.[Date] = dates.[Date]    
    
 DROP TABLE #selectedDates    
 DROP TABLE #notPresentBhavIds    
    
 SELECT DISTINCT    
  bhav1.RefIsinId,    
  bhav1.[Close]    
 INTO #finalNonDpBhavRates    
 FROM #nonDpBhavRates bhav1    
 WHERE RN = 1 AND (bhav1.RefSegmentId = @BSEId OR NOT EXISTS (SELECT 1 FROM #nonDpBhavRates bhav2    
  WHERE bhav1.RefIsinId = bhav2.RefIsinId AND bhav2.RefSegmentId = @BSEId))    
    
 DROP TABLE #nonDpBhavRates  

 SELECT DISTINCT
	RefClientId
 INTO #distinctClients
 FROM #tradeData

 SELECT
	t.RefClientId,
	t.RefCustomerSegmentId
 INTO #clientCSMapping
 FROM
 (
	 SELECT
	  cl.RefClientId,
	  linkClCs.RefCustomerSegmentId,
	  ROW_NUMBER() OVER(PARTITION BY cl.RefClientId ORDER BY linkClCs.StartDate DESC) AS RN
	 FROM #distinctClients cl
	 LEFT JOIN dbo.LinkRefClientRefCustomerSegment linkClCs ON cl.RefClientId = linkClCs.RefClientId
 ) t
 WHERE t.RN = 1

 DROP TABLE #distinctClients
  
  
 SELECT  
 td.*,  
 (td.Quantity * COALESCE(pIds.[Close], nonDpRates.[Close])) AS TxnValue,  
 COALESCE(pIds.[Close], nonDpRates.[Close]) AS Rate  
 INTO #SingleTxnData  
 FROM #tradeData td  
 LEFT JOIN #presentBhavIds pIds ON td.RefIsinId = pIds.RefIsinId  
 LEFT JOIN #finalNonDpBhavRates nonDpRates ON pIds.RefIsinId IS NULL    
  AND td.RefIsinId = nonDpRates.RefIsinId  
  
 DROP TABLE #tradeData  
  
 SELECT     
  t1.RefClientId,    
  t1.RefSegmentId,    
  t1.RefIsinId,    
  t1.DC,    
  SUM(Quantity) AS Qty,  
  SUM(t1.TxnValue) AS DayTxnValue,  
  MAX(t1.Rate) AS Rate,  
  STUFF((SELECT DISTINCT ', ' + ty.[Name]     
   FROM #SingleTxnData t2    
   INNER JOIN dbo.RefDpTransactionType ty ON t2.RefDpTransactionTypeId = ty.RefDpTransactionTypeId    
   WHERE t1.RefClientId = t2.RefClientId AND t1.RefSegmentId = t2.RefSegmentId    
    AND t1.RefIsinId = t2.RefIsinId AND t1.DC = t2.DC    
   FOR XML PATH ('')), 1, 2, '') AS TxnTypes,  
  STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(100), t2.TransactionId) COLLATE DATABASE_DEFAULT     
   FROM #SingleTxnData t2  
   WHERE t1.RefClientId = t2.RefClientId AND t1.RefSegmentId = t2.RefSegmentId    
    AND t1.RefIsinId = t2.RefIsinId AND t1.DC = t2.DC   
   FOR XML PATH ('')), 1, 1, '') AS TxnIds  
 INTO #dateClientWiseData    
 FROM #SingleTxnData t1    
 GROUP BY t1.RefClientId, t1.RefSegmentId, t1.RefIsinId, t1.DC  
  
 SELECT  
  std.RefClientId,  
  std.RefSegmentId,  
  std.DC,  
  std.RefIsinId,  
  std.TxnValue  
 INTO #SingleTxnBreached  
 FROM #SingleTxnData std  
 INNER JOIN #clientCSMapping ccsm ON std.RefClientId = ccsm.RefClientId
 INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)  
 
 WHERE rules.Threshold <> 0 AND std.TxnValue >= rules.Threshold  
  
 SELECT  
  std.RefClientId,  
  std.RefSegmentId,  
  std.DC,  
  std.RefIsinId,  
  SUM(std.TxnValue) AS TotalSingleTxnBreached  
 INTO #TotSingleTxnBreached  
 FROM #SingleTxnBreached std  
 GROUP BY std.RefClientId, std.RefSegmentId, std.DC, std.RefIsinId  
  
 DROP TABLE #SingleTxnData  
  
   
  
 SELECT temp.* INTO #AlertData  
 FROM  
 (  
  SELECT DISTINCT  
   std.RefClientId,  
   std.RefSegmentId,  
   std.DC,  
   std.RefIsinId  
  FROM #SingleTxnBreached std  
  
  UNION  
  
  SELECT   
   dcwd.RefClientId,  
   dcwd.RefSegmentId,  
   dcwd.DC,  
   dcwd.RefIsinId  
  FROM #dateClientWiseData dcwd
  INNER JOIN #clientCSMapping ccsm ON dcwd.RefClientId = ccsm.RefClientId
 INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)  
 
  WHERE  rules.Threshold2<> 0 AND dcwd.DayTxnValue >=  rules.Threshold2  
 ) temp  
  
 DROP TABLE #SingleTxnBreached  
  
    
 SELECT    
  cl.RefClientId,    
  cl.RefSegmentId,    
  cl.RefIsinId,    
  cl.Qty,    
  cl.DC,    
  cl.Rate,    
  cl.DayTxnValue,  
  cl.TxnTypes,  
  cl.TxnIds,  
  ISNULL(tstb.TotalSingleTxnBreached,0) AS TotalSingleTxnBreached  
 INTO #finalData  
 FROM #AlertData ad  
 INNER JOIN #dateClientWiseData cl ON cl.RefClientId = ad.RefClientId AND cl.RefIsinId = ad.RefIsinId   
  AND cl.RefSegmentId = ad.RefSegmentId AND cl.DC = ad.DC  
 LEFT JOIN #TotSingleTxnBreached tstb ON cl.RefClientId = tstb.RefClientId AND cl.RefIsinId = tstb.RefIsinId   
  AND cl.RefSegmentId = tstb.RefSegmentId AND cl.DC = tstb.DC  
  
 DROP TABLE #dateClientWiseData    
 DROP TABLE #presentBhavIds    
 DROP TABLE #finalNonDpBhavRates    
 DROP TABLE #TotSingleTxnBreached  
    
 SELECT DISTINCT    
  RefClientId    
 INTO #selectedClients    
 FROM #finalData    
    
 SELECT     
  cl.RefClientId,    
  audi.AuditDateTime,    
  RTRIM(LTRIM(ISNULL(audi.PAN, ''))) AS PAN,    
  RTRIM(LTRIM(ISNULL(audi.Mobile, ''))) AS Mobile,    
  RTRIM(LTRIM(ISNULL(audi.Email, ''))) AS Email,    
  dbo.RemoveMatchingCharacters(ISNULL(audi.PAddressLine1, '') + ISNULL(audi.PAddressLine2, '') +     
   ISNULL(audi.PAddressLine3, '') + ISNULL(audi.PAddressPin, '') +     
   ISNULL(audi.PAddressCity, '') + ISNULL(audi.PAddressState, '') +     
   ISNULL(audi.PAddressCountry, ''), '^0-9a-z') AS PAddress,   
  dbo.RemoveMatchingCharacters(ISNULL(audi.CAddressLine1, '') + ISNULL(audi.CAddressLine2, '') +     
   ISNULL(audi.CAddressLine3, '') + ISNULL(audi.CAddressPin, '') +     
   ISNULL(audi.CAddressCity, '') + ISNULL(audi.CAddressState, '') +     
   ISNULL(audi.CAddressCountry, ''), '^0-9a-z') AS CAddress,    
  CASE WHEN audi.AuditDataState = 'Old' THEN 1 ELSE 0 END AS AuditState    
 INTO #auditDetails    
 FROM #selectedClients cl    
 INNER JOIN dbo.RefClient_Audit audi ON cl.RefClientId = audi.RefClientId  
 INNER JOIN #clientCSMapping ccsm ON cl.RefClientId = ccsm.RefClientId
 INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)  
 
 WHERE dbo.GetDateWithoutTime(audi.AddedOn) <> dbo.GetDateWithoutTime(audi.EditedOn)  
  AND audi.AuditDmlAction = 'Update'     
  AND audi.AuditDatetime BETWEEN rules.Threshold3 AND @ToDate    
    
 SELECT    
  t.RefClientId,    
  t.ModifedField,    
  t.AuditDateTime AS ModifiedDate    
 INTO #modifiedClients    
 FROM (SELECT    
  a1.RefClientId,    
  a1.AuditDateTime,    
  (CASE WHEN a1.PAN <> a2.PAN AND a1.PAN <> '' THEN 'PAN, ' ELSE '' END) +    
  (CASE WHEN a1.Mobile <> a2.Mobile AND a1.Mobile <> '' THEN 'Mobile, ' ELSE '' END) +    
  (CASE WHEN a1.Email <> a2.Email AND a1.Email <> '' THEN 'Email, ' ELSE '' END) +    
  (CASE WHEN (a1.PAddress <> a2.PAddress AND a1.PAddress <> '') OR (a1.CAddress <> a2.CAddress AND a1.CAddress <> '')  
   THEN 'Address, ' ELSE '' END) AS ModifedField,    
  ROW_NUMBER() OVER (PARTITION BY a1.RefClientId ORDER BY a1.AuditDateTime DESC) AS RN    
  FROM #auditDetails a1    
  INNER JOIN #auditDetails a2 ON a1.RefClientId = a2.RefClientId    
  AND a1.AuditDateTime = a2.AuditDateTime  
  AND ((a1.PAN <> a2.PAN AND a1.PAN <> '') OR (a1.Email <> a2.Email AND a1.Email <> '')   
   OR (a1.Mobile <> a2.Mobile AND a1.Mobile <> '')  
   OR (a1.PAddress <> a2.PAddress AND a1.PAddress <> '')   
   OR (a1.CAddress <> a2.CAddress AND a1.CAddress <> ''))    
  WHERE a1.AuditState = 1 AND a2.AuditState = 0    
 ) t    
 WHERE t.RN = 1    
    
 SELECT DISTINCT    
  t.RefClientId,    
  t.AuditDateTime    
 INTO #bank1    
 FROM ( SELECT    
   cl.RefClientId,    
   bank.AuditDateTime,    
   ROW_NUMBER() OVER (PARTITION BY cl.RefClientId ORDER BY bank.AuditDateTime DESC) AS RN    
  FROM #selectedClients cl    
  INNER JOIN dbo.LinkRefClientRefBankMicr_Audit bank ON cl.RefClientId = bank.RefClientId    
   AND bank.BankAccNo <> '' 
   INNER JOIN #clientCSMapping ccsm ON cl.RefClientId = ccsm.RefClientId
 INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)  
 
  WHERE bank.AuditDatetime BETWEEN rules.Threshold3 AND @ToDate  
   AND bank.AuditDmlAction = 'Update'  
   AND dbo.GetDateWithoutTime(bank.AddedOn) <> dbo.GetDateWithoutTime(bank.EditedOn)  
     
 ) t WHERE t.RN = 1    
    
 SELECT DISTINCT    
  t.RefClientId,    
  t.AuditDateTime    
 INTO #bank2    
 FROM (SELECT    
   cl.RefClientId,    
   bank.AuditDateTime,    
   ROW_NUMBER() OVER (PARTITION BY cl.RefClientId ORDER BY bank.AuditDateTime DESC) AS RN    
  FROM #selectedClients cl    
  INNER JOIN dbo.CoreCRMBankAccount_Audit bank ON bank.RefEntityTypeId = @RefEntityTyepId    
   AND cl.RefClientId = bank.EntityId AND bank.BankAccountNo <> '' 
   INNER JOIN #clientCSMapping ccsm ON cl.RefClientId = ccsm.RefClientId
 INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)  
 
  WHERE bank.AuditDatetime BETWEEN rules.Threshold3 AND @ToDate   
   AND bank.AuditDmlAction = 'Update'  
   AND dbo.GetDateWithoutTime(bank.AddedOn) <> dbo.GetDateWithoutTime(bank.EditedOn)  
 ) t WHERE t.RN = 1    
    
 SELECT    
  COALESCE(b1.RefClientId, b2.RefClientId) AS RefClientId,    
  CASE WHEN b2.AuditDateTime IS NULL OR (b1.AuditDateTime IS NOT NULL AND b1.AuditDateTime >= b2.AuditDateTime)    
  THEN b1.AuditDateTime ELSE b2.AuditDateTime END AS ModifiedDate,    
  'Bank' AS ModifedField    
 INTO #bank    
 FROM #bank1 b1    
 FULL JOIN #bank2 b2 ON b1.RefClientId = b2.RefClientId    
    
 DROP TABLE #bank1    
 DROP TABLE #bank2    
    
 SELECT    
  cl.RefClientId,    
  CASE WHEN ml.ModifedField IS NULL    
   THEN bl.ModifedField    
  WHEN bl.ModifedField IS NULL OR ml.ModifiedDate > bl.ModifiedDate    
   THEN STUFF(ml.ModifedField, LEN(ml.ModifedField), 2, '')    
  WHEN ml.ModifiedDate < bl.ModifiedDate    
   THEN bl.ModifedField    
  ELSE ml.ModifedField + bl.ModifedField END AS ModifiedField,    
  CASE WHEN ml.ModifiedDate IS NULL OR (bl.ModifiedDate IS NOT NULL AND ml.ModifiedDate < bl.ModifiedDate)    
   THEN bl.ModifiedDate ELSE ml.ModifiedDate END AS ModifiedDate    
 INTO #modifiedFields    
 FROM #selectedClients cl    
 LEFT JOIN #modifiedClients ml ON cl.RefClientId = ml.RefClientId    
 LEFT JOIN #bank bl ON cl.RefClientId = bl.RefClientId    
 WHERE ml.RefClientId IS NOT NULL OR bl.RefClientId IS NOT NULL    
    
 DROP TABLE #selectedClients    
 DROP TABLE #modifiedClients    
 DROP TABLE #bank    
    
 SELECT    
  isin.RefIsinId,    
  isin.[Name] AS Isin,    
  inst.[Name],    
  inst.RefInstrumentId,    
  ROW_NUMBER() OVER (PARTITION BY isin.[Name] ORDER BY inst.RefSegmentId) AS RN    
 INTO #instrumentData    
 FROM #modifiedFields mf    
 INNER JOIN #finalData fd ON mf.RefClientId = fd.RefClientId    
 INNER JOIN dbo.RefIsin isin ON fd.RefIsinId = isin.RefIsinId    
 INNER JOIN dbo.RefInstrument inst ON isin.[Name] = inst.Isin    
  AND inst.RefSegmentId IN (@BSEId, @NSEId) AND LTRIM(RTRIM(inst.[Status])) = 'A'    
    
 SELECT DISTINCT    
  fd.RefClientId,    
  cl.ClientId,    
  cl.[Name] AS ClientName,    
  inst.RefInstrumentId,    
  fd.RefSegmentId,    
  @RunDateInternal AS TransactionDate,    
  seg.Segment,    
  inst.[Name] AS InstrumentName,    
  inst.Isin,    
  fd.TxnTypes AS TxnDesc,    
  CASE WHEN fd.DC = 1 THEN 'Cr' ELSE 'Dr' END AS DebitCredit,    
  CONVERT(INT, fd.Qty) AS Quantity,    
  CONVERT(DECIMAL(28, 2), fd.Rate) AS Rate,    
  CONVERT(DECIMAL(28, 2), fd.TotalSingleTxnBreached) AS TxnValue,    
  DATEDIFF(DAY, mf.ModifiedDate, @RunDateInternal) AS NoOfDays,    
  mf.ModifiedField,    
  mf.ModifiedDate AS LastTradeDate,  
  CASE WHEN fd.DayTxnValue >= rules.Threshold2 AND rules.Threshold2 <> 0 THEN CONVERT(DECIMAL(28, 2),fd.DayTxnValue) ELSE 0 END AS DayTxnValue,  
  fd.TxnIds ,
   CASE WHEN cl.DpId IS NULL THEN ''
	ELSE 'IN' +  CONVERT(VARCHAR(MAX),cl.DpId) COLLATE DATABASE_DEFAULT
	END AS DpId,
  custSeg.[Name] AS AccountSegment,
  'Single off market transaction value: ' + CONVERT(VARCHAR(100), rules.Threshold) COLLATE DATABASE_DEFAULT  
   + '; Day off market  transaction value: ' + CONVERT(VARCHAR(100), rules.Threshold2) COLLATE DATABASE_DEFAULT 
   + '; Last modification days: ' + CONVERT(VARCHAR(100), rules.lastModificationDate) COLLATE DATABASE_DEFAULT AS Threshold
  
 FROM #modifiedFields mf    
 INNER JOIN #finalData fd ON fd.RefClientId = mf.RefClientId    
 INNER JOIN dbo.RefClient cl ON mf.RefClientId = cl.RefClientId 
 INNER JOIN #clientCSMapping ccsm ON cl.RefClientId = ccsm.RefClientId
 INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)
 LEFT JOIN dbo.RefCustomerSegment custSeg ON custSeg.RefCustomerSegmentId = ccsm.RefCustomerSegmentId  
 
 INNER JOIN #instrumentData inst ON fd.RefIsinId = inst.RefIsinId    
  AND inst.RN = 1    
 INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = fd.RefSegmentId    
    
END    
GO
--WEB-73377 RC END
