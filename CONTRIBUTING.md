# Contributing to Rose Bud Thorn

Thank you for your interest in contributing to Rose Bud Thorn! We welcome contributions from the community and are grateful for your support.

## How to Contribute

### Reporting Issues

- Check if the issue already exists in our [issue tracker](https://github.com/markcoleman/rose-bud-thorn/issues)
- Use the appropriate issue template when creating a new issue
- Provide as much detail as possible, including:
  - Steps to reproduce the issue
  - Expected behavior vs actual behavior
  - Screenshots if applicable
  - Device/OS version information

### Suggesting Features

- Check existing issues and discussions for similar feature requests
- Open a new issue using the "Feature Request" template
- Clearly describe the feature and its benefits
- Consider including mockups or examples if helpful

### Code Contributions

#### Prerequisites

- Xcode 15.0 or later
- Swift 5.7+
- macOS 12.0+ or iOS 16.0+
- Basic knowledge of SwiftUI and Swift Package Manager development

#### Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/rose-bud-thorn.git
   cd rose-bud-thorn
   ```
3. Create a new branch for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. Open the workspace in Xcode:
   ```bash
   open RoseBudThorn.xcworkspace
   ```

#### Development Workflow

The project uses Swift Package Manager with a modular architecture:

- **RoseBudThornCore**: Business logic and models
- **RoseBudThornUI**: SwiftUI views and design system  
- **RoseBudThornApp**: Executable application

You can develop using either:
- **Xcode**: Open `RoseBudThorn.xcworkspace` and select the `RoseBudThornApp` scheme
- **Command Line**: Use `swift build` and `swift test` for development

#### Making Changes

1. **Code Style**: Follow Swift conventions and existing code patterns
2. **Testing**: Add tests for new features and ensure existing tests pass
3. **Documentation**: Update documentation for any API changes
4. **Commits**: Write clear, descriptive commit messages

#### Testing

- Run all tests before submitting your PR:
  - iOS tests: `Cmd + U` with iOS scheme selected
  - macOS tests: `Cmd + U` with macOS scheme selected
- Add unit tests for new functionality
- Test on both iOS and macOS if applicable

#### Pull Request Process

1. Ensure your code builds without warnings
2. Update the README.md if you've added new features
3. Add or update tests as needed
4. Create a pull request with:
   - Clear title and description
   - Link to related issues
   - Screenshots for UI changes
   - Testing instructions

### Code Review

All contributions require code review. We aim to:
- Provide constructive feedback
- Respond to PRs within a reasonable timeframe
- Maintain code quality and consistency

### Community Guidelines

- Be respectful and inclusive
- Follow our [Code of Conduct](CODE_OF_CONDUCT.md)
- Help others when possible
- Stay focused on constructive discussions

## Development Guidelines

### Architecture

- Follow MVVM pattern with SwiftUI
- Keep views lightweight and focused
- Use dependency injection for services
- Maintain clear separation of concerns

### SwiftUI Best Practices

- Use `@StateObject` for view models
- Prefer `@ObservedObject` for passed-in objects
- Use `@State` for local view state only
- Follow SwiftUI data flow patterns

### Performance

- Avoid expensive operations in view bodies
- Use lazy loading for large data sets
- Optimize images and assets
- Consider memory usage on both platforms

### Accessibility

- Add accessibility labels and hints
- Support Voice Over
- Ensure good color contrast
- Test with accessibility features enabled

## Release Process

1. Features are merged to `main` branch
2. Regular releases are created from `main`
3. Hotfixes may be created from release branches
4. Fastlane handles CI/CD automation

## Questions?

- Open a discussion in [GitHub Discussions](https://github.com/markcoleman/rose-bud-thorn/discussions)
- Create an issue for bugs or feature requests
- Check existing documentation and issues first

Thank you for contributing to Rose Bud Thorn! 🌹