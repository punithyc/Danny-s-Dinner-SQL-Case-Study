# Danny-s-Dinner-SQL-Case-Study
## Intoduction

Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.<br>
Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

## Problem Statement

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.<br>
He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.<br>
Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!<br>

Danny has shared with you 3 key datasets for this case study:<br>
* *__Sales__*
* *__Menu__*
* *__Members__*

![relationship diagram](https://github.com/punithyc/Danny-s-Dinner-SQL-Case-Study/assets/123263654/ad9f59b6-0943-4ee6-a765-75335522cf2f)

## Technologies used
* *__Mysql__*

## Case study questions
* 1.What is the total amount each customer spent at the restaurant?<br>
* 2.How many days has each customer visited the restaurant?<br>
* 3.What was the first item from the menu purchased by each customer?<br>
* 4.What is the most purchased item on the menu and how many times was it purchased by all customers?<br>
* 5.Which item was the most popular for each customer?<br>
* 6.item was purchased first by the customer after they became a member?<br>
* 7.Which item was purchased just before the customer became a member?<br>
* 8.What is the total items and amount spent for each member before they became a member?<br>
* 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?<br>
* 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?<br>

## Bonus Questions
* 1.Join All The Things
* 2.Rank All The Things

## Case study Analysis using Mysql
  *__1.What is the total amount each customer spent at the restaurant?__*
  ```
   select  s.customer_id,sum(m.price) as total
   from sales as s join menu as m on s.product_id=m.product_id
   group by s.customer_id
```
  *__2.How many days has each customer visited the restaurant?__*
  ```
   select customer_id,count(distinct order_date) as days
   from sales
   group by customer_id
```
  
  *__3.What was the first item from the menu purchased by each customer?__*
  ```
with cte as(SELECT s.customer_id, s.order_date, m.product_name, 
  dense_rank() OVER(partition by s.customer_id ORDER BY s.order_date) as rnk
  FROM sales s 
  JOIN menu m 
  ON s.product_id = m.product_id)
  select customer_id,group_concat(product_name) from cte 
  where rnk=1
  group by customer_id
```
  *__4.What is the most purchased item on the menu and how many times was it purchased by all customers?__*
  ```
select m.product_name,count(m.product_name) as total
from sales as s inner join menu as m ON s.product_id = m.product_id
group by m.product_name
order by total desc
limit 1
```
  *__5.Which item was the most popular for each customer?__*
```
with cte as(select s.customer_id,m.product_name,count(m.product_name) cnt
from sales as s join menu as m on  s.product_id = m.product_id
group by customer_id,product_name),
cte2 as(
select *,dense_rank() over(partition by customer_id order by cnt desc) as popular from cte)
select customer_id,group_concat(product_name) from cte2 
where popular =1
group by customer_id
```
  *__6.item was purchased first by the customer after they became a member?__*
```
select customer_id,product_name 
from(select s.*,me.join_date,m.product_name,dense_rank() over(partition by customer_id order by order_date) as fst 
from sales as s join  members as me on s.customer_id=me.customer_id join menu as m on s.product_id=m.product_id
where s.order_date>me.join_date) s
where fst=1
```
  *__7.Which item was purchased just before the customer became a member?__*
  ```
select customer_id,group_concat(product_name)
from(select s.*,me.join_date,m.product_name,dense_rank() over(partition by customer_id order by order_date) as fst
from sales as s join  members as me on s.customer_id=me.customer_id join menu as m on s.product_id=m.product_id
where s.order_date<me.join_date) as s
 where fst =1
 group by customer_id
```
  *__8.What is the total items and amount spent for each member before they became a member?__*
  ```
select s.customer_id,sum(m.price) as amount_spent,count(product_name) as total
from sales as s join  members as me on s.customer_id=me.customer_id join menu as m on s.product_id=m.product_id
where s.order_date<me.join_date
group by s.customer_id
```

  *__9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?__*
  ```
with cte as(select *,case when product_id= 1 then price*20 else price*10 end as points from menu)
SELECT s.customer_id, SUM(c.points) AS total_points 
FROM cte c
JOIN sales s 
ON s.product_id = c.product_id
group by customer_id
```
  *__10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?__*
  ```
with cte as(select s.*,me.join_date,m.price
from sales as s join menu as m on s.product_id=m.product_id join members as me on me.customer_id=s.customer_id
where s.order_date>me.join_date and month(order_date)=1),
cte2 as(select *,case when timestampdiff(day,join_date,order_date)<=7 then price*20 else 0 end as points from cte)
select customer_id,sum(points) from cte2
group by customer_id
```
## Bonus questions queries
*__1.Join All The Things__*
```
SELECT s.customer_id, s.order_date, m.product_name, m.price, 
CASE WHEN s.order_date >= mem.join_date THEN 'Y'
     WHEN s.order_date < mem.join_date THEN 'N'  
     ELSE 'N' 
     END AS member 
FROM sales s 
LEFT JOIN menu m ON s.product_id = m.product_id 
LEFT JOIN members mem 
ON s.customer_id = mem.customer_id ;
```

*__2.Rank All The Things__*
```
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
```

## Conclusion
The analysis of Danny's Dinner case study through SQL has provided valuable insights into various aspects of the business. By querying the database, I've been able to uncover crucial information regarding sales trends, customer preferences, popular items, and more<br>
This demonstrated the power of utilizing data to drive business strategies, enhance customer satisfaction, and ultimately improve the overall performance of Danny's Dinner Restaurant.

## Resources
*__For more details__*:[Case study](https://8weeksqlchallenge.com/case-study-1/)

## For any queries/doubts
*__Connect here__*:[Linkedin](https://www.linkedin.com/in/punith-yc-2240b6267/)   [Leetcode](https://leetcode.com/punithyc8688/)   [HackerRank](https://www.hackerrank.com/profile/punithyc8688)  [GitHub](https://github.com/punithyc)

