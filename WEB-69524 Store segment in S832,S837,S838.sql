----	RC-WEB-69524-start-832
GO
 ALTER PROCEDURE dbo.AML_GetMultipleAccountsOpenedwithCommonDetails (  
 @RunDate DATETIME,  
 @ReportId INT  
)  
AS  
BEGIN  
  
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @PanId INT, @MobileNoId INT, @EmailId INT,  
  @BankACNoId INT, @AddressId INT, @NsdlId INT, @CdslId INT, @ToDate DATETIME ,@cdsl INT,@nsdl INT   
  
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
 SET @ReportIdInternal = @ReportId  
 SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')  
 SELECT @PanId = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'PAN'  
  
 SELECT @MobileNoId = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Mobile_No'  
  
 SELECT @EmailId = CONVERT(DECIMAL, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Email_Id'  
  
 SELECT @BankACNoId = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Bank_AC_No'  
  
 SELECT @AddressId = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Address'  
  
 SELECT @CdslId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'  
 SELECT @NsdlId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL' 
 
 SELECT @cdsl = RefSegmentEnumId FROM  dbo.RefSegmentEnum ref WHERE Segment='CDSL'
 SELECT @nsdl = RefSegmentEnumId FROM  dbo.RefSegmentEnum ref WHERE Segment='NSDL'
   
 -- client to exclude  
 SELECT  
  RefClientId  
 INTO #clientsToExclude  
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion  
 WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportIdInternal)     
 AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)    
    
  
  
 --to exclude closed clients    
  Select RefClientAccountStatusId    
 INTO #statusToExclude    
 from dbo.RefClientAccountStatus     
 WHERE RefClientDatabaseEnumId in (@CdslId, @NsdlId)    
 AND [Name] in ('Closed', 'Closed, Cancelled by DP')    
  
  
 SELECT  
   cl.RefClientId,  
 -- cl.ClientId,  
  LTRIM(RTRIM(ISNULL(cl.PAN, ''))) AS PAN,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.PAN, '')))<>'' THEN 1 ELSE 0 END AS IsPANPresent,  
  LTRIM(RTRIM(ISNULL(cl.Mobile, ''))) AS Mobile,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.Mobile, '')))<>'' THEN 1 ELSE 0 END AS IsMobilePresent,  
  LTRIM(RTRIM(ISNULL(cl.Email, ''))) AS Email,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.Email, '')))<>'' THEN 1 ELSE 0 END AS IsEmailPresent,  
  
  LTRIM(RTRIM(ISNULL(cl.PAddressLine1, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressLine2, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressLine3, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressPin, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressCity, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressState, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressCountry, ''))) AS PAddress,  
  
   Case WHEN (LTRIM(RTRIM(ISNULL(cl.PAddressLine1, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressLine2, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressLine3, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressPin, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressCity, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressState, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressCountry, ''))))<>'' THEN 1 ELSE 0 END AS IsPAddressPresent,  
  
  LTRIM(RTRIM(ISNULL(cl.CAddressLine1, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressLine2, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressLine3, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressPin, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressCity, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressState, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressCountry, ''))) AS CAddress,  
  Case WHEN (LTRIM(RTRIM(ISNULL(cl.CAddressLine1, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressLine2, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressLine3, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressPin, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressCity, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressState, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressCountry, ''))))<>'' THEN 1 ELSE 0 END AS IsCAddressPresent,  
  
  LTRIM(RTRIM(ISNULL(cl.SecondHolderPAN, ''))) AS SecondHolderPAN,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.SecondHolderPAN, '')))<>'' THEN 1 ELSE 0 END AS IsSecondHolderPANPresent,  
  LTRIM(RTRIM(ISNULL(cl.SecondHolderMobile, ''))) AS SecondHolderMobile,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.SecondHolderMobile, '')))<>'' THEN 1 ELSE 0 END AS IsSecondHolderMobilePresent,  
  LTRIM(RTRIM(ISNULL(cl.SecondHolderEmail, ''))) AS SecondHolderEmail,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.SecondHolderEmail, '')))<>'' THEN 1 ELSE 0 END AS IsSecondHolderEmailPresent,  
  LTRIM(RTRIM(ISNULL(cl.ThirdHolderPAN, ''))) AS ThirdHolderPAN,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.ThirdHolderPAN, '')))<>'' THEN 1 ELSE 0 END AS IsThirdHolderPANPresent,  
  LTRIM(RTRIM(ISNULL(cl.ThirdHolderMobile, ''))) AS ThirdHolderMobile,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.ThirdHolderMobile, '')))<>'' THEN 1 ELSE 0 END AS IsThirdHolderMobilePresent,  
  LTRIM(RTRIM(ISNULL(cl.ThirdHolderEmail, ''))) AS ThirdHolderEmail,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.ThirdHolderMobile, '')))<>'' THEN 1 ELSE 0 END AS IsThirdHolderEmailPresent  
  INTO #selectedClients  
 FROM dbo.RefClient cl  
 LEFT JOIN #statusToExclude s ON s.RefClientAccountStatusId=cl.RefClientAccountStatusId    
 LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = cl.RefClientId  
 WHERE cl.RefClientDatabaseEnumId IN (@NsdlId, @CdslId)  
  AND clEx.RefClientId IS NULL  
  AND s.RefClientAccountStatusId IS NULL   
  AND (cl.AccountClosingDate IS NULL OR cl.AccountClosingDate>@RunDateInternal)  
  AND (cl.AccountOpeningDate BETWEEN @RunDateInternal AND @ToDate)  
  
  
 SELECT  
  cl.RefClientId,  
 -- cl.ClientId,  
  LTRIM(RTRIM(ISNULL(cl.PAN, ''))) AS PAN,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.PAN, '')))<>'' THEN 1 ELSE 0 END AS IsPANPresent,  
  LTRIM(RTRIM(ISNULL(cl.Mobile, ''))) AS Mobile,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.Mobile, '')))<>'' THEN 1 ELSE 0 END AS IsMobilePresent,  
  LTRIM(RTRIM(ISNULL(cl.Email, ''))) AS Email,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.Email, '')))<>'' THEN 1 ELSE 0 END AS IsEmailPresent,  
  
  LTRIM(RTRIM(ISNULL(cl.PAddressLine1, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressLine2, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressLine3, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressPin, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressCity, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressState, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressCountry, ''))) AS PAddress,  
  
   Case WHEN (LTRIM(RTRIM(ISNULL(cl.PAddressLine1, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressLine2, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressLine3, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressPin, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressCity, ''))) + LTRIM(RTRIM(ISNULL(cl.PAddressState, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.PAddressCountry, ''))))<>'' THEN 1 ELSE 0 END AS IsPAddressPresent,  
  
  LTRIM(RTRIM(ISNULL(cl.CAddressLine1, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressLine2, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressLine3, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressPin, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressCity, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressState, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressCountry, ''))) AS CAddress,  
  Case WHEN (LTRIM(RTRIM(ISNULL(cl.CAddressLine1, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressLine2, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressLine3, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressPin, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressCity, ''))) + LTRIM(RTRIM(ISNULL(cl.CAddressState, ''))) +   
   LTRIM(RTRIM(ISNULL(cl.CAddressCountry, ''))))<>'' THEN 1 ELSE 0 END AS IsCAddressPresent,  
  
  LTRIM(RTRIM(ISNULL(cl.SecondHolderPAN, ''))) AS SecondHolderPAN,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.SecondHolderPAN, '')))<>'' THEN 1 ELSE 0 END AS IsSecondHolderPANPresent,  
  LTRIM(RTRIM(ISNULL(cl.SecondHolderMobile, ''))) AS SecondHolderMobile,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.SecondHolderMobile, '')))<>'' THEN 1 ELSE 0 END AS IsSecondHolderMobilePresent,  
  LTRIM(RTRIM(ISNULL(cl.SecondHolderEmail, ''))) AS SecondHolderEmail,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.SecondHolderEmail, '')))<>'' THEN 1 ELSE 0 END AS IsSecondHolderEmailPresent,  
  LTRIM(RTRIM(ISNULL(cl.ThirdHolderPAN, ''))) AS ThirdHolderPAN,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.ThirdHolderPAN, '')))<>'' THEN 1 ELSE 0 END AS IsThirdHolderPANPresent,  
  LTRIM(RTRIM(ISNULL(cl.ThirdHolderMobile, ''))) AS ThirdHolderMobile,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.ThirdHolderMobile, '')))<>'' THEN 1 ELSE 0 END AS IsThirdHolderMobilePresent,  
  LTRIM(RTRIM(ISNULL(cl.ThirdHolderEmail, ''))) AS ThirdHolderEmail,  
  Case WHEN LTRIM(RTRIM(ISNULL(cl.ThirdHolderMobile, '')))<>'' THEN 1 ELSE 0 END AS IsThirdHolderEmailPresent  
  INTO #restClients  
 FROM dbo.RefClient cl  
 LEFT JOIN #statusToExclude s ON s.RefClientAccountStatusId=cl.RefClientAccountStatusId    
 LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = cl.RefClientId  
 LEFT JOIN #selectedClients scl ON scl.RefClientId=cl.RefClientId  
 WHERE cl.RefClientDatabaseEnumId IN (@NsdlId, @CdslId)  
  AND clEx.RefClientId IS NULL  
  AND s.RefClientAccountStatusId IS NULL   
  AND SCL.RefClientId IS NULL  
  AND (cl.AccountClosingDate IS NULL OR cl.AccountClosingDate>@RunDateInternal)  
    
    
  Drop TABLE #clientsToExclude  
  Drop TABLE #statusToExclude  
   
 ------index for PAN match  
 --CREATE NONCLUSTERED INDEX [#selectedClients_Pan] ON [dbo].[#selectedClients] ([PAN],[IsPANPresent]) INCLUDE ([RefClientId])  
 --CREATE NONCLUSTERED INDEX [#selectedClients_SecondHolderPAN] ON [dbo].[#selectedClients] ([SecondHolderPAN],[IsSecondHolderPANPresent]) INCLUDE ([RefClientId])  
 --CREATE NONCLUSTERED INDEX [#selectedClients_ThirdHolderPAN] ON [dbo].[#selectedClients] ([ThirdHolderPAN],[IsThirdHolderPANPresent]) INCLUDE ([RefClientId])  
  
 ------index for Mobile match  
 --CREATE NONCLUSTERED INDEX [#selectedClients_Mobile] ON [dbo].[#selectedClients] ([Mobile],[IsMobilePresent]) INCLUDE ([RefClientId])  
 --CREATE NONCLUSTERED INDEX [#selectedClients_SecondHolderMobile] ON [dbo].[#selectedClients] ([SecondHolderMobile],[IsSecondHolderMobilePresent]) INCLUDE ([RefClientId])  
 --CREATE NONCLUSTERED INDEX [#selectedClients_ThirdHolderMobile] ON [dbo].[#selectedClients] ([ThirdHolderMobile],[IsThirdHolderMobilePresent]) INCLUDE ([RefClientId])  
  
   
 ----index for Email match  
 --CREATE NONCLUSTERED INDEX [#selectedClients_Mobile] ON [dbo].[#selectedClients] ([Mobile],[IsMobilePresent]) INCLUDE ([RefClientId])  
 --CREATE NONCLUSTERED INDEX [#selectedClients_SecondHolderMobile] ON [dbo].[#selectedClients] ([SecondHolderMobile],[IsSecondHolderMobilePresent]) INCLUDE ([RefClientId])  
 --CREATE NONCLUSTERED INDEX [#selectedClients_ThirdHolderMobile] ON [dbo].[#selectedClients] ([ThirdHolderMobile],[IsThirdHolderMobilePresent]) INCLUDE ([RefClientId])  
  
 ------ PAN Start  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  1 AS Holder  
 INTO #PanData  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsPANPresent  = 1 AND rest.IsPANPresent  = 1   
 AND sel.PAN = rest.PAN  
  
 INSERT INTO #PanData  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  1 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.RefClientId <> rest.RefClientId   
 AND sel.IsPANPresent  = 1 AND rest.IsPANPresent  = 1 AND sel.PAN = rest.PAN  
    
  
 INSERT INTO #PanData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  2 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsPANPresent  = 1 AND rest.IsSecondHolderPANPresent  = 1  AND sel.PAN = rest.SecondHolderPAN  
 WHERE NOT EXISTS (SELECT 1 FROM #PanData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 INSERT INTO #PanData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  2 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.IsPANPresent  = 1 AND rest.IsSecondHolderPANPresent  = 1 AND sel.PAN = rest.SecondHolderPAN  
  AND sel.RefClientId <> rest.RefClientId  
 WHERE NOT EXISTS (SELECT 1 FROM #PanData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 INSERT INTO #PanData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  2 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsPANPresent  = 1 AND rest.IsThirdHolderPANPresent  = 1 AND sel.PAN = rest.ThirdHolderPAN  
 WHERE NOT EXISTS (SELECT 1 FROM #PanData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 INSERT INTO #PanData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  3 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.IsPANPresent  = 1 AND rest.IsThirdHolderPANPresent  = 1  AND sel.PAN = rest.ThirdHolderPAN  
  AND sel.RefClientId <> rest.RefClientId  
 WHERE NOT EXISTS (SELECT 1 FROM #PanData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 SELECT  
  Pri,  
  COUNT(Sec) AS CommonPan  
 INTO #PanCount  
 FROM #PanData  
 GROUP BY Pri  
 HAVING COUNT(sec)>=@PanId  
  
 SELECT   
 pan.Pri AS RefClientId,  
  pan.CommonPan,  
  'PAN - ' + STUFF((SELECT DISTINCT ',' + client.ClientId + CASE WHEN t.Holder = 1 THEN '' ELSE '(' + CONVERT(VARCHAR,t.Holder) + ')' END   
   FROM #PanData t  
   INNER JOIN dbo.RefClient client ON client.RefClientId = t.Sec   
   WHERE t.Pri = pan.Pri  
   FOR XML PATH ('')), 1, 1, '') AS PanDesc,  
   STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(MAX),t.Sec)    
   FROM #PanData t     
   WHERE t.Pri = pan.Pri    
   FOR XML PATH ('')), 1, 1, '') AS MatchingRefClientid  
 INTO #finalPanData  
 FROM #PanCount pan  
   
  
  
  
 ------ PAN End  
  
 ------ Mobile Start  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  1 AS Holder  
 INTO #MobileData  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsMobilePresent = 1 AND rest.IsMobilePresent  = 1 AND sel.Mobile = rest.Mobile  
  
 INSERT INTO #MobileData  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  1 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.IsMobilePresent = 1 AND rest.IsMobilePresent  = 1   
 AND sel.Mobile = rest.Mobile AND sel.RefClientId <> rest.RefClientId   
  
 INSERT INTO #MobileData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  2 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsMobilePresent = 1 AND rest.IsSecondHolderMobilePresent  = 1  AND sel.Mobile = rest.SecondHolderMobile  
 WHERE NOT EXISTS (SELECT 1 FROM #MobileData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 INSERT INTO #MobileData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  2 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.IsMobilePresent = 1 AND rest.IsSecondHolderMobilePresent = 1 AND sel.Mobile = rest.SecondHolderMobile  
  AND sel.RefClientId <> rest.RefClientId  
 WHERE NOT EXISTS (SELECT 1 FROM #MobileData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 INSERT INTO #MobileData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  3 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsMobilePresent = 1 AND rest.IsThirdHolderMobilePresent = 1 AND sel.Mobile = rest.ThirdHolderMobile  
 WHERE NOT EXISTS (SELECT 1 FROM #MobileData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 INSERT INTO #MobileData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  3 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON  sel.IsMobilePresent = 1 AND rest.IsThirdHolderMobilePresent = 1  AND sel.Mobile = rest.ThirdHolderMobile  
  AND sel.RefClientId <> rest.RefClientId  
 WHERE NOT EXISTS (SELECT 1 FROM #MobileData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 SELECT  
  Pri,  
  COUNT(Sec) AS CommonMobileNo  
 INTO #MobileCount  
 FROM #MobileData  
 GROUP BY Pri  
 HAVING COUNT(sec)>=@MobileNoId  
  
 SELECT mob.Pri AS RefClientId,  
  mob.CommonMobileNo,  
  'Mobile - ' + STUFF((SELECT DISTINCT',' + client.ClientId + CASE WHEN t.Holder = 1 THEN '' ELSE '(' + CONVERT(VARCHAR,t.Holder) + ')' END   
   FROM #MobileData t   
   INNER JOIN dbo.RefClient client ON client.RefClientId = t.Sec   
   WHERE t.Pri = mob.Pri  
   FOR XML PATH ('')), 1, 1, '') AS MobDesc,  
   STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(MAX),t.Sec)    
   FROM #MobileData t     
   WHERE t.Pri = mob.Pri    
   FOR XML PATH ('')), 1, 1, '') AS MatchingRefClientid  
 INTO #finalMobileData  
 FROM #MobileCount mob  
  
 ------ Mobile End  
 ------ Email Start  
 SELECT   
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  1 AS Holder  
 INTO #EmailData  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsEmailPresent  = 1 AND rest.IsEmailPresent = 1 AND sel.Email = rest.Email  
  
 INSERT INTO #EmailData  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  1 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.IsEmailPresent  = 1 AND rest.IsEmailPresent = 1 AND sel.Email = rest.Email  
  AND sel.RefClientId <> rest.RefClientId  
  
 INSERT INTO #EmailData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  2 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsEmailPresent  = 1 AND rest.IsSecondHolderEmailPresent = 1 AND sel.Email = rest.SecondHolderEmail  
 WHERE NOT EXISTS (SELECT 1 FROM #EmailData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 INSERT INTO #EmailData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  2 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.IsEmailPresent  = 1 AND rest.IsSecondHolderEmailPresent = 1AND sel.Email = rest.SecondHolderEmail  
  AND sel.RefClientId <> rest.RefClientId  
 WHERE NOT EXISTS (SELECT 1 FROM #EmailData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 INSERT INTO #EmailData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  3 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsEmailPresent  = 1 AND rest.IsThirdHolderEmailPresent = 1 AND sel.Email = rest.ThirdHolderEmail  
 WHERE NOT EXISTS (SELECT 1 FROM #EmailData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 INSERT INTO #EmailData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec,  
  3 AS Holder  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.IsEmailPresent  = 1 AND rest.IsThirdHolderEmailPresent = 1 AND sel.Email = rest.ThirdHolderEmail  
  AND sel.RefClientId <> rest.RefClientId  
 WHERE NOT EXISTS (SELECT 1 FROM #EmailData dat WHERE dat.Pri = sel.RefClientId AND dat.Sec = rest.RefClientId)  
  
 SELECT  
  Pri,  
  COUNT(Sec) AS CommonEmailId  
 INTO #EmailCount  
 FROM #EmailData  
 GROUP BY Pri  
 HAVING COUNT(Sec)>=@EmailId  
  
 SELECT DISTINCT  
  email.Pri AS RefClientId,  
  email.CommonEmailId,  
  'Email - ' + STUFF((SELECT DISTINCT ',' + client.ClientId + CASE WHEN t.Holder = 1 THEN '' ELSE '(' +CONVERT(VARCHAr, t.Holder )+ ')' END   
   FROM #EmailData t   
   INNER JOIN dbo.RefClient client ON client.RefClientId  = t.Sec  
   WHERE t.Pri = email.Pri  
   FOR XML PATH ('')), 1, 1, '') AS EmailDesc,  
   STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(MAX),t.Sec)    
   FROM #EmailData t     
   WHERE t.Pri = email.Pri    
   FOR XML PATH ('')), 1, 1, '') AS MatchingRefClientid  
 INTO #finalEmailData  
 FROM #EmailCount email  
  
  
 ------ Email End  
 ------ Bank Start  
 DECLARE @RefEntityTyepId INT  
 SELECT @RefEntityTyepId = RefEntityTypeId FROM dbo.RefEntityType WHERE Code = 'Client'  
  
 SELECT  
  sel.RefClientId,  
  bank.BankAccNo  
 INTO #bankAccounts  
 FROM #selectedClients sel  
 INNER JOIN dbo.LinkRefClientRefBankMicr bank ON sel.RefClientId = bank.RefClientId  
  AND ISNULL(bank.BankAccNo,'') <> ''  
  
 INSERT #bankAccounts  
 SELECT  
  sel.RefClientId,  
  bank.BankAccountNo AS BankAccNo  
 FROM #selectedClients sel  
 INNER JOIN dbo.CoreCRMBankAccount bank ON bank.RefEntityTypeId = @RefEntityTyepId  
  AND sel.RefClientId = bank.EntityId AND ISNULL( bank.BankAccountNo,'') <> ''  
  
 INSERT #bankAccounts  
 SELECT  
  rest.RefClientId,  
  bank.BankAccNo  
 FROM #restClients rest  
 INNER JOIN dbo.LinkRefClientRefBankMicr bank ON rest.RefClientId = bank.RefClientId  
  AND ISNULL(bank.BankAccNo,'') <> ''  
  
 INSERT #bankAccounts  
 SELECT  
  rest.RefClientId,  
  bank.BankAccountNo AS BankAccNo  
 FROM #restClients rest  
 INNER JOIN dbo.CoreCRMBankAccount bank ON bank.RefEntityTypeId = @RefEntityTyepId  
  AND rest.RefClientId = bank.EntityId AND ISNULL( bank.BankAccountNo,'') <> ''  
  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec  
 INTO #BankData  
 FROM #selectedClients sel  
 INNER JOIN #bankAccounts bank ON sel.RefClientId = bank.RefClientId  
 INNER JOIN #bankAccounts bank1 ON sel.RefClientId <> bank1.RefClientId AND bank.BankAccNo = bank1.BankAccNo  
 LEFT JOIN #restClients rest ON rest.RefClientId = bank1.RefClientId  
  
 INSERT INTO #BankData  
 SELECT DISTINCT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec  
 FROM #selectedClients sel  
 INNER JOIN #bankAccounts bank ON sel.RefClientId = bank.RefClientId  
 INNER JOIN #bankAccounts bank1 ON sel.RefClientId <> bank1.RefClientId AND bank.BankAccNo = bank1.BankAccNo  
 INNER JOIN #selectedClients rest ON rest.RefClientId = bank1.RefClientId  
  
 Drop TABLE #bankAccounts  
  
 SELECT  
  Pri,  
  COUNT(Sec) AS CommonBankACNo  
 INTO #BankCount  
 FROM #BankData  
 GROUP BY Pri  
 HAVING COUNT(sec)>=@BankACNoId  
  
  
 SELECT DISTINCT  
  bank.Pri AS RefClientId,  
  bank.CommonBankACNo,  
  'Bank A/C No - ' + STUFF((SELECT DISTINCT ',' + client.ClientId   
   FROM #BankData t   
   INNER JOIN dbo.RefClient client ON client.RefClientId = t.Sec   
   WHERE t.Pri = bank.Pri  
   FOR XML PATH ('')), 1, 1, '') AS BankDesc,  
   STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(MAX),t.Sec)    
   FROM #BankData t     
   WHERE t.Pri = bank.Pri    
   FOR XML PATH ('')), 1, 1, '') AS MatchingRefClientid  
 INTO #finalBankData  
 FROM #BankCount bank  
 INNER JOIN #BankData dat ON bank.Pri = dat.Pri  
  
 ------ Bank End  
 ------ Address Start  
 --clietn to rest matching part 1   
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec  
 INTO #AddressData  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsPAddressPresent = 1 AND rest.IsPAddressPresent  = 1  
 AND sel.PAddress  =  rest.PAddress  
  
 --clietn to rest matching part 2   
 INSERT INTO #AddressData  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsPAddressPresent = 1 AND rest.IsCAddressPresent  = 1  
 AND sel.PAddress  =  rest.CAddress  
 --clietn to rest matching part 3   
 INSERT INTO #AddressData  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsCAddressPresent = 1 AND rest.IsPAddressPresent  = 1  
 AND rest.PAddress  =  sel.CAddress  
  
 --clietn to rest matching part 4   
 INSERT INTO #AddressData  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec  
 FROM #selectedClients sel  
 INNER JOIN #restClients rest ON sel.IsCAddressPresent = 1 AND rest.IsCAddressPresent  = 1  
 AND rest.CAddress  =  sel.CAddress  
  
 --SELECT  
 -- sel.RefClientId AS Pri,  
 -- rest.RefClientId AS Sec  
 --INTO #AddressData  
 --FROM #selectedClients sel  
 --INNER JOIN #restClients rest ON (sel.IsPAddressPresent = 1 AND (sel.PAddress  =  rest.PAddress OR sel.PAddress = rest.CAddress))  
 -- OR (sel.IsCAddressPresent = 1 AND (sel.CAddress  = rest.PAddress OR sel.CAddress  =  rest.CAddress))  
  
 --INSERT INTO #AddressData  
 --SELECT  
 -- sel.RefClientId AS Pri,  
 -- rest.RefClientId AS Sec  
 --FROM #selectedClients sel  
 --INNER JOIN #selectedClients rest ON  ((sel.IsPAddressPresent = 1 AND (sel.PAddress  =  rest.PAddress OR sel.PAddress = rest.CAddress))  
 -- OR (sel.IsCAddressPresent = 1 AND (sel.CAddress  = rest.PAddress OR sel.CAddress  =  rest.CAddress)))  
 -- AND sel.RefClientId <> rest.RefClientId  
  
 --clietn to clietn matching part 1   
 INSERT INTO #AddressData  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec  
   
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.IsPAddressPresent = 1 AND rest.IsPAddressPresent  = 1  
 AND sel.PAddress  =  rest.PAddress AND rest.RefClientId<>sel.RefClientId  
  
 --clietn to clietn matching part 2   
 INSERT INTO #AddressData  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.IsPAddressPresent = 1 AND rest.IsCAddressPresent  = 1  
 AND sel.PAddress  =  rest.CAddress AND rest.RefClientId<>sel.RefClientId  
 --clietn to clietn matching part 3   
 INSERT INTO #AddressData  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.IsCAddressPresent = 1 AND rest.IsPAddressPresent  = 1  
 AND rest.PAddress  =  sel.CAddress AND rest.RefClientId<>sel.RefClientId  
  
 --clietn to clietn matching part 4   
 INSERT INTO #AddressData  
 SELECT  
  sel.RefClientId AS Pri,  
  rest.RefClientId AS Sec  
 FROM #selectedClients sel  
 INNER JOIN #selectedClients rest ON sel.IsCAddressPresent = 1 AND rest.IsCAddressPresent  = 1  
 AND rest.CAddress  =  sel.CAddress AND rest.RefClientId<>sel.RefClientId  
  
 SELECT distinct  
  Pri,  
  Sec  
 INTO #distinctAddress  
 FROM #AddressData  
  
 SELECT  
  Pri,  
  COUNT(Sec) AS CommonAddress  
 INTO #AddressCount  
 FROM #distinctAddress  
 GROUP BY Pri  
 HAVING COUNT(Sec)>=@AddressId  
  
 DROP TABLE #distinctAddress  
  
 SELECT DISTINCT  
  addr.Pri AS RefClientId,  
  addr.CommonAddress,  
  'Address - ' + STUFF((SELECT DISTINCT ',' + client.ClientId   
   FROM #AddressData t   
   INNER JOIN dbo.RefClient client oN client.RefClientId = t.Sec  
   WHERE t.Pri = addr.Pri  
   FOR XML PATH ('')), 1, 1, '') AS AddrDesc,  
   STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR(MAX),t.Sec)    
   FROM #AddressData t     
   WHERE t.Pri = addr.Pri    
   FOR XML PATH ('')), 1, 1, '') AS MatchingRefClientid  
 INTO #finalAddressData  
 FROM #AddressCount addr  
 INNER JOIN #AddressData dat ON addr.Pri = dat.Pri  
  
 ------ Address End  
 Drop TABLE #selectedClients  
 Drop TABLE #restClients  
  
 Create TABLE #clientIds(RefClientId INT NOT NULL,MatchingRefClientId INT NOT NULL)  
  
 INSERT INTO #clientIds(RefClientId,MatchingRefClientId)  
 SELECT Pri as RefClientId,Sec as MatchingRefClientid  
 FROM (  
  SELECT DISTINCT p.Pri,Sec  
  --INTO #clientIds  
  FROM #PanData p  
  INNER JOIN #PanCount c ON c.Pri=p.Pri  
  --WHERE CommonPan >= @PanId  
  UNION  
  --INSERT INTO #clientIds  
  SELECT DISTINCT m.Pri,Sec  
  FROM #MobileData m  
  INNER JOIN #MobileCount c ON c.Pri=m.Pri  
  --WHERE CommonMobileNo >= @MobileNoId  
  --AND NOT EXISTS (SELECT 1 FROM #clientIds ids WHERE ids.RefClientId = dat.RefClientId)  
  UNION  
  --INSERT INTO #clientIds  
  SELECT DISTINCT e.Pri,sec  
  FROM #EmailData e  
  INNER JOIN #EmailCount c ON c.Pri=e.Pri  
  --WHERE CommonEmailId >= @EmailId  
  --AND NOT EXISTS (SELECT 1 FROM #clientIds ids WHERE ids.RefClientId = dat.RefClientId)  
  UNION  
  --INSERT INTO #clientIds  
  SELECT DISTINCT b.Pri,Sec  
  FROM #BankData b  
  INNER JOIN #BankCount c ON c.Pri=b.Pri  
  --WHERE CommonBankACNo >= @BankACNoId  
  --AND NOT EXISTS (SELECT 1 FROM #clientIds ids WHERE ids.RefClientId = dat.RefClientId)  
  UNION  
  --INSERT INTO #clientIds  
  SELECT DISTINCT a.Pri,Sec  
  FROM #AddressData a  
  INNER JOIN #AddressCount c ON c.Pri=a.Pri   
  --WHERE CommonAddress >= @AddressId  
  --AND NOT EXISTS (SELECT 1 FROM #clientIds ids WHERE ids.RefClientId = dat.RefClientId)  
  ) t  
  
  DROP TABLE #PanCount  
  DROP TABLE #AddressCount  
  DROP TABLE #BankCount  
  DROP TABLE #EmailCount  
  DROP TABLE #MobileCount  
  DROP TABLE #AddressData  
  DROP TABLE #BankData  
  DROP TABLE #EmailData  
  DROP TABLE #PanData  
  DROP TABLE #MobileData  
  
  select DISTINCT RefClientId  
  INTO #distinctClientIds  
  from #clientIds  
  
  
  select cl.RefClientId,STUFF((SELECT DISTINCT ',' + CAST(t.MatchingRefClientId as varchar)  
    FROM #clientIds t   
    WHERE t.RefClientId = cl.RefClientId  
    FOR XML PATH('')), 1, 1, '') AS [MatchingRefClientIds]  
   INTO #MatchingRefClients  
  from #distinctClientIds cl  
  
  
  
 SELECT  
  ids.RefClientId,  
  cl.ClientId,  
  cl.[Name] AS ClientName,  
  cl.AccountOpeningDate,  
  ISNULL(pan.CommonPan, 0) AS CommonPan,  
  ISNULL(mob.CommonMobileNo, 0 ) AS CommonMobileNo,  
  ISNULL(email.CommonEmailId, 0) AS CommonEmailId,  
  ISNULL(bank.CommonBankACNo, 0) AS CommonBankACNo,  
  ISNULL(addr.CommonAddress, 0) AS CommonAddress,  
  REPLACE(ISNULL(pan.PanDesc + ' ; ', '') + ISNULL(mob.MobDesc + ' ; ', '') +   
  ISNULL(email.EmailDesc + ' ; ', '') + ISNULL(bank.BankDesc + ' ; ', '') +   
  ISNULL(addr.AddrDesc + ' ; ', '') + ';;', ' ; ;;', '') AS [Description],  
  mrc.MatchingRefClientIds ,
  CASE 
	WHEN cl.RefClientDatabaseEnumId = @CdslId THEN @cdsl
	WHEN cl.RefClientDatabaseEnumId = @NsdlId THEN @nsdl
	ELSE NULL
  END AS RefSegmentId
 FROM #distinctClientIds ids  
 INNER JOIN dbo.RefClient cl ON ids.RefClientId = cl.RefClientId 
 INNER JOIN #MatchingRefClients mrc ON mrc.RefClientId = ids.RefClientId  
 LEFT JOIN #finalPanData pan ON ids.RefClientId = pan.RefClientId  
 LEFT JOIN #finalMobileData mob ON ids.RefClientId = mob.RefClientId  
 LEFT JOIN #finalEmailData email ON ids.RefClientId = email.RefClientId  
 LEFT JOIN #finalBankData bank ON ids.RefClientId = bank.RefClientId  
 LEFT JOIN #finalAddressData addr on ids.RefClientId = addr.RefClientId  
   
 END  
GO
----	RC-WEB-69524-end
----	RC-WEB-69524-start-s837
GO
 ALTER PROCEDURE dbo.AML_GetFrequentChangeinClientKYC (    
 @RunDate DATETIME,    
 @ReportId INT    
)    
AS    
BEGIN    
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @DaysChangeThresh INT, @NoOfDaysThresh INT,    
  @TradingId INT, @NSDLId INT, @CDSLId INT, @S166Id INT, @S837Id INT, @FromDate DATETIME,    
  @ToDate DATETIME, @RefEntityTypeId INT ,@InActiveCdsl INT, @ClosedCdsl INT,@ClosedNsdl INT ,@cdsl INT,@nsdl INT    
    
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)    
 SET @ReportIdInternal = @ReportId    
 SELECT @DaysChangeThresh = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Threshold_Quantity'    
 SELECT @NoOfDaysThresh = CONVERT(INT, [Value]) - 1    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Quantity'    
 SELECT @TradingId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'Trading' 
 
 SELECT @CdslId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'    
 SELECT @NsdlId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'   
 
 SELECT @cdsl = RefSegmentEnumId FROM  dbo.RefSegmentEnum ref WHERE Segment='CDSL'
 SELECT @nsdl = RefSegmentEnumId FROM  dbo.RefSegmentEnum ref WHERE Segment='NSDL'

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
 WHERE (ExcludeAllScenarios = 1 OR RefAmlReportId = @ReportIdInternal)    
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)    
    
 SELECT    
  audi.RefClientId,    
  audi.AuditDateTime,    
  audi.PAN,    
  audi.Mobile,    
  audi.Email,    
  dbo.RemoveMatchingCharacters(ISNULL(audi.PAddressLine1, '') + ISNULL(audi.PAddressLine2, '') +     
   ISNULL(audi.PAddressLine3, '') + ISNULL(audi.PAddressPin, '') +     
   ISNULL(audi.PAddressCity, '') + ISNULL(audi.PAddressState, '') +     
   ISNULL(audi.PAddressCountry, ''), '^0-9a-z') AS PAddress,   
  dbo.RemoveMatchingCharacters(ISNULL(audi.CAddressLine1, '') + ISNULL(audi.CAddressLine2, '') +     
   ISNULL(audi.CAddressLine3, '') + ISNULL(audi.CAddressPin, '') +     
   ISNULL(audi.CAddressCity, '') + ISNULL(audi.CAddressState, '') +     
   ISNULL(audi.CAddressCountry, ''), '^0-9a-z') AS CAddress,    
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
   OR ISNULL(a1.PAddress, '') <> ISNULL(a2.PAddress, '') OR ISNULL(a1.CAddress, '') <> ISNULL(a2.CAddress, ''))    
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
  (CASE WHEN ISNULL(a1.PAddress, '') <> ISNULL(a2.PAddress, '') THEN 1 ELSE 0 END) AS PAddressChange,    
  (CASE WHEN ISNULL(a1.CAddress, '') <> ISNULL(a2.CAddress, '') THEN 1 ELSE 0 END) AS CAddressChange    
 INTO #changes    
 FROM #auditDetails a1    
 INNER JOIN #auditDetails a2 ON a1.RefClientId = a2.RefClientId    
  AND a1.AuditDateTime = a2.AuditDateTime    
  AND (a1.PAN <> a2.PAN OR a1.Email <> a2.Email OR a1.Mobile <> a2.Mobile    
   OR ISNULL(a1.PAddress, '') <> ISNULL(a2.PAddress, '') OR ISNULL(a1.CAddress, '') <> ISNULL(a2.CAddress, ''))    
 WHERE a1.AuditState = 1 AND a2.AuditState = 0    
    
 DROP TABLE #auditDetails    
    
 SELECT DISTINCT    
  bank.RefClientId,    
  dbo.GetDateWithoutTime(bank.AuditDateTime) AS AuditDate    
 INTO #bank1    
 FROM #changedClients runDay    
 INNER JOIN dbo.LinkRefClientRefBankMicr_Audit bank ON runDay.RefClientId = bank.RefClientId    
 WHERE bank.BankAccNo <> '' AND (bank.AuditDatetime BETWEEN @FromDate AND @ToDate)   
  AND bank.AuditDmlAction = 'Update'  
    
 SELECT DISTINCT    
  runDay.RefClientId,    
  dbo.GetDateWithoutTime(bank.AuditDateTime) AS AuditDate    
 INTO #bank2    
 FROM #changedClients runDay    
 INNER JOIN dbo.CoreCRMBankAccount_Audit bank ON bank.EntityId = runDay.RefClientId    
 WHERE bank.RefEntityTypeId = @RefEntityTypeId AND  bank.BankAccountNo <> ''     
  AND (bank.AuditDatetime BETWEEN @FromDate AND @ToDate)  
  AND bank.AuditDmlAction = 'Update'  
    
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
    
 END    
 ELSE BEGIN   
  
  SELECT  
   runDay.RefClientId,  
   keyP.AddedOn  
  INTO #ASData  
  FROM #changedClients runDay  
  INNER JOIN dbo.LinkVirtRefClientRefKeyPerson keyP ON runDay.RefClientId = keyP.RefClientId  
   AND keyP.RefDesignationId = @ASDesignationId  
  
  SELECT  
   runDay.RefClientId,  
   dbo.GetDateWithoutTime(runDay.AddedOn) AS AddedOn,  
   COUNT(temp.LinkVirtRefClientRefKeyPersonId) AS ASKeyPersons  
  INTO #ASCounts  
  FROM #ASData runDay  
  INNER JOIN  dbo.LinkVirtRefClientRefKeyPerson temp ON runDay.RefClientId = temp.RefClientId   
   AND temp.RefDesignationId = @ASDesignationId AND temp.AddedOn <= runDay.AddedOn  
  GROUP BY runDay.RefClientId, runDay.AddedOn  
  
  SELECT  
   runDay.RefClientId,  
   audi.AuditDateTime,  
   audi.AuditDmlAction,  
   CASE WHEN audi.AuditDataState = 'New' THEN 1 ELSE 0 END AS AuditState,  
   audi.RefDesignationId,  
   audi.LinkVirtRefClientRefKeyPersonId  
  INTO #kpAuditDetails  
  FROM #changedClients runDay   
  INNER JOIN dbo.LinkVirtRefClientRefKeyPerson_Audit audi ON runDay.RefClientId = audi.RefClientId    
   AND audi.AuditDatetime BETWEEN @FromDate AND @ToDate  
    
  SELECT DISTINCT    
   audi1.RefClientId,    
   dbo.GetDateWithoutTime(audi1.AuditDateTime) AS AuditDate,    
   1 AS DesignationChange    
  INTO #desginations    
  FROM #kpAuditDetails audi1  
  LEFT JOIN #kpAuditDetails audi2 ON audi1.LinkVirtRefClientRefKeyPersonId = audi2.LinkVirtRefClientRefKeyPersonId  
   AND audi1.AuditDateTime = audi2.AuditDateTime  
  LEFT JOIN #ASCounts counts ON counts.RefClientId = audi1.RefClientId  
   AND counts.AddedOn = dbo.GetDateWithoutTime(audi1.AuditDateTime)  
  WHERE (audi1.AuditState = 1 AND audi2.AuditState = 0  
    AND audi1.AuditDmlAction = 'Update'  
    AND (audi1.RefDesignationId = @ASDesignationId OR audi2.RefDesignationId = @ASDesignationId)  
    AND audi1.RefDesignationId <> audi2.RefDesignationId)   
   OR (counts.ASKeyPersons > 1 AND audi1.AuditDmlAction = 'Insert'  
    AND audi1.RefDesignationId = @ASDesignationId)  
      
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
    FOR XML PATH ('')), 1, 3, '') AS [Description],
  CASE 
	WHEN cl.RefClientDatabaseEnumId = @CdslId THEN @cdsl
	WHEN cl.RefClientDatabaseEnumId = @NsdlId THEN @nsdl
	ELSE NULL
  END AS RefSegmentId    
  FROM #intoSelectedData sel    
  INNER JOIN dbo.RefClient cl ON sel.RefClientId = cl.RefClientId    
  INNER JOIN #dateData2 dt ON sel.PAN = dt.PAN    
  WHERE dt.NoOfDays >= @DaysChangeThresh AND (cl.AccountClosingDate IS NULL OR cl.AccountClosingDate > @RunDateInternal)  
  AND ISNULL(cl.RefClientAccountStatusId  ,0) NOT IN (@InActiveCdsl,@ClosedCdsl,@ClosedNsdl)  
    
 END    
END    
GO
----	RC-WEB-69524-end
----	RC-WEB-69524-start-s838
GO
  ALTER PROCEDURE dbo.AML_MultipleTimesCommunicationBounced     
(    
 @RunDate DATETIME,    
 @ReportId INT    
)    
AS    
BEGIN    
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT,    
  @MailThreshold INT, @LetterThreshold INT,    
  @FromDate DATETIME, @ToDate DATETIME,    
  @CDSLId INT, @NSDLId INT, @MailEnumId INT, @LetterEnumId INT ,@cdsl INT,@nsdl INT    
    
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)    
 SET @ReportIdInternal = @ReportId    
    
 SELECT @MailThreshold = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting     
 WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Threshold_Quantity'    
    
 SELECT @LetterThreshold = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting     
 WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Quantity'    
    
 SET @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @RunDateInternal) -1, 0)    
 SET @ToDate = DATEADD(SECOND, -1, DATEADD(MONTH, 1,  DATEADD(MONTH, DATEDIFF(MONTH, 0, @RunDateInternal)-1 , 0) ) )    
    
 SET @MailEnumId = dbo.GetEnumValueId('BounceMail', 'C1')    
 SET @LetterEnumId = dbo.GetEnumValueId('BounceMail', 'C2')    
    
 SELECT    
  RefClientId    
 INTO #clientsToExclude    
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
 WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportIdInternal)     
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)    
     
 SELECT @CDSLId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'    
 SELECT @NSDLId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL' 

 SELECT @cdsl = RefSegmentEnumId FROM  dbo.RefSegmentEnum ref WHERE Segment='CDSL'
 SELECT @nsdl = RefSegmentEnumId FROM  dbo.RefSegmentEnum ref WHERE Segment='NSDL'
    
    
 SELECT    
  bounce.RefClientBounceMailId,    
  bounce.RefClientId,    
  bounce.BounceMailTypeRefEnumValueId,    
  bounce.SentOn,    
  bounce.FromAddress,    
  bounce.ToAddress,    
  client.ClientId,    
  client.[Name] AS ClientName,
  client.RefClientDatabaseEnumId
 INTO #ClientsData    
 FROM dbo.RefClientBounceMail bounce    
 INNER JOIN dbo.RefClient client    
  ON bounce.RefClientId = client.RefClientId    
  AND client.RefClientDatabaseEnumId IN(@CDSLId, @NSDLId)    
 LEFT JOIN #clientsToExclude exclude    
  ON exclude.RefClientId = bounce.RefClientId    
 WHERE     
   SentOn >= @FromDate    
  AND SentOn <=@ToDate    
  AND exclude.RefClientId IS NULL    
 ORDER BY bounce.SentOn    
    
    
 DROP TABLE #clientsToExclude    
    
 SELECT    
  clients.RefClientId,    
  clients.BounceMailTypeRefEnumValueId,    
  COUNT(clients.RefClientBounceMailId) AS  BouncedNumber  
 INTO #countData    
 FROM #ClientsData clients    
 GROUP BY    
   clients.RefClientId,    
   clients.BounceMailTypeRefEnumValueId   
    
 SELECT    
  cd.BouncedNumber,    
  clients.RefClientId,    
  clients.ClientId,    
  clients.ClientName,    
  clients.BounceMailTypeRefEnumValueId,    
  clients.RefClientBounceMailID,
  clients.RefClientDatabaseEnumId    
 INTO #AlertData    
 FROM #countData cd    
 INNER JOIN #ClientsData clients    
 ON cd.RefClientId = clients.RefClientId    
 AND cd.BounceMailTypeRefEnumValueId = clients.BounceMailTypeRefEnumValueId    
    
    
 DROP TABLE #countData    
    
 SELECT    
  alerts.RefClientId,    
  alerts.ClientId,    
  alerts.ClientName,    
  CASE    
   WHEN alerts.BounceMailTypeRefEnumValueId = @MailEnumId     
   THEN COUNT(alerts.RefClientBounceMailID)    
   ELSE 0    
  END AS Number_EmailBounced,    
  CASE    
   WHEN alerts.BounceMailTypeRefEnumValueId = @LetterEnumId     
   THEN COUNT(alerts.RefClientBounceMailID)    
   ELSE 0    
  END AS Number_LetterReturned,
  alerts.RefClientDatabaseEnumId 
 INTO #BounceCountsData    
 FROM #AlertData alerts    
 GROUP BY     
   alerts.RefClientId,    
   alerts.BounceMailTypeRefEnumValueId,    
   alerts.ClientId,    
   alerts.ClientName,
   alerts.RefClientDatabaseEnumId     
    
 DROP TABLE #AlertData    
    
 SELECT    
  bd.RefClientId,    
  bd.ClientId,    
  bd.ClientName,    
  @FromDate AS FromDate,    
  @ToDate AS ToDate,    
  SUM(bd.Number_EmailBounced) AS Number_EmailBounced,    
  SUM(bd.Number_LetterReturned) AS Number_LetterReturned,
  bd.RefClientDatabaseEnumId    
 INTO #FinalData    
 FROM #BounceCountsData bd    
 GROUP BY     
   bd.RefClientId,    
   bd.ClientId,    
   bd.ClientName,
   bd.RefClientDatabaseEnumId   
   
 SELECT    
  fd.RefClientId,    
  fd.ClientId,    
  fd.ClientName,    
  fd.FromDate,    
  fd.ToDate,    
  fd.Number_EmailBounced,    
  CASE     
   WHEN fd.Number_EmailBounced>0    
   THEN    
    STUFF( (SELECT DISTINCT ' , ' + cd.FromAddress    
      FROM #ClientsData cd    
      WHERE cd.RefClientId = fd.RefClientId    
      AND cd.BounceMailTypeRefEnumValueId = @MailEnumId    
      FOR XML PATH ('')    
      ),1,3, '')    
   ELSE ''    
  END AS FromAddress,    
  CASE     
   WHEN fd.Number_EmailBounced>0    
   THEN    
    STUFF( (SELECT DISTINCT  ' , ' + cd.ToAddress    
      FROM #ClientsData cd    
      WHERE cd.RefClientId = fd.RefClientId    
      AND cd.BounceMailTypeRefEnumValueId = @MailEnumId    
      FOR XML PATH ('')    
      ),1,3, '')    
   ELSE ''    
  END AS ToAddress,    
  fd.Number_LetterReturned,    
  CASE     
   WHEN fd.Number_LetterReturned >0    
   THEN    
    STUFF( (SELECT DISTINCT ' ; ' + cd.ToAddress    
      FROM #ClientsData cd    
      WHERE cd.RefClientId = fd.RefClientId    
      AND cd.BounceMailTypeRefEnumValueId = @LetterEnumId    
      FOR XML PATH ('')    
      ),1,3, '')    
   ELSE ''    
  END AS SendAddress,    
  (    
  CASE    
   WHEN fd.Number_EmailBounced>0    
   THEN     
    STUFF( (SELECT DISTINCT  ' , ' + REPLACE(CONVERT(varchar, cd.SentOn, 106), ' ', '-')    
      FROM #ClientsData cd    
      WHERE cd.RefClientId = fd.RefClientId    
      AND cd.BounceMailTypeRefEnumValueId = @MailEnumId    
      FOR XML PATH ('')    
      ),1,3, 'Email: ') + '  '    
   ELSE ''    
  END    
  +    
  CASE    
   WHEN fd.Number_LetterReturned>0    
   THEN     
    STUFF( (SELECT DISTINCT ' , ' + REPLACE(CONVERT(varchar, cd.SentOn, 106), ' ', '-')    
      FROM #ClientsData cd    
      WHERE cd.RefClientId = fd.RefClientId    
      AND cd.BounceMailTypeRefEnumValueId = @LetterEnumId    
      FOR XML PATH ('')    
      ),1,3, 'Letter: ')    
   ELSE ''    
  END    
  ) AS DateOfInstances,
  CASE 
	WHEN fd.RefClientDatabaseEnumId = @CdslId THEN @cdsl
	WHEN fd.RefClientDatabaseEnumId = @NsdlId THEN @nsdl
	ELSE NULL
  END AS RefSegmentId    
 FROM #FinalData fd    
 WHERE    
  fd.Number_EmailBounced >= @MailThreshold    
  OR fd.Number_LetterReturned >= @LetterThreshold    

END    
GO
----	RC-WEB-69524-end
