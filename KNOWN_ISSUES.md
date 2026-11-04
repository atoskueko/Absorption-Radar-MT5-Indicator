# Known issues and limitations — v1.00

Read before relying on this port. These are differences a user can actually observe, not a list of theoretical concerns.

## 1. The package is unvalidated

No `.ex5` is shipped. This repository is a source snapshot: exact-source compilation, terminal validation and matched-data parity against the Pine original have **not** been established for this release. Compile it yourself and inspect the output before using it.

## 2. Real volume can silence the indicator without an error

`InpVolumeSource` defaults to tick volume. If you set it to `SAR_REAL_VOLUME` on a symbol where the broker reports no real volume, the volume average is `0`, `validVolume` fails, no spike is ever detected, and **no signal will ever fire**. Nothing is printed to the log. This is the single most likely way to conclude the port is broken when it is working exactly as written.

## 3. EMA seeding differs during warm-up

The port seeds its EMA from the first close of available history. Pine's `ta.ema` warms up differently. The two lines converge, but early history differs, so the EMA filter can disagree with the original near the left edge of the chart. After roughly 3–5× `emaLength` bars the difference is below display precision. The EMA **line** is previewed on the forming bar and therefore moves intrabar, like any moving average.

## 4. ATR period is fixed at 14

The auto-target stop distance uses ATR(14) with an RMA calculation, and **14 is not an input**. If the original exposes an ATR length — the settings panel suggests the visible numeric inputs are volume length, multiplier, wick ratio, lookback, EMA length, cooldown, zone extension, ATR multiplier and the three risk:rewards — then this port hard-codes a value Pine lets you change. Check before comparing stop distances.

## 5. Rejection thresholds are hard-coded

The close-position test is fixed in the source at `>= 0.60` for a bullish rejection and `<= 0.40` for a bearish one, alongside the `wickRatio` input. If the original exposes the close-position filter as an input, this port does not. Two symbols that produce identical wicks can therefore signal differently here than in Pine if the original's thresholds are configurable and were changed.

## 6. Zone boxes may be narrower than the original's

The BUY zone spans `max(open, close)` down to `low`; the SELL zone spans `high` down to `min(open, close)`. That is the body-to-wick-extreme convention. If the original's `box.new` calls use wick-to-wick bounds, every zone drawn here is shorter by the opposite wick. Compare one zone against the same bar in Pine before publishing screenshots.

## 7. The cooldown is shared between directions

`cooldown` counts bars since **the last signal of either direction**, not since the last signal of the same direction. A BUY therefore suppresses a SELL for the same number of bars. This matches the single `lastSignalBar` variable the original uses, as far as the port's reading of it goes — confirm if you are matching signals one-for-one.

## 8. Dashboard shows closed-bar state, not live-bar state

Pine prints the current bar's values, which can flip intrabar. This port prints the last **closed** bar. The dashboard is calmer and one bar behind Pine while a bar is forming.

This produces one apparently contradictory read: **Buy / Sell Pressure can show `NOT DETECTED` while Last Event still says `BUYER ABSORPTION` or `SELLER ABSORPTION`.** Both cells are correct. The pressure cells describe the most recent closed bar; Last Event remembers the most recent *signal*, which may be many bars older. It is a memory, not a live state. The same applies to the volume cell.

## 9. Sweep markers ignore the sweep filter

`useSweepFilter` gates **signals**, not markers. Sweep arrows appear on every qualifying sweep whether or not the filter is on. If you are counting sweeps to judge signal quality, you are counting all of them.

## 10. Arrow text is lost

MT5 arrows cannot carry text. Pine's BUY / SELL shapes become arrows `233` / `234` with the caption omitted, and sweeps become triangles `225` / `226`. Read direction from the buffer, not from a caption on the chart.

## 11. Levels are carried, not cleared

Buffers 5–9 keep the most recent Entry / SL / TP1–TP3 after the signal bar, and hold `0` before the first signal ever fires. Any EA reading them must treat `0` as "no plan yet" rather than a price level of zero.

## 12. Object economy and redraw

Only the latest bull zone, bear zone and target set are kept — roughly 25 objects at steady state. Changing timeframe or symbol triggers a full recalculation that deletes and redraws them, which is visible as a brief flicker. This is intentional, not a bug.

## 13. Alerts only fire on a bar that closes while the indicator is live

There are no alerts for historical bars. Attaching the indicator to a chart with years of history will not produce a burst of notifications.

## 14. Zone transparency is approximate

Pine's `box.new` alpha is replaced by blending toward the chart background colour, read from `CHART_COLOR_BACKGROUND`, with `InpZoneTransp` (default 87, against Pine's 85/86) and a 15 % border. It adapts to your chart theme, but it will not match Pine pixel-for-pixel on any theme.

## 15. `#property strict` is an MQL4 carry-over

It is ignored by the MQL5 compiler and may produce a warning. Harmless; harmless is not the same as tidy.

## 16. Zone and price labels can overlap

Absorption zone captions are anchored at the left edge of the box, and ENTRY / SL / TP captions are anchored at the right end of their rays. When a zone and a target line sit at similar prices, the captions can overlap — visible in `docs/images/absorption-radar-xauusd-m30.png`, where the `SELLER ABSORPTION` caption crosses the `ENTRY` line. Cosmetic only; nothing about the levels changes. Pick a different chart window if you need a clean marketing capture.

## 17. Not tested on every symbol or timeframe

Behaviour was reasoned from the Pine source, not audited across every market. Gold and BTC on H1 are the intended targets. Coarse-tick, low-liquidity and weekend-gap-prone symbols are the first places to look if the output surprises you.
