CoreScreeningRequestHistory_GetCustomerKycDetail
exec dbo.CoreScreeningRequestHistory_GetCustomerKycDetail  '3995505'
CoreCRMCustomerRelationshipManagerRiskProfilingHistory

CREATE PROCEDURE dbo.CoreScreeningRequestHistory_GetCustomerKycDetail      
(         
        
 @CustomerIds VARCHAR(MAX)       
)          
AS          
BEGIN          
 DECLARE @InternalCustomerIds VARCHAR(MAX), @NatureOfBusinessEnumTypeId INT,@PanIdentificationTypeId INT   , @Nationality INT       
          
 SET @InternalCustomerIds = @CustomerIds          
 SET @NatureOfBusinessEnumTypeId = dbo.GetEnumTypeId('CRMInitialProfilingBusinessNature')      
      
       
 DECLARE @CorrespondenceAddressEnumValueId INT, @PermanentAddressEnumValueId INT, @WorkAddressEnumValueId INT      
 SET @CorrespondenceAddressEnumValueId = dbo.GetEnumValueId('AddressType', 'Correspondence')        
 SET @PermanentAddressEnumValueId = dbo.GetEnumValueId('AddressType', 'Permanent')        
 SET @WorkAddressEnumValueId = dbo.GetEnumValueId('AddressType', 'Work')        
 SELECT @PanIdentificationTypeId = RefIdentificationTypeId FROM dbo.RefIdentificationType WHERE Code = 'PanCard'     
 SET @Nationality=dbo.GetEnumValueId('CustomerCountryRelationType','Nationality')  
          
 SELECT DISTINCT customer.RefCRMCustomerId,customer.RefEntityTypeId          
 INTO #caseCustomerIds          
 FROM dbo.Split(@InternalCustomerIds,',') s          
 INNER JOIN dbo.RefCRMCustomer customer ON customer.RefCRMCustomerId = CONVERT(INT,s.items)          
      
 SELECT         
  COUNT(1) AS AddressCount,        
  addr.AddressTypeRefEnumValueId,        
  addr.EntityId AS RefCRMCustomerId        
 INTO #AddressCount        
 FROM #caseCustomerIds temp        
 INNER JOIN dbo.CoreCRMAddressDetail addr on addr.RefEntityTypeId = temp.RefEntityTypeId AND addr.EntityId = temp.RefCRMCustomerId        
 GROUP BY addr.AddressTypeRefEnumValueId, addr.EntityId       
     
  SELECT     
  cust.RefCRMCustomerId,    
 iden.IdNumber AS PanNumber     
 INTO #CustomerPanDetails     
 FROM #caseCustomerIds cust    
 INNER JOIN dbo.CoreCRMIdentification iden ON iden.RefEntityTypeId = cust.RefEntityTypeId AND iden.EntityId = cust.RefCRMCustomerId    
 WHERE iden.RefIdentificationTypeId = @PanIdentificationTypeId      
    
   SELECT  attachment.[Name] As IncomeProof,    
   cust.RefCRMCustomerId,    
   cust.RefEntityTypeId    
 INTO #IncomeProof    
     FROM dbo.LinkCoreIncomeRefAttachment link      
     INNER JOIN dbo.RefAttachment attachment ON attachment.RefAttachmentId = link.RefAttachmentId    
  INNER JOIN dbo.CoreIncome inc ON inc.CoreIncomeId=link.CoreIncomeId    
  INNER JOIN #caseCustomerIds cust ON cust.RefCRMCustomerId=inc.EntityId AND cust.RefEntityTypeId=inc.RefEntityTypeId    
      
    
    
    SELECT  attachment.[Name] As NetworthProof,    
   cust.RefCRMCustomerId,    
   cust.RefEntityTypeId    
  INTO #networthProof    
  FROM dbo.LinkCoreNetworthRefAttachment link    
  INNER JOIN dbo.RefAttachment attachment ON attachment.RefAttachmentId = link.RefAttachmentId    
  INNER JOIN dbo.CoreNetworth net ON net.CoreNetworthId=link.CoreNetworthId    
  INNER JOIN #caseCustomerIds cust ON net.EntityId = cust.RefCRMCustomerId AND net.RefEntityTypeId=cust.RefEntityTypeId    
  
  SELECT ct.Name AS Nationality,c.RefCRMCustomerId,  
  ROW_NUMBER() OVER(Partition by c.RefCRMCustomerId ORDER BY link.AddedOn DESC) RN  
 INTO #Nationality  
  FROM #caseCustomerIds c  
  INNER JOIN dbo.LinkRefCRMCustomerRefCountry link ON c.RefCRMCustomerId = link.RefCRMCustomerId  
  INNER JOIN dbo.RefCountry ct ON ct.RefCountryId = link.RefCountryId  
  WHERE link.CountryRelationshipRefEnumValueId = @Nationality  
      
 SELECT (CASE WHEN ISNULL(history.Pan,'') <> '' THEN  'PAN, ' else '' END )      
 +(CASE WHEN ISNULL(history.Din,'') <> '' THEN  'Din, ' else '' END )      
 +(CASE WHEN ISNULL(history.Cin,'') <> '' THEN  'Cin, ' else '' END )      
 +(CASE WHEN ISNULL(history.RecordIdentifier,'') <> '' THEN  'RecordIdentifier, ' else '' END )      
 +(CASE WHEN ISNULL(history.ApplicationFormNumber,'') <> '' THEN  'ApplicationFormNumber, ' else '' END )   
 +(CASE WHEN ISNULL(history.DrivingLicenceNumber,'') <> '' THEN  'DrivingLicenceNumber, ' else '' END )       
 +(CASE WHEN ISNULL(history.Passport,'') <> '' THEN  'Passport' else '' END ) CustomerIdentification,  
 tempcust.RefCRMCustomerId  
 INTO #CustomerIdentification  
 FROM #caseCustomerIds tempcust          
  INNER JOIN dbo.CoreScreeningRequestHistory history on history.RecordEntityId  = tempcust.RefCRMCustomerId   
         
 SELECT           
 history.RecordEntityId RefCRMCustomerId,          
 custEntity.Code as EntityTypeCode,         
  CASE WHEN history.CustomerCategoryName='Ind' THEN 1 ELSE 0  END AS IsIndividual,        
 cust.CustomerCode,        
 cust.FirstName,          
 cust.BirthDate,          
 cust.MiddleName,          
 cust.LastName,          
 history.CustomerCategoryName AS CustomerType,          
 ''  AS CustomerSubType,          
 cust.Age,          
 '' AS CustomerFamilyCode,        
 CASE WHEN history.Gender = 'M' THEN 'Male'  
 WHEN history.Gender = 'F' THEN 'Female'  
 ELSE history.Gender END AS Gender,          
 '' as MaritialStatus ,          
 ''as Occupation,          
--industryType.Name as IndustrySector,          
 null as IndustrySubType,          
--pepType.Name AS CustomerPEP,          
 '' as Risk,          
 '' as RiskEffectiveDate,          
 history.PermanentAddress1 AS PAddressAddressLine1,            
    history.PermanentAddress2 AS PAddressAddressLine2,            
    history.PermanentAddress3 AS PAddressAddressLine3,            
    history.PermanentAddressPin AS PAddressPin,            
    history.PermanentAddressCity As PAddressCity ,            
    '' AS PAddressDistrict ,            
    history.PermanentAddressState AS PAddressState,            
    history.PermanentAddressCountry as PAddressCountry,          
 history.CorrespondenceAddress1 AS CAddressAddressLine1,            
    history.CorrespondenceAddress2 AS CAddressAddressLine2,            
    history.CorrespondenceAddress3 AS CAddressAddressLine3,            
    history.CorrespondenceAddressPin AS CAddressPin,            
    history.CorrespondenceAddressCity As CAddressCity ,            
    '' AS CAddressDistrict ,            
    history.[CorrespondenceAddressState] AS CAddressState,            
    history.CorrespondenceAddressCountry as CAddressCountry,          
 '' AS WAddressAddressLine1,            
    '' AS WAddressAddressLine2,            
    '' AS WAddressAddressLine3,            
    '' AS WAddressPin,            
    history.WorkAddressCity As WAddressCity ,            
    '' AS WAddressDistrict ,            
    history.WorkAddressState AS WAddressState,            
    history.WorkAddressCountry as WAddressCountry,          
 CASE WHEN RIGHT(ide.CustomerIdentification, 2) = ', ' THEN substring(ide.CustomerIdentification, 1, len(ide.CustomerIdentification)-2)  
  ELSE ide.CustomerIdentification END AS CustomerIdentification,  
 '' CustomerSourceSystemDetail,          
 '' Citizenship,          
 CASE WHEN n.Nationality IS NOT NULL THEN  n.Nationality  
 ELSE (SELECT country.Name FROM dbo.RefCountry country WHERE country.SwiftCode = history.Nationality OR country.Name = history.Nationality OR country.Iso3DigitCode = history.Nationality) END  AS Nationality,          
 '' TaxResidency,          
 '' CountryOfOperation,          
 history.BranchName  RelationShipManager,          
 history.BranchName RelationShipManagerName,          
 history.Products CustomerSegment,          
 '' Email,          
--caseStatusType.Code as CaseStatusTypeCode,          
 '' ExactIncome,          
 ''  AS IncomeEffectiveDate,          
 '' IncomeTo,          
 '' IncomeFrom,         
 '' IncometoPremiumRation,        
 '' Networth,          
 ''  AS NetworthEffectiveDate,          
 '' AS MobileISDCode,          
 '' AS MobileSTDCode,          
 '' AS MobileContactNumber,          
 '' AS MobileExtension,          
 '' AS LandLineISDCode,          
 '' AS LandLineSTDCode,          
 '' AS LandLineContactNumber,          
 '' AS LandLineExtension,          
  (SELECT addr.AddressCount FROM #AddressCount addr WHERE addr.RefCRMCustomerId = cust.RefCRMCustomerId AND addr.AddressTypeRefEnumValueId = @PermanentAddressEnumValueId ) as  PAddressCount,        
  (SELECT addr.AddressCount FROM #AddressCount addr WHERE addr.RefCRMCustomerId = cust.RefCRMCustomerId AND  addr.AddressTypeRefEnumValueId = @CorrespondenceAddressEnumValueId ) as  CAddressCount,        
  (SELECT addr.AddressCount FROM #AddressCount addr WHERE addr.RefCRMCustomerId = cust.RefCRMCustomerId AND  addr.AddressTypeRefEnumValueId = @WorkAddressEnumValueId ) as  WAddressCount,        
 (SELECT country.Name FROM dbo.RefCountry country WHERE country.SwiftCode = history.CountryOfBirth OR country.Name = history.CountryOfBirth OR country.Iso3DigitCode = history.CountryOfBirth) AS BirthCountry,          
 '' AS CustomerPEP,          
 '' AS CustomerListed,          
 '' EstimatedFinancialSize,          
 '' AS Channel,          
 cust.Links,          
 '' AS AdverseInformation,          
 '' AS SourceOfWealth,          
 '' AS ChannelRisk,      
 intermediary.[Name] as IntermediaryName,      
 history.BranchName AS IntermediaryCode,          
 '' AS StrReported,          
'' AdverseClassification,          
 '' PepClassification,          
 history.Tags AS CustomerTag,          
'' ReputationClassification,          
 '' AS IndustrySector,          
 cust.AddedOn AS StartDate,          
 cust.FatherFirstName,          
 cust.FatherMiddleName,          
 cust.FatherLastName,          
 cust.SpouseFirstName,          
 cust.SpouseMiddleName,          
 cust.SpouseLastName,          
 '' AS ProofOfAddress,          
 '' EmployerName          
 ,'' Designation          
 ,'' EmploymentYears          
 ,'' EducationQualification          
 ,'' RegAmlSpecialCategory        
 ,'' ActivitySector,        
 '' AS CustomerInsiderInformation ,      
cust.LastCDDReviewDate,      
customerFamily.Name AS CustomerFamilyName,      
intermediaryRisk.Name AS IntermediaryRisk,        
cust.NextCDDAnnualReviewDate,    
STUFF((      
  SELECT ', ' + enumValue.Name         
  FROM dbo.LinkRefCRMCustomerRefEnumValue linkCustEnum        
  INNER JOIN dbo.RefEnumValue enumValue on enumValue.RefEnumValueId = linkCustEnum.RefEnumValueId AND enumValue.RefEnumTypeId = @NatureOfBusinessEnumTypeId        
  WHERE linkCustEnum.RefCRMCustomerId = cust.RefCRMCustomerId         
FOR XML PATH('')),1,1,'') NatureOfBusiness,    
reqSourceType.Code as RequestSourceTypeCode,      
STUFF(( SELECT ', ' + inc.IncomeProof     
     FROM #IncomeProof inc    
     WHERE inc.RefCRMCustomerId = cust.RefCRMCustomerId AND inc.RefEntityTypeId=cust.RefEntityTypeId    
 FOR      
 XML PATH('')      
 ), 1, 1, '') AS IncomeProof,    
  STUFF(( SELECT ', ' + nw.NetworthProof    
  FROM #networthProof nw    
  WHERE nw.RefCRMCustomerId = cust.RefCRMCustomerId AND nw.RefEntityTypeId=cust.RefEntityTypeId    
 FOR    
 XML PATH('')    
 ), 1, 1, '') AS NetworthProof,    
 panDetails.PanNumber      
 FROM #caseCustomerIds tempcust          
 INNER JOIN dbo.CoreScreeningRequestHistory history on history.RecordEntityId  = tempcust.RefCRMCustomerId      
 INNER JOIN dbo.CoreScreeningCase cases on cases.CoreScreeningCaseId = history.CoreScreeningCaseId      
 INNER JOIN dbo.RefCRMCustomer cust ON cust.RefCRMCustomerId =  tempcust.RefCRMCustomerId      
 INNER JOIN dbo.RefEntityType custEntity ON custEntity.RefEntityTypeId = cases.RecordRefEntityTypeId      
 LEFT JOIN dbo.RefFamily customerFamily on customerFamily.RefFamilyId = cust.RefFamilyId       
 LEFT JOIN dbo.RefIntermediary intermediary ON intermediary.RefIntermediaryId = cust.RefIntermediaryId         
 LEFT JOIN dbo.RefEnumValue intermediaryRisk ON intermediaryRisk.RefEnumValueId = intermediary.NewRiskClassificationRefEnumValue      
 LEFT JOIN dbo.RefEnumValue reqSourceType ON reqSourceType.RefEnumValueId = history.ScreeningRequestSourceTypeRefEnumValueId     
 LEFT JOIN #CustomerPanDetails panDetails ON panDetails.RefCRMCustomerId = cust.RefCRMCustomerId    
 LEFT JOIN #Nationality n ON n.RefCRMCustomerId = tempcust.RefCRMCustomerId AND n.RN = 1  
 LEFT JOIN #CustomerIdentification ide ON ide.RefCRMCustomerId = tempcust.RefCRMCustomerId  
 WHERE history.CoreScreeningCaseId IS NOT NULL and history.RecordEntityId IS NOT NULL      
        
 END   
 select RecordEntityId,branchname, * from CoreScreeningRequestHistory where RecordEntityId=3995505
 select * from RefIsin where 

 dbo.CoreAlertRegisterCustomerCase_GetCustomerByAlertRegisterCaseId

CREATE PROCEDURE [dbo].[CoreAlertRegisterCustomerCase_GetCustomerByAlertRegisterCaseId]          
(           
 @CustomerIds VARCHAR(MAX)  
)            
AS            
BEGIN            
            
 DECLARE @AlertRegisterCaseIdInternal BIGINT, @IndividualCustomerTypeCategoryEnumValueId INT, @entityTypeCode VARCHAR(200), @refentityTypeId INT, @CountryRelationEnumTypeId INT          
          
 DECLARE           
 @RefContactTypeMobileId INT, @RefContactTypeLandlineId INT,          
 @CitizenRefEnumvalueId INT, @NationalityRefEnumvalueId INT, @TaxResidencyRefenumvalueId INT, @CountryOfOperationRefEnumValueId INT,@NatureOfBusinessEnumTypeId INT,          
 @RefRiskTypeId INT,            
 @IntermediaryChannelEnumValueId INT,            
 @PepClassificationEnumTypeId INT,@AdverseInformationEnumTypeId INT,@ActiveEntityStatusId INT,@ReputationClassificationEnumTypeId INT,            
 @QualificationsEnumTypeId INT, @PanIdentificationTypeId INT          
           
 SET @IndividualCustomerTypeCategoryEnumValueId = dbo.GetEnumValueId('CustomerTypeCategory', 'Individual')            
 SET @CountryOfOperationRefEnumValueId = dbo.GetEnumValueId('CustomerCountryRelationType','CountryOfOperation')            
 SET @CitizenRefEnumvalueId = dbo.GetEnumValueId('CustomerCountryRelationType','Citizenship')            
 SET @NationalityRefEnumvalueId = dbo.GetEnumValueId('CustomerCountryRelationType','Nationality')            
 SET @TaxResidencyRefenumvalueId = dbo.GetEnumValueId('CustomerCountryRelationType','CountryOfTaxResidency')           
            
            
 SET @IntermediaryChannelEnumValueId = dbo.GetEnumValueId('IntroductionChannel','2')            
           
 SET @PepClassificationEnumTypeId = dbo.GetEnumTypeId('PEPClassification')            
 SET @AdverseInformationEnumTypeId = dbo.GetEnumTypeId('AdverseMediaClassification')            
 SET @CountryRelationEnumTypeId = dbo.GetEnumTypeId('CustomerCountryRelationType')            
 SET @ReputationClassificationEnumTypeId = dbo.GetEnumTypeId('ReputationClassification')          
 SET @NatureOfBusinessEnumTypeId = dbo.GetEnumTypeId('CRMInitialProfilingBusinessNature')          
           
 SET @QualificationsEnumTypeId = dbo.GetEnumTypeId('Qualifications')            
 SET @ActiveEntityStatusId = dbo.GetEnumValueId('CRMEntityStatusType','Active')           
 SELECT @RefRiskTypeId = RefRiskTypeId  FROM dbo.RefRiskType WHERE NAME='RegAMLRisk'           
            
 SELECT @RefContactTypeMobileId = RefContactTypeId FROM dbo.RefContactType WHERE Name = 'Mobile-Personal'            
 SELECT @RefContactTypeLandlineId = RefContactTypeId FROM dbo.RefContactType WHERE Name = 'Desk-Personal'            
 SELECT @PanIdentificationTypeId = RefIdentificationTypeId FROM dbo.RefIdentificationType WHERE Code = 'PanCard'         
 DECLARE @InternalCustomerIds VARCHAR(MAX)            
 SET @InternalCustomerIds = @CustomerIds           
              
 SELECT DISTINCT           
  customer.RefCRMCustomerId,          
  customer.RefEntityTypeId            
 INTO #caseCustomerIds            
 FROM dbo.Split(@InternalCustomerIds,',') s            
 INNER JOIN dbo.RefCRMCustomer customer ON customer.RefCRMCustomerId = CONVERT(INT,s.items)            
           
           
           
 --------------------Address Detail--------------------          
 DECLARE @CorrespondenceAddressEnumValueId INT, @PermanentAddressEnumValueId INT, @WorkAddressEnumValueId INT          
 SET @CorrespondenceAddressEnumValueId = dbo.GetEnumValueId('AddressType', 'Correspondence')            
 SET @PermanentAddressEnumValueId = dbo.GetEnumValueId('AddressType', 'Permanent')            
 SET @WorkAddressEnumValueId = dbo.GetEnumValueId('AddressType', 'Work')            
          
 SELECT             
  latestAddress.EntityId AS RefCRMCustomerId,            
  latestAddress.AddressLine1 ,              
  latestAddress.AddressLine2 ,              
  latestAddress.AddressLine3 ,              
  latestAddress.Pin,              
  latestAddress.City,              
  latestAddress.District,              
  latestAddress.State,              
  latestAddress.Country,            
  latestAddress.AddressTypeRefEnumValueId            
 INTO #LatestAddressDetails            
 FROM (            
   SELECT                
    addressdetail.RefEntityTypeId,              
    addressdetail.EntityId ,              
    addressdetail.AddressTypeRefEnumValueId ,              
    addressdetail.AddressLine1 ,              
    addressdetail.AddressLine2 ,              
    addressdetail.AddressLine3 ,              
    addressdetail.Pin ,              
    addressdetail.District ,              
    addressdetail.StartDate ,              
    caddresscity.Name As City ,               
    caddressState.Name AS State,              
    caddressCountry.Name as Country,            
    ROW_NUMBER() OVER ( PARTITION BY addressdetail.RefEntityTypeId, addressdetail.EntityId, addressdetail.AddressTypeRefEnumValueId           
         ORDER BY ISNULL(addressdetail.EndDate,'01/01/9999') DESC, addressDetail.Preference, addressDetail.CoreCRMAddressDetailId) AS RowNumber              
   FROM  #caseCustomerIds temp             
   INNER JOIN CoreCRMAddressDetail addressdetail on temp.RefCRMCustomerId = addressdetail.EntityId AND addressdetail.RefEntityTypeId = temp.RefEntityTypeId            
   LEFT JOIN dbo.RefState cAddressState on cAddressState.RefStateId = addressdetail.RefStateId            
   LEFT JOIN dbo.RefCountry cAddressCountry on cAddressCountry.RefCountryId = addressdetail.RefCountryId            
   LEFT JOIN dbo.RefCity cAddressCity on cAddressCity.RefCityId = addressdetail.RefCityId           
   ) latestAddress              
 WHERE latestAddress.RowNumber = 1;              
             
 SELECT             
  COUNT(1) AS AddressCount,            
  addr.AddressTypeRefEnumValueId,            
  addr.EntityId AS RefCRMCustomerId            
 INTO #AddressCount            
 FROM #caseCustomerIds temp            
 INNER JOIN dbo.CoreCRMAddressDetail addr on addr.RefEntityTypeId = temp.RefEntityTypeId AND addr.EntityId = temp.RefCRMCustomerId            
 GROUP BY addr.AddressTypeRefEnumValueId, addr.EntityId            
           
 --------------------Contact Detail--------------------          
 SELECT            
  temp.RefCRMCustomerId,            
  temp.RefContactTypeId,            
  temp.ISDCode,            
  temp.STDCode,            
  temp.ContactNumber,            
  temp.Extension            
 INTO #customerContactDetails            
 FROM (            
   SELECT             
    CustomerContactLatest.EntityId AS RefCRMCustomerId,            
    CustomerContactLatest.RefContactTypeId,            
    CustomerContactLatest.ISDCode,            
    CustomerContactLatest.STDCode,            
    CustomerContactLatest.ContactNumber,            
    CustomerContactLatest.Extension,            
    ROW_NUMBER() OVER(PARTITION BY CustomerContactLatest.RefEntityTypeId, CustomerContactLatest.EntityId, CustomerContactLatest.RefContactTypeId ORDER BY CustomerContactLatest.Preference ASC, CoreCRMContactDetailId DESC) AS RowNumber            
   FROM #caseCustomerIds temp            
   INNER JOIN CoreCRMContactDetail CustomerContactLatest ON CustomerContactLatest.EntityId = temp.RefCRMCustomerId AND CustomerContactLatest.RefEntityTypeId = temp.RefEntityTypeId            
 ) temp where temp.RowNumber=1            
             
 --------------------Email Detail--------------------           
 DECLARE @EmailRefEnumValueId INT          
 SET @EmailRefEnumValueId = dbo.GetEnumValueId('EmailType','Personal')            
          
 SELECT            
  latest.Email,            
  latest.RefCRMCustomerId            
 INTO #latestEmail            
 FROM (            
   SELECT             
    temp.RefCRMCustomerId,            
    latestEmail.Email,            
   ROW_NUMBER() OVER(PARTITION BY latestEmail.RefEntityTypeId,latestEmail.EntityId,latestEmail.EmailTypeRefEnumValueId ORDER BY latestEmail.Preference ASC,latestEmail.CoreCRMEmailDetailId DESC) AS RowNumber            
   FROM #caseCustomerIds temp            
   INNER JOIN CoreCRMEmailDetail latestEmail on latestEmail.RefEntityTypeId = temp.RefEntityTypeId AND latestEmail.EntityId = temp.RefCRMCustomerId AND latestEmail.EmailTypeRefEnumValueId = @EmailRefEnumValueId            
   ) latest          
 WHERE latest.RowNumber=1            
           
 --------------------Gross Annual Premium--------------------           
 DECLARE @ClientRefEntityTypeId INT, @InforceEnumValueId INT          
 SET @ClientRefEntityTypeId = dbo.GetEntityTypeByCode('Client')          
 SET @InforceEnumValueId = dbo.GetEnumValueId('CRMEntityStatusType','TW01')          
          
 SELECT           
  SUM(client.GrossAnnualPremiumwithoutTax) AS SumGrossAnnualPremiumwithoutTax,          
  cust.RefCRMCustomerId           
 INTO #SumGrossAnnualPremiumwithoutTax          
 FROM #caseCustomerIds cust          
 INNER JOIN dbo.CoreCRMRelatedParty relatedParty ON relatedParty.RelatedPartyRefCRMCustomerId = cust.RefCRMCustomerId AND relatedParty.RefEntityTypeId = @ClientRefEntityTypeId          
 INNER JOIN dbo.RefClient client  ON client.RefClientId = relatedParty.EntityId           
 INNER JOIN dbo.CoreCRMEntityStatus st ON st.EntityId = client.RefClientId          
 INNER JOIN dbo.RefEnumValue enum ON enum.RefEnumValueId = st.CRMEntityStatusTypeRefEnumValueId AND st.RefEntityTypeId = @ClientRefEntityTypeId          
 WHERE enum.RefEnumValueId = @InforceEnumValueId          
 GROUP BY cust.RefCRMCustomerId          
             
 --------------------Customer Latest Income--------------------            
 SELECT             
  t.RefCRMCustomerId,            
  t.ExactIncome,            
  t.EffectiveDate,            
  t.IncomeTo,            
  t.IncomeFrom,          
  t.IncometoPremiumRation,      
  STUFF(( SELECT ', ' + attachment.[Name]      
     FROM dbo.LinkCoreIncomeRefAttachment link      
     INNER JOIN dbo.RefAttachment attachment ON attachment.RefAttachmentId = link.RefAttachmentId      
     WHERE link.CoreIncomeId = t.CoreIncomeId      
    FOR      
    XML PATH('')      
    ), 1, 1, '') AS IncomeProof            
 INTO #customerLatestIncome            
 FROM (            
   SELECT      
   CustomerIncome.CoreIncomeId,              
    CustomerIncome.EntityId as RefCRMCustomerId,            
    CustomerIncome.ExactIncome,            
    CustomerIncome.EffectiveDate,            
    incomeGroup.IncomeTo,            
    incomeGroup.IncomeFrom,            
    CASE WHEN incomeGroup.IncomeTo IS NULL OR incomeGroup.IncomeTo = 0 THEN 0          
      ELSE (gap.SumGrossAnnualPremiumwithoutTax/incomeGroup.IncomeTo)*100           
      END AS IncometoPremiumRation,          
    ROW_NUMBER() OVER (PARTITION BY CustomerIncome.RefEntityTypeId, CustomerIncome.EntityId ORDER BY CustomerIncome.EffectiveDate DESC) as RowNumber            
   FROM dbo.CoreIncome CustomerIncome            
   INNER JOIN #caseCustomerIds temp on temp.RefCRMCustomerId = CustomerIncome.EntityId            
   INNER JOIN dbo.RefIncomeGroup incomeGroup on incomeGroup.RefIncomeGroupId = CustomerIncome.RefIncomeGroupId AND CustomerIncome.RefEntityTypeId = temp.RefEntityTypeId            
   LEFT JOIN #SumGrossAnnualPremiumwithoutTax gap ON gap.RefCRMCustomerId=temp.RefCRMCustomerId          
 ) t            
 WHERE t.RowNumber=1            
             
 --------------------Customer Latest Networth--------------------            
 SELECT             
  t.RefCRMCustomerId,            
  t.Networth,            
  t.EffectiveDate,      
  STUFF(( SELECT ', ' + attachment.[Name]      
     FROM dbo.LinkCoreNetworthRefAttachment link      
     INNER JOIN dbo.RefAttachment attachment ON attachment.RefAttachmentId = link.RefAttachmentId      
     WHERE link.CoreNetworthId = t.CoreNetworthId      
    FOR      
    XML PATH('')      
    ), 1, 1, '') AS NetworthProof            
 INTO #customerLatestNetworth            
 FROM (            
   SELECT       
    CustomerNetworth.CoreNetworthId,             
    CustomerNetworth.EntityId as RefCRMCustomerId,            
    CustomerNetworth.Networth,            
    CustomerNetworth.EffectiveDate,            
    ROW_NUMBER() OVER (PARTITION BY CustomerNetworth.RefEntityTypeId, CustomerNetworth.EntityId ORDER BY CustomerNetworth.EffectiveDate Desc) as RowNumber            
   FROM dbo.CoreNetworth CustomerNetworth            
   INNER JOIN #caseCustomerIds temp on temp.RefCRMCustomerId = CustomerNetworth.EntityId AND CustomerNetworth.RefEntityTypeId =temp.RefEntityTypeId            
 ) t            
 WHERE t.RowNumber=1            
             
 --------------------Customer Estimated Financial Size--------------------           
 SELECT           
  CoreCustomerEstimatedFinancialSizeId,          
  RefCRMCustomerId,          
  EstimatedFinancialSize,          
  EffectiveDate          
 INTO #customerFinancialSize            
 FROM            
 (            
  SELECT            
   CoreCustomerEstimatedFinancialSizeId,          
   fs.RefCRMCustomerId,          
   EstimatedFinancialSize,          
   EffectiveDate,          
   ROW_NUMBER() OVER(PARTITION BY fs.RefCRMCustomerId ORDER BY EffectiveDate DESC) AS RowNumber            
  FROM #caseCustomerIds temp            
  INNER JOIN dbo.CoreCustomerEstimatedFinancialSize fs  on temp.RefCRMCustomerId = fs.RefCRMCustomerId            
 ) t            
 WHERE t.RowNumber = 1            
             
 --------------------CDD Risk--------------------             
 SELECT           
  RefEntityTypeId,           
  EntityId,           
  EffectiveDate,          
  RefRiskTypeId,          
  RefRiskId            
 INTO #CddRiskClassification            
 FROM (          
   SELECT           
    RANK() OVER(PARTITION BY c.RefEntityTypeId, c.EntityId,r.RefRiskTypeId ORDER BY c.EffectiveDate DESC) AS [RankNo],           
    c.RefEntityTypeId,           
    c.EntityId,          
    r.RefRiskTypeId,          
    c.RefRiskId,           
    c.EffectiveDate            
   FROM #caseCustomerIds temp            
   INNER JOIN dbo.CoreCRMCDDClassification c ON c.EntityId = temp.RefCRMCustomerId AND c.RefEntityTypeId = temp.RefEntityTypeId            
   INNER JOIN dbo.RefRisk r ON r.RefRiskId = c.RefRiskId            
 ) t            
 WHERE t.RankNo = 1            
             
 --------------------Customer Segment Details--------------------            
 SELECT            
  custSegment.RefCRMCustomerId,          
  segment.Name AS CustomerSegment            
 INTO #customerSegmentDetail            
 FROM #caseCustomerIds temp             
 INNER JOIN dbo.LinkRefCRMCustomerRefCustomerSegment custSegment ON custSegment.RefCRMCustomerId = temp.RefCRMCustomerId            
 INNER JOIN dbo.RefCustomerSegment segment ON segment.RefCustomerSegmentId = custSegment.RefCustomerSegmentId            
             
 --------------------STR Reported Detail--------------------           
 DECLARE @ReportedStatusEnumValueId INT          
 SET @ReportedStatusEnumValueId = dbo.GetEnumValueId('AmlAlertRegisterStatusType','3')           
          
 SELECT          
  temp.RefCRMCustomerId,          
  cases.CoreAlertRegisterCustomerCaseId            
 INTO #reportedCaseHistory            
 FROM #caseCustomerIds temp            
 INNER JOIN dbo.LinkCoreAlertRegisterCustomerCaseRefCRMCustomer caseLink ON caseLink.RefCRMCustomerId = temp.RefCRMCustomerId            
 INNER JOIN dbo.CoreAlertRegisterCustomerCase cases ON cases.CoreAlertRegisterCustomerCaseId = caseLink.CoreAlertRegisterCustomerCaseId AND cases.AlertRegisterStatusTypeRefEnumValueId = @ReportedStatusEnumValueId            
             
 --------------------Customer Tags Detail--------------------          
 SELECT           
  temp.RefCRMCustomerId,          
  tag.[Name] AS CustomerTag            
 INTO #customerTagDetail            
 FROM #caseCustomerIds temp             
 INNER JOIN dbo.CoreEntityRefTag customerTag ON customerTag.RefEntityTypeId = temp.RefEntityTypeId AND customerTag.EntityId = temp.RefCRMCustomerId            
 INNER JOIN dbo.RefTag tag ON tag.RefTagId = customerTag.RefTagId            
             
 --------------------Entity Status Detail--------------------           
 SELECT             
  t.RefCRMCustomerId,            
  t.EffectiveDate,            
  t.CRMEntityStatusTypeRefEnumValueId            
 INTO #customerEntityStatusDetail            
 FROM (           
  SELECT              
   temp.RefCRMCustomerId,           
   entityStatus.EffectiveDate,          
   entityStatus.CRMEntityStatusTypeRefEnumValueId,          
   ROW_NUMBER() OVER(PARTITION BY temp.RefCRMCustomerId, entityStatus.CRMEntityStatusTypeRefEnumValueId ORDER BY entityStatus.AddedOn DESC) AS RowNumber            
  FROM #caseCustomerIds temp             
  INNER JOIN dbo.CoreCRMEntityStatus entityStatus ON entityStatus.RefEntityTypeId  = temp.RefEntityTypeId AND entityStatus.EntityId = temp.RefCRMCustomerId            
 ) t            
 WHERE t.RowNumber = 1            
             
 --------------------Activity Employment Detail----------------------            
 SELECT            
  t.RefCRMCustomerId,            
  t.EmployerName,            
  t.Designation,            
  t.EmploymentYears           
 INTO #ActivityDetail            
 FROM (            
   SELECT          
    temp.RefCRMCustomerId,            
    acDetail.CompanyName AS EmployerName,            
    acDetail.Designation,             
    acDetail.Years AS EmploymentYears,            
    ROW_NUMBER () OVER(PARTITION BY acDetail.EntityId,acDetail.RefEntityTypeId ORDER BY acDetail.AddedOn DESC) AS RowNumber              
    FROM #caseCustomerIds temp             
   INNER JOIN dbo.CoreCRMActivityDetail acDetail ON acDetail.EntityId = temp.RefCRMCustomerId AND acDetail.RefEntityTypeId = temp.RefEntityTypeId            
 ) t            
 WHERE t.RowNumber = 1       
       
 ------------Customer PAN Details--------------------      
 SELECT       
  cust.RefCRMCustomerId,      
 iden.IdNumber AS PanNumber       
 INTO #CustomerPanDetails       
 FROM #caseCustomerIds cust      
 INNER JOIN dbo.CoreCRMIdentification iden ON iden.RefEntityTypeId = cust.RefEntityTypeId AND iden.EntityId = cust.RefCRMCustomerId      
 WHERE iden.RefIdentificationTypeId = @PanIdentificationTypeId            
             
 ----Final----            
 SELECT             
  cust.RefCRMCustomerId,            
  et.Code as EntityTypeCode,            
  CASE WHEN customerCategoryType.Code='Non Ind' THEN 0 ELSE 1 END AS IsIndividual,            
  cust.CustomerCode,            
  cust.FirstName,            
  cust.BirthDate,            
  cust.MiddleName,            
  cust.LastName,            
  custType.Name AS CustomerType,            
  custSubType.Name AS CustomerSubType,            
  cust.Age,            
  customerFamily.FamilyCode AS CustomerFamilyCode,            
  customerFamily.Name AS CustomerFamilyName,          
  genderEnumValue.Name AS Gender,            
  maritialStatus.Name as MaritialStatus ,            
  Occupation.Name as Occupation,            
  null as IndustrySubType,            
  Risk.Name as Risk,            
  latestCdd.EffectiveDate as RiskEffectiveDate,            
  paddress.AddressLine1 AS PAddressAddressLine1,              
  paddress.AddressLine2 AS PAddressAddressLine2,              
  paddress.AddressLine3 AS PAddressAddressLine3,              
  paddress.Pin AS PAddressPin,              
  pAddress.City As PAddressCity ,              
  paddress.District AS PAddressDistrict ,         
  pAddress.[State] AS PAddressState,              
  pAddress.Country as PAddressCountry,            
  caddress.AddressLine1 AS CAddressAddressLine1,              
  caddress.AddressLine2 AS CAddressAddressLine2,              
  caddress.AddressLine3 AS CAddressAddressLine3,              
  caddress.Pin AS CAddressPin,              
  cAddress.City As CAddressCity ,              
  caddress.District AS CAddressDistrict ,              
  cAddress.[State] AS CAddressState,              
  cAddress.Country as CAddressCountry,            
  wAddress.AddressLine1 AS WAddressAddressLine1,              
  wAddress.AddressLine2 AS WAddressAddressLine2,              
  wAddress.AddressLine3 AS WAddressAddressLine3,              
  wAddress.Pin AS WAddressPin,              
  wAddress.City As WAddressCity ,              
  wAddress.District AS WAddressDistrict ,              
  wAddress.State AS WAddressState,              
  wAddress.Country as WAddressCountry,            
  STUFF((          
    SELECT ', ' + IdenType.Name             
    FROM dbo.CoreCRMIdentification identification            
    INNER JOIN dbo.RefIdentificationType IdenType on IdenType.RefIdentificationTypeId = identification.RefIdentificationTypeId AND IdenType.IsExternalSystem =0            
    WHERE identification.RefEntityTypeId = cust.RefEntityTypeId AND cust.RefCRMCustomerId = identification.EntityId             
  FOR XML PATH('')),1,1,'') CustomerIdentification,            
  STUFF((          
    SELECT ', ' +           
    (IdenType.Name +' - '+ identification.IdNumber )            
    FROM dbo.CoreCRMIdentification identification            
    INNER JOIN dbo.RefIdentificationType IdenType on IdenType.RefIdentificationTypeId = identification.RefIdentificationTypeId AND IdenType.IsExternalSystem =1            
    WHERE identification.RefEntityTypeId = cust.RefEntityTypeId AND cust.RefCRMCustomerId = identification.EntityId             
  FOR XML PATH('')),1,1,'') CustomerSourceSystemDetail,            
  STUFF((          
    SELECT ', ' + country.Name             
    FROM dbo.RefCountry country            
    INNER JOIN dbo.LinkRefCRMCustomerRefCountry linkCustCountry on linkCustCountry.RefCountryId = country.RefCountryId            
    WHERE linkCustCountry.RefCRMCustomerId = cust.RefCRMCustomerId             
    AND linkCustCountry.CountryRelationshipRefEnumValueId = @CitizenRefEnumvalueId            
  FOR XML PATH('')),1,1,'') Citizenship,            
  STUFF((          
    SELECT ', ' + country.Name             
    FROM dbo.RefCountry country            
    INNER JOIN dbo.LinkRefCRMCustomerRefCountry linkCustCountry on linkCustCountry.RefCountryId = country.RefCountryId            
    WHERE linkCustCountry.RefCRMCustomerId = cust.RefCRMCustomerId           
    AND linkCustCountry.CountryRelationshipRefEnumValueId = @NationalityRefEnumvalueId            
  FOR XML PATH('')),1,1,'') Nationality,            
  STUFF((          
    SELECT ', ' + country.Name             
    FROM dbo.RefCountry country            
    INNER JOIN dbo.CoreCRMTaxResidency taxResidency on taxResidency.RefCountryId = country.RefCountryId            
    WHERE taxResidency.RefEntityTypeId = cust.RefEntityTypeId AND taxResidency.EntityId = cust.RefCRMCustomerId             
  --AND linkCustCountry.CountryRelationshipRefEnumValueId = @TaxResidencyRefenumvalueId            
  FOR XML PATH('')),1,1,'') TaxResidency,            
  STUFF((          
    SELECT ', ' + country.Name             
    FROM dbo.RefCountry country            
    INNER JOIN dbo.LinkRefCRMCustomerRefCountry linkCustCountry on linkCustCountry.RefCountryId = country.RefCountryId            
    WHERE linkCustCountry.RefCRMCustomerId = cust.RefCRMCustomerId             
    AND linkCustCountry.CountryRelationshipRefEnumValueId = @CountryOfOperationRefEnumValueId            
  FOR XML PATH('')),1,1,'') CountryOfOperation,            
  STUFF((          
    SELECT ', ' + employeeRm.EmployeeCode             
    FROM dbo.CoreCRMCustomerRelationshipManager custRm            
    INNER JOIN dbo.RefEmployee employeeRm on employeeRm.RefEmployeeId = custRm.RefEmployeeId            
    WHERE custRm.RefCRMCustomerId = cust.RefCRMCustomerId             
  FOR XML PATH('')),1,1,'') RelationShipManager,   
  select * from RefEnumValue where refEnumvalueid=99
  STUFF((          
    SELECT ', ' + employeeRm.Name             
    FROM dbo.CoreCRMCustomerRelationshipManager custRm            
    INNER JOIN dbo.RefEmployee employeeRm on employeeRm.RefEmployeeId = custRm.RefEmployeeId            
    WHERE custRm.RefCRMCustomerId = cust.RefCRMCustomerId             
  FOR XML PATH('')),1,1,'') RelationShipManagerName,            
  STUFF((          
    SELECT ', ' + custSegment.CustomerSegment             
    FROM #customerSegmentDetail custSegment            
    WHERE custSegment.RefCRMCustomerId = cust.RefCRMCustomerId             
  FOR XML PATH('')),1,1,'') CustomerSegment,            
  latestEmail.Email,            
  --caseStatusType.Code as CaseStatusTypeCode,            
  incomeLatest.ExactIncome,            
  incomeLatest.EffectiveDate AS IncomeEffectiveDate,            
  incomeLatest.IncomeTo,            
  incomeLatest.IncomeFrom,           
  incomeLatest.IncometoPremiumRation,          
  networthLatest.Networth,            
  networthLatest.EffectiveDate AS NetworthEffectiveDate,            
  mobileDetails.ISDCode AS MobileISDCode,            
  mobileDetails.STDCode AS MobileSTDCode,            
  mobileDetails.ContactNumber AS MobileContactNumber,            
  mobileDetails.Extension AS MobileExtension,            
  landLineDetails.ISDCode AS LandLineISDCode,            
  landLineDetails.STDCode AS LandLineSTDCode,            
  landLineDetails.ContactNumber AS LandLineContactNumber,            
  landLineDetails.Extension AS LandLineExtension,            
  (SELECT addr.AddressCount FROM #AddressCount addr WHERE addr.RefCRMCustomerId = cust.RefCRMCustomerId AND addr.AddressTypeRefEnumValueId = @PermanentAddressEnumValueId ) as  PAddressCount,            
  (SELECT addr.AddressCount FROM #AddressCount addr WHERE addr.RefCRMCustomerId = cust.RefCRMCustomerId AND  addr.AddressTypeRefEnumValueId = @CorrespondenceAddressEnumValueId ) as  CAddressCount,            
  (SELECT addr.AddressCount FROM #AddressCount addr WHERE addr.RefCRMCustomerId = cust.RefCRMCustomerId AND  addr.AddressTypeRefEnumValueId = @WorkAddressEnumValueId ) as  WAddressCount,            
  birthCountry.Name AS BirthCountry,            
  pepValue.Name AS CustomerPEP,            
  listedValue.Name AS CustomerListed,            
  financialSize.EstimatedFinancialSize,            
  channelEnumValue.name AS Channel,            
  cust.Links,            
  CASE WHEN cust.AdverseMedia= 1 THEN 'Yes'           
    ELSE 'No'           
    END AS AdverseInformation,            
  cust.SourceofWealth AS SourceOfWealth,            
  CASE WHEN channelEnumValue.RefEnumValueId = @IntermediaryChannelEnumValueId THEN derivedRisk.Name           
    ELSE NULL           
    END AS ChannelRisk,    
  intermediary.[Name] as IntermediaryName,            
  intermediary.IntermediaryCode,        
  intermediaryRisk.Name AS IntermediaryRisk,            
  CASE WHEN EXISTS(SELECT 1 FROM #reportedCaseHistory caseHistory WHERE caseHistory.RefCRMCustomerId = cust.RefCRMCustomerId ) THEN 'YES'           
    ELSE 'NO'           
    END AS StrReported,            
  STUFF((          
    SELECT ', ' + enumValue.Name             
    FROM dbo.LinkRefCRMCustomerRefEnumValue linkCustEnum            
    INNER JOIN dbo.RefEnumValue enumValue on enumValue.RefEnumValueId = linkCustEnum.RefEnumValueId AND enumValue.RefEnumTypeId = @AdverseInformationEnumTypeId            
    WHERE linkCustEnum.RefCRMCustomerId = cust.RefCRMCustomerId             
  FOR XML PATH('')),1,1,'') AdverseClassification,            
  STUFF((          
    SELECT ', ' + enumValue.Name             
    FROM dbo.LinkRefCRMCustomerRefEnumValue linkCustEnum            
    INNER JOIN dbo.RefEnumValue enumValue on enumValue.RefEnumValueId = linkCustEnum.RefEnumValueId AND enumValue.RefEnumTypeId = @PepClassificationEnumTypeId            
    WHERE linkCustEnum.RefCRMCustomerId = cust.RefCRMCustomerId             
  FOR XML PATH('')),1,1,'') PepClassification,            
  STUFF((          
    SELECT ', ' + tags.CustomerTag             
    FROM #customerTagDetail tags            
    WHERE tags.RefCRMCustomerId = cust.RefCRMCustomerId             
  FOR XML PATH('')),1,1,'') CustomerTag,            
  STUFF((          
    SELECT ', ' + enumValue.Name             
    FROM dbo.LinkRefCRMCustomerRefEnumValue linkCustEnum            
    INNER JOIN dbo.RefEnumValue enumValue on enumValue.RefEnumValueId = linkCustEnum.RefEnumValueId AND enumValue.RefEnumTypeId = @ReputationClassificationEnumTypeId            
    WHERE linkCustEnum.RefCRMCustomerId = cust.RefCRMCustomerId             
  FOR XML PATH('')),1,1,'') ReputationClassification,            
  inds.Name AS IndustrySector,            
  entityStatus.EffectiveDate AS StartDate,            
  cust.FatherFirstName,            
  cust.FatherMiddleName,            
  cust.FatherLastName,            
  cust.SpouseFirstName,            
  cust.SpouseMiddleName,            
  cust.SpouseLastName,            
  attachment.Name AS ProofOfAddress,            
  activityDetail.EmployerName,            
  activityDetail.Designation,          
  activityDetail.EmploymentYears,          
  STUFF((          
    SELECT ', ' + enumValue.Name             
    FROM dbo.LinkRefCRMCustomerRefEnumValue linkCustEnum            
    INNER JOIN dbo.RefEnumValue enumValue on enumValue.RefEnumValueId = linkCustEnum.RefEnumValueId AND enumValue.RefEnumTypeId = @QualificationsEnumTypeId            
    WHERE linkCustEnum.RefCRMCustomerId = cust.RefCRMCustomerId             
  FOR XML PATH('')),1,1,'') EducationQualification,            
  STUFF((          
    SELECT ', ' + regAmlCat.[Name]            
    FROM dbo.LinkRefCRMCustomerRefClientSpecialCategory linkCustCat            
    INNER JOIN dbo.RefClientSpecialCategory regAmlCat on regAmlCat.RefClientSpecialCategoryId = linkCustCat.RefClientSpecialCategoryId               
    WHERE linkCustCat.RefCRMCustomerId = cust.RefCRMCustomerId AND linkCustCat.StartDate <= GETDATE()             
    AND GETDATE() < ISNULL(linkCustCat.EndDate, DATEADD(DAY, 1,GETDATE()))            
  FOR XML PATH('')),1,1,'') RegAmlSpecialCategory,          
  STUFF((          
    SELECT ', ' + sector.Name             
    FROM dbo.LinkRefCRMCustomerRefActivitySector linkActivitySector          
    INNER JOIN dbo.RefActivitySector sector on sector.RefActivitySectorId = linkActivitySector.RefActivitySectorId          
    WHERE linkActivitySector.RefCRMCustomerId = cust.RefCRMCustomerId          
  FOR XML PATH('')),1,1,'') ActivitySector,          
  customerInsiderInformationEnum.Name AS CustomerInsiderInformation,          
  cust.LastCDDReviewDate,          
  cust.NextCDDAnnualReviewDate,          
  STUFF((          
    SELECT ', ' + enumValue.Name             
    FROM dbo.LinkRefCRMCustomerRefEnumValue linkCustEnum            
    INNER JOIN dbo.RefEnumValue enumValue on enumValue.RefEnumValueId = linkCustEnum.RefEnumValueId AND enumValue.RefEnumTypeId = @NatureOfBusinessEnumTypeId            
    WHERE linkCustEnum.RefCRMCustomerId = cust.RefCRMCustomerId             
  FOR XML PATH('')),1,1,'') NatureOfBusiness,        
  NULL AS RequestSourceTypeCode,      
  incomeLatest.IncomeProof,      
  networthLatest.NetworthProof,      
  panDetails.PanNumber         
 FROM #caseCustomerIds tempcust            
 INNER JOIN dbo.RefCRMCustomer cust on tempcust.RefCRMCustomerId = cust.RefCRMCustomerId            
 INNER JOIN dbo.RefEntityType et on et.RefEntityTypeId = cust.RefEntityTypeId            
 LEFT JOIN dbo.RefFamily customerFamily on customerFamily.RefFamilyId = cust.RefFamilyId            
 LEFT JOIN dbo.RefCountry birthCountry on birthCountry.RefCountryId = cust.BirthCountryId            
 LEFT JOIN dbo.RefCustomerType custType on custType.RefCustomerTypeId = cust.RefCustomerTypeId            
 LEFT JOIN dbo.RefCustomerSubType custSubType ON custSubType.RefCustomerSubTypeId = cust.RefCustomerSubTypeId            
 LEFT JOIN dbo.RefEnumValue customerCategoryType ON customerCategoryType.RefEnumValueId = custType.CustomerTypeCategoryRefEnumValueId            
 LEFT JOIN dbo.RefEnumValue genderEnumValue ON genderEnumValue.RefEnumValueId = cust.GenderRefEnumValueId            
 LEFT JOIN dbo.RefMaritalStatus maritialStatus on maritialStatus.RefMaritalStatusId = cust.RefMaritalStatusId            
 LEFT JOIN dbo.RefEnumValue industryType on industryType.RefEnumValueId = cust.IndustryTypeRefEnumValueId            
 LEFT JOIN dbo.RefIndustry inds ON inds.RefIndustryId  = cust.RefIndustryId            
 LEFT JOIN dbo.RefBseMfOccupationType Occupation on Occupation.RefBseMfOccupationTypeId = cust.RefBseMfOccupationTypeId            
 LEFT JOIN #CddRiskClassification latestCdd on latestCdd.RefEntityTypeId = cust.RefEntityTypeId AND latestCdd.EntityId = cust.RefCRMCustomerId AND latestCdd.RefRiskTypeId = @RefRiskTypeId            
 LEFT JOIN dbo.RefRisk risk  on risk.RefRiskId = latestCdd.RefRiskId            
 LEFT JOIN dbo.RefEnumValue listedValue ON listedValue.RefEnumValueId = cust.ListedYesNoRefEnumValueId            
 LEFT JOIN dbo.RefEnumValue pepValue ON pepValue.RefEnumValueId = cust.PEPRefEnumValueId            
 LEFT JOIN dbo.RefEnumValue channelEnumValue ON channelEnumValue.RefEnumValueId = cust.IntroductionChannelRefEnumValueId            
 LEFT JOIN dbo.RefIntermediary intermediary ON intermediary.RefIntermediaryId = cust.RefIntermediaryId            
 LEFT JOIN dbo.RefEnumValue derivedRisk ON derivedRisk.RefEnumValueId = intermediary.DerivedRiskRefEnumValueId            
 LEFT JOIN dbo.RefEnumValue intermediaryRisk ON intermediaryRisk.RefEnumValueId = intermediary.NewRiskClassificationRefEnumValue          
 LEFT JOIN #LatestAddressDetails pAddress on pAddress.RefCRMCustomerId = cust.RefCRMCustomerId AND pAddress.AddressTypeRefEnumValueId = @PermanentAddressEnumValueId            
 LEFT JOIN #LatestAddressDetails cAddress on cAddress.RefCRMCustomerId = cust.RefCRMCustomerId AND cAddress.AddressTypeRefEnumValueId = @CorrespondenceAddressEnumValueId            
 LEFT JOIN #LatestAddressDetails wAddress on wAddress.RefCRMCustomerId = cust.RefCRMCustomerId AND wAddress.AddressTypeRefEnumValueId = @WorkAddressEnumValueId            
 LEFT JOIN #customerContactDetails mobileDetails on mobileDetails.RefCRMCustomerId = cust.RefCRMCustomerId AND mobileDetails.RefContactTypeId = @RefContactTypeMobileId            
 LEFT JOIN #customerContactDetails landLineDetails on landLineDetails.RefCRMCustomerId = cust.RefCRMCustomerId AND landLineDetails.RefContactTypeId = @RefContactTypeLandlineId            
 LEFT JOIN #customerLatestIncome incomeLatest on incomeLatest.RefCRMCustomerId = cust.RefCRMCustomerId            
 LEFT JOIN #customerLatestNetworth networthLatest on networthLatest.RefCRMCustomerId = cust.RefCRMCustomerId            
 LEFT JOIN #latestEmail latestEmail on latestEmail.RefCRMCustomerId = cust.RefCRMCustomerId            
 LEFT JOIN #customerFinancialSize financialSize ON financialSize.RefCRMCustomerId = cust.RefCRMCustomerId            
 LEFT JOIN #customerEntityStatusDetail entityStatus ON entityStatus.RefCRMCustomerId = cust.RefCRMCustomerId AND entityStatus.CRMEntityStatusTypeRefEnumValueId = @ActiveEntityStatusId            
 LEFT JOIN dbo.RefAttachment attachment ON attachment.RefAttachmentId = cust.PermanentAddressProofRefAttachmentId            
 LEFT JOIN #ActivityDetail activityDetail ON activityDetail.RefCRMCustomerId = cust.RefCRMCustomerId            
 LEFT JOIN dbo.RefEnumValue customerInsiderInformationEnum ON customerInsiderInformationEnum.RefEnumValueId = cust.CRMCustomerInsiderInformationRefEnumValueId          
 LEFT JOIN #CustomerPanDetails panDetails ON panDetails.RefCRMCustomerId = cust.RefCRMCustomerId      
END          