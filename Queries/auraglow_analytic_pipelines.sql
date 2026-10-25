-- ====================================================================
-- Advanced E-Commerce Cohort Analytics & Media ROI Optimization Case Study: MASTER SQL SCRIPT
-- Framework: AuraGlow Organics Production Analytics Pipeline
-- Platform Engine: DuckDB Optimized Local Columnar Store
-- Project: AuraGlow Organics Performance & Retention Audit
-- ====================================================================

-- --------------------------------------------------------------------
-- PHASE 1: INITIAL DATA QUALITY & HYGIENE AUDIT
-- --------------------------------------------------------------------

-- Check 1: Quantify internal staff and system testing accounts
-- Resolution: Filter out system noise using 'is_internal = FALSE'
SELECT is_internal, COUNT(*) AS customer_count 
FROM customers 
GROUP BY is_internal;

-- Check 2: Evaluate transaction status distributions
-- Resolution: Isolate historical revenue metrics strictly to 'completed' rows
SELECT status, COUNT(*) AS order_count, SUM(net_amount) AS total_net_rev
FROM orders 
GROUP BY status;


-- --------------------------------------------------------------------
-- QUESTION 1: SPRING REFILL PROMOTION PERFORMANCE (MARCH 2026)
-- --------------------------------------------------------------------

-- Step 1A: Calculate total order volume and net revenue lift across groups
-- Failsafe: Replaced 'BETWEEN' boundary with an explicit inequality filter
-- to avoid cutting off transactions on the final 24 hours of March 31st.
SELECT 
    r.spring_refill_group,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.net_amount) AS total_net_revenue,
    AVG(o.net_amount) AS average_order_value,
    COUNT(DISTINCT o.customer_id) AS unique_customers
FROM orders o
JOIN regions r ON o.region = r.region
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'completed'         
  AND c.is_internal = FALSE          
  AND o.order_ts >= '2026-03-01'     
  AND o.order_ts < '2026-04-01'      
GROUP BY r.spring_refill_group;

-- Step 1B: Extract exact ad spend for the promotion campaigns
SELECT 
    campaign_name,
    SUM(spend) AS total_spend
FROM ad_spend
WHERE campaign_name LIKE '%Spring Refill promo%'
GROUP BY campaign_name;


-- --------------------------------------------------------------------
-- QUESTION 2: LONGITUDINAL COHORT RETENTION & CHURN DRIVERS
-- --------------------------------------------------------------------

-- Query 2A: Calculate monthly 90-day repeat purchase rate
-- Failsafe: Fixed date boundaries to prevent right-censoring artifacts.
-- Enforced an explicit date delta flag (> first_order_date) to prevent 
-- same-day basket splitting from skewing customer loyalty metrics.
WITH first_orders AS (
    SELECT 
        o.customer_id,
        o.order_id AS first_order_id,
        o.order_ts AS first_order_ts,
        CAST(o.order_ts AS DATE) AS first_order_date,
        DATE_TRUNC('month', CAST(o.order_ts AS DATE)) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.status = 'completed'         
      AND c.is_internal = FALSE          
      AND CAST(o.order_ts AS DATE) BETWEEN '2025-01-01' AND '2026-03-31'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_ts ASC) = 1
),
repeat_customers AS (
    SELECT DISTINCT 
        fo.customer_id
    FROM first_orders fo
    JOIN orders o ON fo.customer_id = o.customer_id
    WHERE o.status = 'completed'
      AND CAST(o.order_ts AS DATE) > fo.first_order_date 
      AND CAST(o.order_ts AS DATE) <= fo.first_order_date + INTERVAL 90 DAY 
)
SELECT 
    f.cohort_month,
    COUNT(DISTINCT f.customer_id) AS new_customer_count,
    COUNT(DISTINCT r.customer_id) AS repeat_customer_count,
    ROUND(COUNT(DISTINCT r.customer_id) * 100.0 / COUNT(DISTINCT f.customer_id), 2) AS repeat_rate_pct
FROM first_orders f
LEFT JOIN repeat_customers r ON f.customer_id = r.customer_id
GROUP BY f.cohort_month
ORDER BY f.cohort_month ASC;

-- Query 2B: Segment 90-day retention by Acquisition Channel
WITH first_orders AS (
    SELECT 
        o.customer_id,
        CAST(o.order_ts AS DATE) AS first_order_date,
        c.acquisition_channel
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.status = 'completed'         
      AND c.is_internal = FALSE          
      AND CAST(o.order_ts AS DATE) BETWEEN '2025-01-01' AND '2026-03-31'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_ts ASC) = 1
),
repeat_customers AS (
    SELECT DISTINCT 
        fo.customer_id
    FROM first_orders fo
    JOIN orders o ON fo.customer_id = o.customer_id
    WHERE o.status = 'completed'
      AND CAST(o.order_ts AS DATE) > fo.first_order_date 
      AND CAST(o.order_ts AS DATE) <= fo.first_order_date + INTERVAL 90 DAY 
)
SELECT 
    f.acquisition_channel,
    COUNT(DISTINCT f.customer_id) AS new_customers,
    COUNT(DISTINCT r.customer_id) AS repeat_customers,
    ROUND(COUNT(DISTINCT r.customer_id) * 100.0 / COUNT(DISTINCT f.customer_id), 2) AS repeat_rate_pct
FROM first_orders f
LEFT JOIN repeat_customers r ON f.customer_id = r.customer_id
GROUP BY f.acquisition_channel
ORDER BY repeat_rate_pct DESC;

-- Query 2C: Segment 90-day retention by Product Category Entry-Point
WITH first_orders AS (
    SELECT 
        o.customer_id,
        CAST(o.order_ts AS DATE) AS first_order_date,
        c.first_order_category
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.status = 'completed'         
      AND c.is_internal = FALSE          
      AND CAST(o.order_ts AS DATE) BETWEEN '2025-01-01' AND '2026-03-31'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_ts ASC) = 1
),
repeat_customers AS (
    SELECT DISTINCT 
        fo.customer_id
    FROM first_orders fo
    JOIN orders o ON fo.customer_id = o.customer_id
    WHERE o.status = 'completed'
      AND CAST(o.order_ts AS DATE) > fo.first_order_date 
      AND CAST(o.order_ts AS DATE) <= fo.first_order_date + INTERVAL 90 DAY 
)
SELECT 
    f.first_order_category,
    COUNT(DISTINCT f.customer_id) AS new_customers,
    COUNT(DISTINCT r.customer_id) AS repeat_customers,
    ROUND(COUNT(DISTINCT r.customer_id) * 100.0 / COUNT(DISTINCT f.customer_id), 2) AS repeat_rate_pct
FROM first_orders f
LEFT JOIN repeat_customers r ON f.customer_id = r.customer_id
GROUP BY f.first_order_category
ORDER BY repeat_rate_pct DESC;


-- --------------------------------------------------------------------
-- QUESTION 3: TRAILING QUARTER MARKETING SPEND AUDIT (Q2 2026)
-- --------------------------------------------------------------------

-- Aggregate historical spend mix and cost-efficiency benchmarks
-- Failsafe: Integrated 'NULLIF' to prevent zero-division query failures
-- on zero-cost or organic non-paid transactional rows.
SELECT 
    channel,
    ROUND(SUM(spend), 2) AS total_spend,
    SUM(clicks) AS total_clicks,
    SUM(impressions) AS total_impressions,
    ROUND(SUM(spend) / NULLIF(SUM(clicks), 0), 2) AS cost_per_click
FROM ad_spend
WHERE date >= '2026-04-01' 
  AND date <= '2026-06-30'
GROUP BY channel
ORDER BY total_spend DESC;
