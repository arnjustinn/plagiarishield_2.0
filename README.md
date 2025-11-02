📖 Overview
Plagiarishield is a complete, end-to-end system for detecting plagiarism in text. It consists of two main components:
A Mobile Platform Client App: Built with Flutter, this app is compatible with Android devices. It provides a user-friendly interface for submitting text, viewing reports, and managing scan history.
A Python AI Backend: A custom-trained Keras deep learning model (plagiarism_model_v9_multilingual.keras) served via a Python API. This backend handles the heavy lifting of text analysis and plagiarism scoring.
✨ Core Features
User Authentication: Secure login and signup screens to manage user accounts.
Multiple Input Methods:
Paste raw text directly.
Upload .docx files (text is extracted automatically).
Upload image files (text is extracted using OCR).
Custom AI Model: Uses a custom-trained, multilingual Keras model for high-accuracy plagiarism detection.
Detailed Reports: View detailed plagiarism reports, including similarity scores and potential sources.
Scan History: All previous scans and reports are saved to the user's account (history_screen.dart).
🛠️ Technology Stack
This project is a full-stack application.
Frontend (Client App)
Framework: Flutter (v3.x)
Language: Dart
Core Libraries:
http: For making requests to the backend API.
flutter_secure_storage: For securely storing user credentials.
file_picker: For selecting .docx or image files.
(Inferred) image_picker, google_ml_kit_text_recognition: For OCR capabilities.
Backend (AI & API)
Language: Python
API Framework: Flask / FastAPI (from api_multilingual.py)
AI Framework: TensorFlow / Keras (from .keras model file)
Data Processing: NumPy, Pickle (for tokenizer)
Training Pipeline: The training/ directory includes scripts for data scraping (scrape_real_dataset_bulk.py), preprocessing, and model training (train_multilingual.py).
📂 Project Structure
Here is a high-level overview of the project's layout:
plagiarishield_2.0/
│
├── lib/                      # Main Flutter application source code
│   ├── main.dart             # App entry point
│   ├── screens/              # UI for each app screen (login, home, report, etc.)
│   ├── services/             # Logic for API calls (api_service.dart)
│   ├── storage/              # Local data persistence (credentials, history)
│   └── utils/                # Helper functions (docx_extractor.dart, ocr_helper.dart)
│
├── training/                 # Python backend and AI model
│   ├── api/                  # Python API to serve the model
│   │   ├── api_multilingual.py # The main API file
│   │   └── requirements.txt  # Python dependencies
│   │
│   ├── models/               # The pre-trained AI models
│   │   ├── plagiarism_model_v9_multilingual.keras
│   │   ├── saved_reference_embeddings_multilingual.npy
│   │   └── tokenizer_v9_multilingual.pkl
│   │
│   └── training/             # Scripts used to train the model
│       ├── train_multilingual.py
│       └── ...
│
├── assets/                   # App logos and other static assets
├── android/                  # Android-specific build files
├── ios/                      # iOS-specific build files
├── web/                      # Web-specific build files
├── windows/                  # Windows-specific build files
├── macos/                    # macOS-specific build files
├── linux/                    # Linux-specific build files
└── pubspec.yaml              # Flutter project dependencies



🚀 Getting Started
To run this project, you must set up both the backend API and the frontend Flutter app.
Prerequisites
Flutter SDK (latest stable version)
Python (v3.8 or higher)
A code editor (like VS Code with Flutter & Python extensions)
1. Backend Setup (Python API)
First, get the AI server running.
Navigate to the API directory:
cd "training/api"


Create and activate a Python virtual environment:
# Windows
python -m venv venv
.\venv\Scripts\activate

# macOS / Linux
python3 -m venv venv
source venv/bin/activate


Install Python dependencies:
(You will need to update requirements.txt with the packages used in api_multilingual.py. Common ones are included here.)
pip install -r requirements.txt
[API Framework
flask
flask-cors
AI & Data Processing
tensorflow
numpy
scikit-learn]


Run the API server:
python api_multilingual.py

The server should now be running, typically on http://127.0.0.1:5000.
2. Frontend Setup (Flutter App)
With the backend running, you can now start the Flutter application.
Navigate to the project root directory:
cd /path/to/plagiarishield_2.0/


Get Flutter dependencies:
flutter pub get


Update API URL:
Open lib/services/api_service.dart and make sure the baseUrl variable points to your local backend server.
// in lib/services/api_service.dart (example)
String baseUrl = '[http://127.0.0.1:5000](http://127.0.0.1:5000)';


Run the app:
Select your target device (e.g., Chrome, Android Emulator, Desktop) and run:
flutter run


The Plagiarishield app should launch and be fully connected to your local AI backend.
⚖️ License
This project is licensed under the MIT License. See the LICENSE file for details.
🧑‍💻 Author
Justin Arn - arnjustinn
