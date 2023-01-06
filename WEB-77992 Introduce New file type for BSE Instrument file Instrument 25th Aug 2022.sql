--File:StoredProcedures:dbo:RefInstrument_InsertBseCashFromStagingNew
--WEB-77992-RC START
GO
CREATE PROCEDURE dbo.RefInstrument_InsertBseCashFromStagingNew
(
	@Guid VARCHAR(40),
	@FaceValueInRupees BIT = 1
)
AS

BEGIN

  DECLARE @SegmentId INT,@AddedOn DATETIME,@GuidInternal VARCHAR(40)
	SELECT @SegmentId = dbo.GetSegmentId('BSE_CASH')
	SET @GuidInternal = @Guid

	  IF (@SegmentId IS NULL)
	  BEGIN
		RAISERROR ('Segment BSE_CASH not present', 11, 1) WITH SETERROR
		RETURN 50010
	  END

  SET @AddedOn = (SELECT TOP 1 AddedOn FROM dbo.StagingRefBseCashInstrument WHERE [GUID] = @Guid)
   
  --isin insert
  
  INSERT INTO dbo.RefIsin (RefSegmentId, [Name], [Description], IsinShortName, AddedBy, AddedOn, LastEditedBy, EditedOn, PmsLiquid, SttExempt, BrokerageExempt)
    SELECT
      @SegmentId ,
      Isin,
      IsinName,
      IsinName,
      AddedBy,
      @AddedOn AS AddedOn,
      AddedBy,
      @AddedOn AS EditedOn,
      0,0,0
    FROM (SELECT
      stag.Isin,
      stag.[Name] AS IsinName,
      stag.AddedBy,
      ROW_NUMBER() OVER (PARTITION BY stag.Isin ORDER BY stag.StagingRefBseCashInstrumentId DESC) AS RowIndex
    FROM dbo.StagingRefBseCashInstrument stag
	LEFT JOIN dbo.RefIsin dupCheck ON dupCheck.[Name] = stag.Isin
    WHERE dupCheck.RefIsinId IS NULL AND stag.[GUID] = @Guid AND stag.Isin IS NOT NULL
    AND stag.Isin NOT IN( '','0','NA')
    ) temp
    WHERE temp.RowIndex = 1

  SELECT
    ref.RefInstrumentId,
    @SegmentId AS RefSegmentId,
    stage.[GUID],
    stage.Code,
	stage.InstrumentCode,
	stage.GroupName,
    stage.[Name],
	stage.Isin,
	stage.MarketLot,
	CASE WHEN @FaceValueInRupees = 1 THEN stage.FaceValue
      ELSE stage.FaceValue / 100
    END FaceValue,
	stage.SecurityTypeFlag,
	stage.NewTickSize,
	stage.GSMType,
	stage.CallAuctionIndicator,
	stage.BcStartDate,
    stage.BcEndDate,
	stage.NoDeliveryStartDate,
    stage.NoDeliveryEndDate,
	stage.SettlementType,
	stage.ExchangeCode,
	stage.PartitionAndProductId,
	stage.ScripType,
	stage.TickSize,
	stage.BSEExclusive,
	stage.[Status],
	stage.ExDivDate,
	stage.ExBonusDate,
	stage.ExRightDate,
	stage.InstrumentType,
    stage.AddedBy AS LastEditedBy,
    stage.AddedOn AS EditedOn
  INTO #TempStagingInstrument
  FROM dbo.StagingRefBseCashInstrument stage
  INNER JOIN dbo.RefInstrument ref ON  ref.RefSegmentId = @SegmentId AND stage.Code = ref.Code 
  WHERE stage.[GUID] = @Guid
  AND (ref.[Name] <> stage.[Name]
	  OR ISNULL(ref.InstrumentCode, '') <> ISNULL(stage.InstrumentCode, '')
	  OR ISNULL(ref.GroupName, '') <> ISNULL(stage.GroupName, '')
	  OR ISNULL(ref.Isin, '') <> ISNULL(stage.Isin, '')
	  OR ISNULL(ref.MarketLot, 0.000) <> ISNULL(stage.MarketLot, 0.000)
	  OR (
		  (ISNULL(ref.FaceValue, 0.000) <> ISNULL(stage.FaceValue, 0.000)
		  AND @FaceValueInRupees = 1)
		  OR (ISNULL(ref.FaceValue, 0.000) <> ISNULL(stage.FaceValue / 100, 0.000)
		  AND @FaceValueInRupees <> 1)
		  )
	  OR ISNULL(ref.SecurityTypeFlag, '') <> ISNULL(stage.SecurityTypeFlag, '')
	  OR ISNULL(ref.NewTickSize, 0.000) <> ISNULL(stage.NewTickSize, 0.000)
	  OR ISNULL(ref.GSMType, '') <> ISNULL(stage.GSMType, '')
	  OR ISNULL(ref.CallAuctionIndicator, 0) <> ISNULL(stage.CallAuctionIndicator, 0)
	  OR ISNULL(ref.BcStartDate, GETDATE()) <> ISNULL(stage.BcStartDate, GETDATE())
	  OR ISNULL(ref.BcEndDate, GETDATE()) <> ISNULL(stage.BcEndDate, GETDATE())
	  OR ISNULL(ref.NoDeliveryStartDate, GETDATE()) <> ISNULL(stage.NoDeliveryStartDate, GETDATE())
	  OR ISNULL(ref.NoDeliveryEndDate, GETDATE()) <> ISNULL(stage.NoDeliveryEndDate, GETDATE())
	  OR ISNULL(ref.SettlementType, '') <> ISNULL(stage.SettlementType, '')
	  OR ISNULL(ref.ExchangeCode, '') <> ISNULL(stage.ExchangeCode, '')
	  OR ISNULL(ref.PartitionAndProductId, '') <> ISNULL(stage.PartitionAndProductId, '')
	  OR ISNULL(ref.ScripType, '') <> ISNULL(stage.ScripType, '')
	  OR ISNULL(ref.TickSize, 0.000) <> ISNULL(stage.TickSize, 0.0000)
	  OR ISNULL(ref.BSEExclusive, '') <> ISNULL(stage.BSEExclusive, '')
	  OR ISNULL(ref.[Status], '') <> ISNULL(stage.[Status], '')
	  OR ISNULL(ref.ExDivDate, GETDATE()) <> ISNULL(stage.ExDivDate, GETDATE())
	  OR ISNULL(ref.ExBonusDate, GETDATE()) <> ISNULL(stage.ExBonusDate, GETDATE())
	  OR ISNULL(ref.ExRightDate, GETDATE()) <> ISNULL(stage.ExRightDate, GETDATE())
	  OR ISNULL(ref.InstrumentType, '') <> ISNULL(stage.InstrumentType, '')
  )

  UPDATE dbo.RefInstrument
  SET RefSegmentId = @SegmentId,
      Code = stage.Code,
	  InstrumentCode = stage.InstrumentCode,
	  GroupName = stage.GroupName,
	  Isin = stage.Isin,
	  MarketLot = stage.MarketLot,
	  FaceValue = stage.FaceValue,
      [Name] = stage.[Name],
	  SecurityTypeFlag =stage.SecurityTypeFlag,
	  NewTickSize = stage.NewTickSize,
	  GSMType = stage.GSMType,
	  CallAuctionIndicator = stage.CallAuctionIndicator,
	  BcStartDate = stage.BcStartDate,
      BcEndDate = stage.BcEndDate,
	  NoDeliveryStartDate = stage.NoDeliveryStartDate,
	  NoDeliveryEndDate = stage.NoDeliveryEndDate,
	  SettlementType = stage.SettlementType,
	  ExchangeCode = stage.ExchangeCode,
	  PartitionAndProductId = stage.PartitionAndProductId,
	  ScripType = stage.ScripType,
	  TickSize = stage.TickSize,
      InstrumentType = stage.InstrumentType,
      BSEExclusive =stage.BSEExclusive,
	  [Status] = stage.[Status],
	  ExDivDate = stage.ExDivDate,
	  ExBonusDate = stage.ExBonusDate,
	  ExRightDate = stage.ExRightDate,
      LastEditedBy = stage.LastEditedBy,
      EditedOn = stage.EditedOn
  FROM #TempStagingInstrument stage
  WHERE stage.RefInstrumentId IS NOT NULL
  AND stage.RefInstrumentId = RefInstrument.RefInstrumentId


   INSERT INTO RefInstrument (
	  RefSegmentId, 
	  Code,
	  InstrumentCode,
	  GroupName,
	  Isin,
	  MarketLot,
	  FaceValue,
	  [Name],
	  SecurityTypeFlag,
	  NewTickSize,
	  GSMType,
	  CallAuctionIndicator,
	  BcStartDate,
	  BcEndDate,
	  NoDeliveryStartDate,
	  NoDeliveryEndDate,
	  SettlementType,
	  ExchangeCode,
	  PartitionAndProductId,
	  ScripType,
	  TickSize,
	  InstrumentType,
	  BSEExclusive,
	  [Status],
	  ExDivDate,
	  ExBonusDate,
	  ExRightDate,
	  AddedBy,
	  AddedOn, 
	  LastEditedBy, 
	  EditedOn)
    SELECT
      @SegmentId,
      stage.Code,
	  stage.InstrumentCode,
	  stage.GroupName,
	  stage.Isin,
	  stage.MarketLot,
	  stage.FaceValue,
      stage.[Name],
	  stage.SecurityTypeFlag,
	  stage.NewTickSize,
	  stage.GSMType,
	  stage.CallAuctionIndicator,
	  stage.BcStartDate,
	  stage.BcEndDate,
	  stage.NoDeliveryStartDate,
	  stage.NoDeliveryEndDate,
	  stage.SettlementType,
	  stage.ExchangeCode,
	  stage.PartitionAndProductId,
	  stage.ScripType,
	  stage.TickSize,
	  stage.InstrumentType,
	  stage.BSEExclusive,
	  stage.[Status],
	  stage.ExDivDate,
	  stage.ExBonusDate,
	  stage.ExRightDate,
      stage.AddedBy,
      stage.AddedOn,
      stage.AddedBy,
      stage.AddedOn
    FROM [dbo].StagingRefBseCashInstrument stage
	LEFT JOIN dbo.RefInstrument ref ON ref.RefSegmentId = @SegmentId AND ref.Code = stage.Code
    WHERE [GUID] = @Guid 
    AND ref.RefInstrumentId IS NULL

  -- DELETE FROM StagingRefBseCashInstrument WHERE [GUID] = @Guid     purpos fully commented to delete data from staging  refer CoreEntityAttributeDetail_GetEntityAttributeToModify prodecure

  EXEC dbo.RefIsin_UpdateInstrumentMapping

END

GO
--WEB-77992-RC END
--File:Tables:dbo:StagingRefBseCashInstrument:ALTER
--WEB-77992-RC START
GO
ALTER TABLE dbo.StagingRefBseCashInstrument
	ADD 
		InstrumentCode VARCHAR(50),
		SecurityTypeFlag VARCHAR(20),
		NewTickSize DECIMAL(19, 6),
		CallAuctionIndicator INT ,
		NoDeliveryStartDate DATETIME,
		NoDeliveryEndDate DATETIME,
		SettlementType VARCHAR(50),
		ExchangeCode VARCHAR(50),
		PartitionAndProductId VARCHAR(50),
		BSEExclusive VARCHAR(10),
		ExDivDate DATETIME,
		ExBonusDate DATETIME,
		ExRightDate DATETIME

GO
--WEB-77992-RC END

--File:Tables:dbo:RefInstrument:ALTER
--WEB-77992-RC START
GO
ALTER TABLE dbo.RefInstrument
	ADD InstrumentCode VARCHAR(50),
		SecurityTypeFlag VARCHAR(20),
		NewTickSize DECIMAL(19, 6),
		CallAuctionIndicator INT ,
		NoDeliveryStartDate DATETIME,
		NoDeliveryEndDate DATETIME,
		ExchangeCode VARCHAR(50),
		PartitionAndProductId VARCHAR(50),
		BSEExclusive VARCHAR(10),
		ExDivDate DATETIME,
		ExBonusDate DATETIME,
		ExRightDate DATETIME

GO
--WEB-77992-RC END

--File:Tables:dbo:RefAmlFileType:DML
--WEB-77992-RC START
GO
EXEC [dbo].[RefAmlFileType_InsertIfNotExists] @FileTypeCode = 'AML' , @AmlFileTypeName = 'Instrument_EffectiveFrom_25thAug2022', @WatchListSourceName = ''
GO
--WEB-77992-RC END