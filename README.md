# Krishi Vaidhya - AI Crop Disease Doctor 🌿

Krishi Vaidhya is an AI-powered agricultural assistant designed to help farmers diagnose crop diseases, manage planting schedules, and connect with a community of experts and peers.

## 🚀 Features

- **AI Crop Diagnosis**: Upload or capture photos of crop leaves to get instant, AI-powered disease diagnosis and treatment recommendations
- **Agricultural Calendar**: Generate a personalized sowing-to-harvest calendar based on your crop type, sowing date, and local weather conditions
- **Community Hub**: Share your findings, ask questions, and interact with other farmers through a social platform including likes and comments
- **Store Locator**: Find nearby agricultural stores to purchase recommended treatments and supplies within a 10km radius
- **Environmental Sensing**: Utilizes device sensors (where available) to monitor environmental conditions
- **Multilingual Support**: Supports multiple languages to reach a wider demographic of farmers
- **Weather Integration**: Real-time weather updates and farming recommendations
- **Smart Reminders**: Timely notifications for farming activities

## 🛠️ Tech Stack

### Frontend
- **Flutter** (Android/iOS/Web)
  - `provider` for state management
  - `google_fonts` for typography
  - `camera` & `image_picker` for image capture
  - `flutter_tflite` for edge AI inference

### Backend
- **Flask** (Python)
  - `Firebase` for authentication and database (Community, Users, Diagnosis)
  - `Gemini Vision` (via Google Generative AI) for AI-powered diagnosis
  - `Flask-CORS` for cross-origin support
  - `APScheduler` for background tasks and reminders
  - Weather API integration

## 📐 Architecture & Design

### System Architecture
The following diagram illustrates the overall system architecture and component interactions:

![System Architecture Diagram](System%20Architecture%20Diagram.png)

### Database Schema
Entity-Relationship diagram showing the database structure:

![Database Schema Diagram](Database%20Schema%20Diagram%20(ER%20Diagram).png)

### UML Diagrams

#### Use Case Diagram
High-level view of system functionality and user interactions:

![Use Case Diagram](Use%20Case%20Diagram.png)

#### Class Diagram
Object-oriented structure of the system:

![Class Diagram](Class%20Diagram.png)

#### Sequence Diagram
Interaction flow between system components:

![Sequence Diagram](Sequence%20Diagram.png)

#### Activity Diagram
Workflow and process flows within the application:

![Activity Diagram](Activity%20Diagram.png)

## 📁 Project Structure

```text
Krishi-Vaidhya/
├── frontend/             # Flutter mobile application
│   ├── lib/              # Application logic and UI
│   │   ├── models/       # Data models
│   │   ├── providers/    # State management
│   │   ├── screens/      # UI screens
│   │   └── services/     # API and service layers
│   ├── assets/           # Images, AI models, and labels
│   └── pubspec.yaml      # Frontend dependencies
├── backend/              # Flask API server
│   ├── agri_calendar/    # Calendar generation and scheduling logic
│   ├── doc_feature/      # Diagnosis pipeline and store service
│   ├── db/               # Database service layers (Firebase)
│   ├── location/         # Location services and Google Maps integration
│   ├── prediction/       # Community signal processing
│   ├── static/           # Static assets (community images)
│   └── app.py            # Main API entry point
└── README.md             # This file
```

## 🚀 Quick Start

### Backend Setup

1. Navigate to the `backend/` directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Set up your `.env` file with necessary API keys:
   - Gemini API key
   - Firebase credentials
   - Weather API key (if applicable)

4. Run the Flask server:
   ```bash
   python app.py
   ```

### Frontend Setup

1. Navigate to the `frontend/` directory:
   ```bash
   cd frontend
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## 📝 License

[Add your license information here]

## 👥 Contributors

[Add contributor information here]
