--File:StoredProcedures:dbo:CoreAlertRegisterCoreWorkFlowProgress_SaveAlertRegisterCoreWorkFlowProgress
--WEB-80757-RC START
GO
CREATE PROCEDURE [dbo].CoreAlertRegisterCoreWorkFlowProgress_SaveAlertRegisterCoreWorkFlowProgress
(
	@CaseId BIGINT,
	@AssigneeEmployeeId INT,
	@AssignorEmployeeId INT
)
AS
BEGIN
	DECLARE @CaseIdInternal BIGINT,@AssigneeEmployeeIdInternal INT,@AssignorEmployeeIdInternal INT,@CoreWorkflowProgressId BIGINT,@AlertRegisterCaseEntityTypeId INT,@Assignor VARCHAR(100),
		@currDate DATETIME

	SET @CaseIdInternal = @CaseId
	SET @AssigneeEmployeeIdInternal = @AssigneeEmployeeId
	SET @AssignorEmployeeIdInternal = @AssignorEmployeeId
	SET @AlertRegisterCaseEntityTypeId = dbo.GetEntityTypeByCode('AlertRegisterCase')   
	SET @CoreWorkflowProgressId = (SELECT core.CoreWorkflowProgressId FROM dbo.CoreWorkflowProgressLatest core WHERE EntityId = @CaseIdInternal AND RefEntityTypeId = @AlertRegisterCaseEntityTypeId)
	SET @Assignor = (SELECT emp.UserName FROM dbo.RefEmployee emp WHERE emp.RefEmployeeId = @AssignorEmployeeIdInternal)
	SET @currDate =  GETDATE()
	
	
	UPDATE core
	SET  core.AssignedRefEmployeeId = @AssigneeEmployeeIdInternal,
		core.AssignorRefEmployeeId = @AssignorEmployeeIdInternal,
		core.EditedOn = @currDate,
		core.LastEditedBy = @Assignor
	FROM dbo.CoreWorkflowProgress core
	WHERE core.CoreWorkflowProgressId = @CoreWorkflowProgressId

END
GO
--WEB-80757-RC END

--File:Tables:dbo:CoreAlertRegisterCaseAssignmentHistory:DML
--WEB-80757-RC START
GO
	DECLARE @AlertRegisterCaseEntityTypeId INT

	SET @AlertRegisterCaseEntityTypeId = dbo.GetEntityTypeByCode('AlertRegisterCase') 
	

	SELECT 
	  la.EntityId,
	  la.AssignedRefEmployeeId,
	  la.AssignorRefEmployeeId,
	  la.EditedOn
	INTO #tempWorkFLowData
	FROM dbo.CoreWorkflowProgressLatest la
	WHERE la.RefEntityTypeId = @AlertRegisterCaseEntityTypeId AND la.AssignedRefEmployeeId IS NOT NULL

	INSERT INTO dbo.CoreAlertRegisterCaseAssignmentHistory
	(
		CoreAlertRegisterCaseId,
		AssigneeRefEmployeeId,
		AssignorRefEmployeeId,
		AddedBy,
		AddedOn,
		LastEditedBy,
		EditedOn
	)SELECT 
		tem.EntityId,
		tem.AssignedRefEmployeeId,
		tem.AssignorRefEmployeeId,
		emp.UserName,
		tem.EditedOn,
		emp.UserName,
		tem.EditedOn
	FROM #tempWorkFLowData tem
	INNER JOIN dbo.RefEmployee emp ON emp.RefEmployeeId = tem.AssignorRefEmployeeId
	INNER JOIN dbo.CoreAlertRegisterCase cas ON cas.CoreAlertRegisterCaseId = tem.EntityId
	LEFT JOIN dbo.CoreAlertRegisterCaseAssignmentHistoryLatest la ON la.CoreAlertRegisterCaseId = tem.EntityId 
	WHERE la.CoreAlertRegisterCaseAssignmentHistoryId IS NULL OR tem.EditedOn >= la.EditedOn
GO
--WEB-80757-RC END

--File:Tables:dbo:CoreWorkFlowProgress:DML
--WEB-80757-RC START
GO
	DECLARE @AlertRegisterCaseEntityTypeId INT

	SET @AlertRegisterCaseEntityTypeId = dbo.GetEntityTypeByCode('AlertRegisterCase') 
	SELECT
		wrla.CoreWorkflowProgressId,
		la.CoreAlertRegisterCaseId,
		la.AssigneeRefEmployeeId,
		la.AssignorRefEmployeeId,
		la.EditedOn
	INTO #tempCoreAlertRegisterCaseAssignmentHistory
	FROM dbo.CoreAlertRegisterCaseAssignmentHistoryLatest la
	INNER JOIN CoreWorkflowProgressLatest wrla ON wrla.EntityId = la.CoreAlertRegisterCaseId AND wrla.RefEntityTypeId = @AlertRegisterCaseEntityTypeId
	WHERE la.EditedOn >= wrla.EditedOn

	UPDATE  pr
		SET pr.AssignedRefEmployeeId = tem.AssigneeRefEmployeeId,
		pr.AssignorRefEmployeeId = tem.AssignorRefEmployeeId,
		pr.EditedOn = tem.EditedOn,
		pr.LastEditedBy = emp.UserName
	FROM dbo.CoreWorkFlowProgress pr
	INNER JOIN #tempCoreAlertRegisterCaseAssignmentHistory tem ON  tem.CoreWorkflowProgressId = pr.CoreWorkflowProgressId
	INNER JOIN dbo.RefEmployee emp ON emp.RefEmployeeId = tem.AssignorRefEmployeeId
	 
GO
--WEB-80757-RC END
