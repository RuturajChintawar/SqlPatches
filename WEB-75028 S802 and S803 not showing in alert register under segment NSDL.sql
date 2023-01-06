
--WEB-75028 RC START
GO
ALTER PROCEDURE [dbo].[AML_GetSignificantHoldingsInListedScripsForScenario]    
(    
    @ReportId INT,    
    @ReportDate DATETIME    
)    
AS    
BEGIN    
            
   DECLARE @ReportIdInternal INT    
  DECLARE @ReportDateInternal DATETIME    
          
  SET @ReportDateInternal = @ReportDate    
  SET @ReportIdInternal = @ReportId    
  DECLARE @BseCashSegmentId INT    
        SET @BseCashSegmentId = dbo.GetSegmentId('BSE_CASH')     
      
      
    
  
  SELECT    
  rules.RefAmlScenarioRuleId,    
  linkCS.RefCustomerSegmentId,    
   rules.Threshold6   
  INTO #scenarioRules    
  FROM dbo.RefAmlScenarioRule rules    
  INNER JOIN dbo.LinkRefAmlScenarioRuleRefCustomerSegment linkCS ON rules.RefAmlScenarioRuleId = linkCS.RefAmlScenarioRuleId    
  WHERE rules.RefAmlReportId = @ReportIdInternal    
      
    
        DECLARE @BhavCopyDate DATETIME    
        SELECT  @BhavCopyDate = MAX([Date])    
        FROM    dbo.CoreBhavCopy bhav    
        WHERE   RefSegmentId = @BseCashSegmentId    
    AND Date <= @ReportDateInternal    
                AND CapitalIssued IS NOT NULL AND CapitalIssued > 0    
                    
       DECLARE @SuspendedAccountStatusId INT    
  SELECT @SuspendedAccountStatusId =RefClientAccountStatusId  from RefClientAccountStatus where Name = 'Suspended'     
    
       DECLARE @SuspendedDrAccountStatusId INT    
  SELECT @SuspendedDrAccountStatusId =RefClientAccountStatusId  from RefClientAccountStatus where Name = 'Suspended for debit'     
      
  DECLARE @SuspendedDrCrAccountStatusId INT    
  SELECT @SuspendedDrCrAccountStatusId =RefClientAccountStatusId  from RefClientAccountStatus where Name = 'Suspended for Debit & Credit'     
    
    
        SELECT  bhav.RefInstrumentId,    
    bhav.CapitalIssued,    
    bhav.[Close],    
    bhav.[Date],    
    bhav.CapitalIssued * bhav.[Close] AS TotalMCap    
        INTO    #CoreBhavCopy     
        FROM    CoreBhavCopy bhav    
        WHERE   bhav.RefSegmentId = @BseCashSegmentId    
    AND bhav.[Date] = @BhavCopyDate    
            
            
        SELECT  holding.RefClientDematAccountId,    
    holding.AsOfDate AS HoldingDate,    
    inst.RefInstrumentId,    
    inst.Name AS Instrument,    
    isin.Name AS Isin,    
    holding.RefIsinId,    
    holding.CurrentBalanceQuantity AS Qty,    
    bhav.[Close] AS Rate,        
    holding.CurrentBalanceQuantity * bhav.[Close] AS TotalHoldingValue,    
    bhav.CapitalIssued AS TotalQty,    
    bhav.TotalMCap,    
    bhav.[Date] AS PriceDate        
                    
        INTO    #ClientDematAccountTotalHolding    
        FROM    CoreClientHolding holding    
                INNER JOIN dbo.RefIsin isin ON holding.RefIsinId = isin.RefIsinId    
                INNER JOIN dbo.RefInstrument inst ON isin.Name = inst.Isin    
                INNER JOIN #CoreBhavCopy bhav ON inst.RefInstrumentId = bhav.RefInstrumentId    
  WHERE holding.AsOfDate = @ReportDateInternal    
            
                 
    
---Geting Client Risk    
create table #TempLinkRefClientRefRiskCategory(    
LinkRefClientRefRiskCategoryId int,    
RefClientId int,    
RefRiskCategoryId int,    
FromDate datetime,    
ToDate datetime,    
AddedBy varchar(100) collate DATABASE_DEFAULT,    
AddedOn datetime,    
LastEditedBy varchar(100) collate DATABASE_DEFAULT,    
EditedOn datetime,    
Notes varchar(2000) collate DATABASE_DEFAULT    
)    
    
create index IX_#TempLinkRefClientRefRiskCategory on #TempLinkRefClientRefRiskCategory(RefClientId)    
    
insert into #TempLinkRefClientRefRiskCategory(    
LinkRefClientRefRiskCategoryId,    
RefClientId,    
RefRiskCategoryId,    
FromDate,    
ToDate,    
AddedBy,    
AddedOn,    
LastEditedBy,    
EditedOn,    
Notes    
)    
select     
linkrisk.LinkRefClientRefRiskCategoryId,    
linkrisk.RefClientId,    
linkrisk.RefRiskCategoryId,    
linkrisk.FromDate,    
linkrisk.ToDate,    
linkrisk.AddedBy,    
linkrisk.AddedOn,    
linkrisk.LastEditedBy,    
linkrisk.EditedOn,    
linkrisk.Notes    
from LinkRefClientRefRiskCategory linkrisk    
where linkrisk.RefClientId in    
(    
SELECT cl.RefClientId from   #ClientDematAccountTotalHolding holding    
      INNER JOIN dbo.RefClientDematAccount demat ON demat.RefClientDematAccountId = holding.RefClientDematAccountId    
      INNER JOIN dbo.RefClient cl ON cl.RefClientId = demat.RefClientId AND     
      (cl.RefClientAccountStatusId NOT IN(@SuspendedAccountStatusId,@SuspendedDrAccountStatusId,@SuspendedDrCrAccountStatusId) or cl.RefClientAccountStatusId IS NULL)     
 )    
    
    
    
SELECT     l.LinkRefClientRefRiskCategoryId, l.RefClientId, l.RefRiskCategoryId, l.Notes, l.FromDate, l.ToDate, l.AddedOn, l.EditedOn    
into #TempLinkRefClientRefRiskCategoryLatest    
FROM         (SELECT     l.LinkRefClientRefRiskCategoryId, l.RefClientId, l.RefRiskCategoryId, l.Notes, l.FromDate, l.ToDate, l.AddedOn, l.EditedOn, ROW_NUMBER()     
                                              OVER (PARTITION BY l.RefClientId    
                       ORDER BY ISNULL(l.ToDate, '31-Dec-9999') DESC) AS RowNum    
FROM         #TempLinkRefClientRefRiskCategory l) l    
WHERE     l.RowNum = 1    
    
--------------------    
  SELECT DISTINCT    
 cl.RefClientId    
 INTO #distinctClients  
  FROM #ClientDematAccountTotalHolding  holding  
 INNER JOIN dbo.RefClientDematAccount demat ON demat.RefClientDematAccountId = holding.RefClientDematAccountId    
      INNER JOIN dbo.RefClient cl ON cl.RefClientId = demat.RefClientId AND     
      (cl.RefClientAccountStatusId NOT IN(@SuspendedAccountStatusId,@SuspendedDrAccountStatusId,@SuspendedDrCrAccountStatusId) or cl.RefClientAccountStatusId IS NULL)  
     
    
 SELECT    
 t.RefClientId,    
 t.RefCustomerSegmentId    
 INTO #clientCSMapping    
 FROM    
 (    
  SELECT    
   cl.RefClientId,    
   linkClCs.RefCustomerSegmentId,    
   ROW_NUMBER() OVER(PARTITION BY cl.RefClientId ORDER BY linkClCs.StartDate DESC) AS RN    
  FROM #distinctClients cl    
  LEFT JOIN dbo.LinkRefClientRefCustomerSegment linkClCs ON cl.RefClientId = linkClCs.RefClientId    
 ) t    
 WHERE t.RN = 1    
    
 DROP TABLE #distinctClients   
    
    
    
    
    
    SELECT DpId,    
    RefClientId,    
    ClientId,                    
    ClientName,                    
    HoldingDate,    
    RefInstrumentId,    
    Instrument,    
    Isin,    
    Qty,    
    Rate,        
    TotalHoldingValue,    
    Percentage,    
    Threshold,    
    TotalQty,    
    TotalMCap,    
    PriceDate,        
    IntermediaryCode,    
    IntermediaryName,    
    TradeName,    
    Risk  ,  
 AccountSegment ,
 RefSegmentEnumId
        FROM (SELECT cl.RefClientId,    
      holding.RefInstrumentId,    
      cl.DpId,    
      cl.ClientId,                    
      cl.[Name] AS ClientName,                    
      holding.HoldingDate,    
      holding.Instrument,    
      holding.RefIsinId,    
      holding.Isin,    
      holding.Qty,    
      holding.Rate,        
      holding.TotalHoldingValue / 1000000 AS TotalHoldingValue,    
      100 * holding.TotalHoldingValue / holding.TotalMCap AS Percentage,    
      CONVERT(DECIMAL(28,2),LTRIM(RTRIM(S.items))) Threshold,    
      holding.TotalQty,    
      holding.TotalMCap / 1000000 AS TotalMCap,    
      holding.PriceDate,          
      rf.IntermediaryCode,    
      rf.Name as IntermediaryName,    
      rf.TradeName,    
      risk.Name as Risk,          
      ROW_NUMBER() OVER (PARTITION BY cl.RefClientId, holding.RefIsinId, holding.HoldingDate ORDER BY CONVERT(DECIMAL(28,2),LTRIM(RTRIM(S.items))) DESC) AS RowNum ,    
      custSeg.[Name] AS AccountSegment  ,
	  enum.RefSegmentEnumId 
    FROM  #ClientDematAccountTotalHolding holding     
       INNER JOIN dbo.RefClientDematAccount demat ON demat.RefClientDematAccountId = holding.RefClientDematAccountId    
       INNER JOIN dbo.RefClient cl ON cl.RefClientId = demat.RefClientId AND     
       (cl.RefClientAccountStatusId NOT IN(@SuspendedAccountStatusId,@SuspendedDrAccountStatusId,@SuspendedDrCrAccountStatusId) or cl.RefClientAccountStatusId IS NULL)  
	   INNER JOIN dbo.RefClientDatabaseEnum base ON base.RefClientDatabaseEnumId = cl.RefClientDatabaseEnumId	 
	   INNER JOIN dbo.RefSegmentEnum enum ON enum.Segment = base.DatabaseType
	   INNER JOIN #clientCSMapping ccsm ON cl.RefClientId = ccsm.RefClientId    
       INNER JOIN #scenarioRules rules ON ISNULL(rules.RefCustomerSegmentId,-1) = ISNULL(ccsm.RefCustomerSegmentId,-1)  
	   LEFT JOIN dbo.RefCustomerSegment custSeg ON custSeg.RefCustomerSegmentId = ccsm.RefCustomerSegmentId     
	   CROSS APPLY dbo.Split(rules.Threshold6,',') S   
      LEFT JOIN #TempLinkRefClientRefRiskCategory link on link.RefClientId=cl.RefClientId    
      LEFT JOIN dbo.RefRiskCategory risk on risk.RefRiskCategoryId=link.RefRiskCategoryId    
      LEFT JOIN dbo.RefIntermediary rf on cl.RefIntermediaryId = rf.RefIntermediaryId          
    WHERE 100 * holding.TotalHoldingValue / holding.TotalMCap >= CONVERT(DECIMAL(28,2),LTRIM(RTRIM(S.items)))  
        
    ) t    
  WHERE t.RowNum = 1    
    AND NOT EXISTS    
       (    
      SELECT 1    
      FROM CoreAmlScenarioAlert alert    
      WHERE alert.RefAmlReportId = @ReportIdInternal AND alert.RefClientId = t.RefClientId    
        AND alert.RefIsinId = t.RefIsinId --AND alert.TransactionDate = t.HoldingDate    
        AND alert.Threshold >= t.Threshold    
       )    
            
            
      
END  
GO
--WEB-75028 RC END
--WEB-75028 RC START
GO
ALTER PROCEDURE dbo.Aml_GetSignificantValueHoldingInAccount
(
	@ReportId INT,
	@ReportDate DATETIME
)
AS
	BEGIN
	
		DECLARE @ReportIdInternal	INT
		DECLARE @ReportDateInternal DATETIME
		      
		SET @ReportDateInternal = @ReportDate
		SET @ReportIdInternal = @ReportId
		
		DECLARE @BseCashSegmentId INT
        SET @BseCashSegmentId = dbo.GetSegmentId('BSE_CASH')		
		
		
		DECLARE @Threshold VARCHAR (50)
			
			
		DECLARE	@DefaultNetworth BIGINT
		SELECT	@DefaultNetworth = cliNetSellPoint.DefaultNetworth 
		FROM	dbo.RefAmlQueryProfile qp  	
				LEFT JOIN dbo.LinkRefAmlQueryProfileRefSegment qpSegment ON qpSegment.RefSegmentId = @BseCashSegmentId
						  AND qpSegment.RefAmlQueryProfileId = qp.RefAmlQueryProfileId				  
				LEFT JOIN dbo.SysAmlClientNetSellPoints cliNetSellPoint ON cliNetSellPoint.LinkRefAmlQueryProfileRefSegmentId = qpSegment.LinkRefAmlQueryProfileRefSegmentId
		WHERE	qp.[Name] = 'Default'	
		
		
		DECLARE @SuspendedAccountStatusId INT
		SELECT @SuspendedAccountStatusId =RefClientAccountStatusId  from RefClientAccountStatus where Name = 'Suspended'

        DECLARE @SuspendedDrAccountStatusId INT
		SELECT @SuspendedDrAccountStatusId =RefClientAccountStatusId  from RefClientAccountStatus where Name = 'Suspended for debit' 
		
		DECLARE @SuspendedDrCrAccountStatusId INT
		SELECT @SuspendedDrCrAccountStatusId =RefClientAccountStatusId  from RefClientAccountStatus where Name = 'Suspended for Debit & Credit' 


		DECLARE	@DefaultIncome VARCHAR (5000)
		SELECT	@DefaultIncome = reportSetting.Value
		FROM	dbo.RefAmlQueryProfile qp 		
		LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.[Name] = 'Client Purchase to Income'
		LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId
				  AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId
				  AND reportSetting.[Name] = 'Default_Income'
		WHERE	qp.[Name] = 'Default';

		
		WITH holdingValue_CTE as
		(
		SELECT	hld.RefClientDematAccountId,
				SUM(hld.CurrentBalanceQuantity * (COALESCE(bhav.[Close], isin.FaceValue, 0))) AS HoldingValue				
		FROM	dbo.CoreClientHolding hld
				INNER JOIN dbo.RefIsin isin ON hld.RefIsinId = isin.RefIsinId
				LEFT JOIN dbo.CoreDPBhavCopy bhav ON hld.RefIsinId = bhav.RefIsinId AND hld.AsOfDate = bhav.[Date]
		WHERE	hld.AsOfDate = @ReportDateInternal
		GROUP BY hld.RefClientDematAccountId		
		),
		
		
		 ClientNetworthIncomeFairValueDetails_CTE as
		(SELECT t.* FROM
			(SELECT	
				cli.RefClientId,
				cli.ClientId,
				cli.[Name],
				cli.RefIntermediaryId,
				cli.Dpid,				
				COALESCE (clientIncomeGroup.Networth, cliIncomeGroupLatest.Networth, @DefaultNetworth, 0) AS Networth,
				COALESCE (clientIncomeGroup.Income, cliIncomeGroupLatest.Income, incomeGroup.IncomeTo, @DefaultIncome, 0) AS Income,				
				(COALESCE (clientIncomeGroup.Networth, cliIncomeGroupLatest.Networth, @DefaultNetworth, 0) * ISNULL(cli.NetworthMultiplier, 1))
				+ (COALESCE (clientIncomeGroup.Income, cliIncomeGroupLatest.Income, incomeGroup.IncomeTo, @DefaultIncome, 0) * ISNULL(cli.IncomeMultiplier, 1))
				AS FairValue,
				linkClCs.RefCustomerSegmentId,
				ROW_NUMBER() OVER(PARTITION BY cli.RefClientId ORDER BY linkClCs.StartDate DESC) AS RN       
			FROM dbo.RefClient cli				
			LEFT JOIN	dbo.LinkRefClientRefIncomeGroup clientIncomeGroup ON clientIncomeGroup.RefClientId = cli.RefClientId
						AND (@ReportDateInternal >= clientIncomeGroup.FromDate OR clientIncomeGroup.FromDate IS NULL) 
						AND (@ReportDateInternal <= clientIncomeGroup.ToDate OR clientIncomeGroup.ToDate IS NULL)		
			LEFT JOIN	LinkRefClientRefIncomeGroupLatest cliIncomeGroupLatest ON cliIncomeGroupLatest.RefClientId = cli.RefClientId
			LEFT JOIN	dbo.RefIncomeGroup incomeGroup ON incomeGroup.RefIncomeGroupId = 
				ISNULL(clientIncomeGroup.RefIncomeGroupId,cliIncomeGroupLatest.RefIncomeGroupId)
			LEFT JOIN dbo.LinkRefClientRefCustomerSegment linkClCs ON cli.RefClientId = linkClCs.RefClientId	
			WHERE cli.RefClientAccountStatusId NOT IN(@SuspendedAccountStatusId,@SuspendedDrAccountStatusId,@SuspendedDrCrAccountStatusId)
			  OR cli.RefClientAccountStatusId IS NULL
			) t
			WHERE t.RN = 1
		),
		
		Rules_CTE AS	
		(
			SELECT
				scenarioRules.RefCustomerSegmentId,
				CONVERT(DECIMAL(28, 2), LTRIM(RTRIM(th.items))) AS Threshold
			FROM
			(
				SELECT
					linkCS.RefCustomerSegmentId,
					rules.Threshold6
				FROM dbo.RefAmlScenarioRule rules
				INNER JOIN dbo.LinkRefAmlScenarioRuleRefCustomerSegment linkCS ON rules.RefAmlScenarioRuleId = linkCS.RefAmlScenarioRuleId
				WHERE rules.RefAmlReportId = @ReportIdInternal
			) scenarioRules
			CROSS APPLY dbo.Split(scenarioRules.Threshold6, ',') th
		)
		
		SELECT	RefClientId,				
				ClientId,
				ClientName,
				DpId,
				HoldingDate,
				HoldingValue,
				Income,
				Networth,
				FairValue,
				PriceDate,
				Threshold,
				IntermediaryCode,
				IntermediaryName,
				TradeName,
				RefCustomerSegmentId
		into  #final
		FROM	(SELECT	cli.RefClientId,				
						cli.ClientId,
						cli.[Name] AS ClientName,
						cli.DpId,
						@ReportDateInternal AS HoldingDate,
						hvt.HoldingValue,
						threshold.Threshold,
						cli.Income,
						cli.Networth,
						cli.FairValue,
						@ReportDateInternal AS PriceDate,
						rf.IntermediaryCode,
						rf.[Name] as IntermediaryName,
						rf.TradeName,
						cli.RefCustomerSegmentId,
						ROW_NUMBER() OVER (PARTITION BY cli.RefClientId ORDER BY threshold.Threshold DESC) AS RowNum
						
				FROM	Rules_CTE threshold
						INNER JOIN holdingValue_CTE hvt ON 1 = 1
						INNER JOIN dbo.RefClientDematAccount demat ON hvt.RefClientDematAccountId = demat.RefClientDematAccountId
						INNER JOIN ClientNetworthIncomeFairValueDetails_CTE cli ON demat.RefClientId = cli.RefClientId
							AND ISNULL(cli.RefCustomerSegmentId, -1) = ISNULL(threshold.RefCustomerSegmentId, -1)
						LEFT JOIN dbo.RefIntermediary rf on cli.RefIntermediaryId = rf.RefIntermediaryId
				WHERE	hvt.HoldingValue >= threshold.Threshold and hvt.HoldingValue > cli.FairValue
						 
				) t
		WHERE	t.RowNum = 1
				AND NOT EXISTS
					  (
						SELECT	1
						FROM	CoreAmlScenarioAlert alert
						WHERE	alert.RefAmlReportId = @ReportIdInternal AND alert.RefClientId = t.RefClientId
								AND alert.Threshold >= t.Threshold
					  )
		


---Geting Client Risk
	create table #TempLinkRefClientRefRiskCategory(
	LinkRefClientRefRiskCategoryId int,
	RefClientId int,
	RefRiskCategoryId int,
	FromDate datetime,
	ToDate datetime,
	AddedBy varchar(100) collate DATABASE_DEFAULT,
	AddedOn datetime,
	LastEditedBy varchar(100) collate DATABASE_DEFAULT,
	EditedOn datetime,
	Notes varchar(2000) collate DATABASE_DEFAULT
	)

	create index IX_#TempLinkRefClientRefRiskCategory on #TempLinkRefClientRefRiskCategory(RefClientId)

	insert into #TempLinkRefClientRefRiskCategory(
	LinkRefClientRefRiskCategoryId,
	RefClientId,
	RefRiskCategoryId,
	FromDate,
	ToDate,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn,
	Notes
	)
	select 
	linkrisk.LinkRefClientRefRiskCategoryId,
	linkrisk.RefClientId,
	linkrisk.RefRiskCategoryId,
	linkrisk.FromDate,
	linkrisk.ToDate,
	linkrisk.AddedBy,
	linkrisk.AddedOn,
	linkrisk.LastEditedBy,
	linkrisk.EditedOn,
	linkrisk.Notes
	from LinkRefClientRefRiskCategory linkrisk
	where linkrisk.RefClientId in
	(
	select final.RefClientId from  #final final 
	 )



	SELECT     l.LinkRefClientRefRiskCategoryId, l.RefClientId, l.RefRiskCategoryId, l.Notes, l.FromDate, l.ToDate, l.AddedOn, l.EditedOn
	into #TempLinkRefClientRefRiskCategoryLatest
	FROM         (SELECT     l.LinkRefClientRefRiskCategoryId, l.RefClientId, l.RefRiskCategoryId, l.Notes, l.FromDate, l.ToDate, l.AddedOn, l.EditedOn, ROW_NUMBER() 
												  OVER (PARTITION BY l.RefClientId
						   ORDER BY ISNULL(l.ToDate, '31-Dec-9999') DESC) AS RowNum
	FROM         #TempLinkRefClientRefRiskCategory l) l
	WHERE     l.RowNum = 1

	--------------------
	SELECT	f.RefClientId,				
					f.ClientId,
					f.ClientName,
					f.DpId,
					f.HoldingDate,
					f.HoldingValue,
					f.Income,
					f.Networth,
					f.FairValue,
					f.PriceDate,
					f.Threshold,
					f.IntermediaryCode,
					f.IntermediaryName,
					f.TradeName,
					risk.[Name] as Risk,
					cs.[Name] AS AccountSegment,
					enum.RefSegmentEnumId 
					from #final f
					INNER JOIN dbo.RefClient cl ON cl.RefClientId = f.RefClientId  
					INNER JOIN dbo.RefClientDatabaseEnum base ON base.RefClientDatabaseEnumId = cl.RefClientDatabaseEnumId	 
					INNER JOIN dbo.RefSegmentEnum enum ON enum.Segment = base.DatabaseType
					LEFT JOIN #TempLinkRefClientRefRiskCategoryLatest link on link.RefClientId=f.RefClientId
					LEFT JOIN dbo.RefRiskCategory risk on risk.RefRiskCategoryId=link.RefRiskCategoryId
					LEFT JOIN dbo.RefCustomerSegment cs ON f.RefCustomerSegmentId = cs.RefCustomerSegmentId
END
GO
--WEB-75028 RC END
--WEB-75028 RC START
GO
DECLARE @S802Id INT,@S803Id INT
	SELECT @S802Id = RefAmlReportId FROM dbo.RefAmlReport ref WHERE ref.[Name] ='S802 Significant Holding In Listed Scrip'
	SELECT @S803Id = RefAmlReportId FROM dbo.RefAmlReport ref WHERE ref.[Name] ='S803 Significant Value Holding In Account'
	UPDATE core
	SET core.RefSegmentEnumId = seg.RefSegmentEnumId
	FROM dbo.CoreAmlScenarioAlert core
	INNER JOIN dbo.RefClient ref ON core.RefAmlReportId IN (@S802Id,@S803Id) AND core.RefClientId =ref.RefClientId
	INNER JOIN dbo.RefClientDatabaseEnum enum ON enum.RefClientDatabaseEnumId = ref.RefClientDatabaseEnumId
	INNER JOIN dbo.RefSegmentEnum seg ON seg.Segment = enum.DatabaseType
GO
--WEB-75028 RC END
select *  FROM CoreAmlScenarioAlert WHERE refamlreportid =839 order by Addedon desc CoreAmlScenarioAlertID = 9231670
select * FROM  CoreAmlScenarioAlert WHERE CoreAmlScenarioAlertID =9230396
,9231720)
UPDATE ref
set ref.IsRuleRequired = 1
FROM
dbo.RefAmlReport ref WHERE ref.Code ='S803'
 ALTER PROCEDURE [dbo].[CoreAmlSignificantValueHoldingInAccountScenarioAlert_Get]     
(       
 @CaseId INT,       
 @ReportId INT     
)     
AS      
BEGIN         
 ---Geting Client Risk    
 CREATE TABLE #TempLinkRefClientRefRiskCategory  
 (    
  LinkRefClientRefRiskCategoryId INT,    
  RefClientId INT,    
  RefRiskCategoryId INT,    
  FromDate DATETIME,    
  ToDate DATETIME,    
  AddedBy VARCHAR(100) COLLATE DATABASE_DEFAULT,    
  AddedOn DATETIME,    
  LastEditedBy VARCHAR(100) COLLATE DATABASE_DEFAULT,    
  EditedOn DATETIME,    
  Notes VARCHAR(2000) COLLATE DATABASE_DEFAULT    
 )    
    
 CREATE INDEX IX_#TempLinkRefClientRefRiskCategory ON #TempLinkRefClientRefRiskCategory(RefClientId)    
    
 INSERT INTO #TempLinkRefClientRefRiskCategory  
 (    
  LinkRefClientRefRiskCategoryId,    
  RefClientId,    
  RefRiskCategoryId,    
  FromDate,    
  ToDate,    
  AddedBy,    
  AddedOn,    
  LastEditedBy,    
  EditedOn,    
  Notes    
 )    
 SELECT     
  linkrisk.LinkRefClientRefRiskCategoryId,    
  linkrisk.RefClientId,    
  linkrisk.RefRiskCategoryId,    
  linkrisk.FromDate,    
  linkrisk.ToDate,    
  linkrisk.AddedBy,    
  linkrisk.AddedOn,    
  linkrisk.LastEditedBy,    
  linkrisk.EditedOn,    
  linkrisk.Notes    
 FROM LinkRefClientRefRiskCategory linkrisk    
 WHERE linkrisk.RefClientId IN    
 (    
  SELECT ScenarioAlert.RefClientId FROM  CoreAmlScenarioAlert ScenarioAlert     
 )    
    
 SELECT       
  l.LinkRefClientRefRiskCategoryId,   
  l.RefClientId,   
  l.RefRiskCategoryId,   
  l.Notes,   
  l.FromDate,   
  l.ToDate,   
  l.AddedOn,   
  l.EditedOn    
 INTO #TempLinkRefClientRefRiskCategoryLatest    
 FROM  
 (  
  SELECT       
   l.LinkRefClientRefRiskCategoryId,   
   l.RefClientId,   
   l.RefRiskCategoryId,   
   l.Notes,   
   l.FromDate,   
   l.ToDate,   
   l.AddedOn,   
   l.EditedOn,   
   ROW_NUMBER() OVER (PARTITION BY l.RefClientId ORDER BY ISNULL(l.ToDate, '31-Dec-9999') DESC) AS RowNum    
  FROM #TempLinkRefClientRefRiskCategory l) l    
  WHERE l.RowNum = 1    
    
--------------------  
 SELECT    
  c.CoreAmlScenarioAlertId ,     
  c.CoreAlertRegisterCaseId,      
  c.RefClientId,      
  client.DpId,     
  client.ClientId ,       
  client.[Name] AS ClientName,        
  c.RefAmlReportId,      
  c.TransactionDate,        
  c.ValueInLacs,       
  c.ValueInMillions,     
  c.Threshold,  
  c.Income,     
  c.Networth,     
  c.FairValue,     
  c.PriceDate,     
  r.RefInstrumentId,     
  c.ReportDate,     
  ISNULL(c.Risk,risk.[Name]) AS Risk,     
  ISNULL(customerSegment.[Name],'') AS [AccountSegment],  
  ROW_NUMBER() OVER (PARTITION BY c.CoreAmlScenarioAlertId, client.RefClientId ORDER BY linkCustomerSegment.StartDate DESC) AS RowNum,  
  c.Comments,     
  c.ClientExplanation,     
  c.[Status],     
  c.AddedBy,       
  c.AddedOn,       
  c.LastEditedBy,       
  c.EditedOn   
 INTO #FinalTable  
 FROM dbo.CoreAmlScenarioAlert c        
 INNER JOIN dbo.RefAmlReport report ON report.RefAmlReportId = c.RefAmlReportId       
 INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId      
 INNER JOIN dbo.CoreAlertRegisterCase alert ON alert.CoreAlertRegisterCaseId = c.CoreAlertRegisterCaseId     
 LEFT JOIN dbo.RefInstrument r ON c.RefInstrumentId = r.RefInstrumentId       
 LEFT JOIN dbo.RefSegmentEnum s ON s.RefSegmentEnumId = r.RefSegmentId      
 LEFT JOIN #TempLinkRefClientRefRiskCategoryLatest  link ON link.RefClientId = client.RefClientId    
 LEFT JOIN dbo.RefRiskCategory risk ON risk.RefRiskCategoryId=link.RefRiskCategoryId    
 LEFT JOIN dbo.LinkRefClientRefCustomerSegment linkCustomerSegment ON client.RefClientId = linkCustomerSegment.RefClientId  
 LEFT JOIN dbo.RefCustomerSegment customerSegment ON customerSegment.RefCustomerSegmentId = linkCustomerSegment.RefCustomerSegmentId  
 WHERE c.CoreAlertRegisterCaseId = @CaseId AND report.RefAmlReportId = @ReportId   
   
 SELECT * FROM #FinalTable WHERE RowNum = 1  
END    
CoreAmlSignificantValueHoldingInAccountScenarioAlert_Get
CoreAmlSignificantValueHoldingInAccountScenarioAlert_Search
 alter PROCEDURE [dbo].[CoreAmlSignificantValueHoldingInAccountScenarioAlert_Search]     
(        
 @ReportId INT,      
 @RefSegmentEnumId int =null,    
 @FromDate DateTime = NULL,      
 @ToDate DateTime = NULL,      
 @AddedOnFromDate DateTime = NULL,      
 @AddedOnToDate DateTime = NULL,    
 @TxnFromDate DateTime = NULL,      
 @TxnToDate DateTime = NULL,     
 @EditedOnFromDate DATETIME = NULL,      
 @EditedOnToDate DATETIME = NULL,     
 @Client Varchar(500) = NULL,      
 @Status INT = NULL,      
 @Comments Varchar(500) = NULL,    
 @Scrip VARCHAR(200) = NULL,    
 @CaseId BIGINT = NULL,    
 @PageNo INT = 1,    
 @PageSize INT = 100    
)        
AS      
  
 ---Geting Client Risk    
 CREATE TABLE #TempLinkRefClientRefRiskCategory  
 (    
  LinkRefClientRefRiskCategoryId INT,    
  RefClientId INT,    
  RefRiskCategoryId INT,    
  FromDate DATETIME,    
  ToDate DATETIME,    
  AddedBy VARCHAR(100) COLLATE DATABASE_DEFAULT,    
  AddedOn DATETIME,    
  LastEditedBy VARCHAR(100) COLLATE DATABASE_DEFAULT,    
  EditedOn DATETIME,    
  Notes VARCHAR(2000) COLLATE DATABASE_DEFAULT    
 )    
    
 CREATE INDEX IX_#TempLinkRefClientRefRiskCategory ON #TempLinkRefClientRefRiskCategory(RefClientId)    
    
 INSERT INTO #TempLinkRefClientRefRiskCategory  
 (    
  LinkRefClientRefRiskCategoryId,    
  RefClientId,    
  RefRiskCategoryId,    
  FromDate,    
  ToDate,    
  AddedBy,    
  AddedOn,    
  LastEditedBy,    
  EditedOn,    
  Notes    
 )    
 SELECT     
  linkrisk.LinkRefClientRefRiskCategoryId,    
  linkrisk.RefClientId,    
  linkrisk.RefRiskCategoryId,    
  linkrisk.FromDate,    
  linkrisk.ToDate,    
  linkrisk.AddedBy,    
  linkrisk.AddedOn,    
  linkrisk.LastEditedBy,    
  linkrisk.EditedOn,    
  linkrisk.Notes    
 FROM LinkRefClientRefRiskCategory linkrisk    
 WHERE linkrisk.RefClientId IN    
 (    
  SELECT ScenarioAlert.RefClientId FROM  CoreAmlScenarioAlert ScenarioAlert     
 )    
    
 SELECT       
  l.LinkRefClientRefRiskCategoryId,   
  l.RefClientId,   
  l.RefRiskCategoryId,   
  l.Notes,   
  l.FromDate,   
  l.ToDate,   
  l.AddedOn,   
  l.EditedOn    
 INTO #TempLinkRefClientRefRiskCategoryLatest    
 FROM   
 (  
  SELECT       
   l.LinkRefClientRefRiskCategoryId,   
   l.RefClientId,   
   l.RefRiskCategoryId,   
   l.Notes,   
   l.FromDate,   
   l.ToDate,   
   l.AddedOn,   
   l.EditedOn,   
   ROW_NUMBER() OVER (PARTITION BY l.RefClientId ORDER BY ISNULL(l.ToDate, '31-Dec-9999') DESC) AS RowNum    
  FROM #TempLinkRefClientRefRiskCategory l  
 ) l    
 WHERE l.RowNum = 1    
    
 --------------------      
    
 DECLARE @InternalReportId INT    
 SET @InternalReportId = @ReportId    
    
 DECLARE @InternalRefSegmentEnumId INT     
 SET @InternalRefSegmentEnumId = @RefSegmentEnumId    
    
 DECLARE @InternalFromDate DATETIME     
 SET @InternalFromDate = @FromDate    
    
 DECLARE @InternalToDate DATETIME     
 SET @InternalToDate = @ToDate    
    
 DECLARE @InternalAddedOnFromDate DATETIME     
 SET @InternalAddedOnFromDate = @AddedOnFromDate    
    
 DECLARE @InternalAddedOnToDate DATETIME     
 SET @InternalAddedOnToDate = @AddedOnToDate    
    
 DECLARE @InternalTxnFromDate DATETIME     
 SET @InternalTxnFromDate = @TxnFromDate    
    
 DECLARE @InternalTxnToDate DATETIME     
 SET @InternalTxnToDate = @TxnToDate    
    
 DECLARE @InternalClient VARCHAR(500)     
 SET @InternalClient = @Client    
    
 DECLARE @InternalStatus INT     
 SET @InternalStatus = @Status    
    
 DECLARE @InternalComments VARCHAR(500)     
 SET @InternalComments = @Comments    
    
 DECLARE @InternalScrip VARCHAR(200)     
 SET @InternalScrip = @Scrip    
    
 DECLARE @InternalCaseId BIGINT    
 SET @InternalCaseId = @CaseId    
    
 DECLARE @InternalPageNo INT    
 SET @InternalPageNo = @PageNo    
    
 DECLARE @InternalPageSize INT    
 SET @InternalPageSize = @PageSize    
    
 DECLARE @InternalEditedOnFromDate DATETIME    
 SET @InternalEditedOnFromDate = dbo.GetDateWithoutTime(@EditedOnFromDate)    
    
 DECLARE @InternalEditedOnToDate DATETIME    
 SET @InternalEditedOnToDate = CONVERT(DATETIME,DATEDIFF(dd, 0,@EditedOnToDate)) + CONVERT(DATETIME,'23:59:59.000')    
    
BEGIN      
       
 SELECT    
  c.CoreAmlScenarioAlertId ,    
  c.CoreAlertRegisterCaseId,     
  c.RefClientId,     
  client.DpId,    
  client.ClientId ,      
  client.[Name] AS ClientName,       
  c.RefAmlReportId,     
  c.TransactionDate,       
  c.ValueInLacs,      
  c.ValueInMillions,   
  c.Threshold,   
  c.Income,    
  c.Networth,    
  c.FairValue,    
  c.PriceDate,    
  r.RefInstrumentId,    
  c.ReportDate,    
  ISNULL(customerSegment.[Name],'') AS [AccountSegment],  
  ISNULL(c.Risk, risk.[Name]) AS Risk,    
  c.Comments,    
  c.ClientExplanation,    
  c.[Status],    
  inter.[Name] AS IntermediaryName,    
  clSpl.[Name] AS CSCCategory,    
  c.AddedBy,      
  c.AddedOn,      
  c.LastEditedBy,      
  c.EditedOn,    
  ROW_NUMBER() OVER ( ORDER BY c.AddedOn DESC ) AS RowNumber,  
  ROW_NUMBER() OVER (PARTITION BY c.CoreAmlScenarioAlertId, client.RefClientId ORDER BY linkCustomerSegment.StartDate DESC) AS RowNumSegment  
 INTO #temp    
 FROM dbo.CoreAmlScenarioAlert c        
 INNER JOIN dbo.RefAmlReport report ON report.RefAmlReportId = c.RefAmlReportId        
 INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId        
 INNER JOIN dbo.CoreAlertRegisterCase alert ON alert.CoreAlertRegisterCaseId = c.CoreAlertRegisterCaseId      
 LEFT JOIN dbo.RefInstrument r ON c.RefInstrumentId = r.RefInstrumentId      
 LEFT JOIN RefIntermediary inter ON client.RefIntermediaryId = inter.RefIntermediaryId    
 LEFT JOIN RefClientSpecialCategory clSpl ON clSpl.RefClientSpecialCategoryId=client.RefClientSpecialCategoryId    
 LEFT JOIN dbo.RefSegmentEnum s ON s.RefSegmentEnumId = r.RefSegmentId     
 LEFT JOIN #TempLinkRefClientRefRiskCategoryLatest  link ON link.RefClientId=client.RefClientId    
 LEFT JOIN dbo.RefRiskCategory risk ON risk.RefRiskCategoryId=link.RefRiskCategoryId     
 LEFT JOIN dbo.LinkRefClientRefCustomerSegment linkCustomerSegment ON client.RefClientId = linkCustomerSegment.RefClientId  
 LEFT JOIN dbo.RefCustomerSegment customerSegment ON customerSegment.RefCustomerSegmentId = linkCustomerSegment.RefCustomerSegmentId  
 WHERE report.RefAmlReportId = @InternalReportId         
    AND (@InternalRefSegmentEnumId IS NULL OR s.RefSegmentEnumId=@InternalRefSegmentEnumId OR c.RefSegmentEnumId=@InternalRefSegmentEnumId)     
    AND ((@InternalFromDate IS NULL OR dbo.GetDateWithoutTime(c.ReportDate) >= @InternalFromDate) AND (@InternalToDate IS NULL OR dbo.GetDateWithoutTime(c.ReportDate) <= @InternalToDate))      
    AND ((@InternalAddedOnFromDate IS NULL OR dbo.GetDateWithoutTime(c.AddedOn) >= @InternalAddedOnFromDate) AND (@InternalAddedOnToDate IS NULL OR dbo.GetDateWithoutTime(c.AddedOn) <= @InternalAddedOnToDate))     
    AND ((@InternalTxnFromDate IS NULL OR (c.TransactionDate IS NOT NULL AND dbo.GetDateWithoutTime(c.TransactionDate) >= @InternalTxnFromDate) OR (c.TransactionDate IS NULL AND dbo.GetDateWithoutTime(c.TransactionFromDate) >= @InternalTxnFromDate))    
    AND (@InternalTxnToDate IS NULL OR (c.TransactionDate IS NOT NULL AND dbo.GetDateWithoutTime(c.TransactionDate) <= @InternalTxnToDate) OR (c.TransactionDate IS NULL AND dbo.GetDateWithoutTime(c.TransactionToDate) <= @InternalTxnToDate)))       
    AND (@InternalStatus IS NULL OR c.Status = @InternalStatus)       
    AND (@InternalComments IS NULL OR c.Comments like '%' +  @InternalComments +'%')      
    AND (@InternalClient IS NULL OR (client.ClientId like '%' +  @InternalClient +'%' OR client.Name like '%' +  @InternalClient +'%'))        
    AND (@InternalScrip IS NULL OR (r.Name like '%' + @InternalScrip + '%' OR r.Code like '%' + @InternalScrip + '%'))    
    AND (@InternalCaseId IS NULL OR c.CoreAlertRegisterCaseId = @InternalCaseId)          
    AND (@InternalEditedOnFromDate IS NULL OR c.EditedOn >= @InternalEditedOnFromDate) AND (@InternalEditedOnToDate IS NULL OR c.EditedOn <= @InternalEditedOnToDate)    
    
 SELECT    
  CoreAmlScenarioAlertId ,    
  CoreAlertRegisterCaseId,     
  RefClientId,    
  DpId,     
  ClientId ,      
  ClientName,       
  RefAmlReportId,     
  TransactionDate,       
  ValueInLacs,      
  ValueInMillions,    
  Threshold,  
  Income,    
  Networth,    
  FairValue,    
  PriceDate,    
  RefInstrumentId,    
  ReportDate,    
  AccountSegment,  
  Comments,    
  ClientExplanation,    
  [Status],    
  IntermediaryName,    
  CSCCategory,    
  AddedBy,      
  AddedOn,      
  LastEditedBy,      
  EditedOn,    
  Risk    
    FROM #temp t  
    WHERE t.RowNumber BETWEEN ( ( ( @InternalPageNo - 1 ) * @InternalPageSize ) + 1 ) AND @InternalPageNo * @InternalPageSize  AND t.RowNumSegment = 1  
    ORDER BY t.CoreAmlScenarioAlertId DESC  
            
    SELECT COUNT(1)    
    FROM #temp      
END    