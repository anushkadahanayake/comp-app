# Arcade Frenzy — System Architecture & Features

Educational iOS arcade hub. This document helps anyone quickly understand **what the app does**, **how it is structured**, and **where to find code**.

---

## 1. What Is Arcade Frenzy?

| Item | Detail |
|------|--------|
| App name | Arcade Frenzy |
| Platform | iOS (SwiftUI) |
| Pattern | **MVVM** (Models · Views · ViewModels · Services) |
| Theme | Dark “Midnight Arcade” blue (`ArcadeTheme`) |
| Persistence | **Local only** (`UserDefaults`) — good for coursework / first app |

**Games**

1. [Tap Frenzy](games/tap-frenzy.md) — levels 1–7, bonus time, combos (starts 10s, max 20s)  
2. [Light It Up](games/light-it-up.md) — lit-card reflex + bonus-time gold cards  
3. [Quiz Rush](games/quiz-rush.md) — trivia campaign (Open Trivia DB)

---

## 2. High-Level Architecture

```text
comp_iosApp
    └── ContentView
            ├── LoginView          (if not signed in)
            └── Tab shell          (if signed in)
                    ├── Home       → pick & play games
                    ├── My Stats   → current player only
                    ├── Map        → session pins + GPS
                    └── Settings   → profile & preferences
```

```text
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│    Views    │────▶│  ViewModels  │────▶│   Models    │
│  (SwiftUI)  │     │ (game state) │     │ (entities)  │
└─────────────┘     └──────┬───────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Services   │
                    │ Auth, GPS,  │
                    │ Trivia, …   │
                    └─────────────┘
```

| Layer | Responsibility |
|-------|----------------|
| **Views** | UI, animations, user taps |
| **ViewModels** | Timers, scoring, campaign flow |
| **Models** | Game modes, sessions, player profile, theme |
| **Services** | Auth, location, trivia API, notifications, feedback |

---

## 3. Folder Map

```text
comp_ios/
├── comp_iosApp.swift          # App entry
├── Models/
│   ├── ArcadeTheme.swift      # Colors / surfaces
│   ├── GameCatalog.swift      # Home game cards
│   ├── GameState.swift        # GameMode, Card, Level, Question
│   ├── GameSession.swift      # Session + history manager
│   └── PlayerProfile.swift    # Local accounts
├── Views/
│   ├── ContentView.swift      # Auth gate + tabs
│   ├── LoginView.swift
│   ├── HomeView.swift
│   ├── TapFrenzyView.swift
│   ├── LightItUpView.swift
│   ├── QuizRushView.swift
│   ├── StatsView.swift
│   ├── GameMapView.swift
│   ├── SettingsView.swift
│   └── ArcadeTabBar.swift
├── ViewModels/
│   ├── GameViewModel.swift    # Tap Frenzy + Light It Up
│   └── QuizViewModel.swift
├── Services/
│   ├── AuthService.swift
│   ├── PlayerStatsStore.swift
│   ├── TriviaService.swift
│   ├── LocationService.swift
│   ├── LocationCoordinateBridge.h/.m
│   ├── NotificationService.swift
│   └── AppFeedback.swift
└── docs/                      # This documentation
```

---

## 4. Feature Guide

### 4.1 Login & Players

| Feature | Behavior |
|---------|----------|
| Sign Up | Username (≥3) + password (≥4), stored locally |
| Log In | Username + password (SHA256 hash check) |
| Guest | Nickname only (≥2); unique guest id; no password |
| Resume guest | Saved guests listed on login (kept **30 days** on device) |
| Upgrade guest | Settings → “Create Account & Keep Scores” — same player id, keeps records |
| Guest log out warning | Explains resume / risk of losing data if a new guest is created |
| Log Out | Clears session only; profiles stay on device |
| Isolation | Each player has own high scores & session history |

**Files:** `LoginView.swift`, `AuthService.swift`, `PlayerProfile.swift`, `SettingsView.swift`

### 4.2 Home

- Game carousel (auto-scroll, tap card or Play to open that game).
- Shows **current player** name and **that player’s** high scores.
- Navigation locks the chosen game so carousel cannot swap mid-play.

**File:** `HomeView.swift`

### 4.3 My Stats (per player)

Shows **only the signed-in player**:

- Profile / rank from total XP  
- Games played, total points, average, favorite mode  
- Personal bests (3 games)  
- Charts (recent runs per mode)  
- Recent games list  

**Not shown:** other players’ totals (global leaderboard removed from this screen).

**File:** `StatsView.swift`

### 4.4 Map

- Pins from finished games that have GPS coordinates.
- Marker color by game mode; detail card shows score + player name.
- Live user location when permission granted.
- Default map focus: **Sri Lanka** if GPS not ready (avoids US default).
- Banner if old pins look far from current GPS (e.g. Simulator).

**Files:** `GameMapView.swift`, `LocationService.swift`

### 4.5 Settings

| Setting | Effect |
|---------|--------|
| Display name | Rename current player |
| Round length | 30 / 60 / 90s → **Light It Up** only |
| Sound / Haptics | Game feedback |
| Daily reminder | Local notification time |
| Save location with scores | Attach GPS to sessions |
| Reset my scores | Clears **this player** only |
| Log out | Switch account |

**File:** `SettingsView.swift`

---

## 5. Data Flow (after a game ends)

```text
Game ends
   → ViewModel / View updates high score (PlayerStatsStore)
   → SessionHistoryManager.saveSession(...)
         • mode, score, time
         • playerId + playerName
         • optional latitude / longitude
   → UserDefaults JSON updated
   → Stats + Map read the same history
```

---

## 6. Persistence Keys (UserDefaults)

| Key | Purpose |
|-----|---------|
| `ArcadeKnownPlayers_v2` | All local accounts |
| `ArcadeCurrentPlayerId` | Who is signed in |
| `SavedGameSessions` | All game history (JSON) |
| `HighScore_<Mode>_<playerId>` | Per-player bests |
| `RoundDurationSetting` | 30 / 60 / 90 |
| `SoundEnabled` / `HapticsEnabled` | Feedback |
| `NotificationsEnabled` / `DailyChallengeTime` | Reminder |
| `SaveLocationWithSessions` | GPS on/off for saves |

---

## 7. External Dependencies

| Dependency | Use |
|------------|-----|
| Open Trivia DB | Quiz Rush questions (`https://opentdb.com`) |
| Core Location | GPS for map pins |
| MapKit | Map UI + `MKReverseGeocodingRequest` place names |
| UserNotifications | Daily play reminder |
| CryptoKit | Password hashing (SHA256) |

No Firebase / cloud backend — everything stays on the device.

---

## 8. Technical Notes

1. **Location bridge** — ObjC helpers (`LocationCoordinateBridge`) avoid Swift `CLLocationCoordinate2D` member issues on newer Xcode toolchains.
2. **Geocoding** — Uses MapKit `MKReverseGeocodingRequest` (not deprecated `CLGeocoder`).
3. **Default actor isolation** — Project uses MainActor isolation; UI and shared services stay on the main thread.
4. **Simulator GPS** — Defaults to Apple’s US location unless you set a Custom Location (e.g. Sri Lanka).

---

## 9. Quick “Where Do I Change X?”

| I want to… | Look here |
|------------|-----------|
| Change Tap Frenzy rules | `GameViewModel.swift` + `tap-frenzy.md` |
| Change Light It Up levels | `GameState.swift` (`Level`) + `GameViewModel.swift` |
| Change Quiz scoring / campaign | `QuizViewModel.swift` |
| Change trivia categories / API | `TriviaService.swift` |
| Change login rules | `AuthService.swift` |
| Change colors | `ArcadeTheme.swift` |
| Change tabs | `ContentView.swift`, `ArcadeTabBar.swift` |
| Change what Stats shows | `StatsView.swift` |

---

## 10. Game Docs Index

| Game | Document |
|------|----------|
| Tap Frenzy | [games/tap-frenzy.md](games/tap-frenzy.md) |
| Light It Up | [games/light-it-up.md](games/light-it-up.md) |
| Quiz Rush | [games/quiz-rush.md](games/quiz-rush.md) |

---

*Arcade Frenzy — educational first-app project documentation.*
