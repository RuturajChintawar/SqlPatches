GO
EXEC dbo.Sys_DropIfExists 'UpdateRefWebFileLocation_InsertAndUpdate_Custom','P'
GO
GO
CREATE PROCEDURE dbo.UpdateRefWebFileLocation_InsertAndUpdate_Custom(
	
	@TaskName VARCHAR(500),
	@TaskCode VARCHAR(200),
	@SementName  VARCHAR(100),
	@FileTypeName VARCHAR(50),
	@FrequencyName VARCHAR(100),
	@ExtraDays VARCHAR(100) = NULL
)
AS
BEGIN

	 DECLARE @TaskRefEntityTypeId INT,@TaskNameInternal VARCHAR(500),@TaskCodeInternal VARCHAR(200),@FormRefEntityTypeId INT,@TaskTypeRefEnumValueId INT,
		@TaskCategoryRefEnumValueId INT,@ActiveYesNoOptionRefEnumValueId INT,@IntroduceByRefEnumValueId INT,@IsVisible BIT,
		@RefTaskId INT, @RefWebFileLocationId INT,@RefSegmentId INT,@SementNameInternal VARCHAR(100),@RefAmlFileTypeId INT,@FileTypeNameInternal VARCHAR(50),
		@FrequencyEnumTypeId INT,@FrequencyNameInternal VARCHAR(50),@FrequencyEnumValueId INT,@ExtraDaysInternal VARCHAR(100),@ExtraDaysEnumTypeId INT

	 SET @TaskRefEntityTypeId = dbo.GetEntityTypeByCode('TaskMasterF1421')  
	 SET @TaskNameInternal = @TaskName
	 SET @TaskCodeInternal = @TaskCode
	 SET @FormRefEntityTypeId = dbo.GetEntityTypeByCode('TaskManagerMasterF1903')  
	 SET @TaskTypeRefEnumValueId = dbo.GetEnumValueId('TaskType','System')
	 SET @TaskCategoryRefEnumValueId = dbo.GetEnumValueId('TaskCategory','Not Required')
	 SET @ActiveYesNoOptionRefEnumValueId = dbo.GetEnumValueId('YesNoOption','Yes')
	 SET @IntroduceByRefEnumValueId = dbo.GetEnumValueId('IntroduceBy','System')
	 SET @IsVisible  = 1
	 
	 IF(NOT EXISTS (SELECT 1 FROM dbo.RefTask ref WHERE ref.TaskRefEntityTypeId = @TaskRefEntityTypeId AND ref.Code = @TaskCodeInternal AND ref.FormRefEntityTypeId = @FormRefEntityTypeId))
		 BEGIN
		 INSERT INTO dbo.RefTask (
			Code,
			[Name],
			TaskRefEntityTypeId,
			FormRefEntityTypeId,
			TaskTypeRefEnumValueId,
			TaskCategoryRefEnumValueId,
			ActiveYesNoOptionRefEnumValueId,
			IntroduceByRefEnumValueId,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedON,
			IsVisible)
			VALUES(
			@TaskCodeInternal,
			@TaskNameInternal,
			@TaskRefEntityTypeId,
			@FormRefEntityTypeId,
			@TaskTypeRefEnumValueId,
			@TaskCategoryRefEnumValueId,
			@ActiveYesNoOptionRefEnumValueId,
			@IntroduceByRefEnumValueId,
			'System',GETDATE(),
			'System',GETDATE(),
			@IsVisible
			)
		END

	 SELECT @RefTaskId  = ref.RefTaskId FROM dbo.RefTask ref WHERE ref.TaskRefEntityTypeId = @TaskRefEntityTypeId AND ref.Code = @TaskCodeInternal AND ref.FormRefEntityTypeId = @FormRefEntityTypeId
	 SET @SementNameInternal = @SementName
	 SET @RefSegmentId  = dbo.GetSegmentId(@SementNameInternal)
	 SET @FileTypeNameInternal = @FileTypeName
	 SELECT @RefAmlFileTypeId = ty.RefAmlFileTypeId FROM dbo.RefAmlFileType ty WHERE ty.[Name] = @FileTypeNameInternal
	 
	 SELECT  @RefWebFileLocationId = RefWebFileLocationid FROM(SELECT
											ref.RefWebFileLocationId,
											ROW_NUMBER() OVER(PARTITION BY ref.RefSegmentId,ref.RefAmlFileTypeId ORDER BY ref.AddedOn DESC)  RN
											FROM dbo.RefWebFileLocation ref WHERE ref.RefSegmentId = @RefSegmentId AND ref.RefAmlFileTypeId = @RefAmlFileTypeId)T
											WHERE t.RN = 1

	 SET @FrequencyNameInternal = @FrequencyName
	 SELECT @FrequencyEnumTypeId = ref.RefEnumTypeId FROM dbo.RefEnumType ref WHERE ref.[Name] = 'FileUploadFrequency'
	 SELECT @FrequencyEnumValueId = val.RefEnumValueId FROM dbo.RefEnumValue val WHERE val.[Name] = @FrequencyNameInternal AND val.RefEnumTypeId = @FrequencyEnumTypeId
	 SELECT @ExtraDaysInternal = @ExtraDays
	 SELECT @ExtraDaysEnumTypeId = ref.RefEnumTypeId FROM dbo.RefEnumType ref WHERE ref.[Name] = 'DaysInWeek'

	UPDATE web
	SET web.RefTaskId = @RefTaskId,
		web.FrequencyRefEnumValueId =  @FrequencyEnumValueId
	FROM dbo.RefWebFileLocation web
	WHERE web.RefWebFileLocationId = @RefWebFileLocationId

	SELECT 
		ref.RefEnumvalueId
	INTO #tempExtraDay
	FROM dbo.ParseString(@ExtraDaysInternal,',') s
	INNER JOIN dbo.RefEnumvalue ref ON ref.[Name] = s.s AND ref.RefEnumTypeId = @ExtraDaysEnumTypeId

	IF(@RefWebFileLocationId  <> NULL)
	BEGIN
		INSERT INTO dbo.LinkRefWebFileLocationRefEnumValue(
			RefWebFileLocationId,
			ExtraDayRefEnumValueId,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn
		)
		SELECT
			@RefWebFileLocationId,
			t.RefEnumvalueId,
			'System',GETDATE(),
			'System',GETDATE()
		FROM #tempExtraDay  t
	END
END
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='BSE_CASH_Bhav copy',@TaskCode='T158',@SementName  = 'BSE_CASH',@FileTypeName  = 'BhavCopy',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='BSE_CASH_Trade',@TaskCode='T159',@SementName  = 'BSE_CASH',@FileTypeName  = 'Trade',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='BSE_CASH_Iliquid Scrip',@TaskCode='T160',@SementName  = 'BSE_CASH',@FileTypeName  = 'Illiquid_BSE',@FrequencyName = 'Quarterly',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='BSE_CASH_Instrument',@TaskCode='T161',@SementName  = 'BSE_CASH',@FileTypeName  = 'Instrument',@FrequencyName = 'Daily',@ExtraDays = 'Saturday'
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='BSE_CASH_Order Log',@TaskCode='T162',@SementName  = 'BSE_CASH',@FileTypeName  = 'OrderLog',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='BSE_CASH_Capital Issued',@TaskCode='T163',@SementName  = 'BSE_CASH',@FileTypeName  = 'CapitalIssued',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName = 'BSE_CASH_Corporate Announcement',@TaskCode='T164',@SementName  = 'BSE_CASH',@FileTypeName  = 'CorporateAnnouncement',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName = 'BSE_CASH_Corporate Action',@TaskCode='T165',@SementName  = 'BSE_CASH',@FileTypeName  = 'CorporateAction',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName = 'BSE_CASH_Equity ISIN',@TaskCode='T166',@SementName  = 'BSE_CASH',@FileTypeName  = 'Equity_ISIN_File',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName = 'NSE_CASH_Instrument',@TaskCode='T167',@SementName  = 'NSE_CASH',@FileTypeName  = 'Instrument',@FrequencyName = 'Daily',@ExtraDays = 'Saturday'
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_CASH_BhavCopy',@TaskCode='T168',@SementName  = 'NSE_CASH',@FileTypeName  = 'BhavCopy',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_CASH_Trade',@TaskCode='T169',@SementName  = 'NSE_CASH',@FileTypeName  = 'Trade',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName = 'NSE_CASH_Corporate Announcement',@TaskCode='T170',@SementName  = 'NSE_CASH',@FileTypeName  = 'CorporateAnnouncement',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName = 'NSE_CASH_Volatility',@TaskCode='T171',@SementName  = 'NSE_CASH',@FileTypeName  = 'Volatility',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName = 'NSE_CASH_OrderLog',@TaskCode='T172',@SementName  = 'NSE_CASH',@FileTypeName  = 'OrderLog',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName = 'NSE_CASH_Iliquid Scrip',@TaskCode='T173',@SementName  = 'NSE_CASH',@FileTypeName  = 'Illiquid_NSE',@FrequencyName = 'Quarterly',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName = 'NSE_FNO_Instrument',@TaskCode='T174',@SementName  = 'NSE_FNO',@FileTypeName  = 'Instrument',@FrequencyName = 'Daily',@ExtraDays = 'Saturday'
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_FNO_BhavCopy',@TaskCode='T175',@SementName  = 'NSE_FNO',@FileTypeName  = 'BhavCopy',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_FNO_Trade',@TaskCode='T176',@SementName  = 'NSE_FNO',@FileTypeName  = 'Trade',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_FNO_Volatility',@TaskCode='T177',@SementName  = 'NSE_FNO',@FileTypeName  = 'Volatility',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_FNO_Margin',@TaskCode='T178',@SementName  = 'NSE_FNO',@FileTypeName  = 'Margin',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_FNO_Position',@TaskCode='T179',@SementName  = 'NSE_FNO',@FileTypeName  = 'Position',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_FNO_OrderLog',@TaskCode='T180',@SementName  = 'NSE_FNO',@FileTypeName  = 'OrderLog',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NCDEX_FNO_Trade',@TaskCode='T181',@SementName  = 'NCDEX_FNO',@FileTypeName  = 'Trade',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NCDEX_FNO_BhavCopy',@TaskCode='T182',@SementName  = 'NCDEX_FNO',@FileTypeName  = 'BhavCopy',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NCDEX_FNO_Position',@TaskCode='T183',@SementName  = 'NCDEX_FNO',@FileTypeName  = 'Position',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NCDEX_FNO_Margin',@TaskCode='T184',@SementName  = 'NCDEX_FNO',@FileTypeName  = 'Margin',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NCDEX_FNO_Instrument',@TaskCode='T185',@SementName  = 'NCDEX_FNO',@FileTypeName  = 'Instrument',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='MCX_FNO_Trade',@TaskCode='T186',@SementName  = 'MCX_FNO',@FileTypeName  = 'Trade',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='MCX_FNO_BhavCopy',@TaskCode='T187',@SementName  = 'MCX_FNO',@FileTypeName  = 'BhavCopy',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='MCX_FNO_Position',@TaskCode='T188',@SementName  = 'MCX_FNO',@FileTypeName  = 'Position',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='MCX_FNO_Margin',@TaskCode='T189',@SementName  = 'MCX_FNO',@FileTypeName  = 'Margin',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='MCX_FNO_Instrument',@TaskCode='T190',@SementName  = 'MCX_FNO',@FileTypeName  = 'Instrument',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='MCXSX_CDX_Trade',@TaskCode='T191',@SementName  = 'MCXSX_CDX',@FileTypeName  = 'Trade',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='MCXSX_CDX_BhavCopy',@TaskCode='T192',@SementName  = 'MCXSX_CDX',@FileTypeName  = 'BhavCopy',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='MCXSX_CDX_Position',@TaskCode='T193',@SementName  = 'MCXSX_CDX',@FileTypeName  = 'Position',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='MCXSX_CDX_Margin',@TaskCode='T194',@SementName  = 'MCXSX_CDX',@FileTypeName  = 'Margin',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='MCXSX_CDX_Instrument',@TaskCode='T195',@SementName  = 'MCXSX_CDX',@FileTypeName  = 'Instrument',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_CDX_Trade',@TaskCode='T196',@SementName  = 'NSE_CDX',@FileTypeName  = 'Trade',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_CDX_BhavCopy',@TaskCode='T197',@SementName  = 'NSE_CDX',@FileTypeName  = 'BhavCopy',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_CDX_Position',@TaskCode='T198',@SementName  = 'NSE_CDX',@FileTypeName  = 'Position',@FrequencyName = 'Daily',@ExtraDays = NULL
Go
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_CDX_Margin',@TaskCode='T199',@SementName  = 'NSE_CDX',@FileTypeName  = 'Margin',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSE_CDX_Instrument',@TaskCode='T200',@SementName  = 'NSE_CDX',@FileTypeName  = 'Instrument',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='CDSL_Bhavcopy (Closing Price)',@TaskCode='T201',@SementName  = 'CDSL',@FileTypeName  = 'Bhavcopy',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='CDSL_ISIN',@TaskCode='T202',@SementName  = 'CDSL',@FileTypeName  = 'ISIN',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='CDSL_Holding_A',@TaskCode='T203',@SementName  = 'CDSL',@FileTypeName  = 'Holding',@FrequencyName = 'Daily',@ExtraDays = 'Saturday,Sunday'
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='CDSL_Transaction_A',@TaskCode='T204',@SementName  = 'CDSL',@FileTypeName  = 'Transaction',@FrequencyName = 'Daily',@ExtraDays = 'Saturday,Sunday'
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='CDSL_DPS8 - Client Master_A',@TaskCode='T205',@SementName  = 'CDSL',@FileTypeName  = 'DPS8 - Effective from 25 - Nov - 2021',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='CDSL_DPM4 - Holding_A',@TaskCode='T206',@SementName  = 'CDSL',@FileTypeName  = 'DPM4 - Holding',@FrequencyName = 'Daily',@ExtraDays = 'Saturday,Sunday'
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSDL_BhavCopy (Combined File)',@TaskCode='T207',@SementName  = 'NSDL',@FileTypeName  = 'Bhavcopy',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSDL_ISIN',@TaskCode='T208',@SementName  = 'NSDL',@FileTypeName  = 'ISIN',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSDL_Holding_A',@TaskCode='T209',@SementName  = 'NSDL',@FileTypeName  = 'Holding',@FrequencyName = 'Daily',@ExtraDays = 'Saturday,Sunday'
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSDL_Transaction_A',@TaskCode='T210',@SementName  = 'NSDL',@FileTypeName  = 'Transaction',@FrequencyName = 'Daily',@ExtraDays = 'Saturday,Sunday'
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSDL_COD_A',@TaskCode='T211',@SementName  = 'NSDL',@FileTypeName  = 'NSDLCOD',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSDL_APOC_A',@TaskCode='T212',@SementName  = 'NSDL',@FileTypeName  = 'APOC - 15 nov 2021',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='CDSL_ Alerts',@TaskCode='T213',@SementName  = 'CDSL',@FileTypeName  = 'Transaction',@FrequencyName = 'Fortnightly',@ExtraDays = 'Saturday,Sunday'
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='NSDL_ Alerts',@TaskCode='T214',@SementName  = 'NSDL',@FileTypeName  = 'NSDLCOD',@FrequencyName = 'Daily',@ExtraDays = NULL
GO
GO
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='Holiday_Master',@TaskCode='T215',@SementName  = 'NSDL',@FileTypeName  = 'APOC - 15 nov 2021',@FrequencyName = 'Yearly',@ExtraDays = NULL
GO
EXEC dbo.Sys_DropIfExists 'UpdateRefWebFileLocation_InsertAndUpdate_Custom','P'
GO
