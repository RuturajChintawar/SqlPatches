
--web-66995-RC start
GO
 ALTER PROCEDURE [dbo].[CoreAmlWatchlist_InsertDataFromStaging] (@Guid VARCHAR(100))  
AS  
BEGIN  
 DECLARE @InternalGuid VARCHAR(100);  
  
 SET @InternalGuid = @Guid;  
  
 DECLARE @datetime DATETIME  
  
 SET @datetime = getdate();  
  
 DECLARE @InternalAddedby VARCHAR(50);  
  
 SELECT TOP 1 @InternalAddedby = AddedBy  
 FROM dbo.StagingAmlWatchList  
 WHERE [Guid] = @InternalGuid  
  
 UPDATE stage  
 SET stage.RefAmlwatchlistSourceId = sources.RefAmlWatchListSourceId  
 FROM dbo.StagingAmlWatchList stage  
 INNER JOIN dbo.RefAmlWatchListSource sources ON stage.WatchListSource = sources.[Name] OR stage.WatchListSource = sources.SourceCode  
 WHERE stage.[Guid] = @InternalGuid  
  AND stage.RefAmlwatchlistSourceId IS NULL  
  
 SELECT DISTINCT stag.Category,  
  stag.RefAmlWatchListSourceId  
 INTO #tempCategory  
 FROM dbo.StagingAmlWatchList stag  
 WHERE stag.[Guid] = @InternalGuid  
  AND dbo.IsVarcharNotEqual(stag.Category, '') = 1  
  
 INSERT INTO dbo.RefAmlWatchListCategory (  
  [Name],  
  AddedBy,  
  AddedOn,  
  LastEditedBy,  
  EditedOn,  
  RefAmlWatchListSourceId  
  )  
 SELECT tempCat.Category,  
  @InternalAddedby,  
  @datetime,  
  @InternalAddedby,  
  @datetime,  
  tempCat.RefAmlWatchListSourceId  
 FROM #tempCategory tempCat  
 WHERE tempCat.Category IS NOT NULL  
  AND NOT EXISTS (  
   SELECT 1  
   FROM dbo.RefAmlWatchListCategory cat  
   WHERE cat.RefAmlWatchListSourceId = tempCat.RefAmlWatchListSourceId  
    AND cat.[Name] = tempCat.Category  
   )  
  
 SELECT DISTINCT cat.RefAmlWatchListCategoryId,  
  stag.SubCategory  
 INTO #tempSubCategory  
 FROM dbo.StagingAmlWatchList stag  
 INNER JOIN dbo.RefAmlWatchListCategory cat ON cat.[Name] = stag.Category  
 WHERE stag.[Guid] = @InternalGuid  
  AND dbo.IsVarcharNotEqual(stag.SubCategory, '') = 1  
  
 INSERT INTO dbo.RefAmlWatchListSubCategory (  
  [Name],  
  AddedBy,  
  AddedOn,  
  LastEditedBy,  
  EditedOn,  
  RefAmlWatchListCategoryId  
  )  
 SELECT tempSubCat.SubCategory,  
  @InternalAddedby,  
  @datetime,  
  @InternalAddedby,  
  @datetime,  
  tempSubCat.RefAmlWatchListCategoryId  
 FROM #tempSubCategory tempSubCat  
 WHERE tempSubCat.RefAmlWatchListCategoryId IS NOT NULL  
  AND tempSubCat.SubCategory IS NOT NULL  
  AND NOT EXISTS (  
   SELECT 1  
   FROM dbo.RefAmlWatchListSubCategory subcat  
   WHERE subcat.[Name] = tempSubCat.SubCategory  
    AND subcat.RefAmlWatchListCategoryId = tempSubCat.RefAmlWatchListCategoryId  
   )  
  
 SELECT *  
 INTO #WatchlistRownumberData  
 FROM (  
  SELECT StagingAmlWatchListId,  
   RefAmlwatchlistSourceId,  
   UniqueId,  
   ROW_NUMBER() OVER (  
    PARTITION BY RefAmlwatchlistSourceId,  
    UniqueId ORDER BY ISNULL(UpdatedDate, '1-Jan-9999') DESC  
    ) AS RowIndex  
  FROM dbo.StagingAmlWatchList  
  WHERE [Guid] = @InternalGuid  
  ) t  
 WHERE t.RowIndex = 1  
  
 SELECT watch.RefAmlWatchListSourceId,  
  watch.OrderDate,  
  watch.OrderDetails,  
  watch.[Name],  
  watch.PAN,  
  watch.[Address],  
  watch.[Period],  
  watch.CircularNo,  
  watch.CircularLink,  
  watch.CircularDate,  
  watch.Notes,  
  watch.AddedBy,  
  watch.AddedOn,  
  watch.ListType,  
  watch.OtherInfo,  
  watch.UniqueId,  
  watch.IsActive,  
  watch.Title,  
  watch.Position,  
  watch.Companies,  
  watch.RecordType,  
  watch.Editor,  
  cat.RefAmlWatchListCategoryId AS RefAmlWatchListCategoryId,  
  subcat.RefAmlWatchListSubCategoryId AS RefAmlWatchListSubCategoryId,  
  watch.UpdatedDate,  
  watch.InactiveDate,  
  watch.TypeIdEnumValueId,  
  watch.DIN,  
  watch.CIN,  
  watch.Aadhaar,  
  watch.Mobile,  
  watch.Email,  
  watch.ISIN,  
  watch.LinkedTo,  
  watch.DowJonesAction,  
  watch.Gender,  
  watch.DowJonesActiveStatus,  
  watch.DowJonesDeceased,  
  watch.EntityIdVersion,  
  watch.EntitySource,  
  watch.EntityOriginalSource,  
  watch.Bank,  
  watch.Branch,  
  watch.OutStandingAmountInLacs,  
  watch.LinkedOrders,  
  watch.[State],  
  watch.NameLastModifiedOn,  
  watch.TWWatchlistEntityId,  
  watch.UpdateCategory,  
  watch.CoreAmlWatchlistId,  
  watch.WatchListSource,  
  watch.GenderRefEnumValueId  
 INTO #finalWatchlistData  
 FROM dbo.StagingAmlWatchList watch  
 INNER JOIN #WatchlistRownumberData wrow ON wrow.StagingAmlWatchListId = watch.StagingAmlWatchListId  
 LEFT JOIN dbo.RefAmlWatchListCategory cat ON cat.[Name] = watch.Category  
  AND cat.RefAmlWatchListSourceId = watch.RefAmlWatchListSourceId  
 LEFT JOIN dbo.RefAmlWatchListSubCategory subcat ON subcat.RefAmlWatchListCategoryId = cat.RefAmlWatchListCategoryId  
  AND subcat.[Name] = watch.SubCategory  
 WHERE watch.[Guid] = @InternalGuid  
  
 --update CoreAmlWatchlist      
 SELECT stag.UniqueId,  
  stag.RefAmlWatchListSourceId,  
  stag.RefAmlWatchListCategoryId,  
  stag.RefAmlWatchListSubCategoryId,  
  stag.UpdatedDate,  
  stag.Editor,  
  stag.OrderDate,  
  stag.CircularDate,  
  stag.UpdateCategory,  
  stag.RecordType,  
  stag.TypeIdEnumValueId,  
  stag.Title,  
  stag.Position,  
  stag.[Name],  
  stag.OrderDetails,  
  stag.LinkedOrders,  
  stag.LinkedTo,  
  stag.CircularNo,  
  stag.CircularLink,  
  stag.Companies,  
  stag.OtherInfo,  
  stag.PAN,  
  stag.DIN,  
  stag.CIN,  
  stag.AddedBy AS LastEditedBy,  
  stag.AddedOn AS EditedOn,  
  stag.IsActive,  
  main.CoreAmlWatchListId,  
  stag.InactiveDate,  
  stag.Aadhaar,  
  stag.Mobile,  
  stag.Email,  
  stag.ISIN,  
  stag.[Period],
  stag.[Address]
 INTO #watchlistUpdatedData  
 FROM #finalWatchlistData stag  
 INNER JOIN dbo.CoreAmlWatchList main ON main.Source = stag.RefAmlWatchListSourceId  
  AND main.UniqueId = stag.UniqueId  
 WHERE ISNULL(main.UpdatedDate, '1-Jan-9999') <= ISNULL(stag.UpdatedDate, '1-Jan-9999')  
  AND (  
   dbo.IsVarcharNotEqual(main.Editor, stag.Editor) = 1  
   OR dbo.IsVarcharNotEqual(main.OrderDate, stag.OrderDate) = 1  
   OR dbo.IsVarcharNotEqual(main.CircularDate, stag.CircularDate) = 1  
   OR dbo.IsDateTimeNotEqual(main.UpdatedDate, stag.UpdatedDate) = 1  
   OR dbo.IsVarcharNotEqual(main.RecordType, stag.RecordType) = 1  
   OR dbo.IsVarcharNotEqual(main.TypeIdEnumValueId, stag.TypeIdEnumValueId) = 1  
   OR dbo.IsVarcharNotEqual(main.Title, stag.Title) = 1  
   OR dbo.IsVarcharNotEqual(main.Position, stag.Position) = 1  
   OR dbo.IsVarcharNotEqual(main.[Name], stag.[Name]) = 1  
   OR dbo.IsVarcharNotEqual(main.OrderDetails, stag.OrderDetails) = 1  
   OR dbo.IsVarcharNotEqual(main.Companies, stag.Companies) = 1  
   OR dbo.IsVarcharNotEqual(main.OtherInfo, stag.OtherInfo) = 1  
   OR dbo.IsVarcharNotEqual(main.PAN, stag.PAN) = 1  
   OR dbo.IsVarcharNotEqual(main.DIN, stag.DIN) = 1  
   OR dbo.IsVarcharNotEqual(main.CIN, stag.CIN) = 1  
   OR dbo.IsBigIntNotEqual(main.RefAmlWatchListCategoryId, stag.RefAmlWatchListCategoryId) = 1  
   OR dbo.IsBigIntNotEqual(main.RefAmlWatchListSubCategoryId, stag.RefAmlWatchListSubCategoryId) = 1  
   OR dbo.IsVarcharNotEqual(main.UpdateCategory, stag.UpdateCategory) = 1  
   OR dbo.IsBitNotEqual(main.IsActive, stag.IsActive) = 1  
   OR dbo.IsVarcharNotEqual(main.LinkedOrders, stag.LinkedOrders) = 1  
   OR dbo.IsVarcharNotEqual(main.LinkedTo, stag.LinkedTo) = 1  
   OR dbo.IsVarcharNotEqual(main.CircularLink, stag.CircularLink) = 1  
   OR dbo.IsVarcharNotEqual(main.CircularNo, stag.CircularNo) = 1  
   OR dbo.IsDateTimeNotEqual(main.InactiveDate, stag.InactiveDate) = 1  
   OR dbo.IsVarcharNotEqual(main.Aadhaar, stag.Aadhaar) = 1  
   OR dbo.IsVarcharNotEqual(main.Mobile, stag.Mobile) = 1  
   OR dbo.IsVarcharNotEqual(main.Email, stag.Email) = 1  
   OR dbo.IsVarcharNotEqual(main.ISIN, stag.ISIN) = 1  
   OR dbo.IsVarcharNotEqual(main.[Period], stag.[Period]) = 1  
   OR dbo.IsVarcharNotEqual(main.[Address], stag.[Address]) = 1
   )  
  
 UPDATE main  
 SET main.RefAmlWatchListCategoryId = stag.RefAmlWatchListCategoryId,  
  main.RefAmlWatchListSubCategoryId = stag.RefAmlWatchListSubCategoryId,  
  main.UpdatedDate = stag.UpdatedDate,  
  main.Editor = stag.Editor,  
  main.OrderDate = stag.OrderDate,  
  main.CircularNo = stag.circularno,  
  main.CircularLink = stag.CircularLink,  
  main.CircularDate = stag.CircularDate,  
  main.UpdateCategory = stag.UpdateCategory,  
  main.RecordType = stag.RecordType,  
  main.TypeIdEnumValueId = stag.TypeIdEnumValueId,  
  main.Title = stag.Title,  
  main.Position = stag.Position,  
  main.[Name] = stag.[Name],  
  main.OrderDetails = stag.OrderDetails,  
  main.Companies = SUBSTRING(stag.Companies, 0, 7500),  
  main.OtherInfo = SUBSTRING(stag.OtherInfo, 0, 7500),  
  main.LinkedOrders = stag.LinkedOrders,  
  main.PAN = stag.PAN,  
  main.DIN = stag.DIN,  
  main.CIN = stag.CIN,  
  main.LastEditedBy = stag.LastEditedBy,  
  main.EditedOn = stag.EditedOn,  
  main.IsActive = stag.IsActive,  
  main.InactiveDate = stag.InactiveDate,  
  main.Aadhaar = stag.Aadhaar,  
  main.Mobile = stag.Mobile,  
  main.Email = stag.Email,  
  main.ISIN = stag.ISIN,  
  main.[Period] = stag.[Period],  
  main.LinkedTo = stag.LinkedTo, 
  main.[Address] = stag.[Address]
 FROM dbo.CoreAmlWatchList main  
 INNER JOIN #watchlistUpdatedData stag ON main.Source = stag.RefAmlWatchListSourceId  
  AND main.UniqueId = stag.UniqueId  
  
 CREATE TABLE #NewlyInsertedWatchlistData (CoreAmlWatchListId BIGINT PRIMARY KEY NOT NULL)  
  
 --insert into coreamlwatchlist      
 INSERT INTO dbo.CoreAmlWatchList (  
  Source,  
  OrderDate,  
  OrderDetails,  
  [Name],  
  PAN,  
  [Address],  
  [Period],  
  CircularNo,  
  CircularDate,  
  Notes,  
  AddedBy,  
  AddedOn,  
  LastEditedBy,  
  EditedOn,  
  ListType,  
  OtherInfo,  
  UniqueId,  
  IsActive,  
  Title,  
  Position,  
  Companies,  
  RecordType,  
  Editor,  
  RefAmlWatchListCategoryId,  
  RefAmlWatchListSubCategoryId,  
  UpdatedDate,  
  InactiveDate,  
  TypeIdEnumValueId,  
  DIN,  
  CIN,  
  Aadhaar,  
  Mobile,  
  Email,  
  ISIN,  
  LinkedTo,  
  DowJonesAction,  
  Gender,  
  DowJonesActiveStatus,  
  DowJonesDeceased,  
  EntityIdVersion,  
  EntitySource,  
  EntityOriginalSource,  
  Bank,  
  Branch,  
  OutStandingAmountInLacs,  
  LinkedOrders,  
  [State],  
  NameLastModifiedOn,  
  TWWatchlistEntityId,  
  UpdateCategory,  
  GenderRefEnumValueId,  
  CircularLink  
  )  
 OUTPUT INSERTED.CoreAmlWatchListId  
 INTO #NewlyInsertedWatchlistData(CoreAmlWatchListId)  
 SELECT watch.RefAmlWatchListSourceId,  
  watch.OrderDate,  
  watch.OrderDetails,  
  watch.[Name],  
  watch.PAN,  
  watch.[Address],  
  watch.[Period],  
  watch.CircularNo,  
  watch.CircularDate,  
  watch.Notes,  
  watch.AddedBy,  
  watch.AddedOn,  
  watch.AddedBy,  
  watch.AddedOn,  
  watch.ListType,  
  SUBSTRING(watch.OtherInfo, 0, 7500),  
  watch.UniqueId,  
  watch.IsActive,  
  watch.Title,  
  watch.Position,  
  SUBSTRING(watch.Companies, 0, 7500),  
  watch.RecordType,  
  watch.Editor,  
  watch.RefAmlWatchListCategoryId,  
  watch.RefAmlWatchListSubCategoryId,  
  watch.UpdatedDate,  
  watch.InactiveDate,  
  watch.TypeIdEnumValueId,  
  watch.DIN,  
  watch.CIN,  
  watch.Aadhaar,  
  watch.Mobile,  
  watch.Email,  
  watch.ISIN,  
  watch.LinkedTo,  
  watch.DowJonesAction,  
  watch.Gender,  
  watch.DowJonesActiveStatus,  
  watch.DowJonesDeceased,  
  watch.EntityIdVersion,  
  watch.EntitySource,  
  watch.EntityOriginalSource,  
  watch.Bank,  
  watch.Branch,  
  watch.OutStandingAmountInLacs,  
  watch.LinkedOrders,  
  watch.[State],  
  watch.NameLastModifiedOn,  
  watch.TWWatchlistEntityId,  
  watch.UpdateCategory,  
  watch.GenderRefEnumValueId,  
  watch.CircularLink  
 FROM #finalWatchlistData watch  
 WHERE NOT EXISTS (  
   SELECT 1  
   FROM dbo.CoreAmlWatchlist watchdata  
   WHERE watch.UniqueId = watchdata.UniqueId  
    AND watchdata.Source = watch.RefAmlWatchListSourceId  
   )  
  
 UPDATE stag  
 SET stag.CoreAmlWatchlistId = main.CoreAmlWatchListId  
 FROM #finalWatchlistData stag  
 INNER JOIN dbo.CoreAmlWatchList main ON main.UniqueId = stag.UniqueId  
  AND main.Source = stag.RefAmlwatchlistSourceId  
  
 UPDATE alias  
 SET alias.CoreAmlWatchlistId = stag.CoreAmlWatchlistId  
 FROM dbo.StagingAmlWatchlistAlias alias  
 INNER JOIN #finalWatchlistData stag ON stag.UniqueId = alias.UniqueId  
  AND stag.WatchListSource = alias.WatchListSource  
 WHERE alias.[Guid] = @InternalGuid  
  AND stag.CoreAmlWatchlistId IS NOT NULL  
  
 SELECT *  
 INTO #AliasFinalData  
 FROM (  
  SELECT *,  
   ROW_NUMBER() OVER (  
    PARTITION BY CoreAmlWatchListId,  
    FirstName,  
    LastName,  
    AliasId,  
    AliasType,  
    EntityName,  
    TitleHonorific,  
    MiddleName,  
    MaidenName,  
    Suffix,  
    SingleStringName,  
    OriginalScriptName,  
    LatinCharName,  
    Code ORDER BY StagingAmlWatchListAliasId DESC  
    ) AS RowIndex  
  FROM dbo.StagingAmlWatchlistAlias  
  WHERE [Guid] = @InternalGuid  
  ) n  
 WHERE n.RowIndex = 1  
  
 SELECT TEMP.CoreAmlWatchListId,  
  TEMP.FirstName,  
  TEMP.LastName,  
  TEMP.AliasType,  
  TEMP.AliasId,  
  TEMP.EntityName,  
  TEMP.TitleHonorific,  
  TEMP.MiddleName,  
  TEMP.MaidenName,  
  TEMP.Suffix,  
  TEMP.SingleStringName,  
  TEMP.OriginalScriptName,  
  TEMP.LatinCharName,  
  TEMP.Code,  
  TEMP.Strength,  
  TEMP.Notes,  
  TEMP.RefEnumValueDowJonesPersonNameTypeId,  
  TEMP.RefEnumValueDowJonesEntityNameTypeId,  
  TEMP.InternalNameStrength,  
  TEMP.Gender,  
  TEMP.LegalBasis,  
  TEMP.Link,  
  TEMP.Programme,  
  TEMP.ReglissReferenceOfTheAlias,  
  TEMP.OrderDate,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  main.CoreAmlWatchlistAliasId  
 INTO #UpdateAliasData  
 FROM #AliasFinalData TEMP  
 INNER JOIN dbo.CoreAmlWatchlistAlias main ON main.CoreAmlWatchListId = TEMP.CoreAmlWatchListId  
  AND main.FirstName = TEMP.FirstName  
  AND main.LastName = TEMP.LastName  
  AND main.AliasType = TEMP.AliasType  
  AND main.AliasId = TEMP.AliasId  
  AND main.EntityName = TEMP.EntityName  
  AND main.TitleHonorific = TEMP.TitleHonorific  
  AND main.MiddleName = TEMP.MiddleName  
  AND main.MaidenName = TEMP.MaidenName  
  AND main.Suffix = TEMP.Suffix  
  AND main.SingleStringName = TEMP.SingleStringName  
  AND main.OriginalScriptName = TEMP.OriginalScriptName  
  AND main.LatinCharName = TEMP.LatinCharName  
  AND main.Code = TEMP.Code  
  AND main.ReglissReferenceOfTheAlias = TEMP.ReglissReferenceOfTheAlias  
 WHERE dbo.IsVarcharNotEqual(main.Strength, TEMP.Strength) = 1  
  OR dbo.IsVarcharNotEqual(main.Notes, TEMP.Notes) = 1  
  OR dbo.IsBigIntNotEqual(main.RefEnumValueDowJonesPersonNameTypeId, TEMP.RefEnumValueDowJonesPersonNameTypeId) = 1  
  OR dbo.IsBigIntNotEqual(main.RefEnumValueDowJonesEntityNameTypeId, TEMP.RefEnumValueDowJonesEntityNameTypeId) = 1  
  OR dbo.IsVarcharNotEqual(main.InternalNameStrength, TEMP.InternalNameStrength) = 1  
  OR dbo.IsVarcharNotEqual(main.Gender, TEMP.Gender) = 1  
  OR dbo.IsVarcharNotEqual(main.LegalBasis, TEMP.LegalBasis) = 1  
  OR dbo.IsVarcharNotEqual(main.Link, TEMP.Link) = 1  
  OR dbo.IsVarcharNotEqual(main.Programme, TEMP.Programme) = 1  
  OR dbo.IsDateTimeNotEqual(main.OrderDate, TEMP.OrderDate) = 1  
  
 --Update core-alias      
 UPDATE main  
 SET main.Strength = TEMP.Strength,  
  main.Notes = TEMP.Notes,  
  main.RefEnumValueDowJonesPersonNameTypeId = TEMP.RefEnumValueDowJonesPersonNameTypeId,  
  main.RefEnumValueDowJonesEntityNameTypeId = TEMP.RefEnumValueDowJonesEntityNameTypeId,  
  main.InternalNameStrength = TEMP.InternalNameStrength,  
  main.Gender = TEMP.Gender,  
  main.LegalBasis = TEMP.LegalBasis,  
  main.Link = TEMP.Link,  
  main.Programme = TEMP.Programme,  
  main.ReglissReferenceOfTheAlias = TEMP.ReglissReferenceOfTheAlias,  
  main.OrderDate = TEMP.OrderDate,  
  main.LastEditedBy = TEMP.AddedBy,  
  main.EditedOn = TEMP.AddedOn  
 FROM dbo.CoreAmlWatchlistAlias main  
 INNER JOIN #UpdateAliasData TEMP ON main.CoreAmlWatchListAliasId = TEMP.CoreAmlWatchListAliasId  
  
 INSERT INTO dbo.CoreAmlWatchlistAlias (  
  CoreAmlWatchListId,  
  FirstName,  
  LastName,  
  AliasId,  
  AliasType,  
  Strength,  
  Notes,  
  AddedBy,  
  AddedOn,  
  LastEditedBy,  
  EditedOn,  
  TitleHonorific,  
  MiddleName,  
  MaidenName,  
  Suffix,  
  EntityName,  
  SingleStringName,  
  OriginalScriptName,  
  RefEnumValueDowJonesPersonNameTypeId,  
  RefEnumValueDowJonesEntityNameTypeId,  
  LatinCharName,  
  InternalNameStrength,  
  Gender,  
  Code,  
  LegalBasis,  
  Link,  
  Programme,  
  OrderDate,  
  ReglissReferenceOfTheAlias  
  )  
 SELECT TEMP.CoreAmlWatchListId,  
  TEMP.FirstName,  
  TEMP.LastName,  
  TEMP.AliasId,  
  TEMP.AliasType,  
  TEMP.Strength,  
  TEMP.Notes,  
  TEMP.AddedBy,    TEMP.AddedOn,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.TitleHonorific,  
  TEMP.MiddleName,  
  TEMP.MaidenName,  
  TEMP.Suffix,  
  TEMP.EntityName,  
  TEMP.SingleStringName,  
  TEMP.OriginalScriptName,  
  TEMP.RefEnumValueDowJonesPersonNameTypeId,  
  TEMP.RefEnumValueDowJonesEntityNameTypeId,  
  TEMP.LatinCharName,  
  TEMP.InternalNameStrength,  
  TEMP.Gender,  
  TEMP.Code,  
  TEMP.LegalBasis,  
  TEMP.Link,  
  TEMP.Programme,  
  TEMP.OrderDate,  
  TEMP.ReglissReferenceOfTheAlias  
 FROM #AliasFinalData TEMP  
 WHERE NOT EXISTS (  
   SELECT 1  
   FROM dbo.CoreAmlWatchListAlias main  
   WHERE main.CoreAmlWatchListId = TEMP.CoreAmlWatchListId  
    AND dbo.IsVarcharNotEqual(main.FirstName, TEMP.FirstName) = 0  
    AND dbo.IsVarcharNotEqual(main.LastName, TEMP.LastName) = 0  
    AND dbo.IsVarcharNotEqual(main.AliasType, TEMP.AliasType) = 0  
    AND dbo.IsBigIntNotEqual(main.AliasId, TEMP.AliasId) = 0  
    AND dbo.IsVarcharNotEqual(main.EntityName, TEMP.EntityName) = 0  
    AND dbo.IsVarcharNotEqual(main.TitleHonorific, TEMP.TitleHonorific) = 0  
    AND dbo.IsVarcharNotEqual(main.MiddleName, TEMP.MiddleName) = 0  
    AND dbo.IsVarcharNotEqual(main.MaidenName, TEMP.MaidenName) = 0  
    AND dbo.IsVarcharNotEqual(main.Suffix, TEMP.Suffix) = 0  
    AND dbo.IsVarcharNotEqual(main.SingleStringName, TEMP.SingleStringName) = 0  
    AND dbo.IsVarcharNotEqual(main.OriginalScriptName, TEMP.OriginalScriptName) = 0  
    AND dbo.IsVarcharNotEqual(main.LatinCharName, TEMP.LatinCharName) = 0  
    AND dbo.IsVarcharNotEqual(main.Code, TEMP.Code) = 0  
    AND dbo.IsVarcharNotEqual(main.ReglissReferenceOfTheAlias, TEMP.ReglissReferenceOfTheAlias) = 0  
   )  
  
 UPDATE addr  
 SET addr.CoreAmlWatchlistId = stag.CoreAmlWatchlistId  
 FROM dbo.StagingAmlWatchListAddress addr  
 INNER JOIN #finalWatchlistData stag ON stag.UniqueId = addr.UniqueId  
  AND stag.WatchListSource = addr.WatchListSource  
 WHERE addr.[Guid] = @InternalGuid  
  AND stag.CoreAmlWatchlistId IS NOT NULL  
  
 SELECT *  
 INTO #AddressFinalData  
 FROM (  
  SELECT *,  
   ROW_NUMBER() OVER (  
    PARTITION BY CoreAmlWatchListId,  
    AddressType,  
    AddressId,  
    Country,  
    RefCountryId,  
    City,  
    [State],  
    AddressLine1,  
    AddressLine2,  
    AddressLine3,  
    PostalCode,  
    Province,  
    Code ORDER BY StagingAmlWatchListAddressId DESC  
    ) AS RowIndex  
  FROM dbo.StagingAmlWatchListAddress stag  
  WHERE [Guid] = @InternalGuid  
  ) n  
 WHERE n.RowIndex = 1  
  
 UPDATE TEMP  
 SET TEMP.RefAddressTypeId = ref.RefAddressTypeId  
 FROM #AddressFinalData TEMP  
 INNER JOIN RefAddressType ref ON TEMP.AddressType = ref.[Name]  
  
 SELECT TEMP.StagingAmlWatchListAddressId,  
  TEMP.CoreAmlWatchListId,  
  TEMP.RefAddressTypeId,  
  TEMP.AddressType,  
  TEMP.AddressId,  
  TEMP.IsMainEntry,  
  TEMP.AddressLine1,  
  TEMP.AddressLine2,  
  TEMP.AddressLine3,  
  TEMP.City,  
  TEMP.[State],  
  TEMP.PostalCode,  
  TEMP.Country,  
  TEMP.Notes,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.StateAbbreviation,  
  TEMP.Province,  
  TEMP.RefCountryId,  
  TEMP.Code,  
  TEMP.LegalBasis,  
  TEMP.Link,  
  TEMP.Programme,  
  TEMP.OrderDate,  
  main.CoreAmlWatchListAddressId  
 INTO #updateAddressData  
 FROM #AddressFinalData TEMP  
 INNER JOIN dbo.CoreAmlWatchListAddress main ON main.CoreAmlWatchListId = TEMP.CoreAmlWatchListId  
  AND main.RefAddressTypeId = TEMP.RefAddressTypeId  
  AND main.Country = TEMP.Country  
  AND main.City = TEMP.City  
  AND main.[State] = TEMP.[State]  
  AND main.AddressLine1 = TEMP.AddressLine1  
  AND main.AddressLine2 = TEMP.AddressLine2  
  AND main.AddressLine3 = TEMP.AddressLine3  
  AND main.PostalCode = TEMP.PostalCode  
  AND main.Province = TEMP.Province  
  AND main.AddressId = TEMP.AddressId  
  AND main.Code = TEMP.Code  
 WHERE dbo.IsBitNotEqual(TEMP.IsMainEntry, main.IsMainEntry) = 1  
  OR dbo.IsVarcharNotEqual(TEMP.StateAbbreviation, main.StateAbbreviation) = 1  
  OR dbo.IsVarcharNotEqual(TEMP.LegalBasis, main.LegalBasis) = 1  
  OR dbo.IsVarcharNotEqual(TEMP.Link, main.Link) = 1  
  OR dbo.IsVarcharNotEqual(TEMP.Programme, main.Programme) = 1  
  OR dbo.IsDateTimeNotEqual(TEMP.OrderDate, main.OrderDate) = 1  
  
 --update CoreAmlWatchListAddress:      
 UPDATE addr  
 SET addr.IsMainEntry = TEMP.IsMainEntry,  
  addr.StateAbbreviation = TEMP.StateAbbreviation,  
  addr.LegalBasis = TEMP.LegalBasis,  
  addr.Link = TEMP.Link,  
  addr.Programme = TEMP.Programme,  
  addr.OrderDate = TEMP.OrderDate,  
  addr.EditedOn = TEMP.AddedOn,  
  addr.LastEditedBy = TEMP.AddedBy  
 FROM dbo.CoreAmlWatchListAddress addr  
 INNER JOIN dbo.#updateAddressData TEMP ON addr.CoreAmlWatchListAddressId = TEMP.CoreAmlWatchListAddressId  
  
 INSERT INTO dbo.CoreAmlWatchListAddress (  
  CoreAmlWatchListId,  
  RefAddressTypeId,  
  AddressId,  
  IsMainEntry,  
  AddressLine1,  
  AddressLine2,  
  AddressLine3,  
  City,  
  [State],  
  PostalCode,  
  Country,  
  Notes,  
  AddedBy,  
  AddedOn,  
  LastEditedBy,  
  EditedOn,  
  StateAbbreviation,  
  Province,  
  RefCountryId,  
  Code,  
  LegalBasis,  
  Link,  
  Programme,  
  OrderDate  
  )  
 SELECT TEMP.CoreAmlWatchListId,  
  TEMP.RefAddressTypeId,  
  TEMP.AddressId,  
  TEMP.IsMainEntry,  
  TEMP.AddressLine1,  
  TEMP.AddressLine2,  
  TEMP.AddressLine3,  
  TEMP.City,  
  TEMP.[State],  
  TEMP.PostalCode,  
  TEMP.Country,  
  TEMP.Notes,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.StateAbbreviation,  
  TEMP.Province,  
  TEMP.RefCountryId,  
  TEMP.Code,  
  TEMP.LegalBasis,  
  TEMP.Link,  
  TEMP.Programme,  
  TEMP.OrderDate  
 FROM #AddressFinalData TEMP  
 WHERE NOT EXISTS (  
   SELECT 1  
   FROM dbo.CoreAmlWatchListAddress main  
   WHERE main.CoreAmlWatchListId = TEMP.CoreAmlWatchListId  
    AND main.RefAddressTypeId = TEMP.RefAddressTypeId  
    AND dbo.IsVarcharNotEqual(main.Country, TEMP.Country) = 0  
    AND dbo.IsVarcharNotEqual(main.City, TEMP.City) = 0  
    AND dbo.IsNVarcharNotEqual(main.[State], TEMP.[State]) = 0  
    AND dbo.IsVarcharNotEqual(main.AddressLine1, TEMP.AddressLine1) = 0  
    AND dbo.IsNVarcharNotEqual(main.AddressLine2, TEMP.AddressLine2) = 0  
    AND dbo.IsNVarcharNotEqual(main.AddressLine3, TEMP.AddressLine3) = 0  
    AND dbo.IsVarcharNotEqual(main.PostalCode, TEMP.PostalCode) = 0  
    AND dbo.IsNVarcharNotEqual(main.Province, TEMP.Province) = 0  
    AND dbo.IsBigIntNotEqual(main.AddressId, TEMP.AddressId) = 0  
    AND dbo.IsBigIntNotEqual(main.Code, TEMP.Code) = 0  
   )  
  
 UPDATE stagDob  
 SET CoreAmlWatchlistId = TEMP.CoreAmlWatchlistId  
 FROM dbo.StagingAmlWatchListDateOfBirth stagDob  
 INNER JOIN #finalWatchlistData TEMP ON stagDob.UniqueId = TEMP.UniqueId  
  AND stagDob.WatchListSource = TEMP.WatchListSource  
 WHERE stagDob.[Guid] = @InternalGuid  
  AND TEMP.CoreAmlWatchListId IS NOT NULL  
  
 SELECT *  
 INTO #DoBFinalData  
 FROM (  
  SELECT *,  
   ROW_NUMBER() OVER (  
    PARTITION BY CoreAmlWatchlistId,  
    DateType,  
    DateOfBirthId,  
    DateOfBirth,  
    Age,  
    Deceased,  
    AgeDate,  
    [Day],  
    [Month],  
    [Year],  
    Code ORDER BY StagingAmlWatchListDateOfBirthId DESC  
    ) AS RowIndex  
  FROM dbo.StagingAmlWatchListDateOfBirth stag  
  WHERE [Guid] = @InternalGuid  
  ) n  
 WHERE n.RowIndex = 1  
  
 SELECT TEMP.StagingAmlWatchListDateOfBirthId,  
  TEMP.CoreAmlWatchListId,  
  TEMP.DateOfBirthId,  
  TEMP.DateType,  
  TEMP.DateOfBirth,  
  TEMP.IsMainEntry,  
  TEMP.BirthYear,  
  TEMP.BirthYearFrom,  
  TEMP.BirthYearTo,  
  TEMP.Notes,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.Age,  
  TEMP.Deceased,  
  TEMP.AgeDate,  
  TEMP.DowJonesPersonDateTypeId,  
  TEMP.DowJonesEntityDateTypeId,  
  TEMP.[Day],  
  TEMP.[Month],  
  TEMP.[Year],  
  TEMP.Code,  
  TEMP.LegalBasis,  
  TEMP.Link,  
  TEMP.Programme,  
  TEMP.OrderDate,  
  main.CoreAmlWatchListDateOfBirthId  
 INTO #updateDobData  
 FROM #DoBFinalData TEMP  
 INNER JOIN dbo.CoreAmlWatchListDateOfBirth main ON main.CoreAmlWatchlistId = TEMP.CoreAmlWatchListId  
  AND main.DateType = TEMP.DateType  
  AND main.DateOfBirthId = TEMP.DateOfBirthId  
  AND main.DateOfBirth = TEMP.DateOfBirth  
  AND main.Age = TEMP.Age  
  AND main.Deceased = TEMP.Deceased  
  AND main.AgeDate = TEMP.AgeDate  
  AND main.[Day] = TEMP.[Day]  
  AND main.[Month] = TEMP.[Month]  
  AND main.[Year] = TEMP.[Year]  
  AND main.Code = TEMP.Code  
 WHERE dbo.IsBitNotEqual(main.IsMainEntry, TEMP.IsMainEntry) = 1  
  OR dbo.IsVarcharNotEqual(main.BirthYear, TEMP.BirthYear) = 1  
  OR dbo.IsBigIntNotEqual(main.BirthYearFrom, TEMP.BirthYearFrom) = 1  
  OR dbo.IsBigIntNotEqual(main.BirthYearTo, TEMP.BirthYearTo) = 1  
  OR dbo.IsVarcharNotEqual(main.Notes, TEMP.Notes) = 1  
  OR dbo.IsBigIntNotEqual(main.DowJonesPersonDateTypeId, TEMP.DowJonesPersonDateTypeId) = 1  
  OR dbo.IsBigIntNotEqual(main.DowJonesEntityDateTypeId, TEMP.DowJonesEntityDateTypeId) = 1  
  OR dbo.IsVarcharNotEqual(main.LegalBasis, TEMP.LegalBasis) = 1  
  OR dbo.IsVarcharNotEqual(main.Link, TEMP.Link) = 1  
  OR dbo.IsVarcharNotEqual(main.Programme, TEMP.Programme) = 1  
  OR dbo.IsDateTimeNotEqual(main.OrderDate, TEMP.OrderDate) = 1  
  
 -- update CoreAmlWatchListDOB      
 UPDATE main  
 SET main.IsMainEntry = TEMP.IsMainEntry,  
  main.BirthYear = TEMP.BirthYear,  
  main.BirthYearFrom = TEMP.BirthYearFrom,  
  main.BirthYearTo = TEMP.BirthYearTo,  
  main.Notes = TEMP.Notes,  
  main.DowJonesPersonDateTypeId = TEMP.DowJonesPersonDateTypeId,  
  main.DowJonesEntityDateTypeId = TEMP.DowJonesEntityDateTypeId,  
  main.LegalBasis = TEMP.LegalBasis,  
  main.Link = TEMP.Link,  
  main.Programme = TEMP.Programme,  
  main.OrderDate = TEMP.OrderDate  
 FROM dbo.CoreAmlWatchListDateOfBirth main  
 INNER JOIN #updateDobData TEMP ON main.CoreAmlWatchListDateOfBirthId = TEMP.CoreAmlWatchListDateOfBirthId  
  
 INSERT INTO dbo.CoreAmlWatchListDateOfBirth (  
  CoreAmlWatchListId,  
  DateOfBirthId,  
  DateType,  
  DateOfBirth,  
  IsMainEntry,  
  BirthYear,  
  BirthYearFrom,  
  BirthYearTo,  
  Notes,  
  AddedBy,  
  AddedOn,  
  LastEditedBy,  
  EditedOn,  
  Age,  
  Deceased,  
  AgeDate,  
  DowJonesPersonDateTypeId,  
  DowJonesEntityDateTypeId,  
  [Day],  
  [Month],  
  [Year],  
  Code,  
  LegalBasis,  
  Link,  
  Programme,  
  OrderDate  
  )  
 SELECT TEMP.CoreAmlWatchListId,  
  TEMP.DateOfBirthId,  
  TEMP.DateType,  
  TEMP.DateOfBirth,  
  TEMP.IsMainEntry,  
  TEMP.BirthYear,  
  TEMP.BirthYearFrom,  
  TEMP.BirthYearTo,  
  TEMP.Notes,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.Age,  
  TEMP.Deceased,  
  TEMP.AgeDate,  
  TEMP.DowJonesPersonDateTypeId,  
  TEMP.DowJonesEntityDateTypeId,  
  TEMP.[Day],  
  TEMP.[Month],  
  TEMP.[Year],  
  TEMP.Code,  
  TEMP.LegalBasis,  
  TEMP.Link,  
  TEMP.Programme,  
  TEMP.OrderDate  
 FROM #DoBFinalData TEMP  
 WHERE NOT EXISTS (  
   SELECT 1  
   FROM dbo.CoreAmlWatchListDateOfBirth main  
   WHERE main.CoreAmlWatchlistId = TEMP.CoreAmlWatchListId  
    AND dbo.IsVarcharNotEqual(main.DateType, TEMP.DateType) = 0  
    AND dbo.IsBigIntNotEqual(main.DateOfBirthId, TEMP.DateOfBirthId) = 0  
    AND dbo.IsDateTimeNotEqual(main.DateOfBirth, TEMP.DateOfBirth) = 0  
    AND dbo.IsBigIntNotEqual(main.Age, TEMP.Age) = 0  
    AND dbo.IsDateTimeNotEqual(main.Deceased, TEMP.Deceased) = 0  
    AND dbo.IsDateTimeNotEqual(main.AgeDate, TEMP.AgeDate) = 0  
    AND dbo.IsVarcharNotEqual(main.[Day], TEMP.[Day]) = 0  
    AND dbo.IsVarcharNotEqual(main.[Month], TEMP.[Month]) = 0  
    AND dbo.IsVarcharNotEqual(main.[Year], TEMP.[Year]) = 0  
    AND dbo.IsBigIntNotEqual(main.Code, TEMP.Code) = 0  
   )  
  
 UPDATE watchId  
 SET watchId.CoreAmlWatchlistId = stag.CoreAmlWatchlistId  
 FROM dbo.StagingAmlWatchListIdentification watchId  
 INNER JOIN #finalWatchlistData stag ON stag.UniqueId = watchId.UniqueId  
  AND stag.WatchListSource = watchId.WatchListSource  
 WHERE watchId.[Guid] = @InternalGuid  
  AND stag.CoreAmlWatchlistId IS NOT NULL  
  
 SELECT *  
 INTO #IdentificationFinalData  
 FROM (  
  SELECT *,  
   ROW_NUMBER() OVER (  
    PARTITION BY CoreAmlWatchListId,  
    AmlWatchListIdentificationUniqueId,  
    IdValue,  
    IdValueDescription,  
    IdType,  
    Country,  
    RefCountryId,  
    Notes,  
    IdType2,  
    IssueDate,  
    ExpirationDate,  
    Code ORDER BY StagingAmlWatchListIdentificationId DESC  
    ) AS RowIndex  
  FROM dbo.StagingAmlWatchListIdentification stag  
  WHERE [Guid] = @InternalGuid  
  ) n  
 WHERE n.RowIndex = 1  
  
 SELECT TEMP.StagingAmlWatchListIdentificationId,  
  TEMP.CoreAmlWatchListId,  
  TEMP.AmlWatchListIdentificationUniqueId,  
  TEMP.IdType,  
  TEMP.IdType2,  
  TEMP.IdValue,  
  TEMP.Country,  
  TEMP.City,  
  TEMP.IssueDate,  
  TEMP.ExpirationDate,  
  TEMP.Notes,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.IdValueDescription,  
  TEMP.RefCountryId,  
  TEMP.Code,  
  TEMP.LegalBasis,  
  TEMP.Link,  
  TEMP.Programme,  
  TEMP.OrderDate,  
  main.CoreAmlWatchListIdentificationId  
 INTO #updateIdData  
 FROM #IdentificationFinalData TEMP  
 INNER JOIN dbo.CoreAmlWatchListIdentification main ON main.CoreAmlWatchListId = TEMP.CoreAmlWatchListId  
  AND main.UniqueId = TEMP.AmlWatchListIdentificationUniqueId  
  AND main.IdValue = TEMP.IdValue  
  AND main.IdValueDescription = TEMP.IdValueDescription  
  AND main.IdType = TEMP.IdType  
  AND main.Country = TEMP.Country  
  AND main.RefCountryId = TEMP.RefCountryId  
  AND main.Notes = TEMP.Notes  
  AND main.IdType2 = TEMP.IdType2  
  AND main.IssueDate = TEMP.IssueDate  
  AND main.ExpirationDate = TEMP.ExpirationDate  
  AND main.Code = TEMP.Code  
 WHERE dbo.IsVarcharNotEqual(main.City, TEMP.City) = 1  
  OR dbo.IsVarcharNotEqual(main.LegalBasis, TEMP.LegalBasis) = 1  
  OR dbo.IsVarcharNotEqual(main.Link, TEMP.Link) = 1  
  OR dbo.IsVarcharNotEqual(main.Programme, TEMP.Programme) = 1  
  OR dbo.IsDateTimeNotEqual(main.OrderDate, TEMP.OrderDate) = 1  
  
 UPDATE main  
 SET main.City = TEMP.City,  
  main.LegalBasis = TEMP.LegalBasis,  
  main.Link = TEMP.Link,  
  main.Programme = TEMP.Programme,  
  main.OrderDate = TEMP.OrderDate  
 FROM dbo.CoreAmlWatchListIdentification main  
 INNER JOIN #updateIdData TEMP ON main.CoreAmlWatchListIdentificationId = TEMP.CoreAmlWatchListIdentificationId  
  
 INSERT INTO dbo.CoreAmlWatchListIdentification (  
  CoreAmlWatchListId,  
  UniqueId,  
  IdType,  
  IdType2,  
  IdValue,  
  Country,  
  City,  
  IssueDate,  
  ExpirationDate,  
  Notes,  
  AddedBy,  
  AddedOn,  
  IdValueDescription,  
  RefCountryId,  
  Code,  
  LegalBasis,  
  Link,  
  Programme,  
  OrderDate,  
  LastEditedBy,  
  EditedOn  
  )  
 SELECT TEMP.CoreAmlWatchListId,  
  TEMP.AmlWatchListIdentificationUniqueId,  
  TEMP.IdType,  
  TEMP.IdType2,  
  TEMP.IdValue,  
  TEMP.Country,  
  TEMP.City,  
  TEMP.IssueDate,  
  TEMP.ExpirationDate,  
  TEMP.Notes,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.IdValueDescription,  
  TEMP.RefCountryId,  
  TEMP.Code,  
  TEMP.LegalBasis,  
  TEMP.Link,  
  TEMP.Programme,  
  TEMP.OrderDate,  
  TEMP.AddedBy,  
  TEMP.AddedOn  
 FROM #IdentificationFinalData TEMP  
 WHERE NOT EXISTS (  
   SELECT 1  
   FROM dbo.CoreAmlWatchListIdentification main  
   WHERE main.CoreAmlWatchListId = TEMP.CoreAmlWatchListId  
    AND dbo.IsBigIntNotEqual(main.UniqueId, TEMP.AmlWatchListIdentificationUniqueId) = 0  
    AND dbo.IsVarcharNotEqual(main.IdValue, TEMP.IdValue) = 0  
    AND dbo.IsNVarcharNotEqual(main.IdValueDescription, TEMP.IdValueDescription) = 0  
    AND dbo.IsVarcharNotEqual(main.IdType, TEMP.IdType) = 0  
    AND dbo.IsVarcharNotEqual(main.Country, TEMP.Country) = 0  
    AND dbo.IsBigIntNotEqual(main.RefCountryId, TEMP.RefCountryId) = 0  
    AND dbo.IsNVarcharNotEqual(main.Notes, TEMP.Notes) = 0  
    AND dbo.IsVarcharNotEqual(main.IdType2, TEMP.IdType2) = 0  
    AND dbo.IsDateTimeNotEqual(main.IssueDate, TEMP.IssueDate) = 0  
    AND dbo.IsDateTimeNotEqual(main.ExpirationDate, TEMP.ExpirationDate) = 0  
    AND dbo.IsBigIntNotEqual(main.Code, TEMP.Code) = 0  
   )  
  
 UPDATE con  
 SET con.CoreAmlWatchlistId = stag.CoreAmlWatchlistId  
 --con.CountryId = ref.RefCountryId       
 FROM dbo.StagingAmlWatchlistCountry con  
 INNER JOIN #finalWatchlistData stag ON stag.UniqueId = con.UniqueId  
  AND stag.WatchListSource = con.WatchListSource  
 LEFT JOIN dbo.RefCountry ref ON con.Country = ref.[Name]  
 WHERE con.[Guid] = @InternalGuid  
  AND stag.CoreAmlWatchlistId IS NOT NULL  
  
 SELECT *  
 INTO #CountryFinalData  
 FROM (  
  SELECT *,  
   ROW_NUMBER() OVER (  
    PARTITION BY CoreAmlWatchlistId,  
    Relation,  
    Code,  
    Country,  
    CountryId ORDER BY StagingAmlWatchlistCountryId DESC  
    ) AS RowIndex  
  FROM dbo.StagingAmlWatchlistCountry stag  
  WHERE [Guid] = @InternalGuid  
   AND (  
    Country IS NOT NULL  
    OR CountryId IS NOT NULL  
    )  
  ) n  
 WHERE n.RowIndex = 1  
  
 SELECT TEMP.StagingAmlWatchlistCountryId,  
  TEMP.CoreAmlWatchlistId,  
  TEMP.Relation,  
  TEMP.CountryId,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.Country,  
  TEMP.Nationality,  
  TEMP.Code,  
  TEMP.LegalBasis,  
  TEMP.Link,  
  TEMP.Programme,  
  TEMP.OrderDate,  
  main.CoreAmlWatchlistCountryId  
 INTO #CountryUpdateData  
 FROM #CountryFinalData TEMP  
 INNER JOIN dbo.CoreAmlWatchlistCountry main ON main.CoreAmlWatchlistId = TEMP.CoreAmlWatchlistId  
  AND main.RefCountryId = TEMP.CountryId  
  AND main.Relation = TEMP.Relation  
  AND main.Code = TEMP.Code  
  AND main.Country = TEMP.Country  
 WHERE dbo.IsVarcharNotEqual(main.Nationality, TEMP.Nationality) = 1  
  OR dbo.IsVarcharNotEqual(main.LegalBasis, TEMP.LegalBasis) = 1  
  OR dbo.IsVarcharNotEqual(main.Link, TEMP.Link) = 1  
  OR dbo.IsVarcharNotEqual(main.Programme, TEMP.Programme) = 1  
  OR dbo.IsDateTimeNotEqual(main.OrderDate, TEMP.OrderDate) = 1  
  
 UPDATE main  
 SET main.Nationality = TEMP.Nationality,  
  main.LegalBasis = TEMP.LegalBasis,  
  main.Link = TEMP.Link,  
  main.Programme = TEMP.Programme,  
  main.OrderDate = TEMP.OrderDate  
 FROM dbo.CoreAmlWatchlistCountry main  
 INNER JOIN #CountryUpdateData TEMP ON main.CoreAmlWatchlistCountryId = TEMP.CoreAmlWatchlistCountryId  
  
 INSERT INTO dbo.CoreAmlWatchlistCountry (  
  CoreAmlWatchlistId,  
  Relation,  
  RefCountryId,  
  AddedBy,  
  AddedOn,  
  LastEditedBy,  
  EditedOn,  
  Country,  
  Nationality,  
  Code,  
  LegalBasis,  
  Link,  
  Programme,  
  OrderDate  
  )  
 SELECT TEMP.CoreAmlWatchlistId,  
  TEMP.Relation,  
  TEMP.CountryId,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.Country,  
  TEMP.Nationality,  
  TEMP.Code,  
  TEMP.LegalBasis,  
  TEMP.Link,  
  TEMP.Programme,  
  TEMP.OrderDate  
 FROM #CountryFinalData TEMP  
 WHERE NOT EXISTS (  
   SELECT 1  
   FROM dbo.CoreAmlWatchlistCountry main  
   WHERE main.CoreAmlWatchlistId = TEMP.CoreAmlWatchlistId  
    AND dbo.IsBigIntNotEqual(main.RefCountryId, TEMP.CountryId) = 0  
    AND dbo.IsVarcharNotEqual(main.Relation, TEMP.Relation) = 0  
    AND dbo.IsBigIntNotEqual(main.Code, TEMP.Code) = 0  
    AND dbo.IsVarcharNotEqual(main.Country, TEMP.Country) = 0  
   )  
  
 --Update Link Table      
 UPDATE link  
 SET link.CoreAmlWatchlistId = stag.CoreAmlWatchlistId  
 FROM dbo.StagingAmlWatchListLink link  
 INNER JOIN #finalWatchlistData stag ON stag.UniqueId = link.UniqueId  
  AND stag.WatchListSource = link.WatchListSource  
 WHERE link.[Guid] = @InternalGuid  
  AND stag.CoreAmlWatchlistId IS NOT NULL  
  
 SELECT *  
 INTO #LinkFinalData  
 FROM (  
  SELECT *,  
   ROW_NUMBER() OVER (  
    PARTITION BY CoreAmlWatchlistId,  
    LinkUniqueId ORDER BY StagingAmlWatchListLinkId DESC  
    ) AS RowIndex  
  FROM dbo.StagingAmlWatchListLink stag  
  WHERE [Guid] = @InternalGuid  
   AND LinkUniqueId IS NOT NULL  
  ) n  
 WHERE n.RowIndex = 1  
  
 INSERT INTO dbo.CoreAmlWatchListLink (  
  CoreAmlWatchListId,  
  UniqueId,  
  AddedBy,  
  AddedOn,  
  LastEditedBy,  
  EditedOn  
  )  
 SELECT TEMP.CoreAmlWatchListId,  
  TEMP.LinkUniqueId,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.AddedBy,  
  TEMP.AddedOn  
 FROM #LinkFinalData TEMP  
 WHERE NOT EXISTS (  
   SELECT 1  
   FROM dbo.CoreAmlWatchListLink main  
   WHERE main.CoreAmlWatchListId = TEMP.CoreAmlWatchListId  
    AND main.UniqueId = TEMP.LinkUniqueId  
   )  
  
 --Update Keyword Table      
 UPDATE keyword  
 SET keyword.CoreAmlWatchlistId = stag.CoreAmlWatchlistId  
 FROM dbo.StagingAmlWatchListKeyword keyword  
 INNER JOIN #finalWatchlistData stag ON stag.UniqueId = keyword.UniqueId  
  AND stag.WatchListSource = keyword.WatchListSource  
 WHERE keyword.[Guid] = @InternalGuid  
  AND stag.CoreAmlWatchlistId IS NOT NULL  
  
 SELECT *  
 INTO #KeywordFinalData  
 FROM (  
  SELECT stag.StagingAmlWatchListKeywordId,  
   stag.CoreAmlWatchListId,  
   stag.UniqueId,  
   stag.WatchListSource,  
   stag.Keyword,  
   stag.AddedBy,  
   stag.AddedOn,  
   stag.RefAmlWatchListKeywordId,  
   ROW_NUMBER() OVER (  
    PARTITION BY stag.CoreAmlWatchlistId,  
    stag.Keyword ORDER BY StagingAmlWatchListKeywordId DESC  
    ) AS RowIndex,  
   watch.RefAmlWatchListSourceId  
  FROM dbo.StagingAmlWatchListKeyword stag  
  INNER JOIN #finalWatchlistData watch ON watch.CoreAmlWatchListId = stag.CoreAmlWatchListId  
  WHERE [Guid] = @InternalGuid  
   AND Keyword IS NOT NULL  
  ) n  
 WHERE n.RowIndex = 1  
  
 SELECT x.StagingAmlWatchListKeywordId,  
  x.CoreAmlWatchListId,  
  x.UniqueId,  
  x.WatchListSource,  
  x.Keyword,  
  x.AddedBy,  
  x.AddedOn,  
  x.RefAmlWatchListKeywordId,  
  x.RefAmlWatchListSourceId  
 INTO #InsertRefKeywordFinalData  
 FROM (  
  SELECT StagingAmlWatchListKeywordId,  
   CoreAmlWatchListId,  
   UniqueId,  
   WatchListSource,  
   Keyword,  
   AddedBy,  
   AddedOn,  
   RefAmlWatchListKeywordId,  
   RefAmlWatchListSourceId,  
   ROW_NUMBER() OVER (  
    PARTITION BY RefAmlWatchListSourceId,  
    Keyword ORDER BY StagingAmlWatchListKeywordId DESC  
    ) AS RowNum  
  FROM #KeywordFinalData  
  ) x  
 WHERE x.RowNum = 1  
  
 INSERT INTO dbo.RefAmlWatchListKeyword (  
  [Name],  
  Code,  
  RefAmlWatchListSourceId,  
  AddedBy,  
  AddedOn,  
  LastEditedBy,  
  EditedOn  
  )  
 SELECT tempr.Keyword,  
  tempr.Keyword,  
  tempr.RefAmlWatchListSourceId,  
  tempr.AddedBy,  
  tempr.AddedOn,  
  tempr.AddedBy,  
  tempr.AddedOn  
 FROM #InsertRefKeywordFinalData tempr  
 WHERE NOT EXISTS (  
   SELECT 1  
   FROM dbo.RefAmlWatchListKeyword keyword  
   WHERE keyword.[Name] = tempr.Keyword  
    AND keyword.[Code] = tempr.Keyword  
    AND keyword.RefAmlWatchListSourceId = tempr.RefAmlWatchListSourceId  
   )  
  
 UPDATE TEMP  
 SET TEMP.RefAmlWatchListKeywordId = ref.RefAmlWatchListKeywordId  
 FROM #KeywordFinalData TEMP  
 INNER JOIN dbo.RefAmlWatchListKeyword ref ON TEMP.Keyword = ref.[Name]  
  AND TEMP.RefAmlWatchListSourceId = ref.RefAmlWatchListSourceId  

  DELETE FROM dbo.CoreAmlWatchListKeyword 
	WHERE CoreAmlWatchListKeywordId IN (SELECT DISTINCT core.CoreAmlWatchListKeywordId 
	FROM dbo.CoreAmlWatchListKeyword core
	INNER  JOIN #KeywordFinalData temp ON  temp.CoreAmlWatchListId=core.CoreAmlWatchListId
	WHERE NOT EXISTS(SELECT 1 FROM #KeywordFinalData t WHERE core.CoreAmlWatchListId=t.CoreAmlWatchListId AND t.Keyword=core.Keyword)
	UNION 
	SELECT DISTINCT core.CoreAmlWatchListKeywordId 
	FROM dbo.CoreAmlWatchListKeyword core
	INNER JOIN #finalWatchlistData watch ON watch.CoreAmlWatchListId = core.CoreAmlWatchListId 
	WHERE NOT EXISTS(SELECT 1 FROM dbo.StagingAmlWatchListKeyword keyword WHERE  watch.UniqueId = keyword.UniqueId    
  AND watch.WatchListSource = keyword.WatchListSource)
	)
  
 INSERT INTO dbo.CoreAmlWatchListKeyword (  
  CoreAmlWatchListId,  
  Keyword,  
  AddedBy,  
  AddedOn,  
  LastEditedBy,  
  EditedOn,  
  RefAmlWatchListKeywordId  
  )  
 SELECT TEMP.CoreAmlWatchListId,  
  TEMP.Keyword,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.AddedBy,  
  TEMP.AddedOn,  
  TEMP.RefAmlWatchListKeywordId  
 FROM #KeywordFinalData TEMP  
 WHERE NOT EXISTS (  
   SELECT 1  
   FROM dbo.CoreAmlWatchListKeyword main  
   WHERE main.CoreAmlWatchListId = TEMP.CoreAmlWatchListId  
    AND main.Keyword = TEMP.Keyword  
   )  
  
 SELECT t.CoreAmlWatchListId  
 INTO #NewlyAdded  
 FROM (  
  SELECT a.CoreAmlWatchListId  
  FROM #NewlyInsertedWatchlistData a  
  ) t  
  
 SELECT t.CoreAmlWatchListId  
 INTO #Updated  
 FROM (  
  SELECT a.CoreAmlWatchListId  
  FROM #finalWatchlistData a  
  INNER JOIN #watchlistUpdatedData b ON b.CoreAmlWatchListId = a.CoreAmlWatchListId  
    
  UNION  
    
  SELECT a.CoreAmlWatchListId  
  FROM #AliasFinalData a  
  LEFT JOIN #NewlyInsertedWatchlistData b ON b.CoreAmlWatchListId = a.CoreAmlWatchListId  
  WHERE b.CoreAmlWatchListId IS NULL  
    
  UNION  
    
  SELECT a.CoreAmlWatchListId  
  FROM #AddressFinalData a  
  LEFT JOIN #NewlyInsertedWatchlistData b ON b.CoreAmlWatchListId = a.CoreAmlWatchListId  
  WHERE b.CoreAmlWatchListId IS NULL  
    
  UNION  
    
  SELECT a.CoreAmlWatchListId  
  FROM #DoBFinalData a  
  LEFT JOIN #NewlyInsertedWatchlistData b ON b.CoreAmlWatchListId = a.CoreAmlWatchListId  
  WHERE b.CoreAmlWatchListId IS NULL  
    
  UNION  
    
  SELECT a.CoreAmlWatchListId  
  FROM #IdentificationFinalData a  
  LEFT JOIN #NewlyInsertedWatchlistData b ON b.CoreAmlWatchListId = a.CoreAmlWatchListId  
  WHERE b.CoreAmlWatchListId IS NULL  
    
  UNION  
    
  SELECT a.CoreAmlWatchListId  
  FROM #CountryFinalData a  
  LEFT JOIN #NewlyInsertedWatchlistData b ON b.CoreAmlWatchListId = a.CoreAmlWatchListId  
  WHERE b.CoreAmlWatchListId IS NULL  
    
  UNION  
    
  SELECT a.CoreAmlWatchListId  
  FROM #LinkFinalData a  
  LEFT JOIN #NewlyInsertedWatchlistData b ON b.CoreAmlWatchListId = a.CoreAmlWatchListId  
  WHERE b.CoreAmlWatchListId IS NULL  
    
  UNION  
    
  SELECT a.CoreAmlWatchListId  
  FROM #KeywordFinalData a  
  LEFT JOIN #NewlyInsertedWatchlistData b ON b.CoreAmlWatchListId = a.CoreAmlWatchListId  
  WHERE b.CoreAmlWatchListId IS NULL  
  ) t  
  
 SELECT (  
   SELECT COUNT(1)  
   FROM #NewlyAdded  
   ) AS TotalNoOfNewRecordAdded,  
  (  
   SELECT COUNT(1)  
   FROM #Updated  
   ) AS TotalNoOfRecordUpdated  
  
 EXEC dbo.CoreAmlWatchlist_DeleteDataFromStaging @Guid = @InternalGuid  
END 
GO
--web-66995-RC end
go
CREATE PROCEDURE [dbo].[CoreAmlWatchlist_DeleteDataFromStaging]  
(  
 @Guid VARCHAR(100)  
)  
AS   
BEGIN  
 DECLARE @InternalGuid VARCHAR(100);  
 SET @InternalGuid = @Guid;  
  
 DELETE FROM dbo.[StagingAmlWatchListKeyword] WHERE [Guid] = @InternalGuid  
 DELETE FROM dbo.[StagingAmlWatchListLink] WHERE [Guid] = @InternalGuid  
 DELETE FROM dbo.[StagingAmlWatchlistCountry] WHERE [Guid] = @InternalGuid  
 DELETE FROM dbo.[StagingAmlWatchListIdentification] WHERE [Guid] = @InternalGuid  
 DELETE FROM dbo.[StagingAmlWatchListDateOfBirth] WHERE [Guid] = @InternalGuid  
 DELETE FROM dbo.[StagingAmlWatchListAddress] WHERE [Guid] = @InternalGuid  
 DELETE FROM dbo.[StagingAmlWatchListAlias] WHERE [Guid] = @InternalGuid  
 DELETE FROM dbo.[StagingAmlWatchList] WHERE [Guid] = @InternalGuid  
END
go