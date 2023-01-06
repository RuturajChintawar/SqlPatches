--WEB-73805-RC START
GO
 ALTER PROCEDURE dbo.AML_GetS168ClientTradingWithSameIPAddressScenarioAlertByCaseId   
(  
 @CaseId INT,    
 @ReportId INT    
)  
AS  
BEGIN  
   
  SELECT  
  c.CoreAmlScenarioAlertId,  
  c.CoreAlertRegisterCaseId,   
  c.RefClientId,   
  client.ClientId, --  
  client.[Name] AS [ClientName], --  
  c.RefAmlReportId,  
  c.TransactionDate AS TradeDate, --  
  c.RefSegmentEnumId AS SegmentId, --  
  seg.Segment, --  
  c.ISINName AS GroupName,
  c.ScripCode AS ScripCode,
  c.SellTerminal AS ScripName,
  c.BseCashTurnover AS ClientTO,  
  c.MoneyInCount AS NoOfClients,  
  c.Symbol AS IPAddress,  
  c.[Description],  
   
  
  c.ReportDate,  
  c.[Status],  
  c.Comments,  
  report.[Name] AS [ReportName],  
  c.AddedBy,  
  c.AddedOn,  
  c.EditedOn,  
  c.LastEditedBy,  
  c.ClientExplanation  
  FROM dbo.CoreAmlScenarioAlert c     
  INNER JOIN dbo.RefAmlReport report ON report.RefAmlReportId = c.RefAmlReportId   
  INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId  
  INNER JOIN dbo.CoreAlertRegisterCase alert ON alert.CoreAlertRegisterCaseId = c.CoreAlertRegisterCaseId  
  INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = c.RefSegmentEnumId  
  WHERE c.CoreAlertRegisterCaseId = @CaseId AND report.RefAmlReportId = @ReportId    
  
END  
GO
--WEB-73805-RC END
--WEB-73805-RC START
GO
 ALTER PROCEDURE dbo.CoreAmlScenarioClientTradingWithSameIPAddressAlert_Search   
(      
 @ReportId INT,    
 @RefSegmentEnumId INT = NULL,  
 @FromDate DATETIME = NULL,    
 @ToDate DATETIME = NULL,    
 @AddedOnFromDate DATETIME = NULL,    
 @AddedOnToDate DATETIME = NULL,  
 @EditedOnFromDate DATETIME = NULL,    
 @EditedOnToDate DATETIME = NULL,  
 @TxnFromDate DATETIME = NULL,    
 @TxnToDate DATETIME = NULL,    
 @Client VARCHAR(500) = NULL,    
 @Status INT = NULL,    
 @Comments VARCHAR(500) = NULL,  
 @Scrip VARCHAR(200) = NULL,  
 @CaseId BIGINT = NULL,  
 @PageNo INT = 1,  
 @PageSize INT = 100  
)      
AS       
BEGIN  
  
 DECLARE @InternalScrip VARCHAR(200), @InternalPageNo INT, @InternalPageSize INT  
   
 SET @InternalScrip = @Scrip  
 SET @InternalPageNo = @PageNo  
 SET @InternalPageSize = @PageSize  
  
 CREATE TABLE #data (CoreAmlScenarioAlertId BIGINT )  
 INSERT INTO #data EXEC dbo.CoreAmlScenarioAlert_SearchCommon   
  @ReportId = @ReportId,  
  @RefSegmentEnumId = @RefSegmentEnumId,  
  @FromDate = @FromDate,  
  @ToDate = @ToDate,  
  @AddedOnFromDate = @AddedOnFromDate,  
  @AddedOnToDate = @AddedOnToDate,    
  @EditedOnFromDate = @EditedOnFromDate,    
  @EditedOnToDate = @EditedOnToDate,   
  @TxnFromDate = @TxnFromDate,    
  @TxnToDate = @TxnToDate,  
  @Client = @Client,  
  @Status = @Status,  
  @Comments = @Comments,   
  @CaseId = @CaseId  
  
  
 SELECT temp.CoreAmlScenarioAlertId, ROW_NUMBER() OVER (ORDER BY alert.AddedOn DESC) AS RowNumber INTO #filteredAlerts  
 FROM #data temp   
 INNER JOIN dbo.CoreAmlScenarioAlert alert ON temp.CoreAmlScenarioAlertId = alert.CoreAmlScenarioAlertId  
  
 SELECT t.CoreAmlScenarioAlertId INTO #alertids   
 FROM #filteredAlerts t  
 WHERE t.RowNumber  
 BETWEEN (((@InternalPageNo - 1) * @InternalPageSize) + 1) AND @InternalPageNo * @InternalPageSize  
 ORDER BY t.CoreAmlScenarioAlertId DESC  
         
  
 SELECT   
  c.CoreAmlScenarioAlertId,  
  c.CoreAlertRegisterCaseId,  
  c.RefClientId,  
  client.ClientId, --  
  client.[Name] AS ClientName, --   
  c.RefAmlReportId,  
  c.TransactionDate AS TradeDate, --  
  c.RefSegmentEnumId AS SegmentId, --  
  seg.Segment, -- 
  c.ISINName AS GroupName,
  c.ScripCode AS ScripCode,
  c.SellTerminal AS ScripName,
  c.BseCashTurnover AS ClientTO,   
  c.MoneyInCount AS NoOfClients,  
  c.Symbol AS IPAddress,  
  c.[Description],  
  
  c.ReportDate,  
  c.AddedBy,  
  c.AddedOn,  
  c.LastEditedBy,  
  c.EditedOn,  
  c.Comments,  
  c.ClientExplanation,  
  c.[Status]  
 FROM #alertids temp  
 INNER JOIN dbo.CoreAmlScenarioAlert c ON c.CoreAmlScenarioAlertId = temp.CoreAmlScenarioAlertId  
 INNER JOIN dbo.RefClient client ON client.RefClientId = c.RefClientId  
 INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = c.RefSegmentEnumId  
         
 SELECT COUNT(1) FROM #filteredAlerts  
END  
GO
--WEB-73805-RC END
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S168 Client Trading With Same IP Address'

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
	'Number_Of_Entity',
	'',
	1,
	'No of clients with same IP',
	1,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
),(
	@AmlReportId,
	'Total_Turnover',
	'',
	1,
	'Client TO',
	1,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
),(
	@AmlReportId,
	'Number_Of_Entity',
	'',
	1,
	'No. of Traded Unique PIN',
	1,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
),(
	@AmlReportId,
	'Number_Of_Days',
	'',
	1,
	'Lookback period',
	1,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO