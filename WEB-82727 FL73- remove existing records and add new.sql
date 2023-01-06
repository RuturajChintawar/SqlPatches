--File:Tables:dbo:CoreEntityAttributeDetail:DML
--WEB-82727 RC START
GO
	DECLARE @UserDefineRefEnumValueId INT
	SET @UserDefineRefEnumValueId =  dbo.GetEnumValueId('EntityAttributeType','UserDefined')

	DELETE core FROM dbo.CoreEntityAttributeDetail core 
	INNER JOIN dbo.RefEntityAttribute ar ON core.RefEntityAttributeId = ar.RefEntityAttributeId AND ar.EntityAttributeTypeRefEnumValueId = @UserDefineRefEnumValueId

GO

GO
EXEC dbo.Sys_DropIfExists 'AddCoreEntityAttributeDetail_InsertAndUpdate_Custom','P'
GO
GO
	CREATE PROCEDURE dbo.AddCoreEntityAttributeDetail_InsertAndUpdate_Custom(
		@SegmentCode VARCHAR(100),
		@ScripCode VARCHAR(50),
		@Series VARCHAR(20),
		@InstrumentGroup VARCHAR(500),
		@InstrumentGroupType VARCHAR(500),
		@StartDate VARCHAR(20),
		@EndDate VARCHAR(20),
		@Remarks VARCHAR(500)
	)
	AS
	BEGIN
		DECLARE @UserDefineRefEnumValueId INT, @RefSegmentId INT, @InternalSegmentCode VARCHAR(100), @InternalScripCode VARCHAR(50), @InternalSeries VARCHAR(20),
			@InternalInstrumentGroup VARCHAR(500), @InternalInstrumentGroupType VARCHAR(500), @InternalStartDate VARCHAR(20), @InternalEndDate VARCHAR(20),
			@InternalRemarks VARCHAR(500), @InstrumentRefEntityTypeId INT, @RefEntityAttributeId INT,@CoreEntityAttributeValueId BIGINT,@StartDateTime DATETIME,
			@EndDateTime DATETIME,@RefInstrumentId INT

		SET @InternalSegmentCode = @SegmentCode
		SET @InternalScripCode = @ScripCode
		SET @InternalSeries = @Series
		SET @InternalInstrumentGroup = @InstrumentGroup
		SET @InternalInstrumentGroupType = @InstrumentGroupType
		SET @InternalStartDate = @StartDate
		SET @InternalEndDate = @EndDate
		SET @InternalRemarks = @Remarks

		SET @InstrumentRefEntityTypeId = dbo.GetEntityTypeByCode('Instrument')
		SET @UserDefineRefEnumValueId = dbo.GetEnumValueId('EntityAttributeType','UserDefined')
		
		SET @RefEntityAttributeId = (SELECT ref.RefEntityAttributeId FROM dbo.RefEntityAttribute ref 
										WHERE ref.ForRefEntityTypeId = @InstrumentRefEntityTypeId
										AND ref.EntityAttributeTypeRefEnumValueId = @UserDefineRefEnumValueId AND ref.[Name] = LTRIM(RTRIM(@InternalInstrumentGroup)))

		SET @CoreEntityAttributeValueId = (SELECT core.CoreEntityAttributeValueId FROM  dbo.CoreEntityAttributeValue core 
										WHERE core.RefEntityAttributeId = @RefEntityAttributeId AND core.UserDefinedValueName = LTRIM(RTRIM(@InternalInstrumentGroupType)))

		SET @RefSegmentId  = dbo.GetSegmentId(@InternalSegmentCode)

		SET @StartDateTime = CONVERT(DATETIME,LTRIM(RTRIM(@InternalStartDate)))
		
		SET @EndDateTime = CONVERT(DATETIME,LTRIM(RTRIM(@InternalEndDate))) 

		SET @RefInstrumentId = (SELECT inst.RefInstrumentId FROM dbo.RefInstrument inst WHERE inst.Code = @InternalScripCode AND inst.RefSegmentId = @RefSegmentId AND ISNULL(@InternalSeries,'') =ISNULL(inst.Series,'') )

		IF( ISNULL(@RefEntityAttributeId, 0) <> 0   AND  ISNULL(@RefInstrumentId,0) <> 0 AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.CoreEntityAttributeDetail de WHERE de.CoreEntityAttributeValueId = @CoreEntityAttributeValueId AND de.RefEntityAttributeId = @RefEntityAttributeId AND
									de.ForEntityId =  @RefInstrumentId AND  de.StartDate =  @StartDateTime ) )
		BEGIN
		INSERT INTO dbo.CoreEntityAttributeDetail (
			RefEntityAttributeId,
			ForEntityId,
			CoreEntityAttributeValueId,
			StartDate,
			EndDate,
			[Source],
			Remarks,
			AddedBy,
			AddedOn,
			LastEditedBy,
			EditedOn,
			RefSegmentId
			)
			VALUES(
				@RefEntityAttributeId,
				@RefInstrumentId,
				@CoreEntityAttributeValueId,
				@StartDateTime,
				@EndDateTime,
				'User',
				LTRIM(RTRIM(@InternalRemarks)),
				'System',
				GETDATE(),
				'System',
				GETDATE(),
				@RefSegmentId)
			END

	END
GO

GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '531453', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-Mar-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '540361', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '12-Aug-2018',@EndDate ='13-Sep-2022', @Remarks = 'Alias: Dwekam Industries Ltd'
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '534748', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-Mar-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '506863', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-Mar-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '531963', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-Mar-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '538423', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '538364', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '537954', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '535141', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539014', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '538861', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '538653', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = 'Date Of Dissemination BSE - 04-05-2018, 15-05-2018,30-10-2018'
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '531893', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539169', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '537820', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539217', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '540812', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '13-Jul-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '511064', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '16-Jul-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539679', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '19-Jul-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '538464', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '19-Jul-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '532183', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '24-Jul-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539123', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '07-Aug-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '540023', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '16-Aug-2018',@EndDate ='13-Sep-2022', @Remarks = 'Alias: MILLITOONS ENTERTAINMENT LTD'
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '538539', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '16-Aug-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '509835', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '14-Dec-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '511724', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Feb-2019',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '514330', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '27-Feb-2019',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539009', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '08-May-2019',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539884', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '08-May-2019',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '533012', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '22-Jul-2019',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539219', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Apr-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '540615', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Apr-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539770', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Apr-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '532880', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Oct-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539310', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '20-Oct-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '540360', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '28-Oct-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '532947', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '30-Dec-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539692', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '18-Feb-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '523151', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '08-Mar-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '540061', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '24-Jun-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '542803', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '16-Jul-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539800', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '17-Sep-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '517214', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Oct-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '543272', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '20-Oct-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '540595', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '20-Oct-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '540073', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '20-Oct-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '530163', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '08-Nov-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '505693', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-Nov-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '512463', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '09-Dec-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='BSE_CASH', @ScripCode = '539835', @Series = NULL,@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-Dec-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'MOHITIND', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-Mar-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'DANUBE', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '12-Aug-2018',@EndDate ='13-Sep-2022', @Remarks = 'Formerly Dwekam Industries Ltd'
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'STEELXIND', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-Mar-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'SWADEIN', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-Mar-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'UNICRSE', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-Mar-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'ALPSMOTOR', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'BCPAL', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'SKP', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'SRDL', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'KALPACOMME', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'AMSONS', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'EML', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = 'Date Of Dissemination BSE - 04-05-2018, 15-05-2018,30-10-2018'
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'SAWABUSI', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'FUNNY', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'VFL', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '04-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'SRESTHA', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-May-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'KMSL', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '13-Jul-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'APLAYA', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '16-Jul-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'KAPILRAJ', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '19-Jul-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'TPROJECT', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '19-Jul-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'GAYATRI', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '24-Jul-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'VBIND', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '07-Aug-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'COLORCHIPS', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '16-Aug-2018',@EndDate ='13-Sep-2022', @Remarks = 'Alias: MILLITOONS ENTERTAINMENT LTD'
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'JTAPARIA', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '16-Aug-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'PREMSYN', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '14-Dec-2018',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'BALFC', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Feb-2019',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'OBRSESY', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '27-Feb-2019',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'GBLIL', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '08-May-2019',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'DARSHANORNA', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '08-May-2019',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'LPDC', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '22-Jul-2019',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'MUL', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Apr-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = '7NR', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Apr-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'DARJEELING', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Apr-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'AGROPHOS', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Apr-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'MITTAL', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Oct-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'OMAXE', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Oct-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'THINKINK', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '20-Oct-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'LLFICL', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '28-Oct-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'IRB', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '30-Dec-2020',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'IFINSER', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '18-Feb-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'OTCO', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '08-Mar-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'AKG', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '16-Jun-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'BIGBLOC', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '24-Jun-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'ELLORATRAD', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '16-Jul-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'CHDCHEM', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '17-Sep-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'DIGISPICE', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '01-Oct-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'SAGARDEEP', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '14-Oct-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'EASEMYTRIP', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '20-Oct-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'TEJASNET', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '20-Oct-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'BLS', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '20-Oct-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'KERALAYUR', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '08-Nov-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'LATIMMETAL', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '15-Nov-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'SHRGLTR', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '12-9-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'SUPERIOR', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Historical Scripts', @StartDate = '12-15-2021',@EndDate ='13-Sep-2022', @Remarks = NULL
GO
EXEC AddCoreEntityAttributeDetail_InsertAndUpdate_Custom @SegmentCode ='NSE_CASH', @ScripCode = 'ATLANTA', @Series = 'EQ',@InstrumentGroup ='SMS Scrip Watchlist', @InstrumentGroupType = 'Information Watchlist', @StartDate = '10-31-2022',@EndDate =NULL, @Remarks = NULL
GO

EXEC dbo.Sys_DropIfExists 'AddCoreEntityAttributeDetail_InsertAndUpdate_Custom','P'
GO
--WEB-82727 RC END

--File:Tables:dbo:RefWebFileLocation:DML
--WEB-82727 RC START
GO
	DECLARE @RefSegmentId INT, @RefAmlFileTypeId INT,@RefProtocolId INT,@RefProcessId INT,@pickUpEnumValueId INT

	SET @RefSegmentId = dbo.GetSegmentId('Other')
	SELECT @RefAmlFileTypeId = ty.RefAmlFileTypeId FROM dbo.RefAmlFileType ty WHERE ty.[Name] ='FL73_Instrument Group Type Master Upload'
	SELECT @RefProtocolId = pro.RefProtocolId FROM dbo.RefProtocol pro WHERE pro.[Name] ='Sftp'
	SELECT @RefProcessId = pro.RefProcessId FROM dbo.RefProcess pro WHERE pro.Code = 'J1480'
	SELECT @pickUpEnumValueId = dbo.GetEnumValueId('FileTask','Pickup')
	IF(NOT EXISTS(SELECT TOP 1 1 FROM dbo.RefWebFileLocation ref WHERE ref.RefSegmentId = @RefSegmentId AND ref.RefAmlFileTypeId = @RefAmlFileTypeId  AND ref.RefProcessId = @RefProcessId AND ref.[Name] ='Unsolicited Stock Tip Messages.zip'))
	BEGIN
	 INSERT INTO dbo.RefWebFileLocation
	 (
		RefSegmentId,
		RefAmlFileTypeId,
		RefProtocolId,
		FtpRemoteDirectory,
		[Name],
		LocalDirectory,
		AddedBy,
		AddedOn,
		LastEditedBy,
		EditedOn,
		RefProcessId,
		TaskRefEnumValueId,
		PriorityLevel,
		DownloadDateOffset
		

	 )
	 VALUES(
		@RefSegmentId,
		@RefAmlFileTypeId,
		@RefProtocolId,
		'/TSS/Screening/Unsolicited Stock Tip Messages/Latest',
		'Unsolicited Stock Tip Messages.zip',
		'C:\TssFileDownload\Other_FL73\',
		'System',
		GETDATE(),
		'System',
		GETDATE(),
		@RefProcessId,
		@pickUpEnumValueId,
		0,
		0
	 )
	END

GO
--WEB-82727 RC END
