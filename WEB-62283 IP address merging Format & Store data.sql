---------------RC WEB-62283 Starts-------
GO
CREATE TABLE dbo.RefClientTradeIPAddress
(
	RefClientTradeIPAddressId INT IDENTITY(1,1),
	RefClientId INT NOT NULL,
	TradeDate DATETIME NOT NULL,
	IPAddress VARCHAR(20) NOT NULL,
	DealingOfficeAddress VARCHAR(8000),
	
	AddedBy VARCHAR(50) NOT NULL,
	AddedOn DATETIME NOT NULL,
	LastEditedBy VARCHAR(50) NOT NULL,
	EditedOn DATETIME NOT NULL

)
GO
ALTER TABLE dbo.RefClientTradeIPAddress
	ADD CONSTRAINT PK_RefClientTradeIPAddress 
	PRIMARY KEY(RefClientTradeIPAddressId)
GO
ALTER TABLE dbo.RefClientTradeIPAddress
	ADD CONSTRAINT FK_RefClientTradeIPAddress_RefClientId 
	FOREIGN KEY(RefClientId) REFERENCES dbo.RefClient (RefClientId)
GO
ALTER TABLE dbo.RefClientTradeIPAddress
	ADD CONSTRAINT UQ_RefClientTradeIPAddress 
	UNIQUE (RefClientId, TradeDate)
GO
---------------RC WEB-62283 Ends---------

---------------RC WEB-62283 Starts-------
GO
CREATE TABLE dbo.StagingRefClientTradeIPAddress
(
	StagingRefClientTradeIPAddressId INT IDENTITY(1,1),
	RefClientId INT NOT NULL,
	TradeDate DATETIME NOT NULL,
	IPAddress VARCHAR(20) NOT NULL,
	DealingOfficeAddress VARCHAR(8000),

	AddedBy VARCHAR(50) NOT NULL,
	AddedOn DATETIME NOT NULL,
	[GUID] VARCHAR(1000)

)
GO
ALTER TABLE dbo.StagingRefClientTradeIPAddress
	ADD CONSTRAINT PK_StagingRefClientTradeIPAddress
	PRIMARY KEY(StagingRefClientTradeIPAddressId)
GO
---------------RC WEB-62283 Ends---------
select * from RefAmlFileType where NAme like '%OFAC%'
select * from RefEnumValue where RefEnumValueId=3104
select * from RefEnumType where RefEnumTypeId=252
----------------RC WEB-62283 Starts-------
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

---------------RC WEB-62283 Ends---------
select * from RefAmlFileType where name like'%APOC%'
---------------RC WEB-62283 Starts-------
GO
CREATE PROCEDURE dbo.RefClientTradeIPAddress_InsertFromStagingRefClientTradeIPAddress
(
	@GUID VARCHAR(1000)
)
AS
BEGIN
	
	SELECT 
		stage.*,
		main.RefClientId AS CheckRefClientId,
		main.TradeDate AS CheckTradeDate
	INTO #TempStaging
	FROM dbo.StagingRefClientTradeIPAddress stage
	LEFT JOIN dbo.RefClientTradeIPAddress main 
	ON 
	(
		stage.RefClientId = main.RefClientId
		AND stage.TradeDate = main.TradeDate
	)
	WHERE stage.[GUID] = @GUID


	INSERT INTO dbo.RefClientTradeIPAddress
	(
		RefClientId,
		TradeDate,
		IPAddress,
		DealingOfficeAddress,

		AddedBy,
		AddedOn,
		LastEditedBy,
		EditedOn
	)
	SELECT
		stage.RefClientId,
		stage.TradeDate,
		stage.IPAddress,
		stage.DealingOfficeAddress,

		stage.AddedBy,
		stage.AddedOn,
		stage.AddedBy AS LastEditedBy,
		stage.AddedOn AS EditedOn
	FROM #TempStaging stage
	WHERE 
		stage.CheckRefClientId IS NULL
		AND stage.CheckTradeDate IS NULL


	DELETE FROM #TempStaging
	WHERE
	(
		CheckRefClientId IS NULL
		AND CheckTradeDate IS NULL
	)
	

	UPDATE dbo.RefClientTradeIPAddress
	SET
		IPAddress = stage.IPAddress,
		DealingOfficeAddress = stage.DealingOfficeAddress,
		LastEditedBy = stage.AddedBy,
		EditedOn = stage.AddedOn
	FROM #TempStaging stage
	WHERE
	(
		RefClientTradeIPAddress.RefClientId = stage.CheckRefClientId
		AND RefClientTradeIPAddress.TradeDate = stage.CheckTradeDate
	)

	DELETE FROM dbo.StagingRefClientTradeIPAddress
	WHERE [GUID] = @GUID
END
GO
---------------RC WEB-62283 Ends---------