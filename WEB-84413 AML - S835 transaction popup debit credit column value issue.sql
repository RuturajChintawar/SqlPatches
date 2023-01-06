
GO
ALTER PROCEDURE dbo.AML_HighValueOffMarketTransactioninaSpecifiedPeriodtxnDetails (
	@AlertId BIGINT,
	@RowsPerPage INT = NULL,
	@PageNo INT = 1
)
AS 
BEGIN

	DECLARE @InternalTxnIds VARCHAR(MAX), @CdslId INT, @TradingId INT,@ActiveStatusId INT, @NsdlId INT,@RowsPerPageInternal INT,@PageNoInternal INT,  @SegmentId INT
		, @NsdlType925 INT, @NsdlType926 INT,@NsdlType905 INT
	SELECT @SegmentId = core.RefSegmentEnumId ,@InternalTxnIds =  core.TransactionProfileRevisedJustification FROM dbo.CoreAmlScenarioAlert core WHERE  core.CoreAmlScenarioAlertId = @AlertId
	SET @RowsPerPageInternal = @RowsPerPage
	SET @PageNoInternal = @PageNo

	SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'CDSL'
	SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment = 'NSDL'
	SELECT @TradingId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'Trading'
	SELECT @ActiveStatusId = RefClientAccountStatusId FROM dbo.RefClientAccountStatus 
		WHERE RefClientDatabaseEnumId = @TradingId AND [Name] = 'Active'
	SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
	SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)' 
	SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = '905'

	IF ISNULL(@InternalTxnIds,'') = ''
	BEGIN
		RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;
		RETURN 50010
	END

	SELECT
		CONVERT(BIGINT, LTRIM(RTRIM(s.items))) AS TxnId,
		ROW_NUMBER() OVER (ORDER BY  CONVERT(BIGINT,s.items)) AS rn 
	INTO #TxnIds
	FROM dbo.Split(@InternalTxnIds, ',') s

	SELECT ids.*
	INTO  #tempIds
	FROM #TxnIds ids      
	WHERE ISNULL(@RowsPerPageInternal , 0) = 0 OR ids.rn BETWEEN ( ( ( @PageNoInternal - 1 ) * @RowsPerPageInternal ) + 1 ) AND @PageNoInternal * @RowsPerPageInternal 

	IF @SegmentId = @CdslId
	BEGIN
		SELECT
			dpTxn.CoreDpTransactionId AS TxnId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			CONVERT(VARCHAR, dpTxn.BusinessDate,103) AS BusinessDate,
			ISNULL(isin.[Name], '') AS ISIN,
			ISNULL(isin.[Description], '') AS ISINName,
			CASE WHEN dpTxn.BuySellFlag = 'C' OR dpTxn.BuySellFlag = 'B' THEN 'Credit'
				ELSE 'Debit' END AS DebitCredit,
			dpTxn.Quantity,
			dpTxn.CounterBOId AS OppClientId ,
			dpTxn.TransactionId,
			ISNULL(cl1.[Name], '') AS OppClientName,
			'' AS DpID,
			'' AS OppDpId,
			cl.PAN
		INTO #TxnDetails
		FROM #tempIds txns
		INNER JOIN dbo.CoreDpTransaction dpTxn ON txns.TxnId = dpTxn.CoreDpTransactionId
		INNER JOIN dbo.RefClient cl ON dpTxn.RefClientId = cl.RefClientId
		LEFT JOIN dbo.RefIsin isin ON dpTxn.RefIsinId = isin.RefIsinId
		LEFT JOIN dbo.RefClient cl1 ON ISNULL(dpTxn.CounterBoId, '') <> ''
			AND ((cl1.RefClientDatabaseEnumId = @CdslId AND cl1.ClientId = dpTxn.CounterBOId)
			OR (cl1.RefClientDatabaseEnumId = @NsdlId
				AND SUBSTRING(dpTxn.CounterBoId, 1, 2) = 'IN'
				AND cl1.DpId = CONVERT(INT, SUBSTRING(dpTxn.CounterBoId, 3, 6))
				AND cl1.ClientId = SUBSTRING(dpTxn.CounterBoId, 9, 8)))

	
	SELECT 
		txn.*,
		STUFF((SELECT DISTINCT ',' + client.ClientId 
	FROM #TxnDetails txn INNER JOIN dbo.RefClient client ON txn.PAN = client.PAN 
	AND client.RefClientDatabaseEnumId = @TradingId 
	AND ( client.RefClientAccountStatusId = @ActiveStatusId OR client.RefClientAccountStatusId IS NULL)
	FOR XML PATH('')), 1, 1, '') AS TradingCode
	FROM #TxnDetails txn

	END
	ELSE IF @SegmentId = @NsdlId
	BEGIN
		SELECT
			CASE WHEN cl.DpId IS NOT NULL
				THEN 'IN' + CONVERT(VARCHAR(100), cl.DpId) COLLATE DATABASE_DEFAULT
				ELSE '' END AS DpId,
			dpTxn.CoreDPTransactionChangeHistoryId AS TxnId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			CONVERT(VARCHAR,dpTxn.ExecutionDate,103) AS BusinessDate,
			ISNULL(isin.[Name], '') AS ISIN,
			ISNULL(isin.[Description], '') AS ISINName,
			CASE WHEN dpTxn.RefDpTransactionTypeId IN(@NsdlType905, @NsdlType926) THEN 'Credit'
				ELSE 'Debit' END AS DebitCredit,
			dpTxn.Quantity,
			
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode
				ELSE dpTxn.OtherDPId END, '') AS OppDpId,
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode + dpTxn.OtherClientCode
				ELSE CONVERT(VARCHAR(100), dpTxn.OtherClientId) COLLATE DATABASE_DEFAULT END, '') AS OppClientId,
			dpTxn.BusinessPartnerInstructionId AS TransactionId,
			ISNULL(cl1.[Name], '') AS OppClientName,
			cl.PAN
		INTO #TxnDetails2
		FROM #tempIds txns
		INNER JOIN dbo.CoreDPTransactionChangeHistory dpTxn ON txns.TxnId = dpTxn.CoreDPTransactionChangeHistoryId
		INNER JOIN dbo.RefClient cl ON dpTxn.RefClientId = cl.RefClientId
		LEFT JOIN dbo.RefIsin isin ON dpTxn.RefIsinId = isin.RefIsinId
		LEFT JOIN dbo.RefClient cl1 ON (dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				AND cl1.RefClientDatabaseEnumId = @CdslId
			AND cl1.ClientId = (dpTxn.OtherDPCode + dpTxn.OtherClientCode))
		OR (cl1.RefClientDatabaseEnumId = @NsdlId AND dpTxn.OtherDPId = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) 
			AND CONVERT(VARCHAR(100),dpTxn.OtherClientId) = cl1.ClientId)

		SELECT 
				txn.*,
				STUFF((SELECT DISTINCT ',' + client.ClientId 
		FROM #TxnDetails2 txn INNER JOIN dbo.RefClient client ON txn.PAN = client.PAN 
		AND client.RefClientDatabaseEnumId = @TradingId 
		AND ( client.RefClientAccountStatusId = @ActiveStatusId OR client.RefClientAccountStatusId IS NULL)
		FOR XML PATH('')), 1, 1, '') AS TradingCode
		FROM #TxnDetails2 txn
	END
	SELECT COUNT(ids.TxnId) AS txnCount
	FROM #TxnIds ids
END
GO
select * from RefClientSpecialCategory
select * from RefEntityType where RefEntityTypeId = 39
LinkRefClientRefClientSpecialCategory