# Memo: Which rewards were worth paying for?

**To:** CRM / Loyalty team · **From:** Bhavya Mohnot · **Data:** Starbucks Rewards app simulation: 17,000 customers, 10 offers, 76,277 offers sent, 30 days

## 1. What happened
- **$164.7k was paid out in rewards** across 61k BOGO and discount offers.
- **30% of it ($49.4k) went to customers who completed the offer without ever viewing it.** They would have spent the money anyway, so the reward bought nothing.
- Measured against each customer's own baseline, and against recipients who never viewed the offer, **discounts generated $4.08 of extra spend per $1 of reward; BOGO generated $1.92.**
- **Informational messages (no reward) added ~$50k of extra spend** at zero reward cost.

## 2. Why it matters
- **The headline completion rate overstates performance.** Completion counts every customer who hit the spend threshold, including people who never saw the offer. For a cashback programme like CLiQ Cash, this is pure leakage.
- **Hard thresholds reward existing big spenders.** The "$5 off $20" offer had only a 35% view rate and **61% of its completions were wasted**; it returned $1.42 per reward dollar, the worst of all offers.
- **Reach drives efficiency.** The four offers sent without social/mobile reach were viewed by 35–54% of customers vs 81–96% for the others, and carried most of the waste (channels are bundled per offer, so this is a strong pattern, not a proven channel effect).
- **Response depends on who receives the offer.** Customers earning $75–100k and members of 1–2 years respond best (≈53% influenced, $2+/day extra spend). $100k+ customers spend more but **45% of their discount completions are wasted**. New members (joined 2018) and customers without profile data barely respond.

## 3. What to do next
1. **Move budget from BOGO to discounts**, led by "$2 off $10, 10 days, all channels" (≈$9.8 extra spend per reward dollar).
2. **Retire the "$5 off $20" offer**, or restrict it to customers whose normal spend is well below $20.
3. **Pay rewards only after a view.** Require the offer to be opened/activated in the app before the cashback is earned; this alone removes the 30% leakage.
4. **Target by segment:** cash offers for the $50–100k, 1–2-year-tenure middle; informational nudges for $100k+ customers and profile-less accounts; onboarding journeys (not cash) for new members.
5. **Run a randomised holdout (10%)** on the next campaign. This analysis is observational, so a holdout is needed to confirm true incremental lift before scaling.

*SQL and method: https://github.com/bhavyamohnot/starbucks-offer-evaluation · Dashboard: https://docs.google.com/spreadsheets/d/1u8Cxzp9UZckH8TFnugbVR53qthWQaBC6Ei03_UrN2CQ/edit?usp=sharing*
