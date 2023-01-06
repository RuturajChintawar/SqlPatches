
GO
EXEC dbo.RefScreeningBox_InsertIfNotExists 'Mobile Number Match', 'A38', 'ActivityBox'
GO
GO
EXEC dbo.RefScreeningBox_InsertIfNotExists 'Email Id Match', 'A39', 'ActivityBox'
GO
GO
DECLARE @matchTyepid INT = dbo.GetEnumValueId('ScreeningAlertMatchType','C2')
Update dbo.RefScreeningBox 
SET MatchTypeRefEnumValueId = @matchTyepid
WHERE Code IN ('A38','A39')

GO


