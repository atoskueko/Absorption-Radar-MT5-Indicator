# Buffers and `iCustom` usage

10 buffers. Values are written on the bar they describe and persist where noted.

| # | Name | Type | Persistence |
| --- | --- | --- | --- |
| 0 | EMA | Line | Every bar, including the forming bar |
| 1 | Buy | Signal | Arrow price on the signal bar only |
| 2 | Sell | Signal | Arrow price on the signal bar only |
| 3 | BullSweep | Event | Sweep low on the sweep bar only |
| 4 | BearSweep | Event | Sweep high on the sweep bar only |
| 5 | Entry | Level | Persists until the next signal; 0 before the first |
| 6 | SL | Level | Persists until the next signal; 0 before the first |
| 7 | TP1 | Level | Persists until the next signal; 0 before the first |
| 8 | TP2 | Level | Persists until the next signal; 0 before the first |
| 9 | TP3 | Level | Persists until the next signal; 0 before the first |

## Reading it from an EA

```mql5
int handle = iCustom(_Symbol, PERIOD_CURRENT, "AbsorptionRadar",
                     /* inputs in declaration order */);

double entry[1], sl[1], tp1[1], buy[1];
// shift 1 = last closed bar
CopyBuffer(handle, 5, 1, 1, entry);
CopyBuffer(handle, 6, 1, 1, sl);
CopyBuffer(handle, 7, 1, 1, tp1);
CopyBuffer(handle, 1, 1, 1, buy);

if(entry[0] > 0.0 && buy[0] > 0.0)
   PrintFormat("AR buy: entry %.2f  SL %.2f  TP1 %.2f", entry[0], sl[0], tp1[0]);
```

Notes:

- Buffers 1–4 are event markers, not levels. A non-zero value on shift 1 means it happened on that closed bar.
- Buffers 5–9 are only meaningful together — one active plan at a time, replaced by the next signal in either direction.
- **Levels are carried, not cleared.** After a signal, buffers 5–9 keep the same values on every following bar until the next signal. Test for a fresh plan with buffer 1 or 2, not with buffer 5.
- `0` in buffers 5–9 means "no signal yet", not a price of zero.
- `iCustom` argument order must match the input declaration order in the source. The 30 inputs are listed in [inputs.md](inputs.md) in that order. If you change the input list in your own build, your EA has to change with it.
- Hiding a plot (`showEMA`, `showSignals`, `showSweep` off) does **not** stop the buffer from filling. Display toggles are cosmetic.
