-- CREATE PROCEDURE [dbo].[RefClient_GetClientfromHighRiskCountry]      
--(      
declare
 @ExcludeClosedAccounts bit=0,   
 @LatestRecordOnly BIT = 0, 
 @FromDate datetime='04-14-2022',      
 @ToDate datetime='04-16-2022',      
 @EffectiveDate datetime = NULL,      
 @RiskIds VARCHAR(MAX)='2,7',      
 @RefClientDatabaseEnumId INT = NULL,      
 @RowsPerPage int = NULL,      
 @Page int= 1      
--)      
--as      
--BEGIN        
      
		 DECLARE @RefClientDatabaseEnumIdInternal INT, @InternalFromDate DATETIME, @InternalToDate DATETIME ,@InternalLatestRecordOnly BIT       
		 SET @InternalLatestRecordOnly = @LatestRecordOnly       
		 SET @RefClientDatabaseEnumIdInternal = @RefClientDatabaseEnumId      
      
		  IF (@RowsPerPage IS NULL )       
			 SET @RowsPerPage = 9999999      
           
          SELECT riskid.s AS RefCountryStatusId      
		 INTO #CountryStatus      
		 FROM  dbo.ParseString(@RiskIds, ',') riskid 
      
		 SELECT link.LinkRefCountryRefCountryStatusId,ROW_NUMBER()OVER (PARTITION BY link.RefCountryId ORDER BY link.EffectiveDate DESC) rn
		 INTO #LatestFATFCountry      
		 FROM dbo.LinkRefCountryRefCountryStatus link      
		 INNER JOIN #CountryStatus s ON s.RefCountryStatusId = link.RefCountryStatusId     
		 WHERE ((@EffectiveDate IS NULL) OR link.EffectiveDate <= @EffectiveDate)      
		 
      
		 SELECT RefClientId, ClientId, PAN, AccountOpeningDate, AccountClosingDate,CAddressCountry,PAddressCountry, [Name], RefClientDatabaseEnumId, RefClientSpecialCategoryId      
		 INTO #Clienttemp      
		 FROM dbo.RefClient           
		 WHERE ISNULL(AccountOpeningDate,'01-01-1900')>=@FromDate and ISNULL(AccountOpeningDate,'01-01-9999')<=@ToDate AND
			(@RefClientDatabaseEnumIdInternal IS NULL OR RefClientDatabaseEnumId = @RefClientDatabaseEnumIdInternal)  AND
			(@ExcludeClosedAccounts = 0 OR ISNULL(AccountClosingDate,'01-01-9999')>GETDATE()) 
      
		 SELECT      
		 rcl.[Name],      
		 rcld.DatabaseType,      
		 rcl.RefClientId,      
		 rcl.ClientId,      
		 rcl.PAN,      
		 country.[Name] AS FATFCountry,      
		 statu.[Name] AS [Status],     
		 link.EffectiveDate,    
		 CASE WHEN country.[Name] = rcl.PAddressCountry THEN rcl.PAddressCountry 
			  WHEN country.[Name] = rcl.CAddressCountry then rcl.CAddressCountry 
			  ELSE null END AS ClientCountry,
		 CASE WHEN country.[Name] = rcl.PAddressCountry THEN 'Permanent Address' 
			  WHEN country.[Name] = rcl.CAddressCountry then 'Correspondence Address' 
			  ELSE null END AS [Type],      
		 riskcat.[Name] AS RiskCategory,      
		 sc.[Name] AS SpecialCategory,      
		 rcl.AccountOpeningDate,      
		 rcl.AccountClosingDate,      
		 ROW_NUMBER() OVER (ORDER BY  rcl.RefClientId) AS rn      
		 INTO #TempReport      
		 FROM #LatestFATFCountry rc 
		 INNER JOIN dbo.LinkRefCountryRefCountryStatus link ON link.LinkRefCountryRefCountryStatusId = rc.LinkRefCountryRefCountryStatusId
		 INNER JOIN dbo.RefCountryStatus statu ON statu.RefCountryStatusId = link.RefCountryStatusId
		 INNER JOIN dbo.RefCountry country ON country.RefCountryId = link.RefCountryId
		 INNER JOIN #Clienttemp rcl ON rcl.CAddressCountry = country.[Name] OR rcl.PAddressCountry = country.[Name]  
		 INNER JOIN dbo.LinkRefClientRefRiskCategoryLatest linkrisk ON linkrisk.RefClientId=rcl.RefClientId      
		 LEFT JOIN dbo.RefRiskCategory riskcat ON riskcat.RefRiskCategoryId=linkrisk.RefRiskCategoryId      
		 LEFT JOIN dbo.RefClientDatabaseEnum rcld ON rcld.RefClientDatabaseEnumId = rcl.RefClientDatabaseEnumId      
		 LEFT JOIN dbo.RefClientSpecialCategory sc ON sc.RefClientSpecialCategoryId = rcl.RefClientSpecialCategoryId      
		 WHERE (@InternalLatestRecordOnly = 0 OR @InternalLatestRecordOnly = rc.rn)      
		
		SELECT *,ROW_NUMBER() OVER (order by #TempReport.RefClientId) AS SrNo  FROM #TempReport      
			WHERE #TempReport.rn BETWEEN ( ( ( @Page - 1 )      
				 * @RowsPerPage ) + 1 )      
				AND     @Page * @RowsPerPage      
      
		SELECT COUNT(*) FROM #TempReport
      
--END   
--select * from LinkRefCountryRefCountryStatus where RefCountryId = 1