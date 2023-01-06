--File:StoredProcedures:dbo:AML_GetS840ClientOffMarketTransferOfSpecificReasonConsolidateVisFairValueTxnDetails
--RC-WEB-82998 START
GO
 ALTER PROCEDURE dbo.AML_GetS840ClientOffMarketTransferOfSpecificReasonConsolidateVisFairValueTxnDetails    
(    
 @AlertId BIGINT,
 @RowsPerPage INT = NULL,
 @PageNo INT = 1
)    
AS    
BEGIN    
 DECLARE @AlertIdInternal BIGINT, @SegmentId INT, @CdslId INT, @NsdlId INT, @TxnIds VARCHAR(MAX),    
   @CdslDbId INT, @TradingDBId INT, @NSDLDbId INT, @NsdlType925 INT, @NsdlType926 INT , @RowsPerPageInternal INT,@PageNoInternal INT,
   @RefClientId INT, @CientPan VARCHAR(20), @TradingCode VARCHAR(MAX)    
   
 SET @AlertIdInternal = @AlertId    
 SET @RowsPerPageInternal = @RowsPerPage
 SET @PageNoInternal = @PageNo
 
   
 SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'CDSL'    
 SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'NSDL'    
   
 SELECT @CdslDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'    
 SELECT @TradingDBId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'Trading'    
 SELECT @NSDLDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'    
   
 SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'        
 SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)'    
   
 SELECT @SegmentId = RefSegmentEnumId, @TxnIds = TransactionProfileRevisedJustification, @RefClientId = RefClientId
 FROM dbo.CoreAmlScenarioAlert WHERE CoreAmlScenarioAlertId = @AlertIdInternal    

 SELECT @CientPan = PAN FROM dbo.RefClient WHERE RefClientId = @RefClientId

 SET @TradingCode = STUFF((
SELECT ', ' + cl.ClientId
FROM dbo.RefClient cl
WHERE RefClientDatabaseEnumId = @TradingDBId AND PAN = @CientPan
FOR XML PATH('')
),1,2,'')
   
 SET @TxnIds = LTRIM(RTRIM(@TxnIds))    

 IF ISNULL(@TxnIds,'') = ''    
 BEGIN    
  RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;    
  RETURN 50010    
 END    
   
 IF  @TxnIds LIKE '%Total Transaction Is Very Large. Total Transaction Count Is%'  
 BEGIN    
  RAISERROR (@TxnIds, 11, 1) WITH SETERROR;    
  RETURN 50010    
 END  
 
 CREATE TABLE #reasonData    
 (          
  RefSegmentId INT,          
  ReasonCode INT,    
  [Description] VARCHAR(100) COLLATE DATABASE_DEFAULT    
 )    
   
 INSERT INTO #reasonData VALUES (@CdslId,1,'Gift')    
 INSERT INTO #reasonData VALUES (@CdslId,2,'Off Market Sale')    
 INSERT INTO #reasonData VALUES (@CdslId,16,'Donation')    
 INSERT INTO #reasonData VALUES (@NsdlId,1,'Off Market Sale')    
 INSERT INTO #reasonData VALUES (@NsdlId,92,'Gift')    
 INSERT INTO #reasonData VALUES (@NsdlId,93,'Donation')    
   
 SELECT    
  CONVERT(BIGINT,t.items) AS TxnId,
  ROW_NUMBER() OVER (ORDER BY  CONVERT(BIGINT,t.items)) AS rn
 INTO #allTxnIds    
 FROM dbo.Split(@TxnIds,',') t  
 
  SELECT ids.*
  INTO  #tempIds
  FROM #allTxnIds ids      
  WHERE ISNULL(@RowsPerPageInternal, 0) = 0 OR ids.rn BETWEEN ( ( ( @PageNoInternal - 1 ) * @RowsPerPageInternal ) + 1 ) AND @PageNoInternal * @RowsPerPageInternal  
   
 IF @SegmentId = @CdslId    
 BEGIN    
  SELECT    
   tids.TxnId,    
   cl.ClientId,    
   cl.[Name] AS ClientName,    
   REPLACE(CONVERT(VARCHAR(20),txn.BusinessDate,106),' ', '/') AS BusinessDate,    
   isin.[Name] AS ISIN,    
   isin.[Description] AS ISINName,    
   'Debit' AS DebitCredit,    
   txn.Quantity,    
   ISNULL(oppCl.ClientId, txn.CounterBOId) AS OppClientId,    
   ISNULL(oppCl.[Name],'') AS OppClientName,    
   txn.TransactionId,    
   rd.[Description] AS ReasonCode,    
   '' AS DpID,    
   '' AS OppDpId,    
   @TradingCode AS TradingCode,    
   seg.Segment AS SegmentName    
  FROM #tempIds tids    
  INNER JOIN dbo.CoreDpTransaction txn ON txn.CoreDpTransactionId = tids.TxnId    
  INNER JOIN dbo.RefClient cl ON cl.RefClientId = txn.RefClientId    
  INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = txn.RefIsinId    
  INNER JOIN #reasonData rd ON rd.RefSegmentId = txn.RefSegmentId AND rd.ReasonCode = txn.ReasonForTrade    
  INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = txn.RefSegmentId    
  LEFT JOIN dbo.RefClient oppCl ON oppCl.RefClientDatabaseEnumId in (@CdslDbId, @NSDLDbId) AND oppCl.ClientId = txn.CounterBOId  
  ORDER BY txn.BusinessDate    
 END    
   
 ELSE IF @SegmentId = @NsdlId    
 BEGIN    
  SELECT    
   txns.TxnId,    
   CASE WHEN cl.DpId IS NOT NULL    
    THEN 'IN' + CONVERT(VARCHAR(100), cl.DpId) COLLATE DATABASE_DEFAULT    
    ELSE '' END AS DpId,    
   cl.ClientId,    
   cl.[Name] AS ClientName,    
   REPLACE(CONVERT(VARCHAR(20),dpTxn.ExecutionDate,106) ,' ', '/') AS BusinessDate,    
   isin.[Name] AS ISIN,    
   isin.[Description] AS ISINName,    
   'Debit' AS DebitCredit,    
   dpTxn.Quantity,    
   ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)    
    THEN dpTxn.OtherDPCode    
    ELSE dpTxn.OtherDPId END, '') AS OppDpId,    
   ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)    
    THEN dpTxn.OtherDPCode + dpTxn.OtherClientCode    
    ELSE CONVERT(VARCHAR(100), dpTxn.OtherClientId) COLLATE DATABASE_DEFAULT END, '') AS OppClientId,    
   ISNULL(cl1.[Name], '') AS OppClientName,    
   dpTxn.BusinessPartnerInstructionId AS TransactionId,    
   rd.[Description] AS ReasonCode,    
   @TradingCode AS TradingCode,    
   seg.Segment AS SegmentName    
  FROM #tempIds txns    
  INNER JOIN dbo.CoreDPTransactionChangeHistory dpTxn ON txns.TxnId = dpTxn.CoreDPTransactionChangeHistoryId    
  INNER JOIN dbo.RefClient cl ON dpTxn.RefClientId = cl.RefClientId    
  INNER JOIN dbo.RefIsin isin ON dpTxn.RefIsinId = isin.RefIsinId    
  INNER JOIN #reasonData rd ON rd.RefSegmentId = dpTxn.RefSegmentId AND CONVERT(VARCHAR(500), rd.ReasonCode) = dpTxn.TransferReasonCode    
  INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = dpTxn.RefSegmentId    
  LEFT JOIN dbo.RefClient cl1 ON (dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926) AND cl1.RefClientDatabaseEnumId in (@NSDLDbId, @CdslDbId)    
    AND cl1.ClientId = (dpTxn.OtherDPCode + dpTxn.OtherClientCode))    
   OR (cl1.RefClientDatabaseEnumId in (@NSDLDbId, @CdslDbId) AND dpTxn.OtherDPId = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT)    
    AND CONVERT(VARCHAR(100),dpTxn.OtherClientId) = cl1.ClientId)
  ORDER BY dpTxn.ExecutionDate    
 
 END  
 SELECT COUNT(ids.TxnId) AS txnTotalCount
  FROM #allTxnIds ids
END    
GO
--RC-WEB-82998 END
--File:StoredProcedures:dbo:AML_GetS843DPTransactionOneToManyCDSLAndNSDLTxnDetails
--RC-WEB-82998 START
GO
	ALTER PROCEDURE dbo.AML_GetS843DPTransactionOneToManyCDSLAndNSDLTxnDetails
	(
		@AlertId BIGINT,
		@RowsPerPage INT = NULL,
		@PageNo INT = 1
	)
	AS
	BEGIN
		DECLARE @AlertIdInternal BIGINT, @SegmentId INT, @CdslId INT, @NsdlId INT, @TxnIds VARCHAR(MAX),
				@CdslDbId INT, @TradingDBId INT, @NSDLDbId INT,@NsdlType905 INT, @NsdlType925 INT, @NsdlType926 INT, @RowsPerPageInternal INT,@PageNoInternal INT    

		SET @AlertIdInternal = @AlertId
		SET @RowsPerPageInternal = @RowsPerPage
		SET @PageNoInternal = @PageNo


		SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'CDSL'
		SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'NSDL'

		SELECT @CdslDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'
		SELECT @NSDLDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'

		SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 905 AND [Name] = 'Receipt Free of Payment (Inter DP) Instruction'
		SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
		SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)' 

		SELECT @SegmentId = RefSegmentEnumId, @TxnIds = [Description] FROM dbo.CoreAmlScenarioAlert WHERE CoreAmlScenarioAlertId = @AlertIdInternal

		SET @TxnIds = LTRIM(RTRIM(@TxnIds))

		IF ISNULL(@TxnIds,'') = ''
		BEGIN
			RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;
			RETURN 50010
		END

		SELECT
			CONVERT(BIGINT,t.items) AS TxnId,
			ROW_NUMBER() OVER (ORDER BY  CONVERT(BIGINT,t.items)) AS rn 
		INTO #allTxnIds
		FROM dbo.Split(@TxnIds,',') t

		SELECT ids.*
		INTO  #tempIds
		FROM #allTxnIds ids      
		WHERE ISNULL(@RowsPerPageInternal , 0)= 0 OR ids.rn BETWEEN ( ( ( @PageNoInternal - 1 ) * @RowsPerPageInternal ) + 1 ) AND @PageNoInternal * @RowsPerPageInternal 

		IF @SegmentId = @CdslId
		BEGIN
			---nsdl database
			SELECT 
			CASE WHEN SUBSTRING(txn.CounterBoId,1,2) ='IN' THEN 1
				ELSE 0
			END isIN,
			SUBSTRING(txn.CounterBoId,9,8) ClientId,
			SUBSTRING(txn.CounterBoId,3,6) dpid,
			txn.CoreDpTransactionId txnId
			INTO #oppTemp
			FROM dbo.CoreDpTransaction txn
			INNER JOIN #tempIds ids ON ids.TxnId = txn.CoreDpTransactionId

			SELECT
				tids.TxnId,
				cl.ClientId,
				cl.[Name] AS ClientName,
				REPLACE(CONVERT(VARCHAR(20),txn.BusinessDate,106),' ', '/') AS BusinessDate,
				isin.[Name] AS ISIN,
				isin.[Description] AS ISINName,
				CASE WHEN txn.BuySellFlag = 'D' OR txn.BuySellFlag = 'S' THEN 'Debit'
					ELSE 'Credit' END AS DebitCredit,
				txn.Quantity,
				ISNULL(oppCl.ClientId, '') AS OppClientId,
				ISNULL(oppCl.[Name],'') AS OppClientName,
				txn.TransactionId,
				txn.CounterBoId AS DpID,
				'' AS OppDpId,
				seg.Segment AS SegmentName
			FROM #tempIds tids
			INNER JOIN dbo.CoreDpTransaction txn ON txn.CoreDpTransactionId = tids.TxnId
			INNER JOIN dbo.RefClient cl ON cl.RefClientId = txn.RefClientId
			INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = txn.RefIsinId
			INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = txn.RefSegmentId
			INNER JOIN #oppTemp opp ON opp.txnId = txn.CoreDpTransactionId
			LEFT JOIN dbo.RefClient oppCl ON (oppCl.RefClientDatabaseEnumId = @CdslDbId AND oppCl.ClientId = txn.CounterBoId)
			OR  (oppCl.RefClientDatabaseEnumId = @NSDLDbId AND opp.isIN = 1 AND  oppCl.ClientId = opp.ClientId AND CONVERT(VARCHAR(100),oppCl.DpId) = opp.dpid ) 
			ORDER BY txn.BusinessDate
		END

		ELSE IF @SegmentId = @NsdlId
		BEGIN
			SELECT
				txns.TxnId,
				CASE WHEN cl.DpId IS NOT NULL
					THEN 'IN' + CONVERT(VARCHAR(100), cl.DpId) COLLATE DATABASE_DEFAULT
					ELSE '' END AS DpId,
				cl.ClientId,
				cl.[Name] AS ClientName,
				REPLACE(CONVERT(VARCHAR(20),dpTxn.ExecutionDate,106) ,' ', '/') AS BusinessDate,
				isin.[Name] AS ISIN,	
				isin.[Description] AS ISINName,
				CASE WHEN dpTxn.RefDpTransactionTypeId IN(@NsdlType905, @NsdlType926) THEN 'Credit'
					ELSE 'Debit' END AS DebitCredit,
				dpTxn.Quantity,
				ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
					THEN dpTxn.OtherDPCode
					ELSE dpTxn.OtherDPId END, '') AS OppDpId,
				ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
					THEN dpTxn.OtherDPCode + dpTxn.OtherClientCode
					ELSE CONVERT(VARCHAR(100), dpTxn.OtherClientId) COLLATE DATABASE_DEFAULT END, '') AS OppClientId,
				ISNULL(cl1.[Name], '') AS OppClientName,
				dpTxn.BusinessPartnerInstructionId AS TransactionId,
				seg.Segment AS SegmentName
			FROM #tempIds txns
			INNER JOIN dbo.CoreDPTransactionChangeHistory dpTxn ON txns.TxnId = dpTxn.CoreDPTransactionChangeHistoryId
			INNER JOIN dbo.RefClient cl ON dpTxn.RefClientId = cl.RefClientId
			INNER JOIN dbo.RefIsin isin ON dpTxn.RefIsinId = isin.RefIsinId
			INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = dpTxn.RefSegmentId
			LEFT JOIN dbo.RefClient cl1 ON (dpTxn.RefDpTransactionTypeId IN (@NsdlType925 , @NsdlType926) AND cl1.RefClientDatabaseEnumId = @NSDLDbId
					AND cl1.ClientId = dpTxn.OtherClientCode AND dpTxn.OtherDPCode = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) )
				OR (cl1.RefClientDatabaseEnumId = @NSDLDbId AND dpTxn.OtherDPId = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) 
					AND CONVERT(VARCHAR(100), dpTxn.OtherClientId) = cl1.ClientId)
				OR(cl1.RefClientDatabaseEnumId = @CdslDbId AND cl1.ClientId = dpTxn.OtherDPCode + dpTxn.OtherClientCode )
			ORDER BY dpTxn.ExecutionDate
		END
		SELECT COUNT(ids.TxnId) AS txnCount
		FROM #allTxnIds ids
	END
GO
--RC-WEB-82998 END
--File:StoredProcedures:dbo:AML_GetS844DPTransactionManyToOneCDSLAndNSDLTxnDetails
--RC-WEB-82998 START
GO
ALTER PROCEDURE dbo.AML_GetS844DPTransactionManyToOneCDSLAndNSDLTxnDetails
(
	@AlertId BIGINT,
	@RowsPerPage INT = NULL,
	@PageNo INT = 1
)
AS
BEGIN
	DECLARE @AlertIdInternal BIGINT, @SegmentId INT, @CdslId INT, @NsdlId INT, @TxnIds VARCHAR(MAX),
			@CdslDbId INT, @TradingDBId INT, @NSDLDbId INT, @NsdlType925 INT, @NsdlType926 INT, @RowsPerPageInternal INT,@PageNoInternal INT    

	SET @AlertIdInternal = @AlertId
	SET @RowsPerPageInternal = @RowsPerPage
	SET @PageNoInternal = @PageNo
	

	SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'CDSL'
	SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'NSDL'

	SELECT @CdslDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'
	SELECT @NSDLDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'

	SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
	SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)' 

	SELECT @SegmentId = RefSegmentEnumId, @TxnIds = [Description] FROM dbo.CoreAmlScenarioAlert WHERE CoreAmlScenarioAlertId = @AlertIdInternal

	SET @TxnIds = LTRIM(RTRIM(@TxnIds))

	IF ISNULL(@TxnIds,'') = ''
	BEGIN
		RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;
		RETURN 50010
	END

	SELECT
		CONVERT(BIGINT,t.items) AS TxnId,
		ROW_NUMBER() OVER (ORDER BY  CONVERT(BIGINT,t.items)) AS rn 
	INTO #allTxnIds
	FROM dbo.Split(@TxnIds,',') t

	SELECT 
		ids.*
	INTO  #tempIds
	FROM #allTxnIds ids      
	WHERE ISNULL(@RowsPerPageInternal , 0)= 0 OR  ids.rn BETWEEN ( ( ( @PageNoInternal - 1 ) * @RowsPerPageInternal ) + 1 ) AND @PageNoInternal * @RowsPerPageInternal 

	IF @SegmentId = @CdslId
	BEGIN
		SELECT DISTINCT
			dp.RefIsinId,      
			dp.BusinessDate
		INTO #selectedIsins
		FROM #tempIds txn
		INNER JOIN dbo.CoreDpTransaction dp ON dp.CoreDpTransactionId = txn.TxnId

		SELECT DISTINCT        
		   bhav.RefIsinId,        
		   bhav.[Close],      
		   bhav.RefSegmentId,      
		   isin.BusinessDate,      
		   ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId , isin.BusinessDate ORDER BY bhav.RefSegmentId) AS RN        
		 INTO #presentBhavIdsTemp        
		 FROM #selectedIsins isin        
		 INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = isin.RefIsinId       
		 WHERE bhav.[Date] = isin.BusinessDate   

		 SELECT       
			temp.RefIsinId,        
			temp.[Close] ,
			temp.BusinessDate
		INTO #presentBhavIds        
		FROM #presentBhavIdsTemp temp        
		WHERE (temp.RN = 1)
		
		---nsdl database
		SELECT 
		CASE WHEN SUBSTRING(txn.CounterBoId,1,2) ='IN' THEN 1
			ELSE 0
		END isIN,
		SUBSTRING(txn.CounterBoId,9,8) ClientId,
		SUBSTRING(txn.CounterBoId,3,6) dpid,
		txn.CoreDpTransactionId txnId
		INTO #oppTemp
		FROM dbo.CoreDpTransaction txn
		INNER JOIN #tempIds ids ON ids.TxnId = txn.CoreDpTransactionId

		

		SELECT
			tids.TxnId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),txn.BusinessDate,106),' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,
			isin.[Description] AS ISINName,
			'Credit' DebitCredit,
			txn.Quantity,
			bhav.[Close] AS Rate,
			(txn.Quantity * bhav.[Close]) AS [Value],
			ISNULL(txn.CounterBoId, '') AS OppClientId,
			ISNULL(oppCl.[Name],'') AS OppClientName,
			txn.TransactionId,
			
			txn.CounterBoId AS DpID,
			'' AS OppDpId,
			seg.Segment AS SegmentName
		FROM #tempIds tids
		INNER JOIN dbo.CoreDpTransaction txn ON txn.CoreDpTransactionId = tids.TxnId
		INNER JOIN dbo.RefClient cl ON cl.RefClientId = txn.RefClientId
		INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = txn.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = txn.RefSegmentId
		INNER JOIN #presentBhavIds bhav ON bhav.RefIsinId = txn.RefIsinId AND bhav.BusinessDate = txn.BusinessDate
		INNER JOIN #oppTemp opp ON opp.txnId = txn.CoreDpTransactionId
		LEFT JOIN dbo.RefClient oppCl ON (oppCl.RefClientDatabaseEnumId = @CdslDbId AND oppCl.ClientId = txn.CounterBoId) OR (oppCl.RefClientDatabaseEnumId = @NSDLDbId AND opp.isIN = 1 AND  oppCl.ClientId = opp.ClientId AND CONVERT(VARCHAR(100),oppCl.DpId) = opp.dpid ) 
		ORDER BY txn.BusinessDate


		DROP TABLE  #presentBhavIds
		DROP TABLE #presentBhavIdsTemp
	END

	ELSE IF @SegmentId = @NsdlId
	BEGIN
		SELECT DISTINCT
			dp.RefIsinId,      
			dp.ExecutionDate
		INTO #selectedIsinsnsdl
		FROM #tempIds txn
		INNER JOIN dbo.CoreDPTransactionChangeHistory dp ON dp.CoreDPTransactionChangeHistoryId = txn.TxnId

		SELECT DISTINCT        
		   bhav.RefIsinId,        
		   bhav.[Close],      
		   bhav.RefSegmentId,      
		   isin.ExecutionDate,      
		   ROW_NUMBER() OVER (PARTITION BY isin.RefIsinId , isin.ExecutionDate ORDER BY bhav.RefSegmentId) AS RN        
		 INTO #presentBhavIdsTempnsdl        
		 FROM #selectedIsinsnsdl isin        
		 INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = isin.RefIsinId       
		 WHERE bhav.[Date] = isin.ExecutionDate   

		 SELECT       
			temp.RefIsinId,        
			temp.[Close] ,
			temp.ExecutionDate
		INTO #presentBhavIdsnsdl        
		FROM #presentBhavIdsTempnsdl temp        
		WHERE (temp.RN = 1)


		SELECT
			txns.TxnId,
			CASE WHEN cl.DpId IS NOT NULL
				THEN 'IN' + CONVERT(VARCHAR(100), cl.DpId) COLLATE DATABASE_DEFAULT
				ELSE '' END AS DpId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),dpTxn.ExecutionDate,106) ,' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,	
			isin.[Description] AS ISINName,
			 'Credit' AS DebitCredit,
			dpTxn.Quantity,
			bhav.[Close] AS Rate,
			(dpTxn.Quantity * bhav.[Close]) AS [Value],
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode
				ELSE dpTxn.OtherDPId END, '') AS OppDpId,
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode + dpTxn.OtherClientCode
				ELSE CONVERT(VARCHAR(100), dpTxn.OtherClientId) COLLATE DATABASE_DEFAULT END, '') AS OppClientId,
			ISNULL(cl1.[Name], '') AS OppClientName,
			dpTxn.BusinessPartnerInstructionId AS TransactionId,
			seg.Segment AS SegmentName
		FROM #tempIds txns
		INNER JOIN dbo.CoreDPTransactionChangeHistory dpTxn ON txns.TxnId = dpTxn.CoreDPTransactionChangeHistoryId
		INNER JOIN dbo.RefClient cl ON dpTxn.RefClientId = cl.RefClientId
		INNER JOIN dbo.RefIsin isin ON dpTxn.RefIsinId = isin.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = dpTxn.RefSegmentId
		LEFT JOIN #presentBhavIdsnsdl bhav ON bhav.RefIsinId = dptxn.RefIsinId AND bhav.ExecutionDate = dpTxn.ExecutionDate
		LEFT JOIN dbo.RefClient cl1 ON (dpTxn.RefDpTransactionTypeId IN (@NsdlType925 , @NsdlType926) AND cl1.RefClientDatabaseEnumId = @NSDLDbId
				AND cl1.ClientId = dpTxn.OtherClientCode AND dpTxn.OtherDPCode = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) )
			OR (cl1.RefClientDatabaseEnumId = @NSDLDbId AND dpTxn.OtherDPId = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) 
				AND CONVERT(VARCHAR(200),dpTxn.OtherClientId) COLLATE DATABASE_DEFAULT = cl1.ClientId)
			OR(cl1.RefClientDatabaseEnumId = @CdslDbId AND cl1.ClientId = dpTxn.OtherDPCode + dpTxn.OtherClientCode )
			
		ORDER BY dpTxn.ExecutionDate
	END
	SELECT 
	COUNT(ids.TxnId) AS txnCount
	FROM #allTxnIds ids
END
GO
--RC-WEB-82998 END
--File:StoredProcedures:dbo:AML_GetS811PreferentialAllotmentTxnDetails
--RC-WEB-82998 START
GO
ALTER PROCEDURE dbo.AML_GetS811PreferentialAllotmentTxnDetails
(
	@AlertId BIGINT,
	@RowsPerPage INT = NULL,
	@PageNo INT = 1

)
AS
BEGIN
	DECLARE @AlertIdInternal BIGINT, @SegmentId INT, @CdslId INT, @NsdlId INT,
			@CdslDbId INT, @NSDLDbId INT, @NsdlType925 INT, @NsdlType926 INT, @NsdlType905 INT, @NsdlType904 INT, @RowsPerPageInternal INT,@PageNoInternal INT    

	SET @AlertIdInternal = @AlertId
	SET @RowsPerPageInternal = @RowsPerPage
	SET @PageNoInternal = @PageNo


	SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'CDSL'
	SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'NSDL'

	SELECT @CdslDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'
	SELECT @NSDLDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'

	SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType 
	WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
	
	SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType
	WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)'

	SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = '905'
	SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = '904'

	SELECT @SegmentId = RefSegmentEnumId FROM dbo.CoreAmlScenarioAlert WHERE CoreAmlScenarioAlertId = @AlertIdInternal

	SELECT
		trans.TransactionId AS TxnId,
		ROW_NUMBER() OVER (ORDER BY trans.TransactionId) AS rn 
	INTO #allTxnIds
	FROM dbo.CoreAmlScenarioAlertDetail trans
	WHERE trans.CoreAmlScenarioAlertId = @AlertIdInternal

	IF (SELECT TOP 1 1 FROM #allTxnIds) IS NULL
	BEGIN
		RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;
		RETURN 50010
	END

	SELECT 
		ids.*
	INTO  #tempIds
	FROM #allTxnIds ids      
	WHERE ISNULL(@RowsPerPageInternal,0)=0 OR ids.rn BETWEEN ( ( ( @PageNoInternal - 1 ) * @RowsPerPageInternal ) + 1 ) AND @PageNoInternal * @RowsPerPageInternal 

	CREATE TABLE #BhavData
	(
		TxnId BIGINT,
		RefIsinId INT,
		RefSegmentId INT,
		[Close] DECIMAL(28,2)
	)

	IF @SegmentId = @CdslId
	BEGIN
		
		INSERT INTO #BhavData
		(
			TxnId,
			RefIsinId,
			RefSegmentId,
			[Close]
		)
		SELECT
			t.TxnId,
			t.RefIsinId,
			t.RefSegmentId,
			t.[Close]
		FROM
		(
			SELECT
				tids.TxnId,
				trans.RefIsinId,
				trans.RefSegmentId,
				bhav.[Close],
				ROW_NUMBER() OVER(PARTITION BY tids.TxnId, bhav.RefIsinId, bhav.RefSegmentId ORDER BY bhav.[Date] DESC) RN
			FROM #tempIds tids
			INNER JOIN dbo.CoreDpTransaction trans ON trans.CoreDpTransactionId = tids.TxnId
			INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = trans.RefIsinId AND bhav.RefSegmentId = trans.RefSegmentId
			AND bhav.[Date] BETWEEN DATEADD(DAY, -7,trans.BusinessDate) AND trans.BusinessDate
		) t
		WHERE t.RN = 1

		SELECT
			tids.TxnId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),txn.BusinessDate,106),' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,
			isin.[Description] AS ISINName,
			CASE WHEN txn.BuySellFlag = 'D' OR txn.BuySellFlag = 'S' THEN 'Debit'
				ELSE 'Credit' END AS DebitCredit,
			txn.Quantity,
			ISNULL(bhav.[Close],isin.FaceValue) AS Rate,
			txn.Quantity*ISNULL(bhav.[Close],isin.FaceValue) AS [Value],
			ISNULL(oppCl.ClientId, '') AS OppClientId,
			ISNULL(oppCl.[Name],'') AS OppClientName,
			txn.TransactionId,
			'' AS DpID,
			'' AS OppDpId,
			seg.Segment AS SegmentName
		FROM #tempIds tids
		INNER JOIN dbo.CoreDpTransaction txn ON txn.CoreDpTransactionId = tids.TxnId
		INNER JOIN dbo.RefClient cl ON cl.RefClientId = txn.RefClientId
		INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = txn.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = txn.RefSegmentId
		LEFT JOIN #BhavData bhav ON bhav.TxnId = tids.TxnId
		LEFT JOIN dbo.RefClient oppCl ON oppCl.RefClientDatabaseEnumId = @CdslDbId AND oppCl.ClientId = txn.OtherClientCode
		ORDER BY txn.BusinessDate
	END

	ELSE IF @SegmentId = @NsdlId
	BEGIN
		
		INSERT INTO #BhavData
		(
			TxnId,
			RefIsinId,
			RefSegmentId,
			[Close]
		)
		SELECT
			t.TxnId,
			t.RefIsinId,
			t.RefSegmentId,
			t.[Close]
		FROM
		(
			SELECT
				tids.TxnId,
				trans.RefIsinId,
				trans.RefSegmentId,
				bhav.[Close],
				ROW_NUMBER() OVER(PARTITION BY tids.TxnId, bhav.RefIsinId, bhav.RefSegmentId ORDER BY bhav.[Date] DESC) RN
			FROM #tempIds tids
			INNER JOIN dbo.CoreDPTransactionChangeHistory trans ON trans.CoreDPTransactionChangeHistoryId = tids.TxnId
			INNER JOIN dbo.CoreDPBhavCopy bhav ON bhav.RefIsinId = trans.RefIsinId AND bhav.RefSegmentId = trans.RefSegmentId
			AND bhav.[Date] BETWEEN DATEADD(DAY, -7,trans.ExecutionDate) AND trans.ExecutionDate
		) t
		WHERE t.RN = 1

		SELECT
			txns.TxnId,
			CASE WHEN cl.DpId IS NOT NULL
				THEN 'IN' + CONVERT(VARCHAR(100), cl.DpId) COLLATE DATABASE_DEFAULT
				ELSE '' END AS DpId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),dpTxn.ExecutionDate,106) ,' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,	
			isin.[Description] AS ISINName,
			CASE WHEN dpTxn.RefDpTransactionTypeId IN(@NsdlType905, @NsdlType926) THEN 'Credit'
				ELSE 'Debit' END AS DebitCredit,
			dpTxn.Quantity,
			ISNULL(bhav.[Close],isin.FaceValue) AS Rate,
			dpTxn.Quantity*ISNULL(bhav.[Close],isin.FaceValue) AS [Value],
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode
				ELSE dpTxn.OtherDPId END, '') AS OppDpId,
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode + dpTxn.OtherClientCode
				ELSE CONVERT(VARCHAR(100), dpTxn.OtherClientId) COLLATE DATABASE_DEFAULT END, '') AS OppClientId,
			ISNULL(cl1.[Name], '') AS OppClientName,
			dpTxn.BusinessPartnerInstructionId AS TransactionId,
			seg.Segment AS SegmentName
		FROM #tempIds txns
		INNER JOIN dbo.CoreDPTransactionChangeHistory dpTxn ON txns.TxnId = dpTxn.CoreDPTransactionChangeHistoryId
		INNER JOIN dbo.RefClient cl ON dpTxn.RefClientId = cl.RefClientId
		INNER JOIN dbo.RefIsin isin ON dpTxn.RefIsinId = isin.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = dpTxn.RefSegmentId
		LEFT JOIN #BhavData bhav ON bhav.TxnId = txns.TxnId
		LEFT JOIN dbo.RefClient cl1 ON (dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926) AND cl1.RefClientDatabaseEnumId = @NSDLDbId
				AND cl1.ClientId = (dpTxn.OtherDPCode + dpTxn.OtherClientCode))
			OR (cl1.RefClientDatabaseEnumId = @NSDLDbId AND dpTxn.OtherDPId = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) 
				AND CONVERT(VARCHAR(100),dpTxn.OtherClientId) = cl1.ClientId)
		ORDER BY dpTxn.ExecutionDate
	END
	SELECT
	COUNT(ids.TxnId) AS txnCount
	FROM #allTxnIds ids
END
GO
--RC-WEB-82998 END
--File:StoredProcedures:dbo:AML_GetS185ConsistentIntradayProfitLossInACalendarMonthTxnDetails
--RC-WEB-82998 START
GO
ALTER PROCEDURE dbo.AML_GetS185ConsistentIntradayProfitLossInACalendarMonthTxnDetails(
	@AlertId  BIGINT,
	@RowsPerPage INT = NULL,
	@PageNo INT = 1
)
AS 
BEGIN
	DECLARE @AlertIdInternal BIGINT,@FirstDateOfMonth DATETIME, @LastDateOfMonth DATETIME, 
			@Week1End DATETIME, @Week2End DATETIME, @Week3End DATETIME,
			@FUTIDX INT, @FUTSTK INT, @FUTIRD INT, @FUTIRT INT, @FUTCUR INT, @FUTIRC INT, @FUTIVX INT, @FUTIRF INT,
			@OPTIDX INT, @OPTSTK INT, @OPTCUR INT, @RowsPerPageInternal INT,@PageNoInternal INT   
			
	SET @AlertIdInternal = @AlertId
	SELECT @FirstDateOfMonth = alert.TransactionFromDate FROM dbo.CoreAmlScenarioAlert alert	WHERE alert.CoreAmlScenarioAlertId = @AlertIdInternal
	SELECT @LastDateOfMonth = alert.TransactionToDate FROM dbo.CoreAmlScenarioAlert alert	WHERE alert.CoreAmlScenarioAlertId = @AlertIdInternal

	SET @RowsPerPageInternal = @RowsPerPage
	SET @PageNoInternal = @PageNo

	
	SET @Week1End = DATEADD(SECOND,-1,DATEADD(DAY, 7, @FirstDateOfMonth))
	SET @Week2End = DATEADD(DAY, 8, @Week1End)
	SET @Week3End = DATEADD(DAY, 7, @Week2End)

	SELECT @FUTIDX = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIDX'
	SELECT @FUTSTK = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTSTK'
	SELECT @FUTIRD = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRD'
	SELECT @FUTIRT = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRT'
	SELECT @FUTCUR = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR'
	SELECT @FUTIRC = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRC'
	SELECT @FUTIVX = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIVX'
	SELECT @FUTIRF = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRF'

	SELECT @OPTIDX = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'
	SELECT @OPTSTK = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'
	SELECT @OPTCUR = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'

	SELECT
		trans.TransactionId AS TxnId,
		RefSegmentEnumId,
		ROW_NUMBER() OVER (ORDER BY  trans.TransactionId) AS rn 
	INTO #allTxnIds
	FROM dbo.CoreAmlScenarioAlertDetail trans
	WHERE trans.CoreAmlScenarioAlertId = @AlertIdInternal  
	

	IF (SELECT TOP 1 1 FROM #allTxnIds) IS NULL
	BEGIN
		RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;
		RETURN 50010
	END

	SELECT 
		trade.RefSegmentId,
		trade.RefInstrumentId,
		trade.TradeDate,
		CASE WHEN trade.BuySell='Buy' THEN 1 ELSE 0 END AS BuySell,
		trade.Rate,
		trade.Quantity,
		(trade.Quantity * trade.Rate) AS TurnOver
	INTO #tradeData	
	FROM dbo.CoreTrade trade
	INNER JOIN #allTxnIds txnid ON txnid.TxnId = trade.CoreTradeId AND ISNULL(txnid.RefSegmentEnumId ,0) = 0
	
	CREATE TABLE #BuySellData(
		TradeDate DATETIME,
		RefInstrumentId INT,
		RefSegmentId INT,
		BuyQuantity INT,
		BuyRate DECIMAL(28,2),
		BuyTurnover DECIMAL(28,2),
		SellQuantity INT,
		SellRate DECIMAL(28,2),
		SellTurnover DECIMAL(28,2),
		TotalProfit DECIMAL(28,2)
	)

	INSERT INTO #BuySellData(
		TradeDate ,
		RefInstrumentId,
		RefSegmentId ,
		BuyQuantity ,
		BuyRate,
		BuyTurnover ,
		SellQuantity ,
		SellRate ,
		SellTurnover ,
		TotalProfit 
	)
	SELECT
		z.TradeDate,
		z.RefInstrumentId,
		z.RefSegmentId,
		z.BuyQty,
		z.BuyAvgRate,
		z.BuyTO,
		z.SellQty,
		z.SellAvgRate,
		z.SellTO,
		(z.SellAvgRate - z.BuyAvgRate) * (CASE WHEN z.BuyQty < z.SellQty THEN z.BuyQty ELSE z.SellQty END) AS TotalProfit
	FROM(
		SELECT
			t.TradeDate,
			t.BuyQty,
			t.SellQty,
			t.BuyTO/BuyQty AS BuyAvgRate,
			t.SellTO/SellQty AS SellAvgRate,
			t.BuyTO,
			t.SellTO,
			t.RefSegmentId,
			t.RefInstrumentId
		FROM
		(
			SELECT
				td.RefSegmentId,
				SUM(CASE WHEN td.BuySell = 1 THEN td.Quantity ELSE 0 END) AS BuyQty,
				SUM(CASE WHEN td.BuySell = 1 THEN td.TurnOver ELSE 0 END) AS BuyTO,
				SUM(CASE WHEN td.BuySell = 0 THEN td.Quantity ELSE 0 END) AS SellQty,
				SUM(CASE WHEN td.BuySell = 0 THEN td.TurnOver ELSE 0 END) AS SellTO,
				td.TradeDate,
				td.RefInstrumentId
			FROM #tradeData td
			GROUP BY td.TradeDate, td.RefSegmentId, RefInstrumentId
		) t
		WHERE t.BuyQty > 0 AND t.SellQty > 0
	)z

	CREATE TABLE #FutInstTypes (RefInstrumentTypeId INT UNIQUE)
	INSERT INTO #FutInstTypes (RefInstrumentTypeId)
	VALUES (@FUTIDX), (@FUTSTK), (@FUTIRD), (@FUTIRT), (@FUTCUR), (@FUTIRC), (@FUTIVX), (@FUTIRF)

	CREATE TABLE #OptInstTypes (RefInstrumentTypeId INT UNIQUE)
	INSERT INTO #OptInstTypes (RefInstrumentTypeId)
	VALUES (@OPTIDX), (@OPTSTK), (@OPTCUR)

	SELECT
		pos.RefClientId,
		pos.DailyMTMSettlementValue,
		pos.PositionDate,
		pos.DayBuyOpenQty,
		pos.DayBuyOpenValue,
		pos.DaySellOpenQty,
		pos.DaySellOpenValue,
		pos.RefSegmentId,
		pos.RefInstrumentId
	INTO #FnoData
	FROM #allTxnIds txnid 
	INNER JOIN dbo.CoreFnoPosition pos ON txnId.RefSegmentEnumId IS NOT NULL AND pos.CoreFnoPositionId = txnid.TxnId 
	INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = pos.RefInstrumentId
	INNER JOIN #FutInstTypes ty ON ty.RefInstrumentTypeId = inst.RefInstrumentTypeId

	INSERT INTO #BuySellData(
		TradeDate ,
		RefInstrumentId,
		RefSegmentId ,
		BuyQuantity ,
		BuyRate,
		BuyTurnover ,
		SellQuantity ,
		SellRate ,
		SellTurnover ,
		TotalProfit 
	)
	SELECT
		z.TradeDate,
		z.RefInstrumentId,
		z.RefSegmentId,
		z.DayBuyOpenQty,
		z.BuyAvgRate,
		z.DayBuyOpenValue,
		z.DaySellOpenQty,
		z.SellAvgRate,
		z.DaySellOpenValue,
		(z.SellAvgRate - z.BuyAvgRate) * (CASE WHEN z.DayBuyOpenQty < z.DaySellOpenQty THEN z.DayBuyOpenQty ELSE z.DaySellOpenQty END) AS TotalProfit
	FROM(
		SELECT
			t.RefInstrumentId,
			t.RefSegmentId,
			t.PositionDate AS TradeDate,
			t.DayBuyOpenValue/t.DayBuyOpenQty AS BuyAvgRate,
			t.DaySellOpenValue/t.DaySellOpenQty AS SellAvgRate,
			t.DayBuyOpenQty,
			t.DaySellOpenQty,
			t.DayBuyOpenValue,
			t.DaySellOpenValue
		
		FROM
		(
			SELECT
				fd.RefClientId,
				fd.RefSegmentId,
				fd.RefInstrumentId,
				fd.PositionDate,
				SUM(fd.DaySellOpenValue) AS DaySellOpenValue,
				SUM(fd.DaySellOpenQty) AS DaySellOpenQty,
				SUM(fd.DayBuyOpenValue) AS DayBuyOpenValue,
				SUM(fd.DayBuyOpenQty) AS DayBuyOpenQty
			FROM #FnoData fd
			GROUP BY fd.RefClientId, fd.RefSegmentId, fd.RefInstrumentId, fd.PositionDate
		)t
		WHERE t.DayBuyOpenQty > 0 AND t.DaySellOpenQty > 0
	)z

	
	INSERT INTO #BuySellData(
		TradeDate ,
		RefInstrumentId,
		RefSegmentId ,
		TotalProfit 
	)
	SELECT
		pos.PositionDate,
		pos.RefInstrumentId,
		pos.RefSegmentId,
		SUM(pos.DailyMTMSettlementValue) AS TotalPl
	FROM #allTxnIds txnid 
	INNER JOIN dbo.CoreFnoPosition pos ON txnId.RefSegmentEnumId IS NOT NULL AND pos.CoreFnoPositionId = txnid.TxnId 
	INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = pos.RefInstrumentId
	INNER JOIN #OptInstTypes ty ON ty.RefInstrumentTypeId = inst.RefInstrumentTypeId
	GROUP BY pos.RefClientId,pos.RefSegmentId,pos.RefInstrumentId,pos.PositionDate
	

	CREATE TABLE #TempResult(
		SrNo INT,
		TradeDate VARCHAR(20),
		Script VARCHAR(100),
		SegmentName VARCHAR(20),
		BuyQuantity INT,
		BuyRate DECIMAL(28,2),
		BuyTurnover DECIMAL(28,2),
		SellQuantity INT,
		SellRate DECIMAL(28,2),
		SellTurnover DECIMAL(28,2),
		TotalProfit DECIMAL(28,2)
	)

	INSERT INTO #TempResult (SrNo,TradeDate)
	VALUES (1,'W1')

	DECLARE @MaxSrNo INT
	SET @MaxSrNo = 1
	INSERT INTO #TempResult(
		 SrNo,
		 TradeDate,
		 Script,
		 SegmentName,
		 BuyQuantity,
		 BuyRate,
		 BuyTurnover,
		 SellQuantity,
		 SellRate,
		 SellTurnover,
		 TotalProfit
	)
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY buySell.TradeDate ASC) + @MaxSrNo SrNo,
			CONVERT (VARCHAR, buySell.Tradedate,106),
			inst.[Name],
			seg.Segment,
			buySell.BuyQuantity,
			buySell.BuyRate,
			buySell.BuyTurnover,
			buySell.SellQuantity,
			buySell.SellRate,
			buySell.SellTurnover,
			buySell.TotalProfit
		FROM #BuySellData  AS buySell
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = buySell.RefInstrumentId  AND buySell.TradeDate >= @FirstDateOfMonth AND buySell.TradeDate <= @Week1End
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = buySell.RefSegmentId 
	)
	INSERT INTO #TempResult (SrNo,TradeDate)
	VALUES ((SELECT MAX(SrNo) FROM #TempResult)+1,'W2')

	SET @MaxSrNo = (SELECT MAX(SrNo) FROM #TempResult)

	INSERT INTO #TempResult(
		 SrNo,
		 TradeDate,
		 Script,
		 SegmentName,
		 BuyQuantity,
		 BuyRate,
		 BuyTurnover,
		 SellQuantity,
		 SellRate,
		 SellTurnover,
		 TotalProfit
	)
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY buySell.TradeDate ASC) + @MaxSrNo SrNo,
			CONVERT (VARCHAR, buySell.Tradedate,106),
			inst.[Name],
			seg.Segment,
			buySell.BuyQuantity,
			buySell.BuyRate,
			buySell.BuyTurnover,
			buySell.SellQuantity,
			buySell.SellRate,
			buySell.SellTurnover,
			buySell.TotalProfit
		FROM #BuySellData  AS buySell
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = buySell.RefInstrumentId  AND buySell.TradeDate > @Week1End AND buySell.TradeDate <= @Week2End
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = buySell.RefSegmentId 
	)
	
	INSERT INTO #TempResult (SrNo,TradeDate)
	VALUES ((SELECT MAX(SrNo) FROM #TempResult)+1,'W3')

	SET @MaxSrNo = (SELECT MAX(SrNo) FROM #TempResult)

	INSERT INTO #TempResult(
		 SrNo,
		 TradeDate,
		 Script,
		 SegmentName,
		 BuyQuantity,
		 BuyRate,
		 BuyTurnover,
		 SellQuantity,
		 SellRate,
		 SellTurnover,
		 TotalProfit
	)
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY buySell.TradeDate ASC) + @MaxSrNo SrNo,
			CONVERT (varchar, buySell.Tradedate,106),
			inst.[Name],
			seg.Segment,
			buySell.BuyQuantity,
			buySell.BuyRate,
			buySell.BuyTurnover,
			buySell.SellQuantity,
			buySell.SellRate,
			buySell.SellTurnover,
			buySell.TotalProfit
		FROM #BuySellData  AS buySell
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = buySell.RefInstrumentId   AND buySell.TradeDate > @Week2End AND buySell.TradeDate <= @Week3End
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = buySell.RefSegmentId 
	)
	INSERT INTO #TempResult (SrNo,TradeDate)
	VALUES ((SELECT MAX(SrNo) FROM #TempResult)+1,'W4')

	SET @MaxSrNo = (SELECT MAX(SrNo) FROM #TempResult)

	INSERT INTO #TempResult(
		 SrNo,
		 TradeDate,
		 Script,
		 SegmentName,
		 BuyQuantity,
		 BuyRate,
		 BuyTurnover,
		 SellQuantity,
		 SellRate,
		 SellTurnover,
		 TotalProfit
	)
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY buySell.TradeDate ASC) + @MaxSrNo SrNo,
			CONVERT (varchar, buySell.Tradedate,106),
			inst.[Name],
			seg.Segment,
			buySell.BuyQuantity,
			buySell.BuyRate,
			buySell.BuyTurnover,
			buySell.SellQuantity,
			buySell.SellRate,
			buySell.SellTurnover,
			buySell.TotalProfit
		FROM #BuySellData  AS buySell
		INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = buySell.RefInstrumentId   AND buySell.TradeDate > @Week3End AND buySell.TradeDate <= @LastDateOfMonth
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = buySell.RefSegmentId 
	)

	SELECT * FROM
	#TempResult te
	WHERE ISNULL(@RowsPerPageInternal,0) = 0 OR te.SrNo  BETWEEN ( ( ( @PageNoInternal - 1 ) * @RowsPerPageInternal ) + 1 ) AND @PageNoInternal * @RowsPerPageInternal 
	ORDER BY te.SrNo

	SELECT COUNT(ids.SrNo) txnCount
	FROM #TempResult ids

END
GO
--RC-WEB-82998 END
--File:StoredProcedures:dbo:AML_GetS848HighValueOnMarketTransactionsInASpecifiedPeriodTxnDetails
--RC-WEB-82998 START
GO
ALTER PROCEDURE dbo.AML_GetS848HighValueOnMarketTransactionsInASpecifiedPeriodTxnDetails
(
	@AlertId BIGINT,
	@RowsPerPage INT = NULL,
	@PageNo INT = 1
)
AS
BEGIN
	DECLARE @AlertIdInternal BIGINT, @SegmentId INT, @CdslId INT, @NsdlId INT, @RowsPerPageInternal INT,@PageNoInternal INT 
			,@CdslDbId INT, @TradingDBId INT, @NSDLDbId INT,@NsdlType905 INT, @NsdlType925 INT, @NsdlType926 INT

	SET @AlertIdInternal = @AlertId
	
	SET @RowsPerPageInternal = @RowsPerPage
	SET @PageNoInternal = @PageNo


	SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'CDSL'
	SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'NSDL'

	SELECT @CdslDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'
	SELECT @NSDLDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'

	SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 905 AND [Name] = 'Receipt Free of Payment (Inter DP) Instruction'
	SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
	SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)' 

	SELECT @SegmentId = RefSegmentEnumId FROM dbo.CoreAmlScenarioAlert WHERE CoreAmlScenarioAlertId = @AlertIdInternal

	SELECT
		trans.TransactionId AS TxnId,
		ROW_NUMBER() OVER (ORDER BY  trans.TransactionId) AS rn 
	INTO #allTxnIds
	FROM dbo.CoreAmlScenarioAlertDetail trans
	WHERE trans.CoreAmlScenarioAlertId = @AlertIdInternal  
	

	IF (SELECT TOP 1 1 FROM #allTxnIds) IS NULL
	BEGIN
		RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;
		RETURN 50010
	END
	SELECT 
		ids.*
	INTO #tempIds
	FROM #allTxnIds ids      
	WHERE ISNULL(@RowsPerPageInternal,0) =0   OR ids.rn BETWEEN ( ( ( @PageNoInternal - 1 ) * @RowsPerPageInternal ) + 1 ) AND @PageNoInternal * @RowsPerPageInternal 


	IF @SegmentId = @CdslId
	BEGIN
		---nsdl database
		SELECT 
		CASE WHEN SUBSTRING(txn.CounterBoId,1,2) ='IN' THEN 1
			ELSE 0
		END isIN,
		SUBSTRING(txn.CounterBoId,9,8) ClientId,
		SUBSTRING(txn.CounterBoId,3,6) dpid,
		txn.CoreDpTransactionId txnId
		INTO #oppTemp
		FROM dbo.CoreDpTransaction txn
		INNER JOIN #tempIds ids ON ids.TxnId = txn.CoreDpTransactionId

		SELECT
			tids.TxnId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),txn.BusinessDate,106),' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,
			isin.[Description] AS ISINName,
			CASE WHEN txn.BuySellFlag = 'D' OR txn.BuySellFlag = 'S' THEN 'Debit'
				ELSE 'Credit' END AS DebitCredit,
			txn.Quantity,
			ISNULL(oppCl.ClientId, '') AS OppClientId,
			ISNULL(oppCl.[Name],'') AS OppClientName,
			txn.TransactionId,
			txn.CounterBoId AS DpID,
			'' AS OppDpId,
			seg.Segment AS SegmentName
		FROM #tempIds tids
		INNER JOIN dbo.CoreDpTransaction txn ON txn.CoreDpTransactionId = tids.TxnId
		INNER JOIN dbo.RefClient cl ON cl.RefClientId = txn.RefClientId
		INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = txn.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = txn.RefSegmentId
		INNER JOIN #oppTemp opp ON opp.txnId = txn.CoreDpTransactionId
		LEFT JOIN dbo.RefClient oppCl ON (oppCl.RefClientDatabaseEnumId = @CdslDbId AND oppCl.ClientId = txn.CounterBoId)
		OR  (oppCl.RefClientDatabaseEnumId = @NSDLDbId AND opp.isIN = 1 AND  oppCl.ClientId = opp.ClientId AND CONVERT(VARCHAR(100),oppCl.DpId) = opp.dpid ) 
		ORDER BY txn.BusinessDate
	END

	ELSE IF @SegmentId = @NsdlId
	BEGIN
		SELECT
			txns.TxnId,
			CASE WHEN cl.DpId IS NOT NULL
				THEN 'IN' + CONVERT(VARCHAR(100), cl.DpId) COLLATE DATABASE_DEFAULT
				ELSE '' END AS DpId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),dpTxn.ExecutionDate,106) ,' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,	
			isin.[Description] AS ISINName,
			CASE WHEN dpTxn.RefDpTransactionTypeId IN(@NsdlType905, @NsdlType926) THEN 'Credit'
				ELSE 'Debit' END AS DebitCredit,
			dpTxn.Quantity,
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode
				ELSE dpTxn.OtherDPId END, '') AS OppDpId,
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode + dpTxn.OtherClientCode
				ELSE CONVERT(VARCHAR(100), dpTxn.OtherClientId) COLLATE DATABASE_DEFAULT END, '') AS OppClientId,
			ISNULL(cl1.[Name], '') AS OppClientName,
			dpTxn.BusinessPartnerInstructionId AS TransactionId,
			seg.Segment AS SegmentName
		FROM #tempIds txns
		INNER JOIN dbo.CoreDPTransactionChangeHistory dpTxn ON txns.TxnId = dpTxn.CoreDPTransactionChangeHistoryId
		INNER JOIN dbo.RefClient cl ON dpTxn.RefClientId = cl.RefClientId
		INNER JOIN dbo.RefIsin isin ON dpTxn.RefIsinId = isin.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = dpTxn.RefSegmentId
		LEFT JOIN dbo.RefClient cl1 ON (dpTxn.RefDpTransactionTypeId IN (@NsdlType925 , @NsdlType926) AND cl1.RefClientDatabaseEnumId = @NSDLDbId
				AND cl1.ClientId = dpTxn.OtherClientCode AND dpTxn.OtherDPCode = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) )
			OR (cl1.RefClientDatabaseEnumId = @NSDLDbId AND dpTxn.OtherDPId = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) 
				AND CONVERT(VARCHAR(100), dpTxn.OtherClientId) = cl1.ClientId)
			OR(cl1.RefClientDatabaseEnumId = @CdslDbId AND cl1.ClientId = dpTxn.OtherDPCode + dpTxn.OtherClientCode )
		ORDER BY dpTxn.ExecutionDate
	END
	SELECT 
	COUNT(ids.TxnId) AS txnCount
	FROM #allTxnIds ids
END
GO
--RC-WEB-82998 END
--File:StoredProcedures:dbo:AML_GetS849ClientHighValueOnMarketTransactionVisAVisFairValueTxnDetails
--RC-WEB-82998 START
GO
ALTER PROCEDURE dbo.AML_GetS849ClientHighValueOnMarketTransactionVisAVisFairValueTxnDetails
(
	@AlertId BIGINT,
	@RowsPerPage INT = NULL,
	@PageNo INT = 1
)
AS
BEGIN
	DECLARE @AlertIdInternal BIGINT, @SegmentId INT, @CdslId INT, @NsdlId INT, @RowsPerPageInternal INT,@PageNoInternal INT ,
			@CdslDbId INT, @NSDLDbId INT, @NsdlType925 INT, @NsdlType926 INT, @NsdlType905 INT, @NsdlType904 INT

	SET @AlertIdInternal = @AlertId
	
	SET @RowsPerPageInternal = @RowsPerPage
	SET @PageNoInternal = @PageNo


	SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'CDSL'
	SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'NSDL'

	SELECT @CdslDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'
	SELECT @NSDLDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'

	SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
	SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)'
	SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = '905'
	SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = '904'

	SELECT @SegmentId = RefSegmentEnumId FROM dbo.CoreAmlScenarioAlert WHERE CoreAmlScenarioAlertId = @AlertIdInternal

	SELECT
		trans.TransactionId AS TxnId,
		ROW_NUMBER() OVER (ORDER BY  trans.TransactionId) AS rn 
	INTO #allTxnIds
	FROM dbo.CoreAmlScenarioAlertDetail trans
	WHERE trans.CoreAmlScenarioAlertId = @AlertIdInternal

	IF ((SELECT TOP 1 1 FROM #allTxnIds) IS NULL)
	BEGIN
		RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;
		RETURN 50010
	END
	SELECT 
		ids.*
	INTO #tempIds
	FROM #allTxnIds ids      
	WHERE ISNULL(@RowsPerPageInternal,0)=0 OR ids.rn BETWEEN ( ( ( @PageNoInternal - 1 ) * @RowsPerPageInternal ) + 1 ) AND @PageNoInternal * @RowsPerPageInternal 

	IF @SegmentId = @CdslId
	BEGIN
		SELECT
			tids.TxnId,
			'' AS DpId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),txn.BusinessDate,106),' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,
			isin.[Description] AS ISINName,
			CASE 
				WHEN txn.BuySellFlag = 'D' OR txn.BuySellFlag = 'S' THEN 'Debit'
				ELSE 'Credit' 
			END AS DebitCredit,
			txn.Quantity,
			'' AS OppDpId,
			ISNULL(oppCl.ClientId, '') AS OppClientId,
			ISNULL(oppCl.[Name],'') AS OppClientName,
			txn.TransactionId,			
			seg.Segment AS SegmentName
		FROM #tempIds tids
		INNER JOIN dbo.CoreDpTransaction txn ON txn.CoreDpTransactionId = tids.TxnId
		INNER JOIN dbo.RefClient cl ON cl.RefClientId = txn.RefClientId
		INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = txn.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = txn.RefSegmentId
		LEFT JOIN dbo.RefClient oppCl ON oppCl.RefClientDatabaseEnumId = @CdslDbId AND oppCl.ClientId = txn.OtherClientCode
		ORDER BY txn.BusinessDate
	END
	ELSE IF @SegmentId = @NsdlId
	BEGIN
		SELECT
			txns.TxnId,
			CASE 
				WHEN cl.DpId IS NOT NULL THEN 'IN' + CONVERT(VARCHAR(100), cl.DpId) COLLATE DATABASE_DEFAULT
				ELSE '' 
			END AS DpId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),dpTxn.ExecutionDate,106) ,' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,	
			isin.[Description] AS ISINName,
			CASE 
				WHEN dpTxn.RefDpTransactionTypeId IN(@NsdlType905, @NsdlType926) THEN 'Credit'
				ELSE 'Debit' 
			END AS DebitCredit,
			dpTxn.Quantity,
			ISNULL(CASE 
					   WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926) THEN dpTxn.OtherDPCode
					   ELSE dpTxn.OtherDPId 
				   END, '') AS OppDpId,
			ISNULL(CASE 
					   WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926) THEN dpTxn.OtherDPCode + dpTxn.OtherClientCode
					   ELSE CONVERT(VARCHAR(100), dpTxn.OtherClientId) COLLATE DATABASE_DEFAULT 
				   END, '') AS OppClientId,
			ISNULL(oppCl.[Name], '') AS OppClientName,
			dpTxn.BusinessPartnerInstructionId AS TransactionId,
			seg.Segment AS SegmentName
		FROM #tempIds txns
		INNER JOIN dbo.CoreDPTransactionChangeHistory dpTxn ON txns.TxnId = dpTxn.CoreDPTransactionChangeHistoryId
		INNER JOIN dbo.RefClient cl ON dpTxn.RefClientId = cl.RefClientId
		INNER JOIN dbo.RefIsin isin ON dpTxn.RefIsinId = isin.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = dpTxn.RefSegmentId
		LEFT JOIN dbo.RefClient oppCl ON (dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926) 
										  AND oppCl.RefClientDatabaseEnumId = @NSDLDbId 
										  AND oppCl.ClientId = (dpTxn.OtherDPCode + dpTxn.OtherClientCode))
									  OR (oppCl.RefClientDatabaseEnumId = @NSDLDbId 
										  AND dpTxn.OtherDPId = ('IN' + CONVERT(VARCHAR(100), oppCl.DpId) COLLATE DATABASE_DEFAULT) 
										  AND CONVERT(VARCHAR(100),dpTxn.OtherClientId) = oppCl.ClientId)
		ORDER BY dpTxn.ExecutionDate
	END
	SELECT 
	COUNT(ids.TxnId) txnCount
	FROM #allTxnIds ids
END
GO
--RC-WEB-82998 END
--File:StoredProcedures:dbo:AML_GetS853OffMarketDeliveryInUnlistedScripTxnDetails
--RC-WEB-82998 START
GO
ALTER PROCEDURE dbo.AML_GetS853OffMarketDeliveryInUnlistedScripTxnDetails
(
	@AlertId BIGINT,
	@RowsPerPage INT = NULL,
	@PageNo INT = 1
)
AS
BEGIN
	DECLARE @AlertIdInternal BIGINT, @SegmentId INT, @CdslId INT, @NsdlId INT, @RowsPerPageInternal INT,@PageNoInternal INT 
			,@CdslDbId INT, @TradingDBId INT, @NSDLDbId INT,@NsdlType905 INT, @NsdlType925 INT, @NsdlType926 INT

	SET @AlertIdInternal = @AlertId
	
	SET @RowsPerPageInternal = @RowsPerPage
	SET @PageNoInternal = @PageNo

	SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'CDSL'
	SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'NSDL'

	SELECT @CdslDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'CDSL'
	SELECT @NSDLDbId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'NSDL'

	SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 905 AND [Name] = 'Receipt Free of Payment (Inter DP) Instruction'
	SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 925 AND [Name] = 'Inter Depository Transfer Instruction (DELIVERY)'    
	SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = 926 AND [Name] = 'Inter Depository Transfer Instruction (RECEIPT)' 

	SELECT @SegmentId = RefSegmentEnumId FROM dbo.CoreAmlScenarioAlert WHERE CoreAmlScenarioAlertId = @AlertIdInternal

	SELECT
		trans.TransactionId AS TxnId,
		ROW_NUMBER() OVER (ORDER BY  trans.TransactionId) AS rn 
	INTO #allTxnIds
	FROM dbo.CoreAmlScenarioAlertDetail trans
	WHERE trans.CoreAmlScenarioAlertId = @AlertIdInternal  
	
 CREATE TABLE #reasonData    
 (          
  RefSegmentId INT,          
  ReasonCode INT,    
  [Description] VARCHAR(100) COLLATE DATABASE_DEFAULT    
 )    
    
 INSERT INTO #reasonData VALUES (@CdslId,1,'Gift')    
 INSERT INTO #reasonData VALUES (@CdslId,2,'Off Market Sale')    
 INSERT INTO #reasonData VALUES (@CdslId,16,'Donation')    
 INSERT INTO #reasonData VALUES (@NsdlId,1,'Off Market Sale')    
 INSERT INTO #reasonData VALUES (@NsdlId,92,'Gift')    
 INSERT INTO #reasonData VALUES (@NsdlId,93,'Donation')  
	

	IF (SELECT TOP 1 1 FROM #allTxnIds) IS NULL
	BEGIN
		RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;
		RETURN 50010
	END

	SELECT 
		ids.*
	INTO #tempIds
	FROM #allTxnIds ids      
	WHERE ISNULL(@RowsPerPageInternal, 0) = 0  OR ids.rn BETWEEN ( ( ( @PageNoInternal - 1 ) * @RowsPerPageInternal ) + 1 ) AND @PageNoInternal * @RowsPerPageInternal  

	IF @SegmentId = @CdslId
	BEGIN
		---nsdl database
		SELECT 
		CASE WHEN SUBSTRING(txn.CounterBoId,1,2) ='IN' THEN 1
			ELSE 0
		END isIN,
		SUBSTRING(txn.CounterBoId,9,8) ClientId,
		SUBSTRING(txn.CounterBoId,3,6) dpid,
		txn.CoreDpTransactionId txnId
		INTO #oppTemp
		FROM dbo.CoreDpTransaction txn
		INNER JOIN #tempIds ids ON ids.TxnId = txn.CoreDpTransactionId

		SELECT
			tids.TxnId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),txn.BusinessDate,106),' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,
			isin.IsinShortName AS ISINName,
			CASE WHEN txn.BuySellFlag = 'D' OR txn.BuySellFlag = 'S' THEN 'Debit'
				ELSE 'Credit' END AS DebitCredit,
			txn.Quantity,
			ISNULL(oppCl.ClientId, '') AS OppClientId,
			ISNULL(oppCl.[Name],'') AS OppClientName,
			txn.TransactionId,
			txn.CounterBoId AS DpID,
			'' AS OppDpId,
			rd.[Description] AS ReasonCode,    
			seg.Segment AS SegmentName,
			dptype.[Name] As TransactionType,
			dpstatus.[Name] As TransactionStatus
		FROM #tempIds tids
		INNER JOIN dbo.CoreDpTransaction txn ON txn.CoreDpTransactionId = tids.TxnId
		INNER JOIN dbo.RefDpTransactionType dptype ON dptype.RefDpTransactionTypeId=txn.RefDpTransactionTypeId
		INNER JOIN dbo.RefDpTransactionStatus dpstatus ON dpstatus.RefDpTransactionStatusId=txn.RefDpTransactionStatusId
		INNER JOIN dbo.RefClient cl ON cl.RefClientId = txn.RefClientId
		INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = txn.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = txn.RefSegmentId
		INNER JOIN #oppTemp opp ON opp.txnId = txn.CoreDpTransactionId
		LEFT JOIN #reasonData rd ON rd.RefSegmentId = txn.RefSegmentId AND rd.ReasonCode = txn.ReasonForTrade 
		LEFT JOIN dbo.RefClient oppCl ON (oppCl.RefClientDatabaseEnumId = @CdslDbId AND oppCl.ClientId = txn.CounterBoId)
		OR  (oppCl.RefClientDatabaseEnumId = @NSDLDbId AND opp.isIN = 1 AND  oppCl.ClientId = opp.ClientId AND CONVERT(VARCHAR(100),oppCl.DpId) = opp.dpid ) 
		ORDER BY txn.BusinessDate
	END

	ELSE IF @SegmentId = @NsdlId
	BEGIN
		SELECT
			txns.TxnId,
			CASE WHEN cl.DpId IS NOT NULL
				THEN 'IN' + CONVERT(VARCHAR(100), cl.DpId) COLLATE DATABASE_DEFAULT
				ELSE '' END AS DpId,
			cl.ClientId,
			cl.[Name] AS ClientName,
			REPLACE(CONVERT(VARCHAR(20),dpTxn.ExecutionDate,106) ,' ', '/') AS BusinessDate,
			isin.[Name] AS ISIN,	
			isin.IsinShortName AS ISINName,
			CASE WHEN dpTxn.RefDpTransactionTypeId IN(@NsdlType905, @NsdlType926) THEN 'Credit'
				ELSE 'Debit' END AS DebitCredit,
			dpTxn.Quantity,
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode
				ELSE dpTxn.OtherDPId END, '') AS OppDpId,
			ISNULL(CASE WHEN dpTxn.RefDpTransactionTypeId IN (@NsdlType925, @NsdlType926)
				THEN dpTxn.OtherDPCode + dpTxn.OtherClientCode
				ELSE CONVERT(VARCHAR(100), dpTxn.OtherClientId) COLLATE DATABASE_DEFAULT END, '') AS OppClientId,
			ISNULL(cl1.[Name], '') AS OppClientName,
			dpTxn.BusinessPartnerInstructionId AS TransactionId,
			rd.[Description] AS ReasonCode,    
			seg.Segment AS SegmentName,
			dptype.[Name] As TransactionType,
			'' As TransactionStatus
		FROM #tempIds txns
		INNER JOIN dbo.CoreDPTransactionChangeHistory dpTxn ON txns.TxnId = dpTxn.CoreDPTransactionChangeHistoryId
		INNER JOIN dbo.RefDpTransactionType dptype ON dptype.RefDpTransactionTypeId=dpTxn.RefDpTransactionTypeId
		INNER JOIN dbo.RefClient cl ON dpTxn.RefClientId = cl.RefClientId
		INNER JOIN dbo.RefIsin isin ON dpTxn.RefIsinId = isin.RefIsinId
		INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = dpTxn.RefSegmentId
		LEFT JOIN #reasonData rd ON rd.RefSegmentId = dpTxn.RefSegmentId AND CONVERT(VARCHAR(500), rd.ReasonCode) = dpTxn.TransferReasonCode 
		LEFT JOIN dbo.RefClient cl1 ON (dpTxn.RefDpTransactionTypeId IN (@NsdlType925 , @NsdlType926) AND cl1.RefClientDatabaseEnumId = @NSDLDbId
				AND cl1.ClientId = dpTxn.OtherClientCode AND dpTxn.OtherDPCode = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) )
			OR (cl1.RefClientDatabaseEnumId = @NSDLDbId AND dpTxn.OtherDPId = ('IN' + CONVERT(VARCHAR(100), cl1.DpId) COLLATE DATABASE_DEFAULT) 
				AND dpTxn.OtherClientId = cl1.ClientId)
			OR(cl1.RefClientDatabaseEnumId = @CdslDbId AND cl1.ClientId = dpTxn.OtherDPCode + dpTxn.OtherClientCode )
		ORDER BY dpTxn.ExecutionDate
	END

	SELECT 
	COUNT(ids.TxnId) txnCount
	FROM #allTxnIds ids
END
GO
--RC-WEB-82998 END
--File:StoredProcedures:dbo:AML_GetS852SuspiciousOffMarketCreditAndDebitTxnDetails
--RC-WEB-82998 START
GO
ALTER PROCEDURE dbo.AML_GetS852SuspiciousOffMarketCreditAndDebitTxnDetails
(
	@AlertId BIGINT,
	@RowsPerPage INT = NULL,
	@PageNo INT = 1
)
AS
BEGIN
	
	DECLARE @AlertIdInternal BIGINT, @SegmentId INT,
			@CdslId INT, @NsdlId INT,
			@NsdlType904 INT, @NsdlType905 INT, @NsdlType925 INT, @NsdlType926 INT,
			@AlertRefClientId INT, @ClientId VARCHAR(200), @ClientName VARCHAR(200), @Pan VARCHAR(20),
			@TradingDBId INT, @TradingCode VARCHAR(MAX), @DpId VARCHAR(20), @RowsPerPageInternal INT,@PageNoInternal INT 

	SET @AlertIdInternal = @AlertId
	
	SET @RowsPerPageInternal = @RowsPerPage
	SET @PageNoInternal = @PageNo

	SELECT @NsdlType904 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = '904'
	SELECT @NsdlType905 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = '905'
	SELECT @NsdlType925 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = '925'
	SELECT @NsdlType926 = RefDpTransactionTypeId FROM dbo.RefDpTransactionType WHERE NsdlCode = '926'

	SELECT @TradingDBId = RefClientDatabaseEnumId FROM dbo.RefClientDatabaseEnum WHERE DatabaseType = 'Trading'

	SELECT @CdslId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'CDSL'
	SELECT @NsdlId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE [Code] = 'NSDL'

	SELECT @SegmentId = RefSegmentEnumId, @AlertRefClientId = RefClientId FROM dbo.CoreAmlScenarioAlert WHERE CoreAmlScenarioAlertId = @AlertIdInternal

	SELECT TransactionId,
		ROW_NUMBER() OVER (ORDER BY TransactionId) AS rn
	INTO #transactions
	FROM dbo.CoreAmlScenarioAlertDetail
	WHERE CoreAmlScenarioAlertId = @AlertIdInternal

	IF NOT ((SELECT TOP 1 1 FROM #transactions) = 1) -- if no txn presents then throw error
	BEGIN
		RAISERROR ('Transaction Details used for generating the alert are missing.', 11, 1) WITH SETERROR;
		RETURN 50010;
	END
	SELECT 
		ids.*
	INTO #tempIds
	FROM #transactions ids      
	WHERE ISNULL(@RowsPerPageInternal, 0) = 0  OR ids.rn BETWEEN ( ( ( @PageNoInternal - 1 ) * @RowsPerPageInternal ) + 1 ) AND @PageNoInternal * @RowsPerPageInternal  

	SELECT 
		@ClientId = ClientId,
		@ClientName = [Name],
		@DpId = CASE WHEN DpId IS NOT NULL THEN 'IN' + CONVERT(VARCHAR(100), DpId) COLLATE DATABASE_DEFAULT ELSE '' END,
		@Pan = PAN
	FROM dbo.RefClient WHERE RefClientId = @AlertRefClientId

	SET @TradingCode =  STUFF(( 
							SELECT ', '+ ClientId
							FROM dbo.RefClient
							WHERE PAN = @Pan AND RefClientDatabaseEnumId = @TradingDBId
							FOR XML PATH(''))
						,1,2, '')


	IF @SegmentId = @CdslId
	BEGIN

		SELECT
			t.TxnId,
			t.ClientId,
			t.ClientName,
			@DpId AS DpId,
			t.BusinessDate,
			t.ISIN,
			t.ISINName,
			t.DebitCredit,
			t.Quantity,
			t.CounterBOId AS OppClientId,
			oppCl.[Name] AS OppClientName,
			'' AS OppDpId,
			t.TransactionId,
			@TradingCode AS TradingCode
		FROM
		(
			SELECT
				txn.CoreDpTransactionId AS TxnId,
				@ClientId AS ClientId,
				@ClientName AS ClientName,
				REPLACE(CONVERT(VARCHAR(20),txn.BusinessDate,106),' ', '-') AS BusinessDate,
				isin.[Name] AS ISIN,
				isin.[Description] AS ISINName,
				CASE WHEN txn.BuySellFlag = 'B' OR txn.BuySellFlag = 'C' THEN 'Credit' ELSE 'Debit' END AS DebitCredit,
				CONVERT(BIGINT, txn.Quantity) AS Quantity,
				CASE WHEN SUBSTRING(ISNULL(txn.CounterBOId,''),1,2) = 'IN' THEN SUBSTRING(ISNULL(txn.CounterBOId,''), 9, 8) ELSE ISNULL(txn.CounterBOId,'') END AS OppClientid,
				CASE WHEN SUBSTRING(ISNULL(txn.CounterBOId,''),1,2) = 'IN' THEN SUBSTRING(ISNULL(txn.CounterBOId,''), 3, 6) ELSE NULL  END OppDpId,
				txn.CounterBOId,
				txn.TransactionId
			FROM #tempIds temp
			INNER JOIN dbo.CoreDpTransaction txn ON temp.TransactionId = txn.CoreDpTransactionId
			INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = txn.RefIsinId
		)t
		LEFT JOIN dbo.RefClient oppCl ON oppCl.ClientId = t.OppClientid AND ISNULL(CONVERT(VARCHAR(20), oppCl.DpId), '') = t.OppDpId
	END

	ELSE
	BEGIN
		SELECT
			t.TxnId,
			t.ClientId,
			t.ClientName,
			@DpId AS DpId,
			t.BusinessDate,
			t.ISIN,
			t.ISINName,
			t.DebitCredit,
			t.Quantity,
			t.OppClientId,
			oppCl.[Name] AS OppClientName,
			t.TransactionId,
			t.OppDpId,
			@TradingCode AS TradingCode
		FROM
		(
			SELECT
				txn.CoreDPTransactionChangeHistoryId AS TxnId,
				@ClientId AS ClientId,
				@ClientName AS ClientName,
				REPLACE(CONVERT(VARCHAR(20),txn.ExecutionDate,106),' ', '-') AS BusinessDate,
				isin.[Name] AS ISIN,
				isin.[Description] AS ISINName,
				CASE WHEN txn.RefDpTransactionTypeId IN (@NsdlType904, @NsdlType925) THEN 'Debit' ELSE 'Credit' END AS DebitCredit,
				CONVERT(BIGINT, txn.Quantity) AS Quantity,
				CASE
					WHEN txn.RefDpTransactionTypeId = @NsdlType904 THEN ISNULL(txn.OtherDPId,'') + CONVERT(VARCHAR(MAX), txn.OtherClientId)
					WHEN txn.RefDpTransactionTypeId = @NsdlType925 AND SUBSTRING(ISNULL(txn.OtherDPCode,''),1,2) = 'IN' 
						THEN ISNULL(txn.OtherDPCode,'') + ISNULL(txn.OtherClientCode,'')
					ELSE ISNULL(txn.OtherClientCode,'') END AS OppClientId,
				
				CASE 
					WHEN txn.RefDpTransactionTypeId = @NsdlType904 AND SUBSTRING(ISNULL(txn.OtherDPId,''),1,2) = 'IN' THEN SUBSTRING(ISNULL(txn.OtherDPId,''), 3, 6)
					WHEN txn.RefDpTransactionTypeId = @NsdlType925 AND SUBSTRING(ISNULL(txn.OtherDPCode,''),1,2) = 'IN' THEN SUBSTRING(ISNULL(txn.OtherDPCode,''), 3, 6)
					ELSE NULL END AS OppDpId,
				txn.BusinessPartnerInstructionId AS TransactionId
			FROM #tempIds temp
			INNER JOIN dbo.CoreDPTransactionChangeHistory txn ON temp.TransactionId = txn.CoreDPTransactionChangeHistoryId
			INNER JOIN dbo.RefIsin isin ON isin.RefIsinId = txn.RefIsinId
		)t
		LEFT JOIN dbo.RefClient oppCl ON oppCl.ClientId = t.OppClientid AND ISNULL(CONVERT(VARCHAR(20), oppCl.DpId), '') = t.OppDpId
	END
	SELECT COUNT(trns.rn) txnCount
	FROM #transactions  trns

END
GO
--RC-WEB-82998 END
--File:StoredProcedures:dbo:AML_HighValueOffMarketTransactioninaSpecifiedPeriodtxnDetails
--RC-WEB-82998 START
GO
CREATE PROCEDURE dbo.AML_HighValueOffMarketTransactioninaSpecifiedPeriodtxnDetails (
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
			CASE WHEN dpTxn.BuySellFlag = 'D' OR dpTxn.BuySellFlag = 'S' THEN 'Debit'
				ELSE 'Credit' END AS DebitCredit,
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
--RC-WEB-82998 END