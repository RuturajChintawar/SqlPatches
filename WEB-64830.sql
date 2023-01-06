--WEB-64830-RC-START
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
	@SourceName VARCHAR (2000) = NULL
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
	@InternalSourceName VARCHAR(100)=@SourceName,
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
	 
	SET @RefAmlWatchListSourceId = (SELECT RefAmlWatchListSourceId FROM dbo.RefAmlWatchListSource WHERE [Name]=@InternalSourceName)
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
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/CBI Wanted Person_Rewards/Latest','CBI Wanted Person Rewards.zip','C:\TssFileDownload\Other_CBI_Wanted_Person_Rewards',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421','CBI Wanted Person Rewards' 
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/MSE Defaulter Members/Latest','MSE Defaulter Members.zip','C:\TssFileDownload\Other_MSE_Defaulter',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,'MSE Defaulter Members'
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/MSE Expelled Members/Latest','MSE Expelled Members.zip','C:\TssFileDownload\Other_MSE_expelled_members',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,'MSE expelled members'
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/Blacklisted Doctors/Latest','Blacklisted Doctors.zip','C:\TssFileDownload\Other_Blacklisted_Doctors',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,'Blacklisted Doctors'
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/NBFC COR Cancellation_RBI/Latest','NBFC Cor Cancellation_RBI.zip','C:\TssFileDownload\Other_NBFC_Cor_Cancellation_-RBI',0,0,0,'Pickup','TrackWizzFeeds',NULL,'J1421','NBFC Cor Cancellation -RBI'  
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/EOW Wanted List_Delhi/Latest','EOW Wanted List_Delhi.zip','C:\TssFileDownload\Other_EOW_Wanted_List-Delhi',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,'EOW Wanted List-Delhi'
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/DSE Suspended Companies/Latest','DSE Suspended Companies.zip','C:\TssFileDownload\Other_DSE_Suspended_Companies',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,'DSE Suspended Companies'
GO
EXEC dbo.RefWebFileLocation_InsertIfNotExists 'Other','FL78_TrackWizz_Screening_Standard_Feed','sftp','/TSS/Screening/ICAI Misconduct/Latest','ICAI Misconduct.zip','C:\TssFileDownload\Other_ICAI_Misconduct',0,0,0,'Pickup','TrackWizzFeeds',NULL ,'J1421' ,'ICAI Misconduct'
GO
GO
EXEC dbo.Sys_DropIfExists @ObjectName='RefWebFileLocation_InsertIfNotExists',@XType='p'
GO
--WEB-64830-RC-END
delete from RefWebFileLocation where RefWebFileLocationId between 535 and 542