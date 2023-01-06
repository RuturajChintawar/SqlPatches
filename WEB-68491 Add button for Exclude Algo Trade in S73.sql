--- rc -WEB-68491-start
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S73 Small Orders In Single Stock 15 Days'

INSERT INTO dbo.SysAmlReportSetting (
	RefAmlReportId,
	[Name],
	[Value],
	RefAmlQueryProfileId,
	DisplayName,
	DisplayOrder,
	AddedOn,
	AddedBy,
	EditedOn,
	LastEditedBy
) VALUES (
	@AmlReportId,
	'Exclude_AlgoTrade',
	'False',
	1,
	'Exclude Algo Trade',
	7,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
--- rc -WEB-68491-end
--- rc -WEB-68491-start
GO
 ALTER PROCEDURE dbo.Aml_GetSmallOrdersInSingleStock  
(  
    @FromDate DATETIME,  
    @ToDate DATETIME,  
    @QtyThreshold INT,  
    @PercentageThreshold DECIMAL (28,4),  
    @MinimumOrder INT,  
    @ExcludePro BIT,  
    @ExcludeInstitution BIT,  
    @ExcludedGroups VARCHAR(MAX),
	@ExcludeAlgoTrade BIT,
 @ReportId INT  
)  
AS  
BEGIN  
          
 DECLARE @FromDateInternal DATETIME, @ToDateInternal DATETIME, @QtyThresholdInternal INT,  
  @PercentageThresholdInternal DECIMAL(28,4), @MinimumOrderInternal INT, @ExcludeProInternal BIT,  
        @ExcludeInstitutionInternal BIT,@ExcludeAlgoTradeInternal BIT, @ExcludeGroupsInternal VARCHAR(MAX), @InstrumentRefEntityTypeId INT,   
  @EntityAttributeTypeRefEnumValueId INT, @ReportIdInternal INT, @BseSegmentId INT, @NseSegmentId INT  
          
    SET @FromDateInternal = @FromDate  
    SET @ToDateInternal = @ToDate  
    SET @QtyThresholdInternal = @QtyThreshold  
    SET @PercentageThresholdInternal = @PercentageThreshold  
    SET @MinimumOrderInternal = @MinimumOrder  
    SET @ExcludeProInternal = @ExcludePro  
    SET @ExcludeInstitutionInternal = @ExcludeInstitution  
    SET @ExcludeGroupsInternal = @ExcludedGroups  
	SET @ExcludeAlgoTradeInternal = @ExcludeAlgoTrade
 SET @ReportIdInternal = @ReportId  
 SELECT @InstrumentRefEntityTypeId = RefEntityTypeId FROM dbo.RefEntityType WHERE Code='Instrument'  
 SET @EntityAttributeTypeRefEnumValueId = dbo.GetEnumValueId('EntityAttributeType', 'UserDefined')  
 SET @BseSegmentId = dbo.GetSegmentId('BSE_CASH')  
 SET @NseSegmentId = dbo.GetSegmentId('NSE_CASH')  
   
    SELECT   
  seg.RefSegmentEnumId,  
        seg.Segment  
    INTO #RefSegmentEnum  
    FROM dbo.RefSegmentEnum seg  
    WHERE seg.Segment IN ('BSE_CASH','NSE_CASH')   
          
    SELECT   
  RefClientId,  
        RefInstrumentId,  
        TradeDate,  
        OrderId,                  
        Quantity,  
        Rate  
    INTO #FilterTrade         
    FROM dbo.CoreTrade trade  
    INNER JOIN #RefSegmentEnum en ON en.RefSegmentEnumid = trade.RefSegmentId  
    WHERE trade.TradeDate BETWEEN @FromDateInternal AND @ToDateInternal AND  (    
  @ExcludealgoTradeInternal = 0 OR (@ExcludealgoTradeInternal = 1 AND     
    LEN(CONVERT(VARCHAR(100), trade.CtclId)) = 15     
    AND SUBSTRING(CONVERT(VARCHAR(100), trade.CtclId), 13, 1) NOT IN ('0','2','4')))
	
 DROP TABLE #RefSegmentEnum  
      
    SELECT   
  trade.RefClientId,  
        trade.RefInstrumentId,  
        trade.TradeDate,  
        trade.OrderId,                
        SUM(trade.Quantity) AS OrderWiseQty,  
        SUM(trade.Quantity * trade.Rate) AS OrderWiseTurnover  
    INTO #OrderWiseData  
 FROM dbo.#FilterTrade trade  
    GROUP BY trade.RefClientId, trade.RefInstrumentId, trade.TradeDate, trade.OrderId  
  
 DROP TABLE #FilterTrade  
  
 SELECT DISTINCT  
  inst.RefInstrumentId,  
  inst.Isin,    
  inst.GroupName,    
  inst.RefSegmentId  
 INTO #tradeIds  
 FROM #OrderWiseData trade  
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
  
 SELECT DISTINCT  
  grp.RefScripGroupId,  
  grp.[Name] AS ScripGroup,  
  attrVal.CoreEntityAttributeValueId,  
  attrDetail.ForEntityId AS RefInstrumentId  
 INTO #internalCodes  
 FROM #tradeIds trade  
 INNER JOIN dbo.CoreEntityAttributeDetail attrDetail ON attrDetail.ForEntityId = trade.RefInstrumentId  
 INNER JOIN dbo.RefEntityAttribute attr ON attrDetail.RefEntityAttributeId = attr.RefEntityAttributeId   
 INNER JOIN dbo.CoreEntityAttributeValue attrVal ON attr.RefEntityAttributeId = attrVal.RefEntityAttributeId  
  AND attrDetail.CoreEntityAttributeValueId = attrVal.CoreEntityAttributeValueId  
 INNER JOIN dbo.RefScripGroup grp ON grp.[Name] = attrVal.UserDefinedValueName  
 WHERE attr.ForRefEntityTypeId = @InstrumentRefEntityTypeId  
 AND attr.EntityAttributeTypeRefEnumValueId = @EntityAttributeTypeRefEnumValueId  
 AND attr.Code IN ('TW01','TW02')  
 AND @ToDateInternal >= attrDetail.StartDate  
 AND (attrDetail.EndDate IS NULL OR attrDetail.EndDate > @ToDateInternal)  
  
 SELECT DISTINCT   
  ids.Isin,    
  COALESCE(inst2.GroupName, inter.ScripGroup, 'B') AS GroupName,  
  COALESCE(inst2.Code, inst1.Code) AS Code  
 INTO #allNseGroupData  
 FROM #tradeIds ids  
 INNER JOIN dbo.RefInstrument inst1 ON ids.RefInstrumentId = inst1.RefInstrumentId  
 LEFT JOIN dbo.RefInstrument inst2 ON inst2.RefSegmentId = @BseSegmentId    
  AND ids.Isin = inst2.Isin AND inst2.[Status] = 'A'  
 LEFT JOIN #internalCodes inter ON ids.RefInstrumentId = inter.RefInstrumentId  
 WHERE ids.RefSegmentId = @NseSegmentId  
  
 DROP TABLE #internalCodes  
 DROP TABLE #tradeIds  
   
 SELECT Isin, COUNT(1) AS rcount  
 INTO #multipleGroups  
 FROM #allNseGroupData  
 GROUP BY Isin  
 HAVING COUNT(1) > 1  
  
 SELECT DISTINCT t.Isin, t.GroupName   
 INTO #nseGroupData  
 FROM (SELECT grp.Isin, grp.GroupName   
  FROM #allNseGroupData grp  
  WHERE NOT EXISTS (SELECT 1 FROM #multipleGroups mg   
   WHERE mg.Isin = grp.Isin)  
    
  UNION  
    
  SELECT mg.Isin, grp.GroupName  
  FROM #multipleGroups mg  
   INNER JOIN #allNseGroupData grp ON grp.Isin = mg.Isin AND grp.Code like '5%'  
 ) t  
  
 DROP TABLE #multipleGroups  
 DROP TABLE #allNseGroupData  
  
 SELECT   
  owd.RefClientId,  
        owd.RefInstrumentId,  
        owd.OrderId,  
        owd.OrderWiseQty,  
        OrderWiseTurnover,  
        CASE WHEN inst.RefSegmentId = @NseSegmentId THEN nse.GroupName ELSE inst.GroupName END AS ScripGroup,  
        inst.Code AS ScripCode,  
        inst.[Name] AS Scrip       
    INTO #intermediateTable  
    FROM #OrderWiseData owd  
    INNER JOIN dbo.RefInstrument inst ON owd.RefInstrumentId = inst.RefInstrumentId  
 LEFT JOIN #nseGroupData nse ON inst.Isin = nse.Isin AND inst.RefSegmentId = @NseSegmentId  
              
    SELECT   
  owd.RefClientId,  
        owd.RefInstrumentId,  
        COUNT(owd.OrderId) AS TotalExeOrders,  
        SUM(owd.OrderWiseQty) AS TotalExeQty,  
        SUM(CASE WHEN owd.OrderWiseQty <= @QtyThresholdInternal THEN 1 ELSE 0 END) AS SmallOrders,  
        SUM(CASE WHEN owd.OrderWiseQty <= @QtyThresholdInternal THEN owd.OrderWiseQty ELSE 0 END) AS SmallOrderQty,  
        SUM(OrderWiseTurnover) AS ClientTurnover,  
        owd.ScripGroup,  
        owd.ScripCode,  
        owd.Scrip       
    INTO #FinalTable  
    FROM #intermediateTable owd  
    GROUP BY owd.RefClientId, owd.RefInstrumentId, owd.ScripGroup, owd.ScripCode, owd.Scrip  
    HAVING EXISTS (SELECT 1 FROM #OrderWiseData od  
  WHERE od.TradeDate = @ToDateInternal AND od.RefClientId = owd.RefClientId AND od.OrderWiseQty <= @QtyThresholdInternal)  
  
 DROP TABLE #OrderWiseData  
 DROP TABLE #intermediateTable  
   
 SELECT items AS [Group]  
    INTO #ExcludedGroups  
    FROM dbo.Split(@ExcludeGroupsInternal, ',')  
  
    SELECT   
  cli.ClientId,  
        cli.[Name] AS ClientName,  
        @FromDateInternal AS FromDate,  
        @ToDateInternal AS ToDate,  
        seg.Segment,  
        ft.ScripGroup,  
        ft.ScripCode,  
        ft.Scrip,  
        ft.TotalExeOrders,  
        ft.TotalExeQty,  
        ft.SmallOrders,  
        ft.SmallOrderQty,  
        ROUND((ft.SmallOrders *1.0 / ft.TotalExeOrders) * 100, 2) AS SmallOrderPercentage,  
        bhav.[Close] AS ClosingPrice,  
        ft.SmallOrderQty * bhav.[Close] AS SmallOrderTurnover,  
        ft.ClientTurnover,  
        cli.RefClientId,  
        inst.RefInstrumentId,  
        rf.IntermediaryCode,  
        rf.[Name] as IntermediaryName,  
        rf.TradeName                 
    FROM #FinalTable ft  
    INNER JOIN dbo.RefClient cli ON ft.RefClientId = cli.RefClientId          
    INNER JOIN dbo.RefClientStatus clientStatus ON cli.RefClientStatusId = clientStatus.RefClientStatusId  
  AND (@ExcludeProInternal = 0 OR clientStatus.[Name] != 'Pro')  
  AND (@ExcludeInstitutionInternal = 0 OR clientStatus.[Name] != 'Institution')       
    INNER JOIN dbo.RefInstrument inst ON ft.RefInstrumentId = inst.RefInstrumentId  
    INNER JOIN dbo.RefSegmentEnum seg ON inst.RefSegmentId = seg.RefSegmentEnumId  
    LEFT JOIN dbo.CoreBhavCopy bhav ON inst.RefSegmentId = bhav.RefSegmentId   
  AND bhav.[Date] = @ToDateInternal AND inst.RefInstrumentId = bhav.RefInstrumentId  
    LEFT JOIN dbo.RefIntermediary rf ON cli.RefIntermediaryId = rf.RefIntermediaryId  
    WHERE ft.TotalExeOrders >= @MinimumOrderInternal   
        AND ft.SmallOrders > 0   
        AND ROUND((ft.SmallOrders * 1.0 / ft.TotalExeOrders) * 100,2) >= @PercentageThresholdInternal      
        AND NOT EXISTS (SELECT 1 FROM #ExcludedGroups exGrp WHERE exGRP.[Group] = ft.ScripGroup)    
      
END  
GO
--- rc -WEB-68491-end