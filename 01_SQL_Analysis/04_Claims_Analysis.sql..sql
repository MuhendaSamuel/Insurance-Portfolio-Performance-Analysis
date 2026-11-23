/*
PROJECT: Insurance Portfolio Performance & Risk Analysis
DATABASE: InsurancePortfolioDB
SECTION: 04 - Claims Analysis

PURPOSE:
Analyse claims volumes, estimated losses, approval
outcomes and claim payment performance.
*/

-- 1. Overall Claims Summary

SELECT
    COUNT(*) AS TotalClaims,
    ROUND(SUM(estimated_loss), 2) AS TotalEstimatedLoss,
    ROUND(AVG(estimated_loss), 2) AS AverageEstimatedLoss,
    ROUND(MIN(estimated_loss), 2) AS MinimumEstimatedLoss,
    ROUND(MAX(estimated_loss), 2) AS MaximumEstimatedLoss
FROM claims;



-- 2. Claims Distribution by Status

SELECT
    status,
    COUNT(*) AS TotalClaims,
    ROUND(SUM(estimated_loss), 2) AS TotalEstimatedLoss,
    ROUND(AVG(estimated_loss), 2) AS AverageEstimatedLoss
FROM claims
GROUP BY status
ORDER BY TotalClaims DESC;

-- 3. Overall Claim Payment Summary

SELECT
    COUNT(*) AS TotalPaymentRecords,
    ROUND(SUM(amount), 2) AS TotalClaimPayments,
    ROUND(AVG(amount), 2) AS AverageClaimPayment,
    ROUND(MIN(amount), 2) AS MinimumClaimPayment,
    ROUND(MAX(amount), 2) AS MaximumClaimPayment
FROM claim_payments;


-- 4. Claims by Status and Payment Records

SELECT
    c.status,
    COUNT(DISTINCT c.id) AS TotalClaims,
    COUNT(DISTINCT cp.claim_id) AS ClaimsWithPayments,
    COUNT(DISTINCT CASE
        WHEN cp.claim_id IS NULL THEN c.id
    END) AS ClaimsWithoutPayments,
    ROUND(SUM(ISNULL(cp.amount, 0)), 2) AS TotalPayments
FROM claims c
LEFT JOIN claim_payments cp
    ON c.id = cp.claim_id
GROUP BY c.status
ORDER BY TotalClaims DESC;

-- 5. Approved Claims: Approved Amount vs Actual Payments

SELECT
    COUNT(DISTINCT c.id) AS TotalApprovedClaims,

    ROUND(SUM(ca.approved), 2) AS TotalApprovedAmount,

    ROUND(SUM(ISNULL(cp.amount, 0)), 2) AS TotalActualPayments,

    ROUND(
        SUM(ca.approved) - SUM(ISNULL(cp.amount, 0)), 2
    ) AS Difference,

    ROUND(
        100.0 * SUM(ISNULL(cp.amount, 0)) /
        NULLIF(SUM(ca.approved), 0), 2
    ) AS PaymentToApprovalRate

FROM claims c
JOIN claim_assessments ca
    ON c.id = ca.claim_id
LEFT JOIN claim_payments cp
    ON c.id = cp.claim_id

WHERE c.status = 'approved';

-- 6. Claims Reporting to Assessment Turnaround Time

SELECT
    COUNT(*) AS TotalAssessedClaims,

    ROUND(
        AVG(CAST(DATEDIFF(DAY, c.report_date, ca.date) AS DECIMAL(10,2))),
        2
    ) AS AverageAssessmentDays,

    MIN(DATEDIFF(DAY, c.report_date, ca.date))
        AS MinimumAssessmentDays,

    MAX(DATEDIFF(DAY, c.report_date, ca.date))
        AS MaximumAssessmentDays

FROM claims c
JOIN claim_assessments ca
    ON c.id = ca.claim_id

WHERE ca.status = 'approved';

-- 7. Claims Assessment to Payment Turnaround Time

SELECT
    COUNT(*) AS TotalPaidClaims,

    ROUND(
        AVG(CAST(DATEDIFF(DAY, ca.date, cp.date) AS DECIMAL(10,2))),
        2
    ) AS AveragePaymentDays,

    MIN(DATEDIFF(DAY, ca.date, cp.date))
        AS MinimumPaymentDays,

    MAX(DATEDIFF(DAY, ca.date, cp.date))
        AS MaximumPaymentDays

FROM claim_assessments ca
JOIN claim_payments cp
    ON ca.claim_id = cp.claim_id

WHERE ca.status = 'approved';

-- 8. Claim Payment Turnaround by Claim Size

SELECT
    CASE
        WHEN c.estimated_loss < 1000 THEN 'Below 1,000'
        WHEN c.estimated_loss < 5000 THEN '1,000 - 4,999'
        WHEN c.estimated_loss < 10000 THEN '5,000 - 9,999'
        WHEN c.estimated_loss < 25000 THEN '10,000 - 24,999'
        ELSE '25,000 and Above'
    END AS ClaimSizeCategory,

    COUNT(*) AS TotalPaidClaims,

    ROUND(AVG(cp.amount), 2) AS AveragePaymentAmount,

    ROUND(
        AVG(CAST(DATEDIFF(DAY, ca.date, cp.date) AS DECIMAL(10,2))),
        2
    ) AS AveragePaymentDays

FROM claims c
JOIN claim_assessments ca
    ON c.id = ca.claim_id
JOIN claim_payments cp
    ON c.id = cp.claim_id

WHERE ca.status = 'approved'

GROUP BY
    CASE
        WHEN c.estimated_loss < 1000 THEN 'Below 1,000'
        WHEN c.estimated_loss < 5000 THEN '1,000 - 4,999'
        WHEN c.estimated_loss < 10000 THEN '5,000 - 9,999'
        WHEN c.estimated_loss < 25000 THEN '10,000 - 24,999'
        ELSE '25,000 and Above'
    END

ORDER BY
    MIN(c.estimated_loss);

    -- 9. Claims Performance by Product Category

SELECT
    pc.name AS ProductCategory,

    COUNT(DISTINCT c.id) AS TotalClaims,

    ROUND(SUM(c.estimated_loss), 2) AS TotalEstimatedLoss,

    ROUND(AVG(c.estimated_loss), 2) AS AverageEstimatedLoss,

    ROUND(SUM(ISNULL(cp.amount, 0)), 2) AS TotalClaimPayments

FROM claims c

JOIN policies p
    ON c.policy_id = p.id

JOIN policy_plans pp
    ON p.plan_id = pp.id

JOIN policy_categories pc
    ON pp.category_id = pc.id

LEFT JOIN claim_payments cp
    ON c.id = cp.claim_id

GROUP BY pc.name

ORDER BY TotalEstimatedLoss DESC;

-- 10. Claims Frequency by Product Category

WITH ProductPolicies AS (
    SELECT
        pc.name AS ProductCategory,
        COUNT(DISTINCT p.id) AS TotalPolicies
    FROM policies p
    JOIN policy_plans pp
        ON p.plan_id = pp.id
    JOIN policy_categories pc
        ON pp.category_id = pc.id
    GROUP BY pc.name
),

ProductClaims AS (
    SELECT
        pc.name AS ProductCategory,
        COUNT(c.id) AS TotalClaims
    FROM claims c
    JOIN policies p
        ON c.policy_id = p.id
    JOIN policy_plans pp
        ON p.plan_id = pp.id
    JOIN policy_categories pc
        ON pp.category_id = pc.id
    GROUP BY pc.name
)

SELECT
    pp.ProductCategory,
    pp.TotalPolicies,
    ISNULL(pc.TotalClaims, 0) AS TotalClaims,

    ROUND(
        100.0 * ISNULL(pc.TotalClaims, 0) /
        NULLIF(pp.TotalPolicies, 0), 2
    ) AS ClaimsPer100Policies

FROM ProductPolicies pp
LEFT JOIN ProductClaims pc
    ON pp.ProductCategory = pc.ProductCategory

ORDER BY ClaimsPer100Policies DESC;

-- 11. Average Claim Severity by Product Category

SELECT
    pc.name AS ProductCategory,
    COUNT(c.id) AS TotalClaims,
    ROUND(AVG(c.estimated_loss), 2) AS AverageClaimSeverity,
    ROUND(MIN(c.estimated_loss), 2) AS MinimumClaimSeverity,
    ROUND(MAX(c.estimated_loss), 2) AS MaximumClaimSeverity
FROM claims c
JOIN policies p
    ON c.policy_id = p.id
JOIN policy_plans pp
    ON p.plan_id = pp.id
JOIN policy_categories pc
    ON pp.category_id = pc.id
GROUP BY pc.name
ORDER BY AverageClaimSeverity DESC;

-- 12. Claims Approval Rate by Product Category

SELECT
    pc.name AS ProductCategory,
    COUNT(c.id) AS TotalClaims,
    SUM(CASE
        WHEN c.status = 'approved' THEN 1
        ELSE 0
    END) AS ApprovedClaims,
    SUM(CASE
        WHEN c.status = 'denied' THEN 1
        ELSE 0
    END) AS DeniedClaims,
    SUM(CASE
        WHEN c.status = 'under review' THEN 1
        ELSE 0
    END) AS ClaimsUnderReview,
    ROUND(
        100.0 * SUM(CASE
            WHEN c.status = 'approved' THEN 1
            ELSE 0
        END) / NULLIF(COUNT(c.id), 0),
        2
    ) AS ApprovalRate
FROM claims c
JOIN policies p
    ON c.policy_id = p.id
JOIN policy_plans pp
    ON p.plan_id = pp.id
JOIN policy_categories pc
    ON pp.category_id = pc.id
GROUP BY pc.name
ORDER BY ApprovalRate DESC;

-- 13. Claims Assessment Performance by Adjuster

SELECT
    a.id AS AdjusterID,
    CONCAT(a.first_name, ' ', a.last_name) AS AdjusterName,
    COUNT(DISTINCT ca.claim_id) AS TotalClaimsAssessed,
    SUM(CASE
        WHEN ca.status = 'approved' THEN 1
        ELSE 0
    END) AS ApprovedClaims,
    SUM(CASE
        WHEN ca.status = 'denied' THEN 1
        ELSE 0
    END) AS DeniedClaims,
    ROUND(
        100.0 * SUM(CASE
            WHEN ca.status = 'approved' THEN 1
            ELSE 0
        END) / NULLIF(COUNT(ca.id), 0),
        2
    ) AS ApprovalRate
FROM claim_assessments ca
JOIN adjusters a
    ON ca.adjuster_id = a.id
GROUP BY
    a.id,
    a.first_name,
    a.last_name
ORDER BY ApprovalRate DESC;



-- 14. Claim Assessment Performance by Adjuster Workload

WITH AdjusterPerformance AS (
    SELECT
        ca.adjuster_id,
        COUNT(ca.id) AS TotalAssessments,
        SUM(CASE
            WHEN ca.status = 'approved' THEN 1
            ELSE 0
        END) AS ApprovedClaims,
        ROUND(
            100.0 * SUM(CASE
                WHEN ca.status = 'approved' THEN 1
                ELSE 0
            END) / NULLIF(COUNT(ca.id), 0),
            2
        ) AS ApprovalRate
    FROM claim_assessments ca
    GROUP BY ca.adjuster_id
)

SELECT
    CASE
        WHEN TotalAssessments < 25 THEN 'Below 25'
        WHEN TotalAssessments < 35 THEN '25 - 34'
        WHEN TotalAssessments < 45 THEN '35 - 44'
        ELSE '45 and Above'
    END AS WorkloadCategory,
    COUNT(*) AS TotalAdjusters,
    SUM(TotalAssessments) AS TotalAssessments,
    ROUND(AVG(ApprovalRate), 2) AS AverageApprovalRate
FROM AdjusterPerformance
GROUP BY
    CASE
        WHEN TotalAssessments < 25 THEN 'Below 25'
        WHEN TotalAssessments < 35 THEN '25 - 34'
        WHEN TotalAssessments < 45 THEN '35 - 44'
        ELSE '45 and Above'
    END
ORDER BY MIN(TotalAssessments);

-- 15. Average Claim Severity by Adjuster

SELECT
    a.id AS AdjusterID,
    CONCAT(a.first_name, ' ', a.last_name) AS AdjusterName,
    COUNT(DISTINCT c.id) AS TotalClaimsAssessed,
    ROUND(AVG(c.estimated_loss), 2) AS AverageClaimSeverity,
    ROUND(AVG(ca.approved), 2) AS AverageApprovedAmount,
    ROUND(
        100.0 * SUM(CASE
            WHEN ca.status = 'approved' THEN 1
            ELSE 0
        END) / NULLIF(COUNT(ca.id), 0),
        2
    ) AS ApprovalRate
FROM claim_assessments ca
JOIN adjusters a
    ON ca.adjuster_id = a.id
JOIN claims c
    ON ca.claim_id = c.id
GROUP BY
    a.id,
    a.first_name,
    a.last_name
ORDER BY AverageClaimSeverity DESC;


-- 16. Claims Outcomes by Incident Year

SELECT
    YEAR(incident_date) AS IncidentYear,
    COUNT(*) AS TotalClaims,
    SUM(CASE
        WHEN status = 'approved' THEN 1
        ELSE 0
    END) AS ApprovedClaims,
    SUM(CASE
        WHEN status = 'denied' THEN 1
        ELSE 0
    END) AS DeniedClaims,
    SUM(CASE
        WHEN status = 'under review' THEN 1
        ELSE 0
    END) AS ClaimsUnderReview,
    ROUND(AVG(estimated_loss), 2) AS AverageEstimatedLoss,
    ROUND(
        100.0 * SUM(CASE
            WHEN status = 'approved' THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS ApprovalRate
FROM claims
GROUP BY YEAR(incident_date)
ORDER BY IncidentYear;


-- 17. Monthly Claims Trends

SELECT
    YEAR(incident_date) AS IncidentYear,
    MONTH(incident_date) AS IncidentMonth,
    COUNT(*) AS TotalClaims,
    ROUND(SUM(estimated_loss), 2) AS TotalEstimatedLoss,
    ROUND(AVG(estimated_loss), 2) AS AverageEstimatedLoss,
    SUM(CASE
        WHEN status = 'approved' THEN 1
        ELSE 0
    END) AS ApprovedClaims,
    SUM(CASE
        WHEN status = 'denied' THEN 1
        ELSE 0
    END) AS DeniedClaims
FROM claims
GROUP BY
    YEAR(incident_date),
    MONTH(incident_date)
ORDER BY
    IncidentYear,
    IncidentMonth;