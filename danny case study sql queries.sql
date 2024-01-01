CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
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
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INT
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  -- 1. What is the total amount each customer spent at the restaurant?
      select  s.customer_id,sum(m.price) as total from sales as s join menu as m on s.product_id=m.product_id
      group by s.customer_id
      
-- 2. How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) as days from sales
group by customer_id

-- 3. What was the first item from the menu purchased by each customer?
 with cte as(SELECT s.customer_id, s.order_date, m.product_name, 
  dense_rank() OVER(partition by s.customer_id ORDER BY s.order_date) as rnk
  FROM sales s 
  JOIN menu m 
  ON s.product_id = m.product_id)
  select customer_id,group_concat(product_name) from cte 
  where rnk=1
  group by customer_id
  
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name,count(m.product_name) as total from sales as s inner join menu as m ON s.product_id = m.product_id
group by m.product_name
order by total desc
limit 1

-- 5. Which item was the most popular for each customer?
with cte as(select s.customer_id,m.product_name,count(m.product_name) cnt from sales as s join menu as m on  s.product_id = m.product_id
group by customer_id,product_name),
cte2 as(
select *,dense_rank() over(partition by customer_id order by cnt desc) as popular from cte)
select customer_id,group_concat(product_name) from cte2 
where popular =1
group by customer_id

-- 6. Which item was purchased first by the customer after they became a member?
select customer_id,product_name from(select s.*,me.join_date,m.product_name,dense_rank() over(partition by customer_id order by order_date) as fst from sales as s join  members as me on s.customer_id=me.customer_id join menu as m on s.product_id=m.product_id
where s.order_date>me.join_date) s
where fst=1


-- 7. Which item was purchased just before the customer became a member?
select customer_id,group_concat(product_name) from(select s.*,me.join_date,m.product_name,dense_rank() over(partition by customer_id order by order_date) as fst from sales as s join  members as me on s.customer_id=me.customer_id join menu as m on s.product_id=m.product_id
where s.order_date<me.join_date) as s
 where fst =1
 group by customer_id

-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id,sum(m.price) as amount_spent,count(product_name) as total from sales as s join  members as me on s.customer_id=me.customer_id join menu as m on s.product_id=m.product_id
where s.order_date<me.join_date
group by s.customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with cte as(select *,case when product_id= 1 then price*20 else price*10 end as points from menu)
SELECT s.customer_id, SUM(c.points) AS total_points 
FROM cte c
JOIN sales s 
ON s.product_id = c.product_id
group by customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with cte as(select s.*,me.join_date,m.price from sales as s join menu as m on s.product_id=m.product_id join members as me on me.customer_id=s.customer_id
where s.order_date>me.join_date and month(order_date)=1),
cte2 as(select *,case when timestampdiff(day,join_date,order_date)<=7 then price*20 else 0 end as points from cte)
select customer_id,sum(points) from cte2
group by customer_id




-- Bonus Question : Join all the things 

SELECT s.customer_id, s.order_date, m.product_name, m.price, 
CASE WHEN s.order_date >= mem.join_date THEN 'Y'
     WHEN s.order_date < mem.join_date THEN 'N'  
     ELSE 'N' 
     END AS member 
FROM sales s 
LEFT JOIN menu m ON s.product_id = m.product_id 
LEFT JOIN members mem 
ON s.customer_id = mem.customer_id ;

-- Bonus Question : Rank all the things 

WITH cte_bonus AS(
 SELECT s.customer_id, s.order_date, m.product_name, m.price, 
  CASE WHEN s.order_date >= mem.join_date THEN 'Y'
       WHEN s.order_date < mem.join_date THEN 'N'  
       ELSE 'N' 
       END AS member 
FROM sales s 
LEFT JOIN menu m ON s.product_id = m.product_id 
LEFT JOIN members mem 
ON s.customer_id = mem.customer_id) 

select *, 
CASE WHEN member = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date)
ELSE 'Null'
END AS ranking 
from cte_bonus 



