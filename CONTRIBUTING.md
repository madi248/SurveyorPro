# Contributing to Surveyor Pro

Thank you for your interest in contributing to Surveyor Pro! This document provides guidelines for contributing to this project.

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/surveyor_pro.git
   ```
3. **Install** dependencies:
   ```bash
   flutter pub get
   ```
4. **Create** a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Guidelines

### Code Style
- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` to check for linting issues
- Keep functions small and focused
- Use meaningful names for variables, functions, and classes

### Architecture
- Follow the **feature-first** folder structure
- Place new features in `lib/features/<feature_name>/`
- Shared services go in `lib/core/services/`
- Data models go in `lib/core/models/`

### Commit Messages
Use clear, descriptive commit messages:
```
feat: add coordinate transformation support
fix: correct GPS position display in World View
docs: update README with new features
refactor: simplify traverse computation logic
```

### Pull Requests
1. Update your branch with the latest `main`
2. Ensure your code passes `flutter analyze`
3. Test on a physical Android device if possible
4. Write a clear description of your changes
5. Reference any related issues

## Reporting Issues

When reporting bugs, please include:
- Device model and Android version
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots if applicable

## Feature Requests

We welcome feature suggestions! Please open an issue with:
- A clear description of the feature
- Why it would be useful for surveyors
- Any reference implementations or examples

## Questions?

Open an issue with the `question` label, and we'll be happy to help.
