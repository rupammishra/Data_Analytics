--After importing CSV files into DB
select * from dbo.pizzas;
select * from [dbo].[pizza_types]
select * from dbo.orders
select * from [dbo].[order_details]


--##################################################Basic:###########################################################################

--Retrieve the total number of orders placed.

select count(order_id) as total_orders_placed
from dbo.orders

--Calculate the total revenue generated from pizza sales.

select sum(a.quantity*b.price) as total_revenue
from dbo.order_details a inner join dbo.pizzas b
on a.pizza_id = b.pizza_id 


--Identify the highest-priced pizza.

select top 1 pizza_id,pizza_type_id,size,price
from dbo.pizzas
order by price desc

--Identify the most common pizza size ordered.


select top 1 b.size as most_common_ordered_size , sum(a.quantity) as order_qty
from dbo.order_details a inner join dbo.pizzas b
on a.pizza_id = b.pizza_id 
group by b.size
order by sum(a.quantity) desc

--List the top 5 most ordered pizza types along with their quantities.

select  top 5 c.pizza_type_id,c.name , sum(a.quantity) as order_qty
from dbo.order_details a 
inner join dbo.pizzas b on a.pizza_id = b.pizza_id 
inner join [dbo].[pizza_types] c on b.pizza_type_id = c.pizza_type_id
group by c.pizza_type_id,c.name
order by sum(a.quantity) desc


--#############################################################Intermediate:#########################################################################

--Join the necessary tables to find the total quantity of each pizza category ordered.

select  c.category, sum(a.quantity) as order_qty
from dbo.order_details a 
inner join dbo.pizzas b on a.pizza_id = b.pizza_id 
inner join [dbo].[pizza_types] c on b.pizza_type_id = c.pizza_type_id
group by c.category

--Determine the distribution of orders by hour of the day.

with cte as(
select count(order_id) as orders_num, DATEPART(hour,[time]) as [hour]
from dbo.orders
group by [time]
)
select sum(orders_num) as order_count ,[hour]
from cte
group by [hour]
order by [hour] 


--Join relevant tables to find the category-wise distribution of pizzas.

select b.category, count(b.name) as num_of_pizzas
from  [dbo].[pizza_types] b 
group by b.category

--Group the orders by date and calculate the average number of pizzas ordered per day.

with cte as(
select a.[date], sum(b.quantity)*1.0 as order_qty
from dbo.orders a
inner join [dbo].[order_details] b on a.order_id = b.order_id
group by a.[date])

select avg(order_qty) from cte

--Determine the top 3 most ordered pizza types based on revenue.

with cte as
(
select a.pizza_id, c.name,(sum(a.quantity)*b.price) as revenue
from dbo.order_details a 
inner join dbo.pizzas b on a.pizza_id = b.pizza_id 
inner join dbo.pizza_types c on b.pizza_type_id = c.pizza_type_id
group by a.pizza_id,a.quantity,b.price,c.name
)

select top 3 name, sum(revenue) as Total_Revenue_by_Pizza
from cte
group by name
order by Total_Revenue_by_Pizza desc

--#####################################################Advanced:#####################################################################

--Calculate the percentage contribution of each pizza type to total revenue.

with cte as(
select c.category,((sum(a.quantity*b.price) /
(select sum(a.quantity*b.price) as amount from dbo.order_details a inner join dbo.pizzas b on a.pizza_id = b.pizza_id ))*100) as percent_contribution
from dbo.order_details a inner join dbo.pizzas b
on a.pizza_id = b.pizza_id 
inner join dbo.pizza_types c
on b.pizza_type_id = c.pizza_type_id
group by c.category)

select * 
from cte
order by 1

--Analyze the cumulative revenue generated over time.

select 
    distinct c.date,
    SUM(a.price*b.quantity) OVER (ORDER BY c.date) AS CumulativeRevenue
	FROM dbo.pizzas a inner join dbo.order_details b
	on a.pizza_id = b.pizza_id
	inner join dbo.orders c
	on b.order_id = c.order_id
	order BY c.date;

--Determine the top 3 most ordered pizza types based on revenue for each pizza category.

with cte as (
select b.category,b.name,
sum(c.quantity*a.price) as revenue,
rank() over (partition by b.category order by (sum(c.quantity*a.price)) desc) as rnk
from dbo.pizzas a
inner join dbo.pizza_types b on a.pizza_type_id = b.pizza_type_id
inner join dbo.order_details c on a.pizza_id = c.pizza_id
inner join dbo.orders d on c.order_id = d.order_id
group by b.category,b.name)

select category, name, revenue 
from cte 
where rnk in (1,2,3)