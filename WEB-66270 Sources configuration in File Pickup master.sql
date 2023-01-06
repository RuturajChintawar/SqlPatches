--WEB-66270-RC-START
GO
EXEC dbo.Sys_DropIfExists @ObjectName='RefWebFileLocation_InsertIfNotExists',@XType='p'
GO
GO
CREATE PROCEDURE dbo.RefWebFileLocation_InsertIfNotExists
(
	@RefSegmentName VARCHAR(500),
	@RefAmlFileTypeName VARCHAR(50),
	@RefProtocolName VARCHAR(100),
	@FtpRemoteDirectory VARCHAR(500),
	@FileName VARCHAR(100),
	@LocalDirectory VARCHAR(500),
	@PriorityLevel INT,
	@IsSystemFile BIT,
	@DownloadDateOffset INT,
	@TaskName VARCHAR(100),
	@ServerName VARCHAR(200),
	@ParentCompanyName VARCHAR(500)=NULL,
	@JobCode VARCHAR (20) = NULL,
	@SourceCode INT = NULL
)
AS
BEGIN

	 
	DECLARE @InternalRefSegmentName VARCHAR(500)=@RefSegmentName,
	@InternalRefAmlFileTypeName VARCHAR(50)=@RefAmlFileTypeName,
	@InternalRefProtocolName VARCHAR(100)=@RefProtocolName,
	@InternalFtpRemoteDirectory VARCHAR(500)=@FtpRemoteDirectory,
	@InternalFileName VARCHAR(100)=@FileName,
	@InternalLocalDirectory VARCHAR(500)=@LocalDirectory,
	@InternalPriorityLevel INT=@PriorityLevel,
	@InternalIsSystemFile BIT=@IsSystemFile,
	@InternalDownloadDateOffset INT=@DownloadDateOffset,
	@InternalParentCompanyName VARCHAR(500)=@ParentCompanyName,
	@InternalServerName VARCHAR(200)=@ServerName,
	@InternalTaskName VARCHAR(100)=@TaskName,
	@InternalJobCode VARCHAR(20)=@JobCode,
	@InternalSourceCode INT =@SourceCode,
	@RefAmlWatchListSourceId INT,
	@RefProcessId INT,
	@CurrentDate DATETIME=getdate(),
	@RefSegmentId INT,
	@RefAmlFileTypeId INT,
	@RefProtocolId INT,
	@ParentCompanyId INT,
	@InternalTaskEnumValueId INT,
	@RefFtpSiteId INT

	SET @InternalTaskEnumValueId=dbo.GetEnumValueId('FileTask',@InternalTaskName)
	
	IF NOT EXISTS (SELECT 1 FROM dbo.RefFtpSite WHERE Name=@InternalServerName)
		BEGIN  
		RAISERROR ('No RefFtpSite with given Server Name  %s ',11,1,@InternalServerName ) WITH SETERROR;  
		RETURN 50010;  
		END

	SET @RefFtpSiteId=(SELECT RefFtpSiteId FROM dbo.RefFtpSite WHERE Name=@InternalServerName)

	IF NOT EXISTS (SELECT 1 FROM dbo.RefSegmentEnum WHERE Segment=@InternalRefSegmentName)
		BEGIN  
		RAISERROR ('No RefSegmentEnum with given Segment Name  %s ',11,1,@InternalRefSegmentName ) WITH SETERROR;  
		RETURN 50010;  
		END

	SET @RefSegmentId=(SELECT RefSegmentEnumId FROM dbo.RefSegmentEnum WHERE Segment=@InternalRefSegmentName)

	IF NOT EXISTS (SELECT 1 FROM dbo.RefAmlFileType WHERE Name=@InternalRefAmlFileTypeName)
		BEGIN  
		RAISERROR ('No RefAmlFileType with given FileType Name  %s ',11,1,@InternalRefAmlFileTypeName ) WITH SETERROR;  
		RETURN 50010;  
		END

	SET @RefAmlFileTypeId=(SELECT RefAmlFileTypeId FROM dbo.RefAmlFileType WHERE Name=@InternalRefAmlFileTypeName)

	IF NOT EXISTS ((SELECT 1 FROM dbo.RefProtocol WHERE Name=@InternalRefProtocolName))
		BEGIN  
		RAISERROR ('No RefProtocol with given Name  %s ',11,1,@InternalRefProtocolName ) WITH SETERROR;  
		RETURN 50010;  
		END

	SET @RefProtocolId=(SELECT RefProtocolId FROM dbo.RefProtocol WHERE Name=@InternalRefProtocolName)

	IF(@ParentCompanyName <> NULL)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.RefParentCompany WHERE Name=@ParentCompanyName)
		BEGIN  
		RAISERROR ('No RefParentCompany with given Parent Company Name  %s ',11,1,@ParentCompanyName ) WITH SETERROR;  
		RETURN 50010;  
		END
	END
	SET @ParentCompanyId=(SELECT RefParentCompanyId FROM dbo.RefParentCompany WHERE Name=@ParentCompanyName)

	IF NOT EXISTS(SELECT 1 FROM dbo.RefWebFileLocation WHERE Name=@InternalFileName AND RefSegmentId=@RefSegmentId
	 AND FtpRemoteDirectory=@InternalFtpRemoteDirectory AND RefAmlFileTypeId=@RefAmlFileTypeId)
	 BEGIN 
	 
	SET @RefAmlWatchListSourceId = (SELECT RefAmlWatchListSourceId FROM dbo.RefAmlWatchListSource WHERE SourceCode=@InternalSourceCode)
	SET @RefProcessId = (SELECT RefProcessId FROM dbo.RefProcess WHERE [Code]=@InternalJobCode)
  
		INSERT INTO [dbo].[RefWebFileLocation]
			   ([RefSegmentId]
			   ,[RefAmlFileTypeId]
			   ,[RefProtocolId]
			   ,[FtpRemoteDirectory]
			   ,[Name]
			   ,[LocalDirectory]
			   ,[AddedBy]
			   ,[AddedOn]
			   ,[LastEditedBy]
			   ,[EditedOn]
			   ,IsExternalDeleteFiles
			   ,IsLocalDeleteFiles
			   ,[PriorityLevel]
			   ,[IsSystemFile]
			   ,[DownloadDateOffset]
			   ,TaskRefEnumValueId
			   ,RefFtpSiteId
			   ,[RefParentCompanyId]
			   ,[RefAmlWatchListSourceId]
			   ,[RefProcessId])
		 VALUES
			   (@RefSegmentId
			   ,@RefAmlFileTypeId
			   ,@RefProtocolId
			   ,@InternalFtpRemoteDirectory
			   ,@InternalFileName
			   ,@InternalLocalDirectory
			   ,'System'
			   ,@CurrentDate
			   ,'System'
			   ,@CurrentDate
			   ,0
			   ,0
			   ,@InternalPriorityLevel
			   ,@InternalIsSystemFile
			   ,@InternalDownloadDateOffset
			   ,@InternalTaskEnumValueId
			   ,@RefFtpSiteId
			   ,@ParentCompanyId
			   ,@RefAmlWatchListSourceId
			   ,@RefProcessId)

	 END 

END
GO
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_UNSC','sftp','/TSS/Screening/UNSC_1267/Latest/','Watchlist_UNSC.zip',
'C:\TssFileDownload\Other_WatchList_UNSC',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',1 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_OFAC','sftp','/TSS/Screening/OFAC/Latest/',
'Watchlist_OFAC.zip','C:\TssFileDownload\Other_WatchList_OFAC',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',2
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_PEP','sftp','/TSS/Screening/PEP/Latest/',
'Watchlist_PEP.zip','C:\TssFileDownload\Other_WatchList_PEP',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',3
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_SEBI_Debarred','sftp','/TSS/Screening/SEBI/Latest/',
'Watchlist_SEBI.zip','C:\TssFileDownload\Other_WatchList_SEBI',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',4
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_Arbitration_NSE','sftp','/TSS/Screening/Arbitration_NSE/Latest/',
'Watchlist_Arbitration_NSE.zip','C:\TssFileDownload\Other_WatchList_Arbitration_NSE',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',5
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_UNSC_1988','sftp','/TSS/Screening/UNSC_1988/Latest/',
'Watchlist_UNSC_1988.zip','C:\TssFileDownload\Other_WatchList_UNSC',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',6
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_UNSC_2140','sftp','/TSS/Screening/UNSC_2140/Latest/',
'Watchlist_UNSC_2140.zip','C:\TssFileDownload\Other_WatchList_UNSC',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',7
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_UNSC_2270','sftp','/TSS/Screening/UNSC_2270/Latest/',
'Watchlist_UNSC_2270.zip','C:\TssFileDownload\Other_WatchList_UNSC',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',8
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_Arbitration_BSE','sftp','/TSS/Screening/Arbitration_BSE/Latest/',
'WatchList_Arbitration_BSE.zip','C:\TssFileDownload\Other_WatchList_Arbitration_BSE',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',9 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_RBI_Suit_File','sftp','/TSS/Screening/RBI_Willfull_Defaulters/Latest/',
'WatchList_RBI_Suit_File.zip','C:\TssFileDownload\Other_WatchList_RBI_Suit_File',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',10

GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_UAPA','sftp','/TSS/Screening/UAPA/Latest/','WatchList_UAPA.zip',
'C:\TssFileDownload\Other_WatchList_UAPA',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',11 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_NSE_Defaulter_Members','sftp','/TSS/Screening/NSE_Defaulter_Members/Latest/',
'Watchlist_NSE_Defaulter_Members.zip','C:\TssFileDownload\Other_Watchlist_NSE_Defaulter_Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',12 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_NSE_Expelled_Members','sftp','/TSS/Screening/NSE_Expelled_Members/Latest/',
'Watchlist_NSE_Expelled_Members.zip','C:\TssFileDownload\Other_Watchlist_NSE_Expelled_Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',13
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_ACE_Suspended_Members','sftp','/TSS/Screening/ACE_Suspended_Members/Latest/',
'WatchList_ACE_Suspended_Members.zip','C:\TssFileDownload\Other_WatchList_ACE_Suspended_Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',14
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_BSE_Defaulter_Expelled_Members','sftp','/TSS/Screening/BSE_Defaulter_Expelled_Members/Latest/',
'Watchlist_BSE_Defaulter_Expelled_Members.zip','C:\TssFileDownload\Other_Watchlist_BSE_Defaulter_Expelled_Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',15 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_ICEX_Defaulter_Members','sftp','/TSS/Screening/ICEX_Defaulter_Members/Latest/',
'WatchList_ICEX_Defaulter_Members.zip','C:\TssFileDownload\Other_WatchList_ICEX_Defaulter_Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',16 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_ICEX_Expelled_Members','sftp','/TSS/Screening/ICEX_Expelled_Members/Latest/',
'Watchlist_ICEX_Expelled_Members.zip','C:\TssFileDownload\Other_Watchlist_ICEX_Expelled_Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',17 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_MCX_Defaulter_Members','sftp','/TSS/Screening/MCX_Defaulter_Members/Latest/',
'Watchlist_MCX_Defaulter_Members.zip','C:\TssFileDownload\Other_Watchlist_MCX_Defaulter_Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',18 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_NCDEX_Sus_Def_Exp_Deb_Members','sftp','/TSS/Screening/NCDEX_Sus_Def_Exp_Deb_Members/Latest/',
'WatchList_NCDEX_Sus_Def_Exp_Deb_Members.zip','C:\TssFileDownload\Other_WatchList_NCDEX_Sus_Def_Exp_Deb_Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',19
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_NMCE_Defaulted_Members','sftp','/TSS/Screening/NMCE_Defaulted_Members/Latest/',
'Watchlist_NMCE_Defaulted_Members.zip','C:\TssFileDownload\Other_Watchlist_NMCE_Defaulted_Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',20 
GO
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_NMCE_Expelled_Members','sftp','/TSS/Screening/NMCE_Expelled_Members/Latest/',
'Watchlist_NMCE_Expelled_Members.zip','C:\TssFileDownload\Other_Watchlist_NMCE_Expelled_Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',21
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_NMCE_Suspended_Members','sftp','/TSS/Screening/NMCE_Suspended_Members/Latest/',
'Watchlist_NMCE_Suspended_Members.zip','C:\TssFileDownload\Other_Watchlist_NMCE_Suspended_Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',22 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_MCA_Company_Defaulter_List','sftp','/TSS/Screening/MCA_Company_Defaulter_List/Latest/',
'Watchlist_MCA_Company_Defaulter_List.zip','C:\TssFileDownload\Other_Watchlist_MCA_Company_Defaulter_List',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',23
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_MCA_Director_Defaulter_List','sftp','/TSS/Screening/MCA_Director_Defaulter_List/Latest/',
'MCA Director Defaulter List.zip','C:\TssFileDownload\Other_MCA Director Defaulter List',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',24
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','IRDA_Blacklisted_Agents','sftp','/TSS/Screening/IRDA_Blacklisted_Agents/Latest/','IRDA Blacklisted Agents.xlsx',
'C:\TssFileDownload\Other_IRDA Blacklisted Agents',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',25 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','MCA_Companies_Struck_Off_List','sftp','/TSS/Screening/MCA_Companies_Struck_Off_List/Latest/',
'MCA_Companies_Struck_Off_List.xlsx','C:\TssFileDownload\Other_MCA_Companies_Struck_Off_List',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',26
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','MCA_Director_Disqualified_List','sftp','/TSS/Screening/MCA_Director_Disqualified_List/Latest/',
'MCA_Director_Disqualified_List.zip','C:\TssFileDownload\Other_MCA_Director_Disqualified_List',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',27
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','MCA_Proclaimed_Offenders','sftp','/TSS/Screening/MCA_Proclaimed_Offenders/Latest/',
'MCA_Proclaimed_Offenders.xlsx','C:\TssFileDownload\Other_MCA_Proclaimed_Offenders',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',28
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','MCA_Secretaries_Defaulter_List','sftp','/TSS/Screening/MCA_Secretaries_Defaulter_List/Latest/',
'MCA_Secretaries_Defaulter_List.xlsx','C:\TssFileDownload\Other_MCA_Secretaries_Defaulter_List',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',29 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_Interpol_Wanted_Persons','sftp','/TSS/Screening/Interpol_Wanted_Persons/Latest/',
'WatchList_Interpol_Wanted_Persons.zip','C:\TssFileDownload\Other_WatchList_Interpol_Wanted_Persons',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',30
GO
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_MSE_Arbitral_Awards','sftp','/TSS/Screening/MSE_Arbitral_Awards/Latest/',
'Watchlist_MSE_Arbitral_Awards.xls','C:\TssFileDownload\Other_Watchlist_MSE_Arbitral_Awards',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',31
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_MSE_Trading_Clearing_Member','sftp','/TSS/Screening/MSE_Trading_Clearing_Member/Latest/',
'Watchlist_MSE_Trading_Clearing_Member.xls','C:\TssFileDownload\Other_Watchlist_MSE_Trading_Clearing_Member',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',32
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','BSE_REGULATORY_DEFAULTING_CLIENTS','sftp','/TSS/Screening/BSE_REGULATORY_DEFAULTING_CLIENTS/Latest/',
'BSE_REGULATORY_DEFAULTING_CLIENTS.zip','C:\TssFileDownload\Other_BSE_REGULATORY_DEFAULTING_CLIENTS',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',33 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_NSE_Regulatory_Defaulting_Clients','sftp','/TSS/Screening/NSE_REGULATORY_DEFAULTING_CLIENTS/Latest/',
'NSE_REGULATORY_DEFAULTING_CLIENTS.zip','C:\TssFileDownload\Other_NSE_REGULATORY_DEFAULTING_CLIENTS',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',34
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','United_Kingdom_Sanctionsconlist','sftp','/TSS/Screening/UnitedKingdomSanctionList/Latest/',
'Watchlist_UnitedKingdomSanctionList.zip','C:\TssFileDownload\Other_Watchlist_UnitedKingdomSanctionList',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',35
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_EuropeanUnionSanction','sftp','/TSS/Screening/EuropeanUnionSanction/Latest/',
'Watchlist_EuropeanUnionSanctionList.zip','C:\TssFileDownload\Other_Watchlist_EuropeanUnionSanctionList',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',36
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_MCX_Action_AP','sftp','/TSS/Screening/MCX_Action_AP/Latest/','WatchList_MCX_Action_AP.zip',
'C:\TssFileDownload\Other_WatchList_MCX_Action_AP',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',37
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_NCLT_Orders','sftp','/TSS/Screening/NCLT_Orders/Latest/','WatchList_NCLT_Orders.zip',
'C:\TssFileDownload\Other_WatchList_NCLT_Orders',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',38 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_SFIO_Convicted_Directors','sftp','/TSS/Screening/SFIO_Convicted Directors/Latest/',
'Watchlist_SFIO_Convicted_Directors.zip','C:\TssFileDownload\Other_Watchlist_SFIO_Convicted_Directors',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',39 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_SFIO_Proclaimed_Offenders','sftp','/TSS/Screening/SFIO_Proclaimed Offenders/Latest/',
'WatchList_SFIO_Proclaimed_Offenders.zip','C:\TssFileDownload\Other_Watchlist_SFIO_Proclaimed_Offenders',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',40
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_Wildlife_Crime_Convicts','sftp','/TSS/Screening/Wildlife_Crime_Convicts/Latest/',
'WatchList_Wildlife_Crime_Convicts.zip','C:\TssFileDownload\Other_WatchList_Wildlife_Crime_Convicts',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',41 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_Income_Tax_Defaulters','sftp','/TSS/Screening/Income_tax_defaulters/Latest/',
'Watchlist_Income_Tax_Defaulters.zip','C:\TssFileDownload\Other_Watchlist_Income_Tax_Defaulters',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',42 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_MCA_Vanishing_Companies','sftp','/TSS/Screening/MCA_Vanishing_Companies/Latest/',
'Watchlist_MCA_Vanishing_Companies.zip','C:\TssFileDownload\Other_Watchlist_MCA_Vanishing_Companies',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',43 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_FCRA_Orders','sftp','/TSS/Screening/FCRA_Orders/Latest/',
'Watchlist_FCRA_Orders.zip','C:\TssFileDownload\Other_Watchlist_FCRA_Orders',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',44
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','Watchlist_NHB_Penalties','sftp','/TSS/Screening/NHB_Penalties/Latest/',
'Watchlist_NHB_Penalties.zip','C:\TssFileDownload\Other_Watchlist_NHB_Penalties',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',45 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','WatchList_IOSCO','sftp','/TSS/Screening/IOSCO_Alerts/Latest/',
'WatchList_IOSCO.zip','C:\TssFileDownload\Other_Watchlist_IOSCO',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',46 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/CBI Wanted Person_Rewards/Latest/',
'CBI Wanted Person Rewards.zip','C:\TssFileDownload\Other_CBI Wanted Person Rewards',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',47 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/MSE Defaulter Members/Latest/',
'MSE Defaulter Members.zip','C:\TssFileDownload\Other_MSE Defaulter Members',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,48
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/MSE Expelled Members/Latest/',
'MSE Expelled Members.zip','C:\TssFileDownload\Other_MSE expelled members',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,49
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/Blacklisted Doctors/Latest/',
'Blacklisted Doctors.zip','C:\TssFileDownload\Other_Blacklisted Doctors',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,50
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/NBFC COR Cancellation_RBI/Latest/',
'NBFC Cor Cancellation_RBI.zip','C:\TssFileDownload\Other_NBFC Cor Cancellation -RBI',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',51 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/EOW Wanted List_Delhi/Latest/',
'EOW Wanted List_Delhi.zip','C:\TssFileDownload\Other_EOW Wanted List-Delhi',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,52
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/DSE Suspended Companies/Latest/',
'DSE Suspended Companies.zip','C:\TssFileDownload\Other_DSE Suspended Companies',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,53
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/NSDL Frozen Accounts/Latest/',
'NSDL Frozen Accounts.zip','C:\TssFileDownload\Other_NSDL Frozen Accounts',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',54
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/ICAI Misconduct/Latest/',
'ICAI Misconduct.zip','C:\TssFileDownload\Other_ICAI Misconduct',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,55
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/ICCL Expelled and Defaulter Members/Latest/',
'ICCL Expelled and Defaulter Members.zip','C:\TssFileDownload\Other_ICCL Expelled and Defaulter Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',56
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/ISEI Defaulter Members/Latest/',
'ISEI Defaulter Members.zip','C:\TssFileDownload\Other_ISEI Defaulter Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',57
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/NCCL Sus Def Exp Members/Latest/',
'NCCL Sus Def Exp Members.zip','C:\TssFileDownload\Other_NCCL Suspended/Defaulter/Expelled Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',58 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/NFRA Orders/Latest/',
'NFRA Orders.zip','C:\TssFileDownload\Other_NFRA Orders',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',59
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/NSEL Defaulter/Latest/',
'NSEL Defaulter.zip','C:\TssFileDownload\Other_NSEL Defaulter',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',60
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/NSCCLI Arbitration Awards/Latest/',
'NSCCLI Arbitration Awards.zip','C:\TssFileDownload\Other_NSCCLI Arbitration Awards',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',61 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/NSCCLI Cessation Membership/Latest/',
'NSCCLI Cessation Membership.zip','C:\TssFileDownload\Other_NSCCLI Cessation of Membership',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',62
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/MCX Expelled Members/Latest/',
'MCX Expelled Members.zip','C:\TssFileDownload\Other_MCX Expelled Members',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',63
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/MCX Members deac sus deb/Latest/',
'MCX Members deac sus deb.zip','C:\TssFileDownload\Other_MCX Members deactivated / suspended / debarred',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',64
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/MCX Disciplinary Action/Latest/',
'MCX Disciplinary Action.zip','C:\TssFileDownload\Other_MCX Disciplinary Action',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',65
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/Singapore Terrorist Sanctions/Latest/',
'Singapore Terrorist Sanctions.zip','C:\TssFileDownload\Other_Singapore Terrorist Sanctions',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',66 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','OFAC Consolidated Non SDN','sftp','/TSS/Screening/OFAC Consolidated-Non SDN/Latest/',
'OFAC Consolidated Non SDN.zip','C:\TssFileDownload\Other_OFAC Consolidated Non SDN',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421',67 
GO
EXEC dbo.Sys_DropIfExists @ObjectName='RefWebFileLocation_InsertIfNotExists',@XType='p'
GO
GO
--WEB-66270-RC-END
