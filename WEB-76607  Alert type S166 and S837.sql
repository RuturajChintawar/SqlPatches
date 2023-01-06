GO
ALTER  PROCEDURE [dbo].[Client_Refresh]	
AS
BEGIN
	
	DECLARE @DataBaseId INT
	SELECT  @DatabaseId = RefClientDatabaseEnumId
	FROM    RefClientDatabaseEnum
	WHERE   DatabaseType = 'Trading'	
	
	
	--DECLARE @StatusId INT
	--SELECT @StatusId = RefClientStatusId FROM RefClientStatus
	--WHERE Name = 'Not_Defined';
	
	--drop table temp_client
	
	--SELECT  top 1 * from temp_client FROM  #client

	IF OBJECT_ID('Smalloffice..temp_client') IS NOT NULL 
    DROP TABLE temp_client

	
----------------------------------------------------

--------declare @ID varchar(200)

--------Set @id = '252525'
select * into temp_client  from OpenQuery(PRCSN,'select CLIENTID,
DPID,
CLIENTNAME,
PAN,
to_char(DATEOFBIRTH),
to_char(ACCOUNTOPENINGDATE),
to_char(ACCOUNTCLOSINGDATE),
CONSTITUTIONTYPE,
PADDRESSLINE1,
PADDRESSLINE2,
PADDRESSLINE3,
PCITY,
PSTATE,
PCOUNTRY,
PPIN,
CADDRESSLINE1,
CADDRESSLINE2,
CADDRESSLINE3,
CCITY,
CSTATE,
CCOUNTRY,
CPIN,
PHONE1,
PHONE2,
PHONE3,
MOBILE,
EMAIL,
GENDER,
OCCUPATION,
FATHERNAME,
INTERMEDIARY,
OFFICEDETAILSNAME,
OFFICEDETAILSADDRESS,
OFFICEDETAILSPHONE,
SPECIALCATEGORY,
SECONDHOLDERSALUTATION,
SECONDHOLDERFIRSTNAME,
SECONDHOLDERMIDDLENAME,
SECONDHOLDERLASTNAME,
SECONDHOLDERGENDER,
To_char(SECONDHOLDERDOB),
SECONDHOLDERPAN,
SECONDHOLDERFATHERORHUSBANDNM,
SECONDHOLDERCONSTITUTIONTYPE,
THIRDHOLDERSALUTATION,
THIRDHOLDERFIRSTNAME,
THIRDHOLDERMIDDLENAME,
THIRDHOLDERLASTNAME,
THIRDHOLDERGENDER,
to_char(THIRDHOLDERDOB),
THIRDHOLDERPAN,
THIRDHOLDERFATHERORHUSBANDNAME,
THIRDHOLDERCONSTITUTIONTYPE,
NOMINEEFIRSTNAME,
NOMINEEMIDDLENAME,
NOMINEELASTNAME,
NOMINEERELATIONSHIPWITHFIRSTHO,
NOMINEERELATIONWITHSECONDHO,
NOMINEERELATIONSHIPWITHTHIRDHO,
NOMINEEADDRESSLINE1,
NOMINEEADDRESSLINE2,
NOMINEEADDRESSLINE3,
NOMINEEADDRESSCITY,
NOMINEEADDRESSSTATE,
NOMINEEADDRESSCOUNTRY,
NOMINEEADDRESSPIN,
NOMINEEPHONE,
to_char(NOMINEEDOB),
GUARDIANFIRSTNAME,
GUARDIANMIDDLENAME,
GUARDIANLASTNAME,
GUARDIANRELATIONSHIP,
GUARDIANADDRESSLINE1,
GUARDIANADDRESSLINE2,
GUARDIANADDRESSLINE3,
GUARDIANADDRESSCITY,
GUARDIANADDRESSSTATE,
GUARDIANADDRESSCOUNTRY,
GUARDIANADDRESSPIN,
GUARDIANPHONE,
GURADIANPAN,
NRIPISAPPROVALNO,
NRIFOREIGNADDRESSLINE1,
NRIFOREIGNADDRESSLINE2,
NRIFOREIGNADDRESSCITY,
NRIFOREIGNADDRESSSTATE,
NRIFOREIGNADDRESSCOUNTRY,
NRIFOREIGNADDRESSPIN,
POAHOLDERPRESENTFLAG,
CLIENT_ACCOUNT_STATUS,
REFCLIENTACTIVATIONSTATUS,
PEP,
BRANCH_MANAGER_CODE,
BRANCH_MANAGER_NAME,
BRANCH_MANAGER_EMAIL_ID,
DEALER_CODE,
DEALER_NAME,
DEALER_EMAIL_ID,
DP_ID_1,
DP_AC_NO1,
DP_ID_2,
DP_AC_NO2,
DP_ID_3,
DP_AC_NO3,
DP_ID_4,
DP_AC_NO4,
DP_ID_5,
DP_AC_NO5,
BANK_ACCOUNT_NO_1,
BANK_ACCOUNT_NO_2,
BANK_ACCOUNT_NO_3,
BANK_ACCOUNT_NO_4,
BANK_ACCOUNT_NO_5
 from CBOSOWNER.V_AML_ENTITY_INFO_VIEW ')
----select * from temp_client where clientid = '252425'

--select * from temp_client

update temp_client set [to_char(DateOfBirth)] = NULL WHERE ISDATE([TO_CHAR(DATEOFBIRTH)]) = 0;
update temp_client set [to_char(ACCOUNTOPENINGDATE)] = NULL WHERE ISDATE([to_char(ACCOUNTOPENINGDATE)]) = 0;
update temp_client set [to_char(NOMINEEDOB)] = NULL ;

WITH cte as
	(
	SELECT ROW_NUMBER() OVER(PARTITION BY ClientID ORDER BY ClientID ) as cnt,* FROM temp_client
		)
	
	DELETE FROM cte
	 WHERE cnt > 1;



IF OBJECT_ID('tempdb..#Temp_ConstitutionTypeMapping') IS NOT NULL 
    DROP TABLE #Temp_ConstitutionTypeMapping
CREATE TABLE #Temp_ConstitutionTypeMapping
	(
		Id INT IDENTITY(1,1) NOT NULL,
		HDFCCode VARCHAR(10),
		TSSName VARCHAR(500)
	)
	
	
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('08', 'Bank')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('15', 'Overseas Corporate Body')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('04', 'Public & Private Companies / Bodies Corporate/ Company')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('09', 'Public & Private Companies / Bodies Corporate/ Company')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('13', 'Public & Private Companies / Bodies Corporate/ Company')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('02', 'Partnership Firm')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('16', 'New Pension System (NPS)/ Pension Fund Scheme')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('06', 'Mutual Fund')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('18', 'Insurance')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('03', 'Hindu Undivided Family')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('07', 'Domestic Financial Institutions (Other than Banks &amp; Insurance)')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('23', 'Foreign Direct Investment')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('21', 'Foreign Direct Investments (FDI) / Foreign Venture Capital Funds (VC)')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('12', 'Foreign Institutional Investor')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('41', 'Foreign National')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('42', 'Foreign National')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('43', 'Foreign National')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('47', 'Foreign National')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('48', 'Foreign National')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('49', 'Foreign National')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('44', 'Foreign National')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('45', 'Foreign National')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('46', 'Foreign National')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('22', 'PMS clients')
--	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('15', 'QFI Individual')
--	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('16', 'QFI Group/Association')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('01', 'Individual/Proprietorship firms')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('05', 'Trust / Society/ Non-Registered Trust')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('10', 'Trust / Society/ Non-Registered Trust')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('19', 'Statutory Bodies')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('11', 'NRI')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('99', 'Other')
	INSERT INTO #Temp_ConstitutionTypeMapping VALUES('14', 'Charities')
-------------------------------------------------
	
	IF OBJECT_ID('tempdb..#Temp_OccupationMapping') IS NOT NULL 
    DROP TABLE #Temp_OccupationMapping
	CREATE TABLE #Temp_OccupationMapping
	(
		Id INT IDENTITY(1,1) NOT NULL,
		HDFCName VARCHAR(500),
		TSSName VARCHAR(500),

		
	)
	
	INSERT INTO #Temp_OccupationMapping VALUES('Agriculturist', 'Agriculture')
	INSERT INTO #Temp_OccupationMapping VALUES('Business', 'Business')
	INSERT INTO #Temp_OccupationMapping VALUES('Business-Agriculture', 'Business')
	INSERT INTO #Temp_OccupationMapping VALUES('Business-Manufacturing', 'Business')
	INSERT INTO #Temp_OccupationMapping VALUES('Business-Real Estate', 'Business')
	INSERT INTO #Temp_OccupationMapping VALUES('Business-Service Provider', 'Business')
	INSERT INTO #Temp_OccupationMapping VALUES('Business-Stock Broker', 'Business')
	INSERT INTO #Temp_OccupationMapping VALUES('Business-Trader', 'Business')
	INSERT INTO #Temp_OccupationMapping VALUES('Forex Dealer', 'Forex Dealer')
	INSERT INTO #Temp_OccupationMapping VALUES('Government Service', 'GOVERNMENT SERVICES')
	INSERT INTO #Temp_OccupationMapping VALUES('Housewife', 'Housewife')
	INSERT INTO #Temp_OccupationMapping VALUES('NGO', 'Others')
	INSERT INTO #Temp_OccupationMapping VALUES('Others', 'Others')
	INSERT INTO #Temp_OccupationMapping VALUES('Politician', 'Others')
	INSERT INTO #Temp_OccupationMapping VALUES('Employed', 'PRIVATE SECTOR')
	INSERT INTO #Temp_OccupationMapping VALUES('Employed with Institution', 'PRIVATE SECTOR')
	INSERT INTO #Temp_OccupationMapping VALUES('Employed with Multinational', 'PRIVATE SECTOR')
	INSERT INTO #Temp_OccupationMapping VALUES('Employed with Private Sector', 'PRIVATE SECTOR')
	INSERT INTO #Temp_OccupationMapping VALUES('Private Sector', 'PRIVATE SECTOR')
	INSERT INTO #Temp_OccupationMapping VALUES('Employed with Government Sector', 'PUBLIC SECTOR')
	INSERT INTO #Temp_OccupationMapping VALUES('Employed with Public Sector', 'PUBLIC SECTOR')
	INSERT INTO #Temp_OccupationMapping VALUES('Public Sector', 'PUBLIC SECTOR')
	INSERT INTO #Temp_OccupationMapping VALUES('Professional', 'Professional')
	INSERT INTO #Temp_OccupationMapping VALUES('SelfEmployed', 'Professional')
	INSERT INTO #Temp_OccupationMapping VALUES('SelfEmployed - Professional', 'Professional')
	INSERT INTO #Temp_OccupationMapping VALUES('SelfEmployed Professional - Architect', 'Professional')
	INSERT INTO #Temp_OccupationMapping VALUES('SelfEmployed Professional - CA/CS', 'Professional')
	INSERT INTO #Temp_OccupationMapping VALUES('SelfEmployed Professional - Doctor', 'Professional')
	INSERT INTO #Temp_OccupationMapping VALUES('SelfEmployed Professional - IT Consultant', 'Professional')
	INSERT INTO #Temp_OccupationMapping VALUES('SelfEmployed Professional - Lawyer', 'Professional')
	INSERT INTO #Temp_OccupationMapping VALUES('Service', 'Services')
	INSERT INTO #Temp_OccupationMapping VALUES('Retired', 'Retired')
	INSERT INTO #Temp_OccupationMapping VALUES('Student', 'Student')
------------------------------------------------------
	
	IF OBJECT_ID('tempdb..#Temp_CountryMapping') IS NOT NULL 
    DROP TABLE #Temp_CountryMapping
	CREATE TABLE #Temp_CountryMapping
	(
		Id INT IDENTITY(1,1) NOT NULL,
		HDFCCountryName VARCHAR(500),
		TSSCountryName VARCHAR(500),
	)
	
	INSERT INTO #Temp_CountryMapping VALUES('BOSNIA AND HERZEGOWINA', 'Bosnia And Herzegovina')
	INSERT INTO #Temp_CountryMapping VALUES('COSTA', 'Costa Rica')
	INSERT INTO #Temp_CountryMapping VALUES('COTE DIVOIRE', 'Côte D''ivoire')
	INSERT INTO #Temp_CountryMapping VALUES('CZECHOSLOVAKIA', 'Czech Republic')
	
	INSERT INTO #Temp_CountryMapping SELECT Name, Name FROM RefCountry
	----employee
	
	if object_id ('tempdb..#ActivationStatus') is not null
	Drop table #ActivationStatus

	Create table #ActivationStatus
	(TssSstatus varchar(50),
	HslAStatus varchar(50))

	Insert into #ActivationStatus values('Institution','FI')
	Insert into #ActivationStatus values('Client','NRI')

Insert into #ActivationStatus values('Client','RCL')

if object_id ('tempdb..#AccountStatus') is not null
	Drop table #AccountStatus

	Create table #AccountStatus
	(Tstatus varchar(50),
	HStatus varchar(50))

Insert into #AccountStatus values('Active','E')

Insert into #AccountStatus values('InActive','D')
Insert into #AccountStatus values('InActive','P')

if object_id ('tempdb..#PEP') is not null
	Drop table #PEP

	Create table #PEP
	(TssPEP varchar(50),
	HslPEP varchar(50))

	Insert into #PEP values('PEP','Y')
	Insert into #PEP values('Not a PEP','N')



	
	--
	
	update RefEmployee
	set Name = t.branch_manager_name,
	email = isnull(t.branch_manager_email_id,''),
	EditedOn = GETDATE(),
	LastEditedBy = 'System'
from temp_client t
	where USERNAME = t.branch_manager_code COLLATE DATABASE_DEFAULT
	
	  insert into refemployee 
	  (employeecode,
	  username,
	  name,
	  Email,
	  password,
	  ChangePasswordNextLogin,
	  mobile,
	  ParentEmployeeId,
	  addedby,
	  AddedOn,
	  LastEditedBy ,
	  EditedOn)
	select branch_manager_code,
	branch_manager_code,
	branch_manager_name,
	isnull(branch_manager_email_id,''),
	'',
	0,
	'',
	1,
	'System',
	GETDATE(),
	'Syetem',
	getdate()
	from (select  branch_manager_code,
	branch_manager_name,
	branch_manager_email_id
,
row_number ()over (partition by branch_manager_code order by branch_manager_code desc) as cnt	from temp_client
where branch_manager_code is not null and branch_manager_name is not null)t
where t.cnt = 1
AND NOT EXISTS (SELECT 1 FROM REFEMPLOYEE WHERE USERNAME = T.branch_manager_code COLLATE DATABASE_DEFAULT)


update RefEmployee
set Name = t1.dealer_name,
Email = isnull(t1.dealer_email_id,''),
EditedOn = GETDATE(),
LastEditedBy = 'System'
from temp_client t1
where USERNAME = t1.dealer_code  COLLATE DATABASE_DEFAULT

  insert into refemployee 
	  (employeecode,
	  username,
	  name,
	  Email,
	  password,
	  ChangePasswordNextLogin,
	  mobile,
	  ParentEmployeeId,
	  addedby,
	  AddedOn,
	  LastEditedBy ,
	  EditedOn)
	select dealer_code,
	dealer_Code,
	dealer_name,
	isnull(dealer_email_id,''),
	'',
	0,
	'',
	1,
	'System',
	GETDATE(),
	'Syetem',
	getdate()
	from (select  dealer_code,
	dealer_name,
	dealer_email_id
,
row_number ()over (partition by dealer_code order by dealer_code desc) as cnt	from temp_client
where dealer_code is not null and dealer_name is not null)t1
where t1.cnt = 1

AND NOT EXISTS (SELECT 1 FROM REFEMPLOYEE WHERE USERNAME = t1.dealer_code  COLLATE DATABASE_DEFAULT)
----
	
	
	IF OBJECT_ID('tempdb..#Clients') IS NOT NULL 
    DROP TABLE #Clients
    
	CREATE TABLE #Clients
    (
      RefClientDatabaseEnumId INT ,
      ClientId VARCHAR(200) ,
      RefClientId INT, 
	  DpId VARCHAR(100),
      ClientName VARCHAR(200) ,
      Pan VARCHAR(300) ,
      Dob DATETIME,
      AccountOpeningDate DATETIME,
      AccountClosingDate DATETIME,
      RefConstitutionTypeId INT, --ConstitutionType
      PAddressLine1 VARCHAR(500),
      PAddressLine2 VARCHAR(500),
      PAddressLine3 VARCHAR(500),
      PAddressCity VARCHAR(200), --PCity
      PAddressState VARCHAR(200), --PState
      PAddressCountry VARCHAR(200), --PCountry
      PAddressPin VARCHAR(50), --PPin
      CAddressLine1 VARCHAR(500),
      CAddressLine2 VARCHAR(500),
      CAddressLine3 VARCHAR(500),
      CAddressCity VARCHAR(200), --CCity
      CAddressState VARCHAR(200), --CState
      CAddressCountry VARCHAR(200), --CCountry
      CAddressPin VARCHAR(50), --CPin
      Phone1 VARCHAR(200),
      Phone2 VARCHAR(200),
      Phone3 VARCHAR(200),
      Mobile VARCHAR (200),
	  Email VARCHAR(300),
	  Gender VARCHAR(50),
	  RefBseMfOccupationTypeId INT,
	  FatherName VARCHAR(300),
	  RefIntermediaryId BIGINT, --Intermediary
	  OfficeDetailsName VARCHAR(300), --OfficeDetailsName
	  OfficeDetailsAddress VARCHAR(300), --OfficeDetailsAddress
	  OfficeDetailsPhone VARCHAR(300), --OfficeDetailsPhone
	  RefClientSpecialCategoryId INT, --SpecialCategory 
	  SecondHolderSalutationId INT, --SecondHolderSalutation
	  SecondHolderFirstName VARCHAR(100), --SecondHolderFirstName
	  SecondHolderMiddleName VARCHAR(100),
	  SecondHolderLastName VARCHAR(100),
	  SecondHolderGender VARCHAR(1),
	  SecondHolderDOB DATETIME,
	  SecondHolderPAN VARCHAR(30),
	  SecondHolderFatherOrHusbandName VARCHAR(200),
	  SecondHolderConstitutionType INT, --SecondHolderConstitutionTypea
	  ThirdHolderSalutationId INT, --ThirdHolderSalutation
	  ThirdHolderFirstName VARCHAR(100),
	  ThirdHolderMiddleName VARCHAR(100),
	  ThirdHolderLastName VARCHAR(100),
	  ThirdHolderGender VARCHAR(1),
	  ThirdHolderDOB DATETIME,
	  ThirdHolderPAN VARCHAR(30),
	  ThirdHolderFatherOrHusbandName VARCHAR(200),
	  ThirdHolderConstitutionTypeId INT, --ThirdHolderConstitutionType,
	  NomineeFirstName VARCHAR(100),
	  NomineeMiddleName VARCHAR(100),
	  NomineeLastName VARCHAR(100),
	  NomineeRelationshipWithFirstHolder VARCHAR(100),
	  NomineeRelationshipWithSecondHolder VARCHAR(100),
	  NomineeRelationshipWithThirdHolder VARCHAR(100),
	  NomineeAddressLine1 VARCHAR(500),
	  NomineeAddressLine2 VARCHAR(500),
	  NomineeAddressLine3 VARCHAR(500),
	  NomineeAddressCity VARCHAR(200),
	  NomineeAddressState  VARCHAR(200),
	  NomineeAddressRefCountryId INT,--NomineeAddressCountry
	  NomineeAddressPin VARCHAR(50),
	  NomineePhone VARCHAR(100),
	  NomineeDOB DATETIME,
	  GuardianFirstName VARCHAR(100),
	  GuardianMiddleName VARCHAR(100),
	  GuardianLastName VARCHAR(100),
	  GuardianRelationship VARCHAR(100),
	  GuardianAddressLine1 VARCHAR(500),
	  GuardianAddressLine2 VARCHAR(500),
	  GuardianAddressLine3 VARCHAR(500),
	  GuardianAddressCity VARCHAR(200),
	  GuardianAddressState VARCHAR(200),
	  GuardianAddressRefCountryId INT, --GuardianAddressCountry
	  GuardianAddressPin VARCHAR(50),
	  GuardianPhone VARCHAR(100),
	  GuradianPAN VARCHAR(10),
	  NriPisApprovalNo VARCHAR(100),
	 
	  NriForeignAddressLine1 VARCHAR(200),
	  NriForeignAddressLine2 VARCHAR(200),
	  NriForeignAddressCity VARCHAR(200),
	  NriForeignAddressState VARCHAR(200),
	  NriForeignAddressRefCountryId INT, --NriForeignAddressCountry
	  NriForeignAddressPin VARCHAR(50),
	  Aadhar VARCHAR(200),
	  RequestedBy VARCHAR(200),
	  RequestedOn DATETIME,
	  refemployeeidRm INT,
	  RefemployeeIdDealer INT,
	  DP_ID_1 VARCHAR(50),
	  DP_AC_NO1 VARCHAR(200),
	  DP_ID_2 VARCHAR(50),
	  DP_AC_NO2 VARCHAR(200),
	  bank_account_no_1 varchar(100),
	  ClientStatuisId INT,
	  PEPId INT,
	  RefClientAccountStatusId int

    )
--------------------------    
     INSERT INTO #Clients(
			RefClientId,
           RefClientDatabaseEnumId  ,
			  ClientId  ,
			  DpId,
			  ClientName  ,
			  Pan  ,
			  Dob ,
			  AccountOpeningDate ,
			  AccountClosingDate ,
			  RefConstitutionTypeId , --ConstitutionType
			  PAddressLine1 ,
			  PAddressLine2 ,
			  PAddressLine3 ,
			  PAddressCity , --PCity
			  PAddressState , --PState
			  PAddressCountry , --PCountry
			  PAddressPin , --PPin
			  CAddressLine1 ,
			  CAddressLine2 ,
			  CAddressLine3 ,
			  CAddressCity , --CCity
			  CAddressState , --CState
			  CAddressCountry , --CCountry
			  CAddressPin , --CPin
			  Phone1 ,
			  Phone2 ,
			  Phone3 ,
			  Mobile ,
			  Email ,
			  Gender ,
			  RefBseMfOccupationTypeId ,
			  FatherName ,
			  RefIntermediaryId , --ermediary
			  OfficeDetailsName , --OfficeDetailsName
			  OfficeDetailsAddress , --OfficeDetailsAddress
			  OfficeDetailsPhone , --OfficeDetailsPhone
			  RefClientSpecialCategoryId , --SpecialCategory 
			  SecondHolderSalutationId , --SecondHolderSalutation
			  SecondHolderFirstName , --SecondHolderFirstName
			  SecondHolderMiddleName ,
			  SecondHolderLastName ,
			  SecondHolderGender ,
			  SecondHolderDOB ,
			  SecondHolderPAN ,
			  SecondHolderFatherOrHusbandName ,
			  SecondHolderConstitutionType , --SecondHolderConstitutionType
			  ThirdHolderSalutationId , --ThirdHolderSalutation
			  ThirdHolderFirstName ,
			  ThirdHolderMiddleName ,
			  ThirdHolderLastName ,
			  ThirdHolderGender ,
			  ThirdHolderDOB ,
			  ThirdHolderPAN ,
			  ThirdHolderFatherOrHusbandName ,
			  ThirdHolderConstitutionTypeId,  --ThirdHolderConstitutionType,
			  NomineeFirstName ,
			  NomineeMiddleName ,
			  NomineeLastName ,
			  NomineeRelationshipWithFirstHolder ,
			  NomineeRelationshipWithSecondHolder ,
			  NomineeRelationshipWithThirdHolder ,
			  NomineeAddressLine1 ,
			  NomineeAddressLine2 ,
			  NomineeAddressLine3 ,
			  NomineeAddressCity ,
			  NomineeAddressState  ,
			  NomineeAddressRefCountryId ,--NomineeAddressCountry
			  NomineeAddressPin ,
			  NomineePhone ,
			  NomineeDOB ,
			  GuardianFirstName ,
			  GuardianMiddleName ,
			  GuardianLastName ,
			  GuardianRelationship ,
			  GuardianAddressLine1 ,
			  GuardianAddressLine2 ,
			  GuardianAddressLine3 ,
			  GuardianAddressCity ,
			  GuardianAddressState ,
			  GuardianAddressRefCountryId , --GuardianAddressCountry
			  GuardianAddressPin ,
			  GuardianPhone ,
			  GuradianPAN ,
			  NriPisApprovalNo ,
			  --NriPisApprovalDate ,
			  NriForeignAddressLine1 ,
			  NriForeignAddressLine2 ,
			  NriForeignAddressCity ,
			  NriForeignAddressState ,
			  NriForeignAddressRefCountryId , --NriForeignAddressCountry
			  NriForeignAddressPin ,
			  RequestedBy ,
			  RequestedOn ,
			  refemployeeidRm,
			  RefemployeeIdDealer,
			  DP_ID_1,
			  DP_AC_NO1,
			  DP_ID_2,
			  DP_AC_NO2,
			  bank_account_no_1,
			  ClientStatuisId,
			  PEPId,
			  RefClientAccountStatusId

    )
		SELECT	
			cl.RefClientId,
			@DatabaseId AS RefClientDatabaseEnumId,
			LTRIM(RTRIM(vCl.CLIENTID)) as ClientId,
			--LTRIM(RTRIM(REPLACE(vCl.DPID,'IN',''))),
			NULL as DpId,
			LTRIM(RTRIM(vCl.CLIENTNAME)) as ClientName,
			LTRIM(RTRIM(vCl.PAN)) as Pan,
			LTRIM(RTRIM(vCl.[to_char(DateOfBirth)])) as Dob,
			vCl.[to_char(ACCOUNTOPENINGDATE)] as AccountOpeningDate,
			vCl.[to_char(ACCOUNTCLOSINGDATE)] as AccountClosingDate,
			refconst.RefConstitutionTypeId as RefConstitutionTypeId,
			LTRIM(RTRIM(vCl.PADDRESSLINE1)) as PAddressLine1,
			LTRIM(RTRIM(vCl.PADDRESSLINE2)) as PAddressLine2,
			LTRIM(RTRIM(vCl.PADDRESSLINE3)) as PAddressLine3,
			LTRIM(RTRIM(vCl.PCITY)) as PAddressCity ,
			LTRIM(RTRIM(vCl.PSTATE)) as PAddressState,
			LTRIM(RTRIM(vCl.PCOUNTRY)) as PAddressCountry,
			LTRIM(RTRIM(vCl.PPIN)) as PAddressPin,
			LTRIM(RTRIM(vCl.CADDRESSLINE1)) as CAddressLine1,
			LTRIM(RTRIM(vCl.CADDRESSLINE2)) as CAddressLine2,
			LTRIM(RTRIM(vCl.CADDRESSLINE3)) as CAddressLine3,
			LTRIM(RTRIM(vCl.CCITY)) as CAddressCity,
			LTRIM(RTRIM(vCl.CSTATE)) as CAddressState,
			LTRIM(RTRIM(vCl.CCOUNTRY)) as CAddressCountry,
			LTRIM(RTRIM(vCl.CPIN)) as CAddressPin,
			LTRIM(RTRIM(vCl.PHONE1)) as Phone1,
			LTRIM(RTRIM(vCl.PHONE2)) as Phone2,
			LTRIM(RTRIM(vCl.PHONE3)) as Phone3,
			LTRIM(RTRIM(vCl.MOBILE)) as Mobile,
			LTRIM(RTRIM(vCl.EMAIL)) as Email,
			LTRIM(RTRIM(vCl.GENDER)) as Gender,
			occ.RefBseMfOccupationTypeId as RefBseMfOccupationTypeId,
			LTRIM(RTRIM(vCl.FATHERNAME)) as FatherName,
			intmed.RefIntermediaryId as RefIntermediaryId, 
			LTRIM(RTRIM(vCl.OFFICEDETAILSNAME)) as OfficeDetailsName,
			LTRIM(RTRIM(vCl.OFFICEDETAILSADDRESS)) as OfficeDetailsAddress,
			LTRIM(RTRIM(vCl.OFFICEDETAILSPHONE)) as OfficeDetailsPhone,
			SPLCAT.RefClientSpecialCategoryId as RefClientSpecialCategoryId,--LTRIM(RTRIM(vCl.SPECIALCATEGORY)),
			LTRIM(RTRIM(vCl.SECONDHOLDERSALUTATION)) as SecondHolderSalutationId,
			LTRIM(RTRIM(vCl.SECONDHOLDERFIRSTNAME)) as SecondHolderFirstName,
			LTRIM(RTRIM(vCl.SECONDHOLDERMIDDLENAME)) as SecondHolderMiddleName,
			LTRIM(RTRIM(vCl.SECONDHOLDERLASTNAME))as SecondHolderLastName,
			LTRIM(RTRIM(vCl.SECONDHOLDERGENDER)) as SecondHolderGender,
			vCl.[to_char(SECONDHOLDERDOB)] as SecondHolderDOB,
			LTRIM(RTRIM(vCl.SECONDHOLDERPAN)) as SecondHolderPAN,
			LTRIM(RTRIM(vCl.SECONDHOLDERFATHERORHUSBANDNM)) as SecondHolderFatherOrHusbandName,
			LTRIM(RTRIM(vCl.SECONDHOLDERCONSTITUTIONTYPE))as SecondHolderConstitutionType,
			LTRIM(RTRIM(vCl.THIRDHOLDERSALUTATION))as ThirdHolderSalutationId,
			LTRIM(RTRIM(vCl.THIRDHOLDERFIRSTNAME)) as ThirdHolderFirstName,
			LTRIM(RTRIM(vCl.THIRDHOLDERMIDDLENAME)) as ThirdHolderMiddleName,
			LTRIM(RTRIM(vCl.THIRDHOLDERLASTNAME)) as  ThirdHolderLastName,
			LTRIM(RTRIM(vCl.THIRDHOLDERGENDER)) as ThirdHolderGender,
			vCl.[to_char(THIRDHOLDERDOB)] as ThirdHolderDOB,
			LTRIM(RTRIM(vCl.THIRDHOLDERPAN)) as ThirdHolderPAN,
			LTRIM(RTRIM(vCl.THIRDHOLDERFATHERORHUSBANDNAME)) as ThirdHolderFatherOrHusbandName,
			LTRIM(RTRIM(vCl.THIRDHOLDERCONSTITUTIONTYPE)) as ThirdHolderConstitutionTypeId,
			LTRIM(RTRIM(vCl.NOMINEEFIRSTNAME)) as NomineeFirstName,
			LTRIM(RTRIM(vCl.NOMINEEMIDDLENAME)) as NomineeMiddleName,
			LTRIM(RTRIM(vCl.NOMINEELASTNAME)) as NomineeLastName,
			LTRIM(RTRIM(vCl.NOMINEERELATIONSHIPWITHFIRSTHO)) as NomineeRelationshipWithFirstHolder,
			LTRIM(RTRIM(vCl.NOMINEERELATIONWITHSECONDHO)) as NomineeRelationshipWithSecondHolder,
			LTRIM(RTRIM(vCl.NOMINEERELATIONSHIPWITHTHIRDHO)) as NomineeRelationshipWithThirdHolder,
			LTRIM(RTRIM(vCl.NOMINEEADDRESSLINE1)) as NomineeAddressLine1,
			LTRIM(RTRIM(vCl.NOMINEEADDRESSLINE2)) as NomineeAddressLine2,
			LTRIM(RTRIM(vCl.NOMINEEADDRESSLINE3)) as NomineeAddressLine3,
			LTRIM(RTRIM(vCl.NOMINEEADDRESSCITY)) as NomineeAddressCity,
			LTRIM(RTRIM(vCl.NOMINEEADDRESSSTATE)) as NomineeAddressState,
			LTRIM(RTRIM(vCl.NOMINEEADDRESSCOUNTRY)) as NomineeAddressRefCountryId,
			LTRIM(RTRIM(vCl.NOMINEEADDRESSPIN)) as NomineeAddressPin,
			LTRIM(RTRIM(vCl.NOMINEEPHONE)) as NomineePhone,
			null as [to_char(NomineeDOB)],--vCl.NOMINEEDOB,
			LTRIM(RTRIM(vCl.GUARDIANFIRSTNAME)) as GuardianFirstName,
			LTRIM(RTRIM(vCl.GUARDIANMIDDLENAME)) as GuardianMiddleName,
			LTRIM(RTRIM(vCl.GUARDIANLASTNAME)) as GuardianLastName,
			LTRIM(RTRIM(vCl.GUARDIANRELATIONSHIP)) as GuardianRelationship,
			LTRIM(RTRIM(vCl.GUARDIANADDRESSLINE1)) as GuardianAddressLine1,
			LTRIM(RTRIM(vCl.GUARDIANADDRESSLINE2)) as GuardianAddressLine2,
			LTRIM(RTRIM(vCl.GUARDIANADDRESSLINE3)) as GuardianAddressLine3,
			LTRIM(RTRIM(vCl.GUARDIANADDRESSCITY)) as GuardianAddressCity,
			LTRIM(RTRIM(vCl.GUARDIANADDRESSSTATE)) as GuardianAddressState,
			LTRIM(RTRIM(vCl.GUARDIANADDRESSCOUNTRY)) as GuardianAddressRefCountryId,
			LTRIM(RTRIM(vCl.GUARDIANADDRESSPIN)) as GuardianAddressPin,
			LTRIM(RTRIM(vCl.GUARDIANPHONE)) as GuardianPhone,
			LTRIM(RTRIM(vCl.GURADIANPAN)) as GuradianPAN,
			LTRIM(RTRIM(vCl.NRIPISAPPROVALNO)) as NriPisApprovalNo,
			--null as NriPisApprovalDate,--vCl.NRIPISAPPROVALDATE,
			LTRIM(RTRIM(vCl.NRIFOREIGNADDRESSLINE1)) as NriForeignAddressLine1,
			LTRIM(RTRIM(vCl.NRIFOREIGNADDRESSLINE2)) as NriForeignAddressLine2,
			LTRIM(RTRIM(vCl.NRIFOREIGNADDRESSCITY)) as NriForeignAddressCity,
			LTRIM(RTRIM(vCl.NRIFOREIGNADDRESSSTATE)) as NriForeignAddressState,
			LTRIM(RTRIM(vCl.NRIFOREIGNADDRESSCOUNTRY))as NriForeignAddressRefCountryId,
			LTRIM(RTRIM(vCl.NRIFOREIGNADDRESSPIN)) as NriForeignAddressPin,
			'System' as RequestedBy, 
		GETDATE() as RequestedOn,
		rm.RefEmployeeId,
		dealer.RefEmployeeId,
		 LEFT(LTRIM(RTRIM(vCl.DP_ID_1)),6),
			  LTRIM(RTRIM(vCl.DP_AC_NO1)),
			  lEFT(LTRIM(RTRIM(vCl.DP_ID_2)),6),
			  LTRIM(RTRIM(vCl.DP_AC_NO2)),
			  ltrim(rtrim(vCl.bank_account_no_1)),
			  clientstatus.RefClientStatusId,
			  pep1.RefPEPId,
			  clientstatus1.RefClientAccountStatusId
		
	FROM temp_client vCl 
	LEFT  JOIN
		RefClient cl ON cl.RefClientDatabaseENumId = @DatabaseId AND vCl.ClientId COLLATE DATABASE_DEFAULT = cl.ClientId
		LEFT JOIN #Temp_OccupationMapping occupationMapping ON occupationMapping.HDFCName = vcl.occupation
		LEFT JOIN RefBseMfOccupationType occ ON occ.Name = occupationMapping.TssName COLLATE DATABASE_DEFAULT
		LEFT  JOIN #Temp_ConstitutionTypeMapping const on const.HDFCCode = vCl.CONSTITUTIONTYPE
		left join RefConstitutionType refconst on refconst.Name = const.TSSName COLLATE DATABASE_DEFAULT
		LEFT  JOIN RefIntermediary intmed ON vCl.INTERMEDIARY = intmed.IntermediaryCode COLLATE DATABASE_DEFAULT
		LEFT  JOIN RefClientSpecialCategory Splcat ON  vCl.SPECIALCATEGORY  collate database_default= splcat.name COLLATE DATABASE_DEFAULT
		Left join refemployee rm on rm.EmployeeCode = vCl.branch_manager_code collate database_default
		Left join refemployee dealer on dealer.employeecode collate database_default= vCl.dealer_code collate database_default
		Left join #ActivationStatus sts on sts.HslAStatus collate database_default = vCl.Refclientactivationstatus collate database_default
		Left join RefClientStatus clientstatus on clientstatus.name collate database_default= sts.TssSstatus collate database_default
		Left join #PEP pepe  on pepe.HslPEP collate database_default= vCl.pep collate database_default
		Left join RefPEP pep1 on pep1.name collate database_default= pepe.TssPEP	collate database_default
		left join #AccountStatus asts on asts.HStatus = vCl.client_account_status collate database_default
		Left join RefClientAccountStatus clientstatus1 on clientstatus1.name = asts.Tstatus collate database_default and clientstatus1.RefClientDatabaseENumId = @DatabaseId
	WHERE 1=1


	;
	--and vCl.clientid = '252425';

	WITH cte 
	as 
	(select ROW_NUMBER() OVER (PARTITION BY  RefClientDatabaseEnumId,ClientId ORDER BY RefclientId DESC) as cnt ,* 
	from #clients 
	--where clientid = '310129'
	)
	DELETE FROM cte
	WHERE cte.cnt > 1

	--select * from #clients
	DECLARE @CurrentDate DATETIME
	SET @CurrentDate = ''

	
	UPDATE  rClient
	SET		  rClient.[Name] =  client.ClientName,
			  rClient.Pan = client.Pan ,
			  rClient.Dob = client.Dob ,
			  rClient.AccountOpeningDate  = client.AccountOpeningDate,
			  rClient.AccountClosingDate= client.AccountClosingDate ,
			  rClient.RefConstitutionTypeId = client.RefConstitutionTypeId, --ConstitutionType
			  rClient.PAddressLine1 = client.PAddressLine1,
			  rClient.PAddressLine2= client.PAddressLine2 ,
			  rClient.PAddressLine3 = client.PAddressLine3,
			  rClient.PAddressCity = client.PAddressCity , --PCity
			  rClient.PAddressState = client.PAddressState,--PState
			  rClient.PAddressCountry= client.PAddressCountry , --PCountry
			  rClient.PAddressPin = client.PAddressPin , --PPin
			  rClient.CAddressLine1 = client.CAddressLine1 ,
			  rClient.CAddressLine2 = client.CAddressLine2,
			  rClient.CAddressLine3 = client.CAddressLine3,
			  rClient.CAddressCity = client.CAddressCity, --CCity
			  rClient.CAddressState = client.CAddressState, --CState
			  rClient.CAddressCountry = client.CAddressCountry, --CCountry
			  rClient.CAddressPin = client.CAddressPin, --CPin
			  rClient.Phone1 = client.Phone1,
			  rClient.Phone2 = client.Phone2 ,
			  rClient.Phone3 = client.Phone3,
			  rClient.Mobile = client.Mobile,
			  rClient.Email = client.Email,
			  rClient.Gender = client.Gender,
			  rClient.RefBseMfOccupationTypeId = client.RefBseMfOccupationTypeId,
			  rClient.FatherName = client.FatherName,
			  rClient.RefIntermediaryId = client.RefIntermediaryId, --ermediary
			  rClient.EmployerName = client.OfficeDetailsName,--OfficeDetailsName
			  rClient.EmployerAddress= client.OfficeDetailsAddress , --OfficeDetailsAddress
			  rClient.EmployerPhone = client.OfficeDetailsPhone, --OfficeDetailsPhone
			  rClient.RefClientSpecialCategoryId = client.RefClientSpecialCategoryId, --SpecialCategory 
			  rClient.SecondHolderRefSalutationId = client.SecondHolderSalutationId, --SecondHolderSalutation
			  rClient.SecondHolderFirstName = client.SecondHolderFirstName, --SecondHolderFirstName
			  rClient.SecondHolderMiddleName = client.SecondHolderMiddleName,
			  rClient.SecondHolderLastName = client.SecondHolderLastName,
			  rClient.SecondHolderGender = client.SecondHolderGender,
			  rClient.SecondHolderDOB = client.SecondHolderDOB,
			  rClient.SecondHolderPAN = client.SecondHolderPAN,
			  rClient.SecondHolderFatherOrHusbandName = client.SecondHolderFatherOrHusbandName,
			  rClient.SecondHolderRefConstitutionTypeId = client.SecondHolderConstitutionType, --SecondHolderConstitutionType
			  rClient.ThirdHolderSalutationId = client.ThirdHolderSalutationId, --ThirdHolderSalutation
			  rClient.ThirdHolderFirstName = client.ThirdHolderFirstName,
			  rClient.ThirdHolderMiddleName = client.ThirdHolderMiddleName,
			  rClient.ThirdHolderLastName = client.ThirdHolderLastName,
			  rClient.ThirdHolderGender = client.ThirdHolderGender,
			  rClient.ThirdHolderDOB = client.ThirdHolderDOB,
			  rClient.ThirdHolderPAN = client.ThirdHolderPAN,
			  rClient.ThirdHolderFatherOrHusbandName = client.ThirdHolderFatherOrHusbandName,
			  rClient.ThirdHoldeRefConstitutionTypeId = client.ThirdHolderConstitutionTypeId,  --ThirdHolderConstitutionType,
			  rClient.NomineeFirstName = client.NomineeFirstName,
			  rClient.NomineeMiddleName = client.NomineeMiddleName,
			  rClient.NomineeLastName = client.NomineeLastName,
			  rClient.NomineeRelationshipWithFirstHolder = client.NomineeRelationshipWithFirstHolder,
			  rClient.NomineeRelationshipWithSecondHolder = client.NomineeRelationshipWithSecondHolder ,
			  rClient.NomineeRelationshipWithThirdHolder = client.NomineeRelationshipWithThirdHolder,
			  rClient.NomineeAddressLine1 = client.NomineeAddressLine1,
			  rClient.NomineeAddressLine2 = client.NomineeAddressLine2,
			  rClient.NomineeAddressLine3 = client.NomineeAddressLine3 ,
			  rClient.NomineeAddressCity = client.NomineeAddressCity,
			  rClient.NomineeAddressState = client.NomineeAddressState ,
			  rClient.NomineeAddressRefCountryId = client.NomineeAddressRefCountryId,--NomineeAddressCountry
			  rClient.NomineeAddressPin = client.NomineeAddressPin,
			  rClient.NomineePhone = client.NomineePhone,
			  rClient.NomineeDOB = client.NomineeDOB,
			  rClient.GuardianFirstName = client.GuardianFirstName,
			  rClient.GuardianMiddleName = client.GuardianMiddleName,
			  rClient.GuardianLastName = client.GuardianLastName,
			  rClient.GuardianRelationship = client.GuardianRelationship,
			  rClient.GuardianAddressLine1 = client.GuardianAddressLine1,
			  rClient.GuardianAddressLine2 = client.GuardianAddressLine2,
			  rClient.GuardianAddressLine3 = client.GuardianAddressLine3,
			  rClient.GuardianAddressCity = client.GuardianAddressCity,
			  rClient.GuardianAddressState = client.GuardianAddressState,
			  rClient.GuardianAddressRefCountryId = client.GuardianAddressRefCountryId, --GuardianAddressCountry
			  rClient.GuardianAddressPin = client.GuardianAddressPin,
			  rClient.GuardianPhone = client.GuardianPhone,
			  rClient.GuradianPAN = client.GuradianPAN,
			  rClient.NriPisApprovalNo = client.NriPisApprovalNo,
			  --rClient.NriPisApprovalDate = client.NriPisApprovalDate,
			  rClient.NriForeignAddressLine1 = client.NriForeignAddressLine1,
			  rClient.NriForeignAddressLine2 = client.NriForeignAddressLine2,
			  rClient.NriForeignAddressCity = client.NriForeignAddressCity,
			  rClient.NriForeignAddressState = client.NriForeignAddressState,
			  rClient.NriForeignAddressRefCountryId = client.NriForeignAddressRefCountryId, --NriForeignAddressCountry
			  rClient.NriForeignAddressPin = client.NriForeignAddressPin,
			  rClient.BankAccNo = client.bank_account_no_1,
			  rclient.RefClientStatusId = client.ClientStatuisId,
			  rclient.RefPEPId = client.pepid,
				 --Aadhar 
			  rClient.LastEditedBy= client.RequestedBy,
			  rClient.EditedOn = client.RequestedOn,
			  rclient.RefClientAccountStatusId = client.RefClientAccountStatusId
	FROM  dbo.RefClient rClient
	INNER JOIN #Clients client ON rClient.RefClientId = client.RefClientId
	WHERE ( 
			ISNULL(rClient.[Name],'') <> ISNULL(client.ClientName,'') OR
			ISNULL(rClient.Pan,'') <> ISNULL(client.Pan,'') OR
			ISNULL(rClient.Dob,@CurrentDate) <> ISNULL(client.Dob,@CurrentDate)OR
			ISNULL(rClient.AccountOpeningDate, @CurrentDate)<> ISNULL(client.AccountOpeningDate, @CurrentDate) OR
			ISNULL(rClient.AccountClosingDate, @CurrentDate) <> ISNULL(client.AccountClosingDate, @CurrentDate)OR
			ISNULL(rClient.RefConstitutionTypeId, 0) <> ISNULL(client.RefConstitutionTypeId, 0)OR

			ISNULL(rClient.PAddressLine1,'') <> ISNULL(client.PAddressLine1,'')OR
			ISNULL(rClient.PAddressLine2,'') <> ISNULL(client.PAddressLine2,'')OR
			ISNULL(rClient.PAddressLine3,'') <> ISNULL(client.PAddressLine3,'')OR
			ISNULL(rClient.PAddressCity,'') <> ISNULL(client.PAddressCity,'')OR
			ISNULL(rClient.PAddressState,'') <> ISNULL(client.PAddressState,'')OR
			ISNULL(rClient.PAddressCountry,'') <> ISNULL(client.PAddressCountry,'')OR
			ISNULL(rClient.PAddressPin,'') <> ISNULL(client.PAddressPin,'')OR

			ISNULL(rClient.CAddressLine1,'') <> ISNULL(client.CAddressLine1,'')OR
			ISNULL(rClient.CAddressLine2,'') <> ISNULL(client.CAddressLine2,'')OR
			ISNULL(rClient.CAddressLine3,'') <> ISNULL(client.CAddressLine3,'')OR
			ISNULL(rClient.CAddressCity,'') <> ISNULL(client.CAddressCity,'')OR
			ISNULL(rClient.CAddressState,'') <> ISNULL(client.CAddressState,'')OR
			ISNULL(rClient.CAddressCountry,'') <> ISNULL(client.CAddressCountry,'')OR
			ISNULL(rClient.CAddressPin,'') <> ISNULL(client.CAddressPin,'')OR

			ISNULL(rClient.Phone1,'') <> ISNULL(client.Phone1,'')OR
			ISNULL(rClient.Phone2,'') <> ISNULL(client.Phone2,'')OR
			ISNULL(rClient.Phone3,'') <> ISNULL(client.Phone3,'')OR
			ISNULL(rClient.Mobile,'') <> ISNULL(client.Mobile,'')OR
			ISNULL(rClient.Email,'') <> ISNULL(client.Email,'')OR
			ISNULL(rClient.Gender,'') <> ISNULL(client.Gender,'')OR
			ISNULL(rClient.RefBseMfOccupationTypeId,0) <> ISNULL(client.RefBseMfOccupationTypeId, 0)OR
			ISNULL(rClient.FatherName,'') <> ISNULL(client.FatherName,'')OR
			ISNULL(rClient.RefIntermediaryId,0) <> ISNULL(client.RefIntermediaryId, 0)OR
			ISNULL(rClient.EmployerName,'') <> ISNULL(client.OfficeDetailsName,'')OR
			ISNULL(rClient.EmployerAddress,'') <> ISNULL(client.OfficeDetailsAddress,'')OR
			ISNULL(rClient.EmployerPhone,'') <> ISNULL(client.OfficeDetailsPhone,'')OR
			ISNULL(rClient.RefClientSpecialCategoryId,0) <> ISNULL(client.RefClientSpecialCategoryId, 0)OR
			ISNULL(rClient.SecondHolderRefSalutationId,0) <> ISNULL(client.SecondHolderSalutationId, 0)OR
			
			ISNULL(rClient.SecondHolderFirstName,'') <> ISNULL(client.SecondHolderFirstName,'')OR
			ISNULL(rClient.SecondHolderMiddleName,'') <> ISNULL(client.SecondHolderMiddleName,'')OR
			ISNULL(rClient.SecondHolderLastName,'') <> ISNULL(client.SecondHolderLastName,'')OR
			ISNULL(rClient.SecondHolderGender,'') <> ISNULL(client.SecondHolderGender,'')OR
			ISNULL(rClient.SecondHolderDOB, @CurrentDate) <> ISNULL(client.SecondHolderDOB, @CurrentDate)OR
			ISNULL(rClient.SecondHolderPAN,'') <> ISNULL(client.SecondHolderPAN,'')OR
			ISNULL(rClient.SecondHolderFatherOrHusbandName,'') <> ISNULL(client.SecondHolderFatherOrHusbandName,'')OR
			ISNULL(rClient.SecondHolderRefConstitutionTypeId,0) <> ISNULL(client.SecondHolderConstitutionType,0)OR
			
			ISNULL(rClient.ThirdHolderSalutationId,0) <> ISNULL(client.ThirdHolderSalutationId,0)OR
			ISNULL(rClient.ThirdHolderFirstName,'') <> ISNULL(client.ThirdHolderFirstName,'')OR
			ISNULL(rClient.ThirdHolderMiddleName,'') <> ISNULL(client.ThirdHolderMiddleName,'')OR
			ISNULL(rClient.ThirdHolderLastName,'') <> ISNULL(client.ThirdHolderLastName,'')OR
			ISNULL(rClient.ThirdHolderGender,'') <> ISNULL(client.ThirdHolderGender,'')OR
			ISNULL(rClient.ThirdHolderDOB, @CurrentDate) <> ISNULL(client.ThirdHolderDOB, @CurrentDate)OR
			ISNULL(rClient.ThirdHolderPAN,'') <> ISNULL(client.ThirdHolderPAN,'')OR
			ISNULL(rClient.ThirdHolderFatherOrHusbandName,'') <> ISNULL(client.ThirdHolderFatherOrHusbandName,'')OR
			ISNULL(rClient.ThirdHoldeRefConstitutionTypeId,0) <> ISNULL(client.ThirdHolderConstitutionTypeId,0)OR
			
			ISNULL(rClient.NomineeFirstName,'') <> ISNULL(client.NomineeFirstName,'')OR
			ISNULL(rClient.NomineeMiddleName,'') <> ISNULL(client.NomineeMiddleName,'')OR
			ISNULL(rClient.NomineeLastName,'') <> ISNULL(client.NomineeLastName,'')OR
			ISNULL(rClient.NomineeRelationshipWithFirstHolder,'') <> ISNULL(client.NomineeRelationshipWithFirstHolder,'')OR
			ISNULL(rClient.NomineeRelationshipWithSecondHolder,'') <> ISNULL(client.NomineeRelationshipWithSecondHolder,'')OR
			ISNULL(rClient.NomineeRelationshipWithThirdHolder,'') <> ISNULL(client.NomineeRelationshipWithThirdHolder,'')OR
			ISNULL(rClient.NomineeAddressLine1,'') <> ISNULL(client.NomineeAddressLine1,'')OR
			ISNULL(rClient.NomineeAddressLine2,'') <> ISNULL(client.NomineeAddressLine2,'')OR
			ISNULL(rClient.NomineeAddressLine3,'') <> ISNULL(client.NomineeAddressLine3,'')OR
			ISNULL(rClient.NomineeAddressCity,'') <> ISNULL(client.NomineeAddressCity,'')OR
			ISNULL(rClient.NomineeAddressState,'') <> ISNULL(client.NomineeAddressState,'')OR
			ISNULL(rClient.NomineeDOB, @CurrentDate) <> ISNULL(client.NomineeDOB, @CurrentDate)OR
			ISNULL(rClient.NomineeAddressPin,'') <> ISNULL(client.NomineeAddressPin,'')OR
			ISNULL(rClient.NomineePhone,'') <> ISNULL(client.NomineePhone,'')OR
			ISNULL(rClient.NomineeAddressRefCountryId,0) <> ISNULL(client.NomineeAddressRefCountryId,0)OR
			
			ISNULL(rClient.GuardianFirstName,'') <> ISNULL(client.GuardianFirstName,'')OR
			ISNULL(rClient.GuardianMiddleName,'') <> ISNULL(client.GuardianMiddleName,'')OR
			ISNULL(rClient.GuardianLastName,'') <> ISNULL(client.GuardianLastName,'')OR
			ISNULL(rClient.GuardianRelationship,'') <> ISNULL(client.GuardianRelationship,'')OR
			ISNULL(rClient.GuardianAddressLine1 ,'') <> ISNULL(client.GuardianAddressLine1 ,'')OR
			ISNULL(rClient.GuardianAddressLine2,'') <> ISNULL(client.GuardianAddressLine2,'')OR
			ISNULL(rClient.GuardianAddressLine3,'') <> ISNULL(client.GuardianAddressLine3,'')OR
			ISNULL(rClient.GuardianAddressCity,'') <> ISNULL(client.GuardianAddressCity,'')OR
			ISNULL(rClient.GuardianAddressState,'') <> ISNULL(client.GuardianAddressState,'')OR
			ISNULL(rClient.GuradianPAN,'') <> ISNULL(client.GuradianPAN,'')OR
			ISNULL(rClient.GuardianAddressPin,'') <> ISNULL(client.GuardianAddressPin,'')OR
			ISNULL(rClient.GuardianPhone,'') <> ISNULL(client.GuardianPhone,'')OR
			ISNULL(rClient.GuardianAddressRefCountryId,0) <> ISNULL(client.GuardianAddressRefCountryId,0)OR
			
			ISNULL(rClient.NriPisApprovalNo,'') <> ISNULL(client.NriPisApprovalNo,'')OR
			ISNULL(rClient.NriForeignAddressLine1,'') <> ISNULL(client.NriForeignAddressLine1,'')OR
			ISNULL(rClient.NriForeignAddressLine2,'') <> ISNULL(client.NriForeignAddressLine2,'')OR
			ISNULL(rClient.NriForeignAddressCity,'') <> ISNULL(client.NriForeignAddressCity,'')OR
			ISNULL(rClient.NriForeignAddressState ,'') <> ISNULL(client.NriForeignAddressState ,'')OR
			ISNULL(rClient.NriForeignAddressPin,'') <> ISNULL(client.NriForeignAddressPin,'')OR
			ISNULL(rClient.BankAccNo,'') <> ISNULL(client.bank_account_no_1,'')OR
			ISNULL(rClient.RefClientStatusId,0) <> ISNULL(client.ClientStatuisId,0)OR
			ISNULL(rClient.NriForeignAddressRefCountryId,0) <> ISNULL(client.NriForeignAddressRefCountryId,0)OR
			ISNULL(rClient.RefClientAccountStatusId,0) <> ISNULL(client.RefClientAccountStatusId,0)
			) 

	INSERT INTO RefClient(
	RefClientDatabaseEnumId  ,
			  ClientId  ,
			  DpId,
			  Name  ,
			  Pan  ,
			  Dob ,
			  AccountOpeningDate ,
			  AccountClosingDate ,
			  RefConstitutionTypeId , --ConstitutionType
			  PAddressLine1 ,
			  PAddressLine2 ,
			  PAddressLine3 ,
			  PAddressCity , --PCity
			  PAddressState , --PState
			  PAddressCountry , --PCountry
			  PAddressPin , --PPin
			  CAddressLine1 ,
			  CAddressLine2 ,
			  CAddressLine3 ,
			  CAddressCity , --CCity
			  CAddressState , --CState
			  CAddressCountry , --CCountry
			  CAddressPin , --CPin
			  Phone1 ,
			  Phone2 ,
			  Phone3 ,
			  Mobile ,
			  Email ,
			  Gender ,
			  RefBseMfOccupationTypeId ,
			  FatherName ,
			  RefIntermediaryId , --ermediary
			 EmployerName,--OfficeDetailsName
			 EmployerAddress , --OfficeDetailsAddress
			  EmployerPhone , --OfficeDetailsPhone
			  RefClientSpecialCategoryId , --SpecialCategory 
			  SecondHolderRefSalutationId , --SecondHolderSalutation
			  SecondHolderFirstName , --SecondHolderFirstName
			  SecondHolderMiddleName ,
			  SecondHolderLastName ,
			  SecondHolderGender ,
			  SecondHolderDOB ,
			  SecondHolderPAN ,
			  SecondHolderFatherOrHusbandName ,
			  SecondHolderRefConstitutionTypeId , --SecondHolderConstitutionType
			  ThirdHolderSalutationId , --ThirdHolderSalutation
			  ThirdHolderFirstName ,
			  ThirdHolderMiddleName ,
			  ThirdHolderLastName ,
			  ThirdHolderGender ,
			  ThirdHolderDOB ,
			  ThirdHolderPAN ,
			  ThirdHolderFatherOrHusbandName ,
			  ThirdHoldeRefConstitutionTypeId,  --ThirdHolderConstitutionType,
			  NomineeFirstName ,
			  NomineeMiddleName ,
			  NomineeLastName ,
			  NomineeRelationshipWithFirstHolder ,
			  NomineeRelationshipWithSecondHolder ,
			  NomineeRelationshipWithThirdHolder ,
			  NomineeAddressLine1 ,
			  NomineeAddressLine2 ,
			  NomineeAddressLine3 ,
			  NomineeAddressCity ,
			  NomineeAddressState  ,
			  NomineeAddressRefCountryId ,--NomineeAddressCountry
			  NomineeAddressPin ,
			  NomineePhone ,
			  NomineeDOB ,
			  GuardianFirstName ,
			  GuardianMiddleName ,
			  GuardianLastName ,
			  GuardianRelationship ,
			  GuardianAddressLine1 ,
			  GuardianAddressLine2 ,
			  GuardianAddressLine3 ,
			  GuardianAddressCity ,
			  GuardianAddressState ,
			  GuardianAddressRefCountryId , --GuardianAddressCountry
			  GuardianAddressPin ,
			  GuardianPhone ,
			  GuradianPAN ,
			  NriPisApprovalNo ,
			  --		 NriPisApprovalDate ,
			  NriForeignAddressLine1 ,
			  NriForeignAddressLine2 ,
			  NriForeignAddressCity ,
			  NriForeignAddressState ,
			  NriForeignAddressRefCountryId , --NriForeignAddressCountry
			  NriForeignAddressPin ,
			  BankAccNo,
			  RefClientStatusId,
			  RefPEPId,
			  --Aadhar ,
			  AddedBy ,
			  AddedOn ,
			  LastEditedBy,
			  EditedOn,
			  RefClientAccountStatusId
	) 
	

SELECT 
		  client.RefClientDatabaseEnumId ,
		client.ClientId ,
		client.DpId,
		client.ClientName ,
		client.Pan ,
		client.Dob ,
		client.AccountOpeningDate ,
		client.AccountClosingDate ,
		client.RefConstitutionTypeId , --ConstitutionType
		client.PAddressLine1 ,
		client.PAddressLine2 ,
		client.PAddressLine3 ,
		client.PAddressCity , --PCity
		client.PAddressState , --PState
		client.PAddressCountry , --PCountry
		client.PAddressPin , --PPin
		client.CAddressLine1 ,
		client.CAddressLine2 ,
		client.CAddressLine3 ,
		client.CAddressCity , --CCity
		client.CAddressState , --CState
		client.CAddressCountry , --CCountry
		client.CAddressPin , --CPin
		client.Phone1 ,
		client.Phone2 ,
		client.Phone3 ,
		client.Mobile ,
		client.Email ,
		client.Gender ,
		client.RefBseMfOccupationTypeId ,
		client.FatherName ,
		client.RefIntermediaryId , --ermediary
		client.OfficeDetailsName , --OfficeDetailsName
		client.OfficeDetailsAddress , --OfficeDetailsAddress
		client.OfficeDetailsPhone , --OfficeDetailsPhone
		client.RefClientSpecialCategoryId , --SpecialCategory 
		client.SecondHolderSalutationId , --SecondHolderSalutation
		client.SecondHolderFirstName , --SecondHolderFirstName
		client.SecondHolderMiddleName ,
		client.SecondHolderLastName ,
		client.SecondHolderGender ,
		client.SecondHolderDOB ,
		client.SecondHolderPAN ,
		client.SecondHolderFatherOrHusbandName ,
		client.SecondHolderConstitutionType , --SecondHolderConstitutionType
		client.ThirdHolderSalutationId , --ThirdHolderSalutation
		client.ThirdHolderFirstName ,
		client.ThirdHolderMiddleName ,
		client.ThirdHolderLastName ,
		client.ThirdHolderGender ,
		client.ThirdHolderDOB ,
		client.ThirdHolderPAN ,
		client.ThirdHolderFatherOrHusbandName ,
		client.ThirdHolderConstitutionTypeId,  --ThirdHolderConstitutionType,
		client.NomineeFirstName ,
		client.NomineeMiddleName ,
		client.NomineeLastName ,
		client.NomineeRelationshipWithFirstHolder ,
		client.NomineeRelationshipWithSecondHolder ,
		client.NomineeRelationshipWithThirdHolder ,
		client.NomineeAddressLine1 ,
		client.NomineeAddressLine2 ,
		client.NomineeAddressLine3 ,
		client.NomineeAddressCity ,
		client.NomineeAddressState  ,
		client.NomineeAddressRefCountryId ,--NomineeAddressCountry
		client.NomineeAddressPin ,
		client.NomineePhone ,
		client.NomineeDOB ,
		client.GuardianFirstName ,
		client.GuardianMiddleName ,
		client.GuardianLastName ,
		client.GuardianRelationship ,
		client.GuardianAddressLine1 ,
		client.GuardianAddressLine2 ,
		client.GuardianAddressLine3 ,
		client.GuardianAddressCity ,
		client.GuardianAddressState ,
		client.GuardianAddressRefCountryId , --GuardianAddressCountry
		client.GuardianAddressPin ,
		client.GuardianPhone ,
		client.GuradianPAN ,
		client.NriPisApprovalNo ,
		--client.NriPisApprovalDate ,
		client.NriForeignAddressLine1 ,
		client.NriForeignAddressLine2 ,
		client.NriForeignAddressCity ,
		client.NriForeignAddressState ,
		client.NriForeignAddressRefCountryId , --NriForeignAddressCountry
		client.NriForeignAddressPin ,
		--client.Aadhar ,
		client.bank_account_no_1,
		client.ClientStatuisId,
		client.pepid,
		client.RequestedBy ,
		client.RequestedOn ,
		client.RequestedBy ,
		client.RequestedOn,
		client.RefClientAccountStatusId 
      FROM #Clients client
	  WHERE client.RefClientId IS NULL	
	  and not exists (select 1 from refclient where RefClientDatabaseEnumId = @DataBaseId  and clientid = client.ClientId collate database_default)
	  
	  delete from  dbo.CoreClientRelationshipManager

insert into dbo.CoreClientRelationshipManager(
refclientid,
RefEmployeeId,
AddedBy,
AddedOn,
LastEditedBy,
EditedOn)
select 
refclientid,
refemployeeidRm,
'System',
getdate(),
'Syetem',
getdate()
from #Clients temp
where  not exists (select 1 from CoreClientRelationshipManager where RefClientId = temp.refclientid and
										RefEmployeeId= temp.refemployeeidRm)
										AND temp.refemployeeidRm IS NOT NULL
										and temp.RefClientId is not null
										


insert into CoreClientRelationshipManager(
refclientid,
RefEmployeeId,
AddedBy,
AddedOn,
LastEditedBy,
EditedOn)
select 
refclientid,
refemployeeiddealer,
'System',
getdate(),
'Syetem',
getdate()
from #Clients temp
where  not exists (select 1 from CoreClientRelationshipManager where RefClientId = temp.refclientid and
										RefEmployeeId= temp.RefemployeeIdDealer)
										AND TEMP.RefemployeeIdDealer IS NOT NULL 
										and temp.RefClientId is not null


insert into RefClientDematAccount
(
refclientid,
RefDematAccountTypeId,
RefDepositoryId,
accountid,
RefDematAccountOwnerTypeId,
addedby,
addedon,
LastEditedBy,
EditedOn,
pms,
poa
)
select 
c.refclientid,
1,
de.RefDepositoryId,
dp_ac_no1,
5,
'System',
GETDATE(),
'System',
getdate(),
0,
0
from #clientS c
inner join RefDepository  de on left(de.DPId,6) = c.dp_id_1
WHERE NOT EXISTS (SELECT 1 FROM RefClientDematAccount WHERE RefDepositoryId  = DE.RefDepositoryId AND AccountId = C.DP_AC_NO1 )
AND c.RefClientId IS NOT NULL and C.dp_ac_no1 NOT LIKE '%[^0-9]%' 


insert into RefClientDematAccount
(
refclientid,
RefDematAccountTypeId,
RefDepositoryId,
accountid,
RefDematAccountOwnerTypeId,
addedby,
addedon,
LastEditedBy,
EditedOn,
pms,
poa
)
select 
c.refclientid,
1,
de.RefDepositoryId,
dp_ac_no2,
5,
'System',
GETDATE(),
'System',
getdate(),
0,
0
from #Clients c
inner join RefDepository  de on left(de.DPId,6) = c.dp_id_2
WHERE NOT EXISTS (SELECT 1 FROM RefClientDematAccount WHERE RefDepositoryId  = DE.RefDepositoryId AND AccountId = C.DP_AC_NO2 )
and C.DP_AC_NO2 NOT LIKE '%[^0-9]%' AND c.RefClientId IS NOT NULL	-- select * from RefClientSpecialCategory 

Declare @SplId INT
Select @SplId = RefClientSpecialCategoryid from RefClientSpecialCategory where Name = 'Politically Exposed person'
update RefClient
set RefClientSpecialCategoryId = @SplId,
EditedOn = GETDATE(),
LastEditedBy = 'System'
where RefPEPId = 2

 exec Client_FinancialTransaction_Refresh 
 exec Client_KeyPerson_Refresh

 exec ClientIncome_Refresh

END


GO
GO
ALTER PROCEDURE [dbo].[Client_KeyPerson_Refresh] 

AS
BEGIN
	
		DECLARE @DatabaseId INT
        SELECT  @DatabaseId = RefClientDatabaseEnumId
        FROM    RefClientDatabaseEnum
        WHERE   DatabaseType = 'Trading'
		

		DROP TABLE temp_keyperson

		select * into temp_keyperson from OpenQuery(PRCSN,'Select * from CBOSOWNER.V_AML_KEYPERSON_INFO_VIEW')

		--SELECT * FROM temp_keyperson

        IF OBJECT_ID('tempdb..#ClientKeyPerson') IS NOT NULL 
            DROP TABLE #ClientKeyPerson
    
        CREATE TABLE #ClientKeyPerson
            (
              RefClientId INT ,
			  FirstName VARCHAR(500),
			  MiddleName VARCHAR(500),
              LastName VARCHAR(500) ,
              RefDesignationId INT ,
              AddressLine1 VARCHAR(500) ,
              AddressLine2 VARCHAR(500) ,
              AddressLine3 VARCHAR(500) ,
              City VARCHAR(200) ,
              State VARCHAR(200) ,
              Country VARCHAR(200) ,
              Pin VARCHAR(100) ,
              Email VARCHAR(200) ,
              Mobile VARCHAR(50) ,
              PAN VARCHAR(10) ,
              ShareHoldingPercent DECIMAL(19, 2) ,
              NumberOfShares INT ,
              UIN VARCHAR(100) ,
              DOB DATETIME
            )
        INSERT  INTO #ClientKeyPerson
                ( RefClientId ,
				FirstName,
				MiddleName,
                  LastName ,
                  RefDesignationId ,
                  AddressLine1 ,
                  AddressLine2 ,
                  AddressLine3 ,
                  City ,
                  State ,
                  Country ,
                  Pin ,
                  Email ,
                  Mobile ,
                  PAN ,
                  ShareHoldingPercent ,
                  NumberOfShares ,
                  UIN ,
                  DOB 
                )
                SELECT  cl.RefClientId ,
						LTRIM(RTRIM(vwKeyPerson.KeyPersonFirstName)) ,
						LTRIM(RTRIM(vwKeyPerson.KeyPersonMiddleName)) ,
						ISNULL(LTRIM(RTRIM(vwKeyPerson.KeyPersonLastName)),'') ,
                        desg.RefDesignationId ,
                        LTRIM(RTRIM(vwKeyPerson.ADDRESSLINE1)) ,
                        LTRIM(RTRIM(vwKeyPerson.ADDRESSLINE2)) ,
                        LTRIM(RTRIM(vwKeyPerson.ADDRESSLINE3)) ,
                        LTRIM(RTRIM(vwKeyPerson.CITY)) ,
                        LTRIM(RTRIM(vwKeyPerson.STATE)) ,
                        LTRIM(RTRIM(vwKeyPerson.Country)) ,
                        LTRIM(RTRIM(vwKeyPerson.PIN)) ,
                        LTRIM(RTRIM(vwKeyPerson.EMAIL)) ,
                        LTRIM(RTRIM(vwKeyPerson.Mobile)) ,
                        LTRIM(RTRIM(vwKeyPerson.PAN)) ,
                        CASE WHEN LTRIM(RTRIM(vwKeyPerson.ShareHoldingPercent)) = '' THEN NULL ELSE LTRIM(RTRIM(vwKeyPerson.ShareHoldingPercent)) END ,
                        CASE WHEN LTRIM(RTRIM(vwKeyPerson.NumberOfShares)) = '' THEN NULL ELSE LTRIM(RTRIM(vwKeyPerson.NumberOfShares)) END,
                        LTRIM(RTRIM(vwKeyPerson.UIN)) ,
                        LTRIM(RTRIM(vwKeyPerson.DOB))
                FROM    temp_keyperson vwKeyPerson
                        INNER JOIN RefClient cl ON cl.RefClientDatabaseEnumId = @DatabaseId
                        AND LTRIM(RTRIM(vwKeyPerson.ClientId)) = cl.ClientId COLLATE DATABASE_DEFAULT
                        INNER JOIN RefDesignation desg ON vwKeyPerson.designation = desg.Name COLLATE DATABASE_DEFAULT
						WHERE KeyPersonFirstName IS NOT NULL OR KeyPersonMiddleName IS NOT NULL OR KeyPersonLastname IS NOT NULL
		--WHERE vwKeyPerson.ClientId = '310129'


        UPDATE  link
        SET     link.Email = keyPerson.Email ,
                link.Mobile = keyPerson.Mobile ,
                link.PAN = keyPerson.Pan ,
                link.AddressLine1 = keyPerson.AddressLine1 ,
                link.AddressLine2 = keyPerson.AddressLine2 ,
                link.AddressLine3 = keyPerson.AddressLine3 ,
                link.City = keyPerson.City ,
                link.State = keyPerson.State ,
                link.Country = keyPerson.Country ,
                link.Pin = keyPerson.pin ,
                link.LastEditedBy = 'System' ,
                link.EditedOn = GETDATE() ,
                link.ShareHoldingPercent = keyPerson.ShareHoldingPercent ,
                link.NumberOfShares = keyPerson.NumberOfShares ,
                link.UIN = keyPerson.UIN ,
                link.DOB = keyPerson.DOB
        FROM    dbo.LinkVirtRefClientRefKeyPerson link
                INNER JOIN #ClientKeyPerson keyPerson 
                ON link.RefClientId = keyPerson.RefClientId
                AND link.LastName = keyPerson.LastName COLLATE DATABASE_DEFAULT
                AND link.RefDesignationId = keyPerson.RefDesignationId
                AND link.RefLinkVirtRefClientRefKeyPersonId = NULL	
				WHERE 
				(ISNULL(link.Email,'')<>ISNULL(keyPerson.Email,'')OR
				ISNULL(link.Mobile,'')<>ISNULL(keyPerson.Mobile,'')OR
				ISNULL(link.PAN,'')<>ISNULL(keyPerson.PAN,'')OR
				ISNULL(link.AddressLine1,'')<>ISNULL(keyPerson.AddressLine1,'')OR
				ISNULL(link.AddressLine2,'')<>ISNULL(keyPerson.AddressLine2,'')OR
				ISNULL(link.AddressLine3,'')<>ISNULL(keyPerson.AddressLine3,'')OR
				ISNULL(link.City,'')<>ISNULL(keyPerson.City,'')OR
				ISNULL(link.[State],'')<>ISNULL(keyPerson.[State],'')OR
				ISNULL(link.Country,'')<>ISNULL(keyPerson.Country,'')OR
				ISNULL(link.Pin,'')<>ISNULL(keyPerson.Pin,'')OR
				ISNULL(link.ShareHoldingPercent,0) <> ISNULL(keyPerson.ShareHoldingPercent,0)OR
				ISNULL(link.NumberOfShares,0) <> ISNULL(keyPerson.NumberOfShares,0)OR
				ISNULL(link.UIN,'') <> ISNULL(keyPerson.UIN,'')OR
				ISNULL(link.DOB,'') <> ISNULL(keyPerson.DOB,'')
				)
		
      
        INSERT  INTO LinkVirtRefClientRefKeyPerson
                ( RefClientId ,
				FirstName,
				MiddleName,
                  LastName ,
                  RefDesignationId ,
                  Email ,
                  Mobile ,
                  PAN ,
                  AddressLine1 ,
                  AddressLine2 ,
                  AddressLine3 ,
                  City ,
                  State ,
                  Country ,
                  Pin ,
                  AddedBy ,
                  AddedOn ,
                  LastEditedBy ,
                  EditedOn ,
                  ShareHoldingPercent ,
                  NumberOfShares ,
                  UIN ,
                  DOB
                )
                SELECT  keyPerson.RefClientId ,
						keyPerson.FirstName,
						keyPerson.MiddleName,
                        keyPerson.LastName ,
                        keyPerson.RefDesignationId ,
                        keyPerson.Email ,
                        keyPerson.Mobile ,
                        keyPerson.PAN ,
                        keyPerson.AddressLine1 ,
                        keyPerson.AddressLine2 ,
                        keyPerson.AddressLine3 ,
                        keyPerson.City ,
                        keyPerson.State ,
                        keyPerson.Country ,
                        keyPerson.Pin ,
                        'System' ,
                        GETDATE() ,
                        'System' ,
                        GETDATE() ,
                        keyPerson.ShareHoldingPercent ,
                        keyPerson.NumberOfShares ,
                        keyPerson.UIN ,
                        keyPerson.DOB
                FROM    #ClientKeyPerson keyPerson
                WHERE   NOT EXISTS ( SELECT 1
                                     FROM   LinkVirtRefClientRefKeyPerson link
                                     WHERE  link.RefClientId = keyPerson.RefClientId
                                            AND ISNULL(link.LastName,'') = ISNULL(keyPerson.LastName,'') COLLATE DATABASE_DEFAULT
                                            AND link.RefDesignationId = keyPerson.RefDesignationId)
                                            
    
    END



GO