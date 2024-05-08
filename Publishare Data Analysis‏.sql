--Publishare Data Analysisþ

USE Publishare
-------------------------------
SELECT * FROM article_types
SELECT * FROM articles
SELECT * FROM authors
SELECT * FROM traffic
SELECT * FROM products
SELECT * FROM categories
-------------------------------

-------------------------------
--In the following queries we will perform a basic recognition of
--the tables to understand what is behind each table

--01
SELECT A.author, AR.title 
FROM authors A
JOIN articles AR
	ON A.author_id = AR.author_id

--02
SELECT A.title, T.traffic_day, T.article_views
FROM articles A
JOIN traffic T
	ON A.article_id = T.article_id 
ORDER BY 3 DESC

--03
SELECT P.product_name, C.category_name  
FROM products P
JOIN categories C
	ON P.category_id = C.category_id

--04
SELECT A.title, T.traffic_day, T.article_views, P.product_name, T.product_views 
FROM articles A
JOIN traffic T 
	ON A.article_id = T.article_id
JOIN products P
	ON T.product_id = P.product_id 
-------------------------------

-------------------------------
--In the following queries, we will build reports for the business departments, 
--we will examine the performance of articles and publications,
--cumulative views in different sections in order to get an overview of the performance.

--05
SELECT A.title, SUM(T.article_views) AS 'total_article_views', SUM(T.product_views) AS 'total_product_views'
FROM articles A
JOIN traffic T 
	ON A.article_id = T.article_id
GROUP BY A.title

--06
SELECT P.product_name, T.article_id, SUM(T.product_views) AS 'total_product_views'
FROM products P
JOIN traffic T 
	ON P.product_id = T.product_id 
GROUP BY P.product_name, T.article_id
ORDER BY 1

--07
SELECT A.title, T.traffic_day, SUM(T.article_views) OVER( PARTITION BY A.title ORDER BY T.traffic_day) AS'acc_article_views'
FROM traffic T
JOIN articles A
	ON T.article_id = A.article_id

--08
SELECT A.author, COUNT(DISTINCT ART.article_id) AS 'num_of_articles', SUM(t.article_views) AS 'total_article_views'
FROM authors A
JOIN articles ART
	ON A.author_id = ART.author_id
JOIN traffic T
	ON ART.article_id =T.article_id
GROUP BY A.author
ORDER BY num_of_articles DESC 

--09
SELECT A.author, T.traffic_day, SUM(T.article_views) AS 'total_articles_views',  SUM(CASE WHEN C.category_name = 'Energy' THEN T.article_views END) AS 'Energy_views',
																				 SUM(CASE WHEN C.category_name = 'Technology' THEN T.article_views END) AS 'Technology_views',
																				 SUM(CASE WHEN C.category_name = 'Finance' THEN T.article_views ELSE 0 END) AS 'Finance_views',
																				 SUM(CASE WHEN C.category_name = 'Transportation' THEN T.article_views END) AS 'Transportation_views'
FROM authors A
JOIN articles ART
	ON A.author_id = ART.author_id
JOIN traffic T 
	ON ART.article_id = T.article_id
JOIN products P
	ON T.product_id = P.product_id
JOIN categories C
	ON P.category_id = C.category_id
GROUP BY A.author, T.traffic_day
ORDER BY A.author, T.traffic_day

--10- ONE WAY
;WITH views_cte AS
		(
		SELECT C.category_name, P.product_name, T.product_views, SUM(T.product_views) OVER ( PARTITION BY C.category_name ) AS 'category_views'
		FROM traffic T
		JOIN products P
			ON T.product_id = P.product_id
		JOIN categories C
			ON P.category_id = C.category_id
		)
SELECT category_name, product_name, SUM(product_views) AS 'product_views', category_views,
	   FORMAT(SUM(product_views)*1.0/category_views,'P') AS 'views_pct'
FROM views_cte
GROUP BY category_name, product_name,category_views
ORDER BY 1,2 

--10 Another way
SELECT C.category_name, P.product_name, SUM(T.product_views) AS 'product_views', SUM(SUM(T.product_views)) OVER ( PARTITION BY C.category_name ) AS 'category_views'
FROM traffic T
JOIN products P
	ON T.product_id = P.product_id
JOIN categories C
	ON P.category_id = C.category_id
GROUP BY C.category_name, P.product_name
ORDER BY 1,2

--11
SELECT DATENAME(MONTH, traffic_day) AS 'traffic_month', DATENAME(WEEKDAY, traffic_day) AS 'traffic_day',
	   SUM(article_views) AS 'daily_article_views', SUM(SUM(article_views)) OVER (PARTITION BY DATENAME(MONTH, traffic_day)) AS 'daily_article_views',
	   FORMAT(SUM(article_views)*1.0/SUM(SUM(article_views)) OVER (PARTITION BY DATENAME(MONTH, traffic_day)),'P') AS 'views_pct'  
FROM traffic
GROUP BY DATENAME(MONTH, traffic_day), DATENAME(WEEKDAY, traffic_day), DATEPART(DW, traffic_day)
ORDER BY DATEPART(DW, traffic_day)


--12
SELECT T.traffic_day, A.title, SUM(T.article_views) AS 'total_article_views', SUM(SUM(t.article_views)) OVER( PARTITION BY T.traffic_day) AS 'total_daily_article_views',
	   FORMAT(SUM(T.article_views)*1.0/SUM(SUM(t.article_views)) OVER( PARTITION BY T.traffic_day),'P') AS 'pct'
FROM articles A
JOIN traffic T
	ON A.article_id = T.article_id
GROUP BY T.traffic_day, A.title 

--13
SELECT A.title, SUM(T.article_views) AS 'total_views', DENSE_RANK() OVER(ORDER BY SUM(T.article_views) DESC) AS 'views_rank'
FROM traffic T
JOIN articles A
	ON T.article_id = A.article_id 
WHERE A.publication_date BETWEEN '2020-12-01' AND '2020-12-07'
GROUP BY A.title

--14
SELECT C.category_name, P.product_name, SUM(T.product_views)  AS 'total_views', 
	   DENSE_RANK() OVER( PARTITION BY C.category_name ORDER BY SUM(T.product_views) DESC) AS 'views_rank'
FROM traffic T
JOIN products P
	ON T.product_id = P.product_id
JOIN categories C
	ON P.category_id = C.category_id
GROUP BY  C.category_name, P.product_name

--15
SELECT A.title, T.traffic_day, T.article_views, LAG(T.article_views) OVER(PARTITION BY A.title ORDER BY T.traffic_day ) AS 'prev_day',
	   FORMAT((T.article_views*1.0/LAG(T.article_views) OVER(PARTITION BY A.title ORDER BY T.traffic_day ))-1,'P') AS 'pct_diff'
FROM traffic T
JOIN articles A
	ON T.article_id = A.article_id 

--16
;WITH day_cte AS
		(
		SELECT A.title, T.article_views, T.traffic_day, SUM(T.article_views) OVER (PARTITION BY A.title ORDER BY T.traffic_day ) AS 'AccumulatedViews',
		COUNT(*) OVER(PARTITION BY A.title ORDER BY T.traffic_day ) AS 'num_of_days'
		FROM articles A
		JOIN traffic T
			ON A.article_id = T.article_id
		)
SELECT title,
	   MIN(num_of_days) AS 'days_to_reach_25k_views',
	   DENSE_RANK() OVER( ORDER BY MIN(num_of_days)) AS 'd_rank'
FROM day_cte
WHERE AccumulatedViews >= 25000 
GROUP BY title

--17
SELECT A.article_id, T.article_views, T.product_views,
	   FORMAT(T.product_views*1.0/T.article_views, 'P') AS 'redirecr_ratio',
	   FORMAT(AVG(T.product_views*1.0/T.article_views) OVER (), 'P') AS 'avg_redirecr_ratio'
FROM articles A
JOIN traffic T
	ON A.article_id = T.article_id
ORDER BY 1,2 

--18
SELECT C.category_name, AVG(T.product_views*1.0/T.article_views)
FROM traffic T
JOIN products P
	ON T.product_id = P.product_id
JOIN categories C
	ON P.category_id = C.category_id
GROUP BY C.category_name

--19
SELECT YEAR(A.publication_date) 'publication_year', DATENAME(MONTH,A.publication_date) AS 'publication_month', 
	   DATEPART(WEEK,A.publication_date) AS 'publication_month',
	   COUNT(*) AS 'total_articles',
	   COUNT(CASE WHEN T.art_type_desc = 'Clinical Case Studies' THEN 1 ELSE NULL END) AS 'Clinical Case Studies',
	   COUNT(CASE WHEN T.art_type_desc = 'Opinion' THEN 1 ELSE NULL END) AS 'Opinion',
	   COUNT(CASE WHEN T.art_type_desc = 'Feature Writing' THEN 1 ELSE NULL END) AS 'Feature Writing',
	   COUNT(CASE WHEN T.art_type_desc = 'Investigative' THEN 1 ELSE NULL END) AS 'Investigative',
	   COUNT(CASE WHEN T.art_type_desc = 'News' THEN 1 ELSE NULL END) AS 'News'
FROM articles A
JOIN article_types T
	ON A.article_type_id = T.art_type_id
GROUP BY YEAR(A.publication_date), DATENAME(MONTH,A.publication_date),  DATEPART(WEEK,A.publication_date)

--20
;WITH top_bottom_rank AS 
	(SELECT prd.product_name, SUM(trf.product_views) AS 'SumProductViews', 
		   DENSE_RANK() OVER (ORDER BY SUM(trf.product_views) DESC) 'TopRank',
		   DENSE_RANK() OVER (ORDER BY SUM(trf.product_views)) 'BottomRank'
	FROM traffic trf JOIN products prd 
	ON   trf.product_id = prd.product_id
	GROUP BY prd.product_name)
SELECT product_name, SumProductViews, 
       CASE WHEN topRank = 1 THEN 'Top' ELSE 'Bottom' END AS 'Top/Bottom'
FROM top_bottom_rank
WHERE TopRank = 1  
OR    BottomRank = 1 
ORDER BY SumProductViews DESC 

-------------------------------