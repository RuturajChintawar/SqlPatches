GO
	DECLARE @RejectionCodeId INT
	SET @RejectionCodeId = (SELECT ref.RefRejectionCodeId FROM dbo.RefRejectionCode ref WHERE ref.[Code] = 'EC4122')

	DELETE  FROM dbo.LinkRefRejectionCodeRefRejectionTag   WHERE RefRejectionCodeId  = @RejectionCodeId

	DELETE  FROM dbo.LinkRefRejectionCodeRefRejectionValidator  WHERE RefRejectionCodeId  = @RejectionCodeId
	
	DELETE  FROM dbo.LinkCoreClientHistoryRefRejectionCode  WHERE RefRejectionCodeId  = @RejectionCodeId 
	
	DELETE  FROM dbo.RefRejectionCode   WHERE RefRejectionCodeId  = @RejectionCodeId

GO