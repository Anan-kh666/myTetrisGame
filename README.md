# Flutter Tetris

A fully-featured Tetris clone built with Flutter — playable on Android, iOS, macOS, Windows, Linux, and Web.

---

## Features

- **7 Tetromino pieces** — L, J, I, O, S, Z, T with authentic colors
- **Ghost piece** — semi-transparent preview showing landing position
- **Hold piece** — save a piece for later (once per spawn)
- **Hard drop** — instant drop to bottom
- **Line clearing** with cascade detection
- **Scoring system** — Single (100), Double (300), Triple (500), Tetris (800) × level multiplier
- **Leveling & speed progression** — piece speed increases every 600 points
- **Persistent high score** tracking per session
- **Sound effects** — move, rotate, hard drop, line clear, game over
- **3D visual effects** — gradient shading and glowing cyan UI theme
- **Pause / resume** support

---


## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `^3.10.8`
- Dart `^3.10.8`

### Run locally

```bash
git clone https://github.com/your-username/flutter-tetris.git
cd flutter-tetris
flutter pub get
flutter run
```

Supports all Flutter targets: Android, iOS, macOS, Windows, Linux, Web.

### Android APK

A prebuilt release APK is available at:

```
build/app/outputs/apk/release/app-release.apk
```

Download it directly to an Android device and install (enable "Install from unknown sources" if prompted).

---

## Controls

| Button | Action |
|--------|--------|
| LEFT | Move piece left |
| RIGHT | Move piece right |
| ROTATE | Rotate piece clockwise |
| HARD DROP | Instantly drop piece |
| HOLD | Hold current piece |
| PAUSE | Pause / resume game |

---

## Scoring

| Lines Cleared | Base Points |
|---------------|-------------|
| 1 (Single) | 100 |
| 2 (Double) | 300 |
| 3 (Triple) | 500 |
| 4 (Tetris) | 800 |

All scores are multiplied by the current level.

---

## Tech Stack

| | |
|---|---|
| Framework | Flutter |
| Language | Dart |
| Audio | `audioplayers ^6.5.1` |
| Icons | `cupertino_icons ^1.0.8` |

---

## Project Structure

```
lib/
└── main.dart          # All game logic, state management, and UI
assets/
├── icon.png           # App icon
└── sounds/
    ├── move.mp3
    ├── rotate.mp3
    ├── drop.mp3
    ├── clear.mp3
    └── gameover.mp3
```

---

## License

MIT
