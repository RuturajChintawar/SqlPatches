--web-68181-RC-start
GO
ALTER Procedure [dbo].[LinkRefClientRefBankMicr_InsertFromStaging]  
(  
	@guid Varchar(5000)
)  
AS   
BEGIN  
DECLARE @guidInternal Varchar(5000)  
SET @guidInternal=@guid  
  
CREATE TABLE #LinkRefClientRefBankMicrFinal  
(  
 RefclientId INT,  
 LinkRefClientRefBankMicrId INT,  
 RefBankMicrId INT,  
 RefBankAccountTypeId INT,  
 BankAccNo VARCHAR(200) COLLATE DATABASE_DEFAULT,  
 PMS INT,  
 POA INT,  
 AddedBy VARCHAR(50),  
 AddedOn DATETIME  
)  
INSERT INTO #LinkRefClientRefBankMicrFinal  
(  
 RefclientId,  
 LinkRefClientRefBankMicrId,  
 RefBankMicrId,  
 RefBankAccountTypeId,  
 BankAccNo,  
 PMS,  
 POA,  
 AddedBy,  
 AddedOn  
)  
select   
client.RefClientId,  
linkBankMicr.LinkRefClientRefBankMicrId,  
BankMicr.RefBankMicrId,  
bankAcctType.RefBankAccountTypeId,  
stg.ClientBankBankAccountNo as BankAccNo,  
0 as PMS,  
0 as POA,  
stg.AddedBy,  
stg.AddedOn  
--into #LinkRefClientRefBankMicrFinal  
from StagingClientRefresh stg  
inner join dbo.RefClient client on client.ClientId=stg.ClientId and client.RefClientDatabaseEnumId=stg.RefClientDatabaseEnumId and ISNULL(client.DpId,0)=ISNULL(stg.DpId,0)  
Inner join RefBankMicr BankMicr on ISNULL(Bankmicr.IfscCode,'')=ISNULL(stg.ClientBankIfscCode,'') AND BankMicr.MicrNo=stg.ClientBankMicrNo  
Inner join RefBankAccountType bankAcctType on bankAcctType.Code=stg.ClientBankAccountType  
left join LinkRefClientRefBankMicr linkBankMicr on  linkBankMicr.RefClientId=client.RefClientId AND  stg.ClientBankBankAccountNo=linkBankMicr.BankAccNo
where stg.GUID is not null and stg.GUID=@guidInternal  

UPDATE link
SET link.RefBankMicrId=stg.RefBankMicrId,
link.RefBankAccountTypeId=stg.RefBankAccountTypeId
FROM dbo.LinkRefClientRefBankMicr link
INNER JOIN #LinkRefClientRefBankMicrFinal stg ON link.RefClientId=stg.RefClientId  AND stg.BankAccNo=link.BankAccNo
WHERE (link.RefBankMicrId<>stg.RefBankMicrId OR link.RefBankAccountTypeId <> stg.RefBankAccountTypeId)
  
INSERT INTO dbo.LinkRefClientRefBankMicr  
(  
RefClientId,  
RefBankMicrId,  
RefBankAccountTypeId,  
BankAccNo,  
POA,  
PMS,  
AddedBy,  
AddedOn,  
LastEditedBy,  
EditedOn  
)  
select   
temp.RefClientId,  
temp.RefBankMicrId,  
temp.RefBankAccountTypeId,  
temp.BankAccNo,  
temp.POA,  
temp.PMS,  
temp.AddedBy,  
temp.AddedOn,  
temp.AddedBy,  
temp.AddedOn  
from #LinkRefClientRefBankMicrFinal  temp  
where temp.LinkRefClientRefBankMicrId is null  
and not exists (select 1 from LinkRefClientRefBankMicr bank  
where temp.RefClientId = bank.RefClientId  
and bank.RefBankMicrId=temp.RefBankMicrId  
and bank.RefBankAccountTypeId=temp.RefBankAccountTypeId  
and temp.BankAccNo=bank.BankAccNo) 

End
GO
--web-68181-RC-end