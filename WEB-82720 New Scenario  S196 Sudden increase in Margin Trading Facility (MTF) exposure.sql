--File:Tables:dbo:RefAmlReport:DML
--RC-WEB-82720 START
GO
	DECLARE @RefAlertRegisterCaseTypeId INT, @FrequencyFlagRefEnumValueId INT

	SELECT @RefAlertRegisterCaseTypeId = RefAlertRegisterCaseTypeId FROM dbo.RefAlertRegisterCaseType WHERE [Name] = 'AML'
	SELECT @FrequencyFlagRefEnumValueId = dbo.GetEnumValueId('PeriodFrequency', 'Daily')


	SET IDENTITY_INSERT dbo.RefAmlReport ON
	INSERT INTO dbo.RefAmlReport (
		RefAmlReportId,
		[Name],
		AddedBy,
		AddedOn,
		LastEditedBy,
		EditedOn,
		RuleWritingEnabled,
		Code,
		RefAlertRegisterCaseTypeId,
		IsRuleRequired, 
		ClassName,
		IsLicensed,
		FrequencyFlagRefEnumValueId,
		ScenarioNo,
		[Description]
	) VALUES (
		1299,
		'S196 Sudden increase in Margin Trading Facility (MTF) exposure',
		'System',
		GETDATE(),
		'System',
		GETDATE(),
		1,
		'S196',
		@RefAlertRegisterCaseTypeId,
		1, 
		'S196SuddenIncreaseInMarginTradingFacilityExposure',
		1,
		@FrequencyFlagRefEnumValueId,
		196,
		'This Scenario will detect the Sudden increase in Margin Trading facility exposure by a client <br>
		 It will generate alert if, <br>
		1. The percentage of Margin Trading facility exposure is greater than or equal to the set threshold by client. ( Compare with previous month )<br>
		2. Margin Trading facility exposure amount for current month is greater than or equal to set threshold by client <br>
		Segments covered : BSE_CASH & NSE_CASH ; Period: Calendar Month<br>
		 Thresholds:<br>
		A.Flat threshold : User can able to exclude Pro and Inst clients from generating the Alerts<br>
		B. MTF Amount : It is the higest MTF amount of the current month for a particular client (Addition of BSE & NSE for all the scrip for a particular client day wise )<br>
		C. % of MTF with previoue month : It is the % compare with previous month to current month<br>'
	)
GO
--RC-WEB-82720 END
--File:Tables:dbo:RefProcess:DML
--RC-WEB-82720 START
GO
	DECLARE	 @EnumValueId INT, @RefAmlReportId INT
	SELECT @EnumValueId = dbo.GetEnumValueId('ProcessType','Simple')
	SELECT @RefAmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S196 Sudden increase in Margin Trading Facility (MTF) exposure'

	INSERT INTO dbo.RefProcess (
		[Name],
		ClassName,
		AssemblyName,
		IsActive,
		IsScheduleEditable,
		AddedBy,
		AddedOn,
		EditedOn,
		LastEditedBy,
		RefAmlReportId,
		ProcessTypeRefEnumValueId,
		IsCompanyWise,
		Code,
		EnableRunDateSelection,
		DisplayName,
		LockingGroupId
	) VALUES (
		'S196 Sudden increase in Margin Trading Facility (MTF) exposure',
		'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S196SuddenIncreaseInMarginTradingFacilityExposure',
		'TSS.SmallOfficeWeb.ManageData',
		1,
		1,
		'System',
		GETDATE(),
		GETDATE(),
		'System',
		@RefAmlReportId,
		@EnumValueId,
		0,
		'S196',
		1,
		'S196 Sudden increase in Margin Trading Facility (MTF) exposure',
		1000
	)
GO
--RC-WEB-82720 END
--File:Tables:dbo:SysAmlReportSetting:DML
--RC-WEB-82720 START
GO
	DECLARE @AmlReportId INT

	SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S196 Sudden increase in Margin Trading Facility (MTF) exposure'

	INSERT INTO dbo.SysAmlReportSetting (
		RefAmlReportId,
		[Name],
		[Value],
		RefAmlQueryProfileId,
		DisplayName,
		DisplayOrder,
		AddedOn,
		AddedBy,
		EditedOn,
		LastEditedBy
	) VALUES (
		@AmlReportId,
		'Exclude_Pro',
		'False',
		1,
		'Exclude Pro',
		1,
		GETDATE(),
		'System',
		GETDATE(),
		'System'
	),(
		@AmlReportId,
		'Exclude_Institution',
		'False',
		1,
		'Exclude Institution',
		2,
		GETDATE(),
		'System',
		GETDATE(),
		'System'
	),(
		@AmlReportId,
		'Turnover',
		'0',
		1,
		'MTF Amount',
		3,
		GETDATE(),
		'System',
		GETDATE(),
		'System'
	),(
		@AmlReportId,
		'Threshold_Percentage',
		'0',
		1,
		'% of MTF with previous month',
		4,
		GETDATE(),
		'System',
		GETDATE(),
		'System'
	)
GO
--RC-WEB-82720 END
--File:StoredProcedures:dbo:AML_GetSuddenIncreaseInMarginTradingFacilityExposure
--RC-WEB-82720 START
GO
	CREATE PROCEDURE dbo.AML_GetSuddenIncreaseInMarginTradingFacilityExposure(        
		 @RunDate DATETIME,
		 @ReportId INT,
		 @IsDuplicateAllowed BIT
	)        
		AS        
		BEGIN     

			DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @ExcludePro BIT, @ExcludeInst BIT, @MTFAmmount DECIMAL(26,8),@MTFPreviuosMonth DECIMAL(26,8),
			@EndDate DATETIME,@StartDate DATETIME,@EndDatePrevious DATETIME,@StartDatePrevious DATETIME, @BSEId INT, @NSEId INT,@ProRefClientStatusId INT,@InstitutionRefClientStatusId INT,
			@IsDuplicateAllowedInternal BIT

			SET @RunDateInternal = @RunDate
			SET @ReportIdInternal = @ReportId
			SET @IsDuplicateAllowedInternal = @IsDuplicateAllowed

			SET @InstitutionRefClientStatusId = dbo.GetClientStatusId('Institution')
			SET @ProRefClientStatusId = dbo.GetClientStatusId('Pro')

			SET @BSEId = dbo.GetSegmentId('BSE_CASH') 
			SET @NSEId = dbo.GetSegmentId('NSE_CASH') 

			SET @EndDate = DATEADD(DAY, -(DAY(@RunDateInternal)), @RunDateInternal) + CONVERT(DATETIME, '23:59:59.000')  
			SET @StartDate = DATEADD(mm, DATEDIFF(mm, 0, @RunDateInternal) - 1, 0)

			SET @EndDatePrevious = DATEADD(DAY, -(DAY(@StartDate)), @StartDate) + CONVERT(DATETIME, '23:59:59.000')  
			SET @StartDatePrevious = DATEADD(mm, DATEDIFF(mm, 0, @StartDate) - 1, 0)

			SELECT @ExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
			FROM dbo.SysAmlReportSetting
			WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_Pro'

			SELECT @ExcludeInst = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
			FROM dbo.SysAmlReportSetting
			WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_Institution'

			SELECT @MTFAmmount = CONVERT(DECIMAL(26,8),[Value])
			FROM dbo.SysAmlReportSetting
			WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Turnover'

			SELECT @MTFPreviuosMonth = CONVERT(DECIMAL(26,8),[Value])
			FROM dbo.SysAmlReportSetting
			WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Threshold_Percentage'
		
			SELECT    
				RefClientId    
			INTO #clientsToExclude    
			FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
			WHERE (ExcludeAllScenarios = 1 OR RefAmlReportId = @ReportIdInternal)
				  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)

			SELECT
				 mar.RefClientId,
				 mar.MarginDate,
				 SUM( CASE WHEN mar.RefSegementId = @BSEId THEN mar.Amount ELSE 0 END) BSEMarginAmount,
				 SUM( CASE WHEN mar.RefSegementId = @NSEId THEN mar.Amount ELSE 0 END) NSEMarginAmount
			INTO #tempClientMargingData
			FROM dbo.CoreClientTradingMargin mar
			LEFT JOIN #clientsToExclude clex ON clex.RefClientId = mar.RefClientId
			WHERE mar.RefSegementId IN (@BSEId,@NSEId) AND clex.RefClientId IS NULL AND mar.MarginDate BETWEEN @StartDate AND @EndDate
			GROUP BY mar.RefClientId, mar.MarginDate
		
			SELECT
				t.RefClientId,
				t.MarginDate,
				(t.BSEMarginAmount + t.NSEMarginAmount) AS TotalMarginAmount,
				CASE WHEN t.BSEMarginAmount >= t.NSEMarginAmount THEN @BSEId ELSE @NSEId END RefSegmentId
			INTO #tempMarginData
			FROM #tempClientMargingData t
			WHERE (t.BSEMarginAmount + t.NSEMarginAmount) >= @MTFAmmount

			DROP TABLE #tempClientMargingData

			SELECT tem.RefClientId,
					tem.MarginDate,
					tem.TotalMarginAmount,
					tem.RefSegmentId
			INTO #finalMargindata
			FROM  (SELECT
						tem.RefClientId,
						tem.MarginDate,
						tem.RefSegmentId,
						tem.TotalMarginAmount,
						ROW_NUMBER()OVER(PARTITION BY tem.RefClientId ORDER BY tem.TotalMarginAmount DESC,tem.MarginDate DESC ) rn
					FROM #tempMarginData tem
					)tem
			WHERE tem.rn = 1
			DROP TABLE #tempMarginData

			SELECT
				 mar.RefClientId,
				 mar.MarginDate,
				 SUM(mar.Amount) AS TotalPreMarginAmount
			INTO #privousMonthData
			FROM dbo.CoreClientTradingMargin mar
			INNER JOIN #finalMargindata fm ON mar.RefClientId = fm.RefClientId
			WHERE mar.MarginDate BETWEEN @StartDatePrevious AND @EndDatePrevious AND mar.RefSegementId IN ( @BSEId, @NSEId)
			GROUP BY  mar.RefClientId, mar.MarginDate
		

			SELECT
				t.RefClientId, t.MarginDate, t.TotalPreMarginAmount
			INTO #finalPreMarginData
			FROM(
				SELECT tem.RefClientId, tem.MarginDate, tem.TotalPreMarginAmount,
				ROW_NUMBER()OVER(PARTITION BY tem.RefClientId ORDER BY tem.TotalPreMarginAmount DESC,tem.MarginDate DESC )rn
				FROM #privousMonthData tem
			)t
			WHERE t.rn = 1
		
			DROP TABLE #privousMonthData
		
			SELECT
				fmd.RefClientId,
				fmd.RefSegmentId,
				fmd.TotalMarginAmount,
				fmd.MarginDate,
				pre.MarginDate AS preMarginDate,
				pre.TotalPreMarginAmount,
				((fmd.TotalMarginAmount - pre.TotalPreMarginAmount)/pre.TotalPreMarginAmount) * 100 AS MTFPercentage
			INTO #finalData 
			FROM #finalMargindata fmd
			INNER JOIN #finalPreMarginData pre ON fmd.RefClientId = pre.RefClientId
			LEFT JOIN dbo.CoreAmlScenarioAlert dupCheck ON dupCheck.RefAmlReportId = @ReportIdInternal AND dupCheck.RefClientId = fmd.RefClientId  AND dupCheck.RefSegmentEnumId = fmd.RefSegmentId AND
			dupCheck.NetSellValue = fmd.TotalMarginAmount AND dupCheck.NetBuyValue = pre.TotalPreMarginAmount AND dupCheck.AccountOpeningDate = pre.MarginDate AND dupCheck.AccountClosingDate = fmd.MarginDate
			WHERE  
				(@IsDuplicateAllowedInternal = 1 OR dupCheck.CoreAmlScenarioAlertId IS NULL)AND 
				fmd.TotalMarginAmount  >= pre.TotalPreMarginAmount AND 
				((fmd.TotalMarginAmount - pre.TotalPreMarginAmount)/pre.TotalPreMarginAmount) * 100 >= @MTFPreviuosMonth


			SELECT
				fd.RefClientId,
				fd.RefSegmentId,
				cl.[Name] ClientName,
				cl.ClientId,
				@StartDate FromDate,
				@EndDate ToDate,
				fd.TotalPreMarginAmount AS MTFAmountOfPreviousMonth,
				fd.preMarginDate AS DateOfMTFAmountOfPreviousMonth,
				fd.TotalMarginAmount AS MTFAmountOfCurrentMonth,
				fd.MarginDate AS DateOfMTFAmountOfCurrentMonth,
				fd.MTFPercentage AS  PercOfMTFWithPreviousMonth
			FROM #finalData fd
			INNER JOIN dbo.RefClient cl ON cl.RefClientId = fd.RefClientId
			WHERE  (@ExcludePro = 0 OR cl.RefClientStatusId <> @ProRefClientStatusId)
				AND (@ExcludeInst = 0 OR cl.RefClientStatusId <> @InstitutionRefClientStatusId)
		END 
GO
--RC-WEB-82720 END
update re
set  re.[Description] ='This Scenario will detect the Sudden increase in Margin Trading facility exposure by a client <br>
		 It will generate alert if, <br>
		1. The percentage of Margin Trading facility exposure is greater than or equal to the set threshold by client. ( Compare with previous month )<br>
		2. Margin Trading facility exposure amount for current month is greater than or equal to set threshold by client <br>
		Segments covered : BSE_CASH & NSE_CASH ; Period: Calendar Month<br>
		 Thresholds:<br>
		A.Flat threshold : User can able to exclude Pro and Inst clients from generating the Alerts<br>
		B. MTF Amount : It is the higest MTF amount of the current month for a particular client (Addition of BSE & NSE for all the scrip for a particular client day wise )<br>
		C. % of MTF with previoue month : It is the % compare with previous month to current month<br>'
from dbo.RefAmlReport re
WHERE  re.Code ='S196'