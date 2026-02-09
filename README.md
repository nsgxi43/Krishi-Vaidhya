<<<<<<< HEAD
# Krishi-Vaidhya

An intelligent agricultural assistance platform combining AI-powered disease diagnosis, crop management, and community features to help farmers make informed decisions.

## Project Overview

Krishi-Vaidhya is a comprehensive agricultural solution that provides:
- AI-powered crop disease diagnosis and treatment recommendations
- Agricultural calendar with crop management scheduling
- Weather-based insights and reminders
- Community platform for farmers
- Location-based agricultural store recommendations

## Technology Stack

### Backend
- Python/Flask
- Firebase (Authentication & Database)
- Google Gemini AI
- APScheduler for background tasks
- Weather API integration

### Frontend
- Flutter
- Cross-platform mobile application

## Architecture & Design

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

## Project Structure

```
Krishi-Vaidhya/
├── backend/              # Python Flask backend
│   ├── agri_calendar/    # Agricultural calendar and scheduling
│   ├── db/               # Database services and Firebase integration
│   ├── doc_feature/      # Disease diagnosis and ML models
│   ├── location/         # Location services and Google Maps integration
│   └── prediction/       # Community signal processing
├── frontend/             # Flutter mobile application
│   ├── lib/              # Dart source code
│   ├── assets/           # Images and model files
│   └── android/ios/      # Platform-specific code
└── diagrams/             # UML and architecture diagrams
```

## Getting Started

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

=======
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
>>>>>>> a8f018ec985b9b42b169984c7704aa5b2c3b9a79
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
<<<<<<< HEAD

3. Configure environment variables in `.env` file

4. Run the Flask application:
=======
3. Set up your `.env` file with necessary API keys (Gemini, Firebase).
4. Run the server:
>>>>>>> a8f018ec985b9b42b169984c7704aa5b2c3b9a79
   ```bash
   python app.py
   ```

### Frontend Setup
<<<<<<< HEAD

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

=======
1. Navigate to the `frontend/` directory.
>>>>>>> a8f018ec985b9b42b169984c7704aa5b2c3b9a79
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
<<<<<<< HEAD

=======
>>>>>>> a8f018ec985b9b42b169984c7704aa5b2c3b9a79
3. Run the application:
   ```bash
   flutter run
   ```
<<<<<<< HEAD

## Features

- **Disease Diagnosis**: Upload crop images for AI-powered disease detection and treatment recommendations
- **Agricultural Calendar**: Automated scheduling based on crop types and regional data
- **Weather Integration**: Real-time weather updates and farming recommendations
- **Community Platform**: Connect with other farmers, share experiences and solutions
- **Smart Reminders**: Timely notifications for farming activities
- **Store Locator**: Find nearby agricultural stores and services

## License

[Add your license information here]

## Contributors

[Add contributor information here]
=======
>>>>>>> a8f018ec985b9b42b169984c7704aa5b2c3b9a79
