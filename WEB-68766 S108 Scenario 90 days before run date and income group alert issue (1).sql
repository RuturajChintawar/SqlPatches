--WEB-68898-RC-START--
GO
ALTER PROCEDURE dbo.AML_GetHighMoneyCumulativeInOutTransactionWithAccOpeningPeriod  
   @StartDate DATETIME ,  
   @EndDate DATETIME,  
   @IsMoneyIn BIT,  
   @Segments varchar(100),  
   @AccountOpeningDate datetime,  
   @ReportId int,  
   @IsIncomeStrengthRequried bit,  
   @IsFairValueRequried bit  
        
AS  
BEGIN  
  DECLARE @StartDateInternal datetime  
  DECLARE @EndDateInternal DATETIME  
  DECLARE @IsMoneyInInternal VARCHAR(50)  
  DECLARE @AccountOpeningDateInternal DATE  
  DECLARE @SegmentsInternal VARCHAR(100)  
  Declare @ReportIdInternal int  
  
  
  
  SET @StartDateInternal = @StartDate  
  SET @EndDateInternal = @EndDate  
  SET @IsMoneyInInternal = @IsMoneyIn  
  SET @AccountOpeningDateInternal = dbo.GetDateWithoutTime(@AccountOpeningDate) 
  SET @SegmentsInternal = @Segments  
  set @ReportIdInternal=@ReportId  
  
  DECLARE @BseCashSegmentId INT  
        SET @BseCashSegmentId = dbo.GetSegmentId('BSE_CASH')  
          
  --voucher type  
        DECLARE @ReceiptOrPayment VARCHAR(10)  
        IF(@IsMoneyIn = 1)  
        SET @ReceiptOrPayment = 'Receipt'  
        ELSE  
        SET @ReceiptOrPayment = 'Payment'  
  
  --segment list  
  SELECT seg.RefSegmentEnumId,seg.Segment  
  INTO #RequiredSegment  
  FROM dbo.RefSegmentEnum seg  
  WHERE seg.Segment IN (SELECT * FROM dbo.Split(@SegmentsInternal,','))  
    
    
        --default networth  
        DECLARE @DefaultNetworth BIGINT  
  SELECT @DefaultNetworth = cliNetSellPoint.DefaultNetworth   
  FROM dbo.RefAmlQueryProfile qp     
    LEFT JOIN dbo.LinkRefAmlQueryProfileRefSegment qpSegment ON qpSegment.RefAmlQueryProfileId = qp.RefAmlQueryProfileId        
    LEFT JOIN dbo.SysAmlClientNetSellPoints cliNetSellPoint ON cliNetSellPoint.LinkRefAmlQueryProfileRefSegmentId = qpSegment.LinkRefAmlQueryProfileRefSegmentId  
    LEFT JOIN #RequiredSegment seg ON seg.RefSegmentEnumId = qpSegment.RefSegmentId  
  WHERE qp.Name = 'Default'   
  
  -- --default income  
  DECLARE @DefaultIncome VARCHAR (5000)  
  SELECT @DefaultIncome = reportSetting.Value  
  FROM dbo.RefAmlQueryProfile qp     
  LEFT JOIN dbo.RefAmlReport amlReport ON amlReport.Name = 'Client Purchase to Income'  
  LEFT JOIN dbo.SysAmlReportSetting reportSetting ON reportSetting.RefAmlQueryProfileId = qp.RefAmlQueryProfileId  
      AND reportSetting.RefAmlReportId = amlReport.RefAmlReportId  
      AND reportSetting.Name = 'Default_Income'  
  WHERE qp.Name = 'Default'  
  
  
  ---default networth and income for institutional client  
  Declare @InstitutionalClientDefaultIncome VARCHAR (5000)  
  Declare @InstitutionalClientDefaultNetworth BIGINT  
  
  select @InstitutionalClientDefaultIncome=value from dbo.SysConfig where Name='Institutional_Client_Default_Income'  
  
  select @InstitutionalClientDefaultNetworth=value from dbo.SysConfig where Name='Institutional_Client_Default_Networth'  
  
  --get clients  
   SELECT DISTINCT RefClientId   
        INTO #clients  
        FROM dbo.CoreFinancialTransaction cft   
    INNER JOIN RefVoucherType vt on cft.RefVoucherTypeId = vt.RefVoucherTypeId  
  WHERE ( vt.Name IN ( @ReceiptOrPayment ) AND cft.TransactionDate BETWEEN @StartDateInternal AND @EndDateInternal )   
    OR ( vt.Name IN ( @ReceiptOrPayment ) AND cft.TransactionDate = @EndDateInternal)  
  
  
  
    ---  
    SELECT t.CoreFinancialTransactionId, 
	t.TransactionDate ,  
        t.RefClientId ,  
        CASE WHEN vt.Name = 'Payment' THEN t.Amount  
          ELSE 0  
        END AS Payment ,  
        CASE WHEN vt.Name = 'Receipt' THEN t.Amount  
          ELSE 0  
        END AS Receipt ,  
        seg.Segment  
        INTO #FinalCoreFinancialTransaction  
      FROM    dbo.CoreFinancialTransaction t  
        INNER JOIN #clients clients ON clients.RefClientId = t.RefClientId  
        INNER JOIN dbo.RefVoucherType vt ON t.RefVoucherTypeId = vt.RefVoucherTypeId  
        INNER JOIN #RequiredSegment seg ON seg.RefSegmentEnumId = t.RefSegmentId  
      WHERE   vt.Name IN ( 'Receipt', 'Payment' )  
        AND dbo.IsDateBetween(t.TransactionDate,  
               @StartDateInternal,  
               @EndDateInternal) = 1  
        AND t.RefSegmentId IS NOT NULL  
      ORDER BY t.TransactionDate ,  
        t.AddedOn               
        --  
  
  
  declare @results varchar(max)  
  
select @results = coalesce(@results + ',', '') +  convert(varchar(12),RefClientId)  
from #clients  
  
create table #TempLinkRefClientRefIncomeGroup(  
LinkRefClientRefIncomeGroupId int,  
RefClientId int,  
RefIncomeGroupId int,  
Income bigint,  
Networth bigint,  
FromDate datetime,  
ToDate datetime,  
AddedBy varchar(50) collate DATABASE_DEFAULT,  
AddedOn datetime,  
LastEditedBy varchar(50) collate DATABASE_DEFAULT,  
EditedOn datetime,  
Notes varchar(5000) collate DATABASE_DEFAULT  
)  
insert into #TempLinkRefClientRefIncomeGroup(  
LinkRefClientRefIncomeGroupId,  
RefClientId,  
RefIncomeGroupId,  
Income,  
Networth,  
FromDate,  
ToDate,  
AddedBy,  
AddedOn,  
LastEditedBy,  
EditedOn,  
Notes)   
execute dbo.LinkRefClientRefIncomeGroup_GetIncomeGroupByGivenDateOrLatest @results,@StartDate,@EndDate  
       
         --get client Income strength  
SELECT   
  cni.RefClientId,  
  client.RefIntermediaryId,  
  (cni.Income) * (client.IncomeMultiplier) AS IncomeStrength  
 INTO #ClientIncomeStrength  
 FROM  
  (SELECT  
     
   COALESCE (clientIncomeGroup.Income, cliIncomeGroupLatest.Income, incomeGroup.IncomeTo, CAST(@DefaultIncome AS BIGINT), 0) AS Income,  
   trade.RefClientId  
   FROM #FinalCoreFinancialTransaction trade   
  
     Left join #TempLinkRefClientRefIncomeGroup templink on templink.RefClientId=trade.RefClientId  
     LEFT JOIN dbo.LinkRefClientRefIncomeGroup clientIncomeGroup on clientIncomeGroup.LinkRefClientRefIncomeGroupId=templink.LinkRefClientRefIncomeGroupId  
     LEFT JOIN dbo.LinkRefClientRefIncomeGroupLatest cliIncomeGroupLatest ON cliIncomeGroupLatest.RefClientId = trade.RefClientId  
     LEFT JOIN dbo.RefIncomeGroup incomeGroup   
     ON incomeGroup.RefIncomeGroupId = ISNULL(clientIncomeGroup.RefIncomeGroupId,cliIncomeGroupLatest.RefIncomeGroupId)    
  )cni  
  INNER JOIN dbo.RefClient client ON (client.RefClientId=cni.RefClientId)  
  
  
SELECT cli.RefClientId,  
    rc.Name AS ClientName,  
    rc.ClientId AS ClientId,      
    --COALESCE (clientIncomeGroup.Networth, cliIncomeGroupLatest.Networth, @DefaultNetworth, 0) AS Networth,  
    case when (clientStatus.Name='Institution' and @InstitutionalClientDefaultNetworth>0)  
    then COALESCE (clientIncomeGroup.Networth, @InstitutionalClientDefaultNetworth, 0)  
    else COALESCE (clientIncomeGroup.Networth, @DefaultNetworth, 0) end AS Networth,  
  
    case when (clientStatus.Name='Institution' and @InstitutionalClientDefaultIncome>0)  
    then COALESCE (clientIncomeGroup.Networth, @InstitutionalClientDefaultIncome, 0)  
    else COALESCE (clientIncomeGroup.Income, incomeGroup.IncomeTo, @DefaultIncome, 0) end AS Income,      
    --COALESCE (clientIncomeGroup.Income, cliIncomeGroupLatest.Income, incomeGroup.IncomeTo, @DefaultIncome, 0) AS Income,      
    --CASE WHEN clientIncomeGroup.Networth IS NULL AND cliIncomeGroupLatest.Networth IS NULL THEN 'Default' ELSE '' END AS NetworthDesc,      
    CASE WHEN clientIncomeGroup.Networth IS NULL  THEN 'Default' ELSE '' END AS NetworthDesc,      
    --CASE WHEN clientIncomeGroup.Income IS NOT NULL OR cliIncomeGroupLatest.Income IS NOT NULL THEN ''  
	CASE WHEN clientIncomeGroup.Income IS NOT NULL  THEN CONVERT(VARCHAR(100),clientIncomeGroup.Income)
      WHEN incomeGroup.IncomeTo IS Not NULL THEN incomeGroup.Name  
      ELSE 'Default' END AS IncomeDesc,      
    ISNULL(rc.IncomeMultiplier, 1) AS IncomeMultiplier,  
    ISNULL(rc.NetworthMultiplier, 1) AS NetworthMultiplier,  
    rc.Email,  
    rc.Mobile,  
    ri.IntermediaryCode,  
    ri.Name AS IntermediaryName,  
    ri.TradeName,  
    riskCategory.Name AS RiskCategory,  
    csc.Name AS CSC,  
    rc.Gender,  
    FLOOR(DATEDIFF(DAY, rc.Dob, GETDATE()) / 365.25) AS Age,  
    rc.RefConstitutionTypeId AS RefConstitutionTypeId,  
    constitution.Name AS ConstitutionName,      
    rc.RefCustomRiskId AS CustomRisk,  
    custRisk.Name AS CustomRiskName,  
    incomeGroup.Name as incomegroup,  
    t.TransactionDate,  
    t.Payment,  
    t.Receipt,
	t.CoreFinancialTransactionId,
	rc.AccountOpeningDate,  
    incomestrength.IncomeStrength,  
    t.segment  
    into #Final  
  FROM #clients cli  
  INNER JOIN dbo.RefClient rc ON rc.RefClientId = cli.RefClientId  
  inner join #FinalCoreFinancialTransaction t on t.RefClientId=cli.RefClientId  
  INNER JOIN dbo.RefClientStatus clientStatus ON rc.RefClientStatusId = clientStatus.RefClientStatusId  
  LEFT JOIN dbo.RefIntermediary ri ON rc.RefIntermediaryId = ri.RefIntermediaryId      
  LEFT JOIN #TempLinkRefClientRefIncomeGroup clientIncomeGroup ON clientIncomeGroup.RefClientId = cli.RefClientId  
  LEFT JOIN dbo.RefIncomeGroup incomeGroup ON incomeGroup.RefIncomeGroupId = clientIncomeGroup.RefIncomeGroupId    
  LEFT JOIN LinkRefClientRefRiskCategoryLatest riskCategoryLatest ON rc.RefClientId = riskCategoryLatest.RefClientId  
  LEFT JOIN RefRiskCategory riskCategory ON riskCategoryLatest.RefRiskCategoryId = riskCategory.RefRiskCategoryId  
  LEFT JOIN RefClientSpecialCategory csc ON rc.RefClientSpecialCategoryId = csc.RefClientSpecialCategoryId  
  LEFT JOIN RefConstitutionType constitution ON rc.RefConstitutionTypeId = constitution.RefConstitutionTypeId  
  LEFT JOIN RefCustomRisk custRisk ON rc.RefCustomRiskId = custRisk.RefCustomRiskId  
  inner join #ClientIncomeStrength incomestrength on cli.RefClientId=incomestrength.RefClientId  
  where dbo.GetDateWithoutTime(rc.AccountOpeningDate) >= @AccountOpeningDateInternal
  
  
select * into #FinalMoneyInOUtData from (select * ,ROW_NUMBER() over(partition by final.RefClientId,  
final.clientName,  
final.ClientId,  
final.AccountOpeningDate,  
final.IncomeStrength,  
final.IncomeMultiplier,  
final.incomeDesc,  
final.Receipt,  
final.Payment,  
final.segment,
final.CoreFinancialTransactionId order by final.RefClientId ) as RowIndex from #Final final)as final3 where final3.RowIndex=1  
  
  
select * from (select  
@StartDateInternal as TransactionFromDate,  
@EndDateInternal as TransactionTodate,   
finalmoneyinout.RefClientId,  
finalmoneyinout.ClientId,  
finalmoneyinout.ClientName,  
finalmoneyinout.IncomeDesc,  
finalmoneyinout.AccountOpeningDate,  
sum(finalmoneyinout.Payment) as MoneyOut,  
sum(finalmoneyinout.Receipt) as MoneyIn,  
case when @IsMoneyIn=0 then sum(finalmoneyinout.Payment)-sum(finalmoneyinout.Receipt) end AS NetMoneyOut,  
case when @IsMoneyIn=1 then sum(finalmoneyinout.Receipt)-sum(finalmoneyinout.Payment) end as NetMoneyIn,  
constitutiontype.RefConstitutionTypeId,  
finalmoneyinout.IncomeMultiplier,  
finalmoneyinout.IncomeStrength,  
finalmoneyinout.Networth,  
finalmoneyinout.NetworthMultiplier,  
(finalmoneyinout.Networth * finalmoneyinout.NetworthMultiplier)+(finalmoneyinout.Income * finalmoneyinout.IncomeMultiplier) as Fairvalue  
--into #MoneyInOutDeatils  
from #FinalMoneyInOUtData finalmoneyinout  
inner join RefConstitutionType constitutiontype on constitutiontype.RefConstitutionTypeId=finalmoneyinout.RefConstitutionTypeId  
    group by finalmoneyinout.RefClientId,finalmoneyinout.ClientId,  
finalmoneyinout.ClientName,  
finalmoneyinout.IncomeDesc,  
finalmoneyinout.Networth,  
finalmoneyinout.NetworthMultiplier,  
finalmoneyinout.Income,  
finalmoneyinout.AccountOpeningDate,constitutiontype.RefConstitutionTypeId,finalmoneyinout.IncomeMultiplier,  
finalmoneyinout.IncomeStrength)as temp  
  
WHERE EXISTS  
    (  
     SELECT 1  
     FROM dbo.RefAmlScenarioRule scenarioRule  
     INNER JOIN dbo.LinkRefAmlScenarioRuleRefConstitutionType linkConstitutionType ON scenarioRule.RefAmlScenarioRuleId = linkConstitutionType.RefAmlScenarioRuleId  
     WHERE scenarioRule.RefAmlReportId = @ReportIdInternal AND  
       temp.RefConstitutionTypeId = linkConstitutionType.RefConstitutionTypeId AND(  
       ((@IsMoneyIn=1 and @IsIncomeStrengthRequried=0 and @IsFairValueRequried=0 and temp.NetMoneyIn>=scenarioRule.Threshold)  
       or(@IsMoneyIn=0 and @IsIncomeStrengthRequried=0 and @IsFairValueRequried=0 and temp.NetMoneyOut>=scenarioRule.Threshold)) OR (@IsMoneyIn=1 and @IsIncomeStrengthRequried=1 and @IsFairValueRequried=0 and temp.NetMoneyIn>=temp.IncomeStrength)   
       Or(@IsMoneyIn=0 and @IsIncomeStrengthRequried=0 and @IsFairValueRequried=1 and temp.NetMoneyOut>=scenarioRule.Threshold and temp.Fairvalue>=scenarioRule.Threshold ))  
           
    )  

END 
GO
--WEB-68898-RC-END--
