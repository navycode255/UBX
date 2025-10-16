# Auth Module Tests

This directory contains comprehensive unit and widget tests for the authentication module.

## Test Structure

### Unit Tests
- **`auth_service_test.dart`** - Tests for the AuthService class
  - Sign in functionality
  - Sign up functionality
  - Authentication status checks
  - Token management
  - Error handling

- **`secure_storage_service_test.dart`** - Tests for the SecureStorageService class
  - Email storage and retrieval
  - Password storage and retrieval
  - Name storage and retrieval
  - Token storage and retrieval
  - User ID management
  - Login status management
  - Data clearing operations
  - Exception handling

- **`form_validators_test.dart`** - Tests for the FormValidators utility class
  - Email validation
  - Password validation
  - Name validation
  - Confirm password validation
  - Phone number validation
  - Age validation
  - URL validation
  - Credit card validation

### Widget Tests
- **`signin_page_test.dart`** - Tests for the SignInPage widget
  - Widget rendering
  - User interactions
  - Form validation
  - Authentication flow
  - Responsive design
  - Accessibility
  - Error handling
  - State management

- **`signup_page_test.dart`** - Tests for the SignUpPage widget
  - Widget rendering
  - User interactions
  - Form validation
  - Authentication flow
  - Responsive design
  - Accessibility
  - Error handling
  - State management

### Test Runner
- **`auth_module_test_runner.dart`** - Main test runner that executes all tests

## Running Tests

### Run All Auth Module Tests
```bash
flutter test lib/modules/auth/test/
```

### Run Specific Test Files
```bash
# Run only unit tests
flutter test lib/modules/auth/test/auth_service_test.dart
flutter test lib/modules/auth/test/secure_storage_service_test.dart
flutter test lib/modules/auth/test/form_validators_test.dart

# Run only widget tests
flutter test lib/modules/auth/test/signin_page_test.dart
flutter test lib/modules/auth/test/signup_page_test.dart
```

### Generate Mocks
Before running tests that use mocks, generate the mock files:
```bash
flutter packages pub run build_runner build
```

## Test Coverage

The tests cover:

### ✅ **Authentication Service**
- Sign in with valid/invalid credentials
- Sign up with complete/incomplete data
- Authentication status management
- Token refresh functionality
- Error handling and exception management

### ✅ **Secure Storage Service**
- All storage operations (email, password, name, tokens, user ID)
- Data retrieval and validation
- Login status management
- Data clearing operations
- Exception handling

### ✅ **Form Validation**
- Email format validation
- Password strength validation
- Name validation
- Password confirmation matching
- Additional validators (phone, age, URL, credit card)

### ✅ **UI Components**
- Widget rendering and structure
- User input handling
- Form validation display
- Loading states and indicators
- Navigation between pages
- Responsive design
- Accessibility features
- Error message display

## Dependencies

The tests use the following testing dependencies:
- `flutter_test` - Core Flutter testing framework
- `mockito` - Mocking framework for unit tests
- `build_runner` - Code generation for mocks

## Best Practices

1. **Isolation**: Each test is independent and doesn't affect others
2. **Mocking**: External dependencies are mocked for unit tests
3. **Coverage**: All public methods and edge cases are tested
4. **Readability**: Test names clearly describe what is being tested
5. **Maintainability**: Tests are organized and well-documented

## Adding New Tests

When adding new functionality to the auth module:

1. **Unit Tests**: Add tests for new service methods
2. **Widget Tests**: Add tests for new UI components
3. **Integration Tests**: Add tests for complete user flows
4. **Update Mocks**: Regenerate mocks if new dependencies are added

