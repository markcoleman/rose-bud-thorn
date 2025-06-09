# 🌹 Rose Bud Thorn

Rose Bud Thorn is a cross-platform (iOS & macOS) journaling app that helps you reflect on your day by recording your "Rose" (highlight), "Bud" (something you're looking forward to), and "Thorn" (challenge). Built with SwiftUI and Swift Package Manager, it provides a simple, beautiful, and secure way to track your daily thoughts.

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

- Xcode 15.0 or later
- Swift 5.7+
- macOS 12.0+ or iOS 16.0+

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/markcoleman/rose-bud-thorn.git
   cd rose-bud-thorn
   ```

2. **Open the workspace in Xcode:**
   ```sh
   open RoseBudThorn.xcworkspace
   ```

3. **Build and run:**
   - Select your target device (iOS Simulator or Mac)
   - Select the `RoseBudThornApp` scheme
   - Press `Cmd + R` to build and run the app

### Command Line Development

The project supports Swift Package Manager for command-line development:

```sh
# Build the project
swift build --configuration release

# Run tests
swift test

# Add a new dependency
swift package update
```

## Architecture

The app is built using SwiftUI with a modular Swift Package Manager structure:

### Package Structure

- **RoseBudThornCore**: Business logic, models, and services
- **RoseBudThornUI**: SwiftUI views, design system, and view models
- **RoseBudThornApp**: The executable iOS/macOS app

### Project Structure

```
Sources/
├── RoseBudThornCore/     # Core business logic
│   ├── Models/          # Data models
│   ├── Services/        # Business services
│   └── Network/         # Networking layer
├── RoseBudThornUI/       # User interface
│   ├── Views/           # SwiftUI views
│   ├── ViewModels/      # View models
│   ├── Resources/       # Assets and localizations
│   └── DesignSystem.swift
└── RoseBudThornApp/      # App entry point
    └── rose_bud_thornApp.swift
```

### Adding New Features

To add a new feature module:

1. Create a new target in `Package.swift`
2. Add source files under `Sources/YourFeature/`
3. Import the module where needed
4. Update dependencies as needed

## Development

### Building for Production

The project uses Fastlane for automated builds and deployment:

```sh
cd src
bundle install
bundle exec fastlane ios beta    # Deploy iOS beta
bundle exec fastlane mac beta    # Deploy macOS beta
```

### Testing

Run tests using either method:

```sh
# Swift Package Manager
swift test

# Xcode
cmd + U (in Xcode with RoseBudThornApp scheme selected)
```

### Adding Dependencies

Add new Swift Package dependencies in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/example/package", from: "1.0.0"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "ExamplePackage", package: "package"),
        ]
    ),
]
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

- Built with ❤️ using SwiftUI and Swift Package Manager
- Icons and design inspired by the Rose, Bud, Thorn reflection framework
- Thanks to all contributors who help improve this app

---

**Rose Bud Thorn** - Reflect. Grow. Thrive. 🌹

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