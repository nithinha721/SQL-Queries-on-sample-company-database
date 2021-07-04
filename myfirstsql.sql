USE mavenfuzzyfactory;

SELECT w.website_session_id,o.order_id 
FROM website_sessions w LEFT JOIN orders o ON w.website_session_id=o.website_session_id
WHERE w.created_at<'2012-04-14' AND w.utm_source='gsearch' AND w.utm_campaign='nonbrand';

SELECT DISTINCT(w.device_type),
COUNT(DISTINCT(w.website_session_id)),
COUNT(DISTINCT(o.order_id)),
COUNT(DISTINCT(o.order_id))/COUNT(DISTINCT(w.website_session_id)) AS SESSION_STR_RATIO
FROM website_sessions w LEFT JOIN orders o ON w.website_session_id=o.website_session_id
WHERE w.created_at<'2012-05-11' AND w.utm_source='gsearch' AND w.utm_campaign='nonbrand' GROUP BY 1;

SELECT 
	primary_product_id,
    COUNT(DISTINCT CASE WHEN items_purchased = 1 THEN order_id ELSE NULL END) AS count_single_items,
    COUNT(DISTINCT CASE WHEN items_purchased = 2 THEN order_id ELSE NULL END) AS count_double_items
FROM orders
WHERE order_id BETWEEN 31000 AND 32000
GROUP BY 1;

SELECT MIN(DATE(created_at)),
	   COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END),
       COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END)
FROM website_sessions
WHERE website_sessions.created_at<'2012-06-09' 
AND website_sessions.created_at>'2012-04-15' 
AND utm_source='gsearch'
AND utm_campaign='nonbrand'
GROUP BY YEAR(created_at),WEEK(created_at);

SELECT pageview_url,COUNT(DISTINCT(website_session_id)) AS SESSIONS
FROM website_pageviews
WHERE created_at<'2012-06-09' GROUP BY 1 ORDER BY 2 DESC;

DROP TABLE first_view;
CREATE TEMPORARY TABLE first_view
SELECT website_session_id,MIN(website_pageview_id) AS page
FROM website_pageviews
WHERE created_at<'2012-06-12'GROUP BY 1;

SELECT * FROM first_view;

SELECT COUNT(DISTINCT(f.website_session_id)),w.pageview_url AS Landing_page
FROM first_view f LEFT JOIN website_pageviews w ON f.page=w.website_pageview_id GROUP BY 2;

/*To find bounce sessions*/

CREATE TEMPORARY TABLE first_pageviews_demo
SELECT website_session_id,MIN(website_pageview_id) as min_pageview_id
FROM website_pageviews 
WHERE created_at BETWEEN '2014-01-01' AND '2014-02-01' GROUP BY 1;

SELECT * FROM first_pageviews_demo;

DROP TABLE sessions_w_landing_page_demo;
CREATE TEMPORARY TABLE sessions_w_landing_page_demo
SELECT f.website_session_id,w.pageview_url AS Landing_page 
FROM first_pageviews_demo f LEFT JOIN website_pageviews w 
ON f.min_pageview_id=w.website_pageview_id 
GROUP BY 1,2; 

SELECT * FROM sessions_w_landing_page_demo;

DROP TABLE bounced_session_only;
CREATE TEMPORARY TABLE bounced_session_only
SELECT s.website_session_id,s.Landing_page,COUNT(w.website_pageview_id) AS count_of_page_viewed
FROM sessions_w_landing_page_demo s LEFT JOIN website_pageviews w ON s.website_session_id=w.website_session_id
GROUP BY 1
HAVING count_of_page_viewed = 1;

SELECT * FROM bounced_session_only;

SELECT s.Landing_page,COUNT(DISTINCT(s.website_session_id)) AS sessions,
COUNT(DISTINCT(b.website_session_id)) AS bounced_sessions,
COUNT(DISTINCT(b.website_session_id))/COUNT(DISTINCT(s.website_session_id)) AS bounce_rate
FROM sessions_w_landing_page_demo s LEFT JOIN bounced_session_only b ON s.website_session_id=b.website_session_id 
GROUP BY 1;

SELECT s.Landing_page,f.created_at,COUNT(DISTINCT(s.website_session_id)) AS sessions,COUNT(DISTINCT(b.website_session_id)) AS bounce_sessions,
COUNT(DISTINCT(b.website_session_id))/COUNT(DISTINCT(s.website_session_id)) AS bounce_rates
FROM sessions_w_landing_page_demo s LEFT JOIN bounced_session_only b ON s.website_session_id=b.website_session_id 
LEFT JOIN first_pageviews_demo f ON f.website_session_id=b.website_session_id
AND f.created_at<'2012-06-14'
AND s.Landing_page='/home';