---------RC-----WEB-65177----start
GO
ALTER PROCEDURE  [dbo].[CoreDPTransactionChangeHistory_InsertDPTransactionFromStaging]  
( @Guid VARCHAR(500)  )
AS
BEGIN

		DECLARE @SegmentId INT,@GuidInternal VARCHAR(500)  
		SET @GuidInternal=@Guid
		
		SELECT  @SegmentId = dbo.GetSegmentId(SegmentName)  
		FROM    dbo.StagingDPTransactionChangeHistory  
		WHERE   [GUID] = @GuidInternal  

		IF ( @SegmentId IS NULL )   
		BEGIN  
			DELETE FROM dbo.StagingDPTransactionChangeHistory WHERE [GUID] = @GuidInternal  
			RAISERROR ('Segment not present',11,1) WITH SETERROR  
			RETURN 50010  
		END  
   
		DECLARE @SegmentDatabaseId INT  
		SELECT @SegmentDatabaseId = seg.RefDatabaseId FROM dbo.RefSegmentEnum seg WHERE seg.RefSegmentEnumId = @SegmentId  
	 
		DECLARE @refEnumTypeId INT  
		SELECT @refEnumTypeId=RefEnumTypeId from dbo.RefEnumType where Name='Channel Indicator'  
 
		UPDATE dbo.StagingDPTransactionChangeHistory SET ISIN='INE999999999' WHERE ISIN='' AND [GUID]=@GuidInternal
	
		
  
		UPDATE stage   
		SET  stage.ClientId = stage.OtherClientId,  
		stage.OtherClientId = stage.ClientId  
		FROM dbo.StagingDPTransactionChangeHistory stage 
		LEFT JOIN dbo.RefClient client ON CONVERT(varchar(200),stage.ClientId)  = client.ClientId
		WHERE [GUID] = @GuidInternal  
		AND stage.TransactionType IN ('910')  
		AND client.RefClientId IS NULL

		DECLARE @ErrorString VARCHAR(50)
		SET @ErrorString='Error in Record at Line : '

		
		CREATE TABLE #ErrorListTable
		(
		LineNumber INT,
		ErrorMessage VARCHAR(MAX) DEFAULT '' COLLATE DATABASE_DEFAULT
		)
		
		SELECT
		ROW_NUMBER() OVER(ORDER BY stage.StagingDPTransactionChangeHistoryId) AS LineNumber,
		stage.ISIN,
		stage.ClientId,
		stage.TransactionType
		INTO #TempStaging
		FROM dbo.StagingDPTransactionChangeHistory stage
		WHERE stage.[GUID] = @GuidInternal

		INSERT INTO #ErrorListTable
		(
			LineNumber
		)
		SELECT
			stage.LineNumber
		FROM #TempStaging stage


		SELECT
		ts.LineNumber,
		ts.ClientId
		INTO #CLIENTCHECK
		FROM #TempStaging ts
		LEFT JOIN dbo.RefClient client ON client.ClientId=CONVERT(varchar(200),ts.ClientId)
		WHERE client.RefClientId IS NULL

		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', Client Id '+ISNULL(CONVERT(varchar(200),ic.ClientId),'')+' not present'
		FROM #CLIENTCHECK ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber
		
		DROP TABLE #CLIENTCHECK

		SELECT
		ts.LineNumber,
		ts.TransactionType
		INTO #TRANSCHECK
		FROM #TempStaging ts
		LEFT JOIN dbo.RefDpTransactionType transtype ON  CONVERT(VARCHAR(20),ts.TransactionType) = transtype.NsdlCode
		WHERE transtype.RefDpTransactionTypeId IS NULL

		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', Transaction type '+CONVERT(VARCHAR(20),ic.TransactionType)+' not present'
		FROM #TRANSCHECK ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber
		
		DROP TABLE #TRANSCHECK
   
		SELECT
		ts.LineNumber,
		ts.ISIN
		INTO #ISINCHECK
		FROM #TempStaging ts
		LEFT JOIN dbo.RefIsin isin ON isin.[NAME]=ts.ISIN
		WHERE isin.RefIsinId IS NULL

		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', ISIN '+ic.ISIN+' not present in Isin Master' 
		FROM #ISINCHECK ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber
		
		DROP TABLE #ISINCHECK

		UPDATE dbo.StagingDPTransactionChangeHistory   SET Quantity = (Quantity/1000) WHERE [GUID]=@GuidInternal  

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
			 INSERT INTO dbo.CoreDPTransactionChangeHistory(  
			 RefSegmentId,  
			 RefDpTransactionTypeId,  
			 RefIsinId,  
			 RefClientId,  
			 ChannelIndicatorRefEnumValueId,  
			 BranchCode,  
			 BusinessPartnerInstructionId,  
			 OrderStatusFrom,  
			 OrderStatusTo,  
			 StatusChangeUser,  
			 CancellationStatusFrom,  
			 CancellationStatusTo,  
			 StatusChangeDateTime,  
			 OriginalBusinessPartnerInstructionId,  
			 Quantity,  
			 LockInReason,  
			 LockInReleaseDate,  
			 MarketType,  
			 SettlementNumber,  
			 ExecutionDate,  
			 OtherBranchCode,  
			 OtherDPId,  
			 OtherClientId,  
			 BeneficiaryAccountCategory,  
			 OtherClearingMemberBusinessPartnerId,  
			 OtherMarketType,  
			 OtherSettlementNumber,  
			 Remarks,  
			 SettledQuantity,  
			 RejectionReasonCode1,  
			 RejectionReasonCode2,  
			 RejectionReasonCode3,  
			 RejectionReasonCode4,  
			 MutualFundIndicator,  
			 FolioNumber,  
			 StatementOfAccountNumber,  
			 AmountIndicator,  
			 TargetClientName,  
			 PriorityFlag,  
			 BackOfficeReferenceDetails,  
			 SenderReferenceNo1,  
			 SenderReferenceNo2,  
			 FileReferenceId,  
			 DepositoryMemberOrderNumber,  
			 OriginalDepositoryMemberOrderNumber,  
			 AgreementNumber,  
			 ClosureType,  
			 ClosureDate,  
			 AutoCorporateActionRemarks,  
			 OtherDPCode,  
			 OtherClientCode,  
			 OtherSettlementDetails,  
			 FromMarketType,  
			 FromSettlementNumber,  
			 ToMarketType,  
			 ToSettlementNumber,  
			 IrreversibleReasonCode1,  
			 IrreversibleReasonCode2,  
			 IrreversibleReasonCode3,  
			 IrreversibleReasonCode4,  
			 TargetClearingCorporationClearingMemberId,  
			 FreezeLevel,  
			 FreezeReasonCode,  
			 AutoCorporateActionIndicator,  
			 SourceIndicator,  
			 FreezeDescriptionReason,  
			 ClosureQuantity,  
			 InvokedQuantity,  
			 PledgeClosureDate,  
			 PledgorClientId,  
			 PledgorClientName,  
			 SecondHolderPledgorClient,  
			 ThirdHolderPledgorClient,  
			 TransmissionReasons,  
			 DemiseIndicator,  
			 DISSerialNo,  
			 DISFormatFlag,  
			 DISTypeIndicator,  
			 DISIssuedHolder,  
			 POAId,  
			 LooseSlipFlag,  
			 NoOfInstructions,  
			 TransferReasonCode,  
			 Reason,  
			 Consideration,  
			 DirectPayFlag,  
			 MarginPledgeInstructionID,  
			 HoldReferenceNumber,  
			 ReleaseQuantity,  
			 HoldReleaseDate,  
			 SourceClientName,  
			 SecondHolderSourceClientName,  
			 ThirdHolderSourceClientName,  
			 CoolingPeriod,  
			 AddedBy,  
			 AddedOn,  
			 LastEditedBy,  
			 EditedOn)  
			 SELECT  
			  @SegmentId,  
			  transtype.RefDpTransactionTypeId,  
			  isin.RefIsinId,  
			  client.RefClientId,  
			  enumvalue.RefEnumValueId,  
			  stage.BranchCode,  
			  stage.BusinessPartnerInstructionId,  
			  stage.OrderStatusFrom,  
			  stage.OrderStatusTo,  
			  stage.StatusChangeUser,  
			  stage.CancellationStatusFrom,  
			  stage.CancellationStatusTo,  
			  stage.StatusChangeDateTime,  
			  stage.OriginalBusinessPartnerInstructionId,  
			  stage.Quantity AS Quantity,  
			  stage.LockInReason,  
			  stage.LockInReleaseDate,  
			  stage.MarketType,  
			  stage.SettlementNumber,  
			  stage.ExecutionDate,  
			  stage.OtherBranchCode,  
			  stage.OtherDPId,  
			  stage.OtherClientId,  
			  stage.BeneficiaryAccountCategory,  
			  stage.OtherClearingMemberBusinessPartnerId,  
			  stage.OtherMarketType,  
			  stage.OtherSettlementNumber,  
			  stage.Remarks,  
			  stage.SettledQuantity,  
			  stage.RejectionReasonCode1,  
			  stage.RejectionReasonCode2,  
			  stage.RejectionReasonCode3,  
			  stage.RejectionReasonCode4,  
			  stage.MutualFundIndicator,  
			  stage.FolioNumber,  
			  stage.StatementOfAccountNumber,  
			  stage.AmountIndicator,  
			  stage.TargetClientName,  
			  stage.PriorityFlag,  
			  stage.BackOfficeReferenceDetails,  
			  stage.SenderReferenceNo1,  
			  stage.SenderReferenceNo2,  
			  stage.FileReferenceId,  
			  stage.DepositoryMemberOrderNumber,  
			  stage.OriginalDepositoryMemberOrderNumber,  
			  stage.AgreementNumber,  
			  stage.ClosureType,  
			  stage.ClosureDate,  
			  stage.AutoCorporateActionRemarks,  
			  stage.OtherDPCode,  
			  stage.OtherClientCode,  
			  stage.OtherSettlementDetails,  
			  stage.FromMarketType,  
			  stage.FromSettlementNumber,  
			  stage.ToMarketType,  
			  stage.ToSettlementNumber,  
			  stage.IrreversibleReasonCode1,  
			  stage.IrreversibleReasonCode2,  
			  stage.IrreversibleReasonCode3,  
			  stage.IrreversibleReasonCode4,  
			  stage.TargetClearingCorporationClearingMemberId,  
			  stage.FreezeLevel,  
			  stage.FreezeReasonCode,  
			  stage.AutoCorporateActionIndicator,  
			  stage.SourceIndicator,  
			  stage.FreezeDescriptionReason,  
			  stage.ClosureQuantity,  
			  stage.InvokedQuantity,  
			  stage.PledgeClosureDate,  
			  stage.PledgorClientId,  
			  stage.PledgorClientName,  
			  stage.SecondHolderPledgorClient,  
			  stage.ThirdHolderPledgorClient,  
			  stage.TransmissionReasons,  
			  stage.DemiseIndicator,  
			  stage.DISSerialNo,  
			  stage.DISFormatFlag,  
			  stage.DISTypeIndicator,  
			  stage.DISIssuedHolder,  
			  stage.POAId,  
			  stage.LooseSlipFlag,  
			  stage.NoOfInstructions,  
			  stage.TransferReasonCode,  
			  stage.Reason,  
			  stage.Consideration,  
			  stage.DirectPayFlag,  
			  stage.MarginPledgeInstructionID,  
			  stage.HoldReferenceNumber,  
			  stage.ReleaseQuantity,  
			  stage.HoldReleaseDate,  
			  stage.SourceClientName,  
			  stage.SecondHolderSourceClientName,  
			  stage.ThirdHolderSourceClientName,  
			  stage.CoolingPeriod,  
			  stage.AddedBy,  
			  GETDATE() as AddedOn,  
			  stage.AddedBy as LastEditedBy,  
			  GETDATE() as EditedOn  
			 FROM  
			  dbo.StagingDPTransactionChangeHistory stage   
			  INNER JOIN dbo.RefClient client ON (CONVERT(VARCHAR(250),stage.ClientId) = client.ClientId AND client.RefClientDatabaseEnumId=@SegmentDatabaseId)   
			  INNER JOIN dbo.RefIsin isin ON (isin.[Name] = stage.ISIN)   
			  INNER JOIN dbo.RefEnumValue enumvalue ON (enumvalue.RefEnumTypeId = @refEnumTypeId AND stage.ChannelIndicator = CONVERT(INT,enumvalue.Code))  
			  LEFT JOIN dbo.RefDpTransactionType transtype ON CONVERT(varchar(100),stage.TransactionType) = transtype.NsdlCode   
			  LEFT JOIN dbo.CoreDPTransactionChangeHistory transact ON transact.RefSegmentId = @SegmentId AND  
			   transact.RefDpTransactionTypeId = ISNULL(transtype.RefDpTransactionTypeId,0) AND  
			   transact.RefClientId = client.RefClientId AND  
			   transact.Quantity = ISNULL(stage.Quantity,0.00) AND  
			   transact.RefIsinId = isin.RefIsinId AND  
			   transact.StatusChangeDateTime = stage.StatusChangeDateTime  
			 WHERE 
			  stage.[GUID] = @GuidInternal  AND transact.CoreDPTransactionChangeHistoryId IS NULL
 
		END
		DELETE FROM dbo.StagingDPTransactionChangeHistory WHERE [GUID]=@GuidInternal  
    
END 
GO
---------RC-----WEB-65177----end
---------RC-----WEB-65177----start
GO
ALTER PROCEDURE [dbo].[CoreClientHolding_InsertFromStaging_NSDL_HOLD] ( @Guid VARCHAR(40) )    
AS     
  BEGIN    
  DECLARE @SegmentId INT,@GuidInternal VARCHAR(500) ,@BadDpid VARCHAR(40)   
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
  ts.ISIN  
  INTO #ISINCHECK  
  FROM #TempStaging ts  
  LEFT JOIN dbo.RefIsin isin ON isin.[NAME]=ts.ISIN  
  WHERE isin.RefIsinId IS NULL  
  
	UPDATE #ErrorListTable  
	SET ErrorMessage = ErrorMessage + ', ISIN '+ ic.Isin +' not present in Isin Master'
	FROM #ISINCHECK ic  
	WHERE #ErrorListTable.LineNumber = ic.LineNumber  
    
	DROP TABLE #ISINCHECK  
  
	

	IF EXISTS(SELECT TOP 1 1
		FROM #TempStaging ts
		LEFT JOIN dbo.RefDepository dp  ON ts.DpId = dp.DPId
		WHERE dp.RefDepositoryID IS NULL)  
	BEGIN  
		SELECT @BadDpid=CONVERT(varchar(40),ts.DpId)  FROM #TempStaging ts  LEFT JOIN dbo.RefDepository dp  ON ts.DpId = dp.DPId  
		WHERE dp.RefDepositoryID IS NULL

		INSERT INTO #ErrorListTable  
		VALUES(0, '  DPId '+@BadDpid+' is incorrect.')  
  
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
	WHERE ISNULL(ts.ClientId,'')='' OR
	NOT EXISTS ( SELECT 1  
               FROM   dbo.RefClientDematAccount demat  
               INNER JOIN dbo.RefClient client ON demat.RefClientId = client.RefClientId  
               INNER JOIN dbo.RefClientDatabaseEnum db ON client.RefClientDatabaseEnumId = db.RefClientDatabaseEnumId  
               WHERE  ts.DatabaseName = db.DatabaseType  
               AND demat.AccountId = ts.ClientId )      
  
	UPDATE #ErrorListTable  
	SET ErrorMessage = ErrorMessage + ', Demat account not found for clientid '+ic.ClientId  
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
---------RC-----WEB-65177----end
s
---------RC-----WEB-65177----start
GO
ALTER PROCEDURE dbo.CoreClientHolding_InsertFromStagingForDPM4 (
	@Guid VARCHAR(40) 
)
AS 
BEGIN
	
	DECLARE @ErrorString VARCHAR(50), @CDSlId INT
	
	SET @ErrorString = 'Error at Line : '
	SELECT @CDSlId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL';

	WITH CTE AS (
		SELECT 
			StagingCoreClientHoldingId, 
			RowNumber, 
			ROW_NUMBER() OVER (ORDER BY StagingCoreClientHoldingId) AS RN 
		FROM dbo.StagingCoreClientHolding
		WHERE [GUID] = @Guid
	) UPDATE CTE SET RowNumber = RN

	UPDATE stage SET stage.RefIsinId = isin.RefIsinId 
	FROM dbo.StagingCoreClientHolding stage
	INNER JOIN dbo.RefIsin isin ON stage.Isin = isin.[Name]
	WHERE stage.[GUID] = @Guid

	UPDATE stage SET stage.RefClientDatabaseEnumId = db.RefClientDatabaseEnumId
	FROM dbo.StagingCoreClientHolding stage
	INNER JOIN dbo.RefClientDatabaseEnum db ON stage.DatabaseName = db.DatabaseType
	WHERE stage.[GUID] = @Guid

	UPDATE dbo.StagingCoreClientHolding 
	SET DpId = CONVERT(INT, SUBSTRING(ClientId, 1, 8))
	WHERE [GUID] = @Guid AND RefClientDatabaseEnumId = @CDSlId

	UPDATE stage SET stage.DpIdMatch = 1
	FROM dbo.StagingCoreClientHolding stage
	INNER JOIN dbo.RefDepository dp ON stage.DpId = dp.DPId
	WHERE stage.[GUID] = @Guid

	CREATE TABLE #ErrorList (LineNumber INT, Msg VARCHAR(MAX) COLLATE DATABASE_DEFAULT) 

	INSERT INTO #ErrorList (LineNumber, Msg)
	SELECT RowNumber, '' FROM dbo.StagingCoreClientHolding
	WHERE [GUID] = @Guid

	UPDATE err
	SET err.Msg = ', ClientId not present'
	FROM #ErrorList err
	INNER JOIN dbo.StagingCoreClientHolding stage ON err.LineNumber = stage.RowNumber
	WHERE stage.[GUID] = @Guid AND LTRIM(ISNULL(stage.ClientId, '')) = ''

	UPDATE err
	SET err.Msg = err.Msg + ', Isin ' + stage.Isin + ' not present in Isin Master'
	FROM #ErrorList err
	INNER JOIN dbo.StagingCoreClientHolding stage ON err.LineNumber = stage.RowNumber
	WHERE stage.[GUID] = @Guid AND stage.RefIsinId IS NULL

	UPDATE err
	SET err.Msg = err.Msg + ', DPId ' + ISNULL(CONVERT(VARCHAR(50), stage.DpId), '') COLLATE DATABASE_DEFAULT + ' not present in Depository Master'
	FROM #ErrorList err
	INNER JOIN dbo.StagingCoreClientHolding stage ON err.LineNumber = stage.RowNumber
	WHERE stage.[GUID] = @Guid AND (stage.DpIdMatch IS NULL OR stage.DpIdMatch = 0)

	UPDATE err
	SET err.Msg = err.Msg + ', DatabaseName ' + stage.DatabaseName + ' not present in Database Master'
	FROM #ErrorList err
	INNER JOIN dbo.StagingCoreClientHolding stage ON err.LineNumber = stage.RowNumber
	WHERE stage.[GUID] = @Guid AND stage.RefClientDatabaseEnumId IS NULL

	EXEC dbo.RefClientDematAccount_ImportFromClientDpDatabaseForCDSL

	UPDATE err
	SET err.Msg = err.Msg + ', Demat Account ' + stage.ClientId + ' not present in Database'
	FROM #ErrorList err
	INNER JOIN dbo.StagingCoreClientHolding stage ON err.LineNumber = stage.RowNumber
	LEFT JOIN dbo.RefClientDematAccount demat ON demat.AccountId = stage.ClientId
	LEFT JOIN dbo.RefClient client ON demat.RefClientId = client.RefClientId
	LEFT JOIN dbo.RefClientDatabaseEnum db ON client.RefClientDatabaseEnumId = db.RefClientDatabaseEnumId
	WHERE stage.[GUID] = @Guid AND db.RefClientDatabaseEnumId IS NULL

	IF EXISTS (SELECT 1 FROM #ErrorList WHERE Msg <> '')
	BEGIN
		SELECT 
			@ErrorString + CONVERT(VARCHAR, elt.LineNumber) COLLATE DATABASE_DEFAULT + ' - ' + STUFF(elt.Msg,1,2,'') + '.' AS ErrorMessage
		FROM #ErrorList elt
		WHERE elt.Msg <> ''
		ORDER BY elt.LineNumber

	END ELSE
	BEGIN

		DECLARE @AsOfDate DATETIME

		SET @AsOfDate = (SELECT TOP 1 dbo.GetDateWithoutTime(AsOfDate) FROM StagingCoreClientHolding WHERE [GUID] = @Guid)

		INSERT INTO dbo.CoreClientHolding(
			AsOfDate,
		    RefClientDematAccountId,
		    RefIsinId,
		    CurrentBalanceQuantity,
		    SafeKeepBalanceQuantity,
		    PledgedBalanceQuantity,
		    FreeBalanceQuantity,
		    LockinBalanceQuantity,
		    EarmarkedBalanceQuantity,
		    LendBalanceQuantity,
		    AVLBalanceQuantity,
		    BorrowedBalanceQuantity,
		    AddedBy,
		    AddedOn,
		    LastEditedBy,
		    EditedOn,
			PendingRematbalance,
			ISINFreezeForDebitOrCreditOrBoth,
			BOIDFreezeForDebitOrCreditOrBoth,
			BOISINFreezeForDebitOrCreditOrBoth,
		    DetailCount
		)SELECT  
			@AsOfDate,
		    demat.RefClientDematAccountId,
		    stage.RefIsinId,
		    SUM(stage.CurrentBalanceQuantity),
		    SUM(stage.SafeKeepBalanceQuantity),
		    SUM(stage.PledgedBalanceQuantity),
		    SUM(stage.FreeBalanceQuantity),
		    SUM(stage.LockinBalanceQuantity),
		    SUM(stage.EarmarkedBalanceQuantity),
		    SUM(stage.LendBalanceQuantity),
		    SUM(stage.AVLBalanceQuantity),
		    SUM(stage.BorrowedBalanceQuantity),
		    MAX(stage.AddedBy),
		    MAX(stage.AddedOn),
		    MAX(stage.AddedBy),
		    MAX(stage.AddedOn),
			SUM(stage.PendingRematbalance),
			MAX(stage.ISINFreezeForDebitOrCreditOrBoth),
			MAX(stage.BOIDFreezeForDebitOrCreditOrBoth),
			MAX(stage.BOISINFreezeForDebitOrCreditOrBoth),
		    COUNT(1)
		FROM StagingCoreClientHolding stage
		INNER JOIN dbo.RefClientDatabaseEnum db ON stage.RefClientDatabaseEnumId = db.RefClientDatabaseEnumId
		INNER JOIN dbo.RefClientDematAccount demat ON demat.AccountId = stage.ClientId
		INNER JOIN dbo.RefDepository dp ON dp.RefDepositoryId = demat.RefDepositoryId
			AND dp.DPId = stage.DpId
		LEFT JOIN dbo.CoreClientHolding h ON h.AsOfDate = @AsOfDate
			AND h.RefClientDematAccountId = demat.RefClientDematAccountId
			AND h.RefIsinId = stage.RefIsinId
		WHERE stage.[GUID] = @Guid AND h.CoreClientHoldingId IS NULL
		GROUP BY stage.AsOfDate, demat.RefClientDematAccountId, stage.RefIsinId
			
		DELETE FROM dbo.StagingCoreClientHolding WHERE [GUID] = @Guid
		
		EXEC CoreEttHolding_CopyFromClientHoldingForCDSL

	END

END
GO
---------RC-----WEB-65177----end