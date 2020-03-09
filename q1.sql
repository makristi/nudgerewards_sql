WITH last_month_set AS
(
	SELECT
		log_date::date as ts,
		user_id,
		action
	FROM event_log_table
	WHERE extract(MONTH from log_date)::INT = extract(MONTH from (now() - interval '1 month'))::INT
)
SELECT
	ts as date,
	count(distinct user_id) as users,
	sum(case when lower(action) = 'test' then 1 else 0 end ) as test_actions
FROM last_month_set
GROUP BY ts