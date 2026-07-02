Prerequisites (Ensure these are installed on the new laptop)
Python (version 3.10 or higher) -> Download Python
Flutter SDK (version 3.x stable) -> Flutter Installation Guide
Step 1: Set Up the Backend (Django DRF)
Open a terminal (PowerShell or Command Prompt) and run these commands:

Navigate into the backend folder:
powershell


cd "path\to\your\cloned-repo\backend"
Create a new Python Virtual Environment:
powershell


python -m venv venv
Activate the virtual environment:
On Windows (PowerShell):
powershell


.\venv\Scripts\activate
On Windows (Command Prompt):
cmd


.\venv\Scripts\activate.bat
On Mac/Linux:
bash


source venv/bin/activate
Install all the required packages:
powershell


pip install -r requirements.txt
Apply database migrations to build the SQLite database locally:
powershell


python manage.py migrate
Seed the default test database (creates Admin, Owner, and Customer logins):
powershell


python manage.py seed_data
Start the backend server:
powershell


python manage.py runserver 0.0.0.0:8000
Step 2: Set Up the Frontend (Flutter)
Keep the backend terminal running, open a new terminal window, and perform these steps:

Navigate to the frontend directory:
powershell


cd "path\to\your\cloned-repo\frontend"
Check your target configuration in 
api_service.dart
:
If running on Android Emulator, change baseUrl to http://10.0.2.2:8000/api/v1
If running on Windows Desktop or iOS Simulator, leave it as http://127.0.0.1:8000/api/v1
Fetch the Flutter packages:
powershell


flutter pub get
Run the application:
powershell


flutter run
Select your browser, desktop, or connected emulator to start viewing the UI.
Step 3: Test Profiles
Log in with these credentials once the app opens:

Admin Control: admin / admin123
Futsal Owner: owner / owner123
Customer: customer / customer123
