--WEB-65521-RC-START--

GO
DECLARE @ScreeningRuleTypeId INT
SET @ScreeningRuleTypeId = dbo.GetEnumValueId('ScreeningRuleType', 'MultiRuleType2')

INSERT INTO dbo.RefScreeningRule
(
	Name,
	Code,
	ClassName,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn,
	ScreeningRuleTypeRefEnumValueId
)
VALUES 
(
	'Customer MultiRule 27',
	'S5050',
	'TSS.SmallOffice.Business.Logic.Aml.Screening.ScreeningRules.MultiRule27.MultiRule27ScreeningRule',
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	@ScreeningRuleTypeId
)
INSERT INTO dbo.RefScreeningRule
(
	Name,
	Code,
	ClassName,
	AddedBy,
	AddedOn,
	LastEditedBy,
	EditedOn,
	ScreeningRuleTypeRefEnumValueId
)
VALUES 
(
	'Customer MultiRule 28',
	'S5051',
	'TSS.SmallOffice.Business.Logic.Aml.Screening.ScreeningRules.MultiRule28.MultiRule28ScreeningRule',
	'System',
	GETDATE(),
	'System',
	GETDATE(),
	@ScreeningRuleTypeId
)
GO
--WEB-65522-RC-END--
