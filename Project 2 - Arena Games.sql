--Project 2 - Arena Games


--Payments Analysis

--01
;WITH card_type_cte AS
		(
		SELECT P.player_id, P.email_address,	
			  ROW_NUMBER() OVER(PARTITION BY P.player_id ORDER BY 
													  CASE WHEN PM.credit_card_type = 'americanexpress' THEN 1
															WHEN PM.credit_card_type = 'mastercard' THEN 2
															WHEN PM.credit_card_type = 'visa' THEN 3
														END) AS 'card_num',
				PM.credit_card_type,
				PM.credit_card_number
		FROM players P
		LEFT JOIN paying_method PM
			ON P.player_id = PM.player_id
		)
SELECT player_id, email_address, credit_card_type, credit_card_number
FROM card_type_cte
WHERE card_num = 1

--02
-------------------------------------------------------
SELECT P.gender, P.age_group,PM.credit_card_number
FROM players P
JOIN paying_method PM
	ON P.player_id = PM.player_id
--------------------------------------------------------

SELECT *
FROM(SELECT P.gender AS 'gender', P.age_group AS 'age_group', PM.credit_card_type AS 'type_card'
	FROM players P
	JOIN paying_method PM
		ON P.player_id = PM.player_id) AS TBL
PIVOT (COUNT(type_card) FOR type_card  IN ([americanexpress],[mastercard],[visa]) ) AS PVT
ORDER BY 1

--Game Sessions Analysis 
--03
SELECT G.game_name, COUNT(*) AS 'game_sessions', 
	   DENSE_RANK() OVER (ORDER BY COUNT(*) DESC ) AS 'd_rank'
FROM games G
JOIN game_sessions S
	ON G.id = S.game_id
GROUP BY G.game_name

--04
SELECT G.game_name, SUM(DATEDIFF(MINUTE,S.session_begin_date, S.session_end_date)) AS 'total_playing_min', 
	   DENSE_RANK() OVER (ORDER BY SUM(DATEDIFF(MINUTE,S.session_begin_date, S.session_end_date)) DESC) AS 'd_rank'
FROM games G
JOIN game_sessions S
	ON G.id = S.game_id
GROUP BY G.game_name

--05
;WITH total_play_cte AS
		(
		SELECT P.age_group ,G.game_name, SUM(DATEDIFF(MINUTE,S.session_begin_date, S.session_end_date)) AS 'total_playing_min', 
			   DENSE_RANK() OVER (PARTITION BY P.age_group ORDER BY SUM(DATEDIFF(MINUTE,S.session_begin_date, S.session_end_date)) DESC) AS 'd_rank'
		FROM games G
		JOIN game_sessions S
			ON G.id = S.game_id
		JOIN players P
			ON P.player_id = S.player_id
		GROUP BY P.age_group, G.game_name
		)
SELECT *
FROM total_play_cte
WHERE d_rank = 1

--06
SELECT session_id, action_id, action_type, CASE WHEN action_type = 'loss' THEN amount * -1
												WHEN action_type = 'gain' THEN amount * 1
										   END AS 'amount',
	 SUM(CASE WHEN action_type = 'loss' THEN amount * -1
												WHEN action_type = 'gain' THEN amount * 1
										   END) OVER(PARTITION BY session_id ORDER BY action_id ) AS 'balance'
FROM session_details

--07-one way 
;WITH balance_cte AS
		(
		SELECT session_id,
			 SUM(CASE WHEN action_type = 'loss' THEN amount * -1
					  WHEN action_type = 'gain' THEN amount * 1
				 END) OVER(PARTITION BY session_id ) AS 'balance'
		FROM session_details
		
		),
     new_cte AS
			(
			SELECT session_id, MAX(balance) AS 'new_balance'
			FROM balance_cte
			GROUP BY session_id
			)
SELECT COUNT (CASE WHEN new_balance > 0 THEN 1 END) AS 'total_gain',
	   COUNT(CASE WHEN new_balance < 0 THEN 1 END) AS 'total_loss',
	   COUNT(CASE WHEN new_balance = 0 THEN 1 END) AS 'total_draws'
FROM new_cte 

--7-second way 
;WITH balance_cte AS 
	(
	SELECT session_id, action_id,
		   SUM(CASE WHEN action_type = 'loss' THEN amount * -1 ELSE amount END)
		   OVER (PARTITION BY session_id ORDER BY action_id) AS 'balance',
		   ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY action_id DESC) AS 'rn_action'
	FROM session_details 
	)
SELECT COUNT(CASE WHEN balance < 0 THEN 1 END)  AS 'total_losses', 
       COUNT(CASE WHEN balance > 0 THEN 1 END) AS 'total_gains',
       COUNT(CASE WHEN balance = 0 THEN 1 END) AS 'total_draws'
FROM balance_cte
WHERE rn_action = 1

--08
;WITH balance_cte AS 
	(
	SELECT session_id, action_id,
		   SUM(CASE WHEN action_type = 'loss' THEN amount * -1 ELSE amount END)
		   OVER (PARTITION BY session_id ORDER BY action_id) AS 'balance',
		   ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY action_id DESC) AS 'rn_action'
	FROM session_details 
	)
SELECT P.gender, P.age_group,
	   COUNT(CASE WHEN C.balance < 0 THEN 1 END)  AS 'total_losses', 
       COUNT(CASE WHEN C.balance > 0 THEN 1 END) AS 'total_gains',
       COUNT(CASE WHEN C.balance = 0 THEN 1 END) AS 'total_draws'
	   
FROM balance_cte C
JOIN game_sessions GS
	ON C.session_id = GS.session_id
JOIN players P
	ON GS.player_id = P.player_id
WHERE rn_action = 1
GROUP BY P.gender, P.age_group
ORDER BY P.gender, P.age_group

--09-one way 
;WITH balance_cte AS 
	(
	SELECT session_id, action_id,
		   SUM(CASE WHEN action_type = 'loss' THEN amount * -1 ELSE amount END)
		   OVER (PARTITION BY session_id ORDER BY action_id) AS 'balance',
		   ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY action_id DESC) AS 'rn_action'
	FROM session_details 
	)
SELECT P.player_id, SUM(balance) AS 'total_gain_loss'
FROM balance_cte C
JOIN game_sessions GS
	ON C.session_id = GS.session_id
JOIN players P
	ON GS.player_id = P.player_id
WHERE rn_action = 1
GROUP BY P.player_id
ORDER BY 1

--9-second way 
SELECT  player_id ,
		SUM(CASE WHEN action_type = 'loss' THEN amount * -1 ELSE amount END) AS 'aum_amount'
FROM 	[dbo].[session_details] S
JOIN  [dbo].[game_sessions]  G
ON S.session_id = G.session_id
GROUP BY player_id
ORDER BY player_id 

--10
;WITH balance_cte AS 
	(
	SELECT session_id, action_id,
		   SUM(CASE WHEN action_type = 'loss' THEN amount * -1 ELSE amount END)
		   OVER (PARTITION BY session_id ORDER BY action_id) AS 'balance',
		   ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY action_id DESC) AS 'rn_action'
	FROM session_details 
	)
SELECT SUM(CASE WHEN balance < 0 THEN balance END) * -1 AS 'house_gains', 
       SUM(CASE WHEN balance > 0 THEN balance END) * -1 AS 'house_losses',
	   (SUM(CASE WHEN balance < 0 THEN balance END) * -1) - SUM(CASE WHEN balance > 0 THEN balance END) AS 'overall_gain_loss'
FROM balance_cte
WHERE rn_action = 1

--Revenue Trend Analysis
--11
;WITH balance_cte AS 
	(
	SELECT session_id, action_id,
		   SUM(CASE WHEN action_type = 'loss' THEN amount * -1 ELSE amount END)
		   OVER (PARTITION BY session_id ORDER BY action_id) AS 'balance',
		   ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY action_id DESC) AS 'rn_action'
	FROM session_details 
	)
SELECT YEAR(G.session_end_date) AS 'year', DATEPART(Q, G.session_end_date) AS 'quarter',
	   SUM(CASE WHEN balance < 0 THEN balance END) * -1 AS 'house_gains', 
       SUM(CASE WHEN balance > 0 THEN balance END) * -1 AS 'house_losses',
	   (SUM(CASE WHEN balance < 0 THEN balance END) * -1) - SUM(CASE WHEN balance > 0 THEN balance END) AS 'overall_gain_loss'
FROM balance_cte C
JOIN game_sessions G
	ON C.session_id = G.session_id 
WHERE rn_action = 1
GROUP BY  YEAR(G.session_end_date), DATEPART(Q, G.session_end_date)
ORDER BY 1, 2

--12
;WITH balance_cte AS 
	(
	SELECT session_id, action_id,
		   SUM(CASE WHEN action_type = 'loss' THEN amount * -1 ELSE amount END)
		   OVER (PARTITION BY session_id ORDER BY action_id) AS 'balance',
		   ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY action_id DESC) AS 'rn_action'
	FROM session_details 
	)
SELECT YEAR(G.session_end_date) AS 'year', MONTH(G.session_end_date) AS 'month',
	   SUM(CASE WHEN balance < 0 THEN balance END) * -1 AS 'house_gains', 
       SUM(CASE WHEN balance > 0 THEN balance END) * -1 AS 'house_losses',
	   (SUM(CASE WHEN balance < 0 THEN balance END) * -1) - SUM(CASE WHEN balance > 0 THEN balance END) AS 'overall_gain_loss'
FROM balance_cte C
JOIN game_sessions G
	ON C.session_id = G.session_id 
WHERE rn_action = 1
GROUP BY  YEAR(G.session_end_date), MONTH(G.session_end_date)
ORDER BY 5 DESC 

-- 12
;WITH balance_cte AS 
	(
	SELECT session_id, action_id,
		   SUM(CASE WHEN action_type = 'loss' THEN amount * -1 ELSE amount END)
		   OVER (PARTITION BY session_id ORDER BY action_id) AS 'balance',
		   ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY action_id DESC) AS 'rn_action'
	FROM session_details 
	), rank_profit_loss AS
	(SELECT YEAR(gs.session_begin_date) AS 'year', DATEPART(MONTH, gs.session_begin_date) AS 'month',
		   SUM(CASE WHEN balance < 0 THEN balance END) * -1 AS 'house_gains', 
		   SUM(CASE WHEN balance > 0 THEN balance END)* -1 AS 'house_losses', 
		   (SUM(CASE WHEN balance < 0 THEN balance END) * -1) - SUM(CASE WHEN balance > 0 THEN balance END) AS 'overall',
		   DENSE_RANK() OVER (ORDER BY (SUM(CASE WHEN balance < 0 THEN balance END) * -1) - SUM(CASE WHEN balance > 0 THEN balance END) DESC) AS 'profit_rank',
		   DENSE_RANK() OVER (ORDER BY (SUM(CASE WHEN balance < 0 THEN balance END) * -1) - SUM(CASE WHEN balance > 0 THEN balance END)) AS 'loss_rank'
	FROM balance_cte ra JOIN game_sessions gs 
	ON   ra.session_id = gs.session_id 
	WHERE rn_action = 1
	GROUP BY YEAR(gs.session_begin_date), DATEPART(MONTH, gs.session_begin_date)
	)
SELECT *,
       CASE WHEN overall < 0 THEN CONCAT('Loss Top-',loss_rank) ELSE CONCAT('Gain Top-',profit_rank) END AS 'overall_rank'
FROM rank_profit_loss
WHERE profit_rank <= 3 OR loss_rank <= 3
ORDER BY CASE WHEN overall > 0 THEN 0 ELSE 1 END, ABS(overall) DESC

