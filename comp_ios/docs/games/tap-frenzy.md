# Tap Frenzy

Fast 10-second tap challenge. Score as many points as you can before time runs out.

---

## Goal

Tap the moving target as quickly as possible within **10 seconds**. Build a combo multiplier, use bonus windows, and avoid penalty taps.

---

## How a Round Works

1. Player taps **Play** on Home → Tap Frenzy screen opens.
2. Round starts with a **10.0s** timer (fixed — Settings round length does **not** change this).
3. The target button moves, changes mode (normal / bonus / penalty), and can shrink as time runs out.
4. When time hits `0`, the round ends.
5. Score is saved to the **current player’s** history and high-score record.

---

## Scoring Rules

| Situation | Effect |
|-----------|--------|
| Normal tap (combo) | Points = current **multiplier** |
| Combo keep | Next tap within **0.5s** → multiplier +1 |
| Combo break | Gap > 0.5s → multiplier resets to **1** |
| Bonus mode (green) | Extra **+1** on top of multiplier points |
| Penalty mode (gray) | Score **−5** (not below 0), multiplier → 1 |
| Double points active | Earned points for that tap are **×2** |

---

## Special Mechanics

### Mode cycle (every 3 seconds)
`normal → bonus → penalty → normal …`

### Movement (every 2 seconds)
Target jumps to a random offset (clamped on screen).

### Double points
- Fires once at a random time between **2–8s**
- Stays active for **2s**

### Shrink
Button scale shrinks as time decreases (down toward about **40%** size).

---

## What Is Saved After Play

- Mode: `"Tap Frenzy"`
- Final score
- Timestamp
- Optional GPS (if location save is on)
- Current `playerId` + player name

High score key pattern: `HighScore_TapFrenzy_<playerId>`

---

## Main Files

| Role | File |
|------|------|
| UI | `Views/TapFrenzyView.swift` |
| Logic | `ViewModels/GameViewModel.swift` (`GameMode.tapFrenzy`) |
| Catalog card | `Models/GameCatalog.swift` |

---

## Player Tips

- Keep tapping quickly to grow the multiplier.
- Watch for **green** (bonus) and avoid **gray** (penalty).
- When double-points flashes, spam taps while it lasts.
