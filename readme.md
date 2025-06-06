# 🌹 Rose Bud Thorn

Rose Bud Thorn is a cross-platform (iOS & macOS) journaling app that helps you reflect on your day by recording your "Rose" (highlight), "Bud" (something you're looking forward to), and "Thorn" (challenge). Built with SwiftUI and supporting Sign in with Apple, it provides a simple, beautiful, and secure way to track your daily thoughts.

## Features

- 📅 Calendar view to browse daily entries
- 🌹 Add a Rose, Bud, and Thorn for each day
- 📷 Attach media to your entries
- 🔒 Sign in with Apple for privacy and security
- ☁️ Sync data across devices (if backend is enabled)
- 🖥️ Native support for both iOS and macOS

## Screenshots

![App Store](src/Shared/appstore.png)
![Play Store](src/Shared/playstore.png)

## Getting Started

### Prerequisites

- Xcode 13.1 or later
- Swift 5.0+
- macOS 12.0+ or iOS 15.0+

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/markcoleman/rose-bud-thorn.git
   cd rose-bud-thorn
   ```

2. **Open the project in Xcode:**
   ```sh
   open src/rose.bud.thorn.xcodeproj
   ```

3. **Build and run:**
   - Select your target device (iOS Simulator or Mac)
   - Press `Cmd + R` to build and run the app

## Architecture

The app is built using SwiftUI and follows the MVVM (Model-View-ViewModel) pattern:

- **Models**: Data structures for Rose, Bud, and Thorn entries
- **Views**: SwiftUI views for the user interface
- **ViewModels**: Business logic and data management
- **Services**: Authentication, data persistence, and cloud sync

## Development

### Project Structure

```
src/
├── Shared/              # Shared code between iOS and macOS
│   ├── Models/         # Data models
│   ├── Views/          # SwiftUI views
│   ├── ViewModels/     # View models
│   └── Services/       # Business logic services
├── macOS/              # macOS-specific code
├── Tests iOS/          # iOS unit tests
├── Tests macOS/        # macOS unit tests
└── fastlane/           # CI/CD automation
```

### Building for Production

The project uses Fastlane for automated builds and deployment:

```sh
cd src
bundle install
bundle exec fastlane ios beta    # Deploy iOS beta
bundle exec fastlane mac beta    # Deploy macOS beta
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## Security

If you discover a security vulnerability, please see our [Security Policy](SECURITY.md) for information on how to report it responsibly.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 Email: [Insert contact email]
- 🐛 Bug reports: [Create an issue](https://github.com/markcoleman/rose-bud-thorn/issues/new/choose)
- 💬 Discussions: [GitHub Discussions](https://github.com/markcoleman/rose-bud-thorn/discussions)

## Acknowledgments

- Built with ❤️ using SwiftUI
- Icons and design inspired by the Rose, Bud, Thorn reflection framework
- Thanks to all contributors who help improve this app

---

**Rose Bud Thorn** - Reflect. Grow. Thrive. 🌹