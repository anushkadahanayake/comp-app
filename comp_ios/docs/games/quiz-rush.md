# Quiz Rush

Trivia campaign using the Open Trivia Database API. Clear Easy → Medium → Hard with lives and a question timer.

---

## Goal

Answer multiple-choice questions correctly before time or lives run out. Finish all three campaign stages for a completion bonus.

---

## How a Run Works

1. Player picks a **category** (or Any Category).
2. Campaign starts on **Easy**.
3. Questions load from Open Trivia DB (`TriviaService`).
4. Each question has a countdown timer.
5. Clear the stage → short continue screen → next difficulty.
6. Run ends on **campaign complete** or **0 lives**.

---

## Campaign Stages

| Stage | API difficulty | Questions | Base time / question |
|-------|----------------|----------|----------------------|
| Easy | `easy` | 5 | 20s |
| Medium | `medium` | 6 | 16s |
| Hard | `hard` | 7 | 13s |

---

## Lives

- Start with **3** lives.
- Wrong answer or timeout → **−1** life.
- Clear a stage → lives = `min(5, lives + 1)`.
- At **0** lives → game over.

---

## Scoring & Time Bonuses (correct answer)

| Rule | Effect |
|------|--------|
| Base points | `2 + (streak − 1)` (streak grows on consecutive correct) |
| Answer ≤ 5s | **+3** pts and **+4s** time |
| Answer ≤ 10s | **+1** pt and **+2s** time |
| Always on correct | **+2s** time |
| Streak ≥ 3 | Extra **+2s** |
| Time bank cap | **40s** max on the timer |
| Carry to next question | Base stage time + a bit of leftover time |

### Wrong / timeout

| Event | Effect |
|-------|--------|
| Wrong | −1 life, −1 score (floor 0), −2s |
| Timeout | −1 life; correct answer is shown |

### Stage / campaign bonuses

| Event | Effect |
|-------|--------|
| Stage clear | **+5** pts, +1 life (cap 5) |
| Full campaign done | **+10** pts, then end |

---

## Categories (Open Trivia DB)

- Any Category  
- General Knowledge (9)  
- Video Games (15)  
- Science & Nature (17)  
- Science: Computers (18)  
- Sports (21)  
- History (23)

---

## Network Behavior

- Endpoint: `https://opentdb.com/api.php`
- Retries (up to 3) when rate-limited (HTTP 429 / API code 5).
- If a difficulty/category has no questions, the service softens filters and retries.
- HTML entities in question text are decoded for display.

---

## What Is Saved After Play

- Mode: `"Quiz Rush"`
- Final score
- Timestamp
- Optional GPS
- Current `playerId` + player name

High score key pattern: `HighScore_QuizRush_<playerId>`

---

## Main Files

| Role | File |
|------|------|
| UI | `Views/QuizRushView.swift` |
| Logic | `ViewModels/QuizViewModel.swift` |
| API | `Services/TriviaService.swift` |
| Models | `Models/GameState.swift` (`Question`, campaign helpers) |

---

## Player Tips

- Answer fast for speed bonuses and extra time.
- Keep a streak for higher points and bonus seconds.
- If loading fails, wait a moment and retry (API rate limits).
