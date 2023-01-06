---RC start WEB-66627
GO
ALTER TABLE dbo.CoreMigrationExternalAlert    
DROP CONSTRAINT UQ_CoreScreeningExternalAlert_LegacyAlertId 

ALTER TABLE dbo.CoreMigrationExternalAlert  
ALTER COLUMN LegacyAlertId varchar(200)


ALTER TABLE dbo.CoreMigrationExternalAlert
	ADD CONSTRAINT UQ_CoreScreeningExternalAlert_LegacyAlertId 
	UNIQUE (LegacyAlertId)
GO
---RC end WEB-66627
---RC start WEB-66627
GO
ALTER TABLE dbo.StagingScreeningFl79Alert    
ALTER COLUMN  LegacyAlertId varchar(200)
GO
---RC end WEB-66627
---RC start WEB-66627
GO
ALTER PROCEDURE [dbo].[CoreScreeningExternalAlert_InsertFromStagingScreeningFl79Alert] (@Guid VARCHAR(40))      
AS      
BEGIN  

 DECLARE @RecordLineNo INT,      
  @CurrentDate DATETIME,      
  @CurrentDateWithoutTime DATE,      
  @AlertTypeRefEnumValueId INT,      
  @AlertClassificationRefEnumTypeId INT      
      
 SET @RecordLineNo = 0      
 SET @CurrentDate = GETDATE()      
 SET @CurrentDateWithoutTime = @CurrentDate      
 SET @AlertTypeRefEnumValueId = dbo.GetEnumValueId('AlertType', 'Fl79AlertMigration')      
 SET @AlertClassificationRefEnumTypeId = dbo.GetEnumTypeId('ExternalAlertClassification')  
      
 UPDATE dbo.StagingScreeningFl79Alert      
 SET @RecordLineNo = RecordLineNo = @RecordLineNo + 1      
      
 SELECT stag.StagingScreeningFl79AlertId,      
  stag.[GUID],      
  stag.SourceSystemName,      
  stag.SrcSysCustCode,      
  stag.AlertDate,      
  stag.LegacyAlertId,      
  stag.Source,      
  stag.SourceID,      
  stag.Decision,      
  stag.DispositionRemarks,      
  stag.OtherDetails,      
  stag.CustomerName,      
  stag.PriorityScore,      
  stag.DecisionChangedBy,      
  stag.DecisionChangedOn,      
  stag.ModifiedOn,      
  stag.AlertClassification,      
  stag.ListName,      
  stag.RiskScore,      
  stag.AddedBy,      
  stag.AddedOn,      
  ROW_NUMBER() OVER(ORDER BY stag.StagingScreeningFl79AlertId)  AS RecordLineNo      
 INTO #TempStaging      
 FROM dbo.StagingScreeningFl79Alert stag      
 WHERE stag.[GUID] = @Guid       
      
 CREATE TABLE #Rejection (      
  StagingScreeningFl79AlertId INT NOT NULL,      
  RejectionMessage VARCHAR(MAX) COLLATE DATABASE_DEFAULT      
  )      
 INSERT INTO #Rejection  
 (  
   StagingScreeningFl79AlertId  
 )  
 SELECT  
   stag.StagingScreeningFl79AlertId  
 FROM #TempStaging stag  
      
DECLARE @ErrorString VARCHAR(500)      
SET @ErrorString = 'Error in FL79 Alerts Migration at Line : '      
 ------------------------------------------------------------------------------------------------------------------------------------------------------        
   
 UPDATE rej  
 SET rej.RejectionMessage=ISNULL(rej.RejectionMessage,'')+', LegacyAlertId should not be blank for any alert'   
 FROM dbo.#TempStaging stag  
 INNER JOIN #Rejection  rej ON rej.StagingScreeningFl79AlertId=stag.StagingScreeningFl79AlertId  
 WHERE ISNULL(stag.LegacyAlertId, '') = ''   
  
 ------------------------------------------------------------------------------------------------------------------------------------------------------        
 UPDATE rej  
 SET rej.RejectionMessage=ISNULL(rej.RejectionMessage,'')+', Alert Classification '+ISNULL(stag.AlertClassification,'')COLLATE DATABASE_DEFAULT+' not as expected'   
 FROM dbo.#TempStaging stag  
 LEFT JOIN dbo.RefEnumValue enum ON stag.AlertClassification = enum.Code      
 AND enum.RefEnumTypeId = @AlertClassificationRefEnumTypeId     
 INNER JOIN #Rejection  rej ON rej.StagingScreeningFl79AlertId=stag.StagingScreeningFl79AlertId  
 WHERE ISNULL(enum.RefEnumValueId, 0) = 0   
  
 -----------------------------------------------------------        
 SELECT stag.LegacyAlertId,      
  COUNT(1) AS TotalCount      
 INTO #TempLegacyAlertIds      
 FROM #TempStaging stag      
 GROUP BY stag.LegacyAlertId      
      
 UPDATE rej  
 SET rej.RejectionMessage=ISNULL(rej.RejectionMessage,'')+', LegacyAlertId '+ISNULL(stag.LegacyAlertId,'')COLLATE DATABASE_DEFAULT+' is not unique'   
 FROM dbo.#TempStaging stag  
 INNER JOIN #TempLegacyAlertIds tempLegacy ON tempLegacy.LegacyAlertId = stag.LegacyAlertId   
 INNER JOIN #Rejection  rej ON rej.StagingScreeningFl79AlertId=stag.StagingScreeningFl79AlertId  
 WHERE tempLegacy.TotalCount > 1    
  
      
 -----------------------------------------------------------------        
      
 UPDATE rej  
 SET rej.RejectionMessage=ISNULL(rej.RejectionMessage,'')+', Alert Date '+ISNULL(stag.AlertDate, '')COLLATE DATABASE_DEFAULT+' should be in DD-MMM-YYYY format'   
 FROM dbo.#TempStaging stag  
 INNER JOIN #Rejection  rej ON rej.StagingScreeningFl79AlertId=stag.StagingScreeningFl79AlertId  
 WHERE ISNULL(stag.AlertDate, '') <> ''      
 AND stag.AlertDate NOT LIKE '[0-3][0-9]-[A-Z][A-Z][A-Z]-[1-2][0-9][0-9][0-9]'     
      
  
 UPDATE rej  
 SET rej.RejectionMessage=ISNULL(rej.RejectionMessage,'')+', Decision Changed On '+ISNULL(stag.DecisionChangedOn, '')COLLATE DATABASE_DEFAULT+' should be in DD-MMM-YYYY format'   
 FROM dbo.#TempStaging stag  
 INNER JOIN #Rejection  rej ON rej.StagingScreeningFl79AlertId=stag.StagingScreeningFl79AlertId  
 WHERE ISNULL(stag.DecisionChangedOn, '') <> ''      
 AND stag.DecisionChangedOn NOT LIKE '[0-3][0-9]-[A-Z][A-Z][A-Z]-[1-2][0-9][0-9][0-9]'      
     
      
   
 UPDATE rej  
 SET rej.RejectionMessage=ISNULL(rej.RejectionMessage,'')+', Modified On '+ISNULL(stag.ModifiedOn, '')COLLATE DATABASE_DEFAULT+' should be in DD-MMM-YYYY format'   
 FROM dbo.#TempStaging stag  
 INNER JOIN #Rejection  rej ON rej.StagingScreeningFl79AlertId=stag.StagingScreeningFl79AlertId  
 WHERE ISNULL(stag.ModifiedOn, '') <> ''      
 AND stag.ModifiedOn NOT LIKE '[0-3][0-9]-[A-Z][A-Z][A-Z]-[1-2][0-9][0-9][0-9]'      
    
      
 --------------------------------------------------------------------------        
 UPDATE alert      
 SET alert.SourceSystemName = stag.SourceSystemName,      
  alert.SourceSystemCustomerCode = stag.SrcSysCustCode,      
  alert.AlertDate = CONVERT(DATETIME, stag.AlertDate),      
  alert.Source = stag.Source,   
  alert.SourceId=stag.SourceId,  
  alert.Decision=stag.Decision,  
  alert.DispositionRemarks = stag.DispositionRemarks,      
  alert.OtherDetails = stag.OtherDetails,      
  alert.CustomerName = stag.CustomerName,      
  alert.PriorityScore = stag.PriorityScore,      
  alert.DecisionChangedBy = stag.DecisionChangedBy,      
  alert.DecisionChangedOn = stag.DecisionChangedOn,      
  alert.ModifiedOn = stag.ModifiedOn,      
  alert.AlertClassification = stag.AlertClassification,   
  alert.AlertClassificationRefEnumValueId=enum.RefEnumValueId,  
  alert.ListName = stag.ListName,      
  alert.RiskScore = stag.RiskScore,      
  alert.LastEditedBy = stag.AddedBy,      
  alert.EditedOn = @CurrentDate      
 FROM dbo.#TempStaging stag      
 LEFT JOIN #Rejection rej ON rej.StagingScreeningFl79AlertId = stag.StagingScreeningFl79AlertId    
 LEFT JOIN dbo.CoreMigrationExternalAlert alert ON alert.LegacyAlertId = stag.LegacyAlertId 
 LEFT JOIN dbo.RefEnumValue enum ON stag.AlertClassification = enum.Code
 WHERE  rej.RejectionMessage IS NULL      
  AND alert.CoreMigrationExternalAlertId IS NOT NULL      
  AND NOT EXISTS (      
   SELECT 1      
   FROM CoreMigrationExternalAlert exchAlert      
   WHERE ISNULL(exchAlert.SourceSystemName, '') = ISNULL(stag.SourceSystemName, '')      
    AND ISNULL(exchAlert.SourceSystemCustomerCode, '') = ISNULL(stag.SrcSysCustCode, '')      
    AND ISNULL(exchAlert.AlertDate, @CurrentDateWithoutTime) = CONVERT(DATETIME, stag.AlertDate)      
    AND ISNULL(exchAlert.Source, '') = ISNULL(stag.Source, '')      
    AND ISNULL(exchAlert.SourceId, '') = ISNULL(stag.SourceID, '')      
    AND ISNULL(exchAlert.Decision, '') = ISNULL(stag.Decision, '')      
    AND ISNULL(exchAlert.DispositionRemarks, '') = ISNULL(stag.DispositionRemarks, '')      
    AND ISNULL(exchAlert.OtherDetails, '') = ISNULL(stag.OtherDetails, '')      
    AND ISNULL(exchAlert.CustomerName, '') = ISNULL(stag.CustomerName, '')      
    AND ISNULL(exchAlert.PriorityScore, '') = ISNULL(stag.PriorityScore, '')      
    AND ISNULL(exchAlert.DecisionChangedBy, '') = ISNULL(stag.DecisionChangedBy, '')      
    AND ISNULL(exchAlert.ModifiedOn, '') = ISNULL(stag.ModifiedOn, '')      
    AND ISNULL(exchAlert.AlertClassification, '') = ISNULL(stag.AlertClassification, '')      
    AND ISNULL(exchAlert.ListName, '') = ISNULL(stag.ListName, '')      
    AND ISNULL(exchAlert.RiskScore, '') = ISNULL(stag.RiskScore, '')      
    AND ISNULL(exchAlert.AlertClassificationRefEnumValueId, '') = ISNULL(enum.RefEnumValueId, '')      
   )      
        
      
 --------------------------------------------------------------------------------------------------------------------------------------------------------        
 INSERT INTO dbo.CoreMigrationExternalAlert (      
  SourceSystemName,      
  SourceSystemCustomerCode,      
  AlertTypeRefEnumValueId,      
  AlertDate,      
  LegacyAlertId,      
  Source,      
  SourceId,      
  Decision,      
  DispositionRemarks,      
  OtherDetails,      
  CustomerName,      
  PriorityScore,      
  DecisionChangedBy,      
  DecisionChangedOn,      
  ModifiedOn,      
  AlertClassification,      
  AlertClassificationRefEnumValueId,      
  ListName,      
  RiskScore,      
  AddedBy,      
  AddedOn,      
  LastEditedBy,      
  EditedOn      
  )      
 SELECT stag.SourceSystemName,      
  stag.SrcSysCustCode,      
  @AlertTypeRefEnumValueId,      
  CONVERT(DATETIME, stag.AlertDate),      
  stag.LegacyAlertId,      
  stag.Source,      
  stag.SourceId,      
  stag.Decision,      
  stag.DispositionRemarks,      
  stag.OtherDetails,      
  stag.CustomerName,      
  stag.PriorityScore,      
  stag.DecisionChangedBy,      
  stag.DecisionChangedOn,      
  stag.ModifiedOn,      
  stag.AlertClassification,      
  enum.RefEnumValueId,      
  stag.ListName,      
  stag.RiskScore,      
  stag.AddedBy,      
  @CurrentDate,      
  stag.AddedBy,      
  @CurrentDate      
 FROM dbo.#TempStaging stag      
 LEFT JOIN #Rejection rej ON rej.StagingScreeningFl79AlertId = stag.StagingScreeningFl79AlertId       
 LEFT JOIN dbo.CoreMigrationExternalAlert alert ON alert.LegacyAlertId = stag.LegacyAlertId 
 LEFT JOIN dbo.RefEnumValue enum ON stag.AlertClassification = enum.Code AND enum.RefEnumTypeId = @AlertClassificationRefEnumTypeId 
 WHERE  rej.RejectionMessage IS NULL     
  AND alert.CoreMigrationExternalAlertId IS NULL   
      
 ------------------------------------------------------------------------------------        
 UPDATE stage      
 SET stage.ErrorDescription = @ErrorString+CONVERT(VARCHAR(10),stag.RecordLineNo) +rej.RejectionMessage,      
  stage.RowDescription = CASE       
   WHEN  rej.RejectionMessage IS NULL      
    THEN 'Success'      
   ELSE 'Failure'      
   END      
 FROM dbo.StagingScreeningFl79Alert stage  
 INNER JOIN #TempStaging stag ON stag.StagingScreeningFl79AlertId=stage.StagingScreeningFl79AlertId  
 LEFT JOIN #Rejection rej ON stage.StagingScreeningFl79AlertId = rej.StagingScreeningFl79AlertId      
 WHERE stage.ErrorDescription IS NULL      
  AND stage.[GUID] = @Guid      
      
 --------------------------------------------------------------        
 SELECT stage.ErrorDescription AS ErrorMessage      
 FROM dbo.StagingScreeningFl79Alert stage      
 WHERE stage.[GUID] = @GUID      
 AND stage.RowDescription = 'Failure'      
      
 DELETE      
 FROM dbo.StagingScreeningFl79Alert      
 WHERE [Guid] = @GUID   
 
 END  
GO
---RC end WEB-66627
---RC start WEB-66627
GO
DECLARE
@RefReportId INT 
SET @RefReportId=(SELECT RefReportId FROM dbo.RefReport WHERE Code='R611')

UPDATE ref
SET ref.ColumnDataType='varchar'
FROM dbo.RefReportColumn ref
WHERE ref.RefReportId=@RefReportId AND
ref.ReportColumnName='LegacyAlertId'

GO
---RC end WEB-66627
exec [CoreScreeningExternalAlert_InsertFromStagingScreeningFl79Alert] 'eabcc9eb-d53e-45a4-ae1d-657099029c8c'