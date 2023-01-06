 ---start WEB-66603 RC
 GO
DECLARE @SourceId INT
SET @SourceId=(SELECT sou.RefAmlWatchListSourceId FROM dbo.RefAmlWatchlistsource sou  WHERE sou.Sourcecode=35)

UPDATE core
SET core.IdType='Passport',
core.Idvalue=CASE WHEN core.Notes NOT LIKE'% %' THEN core.Notes ELSE core.Idvalue END
FROM dbo.CoreAmlWatchListIdentification core
 INNER JOIN dbo.CoreAmlWatchList list ON list.CoreAmlWatchListId=core.CoreAmlWatchListId
 WHERE list.[Source]=@SourceId AND IdType IS NULL 
 
 GO
 ---end WEB-66603 RC

---start WEB-66603 RC
GO
ALTER PROCEDURE [dbo].[CoreWatchListUnitedKingdomSanctionList]  
(  
 @Guid VARCHAR(50)  
)  
AS  
BEGIN  
 DECLARE @SourceId INT,   
   @RefAddressTypeId INT,   
   @InternalGuid VARCHAR(50),  
   @Source VARCHAR(500),  
   @AddressType VARCHAR(500)  
 SET @InternalGuid= @Guid  
 SET @Source ='UnitedKingdomSanctionList'  
 SELECT @SourceId=RefAmlWatchListSourceId FROM dbo.RefAmlWatchListSource WHERE [Name]=@Source  
  
  SELECT  *   INTO #MainIndividualWatchlistData FROM   
 (  
  SELECT  
   ROW_NUMBER()over(PARTITION BY GroupID,AliasType,Name6 ORDER BY StagingUnitedKingdomSanctionListId DESC) AS roWNumber,  
   stage.*   
  FROM dbo.StagingUnitedKingdomSanctionList stage  
  WHERE  stage.GUID = @InternalGuid  
 )a  
 WHERE  a.roWNumber = 1  
  
 INSERT INTO dbo.StagingAmlWatchList  
 (  
  RefAmlWatchListSourceId,  
  [Name],  
  Title,  
  Position,  
  OrderDetails,  
  RecordType,  
  OtherInfo,  
  OrderDate,  
  UpdatedDate,  
  UniqueId,  
  WatchListSource,  
  AddedBy,  
  AddedOn,  
  IsActive,  
  [Guid]  
 )  
 SELECT   
   @SourceId,  
   RTRIM(LTRIM(ISNULL(stage.Name6,'')+' '+ISNULL(stage.Name1,'')+' '+ISNULL(stage.Name2,'')+' '+ISNULL(stage.Name3,'')+' '+ISNULL(stage.Name4,'')+' '+ISNULL(stage.Name5,''))),  
   stage.Title,  
   stage.Position,  
   stage.OtherInformation,  
   stage.GroupType,  
   stage.Regime,  
   stage.ListedOn,  
   stage.LastUpdate,  
   stage.GroupId,  
   @Source,  
   stage.AddedBy,  
   stage.AddedOn,  
   1,  
   @InternalGuid  
 FROM #MainIndividualWatchlistData stage  
 WHERE stage.GUID =@InternalGuid   
  
--- Insert into Stagingamlwatchlistalias  
  SELECT * INTO #WatchlistAliasData FROM   
   (  
     SELECT  
   ROW_NUMBER()over(PARTITION BY GroupID ,AliasType,Name6 ORDER BY StagingUnitedKingdomSanctionListId DESC) AS roWNumber,  
   RTRIM(LTRIM(ISNULL(Name6,'')+' '+ISNULL(Name1,'')+' '+ISNULL(Name2,'')+' '+ISNULL(Name3,'')+' '+ISNULL(Name4,'')+' '+ISNULL(Name5,''))) AS MainName,  
   stage.*   
  FROM dbo.StagingUnitedKingdomSanctionList stage  
  WHERE  stage.GUID = @InternalGuid  
      
  )t  
  WHERE t.roWNumber = 1  
  
  INSERT INTO dbo.StagingAmlWatchListAlias  
  (  
   UniqueId,  
   WatchListSource,  
   FirstName,  
   AliasType,  
   AddedBy,  
   AddedOn,  
   AliasId,  
   [Guid]  
  )  
  SELECT   
   stage.GroupId,  
   @Source,  
   stage.MainName,  
   stage.AliasType,  
   stage.AddedBy,  
   stage.AddedOn,  
   stage.GroupId,  
   @InternalGuid  
   FROM #WatchlistAliasData stage  
  
--- Insert BirthPlace Into StagingAmlWatchListAddress     
   SET @AddressType = 'PlaceOfBirth'  
   SELECT  @RefAddressTypeId=RefAddressTypeId  FROM dbo.RefAddressType WHERE [Name]= @AddressType  
  
  INSERT INTO dbo.StagingAmlWatchListAddress  
  (  
   UniqueId,  
   WatchListSource,  
   RefAddressTypeId,  
   AddressType,  
   City,  
   Country,  
   AddedBy,  
   AddedOn,  
   [Guid]  
  )  
  SELECT  
   stage.GroupId,  
   @Source,  
   @RefAddressTypeId,  
   @AddressType,  
   stage.TownOfBirth,  
   stage.CountryOfBirth,  
   stage.AddedBy,  
   stage.AddedOn,  
   @InternalGuid  
  FROM #MainIndividualWatchlistData stage  
  WHERE TownOfBirth IS NOT NULL   
   AND TownOfBirth <> ''   
   AND CountryOfBirth IS NOT NULL   
   AND CountryOfBirth <> ''  
   AND stage.GUID = @InternalGuid  
   
-- Insert Address Into StagingAmlWatchListAddress     
   SET @AddressType = 'Address'  
   SELECT @RefAddressTypeId=RefAddressTypeId  FROM dbo.RefAddressType WHERE [Name]= @AddressType  
  
  SELECT * INTO #UKSactionAddressList FROM  
   (  
   SELECT  
    ROW_NUMBER() OVER (PARTITION BY  Groupid,RTRIM(LTRIM(ISNULL(Address1,'')+' '+ISNULL(Address2,'')+' '+ISNULL(Address3,'')+' '+ISNULL(Address4,'')+' '+ISNULL(Address5,'')+' '+ISNULL(Address6,'')+' '+ISNULL(PostZipCode,''))) ORDER BY StagingUnitedKingdomSanctionListId DESC) AS RowIndex,  
    RTRIM(LTRIM(ISNULL(Address1,'')+' '+ISNULL(Address2,'')+' '+ISNULL(Address3,'')+' '+ISNULL(Address4,'')+' '+ISNULL(Address5,'')+' '+ISNULL(Address6,'')+' '+ISNULL(PostZipCode,''))) as FullAddress,  
    stage.*  
    FROM #MainIndividualWatchlistData stage   
    WHERE stage.GUID = @InternalGuid             
  )  
  test  
  WHERE test.RowIndex = 1 and test.FullAddress IS NOT NULL AND test.FullAddress <>''  
  
  INSERT INTO dbo.StagingAmlWatchListAddress  
  (  
   UniqueId,  
   WatchListSource,  
   RefAddressTypeId,  
   AddressType,  
   AddressLine1,  
   AddressLine2,  
   AddressLine3,  
   City,  
   [State],  
   PostalCode,  
   AddedBy,  
   AddedOn,  
   [Guid]  
  )  
  SELECT  
   stage.GroupId,  
   @Source,  
   @RefAddressTypeId,  
   @AddressType,  
   stage.Address1,  
   stage.Address2,  
   stage.Address3 + stage.Address4,  
   stage.Address5,  
   stage.Address6,  
   stage.PostZipCode,  
   stage.AddedBy,  
   stage.AddedOn,  
   @InternalGuid  
  FROM  #UKSactionAddressList stage  
  
--Insert details into StagingAmlWatchlistCountry  
  INSERT INTO dbo.StagingAmlWatchlistCountry   
  (  
   UniqueId,  
   WatchListSource,  
   Relation,  
   AddedBy,  
   AddedOn,  
   Country,  
   Nationality,  
   [Guid]  
  )  
  SELECT  
   stage.GroupId,  
   @Source,  
'Citizenship'   ,  
   stage.AddedBy,  
   stage.AddedOn,  
   stage.Country,  
   stage.Nationality,  
   @InternalGuid  
     FROM #MainIndividualWatchlistData stage  
  WHERE stage.Country IS NOT NULL OR stage.Nationality IS NOT NULL   
   
-- Insert into StagingAmlWatchListIdentification  
  
  SELECT * INTO #IdentificationDetails FROM   
  (  
   SELECT ROW_NUMBER() OVER (PARTITION BY  GroupId,RTRIM(LTRIM(ISNULL(PassportDetails,'')+' '+ISNULL(NINumber,''))) ORDER BY GroupId) AS RowIndex,  
   RTRIM(LTRIM(ISNULL(PassportDetails,'')+' '+ISNULL(NINumber,''))) AS PassPortandNINDetails,  
   stage.*  
   FROM #MainIndividualWatchlistData stage  
   WHERE stage.[GUID] = @InternalGuid  
  )  
  test  
  WHERE test.RowIndex = 1 and test.PassPortandNINDetails IS NOT NULL AND test.PassPortandNINDetails <>''  
  
  INSERT INTO dbo.StagingAmlWatchListIdentification  
  (  
   UniqueId,  
   WatchListSource,
   IdType,
   IdValue,
   Notes,  
   AddedBy,  
   AddedOn,  
   [Guid]  
  )  
  SELECT   
   stage.GroupId,  
   @Source,
   'Passport',
   CASE WHEN PassPortandNINDetails NOT LIKE'% %' THEN PassPortandNINDetails ELSE NULL END,
   PassPortandNINDetails,  
   stage.AddedBy,  
   stage.AddedOn,  
   @InternalGuid  
  FROM #IdentificationDetails stage  
  
--- Insert into StagingAmlWatchListDateOfBirth  
  INSERT INTO dbo.StagingAmlWatchListDateOfBirth  
  (  
   UniqueId,  
   WatchListSource,  
   DateType,  
   DateOfBirth,  
   AddedBy,  
   AddedOn,  
   [Day],  
   [Month],  
   [Year],  
   [Guid]  
  )  
  SELECT   
   stage.GroupId,  
   @Source,  
'Exact'   ,  
   CASE WHEN  LEFT(stage.DOB,2)<> '00' AND  SUBSTRING(stage.DOB,4,2)<> '00' AND SUBSTRING(stage.DOB,7,4)<> '0' AND LEN(stage.DOB)=10 THEN CONVERT(DATETIME,stage.DOB,103)   
   ELSE NULL END,  
   stage.AddedBy,  
   stage.AddedOn,  
   CASE WHEN  LEFT(stage.DOB,2)<> '00' THEN  LEFT(stage.DOB,2) ELSE NULL END,  
   CASE WHEN  SUBSTRING(stage.DOB,4,2)<> '00'  THEN  SUBSTRING(stage.DOB,4,2) ELSE NULL END,  
   CASE WHEN  SUBSTRING(stage.DOB,7,4)<> '0' OR SUBSTRING(stage.DOB,7,4)<> '00'  OR SUBSTRING(stage.DOB,7,4)<>'000'  OR SUBSTRING(stage.DOB,7,4)<>'0000'  THEN SUBSTRING(stage.DOB,7,4) ELSE NULL END,  
   @InternalGuid  
  FROM #MainIndividualWatchlistData stage  
  
  EXEC dbo.CoreAmlWatchlist_InsertDataFromStaging @Guid = @InternalGuid  
  EXEC dbo.CoreAmlWatchlist_DeleteDataFromStaging @Guid = @InternalGuid  
  DELETE FROM dbo.StagingUnitedKingdomSanctionList where [GUID]=@InternalGuid  
END  
GO
---end WEB-66603 RC
