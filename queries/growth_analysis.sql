WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        COUNT(DISTINCT o.customer_id) AS unique_customers,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT
    month,
    unique_customers,
    order_count,
    revenue,
    ROUND(revenue / NULLIF(order_count, 0), 2) AS avg_order_value,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
        2
    ) AS mom_revenue_growth_pct,
    LAG(order_count) OVER (ORDER BY month) AS prev_month_orders,
    ROUND(
        100.0 * (order_count - LAG(order_count) OVER (ORDER BY month))
        / NULLIF(LAG(order_count) OVER (ORDER BY month), 0),
        2
    ) AS mom_order_growth_pct
FROM monthly_metrics
ORDER BY month;

WITH quarterly_revenue AS (
    SELECT
        DATE_TRUNC('quarter', o.order_date) AS quarter,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY DATE_TRUNC('quarter', o.order_date)
)
SELECT
    quarter,
    revenue,
    LAG(revenue) OVER (ORDER BY quarter) AS prev_quarter_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY quarter))
        / NULLIF(LAG(revenue) OVER (ORDER BY quarter), 0),
        2
    ) AS qoq_revenue_growth_pct
FROM quarterly_revenue
ORDER BY quarter;