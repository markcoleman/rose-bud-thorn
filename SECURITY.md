# Security Policy

## Supported Versions

We actively support the following versions of Rose Bud Thorn with security updates:

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| Previous| :white_check_mark: |
| Older   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability in Rose Bud Thorn, please report it to us responsibly.

### How to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report vulnerabilities by:

1. **Email**: Send details to [security@your-domain.com] (replace with actual contact)
2. **Private Issue**: Create a private security advisory on GitHub

### What to Include

When reporting a vulnerability, please include:

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact of the vulnerability
- Any suggested fixes or mitigations
- Your contact information for follow-up

### Response Timeline

- **Initial Response**: Within 48 hours of report
- **Status Update**: Within 7 days with preliminary assessment
- **Resolution**: Target 30 days for fixes, depending on complexity

### Security Measures

Rose Bud Thorn implements several security measures:

#### Data Protection
- All user data is encrypted at rest and in transit
- Sign in with Apple provides secure authentication
- No sensitive data is logged or transmitted to third parties
- Local data storage uses iOS/macOS secure keychain when appropriate

#### Code Security
- Regular dependency updates via Dependabot
- Code review required for all changes
- Automated security scanning in CI/CD pipeline
- Following Apple's security guidelines for iOS/macOS apps

#### Privacy
- Minimal data collection - only what's necessary for app functionality
- No tracking or analytics without explicit user consent
- User data remains on device unless explicitly synced with user's iCloud
- Compliance with Apple's privacy requirements

### Security Best Practices for Contributors

When contributing to Rose Bud Thorn:

1. **Never commit secrets**: API keys, passwords, or credentials
2. **Validate input data**: Always sanitize and validate user inputs
3. **Use secure APIs**: Follow Apple's security recommendations
4. **Review dependencies**: Check third-party libraries for vulnerabilities
5. **Follow secure coding practices**: Avoid common security pitfalls

### Vulnerability Disclosure

After a vulnerability is fixed:

1. We will publicly disclose the vulnerability details
2. Affected users will be notified through app updates
3. Credit will be given to the reporter (if desired)
4. Details will be added to our security changelog

### Contact

For any security-related questions or concerns:

- **Security Email**: [Insert security contact email]
- **General Contact**: [Insert general contact email]
- **GitHub Security**: Use GitHub's security reporting feature

## Security Updates

Users are strongly encouraged to:

- Keep the app updated to the latest version
- Enable automatic updates when possible
- Review app permissions periodically
- Report any suspicious behavior

---

Thank you for helping keep Rose Bud Thorn secure! 🔒