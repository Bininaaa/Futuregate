# FutureGate

FutureGate is a role-based Flutter and Firebase application that connects students, companies, and administrators in one platform. It helps students discover opportunities and academic resources, allows companies to manage recruitment flows, and provides admins with moderation and platform oversight tools.

## Overview

The application is organized around three core user roles:

- `Student`: explore opportunities, scholarships, trainings, project ideas, saved items, profile management, and CV creation.
- `Company`: publish and manage opportunities, review applications, and maintain company profile data.
- `Admin`: manage users, monitor activity, and moderate content.

The project uses Firebase Authentication for login, Cloud Firestore for primary data, Firebase Storage for file-related features, and Provider for state management.

## Key Features

### Student Experience

- Email/password authentication
- Google Sign-In
- Role-aware dashboard
- Browse open jobs and internships
- Apply to opportunities with duplicate-application protection
- Save opportunities for later
- Create and edit a CV
- Explore scholarships and trainings
- Submit and manage project ideas
- Edit profile information
- Access chat-related screens for communication flows

### Company Experience

- Company dashboard with opportunity and application statistics
- Create, edit, open, close, and safely delete opportunities
- Review student applications
- View student CV data
- Manage company profile information

### Admin Experience

- Admin dashboard
- User management screens
- Moderation screens for platform oversight

## Tech Stack

- `Flutter`
- `Dart`
- `Firebase Authentication`
- `Cloud Firestore`
- `Firebase Storage`
- `Firebase Analytics`
- `Firebase Messaging`
- `Provider`
- `Google Sign-In`

## Project Structure

```text
lib/
|- models/        # Firestore/domain models
|- providers/     # State management with Provider
|- screens/       # UI grouped by role and feature
|- services/      # Firebase and business logic
|- utils/         # Constants, formatters, validators
|- widgets/       # Reusable UI components
`- main.dart      # App bootstrap
```

## Current Architecture

- `main.dart` initializes Firebase and registers providers.
- `AuthWrapper` routes authenticated users into student, company, or admin flows based on their stored role.
- Services contain Firebase access and business logic.
- Providers expose async state and mutations to the UI.

## Supported Platforms

The repository includes Flutter platform folders for Android, iOS, web, Windows, macOS, and Linux.

Firebase is currently configured in the repository for:

- `Android`
- `Web`

If you want to use your own Firebase project, regenerate the configuration with `flutterfire configure` and replace the existing generated files.

## Getting Started

### Prerequisites

- Flutter SDK `3.11+`
- Dart SDK compatible with the Flutter version above
- A Firebase project
- Node.js if you want to run the seed script

### Installation

```bash
git clone https://github.com/<your-username>/avenirdz.git
cd avenirdz
flutter pub get
```

### Run the App

```bash
flutter run
```

Examples:

```bash
flutter run -d chrome
flutter run -d android
```

## Firebase Configuration

This repository already contains FlutterFire-generated configuration for the current Firebase project.

If you are setting up your own Firebase project:

1. Create a Firebase project.
2. Enable Authentication and Firestore.
3. Add your Android and/or web apps in Firebase.
4. Run `flutterfire configure`.
5. Replace `lib/firebase_options.dart` and any platform-specific configuration files with your generated ones.

Depending on the features you want to use, you may also need to configure:

- Google Sign-In
- Firebase Storage
- Firestore security rules
- Firebase Cloud Messaging

## Database Seeding

The project includes a Firestore seed script at `firebase_seed/seed.js`.

The repository does **not** store a Firebase Admin service account key. To seed locally, provide credentials in one of these ways.

Using an explicit path:

```powershell
$env:FIREBASE_SERVICE_ACCOUNT_PATH="C:\path\to\service-account.json"
npm run seed:firebase
```

Using `GOOGLE_APPLICATION_CREDENTIALS`:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
npm run seed:firebase
```

Using an untracked local file:

```text
firebase_seed/service-account.local.json
```

Then run:

```bash
npm run seed:firebase
```

## Quality Checks

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

The repository currently analyzes cleanly and the included widget tests pass.

## Product Status

This project is actively evolving. The main role-based flows are implemented, and the next areas that would strengthen the repository are:

- broader automated test coverage
- production-ready Firebase security rules and indexes
- deployment documentation
- screenshots or demo assets for the GitHub page

## Security Notes

- Do not commit Firebase Admin service account keys.
- If a credential was previously exposed, revoke it in Google Cloud or Firebase and generate a new one before continuing.
- Review Authentication, Firestore, and Storage rules before using the project in production.

## Publishing Tips

Before making the repository public on GitHub, consider adding:

- a `LICENSE` file
- screenshots or a short demo GIF
- a roadmap or issue board
- deployment instructions
- Firestore rules and indexes if they are part of your release process

## License

No license file is currently included in this repository. Add one before public reuse or distribution.
