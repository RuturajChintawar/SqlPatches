
--RC-START-WEB=58818
GO
ALTER procedure [dbo].[RefClient_RiskProfiliing]  
(  
@lowRiskPan Varchar(MAX)=NULL  
)  
AS
BEGIN

DECLARE
@ActiveCdsl INT, @ClosedCdsl INT,@InActiveCdsl INT,@ClosedNsdl INT,@ActiveNsdl INT,@ActiveTrading INT,@InActiveTrading INT,@NRISpecialCategoryId INT

SELECT @ActiveCdsl = sta.RefClientAccountStatusId FROM dbo.RefClientAccountStatus sta INNER JOIN dbo.RefClientDatabaseEnum dat ON dat.DatabaseType='CDSL' AND  sta.[NAME]='Active' AND dat.RefClientDatabaseEnumId=sta.RefClientDatabaseEnumId   
SELECT @ClosedCdsl = sta.RefClientAccountStatusId FROM dbo.RefClientAccountStatus sta INNER JOIN dbo.RefClientDatabaseEnum dat ON dat.DatabaseType='CDSL' AND  sta.[NAME]='Closed' AND dat.RefClientDatabaseEnumId=sta.RefClientDatabaseEnumId   
SELECT @InActiveCdsl = sta.RefClientAccountStatusId FROM dbo.RefClientAccountStatus sta INNER JOIN dbo.RefClientDatabaseEnum dat ON dat.DatabaseType='CDSL' AND  sta.[NAME]='InActive' AND dat.RefClientDatabaseEnumId=sta.RefClientDatabaseEnumId   

SELECT @ActiveNsdl = sta.RefClientAccountStatusId FROM dbo.RefClientAccountStatus sta INNER JOIN dbo.RefClientDatabaseEnum dat ON dat.DatabaseType='NSDL' AND  sta.[NAME]='Active' AND dat.RefClientDatabaseEnumId=sta.RefClientDatabaseEnumId   
SELECT @ClosedNsdl = sta.RefClientAccountStatusId FROM dbo.RefClientAccountStatus sta INNER JOIN dbo.RefClientDatabaseEnum dat ON dat.DatabaseType='NSDL' AND  sta.[NAME]='Closed' AND dat.RefClientDatabaseEnumId=sta.RefClientDatabaseEnumId   

SELECT @ActiveTrading = sta.RefClientAccountStatusId FROM dbo.RefClientAccountStatus sta INNER JOIN dbo.RefClientDatabaseEnum dat ON dat.DatabaseType='Trading' AND  sta.[NAME]='Active' AND dat.RefClientDatabaseEnumId=sta.RefClientDatabaseEnumId   
SELECT @InActiveTrading = sta.RefClientAccountStatusId FROM dbo.RefClientAccountStatus sta INNER JOIN dbo.RefClientDatabaseEnum dat ON dat.DatabaseType='Trading' AND  sta.[NAME]='InActive' AND dat.RefClientDatabaseEnumId=sta.RefClientDatabaseEnumId   

SELECT @NRISpecialCategoryId = ref.RefClientSpecialCategoryId FROM dbo.RefClientSpecialCategory ref WHERE ref.Code='TW01' AND ref.[Name]='NRI' AND ref.RefEntityTypeId = dbo.GetEntityTypeByCode('Client')

SELECT items  
INTO #AML_High_Risk_SpecialCategory  
FROM [dbo].[Split]((  
   SELECT Value  
   FROM dbo.SysConfig  
   WHERE NAME = 'AML_High_Risk_SpecialCategory'  
   ), '|')  
  
Select items , 'Low' as Risk  
INTO #lowRiskPAN  
FROM [dbo].[Split](@lowRiskPan, ',')  
  
SELECT client.RefClientId  
 ,client.ClientId  
 ,clientdatabase.DatabaseType  
 ,client.RefClientDatabaseEnumId AS ClientDatabaseId  
 ,client.PAN AS Pan  
 ,clientcurrentrisk.NAME AS CurrentRisk  
 ,Currentrisk.LinkRefClientRefRiskCategoryId AS ClientCurrentRiskId  
 ,CASE WHEN lowrisk.Risk='Low' THEN lowrisk.Risk ELSE 'High' END AS NewRisk  
 ,'Client Special Category is : ' + clientspecialcategory.NAME AS Note  
INTO #SpecialCategory  
FROM dbo.RefClient client  
INNER JOIN [dbo].RefClientStatus clientstatus ON clientstatus.RefClientStatusId = client.RefClientStatusId  
INNER JOIN dbo.RefClientDatabaseEnum clientdatabase ON clientdatabase.RefClientDatabaseEnumId = client.RefClientDatabaseEnumId  
INNER JOIN dbo.RefClientSpecialCategory csc ON csc.RefClientSpecialCategoryId = client.RefClientSpecialCategoryId  
INNER JOIN #AML_High_Risk_SpecialCategory ON #AML_High_Risk_SpecialCategory.items = csc.NAME  
LEFT JOIN [dbo].[LinkRefClientRefRiskCategoryLatest] Currentrisk ON client.RefClientId = Currentrisk.RefClientId  
 AND ISNULL(Currentrisk.ToDate, '31-Dec-9999') >= GETDATE()  
LEFT JOIN dbo.RefRiskCategory clientcurrentrisk ON clientcurrentrisk.RefRiskCategoryId = Currentrisk.RefRiskCategoryId  
LEFT JOIN dbo.RefClientSpecialCategory clientspecialcategory ON clientspecialcategory.RefClientSpecialCategoryId = client.RefClientSpecialCategoryId  
LEFT JOIN #lowRiskPAN lowrisk ON lowrisk.items=client.PAN  
WHERE clientdatabase.databasetype IN (  
'Trading'    
  ,'CDSL'  
  ,'NSDL'  
  ,'Commodity'  
  ,'Commodities'  
  ,'Currency'  
  )  
--AND clientstatus.NAME <> 'Institution'  
 AND ISNULL(client.AccountClosingDate, '31-Dec-9999') >= GETDATE()  
 AND (  
  clientcurrentrisk.NAME IS NULL  
  OR clientcurrentrisk.NAME = 'Low'  
  OR clientcurrentrisk.NAME = 'Medium'  
  )  
  and (Currentrisk.FromDate is null or Currentrisk.FromDate<>DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))  
  AND client.ExcludeHighRiskMarking != 1  
  AND (clientspecialcategory.RefClientSpecialCategoryId <> @NRISpecialCategoryId OR  ISNULL(client.RefClientAccountStatusId  ,0) NOT IN (@ActiveCdsl , @ClosedCdsl ,@InActiveCdsl,@ClosedNsdl ,@ActiveNsdl ,@ActiveTrading ,@InActiveTrading ))
  
UPDATE link  
SET link.ToDate = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(DD, - 1, GETDATE())))  
 ,AuroUpdateRiskMarking = getdate()  
 ,link.FromDate = CASE   
  WHEN link.FromDate IS NULL  
   THEN CASE   
     WHEN cl.AccountOpeningDate IS NULL  
      THEN '01-01-1900'  
     ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, cl.AccountOpeningDate))  
     END  
  ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, link.FromDate))  
  END  
FROM dbo.LinkRefClientRefRiskCategory link  
INNER JOIN #SpecialCategory TEMP ON link.LinkRefClientRefRiskCategoryId = TEMP.ClientCurrentRiskId  
INNER JOIN dbo.RefClient cl ON TEMP.RefClientId = cl.RefClientId  
WHERE TEMP.ClientCurrentRiskId IS NOT NULL  
  
INSERT INTO dbo.LinkRefClientRefRiskCategory (  
 RefClientId  
 ,RefRiskCategoryId  
 ,FromDate  
 ,AddedBy  
 ,AddedOn  
 ,LastEditedBy  
 ,EditedOn  
 ,Notes  
 ,AuroRiskMarking  
 )  
SELECT TEMP.RefClientId  
 ,risk.RefRiskCategoryId  
 ,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))  
 ,'System'  
 ,GETDATE()  
 ,'System'  
 ,GETDATE()  
 ,TEMP.Note  
 ,GETDATE()  
FROM #SpecialCategory TEMP  
INNER JOIN RefRiskCategory risk ON risk.NAME = TEMP.NewRisk  
  
  
SELECT items  
INTO #AML_High_Risk_Marking_Base_ON_Constituition_Type  
FROM [dbo].[Split]((  
   SELECT Value  
   FROM dbo.SysConfig  
   WHERE NAME = 'AML_High_Risk_Marking_Base_ON_Constituition_Type'  
   ), '|')  
  
SELECT client.RefClientId  
 ,client.ClientId  
 ,clientdatabase.DatabaseType  
 ,client.RefClientDatabaseEnumId AS ClientDatabaseId  
 ,client.PAN AS Pan  
 ,clientcurrentrisk.NAME AS CurrentRisk  
 ,Currentrisk.LinkRefClientRefRiskCategoryId AS ClientCurrentRiskId  
 ,CASE WHEN lowrisk.Risk='Low' THEN lowrisk.Risk ELSE 'High' END AS NewRisk  
 ,'Client High Risk Marking Base ON Constituition Type  : ' + clientconstitutiontype.NAME AS Note  
INTO #HighRiskMarkingConstituitionType  
FROM dbo.RefClient client  
INNER JOIN [dbo].RefClientStatus clientstatus ON clientstatus.RefClientStatusId = client.RefClientStatusId  
INNER JOIN dbo.RefClientDatabaseEnum clientdatabase ON clientdatabase.RefClientDatabaseEnumId = client.RefClientDatabaseEnumId  
INNER JOIN dbo.RefConstitutionType clientconstitutiontype ON clientconstitutiontype.RefConstitutionTypeId = client.RefConstitutionTypeId  
INNER JOIN #AML_High_Risk_Marking_Base_ON_Constituition_Type clienthighriskconstitutiontype ON clienthighriskconstitutiontype.items = clientconstitutiontype.Code  
LEFT JOIN [dbo].[LinkRefClientRefRiskCategoryLatest] Currentrisk ON client.RefClientId = Currentrisk.RefClientId  
 AND ISNULL(Currentrisk.ToDate, '31-Dec-9999') >= GETDATE()  
LEFT JOIN dbo.RefRiskCategory clientcurrentrisk ON clientcurrentrisk.RefRiskCategoryId = Currentrisk.RefRiskCategoryId  
LEFT JOIN RefClientSpecialCategory clientspecialcategory ON clientspecialcategory.RefClientSpecialCategoryId = client.RefClientSpecialCategoryId  
LEFT JOIN #lowRiskPAN lowrisk ON lowrisk.items=client.PAN  
WHERE clientdatabase.databasetype IN (  
'Trading'    
  ,'CDSL'  
  ,'NSDL'  
  ,'Commodity'  
  ,'Commodities'  
  ,'Currency'  
  )  
--AND clientstatus.NAME <> 'Institution'  
 AND ISNULL(client.AccountClosingDate, '31-Dec-9999') >= GETDATE()  
 AND client.RefConstitutionTypeId IS NOT NULL  
 AND (  
  clientcurrentrisk.NAME IS NULL  
  OR clientcurrentrisk.NAME = 'Low'  
  OR clientcurrentrisk.NAME = 'Medium'  
  )  
  and (Currentrisk.FromDate is null or Currentrisk.FromDate<>DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))  
  AND client.ExcludeHighRiskMarking != 1  
  
UPDATE link  
SET link.ToDate = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(DD, - 1, GETDATE())))  
 ,AuroUpdateRiskMarking = getdate()  
 ,link.FromDate = CASE   
  WHEN link.FromDate IS NULL  
   THEN CASE   
     WHEN cl.AccountOpeningDate IS NULL  
      THEN '01-01-1900'  
     ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, cl.AccountOpeningDate))  
     END  
  ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, link.FromDate))  
  END  
FROM dbo.LinkRefClientRefRiskCategory link  
INNER JOIN #HighRiskMarkingConstituitionType TEMP ON link.LinkRefClientRefRiskCategoryId = TEMP.ClientCurrentRiskId  
INNER JOIN dbo.RefClient cl ON TEMP.RefClientId = cl.RefClientId  
WHERE TEMP.ClientCurrentRiskId IS NOT NULL  
  
INSERT INTO dbo.LinkRefClientRefRiskCategory (  
 RefClientId  
 ,RefRiskCategoryId  
 ,FromDate  
 ,AddedBy  
 ,AddedOn  
 ,LastEditedBy  
 ,EditedOn  
 ,Notes  
 ,AuroRiskMarking  
 )  
SELECT TEMP.RefClientId  
 ,risk.RefRiskCategoryId  
 ,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))  
 ,'System'  
 ,GETDATE()  
 ,'System'  
 ,GETDATE()  
 ,TEMP.Note  
 ,GETDATE()  
FROM #HighRiskMarkingConstituitionType TEMP  
INNER JOIN RefRiskCategory risk ON risk.NAME = TEMP.NewRisk  
  
  
SELECT items  
INTO #AML_High_Risk_Occupation_Codes  
FROM [dbo].[Split]((  
   SELECT Value  
   FROM dbo.SysConfig  
   WHERE NAME = 'AML_High_Risk_Occupation_Codes'  
   ), '|')  
  
SELECT client.RefClientId  
 ,client.ClientId  
 ,clientdatabase.DatabaseType  
 ,client.RefClientDatabaseEnumId AS ClientDatabaseId  
 ,client.PAN AS Pan  
 ,clientcurrentrisk.NAME AS CurrentRisk  
 ,Currentrisk.LinkRefClientRefRiskCategoryId AS ClientCurrentRiskId  
 ,CASE WHEN lowrisk.Risk='Low' THEN lowrisk.Risk ELSE 'High' END AS NewRisk  
 ,'Client High Risk Occupation is : ' + clientoccupation.NAME AS Note  
INTO #HighRiskOccupation  
FROM dbo.RefClient client  
INNER JOIN [dbo].RefClientStatus clientstatus ON clientstatus.RefClientStatusId = client.RefClientStatusId  
INNER JOIN dbo.RefClientDatabaseEnum clientdatabase ON clientdatabase.RefClientDatabaseEnumId = client.RefClientDatabaseEnumId  
INNER JOIN dbo.RefBseMfOccupationType clientoccupation ON clientoccupation.RefBseMfOccupationTypeId = client.RefBseMfOccupationTypeId  
INNER JOIN #AML_High_Risk_Occupation_Codes clienthighriskoccupation ON clienthighriskoccupation.items = clientoccupation.Code  
LEFT JOIN [dbo].[LinkRefClientRefRiskCategoryLatest] Currentrisk ON client.RefClientId = Currentrisk.RefClientId  
 AND ISNULL(Currentrisk.ToDate, '31-Dec-9999') >= GETDATE()  
LEFT JOIN dbo.RefRiskCategory clientcurrentrisk ON clientcurrentrisk.RefRiskCategoryId = Currentrisk.RefRiskCategoryId  
LEFT JOIN RefClientSpecialCategory clientspecialcategory ON clientspecialcategory.RefClientSpecialCategoryId = client.RefClientSpecialCategoryId  
LEFT JOIN #lowRiskPAN lowrisk ON lowrisk.items=client.PAN  
WHERE clientdatabase.databasetype IN (  
'Trading'    
  ,'CDSL'  
  ,'NSDL'  
  ,'Commodity'  
  ,'Commodities'  
  ,'Currency'  
  )  
--AND clientstatus.NAME <> 'Institution'  
 AND ISNULL(client.AccountClosingDate, '31-Dec-9999') >= GETDATE()  
 AND client.RefBseMfOccupationTypeId IS NOT NULL  
 AND (  
  clientcurrentrisk.NAME IS NULL  
  OR clientcurrentrisk.NAME = 'Low'  
  OR clientcurrentrisk.NAME = 'Medium'  
  )  
  and (Currentrisk.FromDate is null or Currentrisk.FromDate<>DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))  
  AND client.ExcludeHighRiskMarking != 1  
  
UPDATE link  
SET link.ToDate = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(DD, - 1, GETDATE())))  
 ,AuroUpdateRiskMarking = getdate()  
 ,link.FromDate = CASE   
  WHEN link.FromDate IS NULL  
   THEN CASE   
     WHEN cl.AccountOpeningDate IS NULL  
      THEN '01-01-1900'  
     ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, cl.AccountOpeningDate))  
     END  
  ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, link.FromDate))  
  END  
FROM dbo.LinkRefClientRefRiskCategory link  
INNER JOIN #HighRiskOccupation TEMP ON link.LinkRefClientRefRiskCategoryId = TEMP.ClientCurrentRiskId  
INNER JOIN dbo.RefClient cl ON TEMP.RefClientId = cl.RefClientId  
WHERE TEMP.ClientCurrentRiskId IS NOT NULL  
  
INSERT INTO dbo.LinkRefClientRefRiskCategory (  
 RefClientId  
 ,RefRiskCategoryId  
 ,FromDate  
 ,AddedBy  
 ,AddedOn  
 ,LastEditedBy  
 ,EditedOn  
 ,Notes  
 ,AuroRiskMarking  
 )  
SELECT TEMP.RefClientId  
 ,risk.RefRiskCategoryId  
 ,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))  
 ,'System'  
 ,GETDATE()  
 ,'System'  
 ,GETDATE()  
 ,TEMP.Note  
 ,GETDATE()  
FROM #HighRiskOccupation TEMP  
INNER JOIN RefRiskCategory risk ON risk.NAME = TEMP.NewRisk  
  
  
  
SELECT items  
INTO #AML_Medium_Risk_SpecialCategory  
FROM [dbo].[Split]((  
   SELECT Value  
   FROM dbo.SysConfig  
   WHERE NAME = 'AML_Medium_Risk_SpecialCategory'  
   ), '|')  
  
SELECT client.RefClientId  
 ,client.ClientId  
 ,clientdatabase.DatabaseType  
 ,client.RefClientDatabaseEnumId AS ClientDatabaseId  
 ,client.PAN AS Pan  
 ,clientcurrentrisk.NAME AS CurrentRisk  
 ,Currentrisk.LinkRefClientRefRiskCategoryId AS ClientCurrentRiskId  
 ,CASE WHEN lowrisk.Risk='Low' THEN lowrisk.Risk ELSE 'Medium' END AS NewRisk  
 ,'Client Special Category is : ' + clientspecialcategory.NAME AS Note  
INTO #SpecialCategoryMedium  
FROM dbo.RefClient client  
INNER JOIN [dbo].RefClientStatus clientstatus ON clientstatus.RefClientStatusId = client.RefClientStatusId  
INNER JOIN dbo.RefClientDatabaseEnum clientdatabase ON clientdatabase.RefClientDatabaseEnumId = client.RefClientDatabaseEnumId  
INNER JOIN dbo.RefClientSpecialCategory csc ON csc.RefClientSpecialCategoryId = client.RefClientSpecialCategoryId  
INNER JOIN #AML_Medium_Risk_SpecialCategory ON #AML_Medium_Risk_SpecialCategory.items = csc.NAME  
LEFT JOIN [dbo].[LinkRefClientRefRiskCategoryLatest] Currentrisk ON client.RefClientId = Currentrisk.RefClientId  
 AND ISNULL(Currentrisk.ToDate, '31-Dec-9999') >= GETDATE()  
LEFT JOIN dbo.RefRiskCategory clientcurrentrisk ON clientcurrentrisk.RefRiskCategoryId = Currentrisk.RefRiskCategoryId  
LEFT JOIN RefClientSpecialCategory clientspecialcategory ON clientspecialcategory.RefClientSpecialCategoryId = client.RefClientSpecialCategoryId  
LEFT JOIN #lowRiskPAN lowrisk ON lowrisk.items=client.PAN  
WHERE clientdatabase.databasetype IN (  
'Trading'    
  ,'CDSL'  
  ,'NSDL'  
  ,'Commodity',  
'Commodities'    
  ,'Currency'  
  )  
--AND clientstatus.NAME <> 'Institution'  
 AND ISNULL(client.AccountClosingDate, '31-Dec-9999') >= GETDATE()  
 AND (  
  clientcurrentrisk.NAME IS NULL  
  OR clientcurrentrisk.NAME = 'Low'  
  )  
  and (Currentrisk.FromDate is null or Currentrisk.FromDate<>DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))  
  AND client.ExcludeHighRiskMarking != 1  
  
UPDATE link  
SET link.ToDate = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(DD, - 1, GETDATE())))  
 ,AuroUpdateRiskMarking = getdate()  
 ,link.FromDate = CASE   
  WHEN link.FromDate IS NULL  
   THEN CASE   
     WHEN cl.AccountOpeningDate IS NULL  
      THEN '01-01-1900'  
     ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, cl.AccountOpeningDate))  
     END  
  ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, link.FromDate))  
  END  
FROM dbo.LinkRefClientRefRiskCategory link  
INNER JOIN #SpecialCategoryMedium TEMP ON link.LinkRefClientRefRiskCategoryId = TEMP.ClientCurrentRiskId  
INNER JOIN dbo.RefClient cl ON TEMP.RefClientId = cl.RefClientId  
WHERE TEMP.ClientCurrentRiskId IS NOT NULL  
  
INSERT INTO dbo.LinkRefClientRefRiskCategory (  
 RefClientId  
 ,RefRiskCategoryId  
 ,FromDate  
 ,AddedBy  
 ,AddedOn  
 ,LastEditedBy  
 ,EditedOn  
 ,Notes  
 ,AuroRiskMarking  
 )  
SELECT TEMP.RefClientId  
 ,risk.RefRiskCategoryId  
 ,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))  
 ,'System'  
 ,GETDATE()  
 ,'System'  
 ,GETDATE()  
 ,TEMP.Note  
 ,GETDATE()  
FROM #SpecialCategoryMedium TEMP  
INNER JOIN RefRiskCategory risk ON risk.NAME = TEMP.NewRisk  
  
  
  
SELECT items  
INTO #AML_Medium_Risk_Marking_Base_ON_Constituition_Type  
FROM [dbo].[Split]((  
   SELECT Value  
   FROM dbo.SysConfig  
   WHERE NAME = 'AML_Medium_Risk_Marking_Base_ON_Constituition_Type'  
   ), '|')  
  
SELECT client.RefClientId  
 ,client.ClientId  
 ,clientdatabase.DatabaseType  
 ,client.RefClientDatabaseEnumId AS ClientDatabaseId  
 ,client.PAN AS Pan  
 ,clientcurrentrisk.NAME AS CurrentRisk  
 ,Currentrisk.LinkRefClientRefRiskCategoryId AS ClientCurrentRiskId  
 ,CASE WHEN lowrisk.Risk='Low' THEN lowrisk.Risk ELSE 'Medium' END AS NewRisk  
 ,'Client Medium Risk Marking Base ON Constituition Type  : ' + clientconstitutiontype.NAME AS Note  
INTO #MediumRiskMarkingConstituition  
FROM dbo.RefClient client  
INNER JOIN [dbo].RefClientStatus clientstatus ON clientstatus.RefClientStatusId = client.RefClientStatusId  
INNER JOIN dbo.RefClientDatabaseEnum clientdatabase ON clientdatabase.RefClientDatabaseEnumId = client.RefClientDatabaseEnumId  
INNER JOIN dbo.RefConstitutionType clientconstitutiontype ON clientconstitutiontype.RefConstitutionTypeId = client.RefConstitutionTypeId  
INNER JOIN #AML_Medium_Risk_Marking_Base_ON_Constituition_Type clientmediumriskconstitutiontype ON clientmediumriskconstitutiontype.items = clientconstitutiontype.Code  
LEFT JOIN [dbo].[LinkRefClientRefRiskCategoryLatest] Currentrisk ON client.RefClientId = Currentrisk.RefClientId  
 AND ISNULL(Currentrisk.ToDate, '31-Dec-9999') >= GETDATE()  
LEFT JOIN dbo.RefRiskCategory clientcurrentrisk ON clientcurrentrisk.RefRiskCategoryId = Currentrisk.RefRiskCategoryId  
LEFT JOIN RefClientSpecialCategory clientspecialcategory ON clientspecialcategory.RefClientSpecialCategoryId = client.RefClientSpecialCategoryId  
LEFT JOIN #lowRiskPAN lowrisk ON lowrisk.items=client.PAN  
WHERE clientdatabase.databasetype IN (  
'Trading'    
  ,'CDSL'  
  ,'NSDL'  
  ,'Commodity'  
  ,'Commodities'  
  ,'Currency'  
  )  
--AND clientstatus.NAME <> 'Institution'  
 AND ISNULL(client.AccountClosingDate, '31-Dec-9999') >= GETDATE()  
 AND client.RefConstitutionTypeId IS NOT NULL  
 AND (  
  clientcurrentrisk.NAME IS NULL  
  OR clientcurrentrisk.NAME = 'Low'  
  )  
  and (Currentrisk.FromDate is null or Currentrisk.FromDate<>DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))  
  AND client.ExcludeHighRiskMarking != 1  
  
UPDATE link  
SET link.ToDate = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(DD, - 1, GETDATE())))  
 ,AuroUpdateRiskMarking = getdate()  
 ,link.FromDate = CASE   
  WHEN link.FromDate IS NULL  
   THEN CASE   
     WHEN cl.AccountOpeningDate IS NULL  
      THEN '01-01-1900'  
     ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, cl.AccountOpeningDate))  
     END  
  ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, link.FromDate))  
  END  
FROM dbo.LinkRefClientRefRiskCategory link  
INNER JOIN #MediumRiskMarkingConstituition TEMP ON link.LinkRefClientRefRiskCategoryId = TEMP.ClientCurrentRiskId  
INNER JOIN dbo.RefClient cl ON TEMP.RefClientId = cl.RefClientId  
WHERE TEMP.ClientCurrentRiskId IS NOT NULL  
  
INSERT INTO dbo.LinkRefClientRefRiskCategory (  
 RefClientId  
 ,RefRiskCategoryId  
 ,FromDate  
 ,AddedBy  
 ,AddedOn  
 ,LastEditedBy  
 ,EditedOn  
 ,Notes  
 ,AuroRiskMarking  
 )  
SELECT TEMP.RefClientId  
 ,risk.RefRiskCategoryId  
 ,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))  
 ,'System'  
 ,GETDATE()  
 ,'System'  
 ,GETDATE()  
 ,TEMP.Note  
 ,GETDATE()  
FROM #MediumRiskMarkingConstituition TEMP  
INNER JOIN RefRiskCategory risk ON risk.NAME = TEMP.NewRisk  
  
  
  
SELECT items  
INTO #AML_Medium_Risk_Occupation_Codes  
FROM [dbo].[Split]((  
   SELECT Value  
   FROM dbo.SysConfig  
   WHERE NAME = 'AML_Medium_Risk_Occupation_Codes'  
   ), '|')  
  
SELECT client.RefClientId  
 ,client.ClientId  
 ,clientdatabase.DatabaseType  
 ,client.RefClientDatabaseEnumId AS ClientDatabaseId  
 ,client.PAN AS Pan  
 ,clientcurrentrisk.NAME AS CurrentRisk  
 ,Currentrisk.LinkRefClientRefRiskCategoryId AS ClientCurrentRiskId  
 ,CASE WHEN lowrisk.Risk='Low' THEN lowrisk.Risk ELSE 'Medium' END AS NewRisk  
 ,'Client Medium Risk Occupation is : ' + clientoccupation.NAME AS Note  
INTO #MediumRiskOccupation  
FROM dbo.RefClient client  
INNER JOIN [dbo].RefClientStatus clientstatus ON clientstatus.RefClientStatusId = client.RefClientStatusId  
INNER JOIN dbo.RefClientDatabaseEnum clientdatabase ON clientdatabase.RefClientDatabaseEnumId = client.RefClientDatabaseEnumId  
INNER JOIN dbo.RefBseMfOccupationType clientoccupation ON clientoccupation.RefBseMfOccupationTypeId = client.RefBseMfOccupationTypeId  
INNER JOIN #AML_Medium_Risk_Occupation_Codes clientmediumriskoccupation ON clientmediumriskoccupation.items = clientoccupation.Code  
LEFT JOIN [dbo].[LinkRefClientRefRiskCategoryLatest] Currentrisk ON client.RefClientId = Currentrisk.RefClientId  
 AND ISNULL(Currentrisk.ToDate, '31-Dec-9999') >= GETDATE()  
LEFT JOIN dbo.RefRiskCategory clientcurrentrisk ON clientcurrentrisk.RefRiskCategoryId = Currentrisk.RefRiskCategoryId  
LEFT JOIN RefClientSpecialCategory clientspecialcategory ON clientspecialcategory.RefClientSpecialCategoryId = client.RefClientSpecialCategoryId  
LEFT JOIN #lowRiskPAN lowrisk ON lowrisk.items=client.PAN  
WHERE clientdatabase.databasetype IN (  
'Trading'    
  ,'CDSL'  
  ,'NSDL'  
  ,'Commodity'  
  ,'Commodities'  
  ,'Currency'  
  )  
--AND clientstatus.NAME <> 'Institution'  
 AND ISNULL(client.AccountClosingDate, '31-Dec-9999') >= GETDATE()  
 AND client.RefBseMfOccupationTypeId IS NOT NULL  
 AND (  
  clientcurrentrisk.NAME IS NULL  
  OR clientcurrentrisk.NAME = 'Low'  
  )  
  and (Currentrisk.FromDate is null or Currentrisk.FromDate<>DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))  
  AND client.ExcludeHighRiskMarking != 1  
  
UPDATE link  
SET link.ToDate = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(DD, - 1, GETDATE())))  
 ,AuroUpdateRiskMarking = getdate()  
 ,link.FromDate = CASE   
  WHEN link.FromDate IS NULL  
   THEN CASE   
     WHEN cl.AccountOpeningDate IS NULL  
      THEN '01-01-1900'  
     ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, cl.AccountOpeningDate))  
     END  
  ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, link.FromDate))  
  END  
FROM dbo.LinkRefClientRefRiskCategory link  
INNER JOIN #MediumRiskOccupation TEMP ON link.LinkRefClientRefRiskCategoryId = TEMP.ClientCurrentRiskId  
INNER JOIN dbo.RefClient cl ON TEMP.RefClientId = cl.RefClientId  
WHERE TEMP.ClientCurrentRiskId IS NOT NULL  
  
INSERT INTO dbo.LinkRefClientRefRiskCategory (  
 RefClientId  
 ,RefRiskCategoryId  
 ,FromDate  
 ,AddedBy  
 ,AddedOn  
 ,LastEditedBy  
 ,EditedOn  
 ,Notes  
 ,AuroRiskMarking  
 )  
SELECT TEMP.RefClientId  
 ,risk.RefRiskCategoryId  
 ,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))  
 ,'System'  
 ,GETDATE()  
 ,'System'  
 ,GETDATE()  
 ,TEMP.Note  
 ,GETDATE()  
FROM #MediumRiskOccupation TEMP  
INNER JOIN RefRiskCategory risk ON risk.NAME = TEMP.NewRisk  
  
  
  
DECLARE @ProcessId INT  
  SELECT @ProcessId=RefProcessId FROM dbo.RefProcess WHERE Name='J36 Risk Profiling';  
  
  
SELECT items  
INTO #AML_Medium_Risk_Income_Category  
FROM [dbo].[Split]((  
   SELECT Value  
   FROM dbo.RefProcessSetting  
   WHERE Code = 'AML_Medium_Risk_Income_Category' AND RefProcessId = @ProcessId  
   ), '|')  
  
SELECT client.RefClientId  
 ,client.ClientId  
 ,clientdatabase.DatabaseType  
 ,client.RefClientDatabaseEnumId AS ClientDatabaseId  
 ,client.PAN AS Pan  
 ,clientcurrentrisk.NAME AS CurrentRisk  
 ,Currentrisk.LinkRefClientRefRiskCategoryId AS ClientCurrentRiskId  
 ,CASE WHEN lowrisk.Risk='Low' THEN lowrisk.Risk ELSE 'Medium' END AS NewRisk  
 ,'Income Category is : ' + clientspecialcategory.NAME AS Note  
INTO #IncomeCategory  
FROM dbo.RefClient client  
INNER JOIN [dbo].RefClientStatus clientstatus ON clientstatus.RefClientStatusId = client.RefClientStatusId  
INNER JOIN dbo.RefClientDatabaseEnum clientdatabase ON clientdatabase.RefClientDatabaseEnumId = client.RefClientDatabaseEnumId  
INNER JOIN dbo.LinkRefClientRefIncomeGroupLatest lnk ON lnk.RefClientId = client.RefClientId  
INNER JOIN dbo.RefIncomeGroup grp ON grp.RefIncomeGroupId = lnk.RefIncomeGroupId  
INNER JOIN #AML_Medium_Risk_Income_Category ON #AML_Medium_Risk_Income_Category.items = grp.Name  
LEFT JOIN [dbo].[LinkRefClientRefRiskCategoryLatest] Currentrisk ON client.RefClientId = Currentrisk.RefClientId  
 AND ISNULL(Currentrisk.ToDate, '31-Dec-9999') >= GETDATE()  
LEFT JOIN dbo.RefRiskCategory clientcurrentrisk ON clientcurrentrisk.RefRiskCategoryId = Currentrisk.RefRiskCategoryId  
LEFT JOIN RefClientSpecialCategory clientspecialcategory ON clientspecialcategory.RefClientSpecialCategoryId = client.RefClientSpecialCategoryId  
LEFT JOIN #lowRiskPAN lowrisk ON lowrisk.items=client.PAN  
WHERE clientdatabase.databasetype IN (  
'Trading'    
  ,'CDSL'  
  ,'NSDL'  
  ,'Commodity'  
  ,'Commodities'  
  ,'Currency'  
  )  
--AND clientstatus.NAME <> 'Institution'  
 AND ISNULL(client.AccountClosingDate, '31-Dec-9999') >= GETDATE()  
 AND (  
  clientcurrentrisk.NAME IS NULL  
  OR clientcurrentrisk.NAME = 'Low'  
  OR clientcurrentrisk.NAME = 'Medium'  
  )  
  and (Currentrisk.FromDate is null or Currentrisk.FromDate<>DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))  
  AND client.ExcludeHighRiskMarking != 1  
  
UPDATE link  
SET link.ToDate = DATEADD(dd, 0, DATEDIFF(dd, 0, DATEADD(DD, - 1, GETDATE())))  
 ,AuroUpdateRiskMarking = getdate()  
 ,link.FromDate = CASE   
  WHEN link.FromDate IS NULL  
   THEN CASE   
     WHEN cl.AccountOpeningDate IS NULL  
      THEN '01-01-1900'  
     ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, cl.AccountOpeningDate))  
     END  
  ELSE DATEADD(dd, 0, DATEDIFF(dd, 0, link.FromDate))  
  END  
FROM dbo.LinkRefClientRefRiskCategory link  
INNER JOIN #IncomeCategory TEMP ON link.LinkRefClientRefRiskCategoryId = TEMP.ClientCurrentRiskId  
INNER JOIN dbo.RefClient cl ON TEMP.RefClientId = cl.RefClientId  
WHERE TEMP.ClientCurrentRiskId IS NOT NULL  
  
INSERT INTO dbo.LinkRefClientRefRiskCategory (  
 RefClientId  
 ,RefRiskCategoryId  
 ,FromDate  
 ,AddedBy  
 ,AddedOn  
 ,LastEditedBy  
 ,EditedOn  
 ,Notes  
 ,AuroRiskMarking  
 )  
SELECT TEMP.RefClientId  
 ,risk.RefRiskCategoryId  
 ,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))  
 ,'System'  
 ,GETDATE()  
 ,'System'  
 ,GETDATE()  
 ,TEMP.Note  
 ,GETDATE()  
FROM #IncomeCategory TEMP  
INNER JOIN RefRiskCategory risk ON risk.NAME = TEMP.NewRisk  
  
  
SELECT client.RefClientId  
 ,client.ClientId  
 ,clientdatabase.DatabaseType  
 ,client.RefClientDatabaseEnumId AS ClientDatabaseId  
 ,client.PAN AS Pan  
 ,clientcurrentrisk.NAME AS CurrentRisk  
 ,Currentrisk.LinkRefClientRefRiskCategoryId AS ClientCurrentRiskId  
 ,'Low' AS NewRisk  
 ,'Default Risk Marked from J36' AS Note  
INTO #DefaultRisk  
FROM dbo.RefClient client  
INNER JOIN [dbo].RefClientStatus clientstatus ON clientstatus.RefClientStatusId = client.RefClientStatusId  
INNER JOIN dbo.RefClientDatabaseEnum clientdatabase ON clientdatabase.RefClientDatabaseEnumId = client.RefClientDatabaseEnumId  
LEFT JOIN [dbo].[LinkRefClientRefRiskCategoryLatest] Currentrisk ON client.RefClientId = Currentrisk.RefClientId  
 AND ISNULL(Currentrisk.ToDate, '31-Dec-9999') >= GETDATE()  
LEFT JOIN dbo.RefRiskCategory clientcurrentrisk ON clientcurrentrisk.RefRiskCategoryId = Currentrisk.RefRiskCategoryId  
WHERE clientdatabase.databasetype IN (  
'Trading'    
  ,'CDSL'  
  ,'NSDL'  
  ,'Commodity'  
  ,'Commodities'  
  ,'Currency'  
  )  
--AND clientstatus.NAME <> 'Institution'  
 AND ISNULL(client.AccountClosingDate, '31-Dec-9999') >= GETDATE()  
 AND clientcurrentrisk.NAME IS NULL  
 and (Currentrisk.FromDate is null or Currentrisk.FromDate<>DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))  
 AND client.ExcludeHighRiskMarking != 1  
  
INSERT INTO dbo.LinkRefClientRefRiskCategory (  
 RefClientId  
 ,RefRiskCategoryId  
 ,FromDate  
 ,AddedBy  
 ,AddedOn  
 ,LastEditedBy  
 ,EditedOn  
 ,Notes  
 ,AuroRiskMarking  
 )  
SELECT TEMP.RefClientId  
 ,risk.RefRiskCategoryId  
 ,DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))  
 ,'System'  
 ,GETDATE()  
 ,'System'  
 ,GETDATE()  
 ,TEMP.Note  
 ,GETDATE()  
FROM #DefaultRisk TEMP  
INNER JOIN RefRiskCategory risk ON risk.NAME = TEMP.NewRisk  
  
  
  
SELECT link.LinkRefClientRefRiskCategoryId  
 ,client.AccountOpeningDate  
INTO #clientriskwhichhavefromdatenull  
FROM dbo.RefClient client  
INNER JOIN dbo.LinkRefClientRefRiskCategoryLatest link   
ON client.RefClientId = link.RefClientId  
WHERE link.FromDate IS NULL  
 AND client.AccountOpeningDate IS NOT NULL  
 and Not exists  
 (  
 select 1 from dbo.LinkRefClientRefRiskCategory riskall   
 where riskall.RefClientId=link.RefClientId and riskall.FromDate=DATEADD(dd, 0, DATEDIFF(dd, 0, client.AccountOpeningDate))  
 )  
  
UPDATE dbo.LinkRefClientRefRiskCategory  
SET FromDate = DATEADD(dd, 0, DATEDIFF(dd, 0, client.AccountOpeningDate)),  
LastEditedBy='System',EditedOn=GETDATE()  
FROM dbo.LinkRefClientRefRiskCategory link  
INNER JOIN #clientriskwhichhavefromdatenull client ON link.LinkRefClientRefRiskCategoryId = client.LinkRefClientRefRiskCategoryId  
  
END
GO
--RC-END-WEB=58818