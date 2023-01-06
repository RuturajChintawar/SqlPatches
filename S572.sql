DECLARE @RefEntityTypeId INT
SELECT @RefEntityTypeId=RefEntityTypeId FROM dbo.RefEntityType WHERE Code='AmlScenarioRuleUi'
INSERT INTO dbo.RefEntityColumn 
(	[NAME],
	RefEntityTypeId,
	AddedBy ,
	AddedOn ,
	LastEditedBy ,
	EditedOn
)VALUES(
	'Threshold6',
	@RefEntityTypeId,
	'System' , 
	GETDATE() , 
	'System' ,
	GETDATE()
)


------WEB-64402 RC START----
GO
ALTER TABLE dbo.RefAmlReport ADD Threshold6DisplayName VARCHAR(500)
GO
------WEB-64402 RC END---
------WEB-64402 RC START----
GO
ALTER TABLE dbo.RefAmlScenarioRule ADD Threshold6 VARCHAR(500)
GO
------WEB-64402 RC END---
------WEB-64402 RC START----
GO
CREATE PROCEDURE dbo.RefAmlReport_GetThreshold6DisplayName
(
	@ReportCode VARCHAR(100)
)
AS 
BEGIN
	SELECT Threshold6DisplayName FROM dbo.RefAmlReport WHERE code = @ReportCode
END
GO
------WEB-64402 RC END---
GO
ALTER PROCEDURE dbo.RefAmlScenarioRule_Search 
(  
 @AmlReportId INT = NULL,  
 @ConstitutionTypeId INT = NULL,  
 @ClientStatusId INT = NULL,  
 @ScripGroupId INT = NULL,  
 @InstrumentTypeId INT = NULL,
 @SegmentId INT = NULL
 )  
AS  
BEGIN  
 SELECT rasr.RefAmlScenarioRuleId As Id,  
  rasr.RuleNumber,  
  CASE   
   WHEN rvt.Name = 'Payment' THEN 'Out'  
   WHEN rvt.Name = 'Receipt' THEN 'In'  
   ELSE NULL  
  END AS Direction,  
  Stuff(  
  (  
   SELECT ', ' + rct.Code  
   FROM dbo.RefAmlScenarioRule a  
   INNER JOIN dbo.LinkRefAmlScenarioRuleRefConstitutionType linkrasrrc ON rasr.RefAmlScenarioRuleId = linkrasrrc.RefAmlScenarioRuleId  
   INNER JOIN dbo.RefConstitutionType rct ON linkrasrrc.RefConstitutionTypeId = rct.RefConstitutionTypeId  
   WHERE a.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId and a.RefEntityTypeId is null 
   FOR XML path('')  
  ), 1, 2, '') AS Constitution,    
  Stuff(  
  (  
   SELECT ', ' + rcs.Name  
   FROM dbo.RefAmlScenarioRule a  
   INNER JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus linkrClientStatus ON rasr.RefAmlScenarioRuleId = linkrClientStatus.RefAmlScenarioRuleId  
   INNER JOIN dbo.RefClientStatus rcs ON linkrClientStatus.RefClientStatusId = rcs.RefClientStatusId  
   WHERE a.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId  and a.RefEntityTypeId is null 
   FOR XML path('')  
  ), 1, 2, '') AS ClientStatus,    
  Stuff(  
  (  
   SELECT ', ' + rsg.Name  
   FROM dbo.RefAmlScenarioRule a  
   INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup linkScripGroup ON rasr.RefAmlScenarioRuleId = linkScripGroup.RefAmlScenarioRuleId  
   INNER JOIN dbo.RefScripGroup rsg ON linkScripGroup.RefScripGroupId = rsg.RefScripGroupId  
   WHERE a.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId and a.RefEntityTypeId is null  
   FOR XML path('')  
  ), 1, 2, '') AS ScripGroup,
  Stuff(  
  (  
   SELECT ', ' + seg.Segment  
   FROM dbo.RefAmlScenarioRule a  
   INNER JOIN dbo.LinkRefAmlScenarioRuleRefSegmentEnum linkSegment ON rasr.RefAmlScenarioRuleId = linkSegment.RefAmlScenarioRuleId  
   INNER JOIN dbo.RefSegmentEnum seg ON linkSegment.RefSegmentEnumId = seg.RefSegmentEnumId  
   WHERE a.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId and a.RefEntityTypeId is null  
   FOR XML path('')  
  ), 1, 2, '') AS Segments,
  Stuff(  
  (  
   SELECT ', ' + rit.InstrumentType  
   FROM dbo.RefAmlScenarioRule a  
   INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType linkInstrumentType ON rasr.RefAmlScenarioRuleId = linkInstrumentType.RefAmlScenarioRuleId  
   INNER JOIN dbo.RefInstrumentType rit ON linkInstrumentType.RefInstrumentTypeId = rit.RefInstrumentTypeId  
   WHERE a.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId  and a.RefEntityTypeId is null 
   FOR XML path('')  
  ), 1, 2, '') AS InstrumentType,    
  STUFF(  
  (  
   SELECT ', ' + rrc.Name  
   FROM dbo.RefAmlScenarioRule a  
   INNER JOIN dbo.LinkRefAmlScenarioRuleRefRiskCategory linkRiskCategory ON rasr.RefAmlScenarioRuleId = linkRiskCategory.RefAmlScenarioRuleId  
   INNER JOIN dbo.RefRiskCategory rrc ON linkRiskCategory.RefRiskCategoryId = rrc.RefRiskCategoryId  
   WHERE a.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId  and a.RefEntityTypeId is null 
   FOR XML PATH('')  
  ),1,2,'') AS RiskCategory,  
  
  
   STUFF(  
  (  
   SELECT ', ' + rg.Name  
   FROM dbo.RefAmlScenarioRule a  
   INNER JOIN dbo.LinkRefAmlScenarioRuleRefGsm linkGsm ON rasr.RefAmlScenarioRuleId = linkGsm.RefAmlScenarioRuleId  
   INNER JOIN dbo.refGsm rg ON linkGsm.RefGSMId = rg.RefGSMId  
   WHERE a.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId  and a.RefEntityTypeId is null 
   FOR XML PATH('')  
  ),1,2,'') AS GsmStages, 
  
  
  
  rasr.Threshold,  
  rasr.Threshold2,
  rasr.Threshold3, 
  rasr.Threshold4,
  rasr.Threshold5,
  rasr.Threshold6,
  CASE WHEN rasr.IsBuy = 1 THEN 'Buy' WHEN rasr.IsBuy = 0 THEN 'Sell' ELSE NULL END AS BuySell,  
  rasr.AddedBy,  
  rasr.AddedOn,  
  rasr.LastEditedBy,  
  rasr.EditedOn
 FROM dbo.RefAmlScenarioRule rasr  
 INNER JOIN dbo.RefAmlReport rar ON rar.RefAmlReportId = rasr.RefAmlReportId  
 LEFT JOIN dbo.RefVoucherType rvt ON rvt.RefVoucherTypeId = rasr.RefVoucherTypeId  
 WHERE (  
   @AmlReportId IS NULL  
   OR rar.RefAmlReportId = @AmlReportId  
   )  
  AND (  
   @ConstitutionTypeId IS NULL  
   OR EXISTS (  
    SELECT 1  
    FROM dbo.LinkRefAmlScenarioRuleRefConstitutionType link  
    WHERE link.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId  
     AND link.RefConstitutionTypeId = @ConstitutionTypeId  
    )  
   )     
  AND (  
   @ClientStatusId IS NULL  
   OR EXISTS (  
    SELECT 1  
    FROM dbo.LinkRefAmlScenarioRuleRefClientStatus clientStatusLink  
    WHERE clientStatusLink.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId  
     AND clientStatusLink.RefClientStatusId = @ClientStatusId  
    )  
   )     
  AND (  
   @ScripGroupId IS NULL  
   OR EXISTS (  
    SELECT 1  
    FROM dbo.LinkRefAmlScenarioRuleRefScripGroup scripGroupLink  
    WHERE scripGroupLink.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId  
     AND scripGroupLink.RefScripGroupId = @ScripGroupId  
    )  
   )    
  AND (  
   @SegmentId IS NULL  
   OR EXISTS (  
    SELECT 1  
    FROM dbo.LinkRefAmlScenarioRuleRefSegmentEnum segmentLink  
    WHERE segmentLink.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId  
     AND segmentLink.RefSegmentEnumId = @SegmentId  
    )  
   )
  AND (  
   @InstrumentTypeId IS NULL     OR EXISTS (  
    SELECT 1  
    FROM dbo.LinkRefAmlScenarioRuleRefInstrumentType instrumentTypeLink  
    WHERE instrumentTypeLink.RefAmlScenarioRuleId = rasr.RefAmlScenarioRuleId  
     AND instrumentTypeLink.RefInstrumentTypeId = @InstrumentTypeId  
    )
  and rasr.RefEntityTypeId is null   
   )
END  
GO
------WEB-64402 RC END---