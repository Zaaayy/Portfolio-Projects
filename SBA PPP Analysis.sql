-- cleaning of sba industry data and dropping into a new table

SELECT * 
INTO sba_sector_codes
FROM (
	SELECT NAICS_Industry_Description,
		CASE
			WHEN NAICS_Industry_Description LIKE '%�%'
			THEN SUBSTRING(NAICS_Industry_Description, 8, 2)
		END AS LookupCodes,
		CASE
			WHEN NAICS_Industry_Description LIKE '%�%'
			THEN SUBSTRING(NAICS_Industry_Description,
				 CHARINDEX('�', NAICS_Industry_Description) + 2,
				 LEN(NAICS_Industry_Description))
		END AS Sector
	FROM [dbo].[sba_industry_standards]
	WHERE NAICS_Codes = ''
	) main
WHERE LookupCodes != '';

INSERT INTO [dbo].[sba_sector_codes]
VALUES
	('Sector 31 – 33 – Manufacturing', 32, 'Manufacturing'),
	('Sector 31 – 33 – Manufacturing', 33, 'Manufacturing'),
	('Sector 44 - 45 – Retail Trade', 45, 'Retail Trade'),
	('Sector 48 - 49 – Transportation and Warehousing', 49, 'Transportation and Warehousing');

UPDATE [dbo].[sba_sector_codes]
SET Sector = 'Manufacturing'
WHERE LookupCodes = 31;


-- what is the summary of all approved PPP loans
SELECT
	COUNT(LoanNumber) Loan_Count,
	SUM(InitialApprovalAmount) Loan_Approved,
	AVG(InitialApprovalAmount) Average_Loan_Approved
FROM [dbo].[sba_public_data];


-- what is the summary of all approved PPP loans by year
SELECT
	COUNT(LoanNumber) Loan_Count,
	SUM(InitialApprovalAmount) Loan_Approved,
	AVG(InitialApprovalAmount) Average_Loan_Approved
FROM [dbo].[sba_public_data]
WHERE YEAR(DateApproved) = 2020

SELECT
	COUNT(LoanNumber) Loan_Count,
	SUM(InitialApprovalAmount) Loan_Approved,
	AVG(InitialApprovalAmount) Average_Loan_Approved
FROM [dbo].[sba_public_data]
WHERE YEAR(DateApproved) = 2021;


-- total count of originating lenders
SELECT 
	COUNT( DISTINCT OriginatingLender) Total_Lenders,
	COUNT(LoanNumber) Loan_Count,
	SUM(InitialApprovalAmount) Loan_Approved,
	AVG(InitialApprovalAmount) Average_Loan_Approved
FROM [dbo].[sba_public_data]
WHERE YEAR(DateApproved) = 2020

SELECT
	COUNT(DISTINCT OriginatingLender) Total_Lenders,
	COUNT(LoanNumber) Loan_Count,
	SUM(InitialApprovalAmount) Loan_Approved,
	AVG(InitialApprovalAmount) Average_Loan_Approved
FROM [dbo].[sba_public_data]
WHERE YEAR(DateApproved) = 2021;


-- top 15 summary by originating lenders
SELECT
	TOP 15
	OriginatingLender,
	COUNT(LoanNumber) Loan_Count,
	SUM(InitialApprovalAmount) Loan_Approved,
	AVG(InitialApprovalAmount) Average_Loan_Approved
FROM [dbo].[sba_public_data]
WHERE YEAR(DateApproved) = 2020
GROUP BY OriginatingLender
ORDER BY SUM(InitialApprovalAmount) DESC

SELECT
	TOP 15
	OriginatingLender,
	COUNT(LoanNumber) Loan_Count,
	SUM(InitialApprovalAmount) Loan_Approved,
	AVG(InitialApprovalAmount) Average_Loan_Approved
FROM [dbo].[sba_public_data]
WHERE YEAR(DateApproved) = 2021
GROUP BY OriginatingLender
ORDER BY SUM(InitialApprovalAmount) DESC;


-- % distribution by sector
WITH cte as (
	SELECT ncd.Sector, COUNT(LoanNumber) Loans_Count, SUM(InitialApprovalAmount) Loan_Approved
	FROM [dbo].[sba_public_data] main
	INNER JOIN [dbo].[sba_sector_codes]  ncd
		ON LEFT(CAST(main.NAICSCode AS VARCHAR), 2) = ncd.LookupCodes
	GROUP BY ncd.Sector

)
SELECT 
	sector, Loans_Count,
	SUM(Loan_Approved) OVER(PARTITION BY sector) AS Loan_Approved,
	CAST(1. * Loan_Approved / SUM(Loan_Approved) OVER() AS DECIMAL(5,2)) * 100 AS Percent_by_Amount  
FROM cte  
ORDER BY SUM(Loan_Approved) OVER(PARTITION BY sector) DESC

-- how much of the loans have been fully forgiven in 2020 & 2021
SELECT
	COUNT(LoanNumber) Loan_Count,
	SUM(CurrentApprovalAmount) Loan_Approved,
	AVG(CurrentApprovalAmount) Average_Loan_Approved,
	SUM(ForgivenessAmount) Total_Forgiveness_Amount,
	SUM(ForgivenessAmount) / SUM(CurrentApprovalAmount) * 100 percent_forgiven
FROM [dbo].[sba_public_data]
WHERE YEAR(DateApproved) = 2020 AND ForgivenessAmount <> 0

SELECT
	COUNT(LoanNumber) Loan_Count,
	SUM(CurrentApprovalAmount) Loan_Approved,
	AVG(CurrentApprovalAmount) Average_Loan_Approved,
	SUM(ForgivenessAmount) Total_Forgiveness_Amount,
	SUM(ForgivenessAmount) / SUM(CurrentApprovalAmount) * 100 percent_forgiven
FROM [dbo].[sba_public_data]
WHERE YEAR(DateApproved) = 2021;

---Demographics for PPP
SELECT Race, COUNT(LoanNumber) Loan_Count, SUM(CurrentApprovalAmount) Loan_Approved
FROM [dbo].[sba_public_data]
GROUP BY Race
ORDER BY SUM(CurrentApprovalAmount) DESC;

SELECT Gender, COUNT(LoanNumber) Loan_Count, SUM(CurrentApprovalAmount) Loan_Approved
FROM [dbo].[sba_public_data]
GROUP BY Gender
ORDER BY sum(CurrentApprovalAmount) DESC;

SELECT Ethnicity, COUNT(LoanNumber) Loan_Count, SUM(CurrentApprovalAmount) Loan_Approved
FROM [dbo].[sba_public_data]
GROUP BY Ethnicity
ORDER BY SUM(CurrentApprovalAmount) DESC;

SELECT Veteran, COUNT(LoanNumber) Loan_Count, SUM(CurrentApprovalAmount) Loan_Approved
FROM [dbo].[sba_public_data]
GROUP BY Veteran
ORDER BY SUM(CurrentApprovalAmount) DESC;


-- year, month with the highest PPP loans approved
SELECT
	YEAR(DateApproved) Year,
	FORMAT(DateApproved, 'MMM') MonthName,
	COUNT(LoanNumber) Loan_Count,
	SUM(InitialApprovalAmount) Loan_Approved,
	AVG(InitialApprovalAmount) Average_Loan_Approved
FROM [dbo].[sba_public_data]
GROUP BY YEAR(DateApproved),
	FORMAT(DateApproved, 'MMM')
Order by SUM(InitialApprovalAmount) DESC;

-- count of states
SELECT
	COUNT(DISTINCT BorrowerState) Total_states,
	COUNT(DISTINCT BorrowerCity) Total_cities
FROM [dbo].[sba_public_data];

-- states with highest ppp loans approved
SELECT
	TOP 15
	BorrowerState,
	COUNT(LoanNumber) Loan_Count,
	SUM(InitialApprovalAmount) Loan_Approved,
	AVG(InitialApprovalAmount) Average_Loan_Approved
FROM [dbo].[sba_public_data]
GROUP BY BorrowerState
ORDER BY SUM(InitialApprovalAmount) DESC;


---- Power BI Data Source Query

CREATE VIEW ppp_main AS

SELECT
			c.Sector,
			YEAR(DateApproved) Year_Approved,
			MONTH(DateApproved) Month_Num,
			FORMAT(DateApproved, 'MMM') Month_Approved,
			OriginatingLender,
			State,
			Borrowerstate,
			Race,
			Gender,
			Ethnicity,

			COUNT(LoanNumber) Number_of_loans,
			SUM(CurrentApprovalAmount) Current_loan_approved,
			AVG(CurrentApprovalAmount) Current_average_loan_approved,

			SUM(InitialApprovalAmount) Initial_loan_approved,
			AVG(InitialApprovalAmount) Initial_average_loan_amount,
			SUM(ForgivenessAmount) Total_forgiveness_amount

FROM [dbo].[sba_public_data] p
			INNER JOIN [dbo].[sba_sector_codes] c
			ON LEFT(NAICSCode, 2) = LookupCodes
			INNER JOIN [dbo].[State_abbs]
			ON Postal = BorrowerState
		
GROUP BY c.Sector,
			YEAR(DateApproved),
			MONTH(DateApproved),
			FORMAT(DateApproved, 'MMM'),
			OriginatingLender,
			State,
			BorrowerState,
			Race,
			Gender,
			Ethnicity;
