GO
ALTER PROCEDURE [dbo].[CoreAmlWatchList_InsertNSEDefaulterMembersFromStaging] (@Guid VARCHAR(100))  
AS  
BEGIN  
 IF (  
   EXISTS (  
    SELECT 1  
    FROM dbo.RefAmlWatchListSource  
    WHERE name = 'NSE_SEBI'  
    )  
   )  
 BEGIN  
  UPDATE dbo.StagingAmlWatchlistNseDefaulter  
  SET AmlWatchListSource = 'NSE_SEBI'  
  WHERE GUID = @guid  
   AND AmlWatchListSource = 'SEBI'  
   OR AmlWatchListSource = 'SEBI_Debarred'  
 END  
  
 IF (  
   EXISTS (  
    SELECT 1  
    FROM dbo.RefAmlWatchListSource  
    WHERE name = 'SEBI'  
    )  
   )  
 BEGIN  
  UPDATE dbo.StagingAmlWatchlistNseDefaulter  
  SET AmlWatchListSource = 'SEBI'  
  WHERE GUID = @guid  
   AND AmlWatchListSource = 'NSE_SEBI'  
   OR AmlWatchListSource = 'SEBI_Debarred'  
 END  
  
 IF (  
   EXISTS (  
    SELECT 1  
    FROM dbo.RefAmlWatchListSource  
    WHERE name = 'SEBI_Debarred'  
    )  
   )  
 BEGIN  
  UPDATE dbo.StagingAmlWatchlistNseDefaulter  
  SET AmlWatchListSource = 'SEBI_Debarred'  
  WHERE GUID = @guid  
   AND AmlWatchListSource = 'NSE_SEBI'  
   OR AmlWatchListSource = 'SEBI'  
 END  
  
 DECLARE @RefEnumTypeId INT,  
  @RefAddressTypeId INT  
  
 SELECT @RefEnumTypeId = RefEnumTypeId  
 FROM dbo.RefEnumType  
 WHERE Name = 'WatchListType1'  
  
 SELECT @RefAddressTypeId = RefAddressTypeId  
 FROM dbo.RefAddressType  
 WHERE Name = 'Address'  
  
 SELECT stag.StagingAmlWatchlistNseDefaulterId,  
  watch.CoreAmlWatchListId,  
  stag.[Guid],  
  ISNULL(stag.UniqueId, stag.CircularNo) AS UniqueId,  
  stag.OrderDate,  
  stag.OrderParticulars,  
  stag.Name,  
  stag.OtherInformation,  
  stag.amlwatchlistsource,  
  stag.[Address],  
  stag.Passport,  
  stag.PAN,  
  stag.Period,  
  CASE   
   WHEN stag.Active = 'Y'  
    THEN 1  
   ELSE 0  
   END AS Active,  
  stag.InactiveDate,  
  stag.Type1,  
  stag.DIN,  
  stag.CIN,  
  stag.Alias1,  
  stag.Alias2,  
  stag.Aadhaar,  
  stag.Mobile,  
  stag.Email,  
  stag.ISIN,  
  stag.Gender,  
  stag.DateOfBirth,  
  stag.Nationality,  
  stag.LinkedTo,  
  stag.LinkedOrders,  
  stag.AddedBy,  
  stag.AddedOn,  
  sourcedata.RefAmlWatchListSourceId AS [Source],  
  stag.CircularNo,  
  stag.CircularDate,  
  stag.CircularLink,  
  stag.TWWatchlistEntityId  
 INTO #StagingAmlWatchlistNseDefaulter  
 FROM dbo.StagingAmlWatchlistNseDefaulter stag  
 INNER JOIN dbo.RefAmlWatchListSource sourcedata ON sourcedata.Name = stag.AmlWatchListSource OR sourcedata.SourceCode = stag.AmlWatchListSource  
 LEFT JOIN dbo.CoreAmlWatchList watch ON watch.Source = sourcedata.RefAmlWatchListSourceId  
  AND stag.UniqueId = watch.UniqueId  
 WHERE stag.[Guid] = @Guid  
  
 INSERT INTO dbo.StagingAmlWatchList (  
  RefAmlWatchListSourceId,  
  WatchListSource,  
  OrderDate,  
  OrderDetails,  
  Name,  
  PAN,  
  Address,  
  Period,  
  AddedOn,  
  AddedBy,  
  circulardate,  
  CircularNo,  
  CircularLink,  
  OtherInfo,  
  UniqueId,  
  IsActive,  
  InactiveDate,  
  TypeIdEnumValueId,  
  DIN,  
  CIN,  
  Aadhaar,  
  Mobile,  
  Email,  
  ISIN,  
  LinkedTo,  
  LinkedOrders,  
  Gender,  
  TWWatchlistEntityId,  
  Guid  
  )  
 SELECT stage.Source,  
  stage.Amlwatchlistsource,  
  stage.OrderDate,  
  OrderParticulars,  
  stage.Name,  
  stage.PAN,  
  stage.Address,  
  stage.Period,  
  stage.AddedOn,  
  stage.AddedBy,  
  stage.circulardate,  
  stage.CircularNo,  
  stage.CircularLink,  
  stage.OtherInformation,  
  stage.UniqueId,  
  stage.Active,  
  stage.InactiveDate,  
  enumvalue.RefEnumValueId,  
  stage.DIN,  
  stage.CIN,  
  stage.Aadhaar,  
  stage.Mobile,  
  stage.Email,  
  stage.ISIN,  
  stage.LinkedTo,  
  stage.LinkedOrders,  
  stage.Gender,  
  stage.TWWatchlistEntityId,  
  stage.GUID  
 FROM #StagingAmlWatchlistNseDefaulter stage  
 LEFT JOIN dbo.RefEnumValue enumvalue ON enumvalue.RefEnumTypeId = @RefEnumTypeId  
  AND enumvalue.Name = stage.Type1  
  
 SELECT watch.CoreAmlWatchListId,  
  stag.[Guid],  
  ISNULL(stag.UniqueId, stag.CircularNo) AS UniqueId,  
  stag.OrderDate,  
  stag.Passport,  
  stag.DateOfBirth,  
  stag.AmlWatchListSource,  
  stag.LinkedTo,  
  stag.LinkedOrders,  
  stag.AddedBy,  
  stag.AddedOn,  
  watch.LastEditedBy,  
  watch.EditedOn,  
  sourcedata.RefAmlWatchListSourceId AS [Source]  
 INTO #StagingAmlWatchlistNseDefaulterforDobAndPassport  
 FROM dbo.StagingAmlWatchlistNseDefaulter stag  
 INNER JOIN dbo.RefAmlWatchListSource sourcedata ON sourcedata.Name = stag.AmlWatchListSource OR sourcedata.SourceCode = stag.AmlWatchListSource  
 LEFT JOIN dbo.CoreAmlWatchList watch ON watch.Source = sourcedata.RefAmlWatchListSourceId  
  AND stag.UniqueId = watch.UniqueId  
 WHERE stag.[Guid] = @Guid  
  
 INSERT INTO dbo.StagingAmlWatchListDateOfBirth (  
  CoreAmlWatchListId,  
  Watchlistsource,  
  DateType,  
  DateOfBirth,  
  UniqueId,  
  AddedBy,  
  AddedOn,  
  Guid  
  )  
 SELECT stag.CoreAmlWatchListId,  
  stag.amlwatchlistsource,  
  'Exact',  
  stag.DateOfBirth,  
  stag.UniqueId,  
  stag.AddedBy,  
  Stag.AddedOn,  
  Guid  
 FROM #StagingAmlWatchlistNseDefaulterforDobAndPassport stag  
 WHERE stag.DateOfBirth IS NOT NULL  
  AND stag.amlwatchlistsource IS NOT NULL  
  
 INSERT INTO dbo.StagingAmlWatchListIdentification (  
  CoreAmlWatchListId,  
  UniqueId,  
  AmlWatchListIdentificationUniqueId,  
  WatchListSource,  
  IdType,  
  IdValue,  
  AddedBy,  
  AddedOn,  
  Guid  
  )  
 SELECT stag.CoreAmlWatchListId,  
  stag.UniqueId,  
  stag.UniqueId,  
  stag.AmlWatchListSource,  
  'Passport',  
  stag.Passport,  
  stag.AddedBy,  
  Stag.AddedOn,  
  GUID  
 FROM #StagingAmlWatchlistNseDefaulterforDobAndPassport stag  
 WHERE REPLACE(ISNULL(stag.Passport, ''), ' ', '') != ''  
  AND stag.amlwatchlistsource IS NOT NULL  
  
 SELECT StagingAmlWatchlistNseDefaulterId,  
  watch.CoreAmlWatchListId,  
  ISNULL(stag.UniqueId, stag.CircularNo) AS UniqueId,  
  stag.AmlWatchListSource,  
  stag.GUID,  
  country.RefCountryId,  
  nationality.s AS Nationality,  
  stag.AddedBy,  
  stag.AddedOn,  
  sourcedata.RefAmlWatchListSourceId AS [Source]  
 INTO #StagingAmlWatchlistNseDefaulterforNationality  
 FROM dbo.StagingAmlWatchlistNseDefaulter stag  
 INNER JOIN dbo.RefAmlWatchListSource sourcedata ON sourcedata.Name = stag.AmlWatchListSource OR sourcedata.SourceCode = stag.AmlWatchListSource  
 LEFT JOIN dbo.CoreAmlWatchList watch ON watch.Source = sourcedata.RefAmlWatchListSourceId  
  AND stag.UniqueId = watch.UniqueId  
 CROSS APPLY dbo.ParseString(stag.Nationality, ',') AS nationality  
 LEFT JOIN dbo.RefCountry country ON country.Name = nationality.s  
 WHERE stag.GUID = @Guid  
  AND stag.amlwatchlistsource IS NOT NULL  
  
 INSERT INTO dbo.StagingAmlWatchlistCountry (  
  CoreAmlWatchlistId,  
  UniqueId,  
  WatchListSource,  
  Relation,  
  CountryId,  
  Country,  
  AddedBy,  
  AddedOn,  
  Guid  
  )  
 SELECT stag.CoreAmlWatchListId,  
  stag.UniqueId,  
  stag.AmlWatchListSource,  
  'Nationality',  
  stag.RefCountryId,  
  stag.Nationality,  
  stag.AddedBy,  
  stag.AddedOn,  
  stag.Guid  
 FROM #StagingAmlWatchlistNseDefaulterforNationality stag  
  
 SELECT StagingAmlWatchlistNseDefaulterId,  
  watch.CoreAmlWatchListId,  
  stag.UniqueId,  
  stag.AmlWatchListSource,  
  stag.GUID,  
  country.RefCountryId,  
  stag.AddedBy,  
  stag.AddedOn,  
  sourcedata.RefAmlWatchListSourceId AS [Source],  
  stag.Country,  
  stag.[State],  
  stag.PostalCode,  
  stag.City,  
  @RefAddressTypeId AS RefAddressTypeId,  
  stag.Address  
 INTO #StagingAmlWatchListAddress  
 FROM dbo.StagingAmlWatchlistNseDefaulter stag  
 INNER JOIN dbo.RefAmlWatchListSource sourcedata ON sourcedata.Name=stag.AmlWatchListSource  OR sourcedata.SourceCode = stag.AmlWatchListSource  
 LEFT JOIN dbo.CoreAmlWatchList watch ON watch.Source = sourcedata.RefAmlWatchListSourceId  
  AND stag.UniqueId = watch.UniqueId  
 LEFT JOIN dbo.RefCountry country ON country.Name = stag.Country  
 WHERE stag.GUID = @Guid  
  AND stag.amlwatchlistsource IS NOT NULL  
  AND (watch.CoreAmlWatchListId IS NOT NULL)  
  AND (  
   ISNULL(stag.Country, '') <> ''  
   OR ISNULL(stag.[State], '') <> ''  
   OR ISNULL(stag.PostalCode, '') <> ''  
   OR ISNULL(stag.City, '') <> ''  
   )  
  
 INSERT INTO dbo.StagingAmlWatchListAddress (  
  CoreAmlWatchlistId,  
  UniqueId,  
  WatchListSource,  
  AddedBy,  
  AddedOn,  
  Guid,  
  City,  
  Country,  
  RefCountryId,  
  RefAddressTypeId,  
  PostalCode,  
  STATE,  
  AddressLine1,  
  AddressType  
  )  
 SELECT CoreAmlWatchlistId,  
  UniqueId,  
  AmlWatchListSource,  
  AddedBy,  
  AddedOn,  
  GUID,  
  City,  
  Country,  
  RefCountryId,  
  RefAddressTypeId,  
  PostalCode,  
  STATE,  
  Address,  
  'Address'  
 FROM #StagingAmlWatchListAddress  

	SELECT * INTO #tempAlias1 FROM #StagingAmlWatchlistNseDefaulter stage
	CROSS APPLY dbo.Split(stage.Alias1,';')

   
	SELECT * INTO #tempAlias2 FROM #StagingAmlWatchlistNseDefaulter stage
	CROSS APPLY  dbo.Split(stage.Alias2,';')

	INSERT INTO dbo.StagingAmlWatchListAlias (
		UniqueId,
		WatchListSource,
		AliasType,
		FirstName,
		AddedBy,
		AddedOn,
		Guid
		)
	SELECT stag.UniqueId,
		stag.AmlWatchListSource,
		'Alias1',
		LTRIM(RTRIM(stag.items)),
		stag.AddedBy,
		stag.AddedOn,
		GUID
	FROM #tempAlias1 stag
	WHERE stag.Alias1 IS NOT NULL AND LTRIM(RTRIM(stag.items)) <>''

	INSERT INTO dbo.StagingAmlWatchListAlias (
		UniqueId,
		WatchListSource,
		AliasType,
		FirstName,
		AddedBy,
		AddedOn,
		Guid
		)
	SELECT stag.UniqueId,
		stag.AmlWatchListSource,
		'Alias2',
		LTRIM(RTRIM(stag.items)),
		stag.AddedBy,
		stag.AddedOn,
		GUID
	FROM #tempAlias2 stag
	WHERE stag.Alias2 IS NOT NULL AND LTRIM(RTRIM(stag.items)) <>''
  
	DELETE  
	FROM dbo.StagingAmlWatchlistNseDefaulter  
	WHERE [Guid] = @Guid  
  
	EXECUTE [dbo].[CoreAmlWatchlist_InsertDataFromStaging] @GUID = @Guid  
END  
GO
