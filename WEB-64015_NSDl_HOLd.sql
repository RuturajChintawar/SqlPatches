--- WEb-64015--RC start
GO
CREATE PROCEDURE [dbo].[CoreClientHolding_InsertFromStaging_NSDL_HOLD] ( @Guid VARCHAR(40) )  
AS   
    BEGIN  
		DECLARE @SegmentId INT,@GuidInternal VARCHAR(500)  
		SET @GuidInternal=@Guid

		DECLARE @ErrorString VARCHAR(50)
		

		SET @ErrorString='Error in Record at Line : '
		CREATE TABLE #ErrorListTable
		(
		LineNumber INT,
		ErrorMessage VARCHAR(MAX) DEFAULT '' COLLATE DATABASE_DEFAULT
		)
		
		SELECT
		ROW_NUMBER() OVER(ORDER BY stage.StagingCoreClientHoldingId) AS LineNumber,
		stage.Isin,--
		stage.DpId,--
		stage.ClientId,--
		stage.DatabaseName
		INTO #TempStaging
		FROM dbo.StagingCoreClientHolding stage
		WHERE [GUID] = @Guid

		INSERT INTO #ErrorListTable
		(
			LineNumber
		)
		SELECT
			stage.LineNumber
		FROM #TempStaging stage

		SELECT
		ts.LineNumber,
		isin.RefIsinId
		INTO #ISINCHECK
		FROM #TempStaging ts
		LEFT JOIN dbo.RefIsin isin ON isin.[NAME]=ts.ISIN
		WHERE isin.RefIsinId IS NULL

		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', ISIN not Found'
		FROM #ISINCHECK ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber
		
		DROP TABLE #ISINCHECK

		IF EXISTS(SELECT TOP 1 1
		FROM #TempStaging ts
		LEFT JOIN dbo.RefDepository dp  ON ts.DpId = dp.DPId
		WHERE dp.RefDepositoryID IS NULL)
		BEGIN

		INSERT INTO #ErrorListTable
		VALUES(0, '  DPId not Found')

		END

        UPDATE dbo.StagingCoreClientHolding   
        SET  DpId = CONVERT( INT, SUBSTRING(ClientId,1,8))  
        WHERE   GUID = @Guid AND DatabaseName = 'CDSL'        
         
		 
		EXEC dbo.RefClientDematAccount_ImportFromClientDpDatabase 
		SELECT
		ts.LineNumber,
		ts.ClientId
		INTO #DematCheck
		FROM #TempStaging ts  
		LEFT JOIN  dbo.RefClientDematAccount demat ON demat.AccountId = ts.ClientId
        INNER JOIN dbo.RefClient client ON demat.RefClientId = client.RefClientId
        INNER JOIN dbo.RefClientDatabaseEnum db ON client.RefClientDatabaseEnumId = db.RefClientDatabaseEnumId AND ts.DatabaseName = db.DatabaseType
		WHERE demat.RefClientDematAccountId IS NULL 

		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', Demat account not found'
		FROM #DematCheck ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber
       
		DROP TABLE #DematCheck
       

		 IF (SELECT TOP 1 1 FROM #ErrorListTable elt WHERE elt.ErrorMessage IS NOT NULL AND elt.ErrorMessage <> '') = 1
			BEGIN

			SELECT 
			@ErrorString + CONVERT(VARCHAR, elt.LineNumber) + ' ' + STUFF(elt.ErrorMessage,1,2,'') AS ErrorMessage
			FROM #ErrorListTable elt
			WHERE elt.ErrorMessage IS NOT NULL AND elt.ErrorMessage <> ''
			ORDER BY elt.LineNumber
			
			
			END
		ELSE
		BEGIN

        INSERT  INTO dbo.CoreClientHolding  
                ( AsOfDate ,  
                  RefClientDematAccountId ,  
                  RefIsinId ,  
                  CurrentBalanceQuantity ,  
                  SafeKeepBalanceQuantity ,  
                  PledgedBalanceQuantity ,  
                  FreeBalanceQuantity ,  
                  LockinBalanceQuantity ,  
                  EarmarkedBalanceQuantity ,  
                  LendBalanceQuantity ,  
                  AVLBalanceQuantity ,  
                  BorrowedBalanceQuantity ,  
                  AddedBy ,  
                  AddedOn ,  
                  LastEditedBy ,  
                  EditedOn,  
                  DetailCount  
           )  
                SELECT  stage.AsOfDate ,  
                        client.RefClientDematAccountId ,  
                        isin.RefIsinId,  
                        SUM(stage.CurrentBalanceQuantity) ,  
                        SUM(stage.SafeKeepBalanceQuantity) ,  
                        SUM(stage.PledgedBalanceQuantity) ,  
                        SUM(stage.FreeBalanceQuantity) ,  
                        SUM(stage.LockinBalanceQuantity) ,  
                        SUM(stage.EarmarkedBalanceQuantity) ,  
						SUM(stage.LendBalanceQuantity) ,  
                        SUM(stage.AVLBalanceQuantity) ,  
                        SUM(stage.BorrowedBalanceQuantity) ,  
                        MAX(stage.AddedBy) ,  
                        MAX(stage.AddedOn) ,  
                        MAX(stage.AddedBy) ,  
                        MAX(stage.AddedOn),  
                        COUNT(1)  
                FROM    dbo.StagingCoreClientHolding stage  
                        LEFT JOIN (SELECT  db.DatabaseType ,
                                            demat.AccountId ,
                                            demat.RefClientDematAccountId,
                                            dp.DPId
                                    FROM    dbo.RefClientDematAccount demat
                                            INNER JOIN dbo.RefClient client ON demat.RefClientId = client.RefClientId
                                            INNER JOIN dbo.RefClientDatabaseEnum db ON client.RefClientDatabaseEnumId = db.RefClientDatabaseEnumId
                                            INNER JOIN dbo.RefDepository dp ON dp.RefDepositoryId = demat.RefDepositoryId) AS client ON stage.DatabaseName = client.DatabaseType  
                                                 AND client.AccountId = stage.ClientId and client.DPId = stage.Dpid  
                         LEFT JOIN dbo.RefIsin isin ON isin.Name = stage.Isin
						 LEFT JOIN  dbo.CoreClientHolding hold ON hold.AsOfDate=stage.AsOfDate AND hold.RefClientDematAccountId = client.RefClientDematAccountId AND hold.RefIsinId = isin.RefIsinId
					
				WHERE   stage.GUID = @Guid  AND hold.CoreClientHoldingId IS NULL
                GROUP BY stage.AsOfDate ,  
                        client.RefClientDematAccountId ,  
                        isin.RefIsinId 
						
				
		END
        DELETE  FROM dbo.StagingCoreClientHolding  WHERE   [GUID] = @Guid  
          
        EXEC dbo.CoreEttHolding_CopyFromClientHolding  
  
    END  
GO
--- WEb-64015--RC ends