# Contributing to SqliteRecords

Thank you for your interest in contributing! This project aims to provide a minimal, type-safe wrapper for SQLite/PowerSync using Dart 3 records.

## Getting Started

1.  Ensure you have the [Dart SDK](https://dart.dev/get-dart) installed (version 3.0.0 or later).
2.  Clone the repository.
3.  Install dependencies:
    ```bash
    dart pub get
    ```

## Development Workflow

### Formatting

Always format your code before committing:
```bash
dart format .
```

### Static Analysis

Ensure your changes pass static analysis:
```bash
dart analyze
```

### Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/). This helps us automate versioning and changelog generation.

Example: `feat: add support for custom parsers`

For more details on automated agent workflows, see [AGENTS.md](./AGENTS.md).

## Publishing

Currently, `pubspec.yaml` is set to `publish_to: none`. This prevents accidental publishing to [pub.dev](https://pub.dev).

If this project is ever ready for a public release:
1.  Update the `version` in `pubspec.yaml`.
2.  Update `CHANGELOG.md` (if applicable).
3.  Remove `publish_to: none` or set it to a private repository URL if intended for private use.
4.  Run `dart pub publish --dry-run` to verify the package.
5.  Run `dart pub publish` to release.

## Submitting Changes

1.  Create a new branch for your feature or bug fix.
2.  Implement your changes.
3.  Ensure code is formatted and passes analysis.
4.  Submit a Pull Request.
