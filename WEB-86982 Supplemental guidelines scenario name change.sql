--File:Tables:dbo:RefProcess:DML
--RC WEB-86982 START
GO
	-- S851
	UPDATE re
	SET re.[Name] = 'S851 Off Market transfer to unrelated accounts (TM13)'
	FROM dbo.RefAmlReport re
	WHERE re.[Name] = 'S851 Off Market transfer to unrelated accounts'

	UPDATE pre
	SET pre.[Name] = 'S851 Off Market transfer to unrelated accounts (TM13)',
	pre.DisplayName = 'S851 Off Market transfer to unrelated accounts (TM13)'
	FROM dbo.RefProcess pre
	WHERE pre.Code = 'S851'

	-- S852

	UPDATE re
	SET re.[Name] = 'S852 Suspicious off market credit and debit (TM 13A)'
	FROM dbo.RefAmlReport re
	WHERE re.[Name] = 'S852 Suspicious off market credit and debit'

	UPDATE pre
	SET pre.[Name] = 'S852 Suspicious off market credit and debit (TM 13A)',
	pre.DisplayName = 'S852 Suspicious off market credit and debit (TM 13A)'
	FROM dbo.RefProcess pre
	WHERE pre.Code = 'S852'

	-- S853

	UPDATE re
	SET re.[Name] = 'S853 Off Market delivery in unlisted scrip (TM 13B)'
	FROM dbo.RefAmlReport re
	WHERE re.[Name] = 'S853 Off Market delivery in unlisted scrip'

	UPDATE pre
	SET pre.[Name] = 'S853 Off Market delivery in unlisted scrip (TM 13B)',
	pre.DisplayName = 'S853 Off Market delivery in unlisted scrip (TM 13B)'
	FROM dbo.RefProcess pre
	WHERE pre.Code = 'S853'

	-- S854

	UPDATE re
	SET re.[Name] = 'S854 Gift Donation related off market transfer (TM 13C)'
	FROM dbo.RefAmlReport re
	WHERE re.[Name] = 'S854 Gift Donation related off market transfer'

	UPDATE pre
	SET pre.[Name] = 'S854 Gift Donation related off market transfer (TM 13C)',
	pre.DisplayName = 'S854 Gift Donation related off market transfer (TM 13C)'
	FROM dbo.RefProcess pre
	WHERE pre.Code = 'S854'

	-- S855

	UPDATE re
	SET re.[Name] = 'S855 Off Market transfer at variance with market value (TM 13D)'
	FROM dbo.RefAmlReport re
	WHERE re.[Name] = 'S855 Market transfer at variance with market value'

	UPDATE pre
	SET pre.[Name] = 'S855 Off Market transfer at variance with market value (TM 13D)',
	pre.DisplayName = 'S855 Off Market transfer at variance with market value (TM 13D)'
	FROM dbo.RefProcess pre
	WHERE pre.Code = 'S855'
	
	-- S856

	UPDATE re
	SET re.[Name] = 'S856 Off Market Transfer in suspicious Scrip (TM 13E)'
	FROM dbo.RefAmlReport re
	WHERE re.[Name] = 'S856 Off Market Transfer in suspicious Scrip'

	UPDATE pre
	SET pre.[Name] = 'S856 Off Market Transfer in suspicious Scrip (TM 13E)',
	pre.DisplayName = 'S856 Off Market Transfer in suspicious Scrip (TM 13E)'
	FROM dbo.RefProcess pre
	WHERE pre.Code = 'S856'

	-- S857

	UPDATE re
	SET re.[Name] = 'S857 Suspicious closure of account (EI 13)'
	FROM dbo.RefAmlReport re
	WHERE re.[Name] = 'S857 Suspicious closure of account'

	UPDATE pre
	SET pre.[Name] = 'S857 Suspicious closure of account (EI 13)',
	pre.DisplayName = 'S857 Suspicious closure of account (EI 13)'
	FROM dbo.RefProcess pre
	WHERE pre.Code = 'S857'
GO
--RC WEB-86982 START