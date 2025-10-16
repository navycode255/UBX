# Secure Mobile App – Flutter

# Overview
This is a **secure Flutter mobile application** that provides:
- User authentication (login & registration)
- Profile management
- Biometric authentication (fingerprint or face ID)
- App lockout when paused or quit
- Secure data storage and communication
- Device unique ID integration for API security

The app use **Flutter** for frontend development and communicate with a backend API or use a local database if API is unavailable.


# Functional Requirements

# 1. Authentication
- **Login:** Users can log in using email and password.  
- **Register:** New users can create an account by entering name, email, and password.  
- **Validation:** Validate all input fields.  
- **Secure Storage:** Store login credentials securely using `flutter_secure_storage`.

# 2. Profile Management
- Fetch user profile details from API or local DB.  
- Allowing the user to **capture or upload a profile picture** (using camera or gallery).  
- Binding data to the UI dynamically using `flutter_fiverpod`.

# 3. Biometric Authentication
- Using `local_auth` for fingerprint or face recognition.  
- Included a **PIN/password fallback** when biometrics are not available or fail.

# 4. App Lockout
- Lock the app immediately when minimized or closed.  
- Requiring biometric or password re-authentication when reopened.

## 5. Device Unique ID
- Using the `device_info_plus` package to get a unique device ID.  
- Attaching this ID to all API requests for tracking and security purposes.



# Security Requirements

# Data Encryption
- **Encryption at Rest:**    |   Using secure storage for locally saved data (credentials, tokens).  
- **Encryption in Transit:** |   All API communication use **HTTPS**.

# App Security
- **Obfuscation:**     |   Enabled Dart obfuscation before release making reverse engineering harder.  
- **Code Signing:**    |   Signed the application with a valid key before deployment.  
- **Secure Storage:**  |   Using `flutter_secure_storage` for sensitive data.


# Non-Functional Requirements

Category | Description
- **Performance**      |   App is responsive and handle data efficiently.
- **Usability**        |   It has clean and user-friendly interface.
- **Maintainability**  |   Organized folder structure and modular code.
- **Reliability**      |   Stable across different app lifecycle states (pause, quit, resume)
- **Scalability**      |   Its architecture allows adding new features easily.


# Development Packages 

- Secure Storage    `flutter_secure_storage`
- Biometric Auth    `local_auth` 
- Device Info       `device_info_plus`
- Image Capture     `image_picker`
- State Management  `flutter_riverpod`
- HTTP Requests     `http`
