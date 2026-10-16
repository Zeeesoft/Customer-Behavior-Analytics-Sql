-- ============================================================
-- Scenario 3: Identify active plans with no transactions 
--             in the past 365 days (inactivity alert)
-- ============================================================

WITH latest_transaction AS (
    -- Step 1: Capture most recent transaction per plan
    SELECT 
        s.plan_id,
        MAX(s.transaction_date) AS last_transaction_date
    FROM 
        savings_savingsaccount s
    GROUP BY 
        s.plan_id
),

filtered_plans AS (
    -- Step 2: Enrich each plan with transaction and owner details
    SELECT 
        p.id AS plan_id,
        p.owner_id,
        -- Infer plan type using logical flags
        CASE 
            WHEN p.is_regular_savings = 1 THEN 'Savings'
            WHEN p.is_a_fund = 1 THEN 'Investment'
            ELSE 'Unknown'
        END AS type,
        lt.last_transaction_date,
        -- Compute inactivity duration in days
        DATEDIFF(CURRENT_DATE, lt.last_transaction_date) AS inactivity_days
    FROM 
        plans_plan p

    -- Join to get each plan's last transaction date
    JOIN 
        latest_transaction lt ON p.id = lt.plan_id

    -- Filter to retain only active (non-archived) plans
    WHERE 
        p.is_archived = 0 
        AND p.is_deleted = 0 
        AND p.is_deleted_from_group = 0
        AND lt.last_transaction_date < DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY)
)

-- Step 3: Output plans that meet inactivity criteria
SELECT 
    plan_id,
    owner_id,
    type,
    last_transaction_date,
    inactivity_days
FROM 
    filtered_plans
ORDER BY 
    inactivity_days DESC;
