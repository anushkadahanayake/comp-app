# Tap Frenzy

Fast tap challenge with **levels**, **bonus time**, and combos. Score as many points as you can before time runs out.

---

## Goal

Tap the moving target quickly. Build a combo multiplier, grab green bonus windows, avoid gray penalties, **level up as your score climbs**, and **earn extra time** to stay in the round longer.

---

## How a Round Works

1. Player taps **Play** on Home → Tap Frenzy opens.
2. Round starts with **10.0s** on the clock (can grow with bonuses, hard cap **25s**).
3. You begin at **Level 1**. Hitting score thresholds raises the level and makes the target harder.
4. Green taps and combo milestones add time; a floating banner shows `+Xs` / `LEVEL N!`.
5. When time hits `0`, the round ends.
6. Score is saved for the **current player** (history + high score). Leaderboard is available in-game (trophy).

---

## Levels (score thresholds)

| Level | Score needed | What changes |
|------:|--------------|--------------|
| 1 | 0 (start) | Base speed |
| 2 | **25** | Faster moves / mode swaps, +2s |
| 3 | **50** | Harder again, +2s |
| 4 | **80** | Harder again, +2s |
| 5 | **120** | Max in-round level, +2s |

On each level-up: short **LEVEL N!** banner, **+2 seconds**, target moves farther/faster.

---

## Bonus time (stay longer)

| Action | Extra time |
|--------|------------|
| Tap while **green (bonus)** | **+1.0s** |
| Combo milestones **×3, ×5, ×7…** | **+0.8s** each |
| **Level up** | **+2.0s** |
| Hard cap | Time cannot go above **25s** |

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
Interval shortens as level rises.

### Movement
Target jumps on a timer; interval shortens and jump range grows with level.

### Double points
- Fires once per round (random ~2–8s)
- Active for **2s**

### Shrink
Button shrinks as time runs low; minimum size is smaller at higher levels.

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

- Keep the combo alive for points **and** time boosts at odd multipliers (×3, ×5…).
- Hunt **green** windows for +1s and +1 point.
- Push past 25 / 50 / 80 / 120 to level up and grab +2s — but expect a faster target.
- Avoid **gray** — it hurts score and breaks your combo.
