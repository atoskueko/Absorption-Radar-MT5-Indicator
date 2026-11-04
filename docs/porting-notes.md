# Porting notes — Pine Script v6 → MQL5

Reference: **Smart Money Absorption Radar \[Thomas\]** (Pine v6) → **AbsorptionRadar.mq5 v1.00**.

**Scope of this document.** These notes were written from the MQL5 source and from the original's published description and settings panel. The Pine source itself was **not** audited line by line when this file was written. Anything marked *Expected* is a claim about behaviour that should be checked against the Pine editor before the port is compared signal-for-signal with the original.

Legend: **Asserted** = verifiable in the MQL5 source alone. **Expected** = parity is likely but unproven.

---

## A. Logic — intentional, behaviour-preserving

| # | Pine | MT5 port | Effect | Status |
| --- | --- | --- | --- | --- |
| 1 | `barstate.isconfirmed` guard | The forming bar is never evaluated; state is committed once per closed bar | Signals do not repaint after the close | Asserted |
| 2 | `syminfo.mintick` | `_Point` | Same meaning | Asserted |
| 3 | `volume` on FX/CFD feeds (tick-based on most brokers) | `tick_volume[]`, with `real volume[]` selectable | Equivalent by default; see the real-volume warning in KNOWN_ISSUES #2 | Asserted / Expected |
| 4 | `ta.sma(volume, volLength)` | Own summation loop over `volLength` bars | Identical arithmetic once the window is full | Asserted |
| 5 | Relative volume test `volume >= avg * mult` | Same comparison, guarded by `avg > 0` | The port adds a zero guard; behaviour differs only on feeds with no volume at all | Asserted |
| 6 | Wick ratio and close position from candle geometry | Same definitions: wick ÷ range, `(close − low) ÷ range` | Identical | Asserted |
| 7 | Sweep = break of the previous `rangeLength` extreme, then close back inside | Own loop over bars `i-1 … i-rangeLength`, excluding the current bar | Same definition; the exclusion of the current bar is what makes it a sweep rather than a breakout | Expected |
| 8 | `cooldown` in bars since the last signal | `i - lastSignalBar > cooldown`, single shared counter | One cooldown for both directions, not per side | Expected |
| 9 | ATR-based stop, RR targets | Stop at `ATR(14) × targetATR`, targets at `risk × RR1/2/3` from entry at close | Same ladder; ATR length is hardcoded | Expected |
| 10 | Boxes extended right on the last bar | Rectangles redrawn on each new signal with `zoneExtension` bars | Latest-only in both; the port does not restack history | Asserted |
| 11 | EMA trend filter | `close > EMA` for longs, `close < EMA` for shorts, applied to the closed bar | Same direction test | Asserted |

## B. Logic — evaluated on the live bar in Pine, not in the port

| # | Pine | MT5 port | Effect |
| --- | --- | --- | --- |
| 12 | Dashboard cells reflect the current bar and can flip intrabar | Reflect the last **closed** bar | Calmer, one bar behind during a forming bar |
| 13 | EMA line drawn from the live tick | EMA line previewed on the forming bar, filter still uses the closed bar | The line can cross before the filter acknowledges it |

## C. Drawing

| # | Pine | MT5 port | Effect |
| --- | --- | --- | --- |
| 14 | `plotshape` for BUY / SELL and sweeps | Arrow buffers: `233` / `234` with ±14 shift, sweeps `225` / `226` with ±8 | Shapes differ; MT5 arrows carry no text |
| 15 | `box.new` with alpha fill | `OBJ_RECTANGLE` filled with a colour blended toward the chart background (`InpZoneTransp`, default 87) plus a 15 % border | Approximate; adapts to your theme via `CHART_COLOR_BACKGROUND` |
| 16 | `label.new` for price captions | `OBJ_TEXT` anchored left-lower so the text sits above its line | No bubble background or pointer |
| 17 | Dashboard `table`, 7 rows | Rectangle grid + `OBJ_LABEL` cells, fixed 244 px width, positioned **top-left** | Layout differs; content and colour coding match. The port adds a footer: "Port by AlgoToolbox.com" |
| 18 | `max_boxes_count` / `max_lines_count` | Keeps only the latest zones and levels, ~25 objects | Equivalent to what the Pine script effectively shows |
| 19 | Zone and dashboard colours | Green `0,150,120`, red `200,55,65`, aqua, orange, plus dashboard cell backgrounds | Near-identical on a dark chart |

## D. Inputs and alerts

| # | Pine | MT5 port | Effect |
| --- | --- | --- | --- |
| 20 | Visible numeric settings in the publication panel | 20 inputs carried over with the same defaults; names normalised to this port's convention | Defaults match; **names were not copied from the Pine source** because the source was not available when this file was written |
| 21 | Alert placeholders `{{ticker}}`, `{{interval}}`, `{{close}}` | Symbol, timeframe and close inserted directly; fire only on a bar that closed while attached | No alerts for historical bars |
| 22 | Display toggles | `DRAW_NONE` on the plot; the buffer keeps filling | Hiding a plot never removes the data |
| 23 | Optional sweep confirmation | `useSweepFilter` gates **signals only**; sweep arrows always draw when `showSweep` is on | Marker count is not a measure of filter quality |

## E. Present in the port, not in the Pine original

| # | Addition | Why |
| --- | --- | --- |
| 24 | Hidden buffers 5–9: Entry / SL / TP1 / TP2 / TP3 carried bar-by-bar | Lets an EA consume the plan through `iCustom` without reading chart objects |
| 25 | `InpVolumeSource` | MT5 exposes two volume arrays and only one of them is populated on FX/CFD; the choice has to be explicit |
| 26 | Input validation in `OnInit` | Stands in for Pine's `minval` / `maxval` |
| 27 | `InpZoneTransp` | Pine's box alpha has no direct MQL5 equivalent |
| 28 | Footer credit in the dashboard | Attribution travels with the chart, not just with the source file |

---

## Summary

The functional deviations that matter are **#5** (zero-volume guard), **#6/#9** (email-style seeding and a hardcoded ATR length), **#8** (shared cooldown) and **#12** (dashboard one bar behind). Everything else is presentation. Items **#7**, **#8** and **#9** carry the most risk of a visible signal difference, because each one changes *when a signal exists*, not merely how it looks.

## What is not claimed

- Bit-exact numerical parity with the Pine original on any dataset.
- That every Pine input exists here with the same name.
- Validation on every symbol, timeframe or broker feed.
- Any forward-tested or live-traded performance, since this is an analysis indicator that places no orders.
