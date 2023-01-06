--File:StoredProcedures:dbo:CoreFinancialTransaction_GetS7006SuddenHighValueTransactionForTheClientInAMonthScenarioAlert
--WEB-77889-RC-START
GO
ALTER PROCEDURE [dbo].[CoreFinancialTransaction_GetS7006SuddenHighValueTransactionForTheClientInAMonthScenarioAlert]
(
	 @RunDate DATETIME
	,@AmlReportId INT
	,@ProfileId INT
	,@ParentCompanyId INT
	,@IsRuleDuplicationAllowed BIT = 0
)
AS 
BEGIN
	DECLARE 
	@ClientEntityTypeId INT,
	@ReceiptVoucherTypeId INT,
	--@ActiveEntityStatusTypeEnumValueId INT,
	@CurrentDate DATETIME,
	@RuleEntityTypeId INT,
	@InternalAmlReportId INT,
	@InternalProfileId INT,
	@InternalParentCompanyId INT,
	@InternalStartDate DATETIME,
	@InternalEndDate DATETIME,
	@RelatedPartyRelationRefEnumTypeId INT,
	@LookBackStartDate DATETIME,
	@LookBackEndDate DATETIME,
	@InternalIsRuleDuplicationAllowed BIT,
	@PercentageJumpThreshold DECIMAL(10,2), @ConsiderMonths INT , @MoneyInValue DECIMAL(19,2) , @ConsiderRelations VARCHAR(MAX)

	SET @ClientEntityTypeId = dbo.GetEntityTypeByCode('Client')
	SELECT @ReceiptVoucherTypeId = RefVoucherTypeId FROM dbo.RefVoucherType WHERE [Name] = 'Receipt'
	--SET @ActiveEntityStatusTypeEnumValueId = dbo.GetEnumValueId('CRMEntityStatusType','Active');
	SET @RuleEntityTypeId = dbo.GetEntityTypeByParentCompanyIdAndParentEntityTypeCode(@ParentCompanyId,'BaseScenarioRule');
	SET @InternalStartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @RunDate), 0)  
	SET @InternalEndDate = @RunDate	
	SET @InternalAmlReportId = @AmlReportId
	SET @InternalProfileId = @ProfileId
	SET @InternalParentCompanyId = @ParentCompanyId
	SET @RelatedPartyRelationRefEnumTypeId = dbo.GetEnumTypeId('RelatedPartyRelation')
	SET @InternalIsRuleDuplicationAllowed = @IsRuleDuplicationAllowed
	
	
	----Get-Report Settings-----
	SELECT
	rs.[Name],
	link.[Value]
	INTO #reportSetting
	FROM
	dbo.SysAmlReportSetting rs
	INNER JOIN
	LinkSysAmlReportSettingRefAMLScenarioRuleProfile link ON link.SysAmlReportSettingId = rs.SysAmlReportSettingId
	INNER JOIN
	RefAMLScenarioRuleProfile rp ON rp.RefAMLScenarioRuleProfileId = link.RefAMLScenarioRuleProfileId AND rp.RefEntityTypeId = @RuleEntityTypeId
	WHERE 
	rs.RefAmlReportId = @InternalAmlReportId 
	AND
	rp.RefAMLScenarioRuleProfileId = @InternalProfileId
	
	SELECT 
		@PercentageJumpThreshold = CONVERT(DECIMAL(10,2) ,temp.[Value])
	FROM #reportSetting	temp
	WHERE temp.[Name] = 'PercentageJumpThreshold'

	SELECT 
		@ConsiderMonths = CAST(temp.[Value] AS INT)
	FROM #reportSetting	temp
	WHERE temp.[Name] = 'ConsiderMonths'

	SELECT
		@MoneyInValue = CONVERT(DECIMAL(19,2) ,temp.[Value])
	FROM #reportSetting	temp
	WHERE temp.[Name] = 'MoneyInValue'

	SELECT
		@ConsiderRelations = temp.[Value]
	FROM #reportSetting	temp
	WHERE temp.[Name] = 'ConsiderRelations'

	SELECT 
		enumvalue.RefEnumValueId
	INTO #Relations
	FROM
	dbo.Split(@ConsiderRelations, ',') s
	INNER JOIN dbo.RefEnumValue enumvalue ON enumvalue.Code = RTRIM(LTRIM(s.items))  
	WHERE RefEnumTypeId =  @RelatedPartyRelationRefEnumTypeId

	-------- Accessible Prod Accs
	SELECT DISTINCT
			cust.RefCRMCustomerId
		   ,rp.EntityId AS RefClientId
		   ,cust.CustomerCode
		   ,cust.FirstName
		   ,cust.MiddleName
		   ,cust.LastName
		   ,cust.RefEntityTypeId
		   ,clients.ClientId AS ProductAccountNumber
		   ,STUFF(( SELECT ',' + seg.Segment
					FROM dbo.LinkRefClientRefSegment link
					INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = link.RefSegmentId
					WHERE link.RefClientId = rp.EntityId
			 FOR
			 XML PATH('')
			 ), 1, 1, '') AS Products,
			 --@ActiveEntityStatusTypeEnumValueId as active,
			 cust.RefParentCompanyId,
			  clients.AccountOpeningDate,
			  DATEADD(MONTH, -3, @InternalEndDate) AS expectDate
	 INTO #AccessibleProductAccount
		FROM dbo.CoreCRMRelatedParty rp 
		 INNER JOIN #Relations conRel ON rp.RelatedPartyRelationRefEnumValueId = conRel.RefEnumValueId
		 INNER JOIN dbo.RefCRMCustomer cust ON cust.RefCRMCustomerId = rp.RelatedPartyRefCRMCustomerId AND rp.RefEntityTypeId = @ClientEntityTypeId
		 INNER JOIN dbo.RefClient clients ON clients.RefClientId = rp.EntityId
		 LEFT JOIN dbo.RefClientDatabaseEnum dbEnum ON dbEnum.RefClientDatabaseEnumId = clients.RefClientDatabaseEnumId 
	 WHERE 
	 --st.CRMEntityStatusTypeRefEnumValueId = @ActiveEntityStatusTypeEnumValueId AND 
	 cust.RefParentCompanyId = @InternalParentCompanyId
	 AND clients.AccountOpeningDate <= DATEADD(MONTH, -3, @InternalEndDate) 
	 AND NOT EXISTS
	 (	SELECT 1 
		FROM dbo.CoreAmlScenarioExclusion excl 
		WHERE excl.RefCRMCustomerId = cust.RefCRMCustomerId 
		AND excl.RefAmlReportId = @InternalAmlReportId 
		AND @InternalEndDate >= excl.StartDate 
		AND (excl.EndDate IS NULL OR @InternalEndDate <= excl.EndDate)
	 )

	---------Get Clients With atleast One Transaction on End Date------------
	SELECT 
		pa.RefCRMCustomerId,
		ft.RefClientId,
		ft.RefVoucherTypeId,
		ft.Amount,
		ft.TransactionDate 
	INTO #monthlyFinancialTransaction
	FROM dbo.CoreFinancialTransaction ft 	
	INNER JOIN #AccessibleProductAccount pa ON ft.RefClientId = pa.RefClientId
	WHERE ft.TransactionDate BETWEEN @InternalStartDate AND @InternalEndDate 
	AND ft.RefVoucherTypeId = @ReceiptVoucherTypeId 

	SELECT DISTINCT
		mft.RefCRMCustomerId
	INTO #tempConsiderableCustomers
	FROM #monthlyFinancialTransaction  mft
	WHERE mft.TransactionDate = @InternalEndDate	

	SELECT 
		cust.RefCRMCustomerId,
		pa.RefClientId
	INTO #tempConsiderableClients
	FROM #tempConsiderableCustomers cust
	INNER JOIN #AccessibleProductAccount pa ON cust.RefCRMCustomerId = pa.RefCRMCustomerId
	

	SELECT DISTINCT
		ft.RefCRMCustomerId,
		SUM(ft.Amount) AS TransactionAmount 
	INTO #consolidatedCurrentMonthTransactions 
	FROM #monthlyFinancialTransaction ft
	INNER JOIN #tempConsiderableClients clients ON clients.RefCRMCustomerId = ft.RefCRMCustomerId AND clients.RefClientId = ft.RefClientId 
	GROUP BY ft.RefCRMCustomerId

	SELECT DISTINCT
		RefCRMCustomerId
	INTO #considerableCustomers	 
	FROM #consolidatedCurrentMonthTransactions temp
	WHERE temp.TransactionAmount >= @MoneyInValue

	
	 SET @LookBackEndDate =  DATEADD(DAY,-1,@InternalStartDate)
	 SET @LookBackStartDate = DATEADD(MONTH,-@ConsiderMonths,@LookBackEndDate)

	 SELECT 
		 clients.RefCRMCustomerId,
		 ft.RefVoucherTypeId,
		 ft.Amount,
		 ft.TransactionDate,
		 ft.RefClientId
	 INTO #tempLookBackFinancial	
	 FROM #considerableCustomers cust 
	 INNER JOIN #tempConsiderableClients clients ON clients.RefCRMCustomerId = cust.RefCRMCustomerId
	 INNER JOIN dbo.CoreFinancialTransaction ft ON clients.RefClientId = ft.RefClientId
	 WHERE TransactionDate BETWEEN @LookBackStartDate AND @LookBackEndDate 
	 AND RefVoucherTypeId = @ReceiptVoucherTypeId

	SELECT 
		ft.RefCRMCustomerId,
		SUM(ft.Amount) AS monthwisePerviousTransactionAmount
	INTO #TempCoreFinancialTransaction
	FROM #TempLookBackFinancial ft
	GROUP BY ft.RefCRMCustomerId,
			DATEADD(MONTH, DATEDIFF(MONTH, 0, ft.TransactionDate), 0)

	SELECT 
		temp.RefCRMCustomerId,
		SUM(temp.monthwisePerviousTransactionAmount) AS PerviousTrasactionAmount,
		COUNT(temp.RefCRMCustomerId) AS MonthsConsidered
	INTO #FinalCoreFinancialTransaction
	FROM #TempCoreFinancialTransaction temp
	GROUP BY 
	temp.RefCRMCustomerId

	---------------------------------------
	SELECT 
		temp2.RefCRMCustomerId,
		temp2.TransactionAmount,
		CONVERT(DECIMAL(10,2), (temp2.TransactionAmount - (temp1.PerviousTrasactionAmount / temp1.MonthsConsidered))/(temp1.PerviousTrasactionAmount / temp1.MonthsConsidered) * 100) AS PercentageJump,
		(temp1.PerviousTrasactionAmount / temp1.MonthsConsidered) AS AverageTransactionAmount,
		temp1.MonthsConsidered
	INTO #FinalFinancialOutput
	FROM #FinalCoreFinancialTransaction temp1
	INNER JOIN #consolidatedCurrentMonthTransactions temp2 ON temp2.RefCRMCustomerId = temp1.RefCRMCustomerId
	---------------------------
	SELECT DISTINCT
		fl.RefCRMCustomerId	
	INTO #distinctCust
	FROM #FinalFinancialOutput fl

	SELECT identification.IdNumber,
		ex.[Name] AS exName,
		dis.RefCRMCustomerId
	INTO #custSource  
	FROM dbo.CoreCRMIdentification identification  
	INNER JOIN #distinctCust dis ON dis.RefCRMCustomerId = identification.EntityId
	INNER JOIN dbo.RefCRMCustomer cust ON cust.RefCRMCustomerId = dis.RefCRMCustomerId   AND identification.RefEntityTypeId = cust.RefEntityTypeId
	INNER JOIN dbo.RefIdentificationType IdenType ON IdenType.RefIdentificationTypeId = identification.RefIdentificationTypeId AND IdenType.IsExternalSystem = 1 
	INNER JOIN dbo.RefExternalSystem ex ON ex.RefIdentificationTypeId = IdenType.RefIdentificationTypeId

	SELECT DISTINCT
		 accounts.RefCRMCustomerId AS CustomerId,
		 accounts.CustomerCode,
		 accounts.FirstName,
		 accounts.MiddleName,
		 accounts.LastName,	 
		 @InternalStartDate AS StartDate,
		 @InternalEndDate AS EndDate,
		 ft.TransactionAmount,
		 ft.PercentageJump,
		 ft.AverageTransactionAmount,
		 ft.MonthsConsidered,
		 STUFF(( SELECT DISTINCT ', '+ cl.ClientId        
			  FROM #tempConsiderableClients temp
			  INNER JOIN dbo.RefClient cl ON  temp.RefCRMCustomerId = ft.RefCRMCustomerId AND cl.RefClientId = temp.RefClientId 
			  FOR XML PATH('')),1,1,'') 
			  AS ProductAccountDetail,
		 STUFF(( SELECT ', '+ ( src.IdNumber +' - '  + src.exName )        
			  FROM #custSource src
				WHERE src.RefCRMCustomerId = ft.RefCRMCustomerId
			  FOR XML PATH('')),1,1,'') 
			   AS SourceSystemDetail
	 FROM #FinalFinancialOutput ft
	 INNER JOIN #AccessibleProductAccount accounts ON  ft.RefCRMCustomerId = accounts.RefCRMCustomerId
	 LEFT JOIN dbo.CoreAlertRegisterCustomerCaseAlert dupCheck ON dupCheck.RefCRMCustomerId = ft.RefCRMCustomerId
				AND dupCheck.RefAmlReportId = @InternalAmlReportId
				AND dupCheck.StartDate = @InternalStartDate
				AND dupCheck.EndDate = @InternalEndDate
				AND dupCheck.MoneyIn = ft.TransactionAmount
	 WHERE ft.PercentageJump >= @PercentageJumpThreshold 
	 AND (@InternalIsRuleDuplicationAllowed = 1 OR dupCheck.CoreAlertRegisterCustomerCaseAlertId IS NULL)
END
GO
--WEB-77889-RC-END

--File:StoredProcedures:dbo:CoreFinancialTransaction_GetS7013SuddenIncreaseInNumberOfTransactionsInAMonthForTheClient
--WEB-77889-RC-START
GO
ALTER PROCEDURE [dbo].[CoreFinancialTransaction_GetS7013SuddenIncreaseInNumberOfTransactionsInAMonthForTheClient]
( 
	 @RunDate DATETIME
	,@StartDate DATETIME
	,@AmlReportId INT
	,@ProfileId INT
	,@ParentCompanyId INT
	,@IsAlertDuplicationAllowed BIT = 0
)
AS 
BEGIN

	DECLARE 
	@ClientEntityTypeId INT,
	@CurrentDate DATETIME,
	@RuleEntityTypeId INT,
	@InternalAmlReportId INT,
	@InternalProfileId INT,
	@InternalParentCompanyId INT,
	@InternalStartDate DATETIME,
	@InternalEndDate DATETIME,
	@CustomerRelations VARCHAR(MAX),
	@RelatedPartyRelationRefEnumTypeId INT,
	@InternalIsAlertDuplicationAllowed BIT,
	@PercentageJump DECIMAL(19,2),
	@NoOfTnx INT,
	@NoOfMonth INT,
	@InternalEndDateMaxTime DATETIME,
	@GivenNoOfMonthStartDate DATETIME,
	@GivenNoOfMonthENDDate DATETIME
	--,@ActiveEntityStatusTypeEnumValueId INT
	
	--SET @ActiveEntityStatusTypeEnumValueId = dbo.GetEnumValueId('CRMEntityStatusType','Active');
	SET @ClientEntityTypeId = dbo.GetEntityTypeByCode('Client')
	SET @RuleEntityTypeId = dbo.GetEntityTypeByParentCompanyIdAndParentEntityTypeCode(@ParentCompanyId,'BaseScenarioRule');
	SET @InternalStartDate = dbo.GetDateWithoutTime(@StartDate)  
	SET @InternalEndDate = dbo.GetDateWithoutTime(@RunDate)		
	SET @InternalAmlReportId = @AmlReportId
	SET @InternalProfileId = @ProfileId
	SET @InternalParentCompanyId = @ParentCompanyId
	SET @RelatedPartyRelationRefEnumTypeId = dbo.GetEnumTypeId('RelatedPartyRelation')	
	SET @InternalIsAlertDuplicationAllowed = @IsAlertDuplicationAllowed
	SET @InternalEndDateMaxTime = CONVERT(DATETIME,DATEDIFF(dd, 0,@InternalEndDate)) + CONVERT(DATETIME,'23:59:59.997')	
	

-------------------------------Get-Report Settings--------------------------
	SELECT
	rs.[Name],
	link.[Value]
	INTO #reportSetting
	FROM
	dbo.SysAmlReportSetting rs
	INNER JOIN
	LinkSysAmlReportSettingRefAMLScenarioRuleProfile link ON link.SysAmlReportSettingId = rs.SysAmlReportSettingId
	INNER JOIN dbo.RefAMLScenarioRuleProfile rp ON rp.RefAMLScenarioRuleProfileId = link.RefAMLScenarioRuleProfileId AND rp.RefEntityTypeId = @RuleEntityTypeId
	WHERE 
	rs.RefAmlReportId = @InternalAmlReportId 
	AND
	rp.RefAMLScenarioRuleProfileId = @InternalProfileId
	
----------------------------Make Customer Relations Table------------------
	SELECT 
	@NoOfTnx = CAST(temp.[Value] AS INT)
	FROM
	#reportSetting	temp
	WHERE temp.[Name] = 'NumberofTransactions'
	
	SELECT 
	@NoOfMonth = CAST(temp.[Value] AS INT)
	FROM
	#reportSetting	temp
	WHERE temp.[Name] = 'ConsiderMonths'
	
	SELECT 
	@PercentageJump = CAST(temp.[Value] AS DECIMAL)
	FROM
	#reportSetting	temp
	WHERE temp.[Name] = 'PercentageJump'
	
	SELECT 
	@CustomerRelations = temp.[Value]
	FROM
	#reportSetting	temp
	WHERE temp.[Name] = 'RelationtoProductAccount'

	SET @GivenNoOfMonthStartDate = DATEADD(m, -@NoOfMonth, @InternalStartDate)
	SET @GivenNoOfMonthENDDate = DATEADD(d, -1, @InternalStartDate) + CONVERT(DATETIME,'23:59:59.997')
	--select @GivenNoOfMonthStartDate,@GivenNoOfMonthENDDate

	SELECT 
	enumvalue.RefEnumValueId
	INTO #Relations
	FROM
	dbo.Split(@CustomerRelations, ',') s
	INNER JOIN dbo.RefEnumValue enumvalue ON enumvalue.Code = REPLACE(s.items, ' ', '')  
	WHERE RefEnumTypeId =  @RelatedPartyRelationRefEnumTypeId

	SELECT excl.RefCRMCustomerId 
	INTO #ExcludeCustomers
	FROM dbo.CoreAmlScenarioExclusion excl 
	 WHERE   excl.RefAmlReportId = @InternalAmlReportId 
	 AND @InternalEndDate >= excl.StartDate AND (excl.EndDate IS NULL OR @InternalEndDate <= excl.EndDate)

	SELECT DISTINCT
			cust.RefCRMCustomerId
		   ,rp.EntityId AS RefClientId
		   ,cust.CustomerCode
		   ,cust.FirstName
		   ,cust.MiddleName
		   ,cust.LastName
		   ,cust.RefEntityTypeId

	 INTO #AccessibleProductAccount
	 FROM dbo.CoreCRMRelatedParty rp 
	 INNER JOIN dbo.RefCRMCustomer cust ON cust.RefCRMCustomerId = rp.RelatedPartyRefCRMCustomerId 
	 INNER JOIN #Relations tempRelation ON tempRelation.RefEnumValueId = rp.RelatedPartyRelationRefEnumValueId AND rp.RefEntityTypeId = @ClientEntityTypeId
	 WHERE 	 
	 --st.CRMEntityStatusTypeRefEnumValueId = @ActiveEntityStatusTypeEnumValueId AND 
	 cust.RefParentCompanyId = @InternalParentCompanyId
	 AND NOT EXISTS(SELECT 1 FROM #ExcludeCustomers excl WHERE excl.RefCRMCustomerId=cust.RefCRMCustomerId)

	 SELECT  
		DISTINCT RefClientId 
	 INTO #distinctClient
	 FROM #AccessibleProductAccount

	 SELECT  
		DISTINCT 
		temp.RefClientId
	 INTO #ftClient
	 FROM #distinctClient temp
	 INNER JOIN dbo.CoreFinancialTransaction  ft ON ft.RefClientId = temp.RefClientId
	WHERE 
		ft.TransactionDate BETWEEN @InternalEndDate AND @InternalEndDateMaxTime


	
	SELECT DISTINCT
		pAcc.RefCRMCustomerId  
	INTO #considerableCustomers
	FROM #ftClient clients
	INNER JOIN #AccessibleProductAccount pAcc ON pAcc.RefClientId =  clients.RefClientId

	SELECT 
			pAcc.RefCRMCustomerId
		   ,pAcc.RefClientId
		   ,pAcc.CustomerCode
		   ,pAcc.FirstName
		   ,pAcc.MiddleName
		   ,pAcc.LastName
	INTO #FinalAccessibleProductAccount
	FROM #considerableCustomers cust
	INNER JOIN #AccessibleProductAccount pAcc  ON cust.RefCRMCustomerId = pAcc.RefCRMCustomerId	

	SELECT DISTINCT
	ft.RefClientId,ft.CoreFinancialTransactionId, cl.ClientId, ft.TransactionDate,ft.Amount
	INTO #Transactions
	FROM 
	#FinalAccessibleProductAccount acc
	INNER JOIN dbo.CoreFinancialTransaction ft ON ft.RefClientId=acc.RefClientId
	INNER JOIN dbo.RefClient cl ON cl.RefClientId=acc.RefClientId 
	WHERE
	ft.TransactionDate BETWEEN @GivenNoOfMonthStartDate AND @InternalEndDateMaxTime

	SELECT t.RefCRMCustomerId,t.ftCount
	INTO #ftCurrentMonthCount
	FROM 
	(
		 SELECT  		 
			temp.RefCRMCustomerId
			,COUNT(ft.CoreFinancialTransactionId) AS ftCount
		FROM #FinalAccessibleProductAccount temp
		 INNER JOIN #Transactions  ft ON ft.RefClientId = temp.RefClientId
		WHERE 
			ft.TransactionDate BETWEEN @InternalStartDate AND @InternalEndDateMaxTime
		GROUP BY temp.RefCRMCustomerId
	) t
	WHERE t.ftCount>=@NoOfTnx

	select RefCRMCustomerId,
			COUNT(MonthsConsidered) as MonthsCount
	INTO #TempCoreFinancialTransaction
	FROM(
	SELECT 
		temp.RefCRMCustomerId,
		COUNT(ft.CoreFinancialTransactionId) AS MonthsConsidered
	FROM #FinalAccessibleProductAccount temp
	 INNER JOIN #Transactions  ft ON ft.RefClientId = temp.RefClientId
	 WHERE 
		ft.TransactionDate BETWEEN @GivenNoOfMonthStartDate AND @GivenNoOfMonthENDDate
	GROUP BY temp.RefCRMCustomerId,
			DATEADD(MONTH, DATEDIFF(MONTH, 0, ft.TransactionDate), 0)
	)t GROUP BY RefCRMCustomerId
	
	SELECT  		 
		temp.RefCRMCustomerId
		,COUNT(ft.CoreFinancialTransactionId) AS ftCount
	INTO #ftCustomerwiseCount
	FROM #FinalAccessibleProductAccount temp
	 INNER JOIN #Transactions  ft ON ft.RefClientId = temp.RefClientId
	 WHERE 
		ft.TransactionDate BETWEEN @GivenNoOfMonthStartDate AND @GivenNoOfMonthENDDate
	 GROUP BY temp.RefCRMCustomerId
	
	 SELECT  		 
		temp.RefCRMCustomerId
		,ftCount
		,CAST(ftCount/CAST(t.MonthsCount AS DECIMAL (19,2)) AS DECIMAL (19,2)) AS AVGCount
		,t.MonthsCount
	INTO #ftGivenMonthCount
	FROM #ftCustomerwiseCount temp
	 INNER JOIN #TempCoreFinancialTransaction t ON t.RefCRMCustomerId=temp.RefCRMCustomerId
	 
	
	


	SELECT CurrentMonthFt.RefCRMCustomerId
	,cu.CustomerCode
	,cu.FirstName
	,cu.MiddleName
	,cu.LastName
	,CurrentMonthFt.ftCount AS CurrentMonthTransactionCount
	,AVGCount AS AvgTransactionCount
	,((CurrentMonthFt.ftCount - AVGCount) /  CAST(AVGCount AS DECIMAL (19,2)) * 100 ) AS PercentageJump
	,MonthFt.MonthsCount
	INTO #CustomerOutput
	FROM #ftGivenMonthCount MonthFt
	INNER JOIN #ftCurrentMonthCount CurrentMonthFt ON CurrentMonthFt.RefCRMCustomerId=MonthFt.RefCRMCustomerId
	INNER JOIN dbo.RefCRMCustomer cu ON cu.RefCRMCustomerId=CurrentMonthFt.RefCRMCustomerId
	WHERE (CurrentMonthFt.ftCount - (MonthFt.ftCount / @NoOfMonth)) > 0

	SELECT DISTINCT
		fl.RefCRMCustomerId	
	INTO #distinctCust
	FROM #CustomerOutput fl

	SELECT identification.IdNumber,
		ex.[Name] AS exName,
		dis.RefCRMCustomerId
	INTO #custSource  
	FROM dbo.CoreCRMIdentification identification  
	INNER JOIN #distinctCust dis ON dis.RefCRMCustomerId = identification.EntityId
	INNER JOIN dbo.RefCRMCustomer cust ON cust.RefCRMCustomerId = dis.RefCRMCustomerId   AND identification.RefEntityTypeId = cust.RefEntityTypeId
	INNER JOIN dbo.RefIdentificationType IdenType ON IdenType.RefIdentificationTypeId = identification.RefIdentificationTypeId AND IdenType.IsExternalSystem = 1 
	INNER JOIN dbo.RefExternalSystem ex ON ex.RefIdentificationTypeId = IdenType.RefIdentificationTypeId

	
	 SELECT DISTINCT 
			ft.RefCRMCustomerId AS CustomerId,
			ft.CustomerCode,
			ft.FirstName,
			ft.MiddleName,
			ft.LastName,
			@InternalStartDate AS StartDate,
			@InternalEndDate AS EndDate,
			ft.CurrentMonthTransactionCount,
			CAST(ft.AvgTransactionCount AS DECIMAL (19,2)) AS AvgTransactionCount,
			CAST(ft.PercentageJump AS DECIMAL (19,2)) AS PercentageJump,
			MonthsCount AS NumberOfMonths,
			STUFF(( SELECT ', '+ ( src.IdNumber +' - '  + src.exName )        
			  FROM #custSource src
				WHERE src.RefCRMCustomerId = ft.RefCRMCustomerId
			  FOR XML PATH('')),1,1,'') AS SourceSystemDetail,
			STUFF(( SELECT DISTINCT ', '+ (cl.ClientId)        
			  FROM #FinalAccessibleProductAccount  tr
			  INNER JOIN dbo.RefClient cl ON tr.RefCRMCustomerId = ft.RefCRMCustomerId AND  cl.RefClientId = tr.RefClientId
			  INNER JOIN #ftClient fc ON fc.RefClientId = cl.RefClientId

			FOR XML PATH('')),1,1,'') ProductAccountDetail  
	FROM 
		#CustomerOutput ft
		WHERE 
		ft.PercentageJump >= @PercentageJump
		AND
		NOT EXISTS
		  (
			SELECT 1 FROM dbo.CoreAlertRegisterCustomerCaseAlert dupCheck 
			WHERE (@InternalIsAlertDuplicationAllowed = 0)
			AND
				(dupCheck.RefCRMCustomerId = ft.RefCRMCustomerId
					AND dupCheck.RefAmlReportId = @AmlReportId
					AND dupCheck.AverageHoldingValue = CAST(ft.AvgTransactionCount AS DECIMAL (19,2))
					AND dupCheck.MoneyInCount = ft.CurrentMonthTransactionCount
					AND dupCheck.StartDate = @InternalStartDate
					AND dupCheck.EndDate = @InternalEndDate
					AND AverageMonths = @NoOfMonth
					AND MoneyInPercentage = CAST(ft.PercentageJump AS DECIMAL (19,2))) 
		  )

END
GO
--WEB-77889-RC-END
