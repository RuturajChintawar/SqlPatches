---RC Start-WEB-65103
GO
ALTER PROCEDURE dbo.CoreScreeningRequestHistory_GetWebhookData (
	@CaseId BIGINT
)
AS
BEGIN
	DECLARE @ScreeningRequestSourceValueId INT, @InternalCaseId BIGINT, @AdverseMediaClassificationId INT, 
		@PEPClassificationId INT, @ReputationClassificationId INT, @ExternalSystemId INT,
		@WebhookTypeId INT, @Proceed BIT = 0

	SET @InternalCaseId = @CaseId
	SET @ScreeningRequestSourceValueId = dbo.GetEnumValueId('CustomerScreeningRequestSourceType', 'T5')
	SET @AdverseMediaClassificationId = dbo.GetEnumTypeId('AdverseMediaClassification')
	SET @PEPClassificationId = dbo.GetEnumTypeId('PEPClassification')
	SET @ReputationClassificationId = dbo.GetEnumTypeId('ReputationClassification')
	SET @WebhookTypeId = dbo.GetEnumValueId('WebHookType', 'TW04')

	IF EXISTS (SELECT 1 FROM dbo.CoreScreeningRequestHistory 
		WHERE CoreScreeningCaseId = @InternalCaseId AND ScreeningRequestSourceTypeRefEnumValueId = @ScreeningRequestSourceValueId)
	BEGIN
		SET @Proceed = 1

		SELECT
			cas.CoreScreeningCaseId,
			parent.[Name] AS ParentCompany,
			cas.RefEntityTypeId,
			entity.Code AS EntityTypeCode,
			cas.RecordIdentifier,
			latest.RefWorkflowStepId,
			hist.SystemName,
			pepEnum.[Name] AS PEP,
			pepEnum.Code AS PEPCode,
			finalEnum.[Name] AS FinalDecision
		INTO #tempCase
		FROM dbo.CoreScreeningRequestHistory hist
		INNER JOIN dbo.CoreScreeningCase cas ON cas.CoreScreeningCaseId = hist.CoreScreeningCaseId
		INNER JOIN dbo.RefParentCompany parent ON cas.RefParentCompanyId = parent.RefParentCompanyId
		INNER JOIN dbo.RefEntityType entity ON cas.RefEntityTypeId = entity.RefEntityTypeId
		INNER JOIN dbo.CoreWorkflowProgressLatest latest ON latest.RefEntityTypeId = cas.RefEntityTypeId
			AND latest.EntityId = cas.CoreScreeningCaseId
		LEFT JOIN dbo.RefEnumValue pepEnum ON cas.PEPRefEnumValueId = pepEnum.RefEnumValueId
		LEFT JOIN dbo.RefEnumValue finalEnum ON cas.ScreeningCaseFinalDecisionRefEnumValueId = finalEnum.RefEnumValueId
		WHERE hist.CoreScreeningCaseId = @InternalCaseId 
			AND hist.ScreeningRequestSourceTypeRefEnumValueId = @ScreeningRequestSourceValueId

		SELECT @ExternalSystemId = ex.RefExternalSystemId
		FROM #tempCase temp
		INNER JOIN dbo.RefExternalSystem ex ON temp.SystemName = ex.[Name]

		IF @ExternalSystemId IS NULL
			SET @Proceed = 0

		SELECT @Proceed

		SELECT link.RefWebHookId AS WebbookId
		FROM dbo.LinkRefExternalSystemRefWebhook link
		INNER JOIN dbo.RefWebHook webhook ON link.RefWebHookId = webhook.RefWebHookId
		WHERE link.RefExternalSystemId = @ExternalSystemId
			AND webhook.WebHookTypeRefEnumValueId = @WebhookTypeId

		SELECT  
			tempCase.CoreScreeningCaseId,
			enumValue.[Name] AS EnumValue,
			enumValue.RefEnumTypeId,
			enumValue.Code,
			ROW_NUMBER() OVER(Partition By tempCase.CoreScreeningCaseId, enumValue.RefEnumTypeId Order By entityEnumValue.EditedOn DESC, enumValue.[Name] ) RN
		INTO #caseEnumValues
		FROM #tempCase tempCase
		INNER JOIN dbo.CoreEntityEnumValue entityEnumValue ON entityEnumValue.RefEntityTypeId = tempCase.RefEntityTypeId 
			AND entityEnumValue.EntityId = tempCase.CoreScreeningCaseId
		INNER JOIN dbo.RefEnumValue enumValue ON enumValue.RefEnumValueId = entityEnumValue.RefEnumValueId

		SELECT  
			scrCase.RecordIdentifier,  
			scrCase.RefWorkflowStepId,
			STUFF((SELECT ',' + t.Code 
					FROM #caseEnumValues t 
					WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @AdverseMediaClassificationId
			FOR XML PATH ('')), 1, 1, '')AS AdverseMediaClassificationCode,
			STUFF((SELECT ',' + EnumValue 
					FROM #caseEnumValues t 
					WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @AdverseMediaClassificationId
			FOR XML PATH ('')), 1, 1, '') AS AdverseMediaClassification,
			STUFF((SELECT ',' + t.Code 
					FROM #caseEnumValues t 
					WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @ReputationClassificationId
			FOR XML PATH ('')), 1, 1, '') AS ReputationalClassificationCode,
			STUFF((SELECT ',' + EnumValue 
					FROM #caseEnumValues t 
					WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @ReputationClassificationId
			FOR XML PATH ('')), 1, 1, '') AS ReputationalClassification,
			STUFF((SELECT ',' + t.Code  
					FROM #caseEnumValues t 
					WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @PEPClassificationId
			FOR XML PATH ('')), 1, 1, '') AS PEPClassificationCode, 
			STUFF((SELECT ',' + EnumValue 
					FROM #caseEnumValues t 
					WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @PEPClassificationId
			FOR XML PATH ('')), 1, 1, '') AS PEPClassification,
			scrCase.PEP,
			scrCase.PEPCode,
			scrCase.FinalDecision,
			scrCase.ParentCompany,
			scrCase.EntityTypeCode,
			scrCase.RefEntityTypeId,
			scrCase.SystemName as SourceSystem  
		FROM #tempCase scrCase
	END ELSE SELECT @Proceed
END
GO
---RC Start-WEB-65103
---RC Start-WEB-65103
GO
ALTER PROCEDURE [dbo].[CoreScreeningCase_GetWH7WebHookRequestData]  
(  
 @EntityIds VARCHAR(MAX)  
)  
AS  
BEGIN  
   
 DECLARE @InternalEntityIds VARCHAR(MAX)  
 SET @InternalEntityIds = @EntityIds  
  
 DECLARE @ParentCompany VARCHAR(400), @EntityTypeId INT, @EntityTypeCode VARCHAR(200),
		@AdverseMediaClassificationId INT,@PEPClassificationId INT,@ReputationClassificationId INT

	SET @AdverseMediaClassificationId = dbo.GetEnumTypeId('AdverseMediaClassification')
	SET @PEPClassificationId = dbo.GetEnumTypeId('PEPClassification')
	SET @ReputationClassificationId = dbo.GetEnumTypeId('ReputationClassification')
  
 SELECT   
  t.s AS CoreScreeningCaseId  
 INTO #CaseIds  
 FROM dbo.ParseString(@InternalEntityIds,',') as t  
  
	 SELECT   
		scrCase.CoreScreeningCaseId,  
		scrCase.RefParentCompanyId,  
		scrCase.RefEntityTypeId,  
		scrCase.RecordIdentifier,  
		pc.Name AS ParentCompany,  
		latest.RefWorkflowStepId ,
		pepValue.Name AS PEP ,
		pepValue.Code AS PEPCode ,
		finalDecesion.Name AS FinalDecision,
		scrCase.RecordEntityId,
		scrCase.RecordRefEntityTypeId
	 INTO #tempCases  
	 FROM dbo.CoreScreeningCase scrCase  
	 INNER JOIN #CaseIds cids ON cids.CoreScreeningCaseId = scrCase.CoreScreeningCaseId  
	 INNER JOIN dbo.RefParentCompany pc ON pc.RefParentCompanyId = scrCase.RefParentCompanyId  
	 INNER JOIN dbo.CoreWorkflowProgressLatest latest ON latest.RefEntityTypeId = scrCase.RefEntityTypeId AND latest.EntityId = scrCase.CoreScreeningCaseId  
	 LEFT JOIN dbo.RefEnumValue pepValue ON pepValue.RefEnumValueId = scrCase.PEPRefEnumValueId
	 LEFT JOIN dbo.RefEnumValue finalDecesion on finalDecesion.RefEnumValueId = scrCase.ScreeningCaseFinalDecisionRefEnumValueId

	 SELECT  
		 tempCases.CoreScreeningCaseId,
		 enumValue.Name AS EnumValue,
		 enumValue.Code,
		 enumValue.RefEnumTypeId,
			ROW_NUMBER() OVER(Partition By tempCases.CoreScreeningCaseId, enumValue.RefEnumTypeId Order By entityEnumValue.EditedOn, enumValue.[Name] DESC ) RN
	 INTO #caseEnumValues
	 FROM #tempCases tempCases
	 INNER JOIN dbo.CoreEntityEnumValue entityEnumValue ON entityEnumValue.RefEntityTypeId = tempCases.RefEntityTypeId AND entityEnumValue.EntityId = tempCases.CoreScreeningCaseId
	 INNER JOIN dbo.RefEnumValue enumValue ON enumValue.RefEnumValueId = entityEnumValue.RefEnumValueId

	 SELECT   
	 TOP 1   
	 @ParentCompany = scrCase.ParentCompany, @EntityTypeId = scrCase.RefEntityTypeId   
	 FROM #tempCases scrCase  
  
	--SoucreSystemCode of Customer
	SELECT  * 
	INTO #CaseCustomerSourceSystemInfo
	FROM (
		SELECT   
		temp.CoreScreeningCaseId,
		externalSystem.Name AS ExternalSystem,
		ROW_NUMBER() OVER(PARTITION BY temp.CoreScreeningCaseId  ORDER BY ident.CoreCRMIdentificationId) AS ROWNUM
		FROM #tempCases temp 
		INNER JOIN dbo.CoreCRMIdentification ident ON temp.RecordRefEntityTypeId = ident.RefEntityTypeId AND temp.RecordEntityId  = ident.EntityId
		INNER JOIN dbo.RefIdentificationType idenType ON idenType.RefIdentificationTypeId = ident.RefIdentificationTypeId AND idenType.IsExternalSystem = 1
		INNER JOIN dbo.RefExternalSystem externalSystem On externalSystem.RefIdentificationTypeId = ident.RefIdentificationTypeId
	) t
	WHERE t.ROWNUM = 1

	 SELECT @EntityTypeCode = Code FROM dbo.RefEntityType WHERE RefEntityTypeId = @EntityTypeId  
   
	-- table 1  
	 SELECT @ParentCompany, @EntityTypeCode  
  
	-- table 2  
	SELECT   
		scrCase.CoreScreeningCaseId,  
		scrCase.RecordIdentifier,  
		scrCase.RefWorkflowStepId,
		STUFF((SELECT ',' + t.Code 
					FROM #caseEnumValues t 
					WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @AdverseMediaClassificationId
			FOR XML PATH ('')), 1, 1, '')AS AdverseMediaClassificationCode,
		STUFF((SELECT ',' + EnumValue 
				FROM #caseEnumValues t 
				WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @AdverseMediaClassificationId
		FOR XML PATH ('')), 1, 1, '') AS AdverseMediaClassification,
		STUFF((SELECT ',' + t.Code 
					FROM #caseEnumValues t 
					WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @ReputationClassificationId
			FOR XML PATH ('')), 1, 1, '') AS ReputationalClassificationCode,
		STUFF((SELECT ',' + EnumValue 
				FROM #caseEnumValues t 
				WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @ReputationClassificationId
		FOR XML PATH ('')), 1, 1, '') AS ReputationalClassification,
		STUFF((SELECT ',' + t.Code  
					FROM #caseEnumValues t 
					WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @PEPClassificationId
			FOR XML PATH ('')), 1, 1, '') AS PEPClassificationCode,
		STUFF((SELECT ',' + EnumValue 
				FROM #caseEnumValues t 
				WHERE t.CoreScreeningCaseId = scrCase.CoreScreeningCaseId AND t.RefEnumTypeId = @PEPClassificationId
		FOR XML PATH ('')), 1, 1, '') AS PEPClassification,
		scrCase.PEP,
		scrCase.PEPCode,
		scrCase.FinalDecision,
		tempSourceSystem.ExternalSystem AS SourceSystem
	 FROM #tempCases scrCase 
	 LEFT JOIN #CaseCustomerSourceSystemInfo tempSourceSystem ON scrCase.CoreScreeningCaseId = tempSourceSystem.CoreScreeningCaseId
  
END
GO
---RC END-WEB-65103