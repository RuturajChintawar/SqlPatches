------WEB-64402 RC END---
GO
ALTER PROCEDURE [dbo].[RefAmlScenarioRule_H1084MoveApprovedRulesToRuleWritingTable]      
(      
@AmlScenarioRuleMakerCheckerId BIGINT  
)      
AS      
BEGIN      
       
 DECLARE @InternalAmlScenarioRuleMakerCheckerId BIGINT      
 SET @InternalAmlScenarioRuleMakerCheckerId = @AmlScenarioRuleMakerCheckerId      
      
 SELECT  makerChecker.CoreAmlScenarioRuleMakerCheckerId      
   ,makerChecker.RuleNumber      
   ,makerChecker.RefAmlReportId      
   ,makerChecker.SysAmlReportSettingId      
   ,makerChecker.RefAmlScenarioRuleId_NoFK      
   ,makerChecker.PropertyName      
   ,makerChecker.OldValue      
   ,makerChecker.NewValue      
   ,actionEnumValue.Code AS ActionCode      
   ,makerChecker.AddedBy      
   ,makerChecker.AddedOn      
 INTO #MakerCheckerData      
 FROM dbo.CoreAmlScenarioRuleMakerChecker makerChecker      
 INNER JOIN dbo.RefEnumValue actionEnumValue ON actionEnumValue.RefEnumValueId = makerChecker.ActionRefEnumValueId      
 WHERE makerChecker.CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId      
      
 DECLARE @IsUpdateSysAmlReportSetting BIT      
 SELECT @IsUpdateSysAmlReportSetting = CASE WHEN SysAmlReportSettingId IS NULL THEN 0 ELSE 1 END       
 FROM #MakerCheckerData       
 WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId      
      
 IF @IsUpdateSysAmlReportSetting = 1 ------Moving approved values to sysamlreportsetting      
 BEGIN      
  --EXEC dbo.PrintCurrentTime 'Starting to update SysAmlReportSetting at '      
      
  UPDATE amlReportSetting      
  SET amlReportSetting.Value = makerCheckerData.NewValue      
   ,amlReportSetting.LastEditedBy = makerCheckerData.AddedBy      
   ,amlReportSetting.EditedOn = GETDATE()      
  FROM dbo.SysAmlReportSetting amlReportSetting      
  INNER JOIN #MakerCheckerData makerCheckerData ON makerCheckerData.SysAmlReportSettingId = amlReportSetting.SysAmlReportSettingId      
      
  --EXEC dbo.PrintCurrentTime 'Ending to update SysAmlReportSetting at '      
 END;      
      
 ELSE ------Moving approved values to RefAmlScenarioRule      
 BEGIN      
        
  DECLARE @NewThresholdValue DECIMAL(28,2),@NewThreshold2Value DECIMAL(28,2)      
    ,@NewThreshold3Value DECIMAL(28,2),@NewThreshold4Value DECIMAL(28,2),@NewThreshold6Value VARCHAR(500) ,@NewIsBuyValue BIT,@NewInitialAmountValue DECIMAL(19,6)      
    ,@NewNonInitialAmountValue DECIMAL(19,6),@NewVoucherTypeValue INT      
    ,@OldClientStatusValue VARCHAR(MAX),@NewClientStatusValue VARCHAR(MAX)      
    ,@OldConstitutionTypeValue VARCHAR(MAX),@NewConstitutionTypeValue VARCHAR(MAX)      
    ,@OldAmlGsmStagesValue VARCHAR(MAX),@NewAmlGsmStagesValue VARCHAR(MAX)      
    ,@OldInstrumentTypeValue VARCHAR(MAX),@NewInstrumentTypeValue VARCHAR(MAX)      
    ,@OldScripGroupValue VARCHAR(MAX),@NewScripGroupValue VARCHAR(MAX)      
    ,@OldRiskCategoryValue VARCHAR(MAX),@NewRiskCategoryValue VARCHAR(MAX)      
      
  DECLARE @ActionCode VARCHAR(2000),@AmlScenarioRuleId INT,@AddedBy VARCHAR(100),@AddedOn DATETIME;      
  SELECT  @ActionCode = ActionCode       
    ,@AmlScenarioRuleId = RefAmlScenarioRuleId_NoFK      
    ,@AddedBy = AddedBy      
    ,@AddedOn = AddedOn      
  FROM #MakerCheckerData       
  WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
      
  IF @ActionCode = 'I' -----Adding new record in RefAmlScenarioRule      
  BEGIN      
      
   DECLARE @RuleNumber INT,@AmlReportId INT      
   SELECT  @RuleNumber = RuleNumber       
     ,@AmlReportId = RefAmlReportId      
   FROM #MakerCheckerData       
   WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
      
   IF NOT EXISTS(SELECT 1 FROM dbo.RefAmlScenarioRule WHERE RuleNumber = @RuleNumber)      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to insert new data in RefAmlScenarioRule at '      
      
    INSERT INTO #MakerCheckerData      
    SELECT  makerChecker.CoreAmlScenarioRuleMakerCheckerId      
      ,makerChecker.RuleNumber      
      ,makerChecker.RefAmlReportId      
      ,makerChecker.SysAmlReportSettingId      
      ,makerChecker.RefAmlScenarioRuleId_NoFK      
      ,makerChecker.PropertyName      
      ,makerChecker.OldValue      
      ,makerChecker.NewValue      
      ,actionEnumValue.Code AS ActionCode      
      ,makerChecker.AddedBy      
      ,makerChecker.AddedOn      
    FROM dbo.CoreAmlScenarioRuleMakerChecker makerChecker      
    INNER JOIN dbo.RefEnumValue actionEnumValue ON actionEnumValue.RefEnumValueId = makerChecker.ActionRefEnumValueId      
    WHERE makerChecker.RuleNumber = @RuleNumber        
    AND makerChecker.CoreAmlScenarioRuleMakerCheckerId <> @InternalAmlScenarioRuleMakerCheckerId      
      
    SELECT @NewThresholdValue = CONVERT(DECIMAL(28,2),NewValue) FROM #MakerCheckerData WHERE PropertyName = 'Threshold';      
    SELECT @NewThreshold2Value = CONVERT(DECIMAL(28,2),NewValue) FROM #MakerCheckerData WHERE PropertyName = 'Threshold2';      
    SELECT @NewThreshold3Value = CONVERT(DECIMAL(28,2),NewValue) FROM #MakerCheckerData WHERE PropertyName = 'Threshold3';     
    SELECT @NewThreshold4Value = CONVERT(DECIMAL(28,2),NewValue) FROM #MakerCheckerData WHERE PropertyName = 'Threshold4';      
    SELECT @NewThreshold6Value = NewValue FROM #MakerCheckerData WHERE PropertyName = 'Threshold6';
	SELECT @NewIsBuyValue = CASE WHEN CONVERT(INT,NewValue) = 1 THEN 1 ELSE 0 END FROM #MakerCheckerData WHERE PropertyName = 'IsBuy';      
    SELECT @NewInitialAmountValue = CONVERT(DECIMAL(19,6),NewValue) FROM #MakerCheckerData WHERE PropertyName = 'InitialAmount';      
    SELECT @NewNonInitialAmountValue = CONVERT(DECIMAL(19,6),NewValue) FROM #MakerCheckerData WHERE PropertyName = 'NonInitialAmount';      
    SELECT @NewVoucherTypeValue = CONVERT(INT,NewValue) FROM #MakerCheckerData WHERE PropertyName = 'VoucherType';      
    SELECT @NewClientStatusValue = NewValue FROM #MakerCheckerData WHERE PropertyName = 'ClientStatus';      
    SELECT @NewConstitutionTypeValue = NewValue FROM #MakerCheckerData WHERE PropertyName = 'ConstitutionType';      
    SELECT @NewAmlGsmStagesValue = NewValue FROM #MakerCheckerData WHERE PropertyName = 'AmlGsmStages';      
    SELECT @NewInstrumentTypeValue = NewValue FROM #MakerCheckerData WHERE PropertyName = 'InstrumentType';      
    SELECT @NewScripGroupValue = NewValue FROM #MakerCheckerData WHERE PropertyName = 'ScripGroup';      
    SELECT @NewRiskCategoryValue = NewValue FROM #MakerCheckerData WHERE PropertyName = 'RiskCategory';      
      
    INSERT INTO dbo.RefAmlScenarioRule      
    ( RuleNumber,RefAmlReportId,RefVoucherTypeId,Threshold,Threshold2,Threshold3, Threshold4,Threshold6, IsBuy,InitialAmount,NonInitialAmount,AddedBy,AddedOn,LastEditedBy,EditedOn      
    )      
    VALUES      
    ( @RuleNumber,@AmlReportId,@NewVoucherTypeValue,@NewThresholdValue,@NewThreshold2Value,@NewThreshold3Value,@NewThreshold4Value,@NewThreshold6Value,@NewIsBuyValue,@NewInitialAmountValue,@NewNonInitialAmountValue      
     ,@AddedBy,GETDATE(),@AddedBy,GETDATE()      
    );      
         
    SELECT @AmlScenarioRuleId = SCOPE_IDENTITY();      
      
    IF @NewClientStatusValue IS NOT NULL      
    BEGIN      
     --EXEC dbo.PrintCurrentTime 'Starting to insert data in ClientStatusLink at '      
      
     IF NOT EXISTS(      
      SELECT 1      
      FROM dbo.LinkRefAmlScenarioRuleRefClientStatus link      
      INNER JOIN dbo.RefAmlScenarioRule rul ON rul.RefAmlScenarioRuleId = link.RefAmlScenarioRuleId      
      INNER JOIN dbo.RefAmlReport rep ON rep.RefAmlReportId = rul.RefAmlReportId      
      LEFT JOIN dbo.RefVoucherType voucherType ON voucherType.RefVoucherTypeId = rul.RefVoucherTypeId      
      LEFT JOIN dbo.ParseString(@NewClientStatusValue,',') newClientStatus ON convert(int,newClientStatus.s) = link.RefClientStatusId      
      LEFT JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup oldScripGroup ON oldScripGroup.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId      
      LEFT JOIN dbo.ParseString(@NewScripGroupValue,',') newScripGroupValue ON convert(int,newScripGroupValue.s) = oldScripGroup.RefScripGroupId      
      WHERE rep.RefAmlReportId = @AmlReportId            AND (voucherType.RefVoucherTypeId IS NULL OR voucherType.RefVoucherTypeId = @NewVoucherTypeValue)      
      AND (rul.IsBuy IS NULL OR rul.IsBuy = @NewIsBuyValue)      
      AND (@NewClientStatusValue IS NULL OR newClientStatus.s IS NOT NULL)      
     AND (@NewScripGroupValue IS NULL OR newScripGroupValue.s IS NOT NULL)      
            
     )      
     BEGIN      
      EXEC dbo.LinkRefAmlScenarioRuleRefClientStatus_Insert @AmlScenarioRuleId = @AmlScenarioRuleId,@OldValue = NULL,@NewValue = @NewClientStatusValue,@AddedBy = @AddedBy      
     END;      
     ELSE      
     BEGIN      
      RAISERROR('There is already rule defined for same Scenario / ClientStatus',11,1) WITH SETERROR      
RETURN 50010     
     END;      
      
     --EXEC dbo.PrintCurrentTime 'Ending to insert data in ClientStatusLink at '      
    END      
      
    IF @NewConstitutionTypeValue IS NOT NULL      
    BEGIN      
     --EXEC dbo.PrintCurrentTime 'Starting to insert data in ConstitutionTypeLink at '      
      
     IF NOT EXISTS(      
      SELECT 1      
      FROM dbo.LinkRefAmlScenarioRuleRefConstitutionType link      
      INNER JOIN dbo.RefAmlScenarioRule rul ON rul.RefAmlScenarioRuleId = link.RefAmlScenarioRuleId      
      LEFT JOIN dbo.RefVoucherType voucherType ON voucherType.RefVoucherTypeId = rul.RefVoucherTypeId      
      INNER JOIN dbo.RefAmlReport rep ON rep.RefAmlReportId = rul.RefAmlReportId      
      INNER JOIN dbo.ParseString(@NewConstitutionTypeValue,',') s ON convert(int,s.s) = link.RefConstitutionTypeId      
      WHERE rep.RefAmlReportId = @AmlReportId      
      AND (voucherType.RefVoucherTypeId IS NULL OR voucherType.RefVoucherTypeId = @NewVoucherTypeValue)      
      AND (rul.IsBuy IS NULL OR rul.IsBuy = @NewIsBuyValue)      
     )      
     BEGIN      
      EXEC dbo.LinkRefAmlScenarioRuleRefConstitutionType_Insert @AmlScenarioRuleId = @AmlScenarioRuleId,@OldValue = NULL,@NewValue = @NewConstitutionTypeValue,@AddedBy = @AddedBy      
     END      
     ELSE      
     BEGIN      
      RAISERROR('There is already rule defined for same Scenario / ConstitutionType',11,1) WITH SETERROR      
RETURN 50010     
     END;      
      
     --EXEC dbo.PrintCurrentTime 'Ending to insert data in ConstitutionTypeLink at '      
    END      
      
    IF @NewAmlGsmStagesValue IS NOT NULL      
    BEGIN      
     --EXEC dbo.PrintCurrentTime 'Starting to insert data in AmlGsmStagesLink at '      
      
     IF NOT EXISTS(      
      SELECT 1      
      FROM dbo.LinkRefAmlScenarioRuleRefGsm link      
      INNER JOIN dbo.RefAmlScenarioRule rul ON rul.RefAmlScenarioRuleId = link.RefAmlScenarioRuleId      
      LEFT JOIN dbo.RefVoucherType voucherType ON voucherType.RefVoucherTypeId = rul.RefVoucherTypeId      
      INNER JOIN dbo.RefAmlReport rep ON rep.RefAmlReportId = rul.RefAmlReportId      
      INNER JOIN dbo.ParseString(@NewAmlGsmStagesValue,',') s ON convert(int,s.s) = link.RefGSMId      
      WHERE rep.RefAmlReportId = @AmlReportId      
      AND (voucherType.RefVoucherTypeId IS NULL OR voucherType.RefVoucherTypeId = @NewVoucherTypeValue)      
      AND (rul.IsBuy IS NULL OR rul.IsBuy = @NewIsBuyValue)      
     )      
     BEGIN      
      EXEC dbo.LinkRefAmlScenarioRuleRefGsm_Insert @AmlScenarioRuleId = @AmlScenarioRuleId,@OldValue = NULL,@NewValue = @NewAmlGsmStagesValue,@AddedBy = @AddedBy      
     END      
     ELSE      
     BEGIN      
      RAISERROR('There is already rule defined for same Scenario / AmlGsmStages',11,1) WITH SETERROR      
RETURN 50010     
     END;      
      
     --EXEC dbo.PrintCurrentTime 'Ending to insert data in AmlGsmStagesLink at '      
    END      
      
    IF @NewInstrumentTypeValue IS NOT NULL      
    BEGIN      
     --EXEC dbo.PrintCurrentTime 'Starting to insert data in InstrumentTypeLink at '      
      
     IF NOT EXISTS(      
      SELECT 1      
      FROM dbo.LinkRefAmlScenarioRuleRefInstrumentType link      
      INNER JOIN dbo.RefAmlScenarioRule rul ON rul.RefAmlScenarioRuleId = link.RefAmlScenarioRuleId       
      INNER JOIN dbo.RefAmlReport rep ON rep.RefAmlReportId = rul.RefAmlReportId      
      INNER JOIN dbo.ParseString(@NewInstrumentTypeValue,',') s ON convert(int,s.s) = link.RefInstrumentTypeId      
   LEFT JOIN dbo.RefVoucherType voucherType ON voucherType.RefVoucherTypeId = rul.RefVoucherTypeId     
   LEFT JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus lnkClientStatus ON lnkClientStatus.RefAmlScenarioRuleId=rul.RefAmlScenarioRuleId    
      WHERE rep.RefAmlReportId = @AmlReportId      
      AND (voucherType.RefVoucherTypeId IS NULL OR voucherType.RefVoucherTypeId = @NewVoucherTypeValue)      
      AND (rul.IsBuy IS NULL OR rul.IsBuy = @NewIsBuyValue)      
   AND (lnkClientStatus.RefClientStatusId IS NULL OR lnkClientStatus.RefClientStatusId=@NewClientStatusValue)    
     )      
     BEGIN      
      EXEC dbo.LinkRefAmlScenarioRuleRefInstrumentType_Insert @AmlScenarioRuleId = @AmlScenarioRuleId,@OldValue = NULL,@NewValue = @NewInstrumentTypeValue,@AddedBy = @AddedBy      
     END      
     ELSE      
     BEGIN      
      RAISERROR('There is already rule defined for same Scenario / InstrumentType',11,1) WITH SETERROR      
RETURN 50010     
     END;      
      
     --EXEC dbo.PrintCurrentTime 'Ending to insert data in InstrumentTypeLink at '      
    END      
      
    IF @NewScripGroupValue IS NOT NULL      
    BEGIN      
     --EXEC dbo.PrintCurrentTime 'Starting to insert data in ScripGroupLink at '      
      
     IF NOT EXISTS(      
      SELECT 1      
      FROM dbo.LinkRefAmlScenarioRuleRefScripGroup link      
      INNER JOIN dbo.RefAmlScenarioRule rul ON rul.RefAmlScenarioRuleId = link.RefAmlScenarioRuleId      
      INNER JOIN dbo.RefAmlReport rep ON rep.RefAmlReportId = rul.RefAmlReportId      
      LEFT JOIN dbo.RefVoucherType voucherType ON voucherType.RefVoucherTypeId = rul.RefVoucherTypeId      
      LEFT JOIN dbo.ParseString(@NewScripGroupValue,',') newScripGroup ON convert(int,newScripGroup.s) = link.RefScripGroupId      
      LEFT JOIN dbo.LinkRefAmlScenarioRuleRefClientStatus oldClientStatus ON oldClientStatus.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId      
      LEFT JOIN dbo.ParseString(@NewClientStatusValue,',') newClientStatus ON convert(int,newClientStatus.s) = oldClientStatus.RefClientStatusId      
      WHERE rep.RefAmlReportId = @AmlReportId      
      AND (voucherType.RefVoucherTypeId IS NULL OR voucherType.RefVoucherTypeId = @NewVoucherTypeValue)      
      AND (rul.IsBuy IS NULL OR rul.IsBuy = @NewIsBuyValue)      
      AND (@NewScripGroupValue IS NULL OR newScripGroup.s IS NOT NULL)      
      AND (@NewClientStatusValue IS NULL OR newClientStatus.s IS NOT NULL)      
     )      
     BEGIN      
      EXEC dbo.LinkRefAmlScenarioRuleRefScripGroup_Insert @AmlScenarioRuleId = @AmlScenarioRuleId,@OldValue = NULL,@NewValue = @NewScripGroupValue,@AddedBy = @AddedBy      
     END      
     ELSE      
     BEGIN      
      RAISERROR('There is already rule defined for same Scenario / ScripGroup',11,1) WITH SETERROR      
RETURN 50010     
     END;      
      
     --EXEC dbo.PrintCurrentTime 'Ending to insert data in ScripGroupLink at '      
    END      
      
    IF @NewRiskCategoryValue IS NOT NULL      
    BEGIN      
     --EXEC dbo.PrintCurrentTime 'Starting to insert data in RiskCategoryLink at '      
      
     IF NOT EXISTS(      
      SELECT 1      
      FROM dbo.LinkRefAmlScenarioRuleRefRiskCategory link      
      INNER JOIN dbo.RefAmlScenarioRule rul ON rul.RefAmlScenarioRuleId = link.RefAmlScenarioRuleId      
      LEFT JOIN dbo.RefVoucherType voucherType ON voucherType.RefVoucherTypeId = rul.RefVoucherTypeId      
      INNER JOIN dbo.RefAmlReport rep ON rep.RefAmlReportId = rul.RefAmlReportId      
      INNER JOIN dbo.ParseString(@NewRiskCategoryValue,',') s ON convert(int,s.s) = link.RefRiskCategoryId      
      WHERE rep.RefAmlReportId = @AmlReportId      
      AND (voucherType.RefVoucherTypeId IS NULL OR voucherType.RefVoucherTypeId = @NewVoucherTypeValue)      
  AND (rul.IsBuy IS NULL OR rul.IsBuy = @NewIsBuyValue)      
     )      
     BEGIN      
      EXEC dbo.LinkRefAmlScenarioRuleRefRiskCategory_Insert @AmlScenarioRuleId = @AmlScenarioRuleId,@OldValue = NULL,@NewValue = @NewRiskCategoryValue,@AddedBy = @AddedBy      
     END      
     ELSE      
     BEGIN      
      RAISERROR('There is already rule defined for same Scenario / RiskCategory',11,1) WITH SETERROR      
RETURN 50010     
     END;      
      
     --EXEC dbo.PrintCurrentTime 'Ending to insert data in RiskCategoryLink at '      
    END      
      
    --EXEC dbo.PrintCurrentTime 'Ending to insert new data in RefAmlScenarioRule at '      
   END;      
         
  END;      
      
  ELSE IF @ActionCode = 'M' ----------updating record in RefAmlScenarioRule      
  BEGIN      
      
   DECLARE @PropertyName VARCHAR(200);      
   SELECT @PropertyName = PropertyName FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
      
   IF @PropertyName = 'Threshold'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update field Threshold in RefAmlScenarioRule at '      
      
    SELECT @NewThresholdValue = CONVERT(DECIMAL(28,2),NewValue) FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
    UPDATE dbo.RefAmlScenarioRule SET Threshold = @NewThresholdValue,LastEditedBy = @AddedBy,EditedOn = GETDATE() WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update field Threshold in RefAmlScenarioRule at '      
   END      
   ELSE IF @PropertyName = 'Threshold2'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update field Threshold2 in RefAmlScenarioRule at '      
      
    SELECT @NewThreshold2Value = CONVERT(DECIMAL(28,2),NewValue) FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
    UPDATE dbo.RefAmlScenarioRule SET Threshold2 = @NewThreshold2Value,LastEditedBy = @AddedBy,EditedOn = GETDATE() WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update field Threshold2 in RefAmlScenarioRule at '      
   END      
   ELSE IF @PropertyName = 'Threshold3'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update field Threshold3 in RefAmlScenarioRule at '      
      
    SELECT @NewThreshold3Value = CONVERT(DECIMAL(28,2),NewValue) FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
    UPDATE dbo.RefAmlScenarioRule SET Threshold3 = @NewThreshold3Value,LastEditedBy = @AddedBy,EditedOn = GETDATE() WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update field Threshold3 in RefAmlScenarioRule at '      
   END      
    ELSE IF @PropertyName = 'Threshold4'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update field Threshold3 in RefAmlScenarioRule at '      
      
    SELECT @NewThreshold4Value = CONVERT(DECIMAL(28,2),NewValue) FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
    UPDATE dbo.RefAmlScenarioRule SET Threshold4 = @NewThreshold4Value,LastEditedBy = @AddedBy,EditedOn = GETDATE() WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update field Threshold3 in RefAmlScenarioRule at '      
   END     
   ELSE IF @PropertyName = 'Threshold6'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update field Threshold3 in RefAmlScenarioRule at '      
      
    SELECT @NewThreshold6Value = NewValue FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
    UPDATE dbo.RefAmlScenarioRule SET Threshold6 = @NewThreshold6Value,LastEditedBy = @AddedBy,EditedOn = GETDATE() WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update field Threshold3 in RefAmlScenarioRule at '      
   END
   ELSE IF @PropertyName = 'IsBuy'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update field IsBuy in RefAmlScenarioRule at '      
      
    SELECT @NewIsBuyValue = CASE WHEN CONVERT(INT,NewValue) = 1 THEN 1 ELSE 0 END FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
    UPDATE dbo.RefAmlScenarioRule SET IsBuy = @NewIsBuyValue,LastEditedBy = @AddedBy,EditedOn = GETDATE() WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId      
      
   --EXEC dbo.PrintCurrentTime 'Ending to update field IsBuy in RefAmlScenarioRule at '      
   END      
   ELSE IF @PropertyName = 'InitialAmount'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update field InitialAmount in RefAmlScenarioRule at '      
      
    SELECT @NewInitialAmountValue = CONVERT(DECIMAL(19,6),NewValue) FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
    UPDATE dbo.RefAmlScenarioRule SET InitialAmount = @NewInitialAmountValue,LastEditedBy = @AddedBy,EditedOn = GETDATE() WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update field InitialAmount in RefAmlScenarioRule at '      
   END      
   ELSE IF @PropertyName = 'NonInitialAmount'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update field NonInitialAmount in RefAmlScenarioRule at '      
      
    SELECT @NewNonInitialAmountValue = CONVERT(DECIMAL(19,6),NewValue) FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
    UPDATE dbo.RefAmlScenarioRule SET InitialAmount = @NewInitialAmountValue,LastEditedBy = @AddedBy,EditedOn = GETDATE() WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update field NonInitialAmount in RefAmlScenarioRule at '      
   END      
   ELSE IF @PropertyName = 'VoucherType'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update field VoucherType in RefAmlScenarioRule at '      
      
    SELECT @NewVoucherTypeValue = CONVERT(INT,NewValue) FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
    UPDATE dbo.RefAmlScenarioRule SET RefVoucherTypeId = @NewVoucherTypeValue,LastEditedBy = @AddedBy,EditedOn = GETDATE() WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update field VoucherType in RefAmlScenarioRule at '      
   END      
   ELSE IF @PropertyName = 'ClientStatus'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update ClientStatusLink Data at '      
      
    SELECT @OldClientStatusValue = OldValue,@NewClientStatusValue = NewValue       
    FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
      
    EXEC dbo.LinkRefAmlScenarioRuleRefClientStatus_Insert @AmlScenarioRuleId = @AmlScenarioRuleId,@OldValue = @OldClientStatusValue      
       ,@NewValue = @NewClientStatusValue,@AddedBy = @AddedBy      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update ClientStatusLink Data at '      
   END      
   ELSE IF @PropertyName = 'ConstitutionType'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update ConstitutionTypeLink Data at '      
      
    SELECT @OldConstitutionTypeValue = OldValue,@NewConstitutionTypeValue = NewValue       
    FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
      
    EXEC dbo.LinkRefAmlScenarioRuleRefConstitutionType_Insert @AmlScenarioRuleId = @AmlScenarioRuleId      
       ,@OldValue = @OldConstitutionTypeValue,@NewValue = @NewConstitutionTypeValue,@AddedBy = @AddedBy      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update ConstitutionTypeLink Data at '      
   END      
   ELSE IF @PropertyName = 'AmlGsmStages'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update AmlGsmStagesLink Data at '      
      
    SELECT @OldAmlGsmStagesValue = OldValue,@NewAmlGsmStagesValue = NewValue FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
      
    EXEC dbo.LinkRefAmlScenarioRuleRefGsm_Insert @AmlScenarioRuleId = @AmlScenarioRuleId,@OldValue = @OldAmlGsmStagesValue,@NewValue = @NewAmlGsmStagesValue,@AddedBy = @AddedBy      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update AmlGsmStagesLink Data at '      
END      
   ELSE IF @PropertyName = 'InstrumentType'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update InstrumentTypeLink Data at '      
      
    SELECT @OldInstrumentTypeValue = OldValue,@NewInstrumentTypeValue = NewValue       
    FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
          
    EXEC dbo.LinkRefAmlScenarioRuleRefInstrumentType_Insert @AmlScenarioRuleId = @AmlScenarioRuleId,@OldValue = @OldInstrumentTypeValue      
        ,@NewValue = @NewInstrumentTypeValue,@AddedBy = @AddedBy      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update InstrumentTypeLink Data at '      
   END      
   ELSE IF @PropertyName = 'ScripGroup'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update ScripGroupLink Data at '      
      
    SELECT @OldScripGroupValue = OldValue,@NewScripGroupValue = NewValue       
    FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
          
    EXEC dbo.LinkRefAmlScenarioRuleRefScripGroup_Insert @AmlScenarioRuleId = @AmlScenarioRuleId,@OldValue = @OldScripGroupValue      
        ,@NewValue = @NewScripGroupValue,@AddedBy = @AddedBy      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update ScripGroupLink Data at '      
   END      
   ELSE IF @PropertyName = 'RiskCategory'      
   BEGIN      
    --EXEC dbo.PrintCurrentTime 'Starting to update RiskCategoryLink Data at '      
      
    SELECT @OldRiskCategoryValue = OldValue,@NewRiskCategoryValue = NewValue       
    FROM #MakerCheckerData WHERE CoreAmlScenarioRuleMakerCheckerId = @InternalAmlScenarioRuleMakerCheckerId;      
      
    EXEC dbo.LinkRefAmlScenarioRuleRefRiskCategory_Insert @AmlScenarioRuleId = @AmlScenarioRuleId,@OldValue = @OldRiskCategoryValue      
        ,@NewValue = @NewRiskCategoryValue,@AddedBy = @AddedBy      
      
    --EXEC dbo.PrintCurrentTime 'Ending to update RiskCategoryLink Data at '      
   END      
      
  END;      
      
  ELSE IF @ActionCode = 'D' -----Deleting record from RefAmlScenarioRule      
  BEGIN      
   --EXEC dbo.PrintCurrentTime 'Starting to delete data from RefAmlScenarioRule at '      
      
   DELETE dbo.LinkRefAmlScenarioRuleRefClientStatus WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId;      
   DELETE dbo.LinkRefAmlScenarioRuleRefConstitutionType WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId;      
   DELETE dbo.LinkRefAmlScenarioRuleRefGsm WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId;      
   DELETE dbo.LinkRefAmlScenarioRuleRefInstrumentType WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId;      
   DELETE dbo.LinkRefAmlScenarioRuleRefRiskCategory WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId;      
   DELETE dbo.LinkRefAmlScenarioRuleRefScripGroup WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId;      
      
   DELETE dbo.RefAmlScenarioRule WHERE RefAmlScenarioRuleId = @AmlScenarioRuleId;      
      
   --EXEC dbo.PrintCurrentTime 'Ending to delete data from RefAmlScenarioRule at '      
  END;      
      
 END;      
      
END      
GO
------WEB-64402 RC END---
------WEB-64402 RC START----
GO
ALTER PROCEDURE [dbo].[CoreAmlScenarioRuleMakerChecker_Search]  
(  
 @EntityTypeCode VARCHAR(200),  
 @WorkflowRequest BIT = 0 ,  
 @EmployeeId INT ,  
 @WorkflowStepId INT = NULL,  
 @PageNo INT = 1,  
 @RowsPerPage INT = 25   
)  
as  
begin  
  
 DECLARE @RefEntityTypeId int,@InternalEmployeeId INT,@InternalWorkflowStepId INT,@InternalWorkflowRequest INT,@InternalPageNumber INT,@InternalRowsPerPage INT  
 DECLARE @InternalEntityTypeCode VARCHAR(200)  
 SET @InternalEntityTypeCode = @EntityTypeCode  
 SET @InternalWorkflowStepId = @WorkflowStepId  
 SET @InternalWorkflowRequest = @WorkflowRequest  
  
 SET @InternalPageNumber = @PageNo  
 SET @InternalRowsPerPage = @RowsPerPage  
  
 select @RefEntityTypeId = dbo.GetEntityTypeByCode(@InternalEntityTypeCode)  
 SET @InternalEmployeeId = @EmployeeId  
  
 create Table #ValuesNames(  
 ValueName varchar(200) collate DATABASE_DEFAULT,  
 PropertyName varchar(200) collate DATABASE_DEFAULT,  
 ActionName varchar(200) collate DATABASE_DEFAULT,  
 RuleNumber int,  
 CoreAmlScenarioRuleMakerCheckerId int,  
 NameValues varchar(max) collate DATABASE_DEFAULT  
 )  
  
  
 insert into #ValuesNames  
 exec dbo.GetValuesNamesForConstitutionType  
  
 insert into #ValuesNames  
 exec dbo.GetValuesNamesForInsturmentType  
  
 insert into #ValuesNames  
 exec dbo.GetValuesNamesForScripGroup  
  
 insert into #ValuesNames  
 exec dbo.GetValuesNamesForClientStatus  
  
 insert into #ValuesNames  
 exec dbo.GetValuesNamesForAmlGsmStages  
  
  CREATE TABLE #RuleWritingMakerCheckerId(      
        CoreAmlScenarioRuleMakerCheckerId BIGINT,      
  RefWorkflowStepId INT,      
        CoreWorkflowProgressId BIGINT,      
        WorkflowProgressAddedOn DATETIME ,  
  CheckerName VARCHAR(100) COLLATE DATABASE_DEFAULT,  
  CheckerDate DATETIME);    
  
 INSERT  INTO #RuleWritingMakerCheckerId      
    EXEC dbo.CoreAmlScenarioRuleMakerChecker_GetIds @InternalWorkflowRequest, @InternalEmployeeId, @InternalWorkflowStepId,@RefEntityTypeId  
  
 select   
  makerchecker.CoreAmlScenarioRuleMakerCheckerId,  
  case   
   when makerchecker.RuleNumber=0   
    then 'T '+ CONVERT(varchar(10),makerchecker.SysAmlReportSettingId)   
   else   
    CONVERT(varchar(10),makerchecker.RuleNumber)   
   end as RuleNo,  
  report.Name as Scenario,  
  case   
   when makerchecker.RuleNumber=0   
    then reportsetting.DisplayName    
   when makerchecker.PropertyName='Threshold'   
    then report.Threshold1DisplayName   
   when makerchecker.PropertyName='Threshold2'   
    then report.Threshold2DisplayName   
   when makerchecker.PropertyName='Threshold3'   
    then report.Threshold3DisplayName
   when makerchecker.PropertyName='Threshold4'   
    then report.Threshold4DisplayName
	when makerchecker.PropertyName='Threshold6'   
    then report.Threshold6DisplayName
   else  
   makerchecker.PropertyName   
  end as PropertyName,  
  actionvalue.Name as [Action],  
  case   
   when makerchecker.PropertyName='VoucherType'   
    then voucherTypeOld.Name   
   when valuename.ValueName='OldValue'   
    then valuename.NameValues  
   when makerchecker.PropertyName='CustomRisk'   
    then oldCustomRisk.Name   
   when makerchecker.PropertyName='AlertTag'   
    then oldAlertTageValue.Name   
   else   
    makerchecker.OldValue   
  end as OldValue,  
  case  
   when makerchecker.PropertyName='VoucherType'   
    then voucherTypeNew.Name   
   when makerchecker.PropertyName='CustomRisk'   
    then newCustomRisk.Name   
   when makerchecker.PropertyName='AlertTag'   
    then newAlertTageValue.Name   
   when valuenameNew.ValueName='NewValue'   
    then valuenameNew.NameValues  
   else   
    makerchecker.NewValue   
  end as NewValue,  
  progress.Notes,  
  temp.CheckerName AS LastEditedBy,  
  ws.Name AS WorkFlowStatus,  
  temp.CheckerDate as EditedOn,  
  makerchecker.AddedBy as MakerName,  
  makerchecker.AddedOn as [Date],  
  ws.RefWorkflowStepId AS WorkflowStepId,  
  ROW_NUMBER() OVER ( ORDER BY progress.EditedOn DESC ) AS RowNumber  
  INTO #temp  
 from #RuleWritingMakerCheckerId temp   
 INNER JOIN dbo.CoreAmlScenarioRuleMakerChecker makerchecker ON makerchecker.CoreAmlScenarioRuleMakerCheckerId = temp.CoreAmlScenarioRuleMakerCheckerId  
 inner join CoreWorkflowProgress progress on progress.CoreWorkflowProgressId = temp.CoreWorkflowProgressId  
 inner join dbo.RefAmlReport report on report.RefAmlReportId=makerchecker.RefAmlReportId  
 INNER JOIN dbo.RefWorkflowStep ws ON progress.RefWorkflowStepId = ws.RefWorkflowStepId  
 INNER JOIN dbo.RefWorkflowStepCategory category ON ws.RefWorkflowStepCategoryId = category.RefWorkflowStepCategoryId  
 left join dbo.RefVoucherType voucherTypeOld on CONVERT(varchar(10),voucherTypeOld.RefVoucherTypeId)=makerchecker.OldValue   
 left join dbo.RefVoucherType voucherTypeNew on CONVERT(varchar(10),voucherTypeNew.RefVoucherTypeId)=makerchecker.NewValue  
 LEFT JOIN dbo.RefCustomRisk oldCustomRisk ON CONVERT(varchar(10),oldCustomRisk.RefCustomRiskId)=makerchecker.OldValue   
 LEFT JOIN dbo.RefCustomRisk newCustomRisk ON CONVERT(varchar(10),newCustomRisk.RefCustomRiskId)=makerchecker.NewValue   
 left join dbo.SysAmlReportSetting reportsetting on reportsetting.SysAmlReportSettingId=makerchecker.SysAmlReportSettingId  
 LEFT JOIN dbo.RefEnumValue oldAlertTageValue on CONVERT(varchar(10),oldAlertTageValue.RefEnumValueId)  = makerchecker.OldValue  
 LEFT JOIN dbo.RefEnumValue newAlertTageValue on CONVERT(varchar(10),newAlertTageValue.RefEnumValueId)  = makerchecker.NewValue  
 inner join dbo.RefEnumValue actionvalue on actionvalue.RefEnumValueId=makerchecker.ActionRefEnumValueId  
 left join #ValuesNames valuename on valuename.CoreAmlScenarioRuleMakerCheckerId=makerchecker.CoreAmlScenarioRuleMakerCheckerId  
 and valuename.PropertyName=makerchecker.PropertyName and valuename.ActionName=actionvalue.Name and valuename.RuleNumber=makerchecker.RuleNumber and valuename.ValueName='OldValue'  
 left join #ValuesNames valuenameNew on valuenameNew.CoreAmlScenarioRuleMakerCheckerId=makerchecker.CoreAmlScenarioRuleMakerCheckerId  
 and valuenameNew.PropertyName=makerchecker.PropertyName and valuenameNew.ActionName=actionvalue.Name and valuenameNew.RuleNumber=makerchecker.RuleNumber and valuenameNew.ValueName='NewValue'  
 where (@InternalWorkflowRequest=1 AND  category.Name <> 'Completed' AND category.Name <> 'Closed') OR @InternalWorkflowRequest = 0  
 order by makerchecker.RuleNumber  
  
 SELECT   
  t.CoreAmlScenarioRuleMakerCheckerId,  
  t.RuleNo,  
  t.Scenario,  
  t.PropertyName,  
  t.[Action],  
  t.OldValue,  
  t.NewValue,  
  t.MakerName,  
  t.[Date],  
  t.WorkflowStepId,  
  t.WorkFlowStatus,  
  t.Notes,  
  t.LastEditedBy,  
  t.EditedOn  
  from #temp t WHERE t.RowNumber BETWEEN   
  (((@InternalPageNumber - 1)* @InternalRowsPerPage ) + 1) AND @InternalPageNumber * @InternalRowsPerPage  
  order by t.[Date] desc;   
  
   SELECT  COUNT(1) as TotalRows  
   FROM    #temp  
  
end  
  
GO
------WEB-64402 RC END---
