create database walmart

use walmart
-- Walmart Project Queries - SQL Server

-- View all data
SELECT * FROM dbo.walmart;

-- Drop Table (Use with Caution)
-- DROP TABLE dbo.walmart;

-- Count total records
SELECT COUNT(*) AS TotalRecords FROM dbo.walmart;

-- Count transactions by payment method
SELECT 
    payment_method, 
    COUNT(*) AS no_payments
FROM dbo.walmart
GROUP BY payment_method;

-- Count distinct branches
SELECT COUNT(DISTINCT branch) AS TotalBranches FROM dbo.walmart;

-- Find the minimum quantity sold
SELECT MIN(quantity) AS MinQuantity FROM dbo.walmart;

-- Find different payment methods, number of transactions, and quantity sold by payment method
SELECT 
    payment_method, 
    COUNT(*) AS no_payments, 
    SUM(quantity) AS total_qty_sold
FROM dbo.walmart
GROUP BY payment_method;

-- Find the highest-rated category per branch
WITH Ranked AS (
    SELECT 
        branch, 
        category, 
        AVG(rating) AS avg_rating,
        RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank
    FROM dbo.walmart
    GROUP BY branch, category
)
SELECT branch, category, avg_rating
FROM Ranked
WHERE rank = 1;

-- Find the busiest day for each branch based on transactions
WITH Ranked AS (
    SELECT 
        branch, 
        DATENAME(WEEKDAY, CONVERT(DATE, date, 103)) AS day_name, -- Convert string to DATE
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM dbo.walmart
    GROUP BY branch, DATENAME(WEEKDAY, CONVERT(DATE, date, 103))
)
SELECT branch, day_name, no_transactions
FROM Ranked
WHERE rank = 1;


-- Calculate the total quantity of items sold per payment method
SELECT 
    payment_method, 
    SUM(quantity) AS total_qty_sold
FROM dbo.walmart
GROUP BY payment_method;

-- Determine the average, minimum, and maximum rating of categories for each city
SELECT 
    city, 
    category, 
    MIN(rating) AS min_rating, 
    MAX(rating) AS max_rating, 
    AVG(rating) AS avg_rating
FROM dbo.walmart
GROUP BY city, category;

-- Calculate the total profit for each category
SELECT 
    category, 
    SUM(unit_price * quantity * profit_margin) AS total_profit
FROM dbo.walmart
GROUP BY category
ORDER BY total_profit DESC;

-- Determine the most common payment method for each branch
WITH CTE AS (
    SELECT 
        branch, 
        payment_method, 
        COUNT(*) AS total_trans, 
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM dbo.walmart
    GROUP BY branch, payment_method
)
SELECT branch, payment_method AS preferred_payment_method
FROM CTE
WHERE rank = 1;

-- Categorize sales into shifts (Morning, Afternoon, Evening)
SELECT 
    branch, 
    CASE 
        WHEN DATEPART(HOUR, CAST(time AS TIME)) < 12 THEN 'Morning'
        WHEN DATEPART(HOUR, CAST(time AS TIME)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift, 
    COUNT(*) AS num_invoices
FROM dbo.walmart
GROUP BY branch, 
    CASE 
        WHEN DATEPART(HOUR, CAST(time AS TIME)) < 12 THEN 'Morning'
        WHEN DATEPART(HOUR, CAST(time AS TIME)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END
ORDER BY branch, num_invoices DESC;

-- Identify the 5 branches with the highest revenue decrease ratio from last year to current year
WITH revenue_2022 AS (
    SELECT 
        branch, 
        SUM(total) AS revenue
    FROM dbo.walmart
    WHERE YEAR(CAST(date AS DATE)) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT 
        branch, 
        SUM(total) AS revenue
    FROM dbo.walmart
    WHERE YEAR(CAST(date AS DATE)) = 2023
    GROUP BY branch
)
SELECT 
    r2022.branch, 
    r2022.revenue AS last_year_revenue, 
    r2023.revenue AS current_year_revenue, 
    ROUND(((r2022.revenue - r2023.revenue) / NULLIF(r2022.revenue, 0)) * 100, 2) AS revenue_decrease_ratio
FROM revenue_2022 AS r2022
JOIN revenue_2023 AS r2023 ON r2022.branch = r2023.branch
WHERE r2022.revenue > r2023.revenue
ORDER BY revenue_decrease_ratio DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
