# Light It Up

Reflex grid game. Tap only the lit cards. Misses and timeouts cost lives. From Level 3, chase the **gold clock** card for extra time.

---

## Goal

Survive the round by tapping **lit** cards and avoiding **dim** ones. Score rises with every correct tap. Levels get harder as time passes. Grab **bonus-time** cards to stay in the round longer.

---

## How a Round Works

1. Player starts Light It Up from Home.
2. Round length comes from Settings: **30 / 60 / 90** seconds (default **60**).
3. Player starts with **3 lives**.
4. Random cards light up; player must tap them before they expire.
5. From **Level 3**, **two** cards light at once: one normal + one **bonus-time** (gold clock).
6. Round ends when **time runs out** or **lives reach 0**.
7. Score is saved for the **current player** only.

---

## Scoring & Lives

| Event | Effect |
|-------|--------|
| Tap a normal lit card | **+1** score; that card clears |
| Tap a **bonus-time** lit card (gold clock) | **+2** score + **+3 seconds** |
| Tap a dim card | **−1** life |
| Lit cards expire without being cleared | **−1** life |
| All lit cards cleared | New set of lit cards appears immediately |

Bonus time is capped at **round length + 20s** so rounds cannot grow forever.

---

## Bonus-time cards

- Appear whenever **2 cards** light together (Level 3 & 4).
- Exactly **one** of the two is bonus-time; the other is a normal lit card.
- Look: yellow–orange glow with a **clock** icon.
- Banner shows `+3s TIME!` when collected.

---

## Levels (by round progress)

Levels advance based on how much of the round time has elapsed:

| Progress | Level | Cards | Lit window | Lit at once |
|----------|-------|-------|------------|-------------|
| 0–25% | Level 1 | 3 | 1.5s | 1 |
| 25–50% | Level 2 | 4 | 1.2s | 1 |
| 50–75% | Level 3 | 6 | 1.0s | **2** (1 normal + 1 bonus) |
| 75–100% | Level 4 | 9 | 0.8s | **2** (1 normal + 1 bonus) |

A short **level-up banner** appears when the level changes.

---

## What Settings Affect

- **Round Length** in Settings changes Light It Up duration and when level thresholds hit.
- Sound / haptics use the global feedback toggles.

---

## What Is Saved After Play

- Mode: `"Light It Up"`
- Final score
- Timestamp
- Optional GPS
- Current `playerId` + player name

High score key pattern: `HighScore_LightItUp_<playerId>`

---

## Main Files

| Role | File |
|------|------|
| UI | `Views/LightItUpView.swift` |
| Logic | `ViewModels/GameViewModel.swift` (`GameMode.lightItUp`) |
| Level / card models | `Models/GameState.swift` (`Level`, `Card`) |

---

## Player Tips

- Only tap glowing cards.
- Prioritize the **gold clock** when two cards light — you get points and +3s.
- Still clear the normal lit card before both expire, or you lose a life.
- Longer rounds (90s) give more time to reach Level 3+ bonus waves.
