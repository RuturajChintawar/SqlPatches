CoreDpSuspiciousTransactionBatch
CoreAmlScenarioAlert
RefAmlReport_GetTssAlertCount
SELECT name, type_desc, is_unique, is_primary_key
FROM sys.indexes
WHERE [object_id] = OBJECT_ID('dbo.CoreAmlScenarioAlert')
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CoreAmlScenarioAlert'
CoreAlertRegisterCase_Search
CoreTrade
CoreStrSinCtl
CoreFinancialTransaction_Search
CoreStrSinAcc ,CoreStrSinBrc, CoreStrSinCtl, CoreStrSinInp, CoreStrSinLpe, CoreStrSinRpt, CoreStrSinTrn
CoreStrSinTrn
CoreAmlWatchListAddress , [dbo].[CoreAmlWatchListAlias] ,[dbo].[CoreamlwatchlistBirthPlace] ,[dbo].[CoreAmlWatchlistCatagoryMarking] , [dbo].[CoreAmlWatchlistChangeLogActionable] ,[dbo].[CoreAmlWatchlistCountry] ,[dbo].[CoreAmlWatchListDateOfBirth] ,[dbo].[CoreAmlWatchlistHistory] ,[dbo].[CoreAmlWatchListIdentification] ,[dbo].[CoreAmlWatchListKeyValueData]
[dbo].[CoreAmlWatchListKeyword]
CoreAlert
 CREATE PROCEDURE [dbo].[CoreFinancialTransaction_Search]    
    (    
      @FinancialTransactionId BIGINT = NULL ,    
      @RefClientId INT = NULL,    
      @FromDate DATETIME = NULL,    
      @ToDate DATETIME = NULL ,    
      @RefBankAccountId INT = NULL,    
      @RefSegmentId INT = NULL,    
      @RefVoucherTypeId INT = NULL,    
      @RefInstrumentTypeId INT = NULL,    
      @InstrumentNo VARCHAR(100) = NULL,    
      @Client VARCHAR(100) = NULL,    
   @IsExactSearch BIT=NULL,    
      @RowsPerPage INT = 25 , -- Rows per page    
      @PageNumber INT = 1, -- Page number    
   @FinancialTransactionIds VARCHAR(MAX)=NULL  
 )    
AS    
    BEGIN    
        DECLARE @InternalFinancialTransactionId BIGINT    
        SET @InternalFinancialTransactionId = @FinancialTransactionId    
       
        DECLARE @InternalRefClientId INT    
        SET @InternalRefClientId = @RefClientId    
          
        DECLARE @InternalFromDate DATETIME    
        SET @InternalFromDate = @FromDate    
          
        DECLARE @InternalToDate DATETIME       
        SET @InternalToDate = @ToDate        
                 
        DECLARE @InternalRefBankAccountId INT    
        SET @InternalRefBankAccountId = @RefBankAccountId    
            
         DECLARE @InternalRefSegmentId INT    
        SET @InternalRefSegmentId = @RefSegmentId    
            
         DECLARE @InternalRefVoucherTypeId INT    
        SET @InternalRefVoucherTypeId = @RefVoucherTypeId    
            
         DECLARE @InternalRefInstrumentTypeId INT    
        SET @InternalRefInstrumentTypeId = @RefInstrumentTypeId    
            
         DECLARE @InternalInstrumentNo VARCHAR(100)       
        SET @InternalInstrumentNo = @InstrumentNo     
            
       DECLARE @InternalClient VARCHAR(100)       
        SET @InternalClient = @Client     
            
  DECLARE @Internal@IsExactSearch BIT    
        SET @Internal@IsExactSearch = @IsExactSearch    
    
        DECLARE @InternalRowsPerPage INT    
        SET @InternalRowsPerPage = @RowsPerPage    
            
        DECLARE @InternalPageNumber INT    
        SET @InternalPageNumber = @PageNumber    
  
  DECLARE @InternalTransactionIds VARCHAR(MAX)  
  SET @InternalTransactionIds=Replace(@FinancialTransactionIds,' ','')  
            
          CREATE TABLE #CoreFinancialTransactionIds    
            (    
              CoreFinancialTransactionId BIGINT     
            )    
     
   IF(@InternalTransactionIds IS NULL)  
   BEGIN  
   INSERT INTO #CoreFinancialTransactionIds    
                EXEC CoreFinancialTransaction_GetCoreFinancialTransactionIds @InternalFinancialTransactionId, @InternalRefClientId,@InternalFromDate, @InternalToDate,    
                    @InternalRefBankAccountId, @InternalRefSegmentId, @InternalRefVoucherTypeId,  @InternalRefInstrumentTypeId,    
                    @InternalInstrumentNo, @InternalClient,@Internal@IsExactSearch    
          END  
    ELSE   
    BEGIN  
    INSERT INTO #CoreFinancialTransactionIds    
    SELECT CAST(s.items AS BIGINT)  
    FROM dbo.Split(@InternalTransactionIds, ',') s  
    END  
         PRINT 'Running Main SP - ' + CONVERT(VARCHAR(50), GETDATE(), 13)    
    
        SELECT  cft.CoreFinancialTransactionId as FinancialTransactionId,    
                cft.TransactionDate,    
                cft.ValueDate,    
                rc.ClientId as ClientId,    
    rc.Name as Client,    
    rba.Name AS BankAccount,    
    cft.ClientBankMicrCode,    
    cft.ClientBankAccountNo,    
    rs.Segment,    
    rvt.Name as VoucherType,    
                cft.VoucherNo,    
                cft.Amount,    
    rftit.Name as InstrumentType,    
                cft.InstrumentNo,    
                cft.TransactionReferenceNo,    
                cft.Remarks,    
                cft.AddedBy ,    
                cft.AddedOn ,    
                cft.EditedOn ,    
                cft.LastEditedBy ,    
    type2.Name AS Type2,    
 cft.UniqueReferenceNo,  
                ROW_NUMBER() OVER ( ORDER BY cft.AddedOn DESC ) AS RowNumber    
        INTO    #temp    
        FROM    dbo.CoreFinancialTransaction cft    
    INNER JOIN #CoreFinancialTransactionIds cfttemp ON cfttemp.CoreFinancialTransactionId = cft.CoreFinancialTransactionId    
                INNER JOIN dbo.RefClient rc ON cft.RefClientId = rc.RefClientId    
                INNER JOIN dbo.RefBankAccount rba ON cft.RefBankAccountId = rba.RefBankAccountId    
                LEFT JOIN dbo.RefSegmentEnum rs ON rs.RefSegmentEnumId = cft.RefSegmentId    
                LEFT JOIN dbo.RefFinancialTransactionInstrumentType rftit ON rftit.RefFinancialTransactionInstrumentTypeId = cft.RefFinancialTransactionInstrumentTypeId    
                LEFT JOIN dbo.RefVoucherType rvt ON rvt.RefVoucherTypeId = cft.RefVoucherTypeId    
    LEFT JOIN dbo.RefEnumValue type2 ON type2.RefEnumValueId = cft.FinancialTransactionType2RefEnumValueId    
                    
        ORDER BY cft.EditedOn DESC    
     
  PRINT 'Done Running Main SP - ' + CONVERT(VARCHAR(50), GETDATE(), 13)    
     
        SELECT  t.*    
        FROM    #temp t    
        WHERE (  
    @InternalTransactionIds IS NULL   
    AND  t.RowNumber BETWEEN ( ( ( @InternalPageNumber - 1 ) * @InternalRowsPerPage ) + 1 )    
                            AND     (@InternalPageNumber * @InternalRowsPerPage)    
    )  
    OR  
    (  
    @InternalTransactionIds IS NOT NULL  
    )  
        ORDER BY t.FinancialTransactionId DESC    
    
        PRINT 'Done Selecting Main SP - ' + CONVERT(VARCHAR(50), GETDATE(), 13)    
            
        SELECT  COUNT(1)    
        FROM    #temp    
     
    END  
	RefFinancialTransactionInstrumentType
	CoreFinancialTransaction_GetCoreFinancialTransactionIds

	CoreAmlWatchList
	RefClientDematAccount
	Select * from Corestrsin