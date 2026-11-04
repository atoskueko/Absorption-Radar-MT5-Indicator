# Inputs — v1.00

30 inputs. 20 are carried over from the Pine v6 original with the same defaults; port-only inputs are marked **(added)**.

## 00 — About (added)

| Input | Default | Purpose |
| --- | --- | --- |
| `InpAbout` | Port by AlgoToolbox.com - original by Thomas-Sterling (MPL-2.0) | Credit line |
| `InpInfoTelegram` | https://t.me/algotoolbox | Support channel |
| `InpInfoHomepage` | https://algotoolbox.com | Project page |
| `InpInfoBroker` | affiliate link | Contextual link; **affiliate**, disclosed in NOTICE.md |

## 01 — Absorption Engine

| Input | Default | Purpose |
| --- | --- | --- |
| `InpVolumeSource` **(added)** | `SAR_TICK_VOLUME` | Tick volume or real volume. On FX/CFD feeds real volume is usually empty and the indicator then never signals |
| `volLength` | 20 | Bars in the volume average |
| `volMultiplier` | 1.5 | A bar counts as a spike at `volume >= average × multiplier` |
| `wickRatio` | 0.40 | Minimum rejection wick as a fraction of candle range |
| `rangeLength` | 20 | Lookback for the previous range high / low used by sweep detection |

## 02 — Signal Filters

| Input | Default | Purpose |
| --- | --- | --- |
| `useTrendFilter` | false | Require close above / below the EMA before a signal is drawn |
| `emaLength` | 200 | EMA length used by the trend filter and the dashboard |
| `useSweepFilter` | false | Require a liquidity sweep on the same bar as the absorption candle |
| `cooldown` | 8 | Minimum bars between signals, **shared across both directions** |

## 03 — Chart Visuals

| Input | Default | Purpose |
| --- | --- | --- |
| `showZones` | true | Draw the latest bull / bear absorption zone rectangles |
| `showSweep` | true | Draw sweep arrows |
| `showEMA` | false | Draw the EMA line (buffer keeps filling either way) |
| `showSignals` | true | Draw BUY / SELL arrows (buffers keep filling either way) |
| `zoneExtension` | 20 | Bars each zone extends to the right |
| `InpZoneTransp` **(added)** | 87 | Zone fill transparency, 0–100, blended toward the chart background |

## 04 — Auto Targets

| Input | Default | Purpose |
| --- | --- | --- |
| `showTargets` | true | Draw Entry / SL / TP lines |
| `targetATR` | 1.5 | Stop distance as a multiple of ATR(14) |
| `targetRR1` | 1.0 | TP1 risk:reward |
| `targetRR2` | 2.0 | TP2 risk:reward |
| `targetRR3` | 3.0 | TP3 risk:reward |
| `targetExtension` | 20 | Bars the target lines project to the right |

## 05 — Radar Dashboard

| Input | Default | Purpose |
| --- | --- | --- |
| `showDashboard` | true | Show the seven-row panel, top-left |

## 06 — Alerts (closed bar) **(added)**

| Input | Default | Purpose |
| --- | --- | --- |
| `InpAlertSignals` | false | Buyer / seller absorption alerts |
| `InpAlertSweeps` | false | Liquidity sweep alerts |
| `InpAlertVolume` | false | Volume spike alerts |
| `InpPush` | false | Also send push notifications |

Alerts fire only on a bar that closes while the indicator is attached. Historical bars never alert. If an input is set outside a sane range, `OnInit` rejects it and explains why in the Experts log.
