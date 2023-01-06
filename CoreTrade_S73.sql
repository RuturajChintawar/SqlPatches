GO
CREATE TABLE [dbo].[CoreTrade_S74](
	[CoreTradeId] [bigint] IDENTITY(1,1) NOT NULL,
	[RefSegmentId] [int] NOT NULL,
	[RefSettlementId] [int] NOT NULL,
	[RefInstrumentId] [int] NOT NULL,
	[RefClientId] [int] NOT NULL,
	[BuySell] [varchar](4) NOT NULL,
	[Rate] [decimal](19, 6) NOT NULL,
	[Quantity] [decimal](28, 4) NOT NULL,
	[MemberId] [varchar](20) NULL,
	[TraderId] [varchar](20) NULL,
	[OppMemberId] [varchar](20) NULL,
	[OppTraderId] [int] NULL,
	[TradeDateTime] [datetime] NOT NULL,
	[OrderId] [decimal](22, 0) NULL,
	[TransactionType] [varchar](10) NULL,
	[TradeId] [bigint] NOT NULL,
	[InstitutionId] [varchar](20) NULL,
	[OrderTimeStamp] [datetime] NOT NULL,
	[AoPoFlag] [varchar](1) NULL,
	[AddedBy] [varchar](50) NOT NULL,
	[AddedOn] [datetime] NOT NULL,
	[LastEditedBy] [varchar](50) NOT NULL,
	[EditedOn] [datetime] NOT NULL,
	[TradeDate] [datetime] NOT NULL,
	[ScripGroup] [varchar](15) NULL,
	[TradeStatus] [int] NULL,
	[InstrumentType] [int] NULL,
	[BookType] [int] NULL,
	[MarketType] [int] NULL,
	[BranchCode] [varchar](15) NULL,
	[ProClient] [int] NULL,
	[AuctionNumber] [int] NULL,
	[LastUpdateDate] [datetime] NULL,
	[AuctionPartType] [varchar](1) NULL,
	[SettlementPeriod] [int] NULL,
	[NseFnoFlag] [int] NULL,
	[OriginalRefClientId] [int] NULL,
	[IsSplitTrade] [bit] NULL,
	[TradingBrokerage] [decimal](19, 4) NULL,
	[DeliveryBrokerage] [decimal](19, 4) NULL,
	[Brokerage] [decimal](19, 4) NULL,
	[StampDutyTrading] [decimal](19, 4) NULL,
	[StampDutyDelivery] [decimal](19, 4) NULL,
	[ServiceTax] [decimal](19, 4) NULL,
	[ServiceTaxPrimaryCess] [decimal](19, 4) NULL,
	[ServiceTaxSecondaryCess] [decimal](19, 4) NULL,
	[SttTrading] [decimal](19, 4) NULL,
	[SttDelivery] [decimal](19, 4) NULL,
	[TOC] [decimal](19, 4) NULL,
	[NetRate] [decimal](19, 4) NULL,
	[OriginalTradeId] [bigint] NULL,
	[IsPmsTrade] [bit] NOT NULL,
	[ReportDate] [datetime] NULL,
	[MfOrderAmount] [decimal](28, 4) NULL,
	[FolioNo] [varchar](20) NULL,
	[RtaTransNo] [varchar](20) NULL,
	[MfBeneficiaryDematAccount] [varchar](16) NULL,
	[MfObligationAmount] [decimal](28, 4) NULL,
	[MfRemarks] [varchar](250) NULL,
	[MfInternalRefNo] [varchar](15) NULL,
	[MfOrderType] [varchar](4) NULL,
	[MfSipRegnNo] [bigint] NULL,
	[MfSipRegnDate] [datetime] NULL,
	[MfOrderQuantity] [decimal](28, 4) NULL,
	[SpreadPrice] [decimal](19, 4) NULL,
	[ClearingMemberCode] [varchar](10) NULL,
	[CustodialParticipantCode] [varchar](15) NULL,
	[CtclId] [bigint] NULL,
	[UniqueReferenceNo] [bigint] NULL,
	[OrderIdAlphaNumeric] [varchar](30) NULL,
	[TradeIdAlphaNumeric] [varchar](30) NULL,
	[StrikePrice] [decimal](19, 4) NULL,
	[OptionType] [varchar](5) NULL,
	[PutCall] [varchar](1) NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[CoreTrade_S74] ADD  DEFAULT ((0)) FOR [IsPmsTrade]
GO

ALTER TABLE [dbo].[CoreTrade_S74]  WITH CHECK ADD  CONSTRAINT [FK_CoreTrade_S74_RefClientId] FOREIGN KEY([RefClientId])
REFERENCES [dbo].[RefClient] ([RefClientId])
GO

ALTER TABLE [dbo].[CoreTrade_S74] CHECK CONSTRAINT [FK_CoreTrade_S74_RefClientId]
GO

ALTER TABLE [dbo].[CoreTrade_S74]  WITH CHECK ADD  CONSTRAINT [FK_CoreTrade_S74_RefInstrumentId] FOREIGN KEY([RefInstrumentId])
REFERENCES [dbo].[RefInstrument] ([RefInstrumentId])
GO

ALTER TABLE [dbo].[CoreTrade_S74] CHECK CONSTRAINT [FK_CoreTrade_S74_RefInstrumentId]
GO

ALTER TABLE [dbo].[CoreTrade_S74]  WITH CHECK ADD  CONSTRAINT [FK_CoreTrade_S74_RefSegmentId] FOREIGN KEY([RefSegmentId])
REFERENCES [dbo].[RefSegmentEnum] ([RefSegmentEnumId])
GO

ALTER TABLE [dbo].[CoreTrade_S74] CHECK CONSTRAINT [FK_CoreTrade_S74_RefSegmentId]
GO

ALTER TABLE [dbo].[CoreTrade_S74]  WITH CHECK ADD  CONSTRAINT [FK_CoreTrade_S74_RefSettlementId] FOREIGN KEY([RefSettlementId])
REFERENCES [dbo].[RefSettlement] ([RefSettlementId])
GO

ALTER TABLE [dbo].[CoreTrade_S74] CHECK CONSTRAINT [FK_CoreTrade_S74_RefSettlementId]
GO

