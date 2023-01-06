---------- WEB-62858 RC starts ---------
GO
 ALTER PROCEDURE [dbo].[RefInstrument_InsertMcxFnoFromStaging] (@Guid varchar(40))  
AS  
BEGIN  
   ---- Pre-merging Validation------------------  
  DECLARE @SegmentId int  
  SELECT  
    @SegmentId = dbo.GetSegmentId(SegmentName)  
  FROM dbo.StagingMcxInstrument  
  WHERE [GUID] = @Guid  
  
  
  IF (@SegmentId IS NULL)  
  BEGIN  
    RAISERROR ('Segment not present', 11, 1) WITH SETERROR  
    RETURN 50010  
  END  
  
  DECLARE @InvalidInstrumentType VARCHAR(MAX)  
    
  SELECT DISTINCT stag.InstrumentType INTO #instTypeNotPresent FROM dbo.StagingMcxInstrument stag   
  LEFT JOIN dbo.RefInstrumentType instType ON instType.InstrumentType = stag.InstrumentType  
  WHERE instType.RefInstrumentTypeId IS NULL  
  
   SELECT @InvalidInstrumentType =  STUFF(( SELECT ',' + InstrumentType  
    FROM #instTypeNotPresent  
    FOR  
    XML PATH('')  
    ), 1, 1, '');  
   
 IF(@InvalidInstrumentType != '')  
 BEGIN  
  RAISERROR ('Instrument Type(s) %s not present in database.', 11, 1,@InvalidInstrumentType) WITH SETERROR  
  RETURN 50010  
 END  
  
  
  -- this is required for uniqueness  
  DECLARE @CurDate datetime  
  SET @CurDate = GETDATE()  
  
  
  UPDATE stage  
  SET PutCall =  
               CASE OptionType  
                 WHEN 'CE' THEN 'C'  
                 WHEN 'CA' THEN 'C'  
                 WHEN 'PE' THEN 'P'  
                 WHEN 'PA' THEN 'P'  
                 ELSE NULL  
               END,  
      OptionStyle =  
                   CASE OptionType  
                     WHEN 'CE' THEN 'E'  
                     WHEN 'CA' THEN 'A'  
                     WHEN 'PE' THEN 'E'  
                     WHEN 'PA' THEN 'A'  
                     ELSE NULL  
                   END  
  FROM dbo.StagingMcxInstrument stage  
  LEFT JOIN dbo.RefInstrumentType map  
    ON stage.InstrumentType = map.InstrumentType  
  WHERE stage.GUID = @Guid  
  
  
  
  SELECT  
    @SegmentId AS RefSegmentId,  
    stage.UniqueId, -- Code  
    stage.Symbol AS Name,  -- Name  
    stage.Symbol AS ScripId,  -- ScripId  
    stage.PriceTick,  
    stage.AddedBy,  
    GETDATE() AS AddedOn,  
    stage.AddedBy AS LastEditedBy,  
    GETDATE() AS EditedOn,  
    insType.RefInstrumentTypeId,  
    stage.ExpiryDate,  
    stage.TradableLot,  
    stage.PutCall, -- PutCall ,  
    stage.OptionStyle, -- OptionStyle ,  
    stage.StrikePrice,  
    NULL AS UnderlierId, -- UnderlierId ,  
    stage.UnderlyingAsset,  
    stage.UnderlyingGroup,  
    stage.BasePrice,  
    stage.QuotationQuantity,  
    stage.QuotationUnit,  
    stage.UniqueIdMappedAuctionBuyInProduct,  
    stage.UniqueIdMappedAuctionSellOutProduct,  
    stage.NearMonthProductUniqueId,  
    stage.FarMonthProductUniqueId,  
    stage.ProductStartDateTime,  
    stage.ProductEndDateTime,  
    stage.TenderStartDateTime,  
    stage.TenderEndDate,  
    stage.DeliveryStartDate,  
    stage.DeliveryEndDate,  
    stage.ExpiryProcessDate,  
    stage.MarginIndicator,  
    stage.RegularBuyMargin,  
    stage.RegularSellMargin,  
    stage.SpecialBuyMargin,  
    stage.SpecialSellMargin,  
    stage.TenderBuyMargin,  
    stage.TenderSellMargin,  
    stage.DeliveryBuyMargin,  
    stage.DeliverySellMargin,  
    stage.LimitForAllClient,  
    stage.LimitForOnlyAllClient,  
    stage.LimitForOnlyAllOwn,  
    stage.LimitPerClientAccount,  
    stage.LimitPerOwnAccount,  
    stage.SpreadBenefitAllowed,  
    stage.RecordDeleted,  
    stage.Remarks,  
    stage.PriceNumerator,  
    stage.PriceDenominator,  
    stage.GeneralNumerator,  
    stage.GeneralDenominator,  
    stage.LotNumerator,  
    stage.LotDenominator,  
    stage.DecimalLocator,  
    stage.BlockDeal,  
    stage.CurrencyCode,  
    stage.DeliveryWeight,  
    stage.DeliveryUnit,  
    stage.ProductMonth,  
    stage.TradeGroupId,  
    stage.MatchingNo,  
    stage.PreOpenSession,  
    stage.SpreadType,  
    stage.ProductDescription,  
    stage.OptionPricingMethod INTO #StagingMcxInstrument  
  FROM dbo.StagingMcxInstrument stage  
  LEFT JOIN dbo.RefInstrumentType insType  
    ON stage.InstrumentType = insType.InstrumentType  
  WHERE [GUID] = @Guid  
  AND NOT EXISTS (SELECT  
    1  
  FROM dbo.RefInstrument inst  
  WHERE inst.RefSegmentId = @SegmentId  
  AND ISNULL(inst.ContractSize,0) = ISNULL(stage.TradableLot,0)
  AND inst.Code = stage.UniqueId  
  AND ISNULL(inst.ExpiryDate, '1-Jan-1900') = ISNULL(stage.ExpiryDate, '1-Jan-1900')  
  AND ISNULL(inst.PutCall, '') = ISNULL(stage.PutCall, '')  
  AND ISNULL(inst.OptionStyle, '') = ISNULL(stage.OptionStyle, '')  
  AND ISNULL(inst.StrikePrice, 0) = ISNULL(stage.StrikePrice, 0))  
  
  
  INSERT INTO dbo.RefInstrument (RefSegmentId,  
  Code,  
  Name,  
  ScripId,  
  TickSize,  
  AddedBy,  
  AddedOn,  
  LastEditedBy,  
  EditedOn,  
  RefInstrumentTypeId,  
  ExpiryDate,  
  ContractSize,  
  PutCall,  
  OptionStyle,  
  StrikePrice,  
  UnderlierId,  
  UnderlyingAsset,  
  UnderlyingGroup,  
  BasePrice,  
  QuotationQuantity,  
  QuotationUnit,  
  UniqueIdMappedAuctionBuyInProduct,  
  UniqueIdMappedAuctionSellOutProduct,  
  NearMonthProductUniqueId,  
  FarMonthProductUniqueId,  
  ProductStartDateTime,  
  ProductEndDateTime,  
  TenderStartDateTime,  
  TenderEndDate,  
  DeliveryStartDate,  
  DeliveryEndDate,  
  ExpiryProcessDate,  
  MarginIndicator,  
  RegularBuyMargin,  
  RegularSellMargin,  
  SpecialBuyMargin,  
  SpecialSellMargin,  
  TenderBuyMargin,  
  TenderSellMargin,  
  DeliveryBuyMargin,  
  DeliverySellMargin,  
  LimitForAllClient,  
  LimitForOnlyAllClient,  
  LimitForOnlyAllOwn,  
  LimitPerClientAccount,  
  LimitPerOwnAccount,  
  SpreadBenefitAllowed,  
  RecordDeleted,  
  Remarks,  
  PriceNumerator,  
  PriceDenominator,  
  GeneralNumerator,  
  GeneralDenominator,  
  LotNumerator,  
  LotDenominator,  
  DecimalLocator,  
  BlockDeal,  
  CurrencyCode,  
  DeliveryWeight,  
  DeliveryUnit,  
  ProductMonth,  
  TradeGroupId,  
  MatchingNo,  
  PreOpenSession,  
  SpreadType,  
  ProductDescription,  
  OptionPricingMethod)  
    SELECT  
      stage.RefSegmentId,  
      stage.UniqueId, -- Code  
      stage.Name,  -- Name  
      stage.ScripId,  -- ScripId  
      stage.PriceTick,  
      stage.AddedBy,  
      stage.AddedOn,  
      stage.AddedBy AS LastEditedBy,  
      stage.EditedOn,  
      stage.RefInstrumentTypeId,  
      stage.ExpiryDate,  
      stage.TradableLot,  
      stage.PutCall, -- PutCall ,  
      stage.OptionStyle, -- OptionStyle ,  
      stage.StrikePrice,  
      stage.UnderlierId, -- UnderlierId ,  
      stage.UnderlyingAsset,  
      stage.UnderlyingGroup,  
      stage.BasePrice,  
      stage.QuotationQuantity,  
      stage.QuotationUnit,  
      stage.UniqueIdMappedAuctionBuyInProduct,  
      stage.UniqueIdMappedAuctionSellOutProduct,  
      stage.NearMonthProductUniqueId,  
      stage.FarMonthProductUniqueId,  
      stage.ProductStartDateTime,  
      stage.ProductEndDateTime,  
      stage.TenderStartDateTime,  
      stage.TenderEndDate,  
      stage.DeliveryStartDate,  
      stage.DeliveryEndDate,  
      stage.ExpiryProcessDate,  
      stage.MarginIndicator,  
      stage.RegularBuyMargin,  
      stage.RegularSellMargin,  
      stage.SpecialBuyMargin,  
      stage.SpecialSellMargin,  
      stage.TenderBuyMargin,  
      stage.TenderSellMargin,  
      stage.DeliveryBuyMargin,  
      stage.DeliverySellMargin,  
      stage.LimitForAllClient,  
      stage.LimitForOnlyAllClient,  
      stage.LimitForOnlyAllOwn,  
      stage.LimitPerClientAccount,  
      stage.LimitPerOwnAccount,  
      stage.SpreadBenefitAllowed,  
      stage.RecordDeleted,  
      stage.Remarks,  
      stage.PriceNumerator,  
      stage.PriceDenominator,  
      stage.GeneralNumerator,  
      stage.GeneralDenominator,  
      stage.LotNumerator,  
      stage.LotDenominator,  
      stage.DecimalLocator,  
      stage.BlockDeal,  
      stage.CurrencyCode,  
      stage.DeliveryWeight,  
      stage.DeliveryUnit,  
      stage.ProductMonth,  
      stage.TradeGroupId,  
      stage.MatchingNo,  
      stage.PreOpenSession,  
      stage.SpreadType,  
      stage.ProductDescription,  
      stage.OptionPricingMethod  
    FROM #StagingMcxInstrument AS stage  
  
  SELECT  
    RefInstrument.RefInstrumentId INTO #StagingRefinstrumentInsert  
 FROM dbo.RefInstrument RefInstrument  
  INNER JOIN StagingMcxInstrument stage  
    ON stage.UnderlyingUniqueId = RefInstrument.Code  
  WHERE stage.GUID = @Guid  
  AND RefInstrument.UnderlierId IS NULL  
  AND RefInstrument.RefSegmentId = @SegmentId  
  -- update the underlier  
  UPDATE inst  
  SET UnderlierId = inst.RefInstrumentId  
  FROM dbo.RefInstrument inst  
  INNER JOIN #StagingRefinstrumentInsert stage  
    ON inst.RefInstrumentId = stage.RefInstrumentId  
  WHERE stage.RefInstrumentId IS NOT NULL  
  
  DELETE FROM dbo.StagingMcxInstrument  
  
END  
GO
----------- RC ends ----------
------------ WEB-62858 RC starts------------
GO
	ALTER TABLE dbo.RefInstrument
	DROP CONSTRAINT UQ_RefInstrument
GO
ALTER TABLE dbo.RefInstrument
	ADD CONSTRAINT UQ_RefInstrument
	UNIQUE NONCLUSTERED (
	[RefSegmentId] ASC,
	[ContractSize] ASC,
	[Code] ASC,
	[Series] ASC,
	[ExpiryDate] ASC,
	[PutCall] ASC,
	[OptionStyle] ASC,
	[StrikePrice] ASC)
Go
-------------RC Ends-------------