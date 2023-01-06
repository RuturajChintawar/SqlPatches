 ---------------------Alert Register RC------------------
 GO
 ALTER PROCEDURE [dbo].[CoreAlert_SearchExchangeAlerts]        
(        
 @Segments VARCHAR(100) = null,        
 @FromDate DateTime = NULL,        
 @ToDate DateTime = NULL,        
 @TransactionFromDate DateTime = NULL,        
 @TransactionToDate DateTime = NULL,        
 @AlertType Varchar(100) = NULL,        
 @Client Varchar(100) = NULL,        
 @Instrument VARCHAR(100) = NULL,        
 @Status INT = NULL,        
 @Comments Varchar(500) = NULL,        
 @AddedOnFromDate DateTime = NULL,        
 @AddedOnToDate DATETIME = NULL,        
 @EditedOnFromDate DateTime = NULL,        
 @EditedOnToDate DATETIME = NULL,        
 @RowsPerPage INT = 100,            
 @PageNumber INT = 1        
)        
AS        
BEGIN        
        
 DECLARE        
 @InternalSegments VARCHAR(100),        
 @InternalFromDate DateTime,        
 @InternalToDate DateTime,        
 @InternalTransactionFromDate DateTime,        
 @InternalTransactionToDate DateTime,        
 @InternalAlertType Varchar(100),        
 @InternalClient Varchar(100),        
 @InternalInstrument VARCHAR(100),        
 @InternalStatus INT,        
 @InternalComments Varchar(500),        
 @InternalAddedOnFromDate DateTime,        
 @InternalAddedOnToDate DATETIME,        
 @InternalEditedOnFromDate DateTime ,        
 @InternalEditedOnToDate DATETIME ,        
 @InternalRowsPerPage INT,        
 @InternalPageNumber INT        
         
 SET @InternalSegments=@Segments;        
 SET @InternalFromDate=dbo.GetDateWithoutTime(@FromDate);        
 SET @InternalToDate=CONVERT(DATETIME,DATEDIFF(dd, 0,dbo.GetDateWithoutTime(@ToDate))) + CONVERT(DATETIME,'23:59:59.000');        
 SET @InternalTransactionFromDate=dbo.GetDateWithoutTime(@TransactionFromDate);        
 SET @InternalTransactionToDate=CONVERT(DATETIME,DATEDIFF(dd, 0,dbo.GetDateWithoutTime(@TransactionToDate))) + CONVERT(DATETIME,'23:59:59.000');        
 SET @InternalAlertType=@AlertType;        
 SET @InternalClient=@Client;        
 SET @InternalInstrument=@Instrument;        
 SET @InternalStatus=@Status;        
 SET @InternalComments=@Comments;        
 SET @InternalAddedOnFromDate=@AddedOnFromDate;        
 SET @InternalAddedOnToDate=CONVERT(DATETIME,DATEDIFF(dd, 0,dbo.GetDateWithoutTime(@AddedOnToDate))) + CONVERT(DATETIME,'23:59:59.000');        
 SET @InternalRowsPerPage=@RowsPerPage;        
 SET @InternalPageNumber=@PageNumber;        
 SET @InternalEditedOnFromDate=@EditedOnFromDate;        
 SET @InternalEditedOnToDate=CONVERT(DATETIME,DATEDIFF(dd, 0,dbo.GetDateWithoutTime(@EditedOnToDate))) + CONVERT(DATETIME,'23:59:59.000');        
         
 SELECT t.items AS Segment          
  INTO #SegmentEnums          
  FROM dbo.Split(@InternalSegments,',') t        
        
SELECT  alr.CoreAlertId,        
 ROW_NUMBER() OVER ( ORDER BY alr.AddedOn DESC ) AS RowNumber         
  INTO #tempdata        
FROM dbo.CoreAlert alr        
INNER JOIN dbo.RefSegmentEnum seg ON alr.RefSegmentId=seg.RefSegmentEnumId        
INNER JOIN #SegmentEnums segid ON seg.Segment=segid.Segment        
INNER JOIN dbo.RefClient cli ON cli.RefClientId=alr.RefClientId        
LEFT JOIN dbo.RefInstrument ins ON alr.RefInstrumentId=ins.RefInstrumentId        
LEFT JOIN dbo.RefAlertType alt on alt.RefAlertTypeId=alr.RefAlertTypeId        
WHERE (@InternalFromDate IS NULL AND @InternalToDate IS NULL OR(alr.AlertDate >=@InternalFromDate AND alr.AlertDate <=@InternalToDate))        
 AND (@InternalTransactionFromDate IS NULL AND @InternalTransactionToDate IS NULL OR(alr.AlertDate >=@InternalTransactionFromDate AND alr.AlertDate <=@InternalTransactionToDate))        
 AND(@InternalAddedOnFromDate IS NULL AND @InternalAddedOnToDate IS NULL OR(alr.AddedOn >=@InternalAddedOnFromDate AND alr.AddedOn<=@InternalAddedOnToDate))        
 AND (@InternalEditedOnFromDate IS NULL AND @InternalEditedOnToDate IS NULL OR(alr.EditedOn >=@InternalEditedOnFromDate AND alr.EditedOn<=@InternalEditedOnToDate))        
 and (@InternalAlertType IS NULL OR alt.Code=@InternalAlerttype)        
 AND (@InternalClient IS NULL OR (cli.ClientId LIKE '%'+@InternalClient+'%' OR cli.Name='%'+@InternalClient+'%'))        
 AND (@InternalInstrument IS NULL OR (ins.Code='%'+@InternalInstrument+'%' OR ins.Name='%'+@InternalInstrument+'%'))        
 AND (@InternalStatus IS NULL OR (alr.[Status]=@InternalStatus))        
 AND (@InternalComments IS NULL OR (alr.Comments='%'+@InternalComments+'%'))        
 AND (@InternalInstrument IS NULL OR (ins.Code='%'+@InternalInstrument+'%' OR ins.Name='%'+@InternalInstrument+'%'))        
        
         
        
        
 SELECT  t.*        
 into #alertdata        
 FROM    #tempdata t        
 WHERE   t.RowNumber BETWEEN ( ( ( @InternalPageNumber - 1 )        
                                         * @InternalRowsPerPage ) + 1 )        
                             AND     @InternalPageNumber * @InternalRowsPerPage        
 ORDER BY t.CoreAlertId DESC        
        
        
 SELECT alr.CoreAlertId,        
 alt.RefAlertTypeId,        
 alt.Name As AlterType,        
 alt.Code As AlterTypeCode,        
 cli.RefClientId,        
 cli.ClientId As ClientId,        
 cli.Name As ClientName,        
 cli.Email As Email,        
 cli.Mobile As Mobile,        
 cli.PAN As PAN,        
 income.LinkRefClientRefIncomeGroupId,        
 ISNULL(income.Income, incomegrp.IncomeTo) AS Income,        
 incomegrp.RefIncomeGroupId,        
 incomegrp.Name AS IncomeGroupName,        
 intr.IntermediaryCode,        
 intr.Name As IntermediaryName,        
 intr.RefIntermediaryId,        
 cli.Gender As Gender,        
 bcli.RefClientId AS BigRefClientId,        
 bcli.Name As BigClientName,        
 alft.RefAlertFrequencyTypeId,        
 alft.Name As AlertFrequencyType,        
 seg.REfSegmentEnumId,        
 seg.Segment,        
 exst.RefExchangeStatusId,        
 exst.Name AS ExchangeStatus,        
 alr.AlertDate,        
 alr.InstrumentCode,        
 alr.TradeDate,        
 alr.MemberId,        
 alr.CurrentPeriod,        
 alr.CurrentTurnover,        
 alr.PreviousPeriod,        
 alr.PreviousTurnover,        
 alr.PercentIncrease,        
 alr.ClientBuyQuantity,        
 alr.ClientSellQuantity,        
 alr.ClientBuyValue,        
 alr.ClientSellValue,        
 alr.MemberBuyQuantity,        
 alr.MemberSellQuantity,        
 alr.MemberBuyValue,        
 alr.MemberSellValue,        
 alr.GrossScripQuantity,        
 alr.MemberScripQuantity,        
 alr.MemberScripPercent,        
 alr.Top5ClientBuyValue,        
 alr.Top5ClientSellValue,        
 alr.AggregateClientPercentage,        
 alr.PercentClientMemberConcentration,        
 alr.PercentClientMarketConcentation AS PercentClientMarketConcentration,        
 alr.InstrumentSeries,        
 alr.NotionalSquareOffDifference,        
 alr.PercentFrontRunClientBigClientBuyMatch,        
 alr.PercentFrontRunClientBigClientSellMatch,        
 alr.FrontRunnerProfit,        
 alr.ClientPan,        
 alr.IsExchangeInformed,        
 alr.TradeNo,        
 alr.TradeTime,        
 alr.TradePrice,        
 alr.TradeQuantity,        
 alr.TradeValue,        
 alr.BuyTradingMemberId,        
 alr.SellTradingMemberId,        
 alr.BuyClientId,        
 alr.SellClientId,        
 alr.BuyTradingMemberName,        
 alr.SellTradingMemberName,        
 alr.BuyClientName,        
 alr.BuyClientPan,        
 alr.SellClientName,        
 alr.SellClientPan,        
 alr.AlertClosedDate,        
 alr.LimitPrice,        
 alr.OriginalVolume,        
 alr.VolumeDisclosed,        
 alr.LtpVariation,        
 alr.BuySell,        
 alr.OrderNumber,        
 alr.UnderlyingPrice,        
 alr.OptionType,        
 alr.StrikePrice,        
 alr.ExpiryDate,        
 alr.Part,        
 alr.TotalSelfQuantity,        
 alr.Total_Buy_Qty,        
 alr.Total_Sell_Qty,        
 alr.Total_Pan_Symbol_Spoof_qty,        
 alr.Profit,        
 alr.ClientGrossValue,        
 alr.CurrentMonthAdtv,        
 alr.AdtvOfThreeMonths,       
 alr.AdtvOfSixMonths,    
 alr.NoOfTimes,        
 alr.TMID,        
 alr.LongOI,        
 alr.ShortOI,        
 alr.LongOIPer,        
 alr.ShortOIPer,        
 alr.Symbol,        
 alr.UORLAsset,        
 alr.OIComputationMethod,        
 alr.OpenPositionClient,        
 alr.OpenPositionExchange,        
 alr.PercentageofClient,        
 alr.CurrentPeriodFromDate,        
 alr.CurrentPeriodToDate,        
 alr.PreviousPeriodFromDate,        
 alr.PreviousPeriodToDate,        
 alr.CurrentPeriodAvgDailyTurnover,        
 alr.PreviousPeriodAvgDailyTurnover,        
 alr.PercentageIncreaseInTurnover,        
 alr.DateofUCCRegistration,        
 alr.LastTradePriorToPreviousPeriod,        
 alr.FromDate,        
 alr.ToDate,        
 alr.ClientTurnoverInLakh,        
 alr.ExchangeLevelTurnoverOfTheCommodityInLakh,        
 alr.AddedBy,        
 alr.AddedOn,        
 alr.LastEditedBy,        
 alr.EditedOn,        
 alr.CoreAlertRegisterCaseId,        
 alr.[Status] AS StatusType,        
 alr.AlertReferenceNo,        
 alr.CommReferenceNo,        
 alr.Comments,        
 alr.ClientExplanation,        
 alr.[Message],        
 alr.InstrumentName,        
 alr.MemberName,        
 alr.GroupAlertNo,        
 alr.OtherClients,        
 alr.[FileName],        
 risk.[Name] AS RiskName,        
 alr.OrderCancellation,        
 alr.OppTradeQuantity,        
 alr.OppTradeValue,        
 alr.OrderQuantity,        
 alr.CloseOutDifference,        
 alr.InstrumentType,        
 alr.OptionTurnoverBasedOn,        
 alr.CcdCategory,        
 alert.RowNumber,      
 alr.OriginalTime,      
 alr.SellOrderEnts,      
 alr.SellOrderNumber,      
 alr.TradeNoAlphaNumeric,      
 alr.TimeDifference,      
 alr.TransactionCode,      
 alr.OrderType,      
 alr.StartLastTradedPrice,      
 alr.EndLastTradedPrice,      
 alr.AccountType,      
 alr.[Contract],      
 alr.TotalBidQuantity,    
 alr.SellQuantity,    
 alr.TotalOfferQuantity,    
 alr.DNP,  
 alr.EndTime    
 --INTO #temp        
 FROM dbo.CoreAlert alr        
 INNER JOIN #alertdata alert ON alert.CoreAlertId=alr.CoreAlertId        
 INNER JOIN dbo.RefSegmentEnum seg ON alr.RefSegmentId=seg.RefSegmentEnumId        
 INNER JOIN dbo.RefClient cli ON alr.RefClientId=cli.RefClientId        
 LEFT JOIN dbo.RefClient bcli ON alr.BigClientId=bcli.RefClientId        
 LEFT JOIN dbo.RefIntermediary intr ON cli.RefIntermediaryId=intr.RefIntermediaryId        
 LEFT JOIN dbo.LinkRefClientRefIncomeGroupLatest income ON cli.RefClientId=income.RefClientId        
 LEFT JOIN dbo.RefIncomeGroup incomegrp ON income.RefIncomeGroupId=incomegrp.RefIncomeGroupId        
 LEFT JOIN dbo.RefAlertType alt ON alr.RefAlertTypeId=alt.RefAlertTypeId        
 LEFT JOIN dbo.RefAlertFrequencyType alft ON alr.RefAlertFrequencyTypeId=alft.RefAlertFrequencyTypeId        
 LEFT JOIN dbo.RefExchangeStatus exst ON alr.RefExchangeStatusId=exst.RefExchangeStatusId        
 LEFT JOIN dbo.LinkRefClientRefRiskCategoryLatest linkcrc ON cli.RefClientId=linkcrc.RefClientId        
 LEFT JOIN dbo.RefRiskCategory risk ON linkcrc.RefRiskCategoryId=risk.RefRiskCategoryId        
 ORDER BY CoreAlertID        
        
        
                 
 SELECT  COUNT(1)        
 FROM    #tempdata        
        
END   
GO
----------------------RC ENds----------------
-----------------------RC Starts Case Manager-------------

GO
ALTER PROCEDURE [dbo].[CoreAlert_GetExchangeAlerts]        
(        
	@CaseId INT = NULL,        
	@Segments VARCHAR(100) = NULL,        
	@AlertType VARCHAR(100) = NULL,        
	@RowsPerPage INT = 20 ,            
	@PageNumber INT = 1        
)        
AS        
BEGIN        
        
	DECLARE        
		@InternalCaseId INT,        
		@InternalSegments VARCHAR(100),        
		@InternalAlertType VARCHAR(100),        
		@InternalRowsPerPage INT,        
		@InternalPageNumber INT        
	        
	SET @InternalCaseId=@CaseId;        
	SET @InternalSegments=@Segments;        
	SET @InternalAlertType=@AlertType;        
	SET @InternalRowsPerPage=@RowsPerPage;        
	SET @InternalPageNumber=@PageNumber;        
         
	SELECT t.items AS Segment          
	INTO #SegmentEnums          
	FROM dbo.Split(@InternalSegments,',') t        
         
    SELECT   
		alert.CoreAlertId,
		ROW_NUMBER() OVER ( ORDER BY alert.AddedOn DESC ) AS RowNumber   
	INTO #alerts
	FROM dbo.CoreAlert alert
	INNER JOIN dbo.RefAlertType alt ON alert.RefAlertTypeId=alt.RefAlertTypeId        
	WHERE         
	(
		@InternalCaseId IS NULL OR alert.CoreAlertRegisterCaseId=@InternalCaseId
	)        
	AND 
	(
		@InternalAlertType IS NULL OR alt.Code=@InternalAlertType
	)        
	ORDER BY alert.CoreAlertId        
         
         
	 SELECT  t.CoreAlertId
	 INTO #filtredAlert       
	 FROM    #alerts t        
	 WHERE   t.RowNumber BETWEEN ( ( ( @InternalPageNumber - 1 )        
									 * @InternalRowsPerPage ) + 1 )        
						 AND     @InternalPageNumber * @InternalRowsPerPage   
						      
	ORDER BY t.CoreAlertId DESC   
	 SELECT 
		 alr.CoreAlertId,        
		 alt.RefAlertTypeId,        
		 alt.Name As AlterType,        
		 alt.Code As AlterTypeCode,        
		 cli.RefClientId,        
		 cli.ClientId As ClientId,        
		 cli.Name As ClientName,        
		 cli.Email As Email,        
		 cli.Mobile As Mobile,        
		 cli.PAN As PAN,        
		 cli.Gender As Gender,        
		 bcli.RefClientId AS BigRefClientId,        
		 bcli.Name As BigClientName,        
		 alft.RefAlertFrequencyTypeId,        
		 alft.Name As AlertFrequencyType,        
		 seg.REfSegmentEnumId,        
		 seg.Segment,        
		 exst.RefExchangeStatusId,        
		 exst.Name AS ExchangeStatus,        
		 alr.AlertDate,        
		 alr.InstrumentCode,        
		 alr.TradeDate,        
		 alr.MemberId,        
		 alr.CurrentPeriod,        
		 alr.CurrentTurnover,        
		 alr.PreviousPeriod,        
		 alr.PreviousTurnover,        
		 alr.PercentIncrease,        
		 alr.ClientBuyQuantity,        
		 alr.ClientSellQuantity,        
		 alr.ClientBuyValue,        
		 alr.ClientSellValue,        
		 alr.MemberBuyQuantity,        
		 alr.MemberSellQuantity,        
		 alr.MemberBuyValue,        
		 alr.MemberSellValue,        
		 alr.GrossScripQuantity,        
		 alr.MemberScripQuantity,        
		 alr.MemberScripPercent,        
		 alr.Top5ClientBuyValue,        
		 alr.Top5ClientSellValue,        
		 alr.AggregateClientPercentage,        
		 alr.PercentClientMemberConcentration,        
		 alr.PercentClientMarketConcentation AS PercentClientMarketConcentration,        
		 alr.InstrumentSeries,        
		 alr.NotionalSquareOffDifference,        
		 alr.PercentFrontRunClientBigClientBuyMatch,        
		 alr.PercentFrontRunClientBigClientSellMatch,        
		 alr.FrontRunnerProfit,        
		 alr.ClientPan,        
		 alr.IsExchangeInformed,        
		 alr.TradeNo,        
		 alr.TradeTime,        
		 alr.TradePrice,        
		 alr.TradeQuantity,        
		 alr.TradeValue,        
		 alr.BuyTradingMemberId,        
		 alr.SellTradingMemberId,        
		 alr.BuyClientId,        
		 alr.SellClientId,        
		 alr.BuyTradingMemberName,        
		 alr.SellTradingMemberName,        
		 alr.BuyClientName,        
		 alr.BuyClientPan,        
		 alr.SellClientName,        
		 alr.SellClientPan,        
		 alr.AlertClosedDate,        
		 alr.LimitPrice,        
		 alr.OriginalVolume,        
		 alr.VolumeDisclosed,        
		 alr.LtpVariation,        
		 alr.BuySell,        
		 alr.OrderNumber,        
		 alr.UnderlyingPrice,        
		 alr.OptionType,        
		 alr.StrikePrice,        
		 alr.ExpiryDate,        
		 alr.Part,        
		 alr.TotalSelfQuantity,        
		 alr.Total_Buy_Qty,        
		 alr.Total_Sell_Qty,        
		 alr.Total_Pan_Symbol_Spoof_qty,        
		 alr.Profit,        
		 alr.ClientGrossValue,        
		 alr.CurrentMonthAdtv,        
		 alr.AdtvOfThreeMonths,    
		 alr.AdtvOfSixMonths,    
		 alr.NoOfTimes,        
		 alr.TMID,        
		 alr.LongOI,        
		 alr.ShortOI,        
		 alr.LongOIPer,        
		 alr.ShortOIPer,        
		 alr.Symbol,        
		 alr.UORLAsset,        
		 alr.OIComputationMethod,        
		 alr.OpenPositionClient,        
		 alr.OpenPositionExchange,        
		 alr.PercentageofClient,        
		 alr.CurrentPeriodFromDate,        
		 alr.CurrentPeriodToDate,        
		 alr.PreviousPeriodFromDate,        
		 alr.PreviousPeriodToDate,        
		 alr.CurrentPeriodAvgDailyTurnover,        
		 alr.PreviousPeriodAvgDailyTurnover,        
		 alr.PercentageIncreaseInTurnover,        
		 alr.DateofUCCRegistration,        
		 alr.LastTradePriorToPreviousPeriod,        
		 alr.FromDate,        
		 alr.ToDate,        
		 alr.ClientTurnoverInLakh,        
		 alr.ExchangeLevelTurnoverOfTheCommodityInLakh,        
		 alr.AddedBy,        
		 alr.AddedOn,        
		 alr.LastEditedBy,        
		 alr.EditedOn,        
		 alr.CoreAlertRegisterCaseId,        
		 alr.[Status] AS StatusType,   
		-- clink.LinkRefClientRefIncomeGroupId,        
		----clink.RefClientId,        
		-- ig.RefIncomeGroupId,        
		-- clink.Income,        
		-- clink.Networth,        
		----clink.FromDate,        
		----clink.ToDate,        
		--ig.Name as IncomeGroup,        
		-- ig.IncomeFrom,        
		-- ig.IncomeTo,        
         
		 inter.RefIntermediaryId,        
		 inter.Name AS IntermediaryName,        
		 inter.IntermediaryCode,        
		 inter.TradeName,        
		 alr.Comments,        
		 alr.CommReferenceNo,        
		 alr.AlertReferenceNo,        
		-- risk.Name AS RiskName,        
		 alr.[Message],        
		 alr.InstrumentName,        
		 alr.MemberName,        
		 alr.ClientExplanation,        
		 alr.OrderCancellation,        
		 alr.OppTradeQuantity,        
		 alr.OppTradeValue,        
		 alr.OrderQuantity,        
		 alr.CloseOutDifference,        
		 alr.InstrumentType,        
		 alr.OptionTurnoverBasedOn,        
		 alr.CcdCategory,        
		 alr.OriginalTime,      
		 alr.SellOrderEnts,      
		 alr.SellOrderNumber,      
		 alr.TransactionCode,      
		 alr.OrderType,      
		 alr.StartLastTradedPrice,      
		 alr.EndLastTradedPrice,      
		 alr.TradeNoAlphaNumeric,      
		 alr.TimeDifference,      
		 alr.AccountType,      
		 alr.[Contract],     
		 alr.TotalBidQuantity,    
		 alr.SellQuantity,    
		 alr.TotalOfferQuantity,    
		 alr.DNP,     
		 alr.EndTime
		--temp.RowNumber         
	 INTO #temp        
	 FROM #filtredAlert temp 
	 INNER JOIN dbo.CoreAlert alr  ON alr.CoreAlertId = temp.CoreAlertId      
	 INNER JOIN dbo.RefSegmentEnum seg ON alr.RefSegmentId=seg.RefSegmentEnumId        
	 INNER JOIN #SegmentEnums segid ON seg.Segment=segid.Segment        
	 INNER JOIN dbo.RefClient cli ON alr.RefClientId=cli.RefClientId            
	 INNER JOIN dbo.RefAlertType alt ON alr.RefAlertTypeId=alt.RefAlertTypeId 
	 LEFT JOIN dbo.RefClient bcli ON alr.BigClientId=bcli.RefClientId        
	 LEFT JOIN dbo.RefInstrument ins ON alr.RefInstrumentId=ins.RefInstrumentId        
	 LEFT JOIN dbo.RefAlertFrequencyType alft ON alr.RefAlertFrequencyTypeId=alft.RefAlertFrequencyTypeId        
	 LEFT JOIN dbo.RefExchangeStatus exst ON alr.RefExchangeStatusId=exst.RefExchangeStatusId        
	-- LEFT JOIN dbo.LinkRefClientRefIncomeGroupLatest clink ON cli.RefClientId=clink.RefClientId        
	-- left JOIN dbo.RefIncomeGroup ig ON ig.RefIncomeGroupId=clink.RefIncomeGroupId        
	 LEFT JOIN dbo.RefIntermediary inter ON cli.RefIntermediaryId=inter.RefIntermediaryId        
	-- LEFT JOIN dbo.LinkRefClientRefRiskCategoryLatest linkcrc ON cli.RefClientId=linkcrc.RefClientId        
	 --LEFT JOIN dbo.RefRiskCategory risk ON linkcrc.RefRiskCategoryId=risk.RefRiskCategoryId       

	SELECT  temp.* , temp2.LinkRefClientRefIncomeGroupId,        
		--clink.RefClientId,        
		 temp2.RefIncomeGroupId,        
		 temp2.Income,        
		 temp2.Networth,        
		--clink.FromDate,        
		--clink.ToDate,        
		igrp.Name as IncomeGroup,        
		 temp2.FromDate AS IncomeFrom,        
		 temp2.ToDate AS IncomeTo,   
		 rc.Name AS RiskName 
	FROM #temp temp 
	LEFT JOIN (
		SELECT              
			  l.RefClientId,        
			  l.RefRiskCategoryId     
				FROM (SELECT             
				  l.RefClientId,        
				  l.RefRiskCategoryId,          
				  ROW_NUMBER() OVER (PARTITION BY l.RefClientId ORDER BY ISNULL(l.ToDate, '31-Dec-9999') DESC,l.LinkRefClientRefRiskCategoryId DESC  ) AS RowNum        
			FROM dbo.LinkRefClientRefRiskCategory l
			INNER JOIN #temp t ON t.RefClientId = l.RefClientId
		) l        
		WHERE l.RowNum = 1 
	) temp1 ON temp1.RefClientId =  temp.RefClientId
	LEFT JOIN dbo.RefRiskCategory rc ON temp1.RefRiskCategoryId = rc.RefRiskCategoryId
	LEFT JOIN (
		SELECT     
		lnkci.LinkRefClientRefIncomeGroupId,
		lnkci.Income,
		lnkci.Networth,  
		lnkci.RefClientId,  
		lnkci.RefIncomeGroupId ,
		lnkci.FromDate,
		lnkci.ToDate,
		lnkci.RowNum
		FROM        
		(
			SELECT
			lnkci.LinkRefClientRefIncomeGroupId,
			lnkci.RefClientId,  
			lnkci.RefIncomeGroupId,   
			lnkci.Networth,  
			ISNULL(lnkci.Income, gp.IncomeTo) AS Income, 
			lnkci.FromDate,
			lnkci.ToDate,
			ROW_NUMBER() OVER(PARTITION BY lnkci.RefClientId ORDER BY ISNULL(lnkci.ToDate,'31-Dec-9999') DESC) AS RowNum  
			FROM LinkRefClientRefIncomeGroup lnkci 
			INNER JOIN #temp t ON t.RefClientId = lnkci.RefClientId 
			INNER JOIN dbo.RefIncomeGroup gp ON gp.RefIncomeGroupId = lnkci.RefIncomeGroupId
		) lnkci  
		WHERE     lnkci .RowNum = 1  
	) temp2 ON temp2.RefClientId =  temp.RefClientId
	LEFT JOIN RefIncomeGroup igrp ON temp2.RefIncomeGroupId=igrp.RefIncomeGroupId
	 ORDER BY temp.CoreAlertId DESC 
	 SELECT  COUNT(1)        
	 FROM    #alerts  
	       
END       
GO

--------------------RC Ends --------------------