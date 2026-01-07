<img width="353" height="777" alt="Screenshot 2026-01-07 at 4 23 47 PM" src="https://github.com/user-attachments/assets/48700ef9-36db-4c34-b903-f67479fcc8db" />


```md
# Network Monitor (Flutter + Android Platform Channels)

A clean and lightweight **Network Monitor** app built with **Flutter (Material 3)** and **native Android (Kotlin)** using **Platform Channels**—without using any third-party connectivity packages.

This project demonstrates:
- **EventChannel** for real-time network change updates (stream-based)
- **MethodChannel** for one-time current status check (request-response)

---

## ✅ Features

- ✅ Real-time connection changes via **EventChannel**
- ✅ Manual **Re-check** via **MethodChannel**
- ✅ Material 3 UI with:
  - Online/Offline pill indicator
  - Animated state transitions
  - Snackbars for status updates
- ✅ Internet validation on Android (API 23+):
  - `NET_CAPABILITY_INTERNET`
  - `NET_CAPABILITY_VALIDATED` (ensures actual internet access)

---

## 🧩 Tech Stack

- Flutter (Dart)
- Android (Kotlin)
- Platform Channels:
  - `EventChannel('app.network/events')`
  - `MethodChannel('app.network/methods')`
- Android Networking:
  - `ConnectivityManager`
  - `NetworkCallback`
  - `NetworkCapabilities`

---

## 📌 Channel Names (Must Match Exactly)

| Type | Name |
|------|------|
| EventChannel | `app.network/events` |
| MethodChannel | `app.network/methods` |

---

## 📂 File Layout

Recommended file structure:

```

lib/
main.dart
network_channel.dart

android/app/src/main/kotlin/<your_package>/
MainActivity.kt

```

Example package path:
```

android/app/src/main/kotlin/com/example/net_monitor_flutter/MainActivity.kt

````

---

## ⚙️ Setup Instructions

### 1) Create a Flutter Project
```bash
flutter create net_monitor_flutter
cd net_monitor_flutter
````

### 2) Replace / Add Dart Files

#### ✅ `lib/main.dart`

Paste your full UI code here.

#### ✅ `lib/network_channel.dart`

Paste your full NetworkChannel code here.

### 3) Add Kotlin MainActivity

Go to:

```
android/app/src/main/kotlin/<your_package>/
```

Replace `MainActivity.kt` with your Kotlin code.

> ⚠️ Important: the first line of Kotlin must match your package:

```kotlin
package com.example.net_monitor_flutter
```

If your package differs, update it accordingly and ensure folder structure matches.

---

## ▶️ Run the App

```bash
flutter pub get
flutter run
```

---

## 🧪 Testing Checklist

Try these and observe UI + snackbar:

* Turn **Wi-Fi** ON/OFF
* Turn **Mobile Data** ON/OFF
* Enable **Airplane Mode**
* Connect to a Wi-Fi that has **no internet**
* Tap **Re-check** button

---

## 🧠 How It Works (Professional Explanation)

### ✅ EventChannel (Realtime Stream)

Flutter listens using:

```dart
NetworkChannel.changes().listen(...)
```

Android responds:

* registers `ConnectivityManager.NetworkCallback`
* pushes updates via:

```kotlin
sink?.success("connected" / "disconnected")
```

This makes it perfect for **continuous monitoring**.

---

### ✅ MethodChannel (One-time Request)

Flutter calls:

```dart
await NetworkChannel.current();
```

Android returns:

```kotlin
result.success(currentStatus())
```

This is perfect for **manual refresh** or **initial check**.

---

## 📶 Status Logic (Android Side)

### Android API 23+ (Recommended)

We check:

* `NET_CAPABILITY_INTERNET`
* `NET_CAPABILITY_VALIDATED`

Only if both are true → `connected`

This prevents false positives like:
✅ Wi-Fi connected
❌ but no real internet access

### Android < 23

Fallback:

* `activeNetworkInfo.isConnected`

---

## 🧵 Important: Main Thread Delivery

Platform events must be sent on the **main thread**.

This project ensures it using:

```kotlin
mainHandler.post {
  sink?.success(status)
}
```

---

## 🛡️ Anti-Spam / Duplicate Guard

To prevent pushing the same status repeatedly:

```kotlin
if (status == last) return
last = status
```

---

## ❗ Common Issues & Fix

### 1) No stream updates

Check:

* channel names match exactly
* Kotlin file package + folder path match
* full restart app after Kotlin changes (`flutter run` again)

---

### 2) Always shows disconnected

If your network is not validated (captive portal etc.), it will show disconnected by design.

If you want a looser check, remove:
`NET_CAPABILITY_VALIDATED`
(but accuracy will reduce)

---

## 🚀 Optional Improvements (Next Steps)

* Add iOS support using `NWPathMonitor`
* Detect network type (Wi-Fi vs Mobile)
* Display last change timestamp
* Add logs screen for debugging

---

## 📜 License

Free to use, modify, and integrate into your own apps.

---

## 👤 Author Notes

This project is designed for learning OS-level networking and platform channels
without relying on packages like `connectivity_plus`.

```
```
