WITH DataCleaning AS (
	SELECT
		UPPER(TRIM(u.country)) AS country_name, 
		u.id AS user_id,
		t.transaction_timestamp, 
		t.amount,
		t.merchant_category,
		t.currency
	FROM users AS u
	INNER JOIN transactions AS t
		ON u.id = t.user_id
	INNER JOIN cards AS c
		ON u.id = c.user_id
	WHERE u.is_active = 1 AND t.status = 'COMPLETED'
),

UnionGBandFR AS (
	SELECT
		country_name,
		user_id,
		transaction_timestamp,
		amount,
		merchant_category,
		currency
	FROM DataCleaning
	WHERE country_name = 'GB' 
	  AND amount >= 500 
	  AND (merchant_category = 'CRYPTO' OR merchant_category = 'TRAVEL')

	UNION ALL

	SELECT
		country_name,
		user_id,
		transaction_timestamp,
		amount,
		merchant_category,
		currency
	FROM DataCleaning
	WHERE country_name = 'FR' 
	  AND amount >= 400 
	  AND (merchant_category = 'LUXURY' OR merchant_category = 'ELECTRONICS')
),

SumAndLag AS (
	SELECT
		country_name,
		user_id,
		transaction_timestamp,
		amount,
		merchant_category,
		currency,
		-- Running cumulative spend per user
		SUM(amount) OVER (PARTITION BY user_id ORDER BY transaction_timestamp) AS cumulative_sum,
		-- Time of the previous transaction for velocity tracking
		LAG(transaction_timestamp, 1) OVER (PARTITION BY user_id ORDER BY transaction_timestamp) AS prev_transaction_time,
		-- Dense rank based on transaction amount
		DENSE_RANK() OVER (PARTITION BY user_id ORDER BY amount DESC) AS amount_rank
	FROM UnionGBandFR
)

SELECT
	country_name AS country,
	user_id,
	transaction_timestamp,
	amount,
	merchant_category,
	cumulative_sum,
	amount_rank
FROM SumAndLag
WHERE cumulative_sum >= 1000 OR amount_rank <= 2
ORDER BY country_name ASC, user_id ASC, transaction_timestamp DESC;
