# NOTICE — attribution and licensing

## Original work

**Smart Money Absorption Radar \[Thomas\]**
Pine Script v6 · © Thomas-Sterling · Mozilla Public License 2.0

- Original publication: https://www.tradingview.com/script/7XJBJBZH-Smart-Money-Absorption-Radar-Thomas/
- The original author has not reviewed, approved or endorsed this MT5 port.
- The author distributes trading signals through Telegram. This repository is unrelated to that service, and nothing here should be read as an endorsement of it or by it.
- Trading ideas described in the original (volume absorption, rejection wicks, liquidity sweeps, EMA trend filtering, ATR-based trade levels) are not claimed as original to this port.

## MT5 adaptation

**AbsorptionRadar.mq5** — MT5 port and modifications
Copyright 2026 AlgoToolbox (atoskueko)
https://algotoolbox.com · https://t.me/algotoolbox

Changes made for MetaTrader 5, in summary:

- Re-implemented the Pine v6 script in MQL5 as a 10-buffer indicator with native drawing objects.
- Replaced Pine drawing primitives (`plotshape`, `box.new`, `line.new`, `label.new`, `table.new`) with MT5 arrow buffers, `OBJ_RECTANGLE`, `OBJ_TREND`, `OBJ_TEXT` and rectangle-based dashboard objects.
- Added a selectable volume source, because MT5 exposes both tick volume and real volume and only one of them is populated on FX/CFD feeds.
- Added hidden buffers 5–9 carrying Entry / SL / TP1 / TP2 / TP3 for Expert Advisor consumption.
- Added input validation in `OnInit` equivalent to Pine `minval` / `maxval`.
- Added port-only inputs: volume source, zone transparency, four alert toggles, push notifications, and an About group.
- All deviations from the original are itemised in `docs/porting-notes.md`.

The adaptation credit does not claim authorship of the original work, and does not imply endorsement by its author.

## Affiliate link disclosure

The About input group contains a `Recommended Broker` field pointing at an affiliate link owned by AlgoToolbox. It is a referral link, not a recommendation based on testing, and it has no effect on the indicator's logic. Nothing in this repository is paid placement for that broker or any other third party.

## Licence

This repository, including the port and its modifications, is distributed under the **Mozilla Public License 2.0**. The full text is in [LICENSE](LICENSE).

Under MPL-2.0:

- Covered source files, including this port, must remain available under MPL-2.0 when distributed.
- If you distribute a **compiled** `.ex5`, you must tell recipients how to obtain the corresponding covered source — for example, by linking to this repository and the release tag it was built from.
- Files you add and keep separate from covered source may be licensed differently, but the port itself cannot be relicensed.

## No warranty

Provided as-is, without warranty of any kind. This is an analysis indicator, not investment advice, and not an Expert Advisor. "Absorption" and "smart money" are descriptive names for candle-and-volume conditions, not evidence of institutional order flow. Past behaviour on historical data does not indicate future results. Trading leveraged products carries a high risk of loss.
