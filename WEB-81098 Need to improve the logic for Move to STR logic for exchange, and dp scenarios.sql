--File:StoredProcedures:dbo:CoreStrSinTrn_PopulateStrFromCaseManager
--WEB-80232-RC START
GO
ALTER PROCEDURE [dbo].[CoreStrSinTrn_PopulateStrFromCaseManager]
( 
	@AddedBy VARCHAR(100),
	@RefClientId INT = NULL,
	@CoreStrSinBrcId BIGINT,
	@CaseId BIGINT = NULL,
	@ClientIds VARCHAR(MAX) = NULL
)
AS 
BEGIN  

	DECLARE @year INT,@month INT,@financialyear INT,@TradeStartDate DATETIME, @TradeEndDate DATETIME,@TnxSecurityMode INT, @TnxTypeId INT, @RefClientIdInternal INT, @CaseIdInternal BIGINT,@CoreStrSinAccId INT,
		@CoreStrSinBrcIdInternal BIGINT,@CurrDate DATETIME,@StartDate DATETIME,@EndDate DATETIME,@CashRefFinancialTransactionInstrumentTypeId INT, 
		@ChequeRefFinancialTransactionInstrumentTypeId INT, @DemandRefFinancialTransactionInstrumentTypeId INT,@NetBanking INT, @other INT, @Others INT, @UPI INT, @RTGSNEFT INT, @RefStrTransactionModeId INT ,
		@CashRefStrTransactionModeId INT, @ChequeRefStrTransactionModeId INT, @DemandRefStrTransactionModeId INT, @ElectronicRefStrTransactionModeId INT, @OtherRefStrTransactionModeId INT,@RefCurrencyId INT,
		@RefStrProductTypeId int , @EQProductType INT, @FUProductType INT, @OPProductType INT, @STProductType INT,@BSE_CASH INT, @NSE_CASH INT, @CDSL INT, @NSDL INT,@RefStrTransactionTypeId INT , @DMTnxTypeId INT,
		@DDTnxTypeId INT, @DRTnxTypeId INT, @DPTnxTypeId INT, @DCTnxTypeId INT, @DOTnxTypeId INT, @financialId INT, @DPId INT, @TradeId INT,@pan VARCHAR(20)
	 
	SET @CurrDate = GETDATE();
	SET @RefClientIdInternal = @RefClientId
	SET @CaseIdInternal = @CaseId
	SET @CoreStrSinBrcIdInternal = @CoreStrSinBrcId

	SET @TnxTypeId = dbo.GetEnumValueId('AMLTransactionReportingType','STR')
	SET @RefStrTransactionModeId = (SELECT RefStrTransactionModeId FROM dbo.RefStrTransactionMode WHERE TransactionReportingTypeRefEnumValueId = @TnxTypeId AND StrCode='X'  )
	SET @TnxSecurityMode = (SELECT RefStrTransactionModeId FROM dbo.RefStrTransactionMode WHERE TransactionReportingTypeRefEnumValueId = @TnxTypeId AND StrCode='G')

	SET @RefCurrencyId = (SELECT RefCurrencyId FROM dbo.RefCurrency WHERE Code='INR')
	
	SET @BSE_CASH = (SELECT RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'BSE_CASH')
	SET @NSE_CASH = (SELECT RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSE_CASH')
	
	SET @RefStrProductTypeId = (SELECT RefStrProductTypeId FROM dbo.RefStrProductType WHERE Code='ZZ')
	SET @RefStrTransactionTypeId = (SELECT RefStrTransactionTypeId FROM dbo.RefStrTransactionType WHERE Code='ZZ')
	SET @DMTnxTypeId = (SELECT RefStrTransactionTypeId FROM dbo.RefStrTransactionType WHERE Code='DM')
	
	SET @CoreStrSinAccId = (SELECT acc.CoreStrSinAccId FROM dbo.CoreStrSinAcc acc
	INNER JOIN dbo.RefClient client ON client.RefClientId = @RefClientIdInternal AND acc.CoreStrSinBrcId = @CoreStrSinBrcIdInternal AND acc.AccountNo = client.ClientId)
	
	SET @dpid = dbo.GetEnumValueId('AmlReportType','AmlReportType2')
	SET @tradeid = dbo.GetEnumValueId('AmlReportType','AmlReportType3')
	SET @financialId = dbo.GetEnumValueId('AmlReportType','AmlReportType4')

	SET @EQProductType = (SELECT RefStrProductTypeId FROM dbo.RefStrProductType WHERE Code = 'EQ')
	SET @FUProductType = (SELECT RefStrProductTypeId FROM dbo.RefStrProductType WHERE Code = 'FU')
	SET @OPProductType = (SELECT  RefStrProductTypeId FROM dbo.RefStrProductType WHERE Code = 'OP')
	SET @STProductType = (SELECT RefStrProductTypeId FROM dbo.RefStrProductType WHERE Code = 'ST')

	SET @DDTnxTypeId = (SELECT RefStrTransactionTypeId FROM dbo.RefStrTransactionType WHERE Code='DD')
	SET @DRTnxTypeId = (SELECT RefStrTransactionTypeId FROM dbo.RefStrTransactionType WHERE Code='DR')
	SET @DPTnxTypeId = (SELECT RefStrTransactionTypeId FROM dbo.RefStrTransactionType WHERE Code='DP')
	SET @DCTnxTypeId = (SELECT RefStrTransactionTypeId FROM dbo.RefStrTransactionType WHERE Code='DC')
	SET @DOTnxTypeId = (SELECT RefStrTransactionTypeId FROM dbo.RefStrTransactionType WHERE Code='DO')
		
	SET @NSDL = (SELECT RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSDL')
	SET @CDSL = (SELECT RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'CDSL')

	

	SELECT
		clId.s AS ClientId
	INTO #ClientToConsider
	FROM dbo.ParseString(@ClientIds,',') clId

	CREATE TABLE #clients(RefClientId INT)

	IF EXISTS (SELECT TOP 1 1 FROM #ClientToConsider)
	BEGIN
		SET @pan = (SELECT PAN FROM dbo.RefClient WHERE RefClientId = @RefClientIdInternal)	

		INSERT INTO #clients(RefClientId)
		SELECT DISTINCT cl.RefClientId
		FROM dbo.RefClient cl
		INNER JOIN #ClientToConsider cls ON cls.ClientId = cl.ClientId
		WHERE cl.PAN = @pan

	END
	ELSE
	BEGIN
		INSERT INTO #clients(RefClientId)
		SELECT DISTINCT cl.RefClientId
		FROM dbo.RefClient cl
		WHERE cl.RefClientId = @RefClientIdInternal
	END


	
	IF EXISTS (SELECT TOP 1 1 FROM dbo.RefAmlReport al 
					INNER JOIN dbo.CoreAmlScenarioAlert temp ON al.AmlReportTypeRefEnumValueId = @financialId AND temp.RefAmlReportId = al.RefAmlReportId
					WHERE CoreAlertRegisterCaseId = @CaseIdInternal)
	BEGIN

		SELECT @year = DATEPART(YEAR,@CurrDate)
		SELECT @month = DATEPART(MONTH,@CurrDate)
		
		IF(@month = 1  OR @month = 2 OR  @month = 3)
		BEGIN 
			SET @financialyear = @year-1
		END 
		ELSE 
		BEGIN
			SET  @financialyear = @year
		END 
		
		SET @StartDate= CONVERT(DATETIME,CONVERT(VARCHAR(10), @financialyear)+'/'+'04'+'/'+'01')
		SET @EndDate = GETDATE()
		

		SET @CashRefStrTransactionModeId =( SELECT RefStrTransactionModeId FROM dbo.RefStrTransactionMode WHERE TransactionReportingTypeRefEnumValueId = @TnxTypeId AND StrCode='C')
		SET @ChequeRefStrTransactionModeId = (SELECT RefStrTransactionModeId FROM dbo.RefStrTransactionMode WHERE TransactionReportingTypeRefEnumValueId = @TnxTypeId AND StrCode='A') 
		SET @DemandRefStrTransactionModeId = (SELECT  RefStrTransactionModeId FROM dbo.RefStrTransactionMode WHERE TransactionReportingTypeRefEnumValueId = @TnxTypeId AND StrCode='D')
		SET @ElectronicRefStrTransactionModeId = (SELECT RefStrTransactionModeId FROM dbo.RefStrTransactionMode WHERE TransactionReportingTypeRefEnumValueId = @TnxTypeId AND StrCode='E') 
		SET @OtherRefStrTransactionModeId = (SELECT RefStrTransactionModeId FROM dbo.RefStrTransactionMode WHERE TransactionReportingTypeRefEnumValueId = @TnxTypeId AND StrCode='Z' ) 
		
		SET @CashRefFinancialTransactionInstrumentTypeId = (SELECT RefFinancialTransactionInstrumentTypeId FROM dbo.RefFinancialTransactionInstrumentType WHERE [Name] = 'Cash')
		SET @ChequeRefFinancialTransactionInstrumentTypeId = (SELECT RefFinancialTransactionInstrumentTypeId FROM dbo.RefFinancialTransactionInstrumentType WHERE [Name] = 'Cheque')
		SET @DemandRefFinancialTransactionInstrumentTypeId = (SELECT RefFinancialTransactionInstrumentTypeId FROM dbo.RefFinancialTransactionInstrumentType WHERE [Name] = 'DDBCPO')
		SET @NetBanking = (SELECT RefFinancialTransactionInstrumentTypeId FROM dbo.RefFinancialTransactionInstrumentType WHERE [Name] = 'Net Banking')
		SET @RTGSNEFT = (SELECT RefFinancialTransactionInstrumentTypeId FROM dbo.RefFinancialTransactionInstrumentType WHERE [name] = 'RTGSNEFT')
		SET @UPI = (SELECT RefFinancialTransactionInstrumentTypeId FROM dbo.RefFinancialTransactionInstrumentType WHERE [Name] = 'UPI')
		SET @Other = (SELECT RefFinancialTransactionInstrumentTypeId FROM dbo.RefFinancialTransactionInstrumentType WHERE [Name] = 'other')
		SET @Others = (SELECT RefFinancialTransactionInstrumentTypeId FROM dbo.RefFinancialTransactionInstrumentType WHERE [name] = 'Others')

									
		SELECT 
			acc.CoreStrSinAccId,
			trans.VoucherNo,
			trans.TransactionDate,		
			CASE WHEN trans.RefFinancialTransactionInstrumentTypeId = @CashRefFinancialTransactionInstrumentTypeId THEN @CashRefStrTransactionModeId
				 WHEN trans.RefFinancialTransactionInstrumentTypeId = @DemandRefFinancialTransactionInstrumentTypeId THEN @DemandRefStrTransactionModeId
				 WHEN trans.RefFinancialTransactionInstrumentTypeId = @ChequeRefFinancialTransactionInstrumentTypeId THEN @ChequeRefStrTransactionModeId
				 WHEN trans.RefFinancialTransactionInstrumentTypeId IN (@UPI, @RTGSNEFT, @NetBanking) THEN @ElectronicRefStrTransactionModeId
				 ELSE @OtherRefStrTransactionModeId END AS ModeId,
			CASE WHEN voucher.[Name]='Payment' THEN 'D' ELSE 'C' END AS Voucher,
			trans.Amount,
			trans.ClientBankAccountNo,
			RefSegmentId,
			trans.ClientBankName,
			trans.RefFinancialTransactionInstrumentTypeId
		INTO #financialTransaction
		FROM #clients cl 
		INNER JOIN dbo.CoreStrSinAcc acc ON cl.RefClientId = acc.RefClientId AND acc.CoreStrSinBrcId = @CoreStrSinBrcIdInternal
		INNER JOIN dbo.CoreFinancialTransaction  trans ON trans.RefClientId = cl.RefClientId
		INNER JOIN dbo.RefVoucherType voucher ON voucher.RefVoucherTypeId = trans.RefVoucherTypeId
		WHERE TransactionDate >= @StartDate AND TransactionDate <= @EndDate 

		
		INSERT INTO dbo.CoreStrSinTrn
		(
			CoreStrSinAccId,
			RecordType,
			TransactionId,
			TransactionDate,
			RefStrTransactionModeId,
			CreditDebit,
			Amount,
			RefCurrencyId,
			FundsDisposition,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn,
			RefStrProductTypeId,
			RefStrTransactionTypeId,
			RelatedAccountNum,
			Quantity,
			RefSegmentId,
			RelatedInstitutionName
		)
		SELECT 
			ft.CoreStrSinAccId,
			'TRN',
			ft.VoucherNo,
			ft.TransactionDate,		
			ft.ModeId,
			ft.Voucher,
			ft.Amount,
			@RefCurrencyId,
			'X',
			@AddedBy,
			@CurrDate,
			@AddedBy,
			@CurrDate,
			@RefStrProductTypeId,
			@RefStrTransactionTypeId,
			ft.ClientBankAccountNo,
			0,
			ft.RefSegmentId,
			ft.ClientBankName
		FROM #financialTransaction ft
		LEFT JOIN dbo.CoreStrSinTrn  acc ON acc.CoreStrSinAccId = ft.CoreStrSinAccId AND acc.Quantity = 0 AND  TransactionId = ft.VoucherNo AND  acc.CreditDebit = ft.Voucher 
		AND  acc.TransactionDate =ft.TransactionDate 
		WHERE acc.CoreStrSinAccId IS NULL

		SELECT 
			CoreStrSinAccId,
			SUM(CASE WHEN Voucher = 'C' THEN Amount ELSE 0 END) CumulativeCreditTurnover,
			SUM(CASE WHEN Voucher = 'D' THEN Amount ELSE 0 END) CumulativeDebitTurnover,
			SUM(CASE WHEN Voucher = 'C' AND RefFinancialTransactionInstrumentTypeId = @CashRefFinancialTransactionInstrumentTypeId THEN Amount ELSE 0 END) CumulativeCashDepositTurnover,
			SUM(CASE WHEN Voucher = 'D' AND RefFinancialTransactionInstrumentTypeId = @CashRefFinancialTransactionInstrumentTypeId THEN Amount ELSE 0 END) CumulativeCashWithdrawlTurnover
		INTO #tempTradeData
		FROM #financialTransaction
		GROUP BY CoreStrSinAccId
		
		UPDATE acc
			SET acc.CumulativeCashDepositTurnover = temp.CumulativeCashDepositTurnover,
				acc.CumulativeCashWithdrawlTurnover = temp.CumulativeCashWithdrawlTurnover,
				acc.CumulativeCreditTurnover = temp.CumulativeCreditTurnover,
				acc.CumulativeDebitTurnover = temp.CumulativeDebitTurnover
		FROM #tempTradeData temp
		INNER JOIN dbo.CoreStrSinAcc acc ON acc.CoreStrSinAccId = temp.CoreStrSinAccId


	END


	IF EXISTS( ( SELECT TOP 1 1 FROM dbo.RefAmlReport al INNER JOIN dbo.CoreAmlScenarioAlert temp  ON temp.CoreAlertRegisterCaseId = @CaseIdInternal AND 
					al.AmlReportTypeRefEnumValueId = @TradeId AND temp.RefAmlReportId = al.RefAmlReportId))
					
	BEGIN

		SELECT 
			@TradeStartDate = MIN(ISNULL(TransactionDate, TransactionFromDate)), 
			@TradeEndDate = MAX(ISNULL(TransactionDate, TransactionToDate))
		FROM dbo.RefAmlReport al 
		INNER JOIN dbo.CoreAmlScenarioAlert temp ON al.AmlReportTypeRefEnumValueId = @TradeId AND temp.RefAmlReportId = al.RefAmlReportId
		WHERE CoreAlertRegisterCaseId = @CaseIdInternal

		SELECT tr.CoreTradeId,
			tr.RefClientId,
			tr.TradeId,
			tr.TradeDate,
			CASE WHEN tr.BuySell = 'B' THEN 1 ELSE 0 END AS BuySell,
			tr.Rate,
			tr.Quantity,
			tr.RefInstrumentId,
			tr.RefSegmentId
		INTO #trades 
		FROM #clients cl
		INNER JOIN dbo.CoreTrade tr ON tr.RefClientId = cl.RefClientId
		WHERE TradeDate BETWEEN @TradeStartDate AND @TradeEndDate

		INSERT INTO dbo.CoreStrSinTrn
		(
			CoreStrSinAccId,
			RecordType,
			TransactionId,
			TransactionDate,
			RefStrTransactionModeId,
			CreditDebit,
			SecurityId,
			Quantity,
			Rate,
			Amount,
			RefCurrencyId,
			FundsDisposition,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn,
			RefStrProductTypeId,
			RefStrTransactionTypeId,
			RefSegmentId
		)
		SELECT 
			acc.CoreStrSinAccId,
			'TRN',
			trans.TradeId,
			trans.TradeDate,
			@TnxSecurityMode,
			CASE WHEN BuySell = 1 THEN 'C' ELSE 'D' END,
			inst.Isin,
			trans.Quantity,
			trans.Rate,
			ISNULL(trans.Rate,1) * ISNULL(trans.Quantity,1),
			@RefCurrencyId,
			'X',
			@AddedBy,
			@CurrDate,
			@AddedBy,
			@CurrDate,
			CASE WHEN trans.RefSegmentId IN (@BSE_CASH, @NSE_CASH) THEN @EQProductType 
				 WHEN inType.[InstrumentType] LIKE 'FUT%' THEN @FUProductType
				 ELSE @OPProductType END,
			@DMTnxTypeId, 
			trans.RefSegmentId
		FROM #clients cl
		INNER JOIN dbo.CoreStrSinAcc acc ON cl.RefClientId = acc.RefClientId AND acc.CoreStrSinBrcId = @CoreStrSinBrcIdInternal
		INNER JOIN #trades trans ON trans.RefClientId = cl.RefClientId 
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trans.RefInstrumentId
		INNER JOIN dbo.RefInstrumentType inType ON inType.RefInstrumentTypeId = inst.RefInstrumentTypeId
		LEFT JOIN dbo.CoreStrSinTrn strTnx ON strTnx.CoreStrSinAccId = acc.CoreStrSinAccId  AND  (ISNUMERIC(TransactionId) = 1 AND TransactionId = trans.TradeId)
			AND strTnx.Quantity = trans.Quantity AND strTnx.TransactionDate = trans.TradeDate AND strTnx.CreditDebit = (CASE WHEN BuySell = 1 THEN 'C' ELSE 'D' END) 
		WHERE strTnx.CoreStrSinTrnId IS NULL

		DROP TABLE #trades
		
	END
	
	IF EXISTS ( SELECT TOP 1 1 FROM dbo.RefAmlReport al 
				INNER JOIN dbo.CoreAmlScenarioAlert temp ON al.AmlReportTypeRefEnumValueId = @DpId AND CoreAlertRegisterCaseId = @CaseIdInternal AND temp.RefAmlReportId = al.RefAmlReportId)
	BEGIN

		SELECT 
			@TradeStartDate = MIN(ISNULL(TransactionDate, TransactionFromDate)), 
			@TradeEndDate = MAX(ISNULL(TransactionDate, TransactionToDate))
		FROM dbo.RefAmlReport al 
		INNER JOIN dbo.CoreAmlScenarioAlert temp ON al.AmlReportTypeRefEnumValueId = @DpId AND temp.RefAmlReportId = al.RefAmlReportId
		WHERE CoreAlertRegisterCaseId = @CaseIdInternal
		
		SELECT        
			 dp.CoreDpTransactionId,  
			 dp.RefClientId,        
			 dp.RefSegmentId,        
			 dp.RefIsinId,        
			 dp.Quantity,        
			 dp.BusinessDate,        
			 dp.ReasonForTrade ,
			 BuySellFlag,
			 TransactionId,
			 RefDpTransactionTypeId,
			 SettlementId,
			 CounterBOId
		INTO #tradeData
		FROM #clients cl
		INNER JOIN dbo.CoreDpTransaction dp ON cl.RefClientId = dp.RefClientId   
		AND dp.RefSegmentId IN (@NSDL, @CDSL)        
		 AND (dp.BusinessDate BETWEEN @TradeStartDate AND @TradeEndDate)   

		 
		 SELECT DISTINCT        
			  RefIsinId,        
			  BusinessDate        
		 INTO #selectedIsins        
		 FROM #tradeData        
		       
		 SELECT DISTINCT          
			 bhav.RefIsinId,          
			 bhav.[Close],        
			 bhav.RefSegmentId,        
			 isin.BusinessDate,        
			 ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId, isin.BusinessDate ORDER BY bhav.RefSegmentId) AS RN          
		 INTO #presentBhavIdsTemp          
		 FROM #selectedIsins isin          
		 INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = isin.RefIsinId        
		 WHERE bhav.[Date] = isin.BusinessDate        
		       
		 SELECT        
		  RefIsinId,        
		  [Close],        
		  BusinessDate        
		 INTO #presentBhavIds        
		 FROM #presentBhavIdsTemp temp          
		 WHERE temp.RN = 1        
		       
		 DROP TABLE #presentBhavIdsTemp        
		            
		       
		 SELECT DISTINCT        
		  isin.RefIsinId,        
		  isin.BusinessDate        
		 INTO #notPresentBhavIds        
		 FROM #selectedIsins isin        
		 LEFT JOIN #presentBhavIds ids ON isin.RefIsinId = ids.RefIsinId        
		  AND isin.BusinessDate = ids.BusinessDate        
		 WHERE ids.RefIsinId IS NULL        
		       
		 DROP TABLE #selectedIsins        
		       
		 SELECT DISTINCT        
			  ids.RefIsinId,        
			  ids.BusinessDate,        
			  inst.RefSegmentId,        
			  bhav.[Close],        
			  ROW_NUMBER() OVER (PARTITION BY ids.RefIsinId, ids.BusinessDate, inst.RefSegmentId ORDER BY bhav.[Date] DESC) AS RN        
		 INTO #nonDpBhavRates        
		 FROM #notPresentBhavIds ids        
		 INNER JOIN dbo.RefIsin isin ON ids.RefIsinId = isin.RefIsinId        
		 INNER JOIN dbo.RefInstrument inst ON isin.[Name] = inst.Isin        
		  AND inst.RefSegmentId IN (@BSE_CASH, @NSE_CASH) AND LTRIM(RTRIM(inst.[Status])) = 'A'        
		 INNER JOIN dbo.CoreBhavCopy bhav ON bhav.RefInstrumentId = inst.RefInstrumentId AND bhav.RefSegmentId = inst.RefSegmentId        
		  AND bhav.[Date] = ids.BusinessDate        
		 WHERE bhav.[Date] = ids.BusinessDate       
		          
		 DROP TABLE #notPresentBhavIds        
		       
		 SELECT DISTINCT        
		  bhav1.RefIsinId,        
		  bhav1.BusinessDate,        
		  bhav1.[Close]        
		 INTO #finalNonDpBhavRates        
		 FROM #nonDpBhavRates bhav1        
		 WHERE RN = 1 AND (bhav1.RefSegmentId = @BSE_CASH OR NOT EXISTS 
		 (SELECT TOP 1 1 FROM #nonDpBhavRates bhav2        
		  WHERE bhav1.RefIsinId = bhav2.RefIsinId AND bhav1.BusinessDate = bhav2.BusinessDate        
		   AND bhav2.RefSegmentId = @BSE_CASH))        
		       
		 DROP TABLE #nonDpBhavRates   


		INSERT INTO dbo.CoreStrSinTrn
		(
			CoreStrSinAccId,
			RecordType,
			TransactionId,
			CoreFinancialTransactionId_NoFK,
			TransactionDate,
			RefStrTransactionModeId,
			CreditDebit,
			SecurityId,
			Quantity,
			Rate,
			Amount,
			RefCurrencyId,
			FundsDisposition,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn,
			RefStrProductTypeId,
			RefStrTransactionTypeId,
			RefSegmentId,
			Remarks
		)
		SELECT 
			acc.CoreStrSinAccId,
			'TRN',
			CASE WHEN trans.RefSegmentId = @CDSL THEN trans.TransactionId ELSE NULL END,
			trans.CoreDpTransactionId,
			trans.BusinessDate,
			@TnxSecurityMode,
			CASE WHEN trans.BuySellFlag = 'D' OR trans.BuySellFlag = 'S' THEN 'D' ELSE 'C' END,
			isi.[Name],
			trans.Quantity,
			COALESCE(pIds.[Close], nonDpRates.[Close]),
			CASE WHEN pIds.RefIsinId IS NOT NULL OR nonDpRates.RefIsinId IS NOT NULL THEN (trans.Quantity * COALESCE(pIds.[Close], nonDpRates.[Close]))
				ELSE trans.Quantity END,
			@RefCurrencyId,
			'X',
			@AddedBy,
			@CurrDate,
			@AddedBy,
			@CurrDate,
			@STProductType,
			CASE WHEN dpType.[Name] = 'Demat' THEN 	@DDTnxTypeId
				 WHEN dpType.[Name] = 'Remat' THEN @DRTnxTypeId
				 WHEN dpType.[Name] = 'Pledge' THEN @DPTnxTypeId
				 WHEN dpType.[Name] IN ('CA','Auto CA') THEN @DCTnxTypeId
				 WHEN dpType.[Name] = 'Transactions across DPs' AND trans.SettlementId IS NOT NULL AND trans.SettlementId <> '' THEN @DMTnxTypeId
				 WHEN dpType.[Name] = 'Transactions across DPs' AND (ISNULL(trans.SettlementId,'') <> '' OR ISNULL(CounterBOId,'') <> '') THEN @DOTnxTypeId
				 WHEN dpType.[Name] = 'Inter-depository' AND trans.CounterBOId LIKE 'IN3%' THEN @DOTnxTypeId
				 WHEN dpType.[Name] = 'Inter-depository' AND trans.CounterBOId NOT LIKE 'IN3%' THEN @DMTnxTypeId
				 ELSE @RefStrTransactionTypeId END,
			trans.RefSegmentId,
			CASE WHEN pIds.RefIsinId IS NOT NULL OR nonDpRates.RefIsinId IS NOT NULL THEN NULL
				ELSE 'Rate of the ISIN not available in DP bhav copy and Exchange bhav copy hence quantity mentioned' END
		FROM #tradeData trans
		INNER JOIN dbo.CoreStrSinAcc acc ON trans.RefClientId = acc.RefClientId AND acc.CoreStrSinBrcId=@CoreStrSinBrcIdInternal
		INNER JOIN dbo.RefIsin isi ON isi.RefIsinId = trans.RefIsinId
		LEFT JOIN dbo.RefDpTransactionType dpType ON dpType.RefDpTransactionTypeId = trans.RefDpTransactionTypeId
		LEFT JOIN #presentBhavIds pIds ON trans.RefIsinId = pIds.RefIsinId AND trans.BusinessDate = pIds.BusinessDate        
		LEFT JOIN #finalNonDpBhavRates nonDpRates ON pIds.RefIsinId IS NULL AND trans.RefIsinId = nonDpRates.RefIsinId AND trans.BusinessDate = nonDpRates.BusinessDate
		LEFT JOIN  dbo.CoreStrSinTrn strTnx ON strTnx.CoreStrSinAccId = acc.CoreStrSinAccId  AND  strTnx.TransactionId = trans.TransactionId AND strTnx.Quantity= trans.Quantity AND strTnx.TransactionDate = trans.BusinessDate 
				AND CreditDebit=(CASE WHEN trans.BuySellFlag = 'D' OR trans.BuySellFlag = 'S' THEN 'D' ELSE 'C' END) 
		WHERE strTnx.CoreStrSinTrnId IS NULL

		DROP TABLE #tradeData
		

	END
	IF EXISTS ( SELECT TOP 1 1 FROM  dbo.CoreAlert alert WHERE CoreAlertRegisterCaseId = @CaseIdInternal )
	BEGIN
		
		SELECT 
			@TradeStartDate = MIN(al.AlertDate), 
			@TradeEndDate = MAX(al.AlertDate)
		FROM dbo.CoreAlert al 
		WHERE al.CoreAlertRegisterCaseId = @CaseIdInternal

		SELECT tr.CoreTradeId,
			tr.RefClientId,
			tr.TradeId,
			tr.TradeDate,
			CASE WHEN tr.BuySell = 'B' THEN 1 ELSE 0 END AS BuySell,
			tr.Rate,
			tr.Quantity,
			tr.RefInstrumentId,
			tr.RefSegmentId
		INTO #exchangeScenariotrades 
		FROM #clients cl
		INNER JOIN dbo.CoreTrade tr ON tr.RefClientId=cl.RefClientId
		WHERE TradeDate BETWEEN @TradeStartDate AND @TradeEndDate

		INSERT INTO dbo.CoreStrSinTrn
		(
			CoreStrSinAccId,
			RecordType,
			TransactionId,
			TransactionDate,
			RefStrTransactionModeId,
			CreditDebit,
			SecurityId,
			Quantity,
			Rate,
			Amount,
			RefCurrencyId,
			FundsDisposition,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn,
			RefStrProductTypeId,
			RefStrTransactionTypeId,
			RefSegmentId
		)
		SELECT 
			acc.CoreStrSinAccId,
			'TRN',
			trans.TradeId,
			trans.TradeDate,
			@TnxSecurityMode,
			CASE WHEN BuySell = 1 THEN 'C' ELSE 'D' END,
			inst.Isin,
			trans.Quantity,
			trans.Rate,
			ISNULL(trans.Rate,1) * ISNULL(trans.Quantity,1),
			@RefCurrencyId,
			'X',
			@AddedBy,
			@CurrDate,
			@AddedBy,
			@CurrDate,
			CASE WHEN trans.RefSegmentId IN (@BSE_CASH, @NSE_CASH) THEN @EQProductType 
				 WHEN inType.[InstrumentType] LIKE 'FUT%' THEN @FUProductType
				 ELSE @OPProductType END,
			@DMTnxTypeId, 
			trans.RefSegmentId
		FROM #clients cl
		INNER JOIN dbo.CoreStrSinAcc acc ON cl.RefClientId = acc.RefClientId AND acc.CoreStrSinBrcId = @CoreStrSinBrcIdInternal
		INNER JOIN #exchangeScenariotrades  trans  ON trans.RefClientId = cl.RefClientId 
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trans.RefInstrumentId
		INNER JOIN dbo.RefInstrumentType inType on inType.RefInstrumentTypeId = inst.RefInstrumentTypeId
		LEFT  JOIN dbo.CoreStrSinTrn strTnx ON strTnx.CoreStrSinAccId = acc.CoreStrSinAccId AND (ISNUMERIC(TransactionId) = 1 AND TransactionId=trans.TradeId)
											AND strTnx.Quantity = trans.Quantity
											AND TransactionDate = trans.TradeDate
											AND CreditDebit = (CASE WHEN BuySell = 1 THEN 'C' ELSE 'D' END) 
			
		WHERE strTnx.CoreStrSinTrnId IS NULL

		DROP TABLE #exchangeScenariotrades

	END
	IF EXISTS ( SELECT TOP 1 1 FROM dbo.CoreDpSuspiciousTransaction temp WHERE temp.CoreAlertRegisterCaseId = @CaseIdInternal )
	BEGIN

		SELECT 
			@TradeStartDate = MIN(TransactionDate), 
			@TradeEndDate = MAX(TransactionDate)
		FROM dbo.CoreDpSuspiciousTransaction temp WHERE temp.CoreAlertRegisterCaseId = @CaseIdInternal
		
		SELECT        
			 dp.CoreDpTransactionId,  
			 dp.RefClientId,        
			 dp.RefSegmentId,        
			 dp.RefIsinId,        
			 dp.Quantity,        
			 dp.BusinessDate,        
			 dp.ReasonForTrade ,
			 BuySellFlag,
			 TransactionId,
			 RefDpTransactionTypeId,
			 SettlementId,
			 CounterBOId
		INTO #fiuAlertTradeData
		FROM #clients cl
		INNER JOIN dbo.CoreDpTransaction dp ON cl.RefClientId = dp.RefClientId AND dp.RefSegmentId IN (@NSDL, @CDSL)        
		 AND (dp.BusinessDate BETWEEN @TradeStartDate AND @TradeEndDate)   

		 
		 SELECT DISTINCT        
		  RefIsinId,        
		  BusinessDate        
		 INTO #FiuselectedIsins        
		 FROM #fiuAlertTradeData
		 
		       
		 SELECT DISTINCT          
			 bhav.RefIsinId,          
			 bhav.[Close],        
			 bhav.RefSegmentId,        
			 isin.BusinessDate,        
			 ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId, isin.BusinessDate ORDER BY bhav.RefSegmentId) AS RN          
		 INTO #FiupresentBhavIdsTemp          
		 FROM #FiuselectedIsins isin          
		 INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = isin.RefIsinId        
		 WHERE bhav.[Date] = isin.BusinessDate        
		       
		 SELECT        
		  RefIsinId,        
		  [Close],        
		  BusinessDate        
		 INTO #FiupresentBhavIds        
		 FROM #FiupresentBhavIdsTemp temp          
		 WHERE temp.RN = 1        
		       
		      
		            
		       
		 SELECT DISTINCT        
		  isin.RefIsinId,        
		  isin.BusinessDate        
		 INTO #FiunotPresentBhavIds        
		 FROM #FiuselectedIsins isin        
		 LEFT JOIN #FiupresentBhavIds ids ON isin.RefIsinId = ids.RefIsinId        
		  AND isin.BusinessDate = ids.BusinessDate        
		 WHERE ids.RefIsinId IS NULL        
		       
		 DROP TABLE #FiuselectedIsins        
		       
		 SELECT DISTINCT        
		  ids.RefIsinId,        
		  ids.BusinessDate,        
		  inst.RefSegmentId,        
		  bhav.[Close],        
		  ROW_NUMBER() OVER (PARTITION BY ids.RefIsinId, ids.BusinessDate, inst.RefSegmentId ORDER BY bhav.[Date] DESC) AS RN        
		 INTO #FiunonDpBhavRates        
		 FROM #FiunotPresentBhavIds ids        
		 INNER JOIN dbo.RefIsin isin ON ids.RefIsinId = isin.RefIsinId        
		 INNER JOIN dbo.RefInstrument inst ON isin.[Name] = inst.Isin        
		  AND inst.RefSegmentId IN (@BSE_CASH, @NSE_CASH) AND LTRIM(RTRIM(inst.[Status])) = 'A'        
		 INNER JOIN dbo.CoreBhavCopy bhav ON bhav.RefInstrumentId = inst.RefInstrumentId AND bhav.RefSegmentId = inst.RefSegmentId        
		  AND bhav.[Date] = ids.BusinessDate        
		 WHERE bhav.[Date] = ids.BusinessDate       
		          
		 DROP TABLE #FiunotPresentBhavIds        
		       
		 SELECT DISTINCT        
		  bhav1.RefIsinId,        
		  bhav1.BusinessDate,        
		  bhav1.[Close]        
		 INTO #FiufinalNonDpBhavRates        
		 FROM #FiunonDpBhavRates bhav1        
		 WHERE RN = 1 AND (bhav1.RefSegmentId = @BSE_CASH OR NOT EXISTS 
		 (SELECT TOP 1 1 FROM #FiunonDpBhavRates bhav2        
		  WHERE bhav1.RefIsinId = bhav2.RefIsinId AND bhav1.BusinessDate = bhav2.BusinessDate        
		   AND bhav2.RefSegmentId = @BSE_CASH))        
		       
		 DROP TABLE #FiunonDpBhavRates   


		INSERT INTO dbo.CoreStrSinTrn
		(
			CoreStrSinAccId,
			RecordType,
			TransactionId,
			CoreFinancialTransactionId_NoFK,
			TransactionDate,
			RefStrTransactionModeId,
			CreditDebit,
			SecurityId,
			Quantity,
			Rate,
			Amount,
			RefCurrencyId,
			FundsDisposition,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn,
			RefStrProductTypeId,
			RefStrTransactionTypeId,
			RefSegmentId,
			Remarks
		)
		SELECT 
			acc.CoreStrSinAccId,
			'TRN',
			CASE WHEN trans.RefSegmentId = @CDSL THEN trans.TransactionId ELSE NULL END,
			trans.CoreDpTransactionId,
			trans.BusinessDate,
			@TnxSecurityMode,
			CASE WHEN trans.BuySellFlag = 'D' OR trans.BuySellFlag = 'S' THEN 'D' ELSE 'C' END,
			isi.[Name],
			trans.Quantity,
			ISNULL(pIds.[Close], nonDpRates.[Close]),
			CASE WHEN pIds.RefIsinId IS NOT NULL OR nonDpRates.RefIsinId IS NOT NULL THEN (trans.Quantity * ISNULL(pIds.[Close], nonDpRates.[Close]))
				ELSE trans.Quantity END,
			@RefCurrencyId,
			'X',
			@AddedBy,
			@CurrDate,
			@AddedBy,
			@CurrDate,
			@STProductType,
			CASE WHEN dpType.[Name] = 'Demat' THEN 	@DDTnxTypeId
				 WHEN dpType.[Name] = 'Remat' THEN @DRTnxTypeId
				 WHEN dpType.[Name] = 'Pledge' THEN @DPTnxTypeId
				 WHEN dpType.[Name] IN ('CA','Auto CA') THEN @DCTnxTypeId
				 WHEN dpType.[Name] = 'Transactions across DPs' AND trans.SettlementId IS NOT NULL AND trans.SettlementId <> '' THEN @DMTnxTypeId
				 WHEN dpType.[Name] = 'Transactions across DPs' AND (ISNULL(trans.SettlementId,'') <> '' OR ISNULL(CounterBOId,'') <> '') THEN @DOTnxTypeId
				 WHEN dpType.[Name] = 'Inter-depository' AND trans.CounterBOId LIKE 'IN3%' THEN @DOTnxTypeId
				 WHEN dpType.[Name] = 'Inter-depository' AND trans.CounterBOId NOT LIKE 'IN3%' THEN @DMTnxTypeId
				 ELSE @RefStrTransactionTypeId END,
			trans.RefSegmentId,
			CASE WHEN pIds.RefIsinId IS NOT NULL OR nonDpRates.RefIsinId IS NOT NULL THEN NULL
				ELSE 'Rate of the ISIN not available in DP bhav copy and Exchange bhav copy hence quantity mentioned' END
		FROM #fiuAlertTradeData trans
		INNER JOIN dbo.CoreStrSinAcc acc ON trans.RefClientId = acc.RefClientId AND acc.CoreStrSinBrcId=@CoreStrSinBrcIdInternal
		INNER JOIN dbo.RefIsin isi ON isi.RefIsinId = trans.RefIsinId
		LEFT JOIN dbo.RefDpTransactionType dpType ON dpType.RefDpTransactionTypeId = trans.RefDpTransactionTypeId
		LEFT JOIN #FiupresentBhavIds pIds ON trans.RefIsinId = pIds.RefIsinId AND trans.BusinessDate = pIds.BusinessDate        
		LEFT JOIN #FiufinalNonDpBhavRates nonDpRates ON pIds.RefIsinId IS NULL AND trans.RefIsinId = nonDpRates.RefIsinId AND trans.BusinessDate = nonDpRates.BusinessDate 
		LEFT JOIN dbo.CoreStrSinTrn strTnx ON  strTnx.CoreStrSinAccId=acc.CoreStrSinAccId AND strTnx.Quantity= trans.Quantity
			AND  strTnx.TransactionId = trans.TransactionId AND strTnx.TransactionDate=trans.BusinessDate  AND CreditDebit = (CASE WHEN trans.BuySellFlag = 'D' OR trans.BuySellFlag = 'S' THEN 'D' ELSE 'C' END) 
			
		WHERE strTnx.CoreStrSinTrnId IS NULL
		
		DROP TABLE #fiuAlertTradeData

	END
END
GO
--WEB-80232-RC END

