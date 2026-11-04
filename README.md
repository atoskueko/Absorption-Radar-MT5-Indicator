# Absorption Radar MT5 Indicator

MQL5 port of **Smart Money Absorption Radar \[Thomas\]** (Pine Script v6): volume-spike + rejection-wick absorption candles, buyer / seller absorption zones, optional liquidity-sweep and EMA-trend filters, a signal cooldown, ATR-based Entry / SL / TP1–TP3 auto targets, and a seven-row radar dashboard.

![Absorption Radar MT5 on XAUUSD M30](docs/images/absorption-radar-xauusd-m30.png)

## Primary project page

**Full documentation, settings, chart examples, and evaluation:**

### [Absorption Radar MT5 Port on AlgoToolbox](https://algotoolbox.com/products/absorption-radar-mt5/)

AlgoToolbox is the primary home for this MT5 project's documentation — settings, chart examples, and evaluation. This repository is the secondary **source** repository, not the manual.

## Source snapshot

- **Platform:** MetaTrader 5 desktop.
- **Version:** `1.00`, as declared in `AbsorptionRadar.mq5`.
- **MT5 adaptation:** AlgoToolbox (atoskueko).
- **License:** [MPL-2.0](LICENSE).
- **Original:** Smart Money Absorption Radar \[Thomas\], Pine Script v6, © Thomas-Sterling.

This is a **source snapshot**, not a validated binary release. No `.ex5` is included. Exact-source compilation, terminal validation and matched-data parity against the Pine original have not been established for this package. Read [KNOWN_ISSUES.md](KNOWN_ISSUES.md) before relying on its outputs.

## Compile and attach

1. Put `src/AbsorptionRadar.mq5` in your terminal's `MQL5/Indicators/` folder. Keep the filename — an EA calling it through `iCustom` needs the name exactly.
2. Open it in MetaEditor, press **F7**, and review errors and warnings.
3. After a clean compile, refresh the Navigator and attach the indicator to a chart with sufficient history.
4. Start with the defaults on a dark chart, one copy per chart. Alerts are off by default.

The indicator does **not** place, modify or close broker orders, and it does not size positions. Entry / SL / TP levels are reference lines drawn on the chart. The Algo Trading switch is not required for its analysis.

## Volume source — read this first

MT5 has no universal real-volume feed for FX and CFD symbols. `InpVolumeSource` defaults to **tick volume**, which is what the Pine original is effectively reading on most OANDA-style gold feeds as well.

If you switch it to `SAR_REAL_VOLUME` on a symbol whose broker reports no real volume, the average is zero, the spike test never passes, and **the indicator produces no signals at all** — silently, with no error. Leave it on tick volume unless you have confirmed your symbol publishes real volume.

## Buffers (for EA use via `iCustom`)

| # | Buffer | Meaning |
| --- | --- | --- |
| 0 | `EMA` | Trend EMA line value |
| 1 | `Buy` | Buyer absorption BUY signal (arrow on bar) |
| 2 | `Sell` | Seller absorption SELL signal (arrow on bar) |
| 3 | `BullSweep` | Bullish liquidity sweep (below previous range low) |
| 4 | `BearSweep` | Bearish liquidity sweep (above previous range high) |
| 5 | `Entry` | Active signal entry level |
| 6 | `SL` | Active signal stop level |
| 7 | `TP1` | 1R target |
| 8 | `TP2` | 2R target |
| 9 | `TP3` | 3R target |

Levels persist until the next signal and are `0` before the first one. Full map and an `iCustom` example: [docs/buffers.md](docs/buffers.md).

## Inputs

30 inputs: 20 carried over from the Pine original with equivalent names and the same defaults, plus port-only additions (volume-source selector, zone transparency, four alert toggles, push notifications, and an About group). Full table: [docs/inputs.md](docs/inputs.md).

## Differences from the Pine original

Nothing from the original was dropped. The functional deviations are the EMA/ATR seeding, the shared signal cooldown, hardcoded rejection thresholds, and two live-bar display behaviours. Read the itemised table with effects and caveats: [docs/porting-notes.md](docs/porting-notes.md).

## Origin and license

**Original work:** [Smart Money Absorption Radar \[Thomas\]](https://www.tradingview.com/script/7XJBJBZH-Smart-Money-Absorption-Radar-Thomas/), © Thomas-Sterling, MPL-2.0.

The AlgoToolbox page is the primary **MT5 project guide**, not the original work's publication. Original authorship is retained; no endorsement by the original author is implied. The original author publishes trading signals on Telegram — that has nothing to do with this repository, and no affiliation is claimed. Attribution detail: [NOTICE.md](NOTICE.md).

Covered source and modifications remain under MPL-2.0. If you distribute a compiled port, tell recipients how to obtain the corresponding covered source.
