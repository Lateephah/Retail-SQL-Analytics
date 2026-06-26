# Retail Transactions Analysis using MySQL

## Project Overview

/*This project analyzes one million retail transactions using MySQL. The objective was to design 
a normalized relational database from a raw transactional dataset and answer key business questions
 related to revenue, customer behavior, promotions, and payment methods.

The project demonstrates the complete SQL analytics workflow, including:
- Data import and troubleshooting
- Data cleaning and deduplication
- Database normalization (3NF)
- Data quality assessment
- Business-driven SQL analysis
- Documentation of dataset limitations
*/

# DATABASE CREATION
-- First and foremost I created a database called retail_project
CREATE DATABASE retail_project;

-- Switch my session to the retail_project database (db), in other to use the db
USE retail_project;

# DATA IMPORT AND TROUBLESHOOTING]
/* I used the MySQL Workbench Import Wizard to import my csv file into a new table 'retail_transactions_raw',
 though i had to interupt the process because it was taking too long to import. But then I proceeded in previewing 
 the first 10 rows to verify successful import and inspect column structure
 */
SELECT * FROM retail_transactions_raw LIMIT 10;

SELECT COUNT(*)
FROM retail_transactions_raw;
/* The above resulted to 138,750 data entries, which is just a small slice of 
the large 1 million data entries that the dataset has. I also figured that MySQL 
Workbench Import Wizard struggled with my 161MB CSV file, later discovered that it's a GUI tool and 
are not optimized for bulk loading so i opt out for loading the csv file directly using Data Infile
   */
   
-- Dropped the half-baked table in other to give way for the new one
DROP TABLE retail_transactions_raw;

--  To load the data, I first created the table structure
CREATE TABLE retail_transactions_raw (
    Transaction_ID INT,
    Date DATE,
    Customer_Name VARCHAR(100),
    Product VARCHAR(255),
    Total_Items INT,
    Total_Cost DOUBLE,
    Payment_Method VARCHAR(50),
    City VARCHAR(100),
    Store_Type VARCHAR(100),
    Discount_Applied BOOLEAN,
    Customer_Category VARCHAR(100),
    Season VARCHAR(50),
    Promotion VARCHAR(255)
);

/* I have to import my csv data file so this is to confirm whether MySQL allows importing 
files using LOAD DATA LOCAL INFILE */
SHOW VARIABLES LIKE 'local_infile';

/* to check if MySQL restricts file imports/exports to a specific directory, ensuring 
I know where CSV files must be placed */
SHOW VARIABLES LIKE 'secure_file_priv';

/* Here I modified the Discount_Applied column datatype from BOOLEAN to VARCHAR(10) 
   so it can store 'True' and 'False' as text */
ALTER TABLE retail_transactions_raw
MODIFY COLUMN Discount_Applied VARCHAR(10);


-- Loading the dataset into the table structure "retail_transactions_raw" I created earlier
LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Retail_Transactions_Dataset.csv'
INTO TABLE retail_transactions_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- Here I tried to preview the first 10 rows to verify successful import and inspect the new column structure again
SELECT * FROM retail_transactions_raw LIMIT 10;

SELECT COUNT(*)
FROM retail_transactions_raw;
/* Here I can see that we have a total entry count of 5 million instead of 1 million, which might indicate duplicate
 since I had to run it more than ones because of connection lost */ 

SELECT COUNT(DISTINCT Transaction_ID) FROM retail_transactions_raw;
-- I got 1 Million distinct entries confirming my initial hunch

# DATA CLEANING AND DEDUPLICATION

-- So to clean it up i createad a new table for the distinct entries which represent my unique entry from the beginning
CREATE TABLE retail_transactions_clean AS
SELECT DISTINCT *
FROM retail_transactions_raw;


SELECT COUNT(*)
FROM retail_transactions_clean;
/* Here I Verified if the new Clean Table is actually cleaned and since it outputted 1 Million entries count, 
I know it is */


DESCRIBE retail_transactions_clean;
/*This table stores 1 million retail transaction records, capturing customer details,
 product information, payment methods, discounts, and promotions to support sales trend
 and customer behavior analysis. */
 
 # EXPLORATORY DATA ANALYSIS (EDA)
 
SELECT MIN(Date), MAX(Date) FROM retail_transactions_clean;
/* Inspecting the Date range, it ranges from 2020-01-01 to 2024-05-18; meaning the dataset spans over four years of transactions 
great temporal coverage for trend analysis.*/


SELECT DISTINCT Payment_Method FROM retail_transactions_clean LIMIT 10;
-- For the Payment_Method, there are 4 Distinct methods, "Mobile Payment", "Cash", "Credit Card" and "Debit Card". 


SELECT DISTINCT store_type FROM retail_transactions_clean LIMIT 10;
-- There are 6 store types, 'Warehouse Club', "Speciality Store, 'Department Store', 'Pharmacy', 'Supermarket', 'Convenience Store'


SELECT DISTINCT Customer_Category FROM retail_transactions_clean;
/* There are 8 Customer Categories , the 'Homemaker', 'Professional', 'Young Adult', 'Retiree','Student', 
'Middle-Aged', 'Senior Citizen' and  'Teenager' */

SELECT DISTINCT season FROM retail_transactions_clean;
-- There are four Seasons Winter, fall, spring and summer.


SELECT DISTINCT promotion FROM retail_transactions_clean;
-- There are three promotion categories, 'None', 'BOGO (Buy One Get One)', and 'Discount on Selected Items'


/* This command does not add a new column; instead, it creates an index structure on the existing Transaction_ID
 column to make queries filtering or searching by transaction ID faster */
CREATE INDEX idx_transaction
ON retail_transactions_clean(Transaction_ID);


 -- Made "Transaction_ID" permit no empty cell
ALTER TABLE retail_transactions_clean
MODIFY Transaction_ID INT NOT NULL;

 -- Made "Transaction_ID" the primary key
ALTER TABLE retail_transactions_clean
ADD PRIMARY KEY (Transaction_ID);


SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Customer_Name) AS unique_customers
FROM retail_transactions_clean;
/* I found 329,738 unique customers in the dataset, so if the total row entry is 1 million then the average transactions per customer would be 3 transactions, 
and this serves as the justification for creating a Customer table because customers appear across multiple transactions. */


SELECT
    Transaction_ID,
    Product,
    Total_Items
FROM retail_transactions_clean
LIMIT 20;
/*some transactions contained a single product with a Total_Items value greater than one, while others
 contained multiple products with a lower Total_Items value than the number of products listed. 
 This indicates that Total_Items does not consistently represent either the number of distinct
 products purchased or the quantity of products purchased.*/
 
 
# DATABASE NORMALIZATION (3NF)

/* Before normalizing I have to investigate one more column; the Product Column
it contains list of products and not one product per row, so if I have to normalize the 
product lists, I can only analyze product popularity but cannot accurately calculate 
product-level revenue because the dataset doesn't provide that breakdown.
*/
SELECT Product
FROM retail_transactions_clean
LIMIT 10;


## 1. Customer Table Normalization
### Creating the Customers Table
/*To begin the normalization process, a separate `customers` table was created to isolate customer-related information from 
the transaction records. A unique constraint was applied to the combination of `customer_name` and `customer_category` because
 customer names were found to appear across multiple customer categories in the dataset.*/
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_category VARCHAR(100),
    UNIQUE(customer_name, customer_category)
);

### Populating the Customers Table
/*After creating the table structure, distinct customer records were extracted from the source table and inserted 
into the normalized `customers` table.*/
INSERT INTO customers (
    customer_name,
    customer_category
)
SELECT DISTINCT
    Customer_Name,
    Customer_Category
FROM retail_transactions_clean;


-- Preview normalized customer records
SELECT COUNT(*)
FROM customers;
-- There are 676,645 customers on the customer table


SELECT
    COUNT(DISTINCT customer_id) AS unique_customer_id,
    COUNT(DISTINCT customer_name) AS customer_name,
    COUNT(DISTINCT customer_category) AS customer_category
FROM customers;
/* The normalized `customers` table contains:
	- 676,645 customer records
	- 329,738 distinct customer names
	- 8 customer categories
*/


/* At first glance, it might appear that the customer table contains duplicate records because there are only 329,738 
distinct customer names but 676,645 customer records. To investigate this discrepancy, the following query was executed:
*/
SELECT
    customer_name,
    COUNT(DISTINCT customer_category) AS category_count
FROM customers
GROUP BY customer_name
HAVING COUNT(DISTINCT customer_category) > 1
LIMIT 20;
/* The analysis revealed that customer names are not unique within the dataset, For example names like
Aaron Allen   has   7 categories
Aaron Anderson  has  7 categories
Aaron Adams  has    6 categories
Aaron Ayers has 3 categories and so many others
Hence, the dataset appears to be synthetically generated and allows the same name to belong to multiple customer categories, so 
as a result, customer uniqueness was defined using the combination of 'customer_name` and `customer_category`*/

SELECT * FROM customers LIMIT 10;

## 2. Transactions Table Normalization
### Creating the Transactions Table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    transaction_date DATE,
    payment_method VARCHAR(50),
    city VARCHAR(100),
    store_type VARCHAR(100),
    discount_applied VARCHAR(10),
    season VARCHAR(50),
    promotion VARCHAR(255),
    total_items INT,
    total_cost DOUBLE,

    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);
# Populate Transactions Table
INSERT INTO transactions (
    transaction_id,
    customer_id,
    transaction_date,
    payment_method,
    city,
    store_type,
    discount_applied,
    season,
    promotion,
    total_items,
    total_cost
)
SELECT
    r.Transaction_ID,
    c.customer_id,
    r.Date,
    r.Payment_Method,
    r.City,
    r.Store_Type,
    r.Discount_Applied,
    r.Season,
    r.Promotion,
    r.Total_Items,
    r.Total_Cost
FROM retail_transactions_clean r
JOIN customers c
    ON r.Customer_Name = c.customer_name
   AND r.Customer_Category = c.customer_category;
   
   
SELECT COUNT(*)
FROM transactions;
-- There are 1,000,000 transactions on the Transactions table, hence normalization worked.


DROP TABLE dim_date;
-- Creating a Date Table (Date Dimension)
CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day_of_month INT,
    month_number INT,
    month_name VARCHAR(20),
    quarter_number INT,
    year_number INT,
    day_name VARCHAR(20),
    week_of_year INT,
    is_weekend BOOLEAN
);

-- Populating the Date Table
INSERT INTO dim_date (
    date_id,
    full_date,
    day_of_month,
    month_number,
    month_name,
    quarter_number,
    year_number,
    day_name,
    week_of_year,
    is_weekend
)
WITH RECURSIVE date_series AS (
    SELECT DATE('2020-01-01') AS dt

    UNION ALL

    SELECT DATE_ADD(dt, INTERVAL 1 DAY)
    FROM date_series
    WHERE dt < '2024-05-18'
)
SELECT
    DATE_FORMAT(dt, '%Y%m%d'),
    dt,
    DAY(dt),
    MONTH(dt),
    MONTHNAME(dt),
    QUARTER(dt),
    YEAR(dt),
    DAYNAME(dt),
    WEEK(dt),
    CASE
        WHEN DAYOFWEEK(dt) IN (1,7) THEN TRUE
        ELSE FALSE
    END
FROM date_series;


-- This is to check  recursion depth because my recursive query aborted after 1001 iterations. 
SHOW VARIABLES LIKE 'cte_max_recursion_depth';

-- Here I tried increasing the cte_max_recursion_depth to a  much larger value, 2000
SET SESSION cte_max_recursion_depth = 2000;

-- Recheck to see if the change what effective, then I tried populating dim_date table again 
SHOW VARIABLES LIKE 'cte_max_recursion_depth';

SELECT *
FROM dim_date
LIMIT 10;
/*Here i confirmed that the date table is populated, it has colunms like the date_id, full_date, day_of_month 
quarter_number, year_number etc. */

-- Adding date_id to the transaction table
ALTER TABLE transactions
ADD COLUMN date_id INT;

-- Populating the date_id column in the transaction table
UPDATE transactions
SET date_id =
DATE_FORMAT(transaction_date,'%Y%m%d');

/*Linked the date_id column in transactions to the date_id column in dim_date, ensuring 
referential integrity between the fact table and the date dimension.*/
ALTER TABLE transactions
ADD CONSTRAINT fk_transaction_date
FOREIGN KEY(date_id)
REFERENCES dim_date(date_id);


-- BUSINESS QUESTIONS
/*1. Revenue Analysis
a. Which city generates the most revenue? */
SELECT
    city,
    ROUND(SUM(total_cost), 2) AS total_revenue
FROM transactions
GROUP BY city
ORDER BY total_revenue DESC;
/*INSIGHTS:
Dallas leads with $5.28M in total revenue, narrowly ahead of Boston and Chicago $5.26M approximately. 
The difference between the top and bottom city (Dallas vs. Atlanta) is only about $74K, 
showing that revenue is fairly evenly distributed across major cities. Atlanta total revenue is  approximately $5.20M*/

# b. Which store type performs best?
SELECT
    store_type,
    ROUND(SUM(total_cost), 2) AS total_revenue,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY store_type
ORDER BY total_revenue DESC;
/*INSIGHTS:
Pharmacies lead with $8.77M in revenue and 166,915 transactions, closely followed by supermarkets 
and warehouse clubs. The differences across store types are relatively small (within about $65K), 
suggesting that revenue is evenly distributed across retail formats.*/

-- What are monthly revenue trends?
SELECT
    YEAR(transaction_date) AS sales_year,
    MONTH(transaction_date) AS sales_month,
    ROUND(SUM(total_cost), 2) AS monthly_revenue
FROM transactions
GROUP BY
    YEAR(transaction_date),
    MONTH(transaction_date)
ORDER BY
    sales_year,
    sales_month;
/*INSIGHTS:
Revenue trends are fairly stable across months and years, typically hovering around $950K–$1.02M per month.
Seasonal dips appear in February across multiple years, while March and July often show stronger performance.
In May 2024, revenue dropped sharply to $586K, which stands out as an anomaly compared to prior years.*/
    
/*Which season drives the most sales?
*/
SELECT
    season,
    ROUND(SUM(total_cost), 2) AS total_revenue
FROM transactions
GROUP BY season
ORDER BY total_revenue DESC;
/*INSIGHTS:
Fall leads with the highest revenue at $13.14M, slightly ahead of Summer and Spring.
The differences between seasons are relatively small (within about $48K), 
showing that sales are consistently strong year around.
Seasonal promotions may boost performance, but overall demand appears 
stable across all four seasons.*/


-- Customer Analysis
-- Top 20 Highest-Spending Customers
SELECT
    c.customer_name,
    c.customer_category,
    ROUND(SUM(t.total_cost), 2) AS lifetime_value
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
GROUP BY
    c.customer_name,
    c.customer_category
ORDER BY lifetime_value DESC
LIMIT 20;
/*INSIGHTS:
Michael Smith	Young Adult	3574.06
Michael Smith	Homemaker	3425.29
Michael Smith	Professional	3318.98
Michael Johnson	Homemaker	3244.05
Michael Smith	Middle-Aged	2982.59
Michael Smith	Retiree	2855.33
James Smith	Young Adult	2778.69
Christopher Smith	Senior Citizen	2670.71
Michael Smith	Senior Citizen	2625.33
Jennifer Smith	Student	2614.23
James Smith	Senior Citizen	2603.28
David Smith	Young Adult	2574.23
Robert Johnson	Student	2524.75
David Smith	Student	2513.19
Michael Smith	Student	2508.52
Michael Smith	Teenager	2478.43
Michael Johnson	Middle-Aged	2465.32
Michael Williams	Student	2438.28
David Johnson	Professional	2397.01
James Smith	Retiree	2360.76
This highlights the synthetic nature of the dataset, where the same name can exist in multiple categories.
For example, Michael Smith dominates the list, appearing across multiple categories (Young Adult, Homemaker, 
 Professional, Middle-Aged, Retiree, Senior Citizen, Student, Teenager).
 Other recurring names like James Smith, David Smith, and Michael Johnson also appear multiple times,
 reinforcing that customer identity is defined by the combination of name + category, not name alone.*/


-- Who are our most valuable customer segments?
SELECT
    c.customer_category,
    ROUND(SUM(t.total_cost), 2) AS total_revenue
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
GROUP BY c.customer_category
ORDER BY total_revenue DESC;
/*INSIGHTS:
Teenagers are the top revenue‑generating segment at $6.58M, closely followed by homemakers and senior citizens.
The spread between the highest and lowest segments is only about $50K, showing that all customer categories contribute almost equally to overall revenue.
This balanced distribution suggests that the business has a diverse and resilient customer base, with no single segment dominating sales.*/


-- Do professionals spend more than students?
SELECT
    c.customer_category,
    ROUND(AVG(t.total_cost), 2) AS avg_transaction_value
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
WHERE c.customer_category IN ('Professional', 'Student')
GROUP BY c.customer_category;
/*INSIGHTS:
Professionals spend slightly more per transaction ($52.53) compared to students ($52.49)
though the difference is marginal only about $0.04; showing that both segments have almost identical spending behavior.
This suggests that marketing strategies targeting either group could expect similar transaction values.*/

-- Which customer category shops most frequently?
 SELECT
    c.customer_category,
    COUNT(*) AS transaction_count
FROM transactions t
JOIN customers c
    ON t.customer_id = c.customer_id
GROUP BY c.customer_category
ORDER BY transaction_count DESC;
 /*INSIGHTS:
Senior Citizens shop most frequently, with 125,485 transactions, narrowly ahead of homemakers and teenagers.
The differences across categories are very small (less than 1,000 transactions between top and bottom), showing that shopping frequency is evenly distributed across all customer segments.
This suggests that while seniors lead slightly, all categories are highly engaged, making broad marketing strategies effective.*/
 
 
 -- Promotion Analysis
-- Do promotions increase revenue?
SELECT
    promotion,
    ROUND(AVG(total_cost), 2) AS avg_transaction_value,
    ROUND(SUM(total_cost), 2) AS total_revenue,
    COUNT(*) AS transactions
FROM transactions
GROUP BY promotion
ORDER BY total_revenue DESC;
/*INSIGHTS:
Transactions without promotions generated the highest total revenue ($17.55M) and the highest average spend ($52.57).
Promotional strategies like Discounts and BOGO slightly reduced both average spend and total revenue.
This suggests that while promotions may drive customer engagement, they do not necessarily increase overall revenue, in fact, they appear to slightly lower it.
The business may benefit more from targeted promotions rather than broad discounts, ensuring they attract incremental sales instead of cannibalizing full price purchases.*/


-- Which promotion performs best?
SELECT
    promotion,
    ROUND(SUM(total_cost), 2) AS total_revenue
FROM transactions
GROUP BY promotion
ORDER BY total_revenue DESC;
/* INSIGHTS:
Transactions with no promotion generated the highest revenue ($17.55M).
Discount on Selected Items and BOGO promotions both resulted in slightly lower revenues, around $17.46M and $17.44M respectively.
The differences are relatively small, but the data suggests that promotions do not outperform regular sales in terms of revenue.
This indicates that promotions may be better suited for customer acquisition or engagement goals rather than direct revenue maximization.
*/


-- Impact of Discount on Revenue
SELECT
    discount_applied,
    ROUND(AVG(total_cost), 2) AS avg_transaction_value
FROM transactions
GROUP BY discount_applied;
/*INSIGHTS:
Transactions with discounts applied have a slightly higher average spend ($52.49) compared to those without discounts ($52.42).
The difference is minimal (only $0.07), suggesting that discounts do not significantly increase transaction value.
This indicates that while discounts may encourage purchases, they do not meaningfully boost revenue per transaction.*/


# Payment Analysis
-- Which payment method is most popular?
SELECT
    payment_method,
    COUNT(*) AS transaction_count
FROM transactions
GROUP BY payment_method
ORDER BY transaction_count DESC;
/*INSIGHTS:
Cash is the most popular payment method, with 250,230 transactions, slightly ahead of debit 
cards (250,074) and credit cards(249,985).*/


-- Which payment method generates the most revenue?
SELECT
    payment_method,
    ROUND(SUM(total_cost), 2) AS total_revenue
FROM transactions
GROUP BY payment_method
ORDER BY total_revenue DESC;


/*INSIGHTS:
Cash transactions generate the highest revenue at $13.13M, slightly ahead of credit cards $13.12M.
Mobile payments and debit cards trail closely, with revenues around $13.10M and $13.09M respectively.*/


-- Do Mobile Payment customers spend more?
SELECT
    payment_method,
    ROUND(AVG(total_cost), 2) AS avg_transaction_value
FROM transactions
GROUP BY payment_method
ORDER BY avg_transaction_value DESC;
/*INSIGHTS:
Credit Card transactions have the highest average spend at $52.50, followed closely by cash and mobile payments.
Mobile Payment customers spend slightly less per transaction ($52.47) compared to credit card and cash users.
The differences are tiny (less than $0.13 across all methods), showing that average spending behavior is nearly identical regardless of payment method.
This suggests that payment method choice is driven more by convenience and preference than by transaction value.*/


/* LIMITATION:

  - Total_Cost appears to be recorded at the transaction level and Product contains multiple products (list of products),
	which means there are no quantity, or product price per product so product level analysis like product frequency, 
    and product revenue are impossibe to calculate.
    
    - Still on dataset Limitation, an investigation was conducted to determine whether discounts increased basket size.
    However, EDA revealed inconsistencies between the `Total_Items` field and the number of products listed
    within individual transactions. Due to the lack of product-level quantities and line-item details, a reliable basket size
    metric could not be established. As a result, the relationship between discounts and basket size was excluded from the 
    final analysis to avoid drawing unsupported conclusions from the data.
    
    BUSINESS RECOMMENDATIONS
    /*
    1. Revenue is distributed relatively evenly across cities, with only a small difference between the highest
 and lowest-performing locations. Rather than concentrating resources on a single city, marketing campaigns
 should be broadly distributed while giving slight additional attention to top-performing cities.

2. Transactions without promotions generated the highest overall revenue, while promotional campaigns 
produced only marginal differences in average transaction value. The company should evaluate whether 
promotions are increasing customer acquisition or simply reducing revenue through unnecessary discounts.

3. Revenue and shopping frequency are well balanced across customer categories. Since no single customer 
segment dominates sales, marketing efforts should continue targeting a broad range of customer groups.

4. Customer spending is nearly identical regardless of payment method. This suggests that offering 
multiple payment options improves convenience without negatively affecting revenue.

5. Future datasets should include:
- Product IDs
- Quantity purchased per product
- Unit prices
- Line-item revenue

These additions would enable product profitability analysis, market basket analysis, 
and more accurate customer purchasing insights.
    */

/* FUTURE IMPROVEMENTS

This project can be extended by:
- Parsing the Product column into individual product records.
- Creating Product and Transaction_Items tables.
- Performing Market Basket Analysis.
- Building customer lifetime value models.
- Creating stored procedures and SQL views.
- Optimizing frequently used queries with additional indexes.
*/



