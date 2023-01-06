
--start-WEB-68218-RC
GO
UPDATE ref
SET ref.[Name]='OFAC Consolidated Non SDN'
FROM dbo.RefAmlWatchListSource ref
WHERE SourceCode='67'
GO
--end-WEB-68218-RC
--start-WEB-68218-RC
GO
UPDATE ref
SET ref.[Name]='OFAC Consolidated Non SDN'
FROM dbo.RefAmlFileType ref
WHERE [Name]='OFAC Consolidated'
GO
--end-WEB-68218-RC