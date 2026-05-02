create database olistdb;
use olistdb;

-- inserting data from jupyter into sql 

-- inserting orders data
create table orders (order_id VARCHAR(50) ,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    purchase_time DATETIME,
    order_approved_at varchar(100),
    order_delivered_carrier_date varchar(100),
    delivery_time DATETIME,
    order_estimated_delivery_date varchar(100)
);
select * from orders;

-- inserting customer  data 
 CREATE TABLE customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);
select * from customers;

-- inserting products data
create table products(product_id varchar(100),   
						product_category_name varchar(100),
						product_name_lenght float,
                        product_description_lenght float,
                        product_photos_qty float,
                        product_weight_g float,
						product_length_cm float,
                        product_height_cm float,
                        product_width_cm float
                      );  
select * from products;     

-- inserting payments data
create table payments( order_id varchar(100),
						payment_sequential int ,
                        payment_type varchar(100) ,
                        payment_installments int ,
                        payment_value float
                      );
select * from payments;

-- inserting reviews data
create table reviews( review_id varchar(100),
						order_id varchar(100),
						review_rating int,
						review_comment_title varchar(100),
						review_comment_message LONGTEXT,
						review_creation_date datetime,
					    review_answer_timestamp datetime
                      );                     
select * from reviews;                      

-- inserting items data
create table items( order_id varchar(100),
					order_item_id int ,
                    product_id varchar(100),    
                    seller_id VARCHAR(100),
                    shipping_limit_date DATETIME,
                    price FLOAT,
                    freight_value  float
                  );
SELECT * FROM ITEMS;

-- inserting sellers data
create table sellers(seller_id VARCHAR(100),
					 seller_zip_code_prefix int,
                     seller_city varchar(100),
                     seller_state varchar(100)
                     );
select * from sellers;

-- inserting geo data
create table geo( geolocation_zip_code_prefix int,
					geo_lattitude float,
                    geo_longitude float,
                    geolocation_city varchar(100),
                    geolocation_state varchar(100)
                 );
select * from geo;   

-- Understanding data 
describe orders;
describe customers;
describe products;
describe payments;
describe reviews;
describe items;
describe sellers;
describe geo;

-- Finding NULL's
select *
from orders
where order_id is null;

select *
from products
where product_id is null;

select * 
from reviews
where order_id is NULL;

-- Finding Duplicates
select order_id , count(*)
from orders
group by order_id
having count(*) > 1;

select product_id , count(*)
from products
group by product_id
having count(*) > 1;

-- (reviews has repeated order_id's comments but it is accepted, beacuse one person has right to give multiple reviews)
select order_id , count(*)
from reviews
group by order_id
having count(*) > 1;

-- creating a big master table from single indivisual tables using VIEWS
create view master_table as 
select 
		o.order_id,
        o.customer_id,
        o.order_status,
        o.purchase_time,
        o.delivery_time,
        
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        
        oi.product_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        
        p.payment_type,
        p.payment_value,
        
        pr.product_category_name
       
       from orders o join customers c join items oi join payments p join products pr
       on o.customer_id = c.customer_id and o.order_id = oi.order_id and o.order_id = p.order_id and oi.product_id = pr.product_id;
       
select * from master_table;

-- 1) total sales
select sum(payment_value) as total_revenue
from master_table;    -- 2cr 3lakh 7121

-- 2) Sales by Month 
select date_format(purchase_time, '%Y-%M') as Month,
		sum(payment_value) as total_sales
from master_table
group by month
order by month;     

-- 3) Top 10 Customers by revenue
select customer_unique_id,
		sum(payment_value) as revenue
from master_table
group by customer_unique_id
order by revenue desc
limit 10;        

-- 4) Finding repeated Customers
select customer_unique_id,
		count(distinct order_id) as customers_count
from master_table
group by customer_unique_id
having customers_count >1 
order by customers_count desc;

-- 5) Top 10 Products ( we take price from orders_item(products comapny buy for sellin) table beacuse if we spend more money in buying products means it is top selling)
select product_id,
		sum(price) as total_revenue
from master_table
group by product_id
order by total_revenue desc
limit 10;

-- 6) top category names
select product_category_name,
		sum(price) as total_sales
from master_table
group by product_category_name
order by total_sales desc;

-- 7) Delivery time calculation 
select order_id, datediff(delivery_time,purchase_time) as delivery_time
from orders;  

-- 8) Average delivery time calculation 
select  avg(datediff(delivery_time,purchase_time)) as Avg_delivery_time
from orders;  

-- 9) No of late Delivery dates than estimated
select count(*) as Late_delivery_day
from orders
where delivery_time>order_estimated_delivery_date;  

-- 10) Payment type behaviour (giving offers on credit card can increase sales)
select payment_type, count(*) as usage_count
from payments
group by payment_type
order by usage_count desc;

-- 11) Average payment value from each type 
select payment_type, avg(payment_value) as avg_payment
from payments
group by payment_type;    

-- 12) RFM Analysis (RFM analysis means grouping customers based on how recently they bought, how often they buy, and how much money they spend)
-- recommendation - give coupans and offers for repaeted and high frequency customers
select customer_unique_id, 
		max(purchase_time) as Last_purchse,
        count(order_id) as frequency,
        sum(payment_value) as monetary
from master_table
group by customer_unique_id
order by frequency desc;

-- 13) Cohort analysis (Tracking how a group of users continue to return or stay active over time.)
-- Recommendation- finding sales why high in 11,1,3,4,5,2,etc of 2017 and 2018 and repeat it to increase sales
SELECT 
    DATE_FORMAT(purchase_time, '%Y-%m') AS cohort,
    COUNT(DISTINCT customer_unique_id) AS users
FROM master_table
GROUP BY cohort
order by users desc;     

-- 14) Seller performance 
select seller_id,
		sum(price) as revenue,
        count(order_id) as total_sales
from master_table
group by seller_id
order by revenue desc;        

-- 15) Delivery Vs Rating calculation
-- recommendation - fast delivery , High ratings 
select r.review_rating,
		avg(datediff(o.delivery_time, o.purchase_time)) as avg_delivery_time
from orders o join reviews r
on o.order_id = r.order_id
group by r.review_rating;        
  