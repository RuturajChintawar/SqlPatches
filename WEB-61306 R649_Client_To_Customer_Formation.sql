--------SecPermission_Insert Starts---
GO
EXEC dbo.SecPermission_Insert @Name='P111359_R649_Client_To_Customer_Formation', @Description='TSS-Screening', @Code='P111359'
GO
--------SecPermission_Insert Ends---


--------RefReport_Insert Starts---
GO
EXEC dbo.RefReport_Insert @Code='R649',
						  @Name='Client to Customer Formation',
						  @ReportType='SP',
						  @URL=NULL,
						  @StoredProcedureName='dbo.GetRefClientToRefCustomerFormation_R649',
						  @Permission='P111359_R649_Client_To_Customer_Formation',
						  @CategoryCode='Screening',
						  @SubCategoryCode='Auditreports(Accountbased)',
						  @Description='<b><u>Objective:</u></b>To provide a list of clients and there associated customers after moving clients from client master/product account master to customer master
										<br><b><u>Specification:</u></b>The user will be able to extract the output on the following basis:<br>
												<ol type="a">
												<li>Prod Acc/Database Type : The type of Product Account the client is associated with.</li>
												<li>Client Id/Account No - The Client Id associated with a Client/ Product Account</li>
												<li>Client Name - The name of the Client</li>
												<li>Customer Code - The code of the customer who is created for this particular client</li>
												<li>Customer Name - The name of the customer who is created for this particular client</li>
												<li>Client/Account Pan - The PAN of the client/product account</li>
												<li>Constitution Type -  The Constitution Type of the client/product account</li>
												<li>Bo Status -  The Bo Status of the client/product account</li>
												<li>Bo Sub Status -  The Bo Sub Status of the client/product account</li>
												<li>Customer Type - The customer type of the customer</li>
												<li>Account Opening Date - The Account Opening Date of the client/product account</li>
												<li>Account Closing Date - The Account Closing Date of the client/product account</li>
												<li>Client Edited On Date - The Edited Date of the client/product account</li></ol>
												<p><b>Specification:</b>This report will be generated Company wise based on the forms Parent Company</p>
												<p><u><b>Limitation :</b></u>This report will be generated for the period of 186 days.</p>'
GO
--------RefReport_Insert Ends---

--------RefReport_AttachRefReportGeneratorType Starts----
GO
EXEC dbo.RefReport_AttachRefReportGeneratorType @ReportCode='R570',@ReportGegneratorTypeCode='1'
GO
--------RefReport_AttachRefReportGeneratorType Ends----
 SELECT  @ReportGeneratorId = RefReportGeneratorTypeId FROM dbo.RefReportGeneratorType WHERE Code = @ReportGegneratorTypeCodeInternal  
--------RefReportParameter_Insert Starts---
GO
DECLARE @ColumnTypeRefEnumValueId INT
SET @ColumnTypeRefEnumValueId = dbo.GetEnumValueId('DataExtractColumnType','MultiSelectDropdown')

	EXEC dbo.RefReportParameter_Insert
		@ColumnName = '@DatabasetypeR649',
		@ColumnTypeRefEnumValueId = @ColumnTypeRefEnumValueId,
		@DropdownQuery = 'dbo.RefReportParameter_GetDatabaseType_IdAsValue_DBTypeAsDesc',
		@SearchWhileTyping = 1,
		@DisplayName = 'Account /Database Type',
		@ParameterName = '@DatabasetypeR649'
GO
select * from RefReportParameter where columnname like'%DATE%'
DECLARE @ColumnTypeRefEnumValueId INT
SET @ColumnTypeRefEnumValueId = dbo.GetEnumValueId('DataExtractColumnType','DateTime')

	EXEC dbo.RefReportParameter_Insert
		@ColumnName = '@ClientEditedOnFromDate',
		@ColumnTypeRefEnumValueId = @ColumnTypeRefEnumValueId,
		@DisplayName = 'Client Edited On From Date',
		@ParameterName = '@ClientEditedOnFromDate'
GO

DECLARE @ColumnTypeRefEnumValueId INT
SET @ColumnTypeRefEnumValueId = dbo.GetEnumValueId('DataExtractColumnType','DateTime')

	EXEC dbo.RefReportParameter_Insert
		@ColumnName = '@ClientEditedOnToDate',
		@ColumnTypeRefEnumValueId = @ColumnTypeRefEnumValueId,
		@DisplayName = 'Client Edited On To Date',
		@ParameterName = '@ClientEditedOnToDate'
GO
--------RefReportParameter_InsertEnds---
select * from dbo.RefReportParameter where columnName = '@CurrentEntityType'
select * from Refenumvalue where refenumvalueid = 1155
--------LinkRefReportRefReportParameter_Insert Starts---
GO
EXEC dbo.LinkRefReportRefReportParameter_Insert @RefReportCode='R649',
												@IsColumnHide=0,
												@ColumnName='@ClientEditedOnFromDate',
												@IsRequired=1
GO
EXEC dbo.LinkRefReportRefReportParameter_Insert @RefReportCode='R649',
												@IsColumnHide=0,
												@ColumnName='@ClientEditedOnToDate',
												@IsRequired=1
GO
EXEC dbo.LinkRefReportRefReportParameter_Insert @RefReportCode='R649',
												@IsColumnHide=0,
												@ColumnName='@DatabaseTypeR649',
												@IsRequired=1

GO
EXEC dbo.LinkRefReportRefReportParameter_Insert @RefReportCode='R570',
												@IsColumnHide=1,
												@ColumnName='@CurrentEntityType'												
GO
--------LinkRefReportRefReportParameter_Insert Ends---

--------SP Starts---
GO
CREATE PROCEDURE [dbo].[GetRefClientToRefCustomerFormation_R649]  
 (  
  @ClientEditedOnFromDate DATETIME,  
  @ClientEditedOnToDate DATETIME,  
  @DatabasetypeR649 VARCHAR(1000),
  @CurrentEntityType VARCHAR(500) = NULL
 )  
   
 AS  
 BEGIN  
  DECLARE @InternalFromDate DATETIME, @InternalToDate DATETIME, @InternalDatabasetypeR649 VARCHAR(1000), @InternalCurrentEntityType VARCHAR(500)
  , @CurrentEntityTypeId INT, @ParentCompanyId INT  
    
  SET @InternalFromDate = dbo.GetDateWithoutTime(@ClientEditedOnFromDate)                
  SET @InternalToDate =   DATEADD(SECOND,-1,DATEADD(DAY,1,dbo.GetDateWithoutTime(@ClientEditedOnToDate)))      
  SET @InternalDatabasetypeR649 =@DatabasetypeR649  
  SET @InternalCurrentEntityType=@CurrentEntityType
  SET @CurrentEntityTypeId=dbo.GetEntityTypeByCode(@InternalCurrentEntityType)
  SELECT @ParentCompanyId  = RefParentCompanyId FROM dbo.RefEntityType WHERE RefEntityTypeId = @CurrentEntityTypeId

 IF (DATEDIFF(DAY,@InternalFromDate,(@InternalToDate+1))>186)    
 BEGIN    
  RAISERROR ('This report will be generated for the period of 186 days.',11,1) WITH SETERROR;    
  RETURN 50010;    
 END    
   
 IF (DATEDIFF(DAY,@InternalFromDate,(@InternalToDate))<0)    
 BEGIN    
  RAISERROR ('To Date should be greater than From Date',11,1) WITH SETERROR;    
  RETURN 50010;    
 END    
  
	SELECT   
		refdata.RefClientDatabaseEnumId,refdata.DatabaseType  
	INTO #ClientDatabaseInfo  
	FROM dbo.ParseString(@InternalDatabasetypeR649,',') s   
	INNER JOIN dbo.RefClientDatabaseEnum refdata  
	ON refdata.RefClientDatabaseEnumId = s.s  
  
	SELECT  
	client.[ClientId],  
	client.[Name],  
	client.[PAN],  
	client.[AccountOpeningDate],  
	client.[AccountClosingDate],  
	client.[EditedOn],  
	client.[RefCRMCustomerId],  
	client.[RefClientDatabaseEnumId],  
	client.[RefConstitutionTypeId],  
	client.[RefBOStatusId],  
	contype.[Name] AS [ConstitutionType],  
	dbinfo.[DatabaseType] ,  
	client.[RefBoSubstatusId]  
	INTO #clientdata  
	FROM  #ClientDatabaseInfo dbinfo  
	INNER JOIN dbo.RefClient client ON dbinfo.RefClientDatabaseEnumId = client.RefClientDatabaseEnumId  
	LEFT JOIN dbo.RefConstitutionType contype ON contype.RefConstitutionTypeId = client.RefConstitutionTypeId  
	WHERE client.EditedOn >= @InternalFromDate AND client.EditedOn <= @InternalToDate  
   
	DROP TABLE  #ClientDatabaseInfo

	SELECT   
	client.*,  
	bostatus.[Name] AS [BoStatus],  
	bosubstatus.[Name] AS [BoSubstatus]  
	INTO #FinalClientData  
	FROM #clientdata client  
	LEFT JOIN dbo.RefBOStatus bostatus ON client.RefBOStatusId=bostatus.RefBOStatusId  
	LEFT JOIN dbo.RefBOSubstatus bosubstatus ON client.RefBoSubstatusId=bosubstatus.RefBOSubstatusId  
   
     
	SELECT DISTINCT RefCRMCustomerId INTO #tempcrmcust FROM #clientdata  
 
	DROP TABLE #clientdata
  
	SELECT   
	customer.RefCRMCustomerId,  
	customer.[CustomerCode],customer.[FirstName]+' '+ISNULL(customer.[MiddleName],'')+' '+ISNULL(customer.[LastName],'') AS [CustomerName],  
	custtype.[Name] as [CustomerType]  
	INTO #Customerdata  
	FROM dbo.RefCRMCustomer customer  
	INNER JOIN #tempcrmcust tempcust ON tempcust.RefCRMCustomerId = customer.RefCRMCustomerId  
	LEFT JOIN dbo.RefCustomerType custtype ON customer.RefCustomerTypeId=custtype.RefCustomerTypeId  
	WHERE customer.RefParentCompanyId=@ParentCompanyId

	DROP TABLE #tempcrmcust
	SELECT   
	client.[DatabaseType] AS [Prod Acc/Database Type],  
	client.[ClientId] AS [Client Id/Prod Acc No.],  
	client.[Name] AS [Client Name],  
	cus.[CustomerCode] AS [Customer Code],  
	cus.[CustomerName] AS [Customer Name],  
	client.[ConstitutionType] AS [Constitution Type],  
	client.[PAN] AS [Client/Account PAN],  
	client.[BoStatus] AS [Bo Status],  
	client.[BoSubstatus] AS [Bo Sub status],  
	cus.[CustomerType] AS [Customer Type],  
	FORMAT(client.[AccountOpeningDate],'dd-MMM-yyyy') AS [Account Opening Date],  
	FORMAT(client.[AccountClosingDate],'dd-MMM-yyyy') AS [Account Closing Date],  
	FORMAT(client.[EditedOn],'dd-MMM-yyyy') AS [Client Edited On Date]  
	FROM #FinalClientData client   
	LEFT JOIN #Customerdata cus ON client.RefCRMCustomerId= cus.RefCRMCustomerId 
 
	DROP TABLE #FinalClientData
	DROP TABLE #Customerdata
END  
GO
----------SP Ends--------

--------RefReportColumn_Insert Starts---
GO
EXEC dbo.RefReportColumn_Insert @Code='R570',@ReportColumnName='$',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Client Id/Prod Acc No.',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Client Name',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Customer Code',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Customer Name',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Client/Account PAN',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Constitution Type',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Bo Status',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Bo Sub status',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Customer Type',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Account Opening Date',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Account Closing Date',@ColumnDataType='varchar'
GO
EXEC dbo.RefReportColumn_Insert @Code='R649',@ReportColumnName='Client Edited On Date',@ColumnDataType='varchar'
GO
--------RefReportColumn_Insert Ends---
delete from RefReportColumn where RefReportId = 499