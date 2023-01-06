--WEB-66269-RC-START
GO
EXEC dbo.Sys_DropIfExists @ObjectName='RefAmlWatchListSource_UpdateIfNotExistsFilePath',@XType='p'
GO
GO
CREATE PROCEDURE dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath
(
	@FilePath VARCHAR(500),
	@ServerName VARCHAR(200),
	@SourceCode INT 
)
AS
BEGIN
	DECLARE 
	@InternalFilePath VARCHAR(500)=@FilePath,
	@InternalServerName VARCHAR(200)=@ServerName,
	@InternalSourceCode INT =@SourceCode,
	@RefAmlWatchListSourceId INT,
	@RefFtpSiteId INT,
	@SebiSourceCode INT,
	@RBISourceCode INT

	SET @RefAmlWatchListSourceId=(SELECT RefAmlWatchListSourceId FROM dbo.RefAmlWatchListSource WHERE SourceCode=CONVERT(VARCHAR(100),@InternalSourceCode))
	SET @SebiSourceCode=4
	SET @RBISourceCode=10

	SET @RefFtpSiteId=(SELECT RefFtpSiteId FROM dbo.RefFtpSite WHERE [Name]=@InternalServerName)
	
	IF( @RefFtpSiteId IS NULL)
		BEGIN
			SET @RefFtpSiteId=(SELECT RefFtpSiteId FROM dbo.RefAmlWatchListSource WHERE SourceCode=CONVERT(VARCHAR(100),@SebiSourceCode))
			IF(@RefFtpSiteId IS NULL)
				BEGIN
					SET @RefFtpSiteId=(SELECT RefFtpSiteId FROM dbo.RefAmlWatchListSource WHERE SourceCode=CONVERT(VARCHAR(100),@RBISourceCode))
				END
		END
	
	IF(@RefFtpSiteId IS NULL)
		BEGIN
			UPDATE ref
			SET ref.FilePath=@InternalFilePath
			FROM dbo.RefAmlWatchListSource ref
			WHERE ref.FilePath IS NULL AND ref.SourceCode=CONVERT(VARCHAR(100),@InternalSourceCode)
		END
	ELSE
		BEGIN
			UPDATE	ref
			SET ref.FilePath=@InternalFilePath,
			ref.RefFtpSiteId=@RefFtpSiteId
			FROM dbo.RefAmlWatchListSource ref
			WHERE ref.FilePath IS NULL AND ref.SourceCode=CONVERT(VARCHAR(100),@InternalSourceCode)
		END
END
GO
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/PEP/Supporting Docs' ,'TrackWizzFeeds',3
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/SEBI/Supporting Docs/CM' ,'TrackWizzFeeds',4
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/Arbitration_NSE/Supporting Docs' ,'TrackWizzFeeds',5
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/Arbitration_BSE/Supporting Docs' ,'TrackWizzFeeds',9
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/RBI_Willfull_Defaulters/Supporting Docs' ,'TrackWizzFeeds',10
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/ACE_Suspended_Members/Supporting Docss' ,'TrackWizzFeeds',14
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/BSE_Defaulter_Expelled_Members/Supporting Docs' ,'TrackWizzFeeds',15
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/ICEX_Defaulter_Members/Supporting Docs' ,'TrackWizzFeeds',16
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/ICEX_Expelled_Members/Supporting Docs' ,'TrackWizzFeeds',17
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MCX_Defaulter_Members/Supporting Docs' ,'TrackWizzFeeds',18
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/NCDEX_Sus_Def_Exp_Deb_Members/Supporting Docs' ,'TrackWizzFeeds',19
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/NMCE_Defaulted_Members/supporting Docs' ,'TrackWizzFeeds',20
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/NMCE_Expelled_Members/Supporting Docs' ,'TrackWizzFeeds',21
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MCA_Company_Defaulter_List/Supporting Docs' ,'TrackWizzFeeds',23
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MCA_Director_Defaulter_List/Supporting Docs' ,'TrackWizzFeeds',24
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/IRDA_Blacklisted_Agents/Supporting Docs' ,'TrackWizzFeeds',25
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MCA_Companies_Struck_Off_List/Supporting Docs' ,'TrackWizzFeeds',26
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MCA_Director_Disqualified_List/Supporting Docs' ,'TrackWizzFeeds',27
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MCA_Proclaimed_Offenders/Supporting Docs' ,'TrackWizzFeeds',28
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MCA_Secretaries_Defaulter_List/Supporting Docs' ,'TrackWizzFeeds',29
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/Interpol_Wanted_Persons/Supporting Docs' ,'TrackWizzFeeds',30
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MCX_Action_AP/Supporting Docs' ,'TrackWizzFeeds',37
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/NCLT_Orders/Supporting Docs' ,'TrackWizzFeeds',38
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/SFIO_Convicted Directors/Supporting Docs' ,'TrackWizzFeeds',39
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/SFIO_Proclaimed Offenders/Supporting Docs' ,'TrackWizzFeeds',40
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/Wildlife_Crime_Convicts/Supporting Docs' ,'TrackWizzFeeds',41
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/Income_tax_defaulters/Supporting Docs' ,'TrackWizzFeeds',42
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/CBI Wanted Person_Rewards/Supporting Docs' ,'TrackWizzFeeds',47
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MSE Defaulter Members/Supporting Docs' ,'TrackWizzFeeds',48
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MSE Expelled Members/Supporting Docs' ,'TrackWizzFeeds',49
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/Blacklisted Doctors' ,'TrackWizzFeeds',50
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/NBFC COR Cancellation_RBI/Supporting Docs' ,'TrackWizzFeeds',51
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/EOW Wanted List_Delhi/Supporting Docs' ,'TrackWizzFeeds',52
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/NSDL Frozen Accounts/Supporting Docs' ,'TrackWizzFeeds',54
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/ICAI Misconduct/Supporting Docs' ,'TrackWizzFeeds',55
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/ICCL Expelled and Defaulter Members/Supporting Docs' ,'TrackWizzFeeds',56
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/ISEI Defaulter Members/Supporting Docs' ,'TrackWizzFeeds',57
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/NCCL Sus Def Exp Members/Supporting Docs' ,'TrackWizzFeeds',58
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '	/TSS/Screening/NFRA Orders/Supporting Docs' ,'TrackWizzFeeds',59
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/NSEL Defaulter/Supporting Docs' ,'TrackWizzFeeds',60
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/NSCCLI Arbitration Awards/Supporting Docs' ,'TrackWizzFeeds',61
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/NSCCLI Cessation Membership/Supporting Docs' ,'TrackWizzFeeds',62
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MCX Expelled Members/Supporting Docs' ,'TrackWizzFeeds',63	
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MCX Members deac sus deb/Supporting Docs' ,'TrackWizzFeeds',64
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/MCX Disciplinary Action/Supporting Docs' ,'TrackWizzFeeds',65
GO
EXEC dbo.RefAmlWatchListSource_UpdateIfNotExistsFilePath '/TSS/Screening/Singapore Terrorist Sanctions/Supporting Docs' ,'TrackWizzFeeds',66
GO
EXEC dbo.Sys_DropIfExists @ObjectName='RefAmlWatchListSource_UpdateIfNotExistsFilePath',@XType='p'
GO
--WEB-66269-RC-END
