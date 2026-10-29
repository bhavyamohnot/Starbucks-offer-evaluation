USE starbucks;

DROP TABLE IF EXISTS offer_segment_base;
CREATE TABLE offer_segment_base AS
SELECT
  w.offer_type, w.outcome, w.viewed, w.lift_per_day, w.reward_paid,
  c.income_band,
  c.age_band,
  COALESCE(c.gender, 'unknown') AS gender,
  CASE
    WHEN c.member_since >= '2018-01-01' THEN '1 joined 2018'
    WHEN c.member_since >= '2017-01-01' THEN '2 joined 2017'
    WHEN c.member_since >= '2016-01-01' THEN '3 joined 2016'
    ELSE '4 joined before 2016'
  END AS tenure_band
FROM offer_window_spend w
JOIN customers c USING (customer_id)
WHERE w.offer_type <> 'informational';

DROP TABLE IF EXISTS segment_response;
CREATE TABLE segment_response AS
WITH long_form AS (
  SELECT 'income' AS dimension, income_band AS segment, b.* FROM offer_segment_base b
  UNION ALL SELECT 'age',    age_band,    b.* FROM offer_segment_base b
  UNION ALL SELECT 'gender', gender,      b.* FROM offer_segment_base b
  UNION ALL SELECT 'tenure', tenure_band, b.* FROM offer_segment_base b
)
SELECT
  dimension, segment, offer_type,
  COUNT(*)                                             AS offers_sent,
  ROUND(100 * AVG(viewed), 1)                          AS view_rate,
  ROUND(100 * AVG(outcome = 'influenced'), 1)          AS influenced_rate,
  ROUND(100 * SUM(outcome = 'wasted')
        / NULLIF(SUM(outcome IN ('influenced', 'wasted')), 0), 1) AS pct_completions_wasted,
  ROUND(AVG(IF(viewed = 1, lift_per_day, NULL))
      - AVG(IF(viewed = 0, lift_per_day, NULL)), 2)    AS incremental_per_day,
  ROUND(SUM(reward_paid) / NULLIF(SUM(outcome = 'influenced'), 0), 2) AS reward_cost_per_influenced
FROM long_form
GROUP BY dimension, segment, offer_type;

SELECT dimension, segment, offer_type, offers_sent, view_rate, influenced_rate,
       pct_completions_wasted, incremental_per_day, reward_cost_per_influenced
FROM segment_response
WHERE dimension IN ('income', 'age')
ORDER BY dimension, offer_type, segment;

SELECT dimension, segment, offer_type, offers_sent, view_rate, influenced_rate,
       pct_completions_wasted, incremental_per_day, reward_cost_per_influenced
FROM segment_response
WHERE dimension IN ('gender', 'tenure')
ORDER BY dimension, offer_type, segment;
