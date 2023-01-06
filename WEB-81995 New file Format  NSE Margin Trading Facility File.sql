--WEB-81995-START RC
GO
	CREATE TABLE dbo.CoreClientTradingMargin(

		CoreClientTradingMarginId BIGINT IDENTITY(1,1) NOT NULL,

		RefClientId INT NOT NULL,
		RefInstrumentId INT NOT NULL,
		RefSegementId INT NOT NULL,
		MarginDate DATETIME NOT NULL,

		CategoryOfHolding VARCHAR(50),
		FlagOfStock VARCHAR(50),
		QuantityBeginDay BIGINT,
		AmountBeginDay DECIMAL (28,6),
		QuantityDuringDay BIGINT,
		AmountDuringDay DECIMAL (28,6),
		QuantityLiquidated BIGINT,
		AmountLiquidated DECIMAL (28,6),
		Quantity BIGINT,
		Amount DECIMAL (28,6),

	
		AddedBy VARCHAR(50) NOT NULL,
		AddedOn DATETIME NOT NULL,
		LastEditedBy VARCHAR(50) NOT NULL,
		EditedOn DATETIME NOT NULL
	)
	ALTER TABLE dbo.CoreClientTradingMargin
	ADD CONSTRAINT [PK_CoreClientTradingMargin] 
	PRIMARY KEY (CoreClientTradingMarginId);

	ALTER TABLE dbo.CoreClientTradingMargin
	ADD CONSTRAINT FK_CoreClientTradingMargin_RefClientId 
	FOREIGN KEY(RefClientId) REFERENCES dbo.RefClient (RefClientId)

	ALTER TABLE dbo.CoreClientTradingMargin
	ADD CONSTRAINT FK_CoreClientTradingMargin_RefInstrumentId 
	FOREIGN KEY(RefInstrumentId) REFERENCES dbo.RefInstrument (RefInstrumentId)

	ALTER TABLE dbo.CoreClientTradingMargin
	ADD CONSTRAINT FK_CoreClientTradingMargin_RefSegementId 
	FOREIGN KEY(RefSegementId) REFERENCES dbo.RefSegmentEnum (RefSegmentEnumId)
	
	ALTER TABLE dbo.CoreClientTradingMargin
	ADD CONSTRAINT UQ_CoreClientTradingMargin
	UNIQUE (RefClientId, RefInstrumentId, RefSegementId, MarginDate)

GO
--WEB-81995-END RC
--WEB-81995-START RC
GO
	CREATE TABLE dbo.RefExemptPan(

		RefExemptPanId INT IDENTITY(1,1) NOT NULL,
		PAN VARCHAR(20) NOT NULL,
		AddedBy VARCHAR(50) NOT NULL,
		AddedOn DATETIME NOT NULL,
		LastEditedBy VARCHAR(50) NOT NULL,
		EditedOn DATETIME NOT NULL
	)
	ALTER TABLE dbo.RefExemptPan
	ADD CONSTRAINT [PK_RefExemptPan] 
	PRIMARY KEY (RefExemptPanId);
GO
--WEB-81995-END RC
--WEB-81996-START RC
GO
	CREATE TABLE dbo.StagingBseTradingMargin
	(
		StagingBseTradingMarginId BIGINT IDENTITY(1,1) NOT NULL,

		RefClientId INT,
		ClientId VARCHAR(200),
		RefInstrumentId INT,

		ScripCode VARCHAR(50),
		MarginDate DATETIME,
		CategoryOfHolding VARCHAR(10),
		FlagOfStock VARCHAR(10),

		Quantity BIGINT,
		Amount DECIMAL(28,6),

		[GUID] VARCHAR(40),
		AddedBy VARCHAR(50) NOT NULL,
		AddedOn DATETIME NOT NULL
	)

		ALTER TABLE dbo.StagingBseTradingMargin
		ADD CONSTRAINT [PK_StagingBseTradingMargin] 
		PRIMARY KEY (StagingBseTradingMarginId);
GO
--WEB-81996-END RC
--WEB-81995-START RC
GO
	CREATE TABLE dbo.StagingNseTradingMargin
	(
		StagingNseTradingMarginId BIGINT IDENTITY(1,1) NOT NULL,

		RefClientId INT,
		RefInstrumentId INT,
		PAN VARCHAR(20),
		ClientName VARCHAR(200),
		Symbol VARCHAR(50),
		Series VARCHAR(50),
		MarginDate DATETIME,
		QuantityBeginDay BIGINT,
		AmountBeginDay DECIMAL (28,6),
		QuantityDuringDay BIGINT,
		AmountDuringDay DECIMAL (28,6),
		QuantityLiquidated BIGINT,
		AmountLiquidated DECIMAL (28,6),
		Quantity BIGINT,
		Amount DECIMAL (28,6),

		[GUID] VARCHAR(40),
		AddedBy VARCHAR(50) NOT NULL,
		AddedOn DATETIME NOT NULL

	)

	ALTER TABLE dbo.StagingNseTradingMargin
	ADD CONSTRAINT [PK_StagingNseTradingMargin] 
	PRIMARY KEY (StagingNseTradingMarginId);
GO
--WEB-81995-END RC