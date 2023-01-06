 -- WEB - 74650 - RC START
 GO
 ALTER PROCEDURE [dbo].RefClient_GetMatchingClientDetails (@AlertId INT)  

AS  
  BEGIN  
  
  DECLARE @RefClientIds VARCHAR(MAX) , @InternalAlertId INT , @AlertRefClientId INT  
  
  SET @InternalAlertId = @AlertId  
  
  SELECT   
 @RefClientIds = CONVERT(VARCHAR,alert.RefClientId) + ','+ alert.ISINName  
  FROM dbo.CoreAmlScenarioAlert alert WHERE CoreAmlScenarioAlertId = @InternalAlertId  
  
  SELECT @AlertRefClientId = alert.RefClientId FROM dbo.CoreAmlScenarioAlert alert WHERE CoreAmlScenarioAlertId = @InternalAlertId  
  
  CREATE TABLE #AccDetails(RefClientId INT,BankAccountNo VARCHAR(500) COLLATE DATABASE_DEFAULT)  
  
  INSERT INTO #AccDetails  
  SELECT DISTINCT   
 S.s,  
 micr.BankAccNo  
  FROM dbo.Parsestring(@RefClientIds, ',') S  
  INNER JOIN dbo.LinkRefClientRefBankMicr micr ON S.s = micr.RefClientId  
  
  INSERT INTO #AccDetails  
  SELECT DISTINCT   
 S.s,  
 acc.BankAccountNo   
  FROM dbo.Parsestring(@RefClientIds, ',') S  
  INNER JOIN dbo.CoreCRMBankAccount acc ON S.s = acc.EntityId  
  
  SELECT   
 S.s AS RefClientId,  
 STUFF((   
   SELECT DISTINCT ' , ' + temp.BankAccountNo  
    FROM dbo.Parsestring(@RefClientIds, ',') S   
   INNER JOIN #AccDetails temp ON S.s = temp.RefClientId  
   FOR XML PATH ('')), 1, 3, '') AS BankAccountNo  
  INTO #BankDetails  
  FROM dbo.Parsestring(@RefClientIds, ',') S   
  
      SELECT cl.RefClientId,  
             cl.[NAME],  
             cl.ClientId,  
             cl.Email,  
             cl.Mobile,  
             cl.PAN,  
             LTRIM(RTRIM(ISNULL(cl.PAddressLine1, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.PAddressLine2, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.PAddressLine3, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.PAddressPin, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.PAddressCity, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.PAddressState, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.PAddressCountry, ''))) AS PAddress,  
			 LTRIM(RTRIM(ISNULL(cl.CAddressLine1, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressLine2, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressLine3, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressPin, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressCity, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressState, '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressCountry, ''))) AS CAddress, 
    bank.BankAccountNo,  
    CASE WHEN cl.RefClientId = @AlertRefClientId THEN 1 ELSE 0 END AS IsAlertRefClientId  
      FROM   dbo.refclient cl  
             INNER JOIN dbo.Parsestring(@RefClientIds, ',') S  
                     ON cl.RefClientId = S.s  
    LEFT JOIN #BankDetails bank ON S.s = bank.RefClientId  
  END  

 GO
 --WEB-74650 RC END
GO
ALTER PROCEDURE [dbo].RefClient_GetMatchingClientDetails (@AlertId INT)
AS
  BEGIN

  DECLARE @RefClientIds VARCHAR(MAX) , @InternalAlertId INT , @AlertRefClientId INT

  SET @InternalAlertId = @AlertId

  SELECT 
	@RefClientIds = CONVERT(VARCHAR,alert.RefClientId) + ','+ alert.ISINName
  FROM dbo.CoreAmlScenarioAlert alert WHERE CoreAmlScenarioAlertId = @InternalAlertId

  SELECT @AlertRefClientId = alert.RefClientId FROM dbo.CoreAmlScenarioAlert alert WHERE CoreAmlScenarioAlertId = @InternalAlertId

  CREATE TABLE #AccDetails(RefClientId INT,BankAccountNo VARCHAR(500) COLLATE DATABASE_DEFAULT)

  INSERT INTO #AccDetails
  SELECT DISTINCT 
	S.s,
	micr.BankAccNo
  FROM dbo.Parsestring(@RefClientIds, ',') S
  INNER JOIN dbo.LinkRefClientRefBankMicr micr ON S.s = micr.RefClientId

  INSERT INTO #AccDetails
  SELECT DISTINCT 
	S.s,
	acc.BankAccountNo	
  FROM dbo.Parsestring(@RefClientIds, ',') S
  INNER JOIN dbo.CoreCRMBankAccount acc ON S.s = acc.EntityId

  SELECT 
	S.s AS RefClientId,
	STUFF((	
			SELECT DISTINCT ' , ' + temp.BankAccountNo
				FROM #AccDetails temp 
				WHERE S.s = temp.RefClientId
			FOR XML PATH ('')), 1, 3, '') AS BankAccountNo
  INTO #BankDetails
  FROM dbo.Parsestring(@RefClientIds, ',') S 

      SELECT cl.RefClientId,
             cl.[NAME],
             cl.ClientId,
             cl.Email,
             cl.Mobile,
             cl.PAN,
             LTRIM(RTRIM(ISNULL(cl.PAddressLine1, '')) + ' ')
             + LTRIM(RTRIM(ISNULL(cl.PAddressLine2, '')) + ' ')
             + LTRIM(RTRIM(ISNULL(cl.PAddressLine3, '')) + ' ')
             + LTRIM(RTRIM(ISNULL(cl.PAddressPin, '')) + ' ')
             + LTRIM(RTRIM(ISNULL(cl.PAddressCity, '')) + ' ')
             + LTRIM(RTRIM(ISNULL(cl.PAddressState, '')) + ' ')
             + LTRIM(RTRIM(ISNULL(cl.PAddressCountry, ''))) AS PAddress,
			 LTRIM(RTRIM(ISNULL(cl.CAddressLine1 + ',', '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressLine2 + ',', '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressLine3 + ',', '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressPin + ',', '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressCity + ',', '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressState + ',', '')) + ' ')  
             + LTRIM(RTRIM(ISNULL(cl.CAddressCountry , ''))) AS CAddress, 
			 bank.BankAccountNo,
			 CASE WHEN cl.RefClientId = @AlertRefClientId THEN 1 ELSE 0 END AS IsAlertRefClientId
      FROM   dbo.RefClient cl
             INNER JOIN dbo.Parsestring(@RefClientIds, ',') S
                     ON cl.RefClientId = S.s
			 LEFT JOIN #BankDetails bank ON S.s = bank.RefClientId
  END

GO
RefClient_audit

al
clie
addedon
