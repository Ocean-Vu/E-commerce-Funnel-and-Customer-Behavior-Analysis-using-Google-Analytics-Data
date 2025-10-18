UniGap - SQL Project 1 - Ecommerce Project Instruction

--- Query 01: calculate total visit, pageview, transaction for Jan, Feb and March 2017 (order by month)totals


SELECT
 FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
 COUNT(DISTINCT(visitId)) AS visits,
 SUM(totals.pageviews) AS pageviews,
 SUM(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
GROUP BY month
ORDER BY month;

-- correct

-- Query 02: Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)

SELECT
 trafficSource.`source` AS source,
 SUM(totals.bounces) AS bounce_number,
 COUNT(visitId) AS visit_total,
 ROUND(SUM(totals.bounces)*100/COUNT(visitId),3) AS Bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
GROUP BY trafficSource.`source`
ORDER BY visit_total DESC;


--- Query 03: Revenue by traffic source by week, by month in June 2017 (source/ type_time/ rev')

-- correct


WITH
Month_rev AS (
  SELECT
    'Month' AS type_time,
    FORMAT_DATE('%Y%m',PARSE_DATE('%Y%m%d',a.date)) AS time,
    a.trafficSource.`source` AS source,
    ROUND((SUM(product.productRevenue)/1000000),3) AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*` AS a,
    UNNEST (a.hits) AS hits,
    UNNEST (hits.product) AS product
  WHERE product.productRevenue IS NOT NULL
  GROUP BY type_time, time, source),


Week_rev AS (
  SELECT
    'Week' AS type_time,
    FORMAT_DATE('%Y%V',PARSE_DATE('%Y%m%d',a.date)) AS time,
    a.trafficSource.`source` AS source,
    ROUND((SUM(product.productRevenue)/1000000.0),3) AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*` AS a,
    UNNEST (a.hits) AS hits,
    UNNEST (hits.product) AS product
  WHERE product.productRevenue IS NOT NULL
  GROUP BY type_time, time, source)


SELECT *
FROM Month_rev
UNION ALL
SELECT *
FROM Week_rev
ORDER BY type_time, time, source,revenue DESC;


=> NẾU Ở CTE của week dùng WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331' lại ko ra kêts quả => chưa hiểu trình tự logic ?
-- where đi ngay sau from, mình lấy 201706*, nghĩa là lấy bảng chưa dữ liệu tháng 6
-- nếu filter tháng 3 thì sao có data đc



--- Query 04: Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017.  Hint 1: purchaser: totals.transactions >=1; productRevenue is not null. Hint 3: Avg pageview = total pageview / number unique user.

WITH
Purchase_table AS(
 SELECT
   FORMAT_DATE('%Y%m',PARSE_DATE('%Y%m%d',a.date)) AS time,
   ROUND(SUM(a.totals.pageviews)/COUNT(DISTINCT(a.visitorId)),3) AS avg_pageviews
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` a,
 UNNEST (a.hits) hits,
 UNNEST (hits.product) product
 WHERE a.totals.transactions >=1
 AND product.productRevenue IS NOT NULL
 AND _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'),


Non_Purchase_table AS(
 SELECT
   FORMAT_DATE('%Y%m',PARSE_DATE('%Y%m%d',a.date)) AS time,
   ROUND(SUM(a.totals.pageviews)/COUNT(DISTINCT(a.visitorId)),3) avg_pageviews
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` a,
 UNNEST (a.hits) hits,
 UNNEST (hits.product) product
 WHERE a.totals.transactions =0
 OR product.productRevenue IS NULL
 AND _TABLE_SUFFIX BETWEEN '20170601' AND '20170731')


SELECT *
FROM Purchase_table
UNION ALL
SELECT *
FROM Non_Purchase_table
GROUP BY time
ORDER BY time;

=> Không ra kết quả
-- filter sai date, T đã hướng dẫn trong buổi project support rồi
-- mình ghi _TABLE_SUFFIX BETWEEN '20170601' AND '20170731' thì máy sẽ tìm bảng 201720170601
-- mà rõ ràng là k có ngày nào như vậy
with 
purchaser_data as(
  select
      format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
      (sum(totals.pageviews)/count(distinct fullvisitorid)) as avg_pageviews_purchase,
  from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    ,unnest(hits) hits
    ,unnest(product) product
  where _table_suffix between '0601' and '0731'
  and totals.transactions>=1
  and product.productRevenue is not null
  group by month
),

non_purchaser_data as(
  select
      format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
      sum(totals.pageviews)/count(distinct fullvisitorid) as avg_pageviews_non_purchase,
  from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
      ,unnest(hits) hits
    ,unnest(product) product
  where _table_suffix between '0601' and '0731'
  and totals.transactions is null
  and product.productRevenue is null
  group by month
)

select
    pd.*,
    avg_pageviews_non_purchase
from purchaser_data pd
full join non_purchaser_data using(month)
order by pd.month;

-- câu 4 này lưu ý là mình nên dùng full join/left join, bởi vì trong câu này, phạm vi chỉ từ tháng 6-7, nên chắc chắc sẽ có pur và nonpur của cả 2 tháng
-- mình inner join thì vô tình nó sẽ ra đúng. nhưng nếu đề bài là 1 khoảng thời gian dài hơn, 2-3 năm chẳng hạn, thì có tháng chỉ có nonpur mà k có pur
-- thì khi đó inner join nó sẽ làm mình bị mất data, thay vì hiện số của nonpur và pur thì nó để trống



---Query 05: Average number of transactions per user that made a purchase in July 2017 

SELECT
  FORMAT_DATE('%Y%m',PARSE_DATE('%Y%m%d',a.date)) AS time,
  ROUND(SUM(a.totals.transactions)/COUNT(DISTINCT(a.fullVisitorId)),9) AS avg_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` a,
UNNEST (a.hits) AS hits,
UNNEST (hits.product) AS product
WHERE totals.transactions >=1
 AND product.productRevenue IS NOT NULL
GROUP BY time;

-- correct


---Query 06: Average amount of money spent per session. Only include purchaser data in July 2017

SELECT
 FORMAT_DATE('%Y%m',PARSE_DATE('%Y%m%d',a.date)) AS time,
 ROUND(SUM(product.productRevenue)/1000000/SUM(a.totals.visits),3) AS avg_amount_money_per_session
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` a,
UNNEST (a.hits) AS hits,
UNNEST (hits.product) AS product
WHERE totals.transactions IS NOT NULL
AND product.productRevenue IS NOT NULL
GROUP BY time;

-- correct

--- Query 07: Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.

WITH
customers_purchased_target_product AS (
SELECT
  DISTINCT fullVisitorId
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` a,
  UNNEST (a.hits) AS hits,
  UNNEST (hits.product) AS product
WHERE
  a.totals.transactions >= 1
  AND product.productRevenue IS NOT NULL
  AND product.v2ProductName = "YouTube Men's Vintage Henley")


SELECT
product.v2ProductName AS other_purchased_products,
SUM(product.productQuantity) AS quantity_ordered
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` AS a,
UNNEST (a.hits) AS hits,
UNNEST (hits.product) AS product
LEFT JOIN customers_purchased_target_product AS b
ON b.fullVisitorId=a.fullVisitorId
WHERE
  a.totals.transactions >= 1
  AND product.productRevenue IS NOT NULL
  AND product.v2ProductName != "YouTube Men's Vintage Henley"
GROUP BY other_purchased_products
ORDER BY quantity_ordered DESC;

-- câu query trên viết dính nhau quá
-- subquery:
select
    product.v2productname as other_purchased_product,
    sum(product.productQuantity) as quantity
from `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    unnest(hits) as hits,
    unnest(hits.product) as product
where fullvisitorid in (select distinct fullvisitorid
                        from `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
                        unnest(hits) as hits,
                        unnest(hits.product) as product
                        where product.v2productname = "YouTube Men's Vintage Henley"
                        and product.productRevenue is not null
                        AND totals.transactions>=1)
  and product.v2productname != "YouTube Men's Vintage Henley"
  and product.productRevenue is not null
  AND totals.transactions>=1
group by other_purchased_product
order by quantity desc;

-- CTE:
-- ở bảng buyer_list này, mình chỉ muốn tìm ra danh sách nhưng ng mua, thì nó người ngta sẽ mua nhiều lần chẳng hặn
-- khi mình select distinct fullVisitorId, nó sẽ 3 người, nhưng nếu mình select fullVisitorId
-- nó ra 6 dòng, tường ứng với 6 record trong bảng, rồi nó mang 6 dòng này, đi mapping tiếp với câu dưới, nên nó bị dup lên

with buyer_list as(
    SELECT
        distinct fullVisitorId  
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    , UNNEST(hits) AS hits
    , UNNEST(hits.product) as product
    WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
    AND totals.transactions>=1
    AND product.productRevenue is not null
)

SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
, UNNEST(hits) AS hits
, UNNEST(hits.product) as product
JOIN buyer_list using(fullVisitorId)
WHERE product.v2ProductName != "YouTube Men's Vintage Henley"
 and product.productRevenue is not null
 AND totals.transactions>=1
GROUP BY other_purchased_products
ORDER BY quantity DESC;



--- "Query 08: Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. The output should be calculated in product level."



WITH product_action AS(
SELECT
FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', a.date)) AS month,
product.v2ProductName AS product_name,
SUM(CASE WHEN hits.eCommerceAction.action_type = '2' THEN 1 ELSE 0 END) AS total_product_views,
SUM(CASE WHEN hits.eCommerceAction.action_type = '3' THEN 1 ELSE 0 END) AS total_add_to_carts,
SUM(CASE WHEN hits.eCommerceAction.action_type = '6' AND product.productRevenue IS NOT NULL THEN 1 ELSE 0 END) AS total_purchases
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` a,
UNNEST (a.hits) AS hits,
UNNEST (hits.product) AS product
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
GROUP BY month, product_name)


SELECT
b.month,
b.product_name,
b.total_product_views,
b.total_add_to_carts,
b.total_purchases,
ROUND(b.total_add_to_carts/b.total_product_views,2) AS add_to_carts_rate,
ROUND(b.total_purchases/b.total_product_views,2) AS purchases_rate
FROM product_action AS b
ORDER BY b.month, b.product_name;

/*
Với mỗi sản phẩm, nó sẽ trải qua 3 stage, view -> add to cart -> purchase
thì để bài đang yêu cầu mình tính theo kiểu cohort map, qua từng stage như vậy, số sản phầm rớt dần còn bao nhiêu %
ví dụ có mình xem 10 sản phẩm, xong bỏ 4 sản phẩm vào giỏ hàng, rồi quyết định chỉ mua 1 cái thôi
*/

-- bài yêu cầu tính số sản phầm, mình nên count productName hay productSKU thì sẽ hợp lý hơn là count action_type
-- k nên xài inner join, nếu table1 có 10 record,table2 có 5 record,table3 có 1 record, thì sau khi inner join, output chỉ ra 1 record

-- Cách 1:dùng CTE  
with
product_view as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_product_view
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '2'
  GROUP BY 1
),

add_to_cart as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_addtocart
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '3'
  GROUP BY 1
),

purchase as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '6'
  and product.productRevenue is not null   --phải thêm điều kiện này để đảm bảo có revenue
  group by 1
)

select
    pv.*,
    num_addtocart,
    num_purchase,
    round(num_addtocart*100/num_product_view,2) as add_to_cart_rate,
    round(num_purchase*100/num_product_view,2) as purchase_rate
from product_view pv
left join add_to_cart a on pv.month = a.month
left join purchase p on pv.month = p.month
order by pv.month;

-- bài này k nên inner join, vì nếu như bảng purchase k có data thì sẽ k mapping đc vs bảng productview, từ đó kết quả sẽ k có luôn, mình nên dùng left join
-- lấy số product_view làm gốc, nên mình sẽ left join ra 2 bảng còn lại

-- Cách 2: bài này mình có thể dùng count(case when) hoặc sum(case when)

with product_data as(
select
    format_date('%Y%m', parse_date('%Y%m%d',date)) as month,
    count(CASE WHEN eCommerceAction.action_type = '2' THEN product.v2ProductName END) as num_product_view,
    count(CASE WHEN eCommerceAction.action_type = '3' THEN product.v2ProductName END) as num_add_to_cart,
    count(CASE WHEN eCommerceAction.action_type = '6' and product.productRevenue is not null THEN product.v2ProductName END) as num_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
,UNNEST(hits) as hits
,UNNEST (hits.product) as product
where _table_suffix between '20170101' and '20170331'
and eCommerceAction.action_type in ('2','3','6')
group by month
order by month
)

select
    *,
    round(num_add_to_cart/num_product_view * 100, 2) as add_to_cart_rate,
    round(num_purchase/num_product_view * 100, 2) as purchase_rate
from product_data;












