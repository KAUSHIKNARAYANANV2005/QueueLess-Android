# QueueLess 🚀

> **Skip the Wait, Not the Visit.***
> Smart queue management for clinics, salons, banks, and government offices.

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange.svg)](https://firebase.google.com)
[![Razorpay](https://img.shields.io/badge/Payments-Razorpay-blue.svg)](https://razorpay.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📱 Features

| Feature | Description |
|---------|-------------|
| 🗺️ **Live Map** | Find businesses near you with real-time queue counts |
| 📅 **Smart Booking** | AI recommends the least busy time to visit |
| ⏱️ **Queue Tracking** | See your position live — get notified when you're next |
| 🤖 **QueueBot AI** | Chat with Gemini/Ollama AI to book, cancel or check status |
| 💳 **Razorpay Payments** | UPI, Card, NetBanking, Wallets — all secured |
| 👔 **Business Dashboard** | Manage queues, staff, services, and analytics |
| 👑 **Admin Panel** | Platform-wide analytics and user management |

---

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.22+ (Dart)
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **Maps**: Google Maps Flutter + Geolocator
- **Payments**: Razorpay Flutter SDK
- **AI**: Google Gemini 1.5 Flash + Ollama (local LLM)
- **Web**: HTML/CSS/JS landing page (`webapp/`)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.22+
- Android Studio / VS Code
- Firebase project (see setup below)

### 1. Clone & install
```bash
git clone https://github.com/your-org/queueless.git
cd queueless
flutter pub get
```

### 2. Firebase Setup
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create project `queueless`
3. Add **Android app** with package `com.queueless.queueless`
4. Download `google-services.json` → place in `android/app/`
5. Enable: **Authentication** (Email, Phone, Google), **Firestore**, **Storage**, **Messaging**
6. Deploy Firestore rules: `firebase deploy --only firestore:rules`

### 3. Google Maps API Key
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Enable: Maps SDK for Android, Places API, Geocoding API
3. Create API key → copy it
4. Open `android/app/src/main/AndroidManifest.xml`
5. Replace `YOUR_MAPS_API_KEY` with your key

### 4. Razorpay
1. Go to [dashboard.razorpay.com](https://dashboard.razorpay.com)
2. Settings → API Keys → **Generate Test Key**
3. Open `lib/core/services/razorpay_service.dart`
4. Replace `YOUR_RAZORPAY_KEY_ID` with your key

### 5. Gemini AI (optional — works without it)
1. Go to [makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)
2. Create API key
3. Open `lib/features/ai/services/gemini_service.dart`
4. Replace `YOUR_GEMINI_API_KEY`

### 6. Run the app
```bash
flutter run                    # Debug on device/emulator
flutter build apk --release    # Release APK
flutter build appbundle        # For Play Store
```

---

## 🔑 API Keys Required

| Service | File | How to Get |
|---------|------|-----------|
| Google Maps | `android/app/src/main/AndroidManifest.xml` | Google Cloud Console |
| Razorpay | `lib/core/services/razorpay_service.dart` | Razorpay Dashboard |
| Gemini AI | `lib/features/ai/services/gemini_service.dart` | Google AI Studio (free) |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── services/
│   │   ├── firebase_service.dart     # All Firestore operations
│   │   ├── location_service.dart     # GPS + distance calculation
│   │   └── razorpay_service.dart     # Payment processing
│   ├── theme/
│   │   └── app_theme.dart            # Design system tokens
│   └── utils/
│       └── nav_helper.dart           # AppBackButton + safePop()
├── features/
│   ├── auth/screens/                 # Login, Register, OTP, Splash
│   ├── customer/screens/             # Home, Map, Booking, Profile
│   ├── business/screens/             # Dashboard, Queue, Staff
│   ├── admin/screens/                # Super panel, Reports
│   └── ai/
│       ├── screens/                  # QueueBot chatbot UI
│       └── services/gemini_service.dart  # AI backend
├── shared/
│   └── widgets/                      # PremiumButton, AnimatedCard, etc.
└── routes/
    └── app_router.dart               # GoRouter configuration

android/
├── app/
│   ├── google-services.json          # Firebase config (not in git)
│   ├── queueless-release.jks         # Keystore (not in git)
│   └── proguard-rules.pro            # Release build rules
└── key.properties                    # Signing config (not in git)

webapp/                               # Web landing page
├── index.html
├── styles.css
└── app.js

test/
└── widget_test.dart                  # 16 tests (all passing)
```

---

## 🧪 Tests

```bash
flutter test                          # Run all 16 tests
flutter analyze                       # Code analysis (0 errors)
```

**Test coverage:**
- `LocationService` — distance math, label formatting
- `GeminiService` — 6 intent detection scenarios
- Widget smoke tests — renders, interactions
- Model validation

---

## 🚀 Deployment

### Android (Play Store)
```bash
flutter build appbundle --release     # Builds .aab for Play Store
```
Upload to [play.google.com/console](https://play.google.com/console)

### Web App
```bash
cd webapp
# Deploy to Firebase Hosting:
firebase deploy --only hosting
# Or just open index.html in browser for local preview
```

### Firestore Rules
```bash
firebase deploy --only firestore:rules
```

---

## 📞 Support

Built by **QueueLess Technologies Pvt. Ltd.**
- Website: [queueless.app](https://queueless.app)
- Email: support@queueless.app
- Play Store: Coming soon

---

## 📄 License

MIT License — see [LICENSE](LICENSE) file.
