/*
PROJECT: Insurance Portfolio Performance & Risk Analysis
DATABASE: InsurancePortfolioDB
SECTION: Supplementary - Renewals Analysis

PURPOSE:
Examine policy renewal outcomes and identify
patterns in portfolio retention.
*/


-- 1. Overall Renewal Performance

SELECT
    status,
    COUNT(*) AS TotalRenewals,
    ROUND(AVG(premium), 2) AS AverageRenewalPremium,
    MIN(date) AS EarliestRenewalDate,
    MAX(date) AS LatestRenewalDate

FROM renewals

GROUP BY status

ORDER BY TotalRenewals DESC;

-- 2. Renewal Performance by Product Category

SELECT
    pc.name AS ProductCategory,

    COUNT(*) AS TotalRenewals,

    SUM(CASE
        WHEN r.status = 'renewed' THEN 1
        ELSE 0
    END) AS RenewedPolicies,

    SUM(CASE
        WHEN r.status = 'declined' THEN 1
        ELSE 0
    END) AS DeclinedPolicies,

    SUM(CASE
        WHEN r.status = 'lapsed' THEN 1
        ELSE 0
    END) AS LapsedPolicies,

    ROUND(
        SUM(CASE
            WHEN r.status = 'renewed' THEN 1.0
            ELSE 0
        END) * 100.0 / COUNT(*),
        2
    ) AS RenewalRate

FROM renewals r

JOIN policies p
    ON r.policy_id = p.id

JOIN policy_plans pp
    ON p.plan_id = pp.id

JOIN policy_categories pc
    ON pp.category_id = pc.id

GROUP BY pc.name

ORDER BY RenewalRate DESC;


-- 3. Renewal Performance by Year

SELECT
    YEAR(date) AS RenewalYear,

    COUNT(*) AS TotalRenewals,

    SUM(CASE
        WHEN status = 'renewed' THEN 1
        ELSE 0
    END) AS RenewedPolicies,

    SUM(CASE
        WHEN status = 'declined' THEN 1
        ELSE 0
    END) AS DeclinedPolicies,

    SUM(CASE
        WHEN status = 'lapsed' THEN 1
        ELSE 0
    END) AS LapsedPolicies,

    ROUND(
        SUM(CASE
            WHEN status = 'renewed' THEN 1.0
            ELSE 0
        END) * 100.0 / COUNT(*),
        2
    ) AS RenewalRate

FROM renewals

GROUP BY YEAR(date)

ORDER BY RenewalYear;


-- 4. Average Renewal Premium by Outcome and Product

SELECT
    pc.name AS ProductCategory,
    r.status,

    COUNT(*) AS TotalRenewals,

    ROUND(AVG(r.premium), 2) AS AverageRenewalPremium,

    ROUND(MIN(r.premium), 2) AS MinimumPremium,

    ROUND(MAX(r.premium), 2) AS MaximumPremium

FROM renewals r

JOIN policies p
    ON r.policy_id = p.id

JOIN policy_plans pp
    ON p.plan_id = pp.id

JOIN policy_categories pc
    ON pp.category_id = pc.id

GROUP BY
    pc.name,
    r.status

ORDER BY
    pc.name,
    AverageRenewalPremium DESC;