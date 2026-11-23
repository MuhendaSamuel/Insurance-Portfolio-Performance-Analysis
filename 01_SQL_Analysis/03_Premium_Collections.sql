/*
PROJECT: Insurance Portfolio Performance & Risk Analysis
DATABASE: InsurancePortfolioDB
SECTION: 03 - Premium Collections

PURPOSE:
Evaluate premium collection performance, outstanding
balances and collection efficiency.
*/


-- 1. Overall premium collection performance

SELECT
    COUNT(*) AS TotalInvoices,
    ROUND(SUM(i.amount_due), 2) AS TotalInvoiced,
    ROUND(SUM(ISNULL(pay.amount_paid, 0)), 2) AS TotalCollected,

    ROUND(
        SUM(i.amount_due) - SUM(ISNULL(pay.amount_paid, 0)), 2
    ) AS OutstandingBalance,

    ROUND(
        100.0 * SUM(ISNULL(pay.amount_paid, 0)) /
        NULLIF(SUM(i.amount_due), 0), 2
    ) AS CollectionRate

FROM invoices i
LEFT JOIN payments pay
    ON i.id = pay.invoice_id;


    -- 2. Premium collection performance by product

SELECT
    pc.name AS ProductCategory,
    COUNT(DISTINCT p.id) AS TotalPolicies,
    ROUND(SUM(i.amount_due), 2) AS TotalInvoiced,
    ROUND(SUM(ISNULL(pay.amount_paid, 0)), 2) AS TotalCollected,

    ROUND(
        SUM(i.amount_due) -
        SUM(ISNULL(pay.amount_paid, 0)), 2
    ) AS OutstandingBalance,

    ROUND(
        100.0 * SUM(ISNULL(pay.amount_paid, 0)) /
        NULLIF(SUM(i.amount_due), 0), 2
    ) AS CollectionRate

FROM invoices i
JOIN policies p
    ON i.policy_id = p.id
JOIN policy_plans pp
    ON p.plan_id = pp.id
JOIN policy_categories pc
    ON pp.category_id = pc.id
LEFT JOIN payments pay
    ON i.id = pay.invoice_id

GROUP BY pc.name
ORDER BY CollectionRate DESC;

-- 3. Outstanding invoice ageing analysis
-- Reporting date: 31 December 2025

WITH Ageing AS (
    SELECT
        i.id,
        i.amount_due,
        CASE
            WHEN DATEDIFF(DAY, i.due_date, '2025-12-31') <= 0
                THEN 'Not Yet Due'
            WHEN DATEDIFF(DAY, i.due_date, '2025-12-31') BETWEEN 1 AND 30
                THEN '1-30 Days'
            WHEN DATEDIFF(DAY, i.due_date, '2025-12-31') BETWEEN 31 AND 60
                THEN '31-60 Days'
            WHEN DATEDIFF(DAY, i.due_date, '2025-12-31') BETWEEN 61 AND 90
                THEN '61-90 Days'
            ELSE 'Over 90 Days'
        END AS AgeingCategory
    FROM invoices i
    LEFT JOIN payments pay
        ON i.id = pay.invoice_id
    WHERE pay.id IS NULL
)

SELECT
    AgeingCategory,
    COUNT(*) AS OutstandingInvoices,
    ROUND(SUM(amount_due), 2) AS OutstandingAmount
FROM Ageing
GROUP BY AgeingCategory
ORDER BY
    CASE AgeingCategory
        WHEN 'Over 90 Days' THEN 1
        WHEN '61-90 Days' THEN 2
        WHEN '31-60 Days' THEN 3
        WHEN '1-30 Days' THEN 4
        WHEN 'Not Yet Due' THEN 5
    END;


    -- 4. Outstanding premium by insurance agent

SELECT
    a.id AS AgentID,
    CONCAT(a.first_name, ' ', a.last_name) AS AgentName,
    COUNT(i.id) AS OutstandingInvoices,
    COUNT(DISTINCT p.id) AS AffectedPolicies,
    ROUND(SUM(i.amount_due), 2) AS OutstandingAmount

FROM invoices i
JOIN policies p
    ON i.policy_id = p.id
JOIN agents a
    ON p.agent_id = a.id
LEFT JOIN payments pay
    ON i.id = pay.invoice_id

WHERE pay.id IS NULL

GROUP BY
    a.id,
    a.first_name,
    a.last_name

ORDER BY OutstandingAmount DESC;


-- 5. Premium collection performance by agent

SELECT
    a.id AS AgentID,
    CONCAT(a.first_name, ' ', a.last_name) AS AgentName,

    COUNT(i.id) AS TotalInvoices,

    ROUND(SUM(i.amount_due), 2) AS TotalInvoiced,

    ROUND(SUM(ISNULL(pay.amount_paid, 0)), 2) AS TotalCollected,

    ROUND(
        SUM(i.amount_due) -
        SUM(ISNULL(pay.amount_paid, 0)), 2
    ) AS OutstandingAmount,

    ROUND(
        100.0 * SUM(ISNULL(pay.amount_paid, 0)) /
        NULLIF(SUM(i.amount_due), 0), 2
    ) AS CollectionRate

FROM invoices i
JOIN policies p
    ON i.policy_id = p.id
JOIN agents a
    ON p.agent_id = a.id
LEFT JOIN payments pay
    ON i.id = pay.invoice_id

GROUP BY
    a.id,
    a.first_name,
    a.last_name

ORDER BY CollectionRate ASC;


-- 5. Premium collection performance by agent

SELECT
    a.id AS AgentID,
    CONCAT(a.first_name, ' ', a.last_name) AS AgentName,

    COUNT(i.id) AS TotalInvoices,

    ROUND(SUM(i.amount_due), 2) AS TotalInvoiced,

    ROUND(SUM(ISNULL(pay.amount_paid, 0)), 2) AS TotalCollected,

    ROUND(
        SUM(i.amount_due) -
        SUM(ISNULL(pay.amount_paid, 0)), 2
    ) AS OutstandingAmount,

    ROUND(
        100.0 * SUM(ISNULL(pay.amount_paid, 0)) /
        NULLIF(SUM(i.amount_due), 0), 2
    ) AS CollectionRate

FROM invoices i
JOIN policies p
    ON i.policy_id = p.id
JOIN agents a
    ON p.agent_id = a.id
LEFT JOIN payments pay
    ON i.id = pay.invoice_id

GROUP BY
    a.id,
    a.first_name,
    a.last_name

ORDER BY CollectionRate ASC;


-- 6. Premium Collection Performance by Branch

SELECT
    b.id AS BranchID,
    b.name AS BranchName,
    COUNT(DISTINCT p.id) AS TotalPolicies,
    SUM(i.amount_due) AS TotalInvoiced,
    SUM(CASE
        WHEN pay.id IS NOT NULL THEN pay.amount_paid
        ELSE 0
    END) AS TotalCollected,
    SUM(i.amount_due) -
    SUM(CASE
        WHEN pay.id IS NOT NULL THEN pay.amount_paid
        ELSE 0
    END) AS OutstandingAmount,
    ROUND(
        100.0 * SUM(CASE
            WHEN pay.id IS NOT NULL THEN pay.amount_paid
            ELSE 0
        END) / NULLIF(SUM(i.amount_due), 0), 2
    ) AS CollectionRate

FROM policies p
JOIN agents a
    ON p.agent_id = a.id
JOIN branches b
    ON a.branch_id = b.id
JOIN invoices i
    ON p.id = i.policy_id
LEFT JOIN payments pay
    ON i.id = pay.invoice_id

GROUP BY
    b.id,
    b.name

ORDER BY CollectionRate ASC;