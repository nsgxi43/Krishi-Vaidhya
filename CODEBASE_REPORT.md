# Krishi Vaidhya — Complete Codebase Report

> **"Krishi Vaidhya"** means *"Crop Doctor"* in Sanskrit/Hindi.  
> An AI-powered agricultural assistant for Indian farmers — crop disease diagnosis, calendar planning, community, predictive alerts, and agri-store discovery.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [Repository Structure](#3-repository-structure)
4. [System Architecture](#4-system-architecture)
5. [Backend — Deep Dive](#5-backend--deep-dive)
6. [Frontend — Deep Dive](#6-frontend--deep-dive)
7. [Complete App Flow](#7-complete-app-flow)
8. [Feature Breakdown](#8-feature-breakdown)
9. [Data Models](#9-data-models)
10. [API Reference](#10-api-reference)
11. [Offline Functionality](#11-offline-functionality)
12. [State Management](#12-state-management)
13. [Configuration & Environment](#13-configuration--environment)
14. [Known Issues & Limitations](#14-known-issues--limitations)

---

## 1. Project Overview

Krishi Vaidhya is a full-stack mobile/web application targeting Indian farmers. It provides:

| Feature | Description |
|---------|-------------|
| **AI Disease Diagnosis** | Upload a crop photo → CNN or Gemini AI identifies disease → LLM generates treatment plan |
| **Crop Calendar** | Sowing-date-based lifecycle scheduler with weather-driven auto-rescheduling |
| **Predictive Alerts** | Risk scoring engine that analyses nearby community diagnoses + weather to alert farmers about incoming disease outbreaks |
| **Community Forum** | Farmers post questions, share diagnoses, like/comment |
| **Agri Store Locator** | Nearby agricultural stores via Google Places API |
| **Fertilizer Calculator** | NPK requirement calculator based on crop type and acreage |
| **Multi-language** | English, Hindi (हिंदी), Tamil (தமிழ்), Telugu (తెలుగు) |
| **Offline Mode** | Pre-loaded disease database + local calendar cache for no-internet use |

---

## 2. Tech Stack

### Backend
| Layer | Technology |
|-------|-----------|
| Runtime | Python 3.13.1 |
| Web Framework | Flask 3.x + Flask-CORS |
| AI / Vision | Google Gemini API (`gemini-2.0-flash` → fallback chain) |
| Local ML | TensorFlow/Keras — MobileNetV2-based `.h5` model (optional) |
| Explainability | Grad-CAM (OpenCV + NumPy) |
| Database | Google Cloud Firestore (Firebase Admin SDK) |
| Weather | WeatherAPI.com (7-14 day forecast) |
| Geolocation | Google Maps Geocoding API + Google Places API |
| Geohashing | `python-geohash` library |
| Environment | `python-dotenv` |
| Virtual Env | `.venv` (Python `venv` module, Windows) |

### Frontend
| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.27.2 / Dart 3.6.1 |
| Platforms | Web (Chrome), Android, iOS, Windows, macOS, Linux |
| State Management | `provider` ^6.1.2 |
| Local Storage | `shared_preferences` ^2.2.2 |
| HTTP Client | `http` ^1.2.0 |
| Camera | `camera` ^0.10.5 + `image_picker` 1.0.7 (pinned) |
| On-device ML | `flutter_tflite` ^1.0.1 |
| Geolocation | `geolocator` ^10.1.0 |
| URL Launcher | `url_launcher` ^6.2.1 |
| Fonts | `google_fonts` ^6.1.0 |
| Sensors | `sensors_plus` ^5.0.1, `environment_sensors` ^0.3.0 |
| Internationalisation | `intl` ^0.19.0 |

---

## 3. Repository Structure

```
Krishi-Vaidhya-main/
├── backend/                        # Python Flask API
│   ├── app.py                      # Entry point — all routes registered here
│   ├── requirements.txt            # Python dependencies
│   ├── .env                        # API keys (not committed to main)
│   ├── db/                         # Firestore service layer
│   │   ├── firebase_init.py        # Firebase Admin SDK init
│   │   ├── users_service.py        # User upsert
│   │   ├── diagnosis_service.py    # Save/retrieve diagnoses
│   │   ├── calendar_db_service.py  # Save/retrieve calendars
│   │   └── community_service.py    # Posts, comments, likes
│   ├── doc_feature/                # AI pipeline
│   │   ├── pipeline.py             # Orchestrates CNN→GradCAM→LLM→DB→Stores
│   │   ├── infer.py                # CNN inference (TensorFlow)
│   │   ├── gradcam.py              # Grad-CAM explainability
│   │   ├── llm.py                  # Gemini Vision + text LLM
│   │   ├── agri_store_service.py   # Nearby store lookup (Google Places)
│   │   └── model/                  # plant_disease_model.h5 (not in git)
│   ├── agri_calendar/              # Calendar & weather
│   │   ├── calendar_service.py     # Calendar generation logic
│   │   ├── crop_data_accurate.py   # ICAR-sourced crop lifecycle data
│   │   ├── weather_service.py      # WeatherAPI.com integration
│   │   ├── scheduler.py            # Weather-based rescheduling
│   │   ├── reminder_service.py     # Activity reminders
│   │   └── background_jobs.py      # Scheduled background tasks
│   ├── location/
│   │   ├── location_service.py     # Reverse geocode + Place search
│   │   └── gmaps_client.py         # Google Maps HTTP client
│   └── prediction/
│       └── prediction_engine.py    # Disease risk alert engine
│
└── frontend/                       # Flutter application
    ├── lib/
    │   ├── main.dart               # App entry, provider registration
    │   ├── providers/              # State (LanguageProvider, UserProvider, ThemeProvider, ConnectivityProvider)
    │   ├── screens/                # 20 screen files
    │   ├── services/               # 8 service files (API, auth, offline, etc.)
    │   ├── models/                 # 8 data model files
    │   ├── widgets/                # Shared widgets (WeatherCard)
    │   └── utils/                  # Theme, Translations (4 languages, 874 lines)
    ├── assets/
    │   ├── images/                 # Crop images (tomato, wheat, rice, etc.)
    │   ├── model/                  # model.tflite + labels.txt
    │   └── offline_data/
    │       └── crop_diseases.json  # Pre-loaded disease DB (5 crops, ~356 lines)
    └── pubspec.yaml
```

---

## 4. System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Frontend                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │ Language │→ │  Login   │→ │  Crop    │→ │  Home  │  │
│  │ Screen   │  │  Screen  │  │ Select   │  │ Screen │  │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘  │
│                                                │         │
│         ┌──────────────────────────────────────┤         │
│         ▼            ▼           ▼            ▼         │
│   ┌──────────┐ ┌─────────┐ ┌────────┐ ┌───────────┐   │
│   │ Disease  │ │  Crop   │ │ Agri   │ │ Community │   │
│   │ Diagnosis│ │Calendar │ │ Store  │ │  Forum    │   │
│   └─────┬────┘ └────┬────┘ └───┬────┘ └─────┬─────┘   │
└─────────┼───────────┼──────────┼─────────────┼─────────┘
          │           │          │             │
          └─────────────────┬────┘─────────────┘
                            ▼
┌─────────────────────────────────────────────────────────┐
│           Flask REST API  (port 5001)                    │
│                                                          │
│  /api/diagnosis  →  AI Pipeline                         │
│  /api/calendar/generate  →  Calendar Service            │
│  /api/stores  →  Google Places                          │
│  /api/community/*  →  Firestore Community               │
│  /api/prediction/alerts  →  Risk Engine                 │
│  /api/weather/current  →  WeatherAPI                    │
│  /api/users/login  →  Firestore Users                   │
└──────────────────────────┬──────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
  ┌──────────┐     ┌──────────────┐    ┌──────────────┐
  │ Firestore│     │  Gemini API  │    │ WeatherAPI + │
  │ (Google  │     │ (AI/Vision)  │    │ Google Maps  │
  │  Cloud)  │     └──────────────┘    └──────────────┘
  └──────────┘
```

---

## 5. Backend — Deep Dive

### 5.1 Entry Point (`app.py`)

All routes are defined in a single `app.py`. Flask runs on `host='0.0.0.0', port=5001`. CORS is globally enabled for all origins (required for Flutter web). Key route groups:

| Route Group | Prefix | Methods |
|-------------|--------|---------|
| Health check | `GET /` | Returns status + DB connection state |
| Authentication | `/api/users/login` | `POST` |
| Disease Diagnosis | `/api/diagnosis` | `POST` (multipart/form-data) |
| Crop Calendar | `/api/calendar/*` | `POST`, `GET` |
| Agri Stores | `/api/stores` | `POST` |
| Community | `/api/community/*` | `GET`, `POST` |
| Predictive Alerts | `/api/prediction/alerts` | `POST` |
| Weather | `/api/weather/current` | `GET` |
| Static Files | `/static/*` | `GET` (serves community images) |

---

### 5.2 AI Disease Diagnosis Pipeline (`doc_feature/pipeline.py`)

The pipeline follows a 6-step sequential flow:

```
Step 0: TensorFlow Available?
    │
    ├─ NO  → Gemini Vision (analyze_image_with_gemini) → Cloud AI does everything
    │
    └─ YES → Step 1: CNN Inference (run_inference)
                      │
             Step 2: Grad-CAM Explainability (run_gradcam)
                      │
             Step 3: LLM Text Explanation (get_llm_explanation)
                      │
             Step 4: Reverse Geocode Location (normalize_location)
                      │
             Step 5: Save to Firestore (create_diagnosis)
                      │
             Step 6: Get Nearby Agri Stores (get_nearby_agri_stores)
```

**CNN Model** (`doc_feature/infer.py`):
- Architecture: MobileNetV2-based transfer learning model
- Input: 224×224 RGB image
- Output: Disease class label + confidence score
- Model file: `doc_feature/model/plant_disease_model.h5` (not in git, loaded at startup)
- Label file: `assets/model/labels.txt`
- Supports 38 plant disease classes from the PlantVillage dataset

**Grad-CAM** (`doc_feature/gradcam.py`):
- Target layer: `Conv_1` (last convolutional layer)
- Produces a heatmap showing which image regions influenced the prediction
- Falls back to a text summary if TensorFlow or OpenCV is unavailable
- Result stored in `explainability` dict passed to LLM

**LLM Module** (`doc_feature/llm.py`):
- Primary model: `gemini-2.0-flash`
- Fallback chain: `gemini-2.0-flash` → `gemini-2.5-flash` → `gemini-1.5-flash`
- Rate limit handling: exponential backoff (4s, 8s, 16s)
- Local fallback: hardcoded `_DISEASE_DB` dictionary with ~20 common diseases
- Minimum confidence threshold: `0.60` (rejects low-confidence CNN predictions)
- Two modes:
  - **Text explanation mode**: takes CNN + Grad-CAM output, asks Gemini to explain
  - **Vision mode**: sends raw image to Gemini for end-to-end diagnosis when TF is absent

**Gemini Vision prompt** asks for strict JSON with:
```json
{
  "crop": "...",
  "predicted_disease": "Crop___Disease_Name",
  "confidence": 0.95,
  "explainability": { "method": "...", "summary": "..." },
  "llm": {
    "disease_overview": "...",
    "why_this_prediction": "...",
    "chemical_treatments": ["..."],
    "organic_treatments": ["..."],
    "prevention_tips": ["..."]
  }
}
```

---

### 5.3 Crop Calendar (`agri_calendar/`)

**Calendar generation flow:**
1. Validate crop name against known list
2. Load lifecycle data from `crop_data_accurate.py` (ICAR-sourced)
3. Calculate scheduled dates by adding day offsets to the sowing date
4. Run `scheduler.auto_reschedule_calendar()` — checks 7-day weather forecast
5. Save to Firestore via `calendar_db_service.py`

**Supported crops in calendar:**
- Tomato (90 days, 20+ activities)
- Potato, Corn, Wheat, Rice, Cotton, Sugarcane, Chilli, Onion (varying durations)

**Weather rescheduling:**
- Calls WeatherAPI.com for 7-day forecast
- Checks each upcoming activity against crop's `optimal_conditions`
- Recommends delays for: heavy rain (>50mm), frost, extreme heat/cold, high winds
- `scheduler.py` applies delays and logs changes in `reschedulingHistory`

**Crop data sources:** ICAR-IIHR Bangalore, University of Agricultural Sciences Bangalore, Karnataka Department of Agriculture — cited per activity.

---

### 5.4 Predictive Analysis Engine (`prediction/prediction_engine.py`)

The most sophisticated backend module. Generates disease risk alerts per crop.

**Input:** userId, lat, lng, optional crops list  
**Output:** Per-crop alert objects with risk level, weather correlation, case count

**Algorithm:**

```
1. Resolve lat/lng → district/village (Google Geocoding)
2. Fetch user's registered crops from Firestore
3. Query Firestore diagnoses within 25km radius, last 30 days
4. Query community posts with analysis data in same radius
5. For each nearby case:
   a. Calculate distance-based weight: weight = e^(-distance / 10km)
   b. Look up DISEASE_SEVERITY score for that disease
   c. Compute base_risk = Σ(case_weight × severity) × crop_susceptibility
   d. Fetch weather forecast; calculate weather_multiplier:
      - Temperature match, humidity match, rain probability
   e. Final risk = base_risk × (1 + 0.6×weather_mult + 0.4×severity_mult)
6. Classify: HIGH (≥0.65), MEDIUM (≥0.35), LOW (<0.35)
7. Use Gemini to generate 2-3 sentence "communicability reasoning" per alert
8. Return sorted alerts + weather summary
```

**Key constants:**
- Search radius: 25 km
- Lookback window: 30 days
- Distance decay constant: 10 km
- Minimum cases for alert: 1
- Risk weights: Weather 60%, Severity 40%

**Crop susceptibility scores** (0–1):
- Tomato: 1.0, Potato: 0.9, Grape: 0.85, Corn: 0.7, Wheat: 0.5

---

### 5.5 Location Service (`location/location_service.py`)

- `reverse_geocode(lat, lng)` → Google Geocoding API → extracts state, district, village from address components
- `normalize_location(lat, lng)` → wraps above + adds geohash (precision 6 = ~1.2km cell)
- `nearby_search(lat, lng, radius, keyword)` → Google Places Nearby Search
- `get_nearby_agri_stores(location, radius_km)` → searches for "fertilizer shop", "pesticide shop", "agricultural supply store"
- All functions gracefully degrade to mock data if `GOOGLE_MAPS_API_KEY` is not set

---

### 5.6 Firebase / Firestore (`db/`)

**Collections:**
| Collection | Purpose | Key Fields |
|------------|---------|-----------|
| `users` | User profiles | phone (doc ID), name, language, crops, lastActive |
| `diagnoses` | Diagnosis history | userId, crop, disease, confidence, location (with geohash), llm output, timestamp |
| `calendars` | Crop calendars | userId, crop, sowingDate, lifecycle[], reschedulingHistory[] |
| `community` | Forum posts | userId, userName, content, imageUrl, analysisData, likes[], comments[], location |

**Graceful degradation:** All Firestore service functions check `if db is None` and return mock success responses — the app continues to function without Firebase credentials.

---

### 5.7 Backend Environment Variables (`.env`)

```env
GEMINI_API_KEY=...          # Google AI Studio key
WEATHER_API_KEY=...         # WeatherAPI.com key
GOOGLE_MAPS_API_KEY=...     # Google Maps Platform key (Geocoding + Places)
```

---

## 6. Frontend — Deep Dive

### 6.1 App Entry (`main.dart`)

Bootstrap sequence:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `initializeDateFormatting()` — locale-aware date formatting
3. `MultiProvider` wraps the entire app with 4 providers
4. `MaterialApp` with light + dark theme, starts at `LanguageScreen`

---

### 6.2 Screens (20 total)

| Screen | File | Purpose |
|--------|------|---------|
| Language | `language_screen.dart` | First launch — pick EN/HI/TA/TE |
| Login | `login_screen.dart` | Phone number input |
| OTP Verification | `otp_verification_screen.dart` | Simulated OTP (Random 4-digit, shown in SnackBar) |
| Name Input | `name_input_screen.dart` | First-time user name entry |
| Crop Select | `crop_select_screen.dart` | Pick up to 5 crops from 22-item grid |
| Home | `home_screen.dart` | Dashboard with weather card, crop chips, tool grid, bottom nav |
| Camera | `camera_screen.dart` | Live camera feed + gallery picker |
| Image Preview | `image_preview_screen.dart` | Confirm image + trigger analysis |
| Result | `result_screen.dart` | Diagnosis report (disease, treatments, nearby stores) |
| Remedies | `remedies_screen.dart` | Full chemical/organic treatment details |
| Crop Calendar | `crop_calendar_screen.dart` | Generate + view crop activity timeline |
| Fertilizer Calculator | `fertilizer_calculator_screen.dart` | NPK → Urea/DAP/MOP bag count |
| Agri Store | `agri_store_screen.dart` | Nearby stores (map + product catalog) |
| Community | `community_screen.dart` | Forum posts, likes, comments |
| Predictive Analysis | `predictive_analysis_screen.dart` | Risk alert cards with weather correlation |
| Profile | `profile_screen.dart` | User info, edit profile |
| Edit Profile | `edit_profile_screen.dart` | Update name, language, crops |
| Settings | `settings_screen.dart` | Theme toggle, language, help |
| Help & Support | `help_support_screen.dart` | FAQ, contact |
| Calendar (v2) | `calendar_screen.dart` | Alternate calendar view |

---

### 6.3 Providers (State Management)

| Provider | File | State Managed |
|----------|------|--------------|
| `LanguageProvider` | `language_provider.dart` | `currentLocale` (en/hi/ta/te), persisted via SharedPreferences |
| `UserProvider` | `user_provider.dart` | `phone`, `name`, `crops`, login state |
| `ThemeProvider` | `theme_provider.dart` | `themeMode` (light/dark/system) |
| `ConnectivityProvider` | `connectivity_provider.dart` | `isOnline` bool, polls every 10 seconds |

---

### 6.4 Services

| Service | File | Responsibility |
|---------|------|---------------|
| `ApiService` | `api_service.dart` | All HTTP calls to Flask backend; handles web vs Android URL differences |
| `AuthService` | `auth_service.dart` | Login, OTP (simulated), user session |
| `CalendarService` | `calendar_service.dart` | POST to `/api/calendar/generate` |
| `CommunityService` | `community_service.dart` | GET/POST community posts, likes, comments |
| `WeatherService` | `weather_service.dart` | GET `/api/weather/current` |
| `AiService` | `ai_service.dart` | (Legacy) direct Gemini calls from Flutter |
| `SensorService` | `sensor_service.dart` | Device barometer/accelerometer access |
| `OfflineService` | `offline_service.dart` | Connectivity check, offline diagnosis, calendar cache |

**Base URL logic in `ApiService`:**
```dart
if (kIsWeb)          → "http://127.0.0.1:5001/api"
if (Android emulator) → "http://10.0.2.2:5001/api"
else (iOS/desktop)   → "http://127.0.0.1:5001/api"
```

---

### 6.5 Models

| Model | File | Represents |
|-------|------|-----------|
| `DiagnosisResponse` | `diagnosis_response.dart` | Full diagnosis result + LLM output + nearby stores |
| `DiagnosisLLM` | *(inner class)* | disease_overview, why, chemical/organic treatments, prevention |
| `NearbyStore` | *(inner class)* | Store name, address, distance, phone |
| `CropItem` | `crop_item.dart` | Crop name key, image path, color, isSelected |
| `CommunityPost` | `community_post.dart` | Post content, author, likes, comments, imageUrl, analysisData |
| `PredictionAlert` / `PredictionResponse` | `prediction_alert.dart` | Risk level, disease name, case count, weather correlation, Gemini reasoning |
| `Product` | `product.dart` | Store product with price, category, seller |
| `CalendarEvent` | `calendar_event.dart` | Calendar UI event object |
| `DiseaseData` | `disease_data.dart` | Static disease info model |

---

### 6.6 Translations (`utils/translations.dart`)

A static `AppTranslations.getText(langCode, key)` lookup. Contains 874 lines covering 4 languages:

- `en` — English (base)
- `hi` — Hindi
- `ta` — Tamil
- `te` — Telugu

Covers all UI strings: general, auth, home, diagnosis, calendar, community, store, settings, predictive analysis, fertilizer calculator, offline messages.

---

### 6.7 Assets

| Asset | Purpose |
|-------|---------|
| `assets/images/` | Crop images (tomato, wheat, rice, potato, corn, apple, etc.) |
| `assets/model/model.tflite` | On-device TFLite disease model |
| `assets/model/labels.txt` | Class label list for TFLite model |
| `assets/offline_data/crop_diseases.json` | Bundled disease DB (Tomato × 9, Potato × 4, Corn × 4, Wheat × 3, Rice × 4 diseases) |

---

## 7. Complete App Flow

### 7.1 Onboarding Flow (First Launch)

```
App Launch
    ↓
LanguageScreen
  [Select: English / Hindi / Tamil / Telugu]
    ↓
LoginScreen
  [Enter 10-digit mobile number]
    ↓
OtpVerificationScreen
  [Enter 4-digit OTP shown in SnackBar — simulated, no real SMS]
  [POST /api/users/login → Firestore upsert]
    ↓
NameInputScreen
  [Enter name for personalization]
    ↓
CropSelectScreen
  [Select up to 5 crops from 22-crop grid]
    ↓
HomeScreen
```

### 7.2 Disease Diagnosis Flow (Online)

```
HomeScreen → Camera tile
    ↓
CameraScreen
  [Live camera or gallery picker]
    ↓
ImagePreviewScreen
  [Preview image]
  [Tap "Analyze"]
    ↓
OfflineService.isOnline() → true
    ↓
ApiService.uploadImage() → POST /api/diagnosis (multipart)
    ↓
[Flask] pipeline.run_pipeline()
  → TF available? NO → Gemini Vision analysis
  → TF available? YES → CNN → Grad-CAM → Gemini LLM
  → Normalize location (Google Geocoding)
  → Save to Firestore (diagnoses collection)
  → Get nearby stores (Google Places)
    ↓
DiagnosisResponse deserialized
    ↓
ResultScreen
  [Disease name + confidence + LLM explanation]
  [Chemical / Organic treatments]
  [Prevention tips]
  [Nearby store cards]
  [Share to Community button]
    ↓
Optional: RemediesScreen (full treatment detail)
Optional: AgriStoreScreen (browse products)
```

### 7.3 Disease Diagnosis Flow (Offline)

```
ImagePreviewScreen
  [Tap "Analyze"]
    ↓
OfflineService.isOnline() → false
    ↓
_analyzeImageOffline()
    ↓
Dialog 1: "Offline Mode" — Select crop
  [Tomato / Potato / Corn / Wheat / Rice]
    ↓
Dialog 2: Select symptom/disease
  [Lists all diseases for that crop from bundled JSON]
    ↓
OfflineService.buildOfflineDiagnosisResponse()
    ↓
ResultScreen (isOffline: true)
  [Orange "OFFLINE MODE" banner]
  [Pre-loaded treatment info — no AI, no confidence score]
```

### 7.4 Crop Calendar Flow

```
HomeScreen → Calendar tile
    ↓
CropCalendarScreen
  [Select crop from dropdown: Tomato / Potato / Corn]
  [Pick sowing date]
  [Tap "Generate Schedule"]
    ↓
_generateSchedule():
  1. OfflineService.isOnline()?
     │
     ├─ OFFLINE → OfflineService.getCachedCalendar()
     │    ├─ Cache exists → show with "Cached on [date]" badge
     │    └─ No cache → Snackbar: "Go online to generate first"
     │
     └─ ONLINE → CalendarService.generateCalendar()
          → POST /api/calendar/generate
          → [Flask] calendar_service.generate_calendar()
          → scheduler.auto_reschedule_calendar() (weather check)
          → Save to Firestore
          → On success: OfflineService.cacheCalendar() (for offline use)
          → On failure: try cached version
    ↓
Timeline view
  [Activity cards sorted by date]
  [Categories: planting / irrigation / fertilization / pest-control / maintenance / harvest]
  [Yellow banner if showing from cache]
```

### 7.5 Predictive Analysis Flow

```
HomeScreen → Predictive Alerts tile (disabled when offline)
    ↓
PredictiveAnalysisScreen
    ↓
ApiService.fetchPredictionAlerts(userId, lat, lng)
  → POST /api/prediction/alerts
    ↓
[Flask] prediction_engine.generate_alerts()
  → Query Firestore: nearby diagnoses (25km, 30 days)
  → Query Firestore: community posts with analysisData
  → Fetch weather: WeatherAPI.com
  → Score each disease per crop:
      risk = Σ(case_weight × severity) × susceptibility × weather_mult
  → Ask Gemini: "Explain communicability risk in 2 sentences"
  → Return sorted alerts
    ↓
PredictionResponse deserialized
    ↓
Alert cards:
  [HIGH risk: red card]
  [MEDIUM risk: orange card]
  [LOW risk: yellow card]
  [Each: disease name, case count, affected area, weather factor, Gemini reasoning]
```

### 7.6 Community Flow

```
HomeScreen → Community tab (bottom nav)
    ↓
CommunityScreen
  → GET /api/community/posts?limit=20
    ↓
Post cards with:
  [Author name + phone]
  [Content text]
  [Optional image]
  [Optional analysisData (linked to a diagnosis)]
  [Like count + comment count]
    ↓
Actions:
  [Like → POST /api/community/posts/:id/like]
  [Comment → POST /api/community/posts/:id/comment]
  [New Post → FAB → bottom sheet with text input]
    ↓
From ResultScreen: "Share to Community" button
  → Pre-fills post with diagnosis analysis data
```

---

## 8. Feature Breakdown

### 8.1 Fertilizer Calculator (Fully Offline)

Pure local calculation. No network call.

| Input | Output |
|-------|--------|
| Crop (Wheat/Rice/Corn/Potato/Tomato) | Urea bags needed |
| Farm area (acres) | DAP bags needed |
| | MOP bags needed |

**Formula:**
- DAP bags = (Total P required / 0.46) / 50kg
- Urea bags = (Remaining N after DAP / 0.46) / 50kg
- MOP bags = (Total K required / 0.60) / 50kg

NPK requirements per acre (kg): Wheat 50:25:20, Rice 40:20:20, Corn 60:30:20, Potato 60:40:40, Tomato 50:25:25

---

### 8.2 Agri Store Screen

Two tabs:
1. **Nearby Stores** — fetches from `POST /api/stores` using device GPS → Google Places → displays store cards with name, address, distance, rating, directions button (opens Google Maps)
2. **Product Catalog** — hardcoded mock products in 3 categories: Fertilizers, Seeds, Tools; filterable by category; "Call Seller" button opens phone dialer

---

### 8.3 Multi-language System

`AppTranslations.getText(langCode, key)` returns the string for the current locale. If a key is missing in a non-English locale, it falls back to English. Language preference is persisted in `SharedPreferences` and restored on next launch via `LanguageProvider`.

---

### 8.4 Theme System

`ThemeProvider` controls `ThemeMode.light / ThemeMode.dark / ThemeMode.system`. Dark theme has `#121212` scaffold background, `#1F1F1F` app bar and cards. Toggle in Settings screen.

---

## 9. Data Models

### DiagnosisResponse (Flutter)
```
DiagnosisResponse
├── diagnosisId: String
├── crop: String
├── predictedDisease: String   (raw: "Tomato___Early_blight")
├── displayLabel: String       (formatted: "Tomato Early blight")
├── confidence: double
├── isHealthy: bool
├── llm: DiagnosisLLM?
│   ├── diseaseOverview: String
│   ├── whyThisPrediction: String
│   ├── chemicalTreatments: List<String>
│   ├── organicTreatments: List<String>
│   └── preventionTips: List<String>
└── nearbyStores: List<NearbyStore>
    └── NearbyStore: { name, address, distance, phone, rating, placeId }
```

### Firestore Diagnosis Document
```json
{
  "userId": "9876543210",
  "crop": "Tomato",
  "disease": "Tomato___Early_blight",
  "confidence": 0.93,
  "location": {
    "lat": 12.97, "lng": 77.59,
    "state": "Karnataka", "district": "Bangalore",
    "village": "Whitefield", "geohash": "tdr1wz"
  },
  "explainability": { "method": "Grad-CAM", "summary": "..." },
  "llm": { "disease_overview": "...", ... },
  "timestamp": "2026-03-06T..."
}
```

### Offline Disease JSON Structure
```json
{
  "Tomato": [
    {
      "diseaseName": "Tomato___Early_blight",
      "displayLabel": "Tomato Early Blight",
      "isHealthy": false,
      "diseaseOverview": "...",
      "whyThisPrediction": "...",
      "chemicalTreatments": ["..."],
      "organicTreatments": ["..."],
      "preventionTips": ["..."]
    }
  ]
}
```
Contains 5 crops × 3–9 diseases = ~24 disease entries total.

---

## 10. API Reference

### `POST /api/users/login`
```json
Request:  { "phone": "9876543210", "name": "Ramesh", "language": "en", "crops": ["Tomato"] }
Response: { "userId": "9876543210", "status": "user_saved" }
```

### `POST /api/diagnosis`
```
Request:  multipart/form-data — image file, userId, lat, lng
Response: DiagnosisResponse JSON (see model above)
Error 400: { "error": "Not a Plant Image", "message": "...", "suggestion": "..." }
```

### `POST /api/calendar/generate`
```json
Request:  { "userId": "...", "crop": "Tomato", "sowingDate": "2026-03-01", "lat": 12.9, "lng": 77.5 }
Response: { "calendarId": "...", "calendar": { "lifecycle": [...], "optimalConditions": {...} } }
```

### `POST /api/stores`
```json
Request:  { "lat": 12.97, "lng": 77.59 }
Response: [ { "name": "...", "address": "...", "distance": 2.3, "rating": 4.5, "placeId": "..." } ]
```

### `GET /api/community/posts?limit=20`
```json
Response: [ { "postId": "...", "userId": "...", "userName": "...", "content": "...", "imageUrl": null, "likes": [], "comments": [] } ]
```

### `POST /api/prediction/alerts`
```json
Request:  { "userId": "...", "lat": 12.97, "lng": 77.59, "crops": ["Tomato"] }
Response: {
  "alerts": [ { "crop": "Tomato", "disease": "...", "riskLevel": "HIGH", "riskScore": 0.72, "casesNearby": 3, "weatherFactor": 0.8, "reasoning": "..." } ],
  "weather": { "temp_c": 28, "humidity": 85, "condition": "Partly cloudy" },
  "crops_monitored": ["Tomato"],
  "generated_at": "2026-03-06T..."
}
```

### `GET /api/weather/current?lat=12.97&lng=77.59`
```json
Response: { "temp_c": 28.0, "condition": "Partly cloudy", "humidity": 72, "wind_kph": 14.4, "location": "Bangalore" }
```

---

## 11. Offline Functionality

Three-tier offline strategy implemented across `OfflineService`, `ConnectivityProvider`, `HomeScreen`, `ImagePreviewScreen`, `ResultScreen`, and `CropCalendarScreen`.

### Connectivity Detection
- `ConnectivityProvider` polls `OfflineService.isOnline()` every 10 seconds
- `isOnline()` pings `http://127.0.0.1:5001/` with a 4-second timeout
- "Online" = backend reachable. Backend being down implies external APIs (Gemini, Weather) are also inaccessible.

### Feature Behaviour by Connectivity

| Feature | Online | Offline |
|---------|--------|---------|
| Home screen | Normal | Yellow banner + grayed-out tiles |
| Disease Diagnosis | Full AI pipeline → result | Crop picker → disease picker → pre-loaded result |
| Crop Calendar | Generate + cache result | Load from SharedPreferences cache |
| Agri Store | Live Google Places | Disabled (grayed tile) |
| Predictive Alerts | Live Firestore + Gemini | Disabled (grayed tile) |
| Community | Live Firestore | Disabled (tile navigates, API fails) |
| Fertilizer Calc | Local only | Fully works (no network needed) |
| Weather card | Live WeatherAPI | Fails silently (no banner) |

### Calendar Cache Fallback
`_generateSchedule()` has a 3-stage fallback:
1. Try online generation
2. If online fails → load cache → show orange "showing cached calendar" toast
3. If offline + no cache → orange "generate online first" toast

### Offline Diagnosis Assets
`assets/offline_data/crop_diseases.json` is bundled at build time. No network request. Updated only with app updates.

---

## 12. State Management

```
MultiProvider
├── LanguageProvider     → locale string, persisted in SharedPreferences
├── UserProvider         → phone, name, crops list
├── ThemeProvider        → ThemeMode enum, persisted
└── ConnectivityProvider → isOnline bool, Timer.periodic(10s)
```

All providers use `ChangeNotifier` + `notifyListeners()`. Consumed via `Provider.of<T>(context)` or `Consumer<T>`.

---

## 13. Configuration & Environment

### Running the Backend
```powershell
cd backend
.venv\Scripts\python.exe app.py
# Starts on http://0.0.0.0:5001
```

Requires:
- `backend/.env` with three API keys
- `backend/db/firebase-key.json` for Firestore (gracefully degrades without it)
- `backend/doc_feature/model/plant_disease_model.h5` for local CNN (gracefully falls back to Gemini Vision)

### Running the Frontend
```powershell
cd frontend
flutter run -d chrome          # Web (development)
flutter build web --release    # Production web build
flutter run -d android         # Android
```

### Key Dependency Note
`image_picker` is pinned to exact version `1.0.7` via `dependency_overrides` because `1.2.1` requires Dart >3.6 which is incompatible with Flutter 3.27.2's Dart 3.6.1.

---

## 14. Known Issues & Limitations

| Issue | Severity | Notes |
|-------|----------|-------|
| OTP is simulated | Low | No real SMS gateway. OTP shown in SnackBar. Production would use Firebase Auth or Twilio. |
| `setState after dispose` in `CropCalendarScreen` and `PredictiveAnalysisScreen` | Medium | `mounted` guards added to calendar screen; predictive analysis screen still has the warning. |
| Community screen `RenderFlex overflow` | Low | 14px overflow in `FlexibleSpaceBar` on smaller screens. Pre-existing layout issue. |
| `isOnline()` is backend-ping only | Medium | Turning off WiFi while backend is locally running will show app as "online". By design — but unintuitive. |
| `result_screen.dart` unused methods | Low | `_buildBulletPoint` and `_getFallbackRemedy` are declared but never called. Pre-existing dead code. |
| Gemini rate limits | Medium | Free tier API keys hit 429 quickly on repeated diagnoses. Handled by exponential backoff + model fallback. |
| No real user authentication | Medium | Phone is used as userId key. No password, no token. Production would require proper auth. |
| Offline mode disease list is manual/static | Low | `crop_diseases.json` needs manual updating when new diseases are added to the backend model. |
| Google Maps API required for full store/location | Low | All location features gracefully fall back to mock data without the key. |
| TFLite model unused in frontend | Low | `assets/model/model.tflite` is bundled but diagnosis uses backend API, not on-device inference via `flutter_tflite`. |

---

*Report generated: March 6, 2026*  
*Branch: `sub` — 35 commits ahead of `origin/main`*  
*Codebase size: ~8,000 lines Dart / ~3,500 lines Python*
