--WEB-66637-RC-START
GO
  ALTER PROCEDURE dbo.CoreAmlWatchList_Get    
(    
 @WatchListId INT    
)    
AS    
BEGIN     
        SELECT      
			watch.CoreAmlWatchListId ,    
            watchSource.RefAmlWatchListSourceId,    
            watchSource.[Name] AS [Source],
			watchSource.SourceCode,
            watch.OrderDate ,    
            watch.OrderDetails ,    
            watch.[Name] ,    
            watch.PAN ,    
            watch.[Address] ,    
            watch.[Period] ,    
            watch.CircularNo ,    
			watch.CircularLink,    
            watch.CircularDate ,    
            watch.Notes ,    
            watch.AddedBy ,    
            watch.AddedOn ,    
            watch.LastEditedBy ,    
            watch.EditedOn ,    
            watch.ListType ,    
            watch.OtherInfo ,    
            watch.UniqueId ,    
            watch.IsActive ,    
            watch.Title ,    
            watch.Position ,    
            watch.Companies ,    
            watch.RecordType ,    
            watch.Editor ,    
            watch.RefAmlWatchListCategoryId ,    
            watch.RefAmlWatchListSubCategoryId ,    
            watch.UpdatedDate ,    
            watch.InactiveDate ,    
            watch.TypeIdEnumValueId ,    
            watch.DIN ,    
            watch.CIN ,    
            watch.Aadhaar ,    
            watch.Mobile ,    
            watch.Email ,    
            watch.ISIN,    
            type1.[Name] AS [Type1],    
            type1.RefEnumValueId AS [Type1Id],    
            watch.LinkedTo,    
            watch.Bank,    
            watch.Branch,    
            watch.OutStandingAmountInLacs,    
            watch.[State],    
            watch.LinkedOrders,    
            watch.EntityOriginalSource,    
   watch.LastDayUpdated,    
   CASE WHEN watch.GenderRefEnumValueId IS NOT NULL    
    THEN gender.[Name]    
    ELSE watch.Gender END AS Gender    
        FROM dbo.CoreAmlWatchList watch                   
        INNER JOIN dbo.RefAmlWatchListSource watchSource ON watchSource.RefAmlWatchListSourceId = watch.Source    
        LEFT JOIN dbo.RefEnumValue type1 ON type1.RefEnumValueId = watch.TypeIdEnumValueId    
		LEFT JOIN dbo.RefEnumValue gender ON watch.GenderRefEnumValueId = gender.RefEnumValueId    
        WHERE watch.CoreAmlWatchListId = @WatchListId    
                    
        SELECT    
   watchAddress.CoreAmlWatchListAddressId ,    
            watchAddress.CoreAmlWatchListId ,    
            watchAddress.RefAddressTypeId ,    
            watchAddress.AddressId ,    
            watchAddress.IsMainEntry ,    
            watchAddress.AddressLine1 ,    
            watchAddress.AddressLine2 ,    
            watchAddress.AddressLine3 ,    
            watchAddress.City ,    
            watchAddress.[State],    
            watchAddress.PostalCode ,    
            watchAddress.Country ,    
            watchAddress.Notes ,    
            watchAddress.AddedBy ,    
            watchAddress.AddedOn ,    
            watchAddress.LastEditedBy ,    
            watchAddress.EditedOn    
        FROM dbo.CoreAmlWatchListAddress watchAddress    
        INNER JOIN dbo.CoreAmlWatchList watch ON watchAddress.CoreAmlWatchListId = watch.CoreAmlWatchListId    
        WHERE watch.CoreAmlWatchListId = @WatchListId    
                    
        SELECT  alias.CoreAmlWatchListAliasId ,    
                alias.CoreAmlWatchListId ,    
                alias.FirstName ,    
                alias.LastName ,    
                alias.AliasId ,    
                alias.AliasType ,    
                alias.Strength ,    
                alias.Notes ,    
                alias.AddedBy ,    
                alias.AddedOn ,    
                alias.LastEditedBy ,    
                alias.EditedOn    
        FROM    dbo.CoreAmlWatchListAlias alias    
                INNER JOIN dbo.CoreAmlWatchList watch ON alias.CoreAmlWatchListId = watch.CoreAmlWatchListId    
                where watch.CoreAmlWatchListId = @WatchListId    
                    
        SELECT  Dob.CoreAmlWatchListDateOfBirthId ,    
            Dob.CoreAmlWatchListId ,    
                Dob.DateOfBirthId ,    
                Dob.DateType ,    
                Dob.DateOfBirth ,    
                Dob.IsMainEntry ,    
                Dob.BirthYear ,    
                Dob.BirthYearFrom ,    
                Dob.BirthYearTo ,    
                Dob.Notes ,    
                Dob.AddedBy ,    
                Dob.AddedOn ,    
                Dob.LastEditedBy ,    
                Dob.EditedOn ,    
                Dob.Age ,    
                Dob.Deceased ,    
                Dob.AgeDate,    
    Dob.[Day],    
    Dob.[Month],    
    Dob.[Year]    
        FROM    dbo.CoreAmlWatchListDateOfBirth Dob    
                INNER JOIN dbo.CoreAmlWatchList watch ON Dob.CoreAmlWatchListId = watch.CoreAmlWatchListId    
                where watch.CoreAmlWatchListId = @WatchListId    
                    
        SELECT  identification.CoreAmlWatchListIdentificationId ,    
                identification.CoreAmlWatchListId ,    
                identification.UniqueId ,    
                identification.IdType ,    
                identification.IdType2 ,    
                identification.IdValue ,    
                identification.IdValueDescription,    
                identification.Country ,    
                identification.City ,    
                identification.IssueDate ,    
                identification.ExpirationDate ,    
                identification.Notes ,    
                identification.AddedBy ,    
                identification.AddedOn ,    
                identification.LastEditedBy ,    
                identification.EditedOn    
        FROM    dbo.CoreAmlWatchListIdentification identification    
                INNER JOIN dbo.CoreAmlWatchList watch ON identification.CoreAmlWatchListId = watch.CoreAmlWatchListId    
                where watch.CoreAmlWatchListId = @WatchListId    
                    
                    
        SELECT  vessel.CoreAmlWatchListVesselInfoId ,    
                vessel.CoreAmlWatchListId ,    
                vessel.CallSign ,    
                vessel.VesselType ,    
                vessel.VesselFlag ,    
                vessel.VesselOwner ,    
                vessel.Tonnage ,    
                vessel.GrossRegisteredTonnage ,    
                vessel.AddedBy ,    
                vessel.AddedOn ,    
                vessel.LastEditedBy ,    
                vessel.EditedOn    
        FROM    dbo.CoreAmlWatchListVesselInfo vessel    
                INNER JOIN dbo.CoreAmlWatchList watch ON vessel.CoreAmlWatchListId = watch.CoreAmlWatchListId    
                where watch.CoreAmlWatchListId = @WatchListId    
                    
        SELECT  link.CoreAmlWatchListLinkId ,    
                link.CoreAmlWatchListId ,    
                link.UniqueId ,    
                link.AddedBy ,    
                link.AddedOn ,    
                link.LastEditedBy ,    
                link.EditedOn    
        FROM    dbo.CoreAmlWatchListLink link    
                INNER JOIN dbo.CoreAmlWatchList watch ON link.CoreAmlWatchListId = watch.CoreAmlWatchListId    
                where watch.CoreAmlWatchListId = @WatchListId    
            
        SELECT  keyword.CoreAmlWatchListKeywordId ,    
                keyword.CoreAmlWatchListId ,    
                keyword.Keyword ,    
                keyword.AddedBy ,    
                keyword.AddedOn ,    
                keyword.LastEditedBy ,    
                keyword.EditedOn    
        FROM    dbo.CoreAmlWatchListKeyword keyword    
                INNER JOIN dbo.CoreAmlWatchList watch ON keyword.CoreAmlWatchListId = watch.CoreAmlWatchListId    
                where watch.CoreAmlWatchListId = @WatchListId    
                    
                    
                select      
                birthplace.CoreamlwatchlistBirthPlaceId,    
    birthplace.CoreAmlWatchlistId,    
    birthplace.Name as BirthPlace,    
    birthplace.AddedBy,    
    birthplace.AddedOn,    
    birthplace.LastEditedBy,    
    birthplace.EditedOn    
                from  dbo.CoreamlwatchlistBirthPlace birthplace    
                INNER JOIN dbo.CoreAmlWatchList watch ON birthplace.CoreAmlWatchListId = watch.CoreAmlWatchListId    
                where watch.CoreAmlWatchListId = @WatchListId    
                    
                select     
                country.CoreAmlWatchlistCountryId,    
    country.CoreAmlWatchlistId,    
    country.Relation,    
    country.RefCountryId,    
    CASE WHEN con.[Name] IS NULL THEN country.Country  
 ELSE con.[Name] END AS [Country],    
    country.AddedBy,    
    country.AddedOn,    
    country.LastEditedBy,    
    country.EditedOn    
                from dbo.CoreAmlWatchlistCountry country    
                INNER JOIN dbo.CoreAmlWatchList watch ON country.CoreAmlWatchListId = watch.CoreAmlWatchListId    
                LEFT JOIN dbo.RefCountry con  on con.RefCountryId=country.RefCountryId    
                where watch.CoreAmlWatchListId = @WatchListId    
                    
                select     
                keydata.CoreAmlWatchListKeyValueDataId,    
    keydata.CoreAmlWatchListId,    
    keydata.KeyValueDataTypeRefEnumValueId,    
    evalue.Name as KeyValueDataType,    
    keydata.[Type],    
    keydata.Value,    
    keydata.AddedBy,    
    keydata.AddedOn,    
    keydata.LastEditedBy,    
    keydata.EditedOn    
                from dbo.CoreAmlWatchListKeyValueData keydata    
                INNER JOIN dbo.CoreAmlWatchList watch ON keydata.CoreAmlWatchListId = watch.CoreAmlWatchListId    
                left join dbo.RefEnumValue evalue on evalue.RefEnumValueId=keydata.KeyValueDataTypeRefEnumValueId    
                where watch.CoreAmlWatchListId = @WatchListId    
                    
END    
GO
--WEB-66637-RC-END