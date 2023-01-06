select * from StagingDpTransaction
sp_helptext CoreDpTransaction_InsertDpTransactionFromStaging

Go
CREATE PROCEDURE [dbo].[CoreDpTransaction_InsertDpTransactionFromStaging]  
(  
 @Guid VARCHAR(40)  
)  
AS  
  
BEGIN  
     
    DECLARE @SegmentId INT  
        SELECT  @SegmentId = dbo.GetSegmentId(SegmentName)  
        FROM    dbo.StagingDpTransaction  
        WHERE   [GUID] = @Guid  
  
  
        IF ( @SegmentId IS NULL )   
            BEGIN  
                DELETE FROM dbo.StagingDpTransaction WHERE [GUID] = @Guid  
                RAISERROR ('Segment not present',11,1) WITH SETERROR  
                RETURN 50010  
            END  
      
    DECLARE @SegmentDatabaseId INT  
    SELECT @SegmentDatabaseId = RefDatabaseId FROM RefSegmentEnum WHERE RefSegmentEnumId = @SegmentId  
     
  
 UPDATE dbo.StagingDpTransaction   
 SET  BOId = CounterBOId,  
   CounterBOId = BOId,  
   IsPledgee = 1  
 WHERE [GUID] = @Guid  
   AND StagingDpTransaction.TransactionStatus IN ('802','804','818','816','819','902','904','1101','805')  
   AND   
   NOT EXISTS (  
      SELECT 1   
      FROM dbo.RefClient client   
      WHERE dbo.StagingDpTransaction.BOId = client.ClientId  
      )  
      
  UPDATE stage   
 SET  BOId = CounterBOId,  
   CounterBOId = BOId  
  FROM dbo.StagingDpTransaction stage  
  INNER JOIN dbo.RefClient cli ON cli.clientid=stage.CounterBOId  
 WHERE [GUID] = @Guid  
   AND stage.TransactionStatus IN ('828','829','830','831','832','833','834','835','836','837','838')  
   AND   
   NOT EXISTS (  
      SELECT 1   
      FROM dbo.RefClient client   
      WHERE stage.BOId = client.ClientId  
      )  
      
    DECLARE @BadClient VARCHAR(50)  
    SELECT @BadClient = stage.BOId FROM dbo.StagingDpTransaction stage WHERE NOT EXISTS  
    (  
        SELECT 1 FROM dbo.RefClient client  
        WHERE stage.BOId = client.ClientId OR stage.counterboid=client.clientid  
    )  
    AND stage.[GUID] = @Guid      
      
    IF (@BadClient IS NOT NULL)  
    BEGIN  
                DELETE FROM dbo.StagingDpTransaction WHERE [GUID] = @Guid  
                RAISERROR ('Client %s not present in Database',11,1,@BadClient) with SETERROR  
                RETURN 50010  
    END  
      
      
    UPDATE StagingDpTransaction   
    SET ISIN = 'INE999999999'  
    WHERE ISIN = ''  
      
      
    DECLARE @BadIsin VARCHAR(50)  
    SELECT @BadIsin = stage.ISIN FROM dbo.StagingDpTransaction stage WHERE NOT EXISTS  
    (  
        SELECT 1 FROM RefIsin isin  
        WHERE stage.ISIN = isin.Name  
    )  
    AND stage.[GUID] = @Guid  
  
    IF (@BadIsin IS NOT NULL)  
    BEGIN  
                DELETE FROM dbo.StagingDpTransaction WHERE [GUID] = @Guid  
                RAISERROR ('ISIN %s not present in Database',11,1,@BadIsin) with SETERROR  
                RETURN 50010  
    END  
          
      
    DECLARE @BadTransactionType VARCHAR(50)  
    SELECT @BadTransactionType = stage.TransactionType FROM dbo.StagingDpTransaction stage  
    WHERE stage.TransactionType IS NOT NULL AND NOT EXISTS   
    (  
  SELECT 1 FROM RefDpTransactionType transtype  
  WHERE stage.TransactionType = transtype.CdslCode  
 )  
 AND stage.[GUID] = @Guid   
  
    IF (@BadTransactionType IS NOT NULL)  
    BEGIN  
                DELETE FROM dbo.StagingDpTransaction WHERE [GUID] = @Guid  
                RAISERROR ('TransactionType = %s not present in Database',11,1,@BadTransactionType) with SETERROR  
                RETURN 50010  
    END  
      
      
    UPDATE dbo.StagingDpTransaction   
    SET DestatRejectionCode = NULL  
    WHERE TransactionType <> '32'  
      
    UPDATE dbo.StagingDpTransaction   
    SET BuySellFlag = NULL  
    WHERE SegmentName <> 'NSDL' AND TransactionType <> '1' AND TransactionType <> '2' AND TransactionType <> '3' AND TransactionType <> '5'     
      
    UPDATE dbo.StagingDpTransaction   
    SET BuySellFlag = OrderStatusFlag  
    WHERE TransactionType = '14' OR TransactionType = '15' OR TransactionType = '16' OR   
    TransactionType = '26' OR TransactionType = '27' OR TransactionType = '29'  
  
    
 INSERT INTO dbo.CoreDpTransaction (RefSegmentId,  RefDpTransactionTypeId, RefClientId, RefIsinId, TransactionId, FreezeId, Quantity,   
 RefDpTransactionStatusId, TransactionSetupDate, BusinessDate, BuySellFlag, FreeLockInFlag, FreezeLevel,   
 TransactionTypeFlag, CounterBOId, FolioNumber, PartialAllQuantityFlag, CMId, OriginalPSN, RestatementRedemptionFlag,   
 SettlementId, CounterSettlementId, TradeId, ObligationId, TransferTransmissionTransactoinNumber, PartCounter, ParentPSN,   
 FreezeParentId, SenderTransactionReferenceNumber, SequenceNumber, ExecutionDate, DispatchDate, RematReceivedDate,   
 PledgeExecutionDate, RestatReceivedDate, RTAId, UnpledgePartCounter, ConfiscatonCounter, FreezeInitiatedBy,   
 TransferReasonCode, LockInId, ParentTXNId, DocumentNumber, DIS,DeliveryInstructionSlip, DispatchDocumentId,   
 AgreementNumber, ParentLockInId, EasiAuthenticationRefNumber, CourierName, PledgeeDpInternalRefNumber, SelfBatchId,DespatchName,   
 CASequenceNumber, NumberOfCertificates, LotSize, FreezeSubOption, NumberOfPages, LockInCode, FreezeReasonCode,   
 LockInReasonCode, LockInExpiryDate, ReceivedDate, PledgeExpiryDate, FreezeExpiryDate, TransferType, ConfirmationRejectionFlag,   
 MakerCheckerFlag, FreezeQuantityType, TransferStatusFlag, AcceptedRejectionFlag, MakerCheckerTransactionFlag,   
 OrderStatusFlag, PayInTypeFlag, DematRejectionFlag, LotType, FreezeType, AllQuantityFlag, ReasonForTrade, DematRejectionCode,   
 CAType, FrozenFlag, TransferTypeFlag, TransactionReasonCode, DestatRejectionCode, ConfirmationDate, EarmarkQuantity,   
 VerifyAcceptedQuantity, AcceptedQuantity, PledgeValue, TotalPledgedQuantity, SetupQuantity, ActualQuantity, TransferredQuantity,   
 RejectedQuantity, PledgeBalace, TotalQuantityUnpledgeConfiscation, ConfirmedAcceptedQuantity, PledgeAvailableQuantity,   
 QuantityAvailableUnpledgeConfiscation, LockInQuantity, RestatRedemptionAmount, ConfirmedRejectedQuantity,   
 TotalQtyUnpledgeConfiscationInitiated, TotalRejectedQuantity, FinancialFlag, EFTSCode, RefDpTransactionCodeId,   
 IsModificationFlag, TransactionCounter,TransactionBalType, InternalRefNumber, RTAInternalRefNumber, PledgorDPInternalRefNumber, TrustRemarks,   
 TxnRemarks, DpRemarks, RejectionRemarks, PledgorDpRemarks, Remarks, RTARemarks,CTRTransactionRemarks ,PledgeeDpRemarks, OperatorId,   
 TransactionSource, LastModificationDate, EasiReferenceNumber, RejectionReason1, ErrorCode,IsTransactionElectronicFlag,   
 CounterLockInId, DematRequestNumber, ParentChildRematRequestNumber, OldNewDestatRequestNumber, TransferId, BranchCode,   
 BeneficiaryCategory, BeneficiaryAccountType, BookingNarrationCode, BookingType, ClearingCorporationId, MarketType, BlockLockFlag,   
 CounterDPIdOrOtherDepositoryId, BPInstructionId, DMOrderNumber, CounterCMBPId, RejectionReason2, RejectionReason3,   
 RejectionReason4, OtherClientCode, BeneficiaryAccountTypePrevious, BookingNarrationCodePrevious,AddedBy,AddedOn,LastEditedBy,EditedOn,IsPledgee,  
 PaymentMode,BankAccountNumber,BankName,BranckName,ChequeReferenceNumber,DateOfIssue,Ucc,SegmentCode,ExchangeId,TMId,CPId,EntityIdentifier,ParentMarginPledgePSN)  
 SELECT    
  @SegmentId,  
  transtype.RefDpTransactionTypeId,  
  client.RefClientId,  
  isin.RefIsinId,  
  CASE WHEN transtype.CdslCode <> '12' THEN stage.TransactionId ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '12' THEN stage.FreezeId ELSE NULL END,  
  stage.Quantity,    
  transstatus.RefDpTransactionStatusId,    
  stage.TransactionSetupDate,  
  stage.BusinessDate,    
  CASE WHEN transtype.CdslCode = '14' OR transtype.CdslCode = '15' OR transtype.CdslCode = '16' OR transtype.CdslCode = '26' OR transtype.CdslCode = '27' OR transtype.CdslCode = '29' THEN stage.OrderStatusFlag ELSE stage.BuySellFlag END,    
  CASE WHEN transtype.CdslCode = '6' OR transtype.CdslCode = '7' OR transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' OR transtype.CdslCode = '32' OR transtype.CdslCode = '33' THEN stage.FreeLoc
kInFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '12' THEN stage.FreezeLevel ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '17' OR transtype.CdslCode = '18' OR transtype.CdslCode = '28' THEN stage.TransactionTypeFlag ELSE NULL END,    
  CASE WHEN stage.SegmentName = 'NSDL' THEN stage.CounterBOId WHEN transtype.CdslCode = '32' AND transtype.CdslCode = '33' THEN stage.CounterLockInId ELSE stage.CounterBOId END,    
  CASE WHEN transtype.CdslCode = '32' THEN stage.FolioNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '33' THEN stage.PartialAllQuantityFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode <> '8' AND transtype.CdslCode <> '33'  THEN stage.CMId ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' THEN stage.OriginalPSN ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '33' THEN stage.RestatementRedemptionFlag ELSE NULL END,  
  stage.SettlementId,  
  stage.CounterSettlementId,  
  CASE WHEN transtype.CdslCode = '2' OR transtype.CdslCode = '3' OR transtype.CdslCode = '28' THEN stage.TradeId ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '1' THEN stage.ObligationId ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '5' THEN stage.TransferTransmissionTransactoinNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '7' OR transtype.CdslCode = '33' THEN stage.PartCounter ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' THEN stage.ParentPSN ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '12' THEN stage.FreezeParentId ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '17' OR transtype.CdslCode = '18' THEN stage.SenderTransactionReferenceNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '20' OR transtype.CdslCode = '21' OR transtype.CdslCode = '22' THEN stage.SequenceNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode <> '6' AND transtype.CdslCode <> '7' AND transtype.CdslCode <> '8' AND transtype.CdslCode <> '33' THEN stage.ExecutionDate ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' THEN stage.DispatchDate WHEN transtype.CdslCode = '32' THEN stage.ReceivedDate ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '7' THEN stage.RematReceivedDate ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' THEN stage.PledgeExecutionDate ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '33' THEN stage.RestatReceivedDate ELSE NULL END,  
  CASE WHEN transtype.CdslCode <> '9' AND transtype.CdslCode <> '11' AND transtype.CdslCode <> '12' AND transtype.CdslCode <> '18' THEN stage.RTAId ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '9' OR transtype.CdslCode = '10' THEN stage.UnpledgePartCounter ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '11' THEN stage.ConfiscatonCounter ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '12' THEN stage.FreezeInitiatedBy ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '18' THEN stage.TransferReasonCode ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '2' OR transtype.CdslCode = '3' OR transtype.CdslCode = '14' OR transtype.CdslCode = '16' OR transtype.CdslCode = '22' OR transtype.CdslCode = '23' OR transtype.CdslCode = '29' THEN stage.LockInId WHEN transtype.CdslCode 
= '18' THEN stage.DeliveryInstructionSlip WHEN transtype.CdslCode = '6' OR transtype.CdslCode = '7' OR transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' OR transtype.CdslCode = '20' OR transtype
.CdslCode = '21' OR transtype.CdslCode = '32' OR transtype.CdslCode = '33' THEN stage.EasiReferenceNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '1' THEN stage.ParentTXNId ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' OR transtype.CdslCode = '7' OR transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' OR transtype.CdslCode = '12' OR transtype.CdslCode = '32' THEN stage.Documen
tNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '28' THEN stage.DIS ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '1' OR transtype.CdslCode = '2' OR transtype.CdslCode = '3' OR transtype.CdslCode = '4' OR transtype.CdslCode = '5' THEN stage.DeliveryInstructionSlip ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' OR transtype.CdslCode = '32'  OR transtype.CdslCode = '28' THEN stage.DispatchDocumentId ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' THEN stage.AgreementNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '21' OR transtype.CdslCode = '22' THEN stage.ParentLockInId ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '1' OR transtype.CdslCode = '2' OR transtype.CdslCode = '3' OR transtype.CdslCode = '4' OR transtype.CdslCode = '5' THEN stage.EasiAuthenticationRefNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' OR transtype.CdslCode = '32' THEN stage.CourierName ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' THEN stage.PledgeeDpInternalRefNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '16' OR transtype.CdslCode = '17' OR transtype.CdslCode = '26' OR transtype.CdslCode = '27' OR transtype.CdslCode = '29' THEN stage.SelfBatchId ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '28' THEN stage.DespatchName ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '1' OR transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' THEN stage.CASequenceNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' OR transtype.CdslCode = '33' OR transtype.CdslCode = '28' THEN stage.NumberOfCertificates ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '7' THEN stage.LotSize ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '12' THEN stage.FreezeSubOption ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '32' THEN stage.NumberOfPages ELSE NULL END,    
  CASE WHEN stage.SegmentName = 'NSDL' OR transtype.CdslCode = '28' THEN stage.LockInCode WHEN transtype.CdslCode = '14' THEN stage.CASequenceNumber WHEN transtype.CdslCode <> '12' AND transtype.CdslCode <> '16' THEN stage.LockInCode ELSE NULL END,    
  CASE WHEN transtype.CdslCode = '12' THEN stage.FreezeReasonCode ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '16' THEN stage.LockInReasonCode ELSE NULL END,  
  stage.LockInExpiryDate,  
  CASE WHEN transtype.CdslCode = '6' THEN stage.ReceivedDate ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' THEN stage.PledgeExpiryDate ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '12' OR transtype.CdslCode = '28' THEN stage.FreezeExpiryDate ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '2' OR transtype.CdslCode = '3' THEN stage.TransferType ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '7' THEN stage.ConfirmationRejectionFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '17' OR transtype.CdslCode = '18' THEN stage.OrderStatusFlag WHEN transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' OR transtype.CdslCode = '28' THEN stage.Maker
CheckerFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '12' THEN stage.FreezeQuantityType ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '18' THEN stage.TransferStatusFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '33' THEN stage.AcceptedRejectionFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '17' THEN stage.MakerCheckerTransactionFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '2' OR transtype.CdslCode = '3'  OR transtype.CdslCode = '28' THEN stage.OrderStatusFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '1' OR transtype.CdslCode = '30' THEN stage.PayInTypeFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' THEN stage.DematRejectionFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '7' OR transtype.CdslCode = '33' THEN stage.LotType ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '12' THEN stage.FreezeType ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '32' THEN stage.AllQuantityFlag ELSE NULL END,    
  CASE WHEN transtype.CdslCode = '2' OR transtype.CdslCode = '3' OR transtype.CdslCode = '28' THEN stage.ReasonForTrade ELSE NULL END,    
  CASE WHEN transtype.CdslCode = '6' THEN stage.DematRejectionCode ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' THEN stage.CAType WHEN transtype.CdslCode = '21' OR transtype.CdslCode = '22' THEN stage.TransactionCounter ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '12' THEN stage.FrozenFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '17' THEN stage.TransferTypeFlag ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '18' THEN stage.TransactionReasonCode ELSE NULL END,  
  stage.DestatRejectionCode,  
  stage.ConfirmationDate,  
  CASE WHEN transtype.CdslCode = '1' OR transtype.CdslCode = '4' THEN stage.EarmarkQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' OR transtype.CdslCode = '28' THEN stage.VerifyAcceptedQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '7' OR transtype.CdslCode = '33' THEN stage.AcceptedQuantity WHEN transtype.CdslCode = '32' THEN stage.ConfirmedAcceptedQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' THEN stage.PledgeValue ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11'  THEN stage.TotalPledgedQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '12' THEN stage.SetupQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '15' OR transtype.CdslCode = '26' THEN stage.ActualQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '17' OR transtype.CdslCode = '18' THEN stage.TransferredQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' OR transtype.CdslCode = '7' OR transtype.CdslCode = '17' OR transtype.CdslCode = '18' OR transtype.CdslCode = '32' OR transtype.CdslCode = '33' OR transtype.CdslCode = '28' THEN stage.RejectedQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' THEN stage.PledgeBalace ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11'  THEN stage.TotalQuantityUnpledgeConfiscation ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6'  OR transtype.CdslCode = '28' THEN stage.ConfirmedAcceptedQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' THEN stage.PledgeAvailableQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11'  THEN stage.QuantityAvailableUnpledgeConfiscation ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '23' THEN stage.LockInQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '33' THEN stage.RestatRedemptionAmount ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' OR transtype.CdslCode = '28' THEN stage.ConfirmedRejectedQuantity ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11'  THEN stage.TotalQtyUnpledgeConfiscationInitiated ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '32' THEN stage.TotalRejectedQuantity ELSE NULL END,  
  stage.FinancialFlag,  
  stage.EFTSCode,    
  transcode.RefDpTransactionCodeId,    
  CASE WHEN transtype.CdslCode <> '17' AND transtype.CdslCode <> '18' AND transtype.CdslCode <> '32' AND transtype.CdslCode <> '21' AND transtype.CdslCode <> '22' AND stage.ModificationFlag = 1 THEN 1 WHEN transtype.CdslCode <> '17' AND transtype.CdslCode
 <> '18' AND transtype.CdslCode <> '32' AND transtype.CdslCode <> '21' AND transtype.CdslCode <> '22' AND stage.ModificationFlag = 0 THEN 0 ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '17' OR transtype.CdslCode = '18' OR transtype.CdslCode = '32' THEN stage.TransactionCounter ELSE NULL END,   
  CASE WHEN transtype.CdslCode = '28'  THEN stage.TransactionBalType ELSE NULL END,     
  CASE WHEN stage.SegmentName = 'NSDL' THEN stage.InternalRefNumber WHEN transtype.CdslCode = '7' THEN stage.DeliveryInstructionSlip WHEN transtype.CdslCode = '33' THEN stage.DocumentNumber WHEN transtype.CdslCode <> '33' AND transtype.CdslCode <> '8' AND
 transtype.CdslCode <> '9' AND transtype.CdslCode <> '10' AND transtype.CdslCode <> '11' THEN stage.InternalRefNumber ELSE NULL END,    
  CASE WHEN transtype.CdslCode = '7' OR transtype.CdslCode = '33' THEN stage.RTAInternalRefNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' THEN stage.PledgorDPInternalRefNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '2' OR transtype.CdslCode = '3' OR transtype.CdslCode = '4'  THEN stage.TrustRemarks WHEN transtype.CdslCode = '1' THEN stage.RTARemarks ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '1' OR transtype.CdslCode = '28' THEN stage.TxnRemarks ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' OR transtype.CdslCode = '32' THEN stage.DpRemarks ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '7' THEN stage.RejectionRemarks ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' THEN stage.PledgorDpRemarks ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '12' OR transtype.CdslCode = '15' OR transtype.CdslCode = '16' OR transtype.CdslCode = '17' OR transtype.CdslCode = '18' OR transtype.CdslCode = '22' OR transtype.CdslCode = '23' OR transtype.CdslCode = '26' OR transtype.C
dslCode = '27' OR transtype.CdslCode = '29' OR transtype.CdslCode = '33' THEN stage.Remarks ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' OR transtype.CdslCode = '7' OR transtype.CdslCode = '32' OR transtype.CdslCode = '33' THEN stage.RTARemarks ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '28' THEN stage.CTRTransactionRemarks ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '8' OR transtype.CdslCode = '9' OR transtype.CdslCode = '10' OR transtype.CdslCode = '11' THEN stage.PledgeeDpRemarks ELSE NULL END,  
  stage.OperatorId,    
  stage.TransactionSource,    
  stage.LastModificationDate,  
  CASE WHEN transtype.CdslCode = '1' OR transtype.CdslCode = '2' OR transtype.CdslCode = '3' OR transtype.CdslCode = '4' OR transtype.CdslCode = '5' OR transtype.CdslCode = '30' THEN stage.EasiReferenceNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode <>'28'  THEN stage.RejectionReason1 ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '28' THEN stage.ErrorCode ELSE NULL END,  
  CASE WHEN stage.TransactionElectronicFlag = 'Y' THEN 1 WHEN stage.TransactionElectronicFlag = 'N' THEN 0 ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '18' THEN stage.CounterLockInId ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' THEN stage.DematRequestNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '7' THEN stage.ParentChildRematRequestNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '32' OR transtype.CdslCode = '33' THEN stage.OldNewDestatRequestNumber ELSE NULL END,  
  CASE WHEN transtype.CdslCode = '6' THEN stage.TransferId ELSE NULL END,  
  stage.BranchCode,  
  stage.BeneficiaryCategory,  
  stage.BeneficiaryAccountType,  
  stage.BookingNarrationCode,  
  stage.BookingType,  
  stage.ClearingCorporationId,  
  stage.MarketType,  
  stage.BlockLockFlag,  
  stage.CounterDPIdOrOtherDepositoryId,  
  stage.BPInstructionId,  
  stage.DMOrderNumber,  
  stage.CounterCMBPId,  
  stage.RejectionReason2,  
  stage.RejectionReason3,  
  stage.RejectionReason4,  
  stage.OtherClientCode,  
  stage.BeneficiaryAccountTypePrevious,  
  stage.BookingNarrationCodePrevious,  
  stage.AddedBy,  
  GETDATE() as AddedOn,  
  stage.AddedBy as LastEditedBy,  
  GETDATE() as EditedOn,  
  stage.IsPledgee,  
  stage.PaymentMode,  
  stage.BankAccountNumber,  
  stage.BankName,  
  stage.BranckName,  
  stage.ChequeReferenceNumber,  
  CASE WHEN transtype.CdslCode = '2' OR transtype.CdslCode = '3' OR transtype.CdslCode = '5' then stage.DateOfIssue else null end,  
  stage.Ucc,  
  stage.SegmentCode,  
  stage.ExchangeId,  
  stage.TMId,  
  stage.CPId,  
  stage.EntityIdentifier,  
  stage.ParentMarginPledgePSN  
 FROM   
  dbo.StagingDpTransaction stage LEFT JOIN  
  dbo.RefDpTransactionType transtype ON (transtype.CdslCode = stage.TransactionType) INNER JOIN    
  dbo.RefClient client ON (client.ClientId = stage.BOId AND client.RefClientDatabaseEnumId = @SegmentDatabaseId  
  AND stage.SegmentName = 'NSDL' AND ISNULL(client.DpId,0) = ISNULL(stage.DpId,0)) OR  
  (client.ClientId = stage.BOId AND client.RefClientDatabaseEnumId = @SegmentDatabaseId  
  AND stage.SegmentName = 'CDSL' AND client.DpId IS NULL) INNER JOIN  
  dbo.RefIsin isin ON (isin.Name = stage.ISIN) LEFT JOIN    
  dbo.RefDpTransactionStatus transstatus ON (transstatus.CdslCode = stage.TransactionStatus) LEFT JOIN    
  dbo.RefDpTransactionCode transcode ON (transcode.CdslCode = stage.TransactionCode and  
  transcode.RefDpTransactionTypeId = transtype.RefDpTransactionTypeId and   
  (transcode.RefDpTransactionStatusId = transstatus.RefDpTransactionStatusId OR  
  transcode.RefDpTransactionStatusId IS NULL))  
   
 WHERE stage.[GUID] = @Guid  
 AND NOT EXISTS  
 (  
  SELECT 1   
  FROM dbo.CoreDpTransaction transact  
    
  WHERE transact.RefSegmentId = @SegmentId AND    
     ISNULL(transact.RefDpTransactionTypeId,0) = ISNULL(transtype.RefDpTransactionTypeId,0) AND   
     transact.RefClientId = client.RefClientId AND  
     transact.RefIsinId = isin.RefIsinId AND  
     ISNULL(transact.TransactionId,0) = ISNULL(stage.TransactionId,0) AND  
     transact.Quantity = stage.Quantity AND  
     transact.TransactionSetupDate = stage.TransactionSetupDate AND  
     ISNULL(transact.RefDpTransactionStatusId,0) = ISNULL(transstatus.RefDpTransactionStatusId,0) AND  
     ISNULL(transact.RefDpTransactionCodeId,0) = ISNULL(transcode.RefDpTransactionCodeId,0) AND  
     ISNULL(transact.DestatRejectionCode,0) = ISNULL(stage.DestatRejectionCode,0) AND   
     ISNULL(transact.BPInstructionId,0) = ISNULL(stage.BPInstructionId,0) AND  
     ISNULL(transact.BookingNarrationCode,0) = ISNULL(stage.BookingNarrationCode,0) AND    
     ISNULL(transact.BuySellFlag,'') = ISNULL(stage.BuySellFlag,'')  
 )  
    
 DELETE FROM dbo.StagingDpTransaction WHERE [GUID] = @Guid  
  
End  
Go
declare @cliid INT
select @cliid=RefClientId from RefClient where clientid='100000343434'
SELECT @cliid