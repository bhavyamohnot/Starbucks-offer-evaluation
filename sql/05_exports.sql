-- 05_exports.sql  (MySQL 8.4)
-- Tables exported to CSV for the Google Sheets dashboard.
-- Each query is run separately by the export script; the -- @file tag names the output.
USE starbucks;

-- @file offer_summary
SELECT
  f.offer_code, f.offer_type, f.sent, f.view_rate, f.completion_rate, f.influenced_rate,
  f.pct_completions_wasted, f.reward_cost, f.wasted_reward,
  r.incremental_spend, r.incremental_spend_per_reward_dollar AS roi
FROM (
  SELECT offer_code, offer_type,
         COUNT(*) AS sent,
         ROUND(AVG(first_view_hour IS NOT NULL), 4)     AS view_rate,
         ROUND(AVG(first_complete_hour IS NOT NULL), 4) AS completion_rate,
         ROUND(AVG(outcome = 'influenced'), 4)          AS influenced_rate,
         ROUND(SUM(outcome = 'wasted') / NULLIF(SUM(first_complete_hour IS NOT NULL), 0), 4) AS pct_completions_wasted,
         ROUND(SUM(reward_paid), 0)                     AS reward_cost,
         ROUND(SUM(IF(outcome = 'wasted', reward_paid, 0)), 0) AS wasted_reward
  FROM offer_outcomes
  GROUP BY offer_code, offer_type
) f
JOIN offer_roi r USING (offer_code)
ORDER BY f.offer_code;

-- @file offer_outcomes
SELECT
  w.instance_id, w.customer_id, w.offer_code, w.offer_type, w.outcome,
  w.viewed, w.reward_paid, ROUND(w.window_spend, 2) AS window_spend,
  c.income_band, c.age_band, COALESCE(c.gender, 'unknown') AS gender,
  CASE
    WHEN c.member_since >= '2018-01-01' THEN '1 joined 2018'
    WHEN c.member_since >= '2017-01-01' THEN '2 joined 2017'
    WHEN c.member_since >= '2016-01-01' THEN '3 joined 2016'
    ELSE '4 joined before 2016'
  END AS tenure_band
FROM offer_window_spend w
JOIN customers c USING (customer_id)
ORDER BY w.instance_id;

-- @file segment_response
SELECT * FROM segment_response ORDER BY dimension, segment, offer_type;

-- @file sql_control_totals
SELECT 'offers sent' AS metric, COUNT(*) AS sql_value FROM offer_outcomes
UNION ALL SELECT 'influenced completions', SUM(outcome = 'influenced') FROM offer_outcomes
UNION ALL SELECT 'wasted completions', SUM(outcome = 'wasted') FROM offer_outcomes
UNION ALL SELECT 'total reward cost', ROUND(SUM(reward_paid), 0) FROM offer_outcomes
UNION ALL SELECT 'wasted reward cost', ROUND(SUM(IF(outcome = 'wasted', reward_paid, 0)), 0) FROM offer_outcomes;
