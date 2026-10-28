-- 00_load_mysql.sql
-- Create the database and load the 3 raw CSVs (run with: mysql --local-infile=1).
-- Replace the paths with where your CSVs are.

CREATE DATABASE IF NOT EXISTS starbucks;
USE starbucks;

DROP TABLE IF EXISTS raw_portfolio, raw_profile, raw_transcript;

CREATE TABLE raw_portfolio (
  idx INT, reward INT, channels VARCHAR(100), difficulty INT,
  duration INT, offer_type VARCHAR(20), id CHAR(32)
);

CREATE TABLE raw_profile (
  idx INT, gender VARCHAR(5), age INT, id CHAR(32),
  became_member_on CHAR(8), income DECIMAL(10,1) NULL
);

CREATE TABLE raw_transcript (
  idx INT, person CHAR(32), event VARCHAR(20), value VARCHAR(200), time INT
);

LOAD DATA LOCAL INFILE 'C:/Users/erbha/starbucks-offer-evaluation/data/raw/portfolio.csv'
INTO TABLE raw_portfolio
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Empty gender/income cells become NULL instead of '' / 0.
LOAD DATA LOCAL INFILE 'C:/Users/erbha/starbucks-offer-evaluation/data/raw/profile.csv'
INTO TABLE raw_profile
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(idx, @gender, age, id, became_member_on, @income)
SET gender = NULLIF(@gender, ''),
    income = NULLIF(@income, '');

LOAD DATA LOCAL INFILE 'C:/Users/erbha/starbucks-offer-evaluation/data/raw/transcript.csv'
INTO TABLE raw_transcript
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT 'raw_portfolio' AS tbl, COUNT(*) AS row_count FROM raw_portfolio
UNION ALL SELECT 'raw_profile', COUNT(*) FROM raw_profile
UNION ALL SELECT 'raw_transcript', COUNT(*) FROM raw_transcript;
