-- 01_clean_and_quality.sql  (MySQL 8.4)
-- Turn the 3 raw tables into clean tables, then run data-quality checks.
USE starbucks;

-- Offers: readable code + one flag per channel.
DROP TABLE IF EXISTS offers;
CREATE TABLE offers AS
SELECT
  id AS offer_id,
  offer_type,
  CONCAT(offer_type, '_', reward, '_', difficulty, '_', duration, 'd') AS offer_code,
  reward,              -- $ given back on completion
  difficulty,          -- $ the customer must spend to complete
  duration AS duration_days,
  duration * 24 AS duration_hours,
  LOCATE('email',  channels) > 0 AS ch_email,
  LOCATE('mobile', channels) > 0 AS ch_mobile,
  LOCATE('social', channels) > 0 AS ch_social,
  LOCATE('web',    channels) > 0 AS ch_web
FROM raw_portfolio;
ALTER TABLE offers ADD PRIMARY KEY (offer_id);

-- Customers: age 118 is the dataset's code for "missing".
DROP TABLE IF EXISTS customers;
CREATE TABLE customers AS
SELECT
  id AS customer_id,
  gender,
  IF(age = 118, NULL, age) AS age,
  income,
  STR_TO_DATE(became_member_on, '%Y%m%d') AS member_since,
  age = 118 AS missing_demographics,
  CASE
    WHEN age = 118 THEN 'unknown'
    WHEN income < 50000 THEN '1 <50k'
    WHEN income < 75000 THEN '2 50-75k'
    WHEN income < 100000 THEN '3 75-100k'
    ELSE '4 100k+'
  END AS income_band,
  CASE
    WHEN age = 118 THEN 'unknown'
    WHEN age < 35 THEN '1 18-34'
    WHEN age < 50 THEN '2 35-49'
    WHEN age < 65 THEN '3 50-64'
    ELSE '4 65+'
  END AS age_band
FROM raw_profile;
ALTER TABLE customers ADD PRIMARY KEY (customer_id);

-- Events: split the mixed `value` text into proper columns.
-- value looks like {'offer id': '...'} or {'amount': 0.83} or {'offer_id': '...', 'reward': 2}
DROP TABLE IF EXISTS events;
CREATE TABLE events AS
SELECT
  idx AS event_id,
  person AS customer_id,
  event,
  time AS hour,                                  -- hours since the test started
  CAST(COALESCE(v ->> '$."offer id"', v ->> '$.offer_id') AS CHAR(32)) AS offer_id,
  CAST(v ->> '$.amount' AS DECIMAL(10,2))      AS amount,
  CAST(v ->> '$.reward' AS DECIMAL(10,2))      AS reward_paid
FROM (
  SELECT idx, person, event, time, CAST(REPLACE(value, '''', '"') AS JSON) AS v
  FROM raw_transcript
) t;
ALTER TABLE events ADD PRIMARY KEY (event_id),
                   ADD INDEX idx_cust_hour (customer_id, hour),
                   ADD INDEX idx_offer (offer_id);

-- Check 1: event mix.
SELECT event, COUNT(*) AS events, COUNT(DISTINCT customer_id) AS customers
FROM events
GROUP BY event ORDER BY events DESC;

-- Check 2: did the parsing work?
SELECT
  SUM(event <> 'transaction' AND offer_id IS NULL)   AS offer_events_missing_id,
  SUM(event = 'transaction' AND amount IS NULL)      AS transactions_missing_amount,
  SUM(event = 'offer completed' AND reward_paid IS NULL) AS completions_missing_reward
FROM events;

-- Check 3: missing demographics.
SELECT
  COUNT(*) AS customers,
  SUM(missing_demographics) AS missing_demographics,
  ROUND(100 * SUM(missing_demographics) / COUNT(*), 1) AS pct_missing,
  SUM(missing_demographics AND (gender IS NOT NULL OR income IS NOT NULL)) AS inconsistent_rows
FROM customers;

-- Check 4: test length.
SELECT MIN(hour) AS first_hour, MAX(hour) AS last_hour, ROUND(MAX(hour) / 24, 1) AS days
FROM events;
