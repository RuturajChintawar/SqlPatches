------RC-WEB-65063 START
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S151 High Turnover by Group of Clients in 1 Day EQ'

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
	'Active_In_Report',
	'True',
	1,
	'No. of clients in a group >1',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S152 High Turnover by Group of Clients in 1 Day FNO'

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
	'Active_In_Report',
	'True',
	1,
	'No. of clients in a group >1',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S154 High Turnover by Group of New Clients in 1 Day EQ'

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
	'Active_In_Report',
	'True',
	1,
	'No. of clients in a group >1',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S156 High Turnover by Group of New Clients in 1 Day FNO'

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
	'Active_In_Report',
	'True',
	1,
	'No. of clients in a group >1',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S157 Small Orders in Single Stock by Group of Clients EQ'

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
	'Active_In_Report',
	'True',
	1,
	'No. of clients in a group >1',
	9,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S159 Small Orders in Single Stock by Group of Clients FNO'

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
	'Active_In_Report',
	'True',
	1,
	'No. of clients in a group >1',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)

GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S161 Trade near Corporate Announcement by group of clients EQ'

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
	'Active_In_Report',
	'True',
	1,
	'No. of clients in a group >1',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)

GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S162 High Turnover by Group of Clients in 1 Day in Specific Scrip EQ'

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
	'Active_In_Report',
	'True',
	1,
	'No. of clients in a group >1',
	3,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S163 High Profit or Loss by Group of Clients in 1 Day EQ'

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
	'Active_In_Report',
	'True',
	1,
	'No. of clients in a group >1',
	7,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)

GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S164 High Profit or Loss by Group of Clients in 1 Day FNO'

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
	'Active_In_Report',
	'True',
	1,
	'No. of clients in a group >1',
	7,
	GETDATE(),
	'System',
	GETDATE(),
	'System'
)
GO
------RC-WEB-65063 END
------RC-WEB-65063 START
GO
DECLARE @AmlReportId INT
SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S151 High Turnover by Group of Clients in 1 Day EQ'
UPDATE dbo.RefAmlReport
SET [Description]='This Scenario will detect the High Turnover done by a group of clients in 1 day. <br>  
It will generate alert if, <br>   
1. The percentage of scrip turnover buy or sell to the exchange turnover is greater than or equal to the set Scrip percent threshold by group of clients. <br>    
2. Client Group turnover in stock buy or sell is greater than or equal to set turnover threshold by group of clients <br>   
Segments covered: BSE_CASH, NSE_CASH; Period: 1 day <br>   <b>Thresholds:</b> <br>       
1. Scrip %: It is Turnover % contribution done in a stock by the group of clients compared to the Exchange Turnover. It will generate alerts if the Scrip % is greater than or equal to the set threshold. <br>   
2. Group Turnover: It is Turnover contribution done in a stock by the group of clients. It will generate alerts if the Group Turnover is greater than or equal to the set threshold. <br>   
3. No. of Clients: The top ''X'' number of clients that are to be considered in the group of clients for alert generation are to be mentioned in this threshold. System will generate alerts for ''X'' or less than ''X'' number of clients as per the set threshold. <br>   
4. Scrip Group: Threshold can be set Scrip group wise. ( e.g. A, B, T ) <br>       
5. Group Share %: It is the individual % contribution by each client from the group of clients. System will include the clients which have greater than or equal to ''X'' Group share % <br>   
6. A seperate checkbox threshold of <b>''No. of clients in a group >1''</b> is introduced.<br>
7. If it is enabled (tick), then system will generate alerts for more than 1 client in group and not only for single client. <br>
8. If it is disabled ( untick), then system will generate alerts even for 1 client if it breaches the set thresholds. <br>
<b>Note:</b> Seperate alerts will be generated for Buy and Sell Trades for same client if conditions get breach.'
WHERE RefAmlReportId=@AmlReportId
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S152 High Turnover by Group of Clients in 1 Day FNO'
UPDATE dbo.RefAmlReport
SET [Description]='This Scenario will detect the High Turnover done by a group of clients in 1 day. <br>   
It will generate alert if, <br>   
1. The percentage of scrip turnover buy or sell to the exchange turnover is greater than or equal to the set Scrip percent threshold by group of clients.<br>    
2. Client Group turnover in stock buy or sell is greater than or equal to set turnover threshold by group of clients<br>   
Segments covered: NSE_FNO, NSE_CDX; Period: 1 day<br>   <b>Thresholds:</b> <br>   
1. Scrip %: It is Turnover % contribution done in a stock by the group of clients compared to the Exchange Turnover. It will generate alerts if the Scrip % is greater than or equal to the set threshold. <br>   
2. Group Turnover: It is Turnover contribution done in a stock by the group of clients. It will generate alerts if the Group Turnover is greater than or equal to the set threshold. <br>   
3. No. of Clients: The top ''X'' number of clients that are to be considered in the group of clients for alert generation are to be mentioned in this threshold. System will generate alerts for ''X'' or less than ''X'' number of clients as per the set threshold. <br>   
4. Instrument Type: Threshold can be set Instrument Type wise. ( e.g. FUTSTK,OPTSTK )<br>   
5. Group Share %: It is the individual % contribution by each client from the group of clients. System will include the clients which have greater than or equal to ''X'' Group share % <br>
6. A seperate checkbox threshold of <b>''No. of clients in a group >1''</b> is introduced.<br>
7. If it is enabled (tick), then system will generate alerts for more than 1 client in group and not only for single client. <br>
8. If it is disabled ( untick), then system will generate alerts even for 1 client if it breaches the set thresholds. <br>
<b>Note:</b> Seperate alerts will be generated for Buy and Sell Trades for same client if conditions get breach.'

WHERE RefAmlReportId=@AmlReportId
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S154 High Turnover by Group of New Clients in 1 Day EQ'
UPDATE dbo.RefAmlReport
SET [Description]='This Scenario will detect the High Turnover done by a group of new clients in 1 day. <br>
		It will generate alert if, <br>
		1.The percentage of scrip turnover buy or sell to the exchange turnover is greater than or equal to the set Scrip percent threshold by group of new clients<br>
		2.Client Group turnover in stock buy or sell is greater than or equal to set turnover threshold by group of new clients<br>
		Segments covered : BSE_CASH, NSE_CASH ; Period: 1 day<br>
		<b>Thresholds:</b><br> 
		1. Scrip % : It is Turnover % contribution done in a stock by the group of clients compared to the Exchange Turnover. It will generate alerts if the Scrip % is greater than or equal to the set threshold. <br>
		2. Group Turnover : It is Turnover contribution done in a stock by the group of clients.  It will generate alerts if the Group Turnover is greater than or equal to the set threshold. <br>
		3. No. of Clients : The top ''X'' number of clients that are to be considered in the group of clients for alert generation are to be mentioned in this threshold. System will generate alerts for ''X'' or less than ''X'' number of clients as per the set threshold.<br> 
		4. Scrip Group: Threshold can be set Scrip group wise. ( e.g. A, B, T )<br>
		5. Group Share % : It is the individual % contribution by each client from the group of clients. System will exclude the clients which have less than ''X'' Group share % <br>
		6. New/Not traded Days > : This threshold will consider the clients with 2 conditions: <br>
		7. A seperate checkbox threshold of <b>''No. of clients in a group >1''</b> is introduced.<br>
		8. If it is enabled (tick), then system will generate alerts for more than 1 client in group and not only for single client. <br>
		9. If it is disabled ( untick), then system will generate alerts even for 1 client if it breaches the set thresholds. <br>
		a. Newly opened accounts for the past ''X'' days from the Run date. <br>
		b. Clients who have not traded for the past ''X'' days from the Run date.'
WHERE RefAmlReportId=@AmlReportId
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S156 High Turnover by Group of New Clients in 1 Day FNO'
UPDATE dbo.RefAmlReport
SET [Description]='This Scenario will detect the High Turnover done by a group of new clients in 1 day. <br>
		It will generate alert if, <br>
		1.The percentage of scrip turnover buy or sell to the exchange turnover is greater than or equal to the set Scrip percent threshold by group of new clients<br>
		2.Client Group turnover in stock buy or sell is greater than or equal to set turnover threshold by group of new clients<br>
		Segments covered : NSE_FNO, NSE_CDX ; Period: 1 day<br>
		<b>Thresholds:</b><br> 
		1. Scrip % : It is Turnover % contribution done in a stock by the group of clients compared to the Exchange Turnover. It will generate alerts if the Scrip % is greater than or equal to the set threshold. <br>
		2. Group Turnover : It is Turnover contribution done in a stock by the group of clients.  It will generate alerts if the Group Turnover is greater than or equal to the set threshold. <br>
		3. No. of Clients : The top ''X'' number of clients that are to be considered in the group of clients for alert generation are to be mentioned in this threshold. System will generate alerts for ''X'' or less than ''X'' number of clients as per the set threshold. <br>
		4. Instrument Type: Threshold can be set Instrument Type wise. ( e.g. FUTSTK,OPTSTK )<br>
		5. Group Share % : It is the individual % contribution by each client from the group of clients. System will exclude the clients which have less than ''X'' Group share % <br>
		6. New/Not traded Days > : This threshold will consider the clients with 2 conditions: <br>
		7. A seperate checkbox threshold of <b>''No. of clients in a group >1''</b> is introduced.<br>
		8. If it is enabled (tick), then system will generate alerts for more than 1 client in group and not only for single client. <br>
		9. If it is disabled ( untick), then system will generate alerts even for 1 client if it breaches the set thresholds. <br>
		a. Newly opened accounts for the past ''X'' days from the Run date. <br>
		b. Clients who have not traded for the past ''X'' days from the Run date.'
WHERE RefAmlReportId=@AmlReportId
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S157 Small Orders in Single Stock by Group of Clients EQ'
UPDATE dbo.RefAmlReport
SET [Description]='This scenario will help us to identify the group of clients indulging in frequent small quantity orders.<br>
		Segments covered: BSE_CASH, NSE_CASH ; Period: 1 day<br>
		<b>Thresholds:</b> <br>
		1. Client Small Order Qty: These are the Small Quantity trades done by a particular client. System will generate alerts for ''X'' or less than ''X'' number of small quantity trades as per the set threshold. (<=)<br>
		2. Group Small Order Total Qty: These are the Small Quantity trades done by the Group of clients. System will generate alerts for ''X'' or less than ''X'' number of small quantity trades as per the set threshold. (<=)<br>
		3. Percentage of Total Group Orders Qty: It is the percentage ratio of the Small Quantity Trades done by group of clients to the Total Executed Trades done by the group of clients. It will work on Greater than or equal to basis (=>)<br>
		4. Minimum Group Orders: The minimum number of trades that will be considered for a Group is the Minimum Group Orders. It will consider the ''X'' number of trades greater than or equal to the set threshold. (=>)<br>
		5. No. of clients in a Group: The ''X'' number of clients that are to be considered in the group of clients for alert generation are to be mentioned in this threshold. System will generate alerts for ''X'' or less than ''X'' number of clients as per the set threshold. (<=)<br>
		6. A seperate checkbox threshold of <b>''No. of clients in a group >1''</b> is introduced.<br>
		7. If it is enabled (tick), then system will generate alerts for more than 1 client in group and not only for single client. <br>
		8. If it is disabled ( untick), then system will generate alerts even for 1 client if it breaches the set thresholds. <br>'

WHERE RefAmlReportId=@AmlReportId
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S159 Small Orders in Single Stock by Group of Clients FNO'
UPDATE dbo.RefAmlReport
SET [Description]='This scenario will help us to identify the group of clients indulging in frequent small quantity orders.<br>    
Segments covered: NSE_FNO, NSE_CDX; Period: 1 day<br>    <b>Thresholds:</b><br>    
1. Client Small Order Turnover: It is the Turnover contributed in that scrip by the small quantity trades done by a particular client. System will generate alerts for ''X'' or less than ''X'' number of Client TO of small quantity trades as per the set threshold. (<=)<br>    
2. Group Small Order Total TO: These are the Total Turnover of the Small Quantity trades done by the Group of clients. System will generate alerts for ''X'' or less than ''X'' number of Total TO of small quantity trades as per the set threshold. (<=)<br>    
3. Price Away from Previous Day Close %: It is the percentage of the Average Rate of the Small Quantity Trades done by the clients to the Previous Closing price of the Contract. It will work on Greater than or equal to basis (=>)<br>    
4. Instrument Type: Threshold can be set Instrument Type wise. ( e.g. FUTSTK,OPTSTK )<br>    
5. No. of clients in a Group: The ''X'' number of clients that are to be considered in the group of clients for alert generation are to be mentioned in this threshold. 
System will generate alerts for ''X'' or less than ''X'' number of clients as per the set threshold. (<=)<br>
6. A seperate checkbox threshold of <b>''No. of clients in a group >1''</b> is introduced.<br>
7. If it is enabled (tick), then system will generate alerts for more than 1 client in group and not only for single client. <br>
8. If it is disabled ( untick), then system will generate alerts even for 1 client if it breaches the set thresholds. <br>'

WHERE RefAmlReportId=@AmlReportId
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S161 Trade near Corporate Announcement by group of clients EQ'
UPDATE dbo.RefAmlReport
SET [Description]='This scenario will help us to identify the group of clients who have undertaken any suspicious trading activity prior to Corporate announcement by said listed company.<br>
Segments covered: BSE_CASH, NSE_CASH ; Period: 1 day<br>    <b>Thresholds:</b><br>     
1. Group Turnover: It is the Turnover done by the group of clients in that particular scrip on the day of Corporate announcement. System will generate alerts if the group turnover in that scrip is greater than or equal to the set threshold. ( => )<br>    
2. Group contribution % compare to Exchange TO : It is Turnover % contribution done in a stock by the group of clients compared to the Exchange Turnover. It will generate alerts if the Group % is greater than or equal to the set threshold. ( => )<br>    
3. No. of Clients : The top ''X'' number of clients that are to be considered in the group of clients for alert generation are to be mentioned in this threshold. System will generate alerts for ''X'' or less than ''X'' number of clients as per the set threshold.<br>
4. A seperate checkbox threshold of <b>''No. of clients in a group >1''</b> is introduced.<br>
5. If it is enabled (tick), then system will generate alerts for more than 1 client in group and not only for single client. <br>
6. If it is disabled ( untick), then system will generate alerts even for 1 client if it breaches the set thresholds. <br>'

WHERE RefAmlReportId=@AmlReportId
GO
DECLARE @AmlReportId INT

SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S162 High Turnover by Group of Clients in 1 Day in Specific Scrip EQ'
UPDATE dbo.RefAmlReport
SET [Description]='This Scenario will detect the High Turnover done by a group of clients in a specific scrip in 1 day. <br>   It will generate alert if, <br>   
1. The percentage of scrip turnover buy or sell to the exchange turnover is greater than or equal to the set Scrip percent threshold by group of clients  in a specific scrip.<br>   
2. Client Group turnover in stock buy or sell is greater than or equal to set turnover threshold by group of clients<br>   Segments covered: BSE_CASH, NSE_CASH; Period: 1 day <br>   <b>Thresholds: </b> <br>   1. Scrip % : It is Turnover % contribution done in a stock by the group of clients compared to the Exchange Turnover. It will generate alerts if the Scrip % is greater than or equal to the set threshold. <br>   2. Group Turnover: It is Turnover contribution done in a stock by the group of clients. It will generate alerts if the Group Turnover is greater than or equal to the set threshold. <br>   
3. No. of Clients: The top ''X'' number of clients that are to be considered in the group of clients for alert generation are to be mentioned in this threshold. System will generate alerts for ''X'' or less than ''X'' number of clients as per the set threshold. <br>   
4. Internal Scrip Group: Threshold can be set for scrips which are configured in the ''Instrument Group Type Master'' as Internal Scrip Groups. (Internal 1,2,3.. and SMS, Current or Historical Watchlist)<br>   
5. Group Share %: It is the individual % contribution by each client from the group of clients. System will include the clients which have greater than or equal to ''X'' Group share % <br> 
6. A seperate checkbox threshold of <b>''No. of clients in a group >1''</b> is introduced.<br>
7. If it is enabled (tick), then system will generate alerts for more than 1 client in group and not only for single client. <br>
8. If it is disabled ( untick), then system will generate alerts even for 1 client if it breaches the set thresholds. <br>
<b>Note:</b> Seperate alerts will be generated for Buy and Sell Trades for same client if conditions get breach.'
WHERE RefAmlReportId=@AmlReportId
GO
DECLARE @AmlReportId INT
SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S163 High Profit or Loss by Group of Clients in 1 Day EQ'
UPDATE dbo.RefAmlReport
SET [Description]='This Scenario will detect the Intraday Profit/Loss done by a group of clients in 1 day. <br>
		It will generate alert if, <br>
		1.The amount of profit/loss is greater than or equal to the set threshold by group of clients <br>
		2.Intraday turnover is greater than or equal to set turnover threshold by group of clients <br>
		Segments covered: BSE_CASH, NSE_CASH; Period: 1 day <br>
		<b>Thresholds: </b> <br>
		1. Group Profit/Loss: It is the Profit/Loss procured by the group of clients on the basis of the alert generated. System will generate alerts if the Profit / Loss is greater than or equal to the set threshold.(=>) <br>
		2. Group Turnover: It is Turnover contribution done by the group of clients.  It will generate alerts if the Group Turnover is greater than or equal to the set threshold.(=>) <br>
		3. No. of Clients: The top ''X'' number of clients that are to be considered in the group of clients for alert generation are to be mentioned in this threshold. System will generate alerts for ''X'' or less than ''X'' number of clients as per the set threshold.(<=) <br>
		4. Client Share in P/L %: It is the individual % contribution by each client from the group of clients. System will exclude the clients which have less than ''X'' Group share %.(<=) <br>
		5. A seperate checkbox threshold of <b>''No. of clients in a group >1''</b> is introduced.<br>
		6. If it is enabled (tick), then system will generate alerts for more than 1 client in group and not only for single client. <br>
		7. If it is disabled ( untick), then system will generate alerts even for 1 client if it breaches the set thresholds. <br>
		<b>Note:</b> This Scenario will run only for Intraday Trades.'
WHERE RefAmlReportId=@AmlReportId

GO
DECLARE @AmlReportId INT
SELECT @AmlReportId = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S164 High Profit or Loss by Group of Clients in 1 Day FNO'
UPDATE dbo.RefAmlReport
SET [Description]='This Scenario will detect the Intraday Profit/Loss done by a group of clients in 1 day. <br>
		It will generate alert if, <br>
		1.The amount of profit/loss is greater than or equal to the set threshold by group of clients <br>
		2.Intraday turnover is greater than or equal to set turnover threshold by group of clients <br>
		Segments covered: NSE_FNO, NSE_CDX; Period: 1 day <br>
		<b>Thresholds: </b> <br>
		1. Group Profit/Loss: It is the Profit/Loss procured by the group of clients on the basis of the alert generated. System will generate alerts if the Profit / Loss is greater than or equal to the set threshold.(=>) <br>
		2. Group Turnover: It is Turnover contribution done by the group of clients.  It will generate alerts if the Group Turnover is greater than or equal to the set threshold.(=>) <br>
		3. No. of Clients: The top ''X'' number of clients that are to be considered in the group of clients for alert generation are to be mentioned in this threshold. System will generate alerts for ''X'' or less than ''X'' number of clients as per the set threshold.(<=) <br>
		4. Client Share in P/L %: It is the individual % contribution by each client from the group of clients. System will exclude the clients which have less than ''X'' Group share %.(<=) <br>
		5. A seperate checkbox threshold of <b>''No. of clients in a group >1''</b> is introduced.<br>
		6. If it is enabled (tick), then system will generate alerts for more than 1 client in group and not only for single client. <br>
		7. If it is disabled ( untick), then system will generate alerts even for 1 client if it breaches the set thresholds. <br>
		<b>Note:</b> This Scenario will run only for Intraday Trades.'
		
WHERE RefAmlReportId=@AmlReportId
GO
------RC-WEB-65063 END
------------procedure
---S151
------RC-WEB-65063 START
GO
ALTER PROCEDURE dbo.AML_GetHighTurnoverTradesByGroupofClientsIn1Day  
(    
 @RunDate DATETIME,    
 @ReportId INT    
)    
AS    
BEGIN    
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @BSECashId INT, @NSECashId INT,  
   @IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT,  @IsGroupGreaterThanOneClient INT
    
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)    
 SET @ReportIdInternal = @ReportId    
 SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'    
 SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'  

 SELECT   
  @IsGroupGreaterThanOneClient = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Active_In_Report' 

 SELECT   
  @IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Exclude_Pro'  
   
 SELECT   
  @IsExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Exclude_Institution'  
   
 SELECT   
  @ProStatusId = RefClientStatusId   
 FROM dbo.RefClientStatus   
 WHERE [Name] = 'Pro'  
   
   
 SELECT   
  @InstituteStatusId = RefClientStatusId  
 FROM dbo.RefClientStatus WHERE [Name] = 'Institution'  
     
 SELECT    
  RefClientId    
 INTO #clientsToExclude    
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
 WHERE RefAmlReportId = @ReportIdInternal    
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)    
    
 SELECT    
  rul.Threshold,    
  rul.Threshold2,    
  rul.Threshold3,    
  rul.Threshold4,    
  scrip.[Name] AS ScripGroup,    
  scrip.RefScripGroupId    
 INTO #scenarioRules    
 FROM dbo.RefAmlScenarioRule rul    
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId    
 INNER JOIN dbo.RefScripGroup scrip ON scrip.RefScripGroupId = link.RefScripGroupId    
 WHERE RefAmlReportId = @ReportIdInternal    
    
 SELECT    
  trade.CoreTradeId,    
  inst.Isin,    
  inst.GroupName,    
  inst.RefSegmentId    
 INTO #tradeIds    
 FROM dbo.CoreTrade trade    
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
 INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId  
 WHERE trade.TradeDate = @RunDateInternal AND trade.RefSegmentId IN (@BSECashId, @NSECashId)  
 AND (@IsExcludePro = 0 OR cl.RefClientStatusId <> @ProStatusId)  
 AND (@IsExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstituteStatusId)  
 AND NOT EXISTS(SELECT 1 FROM #clientsToExclude clEx    
 WHERE clEx.RefClientId = trade.RefClientId)  
    
 DROP TABLE #clientsToExclude    
    
  SELECT DISTINCT    
  ids.Isin,    
  CASE WHEN inst.GroupName IS NOT NULL    
  THEN inst.GroupName    
  ELSE 'B' END AS GroupName,  
  inst.Code  
 INTO #allNseGroupData    
 FROM #tradeIds ids    
 LEFT JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @BSECashId    
  AND ids.Isin = inst.Isin  AND inst.[Status]='A'   
 WHERE ids.RefSegmentId = @NSECashId    
  
  
 SELECT Isin, COUNT(1) AS rcount  
 INTO #multipleGroups  
 FROM #allNseGroupData  
 GROUP BY Isin  
 HAVING COUNT(1)>1  
  
 SELECT t.Isin, t.GroupName   
 INTO #nseGroupData  
 FROM   
 (  
  SELECT grp.Isin, grp.GroupName   
  FROM #allNseGroupData grp  
  WHERE NOT EXISTS  
  (  
   SELECT 1 FROM #multipleGroups mg   
   WHERE mg.Isin=grp.Isin  
  )  
  
  UNION  
  
  SELECT  mg.Isin, grp.GroupName  
  FROM #multipleGroups mg  
  INNER JOIN #allNseGroupData grp ON grp.Isin=mg.Isin AND grp.Code like '5%'  
 )t  
  
 DROP TABLE #multipleGroups  
 DROP TABLE #allNseGroupData  
  
    
 SELECT     
  trade.RefClientId,    
  trade.RefInstrumentId,    
  CASE WHEN trade.BuySell = 'Buy'    
   THEN 1    
   ELSE 0 END BuySell,    
  trade.Rate,    
  trade.Quantity,    
  (trade.Rate * trade.Quantity) AS tradeTO,    
  rules.RefScripGroupId,    
  trade.RefSegmentId    
 INTO #tradeData    
 FROM #tradeIds ids    
 INNER JOIN dbo.CoreTrade trade ON ids.CoreTradeId = trade.CoreTradeId    
 LEFT JOIN #nseGroupData nse ON  ids.Isin = nse.Isin AND ids.RefSegmentId=@NSECashId  
 INNER JOIN #scenarioRules rules ON (ids.RefSegmentId = @BSECashId     
  AND rules.ScripGroup = ids.GroupName) OR (ids.RefSegmentId = @NSECashId    
  AND rules.ScripGroup = nse.GroupName)     
    
 DROP TABLE #tradeIds    
 DROP TABLE #nseGroupData    
    
 SELECT    
  RefClientId,    
  RefScripGroupId,    
  RefInstrumentId,    
  RefSegmentId,    
  BuySell,    
  SUM(tradeTO) AS ClientTO,    
  SUM(Quantity) AS ClientQT    
 INTO #clientTOs    
 FROM #tradeData    
 GROUP BY RefClientId, RefScripGroupId, RefInstrumentId, RefSegmentId, BuySell    
    
 DROP TABLE #tradeData    
    
 SELECT    
  t.RefInstrumentId,    
  t.RefSegmentId,    
  t.BuySell,    
  t.RefScripGroupId,    
  t.RefClientId,    
  t.ClientTO,    
  t.ClientQT,
  COUNT(t.RefClientId) OVER (PARTITION BY t.RefInstrumentId, t.RefSegmentId, t.BuySell) CRN    
 INTO #topClients    
 FROM (SELECT     
   RefInstrumentId,    
   RefSegmentId,    
   BuySell,    
   RefScripGroupId,    
   RefClientId,    
   ClientTO,    
   ClientQT,    
   DENSE_RANK() OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell ORDER BY ClientTO DESC) AS RN
  FROM #clientTOs    
 ) t    
 INNER JOIN #scenarioRules rules ON t.RefScripGroupId = rules.RefScripGroupId    
 WHERE t.RN <= rules.Threshold3     
    
 DROP TABLE #clientTOs    
    
 SELECT    
  RefScripGroupId,    
  RefInstrumentId,     
  RefSegmentId,     
  BuySell,    
  SUM(ClientTO) AS GroupTO    
 INTO #groupedSum    
 FROM #topClients  
 WHERE @IsGroupGreaterThanOneClient<CRN
 GROUP BY RefScripGroupId, RefInstrumentId, RefSegmentId, BuySell    
    
 SELECT    
  grp.RefScripGroupId,    
  grp.RefInstrumentId,    
  grp.BuySell,    
  grp.RefSegmentId,    
  grp.GroupTO,    
  bhav.NetTurnOver AS ExchangeTO,    
  (grp.GroupTO * 100 / bhav.NetTurnOver) AS GroupContributedPerc    
 INTO #selectedScrips    
 FROM #groupedSum grp    
 INNER JOIN dbo.CoreBhavCopy bhav ON grp.RefInstrumentId = bhav.RefInstrumentId    
 INNER JOIN #scenarioRules rules ON rules.RefScripGroupId = grp.RefScripGroupId    
 WHERE bhav.[Date] = @RunDateInternal AND grp.GroupTO >= rules.Threshold2    
  AND (grp.GroupTO * 100 / bhav.NetTurnOver) >= rules.Threshold    
    
 DROP TABLE #groupedSum    
    
 SELECT    
  cl.RefClientId,    
  client.ClientId,    
  client.[Name] AS ClientName,    
  seg.Segment,    
  @RunDateInternal AS TradeDate,    
  rules.ScripGroup AS GroupName,    
  instru.Code AS ScripCode,    
  instru.[Name] AS ScripName,    
  scrips.GroupTO,    
  scrips.GroupContributedPerc,    
  scrips.ExchangeTO,    
  cl.ClientQT AS ClientTradedQty,    
  (cl.ClientTO / cl.ClientQT) AS AvgRate,    
  cl.ClientTO,    
  (cl.ClientTO * 100 / scrips.ExchangeTO) AS ClientPerc,    
  (cl.ClientTO * 100 / scrips.GroupTO) AS GroupSharePerc,    
  rules.RefScripGroupId,    
  scrips.RefInstrumentId,    
  scrips.RefSegmentId,    
  scrips.BuySell    
 INTO #finalData    
 FROM #selectedScrips scrips    
 INNER JOIN #topClients cl ON scrips.RefInstrumentId = cl.RefInstrumentId     
  AND scrips.RefSegmentId = cl.RefSegmentId AND scrips.BuySell = cl.BuySell    
 INNER JOIN dbo.RefClient client ON cl.RefClientId = client.RefClientId    
 INNER JOIN dbo.RefSegmentEnum seg ON scrips.RefSegmentId = seg.RefSegmentEnumId    
 INNER JOIN #scenarioRules rules ON scrips.RefScripGroupId = rules.RefScripGroupId    
 INNER JOIN dbo.RefInstrument instru ON scrips.RefInstrumentId = instru.RefInstrumentId    
    
 DROP TABLE #topClients    
 DROP TABLE #selectedScrips    
    
 SELECT    
  final.RefClientId,    
  final.ClientId,    
  final.ClientName,    
  final.RefSegmentId,    
  final.Segment,    
  final.TradeDate,    
  final.GroupName,    
  CASE WHEN final.BuySell = 1    
   THEN 'Buy'    
   ELSE 'Sell' END AS BuySell,    
  final.ScripCode,    
  final.ScripName,    
  CONVERT(DECIMAL(28, 2), final.GroupTO) AS GroupTO,    
  CONVERT(DECIMAL(28, 2), final.GroupContributedPerc) AS GroupContributedPerc,    
  CONVERT(DECIMAL(28, 2), final.ExchangeTO) AS ExchangeTO,    
  CONVERT(DECIMAL(28, 2), final.ClientTradedQty) AS ClientTradedQty,    
  CONVERT(DECIMAL(28, 2), final.AvgRate) AS AvgRate,    
  CONVERT(DECIMAL(28, 2), final.ClientTO) AS ClientTO,    
  CONVERT(DECIMAL(28, 2), final.ClientPerc) AS ClientPerc,    
  CONVERT(DECIMAL(28, 2), final.GroupSharePerc) AS GroupSharePerc,    
  STUFF((SELECT ' ; ' + t.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) + '%'    
     FROM #finalData t    
     WHERE t.RefInstrumentId = final.RefInstrumentId AND t.RefSegmentId = final.RefSegmentId    
      AND t.BuySell = final.BuySell AND t.RefClientId <> final.RefClientId    
     ORDER BY t.ClientPerc DESC    
   FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc,    
  final.RefInstrumentId    
 FROM #finalData final    
 INNER JOIN #scenarioRules rules ON final.RefScripGroupId = rules.RefScripGroupId    
 WHERE final.GroupSharePerc >= rules.Threshold4    
 ORDER BY final.RefInstrumentId, final.RefSegmentId, final.BuySell, final.ClientPerc DESC    
  
END  
GO
------RC-WEB-65063 END
---S152
------RC-WEB-65063 START
GO
ALTER PROCEDURE dbo.AML_GetHighTurnoverbyGroupofClientsin1DayFNO
(
	@RunDate DATETIME,
	@ReportId INT
)
AS
BEGIN
	DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @OPTSTKId INT, @OPTIDXId INT, @OPTCURId INT,
			@OPTIRCId INT, @FUTIDXId INT, @FUTSTKId INT, @FUTIRDId INT, @FUTIRTId INT, @FUTCURId INT,
			@FUTIRCId INT, @FUTIVXId INT, @FUTIRFId INT, @IsGroupGreaterThanOneClient INT,
			@IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT

	SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)
	SET @ReportIdInternal = @ReportId
	SELECT @OPTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'
	SELECT @OPTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'
	SELECT @OPTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'
	SELECT @OPTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIRC'
	SELECT @FUTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIDX'
	SELECT @FUTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTSTK'
	SELECT @FUTIRDId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRD'
	SELECT @FUTIRTId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRT'
	SELECT @FUTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR'
	SELECT @FUTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRC'
	SELECT @FUTIVXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIVX'
	SELECT @FUTIRFId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRF'
	
	SELECT   
	@IsGroupGreaterThanOneClient = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
	FROM dbo.SysAmlReportSetting   
	WHERE   
	RefAmlReportId = @ReportIdInternal   
	AND [Name] = 'Active_In_Report' 

	SELECT 
		@IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
	FROM dbo.SysAmlReportSetting 
	WHERE 
		RefAmlReportId = @ReportIdInternal 
		AND [Name] = 'Exclude_Pro'
	
	SELECT 
		@IsExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
	FROM dbo.SysAmlReportSetting 
	WHERE 
		RefAmlReportId = @ReportIdInternal 
		AND [Name] = 'Exclude_Institution'
	
	SELECT 
		@ProStatusId = RefClientStatusId 
	FROM dbo.RefClientStatus 
	WHERE [Name] = 'Pro'
	
	
	SELECT 
		@InstituteStatusId = RefClientStatusId
	FROM dbo.RefClientStatus WHERE [Name] = 'Institution'

	SELECT 
		RefSegmentEnumId,
		Segment
	INTO #segments
	FROM dbo.RefSegmentEnum WHERE Code IN ('NSE_FNO', 'NSE_CDX')

	SELECT
		RefClientId
	INTO #clientsToExclude
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion
	WHERE RefAmlReportId = @ReportIdInternal
		AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)

	SELECT
		rul.Threshold,
		rul.Threshold2,
		rul.Threshold3,
		rul.Threshold4,
		instType.InstrumentType,
		instType.RefInstrumentTypeId
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule rul
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId
	INNER JOIN dbo.RefInstrumentType instType ON instType.RefInstrumentTypeId = link.RefInstrumentTypeId
	WHERE RefAmlReportId = @ReportIdInternal 
		AND instType.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTCURId, @OPTIRCId, @FUTIDXId, @FUTSTKId,
			@FUTIRDId, @FUTIRTId, @FUTCURId, @FUTIRCId, @FUTIVXId, @FUTIRFId)
	
	SELECT 									 
		trade.RefClientId,					 
		trade.RefInstrumentId,				 
		CASE WHEN trade.BuySell = 'Buy'		 
			THEN 1							 
			ELSE 0 END BuySell,
		CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)
		THEN trade.Quantity * ISNULL(inst.ContractSize, 1)
		ELSE trade.Quantity END AS Quantity,
		CASE WHEN inst.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId)
			THEN (ISNULL(inst.StrikePrice, 0) + trade.Rate) * trade.Quantity
			WHEN inst.RefInstrumentTypeId = @OPTCURId
			THEN (ISNULL(inst.StrikePrice, 0) + trade.Rate) * trade.Quantity * ISNULL(inst.ContractSize, 1)
			WHEN inst.RefInstrumentTypeId = @FUTCURId
			THEN trade.Rate * trade.Quantity * ISNULL(inst.ContractSize, 1)
			ELSE trade.Rate * trade.Quantity END AS tradeTO,
		rules.RefInstrumentTypeId,
		trade.RefSegmentId
	INTO #tradeData
	FROM dbo.CoreTrade trade
	INNER JOIN #segments seg ON trade.RefSegmentId = RefSegmentEnumId
	INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId
	INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = inst.RefInstrumentTypeId
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId
	WHERE trade.TradeDate = @RunDateInternal
		AND (@IsExcludePro = 0 OR cl.RefClientStatusId <> @ProStatusId)
		AND (@IsExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstituteStatusId)
		AND NOT EXISTS(SELECT 1 FROM #clientsToExclude clEx
			WHERE clEx.RefClientId = trade.RefClientId)

	SELECT
		RefClientId,
		RefInstrumentTypeId,
		RefInstrumentId,
		RefSegmentId,
		BuySell,
		SUM(tradeTO) AS ClientTO,
		SUM(Quantity) AS ClientQT
	INTO #clientTOs
	FROM #tradeData
	GROUP BY RefClientId, RefInstrumentTypeId, RefInstrumentId, RefSegmentId, BuySell

	DROP TABLE #tradeData

	SELECT
		t.RefInstrumentId,
		t.RefSegmentId,
		t.BuySell,
		t.RefInstrumentTypeId,
		t.RefClientId,
		t.ClientTO,
		t.ClientQT,
		COUNT(t.RefClientId) OVER (PARTITION BY t.RefInstrumentId, t.RefSegmentId, t.BuySell) CRN
	INTO #topClients
	FROM (SELECT 
			RefInstrumentId,
			RefSegmentId,
			BuySell,
			RefInstrumentTypeId,
			RefClientId,
			ClientTO,
			ClientQT,
			DENSE_RANK() OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell ORDER BY ClientTO DESC) AS RN

		FROM #clientTOs
	) t
	INNER JOIN #scenarioRules rules ON t.RefInstrumentTypeId = rules.RefInstrumentTypeId
	WHERE t.RN <= rules.Threshold3  

	DROP TABLE #clientTOs

	SELECT
		RefInstrumentTypeId,
		RefInstrumentId, 
		RefSegmentId, 
		BuySell,
		SUM(ClientTO) AS GroupTO
	INTO #groupedSum
	FROM #topClients
	WHERE @IsGroupGreaterThanOneClient< CRN
	GROUP BY RefInstrumentTypeId, RefInstrumentId, RefSegmentId, BuySell

	SELECT
		grp.RefInstrumentTypeId,
		grp.RefInstrumentId,
		grp.BuySell,
		grp.RefSegmentId,
		grp.GroupTO,
		bhav.NetTurnOver AS ExchangeTO,
		(grp.GroupTO * 100 / bhav.NetTurnOver) AS GroupContributedPerc
	INTO #selectedScrips
	FROM #groupedSum grp
	INNER JOIN dbo.CoreBhavCopy bhav ON grp.RefInstrumentId = bhav.RefInstrumentId
	INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = grp.RefInstrumentTypeId
	WHERE bhav.[Date] = @RunDateInternal AND grp.GroupTO >= rules.Threshold2
		AND (grp.GroupTO * 100 / bhav.NetTurnOver) >= rules.Threshold

	DROP TABLE #groupedSum

	SELECT
		cl.RefClientId,
		client.ClientId,
		client.[Name] AS ClientName,
		seg.Segment,
		rules.InstrumentType,
		inst.[Name] + '-' + ISNULL(rules.InstrumentType, '') + 
			'-' + 							 
			CASE WHEN inst.ExpiryDate IS NULL THEN ''
			ELSE CONVERT(varchar, inst.ExpiryDate, 106) END + '-' + 
			ISNULL(inst.PutCall, '') + '-' + ISNULL(CONVERT(VARCHAR(100), inst.StrikePrice), '') AS ScripTypeExpDtPutCallStrikePrice,
		scrips.GroupTO,
		scrips.GroupContributedPerc,
		scrips.ExchangeTO,
		cl.ClientQT AS ClientTradedQty,
		(cl.ClientTO / cl.ClientQT) AS AvgRate,
		cl.ClientTO,
		(cl.ClientTO * 100 / scrips.ExchangeTO) AS ClientPerc,
		(cl.ClientTO * 100 / scrips.GroupTO) AS GroupSharePerc,
		rules.RefInstrumentTypeId,
		scrips.RefInstrumentId,
		scrips.RefSegmentId,
		scrips.BuySell
	INTO #finalData
	FROM #selectedScrips scrips
	INNER JOIN #topClients cl ON scrips.RefInstrumentId = cl.RefInstrumentId 
		AND scrips.RefSegmentId = cl.RefSegmentId AND scrips.BuySell = cl.BuySell
	INNER JOIN dbo.RefClient client ON cl.RefClientId = client.RefClientId
	INNER JOIN #segments seg ON scrips.RefSegmentId = seg.RefSegmentEnumId
	INNER JOIN #scenarioRules rules ON scrips.RefInstrumentTypeId = rules.RefInstrumentTypeId
	INNER JOIN dbo.RefInstrument inst ON scrips.RefInstrumentId = inst.RefInstrumentId

	SELECT
		final.RefClientId,
		final.ClientId,
		final.ClientName,
		final.RefSegmentId AS SegmentId,
		final.Segment,
		@RunDateInternal AS TradeDate,
		final.InstrumentType,
		final.ScripTypeExpDtPutCallStrikePrice AS InstrumentInfo,
		CASE WHEN final.BuySell = 1
			THEN 'Buy'
			ELSE 'Sell' END AS BuySell,
		CONVERT(DECIMAL(28, 2), final.GroupTO) AS GroupTO,
		CONVERT(DECIMAL(28, 2), final.GroupContributedPerc) AS GroupContributedPerc,
		CONVERT(DECIMAL(28, 2), final.ExchangeTO) AS ExchangeTO,
		CONVERT(DECIMAL(28, 2), final.ClientTradedQty) AS ClientTradedQty,
		CONVERT(DECIMAL(28, 2), final.AvgRate) AS AvgRate,
		CONVERT(DECIMAL(28, 2), final.ClientTO) AS ClientTO,
		CONVERT(DECIMAL(28, 2), final.ClientPerc) AS ClientPerc,
		CONVERT(DECIMAL(28, 2), final.GroupSharePerc) AS GroupSharePerc,
		STUFF((SELECT ' ; ' + t.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) + '%'
					FROM #finalData t
					WHERE t.RefInstrumentId = final.RefInstrumentId AND t.RefSegmentId = final.RefSegmentId
						AND t.BuySell = final.BuySell AND t.RefClientId <> final.RefClientId
					ORDER BY t.ClientPerc DESC
			FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc,
		final.RefInstrumentId
	FROM #finalData final
	INNER JOIN #scenarioRules rules ON final.RefInstrumentTypeId = rules.RefInstrumentTypeId
	WHERE final.GroupSharePerc >= rules.Threshold4
	ORDER BY final.RefInstrumentId, final.RefSegmentId, final.BuySell, final.ClientPerc DESC

END
GO
------RC-WEB-65063 END

--S163andS164
------RC-WEB-65063 START
GO
 ALTER PROCEDURE dbo.AML_GetHighProfitLossbyGroupofClientsin1Day   
(  
 @RunDate DATETIME,  
 @ReportId INT  
)  
AS  
BEGIN  
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @BSECashId INT, @NSECashId INT, @OPTSTKId INT,   
  @OPTIDXId INT, @OPTCURId INT, @OPTIRCId INT, @FUTIDXId INT, @FUTSTKId INT, @FUTIRDId INT,   
  @FUTIRTId INT, @FUTCURId INT, @FUTIRCId INT, @FUTIVXId INT, @FUTIRFId INT, @NSEFNOId INT,   
  @NSECDXId INT, @GrpPLThresh DECIMAL(28, 2), @GrpTOThresh DECIMAL(28, 2), @NoOfClThresh INT,  
  @ClSharePercThresh DECIMAL(28, 2), @S163Id INT, @S164Id INT, @IsGroupGreaterThanOneClient INT,  
  @IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT  
  
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
 SET @ReportIdInternal = @ReportId  
 SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'  
 SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'  
 SELECT @NSEFNOId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_FNO'  
 SELECT @NSECDXId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CDX'  
 SELECT @OPTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'  
 SELECT @OPTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'  
 SELECT @OPTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'  
 SELECT @OPTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIRC'  
 SELECT @FUTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIDX'  
 SELECT @FUTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTSTK'  
 SELECT @FUTIRDId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRD'  
 SELECT @FUTIRTId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRT'  
 SELECT @FUTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR'  
 SELECT @FUTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRC'  
 SELECT @FUTIVXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIVX'  
 SELECT @FUTIRFId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRF'  
 SELECT @GrpPLThresh = CONVERT(DECIMAL(28, 2), [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Profit_Loss'  
 SELECT @GrpTOThresh = CONVERT(DECIMAL(28, 2), [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Threshold_Quantity'  
 SELECT @NoOfClThresh = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Quantity'  
 SELECT @ClSharePercThresh = CONVERT(DECIMAL(28, 2), [Value])  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Client_Turnover_Percentage'  
 SELECT @S163Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S163 High Profit or Loss by Group of Clients in 1 Day EQ'  
 SELECT @S164Id = RefAmlReportId FROM dbo.RefAmlReport WHERE [Name] = 'S164 High Profit or Loss by Group of Clients in 1 Day FNO'  
  
  SELECT   
	@IsGroupGreaterThanOneClient = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
	FROM dbo.SysAmlReportSetting   
	WHERE   
	RefAmlReportId = @ReportIdInternal   
	AND [Name] = 'Active_In_Report'

 SELECT   
  @IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Exclude_Pro'  
   
 SELECT   
  @IsExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Exclude_Institution'  
   
 SELECT   
  @ProStatusId = RefClientStatusId   
 FROM dbo.RefClientStatus   
 WHERE [Name] = 'Pro'  
   
   
 SELECT   
  @InstituteStatusId = RefClientStatusId  
 FROM dbo.RefClientStatus WHERE [Name] = 'Institution'  
  
 SELECT  
  RefClientId  
 INTO #clientsToExclude  
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion  
 WHERE RefAmlReportId = @ReportIdInternal  
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)  
  
 CREATE TABLE #scrnarioDataMapping(  
  RefSegmentId INT NOT NULL,  
  RefAmlReportId INT NOT NULL,  
 -- RefInstrumentTypeId INT NULL,  
  TradeDate DATETIME NOT NULL  
 )  
 --for S163 there is no instrumentType filter  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@BSECashId,@S163Id,@RunDateInternal)  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@NSECashId,@S163Id,@RunDateInternal)  
  
 --for S164 there is instrumentType filter  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@NSEFNOId,@S164Id,@RunDateInternal)  
 INSERT INTO #scrnarioDataMapping(RefSegmentId,RefAmlReportId,TradeDate) VALUES (@NSECDXId,@S163Id,@RunDateInternal)  
  
 CREATE TABLE #trades (RefClientId INT, Quantity INT, Turnover DECIMAL(28, 2), BuySell INT, RefSegmentId INT, RefInstrumentId INT)  
  
 INSERT INTO #trades (RefClientId, BuySell, RefSegmentId, RefInstrumentId,Turnover,Quantity)  
 SELECT    
  trade.RefClientId,  
  CASE WHEN trade.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell,  
  trade.RefSegmentId,  
  trade.RefInstrumentId,  
  CASE   
   WHEN (INST.RefInstrumentTypeId = @OPTCURId or INST.RefInstrumentTypeId = @FUTCURId  )  
    THEN trade.Quantity * ISNULL(inst.ContractSize, 1)  
   ELSE   
    trade.Quantity * trade.Rate  
  END AS Turnover,  
  CASE   
   WHEN (INST.RefInstrumentTypeId = @OPTCURId or INST.RefInstrumentTypeId = @FUTCURId  )  
    THEN trade.Quantity * ISNULL(inst.ContractSize, 1)  
   ELSE  
    trade.Quantity   
  END AS Quantity  
      
 FROM #scrnarioDataMapping mapping  
 INNER JOIN dbo.CoreTrade trade ON trade.TradeDate = mapping.TradeDate AND trade.RefSegmentId = mapping.RefSegmentId   
  AND mapping.RefAmlReportId = @ReportIdInternal --report filter   
 INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
 INNER JOIN dbo.RefInstrument inst ON inst.RefInstrumentId = trade.RefInstrumentId  
 --LEFT JOIN dbo.RefInstrumentType instType ON  instType.RefInstrumentTypeId = inst.RefInstrumentTypeId   
 --  AND (mapping.RefInstrumentTypeId IS NOT NULL AND instType.RefInstrumentTypeId = mapping.RefInstrumentTypeId)-- for instrument type case condition  
 LEFT JOIN #clientsToExclude cl ON trade.RefClientId = cl.RefClientId  
 WHERE cl.RefClientId IS NULL  
 AND (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)  
 AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)  
  
 --IF @ReportIdInternal = @S163Id  
 --BEGIN  
 -- INSERT INTO #trades (RefClientId, Quantity, Turnover, BuySell, RefSegmentId, RefInstrumentId)  
 -- SELECT  
 --  trade.RefClientId,  
 --  trade.Quantity,  
 --  (trade.Quantity * trade.Rate) AS Turnover,  
 --  CASE WHEN trade.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell,  
 --  trade.RefSegmentId,  
 --  trade.RefInstrumentId  
 -- FROM dbo.CoreTrade trade  
 -- INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
 -- LEFT JOIN #clientsToExclude cl ON trade.RefClientId = cl.RefClientId  
 -- WHERE cl.RefClientId IS NULL  
 -- AND (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)  
 -- AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)  
 -- AND trade.RefSegmentId IN (@BSECashId, @NSECashId)  
 -- AND trade.TradeDate = @RunDateInternal  
  
 --END   
 --ELSE IF @ReportIdInternal = @S164Id  
 --BEGIN  
 -- INSERT INTO #trades (RefClientId, Quantity, Turnover, BuySell, RefSegmentId, RefInstrumentId)  
 -- SELECT  
 --  trade.RefClientId,  
 --  CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)  
 --   THEN trade.Quantity * ISNULL(inst.ContractSize, 1)  
 --   ELSE trade.Quantity END AS Quantity,  
 --  CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)  
 --   THEN trade.Quantity * trade.Rate * ISNULL(inst.ContractSize, 1)  
 --   ELSE trade.Quantity * trade.Rate END AS Turnover,  
 --  CASE WHEN trade.BuySell = 'Buy' THEN 1 ELSE 0 END AS BuySell,  
 --  trade.RefSegmentId,  
 --  trade.RefInstrumentId  
 -- FROM dbo.CoreTrade trade  
 -- INNER JOIN dbo.RefClient client ON client.RefClientId = trade.RefClientId  
 -- LEFT JOIN #clientsToExclude cl ON trade.RefClientId = cl.RefClientId  
 -- INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
 -- WHERE cl.RefClientId IS NULL  
 -- AND (@IsExcludePro = 0 OR client.RefClientStatusId <> @ProStatusId)  
 -- AND (@IsExcludeInstitution = 0 OR client.RefClientStatusId <> @InstituteStatusId)  
 -- AND trade.RefSegmentId IN (@NSEFNOId, @NSECDXId)  
 -- AND trade.TradeDate = @RunDateInternal  
 --END  
  
 DROP TABLE #clientsToExclude  
  
 SELECT  
  RefClientId,  
  RefSegmentId,  
  RefInstrumentId,  
  SUM(CASE WHEN BuySell = 1 THEN Quantity ELSE 0 END) AS BuyQty,  
  SUM(CASE WHEN BuySell = 0 THEN Quantity ELSE 0 END) AS SellQty,  
  SUM(CASE WHEN BuySell = 1 THEN Turnover ELSE 0 END) AS BuyTurnover,  
  SUM(CASE WHEN BuySell = 0 THEN Turnover ELSE 0 END) AS SellTurnover  
 INTO #clientWiseTrades  
 FROM #trades  
 GROUP BY RefClientId, RefSegmentId, RefInstrumentId  
  
 DROP TABLE #trades  
  
 --SELECT  
 -- RefClientId,  
 -- RefSegmentId,  
 -- RefInstrumentId,  
 -- CASE   
 --  WHEN BuyQty <= SellQty  
 --   THEN BuyQty   
 --  ELSE   
 --   SellQty   
 -- END AS Qty,  
 -- (BuyTurnover / BuyQty) AS BuyRate,  
 -- (SellTurnover / SellQty) AS SellRate  
 --INTO #intradayData  
 --FROM #clientWiseTrades  
 --WHERE SellQty > 0 AND BuyQty > 0  
  
-- DROP TABLE #clientWiseTrades  
  
 SELECT  
  RefClientId,  
  SUM(  
   (  
    (CASE WHEN BuyQty <= SellQty THEN BuyQty ELSE SellQty END) * ((BuyTurnover / BuyQty) + (SellTurnover / SellQty))  
   )  
  ) AS ClientTO,  
  SUM(  
   (  
    (CASE WHEN BuyQty <= SellQty THEN BuyQty ELSE SellQty END) * ((SellTurnover / SellQty) - (BuyTurnover / BuyQty))  
   )  
  ) AS ClientPL  
 INTO #clientFinalData  
 FROM #clientWiseTrades  
 WHERE SellQty <> 0 AND BuyQty <> 0     
 GROUP BY RefClientId  
  
 DROP TABLE #clientWiseTrades  
 --DROP TABLE #intradayData  
  
 --SELECT  
 -- RefClientId,  
 -- SUM(ClientTO) AS ClientTO,  
 -- SUM(ClientPL) AS ClientPL  
 --INTO #clientFinalData  
 --FROM #clientFinalDataInter  
 --GROUP BY RefClientId  
  
 --DROP TABLE #clientFinalDataInter  
  
 SELECT  
  t.RefClientId,  
  t.ClientTO,  
  t.ClientPL,
  COUNT(t.RefClientId) OVER() CRN  
 INTO #group1  
 FROM (SELECT   
   RefClientId,  
   ClientTO,  
   ClientPL,  
   DENSE_RANK() OVER (ORDER BY ClientTO DESC) AS RN  
  FROM #clientFinalData  
  WHERE ClientPL > 0  
 ) t WHERE t.RN <= @NoOfClThresh  
  
 SELECT  
  t.RefClientId,  
  t.ClientTO,  
  t.ClientPL,
  COUNT(t.RefClientId) OVER() CRN
 INTO #group2  
 FROM (SELECT   
   RefClientId,  
   ClientTO,  
   ClientPL,  
   DENSE_RANK() OVER (ORDER BY ClientTO DESC) AS RN  
  FROM #clientFinalData  
  WHERE ClientPL < 0  
 ) t WHERE t.RN <= @NoOfClThresh  
  
 DROP TABLE #clientFinalData  


  
 SELECT  
  SUM(ClientTO) AS GroupTO,  
  SUM(ClientPL) AS GroupPL  
 INTO #group1Total  
 FROM #group1  
  
 SELECT  
  SUM(ClientTO) AS GroupTO,  
  SUM(ClientPL) AS GroupPL  
 INTO #group2Total  
 FROM #group2  
   
   
 Declare @Grp1PL DECIMAL(28,2),@Grp1TO DECIMAL(28,2),@Grp2PL DECIMAL(28,2),@Grp2TO DECIMAL(28,2)  
 SELECT  @Grp2PL = GroupPL, @Grp2TO = GroupTO FROM #group2Total  
 SELECT  @Grp1PL = GroupPL, @Grp1TO = GroupTO FROM #group1Total  
  
 CREATE TABLE #data(   
  RefClientId INT,  
  ClientTO DECIMAL(28, 2),   
  ClientPL DECIMAL(28, 2),   
  GroupPL DECIMAL(28, 2),   
  GroupTO DECIMAL(28, 2),   
  ClientPerc DECIMAL(28, 2),  
  DataType INT NOT NULL  
 )  
 IF(ABS(@Grp1PL)>=@GrpPLThresh AND @Grp1TO >= @GrpTOThresh)  
  
 BEGIN    
 INSERT INTO #data(RefClientId, ClientTO, ClientPL, GroupPL, GroupTO, ClientPerc,DataType)  
  SELECT  
   grp.RefClientId,  
   --cl.ClientId,  
   --cl.[Name] AS ClientName,  
   grp.ClientTO,  
   grp.ClientPL,  
   @Grp1PL,  
   @Grp1TO,  
   (ABS(grp.ClientPL) * 100 / ABS(@Grp1PL)) AS ClientPerc,  
   1  
  FROM #group1 grp  
  WHERE (ABS(grp.ClientPL) * 100 / ABS(@Grp1PL))>=@ClSharePercThresh  AND @IsGroupGreaterThanOneClient < CRN
 END  
  
 DROP TABLE #group1  
 DROP TABLE #group1Total  
  
  
 IF(ABS(@Grp2PL)>=@GrpPLThresh AND @Grp2TO >= @GrpTOThresh)  
  
 BEGIN    
 INSERT INTO #data(RefClientId, ClientTO, ClientPL, GroupPL, GroupTO, ClientPerc,DataType)  
  SELECT  
   grp.RefClientId,  
   grp.ClientTO,  
   grp.ClientPL,  
   @Grp2PL,  
   @Grp2TO,  
   (ABS(grp.ClientPL) * 100 / ABS(@Grp2PL)) AS ClientPerc,  
   2  
  FROM #group2 grp  
  WHERE (ABS(grp.ClientPL) * 100 / ABS(@Grp2PL)) >= @ClSharePercThresh  
 END  
  
 DROP TABLE #group2  
 DROP TABLE #group2Total  
  
  
 SELECT  t.RefClientId,    
   cl.ClientId,  
   cl.[Name] AS ClientName,   
   t.ClientTO,    
   t.ClientPL,    
   t.GroupPL,    
   t.GroupTO,    
   t.ClientPerc,   
   t.DescriptionClientPerc,  
   @RunDateInternal AS TradeDate   
 FROM (  
  
  SELECT  
   fd.RefClientId,  
     
   fd.ClientTO,  
   fd.ClientPL,  
   fd.GroupPL,  
   fd.GroupTO,  
   fd.ClientPerc,  
   STUFF((SELECT ' ; ' + client.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) COLLATE DATABASE_DEFAULT + '%'  
    FROM #data t  
    INNER JOIN dbo.RefClient client ON client.RefClientId = t.RefClientId   
    WHERE DataType = 1 AND fd.RefClientId <> t.RefClientId  
    FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc  
  FROM #data fd  
  WHERE DataType = 1   
  
  UNION ALL  
  
  SELECT  
   fd.RefClientId,  
   fd.ClientTO,  
   fd.ClientPL,  
   fd.GroupPL,  
   fd.GroupTO,  
   fd.ClientPerc,  
   STUFF((SELECT ' ; ' + client.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) COLLATE DATABASE_DEFAULT + '%'  
    FROM #data t   
    INNER JOIN dbo.RefClient client ON client.RefClientId = t.RefClientId   
    WHERE DataType = 2 AND fd.RefClientId <> t.RefClientId  
    FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc  
  FROM #data fd  
  WHERE DataType = 2  
 ) t  
 INNER JOIN dbo.RefClient cl On cl.RefClientId = t.RefClientId  
  
END  
GO
------RC-WEB-65063 END
---S154
------RC-WEB-65063 START
GO
 AlTER PROCEDURE dbo.AML_GetHighTurnoverbyGroupofNewClientsin1DayEQ    
(      
 @RunDate DATETIME,      
 @ReportId INT      
)      
AS      
BEGIN      
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @FromDate DATETIME,       
   @DormantDays INT, @BSECashId INT, @NSECashId INT, @IsGroupGreaterThanOneClient INT,    
   @IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT    
      
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)      
 SET @ReportIdInternal = @ReportId      
 SELECT @DormantDays = CONVERT(INT, [Value]) FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal  AND [Name]='New_Not_traded_Days'    
 SET @FromDate = DATEADD(d, -@DormantDays, @RunDateInternal)      
    
 SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'      
 SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH' 
 
 SELECT   
  @IsGroupGreaterThanOneClient = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Active_In_Report' 
    
 SELECT     
  @IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END    
 FROM dbo.SysAmlReportSetting     
 WHERE     
  RefAmlReportId = @ReportIdInternal     
  AND [Name] = 'Exclude_Pro'    
     
 SELECT     
  @IsExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END    
 FROM dbo.SysAmlReportSetting     
 WHERE     
  RefAmlReportId = @ReportIdInternal     
  AND [Name] = 'Exclude_Institution'    
     
 SELECT     
  @ProStatusId = RefClientStatusId     
 FROM dbo.RefClientStatus     
 WHERE [Name] = 'Pro'    
     
     
 SELECT     
  @InstituteStatusId = RefClientStatusId    
 FROM dbo.RefClientStatus WHERE [Name] = 'Institution'    
      
 SELECT      
  RefClientId      
 INTO #clientsToExclude      
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion      
 WHERE RefAmlReportId = @ReportIdInternal      
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)      
      
 SELECT      
  rul.Threshold,      
  rul.Threshold2,      
  rul.Threshold3,      
  rul.Threshold4,      
  scrip.[Name] AS ScripGroup,      
  scrip.RefScripGroupId      
 INTO #scenarioRules      
 FROM dbo.RefAmlScenarioRule rul      
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId      
 INNER JOIN dbo.RefScripGroup scrip ON scrip.RefScripGroupId = link.RefScripGroupId      
 WHERE rul.RefAmlReportId = @ReportIdInternal      
      
 SELECT      
  trade.CoreTradeId,      
  inst.Isin,      
  inst.GroupName,      
  inst.RefSegmentId,      
  cl.AccountOpeningDate,      
  trade.RefClientId      
 INTO #tradeIds      
 FROM dbo.CoreTrade trade      
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId      
 INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId    
 WHERE trade.TradeDate = @RunDateInternal AND trade.RefSegmentId IN (@BSECashId, @NSECashId)    
 AND (@IsExcludePro = 0 OR cl.RefClientStatusId <> @ProStatusId)    
 AND (@IsExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstituteStatusId)    
 AND NOT EXISTS(SELECT 1 FROM #clientsToExclude clEx      
  WHERE clEx.RefClientId = trade.RefClientId)      
      
 DROP TABLE #clientsToExclude      
      
 SELECT DISTINCT      
  ids.Isin,      
  CASE WHEN inst.GroupName IS NOT NULL      
  THEN inst.GroupName      
  ELSE 'B' END AS GroupName,    
  inst.Code    
 INTO #allNseGroupData      
 FROM #tradeIds ids      
 LEFT JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @BSECashId      
  AND ids.Isin = inst.Isin  AND inst.[Status]='A'     
 WHERE ids.RefSegmentId = @NSECashId      
    
    
 SELECT Isin, COUNT(1) AS rcount    
 INTO #multipleGroups    
 FROM #allNseGroupData    
 GROUP BY Isin    
 HAVING COUNT(1)>1    
    
 SELECT t.Isin, t.GroupName     
 INTO #nseGroupData    
 FROM     
 (    
  SELECT grp.Isin, grp.GroupName     
  FROM #allNseGroupData grp    
  WHERE NOT EXISTS    
  (    
   SELECT 1 FROM #multipleGroups mg     
   WHERE mg.Isin=grp.Isin    
  )    
    
  UNION    
    
  SELECT  mg.Isin, grp.GroupName    
  FROM #multipleGroups mg    
  INNER JOIN #allNseGroupData grp ON grp.Isin=mg.Isin AND grp.Code like '5%'    
 )t    
    
 DROP TABLE #multipleGroups    
 DROP TABLE #allNseGroupData     
      
 SELECT       
  ids.*,      
  rules.RefScripGroupId      
 INTO #finalIds      
 FROM #tradeIds ids      
 LEFT JOIN #nseGroupData nse ON ids.Isin = nse.Isin AND ids.RefSegmentId=@NSECashId    
 INNER JOIN #scenarioRules rules ON (ids.RefSegmentId = @BSECashId       
  AND rules.ScripGroup = ids.GroupName) OR (ids.RefSegmentId = @NSECashId      
  AND rules.ScripGroup = nse.GroupName)       
      
 DROP TABLE #tradeIds      
 DROP TABLE #nseGroupData      
      
 SELECT DISTINCT      
  RefClientId,      
  AccountOpeningDate      
 INTO #allClients      
 FROM #finalIds      
      
 SELECT      
  RefClientId,      
  DATEDIFF(DAY, TradeDate, @RunDateInternal) AS NoOfDays      
 INTO #lastTrade      
 FROM (SELECT       
   trade.RefClientId,      
   trade.TradeDate,      
   ROW_NUMBER() OVER (PARTITION BY trade.RefClientId ORDER BY trade.TradeDate DESC) AS RN      
  FROM #allClients cl      
  INNER JOIN dbo.CoreTrade trade ON cl.RefClientId = trade.RefClientId      
  WHERE trade.TradeDate < @RunDateInternal      
 ) t      
 WHERE t.RN = 1      
      
 SELECT      
  al.RefClientId,      
  CASE WHEN lt.NoOfDays IS NULL      
  THEN 0      
  ELSE lt.NoOfDays END AS NoOfDays      
 INTO #finalClients      
 FROM #allClients al      
 LEFT JOIN #lastTrade lt ON al.RefClientId = lt.RefClientId      
 WHERE lt.NoOfDays IS NULL OR lt.NoOfDays > @DormantDays      
  OR (al.AccountOpeningDate IS NOT NULL AND al.AccountOpeningDate >= @FromDate)      
      
 DROP TABLE #allClients      
 DROP TABLE #lastTrade      
      
 SELECT      
  trade.RefClientId,      
  trade.RefInstrumentId,      
  CASE WHEN trade.BuySell = 'Buy'      
   THEN 1      
   ELSE 0 END BuySell,      
  trade.Quantity,      
  (trade.Rate * trade.Quantity) AS tradeTO,      
  ids.RefScripGroupId,      
  trade.RefSegmentId      
 INTO #tradeData      
 FROM #finalClients cl      
 INNER JOIN #finalIds ids ON cl.RefClientId = ids.RefClientId      
 INNER JOIN dbo.CoreTrade trade ON ids.CoreTradeId = trade.CoreTradeId      
      
 DROP TABLE #finalIds      
      
 SELECT      
  RefClientId,      
  RefScripGroupId,      
  RefInstrumentId,      
  RefSegmentId,      
  BuySell,      
  SUM(tradeTO) AS ClientTO,      
  SUM(Quantity) AS ClientQT      
 INTO #clientTOs      
 FROM #tradeData      
 GROUP BY RefClientId, RefScripGroupId, RefInstrumentId, RefSegmentId, BuySell      
      
 DROP TABLE #tradeData      
      
 SELECT      
  t.RefInstrumentId,      
  t.RefSegmentId,      
  t.BuySell,      
  t.RefScripGroupId,      
  t.RefClientId,      
  t.ClientTO,      
  t.ClientQT,
   COUNT(RefClientId) OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell ) AS CRN     
 INTO #topClients      
 FROM (SELECT       
   RefInstrumentId,      
   RefSegmentId,      
   BuySell,      
   RefScripGroupId,      
   RefClientId,      
   ClientTO,      
   ClientQT,      
   DENSE_RANK() OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell ORDER BY ClientTO DESC) AS RN      
  FROM #clientTOs      
 ) t      
 INNER JOIN #scenarioRules rules ON t.RefScripGroupId = rules.RefScripGroupId      
 WHERE t.RN <= rules.Threshold3      
      
 DROP TABLE #clientTOs      
      
 SELECT      
  RefScripGroupId,      
  RefInstrumentId,       
  RefSegmentId,       
  BuySell,      
  SUM(ClientTO) AS GroupTO      
 INTO #groupedSum      
 FROM #topClients 
 WHERE  @IsGroupGreaterThanOneClient < CRN
 GROUP BY RefScripGroupId, RefInstrumentId, RefSegmentId, BuySell      
      
 SELECT      
  grp.RefScripGroupId,      
  grp.RefInstrumentId,      
  grp.BuySell,      
  grp.RefSegmentId,      
  grp.GroupTO,      
  bhav.NetTurnOver AS ExchangeTO,      
  (grp.GroupTO * 100 / bhav.NetTurnOver) AS GroupContributedPerc      
 INTO #selectedScrips      
 FROM #groupedSum grp      
 INNER JOIN dbo.CoreBhavCopy bhav ON grp.RefInstrumentId = bhav.RefInstrumentId      
 INNER JOIN #scenarioRules rules ON rules.RefScripGroupId = grp.RefScripGroupId      
 WHERE bhav.[Date] = @RunDateInternal AND grp.GroupTO >= rules.Threshold2      
  AND (grp.GroupTO * 100 / bhav.NetTurnOver) >= rules.Threshold      
      
 DROP TABLE #groupedSum      
      
 SELECT      
  cl.RefClientId,      
  client.ClientId,      
  client.[Name] AS ClientName,      
  seg.Segment,      
  @RunDateInternal AS TradeDate,      
  rules.ScripGroup AS GroupName,      
  instru.Code AS ScripCode,      
  instru.[Name] AS ScripName,      
  scrips.GroupTO,      
  scrips.GroupContributedPerc,      
  scrips.ExchangeTO,      
  cl.ClientQT AS ClientTradedQty,      
  (cl.ClientTO / cl.ClientQT) AS AvgRate,      
  cl.ClientTO,      
  (cl.ClientTO * 100 / scrips.ExchangeTO) AS ClientPerc,      
  (cl.ClientTO * 100 / scrips.GroupTO) AS GroupSharePerc,      
  rules.RefScripGroupId,      
  scrips.RefInstrumentId,      
  scrips.RefSegmentId,      
  scrips.BuySell,      
  fl.NoOfDays      
 INTO #finalData      
 FROM #selectedScrips scrips      
 INNER JOIN #topClients cl ON scrips.RefInstrumentId = cl.RefInstrumentId       
  AND scrips.RefSegmentId = cl.RefSegmentId AND scrips.BuySell = cl.BuySell      
 INNER JOIN #finalClients fl ON fl.RefClientId = cl.RefClientId      
 INNER JOIN dbo.RefClient client ON cl.RefClientId = client.RefClientId      
 INNER JOIN dbo.RefSegmentEnum seg ON scrips.RefSegmentId = seg.RefSegmentEnumId      
 INNER JOIN #scenarioRules rules ON scrips.RefScripGroupId = rules.RefScripGroupId      
 INNER JOIN dbo.RefInstrument instru ON scrips.RefInstrumentId = instru.RefInstrumentId      
      
 DROP TABLE #topClients      
 DROP TABLE #finalClients      
 DROP TABLE #selectedScrips      
      
 SELECT      
  final.RefClientId,      
  final.ClientId,      
  final.ClientName,      
  final.RefSegmentId,      
  final.Segment,      
  final.TradeDate,      
  final.GroupName,      
  CASE WHEN final.BuySell = 1      
   THEN 'Buy'      
   ELSE 'Sell' END AS BuySell,      
  final.ScripCode,      
  final.ScripName,      
  CONVERT(DECIMAL(28, 2), final.GroupTO) AS GroupTO,      
  CONVERT(DECIMAL(28, 2), final.GroupContributedPerc) AS GroupContributedPerc,      
  CONVERT(DECIMAL(28, 2), final.ExchangeTO) AS ExchangeTO,      
  CONVERT(DECIMAL(28, 2), final.ClientTradedQty) AS ClientTradedQty,      
  CONVERT(DECIMAL(28, 2), final.AvgRate) AS AvgRate,      
  CONVERT(DECIMAL(28, 2), final.ClientTO) AS ClientTO,      
  CONVERT(DECIMAL(28, 2), final.ClientPerc) AS ClientPerc,      
  CONVERT(DECIMAL(28, 2), final.GroupSharePerc) AS GroupSharePerc,      
  final.NoOfDays,      
  STUFF((SELECT ' ; ' + t.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) + '%'      
     FROM #finalData t      
     WHERE t.RefInstrumentId = final.RefInstrumentId AND t.RefSegmentId = final.RefSegmentId      
      AND t.BuySell = final.BuySell AND t.RefClientId <> final.RefClientId      
     ORDER BY t.ClientPerc DESC      
   FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc,      
  final.RefInstrumentId      
 FROM #finalData final      
 INNER JOIN #scenarioRules rules ON final.RefScripGroupId = rules.RefScripGroupId      
 WHERE final.GroupSharePerc >= rules.Threshold4      
 ORDER BY final.RefInstrumentId, final.RefSegmentId, final.BuySell, final.ClientPerc DESC      
      
END      
GO
------RC-WEB-65063 END
---S156
------RC-WEB-65063 START
GO
 ALTER PROCEDURE dbo.AML_GetHighTurnoverbyGroupofNewClientsin1DayFNO  
(  
 @RunDate DATETIME,  
 @ReportId INT  
)  
AS  
BEGIN  
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @FromDate DATETIME,   
  @DormantDays INT, @OPTSTKId INT, @OPTIDXId INT, @OPTCURId INT, @OPTIRCId INT,   
  @FUTIDXId INT, @FUTSTKId INT, @FUTIRDId INT, @FUTIRTId INT, @FUTCURId INT,  
  @FUTIRCId INT, @FUTIVXId INT, @FUTIRFId INT, @IsGroupGreaterThanOneClient INT,  
  @IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT  
  
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
 SET @ReportIdInternal = @ReportId  
   
 SELECT @DormantDays = CONVERT(INT, [Value])  
 FROM dbo.SysAmlReportSetting   
 WHERE RefAmlReportId = @ReportIdInternal  
 AND [Name]='New_Not_traded_Days'  
  
 SET @FromDate = DATEADD(d, -@DormantDays, @RunDateInternal)  
 SELECT @OPTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'  
 SELECT @OPTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'  
 SELECT @OPTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'  
 SELECT @OPTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIRC'  
 SELECT @FUTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIDX'  
 SELECT @FUTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTSTK'  
 SELECT @FUTIRDId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRD'  
 SELECT @FUTIRTId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRT'  
 SELECT @FUTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR'  
 SELECT @FUTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRC'  
 SELECT @FUTIVXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIVX'  
 SELECT @FUTIRFId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRF'  
  
  SELECT   
	@IsGroupGreaterThanOneClient = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
	FROM dbo.SysAmlReportSetting   
	WHERE   
	RefAmlReportId = @ReportIdInternal   
	AND [Name] = 'Active_In_Report'

 SELECT   
  @IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Exclude_Pro'  
   
 SELECT   
  @IsExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting   
 WHERE   
  RefAmlReportId = @ReportIdInternal   
  AND [Name] = 'Exclude_Institution'  
   
 SELECT   
  @ProStatusId = RefClientStatusId   
 FROM dbo.RefClientStatus   
 WHERE [Name] = 'Pro'  
   
   
 SELECT   
  @InstituteStatusId = RefClientStatusId  
 FROM dbo.RefClientStatus WHERE [Name] = 'Institution'  
  
 SELECT   
  RefSegmentEnumId,  
  Segment  
 INTO #segments  
 FROM dbo.RefSegmentEnum WHERE Code IN ('NSE_FNO', 'NSE_CDX')  
  
 SELECT  
  RefClientId  
 INTO #clientsToExclude  
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion  
 WHERE RefAmlReportId = @ReportIdInternal  
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)  
  
 SELECT  
  rul.Threshold,  
  rul.Threshold2,  
  rul.Threshold3,  
  rul.Threshold4,  
  instType.InstrumentType,  
  instType.RefInstrumentTypeId  
 INTO #scenarioRules  
 FROM dbo.RefAmlScenarioRule rul  
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId  
 INNER JOIN dbo.RefInstrumentType instType ON instType.RefInstrumentTypeId = link.RefInstrumentTypeId  
 WHERE rul.RefAmlReportId = @ReportIdInternal   
  AND instType.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTCURId, @OPTIRCId, @FUTIDXId, @FUTSTKId,  
   @FUTIRDId, @FUTIRTId, @FUTCURId, @FUTIRCId, @FUTIVXId, @FUTIRFId)  
  
 SELECT DISTINCT  
  trade.RefClientId,  
  cl.AccountOpeningDate  
 INTO #allClients  
 FROM dbo.CoreTrade trade  
 INNER JOIN #segments seg ON trade.RefSegmentId = RefSegmentEnumId  
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
 INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = inst.RefInstrumentTypeId  
 INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId  
 WHERE trade.TradeDate = @RunDateInternal  
  AND (@IsExcludePro = 0 OR cl.RefClientStatusId <> @ProStatusId)  
  AND (@IsExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstituteStatusId)  
  AND NOT EXISTS(SELECT 1 FROM #clientsToExclude clEx  
   WHERE clEx.RefClientId = trade.RefClientId)  
  
 DROP TABLE #clientsToExclude  
  
 SELECT  
  RefClientId,  
  DATEDIFF(DAY, TradeDate, @RunDateInternal) AS NoOfDays  
 INTO #lastTrade  
 FROM (SELECT   
   trade.RefClientId,  
   trade.TradeDate,  
   ROW_NUMBER() OVER (PARTITION BY trade.RefClientId ORDER BY trade.TradeDate DESC) AS RN  
  FROM #allClients cl  
  INNER JOIN dbo.CoreTrade trade ON cl.RefClientId = trade.RefClientId  
  WHERE trade.TradeDate < @RunDateInternal  
 ) t  
 WHERE t.RN = 1  
  
 SELECT  
  al.RefClientId,  
  CASE WHEN lt.NoOfDays IS NULL  
  THEN 0  
  ELSE lt.NoOfDays END AS NoOfDays  
 INTO #finalClients  
 FROM #allClients al  
 LEFT JOIN #lastTrade lt ON al.RefClientId = lt.RefClientId  
 WHERE lt.NoOfDays IS NULL OR lt.NoOfDays > @DormantDays  
  OR (al.AccountOpeningDate IS NOT NULL AND al.AccountOpeningDate >= @FromDate)  
  
  
 DROP TABLE #allClients  
 DROP TABLE #lastTrade  
  
 SELECT  
  trade.RefClientId,  
  rules.RefInstrumentTypeId,  
  trade.RefInstrumentId,  
  CASE WHEN trade.BuySell = 'Buy'  
   THEN 1  
   ELSE 0 END BuySell,  
  trade.RefSegmentId,  
  CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)  
  THEN trade.Quantity * ISNULL(inst.ContractSize, 1)  
  ELSE trade.Quantity END AS Quantity,  
  CASE WHEN inst.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTIRCId)  
   THEN (ISNULL(inst.StrikePrice, 0) + trade.Rate) * trade.Quantity  
   WHEN inst.RefInstrumentTypeId = @OPTCURId  
   THEN (ISNULL(inst.StrikePrice, 0) + trade.Rate) * trade.Quantity * ISNULL(inst.ContractSize, 1)  
   WHEN inst.RefInstrumentTypeId = @FUTCURId  
   THEN trade.Rate * trade.Quantity * ISNULL(inst.ContractSize, 1)  
   ELSE trade.Rate * trade.Quantity END AS TurnOver  
 INTO #tradeData  
 FROM #finalClients cl  
 INNER JOIN dbo.CoreTrade trade ON cl.RefClientId = trade.RefClientId  
 INNER JOIN #segments seg ON trade.RefSegmentId = RefSegmentEnumId  
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
 INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = inst.RefInstrumentTypeId  
 WHERE trade.TradeDate = @RunDateInternal  
  AND inst.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTCURId, @OPTIRCId, @FUTIDXId, @FUTSTKId,  
   @FUTIRDId, @FUTIRTId, @FUTCURId, @FUTIRCId, @FUTIVXId, @FUTIRFId)  
  
 SELECT  
  RefClientId,  
  RefInstrumentTypeId,  
  RefInstrumentId,  
  RefSegmentId,  
  BuySell,  
  SUM(TurnOver) AS ClientTO,  
  SUM(Quantity) AS ClientQT  
 INTO #clientTOs  
 FROM #tradeData  
 GROUP BY RefClientId, RefInstrumentId, RefInstrumentTypeId, RefSegmentId, BuySell  
  
 DROP TABLE #tradeData  
  
 SELECT  
  t.RefInstrumentId,  
  t.RefSegmentId,  
  t.BuySell,  
  t.RefInstrumentTypeId,  
  t.RefClientId,  
  t.ClientTO,  
  t.ClientQT,
  COUNT(t.RefClientId) OVER (PARTITION BY t.RefInstrumentId, t.RefSegmentId, t.BuySell ) AS CRN
 INTO #topClients  
 FROM (SELECT   
   RefInstrumentId,  
   RefSegmentId,  
   BuySell,  
   RefInstrumentTypeId,  
   RefClientId,  
   ClientTO,  
   ClientQT,  
   DENSE_RANK() OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell ORDER BY ClientTO DESC) AS RN  
  FROM #clientTOs  
 ) t  
 INNER JOIN #scenarioRules rules ON t.RefInstrumentTypeId = rules.RefInstrumentTypeId  
 WHERE t.RN <= rules.Threshold3  
  
 DROP TABLE #clientTOs  
  
 SELECT  
  RefInstrumentTypeId,  
  RefInstrumentId,   
  RefSegmentId,   
  BuySell,  
  SUM(ClientTO) AS GroupTO  
 INTO #groupedSum  
 FROM #topClients  
 WHERE @IsGroupGreaterThanOneClient < CRN
 GROUP BY RefInstrumentTypeId, RefInstrumentId, RefSegmentId, BuySell  
  
 SELECT  
  grp.RefInstrumentTypeId,  
  grp.RefInstrumentId,  
  grp.BuySell,  
  grp.RefSegmentId,  
  grp.GroupTO,  
  bhav.NetTurnOver AS ExchangeTO,  
  (grp.GroupTO * 100 / bhav.NetTurnOver) AS GroupContributedPerc  
 INTO #selectedScrips  
 FROM #groupedSum grp  
 INNER JOIN dbo.CoreBhavCopy bhav ON grp.RefInstrumentId = bhav.RefInstrumentId  
 INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = grp.RefInstrumentTypeId  
 WHERE bhav.[Date] = @RunDateInternal AND grp.GroupTO >= rules.Threshold2  
  AND (grp.GroupTO * 100 / bhav.NetTurnOver) >= rules.Threshold  
  
 DROP TABLE #groupedSum  
  
 SELECT  
  cl.RefClientId,  
  client.ClientId,  
  client.[Name] AS ClientName,  
  seg.Segment,  
  @RunDateInternal AS TradeDate,  
  inst.[Name] + '-'  + rules.InstrumentType + '-' +           
   CASE WHEN inst.ExpiryDate IS NULL THEN ''  
   ELSE CONVERT(VARCHAR(100), inst.ExpiryDate, 106) END + '-' +   
   ISNULL(inst.PutCall, '') + '-' +   
   ISNULL(CONVERT(VARCHAR(100), inst.StrikePrice), '') AS ScripTypeExpDtPutCallStrikePrice,  
  scrips.GroupTO,  
  scrips.GroupContributedPerc,  
  scrips.ExchangeTO,  
  cl.ClientQT AS ClientTradedQty,  
  (cl.ClientTO / cl.ClientQT) AS AvgRate,  
  cl.ClientTO,  
  (cl.ClientTO * 100 / scrips.ExchangeTO) AS ClientPerc,  
  (cl.ClientTO * 100 / scrips.GroupTO) AS GroupSharePerc,  
  rules.RefInstrumentTypeId,  
  scrips.RefInstrumentId,  
  scrips.RefSegmentId,  
  scrips.BuySell,  
  fl.NoOfDays  
 INTO #finalData  
 FROM #selectedScrips scrips  
 INNER JOIN #topClients cl ON scrips.RefInstrumentId = cl.RefInstrumentId   
  AND scrips.RefSegmentId = cl.RefSegmentId AND scrips.BuySell = cl.BuySell  
 INNER JOIN #finalClients fl ON fl.RefClientId = cl.RefClientId  
 INNER JOIN dbo.RefClient client ON cl.RefClientId = client.RefClientId  
 INNER JOIN #segments seg ON scrips.RefSegmentId = seg.RefSegmentEnumId  
 INNER JOIN #scenarioRules rules ON scrips.RefInstrumentTypeId = rules.RefInstrumentTypeId  
 INNER JOIN dbo.RefInstrument inst ON scrips.RefInstrumentId = inst.RefInstrumentId  
  
 DROP TABLE #topClients  
 DROP TABLE #finalClients  
 DROP TABLE #selectedScrips  
  
 SELECT  
  final.RefClientId,  
  final.ClientId,  
  final.ClientName,  
  final.RefSegmentId AS SegmentId,  
  final.Segment,  
  final.TradeDate,  
  rules.InstrumentType,  
  final.ScripTypeExpDtPutCallStrikePrice,  
  CASE WHEN final.BuySell = 1  
   THEN 'Buy'  
   ELSE 'Sell' END AS BuySell,  
  CONVERT(DECIMAL(28, 2), final.GroupTO) AS GroupTO,  
  CONVERT(DECIMAL(28, 2), final.GroupContributedPerc) AS GroupContributedPerc,  
  CONVERT(DECIMAL(28, 2), final.ExchangeTO) AS ExchangeTO,  
  CONVERT(DECIMAL(28, 2), final.ClientTradedQty) AS ClientTradedQty,  
  CONVERT(DECIMAL(28, 2), final.AvgRate) AS AvgRate,  
  CONVERT(DECIMAL(28, 2), final.ClientTO) AS ClientTO,  
  CONVERT(DECIMAL(28, 2), final.ClientPerc) AS ClientPerc,  
  CONVERT(DECIMAL(28, 2), final.GroupSharePerc) AS GroupSharePerc,  
  final.NoOfDays,  
  STUFF((SELECT ' ; ' + t.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) + '%'  
     FROM #finalData t  
     WHERE t.RefInstrumentId = final.RefInstrumentId AND t.RefSegmentId = final.RefSegmentId  
      AND t.BuySell = final.BuySell AND t.RefClientId <> final.RefClientId  
     ORDER BY t.ClientPerc DESC  
   FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc,  
  final.RefInstrumentId  
 FROM #finalData final  
 INNER JOIN #scenarioRules rules ON final.RefInstrumentTypeId = rules.RefInstrumentTypeId  
 WHERE final.GroupSharePerc >= rules.Threshold4  
 ORDER BY final.RefInstrumentId, final.RefSegmentId, final.BuySell, final.ClientPerc DESC  
  
END  
GO
------RC-WEB-65063 END
---S157
------RC-WEB-65063 START
GO
  ALTER PROCEDURE dbo.AML_GetSmallOrdersinSingleStockbyGroupofClientsEQ (    
 @RunDate DATETIME,    
 @ReportId INT    
)    
AS    
BEGIN    
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @IsExcludePro INT, @InExcludeInstitution INT,    
  @ExcludeScrips VARCHAR(MAX), @ProStatusId INT, @InstituteStatusId INT, @SmallOrderQtyId INT,    
  @GroupSmallOrderQty INT, @PercentageSmallOrders INT, @MimGroupOrderId INT, @ClientNumGroupsId INT,    
  @BSECashId INT, @NSECashId INT,@IsGroupGreaterThanOneClient INT    
    
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)    
 SET @ReportIdInternal = @ReportId    
 SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'    
 SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'    
    
 SELECT @SmallOrderQtyId = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = 1222 AND [Name] = 'Threshold_Quantity'    
    
 SELECT @GroupSmallOrderQty = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = 1222 AND [Name] = 'Quantity'    
    
 SELECT @PercentageSmallOrders = CONVERT(DECIMAL, [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = 1222 AND [Name] = 'Threshold_Percentage'    
    
 SELECT @MimGroupOrderId = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = 1222 AND [Name] = 'Minimum_Number_Of_Order'    
    
 SELECT @ClientNumGroupsId = CONVERT(INT, [Value])    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = 1222 AND [Name] = 'Account_Count'    
    
 SELECT @IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = 1222 AND [Name] = 'Exclude_Pro'    
    
 SELECT @InExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = 1222 AND [Name] = 'Exclude_Institution'    
    
 SELECT @ExcludeScrips = [Value]    
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = 1222 AND [Name] = 'Excluded_Groups'    
 
 SELECT  @IsGroupGreaterThanOneClient = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting  WHERE   RefAmlReportId = 1222  AND [Name] = 'Active_In_Report'

 SELECT    
  t.items AS ExcScripGroups    
 INTO #excludedGroups    
 FROM dbo.Split(@ExcludeScrips, ',') AS t    
    
 SELECT @ProStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Pro'    
 SELECT @InstituteStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'    
    
 SELECT    
  RefClientId    
 INTO #clientsToExclude    
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion    
 WHERE RefAmlReportId = @ReportIdInternal    
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)    
    
 SELECT    
  trade.CoreTradeId,    
  inst.Isin,    
  inst.GroupName,    
  inst.RefSegmentId,    
  cl.RefClientId    
 INTO #tradeIds    
 FROM dbo.CoreTrade trade    
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId    
 INNER JOIN dbo.RefClient cl ON trade.RefClientId = cl.RefClientId    
 WHERE trade.TradeDate = @RunDateInternal AND trade.RefSegmentId IN (@BSECashId, @NSECashId)    
  AND (@IsExcludePro = 0 OR cl.RefClientStatusId <> @ProStatusId)    
  AND (@InExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstituteStatusId)    
  AND trade.Quantity <= @SmallOrderQtyId    
  AND NOT EXISTS(SELECT 1 FROM #clientsToExclude clEx    
   WHERE clEx.RefClientId = trade.RefClientId)    
    
 DROP TABLE #clientsToExclude    
    
 SELECT DISTINCT    
  ids.Isin,    
  CASE WHEN inst.GroupName IS NOT NULL    
  THEN inst.GroupName    
  ELSE 'B' END AS GroupName,  
  inst.Code  
 INTO #allNseGroupData    
 FROM #tradeIds ids    
 LEFT JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @BSECashId    
  AND ids.Isin = inst.Isin  AND inst.[Status]='A'   
 WHERE ids.RefSegmentId = @NSECashId    
  
  
 SELECT Isin, COUNT(1) AS rcount  
 INTO #multipleGroups  
 FROM #allNseGroupData  
 GROUP BY Isin  
 HAVING COUNT(1)>1  
  
 SELECT t.Isin, t.GroupName   
 INTO #nseGroupData  
 FROM   
 (  
  SELECT grp.Isin, grp.GroupName   
  FROM #allNseGroupData grp  
  WHERE NOT EXISTS  
  (  
   SELECT 1 FROM #multipleGroups mg   
   WHERE mg.Isin=grp.Isin  
  )  
  
  UNION  
  
  SELECT  mg.Isin, grp.GroupName  
  FROM #multipleGroups mg  
  INNER JOIN #allNseGroupData grp ON grp.Isin=mg.Isin AND grp.Code like '5%'  
 )t  
  
 DROP TABLE #multipleGroups  
 DROP TABLE #allNseGroupData    
    
 SELECT    
  trade.CoreTradeId,    
  trade.RefClientId,    
  trade.RefInstrumentId,    
  CONVERT(INT, trade.Quantity) AS Quantity,    
  CASE WHEN ids.RefSegmentId = @BSECashId     
   THEN ids.GroupName    
   ELSE nse.GroupName END AS ScripGroup,    
  trade.RefSegmentId    
 INTO #tradeData    
 FROM #tradeIds ids    
 INNER JOIN dbo.CoreTrade trade ON ids.CoreTradeId = trade.CoreTradeId    
 LEFT JOIN #nseGroupData nse ON ids.Isin = nse.Isin AND ids.RefSegmentId=@NSECashId  
    
 DROP TABLE #tradeIds    
 DROP TABLE #nseGroupData    
    
 SELECT    
  trade.ScripGroup,    
  trade.RefInstrumentId,    
  trade.RefSegmentId,    
  trade.RefClientId,    
  COUNT(trade.CoreTradeId) AS ClientExeOrders,    
  SUM(trade.Quantity) AS ClientExeSmallOrderQty    
 INTO #clientCalc    
 FROM #tradeData trade    
 INNER JOIN dbo.RefScripGroup scrip ON trade.ScripGroup = scrip.[Name]    
 WHERE NOT EXISTS(SELECT 1 FROM #excludedGroups excGroups    
   WHERE trade.ScripGroup = excGroups.ExcScripGroups)    
 GROUP BY trade.ScripGroup, trade.RefInstrumentId, trade.RefSegmentId, trade.RefClientId    
    
 DROP TABLE #tradeData    
 DROP TABLE #excludedGroups    
    
 SELECT    
  trade.ScripGroup,    
  trade.RefInstrumentId,    
  trade.RefSegmentId,    
  SUM(trade.ClientExeOrders) AS TotalOrder,    
  SUM(trade.ClientExeSmallOrderQty) AS TotalOrderQuantity    
 INTO #totalCalc    
 FROM #clientCalc trade    
 GROUP BY trade.ScripGroup, trade.RefInstrumentId, trade.RefSegmentId    
    
 SELECT    
  t.ScripGroup,    
  t.RefInstrumentId,    
  t.RefSegmentId,    
  t.RefClientId,    
  t.ClientExeOrders,    
  t.ClientExeSmallOrderQty,
  COUNT(t.RefClientId) OVER (PARTITION BY t.RefInstrumentId, t.RefSegmentId) CRN    
 INTO #selectClients    
 FROM (SELECT    
   cc.ScripGroup,    
   cc.RefInstrumentId,    
   cc.RefSegmentId,    
   cc.RefClientId,    
   cc.ClientExeOrders,    
   cc.ClientExeSmallOrderQty,    
   DENSE_RANK() OVER (PARTITION BY cc.RefInstrumentId, cc.RefSegmentId ORDER BY cc.ClientExeSmallOrderQty) AS RN    
  FROM #clientCalc cc    
 ) t    
 WHERE t.RN <= @ClientNumGroupsId    
    
 DROP TABLE #clientCalc    
    
 SELECT    
  trade.ScripGroup,    
  trade.RefInstrumentId,    
  trade.RefSegmentId,    
  SUM(trade.ClientExeOrders) AS SmallTotalOrder,    
  SUM(trade.ClientExeSmallOrderQty) AS SmallTotalOrderQuantity    
 INTO #smallOrderCalc    
 FROM #selectClients trade
 WHERE @IsGroupGreaterThanOneClient<trade.CRN 
 GROUP BY trade.ScripGroup, trade.RefInstrumentId, trade.RefSegmentId    
    
 SELECT DISTINCT    
  small.RefInstrumentId,    
  small.RefSegmentId,    
  total.TotalOrder AS GroupExeOrders,    
  total.TotalOrderQuantity AS GroupExeQty,    
  small.SmallTotalOrder AS SmallOrders,    
  small.SmallTotalOrderQuantity AS SmallOrderQuantity,    
  (small.SmallTotalOrderQuantity * 100 / total.TotalOrderQuantity) AS SmallOrdersPercentage,    
  small.ScripGroup    
 INTO #instrumentDataCalc    
 FROM #smallOrderCalc small    
 INNER JOIN #totalCalc total ON small.RefInstrumentId = total.RefInstrumentId AND small.RefSegmentId = total.RefSegmentId    
 WHERE small.SmallTotalOrderQuantity <= @GroupSmallOrderQty    
  AND small.SmallTotalOrder >= @MimGroupOrderId    
  AND (small.SmallTotalOrderQuantity * 100 / total.TotalOrderQuantity) >= @PercentageSmallOrders    
    
 DROP TABLE #totalCalc    
 DROP TABLE #smallOrderCalc    
    
 SELECT DISTINCT    
  clc.RefClientId,    
  cl.ClientId,    
  cl.[Name] AS ClientName,    
  calc.RefInstrumentId,    
  calc.RefSegmentId,    
  seg.Segment,    
  calc.ScripGroup,    
  inst.Code AS ScripCode,    
  inst.[Name] AS Scrip,    
  calc.GroupExeOrders,    
  calc.GroupExeQty,    
  calc.SmallOrders,    
  calc.SmallOrderQuantity,    
  CONVERT(DECIMAL(28, 2), calc.SmallOrdersPercentage) AS SmallOrdersPercentage,    
  clc.ClientExeOrders,    
  clc.ClientExeSmallOrderQty    
 INTO #finalData    
 FROM #selectClients clc    
 INNER JOIN #instrumentDataCalc calc ON clc.RefInstrumentId = calc.RefInstrumentId     
  AND clc.RefSegmentId = calc.RefSegmentId    
 INNER JOIN dbo.RefClient cl ON clc.RefClientId = cl.RefClientId    
 INNER JOIN dbo.RefSegmentEnum seg ON seg.RefSegmentEnumId = calc.RefSegmentId    
 INNER JOIN dbo.RefInstrument inst ON calc.RefInstrumentId = inst.RefInstrumentId    
    
 DROP TABLE #selectClients    
 DROP TABLE #instrumentDataCalc    
    
 SELECT    
  fd.RefClientId,    
  fd.ClientId,    
  fd.ClientName,    
  fd.RefInstrumentId,    
  @RunDateInternal AS TradeDate,    
  fd.RefSegmentId,    
  fd.Segment,    
  fd.ScripGroup,    
  fd.ScripCode,    
  fd.Scrip,    
  fd.GroupExeOrders,    
  fd.GroupExeQty,    
  fd.SmallOrders,    
  fd.SmallOrderQuantity,    
  fd.SmallOrdersPercentage,    
  fd.ClientExeOrders,    
  fd.ClientExeSmallOrderQty,    
  STUFF((SELECT ' ; ' + t.ClientId + '-' + CONVERT(VARCHAR(100), t.ClientExeSmallOrderQty)    
     FROM #finalData t    
     WHERE t.RefInstrumentId = fd.RefInstrumentId AND t.RefSegmentId = fd.RefSegmentId    
      AND t.RefClientId <> fd.RefClientId    
     ORDER BY t.ClientExeSmallOrderQty    
   FOR XML PATH ('')), 1, 3, '') AS [Description]    
 FROM #finalData fd    
 ORDER BY fd.RefInstrumentId, fd.RefSegmentId, fd.ClientExeSmallOrderQty    
    
END    

GO
------RC-WEB-65063 END
---S159
------RC-WEB-65063 START
GO
 ALTER PROCEDURE dbo.AML_GetSmallOrdersinSingleStockbyGroupofClientsFNO (  
 @RunDate DATETIME,  
 @ReportId INT  
)  
AS  
BEGIN  
 DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @OPTSTKId INT, @OPTIDXId INT, @OPTCURId INT,  
  @OPTIRCId INT, @FUTIDXId INT, @FUTSTKId INT, @FUTIRDId INT, @FUTIRTId INT, @FUTCURId INT,  
  @FUTIRCId INT, @FUTIVXId INT, @FUTIRFId INT, @IsExcludePro INT, @InExcludeInstitution INT,  
  @ProStatusId INT, @InstituteStatusId INT,  @IsGroupGreaterThanOneClient INT  
  
 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)  
 SET @ReportIdInternal = @ReportId  
 SELECT @OPTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTSTK'  
 SELECT @OPTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIDX'  
 SELECT @OPTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTCUR'  
 SELECT @OPTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'OPTIRC'  
 SELECT @FUTIDXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIDX'  
 SELECT @FUTSTKId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTSTK'  
 SELECT @FUTIRDId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRD'  
 SELECT @FUTIRTId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRT'  
 SELECT @FUTCURId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTCUR'  
 SELECT @FUTIRCId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRC'  
 SELECT @FUTIVXId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIVX'  
 SELECT @FUTIRFId = RefInstrumentTypeId FROM dbo.RefInstrumentType WHERE InstrumentType = 'FUTIRF'  
   
 SELECT @IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_Pro'  
 SELECT @InExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
 FROM dbo.SysAmlReportSetting WHERE RefAmlReportId = @ReportIdInternal AND [Name] = 'Exclude_Institution'  
 SELECT @ProStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Pro'  
 SELECT @InstituteStatusId = RefClientStatusId FROM dbo.RefClientStatus WHERE [Name] = 'Institution'  

 SELECT   
	@IsGroupGreaterThanOneClient = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
	FROM dbo.SysAmlReportSetting   
	WHERE   
	RefAmlReportId = @ReportIdInternal   
	AND [Name] = 'Active_In_Report' 
  
 SELECT   
  RefSegmentEnumId,  
  Segment  
 INTO #segments  
 FROM dbo.RefSegmentEnum WHERE Code IN ('NSE_FNO', 'NSE_CDX')  
  
 SELECT  
  RefClientId  
 INTO #clientsToExclude  
 FROM dbo.LinkRefAmlReportRefClientAlertExclusion  
 WHERE RefAmlReportId = @ReportIdInternal  
  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)  
  
 SELECT  
  rul.Threshold,  
  rul.Threshold2,  
  rul.Threshold3,  
  rul.Threshold4,  
  instType.InstrumentType,  
  instType.RefInstrumentTypeId  
 INTO #scenarioRules  
 FROM dbo.RefAmlScenarioRule rul  
 INNER JOIN dbo.LinkRefAmlScenarioRuleRefInstrumentType link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId  
 INNER JOIN dbo.RefInstrumentType instType ON instType.RefInstrumentTypeId = link.RefInstrumentTypeId  
 WHERE RefAmlReportId = @ReportIdInternal   
  AND instType.RefInstrumentTypeId IN (@OPTSTKId, @OPTIDXId, @OPTCURId, @OPTIRCId, @FUTIDXId, @FUTSTKId,  
   @FUTIRDId, @FUTIRTId, @FUTCURId, @FUTIRCId, @FUTIVXId, @FUTIRFId)  
   
 SELECT    
  trade.CoreTradeId,           
  trade.RefClientId,        
  trade.RefInstrumentId,  
  CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)  
  THEN trade.Quantity * ISNULL(inst.ContractSize, 1)  
  ELSE trade.Quantity END AS Quantity,  
  CASE WHEN inst.RefInstrumentTypeId IN (@OPTCURId, @FUTCURId)  
   THEN trade.Rate * trade.Quantity * ISNULL(inst.ContractSize, 1)  
   ELSE trade.Rate * trade.Quantity END AS tradeTO,  
  rules.RefInstrumentTypeId,  
  trade.RefSegmentId  
 INTO #tradeData  
 FROM dbo.CoreTrade trade  
 INNER JOIN #segments seg ON trade.RefSegmentId = RefSegmentEnumId  
 INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId  
 INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = inst.RefInstrumentTypeId  
 INNER JOIN dbo.RefClient cl ON trade.RefClientId = cl.RefClientId  
 WHERE trade.TradeDate = @RunDateInternal  AND (@IsExcludePro = 0 OR cl.RefClientStatusId <> @ProStatusId)  
  AND (@InExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstituteStatusId)  
  AND NOT EXISTS(SELECT 1 FROM #clientsToExclude clEx  
   WHERE clEx.RefClientId = trade.RefClientId)  
  
 DROP TABLE #clientsToExclude  
  
 SELECT  
  RefClientId,  
  RefInstrumentTypeId,  
  RefInstrumentId,  
  RefSegmentId,  
  COUNT(CoreTradeId) AS TotalExecutedOrders,  
  SUM(Quantity) AS ClientExeSmallOrderQty,  
  SUM(tradeTO) AS ClientExeSmallOrderTO  
 INTO #totalTradeData  
 FROM #tradeData  
 GROUP BY RefClientId, RefInstrumentTypeId, RefInstrumentId, RefSegmentId   
  
 DROP TABLE #tradeData  
   
 SELECT  
  trade.*,  
  (trade.ClientExeSmallOrderTO / trade.ClientExeSmallOrderQty) AS AvgRate  
 INTO #finalTradeData  
 FROM #totalTradeData trade  
 INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = trade.RefInstrumentTypeId  
  AND trade.ClientExeSmallOrderTO <= rules.Threshold  
  
 DROP TABLE #totalTradeData  
  
 SELECT DISTINCT TOP 5 [Date]  
 INTO #selectableDates  
 FROM dbo.CoreBhavCopy  
 WHERE [Date] < @RunDateInternal  
 ORDER BY [Date] DESC  
  
 SELECT  
  trade.RefClientId,  
  trade.RefInstrumentId,  
  bhav.[Date],  
  bhav.[Close]  
 INTO #bhavData  
 FROM #finalTradeData trade  
 INNER JOIN dbo.CoreBhavCopy bhav ON trade.RefInstrumentId = bhav.RefInstrumentId  
 INNER JOIN #selectableDates dates ON bhav.[Date] = dates.[Date]  
  
 DROP TABLE #selectableDates  
  
 SELECT  
  RefClientId,  
  RefInstrumentId,  
  MAX([Date]) AS PreviousDate  
 INTO #previousDates  
 FROM #bhavData  
 GROUP BY RefClientId, RefInstrumentId  
  
 SELECT  
  trade.*,  
  bhav.[Close] AS PreviousClose,  
  CASE WHEN bhav.[Close] IS NULL OR bhav.[Close] = 0  
  THEN 0  
  ELSE ((trade.AvgRate - bhav.[Close]) / bhav.[Close] * 100)   
  END AS AwayFromPreviousClosePerc  
 INTO #finalSmallTradeData  
 FROM #previousDates prev  
 INNER JOIN #bhavData bhav ON prev.RefClientId = bhav.RefClientId  
  AND prev.RefInstrumentId = bhav.RefInstrumentId AND prev.PreviousDate = bhav.[Date]  
 INNER JOIN #finalTradeData trade ON bhav.RefClientId = trade.RefClientId  
  AND bhav.RefInstrumentId = trade.RefInstrumentId  
  
 DROP TABLE #finalTradeData  
 DROP TABLE #bhavData  
 DROP TABLE #previousDates  
  
 SELECT  
  t.* ,
COUNT(t.ClientExeSmallOrderQty) OVER (PARTITION BY RefInstrumentId, RefSegmentId) CRN 
 INTO #topClients  
 FROM (SELECT   
   trade.*,  
   DENSE_RANK() OVER (PARTITION BY trade.RefInstrumentId, trade.RefSegmentId   
    ORDER BY trade.ClientExeSmallOrderQty) AS RN  
  FROM #finalSmallTradeData trade  
  INNER JOIN #scenarioRules rules ON trade.RefInstrumentTypeId = rules.RefInstrumentTypeId  
   AND ABS(trade.AwayFromPreviousClosePerc) >= rules.Threshold3  
 ) t  
 INNER JOIN #scenarioRules rules ON t.RefInstrumentTypeId = rules.RefInstrumentTypeId  
  AND t.RN <= rules.Threshold4  
  
 DROP TABLE #finalSmallTradeData  
  
 SELECT  
  RefInstrumentTypeId,  
  RefInstrumentId,  
  RefSegmentId,  
  SUM(TotalExecutedOrders) AS TotalExecutedOrders,  
  SUM(ClientExeSmallOrderTO) AS TotalExecutedTO  
 INTO #groupData  
 FROM #topClients  
 WHERE @IsGroupGreaterThanOneClient<CRN
 GROUP BY RefInstrumentTypeId, RefInstrumentId, RefSegmentId  
  
 SELECT  
  tcl.RefClientId,  
  cl.ClientId,  
  cl.[Name] AS ClientName,  
  tCl.RefInstrumentId,  
  tCl.RefSegmentId,  
  rules.InstrumentType,  
  trade.TotalExecutedOrders,  
  CONVERT(DECIMAL(28, 2), trade.TotalExecutedTO) AS TotalExecutedTO,  
  CONVERT(INT, tCl.ClientExeSmallOrderQty) AS ClientExeSmallOrderQty,  
  CONVERT(DECIMAL(28, 2), tCl.AvgRate) AS AvgRate,  
  CONVERT(DECIMAL(28, 2), tCl.ClientExeSmallOrderTO) AS ClientExeSmallOrderTO,  
  CONVERT(DECIMAL(28, 2), tCl.PreviousClose) AS PreviousClose,  
  CONVERT(DECIMAL(28, 2), tCl.AwayFromPreviousClosePerc) AS AwayFromPreviousClosePerc  
 INTO #finalData  
 FROM #groupData trade  
 INNER JOIN #scenarioRules rules ON rules.RefInstrumentTypeId = trade.RefInstrumentTypeId  
  AND trade.TotalExecutedTO <= rules.Threshold2  
 INNER JOIN #topClients tCl ON trade.RefInstrumentTypeId = tCl.RefInstrumentTypeId  
  AND tCl.RefInstrumentId = trade.RefInstrumentId AND tCl.RefSegmentId = trade.RefSegmentId  
 INNER JOIN dbo.RefClient cl ON tCl.RefClientId = cl.RefClientId  
  
 DROP TABLE #scenarioRules  
 DROP TABLE #topClients  
 DROP TABLE #groupData  
  
 SELECT  
  fd.RefClientId,  
  fd.ClientId,  
  fd.ClientName,  
  fd.RefInstrumentId,  
  @RunDateInternal AS TradeDate,  
  fd.RefSegmentId,  
  seg.Segment,  
  fd.InstrumentType,  
  inst.[Name] + '-'  + fd.InstrumentType + '-' +           
   CASE WHEN inst.ExpiryDate IS NULL THEN ''  
   ELSE CONVERT(VARCHAR(100), inst.ExpiryDate, 106) END + '-' +   
   ISNULL(inst.PutCall, '') + '-' +   
   ISNULL(CONVERT(VARCHAR(100), inst.StrikePrice), '') AS ScripTypeExpDtPutCallStrikePrice,  
  fd.TotalExecutedOrders,  
  fd.TotalExecutedTO,  
  fd.ClientExeSmallOrderQty,  
  fd.AvgRate,  
  fd.ClientExeSmallOrderTO,  
  fd.PreviousClose,  
  fd.AwayFromPreviousClosePerc,  
  STUFF((SELECT ' ; ' + t.ClientId + '-' + CONVERT(VARCHAR(100), t.ClientExeSmallOrderQty)  
     FROM #finalData t  
     WHERE t.RefInstrumentId = fd.RefInstrumentId AND t.RefSegmentId = fd.RefSegmentId  
      AND t.RefClientId <> fd.RefClientId  
     ORDER BY t.ClientExeSmallOrderQty  
   FOR XML PATH ('')), 1, 3, '') AS [Description]  
 FROM #finalData fd  
 INNER JOIN #segments seg ON fd.RefSegmentId = seg.RefSegmentEnumId  
 INNER JOIN dbo.RefInstrument inst ON fd.RefInstrumentId = inst.RefInstrumentId  
 ORDER BY RefInstrumentId, RefSegmentId, ClientExeSmallOrderQty  
  
END  
GO
------RC-WEB-65063 END
---S161
------RC-WEB-65063 START
GO
ALTER PROCEDURE dbo.AML_GetTradenearCorporateAnnouncementbyGroupOfClientsEQ
(      
 @RunDate DATETIME,      
 @ReportId INT      
)      
AS      
BEGIN      
	DECLARE	@RunDateInternal DATETIME, @ReportIdInternal INT, @BSECashId INT, @NSECashId INT,
			@IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT,  @IsGroupGreaterThanOneClient INT
      
	 SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)      
	 SET @ReportIdInternal = @ReportId      
      
	 SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'      
	 SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH' 

      
	SELECT  * 
	INTO #segments
	FROM dbo.RefSegmentEnum 
	WHERE RefSegmentEnumId IN (@BSECashId,@NSECashId)

	SELECT   
	@IsGroupGreaterThanOneClient = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
	FROM dbo.SysAmlReportSetting   
	WHERE   
	RefAmlReportId = @ReportIdInternal   
	AND [Name] = 'Active_In_Report' 

	SELECT 
		@IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
	FROM dbo.SysAmlReportSetting 
	WHERE 
		RefAmlReportId = @ReportIdInternal 
		AND [Name] = 'Exclude_Pro'
	
	SELECT 
		@IsExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
	FROM dbo.SysAmlReportSetting 
	WHERE 
		RefAmlReportId = @ReportIdInternal 
		AND [Name] = 'Exclude_Institution'
	
	SELECT 
		@ProStatusId = RefClientStatusId 
	FROM dbo.RefClientStatus 
	WHERE [Name] = 'Pro'
	
	
	SELECT 
		@InstituteStatusId = RefClientStatusId
	FROM dbo.RefClientStatus WHERE [Name] = 'Institution'    
       
	 SELECT      
	  RefClientId      
	 INTO #clientsToExclude      
	 FROM dbo.LinkRefAmlReportRefClientAlertExclusion      
	 WHERE RefAmlReportId = @ReportIdInternal      
	  AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)      
      
	 SELECT      
	  rul.Threshold,      
	  rul.Threshold2,      
	  rul.Threshold3,      
	  scrip.[Name] AS ScripGroup,      
	  scrip.RefScripGroupId      
	 INTO #scenarioRules      
	 FROM dbo.RefAmlScenarioRule rul      
	 INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId      
	 INNER JOIN dbo.RefScripGroup scrip ON scrip.RefScripGroupId = link.RefScripGroupId      
	 WHERE RefAmlReportId = @ReportIdInternal      
      
	SELECT    
		annc.ScripCode,      
		annc.RefSegmentId,  
		annc.Announcements  
	INTO #allAnnouncements  
	FROM #segments segment
	INNER JOIN  dbo.CoreCorporateAnnouncement annc  ON segment.refSegmentEnumId  = annc.RefSegmentId AND FileDate = @RunDateInternal
	WHERE   --AND annc.RefSegmentId IN (@BSECashId, @NSECashId)      
	 --AND 
	 ([Subject] IS NULL OR [Subject] <> 'Declaration of NAV')
   
   SELECT DISTINCT annc.ScripCode, annc.RefSegmentId 
	INTO #distinctAnnc
	FROM #allAnnouncements annc

	SELECT DISTINCT inst.RefInstrumentId 
	INTO #instFromAnnoucement
	FROM #distinctAnnc anc      
	INNER JOIN dbo.RefInstrument inst ON inst.Code = anc.ScripCode      
	 AND anc.RefSegmentId = inst.RefSegmentId 
	 

	 --SELECT      
	 -- annc.ScripCode,      
	 -- annc.RefSegmentId,      
	 -- STUFF(    
	 --  (    
		--SELECT DISTINCT ', ' + cca.Announcements    
		--FROM #allAnnouncements cca    
		--WHERE cca.RefSegmentId =annc.RefSegmentId  
		--AND cca.ScripCode = annc.ScripCode   
		--FOR XML PATH ('')    
	 --  ), 1, 1, ''    
	 -- ) AS Announcements      
	 --INTO #annoucements      
	 --FROM #allAnnouncements annc      
	 -- GROUP BY annc.ScripCode, annc.RefSegmentId  
  
	--  DROP TABLE #allAnnouncements  
  
	SELECT     
		 trade.CoreTradeId,      
		 inst.Isin,      
		 inst.GroupName,      
		 inst.RefSegmentId,      
		 inst.RefInstrumentId      
	INTO #tradeIds      
	FROM #segments segment
	INNER JOIN dbo.CoreTrade trade ON segment.RefSegmentEnumId = trade.RefSegmentId AND trade.TradeDate = @RunDateInternal 
	INNER JOIN dbo.RefInstrument inst ON trade.RefInstrumentId = inst.RefInstrumentId
	INNER JOIN #instFromAnnoucement annouceInst ON  annouceInst.RefInstrumentId = trade.RefInstrumentId
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId
	LEFT JOIN  #clientsToExclude clEx  ON clEx.RefClientId = trade.RefClientId
	WHERE clEx.RefClientId IS NULL
	AND (@IsExcludePro = 0 OR cl.RefClientStatusId <> @ProStatusId)
	AND (@IsExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstituteStatusId)

      
	 DROP TABLE #clientsToExclude      
      
	 SELECT DISTINCT      
		 ids.Isin,      
		 --CASE WHEN inst.GroupName IS NOT NULL      
		 --THEN inst.GroupName      
		 --ELSE 'B' END AS GroupName, 
		 ISNULL( inst.GroupName,'B') AS  GroupName,  
		 inst.Code    
	 INTO #allNseGroupData      
	 FROM #tradeIds ids      
	 LEFT JOIN dbo.RefInstrument inst ON inst.RefSegmentId = @BSECashId      
	  AND ids.Isin = inst.Isin  AND inst.[Status]='A'     
	 WHERE ids.RefSegmentId = @NSECashId      
    
    
	 SELECT Isin, 
		COUNT(1) AS rcount    
	 INTO #multipleGroups    
	 FROM #allNseGroupData    
	 GROUP BY Isin    
	 HAVING COUNT(1)>1    
    
	 SELECT t.Isin, t.GroupName     
	 INTO #nseGroupData    
	 FROM     
	 (    
		  SELECT grp.Isin, grp.GroupName     
		  FROM #allNseGroupData grp    
		  WHERE NOT EXISTS    
		  (    
		   SELECT 1 FROM #multipleGroups mg     
		   WHERE mg.Isin=grp.Isin    
		  )    
    
		  UNION    
    
		  SELECT  mg.Isin, grp.GroupName    
		  FROM #multipleGroups mg    
		  INNER JOIN #allNseGroupData grp ON grp.Isin=mg.Isin AND grp.Code like '5%'    
	 )t    
    
	 DROP TABLE #multipleGroups    
	 DROP TABLE #allNseGroupData       
      
	SELECT DISTINCT 
		 trade.CoreTradeId,
		 trade.RefClientId,      
		 ISNULL(bseRules.RefScripGroupId,nseRules.RefScripGroupId) as   RefScripGroupId ,      
		 trade.RefInstrumentId,      
		 CASE WHEN trade.BuySell = 'Buy'      
		 THEN 1 ELSE 0 END AS BuySell,      
		 trade.RefSegmentId,      
		 trade.Quantity,      
		 (trade.Rate * trade.Quantity) AS TurnOver      
	INTO #tradeData      
	FROM #tradeIds ids --ON ids.RefInstrumentId = inst.RefInstrumentId      
	INNER JOIN dbo.CoreTrade trade ON ids.CoreTradeId = trade.CoreTradeId      
	LEFT JOIN #nseGroupData nse ON ids.Isin = nse.Isin AND ids.RefSegmentId=@NSECashId    
	LEFT JOIN #scenarioRules bseRules ON ids.RefSegmentId = @BSECashId AND bseRules.ScripGroup = ids.GroupName
	LEFT JOIN #scenarioRules nseRules ON ids.RefSegmentId = @NSECashId AND nseRules.ScripGroup = nse.GroupName 
    Where bseRules.RefScripGroupId IS NOT NULL OR  nseRules.RefScripGroupId IS NOT NULL

	 DROP TABLE #tradeIds      
	 DROP TABLE #nseGroupData      
      
	 SELECT      
		  RefClientId,      
		  RefScripGroupId,      
		  RefInstrumentId,      
		  RefSegmentId,      
		  SUM(CASE WHEN BuySell = 1      
		   THEN TurnOver ELSE 0 END) AS BuyTO,      
		  SUM(CASE WHEN BuySell = 1      
		   THEN Quantity ELSE 0 END) AS BuyQty,      
		  SUM(CASE WHEN BuySell = 0      
		   THEN TurnOver ELSE 0 END) AS SellTO,      
		  SUM(CASE WHEN BuySell = 0      
		   THEN Quantity ELSE 0 END) AS SellQty,      
		  SUM(TurnOver) AS ClientTO ,
		  DENSE_RANK() OVER (PARTITION BY RefInstrumentId, RefSegmentId ORDER BY SUM(TurnOver) DESC) as RN,
		COUNT(SUM(TurnOver)) OVER (PARTITION BY RefInstrumentId, RefSegmentId) CRN     
	 INTO #BuySellData      
	 FROM #tradeData      
	 GROUP BY RefClientId, RefScripGroupId, RefInstrumentId, RefSegmentId      
      
	DROP TABLE #tradeData      
    
	SELECT   buysell.RefClientId,      
	   buysell.RefScripGroupId,      
	   buysell.RefInstrumentId,      
	   buysell.RefSegmentId,      
	   buysell.BuyTO,      
	   buysell.BuyQty,      
	   buysell.SellTO,      
	   buysell.SellQty,      
	   (buysell.BuyTO + buysell.SellTO) as TotalTO,      
	   buysell.ClientTO ,
	   bhavcopy.NetTurnOver as ExchangeTO,
	   bhavcopy.NumberOfShares as ExchangeQty
	INTO #exchangeData
	FROM #BuySellData buysell
	INNER JOIN #scenarioRules rules ON rules.RefScripGroupId = buysell.RefScripGroupId AND buysell.RN<=rules.Threshold3 AND @IsGroupGreaterThanOneClient<buysell.CRN 
	INNER JOIN CoreBhavCopy bhavcopy ON bhavcopy.RefInstrumentId = buysell.RefInstrumentId 
		AND bhavcopy.RefSegmentId = buysell.RefSegmentId  AND bhavcopy.[Date] = @RunDateInternal


      
	 DROP TABLE #BuySellData      
    SELECT  t.* 
	INTO #GroupData 
	FROM (
		SELECT      
			  exchange.RefScripGroupId,      
			  exchange.RefInstrumentId,      
			  exchange.RefSegmentId,      
			  SUM(exchange.BuyTO) AS BuyTO,      
			  SUM(exchange.BuyQty) AS BuyQty,      
			  SUM(exchange.SellTO) AS SellTO,      
			  SUM(exchange.SellQty) AS SellQty,      
			  SUM(exchange.TotalTO) AS TotalTO      
		     
		 FROM #exchangeData exchange      
		 GROUP BY exchange.RefScripGroupId, exchange.RefInstrumentId, exchange.RefSegmentId      
      ) t
	  INNER JOIN #scenarioRules rules ON rules.RefScripGroupId  =  t.RefScripGroupId AND t.TotalTO >= rules.Threshold

	 SELECT      
	  exchange.RefClientId,      
	  client.ClientId,      
	  client.[Name] AS ClientName,      
	  exchange.RefScripGroupId,      
	  exchange.RefInstrumentId,      
	  exchange.RefSegmentId,      
	  gd.BuyTO,      
	  gd.BuyQty,      
	  CASE WHEN ISNULL(gd.BuyQty,0) <> 0 THEN (ISNULL(gd.BuyTO,0) / gd.BuyQty)      
	  ELSE 0 END AS BuyAvgRate,      
	  gd.SellTO,      
	  gd.SellQty,      
	  CASE WHEN ISNULL(gd.SellQty,0)<> 0 THEN (ISNULL(gd.SellTO,0) / gd.SellQty)       
	  ELSE 0 END AS SellAvgRate,      
	  exchange.ClientTO,      
	  gd.TotalTO,      
	  CASE WHEN exchange.ExchangeTO<>0 THEN ((gd.TotalTO*100)/exchange.ExchangeTO )       
	  ELSE 0 END AS ScripPercent,      
	  exchange.ExchangeTO,      
	  exchange.ExchangeQty      
	 INTO #FinalData      
	 FROM #GroupData gd
	 INNER JOIN #exchangeData exchange ON exchange.RefInstrumentId = gd.RefInstrumentId AND exchange.RefScripGroupId = gd.RefScripGroupId      
			AND exchange.RefSegmentId = gd.RefSegmentId   
	 INNER JOIN #scenarioRules rules ON rules.RefScripGroupId = exchange.RefScripGroupId  
	 INNER JOIN dbo.RefClient client ON client.RefClientId = exchange.RefClientId        
     WHERE (CASE WHEN exchange.ExchangeTO<>0 THEN ((gd.TotalTO*100)/exchange.ExchangeTO ) ELSE 0 END )>= rules.Threshold2    

	 DROP TABLE #exchangeData      
      
	 SELECT      
	  fd.RefClientId,      
	  fd.ClientId,      
	  fd.ClientName,      
	  fd.RefInstrumentId,      
	  fd.RefSegmentId AS SegmentId,      
	  @RunDateInternal AS TradeDate,      
	  segment.Code AS Segment,      
	  scrip.[Name] AS GroupName,      
	  inst.[Code] AS ScripCode,      
	  inst.[Name] as ScripName,      
	  fd.BuyQty,      
	  fd.BuyAvgRate,      
	  fd.BuyTO,      
	  fd.SellQty,      
	  fd.SellAvgRate,      
	  fd.SellTO,      
	  fd.TotalTO,      
	  fd.ScripPercent as GroupScripPercentage,      
	  fd.ExchangeTO,      
	  fd.ExchangeQty,      
	  fd.ClientTO,      
	  STUFF((    
			SELECT DISTINCT ', ' + cca.Announcements    
			FROM #allAnnouncements cca    
			WHERE cca.RefSegmentId =inst.RefSegmentId  
			AND cca.ScripCode = inst.Code
			FOR XML PATH ('')    
		  ), 1, 1, '') AS  CorporateAnnoucement,      
	  STUFF(      
	   (      
		SELECT ' ; ' + tfd.ClientId + '-' +CONVERT(VARCHAR, CONVERT(DECIMAL(28, 2),tfd.ClientTO))      
		FROM #finalData tfd      
		WHERE tfd.RefInstrumentId = fd.RefInstrumentId      
		AND tfd.RefSegmentId = fd.RefSegmentId      
		AND tfd.RefScripGroupId= fd.RefScripGroupId      
		AND tfd.RefClientId <> fd.RefClientId      
		ORDER BY tfd.ClientTO DESC      
		FOR XML PATH ('')      
	   ), 1, 3, ''      
	  ) AS DescriptionClient      
	 FROM #FinalData fd      
	 INNER JOIN RefSegmentEnum segment  ON fd.RefSegmentId = segment.RefSegmentEnumId         
	 INNER JOIN dbo.RefInstrument inst  ON inst.RefInstrumentId = fd.RefInstrumentId      
	 INNER JOIN dbo.RefScripGroup scrip ON scrip.RefScripGroupId = fd.RefScripGroupId       
END   
GO
------RC-WEB-65063 END
---S162
------RC-WEB-65063 START
GO
ALTER PROCEDURE dbo.AML_GetHighTurnoverbyGroupofClientsin1DayinSpecificScripEQ
(
	@RunDate DATETIME,
	@ReportId INT
)
AS
BEGIN
	DECLARE @RunDateInternal DATETIME, @ReportIdInternal INT, @BSECashId INT,
			@NSECashId INT, @InstrumentRefEntityTypeId INT, @EntityAttributeTypeRefEnumValueId INT,
			@IsExcludePro INT, @IsExcludeInstitution INT, @ProStatusId INT, @InstituteStatusId INT,
			@IsGroupGreaterThanOneClient INT

	SET @RunDateInternal = dbo.GetDateWithoutTime(@RunDate)
	SET @ReportIdInternal = @ReportId
	SELECT @BSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'BSE_CASH'
	SELECT @NSECashId = RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Code = 'NSE_CASH'
	SELECT @InstrumentRefEntityTypeId = RefEntityTypeId FROM dbo.RefEntityType WHERE Code = 'Instrument'
	SET @EntityAttributeTypeRefEnumValueId = dbo.GetEnumValueId('EntityAttributeType', 'UserDefined')

	SELECT   
	@IsGroupGreaterThanOneClient = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END  
	FROM dbo.SysAmlReportSetting   
	WHERE   
	RefAmlReportId = @ReportIdInternal   
	AND [Name] = 'Active_In_Report' 

	SELECT 
		@IsExcludePro = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
	FROM dbo.SysAmlReportSetting 
	WHERE 
		RefAmlReportId = @ReportIdInternal 
		AND [Name] = 'Exclude_Pro'
	
	SELECT 
		@IsExcludeInstitution = CASE WHEN [Value] = 'True' THEN 1 ELSE 0 END
	FROM dbo.SysAmlReportSetting 
	WHERE 
		RefAmlReportId = @ReportIdInternal 
		AND [Name] = 'Exclude_Institution'
	
	SELECT 
		@ProStatusId = RefClientStatusId 
	FROM dbo.RefClientStatus 
	WHERE [Name] = 'Pro'
	
	
	SELECT 
		@InstituteStatusId = RefClientStatusId
	FROM dbo.RefClientStatus WHERE [Name] = 'Institution'

	SELECT
		RefClientId
	INTO #clientsToExclude
	FROM dbo.LinkRefAmlReportRefClientAlertExclusion
	WHERE RefAmlReportId = @ReportIdInternal
		AND @RunDateInternal >= FromDate AND (ToDate IS NULL OR ToDate >= @RunDateInternal)

	SELECT
		rul.Threshold,
		rul.Threshold2,
		rul.Threshold3,
		rul.Threshold4,
		scrip.[Name] AS ScripGroup,
		scrip.RefScripGroupId,
		attrDetail.ForEntityId AS RefInstrumentId
	INTO #scenarioRules
	FROM dbo.RefAmlScenarioRule rul
	INNER JOIN dbo.LinkRefAmlScenarioRuleRefScripGroup link ON link.RefAmlScenarioRuleId = rul.RefAmlScenarioRuleId
	INNER JOIN dbo.RefScripGroup scrip ON scrip.RefScripGroupId = link.RefScripGroupId
	INNER JOIN dbo.CoreEntityAttributeValue attrVal ON attrVal.UserDefinedValueName = scrip.[Name]	
	INNER JOIN dbo.RefEntityAttribute attr ON attr.RefEntityAttributeId = attrVal.RefEntityAttributeId
	INNER JOIN dbo.CoreEntityAttributeDetail attrDetail ON attrDetail.RefEntityAttributeId = attr.RefEntityAttributeId 
		AND attrDetail.CoreEntityAttributeValueId = attrVal.CoreEntityAttributeValueId
	WHERE RefAmlReportId = @ReportIdInternal AND attr.ForRefEntityTypeId = @InstrumentRefEntityTypeId
		AND attr.EntityAttributeTypeRefEnumValueId = @EntityAttributeTypeRefEnumValueId
		AND attr.Code IN ('TW01','TW02')
		AND (attrDetail.EndDate IS NULL OR attrDetail.EndDate > @RunDateInternal)

	SELECT 
		trade.RefClientId,
		trade.RefInstrumentId,
		CASE WHEN trade.BuySell = 'Buy'
			THEN 1
			ELSE 0 END BuySell,
		trade.Rate,
		trade.Quantity,
		(trade.Rate * trade.Quantity) AS tradeTO,
		rules.RefScripGroupId,
		trade.RefSegmentId
	INTO #tradeData
	FROM dbo.CoreTrade trade
	LEFT JOIN #clientsToExclude clEx ON clEx.RefClientId = trade.RefClientId
	INNER JOIN #scenarioRules rules ON rules.RefInstrumentId = trade.RefInstrumentId
	INNER JOIN dbo.RefClient cl ON cl.RefClientId = trade.RefClientId
	WHERE trade.TradeDate = @RunDateInternal 
	AND trade.RefSegmentId IN (@BSECashId, @NSECashId)
	AND (@IsExcludePro = 0 OR cl.RefClientStatusId <> @ProStatusId)
	AND (@IsExcludeInstitution = 0 OR cl.RefClientStatusId <> @InstituteStatusId)
	AND clEx.RefClientId IS NULL

	DROP TABLE #clientsToExclude

	SELECT
		RefClientId,
		RefScripGroupId,
		RefInstrumentId,
		RefSegmentId,
		BuySell,
		SUM(tradeTO) AS ClientTO,
		SUM(Quantity) AS ClientQT
	INTO #clientTOs
	FROM #tradeData
	GROUP BY RefClientId, RefScripGroupId, RefInstrumentId, RefSegmentId, BuySell

	DROP TABLE #tradeData

	SELECT
		t.RefInstrumentId,
		t.RefSegmentId,
		t.BuySell,
		t.RefScripGroupId,
		t.RefClientId,
		t.ClientTO,
		t.ClientQT,
		COUNT(t.RefClientId) OVER (PARTITION BY t.RefInstrumentId, t.RefSegmentId, t.BuySell) CRN
	INTO #topClients
	FROM (SELECT 
			RefInstrumentId,
			RefSegmentId,
			BuySell,
			RefScripGroupId,
			RefClientId,
			ClientTO,
			ClientQT,
			DENSE_RANK() OVER (PARTITION BY RefInstrumentId, RefSegmentId, BuySell ORDER BY ClientTO DESC) AS RN
		FROM #clientTOs
	) t
	INNER JOIN #scenarioRules rules ON t.RefScripGroupId = rules.RefScripGroupId
		AND rules.RefInstrumentId = t.RefInstrumentId
	WHERE t.RN <= rules.Threshold3  

	DROP TABLE #clientTOs

	SELECT
		RefScripGroupId,
		RefInstrumentId, 
		RefSegmentId, 
		BuySell,
		SUM(ClientTO) AS GroupTO
	INTO #groupedSum
	FROM #topClients
	WHERE  @IsGroupGreaterThanOneClient<CRN
	GROUP BY RefScripGroupId, RefInstrumentId, RefSegmentId, BuySell

	SELECT
		grp.RefScripGroupId,
		grp.RefInstrumentId,
		grp.BuySell,
		grp.RefSegmentId,
		grp.GroupTO,
		bhav.NetTurnOver AS ExchangeTO,
		(grp.GroupTO * 100 / bhav.NetTurnOver) AS GroupContributedPerc
	INTO #selectedScrips
	FROM #groupedSum grp
	INNER JOIN dbo.CoreBhavCopy bhav ON grp.RefInstrumentId = bhav.RefInstrumentId
	INNER JOIN #scenarioRules rules ON rules.RefScripGroupId = grp.RefScripGroupId
		AND rules.RefInstrumentId = grp.RefInstrumentId
	WHERE bhav.[Date] = @RunDateInternal AND grp.GroupTO >= rules.Threshold2
		AND (grp.GroupTO * 100 / bhav.NetTurnOver) >= rules.Threshold

	DROP TABLE #groupedSum

	SELECT DISTINCT
		cl.RefClientId,
		client.ClientId,
		client.[Name] AS ClientName,
		seg.Segment,
		rules.ScripGroup AS ScripGroupNames,
		instru.Code AS ScripCode,
		instru.[Name] AS ScripName,
		scrips.GroupTO,
		scrips.GroupContributedPerc,
		scrips.ExchangeTO,
		cl.ClientQT AS ClientTradedQty,
		(cl.ClientTO / cl.ClientQT) AS AvgRate,
		cl.ClientTO,
		(cl.ClientTO * 100 / scrips.ExchangeTO) AS ClientPerc,
		(cl.ClientTO * 100 / scrips.GroupTO) AS GroupSharePerc,
		rules.RefScripGroupId,
		scrips.RefInstrumentId,
		scrips.RefSegmentId,
		scrips.BuySell
	INTO #finalData
	FROM #selectedScrips scrips
	INNER JOIN #topClients cl ON scrips.RefInstrumentId = cl.RefInstrumentId 
		AND scrips.RefSegmentId = cl.RefSegmentId AND scrips.BuySell = cl.BuySell
	INNER JOIN dbo.RefClient client ON cl.RefClientId = client.RefClientId
	INNER JOIN dbo.RefSegmentEnum seg ON scrips.RefSegmentId = seg.RefSegmentEnumId
	INNER JOIN #scenarioRules rules ON scrips.RefScripGroupId = rules.RefScripGroupId
		AND rules.RefInstrumentId = scrips.RefInstrumentId
	INNER JOIN dbo.RefInstrument instru ON scrips.RefInstrumentId = instru.RefInstrumentId

	DROP TABLE #topClients
	DROP TABLE #selectedScrips

	SELECT
		final.RefClientId,
		final.ClientId,
		final.ClientName,
		final.RefInstrumentId,
		final.RefSegmentId,
		final.Segment,
		@RunDateInternal AS TransactionDate,
		final.ScripGroupNames,
		CASE WHEN final.BuySell = 1
			THEN 'Buy'
			ELSE 'Sell' END AS BuySell,
		final.ScripCode,
		final.ScripName,
		CONVERT(DECIMAL(28, 2), final.GroupTO) AS GroupTO,
		CONVERT(DECIMAL(28, 2), final.GroupContributedPerc) AS GroupContributedPerc,
		CONVERT(DECIMAL(28, 2), final.ExchangeTO) AS ExchangeTO,
		CONVERT(INT, final.ClientTradedQty) AS ClientTradedQty,
		CONVERT(DECIMAL(28, 2), final.AvgRate) AS AvgRate,
		CONVERT(DECIMAL(28, 2), final.ClientTO) AS ClientTO,
		CONVERT(DECIMAL(28, 2), final.ClientPerc) AS ClientPerc,
		CONVERT(DECIMAL(28, 2), final.GroupSharePerc) AS GroupSharePerc,
		STUFF((SELECT ' ; ' + t.ClientId + '-' + CONVERT(VARCHAR(100), CONVERT(DECIMAL(28, 2), t.ClientPerc)) + '%'
					FROM #finalData t
					WHERE t.RefInstrumentId = final.RefInstrumentId AND t.RefSegmentId = final.RefSegmentId
						AND t.BuySell = final.BuySell AND t.RefScripGroupId = final.RefScripGroupId
						AND t.RefClientId <> final.RefClientId
					ORDER BY t.ClientPerc DESC
			FOR XML PATH ('')), 1, 3, '') AS DescriptionClientPerc,
		final.RefInstrumentId
	FROM #finalData final
	INNER JOIN #scenarioRules rules ON final.RefScripGroupId = rules.RefScripGroupId
		AND rules.RefInstrumentId = final.RefInstrumentId
	WHERE final.GroupSharePerc >= rules.Threshold4
	ORDER BY final.RefInstrumentId, final.RefSegmentId, final.BuySell, final.ClientPerc DESC

END
GO
------RC-WEB-65063 END
