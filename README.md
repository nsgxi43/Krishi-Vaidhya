# Krishi Vaidhya - AI Crop Disease Doctor 🌿

Krishi Vaidhya is an AI-powered agricultural assistant designed to help farmers diagnose crop diseases, manage planting schedules, and connect with a community of experts and peers.

## 🚀 Features

- **AI Crop Diagnosis**: Upload or capture photos of crop leaves to get instant, AI-powered disease diagnosis and treatment recommendations.
- **Agricultural Calendar**: Generate a personalized sowing-to-harvest calendar based on your crop type, sowing date, and local weather conditions.
- **Community Hub**: Share your findings, ask questions, and interact with other farmers through a social platform including likes and comments.
- **Store Locator**: Find nearby agricultural stores to purchase recommended treatments and supplies within a 10km radius.
- **Environmental Sensing**: Utilizes device sensors (where available) to monitor environmental conditions.
- **Multilingual Support**: Supports multiple languages to reach a wider demographic of farmers.

## 🛠️ Tech Stack

- **Frontend**: Flutter (Android/iOS/Web)
  - `provider` for state management.
  - `google_fonts` for typography.
  - `camera` & `image_picker` for image capture.
  - `flutter_tflite` for edge AI inference.
- **Backend**: Flask (Python)
  - `Firebase` for database (Community, Users, Diagnosis).
  - `Gemini Vision` (via Google Generative AI) for diagnosis.
  - `Flask-CORS` for cross-origin support.
- **Deployment**: Local Flask server with support for external access.

## 📁 Project Structure

```text
Krishi-Vaidhya-main/
├── frontend/             # Flutter application
│   ├── lib/              # Application logic and UI
│   ├── assets/           # Images, AI models, and labels
│   └── pubspec.yaml      # Frontend dependencies
├── backend/              # Flask API server
│   ├── agri_calendar/    # Calendar generation logic
│   ├── doc_feature/      # Diagnosis pipeline and store service
│   ├── db/               # Database service layers
│   ├── static/           # Static assets (community images)
│   └── app.py            # Main API entry point
└── README.md             # This file
```

## 🚗 Quick Start

### Backend Setup
1. Navigate to the `backend/` directory.
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Set up your `.env` file with necessary API keys (Gemini, Firebase).
4. Run the server:
   ```bash
   python app.py
   ```

### Frontend Setup
1. Navigate to the `frontend/` directory.
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```
