# E-Commerce Consumer Analytics: 90-Day Retention Dynamics & Promotional ROI Optimization

## Executive Summary
This project delivers a comprehensive analytical audit of top-of-funnel customer acquisition, promotional marketing efficiency, and multi-cohort retention decay for **AuraGlow Organics**. Utilizing an optimized local column store environment (DuckDB), this analysis untangles conflicting performance signals from a recent sitewide discount campaign, establishes a baseline for long-term customer lifetime value (LTV), and provides a mathematically verified budget reallocation plan to eliminate capital inefficiencies.
---
## Strategic Business Discoveries

### 1. Promotional Lift & Media Campaign ROI (March 2026)
A deep-dive, matched-market evaluation was conducted to analyze the financial lift of the March 2026 20% discount campaign against a full-price holdout control group.
* **Test Group (20% Discount Active):** Generated $1,275,745.60 in net revenue across 17,233 completed orders, yielding an Average Order Value (AOV) of $74.03 from 15,848 unique customers.
* **Holdout Group (Full Price Control):** Generated $766,103.20 in net revenue across 8,746 completed orders, yielding an AOV of $87.59 from 8,334 unique customers.
* **Campaign Outlays:** Total direct media outflow reached $280,395.46, split between Paid Search ($154,486.40) and Paid Social ($125,909.06). Outlays were isolated dynamically using SQL string pattern-matching (`LIKE '%Spring Refill promo%'`).
* **Net Incremental Lift:** The promotional campaign delivered an incremental gain of +8,487 orders and +$509,642.40 in net revenue. Applying a 65% corporate gross margin rule, this yielded +$331,267.56 in incremental gross margin.
* **Bottom-Line Returns:** The campaign achieved +$50,872.10 in net campaign profit and a top-line marketing efficiency of 1.82x Incremental ROAS.

### 2. 90-Day Longitudinal Retention Decay (Jan 2025 – Mar 2026)
Longitudinal cohort analysis reveals a systemic structural degradation in user habit-loop formation over a 15-month timeline.
* **January 2025 Cohort (Historical Baseline):** 14,059 new signups | 5,328 repeaters | 37.90% repeat purchase rate.
* **December 2025 Cohort (Holiday Spike Degradation):** 13,165 new signups | 3,977 repeaters | 30.21% repeat purchase rate.
* **March 2026 Cohort (Promotion Influx Floor):** 13,952 new signups | 3,820 repeaters | 27.38% repeat purchase rate (All-time structural low).

### 3. Retention Variance Segmented by Acquisition Channel
Evaluating 90-day retention performance across specific channels isolates where toxic, discount-driven customer acquisition is driving retention down.
* **High-Intent Organic Engines:** Referral (42.66% repeat rate) and Organic Search (40.09% repeat rate).
* **Viable Paid Acquisition Funnels:** App Unattributed (38.33% repeat rate) and Paid Search (37.51% repeat rate).
* **Low-Intent Transient Funnels:** Paid Social (28.98% repeat rate) and Affiliate Networks (24.98% repeat rate).
* **Primary Churn Vector:** Influencer Marketing (12.98% repeat rate). This highlights a severe risk of acquiring single-purchase, discount-driven transaction volume rather than sticky, recurring lifetime users.

### 4. Retention Variance Segmented by Entry Product Category
To determine if product quality defects caused the retention drop, cohorts were isolated by their first-purchase item category:
* **Body:** 34.00% repeat rate
* **Cleansers:** 33.79% repeat rate
* **Refills:** 33.55% repeat rate
* **Moisturizers:** 33.47% repeat rate
* **Bundles:** 33.23% repeat rate
* **Serums:** 33.09% repeat rate
* **Strategic Evaluation:** Retention rates are completely flat across all lines with less than 1% variance. This uniform flatness mathematically disproves any product quality defect or operational fulfillment failure, isolating the issue entirely as an acquisition marketing mix anomaly.

---

## Trailing Quarter Spend Audit & Q2 Budget Realignment
To maximize capital efficiency, Q2 spending was optimized against a fixed $1,105,991.99 total capital ceiling using historical channel efficiencies:
* **Paid Search:** Scaled up to 45% ($497.6k) to protect stable, high-intent traffic streams (Historical baseline: $334.4k at $0.48 CPC).
* **Paid Social:** Maintained at 30% ($331.7k) to feed mid-funnel retargeting efforts (Historical baseline: $313.6k at $0.81 CPC).
* **Lifecycle Email Marketing:** Doubled to 15% ($165.8k) to directly counter customer churn using the database's lowest-cost reactivation click asset (Historical baseline: $110.0k at $0.04 CPC).
* **Influencer & Affiliate Networks:** Slashed by 60% down to a combined 10% ceiling ($110.5k) to eliminate severe budget leakage through low-retention channels (Historical baselines: Influencer at $272.8k / $1.55 CPC; Affiliate at $75.1k / $0.29 CPC).
---

## Defensive Engineering & Data Hygiene Guardrails

### 1. Timestamp Boundary Condition Filter
Standard scripts filter dates via `WHERE order_ts BETWEEN '2026-03-01' AND '2026-03-31'`. Because standalone date strings on TIMESTAMP columns expand to midnight (`00:00:00`), `BETWEEN` drops the final 24 hours of March 31st. This framework enforces:
```sql
WHERE o.order_ts >= '2026-03-01' AND o.order_ts < '2026-04-01'
```
This safely captures every transaction up to the final second of the month.

### 2. Same-Day Session Duplication Guardrail
Basic retention calculations check if `o.order_id != fo.first_order_id`. If a user places a secondary order 15 minutes after their first checkout to buy a forgotten item, ordinary scripts mistake them for a successfully "retained" customer. This model enforces an explicit calendar-date inequality constraint:
```sql
CAST(o.order_ts AS DATE) > fo.first_order_date
```
This isolates authentic multi-day habit loops from split cart sessions.

### 3. LEFT JOIN Null Fraction Count Safety
An ordinary `INNER JOIN` completely drops any consumer record that fails to place a secondary order, outputting an erroneous 100% repeat rate. This framework utilizes a `LEFT JOIN` to connect the baseline signup pool to returning customers, preserving non-returning users as `NULL` values. Because SQL's built-in `COUNT(column_name)` automatically skips `NULL` records, the fraction line cleanly tracks unique repeaters against the true size of the original cohort signup bucket.

### 4. Code Architecture Note
The underlying query is highly optimized for modern OLAP analytics. If you see visual red error highlights or linting squiggles beneath the `WITH` statement in tools like VS Code or SQL Workbench, this represents an artificial dialect mismatch, not a script error. Generic IDE database extensions evaluate code models using standard transactional rules (like PostgreSQL or MySQL) which fail to recognize modern analytic keywords such as DuckDB's native `QUALIFY` filter.
