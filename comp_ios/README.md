# Arcade Frenzy 🎮

Educational iOS arcade hub with three games, local player accounts, personal stats, and a map of play locations.

---

## Documentation

| Document | Description |
|----------|-------------|
| [System Architecture & Features](docs/SYSTEM_ARCHITECTURE_AND_FEATURES.md) | Full app structure, features, data flow, file map |
| [Deep Coverage Score](docs/DEEP_COVERAGE_SCORE.md) | Score by skill area — what you covered and gaps |
| [Top Marks / AI Evaluation Guide](docs/TOP_MARKS_AI_EVALUATION_GUIDE.md) | What AI markers look for + how to hit top marks |
| [Tap Frenzy](docs/games/tap-frenzy.md) | 10s tap challenge rules & scoring |
| [Light It Up](docs/games/light-it-up.md) | Lit-card reflex game & levels |
| [Quiz Rush](docs/games/quiz-rush.md) | Trivia campaign & API behavior |

---

## Quick start

1. Open `comp_ios.xcodeproj` in Xcode.
2. Select a simulator or device → Run.
3. **Sign Up**, **Log In**, or **Continue as Guest**.
4. Play from **Home**; check **My Stats** and **Map**.

---

## Architecture (short)

**MVVM** — Views (SwiftUI) · ViewModels (game logic) · Models (entities) · Services (auth, GPS, trivia, notifications).

```
Login → Home / Stats / Map / Settings
              ↓
         Tap Frenzy · Light It Up · Quiz Rush
```

Details: [docs/SYSTEM_ARCHITECTURE_AND_FEATURES.md](docs/SYSTEM_ARCHITECTURE_AND_FEATURES.md)

---

## Features (short)

- Local accounts (username/password) + guest nickname
- Per-player scores, stats, and session history
- Map pins with optional GPS
- Settings: round length, sound, haptics, daily reminder
- Quiz questions from Open Trivia DB

---

## Project layout

```
Models/       Theme, catalog, sessions, player profile
Views/        Screens + custom tab bar
ViewModels/   Tap/Light + Quiz logic
Services/     Auth, stats, location, trivia, notifications
docs/         Architecture + per-game guides
```

---

## Notes

- Data is stored **on device only** (`UserDefaults`).
- Stats show the **signed-in player only**.
- Simulator GPS often defaults to the US — set **Features → Location → Custom Location** for Sri Lanka testing.
- Open Trivia DB may rate-limit; Quiz Rush retries and shows a retry UI when needed.
