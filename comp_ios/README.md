# Arcade Frenzy 🎮

Arcade Frenzy is a premium, high-fidelity iOS arcade game hub featuring multiple interactive game modes: **Tap Frenzy**, **Light It Up**, and **Quiz Rush**. It features a modern Tab Bar shell, integrated GPS mapping, statistics dashboards, custom local daily reminders, and score sharing.

---

## 🏗️ Architecture Overview

The app is built using clean architecture conforming to the **MVVM (Model-View-ViewModel)** design pattern. It organizes source files into logical modules:

```
├── Models/
│   ├── GameState.swift       # Holds GameState, Level, Card and GameMode definitions
│   └── GameSession.swift     # Log record modeling user scores, dates, and locations
├── Services/
│   ├── TriviaService.swift   # Network layer calling Open Trivia DB API
│   ├── LocationService.swift # Core Location service fetching player coordinates
│   └── NotificationService.swift # Local notification reminder calendar scheduler
├── ViewModels/
│   ├── GameViewModel.swift   # Handles game loops, ticks, levels, and cards logic
│   └── QuizViewModel.swift   # ViewModel for trivia loading, answers, and streak state
└── Views/
    ├── ContentView.swift     # Root view loading the 4-tab TabView navigation shell
    ├── HomeView.swift        # Home screen with aurora particles and cascading entry cards
    ├── TapFrenzyView.swift   # Speed tap mode view
    ├── LightItUpView.swift   # Level-progressing grid tap view
    ├── QuizRushView.swift    # API-powered Live Trivia game view
    ├── StatsView.swift       # Statistics dashboard utilizing SwiftUI Charts
    ├── GameMapView.swift     # MapKit displaying completed game locations with Markers
    └── SettingsView.swift    # Game duration, reminder picker, and records reset
```

- **Models**: Defines raw entities (`Card`, `GameMode`, `GameSession`, `Level`) and structures.
- **Views**: SwiftUI layers displaying layouts, fluid gradient backgrounds, overlays, and spring animations.
- **ViewModels**: State controllers isolating reactive game logic, timers, question caching, and streak bonuses from the UI.
- **Services**: Adapters handling platform SDK APIs (MapKit, Core Location, UserNotifications, and URLSession).

---

## 🌟 Features List

### 1. Game Modes
- **Tap Frenzy**: A fast-paced tap-counting challenge. Features color-coded bonus buttons (+3) and penalty buttons (-2) with random spring offsets and double points multipliers.
- **Light It Up**: A grid reflex game with 4 progressive levels. Lit cards scale up with custom glows. Integrates a 3-lives system and Proportionate Level-Up thresholds.
- **Quiz Rush**: A live trivia challenge pulling questions dynamically from Open Trivia DB using modern async/await. Tracks answer streaks for bonus multipliers.

### 2. Core Navigation Shell
- A native `TabView` shell linking **Home**, **Stats**, **Map**, and **Settings** navigation stacks with standard SF Symbols (`gamecontroller`, `chart.bar`, `map`, `gear`).

### 3. Core Location MapKit
- Fetches device coordinates on each completed game session.
- Displays standard MapKit `Marker` balloons pinned to played locations on the Map tab. Selecting a pin shows game mode and score.

### 4. Stats & Analytics Charts
- Persists session arrays locally via `UserDefaults`.
- Displays personal best records, totals, and a list of recent games.
- Uses SwiftUI **Charts** framework to render individual bar graphs for each mode.

### 5. Local Daily Reminders
- Integrates calendar notification scheduling (`UserNotifications`).
- Allows selecting custom daily reminder times in Settings.

### 6. Interactive Settings
- Adjusts default round duration (30s / 60s / 90s) adapting game thresholds.
- Allows clearing high scores and history logs with confirmation dialog safety checks.

---

## ⚠️ Known Limitations

1. **API Rate Limiting**: The Open Trivia DB API has a brief rate-limiting cooldown if queried in rapid succession. A fallback Retry button is provided in `QuizRushView` to handle network issues.
2. **GPS Accuracy**: In indoor environments, Core Location might return cached or less accurate coordinates. Location fetches use standard location checks, falling back to Cupertino coordinates in the simulator if location access is denied.
3. **Local Notifications Storage**: Push schedules require explicit OS authorization. If a user denies notifications, the toggle in Settings automatically flips back.

---

## 🧠 Reflection

Arcade Frenzy was designed as a showcase of modern Swift and SwiftUI techniques:
- **Clean Structure**: Separating managers/adapters into `Services` and keeping Views decoupled from states via `ObservableObject` view-models makes adding features straightforward.
- **Modern SwiftUI**: Standardized on iOS 17 features like the new `MapKit` builder (`Marker`, `MapCameraPosition`) and SwiftUI `Charts` for seamless visualization.
- **Robust Layout**: Staged spring animation offsets and Fluid Aurora Blobs create an engaging user experience, making the application feel premium and responsive.
