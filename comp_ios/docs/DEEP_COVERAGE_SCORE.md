# Arcade Frenzy — Deep Coverage Score Report

Assessment of what your application covers **right now**, by learning / coursework area.  
Scoring is for an **educational first iOS app** (not App Store production).

**Scale:** `0–10` per area · **Overall** = average of all areas.

| Score | Meaning |
|------:|---------|
| 9–10 | Strong, demo-ready for this level |
| 7–8 | Solid coverage, small gaps OK |
| 5–6 | Present but basic / incomplete |
| 3–4 | Thin or only partially done |
| 0–2 | Missing or barely touched |

---

## Overall Snapshot

| # | Area | Score | Weight feel |
|---|------|------:|-------------|
| 1 | App architecture (MVVM) | **9.0** | Strong |
| 2 | SwiftUI UI / navigation | **8.5** | Strong |
| 3 | Game design & logic | **9.0** | Strong |
| 4 | State management | **8.0** | Strong |
| 5 | Networking (API) | **8.0** | Strong |
| 6 | Local data persistence | **8.0** | Strong |
| 7 | Authentication / multi-player profiles | **7.5** | Good |
| 8 | Location & MapKit | **8.5** | Strong |
| 9 | Notifications | **7.0** | Good |
| 10 | Charts & personal analytics | **8.0** | Strong |
| 11 | Settings & user preferences | **8.0** | Strong |
| 12 | UX polish (theme, motion, feedback) | **8.0** | Strong |
| 13 | Error handling & edge cases | **7.0** | Good |
| 14 | Security (local auth) | **5.5** | Basic (OK for class) |
| 15 | Testing | **1.0** | Almost none |
| 16 | Documentation | **9.0** | Strong |
| 17 | Accessibility | **3.5** | Thin |
| 18 | Cloud / backend sync | **1.0** | Not in scope (local only) |

### Overall score: **7.1 / 10**

**Verdict:** For a first educational iOS app, this is a **strong, feature-rich** project. You cover architecture, three real games, auth, GPS/map, stats, settings, API, and docs. Main gaps: automated tests, accessibility, and production-grade security/cloud (usually not required for this level).

```text
Coverage radar (approx.)

Architecture     █████████░  9.0
UI / Navigation  ████████░░  8.5
Games            █████████░  9.0
Networking       ████████░░  8.0
Persistence      ████████░░  8.0
Auth / Profiles  ███████░░░  7.5
Map / Location   ████████░░  8.5
Stats / Charts   ████████░░  8.0
Notifications    ███████░░░  7.0
Docs             █████████░  9.0
Testing          █░░░░░░░░░  1.0
Accessibility    ███░░░░░░░  3.5
```

---

## 1. App Architecture (MVVM) — **9.0 / 10**

### What you covered
- Clear folders: `Models` · `Views` · `ViewModels` · `Services`
- Views stay mostly UI; game rules live in ViewModels
- Shared services: Auth, Location, Trivia, Notifications, Feedback, Stats
- Root gate: Login → tab shell (`ContentView`)

### Evidence
- `GameViewModel` / `QuizViewModel` drive game state
- `AuthService`, `LocationService`, `TriviaService` isolate platform work
- Docs describe the same structure

### Gaps
- No formal repository protocol / dependency injection (fine for this size)
- Some high-score updates still tied closely to Views

---

## 2. SwiftUI UI & Navigation — **8.5 / 10**

### What you covered
- Custom tab bar (Home, Stats, Map, Settings)
- `NavigationStack` per tab
- Login screen with Sign Up / Log In / Guest
- Home carousel with locked navigation into a chosen game
- Sheets, confirmation dialogs, segmented controls

### Evidence
- `ArcadeTabBar`, `HomeView`, `LoginView`, game screens
- Dark theme forced app-wide

### Gaps
- No deep links / URL routing
- Limited iPad-specific layout tuning

---

## 3. Game Design & Logic — **9.0 / 10**

### What you covered

| Game | Depth | Highlights |
|------|------:|------------|
| Tap Frenzy | High | Timer, combo, bonus/penalty, move, shrink, double points |
| Light It Up | High | Lives, 4 levels, lit windows, Settings round length |
| Quiz Rush | High | Campaign Easy→Hard, lives, streak, speed bonuses, categories |

### Evidence
- Documented in `docs/games/*.md`
- Distinct mechanics (not three copies of the same game)

### Gaps
- Pause / resume mid-round not emphasized
- No online multiplayer gameplay (profiles are local)

---

## 4. State Management — **8.0 / 10**

### What you covered
- `ObservableObject` + `@Published` ViewModels
- `@AppStorage` for settings
- Shared singletons (`AuthService.shared`, history, location)
- Per-player high scores via `PlayerStatsStore`

### Gaps
- No Combine pipelines beyond basic observation
- Singletons are simple but harder to unit test

---

## 5. Networking (API) — **8.0 / 10**

### What you covered
- Real HTTP API: Open Trivia DB
- `async/await` style loading in Quiz flow
- Category + difficulty parameters
- Retries on rate limit / empty results
- HTML entity decode for question text
- User-facing loading / error / retry UI

### Evidence
- `TriviaService.swift`, `QuizViewModel.swift`

### Gaps
- Only one API (expected)
- No offline question cache

---

## 6. Local Data Persistence — **8.0 / 10**

### What you covered
- `UserDefaults` for players, sessions, highs, settings
- JSON encode/decode for profiles & sessions
- Per-player score keys
- Legacy migration for old high-score keys
- Reset scoped to current player

### Gaps
- Not Core Data / SwiftData (optional for class)
- No Keychain for passwords (see Security)

---

## 7. Authentication & Multi-Player Profiles — **7.5 / 10**

### What you covered
- Sign Up / Log In (username + password)
- Guest nickname login
- Password show/hide (eye icon)
- Unique player IDs
- Separate stats / highs per player
- Log out / switch account
- Display name edit in Settings

### Gaps
- Local device only (no cloud accounts)
- Password hashing is SHA256 without salt (OK for demo, not production)
- Guest cannot “upgrade” to full account later

---

## 8. Location & MapKit — **8.5 / 10**

### What you covered
- When-in-use permission flow
- Attach GPS to finished sessions (toggleable)
- Map pins by game mode
- User annotation, compass, pitch, recenter
- Place label via **MapKit reverse geocoding** (iOS 26+)
- Sri Lanka fallback (avoids US default)
- Far-pin warning for Simulator / old data
- ObjC coordinate bridge for toolchain quirks

### Gaps
- Map still can show pins from all players on device (by design for “where games were played”)
- No clustering for many pins

---

## 9. Notifications — **7.0 / 10**

### What you covered
- Permission request
- Daily reminder scheduling
- Time picker in Settings
- Respect denied status + open Settings path
- Sound tied to preference

### Gaps
- Only one notification type
- No actionable notification buttons

---

## 10. Charts & Personal Analytics — **8.0 / 10**

### What you covered
- SwiftUI Charts bar charts per mode
- XP / rank progression
- Games, totals, average, favorite mode
- Personal bests
- Recent games list
- **Scoped to current player only** (fixed)

### Gaps
- No weekly trends / calendars
- Leaderboard UI removed (local multi-account compare only via switching users)

---

## 11. Settings & Preferences — **8.0 / 10**

### What you covered
- Round length, sound, haptics
- Notifications + location controls
- Profile section
- About section
- Destructive reset with confirmation

### Gaps
- No language / localization settings
- No export/import of data

---

## 12. UX Polish — **8.0 / 10**

### What you covered
- Central theme (`ArcadeTheme`)
- Animated home background / game atmospheres
- Haptics + optional sound
- Loading and empty states (map, stats, quiz)
- Consistent dark arcade look

### Gaps
- Accessibility labels incomplete
- Some copy/UI still denser than a minimal first-app needs (but impressive)

---

## 13. Error Handling & Edge Cases — **7.0 / 10**

### What you covered
- Auth validation messages
- Quiz API retries + retry button
- Location denied / waiting for GPS messaging
- Empty stats / empty map banners
- Invalid GPS accuracy filtering

### Gaps
- Limited global error boundary
- Few offline-mode strategies beyond Quiz retry

---

## 14. Security — **5.5 / 10**

### What you covered
- Passwords not stored as plain text (SHA256)
- Guest vs registered separation
- Location privacy usage description

### Gaps (expected for class app)
- No salt / Keychain
- No biometric unlock
- Local storage can be read on jailbroken / simulator filesystem

**For coursework:** usually acceptable if you explain “local educational auth.”

---

## 15. Testing — **1.0 / 10**

### What you covered
- Manual run / simulator testing (implied)

### Gaps
- No unit tests
- No UI tests
- No test target evidence in project docs

**Highest-impact improvement** if marks depend on testing.

---

## 16. Documentation — **9.0 / 10**

### What you covered
- System architecture & features MD
- Per-game rule docs
- Updated README with links
- Clear “where to change X” map

### Gaps
- No screenshots / UML diagrams in docs (optional)

---

## 17. Accessibility — **3.5 / 10**

### What you covered
- Some accessibility labels (e.g. password eye)

### Gaps
- VoiceOver not systematically supported
- Dynamic Type not verified
- Color contrast not audited

---

## 18. Cloud / Backend Sync — **1.0 / 10**

### What you covered
- Intentionally local-only (correct for your scope)

### Note
Not a failure if the brief says local storage is enough. Score stays low because the *capability* is absent — mark as **N/A** if cloud was never required.

If cloud is **out of scope**, treat this as **N/A** and recalculate overall without it → **~7.5 / 10**.

---

## Feature Checklist (quick)

| Feature | Status |
|---------|--------|
| 3 playable games | Done |
| MVVM structure | Done |
| Local Sign Up / Log In | Done |
| Guest login | Done |
| Password show/hide | Done |
| Per-player stats | Done |
| High scores per player | Done |
| Session history | Done |
| SwiftUI Charts | Done |
| Map + GPS pins | Done |
| Reverse geocoding (MapKit) | Done |
| Daily notifications | Done |
| Sound / haptics toggles | Done |
| Settings round length | Done |
| External trivia API | Done |
| Project documentation | Done |
| Unit / UI tests | Missing |
| Cloud leaderboard | Missing (by choice) |
| Full a11y pass | Missing |

---

## Marks-Style Summary (how to explain in a viva)

**Strengths to highlight**
1. Clean MVVM + Services split  
2. Three meaningfully different games  
3. Real networking with retries  
4. Location + MapKit integration  
5. Multi-account local profiles with isolated stats  
6. Charts + personal analytics  
7. Written docs for architecture and each game  

**Honest limitations to mention**
1. Local-only storage (no cloud sync)  
2. Simple password hashing (educational)  
3. No automated tests yet  
4. Accessibility only lightly touched  

---

## Suggested Next Steps (only if you need higher marks)

| Priority | Action | Likely score lift |
|----------|--------|-------------------|
| 1 | Add 5–10 unit tests (scoring, auth validation, session filter) | Testing 1 → 6+ |
| 2 | Add VoiceOver labels on main buttons | A11y 3.5 → 6 |
| 3 | Short “limitations” slide using this report | Presentation polish |
| 4 | 2–3 screenshots in README | Docs 9 → 9.5 |

---

## Final Score Card

| Bundle | Score |
|--------|------:|
| Core iOS skills (UI, arch, games, data, map, API) | **~8.3 / 10** |
| Product completeness (auth, settings, stats, docs) | **~8.0 / 10** |
| Engineering extras (tests, a11y, security, cloud) | **~2.8 / 10** |
| **Balanced overall (all 18 areas)** | **7.1 / 10** |
| **Overall if cloud = N/A** | **~7.5 / 10** |

**Bottom line:** You have covered a **wide and deep** set of iOS topics for a first educational app. The project is already presentation-ready; the biggest missing academic piece is **automated testing**, not more features.
