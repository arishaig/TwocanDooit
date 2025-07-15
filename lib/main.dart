import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/routine_provider.dart';
import 'providers/execution_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/schedule_service.dart';
// import 'services/llm/local_llm_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service and request permissions
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  
  // Initialize schedule service
  await ScheduleService().initialize();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase initialization failed - this is expected in test environments
    debugPrint('Firebase initialization skipped: $e');
  }
  
  // Initialize Local AI service (on-device Gemma model)
  // try {
  //   await LocalLLMService.instance.initialize();
  //   print('Local AI initialized successfully');
  // } catch (e) {
  //   print('Local AI initialization failed: $e');
  //   // App continues to work without AI features
  // }
  
  runApp(const TwocanDooitApp());
}

class TwocanDooitApp extends StatefulWidget {
  const TwocanDooitApp({super.key});
  
  static bool get isAppInForeground => _TwocanDooitAppState._currentState == AppLifecycleState.resumed;

  @override
  State<TwocanDooitApp> createState() => _TwocanDooitAppState();
}

class _TwocanDooitAppState extends State<TwocanDooitApp> with WidgetsBindingObserver {
  static AppLifecycleState _currentState = AppLifecycleState.resumed;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupNotificationActionListener();
  }
  
  /// Setup listener for notification actions
  void _setupNotificationActionListener() {
    NotificationService.notificationActionStream.listen((action) {
      final parts = action.split(':');
      if (parts.length >= 2) {
        final actionType = parts[0];
        final scheduleId = parts[1];
        
        switch (actionType) {
          case 'start':
            if (parts.length >= 3) {
              final routineId = parts[2];
              _handleStartRoutine(scheduleId, routineId);
            }
            break;
          case 'snooze':
            _handleSnoozeSchedule(scheduleId);
            break;
          case 'skip':
            _handleSkipSchedule(scheduleId);
            break;
        }
      }
    });
  }
  
  /// Handle start routine action
  void _handleStartRoutine(String scheduleId, String routineId) {
    debugPrint('Handling start routine: $scheduleId, $routineId');
    // Mark schedule as triggered
    ScheduleService().handleScheduleTrigger(scheduleId);
    
    // Navigate to routine execution
    // This would need to be implemented with proper navigation
    // For now, just log the action
    debugPrint('Would navigate to routine execution for: $routineId');
  }
  
  /// Handle snooze schedule action
  void _handleSnoozeSchedule(String scheduleId) {
    debugPrint('Handling snooze schedule: $scheduleId');
    ScheduleService().snoozeSchedule(scheduleId);
  }
  
  /// Handle skip schedule action
  void _handleSkipSchedule(String scheduleId) {
    debugPrint('Handling skip schedule: $scheduleId');
    ScheduleService().skipSchedule(scheduleId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle changed to: $state');
    _currentState = state;
    if (state == AppLifecycleState.resumed) {
      // App regained focus - dismiss nudge notifications
      NotificationService.dismissNudgeNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(create: (_) => ExecutionProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) => MaterialApp(
          title: 'TwocanDooit',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            // Add more locales here as needed
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              // Twocan brand colors from brand guide
              primary: Color(0xFF2D7A9A),        // 🐦 Toucan Blue
              secondary: Color(0xFFFFAD49),      // 🍊 Beak Orange
              tertiary: Color(0xFFA393D3),       // 💜 Cozy Purple
              surface: Color(0xFFFFF7ED),        // 🪶 Belly Cream
              onSurface: Color(0xFF2B2B2B),      // 🌑 Charcoal Text
              onPrimary: Color(0xFFFFF7ED),      // White text on Toucan Blue
              onSecondary: Color(0xFF2B2B2B),    // Charcoal text on Beak Orange
              surfaceContainerHighest: Color(0xFFF5F5F5), // Light variant
              outline: Color(0xFFE0E0E0),        // Subtle borders
            ),
          // Mobile-friendly card theme
          cardTheme: CardThemeData(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          // Mobile-friendly button themes with larger touch targets
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56), // Larger touch target
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48), // Minimum touch target
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Mobile-friendly input decoration
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            labelStyle: const TextStyle(fontSize: 16),
            hintStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          // Mobile-friendly app bar theme
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Mobile-friendly floating action button
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: const ColorScheme.dark(
              // Twocan brand colors adapted for dark mode
              primary: Color(0xFF2D7A9A),        // 🐦 Toucan Blue
              secondary: Color(0xFFFFAD49),      // 🍊 Beak Orange
              tertiary: Color(0xFFA393D3),       // 💜 Cozy Purple
              surface: Color(0xFF1A1A1A),        // Dark surface
              onSurface: Color(0xFFFFF7ED),      // Light text
              onPrimary: Color(0xFFFFF7ED),      // White text on Toucan Blue
              onSecondary: Color(0xFF2B2B2B),    // Charcoal text on Beak Orange
              surfaceContainerHighest: Color(0xFF2A2A2A), // Dark variant
              outline: Color(0xFF404040),        // Subtle dark borders
            ),
            // Mobile-friendly card theme for dark mode
            cardTheme: CardThemeData(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            // Mobile-friendly button themes with larger touch targets
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Mobile-friendly input decoration
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              labelStyle: const TextStyle(fontSize: 16),
            ),
            // Mobile-friendly app bar theme
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Mobile-friendly floating action button
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          themeMode: settingsProvider.settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: settingsProvider.isLoading 
              ? const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : () {
                  debugPrint('Main: isLoading: ${settingsProvider.isLoading}, hasCompletedOnboarding: ${settingsProvider.settings.hasCompletedOnboarding}');
                  return settingsProvider.settings.hasCompletedOnboarding 
                      ? const HomeScreen()
                      : const OnboardingScreen();
                }(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}