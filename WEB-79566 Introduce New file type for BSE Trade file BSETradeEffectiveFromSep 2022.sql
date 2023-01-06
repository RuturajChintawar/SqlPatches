--File:StoredProcedures:dbo:CoreTrade_InsertBseCashFromStagingNew
--START RC WEB-80329
GO
CREATE PROCEDURE [dbo].[CoreTrade_InsertBseCashFromStagingNew]   
(  
 @Guid VARCHAR(40)  
)    
AS    
  BEGIN    
  
	  DECLARE @ErrorString VARCHAR(50),@InternalGuid VARCHAR(40) , @SegmentId INT, @CurrDate DATETIME, @RequestBy VARCHAR(50), @System VARCHAR(10), 
				@BseDatabaseId INT ,  @TradeDate DATETIME 

	  SELECT @SegmentId = dbo.GetSegmentId('BSE_CASH')
	  IF ( @SegmentId IS NULL )    
        BEGIN    
            RAISERROR ('Segment BSE_CASH not present',11,1) WITH seterror    
    
            RETURN 50010    
        END

	  SET @ErrorString='Error in Record at Line : '  
	  SET @InternalGuid = @Guid
	  SET @CurrDate = GETDATE()
	  SET @System = 'System'
      SELECT @RequestBy = AddedBy, @TradeDate = TradeDate  FROM  dbo.StagingCoreBseCashTrade  WHERE  [GUID] = @InternalGuid 
      SELECT @BseDatabaseId = RefDatabaseId   FROM   dbo.RefSegmentEnum    WHERE  [Segment] = 'BSE_CASH' 
	  
	  CREATE TABLE #ErrorListTable    
	  (    
		 LineNumber INT,    
		 ErrorMessage VARCHAR(MAX) DEFAULT '' COLLATE DATABASE_DEFAULT    
	  )  
  
	  SELECT    
		 ROW_NUMBER() OVER(ORDER BY stage.StagingCoreBseCashTradeId) AS LineNumber,  
		 stage.ScriptGroup,  
		 stage.ClientId  
	  INTO #TempStaging    
	  FROM dbo.StagingCoreBseCashTrade stage    
	  WHERE [GUID] = @InternalGuid  
  
	  INSERT INTO #ErrorListTable    
	  (    
		LineNumber    
	  )    
	  SELECT    
	   stage.LineNumber    
	  FROM #TempStaging stage  
  
      UPDATE stage    
      SET    stage.RefInstrumentId = inst.RefInstrumentId    
      FROM   dbo.StagingCoreBseCashTrade stage    
      INNER JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @SegmentId AND stage.[GUID] = @InternalGuid AND inst.Code = CONVERT(VARCHAR(50), stage.ScripCode)     
    
      INSERT INTO dbo.RefInstrument(RefSegmentId, Code, [Name], ScripId, GroupName, AddedBy, AddedOn, LastEditedBy,EditedOn)    
      SELECT DISTINCT @SegmentId, ScripCode, ScripId, ScripId, ScriptGroup, @System , @CurrDate,  @System, @CurrDate    
      FROM   dbo.StagingCoreBseCashTrade stage    
      WHERE  stage.RefInstrumentId IS NULL    
             AND stage.[GUID] = @InternalGuid    
     
     
		SELECT  
			stage.LineNumber,  
			stage.ScriptGroup  
		INTO #GroupCheck  
		FROM #TempStaging stage 
		LEFT JOIN dbo.RefScripGroup scripGroup  ON scripGroup.RefSegmentId = @SegmentId AND stage.ScriptGroup = scripGroup.[NAME]      
			WHERE  scripGroup.RefScripGroupId IS NULL  
     
		UPDATE #ErrorListTable    
			SET ErrorMessage = ErrorMessage + ', Scrip Group '+ gc.ScriptGroup COLLATE DATABASE_DEFAULT +' is not present with BSE_CASH Segment, please contact TSS support'  
		FROM #GroupCheck gc    
		WHERE #ErrorListTable.LineNumber = gc.LineNumber   
	
	  DROP TABLE #GroupCheck
    
         
      INSERT INTO dbo.RefSettlement  (RefSegmentId, [Name], SettlementType, FromDate, ToDate, AddedBy, AddedOn, LastEditedBy, EditedOn)    
      SELECT DISTINCT @SegmentId, stage.SettlementNo, ISNULL(scripGroup.SettlementType, 'N'),stage.TradeDate, stage.TradeDate,'System',@CurrDate, 'System', @CurrDate    
      FROM   dbo.StagingCoreBseCashTrade stage    
      INNER JOIN dbo.RefScripGroup scripGroup  ON stage.ScriptGroup = scripGroup.[NAME]  AND scripGroup.RefSegmentId = @SegmentId  
	  LEFT JOIN dbo.RefSettlement sett ON sett.RefSegmentId = @SegmentId AND sett.NAME = stage.SettlementNo  AND sett.SettlementType = scripGroup.SettlementType
      WHERE  sett.RefSettlementId IS NULL AND stage.[GUID] = @InternalGuid    
         
    
	   SELECT  
		  stage.LineNumber,  
		  stage.ClientId  
	   INTO #ClientCheck  
	   FROM #TempStaging stage 
	   LEFT JOIN dbo.RefClient client ON client.RefClientDatabaseEnumId = @BseDatabaseId AND stage.ClientId = client.ClientId   
	   WHERE client.RefClientId IS NULL  
  
	 UPDATE #ErrorListTable    
			SET ErrorMessage = ErrorMessage + ', Client '+ cc.ClientId COLLATE DATABASE_DEFAULT +' not present in Database'  
	 FROM #ClientCheck cc    
	 WHERE #ErrorListTable.LineNumber = cc.LineNumber 
 
	  DROP TABLE #ClientCheck
        
      SELECT t.StagingCoreBseCashTradeId,    
             CONVERT(BIGINT, ( CONVERT(VARCHAR, TradeId) + CONVERT(VARCHAR, CASE WHEN    
                               SEQ > 1    
                               THEN CONVERT(  NVARCHAR, 1109 + ROW_NUMBER()    
                               OVER    
                               (  PARTITION BY TransactionId, TradeId ORDER BY StagingCoreBseCashTradeId ) ) ELSE '' END ) )) AS NewTradeId    
      INTO   #updatetable    
      FROM   (SELECT ROW_NUMBER() OVER (  PARTITION BY TransactionId, TradeId ORDER BY StagingCoreBseCashTradeId ) AS 'SEQ',    
                     StagingCoreBseCashTradeId,    
                     TradeId,    
                     TransactionId    
              FROM   (SELECT TransactionId AS Tran_Id,    
                             TradeId       AS Trd_Id    
                      FROM  dbo.StagingCoreBseCashTrade    
                      WHERE  [GUID] = @InternalGuid    
                      GROUP  BY TradeDate,TransactionId,TradeId    
                      HAVING COUNT(1) > 1) AS tbl    
                     INNER JOIN dbo.StagingCoreBseCashTrade a ON tbl.Tran_Id = a.TransactionId AND Trd_Id = a.TradeId    
              WHERE  a.[GUID] = @InternalGuid) AS t    
    
      UPDATE dbo.StagingCoreBseCashTrade    
      SET    TradeId = t1.NewTradeId    
      FROM   dbo.StagingCoreBseCashTrade t2    
      INNER JOIN #updatetable t1 ON t1.StagingCoreBseCashTradeId = t2.StagingCoreBseCashTradeId    
    
        
   IF  (SELECT TOP 1   1  FROM   #ErrorListTable elt WHERE  elt.ErrorMessage IS NOT NULL  AND    elt.ErrorMessage <> '') = 1  
		BEGIN  
		  SELECT   @ErrorString + CONVERT(VARCHAR, elt.linenumber) COLLATE DATABASE_DEFAULT + ' ' + STUFF(elt.ErrorMessage,1,2,'') AS ErrorMessage  
		  FROM     #ErrorListTable elt  
		  WHERE    elt.ErrorMessage IS NOT NULL  
		  AND      elt.ErrorMessage <> ''  
		  ORDER BY elt.linenumber  
		END  
	 ELSE  
	BEGIN  
      SELECT @SegmentId                                       AS SegmentId,    
             settlement.RefSettlementId,    
             inst.RefInstrumentId,    
             client.RefClientId,    
             CASE stage.BuySell    
               WHEN 'B' THEN 'Buy'    
               WHEN 'S' THEN 'Sell'    
               ELSE NULL    
             END                                              AS BuySell,    
             stage.RateInPaise / CONVERT(DECIMAL(19, 6), 100) AS RateInPaise,    
             stage.Quantity,    
             stage.MemberId,    
             stage.TraderId,    
             stage.OppMemId,    
             stage.OppTraderId,    
             stage.TradeDateTime,    
             stage.TransactionId,    
             stage.TransactionType,    
             stage.TradeId,    
             stage.InstitutionId,    
             stage.OrderTimeStamp,    
             stage.AoPoFlag,    
             stage.AddedBy,    
             stage.AddedOn,    
             stage.AddedBy                                    AS LastEditedBy,    
             stage.AddedOn                                    AS EditedOn,    
             stage.TradeDate,    
             stage.ScriptGroup,    
             stage.CtclId    
      INTO   #stagingcorebsecashtrade    
      FROM   dbo.StagingCoreBseCashTrade stage    
      LEFT JOIN dbo.RefInstrument inst  ON inst.RefSegmentId = @SegmentId AND inst.Code = CONVERT(VARCHAR, stage.ScripCode)    
      LEFT JOIN dbo.RefScripGroup scripGroup  ON scripGroup.RefSegmentId = @SegmentId AND stage.ScriptGroup = scripGroup.[NAME]     
      LEFT JOIN dbo.RefSettlement settlement  ON ( settlement.RefSegmentId = @SegmentId  AND settlement.[NAME] = stage.SettlementNo AND settlement.SettlementType = ISNULL(scripGroup.SettlementType, 'N')    
                         AND stage.TradeDate BETWEEN settlement.FromDate AND settlement.ToDate )    
      LEFT JOIN dbo.RefClient client ON client.ClientId = stage.ClientId AND client.RefClientDatabaseEnumId = @BseDatabaseId  
	  LEFT JOIN dbo.CoreTrade trd1  ON trd1.RefSegmentId = @SegmentId  AND trd1.TradeDate = stage.TradeDate AND trd1.OrderId = stage.TransactionId AND trd1.TradeId = stage.TradeId
      WHERE  trd1.CoreTradeId IS NULL AND stage.[GUID] = @InternalGuid    
             
    
      INSERT INTO dbo.CoreTrade    
                  (RefSegmentId,    
                   RefSettlementId,    
                   RefInstrumentId,    
                   RefClientId,    
                   BuySell,    
                   Rate,    
                   Quantity,    
                   MemberId,    
                   TraderId,    
                   OppMemberId,    
                   OppTraderId,    
                   TradeDateTime,    
                   OrderId,    
                   TransactionType,    
                   TradeId,    
                   InstitutionId,    
                   OrderTimeStamp,    
                   AoPoFlag,    
                   AddedBy,    
                   AddedOn,    
                   LastEditedBy,    
                   EditedOn,    
                   TradeDate,    
                   ScripGroup,    
                   CtclId)    
      SELECT stage.SegmentId,    
             stage.RefSettlementId,    
             stage.RefInstrumentId,    
             stage.RefClientId,    
             stage.BuySell,    
             stage.RateInPaise,    
             stage.Quantity,    
             stage.MemberId,    
             stage.TraderId,    
             stage.OppMemId,    
             stage.OppTraderId,    
             stage.TradeDateTime,    
             stage.TransactionId,    
             stage.TransactionType,    
             stage.TradeId,    
             stage.InstitutionId,    
             stage.OrderTimeStamp,    
             stage.AoPoFlag,    
             stage.AddedBy,    
             stage.AddedOn,    
             stage.LastEditedBy,    
             stage.EditedOn,    
             stage.TradeDate,    
             stage.ScriptGroup,    
             stage.CtclId    
      FROM   #stagingcorebsecashtrade AS stage    
	  
      EXEC dbo.Coreettintimation_insertfromtrade    @RequestBy,    @TradeDate,  @SegmentId    
    END  
      DELETE FROM dbo.StagingCoreBseCashTrade WHERE  [GUID] = @InternalGuid    
  END
GO
--END RC WEB-80329
--File:Tables:dbo:RefAmlFileType:DML
--START RC WEB-80329
GO
EXEC [dbo].[RefAmlFileType_InsertIfNotExists] @FileTypeCode = 'AML' , @AmlFileTypeName = 'Trade_EffectiveFrom_Sep2022', @WatchListSourceName = ''
GO
--END RC WEB-80329