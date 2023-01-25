--File:StoredProcedures:dbo:AML_GetFrequentChangeinClientKYCforKYCDetails
---RC END WEB- 86153
GO
	CREATE PROCEDURE dbo.AML_GetFrequentChangeinClientKYCforKYCDetails
	(
		@AlertId BIGINT
	)
	AS
	BEGIN
		DECLARE @AlertIdInternal BIGINT, @RefClientId BIGINT, @RunDate DATETIME, @ToDate DATETIME, @AuditIdEmailChange INT, @AuditIdBankAccNoChangeState DATETIME,
			@AuditIdMobileChangeState INT, @AuditIdPanChangeState INT, @AuditIdPAddressChangeState INT, @AuditIdCAddressChangeState INT, @RefEntityTypeId INT,@AlertAddedOn DATETIME

		SET @AlertIdInternal = @AlertId
		SELECT @RefClientId = alert.RefClientId, @RunDate = alert.ReportDate, @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, alert.ReportDate)) + CONVERT(DATETIME, '23:59:59.000') ,@AlertAddedOn = alert.AddedOn
											FROM dbo.CoreAmlScenarioAlert alert WHERE alert.CoreAmlScenarioAlertId = @AlertIdInternal
		
		SET @RefEntityTypeId = dbo.GetEntityTypeByCode('Client')  

		SELECT
			DENSE_RANK() OVER(ORDER BY aud.AuditDateTime DESC) AuditId,
			aud.Email,
			aud.Mobile,
			aud.PAN,
			ISNULL(aud.PAddressLine1 + ', ', '') + ISNULL(aud.PAddressLine2 + ', ', '') +     
			ISNULL(aud.PAddressLine3 + ', ', '') + ISNULL(aud.PAddressCity + ', ', '') + 
			ISNULL(aud.PAddressState + ', ', '') + ISNULL(aud.PAddressCountry + ', ', '') + 
			ISNULL(aud.PAddressPin + '.', '')  AS PAddress,
			ISNULL(aud.CAddressLine1 + ', ', '') + ISNULL(aud.CAddressLine2 + ', ', '') +     
			ISNULL(aud.CAddressLine3 + ', ', '') + ISNULL(aud.CAddressCity + ', ', '') + 
			ISNULL(aud.CAddressState + ', ', '') + ISNULL(aud.CAddressCountry + ', ', '') + 
			ISNULL(aud.CAddressPin + '.', '') AS CAddress,
			CASE WHEN aud.AuditDataState = 'Old' THEN 1 ELSE 0 END AS AuditState
		INTO #tempCilentChanges
		FROM dbo.RefClient_Audit aud WHERE aud.RefClientId = @RefClientId AND aud.AuditDmlAction = 'Update'
			AND aud.AuditDateTime BETWEEN @RunDate AND @ToDate AND aud.AuditDateTime < @AlertAddedOn
		
		SELECT
			t.AuditId, t.EmailChangeState, t.MobileChangeState, t.PANChangeState, t.PAddressChangeState, t.CAddressChangeState
		INTO #tempChangesBit
		FROM
		(SELECT
			DISTINCT
			aud1.AuditId,
			CASE WHEN ISNULL(aud1.Email, '') <> ISNULL(aud2.Email, '') THEN 1 ELSE 0 END AS EmailChangeState,
			CASE WHEN ISNULL(aud1.Mobile, '') <> ISNULL(aud2.Mobile, '') THEN 1 ELSE 0 END AS MobileChangeState,
			CASE WHEN ISNULL(aud1.PAN, '') <> ISNULL(aud2.PAN, '') THEN 1 ELSE 0 END AS PANChangeState,
			CASE WHEN dbo.RemoveMatchingCharacters(aud1.PAddress, '^0-9a-z') <> dbo.RemoveMatchingCharacters(aud2.PAddress, '^0-9a-z') THEN 1 ELSE 0 END AS PAddressChangeState,
			CASE WHEN dbo.RemoveMatchingCharacters(aud1.CAddress, '^0-9a-z') <> dbo.RemoveMatchingCharacters(aud2.CAddress, '^0-9a-z') THEN 1 ELSE 0 END AS CAddressChangeState
		
		FROM #tempCilentChanges aud1
		INNER JOIN #tempCilentChanges aud2 ON aud1.AuditId = aud2.AuditId AND aud1.AuditState + aud2.AuditState = 1)t
		WHERE t.EmailChangeState + t.MobileChangeState + t.PANChangeState + t.PAddressChangeState + CAddressChangeState >= 1

		SET @AuditIdEmailChange = (SELECT MIN(tem.AuditId) FROM #tempChangesBit tem WHERE tem.EmailChangeState = 1 )
		SET @AuditIdMobileChangeState = (SELECT MIN(tem.AuditId) FROM #tempChangesBit tem WHERE tem.MobileChangeState = 1)
		SET @AuditIdPANChangeState = (SELECT MIN(tem.AuditId) FROM #tempChangesBit tem WHERE tem.PANChangeState = 1)
		SET @AuditIdPAddressChangeState = (SELECT MIN(tem.AuditId) FROM #tempChangesBit tem WHERE tem.PAddressChangeState = 1)
		SET @AuditIdCAddressChangeState = (SELECT MIN(tem.AuditId)  FROM #tempChangesBit tem WHERE tem.CAddressChangeState = 1)

		CREATE TABLE #finalResult
		(
			OldNewBit BIT,
			[Values] VARCHAR(100),
			CAddress VARCHAR(MAX)COLLATE DATABASE_DEFAULT,
			PAddress VARCHAR(MAX)COLLATE DATABASE_DEFAULT,
			Email VARCHAR(100) COLLATE DATABASE_DEFAULT,
			Mobile VARCHAR(100)COLLATE DATABASE_DEFAULT,
			PAN VARCHAR(100)COLLATE DATABASE_DEFAULT,
			BankNo VARCHAR(100)COLLATE DATABASE_DEFAULT
		)

		INSERT INTO #finalResult (OldNewBit, [Values]) VALUES (1, 'Old'), (0,'New')

		UPDATE fr
		SET fr.CAddress = tem.CAddress
		FROM #finalResult fr
		INNER JOIN #tempCilentChanges tem ON tem.AuditState = fr.OldNewBit AND tem.AuditId = @AuditIdCAddressChangeState

		UPDATE fr
		SET fr.PAddress = tem.PAddress
		FROM #finalResult fr
		INNER JOIN #tempCilentChanges tem ON tem.AuditState = fr.OldNewBit AND tem.AuditId = @AuditIdPAddressChangeState

		UPDATE fr
		SET fr.PAN = tem.PAN
		FROM #finalResult fr
		INNER JOIN #tempCilentChanges tem ON tem.AuditState = fr.OldNewBit AND tem.AuditId = @AuditIdPANChangeState

		UPDATE fr
		SET fr.Mobile = tem.Mobile
		FROM #finalResult fr
		INNER JOIN #tempCilentChanges tem ON tem.AuditState = fr.OldNewBit AND tem.AuditId = @AuditIdMobileChangeState

		UPDATE fr
		SET fr.Email = tem.Email 
		FROM #finalResult fr
		INNER JOIN #tempCilentChanges tem ON tem.AuditState = fr.OldNewBit AND tem.AuditId = @AuditIdEmailChange


		CREATE TABLE #tempBankChanges(
			AuditId DATETIME,
			BankAccNo VARCHAR (100) COLLATE DATABASE_DEFAULT,
			AuditState INT
		)

		

		INSERT INTO #tempBankChanges 
				SELECT
					bank.AuditDateTime,
					bank.BankAccNo,
					CASE WHEN bank.AuditDataState = 'Old' THEN 1 ELSE 0 END AS AuditState
				FROM dbo.LinkRefClientRefBankMicr_Audit bank 
				WHERE bank.BankAccNo <> '' AND bank.RefClientId = @RefClientId AND bank.AuditDmlAction = 'Update' AND bank.AuditDateTime BETWEEN @RunDate AND @ToDate AND bank.AuditDateTime < @AlertAddedOn

		INSERT INTO #tempBankChanges 

				  SELECT
					bank.AuditDateTime,
					bank.BankAccountNo AS BankAccNo,
					CASE WHEN bank.AuditDataState = 'Old' THEN 1 ELSE 0 END AS AuditState
				  FROM dbo.CoreCRMBankAccount_Audit bank
				  WHERE bank.BankAccountNo <> '' AND bank.EntityId = @RefClientId AND bank.RefEntityTypeId = @RefEntityTypeId  AND bank.AuditDmlAction = 'Update' AND bank.AuditDateTime BETWEEN @RunDate AND @ToDate AND bank.AuditDateTime < @AlertAddedOn
			
		SET @AuditIdBankAccNoChangeState = (SELECT MIN(aud1.AuditId) FROM #tempBankChanges aud1 INNER JOIN #tempBankChanges aud2 ON aud2.AuditId = aud1.AuditId AND aud1.AuditState + aud2.AuditState = 1 AND aud1.BankAccNo <> aud2.BankAccNo )
			
		UPDATE fr
		SET fr.BankNo = bank.BankAccNo	
		FROM #finalResult fr
		INNER JOIN #tempBankChanges bank ON fr.OldNewBit = bank.AuditState AND bank.AuditId =  @AuditIdBankAccNoChangeState

		SELECT
			fr.[Values],
			ISNULL(fr.CAddress,'-') AS CAddress,
			ISNULL(fr.PAddress,'-') AS PAddress ,
			ISNULL(fr.Email,'-') AS Email,
			ISNULL(fr.Mobile,'-') AS Mobile,
			ISNULL(fr.PAN, '-') AS PAN,
			ISNULL(fr.BankNo, '-') AS BankNo
		FROM #finalResult fr

		SELECT
			COUNT(fr.OldNewBit)
		FROM #finalResult fr

	END

GO
---RC END WEB- 86153