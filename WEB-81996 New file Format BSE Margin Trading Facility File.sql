--File:Tables:dbo:CoreClientTradingMargin:CREATE
--WEB- 81996-START RC
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
--WEB- 81996-END RC

--File:Tables:dbo:RefExemptPan:CREATE
--WEB- 81996-START RC
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
--WEB- 81996-END RC

--File:Tables:dbo:RefExemptPan:DML
--WEB- 81996-START RC
GO
	DECLARE @CurDate DATETIME
	SET @CurDate = GETDATE()
	INSERT INTO dbo.RefExemptPan(
		PAN,
		AddedOn,
		AddedBy,
		EditedOn,
		LastEditedBy
	)VALUES('TRANSMISIN',@CurDate,'System',@CurDate,'System'),
	('SIKKIMCATG',@CurDate,'System',@CurDate,'System'),
	('EXEMPTCATG',@CurDate,'System',@CurDate,'System')
GO
--WEB- 81996-END RC

--File:Tables:dbo:StagingBseTradingMargin:CREATE
--WEB-81996--RP--START--
GO
CREATE TABLE dbo.StagingBseTradingMargin
(
	StagingBseTradingMarginId INT IDENTITY(1,1) NOT NULL,
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
GO
--WEB-81996--RP--END--

--File:Tables:dbo:StagingNseTradingMargin:CREATE
--WEB- 81996-START RC
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
--WEB- 81996-END RC

--File:StoredProcedures:dbo:CoreClientTradingMargin_InsertFromStagingNseTradingMargin
--WEB- 81996-START RC
GO
	CREATE PROCEDURE dbo.CoreClientTradingMargin_InsertFromStagingNseTradingMargin
	(
		@GUID VARCHAR(40)
	)
	AS 
	BEGIN
		DECLARE @InternalGuid VARCHAR(40), @NseDatabaseId INT, @NseSegmentId INT ,@ErrorString VARCHAR(50),
			@InActiveAccountStatusId INT,@ClosedAccountStatusId INT

		SET @ErrorString='Error in Record at Line : '  
		SET @InternalGuid = @Guid  

		SELECT @NseSegmentId = dbo.Getsegmentid('NSE_CASH')   
		SELECT @NseDatabaseId = RefDatabaseId FROM dbo.RefSegmentEnum WHERE [Segment] = 'NSE_CASH'
		SELECT @InActiveAccountStatusId = st.RefClientAccountStatusId FROM dbo.RefClientAccountStatus st WHERE st.RefClientDatabaseEnumId =  @NseDatabaseId AND st.[Name] ='InActive'
		SELECT @ClosedAccountStatusId = st.RefClientAccountStatusId FROM dbo.RefClientAccountStatus st WHERE st.RefClientDatabaseEnumId =  @NseDatabaseId AND st.[Name] ='Closed'
		IF ( @NseSegmentId IS NULL )    
		BEGIN    
			RAISERROR ('Segment NSE_CASH not present',11,1) WITH seterror    
			RETURN 50010    
		END    

		SELECT 
			DISTINCT stage.PAN
		INTO #distinctPan
		FROM dbo.StagingNseTradingMargin stage
		WHERE stage.[GUID]= @InternalGuid
		
		SELECT
			dis.PAN
		INTO #normalPan
		FROM #distinctPan dis
		LEFT JOIN  dbo.RefExemptPan ref   ON dis.PAN = ref.PAN
		WHERE ref.RefExemptPanId IS NULL
		
		SELECT
		t.PAN,t.RefCLientId
		INTO #tempPanCLientMapping
		FROM 
			(SELECT 
				cli.PAN,
				ROW_NUMBER() OVER(PARTITION BY clI.PAN ORDER BY clI.AddedOn )rn,
				cli.RefClientId
			FROM #normalPan dis
			INNER JOIN dbo.RefClient cli ON cli.RefClientDatabaseEnumId = @NseDatabaseId AND 
					(	
						cli.RefClientAccountStatusId IS NULL 
						OR 
						cli.RefClientAccountStatusId NOT IN (@InActiveAccountStatusId,@ClosedAccountStatusId)
					)  
				  AND dis.PAN = cli.PAN
				  )t 
			  WHERE t.rn = 1

		UPDATE stage
		SET stage.RefClientId = t.RefClientId
		FROM dbo.StagingNseTradingMargin stage
		INNER JOIN #tempPanCLientMapping t ON t.PAN = stage.PAN



		SELECT 
			stag.StagingNseTradingMarginId, stag.PAN,stag.ClientName
		INTO #exemptData
		FROM dbo.StagingNseTradingMargin stag
		INNER JOIN dbo.RefExemptPan ref ON stag.PAN = ref.PAN

		IF(EXISTS(SELECT TOP 1 1 FROM #exemptData))
		BEGIN
			WITH exemptClientData AS
			(
				SELECT 
					exe.StagingNseTradingMarginId,
					ROW_NUMBER() OVER(PARTITION BY exe.StagingNseTradingMarginId ORDER BY cli.AddedOn )rn,
					cli.RefClientId
				FROM #exemptData exe
				INNER JOIN dbo.RefClient cli ON exe.PAN = cli.PAN AND exe.ClientName = cli.[Name]
			)

			UPDATE stag
			SET stag.RefClientId = exe.RefClientId
			FROM dbo.StagingNseTradingMargin stag
			INNER JOIN exemptClientData exe ON exe.rn = 1 AND exe.StagingNseTradingMarginId = stag.StagingNseTradingMarginId
		END

		UPDATE stage
		SET stage.RefInstrumentId = inst.RefInstrumentId 
		FROM dbo.StagingNseTradingMargin stage
		INNER JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @NseSegmentId AND inst.Code = stage.Symbol AND inst.Series = stage.Series AND inst.[Status] = 'A'
		WHERE stage.[GUID]= @InternalGuid

		CREATE TABLE #ErrorListTable    
		(    
			LineNumber INT,
			StagingNseTradingMarginId INT,
			ErrorMessage VARCHAR(MAX) DEFAULT '' COLLATE DATABASE_DEFAULT    
		)  
	
		INSERT INTO #ErrorListTable (StagingNseTradingMarginId, LineNumber)
		SELECT stage.StagingNseTradingMarginId, ROW_NUMBER() OVER(ORDER BY stage.StagingNseTradingMarginId) AS LineNumber
		FROM dbo.StagingNseTradingMargin stage
		WHERE stage.[GUID] = @InternalGuid

		UPDATE error
			SET error.ErrorMessage = error.ErrorMessage + ', Client with Pan '+ stage.PAN COLLATE DATABASE_DEFAULT +' not present in Database'  
		FROM dbo.StagingNseTradingMargin stage
		INNER JOIN #ErrorListTable error ON stage.StagingNseTradingMarginId = error.StagingNseTradingMarginId
		WHERE stage.[GUID]= @InternalGuid AND stage.PAN IS NOT NULL AND stage.RefClientId IS NULL

		UPDATE error
			SET error.ErrorMessage = error.ErrorMessage + ', Symbol'+ stage.Symbol COLLATE DATABASE_DEFAULT +' is not present with NSE_CASH Segment'  
		FROM dbo.StagingNseTradingMargin stage
		INNER JOIN #ErrorListTable error ON stage.StagingNseTradingMarginId = error.StagingNseTradingMarginId
		WHERE stage.[GUID]= @InternalGuid AND stage.Symbol IS NOT NULL AND stage.RefInstrumentId IS NULL

		IF EXISTS (SELECT TOP 1 1 FROM #ErrorListTable elt WHERE elt.ErrorMessage IS NOT NULL AND elt.ErrorMessage <> '') 
		BEGIN  
			SELECT @ErrorString + CONVERT(VARCHAR, elt.linenumber) COLLATE DATABASE_DEFAULT + ' ' + Stuff(elt.ErrorMessage,1,2,'') AS ErrorMessage  
			FROM #ErrorListTable elt  
			WHERE elt.ErrorMessage IS NOT NULL AND elt.ErrorMessage <> ''  
			ORDER BY elt.linenumber  
		END  
		ELSE 
		BEGIN 
			INSERT INTO dbo.CoreClientTradingMargin
			(
				RefClientId,
				RefInstrumentId,
				RefSegementId,
				MarginDate,
				QuantityBeginDay ,
				AmountBeginDay ,
				QuantityDuringDay ,
				AmountDuringDay ,
				QuantityLiquidated ,
				AmountLiquidated ,
				Quantity ,
				Amount ,
				AddedBy,
				AddedOn,
				LastEditedBy,
				EditedOn
			)
			SELECT 
				stage.RefClientId,
				stage.RefInstrumentId,
				@NseSegmentId,
				stage.MarginDate,
				stage.QuantityBeginDay,
				stage.AmountBeginDay,
				stage.QuantityDuringDay,
				stage.AmountDuringDay,
				stage.QuantityLiquidated,
				stage.AmountLiquidated,
				stage.Quantity,
				stage.Amount ,
				stage.AddedBy,
				stage.AddedOn,
				stage.AddedBy,
				stage.AddedOn
			FROM dbo.StagingNseTradingMargin stage
			LEFT JOIN dbo.CoreClientTradingMargin main ON stage.RefClientId = main.RefClientId AND stage.RefInstrumentId = main.RefInstrumentId AND stage.MarginDate = main.MarginDate
			AND main.RefSegementId = @NseSegmentId
			WHERE stage.[GUID] = @InternalGuid AND main.CoreClientTradingMarginId IS NULL
		END

		DELETE FROM dbo.StagingNseTradingMargin WHERE [GUID] = @InternalGuid
	END
GO
--WEB- 81996-END RC

--File:Tables:dbo:RefAmlFileType:DML
--WEB-81996--RP--START--
GO
EXEC [dbo].[RefAmlFileType_InsertIfNotExists] @FileTypeCode = 'AML' , @AmlFileTypeName = 'Margin_Trading_Facility', @WatchListSourceName = ''
GO
--WEB-81996--RP--END--

--File:StoredProcedures:dbo:CoreClientTradingMargin_InsertBseMarginFromStaging
--WEB-81996--RP--START--
GO
CREATE PROCEDURE dbo.CoreClientTradingMargin_InsertBseMarginFromStaging
(
	@GUID VARCHAR(40)
)
AS 
BEGIN
	DECLARE @InternalGuid VARCHAR(40), @BseDatabaseId INT, @BseSegmentId INT ,@ErrorString VARCHAR(50)
	SET @ErrorString='Error in Record at Line : '  
	SET @InternalGuid = @Guid  
	SELECT @BseSegmentId = dbo.Getsegmentid('BSE_CASH')   
	SELECT @BseDatabaseId = RefDatabaseId FROM dbo.RefSegmentEnum WHERE [Segment] = 'BSE_CASH' 

	IF ( @BseSegmentId IS NULL )    
	BEGIN    
		RAISERROR ('Segment BSE_CASH not present',11,1) WITH seterror    
		RETURN 50010    
	END    

	UPDATE stage
	SET stage.RefClientId = cli.RefClientId
	FROM dbo.StagingBseTradingMargin stage
	INNER JOIN dbo.RefClient cli ON cli.RefClientDatabaseEnumId = @BseDatabaseId  AND stage.ClientId = cli.ClientId 
	WHERE stage.[GUID]= @InternalGuid

	UPDATE stage
	SET stage.RefInstrumentId = inst.RefInstrumentId 
	FROM dbo.StagingBseTradingMargin stage
	INNER JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @BseSegmentId AND inst.Code = stage.ScripCode AND inst.[Status] = 'A'
	WHERE stage.[GUID]= @InternalGuid

	CREATE TABLE #ErrorListTable    
	(    
		LineNumber INT,
		StagingBseTradingMarginId INT,
		ErrorMessage VARCHAR(MAX) DEFAULT '' COLLATE DATABASE_DEFAULT    
	)  
	
	INSERT INTO #ErrorListTable (StagingBseTradingMarginId, LineNumber)
	SELECT stage.StagingBseTradingMarginId, ROW_NUMBER() OVER(ORDER BY stage.StagingBseTradingMarginId) AS LineNumber
	FROM dbo.StagingBseTradingMargin stage
	WHERE stage.[GUID] = @InternalGuid

	UPDATE error
		SET error.ErrorMessage = error.ErrorMessage + ', Client '+ stage.ClientId COLLATE DATABASE_DEFAULT +' not present in Database'  
	FROM dbo.StagingBseTradingMargin stage
	INNER JOIN #ErrorListTable error ON stage.StagingBseTradingMarginId = error.StagingBseTradingMarginId
	WHERE stage.[GUID]= @InternalGuid AND stage.ClientId IS NOT NULL AND stage.RefClientId IS NULL

	UPDATE error
		SET error.ErrorMessage = error.ErrorMessage + ', Scrip Code'+ stage.ScripCode COLLATE DATABASE_DEFAULT +' is not present with BSE_CASH Segment'  
	FROM dbo.StagingBseTradingMargin stage
	INNER JOIN #ErrorListTable error ON stage.StagingBseTradingMarginId = error.StagingBseTradingMarginId
	WHERE stage.[GUID]= @InternalGuid AND stage.ScripCode IS NOT NULL AND stage.RefInstrumentId IS NULL

	IF EXISTS (SELECT TOP 1 1 FROM #ErrorListTable elt WHERE elt.ErrorMessage IS NOT NULL AND elt.ErrorMessage <> '') 
	BEGIN  
		SELECT @ErrorString + CONVERT(VARCHAR, elt.linenumber) COLLATE DATABASE_DEFAULT + ' ' + Stuff(elt.ErrorMessage,1,2,'') AS ErrorMessage  
		FROM #ErrorListTable elt  
		WHERE elt.ErrorMessage IS NOT NULL AND elt.ErrorMessage <> ''  
		ORDER BY elt.linenumber  
	END  
	ELSE 
	BEGIN 
		INSERT INTO dbo.CoreClientTradingMargin
		(
			RefClientId,
			RefInstrumentId,
			RefSegementId,
			MarginDate,
			CategoryOfHolding,
			FlagOfStock,
			Quantity,
			Amount,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT 
			stage.RefClientId,
			stage.RefInstrumentId,
			@BseSegmentId,
			stage.MarginDate,
			CASE stage.CategoryOfHolding
				WHEN 'P' THEN 'Promoter'
				WHEN 'PG' THEN 'Promoter Group'
				WHEN 'NP' THEN 'Non-Promoter'
			END,
			CASE stage.FlagOfStock
				WHEN 'C' THEN 'Collateral'
				WHEN 'F' THEN 'Funded'
			END,
			stage.Quantity,
			stage.Amount*100000,
			stage.AddedBy,
			stage.AddedOn,
			stage.AddedBy,
			stage.AddedOn
		FROM dbo.StagingBseTradingMargin stage
		WHERE stage.[GUID] = @InternalGuid AND 
			  NOT EXISTS (  SELECT TOP 1 1 
							FROM dbo.CoreClientTradingMargin main 
							WHERE stage.RefClientId = main.RefClientId AND 
								  stage.RefInstrumentId = main.RefInstrumentId AND 
								  stage.MarginDate = main.MarginDate
						  )
	END

	DELETE FROM dbo.StagingBseTradingMargin WHERE [GUID]=@InternalGuid
END
GO
--WEB-81996--RP--END--

--File:StoredProcedures:dbo:CoreClientTradingMargin_GetMergeStatsforMarginFile
--WEB-81996--RP--START--
GO
CREATE PROCEDURE dbo.CoreClientTradingMargin_GetMergeStatsforMarginFile
(
    @SegmentId INT,
    @FromDate DATETIME,
    @ToDate DATETIME
)
AS 
BEGIN
	SELECT MarginDate AS [Date], COUNT(1) AS [Count]
	FROM dbo.CoreClientTradingMargin 
	WHERE RefSegementId = @SegmentId AND 
		  MarginDate BETWEEN @FromDate AND @ToDate
    GROUP BY MarginDate
END
GO
--WEB-81996--RP--END--