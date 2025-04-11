# FitQuest V2

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

<div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px;">
    <img src="https://github.com/user-attachments/assets/2143e077-426e-4558-a97b-851e1e04401d" width="200" alt="">
    <img src="https://github.com/user-attachments/assets/669936d1-3ec9-44de-bb86-d828dfa8c81d" width="200" alt="">
    <img src="https://github.com/user-attachments/assets/588c49ea-ca1c-4201-8040-d77a8ec611ab" width="200" alt="">
    <img src="https://github.com/user-attachments/assets/7c101656-6f4c-4c73-b3eb-f371c8083946" width="200" alt="">
</div>

<div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px;">
    <img src="https://github.com/user-attachments/assets/a65f65fe-b861-4c52-8c09-aa26ce252091" width="200" alt="">
    <img src="https://github.com/user-attachments/assets/386d3acb-9866-42ef-8b82-1d0102a317c8" width="200" alt="">
    <img src="https://github.com/user-attachments/assets/7f228baf-ae21-4911-a352-aa2d84c7c5df" width="200" alt="">
    <img src="https://github.com/user-attachments/assets/7ce47d60-1c5c-4b28-92d2-ff478ada3e64" width="200" alt="">
</div>

<div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px;">
    <img src="https://github.com/user-attachments/assets/b3bf16e6-31d8-465c-b01f-afad94deea50" width="200" alt="">
    <img src="https://github.com/user-attachments/assets/56d05fdf-2f55-4007-9c51-1c33a1a90e34" width="200" alt="">
    <img src="https://github.com/user-attachments/assets/8c7d7068-f5ca-47e1-b336-b108a27ec9c0" width="200" alt="">
    <img src="https://github.com/user-attachments/assets/4a992d1f-9648-4bfa-a751-aa0be6417c4d" width="200" alt="">
</div>

<div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px;">
    <img src="https://github.com/user-attachments/assets/186be706-2ae4-4d02-a12b-0b3ad60bb919" width="200" alt="">
    <img src="https://github.com/user-attachments/assets/b5c65500-c30f-4082-be71-5c6f2d992cc4" width="200" alt="">
    <img src="https://github.com/user-attachments/assets/ca15654d-461a-4507-a26e-01738dfbd065" width="200" alt="">
</div>

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
```
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
```

## Requirements
- **Flutter**: (latest version)
- **Android Studio / VS Code**
- **Android SDK / Xcode**
- **A physical device or emulator**

## Acknowledgments 
- The amazing Flutter Team for the framework
- OpenStreetMap contributors

- **Android SDK / Xcode**
- **A physical device or emulator**

## Acknowledgments 
- The amazing Flutter Team for the framework
- OpenStreetMap contributors
