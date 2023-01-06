--WEB-68249-START-RC
GO
EXEC dbo.RefEnumType_Insert @EnumTypeName='AmlReportType',@EnumLevelCode= 'Flat'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName='AmlReportType',@EnumValueName = 'Exchange', @EnumValueCode = 'AmlReportType1'
GO
EXEC dbo.RefEnumValue_Insert @EnumTypeName='AmlReportType',@EnumValueName = 'DP', @EnumValueCode = 'AmlReportType2'
GO
--WEB-68249-END	-RC
--WEB-68249-START-RC
GO
ALTER TABLE dbo.RefAmlReport
ADD AmlReportTypeRefEnumValueId INT
GO
ALTER TABLE dbo.RefAmlReport  ADD  CONSTRAINT [FK_RefAmlReport_RefEnumValueId] FOREIGN KEY(AmlReportTypeRefEnumValueId)
REFERENCES dbo.RefEnumValue (RefEnumValueId)
GO
--WEB-68249-END	-RC

--WEB-68249-START-RC
GO
DECLARE @AmlReportTypeRefEnumValueId INT
SET @AmlReportTypeRefEnumValueId=dbo.GetEnumValueId('AmlReportType','AmlReportType1')

 UPDATE ref
 SET ref.AmlReportTypeRefEnumValueId=@AmlReportTypeRefEnumValueId
 FROM dbo.RefAmlReport ref
 WHERE ref.Code IN ('S151', 'S152', 'S153', 'S154', 'S155', 'S156', 'S157', 'S158', 'S159', 'S160', 'S161', 'S162', 'S163', 'S164', 'S165', 'S166', 'S167')

 SET @AmlReportTypeRefEnumValueId=dbo.GetEnumValueId('AmlReportType','AmlReportType2')

 UPDATE ref
 SET ref.AmlReportTypeRefEnumValueId=@AmlReportTypeRefEnumValueId
 FROM dbo.RefAmlReport ref
 WHERE ref.Code IN ('S832', 'S833', 'S834', 'S835', 'S836', 'S837', 'S838', 'S839', 'S840', 'S841')
 GO
--WEB-68249-END	-RC
