DECLARE
 @RunDate DATETIME = '2022-oct-18',  
 @ReportId INT  = 1228

 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT,  
   @PanCount INT, @MobileNoCount INT, @EmailCount INT,  @IsFamilyDeclaration BIT,
   @BankACNoCount INT, @AddressCount INT,  
   @NsdlDbId INT, @CdslDbId INT, @CdslSegmentId INT, @NsdlSegmentId INT,  
   @ToDate DATETIME, @ClientEntityTypeId INT  , @customFromDate DATETIME
   , @CustomToDate DATETIME

   SET @customFromDate = @RunDate
   SET @CustomToDate = @RunDate
  
 SELECT @ClientEntityTypeId = RefEntityTypeId FROM dbo.RefEntityType WHERE Code = 'Client'  
 SET @RunDateInternal = dbo.GetDateWithoutTime(@customFromDate)  
 SET @ReportIdInternal = @ReportId  
 SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, dbo.GetDateWithoutTime(@CustomToDate))) + CONVERT(DATETIME, '23:59:59.000')  
   
 SELECT @PanCount = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'PAN'  
  
 SELECT @MobileNoCount = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Mobile_No'  
  
 SELECT @EmailCount = CONVERT(DECIMAL, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Email_Id'  
  
 SELECT @BankACNoCount = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Bank_AC_No'  
  
 SELECT @AddressCount = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Address'  

 SELECT @IsFamilyDeclaration = CONVERT(BIT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Family_Declaration'  
  
  
 SELECT @CdslDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'  
 SELECT @NsdlDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'   
   
 SELECT @CdslSegmentId = RefSegmentEnumId FROM dbo.RefSegmentEnum ref WHERE Segment='CDSL'  
 SELECT @NsdlSegmentId = RefSegmentEnumId FROM dbo.RefSegmentEnum ref WHERE Segment='NSDL'  
  
 -- client to exclude  
 SELECT  
  RefClientId  
 INTO #clientsToExclude  
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion  
 WHERE (ExcludeAllScenarios=1 OR RefAmlReportId = @ReportIdInternal)  
 AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)   
   
 --to exclude closed clients   
 SELECT RefClientAccountStatusId   
 INTO #statusToExclude   
 FROM dbo.RefClientAccountStatus  
 WHERE RefClientDatabaseEnumId in (@CdslDbId, @NsdlDbId)  
 AND [Name] in ('Closed', 'Closed, Cancelled by DP')  


 SELECT cl.RefClientId, cl.AccountOpeningDate, cl.AccountClosingDate, cl.ClientId, cl.IsFamilyDeclaration
 INTO #clients
 FROM dbo.RefClient cl   
 LEFT JOIN #statusToExclude statusEx ON statusEx.RefClientAccountStatusId = cl.RefClientAccountStatusId   
 LEFT JOIN #clientsToExclude clEx ON cl.RefClientId = clEx.RefClientId  
 WHERE cl.RefClientDatabaseEnumId IN (@CdslDbId, @NsdlDbId)
 AND clEx.RefClientId IS NULL AND statusEx.RefClientAccountStatusId IS NULL 
  
 --TRUNCATE TABLE #clientsToExclude  
 --TRUNCATE TABLE #statusToExclude  
 
 CREATE CLUSTERED INDEX IX_client_dummy_index_S832
	ON #clients(RefClientId);
  
 SELECT   
  audi.RefClientId,   
  audi.AuditDateTime,   
  audi.PAN,  
  audi.Mobile,  
  audi.Email,  
    
  dbo.RemoveMatchingCharacters(ISNULL(audi.PAddressLine1, '') + ISNULL(audi.PAddressLine2, '') +  
  ISNULL(audi.PAddressLine3, ''), '^0-9a-z') AS PAddress,  
    
  dbo.RemoveMatchingCharacters(ISNULL(audi.CAddressLine1, '') + ISNULL(audi.CAddressLine2, '') +  
  ISNULL(audi.CAddressLine3, ''), '^0-9a-z') AS CAddress,   
    
  CASE WHEN audi.AuditDataState = 'Old' THEN 1 ELSE 0 END AS AuditState   
 INTO #runDayAuditDetails  
 FROM #clients cl
 INNER JOIN dbo.RefClient_Audit audi  ON cl.RefClientId = audi.RefClientId
 WHERE audi.AuditDatetime BETWEEN @RunDateInternal AND @ToDate  
  AND audi.AuditDmlAction = 'Update'   
  
 CREATE TABLE #ClientFieldsChanged  
 (  
  RefClientId INT NOT NULL,  
  ChangedField INT  
  /*************  
  NULL for new client account,  
  1 for mobile,  
  2 for Bank account number,  
  3 for Paddress,  
  4 for Caddress,  
  5 for emailid,  
  6 for pan  
  *************/  
 )  
  
 /*********************Clients Accounts Open on runday*********************/  
 INSERT INTO #ClientFieldsChanged (RefClientId)  
 SELECT  
  cls.RefClientId  
 FROM #clients cls
 WHERE(cls.AccountOpeningDate BETWEEN @RunDateInternal AND @ToDate)  
  AND (cls.AccountClosingDate IS NULL OR cls.AccountClosingDate > @RunDateInternal)  
  
 SELECT  
  a1.RefClientId,  
  
  a1.Mobile AS OldMobile,  
  a1.Email AS OldEmail,  
  a1.PAN AS OldPAN,  
  a1.PAddress AS OldPAddress, 
  a1.CAddress AS OldCAddress, 
  
  
  a2.Mobile AS NewMobile,  
  a2.Email AS NewEmail,  
  a2.PAN AS NewPAN,  
  a2.PAddress AS NewPAddress, 
  a2.CAddress AS NewCAddress

 INTO #auditDetails  
 FROM #runDayAuditDetails a1   
 INNER JOIN #runDayAuditDetails a2 ON a1.RefClientId = a2.RefClientId AND a1.AuditState = 1 AND a2.AuditState = 0 AND a1.AuditDateTime = a2.AuditDateTime  
 LEFT JOIN #ClientFieldsChanged runDayAdded ON a1.RefClientId = runDayAdded.RefClientId AND runDayAdded.ChangedField IS NULL  
 WHERE runDayAdded.RefClientId IS NULL  
  
 --TRUNCATE TABLE #runDayAuditDetails  
  
 /*********************mobile changed on runday*********************/  
 INSERT INTO #ClientFieldsChanged  
 (RefClientId, ChangedField)  
 SELECT DISTINCT   
  ad.RefClientId,  
  1  
 FROM #auditDetails ad   
 WHERE ad.OldMobile <> ad.NewMobile  
   
 /*********************bank account no changed on runday*********************/  
 INSERT INTO #ClientFieldsChanged  
 SELECT DISTINCT RefClientId, 2  
 FROM  
 (  
  SELECT   
   cls.RefClientId  
  FROM #clients cls     
  INNER JOIN dbo.LinkRefClientRefBankMicr_Audit bank ON bank.RefClientId = cls.RefClientId 
  LEFT JOIN #ClientFieldsChanged runDayAdded ON cls.RefClientId = runDayAdded.RefClientId AND runDayAdded.ChangedField IS NULL    
  WHERE runDayAdded.RefClientId IS NULL AND bank.AuditDatetime BETWEEN @RunDateInternal AND @ToDate AND bank.BankAccNo <> ''   
  
  UNION  
  
  SELECT   
   bank.EntityId AS RefClientId   
  FROM #clients cls  
  INNER JOIN dbo.CoreCRMBankAccount_Audit bank ON bank.EntityId = cls.RefClientId
  LEFT JOIN #ClientFieldsChanged runDayAdded ON cls.RefClientId = runDayAdded.RefClientId AND runDayAdded.ChangedField IS NULL  
  WHERE bank.RefEntityTypeId = @ClientEntityTypeId AND bank.BankAccountNo <> ''  
   AND (bank.AuditDatetime BETWEEN @RunDateInternal AND @ToDate)   
   AND runDayAdded.RefClientId IS NULL  
 )t  
  
 /*********************PAddress changed on runday*********************/  
 INSERT INTO #ClientFieldsChanged  
 (RefClientId, ChangedField)  
 SELECT DISTINCT   
  ad.RefClientId,  
  3  
  FROM #auditDetails ad   
  WHERE ad.OldPAddress <> ad.NewPAddress
  
  
 /*********************CAddress changed on runday*********************/  
 INSERT INTO #ClientFieldsChanged  
 (RefClientId, ChangedField)  
 SELECT DISTINCT   
  ad.RefClientId,  
  4  
  FROM #auditDetails ad   
 WHERE ad.OldCAddress <> ad.NewCAddress
  
 /*********************Email changed on runday*********************/  
 INSERT INTO #ClientFieldsChanged  
 (RefClientId, ChangedField)  
 SELECT DISTINCT   
  ad.RefClientId,  
  5  
 FROM #auditDetails ad   
 WHERE ad.OldEmail <> ad.NewEmail  
  
 /*********************PAN changed on runday*********************/  
 INSERT INTO #ClientFieldsChanged  
 (RefClientId, ChangedField)  
 SELECT DISTINCT   
  ad.RefClientId,  
  6  
 FROM #auditDetails ad   
 WHERE ad.OldPAN <> ad.NewPAN  
  
 --TRUNCATE TABLE #auditDetails  
  
 /*********************Fetching changed client details*********************/  
   
 SELECT DISTINCT RefClientId  
 INTO #DistinctClientsConsidered  
 FROM #ClientFieldsChanged  
  
 SELECT  
   t.RefClientId,  
   t.ClientId,
   t.Mobile,  
   t.SecondHolderMobile,  
   t.ThirdHolderMobile,
   t.Email,  
   t.SecondHolderEmail,  
   t.ThirdHolderEmail,  
   t.PAN,  
   t.SecondHolderPAN,  
   t.ThirdHolderPAN,  
   t.PAddress,  
   t.CAddress ,
   t.IsFamilyDeclaration, 
  
 CASE WHEN t.Mobile <> '' THEN 1 ELSE 0 END IsMobilePresent,   
 ASCII(LEFT(t.Mobile, 1)) AS MobileFirstAscii,
 ASCII(RIGHT(t.Mobile, 1)) AS MobileLastAscii,
 CASE WHEN t.SecondHolderMobile <> '' THEN 1 ELSE 0 END IsSecondHolderMobilePresent,   
 ASCII(LEFT(t.SecondHolderMobile, 1)) AS SecondHolderMobileFirstAscii,
 ASCII(RIGHT(t.SecondHolderMobile, 1)) AS SecondHolderMobileLastAscii,
 CASE WHEN t.ThirdHolderMobile <> '' THEN 1 ELSE 0 END IsThirdHolderMobilePresent,   
 ASCII(LEFT(t.ThirdHolderMobile, 1)) AS ThirdHolderMobileFirstAscii,
 ASCII(RIGHT(t.ThirdHolderMobile, 1)) AS ThirdHolderMobileLastAscii,
  
 CASE WHEN t.Email <> '' THEN 1 ELSE 0 END IsEmailPresent,  
 ASCII(LEFT(t.Email, 1)) AS EmailFirstAscii,

 CASE WHEN t.SecondHolderEmail <> '' THEN 1 ELSE 0 END IsSecondHolderEmailPresent, 
 ASCII(LEFT(t.SecondHolderEmail, 1)) AS SecondHolderEmailFirstAscii, 

 CASE WHEN t.ThirdHolderEmail <> '' THEN 1 ELSE 0 END IsThirdHolderEmailPresent,  
 ASCII(LEFT(t.ThirdHolderEmail, 1)) AS ThirdHolderEmailFirstAscii,
  
 CASE WHEN t.PAN <> '' THEN 1 ELSE 0 END IsPANPresent,  
 ASCII(LEFT(t.PAN, 1)) AS PANFirstAscii,
 ASCII(RIGHT(t.PAN, 1)) AS PANLastAscii,

 CASE WHEN t.SecondHolderPAN <> '' THEN 1 ELSE 0 END IsSecondHolderPANPresent, 
 ASCII(LEFT(t.SecondHolderPAN, 1)) AS SecondHolderPANFirstAscii, 
 ASCII(RIGHT(t.SecondHolderPAN, 1)) AS SecondHolderPANLastAscii, 

 CASE WHEN t.ThirdHolderPAN <> '' THEN 1 ELSE 0 END IsThirdHolderPANPresent,
	ASCII(LEFT(t.ThirdHolderPAN, 1)) AS ThirdHolderPANFirstAscii,
	ASCII(RIGHT(t.ThirdHolderPAN, 1)) AS ThirdHolderPANLastAscii,
  
 CASE WHEN t.PAddress <> '' THEN 1 ELSE 0 END AS IsPAddressPresent,  
 CASE WHEN t.CAddress <> '' THEN 1 ELSE 0 END AS IsCAddressPresent
  
 INTO #selectedClients  
 FROM  
 (  
  SELECT  
   cl.RefClientId,  
   cl.ClientId,  
    
   ISNULL(cl.Mobile, '') AS Mobile,  
   ISNULL(cl.SecondHolderMobile, '') AS SecondHolderMobile,  
   ISNULL(cl.ThirdHolderMobile, '') AS ThirdHolderMobile,  
  
   ISNULL(cl.Email, '') AS Email,  
   ISNULL(cl.SecondHolderEmail, '') AS SecondHolderEmail,  
   ISNULL(cl.ThirdHolderEmail, '') AS ThirdHolderEmail,  
  
   ISNULL(cl.PAN, '') AS PAN,  
   ISNULL(cl.SecondHolderPAN, '') AS SecondHolderPAN,  
   ISNULL(cl.ThirdHolderPAN, '') AS ThirdHolderPAN,  
  
   dbo.RemoveMatchingCharacters(ISNULL(cl.PAddressLine1, '') + ISNULL(cl.PAddressLine2, '') +  
   ISNULL(cl.PAddressLine3, ''), '^0-9a-z') AS PAddress,  
    
   dbo.RemoveMatchingCharacters(ISNULL(cl.CAddressLine1, '') + ISNULL(cl.CAddressLine2, '') +  
   ISNULL(cl.CAddressLine3, ''), '^0-9a-z') AS CAddress ,
   ISNULL(cl.IsFamilyDeclaration,0) As IsFamilyDeclaration
  FROM #DistinctClientsConsidered dc  
  INNER JOIN dbo.RefClient cl ON cl.RefClientId = dc.RefClientId  
 ) t  
  
  
 /*********************Fetching rest client details*********************/  
  
  
 SELECT cls.RefClientId  
 INTO #distinctRestClients_CTE
 FROM #clients cls 
 LEFT JOIN #DistinctClientsConsidered dcc ON dcc.RefClientId=cls.RefClientId  
 WHERE dcc.RefClientId IS NULL  
  AND (cls.AccountClosingDate IS NULL OR cls.AccountClosingDate > @RunDateInternal)  
  
   
 SELECT  
   t.RefClientId,  
   t.ClientId,
   t.Mobile,  
   t.SecondHolderMobile,  
   t.ThirdHolderMobile,
   t.Email,  
   t.SecondHolderEmail,  
   t.ThirdHolderEmail,  
   t.PAN,  
   t.SecondHolderPAN,  
   t.ThirdHolderPAN,  
   t.PAddress,  
   t.CAddress ,
   t.IsFamilyDeclaration,
   
	CASE WHEN t.Mobile <> '' THEN 1 ELSE 0 END IsMobilePresent,   
	ASCII(LEFT(t.Mobile, 1)) AS MobileFirstAscii,
	ASCII(RIGHT(t.Mobile, 1)) AS MobileLastAscii,
	CASE WHEN t.SecondHolderMobile <> '' THEN 1 ELSE 0 END IsSecondHolderMobilePresent,   
	ASCII(LEFT(t.SecondHolderMobile, 1)) AS SecondHolderMobileFirstAscii,
	ASCII(RIGHT(t.SecondHolderMobile, 1)) AS SecondHolderMobileLastAscii,
	CASE WHEN t.ThirdHolderMobile <> '' THEN 1 ELSE 0 END IsThirdHolderMobilePresent,   
	ASCII(LEFT(t.ThirdHolderMobile, 1)) AS ThirdHolderMobileFirstAscii,
	ASCII(RIGHT(t.ThirdHolderMobile, 1)) AS ThirdHolderMobileLastAscii,
	 
	CASE WHEN t.Email <> '' THEN 1 ELSE 0 END IsEmailPresent,  
	ASCII(LEFT(t.Email, 1)) AS EmailFirstAscii,

	CASE WHEN t.SecondHolderEmail <> '' THEN 1 ELSE 0 END IsSecondHolderEmailPresent, 
	ASCII(LEFT(t.SecondHolderEmail, 1)) AS SecondHolderEmailFirstAscii, 

	CASE WHEN t.ThirdHolderEmail <> '' THEN 1 ELSE 0 END IsThirdHolderEmailPresent,  
	ASCII(LEFT(t.ThirdHolderEmail, 1)) AS ThirdHolderEmailFirstAscii,
	 
	CASE WHEN t.PAN <> '' THEN 1 ELSE 0 END IsPANPresent,  
	ASCII(LEFT(t.PAN, 1)) AS PANFirstAscii,
	ASCII(RIGHT(t.PAN, 1)) AS PANLastAscii,

	CASE WHEN t.SecondHolderPAN <> '' THEN 1 ELSE 0 END IsSecondHolderPANPresent, 
	ASCII(LEFT(t.SecondHolderPAN, 1)) AS SecondHolderPANFirstAscii, 
	ASCII(RIGHT(t.SecondHolderPAN, 1)) AS SecondHolderPANLastAscii, 

	CASE WHEN t.ThirdHolderPAN <> '' THEN 1 ELSE 0 END IsThirdHolderPANPresent,  
	ASCII(LEFT(t.ThirdHolderPAN, 1)) AS ThirdHolderPANFirstAscii,
	ASCII(RIGHT(t.ThirdHolderPAN, 1)) AS ThirdHolderPANLastAscii,

   CASE WHEN t.PAddress <> '' THEN 1 ELSE 0 END AS IsPAddressPresent,  
   CASE WHEN t.CAddress <> '' THEN 1 ELSE 0 END AS IsCAddressPresent
  
 INTO #restClientsData  
 FROM  
 (  
  SELECT  
   cl.RefClientId,  
   cl.ClientId,  
    
   ISNULL(cl.Mobile, '') AS Mobile,  
   ISNULL(cl.SecondHolderMobile, '') AS SecondHolderMobile,  
   ISNULL(cl.ThirdHolderMobile, '') AS ThirdHolderMobile,  
  
   ISNULL(cl.Email, '') AS Email,  
   ISNULL(cl.SecondHolderEmail, '') AS SecondHolderEmail,  
   ISNULL(cl.ThirdHolderEmail, '') AS ThirdHolderEmail,  
  
   ISNULL(cl.PAN, '') AS PAN,  
   ISNULL(cl.SecondHolderPAN, '') AS SecondHolderPAN,  
   ISNULL(cl.ThirdHolderPAN, '') AS ThirdHolderPAN,  
  
   dbo.RemoveMatchingCharacters(ISNULL(cl.PAddressLine1, '') + ISNULL(cl.PAddressLine2, '') +  
   ISNULL(cl.PAddressLine3, ''), '^0-9a-z') AS PAddress,  
    
   dbo.RemoveMatchingCharacters(ISNULL(cl.CAddressLine1, '') + ISNULL(cl.CAddressLine2, '') +  
   ISNULL(cl.CAddressLine3, ''), '^0-9a-z') AS CAddress ,
   ISNULL(cl.IsFamilyDeclaration,0) As IsFamilyDeclaration
  FROM #distinctRestClients_CTE AS drc  
  INNER JOIN dbo.RefClient cl ON cl.RefClientId = drc.RefClientId  
 ) t  

 --TRUNCATE TABLE #DistinctClientsConsidered  
  
 SELECT  
  t.*,
  changed.ChangedField  
 INTO #clientsChangeMapping  
 FROM #ClientFieldsChanged changed  
 INNER JOIN #selectedClients t ON changed.RefClientId = t.RefClientId  
  
 /********************* Mobile match starts *********************/  
 CREATE TABLE #MobileMatchData (RefClientId INT, MatchingRefClientId INT, Holder INT)  
  
 INSERT INTO #MobileMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId AS SelectedRefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  1 AS Holder  
 FROM #clientsChangeMapping mapping  
 INNER JOIN #restClientsData rest ON ISNULL(mapping.ChangedField, 1) = 1  
  AND mapping.MobileFirstAscii = rest.MobileFirstAscii AND mapping.MobileLastAscii = rest.MobileLastAscii
  AND mapping.IsMobilePresent = 1 AND rest.IsMobilePresent = 1 
  AND (  @IsFamilyDeclaration=0 
			OR 
			(mapping.IsFamilyDeclaration=0
			OR
			(mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
			)
		 ) 
   WHERE mapping.Mobile = rest.Mobile  
  
 INSERT INTO #MobileMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  1 AS Holder  
 FROM #clientsChangeMapping mapping  
 INNER JOIN #selectedClients rest ON ISNULL(mapping.ChangedField, 1) = 1 AND mapping.IsMobilePresent = 1 AND rest.IsMobilePresent = 1   
  AND mapping.MobileFirstAscii = rest.MobileFirstAscii AND mapping.MobileLastAscii = rest.MobileLastAscii
  AND mapping.RefClientId <> rest.RefClientId 
  AND ( @IsFamilyDeclaration=0 
		   OR 
		   ( mapping.IsFamilyDeclaration=0
		   	 OR
		    (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		   )
	    )
	WHERE mapping.Mobile = rest.Mobile  

 INSERT INTO #MobileMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  2 AS Holder  
 FROM #clientsChangeMapping mapping   
 INNER JOIN #restClientsData rest ON ISNULL(mapping.ChangedField, 1) = 1   
  AND mapping.MobileFirstAscii = rest.SecondHolderMobileFirstAscii 
  AND mapping.MobileLastAscii = rest.SecondHolderMobileLastAscii
  AND mapping.IsMobilePresent = 1 AND rest.IsSecondHolderMobilePresent = 1   
   AND ( @IsFamilyDeclaration=0 
		   OR 
		   ( mapping.IsFamilyDeclaration=0
		   	 OR
		    (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		   )
	    )
   WHERE mapping.Mobile = rest.SecondHolderMobile 
	AND ((mapping.IsPANPresent = 0 AND rest.IsSecondHolderPANPresent = 0) OR (mapping.IsPANPresent <> rest.IsSecondHolderPANPresent)  
			OR (mapping.IsPANPresent = 1 AND rest.IsSecondHolderPANPresent = 1 AND mapping.PAN <> rest.SecondHolderPAN)) 
	

 INSERT INTO #MobileMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  2 AS Holder  
 FROM #clientsChangeMapping mapping  
 INNER JOIN #selectedClients rest ON ISNULL(mapping.ChangedField, 1) = 1  
  AND mapping.MobileFirstAscii = rest.SecondHolderMobileFirstAscii AND mapping.MobileLastAscii = rest.SecondHolderMobileLastAscii
  AND mapping.IsMobilePresent = 1 AND rest.IsSecondHolderMobilePresent = 1   
  AND mapping.RefClientId <> rest.RefClientId  
   AND ( @IsFamilyDeclaration=0 
		   OR 
		   ( mapping.IsFamilyDeclaration=0
		   	 OR
		    (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		   )
	    )
	WHERE mapping.Mobile = rest.SecondHolderMobile  
	AND ((mapping.IsPANPresent = 0 AND rest.IsSecondHolderPANPresent = 0) OR (mapping.IsPANPresent <> rest.IsSecondHolderPANPresent)  
		OR (mapping.IsPANPresent = 1 AND rest.IsSecondHolderPANPresent = 1 AND mapping.PAN <> rest.SecondHolderPAN))

 INSERT INTO #MobileMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  3 AS Holder  
 FROM #clientsChangeMapping mapping  
 INNER JOIN #restClientsData rest ON ISNULL(mapping.ChangedField, 1) = 1  
  AND mapping.MobileFirstAscii = rest.ThirdHolderMobileFirstAscii AND mapping.MobileLastAscii = rest.ThirdHolderMobileLastAscii
  AND mapping.IsMobilePresent = 1 AND rest.IsThirdHolderMobilePresent = 1    
   AND ( @IsFamilyDeclaration=0 
		   OR 
		   ( mapping.IsFamilyDeclaration=0
		   	 OR
		    (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		   )
	    ) 
	WHERE mapping.Mobile = rest.ThirdHolderMobile
  AND((mapping.IsPANPresent = 0 AND rest.IsThirdHolderPANPresent = 0) OR (mapping.IsPANPresent <> rest.IsThirdHolderPANPresent)  
   OR (mapping.IsPANPresent = 1 AND rest.IsThirdHolderPANPresent = 1 AND mapping.PAN <> rest.ThirdHolderPAN))

 INSERT INTO #MobileMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  3 AS Holder  
 FROM #clientsChangeMapping mapping  
 INNER JOIN #selectedClients rest ON ISNULL(mapping.ChangedField, 1) = 1   
  AND mapping.MobileFirstAscii = rest.ThirdHolderMobileFirstAscii AND mapping.MobileLastAscii = rest.ThirdHolderMobileLastAscii
  AND mapping.IsMobilePresent = 1 AND rest.IsThirdHolderMobilePresent = 1  
  AND mapping.RefClientId <> rest.RefClientId  
  AND ( @IsFamilyDeclaration=0 
		   OR 
		   ( mapping.IsFamilyDeclaration=0
		   	 OR
		    (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		   )
	    )
	WHERE mapping.Mobile = rest.ThirdHolderMobile 
  AND((mapping.IsPANPresent = 0 AND rest.IsThirdHolderPANPresent = 0) OR (mapping.IsPANPresent <> rest.IsThirdHolderPANPresent)  
   OR (mapping.IsPANPresent = 1 AND rest.IsThirdHolderPANPresent = 1 AND mapping.PAN <> rest.ThirdHolderPAN))  

 SELECT   
  t.RefClientId,
  t.MobileMatchCount
 INTO #MobileCounts  
 FROM  
 (  
 SELECT  
  matchData.RefClientId,  
  COUNT(1) AS MobileMatchCount  
 FROM #MobileMatchData matchData  
 GROUP BY matchData.RefClientId  
 )t  
 WHERE t.MobileMatchCount >= @MobileNoCount 
 
 
 SELECT t.Holder, client.ClientId, t.RefClientId, t.MatchingRefClientId
 INTO #descMobile
 FROM #MobileCounts fn
	  INNER JOIN #MobileMatchData t  ON t.RefClientId = fn.RefClientId 
      INNER JOIN #clients client ON client.RefClientId = t.MatchingRefClientId  
	  
 --TRUNCATE TABLE #MobileMatchData
  
 SELECT  
  Mobile.RefClientId,  
  Mobile.MobileMatchCount,  
  'Mobile - ' +   
   STUFF((  
     SELECT DISTINCT ',' + t.ClientId   
      + CASE WHEN t.Holder = 1 THEN '' ELSE '(' + CONVERT(VARCHAR,t.Holder) + ')' END  
     FROM #descMobile t 
     WHERE t.RefClientId = Mobile.RefClientId  
     FOR XML PATH (''))  
    , 1, 1, '') AS MobileDesc,  
  STUFF((  
   SELECT DISTINCT ',' + CONVERT(VARCHAR(MAX),t.MatchingRefClientId)   
   FROM #descMobile t  
   WHERE t.RefClientId = Mobile.RefClientId   
   FOR XML PATH (''))  
  , 1, 1, '') AS MatchingRefClientid  
 INTO #finalMobileData  
 FROM #MobileCounts Mobile  

 --TRUNCATE TABLE #MobileCounts
  
 /********************* Mobile match ends *********************/  
  
 /********************* Address match starts *********************/  
  
 CREATE TABLE #AddressMatchData (RefClientId INT, MatchingRefClientId INT)  

  --//new adrress match
   SELECT  t.RefClientId,t.[Address] ,t.OppositeClient,t.IsFamilyDeclaration
  INTO #tempAddressMatchData
  FROM (

	  SELECT mapping.CAddress AS [Address],mapping.RefClientId, null as OppositeClient,mapping.IsFamilyDeclaration
	  FROM #clientsChangeMapping mapping 
	  where mapping.IsCAddressPresent = 1 AND ISNULL(mapping.ChangedField, 4) = 4  

	  UNION ALL

	   SELECT  mapping.PAddress AS [Address],mapping.RefClientId,null as OppositeClient,mapping.IsFamilyDeclaration
	  FROM #clientsChangeMapping mapping 
	  where
	  mapping.IsPAddressPresent = 1 AND ISNULL(mapping.ChangedField, 3) = 3  

	  UNION ALL

	  select rest.PAddress as [Address],null as RefClientId,rest.RefClientId as OppositeClient,rest.IsFamilyDeclaration
	  from #restClientsData rest 
	  WHERE rest.IsPAddressPresent = 1

	  UNION ALL

	  select rest.CAddress as [Address],null as RefClientId,rest.RefClientId as OppositeClient,rest.IsFamilyDeclaration
	  from #restClientsData rest 
	  WHERE rest.IsCAddressPresent = 1
	) t

	--SELECT COUNT_BIG(1) FROM #restClientsData where IsPAddressPresent = 1  
	--SELECT COUNT_BIG(1) FROM #restClientsData where IsCAddressPresent = 1  
	--SELECT COUNT_BIG(1) FROM #clientsChangeMapping where IsPAddressPresent = 1  AND ISNULL(ChangedField, 3) = 3
	--SELECT COUNT_BIG(1) FROM #clientsChangeMapping where IsCAddressPresent = 1  AND ISNULL(ChangedField, 4) = 4
	--SELECT COUNT_BIG(1) FROM #tempAddressMatchData where refclientid is not null

	
	--SELECT * FROM #clientsChangeMapping where IsPAddressPresent = 1  AND ISNULL(ChangedField, 3) = 3 AND refclientid = 26617648
	--SELECT * FROM #clientsChangeMapping where IsCAddressPresent = 1  AND ISNULL(ChangedField, 4) = 4 AND refclientid = 26617648
	--SELECT * FROM #restClientsData where IsPAddressPresent = 1  									 AND refclientid = 26617648
	--SELECT * FROM #restClientsData where IsCAddressPresent = 1  									 AND refclientid = 26617648
	--SELECT * FROM #tempAddressMatchData	WHERE address = 'WARDNO3AMARCOLONI3STRGHARSANAGANGANAGAR'

	
	 CREATE TABLE #matchedAddress
	 ([Address] VARCHAR(1500) COLLATE DATABASE_DEFAULT ,
	 ACOUNT BIGINT)

    CREATE UNIQUE INDEX IX_Temp_ClientFieldsChangedCAdress
	ON #matchedAddress([Address])
	
	--SELECT * FROM #matchedAddress order by ACOUNT desc
	INSERT INTO #matchedAddress
	select t.[Address], COUNT(1)
	from #tempAddressMatchData t
	GROUP BY t.[Address]
	HAVING COUNT(1) > 1


	INSERT INTO #AddressMatchData (RefClientId, MatchingRefClientId) 
	SELECT DISTINCT client.RefClientId ,ISNULL(oppClient.OppositeClient, oppClient.RefClientId)
	FROM #matchedAddress matchs
	INNER JOIN #tempAddressMatchData client ON client.RefClientId is not null AND client.[Address] = matchs.[Address] 
	INNER JOIN #tempAddressMatchData oppClient ON client.RefClientId <> ISNULL(oppClient.RefClientId ,0)
	AND oppClient.[Address] = matchs.[Address] 
	WHERE  ( @IsFamilyDeclaration=0 
		   OR 
		   ( client.IsFamilyDeclaration=0
		   	 OR
		    (client.IsFamilyDeclaration<>oppClient.IsFamilyDeclaration)
		   )
	    )
		--SELECT * FROM #AddressMatchData where refclientid = 26617648
	--TRUNCATE TABLE #matchedAddress
  
 SELECT   
  t.*  
 INTO #AddressCounts  
 FROM  
 (  
 SELECT  
  matchData.RefClientId,  
  COUNT(1) AS AddressMatchCount  
 FROM #AddressMatchData matchData  
 GROUP BY matchData.RefClientId  
 )t  
 WHERE t.AddressMatchCount >= @AddressCount  
  
  SELECT client.ClientId, t.RefClientId, t.MatchingRefClientId
  INTO #descAddress
  FROM #AddressCounts fn
  INNER JOIN #AddressMatchData t  ON t.RefClientId = fn.RefClientId 
  INNER JOIN #clients client ON client.RefClientId = t.MatchingRefClientId 
  
 --TRUNCATE TABLE #AddressMatchData  
   
 SELECT DISTINCT  
  addr.RefClientId,  
  addr.AddressMatchCount,  
  'Address - ' +   
   STUFF((  
     SELECT DISTINCT TOP 50 ',' + t.ClientId   
     FROM #descAddress t
     WHERE t.RefClientId = addr.RefClientId  
     FOR XML PATH (''))  
    , 1, 1, '') AS AddrDesc,  
  STUFF((  
    SELECT DISTINCT TOP 50 ',' + CONVERT(VARCHAR(MAX),t.MatchingRefClientId)   
    FROM #descAddress t  
    WHERE t.RefClientId = addr.RefClientId   
    FOR XML PATH (''))  
   , 1, 1, '') AS MatchingRefClientid  
 INTO #finalAddressData  
 FROM #AddressCounts addr  
 
 --TRUNCATE TABLE #AddressCounts  
 /********************* Address match ends *********************/  
  
 /********************* Email match starts *********************/  
 CREATE TABLE #EmailMatchData (RefClientId INT, MatchingRefClientId INT, Holder INT)  
  
 INSERT INTO #EmailMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId AS SelectedRefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  1 AS Holder  
 FROM #clientsChangeMapping mapping   
 INNER JOIN #restClientsData rest ON ISNULL(mapping.ChangedField, 5) = 5  
  AND mapping.EmailFirstAscii = rest.EmailFirstAscii 
  AND mapping.IsEmailPresent = 1 AND rest.IsEmailPresent = 1 
  AND (  @IsFamilyDeclaration=0 
			OR 
		   ( mapping.IsFamilyDeclaration=0
		   	 OR
		    (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		   )
		 )
 WHERE mapping.Email = rest.Email
  
 INSERT INTO #EmailMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  1 AS Holder  
 FROM #clientsChangeMapping mapping   
 INNER JOIN #selectedClients rest ON ISNULL(mapping.ChangedField, 5) = 5  
  AND mapping.EmailFirstAscii = rest.EmailFirstAscii 
 AND mapping.IsEmailPresent = 1 AND rest.IsEmailPresent = 1   
  AND mapping.RefClientId <> rest.RefClientId
  AND ( @IsFamilyDeclaration=0 
		   OR 
		   ( mapping.IsFamilyDeclaration=0
		   	 OR
		    (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		   )
	    )
  WHERE mapping.Email = rest.Email  
  
 INSERT INTO #EmailMatchData (RefClientId, MatchingRefClientId, Holder)  

 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  2 AS Holder  
 FROM #clientsChangeMapping mapping   
 INNER JOIN #restClientsData rest ON ISNULL(mapping.ChangedField, 5) = 5  
  AND mapping.EmailFirstAscii = rest.SecondHolderEmailFirstAscii 
 AND mapping.IsEmailPresent = 1 AND rest.IsSecondHolderEmailPresent = 1  
   AND ( @IsFamilyDeclaration=0 
		   OR 
		   ( mapping.IsFamilyDeclaration=0
		   	 OR
		    (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		   )
	    )
	WHERE mapping.Email = rest.SecondHolderEmail  
	AND((mapping.IsPANPresent = 0 AND rest.IsSecondHolderPANPresent = 0) OR (mapping.IsPANPresent <> rest.IsSecondHolderPANPresent)  
	 OR (mapping.IsPANPresent = 1 AND rest.IsSecondHolderPANPresent = 1 AND mapping.PAN <> rest.SecondHolderPAN))  

 INSERT INTO #EmailMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  2 AS Holder  
 FROM #clientsChangeMapping mapping   
 INNER JOIN #selectedClients rest ON ISNULL(mapping.ChangedField, 5) = 5  
  AND mapping.EmailFirstAscii = rest.SecondHolderEmailFirstAscii 
 AND mapping.IsEmailPresent = 1 AND rest.IsSecondHolderEmailPresent = 1  
  AND mapping.RefClientId <> rest.RefClientId  
  AND ( @IsFamilyDeclaration=0 
		   OR 
		   ( mapping.IsFamilyDeclaration=0
		   	 OR
		    (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		   )
	    )
 WHERE mapping.Email = rest.SecondHolderEmail  
  AND((mapping.IsPANPresent = 0 AND rest.IsSecondHolderPANPresent = 0) OR (mapping.IsPANPresent <> rest.IsSecondHolderPANPresent)  
   OR (mapping.IsPANPresent = 1 AND rest.IsSecondHolderPANPresent = 1 AND mapping.PAN <> rest.SecondHolderPAN)) 


 INSERT INTO #EmailMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  3 AS Holder  
 FROM #clientsChangeMapping mapping   
 INNER JOIN #restClientsData rest ON ISNULL(mapping.ChangedField, 5) = 5  
  AND mapping.EmailFirstAscii = rest.ThirdHolderEmailFirstAscii 
 AND mapping.IsEmailPresent = 1 AND rest.IsThirdHolderEmailPresent = 1  
   AND ( @IsFamilyDeclaration=0 
		   OR 
		   ( mapping.IsFamilyDeclaration=0
		   	 OR
		    (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		   )
	    )
  WHERE mapping.Email = rest.ThirdHolderEmail  
  AND((mapping.IsPANPresent = 0 AND rest.IsThirdHolderPANPresent = 0) OR (mapping.IsPANPresent <> rest.IsThirdHolderPANPresent)  
   OR (mapping.IsPANPresent = 1 AND rest.IsThirdHolderPANPresent = 1 AND mapping.PAN <> rest.ThirdHolderPAN))  

 INSERT INTO #EmailMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  3 AS Holder  
 FROM #clientsChangeMapping mapping   
 INNER JOIN #selectedClients rest ON ISNULL(mapping.ChangedField, 5) = 5  
  AND mapping.EmailFirstAscii = rest.ThirdHolderEmailFirstAscii
 AND mapping.IsEmailPresent = 1 AND rest.IsThirdHolderEmailPresent = 1  
  AND mapping.RefClientId <> rest.RefClientId 
  AND (  @IsFamilyDeclaration=0 
		  OR 
		  ( mapping.IsFamilyDeclaration=0
		  	OR
		   (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		  )
	   )
  WHERE mapping.Email = rest.ThirdHolderEmail  
  AND((mapping.IsPANPresent = 0 AND rest.IsThirdHolderPANPresent = 0) OR (mapping.IsPANPresent <> rest.IsThirdHolderPANPresent)  
   OR (mapping.IsPANPresent = 1 AND rest.IsThirdHolderPANPresent = 1 AND mapping.PAN <> rest.ThirdHolderPAN))  

 SELECT   
  t.*  
 INTO #EmailCounts  
 FROM  
 (  
 SELECT  
  matchData.RefClientId,  
  COUNT(1) AS EmailMatchCount  
 FROM #EmailMatchData matchData  
 GROUP BY matchData.RefClientId  
 )t  
 WHERE t.EmailMatchCount >= @EmailCount  
 
  SELECT client.ClientId, t.RefClientId, t.MatchingRefClientId, t.Holder
  INTO #descEmail
  FROM #EmailCounts fn
  INNER JOIN #EmailMatchData t  ON t.RefClientId = fn.RefClientId 
  INNER JOIN #clients client ON client.RefClientId = t.MatchingRefClientId 
 
 --TRUNCATE TABLE #EmailMatchData  
  
 SELECT  
  Email.RefClientId,  
  Email.EmailMatchCount,  
  'Email - ' +   
   STUFF((  
     SELECT DISTINCT ',' + t.ClientId   
      + CASE WHEN t.Holder = 1 THEN '' ELSE '(' + CONVERT(VARCHAR,t.Holder) + ')' END  
     FROM #descEmail t 
     WHERE t.RefClientId = Email.RefClientId  
     FOR XML PATH (''))  
    , 1, 1, '') AS EmailDesc,  
  STUFF((  
   SELECT DISTINCT ',' + CONVERT(VARCHAR(MAX),t.MatchingRefClientId)   
   FROM #descEmail t  
   WHERE t.RefClientId = Email.RefClientId   
   FOR XML PATH (''))  
  , 1, 1, '') AS MatchingRefClientid  
 INTO #finalEmailData  
 FROM #EmailCounts Email  

 --TRUNCATE TABLE #EmailCounts 
 /********************* Email match ends *********************/  
  
 /********************* PAN match starts *********************/  
 CREATE TABLE #PanMatchData (RefClientId INT, MatchingRefClientId INT, Holder INT)  
  
 INSERT INTO #PanMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId AS SelectedRefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  1 AS Holder  
 FROM #clientsChangeMapping mapping  
 INNER JOIN #restClientsData rest ON ISNULL(mapping.ChangedField, 6) = 6  
  AND mapping.PANFirstAscii = rest.PANFirstAscii AND mapping.PANLastAscii = rest.PANLastAscii
 AND mapping.IsPANPresent = 1 AND rest.IsPANPresent = 1 
 AND (  @IsFamilyDeclaration=0 
		  OR 
		  ( mapping.IsFamilyDeclaration=0
		  	OR
		   (mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
		  )
	   )
 WHERE mapping.PAN = rest.PAN
  
 INSERT INTO #PanMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  1 AS Holder  
 FROM #clientsChangeMapping mapping  
 INNER JOIN #selectedClients rest ON ISNULL(mapping.ChangedField, 6) = 6  
  AND mapping.PANFirstAscii = rest.PANFirstAscii AND mapping.PANLastAscii = rest.PANLastAscii
  AND mapping.IsPANPresent = 1 AND rest.IsPANPresent = 1 AND mapping.RefClientId <> rest.RefClientId   
  AND (  @IsFamilyDeclaration=0 
			OR 
			(mapping.IsFamilyDeclaration=0
			OR
			(mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
			)
		 )
  WHERE mapping.PAN = rest.PAN 
  
 INSERT INTO #PanMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  2 AS Holder  
 FROM #clientsChangeMapping mapping  
 INNER JOIN #restClientsData rest ON ISNULL(mapping.ChangedField, 6) = 6  
  AND mapping.PANFirstAscii = rest.SecondHolderPANFirstAscii AND mapping.PANLastAscii = rest.SecondHolderPANLastAscii
 AND mapping.IsPANPresent = 1 AND rest.IsSecondHolderPANPresent = 1  
 AND (  @IsFamilyDeclaration=0 
			OR 
			(mapping.IsFamilyDeclaration=0
			OR
			(mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
			)
		 )
 WHERE mapping.PAN = rest.SecondHolderPAN 
   
 INSERT INTO #PanMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  2 AS Holder  
 FROM #clientsChangeMapping mapping  
 INNER JOIN #selectedClients rest ON ISNULL(mapping.ChangedField, 6) = 6  
  AND mapping.PANFirstAscii = rest.SecondHolderPANFirstAscii AND mapping.PANLastAscii = rest.SecondHolderPANLastAscii
  AND mapping.IsPANPresent = 1 AND rest.IsSecondHolderPANPresent = 1   
  AND mapping.RefClientId <> rest.RefClientId 
  AND (  @IsFamilyDeclaration=0 
			OR 
			(mapping.IsFamilyDeclaration=0
			OR
			(mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
			)
		 )
  WHERE mapping.PAN = rest.SecondHolderPAN 
   
 INSERT INTO #PanMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  3 AS Holder  
 FROM #clientsChangeMapping mapping  
 INNER JOIN #restClientsData rest ON ISNULL(mapping.ChangedField, 6) = 6  
  AND mapping.PANFirstAscii = rest.ThirdHolderPANFirstAscii AND mapping.PANLastAscii = rest.ThirdHolderPANLastAscii
 AND mapping.IsPANPresent = 1 AND rest.IsThirdHolderPANPresent = 1  
  AND (  @IsFamilyDeclaration=0 
			OR 
			(mapping.IsFamilyDeclaration=0
			OR
			(mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
			)
		 )
  WHERE mapping.PAN = rest.ThirdHolderPAN 
   
 INSERT INTO #PanMatchData (RefClientId, MatchingRefClientId, Holder)  
 SELECT  
  mapping.RefClientId,  
  rest.RefClientId AS MatchingRefClientId,  
  3 AS Holder  
 FROM #clientsChangeMapping mapping  
 INNER JOIN #selectedClients rest ON ISNULL(mapping.ChangedField, 6) = 6 
  AND mapping.PANFirstAscii = rest.ThirdHolderPANFirstAscii AND mapping.PANLastAscii = rest.ThirdHolderPANLastAscii 
  AND mapping.IsPANPresent = 1 AND rest.IsThirdHolderPANPresent = 1   
  AND mapping.RefClientId <> rest.RefClientId  
  AND (  @IsFamilyDeclaration=0 
			OR 
			(mapping.IsFamilyDeclaration=0
			OR
			(mapping.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
			)
		 )
  WHERE mapping.PAN = rest.ThirdHolderPAN
   
 --TRUNCATE TABLE #selectedClients  
  
 SELECT   
  t.*  
 INTO #PanCounts  
 FROM  
 (  
 SELECT  
  matchData.RefClientId,  
  COUNT(1) AS PanMatchCount  
 FROM #PanMatchData matchData  
 GROUP BY matchData.RefClientId  
 )t  
 WHERE t.PanMatchCount >= @PanCount  

  SELECT client.ClientId, t.RefClientId, t.MatchingRefClientId, t.Holder
  INTO #descPAN
  FROM #PanCounts fn
  INNER JOIN #PanMatchData t  ON t.RefClientId = fn.RefClientId 
  INNER JOIN #clients client ON client.RefClientId = t.MatchingRefClientId 
  
 --TRUNCATE TABLE #PanMatchData  
  
 SELECT  
  pan.RefClientId,  
  pan.PanMatchCount,  
  'PAN - ' +   
   STUFF((  
     SELECT DISTINCT ',' + t.ClientId   
      + CASE WHEN t.Holder = 1 THEN '' ELSE '(' + CONVERT(VARCHAR,t.Holder) + ')' END  
     FROM #descPAN t 
     WHERE t.RefClientId = pan.RefClientId  
     FOR XML PATH (''))  
    , 1, 1, '') AS PanDesc,  
  STUFF((  
   SELECT DISTINCT ',' + CONVERT(VARCHAR(MAX),t.MatchingRefClientId)   
   FROM #descPAN t  
   WHERE t.RefClientId = pan.RefClientId   
   FOR XML PATH (''))  
  , 1, 1, '') AS MatchingRefClientid  
 INTO #finalPanData  
 FROM #PanCounts pan  
 
 --TRUNCATE TABLE #PanCounts 
 /********************* PAN match ends *********************/  
  
 /********************* Fetching bank account data *********************/  
 SELECT  
  changed.RefClientId,  
  bank.BankAccNo ,
  ISNULL(cl.IsFamilyDeclaration,0) As IsFamilyDeclaration,
  ASCII(LEFT(bank.BankAccNo, 1)) AS BankAccNoFirstAscii,
  ASCII(RIGHT(bank.BankAccNo, 1)) AS BankAccNoLastAscii
 INTO #selectedBankAccounts  
 FROM #clients cl
 INNER JOIN  #ClientFieldsChanged changed ON cl.RefClientId=changed.RefClientId
 INNER JOIN dbo.LinkRefClientRefBankMicr bank ON ISNULL(changed.ChangedField,2) = 2   
 AND changed.RefClientId = bank.RefClientId 
 WHERE bank.BankAccNo<> ''  
  
 INSERT INTO #selectedBankAccounts  
 SELECT  
  changed.RefClientId,  
  bank.BankAccountNo AS BankAccNo,
  ISNULL(cl.IsFamilyDeclaration,0) As IsFamilyDeclaration,  
  ASCII(LEFT(bank.BankAccountNo, 1)) AS BankAccNoFirstAscii,
  ASCII(RIGHT(bank.BankAccountNo, 1)) AS BankAccNoLastAscii
 FROM #clients cl 
 INNER JOIN #ClientFieldsChanged changed  ON cl.RefClientId=changed.RefClientId
 INNER JOIN dbo.CoreCRMBankAccount bank ON ISNULL(changed.ChangedField,2) = 2   
 AND changed.RefClientId = bank.EntityId AND bank.RefEntityTypeId = @ClientEntityTypeId   
 WHERE bank.BankAccountNo <> ''  
  
   
 SELECT  
  rest.RefClientId,  
  bank.BankAccNo  ,
  ISNULL(rest.IsFamilyDeclaration,0) As IsFamilyDeclaration,
  ASCII(LEFT(bank.BankAccNo, 1)) AS BankAccNoFirstAscii,
  ASCII(RIGHT(bank.BankAccNo, 1)) AS BankAccNoLastAscii
 INTO #restBankAccounts  
 FROM #restClientsData rest  
 INNER JOIN dbo.LinkRefClientRefBankMicr bank ON rest.RefClientId = bank.RefClientId 
 WHERE bank.BankAccNo<> ''  
  
 INSERT INTO #restBankAccounts  
 SELECT  
  rest.RefClientId,  
  bank.BankAccountNo AS BankAccNo ,
  ISNULL(rest.IsFamilyDeclaration,0) As IsFamilyDeclaration,  
  ASCII(LEFT(bank.BankAccountNo, 1)) AS BankAccNoFirstAscii,
  ASCII(RIGHT(bank.BankAccountNo, 1)) AS BankAccNoLastAscii
 FROM #restClientsData rest  
 INNER JOIN dbo.CoreCRMBankAccount bank ON rest.RefClientId = bank.EntityId AND bank.RefEntityTypeId = @ClientEntityTypeId  
 WHERE bank.BankAccountNo <> ''   
  
 --TRUNCATE TABLE #ClientFieldsChanged  
 --TRUNCATE TABLE #restClientsData  
  
 /********************* Bank Acc/No match starts *********************/  
  
 SELECT  
  sel.RefClientId,  
  rest.RefClientId AS MatchingRefClientId  
 INTO #BankMatchData  
 FROM #selectedBankAccounts sel  
 INNER JOIN #restBankAccounts rest ON (  @IsFamilyDeclaration=0 
			OR 
			(sel.IsFamilyDeclaration=0
			OR
			(sel.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
			)
		 )
  AND sel.BankAccNoFirstAscii = rest.BankAccNoFirstAscii AND sel.BankAccNoLastAscii = rest.BankAccNoLastAscii 
 WHERE sel.BankAccNo = rest.BankAccNo 
   
 INSERT INTO #BankMatchData  
 SELECT  
  sel.RefClientId,  
  rest.RefClientId AS MatchingRefClientId  
 FROM #selectedBankAccounts sel  
 INNER JOIN #selectedBankAccounts rest ON rest.RefClientId <> sel.RefClientId  
  AND sel.BankAccNoFirstAscii = rest.BankAccNoFirstAscii AND sel.BankAccNoLastAscii = rest.BankAccNoLastAscii
  AND (  @IsFamilyDeclaration=0 
			OR 
			(sel.IsFamilyDeclaration=0
			OR
			(sel.IsFamilyDeclaration<>rest.IsFamilyDeclaration)
			)
		 )
  WHERE rest.BankAccNo = sel.BankAccNo
   
 --TRUNCATE TABLE #restBankAccounts  
 --TRUNCATE TABLE #selectedBankAccounts  
  
 SELECT   
  t.*  
 INTO #BankCounts  
 FROM  
 (  
 SELECT  
  matchData.RefClientId,  
  COUNT(1) AS BankMatchCount  
 FROM #BankMatchData matchData  
 GROUP BY matchData.RefClientId  
 )t  
 WHERE t.BankMatchCount >= @BankACNoCount  

  SELECT client.ClientId, t.RefClientId, t.MatchingRefClientId
  INTO #descBank
  FROM #BankCounts fn
  INNER JOIN #BankMatchData t  ON t.RefClientId = fn.RefClientId 
  INNER JOIN #clients client ON client.RefClientId = t.MatchingRefClientId 

  --TRUNCATE TABLE #clients
  --TRUNCATE TABLE #BankMatchData 
  
 SELECT DISTINCT  
  bank.RefClientId,  
  bank.BankMatchCount,  
  'Bank - ' +   
   STUFF((  
     SELECT DISTINCT ',' + t.ClientId   
     FROM #descBank t
     WHERE t.RefClientId = bank.RefClientId  
     FOR XML PATH (''))  
    , 1, 1, '') AS bankDesc,  
  STUFF((  
    SELECT DISTINCT ',' + CONVERT(VARCHAR(MAX),t.MatchingRefClientId)   
    FROM #descBank t  
    WHERE t.RefClientId = bank.RefClientId   
    FOR XML PATH (''))  
   , 1, 1, '') AS MatchingRefClientid  
 INTO #finalBankData  
 FROM #BankCounts bank  
   
 --TRUNCATE TABLE #BankCounts  
 /********************* Bank Acc/No match ends *********************/  
  
 CREATE TABLE #clientIds(RefClientId INT NOT NULL,MatchingRefClientId INT NOT NULL)  
  
 INSERT INTO #clientIds(RefClientId,MatchingRefClientId)  
 SELECT DISTINCT  
  RefClientId, MatchingRefClientId   
 FROM (  
  SELECT RefClientId,MatchingRefClientId  
  FROM #descPAN
  
  UNION  
  
  SELECT RefClientId,MatchingRefClientId  
  FROM #descMobile
    
  UNION  
  
  SELECT RefClientId,MatchingRefClientId  
  FROM #descEmail
  UNION  
    
  SELECT RefClientId,MatchingRefClientId  
  FROM #descBank
  
  UNION  
  
  SELECT RefClientId,MatchingRefClientId  
  FROM #descAddress
 ) t  

   --TRUNCATE TABLE #descAddress
   --TRUNCATE TABLE #descBank
   --TRUNCATE TABLE #descEmail
   --TRUNCATE TABLE #descMobile
   --TRUNCATE TABLE #descPAN
  
 SELECT DISTINCT RefClientId  
 INTO #distinctAlertClients  
 FROM #clientIds  
 
 SELECT  
   t.RefClientId,  
   t.AccountSegment 
 INTO #clientCSMapping 
 FROM  
 (  
	SELECT  
	cl.RefClientId,  
	seg.[Name] AS AccountSegment,  
	ROW_NUMBER() OVER(PARTITION BY cl.RefClientId ORDER BY linkClCs.StartDate DESC) AS RN  
	FROM #distinctAlertClients cl  
	LEFT JOIN dbo.LinkRefClientRefCustomerSegment linkClCs ON cl.RefClientId = linkClCs.RefClientId  
	LEFT JOIN dbo.RefCustomerSegment seg ON linkClCs.RefCustomerSegmentId=seg.RefCustomerSegmentId
 ) t  
 WHERE t.RN = 1   


 SELECT   
  cl.RefClientId,  
  STUFF((  
   SELECT DISTINCT ',' + CONVERT(VARCHAR(MAX), t.MatchingRefClientId)  
   FROM #clientIds t  
   WHERE t.RefClientId = cl.RefClientId  
   FOR XML PATH(''))  
  , 1, 1, '') AS MatchingRefClientIds  
 INTO #MatchingRefClients_CTE
 FROM #distinctAlertClients cl 
  
 SELECT  
  mrc.RefClientId,  
  cl.ClientId,  
  cl.[Name] AS ClientName,  
  cl.AccountOpeningDate,  
    
  ISNULL(pan.PanMatchCount, 0) AS CommonPan,  
  ISNULL(mob.MobileMatchCount, 0 ) AS CommonMobileNo,  
  ISNULL(email.EmailMatchCount, 0) AS CommonEmailId,  
  ISNULL(bank.BankMatchCount, 0) AS CommonBankACNo,  
  ISNULL(addr.AddressMatchCount, 0) AS CommonAddress,  
    
  REPLACE(ISNULL(pan.PanDesc + ' ; ', '') + ISNULL(mob.MobileDesc + ' ; ', '') +  
   ISNULL(email.EmailDesc + ' ; ', '') + ISNULL(bank.BankDesc + ' ; ', '') +  
   ISNULL(addr.AddrDesc + ' ; ', '') + ';;', ' ; ;;', '') AS [Description],  
  mrc.MatchingRefClientIds ,  
  CASE   
   WHEN cl.RefClientDatabaseEnumId = @CdslDbId THEN @CdslSegmentId  
   WHEN cl.RefClientDatabaseEnumId = @NsdlDbId THEN @NsdlSegmentId  
   ELSE NULL  
  END AS RefSegmentId,
  clcs.AccountSegment,
  de.DatabaseType AS Depository 
 FROM #MatchingRefClients_CTE mrc  
 INNER JOIN dbo.RefClient cl ON mrc.RefClientId = cl.RefClientId
 INNER JOIN dbo.RefClientDatabaseEnum de on de.RefClientDatabaseEnumId = cl.RefClientDatabaseEnumId
 LEFT JOIN #finalPanData pan ON mrc.RefClientId = pan.RefClientId  
 LEFT JOIN #finalMobileData mob ON mrc.RefClientId = mob.RefClientId  
 LEFT JOIN #finalEmailData email ON mrc.RefClientId = email.RefClientId  
 LEFT JOIN #finalBankData bank ON mrc.RefClientId = bank.RefClientId  
 LEFT JOIN #finalAddressData addr ON mrc.RefClientId = addr.RefClientId  
 LEFT JOIN #clientCSMapping clcs ON mrc.RefClientId = clcs.RefClientId
 