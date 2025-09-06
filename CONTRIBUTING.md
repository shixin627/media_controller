# Contributing to media_controller

Thank you for your interest in contributing to the media_controller Flutter plugin! This document provides guidelines for contributing to this project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/media_controller.git`
3. Create a feature branch: `git checkout -b feat/your-feature-name`

## Branch Naming Convention

Please use the following prefixes for your branch names:

- `feat/` - for new features
- `fix/` - for bug fixes
- `docs/` - for documentation changes
- `refactor/` - for code refactoring
- `test/` - for adding or modifying tests
- `chore/` - for maintenance tasks

## Commit Message Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` - new features
- `fix:` - bug fixes
- `docs:` - documentation only changes
- `refactor:` - code changes that neither fix bugs nor add features
- `test:` - adding missing tests or correcting existing tests
- `chore:` - changes to the build process or auxiliary tools

Examples:
```
feat: add volume control methods
fix: resolve memory leak in Android plugin
docs: update API documentation
refactor: improve error handling structure
```

## Development Guidelines

### Code Style

- Follow Dart's official style guide
- Run `flutter analyze` before submitting
- Ensure all tests pass with `flutter test`
- Add documentation comments (`///`) for all public APIs
- Use meaningful variable and method names

### Testing

- Write tests for new functionality
- Maintain or improve test coverage
- Test on real devices when possible
- Include both unit tests and integration tests

### Documentation

- Update README.md if you change public APIs
- Add or update code comments for complex logic
- Update CHANGELOG.md following the existing format
- Include usage examples for new features

## Pull Request Process

1. Ensure your code follows the project's coding standards
2. Update documentation as needed
3. Add or update tests for your changes
4. Ensure all tests pass
5. Update CHANGELOG.md with your changes
6. Create a pull request with a clear title and description
7. Include rationale for your changes in the PR description

## Code Review Guidelines

- Be respectful and constructive in code reviews
- Focus on the code, not the person
- Explain your suggestions clearly
- Be open to feedback and discussion

## Reporting Issues

When reporting issues, please include:

- A clear description of the problem
- Steps to reproduce the issue
- Expected vs actual behavior
- Device/platform information
- Relevant code snippets or logs

## Feature Requests

For feature requests, please:

- Check if a similar request already exists
- Clearly describe the proposed feature
- Explain the use case and benefits
- Consider backward compatibility

## Questions?

If you have questions about contributing, please:

- Check existing issues and discussions
- Open a new issue with the "question" label
- Be specific about what you need help with

Thank you for contributing to media_controller!