--RC-WEB-66329--START
GO
ALTER PROCEDURE [dbo].[LinkRefClientRefIncomeGroup_InsertFromStagingCoreClientIncomeCategorizationWithExactIncome]    
(    
 @Guid VARCHAR(100)    
)    
as    
begin    
    
DECLARE @RecordLineNo INT     
SET @RecordLineNo = 0     
    
UPDATE dbo.StagingCoreFinancialTransaction     
SET @RecordLineNo = RecordLineNo = @RecordLineNo + 1     
WHERE [GUID]=@Guid    
    
SELECT StagingCoreClientIncomeCategorizationWithExactIncomeId ,    
DatabaseType ,    
DpId,    
ClientId ,    
EffectiveFrom ,    
EffectiveTo,    
ExactIncome ,    
IncomeRange,    
Networth ,    
AddedBy ,    
AddedOn ,    
[GUID] ,    
ROW_NUMBER() OVER (ORDER BY StagingCoreClientIncomeCategorizationWithExactIncomeId ASC)  AS RowNumber      
INTO #tempStaging    
FROM dbo.StagingCoreClientIncomeCategorizationWithExactIncome    
WHERE [GUID]=@Guid    
    
SELECT    
 LinkRefClientRefIncomeGroupId,    
 RefClientId,    
 FromDate,    
 ToDate,    
 ROW_NUMBER() OVER (    
 PARTITION BY RefClientId    
 ORDER BY LinkRefClientRefIncomeGroupId DESC    
 ) rownum    
INTO #tempLinkRefClientRefIncomeGroup    
FROM     
 dbo.LinkRefClientRefIncomeGroup    
    
SELECT * INTO #tempLinkIncomeGroupLatest FROM #tempLinkRefClientRefIncomeGroup WHERE rownum = 1    
    
-------------------------------------------------//VALIDATION START-------------------------------------------------------------------------------    
CREATE TABLE #Rejection          
  (          
   StagingCoreClientIncomeCategorizationWithExactIncomeId INT NOT NULL ,          
   RejectionMessage VARCHAR(MAX) COLLATE DATABASE_DEFAULT          
  )     
    
------------------------------------------------------------------------------------------------------------------------------------------------------    
Declare @ErrorString varchar(500)    
-----------------------------------------------------------------------------------------------------------------------------------------------------    
----Get Duplicate Records Rejection(1)    
    
SET @ErrorString='Error in Client upload at Line : '    
    
SELECT     
 temp.ClientId,    
 ROW_NUMBER() OVER (    
 PARTITION BY temp.ClientId    
 ORDER BY temp.StagingCoreClientIncomeCategorizationWithExactIncomeId ASC     
 ) rownum    
INTO #tempRecords    
FROM     
 #tempStaging temp    
    
SELECT DISTINCT ClientId INTO #duplicateClients FROM #tempRecords WHERE rownum > 1     
    
INSERT INTO #Rejection(StagingCoreClientIncomeCategorizationWithExactIncomeId, RejectionMessage)    
 SELECT temp.StagingCoreClientIncomeCategorizationWithExactIncomeId,    
   @ErrorString + CONVERT(varchar(10),temp.RowNumber) + ',Duplicate Record Found For Client '+ dupClient.ClientId     
     FROM    
      #tempStaging temp     
  INNER JOIN #duplicateClients dupClient ON dupClient.ClientId = temp.ClientId     
    
-------------------------------------------------------------------------------------------------------------------------------------------    
----Client Not Found Rejection(2)    
SET @ErrorString='Error in Client upload at Line : '    
    
INSERT INTO #Rejection(StagingCoreClientIncomeCategorizationWithExactIncomeId,RejectionMessage)          
SELECT temp.StagingCoreClientIncomeCategorizationWithExactIncomeId,          
@ErrorString + CONVERT(varchar(10),temp.RowNumber) + ',Client Not Found In Database '    
FROM dbo.#tempStaging temp     
INNER JOIN dbo.RefClientDatabaseEnum db ON temp.DatabaseType=db.DatabaseType    
LEFT JOIN dbo.RefClient cli ON temp.ClientId=cli.ClientId AND db.RefClientDatabaseEnumId=cli.RefClientDatabaseEnumId AND (db.DatabaseType !='NSDL' OR temp.DpId=cli.DpId )    
WHERE cli.ClientId IS NULL    
AND NOT EXISTS (SELECT 1 FROM #Rejection rej WHERE rej.StagingCoreClientIncomeCategorizationWithExactIncomeId=temp.StagingCoreClientIncomeCategorizationWithExactIncomeId)    
    
-----------------------------------------------------------------------------------------------------------------    
-----Effective from date is null Rejection(3)    
SET @ErrorString='Error in Client Income File for Client Id : '    
    
INSERT INTO #Rejection(StagingCoreClientIncomeCategorizationWithExactIncomeId,RejectionMessage)    
SELECT    
temp.StagingCoreClientIncomeCategorizationWithExactIncomeId,    
@ErrorString + temp.ClientId +'. Line: '+ CONVERT(varchar(10),temp.RowNumber) + ', Start date should be specified for client '+ temp.ClientId    
FROM    
dbo.#tempStaging temp    
WHERE temp.EffectiveFrom IS NULL    
AND NOT EXISTS (SELECT 1 FROM #Rejection rej WHERE rej.StagingCoreClientIncomeCategorizationWithExactIncomeId=temp.StagingCoreClientIncomeCategorizationWithExactIncomeId)    
    
------------------------------------------------------------------------------------------------------------------------------------------------------    
----No database Found Rejection(4)    
SET @ErrorString='Error in Client upload at Line : '    
    
INSERT INTO #Rejection(StagingCoreClientIncomeCategorizationWithExactIncomeId,RejectionMessage)          
SELECT temp.StagingCoreClientIncomeCategorizationWithExactIncomeId,          
@ErrorString + CONVERT(varchar(10),temp.RowNumber) + ',No Such Database Found: ' + temp.DatabaseType    
FROM dbo.#tempStaging temp     
LEFT JOIN dbo.RefClientDatabaseEnum db ON temp.DatabaseType=db.DatabaseType    
WHERE db.DatabaseType IS NULL    
AND NOT EXISTS (SELECT 1 FROM #Rejection WHERE StagingCoreClientIncomeCategorizationWithExactIncomeId=temp.StagingCoreClientIncomeCategorizationWithExactIncomeId)    
    
------------------------------------------------------------------------------------------------------------------------------------------------------    
----No Income Group Found Rejection(5)    
SET @ErrorString='Error in Client upload at Line : '    
    
INSERT INTO #Rejection(StagingCoreClientIncomeCategorizationWithExactIncomeId,RejectionMessage)          
  SELECT temp.StagingCoreClientIncomeCategorizationWithExactIncomeId,          
    @ErrorString + CONVERT(varchar(10),temp.RowNumber) + ',No Such Income Group Found: ' + temp.IncomeRange    
  FROM dbo.#tempStaging temp     
  LEFT JOIN dbo.RefIncomeGroup grp ON (temp.IncomeRange=grp.[Name])    
  WHERE grp.RefIncomeGroupId IS NULL    
  and ISNULL(temp.IncomeRange,'')<>''    
  AND NOT EXISTS (SELECT 1 FROM #Rejection WHERE StagingCoreClientIncomeCategorizationWithExactIncomeId=temp.StagingCoreClientIncomeCategorizationWithExactIncomeId)    
    
------No Income Group Found using ExactIncome when IncomeRange is null     
--INSERT INTO #Rejection(StagingCoreClientIncomeCategorizationWithExactIncomeId,RejectionMessage)          
--  SELECT temp.StagingCoreClientIncomeCategorizationWithExactIncomeId,          
--    @ErrorString + CONVERT(varchar(10),temp.RowNumber) + ',No Such Income Group Found for client : ' + temp.ClientId    
--  FROM dbo.#tempStaging temp     
--  LEFT JOIN dbo.RefIncomeGroup grp ON (CAST(temp.ExactIncome AS INT)>=grp.IncomeFrom AND CAST(temp.ExactIncome AS INT) <= grp.IncomeTo)    
--  WHERE ISNULL(temp.IncomeRange,'')=''    
--  and isnumeric(temp.ExactIncome)=1    
--  AND NOT EXISTS (SELECT 1 FROM #Rejection WHERE StagingCoreClientIncomeCategorizationWithExactIncomeId=temp.StagingCoreClientIncomeCategorizationWithExactIncomeId)    
      
----Exact Income and Income Range cannot be empty Rejection(6)    
SET @ErrorString='Error in Client upload at Line : '    
    
INSERT INTO #Rejection(StagingCoreClientIncomeCategorizationWithExactIncomeId,RejectionMessage)          
  SELECT temp.StagingCoreClientIncomeCategorizationWithExactIncomeId,          
    @ErrorString + CONVERT(varchar(10),temp.RowNumber) + ', Exact Income and Income Range cannot be empty'    
  FROM dbo.#tempStaging temp     
   WHERE isnull(temp.IncomeRange,'')='' and isnumeric(temp.ExactIncome)=0    
  AND NOT EXISTS (SELECT 1 FROM #Rejection WHERE StagingCoreClientIncomeCategorizationWithExactIncomeId=temp.StagingCoreClientIncomeCategorizationWithExactIncomeId)    
    
      
----Invalid Income Group Found for ExactIncome    
INSERT INTO #Rejection(StagingCoreClientIncomeCategorizationWithExactIncomeId,RejectionMessage)   
 Select temp.StagingCoreClientIncomeCategorizationWithExactIncomeId,          
  @ErrorString + CONVERT(varchar(10),temp.RowNumber) + ',Invalid Income Group Found for client : ' + temp.ClientId    
 from #tempStaging temp    
  WHERE     
  ISNULL(temp.IncomeRange,'')<>'' and isnumeric(temp.ExactIncome)=1    
  AND    
  NOT EXISTS     
  (    
   Select 1 from RefIncomeGroup grp where     
   (CAST(temp.ExactIncome AS BIGINT)>=grp.IncomeFrom AND CAST(temp.ExactIncome AS BIGINT) <= grp.IncomeTo)     
   AND temp.IncomeRange=grp.[Name]    
  )    
   AND NOT EXISTS (SELECT 1 FROM #Rejection WHERE StagingCoreClientIncomeCategorizationWithExactIncomeId=temp.StagingCoreClientIncomeCategorizationWithExactIncomeId)    
       
      
    
----Decimal values Found for ExactIncome    
INSERT INTO #Rejection(StagingCoreClientIncomeCategorizationWithExactIncomeId,RejectionMessage)          
 Select temp.StagingCoreClientIncomeCategorizationWithExactIncomeId,          
  @ErrorString + CONVERT(varchar(10),temp.RowNumber) + ',Decimal values are not accepted in Income column, Please enter Exact Income for client : ' + temp.ClientId    
 from #tempStaging temp    
  WHERE     
  ISNUMERIC(temp.ExactIncome) = 1 AND (temp.ExactIncome % 1) > 0    
   AND NOT EXISTS (SELECT 1 FROM #Rejection WHERE StagingCoreClientIncomeCategorizationWithExactIncomeId=temp.StagingCoreClientIncomeCategorizationWithExactIncomeId)    
    
----Negative value Found for Networth    
INSERT INTO #Rejection(StagingCoreClientIncomeCategorizationWithExactIncomeId,RejectionMessage)          
 Select temp.StagingCoreClientIncomeCategorizationWithExactIncomeId,          
  @ErrorString + CONVERT(varchar(10),temp.RowNumber) + ',Negative Networth is not accepted, Please Enter Positive Values ' + 'Client ID: ' + temp.ClientId    
 from #tempStaging temp    
  WHERE     
  ISNUMERIC(temp.Networth) = 1 AND (temp.Networth) < 0    
   AND NOT EXISTS (SELECT 1 FROM #Rejection WHERE StagingCoreClientIncomeCategorizationWithExactIncomeId=temp.StagingCoreClientIncomeCategorizationWithExactIncomeId)    
       
----------------------------------------------------------------------------------------------------------------------    
----From Date Cannot Be Before Latest From Date(6)    
INSERT INTO #Rejection(StagingCoreClientIncomeCategorizationWithExactIncomeId,RejectionMessage)          
  SELECT temp.StagingCoreClientIncomeCategorizationWithExactIncomeId,          
    @ErrorString + CONVERT(varchar(10),temp.RowNumber) + '. From Date Cannot be before: ' + CONVERT(varchar(15), tl.FromDate) + ' for client ' + temp.ClientId    
FROM #tempStaging temp      
 INNER JOIN dbo.RefClientDatabaseEnum db ON temp.DatabaseType=db.DatabaseType    
 INNER JOIN dbo.RefClient cli ON temp.ClientId=cli.ClientId AND db.RefClientDatabaseEnumId=cli.RefClientDatabaseEnumId AND (db.DatabaseType !='NSDL' OR temp.DpId=cli.DpId )    
 INNER JOIN #tempLinkIncomeGroupLatest tl ON tl.RefClientId = cli.RefClientId    
WHERE temp.EffectiveFrom < tl.FromDate     
 AND NOT EXISTS (SELECT 1 FROM #Rejection rej WHERE rej.StagingCoreClientIncomeCategorizationWithExactIncomeId=temp.StagingCoreClientIncomeCategorizationWithExactIncomeId)    
    
---------------------------------------------------------------------------------------------------------------------------------------    
set @ErrorString='Error in Client upload at Line : '    
    
SELECT CASE WHEN ISNUMERIC(tem.ExactIncome)=1 THEN tem.StagingCoreClientIncomeCategorizationWithExactIncomeId END AS StagingCoreClientIncomeCategorizationWithExactIncomeId    
INTO #tempRejection    
FROM #tempStaging tem    
INNER JOIN #Rejection rej ON tem.StagingCoreClientIncomeCategorizationWithExactIncomeId=rej.StagingCoreClientIncomeCategorizationWithExactIncomeId    
WHERE ISNUMERIC(tem.ExactIncome)=1    
--and isnull(ExactIncome,'')<>''    
    
--DELETE Rej    
    
--FROM #Rejection Rej    
--INNER JOIN #tempRejection trej ON Rej.StagingCoreClientIncomeCategorizationWithExactIncomeId=trej.StagingCoreClientIncomeCategorizationWithExactIncomeId     
--INNER JOIN #tempStaging temp ON trej.StagingCoreClientIncomeCategorizationWithExactIncomeId=temp.StagingCoreClientIncomeCategorizationWithExactIncomeId    
--LEFT JOIN dbo.RefIncomeGroup grp ON (CAST(temp.ExactIncome AS INT)>=grp.IncomeFrom AND CAST(temp.ExactIncome AS INT) <= grp.IncomeTo)    
--where isnull(ExactIncome,'')<>''    
    
------------------------------------------------------------------------------------------------------------------------------------------------------    
---//VALIDATION END---    
    
------------------------------------UPDATE TODATE OF ALL OEN ACCOUNTS-------------------------------    
--GET THE LATEST RECORD WHOSE TO DATE IS NULL    
    
SELECT temp.* INTO #tempLink 
FROM #tempStaging stage  
INNER JOIN dbo.RefClientDatabaseEnum db ON stage.DatabaseType=db.DatabaseType    
INNER JOIN dbo.RefClient cli ON stage.ClientId=cli.ClientId AND db.RefClientDatabaseEnumId=cli.RefClientDatabaseEnumId AND (db.DatabaseType <>'NSDL' OR stage.DpId=cli.DpId )  
INNER JOIN #tempLinkIncomeGroupLatest temp ON temp.RefClientId=cli.RefClientid
WHERE temp.ToDate IS NULL OR temp.ToDate> stage.EffectiveFrom

--UPDATE LINK TABLE         
UPDATE link      
SET ToDate = DATEADD(DAY, -1, stage.EffectiveFrom)    
FROM    
#tempStaging stage    
LEFT JOIN #Rejection rej ON rej.StagingCoreClientIncomeCategorizationWithExactIncomeId = stage.StagingCoreClientIncomeCategorizationWithExactIncomeId    
INNER JOIN dbo.RefClientDatabaseEnum db ON stage.DatabaseType=db.DatabaseType    
INNER JOIN dbo.RefClient cli ON stage.ClientId=cli.ClientId AND db.RefClientDatabaseEnumId=cli.RefClientDatabaseEnumId AND (db.DatabaseType !='NSDL' OR stage.DpId=cli.DpId )    
INNER JOIN #tempLink tl ON tl.RefClientId = cli.RefClientId    
INNER JOIN dbo.LinkRefClientRefIncomeGroup link ON link.LinkRefClientRefIncomeGroupId = tl.LinkRefClientRefIncomeGroupId    
WHERE rej.StagingCoreClientIncomeCategorizationWithExactIncomeId IS NULL    
AND NOT EXISTS (SELECT 1 FROM dbo.LinkRefClientRefIncomeGroup WHERE RefClientId=cli.RefClientId AND FromDate=stage.EffectiveFrom)    
    
--------------------------------------------------------------------------------------------------------------------    
Select grp.RefIncomeGroupId, stage.ClientId,    
ROW_NUMBER() OVER (    
 PARTITION BY stage.ClientId    
 ORDER BY RefIncomeGroupId ASC     
 ) rownum    
into #stageIncomeGroup    
FROM #tempStaging stage    
LEFT JOIN dbo.RefIncomeGroup grp ON dbo.IsVarcharNotEqual(stage.IncomeRange, grp.[Name])=0  OR   
((CAST(stage.ExactIncome AS BIGINT)>=grp.IncomeFrom AND CAST(stage.ExactIncome AS BIGINT) <= grp.IncomeTo) OR (CAST(stage.ExactIncome AS BIGINT)>=grp.IncomeFrom AND grp.IncomeFrom =10000000));  
--where     
--( Isnumeric(stage.ExactIncome)=1 and stage.ExactIncome>=grp.IncomeFrom AND stage.ExactIncome <= grp.IncomeTo)    
--OR    
--(stage.IncomeRange=grp.[Name])    
    
    
    
INSERT INTO dbo.LinkRefClientRefIncomeGroup(    
RefClientId,    
RefIncomeGroupId,    
Income,    
Networth,    
FromDate,    
ToDate,    
AddedBy,    
AddedOn,    
LastEditedBy,    
EditedOn    
)    
SELECT cli.RefClientId,    
stageIncomeGrp.RefIncomeGroupId,    
CAST(stage.ExactIncome AS BIGINT),    
stage.Networth * 100000,    
stage.EffectiveFrom,    
stage.EffectiveTo,    
stage.AddedBy,    
GETDATE(),    
stage.AddedBy,    
GETDATE()    
FROM #tempStaging stage    
LEFT JOIN #Rejection Rej ON stage.StagingCoreClientIncomeCategorizationWithExactIncomeId=Rej.StagingCoreClientIncomeCategorizationWithExactIncomeId    
INNER JOIN dbo.RefClientDatabaseEnum db ON stage.DatabaseType=db.DatabaseType    
INNER JOIN dbo.RefClient cli ON stage.ClientId=cli.ClientId AND db.RefClientDatabaseEnumId=cli.RefClientDatabaseEnumId AND (db.DatabaseType !='NSDL' OR stage.DpId=cli.DpId )    
LEFT JOIN #stageIncomeGroup stageIncomeGrp on stageIncomeGrp.ClientId=cli.ClientId and stageIncomeGrp.rownum=1    
WHERE Rej.StagingCoreClientIncomeCategorizationWithExactIncomeId IS NULL    
AND NOT EXISTS (SELECT 1 FROM LinkRefClientRefIncomeGroup WHERE RefClientId=cli.RefClientId AND FromDate=stage.EffectiveFrom)    
    
    
SELECT rej.RejectionMessage AS ErrorMessage    
FROM #Rejection rej    
ORDER BY rej.StagingCoreClientIncomeCategorizationWithExactIncomeId    
    
DELETE FROM dbo.StagingCoreClientIncomeCategorizationWithExactIncome  WHERE [Guid]=@Guid    
    
END
GO
--RC-WEB-66329--END