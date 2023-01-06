---passport-(2 records)
 DELETE 
FROM dbo.CoreAmlWatchListIdentification
WHERE CoreAmlWatchListIdentificationId IN(
SELECT core.*
 FROM dbo.CoreAmlWatchListIdentification core
 INNER JOIN dbo.CoreAmlWatchList list ON list.CoreAmlWatchListId=core.CoreAmlWatchListId
 INNER JOIN dbo.RefAmlWatchlistsource sou ON sou.RefAmlWatchListSourceId=list.[Source]
 WHERE sou.Sourcecode=33)


 ---passport-( 2 records)
DELETE 
FROM dbo.CoreAmlWatchListDateOfBirth
WHERE CoreAmlWatchListDateOfBirthId IN(
 SELECT core.*
 FROM dbo.CoreAmlWatchListDateOfBirth core
 INNER JOIN dbo.CoreAmlWatchList list ON list.CoreAmlWatchListId=core.CoreAmlWatchListId
 INNER JOIN dbo.RefAmlWatchlistsource sou ON sou.RefAmlWatchListSourceId=list.Source
 WHERE sou.Sourcecode=4)

 dbo.CoreAmlWatchList list  
 INNER JOIN dbo.RefAmlWatchlistsource sou ON sou.RefAmlWatchListSourceId=4
 WHERE list.AddedOn='2022-01-20'
 LinkRefAmlReportRefClientAlertExclusion