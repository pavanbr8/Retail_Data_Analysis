Create Database Retail_Project
USE Retail_Project
--________________________________________________ DATA CLEANING ___ (Slide No. 16-18)___________________________________________________


---------- STEP 1 ---
/*
Cust_order CTE: Aggregates customer order information by summing up the total amount (Total_Amount) for each Customer_id and Order_id, and rounding it off to the nearest integer.

Orderpayment_grouped CTE: Aggregates payment data from the Orders_Payement table by summing up the payment_value for each Order_id and rounding it to the nearest integer.

Match_order CTE: Performs an inner join between Cust_order and Orderpayment_grouped based on Order_id and ensures that the total amount matches the total payment value.

Final Selection: Inserts the results of the Match_order CTE (where total order amount equals payment value) into a new table called Matched_order_1.
*/
---
with   Cust_order as (select A.Customer_id, A.Order_id, round(sum(A.Total_Amount),0) as Total_amt from Orders A
group by A.Customer_id, A.Order_id),

Orderpayment_grouped as(select  A.order_ID, round(sum(A.payment_value),0) as pay_value_total from orderpayments 
A group by A.Order_id),

Match_order as (select A.* from Cust_order as A inner join Orderpayment_grouped as B 
on A.Order_id =B.order_ID and A.Total_amt=B.pay_value_total)
 

select * into Matched_order_1 from Match_order

--DROP TABLE Matched_order_1

-------- STEP 2------
/*
i. Cust_order CTE: This Common Table Expression (CTE) aggregates the total amount spent per customer for each order in the `Orders` table, rounding the total amount to the nearest integer.

ii. Orderpayment_grouped CTE: This CTE calculates the total payment value for each order from the `Orders_Payment` table, grouping by the order and rounding the total payment value.

iii. Null_list CTE: A right join is performed between `Cust_order` and `Orderpayment_grouped` to find orders where the total amount from `Orders` doesn't match the payment amount from `Orders_Payment`. It filters for cases where no matching customer ID is found, meaning the total order amount is not equal to the payment amount.

iv. Remaining_ids CTE: This part joins the mismatched payment orders from `Null_list` with the `Orders` table to retrieve the correct customer ID and order information where there are discrepancies in payment values.

v. Final Output: The result from `Remaining_ids`, which contains orders with mismatched payment and total amounts, is stored into a new table named `Remaining_orders_1`.
*/
WITH Cust_order AS (
    SELECT 
        A.Customer_id, 
        A.Order_id, 
        Round(sum(A.Total_Amount),0) AS Total_amt 
    FROM 
        Orders A
    GROUP BY 
        A.Customer_id, 
        A.Order_id
),

Orderpayment_grouped AS (
    SELECT 
        A.Order_ID, 
        Round(sum(A.payment_value ),0) AS pay_value_total 
    FROM 
        orderpayments A
    GROUP BY 
        A.Order_ID
),
--- We are right joining as we are having null values 
Null_list AS (
    SELECT 
        B.* 
    FROM 
        Cust_order AS A 
    RIGHT JOIN 
        Orderpayment_grouped AS B 
    ON 
        A.Order_id = B.Order_ID 
        AND A.Total_amt = B.pay_value_total
    WHERE 
        A.Customer_id IS NULL
) ,
Remaining_ids as (SELECT 
    B.Customer_id ,B.Order_id,A.pay_value_total
FROM 
    Null_list  A inner join Orders B on A.Order_ID =B.Order_id and  A.pay_value_total = round(B.Total_Amount,0))	 

select * into Remaining_orders_1 from Remaining_ids

--DROP TABLE Remaining_orders_1
----------
with T1 as (select B.* from Matched_order_1 A inner join Orders B on A.Customer_id=B.Customer_id and A.Order_id =B.Order_id),
	T2 as (select B.* from Remaining_orders_1 A inner join  Orders B on A.Customer_id=B.Customer_id and A.Order_id =B.Order_id and A.pay_value_total=round(B.Total_Amount,0) ),

	T as (select * from T1 union all select * from T2 )

	Select * into NEW_ORDER_TABLE_1 from T

--DROP TABLE NEW_ORDER_TABLE_1
------

Select * into Integrated_Table_1 from (select A.*, D.Category ,C.Avg_rating,E.seller_city ,E.seller_state,E.Region,F.customer_city,F.customer_state,F.Gender from NEW_ORDER_TABLE_1 A  
	inner join (select A.ORDER_id,avg(A.Customer_Satisfaction_Score) as Avg_rating from OrderReview_Ratings A group by A.ORDER_id) as C on C.ORDER_id =A.Order_id 
	inner join productsinfo as D on A.product_id =D.product_id
	inner join (Select distinct * from storeinfo) as E on A.Delivered_StoreID =E.StoreID
	inner join Customers as F on A.Customer_id =F.Custid) as T

Select * From Integrated_Table_1

--DROP TABLE Integrated_Table_1

--------------FINALISED RECORDS AFTER DATA CLEANING -- 98379 DATA RECORDS------------------------

Select * Into Finalised_Records_no from (
Select * From Integrated_Table_1

UNION ALL

(Select T.Customer_id,T.order_id,T.product_id,T.Channel,T.Delivered_StoreID,T.Bill_date_timestamp,Sum(T.Net_QTY)as Quantity,T.Cost_Per_Unit,
T.MRP,T.Discount,SUM(Net_amount) as Total_Amount ,C.Category,F.Customer_Satisfaction_Score as Avg_rating,
G.seller_city,G.seller_state,G.Region,E.customer_city,E.customer_state,E.Gender
from (
Select Distinct A.*,(A.Total_Amount/A.Quantity) as Net_amount, (A.Quantity/A.Quantity) as Net_QTY From Orders A
join Orders B
on A.order_id = B.order_id
where A.Delivered_StoreID <> B.Delivered_StoreID 
) as T
Inner Join productsinfo C
on T.product_id = C.product_id
inner join orderpayments as D
on T.order_id = D.order_id
inner Join Customers As E
on T.Customer_id = E.Custid
inner join OrderReview_Ratings F
on T.order_id = F.order_id
inner join storeinfo G
on T.Delivered_StoreID = G.StoreID
Group by T.Customer_id,T.order_id,T.product_id,T.Channel,T.Bill_date_timestamp,T.Cost_Per_Unit,T.Delivered_StoreID,
T.Discount,T.MRP,T.Total_Amount,T.Quantity,T.Net_amount,T.Net_QTY,C.Category,F.Customer_Satisfaction_Score,
G.seller_city,G.seller_state,G.Region,E.customer_city,E.customer_state,E.Gender) 
) AS x

--DROP TABLE Finalised_Records_no
------------ Creating the Table and storing the above Code output to Add_records table------------

Select * into Add_records from (
Select T.Customer_id,T.order_id,T.product_id,T.Channel,T.Delivered_StoreID,T.Bill_date_timestamp,Sum(T.Net_QTY)as Quantity,T.Cost_Per_Unit,
T.MRP,T.Discount,SUM(Net_amount) as Total_Amount ,C.Category,F.Customer_Satisfaction_Score as Avg_rating,
G.seller_city,G.seller_state,G.Region,E.customer_city,E.customer_state,E.Gender
from (
Select Distinct A.*,(A.Total_Amount/A.Quantity) as Net_amount, (A.Quantity/A.Quantity) as Net_QTY From Orders A
join Orders B
on A.order_id = B.order_id
where A.Delivered_StoreID <> B.Delivered_StoreID 
) as T
Inner Join productsinfo C
on T.product_id = C.product_id
inner join orderpayments as D
on T.order_id = D.order_id
inner Join Customers As E
on T.Customer_id = E.Custid
inner join OrderReview_Ratings F
on T.order_id = F.order_id
inner join storeinfo G
on T.Delivered_StoreID = G.StoreID
Group by T.Customer_id,T.order_id,T.product_id,T.Channel,T.Bill_date_timestamp,T.Cost_Per_Unit,T.Delivered_StoreID,
T.Discount,T.MRP,T.Total_Amount,T.Quantity,T.Net_amount,T.Net_QTY,C.Category,F.Customer_Satisfaction_Score,
G.seller_city,G.seller_state,G.Region,E.customer_city,E.customer_state,E.Gender) a


--DROP TABLE Add_records


Select * Into All_Tables From (
Select * From Finalised_Records_no
except
---------------Checking whether the records in Add_records table are also available with Integratable_Table _1 
(Select A.* From Add_records A
inner Join Integrated_Table_1 B
on A.order_id = B.order_id) 
) x
----- We found some records thus these needed to be deleted so using the Except function from Finalised Records 
----- And storing the data into new table Finalised_Records_1 
Select * From All_Tables

Select * from Add_records

---- Example for you all how to use the data set if you want the distinct Order and calculation
Select Distinct order_id, Sum(Total_Amount) From All_Tables
Group by order_id


--Main Table :
--DROP TABLE All_Tables
Select * From All_Tables
-------------------------------------------------------------------------------------------------------------

--****Dealing with the Other Data Discrepancies****--

--1. Deleting the records which are out of mentioned time period(removes 3 records)
select  *
from All_Tables
where Bill_date_timestamp not between '2021-01-09' AND '2023-10-31'

DELETE FROM All_Tables
WHERE Bill_date_timestamp NOT BETWEEN '2021-01-09' AND '2023-10-31'

---2. Replacing the storeid with the minimum of the storeid where one orderid mapped to multiple storeid(instore) (1119 records)
with CTE as
(select order_id,min(Delivered_StoreID) as min_StoreID 
from All_Tables
where Channel='Instore'
group by order_id)

                     
update All_Tables
set Delivered_StoreID=CTE.min_StoreID
                      from Finalised_Records_1 join CTE
                      on Finalised_Records_1.order_id=CTE.order_id
					  where Finalised_Records_1.Delivered_StoreID<>CTE.min_StoreID 
					  and Finalised_Records_1.Channel='Instore'

---3.Considering the Latest timestamp where one orderid mapped to multiple timestamps (347 records)
with CTE as 
(select order_id,max(Bill_date_timestamp) as max_timestamp
from All_Tables
group by order_id)

update All_Tables
set Bill_date_timestamp=C.max_timestamp 
                        from All_Tables join CTE as C
						on All_Tables.order_id=C.order_id
						where All_Tables.Bill_date_timestamp <>C.max_timestamp

--4. Delete Qty in consecutive order (197 records)
WITH CTE AS (
    SELECT Customer_id, order_id, product_id, Channel, Delivered_StoreID, Bill_date_timestamp,
           Cost_Per_Unit, MRP, Discount, Quantity,
           ROW_NUMBER() OVER (
               PARTITION BY Customer_id, order_id, product_id, Channel, Delivered_StoreID,
                            Bill_date_timestamp, Cost_Per_Unit, Discount
               ORDER BY order_id, Quantity DESC
           ) AS Row_number
    FROM All_Tables
)
DELETE FROM All_Tables
WHERE EXISTS (
    SELECT 1 
    FROM CTE AS C
    WHERE C.order_id = All_Tables.order_id
      AND C.product_id = All_Tables.product_id
      AND C.Quantity = All_Tables.Quantity
      AND C.MRP = All_Tables.MRP
      AND C.Cost_Per_Unit = All_Tables.Cost_Per_Unit
      AND C.Discount = All_Tables.Discount
      AND C.Row_number > 1
)
-- Creating Customer360, Orders360, and Store360 Tables for the Analysis
--
SELECT 
Customer_id, 
min(CAST(Bill_date_timestamp AS DATE)) AS First_Txn_Date, 
max(CAST(Bill_date_timestamp AS DATE)) AS Last_Txn_Date, 
DATEDIFF(Day,min(CAST(Bill_date_timestamp AS DATE)) ,max(CAST(Bill_date_timestamp AS DATE))) AS Tenure, 
COUNT(DISTINCT order_id) AS No_of_Transaction,
SUM(Total_Amount) AS Total_Revenue,
(SUM(Total_Amount) - SUM((Cost_Per_Unit * Quantity))) AS Profit,
SUM(Discount*Quantity) AS Discount,
SUM(Quantity) AS Total_Quantity,
COUNT( DISTINCT product_id) AS items_purchased,
COUNT(DISTINCT Delivered_StoreID) AS Total_Stores_Purch
INTO Customer_360
FROM All_Tables
GROUP BY Customer_id

SELECT * FROM Customer_360


--DROP TABLE Customer_360

ALTER TABLE Customer360
DROP COLUMN Customer_id

SELECT * 
INTO Customer360 
FROM Customers
LEFT JOIN Customer_360 ON Custid = Customer_id

--DROP TABLE Customer360


SELECT * FROM Customer360




---------------------------------------------------------Orders360----------------------------------------------------

SELECT order_id,
COUNT(DISTINCT product_id) AS Total_Items,
SUM(Quantity )AS Total_Quantity,
SUM(Total_Amount) AS Amount,
SUM(Discount * Quantity) AS Total_Discount,
COUNT(DISTINCT CASE WHEN Discount > 0 THEN product_id END) AS items_with_discount,
SUM(Cost_Per_Unit * Quantity) AS Total_cost,
(SUM(Total_Amount) - SUM((Cost_Per_unit * Quantity))) AS Total_Profit,
(SUM(Total_Amount) - SUM((Cost_Per_unit * Quantity)))/(SUM(Cost_Per_Unit * Quantity)) * 100 AS Profit_Percentage,
COUNT(DISTINCT Category) AS distinct_categories,
CASE 
    WHEN DATEPART(WEEKDAY, MIN(Bill_Date_timestamp)) IN (1, 7) THEN 'Weekend'  -- Sunday or Saturday
    ELSE 'Weekday'
  END AS weekend_trans_flag,
CASE 
    WHEN DATEPART(HOUR, MIN(Bill_Date_timestamp)) BETWEEN 6 AND 11 THEN 'Morning'
    WHEN DATEPART(HOUR, MIN(Bill_Date_timestamp)) BETWEEN 12 AND 17 THEN 'Afternoon'
    WHEN DATEPART(HOUR, MIN(Bill_Date_timestamp)) BETWEEN 18 AND 21 THEN 'Evening'
    ELSE 'Night'
  END AS Hours_flag
 
INTO Orders360
FROM All_Tables
GROUP BY order_id

--DROP TABLE Orders360

SELECT * FROM Orders360
------------------------------Store360--------------------------------
SELECT 
  Delivered_StoreID AS Store_ID,
  MAX(seller_city) AS seller_city,
  MAX(seller_State) AS seller_State,
  MAX(Region) AS Region,

  COUNT(DISTINCT product_id) AS Total_Store_Items_Sold,
  SUM(Quantity) AS Total_Quantity_Store_Sold,
  SUM(Total_Amount) AS Store_Total_Amount,
  SUM(Discount * Quantity) AS Total_Discount,
  COUNT(DISTINCT CASE WHEN Discount > 0 THEN product_id END) AS Store_items_with_discount,
  SUM(Cost_Per_Unit * Quantity) AS Total_cost,
  (SUM(Total_Amount) - SUM(Cost_Per_Unit * Quantity)) AS Total_Profit,
  ((SUM(Total_Amount) - SUM(Cost_Per_Unit * Quantity)) / NULLIF(SUM(Cost_Per_Unit * Quantity), 0)) * 100 AS Profit_Percentage,
  COUNT(DISTINCT Category) AS distinct_categories,

  SUM(CASE WHEN DATEPART(WEEKDAY, Bill_Date_timestamp) IN (1, 7) THEN Total_Amount ELSE 0 END) AS Weekend_Sales,
  SUM(CASE WHEN DATEPART(WEEKDAY, Bill_Date_timestamp) BETWEEN 2 AND 6 THEN Total_Amount ELSE 0 END) AS Weekday_Sales,

  (SUM(Total_Amount) / NULLIF(COUNT(DISTINCT Order_id), 0)) AS Average_order_value,
  ((SUM(Total_Amount) - SUM(Cost_Per_Unit * Quantity)) / NULLIF(COUNT(DISTINCT Order_id), 0)) AS Average_profit_per_tnx,
  ((SUM(Total_Amount) - SUM(Cost_Per_Unit * Quantity)) / NULLIF(COUNT(DISTINCT Customer_id), 0)) AS Average_profit_per_customer,
  (COUNT(DISTINCT order_id) * 1.0 / NULLIF(COUNT(DISTINCT Customer_id), 0)) AS Average_customer_visits,
  (SUM(Avg_rating) * 1.0 / NULLIF(COUNT(Customer_id), 0)) AS Average_rating_per_customer
INTO Store360
FROM All_Tables
GROUP BY Delivered_StoreID


--DROP TABLE Store360
SELECT * FROM Store360