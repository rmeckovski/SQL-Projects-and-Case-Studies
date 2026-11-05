WITH data_filter_1 AS (
	SELECT 
		u.account_id,
		u.account_type,
		u.created_at,
		c.risk_level,
		l.booked_at,
		UPPER(TRIM(u.market_code)) AS clean_market_code,
		UPPER(
			CASE 
				WHEN l.merchant_descriptor LIKE '%TRANSFER%' THEN REPLACE(l.merchant_descriptor, 'TRANSFER', 'INTERNAL_TRANSFER')
				WHEN l.merchant_descriptor IS NULL THEN 'UNKNOWN_MERCHANT'
				ELSE l.merchant_descriptor
			END
		) AS clean_merchant_descriptor,
		(l.amount_cents / 100.0) * f.rate AS euro_amount,
		CASE
			WHEN l.entry_type = 'DEBIT' THEN (-1 * (l.amount_cents / 100.0) * f.rate)
			ELSE (+1 * (l.amount_cents / 100.0) * f.rate)
		END AS signed_euro_amount
	FROM user_accounts AS u
	INNER JOIN ledger_entries AS l
		ON u.account_id = l.account_id
	INNER JOIN compliance_flags AS c
		ON u.account_id = c.account_id
	INNER JOIN fx_rates AS f
		ON l.currency = f.from_currency 
	   AND f.to_currency = 'EUR'
	WHERE u.status = 'ACTIVE' 
	  AND l.is_settled = 1
),

union_both AS (
	SELECT
		account_id,
		account_type,
		booked_at,
		created_at,
		risk_level,
		clean_market_code,
		clean_merchant_descriptor,
		euro_amount,
		signed_euro_amount
	FROM data_filter_1
	WHERE (clean_market_code = 'GB' OR clean_market_code = 'US') 
	  AND (euro_amount >= 1000 OR risk_level = 'HIGH')

	UNION ALL

	SELECT
		account_id,
		account_type,
		booked_at,
		created_at,
		risk_level,
		clean_market_code,
		clean_merchant_descriptor,
		euro_amount,
		signed_euro_amount
	FROM data_filter_1
	WHERE (clean_market_code = 'FR' OR clean_market_code = 'DE' OR clean_market_code = 'ES') 
	  AND euro_amount >= 500 
	  AND created_at >= '2024-01-01'
),

calculating AS (
	SELECT
		account_id,
		account_type,
		booked_at,
		created_at,
		risk_level,
		clean_market_code,
		clean_merchant_descriptor,
		euro_amount,
		signed_euro_amount,
		SUM(signed_euro_amount) OVER (PARTITION BY account_id ORDER BY booked_at ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative,
		LAG(booked_at, 1) OVER (PARTITION BY account_id ORDER BY booked_at) AS previous_transaction,
		AVG(signed_euro_amount) OVER (PARTITION BY account_id ORDER BY booked_at ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS avg_for_last_3_transactions,
		ROW_NUMBER() OVER (PARTITION BY clean_market_code, account_type ORDER BY booked_at DESC) AS row_nr,
		DENSE_RANK() OVER (PARTITION BY account_id ORDER BY euro_amount DESC) AS ranking
	FROM union_both
)

SELECT
	clean_market_code AS market_code,
	account_id,
	account_type,
	clean_merchant_descriptor AS merchant_descriptor,
	booked_at,
	ROUND(signed_euro_amount, 2) AS signed_euro_amount,
	ROUND(cumulative, 2) AS cumulative_balance,
	ROUND(avg_for_last_3_transactions, 2) AS avg_for_last_3_transactions,
	(booked_at - previous_transaction) AS time_gap,
	row_nr,
	ranking
FROM calculating
WHERE (cumulative < -2500 OR cumulative > 10000) 
  AND ranking <= 3 
  AND (booked_at - previous_transaction) <= INTERVAL '30 minutes'
ORDER BY clean_market_code ASC, account_id ASC, booked_at DESC;
