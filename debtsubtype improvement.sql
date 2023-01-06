GO
 CREATE PROCEDURE dbo.GetCustomerTypeFromClientId  
(  
 @ClientId BIGINT 
)  
AS  
BEGIN  
DECLARE @clientEntityTypeId INT , @INDEnumValueId INT,@NonINDEnumValueId INT
SET @clientEntityTypeId = dbo.GetEntityTypeByCode('Client')
SET @INDEnumValueId = dbo.GetEnumValueId('CustomerTypeCategory','Ind')
SET @NonINDEnumValueId = dbo.GetEnumValueId('CustomerTypeCategory','Non Ind')
 
 SELECT
 rel.RelatedPartyRefCRMCustomerId
 ,* FROM
 dbo.CoreCRMRelatedParty rel
 INNER JOIN dbo.RefCRMCustomer core ON rel.EntityId = @ClientId AND rel.RefEntityTypeId = @clientEntityTypeId AND core.RefCRMCustomerId = rel.RelatedPartyRefCRMCustomerId
 INNER JOIN dbo.RefCustomerType ty ON ty.RefCustomerTypeId = core.RefCustomerTypeId

END 
GO 