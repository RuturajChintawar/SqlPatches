--start-WEB-66636-RC
GO
DECLARE @WebFileTypeEnumValueId INT,@SourceId INT
SELECT @WebFileTypeEnumValueId=dbo.GetEnumValueId('WebFileType','Screening')

SET @SourceId=(SELECT sou.RefAmlWatchListSourceId FROM dbo.RefAmlWatchlistsource sou  WHERE sou.[Name]='OFAC Consolidated')

INSERT INTO dbo.RefAmlFileType
( 
	[Name],
	AddedBy ,
	AddedOn ,
	LastEditedBy ,
	EditedOn,
	WebFileTypeRefEnumValueId,
	RefAmlWatchListSourceId
	
)
VALUES  
( 
	'OFAC Consolidated' ,
	'System' , 
	GETDATE() , 
	'System' ,
	GETDATE(),
	@WebFileTypeEnumValueId,
	@SourceId
)
GO
--end-WEB-66636-RC