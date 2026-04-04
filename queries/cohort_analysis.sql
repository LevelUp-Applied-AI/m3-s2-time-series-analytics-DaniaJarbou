WITH ranked_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date
        ) AS rn
    FROM orders o
    WHERE o.status <> 'cancelled'
),
first_purchase AS (
    SELECT
        customer_id,
        order_id AS first_order_id,
        order_date AS first_order_date,
        DATE_TRUNC('month', order_date) AS cohort_month
    FROM ranked_orders
    WHERE rn = 1
),
repeat_flags AS (
    SELECT
        fp.customer_id,
        fp.cohort_month,
        MAX(CASE
            WHEN o.order_date > fp.first_order_date
             AND o.order_date <= fp.first_order_date + INTERVAL '30 days'
            THEN 1 ELSE 0
        END) AS repeated_within_30d,
        MAX(CASE
            WHEN o.order_date > fp.first_order_date
             AND o.order_date <= fp.first_order_date + INTERVAL '60 days'
            THEN 1 ELSE 0
        END) AS repeated_within_60d,
        MAX(CASE
            WHEN o.order_date > fp.first_order_date
             AND o.order_date <= fp.first_order_date + INTERVAL '90 days'
            THEN 1 ELSE 0
        END) AS repeated_within_90d
    FROM first_purchase fp
    LEFT JOIN orders o
        ON fp.customer_id = o.customer_id
       AND o.status <> 'cancelled'
    GROUP BY fp.customer_id, fp.cohort_month
)
SELECT
    cohort_month,
    COUNT(*) AS cohort_size,
    ROUND(100.0 * AVG(repeated_within_30d), 2) AS retention_30d_pct,
    ROUND(100.0 * AVG(repeated_within_60d), 2) AS retention_60d_pct,
    ROUND(100.0 * AVG(repeated_within_90d), 2) AS retention_90d_pct
FROM repeat_flags
GROUP BY cohort_month
ORDER BY cohort_month;