-- ==========================================================
-- Scenario 1: Identify customers who have both a funded savings 
--            and a funded investment plan, ranked by total deposits
-- ==========================================================

SELECT 
    u.id AS owner_id,
    u.name,
    
    -- Count of distinct funded savings plans for this customer
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN s.id END) AS savings_count,
    
    -- Count of distinct funded investment plans for this customer
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN s.id END) AS investment_count,
    
    -- Sum of confirmed deposits (converted from kobo to naira and rounded)
    ROUND(SUM(s.confirmed_amount) / 100.0, 2) AS total_deposits

FROM 
    savings_savingsaccount s

-- Join to get the plan type flags (is_regular_savings, is_a_fund)
JOIN 
    plans_plan p ON s.plan_id = p.id

-- Join to get customer details for reporting (name, id)
JOIN 
    users_customuser u ON s.owner_id = u.id

-- Filter only funded transactions (confirmed_amount > 0)
WHERE 
    s.confirmed_amount > 0

-- Group by customer to compute aggregates per user
GROUP BY 
    u.id, u.name

-- Keep only customers who have at least one savings and one investment plan
HAVING 
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN s.id END) > 0
    AND COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN s.id END) > 0

-- Order by financial value to prioritize high-value users
ORDER BY 
    total_deposits DESC;
