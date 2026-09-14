-- Total Orders
SELECT COUNT(*) AS total_orders
FROM orders;

-- Total Customers
SELECT COUNT(*) AS total_customers
FROM customers;

-- Total Products
SELECT COUNT(*) AS total_products
FROM products;

-- Total Sellers
SELECT COUNT(*) AS total_sellers
FROM sellers;

-- Total Items Sold
SELECT COUNT(*) AS total_items
FROM order_items;

-- Revenue
SELECT ROUND(SUM(price), 2) AS total_revenue
FROM order_items;

-- Average Order Value
SELECT ROUND(
    SUM(price) / COUNT(DISTINCT order_id),
    2
) AS average_order_value
FROM order_items;

-- Gross Merchandise Value (GMV)
SELECT ROUND(SUM(price + freight_value), 2) AS gmv
FROM order_items;

-- Average Order Value (GMV-based)
SELECT ROUND(
    SUM(price + freight_value) / COUNT(DISTINCT order_id),
    2
) AS average_order_value
FROM order_items;

-- Monthly Sales Trend
SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_gmv,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gmv,
    COUNT(DISTINCT oi.order_id) AS orders,
    COUNT(*) AS items_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY category
ORDER BY gmv DESC
LIMIT 15;

-- Payment Method Analysis
SELECT
    payment_type,
    COUNT(*) AS payment_count,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment_value
FROM payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- Customer Purchase Frequency
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS repeat_customer_rate
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
);

-- Customer Revenue Analysis
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_spend,
    ROUND(
        SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id),
        2
    ) AS customer_aov
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spend DESC
LIMIT 10;

-- Seller Performance Analysis
SELECT
    s.seller_id,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_id
ORDER BY total_sales DESC
LIMIT 10;

-- Review Performance Analysis
SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS review_percentage
FROM reviews
GROUP BY review_score
ORDER BY review_score;

-- Delivery Performance Analysis
SELECT
    CASE
        WHEN order_delivered_customer_date IS NULL THEN 'Not Delivered'
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM orders
GROUP BY delivery_status
ORDER BY total_orders DESC;

-- Delivery Delay Analysis
SELECT
    ROUND(AVG(
        julianday(order_delivered_customer_date)
        - julianday(order_estimated_delivery_date)
    ), 2) AS avg_delay_days,
    
    ROUND(MAX(
        julianday(order_delivered_customer_date)
        - julianday(order_estimated_delivery_date)
    ), 2) AS max_delay_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND order_delivered_customer_date > order_estimated_delivery_date;

-- Delivery Performance vs Customer Satisfaction
SELECT
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN 'Not Delivered'
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(r.review_id) AS total_reviews
FROM orders o
JOIN reviews r
    ON o.order_id = r.order_id
GROUP BY delivery_status
ORDER BY avg_review_score DESC;