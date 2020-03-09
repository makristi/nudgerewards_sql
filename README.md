It was a part of interview coding test for Nudge Rewards

Requirements were to write PostgreSQL queries to answer the following questions:

● QUESTION 1
We have an event log table with the following structure:
id | user_id | action | log_date int int varchar
date-time
- Write a SQL query that will get last month’s data, by day, with the following result columns:
Date
Users (Distinct count of user_ids, regardless of action)
Test_Actions (Count of records with the action “test”)

● QUESTION 2
Starting with the same initial table as Question 1, write a SQL query (or several queries)
that identifies distinct user sessions where a session is defined as:
- An ordered (by log_date) series of events for a specific user where each event
occurs within 5 minutes of the preceding event.
- Or put another way, any gap of over 5 minutes between events for a specific user_id
indicates the end of a session, with the next event (the one over 5 minutes after it’s
preceding event) the start of the next session.
- The result of these session queries should have the following format:
id | user_id | session_start | session_end | duration (in seconds) int int
date-time date-time int
