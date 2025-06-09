# Google Sign-In Setup Guide

This guide explains how to set up Google Sign-In for the Rose Bud Thorn app.

## Prerequisites

1. **Google Developer Console Setup**
   - Create a project in the [Google Developer Console](https://console.developers.google.com)
   - Enable the Google Sign-In API
   - Create iOS OAuth 2.0 client credentials
   - Download the `GoogleService-Info.plist` file

2. **iOS Project Configuration**
   - Add `GoogleService-Info.plist` to your iOS project bundle
   - Ensure the file is included in the target's Build Phases → Copy Bundle Resources

## Implementation Details

### Dependencies Added
- **GoogleSignIn-iOS**: Official Google Sign-In SDK via SPM
- **KeychainAccess**: Secure token storage in keychain

### Key Components

#### 1. GoogleAuthService Protocol
```swift
protocol GoogleAuthService {
    func signIn() async throws -> GoogleUserData
    func signOut() throws
    func configure()
}
```

#### 2. ProfileModel Extensions
Added Google-specific properties:
- `googleAccessToken`: OAuth access token
- `googleIdToken`: OpenID Connect ID token  
- `googleUserId`: Unique Google user identifier

#### 3. AuthViewModel Integration
- `loginWithGoogle()`: Handles Google sign-in flow
- Secure token storage using KeychainAccess
- Error handling with user-friendly messages
- Updated `isSignedIn` logic to include Google authentication

#### 4. UI Components
- `GoogleButtonStyle`: Custom button following Google branding guidelines
- White background with colored Google "G" icon
- Positioned below Facebook button with 16pt spacing
- Accessibility support with proper labels and hints

## Security Features

### Token Storage
- Access tokens stored securely in iOS keychain
- Separate keychain service for Google tokens
- Automatic cleanup on sign-out

### OAuth Scopes
- `profile`: User's basic profile information
- `email`: User's email address
- No additional permissions requested

### Error Handling
- User cancellation handled gracefully
- Network errors displayed with retry option
- Failed authentication shows appropriate error messages

## Testing

### Unit Tests
- `GoogleAuthTests.swift` provides comprehensive test coverage
- Mock service for testing without network dependencies
- Tests for success/failure scenarios
- Profile data validation

### Test Coverage
- ✅ Successful sign-in flow
- ✅ Failed sign-in with error handling
- ✅ User cancellation scenarios
- ✅ Profile data persistence
- ✅ Sign-out functionality
- ✅ Token management

## Usage Example

```swift
// In your view model
await authViewModel.loginWithGoogle()

// Check authentication status
if authViewModel.isSignedIn {
    // User is authenticated
}

// Sign out
authViewModel.signOut()
```

## Accessibility

- Button supports VoiceOver with descriptive labels
- Minimum 44pt touch target for accessibility compliance
- Error messages announced to screen readers
- Supports Dynamic Type for text scaling

## Platform Support

- iOS 16+ (matches current app minimum)
- Conditional compilation for iOS-only features
- Graceful fallback on unsupported platforms

## Configuration Checklist

- [ ] Add `GoogleService-Info.plist` to iOS bundle
- [ ] Verify OAuth client configuration in Google Console
- [ ] Test sign-in flow on device
- [ ] Verify token storage in keychain
- [ ] Test accessibility with VoiceOver
- [ ] Validate error handling scenarios

## Troubleshooting

### Common Issues
1. **GoogleService-Info.plist not found**: Ensure file is added to bundle
2. **OAuth configuration errors**: Verify client ID in Google Console
3. **Keychain access denied**: Check app entitlements and signing

### Debug Tips
- Enable console logging to see OAuth flow details
- Use mock service during development for faster iteration
- Test with multiple Google accounts to verify user switching