# FitQuest 

FitQuest is an advanced running tracking application designed to help you achieve your fitness goals. Whether you're a beginner or an experienced runner, FitQuest offers precise GPS tracking, detailed analytics, and personalized training plans to enhance your running journey.

---

## Key Features 

### Run Tracking
-  **High-precision GPS tracking** with accuracy indicators
-  **Live route visualization** powered by OpenStreetMap
-  **Real-time metrics:** pace, distance, and duration
-  Intuitive **pause/resume functionality**
-  **Smart route smoothing algorithm**

### Analytics Dashboard
-  **Comprehensive performance analysis**
-  Weekly and monthly **activity summaries**
-  Personal **records tracking**
-  **Progress visualization**

### Goal Setting
-  **Custom fitness goals:** distance, duration, calories, and workout frequency
-  **Distance targets**
-  **Duration objectives**
-  **Calorie goals**
-  **Workout frequency targets**

### Training
-  **Structured training plans** for runners of all levels
-  **Progress tracking** for continuous improvement
-  **Achievement system** to celebrate milestones
-  **Intuitive workout interface**

---

## Screenshots 

*(Insert your app screenshots here with descriptions)*

---

## Installation 

### Clone the repository
```
git clone https://github.com/yourusername/mobile-project-fitquest.git
```
```
cd mobile-project-fitquest
```
```
flutter pub get
```
```
flutter run
```

## Tech Stack
-  **Frontend:** Flutter 
-  **State Management:** Provider 
-  **Local Database:** SQLite
-  **Map:** OpenStreetMap with flutter_map
-  **Location Services:** Flutter Location
-  **Architecture**: MVVM with Clean Architecture

## Project Structure
lib/
├── core/
│   ├── theme/                # App theme and styling
│   ├── constants/            # App-wide constants
│   └── utils/                # Helper functions
├── data/
│   ├── repositories/         # Data repositories
│   └── local/                # Local data storage
├── domain/
│   ├── models/               # Business logic models
│   └── services/             # Business logic services
├── presentation/
│   ├── screens/              # App screens
│   ├── widgets/              # Reusable widgets
│   └── viewmodels/           # Screen logic
└── main.dart                 # App entry point


## Requirements
- **Flutter**: (latest version)
- **Android Studio / VS Code**
- **Android SDK / Xcode**
- **A physical device or emulator**

## Acknowledgments 
- The amazing Flutter Team for the framework
- OpenStreetMap contributors
