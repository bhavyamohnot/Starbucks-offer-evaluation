# Results Log

Simulated Starbucks Rewards app data (Udacity/Starbucks; Kaggle `ihormuliar/starbucks-customer-data`): 17,000 customers, 10 offers, 306,534 events over 30 days. Analysis in **MySQL 8.4**.

---

## Module 1: Load, clean, data quality
**SQL:** `sql/00_load_mysql.sql`, `sql/01_clean_and_quality.sql`

| Check | Result |
|---|---|
| Events | 138,953 transactions · 76,277 offers received · 57,725 viewed · 33,579 completed |
| Parsing the mixed `value` column (offer id / amount / reward in one text field) | Converted to JSON and split into typed columns; **0 rows failed** |
| Missing demographics | 2,175 customers (12.8%) have age = 118 (placeholder), no gender, no income; nulled and kept as an "unknown" segment |
| Test length | 30 days (hour 0–714) |
| Channels | Every offer uses email; channels are bundled per offer, so single-channel effects cannot be isolated |

## Module 2: Offer funnel & wasted rewards
**SQL:** `sql/02_offer_funnel.sql` (builds `offer_instances`, `offer_event_map`, `offer_outcomes`)
**Method:** each "offer received" is one offer instance with a validity window (received hour + duration). Each view/completion is matched to the most recent valid instance of the same offer for the same customer. A completion counts as **influenced** only if the offer was viewed before it was completed; a completion with no prior view is **wasted** (the customer would have hit the spend threshold anyway). 1,158 views (2%) fell after the offer expired and were left unmatched.

| Offer | Sent | View rate | Completion rate | Influenced rate | % of completions wasted | Reward cost | Wasted reward |
|---|---|---|---|---|---|---|---|
| bogo_10_10_5d | 7,593 | 95.3% | 43.5% | 36.1% | 17.0% | $33,310 | $5,720 |
| bogo_10_10_7d | 7,658 | 87.2% | 47.5% | 33.7% | 29.0% | $36,880 | $10,820 |
| bogo_5_5_5d | 7,571 | 95.2% | 56.3% | 46.4% | 17.6% | $21,480 | $3,835 |
| bogo_5_5_7d | 7,677 | 53.8% | 56.1% | 27.4% | 51.1% | $21,770 | $11,150 |
| discount_2_10_10d | 7,597 | 96.4% | 68.8% | **60.2%** | **12.5%** | $10,634 | $1,348 |
| discount_2_10_7d | 7,632 | 53.2% | 51.8% | 27.5% | 46.9% | $8,034 | $3,766 |
| discount_3_7_7d | 7,646 | 95.9% | 66.7% | 56.9% | 14.8% | $15,468 | $2,304 |
| discount_5_20_10d | 7,668 | 34.6% | 43.2% | 17.0% | **60.8%** | $17,100 | $10,420 |
| informational_0_0_3d | 7,618 | 80.7% | n/a | n/a | n/a | $0 | $0 |
| informational_0_0_4d | 7,617 | 49.9% | n/a | n/a | n/a | $0 | $0 |

**Totals (rewarded offers):** 33,101 completions, of which 23,267 influenced and 9,834 wasted. **$49.4k of $164.7k reward spend (30%) went to customers who never saw the offer before completing it.**

**Findings**
- The headline "completion rate" overstates offer performance: 30% of completions (and of reward cost) were not driven by the offer.
- Waste tracks view rate. The 4 offers sent **without social** have view rates of 35–54%, vs 81–96% for the 6 offers that include social (and mobile). Channels are bundled, so this is a strong pattern across all 10 offers rather than a proven causal channel effect.
- **Best offer:** discount_2_10_10d: 60% influenced, only 12.5% waste, lowest reward cost per completion.
- **Worst offer:** discount_5_20_10d: $20 spend threshold, 35% view rate, **61% of completions wasted**. It mostly rewards big spenders for purchases they were already making.

## Module 3: Incremental spend & ROI
**SQL:** `sql/03_incrementality_roi.sql` (builds `customer_baseline`, `offer_window_spend`, `offer_roi`)
**Method:** difference-in-differences. For every offer sent, lift = customer's spend per day inside the offer window minus their own average daily spend over the 30 days. Incremental effect per offer = average lift of customers who viewed it minus average lift of customers who received the same offer but never viewed it. Incremental spend = that difference × window length × number of viewers. ROI = incremental spend ÷ reward cost.

| Offer | Incremental $/day per viewer | Incremental spend | Reward cost | Incremental $ per $1 reward |
|---|---|---|---|---|
| discount_2_10_10d | $1.43 | $104,685 | $10,634 | **9.84** |
| discount_2_10_7d | $1.39 | $39,504 | $8,034 | 4.92 |
| discount_3_7_7d | $0.79 | $40,775 | $15,468 | 2.64 |
| bogo_5_5_5d | $1.54 | $55,502 | $21,480 | 2.58 |
| bogo_10_10_5d | $1.83 | $66,328 | $33,310 | 1.99 |
| bogo_10_10_7d | $1.34 | $62,713 | $36,880 | 1.70 |
| bogo_5_5_7d | $1.14 | $32,912 | $21,770 | 1.51 |
| discount_5_20_10d | $0.91 | $24,241 | $17,100 | **1.42** |
| informational_0_0_3d | $1.65 | $30,454 | $0 | free |
| informational_0_0_4d | $1.31 | $19,936 | $0 | free |

| Offer type | Incremental spend | Reward cost | $ per $1 reward |
|---|---|---|---|
| Discount | $209k | $51k | **4.08** |
| BOGO | $217k | $113k | 1.92 |
| Informational | $50k | $0 | n/a |

**Findings**
- **Discounts return about twice as much per reward dollar as BOGO** ($4.08 vs $1.92). BOGO drives similar extra spend but costs more than twice as much in rewards.
- **Best offer:** discount_2_10_10d returns ~$9.8 of extra spend per $1 of reward: small reward, achievable threshold, long window, sent on all channels.
- **Informational messages alone added ~$50k** with no reward cost: a reminder without a discount still moves spend.
- **At an assumed 30–40% gross margin** (not in the data), an offer needs ≥$2.5–3.3 of incremental spend per reward dollar to pay for itself, so only the two $2-off-$10 discounts clearly clear the bar; BOGO and the $20-threshold discount likely lose money.

**Limitations (stated, not hidden)**
- Viewers may be more engaged customers to begin with; comparing each customer to their own baseline reduces but does not remove this selection bias. A randomised holdout would be needed for a causal estimate.
- Offer windows can overlap, so some spend is counted under more than one offer.
- BOGO reward cost is booked at face value; the real cost of a free drink is lower.

## Module 4: Which segments respond
**SQL:** `sql/04_segments.sql` (builds `segment_response`)
**Method:** the funnel and difference-in-differences metrics from Modules 2–3, cut by income, age, gender and membership tenure, separately for discount and BOGO offers.

**Discount offers by income**

| Income | View rate | Influenced rate | % completions wasted | Incremental $/day | Reward $ per influenced completion |
|---|---|---|---|---|---|
| <50k | 58.7% | 33.7% | 31.3% | $0.94 | $4.13 |
| 50–75k | 71.5% | 45.1% | 27.6% | $1.18 | $4.01 |
| **75–100k** | 77.7% | **52.8%** | 30.8% | **$2.28** | $4.33 |
| 100k+ | 62.1% | 43.1% | **45.0%** | $2.89 | $5.43 |
| unknown | 76.7% | 16.5% | 8.7% | $0.21 | $2.85 |

**Other cuts (discount / BOGO incremental $/day)**

| Segment | Discount | BOGO |
|---|---|---|
| Age 18–34 | $1.16 | $1.52 |
| Age 50+ | $1.67 | $1.71–1.80 |
| Women | $1.84 | $2.09 |
| Men | $1.23 | $1.47 |
| Joined 2018 (newest) | **$0.30** | **$0.25** |
| Joined 2016 | **$2.07** | **$3.13** |
| Unknown profile | $0.21 | $0.31 |

**Findings**
- **Response rises with income up to $100k.** The $75–100k band has the highest influenced rate (53%) and $2.28/day of extra spend on discounts.
- **$100k+ customers spend the most extra, but 45% of their discount completions are wasted**: they often hit the threshold without seeing the offer. Give them low-cost or informational nudges, not cash.
- **Newest members (joined 2018) barely respond** ($0.25–0.30/day). They haven't built the habit yet; onboarding messages fit better than rewards.
- **Customers with no profile data (12.8%) almost never respond** (7–17% influenced, ~$0.2–0.3/day). Likely inactive accounts: send them informational messages only.
- **Discounts cost ~$4 per influenced completion vs ~$10 for BOGO in every segment**, so the discount-over-BOGO conclusion holds across the board.

**Targeting recommendation**
| Segment | Action |
|---|---|
| $50–100k income, members since 2016–2017 | **$2-off-$10 discount, 10 days, all channels** (best ROI offer) |
| $100k+ | Informational / low-reward nudges; avoid high-threshold cash offers |
| Joined 2018 | Onboarding + informational; no cash rewards yet |
| Unknown profile | Informational only |
| Everyone | Stop the $5-off-$20 offer; move BOGO budget to discounts; keep a 10% randomised holdout to measure true lift |
