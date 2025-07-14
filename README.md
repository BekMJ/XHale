# XHale Health

**XHale Health** is an iOS app for real-time carbon monoxide (CO) and temperature monitoring using a Bluetooth Low Energy (BLE) sensor. Developed for research at the University of Oklahoma Electrical Engineering Department, XHale Health is designed for both academic and personal use, providing a user-friendly interface for safe, accessible, and accurate environmental monitoring.

---

## Features

- **Bluetooth LE Device Discovery & Connection**  
  Scan for, connect to, and manage BLE-enabled CO/temperature sensors. Device info (MAC address, serial number, battery status) is clearly displayed.

- **Real-Time CO & Temperature Monitoring**  
  View live sensor data with a dual y-axis chart (CO in ppm, temperature in °C), color-coded for clarity. Data points are connected for easy trend analysis.

- **Breath Sampling Workflow**  
  Guided breath sample collection with countdown timer, live readings, and clear instructions. Data is visualized and can be exported as CSV for research or record-keeping.

- **Battery Life Indicator**  
  Visual battery icon reflects estimated battery life, accounting for device degradation (80% of 170 hours typical lifespan).

- **User Authentication**  
  Secure login and registration with Firebase Auth. Password reset and account management included.

- **Data Backup & Sync**  
  Sensor readings are uploaded to Firebase Firestore, organized by device and user for secure, cloud-based storage.

- **Accessibility & Design**  
  High-contrast UI, large fonts, and responsive layouts for readability and App Store compliance. Dark mode supported.

- **Onboarding & Tutorial**  
  Step-by-step interactive tutorial guides new users through device setup, scanning, sampling, and data export.

- **Medical Disclaimer & Compliance**  
  Medical disclaimer shown on first login. Privacy Policy and Terms of Service are accessible in-app.

- **Settings & Customization**  
  - Dark mode toggle
  - Adjustable sample duration (5–60 seconds)
  - Battery replacement/reset
  - Privacy Policy, Terms of Service, and account deletion
  - Notification preferences

- **Offline Support**  
  Network monitoring disables cloud sync when offline and re-enables when reconnected.

---

## Getting Started

### Prerequisites
- Xcode 15 or later
- iOS 16.0 or later
- Swift 5.8+
- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)

### Setup
1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   ```
2. **Open the project in Xcode:**
   - Use `XHale Health.xcodeproj`.
3. **Install dependencies:**
   - Ensure CocoaPods or Swift Package Manager is set up for Firebase.
   - Add your `GoogleService-Info.plist` to `XHale/Resources/` (replace the placeholder if needed).
4. **Build and run on a real device:**
   - BLE features require a physical iOS device (not the simulator).

---

## App Structure
- **Home:** Scan/connect to devices, view live data, battery, and device info.
- **Breath Sample:** Guided sampling, real-time chart, export data.
- **Settings:** Appearance, sampling, privacy, account, and device options.
- **Instructions:** Device usage and safety guidance.
- **Side Menu:** Navigation and logout.

---

## Compliance & Legal
- **Privacy Policy:** See [PrivacyPolicyView.swift](XHale/Views/PrivacyPolicyView.swift) and in-app.
- **Medical Disclaimer:** App is for research and informational purposes only; not a substitute for professional medical advice.
- **App Store Compliance:**
  - Organization account required for distribution.
  - No unsubstantiated medical claims.
  - Trademark and intellectual property compliance required for app name and branding.

---

## Contact & Support
- **Email:** asku@nexlusense.com
- **Website:** https://nexlusense.com/
- **University of Oklahoma, Electrical Engineering Department**

For issues, feature requests, or contributions, please open an issue or pull request.

---

## License
This project is for research and educational use. For licensing or commercial inquiries, contact the project maintainers.

## Screenshots

![Home Screen](XHale/Resources/Images/sim1.png)
*Home screen of XHale Health app on iPhone 16 Pro Max*

![Breath Sample Screen](XHale/Resources/Images/sim2.png)
*Breath sample workflow on iPhone 16 Pro Max*
