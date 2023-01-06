--File:Tables:dbo:RefAmlReport:CREATE
--WEB-85320-START- RC
GO
	CREATE TABLE dbo.StagingClientRiskCategorizationPAN
	(
		StagingClientRiskCategorizationPANId INT IDENTITY(1,1) NOT NULL,
		PAN VARCHAR(20),
		EffectiveFrom DATETIME,
		EffectiveTo DATETIME,
		Risk VARCHAR(200),
		Remarks VARCHAR(2000),

		ErrorString VARCHAR(MAX),

		[GUID] VARCHAR(40),
		AddedBy VARCHAR(50) NOT NULL,
		AddedOn DATETIME NOT NULL
	)
		ALTER TABLE dbo.StagingClientRiskCategorizationPAN
		ADD CONSTRAINT [PK_StagingClientRiskCategorizationPAN] 
		PRIMARY KEY (StagingClientRiskCategorizationPANId);
GO
--WEB-85320 -END - RC
--File:StoredProcedures:dbo:LinkRefClientRefRiskCategory_insertUpdateFromStagingClientRiskCategorizationPAN
--WEB- 85320 -START- RC
GO
	CREATE PROCEDURE [dbo].[LinkRefClientRefRiskCategory_insertUpdateFromStagingClientRiskCategorizationPAN]  
	(  
		 @Guid VARCHAR(40)  
	)  
	AS
	BEGIN
	 
	 DECLARE @GuidInternal VARCHAR(40), @RecordLineNo INT, @ErrorString VARCHAR(100)  
	 
	 SET @GuidInternal = @Guid  
	 
	 SET @ErrorString = 'Error in Client RiskCategorizationPan upload at Line : '  
  
	 SET @RecordLineNo = (SELECT MIN(stag.StagingClientRiskCategorizationPANId) FROM dbo.StagingClientRiskCategorizationPAN stag WHERE stag.[GUID] = @GuidInternal)  
	
	 DELETE stag
	 FROM dbo.StagingClientRiskCategorizationPAN stag
	 LEFT JOIN dbo.RefExemptPAN exe ON exe.PAN = stag.PAN AND stag.[GUID] = @GuidInternal
	 WHERE exe.RefExemptPanId IS NOT NULL OR SUBSTRING(ISNULL(stag.PAN, ''), 1, 6) = 'MERGER'
	 
	 UPDATE stag
	 SET stag.ErrorString = 'Invalid Risk '+ stag.Risk
	 FROM dbo.StagingClientRiskCategorizationPAN stag
	 LEFT JOIN dbo.RefRiskCategory catg ON catg.[Name] =  stag.Risk AND stag.[GUID] = @GuidInternal
	 WHERE catg.RefRiskCategoryId IS NULL

	 SELECT 
		t.StagingClientRiskCategorizationPANId,
		t.RefClientId,
		t.RefClientSpecialCategoryId
	 INTO #clientData
	 FROM(
			 SELECT stag.StagingClientRiskCategorizationPANId , cl.RefClientId,cl.RefClientSpecialCategoryId,
				ROW_NUMBER() OVER(PARTITION BY stag.StagingClientRiskCategorizationPANId ORDER BY  cl.AddedOn) AS RN
			 FROM dbo.StagingClientRiskCategorizationPAN stag
			 INNER JOIN dbo.RefClient cl ON cl.PAN = stag.PAN
			 WHERE  stag.[GUID] = @GuidInternal 
		)t WHERE t.RN = 1

	 UPDATE stag
	 SET stag.ErrorString = ISNULL(stag.ErrorString + ', ','') + 'Risk Of Special Category Client Should be atleast High'
	 FROM dbo.StagingClientRiskCategorizationPAN stag
	 INNER JOIN #clientData cl ON cl.StagingClientRiskCategorizationPANId = stag.StagingClientRiskCategorizationPANId
	 INNER JOIN dbo.RefRiskCategory catg ON catg.[Name] =  stag.Risk 
	 WHERE stag.[GUID] = @GuidInternal AND stag.ErrorString IS NULL AND catg.RiskLevel NOT IN (7,10) AND cl.RefClientSpecialCategoryId IS NOT NULL

	 UPDATE stag
	 SET stag.ErrorString = CASE WHEN dbo.ValidatePan(stag.PAN) = 0 OR stag.PAN IS NULL THEN ISNULL(stag.ErrorString + ', ','') + 'Entered PAN NOT Valid:' + ISNULL(stag.PAN,'')
							WHEN cl.StagingClientRiskCategorizationPANId IS NULL THEN ISNULL(stag.ErrorString + ', ','') +  'Client with PAN ' + stag.PAN +' not present in database'
							ELSE stag.ErrorString
							END
	 FROM dbo.StagingClientRiskCategorizationPAN stag
	 LEFT JOIN #clientData cl ON cl.StagingClientRiskCategorizationPANId = stag.StagingClientRiskCategorizationPANId
	 WHERE stag.[GUID] = @GuidInternal

	 UPDATE stag 
	 SET stag.ErrorString = ISNULL(stag.ErrorString + ', ','') + ' Effective From Date Sould not be Blank'
	 FROM dbo.StagingClientRiskCategorizationPAN stag
	 WHERE stag.EffectiveFrom IS NULL AND stag.[GUID] = @GuidInternal 

	 UPDATE stag
	 SET stag.ErrorString = ISNULL(stag.ErrorString + ', ','') + 'From Date should be less than To date'
	 FROM dbo.StagingClientRiskCategorizationPAN stag
	 WHERE stag.EffectiveFrom IS NOT NULL AND stag.EffectiveTo IS NOT NULL AND stag.EffectiveFrom > stag.EffectiveTo AND stag.[GUID] = @GuidInternal

	 SELECT t.*
	 INTO #tempLatestRisk
	 FROM(
		 SELECT
			cl.RefClientId,
			cl.StagingClientRiskCategorizationPANId,
			ROW_NUMBER() OVER(PARTITION BY risk.RefClientId ORDER BY risk.FromDate DESC) rn,
			risk.LinkRefClientRefRiskCategoryId
		 FROM #clientData cl
		 INNER JOIN dbo.LinkRefClientRefRiskCategory risk ON risk.RefClientId = cl.RefClientId
		 )t WHERE t.rn = 1
	 
	 UPDATE stag
	 SET stag.ErrorString = ISNULL(stag.ErrorString + ', ','') + 'The Current From Date Conflict with existing record'
	 FROM dbo.StagingClientRiskCategorizationPAN stag
	 INNER JOIN #tempLatestRisk risk ON risk.StagingClientRiskCategorizationPANId = stag.StagingClientRiskCategorizationPANId
	 INNER JOIN  dbo.LinkRefClientRefRiskCategory riskLink ON riskLink.LinkRefClientRefRiskCategoryId = risk.LinkRefClientRefRiskCategoryId AND (riskLink.FromDate > stag.EffectiveFrom OR (riskLink.ToDate IS NOT NULL AND riskLink.ToDate >= stag.EffectiveFrom))
	  
	 UPDATE riskLink  
		 SET riskLink.ToDate = DATEADD(DAY, -1, stag.EffectiveFrom),  
		  riskLink.LastEditedBy = stag.AddedBy,  
		  riskLink.EditedOn = stag.AddedOn  
	 FROM dbo.StagingClientRiskCategorizationPAN stag 
	 INNER JOIN #tempLatestRisk risk ON risk.StagingClientRiskCategorizationPANId = stag.StagingClientRiskCategorizationPANId
	 INNER JOIN  dbo.LinkRefClientRefRiskCategory riskLink ON riskLink.LinkRefClientRefRiskCategoryId = risk.LinkRefClientRefRiskCategoryId  AND riskLink.FromDate < stag.EffectiveFrom
	 WHERE riskLink.ToDate  IS NULL AND stag.ErrorString IS NULL  AND stag.[GUID] = @GuidInternal

	 UPDATE riskLink  
		 SET riskLink.RefRiskCategoryId = catg.RefRiskCategoryId,
		  riskLink.ToDate = stag.EffectiveTo,  
		  riskLink.LastEditedBy = stag.AddedBy,  
		  riskLink.EditedOn = stag.AddedOn,
		  riskLink.Notes = stag.Remarks
	 FROM dbo.StagingClientRiskCategorizationPAN stag 
	 INNER JOIN #tempLatestRisk risk ON risk.StagingClientRiskCategorizationPANId = stag.StagingClientRiskCategorizationPANId
	 INNER JOIN  dbo.LinkRefClientRefRiskCategory riskLink ON riskLink.LinkRefClientRefRiskCategoryId = risk.LinkRefClientRefRiskCategoryId  AND riskLink.FromDate = stag.EffectiveFrom
	 INNER JOIN dbo.RefRiskCategory catg ON catg.[Name] = stag.Risk
	 WHERE riskLink.ToDate  IS NULL AND stag.ErrorString IS NULL  AND stag.[GUID] = @GuidInternal

	 INSERT INTO dbo.LinkRefClientRefRiskCategory   
	 (  
		  RefClientId,  
		  RefRiskCategoryId,  
		  FromDate,  
		  ToDate,  
		  AddedBy,  
		  AddedOn,  
		  LastEditedBy,  
		  EditedOn,  
		  Notes  
	 )  
		 SELECT   
		  cl.RefClientId,  
		  ctag.RefRiskCategoryId,
		  stag.EffectiveFrom,
		  stag.EffectiveTo, 
		  stag.AddedBy,
		  stag.AddedOn,  
		  stag.AddedBy,  
		  stag.AddedOn,  
		  stag.Remarks  
		 FROM #clientData cl
		 INNER JOIN dbo.StagingClientRiskCategorizationPAN stag ON stag.StagingClientRiskCategorizationPANId = cl.StagingClientRiskCategorizationPANId
		 INNER JOIN dbo.RefRiskCategory ctag ON ctag.[Name] = stag.Risk
		 LEFT JOIN dbo.LinkRefClientRefRiskCategory dupcheck ON dupcheck.RefClientId = cl.RefClientId AND stag.EffectiveFrom = dupcheck.FromDate 
		 WHERE stag.[GUID] = @GuidInternal AND stag.ErrorString IS NULL AND dupcheck.LinkRefClientRefRiskCategoryId IS NULL 

	 SELECT
		@ErrorString + CONVERT(VARCHAR , (stag.StagingClientRiskCategorizationPANId - @RecordLineNo + 1))+ stag.ErrorString AS ErrorMessage
	 FROM dbo.StagingClientRiskCategorizationPAN stag
	 WHERE stag.ErrorString IS NOT NULL AND stag.[GUID] = @GuidInternal

	 DELETE FROM dbo.StagingClientRiskCategorizationPAN WHERE [GUID] = @GuidInternal  
  
	END  
GO
--WEB-  85320- END -RC
