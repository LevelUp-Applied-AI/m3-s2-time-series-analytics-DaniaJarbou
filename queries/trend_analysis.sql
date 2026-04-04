WITH daily_metrics AS (
    SELECT
        DATE(o.order_date) AS day,
        SUM(oi.quantity * oi.unit_price) AS revenue,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY DATE(o.order_date)
)
SELECT
    day,
    revenue,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS revenue_ma_7d,
    ROUND(
        AVG(revenue) OVER (
            ORDER BY day
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ), 2
    ) AS revenue_ma_30d,
    order_count,
    ROUND(
        AVG(order_count) OVER (
            ORDER BY day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS orders_ma_7d
FROM daily_metrics
ORDER BY day;