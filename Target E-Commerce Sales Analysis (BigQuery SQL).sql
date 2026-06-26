--Target E-Commerce Sales Analysis (BigQuery SQL)
--1. Data Import & Exploratory Data Analysis (EDA)
--1.1 Preview the Customers Table

SELECT *
FROM `TargetsalesAnalysis.Customers`
LIMIT 10;

--1.2 Preview the Orders Table

SELECT *
FROM `TargetsalesAnalysis.Orders`
LIMIT 5;

--1.3 Find the Time Range of Orders

SELECT
    MIN(order_purchase_timestamp) AS start_time,
    MAX(order_purchase_timestamp) AS end_time
FROM `TargetsalesAnalysis.Orders`;

--1.4 Display Cities & States of Customers Who Ordered During Jan–Mar 2018

SELECT
    c.customer_city,
    c.customer_state
FROM `TargetsalesAnalysis.Customers` AS c
JOIN `TargetsalesAnalysis.Orders` AS o
    ON c.customer_id = o.customer_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
  AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 3;

--2. In-Depth Exploration
--2.1 Year-wise Growth in Number of Orders

SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    COUNT(order_id) AS total_orders
FROM `TargetsalesAnalysis.Orders`
GROUP BY year
ORDER BY year;

--2.2 Monthly Seasonality of Orders

SELECT
    EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
    COUNT(order_id) AS order_count
FROM `TargetsalesAnalysis.Orders`
GROUP BY month
ORDER BY month;

--2.3 Time of Day When Customers Place Orders

SELECT
    EXTRACT(HOUR FROM order_purchase_timestamp) AS hour,
    COUNT(order_id) AS total_orders
FROM `TargetsalesAnalysis.Orders`
GROUP BY hour
ORDER BY hour;

--3. Evolution of E-Commerce Orders in Brazil
--3.1 Month-on-Month Orders

SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
    COUNT(*) AS total_orders
FROM `TargetsalesAnalysis.Orders`
GROUP BY year, month
ORDER BY year, month;

--3.2 Customer Distribution Across States

SELECT
    customer_state,
    COUNT(DISTINCT customer_id) AS customer_count
FROM `TargetsalesAnalysis.Customers`
GROUP BY customer_state
ORDER BY customer_count DESC;

--4. Impact on Economy
--4.1 Percentage Increase in Order Cost (Jan–Aug 2017 vs 2018)

WITH yearly_totals AS (

    SELECT
        EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
        SUM(p.payment_value) AS total_payment
    FROM `TargetsalesAnalysis.Payment` AS p
    JOIN `TargetsalesAnalysis.Orders` AS o
        ON p.order_id = o.order_id
    WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
      AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY year

),

yearly_comparisons AS (

    SELECT
        year,
        total_payment,
        LEAD(total_payment) OVER (ORDER BY year DESC) AS previous_year_payment
    FROM yearly_totals

)

SELECT
    ROUND(
        ((total_payment - previous_year_payment) / previous_year_payment) * 100,
        2
    ) AS percentage_increase
FROM yearly_comparisons;

--4.2 Average & Total Price and Freight by State

SELECT
    c.customer_state,

    ROUND(AVG(oi.price), 2) AS avg_price,
    ROUND(SUM(oi.price), 2) AS total_price,

    ROUND(AVG(oi.freight_value), 2) AS avg_freight,
    ROUND(SUM(oi.freight_value), 2) AS total_freight

FROM `TargetsalesAnalysis.Orders` AS o

JOIN `TargetsalesAnalysis.Orders_items` AS oi
    ON o.order_id = oi.order_id

JOIN `TargetsalesAnalysis.Customers` AS c
    ON o.customer_id = c.customer_id

GROUP BY c.customer_state

ORDER BY total_price DESC;

--5. Sales, Freight & Delivery Analysis
--5.1 Delivery Time & Estimated Delivery Difference

SELECT
    order_id,

    DATE_DIFF(
        DATE(order_delivered_customer_date),
        DATE(order_purchase_timestamp),
        DAY
    ) AS days_to_delivery,

    DATE_DIFF(
        DATE(order_delivered_customer_date),
        DATE(order_estimated_delivery_date),
        DAY
    ) AS estimated_delivery_difference

FROM `TargetsalesAnalysis.Orders`;

--5.2 Top 5 States with Highest Average Freight Value

SELECT
    c.customer_state,
    AVG(oi.freight_value) AS avg_freight
FROM `TargetsalesAnalysis.Customers` AS c

JOIN `TargetsalesAnalysis.Orders` AS o
    ON c.customer_id = o.customer_id

JOIN `TargetsalesAnalysis.Orders_items` AS oi
    ON o.order_id = oi.order_id

GROUP BY c.customer_state

ORDER BY avg_freight DESC

LIMIT 5;

--5.3 Top 5 States with Highest Average Delivery Time

SELECT
    c.customer_state,

    AVG(
        DATE_DIFF(
            DATE(o.order_delivered_customer_date),
            DATE(o.order_purchase_timestamp),
            DAY
        )
    ) AS avg_delivery_time

FROM `TargetsalesAnalysis.Customers` AS c

JOIN `TargetsalesAnalysis.Orders` AS o
    ON c.customer_id = o.customer_id

GROUP BY c.customer_state

ORDER BY avg_delivery_time DESC

LIMIT 5;

--5.4 Top 5 States Where Deliveries Were Earlier Than Estimated

SELECT
    c.customer_state,

    ROUND(
        AVG(
            DATE_DIFF(
                DATE(o.order_estimated_delivery_date),
                DATE(o.order_delivered_customer_date),
                DAY
            )
        ),
        2
    ) AS avg_days_early

FROM `TargetsalesAnalysis.Customers` AS c

JOIN `TargetsalesAnalysis.Orders` AS o
    ON c.customer_id = o.customer_id

WHERE o.order_delivered_customer_date IS NOT NULL

GROUP BY c.customer_state

ORDER BY avg_days_early DESC

LIMIT 5;

--6. Payment Analysis
--6.1 Month-on-Month Orders by Payment Type

SELECT
    p.payment_type,

    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,

    COUNT(DISTINCT o.order_id) AS total_orders

FROM `TargetsalesAnalysis.Orders` AS o

JOIN `TargetsalesAnalysis.Payment` AS p
    ON o.order_id = p.order_id

GROUP BY
    payment_type,
    year,
    month

ORDER BY
    payment_type,
    year,
    month;

--6.2 Orders by Number of Payment Installments

SELECT
    payment_installments,
    COUNT(DISTINCT order_id) AS total_orders
FROM `TargetsalesAnalysis.Payment`
GROUP BY payment_installments
ORDER BY payment_installments;