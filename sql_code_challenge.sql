/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/

select market from gdb023.dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC'
group by market 
order by market ;


/*2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg*/


Select 
X.A AS unique_product_2020,
Y.B AS unique_product_2021,
round(( Y.B - X.A )* 100 / X.A ,2) AS percentage_chg
	
FROM      
(SELECT count(distinct product_code) AS A 
from gdb023.fact_sales_monthly
where fiscal_year =2020) X ,
 (SELECT count(distinct product_code) AS B 
from gdb023.fact_sales_monthly
where fiscal_year =2021) Y ;


/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/


select segment, count(distinct product_code) as product_count 
  from gdb023.dim_product
  group by segment
  order by product_count desc;
  
/* 4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/
       
with CTE1 AS 
( select P.segment as A, count(distinct(FS.product_code)) as B
from gdb023.dim_product P , gdb023.fact_sales_monthly FS 
where P.product_code = FS.product_code 
GROUP BY FS.fiscal_year, P.segment
    HAVING FS.fiscal_year = '2020'),
 
  CTE2 AS
( select P.segment as C, count(distinct(FS.product_code)) as D
from gdb023.dim_product P , gdb023.fact_sales_monthly FS 
where P.product_code = FS.product_code 
GROUP BY FS.fiscal_year, P.segment
    HAVING FS.fiscal_year = '2021')
    
  SELECT CTE1.A AS segment, CTE1.B AS product_count_2020, CTE2.D AS product_count_2021, (CTE2.D - CTE1.B) AS difference  
FROM CTE1, CTE2
WHERE CTE1.A = CTE2.C;  
    
/*5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost*/

SELECT F.product_code, P.product, F.manufacturing_cost 
FROM  gdb023.fact_manufacturing_cost F JOIN  gdb023.dim_product P
ON F.product_code = P.product_code
WHERE manufacturing_cost
IN (
	SELECT MAX(manufacturing_cost) FROM gdb023.fact_manufacturing_cost
    UNION
    SELECT MIN(manufacturing_cost) FROM gdb023.fact_manufacturing_cost
    ) 
ORDER BY manufacturing_cost DESC ;



/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/

WITH TBL1 AS
(SELECT customer_code AS A, AVG(pre_invoice_discount_pct) AS B FROM  gdb023.fact_pre_invoice_deductions
WHERE fiscal_year = '2021'
GROUP BY customer_code),
     TBL2 AS
(SELECT customer_code AS C, customer AS D FROM  gdb023.dim_customer
WHERE market = 'India')

SELECT TBL2.C AS customer_code, TBL2.D AS customer, ROUND (TBL1.B, 4) AS average_discount_percentage
FROM TBL1 JOIN TBL2
ON TBL1.A = TBL2.C
ORDER BY average_discount_percentage DESC
LIMIT 5;


/*7.Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount
*/


WITH temp_table AS (
    SELECT customer,
           monthname(date) AS months,
           month(date) AS month_number, 
           year(date) AS year,
           (sold_quantity * gross_price) AS gross_sales
    FROM gdb023.fact_sales_monthly s
    JOIN gdb023.fact_gross_price g ON s.product_code = g.product_code
    JOIN gdb023.dim_customer c ON s.customer_code = c.customer_code
    WHERE customer = "Atliq exclusive"
)
SELECT months, 
       year, 
       concat(round(sum(gross_sales) / 1000000, 2), "M") AS gross_sales
FROM temp_table
GROUP BY year, months, month_number
ORDER BY year, month_number;
