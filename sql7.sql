WITH Filter_1 AS ( 
	SELECT	
		u.id AS user_id,
		UPPER(TRIM(u.country)) AS trimmed_country,
		t.transaction_timestamp,
		t.amount,
		t.merchant_category
	FROM users AS u
	INNER JOIN transactions AS t
		ON u.id = t.user_id
	WHERE u.is_active = 1 
	  AND t.status = 'COMPLETED'
),

WindowAnalytics AS (
	SELECT
		user_id,
		trimmed_country,
		transaction_timestamp,
		amount,
		merchant_category,
		SUM(amount) OVER (PARTITION BY user_id ORDER BY transaction_timestamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_amount,
		LAG(transaction_timestamp, 1) OVER (PARTITION BY user_id ORDER BY transaction_timestamp) AS previous_transaction,
		ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY transaction_timestamp DESC) AS row_nr,
		DENSE_RANK() OVER (PARTITION BY user_id ORDER BY transaction_timestamp DESC) AS dense_nr
	FROM Filter_1
)

SELECT
	user_id,
	trimmed_country AS country,
	transaction_timestamp,
	amount,
	merchant_category,
	total_amount,
	previous_transaction,
	row_nr,
	dense_nr
FROM WindowAnalytics
WHERE total_amount > 2500 
   OR (transaction_timestamp - previous_transaction) <= INTERVAL '1 hour'
ORDER BY trimmed_country ASC, user_id ASC, transaction_timestamp DESC;
