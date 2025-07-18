class AppSettings {
  final bool ttsEnabled;
  final double ttsRate;
  final double ttsPitch;
  final double ttsVolume;
  final String ttsLanguage;
  final String? ttsVoice;
  final String? ttsVoiceLocale;
  
  // Nudge notification settings
  final bool nudgeEnabled;
  final int nudgeIntervalMinutes;
  final int maxNudgeCount;
  
  // Audio and haptic feedback settings
  final bool audioFeedbackEnabled;
  final bool hapticFeedbackEnabled;
  
  // Theme settings
  final bool isDarkMode;
  
  // Accessibility settings
  final bool reducedAnimations;
  final bool focusMode;
  final bool simplifiedUI;
  
  // User preferences
  final String userName;
  final bool hasCompletedOnboarding;
  
  // Tutorial state tracking
  final bool hasSeenBasicStepTutorial;
  final bool hasSeenTimerStepTutorial;
  final bool hasSeenRepsStepTutorial;
  final bool hasSeenRandomRepsStepTutorial;
  final bool hasSeenRandomChoiceStepTutorial;

  const AppSettings({
    this.ttsEnabled = false,
    this.ttsRate = 0.5,
    this.ttsPitch = 1.0,
    this.ttsVolume = 1.0,
    this.ttsLanguage = 'en-US',
    this.ttsVoice,
    this.ttsVoiceLocale,
    this.nudgeEnabled = true,
    this.nudgeIntervalMinutes = 5,
    this.maxNudgeCount = 3,
    this.audioFeedbackEnabled = true,
    this.hapticFeedbackEnabled = true,
    this.isDarkMode = true,
    this.reducedAnimations = false,
    this.focusMode = false,
    this.simplifiedUI = false,
    this.userName = '',
    this.hasCompletedOnboarding = false,
    this.hasSeenBasicStepTutorial = false,
    this.hasSeenTimerStepTutorial = false,
    this.hasSeenRepsStepTutorial = false,
    this.hasSeenRandomRepsStepTutorial = false,
    this.hasSeenRandomChoiceStepTutorial = false,
  });

  AppSettings copyWith({
    bool? ttsEnabled,
    double? ttsRate,
    double? ttsPitch,
    double? ttsVolume,
    String? ttsLanguage,
    String? ttsVoice,
    String? ttsVoiceLocale,
    bool? nudgeEnabled,
    int? nudgeIntervalMinutes,
    int? maxNudgeCount,
    bool? audioFeedbackEnabled,
    bool? hapticFeedbackEnabled,
    bool? isDarkMode,
    bool? reducedAnimations,
    bool? focusMode,
    bool? simplifiedUI,
    String? userName,
    bool? hasCompletedOnboarding,
    bool? hasSeenBasicStepTutorial,
    bool? hasSeenTimerStepTutorial,
    bool? hasSeenRepsStepTutorial,
    bool? hasSeenRandomRepsStepTutorial,
    bool? hasSeenRandomChoiceStepTutorial,
  }) {
    return AppSettings(
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      ttsVolume: ttsVolume ?? this.ttsVolume,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      ttsVoiceLocale: ttsVoiceLocale ?? this.ttsVoiceLocale,
      nudgeEnabled: nudgeEnabled ?? this.nudgeEnabled,
      nudgeIntervalMinutes: nudgeIntervalMinutes ?? this.nudgeIntervalMinutes,
      maxNudgeCount: maxNudgeCount ?? this.maxNudgeCount,
      audioFeedbackEnabled: audioFeedbackEnabled ?? this.audioFeedbackEnabled,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      reducedAnimations: reducedAnimations ?? this.reducedAnimations,
      focusMode: focusMode ?? this.focusMode,
      simplifiedUI: simplifiedUI ?? this.simplifiedUI,
      userName: userName ?? this.userName,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasSeenBasicStepTutorial: hasSeenBasicStepTutorial ?? this.hasSeenBasicStepTutorial,
      hasSeenTimerStepTutorial: hasSeenTimerStepTutorial ?? this.hasSeenTimerStepTutorial,
      hasSeenRepsStepTutorial: hasSeenRepsStepTutorial ?? this.hasSeenRepsStepTutorial,
      hasSeenRandomRepsStepTutorial: hasSeenRandomRepsStepTutorial ?? this.hasSeenRandomRepsStepTutorial,
      hasSeenRandomChoiceStepTutorial: hasSeenRandomChoiceStepTutorial ?? this.hasSeenRandomChoiceStepTutorial,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ttsEnabled': ttsEnabled,
      'ttsRate': ttsRate,
      'ttsPitch': ttsPitch,
      'ttsVolume': ttsVolume,
      'ttsLanguage': ttsLanguage,
      'ttsVoice': ttsVoice,
      'ttsVoiceLocale': ttsVoiceLocale,
      'nudgeEnabled': nudgeEnabled,
      'nudgeIntervalMinutes': nudgeIntervalMinutes,
      'maxNudgeCount': maxNudgeCount,
      'audioFeedbackEnabled': audioFeedbackEnabled,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
      'isDarkMode': isDarkMode,
      'reducedAnimations': reducedAnimations,
      'focusMode': focusMode,
      'simplifiedUI': simplifiedUI,
      'userName': userName,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasSeenBasicStepTutorial': hasSeenBasicStepTutorial,
      'hasSeenTimerStepTutorial': hasSeenTimerStepTutorial,
      'hasSeenRepsStepTutorial': hasSeenRepsStepTutorial,
      'hasSeenRandomRepsStepTutorial': hasSeenRandomRepsStepTutorial,
      'hasSeenRandomChoiceStepTutorial': hasSeenRandomChoiceStepTutorial,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      ttsEnabled: json['ttsEnabled'] ?? false,
      ttsRate: _parseDouble(json['ttsRate'], 0.5),
      ttsPitch: _parseDouble(json['ttsPitch'], 1.0),
      ttsVolume: _parseDouble(json['ttsVolume'], 1.0),
      ttsLanguage: json['ttsLanguage'] ?? 'en-US',
      ttsVoice: json['ttsVoice'],
      ttsVoiceLocale: json['ttsVoiceLocale'],
      nudgeEnabled: json['nudgeEnabled'] ?? true,
      nudgeIntervalMinutes: _parseInt(json['nudgeIntervalMinutes'], 5),
      maxNudgeCount: _parseInt(json['maxNudgeCount'], 3),
      audioFeedbackEnabled: json['audioFeedbackEnabled'] ?? true,
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] ?? true,
      isDarkMode: json['isDarkMode'] ?? true,
      reducedAnimations: json['reducedAnimations'] ?? false,
      focusMode: json['focusMode'] ?? false,
      simplifiedUI: json['simplifiedUI'] ?? false,
      userName: json['userName'] ?? '',
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      hasSeenBasicStepTutorial: json['hasSeenBasicStepTutorial'] ?? false,
      hasSeenTimerStepTutorial: json['hasSeenTimerStepTutorial'] ?? false,
      hasSeenRepsStepTutorial: json['hasSeenRepsStepTutorial'] ?? false,
      hasSeenRandomRepsStepTutorial: json['hasSeenRandomRepsStepTutorial'] ?? false,
      hasSeenRandomChoiceStepTutorial: json['hasSeenRandomChoiceStepTutorial'] ?? false,
    );
  }

  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}