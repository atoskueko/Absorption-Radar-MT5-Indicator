# Changelog

## 1.00 — 2026-11-04

Initial MT5 port of Smart Money Absorption Radar \[Thomas\] (Pine Script v6).

**Added**

- 10 buffers: EMA, Buy, Sell, BullSweep, BearSweep, Entry, SL, TP1, TP2, TP3.
- Hidden buffers 5–9 carrying entry, stop and the three targets bar-by-bar for EA use through `iCustom`.
- Buyer and seller absorption detection: lower / upper wick rejection, close-position test, and relative volume spike against a configurable average.
- Liquidity sweep detection against the highest high and lowest low of the preceding `rangeLength` bars.
- Optional EMA trend filter and optional sweep-confirmation filter, both off by default.
- Shared signal cooldown in bars.
- Latest bullish and bearish absorption zones as filled rectangles extended `zoneExtension` bars to the right.
- ATR-based auto targets: stop at `targetATR` × ATR(14), targets at 1R / 2R / 3R with `targetExtension` bar projection, drawn as trend lines with price labels.
- Seven-row radar dashboard: volume state, buyer pressure, seller pressure, market pressure, EMA trend, last event.
- Selectable volume source (tick volume default, real volume optional).
- Dashboard header reads `ABSORPTION RADAR` / `MT5`; the source carries no paid-tier label.
- 20 original Pine inputs carried over with the same defaults.
- Port-only inputs: `InpVolumeSource`, `InpZoneTransp`, alert toggles (`InpAlertSignals`, `InpAlertSweeps`, `InpAlertVolume`), `InpPush`, and the About group. The broker field is labelled as an affiliate link in the input description.
- Input validation in `OnInit` equivalent to Pine `minval` / `maxval`.

**Notes**

- All signal state is committed on closed bars only. The forming bar is never evaluated, so signals do not repaint after the close.
- Alerts fire only for bars that close while the indicator is attached.
- Known deviations are documented in [KNOWN_ISSUES.md](KNOWN_ISSUES.md) and [docs/porting-notes.md](docs/porting-notes.md).
