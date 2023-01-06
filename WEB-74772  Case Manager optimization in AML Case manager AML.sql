--WEB-74772-RC START--
GO   
 CREATE PROCEDURE [dbo].[GetAlertsByStatusForCaseManager_Search]    
(      
		
      @Status VARCHAR(8000) = NULL ,    
      @Count INT = 0 ,    
      @EmployeeId INT = 0 ,    
      @EmployeeIds VARCHAR(MAX) = NULL ,    
      @AssignEmpId INT = 0 ,    
      @RecentFirst BIT = 1 ,    
      @PageNo INT = 1 ,    
      @PageSize INT = 50 ,    
      @Pan VARCHAR(50) = NULL ,    
	  @ClientId varchar(50) =null,    
      @CaseIds VARCHAR(8000) = NULL ,
	  @AccountSegments VARCHAR(500) = NULL,
      @SearchMode INT = 0,    
      @IsWorkFlow BIT = 0,    
      @WorkFlowStep INT = 0,    
      @IsDpAlerts BIT= 0,    
      @IsExchangeAlerts BIT= 0,    
      @IsTradingAlerts BIT= 0,    
      @IsManualAlerts BIT= 0,    
      @RefAlertRegisterCaseType INT = 0    
)    
AS
BEGIN
  DECLARE  @StatusInternal VARCHAR(8000) ,@CountInternal INT ,@EmployeeIdsInternal VARCHAR(MAX) ,@EmployeeIdInternal INT ,@AssignEmpIdInternal INT ,  
           @RecentFirstInternal BIT ,@PageNoInternal INT ,@PageSizeInternal INT ,@PanInternal VARCHAR(50) ,@ClientIdInternal VARCHAR(50) ,@CaseIdsInternal VARCHAR(8000) ,
		   @AccountSegmentsInternal VARCHAR(500),@SearchModeInternal INT,@RefAlertRegisterCaseTypeInternal INT,@IsManualInternal BIT,@IsDpAlertsInternal BIT,  
           @IsExchangeAlertsInternal BIT, @IsTradingAlertsInternal BIT,@bseCashSegmentId INT,@bseCdxSegmentId INT,@InternalWorkflowRequest BIT,@InternalWorkFlowStep INT ,@FrompageNo INT, @TopageNo INT   
            
  SET @bseCashSegmentId = dbo.GetSegmentId('BSE_CASH')  
  SET @bseCdxSegmentId = dbo.GetSegmentId('BSE_CDX')  
  SET @StatusInternal = @Status                               
  SET @CountInternal = @Count  
  SET @EmployeeIdsInternal = @EmployeeIds  
  SET @EmployeeIdInternal = @EmployeeId
  SET @AssignEmpIdInternal = @AssignEmpId  
  SET @RecentFirstInternal = @RecentFirst  
  SET @PageNoInternal = @PageNo  
  SET @PageSizeInternal = @PageSize  
  SET @PanInternal = @Pan  
  SET @ClientIdInternal = @ClientId  
  SET @CaseIdsInternal = @CaseIds
  SET @AccountSegmentsInternal = @AccountSegments
  SET @SearchModeInternal = @SearchMode  
  SET @RefAlertRegisterCaseTypeInternal = @RefAlertRegisterCaseType
  SET @IsDpAlertsInternal = @IsDpAlerts  
  SET @IsExchangeAlertsInternal = @IsExchangeAlerts  
  SET @IsTradingAlertsInternal = @IsTradingAlerts  
  SET @IsManualInternal = @IsManualAlerts  
  SET @InternalWorkflowRequest = @IsWorkFlow     
  SET @InternalWorkFlowStep = @WorkFlowStep 
  SET @FrompageNo = ( @PageNoInternal - 1 ) * @PageSizeInternal + 1
  SET @TopageNo = (@PageNoInternal * @PageSizeInternal) 
  
  CREATE TABLE #SEGMENTNumberMapping(SegmentName VARCHAR(50) COLLATE DATABASE_DEFAULT,ReferenceNumber INT)  

  INSERT INTO #SEGMENTNumberMapping(SegmentName,ReferenceNumber) VALUES ( 'BSE_CDX',3)  
  INSERT INTO #SEGMENTNumberMapping(SegmentName,ReferenceNumber) VALUES ( 'BSE_CASH',3)  
  INSERT INTO #SEGMENTNumberMapping(SegmentName,ReferenceNumber) VALUES ( 'NSE_CASH',4)  
  INSERT INTO #SEGMENTNumberMapping(SegmentName,ReferenceNumber) VALUES ( 'NSE_FNO',4)  
  INSERT INTO #SEGMENTNumberMapping(SegmentName,ReferenceNumber) VALUES ( 'NSE_CDX',4)  
  INSERT INTO #SEGMENTNumberMapping(SegmentName,ReferenceNumber) VALUES ( 'MCXSX_CDX',4)  
  INSERT INTO #SEGMENTNumberMapping(SegmentName,ReferenceNumber) VALUES ( 'NCDEX_FNO',5)  
  INSERT INTO #SEGMENTNumberMapping(SegmentName,ReferenceNumber) VALUES ( 'MCX_FNO',6)  
  
  SELECT  RefSegmentEnumId ,mapping.ReferenceNumber   
  INTo #segment  
  FROM dbo.RefSegmentEnum  segment  
  INNER JOIN #SEGMENTNumberMapping mapping  ON mapping.SegmentName = segment.Segment  
  WHERE  Segment IN('NSE_CASH' ,'NSE_FNO' ,'NSE_CDX' ,'MCXSX_CDX' ,'NCDEX_FNO' ,'MCX_FNO' ,'BSE_CASH' ,'BSE_CDX')  
  
  
  SELECT  RefAmlReportId INTO #AmlReport  
  FROM dbo.RefAmlReport WHERE  RefAlertRegisterCaseTypeId  = @RefAlertRegisterCaseTypeInternal  
  
    
  SELECT  RefAlertTypeId INTO #excchangeReport  
  FROM dbo.RefAlertType WHERE  RefAlertRegisterCaseTypeId  = @RefAlertRegisterCaseTypeInternal  

  SELECT
	CONVERT(BIGINT,s.s)  AS CoreAlertRegisterCaseId
  INTO #tempCaseIds
  FROM dbo.ParseString(@CaseIdsInternal,',') s

  SELECT
	CONVERT(INT,s.s)  AS AlertRegisterStatusTypeId
  INTO #tempStatusIds
  FROM dbo.ParseString(@StatusInternal,',') s

  CREATE TABLE #AlertRegisterCaseIds  
   (  
	   CoreAlertRegisterCaseId BIGINT ,  
	   AlertRegisterStatusTypeId INT,  
	   RefWorkflowStepId INT ,  
	   LastWorkflowProgressId BIGINT ,  
	   WorkflowProgressAddedOn DATETIME,  
	   IsManual BIT  
   )  

   INSERT INTO #AlertRegisterCaseIds  
   EXEC CoreAlertRegisterCase_GetCoreAlertRegisterCaseIds   @EmployeeIdInternal,@EmployeeIdsInternal,@InternalWorkflowRequest, @AssignEmpIdInternal,@CountInternal,  
                @InternalWorkFlowStep, NULL, @RefAlertRegisterCaseTypeInternal  
  
  SELECT  DISTINCT tempCases.CoreAlertRegisterCaseId
  INTO #filteredCases01   
  FROM #AlertRegisterCaseIds tempCases  
  INNER JOIN dbo.CoreAlertRegisterCasePan casePan  ON casePan.CoreAlertRegisterCaseId = tempCases.CoreAlertRegisterCaseId  
  LEFT JOIN #tempCaseIds searchCases  ON searchCases.CoreAlertRegisterCaseId = tempCases.CoreAlertRegisterCaseId  
  LEFT JOIN #tempStatusIds st  ON st.AlertRegisterStatusTypeId = tempCases.AlertRegisterStatusTypeId
  LEFT JOIN dbo.CoreDpSuspiciousTransaction trans  ON trans.CoreAlertRegisterCaseId = tempCases.CoreAlertRegisterCaseId
  LEFT JOIN dbo.CoreAlert core  ON core.CoreAlertRegisterCaseId = tempCases.CoreAlertRegisterCaseId
  LEFT JOIN dbo.CoreAlertRegisterCaseAlertCount cont  ON cont.CoreAlertRegisterCaseId = tempCases.CoreAlertRegisterCaseId AND cont.TradingAlertCount > 0
  WHERE  (@PanInternal IS NULL OR casePan.PAN = @PanInternal)  
  AND (@CaseIdsInternal IS NULL OR searchCases.CoreAlertRegisterCaseId IS NOT NULL)   
  AND (@StatusInternal IS NULL OR st.AlertRegisterStatusTypeId IS NOT NULL) 
  AND (@IsDpAlertsInternal = 0 OR trans.CoreAlertRegisterCaseId IS NOT NULL)  
  AND (@IsExchangeAlertsInternal = 0 OR core.CoreAlertId IS NOT NULL) 
  AND (@IsTradingAlertsInternal = 0 OR cont.CoreAlertRegisterCaseId IS NOT NULL) 
  AND (@IsManualInternal = 0 OR tempCases.IsManual=1)
  
  DROP TABLE #tempCaseIds
  DROP TABLE #tempStatusIds
  
  SELECT temp.*
  INTO #clientCaseTemp
  FROM(
		SELECT alert.RefClientId,
		alert.CoreAlertRegisterCaseId ,
		ROW_NUMBER() OVER(PARTITION BY alert.RefClientId,alert.CoreAlertRegisterCaseId ORDER BY alert.RefClientId,alert.CoreAlertRegisterCaseId)  AS RN   
		FROM  #filteredCases01 temp  
	    INNER JOIN dbo.CoreAmlAlertRegisterCaseClientView alert ON alert.CoreAlertRegisterCaseId = temp.CoreAlertRegisterCaseId)temp
   WHERE temp.RN = 1
  
  SELECT 
	CONVERT(INT,acseg.s)  AS AccSegmentId
  INTO #tempAccSegment
  FROM dbo.ParseString(@AccountSegmentsInternal,',') acseg
    
  SELECT final.CoreAlertRegisterCaseId,final.PAN   
  INTO #TempCaseIdWithClientPan  
  FROM  
  (  
	   SELECT   
	   DISTINCT temp.CoreAlertRegisterCaseId,  
	   temp.Pan ,
	   ROW_NUMBER() OVER(PARTITION BY temp.CoreAlertRegisterCaseId ORDER BY temp.CoreAlertRegisterCaseId)  AS RowIndex   
	   FROM (  
			SELECT   
				tempCases.CoreAlertRegisterCaseId,
				ISNULL(client.PAN ,casePan.PAN)  AS Pan  
			FROM #filteredCases01 tempCases  
			INNER JOIN dbo.CoreAlertRegisterCasePan casePan  ON casePan.CoreAlertRegisterCaseId = tempCases.CoreAlertRegisterCaseId  
			INNER JOIN #clientCaseTemp caseclient  ON tempCases.CoreAlertRegisterCaseId=caseclient.CoreAlertRegisterCaseId  
			INNER JOIN dbo.RefClient client  ON caseclient.refclientId=client.RefClientId
			LEFT JOIN dbo.LinkRefClientRefCustomerSegment link  ON client.RefClientId = link.RefClientId 
			LEFT JOIN #tempAccSegment acseg  ON link.RefCustomerSegmentId = acseg.AccSegmentId
			WHERE (@ClientIdInternal IS NULL OR client.ClientId = @ClientIdInternal) AND
			(@AccountSegmentsInternal IS NULL OR acseg.AccSegmentId IS NOT NULL)

			UNION ALL  
  
			SELECT    
				tempCases.CoreAlertRegisterCaseId
				,casePan.PAN  AS Pan  
			FROM #filteredCases01 tempCases  
			INNER JOIN dbo.CoreAlertRegisterCasePan casePan ON casePan.CoreAlertRegisterCaseId = tempCases.CoreAlertRegisterCaseId  
			INNER JOIN #AlertRegisterCaseIds temp ON temp.CoreAlertRegisterCaseId = tempCases.CoreAlertRegisterCaseId  
			INNER JOIN dbo.RefClient manualClient ON manualClient.PAN=casePan.PAN  
			LEFT JOIN #clientCaseTemp caseclient ON temp.CoreAlertRegisterCaseId=caseclient.CoreAlertRegisterCaseId  
			LEFT JOIN dbo.LinkRefClientRefCustomerSegment link ON manualClient.RefClientId = link.RefClientId 
			LEFT JOIN #tempAccSegment acseg  ON link.RefCustomerSegmentId = acseg.AccSegmentId
			WHERE   temp.IsManual=1 and caseclient.refclientId IS NULL and   
			(@ClientIdInternal IS NULL OR manualClient.ClientId = @ClientIdInternal) AND
			(@AccountSegmentsInternal IS NULL OR acseg.AccSegmentId IS NOT NULL)
	  ) 
	 AS temp 
  )AS final  
  WHERE  final.RowIndex=1  
  
  DROP TABLE  #filteredCases01

  SELECT    
   temp.CoreAlertRegisterCaseId,  
   temp.PAN,  
   RANK() OVER ( ORDER BY CASE WHEN @RecentFirstInternal = 1 THEN temp.CoreAlertRegisterCaseId  ELSE -1 * temp.CoreAlertRegisterCaseId END DESC )  AS [Rank]  
  INTO #CaseWithPanAndRank  
  FROM #TempCaseIdWithClientPan temp 

  SELECT DISTINCT CoreAlertRegisterCaseId   
  INTO #tempPageingCases  
  FROM #CaseWithPanAndRank                          
  WHERE    [Rank]   
  BETWEEN @FrompageNo AND @TopageNo  
  
  DROP TABLE #CaseWithPanAndRank

  SELECT CoreAlertRegisterCaseId,  
		LastEditedBy,  
		EditedOn  
  INTO #WorkFlowStepChange  
  FROM(  
	  SELECT CoreAlertRegisterCaseId,  
		LastEditedBy,  
		EditedOn,  
		ROW_NUMBER() OVER(PARTITION BY CoreAlertRegisterCaseId ORDER BY EditedOn DESC) RO   
	  FROM(  
	  SELECT a.CoreAlertRegisterCaseId,  
		a.LastEditedBy,  
		a.EditedOn,  
		ROW_NUMBER() OVER(PARTITION BY a.CoreAlertRegisterCaseId,a.AlertRegisterStatusTypeId,AuditDMLAction ORDER BY a.editedon ) R   
	  FROM dbo.CoreAlertRegisterCase_DataAudit a  
	  INNER JOIN #tempPageingCases s  ON s.CoreAlertRegisterCaseId=a.CoreAlertRegisterCaseId ) T WHERE  R=1   
  )G WHERE  RO=1  
  
  
  SELECT  cases.CoreAlertRegisterCaseId ,  
	      cases.AlertRegisterStatusTypeId,  
	      cases.AddedBy,  
		  cases.AddedOn,  
		  cases.EditedOn,  
		  tempCase.RefWorkflowStepId,  
		  tempCase.LastWorkflowProgressId,  
		  tempCase.IsManual,  
		  CASE WHEN ISNULL(w.EditedOn,'')='' THEN wl.EditedOn ELSE w.EditedOn END  AS WorkflowProgressAddedOn,  
		  CASE WHEN ISNULL(w.LastEditedBy,'')='' THEN wl.LastEditedBy ELSE w.LastEditedBy END  AS WorkflowProgressAddedBy  
  INTO #TempCase   
  FROM #tempPageingCases temp  
  INNER JOIN #AlertRegisterCaseIds tempCase  ON tempCase.CoreAlertRegisterCaseId = temp.CoreAlertRegisterCaseId   
  INNER JOIN dbo.CoreAlertRegisterCase cases   ON cases.CoreAlertRegisterCaseId=temp.CoreAlertRegisterCaseId              
  LEFT JOIN dbo.coreworkflowprogresslatest wl  ON wl.CoreWorkflowProgressId=tempCase.LastWorkflowProgressId  
  LEFT JOIN #WorkFlowStepChange w  ON w.CoreAlertRegisterCaseId=temp.CoreAlertRegisterCaseId  
    
   CREATE TABLE #Table  
  (  
	   CoreAlertRegisterCaseId BIGINT NOT NULL,  
	   AlertRegisterStatusTypeId INT,  
	   WorkflowStep VARCHAR(500) COLLATE DATABASE_DEFAULT,  
	   WorkflowStepId INT ,  
	   LastWorkflowProgressId BIGINT,  
	   IsManual BIT,  
	   PAN VARCHAR(50) COLLATE DATABASE_DEFAULT,  
	   WorkflowProgressAddedBy VARCHAR(50) COLLATE DATABASE_DEFAULT,  
	   WorkflowProgressAddedOn DATETIME  
  )  
  
	IF ( @SearchModeInternal = 0 ) 
        BEGIN   
             INSERT INTO #Table  
                    SELECT  m.CoreAlertRegisterCaseId,  
                     m.AlertRegisterStatusTypeId,  
                     ws.[Name] AS WorkflowStep,  
					 m.RefWorkflowStepId AS WorkflowStepId,  
					 m.LastWorkflowProgressId,  
					 m.IsManual,  
					 casewithpan.PAN,  
					 m.WorkflowProgressAddedBy,  
					 m.WorkflowProgressAddedOn  
			 FROM  #TempCase m  
			 INNER JOIN #tempPageingCases pageing  ON pageing.CoreAlertRegisterCaseId = m.CoreAlertRegisterCaseId  
			 INNER JOIN  #TempCaseIdWithClientPan casewithpan  ON casewithpan.CoreAlertRegisterCaseId = pageing.CoreAlertRegisterCaseId 
			 LEFT JOIN dbo.RefWorkflowStep ws  ON m.RefWorkflowStepId = ws.RefWorkflowStepId  
        END  
      
	 SELECT temp.*    
     INTO #CoreAlertRegisterCaseAssignmentHistoryLatest  
	 FROM  (
			 SELECT   assign.CoreAlertRegisterCaseAssignmentHistoryId,  
					  assign.CoreAlertRegisterCaseId,  
					  assign.AssignorRefEmployeeId,  
					  assign.AssigneeRefEmployeeId,  
					  assign.AddedBy,  
					  assign.AddedOn,  
					  assign.LastEditedBy,  
					  assign.EditedOn  ,
					  ROW_NUMBER() OVER (PARTITION BY assign.CoreAlertRegisterCaseId ORDER BY assign.CoreAlertRegisterCaseAssignmentHistoryId DESC)  AS RowNum  
			 FROM dbo.CoreAlertRegisterCaseAssignmentHistory assign  
			INNER JOIN #TempCaseIdWithClientPan temp  ON temp.CoreAlertRegisterCaseId = assign.CoreAlertRegisterCaseId  ) temp  
	 WHERE temp.RowNum = 1  
      
  
   
   
		SELECT  c.CoreAlertRegisterCaseId ,  
                c.AlertRegisterStatusTypeId ,  
                temp.AssigneeRefEmployeeId  AS AssigneeEmployeeId,  
                t.WorkflowStep,  
                t.WorkflowStepId,  
                t.LastWorkflowProgressId,  
				c.AddedBy ,  
				c.AddedOn,  
				c.EditedOn,  
				c.WorkflowProgressAddedBy,  
				c.WorkflowProgressAddedOn  
        FROM    #TempCase c  
                INNER JOIN #Table t  ON c.CoreAlertRegisterCaseId = t.CoreAlertRegisterCaseId  
                LEFT JOIN #CoreAlertRegisterCaseAssignmentHistoryLatest temp  ON temp.CoreAlertRegisterCaseId=c.CoreAlertRegisterCaseId  
                ORDER BY c.CoreAlertRegisterCaseId ASC  

  
  SELECT tempallalerts.*
  INTO #TempCasesAndAlert  
  FROM (  
	  SELECT   
		  alert.CoreAlertRegisterCaseId,alert.RefClientId,  
		  null  AS DpSuspiciousType,  
		  SUM(CASE WHEN alert.[Status] = 1 THEN 1  
			 ELSE 0  
		   END)  AS Pending ,  
		  SUM(CASE WHEN alert.[Status] = 2 THEN 1  
			 ELSE 0  
		   END)  AS Closed ,  
		  SUM(CASE WHEN alert.[Status] = 3 THEN 1  
			 ELSE 0  
		   END)  AS Reported ,  
		  SUM(CASE WHEN alert.[Status] = 4 THEN 1  
			 ELSE 0  
		   END)  AS ToBeReported ,  
		  COUNT(1)  AS Cnt ,  
		  MAX(alert.AddedOn)  AS LastAddedOn ,  
		  MAX(alert.EditedOn)  AS LastEditedOn,  
		  1  AS AlertTypeNumber,  
		  cases.WorkflowProgressAddedBy,  
		  cases.WorkflowProgressAddedOn  
	  FROM CoreAmlScenarioAlert alert  
	  INNER JOIN #Table cases  ON cases.CoreAlertRegisterCaseId=alert.CoreAlertRegisterCaseId
	  GROUP BY alert.CoreAlertRegisterCaseId,alert.RefClientId,  
		  cases.WorkflowProgressAddedBy,  
		  cases.WorkflowProgressAddedOn  
  
	  UNION ALL   
  
	  SELECT   
	  alert.CoreAlertRegisterCaseId,alert.RefClientId,  
	  dpt.NAME  AS DpSuspiciousType ,  
	  SUM(CASE WHEN alert.[Status] = 1 THEN 1  
			 ELSE 0  
		   END)  AS Pending ,  
		  SUM(CASE WHEN alert.[Status] = 2 THEN 1  
			 ELSE 0  
		   END)  AS Closed ,  
		  SUM(CASE WHEN alert.[Status] = 3 THEN 1  
			 ELSE 0  
		   END)  AS Reported ,  
		  SUM(CASE WHEN alert.[Status] = 4 THEN 1  
			 ELSE 0  
		   END)  AS ToBeReported ,  
		  COUNT(1)  AS Cnt ,  
		  MAX(alert.AddedOn)  AS LastAddedOn ,  
		  MAX(alert.EditedOn)  AS LastEditedOn,  
		  2  AS AlertTypeNumber,  
		  cases.WorkflowProgressAddedBy,  
		  cases.WorkflowProgressAddedOn  
	  FROM dbo.CoreDpSuspiciousTransaction alert  
	  INNER JOIN #Table cases  ON cases.CoreAlertRegisterCaseId=alert.CoreAlertRegisterCaseId  
	  INNER JOIN dbo.CoreDpSuspiciousTransactionBatch b  ON alert.CoreDpSuspiciousTransactionBatchId = b.CoreDpSuspiciousTransactionBatchId  
	  INNER JOIN dbo.RefDpSuspiciousTransactionType dpt  ON b.RefDpSuspiciousTransactionTypeId = dpt.RefDpSuspiciousTransactionTypeId  
	  group by alert.CoreAlertRegisterCaseId,dpt.NAME,alert.RefClientId,  
		  cases.WorkflowProgressAddedBy,  
		  cases.WorkflowProgressAddedOn  
  
	  UNION ALL     

	  SELECT   
		  alert.CoreAlertRegisterCaseId,alert.RefClientId,  
		  null  AS DpSuspiciousType,  
		  SUM(CASE WHEN alert.[Status] = 1 THEN 1  
				 ELSE 0  
			   END)  AS Pending ,  
		  SUM(CASE WHEN alert.[Status] = 2 THEN 1  
			 ELSE 0  
		   END)  AS Closed ,  
		  SUM(CASE WHEN alert.[Status] = 3 THEN 1  
			 ELSE 0  
		   END)  AS Reported ,  
		  SUM(CASE WHEN alert.[Status] = 4 THEN 1  
			 ELSE 0  
		   END)  AS ToBeReported ,  
		  COUNT(1)  AS Cnt ,  
		  MAX(alert.AddedOn)  AS LastAddedOn ,  
		  MAX(alert.EditedOn)  AS LastEditedOn,  
		  segment.ReferenceNumber  AS AlertTypeNumber,  
		  cases.WorkflowProgressAddedBy,  
		  cases.WorkflowProgressAddedOn  
	  FROM CoreAlert alert  
	  INNER JOIN #Table cases  ON cases.CoreAlertRegisterCaseId=alert.CoreAlertRegisterCaseId  
	  INNER JOIN #segment segment  ON segment.RefSegmentEnumId = alert.RefSegmentId   
	  GROUP BY alert.CoreAlertRegisterCaseId,alert.RefClientId,  
		  cases.WorkflowProgressAddedBy,  
		  cases.WorkflowProgressAddedOn,segment.ReferenceNumber  
  
	  UNION ALL     
  
	  SELECT   
		  cases.CoreAlertRegisterCaseId,cl.RefClientId,  
		  NULL  AS DpSuspiciousType,  
		  0  AS Pending ,  
		  0  AS Closed ,  
		  0  AS Reported ,  
		  0  AS ToBeReported ,  
		  0  AS Cnt ,  
		  NULL  AS LastAddedOn ,  
		  NULL  AS LastEditedOn,  
		  7  AS AlertTypeNumber,  
		  cases.WorkflowProgressAddedBy,  
		  cases.WorkflowProgressAddedOn  
	  FROM #Table cases  
	  INNER JOIN RefClient cl  ON cases.Pan=cl.PAN  
	  WHERE   cases.IsManual=1  
	  GROUP BY cases.CoreAlertRegisterCaseId,
			  cl.RefClientId,  
			  cases.WorkflowProgressAddedBy,  
			  cases.WorkflowProgressAddedOn  
  
  )  AS tempallalerts  
  
  SELECT risk.*
  INTO #TempLinkRefClientRefRiskCategoryLatest
  FROM (SELECT   
		  linkrisk.LinkRefClientRefRiskCategoryId,  
		  linkrisk.RefClientId,  
		  linkrisk.RefRiskCategoryId,    
		  linkrisk.FROMDate,  
		  linkrisk.ToDate,  
		  linkrisk.AddedBy,  
		  linkrisk.AddedOn,  
		  linkrisk.LastEditedBy,  
		  linkrisk.EditedOn,  
		  linkrisk.Notes,
		  ROW_NUMBER() OVER (PARTITION BY linkrisk.RefClientId ORDER BY ISNULL(linkrisk.ToDate, '31-Dec-9999') DESC)  AS RowNum  
	  FROM dbo.LinkRefClientRefRiskCategory linkrisk  
	  INNER JOIN #TempCasesAndAlert alert  ON alert.RefClientId = linkrisk.RefClientId)risk
  WHERE risk.RowNum = 1 

  
  
  
	 SELECT   
		 alert.CoreAlertRegisterCaseId  AS CaseId ,  
		 alert.RefClientId ,  
		 alert.DpSuspiciousType,  
		 client.Name ,  
		 client.Pan ,  
		 client.ClientId ,  
		 alert.Pending ,  
		 alert.Closed ,  
		 alert.Reported ,  
		 alert.ToBeReported ,  
		 alert.Cnt ,  
		 alert.LastAddedOn ,  
		 alert.LastEditedOn,  
		 CASE WHEN client.RefClientSpecialCategoryId IS NOT NULL THEN   
		 CASE WHEN   
		 csc.[Name]='High Networth Client' THEN 'HNI' ELSE csc.[Name] END  
		 ELSE '' END  AS CSCCategory,  
		 risk.[Name]  AS ClientRiskCategory,  
		 alert.AlertTypeNumber,  
		 inter.IntermediaryCode,  
		inter.Name  AS IntermediaryName,  
		inter.TradeName,
		STUFF(
	   (SELECT ','+ seg.[Name]
	   FROM dbo.LinkRefClientRefCustomerSegment linkseg
		   INNER JOIN dbo.RefCustomerSegment seg  ON linkseg.RefCustomerSegmentId = seg.RefCustomerSegmentId
		   WHERE  linkseg.RefClientId=alert.RefClientId 
		FOR XML PATH('')
		),
	  1,1,'')  AS AccountSegment,
		alert.WorkflowProgressAddedBy,  
		alert.WorkflowProgressAddedOn  
		 INTO #TempAllAlerts 
	 FROM #TempCasesAndAlert alert  
	 INNER JOIN dbo.RefClient client  ON alert.RefClientId=client.RefClientId
	 LEFT JOIN dbo.LinkRefClientRefCustomerSegment linkseg  ON linkseg.RefClientId = alert.RefClientId
	 LEFT JOIN #tempAccSegment acseg  ON linkseg.RefCustomerSegmentId = acseg.AccSegmentId
	 LEFT JOIN dbo.RefClientSpecialCategory csc  ON csc.RefClientSpecialCategoryId=client.RefClientSpecialCategoryId  
	 LEFT JOIN #TempLinkRefClientRefRiskCategoryLatest link  ON link.RefClientId=client.RefClientId  
	 LEFT JOIN dbo.RefRiskCategory risk  ON risk.RefRiskCategoryId=link.RefRiskCategoryId  
	 LEFT JOIN dbo.RefIntermediary inter  ON client.RefIntermediaryId = inter.RefIntermediaryId  
	 WHERE  @AccountSegmentsInternal IS NULL OR acseg.AccSegmentId IS NOT NULL

	 DROP TABLE #TempLinkRefClientRefRiskCategoryLatest
	 DROP TABLE #TempCasesAndAlert
  
	select CaseId,RefClientId,Name,Pan,ClientId,Pending,Closed,Reported,ToBeReported,Cnt,LastAddedOn,LastEditedOn,CSCCategory,ClientRiskCategory,IntermediaryCode,IntermediaryName,TradeName,AccountSegment,WorkflowProgressAddedBy,WorkflowProgressAddedOn from #TempAllAlerts where AlertTypeNumber=1  
	SELECT CaseId,RefClientId,DpSuspiciousType,Name,Pan,ClientId,Pending,Closed,Reported,ToBeReported,Cnt,LastAddedOn,LastEditedOn,CSCCategory,ClientRiskCategory,IntermediaryCode,IntermediaryName,TradeName,AccountSegment,WorkflowProgressAddedBy,WorkflowProgressAddedOn FROM #TempAllAlerts WHERE  AlertTypeNumber=2
	SELECT CaseId,RefClientId,Name,Pan,ClientId,Pending,Closed,Reported,ToBeReported,Cnt,LastAddedOn,LastEditedOn,CSCCategory,ClientRiskCategory,IntermediaryCode,IntermediaryName,TradeName,AccountSegment,WorkflowProgressAddedBy,WorkflowProgressAddedOn FROM #TempAllAlerts WHERE  AlertTypeNumber = 3
	SELECT CaseId,RefClientId,Name,Pan,ClientId,Pending,Closed,Reported,ToBeReported,Cnt,LastAddedOn,LastEditedOn,CSCCategory,ClientRiskCategory,IntermediaryCode,IntermediaryName,TradeName,AccountSegment,WorkflowProgressAddedBy,WorkflowProgressAddedOn FROM #TempAllAlerts WHERE  AlertTypeNumber = 4  
	SELECT CaseId,RefClientId,Name,Pan,ClientId,Pending,Closed,Reported,ToBeReported,Cnt,LastAddedOn,LastEditedOn,CSCCategory,ClientRiskCategory,IntermediaryCode,IntermediaryName,TradeName,AccountSegment,WorkflowProgressAddedBy,WorkflowProgressAddedOn FROM #TempAllAlerts WHERE  AlertTypeNumber = 5  
	SELECT CaseId,RefClientId,Name,Pan,ClientId,Pending,Closed,Reported,ToBeReported,Cnt,LastAddedOn,LastEditedOn,CSCCategory,ClientRiskCategory,IntermediaryCode,IntermediaryName,TradeName,AccountSegment,WorkflowProgressAddedBy,WorkflowProgressAddedOn FROM #TempAllAlerts WHERE  AlertTypeNumber = 6  
	SELECT CaseId,RefClientId,Name,Pan,ClientId,Pending,Closed,Reported,ToBeReported,Cnt,LastAddedOn,LastEditedOn,CSCCategory,ClientRiskCategory,IntermediaryCode,IntermediaryName,TradeName,AccountSegment,WorkflowProgressAddedBy,WorkflowProgressAddedOn FROM #TempAllAlerts WHERE  AlertTypeNumber = 7  
    
	DROP TABLE #TempAllAlerts

		SELECT  AlertRegisterStatusTypeId ,  
                COUNT(1)  AS CasesCount  
        FROM    #AlertRegisterCaseIds  
        GROUP BY AlertRegisterStatusTypeId  

		SELECT COUNT(1)  AS MatchingResultCount 
		FROM  #TempCaseIdWithClientPan  
  
  
  
	SELECT SUM(TradingAlertCount)  AS TotalPendingAlertsCount 
	FROM   
		(SELECT v.CoreAlertRegisterCaseId,v.TradingAlertCount FROM CoreAlertRegisterCaseAlertCount v  
		INNER JOIN #AlertRegisterCaseIds vc  ON v.CoreAlertRegisterCaseId = vc.CoreAlertRegisterCaseId  
		WHERE    vc.AlertRegisterStatusTypeId = 1  
		Union all  
		SELECT t.CoreAlertRegisterCaseId,COUNT(1)  AS TradingAlertCount FROM dbo.CoreDpSuspiciousTransaction t   
		INNER JOIN #AlertRegisterCaseIds vc  ON t.CoreAlertRegisterCaseId = vc.CoreAlertRegisterCaseId  
		WHERE    vc.AlertRegisterStatusTypeId = 1  
		group by t.CoreAlertRegisterCaseId  
		Union all  
		SELECT t.CoreAlertRegisterCaseId,COUNT(1)  AS TradingAlertCount FROM dbo.CoreAlert t   
		INNER JOIN #AlertRegisterCaseIds vc  ON t.CoreAlertRegisterCaseId = vc.CoreAlertRegisterCaseId  
		WHERE    vc.AlertRegisterStatusTypeId = 1  
		group by t.CoreAlertRegisterCaseId  
		)  AS tempalertcount  
          
          
    CREATE TABLE #ClosedAlertsCases  
    (  
          ClosedAlertsCasesCount INT  
    )  
  
   
    SELECT CASE WHEN SUM(ClosedAlertsCasesCount) IS NULL THEN 0  
                 ELSE SUM(ClosedAlertsCasesCount)  
            END  AS ClosedAlertsCasesCount  
    FROM #ClosedAlertsCases  
  
    SELECT  0  AS PendingDpCasesWithDormantAlerts  
      
      
   SELECT  t.CoreAlertRegisterCaseId  AS CaseId ,  
            cl.RefClientId ,                
            MAX(cl.[Name])  AS [Name] ,  
            MAX(cl.Pan)  AS Pan ,  
            MAX(cl.ClientId)  AS ClientId,  
            alert.AlertRegisterStatusTypeId,  
            0  AS Pending ,  
            0  AS Closed ,  
            0  AS Reported ,  
            0  AS ToBeReported ,                
            MAX(alert.AddedOn)  AS LastAddedOn ,  
            MAX(alert.EditedOn)  AS LastEditedOn,  
            MAX(t.WorkflowStep)  AS WorkflowStep,  
            t.WorkflowStepId,  
            temp.AssigneeRefEmployeeId  AS AssigneeEmployeeId,  
            inter.IntermediaryCode,  
            inter.[Name]  AS IntermediaryName,  
            inter.TradeName,
			STUFF(
			   (SELECT ','+ seg.[Name]
			   FROM dbo.LinkRefClientRefCustomerSegment linkseg
				   INNER JOIN dbo.RefCustomerSegment seg  ON linkseg.RefCustomerSegmentId = seg.RefCustomerSegmentId
				   WHERE  linkseg.RefClientId=cl.RefClientId 
				FOR XML PATH('')
				),
			  1,1,'')  AS AccountSegment,
			t.WorkflowProgressAddedBy,  
			t.WorkflowProgressAddedOn  
    FROM    #TempCase alert  
            INNER JOIN #Table t  ON t.CoreAlertRegisterCaseId = alert.CoreAlertRegisterCaseId  
            INNER JOIN dbo.CoreAlertRegisterCasePan p  ON p.CoreAlertRegisterCaseId = alert.CoreAlertRegisterCaseId  
            INNER JOIN [dbo].RefClient cl  ON LEN(cl.PAN)=10 AND LEN(p.PAN)=10 AND cl.PAN = p.PAN
			LEFT JOIN dbo. LinkRefClientRefCustomerSegment linkseg  ON linkseg.RefClientId = cl.RefClientId
			LEFT JOIN #tempAccSegment acseg  ON linkseg.RefCustomerSegmentId = acseg.AccSegmentId
            LEFT JOIN #CoreAlertRegisterCaseAssignmentHistoryLatest temp  ON temp.CoreAlertRegisterCaseId=alert.CoreAlertRegisterCaseId  
            LEFT JOIN dbo.RefIntermediary inter  ON cl.RefIntermediaryId = inter.RefIntermediaryId  
	WHERE  @AccountSegmentsInternal IS NULL OR acseg.AccSegmentId IS NOT NULL
    GROUP BY t.CoreAlertRegisterCaseId,  
            cl.RefClientId ,  
            alert.AlertRegisterStatusTypeId,  
            t.WorkflowStepId,  
            temp.AssigneeRefEmployeeId,  
            inter.IntermediaryCode,  
            inter.[Name],  
            inter.TradeName,
			t.WorkflowProgressAddedBy,  
			t.WorkflowProgressAddedOn    
END 
GO
--WEB-74772-RC END  --
