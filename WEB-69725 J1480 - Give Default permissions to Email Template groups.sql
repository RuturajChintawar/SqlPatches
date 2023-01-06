-- RC WEB-69725 STARTS
GO
DECLARE @SuccessJ1480Id INT, @FailJ1480Id INT, @SecPermissionRunId INT, @SecPermissionModifyId INT

SELECT @SuccessJ1480Id = RefEmailTemplateId, @FailJ1480Id = FailureRefEmailTemplateId FROM dbo.RefProcess WHERE Code = 'J1480'
SELECT @SecPermissionRunId = sec.SecPermissionId FROM dbo.SecPermission sec WHERE [Name]='P111463_J1480_Run'
SELECT @SecPermissionModifyId = sec.SecPermissionId FROM dbo.SecPermission sec WHERE [Name]='P111464_J1480_Modify'

SELECT DISTINCT 
link.SecGroupId
INTO #rungroup
FROM dbo.LinkRefEmailTemplateSecGroup link
WHERE link.RefEmailTemplateId IN (@SuccessJ1480Id,@FailJ1480Id)
AND NOT EXISTS ( SELECT 1 FROM dbo.LinkSecGroupSecPermission sec WHERE  sec.SecGroupId=link.SecGroupId AND sec.SecPermissionId = @SecPermissionRunId)

INSERT INTO dbo.LinkSecGroupSecPermission 
(SecGroupId,SecPermissionId,AddedBy,AddedOn,LastEditedBy,EditedOn)
SELECT
run.SecGroupId,
@SecPermissionRunId,
'System',
GETDATE(),
'System',
GETDATE()
FROM #rungroup run

SELECT DISTINCT 
link.SecGroupId
INTO #modifygroup
FROM dbo.LinkRefEmailTemplateSecGroup link
WHERE link.RefEmailTemplateId IN (@SuccessJ1480Id,@FailJ1480Id) AND 
NOT EXISTS ( SELECT 1 FROM dbo.LinkSecGroupSecPermission sec WHERE  sec.SecGroupId=link.SecGroupId AND sec.SecPermissionId = @SecPermissionModifyId)

INSERT INTO dbo.LinkSecGroupSecPermission 
(SecGroupId,SecPermissionId,AddedBy,AddedOn,LastEditedBy,EditedOn)
SELECT
mo.SecGroupId,
@SecPermissionModifyId,
'System',
GETDATE(),
'System',
GETDATE()
FROM #modifygroup mo


GO
-- RC WEB-69725 END