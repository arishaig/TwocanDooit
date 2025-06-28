class AppSettings {
  final bool ttsEnabled;
  final double ttsRate;
  final double ttsPitch;
  final double ttsVolume;
  final String ttsLanguage;
  
  // Nudge notification settings
  final bool nudgeEnabled;
  final int nudgeIntervalMinutes;
  final int maxNudgeCount;
  
  // Audio and haptic feedback settings
  final bool audioFeedbackEnabled;
  final bool hapticFeedbackEnabled;

  const AppSettings({
    this.ttsEnabled = false,
    this.ttsRate = 0.5,
    this.ttsPitch = 1.0,
    this.ttsVolume = 1.0,
    this.ttsLanguage = 'en-US',
    this.nudgeEnabled = true,
    this.nudgeIntervalMinutes = 5,
    this.maxNudgeCount = 3,
    this.audioFeedbackEnabled = true,
    this.hapticFeedbackEnabled = true,
  });

  AppSettings copyWith({
    bool? ttsEnabled,
    double? ttsRate,
    double? ttsPitch,
    double? ttsVolume,
    String? ttsLanguage,
    bool? nudgeEnabled,
    int? nudgeIntervalMinutes,
    int? maxNudgeCount,
    bool? audioFeedbackEnabled,
    bool? hapticFeedbackEnabled,
  }) {
    return AppSettings(
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      ttsVolume: ttsVolume ?? this.ttsVolume,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      nudgeEnabled: nudgeEnabled ?? this.nudgeEnabled,
      nudgeIntervalMinutes: nudgeIntervalMinutes ?? this.nudgeIntervalMinutes,
      maxNudgeCount: maxNudgeCount ?? this.maxNudgeCount,
      audioFeedbackEnabled: audioFeedbackEnabled ?? this.audioFeedbackEnabled,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ttsEnabled': ttsEnabled,
      'ttsRate': ttsRate,
      'ttsPitch': ttsPitch,
      'ttsVolume': ttsVolume,
      'ttsLanguage': ttsLanguage,
      'nudgeEnabled': nudgeEnabled,
      'nudgeIntervalMinutes': nudgeIntervalMinutes,
      'maxNudgeCount': maxNudgeCount,
      'audioFeedbackEnabled': audioFeedbackEnabled,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      ttsEnabled: json['ttsEnabled'] ?? false,
      ttsRate: (json['ttsRate'] ?? 0.5).toDouble(),
      ttsPitch: (json['ttsPitch'] ?? 1.0).toDouble(),
      ttsVolume: (json['ttsVolume'] ?? 1.0).toDouble(),
      ttsLanguage: json['ttsLanguage'] ?? 'en-US',
      nudgeEnabled: json['nudgeEnabled'] ?? true,
      nudgeIntervalMinutes: json['nudgeIntervalMinutes'] ?? 5,
      maxNudgeCount: json['maxNudgeCount'] ?? 3,
      audioFeedbackEnabled: json['audioFeedbackEnabled'] ?? true,
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] ?? true,
    );
  }
}