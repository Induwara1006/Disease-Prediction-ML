# How to Run the Disease Prediction App

## Backend Setup (Do this FIRST)

1. **Navigate to backend folder:**
   ```powershell
   cd backend
   ```

2. **Ensure dependencies are installed:**
   ```powershell
   python -m pip install -r requirements.txt
   ```

3. **Start the Flask server:**
   ```powershell
   python app.py
   ```
   
   ✅ You should see: `Running on http://127.0.0.1:5000` and your network IP (e.g., `http://10.163.39.202:5000`)

## Frontend Setup - Choose Your Device

### Option A: Android Emulator (Android Studio AVD)

**Important:** The emulator uses a special IP `10.0.2.2` to reach your host machine's `127.0.0.1`.

1. **Navigate to Flutter app:**
   ```powershell
   cd frontend/disease_prediction_app
   ```

2. **Start the emulator** from Android Studio

3. **Run the app:**
   ```powershell
   flutter run
   ```
   
   The app will automatically use `http://10.0.2.2:5000` for the Android emulator.

### Option B: Physical Android Device (via USB or WiFi)

**Prerequisites:** Your phone and PC must be on the **same WiFi network**

1. **Find your PC's IP address:**
   ```powershell
   ipconfig
   ```
   Look for "IPv4 Address" under your active WiFi/Ethernet adapter (e.g., `10.163.39.202`)

2. **Navigate to Flutter app:**
   ```powershell
   cd frontend/disease_prediction_app
   ```

3. **Run with custom API URL:**
   ```powershell
   flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:5000
   ```
   
   Example:
   ```powershell
   flutter run --dart-define=API_BASE_URL=http://10.163.39.202:5000
   ```

### Option C: Web Browser

1. **Navigate to Flutter app:**
   ```powershell
   cd frontend/disease_prediction_app
   ```

2. **Run for web:**
   ```powershell
   flutter run -d chrome
   ```
   
   The app will automatically use `http://127.0.0.1:5000`.

## Troubleshooting

### "Analyzing symptoms..." hangs indefinitely

**Check 1:** Is the backend running?
- Look for the terminal where you ran `python app.py`
- You should see Flask debug output

**Check 2:** Are you using the correct API URL?
- **Emulator:** Must use `http://10.0.2.2:5000` (automatic)
- **Physical device:** Must use your PC's actual IP like `http://10.163.39.202:5000`
- **Web/Desktop:** Uses `http://127.0.0.1:5000` (automatic)

**Check 3:** Network connectivity
- For physical devices, ensure both device and PC are on the same WiFi
- Check Windows Firewall isn't blocking port 5000

**Check 4:** View debug logs
- In the Flutter app, check the console/terminal output
- Look for lines starting with 🔍, 📋, ✅, ⏱️, 🔌, or ❌
- These will show exactly what URL is being called and any errors

### Test Backend Manually

From PowerShell:
```powershell
$body = @{symptoms=@('skin_rash','high_fever')} | ConvertTo-Json
Invoke-WebRequest -Uri 'http://127.0.0.1:5000/predict' -Method POST -ContentType 'application/json' -Body $body -UseBasicParsing | Select-Object -ExpandProperty Content
```

You should see a JSON response with predictions.

## Notes

- The backend now runs on `0.0.0.0:5000` which means it accepts connections from your local network
- The app has a 10-second timeout - if predictions don't return in 10s, you'll see an error
- Debug mode will print detailed logs about API calls in the Flutter console
