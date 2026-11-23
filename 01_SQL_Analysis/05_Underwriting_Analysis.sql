-- 1. Overall Underwriting Decision Summary

SELECT
    decision,
    COUNT(*) AS TotalAssessments,
    ROUND(AVG(risk_score), 2) AS AverageRiskScore,
    MIN(risk_score) AS MinimumRiskScore,
    MAX(risk_score) AS MaximumRiskScore,
    ROUND(AVG(p.premium), 2) AS AveragePremium,
    ROUND(AVG(p.coverage), 2) AS AverageCoverage
FROM underwriting_assessments ua
JOIN policies p
    ON ua.policy_id = p.id
GROUP BY decision
ORDER BY TotalAssessments DESC;

-- 2. Underwriting Decisions by Risk Category

SELECT
    CASE
        WHEN risk_score < 20 THEN 'Very Low Risk'
        WHEN risk_score < 40 THEN 'Low Risk'
        WHEN risk_score < 60 THEN 'Moderate Risk'
        WHEN risk_score < 80 THEN 'High Risk'
        ELSE 'Very High Risk'
    END AS RiskCategory,

    decision,
    COUNT(*) AS TotalAssessments,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (
            PARTITION BY
                CASE
                    WHEN risk_score < 20 THEN 'Very Low Risk'
                    WHEN risk_score < 40 THEN 'Low Risk'
                    WHEN risk_score < 60 THEN 'Moderate Risk'
                    WHEN risk_score < 80 THEN 'High Risk'
                    ELSE 'Very High Risk'
                END
        ),
        2
    ) AS DecisionPercentage

FROM underwriting_assessments
GROUP BY
    CASE
        WHEN risk_score < 20 THEN 'Very Low Risk'
        WHEN risk_score < 40 THEN 'Low Risk'
        WHEN risk_score < 60 THEN 'Moderate Risk'
        WHEN risk_score < 80 THEN 'High Risk'
        ELSE 'Very High Risk'
    END,
    decision
ORDER BY
    MIN(risk_score),
    decision;


-- 3. Underwriting Decisions by Product Category

SELECT
    pc.name AS ProductCategory,
    ua.decision,
    COUNT(*) AS TotalAssessments,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (
            PARTITION BY pc.name
        ),
        2
    ) AS DecisionPercentage,
    ROUND(AVG(ua.risk_score), 2) AS AverageRiskScore

FROM underwriting_assessments ua
JOIN policies p
    ON ua.policy_id = p.id
JOIN policy_plans pp
    ON p.plan_id = pp.id
JOIN policy_categories pc
    ON pp.category_id = pc.id

GROUP BY
    pc.name,
    ua.decision

ORDER BY
    pc.name,
    ua.decision;

    -- 4. Underwriting Performance by Individual Underwriter

SELECT
    u.id AS UnderwriterID,
    CONCAT(u.first_name, ' ', u.last_name) AS UnderwriterName,
    COUNT(*) AS TotalAssessments,

    SUM(CASE
        WHEN ua.decision = 'approved' THEN 1
        ELSE 0
    END) AS ApprovedApplications,

    SUM(CASE
        WHEN ua.decision = 'approved with conditions' THEN 1
        ELSE 0
    END) AS ConditionalApprovals,

    ROUND(
        100.0 * SUM(CASE
            WHEN ua.decision = 'approved' THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS StraightApprovalRate,

    ROUND(AVG(CAST(ua.risk_score AS DECIMAL(10,2))), 2)
        AS AverageRiskScore

FROM underwriting_assessments ua
JOIN underwriters u
    ON ua.underwriter_id = u.id

GROUP BY
    u.id,
    u.first_name,
    u.last_name

ORDER BY StraightApprovalRate DESC;

-- 5. Average Risk Score and Approval Rate by Underwriter

SELECT
    u.id AS UnderwriterID,
    CONCAT(u.first_name, ' ', u.last_name) AS UnderwriterName,
    COUNT(*) AS TotalAssessments,

    ROUND(
        AVG(CAST(ua.risk_score AS DECIMAL(10,2))),
        2
    ) AS AverageRiskScore,

    ROUND(
        100.0 * SUM(CASE
            WHEN ua.decision = 'approved' THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS StraightApprovalRate

FROM underwriting_assessments ua
JOIN underwriters u
    ON ua.underwriter_id = u.id

GROUP BY
    u.id,
    u.first_name,
    u.last_name

ORDER BY AverageRiskScore DESC;

-- 6. Premium and Coverage by Risk Category

SELECT
    CASE
        WHEN ua.risk_score < 20 THEN 'Very Low Risk'
        WHEN ua.risk_score < 40 THEN 'Low Risk'
        WHEN ua.risk_score < 60 THEN 'Moderate Risk'
        WHEN ua.risk_score < 80 THEN 'High Risk'
        ELSE 'Very High Risk'
    END AS RiskCategory,

    COUNT(*) AS TotalAssessments,

    ROUND(AVG(p.premium), 2) AS AveragePremium,
    ROUND(AVG(p.coverage), 2) AS AverageCoverage,

    ROUND(AVG(ua.risk_score), 2) AS AverageRiskScore

FROM underwriting_assessments ua
JOIN policies p
    ON ua.policy_id = p.id

GROUP BY
    CASE
        WHEN ua.risk_score < 20 THEN 'Very Low Risk'
        WHEN ua.risk_score < 40 THEN 'Low Risk'
        WHEN ua.risk_score < 60 THEN 'Moderate Risk'
        WHEN ua.risk_score < 80 THEN 'High Risk'
        ELSE 'Very High Risk'
    END

ORDER BY MIN(ua.risk_score);

-- 7. Claims Experience by Underwriting Risk Category

WITH PolicyRisk AS (
    SELECT
        ua.policy_id,
        ua.risk_score,
        CASE
            WHEN ua.risk_score < 20 THEN 'Very Low Risk'
            WHEN ua.risk_score < 40 THEN 'Low Risk'
            WHEN ua.risk_score < 60 THEN 'Moderate Risk'
            WHEN ua.risk_score < 80 THEN 'High Risk'
            ELSE 'Very High Risk'
        END AS RiskCategory
    FROM underwriting_assessments ua
),

ClaimsByPolicy AS (
    SELECT
        policy_id,
        COUNT(*) AS TotalClaims,
        SUM(estimated_loss) AS TotalEstimatedLoss
    FROM claims
    GROUP BY policy_id
)

SELECT
    pr.RiskCategory,

    COUNT(*) AS TotalPolicies,

    SUM(COALESCE(cp.TotalClaims, 0)) AS TotalClaims,

    ROUND(
        SUM(COALESCE(cp.TotalClaims, 0)) * 100.0 / COUNT(*),
        2
    ) AS ClaimsPer100Policies,

    ROUND(
        SUM(COALESCE(cp.TotalEstimatedLoss, 0)),
        2
    ) AS TotalEstimatedLoss,

    ROUND(
        SUM(COALESCE(cp.TotalEstimatedLoss, 0)) /
        NULLIF(SUM(COALESCE(cp.TotalClaims, 0)), 0),
        2
    ) AS AverageClaimSeverity

FROM PolicyRisk pr

LEFT JOIN ClaimsByPolicy cp
    ON pr.policy_id = cp.policy_id

GROUP BY pr.RiskCategory

ORDER BY MIN(pr.risk_score);

-- 7. Claims Experience by Underwriting Risk Category

WITH PolicyRisk AS (
    SELECT
        ua.policy_id,
        ua.risk_score,
        CASE
            WHEN ua.risk_score < 20 THEN 'Very Low Risk'
            WHEN ua.risk_score < 40 THEN 'Low Risk'
            WHEN ua.risk_score < 60 THEN 'Moderate Risk'
            WHEN ua.risk_score < 80 THEN 'High Risk'
            ELSE 'Very High Risk'
        END AS RiskCategory
    FROM underwriting_assessments ua
),

ClaimsByPolicy AS (
    SELECT
        policy_id,
        COUNT(*) AS TotalClaims,
        SUM(estimated_loss) AS TotalEstimatedLoss
    FROM claims
    GROUP BY policy_id
)

SELECT
    pr.RiskCategory,
    COUNT(*) AS TotalPolicies,

    SUM(COALESCE(cp.TotalClaims, 0)) AS TotalClaims,

    ROUND(
        SUM(COALESCE(cp.TotalClaims, 0)) * 100.0 / COUNT(*),
        2
    ) AS ClaimsPer100Policies,

    ROUND(
        SUM(COALESCE(cp.TotalEstimatedLoss, 0)),
        2
    ) AS TotalEstimatedLoss,

    ROUND(
        SUM(COALESCE(cp.TotalEstimatedLoss, 0)) /
        NULLIF(SUM(COALESCE(cp.TotalClaims, 0)), 0),
        2
    ) AS AverageClaimSeverity

FROM PolicyRisk pr

LEFT JOIN ClaimsByPolicy cp
    ON pr.policy_id = cp.policy_id

GROUP BY pr.RiskCategory

ORDER BY MIN(pr.risk_score);

-- 8. Claims Approval Rate by Underwriting Risk Category

WITH PolicyRisk AS (
    SELECT
        policy_id,
        CASE
            WHEN risk_score < 20 THEN 'Very Low Risk'
            WHEN risk_score < 40 THEN 'Low Risk'
            WHEN risk_score < 60 THEN 'Moderate Risk'
            WHEN risk_score < 80 THEN 'High Risk'
            ELSE 'Very High Risk'
        END AS RiskCategory
    FROM underwriting_assessments
)

SELECT
    pr.RiskCategory,

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
        SUM(CASE
            WHEN c.status = 'approved' THEN 1.0
            ELSE 0
        END) * 100.0 / NULLIF(COUNT(c.id), 0),
        2
    ) AS ApprovalRate

FROM PolicyRisk pr

JOIN claims c
    ON pr.policy_id = c.policy_id

GROUP BY pr.RiskCategory

ORDER BY MIN(
    CASE
        WHEN pr.RiskCategory = 'Very Low Risk' THEN 1
        WHEN pr.RiskCategory = 'Low Risk' THEN 2
        WHEN pr.RiskCategory = 'Moderate Risk' THEN 3
        WHEN pr.RiskCategory = 'High Risk' THEN 4
        ELSE 5
    END
);