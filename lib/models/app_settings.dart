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
  
  // User preferences
  final String userName;
  final bool hasCompletedOnboarding;

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
    this.userName = '',
    this.hasCompletedOnboarding = false,
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
    String? userName,
    bool? hasCompletedOnboarding,
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
      userName: userName ?? this.userName,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
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
      'userName': userName,
      'hasCompletedOnboarding': hasCompletedOnboarding,
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
      userName: json['userName'] ?? '',
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
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