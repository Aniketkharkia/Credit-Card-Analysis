
-- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends

SELECT city,
       SUM(amount) AS total_city_spends,
       ROUND((SUM(amount) / (SELECT SUM(c1.amount) FROM credit_card_transactions c1)) * 100, 2) AS spend_percentage
FROM credit_card_transactions
GROUP BY city
ORDER BY total_city_spends DESC
LIMIT 5;



-- write a query to print highest spend month and amount in that month for each card type 

WITH transactions AS (
    SELECT
        card_type,
        YEAR(transaction_date) AS ty,
        MONTH(transaction_date) AS tm,
        SUM(amount) AS total_spend
    FROM credit_card_transactions
    GROUP BY card_type, YEAR(transaction_date), MONTH(transaction_date)
), 
type_rank AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY card_type ORDER BY total_spend DESC) AS rnk
    FROM transactions
)
SELECT *
FROM type_rank
WHERE rnk = 1;



-- write a query to print the transactio details (all columns from the table) for each card type when it reaches a cumulative of 1000000
-- total spends (We should have 4 rows in the o/p one for each card type)

WITH cumulative_amount AS (
    SELECT
        *,
        SUM(amount) OVER (
            PARTITION BY card_type
            ORDER BY transaction_date, transaction_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS total_spend
    FROM credit_card_transactions
)
SELECT *
FROM (
    SELECT
        *,
        RANK() OVER (PARTITION BY card_type ORDER BY total_spend) AS rn
    FROM cumulative_amount
    WHERE total_spend >= 1000000
) AS cumulative_spend
WHERE rn = 1;


-- write a query to find city which had lowest percentage spend for gold card type


SELECT city,
       SUM(amount) AS total_spend,
       ROUND(
           (SUM(amount) / (SELECT SUM(amount) FROM credit_card_transactions WHERE card_type = 'Gold')) * 100,
           5
       ) AS percentage
FROM credit_card_transactions
WHERE card_type = 'Gold'
GROUP BY city
ORDER BY total_spend;


-- write a query to find print 3 columns: city, highest expense type, lowest_expense_type (example format : Delhi, bills, Fuel)


WITH total_transactions AS (
    SELECT
        city,
        exp_type,
        SUM(amount) AS total_amount
    FROM credit_card_transactions
    GROUP BY city, exp_type
),
city_rank AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY city ORDER BY total_amount DESC) AS rn_desc,
        RANK() OVER (PARTITION BY city ORDER BY total_amount ASC) AS rn_asc
    FROM total_transactions
)
SELECT
    city,
    MAX(CASE WHEN rn_asc = 1 THEN exp_type END) AS lowest_exp_type,
    MIN(CASE WHEN rn_desc = 1 THEN exp_type END) AS highest_exp_type
FROM city_rank
GROUP BY city;



-- What is the percentage of total spend by females and males for each expense type, along with the total spend amount
SELECT 
    *, 
    ROUND((female_spend / total_spend) * 100, 2) AS female_spend_Pct, 
    total_spend - female_spend AS male_spend,
    100 - ROUND((female_spend / total_spend) * 100, 2) AS male_spend_Pct
FROM (
    SELECT
        exp_type,
        SUM(amount) AS total_spend,
        SUM(CASE WHEN gender = 'F' THEN amount ELSE 0 END) AS female_spend
    FROM credit_card_transactions
    GROUP BY exp_type
) AS female_spend_analysis
ORDER BY total_spend DESC;



-- which card and expense type combination saw highest month over month gowth in Jan-2024
-- order by growth percentage
WITH year_month_transactions AS (
    SELECT
        card_type,
        exp_type,
        SUM(amount) AS total_spend,
        YEAR(transaction_date) AS ty,
        MONTH(transaction_date) AS tm
    FROM credit_card_transactions
    GROUP BY card_type, exp_type, YEAR(transaction_date), MONTH(transaction_date)
),
prev_month AS (
    SELECT
        *,
        LAG(total_spend, 1) OVER (
            PARTITION BY card_type, exp_type
            ORDER BY ty, tm
        ) AS prev_spend
    FROM year_month_transactions
)
SELECT
    *,
    (total_spend - prev_spend) AS growth_in_spend,
    ROUND(((total_spend - prev_spend) / prev_spend) * 100, 2) AS growth_percentage
FROM prev_month
WHERE prev_spend IS NOT NULL AND ty = 2014 AND tm = 1
ORDER BY growth_percentage DESC
LIMIT 1;


-- order by growth in spend amount
WITH year_month_transactions AS (
    SELECT
        card_type,
        exp_type,
        SUM(amount) AS total_spend,
        YEAR(transaction_date) AS ty,
        MONTH(transaction_date) AS tm
    FROM credit_card_transactions
    GROUP BY card_type, exp_type, YEAR(transaction_date), MONTH(transaction_date)
),
prev_month AS (
    SELECT
        *,
        LAG(total_spend, 1) OVER (
            PARTITION BY card_type, exp_type
            ORDER BY ty, tm
        ) AS prev_spend
    FROM year_month_transactions
)
SELECT
    *,
    (total_spend - prev_spend) AS growth_in_spend,
    ROUND(((total_spend - prev_spend) / prev_spend) * 100, 2) AS growth_percentage
FROM prev_month
WHERE prev_spend IS NOT NULL AND ty = 2014 AND tm = 1
ORDER BY growth_in_spend DESC
LIMIT 1;


-- during weekends which city has highest avg spend 
SELECT
    city,
    SUM(amount) AS total_spend,
    COUNT(*) AS no_of_transaction,
    FLOOR(AVG(amount)) AS transaction_ratio
FROM credit_card_transactions
WHERE DAYOFWEEK(transaction_date) IN (1, 7)
GROUP BY city
ORDER BY transaction_ratio DESC
LIMIT 1;


-- during weekends cities which has highest avg spend with more than 200 transaction records

SELECT
    city,
    SUM(amount) AS total_spend,
    COUNT(*) AS no_of_transaction,
    FLOOR(AVG(amount)) AS transaction_ratio
FROM credit_card_transactions
WHERE DAYOFWEEK(transaction_date) IN (1, 7)
GROUP BY city
HAVING COUNT(*) > 200
ORDER BY transaction_ratio DESC;

-- which city took least number of days to reach it's 500th transaction after the first transaction in that city

WITH rn_cte AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY transaction_date) AS rn
    FROM credit_card_transactions
)
SELECT
    city,
    DATEDIFF(MAX(transaction_date), MIN(transaction_date)) AS no_of_days
FROM rn_cte
WHERE rn = 1 OR rn = 500
GROUP BY city
HAVING COUNT(*) = 2
ORDER BY no_of_days;




-- What is the total spend for each card type, ranked in descending order
SELECT card_type, SUM(amount) AS total_spend
FROM credit_card_transactions
GROUP BY card_type
ORDER BY total_spend DESC;


-- total spend by each city
SELECT city, SUM(amount) AS total_spend
FROM credit_card_transactions
GROUP BY city
ORDER BY total_spend DESC;

















