--WEB-83715 RC START
GO
EXEC dbo.Sys_DropIfExists 'AddRefBankMicr_InsertAndUpdate_Custom','P'
GO
GO
	CREATE PROCEDURE dbo.AddRefBankMicr_InsertAndUpdate_Custom(
		@MicrNo VARCHAR(20),
		@IfscCode VARCHAR(100),
		@BankName VARCHAR(100),
		@Address VARCHAR(500)
	)
	AS
	BEGIN
		DECLARE
		@MicrNoInternal VARCHAR(20), @IfscCodeInternal VARCHAR(100), @BankNameInternal VARCHAR(100),@AddressInternal VARCHAR(500), @CurrDate DATETIME

		SET @MicrNoInternal = @MicrNo
		SET @IfscCodeInternal = @IfscCode
		SET @BankNameInternal = @BankName
		SET @AddressInternal = @Address
		SET @CurrDate = GETDATE()

		IF(NOT EXISTS (SELECT TOP 1 1 FROM dbo.RefBankMicr micr WHERE micr.MicrNo = @MicrNoInternal AND micr.IfscCode = @IfscCodeInternal ))
			BEGIN
				INSERT INTO dbo.RefBankMicr
				(
					MicrNo,
					[Name],
					IfscCode,
					[Address],
					AddedBy,
					AddedOn,
					LastEditedBy,
					EditedOn
				)
				VALUES(
					@MicrNoInternal,
					@BankNameInternal,
					@IfscCodeInternal,
					@AddressInternal,
					'System',
					@CurrDate,
					'System',
					@CurrDate
				
				)
			END


	END
GO
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5039',@BankName = 'BANK OF INDIA',@Address = 'MURMADI, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5040',@BankName = 'BANK OF INDIA',@Address = 'PANDHARI, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5041',@BankName = 'BANK OF INDIA',@Address = 'RAWANWADI, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5042',@BankName = 'BANK OF INDIA',@Address = 'SADAK ARJUNI, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5043',@BankName = 'BANK OF INDIA',@Address = 'SALEKASA, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5044',@BankName = 'BANK OF INDIA',@Address = 'SUKADI, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5045',@BankName = 'BANK OF INDIA',@Address = 'TIRORA, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5046',@BankName = 'BANK OF INDIA',@Address = 'HUDKESHWAR, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '688009052' , @IfscCode = 'SBIN0070081',@BankName = 'STATE BANK OF INDIA',@Address = 'PB NO1,NEW BUILDINGS,, CHERTHALA, KERALA, INDIA, 688524'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '695177008' , @IfscCode = 'KSBK0000002',@BankName = 'THE KERALA STATE CO-OPERATIVE BANK LTD',@Address = 'STATUE, THIRUVANANTHAPURAM, KERALA, INDIA, 695001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '400079006' , @IfscCode = 'TMSB0000006',@BankName = 'THE MALAD SAHAKARI BANK LTD',@Address = 'KANDIVALI BRANCH, MUMBAI, MAHARASHTRA, INDIA, 400101'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '464240102' , @IfscCode = 'HDFC0006342',@BankName = 'HDFC BANK LTD',@Address = 'VIDISHA 2, VIDISHA, MADHYA PRADESH, INDIA, 464001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '532026026' , @IfscCode = 'UBIN0801330',@BankName = 'UNION BANK OF INDIA',@Address = 'MANDAVAKURITY, MANDAVAKURITY, ANDHRA PRADESH, INDIA, 532168'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '364662006' , @IfscCode = 'SGBA0000275',@BankName = 'SAURASHTRA GRAMIN BANK',@Address = 'BHARATNAGAR BRANCH, BHAVNAGAR, BHAVNAGAR, BHAVNAGAR, GUJARAT, INDIA, 364002'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '000234000' , @IfscCode = 'INDB0001383',@BankName = 'INDUSIND BANK',@Address = 'VASANT VIHAR, NEW DELHI, DELHI, INDIA, 110057'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '247019313' , @IfscCode = 'IDIB000U526',@BankName = 'INDIAN BANK',@Address = 'UN(4149), PRABUDH NAGAR, UTTAR PRADESH, INDIA, 247778'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '721024323' , @IfscCode = 'PUNB0127620',@BankName = 'PUNJAB NATIONAL BANK',@Address = 'SANDHIPUR, MEDINIPUR, WEST BENGAL, INDIA, 721133'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '508026046' , @IfscCode = 'UBIN0823333',@BankName = 'UNION BANK OF INDIA',@Address = 'DAMERCHERLA, NALGONDA, TELANGANA, INDIA, 508355'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '506019006' , @IfscCode = 'IDIB000W505',@BankName = 'INDIAN BANK',@Address = 'TELENGANA, TELENGANA, TELENGANA, INDIA, 506002'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '276026002' , @IfscCode = 'UBIN0554448',@BankName = 'UNION BANK OF INDIA',@Address = 'NEAR CHANAKYA CINEMA HALL, SAFRUDDINOUR, AZAMGARH, AZAMGARH, UTTAR PRADESH, INDIA, 276001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '262019711' , @IfscCode = 'IDIB000A616',@BankName = 'INDIAN BANK',@Address = 'AMRITGANJ, KHERI, UTTAR PRADESH, INDIA, 262721'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '400011049' , @IfscCode = 'UBIN0822841',@BankName = 'UNION BANK OF INDIA',@Address = 'A LLX L L A AW BHANDUP, MUMBAI, MAHARASHTRA, INDIA, 400078'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '224240503' , @IfscCode = 'HDFC0006298',@BankName = 'HDFC BANK LTD',@Address = 'UPPER GROUND AND 1 ST FLOOR, GATE NO 258 NAVIN MANDI NAKA, MUJJFRABAD ROAD, FAIZABAD, UTTAR PRADESH, INDIA, 224001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '285014102' , @IfscCode = 'MAHB0002174',@BankName = 'BANK OF MAHARASHTRA',@Address = 'ORAI, JALAUN, UTTAR PRADESH, INDIA, 285001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '135696011' , @IfscCode = 'PUNB0HGB001',@BankName = 'SARVA HARYANA GRAMIN BANK',@Address = 'VPO DAMLA, YAMUNA NAGAR, HARYANA, INDIA, 135001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '302240059' , @IfscCode = 'HDFC0006983',@BankName = 'HDFC BANK LTD',@Address = 'GANGORI BAZAR JAIPUR, JAIPUR, RAJASTHAN, INDIA, 302001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '691768002' , @IfscCode = 'IPOS0000001',@BankName = 'INDIA POST PAYMENTS BANK',@Address = 'Mumbai, Mumbai, Maharashtra, INDIA, 110001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '500229135' , @IfscCode = 'ICIC0007712',@BankName = 'ICICI BANK',@Address = 'HYDERABAD INFOSYS SOLUTION HUB, GHATKESAR, TELANGANA, INDIA, 500088'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '764026205' , @IfscCode = 'UBIN0813010',@BankName = 'UNION BANK OF INDIA',@Address = 'UMARKOTE, NAWRANGPUR, ODISHA, INDIA, 764073'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '560240206' , @IfscCode = 'HDFC0000984',@BankName = 'HDFC BANK LTD',@Address = 'BALAGERE, BANGALORE, KARNATAKA, INDIA, 560087'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '263184301' , @IfscCode = 'NTBL0NAI999',@BankName = 'THE NAINITAL BANK LTD',@Address = 'HEAD OFFICE, G.B.PANT ROAD, SEVEN OAKS BUILDING, NAINITAL, UTTARAKHAND, INDIA, 263001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '322010002' , @IfscCode = 'IDIB0008598',@BankName = 'INDIAN BANK',@Address = 'SAWAI MADHOPUR, OPP POLICE ANVESHAN BHAVAN, DAUSA ROAD, SAWAI MADHOPUR, RAJASTHA, INDIA, 322001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '385012512' , @IfscCode = 'BARB0THARAX',@BankName = 'BANK OF BARODA',@Address = 'THARA BRANCH, THARA, GUJARAT, INDIA, 385555'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '411002091' , @IfscCode = 'SBIN0010431',@BankName = 'STATE BANK OF INDIA',@Address = 'PUNE, PUNE, MAHARASHTRA, INDIA, 411005'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '360662510' , @IfscCode = 'SGBA0000138',@BankName = 'SAURASHTRA GRAMIN BANK',@Address = 'AT POST BHANGOR, TA JAMJODHPUR, JAMNAGAR, GUJARAT, INDIA, 361001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '521026060' , @IfscCode = 'UBIN0805637',@BankName = 'UNION BANK OF INDIA',@Address = 'TIRUVUR, KRISHNA, KRISHNA, ANDHRA PRADESH, INDIA, 521235'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '500765004' , @IfscCode = 'AUBL0002612',@BankName = 'AU SMALL FINANCE BANK',@Address = 'S R NAGAR HYDERABAD, HYDERABAD, TELANGANA, INDIA, 500038'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '757768002' , @IfscCode = 'IPOS0000001',@BankName = 'INDIA POST PAYMENT BANK',@Address = 'SPEED POST CENTRE, BUILDING, MARKET ROAD NEW DELHI, NEW DELHI, DELHI, INDIA, 110001'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '791240004' , @IfscCode = 'HDFC0007317',@BankName = 'HDFC BANK LTD',@Address = 'ZIRO, LOWER SUBANSIRI, ZIRO, LOWER SUBANSIRI, LOWER SUBANSIRI,ARUNACHAL PRAD, LOWER SUBANSIRI, ARUNACHAL PRADESH, INDIA, 791120'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'AUBL0002669',@BankName = 'AU SMALL FINANCE BANK LTD',@Address = 'BANGLORE, BANGALORE, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'AUBL0002670',@BankName = 'AU SMALL FINANCE BANK LTD',@Address = 'KOCHI, ERNAKULAM, KERALA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'AUBL0002673',@BankName = 'AU SMALL FINANCE BANK LTD',@Address = 'BHOPAL, BHOPAL, MADHYA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BARB0HOPARD',@BankName = 'BANK OF BARODA',@Address = 'JODHPUR, JODHPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BARB0MIDCLK',@BankName = 'BANK OF BARODA',@Address = 'KOLKATA, KOLKATA, WEST BENGAL, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BARB0MIDCLS',@BankName = 'BANK OF BARODA',@Address = 'CHENNAI, CHENNAI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BARB0RAIMAL',@BankName = 'BANK OF BARODA',@Address = 'JODHPUR, JODHPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BARB0SMECOI',@BankName = 'BANK OF BARODA',@Address = 'COIMBATORE, COIMBATORE, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0006284',@BankName = 'BANK OF INDIA',@Address = 'MOTIHARI, EAST CHAMPARAN, BIHAR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0006285',@BankName = 'BANK OF INDIA',@Address = 'MOTIHARI, EAST CHAMAPARAN, BIHAR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0008929',@BankName = 'BANK OF INDIA',@Address = 'POLAKHAL, DEWAS, MADHYA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0AG0302',@BankName = 'BANK OF INDIA',@Address = 'LUCKNOW, BARA BANKI, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0MG0101',@BankName = 'BANK OF INDIA',@Address = 'DEWAS, DEWAS, MADHYA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0MG0447',@BankName = 'BANK OF INDIA',@Address = 'INDORE, INDORE, MADHYA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0MG9000',@BankName = 'BANK OF INDIA',@Address = 'GWALIOR, GWALIOR, MADHYA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0MG9999',@BankName = 'BANK OF INDIA',@Address = 'INDORE, INDORE, MADHYA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG0000',@BankName = 'BANK OF INDIA',@Address = 'NEW MUMBAI, THANE, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG1100',@BankName = 'BANK OF INDIA',@Address = 'MUMBAI, MUMBAI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG4052',@BankName = 'BANK OF INDIA',@Address = 'SIRONCHA, GADCHIROLI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG4053',@BankName = 'BANK OF INDIA',@Address = 'WADADHA, GADCHIROLI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG4054',@BankName = 'BANK OF INDIA',@Address = 'WADASA, GADCHIROLI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG4055',@BankName = 'BANK OF INDIA',@Address = 'HINGANGHAT, WARDHA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG4056',@BankName = 'BANK OF INDIA',@Address = 'WARDHA, WARDHA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG4057',@BankName = 'BANK OF INDIA',@Address = 'DEOLI, WARDHA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG4058',@BankName = 'BANK OF INDIA',@Address = 'ARVI, WARDHA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG4059',@BankName = 'BANK OF INDIA',@Address = 'KARANJA G, WARDHA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG4060',@BankName = 'BANK OF INDIA',@Address = 'MURUMGAON, GADCHIROLI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG4062',@BankName = 'BANK OF INDIA',@Address = 'ANJI MOTHI, WARDHA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG4063',@BankName = 'BANK OF INDIA',@Address = 'NAVEGAON, GADCHIROLI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5000',@BankName = 'BANK OF INDIA',@Address = 'BHANDARA, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5001',@BankName = 'BANK OF INDIA',@Address = 'ADYAL, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5002',@BankName = 'BANK OF INDIA',@Address = 'ASGAON, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5003',@BankName = 'BANK OF INDIA',@Address = 'BARWA, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5004',@BankName = 'BANK OF INDIA',@Address = 'BHANDARA, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5005',@BankName = 'BANK OF INDIA',@Address = 'DIGHORI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5006',@BankName = 'BANK OF INDIA',@Address = 'GARRA-BAGHEDA, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5007',@BankName = 'BANK OF INDIA',@Address = 'GONDEKHARI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5008',@BankName = 'BANK OF INDIA',@Address = 'LAKHANDUR, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5009',@BankName = 'BANK OF INDIA',@Address = 'LAKHANI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5010',@BankName = 'BANK OF INDIA',@Address = 'MANEGAON, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5011',@BankName = 'BANK OF INDIA',@Address = 'MANGALI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5012',@BankName = 'BANK OF INDIA',@Address = 'MOHADI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5013',@BankName = 'BANK OF INDIA',@Address = 'NAKADONGRI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5014',@BankName = 'BANK OF INDIA',@Address = 'PALANDUR, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5015',@BankName = 'BANK OF INDIA',@Address = 'PARSODI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5016',@BankName = 'BANK OF INDIA',@Address = 'PAONI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5017',@BankName = 'BANK OF INDIA',@Address = 'SAKOLI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5018',@BankName = 'BANK OF INDIA',@Address = 'SANGADI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5019',@BankName = 'BANK OF INDIA',@Address = 'THANA BHANDARA, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5020',@BankName = 'BANK OF INDIA',@Address = 'TUMSAR, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5021',@BankName = 'BANK OF INDIA',@Address = 'VIRLI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5022',@BankName = 'BANK OF INDIA',@Address = 'ADASI, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5023',@BankName = 'BANK OF INDIA',@Address = 'AMGAON, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5024',@BankName = 'BANK OF INDIA',@Address = 'ARJUNI MORGAON, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5025',@BankName = 'BANK OF INDIA',@Address = 'BONDGAON, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5026',@BankName = 'BANK OF INDIA',@Address = 'CHOPA, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5027',@BankName = 'BANK OF INDIA',@Address = 'DASGAON, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5028',@BankName = 'BANK OF INDIA',@Address = 'DEORI, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5029',@BankName = 'BANK OF INDIA',@Address = 'FULCHUR, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5030',@BankName = 'BANK OF INDIA',@Address = 'GONDIA, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5031',@BankName = 'BANK OF INDIA',@Address = 'GOREGAON, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5032',@BankName = 'BANK OF INDIA',@Address = 'KAKODI, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5033',@BankName = 'BANK OF INDIA',@Address = 'KALIMATI, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5034',@BankName = 'BANK OF INDIA',@Address = 'KATANGIKALA, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5035',@BankName = 'BANK OF INDIA',@Address = 'KAWARABANDH, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5036',@BankName = 'BANK OF INDIA',@Address = 'KUDWA, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5037',@BankName = 'BANK OF INDIA',@Address = 'KURHADI, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5038',@BankName = 'BANK OF INDIA',@Address = 'MAHAGAON, GONDIA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5047',@BankName = 'BANK OF INDIA',@Address = 'MAUDA, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5048',@BankName = 'BANK OF INDIA',@Address = 'UMRED, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5049',@BankName = 'BANK OF INDIA',@Address = 'KHAMALA, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5050',@BankName = 'BANK OF INDIA',@Address = 'HINGNA, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5052',@BankName = 'BANK OF INDIA',@Address = 'PARDI, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5053',@BankName = 'BANK OF INDIA',@Address = 'RAMTEK, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5054',@BankName = 'BANK OF INDIA',@Address = 'BELA, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5055',@BankName = 'BANK OF INDIA',@Address = 'MOHAPA, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5056',@BankName = 'BANK OF INDIA',@Address = 'PATANSAONGI, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5057',@BankName = 'BANK OF INDIA',@Address = 'TARSA, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5058',@BankName = 'BANK OF INDIA',@Address = 'BELONA, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG5100',@BankName = 'BANK OF INDIA',@Address = 'NAGPUR, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6000',@BankName = 'BANK OF INDIA',@Address = 'AKOLA, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6001',@BankName = 'BANK OF INDIA',@Address = 'AKOLA, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6002',@BankName = 'BANK OF INDIA',@Address = 'UGAWA, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6003',@BankName = 'BANK OF INDIA',@Address = 'ALEGAON, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6004',@BankName = 'BANK OF INDIA',@Address = 'URAL, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6005',@BankName = 'BANK OF INDIA',@Address = 'RAJANDA, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6006',@BankName = 'BANK OF INDIA',@Address = 'CHANNI, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6007',@BankName = 'BANK OF INDIA',@Address = 'UMARA, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6008',@BankName = 'BANK OF INDIA',@Address = 'HIWARKHED, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6009',@BankName = 'BANK OF INDIA',@Address = 'CHOTTABAZAR, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6010',@BankName = 'BANK OF INDIA',@Address = 'BALAPUR, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6011',@BankName = 'BANK OF INDIA',@Address = 'JAMATHI, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6012',@BankName = 'BANK OF INDIA',@Address = 'BORGAON MANJU, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6013',@BankName = 'BANK OF INDIA',@Address = 'TELHARA, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6014',@BankName = 'BANK OF INDIA',@Address = 'KANHERI SARAP, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6015',@BankName = 'BANK OF INDIA',@Address = 'OLD CITY AKOLA, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6016',@BankName = 'BANK OF INDIA',@Address = 'APATAPA, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6018',@BankName = 'BANK OF INDIA',@Address = 'ANDURA, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6019',@BankName = 'BANK OF INDIA',@Address = 'MURTIZAPUR, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6020',@BankName = 'BANK OF INDIA',@Address = 'GAIGAON, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6021',@BankName = 'BANK OF INDIA',@Address = 'AKOT, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6022',@BankName = 'BANK OF INDIA',@Address = 'MOTHI UMARI, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6023',@BankName = 'BANK OF INDIA',@Address = 'MALKAPUR AKOLA, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6024',@BankName = 'BANK OF INDIA',@Address = 'MHAISANG, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6025',@BankName = 'BANK OF INDIA',@Address = 'BARSHI TAKALI, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6026',@BankName = 'BANK OF INDIA',@Address = 'PATUR, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6027',@BankName = 'BANK OF INDIA',@Address = 'BULDANA, BULDHANA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6028',@BankName = 'BANK OF INDIA',@Address = 'VIVEKANAND NAGAR, BULDHANA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6029',@BankName = 'BANK OF INDIA',@Address = 'ANDHERA, BULDHANA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG6030',@BankName = 'BANK OF INDIA',@Address = 'KHAMGAON, BULDHANA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7013',@BankName = 'BANK OF INDIA',@Address = 'GIROLI, WASHIM, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7014',@BankName = 'BANK OF INDIA',@Address = 'MANGRULPIR, WASHIM, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7015',@BankName = 'BANK OF INDIA',@Address = 'RISOD, WASHIM, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7016',@BankName = 'BANK OF INDIA',@Address = 'MANORA, WASHIM, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7017',@BankName = 'BANK OF INDIA',@Address = 'KARANJA, WASHIM, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7018',@BankName = 'BANK OF INDIA',@Address = 'YAVATMAL, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7019',@BankName = 'BANK OF INDIA',@Address = 'SAWAR, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7020',@BankName = 'BANK OF INDIA',@Address = 'PANDHARKAWADA, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7021',@BankName = 'BANK OF INDIA',@Address = 'AKOLA BAZAR, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7022',@BankName = 'BANK OF INDIA',@Address = 'KARANJI, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7023',@BankName = 'BANK OF INDIA',@Address = 'KURLI, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7024',@BankName = 'BANK OF INDIA',@Address = 'RALEGAON, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7025',@BankName = 'BANK OF INDIA',@Address = 'GHARFAL, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7026',@BankName = 'BANK OF INDIA',@Address = 'GHATANJI, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7027',@BankName = 'BANK OF INDIA',@Address = 'ARNI, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7028',@BankName = 'BANK OF INDIA',@Address = 'DARWHA, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7029',@BankName = 'BANK OF INDIA',@Address = 'HARSHI, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7030',@BankName = 'BANK OF INDIA',@Address = 'HIWARA, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7031',@BankName = 'BANK OF INDIA',@Address = 'MUKUTBAN, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7032',@BankName = 'BANK OF INDIA',@Address = 'BANSI, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7033',@BankName = 'BANK OF INDIA',@Address = 'DIGRAS, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7034',@BankName = 'BANK OF INDIA',@Address = 'WANI, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7035',@BankName = 'BANK OF INDIA',@Address = 'BABHULGAON, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7036',@BankName = 'BANK OF INDIA',@Address = 'WADGAON, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7037',@BankName = 'BANK OF INDIA',@Address = 'MAREGAON, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7038',@BankName = 'BANK OF INDIA',@Address = 'NER, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7039',@BankName = 'BANK OF INDIA',@Address = 'UMARKHED, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7040',@BankName = 'BANK OF INDIA',@Address = 'PUSAD, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7041',@BankName = 'BANK OF INDIA',@Address = 'BADNERA, AMARAVATI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7042',@BankName = 'BANK OF INDIA',@Address = 'AMRAVATI, AMARAVATI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7043',@BankName = 'BANK OF INDIA',@Address = 'MORSHI, AMARAVATI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7044',@BankName = 'BANK OF INDIA',@Address = 'PARATWADA, AMARAVATI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7045',@BankName = 'BANK OF INDIA',@Address = 'DHAMANGAON, AMARAVATI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7046',@BankName = 'BANK OF INDIA',@Address = 'KHANDESHWAR, AMARAVATI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7047',@BankName = 'BANK OF INDIA',@Address = 'SHIRASGAON KASBA, AMARAVATI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7048',@BankName = 'BANK OF INDIA',@Address = 'RUNZA, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7049',@BankName = 'BANK OF INDIA',@Address = 'ZARIJAMNI, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7050',@BankName = 'BANK OF INDIA',@Address = 'TIWASA, AMARAVATI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7051',@BankName = 'BANK OF INDIA',@Address = 'MOZARI, AMARAVATI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'BKID0VG7052',@BankName = 'BANK OF INDIA',@Address = 'PIMPALGAON, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CNRB0007263',@BankName = 'CANARA BANK',@Address = 'AGRA, AGRA, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CNRB0007326',@BankName = 'CANARA BANK',@Address = 'SAGAR, SHIVAMOGGA, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CNRB0007329',@BankName = 'CANARA BANK',@Address = 'KARWAR, UTTAR KANNADA, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000690',@BankName = 'CSB BANK LTD',@Address = 'PATIALA, PATIALA, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000691',@BankName = 'CSB BANK LTD',@Address = 'VILLUPURAM, VILLUPURAM, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000692',@BankName = 'CSB BANK LTD',@Address = 'HARUR, DHARMAPURI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000693',@BankName = 'CSB BANK LTD',@Address = 'AMBAJIPETA, EAST GODAVARI, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000694',@BankName = 'CSB BANK LTD',@Address = 'CHILAKALURIPETA, GUNTUR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000695',@BankName = 'CSB BANK LTD',@Address = 'GANNAVARAM, KRISHNA, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000696',@BankName = 'CSB BANK LTD',@Address = 'HANUMAN JUNCTION, KRISHNA, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000697',@BankName = 'CSB BANK LTD',@Address = 'GURUGRAM, GURUGRAM, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000698',@BankName = 'CSB BANK LTD',@Address = 'ASWARAOPETA, BHADRADRI KOTHAGUDEM, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000699',@BankName = 'CSB BANK LTD',@Address = 'LAJPAT NAGAR, SOUTH EAST DELHI, DELHI, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000700',@BankName = 'CSB BANK LTD',@Address = 'VELACHERY, CHENNAI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000701',@BankName = 'CSB BANK LTD',@Address = 'GREATER NOIDA, GAUTHAM BUDH NAGAR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000703',@BankName = 'CSB BANK LTD',@Address = 'SHAMSHABAD, RANGAREDDY, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000704',@BankName = 'CSB BANK LTD',@Address = 'CHANDIGARH, CHANDHIGARH, CHANDIGARH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000705',@BankName = 'CSB BANK LTD',@Address = 'PANCHKULA, PANCHKULA, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000706',@BankName = 'CSB BANK LTD',@Address = 'BOBBILI, VIZIANAGARAM, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000707',@BankName = 'CSB BANK LTD',@Address = 'ISUKAPALLE, GUNTUR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000708',@BankName = 'CSB BANK LTD',@Address = 'NARASAPUR, WEST GODAVARI, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000709',@BankName = 'CSB BANK LTD',@Address = 'PARVATHIPURAM, VIZIANAGARAM, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000710',@BankName = 'CSB BANK LTD',@Address = 'JUVVALAPALEM, WEST GODAVARI, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000711',@BankName = 'CSB BANK LTD',@Address = 'AMBALA, AMBALA, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000712',@BankName = 'CSB BANK LTD',@Address = 'GURDASPUR, GURDASPUR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000713',@BankName = 'CSB BANK LTD',@Address = 'KARNAL, KARNAL, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000714',@BankName = 'CSB BANK LTD',@Address = 'KURUKSHETRA, KURUKSHETRA, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000716',@BankName = 'CSB BANK LTD',@Address = 'AHMEDABAD, AHMEDABAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000718',@BankName = 'CSB BANK LTD',@Address = 'BANER, PUNE, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000719',@BankName = 'CSB BANK LTD',@Address = 'GHODBUNDER ROAD, THANE, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000721',@BankName = 'CSB BANK LTD',@Address = 'SURAT VARACHHA, SURAT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000722',@BankName = 'CSB BANK LTD',@Address = 'BELLARY, BELLARY, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000723',@BankName = 'CSB BANK LTD',@Address = 'NARAYANAPURAM, WEST GODAVARI, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000724',@BankName = 'CSB BANK LTD',@Address = 'DRAKSHARAMA, EAST GODAVARI, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000725',@BankName = 'CSB BANK LTD',@Address = 'NARSAMPET, WARANGAL RURAL, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000726',@BankName = 'CSB BANK LTD',@Address = 'BIKANER, BIKANER, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000727',@BankName = 'CSB BANK LTD',@Address = 'JODHPUR, JODHPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000728',@BankName = 'CSB BANK LTD',@Address = 'BHATINDA, BHATINDA, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000729',@BankName = 'CSB BANK LTD',@Address = 'LUDHIANA, LUDHIANA, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000731',@BankName = 'CSB BANK LTD',@Address = 'KARLAPALEM, GUNTUR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000732',@BankName = 'CSB BANK LTD',@Address = 'RAVIPADU, GUNTUR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000733',@BankName = 'CSB BANK LTD',@Address = 'DHARMAPURI, DHARMAPURI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000735',@BankName = 'CSB BANK LTD',@Address = 'KARIMNAGAR, KARIMNAGAR, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000738',@BankName = 'CSB BANK LTD',@Address = 'NOIDA, GAUTAM BUDH NAGAR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000739',@BankName = 'CSB BANK LTD',@Address = 'PANIPAT, PANIPAT, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000740',@BankName = 'CSB BANK LTD',@Address = 'LAXMI NAGAR, NEW DELHI, DELHI, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000742',@BankName = 'CSB BANK LTD',@Address = 'GAJAPATHINAGARAM, VIZIANAGARAM, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000743',@BankName = 'CSB BANK LTD',@Address = 'PEENYA, BANGALORE URBAN, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000744',@BankName = 'CSB BANK LTD',@Address = 'JP NAGAR, BANGALORE URBAN, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000747',@BankName = 'CSB BANK LTD',@Address = 'KRISHNAGIRI, KRISHNAGIRI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000748',@BankName = 'CSB BANK LTD',@Address = 'JALANDHAR, JALANDHAR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'CSBK0000751',@BankName = 'CSB BANK LTD',@Address = 'JANGAON, JANGAON, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'DLXB0000284',@BankName = 'DHANALAKSHMI BANK',@Address = 'KURNOOL, KURNOOL, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'DLXB0000285',@BankName = 'DHANALAKSHMI BANK',@Address = 'CHERPULASSERY, PALAKKAD, KERALA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'DLXB0000286',@BankName = 'DHANALAKSHMI BANK',@Address = 'KOYILANDY, KOZHIKODE, KERALA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ESFB0009153',@BankName = 'EQUITAS SMALL FINANCE BANK LTD',@Address = 'MUMBAI, MUMBAI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ESFB0009154',@BankName = 'EQUITAS SMALL FINANCE BANK LTD',@Address = 'MUMBAI, MUMBAI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ESMF0001700',@BankName = 'ESAF SMALL FINANCE BANK LTD',@Address = 'BALANGIR, BALANGIR, ODISHA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002378',@BankName = 'FEDERAL BANK',@Address = 'HYDERABAD, RANGAREDDY, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002379',@BankName = 'FEDERAL BANK',@Address = 'MAYILADUTHURAI, MAYILADUTHURAI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002380',@BankName = 'FEDERAL BANK',@Address = 'AHMEDABAD, AHMEDABAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002381',@BankName = 'FEDERAL BANK',@Address = 'AHMEDABAD, AHMEDABAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002382',@BankName = 'FEDERAL BANK',@Address = 'BANGALORE, BANGALORE, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002383',@BankName = 'FEDERAL BANK',@Address = 'BANGALORE, BANGALORE, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002384',@BankName = 'FEDERAL BANK',@Address = 'BAGALKOTE, BAGALKOTE, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002386',@BankName = 'FEDERAL BANK',@Address = 'AYODHYA, AYODHYA, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002387',@BankName = 'FEDERAL BANK',@Address = 'VALSAD, VALSAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002390',@BankName = 'FEDERAL BANK',@Address = 'CHENNAI, CHENNAI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002391',@BankName = 'FEDERAL BANK',@Address = 'SATHANGADU, SATHANGADU, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0002392',@BankName = 'FEDERAL BANK',@Address = 'TENKASI, TENKASI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'FDRL0PAUCB1',@BankName = 'FEDERAL BANK',@Address = 'KOTTAYAM, KOTTAYAM, KERALA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0004778',@BankName = 'HDFC BANK',@Address = 'GUDIVADA, KRISHNA, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0004932',@BankName = 'HDFC BANK',@Address = 'THIRUVANANTHAPURAM, THIRUVANANTHAPURAM, KERALA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005033',@BankName = 'HDFC BANK',@Address = 'HYDERABAD, RANGAREDDY, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005054',@BankName = 'HDFC BANK',@Address = 'ONGOLE, PRAKASAM, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005130',@BankName = 'HDFC BANK',@Address = 'DASUA, HOSHIARPUR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005131',@BankName = 'HDFC BANK',@Address = 'GUDHA GORJI, JHUNJHUNUN, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005270',@BankName = 'HDFC BANK',@Address = 'SHAH BERI, GAUTAM BUDH NAGAR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005274',@BankName = 'HDFC BANK',@Address = 'BANSDIH, BALLIA, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005283',@BankName = 'HDFC BANK',@Address = 'BASTI, BASTI, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005359',@BankName = 'HDFC BANK',@Address = 'CHUMUKEDIMA, DIMAPUR, NAGALAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005406',@BankName = 'HDFC BANK',@Address = 'RAJAPUR, RATNAGIRI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005434',@BankName = 'HDFC BANK',@Address = 'RATNAGIRI, RATNAGIRI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005442',@BankName = 'HDFC BANK',@Address = 'CHAKDAHA, NADIA, WEST BENGAL, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005443',@BankName = 'HDFC BANK',@Address = 'HYDERABAD, MEDCHAL MALKAJGIRI, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005463',@BankName = 'HDFC BANK',@Address = 'WALAJAPET, VELLORE, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005476',@BankName = 'HDFC BANK',@Address = 'NELLORE, NELLORE, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005479',@BankName = 'HDFC BANK',@Address = 'VIZIANAGARAM, VIZIANAGARAM, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005486',@BankName = 'HDFC BANK',@Address = 'HYDERABAD, HYDERABAD, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005534',@BankName = 'HDFC BANK',@Address = 'VINJAMUR, NELLORE, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005540',@BankName = 'HDFC BANK',@Address = 'TEKKALI, SRIKAKULAM, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005543',@BankName = 'HDFC BANK',@Address = 'JAWAHARNAGAR, MEDCHAL MALKAJGIRI, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005555',@BankName = 'HDFC BANK',@Address = 'CHENNAI, CHENNAI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005562',@BankName = 'HDFC BANK',@Address = 'RENAPUR, LATUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005564',@BankName = 'HDFC BANK',@Address = 'JAMKHED, AHMADNAGAR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005580',@BankName = 'HDFC BANK',@Address = 'LAKHANDUR, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005583',@BankName = 'HDFC BANK',@Address = 'HARGAON, SITAPUR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005603',@BankName = 'HDFC BANK',@Address = 'DELHI, SHAHDARA, DELHI, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005688',@BankName = 'HDFC BANK',@Address = 'KURE BHAR, SULTANPUR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005708',@BankName = 'HDFC BANK',@Address = 'SARHALI KALAN, AMRITSAR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005709',@BankName = 'HDFC BANK',@Address = 'LUDHIANA, LUDHIANA, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005716',@BankName = 'HDFC BANK',@Address = 'MUKTSAR, MUKTSAR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005717',@BankName = 'HDFC BANK',@Address = 'JAIPUR, JAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005725',@BankName = 'HDFC BANK',@Address = 'SALHAWAS, JHAJJAR, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005728',@BankName = 'HDFC BANK',@Address = 'BATALA, GURDASPUR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005729',@BankName = 'HDFC BANK',@Address = 'KADIPUR, SULTANPUR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005737',@BankName = 'HDFC BANK',@Address = 'TITTAKUDI, CUDDALORE, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005739',@BankName = 'HDFC BANK',@Address = 'PAUNI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005758',@BankName = 'HDFC BANK',@Address = 'SHOOLAGIRI, KRISHNAGIRI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005794',@BankName = 'HDFC BANK',@Address = 'GURGAON, GURGAON, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005870',@BankName = 'HDFC BANK',@Address = 'CAMPIER GANJ, GORAKHPUR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005897',@BankName = 'HDFC BANK',@Address = 'BALIAPUR, DHANBAD, JHARKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005900',@BankName = 'HDFC BANK',@Address = 'MANDI, MANDI, HIMACHAL PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005904',@BankName = 'HDFC BANK',@Address = 'KURNOOL, KURNOOL, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005924',@BankName = 'HDFC BANK',@Address = 'NARKHED, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005944',@BankName = 'HDFC BANK',@Address = 'MIRAJGAON, AHMADNAGAR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0005954',@BankName = 'HDFC BANK',@Address = 'BOMMAYAPALAYAM, CUDDALORE, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006002',@BankName = 'HDFC BANK',@Address = 'JAIPUR, JAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006025',@BankName = 'HDFC BANK',@Address = 'BANSWARA, BANSWARA, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006026',@BankName = 'HDFC BANK',@Address = 'BHIWADI, ALWAR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006065',@BankName = 'HDFC BANK',@Address = 'VADODARA, VADODARA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006075',@BankName = 'HDFC BANK',@Address = 'GANDERBAL, GANDERBAL, JAMMU AND KASHMIR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006085',@BankName = 'HDFC BANK',@Address = 'GOREGAON, GONDIYA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006094',@BankName = 'HDFC BANK',@Address = 'KHADAKWASALA, PUNE, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006095',@BankName = 'HDFC BANK',@Address = 'SINDKHED RAJA, BULDANA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006127',@BankName = 'HDFC BANK',@Address = 'NAGPUR, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006148',@BankName = 'HDFC BANK',@Address = 'MHASLA, MHASLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006174',@BankName = 'HDFC BANK',@Address = 'SANGRAMPUR, BULDANA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006230',@BankName = 'HDFC BANK',@Address = 'WADKHAL, RAIGARH, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006263',@BankName = 'HDFC BANK',@Address = 'PATHARDI, AHMADNAGAR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006273',@BankName = 'HDFC BANK',@Address = 'BARGARWA, RANCHI, JHARKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006327',@BankName = 'HDFC BANK',@Address = 'GONDIYA, GONDIYA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006334',@BankName = 'HDFC BANK',@Address = 'HYDERABAD, HYDERABAD, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006358',@BankName = 'HDFC BANK',@Address = 'MIHIJAM, JAMTARA, JHARKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006373',@BankName = 'HDFC BANK',@Address = 'NEVASA, AHMADNAGAR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006438',@BankName = 'HDFC BANK',@Address = 'SHIRUR, BID, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006440',@BankName = 'HDFC BANK',@Address = 'KANKE, RANCHI, JHARKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006511',@BankName = 'HDFC BANK',@Address = 'BHILWARA, BHILWARA, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006608',@BankName = 'HDFC BANK',@Address = 'JAIPUR, JAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006609',@BankName = 'HDFC BANK',@Address = 'JAIPUR, JAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006621',@BankName = 'HDFC BANK',@Address = 'JINTUR, PARBHANI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006633',@BankName = 'HDFC BANK',@Address = 'JAIPUR, JAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006656',@BankName = 'HDFC BANK',@Address = 'JAIPUR, JAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006706',@BankName = 'HDFC BANK',@Address = 'BASSI, CHITTAURGARH, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006729',@BankName = 'HDFC BANK',@Address = 'KALLUR, KALLUR, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006772',@BankName = 'HDFC BANK',@Address = 'LAKHANI, BHANDARA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006807',@BankName = 'HDFC BANK',@Address = 'KAPTANGANJ, KUSHI NAGAR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006913',@BankName = 'HDFC BANK',@Address = 'SHRINGARTALI, GUHAGAR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006934',@BankName = 'HDFC BANK',@Address = 'CHOTI SADRI, PRATAPGARH, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0006995',@BankName = 'HDFC BANK',@Address = 'MAHESWARAM, RANGAREDDY, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007005',@BankName = 'HDFC BANK',@Address = 'CHIPLUN, RATNAGIRI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007014',@BankName = 'HDFC BANK',@Address = 'MAVLI, UDAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007025',@BankName = 'HDFC BANK',@Address = 'FULAMBRI, PHULAMBRI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007036',@BankName = 'HDFC BANK',@Address = 'HYDERABAD, RANGAREDDY, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007255',@BankName = 'HDFC BANK',@Address = 'RURA, KANPUR DEHAT, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007302',@BankName = 'HDFC BANK',@Address = 'KANPUR, KANPUR CITY, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007350',@BankName = 'HDFC BANK',@Address = 'JOGA, MANSA, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007354',@BankName = 'HDFC BANK',@Address = 'LUCKNOW, LUCKNOW, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007377',@BankName = 'HDFC BANK',@Address = 'GOGUNDA, UDAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007401',@BankName = 'HDFC BANK',@Address = 'BAHADURGARH, JHAJJAR, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007462',@BankName = 'HDFC BANK',@Address = 'HISAR, HISAR, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007475',@BankName = 'HDFC BANK',@Address = 'JARWAL, BAHRAICH, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007495',@BankName = 'HDFC BANK',@Address = 'ASAN KALAN, PANIPAT, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007574',@BankName = 'HDFC BANK',@Address = 'GURGAON, GURGAON, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007692',@BankName = 'HDFC BANK',@Address = 'PIMPRI CHINCHWAD, PUNE, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007713',@BankName = 'HDFC BANK',@Address = 'ASPUR, DUNGARPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007720',@BankName = 'HDFC BANK',@Address = 'JALANDHAR, JALANDHAR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007734',@BankName = 'HDFC BANK',@Address = 'CHITTAURGARH, CHITTAURGARH, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007741',@BankName = 'HDFC BANK',@Address = 'HOSHIARPUR, HOSHIARPUR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007784',@BankName = 'HDFC BANK',@Address = 'ABOHAR, FEROZPUR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007785',@BankName = 'HDFC BANK',@Address = 'JAUNPUR, JAUNPUR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007824',@BankName = 'HDFC BANK',@Address = 'KANCHIPURAM, KANCHEEPURAM, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007836',@BankName = 'HDFC BANK',@Address = 'HYDERABAD, RANGAREDDY, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007845',@BankName = 'HDFC BANK',@Address = 'PUNE, PUNE, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007929',@BankName = 'HDFC BANK',@Address = 'PUNE, PUNE, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007970',@BankName = 'HDFC BANK',@Address = 'GUNTUR, GUNTUR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0007991',@BankName = 'HDFC BANK',@Address = 'PUNE, PUNE, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008016',@BankName = 'HDFC BANK',@Address = 'TIRUCHANUR, CHITTOOR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008027',@BankName = 'HDFC BANK',@Address = 'KARLAPALEM, GUNTUR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008029',@BankName = 'HDFC BANK',@Address = 'NELLORE, NELLORE, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008040',@BankName = 'HDFC BANK',@Address = 'BHAINCHUA, KHORDHA, ODISHA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008072',@BankName = 'HDFC BANK',@Address = 'DEVRUKH, RATNAGIRI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008226',@BankName = 'HDFC BANK',@Address = 'GODHANI, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008262',@BankName = 'HDFC BANK',@Address = 'BHATNI BAZAR, DEORIA, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008305',@BankName = 'HDFC BANK',@Address = 'DHARUHERA, REWARI, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008318',@BankName = 'HDFC BANK',@Address = 'SAFEDABAD, BARA BANKI, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008321',@BankName = 'HDFC BANK',@Address = 'DARIYABAD, BARA BANKI, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008322',@BankName = 'HDFC BANK',@Address = 'RALEGAON, YAVATMAL, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008412',@BankName = 'HDFC BANK',@Address = 'ANANTAPUR, ANANTAPUR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008420',@BankName = 'HDFC BANK',@Address = 'HYDERABAD, RANGAREDDY, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008424',@BankName = 'HDFC BANK',@Address = 'SADASIVPET, SANGAREDDY, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008485',@BankName = 'HDFC BANK',@Address = 'DEHRADUN, DEHRA DUN, UTTARAKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008569',@BankName = 'HDFC BANK',@Address = 'S A S NAGAR, AJIT SINGH NAGAR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008642',@BankName = 'HDFC BANK',@Address = 'ARKI, SOLAN, HIMACHAL PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008644',@BankName = 'HDFC BANK',@Address = 'NARNAUL, MAHENDRAGARH, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008662',@BankName = 'HDFC BANK',@Address = 'PALWAL, FARIDABAD, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008670',@BankName = 'HDFC BANK',@Address = 'BUNDI, BUNDI, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008681',@BankName = 'HDFC BANK',@Address = 'NANGAON, PUNE, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008696',@BankName = 'HDFC BANK',@Address = 'PATODA, BID, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008705',@BankName = 'HDFC BANK',@Address = 'NAGPUR, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008778',@BankName = 'HDFC BANK',@Address = 'CHAKUR, LATUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008779',@BankName = 'HDFC BANK',@Address = 'VENGURLA, SINDHUDURG, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'HDFC0008911',@BankName = 'HDFC BANK',@Address = 'NAGAUR, NAGAUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IBKL0002177',@BankName = 'IDBI BANK',@Address = 'POROMPAT, IMPHAL EAST, MANIPUR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IBKL0002178',@BankName = 'IDBI BANK',@Address = 'KOZHIKODE, KOZHIKODE, KERALA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IBKL0002181',@BankName = 'IDBI BANK',@Address = 'ARWAL, ARWAL, BIHAR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IBKL0009013',@BankName = 'IDBI BANK',@Address = 'UDAIPUR, UDAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004501',@BankName = 'ICICI BANK LTD',@Address = 'CHENNAI, CHENNAI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004520',@BankName = 'ICICI BANK LTD',@Address = 'RANI, PALI, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004536',@BankName = 'ICICI BANK LTD',@Address = 'UDHAMPUR, UDHAMPUR, JAMMU AND KASHMIR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004539',@BankName = 'ICICI BANK LTD',@Address = 'ALIGARH, ALIGARH, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004541',@BankName = 'ICICI BANK LTD',@Address = 'OLPAD, SURAT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004564',@BankName = 'ICICI BANK LTD',@Address = 'SULLURPET, NELLORE, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004565',@BankName = 'ICICI BANK LTD',@Address = 'CHITTOOR, CHITTOOR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004585',@BankName = 'ICICI BANK LTD',@Address = 'KOPPAM, PALAKKAD, KERALA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004598',@BankName = 'ICICI BANK LTD',@Address = 'KANPUR, KANPUR CITY, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004601',@BankName = 'ICICI BANK LTD',@Address = 'BULANDSHAHR, BULANDSHAHR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004602',@BankName = 'ICICI BANK LTD',@Address = 'ALIGARH, ALIGARH, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004639',@BankName = 'ICICI BANK LTD',@Address = 'TUTICORIN, TOOTHUKUDI, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004641',@BankName = 'ICICI BANK LTD',@Address = 'NAXALBARI, DARJILING, WEST BENGAL, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'ICIC0004683',@BankName = 'ICICI BANK LTD',@Address = 'AMBASSA, DHALAI, TRIPURA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0020217',@BankName = 'IDFC FIRST BANK LTD',@Address = 'DELHI, SOUTH-EAST DELHI, DELHI, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0020256',@BankName = 'IDFC FIRST BANK LTD',@Address = 'DELHI, NORTH DELHI, DELHI, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0020257',@BankName = 'IDFC FIRST BANK LTD',@Address = 'DELHI, CENTRAL DELHI, DELHI, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0021234',@BankName = 'IDFC FIRST BANK LTD',@Address = 'DEHRADUN, DEHRADUN, UTTARAKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0021791',@BankName = 'IDFC FIRST BANK LTD',@Address = 'HARIDWAR, HARDWAR, UTTARAKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0040192',@BankName = 'IDFC FIRST BANK LTD',@Address = 'MUMBAI, MUMBAI, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0040445',@BankName = 'IDFC FIRST BANK LTD',@Address = 'MORBI, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0042145',@BankName = 'IDFC FIRST BANK LTD',@Address = 'UJJAIN, UJJAIN, MADHYA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0042186',@BankName = 'IDFC FIRST BANK LTD',@Address = 'AJMER, AJMER, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0042504',@BankName = 'IDFC FIRST BANK LTD',@Address = 'NAGPUR, NAGPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0043491',@BankName = 'IDFC FIRST BANK LTD',@Address = 'AURANGABAD, AURANGABAD, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0043505',@BankName = 'IDFC FIRST BANK LTD',@Address = 'GANDHIDHAM, KACHCHH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0080217',@BankName = 'IDFC FIRST BANK LTD',@Address = 'HYDERABAD, RANGA REDDY, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0081176',@BankName = 'IDFC FIRST BANK LTD',@Address = 'BANGALORE, BENGALURU URBAN, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDFB0081773',@BankName = 'IDFC FIRST BANK LTD',@Address = 'BANGALORE, BENGALURU URBAN, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDIB000A222',@BankName = 'INDIAN BANK',@Address = 'NOIDA, GAUTAM BUDH NAGAR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'IDIB000M384',@BankName = 'INDIAN BANK',@Address = 'ERNAKULAM, ERNAKULAM, KERALA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'INDB0002106',@BankName = 'INDUSIND BANK',@Address = 'KOLHAPUR, KOLHAPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'KJSB0000219',@BankName = 'THE KALYAN JANATA SAHAKARI BANK LTD',@Address = 'SURAT, SURAT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'KKBK0002089',@BankName = 'KOTAK MAHINDRA BANK LTD',@Address = 'VASLAI, PALGHAR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'KKBK0002092',@BankName = 'KOTAK MAHINDRA BANK LTD',@Address = 'SANGRAMNAGAR, SOLAPUR, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'KKBK0003057',@BankName = 'KOTAK MAHINDRA BANK LTD',@Address = 'SANJALI, BHARUCH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'KKBK0003739',@BankName = 'KOTAK MAHINDRA BANK LTD',@Address = 'BEEKASAR, BIKANER, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'KKBK0004378',@BankName = 'KOTAK MAHINDRA BANK LTD',@Address = 'GURGAON, GURGAON, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'KKBK0005345',@BankName = 'KOTAK MAHINDRA BANK LTD',@Address = 'GHAZIABAD, GHAZIABAD, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'KKBK0008804',@BankName = 'KOTAK MAHINDRA BANK LTD',@Address = 'SRIPERUMBUDUR, KANCHEEPURAM, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'KSBK0001058',@BankName = 'The Kerala State Co Operative Bank Ltd',@Address = 'THIRUVANANTHAPURAM, THIRUVANANTHAPURAM, KERALA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'MAHB0002235',@BankName = 'BANK OF MAHARASHTRA',@Address = 'BARWANI, BARWANI, MADHYA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'MAHB0002236',@BankName = 'BANK OF MAHARASHTRA',@Address = 'UNJHA, MEHSANA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'MAHB0002242',@BankName = 'BANK OF MAHARASHTRA',@Address = 'THIRUVALLUR, THIRUVALLUR, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'NESF0000229',@BankName = 'NORTH EAST SMALL FINANCE BANK LTD',@Address = 'BISHNUPUR, BISHNUPUR, MANIPUR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'NESF0000230',@BankName = 'NORTH EAST SMALL FINANCE BANK LTD',@Address = 'SENAPATI, SENAPATI, MANIPUR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'NESF0000231',@BankName = 'NORTH EAST SMALL FINANCE BANK LTD',@Address = 'THOUBAL, THOUBAL, MANIPUR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'PMEC0104343',@BankName = 'PRIME COOP BANK LTD',@Address = 'SURAT, SURAT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'PUNB0935000',@BankName = 'PUNJAB NATIONAL BANK',@Address = 'ALLUR, ALLUR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'PUNB0944900',@BankName = 'PUNJAB NATIONAL BANK',@Address = 'MUZAFFARPUR, MUZAFFARPUR, BIHAR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'PUNB0945300',@BankName = 'PUNJAB NATIONAL BANK',@Address = 'WARASEONI, WARASEONI, MADHYA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'RATN0000527',@BankName = 'RBL BANK LTD',@Address = 'CHANDIGARH, CHANDIGARH, CHANDIGARH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0063964',@BankName = 'STATE BANK OF INDIA',@Address = 'VADODARA, VADODARA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064028',@BankName = 'STATE BANK OF INDIA',@Address = 'HARIDWAR, HARIDWAR, UTTARAKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064040',@BankName = 'STATE BANK OF INDIA',@Address = 'CHIRANG, CHIRANG, ASSAM, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064041',@BankName = 'STATE BANK OF INDIA',@Address = 'MANIKPUR, MANIKPUR, ASSAM, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064081',@BankName = 'STATE BANK OF INDIA',@Address = 'AGARTALA NORTH, AGARTALA NORTH, TRIPURA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064093',@BankName = 'STATE BANK OF INDIA',@Address = 'BHOJPUR, BHOJPUR, BIHAR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064105',@BankName = 'STATE BANK OF INDIA',@Address = 'TIRUNELVELI, TIRUNELVELI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064115',@BankName = 'STATE BANK OF INDIA',@Address = 'NALGONDA, NALGONDA, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064143',@BankName = 'STATE BANK OF INDIA',@Address = 'CHNGALPATTU, CHNGALPATTU, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064149',@BankName = 'STATE BANK OF INDIA',@Address = 'NADIAD, NADIAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064172',@BankName = 'STATE BANK OF INDIA',@Address = 'AKOLA, AKOLA, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064173',@BankName = 'STATE BANK OF INDIA',@Address = 'SURYAPET, SURYAPET, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064177',@BankName = 'STATE BANK OF INDIA',@Address = 'SILIGURI, SILIGURI, WEST BENGAL, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SBIN0064178',@BankName = 'STATE BANK OF INDIA',@Address = 'KOTHAPETA, KOTHAPETA, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA00000SC',@BankName = 'Saurashtra Gramin Bank',@Address = 'AMRA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000100',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJKOT, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000101',@BankName = 'Saurashtra Gramin Bank',@Address = 'JAMNAGAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000102',@BankName = 'Saurashtra Gramin Bank',@Address = 'AMRA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000103',@BankName = 'Saurashtra Gramin Bank',@Address = 'JAMNAGAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000104',@BankName = 'Saurashtra Gramin Bank',@Address = 'MOTI BANUGAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000105',@BankName = 'Saurashtra Gramin Bank',@Address = 'MATWA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000106',@BankName = 'Saurashtra Gramin Bank',@Address = 'FALLA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000107',@BankName = 'Saurashtra Gramin Bank',@Address = 'CHELA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000108',@BankName = 'Saurashtra Gramin Bank',@Address = 'DHUNVAV, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000109',@BankName = 'Saurashtra Gramin Bank',@Address = 'DHUTARPAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000111',@BankName = 'Saurashtra Gramin Bank',@Address = 'DHROL, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000112',@BankName = 'Saurashtra Gramin Bank',@Address = 'MOTA ITALA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000113',@BankName = 'Saurashtra Gramin Bank',@Address = 'JAIVA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000114',@BankName = 'Saurashtra Gramin Bank',@Address = 'MEGHPAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000115',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHADRA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000116',@BankName = 'Saurashtra Gramin Bank',@Address = 'JAM DUDHAI, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000117',@BankName = 'Saurashtra Gramin Bank',@Address = 'PITHAD, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000118',@BankName = 'Saurashtra Gramin Bank',@Address = 'AMRAN, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000119',@BankName = 'Saurashtra Gramin Bank',@Address = 'GADHAKA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000120',@BankName = 'Saurashtra Gramin Bank',@Address = 'DEVALIA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000121',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAN, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000122',@BankName = 'Saurashtra Gramin Bank',@Address = 'KHIRASARA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000123',@BankName = 'Saurashtra Gramin Bank',@Address = 'BANKODI, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000124',@BankName = 'Saurashtra Gramin Bank',@Address = 'MOTA PANCHDEVDA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000125',@BankName = 'Saurashtra Gramin Bank',@Address = 'MOTA VADALA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000126',@BankName = 'Saurashtra Gramin Bank',@Address = 'NAVAGAM KALAVAD, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000127',@BankName = 'Saurashtra Gramin Bank',@Address = 'MAKRANI SANOSRA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000128',@BankName = 'Saurashtra Gramin Bank',@Address = 'BERAJA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000129',@BankName = 'Saurashtra Gramin Bank',@Address = 'PADANA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000130',@BankName = 'Saurashtra Gramin Bank',@Address = 'PIPERTODA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000131',@BankName = 'Saurashtra Gramin Bank',@Address = 'HARIPAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000132',@BankName = 'Saurashtra Gramin Bank',@Address = 'LALPUR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000133',@BankName = 'Saurashtra Gramin Bank',@Address = 'KHAD KHAMBHALIA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000134',@BankName = 'Saurashtra Gramin Bank',@Address = 'VIRAMDAD, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000135',@BankName = 'Saurashtra Gramin Bank',@Address = 'VADATARA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000136',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHAN KHOKHARI, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000137',@BankName = 'Saurashtra Gramin Bank',@Address = 'JAMKHAMBHALIA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000138',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHANGOR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000139',@BankName = 'Saurashtra Gramin Bank',@Address = 'SHIVA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000140',@BankName = 'Saurashtra Gramin Bank',@Address = 'MOTA GUNDA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000141',@BankName = 'Saurashtra Gramin Bank',@Address = 'PACHHATAR, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000142',@BankName = 'Saurashtra Gramin Bank',@Address = 'MOTI GOP, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000143',@BankName = 'Saurashtra Gramin Bank',@Address = 'SHETH VADALA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000144',@BankName = 'Saurashtra Gramin Bank',@Address = 'GINGANI, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000145',@BankName = 'Saurashtra Gramin Bank',@Address = 'SADODAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000146',@BankName = 'Saurashtra Gramin Bank',@Address = 'SURAJ KARADI, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000147',@BankName = 'Saurashtra Gramin Bank',@Address = 'VARVALA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000148',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHANVAD, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000149',@BankName = 'Saurashtra Gramin Bank',@Address = 'KALAVAD, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000150',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHATIYA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000151',@BankName = 'Saurashtra Gramin Bank',@Address = 'JAM JODHPUR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000152',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHANVAD VERAD NAKA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000153',@BankName = 'Saurashtra Gramin Bank',@Address = 'DWARKA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000154',@BankName = 'Saurashtra Gramin Bank',@Address = 'JAMNAGAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000155',@BankName = 'Saurashtra Gramin Bank',@Address = 'JAMNAGAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000156',@BankName = 'Saurashtra Gramin Bank',@Address = 'SIKKA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000157',@BankName = 'Saurashtra Gramin Bank',@Address = 'BEDIBANDAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000158',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJPARA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000159',@BankName = 'Saurashtra Gramin Bank',@Address = 'LATIPAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000160',@BankName = 'Saurashtra Gramin Bank',@Address = 'SALAYA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000161',@BankName = 'Saurashtra Gramin Bank',@Address = 'ROJIVADA, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000162',@BankName = 'Saurashtra Gramin Bank',@Address = 'NANDURI, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000163',@BankName = 'Saurashtra Gramin Bank',@Address = 'JAMNAGAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000164',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHADTHAR, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000165',@BankName = 'Saurashtra Gramin Bank',@Address = 'BAJANA, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000166',@BankName = 'Saurashtra Gramin Bank',@Address = 'MORKANDA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000167',@BankName = 'Saurashtra Gramin Bank',@Address = 'DHUN DHORAJI, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000168',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAVAL, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000169',@BankName = 'Saurashtra Gramin Bank',@Address = 'MORZAR, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000170',@BankName = 'Saurashtra Gramin Bank',@Address = 'KHIMRANA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000171',@BankName = 'Saurashtra Gramin Bank',@Address = 'HARSHADPUR, DEVBHUMI DWARKA, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000176',@BankName = 'Saurashtra Gramin Bank',@Address = 'DODIYALA, JAMNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000177',@BankName = 'Saurashtra Gramin Bank',@Address = 'AMBARDI, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000178',@BankName = 'Saurashtra Gramin Bank',@Address = 'WANKANER, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000179',@BankName = 'Saurashtra Gramin Bank',@Address = 'KHAJURDA, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000180',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJKOT, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000181',@BankName = 'Saurashtra Gramin Bank',@Address = 'MALIYASAN, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000182',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJKOT, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000183',@BankName = 'Saurashtra Gramin Bank',@Address = 'GONDAL, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000184',@BankName = 'Saurashtra Gramin Bank',@Address = 'PADADHRI, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000185',@BankName = 'Saurashtra Gramin Bank',@Address = 'DHORAJI, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000186',@BankName = 'Saurashtra Gramin Bank',@Address = 'MORBI, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000187',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJKOT, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000188',@BankName = 'Saurashtra Gramin Bank',@Address = 'VIRPUR, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000189',@BankName = 'Saurashtra Gramin Bank',@Address = 'JETPUR, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000190',@BankName = 'Saurashtra Gramin Bank',@Address = 'TANKARA, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000191',@BankName = 'Saurashtra Gramin Bank',@Address = 'RANCHHODNAGAR, RANCHHODNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000192',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJKOT, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000193',@BankName = 'Saurashtra Gramin Bank',@Address = 'MADHAPAR, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000194',@BankName = 'Saurashtra Gramin Bank',@Address = 'SHAPAR VERAVAL, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000195',@BankName = 'Saurashtra Gramin Bank',@Address = 'UPLETA, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000197',@BankName = 'Saurashtra Gramin Bank',@Address = 'JASDAN, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000198',@BankName = 'Saurashtra Gramin Bank',@Address = 'AATKOT, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000199',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJKOT, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000201',@BankName = 'Saurashtra Gramin Bank',@Address = 'SURENDRANAGAR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000202',@BankName = 'Saurashtra Gramin Bank',@Address = 'ADARIYANA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000203',@BankName = 'Saurashtra Gramin Bank',@Address = 'ANANDPUR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000204',@BankName = 'Saurashtra Gramin Bank',@Address = 'CHOTILA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000205',@BankName = 'Saurashtra Gramin Bank',@Address = 'DEDADARA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000206',@BankName = 'Saurashtra Gramin Bank',@Address = 'DHRANGDHRA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000207',@BankName = 'Saurashtra Gramin Bank',@Address = 'HALVAD, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000209',@BankName = 'Saurashtra Gramin Bank',@Address = 'JASAPAR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000210',@BankName = 'Saurashtra Gramin Bank',@Address = 'KUNTALPUR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000211',@BankName = 'Saurashtra Gramin Bank',@Address = 'LILAPUR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000212',@BankName = 'Saurashtra Gramin Bank',@Address = 'LIMBDI, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000214',@BankName = 'Saurashtra Gramin Bank',@Address = 'METHAN, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000215',@BankName = 'Saurashtra Gramin Bank',@Address = 'MORTHARA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000216',@BankName = 'Saurashtra Gramin Bank',@Address = 'MOTA ANKEVALIA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000217',@BankName = 'Saurashtra Gramin Bank',@Address = 'MOTI MOLDI, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000218',@BankName = 'Saurashtra Gramin Bank',@Address = 'NAGNESH, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000219',@BankName = 'Saurashtra Gramin Bank',@Address = 'NANA ANKEVALIYA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000220',@BankName = 'Saurashtra Gramin Bank',@Address = 'PATDI, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000221',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJPARA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000222',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAMPARA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000223',@BankName = 'Saurashtra Gramin Bank',@Address = 'SANOSARA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000224',@BankName = 'Saurashtra Gramin Bank',@Address = 'SHEKHPAR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000225',@BankName = 'Saurashtra Gramin Bank',@Address = 'SURENDRANAGAR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000226',@BankName = 'Saurashtra Gramin Bank',@Address = 'UMARDA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000227',@BankName = 'Saurashtra Gramin Bank',@Address = 'WADHWAN, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000228',@BankName = 'Saurashtra Gramin Bank',@Address = 'SAYLA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000229',@BankName = 'Saurashtra Gramin Bank',@Address = 'SURENDRANAGAR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000230',@BankName = 'Saurashtra Gramin Bank',@Address = 'CHUDA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000231',@BankName = 'Saurashtra Gramin Bank',@Address = 'KOTHARIA BALA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000232',@BankName = 'Saurashtra Gramin Bank',@Address = 'GHANSHYAMPUR, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000233',@BankName = 'Saurashtra Gramin Bank',@Address = 'JORAVARNAGAR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000234',@BankName = 'Saurashtra Gramin Bank',@Address = 'NANI KATHECHI, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000235',@BankName = 'Saurashtra Gramin Bank',@Address = 'LAKHTAR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000236',@BankName = 'Saurashtra Gramin Bank',@Address = 'ALKA CHOWK, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000237',@BankName = 'Saurashtra Gramin Bank',@Address = 'SURENDRANAGAR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000238',@BankName = 'Saurashtra Gramin Bank',@Address = 'THANGADH THAN, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000240',@BankName = 'Saurashtra Gramin Bank',@Address = 'KHARVA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000241',@BankName = 'Saurashtra Gramin Bank',@Address = 'BALOL, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000242',@BankName = 'Saurashtra Gramin Bank',@Address = 'SARA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000243',@BankName = 'Saurashtra Gramin Bank',@Address = 'KAMALPUR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000244',@BankName = 'Saurashtra Gramin Bank',@Address = 'LATUDA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000245',@BankName = 'Saurashtra Gramin Bank',@Address = 'GAVANA, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000246',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHRAGUPUR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000247',@BankName = 'Saurashtra Gramin Bank',@Address = 'VELAVADAR, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000248',@BankName = 'Saurashtra Gramin Bank',@Address = 'KANKAVATI, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000251',@BankName = 'Saurashtra Gramin Bank',@Address = 'BAJUD, SURENDRANAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000252',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHAVNAGAR, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000254',@BankName = 'Saurashtra Gramin Bank',@Address = 'DEVLI, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000255',@BankName = 'Saurashtra Gramin Bank',@Address = 'DUDHALA, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000256',@BankName = 'Saurashtra Gramin Bank',@Address = 'MAHUVA, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000257',@BankName = 'Saurashtra Gramin Bank',@Address = 'MANGADH, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000258',@BankName = 'Saurashtra Gramin Bank',@Address = 'NANA ASHARANA, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000259',@BankName = 'Saurashtra Gramin Bank',@Address = 'PADVA, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000260',@BankName = 'Saurashtra Gramin Bank',@Address = 'ROHISHALA, BOTAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000261',@BankName = 'Saurashtra Gramin Bank',@Address = 'SARVA, BOTAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000262',@BankName = 'Saurashtra Gramin Bank',@Address = 'TAJPAR, BOTAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000263',@BankName = 'Saurashtra Gramin Bank',@Address = 'TALAJA, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000264',@BankName = 'Saurashtra Gramin Bank',@Address = 'TARSAMIYA, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000265',@BankName = 'Saurashtra Gramin Bank',@Address = 'TATAM, BOTAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000266',@BankName = 'Saurashtra Gramin Bank',@Address = 'VALUKAD, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000267',@BankName = 'Saurashtra Gramin Bank',@Address = 'PALITANA, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000268',@BankName = 'Saurashtra Gramin Bank',@Address = 'BOTAD, BOTAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000269',@BankName = 'Saurashtra Gramin Bank',@Address = 'GADHADA SWAMINA, BOTAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000270',@BankName = 'Saurashtra Gramin Bank',@Address = 'SIDSAR, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000272',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHAVNAGAR, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000273',@BankName = 'Saurashtra Gramin Bank',@Address = 'SIHOR, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000274',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHAVNAGAR, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000275',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHARATNAGAR, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000276',@BankName = 'Saurashtra Gramin Bank',@Address = 'TANA, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000277',@BankName = 'Saurashtra Gramin Bank',@Address = 'TALGAJARDA, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000278',@BankName = 'Saurashtra Gramin Bank',@Address = 'CHOGATH, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000279',@BankName = 'Saurashtra Gramin Bank',@Address = 'HATHAB, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000280',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHAVNAGAR, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000281',@BankName = 'Saurashtra Gramin Bank',@Address = 'AKWADA, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000282',@BankName = 'Saurashtra Gramin Bank',@Address = 'FARIYADKA, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000283',@BankName = 'Saurashtra Gramin Bank',@Address = 'PADIYAD, BOTAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000284',@BankName = 'Saurashtra Gramin Bank',@Address = 'JESAR BODANANESH, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000301',@BankName = 'Saurashtra Gramin Bank',@Address = 'JUNAGADH, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000302',@BankName = 'Saurashtra Gramin Bank',@Address = 'AJOTHA, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000303',@BankName = 'Saurashtra Gramin Bank',@Address = 'AMODRA, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000304',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHANDURI, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000305',@BankName = 'Saurashtra Gramin Bank',@Address = 'CHANDWANA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000306',@BankName = 'Saurashtra Gramin Bank',@Address = 'DHAVA, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000307',@BankName = 'Saurashtra Gramin Bank',@Address = 'JUNAGADH, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000308',@BankName = 'Saurashtra Gramin Bank',@Address = 'KEVADRA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000309',@BankName = 'Saurashtra Gramin Bank',@Address = 'MEKHDI, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000310',@BankName = 'Saurashtra Gramin Bank',@Address = 'MENDPARA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000311',@BankName = 'Saurashtra Gramin Bank',@Address = 'MENDARDA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000312',@BankName = 'Saurashtra Gramin Bank',@Address = 'MOTA SAMADHIALA, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000313',@BankName = 'Saurashtra Gramin Bank',@Address = 'NANADIA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000314',@BankName = 'Saurashtra Gramin Bank',@Address = 'NAREDI, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000315',@BankName = 'Saurashtra Gramin Bank',@Address = 'SAVANI, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000316',@BankName = 'Saurashtra Gramin Bank',@Address = 'KESARIYA, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000317',@BankName = 'Saurashtra Gramin Bank',@Address = 'TALALA GIR, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000318',@BankName = 'Saurashtra Gramin Bank',@Address = 'TIKAR, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000319',@BankName = 'Saurashtra Gramin Bank',@Address = 'VADHAVI, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000320',@BankName = 'Saurashtra Gramin Bank',@Address = 'VIRDI, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000321',@BankName = 'Saurashtra Gramin Bank',@Address = 'VERAVAL, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000322',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAVANI, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000323',@BankName = 'Saurashtra Gramin Bank',@Address = 'KODINAR, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000324',@BankName = 'Saurashtra Gramin Bank',@Address = 'VISAVADAR, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000325',@BankName = 'Saurashtra Gramin Bank',@Address = 'NAKARA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000326',@BankName = 'Saurashtra Gramin Bank',@Address = 'IVNAGAR, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000327',@BankName = 'Saurashtra Gramin Bank',@Address = 'KESHOD, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000328',@BankName = 'Saurashtra Gramin Bank',@Address = 'MALIYA HATINA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000329',@BankName = 'Saurashtra Gramin Bank',@Address = 'UNA, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000330',@BankName = 'Saurashtra Gramin Bank',@Address = 'MANGROL, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000331',@BankName = 'Saurashtra Gramin Bank',@Address = 'JUNAGADH, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000332',@BankName = 'Saurashtra Gramin Bank',@Address = 'BORVAV, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000333',@BankName = 'Saurashtra Gramin Bank',@Address = 'VANTHALI, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000334',@BankName = 'Saurashtra Gramin Bank',@Address = 'KANJHA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000335',@BankName = 'Saurashtra Gramin Bank',@Address = 'KANKARA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000336',@BankName = 'Saurashtra Gramin Bank',@Address = 'JUNAGADH, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000337',@BankName = 'Saurashtra Gramin Bank',@Address = 'JUNAGADH, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000338',@BankName = 'Saurashtra Gramin Bank',@Address = 'CHIRODA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000339',@BankName = 'Saurashtra Gramin Bank',@Address = 'SHIL, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000340',@BankName = 'Saurashtra Gramin Bank',@Address = 'VADVIYALA, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000341',@BankName = 'Saurashtra Gramin Bank',@Address = 'SAMADHIALA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000342',@BankName = 'Saurashtra Gramin Bank',@Address = 'JAMKA, JUNAGADH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000343',@BankName = 'Saurashtra Gramin Bank',@Address = 'DHOKADVA, GIR SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000351',@BankName = 'Saurashtra Gramin Bank',@Address = 'AMBA, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000352',@BankName = 'Saurashtra Gramin Bank',@Address = 'AMRELI, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000353',@BankName = 'Saurashtra Gramin Bank',@Address = 'DATARDI, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000354',@BankName = 'Saurashtra Gramin Bank',@Address = 'DHARAGNI, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000355',@BankName = 'Saurashtra Gramin Bank',@Address = 'HEMAL, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000356',@BankName = 'Saurashtra Gramin Bank',@Address = 'KERIACHAD, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000357',@BankName = 'Saurashtra Gramin Bank',@Address = 'KHAMBHALA, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000358',@BankName = 'Saurashtra Gramin Bank',@Address = 'MOTA BARMAN, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000359',@BankName = 'Saurashtra Gramin Bank',@Address = 'PIPALVA, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000360',@BankName = 'Saurashtra Gramin Bank',@Address = 'SALADI, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000361',@BankName = 'Saurashtra Gramin Bank',@Address = 'SANALI, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000362',@BankName = 'Saurashtra Gramin Bank',@Address = 'DHARI, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000363',@BankName = 'Saurashtra Gramin Bank',@Address = 'AMRAPARA, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000364',@BankName = 'Saurashtra Gramin Bank',@Address = 'SAVARKUNDLA, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000365',@BankName = 'Saurashtra Gramin Bank',@Address = 'MANDAL, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000366',@BankName = 'Saurashtra Gramin Bank',@Address = 'INGORALA, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000367',@BankName = 'Saurashtra Gramin Bank',@Address = 'CHAKKARGADH ROAD, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000368',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJULA, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000369',@BankName = 'Saurashtra Gramin Bank',@Address = 'VAGHANIYA JUNA, AMRELI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000376',@BankName = 'Saurashtra Gramin Bank',@Address = 'BALEJ, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000377',@BankName = 'Saurashtra Gramin Bank',@Address = 'GAREJ, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000378',@BankName = 'Saurashtra Gramin Bank',@Address = 'KHAMBHODAR, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000379',@BankName = 'Saurashtra Gramin Bank',@Address = 'SISALI, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000380',@BankName = 'Saurashtra Gramin Bank',@Address = 'PORBANDAR, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000381',@BankName = 'Saurashtra Gramin Bank',@Address = 'PARWADA, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000382',@BankName = 'Saurashtra Gramin Bank',@Address = 'VADALA, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000383',@BankName = 'Saurashtra Gramin Bank',@Address = 'KUTIYANA, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000384',@BankName = 'Saurashtra Gramin Bank',@Address = 'KHAPAT, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000385',@BankName = 'Saurashtra Gramin Bank',@Address = 'CHHAYA, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000386',@BankName = 'Saurashtra Gramin Bank',@Address = 'RANAVAV, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000387',@BankName = 'Saurashtra Gramin Bank',@Address = 'RANAKANDORANA, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000388',@BankName = 'Saurashtra Gramin Bank',@Address = 'KUCHHADI, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000389',@BankName = 'Saurashtra Gramin Bank',@Address = 'BOKHIRA, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000390',@BankName = 'Saurashtra Gramin Bank',@Address = 'CHAUTA, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000391',@BankName = 'Saurashtra Gramin Bank',@Address = 'NAGAKA, PORBANDAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000401',@BankName = 'Saurashtra Gramin Bank',@Address = 'BHAVNAGAR, BHAVNAGAR, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000402',@BankName = 'Saurashtra Gramin Bank',@Address = 'KUVADVA, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000403',@BankName = 'Saurashtra Gramin Bank',@Address = 'GUNDALA, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000404',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJPAR MORBI, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000405',@BankName = 'Saurashtra Gramin Bank',@Address = 'MORBI, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000406',@BankName = 'Saurashtra Gramin Bank',@Address = 'LODHIKA, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000407',@BankName = 'Saurashtra Gramin Bank',@Address = 'BILIYALA, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000408',@BankName = 'Saurashtra Gramin Bank',@Address = 'BEDI, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000409',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJKOT, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000410',@BankName = 'Saurashtra Gramin Bank',@Address = 'RANMALPUR, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000411',@BankName = 'Saurashtra Gramin Bank',@Address = 'SAPAKADA, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000501',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJKOT, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'SGBA0000900',@BankName = 'Saurashtra Gramin Bank',@Address = 'RAJKOT, RAJKOT, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UBIN0579301',@BankName = 'UNION BANK OF INDIA',@Address = 'DELHI, DELHI, DELHI, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UBIN0579319',@BankName = 'UNION BANK OF INDIA',@Address = 'VEMULA, KADAPA, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UCBA0003411',@BankName = 'UCO BANK',@Address = 'DADAHU, SIRMOUR, HIMACHAL PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UCBA0003431',@BankName = 'UCO BANK',@Address = 'DURGAPUR, PASCHIM BARDHAMAN, WEST BENGAL, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UCBA0003435',@BankName = 'UCO BANK',@Address = 'JAIPUR, JAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UCBA0003437',@BankName = 'UCO BANK',@Address = 'HISSAR, HISSAR, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UJVN0001708',@BankName = 'Ujjivan Small Finance Bank LTD',@Address = 'PATHANAMTHITTA, NMI, KERALA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UJVN0001709',@BankName = 'Ujjivan Small Finance Bank LTD',@Address = 'CHENNAI, CHENNAI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UJVN0003630',@BankName = 'Ujjivan Small Finance Bank LTD',@Address = 'CUTTACK, CUTTACK, ODISHA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UJVN0003631',@BankName = 'Ujjivan Small Finance Bank LTD',@Address = 'KOLKATA, KOLKATA, WEST BENGAL, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0004986',@BankName = 'AXIS BANK',@Address = 'CUTTACK, CUTTACK, ODISHA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0004993',@BankName = 'AXIS BANK',@Address = 'SATNA, SATNA, MADHYA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005002',@BankName = 'AXIS BANK',@Address = 'VISAKHAPATNAM, VISAKHAPATNAM, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005006',@BankName = 'AXIS BANK',@Address = 'BATALA, GURDASPUR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005008',@BankName = 'AXIS BANK',@Address = 'BANGALORE, BANGALORE, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005009',@BankName = 'AXIS BANK',@Address = 'AHMEDABAD, AHMEDABAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005010',@BankName = 'AXIS BANK',@Address = 'VERAVAL, GIR-SOMNATH, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005011',@BankName = 'AXIS BANK',@Address = 'BANGALORE, BANGALORE, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005012',@BankName = 'AXIS BANK',@Address = 'LAKSAR, HARIDWAR, UTTARAKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005013',@BankName = 'AXIS BANK',@Address = 'JORETHANG, SOUTH SIKKIM, SIKKIM, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005014',@BankName = 'AXIS BANK',@Address = 'JANJGIR CHAMPA, JANJGIR CHAMPA, CHHATTISGARH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005016',@BankName = 'AXIS BANK',@Address = 'RAIPUR, RAIPUR, CHHATTISGARH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005019',@BankName = 'AXIS BANK',@Address = 'BANGALORE, BANGALORE, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005020',@BankName = 'AXIS BANK',@Address = 'KOLKATA, NORTH 24 PARGANAS, WEST BENGAL, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005025',@BankName = 'AXIS BANK',@Address = 'VISAKHAPATNAM, VISAKHAPATNAM, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005026',@BankName = 'AXIS BANK',@Address = 'MAHENDRANAGAR, MORBI, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005027',@BankName = 'AXIS BANK',@Address = 'UDAIPUR, UDAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005028',@BankName = 'AXIS BANK',@Address = 'UDAIPUR, UDAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005030',@BankName = 'AXIS BANK',@Address = 'BHOPAL, BHOPAL, MADHYA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005031',@BankName = 'AXIS BANK',@Address = 'JAIPUR, JAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005032',@BankName = 'AXIS BANK',@Address = 'NOIDA, GAUTAM BUDH NAGAR, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005035',@BankName = 'AXIS BANK',@Address = 'SIVAGANGAI, SIVAGANGAI, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005036',@BankName = 'AXIS BANK',@Address = 'ERODE, ERODE, TAMIL NADU, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005037',@BankName = 'AXIS BANK',@Address = 'NASHIK, NASHIK, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005038',@BankName = 'AXIS BANK',@Address = 'NANPARA, BAHRAICH, UTTAR PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005039',@BankName = 'AXIS BANK',@Address = 'NEW DELHI, DELHI, DELHI, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005040',@BankName = 'AXIS BANK',@Address = 'HYDERABAD, HYDERABAD, DELHI, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005041',@BankName = 'AXIS BANK',@Address = 'HYDERABAD, MEDCHAL MALKAJGIRI, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005043',@BankName = 'AXIS BANK',@Address = 'HYDERABAD, MEDCHAL MALKAJGIRI, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005044',@BankName = 'AXIS BANK',@Address = 'BHUNA, FATEHABAD, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005045',@BankName = 'AXIS BANK',@Address = 'BIKANER, BIKANER, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005046',@BankName = 'AXIS BANK',@Address = 'ANUPGARH, SRIGANGANAGAR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005047',@BankName = 'AXIS BANK',@Address = 'BORANADA, BARMER, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005048',@BankName = 'AXIS BANK',@Address = 'BANBEERPUR, ALWAR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005049',@BankName = 'AXIS BANK',@Address = 'BAGRU, JAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005058',@BankName = 'AXIS BANK',@Address = 'KURUKSHETRA, KURUKSHETRA, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005060',@BankName = 'AXIS BANK',@Address = 'NAWANSHAHR, HOSHIARPUR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005063',@BankName = 'AXIS BANK',@Address = 'DHARAMKOT, MOGA, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005064',@BankName = 'AXIS BANK',@Address = 'MUKTSAR, MUKTSAR, PUNJAB, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0005068',@BankName = 'AXIS BANK',@Address = 'KULLAN, FATEHABAD, HARYANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTIB0S9AZAD',@BankName = 'AXIS BANK',@Address = 'HUBLI, DHARWAD, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTKS0001668',@BankName = 'UTKARSH SMALL FINANCE BANK',@Address = 'JAIPUR, JAIPUR, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTKS0001898',@BankName = 'UTKARSH SMALL FINANCE BANK',@Address = 'BOKARO, BOKARO, JHARKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTKS0001901',@BankName = 'UTKARSH SMALL FINANCE BANK',@Address = 'GUMLA, GUMLA, JHARKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTKS0001902',@BankName = 'UTKARSH SMALL FINANCE BANK',@Address = 'DUMKA, DUMKA, JHARKHAND, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTKS0001905',@BankName = 'UTKARSH SMALL FINANCE BANK',@Address = 'SARAN, SARAN, BIHAR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'UTKS0001909',@BankName = 'UTKARSH SMALL FINANCE BANK',@Address = 'CHAMPARAN, CHAMPARAN, BIHAR, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'WBSC000MOBI',@BankName = 'THE WEST BENGAL STATE COOP BANK',@Address = 'KOLKATA, KOLKATA, WEST BENGAL, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'YESB0001205',@BankName = 'YES BANK',@Address = 'AHMEDABAD, AHMEDABAD, GUJARAT, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'YESB0001272',@BankName = 'YES BANK',@Address = 'NAVI MUMBAI, THANE, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'YESB0001274',@BankName = 'YES BANK',@Address = 'HYDERABAD, RANGAREDDY, TELANGANA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'YESB0001276',@BankName = 'YES BANK',@Address = 'THANE, THANE, MAHARASHTRA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'YESB0001277',@BankName = 'YES BANK',@Address = 'BENGALURU, BANGALORE, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'YESB0001285',@BankName = 'YES BANK',@Address = 'HANUMANGARH, HANUMANGARH, RAJASTHAN, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'YESB0001287',@BankName = 'YES BANK',@Address = 'NEW DELHI, NEW DELHI, DELHI, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'YESB0001291',@BankName = 'YES BANK',@Address = 'BENGALURU, BANGALORE, KARNATAKA, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'YESB0CCTB01',@BankName = 'YES BANK',@Address = 'CHITTOOR, CHITTOOR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'YESB0CCTB02',@BankName = 'YES BANK',@Address = 'CHITTOOR, CHITTOOR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = NULL, @IfscCode = 'YESB0CCTB03',@BankName = 'YES BANK',@Address = 'CHITTOOR, CHITTOOR, ANDHRA PRADESH, INDIA, 999999'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '636532102' , @IfscCode = 'YESB0001223',@BankName = 'YES BANK LTD',@Address = 'GROUND FLOOR 2-939C, SALEM MAIN ROAD NELLAI NAGAR, DHARMAPURI, DHARMAPURI, TAMIL NADU, INDIA, 636701'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '000JIO000' , @IfscCode = 'JIOP0000001',@BankName = 'JIO PAYMENTS BANK',@Address = 'NAVI MUMBAI,MAHARASHTRA, NAVI MUMBAI,MAHARASHTRA, NAVI MUMBAI, MUMBAI, MAHARASHTRA, INDIA, 410206'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '142240010' , @IfscCode = 'HDFC0007279',@BankName = 'HDFC BANK LTD',@Address = 'Kishanpur Kalan, Kishanpur Kalan, 281305, Kishanpur, PUNJAB, INDIA, 281305'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '586240007' , @IfscCode = 'HDFC0005490',@BankName = 'HDFC BANK LTD',@Address = 'SURVEY NO PLOT NO 09, SURVEY NO PLOT NO 09, BIJAPUR,KARNATAKA, BIJAPUR, KARNATAKA, INDIA, 586101'
GO
EXEC dbo.AddRefBankMicr_InsertAndUpdate_Custom @MicrNo = '586240007' , @IfscCode = 'HDFC0005490',@BankName = 'HDFC BANK LTD',@Address = 'SURVEY NO PLOT NO 09, SURVEY NO PLOT NO 09, BIJAPUR,KARNATAKA, BIJAPUR, KARNATAKA, INDIA, 586101'
GO

EXEC dbo.Sys_DropIfExists 'AddRefBankMicr_InsertAndUpdate_Custom','P'
GO

--WEB-83715 RC END