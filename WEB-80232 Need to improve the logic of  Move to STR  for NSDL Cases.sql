
--WEB-80232-RC START
GO
ALTER PROCEDURE [dbo].[CoreStrSinTrn_PopulateStrFromCaseManager]
( 
	@AddedBy varchar(100),
	@RefClientId int =null,
	@CoreStrSinBrcId bigint,
	@CaseId BIGINT = null,
	@ClientIds VARCHAR(MAX)=null
)
as 
begin  

	declare @year int,@month int,@financialyear int,@TradeStartDate DATETIME, @TradeENdDAte DATETIME,
		@TnxSecurityMode INT, @TnxTypeId INT, @RefClientIdInternal INT, @CaseIdInternal BIGINT,
		@CoreStrSinBrcIdInternal BIGINT
	
	SET @RefClientIdInternal = @RefClientId
	SET @CaseIdInternal = @CaseId
	SET @CoreStrSinBrcIdInternal = @CoreStrSinBrcId
	
	declare @StartDate datetime,@EndDate datetime
	
	DECLARE @CashRefFinancialTransactionInstrumentTypeId INT, @ChequeRefFinancialTransactionInstrumentTypeId INT, @DemandRefFinancialTransactionInstrumentTypeId INT
			,@NetBanking INT, @other INT, @Others INT, @UPI INT, @RTGSNEFT INT

	
	declare @RefStrTransactionModeId int 
	
	SET @TnxTypeId = dbo.GetEnumValueId('AMLTransactionReportingType','STR')

	select @RefStrTransactionModeId=RefStrTransactionModeId from dbo.RefStrTransactionMode 
									where StrCode='X' AND TransactionReportingTypeRefEnumValueId = @TnxTypeId
									
	DECLARE @CashRefStrTransactionModeId INT, @ChequeRefStrTransactionModeId INT, @DemandRefStrTransactionModeId INT
			,@ElectronicRefStrTransactionModeId INT, @OtherRefStrTransactionModeId INT

	SET @TnxSecurityMode = ( SELECT RefStrTransactionModeId from dbo.RefStrTransactionMode 
							WHERE StrCode='G' AND TransactionReportingTypeRefEnumValueId = @TnxTypeId)
	
	declare @RefCurrencyId int 
	select @RefCurrencyId=RefCurrencyId from dbo.RefCurrency where Code='INR'
	
	declare @RefStrProductTypeId int , @EQProductType INT, @FUProductType INT, @OPProductType INT, @STProductType INT
	
	select @RefStrProductTypeId=RefStrProductTypeId from dbo.RefStrProductType where Code='ZZ'

	DECLARE @BSE_CASH INT, @NSE_CASH INT, @CDSL INT, @NSDL INT

	SET @BSE_CASH = (SELECT RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'BSE_CASH')
	SET @NSE_CASH = (SELECT RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSE_CASH')
	
	declare @RefStrTransactionTypeId int , @DMTnxTypeId INT, @DDTnxTypeId INT
	, @DRTnxTypeId INT, @DPTnxTypeId INT, @DCTnxTypeId INT, @DOTnxTypeId INT
	
	select @RefStrTransactionTypeId=RefStrTransactionTypeId from dbo.RefStrTransactionType where Code='ZZ'
	select @DMTnxTypeId =RefStrTransactionTypeId from dbo.RefStrTransactionType where Code='DM'
	
	
	declare @CoreStrSinAccId int 
	
	select @CoreStrSinAccId=CoreStrSinAccId from dbo.CoreStrSinAcc acc
	inner join dbo.RefClient client on acc.AccountNo=client.ClientId
	where client.RefClientId=@RefClientIdInternal and acc.CoreStrSinBrcId=@CoreStrSinBrcIdInternal

	
	DECLARE @FinancialId INT, @DPId INT, @TradeId INT

	SET @FinancialId = dbo.GetEnumValueId('AmlReportType','AmlReportType4')
	SET @dpid = dbo.GetEnumValueId('AmlReportType','AmlReportType2')
	SET @tradeid = dbo.GetEnumValueId('AmlReportType','AmlReportType3')

	SELECT
	clId.s AS ClientId
	INTO #ClientToConsider
	FROM dbo.ParseString(@ClientIds,',') clId

	CREATE TABLE #clients(RefClientId INT)

	IF EXISTS (SELECT 1 FROM #ClientToConsider)
	BEGIN
		INSERT INTO #clients(RefClientId)
		SELECT DISTINCT cl.RefClientId
		FROM dbo.RefClient cl
		INNER JOIN #ClientToConsider cls ON cls.ClientId=cl.ClientId 
		WHERE cl.PAN = (SELECT PAN FROM dbo.RefClient WHERE RefClientId = @RefClientIdInternal)	
	END
	ELSE
	BEGIN
		INSERT INTO #clients(RefClientId)
		SELECT DISTINCT cl.RefClientId
		FROM dbo.RefClient cl
		WHERE RefClientId = @RefClientIdInternal
	END


	
	IF EXISTS (SELECT TOP 1 1 FROM dbo.RefAmlReport al 
					INNER JOIN dbo.CoreAmlScenarioAlert temp ON al.AmlReportTypeRefEnumValueId = @FinancialId AND temp.RefAmlReportId = al.RefAmlReportId
					WHERE CoreAlertRegisterCaseId = @CaseIdInternal)
	BEGIN

		select @year= DATEPART(year,GETDATE())
		select @month= DATEPART(MONTH,GETDATE())
		
		if(@month=1  or @month=2 or  @month=3)
		begin 
		set @financialyear=@year-1
		end 
		else 
		begin
		set  @financialyear=@year
		end 
		
		set @StartDate= convert(datetime,convert(varchar(10),@financialyear)+'/'+'04'+'/'+'01')
		set @EndDate=GETDATE()
		

		select @CashRefStrTransactionModeId=RefStrTransactionModeId from dbo.RefStrTransactionMode 
										where StrCode='C' AND TransactionReportingTypeRefEnumValueId = @TnxTypeId

		select @ChequeRefStrTransactionModeId = RefStrTransactionModeId from dbo.RefStrTransactionMode 
										where StrCode='A' AND TransactionReportingTypeRefEnumValueId = @TnxTypeId

		select @DemandRefStrTransactionModeId=RefStrTransactionModeId from dbo.RefStrTransactionMode 
										where StrCode='D' AND TransactionReportingTypeRefEnumValueId = @TnxTypeId

		select @ElectronicRefStrTransactionModeId=RefStrTransactionModeId from dbo.RefStrTransactionMode 
										where StrCode='E' AND TransactionReportingTypeRefEnumValueId = @TnxTypeId

		select @OtherRefStrTransactionModeId=RefStrTransactionModeId from dbo.RefStrTransactionMode 
									where StrCode='Z' AND TransactionReportingTypeRefEnumValueId = @TnxTypeId
		
		select @CashRefFinancialTransactionInstrumentTypeId=RefFinancialTransactionInstrumentTypeId from dbo.RefFinancialTransactionInstrumentType 
										where [Name] = 'Cash'

		select @ChequeRefFinancialTransactionInstrumentTypeId = RefFinancialTransactionInstrumentTypeId from dbo.RefFinancialTransactionInstrumentType 
										where [Name] = 'Cheque'

		select @DemandRefFinancialTransactionInstrumentTypeId=RefFinancialTransactionInstrumentTypeId from dbo.RefFinancialTransactionInstrumentType 
										where [Name] = 'DDBCPO'

		select @NetBanking = RefFinancialTransactionInstrumentTypeId from dbo.RefFinancialTransactionInstrumentType 
										where [Name] = 'Net Banking'

		select @RTGSNEFT=RefFinancialTransactionInstrumentTypeId from dbo.RefFinancialTransactionInstrumentType 
										where [name] = 'RTGSNEFT'

		
		select @UPI =RefFinancialTransactionInstrumentTypeId from dbo.RefFinancialTransactionInstrumentType 
										where [Name] = 'UPI'

		select @Other = RefFinancialTransactionInstrumentTypeId from dbo.RefFinancialTransactionInstrumentType 
										where [Name] = 'other'

		select @Others = RefFinancialTransactionInstrumentTypeId from dbo.RefFinancialTransactionInstrumentType 
									where [name] = 'Others'

									
		select 
		acc.CoreStrSinAccId,
		trans.VoucherNo,
		trans.TransactionDate,		
		CASE WHEN trans.RefFinancialTransactionInstrumentTypeId = @CashRefFinancialTransactionInstrumentTypeId THEN @CashRefStrTransactionModeId
			 WHEN trans.RefFinancialTransactionInstrumentTypeId = @DemandRefFinancialTransactionInstrumentTypeId THEN @DemandRefStrTransactionModeId
			 WHEN trans.RefFinancialTransactionInstrumentTypeId = @ChequeRefFinancialTransactionInstrumentTypeId THEN @ChequeRefStrTransactionModeId
			 WHEN trans.RefFinancialTransactionInstrumentTypeId IN (@UPI, @RTGSNEFT, @NetBanking) THEN @ElectronicRefStrTransactionModeId
			 ELSE @OtherRefStrTransactionModeId END AS ModeId,
		case when voucher.Name='Payment' then 'D' else 'C' end AS Voucher,
		trans.Amount,
		trans.ClientBankAccountNo,
		RefSegmentId,
		trans.ClientBankName,
		trans.RefFinancialTransactionInstrumentTypeId
		INTO #FT
		from #clients cl 
		INNER JOIN dbo.CoreStrSinAcc acc ON cl.RefClientId = acc.RefClientId AND acc.CoreStrSinBrcId=@CoreStrSinBrcIdInternal
		INNER JOIN dbo.CoreFinancialTransaction  trans ON trans.RefClientId = cl.RefClientId
		inner join dbo.RefVoucherType voucher on voucher.RefVoucherTypeId=trans.RefVoucherTypeId
		where TransactionDate>=@StartDate and TransactionDate<=@EndDate 

		
		insert into dbo.CoreStrSinTrn
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
		select 
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
		GETDATE(),
		@AddedBy,
		GETDATE(),
		@RefStrProductTypeId,
		@RefStrTransactionTypeId,
		ft.ClientBankAccountNo,
		0,
		ft.RefSegmentId,
		ft.ClientBankName
		FROM #FT ft
		WHERE not exists (
			select top 1 1 from dbo.CoreStrSinTrn 
			where CoreStrSinAccId=ft.CoreStrSinAccId and  TransactionDate=ft.TransactionDate 
			and  TransactionId=ft.VoucherNo and  CreditDebit=ft.Voucher and Quantity=0
		)

		
		UPDATE acc
			SET acc.CumulativeCashDepositTurnover = temp.CumulativeCashDepositTurnover,
				acc.CumulativeCashWithdrawlTurnover = temp.CumulativeCashWithdrawlTurnover,
				acc.CumulativeCreditTurnover = temp.CumulativeCreditTurnover,
				acc.CumulativeDebitTurnover = temp.CumulativeDebitTurnover
		FROM (
			SELECT 
				CoreStrSinAccId,
				SUM(CASE WHEN Voucher = 'C' THEN Amount ELSE 0 END) CumulativeCreditTurnover,
				SUM(CASE WHEN Voucher = 'D' THEN Amount ELSE 0 END) CumulativeDebitTurnover,
				SUM(CASE WHEN Voucher = 'C' AND RefFinancialTransactionInstrumentTypeId = @CashRefFinancialTransactionInstrumentTypeId THEN Amount ELSE 0 END) CumulativeCashDepositTurnover,
				SUM(CASE WHEN Voucher = 'D' AND RefFinancialTransactionInstrumentTypeId = @CashRefFinancialTransactionInstrumentTypeId THEN Amount ELSE 0 END) CumulativeCashWithdrawlTurnover
			FROM #FT
			GROUP BY CoreStrSinAccId
		) temp
		INNER JOIN dbo.CoreStrSinAcc acc ON acc.CoreStrSinAccId = temp.CoreStrSinAccId


	END


	IF EXISTS ( SELECT TOP 1 1 FROM dbo.RefAmlReport al 
					INNER JOIN dbo.CoreAmlScenarioAlert temp ON al.AmlReportTypeRefEnumValueId = @TradeId AND temp.RefAmlReportId = al.RefAmlReportId
					WHERE CoreAlertRegisterCaseId = @CaseIdInternal )
	BEGIN

		
		select @EQProductType=RefStrProductTypeId from dbo.RefStrProductType where Code = 'EQ'
		select @FUProductType =RefStrProductTypeId from dbo.RefStrProductType where Code = 'FU'
		select @OPProductType =RefStrProductTypeId from dbo.RefStrProductType where Code = 'OP'

		SELECT 
			@TradeStartDate = MIN(ISNULL(TransactionDate, TransactionFromDate)), 
			@TradeENdDAte = MAX(ISNULL(TransactionDate, TransactionToDate))
		FROM dbo.RefAmlReport al 
		INNER JOIN dbo.CoreAmlScenarioAlert temp ON al.AmlReportTypeRefEnumValueId = @TradeId AND temp.RefAmlReportId = al.RefAmlReportId
		WHERE CoreAlertRegisterCaseId = @CaseIdInternal

		
		Select tr.CoreTradeId,
		tr.RefClientId,
		tr.TradeId,
		tr.TradeDate,
		CASE WHEN tr.BuySell='B' THEN 1 ELSE 0 END AS BuySell,
		tr.Rate,
		tr.Quantity,
		tr.RefInstrumentId,
		tr.RefSegmentId
		INTO #trades 
		from #clients cl
		INNER JOIN dbo.CoreTrade tr ON tr.RefClientId=cl.RefClientId
		WHERE TradeDate BETWEEN @TradeStartDate AND @TradeENdDAte

		insert into dbo.CoreStrSinTrn
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
		select 
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
			GETDATE(),
			@AddedBy,
			GETDATE(),
			CASE WHEN trans.RefSegmentId IN (@BSE_CASH, @NSE_CASH) THEN @EQProductType 
				 WHEN inType.[InstrumentType] LIKE 'FUT%' THEN @FUProductType
				 ELSE @OPProductType END,
			@DMTnxTypeId, 
			trans.RefSegmentId
		from #clients cl
		INNER JOIN dbo.CoreStrSinAcc acc ON cl.RefClientId = acc.RefClientId AND acc.CoreStrSinBrcId=@CoreStrSinBrcIdInternal
		INNER JOIN #trades  trans  ON trans.RefClientId = cl.RefClientId 
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trans.RefInstrumentId
		INNER JOIN dbo.RefInstrumentType inType on inType.RefInstrumentTypeId = inst.RefInstrumentTypeId
		--where TradeDate>=@TradeStartDate and TradeDate<=@TradeENdDAte
		WHERE not exists (
			select top 1 1 from dbo.CoreStrSinTrn strTnx
			where CoreStrSinAccId=acc.CoreStrSinAccId and TransactionDate=trans.TradeDate 
			and  (ISNUMERIC(TransactionId)=1 AND TransactionId=trans.TradeId) and CreditDebit=(CASE WHEN BuySell = 1 THEN 'C' ELSE 'D' END) 
			AND strTnx.Quantity= trans.Quantity
		)


	END
	
	IF EXISTS ( SELECT TOP 1 1 FROM dbo.RefAmlReport al 
					INNER JOIN dbo.CoreAmlScenarioAlert temp ON al.AmlReportTypeRefEnumValueId = @DpId AND temp.RefAmlReportId = al.RefAmlReportId
					WHERE CoreAlertRegisterCaseId = @CaseIdInternal )
	BEGIN

		SELECT 
			@TradeStartDate = MIN(ISNULL(TransactionDate, TransactionFromDate)), 
			@TradeENdDAte = MAX(ISNULL(TransactionDate, TransactionToDate))
		FROM dbo.RefAmlReport al 
		INNER JOIN dbo.CoreAmlScenarioAlert temp ON al.AmlReportTypeRefEnumValueId = @DpId AND temp.RefAmlReportId = al.RefAmlReportId
		WHERE CoreAlertRegisterCaseId = @CaseIdInternal
		
		select @DDTnxTypeId = RefStrTransactionTypeId from dbo.RefStrTransactionType where Code='DD'
		select @DRTnxTypeId = RefStrTransactionTypeId from dbo.RefStrTransactionType where Code='DR'
		select @DPTnxTypeId = RefStrTransactionTypeId from dbo.RefStrTransactionType where Code='DP'
		select @DCTnxTypeId = RefStrTransactionTypeId from dbo.RefStrTransactionType where Code='DC'
		select @DOTnxTypeId = RefStrTransactionTypeId from dbo.RefStrTransactionType where Code='DO'
		
		select @STProductType = RefStrProductTypeId from dbo.RefStrProductType where Code='ST'
		
		SET @NSDL = (SELECT RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSDL')
		SET @CDSL = (SELECT RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'CDSL')
		    
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
		 AND (dp.BusinessDate BETWEEN @TradeStartDate AND @TradeENdDAte)   

		 
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


		insert into dbo.CoreStrSinTrn
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
			Remarks,
			CoreFinancialTransactionId_NoFK
		)
		select 
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
			GETDATE(),
			@AddedBy,
			GETDATE(),
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
				ELSE 'Rate of the ISIN not available in DP bhav copy and Exchange bhav copy hence quantity mentioned' END,
			trans.CoreDpTransactionId
		from #tradeData trans
		INNER JOIN dbo.CoreStrSinAcc acc ON trans.RefClientId = acc.RefClientId AND acc.CoreStrSinBrcId=@CoreStrSinBrcIdInternal
		INNER JOIN dbo.RefIsin isi ON isi.RefIsinId = trans.RefIsinId
		LEFT JOIN dbo.RefDpTransactionType dpType ON dpType.RefDpTransactionTypeId = trans.RefDpTransactionTypeId
		LEFT JOIN #presentBhavIds pIds ON trans.RefIsinId = pIds.RefIsinId        
											AND trans.BusinessDate = pIds.BusinessDate        
		LEFT JOIN #finalNonDpBhavRates nonDpRates ON pIds.RefIsinId IS NULL        
											AND trans.RefIsinId = nonDpRates.RefIsinId AND trans.BusinessDate = nonDpRates.BusinessDate 
		WHERE not exists (
			select top 1 1 from dbo.CoreStrSinTrn strTnx
			where CoreStrSinAccId=acc.CoreStrSinAccId and TransactionDate=trans.BusinessDate 
			and  TransactionId=trans.TransactionId and CreditDebit=(CASE WHEN trans.BuySellFlag = 'D' OR trans.BuySellFlag = 'S' THEN 'D' ELSE 'C' END) 
			AND strTnx.Quantity= trans.Quantity
		)

	END

END
GO
--WEB-80232-RC END