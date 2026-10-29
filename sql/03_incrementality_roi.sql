USE starbucks;

DROP TABLE IF EXISTS customer_baseline;
CREATE TABLE customer_baseline AS
SELECT c.customer_id,
       COALESCE(SUM(e.amount), 0) / 30 AS spend_per_day
FROM customers c
LEFT JOIN events e
  ON e.customer_id = c.customer_id AND e.event = 'transaction'
GROUP BY c.customer_id;
ALTER TABLE customer_baseline ADD PRIMARY KEY (customer_id);

DROP TABLE IF EXISTS offer_window_spend;
CREATE TABLE offer_window_spend AS
SELECT
  o.instance_id, o.customer_id, o.offer_code, o.offer_type, o.outcome, o.reward_paid,
  o.first_view_hour IS NOT NULL AS viewed,
  (o.end_hour - o.received_hour) / 24 AS window_days,
  COALESCE(SUM(t.amount), 0) AS window_spend,
  COALESCE(SUM(t.amount), 0) / ((o.end_hour - o.received_hour) / 24) - b.spend_per_day AS lift_per_day
FROM offer_outcomes o
JOIN customer_baseline b USING (customer_id)
LEFT JOIN events t
  ON t.customer_id = o.customer_id
 AND t.event = 'transaction'
 AND t.hour BETWEEN o.received_hour AND o.end_hour
GROUP BY o.instance_id, o.customer_id, o.offer_code, o.offer_type, o.outcome,
         o.reward_paid, viewed, window_days, b.spend_per_day;

DROP TABLE IF EXISTS offer_roi;
CREATE TABLE offer_roi AS
SELECT
  offer_code,
  offer_type,
  SUM(viewed)                                       AS viewed_count,
  ROUND(AVG(IF(viewed = 1, lift_per_day, NULL)), 2) AS lift_viewed,
  ROUND(AVG(IF(viewed = 0, lift_per_day, NULL)), 2) AS lift_not_viewed,
  ROUND(AVG(IF(viewed = 1, lift_per_day, NULL)) - AVG(IF(viewed = 0, lift_per_day, NULL)), 2) AS incremental_per_day,
  ROUND((AVG(IF(viewed = 1, lift_per_day, NULL)) - AVG(IF(viewed = 0, lift_per_day, NULL)))
        * MAX(window_days) * SUM(viewed), 0)        AS incremental_spend,
  ROUND(SUM(reward_paid), 0)                        AS reward_cost,
  ROUND((AVG(IF(viewed = 1, lift_per_day, NULL)) - AVG(IF(viewed = 0, lift_per_day, NULL)))
        * MAX(window_days) * SUM(viewed) / NULLIF(SUM(reward_paid), 0), 2) AS incremental_spend_per_reward_dollar
FROM offer_window_spend
GROUP BY offer_code, offer_type;

SELECT * FROM offer_roi ORDER BY incremental_spend_per_reward_dollar DESC;

SELECT offer_type,
       ROUND(SUM(incremental_spend), 0) AS incremental_spend,
       ROUND(SUM(reward_cost), 0)       AS reward_cost,
       ROUND(SUM(incremental_spend) / NULLIF(SUM(reward_cost), 0), 2) AS spend_per_reward_dollar
FROM offer_roi
GROUP BY offer_type;
