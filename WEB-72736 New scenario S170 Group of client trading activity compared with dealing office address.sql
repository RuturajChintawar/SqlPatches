--WEB-72736-START RC
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
	[Description],
	Threshold1DisplayName,
	Threshold2DisplayName
) VALUES (
	1271,
	'S170 Group of client trading activity compared with dealing office address',
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	1,
	'S170',
	@RefAlertRegisterCaseTypeId,
	1, 
	'S170GroupOfClientTradingActivityComparedWithDealingOfficeAddress',
	1,
	@FrequencyFlagRefEnumValueId,
	170,
	'This Scenario will detect and alert if clients have done trades with diffrent PIN codes from KYC and dealing office PIN<br>
	Segments covered : BSE_CASH, NSE_CASH  <br>
	<b>Thresholds:</b> <br>
	1. No. of Traded Unique Group PIN: These are the unique PIN codes that the client has traded on the run date in one particular scrip. It will work on greater than or equal to basis.  It will generate alerts If the these traded PIN are totally different from the PIN mentioned in the client KYC. (Correspondence, Permanent address pin of the client and Pin of the intermediary mapped to the client ). 2. No. of Traded Unique PIN: These are the unique PIN codes that the client has traded on the run date in one particular segment. It will work on greater than or equal to basis.  It will generate alerts If the these traded PIN are totally different from the PIN mentioned in the client KYC. (Correspondence, Permanent address pin of the client and Pins of all the intermediary as per intermediary master ). The Top ''X'' PIN''s will be shown in alert output as per the threshold. <br>
	2.Clients trading with different pins and having atleast 1 common PIN and trades in the same scrip are to be considered as a group. <br> 
	3. Exclude PIN: It is a Flat manual textbox threshold. User can add the PIN Codes which they want to exclude from alert generation. The PIN''s are to be entered comma seperated. ( e.g. 400101, 396235 ) <br>
	<b>Note:</b><br>
	1. The number of Traded Unique PIN should be totally different from the Client PIN''s to generate alert. <br>',
	'No. of Traded Unique PIN',
	'Group TO'
)
GO
--WEB-72736-END RC
--WEB-72736-START RC
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S170 Group of client trading activity compared with dealing office address'
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
	'Excluded_Groups',
	'',
	1,
	'Exclude PIN',
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
	'Exclude_Pro',
	'False',
	1,
	'Exclude Pro',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
--WEB-72736-END RC
--WEB-72736-START RC
GO
DECLARE	 @EnumValueId INT, @RefAmlReportId INT


SELECT @EnumValueId = dbo.GetEnumValueId('ProcessType','Simple')
SELECT @RefAmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S170 Group of client trading activity compared with dealing office address'

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
	DisplayName
) VALUES (
	'S170 Group of client trading activity compared with dealing office address',
	'TSS.SmallOfficeWeb.ManageData.Processes.AML.Reports.S170GroupOfClientTradingActivityComparedWithDealingOfficeAddress',
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
	'S170',
	1,
	'S170 Group of client trading activity compared with dealing office address'
)
GO
--WEB-72736-END RC
--WEB-72736-START RC
GO
ALTER PROCEDURE dbo.AML_GetGroupOfClientTradingActivityComparedWithDealingOfficeAddress (              
 @RunDate DATETIME,              
 @ReportId INT              
)              
AS              
BEGIN           
	DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @ExcludePin VARCHAR(MAX), @ClientToThreshold DECIMAL(28,2), @UniquePinThreshold INT,          
   @BSECashId INT, @NSECashId INT, @Lookback INT,@LookBackDate DATETIME ,@ToDate DATETIME ,@TotalTO DECIMAL(28,2) ,    
   @IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT      
           
   SET @ReportIdInternal = @ReportId             
   SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)            
           
   SELECT @Lookback = CONVERT(INT, [Value]) FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Number_Of_Days'              
   SET @ToDate = CONVERT(DATETIME, DATEDIFF(dd, 0, @RunDateInternal)) + CONVERT(DATETIME, '23:59:59.000')                 
   SET @LookBackDate = CONVERT(DATETIME, DATEDIFF(dd, @Lookback-1, @RunDateInternal))           
            
          
   SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'          
   SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'          
       
   SELECT @ProStatusId = RefClientStatusId  FROM dbo.RefClientStatus WHERE [Name] = 'Pro'      
   SELECT  @InstituteStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'      
        
   SELECT       
    @IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END      
   FROM dbo.SysAmlReportSetting       
   WHERE       
    RefAmlReportId = @ReportIdInternal       
    AND [Name] = 'Exclude_Pro'      
       
   SELECT       
   @IsExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END      
   FROM dbo.SysAmlReportSetting       
   WHERE       
   RefAmlReportId = @ReportIdInternal       
   AND [Name] = 'Exclude_Institution'      
    
          
   SELECT           
   @ExcludePin = [Value]           
   FROM dbo.SysAmlReportSetting           
   WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Excluded_Groups'          

   SELECT          
   RTRIM(LTRIM(pins.items)) AS pin          
   INTO #ExcludePin          
   FROM dbo.Split(@ExcludePin,',') pins   
   
   SELECT
		sg.[Name] AS ScripGroup,
		rul.Threshold,
		rul.Threshold2
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule rul
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup linkSG ON linkSG.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId
	INNER JOIN dbo.RefScripGroup sg ON sg.RefScripGroupId = linkSG.RefScripGroupId
	WHERE RefAmlReportId = @ReportIdInternal
           
   SELECT DISTINCT          
   RefClientId          
   INTO #clientsToExclude      
   FROM dbo.LinkRefAmlReportRefClientAlertExclusion ex          
   WHERE (ex.RefAmlReportId = @ReportIdInternal OR ex.ExcludeAllScenarios = 1)           
   AND @RunDateInternal >= ex.FromDate AND (ex.ToDate IS NULL OR ex.ToDate >= @RunDateInternal)         
      
   SELECT      
	   trade.RefClientId,      
	   trade.RefSegmentId,      
	   trade.RefInstrumentId,      
	   SUBSTRING (CONVERT(VARCHAR(MAX),trade.CtclId) ,1,6)AS Pin,      
	   (trade.Rate * trade.Quantity) AS Turnover,     
	   trade.Quantity,
	   inst.GroupName,
	   inst.Isin
   INTO #tradedetails      
   FROM dbo.CoreTrade trade      
   INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
   INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId
   LEFT JOIN #clientsToExclude ex ON ex.RefClientId = trade.RefClientId          
   WHERE ex.RefClientId IS NULL AND        
   trade.RefSegmentId IN ( @BSECashId, @NSECashId )  AND       
   trade.TradeDate = @RunDateInternal   AND    
   (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)      
   AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)  
   
   SELECT DISTINCT
		td.Isin,
		CASE WHEN inst.GroupName IS NOT NULL
		THEN inst.GroupName
		ELSE 'B' END AS GroupName,
		inst.Code
	INTO #allNseGroupData
	FROM #tradedetails td
	LEFT JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @BSECashId
	AND td.Isin = inst.Isin  AND inst.[Status]='A'
	WHERE td.RefSegmentId = @NSECashId

	SELECT Isin, COUNT(1) AS rcount
	INTO #multipleGroups 
	FROM #allNseGroupData
	GROUP BY Isin
	HAVING COUNT(1)>1

	SELECT t.Isin, t.GroupName
	INTO #nseGroupData
	FROM
	(
		SELECT grp.Isin, grp.GroupName   
		FROM #allNseGroupData grp
		LEFT JOIN #multipleGroups mg ON mg.Isin = grp.Isin
		WHERE mg.Isin IS NULL
	
		UNION

		SELECT  mg.Isin, grp.GroupName
		FROM #multipleGroups mg
		INNER JOIN #allNseGroupData grp ON grp.Isin=mg.Isin AND grp.Code like '5%'
	)t

	DROP TABLE #allNseGroupData
	DROP TABLE #multipleGroups

	SELECT
		td.RefClientId,
		td.RefSegmentId,
		td.TurnOver,
		td.Pin,
		td.Isin,
		td.RefInstrumentId,
		CASE WHEN td.RefSegmentId = @BSECashId THEN td.GroupName ELSE ngd.GroupName END AS GroupName
	INTO #tradeDataWithScripGroup
	FROM #tradedetails td
	INNER JOIN  dbo.RefClient ref ON ref.RefClientId = td.RefClientId      
    LEFT JOIN dbo.RefIntermediary inter ON inter.RefIntermediaryId = ref.RefIntermediaryId  
	LEFT JOIN #nseGroupData ngd ON td.RefSegmentId = @NSECashId AND td.Isin = ngd.Isin
	LEFT JOIN #ExcludePin pins ON pins.pin = td.Pin  
	INNER JOIN #scenarioRules rules ON (td.RefSegmentId = @BSECashId AND td.GroupName = rules.ScripGroup) OR
	(td.RefSegmentId = @NSECashId AND ngd.GroupName = rules.ScripGroup)
	WHERE pins.pin IS NULL AND  
		  td.Pin NOT IN ('111111','333333','555555', '0',ISNULL(ref.CAddressPin,''), ISNULL(ref.PAddressPin,''), ISNULL(inter.Pin,''),ISNULL(inter.ResPin,''))

	
	SELECT 
	DISTINCT
	trade.RefClientId,
		trade.RefSegmentId,
		trade.RefInstrumentId,
		trade.Pin
	INTO #uniquePinData
	FROM #tradeDataWithScripGroup trade

	--CLIENT SIDE DATA
	SELECT t.*
	INTO #uniquetradeddata
	FROM
		(SELECT
		trade.RefClientId,
		trade.RefSegmentId,
		trade.RefInstrumentId,
		COUNT(DISTINCT trade.Pin) uniCount,
		trade.GroupName,
		SUM(trade.TurnOver) AS ClientTO,
		STUFF
		(
			(
				SELECT ', ' + trade1.Pin
				FROM #UNIQUEPINDATA trade1
				WHERE trade.RefSegmentId =  trade1.RefSegmentId 
				AND trade.RefClientId = trade1.RefClientId
				AND trade.RefInstrumentId = trade1.RefInstrumentId
				
				FOR XML PATH ('')
			),
		1,2,''
		) AS UniquePIN
		FROM #tradeDataWithScripGroup trade
		GROUP BY trade.RefClientId,
			trade.RefSegmentId,
			trade.RefInstrumentId,
			trade.GroupName)t
	INNER JOIN #scenarioRules rules ON rules.ScripGroup =t.GroupName AND t.uniCount >= rules.Threshold

	-- group pin data
	SELECT t.*,
	ROW_NUMBER ()OVER(ORDER BY t.Pin) RN
	INTO #GroupDataTradeData
	FROM
	(SELECT
		STUFF
			(
				(
					SELECT DISTINCT ', ' + CONVERT(VARCHAR(100),trade1.RefClientId)
					FROM #tradeDataWithScripGroup trade1
					INNER JOIN #uniquetradeddata uni ON uni.RefClientId =trade1.RefClientId AND uni.RefSegmentId = trade1.RefSegmentId AND uni.RefInstrumentId = trade1.RefInstrumentId
					WHERE trade.RefSegmentId =  trade1.RefSegmentId 
					AND trade.Pin = trade1.Pin
					AND trade.RefInstrumentId = trade1.RefInstrumentId
				
					FOR XML PATH ('')
				),
			1,2,''
		) AS GroupClientId,
		trade.PIN,
		trade.RefSegmentId,
		trade.RefInstrumentId,
		trade.GroupName,
		COUNT(DISTINCT trade.RefClientid) clcount
	
	FROM #tradeDataWithScripGroup trade
	INNER JOIN #uniquetradeddata uni ON uni.RefClientId = trade.RefClientId AND trade.RefSegmentId = uni.RefSegmentId AND trade.RefInstrumentId = uni.RefInstrumentId 
	GROUP BY trade.PIN,
		trade.RefSegmentId,
		trade.RefInstrumentId,
		trade.GroupName) t
	WHERE  clcount>1

	SELECT grp.RN,
	SUM(uni.ClientTO) grpTO
	INTO #grpTurnOverData	
	FROM #groupDataTradeData grp
	INNER JOIN #uniquetradeddata uni ON grp.Pin IN(SELECT CONVERT(VARCHAR(10),s.s) FROM dbo.ParseString(uni.UniquePIN,',')s)
	GROUP BY grp.RN

	SELECT
	   uni.RefClientId,
	   uni.RefSegmentId,
	   uni.RefInstrumentId,
	   ref.ClientId,
	   @RunDateInternal AS TradeDate,
	   seg.Segment,
	   ref.[Name] ClientName,
	   uni.GroupName AS [Group],
	   inst.Code AS ScripCode,
	   inst.[Name] AS ScripName,
	   uni.ClientTO AS ClientScripTO,
	   grd.grpTO AS GroupScripTO,
	   STUFF((ISNULL(', '+ref.CAddressPin,'')+ISNULL(', '+ref.PAddressPin,'')+ISNULL(', '+inter.Pin,'')+ISNULL(', '+inter.ResPin,'')),1,2,'') AS ClientKYCPIN,
	   grp.Pin GroupCommonPIN,
	   STUFF
		(
			(
				SELECT ', ' + cl.ClientId
				FROM dbo.Split(grp.GroupClientId,',') grpcl
				INNER JOIN dbo.RefClient cl ON cl.RefClientId = CONVERT(BIGINT,grpcl.items)
				WHERE cl.RefClientId <>uni.RefClientId
				FOR XML PATH ('')
			),
		1,2,''
		) AS [GrpClientId],
		uni.UniquePIN
	FROM #uniquetradeddata uni
	INNER JOIN #GroupDataTradeData grp ON uni.RefInstrumentId = grp.RefInstrumentId AND uni.RefSegmentId = grp.RefSegmentId AND uni.RefClientId IN (SELECT CONVERT(BIGINT,s.items)FROM dbo.Split(grp.GroupClientId,',') s)
	INNER JOIN #grpTurnOverData grd ON grd.RN = grp.RN
	INNER JOIN #scenarioRules rules ON rules.ScripGroup = grp.GroupName AND grd.grpTO >= rules.Threshold2
	INNER JOIN dbo.RefClient ref ON ref.RefClientId = uni.RefClientId  
    LEFT JOIN dbo.RefIntermediary inter ON inter.RefIntermediaryId = ref.RefIntermediaryId          
	INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = uni.RefSegmentId
	INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = uni.RefInstrumentId
 END          
GO
--WEB-72736-END RC