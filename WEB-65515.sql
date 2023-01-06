----WEB-65515--RC-Start
GO
ALTER PROCEDURE dbo.AML_GetFrequentChangeinClientKYC (  
 @RunDate DATETIME,  
 @ReportId INT  
)  
AS  
BEGIN  
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @DaysChangeThresh INT, @NoOfDaysThresh INT,  
  @TradingId INT, @NSDLId INT, @CDSLId INT, @S166Id INT, @S837Id INT, @FromDate DATETIME,  
  @ToDate DATETIME, @RefEntityTypeId INT ,@InActiveCdsl INT, @ClosedCdsl INT,@ClosedNsdl INT
  
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
 SET @ReportIdInternal = @ReportId  
 SELECT @DaysChangeThresh = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Threshold_Quantity'  
 SELECT @NoOfDaysThresh = CONVERT(INT, [Value]) - 1  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Quantity'  
 SELECT @TradingId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'Trading'  
 SELECT @CdslId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'  
 SELECT @NsdlId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'  
 SELECT @S166Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S166 Frequent Change in Client KYC'  
 SELECT @S837Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S837 Frequent Change in Client KYC for DP Accounts (CDSL & NSDL)'  
 SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')  
 SET @FromDate = CONVERT(DATETIME, DATEDIFF(dd, @NoOfDaysThresh, @RunDateInternal))  
 SELECT @RefEntityTypeId = RefEntityTypeId FROM dbo.RefEntityType WHERE Code = 'Client'  
 SELECT @InActiveCdsl=RefClientAccountStatusId FROM dbo.RefClientAccountStatus WHERE RefClientDatabaseEnumId=@CdslId AND [NAME]='InActive'
 SELECT @ClosedCdsl=RefClientAccountStatusId FROM dbo.RefClientAccountStatus WHERE RefClientDatabaseEnumId=@CdslId AND [NAME]='Closed'
 SELECT @ClosedNsdl=RefClientAccountStatusId FROM dbo.RefClientAccountStatus WHERE RefClientDatabaseEnumId=@NsdlId AND [NAME]='Closed'

 SELECT  
  RefClientId  
 INTO #clientsToExclude  
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion  
 WHERE RefAmlReportId = @ReportIdInternal  
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)  
  
 SELECT  
  audi.RefClientId,  
  audi.AuditDateTime,  
  audi.PAN,  
  audi.Mobile,  
  audi.Email,  
  LTRIM(RTRIM(ISNULL(audi.PAddressLine1, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.PAddressLine2, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.PAddressLine3, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.PAddressPin, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.PAddressCity, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.PAddressState, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.PAddressCountry, ''))) AS PAddress,  
  LTRIM(RTRIM(ISNULL(audi.CAddressLine1, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.CAddressLine2, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.CAddressLine3, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.CAddressPin, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.CAddressCity, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.CAddressState, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.CAddressCountry, ''))) AS CAddress,  
  CASE WHEN audi.AuditDataState = 'Old' THEN 1 ELSE 0 END AS AuditState  
 INTO #runDayAuditDetails  
 FROM dbo.RefClient_Audit audi  
 LEFT JOIN #clientsToExclude clEx ON audi.RefClientId = clEx.RefClientId  
 WHERE clEx.RefClientId IS NULL AND audi.AuditDmlAction = 'Update'  
  AND audi.AuditDatetime BETWEEN @RunDateInternal AND @ToDate  
  AND ((@ReportIdInternal = @S166Id AND audi.RefClientDatabaseEnumId = @TradingId)  
   OR (@ReportIdInternal = @S837Id AND audi.RefClientDatabaseEnumId IN (@CDSLId, @NSDLId)))  
  
 CREATE TABLE #changedClients (RefClientId INT)  
  
 INSERT INTO #changedClients (RefClientId)  
 SELECT DISTINCT  
  a1.RefClientId  
 FROM #runDayAuditDetails a1  
 INNER JOIN #runDayAuditDetails a2 ON a1.RefClientId = a2.RefClientId  
  AND a1.AuditDateTime = a2.AuditDateTime  
  AND (a1.PAN <> a2.PAN OR a1.Email <> a2.Email OR a1.Mobile <> a2.Mobile  
   OR a1.PAddress <> a2.PAddress OR a1.CAddress <> a2.CAddress)  
 WHERE a1.AuditState = 1 AND a2.AuditState = 0  
  
 DROP TABLE #runDayAuditDetails  
  
 INSERT INTO #changedClients (RefClientId)  
 SELECT DISTINCT  
  cl.RefClientId  
 FROM dbo.LinkRefClientRefBankMicr_Audit bank  
 INNER JOIN dbo.RefClient cl ON cl.RefClientId = bank.RefClientId  
 LEFT JOIN #clientsToExclude clEx ON cl.RefClientId = clEx.RefClientId  
 WHERE clEX.RefClientId IS NULL AND bank.BankAccNo <> '' AND (bank.AuditDatetime BETWEEN @RunDateInternal AND @ToDate)  
  AND ((@ReportIdInternal = @S166Id AND cl.RefClientDatabaseEnumId = @TradingId)  
   OR (@ReportIdInternal = @S837Id AND cl.RefClientDatabaseEnumId IN (@CDSLId, @NSDLId)))  
  AND NOT EXISTS (SELECT 1 FROM #changedClients ch WHERE cl.RefClientId = ch.RefClientId)  
  
 INSERT INTO #changedClients (RefClientId)  
 SELECT DISTINCT  
  bank.EntityId AS RefClientId  
 FROM dbo.CoreCRMBankAccount_Audit bank   
 INNER JOIN dbo.RefClient cl ON cl.RefClientId = bank.EntityId  
 LEFT JOIN #clientsToExclude clEx ON cl.RefClientId = clEx.RefClientId  
 WHERE clEX.RefClientId IS NULL AND bank.RefEntityTypeId = @RefEntityTypeId AND bank.BankAccountNo <> ''   
  AND (bank.AuditDatetime BETWEEN @RunDateInternal AND @ToDate)  
  AND ((@ReportIdInternal = @S166Id AND cl.RefClientDatabaseEnumId = @TradingId)  
   OR (@ReportIdInternal = @S837Id AND cl.RefClientDatabaseEnumId IN (@CDSLId, @NSDLId)))  
  AND NOT EXISTS (SELECT 1 FROM #changedClients ch WHERE cl.RefClientId = ch.RefClientId)  
  
 IF @ReportIdInternal = @S837Id   
 BEGIN  
  DECLARE @ASDesignationId INT  
  SELECT @ASDesignationId = RefDesignationId FROM dbo.RefDesignation WHERE [Name] = 'Authorized Signatory'  
  
  INSERT INTO #changedClients (RefClientId)  
  SELECT DISTINCT  
   audi.RefClientId  
  FROM dbo.LinkVirtRefClientRefKeyPerson_Audit audi  
  LEFT JOIN #clientsToExclude clEX ON audi.RefClientId = clEx.RefClientId  
  INNER JOIN dbo.RefClient cl ON audi.RefClientId = cl.RefClientId  
  WHERE clEX.RefClientId IS NULL AND audi.RefDesignationId = @ASDesignationId  
   AND (audi.AuditDatetime BETWEEN @RunDateInternal AND @ToDate)  
   AND ((@ReportIdInternal = @S166Id AND cl.RefClientDatabaseEnumId = @TradingId)  
    OR (@ReportIdInternal = @S837Id AND cl.RefClientDatabaseEnumId IN (@CDSLId, @NSDLId)))  
   AND NOT EXISTS (SELECT 1 FROM #changedClients ch WHERE cl.RefClientId = ch.RefClientId)  
 END  
  
 SELECT  
  audi.RefClientId,  
  audi.AuditDateTime,  
  audi.PAN,  
  audi.Mobile,  
  audi.Email,  
  LTRIM(RTRIM(ISNULL(audi.PAddressLine1, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.PAddressLine2, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.PAddressLine3, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.PAddressPin, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.PAddressCity, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.PAddressState, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.PAddressCountry, ''))) AS PAddress,  
  LTRIM(RTRIM(ISNULL(audi.CAddressLine1, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.CAddressLine2, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.CAddressLine3, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.CAddressPin, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.CAddressCity, '')) + ' ') + LTRIM(RTRIM(ISNULL(audi.CAddressState, '')) + ' ') +   
   LTRIM(RTRIM(ISNULL(audi.CAddressCountry, ''))) AS CAddress,  
  CASE WHEN audi.AuditDataState = 'Old' THEN 1 ELSE 0 END AS AuditState  
 INTO #auditDetails  
 FROM #changedClients fil  
 INNER JOIN dbo.RefClient_Audit audi ON fil.RefClientId = audi.RefClientId  
 WHERE audi.AuditDmlAction = 'Update'  
  AND audi.AuditDatetime BETWEEN @FromDate AND @ToDate  
  
 SELECT  
  a1.RefClientId,  
  dbo.GetDateWithoutTime(a1.AuditDateTime) AS AuditDate,  
  (CASE WHEN a1.PAN <> a2.PAN THEN 1 ELSE 0 END) AS PanChange,  
  (CASE WHEN a1.Mobile <> a2.Mobile THEN 1 ELSE 0 END) AS MobileChange,  
  (CASE WHEN a1.Email <> a2.Email THEN 1 ELSE 0 END) AS EmailChange,  
  (CASE WHEN a1.PAddress <> a2.PAddress THEN 1 ELSE 0 END) AS PAddressChange,  
  (CASE WHEN a1.CAddress <> a2.CAddress THEN 1 ELSE 0 END) AS CAddressChange  
 INTO #changes  
 FROM #auditDetails a1  
 INNER JOIN #auditDetails a2 ON a1.RefClientId = a2.RefClientId  
  AND a1.AuditDateTime = a2.AuditDateTime  
  AND (a1.PAN <> a2.PAN OR a1.Email <> a2.Email OR a1.Mobile <> a2.Mobile  
   OR a1.PAddress <> a2.PAddress OR a1.CAddress <> a2.CAddress)  
 WHERE a1.AuditState = 1 AND a2.AuditState = 0  
  
 DROP TABLE #auditDetails  
  
 SELECT DISTINCT  
  bank.RefClientId,  
  dbo.GetDateWithoutTime(bank.AuditDateTime) AS AuditDate  
 INTO #bank1  
 FROM #changedClients runDay  
 INNER JOIN dbo.LinkRefClientRefBankMicr_Audit bank ON runDay.RefClientId = bank.RefClientId  
 WHERE bank.BankAccNo <> '' AND (bank.AuditDatetime BETWEEN @FromDate AND @ToDate)  
  
 SELECT DISTINCT  
  runDay.RefClientId,  
  dbo.GetDateWithoutTime(bank.AuditDateTime) AS AuditDate  
 INTO #bank2  
 FROM #changedClients runDay  
 INNER JOIN dbo.CoreCRMBankAccount_Audit bank ON bank.EntityId = runDay.RefClientId  
 WHERE bank.RefEntityTypeId = @RefEntityTypeId AND  bank.BankAccountNo <> ''   
  AND (bank.AuditDatetime BETWEEN @FromDate AND @ToDate)  
  
 SELECT DISTINCT  
  COALESCE(b1.RefClientId, b2.RefClientId) AS RefClientId,  
  COALESCE(b1.AuditDate, b2.AuditDate) AS AuditDate,  
  1 AS BankChange  
 INTO #bank  
 FROM #bank1 b1  
 FULL JOIN #bank2 b2 ON b1.RefClientId = b2.RefClientId  
  
 DROP TABLE #bank1  
 DROP TABLE #bank2  
  
 SELECT DISTINCT  
  COALESCE(ch.RefClientId, b.RefClientId) AS RefClientId,  
  COALESCE(ch.AuditDate, b.AuditDate) AS AuditDate,  
  ISNULL(ch.PanChange, 0) AS PanChange,  
  ISNULL(ch.EmailChange, 0) AS EmailChange,  
  ISNULL(ch.MobileChange, 0) AS MobileChange,  
  ISNULL(ch.PAddressChange, 0) AS PAddressChange,  
  ISNULL(ch.CAddressChange, 0) AS CAddressChange,  
  ISNULL(b.BankChange, 0) AS BankChange  
 INTO #finalChanges  
 FROM #changes ch  
 FULL JOIN #bank b ON ch.RefClientId = b.RefClientId  
  AND ch.AuditDate = b.AuditDate  
  
 DROP TABLE #changes  
 DROP TABLE #bank  
  
 IF @ReportIdInternal = @S166Id  
 BEGIN  
  DROP TABLE #changedClients  
  
  SELECT  
   RefClientId,  
   AuditDate,  
   MAX(PanChange) AS PanChange,  
   MAX(EmailChange) EmailChange,  
   MAX(MobileChange) AS MobileChange,  
   MAX(PAddressChange) AS PAddressChange,  
   MAX(CAddressChange) AS CAddressChange,  
   MAX(BankChange) AS BankChange  
  INTO #finalData  
  FROM #finalChanges  
  GROUP BY RefClientId, AuditDate  
  
  DROP TABLE #finalChanges  
  
  SELECT  
   RefClientId,  
   COUNT(AuditDate) AS NoOfDays,  
   MIN(AuditDate) AS StartDate,  
   MAX(AuditDate) AS EndDate  
  INTO #dateData  
  FROM #finalData  
  GROUP BY RefClientId  
  
  SELECT  
   dt.RefClientId,  
   cl.ClientId,  
   cl.[Name] AS ClientName,  
   @FromDate AS StartDate,  
   @RunDateInternal AS EndDate,  
   dt.NoOfDays,  
   STUFF((SELECT ' ; ' + REPLACE((CASE WHEN fd.PanChange = 1 THEN 'PAN , ' ELSE '' END) +  
     (CASE WHEN fd.EmailChange = 1 THEN 'Email Id , ' ELSE '' END) +  
     (CASE WHEN fd.MobileChange = 1 THEN 'Mobile , ' ELSE '' END) +   
     (CASE WHEN fd.CAddressChange = 1 THEN 'Correspondence Address , ' ELSE '' END) +  
     (CASE WHEN fd.PAddressChange = 1 THEN 'Permanent Address , ' ELSE '' END) +   
     (CASE WHEN fd.BankChange = 1 THEN 'Bank A/C No. , ' ELSE '' END) + ',', ', ,', ': ')  
     + REPLACE(CONVERT(varchar, fd.AuditDate, 106), ' ', '-')  
    FROM #finalData fd   
    WHERE fd.RefClientId = dt.RefClientId  
    ORDER BY fd.AuditDate DESC  
    FOR XML PATH ('')), 1, 3, '') AS [Description]  
  FROM #dateData dt  
  INNER JOIN dbo.RefClient cl ON dt.RefClientId = cl.RefClientId  
  WHERE dt.NoOfDays >= @DaysChangeThresh  
  
  DROP TABLE #dateData  
  DROP TABLE #finalData  
  
 END  
 ELSE BEGIN  
  
  SELECT DISTINCT  
   audi.RefClientId,  
   dbo.GetDateWithoutTime(audi.AuditDateTime) AS AuditDate,  
   1 AS DesignationChange  
  INTO #desginations  
  FROM #changedClients runDay  
  INNER JOIN dbo.LinkVirtRefClientRefKeyPerson_Audit audi ON runDay.RefClientId = audi.RefClientId  
  WHERE audi.RefDesignationId = @ASDesignationId  
   AND (audi.AuditDatetime BETWEEN @FromDate AND @ToDate)  
    
  DROP TABLE #changedClients  
  
  SELECT DISTINCT  
   COALESCE(ch.RefClientId, b.RefClientId) AS RefClientId,  
   COALESCE(ch.AuditDate, b.AuditDate) AS AuditDate,  
   ISNULL(ch.PanChange, 0) AS PanChange,  
   ISNULL(ch.EmailChange, 0) AS EmailChange,  
   ISNULL(ch.MobileChange, 0) AS MobileChange,  
   ISNULL(ch.PAddressChange, 0) AS PAddressChange,  
   ISNULL(ch.CAddressChange, 0) AS CAddressChange,  
   ISNULL(ch.BankChange, 0) AS BankChange,  
   ISNULL(b.DesignationChange, 0) AS DesignationChange  
  INTO #finalChangesWithDesignation  
  FROM #finalChanges ch  
  FULL JOIN #desginations b ON ch.RefClientId = b.RefClientId  
   AND ch.AuditDate = b.AuditDate  
  
  DROP TABLE #finalChanges  
  
  SELECT  
   fc.RefClientId,  
   fc.AuditDate,  
   cl.PAN,  
   cl.RefClientDatabaseEnumId,  
   fc.PanChange,  
   fc.EmailChange,  
   fc.MobileChange,  
   fc.PAddressChange,  
   fc.CAddressChange,  
   fc.BankChange,  
   fc.DesignationChange  
  INTO #panData  
  FROM #finalChangesWithDesignation fc  
  INNER JOIN dbo.RefClient cl ON cl.RefClientId = fc.RefClientId  
  WHERE ISNULL(cl.PAN, '') <> ''   
  
  DROP TABLE #finalChangesWithDesignation  
  
  SELECT  
   PAN,  
   AuditDate,  
   MAX(PanChange) AS PanChange,  
   MAX(EmailChange) EmailChange,  
   MAX(MobileChange) AS MobileChange,  
   MAX(PAddressChange) AS PAddressChange,  
   MAX(CAddressChange) AS CAddressChange,  
   MAX(BankChange) AS BankChange,  
   MAX(DesignationChange) AS DesignationChange  
  INTO #finalData2  
  FROM #panData  
  GROUP BY PAN, AuditDate  
  
  SELECT  
   PAN,  
   COUNT(AuditDate) AS NoOfDays,  
   MIN(AuditDate) AS StartDate,  
   MAX(AuditDate) AS EndDate  
  INTO #dateData2  
  FROM #finalData2  
  GROUP BY PAN  
  
  SELECT DISTINCT  
   pd.PAN  
  INTO #cdslnsdlConnectedIds  
  FROM #panData pd  
  INNER JOIN #panData pd2 ON pd.PAN = pd2.PAN  
  WHERE pd2.RefClientDatabaseEnumId = @NSDLId  
   AND pd.RefClientDatabaseEnumId = @CDSLId  
    
  SELECT DISTINCT  
   RefClientId,  
   PAN  
  INTO #intoSelectedData  
  FROM #panData pd  
  WHERE pd.RefClientDatabaseEnumId = @CDSLId  
   OR NOT EXISTS (SELECT 1 FROM #cdslnsdlConnectedIds cd WHERE cd.PAN = pd.PAN)  
  
  DROP TABLE #panData  
  DROP TABLE #cdslnsdlConnectedIds  
  
  SELECT  
   sel.RefClientId,  
   cl.ClientId,  
   cl.[Name] AS ClientName,  
   @FromDate AS StartDate,  
   @RunDateInternal AS EndDate,  
   dt.NoOfDays,  
   STUFF((SELECT ' ; ' + REPLACE((CASE WHEN fd.PanChange = 1 THEN 'PAN, ' ELSE '' END) +  
     (CASE WHEN fd.EmailChange = 1 THEN 'Email Id, ' ELSE '' END) +  
     (CASE WHEN fd.MobileChange = 1 THEN 'Mobile, ' ELSE '' END) +   
     (CASE WHEN fd.CAddressChange = 1 THEN 'Correspondence Address, ' ELSE '' END) +  
     (CASE WHEN fd.PAddressChange = 1 THEN 'Permanent Address, ' ELSE '' END) +   
     (CASE WHEN fd.BankChange = 1 THEN 'Bank A/C No., ' ELSE '' END) +  
     (CASE WHEN fd.DesignationChange = 1 THEN 'Authorized Signatory, ' ELSE '' END) + ',', ', ,', ' : ')  
     + REPLACE(CONVERT(varchar, fd.AuditDate, 106), ' ', '-')  
    FROM #finalData2 fd   
    WHERE sel.PAN = fd.PAN  
    ORDER BY fd.AuditDate DESC  
    FOR XML PATH ('')), 1, 3, '') AS [Description]  
  FROM #intoSelectedData sel  
  INNER JOIN dbo.RefClient cl ON sel.RefClientId = cl.RefClientId  
  INNER JOIN #dateData2 dt ON sel.PAN = dt.PAN  
  WHERE dt.NoOfDays >= @DaysChangeThresh AND (cl.AccountClosingDate IS NULL OR cl.AccountClosingDate > @RunDateInternal)
  AND ISNULL(cl.RefClientAccountStatusId  ,0) NOT IN (@InActiveCdsl,@ClosedCdsl,@ClosedNsdl)
  
  DROP TABLE #intoSelectedData  
  DROP TABLE #dateData2  
  DROP TABLE #finalData2  
  
 END  
END  
GO
----WEB-65515--RC-End