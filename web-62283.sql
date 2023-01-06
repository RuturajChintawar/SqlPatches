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
