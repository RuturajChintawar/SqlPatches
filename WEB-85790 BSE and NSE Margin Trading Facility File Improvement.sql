GO
	ALTER PROCEDURE dbo.CoreClientTradingMargin_InsertFromStagingNseTradingMargin
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

		SELECT
			t.StagingNseTradingMarginId,
			t.RefInstrumentId,
			t.Isactive
		INTO #tempInstrumentData
		FROM(
				SELECT stage.StagingNseTradingMarginId,
					inst.RefInstrumentId,
					CASE WHEN inst.[Status] = 'A' THEN 1 ELSE 0 END Isactive,
					ROW_NUMBER() OVER(PARTITION BY stage.StagingNseTradingMarginId ORDER BY CASE WHEN inst.[Status] = 'A' THEN 1 ELSE 0 END DESC) RN
				FROM dbo.StagingNseTradingMargin stage
				INNER JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @NseSegmentId AND inst.Code = stage.Symbol AND inst.Series = stage.Series
				WHERE stage.[GUID]= @InternalGuid
			)t
		WHERE t.RN = 1

		DELETE stage FROM dbo.StagingNseTradingMargin stage 
			INNER JOIN #tempInstrumentData inst ON inst.StagingNseTradingMarginId = stage.StagingNseTradingMarginId AND inst.Isactive = 0

		UPDATE error
			SET error.ErrorMessage = error.ErrorMessage + ', Symbol'+ stage.Symbol COLLATE DATABASE_DEFAULT +' is not present with NSE_CASH Segment'  
		FROM dbo.StagingNseTradingMargin stage
		INNER JOIN #ErrorListTable error ON stage.StagingNseTradingMarginId = error.StagingNseTradingMarginId
		LEFT JOIN #tempInstrumentData inst ON inst.StagingNseTradingMarginId = error.StagingNseTradingMarginId
		WHERE stage.[GUID]= @InternalGuid AND stage.Symbol IS NOT NULL AND inst.StagingNseTradingMarginId IS NULL

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
				inst.RefInstrumentId,
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
			INNER JOIN #tempInstrumentData inst ON inst.StagingNseTradingMarginId = stage.StagingNseTradingMarginId AND inst.Isactive = 1
			LEFT JOIN dbo.CoreClientTradingMargin main ON stage.RefClientId = main.RefClientId AND inst.RefInstrumentId = main.RefInstrumentId AND stage.MarginDate = main.MarginDate 
			AND main.RefSegementId = @NseSegmentId AND stage.Quantity = main.Quantity AND stage.Amount = main.Amount
			WHERE stage.[GUID] = @InternalGuid AND main.CoreClientTradingMarginId IS NULL
		END

		DELETE FROM dbo.StagingNseTradingMargin WHERE [GUID] = @InternalGuid
	END
GO
GO
	ALTER TABLE dbo.StagingNseTradingMargin
	DROP COLUMN RefInstrumentId
GO
GO
	
	ALTER TABLE dbo.CoreClientTradingMargin
	DROP CONSTRAINT UQ_CoreClientTradingMargin

	ALTER TABLE dbo.CoreClientTradingMargin
	ADD CONSTRAINT UQ_CoreClientTradingMargin
	UNIQUE (RefClientId, RefInstrumentId, RefSegementId, MarginDate, FlagOfStock, Quantity, Amount)
GO
GO
	ALTER PROCEDURE dbo.CoreClientTradingMargin_InsertBseMarginFromStaging
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
	
		UPDATE stage
			SET stage.FlagOfStock = CASE stage.FlagOfStock
					WHEN 'C' THEN 'Collateral'
					WHEN 'F' THEN 'Funded'
				END
		FROM dbo.StagingBseTradingMargin stage
		WHERE stage.[GUID]= @InternalGuid 

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
				stage.FlagOfStock,
				stage.Quantity,
				stage.Amount*100000,
				stage.AddedBy,
				stage.AddedOn,
				stage.AddedBy,
				stage.AddedOn
			FROM dbo.StagingBseTradingMargin stage
			LEFT JOIN dbo.CoreClientTradingMargin main ON stage.RefClientId = main.RefClientId AND stage.RefInstrumentId = main.RefInstrumentId AND stage.MarginDate = main.MarginDate 
				AND main.RefSegementId = @BseSegmentId  AND stage.Quantity = main.Quantity AND stage.Amount = main.Amount AND main.FlagOfStock = stage.FlagOfStock
			WHERE stage.[GUID] = @InternalGuid AND main.CoreClientTradingMarginId IS NULL
			 
		END

		DELETE FROM dbo.StagingBseTradingMargin WHERE [GUID] = @InternalGuid
	END
GO
SELECT * FROM RefAmlreport  where code ='S82'