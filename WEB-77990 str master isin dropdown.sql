--RC -END WEB-71986
GO
 ALTER PROCEDURE [dbo].[RefInstrument_GetStrTransactionInstruments]   
(    
	@segmentId INT
)    
AS    
BEGIN    

	DECLARE @nsdlId INT,
	@InternalSegmentId INT
	SET @InternalSegmentId = @segmentId
	SELECT @nsdlId = ref.RefSegmentEnumId FROM dbo.RefsegmentEnum ref WHERE ref.Code ='NSDL'
	IF(EXISTS(SELECT 1 FROM dbo.RefsegmentEnum ref WHERE ref.Code IN ('CDSL','NSDL') AND ref.RefSegmentEnumId = @InternalSegmentId ))
		BEGIN
		  SELECT 
		  ref.RefIsinId AS RefInstrumentId,
		  ref.IsinNumericCode AS [Code],
		  ref.[Name] AS [Name],
		  ref.[Name] AS Isin,
		  '' AS ScripId
		  FROM dbo.RefIsin ref
		  WHERE ref.RefSegmentId = @InternalSegmentId AND (@InternalSegmentId = @nsdlId OR ref.ISINStatus IS NULL OR ref.ISINStatus = 'A')
		END
	ELSE
		BEGIN
		  SELECT 
		  ref.RefInstrumentId AS RefInstrumentId,
		  ref.[Name] AS [Name],
		  ref.Code AS [Code],
		  ref.Isin AS [Isin],
		  ref.ScripId
		  FROM dbo.RefInstrument ref
		  WHERE ref.RefSegmentId = @InternalSegmentId AND (ref.[Status] ='A' OR ref.[Status] IS NULL)
		END
END   
GO
--RC -END WEB-71986
