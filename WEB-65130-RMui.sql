-----RC-WEB-65130-start
GO
CREATE PROCEDURE [dbo].[CoreScrenningRMDetailHistory_GetCustomerRMDetailsByCustomerId]  
(   @CustomerId VARCHAR(MAX),
	@EntityTypeCode VARCHAR(100) 
)  
AS  
BEGIN  
	DECLARE @CustomerIdInternal VARCHAR(MAX),@EntityTypeCodeInternal VARCHAR(100),@RefEntityTypeId INT
	SET @CustomerIdInternal = @CustomerId 
	
	SET @EntityTypeCodeInternal = @EntityTypeCode 
	SET  @RefEntityTypeId = dbo.GetEntityTypeByCode(@EntityTypeCodeInternal)
	
	SELECT DISTINCT CONVERT(INT,s.items) AS RefCRMCustomerId      
	INTO #caseCustomerIds          
	FROM dbo.Split(@CustomerIdInternal,',') s          
	
	SELECT
	ISNULL(employeeRm.[Name],'') AS RelationshipManagerName,
	ISNULL(val.[Name],'') AS RelationshipManagerType,
	ISNULL(custRm.FromDate,'') AS FromDate
	FROM #caseCustomerIds cust
	INNER JOIN dbo.CoreScreeningCase cas ON cas.RecordEntityId=cust.RefCRMCustomerId AND cas.RecordRefEntityTypeId=@RefEntityTypeId
	INNER JOIN dbo.CoreScreeningRequestHistory hist ON cas.RecordEntityId=hist.RecordEntityId
	INNER JOIN dbo.CoreScrenningRMDetailHistory custRm ON custRm.CoreScreeningRequestHistoryId=hist.CoreScreeningRequestHistoryId
	INNER JOIN dbo.RefEmployee employeeRm on employeeRm.RefEmployeeId = custRm.UserCodeRefEmployeeId
	INNER JOIN dbo.RefEnumValue val ON val.RefEnumValueId=custRm.CustomerRMTypeRefEnumValueId
END
GO
-----RC-WEB-65130-end
