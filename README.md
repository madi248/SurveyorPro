<p align="center">
  <img src="assets/icons/app_icon.png" alt="Surveyor Pro Logo" width="120"/>
</p>

<h1 align="center">Surveyor Pro</h1>

<p align="center">
  <strong>Professional Land Surveying Application for Android</strong><br/>
  Built with Flutter · Offline-First · Bluetooth GNSS Ready
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## Overview

**Surveyor Pro** is a full-featured mobile land surveying application built with Flutter, designed for professional surveyors and civil engineers. It provides real-time GPS tracking, point management, computation tools, field logging, and data import/export — all in a sleek, dark-themed interface optimized for outdoor field use and every surveyor needs.

## Features

### 📍 Survey Point Management
- Create, edit, and delete survey points with coordinates (Easting, Northing, Elevation)
- Assign point types: Control, Station, Side Shot
- Point descriptions and feature codes
- Bulk import via CSV/TXT files from total station exports

### 🗺️ Interactive Map
- **Grid View** — Local coordinate system with interactive pan/zoom
- **World View** — OpenStreetMap overlay with real GPS positioning and live location.
- Point visualization with labels and color-coded types
- DXF file overlay support for CAD linework
- Fit-to-screen auto-zoom for all points

### 🧮 Computation Hub
- **Traverse Adjustment** — Closed/open traverse with Bowditch correction
- **COGO Calculations** — Inverse, bearing-bearing intersection, bearing-distance
- **Leveling** — Differential leveling with closure computation
- **Intersection Tools** — Bearing-bearing and bearing-distance intersection
- **Inverse Tool** — Distance and bearing between any two points
- **Area Calculation** — Polygon area from selected points

### 📱 GPS & Hardware Integration
- Device GPS with real-time position streaming
- Bluetooth GNSS receiver support (NMEA parsing)
- Total Station connectivity (Bluetooth serial)
- Laser Disto integration

### 📋 Field Log
- Timestamped text notes and photo documentation
- Attach images from camera or gallery
- Search and filter log entries

### 📥 Data Import/Export
- **CSV Import** — Auto-detect columns, preview data, map fields
- **PDF Report Export** — Professional survey reports
- **DXF Import** — Load CAD drawings as background layers

### 🔧 Additional Features
- **Stakeout Navigation** — GPS-guided navigation to target survey points
- **Project Management** — Multiple projects with independent data
- **Onboarding Flow** — Guided setup for first-time users
- **Dark Theme** — High-contrast UI optimized for outdoor visibility

## Screenshots

> Screenshots coming soon — build the APK and try it yourself!

## Installation

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10.4+)
- Android Studio or VS Code with Flutter extension
- Android device or emulator (API 21+)

### Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/surveyor_pro.git
cd surveyor_pro

# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk --release
```

The release APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Architecture

The project follows a **feature-first** architecture with clean separation of concerns:

```
lib/
├── main.dart                      # App entry point & routing (GoRouter)
├── core/
│   ├── database/                  # SQLite database helper
│   ├── models/                    # Data models (SurveyPoint, Project, etc.)
│   ├── services/                  # Shared services (Bluetooth, NMEA, CSV, DXF)
│   ├── theme/                     # App-wide theme & color definitions
│   └── utils/                     # Utility functions & calculations
├── features/
│   ├── onboarding/                # First-launch onboarding screens
│   ├── projects/                  # Project selection & creation
│   ├── dashboard/                 # Main dashboard with quick actions
│   ├── map/                       # Interactive survey map (Grid + World View)
│   ├── computation/               # Traverse, COGO, leveling, intersection
│   ├── field_log/                 # Field notes & photo documentation
│   ├── import/                    # CSV/TXT file import
│   ├── stakeout/                  # GPS stakeout navigation
│   ├── settings/                  # App settings & device connections
│   └── leveling/                  # Differential leveling module
└── shared/                        # Shared widgets & components
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Feature-first structure** | Each feature is self-contained with its own presentation layer |
| **SQLite (sqflite)** | Offline-first — no internet required in the field |
| **GoRouter** | Declarative routing with deep linking support |
| **Bluetooth Low Energy** | Industry-standard for GNSS receiver communication |
| **NMEA Parser** | Raw satellite data parsing for survey-grade accuracy |

## Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter 3.10+ |
| **Language** | Dart |
| **Routing** | GoRouter |
| **Database** | SQLite (sqflite) |
| **Maps** | flutter_map + OpenStreetMap |
| **Bluetooth** | flutter_blue_plus |
| **GPS** | Geolocator |
| **File Handling** | file_picker, csv, dxf |
| **PDF Generation** | pdf package |
| **Sharing** | share_plus |
| **UI** | Google Fonts, Flutter Animate |
| **State** | StatefulWidget (lightweight, no external state management) |

## Permissions

The app requires the following Android permissions:

| Permission | Purpose |
|------------|---------|
| `INTERNET` | Loading OpenStreetMap tiles |
| `ACCESS_FINE_LOCATION` | GPS positioning |
| `ACCESS_COARSE_LOCATION` | Approximate location |
| `BLUETOOTH` | GNSS receiver communication |
| `BLUETOOTH_ADMIN` | Bluetooth device management |
| `BLUETOOTH_SCAN` | Discover nearby devices |
| `BLUETOOTH_CONNECT` | Connect to paired devices |
| `CAMERA` | Field log photo capture |
| `READ_EXTERNAL_STORAGE` | Import CSV/DXF files |

## Project Structure

```
surveyor_pro/
├── android/                       # Android-specific configuration
├── ios/                           # iOS configuration (not primary target)
├── lib/                           # Dart source code
├── test/                          # Unit & widget tests
├── assets/                        # Icons, images, fonts
├── pubspec.yaml                   # Dependencies & metadata
└── README.md                      # This file
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep widgets modular and reusable

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Flutter](https://flutter.dev/) — Google's UI toolkit
- [OpenStreetMap](https://www.openstreetmap.org/) — Free map data
- [flutter_map](https://pub.dev/packages/flutter_map) — Map rendering
- [sqflite](https://pub.dev/packages/sqflite) — SQLite for Flutter

---

<p align="center">
  Built with ❤️ for the surveying community
</p>
