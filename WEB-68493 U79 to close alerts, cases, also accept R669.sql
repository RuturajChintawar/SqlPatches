--WEB-68493-RC-start
GO
CREATE TABLE dbo.StagingScreeningAlertClosure
(
	StagingScreeningAlertClosureId INT IDENTITY(1,1),
	AlertId BIGINT NULL,
	AlertDecision VARCHAR(100)  NULL,
	AlertComment VARCHAR(500)  NULL,
	ErrorDescription VARCHAR(MAX) NULL,
	IsError BIT NULL,
	
	AddedBy VARCHAR(100) NOT NULL,
	AddedOn DATETIME NOT NULL,
	[GUID] VARCHAR(1000)
	
)
GO
ALTER TABLE dbo.StagingScreeningAlertClosure
	ADD CONSTRAINT PK_StagingScreeningAlertClosure 
	PRIMARY KEY(StagingScreeningAlertClosureId)
GO
--WEB-68493-RC-end
--WEB-68493-RC-start
GO
 CREATE PROCEDURE [dbo].[CoreScreeningCaseAlert_CloseFromStagingScreeningAlertClosure]    
(    
 @Guid VARCHAR(100),
  @RefEntityTypeCode  VARCHAR(50)  
)    
AS    
BEGIN    
	DECLARE @InternalGuid VARCHAR(100) ,@InternalRefEntityTypeCode  VARCHAR(50),@refParentCompanyId INT, @ScreeningRefEntityTypeId INT
	SET @InternalGuid=@Guid    
    SET @InternalRefEntityTypeCode = @RefEntityTypeCode 

	DECLARE  @AlertDecisionEnumTypeId INT   
    SELECT @AlertDecisionEnumTypeId = refenumtypeid FROM dbo.refenumtype where [Name] = 'ScreeningCaseAlertDecision'  
	
	-----getting the Screening Entitype  
	SELECT @refParentCompanyId = RefParentCompanyId FROM dbo.RefEntityType where code = @InternalRefEntityTypeCode  
	SET @ScreeningRefEntityTypeId =  dbo.GetEntityTypeByParentCompanyIdAndParentEntityTypeCode(@refParentCompanyId,'BaseScreeningCaseManager')  
  
	SELECT stag.StagingScreeningAlertClosureId,      
	stag.[GUID],      
	stag.AlertId,
	stag.AlertDecision,
	stag.AlertComment,
	stag.AddedBy,      
	stag.AddedOn   
	INTO #TempStaging       
	FROM dbo.StagingScreeningAlertClosure stag     
	WHERE stag.[GUID] = @InternalGuid 
	
	CREATE TABLE #Rejection (      
	StagingScreeningAlertClosureId INT NOT NULL,      
	AlertIdRejectionMessage VARCHAR(MAX) COLLATE DATABASE_DEFAULT ,
	AlertDecisionRejectionMessage VARCHAR(MAX) COLLATE DATABASE_DEFAULT ,
	CommentsRejectionMessage VARCHAR(MAX) COLLATE DATABASE_DEFAULT
	)      
	INSERT INTO #Rejection  
	(  
		StagingScreeningAlertClosureId  
	)  
	SELECT  
		stag.StagingScreeningAlertClosureId  
	FROM #TempStaging stag  

	
	--VALIDATION STARTS--  
  
	--All FIELDS MANDATORY VALIDATION /VAR CHECK/ REF ENUM CHECK/COMMENTS VALIDATION
	UPDATE rej  
		SET rej.AlertIdRejectionMessage=CASE
			WHEN ISNULL(stag.AlertId, '') = '' THEN 'Alert Id is mandatory, '
			WHEN ISNULL(alert.CoreScreeningCaseAlertId , '') = '' THEN 'Alert with this Alert Id does not exist, '
			WHEN ISNULL(cases.CoreScreeningCaseId , '') = '' THEN 'Alert Id does belong to this parent company, '
			ELSE NULL
			END,
			rej.AlertDecisionRejectionMessage=CASE
			WHEN ISNULL(stag.AlertDecision, '') = '' THEN 'Alert Decision is mandatory, '
			WHEN ISNULL(ref.RefEnumValueId, '') = '' THEN 'Invaild Decision, '
			ELSE NULL
			END,
			rej.CommentsRejectionMessage=CASE
			WHEN ISNULL(stag.AlertComment, '') = '' THEN 'Alert Comment is mandatory.'
			WHEN LEN(stag.AlertComment) < 25	 THEN 'Minimum 25 characters are mandatory in alert comment.'
			ELSE NULL
			END
	FROM dbo.#TempStaging stag  
	INNER JOIN #Rejection  rej ON rej.StagingScreeningAlertClosureId=stag.StagingScreeningAlertClosureId
	LEFT JOIN dbo.RefEnumValue	ref ON ref.[Name] = stag.AlertDecision AND ref.RefEnumTypeId =@AlertDecisionEnumTypeId
	LEFT JOIN dbo.CoreScreeningCaseAlert alert ON alert.CoreScreeningCaseAlertId = stag.AlertId
	LEFT JOIN dbo.CoreScreeningCase cases ON cases.CoreScreeningCaseId=alert.CoreScreeningCaseId AND cases.RefEntityTypeId = @ScreeningRefEntityTypeId AND cases.RefParentCompanyId = @refParentCompanyId
	 
	--DUPLICATE ALERTID VALIDATION
	UPDATE rej
	SET rej.AlertIdRejectionMessage=ISNULL(rej.AlertIdRejectionMessage, '')+'Duplicate AlertId in file, '
	FROM #Rejection  rej
	INNER JOIN #TempStaging stag ON rej.StagingScreeningAlertClosureId=stag.StagingScreeningAlertClosureId
	INNER JOIN (SELECT stag.AlertId FROM dbo.#TempStaging stag GROUP BY stag.AlertId HAVING COUNT(stag.StagingScreeningAlertClosureId )>1  ) stag1 ON stag.AlertId=stag1.AlertId 

--VALIDATION ENDS--

-- update staging
	UPDATE stag
	SET stag.ErrorDescription=ISNULL(rej.AlertIdRejectionMessage,'')+ISNULL(rej.AlertDecisionRejectionMessage,'')+ISNULL(rej.CommentsRejectionMessage,''),
	stag.IsError=CASE 
	WHEN ISNULL(rej.AlertIdRejectionMessage,'')<>'' OR ISNULL(rej.AlertDecisionRejectionMessage,'') <>'' OR ISNULL(rej.CommentsRejectionMessage,'') <>''THEN 1
	ELSE 0
	END
	FROM dbo.StagingScreeningAlertClosure stag 
	INNER JOIN #Rejection  rej ON rej.StagingScreeningAlertClosureId=stag.StagingScreeningAlertClosureId

	DROP TABLE #Rejection
	DROP TABLE #TempStaging
  
	UPDATE main  
		SET main.ScreeningCaseAlertDecisionRefEnumValueId = ref.refenumvalueid,  
		main.Comments = stag.AlertComment,  
		main.LastEditedBy = stag.AddedBy,  
		main.EditedOn = stag.AddedOn  
	FROM dbo.CoreScreeningCaseAlert main  
	INNER JOIN dbo.StagingScreeningAlertClosure stag ON main.CoreScreeningCaseAlertId = stag.AlertId AND stag.IsError=0
	INNER JOIN dbo.RefEnumValue ref ON ref.[Name] = stag.AlertDecision AND ref.RefEnumTypeId = @AlertDecisionEnumTypeId  
	
	--output excel
	SELECT 
		stag.AlertId,
		stag.AlertDecision,
		stag.AlertComment,
		stag.ErrorDescription
		FROM dbo.StagingScreeningAlertClosure stag
		WHERE stag.IsError=1

  END  
GO
--WEB-68493-RC-end
--WEB-68493-RC-start
GO
 CREATE PROCEDURE [dbo].[CoreScreeningCaseAlert_GetCaseIdU79Utility]  
(  
  @RefEntityTypeCode  VARCHAR(50),  
  @Guid VARCHAR(100),
  @CurrentStepIds VARCHAR(500) = NULL  
)  
AS  
BEGIN  
	  DECLARE @InternalRefEntityTypeCode  VARCHAR(50), @InternalCurrentStepIds VARCHAR(500),  
	   @refParentCompanyId INT, @ScreeningRefEntityTypeId INT, @PendingEnum INT, @MatchEnum INT, @NoMatchEnum INT  ,@InternalGuid VARCHAR(100)
  
	  SET @InternalRefEntityTypeCode = @RefEntityTypeCode  
	  SET @InternalGuid = @Guid
	  SET @PendingEnum = dbo.GetEnumValueId('ScreeningCaseAlertDecision','Pending')
	  SET @MatchEnum = dbo.GetEnumValueId('ScreeningCaseAlertDecision','Match')
	  SET @NoMatchEnum = dbo.GetEnumValueId('ScreeningCaseAlertDecision','NoMatch') 

	-----getting the Screening Entitype  
	SELECT @refParentCompanyId = RefParentCompanyId FROM dbo.RefEntityType where code = @InternalRefEntityTypeCode  
	SET @ScreeningRefEntityTypeId =  dbo.GetEntityTypeByParentCompanyIdAndParentEntityTypeCode(@refParentCompanyId,'BaseScreeningCaseManager')  
  
	----CurrentStep Ids   
	SELECT  
    step.RefWorkflowStepId,  
	step.[Name] AS [StepName]  
	INTO #CurrentWorkflow  
	FROM  dbo.ParseString(@InternalCurrentStepIds,',') s  
	INNER JOIN dbo.RefWorkflowStep step ON s.s = step.RefWorkflowStepId  
  
	--CASE ID FROM STAGING
	SELECT DISTINCT
	alert.CoreScreeningCaseId
	INTO #CaseIdFromStaging
	FROM dbo.StagingScreeningAlertClosure stag
	INNER JOIN dbo.CoreScreeningCaseAlert  alert ON alert.CoreScreeningCaseAlertId = stag.AlertId
	WHERE stag.GUID = @InternalGuid AND stag.IsError = 0

  
   
	---getting the Alert based on filter  
	SELECT  
    cases.CoreScreeningCaseId,  
	alert.CoreScreeningCaseAlertId,  
	alert.ScreeningCaseAlertDecisionRefEnumValueId
	  
	INTO #filterAlerts 
	FROM #CaseIdFromStaging stag
	INNER JOIN dbo.CoreScreeningCase cases  ON cases.CoreScreeningCaseId=stag.CoreScreeningCaseId
	INNER JOIN dbo.CoreScreeningCaseAlert  alert ON alert.CoreScreeningCaseId = cases.CoreScreeningCaseId  
	INNER JOIN dbo.CoreWorkflowProgressLatest wk ON WK.RefEntityTypeId = cases.RefEntityTypeId AND wk.EntityId = cases.CoreScreeningCaseId  
	WHERE cases.RefEntityTypeId = @ScreeningRefEntityTypeId AND cases.RefParentCompanyId = @refParentCompanyId  
	AND ( @InternalCurrentStepIds IS NULL OR EXISTS( SELECT 1 FROM #CurrentWorkflow cw  WHERE cw.RefWorkflowStepId = wk.RefWorkflowStepId))  
	
  -----Total Alert Count after filter  
	SELECT COUNT(DISTINCT(CoreScreeningCaseAlertId)) AS [TotalAlertCount]  
	FROM #filterAlerts  
  

  
 -----For Case Closing  
	SELECT   
	CoreScreeningCaseId,   
	COUNT(CASE WHEN ScreeningCaseAlertDecisionRefEnumValueId=@PendingEnum THEN 1 END) AS [Pending],  
	COUNT(CASE WHEN ScreeningCaseAlertDecisionRefEnumValueId=@MatchEnum THEN 1 END) AS [Match],  
	COUNT(CASE WHEN ScreeningCaseAlertDecisionRefEnumValueId=@NoMatchEnum THEN 1 END) AS [NoMatch],  
	COUNT(1) AS Total  
	INTO #finalCases  
	FROM #filterAlerts  
	GROUP BY CoreScreeningCaseId  
  
	-----At least one alert with Pending  
	SELECT CoreScreeningCaseId FROM #finalCases  
	WHERE [Pending]>0  
  
	 -----At least one with Match and rest with NoMatch  
	 SELECT CoreScreeningCaseId FROM #finalCases  
	 WHERE [Match]>0 AND ([Match]+[NoMatch])=[Total]  
  
	 -----All with NoMatch  
	 SELECT CoreScreeningCaseId FROM #finalCases  
	 WHERE [NoMatch]=[Total]  

	  -----DELETE FROM STAGING   
	  DELETE FROM dbo.StagingScreeningAlertClosure WHERE [GUID] = @internalGuid

END  
GO
--WEB-68493-RC-end
--WEB-68493-RC-start
GO
UPDATE ref
SET ref.[Name]='Utility for closing screening alerts and move cases'
FROM dbo.RefUtility ref
WHERE ref.Code='U79'
GO
--WEB-68493-RC-end