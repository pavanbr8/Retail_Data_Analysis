USE Retail_Project
--Exploratory Data Analysis
SELECT COUNT(DISTINCT Product_id) Products_Count,
COUNT(DISTINCT order_id) Total_Orders,
COUNT(DISTINCT Category) Category, 
SUM(Quantity) Qty,
SUM(Cost_Per_Unit) Purchased,
SUM(Total_Amount) Revenue,
SUM(Discount) Discount,
SUM(Total_Amount) - SUM(Cost_Per_Unit * Quantity) Profit
FROM All_Tables

--Customer Level Analysis--
SELECT
COUNT(DISTINCT Customer_id) AS Customer,
COUNT(DISTINCT order_id) * 1.0 / COUNT(DISTINCT Customer_id)*1.0 AS Total_Avg_Transactions,
COUNT(DISTINCT order_id)  AS Total_Transactions,
SUM(Total_Amount) * 1.0 / COUNT(DISTINCT Customer_id)*1.0 AS Average_Customer_Spend,
SUM(Total_Amount) * 1.0 AS Total_Customer_Spend,
SUM(Total_Amount) * 1.0 / COUNT(DISTINCT order_id)*1.0 AS Average_Transaction_value,
SUM(Total_Amount) * 1.0  AS Total_Transaction_value,
(SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) * 1.0 / COUNT(DISTINCT Customer_id)*1.0 AS Avg_Profit,
(SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) * 1.0 AS Total_Profit,
AVG(Avg_rating * 1.0) AS Avg_Review_per_Order

FROM All_Tables

--*******************RFM Segmentation********************--
--1. Find the Recency, Frequency, Monetory
--2. Using NTILE(4) find the R_Quartile, F_Quartile, M_Quartile
--3. Find RFM_Score by adding the R_Quartile, F_Quartile, M_Quartile
--4. Based on the RFM_Score Segment the Customers where 1+1+1 = 3 is Min and 4+4+4 = 12 is Max, so the RFM_Score from 11 to 12 is Premium, 9 to 10 is Gold, 7 to 8 is Silver and 3 to 6 are Standard Customers
WITH CTE AS (
    SELECT 
        Customer_id,
        MIN(Bill_Date_timestamp) AS First_tnx,
        MAX(Bill_Date_timestamp) AS Last_tnx,
        COUNT(DISTINCT order_id) AS Frequency,
        ROUND(SUM(Total_Amount), 5) AS Monetory
    FROM All_Tables
    GROUP BY Customer_id
),
CTE1 AS (
    SELECT MAX(Bill_Date_timestamp) AS Fixed_date
    FROM All_Tables
),
CTE2 AS (
    SELECT 
        C.Customer_id,
        DATEDIFF(DAY, C.Last_tnx, C1.Fixed_date) AS Recency,
        C.Frequency,
        C.Monetory 
    FROM CTE C
    CROSS JOIN CTE1 C1
),
CTE3 AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY Recency DESC) AS R_Quartile,   -- Lower recency is better
        NTILE(4) OVER (ORDER BY Frequency ASC) AS F_Quartile, -- Higher frequency is better
        NTILE(4) OVER (ORDER BY Monetory ASC) AS M_Quartile   -- Higher monetary is better
    FROM CTE2
)
SELECT *,
       (R_Quartile + F_Quartile + M_Quartile) AS RFM_Score,
       CASE 
           WHEN (R_Quartile + F_Quartile + M_Quartile) >= 11 THEN 'Premium' 
           WHEN (R_Quartile + F_Quartile + M_Quartile) >= 9 THEN 'Gold' 
           WHEN (R_Quartile + F_Quartile + M_Quartile) >= 7 THEN 'Silver' 
           ELSE 'Standard'
       END AS Segment
	   INTO RFM_Base
FROM CTE3
ORDER BY Segment, RFM_Score DESC


--DROP TABLE RFM_Base

SELECT *
FROM RFM_Base

--Customer Behaviour Analysis--
SELECT Customer_id, COUNT(DISTINCT order_id) Total_Orders,
SUM(Total_amount) - SUM(Cost_Per_Unit * Quantity) Profit
FROM All_Tables
GROUP BY Customer_id

--Gender Based Analysis--
WITH GenderStats AS (
    SELECT 
        Gender, 
        COUNT(DISTINCT Customer_id) AS Cust,
        COUNT(DISTINCT Order_id) AS Orders,
        SUM(Total_Amount) * 1.0 / COUNT(DISTINCT Customer_id) AS Average_Customer_Spend,
        SUM(Total_Amount) * 1.0 AS Total_Customer_Spend,
        (SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) * 1.0 AS Total_Profit,
        (SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) / COUNT(DISTINCT Customer_id) AS Avg_Profit
    FROM All_Tables
    GROUP BY Gender
),
TotalStats AS (
    SELECT 
        SUM(Cust) AS Total_Cust,
        SUM(Orders) AS Total_Orders,
        SUM(Total_Customer_Spend) AS Total_Spend,
        SUM(Total_Profit) AS Total_Profit
    FROM GenderStats
)
SELECT 
    gs.Gender,
    gs.Cust,
    gs.Orders,
    ROUND(gs.Average_Customer_Spend, 2) AS Average_Customer_Spend,
    ROUND(gs.Total_Customer_Spend, 2) AS Total_Customer_Spend,
    ROUND(gs.Total_Profit, 2) AS Total_Profit,
    ROUND(gs.Avg_Profit, 2) AS Avg_Profit,

    ROUND((gs.Cust * 100.0) / ts.Total_Cust, 2) AS Total_Customer_Percentage,
    ROUND((gs.Orders * 100.0) / ts.Total_Orders, 2) AS Total_Orders_Percentage,
    ROUND((gs.Total_Customer_Spend * 100.0) / ts.Total_Spend, 2) AS Total_Customer_Spend_Percentage,
    ROUND((gs.Total_Profit * 100.0) / ts.Total_Profit, 2) AS Total_Profit_Percentage

FROM GenderStats gs, TotalStats ts



--*****************************--Month wise Analysis--******************************--
SELECT  
    DATENAME(MONTH, Bill_Date_timestamp) AS [Month],
    YEAR(Bill_Date_timestamp) AS [Year],
    COUNT(DISTINCT Customer_id) AS Customer,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) * 1.0 / COUNT(DISTINCT Customer_id) * 1.0 AS Total_Avg_Transactions,
    COUNT(DISTINCT order_id) * 1.0 AS Total_Transactions,
    SUM(Total_Amount) * 1.0 / COUNT(DISTINCT Customer_id) * 1.0 AS Average_Customer_Spend,
    SUM(Total_Amount) * 1.0 AS Total_Customer_Spend,
    SUM(Total_Amount) * 1.0 / COUNT(DISTINCT order_id) AS Average_Transaction_value,
    (SUM(Total_Amount) * 1.0 - SUM(Cost_Per_unit * Quantity) * 1.0) / COUNT(DISTINCT Customer_id) * 1.0 AS Avg_Profit,
    (SUM(Total_Amount) * 1.0 - SUM(Cost_Per_unit * Quantity) * 1.0) AS Total_Profit,
    (SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) / COUNT(DISTINCT Delivered_StoreID) AS Avg_Store_Profit,
    (SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) AS Total_Profit_Check,
    SUM(Avg_rating) * 1.0 / COUNT(DISTINCT order_id) * 1.0 AS Avg_Review_per_Order
FROM All_Tables
GROUP BY  
    YEAR(Bill_Date_timestamp),
    MONTH(Bill_Date_timestamp),
    DATENAME(MONTH, Bill_Date_timestamp),
    Delivered_StoreID
ORDER BY 
    YEAR(Bill_Date_timestamp),
    MONTH(Bill_Date_timestamp)




--**********************--
SELECT  DATENAME(MONTH,Bill_Date_timestamp) 'Month',
SUM(Total_Amount) *1.0/COUNT(DISTINCT order_id)*1.0 Total_Avg_Transactions,
COUNT(DISTINCT order_id)*1.0 Total_Transactions
FROM All_Tables
GROUP BY  DATENAME(MONTH,Bill_Date_timestamp),
MONTH(Bill_Date_timestamp)
ORDER BY  MONTH(Bill_Date_timestamp)

--*************--
SELECT  DATENAME(MONTH,Bill_Date_timestamp) 'Month',
COUNT(DISTINCT Customer_id) Customer,
COUNT(DISTINCT order_id) orders,
COUNT(DISTINCT order_id)*1.0/COUNT(DISTINCT Customer_id)*1.0 Total_Avg_Transactions,
COUNT(DISTINCT order_id)*1.0 Total_Transactions,
SUM(Total_Amount)*1.0/COUNT(DISTINCT Customer_id)*1.0 Average_Customer_Spend,
SUM(Total_Amount)*1.0 Total_Customer_Spend,
SUM(Total_Amount)/COUNT(DISTINCT order_id) Average_Transaction_value,
(SUM(Total_Amount)*1.0 - SUM(Cost_Per_unit * Quantity)*1.0) / COUNT(DISTINCT Customer_id)*1.0 Avg_Profit,
(SUM(Total_Amount)*1.0 - SUM(Cost_Per_unit * Quantity)*1.0)  Total_Profit,
(SUM(Total_Amount)- SUM(Cost_Per_unit * Quantity)) / COUNT(DISTINCT Delivered_StoreID) Avg_Store_Profit,
(SUM(Total_Amount)- SUM(Cost_Per_unit * Quantity)) Total_Profit,
SUM(Customer_Satisfaction_Score) * 1.0 /COUNT(DISTINCT order_id)*1.0 Avg_Review_per_Order
FROM All_Tables
GROUP BY  DATENAME(MONTH,Bill_Date_timestamp),
MONTH(Bill_Date_timestamp)
ORDER BY  MONTH(Bill_Date_timestamp)


--*****************Year-Over-Year*********************--
SELECT YEAR(Bill_Date_timestamp) AS year,
COUNT(DISTINCT Delivered_StoreID) Total_Stores,
COUNT(DISTINCT Customer_id) Total_Customer,
COUNT(DISTINCT order_id) Total_order,
COUNT(DISTINCT product_id) Total_product,
ROUND(SUM(Cost_Per_unit * Quantity),2) Total_Cost,
ROUND(SUM(Total_Amount),2) Total_Amount_Sold,
ROUND(SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity),2) Total_Profit,
SUM(Quantity) Total_Quantity,
SUM(Discount) Total_Discount 
FROM All_Tables
GROUP BY YEAR(Bill_Date_timestamp)

--**********************--
SELECT  YEAR(Bill_Date_timestamp) 'Year',
COUNT(DISTINCT Customer_id) Customer,
COUNT(DISTINCT order_id)* 1.0/COUNT(DISTINCT Customer_id)* 1.0 Total_Avg_Transactions,
SUM(Total_Amount )* 1.0/COUNT(DISTINCT Customer_id) *1.0 Average_Customer_Spend,
ROUND(SUM(Total_Amount)/COUNT(DISTINCT order_id),0) Average_Transaction_value,
(SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) / COUNT(DISTINCT Customer_id)* 1.0 Avg_Profit,
--ROUND((SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) / COUNT(DISTINCT Delivered_StoreID),0) Avg_Store_Profit,
CAST(SUM(Avg_rating) * 1.0 /COUNT(DISTINCT order_id) AS DECIMAL(10,2)) Avg_Review_per_Order
FROM All_Tables
GROUP BY  YEAR(Bill_Date_timestamp)

--**************************Regional**********************--
SELECT Region,
COUNT(DISTINCT Delivered_StoreID) Total_Stores,
COUNT(DISTINCT Customer_id)/COUNT(DISTINCT Delivered_StoreID) Total_Customer,
COUNT(DISTINCT order_id)/COUNT(DISTINCT Delivered_StoreID) Total_order,
COUNT(DISTINCT product_id) Total_product,
ROUND(SUM(Cost_Per_unit * Quantity),2) Total_Cost,
ROUND(SUM(Total_Amount),2) Total_Amount_Sold,
ROUND(SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity),2)/COUNT(DISTINCT Delivered_StoreID) Total_Profit,
SUM(Quantity)/COUNT(DISTINCT Delivered_StoreID) Total_Quantity,
SUM(Discount) Total_Discount,
ROUND((SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity))/SUM(Cost_Per_unit * Quantity)*100,2) Profit_Percentage
FROM All_Tables
GROUP BY Region
ORDER BY Region

--********--
SELECT Region,--Customer_state,
COUNT(DISTINCT Customer_id) Customer,
COUNT(DISTINCT order_id) *1.0/COUNT(DISTINCT Customer_id) *1.0  Total_Avg_Transactions,
SUM(Total_Amount)/COUNT(DISTINCT Customer_id) Average_Customer_Spend,
SUM(Total_Amount)/COUNT(DISTINCT order_id) Average_Transaction_value,
(SUM(Total_Amount)*1.0 - SUM(Cost_Per_unit * Quantity)*1.0) / COUNT(DISTINCT Customer_id)*1.0 Avg_Profit,
--ROUND((SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) / COUNT(DISTINCT Delivered_StoreID),0) Avg_Store_Profit,
SUM(Avg_rating) * 1.0 /COUNT(DISTINCT order_id)*1.0 Avg_Review_per_Order
FROM All_Tables
GROUP BY Region

--***********************************WEEKDAY_WEEKEND*********************************--
WITH WeekendFlagged AS (
  SELECT *,
    CASE 
      WHEN DATEPART(WEEKDAY, Bill_Date_timestamp) IN (1, 7) THEN 'Weekend'
      ELSE 'Weekday'
    END AS weekend_trans_flag
  FROM All_Tables
)

SELECT  
weekend_trans_flag,Channel,COUNT(DISTINCT order_id) AS Orders, Category,
COUNT(DISTINCT Customer_id) AS Customer,
COUNT(DISTINCT order_id) * 1.0 / COUNT(DISTINCT Customer_id) * 1.0 AS Total_Avg_Transactions,
COUNT(DISTINCT order_id) * 1.0  AS Total_Transactions,
SUM(Total_Amount) * 1.0 / COUNT(DISTINCT Customer_id)*1.0 AS Average_Customer_Spend,
SUM(Total_Amount) * 1.0 AS Total_Customer_Spend,
SUM(Total_Amount) * 1.0 / COUNT(DISTINCT order_id)*1.0 AS Average_Transaction_value,
SUM(Total_Amount) * 1.0  AS Total_Transaction_value,
(SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) * 1.0 / COUNT(DISTINCT Customer_id)*1.0 AS Avg_Profit,
(SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) * 1.0 AS Total_Profit,
(SUM(Avg_rating) * 1.0 / COUNT(DISTINCT order_id)*1.0) AS Avg_Review_per_Order
FROM WeekendFlagged
GROUP BY weekend_trans_flag, Category, Channel
ORDER BY Total_Customer_Spend DESC

--********************************************************************--
WITH WeekendFlagged AS (
  SELECT *,
    CASE 
      WHEN DATEPART(WEEKDAY, Bill_Date_timestamp) IN (1, 7) THEN 'Weekend'
      ELSE 'Weekday'
    END AS weekend_trans_flag
  FROM All_Tables
)

SELECT  
weekend_trans_flag,
SUM(Total_Amount) * 1.0 / COUNT(DISTINCT Order_id) AS Total_Avg_Transactions,
COUNT(DISTINCT order_id) * 1.0  AS Total_Transactions
FROM WeekendFlagged
GROUP BY weekend_trans_flag


--********************************************************************--
WITH WeekendFlagged AS (
  SELECT *,
    CASE 
      WHEN DATEPART(WEEKDAY, Bill_Date_timestamp) IN (1, 7) THEN 'Weekend'
      ELSE 'Weekday'
    END AS weekend_trans_flag
  FROM All_Tables
)
SELECT  
weekend_trans_flag,Channel,
SUM(Total_Amount) * 1.0 AS Revenue,
(SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity)) * 1.0 AS Total_Profit
FROM WeekendFlagged
GROUP BY weekend_trans_flag, Channel


--*********************************************************************--
WITH WeekendFlagged AS (
  SELECT *,
    CASE 
      WHEN DATEPART(WEEKDAY, Bill_Date_timestamp) IN (1, 7) THEN 'Weekend'
      ELSE 'Weekday'
    END AS weekend_trans_flag
  FROM All_Tables
)

SELECT  
weekend_trans_flag, Category,
COUNT(DISTINCT Customer_id) AS Customer,
COUNT(DISTINCT Order_id) AS Orders,
SUM(Total_Amount) Revenue,
SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity) Profit
FROM WeekendFlagged
GROUP BY weekend_trans_flag, Category

--*********************************************************************--
WITH WeekendFlagged AS (
  SELECT *,
    CASE 
      WHEN DATEPART(WEEKDAY, Bill_Date_timestamp) IN (1, 7) THEN 'Weekend'
      ELSE 'Weekday'
    END AS weekend_trans_flag
  FROM All_Tables
)

SELECT  
weekend_trans_flag,
ROUND(SUM(Total_Amount),2) AS Revenue
FROM WeekendFlagged
GROUP BY weekend_trans_flag

--********************************************************************--
WITH WeekendFlagged AS (
  SELECT *,
    CASE 
      WHEN DATEPART(WEEKDAY, Bill_Date_timestamp) IN (1, 7) THEN 'Weekend'
      ELSE 'Weekday'
    END AS weekend_trans_flag
  FROM All_Tables
)

SELECT  
weekend_trans_flag,Channel,
COUNT(DISTINCT Customer_id) AS Customer,
COUNT(DISTINCT Order_id) AS 'Orders'
FROM WeekendFlagged
GROUP BY weekend_trans_flag, Channel

--****************************Overall_category_Analysis***********************--
SELECT Category,
SUM(Total_Amount) Revenue,
SUM(Total_Amount) - SUM(Cost_Per_unit * Quantity) Profit
FROM All_Tables
GROUP BY Category

UPDATE dbo.All_Tables
SET Category='Others'
WHERE Category ='#N/A'

--************************Store-wise Data Analysis*************************--
SELECT Delivered_StoreID,
COUNT(DISTINCT Customer_id) Customers,
COUNT(DISTINCT order_id) 'Orders',
SUM(Total_Amount) Revenue,
SUM(Total_Amount) - SUM(Cost_per_unit * Quantity) Profit,
AVG(Avg_rating * 1.0) Avg_rating,
COUNT(DISTINCT order_id) / COUNT(DISTINCT Delivered_StoreID) Avg_Transactions
FROM All_Tables
WHERE Delivered_StoreID = 'ST103'
GROUP BY Delivered_StoreID

--******************MONTHLY Analysis*********************--
SELECT 
    YEAR(Bill_date_timestamp) AS [Year],
    DATENAME(MONTH, Bill_date_timestamp) AS [MonthName],
    MONTH(Bill_date_timestamp) AS [MonthNumber],
    SUM(Total_Amount) AS Revenue,
    COUNT(DISTINCT CUSTOMER_ID) AS Customers
FROM 
    All_Tables
GROUP BY 
    YEAR(Bill_date_timestamp),
    MONTH(Bill_date_timestamp),
    DATENAME(MONTH, Bill_date_timestamp)
ORDER BY 
    YEAR(Bill_date_timestamp),
    MONTH(Bill_date_timestamp)

--**************Sales BY State*********--
SELECT TOP 5 Seller_State,
SUM(Total_Amount) Revenue
FROM All_Tables
GROUP BY seller_state
ORDER BY 2 

--**************Revenue by category and region Wise***************--
SELECT 
    Category,
    Region AS Region,
    SUM(Total_Amount) AS Revenue
FROM 
    All_Tables
GROUP BY 
    Category, Region
ORDER BY 3 DESC

--******************TOP and BOTTOM Products******************--
SELECT TOP 1 product_id,
SUM(Total_Amount) Revenue,
SUM(Total_Amount) - SUM(Cost_per_unit * Quantity) Profit
FROM All_Tables
GROUP BY product_id, Category
ORDER BY 2 DESC, 3 DESC

SELECT TOP 1 product_id,
SUM(Total_Amount) Revenue,
SUM(Total_Amount) - SUM(Cost_per_unit * Quantity) Profit
FROM All_Tables
GROUP BY product_id, Category
ORDER BY 2, 3 

SELECT TOP 1 product_id,
SUM(Total_Amount) Revenue,
SUM(Total_Amount) - SUM(Cost_per_unit * Quantity) Profit
FROM All_Tables
GROUP BY product_id, Category
ORDER BY  3 DESC, 2 DESC

SELECT TOP 1 product_id,
SUM(Total_Amount) Revenue,
SUM(Total_Amount) - SUM(Cost_per_unit * Quantity) Profit
FROM All_Tables
GROUP BY product_id, Category
ORDER BY  3, 2