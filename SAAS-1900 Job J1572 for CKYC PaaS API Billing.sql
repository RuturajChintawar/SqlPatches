GO
CREATE PROCEDURE dbo.GetJ1572CkycBilling
	(
		@FromDate DATETIME,
		@ToDate DATETIME,
		@StatusEnumType1 VARCHAR(MAX),
		@StatusEnumType2 VARCHAR(MAX),
		@StatusEnumType3 VARCHAR(MAX) = NULL,
		@ApiCode VARCHAR(MAX)
	)
	AS
	BEGIN

 
	DECLARE @FromDateInternal DATETIME, @ToDateInternal DATETIME, @StatusRefEnumTypeId INT, @ApiCodeInternal VARCHAR(MAX), @StatusEnumType1Internal VARCHAR(MAX),
		@StatusEnumType2Internal VARCHAR(MAX)

	SET @FromDateInternal = @FromDate
	SET @ToDateInternal  = @ToDate
	SET @ApiCodeInternal = @ApiCode
	SET @StatusEnumType1Internal = @StatusEnumType1
	SET @StatusEnumType2Internal = @StatusEnumType2


	SELECT t.s ApiCode 
	INTO #tempApiCodes
	FROM dbo.ParseString(@ApiCode,',') t

	SELECT @StatusRefEnumTypeId = RefEnumTypeId FROM dbo.RefEnumType WHERE [Name] = 'ApiRequestStatus'

	CREATE TABLE #tempStringData(
		CompanyCode VARCHAR(100) COLLATE DATABASE_DEFAULT,
		EnumValueCode  VARCHAR(2000) COLLATE DATABASE_DEFAULT
	);

	WITH expression_CTE AS(

		SELECT t.s Exps
			 ,ROW_NUMBER() OVER( ORDER BY (SELECT NULL)) AS RN 
		FROM dbo.ParseString(@StatusEnumType1Internal,':') t
	)
	SELECT [1] AS companyCode ,[2] AS enumCode 
	INTO #splitExpression
	FROM expression_CTE
	PIVOT(  
	   MAX(Exps)  
	   FOR RN IN([1],[2])    
	  ) AS PVT; 

	INSERT INTO #tempStringData (
			CompanyCode,
			EnumValueCode
	 )
	SELECT
		com.s AS companyCode,
		enum.s AS enumCode
	FROM #splitExpression ex
	CROSS APPLY dbo.ParseString(ex.companyCode,',') com
	CROSS APPLY dbo.ParseString(ex.enumCode,',') enum

	WITH expression_CTE AS(

		SELECT t.s Exps
			 ,ROW_NUMBER() OVER( ORDER BY (SELECT NULL)) AS RN 
		FROM dbo.ParseString(@StatusEnumType2Internal,':') t
	)
	SELECT [1] AS companyCode ,[2] AS enumCode 
	INTO #splitExpression2
	FROM expression_CTE
	PIVOT(  
	   MAX(Exps)  
	   FOR RN IN([1],[2])    
	  ) AS PVT;
	INSERT INTO #tempStringData (
			CompanyCode,
			EnumValueCode
	 )
	SELECT
		com.s AS companyCode,
		enum.s AS enumCode
	FROM #splitExpression2 ex
	CROSS APPLY dbo.ParseString(ex.companyCode,',') com
	CROSS APPLY dbo.ParseString(ex.enumCode,',') enum

	SELECT
		ref.RefParentCompanyId,
		ref.[Name] CompanyName,
		val.RefEnumValueId
	INTO #expressionData
	FROM #tempStringData ex
	INNER JOIN dbo.RefParentCompany ref ON ex.CompanyCode = ref.UniqueId
	INNER JOIN dbo.RefEnumValue val ON val.Code = ex.EnumValueCode AND val.RefEnumTypeId = @StatusRefEnumTypeId

	SELECT  
		hits.TrackWizzRequestId,
		ex.CompanyName,
		hits.SearchDate,
		hits.SysApiCode ApiCode,
		ex.RefParentCompanyId
	FROM API.CKYCSearchLog hits
	INNER JOIN #tempApiCodes api ON hits.SysApiCode = api.ApiCode
	INNER JOIN #expressionData ex ON ex.RefEnumValueId = hits.RequestStatusRefEnumValueId AND hits.RefParentCompanyId = ex.RefParentCompanyId
	WHERE hits.SearchDate BETWEEN @FromDateInternal AND @ToDateInternal

  END
GO
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              