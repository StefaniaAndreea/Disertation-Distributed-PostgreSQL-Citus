--1.
SELECT
 s.s_state,
  s.s_store_id,
  SUM(ss.ss_net_paid) AS revenue
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s    ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year = 2000
GROUP BY s.s_state, s.s_store_id
ORDER BY revenue DESC
LIMIT 20;
--2.
SELECT
  d.d_year,
  i.i_category,
  SUM(ss.ss_net_paid) AS revenue,
  COUNT(*) AS line_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i     ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, i.i_category
ORDER BY revenue DESC;
--3.
SELECT
  ca.ca_state,
  COUNT(DISTINCT c.c_customer_sk) AS nr_of_customers
FROM store_sales ss
JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c          ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2000
GROUP BY ca.ca_state
ORDER BY nr_of_customers DESC
LIMIT 25;
--4.
SELECT
  w.web_site_id,
  d.d_year AS date_year,
  d.d_moy as date_month,
  ca.ca_state,
  i.i_category,
  SUM(ws.ws_net_paid) AS revenue
FROM web_sales ws
JOIN date_dim d          ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site w          ON ws.ws_web_site_sk  = w.web_site_sk
JOIN item i              ON ws.ws_item_sk      = i.i_item_sk
JOIN customer c          ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk    = ca.ca_address_sk
WHERE d.d_year = 2000
GROUP BY w.web_site_id, d.d_year, d.d_moy, ca.ca_state, i.i_category
ORDER BY revenue DESC, w.web_site_id, d.d_moy;
--5.
SELECT
  s.s_store_id,
  SUM(ss.ss_net_paid) - COALESCE(SUM(sr.sr_return_amt), 0) AS net_revenue
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk       = ss.ss_item_sk
 AND sr.sr_store_sk      = ss.ss_store_sk
 AND sr.sr_customer_sk   = ss.ss_customer_sk
WHERE d.d_year = 2000
GROUP BY s.s_store_id
ORDER BY net_revenue DESC;
--6.
SELECT
  w.w_warehouse_name,
  d.d_year as date_year,
  d.d_moy as date_month,
  i.i_category,
  AVG(inv.inv_quantity_on_hand) AS avg_qoh
FROM inventory inv
JOIN date_dim d   ON inv.inv_date_sk = d.d_date_sk
JOIN item i       ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w  ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year between 2000 and 2005
GROUP BY w.w_warehouse_name, d.d_year, d.d_moy, i.i_category
ORDER BY d_year,d_moy,avg_qoh ASC, w.w_warehouse_name, i.i_category;
--7.
SELECT
  r.r_reason_desc,
  COUNT(*) AS return_lines,
  SUM(sr.sr_return_amt) AS total_return_amt
FROM store_returns sr
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
GROUP BY r.r_reason_desc
ORDER BY total_return_amt DESC, return_lines DESC
LIMIT 5;
--8.
SELECT
  ca.ca_state,
  cd.cd_gender,
  cd.cd_marital_status,
  COUNT(*) AS nr_of_customers
FROM customer c
JOIN customer_address ca      ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE ca.ca_state = 'CA'
  AND cd.cd_gender IN ('M','F')
GROUP BY ca.ca_state, cd.cd_gender, cd.cd_marital_status
ORDER BY nr_of_customers DESC;
--9.
SELECT
  sm.sm_type,
  COUNT(*) AS nr_orders
FROM web_sales ws
JOIN date_dim dsold ON ws.ws_sold_date_sk = dsold.d_date_sk
JOIN date_dim dship ON ws.ws_ship_date_sk = dship.d_date_sk
JOIN ship_mode sm   ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE dsold.d_year = 2000
  AND (dship.d_date - dsold.d_date) > 7
GROUP BY sm.sm_type
ORDER BY nr_orders DESC, sm.sm_type;
--10.
SELECT
  i.i_category,
  i.i_item_id,
  r.ret_qty
FROM (
  SELECT
    sr.sr_item_sk,
    SUM(sr.sr_return_quantity) AS ret_qty
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
  GROUP BY sr.sr_item_sk
) r
JOIN item i ON r.sr_item_sk = i.i_item_sk
WHERE r.ret_qty >
  (
    SELECT AVG(t.ret_qty)
    FROM (
      SELECT
        sr2.sr_item_sk,
        SUM(sr2.sr_return_quantity) AS ret_qty
      FROM store_returns sr2
      JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
      WHERE d2.d_year = 2000
      GROUP BY sr2.sr_item_sk
    ) t
  )
ORDER BY r.ret_qty DESC;
--11.
SELECT DISTINCT ws.ws_bill_customer_sk
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000
EXCEPT
SELECT DISTINCT ss.ss_customer_sk
FROM store_sales ss
JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
WHERE d2.d_year = 2000;
--12.
SELECT c.c_customer_sk
FROM customer c
JOIN (
  SELECT DISTINCT ws.ws_bill_customer_sk AS customer_sk
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
    AND ws.ws_bill_customer_sk IS NOT NULL
  EXCEPT
  SELECT DISTINCT ss.ss_customer_sk
  FROM store_sales ss
  JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
  WHERE d2.d_year = 2000
    AND ss.ss_customer_sk IS NOT NULL
) x ON x.customer_sk = c.c_customer_sk;
--13.
SELECT
  c.c_customer_sk
FROM customer c
WHERE EXISTS (
  SELECT ws.ws_bill_customer_sk
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
    AND ws.ws_bill_customer_sk = c.c_customer_sk
)
AND NOT EXISTS (
  SELECT ss.ss_customer_sk
  FROM store_sales ss
  JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
  WHERE d2.d_year = 2000
    AND ss.ss_customer_sk = c.c_customer_sk
);
--14.
SELECT
  s.s_store_id,
  r.r_reason_desc,
  COUNT(*) AS return_lines,
  SUM(sr.sr_return_amt) AS total_return_amt
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r   ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year BETWEEN 1998 AND 2001
GROUP BY s.s_store_id, r.r_reason_desc
ORDER BY total_return_amt DESC, return_lines DESC;
--15.
SELECT
  r.r_reason_desc,
  COUNT(*) AS return_lines,
  SUM(sr.sr_return_amt) AS total_return_amt
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r   ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year BETWEEN 1998 AND 2001
GROUP BY r.r_reason_desc
ORDER BY total_return_amt DESC, return_lines DESC
LIMIT 5;
--16.
SELECT
  cc.cc_name,
  sm.sm_type,
  COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
  AVG(cs.cs_ext_ship_cost) AS avg_ship_cost
FROM catalog_sales cs
JOIN date_dim d   ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm   ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
GROUP BY cc.cc_name, sm.sm_type
ORDER BY orders_cnt DESC, avg_ship_cost DESC;
--17.
SELECT
  p.p_promo_id,
  p.p_channel_email,
  p.p_channel_catalog,
  SUM(ss.ss_ext_discount_amt) AS total_discount,
  SUM(ss.ss_ext_sales_price)  AS total_sales_price,
  CAST(SUM(ss.ss_ext_discount_amt) AS numeric)
    / NULLIF(CAST(SUM(ss.ss_ext_sales_price) AS numeric), 0) AS discount_rate,
  COUNT(*) AS line_cnt
FROM store_sales ss
JOIN date_dim d  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk     = p.p_promo_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY p.p_promo_id, p.p_channel_email, p.p_channel_catalog
HAVING
  CAST(SUM(ss.ss_ext_discount_amt) AS numeric)
    / NULLIF(CAST(SUM(ss.ss_ext_sales_price) AS numeric), 0)
  >
  (
    SELECT
      CAST(SUM(ss2.ss_ext_discount_amt) AS numeric)
        / NULLIF(CAST(SUM(ss2.ss_ext_sales_price) AS numeric), 0)
    FROM store_sales ss2
    JOIN date_dim d2  ON ss2.ss_sold_date_sk = d2.d_date_sk
    JOIN promotion p2 ON ss2.ss_promo_sk     = p2.p_promo_sk
    WHERE d2.d_year BETWEEN 1999 AND 2002
  )
ORDER BY discount_rate DESC, total_discount DESC
LIMIT 50;
--18.
WITH global_avg AS (
  SELECT
    CAST(SUM(ss2.ss_ext_discount_amt) AS numeric)
      / NULLIF(CAST(SUM(ss2.ss_ext_sales_price) AS numeric), 0) AS global_discount_rate
  FROM store_sales ss2
  JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
  WHERE d2.d_year BETWEEN 1999 AND 2002
)
SELECT
  p.p_promo_id,
  p.p_channel_email,
  p.p_channel_catalog,
  SUM(ss.ss_ext_discount_amt) AS total_discount,
  SUM(ss.ss_ext_sales_price)  AS total_sales_price,
  CAST(SUM(ss.ss_ext_discount_amt) AS numeric)
    / NULLIF(CAST(SUM(ss.ss_ext_sales_price) AS numeric), 0) AS discount_rate,
  ga.global_discount_rate,
  (CAST(SUM(ss.ss_ext_discount_amt) AS numeric)
    / NULLIF(CAST(SUM(ss.ss_ext_sales_price) AS numeric), 0)) - ga.global_discount_rate AS discount_rate_delta,
  COUNT(*) AS line_cnt
FROM store_sales ss
JOIN date_dim d  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk     = p.p_promo_sk
CROSS JOIN global_avg ga
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY p.p_promo_id, p.p_channel_email, p.p_channel_catalog, ga.global_discount_rate
HAVING
  CAST(SUM(ss.ss_ext_discount_amt) AS numeric)
    / NULLIF(CAST(SUM(ss.ss_ext_sales_price) AS numeric), 0)
  > ga.global_discount_rate
ORDER BY discount_rate DESC, total_discount DESC
LIMIT 50;
--19.
SELECT
  ca.ca_state,
  cd.cd_gender,
  COUNT(*) AS customers
FROM customer c
JOIN customer_address ca      ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE ca.ca_state LIKE 'C%'
  AND cd.cd_gender IN ('M','F')
GROUP BY ca.ca_state, cd.cd_gender
ORDER BY customers DESC, ca.ca_state, cd.cd_gender;
--20.
SELECT
  i.i_category,
  i.i_item_id,
  r.ret_qty
FROM (
  SELECT
    sr.sr_item_sk,
    SUM(sr.sr_return_quantity) AS ret_qty
  FROM store_returns sr
  GROUP BY sr.sr_item_sk
) r
JOIN item i ON r.sr_item_sk = i.i_item_sk
WHERE r.ret_qty >
  (
    SELECT AVG(t.ret_qty)
    FROM (
      SELECT
        sr2.sr_item_sk,
        SUM(sr2.sr_return_quantity) AS ret_qty
      FROM store_returns sr2
      GROUP BY sr2.sr_item_sk
    ) t
  )
ORDER BY r.ret_qty DESC
LIMIT 200;
--21.
SELECT 
    i.i_brand, 
    SUM(ss.ss_net_profit) as total_profit 
FROM store_sales ss 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE d.d_year = 2001 AND ss.ss_net_profit > 0 
GROUP BY i.i_brand 
ORDER BY total_profit DESC;

--22.
WITH yearly_sales AS (
    SELECT 
        d.d_year, 
        i.i_category, 
        SUM(ss.ss_net_paid) as sales 
    FROM store_sales ss 
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
    JOIN item i ON ss.ss_item_sk = i.i_item_sk 
    GROUP BY d.d_year, i.i_category
) 
SELECT 
    d_year, 
    i_category, 
    sales, 
    LAG(sales) OVER (PARTITION BY i_category ORDER BY d_year) as prev_year_sales 
FROM yearly_sales 
ORDER BY i_category, d_year;

--23.
SELECT * FROM (
    SELECT 
        i.i_category, 
        i.i_item_desc, 
        SUM(ss.ss_quantity) as total_qty, 
        RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(ss.ss_quantity) DESC) as rank_in_cat 
    FROM store_sales ss 
    JOIN item i ON ss.ss_item_sk = i.i_item_sk 
    GROUP BY i.i_category, i.i_item_desc
) t 
WHERE rank_in_cat <= 3;

--24.
SELECT 
    i.i_item_desc, 
    w.w_warehouse_name, 
    SUM(ss.ss_quantity) as sold 
FROM store_sales ss 
JOIN inventory inv ON ss.ss_item_sk = inv.inv_item_sk 
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
WHERE inv.inv_quantity_on_hand = 0 
GROUP BY i.i_item_desc, w.w_warehouse_name ;
--25.
SELECT 
    s.s_store_name, 
    AVG(ticket_sum) as avg_ticket_value 
FROM (
    SELECT 
        ss_store_sk, 
        ss_ticket_number, 
        SUM(ss_net_paid) as ticket_sum 
    FROM store_sales 
    GROUP BY ss_store_sk, ss_ticket_number
) t 
JOIN store s ON t.ss_store_sk = s.s_store_sk 
GROUP BY s.s_store_name;
--26.
WITH client_sales AS (
    SELECT 
        ss_customer_sk, 
        SUM(ss_net_paid) as total_paid 
    FROM store_sales ss 
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
    WHERE d.d_year = 2001 
    GROUP BY ss_customer_sk
) 
SELECT 
    c.c_last_name, 
    cs.total_paid 
FROM client_sales cs 
JOIN customer c ON cs.ss_customer_sk = c.c_customer_sk 
WHERE cs.total_paid > 5000 
ORDER BY cs.total_paid DESC;

--27.
SELECT 
    d.d_year, 
    d.d_moy, 
    SUM(ss.ss_net_paid) as sales, 
    AVG(SUM(ss.ss_net_paid)) OVER (ORDER BY d.d_year, d.d_moy ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as moving_avg 
FROM store_sales ss 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE d.d_year BETWEEN 2000 AND 2001 
GROUP BY d.d_year, d.d_moy;

--28.
SELECT 
    i.i_item_sk, 
    i.i_product_name 
FROM item i 
WHERE i.i_item_sk NOT IN (
    SELECT ws_item_sk 
    FROM web_sales ws 
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    WHERE d.d_year = 2002
); 
--29.
SELECT 
    t.t_hour, 
    SUM(ss.ss_net_paid) as revenue 
FROM store_sales ss 
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE d.d_year = 2000 
  AND d.d_dow IN (6, 7) 
GROUP BY t.t_hour 
ORDER BY revenue DESC;
--30.
SELECT 
    customer_class, 
    COUNT(*) as customer_count 
FROM (
    SELECT 
        ss_customer_sk, 
        CASE 
            WHEN SUM(ss_net_paid) > 10000 THEN 'High Value' 
            WHEN SUM(ss_net_paid) > 1000 THEN 'Medium Value' 
            ELSE 'Low Value' 
        END as customer_class 
    FROM store_sales 
    GROUP BY ss_customer_sk
) t 
GROUP BY customer_class;

--31.
SELECT i.i_item_sk 
FROM item i 
WHERE i.i_item_sk IN (
    SELECT ss_item_sk FROM store_sales 
    INTERSECT 
    SELECT ws_item_sk FROM web_sales 
    INTERSECT 
    SELECT cs_item_sk FROM catalog_sales
) ;
--32.
SELECT 
    ca.ca_county, 
    SUM(cs.cs_net_profit) as total_profit 
FROM catalog_sales cs 
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk 
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk 
WHERE d.d_year = 2001 
GROUP BY ca.ca_county 
ORDER BY total_profit DESC 
LIMIT 10;
--33.
SELECT 
    w.w_warehouse_name, 
    SUM(inv.inv_quantity_on_hand * i.i_current_price) as inventory_value 
FROM inventory inv 
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk 
JOIN item i ON inv.inv_item_sk = i.i_item_sk 
GROUP BY w.w_warehouse_name 
ORDER BY inventory_value DESC;
--34.
WITH total_rev AS (
    SELECT SUM(ss_net_paid) as global_sum 
    FROM store_sales ss 
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
    WHERE d.d_year = 2000
) 
SELECT 
    i.i_item_desc, 
    SUM(ss.ss_net_paid) as item_rev 
FROM store_sales ss 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk, 
total_rev tr 
WHERE d.d_year = 2000 
GROUP BY i.i_item_desc, tr.global_sum 
HAVING SUM(ss.ss_net_paid) > (tr.global_sum * 0.0002);

--35.
SELECT 
    i.i_brand, 
    SUM(ss.ss_net_profit) as total_profit 
FROM store_sales ss 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE d.d_year = 2001 AND ss.ss_net_profit > 0 
GROUP BY i.i_brand 
ORDER BY total_profit DESC;

--36.
SELECT 
    basket_size, 
    COUNT(*) as total_orders 
FROM (
    SELECT 
        ss_ticket_number as order_id, 
        CASE 
            WHEN COUNT(ss_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(ss_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM store_sales 
    GROUP BY ss_ticket_number
    
    UNION ALL
    
    SELECT 
        ws_order_number as order_id, 
        CASE 
            WHEN COUNT(ws_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(ws_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM web_sales 
    GROUP BY ws_order_number
    
    UNION ALL
    

    SELECT 
        cs_order_number as order_id, 
        CASE 
            WHEN COUNT(cs_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(cs_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM catalog_sales 
    GROUP BY cs_order_number
) t 
GROUP BY basket_size 
ORDER BY total_orders DESC;

--37.
SELECT 
    channel, 
    basket_size, 
    COUNT(*) as total_orders, 
    AVG(order_amt) as avg_order_value 
FROM (

    SELECT 
        'Store' as channel, 
        ss_ticket_number, 
        SUM(ss_net_paid) as order_amt, 
        CASE 
            WHEN COUNT(ss_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(ss_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM store_sales ss 
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk 
    WHERE d.d_year = 2001 AND d.d_moy = 12 AND ca.ca_state = 'TX' 
    GROUP BY ss_ticket_number

    UNION ALL


    SELECT 
        'Web' as channel, 
        ws_order_number, 
        SUM(ws_net_paid) as order_amt, 
        CASE 
            WHEN COUNT(ws_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(ws_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM web_sales ws 
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk 
    WHERE d.d_year = 2001 AND d.d_moy = 12 AND ca.ca_state = 'TX' 
    GROUP BY ws_order_number

    UNION ALL

    SELECT 
        'Catalog' as channel, 
        cs_order_number, 
        SUM(cs_net_paid) as order_amt, 
        CASE 
            WHEN COUNT(cs_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(cs_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM catalog_sales cs 
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk 
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk 
    WHERE d.d_year = 2001 AND d.d_moy = 12 AND ca.ca_state = 'TX' 
    GROUP BY cs_order_number
) t 
GROUP BY channel, basket_size 
ORDER BY channel, total_orders DESC;
--38.
SELECT 
    channel, 
    basket_size, 
    COUNT(*) as total_orders, 
    AVG(order_amt) as avg_order_val, 
    AVG(promo_cost) as avg_promo_cost 
FROM (
    SELECT 
        'Store' as channel, 
        ss_ticket_number, 
        SUM(ss_net_paid) as order_amt, 
        SUM(COALESCE(p.p_cost, 0)) as promo_cost, 
        CASE 
            WHEN COUNT(ss_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(ss_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM store_sales ss 
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk 
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk 
    WHERE d.d_year = 2001 
      AND d.d_moy = 12 
      AND ca.ca_state = 'TX' 
      AND cd.cd_marital_status = 'M' 
    GROUP BY ss_ticket_number

    UNION ALL

    SELECT 
        'Web' as channel, 
        ws_order_number, 
        SUM(ws_net_paid) as order_amt, 
        SUM(COALESCE(p.p_cost, 0)) as promo_cost, 
        CASE 
            WHEN COUNT(ws_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(ws_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM web_sales ws 
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk 
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk 
    WHERE d.d_year = 2001 
      AND d.d_moy = 12 
      AND ca.ca_state = 'TX' 
      AND cd.cd_marital_status = 'M' 
    GROUP BY ws_order_number

    UNION ALL
    SELECT 
        'Catalog' as channel, 
        cs_order_number, 
        SUM(cs_net_paid) as order_amt, 
        SUM(COALESCE(p.p_cost, 0)) as promo_cost, 
        CASE 
            WHEN COUNT(cs_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(cs_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM catalog_sales cs 
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk 
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk 
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk 
    WHERE d.d_year = 2001 
      AND d.d_moy = 12 
      AND ca.ca_state = 'TX' 
      AND cd.cd_marital_status = 'M' 
    GROUP BY cs_order_number
) t 
GROUP BY channel, basket_size 
ORDER BY channel, total_orders DESC;

---39.
SELECT 
    channel, 
    basket_size, 
    COUNT(*) as total_orders, 
    AVG(order_amt) as avg_order_value 
FROM (
    SELECT 
        'Store' as channel, 
        ss_ticket_number, 
        SUM(ss_net_paid) as order_amt, 
        CASE 
            WHEN COUNT(ss_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(ss_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM store_sales ss 
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk 
    WHERE d.d_year = 2001 
      AND (d.d_moy % 2 = 1) -- Luni Impare
      AND ca.ca_state = 'TX' 
    GROUP BY ss_ticket_number

    UNION ALL

    SELECT 
        'Web' as channel, 
        ws_order_number, 
        SUM(ws_net_paid) as order_amt, 
        CASE 
            WHEN COUNT(ws_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(ws_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM web_sales ws 
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk 
    WHERE d.d_year = 2001 
      AND (d.d_moy % 2 = 1) 
      AND ca.ca_state = 'TX' 
    GROUP BY ws_order_number

    UNION ALL

    SELECT 
        'Catalog' as channel, 
        cs_order_number, 
        SUM(cs_net_paid) as order_amt, 
        CASE 
            WHEN COUNT(cs_item_sk) < 5 THEN 'Small' 
            WHEN COUNT(cs_item_sk) BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Large' 
        END as basket_size 
    FROM catalog_sales cs 
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk 
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk 
    WHERE d.d_year = 2001 
      AND (d.d_moy % 2 = 1) 
      AND ca.ca_state = 'TX' 
    GROUP BY cs_order_number
) t 
GROUP BY channel, basket_size 
ORDER BY channel, total_orders DESC;

--40.
SELECT 
    s.s_store_name, 
    d1.d_moy, 
    SUM(ss1.ss_net_paid) as sales_2000, 
    SUM(ss2.ss_net_paid) as sales_2001, 
    (SUM(ss2.ss_net_paid) - SUM(ss1.ss_net_paid)) as growth 
FROM store_sales ss1 
JOIN store_sales ss2 ON ss1.ss_store_sk = ss2.ss_store_sk 
    AND ss1.ss_item_sk = ss2.ss_item_sk 
JOIN date_dim d1 ON ss1.ss_sold_date_sk = d1.d_date_sk 
JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk 
JOIN store s ON ss1.ss_store_sk = s.s_store_sk 
WHERE d1.d_year = 2000 
  AND d2.d_year = 2001 
  AND d1.d_moy = d2.d_moy 
GROUP BY s.s_store_name, d1.d_moy 
ORDER BY s.s_store_name, d1.d_moy;

--41.
SELECT 
    c.c_customer_id, 
    c.c_last_name, 
    c.c_first_name, 
    SUM(ss.ss_net_paid) as total_store_spend 
FROM store_sales ss 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE d.d_year = 2000 
  AND ca.ca_state = 'TX' 
GROUP BY c.c_customer_id, c.c_last_name, c.c_first_name 
HAVING SUM(ss.ss_net_paid) > (
    SELECT AVG(ws.ws_net_paid) 
    FROM web_sales ws 
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk 
    WHERE d2.d_year = 2000
) 
ORDER BY total_store_spend DESC ;

--42.
WITH web AS (
    SELECT AVG(ws_net_paid) as avg_web_amt
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2000
)
SELECT 
    c.c_customer_id, 
    c.c_last_name, 
    c.c_first_name, 
    s.s_store_name,
    cd.cd_education_status,
    hd.hd_dep_count,
    SUM(ss.ss_net_paid) as total_store_spend 
FROM store_sales ss 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
JOIN store s ON ss.ss_store_sk = s.s_store_sk 
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk 
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
CROSS JOIN web wb 
WHERE d.d_year = 2000 
  AND ca.ca_state = 'TX' 
  AND cd.cd_education_status = 'Advanced Degree' 
  AND hd.hd_dep_count > 4                        
GROUP BY c.c_customer_id, c.c_last_name, c.c_first_name, s.s_store_name, cd.cd_education_status, hd.hd_dep_count, wb.avg_web_amt
HAVING SUM(ss.ss_net_paid) > wb.avg_web_amt
ORDER BY total_store_spend DESC 
LIMIT 100;

--43.
SELECT 
    s.s_store_name, 
    hd.hd_vehicle_count, 
    SUM(ss.ss_net_paid) as sales 
FROM store_sales ss 
JOIN store s ON ss.ss_store_sk = s.s_store_sk 
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
WHERE hd.hd_vehicle_count >= 2 
GROUP BY s.s_store_name, hd.hd_vehicle_count 
ORDER BY sales DESC;

--44.
WITH store_yearly_total AS (
    SELECT 
        ss.ss_store_sk,
        d.d_year,
        SUM(ss.ss_net_paid) as total_annual_revenue
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY ss.ss_store_sk, d.d_year
)
SELECT 
    d.d_year,
    s.s_store_name,
    hd.hd_vehicle_count,
    SUM(ss.ss_net_paid) as segment_sales,
    st.total_annual_revenue,
    (SUM(ss.ss_net_paid) / st.total_annual_revenue) * 100 as share_percentage
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store_yearly_total st ON ss.ss_store_sk = st.ss_store_sk AND d.d_year = st.d_year 
WHERE d.d_year BETWEEN 1999 AND 2001
  AND hd.hd_vehicle_count >= 2
GROUP BY d.d_year, s.s_store_name, hd.hd_vehicle_count, st.total_annual_revenue
ORDER BY s.s_store_name, d.d_year;

--45.
SELECT 
    c.c_last_name, 
    c.c_customer_sk, 
    COUNT(DISTINCT i.i_brand) as unique_brands 
FROM store_sales ss 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
GROUP BY c.c_last_name, c.c_customer_sk 
HAVING COUNT(DISTINCT i.i_brand) > 5 
ORDER BY unique_brands DESC;

--46.
SELECT 
    c.c_customer_sk,
    c.c_last_name, 
    c.c_first_name,
    ca.ca_state,
    COUNT(DISTINCT i.i_brand) as unique_brands,
    COUNT(DISTINCT i.i_category) as unique_categories,
    SUM(ss.ss_net_paid) as total_spend,
    AVG(ss.ss_net_paid) as avg_ticket_item
FROM store_sales ss 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2000 
  AND ca.ca_state IN ('TX', 'CA', 'NY', 'FL', 'IL') 
GROUP BY c.c_customer_sk, c.c_last_name, c.c_first_name, ca.ca_state 
HAVING COUNT(DISTINCT i.i_brand) > 10 
   AND COUNT(DISTINCT i.i_category) > 3
   AND SUM(ss.ss_net_paid) > 5000
ORDER BY unique_brands DESC, total_spend DESC ;

--47.
SELECT 
    c.c_customer_sk,
    c.c_last_name, 
    c.c_first_name,
    ca.ca_state,
    COUNT(DISTINCT i.i_brand) as unique_brands,
    COUNT(DISTINCT i.i_category) as unique_categories,
    SUM(ss.ss_net_paid) as total_spend
FROM store_sales ss 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2000 
  AND ca.ca_state IN (
      SELECT ca_s.ca_state
      FROM store_sales ss_s
      JOIN date_dim d_s ON ss_s.ss_sold_date_sk = d_s.d_date_sk
      JOIN customer c_s ON ss_s.ss_customer_sk = c_s.c_customer_sk
      JOIN customer_address ca_s ON c_s.c_current_addr_sk = ca_s.ca_address_sk
      WHERE d_s.d_year = 2000
      GROUP BY ca_s.ca_state
      ORDER BY SUM(ss_s.ss_net_paid) DESC
      LIMIT 5
  )
GROUP BY c.c_customer_sk, c.c_last_name, c.c_first_name, ca.ca_state 
HAVING COUNT(DISTINCT i.i_brand) > 10 
   AND COUNT(DISTINCT i.i_category) > 3
   AND SUM(ss.ss_net_paid) > 5000
ORDER BY unique_brands DESC, total_spend DESC;

--48.
SELECT 
    i.i_product_name, 
    SUM(ss.ss_net_paid) as total_sales, 
    SUM(sr.sr_return_amt) as total_returns, 
    (SUM(ss.ss_net_paid) - COALESCE(SUM(sr.sr_return_amt), 0)) as net_profit 
FROM store_sales ss 
JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE d.d_year = 2000 
GROUP BY i.i_product_name 
ORDER BY net_profit DESC 
LIMIT 100;

--49.
SELECT 
    i.i_product_name, 
    i.i_category,
    COUNT(DISTINCT ss.ss_ticket_number) as problematic_transactions,
    SUM(sr.sr_return_amt) as total_refunded,
    (SUM(sr.sr_return_amt) / NULLIF(SUM(ss.ss_net_paid), 0)) * 100 as return_rate_percent
FROM store_sales ss 
JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE d.d_year = 2000 
GROUP BY i.i_product_name, i.i_category
HAVING SUM(sr.sr_return_amt) > 1000 
ORDER BY total_refunded DESC 
LIMIT 100;

--50.
SELECT 
    c.c_last_name, 
    c.c_first_name, 
    i.i_item_desc, 
    ss.ss_net_paid 
FROM store_sales ss 
JOIN web_returns wr ON ss.ss_item_sk = wr.wr_item_sk AND ss.ss_customer_sk = wr.wr_refunded_customer_sk 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
WHERE ss.ss_net_paid > 100 
ORDER BY ss.ss_net_paid DESC 
LIMIT 100;

--51.
SELECT 
    s1.ss_customer_sk,
    d1.d_year,
    d1.d_moy,
    COUNT(DISTINCT s1.ss_store_sk) as stores_visited,
    COUNT(*) as total_transactions
FROM store_sales s1
JOIN date_dim d1 ON s1.ss_sold_date_sk = d1.d_date_sk
JOIN store_sales s2 ON s1.ss_customer_sk = s2.ss_customer_sk 
JOIN date_dim d2 ON s2.ss_sold_date_sk = d2.d_date_sk
WHERE d1.d_year = 2000 
  AND d2.d_year = 2000
  AND d1.d_moy = d2.d_moy          
  AND s1.ss_store_sk != s2.ss_store_sk 
GROUP BY s1.ss_customer_sk, d1.d_year, d1.d_moy
HAVING COUNT(DISTINCT s1.ss_store_sk) > 1
ORDER BY total_transactions DESC
LIMIT 100;


--52.
SELECT 
    c.c_customer_sk,
    (c.c_first_name || ' ' || c.c_last_name) as customer_name,
    SUM(COALESCE(cs.cs_net_paid, 0)) as spent_on_music
FROM catalog_sales cs
INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk AND d.d_year = 2001
INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk AND i.i_category = 'Music'
RIGHT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE c.c_birth_year BETWEEN 1970 AND 1975 
GROUP BY c.c_customer_sk, c.c_last_name, c.c_first_name
ORDER BY spent_on_music DESC, c.c_last_name;


--53.
SELECT 
    c.c_customer_sk,
    (c.c_first_name || ' ' || c.c_last_name) as customer_name,
    SUM(COALESCE(cs.cs_net_paid, 0)) as spent_on_music
FROM catalog_sales cs
INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk AND d.d_year = 2001
INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk AND i.i_category = 'Music'
RIGHT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE c.c_birth_year BETWEEN 1970 AND 1975 
GROUP BY c.c_customer_sk, c.c_last_name, c.c_first_name
HAVING SUM(COALESCE(cs.cs_net_paid, 0)) = 0
ORDER BY c.c_last_name, c.c_first_name;

--54.
WITH customer_visits AS (
    SELECT DISTINCT 
        ss.ss_customer_sk, 
        d.d_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2000 
),
visit_gaps AS (
    SELECT 
        ss_customer_sk,
        d_date,
        d_date - LAG(d_date, 1) OVER (PARTITION BY ss_customer_sk ORDER BY d_date) as days_since_last_visit
    FROM customer_visits
)
SELECT 
    c.c_customer_sk,
    (c.c_last_name || ' ' || c.c_first_name) as customer_name,
    COUNT(*) as total_visits,
    ROUND(AVG(days_since_last_visit), 1) as avg_days_between_shopping
FROM visit_gaps vg
JOIN customer c ON vg.ss_customer_sk = c.c_customer_sk
GROUP BY c.c_customer_sk, c.c_last_name, c.c_first_name
HAVING COUNT(*) > 1           
   AND AVG(days_since_last_visit) IS NOT NULL
ORDER BY total_visits DESC, avg_days_between_shopping DESC ;

--55.
SELECT 
    i1.i_product_name as product_A,
    i2.i_product_name as product_B,
    COUNT(*) as frequency
FROM store_sales s1
JOIN store_sales s2 ON s1.ss_ticket_number = s2.ss_ticket_number 
                   AND s1.ss_item_sk != s2.ss_item_sk           
                   AND s1.ss_item_sk < s2.ss_item_sk             
JOIN item i1 ON s1.ss_item_sk = i1.i_item_sk
JOIN item i2 ON s2.ss_item_sk = i2.i_item_sk
JOIN date_dim d ON s1.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000 
  AND d.d_moy = 12
GROUP BY i1.i_product_name, i2.i_product_name
ORDER BY frequency DESC;
--56.
SELECT * FROM (
    SELECT 
        s.s_store_name,
        i.i_product_name,
        SUM(ss.ss_quantity) as total_qty,
        RANK() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_quantity) DESC) as rank_in_store
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY s.s_store_name, i.i_product_name
) ranked_sales
WHERE rank_in_store <= 3
ORDER BY s_store_name, rank_in_store;

--57.
WITH ordered_purchases AS (
    SELECT 
        ss.ss_customer_sk,
        ss.ss_item_sk,
        i.i_product_name,
        d.d_date,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY d.d_date ASC, ss.ss_ticket_number ASC) as first_purchase_rank,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY d.d_date DESC, ss.ss_ticket_number DESC) as last_purchase_rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
)
SELECT 
    p1.ss_customer_sk,
    p1.ss_item_sk as first_item_sk, 
    p1.i_product_name as first_product_bought,
    p1.d_date as first_purchase_date,
    p2.ss_item_sk as last_item_sk,  
    p2.i_product_name as last_product_bought,
    p2.d_date as last_purchase_date
FROM ordered_purchases p1
JOIN ordered_purchases p2 ON p1.ss_customer_sk = p2.ss_customer_sk
WHERE p1.first_purchase_rank = 1 
  AND p2.last_purchase_rank = 1
  AND p1.d_date != p2.d_date 
ORDER BY p1.ss_customer_sk;

--58.
SELECT 
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    COUNT(ws.ws_order_number) as times_sold_online,
    SUM(COALESCE(ws.ws_net_paid, 0)) as total_web_revenue,
    SUM(COALESCE(wr.wr_return_amt, 0)) as total_web_refunds
FROM item i
LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number 
                        AND ws.ws_item_sk = wr.wr_item_sk
GROUP BY i.i_item_sk, i.i_product_name, i.i_category
ORDER BY total_web_revenue DESC, i.i_item_sk ASC;

--59.

SELECT 
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    COUNT(ws.ws_order_number) as times_sold_online,
    SUM(COALESCE(ws.ws_net_paid, 0)) as total_web_revenue,
    SUM(COALESCE(wr.wr_return_amt, 0)) as total_web_refunds
FROM item i
LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number 
                        AND ws.ws_item_sk = wr.wr_item_sk
GROUP BY i.i_item_sk, i.i_product_name, i.i_category
HAVING SUM(COALESCE(wr.wr_return_amt, 0)) = 0 
ORDER BY times_sold_online DESC, total_web_revenue DESC;

--60.
SELECT 
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    i.i_current_price
FROM item i
LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
WHERE ss.ss_item_sk IS NULL 
ORDER BY i.i_current_price DESC;

--61.
SELECT 
    i.i_item_sk,
    i.i_product_name,
    COALESCE(SUM(ss.ss_net_paid),0) as store_revenue,
    COALESCE(SUM(ws.ws_net_paid),0) as web_revenue
FROM store_sales ss
JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk 
                 AND ss.ss_sold_date_sk = ws.ws_sold_date_sk 
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001 AND d.d_moy = 1 
GROUP BY i.i_item_sk, i.i_product_name
ORDER BY store_revenue DESC;

--62.
SELECT 
    ss.ss_ticket_number,
    ss.ss_customer_sk,
    SUM(ss.ss_net_paid) as total_paid,
    SUM(sr.sr_return_amt) as total_returned
FROM store_sales ss
JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
                     AND ss.ss_item_sk = sr.sr_item_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000 
GROUP BY ss.ss_ticket_number, ss.ss_customer_sk
HAVING SUM(sr.sr_return_amt) > SUM(ss.ss_net_paid)
ORDER BY total_returned DESC;

--63.
SELECT 
    ws.ws_order_number,
    SUM(ws.ws_net_paid) as order_total_paid,
    SUM(COALESCE(wr.wr_return_amt, 0)) as order_total_returned,
    (SUM(ws.ws_net_paid) - SUM(COALESCE(wr.wr_return_amt, 0))) as net_profit
FROM web_sales ws
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number 
                        AND ws.ws_item_sk = wr.wr_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
GROUP BY ws.ws_order_number
HAVING (SUM(ws.ws_net_paid) - SUM(COALESCE(wr.wr_return_amt, 0))) < 0
ORDER BY net_profit ASC;

--64.
SELECT 
    i.i_item_sk,
    i.i_product_name,
    COALESCE(SUM(inv.inv_quantity_on_hand * i.i_current_price),0) as total_inventory_value,
    SUM(cs.cs_ext_sales_price) as total_catalog_sales_value
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN catalog_sales cs ON inv.inv_item_sk = cs.cs_item_sk
JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
WHERE d_inv.d_year = 2001 AND d_inv.d_moy = 12 
  AND d_sales.d_year = 2001                    
GROUP BY i.i_item_sk, i.i_product_name
ORDER BY total_inventory_value DESC;
--65.
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) as total_store_spent
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE c.c_birth_year BETWEEN 1980 AND 1990
  AND cd.cd_marital_status = 'M'
  AND i.i_category IN ('Electronics', 'Music')
  AND NOT EXISTS (
      SELECT 1 
      FROM web_sales ws 
      WHERE ws.ws_bill_customer_sk = c.c_customer_sk
  )
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
HAVING SUM(ss.ss_net_paid) > 500
ORDER BY total_store_spent DESC;

--66.
SELECT 
    s.s_store_name,
    COUNT(DISTINCT ss.ss_ticket_number) as total_tickets,
    AVG(ss.ss_net_paid) as avg_ticket_value
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000
GROUP BY s.s_store_name
HAVING AVG(ss.ss_net_paid) > (
    SELECT AVG(ss2.ss_net_paid) 
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk 
    WHERE d2.d_year = 2000
)
ORDER BY avg_ticket_value DESC;

--67.
SELECT 
    i.i_item_sk,
    i.i_product_name,
    SUM(ss.ss_net_paid) as total_store_revenue,
    SUM(ss.ss_quantity) as total_units_sold
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk 
WHERE d.d_year = 2001
  AND s.s_country = 'United States'        
  AND ss.ss_item_sk IN (
      SELECT DISTINCT cs.cs_item_sk 
      FROM catalog_sales cs
      JOIN date_dim cd ON cs.cs_sold_date_sk = cd.d_date_sk
      WHERE cd.d_year = 2001
  )
GROUP BY i.i_item_sk, i.i_product_name
HAVING SUM(ss.ss_net_paid) > 5000 
   AND SUM(ss.ss_quantity) > 200
ORDER BY total_store_revenue DESC;


--68.
SELECT 
    top_items.i_item_sk,
    i.i_product_name,
    i.i_category,
    top_items.total_store_revenue
FROM (
    SELECT ss_item_sk as i_item_sk, SUM(ss_net_paid) as total_store_revenue
    FROM store_sales
    GROUP BY ss_item_sk
    HAVING SUM(ss_net_paid) > 50000
) top_items
JOIN item i ON top_items.i_item_sk = i.i_item_sk
WHERE i.i_category_id IN (
    SELECT i_category_id 
    FROM item 
    WHERE i_category IN ('Electronics', 'Music', 'Books')
)
AND NOT EXISTS (
    SELECT sr.sr_item_sk
    FROM store_returns sr
    WHERE sr.sr_item_sk = top_items.i_item_sk
)
ORDER BY top_items.total_store_revenue DESC;

--69.
SELECT 
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    SUM(ss.ss_net_paid) as total_store_revenue
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE i.i_category IN ('Electronics', 'Music', 'Books')
  AND NOT EXISTS (
      SELECT sr.sr_item_sk
      FROM store_returns sr
      WHERE sr.sr_item_sk = i.i_item_sk
  )
GROUP BY i.i_item_sk, i.i_product_name, i.i_category
HAVING SUM(ss.ss_net_paid) > 50000
ORDER BY total_store_revenue DESC;

--70.
WITH store AS (
    SELECT ss_customer_sk, SUM(ss_net_paid) as store_spent
    FROM store_sales
    JOIN date_dim ON ss_sold_date_sk = d_date_sk
    WHERE d_year = 2001 
      AND d_moy BETWEEN 1 AND 12
      AND ss_customer_sk IS NOT NULL
    GROUP BY ss_customer_sk
    HAVING SUM(ss_net_paid) > 3000
),
web AS (
    SELECT ws_bill_customer_sk as ws_customer_sk, SUM(ws_net_paid) as web_spent
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_year = 2001
      AND ws_bill_customer_sk IS NOT NULL
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_paid) > 2000
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    sv.store_spent,
    wv.web_spent,
    (sv.store_spent + wv.web_spent) as total_omnichannel_spent
FROM store sv
JOIN web wv ON sv.ss_customer_sk = wv.ws_customer_sk
JOIN customer c ON sv.ss_customer_sk = c.c_customer_sk
ORDER BY total_omnichannel_spent DESC;

--71.
WITH city_category_sales AS (
    SELECT 
        s.s_city,
        i.i_category,
        SUM(ss.ss_net_paid) as category_revenue
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND s.s_country = 'United States'
      AND i.i_category IS NOT NULL
      AND s.s_city IS NOT NULL
    GROUP BY s.s_city, i.i_category
),
ranked_categories AS (
    SELECT 
        s_city,
        i_category,
        category_revenue,
        RANK() OVER (PARTITION BY s_city ORDER BY category_revenue DESC) as category_rank
    FROM city_category_sales
)
SELECT 
    s_city as store_city,
    i_category as top_category,
    category_revenue
FROM ranked_categories
WHERE category_rank = 1
ORDER BY store_city;

--72.
WITH city_category_web_sales AS (
    SELECT 
        ca.ca_city,
        i.i_category,
        SUM(ws.ws_net_paid) as category_revenue
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ca.ca_country = 'United States'
      AND i.i_category IS NOT NULL
      AND ca.ca_city IS NOT NULL
    GROUP BY ca.ca_city, i.i_category
),
ranked_web_categories AS (
    SELECT 
        ca_city,
        i_category,
        category_revenue,
        RANK() OVER (PARTITION BY ca_city ORDER BY category_revenue DESC) as category_rank
    FROM city_category_web_sales
)
SELECT 
    ca_city as customer_city,
    i_category as top_category,
    category_revenue
FROM ranked_web_categories
WHERE category_rank = 1
ORDER BY customer_city;

--73.
SELECT 
    i.i_item_sk, 
    i.i_product_name
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND d.d_moy = 11
INTERSECT
SELECT 
    i.i_item_sk, 
    i.i_product_name
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND d.d_moy = 11
ORDER BY i_item_sk;

--74.
SELECT DISTINCT
    i.i_item_sk, 
    i.i_product_name
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND d.d_moy = 11

INTERSECT

SELECT DISTINCT
    i.i_item_sk, 
    i.i_product_name
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND d.d_moy = 11
ORDER BY i_item_sk;

--75.
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
INTERSECT
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
INTERSECT
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
ORDER BY c_last_name, c_first_name;

--76.

SELECT DISTINCT
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002

INTERSECT

SELECT DISTINCT
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002

INTERSECT

SELECT DISTINCT
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002

ORDER BY c_last_name, c_first_name;

--77.
SELECT 
    i.i_brand_id, 
    i.i_brand
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000 
  AND i.i_brand_id IS NOT NULL
GROUP BY i.i_brand_id, i.i_brand
HAVING SUM(ss.ss_net_paid) > 50000

INTERSECT

SELECT 
    i.i_brand_id, 
    i.i_brand
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000 
  AND i.i_brand_id IS NOT NULL
GROUP BY i.i_brand_id, i.i_brand
HAVING SUM(ws.ws_net_paid) > 20000

ORDER BY i_brand;

--78.
SELECT DISTINCT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002

EXCEPT

SELECT DISTINCT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002

ORDER BY c_last_name, c_first_name;

--79.
SELECT DISTINCT 
    i.i_item_sk, 
    i.i_product_name, 
    i.i_category
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001

EXCEPT

SELECT DISTINCT 
    i.i_item_sk, 
    i.i_product_name, 
    i.i_category
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002

ORDER BY i_category, i_product_name;

--80
SELECT 
    SUBSTRING(ca_zip, 1, 3) as zip_area_code, 
    COUNT(*) as customer_count 
FROM customer_address 
WHERE ca_country = 'United States' 
  AND ca_zip IS NOT NULL 
GROUP BY SUBSTRING(ca_zip, 1, 3) 
ORDER BY customer_count DESC;

--81
SELECT 
    c.c_customer_sk, 
    c.c_last_name, 
    ca.ca_city 
FROM customer c 
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
WHERE LENGTH(c.c_last_name) >= 3 
  AND LENGTH(ca.ca_city) >= 3 
  AND SUBSTRING(LOWER(c.c_last_name), 1, 3) = SUBSTRING(LOWER(ca.ca_city), 1, 3) 
ORDER BY c_last_name;

--82.
WITH email_domains AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        ws.ws_net_paid, 
        SUBSTRING(c.c_email_address FROM '@(.*)$') as email_domain 
    FROM web_sales ws 
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    WHERE d.d_year = 2002 
      AND c.c_email_address IS NOT NULL
) 
SELECT 
    email_domain, 
    COUNT(DISTINCT ws_bill_customer_sk) as unique_customers, 
    SUM(ws_net_paid) as total_web_revenue 
FROM email_domains 
GROUP BY email_domain 
HAVING SUM(ws_net_paid) > 1000 
ORDER BY total_web_revenue DESC;

--83.
SELECT 
    ss.ss_ticket_number, 
    STRING_AGG(DISTINCT i.i_product_name, ' | ') as purchased_items_list, 
    SUM(ss.ss_net_paid) as ticket_total 
FROM store_sales ss 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE d.d_year = 2000 
  AND d.d_moy = 1 
GROUP BY ss.ss_ticket_number 
HAVING COUNT(ss.ss_item_sk) > 3 
ORDER BY ticket_total DESC;

--84.
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name, 
    c.c_email_address,
    SUM(ws.ws_net_paid) as edu_web_spend
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 AND d.d_moy = 12
  AND c.c_email_address LIKE '%.edu'
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
ORDER BY edu_web_spend DESC;

--85.
SELECT * FROM ( 
SELECT 
    i.i_item_sk, 
    i.i_product_name, 
    LENGTH(i.i_item_desc) as desc_length,
    SUM(sr.sr_return_amt) as total_returned
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND LENGTH(i.i_item_desc) < 20 
  AND i.i_item_desc IS NOT NULL
GROUP BY i.i_item_sk, i.i_product_name, LENGTH(i.i_item_desc)
ORDER BY total_returned DESC) SUB where total_returned is not null;


--86.
WITH email_domains AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        ws.ws_net_paid, 
        SUBSTRING(c.c_email_address FROM '@(.*)$') as email_domain 
    FROM web_sales ws 
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    WHERE c.c_email_address IS NOT NULL
),
domain_ranking AS (
    SELECT 
        email_domain, 
        SUM(ws_net_paid) as total_web_revenue,
        RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) as revenue_rank
    FROM email_domains 
    GROUP BY email_domain 
)
SELECT 
    email_domain, 
    total_web_revenue,
    revenue_rank
FROM domain_ranking
WHERE revenue_rank <= 50
ORDER BY revenue_rank;

--87.
SELECT 
    ss.ss_ticket_number, 
    COUNT(DISTINCT i.i_category) as distinct_categories,
    STRING_AGG(DISTINCT i.i_product_name, ' | ') as purchased_items_list, 
    SUM(ss.ss_net_paid) as ticket_total 
FROM store_sales ss 
JOIN item i ON ss.ss_item_sk = i.i_item_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE d.d_year = 2000 
  AND d.d_moy = 12
GROUP BY ss.ss_ticket_number 
HAVING COUNT(DISTINCT i.i_category) >= 4 
ORDER BY ticket_total DESC;

--88.
WITH tickets AS (
    SELECT 
        ss.ss_ticket_number,
        ss.ss_store_sk,
        c.c_first_name || ' ' || c.c_last_name as customer_full_name,
        ca.ca_city,
        COUNT(DISTINCT i.i_category) as distinct_categories,
        STRING_AGG(DISTINCT i.i_product_name, ' | ') as purchased_items_list, 
        SUM(ss.ss_net_paid) as ticket_total
    FROM store_sales ss 
    JOIN item i ON ss.ss_item_sk = i.i_item_sk 
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000 
      AND d.d_moy = 12
      AND ca.ca_city LIKE 'S%' 
    GROUP BY ss.ss_ticket_number, ss.ss_store_sk, c.c_first_name, c.c_last_name, ca.ca_city
    HAVING COUNT(DISTINCT i.i_category) >= 4 
)
SELECT 
    t.*,
    AVG(t.ticket_total) OVER (PARTITION BY t.ss_store_sk) as store_avg_ticket,
    t.ticket_total - AVG(t.ticket_total) OVER (PARTITION BY t.ss_store_sk) as diff_from_store_avg
FROM tickets t
ORDER BY diff_from_store_avg DESC;

--89.
SELECT 
    sub.ss_ticket_number,
    sub.customer_last_name,
    sub.distinct_categories,
    sub.purchased_items_list,
    sub.ticket_total
FROM (
    SELECT 
        ss.ss_ticket_number,
        c.c_last_name as customer_last_name,
        COUNT(DISTINCT i.i_category) as distinct_categories,
        STRING_AGG(DISTINCT i.i_product_name, ' | ') as purchased_items_list, 
        SUM(ss.ss_net_paid) as ticket_total
    FROM store_sales ss 
    JOIN item i ON ss.ss_item_sk = i.i_item_sk 
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000 
      AND d.d_moy = 12
      AND ca.ca_state = 'TN'
    GROUP BY ss.ss_ticket_number, c.c_last_name
) sub
WHERE sub.distinct_categories >= 4
ORDER BY sub.ticket_total DESC;

--90.
SELECT 
    sub.ss_ticket_number,
    sub.customer_last_name,
    sub.distinct_categories,
    sub.purchased_items_list,
    sub.ticket_total
FROM (
    SELECT 
        ss.ss_ticket_number,
        c.c_last_name as customer_last_name,
        COUNT(DISTINCT i.i_category) as distinct_categories,
        STRING_AGG(DISTINCT i.i_product_name, ' | ') as purchased_items_list, 
        SUM(ss.ss_net_paid) as ticket_total
    FROM store_sales ss 
    JOIN item i ON ss.ss_item_sk = i.i_item_sk 
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'TN'
    GROUP BY ss.ss_ticket_number, c.c_last_name
) sub
WHERE sub.distinct_categories >= 4
ORDER BY sub.ticket_total DESC;

--91.
SELECT 
    c.c_customer_sk,
    MIN(wr.wr_return_amt) as smallest_return,
    MAX(wr.wr_return_amt) as largest_return
FROM web_returns wr
LEFT JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
WHERE c.c_email_address IS NULL
  AND d.d_year = 2001
GROUP BY c.c_customer_sk
HAVING MIN(wr.wr_return_amt) > 5
ORDER BY largest_return DESC;

--92.
SELECT 
    i.i_category,
    ca.ca_state,
    s.s_company_name,
    MIN(ss.ss_net_profit) as min_net_profit,
    MAX(ss.ss_net_profit) as max_net_profit,
    SUM(ss.ss_sales_price) as total_gross_revenue,
    COUNT(sr.sr_return_amt) as total_return_incidents
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number 
                          AND ss.ss_item_sk = sr.sr_item_sk
WHERE d.d_year IN (2001, 2002)
  AND i.i_category IS NOT NULL
  AND ca.ca_country = 'United States'
GROUP BY i.i_category, ca.ca_state, s.s_company_name
HAVING SUM(ss.ss_sales_price) > 1000
ORDER BY total_gross_revenue DESC;
--93.
SELECT 
    i.i_category,
    ca.ca_state,
    s.s_company_name,
    MIN(ss.ss_net_profit) as min_net_profit,
    MAX(ss.ss_net_profit) as max_net_profit,
    SUM(ss.ss_sales_price) as total_gross_revenue,
    COUNT(sr.sr_return_amt) as total_return_incidents
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number 
                          AND ss.ss_item_sk = sr.sr_item_sk
WHERE d.d_year IN (2001, 2002)
  AND i.i_category IS NOT NULL
  AND ca.ca_country = 'United States'
GROUP BY i.i_category, ca.ca_state, s.s_company_name
HAVING SUM(ss.ss_sales_price) > 1000
ORDER BY total_gross_revenue DESC;

--94.
SELECT 
    ca.ca_state, 
    ca.ca_city,
    MIN(ws.ws_net_paid) as min_web_sale,
    MAX(ws.ws_net_paid) as max_web_sale,
    AVG(ws.ws_net_profit) as avg_web_profit,
    COUNT(DISTINCT ws.ws_order_number) as total_orders,
    SUM(wr.wr_return_amt) as total_returned_amt
FROM web_sales ws
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number 
                        AND ws.ws_item_sk = wr.wr_item_sk
WHERE (ca.ca_city LIKE '%ville%' OR ca.ca_city LIKE '%burg%')
  AND d.d_year = 2002
  AND ca.ca_country = 'United States'
GROUP BY ca.ca_state, ca.ca_city
HAVING MAX(ws.ws_net_paid) > 200 
   AND COUNT(DISTINCT ws.ws_order_number) > 2
ORDER BY max_web_sale DESC;

--95.
SELECT 
    sub.ca_state, 
    sub.ca_city,
    sub.min_web_sale,
    sub.max_web_sale,
    sub.total_orders,
    sub.total_returned_amt
FROM (
    SELECT 
        ca.ca_state, 
        ca.ca_city,
        MIN(ws.ws_net_paid) as min_web_sale,
        MAX(ws.ws_net_paid) as max_web_sale,
        COUNT(DISTINCT ws.ws_order_number) as total_orders,
        SUM(wr.wr_return_amt) as total_returned_amt
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number 
                            AND ws.ws_item_sk = wr.wr_item_sk
    WHERE (ca.ca_city LIKE '%ville%' OR ca.ca_city LIKE '%burg%')
      AND d.d_year = 2002
      AND ca.ca_country = 'United States'
    GROUP BY ca.ca_state, ca.ca_city
) sub
WHERE sub.max_web_sale > 200 
  AND sub.total_orders > 2
ORDER BY sub.max_web_sale DESC;

--96.
WITH web_performance AS (
    SELECT 
        ca.ca_state, 
        ca.ca_city,
        MIN(ws.ws_net_paid) as min_web_sale,
        MAX(ws.ws_net_paid) as max_web_sale,
        COUNT(DISTINCT ws.ws_order_number) as total_orders,
        SUM(wr.wr_return_amt) as total_returned_amt
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number 
                            AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d.d_year = 2002
      AND ca.ca_country = 'United States'
    GROUP BY ca.ca_state, ca.ca_city
)
SELECT * FROM web_performance
WHERE (ca_city LIKE '%ville%' OR ca_city LIKE '%burg%')
  AND max_web_sale > 200
  AND total_orders > 2
ORDER BY max_web_sale DESC;

--97.
SELECT 
    s.s_state,
    s.s_store_name,
    s.s_store_id,
    SUM(CASE WHEN d.d_quarter_name = '2000Q1' THEN ss.ss_net_paid ELSE 0 END) as Q1_revenue,
    SUM(CASE WHEN d.d_quarter_name = '2000Q2' THEN ss.ss_net_paid ELSE 0 END) as Q2_revenue,
    SUM(CASE WHEN d.d_quarter_name = '2000Q3' THEN ss.ss_net_paid ELSE 0 END) as Q3_revenue,
    SUM(CASE WHEN d.d_quarter_name = '2000Q4' THEN ss.ss_net_paid ELSE 0 END) as Q4_revenue,
    SUM(ss.ss_net_paid) as total_annual_revenue
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000
GROUP BY s.s_state, s.s_store_name, s.s_store_id
ORDER BY s.s_state, total_annual_revenue DESC;

--98.
WITH store_pivot AS (
    SELECT 
        s.s_state, s.s_store_name,
        SUM(CASE WHEN d.d_quarter_name = '2000Q1' THEN ss.ss_net_paid ELSE 0 END) as Q1,
        SUM(CASE WHEN d.d_quarter_name = '2000Q2' THEN ss.ss_net_paid ELSE 0 END) as Q2,
        SUM(CASE WHEN d.d_quarter_name = '2000Q3' THEN ss.ss_net_paid ELSE 0 END) as Q3,
        SUM(CASE WHEN d.d_quarter_name = '2000Q4' THEN ss.ss_net_paid ELSE 0 END) as Q4,
        SUM(ss.ss_net_paid) as store_total
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY s.s_state, s.s_store_name
)
SELECT 
    *,
    ROUND((store_total / SUM(store_total) OVER (PARTITION BY s_state)) * 100, 2) as state_contribution_pct
FROM store_pivot
ORDER BY s_state, state_contribution_pct DESC;

--99.
WITH regional_data AS (
    SELECT 
        ca.ca_state,
        CASE 
            WHEN ca.ca_state IN ('NY', 'CT', 'MA', 'PA') THEN 'East'
            WHEN ca.ca_state IN ('WA', 'OR', 'CA', 'NV') THEN 'West'
            WHEN ca.ca_state IN ('TX', 'FL', 'GA', 'AL') THEN 'South'
            ELSE 'Other'
        END as region,
        ss.ss_net_profit as s_profit,
        ws.ws_net_profit as w_profit
    FROM customer_address ca
    LEFT JOIN store_sales ss ON ca.ca_address_sk = ss.ss_addr_sk
    LEFT JOIN web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
    WHERE ca.ca_country = 'United States'
)
SELECT 
    region,
    SUM(CASE WHEN s_profit IS NOT NULL THEN s_profit ELSE 0 END) as total_store_profit,
    SUM(CASE WHEN w_profit IS NOT NULL THEN w_profit ELSE 0 END) as total_web_profit,
    AVG(CASE WHEN s_profit IS NOT NULL THEN s_profit ELSE NULL END) as avg_store_profit
FROM regional_data
GROUP BY region
ORDER BY total_store_profit DESC;

--100
SELECT 
    i.i_category,
    COUNT(DISTINCT sr.sr_ticket_number) as total_returns,
    SUM(CASE WHEN d.d_day_name IN ('Saturday', 'Sunday') THEN sr.sr_return_amt ELSE 0 END) as weekend_returns_value,
    SUM(CASE WHEN d.d_day_name NOT IN ('Saturday', 'Sunday') THEN sr.sr_return_amt ELSE 0 END) as weekday_returns_value
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE d.d_year = 2001
GROUP BY i.i_category
HAVING COUNT(DISTINCT sr.sr_ticket_number) > 10
ORDER BY weekend_returns_value DESC;

--101
SELECT 
    cd.cd_education_status,
    SUM(CASE WHEN ss.ss_item_sk IS NOT NULL THEN 1 ELSE 0 END) as store_transactions,
    SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN 1 ELSE 0 END) as web_transactions,
    SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN 1 ELSE 0 END) as catalog_transactions
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
GROUP BY cd.cd_education_status
ORDER BY store_transactions DESC;

--102.
SELECT 
    sm.sm_type,
    sm.sm_carrier,
    COUNT(CASE WHEN (ws.ws_ship_date_sk - ws.ws_sold_date_sk) <= 5 THEN 1 END) as fast_shipping,
    COUNT(CASE WHEN (ws.ws_ship_date_sk - ws.ws_sold_date_sk) > 5 AND (ws.ws_ship_date_sk - ws.ws_sold_date_sk) <= 10 THEN 1 END) as normal_shipping,
    COUNT(CASE WHEN (ws.ws_ship_date_sk - ws.ws_sold_date_sk) > 10 THEN 1 END) as slow_shipping
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_ship_date_sk IS NOT NULL
GROUP BY sm.sm_type, sm.sm_carrier
ORDER BY fast_shipping DESC;

--103.
SELECT 
    d.d_year,
    ca.ca_state,
    i.i_category,
    SUM(ss.ss_net_paid) as total_sales
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year = 2002 
  AND ca.ca_country = 'United States'
GROUP BY ROLLUP(d.d_year, ca.ca_state, i.i_category)
ORDER BY d.d_year, ca.ca_state, i.i_category;

--104.
SELECT 
    d.d_year,
    ca.ca_state,
    SUM(CASE WHEN i.i_category = 'Electronics' THEN ss.ss_net_paid ELSE 0 END) as electronics_sales,
    SUM(CASE WHEN i.i_category = 'Music' THEN ss.ss_net_paid ELSE 0 END) as music_sales,
    SUM(CASE WHEN i.i_category = 'Home' THEN ss.ss_net_paid ELSE 0 END) as home_sales,
    SUM(CASE WHEN i.i_category NOT IN ('Electronics', 'Music', 'Home') OR i.i_category IS NULL THEN ss.ss_net_paid ELSE 0 END) as other_categories_sales,
    SUM(ss.ss_net_paid) as total_state_sales
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year = 2002 
  AND ca.ca_country = 'United States'
GROUP BY d.d_year, ca.ca_state
ORDER BY total_state_sales DESC;

--105.
WITH daily_purchases AS (
    SELECT DISTINCT ss_customer_sk, d.d_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND ss.ss_customer_sk IS NOT NULL
),
streaks AS (
    SELECT 
        ss_customer_sk,
        d_date,
        (d_date - CAST(DENSE_RANK() OVER (PARTITION BY ss_customer_sk ORDER BY d_date) AS INTEGER)) AS streak_id
    FROM daily_purchases
)
SELECT 
    c.c_last_name,
    c.c_first_name,
    COUNT(*) as consecutive_days_streak,
    MIN(d_date) as streak_start_date,
    MAX(d_date) as streak_end_date
FROM streaks s
JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
GROUP BY s.ss_customer_sk, c.c_last_name, c.c_first_name, streak_id
HAVING COUNT(*) >= 2
ORDER BY consecutive_days_streak DESC;

--106
SELECT 
    ss.ss_customer_sk,
    ARRAY_AGG(DISTINCT i.i_brand ORDER BY i.i_brand) as preferred_brands,
    SUM(ss.ss_net_paid) as total_spent
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND ss.ss_customer_sk IS NOT NULL
  AND i.i_brand IS NOT NULL
GROUP BY ss.ss_customer_sk
HAVING SUM(ss.ss_net_paid) > 1000
ORDER BY total_spent DESC
LIMIT 500;

--107
SELECT 
    s.s_store_id,
    s.s_store_name,
    s.s_manager,
    COUNT(DISTINCT ss.ss_customer_sk) as unique_sports_customers,
    SUM(ss.ss_net_paid) as gross_sports_revenue,
    SUM(COALESCE(sr.sr_return_amt, 0)) as total_sports_returns,
    (SUM(ss.ss_net_paid) - SUM(COALESCE(sr.sr_return_amt, 0))) as net_sports_profit
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number 
                          AND ss.ss_item_sk = sr.sr_item_sk
WHERE i.i_category = 'Sports'
GROUP BY s.s_store_id, s.s_store_name, s.s_manager
ORDER BY net_sports_profit DESC
LIMIT 3;

--108.
SELECT 
    s.s_store_id,
    s.s_store_name,
    s.s_manager,
    COUNT(DISTINCT ss.ss_customer_sk) as unique_sports_customers,
    SUM(ss.ss_net_paid) as gross_sports_revenue,
    SUM(COALESCE(sr.sr_return_amt, 0)) as total_sports_returns,
    (SUM(ss.ss_net_paid) - SUM(COALESCE(sr.sr_return_amt, 0))) as net_sports_profit
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number 
                          AND ss.ss_item_sk = sr.sr_item_sk
WHERE i.i_category = 'Sports'
GROUP BY s.s_store_id, s.s_store_name, s.s_manager
HAVING COUNT(DISTINCT ss.ss_customer_sk) > 1000 
   AND SUM(ss.ss_net_paid) > 100000 
   AND SUM(COALESCE(sr.sr_return_amt, 0)) < (SUM(ss.ss_net_paid) * 0.25)
ORDER BY net_sports_profit DESC
LIMIT 3;

--109.
SELECT 
    i.i_category,
    SUM(CASE WHEN p.p_promo_sk IS NOT NULL AND p.p_channel_tv = 'Y' THEN ss.ss_net_paid ELSE 0 END) as tv_promo_sales,
    SUM(CASE WHEN p.p_promo_sk IS NOT NULL AND p.p_channel_email = 'Y' THEN ss.ss_net_paid ELSE 0 END) as email_promo_sales,
    SUM(CASE WHEN p.p_promo_sk IS NULL THEN ss.ss_net_paid ELSE 0 END) as non_promo_sales,
    COUNT(ss.ss_ticket_number) as total_transactions
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND i.i_category IS NOT NULL
GROUP BY i.i_category
ORDER BY non_promo_sales DESC;

--110
SELECT 
    s.s_manager,
    s.s_store_name,
    AVG(ss.ss_net_paid) as store_avg_ticket,
    (SELECT AVG(ss2.ss_net_paid) 
     FROM store_sales ss2 
     JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk 
     WHERE d2.d_year = 2000) as global_avg_ticket,
    (AVG(ss.ss_net_paid) - 
        (SELECT AVG(ss2.ss_net_paid) 
         FROM store_sales ss2 
         JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk 
         WHERE d2.d_year = 2000)) as performance_gap
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000
GROUP BY s.s_manager, s.s_store_name
ORDER BY performance_gap DESC;

--111.
WITH yearly_category_sales AS (
    SELECT 
        i.i_category,
        d.d_year,
        SUM(ss.ss_net_paid) as annual_sales
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (2000, 2001, 2002) AND i.i_category IS NOT NULL
    GROUP BY i.i_category, d.d_year
)
SELECT 
    i_category,
    d_year,
    annual_sales,
    LAG(annual_sales) OVER (PARTITION BY i_category ORDER BY d_year) as prev_year_sales,
    ROUND(
        ((annual_sales - LAG(annual_sales) OVER (PARTITION BY i_category ORDER BY d_year)) / 
        NULLIF(LAG(annual_sales) OVER (PARTITION BY i_category ORDER BY d_year), 0)) * 100, 
    2) as yoy_growth_percentage
FROM yearly_category_sales
ORDER BY i_category, d_year;

--112.
WITH global_avg AS (
    SELECT AVG(ss.ss_net_paid) as global_avg_ticket
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
)
SELECT 
    s.s_manager,
    s.s_store_name,
    AVG(ss.ss_net_paid) as store_avg_ticket,
    ga.global_avg_ticket,
    (AVG(ss.ss_net_paid) - ga.global_avg_ticket) as performance_gap
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
CROSS JOIN global_avg ga
WHERE d.d_year = 2000
GROUP BY s.s_manager, s.s_store_name, ga.global_avg_ticket
ORDER BY performance_gap DESC;

--113
WITH ss_aggs AS (
    SELECT ss_customer_sk, SUM(ss_net_paid) as store_spent
    FROM store_sales
    JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND ss_customer_sk IS NOT NULL
    GROUP BY ss_customer_sk
),
ws_aggs AS (
    SELECT ws_bill_customer_sk as ws_customer_sk, SUM(ws_net_paid) as web_spent
    FROM web_sales
    JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND ws_bill_customer_sk IS NOT NULL
    GROUP BY ws_bill_customer_sk
)
SELECT 
    COALESCE(s.ss_customer_sk, w.ws_customer_sk) as customer_sk,
    COALESCE(s.store_spent, 0) as store_total,
    COALESCE(w.web_spent, 0) as web_total,
    CASE 
        WHEN s.store_spent IS NOT NULL AND w.web_spent IS NOT NULL THEN 'Omnichannel'
        WHEN s.store_spent IS NOT NULL THEN 'Store Only'
        ELSE 'Web Only'
    END as customer_type
FROM ss_aggs s
FULL OUTER JOIN ws_aggs w ON s.ss_customer_sk = w.ws_customer_sk
ORDER BY store_total DESC, web_total DESC;

--114
WITH sr_aggs AS (
    SELECT i.i_category, SUM(sr.sr_return_amt) as store_returns_total
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND i.i_category IS NOT NULL
    GROUP BY i.i_category
),
wr_aggs AS (
    SELECT i.i_category, SUM(wr.wr_return_amt) as web_returns_total
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND i.i_category IS NOT NULL
    GROUP BY i.i_category
)
SELECT 
    COALESCE(s.i_category, w.i_category) as product_category,
    COALESCE(s.store_returns_total, 0) as store_returns,
    COALESCE(w.web_returns_total, 0) as web_returns,
    (COALESCE(s.store_returns_total, 0) + COALESCE(w.web_returns_total, 0)) as total_omnichannel_returns
FROM sr_aggs s
FULL OUTER JOIN wr_aggs w ON s.i_category = w.i_category
ORDER BY total_omnichannel_returns DESC;

--115
WITH monthly_sales AS (
    SELECT ss_item_sk, SUM(ss_quantity) as total_sold
    FROM store_sales
    JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 11
    GROUP BY ss_item_sk
),
monthly_inv AS (
    SELECT inv_item_sk, AVG(inv_quantity_on_hand) as avg_stock
    FROM inventory
    JOIN date_dim d ON inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 11
    GROUP BY inv_item_sk
)
SELECT 
    i.i_product_name, 
    s.total_sold, 
    inv.avg_stock
FROM monthly_sales s
JOIN monthly_inv inv ON s.ss_item_sk = inv.inv_item_sk
JOIN item i ON s.ss_item_sk = i.i_item_sk
WHERE s.total_sold > (inv.avg_stock * 2)
ORDER BY s.total_sold DESC 
LIMIT 50;

--116
SELECT 
    ss.ss_ticket_number,
    COUNT(ss.ss_item_sk) as items_bought,
    COUNT(sr.sr_item_sk) as items_returned,
    SUM(ss.ss_net_paid) as ticket_revenue,
    SUM(COALESCE(sr.sr_return_amt, 0)) as ticket_refund
FROM store_sales ss
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number 
                          AND ss.ss_item_sk = sr.sr_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY ss.ss_ticket_number
HAVING SUM(COALESCE(sr.sr_return_amt, 0)) > (SUM(ss.ss_net_paid) * 0.8)
ORDER BY ticket_revenue DESC;

--117
WITH monthly_sales AS (
    SELECT ss_item_sk, SUM(ss_quantity) as total_sold
    FROM store_sales
    JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 11
    GROUP BY ss_item_sk
),
monthly_inv AS (
    SELECT inv_item_sk, AVG(inv_quantity_on_hand) as avg_stock
    FROM inventory
    JOIN date_dim d ON inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 11
    GROUP BY inv_item_sk
)
SELECT 
    i.i_product_name, 
    SUM(s.total_sold) as final_total_sold, 
    AVG(inv.avg_stock) as final_avg_stock
FROM monthly_sales s
JOIN monthly_inv inv ON s.ss_item_sk = inv.inv_item_sk
JOIN item i ON s.ss_item_sk = i.i_item_sk
GROUP BY i.i_product_name
HAVING SUM(s.total_sold) > (AVG(inv.avg_stock) * 2)
ORDER BY final_total_sold DESC 
LIMIT 50;

--118
WITH monthly_sales AS (
    SELECT ss_item_sk, SUM(ss_quantity) as total_sold
    FROM store_sales
    JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 11
    GROUP BY ss_item_sk
),
monthly_inv AS (
    SELECT inv_item_sk, AVG(inv_quantity_on_hand) as avg_stock
    FROM inventory
    JOIN date_dim d ON inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 11
    GROUP BY inv_item_sk
)
SELECT 
    i.i_category,
    i.i_product_name, 
    SUM(s.total_sold) as final_total_sold, 
    AVG(inv.avg_stock) as final_avg_stock
FROM monthly_sales s
JOIN monthly_inv inv ON s.ss_item_sk = inv.inv_item_sk
JOIN item i ON s.ss_item_sk = i.i_item_sk
WHERE i.i_category IN ('Electronics', 'Music') 
GROUP BY i.i_category, i.i_product_name
HAVING SUM(s.total_sold) > (AVG(inv.avg_stock) * 2) 
   AND SUM(s.total_sold) > 100                 
ORDER BY final_total_sold DESC ;

--119
SELECT 
    c.c_last_name,
    c.c_first_name,
    d.d_date,
    SUM(ss.ss_net_paid) as daily_store_spent,
    SUM(ws.ws_net_paid) as daily_web_spent
FROM store_sales ss
JOIN web_sales ws ON ss.ss_customer_sk = ws.ws_bill_customer_sk 
                 AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001 AND d.d_moy = 12
  AND ss.ss_customer_sk IS NOT NULL
GROUP BY c.c_last_name, c.c_first_name, d.d_date
HAVING SUM(ss.ss_net_paid) > 500 AND SUM(ws.ws_net_paid) > 500
ORDER BY (SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid)) DESC;

--120
WITH store_ret_agg AS (
    SELECT sr_item_sk, SUM(sr_return_amt) as store_returns
    FROM store_returns
    JOIN date_dim d ON sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY sr_item_sk
),
web_ret_agg AS (
    SELECT wr_item_sk, SUM(wr_return_amt) as web_returns
    FROM web_returns
    JOIN date_dim d ON wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(sr.store_returns, 0) as store_return_total,
    COALESCE(wr.web_returns, 0) as web_return_total
FROM store_ret_agg sr
FULL OUTER JOIN web_ret_agg wr ON sr.sr_item_sk = wr.wr_item_sk
JOIN item i ON COALESCE(sr.sr_item_sk, wr.wr_item_sk) = i.i_item_sk
WHERE COALESCE(wr.web_returns, 0) > (COALESCE(sr.store_returns, 0) * 1.5)
ORDER BY web_return_total DESC;


--121
SELECT 
    i.i_category,
    SUM(ss.ss_net_paid) as category_total,
    ROUND(
        (SUM(ss.ss_net_paid) / 
        (SELECT SUM(ss2.ss_net_paid) 
         FROM store_sales ss2 
         JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk 
         WHERE d2.d_year = 2001)) * 100, 
    2) as percentage_of_total
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001 AND i.i_category IS NOT NULL
GROUP BY i.i_category;

--122.
WITH all_sales AS (
    SELECT i.i_category, ss.ss_net_paid as net_paid
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND i.i_category IS NOT NULL
    
    UNION ALL
    
    SELECT i.i_category, ws.ws_net_paid as net_paid
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND i.i_category IS NOT NULL
    
    UNION ALL
    
    SELECT i.i_category, cs.cs_net_paid as net_paid
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND i.i_category IS NOT NULL
)
SELECT 
    i_category,
    SUM(net_paid) as category_total,
    ROUND(
        (SUM(net_paid) / (SELECT SUM(net_paid) FROM all_sales)) * 100, 
    2) as percentage_of_total
FROM all_sales
GROUP BY i_category;

--123
SELECT 
    i.i_category,
    SUM(COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) + COALESCE(cs.catalog_revenue, 0)) as category_total,
    ROUND(
        (SUM(COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) + COALESCE(cs.catalog_revenue, 0)) / 
        (
            (SELECT SUM(ss2.ss_net_paid) FROM store_sales ss2 JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk WHERE d2.d_year = 2001) +
            (SELECT SUM(ws2.ws_net_paid) FROM web_sales ws2 JOIN date_dim d3 ON ws2.ws_sold_date_sk = d3.d_date_sk WHERE d3.d_year = 2001) +
            (SELECT SUM(cs2.cs_net_paid) FROM catalog_sales cs2 JOIN date_dim d4 ON cs2.cs_sold_date_sk = d4.d_date_sk WHERE d4.d_year = 2001)
        )) * 100, 
    2) as percentage_of_total
FROM item i
LEFT JOIN (
    SELECT ss_item_sk, SUM(ss_net_paid) as store_revenue
    FROM store_sales
    JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss_item_sk
) ss ON i.i_item_sk = ss.ss_item_sk
LEFT JOIN (
    SELECT ws_item_sk, SUM(ws_net_paid) as web_revenue
    FROM web_sales
    JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws_item_sk
) ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN (
    SELECT cs_item_sk, SUM(cs_net_paid) as catalog_revenue
    FROM catalog_sales
    JOIN date_dim d ON cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs_item_sk
) cs ON i.i_item_sk = cs.cs_item_sk
WHERE i.i_category IS NOT NULL
GROUP BY i.i_category;

--124
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_preferred_cust_flag
FROM customer c
WHERE EXISTS (
    SELECT ss.ss_customer_sk 
    FROM store_sales ss 
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
    WHERE ss.ss_customer_sk = c.c_customer_sk 
      AND d.d_year = 2000
)
AND EXISTS (
    SELECT ss2.ss_customer_sk 
    FROM store_sales ss2 
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk 
    WHERE ss2.ss_customer_sk = c.c_customer_sk 
      AND d2.d_year = 2001
);
--125
SELECT 
    p.p_promo_id,
    p.p_promo_name,
    (
        SELECT SUM(ss.ss_net_paid) 
        FROM store_sales ss 
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
        WHERE ss.ss_promo_sk = p.p_promo_sk 
          AND d.d_year = 2001
    ) as store_promo_revenue,
    (
        SELECT SUM(ws.ws_net_paid) 
        FROM web_sales ws 
        JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk 
        WHERE ws.ws_promo_sk = p.p_promo_sk 
          AND d2.d_year = 2001
    ) as web_promo_revenue
FROM promotion p
WHERE p.p_end_date_sk IS NOT NULL;


--126
(
    SELECT ss_customer_sk FROM store_sales JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk WHERE d.d_year = 2001
    INTERSECT
    SELECT ws_bill_customer_sk FROM web_sales JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk WHERE d.d_year = 2001
    INTERSECT
    SELECT cs_bill_customer_sk FROM catalog_sales JOIN date_dim d ON cs_sold_date_sk = d.d_date_sk WHERE d.d_year = 2001
)
EXCEPT
(
    SELECT sr_customer_sk FROM store_returns JOIN date_dim d ON sr_returned_date_sk = d.d_date_sk WHERE d.d_year = 2001
    UNION
    SELECT wr_returning_customer_sk FROM web_returns JOIN date_dim d ON wr_returned_date_sk = d.d_date_sk WHERE d.d_year = 2001
    UNION
    SELECT cr_returning_customer_sk FROM catalog_returns JOIN date_dim d ON cr_returned_date_sk = d.d_date_sk WHERE d.d_year = 2001
);

--127
SELECT ss_customer_sk
FROM store_sales
JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 AND ss_customer_sk IS NOT NULL

EXCEPT

SELECT ws_bill_customer_sk
FROM web_sales
JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 AND ws_bill_customer_sk IS NOT NULL

EXCEPT

SELECT cs_bill_customer_sk
FROM catalog_sales
JOIN date_dim d ON cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 AND cs_bill_customer_sk IS NOT NULL;

--128
SELECT 
    i.i_item_id, 
    i.i_product_name, 
    i.i_color,
    SUM(ss.ss_quantity) as total_units_sold,
    SUM(ss.ss_net_paid) as total_revenue
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND (
      i.i_product_name LIKE '%Vintage%' 
      OR i.i_product_name LIKE '%Classic%'
      OR i.i_item_desc LIKE '%antique%'
      OR i.i_color LIKE 'bl%'
  )
GROUP BY i.i_item_id, i.i_product_name, i.i_color
ORDER BY total_revenue DESC;


--129
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city,
    ca.ca_street_name,
    SUM(ws.ws_net_paid) as total_web_spent
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND (
      ca.ca_city LIKE 'San%' 
      OR ca.ca_city LIKE 'New%'
      OR ca.ca_street_name LIKE '%Washington%'
      OR ca.ca_street_name LIKE '%Lincoln%'
  )
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_street_name
HAVING SUM(ws.ws_net_paid) > 2000;

--130.
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city,
    ca.ca_street_name,
    SUM(ws.ws_net_paid) as total_web_spent
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND (
      ca.ca_city LIKE 'San%' 
      OR ca.ca_city LIKE 'New%'
      OR ca.ca_street_name LIKE '%Washington%'
      OR ca.ca_street_name LIKE '%Lincoln%'
  )
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_street_name
HAVING SUM(ws.ws_net_paid) > 2000
ORDER BY total_web_spent DESC
LIMIT 3;


--131
WITH customer_timeline AS (
    SELECT 
        ws.ws_bill_customer_sk as customer_sk,
        ws.ws_sold_date_sk as date_sk,
        i.i_product_name
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND ws.ws_bill_customer_sk IS NOT NULL
),
first_last_purchase AS (
    SELECT DISTINCT
        customer_sk,
        FIRST_VALUE(i_product_name) OVER (
            PARTITION BY customer_sk 
            ORDER BY date_sk ASC
        ) as first_product_bought,
        LAST_VALUE(i_product_name) OVER (
            PARTITION BY customer_sk 
            ORDER BY date_sk ASC 
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) as last_product_bought
    FROM customer_timeline
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    flp.first_product_bought,
    flp.last_product_bought
FROM first_last_purchase flp
JOIN customer c ON flp.customer_sk = c.c_customer_sk
ORDER BY flp.customer_sk
LIMIT 100;

--132
WITH RECURSIVE week_days(calc_date) AS (
    SELECT CAST('2001-01-01' AS DATE)
    UNION ALL
    SELECT CAST(calc_date + INTERVAL '1 day' AS DATE) 
    FROM week_days 
    WHERE calc_date < CAST('2001-01-07' AS DATE)
)
SELECT 
    wd.calc_date,
    COUNT(ss.ss_item_sk) as items_sold
FROM week_days wd
LEFT JOIN date_dim d ON wd.calc_date = d.d_date
LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
GROUP BY wd.calc_date
ORDER BY wd.calc_date;

--133
WITH customer_sales AS (
    SELECT ss_customer_sk, SUM(ss_net_paid) as total_spent
    FROM store_sales
    WHERE ss_customer_sk IS NOT NULL
    GROUP BY ss_customer_sk
),
customer_returns AS (
    SELECT sr_customer_sk, SUM(sr_return_amt) as total_returned
    FROM store_returns
    WHERE sr_customer_sk IS NOT NULL
    GROUP BY sr_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_spent,
    cr.total_returned,
    ROUND((cr.total_returned / cs.total_spent) * 100, 2) as return_percentage
FROM customer_sales cs
JOIN customer_returns cr ON cs.ss_customer_sk = cr.sr_customer_sk
JOIN customer c ON cs.ss_customer_sk = c.c_customer_sk
WHERE cs.total_spent > 1000 
  AND (cr.total_returned / cs.total_spent) > 0.5
ORDER BY return_percentage DESC;


--134
WITH omnichannel_sales AS (
    SELECT ss_customer_sk as customer_sk, SUM(ss_net_paid) as spent FROM store_sales GROUP BY ss_customer_sk
    UNION ALL
    SELECT ws_bill_customer_sk as customer_sk, SUM(ws_net_paid) as spent FROM web_sales GROUP BY ws_bill_customer_sk
    UNION ALL
    SELECT cs_bill_customer_sk as customer_sk, SUM(cs_net_paid) as spent FROM catalog_sales GROUP BY cs_bill_customer_sk
),
customer_total_spent AS (
    SELECT customer_sk, SUM(spent) as grand_total_spent
    FROM omnichannel_sales
    WHERE customer_sk IS NOT NULL
    GROUP BY customer_sk
),
omnichannel_returns AS (
    SELECT sr_customer_sk as customer_sk, SUM(sr_return_amt) as returned_amt FROM store_returns GROUP BY sr_customer_sk
    UNION ALL
    SELECT wr_returning_customer_sk as customer_sk, SUM(wr_return_amt) as returned_amt FROM web_returns GROUP BY wr_returning_customer_sk
    UNION ALL
    SELECT cr_returning_customer_sk as customer_sk, SUM(cr_return_amount) as returned_amt FROM catalog_returns GROUP BY cr_returning_customer_sk
),
customer_total_returned AS (
    SELECT customer_sk, SUM(returned_amt) as grand_total_returned
    FROM omnichannel_returns
    WHERE customer_sk IS NOT NULL
    GROUP BY customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cts.grand_total_spent,
    ctr.grand_total_returned,
    ROUND((ctr.grand_total_returned / cts.grand_total_spent) * 100, 2) as return_percentage
FROM customer_total_spent cts
JOIN customer_total_returned ctr ON cts.customer_sk = ctr.customer_sk
JOIN customer c ON cts.customer_sk = c.c_customer_sk
WHERE cts.grand_total_spent > 1000 
  AND (ctr.grand_total_returned / cts.grand_total_spent) > 0.5
ORDER BY return_percentage DESC
LIMIT 100;

--135
WITH reason_totals AS (
    SELECT 
        r.r_reason_desc,
        COUNT(sr.sr_item_sk) as total_return_transactions,
        SUM(sr.sr_return_amt) as total_money_refunded
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY r.r_reason_desc
)
SELECT 
    r_reason_desc,
    total_return_transactions,
    total_money_refunded,
    ROUND(
        (total_money_refunded / SUM(total_money_refunded) OVER ()) * 100, 
    2) as percentage_of_total_loss
FROM reason_totals
ORDER BY total_money_refunded DESC;

--136
WITH item_promo_metrics AS (
    SELECT 
        i.i_category,
        i.i_item_id,
        i.i_product_name,
        SUM(CASE WHEN ss.ss_promo_sk IS NOT NULL THEN ss.ss_net_paid ELSE 0 END) as promo_revenue,
        SUM(CASE WHEN ss.ss_promo_sk IS NULL THEN ss.ss_net_paid ELSE 0 END) as regular_revenue,
        SUM(ss.ss_net_paid) as total_revenue
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND i.i_category IS NOT NULL
    GROUP BY i.i_category, i.i_item_id, i.i_product_name
    HAVING SUM(ss.ss_net_paid) > 0
)
SELECT 
    i_category,
    i_product_name,
    promo_revenue,
    regular_revenue,
    ROUND((promo_revenue / total_revenue) * 100, 2) as promo_dependency_pct,
    RANK() OVER (PARTITION BY i_category ORDER BY promo_revenue DESC) as category_rank
FROM item_promo_metrics
WHERE (promo_revenue / total_revenue) > 0.30;

--137
WITH item_promo_metrics AS (
    SELECT 
        i.i_category,
        i.i_item_id,
        i.i_product_name,
        SUM(CASE WHEN ss.ss_promo_sk IS NOT NULL THEN ss.ss_net_paid ELSE 0 END) as promo_revenue,
        SUM(CASE WHEN ss.ss_promo_sk IS NULL THEN ss.ss_net_paid ELSE 0 END) as regular_revenue,
        SUM(ss.ss_net_paid) as total_revenue
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND i.i_category IS NOT NULL
    GROUP BY i.i_category, i.i_item_id, i.i_product_name
    HAVING SUM(ss.ss_net_paid) > 0
)
SELECT 
    i_category,
    i_product_name,
    promo_revenue,
    regular_revenue,
    ROUND((promo_revenue / total_revenue) * 100, 2) as promo_dependency_pct,
    RANK() OVER (PARTITION BY i_category ORDER BY promo_revenue DESC) as category_rank
FROM item_promo_metrics
WHERE (promo_revenue / total_revenue) > 0.30
ORDER BY i_category, category_rank
LIMIT 100;

--138
WITH promo_performance AS (
    SELECT 
        p.p_purpose as promotion_type,
        COUNT(ss.ss_item_sk) as items_sold,
        SUM(ss.ss_net_paid) as total_revenue
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
     AND ss.ss_promo_sk IS NOT NULL 
    GROUP BY p.p_purpose
)
SELECT 
    COALESCE(promotion_type, 'Unknown') as promotion_type,
    items_sold,
    total_revenue,
    ROUND(
        (total_revenue / SUM(total_revenue) OVER ()) * 100, 
    2) as percentage_of_all_promos
FROM promo_performance
ORDER BY total_revenue DESC;

--139
SELECT 
    p.p_promo_name,
    p.p_cost as promotion_cost,
    SUM(ss.ss_net_paid) as gross_revenue_generated,
    (SUM(ss.ss_net_paid) - p.p_cost) as net_profit
FROM store_sales ss
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND p.p_cost IS NOT NULL
GROUP BY p.p_promo_name, p.p_cost
ORDER BY net_profit DESC;


--140
WITH promo_aggressiveness AS (
    SELECT 
        p_promo_sk,
        p_promo_name,
        (
            (CASE WHEN p_channel_dmail = 'Y' THEN 1 ELSE 0 END) +
            (CASE WHEN p_channel_email = 'Y' THEN 1 ELSE 0 END) +
            (CASE WHEN p_channel_tv = 'Y' THEN 1 ELSE 0 END) +
            (CASE WHEN p_channel_radio = 'Y' THEN 1 ELSE 0 END) +
            (CASE WHEN p_channel_press = 'Y' THEN 1 ELSE 0 END) +
            (CASE WHEN p_channel_event = 'Y' THEN 1 ELSE 0 END) +
            (CASE WHEN p_channel_demo = 'Y' THEN 1 ELSE 0 END)
        ) as total_channels_used
    FROM promotion
)
SELECT 
    pa.total_channels_used,
    COUNT(DISTINCT pa.p_promo_sk) as number_of_promos_in_category,
    SUM(ss.ss_net_paid) as total_revenue_generated,
    AVG(ss.ss_net_paid) as avg_revenue_per_transaction
FROM store_sales ss
JOIN promo_aggressiveness pa ON ss.ss_promo_sk = pa.p_promo_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY pa.total_channels_used
ORDER BY pa.total_channels_used DESC;

--141
SELECT 
    ws.web_company_name,
    ws.web_country,
    ws.web_city,
    ws.web_tax_percentage,
    COUNT(s.ws_order_number) as total_orders,
    SUM(s.ws_net_paid) as gross_revenue,
    SUM(s.ws_net_paid * (ws.web_tax_percentage / 100)) as estimated_tax_collected
FROM web_sales s
JOIN web_site ws ON s.ws_web_site_sk = ws.web_site_sk
JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND ws.web_tax_percentage IS NOT NULL
GROUP BY ws.web_company_name, ws.web_country, ws.web_city, ws.web_tax_percentage
ORDER BY gross_revenue DESC;

--142
SELECT 
    wp.wp_web_page_id,
    wp.wp_type,
    wp.wp_url,
    COUNT(wr.wr_item_sk) as total_return_incidents,
    SUM(wr.wr_return_amt) as total_money_lost
FROM web_returns wr
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY wp.wp_web_page_id, wp.wp_type, wp.wp_url
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_money_lost DESC;

--143
WITH daily_manager_sales AS (
    SELECT 
        ws.web_manager,
        d.d_date,
        SUM(s.ws_net_paid) as daily_revenue
    FROM web_sales s
    JOIN web_site ws ON s.ws_web_site_sk = ws.web_site_sk
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND ws.web_manager IS NOT NULL
    GROUP BY ws.web_manager, d.d_date
)
SELECT 
    web_manager,
    COUNT(d_date) as days_target_hit,
    SUM(daily_revenue) as total_revenue_on_hit_days
FROM daily_manager_sales
WHERE daily_revenue > 10000
GROUP BY web_manager
ORDER BY days_target_hit DESC;

--144
SELECT 
    sm.sm_carrier,
    sm.sm_type,
    ca.ca_state as destination_state,
    COUNT(ws.ws_order_number) as total_shipments,
    SUM(CASE WHEN (d_ship.d_date - d_sold.d_date) > 5 THEN 1 ELSE 0 END) as delayed_shipments,
    ROUND(AVG(d_ship.d_date - d_sold.d_date), 2) as avg_processing_days
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
WHERE d_sold.d_year = 2002
  AND sm.sm_carrier IS NOT NULL
  AND ws.ws_ship_date_sk IS NOT NULL
GROUP BY sm.sm_carrier, sm.sm_type, ca.ca_state
ORDER BY delayed_shipments DESC, avg_processing_days DESC;

--145
SELECT 
    sm.sm_carrier,
    sm.sm_type,
    ca.ca_state as destination_state,
    COUNT(ws.ws_order_number) as total_shipments,
    SUM(CASE WHEN (d_ship.d_date - d_sold.d_date) > 5 THEN 1 ELSE 0 END) as delayed_shipments,
    ROUND(AVG(d_ship.d_date - d_sold.d_date), 2) as avg_processing_days
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
WHERE d_sold.d_year = 2002
  AND sm.sm_carrier IS NOT NULL
  AND ws.ws_ship_date_sk IS NOT NULL
GROUP BY sm.sm_carrier, sm.sm_type, ca.ca_state
HAVING COUNT(ws.ws_order_number) > 100 
ORDER BY delayed_shipments DESC, avg_processing_days DESC;

--146.
SELECT 
    i.i_category,
    i.i_class,
    sm.sm_type as shipping_speed,
    COUNT(ws.ws_item_sk) as items_shipped,
    SUM(ws.ws_net_paid) as total_revenue,
    SUM(ws.ws_ext_ship_cost) as total_shipping_cost,
    ROUND((SUM(ws.ws_ext_ship_cost) / SUM(ws.ws_net_paid)) * 100, 2) as shipping_cost_percentage
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_category IN ('Furniture', 'Electronics', 'Home')
  AND ws.ws_ext_ship_cost IS NOT NULL
GROUP BY i.i_category, i.i_class, sm.sm_type;

--147

SELECT 
    i.i_category,
    i.i_class,
    sm.sm_type as shipping_speed,
    COUNT(ws.ws_item_sk) as items_shipped,
    SUM(ws.ws_net_paid) as total_revenue,
    SUM(ws.ws_ext_ship_cost) as total_shipping_cost,
    ROUND((SUM(ws.ws_ext_ship_cost) / SUM(ws.ws_net_paid)) * 100, 2) as shipping_cost_percentage
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_category IN ('Furniture', 'Electronics', 'Home')
  AND ws.ws_ext_ship_cost IS NOT NULL
GROUP BY i.i_category, i.i_class, sm.sm_type
ORDER BY shipping_cost_percentage DESC
LIMIT 100;


--148
SELECT 
    w.w_warehouse_name,
    w.w_state as origin_state,
    ca.ca_state as destination_state,
    sm.sm_contract,
    sm.sm_carrier,
    COUNT(cs.cs_order_number) as shipments_count,
    SUM(cs.cs_ext_ship_cost) as total_contract_cost
FROM catalog_sales cs
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND w.w_state != ca.ca_state 
  AND sm.sm_contract IS NOT NULL
GROUP BY w.w_warehouse_name, w.w_state, ca.ca_state, sm.sm_contract, sm.sm_carrier
ORDER BY total_contract_cost DESC
LIMIT 50;


--149
SELECT 
    w.w_warehouse_name,
    w.w_state as origin_state,
    ca.ca_state as destination_state,
    sm.sm_contract,
    sm.sm_carrier,
    COUNT(cs.cs_order_number) as shipments_count,
    SUM(cs.cs_ext_ship_cost) as total_contract_cost
FROM catalog_sales cs
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND w.w_state != ca.ca_state
  AND sm.sm_contract IS NOT NULL
GROUP BY w.w_warehouse_name, w.w_state, ca.ca_state, sm.sm_contract, sm.sm_carrier
HAVING COUNT(cs.cs_order_number) > 100 
   AND SUM(cs.cs_ext_ship_cost) > 5000 
ORDER BY total_contract_cost DESC
LIMIT 50;

--150
SELECT 
    w.w_warehouse_name,
    w.w_state as origin_state,
    ca.ca_state as destination_state,
    sm.sm_contract,
    sm.sm_carrier,
    sm.sm_type as shipping_speed,
    COUNT(cs.cs_order_number) as shipments_count,
    SUM(cs.cs_ext_ship_cost) as total_contract_cost
FROM catalog_sales cs
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT') 
  AND w.w_state != ca.ca_state 
  AND sm.sm_contract IS NOT NULL
GROUP BY w.w_warehouse_name, w.w_state, ca.ca_state, sm.sm_contract, sm.sm_carrier, sm.sm_type
HAVING COUNT(cs.cs_order_number) > 100 
   AND SUM(cs.cs_ext_ship_cost) > 5000 
ORDER BY total_contract_cost DESC
LIMIT 50;

--151
WITH monthly_sales AS (
    SELECT ss_item_sk, ss_store_sk, SUM(ss_quantity) as total_sold
    FROM store_sales
    JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 12
    GROUP BY ss_item_sk, ss_store_sk
),
monthly_inv AS (
    SELECT inv_item_sk, inv_warehouse_sk, AVG(inv_quantity_on_hand) as avg_qoh
    FROM inventory
    JOIN date_dim d ON inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 12
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT 
    i.i_item_id, 
    i.i_product_name,
    w.w_warehouse_name, 
    s.total_sold, 
    ROUND(inv.avg_qoh, 2) as avg_inventory,
    CASE WHEN inv.avg_qoh = 0 THEN 0 ELSE ROUND(s.total_sold / inv.avg_qoh, 2) END as turnover_ratio
FROM monthly_sales s
JOIN monthly_inv inv ON s.ss_item_sk = inv.inv_item_sk
JOIN item i ON s.ss_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE s.total_sold > 50 AND inv.avg_qoh < 100;

--152
WITH monthly_sales AS (
    SELECT ss_item_sk, ss_store_sk, SUM(ss_quantity) as total_sold
    FROM store_sales
    JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 12
    GROUP BY ss_item_sk, ss_store_sk
),
monthly_inv AS (
    SELECT inv_item_sk, inv_warehouse_sk, AVG(inv_quantity_on_hand) as avg_qoh
    FROM inventory
    JOIN date_dim d ON inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 12
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT 
    i.i_item_id, 
    i.i_product_name,
    w.w_warehouse_name, 
    s.total_sold, 
    ROUND(inv.avg_qoh, 2) as avg_inventory,
    CASE WHEN inv.avg_qoh = 0 THEN 0 ELSE ROUND(s.total_sold / inv.avg_qoh, 2) END as turnover_ratio
FROM monthly_sales s
JOIN monthly_inv inv ON s.ss_item_sk = inv.inv_item_sk
JOIN item i ON s.ss_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE s.total_sold > 50 AND inv.avg_qoh < 100
ORDER BY turnover_ratio DESC 
LIMIT 100;

--153

SELECT 
    i.i_class, 
	 w.w_warehouse_name as warehouse_location,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) as total_pieces,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0) * i.i_wholesale_cost) as total_capital_locked
FROM item i
LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk AND d.d_year = 2002 AND d.d_moy = 1
WHERE i.i_category IN ('Electronics', 'Music', 'Jewelry')
GROUP BY i.i_class, w.w_warehouse_name
ORDER BY total_capital_locked DESC;

--154
SELECT 
    i.i_class, 
    w.w_warehouse_name as warehouse_location,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) as total_pieces,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0) * i.i_wholesale_cost) as total_capital_locked
FROM item i
LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk AND d.d_year = 2002 AND d.d_moy = 1
WHERE i.i_category IN ('Electronics', 'Music', 'Jewelry')
GROUP BY i.i_class, w.w_warehouse_name
HAVING SUM(COALESCE(inv.inv_quantity_on_hand, 0) * i.i_wholesale_cost) > 10000000
ORDER BY total_capital_locked DESC;

--155
SELECT 
    i.i_class, 
    w.w_warehouse_name as warehouse_location,
    ROUND(AVG(COALESCE(inv.inv_quantity_on_hand, 0)), 0) as avg_historical_pieces,
    ROUND(AVG(COALESCE(inv.inv_quantity_on_hand, 0) * i.i_wholesale_cost), 2) as avg_capital_locked
FROM item i
LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.i_category IN ('Electronics', 'Music', 'Jewelry')
  AND w.w_warehouse_sq_ft > 500000
GROUP BY i.i_class, w.w_warehouse_name
ORDER BY avg_capital_locked DESC;

--156
WITH inv_fluctuation AS (
    SELECT 
        inv_item_sk, 
        inv_warehouse_sk, 
        d.d_date, 
        inv_quantity_on_hand,
        LAG(inv_quantity_on_hand, 1) OVER (
            PARTITION BY inv_item_sk, inv_warehouse_sk 
            ORDER BY d.d_date
        ) as prev_week_qoh
    FROM inventory
    JOIN date_dim d ON inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy BETWEEN 1 AND 3
)
SELECT 
    i.i_product_name, 
    w.w_warehouse_name, 
    f.d_date as current_snapshot_date, 
    f.prev_week_qoh,
    f.inv_quantity_on_hand as current_qoh,
    (f.prev_week_qoh - f.inv_quantity_on_hand) as quantity_dropped
FROM inv_fluctuation f
JOIN item i ON f.inv_item_sk = i.i_item_sk
JOIN warehouse w ON f.inv_warehouse_sk = w.w_warehouse_sk
WHERE (f.prev_week_qoh - f.inv_quantity_on_hand) > 500;


--157
WITH inv_fluctuation AS (
    SELECT 
        inv_item_sk, 
        inv_warehouse_sk, 
        d.d_date, 
        inv_quantity_on_hand,
        LAG(inv_quantity_on_hand, 1) OVER (
            PARTITION BY inv_item_sk, inv_warehouse_sk 
            ORDER BY d.d_date
        ) as prev_week_qoh
    FROM inventory
    JOIN date_dim d ON inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy BETWEEN 1 AND 3
)
SELECT 
    i.i_product_name, 
    w.w_warehouse_name, 
    f.d_date as current_snapshot_date, 
    f.prev_week_qoh,
    f.inv_quantity_on_hand as current_qoh,
    (f.prev_week_qoh - f.inv_quantity_on_hand) as quantity_dropped
FROM inv_fluctuation f
JOIN item i ON f.inv_item_sk = i.i_item_sk
JOIN warehouse w ON f.inv_warehouse_sk = w.w_warehouse_sk
WHERE (f.prev_week_qoh - f.inv_quantity_on_hand) > 500
ORDER BY quantity_dropped DESC 
LIMIT 3;

--158
WITH ranked_transactions AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        i.i_product_name,
        ss.ss_net_paid,
        ss.ss_ticket_number as receipt_number,
        d.d_date as transaction_date,
        ROW_NUMBER() OVER (
            PARTITION BY ss.ss_customer_sk 
            ORDER BY ss.ss_net_paid DESC NULLS LAST
        ) as transaction_rank
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ss.ss_customer_sk IS NOT NULL
      AND ss.ss_net_paid IS NOT NULL
)
SELECT 
    c_first_name,
    c_last_name,
    i_product_name,
    ss_net_paid as highest_amount_paid,
    receipt_number,
    transaction_date
FROM ranked_transactions
WHERE transaction_rank = 1
ORDER BY highest_amount_paid DESC
LIMIT 100;

--159
WITH ranked_transactions AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        i.i_product_name,
        ss.ss_net_paid,
        ss.ss_ticket_number as receipt_number,
        d.d_date as transaction_date,
        ROW_NUMBER() OVER (
            PARTITION BY ss.ss_customer_sk 
            ORDER BY ss.ss_net_paid DESC NULLS LAST
        ) as transaction_rank
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ss.ss_customer_sk IS NOT NULL
      AND ss.ss_net_paid IS NOT NULL
)
SELECT 
    c_first_name,
    c_last_name,
    transaction_rank,
    i_product_name,
    ss_net_paid as amount_paid,
    receipt_number,
    transaction_date
FROM ranked_transactions
WHERE transaction_rank <= 3
ORDER BY c_last_name, c_first_name, transaction_rank
LIMIT 150;

--160.
SELECT 
    c_customer_sk,
    c_first_name, 
    c_last_name, 
    c_email_address
FROM customer c
WHERE EXISTS (
    SELECT 1 FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_customer_sk = c.c_customer_sk 
      AND i.i_category = 'Jewelry'
)
AND EXISTS (
    SELECT 1 FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = c.c_customer_sk
)
ORDER BY c_last_name ASC;


--161
SELECT 
    ib.ib_lower_bound as income_start,
    ib.ib_upper_bound as income_end,
    hd.hd_dep_count as dependents_count,
    hd.hd_vehicle_count as vehicles_owned,
    COUNT(DISTINCT c.c_customer_sk) as unique_families_count,
    SUM(ss.ss_net_paid) as total_essential_spend,
    ROUND(SUM(ss.ss_net_paid) / COUNT(DISTINCT c.c_customer_sk), 2) as avg_spend_per_family
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_category IN ('Children', 'Food')
  AND hd.hd_dep_count > 0 
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_dep_count, hd.hd_vehicle_count
ORDER BY ib.ib_lower_bound ASC, hd.hd_dep_count DESC;

--162
WITH customer_web_spend AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) as total_web_spend
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_year = 2002
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound as actual_income_start,
    COALESCE(cws.total_web_spend, 0) as online_money_spent
FROM customer c
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN customer_web_spend cws ON c.c_customer_sk = cws.ws_bill_customer_sk
WHERE hd.hd_buy_potential IN ('>10000', '5001-10000') 
  AND ib.ib_lower_bound >= 100000
  AND COALESCE(cws.total_web_spend, 0) < 500;

--163
WITH customer_web_spend AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) as total_web_spend
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_year = 2002
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound as actual_income_start,
    COALESCE(cws.total_web_spend, 0) as online_money_spent
FROM customer c
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN customer_web_spend cws ON c.c_customer_sk = cws.ws_bill_customer_sk
WHERE hd.hd_buy_potential IN ('>10000', '5001-10000') 
  AND ib.ib_lower_bound >= 100000
  AND COALESCE(cws.total_web_spend, 0) < 500
ORDER BY online_money_spent ASC, ib.ib_lower_bound DESC
LIMIT 100;


--164
WITH store_demo_sales AS (
    SELECT 
        hd.hd_income_band_sk, 
        SUM(ss.ss_net_paid) as store_sales
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND hd.hd_vehicle_count >= 2
    GROUP BY hd.hd_income_band_sk
),
web_demo_sales AS (
    SELECT 
        hd.hd_income_band_sk, 
        SUM(ws.ws_net_paid) as web_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND hd.hd_vehicle_count >= 2
    GROUP BY hd.hd_income_band_sk
)
SELECT 
    ib.ib_lower_bound as income_start,
    ib.ib_upper_bound as income_end,
    COALESCE(sds.store_sales, 0) as total_store_spend,
    COALESCE(wds.web_sales, 0) as total_web_spend,
    CASE 
        WHEN COALESCE(wds.web_sales, 0) = 0 THEN 0 
        ELSE ROUND((COALESCE(sds.store_sales, 0) / wds.web_sales), 2) 
    END as store_to_web_ratio
FROM income_band ib
JOIN store_demo_sales sds ON ib.ib_income_band_sk = sds.hd_income_band_sk
LEFT JOIN web_demo_sales wds ON ib.ib_income_band_sk = wds.hd_income_band_sk
ORDER BY income_start ASC;

--165
SELECT 
    ib.ib_lower_bound as income_start,
    ib.ib_upper_bound as income_end,
    COALESCE(sds.store_sales, 0) as total_store_spend,
    COALESCE(wds.web_sales, 0) as total_web_spend,
    CASE 
        WHEN COALESCE(wds.web_sales, 0) = 0 THEN 0 
        ELSE ROUND((COALESCE(sds.store_sales, 0) / wds.web_sales), 2) 
    END as store_to_web_ratio
FROM income_band ib
JOIN (
    SELECT 
        hd.hd_income_band_sk, 
        SUM(ss.ss_net_paid) as store_sales
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND hd.hd_vehicle_count >= 2
    GROUP BY hd.hd_income_band_sk
) sds ON ib.ib_income_band_sk = sds.hd_income_band_sk
LEFT JOIN (
    SELECT 
        hd.hd_income_band_sk, 
        SUM(ws.ws_net_paid) as web_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND hd.hd_vehicle_count >= 2
    GROUP BY hd.hd_income_band_sk
) wds ON ib.ib_income_band_sk = wds.hd_income_band_sk
ORDER BY income_start ASC;

--166.
SELECT 
    ib.ib_lower_bound as income_start,
    ib.ib_upper_bound as income_end,
    COALESCE(sds.store_sales, 0) as total_store_spend,
    COALESCE(wds.web_sales, 0) as total_web_spend,
    CASE 
        WHEN COALESCE(wds.web_sales, 0) = 0 THEN 0 
        ELSE ROUND((COALESCE(sds.store_sales, 0) / wds.web_sales), 2) 
    END as store_to_web_ratio
FROM income_band ib
JOIN (
    SELECT 
        hd.hd_income_band_sk, 
        SUM(ss.ss_net_paid) as store_sales
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND hd.hd_vehicle_count >= 2
    GROUP BY hd.hd_income_band_sk
    HAVING SUM(ss.ss_net_paid) > 22000000 
) sds ON ib.ib_income_band_sk = sds.hd_income_band_sk
LEFT JOIN (
    SELECT 
        hd.hd_income_band_sk, 
        SUM(ws.ws_net_paid) as web_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND hd.hd_vehicle_count >= 2
    GROUP BY hd.hd_income_band_sk
) wds ON ib.ib_income_band_sk = wds.hd_income_band_sk
ORDER BY income_start ASC;

--167
SELECT 
    ca.ca_state as customer_home_state,
    s.s_state as store_location_state,
    COUNT(DISTINCT ss.ss_ticket_number) as border_crossing_trips,
    SUM(ss.ss_net_paid) as total_spent_out_of_state
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 
  AND ca.ca_state != s.s_state 
  AND ca.ca_state IS NOT NULL 
  AND s.s_state IS NOT NULL
GROUP BY ca.ca_state, s.s_state;

--168
SELECT 
    ca.ca_state as customer_home_state,
    s.s_state as store_location_state,
    COUNT(DISTINCT ss.ss_ticket_number) as border_crossing_trips,
    SUM(ss.ss_net_paid) as total_spent_out_of_state
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 
  AND ca.ca_state != s.s_state
  AND ca.ca_state IS NOT NULL 
  AND s.s_state IS NOT NULL
GROUP BY ca.ca_state, s.s_state
HAVING SUM(ss.ss_net_paid) > 100000;

--169
SELECT 
    ca.ca_state as customer_home_state,
    s.s_state as store_location_state,
    COUNT(DISTINCT ss.ss_ticket_number) as border_crossing_trips,
    SUM(ss.ss_net_paid) as total_spent_out_of_state
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 
  AND ca.ca_state != s.s_state
  AND ca.ca_state IS NOT NULL 
  AND s.s_state IS NOT NULL
GROUP BY ca.ca_state, s.s_state
HAVING SUM(ss.ss_net_paid) > 100000
ORDER BY total_spent_out_of_state DESC
LIMIT 50;

--170
SELECT 
    global_rank,
    c_first_name,
    c_last_name,
    customer_home_state,
    store_location_state,
    receipt_number,
    transaction_total
FROM (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_state as customer_home_state,
        s.s_state as store_location_state,
        ss.ss_ticket_number as receipt_number,
        SUM(ss.ss_net_paid) as transaction_total,
        RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) as global_rank
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002 
      AND ca.ca_state != s.s_state 
      AND ca.ca_state IS NOT NULL 
      AND s.s_state IS NOT NULL
    GROUP BY 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_state, 
        s.s_state, 
        ss.ss_ticket_number
) ranked_tickets
WHERE global_rank <= 3
ORDER BY global_rank ASC;

--171
WITH TicketTotals AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_state as customer_home_state,
        s.s_state as store_location_state,
        ss.ss_ticket_number as receipt_number,
        SUM(ss.ss_net_paid) as transaction_total
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002 
      AND ca.ca_state != s.s_state 
      AND ca.ca_state IS NOT NULL 
      AND s.s_state IS NOT NULL
    GROUP BY 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_state, 
        s.s_state, 
        ss.ss_ticket_number
),
RankedTickets AS (
    SELECT 
        c_first_name,
        c_last_name,
        customer_home_state,
        store_location_state,
        receipt_number,
        transaction_total,
        RANK() OVER (ORDER BY transaction_total DESC) as global_rank
    FROM TicketTotals
)
SELECT 
    global_rank,
    c_first_name,
    c_last_name,
    customer_home_state,
    store_location_state,
    receipt_number,
    transaction_total
FROM RankedTickets
WHERE global_rank <= 3
ORDER BY global_rank ASC;

--172
SELECT 
    ca.ca_state,
    ca.ca_county,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_bill_customer_sk) as unique_local_customers,
    SUM(ws.ws_net_paid) as city_total_revenue
FROM web_sales ws
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND ca.ca_state IN ('CA', 'TX', 'NY', 'FL', 'IL') 
GROUP BY ca.ca_state, ca.ca_county, ca.ca_city;

--173
SELECT 
    ca.ca_state,
    ca.ca_county,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_bill_customer_sk) as unique_local_customers,
    SUM(ws.ws_net_paid) as city_total_revenue
FROM web_sales ws
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND ca.ca_state IN ('CA', 'TX', 'NY', 'FL', 'IL') 
GROUP BY ca.ca_state, ca.ca_county, ca.ca_city
HAVING SUM(ws.ws_net_paid) > 100000;

--174
SELECT 
    ca.ca_state,
    ca.ca_county,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_bill_customer_sk) as unique_local_customers,
    SUM(ws.ws_net_paid) as city_total_revenue
FROM web_sales ws
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND ca.ca_state IN ('CA', 'TX', 'NY', 'FL', 'IL') 
GROUP BY ca.ca_state, ca.ca_county, ca.ca_city
HAVING SUM(ws.ws_net_paid) > 100000
ORDER BY city_total_revenue DESC
LIMIT 100;


--175
SELECT 
    ca.ca_location_type as housing_type,
    i.i_category as product_category,
    COUNT(ws.ws_order_number) as total_orders,
    SUM(ws.ws_net_paid) as category_revenue
FROM web_sales ws
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND ca.ca_location_type IS NOT NULL
GROUP BY ca.ca_location_type, i.i_category
ORDER BY housing_type ASC, category_revenue DESC;

--176
SELECT 
    ca.ca_location_type as housing_type,
    i.i_category as product_category,
    COUNT(ws.ws_order_number) as total_orders,
    SUM(ws.ws_net_paid) as category_revenue
FROM web_sales ws
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND ca.ca_location_type IS NOT NULL
GROUP BY ca.ca_location_type, i.i_category
HAVING SUM(ws.ws_net_paid) > 10000
ORDER BY housing_type ASC, category_revenue DESC;

--177
WITH CategoryStats AS (
    SELECT 
        ca.ca_location_type as housing_type,
        i.i_category as product_category,
        COUNT(ws.ws_order_number) as total_orders,
        SUM(ws.ws_net_paid) as category_revenue
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ca.ca_location_type IS NOT NULL
    GROUP BY ca.ca_location_type, i.i_category
    HAVING SUM(ws.ws_net_paid) > 10000
),
RankedCategories AS (
    SELECT 
        housing_type,
        product_category,
        total_orders,
        category_revenue,
        RANK() OVER (PARTITION BY housing_type ORDER BY category_revenue DESC) as popularity_rank
    FROM CategoryStats
)
SELECT 
    housing_type,
    popularity_rank,
    product_category,
    category_revenue
FROM RankedCategories
WHERE popularity_rank <= 3
ORDER BY housing_type ASC, popularity_rank ASC;

--178
SELECT 
    ca.ca_location_type as housing_type,
    i.i_category as product_category,
    SUM(CASE WHEN d.d_year = 2001 THEN ws.ws_net_paid ELSE 0 END) as revenue_2001,
    SUM(CASE WHEN d.d_year = 2002 THEN ws.ws_net_paid ELSE 0 END) as revenue_2002,
    ROUND(
        (SUM(CASE WHEN d.d_year = 2002 THEN ws.ws_net_paid ELSE 0 END) - 
         SUM(CASE WHEN d.d_year = 2001 THEN ws.ws_net_paid ELSE 0 END)) / 
        NULLIF(SUM(CASE WHEN d.d_year = 2001 THEN ws.ws_net_paid ELSE 0 END), 0) * 100, 
    2) as growth_percentage
FROM web_sales ws
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year IN (2001, 2002)
  AND ca.ca_location_type IS NOT NULL
GROUP BY ca.ca_location_type, i.i_category
HAVING SUM(CASE WHEN d.d_year = 2002 THEN ws.ws_net_paid ELSE 0 END) > 10000
ORDER BY housing_type ASC, growth_percentage DESC;

--179
SELECT 
    ca.ca_location_type as housing_type,
    ib.ib_lower_bound as income_start,
    i.i_category as product_category,
    COUNT(ws.ws_order_number) as total_orders,
    SUM(ws.ws_net_paid) as category_revenue,
    ROUND(SUM(ws.ws_net_paid) / COUNT(ws.ws_order_number), 2) as avg_order_value
FROM web_sales ws
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND ca.ca_location_type IS NOT NULL
GROUP BY ca.ca_location_type, ib.ib_lower_bound, i.i_category
ORDER BY housing_type ASC, income_start DESC, category_revenue DESC;

--180
SELECT 
    ca.ca_location_type as housing_type,
    ib.ib_lower_bound as income_start,
    i.i_category as product_category,
    COUNT(ws.ws_order_number) as total_orders,
    SUM(ws.ws_net_paid) as category_revenue,
    ROUND(SUM(ws.ws_net_paid) / COUNT(ws.ws_order_number), 2) as avg_order_value
FROM web_sales ws
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND ca.ca_location_type IS NOT NULL
GROUP BY ca.ca_location_type, ib.ib_lower_bound, i.i_category
HAVING SUM(ws.ws_net_paid) > 150000
ORDER BY housing_type ASC, income_start DESC, category_revenue DESC;

--181
SELECT 
    i.i_category as product_category,
    d.d_moy as month_of_year,
    SUM(CASE WHEN d.d_year = 2001 THEN ss.ss_net_paid ELSE 0 END) as holiday_revenue_2001,
    SUM(CASE WHEN d.d_year = 2002 THEN ss.ss_net_paid ELSE 0 END) as holiday_revenue_2002,
    ROUND(
        (SUM(CASE WHEN d.d_year = 2002 THEN ss.ss_net_paid ELSE 0 END) - 
         SUM(CASE WHEN d.d_year = 2001 THEN ss.ss_net_paid ELSE 0 END)) / 
        SUM(CASE WHEN d.d_year = 2001 THEN ss.ss_net_paid ELSE 0 END) * 100, 
    2) as yoy_holiday_growth
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year IN (2001, 2002)
  AND d.d_moy IN (11, 12) 
  AND i.i_category IN ('Electronics', 'Jewelry')
GROUP BY i.i_category, d.d_moy
ORDER BY product_category ASC, month_of_year ASC;

--182
SELECT 
    q_store.quarter_of_year,
    q_store.total_store_revenue,
    COALESCE(q_web.total_web_revenue, 0) as total_web_revenue,
    ROUND((COALESCE(q_web.total_web_revenue, 0) / q_store.total_store_revenue) * 100, 2) as web_percentage_of_store
FROM (
    SELECT d.d_qoy as quarter_of_year, SUM(ss.ss_net_paid) as total_store_revenue
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_qoy
) q_store
LEFT JOIN (
    SELECT d.d_qoy as quarter_of_year, SUM(ws.ws_net_paid) as total_web_revenue
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_qoy
) q_web ON q_store.quarter_of_year = q_web.quarter_of_year
ORDER BY q_store.quarter_of_year ASC;

--183
WITH omnichannel_sales AS (
    SELECT d.d_qoy as quarter_of_year, ss.ss_net_paid as store_amount, 0 as web_amount, 0 as catalog_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001

    UNION ALL 
    SELECT d.d_qoy as quarter_of_year, 0 as store_amount, ws.ws_net_paid as web_amount, 0 as catalog_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT d.d_qoy as quarter_of_year, 0 as store_amount, 0 as web_amount, cs.cs_net_paid as catalog_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT 
    quarter_of_year,
    SUM(store_amount) as total_store_revenue,
    SUM(web_amount) as total_web_revenue,
    SUM(catalog_amount) as total_catalog_revenue,
    ROUND(
        (SUM(web_amount) / 
        NULLIF(SUM(store_amount) + SUM(web_amount) + SUM(catalog_amount), 0)) * 100, 
    2) as web_percentage_of_total
FROM omnichannel_sales
GROUP BY quarter_of_year
ORDER BY quarter_of_year ASC;

--184
WITH omnichannel_sales AS (
    SELECT d.d_qoy as quarter_of_year, ss.ss_net_paid as store_amount, 0 as web_amount, 0 as catalog_amount
    FROM store_sales ss JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk WHERE d.d_year = 2001
    UNION ALL
    SELECT d.d_qoy as quarter_of_year, 0 as store_amount, ws.ws_net_paid as web_amount, 0 as catalog_amount
    FROM web_sales ws JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk WHERE d.d_year = 2001
    UNION ALL
    SELECT d.d_qoy as quarter_of_year, 0 as store_amount, 0 as web_amount, cs.cs_net_paid as catalog_amount
    FROM catalog_sales cs JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk WHERE d.d_year = 2001
),
quarterly_totals AS (
    SELECT 
        quarter_of_year,
        SUM(store_amount) as total_store_revenue,
        SUM(web_amount) as total_web_revenue,
        SUM(catalog_amount) as total_catalog_revenue
    FROM omnichannel_sales
    GROUP BY quarter_of_year
)
SELECT 
    quarter_of_year,
    total_store_revenue,
    ROUND((total_store_revenue - LAG(total_store_revenue, 1) OVER (ORDER BY quarter_of_year)) / 
          NULLIF(LAG(total_store_revenue, 1) OVER (ORDER BY quarter_of_year), 0) * 100, 2) as store_qoq_growth,
          
    total_web_revenue,
    ROUND((total_web_revenue - LAG(total_web_revenue, 1) OVER (ORDER BY quarter_of_year)) / 
          NULLIF(LAG(total_web_revenue, 1) OVER (ORDER BY quarter_of_year), 0) * 100, 2) as web_qoq_growth,
          
    total_catalog_revenue,
    ROUND((total_catalog_revenue - LAG(total_catalog_revenue, 1) OVER (ORDER BY quarter_of_year)) / 
          NULLIF(LAG(total_catalog_revenue, 1) OVER (ORDER BY quarter_of_year), 0) * 100, 2) as catalog_qoq_growth
FROM quarterly_totals
ORDER BY quarter_of_year ASC;


--185
SELECT 
    d_date as sales_date,
    daily_revenue,
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY d_date 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ), 
    2) as moving_avg_30_days
FROM (
    SELECT 
        d.d_date,
        SUM(ss.ss_net_paid) as daily_revenue
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002 
      AND d.d_moy BETWEEN 1 AND 6
    GROUP BY d.d_date
) daily_aggregated
ORDER BY sales_date ASC;

--186
SELECT 
    cd.cd_gender as gender,
    cd.cd_education_status as education_level,
    i.i_category as product_category,
    COUNT(DISTINCT ss.ss_ticket_number) as total_weekend_trips,
    SUM(ss.ss_net_paid) as total_weekend_spend,
    ROUND(AVG(ss.ss_net_paid), 2) as avg_spend_per_item
FROM store_sales ss
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND d.d_day_name IN ('Saturday', 'Sunday') 
  AND cd.cd_marital_status = 'S'
  AND cd.cd_education_status IN ('Advanced Degree', 'College')
GROUP BY cd.cd_gender, cd.cd_education_status, i.i_category
ORDER BY total_weekend_spend DESC;

--187
SELECT 
    cd.cd_gender as gender,
    cd.cd_education_status as education_level,
    i.i_category as product_category,
    COUNT(DISTINCT ss.ss_ticket_number) as total_weekend_trips,
    SUM(ss.ss_net_paid) as total_weekend_spend,
    ROUND(AVG(ss.ss_net_paid), 2) as avg_spend_per_item
FROM store_sales ss
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND d.d_day_name IN ('Saturday', 'Sunday') 
  AND cd.cd_marital_status = 'S'
  AND cd.cd_education_status IN ('Advanced Degree', 'College')
GROUP BY cd.cd_gender, cd.cd_education_status, i.i_category
HAVING SUM(ss.ss_net_paid) > 50000 
   AND AVG(ss.ss_net_paid) > 50 
ORDER BY total_weekend_spend DESC;

--188
SELECT 
    w.w_warehouse_name as warehouse_name, 
    w.w_state as state_location, 
    SUM(ws.ws_quantity) as total_items_shipped, 
    SUM(ws.ws_net_paid) as total_revenue_fulfilled
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
GROUP BY w.w_warehouse_name, w.w_state
HAVING SUM(ws.ws_net_paid) > 1000000
ORDER BY total_revenue_fulfilled DESC;

--189
SELECT 
    w.w_warehouse_name as warehouse_name, 
    i.i_category as product_category, 
    SUM(inv.inv_quantity_on_hand) as total_units_in_stock, 
    SUM(inv.inv_quantity_on_hand * i.i_wholesale_cost) as total_capital_tied_up
FROM inventory inv
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND d.d_moy = 12 
GROUP BY w.w_warehouse_name, i.i_category
ORDER BY w.w_warehouse_name ASC, total_capital_tied_up DESC;

--190
SELECT 
    w.w_warehouse_name as warehouse_name, 
    i.i_category as product_category, 
    SUM(inv.inv_quantity_on_hand) as total_units_in_stock, 
    SUM(inv.inv_quantity_on_hand * i.i_wholesale_cost) as total_capital_tied_up
FROM inventory inv
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND d.d_moy = 12 
GROUP BY w.w_warehouse_name, i.i_category
HAVING SUM(inv.inv_quantity_on_hand * i.i_wholesale_cost) > 500000
ORDER BY w.w_warehouse_name ASC, total_capital_tied_up DESC;

--191
SELECT 
    w.w_warehouse_name as warehouse_name, 
    i.i_category as product_category, 
    SUM(inv.inv_quantity_on_hand) as total_units_in_stock, 
    SUM(inv.inv_quantity_on_hand * i.i_wholesale_cost) as total_capital_tied_up
FROM inventory inv
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND d.d_moy = 12 
GROUP BY w.w_warehouse_name, i.i_category
HAVING SUM(inv.inv_quantity_on_hand * i.i_wholesale_cost) > 500000
ORDER BY w.w_warehouse_name ASC, total_capital_tied_up DESC
LIMIT 1;

--192
SELECT 
    i.i_item_id as product_id,
    i.i_product_name as product_name,
    inv.total_tied_capital,
    COALESCE(ss.total_sales_revenue, 0) as total_sales_revenue,
    CASE 
        WHEN COALESCE(ss.total_sales_revenue, 0) = 0 THEN 'Dead Stock'
        WHEN inv.total_tied_capital > COALESCE(ss.total_sales_revenue, 0) * 2 THEN 'Overstocked'
        ELSE 'Healthy'
    END as stock_health_status
FROM (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand * i.i_wholesale_cost) as total_tied_capital
    FROM inventory
    JOIN item i ON inv_item_sk = i.i_item_sk
    JOIN date_dim d ON inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 12
    GROUP BY inv_item_sk
) inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT 
        ss_item_sk, 
        SUM(ss_net_paid) as total_sales_revenue
    FROM store_sales
    JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss_item_sk
) ss ON inv.inv_item_sk = ss.ss_item_sk
ORDER BY inv.total_tied_capital DESC;


--193
SELECT 
    i.i_item_id as product_id,
    i.i_product_name as product_name,
    inv.total_tied_capital,
    COALESCE(ss.total_sales_revenue, 0) as total_sales_revenue,
    CASE 
        WHEN COALESCE(ss.total_sales_revenue, 0) = 0 THEN 'Dead Stock'
        WHEN inv.total_tied_capital > COALESCE(ss.total_sales_revenue, 0) * 2 THEN 'Overstocked'
        ELSE 'Healthy'
    END as stock_health_status
FROM (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand * i.i_wholesale_cost) as total_tied_capital
    FROM inventory
    JOIN item i ON inv_item_sk = i.i_item_sk
    JOIN date_dim d ON inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND d.d_moy = 12
    GROUP BY inv_item_sk
    HAVING SUM(inv_quantity_on_hand * i.i_wholesale_cost) > 100000
) inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT 
        ss_item_sk, 
        SUM(ss_net_paid) as total_sales_revenue
    FROM store_sales
    JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss_item_sk
) ss ON inv.inv_item_sk = ss.ss_item_sk
ORDER BY inv.total_tied_capital DESC;


--194.
SELECT 
    w.w_warehouse_name as fulfillment_center, 
    w.w_state as warehouse_state, 
    ca.ca_state as customer_destination_state, 
    COUNT(ws.ws_order_number) as long_distance_shipments, 
    SUM(ws.ws_ext_ship_cost) as total_shipping_cost
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 
  AND w.w_state != ca.ca_state 
  AND w.w_state IS NOT NULL 
  AND ca.ca_state IS NOT NULL
GROUP BY w.w_warehouse_name, w.w_state, ca.ca_state;


--195
SELECT 
    w.w_warehouse_name as fulfillment_center, 
    w.w_state as warehouse_state, 
    ca.ca_state as customer_destination_state, 
    COUNT(ws.ws_order_number) as long_distance_shipments, 
    SUM(ws.ws_ext_ship_cost) as total_shipping_cost
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 
  AND w.w_state != ca.ca_state 
  AND w.w_state IS NOT NULL 
  AND ca.ca_state IS NOT NULL
GROUP BY w.w_warehouse_name, w.w_state, ca.ca_state
HAVING COUNT(ws.ws_order_number) > 1000;


--196
SELECT 
    w.w_warehouse_name as fulfillment_center, 
    w.w_state as warehouse_state, 
    ca.ca_state as customer_destination_state, 
    COUNT(ws.ws_order_number) as long_distance_shipments, 
    SUM(ws.ws_ext_ship_cost) as total_shipping_cost
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 
  AND w.w_state != ca.ca_state 
  AND w.w_state IS NOT NULL 
  AND ca.ca_state IS NOT NULL
GROUP BY w.w_warehouse_name, w.w_state, ca.ca_state
HAVING COUNT(ws.ws_order_number) > 1000
ORDER BY total_shipping_cost DESC 
LIMIT 5;

--197
SELECT DISTINCT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    CASE 
        WHEN cs.cs_bill_customer_sk IS NOT NULL THEN 'Client Omnichannel' 
        ELSE 'Exclusiv Web' 
    END as catalog_engagement
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
WHERE i.i_category = 'Jewelry'
ORDER BY c.c_last_name ASC;

--198
SELECT DISTINCT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    CASE 
        WHEN ss_music.ss_customer_sk IS NULL THEN 'Trimite Voucher Muzica' 
        ELSE 'A Cumparat Deja Muzica' 
    END as cross_sell_action
FROM store_sales ss_elec
JOIN item i_elec ON ss_elec.ss_item_sk = i_elec.i_item_sk
JOIN customer c ON ss_elec.ss_customer_sk = c.c_customer_sk
LEFT JOIN store_sales ss_music ON c.c_customer_sk = ss_music.ss_customer_sk 
    AND ss_music.ss_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Music')
WHERE i_elec.i_category = 'Electronics'
ORDER BY cross_sell_action DESC, c.c_last_name ASC;

--199
SELECT 
    cc.cc_call_center_id, 
    cc.cc_name as call_center_name, 
    cc.cc_manager, 
    COUNT(cr.cr_order_number) as total_return_tickets, 
    SUM(cr.cr_return_amount) as total_refunded_amount, 
    ROUND(AVG(cr.cr_return_amount), 2) as avg_refund_per_ticket
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2002
GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_manager
HAVING SUM(cr.cr_return_amount) > 100000
ORDER BY total_refunded_amount DESC;

--200
SELECT 
    web.web_name as website_name, 
    sm.sm_type as shipping_method, 
    sm.sm_carrier as shipping_carrier, 
    COUNT(ws.ws_order_number) as night_orders_count, 
    SUM(ws.ws_net_paid) as night_revenue
FROM web_sales ws
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND t.t_hour BETWEEN 0 AND 5 
GROUP BY web.web_name, sm.sm_type, sm.sm_carrier
ORDER BY night_revenue DESC;

--201
SELECT 
    web.web_name as website_name, 
    sm.sm_type as shipping_method, 
    sm.sm_carrier as shipping_carrier, 
    COUNT(ws.ws_order_number) as night_orders_count, 
    SUM(ws.ws_net_paid) as night_revenue
FROM web_sales ws
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND t.t_hour BETWEEN 0 AND 5 
GROUP BY web.web_name, sm.sm_type, sm.sm_carrier
HAVING COUNT(ws.ws_order_number) > 200 
ORDER BY night_revenue DESC;

--202
WITH NightSales AS (
    SELECT 
        web.web_name as website_name, 
        sm.sm_type as shipping_method, 
        sm.sm_carrier as shipping_carrier, 
        COUNT(ws.ws_order_number) as night_orders_count, 
        SUM(ws.ws_net_paid) as night_revenue
    FROM web_sales ws
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 0 AND 5 
    GROUP BY web.web_name, sm.sm_type, sm.sm_carrier
    HAVING COUNT(ws.ws_order_number) > 200
)
SELECT 
    website_name, 
    shipping_method, 
    shipping_carrier, 
    night_orders_count, 
    night_revenue, 
    RANK() OVER (
        PARTITION BY website_name 
        ORDER BY night_revenue DESC
    ) as carrier_rank
FROM NightSales
ORDER BY website_name ASC, carrier_rank ASC;

--203
SELECT 
    CASE 
        WHEN t.t_hour BETWEEN 6 AND 11 THEN '1. Dimineata (06-11)'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN '2. Dupa-amiaza (12-17)'
        WHEN t.t_hour BETWEEN 18 AND 23 THEN '3. Seara (18-23)'
        ELSE '4. Noaptea (00-05)' 
    END as day_part,
    COUNT(ss.ss_ticket_number) as total_transactions,
    SUM(ss.ss_net_paid) as total_revenue
FROM store_sales ss
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY day_part
ORDER BY day_part ASC;

--204
SELECT 
    d.d_date as sales_date,
    SUM(ws.ws_net_paid) as daily_revenue,
    SUM(SUM(ws.ws_net_paid)) OVER (
        ORDER BY d.d_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as current_total
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 
  AND d.d_moy = 1 
GROUP BY d.d_date
ORDER BY d.d_date ASC;

--205
SELECT 
    daily_stats.sales_date,
    daily_stats.daily_revenue,
    SUM(daily_stats.daily_revenue) OVER (
        ORDER BY daily_stats.sales_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as current_total
FROM (
    SELECT 
        d.d_date as sales_date,
        SUM(ws.ws_net_paid) as daily_revenue
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002 
      AND d.d_qoy = 1 
    GROUP BY d.d_date
    HAVING SUM(ws.ws_net_paid) > 500000 
) daily_stats
ORDER BY daily_stats.sales_date ASC;

--206
SELECT 
    daily_stats.product_category,
    daily_stats.sales_date,
    daily_stats.daily_revenue,
    SUM(daily_stats.daily_revenue) OVER (
        PARTITION BY daily_stats.product_category 
        ORDER BY daily_stats.sales_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as category_current_total
FROM (
    SELECT 
        i.i_category as product_category,
        d.d_date as sales_date,
        SUM(ws.ws_net_paid) as daily_revenue
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2002 
      AND d.d_qoy = 1 
      AND i.i_category IN ('Electronics', 'Books', 'Music') 
    GROUP BY i.i_category, d.d_date
    HAVING SUM(ws.ws_net_paid) > 50000 
) daily_stats
ORDER BY daily_stats.product_category ASC, daily_stats.sales_date ASC;

--207
SELECT 
    daily_stats.sales_date,
    SUM(CASE WHEN elec_daily > 50000 THEN elec_daily ELSE 0 END) OVER (
        ORDER BY daily_stats.sales_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as electronics_ytd,
    
    SUM(CASE WHEN books_daily > 50000 THEN books_daily ELSE 0 END) OVER (
        ORDER BY daily_stats.sales_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as books_ytd,
    
    SUM(CASE WHEN music_daily > 50000 THEN music_daily ELSE 0 END) OVER (
        ORDER BY daily_stats.sales_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as music_ytd
FROM (
    SELECT 
        d.d_date as sales_date,
        SUM(CASE WHEN i.i_category = 'Electronics' THEN ws.ws_net_paid ELSE 0 END) as elec_daily,
        SUM(CASE WHEN i.i_category = 'Books' THEN ws.ws_net_paid ELSE 0 END) as books_daily,
        SUM(CASE WHEN i.i_category = 'Music' THEN ws.ws_net_paid ELSE 0 END) as music_daily
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2002 
      AND d.d_qoy = 1 
      AND i.i_category IN ('Electronics', 'Books', 'Music')
    GROUP BY d.d_date
) daily_stats
WHERE daily_stats.elec_daily > 50000 
   OR daily_stats.books_daily > 50000 
   OR daily_stats.music_daily > 50000
ORDER BY daily_stats.sales_date ASC;

--208
SELECT
i2.i_category as associated_category,
    COUNT(DISTINCT ss1.ss_ticket_number) as times_bought_together
FROM store_sales ss1
JOIN store_sales ss2 ON ss1.ss_ticket_number = ss2.ss_ticket_number 
                     AND ss1.ss_item_sk != ss2.ss_item_sk
JOIN item i1 ON ss1.ss_item_sk = i1.i_item_sk
JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
JOIN date_dim d ON ss1.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 
  AND i1.i_category = 'Men'
  AND i2.i_category != 'Men'
GROUP BY i2.i_category
ORDER BY times_bought_together DESC
LIMIT 5;

--209
SELECT 
    i1.i_product_name as primary_product,
    i2.i_product_name as secondary_product
FROM store_sales ss1
JOIN store_sales ss2 ON ss1.ss_ticket_number = ss2.ss_ticket_number 
                     AND ss1.ss_item_sk < ss2.ss_item_sk 
JOIN item i1 ON ss1.ss_item_sk = i1.i_item_sk
JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
JOIN date_dim d ON ss1.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 
  AND i1.i_category = 'Electronics'
  AND i2.i_category = 'Electronics'
GROUP BY i1.i_product_name, i2.i_product_name;

--210
SELECT 
    i1.i_product_name as primary_product,
    i2.i_product_name as secondary_product,
    COUNT(DISTINCT ss1.ss_ticket_number) as joint_purchases
FROM store_sales ss1
JOIN store_sales ss2 ON ss1.ss_ticket_number = ss2.ss_ticket_number 
                     AND ss1.ss_item_sk < ss2.ss_item_sk 
JOIN item i1 ON ss1.ss_item_sk = i1.i_item_sk
JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
JOIN date_dim d ON ss1.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 
  AND i1.i_category = 'Electronics'
  AND i2.i_category = 'Electronics'
GROUP BY i1.i_product_name, i2.i_product_name
HAVING COUNT(DISTINCT ss1.ss_ticket_number) > 30;

--211
SELECT 
    i1.i_product_name as primary_product,
    i2.i_product_name as secondary_product,
    COUNT(DISTINCT ss1.ss_ticket_number) as joint_purchases
FROM store_sales ss1
JOIN store_sales ss2 ON ss1.ss_ticket_number = ss2.ss_ticket_number 
                     AND ss1.ss_item_sk < ss2.ss_item_sk 
JOIN item i1 ON ss1.ss_item_sk = i1.i_item_sk
JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
JOIN date_dim d ON ss1.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002 
  AND i1.i_category = 'Electronics'
  AND i2.i_category = 'Electronics'
GROUP BY i1.i_product_name, i2.i_product_name
HAVING COUNT(DISTINCT ss1.ss_ticket_number) > 30
ORDER BY joint_purchases DESC
LIMIT 10;

--212
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    MIN(d1.d_date) as first_purchase_date, 
    MAX(d1.d_date) as last_purchase_date, 
    SUM(ss1.ss_net_paid) as total_historical_spend 
FROM store_sales ss1 
JOIN customer c ON ss1.ss_customer_sk = c.c_customer_sk 
JOIN date_dim d1 ON ss1.ss_sold_date_sk = d1.d_date_sk 
WHERE d1.d_year BETWEEN 2000 AND 2001 
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name;

--213
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    MIN(d1.d_date) as first_purchase_date, 
    MAX(d1.d_date) as last_purchase_date, 
    SUM(ss1.ss_net_paid) as total_historical_spend 
FROM store_sales ss1 
JOIN customer c ON ss1.ss_customer_sk = c.c_customer_sk 
JOIN date_dim d1 ON ss1.ss_sold_date_sk = d1.d_date_sk 
LEFT JOIN (
    SELECT DISTINCT ss_customer_sk 
    FROM store_sales ss2 
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk 
    WHERE d2.d_year = 2002
) active_2002 ON c.c_customer_sk = active_2002.ss_customer_sk 
WHERE d1.d_year BETWEEN 2000 AND 2001 
  AND active_2002.ss_customer_sk IS NULL 
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name;

--214
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    MIN(d1.d_date) as first_purchase_date, 
    MAX(d1.d_date) as last_purchase_date, 
    SUM(ss1.ss_net_paid) as total_historical_spend 
FROM store_sales ss1 
JOIN customer c ON ss1.ss_customer_sk = c.c_customer_sk 
JOIN date_dim d1 ON ss1.ss_sold_date_sk = d1.d_date_sk 
LEFT JOIN (
    SELECT DISTINCT ss_customer_sk 
    FROM store_sales ss2 
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk 
    WHERE d2.d_year = 2002
) active_2002 ON c.c_customer_sk = active_2002.ss_customer_sk 
WHERE d1.d_year BETWEEN 2000 AND 2001 
  AND active_2002.ss_customer_sk IS NULL 
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name 
HAVING SUM(ss1.ss_net_paid) > 5000 
ORDER BY total_historical_spend DESC 
LIMIT 50;

--215
WITH ActiveCustomers2002 AS (
    SELECT DISTINCT ss_customer_sk 
    FROM store_sales 
    JOIN date_dim ON ss_sold_date_sk = d_date_sk 
    WHERE d_year = 2002
)
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    MIN(d1.d_date) as first_purchase_date, 
    MAX(d1.d_date) as last_purchase_date, 
    SUM(ss1.ss_net_paid) as total_historical_spend 
FROM store_sales ss1 
JOIN customer c ON ss1.ss_customer_sk = c.c_customer_sk 
JOIN date_dim d1 ON ss1.ss_sold_date_sk = d1.d_date_sk 
LEFT JOIN ActiveCustomers2002 a ON c.c_customer_sk = a.ss_customer_sk 
WHERE d1.d_year BETWEEN 2000 AND 2001 
  AND a.ss_customer_sk IS NULL 
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name 
HAVING SUM(ss1.ss_net_paid) > 5000 
ORDER BY total_historical_spend DESC 
LIMIT 50;

--216
SELECT 
    i.i_category, 
    i.i_product_name, 
    MIN(ws.ws_net_paid) as lowest_price_paid, 
    MAX(ws.ws_net_paid) as highest_price_paid, 
    COUNT(ws.ws_order_number) as total_sales_volume
FROM web_sales ws 
JOIN item i ON ws.ws_item_sk = i.i_item_sk 
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
WHERE d.d_year BETWEEN 1999 AND 2002 
  AND i.i_category IN ('Electronics', 'Home', 'Jewelry') 
GROUP BY i.i_category, i.i_product_name;

--217
SELECT 
    i.i_category, 
    i.i_product_name, 
    MIN(ws.ws_net_paid) as lowest_price_paid, 
    MAX(ws.ws_net_paid) as highest_price_paid, 
    COUNT(ws.ws_order_number) as total_sales_volume, 
    COALESCE(SUM(wr.wr_return_amt), 0) as total_return_loss 
FROM web_sales ws 
JOIN item i ON ws.ws_item_sk = i.i_item_sk 
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk 
                        AND ws.ws_order_number = wr.wr_order_number 
WHERE d.d_year BETWEEN 1999 AND 2002 
  AND i.i_category IN ('Electronics', 'Home', 'Jewelry') 
GROUP BY i.i_category, i.i_product_name;

--218
SELECT 
    i.i_category, 
    i.i_product_name, 
    MIN(ws.ws_net_paid) as lowest_price_paid, 
    MAX(ws.ws_net_paid) as highest_price_paid, 
    COUNT(ws.ws_order_number) as total_sales_volume, 
    COALESCE(SUM(wr.wr_return_amt), 0) as total_return_loss 
FROM web_sales ws 
JOIN item i ON ws.ws_item_sk = i.i_item_sk 
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk 
                        AND ws.ws_order_number = wr.wr_order_number 
WHERE d.d_year BETWEEN 1999 AND 2002 
  AND i.i_category IN ('Electronics', 'Home', 'Jewelry') 
GROUP BY i.i_category, i.i_product_name 
HAVING MIN(ws.ws_net_paid) < MAX(ws.ws_net_paid) * 0.5 
ORDER BY total_return_loss DESC, total_sales_volume DESC 
LIMIT 50;

--219
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    MIN(d.d_date) as first_store_purchase, 
    MAX(d.d_date) as last_store_purchase, 
    MAX(ss.ss_net_paid) as max_single_ticket_spend
FROM store_sales ss 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE d.d_year BETWEEN 2000 AND 2002 
  AND c.c_preferred_cust_flag = 'Y' 
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name;

--220
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    MIN(d.d_date) as first_store_purchase, 
    MAX(d.d_date) as last_store_purchase, 
    MAX(ss.ss_net_paid) as max_single_ticket_spend,
    cc_returns.cr_customer_sk as returned_customer_sk
FROM store_sales ss 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
LEFT JOIN (
    SELECT DISTINCT cr_returning_customer_sk as cr_customer_sk 
    FROM catalog_returns cr 
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk 
    WHERE d2.d_year BETWEEN 2000 AND 2002
) cc_returns ON c.c_customer_sk = cc_returns.cr_customer_sk 
WHERE d.d_year BETWEEN 2000 AND 2002 
  AND c.c_preferred_cust_flag = 'Y' 
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cc_returns.cr_customer_sk;

--221
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    MIN(d.d_date) as first_store_purchase, 
    MAX(d.d_date) as last_store_purchase, 
    MAX(ss.ss_net_paid) as max_single_ticket_spend, 
    CASE 
        WHEN cc_returns.cr_customer_sk IS NOT NULL THEN 'Y' 
        ELSE 'N' 
    END as has_call_center_history 
FROM store_sales ss 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
LEFT JOIN (
    SELECT DISTINCT cr_returning_customer_sk as cr_customer_sk 
    FROM catalog_returns cr 
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk 
    WHERE d2.d_year BETWEEN 2000 AND 2002
) cc_returns ON c.c_customer_sk = cc_returns.cr_customer_sk 
WHERE d.d_year BETWEEN 2000 AND 2002 
  AND c.c_preferred_cust_flag = 'Y' 
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cc_returns.cr_customer_sk;
   
--222
   SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    MIN(d.d_date) as first_store_purchase, 
    MAX(d.d_date) as last_store_purchase, 
    MAX(ss.ss_net_paid) as max_single_ticket_spend, 
    CASE 
        WHEN cc_returns.cr_customer_sk IS NOT NULL THEN 'Y' 
        ELSE 'N' 
    END as has_call_center_history 
FROM store_sales ss 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
LEFT JOIN (
    SELECT DISTINCT cr_returning_customer_sk as cr_customer_sk 
    FROM catalog_returns cr 
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk 
    WHERE d2.d_year BETWEEN 2000 AND 2002
) cc_returns ON c.c_customer_sk = cc_returns.cr_customer_sk 
WHERE d.d_year BETWEEN 2000 AND 2002 
  AND c.c_preferred_cust_flag = 'Y' 
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cc_returns.cr_customer_sk 
HAVING MAX(ss.ss_net_paid) > 2000 
   AND MIN(d.d_date) < '2001-01-01' 
ORDER BY max_single_ticket_spend DESC 
LIMIT 50;


--223
SELECT 
    w.w_warehouse_name, 
    i.i_item_id, 
    i.i_product_name, 
    MIN(inv.inv_quantity_on_hand) as minimum_stock_level,
    AVG(inv.inv_quantity_on_hand) as average_stock_level
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND d.d_moy = 12
GROUP BY 
    w.w_warehouse_name, 
    i.i_item_id, 
    i.i_product_name
HAVING MIN(inv.inv_quantity_on_hand) < 100;


--224
SELECT 
    w.w_warehouse_name, 
    i.i_item_id, 
    i.i_product_name, 
    MIN(inv.inv_quantity_on_hand) as minimum_stock_level,
    AVG(inv.inv_quantity_on_hand) as average_stock_level
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND d.d_moy = 12
GROUP BY 
    w.w_warehouse_name, 
    i.i_item_id, 
    i.i_product_name
HAVING MIN(inv.inv_quantity_on_hand) < 100
ORDER BY minimum_stock_level ASC
LIMIT 50;

--225
WITH DemographicsSpend AS (
    SELECT 
        ca.ca_state as state, 
        cd.cd_gender as gender, 
        ib.ib_lower_bound || ' - ' || ib.ib_upper_bound as income_range, 
        COUNT(DISTINCT c.c_customer_sk) as unique_customers, 
        SUM(ss.ss_net_paid) as total_spend,
        ROUND(AVG(ss.ss_net_paid), 2) as avg_spend_per_ticket
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ca.ca_state LIKE 'C%' 
      AND cd.cd_gender IN ('M','F')
      AND d.d_year = 2001
    GROUP BY 
        ca.ca_state, 
        cd.cd_gender, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound
    HAVING SUM(ss.ss_net_paid) > 50000
)
SELECT 
    state, 
    gender, 
    income_range, 
    unique_customers, 
    total_spend, 
    RANK() OVER (
        PARTITION BY state 
        ORDER BY total_spend DESC
    ) as segment_rank_in_state
FROM DemographicsSpend
ORDER BY state ASC, segment_rank_in_state ASC;

--226
SELECT 
    ds.state, 
    ds.gender, 
    ds.income_range, 
    ds.unique_customers, 
    ds.total_spend, 
    RANK() OVER (
        PARTITION BY ds.state 
        ORDER BY ds.total_spend DESC
    ) as segment_rank_in_state
FROM (
    SELECT 
        ca.ca_state as state, 
        cd.cd_gender as gender, 
        ib.ib_lower_bound || ' - ' || ib.ib_upper_bound as income_range, 
        COUNT(DISTINCT c.c_customer_sk) as unique_customers, 
        SUM(ss.ss_net_paid) as total_spend
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ca.ca_state LIKE 'C%' 
      AND cd.cd_gender IN ('M','F')
      AND d.d_year = 2001
    GROUP BY 
        ca.ca_state, 
        cd.cd_gender, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound
    HAVING SUM(ss.ss_net_paid) > 50000
) ds
ORDER BY 
    ds.state ASC, 
    segment_rank_in_state ASC;

--227
WITH WebSpendPerCustomer AS (
    SELECT 
        ws_bill_customer_sk as customer_sk, 
        SUM(ws_net_paid) as total_web_spend
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_year = 2000
    GROUP BY ws_bill_customer_sk
),
AvgWebSpend AS (
    SELECT AVG(total_web_spend) as national_avg_web_spend
    FROM WebSpendPerCustomer
)
SELECT 
    c.c_customer_id, 
    c.c_last_name, 
    c.c_first_name, 
    SUM(ss.ss_net_paid) as total_store_spend,
    COALESCE(w.total_web_spend, 0) as actual_web_spend 
FROM store_sales ss 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
LEFT JOIN WebSpendPerCustomer w ON c.c_customer_sk = w.customer_sk
WHERE d.d_year = 2000 
  AND ca.ca_state = 'TX' 
GROUP BY 
    c.c_customer_id, 
    c.c_last_name, 
    c.c_first_name, 
    w.total_web_spend 
HAVING SUM(ss.ss_net_paid) > (SELECT national_avg_web_spend FROM AvgWebSpend) 
ORDER BY total_store_spend DESC
LIMIT 50;

--228
WITH WebSpendPerCustomer AS (
    SELECT 
        ws_bill_customer_sk as customer_sk, 
        SUM(ws_net_paid) as total_web_spend
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_year = 2000
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_customer_id, 
    c.c_last_name, 
    c.c_first_name, 
    SUM(ss.ss_net_paid) as total_store_spend,
    COALESCE(w.total_web_spend, 0) as actual_web_spend 
FROM store_sales ss 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
LEFT JOIN WebSpendPerCustomer w ON c.c_customer_sk = w.customer_sk
WHERE d.d_year = 2000 
  AND ca.ca_state = 'TX' 
GROUP BY 
    c.c_customer_id, 
    c.c_last_name, 
    c.c_first_name, 
    w.total_web_spend 
HAVING SUM(ss.ss_net_paid) > (SELECT AVG(total_web_spend) FROM WebSpendPerCustomer) 
ORDER BY total_store_spend DESC
LIMIT 50;

--229
SELECT 
    cd.cd_education_status, 
    cd.cd_marital_status, 
    COUNT(DISTINCT c.c_customer_sk) as unique_shoppers,
    ROUND(AVG(ss.ss_net_paid), 2) as avg_ticket_value
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND d.d_day_name IN ('Saturday', 'Sunday')
GROUP BY 
    cd.cd_education_status, 
    cd.cd_marital_status
ORDER BY avg_ticket_value DESC;

--230
SELECT 
    ca.ca_state as customer_state, 
    cd.cd_education_status as education_level, 
    i.i_category, 
    SUM(ws.ws_quantity) as total_items_sold,
    COALESCE(SUM(wr.wr_return_quantity), 0) as total_items_returned,
    ROUND((COALESCE(SUM(wr.wr_return_quantity), 0) * 100.0) / SUM(ws.ws_quantity), 2) as return_rate_pct,
    COALESCE(SUM(wr.wr_return_amt), 0) as total_money_lost
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk 
                        AND ws.ws_order_number = wr.wr_order_number
WHERE d.d_year = 2002 
  AND i.i_category IN ('Sports', 'Books', 'Music')
  AND ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_state, 
    cd.cd_education_status, 
    i.i_category;

--231
SELECT 
    ca.ca_state as customer_state, 
    cd.cd_education_status as education_level, 
    i.i_category, 
    SUM(ws.ws_quantity) as total_items_sold,
    COALESCE(SUM(wr.wr_return_quantity), 0) as total_items_returned,
    ROUND((COALESCE(SUM(wr.wr_return_quantity), 0) * 100.0) / SUM(ws.ws_quantity), 2) as return_rate_pct,
    COALESCE(SUM(wr.wr_return_amt), 0) as total_money_lost
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk 
                        AND ws.ws_order_number = wr.wr_order_number
WHERE d.d_year = 2002 
  AND i.i_category IN ('Sports', 'Books', 'Music')
  AND ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_state, 
    cd.cd_education_status, 
    i.i_category
HAVING COALESCE(SUM(wr.wr_return_amt), 0) > 1000;

--232
SELECT 
    ca.ca_state as customer_state, 
    cd.cd_education_status as education_level, 
    i.i_category, 
    SUM(ws.ws_quantity) as total_items_sold,
    COALESCE(SUM(wr.wr_return_quantity), 0) as total_items_returned,
    ROUND((COALESCE(SUM(wr.wr_return_quantity), 0) * 100.0) / SUM(ws.ws_quantity), 2) as return_rate_pct,
    COALESCE(SUM(wr.wr_return_amt), 0) as total_money_lost
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk 
                        AND ws.ws_order_number = wr.wr_order_number
WHERE d.d_year = 2002 
  AND i.i_category IN ('Sports', 'Books', 'Music')
  AND ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_state, 
    cd.cd_education_status, 
    i.i_category
HAVING COALESCE(SUM(wr.wr_return_amt), 0) > 1000
ORDER BY total_money_lost DESC, return_rate_pct DESC
LIMIT 30;

--233
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_net_paid) as same_day_store_spend
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND EXISTS (
      SELECT 1 
      FROM web_sales ws
      WHERE ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
  )
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name
ORDER BY same_day_store_spend DESC;

--234
WITH DailyStore AS (
    SELECT 
        ss_customer_sk, 
        ss_sold_date_sk, 
        SUM(ss_net_paid) as daily_ss_spend
    FROM store_sales
    GROUP BY ss_customer_sk, ss_sold_date_sk
),
DailyWeb AS (
    SELECT 
        ws_bill_customer_sk, 
        ws_sold_date_sk, 
        SUM(ws_net_paid) as daily_ws_spend
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_sold_date_sk
)
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ds.daily_ss_spend) as store_spend_on_omni_days,
    SUM(dw.daily_ws_spend) as web_spend_on_omni_days,
    SUM(ds.daily_ss_spend + dw.daily_ws_spend) as total_omni_spend
FROM DailyStore ds
JOIN DailyWeb dw ON ds.ss_customer_sk = dw.ws_bill_customer_sk 
                AND ds.ss_sold_date_sk = dw.ws_sold_date_sk
JOIN customer c ON ds.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ds.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name
ORDER BY total_omni_spend DESC;

--235
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_net_paid) as children_spend
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001 
  AND i.i_category = 'Children'
  AND NOT EXISTS (
      SELECT 1 
      FROM store_sales ss2
      JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
      JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
      WHERE ss2.ss_customer_sk = c.c_customer_sk
        AND d2.d_year = 2001 
        AND i2.i_category = 'Toys'
  )
 and ss.ss_net_paid is not null and ss.ss_net_paid <> 0
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name
ORDER BY children_spend DESC;

--236
SELECT 
    raport.categoria_produsului, 
    raport.total_incasari 
FROM (
    SELECT 
        i.i_category as categoria_produsului, 
        SUM(ss.ss_net_paid) as total_incasari,
        1 as sort_order
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_paid IS NOT NULL AND ss.ss_net_paid <> 0
      AND i.i_category IS NOT NULL
    GROUP BY i.i_category
    
    UNION ALL
    
    SELECT 
        '=== TOTAL GENERAL ===' as categoria_produsului, 
        SUM(ss.ss_net_paid) as total_incasari,
        2 as sort_order 
    FROM store_sales ss
    WHERE ss.ss_net_paid IS NOT NULL AND ss.ss_net_paid <> 0
) raport
ORDER BY 
    raport.sort_order ASC, 
    raport.total_incasari DESC;

--237
SELECT 
    COALESCE(CAST(d.d_year AS VARCHAR), 'TOTAL GENERAL') as sales_year,
    CASE 
        WHEN d.d_year IS NULL THEN '' 
        WHEN d.d_qoy IS NULL THEN 'SUBTOTAL ANUAL' 
        ELSE CAST(d.d_qoy AS VARCHAR)
    END as sales_quarter,
    SUM(ss.ss_net_paid) as total_sales
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year IN (2000, 2001)
  AND ss.ss_net_paid IS NOT NULL 
  AND ss.ss_net_paid <> 0
GROUP BY ROLLUP (d.d_year, d.d_qoy)
ORDER BY 
    d.d_year ASC NULLS LAST, 
    d.d_qoy ASC NULLS LAST;

--238
SELECT 
    CASE 
        WHEN GROUPING(i.i_category) = 1 THEN '=== TOATE CATEGORIILE ==='
        ELSE i.i_category 
    END as product_category,
    
    CASE 
        WHEN GROUPING(cd.cd_gender) = 1 THEN '=== TOATE GENURILE ==='
        ELSE COALESCE(cd.cd_gender, 'N/A') 
    END as customer_gender,
    SUM(ss.ss_net_paid) as total_sales
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE ss.ss_net_paid IS NOT NULL 
  AND ss.ss_net_paid <> 0
GROUP BY CUBE (i.i_category, cd.cd_gender)
ORDER BY 
    GROUPING(i.i_category) ASC,
    GROUPING(cd.cd_gender) ASC,
    i.i_category ASC NULLS LAST;

--239
WITH DailyStateSales AS (
    SELECT 
        ca.ca_state as state,
        d.d_date as sales_date,
        SUM(ss.ss_net_paid) as daily_revenue
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002 
      AND d.d_moy = 12
      AND ca.ca_state IS NOT NULL
      AND ss.ss_net_paid IS NOT NULL 
      AND ss.ss_net_paid <> 0
    GROUP BY 
        ca.ca_state, 
        d.d_date
)
SELECT 
    state,
    sales_date,
    daily_revenue,
    SUM(daily_revenue) OVER (
        PARTITION BY state 
        ORDER BY sales_date ASC
    ) as running_total_revenue
FROM DailyStateSales
ORDER BY 
    state ASC, 
    sales_date ASC;

--240
WITH CustomerEducationSpend AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_education_status as education_level,
        SUM(ss.ss_net_paid) as customer_spend
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cd.cd_education_status IS NOT NULL
      AND ss.ss_net_paid IS NOT NULL 
      AND ss.ss_net_paid <> 0
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_education_status
),
RankedCustomers AS (
    SELECT 
        c_customer_id,
        c_first_name,
        c_last_name,
        education_level,
        customer_spend,
        RANK() OVER (
            PARTITION BY education_level 
            ORDER BY customer_spend DESC
        ) as rank_in_education_group
    FROM CustomerEducationSpend
)
SELECT 
    c_customer_id,
    c_first_name,
    c_last_name,
    education_level,
    customer_spend,
    rank_in_education_group
FROM RankedCustomers
WHERE rank_in_education_group <= 10
ORDER BY 
    education_level ASC, 
    rank_in_education_group ASC;

--241
WITH StoreItemSales AS (
    SELECT 
        s.s_store_name,
        i.i_item_id,
        i.i_product_name,
        SUM(ss.ss_net_paid) as total_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ss.ss_net_paid IS NOT NULL 
      AND ss.ss_net_paid <> 0
      AND s.s_store_name IS NOT NULL
    GROUP BY 
        s.s_store_name,
        i.i_item_id,
        i.i_product_name
),
RankedStoreItems AS (
    SELECT 
        s_store_name,
        i_item_id,
        i_product_name,
        total_sales,
        RANK() OVER (
            PARTITION BY s_store_name 
            ORDER BY total_sales DESC
        ) as rank_in_store
    FROM StoreItemSales
)
SELECT 
    s_store_name,
    rank_in_store,
    i_item_id,
    i_product_name,
    total_sales
FROM RankedStoreItems
WHERE rank_in_store <= 5
ORDER BY 
    s_store_name ASC, 
    rank_in_store ASC;

--242
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    d.d_moy as sales_month,
    COUNT(DISTINCT d.d_date) as unique_shopping_days,
    SUM(ss.ss_net_paid) as total_monthly_spend
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  AND ss.ss_net_paid IS NOT NULL
GROUP BY 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    d.d_moy
HAVING COUNT(DISTINCT d.d_date) >=3
ORDER BY 
    unique_shopping_days DESC,
    total_monthly_spend DESC;

--243
SELECT 
    t.t_hour as hour_of_day, 
    COUNT(ss.ss_ticket_number) as total_transactions, 
    SUM(ss.ss_net_paid) as total_hourly_revenue 
FROM store_sales ss 
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE d.d_year = 2001 
  AND t.t_hour IS NOT NULL 
  AND ss.ss_net_paid IS NOT NULL 
GROUP BY 
    t.t_hour 
ORDER BY 
    total_transactions DESC;

--244
WITH HourlyStoreSales AS (
    SELECT 
        s.s_store_name,
        t.t_hour as hour_of_day, 
        COUNT(ss.ss_ticket_number) as total_transactions, 
        SUM(ss.ss_net_paid) as total_hourly_revenue 
    FROM store_sales ss 
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk 
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001 
      AND t.t_hour IS NOT NULL 
      AND ss.ss_net_paid IS NOT NULL 
      AND s.s_store_name IS NOT NULL
    GROUP BY 
        s.s_store_name,
        t.t_hour 
    HAVING SUM(ss.ss_net_paid) > 10000
),
RankedPeakHours AS (
    SELECT 
        s_store_name,
        hour_of_day,
        total_transactions,
        total_hourly_revenue,
        RANK() OVER (
            PARTITION BY s_store_name 
            ORDER BY total_transactions DESC
        ) as rush_hour_rank
    FROM HourlyStoreSales
)
SELECT 
    s_store_name,
    rush_hour_rank,
    hour_of_day,
    total_transactions,
    total_hourly_revenue
FROM RankedPeakHours
WHERE rush_hour_rank <= 3
ORDER BY 
    s_store_name ASC, 
    rush_hour_rank ASC;

--245
SELECT 
    s.s_store_name,
    t.t_hour as hour_of_day, 
    COUNT(ss.ss_ticket_number) as total_transactions, 
    SUM(ss.ss_net_paid) as total_hourly_revenue 
FROM store_sales ss 
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE d.d_year = 2001 
  AND t.t_hour IS NOT NULL 
  AND ss.ss_net_paid IS NOT NULL 
  AND s.s_store_name IS NOT NULL
GROUP BY 
    s.s_store_name,
    t.t_hour 
HAVING 
    COUNT(ss.ss_ticket_number) >= 50
ORDER BY 
    total_hourly_revenue DESC
LIMIT 10;

--246
SELECT 
    cd.cd_gender as customer_gender, 
    COUNT(DISTINCT ss.ss_customer_sk) as unique_morning_shoppers, 
    SUM(ss.ss_net_paid) as total_morning_spend 
FROM store_sales ss 
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk 
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk 
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk 
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
WHERE d.d_year = 2002 
  AND t.t_hour BETWEEN 8 AND 11 
  AND cd.cd_gender IN ('M', 'F') 
  AND ss.ss_net_paid IS NOT NULL 
GROUP BY 
    cd.cd_gender 
ORDER BY 
    total_morning_spend DESC;

--247
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_product_name,
    SUM(ss.ss_net_paid) as amount_spent_in_store,
    SUM(ws.ws_net_paid) as amount_spent_online
FROM store_sales ss
JOIN web_sales ws ON ss.ss_customer_sk = ws.ws_bill_customer_sk 
                 AND ss.ss_item_sk = ws.ws_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE ss.ss_net_paid IS NOT NULL 
  AND ws.ws_net_paid IS NOT NULL
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    i.i_product_name
ORDER BY 
    amount_spent_online DESC, 
    amount_spent_in_store DESC;

--248
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) as total_store_spend
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
LEFT JOIN web_sales ws ON ss.ss_customer_sk = ws.ws_bill_customer_sk 
                       AND ws.ws_sold_date_sk IN (
                           SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_year = 2001
                       )
WHERE d1.d_year = 2001
  AND ss.ss_net_paid IS NOT NULL
  AND ws.ws_bill_customer_sk IS NULL 
GROUP BY 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name
ORDER BY 
    total_store_spend DESC
LIMIT 50;

--249
SELECT 
    c.c_customer_id,
    i.i_product_name,
    SUM(sr.sr_return_amt) as amount_refunded_in_store,
    SUM(ws.ws_net_paid) as amount_repaid_online
FROM store_returns sr
JOIN web_sales ws ON sr.sr_customer_sk = ws.ws_bill_customer_sk 
                 AND sr.sr_item_sk = ws.ws_item_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE ws.ws_sold_date_sk > sr.sr_returned_date_sk 
  AND sr.sr_return_amt IS NOT NULL 
  AND ws.ws_net_paid IS NOT NULL
GROUP BY 
    c.c_customer_id, 
    i.i_product_name;
--250
SELECT 
    c.c_customer_id,
    i.i_product_name,
    SUM(sr.sr_return_amt) as amount_refunded_in_store,
    SUM(ws.ws_net_paid) as amount_repaid_online
FROM store_returns sr
JOIN web_sales ws ON sr.sr_customer_sk = ws.ws_bill_customer_sk 
                 AND sr.sr_item_sk = ws.ws_item_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE ws.ws_sold_date_sk > sr.sr_returned_date_sk 
  AND sr.sr_return_amt IS NOT NULL 
  AND ws.ws_net_paid IS NOT NULL
GROUP BY 
    c.c_customer_id, 
    i.i_product_name
ORDER BY 
    amount_repaid_online DESC
LIMIT 10;