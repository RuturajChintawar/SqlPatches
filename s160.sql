
GO
 CREATE PROCEDURE dbo.CoreCorporateAnnouncement_GetCountForDateRangeAndSegment (  
 
 @FromDate DATETIME = '04-19-2022',  
 @ToDate DATETIME ='04-19-2022',  
 @SegmentCodes VARCHAR(MAX)  ='BSE_CASH'
)  
AS  
BEGIN  
 DECLARE @FromDateInternal DATETIME, @ToDateInternal DATETIME  
  
 SET @FromDateInternal = dbo.GetDateWithoutTime(@FromDate)  
 SET @ToDateInternal =  CONVERT(DATETIME, DATEDIFF(dd, 0, @ToDate)) + CONVERT(DATETIME, '23:59:59.000')  
  
 SELECT  
  t.items AS SegmentCode  
 INTO #SegmentCodes  
 FROM dbo.Split(@SegmentCodes, ',') AS t  
  
 SELECT   
  codes.SegmentCode,  
  COUNT(corporate.CoreCorporateAnnouncementId) AS Trades  
 FROM #SegmentCodes codes  
 INNER JOIN dbo.RefSegmentEnum seg ON codes.SegmentCode = seg.Code  
 INNER JOIN dbo.CoreCorporateAnnouncement corporate ON seg.RefSegmentEnumId = corporate.RefSegmentId  
 WHERE corporate.FileDate BETWEEN @FromDateInternal AND @ToDateInternal  
 GROUP BY codes.SegmentCode  
  
END  
GO