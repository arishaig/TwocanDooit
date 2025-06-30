# Dooit

An ADHD-friendly routine helper app built with Flutter. Dooit helps users with executive function challenges break down complex routines into manageable, guided steps with supportive features like timers, randomization, and gentle nudges.

## Features

### Core Functionality
- **Structured Routines**: Create multi-step routines with various step types
- **Step Navigation**: Intuitive side-tap zones and floating navigation controls
- **Progress Tracking**: Visual progress indicators and session timing

### Step Types
- **Basic Tasks**: Simple checklist items
- **Timers**: Countdown timers with audio feedback and background notifications
- **Repetition Steps**: Configurable rep counting with optional randomization
- **Random Choice**: Weighted dice system for decision-making
- **Variable Parameters**: Dynamic content selection for routine variety

### ADHD-Friendly Features
- **Gentle Nudges**: Optional reminder notifications that auto-dismiss when app regains focus
- **Audio Feedback**: Customizable sound effects for interactions and transitions
- **Background Music**: Optional focus music during routine execution
- **Voice Announcements**: Text-to-speech for step guidance
- **Visual Design**: Clean, mobile-optimized interface with clear visual hierarchy

### Advanced Features
- **Weighted Randomization**: Customize probability distributions for random choices
- **Smart UI**: Navigation elements hide during interactions (dice rolls, timer countdowns)
- **Cross-Platform**: Runs on Android, iOS, web, and desktop
- **Offline-First**: Local storage with no required internet connection

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio or VS Code with Flutter extensions

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/arishaig/dooit.git
   cd dooit
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Release
- **Android APK**: `flutter build apk`
- **Android App Bundle**: `flutter build appbundle`
- **Web**: `flutter build web`

## Project Structure

```
lib/
├── main.dart                 # App entry point with lifecycle management
├── models/                   # Data models
│   ├── routine.dart         # Routine structure and serialization
│   ├── step.dart           # Step types and weighted selection
│   └── app_settings.dart   # User preferences and settings
├── providers/               # State management (Provider pattern)
│   ├── routine_provider.dart
│   ├── execution_provider.dart
│   └── settings_provider.dart
├── services/               # Business logic and external integrations
│   ├── execution_service.dart    # Routine execution engine
│   ├── notification_service.dart # Push notifications and nudges
│   ├── audio_service.dart        # Sound effects and music
│   └── storage_service.dart      # Local data persistence
└── ui/                     # User interface
    ├── screens/           # Full-screen views
    │   ├── home_screen.dart
    │   ├── execution_screen.dart
    │   ├── routine_editor_screen.dart
    │   └── settings_screen.dart
    └── widgets/           # Reusable components
        ├── routine_card.dart
        ├── dice_widget.dart
        └── step_display.dart
```

## Architecture

Dooit follows Flutter best practices with:
- **Provider Pattern**: For reactive state management
- **Service Layer**: Separation of business logic from UI
- **Model-View-Provider**: Clean architecture with clear boundaries
- **Stream-Based**: Real-time updates for timers and execution state

## Development Commands

- `flutter run` - Run in debug mode with hot reload
- `flutter run --release` - Run optimized release build
- `flutter test` - Run unit and widget tests
- `flutter clean` - Clean build artifacts
- `flutter pub outdated` - Check for dependency updates

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Design Philosophy

Dooit is designed specifically for users with ADHD and executive function challenges:

- **Reduce Cognitive Load**: Clear visual hierarchy and minimal distractions
- **Provide Structure**: Break complex routines into manageable steps
- **Gentle Guidance**: Supportive audio and visual cues without being overwhelming
- **Flexible Interaction**: Multiple ways to navigate and interact with content
- **Respect Focus**: Smart UI that hides during focused interactions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Audio Acknowledgments

All audio assets are sourced from Freesound.org under Creative Commons licenses:

### Sound Effects
- **Button Click**: "Button Click 1.wav" by Mellau - [Freesound #506054](https://freesound.org/s/506054/) - License: Attribution NonCommercial 4.0
- **Subtle Click**: "Electronics-Flashlight-Plastic-Button-01.wav" by DWOBoyle - [Freesound #152537](https://freesound.org/s/152537/) - License: Attribution 4.0
- **Dice Roll**: "Roll Dice A" by Bw2801 - [Freesound #647924](https://freesound.org/s/647924/) - License: Attribution 4.0
- **Go Back**: "Whoosh -Plastic diving fin flat side - A-B 20cm - 1" by Sadiquecat - [Freesound #788416](https://freesound.org/s/788416/) - License: Creative Commons 0
- **Routine Complete**: "Success Jingle" by JustInvoke - [Freesound #446111](https://freesound.org/s/446111/) - License: Attribution 4.0

### Background Music
- **Binaural Beats**: "Binaural Beats Alpha to Delta and Back mp3" by WIM - [Freesound #676878](https://freesound.org/s/676878/) - License: Attribution NonCommercial 4.0
- **Focus Beats**: "EDM Myst Soundscape Cinematic.wav" by szegvari - [Freesound #593786](https://freesound.org/s/593786/) - License: Creative Commons 0
- **Calm Music**: "Meditation" by SergeQuadrado - [Freesound #655395](https://freesound.org/s/655395/) - License: Attribution NonCommercial 4.0

### Additional Credits
- Icons from Google Material Design
- Flutter team for the amazing framework
- The ADHD community for feedback and inspiration