# TripCentral AI Coding Agent Guidelines

Welcome, AI Agent! This guide will help you quickly become productive in the TripCentral codebase.

## 🏗 Big Picture Architecture
This is a Flutter-based trip planning application for Android, using Supabase as the primary backend and Google Maps for location services. It enforces a strict feature-based folder structure combined with deliberate design pattern implementations.

- **`lib/features/`**: The core domain logic is broken down by feature (`home`, `lists`, `map`, `profile`, `shared`, `social`). Always keep UI and logic isolated within its respective feature module.
- **`lib/app/`**: Contains app-level structural scaffolding, including the `TripCentralApp` wrapper, thematic configurations (`app_theme_factory.dart`), and global routing (`app_routes.dart`).
- **`lib/core/`**: Houses foundational configurations (`AppConfig` singleton) and globally reusable architecture patterns.

## 🧩 Foundational Design Patterns
This project avoids "spaghetti code" by actively isolating architectural behavior into explicit classic design patterns within `lib/core/patterns/`. You are expected to adhere to these approaches rather than creating ad-hoc solutions:

- **Facade (`core/patterns/facade/`)**: Use facades like `TripDataFacade` to mask complex subsystems. This is critical for combining heterogeneous data sources (e.g., merging Google Maps API data, Supabase database queries, and local user notes) into single, unified data models.
- **Strategy (`core/patterns/strategy/`)**: Use strategies like `DiscoveryStrategy` for swappable business logic algorithms. For example, sorting locations by popularity or distance is handled purely via implementers of a strategy interface.
- **Observer (`core/patterns/observer/`)**: Use `NotificationCenter` for decoupled, cross-component communication (publish-subscribe) rather than passing deep callback chains.

## 🔌 State & Data Integration
- **Supabase**: Used for database storage, auth, and managing collaborated trip lists. Any DB query should ideally be abstracted behind a repository or Facade to keep the UI clean.
- **Google Maps**: We utilize `google_maps_flutter`. Ensure geographic coordinates (`distanceKm`, etc.) properly pipe into Maps widgets using appropriate facades.

## 🛣 Custom Routing Convention
- We use a map-based routing combined with a Shell application.
- To add a new tab or bottom navigation route, do **not** just add a `Navigator.push`. Instead, register it inside `AppRoutes` (`lib/app/navigation/app_routes.dart`) under the `tabs` list as an `AppTabDefinition`.
- Example:
  ```dart
  AppTabDefinition(
    title: 'Map',
    routeName: '/map',
    pageBuilder: MapPage.new,
  )
  ```

## 🛠 Developer Workflows (Android Focus)
- Ensure changes are tested against an Android target: `flutter build apk` or `flutter run -d android`.
- Before committing, ensure you abide by the strict lint rules defined by `flutter_lints` (run: `flutter analyze`).
- We use standard `MaterialApp`. Do not use Cupertino specific widgets unless wrapped appropriately.

