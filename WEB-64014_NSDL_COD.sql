exec CoreDPTransactionChangeHistory_InsertDPTransactionFromStaging '4b6b4ef2-8784-4c6c-9e2a-e2aa53629717'
alter table StagingDPTransactionChangeHistory drop column RefIsinId,
select * from CoreDPTransactionChangeHistory where AddedBy='Ganesh.patil'
GO
CoreDPTransactionChangeHistory_InsertDPTransactionFromStaging
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
        DELETE FROM dbo.StagingDPTransactionChangeHistory WHERE [GUID] = @Guid  
        RAISERROR ('Segment not present',11,1) WITH SETERROR  
        RETURN 50010  
    END  
   
		DECLARE @SegmentDatabaseId INT  
		SELECT @SegmentDatabaseId = RefDatabaseId FROM dbo.RefSegmentEnum WHERE RefSegmentEnumId = @SegmentId  
	 
			DECLARE @refEnumTypeId INT  
			SELECT @refEnumTypeId=RefEnumTypeId from dbo.RefEnumType where Name='Channel Indicator'  
 
		UPDATE dbo.StagingDPTransactionChangeHistory SET ISIN='INE999999999' WHERE ISIN='' AND [GUID]=@Guid
	
		SELECT stage.*,client.RefClientId ,isin.RefIsinId ,client.RefClientDatabaseEnumId,transtype.RefDpTransactionTypeId
		INTO #temp
		FROM dbo.StagingDPTransactionChangeHistory stage
		LEFT JOIN dbo.RefClient client ON CAST(stage.ClientId AS varchar(200))= client.ClientId
		LEFT JOIN dbo.RefIsin isin ON isin.[Name] = stage.ISIN
		LEFT JOIN dbo.RefDpTransactionType transtype ON CONVERT(varchar(100),stage.TransactionType) = transtype.NsdlCode
		WHERE [GUID] = @Guid
  
		UPDATE stage   
		SET  stage.ClientId = stage.OtherClientId,  
		stage.OtherClientId = stage.ClientId  
		FROM #temp stage
		WHERE [GUID] = @Guid  
		AND stage.TransactionType IN ('910')  
		AND stage.RefClientId is null 

		DECLARE @ErrorString VARCHAR(50)
		SET @ErrorString='Error in Record at Line : '

		CREATE TABLE #ErrorListTable
		(
		LineNumber INT,
		ErrorMessage VARCHAR(MAX) DEFAULT '' COLLATE DATABASE_DEFAULT
		)
		
		SELECT
		ROW_NUMBER() OVER(ORDER BY stage.StagingDPTransactionChangeHistoryId) AS LineNumber,
		stage.RefClientId,
		stage.TransactionType,
		stage.RefIsinId
		INTO #TempStaging
		FROM #temp stage
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
		ts.RefClientId
		INTO #CLIENTCHECK
		FROM #TempStaging ts
		WHERE ts.RefClientId IS NULL

		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', CLient not Found'
		FROM #CLIENTCHECK ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber
		
		DROP TABLE #CLIENTCHECK

		SELECT
		ts.LineNumber,
		ts.TransactionType
		INTO #TRANSCHECK
		FROM #TempStaging ts
		LEFT JOIN dbo.RefDpTransactionType transtype ON  CAST(TS.TransactionType AS VARCHAR) = transtype.NsdlCode
		WHERE ts.TransactionType IS NOT NULL AND
		transtype.RefDpTransactionTypeId IS NULL

		UPDATE #ErrorListTable
		SET ErrorMessage = ErrorMessage + ', Transaction type not Found'
		FROM #TRANSCHECK ic
		WHERE #ErrorListTable.LineNumber = ic.LineNumber
		
		DROP TABLE #TRANSCHECK
   
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
  stage.RefDpTransactionTypeId,  
  stage.RefIsinId,  
  stage.RefClientId,  
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
  #temp stage  
  INNER JOIN dbo.RefEnumValue enumvalue ON (enumvalue.RefEnumTypeId = @refEnumTypeId AND stage.ChannelIndicator = CONVERT(INT,enumvalue.Code))   
	WHERE  stage.RefClientDatabaseEnumId=@SegmentDatabaseId AND 
  stage.[GUID] = @Guid  
  AND NOT EXISTS  
  (  
   SELECT 1   
   FROM dbo.CoreDPTransactionChangeHistory transact  
   WHERE   
   transact.RefSegmentId = @SegmentId AND  
   transact.RefDpTransactionTypeId = ISNULL(stage.RefDpTransactionTypeId,0) AND  
   transact.RefClientId = stage.RefClientId AND  
   transact.Quantity = ISNULL(stage.Quantity,0.00) AND  
   transact.RefIsinId = stage.RefIsinId AND  
   transact.StatusChangeDateTime = stage.StatusChangeDateTime   
  )  
 END
 DROP TABLE #temp
 DELETE FROM dbo.StagingDPTransactionChangeHistory WHERE [GUID]=@Guid  
    
END 
GO