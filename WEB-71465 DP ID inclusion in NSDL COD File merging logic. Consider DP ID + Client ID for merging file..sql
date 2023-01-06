--WEB-71465 RC START
GO
ALTER TABLE dbo.StagingDPTransactionChangeHistory
ADD  DPId  VARCHAR(100) NULL
GO
--WEB-71465 RC END
--WEB-71465 RC START
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
  stage.DPId,
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
  ts.ClientId ,
  ts.DPId
  INTO #CLIENTCHECK  
  FROM #TempStaging ts  
  LEFT JOIN dbo.RefClient client ON client.ClientId=CONVERT(varchar(200),ts.ClientId)  AND ts.DPId = CONVERT(VARCHAR(100),client.DpId)
  WHERE client.RefClientId IS NULL  
  
  UPDATE #ErrorListTable  
  SET ErrorMessage = ErrorMessage + 'DPID ' +ISNULL('IN'+CONVERT(VARCHAR(100),ic.DPId) COLLATE DATABASE_DEFAULT,'') + ' not found for client Id '+ ISNULL(CONVERT(VARCHAR(200),ic.ClientId),'')  
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
  SET ErrorMessage = ErrorMessage + ', ISIN '+ic.ISIN COLLATE DATABASE_DEFAULT+' not present in Isin Master'   
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
     INNER JOIN dbo.RefClient client ON (CONVERT(VARCHAR(250),stage.ClientId) = client.ClientId AND stage.DPId = CONVERT(VARCHAR(100),client.DpId ) AND client.RefClientDatabaseEnumId=@SegmentDatabaseId)     
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
--WEB-71465 RC END
