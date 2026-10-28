# Starbucks Offer Evaluation: Which Rewards Were Worth Paying For? (MySQL · Google Sheets)

Evaluates 10 reward offers (BOGO, discount, informational) sent to 17,000 Starbucks Rewards app customers: did each offer **cause** extra spending, how much of the reward budget was wasted, and which customers should receive which offer. Built as a CRM / loyalty-programme analysis (e.g. cashback programmes like CLiQ Cash).

**📊 Dashboard:** [Google Sheets (pivots, slicer, reconciliation)]  ·  **📝 Memo:** [docs/memo.md](docs/memo.md)  ·  **🔢 Full results:** [docs/results.md](docs/results.md)

## Key findings
| | |
|---|---|
| Wasted rewards | **30% of reward spend ($49.4k of $164.7k)** went to customers who completed the offer without viewing it |
| ROI by offer type | Discounts: **$4.08** extra spend per $1 of reward · BOGO: **$1.92** |
| Best offer | $2 off $10, 10 days, all channels: **$9.84** per reward dollar, 60% influenced, 12.5% waste |
| Worst offer | $5 off $20: 35% view rate, **61% of completions wasted**, $1.42 per reward dollar |
| Free lift | Informational messages (no reward) added ~$50k of spend |
| Best segment | $75–100k income, 1–2-year members: ~53% influenced, $2+/day extra spend |
| Leakage segment | $100k+ customers: 45% of discount completions wasted |

## Analysis modules
| Module | Question | SQL |
|---|---|---|
| Load | Create database, load 3 CSVs | [00_load_mysql.sql](sql/00_load_mysql.sql) |
| 1. Clean & data quality | Parse the mixed JSON `value` column; handle age = 118 placeholder | [01_clean_and_quality.sql](sql/01_clean_and_quality.sql) |
| 2. Offer funnel | View rate, completion rate, influenced vs wasted completions | [02_offer_funnel.sql](sql/02_offer_funnel.sql) |
| 3. Incrementality & ROI | Did offers raise spending, and did it cover the reward cost? | [03_incrementality_roi.sql](sql/03_incrementality_roi.sql) |
| 4. Segments | Which income / age / gender / tenure groups respond? | [04_segments.sql](sql/04_segments.sql) |
| Exports | Tables for the Google Sheets dashboard | [05_exports.sql](sql/05_exports.sql) |

## Methods
- **MySQL 8.4:** `LOAD DATA LOCAL INFILE`, JSON parsing (`->>`), indexes, correlated subqueries, CTEs, conditional aggregation, `UNION ALL` reshaping.
- **Offer attribution:** each offer sent is an instance with a validity window; each view/completion is matched to the most recent valid instance. A completion is **influenced** only if the offer was viewed first; otherwise it is **wasted**.
- **Incrementality (difference-in-differences):** lift = spend/day in the offer window minus the customer's own 30-day average; effect = lift of viewers minus lift of recipients who never viewed. ROI = incremental spend ÷ reward cost.
- **Google Sheets:** pivot tables (COUNTA, % of row), slicer, ROI chart, and a **reconciliation table** that checks every sheet total against SQL control totals with `COUNTIF` / `SUMIF` / `IF` (all 5 match).

## Limitations
- Simulated data. Observational, not a randomised test: viewers may be more engaged customers; comparing each customer with their own baseline reduces but does not remove this bias.
- Overlapping offer windows mean some spend counts under more than one offer.
- Channels are bundled per offer (all use email), so single-channel effects cannot be isolated.
- BOGO cost is booked at reward face value; margin is not in the data.

## Reproduce
1. Download [ihormuliar/starbucks-customer-data](https://www.kaggle.com/datasets/ihormuliar/starbucks-customer-data) (CDLA-Permissive) into `data/raw/`.
2. Enable local file loading: `SET PERSIST local_infile = 1;`
3. Run `sql/00` → `sql/05` in order (`mysql --local-infile=1 < file.sql`), updating the CSV paths in `00_load_mysql.sql`.

## Tools
MySQL 8.4 · Google Sheets · Git/GitHub
