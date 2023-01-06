table Name CoreAlert

SELECT ,* FROM CoreAlert 

sELECT * FROM RefamlReport where code ='s601'
Select * from RefalertType

Select distinct cj.Segment from CoreAlert c
inner join refsegmentenum cj on cj.RefSegmentEnumId = c.RefSegmentId



select distinct RefAlertTypeId from CoreAlert order by RefAlertTypeId
SELECT Refamltypeid from Corealert where BuySell is not null
Total Buy Qty	13,34,36
Buy Avg Rate	
Buy TO 	
Total Sell Qty	13,34,36
Sell Avg Rate	
Sell TO	
Total TO
select * from 
ClientTurnoverInLakh 26
select * from Refalerttype where Refalerttypeid in (13,34,36)

if tradedate null
scenario wise seg or alert wise seg

select * from 
Corealert
where RefalertTypeId=13

GO
 create PROCEDURE dbo.CoreTrade_GetAdditionalDataForR56  
(  
 @RefClientId INT,    
 @RefSegmentId INT,
 @TradeDate DATETIME
)  
AS  
BEGIN  
   
   
  SELECT   
   trade.RefClientId,  
   trade.TradeDate,  
   trade.RefSegmentId,  
   SUM(CASE WHEN trade.BuySell = 'Buy' THEN trade.Quantity ELSE 0 END) AS BuyQty,  
   CASE WHEN trade.BuySell = 'Buy' THEN SUM(trade.Rate * trade.Quantity) / SUM(trade.Quantity)END AS BuyPrice,  
   SUM(CASE WHEN trade.BuySell = 'Sell' THEN trade.Quantity ELSE 0 END) AS SellQty,  
   CASE WHEN trade.BuySell = 'Sell' THEN SUM(trade.Rate * trade.Quantity) / SUM(trade.Quantity)END AS SellPrice
  INTO #Trade  
  FROM dbo.CoreTrade trade  
  WHERE trade.TradeDate = @TradeDate AND trade.RefSegmentId = @RefSegmentId AND trade.RefClientId = @RefSegmentId
  GROUP BY   
   trade.RefClientId,    
   trade.TradeDate,
   trade.RefSegmentId,
   trade.BuySell  
  
END  
GO
Refintermidiary
select Quantity,rate,CtclId,TradeDate,AddedOn,* from CoreTrade where RefClientId=6976012 and refsegmentid=2