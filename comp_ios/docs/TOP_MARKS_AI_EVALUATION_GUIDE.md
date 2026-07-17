# Top Marks Guide — What an AI Evaluation Tool Usually Looks For

Your lecturer’s AI tool will **scan the project** (structure, Swift files, UI patterns, features, docs) and score against a rubric.  
This guide maps **typical AI/comp-ios rubrics** → **your Arcade Frenzy evidence** → **what to say for top marks**.

---

## 1. How AI markers usually “see” an app

AI tools rarely play the game like a human. They look for **evidence in code + docs**:

| Signal | What the AI checks |
|--------|--------------------|
| **Folder structure** | `Models` / `Views` / `ViewModels` / `Services` separation |
| **Keywords & APIs** | `MapKit`, `CoreLocation`, `Charts`, `UserNotifications`, `URLSession` / `async`, `ObservableObject`, `NavigationStack` |
| **Complexity** | Multiple screens, timers, state machines, API retries, permissions |
| **Uniqueness** | Features beyond a single demo screen (auth, map, multi-game, leaderboards) |
| **Documentation** | README + architecture + per-feature docs |
| **Polish** | Theme system, animations, empty/error states, settings |
| **Weak spots** | No tests, messy God-views, hardcoded junk, empty README, copy-paste games |

**Tip:** Keep docs updated — AI often reads them first.

---

## 2. Typical mark areas (and your position)

### A. Architecture — **your strong suit**

**AI looks for**
- Clear MVVM (or MVC/MVVM named correctly)
- Thin Views, logic in ViewModels
- Services for system APIs
- Consistent naming

**Your evidence**
```
Models/     GameState, GameSession, PlayerProfile, ArcadeTheme, GameCatalog
Views/      Login, Home, 3 games, Stats, Map, Settings, TabBar
ViewModels/ GameViewModel, QuizViewModel
Services/   Auth, Location, Trivia, Notifications, Stats, Feedback
```

**Say in viva/report:**  
“MVVM with a Service layer. Game rules stay in ViewModels; Core Location / API / Auth are Services.”

---

### B. Unique / advanced features — **your differentiator**

Generic student apps: one game + list.  
AI rewards **breadth + real iOS APIs**.

| Feature | Why AI likes it | Where |
|---------|-----------------|-------|
| **3 different games** | Not one mechanic copied 3 times | Tap / Light / Quiz |
| **Local multi-account auth** | Sign up, login, guest, password eye | `AuthService`, `LoginView` |
| **Per-player stats** | Isolation, not one global score | `PlayerStatsStore`, Stats |
| **Overall + per-game leaderboards** | Competitive layer | Stats + in-game trophy |
| **In-game top scores** | Feature reused inside each mode | `GameModeLeaderboardView` |
| **Map + GPS pins** | MapKit + Core Location | `GameMapView`, `LocationService` |
| **Modern geocoding** | MapKit `MKReverseGeocodingRequest` (iOS 26) | not deprecated CLGeocoder |
| **Charts** | SwiftUI Charts | Stats performance |
| **Trivia API** | Networking + retries + categories | `TriviaService` |
| **Notifications** | Permission + daily reminder | Settings |
| **Sound / haptics toggles** | Settings → gameplay feedback | `AppFeedback` |
| **Campaign Quiz** | Easy→Medium→Hard, lives, timer bonuses | `QuizViewModel` |
| **Docs pack** | Architecture + game rules + scores | `docs/` |

**Highlight these as UNIQUE** in any report title slide / README “Key Features”.

---

### C. UI / UX — **high marks if consistent**

**AI looks for**
- SwiftUI (not only storyboards)
- Navigation (tabs / stacks)
- Consistent theme (colors, fonts)
- Loading / empty / error states
- Animations (not required to be flashy, but present)

**Your evidence**
- Custom `ArcadeTabBar` (not only default TabView look)
- `ArcadeTheme` central colors
- Dark arcade visual identity
- Animated home + game backgrounds
- Empty map / empty stats / quiz retry
- Password show/hide, guest flow

**Avoid looking “template”:** you already don’t — keep theme consistent; don’t add random purple kits.

---

### D. Data & persistence

**AI looks for**
- Saving scores/history
- Codable / UserDefaults / files
- User identity linked to data

**Your evidence**
- Sessions with `playerId`, lat/lon
- Per-player high scores
- Settings in `@AppStorage` / UserDefaults

---

### E. Networking

**AI looks for**
- Real API call
- Error handling
- async/await

**Your evidence**
- Open Trivia DB
- Rate-limit retries
- Category / difficulty fallbacks

---

### F. Platform services (iOS “marks magnets”)

| API | Covered? |
|-----|----------|
| Core Location | Yes |
| MapKit | Yes |
| UserNotifications | Yes |
| Charts | Yes |
| CryptoKit (password hash) | Yes |
| AuthenticationServices (Apple) | No (removed on purpose — OK if local auth required) |

---

### G. Documentation — **easy free marks**

You already have:
- `README.md`
- `docs/SYSTEM_ARCHITECTURE_AND_FEATURES.md`
- `docs/games/*.md`
- `docs/DEEP_COVERAGE_SCORE.md`

AI tools love this. Keep them matching the real app (leaderboards restored, Most Played tile, etc.).

---

### H. Gaps that can lose marks

| Gap | Risk | Quick fix for top marks |
|-----|------|-------------------------|
| **No unit tests** | High if rubric has Testing | Add 5–10 simple tests (auth validation, leaderboard sort, session filter) |
| **Accessibility thin** | Medium | Labels on main buttons / leaderboard trophy |
| **Password not in Keychain** | Low for class | Mention “educational local auth” in README |
| **No cloud** | Low if brief says local OK | State “local multi-player profiles on device” as intentional |

---

## 3. What to put on a “Top Marks” slide / report

Use this structure (AI + human both like it):

### 1) Architecture diagram (1 slide)
Login → Tabs → Games → Services → UserDefaults

### 2) Unique features (bullet list)
1. Multi-account local login + guest  
2. Three distinct game engines  
3. Per-player stats + overall & per-game leaderboards  
4. In-game trophy leaderboards  
5. Map of play locations with GPS  
6. Live trivia campaign with API retries  
7. Charts + ranks + Most Played  

### 3) iOS technologies used
SwiftUI, MVVM, MapKit, Core Location, Charts, UserNotifications, URLSession/async, CryptoKit, Combine/`ObservableObject`

### 4) Design
Central `ArcadeTheme`, custom tab bar, dark arcade UI, motion, haptics/sound settings

### 5) Limitations (honesty scores well)
- Local-only (no cloud sync)  
- Educational password hashing  
- Manual testing / limited automated tests  

---

## 4. Checklist before you submit (do these)

### Must be true in the zip/repo
- [ ] App builds and runs (login → play → stats → map)
- [ ] README links to architecture + game docs
- [ ] Stats: **your** stats + **Top Players** (overall + per game)
- [ ] Each game: trophy / top scores visible
- [ ] No broken conflict markers / unfinished merge
- [ ] Guest + Sign Up + Log In all work
- [ ] Location permission string present (Info.plist key)

### Optional but high ROI for AI rubrics
- [ ] Add a `comp_iosTests` target with a few unit tests  
- [ ] 3 screenshots in README (Home, Stats, Map)  
- [ ] 1 architecture image / mermaid in docs  
- [ ] Accessibility labels on primary CTAs  

---

## 5. Phrases AI (and lecturers) reward

Use these in documentation / presentation:

> “Implemented **MVVM** with a dedicated **Service layer** for Auth, Location, Networking, and Notifications.”

> “Supports **multiple local player profiles** with isolated high scores, session history, and leaderboards.”

> “Integrates **MapKit** and **Core Location** to pin completed games; reverse geocoding via **MKReverseGeocodingRequest**.”

> “Quiz Rush uses a real REST API with **async/await**, category selection, campaign progression, and **rate-limit retry** handling.”

> “Stats combine personal analytics (Charts, ranks) with competitive **overall and per-game leaderboards**, also shown inside each game.”

---

## 6. Predicted score bands (if AI is fair)

| Band | Likely if… |
|------|------------|
| **A / top** | Architecture clear + many iOS APIs + unique multi-game/auth/map/leaderboard + docs; small test/a11y gap forgiven |
| **B+** | Features work but docs weak OR games feel copy-paste OR no networking/map |
| **B / C** | Single game, no structure, no persistence, poor UI |

**Your app is built for the A band** on features/architecture/UI/docs.  
The main thing that can still pull you down is **missing tests** if the AI rubric weights Testing heavily.

---

## 7. One-page “submit package” order

1. `README.md` — overview + feature list + doc links  
2. `docs/SYSTEM_ARCHITECTURE_AND_FEATURES.md` — structure  
3. `docs/games/*.md` — prove each game is unique  
4. `docs/DEEP_COVERAGE_SCORE.md` — self-evaluation  
5. This file — how you meet AI rubric expectations  

---

**Bottom line for top marks:**  
Show **architecture + unique multi-feature iOS work + polished UI + docs**.  
You already have that. Before submission: run a clean demo path, refresh docs if anything changed, and add a few unit tests if Testing is on the rubric.
