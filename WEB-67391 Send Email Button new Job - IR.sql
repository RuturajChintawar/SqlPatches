GO
DECLARE @EmailTemplateTypeId INT
SET @EmailTemplateTypeId = (SELECT RefEmailTemplateTypeId FROM dbo.RefEmailTemplateType WHERE [Name] = 'TSS-AML');

EXEC dbo.RefEmailTemplate_InsertIfNotExists 
@Code = 'E2005',
@RefEmailTemplateTypeId = @EmailTemplateTypeId,
@Name = 'Notify the when a case is moved to user''s workflow step ',
@EmailSubject = 'A case is been moved to <Step Name>',
@EmailBody ='Dear <User Name>, <br />  
Below case is been moved to <Step Name><br />  
Case Id : <Case Id><br />  
Total Alerts : <Alerts Count><br /> 
Source System Name and code: <SourceSystemDetail><br /> 
Product Account Type and Numbers: <ProductAccountDetail><br/>
Case URL : <Case Url><br />  
Received On : <Date and Time><br />  
Instance Name : <Instance Name><br />  
Do not reply to this email as this is system generated. <br />  
Thanks, <br />
TrackWizz System',
@IsHtml = 1,
@AddedBy = 'System',
@LastEditedBy = 'System'
GO
GO
DECLARE @ProcessTypeId INT,
		@RunPermissionId INT,
		@ModifyPermissionId INT,
		@SuccesEmailTemplateId INT
SET @ProcessTypeId = dbo.GetEnumValueId('ProcessType','Simple')
SET @RunPermissionId = dbo.GetSecPermissionIdByName('P111311_J1455_Run')
SET @ModifyPermissionId = dbo.GetSecPermissionIdByName('P111411_J1455_Modify')
SELECT @SuccesEmailTemplateId = RefEmailTemplateId FROM dbo.RefEmailTemplate WHERE Code = 'E2005'

INSERT INTO dbo.RefProcess 
(
	[Name],
	ClassName,
	IsActive,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn,
	IsScheduleEditable,
	AssemblyName,
	ProcessTypeRefEnumValueId,
	EnableRunDateSelection,
	IsCompanyWise,
	RunSecPermissionId,
	ModifySecPermissionId,
	DisplayName,
	Code,
	RefEmailTemplateId
	)
VALUES 
(
	'Jxxx',
	'TSS.SmallOfficeWeb.ManageData.Processes.AML.Jxxx',
	1,
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	1,
	'TSS.SmallOfficeWeb.ManageData',
	@ProcessTypeId,
	0,
	0,
	@RunPermissionId,
	@ModifyPermissionId,
	'Jxxx',
	'Jxxx',
	@SuccesEmailTemplateId
)
	
GO

GO
EXEC dbo.SecPermission_Insert @Name = 'P111411_J1455_Modify', @Description = 'AML', @Code ='P111411'

EXEC dbo.SecPermission_Insert @Name = 'P111311_J1455_Run', @Description = 'AML', @Code ='P111311'
GO

GO
ALTER TABLE dbo.RefReport
ADD  IsSendEmailButton BIT DEFAULT 0

UPDATE ref
SET IsSendEmailButton=1
FROM  dbo.RefReport ref
WHERE ref.Code IN ('R668','R667')
GO
GO
 alter PROCEDURE [dbo].[RefReport_GetReportByCode]   
(        
 @code VARCHAR(50)        
)        
AS          
BEGIN          
 SELECT           
  report.RefReportId,          
  report.Name,          
  report.StoredProcedureName,          
  report.Code,      
  report.Description,    
  permission.Name AS PermissionName,    
  report.ExportLimit,    
  report.Setting,    
  report.DaysSpanRange,    
  report.FromDateParameterName,    
  report.ToDateParameterName,    
  report.IsExportOnly,    
  reportType.Code as ReportType,  
  ISNULL(report.IsHidePager,0) AS IsHidePager,    
  report.PageSize ,
  report.IsSendEmailButton
 FROM dbo.RefReport report     
 INNER JOIN dbo.RefEnumValue reportType ON reportType.RefEnumValueId = report.ReportTypeRefEnumValueId   
 LEFT JOIN dbo.SecPermission permission on report.SecPermissionId = permission.SecPermissionId        
 WHERE --report.ReportTypeRefEnumValueId = dbo.GetEnumValueId('ReportType','SP') AND          
  report.IsDisabled = 0  AND report.Code = @code        
END  
go