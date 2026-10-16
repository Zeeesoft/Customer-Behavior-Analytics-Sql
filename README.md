# Customer Behavior & Value Analytics in SQL

**A MySQL analysis of customer segmentation, transaction behavior, account inactivity and customer lifetime value (CLV) on a savings and investment platform.**

---

## Overview

This project uses SQL to answer four business questions about a savings and investment platform's customers:

1. Which customers hold both savings and investment products, and how much have they deposited?
2. How often does each customer transact, and how do customers segment by activity?
3. Which active accounts have gone quiet and may need re-engagement?
4. What is each customer's estimated lifetime value?

Each analysis is a self-contained MySQL script built with joins, aggregations, CTEs, conditional logic and date functions.

**Tools:** MySQL
**Techniques:** multi-table joins, `GROUP BY` / `HAVING`, CTEs, `CASE`, date arithmetic, edge-case handling

---

## Repository Structure

```
customer-analytics-sql/
│
├── 01_multi_product_customers.sql         High-value customers with multiple products
├── 02_transaction_frequency_segments.sql  Transaction frequency segmentation
├── 03_inactive_accounts.sql               Account inactivity detection
├── 04_customer_lifetime_value.sql         Customer lifetime value (CLV) estimation
│
└── README.md                              Approach, assumptions and how to run
```

---

## Data Model

The analysis uses four tables:

| Table | Purpose |
|---|---|
| `users_customuser` | Customer records, including sign-up date (`date_joined`) |
| `plans_plan` | Savings and investment plans, with type and status flags |
| `savings_savingsaccount` | Deposit transactions, including `confirmed_amount` and transaction dates |
| `withdrawals_withdrawal` | Withdrawal records |

**Key fields**
- `is_regular_savings = 1` identifies a savings plan
- `is_a_fund = 1` identifies an investment plan
- `confirmed_amount > 0` identifies a confirmed deposit
- Amounts are stored in **kobo** and converted to **naira** for reporting

---

## Analyses

### 1. High-Value Customers with Multiple Products
`01_multi_product_customers.sql`

**Business question:** Which customers have both a funded savings plan and a funded investment plan, and how much have they deposited in total?

**Approach**
- Counted distinct funded savings plans and funded investment plans per customer
- Joined `savings_savingsaccount`, `plans_plan` and `users_customuser` to connect customers, plans and deposits
- Kept confirmed transactions only (`confirmed_amount > 0`)
- Summed deposits, converted from kobo to naira and rounded to 2 decimal places
- Used `HAVING` to keep customers with at least one of each plan type
- Sorted by `total_deposits` descending to surface the highest-value customers

**Data problems handled**
- Classifying plans with boolean flags so savings and investment plans never overlap
- Using `DISTINCT` to prevent double-counting when aggregating plan counts
- Using `HAVING` rather than `WHERE` to filter on aggregated values
- Converting currency units and rounding correctly for reporting

---

### 2. Transaction Frequency Analysis
`02_transaction_frequency_segments.sql`

**Business question:** How often does each customer transact, and how do customers group by activity level?

| Segment | Definition |
|---|---|
| High Frequency | 10 or more transactions per month |
| Medium Frequency | 3 to 9 transactions per month |
| Low Frequency | 2 or fewer transactions per month |

**Approach**
- Counted transactions per customer from `savings_savingsaccount`
- Calculated tenure in months from each customer's first to last transaction
- Applied `GREATEST(..., 1)` to avoid division by zero for single-month customers
- Computed `avg_transactions_per_month` and assigned segments with a `CASE` statement
- Summarised each segment by customer count and average frequency
- Used `FIELD()` to order results High, Medium, Low

**Data problems handled**
- Divide-by-zero risk for customers active in only one month
- Excluding transactions with missing dates so they don't skew averages
- Keeping the output simple enough for non-technical stakeholders

---

### 3. Account Inactivity Detection
`03_inactive_accounts.sql`

**Business question:** Which active savings or investment plans have received no transactions in the last 365 days?

**Approach**
- Found each plan's most recent transaction with `MAX(transaction_date)`
- Joined the result to `plans_plan` for plan details
- Labelled each plan as `Savings`, `Investment` or `Unknown` based on its flags
- Calculated `inactivity_days` using `DATEDIFF(CURRENT_DATE, last_transaction_date)`
- Filtered to active plans (not deleted or archived)
- Flagged plans with `inactivity_days > 365`

**Data problems handled**
- Defining "active" by checking multiple flags: `is_deleted`, `is_archived` and `is_deleted_from_group`
- Limiting the analysis to plans with real transaction history
- Handling plans that were technically valid but dormant

---

### 4. Customer Lifetime Value (CLV) Estimation
`04_customer_lifetime_value.sql`

**Business question:** What is each customer's estimated long-term value to the business?

**Formula**

```
CLV = (Total Transactions / Tenure in Months) x 12 x (0.1% of Total Transaction Value)
```

**Approach**
- Aggregated confirmed transactions per user from `savings_savingsaccount`
- Calculated tenure from `users_customuser.date_joined` to `CURRENT_DATE` in months, with a minimum of 1
- Computed total transaction value and applied a 0.1% profit margin per transaction
- Converted from kobo to naira and rounded to 2 decimal places
- Joined the aggregated results to user records
- Sorted customers by `estimated_clv` descending

**Data problems handled**
- Enforcing a minimum 1-month tenure so new customers don't cause errors or inflated values
- Scoping aggregation to confirmed deposits only (`confirmed_amount > 0`) for consistency

---

## Assumptions

- Profit is estimated at a fixed **0.1%** of each transaction's value
- Monetary values are stored in **kobo** (1 naira = 100 kobo)
- A plan is considered **active** if it is not deleted, archived or removed from its group
- A plan is considered **inactive** after **365 days** without a transaction
- Only **confirmed** deposits (`confirmed_amount > 0`) are counted

---

## How to Run

The scripts are written for a MySQL-compatible environment. Make sure these tables exist and are populated:

- `users_customuser`
- `plans_plan`
- `savings_savingsaccount`
- `withdrawals_withdrawal`

No schema changes are needed. Each script is self-contained and can be run independently.

---

## Skills Demonstrated

- Multi-table joins across a relational schema
- Aggregation with `GROUP BY` and `HAVING`
- CTEs for readable, modular queries
- Conditional logic with `CASE`
- Date calculations for tenure and recency
- Edge-case handling: divide-by-zero, missing dates, double-counting
- Unit conversion and rounding for business reporting
- Turning open-ended business questions into precise query logic

---

## Contact

Questions about the approach, or ideas for optimizing the queries? Feel free to reach out or open an issue.
