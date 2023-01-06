---WEB-67715-RC START
GO
 ALTER PROCEDURE [dbo].[CoreAmlWatchList_GetWatchlistChangeAuditReportData_R561]      
(      
 @SourceIds  VARCHAR(MAX)=null,      
 @UniqueIds  VARCHAR(MAX)=null,      
 @FromDate DATETIME,      
 @ToDate DATETIME      
)      
AS      
BEGIN      
 DECLARE @InternalFromDate DATETIME,      
   @InternalToDate DATETIME,      
   @UniqueIdsInternal  VARCHAR(MAX),      
   @SourceIdsInternal  VARCHAR(MAX)      
SET @InternalFromDate = dbo.GetDateWithoutTime(@FromDate)      
 SET @InternalToDate = DATEDIFF(dd, 0,@ToDate) + CONVERT(DATETIME,'23:59:59.900')       
 SET @UniqueIdsInternal = @UniqueIds      
 SET @SourceIdsInternal = @SourceIds      
      
 CREATE TABLE #SourceIds      
 (      
  RefAmlWatchListSourceId INT PRIMARY KEY      
 )      
      
 INSERT INTO #SourceIds      
 (      
  RefAmlWatchListSourceId      
 )      
 SELECT DISTINCT      
   sor.RefAmlWatchListSourceId      
 FROM dbo.ParseString(@SourceIdsInternal,',') temp      
 INNER JOIN dbo.RefAmlWatchListSource sor ON sor.RefAmlWatchListSourceId= CONVERT(INT,temp.s)      
       
 SELECT DISTINCT      
   temp.s AS UniqueId      
 INTO #UniqueIds      
 FROM dbo.ParseString(@UniqueIdsInternal,',') temp      
      
 SELECT       
  main.Source,main.UniqueId,main.CoreAmlWatchListId,main.AddedOn,main.EditedOn      
 INTO #CoreAmlWatchListData      
 FROM dbo.CoreAmlWatchList main      
 WHERE       
 ( @SourceIdsInternal IS NULL AND @UniqueIdsInternal IS NULL)      
 OR      
 (      
 (@SourceIdsInternal IS NULL      
 OR      
 EXISTS(      
 SELECT 1 FROM #SourceIds temp WHERE temp.RefAmlWatchListSourceId = main.Source      
 ))      
 AND       
 (      
 @UniqueIdsInternal IS NULL      
 OR      
 EXISTS(      
 SELECT 1 FROM #UniqueIds temp WHERE temp.UniqueId = main.UniqueId      
 ))      
 )      
       
 SELECT temp.CoreAmlWatchListId , temp.Source,temp.UniqueId,sl.Name AS SourceName      
 INTO #UpdatedCoreAmlWatchListIds      
 FROM       
 (      
 SELECT main.CoreAmlWatchListId, main.Source,main.UniqueId      
 FROM #CoreAmlWatchListData main      
 WHERE EditedOn  >=  @InternalFromDate       
 AND EditedOn < @InternalToDate AND main.AddedOn <> main.EditedOn      
       
 UNION      
      
 SELECT main.CoreAmlWatchListId , temp.Source,temp.UniqueId      
 FROM dbo.CoreAmlWatchListAlias main      
 INNER JOIN #CoreAmlWatchListData temp ON main.CoreAmlWatchListId = temp.CoreAmlWatchListId      
 WHERE main.EditedOn  >=  @InternalFromDate       
 AND main.EditedOn < @InternalToDate AND main.EditedOn <> main.AddedOn      
      
 UNION      
      
 SELECT main.CoreAmlWatchListId , temp.Source,temp.UniqueId      
 FROM dbo.CoreAmlWatchListAddress main      
 INNER JOIN #CoreAmlWatchListData temp ON main.CoreAmlWatchListId = temp.CoreAmlWatchListId      
 WHERE main.EditedOn  >=  @InternalFromDate       
 AND main.EditedOn < @InternalToDate AND main.EditedOn <> main.AddedOn      
      
 UNION      
      
 SELECT main.CoreAmlWatchListId , temp.Source,temp.UniqueId      
 FROM dbo.CoreAmlWatchListDateOfBirth main      
 INNER JOIN #CoreAmlWatchListData temp ON main.CoreAmlWatchListId = temp.CoreAmlWatchListId      
 WHERE main.EditedOn  >=  @InternalFromDate       
 AND main.EditedOn < @InternalToDate AND main.EditedOn <> main.AddedOn      
      
 UNION      
      
 SELECT main.CoreAmlWatchListId , temp.Source,temp.UniqueId      
 FROM dbo.CoreAmlWatchListIdentification main      
 INNER JOIN #CoreAmlWatchListData temp ON main.CoreAmlWatchListId = temp.CoreAmlWatchListId      
 WHERE main.EditedOn  >=  @InternalFromDate       
 AND main.EditedOn < @InternalToDate AND main.EditedOn <> main.AddedOn      
      
 UNION      
      
 SELECT main.CoreAmlWatchListId , temp.Source,temp.UniqueId      
 FROM dbo.CoreAmlWatchlistCountry main      
 INNER JOIN #CoreAmlWatchListData temp ON main.CoreAmlWatchListId = temp.CoreAmlWatchListId      
 WHERE main.EditedOn  >=  @InternalFromDate       
 AND main.EditedOn < @InternalToDate AND main.EditedOn <> main.AddedOn      
      
 UNION      
      
 SELECT main.CoreAmlWatchListId , temp.Source,temp.UniqueId       FROM dbo.CoreAmlWatchListLink main      
 INNER JOIN #CoreAmlWatchListData temp ON main.CoreAmlWatchListId = temp.CoreAmlWatchListId      
 WHERE main.EditedOn  >=  @InternalFromDate       
 AND main.EditedOn < @InternalToDate AND main.EditedOn <> main.AddedOn      
      
 UNION      
      
 SELECT main.CoreAmlWatchListId , temp.Source,temp.UniqueId      
 FROM dbo.CoreAmlWatchListKeyword main      
 INNER JOIN #CoreAmlWatchListData temp ON main.CoreAmlWatchListId = temp.CoreAmlWatchListId      
 WHERE main.EditedOn  >=  @InternalFromDate       
 AND main.EditedOn < @InternalToDate AND main.EditedOn <> main.AddedOn      
 ) temp      
 INNER JOIN dbo.RefAmlWatchListSource sl ON sl.RefAmlWatchListSourceId=temp.Source      
      
      
 SELECT       
  aud.*,      
  temp.SourceName,      
  aud.CoreAmlWatchListId AS MainId      
 FROM dbo.CoreAmlWatchList_Audit aud      
 INNER JOIN #UpdatedCoreAmlWatchListIds temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId 
 WHERE aud.AuditDMLAction = 'Update'      
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate      
      
 SELECT       
  aud.*,      
  temp.SourceName,temp.UniqueId,      
  aud.CoreAmlWatchListAliasId AS MainId,      
  temp.Source      
 FROM dbo.CoreAmlWatchListAlias_Audit aud      
 INNER JOIN #UpdatedCoreAmlWatchListIds temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
        
 WHERE aud.AuditDMLAction = 'Update'     
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate      
      
 SELECT       
  aud.*,      
  temp.SourceName,temp.UniqueId,      
  aud.CoreAmlWatchListAddressId AS MainId,      
  temp.Source      
 FROM dbo.CoreAmlWatchListAddress_Audit aud      
 INNER JOIN #UpdatedCoreAmlWatchListIds temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
        
 WHERE aud.AuditDMLAction = 'Update'    
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate      
      
 SELECT       
  aud.*,      
  temp.SourceName,temp.UniqueId,      
  aud.CoreAmlWatchListDateOfBirthId AS MainId,      
  temp.Source      
 FROM dbo.CoreAmlWatchListDateOfBirth_Audit aud      
 INNER JOIN #UpdatedCoreAmlWatchListIds temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
        
 WHERE aud.AuditDMLAction = 'Update'     
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate      
      
 SELECT       
  temp.UniqueId,aud.*,aud.UniqueId AS IdentificationUID,      
  temp.SourceName,      
  aud.CoreAmlWatchListIdentificationId AS MainId,      
  temp.Source      
 FROM dbo.CoreAmlWatchListIdentification_Audit aud      
 INNER JOIN #UpdatedCoreAmlWatchListIds temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
        
 WHERE aud.AuditDMLAction = 'Update'     
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate      
      
 SELECT       
  aud.*,      
  temp.SourceName,temp.UniqueId,      
  aud.CoreAmlWatchlistCountryId AS MainId,      
  temp.Source      
 FROM dbo.CoreAmlWatchlistCountry_Audit aud      
 INNER JOIN #UpdatedCoreAmlWatchListIds temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
        
 WHERE aud.AuditDMLAction = 'Update'    
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate      
      
 SELECT      
  aud.*,      
  temp.SourceName,temp.UniqueId,      
  aud.CoreAmlWatchListLinkId AS MainId,      
  temp.Source      
 FROM dbo.CoreAmlWatchListLink_Audit aud      
 INNER JOIN #UpdatedCoreAmlWatchListIds temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
        
 WHERE aud.AuditDMLAction = 'Update'    
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate      
     

  SELECT         
  aud.*,        
  temp.SourceName,temp.UniqueId,        
  aud.CoreAmlWatchListKeywordId AS MainId,        
  temp.Source        
 FROM dbo.CoreAmlWatchListKeyword_Audit aud      
 INNER JOIN #UpdatedCoreAmlWatchListIds temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId        
 WHERE aud.AuditDMLAction = 'Update'       
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate          
      
 SELECT Distinct Source AS SourceId      
 FROM       
 #UpdatedCoreAmlWatchListIds

 SELECT       
  aud.*,      
  src.[Name] AS SourceName,temp.UniqueId,      
  aud.CoreAmlWatchListId AS MainId ,      
  temp.Source      
  FROM dbo.CoreAmlWatchList_Audit aud      
  INNER JOIN #CoreAmlWatchListData temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
  INNER JOIN dbo.RefAmlWatchListSource  src ON src.RefAmlWatchListSourceId=temp.[Source]       
 WHERE aud.AuditDMLAction = 'DELETE'     
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate    

 SELECT       
  aud.*,      
  src.[Name] AS SourceName,temp.UniqueId,      
  aud.CoreAmlWatchListAliasId AS MainId,      
  temp.Source      
 FROM dbo.CoreAmlWatchListAlias_Audit aud      
 INNER JOIN #CoreAmlWatchListData temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
  INNER JOIN dbo.RefAmlWatchListSource  src ON src.RefAmlWatchListSourceId=temp.[Source]       
 WHERE aud.AuditDMLAction = 'DELETE'     
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate      
      
 SELECT       
  aud.*,      
  src.[Name] AS SourceName,temp.UniqueId,      
  aud.CoreAmlWatchListAddressId AS MainId,      
  temp.Source      
 FROM dbo.CoreAmlWatchListAddress_Audit aud      
 INNER JOIN #CoreAmlWatchListData temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
 INNER JOIN dbo.RefAmlWatchListSource  src ON src.RefAmlWatchListSourceId=temp.[Source]       
 WHERE aud.AuditDMLAction = 'DELETE'    
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate      
      
 SELECT       
  aud.*,      
  temp.UniqueId,      
  aud.CoreAmlWatchListDateOfBirthId AS MainId,      
  src.[Name] AS SourceName,temp.Source      
 FROM dbo.CoreAmlWatchListDateOfBirth_Audit aud      
 INNER JOIN #CoreAmlWatchListData temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
  INNER JOIN dbo.RefAmlWatchListSource  src ON src.RefAmlWatchListSourceId=temp.[Source]       
 WHERE aud.AuditDMLAction = 'DELETE'     
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate      
      
  SELECT       
  temp.UniqueId,aud.*,aud.UniqueId AS IdentificationUID,      
  src.[Name] AS SourceName,     
  aud.CoreAmlWatchListIdentificationId AS MainId,      
  temp.Source      
 FROM dbo.CoreAmlWatchListIdentification_Audit aud      
 INNER JOIN #CoreAmlWatchListData temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
 INNER JOIN dbo.RefAmlWatchListSource  src ON src.RefAmlWatchListSourceId=temp.[Source]         
 WHERE aud.AuditDMLAction = 'DELETE'     
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate 

 SELECT       
  aud.*,      
  temp.UniqueId,      
  aud.CoreAmlWatchlistCountryId AS MainId,      
  temp.[Source] ,
  src.[Name] AS SourceName     
 FROM dbo.CoreAmlWatchlistCountry_Audit aud      
 INNER JOIN #CoreAmlWatchListData temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
 INNER JOIN dbo.RefAmlWatchListSource  src ON src.RefAmlWatchListSourceId=temp.[Source]         
 WHERE aud.AuditDMLAction = 'DELETE'    
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate      
      

 SELECT      
  aud.*,      
  temp.[Source],temp.UniqueId,      
  aud.CoreAmlWatchListLinkId AS MainId,
  src.[Name] AS SourceName     
 FROM dbo.CoreAmlWatchListLink_Audit aud      
INNER JOIN #CoreAmlWatchListData temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId      
INNER JOIN dbo.RefAmlWatchListSource  src ON src.RefAmlWatchListSourceId=temp.[Source]       
WHERE aud.AuditDMLAction = 'DELETE'    
AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate   
 
  SELECT     
  aud.*,    
  temp.[Source],temp.UniqueId,    
  aud.CoreAmlWatchListKeywordId AS MainId ,
  src.[Name] AS SourceName
 FROM dbo.CoreAmlWatchListKeyword_Audit aud    
 INNER JOIN #CoreAmlWatchListData temp ON aud.CoreAmlWatchListId = temp.CoreAmlWatchListId    
 INNER JOIN dbo.RefAmlWatchListSource  src ON src.RefAmlWatchListSourceId=temp.[Source]  
 WHERE aud.AuditDMLAction = 'DELETE'   
 AND aud.AuditDateTime BETWEEN @InternalFromDate AND @InternalToDate     
      
END      
GO
---WEB-67715-RC START
--exec CoreAmlWatchList_GetWatchlistChangeAuditReportData_R561 null,null,'02-11-2022','02-14-2022'

select *,RefAmlWatchListKeywordId from CoreAmlWatchListKeyword 