--WEB-75551-RC START
GO
CREATE TABLE dbo.CoreClientIncomeDetailsHistory(
	CoreClientIncomeDetailsHistoryId INT IDENTITY(1,1) NOT NULL,
	[Guid] VARCHAR(100),
	ReferenceNumber INT,
	CoreClientHistoryId BIGINT,
	IncomeGroup	 VARCHAR(100),
	RefIncomeGroupId INT,
	IncomeString VARCHAR(100),
	Income BIGINT,
	NetworthString VARCHAR(100),
	Networth DECIMAL(28,2),
	FromDateString VARCHAR(25),
	FromDate DATETIME,
	AddedBy VARCHAR(50) NOT NULL,
	AddedOn DATETIME NOT NULL,
	LastEditedBy VARCHAR(50) NOT NULL,
	EditedOn DATETIME NOT NULL
	)
GO
ALTER TABLE dbo.CoreClientIncomeDetailsHistory
ADD CONSTRAINT [PK_CoreClientIncomeDetailsHistory] PRIMARY KEY (CoreClientIncomeDetailsHistoryId);
GO
ALTER TABLE dbo.CoreClientIncomeDetailsHistory  ADD  CONSTRAINT [FK_CoreClientIncomeDetailsHistory_CoreClientHistoryId] FOREIGN KEY(CoreClientHistoryId)
REFERENCES dbo.CoreClientHistory (CoreClientHistoryId);
GO
ALTER TABLE dbo.CoreClientIncomeDetailsHistory  ADD  CONSTRAINT [FK_CoreClientIncomeDetailsHistory_RefIncomeGroupId] FOREIGN KEY(RefIncomeGroupId)
REFERENCES dbo.RefIncomeGroup (RefIncomeGroupId);
GO
--WEB-75551-RC END
--WEB-75551-RC START
GO
CREATE TABLE dbo.StagingClientIncomeDetails(
	StagingClientIncomeDetailsId INT IDENTITY(1,1) NOT NULL,
	StagingClientDetailId INT,
	[GUID]   VARCHAR(100) NOT NULL,
	ReferenceNumber INT NOT NULL,
	IncomeGroup	 VARCHAR(100),
	Income VARCHAR(100),
	Networth VARCHAR(100),
	FromDate VARCHAR(25),
	AddedBy VARCHAR(50) NOT NULL,
	AddedOn DATETIME NOT NULL

)

ALTER TABLE dbo.StagingClientIncomeDetails
ADD CONSTRAINT [PK_StagingClientIncomeDetails] PRIMARY KEY (StagingClientIncomeDetailsId);

ALTER TABLE dbo.StagingClientIncomeDetails  ADD  CONSTRAINT [FK_StagingClientIncomeDetails_StagingClientDetailId] FOREIGN KEY(StagingClientDetailId)
REFERENCES dbo.StagingClientDetail (StagingClientDetailId);
GO
--WEB-75551-RC END
corealert 