/*
PROJECT: Insurance Portfolio Performance & Risk Analysis
DATABASE: InsurancePortfolioDB
SECTION: 02 - Portfolio Overview

PURPOSE:
Analyse the size, composition and premium profile
of the insurance portfolio.
*/

-- 1. Overall policy portfolio summary

SELECT
    COUNT(*) AS TotalPolicies,
    ROUND(SUM(premium), 2) AS TotalWrittenPremium,
    ROUND(AVG(premium), 2) AS AveragePremium,
    ROUND(MIN(premium), 2) AS MinimumPremium,
    ROUND(MAX(premium), 2) AS MaximumPremium,
    ROUND(SUM(coverage), 2) AS TotalCoverage
FROM policies;


-- 2. Portfolio composition by product category

SELECT
    pc.name AS ProductCategory,
    COUNT(p.id) AS TotalPolicies,
    ROUND(SUM(p.premium), 2) AS TotalPremium,
    ROUND(AVG(p.premium), 2) AS AveragePremium,
    ROUND(SUM(p.coverage), 2) AS TotalCoverage
FROM policies p
JOIN policy_plans pp
    ON p.plan_id = pp.id
JOIN policy_categories pc
    ON pp.category_id = pc.id
GROUP BY pc.name
ORDER BY TotalPremium DESC;


-- 3. Policy distribution by status

SELECT
    status,
    COUNT(*) AS TotalPolicies,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM policies), 2
    ) AS PercentageOfPortfolio,
    ROUND(SUM(premium), 2) AS TotalPremium
FROM policies
GROUP BY status
ORDER BY TotalPolicies DESC;