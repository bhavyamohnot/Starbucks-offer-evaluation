-- 02_offer_funnel.sql  (MySQL 8.4)
-- One row per offer sent ("offer instance"), with its view/completion matched
-- to the right instance, then the funnel and wasted-reward analysis.
USE starbucks;

-- A) Offer instances: every "offer received" event, with its validity window.
DROP TABLE IF EXISTS offer_instances;
CREATE TABLE offer_instances AS
SELECT
  e.event_id      AS instance_id,
  e.customer_id,
  e.offer_id,
  o.offer_type,
  o.offer_code,
  o.reward,
  e.hour                    AS received_hour,
  e.hour + o.duration_hours AS end_hour
FROM events e
JOIN offers o USING (offer_id)
WHERE e.event = 'offer received';
ALTER TABLE offer_instances ADD PRIMARY KEY (instance_id),
  ADD INDEX idx_match (customer_id, offer_id, received_hour);

-- B) Match each view / completion to the most recent instance of the same
--    offer that was still valid at that moment.
DROP TABLE IF EXISTS offer_event_map;
CREATE TABLE offer_event_map AS
SELECT
  e.event_id, e.event, e.hour, e.reward_paid,
  (SELECT i.instance_id
     FROM offer_instances i
    WHERE i.customer_id = e.customer_id
      AND i.offer_id    = e.offer_id
      AND i.received_hour <= e.hour
      AND e.hour <= i.end_hour
    ORDER BY i.received_hour DESC
    LIMIT 1) AS instance_id
FROM events e
WHERE e.event IN ('offer viewed', 'offer completed');

-- C) Outcome per instance.
DROP TABLE IF EXISTS offer_outcomes;
CREATE TABLE offer_outcomes AS
SELECT
  i.*,
  m.first_view_hour,
  m.first_complete_hour,
  COALESCE(m.reward_paid, 0) AS reward_paid,
  CASE
    WHEN i.offer_type = 'informational' THEN
      IF(m.first_view_hour IS NULL, 'ignored', 'viewed (informational)')
    WHEN m.first_complete_hour IS NOT NULL
         AND m.first_view_hour IS NOT NULL
         AND m.first_view_hour <= m.first_complete_hour THEN 'influenced'
    WHEN m.first_complete_hour IS NOT NULL THEN 'wasted'
    WHEN m.first_view_hour IS NOT NULL THEN 'viewed, not completed'
    ELSE 'ignored'
  END AS outcome
FROM offer_instances i
LEFT JOIN (
  SELECT instance_id,
         MIN(IF(event = 'offer viewed',    hour, NULL)) AS first_view_hour,
         MIN(IF(event = 'offer completed', hour, NULL)) AS first_complete_hour,
         SUM(IF(event = 'offer completed', reward_paid, 0)) AS reward_paid
  FROM offer_event_map
  WHERE instance_id IS NOT NULL
  GROUP BY instance_id
) m USING (instance_id);
ALTER TABLE offer_outcomes ADD PRIMARY KEY (instance_id),
  ADD INDEX idx_cust (customer_id, received_hour, end_hour);

-- Check: how many views/completions could not be matched to a valid instance?
SELECT event, COUNT(*) AS events, SUM(instance_id IS NULL) AS unmatched
FROM offer_event_map GROUP BY event;

-- D) Funnel per offer.
SELECT
  offer_code,
  COUNT(*)                                                      AS sent,
  ROUND(100 * AVG(first_view_hour IS NOT NULL), 1)              AS view_rate,
  ROUND(100 * AVG(first_complete_hour IS NOT NULL), 1)          AS completion_rate,
  ROUND(100 * AVG(outcome = 'influenced'), 1)                   AS influenced_rate,
  ROUND(100 * SUM(outcome = 'wasted')
        / NULLIF(SUM(first_complete_hour IS NOT NULL), 0), 1)   AS pct_completions_wasted,
  ROUND(SUM(reward_paid), 0)                                    AS reward_cost,
  ROUND(SUM(IF(outcome = 'wasted', reward_paid, 0)), 0)         AS wasted_reward
FROM offer_outcomes
GROUP BY offer_code
ORDER BY offer_code;

-- E) Totals for the rewarded offers (BOGO + discount).
SELECT
  COUNT(*) AS sent,
  SUM(first_complete_hour IS NOT NULL) AS completions,
  SUM(outcome = 'influenced') AS influenced,
  SUM(outcome = 'wasted') AS wasted,
  ROUND(100 * SUM(outcome = 'wasted') / SUM(first_complete_hour IS NOT NULL), 1) AS pct_completions_wasted,
  ROUND(SUM(reward_paid), 0) AS total_reward_cost,
  ROUND(SUM(IF(outcome = 'wasted', reward_paid, 0)), 0) AS wasted_reward_cost,
  ROUND(100 * SUM(IF(outcome = 'wasted', reward_paid, 0)) / SUM(reward_paid), 1) AS pct_reward_wasted
FROM offer_outcomes
WHERE offer_type <> 'informational';
