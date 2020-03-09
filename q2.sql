/* Note: you might need to run CREATE EXTENSION btree_gist first */

-- find whether there is an event happened in the next 5 minutes or not
-- return will be null or log_date for next event within 5 min
WITH interval_set AS 
(
	SELECT 
		id, 
		user_id,
		log_date as interval_start,
		interval_end 
	FROM event_log_table cur_event
	LEFT JOIN LATERAL
	(
		SELECT log_date as interval_end
		FROM event_log_table 
		WHERE user_id = cur_event.user_id 
		AND log_date > cur_event.log_date 
		AND log_date <= cur_event.log_date + interval '5 minutes'
		ORDER BY log_date <-> cur_event.log_date -- nearest result
		LIMIT 1
	) prev_event on True
), 
-- get rid off all intermitten intervals
-- leave only ones which ended (interval_end is null) 
-- or ones that started (interval_start isn't some other interval's end date)
uncollapsed_set AS 
(
	SELECT *, 
		-- rank is included for easier comparison in the next step, but it could have been skipped too
		RANK () OVER (PARTITION BY user_id ORDER BY interval_start DESC) rank_nu 
	FROM interval_set rs
	WHERE interval_end IS NULL 
	OR NOT EXISTS (
			SELECT * 
			FROM interval_set rs2 
			WHERE rs.interval_start = rs2.interval_end
	)
)
SELECT *, 
	EXTRACT(EPOCH FROM (session_end - session_start))
FROM
(
	-- for each event we are trying to find previous event (rank - 1)
	-- if there is one and it has end date, then "collapse"
	-- if no, then leave it as it is own session
	SELECT 
		COALESCE(a.id, cs.id) as id, -- id of the log_record which starts session
		cs.user_id,
		case when a.interval_start is null then cs.interval_start else a.interval_start end as session_start,
		-- assumption is that session_end is last_event + 5 min
		-- so, if there was only 1 event in the session at 15:30, then start is 15:30 and end 15:35
		-- if first event was on 15:30 and lest event in the session happened on 15.50, then
		-- start is 15:30 and end is 15.50+5 min = 15.55
		cs.interval_start + interval '5 minutes' as session_end
		/* if we wanted to have end_session as the log_date of last event in the session,
		and if there was only 1 event in session, leave end_date as null, then the following is tru:
		case when a.interval_start is null then cs.interval_end else cs.interval_start end as session_end
		*/
	FROM uncollapsed_set cs
	LEFT JOIN LATERAL
	(
		SELECT id, interval_start 
		FROM uncollapsed_set 
		WHERE user_id = cs.user_id 
		AND rank_nu-1 = cs.rank_nu 
		AND interval_end is not null 
		AND cs.interval_end is null
		LIMIT 1
	)a ON true
	WHERE cs.interval_end is null
)a