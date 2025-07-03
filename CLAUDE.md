# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Flutter Commands
- `flutter run` - Run the app in debug mode
- `flutter run --release` - Run the app in release mode
- `flutter build apk` - Build Android APK
- `flutter build appbundle` - Build Android App Bundle for Play Store
- `flutter build web` - Build for web
- `flutter pub get` - Install dependencies
- `flutter pub outdated` - Check for outdated packages
- `flutter clean` - Clean build artifacts
- `flutter test` - Run unit tests

### Development Workflow
- `flutter pub get` - Always run after modifying pubspec.yaml
- `flutter run` - Start development with hot reload
- Use `r` in terminal for hot reload, `R` for hot restart

## Project Architecture

### Core Architecture
This is a Flutter app for ADHD/executive function support, built with a modular, cross-platform architecture:

**Models Layer** (`lib/models/`):
- `routine.dart` - Core routine data structure with steps, categories, and progress tracking
- `step.dart` - Individual step with support for timers, reps, random choices, and variable parameters
- `step_type.dart` - Enums and content types for different step behaviors

**Services Layer** (`lib/services/`):
- `routine_service.dart` - CRUD operations and routine management
- `execution_service.dart` - Real-time routine execution with timer management and step progression
- `storage_service.dart` - Local data persistence using SharedPreferences

**State Management** (`lib/providers/`):
- Uses Provider pattern for state management
- `routine_provider.dart` - Manages routine data and operations
- `execution_provider.dart` - Manages active routine execution state

**UI Layer** (`lib/ui/`):
- `screens/` - Full-screen views (HomeScreen, ExecutionScreen)
- `widgets/` - Reusable components (RoutineCard, StepDisplay)
- `shared/` - Common UI components

### Key Features Architecture

**Modular Routine Engine**:
- Routines contain multiple steps with flexible configuration
- Steps support: basic tasks, timers, rep counting, random selection, variable parameters
- JSON serialization for persistence

**Execution Engine**:
- Real-time step progression with pause/resume
- Timer management with stream-based updates
- Support for random and deterministic flows
- Session state tracking

**Cross-Platform Support**:
- Flutter framework enables Android, iOS, web, and desktop deployment
- Responsive UI design principles
- Platform-agnostic storage and services

### Data Flow
1. User selects routine from HomeScreen
2. ExecutionProvider starts routine via ExecutionService
3. ExecutionService processes steps (handles randomization, variable parameters)
4. ExecutionScreen displays current step via StepDisplay widget
5. Timer streams provide real-time updates
6. Progress tracked through ExecutionSession state

### Key Dependencies
- `provider: ^6.1.2` - State management
- `shared_preferences: ^2.2.3` - Local storage
- `uuid: ^4.5.1` - Unique ID generation
- `flutter_animate: ^4.5.0` - Animation system for dice rolls
- `vibration: ^2.0.0` - Haptic feedback for dice interactions

### Development Notes
- Sample data is automatically loaded on first run
- All step types are fully configurable (no hardcoded assumptions)
- Timer and execution logic separated for testability
- UI components designed for ADHD-friendly interaction patterns
- 2.5D dice roll animations for random choice steps with haptic feedback
- Interactive dice rolling dialog for engaging random selections

### Testing Strategy
- Unit tests for models and services
- Widget tests for UI components
- Integration tests for complete user flows
- Test execution scenarios with different step types and configurations