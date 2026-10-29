# Starbucks Rewards: Which Offers Were Actually Worth It?

Apps like Starbucks (or CLiQ Cash on Tata CLiQ) keep sending discounts and cashback offers. The question I wanted to answer is simple: did the offer make people spend more, or did we just give money to people who were going to buy anyway?

I used the Starbucks Rewards app dataset (simulated by Starbucks for a Udacity project). It has 17,000 customers, 10 different offers and about 306k app events over 30 days. I did the analysis in MySQL and made the dashboard in Google Sheets.

**Dashboard:** [Google Sheets](https://docs.google.com/spreadsheets/d/1u8Cxzp9UZckH8TFnugbVR53qthWQaBC6Ei03_UrN2CQ/edit?usp=sharing)
**Short memo with recommendations:** [docs/memo.md](docs/memo.md)
**All results in detail:** [docs/results.md](docs/results.md)

## What I found

- 30% of all the reward money ($49k out of $165k) went to people who completed the offer **without ever opening it**. They didn't even know about the offer, so it didn't change anything. That's just wasted money.
- Discounts did much better than BOGO (buy one get one). For every $1 given as a discount, people spent about $4.08 extra. For BOGO it was only $1.92.
- The best offer was "$2 off $10, valid 10 days, sent on all channels": around $9.8 extra spend per $1 of reward.
- The worst was "$5 off $20". Only 35% of people even viewed it and 61% of its completions were wasted.
- Informational messages (no discount at all) still added about $50k in spend. Sometimes a reminder is enough.
- People earning $75-100k who have been members for 1-2 years respond the best. People earning $100k+ spend a lot, but 45% of their rewards were wasted. New members (joined 2018) barely respond to anything.

What I'd suggest: give the reward only after the customer has opened the offer, move budget from BOGO to discounts, stop the $5-off-$20 offer, and always keep around 10% of customers as a holdout to check if offers really work.

## How I did it

- **Cleaning:** the events table had offer id, amount and reward all mixed inside one text column, so I converted it to JSON and split it out. Age 118 is basically "unknown" in this data, so I set it to NULL.
- **Matching events to offers:** every offer someone received has a valid window (say 7 days). Each view and completion is matched to the right offer in that window. If someone completed an offer without viewing it first, I counted it as "wasted".
- **Did it increase spending?** For each offer I compared how much more a customer spent per day during the offer vs their normal 30-day average. Then I compared people who viewed the offer with people who got it but never opened it (difference-in-differences). The difference is the extra spend the offer caused, and I divided it by the reward cost to get ROI.
- **Segments:** same numbers split by income, age, gender and how long someone has been a member.
- **Google Sheets:** I built pivot tables, a slicer, an ROI chart and a small check table (COUNTIF / SUMIF) that matches the sheet totals with the SQL totals. All 5 checks matched.

SQL files, in order:

- `00_load_mysql.sql` - create the database and load the 3 CSVs
- `01_clean_and_quality.sql` - clean tables + data checks
- `02_offer_funnel.sql` - views, completions, influenced vs wasted
- `03_incrementality_roi.sql` - extra spend and ROI per offer
- `04_segments.sql` - which customers respond
- `05_exports.sql` - the tables I exported to Google Sheets

## Things I learned / got stuck on

- In my first pivot I used SUM of instance_id instead of COUNTA, so the numbers were huge and meaningless. Counting rows and adding up IDs are not the same thing.
- MySQL wouldn't let me put an index on the offer_id column pulled from JSON (it was TEXT), so I had to CAST it to CHAR(32).
- The JSON in the raw file used single quotes, which isn't valid JSON, so I had to replace them before parsing.
- My slicer was filtering both pivots at first, which I didn't want.

## Limitations

- The data is simulated, not real Starbucks data.
- This isn't a proper A/B test. People who open offers might just be more active customers anyway. Comparing them to their own normal spend helps, but a real holdout group would be better.
- Some offers overlap in time, so a bit of spend gets counted under more than one offer.
- For BOGO I counted the full reward value as the cost. The real cost of a free drink is lower.

## If you want to run it yourself

1. Download [ihormuliar/starbucks-customer-data](https://www.kaggle.com/datasets/ihormuliar/starbucks-customer-data) from Kaggle.
2. In MySQL run `SET PERSIST local_infile = 1;`
3. Change the CSV paths in `00_load_mysql.sql` to where you saved them, then run the files 00 to 05 in order.
