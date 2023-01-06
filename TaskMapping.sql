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
EXEC UpdateRefWebFileLocation_InsertAndUpdate_Custom @TaskName ='Trade_EffectiveFrom_Sep2022',@TaskCode='T216',@SementName  = 'BSE_CASH',@FileTypeName  = 'Trade_EffectiveFrom_Sep2022',@FrequencyName = 'Daily',@ExtraDays = NULL

GO
EXEC dbo.Sys_DropIfExists 'UpdateRefWebFileLocation_InsertAndUpdate_Custom','P'
GO
