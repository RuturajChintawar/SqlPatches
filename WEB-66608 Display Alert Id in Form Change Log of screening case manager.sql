--WEB-66608-RC-Start
GO
 ALTER PROCEDURE dbo.CoreScreeningCase_Audit_GetChangeLogsForCaseManager (@Id  
INT,  
@FromDate DATETIME = NULL,  
@ToDate   DATETIME = NULL)  
AS  
BEGIN  
DECLARE @InternalId       INT,  
@InternalFromDate DATETIME,  
@InternalToDate   DATETIME  
  
SET @InternalId = @Id  
SET @InternalFromDate = dbo.Getdatewithouttime(@FromDate)  
SET @InternalToDate = Dateadd(ss, -1, Dateadd(day, 1,  
dbo.Getdatewithouttime(@ToDate)))  
  
--Table 1: Case Audit    
SELECT pepEnum.[name]         AS PEP,  
caseAudit.finalremarks AS FinalComments,  
caseAudit.updatecolumns,  
caseAudit.auditdmlaction,  
caseAudit.auditdatastate,  
caseAudit.auditdatetime,  
caseAudit.lasteditedby  
FROM   dbo.corescreeningcase_audit caseAudit  
LEFT JOIN dbo.refenumvalue pepEnum  
ON pepEnum.refenumvalueid = caseAudit.peprefenumvalueid  
WHERE  caseAudit.corescreeningcaseid = @InternalId  
AND ( ( ( @InternalFromDate IS NULL  
OR @InternalToDate IS NULL )  
AND ( caseAudit.auditdatetime IS NOT NULL ) )  
OR ( ( @InternalFromDate IS NOT NULL  
AND @InternalToDate IS NOT NULL )  
AND ( caseAudit.auditdatetime >= @InternalFromDate  
AND caseAudit.auditdatetime <= @InternalToDate )  
)  
)  
  
-- Table 2: Adverse Media Classification    
DECLARE @AMClassificationEnumTypeId INT  
  
SELECT @AMClassificationEnumTypeId =  
dbo.Getenumtypeid('AdverseMediaClassification')  
  
SELECT STUFF(( SELECT ', '+  enum.[Name]    
		FROM dbo.coreentityenumvalue_audit audi1 
		INNER JOIN dbo.refenumvalue enum  
		ON enum.refenumtypeid = @AMClassificationEnumTypeId  
			AND audi1.refenumvalueid = enum.refenumvalueid 
		WHERE audi1.auditdmlaction=entityEnumAudit.AuditDMLAction And
		audi1.auditdatastate=entityEnumAudit.auditdatastate and
		audi1.auditdatetime=entityEnumAudit.auditdatetime and
		audi1.lasteditedby=entityEnumAudit.lasteditedby
		FOR XML PATH('')),1,1,'') [Name],  
entityEnumAudit.auditdmlaction,  
entityEnumAudit.auditdatastate,  
entityEnumAudit.auditdatetime,  
entityEnumAudit.lasteditedby  
FROM   dbo.coreentityenumvalue_audit entityEnumAudit  
WHERE  entityEnumAudit.entityid = @InternalId  
AND entityEnumAudit.refenumtypeid = @AMClassificationEnumTypeId  
AND ( ( @InternalFromDate IS NULL )  
OR ( entityEnumAudit.auditdatetime >= @InternalFromDate  
AND entityEnumAudit.auditdatetime < @InternalToDate ) )  
GROUP BY entityEnumAudit.auditdmlaction,  entityEnumAudit.auditdatastate,  entityEnumAudit.auditdatetime,entityEnumAudit.lasteditedby
ORDER  BY entityEnumAudit.auditdatetime,  
entityEnumAudit.auditdmlaction,  
entityEnumAudit.auditdatastate DESC  

  
-- TABLE 3: Reputation CLassification    
DECLARE @ReputationClassificationEnumTypeId INT  
  
SELECT @ReputationClassificationEnumTypeId =  
dbo.Getenumtypeid('ReputationClassification')  
  
SELECT enum.[name] AS [Name],  
entityEnumAudit.auditdmlaction,  
entityEnumAudit.auditdatastate,  
entityEnumAudit.auditdatetime,  
entityEnumAudit.lasteditedby  
FROM   dbo.coreentityenumvalue_audit entityEnumAudit  
INNER JOIN dbo.refenumvalue enum  
ON enum.refenumtypeid = @ReputationClassificationEnumTypeId  
AND entityEnumAudit.refenumvalueid = enum.refenumvalueid  
WHERE  entityEnumAudit.entityid = @InternalId  
AND entityEnumAudit.refenumtypeid =  
@ReputationClassificationEnumTypeId  
AND ( ( @InternalFromDate IS NULL )  
OR ( entityEnumAudit.auditdatetime >= @InternalFromDate  
AND entityEnumAudit.auditdatetime < @InternalToDate ) )  
ORDER  BY entityEnumAudit.auditdatetime,  
entityEnumAudit.auditdmlaction,  
entityEnumAudit.auditdatastate DESC  
  
-- TABLE 4: PEP CLassification    
DECLARE @PEPClassificationEnumTypeId INT  
  
SELECT @PEPClassificationEnumTypeId =  
dbo.Getenumtypeid('PEPClassification')  
  
SELECT enum.[name]AS [Name],  
entityEnumAudit.auditdmlaction,  
entityEnumAudit.auditdatastate,  
entityEnumAudit.auditdatetime,  
entityEnumAudit.lasteditedby  
FROM   dbo.coreentityenumvalue_audit entityEnumAudit  
INNER JOIN dbo.refenumvalue enum  
ON enum.refenumtypeid = @PEPClassificationEnumTypeId  
AND entityEnumAudit.refenumvalueid = enum.refenumvalueid  
WHERE  entityEnumAudit.entityid = @InternalId  
AND entityEnumAudit.refenumtypeid = @PEPClassificationEnumTypeId  
AND ( ( @InternalFromDate IS NULL )  
OR ( entityEnumAudit.auditdatetime >= @InternalFromDate  
AND entityEnumAudit.auditdatetime < @InternalToDate ) )  
ORDER  BY entityEnumAudit.auditdatetime,  
entityEnumAudit.auditdmlaction,  
entityEnumAudit.auditdatastate DESC  
  
--Table 5: Case Alert Audit    
SELECT  
alrtDecisionEnum.NAME    [AlertDecision],  
alertAudit.Comments,  
alertAudit.updatecolumns,  
alertAudit.auditdmlaction,  
alertAudit.auditdatastate,  
alertAudit.auditdatetime,  
alertAudit.lasteditedby,  
corescreeningcasealertid AS AlertId  
FROM   dbo.corescreeningcasealert_audit alertAudit  
LEFT JOIN dbo.refenumvalue alrtDecisionEnum  
ON alrtDecisionEnum.refenumvalueid =  
alertAudit.screeningcasealertdecisionrefenumvalueid  
WHERE  alertAudit.corescreeningcaseid = @InternalId  
AND ( ( ( @InternalFromDate IS NULL  
OR @InternalToDate IS NULL )  
AND ( alertAudit.auditdatetime IS NOT NULL ) )  
OR ( ( @InternalFromDate IS NOT NULL  
AND @InternalToDate IS NOT NULL )  
AND ( alertAudit.auditdatetime >= @InternalFromDate  
AND alertAudit.auditdatetime <= @InternalToDate )  
)  
)  
  
--Table 6: Case Comment Audit    
SELECT commentAudit.comment,  
commentAudit.updatecolumns,  
commentAudit.auditdmlaction,  
commentAudit.auditdatastate,  
commentAudit.auditdatetime,  
commentAudit.lasteditedby  
FROM   dbo.corescreeningcasecomment_audit commentAudit  
WHERE  commentAudit.corescreeningcaseid = @InternalId  
AND ( ( ( @InternalFromDate IS NULL  
OR @InternalToDate IS NULL )  
AND ( commentAudit.auditdatetime IS NOT NULL ) )  
OR ( ( @InternalFromDate IS NOT NULL  
AND @InternalToDate IS NOT NULL )  
AND ( commentAudit.auditdatetime >= @InternalFromDate  
AND commentAudit.auditdatetime <= @InternalToDate  
)  
) )  
END   
GO
--WEB-66608-RC-End
exec dbo.CoreScreeningCase_Audit_GetChangeLogsForCaseManager 36274

-- Table 2: Adverse Media Classification    
DECLARE @AMClassificationEnumTypeId INT  
  
SELECT @AMClassificationEnumTypeId =  
dbo.Getenumtypeid('AdverseMediaClassification')  
  
SELECT STUFF(( SELECT ', '+  enum.[Name]    
		FROM dbo.coreentityenumvalue_audit audi1 
		INNER JOIN dbo.refenumvalue enum  
		ON enum.refenumtypeid = @AMClassificationEnumTypeId  
			AND audi1.refenumvalueid = enum.refenumvalueid 
		WHERE audi1.entityid = 36197  and audi1.auditdmlaction=entityEnumAudit.AuditDMLAction And
		audi1.auditdatastate=entityEnumAudit.auditdatastate and
		audi1.lasteditedby=entityEnumAudit.lasteditedby and
		entityEnumAudit.EditedOn=audi1.EditedOn
		FOR XML PATH('')),1,1,'') [Name],  
entityEnumAudit.auditdmlaction,  
entityEnumAudit.auditdatastate,  
entityEnumAudit.lasteditedby,
entityEnumAudit.EditedOn
FROM   dbo.coreentityenumvalue_audit entityEnumAudit  
WHERE  entityEnumAudit.entityid = 36197  
AND entityEnumAudit.refenumtypeid = @AMClassificationEnumTypeId  
GROUP BY entityEnumAudit.auditdmlaction,  entityEnumAudit.auditdatastate,entityEnumAudit.lasteditedby,entityEnumAudit.EditedOn
ORDER  BY entityEnumAudit.EditedOn,  entityEnumAudit.auditdmlaction, entityEnumAudit.auditdatastate DESC  

  