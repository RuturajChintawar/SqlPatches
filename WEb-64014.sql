exec CoreDPTransactionChangeHistory_InsertDPTransactionFromStaging 'a023354b-79ce-473f-a690-3e500a7ede3b'
select * from StagingDPTransactionChangeHistory where AddedBy='d'
select * from RefClient where ClientId='10407737'
delete StagingDPTransactionChangeHistory where [GUID]='d29c008a-03d2-4e67-a9b2-8543d515bd8d'
GO
ALTER PROCEDURE  [dbo].[CoreDPTransactionChangeHistory_InsertDPTransactionFromStaging]  
( 

@Guid VARCHAR(500)  )
AS
BEGIN


  
		DECLARE @SegmentId INT  
		SELECT  @SegmentId = dbo.GetSegmentId(SegmentName)  
		FROM    dbo.StagingDPTransactionChangeHistory  
		WHERE   [GUID] = @Guid  
		--IF ( @SegmentId IS NULL )   
		--BEGIN  
		--	DELETE FROM dbo.StagingDPTransactionChangeHistory WHERE [GUID] = @Guid  
		--	RAISERROR ('Segment not present',11,1) WITH SETERROR  
		--	RETURN 50010  
		--END  
   
		DECLARE @SegmentDatabaseId INT  
		SELECT @SegmentDatabaseId = RefDatabaseId FROM dbo.RefSegmentEnum WHERE RefSegmentEnumId = @SegmentId  
	 
		DECLARE @refEnumTypeId INT  
		SELECT @refEnumTypeId=RefEnumTypeId from dbo.RefEnumType where Name='Channel Indicator'  
 
		UPDATE dbo.StagingDPTransactionChangeHistory SET ISIN='INE999999999' WHERE ISIN='' AND [GUID]=@Guid
	
		
  
		UPDATE stage   
		SET  stage.ClientId = stage.OtherClientId,  
		stage.OtherClientId = stage.ClientId  
		FROM dbo.StagingDPTransactionChangeHistory stage 
		LEFT JOIN dbo.RefClient client ON CAST(stage.ClientId AS varchar(200))  = client.ClientId
		WHERE [GUID] = @Guid  
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
		WHERE stage.[GUID] = @Guid

		INSERT INTO #ErrorListTable
		(
			LineNumber
		)
		SELECT
			stage.LineNumber
		FROM #TempStaging stage


		SELECT
		ts.LineNumber,
		client.RefClientId
		INTO #CLIENTCHECK
		FROM #TempStaging ts
		LEFT JOIN dbo.RefClient client ON client.ClientId=CAST(ts.ClientId AS varchar(200))
		WHERE client.RefClientId IS NULL

		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', CLient not Found'
		FROM #CLIENTCHECK ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber
		
		--DROP TABLE #CLIENTCHECK

		SELECT
		ts.LineNumber,
		ts.TransactionType
		INTO #TRANSCHECK
		FROM #TempStaging ts
		LEFT JOIN dbo.RefDpTransactionType transtype ON  CAST(ts.TransactionType AS VARCHAR) = transtype.NsdlCode
		WHERE transtype.RefDpTransactionTypeId IS NULL

		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', Transaction type not Found'
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
		SET ErrorMessage = ErrorMessage + ', ISIN not Found'
		FROM #ISINCHECK ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber
		
		DROP TABLE #ISINCHECK

		Update dbo.StagingDPTransactionChangeHistory   SET Quantity = (Quantity/1000) WHERE [GUID]=@Guid  

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
  stage.[GUID] = @Guid  AND transact.CoreDPTransactionChangeHistoryId IS NULL
 
 END
 
 DELETE FROM dbo.StagingDPTransactionChangeHistory WHERE [GUID]=@Guid  
    
END 
GO
select * from #ErrorListTable
select * from dbo.CoreDPTransactionChangeHistory where AddedBy='d'
GO
ALTER PROCEDURE  [dbo].[CoreDPTransactionChangeHistory_InsertDPTransactionFromStaging]  
(  
@Guid VARCHAR(500)  
)  
AS  
BEGIN  
  
 DECLARE @SegmentId INT  
    SELECT  @SegmentId = dbo.GetSegmentId(SegmentName)  
    FROM    dbo.StagingDPTransactionChangeHistory  
    WHERE   [GUID] = @Guid  
    IF ( @SegmentId IS NULL )   
    BEGIN  
        DELETE FROM dbo.StagingDPTransactionChangeHistory
    END   WHERE [GUID] = @Guid  
        RAISERROR ('Segment not present',11,1) WITH SETERROR  
        RETURN 50010  
   
 DECLARE @SegmentDatabaseId INT  
    SELECT @SegmentDatabaseId = RefDatabaseId FROM dbo.RefSegmentEnum WHERE RefSegmentEnumId = @SegmentId  
  
 UPDATE stage   
 SET  ClientId = OtherClientId,  
   OtherClientId = ClientId  
  FROM dbo.StagingDPTransactionChangeHistory stage   
 WHERE [GUID] = @Guid  
   AND stage.TransactionType IN ('910')  
   AND   
   NOT EXISTS (  
      SELECT 1   
      FROM dbo.RefClient client   
      WHERE CAST(stage.ClientId AS varchar(200))  = client.ClientId  
      )  
   
 DECLARE @BadClient VARCHAR(500)  
    SELECT @BadClient = CAST(stage.ClientId AS VARCHAR) FROM dbo.StagingDPTransactionChangeHistory stage WHERE NOT EXISTS  
    (  
        SELECT 1 FROM dbo.RefClient client  
        WHERE CAST(stage.ClientId AS VARCHAR) = client.ClientId  
    )  
    AND stage.[GUID] = @Guid      
    IF (@BadClient IS NOT NULL)  
    BEGIN  
        DELETE FROM dbo.StagingDPTransactionChangeHistory WHERE [GUID] = @Guid  
        RAISERROR ('Client %s not present in Database',11,1,@BadClient) with SETERROR  
        RETURN 50010  
    END  
   
 DECLARE @refEnumTypeId INT  
 SELECT @refEnumTypeId=RefEnumTypeId from dbo.RefEnumType where Name='Channel Indicator'  
   
 DECLARE @BadTransactionType VARCHAR(500)  
    SELECT @BadTransactionType = CAST(stage.TransactionType AS VARCHAR) FROM dbo.StagingDPTransactionChangeHistory stage  
    WHERE stage.TransactionType IS NOT NULL AND NOT EXISTS   
    (  
  SELECT 1 FROM RefDpTransactionType transtype  
  WHERE CAST(stage.TransactionType AS VARCHAR) = transtype.NsdlCode  
 )  
 AND stage.[GUID] = @Guid   
    IF (@BadTransactionType IS NOT NULL)  
    BEGIN  
        DELETE FROM dbo.StagingDPTransactionChangeHistory WHERE [GUID] = @Guid  
        RAISERROR ('TransactionType = %s not present in Database',11,1,@BadTransactionType) with SETERROR  
        RETURN 50010  
    END  
   
   
 UPDATE dbo.StagingDPTransactionChangeHistory SET ISIN='INE999999999' WHERE ISIN=''  
   
 DECLARE @BadIsin VARCHAR(500)  
    SELECT @BadIsin = stage.ISIN FROM dbo.StagingDPTransactionChangeHistory stage WHERE NOT EXISTS  
    (  
        SELECT 1 FROM RefIsin isin  
        WHERE stage.ISIN = isin.Name  
    )  
    AND stage.[GUID] = @Guid  
    IF (@BadIsin IS NOT NULL)  
    BEGIN  
        DELETE FROM dbo.StagingDPTransactionChangeHistory WHERE [GUID] = @Guid  
        RAISERROR ('ISIN %s not present in Database',11,1,@BadIsin) with SETERROR  
        RETURN 50010  
    END  
  
  Update dbo.StagingDPTransactionChangeHistory   SET Quantity = (Quantity/1000) WHERE [GUID]=@Guid  
   
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
  MarginPledgeInstructionID,  
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
 WHERE  
  stage.GUID = @Guid  
  AND NOT EXISTS  
  (  
   SELECT 1   
   FROM dbo.CoreDPTransactionChangeHistory transact  
   WHERE   
   transact.RefSegmentId = @SegmentId AND  
   transact.RefDpTransactionTypeId = ISNULL(transtype.RefDpTransactionTypeId,0) AND  
   transact.RefClientId = client.RefClientId AND  
   transact.Quantity = ISNULL(stage.Quantity,0.00) AND  
   transact.RefIsinId = isin.RefIsinId AND  
   transact.StatusChangeDateTime = stage.StatusChangeDateTime  
  )  
 --DELETE FROM dbo.StagingDPTransactionChangeHistory WHERE [GUID]=@Guid  
    
END  
GO