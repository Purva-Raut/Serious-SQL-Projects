/* Creating tables sales, members and menu for dannys_diner database*/
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 
DROP TABLE IF EXISTS menu;
CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
DROP TABLE IF EXISTS members;
CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
 
/*Check all tables are loaded*/
SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;

--Case Study Questions
/* 1. What is the total amount each customer spent at the restaurant?*/
SELECT s.customer_id, SUM(p.price) total_amount
FROM sales s
JOIN menu p
ON s.product_id=p.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

/*2.How many days has each customer visited the restaurant?*/
SELECT s.customer_id, COUNT(DISTINCT (s.order_date))total_days
FROM sales s
GROUP BY s.customer_id
ORDER BY s.customer_id;

/*3. What was the first item from the menu purchased by each customer?*/
SELECT DISTINCT customer_id, product_name
FROM
(SELECT s.customer_id, s.order_date, p.product_name, RANK()OVER(PARTITION BY s.customer_id ORDER BY s.order_date) Rank1
FROM sales s
JOIN menu p
ON s.product_id=p.product_id)t
WHERE Rank1=1;

--OR

WITH ordered_sales AS
(SELECT s.customer_id,
RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS order_rank,
p.product_name
FROM sales s
INNER JOIN menu p
ON s.product_id = p.product_id)
SELECT DISTINCT customer_id, product_name
FROM ordered_sales
WHERE order_rank=1;

/*4.What is the most purchased item on the menu and how many times was it purchased by all customers?*/
SELECT p.product_name, COUNT(s.product_id) max_purchase
FROM sales s
JOIN menu p
ON s.product_id=p.product_id
GROUP BY p.product_name
ORDER BY max_purchase DESC
LIMIT 1

/* 5. Which item was the most popular for each customer?*/
SELECT customer_id, product_name, max_purchase
FROM
(SELECT s.customer_id, p.product_name, COUNT(s.product_id) max_purchase,
RANK()OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id)DESC) Rank1
FROM sales s
JOIN menu p
ON s.product_id=p.product_id
GROUP BY s.customer_id,p.product_name
ORDER BY s.customer_id)t
WHERE rank1=1

/* 6. Which item was purchased first by the customer after they became a member?*/
WITH table1 AS
(SELECT s.customer_id,s.order_date,m.join_date,s.product_id, p.product_name,
RANK()OVER(PARTITION BY s.customer_id ORDER BY s.order_date)Rank1
FROM sales s
JOIN members m
ON s.customer_id=m.customer_id
JOIN menu p
ON s.product_id=p.product_id
WHERE s.order_date >=m.join_date
ORDER BY s.order_date)
SELECT customer_id, order_date,product_name
FROM table1
WHERE Rank1=1;

/* 7. Which item was purchased just before the customer became a member?*/
WITH table1 AS
(SELECT s.customer_id,s.order_date,m.join_date,s.product_id, p.product_name,
RANK()OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC)Rank1
FROM sales s
JOIN members m
ON s.customer_id=m.customer_id
JOIN menu p
ON s.product_id=p.product_id
WHERE s.order_date <m.join_date
ORDER BY s.order_date)
SELECT DISTINCT customer_id, order_date,product_name
FROM table1
WHERE Rank1=1;

/* 8. What is the total items and amount spent for each member before they became a member?*/
WITH table1 AS
(SELECT s.customer_id, s.product_id,s.order_date,m.join_date, p.product_name, p.price
FROM sales s
JOIN members m
ON s.customer_id=m.customer_id
JOIN menu p
ON s.product_id=p.product_id
WHERE s.order_date <m.join_date)
SELECT customer_id, COUNT(DISTINCT product_name), SUM(price)
FROM table1
GROUP BY customer_id;

/* 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
how many points would each customer have?*/
WITH table2 AS
(WITH table1 AS
(SELECT s.customer_id, s.product_id, p.product_name,p.price
FROM sales s
JOIN menu p
ON s.product_id=p.product_id)
SELECT customer_id,
CASE
WHEN
product_name=LOWER ('sushi') THEN price*10*2
ELSE price*10
END AS points
FROM table1)
SELECT customer_id, SUM(points) AS total_points
FROM table2
GROUP BY customer_id
ORDER BY customer_id;

/*10. In the first week after a customer joins the program (including their join date) they earn 2x points
on all items, not just sushi - how many points do customer A and B have at the end of January?*/
WITH table2 AS
(WITH table1 AS
(SELECT s.customer_id,s.order_date, m.join_date,p.product_name,p.price
FROM sales s
JOIN menu p
ON s.product_id=p.product_id
JOIN members m
ON s.customer_id=m.customer_id
WHERE s.order_date<'2021-01-31') --end of January
SELECT customer_id, order_date,product_name,price,
CASE
WHEN product_name=LOWER('sushi') THEN price*10*2 --sushi always gets price*10*2 points
WHEN order_date BETWEEN join_date AND join_date+6 THEN price*10*2 --1st wk after and including join_date price*10*2 points
ELSE price*10 -- all other criteria price*10 points
END AS points
FROM table1)
SELECT customer_id, SUM (points)
FROM table2
GROUP BY customer_id
ORDER BY customer_id;

--Bonus Questions:
--1.JOIN tables

WITH table1 AS
(SELECT s.customer_id,s.order_date,p.product_name,p.price,m.join_date
FROM sales s
INNER JOIN menu p
ON s.product_id=p.product_id
LEFT JOIN members m
ON s.customer_id=m.customer_id
ORDER BY s.customer_id,s.order_date, p.product_name)
SELECT customer_id,order_date,product_name,price,
CASE
WHEN order_date>=join_date THEN 'Y'
ELSE 'N'
END AS member
FROM table1

/*2.Danny also requires further information about the ranking of customer products, 
but he purposely does not need the ranking for non-member purchases so he expects null ranking values 
for the records when customers are not yet part of the loyalty program.*/

WITH table2 AS
(WITH table1 AS
(SELECT s.customer_id,s.order_date,p.product_name,p.price,m.join_date
FROM sales s
INNER JOIN menu p
ON s.product_id=p.product_id
LEFT JOIN members m
ON s.customer_id=m.customer_id
ORDER BY s.customer_id,s.order_date, p.product_name)
SELECT customer_id,order_date,product_name,price,
CASE
WHEN order_date>=join_date THEN 'Y'
ELSE 'N'
END AS member
FROM table1)
SELECT customer_id,order_date,product_name,price,member,
CASE
WHEN member='N' THEN NULL
ELSE
DENSE_RANK()OVER(PARTITION BY customer_id,member ORDER BY order_date)
END AS ranking
FROM table2
