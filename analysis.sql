-------
--CAMPAIGN 301--
-------


---CHECK VALUE---
SELECT * FROM campaign
SELECT * FROM transactions
SELECT * FROM campaign_metrics


---CHECK ENGAGEMENT METRICS---
SELECT 
    cm.campaign_id, 
    cm.Clicks, 
    cm.Impressions, 
    SUM(t.amount) AS total_sales
FROM campaign_metrics cm
LEFT JOIN transactions t 
ON cm.campaign_id = t.campaign_id
GROUP BY cm.campaign_id, cm.Clicks, cm.Impressions;


---FIND CPC AND ROI---
SELECT 
    c.campaign_id,
    c.budget,
    cm.Clicks,
    (c.budget * 1.0 / cm.Clicks)::NUMERIC(10,2) AS CPC,
    ((SUM(t.amount) - c.budget) * 1.0 / c.budget)::NUMERIC(10,2) AS ROI
FROM campaigns c
LEFT JOIN campaign_metrics cm 
ON c.campaign_id = cm.campaign_id
LEFT JOIN transactions t 
ON c.campaign_id = t.campaign_id
WHERE c.campaign_id = 301
GROUP BY c.campaign_id, c.budget, cm.Clicks;


---FIND BOUNCE RATE---
SELECT 
    c.campaign_id, 
    cm.impressions, 
    cm.website_landing_hits,
    (1 - cm.website_landing_hits * 1.0 / cm.impressions)::NUMERIC(10,3) AS bounce_rate
FROM campaigns c
LEFT JOIN campaign_metrics cm 
ON c.campaign_id = cm.campaign_id
WHERE c.campaign_id = 301;


---CUSTOMER SEGMENTATION---
WITH customer_transactions AS (
    SELECT 
        customer_id,
        campaign_id,
        COUNT(transaction_id) AS transaction_count
    FROM transactions 
    WHERE campaign_id = 301
    GROUP BY customer_id, campaign_id
)
SELECT 
    CASE
        WHEN transaction_count > 1 THEN 'Repeat'
        ELSE 'New'
    END AS customer_type,
    COUNT(*) AS customer_count
FROM customer_transactions
GROUP BY customer_type;


---DISTRIBUTION OF PRODUCT CATEGORY---
SELECT 
    product_category, 
    COUNT(transaction_id) AS transaction_count, 
    SUM(amount) AS total_sales
FROM transactions 
WHERE campaign_id = 301
GROUP BY product_category
ORDER BY total_sales DESC;


---CUSTOMER DEMOGRAPHIC---
SELECT 
    gender, 
    FLOOR(age / 10) * 10 AS age_group, 
    COUNT(transaction_id) AS transaction_count, 
    SUM(amount) AS total_sales
FROM transactions
WHERE campaign_id = 301
GROUP BY gender, age_group
ORDER BY total_sales DESC;


---CUSTOMER AGE GROUP, CAC, AND SALES---
WITH customer_data AS (
    SELECT 
        campaign_id, 
        COUNT(DISTINCT customer_id) AS customers_acquired, 
        SUM(amount) AS total_sales
    FROM transactions 
    WHERE campaign_id = 301
    GROUP BY campaign_id
)
SELECT 
    t.gender, 
    FLOOR(t.age / 10) * 10 AS age_group, 
    COUNT(t.transaction_id) AS transaction_count, 
    SUM(t.amount) AS total_sales, 
    (c.budget / cd.customers_acquired) AS customer_acquisition_cost
FROM transactions t
LEFT JOIN campaigns c 
ON t.campaign_id = c.campaign_id
LEFT JOIN customer_data cd 
ON t.campaign_id = cd.campaign_id
WHERE t.campaign_id = 301
GROUP BY t.gender, age_group, c.budget, cd.customers_acquired
ORDER BY total_sales DESC;