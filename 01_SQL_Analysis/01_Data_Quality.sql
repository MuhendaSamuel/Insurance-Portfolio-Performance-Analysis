/*
PROJECT: Insurance Portfolio Performance & Risk Analysis
DATABASE: InsurancePortfolioDB
SECTION: 01 - Data Quality Checks

PURPOSE:
Assess the completeness, consistency and reliability
of the insurance portfolio data.
*/

-- 1. Check total number of records in key tables

SELECT 'Policies' AS TableName, COUNT(*) AS TotalRecords
FROM policies

UNION ALL

SELECT 'Customers', COUNT(*)
FROM customers

UNION ALL

SELECT 'Claims', COUNT(*)
FROM claims

UNION ALL

SELECT 'Invoices', COUNT(*)
FROM invoices

UNION ALL

SELECT 'Payments', COUNT(*)
FROM payments

UNION ALL

SELECT 'Underwriting Assessments', COUNT(*)
FROM underwriting_assessments

UNION ALL

SELECT 'Renewals', COUNT(*)
FROM renewals

UNION ALL

SELECT 'Reinsurance Claims', COUNT(*)
FROM reinsurance_claims;




-- 2. Check for missing values in key policy fields

SELECT
    COUNT(*) AS TotalPolicies,

    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)
        AS MissingCustomerID,

    SUM(CASE WHEN agent_id IS NULL THEN 1 ELSE 0 END)
        AS MissingAgentID,

    SUM(CASE WHEN premium IS NULL THEN 1 ELSE 0 END)
        AS MissingPremium,

    SUM(CASE WHEN start_date IS NULL THEN 1 ELSE 0 END)
        AS MissingStartDate,

    SUM(CASE WHEN end_date IS NULL THEN 1 ELSE 0 END)
        AS MissingEndDate,

    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END)
        AS MissingStatus

FROM policies;


-- 3. Check for duplicate policy numbers

SELECT
    number AS PolicyNumber,
    COUNT(*) AS Occurrences
FROM policies
GROUP BY number
HAVING COUNT(*) > 1;



-- 4. Identify invalid policy records

SELECT
    id AS PolicyID,
    number AS PolicyNumber,
    premium,
    coverage,
    start_date,
    end_date
FROM policies
WHERE
    end_date < start_date
    OR premium <= 0
    OR coverage <= 0;