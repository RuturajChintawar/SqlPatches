GO
CREATE PROCEDURE dbo.CoreAlertRegisterCustomerCaseAlert_UpdateCommentAndStatusR434(
	@Guid VARCHAR(40)
)
AS
BEGIN
	DECLARE
	@InternalGuid VARCHAR(40),@RefEnumTypeId INT

	SET @InternalGuid = @Guid
	SET @RefEnumTypeId = (SELECT re.RefEnumTypeId FROM dbo.RefEnumType re WHERE re.[Name] = 'AmlAlertRegisterStatusType')

	UPDATE alert
	SET alert.AlertRegisterStatusTypeRefEnumValueId = enum.RefEnumValueId,
		alert.ClientExplanation = stag.ClientExplanation,
		alert.Comments = stag.Comments,
		alert.LastEditedBy = stag.AddedBy,
		alert.EditedOn = stag.AddedOn
	FROM dbo.CoreAlertRegisterCustomerCaseAlert alert
	INNER JOIN dbo.StagingUpdateCommentAndStatus stag ON stag.EntityId = alert.CoreAlertRegisterCustomerCaseAlertId 
	INNER JOIN dbo.RefEnumValue enum ON enum.[Name] = stag.[Status] AND enum.RefEnumTypeId = @RefEnumTypeId
	WHERE stag.[GUID] = @InternalGuid AND (ISNULL(stag.ClientExplanation, '') <> ISNULL(alert.ClientExplanation, '') OR
		ISNULL(stag.Comments,'') <> ISNULL(alert.Comments,'') OR ISNULL(alert.AlertRegisterStatusTypeRefEnumValueId, 0) <> ISNULL(enum.RefEnumValueId, 0))

	DELETE FROM dbo.StagingUpdateCommentAndStatus WHERE [GUID] = @InternalGuid

END
GO
