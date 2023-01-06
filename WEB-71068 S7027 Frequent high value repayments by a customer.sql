--WEB-71068-RC START
GO
UPDATE ref
SET ref.[Name]= 'S7027 Frequent High Value Repayments By A Customer'
FROM dbo.RefAmlReport ref
WHERE ref.Code ='s7027'
GO
--WEB-71068-RC END
--WEB-71068-RC START
GO
UPDATE ref
SET ref.[Name]= 'J1457 S7027 Frequent High Value Repayments By A Customer',
ref.[DisplayName] = 'J1457 S7027 Frequent High Value Repayments By A Customer'
FROM dbo.RefProcess ref
WHERE ref.Code ='J1457'
GO
--WEB-71068-RC END
--WEB-71068-RC START
GO
ALTER PROCEDURE dbo.CoreFinancialTransaction_S7027FrequentHighValueRepaymentNBFCScenarioAlert (  
 @RunDate DATETIME,    
 @AmlReportId INT,    
 @ProfileId INT,  
 @ParentCompanyId INT,  
 @IsAlertDuplicationAllowed BIT = 0      
)      
AS       
BEGIN      
      
 DECLARE @ClientEntityTypeId INT, @ReceiptVoucherTypeId INT, @ActiveEntityStatusTypeEnumValueId INT,      
  @InstrumentTypeId INT, @RuleEntityTypeId INT, @InternalAmlReportId INT, @InternalProfileId INT,   
  @InternalParentCompanyId INT, @InternalRunDate DATETIME, @StartDate DATETIME, @EndDate DATETIME,   
  @InternalIsAlertDuplicationAllowed BIT, @TransactionType2 INT, @Borrower INT, @EndDateWOTime DATETIME,  
  @LookBackMonths INT, @Type2Codes VARCHAR(MAX), @RefCustomerSegmentEntityTypeId INT  
      
 SET @InternalParentCompanyId = @ParentCompanyId  
 SET @InternalAmlReportId = @AmlReportId      
 SET @InternalProfileId = @ProfileId   
 SET @InternalIsAlertDuplicationAllowed = @IsAlertDuplicationAllowed  
 SET @InternalRunDate = @RunDate   
 SET @EndDate = DATEADD(DAY, -(DAY(@InternalRunDate)), @InternalRunDate) + CONVERT(DATETIME, '23:59:59.000')  
 SET @EndDateWOTime = dbo.GetDateWithoutTime(@EndDate)  
 SET @TransactionType2 = dbo.GetEnumTypeId('FinancialTransactionType2')       
 SET @ClientEntityTypeId = dbo.GetEntityTypeByCode('Client')  
 SET @RefCustomerSegmentEntityTypeId = dbo.GetEntityTypeByCode('BaseCustomer')  
 SELECT @Borrower = dbo.GetEnumValueId('RelatedPartyRelation', '141')  
 SELECT @ReceiptVoucherTypeId = RefVoucherTypeId FROM dbo.RefVoucherType WHERE [Name] = 'Receipt'     
 SELECT @InstrumentTypeId = RefFinancialTransactionInstrumentTypeId FROM dbo.RefFinancialTransactionInstrumentType WHERE [Name] = 'Cash'      
 SET @ActiveEntityStatusTypeEnumValueId = dbo.GetEnumValueId('CRMEntityStatusType', 'Active')  
 SET @RuleEntityTypeId = dbo.GetEntityTypeByParentCompanyIdAndParentEntityTypeCode(@InternalParentCompanyId, 'BaseScenarioRule')  
  
 -------------------------------Get-Report Settings--------------------------      
 SELECT @LookBackMonths = CONVERT(int, link.[Value])     
 FROM dbo.SysAmlReportSetting rs      
 INNER JOIN dbo.LinkSysAmlReportSettingRefAMLScenarioRuleProfile link ON link.SysAmlReportSettingId = rs.SysAmlReportSettingId      
 INNER JOIN dbo.RefAMLScenarioRuleProfile rp ON rp.RefAMLScenarioRuleProfileId = link.RefAMLScenarioRuleProfileId   
  AND rp.RefEntityTypeId = @RuleEntityTypeId      
 WHERE rs.RefAmlReportId = @InternalAmlReportId AND rs.[Name] = 'Txn_Amount'  
  AND rp.RefAMLScenarioRuleProfileId = @InternalProfileId  
  
 IF (@LookBackMonths IS NULL OR @LookBackMonths < 1 OR @LookBackMonths > 12)  
 BEGIN  
  RAISERROR ('Lookback Calendar Month is not set or out of range, it should be between 1 to 12.', 11, 1) WITH SETERROR;            
  RETURN 50010;  
 END  
   
 SET @StartDate = DATEADD(mm, DATEDIFF(mm, 0, @InternalRunDate) -@LookBackMonths, 0)   
  
 SELECT @Type2Codes = link.[Value]    
 FROM dbo.SysAmlReportSetting rs      
 INNER JOIN dbo.LinkSysAmlReportSettingRefAMLScenarioRuleProfile link ON link.SysAmlReportSettingId = rs.SysAmlReportSettingId      
 INNER JOIN dbo.RefAMLScenarioRuleProfile rp ON rp.RefAMLScenarioRuleProfileId = link.RefAMLScenarioRuleProfileId   
  AND rp.RefEntityTypeId = @RuleEntityTypeId      
 WHERE rs.RefAmlReportId = @InternalAmlReportId AND rs.[Name] = 'Transaction_Type_Inclusion'  
  AND rp.RefAMLScenarioRuleProfileId = @InternalProfileId   
  
 SELECT  
  s.items  
 INTO #types2Codes  
 FROM dbo.Split(@Type2Codes, ',') s  
  
   
  
 IF LTRIM(ISNULL(@Type2Codes, '')) = '' OR EXISTS (SELECT 1 FROM #types2Codes WHERE items NOT IN (SELECT ref.Code FROM dbo.RefEnumvalue ref WHERE ref.RefEnumTypeId = @TransactionType2))  
 BEGIN  
  RAISERROR ('Transaction Type not set or has incorrect values', 11, 1) WITH SETERROR;            
  RETURN 50010;  
 END  
  
 SELECT  
  val.RefEnumValueId  
 INTO #type2EnumIds  
 FROM #types2Codes s  
 INNER JOIN dbo.RefEnumValue val ON val.RefEnumTypeId = @TransactionType2 AND s.items = val.Code   
  
 DROP TABLE #types2Codes  
      
 ------------------------------- Get Rule Data------------------------------      
 SELECT   
  rul.Threshold,   
     rul.RefCustomerSegmentId  
 INTO #Rules  
 FROM dbo.RefAmlScenarioRule rul  
 WHERE rul.RefAMLScenarioRuleProfileId = @InternalProfileId AND rul.RefAmlReportId = @InternalAmlReportId  
  
 --- Getting Transactions    
 SELECT  
  trans.CoreFinancialTransactionId,  
  trans.RefClientId,  
  MONTH(trans.TransactionDate) AS TransMonth,  
  trans.Amount  
 INTO #transactions  
 FROM #type2EnumIds type2  
 INNER JOIN dbo.CoreFinancialTransaction trans ON trans.FinancialTransactionType2RefEnumValueId = type2.RefEnumValueId  
  AND trans.RefVoucherTypeId = @ReceiptVoucherTypeId --AND trans.RefFinancialTransactionInstrumentTypeId <> @InstrumentTypeId  
  AND trans.TransactionDate BETWEEN @StartDate AND @EndDate  
  
 DROP TABLE #type2EnumIds  
   
 ---- Getting Borrower Customers and having rule defined Customer Segment  
 SELECT DISTINCT  
  rp.RelatedPartyRefCRMCustomerId AS RefCRMCustomerId,  
  rules.RefCustomerSegmentId  
 INTO #customers  
 FROM #transactions cl  
 INNER JOIN dbo.CoreCRMRelatedParty rp ON rp.RefEntityTypeId = @ClientEntityTypeId   
  AND cl.RefClientId = rp.EntityId AND rp.RelatedPartyRelationRefEnumValueId = @Borrower  
 INNER JOIN dbo.CoreCRMEntityStatusLatest st ON st.RefEntityTypeId = @ClientEntityTypeId  
  AND rp.EntityId = st.EntityId AND st.CRMEntityStatusTypeRefEnumValueId = @ActiveEntityStatusTypeEnumValueId  
 LEFT JOIN dbo.LinkRefCRMCustomerRefCustomerSegment_GetLatestByCustomerSegmentTypeBeforeGivenDate(@RefCustomerSegmentEntityTypeId, @InternalRunDate) custseg ON   
  custseg.EntityId = rp.RelatedPartyRefCRMCustomerId  
 INNER JOIN dbo.RefCRMCustomer cust ON cust.RefCRMCustomerId = rp.RelatedPartyRefCRMCustomerId  
  AND cust.RefParentCompanyId = @InternalParentCompanyId  
 INNER JOIN #Rules rules ON ISNULL(custseg.RefCustomerSegmentId,0) = ISNULL(rules.RefCustomerSegmentId,0)  
 LEFT JOIN dbo.CoreAmlScenarioExclusion excl ON excl.RefCRMCustomerId = cust.RefCRMCustomerId   
  AND excl.RefAmlReportId = @InternalAmlReportId  
  AND @EndDate BETWEEN excl.StartDate AND ISNULL(excl.EndDate, GETDATE())  
 WHERE excl.CoreAmlScenarioExclusionId IS NULL  
  
 ---- filtering transactions  
 SELECT  
  trans.CoreFinancialTransactionId,  
  cust.RefCRMCustomerId,  
  cl.ClientId,  
  trans.Amount,  
  trans.TransMonth,  
  cust.RefCustomerSegmentId  
 INTO #customerTransactions  
 FROM #customers cust  
 INNER JOIN dbo.CoreCRMRelatedParty rp ON rp.RelatedPartyRefCRMCustomerId = cust.RefCRMCustomerId  
  AND rp.RefEntityTypeId = @ClientEntityTypeId  
 INNER JOIN dbo.CoreCRMEntityStatusLatest st ON st.RefEntityTypeId = @ClientEntityTypeId  
  AND rp.EntityId = st.EntityId AND st.CRMEntityStatusTypeRefEnumValueId = @ActiveEntityStatusTypeEnumValueId  
 INNER JOIN #transactions trans ON st.EntityId = trans.RefClientId  
 INNER JOIN dbo.RefClient cl ON trans.RefClientId = cl.RefClientId  
  
 DROP TABLE #transactions  
 DROP TABLE #customers  
  
 SELECT  
  trans.RefCRMCustomerId,  
  trans.RefCustomerSegmentId,  
  trans.TransMonth,  
  COUNT(trans.CoreFinancialTransactionId) AS TxnCount,  
  SUM(trans.Amount) AS RepaymentValue  
 INTO #sumedTransactions  
 FROM #customerTransactions trans  
 GROUP BY trans.RefCRMCustomerId, trans.RefCustomerSegmentId, trans.TransMonth  
  
 SELECT  
  trans.RefCRMCustomerId,  
  trans.RefCustomerSegmentId,  
  trans.TransMonth,  
  trans.TxnCount,  
  trans.RepaymentValue  
 INTO #rulAppliedTransactions  
 FROM #sumedTransactions trans  
 INNER JOIN #Rules rul ON ISNULL( trans.RefCustomerSegmentId,0) = ISNULL( rul.RefCustomerSegmentId,0)  
 WHERE trans.RepaymentValue >= rul.Threshold  
  
 DROP TABLE #Rules  
 DROP TABLE #sumedTransactions  
  
 SELECT  
  t.RefCRMCustomerId  
 INTO #selectedCustomers  
 FROM (SELECT DISTINCT  
   RefCRMCustomerId,  
   TransMonth  
  FROM #rulAppliedTransactions) t  
 GROUP BY t.RefCRMCustomerId  
 HAVING COUNT(t.TransMonth) = @LookBackMonths  
  
 SELECT  
  cust.RefCRMCustomerId,  
  SUM(trans.TxnCount) AS TxnCount,  
  SUM(trans.RepaymentValue) AS RepaymentValue,  
  STUFF((SELECT DISTINCT ', ' + t.ClientId   
   FROM #customerTransactions t  
   WHERE cust.RefCRMCustomerId = t.RefCRMCustomerId  
   FOR XML PATH ('')), 1, 2, '') AS ProductAccounts  
 INTO #finalData  
 FROM #selectedCustomers cust  
 INNER JOIN #rulAppliedTransactions trans ON cust.RefCRMCustomerId = trans.RefCRMCustomerId  
 GROUP BY cust.RefCRMCustomerId  
  
 DROP TABLE #customerTransactions  
 DROP TABLE #rulAppliedTransactions  
 DROP TABLE #selectedCustomers  
   
 ---- final select  
 SELECT  
  cust.FirstName AS FirstName,  
  ISNULL(cust.MiddleName, '') AS MiddleName,  
  ISNULL(cust.LastName, '') AS LastName,  
  cust.RefCRMCustomerId,  
  cust.CustomerCode,  
  @StartDate AS StartDate,  
  @EndDateWOTime AS EndDate,  
  fd.ProductAccounts,  
  CONVERT(DECIMAL(28, 2), fd.RepaymentValue) AS RepaymentValue,  
  fd.TxnCount,  
  @LookBackMonths AS MonthsConsidered  
 FROM #finalData fd  
 INNER JOIN dbo.RefCRMCustomer cust ON fd.RefCRMCustomerId = cust.RefCRMCustomerId  
 LEFT JOIN dbo.CoreAlertRegisterCustomerCaseAlert dupCheck ON dupCheck.RefCRMCustomerId = cust.RefCRMCustomerId  
  AND dupCheck.StartDate = @StartDate AND dupCheck.EndDate = @EndDateWOTime  
  AND CONVERT(DECIMAL(28, 2), dupCheck.MoneyIn) = CONVERT(DECIMAL(28, 2), fd.RepaymentValue)  
  AND dupCheck.ClientIds = fd.ProductAccounts  
 WHERE @InternalIsAlertDuplicationAllowed = 1 OR dupCheck.CoreAlertRegisterCustomerCaseAlertId IS NULL  
  
END      
GO
--WEB-71068-RC END
--WEB-71068-RC START
GO
DECLARE @AmlReportId INT ,@RefEntityColumnId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S7027 Frequent High Value Repayments By A Customer'
SELECT @RefEntityColumnId = RefEntityColumnId FROM dbo.RefEntityColumn ref INNER JOIN dbo.RefentityType ty ON ty.[Code] = 'AmlScenarioRuleUi'  WHERE ref.[Name] ='CustomerSegment'
UPDATE link
SET IsMandatory = 0
FROM dbo.LinkRefAmlReportRefEntityColumn link
WHERE link.RefAmlReportId = @AmlReportId AND link.RefEntityColumnId = @RefEntityColumnId
--WEB-71068-RC END