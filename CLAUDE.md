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

### Git Workflow
- **Commit regularly** - Create git commits after completing meaningful changes or features
- **Descriptive messages** - Use clear commit messages that explain what was changed and why
- **Before major changes** - Always commit current work before starting significant refactoring
- **Rollback capability** - Regular commits enable easy rollback if issues arise
- **End of session** - Commit all changes before ending development sessions

## Project Architecture

### Core Architecture
This is a Flutter app for ADHD/executive function support, built with a modular, cross-platform architecture:

**Models Layer** (`lib/models/`):
- `routine.dart` - Core routine data structure with steps, categories, and analytics computed properties
- `routine_run.dart` - Individual execution records for tracking runs, completion times, and analytics
- `step.dart` - Individual step with support for timers, reps, random choices, and variable parameters
- `step_type.dart` - Enums and content types for different step behaviors

**Services Layer** (`lib/services/`):
- `routine_service.dart` - CRUD operations and routine management
- `execution_service.dart` - Real-time routine execution with timer management, step progression, and run tracking
- `storage_service.dart` - Local data persistence using SharedPreferences with run tracking support
- `routine_import_export_service.dart` - Import/export routines with native sharing integration
- `audio_service.dart` - Sound effects and background music management
- `tts_service.dart` - Text-to-speech functionality
- `notification_service.dart` - Local notifications and timer completion alerts

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
- Session state tracking with comprehensive run analytics
- Individual run recording with completion times, pause tracking, and step progress

**Analytics and Tracking**:
- Individual routine run records with detailed metrics
- Computed analytics: run count, completion rate, average duration, last run time
- Tracking data separated from routine definitions (not included in exports)
- User-initiated run data clearing with confirmation dialogs

**Import/Export System**:
- Native device sharing integration using share_plus
- JSON-based routine exchange format with comprehensive LLM generation prompts
- Import from clipboard, file picker, or shared content
- Export excludes analytics data for clean routine sharing

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
- `shared_preferences: ^2.2.3` - Local storage and run tracking
- `uuid: ^4.5.1` - Unique ID generation
- `flutter_animate: ^4.5.0` - Animation system for dice rolls
- `vibration: ^2.0.0` - Haptic feedback for dice interactions
- `share_plus: ^11.0.0` - Native sharing integration for routine export
- `file_picker: ^8.1.4` - File selection for routine import
- `path_provider: ^2.1.5` - Platform-specific directory access
- `firebase_core: ^3.9.0` - Firebase integration foundation
- `audioplayers: ^6.1.0` - Audio playback for sounds and music
- `flutter_tts: ^4.2.0` - Text-to-speech functionality
- `flutter_local_notifications: ^18.0.1` - Local notification support

### Development Notes
- Sample data is automatically loaded on first run
- All step types are fully configurable (no hardcoded assumptions)
- Timer and execution logic separated for testability
- UI components designed for ADHD-friendly interaction patterns
- 2.5D dice roll animations for random choice steps with haptic feedback
- Interactive dice rolling dialog for engaging random selections
- Comprehensive routine analytics with individual run tracking
- Native sharing integration with Android intent queries for compatibility
- Animated thumbs up mascot that responds to scroll position
- User-friendly relative time displays for run history
- Mobile-first design with appropriate text length constraints

### Testing Strategy
- Unit tests for models and services
- Widget tests for UI components
- Integration tests for complete user flows
- Test execution scenarios with different step types and configurations

## Recent Changes and Features

### Routine Tracking & Analytics (Latest)
- **Individual Run Tracking**: Each routine execution is recorded with detailed metrics
- **Analytics Computed Properties**: Routines now provide `timesRun`, `lastRunAt`, `averageRunTime`, and `completionRate`
- **UI Integration**: Routine cards display "last run" information with relative time formatting
- **Data Management**: Users can clear run data for individual routines with confirmation dialogs
- **Clean Exports**: Tracking data is excluded from routine exports for sharing

### Native Sharing Integration
- **Share Menu Integration**: Export uses device's native share menu instead of file picker
- **Android Compatibility**: Added intent queries to AndroidManifest.xml for Android 11+ support
- **User Experience**: Proper handling of user cancellation vs. errors during sharing
- **Cross-Platform**: Web and mobile sharing with appropriate fallbacks

### UI/UX Improvements
- **Thumbs Up Animation**: Animated Twocan mascot that moves based on scroll position
- **Text Field Constraints**: Updated LLM prompts with mobile-optimized text length guidelines
- **Responsive Design**: Mobile-first approach with appropriate touch targets and spacing
- **Error Handling**: Graceful error states with user-friendly messaging

## Known Issues & Solutions

### Android App Bundle Build
- **Issue**: Previous Gemma LLM integration left asset pack references causing build failures
- **Status**: Cleaned up all Gemma dependencies, asset pack configurations removed
- **Solution Applied**: Removed asset pack references from gradle files and deleted gemma_model directory

### Keystore Management
- **Current**: Using upload-key.jks with basic security
- **Recommendation**: Generate new keystore with stronger credentials when needed
- **Command**: `keytool -genkey -v -keystore upload-key-new.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload-key-new`

### Performance Considerations
- **Scroll Listeners**: Use post-frame callbacks to avoid setState during layout phases
- **Future Builder**: Minimize FutureBuilder usage in list items for better scrolling performance
- **Asset Optimization**: Images and audio assets optimized for mobile delivery