--WEB-66630 RC START
GO
DECLARE 
@UNSC_1267 INT,@OFAC INT,@UNSC_1988 INT,@UNSC_2140 INT,@UNSC_2270 INT,@BSE_REGULATORY_DEFAULTING_CLIENTS INT
SET @UNSC_1267=(SELECT RefAmlWatchListSourceId FROM dbo.RefAmlWatchlistsource WHERE [Name]='UNSC_1267')
SET @UNSC_1988=(SELECT RefAmlWatchListSourceId FROM dbo.RefAmlWatchlistsource WHERE [Name]='UNSC_1988')
SET @UNSC_2140=(SELECT RefAmlWatchListSourceId FROM dbo.RefAmlWatchlistsource WHERE [Name]='UNSC_2140')
SET @UNSC_2270=(SELECT RefAmlWatchListSourceId FROM dbo.RefAmlWatchlistsource WHERE [Name]='UNSC_2270')
SET @BSE_REGULATORY_DEFAULTING_CLIENTS=(SELECT RefAmlWatchListSourceId FROM dbo.RefAmlWatchlistsource WHERE [Name]='BSE_REGULATORY_DEFAULTING_CLIENTS')
SET @OFAC=(SELECT RefAmlWatchListSourceId FROM dbo.RefAmlWatchlistsource WHERE [Name]='OFAC')


UPDATE list
SET list.CircularNo = NULL
FROM dbo.CoreAmlWatchList list  
WHERE list.[Source] IN (@UNSC_1267,@UNSC_1988,@UNSC_2140,@UNSC_2270,@BSE_REGULATORY_DEFAULTING_CLIENTS,@OFAC) AND list.CircularNo=list.UniqueId
GO
--WEB-66630 RC END