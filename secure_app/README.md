# 🔐 Secure Flutter App

A comprehensive Flutter application demonstrating modern mobile app development with security features, authentication, and state management.

## ✨ Features

- **🔑 Multi-Factor Authentication**: Email/password, biometric, and PIN authentication
- **🛡️ App Security**: Immediate lockout on app pause with re-authentication
- **👤 User Profile**: Profile management with image capture and local storage
- **🎨 Modern UI**: Glassmorphism design with smooth animations
- **📱 Cross-Platform**: Full support for Android and iOS
- **🔒 Data Security**: Encrypted local storage with SQLite database

## 🚀 Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd secure_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 🏗️ Architecture

- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Database**: SQLite with secure storage
- **Authentication**: Local auth with biometric support
- **UI**: Material Design with custom components

## 📁 Project Structure

```
lib/
├── core/           # Core services and utilities
├── modules/        # Feature modules (auth, home, profile)
├── router/         # Navigation configuration
└── main.dart       # App entry point
```

## 🔧 Key Services

- **AuthService**: User authentication and session management
- **BiometricService**: Biometric authentication handling
- **PinService**: PIN setup and verification
- **AppLockoutService**: App security and lockout management
- **ProfileService**: User profile data management

## 📚 Documentation

For detailed documentation, see [DEVELOPER_DOCUMENTATION.md](DEVELOPER_DOCUMENTATION.md)

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📱 Platform Support

- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 11.0+

## 🔒 Security Features

- Encrypted local storage
- Biometric authentication
- PIN fallback system
- App lockout protection
- Secure credential management

## 🎯 Learning Resources

This app demonstrates:
- Flutter state management with Riverpod
- Secure authentication flows
- Local database operations
- Modern UI/UX design
- Cross-platform development
- Security best practices

## 📄 License

Educational use only. Please use responsibly.

---

*Built with ❤️ using Flutter*