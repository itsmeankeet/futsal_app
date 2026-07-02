# How to Run on a Physical Mobile Device (Android)

Follow this step-by-step guide to run and test the Futsal Booking App directly on your physical mobile phone.

---

## Step 1: Connect Phone & PC to the Same Wi-Fi Network
To allow the mobile app to communicate with the Django backend server running on your computer:
1. Ensure your laptop/PC is connected to your local Wi-Fi.
2. Connect your mobile phone to the **exact same Wi-Fi network**.

---

## Step 2: Find Your PC's Local IP Address
1. On your Windows computer, open a **PowerShell** or **Command Prompt** window.
2. Run the command:
   ```cmd
   ipconfig
   ```
3. Find your active Wi-Fi adapter (usually labeled `Wireless LAN adapter Wi-Fi` or `Ethernet adapter`).
4. Copy the **IPv4 Address** (it will look like `192.168.1.X` or `10.0.0.X`, e.g., `192.168.1.75`).

---

## Step 3: Configure the API Base URL in Flutter
1. Open the Flutter project in your editor.
2. Open the file [dio_client.dart](file:///d:/futsal_app/frontend/lib/core/network/dio_client.dart).
3. Update `baseUrl` on line 9 by replacing the existing IP with your PC's actual local IPv4 address:
   ```dart
   // Replace "192.168.1.64" with your PC's IP address
   static const String baseUrl = 'http://YOUR_PC_IP:8000/api/v1';
   ```
   *Example:*
   ```dart
   static const String baseUrl = 'http://192.168.1.75:8000/api/v1';
   ```

---

## Step 4: Enable Developer Options & USB Debugging on Your Phone
1. Open the **Settings** app on your Android phone.
2. Scroll to the bottom and tap **About Phone** (or **About Device**).
3. Find **Build Number** (sometimes located under *Software Information*).
4. Tap **Build Number 7 times** in rapid succession. You will see a toast notification saying *"You are now a developer!"*.
5. Go back to main Settings, find **Developer Options** (often located under *System Settings* or *Additional Settings*), and turn it **ON**.
6. Inside Developer Options, scroll down and enable **USB Debugging**.

---

## Step 5: Connect Your Phone to the PC via USB
1. Use a high-quality USB data cable to connect your phone to a USB port on your PC.
2. If prompted on your phone, choose **File Transfer** or **MTP** mode (instead of *Charge Only*).
3. A prompt will appear on your phone screen: *"Allow USB debugging?"*.
4. Check the box **"Always allow from this computer"** and tap **Allow** or **OK**.

---

## Step 6: Start the Django Backend Server
Run the Django backend server with public binding so it accepts requests from other devices on your Wi-Fi network:
1. Open a terminal in the `backend` folder.
2. Activate your virtual environment:
   ```powershell
   .\venv\Scripts\activate
   ```
3. Start the server using `0.0.0.0:8000`:
   ```powershell
   python manage.py runserver 0.0.0.0:8000
   ```

---

## Step 7: Run the Flutter App on Your Phone
1. Open a new terminal in the `frontend` folder.
2. Verify that Flutter detects your physical phone:
   ```powershell
   flutter devices
   ```
   *You should see your mobile phone name and ID in the list.*
3. Launch the application onto your phone:
   ```powershell
   flutter run
   ```
   *If prompted to choose a device, enter the number corresponding to your phone.*
