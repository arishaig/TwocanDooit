# TwocanDooit 🐦

[![Main Tests](https://github.com/arishaig/twocandooit/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/arishaig/twocandooit/actions/workflows/tests.yml)
[![PR Tests](https://github.com/arishaig/twocandooit/actions/workflows/pr-tests.yml/badge.svg)](https://github.com/arishaig/twocandooit/actions/workflows/pr-tests.yml)
[![Deploy](https://github.com/arishaig/twocandooit/actions/workflows/deploy.yml/badge.svg)](https://github.com/arishaig/twocandooit/actions/workflows/deploy.yml)

> *"You don't have to do it alone. Twocan do it."*

A cozy, gently whimsical ADHD-friendly routine helper that respects how your brain works—especially when it doesn't. TwocanDooit is your colorful little sidekick who helps make things feel safe, possible, and even a little fun.

## Meet Twocan! 🐥

Your cheerleader, planner, and snack reminder-er all rolled into one adorable cartoon toucan. Twocan has big "emotional support bird" energy and thinks stickers are currency. They'll 100% celebrate you brushing your teeth like it's the Olympics.

**Sample lines from Twocan:**
- *"One task at a time. I'm right here with you!"*
- *"Aww yiss. You did the thing. I'm so proud I could molt."*
- *"Hey, it's okay to rest. Even I close my eyes sometimes. (Not both. Predators.)"*

## ✨ Features

### 🎯 Core Functionality
- **Single-Task Focus**: No cluttered dashboards. Twocan walks you through one thing at a time
- **Step Navigation**: Intuitive side-tap zones and floating navigation controls
- **Progress Tracking**: Visual progress indicators with gentle celebrations

### 🎲 Step Types
- **Basic Tasks**: Simple checklist items with encouraging checkmarks
- **Timers**: Countdown timers with cozy audio feedback and background notifications
- **Repetition Steps**: Configurable rep counting with optional randomization
- **Random Choice**: Interactive 2.5D dice rolling with haptic feedback for decision-making
- **Variable Parameters**: Dynamic content selection for routine variety

### 📊 Analytics & Tracking
- **Individual Run Tracking**: Each routine execution recorded with detailed metrics
- **Completion Analytics**: Run count, completion rate, average duration, and last run time
- **Progress Visualization**: Routine cards display "last run" with relative time formatting
- **Data Management**: Clear run data for individual routines with confirmation dialogs
- **Clean Exports**: Analytics excluded from routine sharing for privacy

### 🧠 ADHD-Friendly Features
- **Gentle Nudges**: Optional reminder notifications that auto-dismiss when app regains focus
- **Customizable Voice & Tone**: Adjust how much Twocan talks
- **Audio Feedback**: Cozy sound effects for interactions and transitions
- **Background Music**: Optional focus music during routine execution
- **Voice Announcements**: Text-to-speech with Twocan's encouraging personality
- **High Visual Contrast + Soft Edges**: Gentle gradients, curves, and whitespace

### ♿ Accessibility & Comfort Features
- **Reduced Animations**: Minimize moving elements and transitions for sensory sensitivity
- **Focus Mode**: Hide distracting elements during routine execution
- **Simplified Interface**: Larger text and cleaner layouts for better readability
- **Customizable Feedback**: Toggle audio and haptic feedback independently
- **Smart Mascot**: Twocan moves to avoid covering content, or stays static when preferred
- **Tabbed Settings**: Organized, less overwhelming interface for preferences
- **Plain Language**: Clear, jargon-free instructions and error messages
- **Flexible Navigation**: Multiple ways to navigate (buttons, gestures, voice)
- **Sensory Considerations**: Muted color palette and customizable sound options

### 🌟 Advanced Features
- **Weighted Randomization**: Customize probability distributions for random choices
- **Smart UI**: Navigation elements hide during focused interactions
- **Cross-Platform**: Runs on Android, iOS, web, and desktop
- **Offline-First**: Local storage with no required internet connection
- **Native Sharing**: Import/export routines using device's native share menu
- **LLM Integration**: Comprehensive prompts for AI-assisted routine creation

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio or VS Code with Flutter extensions

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/arishaig/twocandooit.git
   cd twocandooit
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

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point with Twocan lifecycle management
├── models/                   # Data models
│   ├── routine.dart         # Routine structure and serialization
│   ├── step.dart           # Step types and weighted selection
│   └── app_settings.dart   # User preferences and Twocan settings
├── providers/               # State management (Provider pattern)
│   ├── routine_provider.dart
│   ├── execution_provider.dart
│   └── settings_provider.dart
├── services/               # Business logic and external integrations
│   ├── execution_service.dart    # Routine execution engine
│   ├── notification_service.dart # Gentle nudges and notifications
│   ├── audio_service.dart        # Cozy sound effects and music
│   └── storage_service.dart      # Local data persistence
└── ui/                     # User interface
    ├── screens/           # Full-screen views
    │   ├── home_screen.dart       # Twocan's home base
    │   ├── execution_screen.dart  # Step-by-step guidance
    │   ├── routine_editor_screen.dart
    │   └── settings_screen.dart
    └── widgets/           # Reusable components
        ├── routine_card.dart
        ├── dice_widget.dart
        └── step_display.dart
```

## 🎨 Brand Colors

Our cozy, accessible color palette:

| Color             | Hex       | Use Case                         |
|------------------|-----------|----------------------------------|
| 🐦 Toucan Blue     | #2D7A9A   | Primary buttons, headers         |
| 🍊 Beak Orange     | #FFAD49   | Highlights, checkmarks, icons    |
| 🪶 Belly Cream     | #FFF7ED   | Backgrounds                      |
| 🌿 Jungle Green    | #64A67B   | Success states, accent buttons   |
| 💜 Cozy Purple     | #A393D3   | Hover states, links, flair       |
| 🌑 Charcoal Text   | #2B2B2B   | Primary text                     |

*All colors pass accessibility thresholds and are neurodivergent-friendly.*

## 🏛️ Architecture

TwocanDooit follows Flutter best practices with Twocan's cozy approach:
- **Provider Pattern**: For reactive state management
- **Service Layer**: Separation of business logic from UI
- **Model-View-Provider**: Clean architecture with clear boundaries
- **Stream-Based**: Real-time updates for timers and execution state

## 🛠️ Development Commands

- `flutter run` - Run in debug mode with hot reload
- `flutter run --release` - Run optimized release build
- `flutter test` - Run unit and widget tests
- `flutter clean` - Clean build artifacts
- `flutter pub outdated` - Check for dependency updates

## 🔧 Troubleshooting

### Common Issues

**Build fails with "No Firebase configuration found"**
- For development: Firebase stub files are automatically created by CI
- For production: Add your own `google-services.json` and `firebase_options.dart`

**"No such file or directory" errors**
- Run `flutter clean && flutter pub get` to reset dependencies
- Ensure you're using Flutter version 3.32.6 or higher

**App crashes on first run**
- Check that sample data loaded correctly
- Clear app data and restart to reload sample routines

**Audio/TTS not working**
- Check device volume settings
- Verify permissions for audio playback
- Try different TTS voices in Settings

**Performance issues**
- Disable animations in Accessibility settings
- Clear routine run data to reduce stored data
- Restart app if timers seem stuck

### Getting Help

- Check [Issues](https://github.com/arishaig/twocandooit/issues) for known problems
- Review the `CLAUDE.md` file for technical details
- Create a new issue with device info and error logs

## 🤝 Contributing

We welcome contributions from developers who want to help make TwocanDooit even better for neurodivergent users! 

### Quick Start for Contributors

1. **Fork and Clone**
   ```bash
   git clone https://github.com/yourusername/twocandooit.git
   cd twocandooit
   ```

2. **Set Up Development Environment**
   ```bash
   flutter pub get
   flutter analyze  # Must pass with zero warnings
   flutter test     # All tests must pass
   ```

3. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make Your Changes**
   - Follow the existing code style and patterns
   - Add tests for new functionality
   - Update documentation as needed
   - Ensure accessibility considerations are maintained

5. **Test Your Changes**
   ```bash
   flutter analyze  # Must have zero warnings
   flutter test     # All tests must pass
   flutter build apk --debug  # Must build successfully
   ```

6. **Submit Pull Request**
   - Provide clear description of changes
   - Reference any related issues
   - Include screenshots for UI changes
   - Ensure CI passes

### Development Guidelines

- **Code Quality**: All code must pass `flutter analyze` with zero warnings
- **Testing**: New features require unit tests; UI changes need widget tests
- **Accessibility**: Maintain ADHD-friendly design principles
- **Documentation**: Update relevant docs and comments
- **Git**: Use clear, descriptive commit messages

### What We're Looking For

- **Accessibility improvements** for neurodiverse users
- **Bug fixes** and performance optimizations
- **New step types** or routine features
- **Documentation** improvements
- **Testing** enhancements
- **Localization** support

### Getting Help

- Check existing issues and discussions
- Review the `CLAUDE.md` file for technical architecture details
- Ask questions in pull request comments
- Follow the existing code patterns and naming conventions

### Code of Conduct

We maintain a welcoming, supportive environment that reflects Twocan's encouraging spirit. Please be kind, patient, and constructive in all interactions.

### Accessibility-First Development

When contributing to TwocanDooit, please keep these principles in mind:

- **Cognitive Load**: Minimize mental effort required to understand and use features
- **Clear Language**: Use simple, direct language in all user-facing text
- **Visual Hierarchy**: Ensure important information stands out clearly
- **Flexible Navigation**: Provide multiple ways to accomplish tasks
- **Error Prevention**: Design to prevent mistakes rather than just handle them
- **Consistent Patterns**: Follow established UI patterns throughout the app

### Testing with Neurodivergent Users

When possible, test your changes with:
- Users who have ADHD
- People with executive function challenges
- Those who use assistive technologies
- Users with different sensory sensitivities

## 🧠 Design Philosophy

TwocanDooit is designed specifically for neurodivergent folks, burnout survivors, and anyone rebuilding executive function gently:

- **Single-Task Focus**: No overwhelm, just one thing at a time
- **Encouraging Tone**: Never judgmental, always supportive
- **Customizable Experience**: Adjust to match your brain's needs
- **Gentle Guidance**: Cozy audio and visual cues without pressure
- **Flexible Interaction**: Multiple ways to navigate and interact
- **Respect for Focus**: Smart UI that gets out of your way
- **Celebration Culture**: Every small win deserves recognition

## 🎯 Why "TwocanDooit"?

The name combines our supportive toucan mascot with the empowering phrase "you can do it!" - because with the right tools, encouragement, and a silly bird by your side, anyone can tackle their routines. Twocan represents the belief that challenges become manageable when broken down into steps and approached with patience, positivity, and maybe a few dice rolls.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎵 Audio Acknowledgments

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

## 🙏 Credits

- Icons from Google Material Design
- Flutter team for the amazing framework
- The ADHD and neurodivergent community for feedback and inspiration
- Twocan mascot concept: your cheerful sidekick who believes in you unreasonably ✨

---

*"Let's try together." - Twocan* 🐦💙