--WEB-76062 START RC
GO
ALTER PROCEDURE [dbo].RefClient_GetMatchingClientDetails (
	@AlertId BIGINT
	)
AS
  BEGIN

  DECLARE @RefClientIds VARCHAR(MAX), @InternalAlertId BIGINT, @AlertRefClientId INT, @AlertAddedOn DATETIME, @ClientEntityTypeId INT

  SET @InternalAlertId = @AlertId
  SELECT @RefClientIds = CONVERT(VARCHAR,alert.RefClientId) + ','+ ISNULL(alert.ISINName,'')FROM dbo.CoreAmlScenarioAlert alert WHERE alert.CoreAmlScenarioAlertId = @InternalAlertId
  SELECT @ClientEntityTypeId = dbo.GetEntityTypeByCode('Client')

  SELECT
	CONVERT( INT,s.s) AS RefClientId
  INTO #tempRefClientId	
  FROM  dbo.Parsestring(@RefClientIds, ',') s

  SELECT @AlertRefClientId = alert.RefClientId ,@AlertAddedOn = alert.AddedOn FROM dbo.CoreAmlScenarioAlert alert WHERE CoreAmlScenarioAlertId = @InternalAlertId

  SELECT
	t.*
  INTO  #tempAuditRefClient
  FROM
  (
	  SELECT
		ref.RefClientId,
		aud.[Name],
		aud.ClientId,
		aud.Email,
		aud.Mobile,
		aud.PAN,
		LTRIM(RTRIM(ISNULL(aud.PAddressLine1, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(aud.PAddressLine2, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(aud.PAddressLine3, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(aud.PAddressPin, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(aud.PAddressCity, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(aud.PAddressState, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(aud.PAddressCountry, ''))) AS PAddress,
		LTRIM(RTRIM(ISNULL(aud.CAddressLine1 + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(aud.CAddressLine2 + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(aud.CAddressLine3 + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(aud.CAddressPin + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(aud.CAddressCity + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(aud.CAddressState + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(aud.CAddressCountry , ''))) AS CAddress,
		ROW_NUMBER() OVER(PARTITION BY aud.RefClientId ORDER BY aud.AuditDateTime ASC) RN
	  FROM #tempRefClientId ref
	  INNER JOIN dbo.RefClient_Audit aud ON aud.RefClientId = ref.RefClientId AND aud.AuditDateTime > @AlertAddedOn AND aud.AuditDMLAction ='Update' AND aud.AuditDataState = 'Old')
  t
  WHERE t.RN = 1

  INSERT INTO #tempAuditRefClient
  SELECT 
		ref.RefClientId,
		ref.[Name],
		ref.ClientId,
		ref.Email,
		ref.Mobile,
		ref.PAN,
		LTRIM(RTRIM(ISNULL(ref.PAddressLine1, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(ref.PAddressLine2, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(ref.PAddressLine3, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(ref.PAddressPin, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(ref.PAddressCity, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(ref.PAddressState, '')) + ' ')
        + LTRIM(RTRIM(ISNULL(ref.PAddressCountry, ''))) AS PAddress,
		LTRIM(RTRIM(ISNULL(ref.CAddressLine1 + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(ref.CAddressLine2 + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(ref.CAddressLine3 + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(ref.CAddressPin + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(ref.CAddressCity + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(ref.CAddressState + ',', '')) + ' ')  
        + LTRIM(RTRIM(ISNULL(ref.CAddressCountry , ''))) AS CAddress,
		1 AS RN
  FROM  #tempRefClientId ids
  INNER JOIN dbo.RefClient ref ON ref.RefClientId = ids.RefClientId
  LEFT JOIN #tempAuditRefClient temp ON  temp.RefClientId = ids.RefClientId 
  WHERE temp.RefClientId IS  NULL

  ---bank details

  CREATE TABLE #AccDetails(
		RefClientId INT,
		TablePrimaryId BIGINT,
		BankAccountNo VARCHAR(500) COLLATE DATABASE_DEFAULT,
		BankAccountNoAudit VARCHAR(500) COLLATE DATABASE_DEFAULT,
		TableBit BIT, -- 0 for link and 1 for crm
	)  
  
  INSERT INTO #AccDetails (RefClientId,TablePrimaryId,BankAccountNo,TableBit)
  SELECT t.*
  FROM(
	  SELECT    
		 ref.RefClientId,
		 micr.LinkRefClientRefBankMicrId AS TablePrimaryId,
		 micr.BankAccNo AS BankAccountNo,
		 0 AS TableBit
	  FROM #tempRefClientId ref  
	  INNER JOIN dbo.LinkRefClientRefBankMicr micr ON ref.RefClientId = micr.RefClientId AND micr.BankAccNo <> '' AND   micr.AddedOn < @AlertAddedOn
		
      UNION

	  SELECT    
		 ref.RefClientId, 
		 acc.CoreCRMBankAccountId AS TablePrimaryId,
		 acc.BankAccountNo AS BankAccountNo, 
		 1 AS TableBit
	  FROM #tempRefClientId ref  
	  INNER JOIN dbo.CoreCRMBankAccount acc ON ref.RefClientId = acc.EntityId   AND  acc.RefEntityTypeId = @ClientEntityTypeId
					AND acc.BankAccountNo <> '' AND acc.AddedOn < @AlertAddedOn )t

  SELECT
	t.*
  INTO #tempAuditLatest
  FROM ( 
		SELECT aud.LinkRefClientRefBankMicrId,
			aud.BankAccNo,
			ROW_NUMBER() OVER(PARTITION BY aud.LinkRefClientRefBankMicrId ORDER BY aud.AuditDateTime ASC) RN
		FROM #AccDetails acc
		INNER JOIN LinkRefClientRefBankMicr_Audit aud ON acc.TableBit = 0 AND aud.LinkRefClientRefBankMicrId = acc.TablePrimaryId AND 
		aud.AuditDateTime > @AlertAddedOn AND aud.AuditDMLAction ='Update' AND aud.AuditDataState = 'Old'  
		)t WHERE t.RN = 1

   UPDATE micr
   SET micr.BankAccountNoAudit = latest.BankAccNo
   FROM #AccDetails micr
   INNER JOIN #tempAuditLatest AS latest ON latest.RN = 1 AND latest.LinkRefClientRefBankMicrId = micr.TablePrimaryId
   
   DROP TABLE #tempAuditLatest

   SELECT
	t.*
   INTO #tempAuditLatestCRM
   FROM ( 
		SELECT aud.CoreCRMBankAccountId,
			aud.BankAccountNo,
			ROW_NUMBER() OVER(PARTITION BY aud.CoreCRMBankAccountId ORDER BY aud.AuditDateTime ASC) RN
		FROM #AccDetails acc
		INNER JOIN dbo.CoreCRMBankAccount_Audit aud ON acc.TableBit = 1 AND aud.CoreCRMBankAccountId = acc.TablePrimaryId AND 
		aud.AuditDateTime > @AlertAddedOn AND aud.AuditDMLAction ='Update' AND aud.AuditDataState = 'Old'  
		)t WHERE t.RN = 1

   UPDATE micr
	SET micr.BankAccountNoAudit = latest.BankAccountNo
   FROM #AccDetails micr
   INNER JOIN #tempAuditLatestCRM AS latest ON latest.RN = 1 AND latest.CoreCRMBankAccountId = micr.TablePrimaryId

  SELECT   
	acc.RefClientId,  
	 STUFF((   
	   SELECT DISTINCT ' , ' + (CASE WHEN temp.BankAccountNoAudit IS NOT NULL THEN temp.BankAccountNoAudit ELSE temp.BankAccountNo END)  
		FROM #AccDetails temp   
		WHERE acc.RefClientId = temp.RefClientId  
	  FOR XML PATH ('')), 1, 3, '') AS BankAccountNo  
  INTO #BankDetails  
  FROM #AccDetails acc
  GROUP BY acc.RefClientId
  

  SELECT cl.RefClientId,
        cl.[NAME],
        cl.ClientId,
        cl.Email,
        cl.Mobile,
        cl.PAN,
        cl.PAddress,
		cl.CAddress, 
		bank.BankAccountNo,
		CASE WHEN cl.RefClientId = @AlertRefClientId THEN 1 ELSE 0 END AS IsAlertRefClientId
   FROM   #tempAuditRefClient cl
   LEFT JOIN #BankDetails bank ON cl.RefClientId = bank.RefClientId
  END
GO
--WEB-76062 END RC