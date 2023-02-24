-- Total amount each customer spent at the restaurant
SELECT 
  s.customer_id, 
  SUM(m.price) AS [Total Amount Spent] 
FROM 
  dbo.sales s 
  LEFT JOIN dbo.menu m ON s.product_id = m.product_id 
GROUP BY 
  s.customer_id;



-- Number of days each customer visited the restaurant
SELECT 
  customer_id, 
  COUNT(
    DISTINCT(order_date)
  ) AS [Number of Days Visited] 
FROM 
  dbo.sales 
GROUP BY 
  customer_id;



--First item from the menu purchased by each customer
WITH item_rank AS (
  SELECT 
    s.customer_id, 
    s.order_date, 
    m.product_name, 
    RANK() OVER(
      PARTITION BY s.customer_id 
      ORDER BY 
        s.order_date
    ) AS Rank 
  FROM 
    dbo.sales s 
    LEFT JOIN dbo.menu m ON s.product_id = m.product_id
) 
SELECT 
  DISTINCT customer_id, 
  product_name, 
  order_date 
FROM 
  item_rank 
WHERE 
  Rank = 1;



-- Most Purchased item on the menu and number of times it was purchased by each customer
SELECT 
  TOP 1 m.product_name, 
  COUNT(s.product_id) AS [No of Times Purchased] 
FROM 
  dbo.sales s 
  LEFT JOIN dbo.menu m ON s.product_id = m.product_id 
GROUP BY 
  m.product_name 
ORDER BY 
  [No of Times Purchased] DESC;



-- Most Popular item for each customer
WITH ranked_list AS(
  SELECT 
    DISTINCT s.customer_id, 
    m.product_name, 
    COUNT(s.product_id) AS [No of Times Purchased], 
    RANK() OVER(
      PARTITION BY customer_id 
      ORDER BY 
        COUNT(s.product_id) DESC
    ) AS Rank 
  FROM 
    dbo.sales s 
    LEFT JOIN dbo.menu m ON s.product_id = m.product_id 
  GROUP BY 
    s.customer_id, 
    m.product_name
) 
SELECT 
  customer_id, 
  product_name, 
  [No of Times Purchased] 
FROM 
  ranked_list 
WHERE 
  Rank = 1;



-- First item purchased by customer after they became member
WITH list AS (
  SELECT 
    s.customer_id, 
    m.product_name, 
    s.order_date, 
    mb.join_date, 
    RANK() OVER(
      PARTITION BY s.customer_id 
      ORDER BY 
        order_date
    ) AS Rank 
  FROM 
    dbo.sales s 
    RIGHT JOIN dbo.members mb ON mb.customer_id = s.customer_id 
    LEFT JOIN dbo.menu m ON m.product_id = s.product_id 
  WHERE 
    mb.join_date <= s.order_date
) 
SELECT 
  customer_id, 
  product_name, 
  order_date 
FROM 
  list 
WHERE 
  Rank = 1;



-- Last item purchased by the customers before becoming members
WITH list AS (
  SELECT 
    s.customer_id, 
    m.product_name, 
    s.order_date, 
    mb.join_date, 
    RANK() OVER(
      PARTITION BY s.customer_id 
      ORDER BY 
        order_date DESC
    ) AS Rank 
  FROM 
    dbo.sales s 
    RIGHT JOIN dbo.members mb ON mb.customer_id = s.customer_id 
    LEFT JOIN dbo.menu m ON m.product_id = s.product_id 
  WHERE 
    s.order_date < mb.join_date
) 
SELECT 
  customer_id, 
  product_name, 
  order_date 
FROM 
  list 
WHERE 
  Rank = 1;



-- Total items and amount spent for each member before they became members
SELECT 
  s.customer_id, 
  COUNT(DISTINCT m.product_id) AS [Total Items], 
  SUM(m.price) AS [Total Amount Spent] 
FROM 
  dbo.sales s 
  RIGHT JOIN dbo.members mb ON mb.customer_id = s.customer_id 
  LEFT JOIN dbo.menu m ON m.product_id = s.product_id 
WHERE 
  s.order_date < mb.join_date 
GROUP BY 
  s.customer_id;



-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
  DISTINCT s.customer_id, 
  SUM(
    CASE WHEN m.product_name = 'sushi' THEN m.price * 10 * 2 
		 ELSE m.price * 10 
		 END
  ) AS points 
FROM 
  dbo.menu m 
  JOIN dbo.sales s ON s.product_id = m.product_id 
GROUP BY 
  s.customer_id;



-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?
SELECT 
  DISTINCT s.customer_id, 
  SUM(
    CASE WHEN s.order_date BETWEEN mb.join_date AND DATEADD(DAY, 7, mb.join_date) THEN m.price * 10 * 2 
		 WHEN s.order_date NOT BETWEEN mb.join_date AND DATEADD(DAY, 7, mb.join_date) AND m.product_name = 'sushi' THEN m.price * 10 * 2
		 WHEN s.order_date NOT BETWEEN mb.join_date AND DATEADD(DAY, 7, mb.join_date) AND m.product_name <> 'sushi' THEN m.price * 10 
		 END
  ) AS points 
FROM 
  dbo.sales s 
  RIGHT JOIN dbo.members mb ON mb.customer_id = s.customer_id 
  LEFT JOIN dbo.menu m ON m.product_id = s.product_id 
WHERE  
  s.order_date <= '2021-01-31' 
GROUP BY 
  s.customer_id;



-- Bonus Questions

-- Recreating the Table (Join All The Things)
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE WHEN s.order_date < mb.join_date THEN 'N'
	 WHEN s.order_date >= mb.join_date THEN 'Y'
	 ELSE 'N' END AS member
INTO updated_customers
FROM dbo.sales s
RIGHT JOIN dbo.menu m ON s.product_id = m.product_id
LEFT JOIN dbo.members mb ON s.customer_id = mb.customer_id
WHERE MONTH(s.order_date) = 1
ORDER BY s.customer_id, s.order_date, m.product_name;

SELECT * FROM updated_customers;


-- Recreating the Table (Rank All The Things)
SELECT *, 
CASE WHEN member = 'Y' THEN RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) END AS ranking
FROM updated_customers;