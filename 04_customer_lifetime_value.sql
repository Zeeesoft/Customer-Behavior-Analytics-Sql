-- ============================================================
-- Scenario 4: Estimate Customer Lifetime Value (CLV)
--     using transaction history and account tenure
-- ============================================================

WITH user_transactions AS (
    -- Step 1: Aggregate confirmed transactions per user
    SELECT 
        s.owner_id,
        COUNT(*) AS total_transactions,
        SUM(s.confirmed_amount) AS total_transaction_value
    FROM 
        savings_savingsaccount s
    WHERE 
        s.confirmed_amount > 0
    GROUP BY 
        s.owner_id
),

clv_data AS (
    -- Step 2: Calculate tenure and derive CLV using the formula
    SELECT 
        u.id AS customer_id,
        u.name,
        GREATEST(TIMESTAMPDIFF(MONTH, u.date_joined, CURRENT_DATE), 1) AS tenure_months,
        ut.total_transactions,
        ut.total_transaction_value,
        
        -- CLV formula with average profit per transaction
        ROUND(
            (ut.total_transactions / GREATEST(TIMESTAMPDIFF(MONTH, u.date_joined, CURRENT_DATE), 1)) 
            * 12 
            * (ut.total_transaction_value * 0.001 / ut.total_transactions) / 100.0, -- kobo to naira
            2
        ) AS estimated_clv
    FROM 
        users_customuser u

    -- Join to merge transaction data with user metadata
    JOIN 
        user_transactions ut ON u.id = ut.owner_id
)

-- Step 3: Present customers ranked by estimated lifetime value
SELECT 
    customer_id,
    name,
    tenure_months,
    total_transactions,
    estimated_clv
FROM 
    clv_data
ORDER BY 
    estimated_clv DESC;
