GO
ALTER TABLE dbo.StagingCoreClientHolding ADD RefIsinId INT NULL,RefClientDatabaseEnumId INT NULL
GO
GO
ALTER TABLE dbo.StagingCoreClientHolding ADD RefClientId INT NULL
GO
select * from StagingCoreClientHolding where DpId<>'300757'[GUID]='0e63d6e8-9f06-47c1-b0e3-caee4694456c'
select * from CoreClientHolding where AddedBy='d'
exec CoreClientHolding_InsertFromStaging '256e7bdc-b978-410e-a6cc-233cdb615cc4'
sp_whoisactive
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

GO
ALTER PROCEDURE [dbo].[CoreClientHolding_InsertFromStaging] ( @Guid VARCHAR(40) )  
AS   
    BEGIN  
      
		EXEC RefClientDematAccount_ImportFromClientDpDatabase  

		UPDATE stage
		SET stage.RefClientDatabaseEnumId= ref.RefClientDatabaseEnumId,
		stage.RefClientId=client.RefClientId,
		stage.RefIsinId=isin.RefIsinId
		FROM dbo.StagingCoreClientHolding stage
		LEFT JOIN dbo.RefClientDatabaseEnum ref ON ref.DatabaseType=stage.DatabaseName
		LEFT JOIN dbo.RefIsin isin ON isin.[NAME]=stage.ISIN
		LEFT JOIN dbo.RefClient client ON client.RefClientDatabaseEnumId=ref.RefClientDatabaseEnumId AND client.ClientId=stage.ClientId AND client.DpId=stage.DpId
		WHERE stage.[GUID]=@Guid

		
		DECLARE @ErrorString VARCHAR(50)
		

		SET @ErrorString='Error in Record at Line : '
		CREATE TABLE #ErrorListTable
		(
		LineNumber INT,
		ErrorMessage VARCHAR(MAX) DEFAULT '' COLLATE DATABASE_DEFAULT
		)
		
		SELECT
		ROW_NUMBER() OVER(ORDER BY stage.StagingCoreClientHoldingId) AS LineNumber,
		stage.Isin,
		stage.DpId,
		stage.ClientId,
		stage.DatabaseName,
		stage.RefIsinId,
		stage.RefClientId,
		stage.RefClientDatabaseEnumId
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
		ts.RefIsinId
		INTO #ISINCHECK
		FROM #TempStaging ts
		WHERE ts.RefIsinId IS NULL

		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', ISIN not Found'
		FROM #ISINCHECK ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber
		
		DROP TABLE #ISINCHECK

		SELECT
		ts.LineNumber,
		ts.DpId,
		dp.RefDepositoryId
		INTO #DPIdCHECK
		FROM #TempStaging ts
		LEFT JOIN dbo.RefDepository dp  ON ts.DpId = dp.DPId
		WHERE dp.RefDepositoryID IS NULL

		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', DPId not Found'
		FROM #DPIdCHECK ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber

		DROP TABLE #DPIdCHECK

		SELECT
		ts.LineNumber,
		ts.ClientId
		INTO #DematCheck
		FROM #TempStaging ts
		LEFT JOIN  dbo.RefClientDematAccount demat ON demat.RefClientId = ts.RefClientId  
		WHERE demat.RefClientDematAccountId is null
		--NOT EXISTS ( SELECT 1  
  --  FROM   dbo.RefClientDematAccount demat  
  --                                      INNER JOIN dbo.RefClient client ON demat.RefClientId = client.RefClientId  
  --                                      INNER JOIN dbo.RefClientDatabaseEnum db ON client.RefClientDatabaseEnumId = db.RefClientDatabaseEnumId  
  --                               WHERE  ts.DatabaseName = db.DatabaseType  
  --                                      AND demat.AccountId = ts.ClientId )
		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', Demat account not found'
		FROM #DematCheck ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber
       
		DROP TABLE #DematCheck
          
        UPDATE dbo.StagingCoreClientHolding   
        SET  DpId = CONVERT( INT, SUBSTRING(ClientId,1,8))  
        WHERE   GUID = @Guid AND DatabaseName = 'CDSL'        
         
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

		SELECT  db.DatabaseType ,   
		demat.AccountId ,  
        demat.RefClientDematAccountId,  
        dp.DPId 
		INTO #ClientInfo
		FROM dbo.StagingCoreClientHolding stage
		INNER JOIN 	dbo.RefClientDematAccount demat  ON demat.RefClientId=stage.RefClientId
		INNER JOIN dbo.RefClientDatabaseEnum db ON db.RefClientDatabaseEnumId = stage.RefClientDatabaseEnumId  
        INNER JOIN dbo.RefDepository dp ON dp.RefDepositoryId = demat.RefDepositoryId

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
                        stage.RefIsinId,  
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
                FROM    StagingCoreClientHolding stage  
                        LEFT JOIN #ClientInfo AS client ON stage.DatabaseName = client.DatabaseType  
                                                 AND client.AccountId = stage.ClientId and client.DPId = stage.Dpid  
                          
                WHERE   stage.GUID = @Guid  
                        AND NOT EXISTS ( SELECT 1  
                                         FROM   dbo.CoreClientHolding h  
                                         WHERE  h.AsOfDate = stage.AsOfDate  
                                                AND h.RefClientDematAccountId = client.RefClientDematAccountId  
                                                AND h.RefIsinId = stage.RefIsinId)  
                GROUP BY stage.AsOfDate ,  
                        client.RefClientDematAccountId ,  
                        stage.RefIsinId 
						
				DROP Table #ClientInfo
		END
        --DELETE  FROM dbo.StagingCoreClientHolding  WHERE   [GUID] = @Guid  
          
        EXEC CoreEttHolding_CopyFromClientHolding  
  
    END  
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[CoreClientHolding_InsertFromStaging] ( @Guid VARCHAR(40) )
AS 
    BEGIN
    
		EXEC RefClientDematAccount_ImportFromClientDpDatabase
    
        DECLARE @BadIsins VARCHAR(8000)
        SET @BadIsins = ''
        SELECT  @BadIsins = stage.Isin 
        FROM    dbo.StagingCoreClientHolding stage
        WHERE   stage.GUID = @Guid
                AND NOT EXISTS ( SELECT 1
                                 FROM   dbo.RefIsin isin
                                 WHERE  stage.Isin = isin.Name )
        IF ( @BadIsins <> '') 
            BEGIN
				DELETE  FROM dbo.StagingCoreClientHolding WHERE   [GUID] = @Guid
                RAISERROR ('Isin %s not present in Isin Master. Please merge the latest ISIN Master',11,1,@BadIsins) WITH SETERROR
                RETURN 50010
            END
		
        
        DECLARE @BadDpId VARCHAR(8000)
        SET		@BadDpId = ''
        SELECT  @BadDpId = stage.DpId 
        FROM    dbo.StagingCoreClientHolding stage
        WHERE   stage.GUID = @Guid
                AND NOT EXISTS ( SELECT 1
                                 FROM   dbo.RefDepository dp
                                 WHERE  stage.DpId = dp.DPId )
        IF ( @BadDpId <> '') 
            BEGIN
				DELETE  FROM dbo.StagingCoreClientHolding WHERE   [GUID] = @Guid
                RAISERROR ('DPId %s not present in Depository Master. Please merge the latest Depository Master',11,1,@BadDpId) WITH SETERROR
                RETURN 50010
            END
        
        
        DECLARE @BadBoIds VARCHAR(8000)
        SET @BadBoIds = ''
        SELECT  @BadBoIds = stage.ClientId 
        FROM    dbo.StagingCoreClientHolding stage
        WHERE   stage.GUID = @Guid
                AND NOT EXISTS ( SELECT 1
                                 FROM   dbo.RefClientDematAccount demat
                                        INNER JOIN dbo.RefClient client ON demat.RefClientId = client.RefClientId
                                        INNER JOIN dbo.RefClientDatabaseEnum db ON client.RefClientDatabaseEnumId = db.RefClientDatabaseEnumId
                                 WHERE  stage.DatabaseName = db.DatabaseType
                                        AND demat.AccountId = stage.ClientId )
		
        IF ( @BadBoIds <> '' ) 
            BEGIN
				DELETE  FROM dbo.StagingCoreClientHolding WHERE   [GUID] = @Guid
                RAISERROR ('Demat Account %s not present in Database. Please merge the latest Client Master',11,1,@BadBoIds) WITH SETERROR
                RETURN 50010
            END
        
        UPDATE	dbo.StagingCoreClientHolding 
        SET		DpId = CONVERT( INT, SUBSTRING(ClientId,1,8))
        WHERE   GUID = @Guid AND DatabaseName = 'CDSL'      
        
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
                        isin.RefIsinId ,
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
                FROM    StagingCoreClientHolding stage
                        LEFT JOIN ( SELECT  db.DatabaseType ,
                                            demat.AccountId ,
                                            demat.RefClientDematAccountId,
                                            dp.DPId
                                    FROM    dbo.RefClientDematAccount demat
                                            INNER JOIN dbo.RefClient client ON demat.RefClientId = client.RefClientId
                                            INNER JOIN dbo.RefClientDatabaseEnum db ON client.RefClientDatabaseEnumId = db.RefClientDatabaseEnumId
                                            INNER JOIN dbo.RefDepository dp ON dp.RefDepositoryId = demat.RefDepositoryId
                                  ) AS client ON stage.DatabaseName = client.DatabaseType
                                                 AND client.AccountId = stage.ClientId and client.DPId = stage.Dpid
                        LEFT JOIN dbo.RefIsin isin ON isin.Name = stage.Isin
                WHERE   stage.GUID = @Guid
                        AND NOT EXISTS ( SELECT 1
                                         FROM   dbo.CoreClientHolding h
                                         WHERE  h.AsOfDate = stage.AsOfDate
                                                AND h.RefClientDematAccountId = client.RefClientDematAccountId
                                                AND h.RefIsinId = isin.RefIsinId )
                GROUP BY stage.AsOfDate ,
                        client.RefClientDematAccountId ,
                        isin.RefIsinId
		
       -- DELETE  FROM dbo.StagingCoreClientHolding
       -- WHERE   [GUID] = @Guid
        
        EXEC CoreEttHolding_CopyFromClientHolding

    END
GO
select * from RefDepository where DPId= '303036'
'552214'
sp_whoisactive
select * from StagingCoreClientHolding where AddedBy='d'
  

SELECT  db.DatabaseType ,  demat.AccountId , demat.RefClientDematAccountId, dp.DPId
                                    FROM    dbo.RefClientDematAccount demat
                                            INNER JOIN dbo.RefClient client ON demat.RefClientId = client.RefClientId
                                            INNER JOIN dbo.RefClientDatabaseEnum db ON client.RefClientDatabaseEnumId = db.RefClientDatabaseEnumId
                                            INNER JOIN dbo.RefDepository dp ON dp.RefDepositoryId = demat.RefDepositoryId
where demat.AccountId ='74516984' and db.DatabaseType='NSDL'
select dpid,* from refclient where ClientId='10035288'
select 
sp_whoisactive

SELECT  db.DatabaseType ,
                                            demat.AccountId ,
                                            demat.RefClientDematAccountId,
                                            dp.DPId
                                    FROM    dbo.RefClientDematAccount demat
                                            INNER JOIN dbo.RefClient client ON demat.RefClientId = client.RefClientId
                                            INNER JOIN dbo.RefClientDatabaseEnum db ON client.RefClientDatabaseEnumId = db.RefClientDatabaseEnumId
                                            INNER JOIN dbo.RefDepository dp ON dp.RefDepositoryId = demat.RefDepositoryId

											RefClientDematAccount_ImportFromClientDpDatabase