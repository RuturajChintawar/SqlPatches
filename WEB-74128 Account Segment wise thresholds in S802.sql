--WEB-74128 RC START
GO
DECLARE @S802Id INT, @HoldingPercentVal VARCHAR(MAX)

SELECT @S802Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S802 Significant Holding In Listed Scrip'

SELECT @HoldingPercentVal = [Value]
FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S802Id AND [Name] = 'Holding %'


INSERT INTO dbo.RefAmlScenarioRule
(
	RuleNumber,
	RefAmlReportId,
	Threshold,
	Threshold6,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn
)
SELECT
	ISNULL((SELECT MAX(RuleNumber) FROM dbo.RefAmlScenarioRule)+1,1),
	@S802Id,
	0,
	ISNULL(@HoldingPercentVal,''),
	'System',
	GETDATE(),
	'System',
	GETDATE()
GO
--WEB-74128 RC END
--WEB-74128 RC START
GO
DECLARE @S802Id INT, @RuleId INT

SELECT @S802Id = RefAmlReportId FROM dbo.RefAmlReport
WHERE [Name] = 'S802 Significant Holding In Listed Scrip'

SELECT @RuleId = RefAmlScenarioRuleId FROM dbo.RefAmlScenarioRule WHERE RefAmlReportId = @S802Id

INSERT INTO dbo.LinkRefAmlScenarioRuleRefCustomerSegment
(
	RefAmlScenarioRuleId,
	RefCustomerSegmentId,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn
)
SELECT
	ISNULL(@RuleId,1),
	NULL,
	'System',
	GETDATE(),
	'System',
	GETDATE()
GO
--WEB-74128 RC END
--WEB-74128 RC START
GO
UPDATE dbo.RefAmlReport
SET
	IsRuleRequired = 1
WHERE [Name] = 'S802 Significant Holding In Listed Scrip'
GO
--WEB-74128 RC END
--WEB-74128 RC START
GO
DECLARE @S802Id INT

SELECT @S802Id = RefAmlReportId FROM dbo.RefAmlReport
WHERE [Name] = 'S802 Significant Holding In Listed Scrip'

DELETE makerChecker FROM
dbo.CoreAmlScenarioRuleMakerChecker makerChecker
INNER JOIN dbo.SysAmlReportSetting sett ON makerChecker.SysAmlReportSettingId = sett.SysAmlReportSettingId
AND sett.RefAmlReportId = @S802Id 

DELETE FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @S802Id 
GO
--WEB-74128 RC END
--WEB-74128 RC START
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
 AccountSegment  
        FROM (SELECT cl.RefClientId,    
      holding.RefInstrumentId,    
      cl.DpId,    
      cl.ClientId,                    
      cl.Name AS ClientName,                    
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
     custSeg.[Name] AS AccountSegment   
    
    FROM  #ClientDematAccountTotalHolding holding     
      INNER JOIN dbo.RefClientDematAccount demat ON demat.RefClientDematAccountId = holding.RefClientDematAccountId    
      INNER JOIN dbo.RefClient cl ON cl.RefClientId = demat.RefClientId AND     
      (cl.RefClientAccountStatusId NOT IN(@SuspendedAccountStatusId,@SuspendedDrAccountStatusId,@SuspendedDrCrAccountStatusId) or cl.RefClientAccountStatusId IS NULL)   
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
--WEB-74128 RC END