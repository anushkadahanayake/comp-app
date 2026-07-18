# Tap Frenzy

Fast tap challenge with **levels**, **bonus time**, and combos. Score as many points as you can before time runs out.

---

## Goal

Tap the moving target quickly. Build a combo multiplier, grab green bonus windows, avoid gray penalties, **level up as your score climbs**, and **earn extra time** to stay in the round longer.

---

## How a Round Works

1. Player taps **Play** on Home → Tap Frenzy opens.
2. Round starts with **10.0s** on the clock (can grow with bonuses, hard cap **20s**).
3. You begin at **Level 1**. Hitting score thresholds raises the level and makes the target harder.
4. Green taps and early combo milestones add time; a floating banner shows `+Xs` / `LEVEL N!`.
5. From **Level 5**, the clock drains a bit faster so bonus time cannot keep a round alive forever.
6. When time hits `0`, the round ends.
7. Score is saved for the **current player** (history + high score). Leaderboard is available in-game (trophy, top right).

---

## Levels (score thresholds)

| Level | Score needed | What changes |
|------:|--------------|--------------|
| 1 | 0 (start) | Base speed |
| 2 | **40** | Faster moves / mode swaps, +1s |
| 3 | **100** | Harder again, +1s |
| 4 | **180** | Harder again, +1s |
| 5 | **280** | Faster drain begins, +1s |
| 6 | **400** | Harder again, +1s |
| 7 | **550** | Max in-round level, +1s |

On each level-up: short **LEVEL N!** banner, **+1 second**, target moves farther/faster. Levels 6–7 keep scaling after the old Level 5 plateau.

---

## Bonus time (stay longer)

| Action | Extra time |
|--------|------------|
| Tap while **green (bonus)** | **+0.5s** |
| Combo milestones **×3, ×5, ×7** only | **+0.4s** each |
| **Level up** | **+1.0s** |
| Hard cap | Time cannot go above **20s** |

Long combos past ×7 still score big — they just no longer refill the clock.

---

## Scoring Rules

| Situation | Effect |
|-----------|--------|
| Normal tap (combo) | Points = current **multiplier** |
| Combo keep | Next tap within **0.5s** → multiplier +1 |
| Combo break | Gap > 0.5s → multiplier resets to **1** |
| Bonus mode (green) | Extra **+1** points + time bonus |
| Penalty mode (gray) | Score **−5** (not below 0), multiplier → 1 |
| Double points active | Earned points for that tap are **×2** |

---

## Other Mechanics

### Mode cycle
`normal → bonus → penalty → normal …`  
Interval shortens as level rises (down to ~0.9s at Level 7).

### Movement
Target jumps on a timer; interval shortens (down to ~0.55s) and jump range grows with level.

### Double points
- Fires once per round (random ~2–8s)
- Active for **2s**

### Shrink
Button shrinks as time runs low; minimum size is smaller at higher levels.

### Late-game drain
From Level 5 upward, each timer tick removes slightly more than 0.05s so high-level rounds still end.

---

## What Is Saved After Play

- Mode: `"Tap Frenzy"`
- Final score
- Timestamp
- Optional GPS
- Current `playerId` + player name

High score key: `HighScore_TapFrenzy_<playerId>`

---

## Main Files

| Role | File |
|------|------|
| UI | `Views/TapFrenzyView.swift` |
| Logic | `ViewModels/GameViewModel.swift` (`GameMode.tapFrenzy`) |
| In-game leaders | `Views/GameModeLeaderboardView.swift` |
| Catalog card | `Models/GameCatalog.swift` |

---

## Player Tips

- Keep the combo alive for points; grab time only at **×3 / ×5 / ×7** and on **green**.
- Push toward 280 / 400 / 550 for Levels 5–7 — expect a faster, farther target and a hungrier clock.
- Avoid **gray** — it hurts score and breaks your combo.
