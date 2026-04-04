WITH monthly_segment_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        c.segment,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY
        DATE_TRUNC('month', o.order_date),
        c.segment
)
SELECT
    month,
    segment,
    revenue,
    LAG(revenue) OVER (
        PARTITION BY segment
        ORDER BY month
    ) AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (
            PARTITION BY segment
            ORDER BY month
        ))
        / NULLIF(LAG(revenue) OVER (
            PARTITION BY segment
            ORDER BY month
        ), 0),
        2
    ) AS mom_growth_pct,
    SUM(revenue) OVER (
        PARTITION BY segment
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_revenue
FROM monthly_segment_revenue
ORDER BY month, segment;

WITH monthly_category_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        p.category,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status <> 'cancelled'
    GROUP BY
        DATE_TRUNC('month', o.order_date),
        p.category
)
SELECT
    month,
    category,
    revenue,
    ROUND(
        100.0 * revenue / NULLIF(SUM(revenue) OVER (PARTITION BY month), 0),
        2
    ) AS revenue_share_pct,
    ROUND(
        AVG(revenue) OVER (
            PARTITION BY category
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS revenue_ma_3m,
    LAG(revenue) OVER (
        PARTITION BY category
        ORDER BY month
    ) AS prev_month_revenue
FROM monthly_category_revenue
ORDER BY month, category;