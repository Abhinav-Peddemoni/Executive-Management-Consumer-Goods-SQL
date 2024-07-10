-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT DISTINCT market FROM dim_customer
WHERE customer LIKE "Atliq Exclusive" AND region LIKE "APAC";

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? 
WITH CTE AS(
SELECT 
(SELECT COUNT(DISTINCT(product_code)) FROM fact_manufacturing_cost
WHERE cost_year = 2020) AS unique_products_2020,
(SELECT COUNT(DISTINCT(product_code)) AS unique_products_2021 FROM fact_manufacturing_cost
WHERE cost_year = 2021) AS unique_products_2021)
SELECT *, CONCAT(ROUND((unique_products_2021-unique_products_2020)/unique_products_2020*100,2),'%') AS percentage_chg FROM CTE;

-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
SELECT segment, COUNT(product_code) AS product_count FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
WITH CTE AS 
(
SELECT a.segment, COUNT(DISTINCT CASE WHEN b.cost_year = 2020 THEN b.product_code END) AS unique_products_2020, COUNT(DISTINCT CASE WHEN b.cost_year = 2021 THEN b.product_code END) AS unique_products_2021
FROM dim_product a 
INNER JOIN fact_manufacturing_cost b 
USING(product_code)
GROUP BY a.segment
)
SELECT *, unique_products_2021 - unique_products_2020 AS new_products_introduced FROM CTE;

-- 5. Get the products that have the highest and lowest manufacturing costs.
WITH CTE AS
(
SELECT product_code, manufacturing_cost FROM fact_manufacturing_cost
WHERE manufacturing_cost = (SELECT max(manufacturing_cost) FROM fact_manufacturing_cost) 
OR manufacturing_cost = (SELECT min(manufacturing_cost) FROM fact_manufacturing_cost)
)
SELECT a.product_code, b.product, b.variant, a.manufacturing_cost FROM CTE a
INNER JOIN dim_product b
USING(product_code);


-- 6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
SELECT a.customer_code,b.customer, a.pre_invoice_discount_pct*100 AS average_discount_percentage  FROM fact_pre_invoice_deductions a
INNER JOIN dim_customer b
USING(customer_code)
WHERE b.market LIKE "india" AND fiscal_year = 2021
ORDER BY pre_invoice_discount_pct DESC
LIMIT 5;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month .
SELECT MONTHNAME(fsm.date) AS Month,
YEAR(fsm.date) AS Year,
ROUND(SUM(gross_price*sold_quantity),0) AS "Gross_Sales"
FROM fact_gross_price fgp
JOIN fact_sales_monthly fsm
USING (product_code)
JOIN dim_customer dc
USING (customer_code)
WHERE customer = "Atliq Exclusive"
GROUP BY MONTH, YEAR
ORDER BY Year, Month(Month) DESC;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity?
WITH CTE AS 
(
SELECT date,
CASE WHEN MONTH(date) IN (9,10,11) THEN "1st Quarter"
     WHEN MONTH(date) IN (12,1,2) THEN "2nd Quarter"
     WHEN MONTH(date) IN (3,4,5) THEN "3rd Quarter"
     ELSE "4th Quarter" END AS "Quarter", sold_quantity
 FROM fact_sales_monthly
 WHERE fiscal_year = 2020
 )
 SELECT Quarter, SUM(sold_quantity) AS total_quantity_sold FROM CTE
 GROUP BY Quarter
 ORDER BY total_quantity_sold DESC;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
WITH CTE AS 
 (
 SELECT c.channel, ROUND(SUM(a.sold_quantity*b.gross_price),0) AS gross_sales FROM fact_sales_monthly a 
 INNER JOIN fact_gross_price b
 ON a.product_code = b.product_code
 INNER JOIN dim_customer c 
 ON c.customer_code = a.customer_code
 WHERE a.fiscal_year = 2021
 GROUP BY c.channel
 )
 SELECT *, CONCAT(ROUND((gross_sales/(SELECT SUM(gross_sales) FROM CTE))*100,0), " %") AS contribution FROM CTE;

-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
WITH CTE AS(
SELECT a.division, b.product_code, a.product, SUM(b.sold_quantity) AS total_sold_quantity, 
RANK() OVER(PARTITION BY division ORDER BY SUM(b.sold_quantity) DESC) AS rank_order FROM dim_product a 
INNER JOIN fact_sales_monthly b
USING(product_code)
WHERE fiscal_year = 2021
GROUP BY a.division, b.product_code, a.product)
SELECT * FROM CTE
WHERE rank_order < 4;


