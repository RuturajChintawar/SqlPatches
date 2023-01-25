GO
	EXEC dbo.Sys_DropIfExists 'CoreBhavCopy_InsertNseFnoFromStaging_ValidateRefInstrument','P'
GO
	CREATE PROCEDURE dbo.CoreBhavCopy_InsertNseFnoFromStaging_ValidateRefInstrument
	(
		@Guid VARCHAR(40)
	)
	AS
	BEGIN
			DECLARE @GuidInternal varchar(40), @SegmentId INT

			SET @GuidInternal = @Guid
			SET @SegmentId = dbo.GetSegmentId('NSE_FNO')
	
			UPDATE stage
			SET PutCall = CASE OptionType
								WHEN 'CE' THEN 'C'
								WHEN 'CA' THEN 'C'
								WHEN 'PE' THEN 'P'
								WHEN 'PA' THEN 'P'
								ELSE NULL END,
					OptionStyle = CASE OptionType
									WHEN 'CE' THEN 'E'
									WHEN 'CA' THEN 'A'
									WHEN 'PE' THEN 'E'
									WHEN 'PA' THEN 'A'
									ELSE NULL END,
					RefInstrumentTypeId = map.RefInstrumentTypeId
			FROM dbo.StagingCoreNseFnoBhavCopy stage
			LEFT JOIN dbo.RefInstrumentType map ON stage.NseInstrumentType = map.InstrumentType
		
		

        
			DECLARE @CurrDate DATETIME
			SET @CurrDate = GETDATE()
                
                
					SELECT  @SegmentId as  SegmentId,
							inst.RefInstrumentId ,
							stage.[open] ,
							stage.high ,
							stage.low ,
							stage.[Close],
							stage.SettlePrice ,
							stage.Contracts ,
							stage.ValInLakhs * 100000  as ValInLakhs,
							stage.[TradeDate] ,
							stage.AddedBy ,
							stage.AddedOn ,
							stage.AddedBy as LastEditedBy,
							stage.AddedOn as EditedOn,
							stage.OpenInterest ,
							stage.ChangeInOpenInterest
							INTO #StagingCoreNseFnoBhavCopy
					FROM    dbo.StagingCoreNseFnoBhavCopy stage
							LEFT JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @SegmentId
															AND inst.Code = stage.Symbol
															AND inst.ExpiryDate = stage.ExpiryDate
															AND ISNULL(inst.PutCall,'' ) = ISNULL(stage.PutCall,'' )
															AND ISNULL(inst.OptionStyle, '') = ISNULL(stage.OptionStyle, '') 
															AND ISNULL(inst.StrikePrice, 0) = ISNULL(stage.StrikePrice, 0)
					WHERE stage.[GUID] = @GuidInternal
				
					IF EXISTS
					(
						SELECT TOP 1 1
						FROM #StagingCoreNseFnoBhavCopy
						WHERE RefInstrumentId IS NULL
					)
					BEGIN
						DELETE  FROM StagingCoreNseFnoBhavCopy WHERE [GUID] = @GuidInternal
						RAISERROR ('Kindly, merge new instrument file (Contract) before merging bhavcopy',11,1) WITH SETERROR
							 RETURN 50010;
					END
                
					UPDATE bhav
					SET bhav.[Open] = staging.[Open],
						bhav.High = staging.High,
						bhav.Low = staging.Low,
						bhav.[Close] = staging.[Close],
						bhav.[Last] = staging.SettlePrice,					
						bhav.NumberOfShares = staging.Contracts,
						bhav.NetTurnOver = staging.ValInLakhs,
						bhav.OpenInterest = staging.OpenInterest,
						bhav.ChangeInOpenInterest = staging.ChangeInOpenInterest,
						bhav.LastEditedBy = staging.AddedBy,
						bhav.EditedOn = staging.AddedOn
					FROM dbo.CoreBhavCopy bhav
					INNER JOIN #StagingCoreNseFnoBhavCopy staging ON bhav.[Date] = staging.TradeDate AND bhav.RefSegmentId = staging.SegmentId AND bhav.RefInstrumentId = staging.RefInstrumentId        
                        
					INSERT INTO dbo.CoreBhavCopy
					( RefSegmentId ,
					  RefInstrumentId ,
					  [Open] ,
					  High ,
					  Low ,
					  [Close] ,
					  [Last],
					  NumberOfShares ,
					  NetTurnOver ,
					  [Date],
					  AddedBy ,
					  AddedOn ,
					  LastEditedBy ,
					  EditedOn ,
					  OpenInterest ,
					  ChangeInOpenInterest
							
					)
					SELECT 
					stage.SegmentId ,
							stage.RefInstrumentId ,
							stage.[open] ,
							stage.high ,
							stage.low ,
							stage.[Close] ,
							stage.SettlePrice ,
							stage.Contracts ,
							stage.ValInLakhs,
							stage.[TradeDate] ,
							stage.AddedBy ,
							stage.AddedOn ,
							stage.LastEditedBy ,
							stage.EditedOn ,
							stage.OpenInterest ,
							stage.ChangeInOpenInterest
					FROM #StagingCoreNseFnoBhavCopy stage
					WHERE NOT EXISTS ( SELECT 1 FROM dbo.CoreBhavCopy c
										 WHERE RefSegmentId = @SegmentId
												AND c.RefInstrumentId = stage.RefInstrumentId
												AND c.[Date] = stage.TradeDate )
                
                
    
        

			DELETE  FROM dbo.StagingCoreNseFnoBhavCopy WHERE [GUID] = @GuidInternal
	END
GO