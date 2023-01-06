GO
EXEC dbo.Sys_DropIfExists 'IncomeDetails_InsertFromCoreClientIncomeDetailsHistory','P'
GO
CREATE PROCEDURE [dbo].[IncomeDetails_InsertFromCoreClientIncomeDetailsHistory]            
(           
 @Guid VARCHAR(100),            
 @AddedBy VARCHAR(100)        
)            
AS              
BEGIN            
   DECLARE @InternalGuid VARCHAR(50),@InternalAddedBy VARCHAR(100), @CurrentDate DATETIME                
   SET @InternalGuid =  @Guid            
   SET @InternalAddedBy = @AddedBy            
   SET @CurrentDate = GETDATE()   
   
   INSERT INTO dbo.LinkRefClientRefIncomeGroup  
	(
		RefClientId,
		RefIncomeGroupId,
		Income,
		Networth,
		FromDate,
		AddedBy,
		AddedOn,
		LastEditedBy,
		EditedOn
	)(
	SELECT 
		ids.RefClientId,
		his.RefIncomeGroupId,
		his.Income,
		his.Networth * 100000,
		ISNULL(his.FromDate,@CurrentDate),
		@InternalAddedBy,
		@CurrentDate,
		@InternalAddedBy,
		@CurrentDate
	FROM #CoreClientHistoryIds ids
	INNER JOIN dbo.CoreClientIncomeDetailsHistory his ON ids.CoreClientHistoryId = his.CoreClientHistoryId AND his.[Guid] = @InternalGuid AND ISNULL(his.RefIncomeGroupId, 0) <> 0
	)
END    
GO

GO
EXEC dbo.Sys_DropIfExists 'IncomeDetails_UpdateFromCoreClientIncomeDetailsHistory','P'
GO
CREATE PROCEDURE [dbo].[IncomeDetails_UpdateFromCoreClientIncomeDetailsHistory]                
(               
	 @Guid VARCHAR(100),                
	 @AddedBy VARCHAR(100)            
)                
AS                  
BEGIN                
   DECLARE @InternalGuid VARCHAR(50),@InternalAddedBy VARCHAR(100), @CurrentDate DATETIME                
                
   SET @InternalGuid =  @Guid                
   SET @InternalAddedBy = @AddedBy                
   SET @CurrentDate = GETDATE()      
    
   SELECT    
	t.*    
   INTO #latestRefIncomeUpdate    
   FROM     
    (
		SELECT    
			  link.LinkRefClientRefIncomeGroupId,    
			  his.FromDate,    
			  ROW_NUMBER() OVER(PARTITION BY link.RefClientId ORDER BY link.FromDate DESC) RN    
		FROM #CoreClientHistoryIds tempHis    
		INNER JOIN dbo.CoreClientIncomeDetailsHistory his  ON tempHis.CoreClientHistoryId = his.CoreClientHistoryId  AND his.[Guid] = @InternalGuid  AND ISNULL(his.RefIncomeGroupId, 0) <> 0      
		INNER JOIN dbo.LinkRefClientRefIncomeGroup link ON link.RefClientId = tempHis.RefClientId    AND link.FromDate < his.FromDate
	) t    
   WHERE t.RN = 1    
    
   UPDATE link    
   SET link.ToDate =  DATEADD(DAY, -1, ISNULL(latest.FromDate,@CurrentDate))   
   FROM dbo.LinkRefClientRefIncomeGroup link    
   INNER JOIN #latestRefIncomeUpdate latest ON latest.LinkRefClientRefIncomeGroupId = link.LinkRefClientRefIncomeGroupId
   WHERE link.ToDate IS NULL

   UPDATE income      
	  SET       
	  income.RefIncomeGroupId = his.RefIncomeGroupId,    
	  income.Income = his.Income,    
	  income.Networth = his.Networth * 100000,    
      income.LastEditedBy = @InternalAddedBy,      
	  income.EditedOn = @CurrentDate      
   FROM dbo.CoreClientIncomeDetailsHistory his      
   INNER JOIN #CoreClientHistoryIds tempHis ON tempHis.CoreClientHistoryId = his.CoreClientHistoryId  AND his.[Guid] = @InternalGuid AND ISNULL(his.RefIncomeGroupId, 0) <> 0     
   INNER JOIN dbo.LinkRefClientRefIncomeGroup income ON income.RefClientId = tempHis.RefClientId AND income.FromDate = his.FromDate     
   WHERE (income.Income <> his.Income OR income.RefIncomeGroupId <> his.RefIncomeGroupId OR income.Networth <> his.Networth* 100000)      
       
	INSERT INTO dbo.LinkRefClientRefIncomeGroup      
		(    
		  RefClientId,    
		  RefIncomeGroupId,    
		  Income,    
		  Networth,    
		  FromDate,    
		  AddedBy,    
		  AddedOn,    
		  LastEditedBy,    
		  EditedOn    
		)    
	SELECT     
		   ids.RefClientId,    
		   his.RefIncomeGroupId,    
		   his.Income,    
		   his.Networth* 100000,    
		   ISNULL(his.FromDate, @CurrentDate),    
		   @InternalAddedBy,    
		   @CurrentDate,    
		   @InternalAddedBy,    
		   @CurrentDate    
	FROM #CoreClientHistoryIds ids    
	INNER JOIN dbo.CoreClientIncomeDetailsHistory his ON ids.CoreClientHistoryId = his.CoreClientHistoryId AND his.[Guid] = @InternalGuid AND ISNULL(his.RefIncomeGroupId, 0) <> 0   
	LEFT JOIN dbo.LinkRefClientRefIncomeGroup grp ON grp.RefClientId = ids.RefClientId AND ISNULL(his.FromDate,@CurrentDate) = grp.FromDate    
	WHERE grp.LinkRefClientRefIncomeGroupId IS NULL     
END 
GO