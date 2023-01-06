--File:Tables:dbo:SysAmlReportSetting:DML
--RC-WEB-83779 START
GO
	DECLARE @AmlReportId INT

	SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE  [Name] = 'S74 Small Orders In Single Stock 30 Days'

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
--RC-WEB-83779 END

--File:StoredProcedures:dbo:Aml_GetS74SmallOrdersInSingleStock30Days
--RC-WEB-83779 START
GO
 CREATE PROCEDURE dbo.Aml_GetS74SmallOrdersInSingleStock30Days  
(  
    @RunDate DATETIME,
	@ReportId INT  
)  
AS  
BEGIN  
          
	 DECLARE @FromDate DATETIME, @ToDate DATETIME, @ReportIdInternal INT, @QtyThreshold INT, @PercentageThreshold DECIMAL(28,6), @MinimumOrder INT, @ExcludePro BIT,  
			@ExcludeInstitution BIT,@ExcludeAlgoTrade BIT, @ExcludeGroups VARCHAR(MAX), @InstrumentRefEntityTypeId INT, @EntityAttributeTypeRefEnumValueId INT, @BseSegmentId INT, @NseSegmentId INT  
    
	SET @ReportIdInternal = @ReportId
	SET @ToDate = @RunDate  
	SET @FromDate = DATEADD(DAY, -29, @ToDate)  

	SET @QtyThreshold = (SELECT CONVERT(INT,syst.[Value] )FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Threshold_Quantity')
    SET @PercentageThreshold = (SELECT CONVERT(DECIMAL(28,6),syst.[Value] )FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Threshold_Percentage')
	SET @MinimumOrder = (SELECT CONVERT(INT,syst.[Value] )FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Minimum_Number_Of_Order') 
    SET @ExcludeInstitution = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Exclude_Institution')
	SET @ExcludePro = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Exclude_Pro')
	SET @ExcludeAlgoTrade = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Exclude_AlgoTrade')
    SET @ExcludeGroups =(SELECT CONVERT(VARCHAR(MAX), syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Excluded_Groups')  
	

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

	SELECT DISTINCT
		RefClientId
	INTO #clientsToExclude
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex
	WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1) 
		AND @ToDate >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @ToDate)
          
    SELECT   
		trade.RefClientId,  
        RefInstrumentId,  
        TradeDate,  
        OrderId,                  
        Quantity,  
        Rate  
    INTO #FilterTrade         
    FROM dbo.CoreTrade trade  
    INNER JOIN #RefSegmentEnum en ON en.RefSegmentEnumid = trade.RefSegmentId  
    LEFT JOIN #clientsToExclude cltex ON cltex.RefClientId = trade.RefClientId 
	WHERE cltex.RefClientId IS NULL AND trade.TradeDate BETWEEN @FromDate AND @ToDate AND  (    

		@ExcludeAlgoTrade = 0 OR  
		LEN(CONVERT(VARCHAR(100), trade.CtclId)) NOT IN (15,16) 
		OR(
			@ExcludeAlgoTrade = 1 AND     
			SUBSTRING(CONVERT(VARCHAR(100), trade.CtclId), 13, 1) NOT IN ('0','2','4')
		)
	)
	
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
	 AND @ToDate >= attrDetail.StartDate  
	 AND (attrDetail.EndDate IS NULL OR attrDetail.EndDate > @ToDate)  
  
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
   
	 SELECT Isin, 
		COUNT(1) AS rcount  
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
        SUM(CASE WHEN owd.OrderWiseQty <= @QtyThreshold THEN 1 ELSE 0 END) AS SmallOrders,  
        SUM(CASE WHEN owd.OrderWiseQty <= @QtyThreshold THEN owd.OrderWiseQty ELSE 0 END) AS SmallOrderQty,  
        SUM(OrderWiseTurnover) AS ClientTurnover,  
        owd.ScripGroup,  
        owd.ScripCode,  
        owd.Scrip       
    INTO #FinalTable  
    FROM #intermediateTable owd  
    GROUP BY owd.RefClientId, owd.RefInstrumentId, owd.ScripGroup, owd.ScripCode, owd.Scrip  
    HAVING EXISTS (SELECT 1 FROM #OrderWiseData od  
	WHERE od.TradeDate = @ToDate AND od.RefClientId = owd.RefClientId AND od.OrderWiseQty <= @QtyThreshold)  
  
	 DROP TABLE #OrderWiseData  
	 DROP TABLE #intermediateTable  
   
	 SELECT items AS [Group]  
		INTO #ExcludedGroups  
		FROM dbo.Split(@ExcludeGroups, ',')  
  
    SELECT   
		cli.ClientId,  
        cli.[Name] AS ClientName,  
        @FromDate AS FromDate,  
        @ToDate AS ToDate,  
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
        inst.RefInstrumentId
    FROM #FinalTable ft  
    INNER JOIN dbo.RefClient cli ON ft.RefClientId = cli.RefClientId          
    INNER JOIN dbo.RefClientStatus clientStatus ON cli.RefClientStatusId = clientStatus.RefClientStatusId  
	  AND (@ExcludePro = 0 OR clientStatus.[Name] != 'Pro')  
	  AND (@ExcludeInstitution = 0 OR clientStatus.[Name] != 'Institution')       
    INNER JOIN dbo.RefInstrument inst ON ft.RefInstrumentId = inst.RefInstrumentId  
    INNER JOIN dbo.RefSegmentEnum seg ON inst.RefSegmentId = seg.RefSegmentEnumId  
    LEFT JOIN dbo.CoreBhavCopy bhav ON inst.RefSegmentId = bhav.RefSegmentId   
	 AND bhav.[Date] = @ToDate AND inst.RefInstrumentId = bhav.RefInstrumentId   
    WHERE ft.TotalExeOrders >= @MinimumOrder   
        AND ft.SmallOrders > 0   
        AND ROUND((ft.SmallOrders * 1.0 / ft.TotalExeOrders) * 100,2) >= @PercentageThreshold      
        AND NOT EXISTS (SELECT 1 FROM #ExcludedGroups exGrp WHERE exGRP.[Group] = ft.ScripGroup)    
      
END  
GO
--RC-WEB-83779 END
--File:StoredProcedures:dbo:Aml_GetS73SmallOrdersInSingleStock15Days
--RC-WEB-83778 START
GO
 CREATE PROCEDURE dbo.Aml_GetS73SmallOrdersInSingleStock15Days  
(  
    @RunDate DATETIME,
	@ReportId INT  
)  
AS  
BEGIN  
          
	 DECLARE @FromDate DATETIME, @ToDate DATETIME, @ReportIdInternal INT, @QtyThreshold INT, @PercentageThreshold DECIMAL(28,6), @MinimumOrder INT, @ExcludePro BIT,  
			@ExcludeInstitution BIT,@ExcludeAlgoTrade BIT, @ExcludeGroups VARCHAR(MAX), @InstrumentRefEntityTypeId INT, @EntityAttributeTypeRefEnumValueId INT, @BseSegmentId INT, @NseSegmentId INT  
    
	SET @ReportIdInternal = @ReportId
	SET @ToDate = @RunDate  
	SET @FromDate = DATEADD(DAY, -14, @ToDate)  

	SET @QtyThreshold = (SELECT CONVERT(INT,syst.[Value] )FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Threshold_Quantity')
    SET @PercentageThreshold = (SELECT CONVERT(DECIMAL(28,6),syst.[Value] )FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Threshold_Percentage')
	SET @MinimumOrder = (SELECT CONVERT(INT,syst.[Value] )FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Minimum_Number_Of_Order') 
    SET @ExcludeInstitution = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Exclude_Institution')
	SET @ExcludePro = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Exclude_Pro')
	SET @ExcludeAlgoTrade = (SELECT CONVERT(BIT, syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Exclude_AlgoTrade')
    SET @ExcludeGroups =(SELECT CONVERT(VARCHAR(MAX), syst.[Value]) FROM dbo.SysAmlReportSetting syst WHERE syst.RefAmlReportId = @ReportIdInternal AND syst.[Name] = 'Excluded_Groups')  
	

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

	SELECT DISTINCT
		RefClientId
	INTO #clientsToExclude
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex
	WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1) 
		AND @ToDate >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @ToDate)
          
    SELECT   
		trade.RefClientId,  
        RefInstrumentId,  
        TradeDate,  
        OrderId,                  
        Quantity,  
        Rate  
    INTO #FilterTrade         
    FROM dbo.CoreTrade trade  
    INNER JOIN #RefSegmentEnum en ON en.RefSegmentEnumid = trade.RefSegmentId  
    LEFT JOIN #clientsToExclude cltex ON cltex.RefClientId = trade.RefClientId 
	WHERE cltex.RefClientId IS NULL AND trade.TradeDate BETWEEN @FromDate AND @ToDate AND  (    

		@ExcludeAlgoTrade = 0 OR  
		LEN(CONVERT(VARCHAR(100), trade.CtclId)) NOT IN (15,16) 
		OR
		(
			@ExcludeAlgoTrade = 1 AND     
			SUBSTRING(CONVERT(VARCHAR(100), trade.CtclId), 13, 1) NOT IN ('0','2','4')
		)
	)
	
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
	 AND @ToDate >= attrDetail.StartDate  
	 AND (attrDetail.EndDate IS NULL OR attrDetail.EndDate > @ToDate)  
  
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
   
	 SELECT Isin, 
		COUNT(1) AS rcount  
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
        SUM(CASE WHEN owd.OrderWiseQty <= @QtyThreshold THEN 1 ELSE 0 END) AS SmallOrders,  
        SUM(CASE WHEN owd.OrderWiseQty <= @QtyThreshold THEN owd.OrderWiseQty ELSE 0 END) AS SmallOrderQty,  
        SUM(OrderWiseTurnover) AS ClientTurnover,  
        owd.ScripGroup,  
        owd.ScripCode,  
        owd.Scrip       
    INTO #FinalTable  
    FROM #intermediateTable owd  
    GROUP BY owd.RefClientId, owd.RefInstrumentId, owd.ScripGroup, owd.ScripCode, owd.Scrip  
    HAVING EXISTS (SELECT 1 FROM #OrderWiseData od  
	WHERE od.TradeDate = @ToDate AND od.RefClientId = owd.RefClientId AND od.OrderWiseQty <= @QtyThreshold)  
  
	 DROP TABLE #OrderWiseData  
	 DROP TABLE #intermediateTable  
   
	 SELECT items AS [Group]  
		INTO #ExcludedGroups  
		FROM dbo.Split(@ExcludeGroups, ',')  
  
    SELECT   
		cli.ClientId,  
        cli.[Name] AS ClientName,  
        @FromDate AS FromDate,  
        @ToDate AS ToDate,  
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
        inst.RefInstrumentId
    FROM #FinalTable ft  
    INNER JOIN dbo.RefClient cli ON ft.RefClientId = cli.RefClientId          
    INNER JOIN dbo.RefClientStatus clientStatus ON cli.RefClientStatusId = clientStatus.RefClientStatusId  
	  AND (@ExcludePro = 0 OR clientStatus.[Name] != 'Pro')  
	  AND (@ExcludeInstitution = 0 OR clientStatus.[Name] != 'Institution')       
    INNER JOIN dbo.RefInstrument inst ON ft.RefInstrumentId = inst.RefInstrumentId  
    INNER JOIN dbo.RefSegmentEnum seg ON inst.RefSegmentId = seg.RefSegmentEnumId  
    LEFT JOIN dbo.CoreBhavCopy bhav ON inst.RefSegmentId = bhav.RefSegmentId   
	 AND bhav.[Date] = @ToDate AND inst.RefInstrumentId = bhav.RefInstrumentId  
    WHERE ft.TotalExeOrders >= @MinimumOrder   
        AND ft.SmallOrders > 0   
        AND ROUND((ft.SmallOrders * 1.0 / ft.TotalExeOrders) * 100,2) >= @PercentageThreshold      
        AND NOT EXISTS (SELECT 1 FROM #ExcludedGroups exGrp WHERE exGRP.[Group] = ft.ScripGroup)    
      
END  
GO
--RC-WEB-83778 END

--File:Tables:dbo:RefAmlReport:DML
--RC-WEB-83779 START
GO
	UPDATE ref
	SET ref.[Description] = '
	"This Scenario will detect the clients indulging in frequent small quantity orders <br>
	It will generate alert if,<br>
	1.Client traded in a small qty less than set threshold <br>
	2.% to the total orders to small orders is greater than set threshold <br>
	3. Client should placed minimum order greater than set threshold <br>
	4. User can able to exclude Pro , Inst and also able to exclude Group from Alert generation <br>
	Segments covered : BSE_CASH & NSE_CASH ; Period: 15 Days Frequency : Daily <br>
	Thresholds: <br>
	A Small order Qty : User must place the order less than or equal to set threshold this threshold is works lessthan or equal basis <br>
	B Small order percentage : % to total oeders to small orders is greater than set threshold this threshold works on greater than or equal basis <br>
	C Minimum order : user must places minimum orders grater than set threshold <br>
	D Exclude Group , Pro , Inst : User can able to exclude Pro,Inst and Group from alert generation <br>"
	'
	FROM dbo.RefAmlReport ref
	WHERE ref.[Name] = 'S73 Small Orders In Single Stock 15 Days'
GO
GO
	UPDATE ref
	SET ref.[Description] = '
	"This Scenario will detect the clients indulging in frequent small quantity orders <br>
	It will generate alert if,<br>
	1.Client traded in a small qty less than set threshold <br>
	2.% to the total orders to small orders is greater than set threshold <br>
	3. Client should placed minimum order greater than set threshold <br>
	4. User can able to exclude Pro , Inst and also able to exclude Group from Alert generation <br>
	Segments covered : BSE_CASH & NSE_CASH ; Period: 30 Days Frequency : Daily <br>
	Thresholds: <br>
	A Small order Qty : User must place the order less than or equal to set threshold this threshold is works lessthan or equal basis <br>
	B Small order percentage : % to total oeders to small orders is greater than set threshold this threshold works on greater than or equal basis <br>
	C Minimum order : user must places minimum orders grater than set threshold <br>
	D Exclude Group , Pro , Inst : User can able to exclude Pro,Inst and Group from alert generation <br>"
	'
	FROM dbo.RefAmlReport ref
	WHERE ref.[Name] = 'S74 Small Orders In Single Stock 30 Days'
	
GO
--RC-WEB-83779 END
