# Flutter App Setup & Testing Guide

## ✅ What You Have

A complete Flutter app with:
- ✔ Search + multi-select symptom selection
- ✔ Backend API integration
- ✔ Real-time disease prediction
- ✔ Professional UI

## 🚀 How to Run

### 1. Start Backend First (IMPORTANT)

Open terminal in your backend folder:
```bash
cd Downloads/Disease-Prediction-ML/backend
python app.py
```

**Verify backend is running:**
```
* Running on http://127.0.0.1:5000
```

### 2. Run Flutter App

In the Flutter project directory:
```bash
flutter run
```

## 📱 Testing URLs

### Android Emulator
The app uses: `http://10.0.2.2:5000/predict`
- `10.0.2.2` = localhost for Android emulator

### Real Android Phone
1. Find your PC's IP address:
   ```bash
   ipconfig
   ```
   Look for IPv4 Address (e.g., `192.168.1.10`)

2. Update `main.dart` line 90:
   ```dart
   Uri.parse("http://YOUR_PC_IP:5000/predict")
   ```
   Example: `http://192.168.1.10:5000/predict`

3. Make sure phone and PC are on the same WiFi network

## 🧪 How to Test

1. **Start Backend** (python app.py)
2. **Run Flutter App** (flutter run)
3. **Select Symptoms:**
   - Search "fever"
   - Check: fever, headache, muscle_pain
4. **Click "Predict Disease"**
5. **View Result:**
   - Predicted disease
   - Confidence %
   - Top 3 diseases

## ❌ Common Issues & Fixes

### "Could not connect to backend"
✔ Backend not running → Start Flask server
✔ Wrong URL → Use 10.0.2.2 for emulator
✔ Firewall → Allow port 5000

### Symptoms don't match
✔ Symptom names MUST exactly match backend
✔ Use snake_case: `high_fever` not `High Fever`

## 📦 Building APK

Once testing works:
```bash
flutter build apk --release
```

APK location:
```
build/app/outputs/flutter-apk/app-release.apk
```

## 🎓 Project Status

✅ ML Model trained (97.6% accuracy)
✅ Flask backend deployed
✅ Flutter app connected
✅ Ready for demo & APK build

## 🔜 Next Steps

1. ✅ Test app with emulator
2. ⏳ Deploy backend online (optional)
3. ⏳ Add Firebase login (optional)
4. ⏳ Build final APK
