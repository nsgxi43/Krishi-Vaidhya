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

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Configure environment variables in `.env` file

4. Run the Flask application:
   ```bash
   python app.py
   ```

### Frontend Setup

1. Navigate to the frontend directory:
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
