import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/routine_provider.dart';
import '../../services/tts_service.dart';
import '../../services/routine_import_export_service.dart';
// import '../widgets/llm_status_widget.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<dynamic> _availableLanguages = [];
  List<dynamic> _availableVoices = [];
  bool _isLoadingLanguages = false;
  bool _isLoadingVoices = false;
  final _ttsTestController = TextEditingController(
    text: 'This is a test of the text to speech feature. Your current language and voice settings sound like this.',
  );

  @override
  void initState() {
    super.initState();
    _loadLanguages();
    _loadVoices();
  }

  @override
  void dispose() {
    _ttsTestController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguages() async {
    setState(() => _isLoadingLanguages = true);
    try {
      _availableLanguages = await TTSService.getLanguages();
    } catch (e) {
      debugPrint('Failed to load TTS languages: $e');
    } finally {
      setState(() => _isLoadingLanguages = false);
    }
  }

  Future<void> _loadVoices() async {
    setState(() => _isLoadingVoices = true);
    try {
      _availableVoices = await TTSService.getVoices();
    } catch (e) {
      debugPrint('Failed to load TTS voices: $e');
    } finally {
      setState(() => _isLoadingVoices = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = settingsProvider.settings;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // TTS Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.record_voice_over,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Text-to-Speech',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Read steps aloud during routine execution',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Enable TTS Toggle
                      SwitchListTile(
                        title: const Text('Enable Text-to-Speech'),
                        subtitle: const Text('Automatically read step instructions'),
                        value: settings.ttsEnabled,
                        onChanged: (value) {
                          settingsProvider.updateTTSEnabled(value);
                        },
                      ),
                      
                      if (settings.ttsEnabled) ...[
                        const SizedBox(height: 16),
                        
                        // Speech Rate
                        Text(
                          'Speech Rate: ${settings.ttsRate.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Slider(
                          value: settings.ttsRate,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          onChanged: (value) {
                            settingsProvider.updateTTSRate(value);
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Speech Pitch
                        Text(
                          'Speech Pitch: ${settings.ttsPitch.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Slider(
                          value: settings.ttsPitch,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          onChanged: (value) {
                            settingsProvider.updateTTSPitch(value);
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Speech Volume
                        Text(
                          'Speech Volume: ${(settings.ttsVolume * 100).round()}%',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Slider(
                          value: settings.ttsVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          onChanged: (value) {
                            settingsProvider.updateTTSVolume(value);
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Language Selection
                        if (_availableLanguages.isNotEmpty) ...[
                          Text(
                            'Language',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _getSelectedLanguageCode(settings.ttsLanguage),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _getLanguageDropdownItems(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                settingsProvider.updateTTSLanguage(newValue);
                                // Clear the selected voice when language changes since voices are language-specific
                                settingsProvider.updateTTSVoice(null);
                              }
                            },
                          ),
                        ] else if (_isLoadingLanguages) ...[
                          const Center(child: CircularProgressIndicator()),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Voice Selection
                        if (_availableVoices.isNotEmpty) ...[
                          Text(
                            'Voice',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final selectedLanguage = _getSelectedLanguageCode(settings.ttsLanguage) ?? 'en';
                              return DropdownButtonFormField<String>(
                                // ignore: deprecated_member_use
                                value: _getSelectedVoice(settings.ttsVoice, settings.ttsVoiceLocale, selectedLanguage),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: _getVoiceDropdownItems(selectedLanguage),
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue.contains('|')) {
                                    final parts = newValue.split('|');
                                    final voiceName = parts[0];
                                    final voiceLocale = parts[1];
                                    settingsProvider.updateTTSVoice(voiceName, voiceLocale: voiceLocale);
                                  } else {
                                    settingsProvider.updateTTSVoice(newValue);
                                  }
                                },
                              );
                            }
                          ),
                        ] else if (_isLoadingVoices) ...[
                          Text(
                            'Voice',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Center(child: CircularProgressIndicator()),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Test TTS Text Input
                        Text(
                          'Test Text',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ttsTestController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter text to test speech...',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          maxLines: 3,
                          minLines: 2,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Test TTS Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _testTTS(settings),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Test Speech'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Nudge Notifications Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Nudge Notifications',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get reminded if you stay on a step too long',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Enable Nudges Toggle
                      SwitchListTile(
                        title: const Text('Enable Nudge Notifications'),
                        subtitle: const Text('Get reminded when stuck on a step'),
                        value: settings.nudgeEnabled,
                        onChanged: (value) {
                          settingsProvider.updateNudgeEnabled(value);
                        },
                      ),
                      
                      if (settings.nudgeEnabled) ...[
                        const SizedBox(height: 16),
                        
                        // Nudge Interval
                        Text(
                          'Nudge Interval: ${settings.nudgeIntervalMinutes} minutes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Slider(
                          value: settings.nudgeIntervalMinutes.toDouble(),
                          min: 1.0,
                          max: 30.0,
                          divisions: 29,
                          label: '${settings.nudgeIntervalMinutes} min',
                          onChanged: (value) {
                            settingsProvider.updateNudgeInterval(value.round());
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Max Nudge Count
                        Text(
                          'Max Nudges: ${settings.maxNudgeCount}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Slider(
                          value: settings.maxNudgeCount.toDouble(),
                          min: 1.0,
                          max: 10.0,
                          divisions: 9,
                          label: '${settings.maxNudgeCount}',
                          onChanged: (value) {
                            settingsProvider.updateMaxNudgeCount(value.round());
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Feedback Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.vibration,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Feedback',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Audio and haptic feedback for interactions',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Audio Feedback Toggle
                      SwitchListTile(
                        title: const Text('Audio Feedback'),
                        subtitle: const Text('Play sounds for button clicks and completions'),
                        value: settings.audioFeedbackEnabled,
                        onChanged: (value) {
                          settingsProvider.updateAudioFeedbackEnabled(value);
                        },
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Haptic Feedback Toggle
                      SwitchListTile(
                        title: const Text('Haptic Feedback'),
                        subtitle: const Text('Vibrate for interactions and completions'),
                        value: settings.hapticFeedbackEnabled,
                        onChanged: (value) {
                          settingsProvider.updateHapticFeedbackEnabled(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Appearance Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Appearance',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customize the app appearance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Dark Mode Toggle
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Use dark theme colors'),
                        value: settings.isDarkMode,
                        onChanged: (value) {
                          settingsProvider.updateThemeMode(value);
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Onboarding Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const OnboardingScreen(canSkip: false),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Restart Setup Wizard'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // LLM Status Section
              // const LLMStatusWidget(),
              // 
              // const SizedBox(height: 20),
              // 
              // // LLM Demo Section (only show if LLM is available)
              // const LLMDemoWidget(),
              // 
              // const SizedBox(height: 20),
              
              // Import/Export Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.import_export,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Import & Export',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share routines or import from external sources',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Import Buttons
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _importRoutineFromFile,
                              icon: const Icon(Icons.file_upload),
                              label: const Text('From File'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _importRoutineFromClipboard,
                              icon: const Icon(Icons.content_paste),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('From Clipboard'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Share All Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _exportAllRoutines,
                          icon: const Icon(Icons.share),
                          label: const Text('Share All Routines'),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // LLM Prompt Generator Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _generateLLMPrompt,
                          icon: const Icon(Icons.psychology, size: 16),
                          label: const Text('Generate LLM Prompt'),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Format Info Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _showFormatInfo,
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Format Documentation'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // About Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'About',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'TwocanDooit',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.1+3',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A cozy, ADHD-friendly routine helper with your colorful toucan sidekick. Features step-by-step guidance, interactive dice rolling, routine analytics, and gentle encouragement to help make tasks feel safe, possible, and even fun.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> _getLanguageDropdownItems() {
    final languageMap = <String, String>{};
    
    // Group languages by language code
    for (final language in _availableLanguages) {
      final languageCode = _getLanguageCode(language.toString());
      final displayName = _getLanguageDisplayName(language.toString());
      
      if (!languageMap.containsKey(languageCode)) {
        languageMap[languageCode] = displayName;
      }
    }
    
    // Create dropdown items
    final items = languageMap.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value),
      );
    }).toList();
    
    // Sort by display name
    items.sort((a, b) => (a.child as Text).data!.compareTo((b.child as Text).data!));
    
    return items;
  }

  String _getLanguageCode(String locale) {
    // Extract language code from locale (e.g., "en-US" -> "en")
    return locale.split('-').first;
  }
  
  String _getLanguageDisplayName(String locale) {
    final languageCode = _getLanguageCode(locale);
    
    // Map language codes to display names
    const languageNames = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ar': 'Arabic',
      'hi': 'Hindi',
      'th': 'Thai',
      'vi': 'Vietnamese',
      'nl': 'Dutch',
      'sv': 'Swedish',
      'da': 'Danish',
      'no': 'Norwegian',
      'nb': 'Norwegian',
      'fi': 'Finnish',
      'pl': 'Polish',
      'cs': 'Czech',
      'hu': 'Hungarian',
      'ro': 'Romanian',
      'bg': 'Bulgarian',
      'hr': 'Croatian',
      'sk': 'Slovak',
      'sl': 'Slovenian',
      'et': 'Estonian',
      'lv': 'Latvian',
      'lt': 'Lithuanian',
      'uk': 'Ukrainian',
      'he': 'Hebrew',
      'tr': 'Turkish',
      'el': 'Greek',
      'ca': 'Catalan',
      'eu': 'Basque',
      'gl': 'Galician',
      'is': 'Icelandic',
      'ga': 'Irish',
      'cy': 'Welsh',
      'mt': 'Maltese',
      'sq': 'Albanian',
      'mk': 'Macedonian',
      'sr': 'Serbian',
      'bs': 'Bosnian',
      'id': 'Indonesian',
      'ms': 'Malay',
      'fil': 'Filipino',
      'tl': 'Tagalog',
      'jv': 'Javanese',
      'su': 'Sundanese',
      'ta': 'Tamil',
      'te': 'Telugu',
      'kn': 'Kannada',
      'ml': 'Malayalam',
      'bn': 'Bengali',
      'gu': 'Gujarati',
      'pa': 'Punjabi',
      'mr': 'Marathi',
      'ne': 'Nepali',
      'si': 'Sinhala',
      'my': 'Burmese',
      'km': 'Khmer',
      'lo': 'Lao',
      'ka': 'Georgian',
      'am': 'Amharic',
      'sw': 'Swahili',
      'zu': 'Zulu',
      'af': 'Afrikaans',
      'ur': 'Urdu',
      'fa': 'Persian',
      'ps': 'Pashto',
      'ku': 'Kurdish',
      'yi': 'Yiddish',
      'la': 'Latin',
      'eo': 'Esperanto',
    };
    
    return languageNames[languageCode] ?? locale;
  }

  String _createVoiceDisplayName(String voiceName, String locale, bool isLocal) {
    final parts = locale.split('-');
    
    // Extract region/country code
    String regionName = '';
    if (parts.length >= 2) {
      final regionCode = parts[1].toUpperCase();
      const regionNames = {
        'US': 'US',
        'GB': 'UK', 
        'AU': 'Australia',
        'CA': 'Canada',
        'IN': 'India',
        'ZA': 'South Africa',
        'IE': 'Ireland',
        'NZ': 'New Zealand',
        'SG': 'Singapore',
        'HK': 'Hong Kong',
        'PH': 'Philippines',
        'MY': 'Malaysia',
        'NG': 'Nigeria',
        'ES': 'Spain',
        'MX': 'Mexico',
        'AR': 'Argentina',
        'CO': 'Colombia',
        'FR': 'France',
        'BE': 'Belgium',
        'CH': 'Switzerland',
        'DE': 'Germany',
        'AT': 'Austria',
        'IT': 'Italy',
        'PT': 'Portugal',
        'BR': 'Brazil',
        'RU': 'Russia',
        'CN': 'China',
        'TW': 'Taiwan',
        'JP': 'Japan',
        'KR': 'Korea',
        'TH': 'Thailand',
        'VN': 'Vietnam',
        'ID': 'Indonesia',
        'NL': 'Netherlands',
        'SE': 'Sweden',
        'NO': 'Norway',
        'DK': 'Denmark',
        'FI': 'Finland',
        'PL': 'Poland',
        'CZ': 'Czech Republic',
        'SK': 'Slovakia',
        'HU': 'Hungary',
        'RO': 'Romania',
        'BG': 'Bulgaria',
        'HR': 'Croatia',
        'SI': 'Slovenia',
        'EE': 'Estonia',
        'LV': 'Latvia',
        'LT': 'Lithuania',
        'TR': 'Turkey',
        'GR': 'Greece',
        'IL': 'Israel',
      };
      regionName = regionNames[regionCode] ?? regionCode;
    }

    // Handle different voice name patterns
    if (voiceName.contains('-language')) {
      // Standard language voices: show as region + type
      final voiceType = isLocal ? 'Local' : 'Online';
      return regionName.isNotEmpty ? '$regionName $voiceType' : voiceType;
    } 
    
    // For other voices, we'll number them by region and type
    // This will be handled by the sorting and grouping logic
    final voiceType = isLocal ? 'Local' : 'Online';
    return regionName.isNotEmpty ? '$regionName $voiceType' : voiceType;
  }

  List<DropdownMenuItem<String>> _getVoiceDropdownItems(String selectedLanguage) {
    final items = <DropdownMenuItem<String>>[];

    // Filter and prioritize voices
    final voiceData = <Map<String, String>>[];
    
    for (final voice in _availableVoices) {
      if (voice is Map) {
        
        final name = voice['name']?.toString();
        final locale = voice['locale']?.toString();
        final quality = voice['quality']?.toString();
        final networkRequired = voice['network_required']?.toString();
        final latency = voice['latency']?.toString();
        
        if (name != null && name.isNotEmpty && locale != null) {
          final voiceLanguageCode = _getLanguageCode(locale);
          if (voiceLanguageCode == selectedLanguage) {
            
            // Only skip truly low quality voices, not null/unknown quality
            if (quality == 'low') continue;
            
            // Prefer local voices over network voices
            final isLocal = networkRequired == '0' || networkRequired == 'false';
            final isHighQuality = quality == 'high';
            
            // Create a simple, honest display name
            String displayName = _createVoiceDisplayName(name, locale, isLocal);
            
            voiceData.add({
              'name': name,
              'locale': locale,
              'displayName': displayName,
              'isLocal': isLocal.toString(),
              'isHighQuality': isHighQuality.toString(),
              'latency': latency ?? 'unknown',
            });
          }
        }
      }
    }

    // First, group voices by locale to apply quality filtering per locale
    final Map<String, List<Map<String, String>>> voicesByLocale = {};
    
    for (final voice in voiceData) {
      final locale = voice['locale']!;
      voicesByLocale.putIfAbsent(locale, () => []);
      voicesByLocale[locale]!.add(voice);
    }
    
    // Filter each locale's voices for best quality/latency
    final filteredVoiceData = <Map<String, String>>[];
    
    for (final locale in voicesByLocale.keys) {
      final localeVoices = voicesByLocale[locale]!;
      
      // Check if this locale has any high quality, low latency voices
      final highQualityLowLatency = localeVoices.where((voice) =>
        voice['isHighQuality'] == 'true' && 
        (voice['latency']?.toString() == 'low' || voice['latency'] == null) // treat null latency as acceptable
      ).toList();
      
      if (highQualityLowLatency.isNotEmpty) {
        // Use only high quality, low latency voices for this locale
        filteredVoiceData.addAll(highQualityLowLatency);
      } else {
        // No high quality, low latency voices available - use all voices for this locale
        filteredVoiceData.addAll(localeVoices);
      }
    }
    
    // Group filtered voices by region and type
    final Map<String, List<Map<String, String>>> voicesByRegionAndType = {};
    
    for (final voice in filteredVoiceData) {
      final locale = voice['locale']!;
      final isLocal = voice['isLocal'] == 'true';
      final regionCode = locale.split('-')[1].toUpperCase();
      
      // Create region display name
      const regionNames = {
        'US': 'US',
        'GB': 'UK', 
        'AU': 'Australia',
        'CA': 'Canada',
        'IN': 'India',
        'ZA': 'South Africa',
        'IE': 'Ireland',
        'NZ': 'New Zealand',
        'SG': 'Singapore',
        'HK': 'Hong Kong',
        'PH': 'Philippines',
        'MY': 'Malaysia',
        'NG': 'Nigeria',
      };
      final regionName = regionNames[regionCode] ?? regionCode;
      final voiceType = isLocal ? 'Local' : 'Online';
      final key = '$regionName $voiceType';
      
      voicesByRegionAndType.putIfAbsent(key, () => []);
      voicesByRegionAndType[key]!.add(voice);
    }
    
    // Sort voices within each group by quality (high quality first)
    for (final groupVoices in voicesByRegionAndType.values) {
      groupVoices.sort((a, b) {
        final aHigh = a['isHighQuality'] == 'true';
        final bHigh = b['isHighQuality'] == 'true';
        if (aHigh != bHigh) return aHigh ? -1 : 1;
        return a['name']!.compareTo(b['name']!);
      });
    }
    
    // Sort groups: US first, then alphabetically
    final sortedKeys = voicesByRegionAndType.keys.toList();
    sortedKeys.sort((a, b) {
      if (a.startsWith('US ') && !b.startsWith('US ')) return -1;
      if (!a.startsWith('US ') && b.startsWith('US ')) return 1;
      return a.compareTo(b);
    });
    
    // Build final voice list with numbering
    final allVoices = <Map<String, String>>[];
    for (final key in sortedKeys) {
      final groupVoices = voicesByRegionAndType[key]!;
      for (int i = 0; i < groupVoices.length; i++) {
        final voice = Map<String, String>.from(groupVoices[i]);
        final number = groupVoices.length > 1 ? ' ${i + 1}' : '';
        voice['finalDisplayName'] = '$key$number';
        allVoices.add(voice);
      }
    }

    final limitedVoices = allVoices;
    
    for (final voice in limitedVoices) {
      final finalDisplayName = voice['finalDisplayName']!;
      
      items.add(DropdownMenuItem<String>(
        value: '${voice['name']}|${voice['locale']}',
        child: Text(finalDisplayName),
      ));
      
    }
    
    return items;
  }

  String? _getSelectedLanguageCode(String currentLanguage) {
    // Handle empty or invalid language
    if (currentLanguage.isEmpty) {
      return _availableLanguages.isNotEmpty 
          ? _getLanguageCode(_availableLanguages.first.toString())
          : null;
    }
    
    // If current language looks like a voice name (contains 'x-'), extract language from it
    if (currentLanguage.contains('x-') || currentLanguage.contains('-network') || currentLanguage.contains('-local')) {
      // This is likely a voice name, extract language code from the beginning
      final parts = currentLanguage.split('-');
      if (parts.length >= 2) {
        final languageCode = parts[0];
        // Validate it's a real language code
        final hasLanguageCode = _availableLanguages.any((lang) => 
            _getLanguageCode(lang.toString()) == languageCode);
        if (hasLanguageCode) {
          return languageCode;
        }
      }
    }
    
    // If current language is already a language code (e.g., "en"), return it if valid
    if (currentLanguage.length == 2) {
      final hasLanguageCode = _availableLanguages.any((lang) => 
          _getLanguageCode(lang.toString()) == currentLanguage);
      if (hasLanguageCode) {
        return currentLanguage;
      }
    }
    
    // If current language is a locale (e.g., "en-US"), extract the language code
    final languageCode = _getLanguageCode(currentLanguage);
    
    // Check if we have any languages for this code
    final hasLanguageCode = _availableLanguages.any((lang) => 
        _getLanguageCode(lang.toString()) == languageCode);
    
    if (hasLanguageCode) {
      return languageCode;
    }
    
    // Fallback to first available language code
    return _availableLanguages.isNotEmpty 
        ? _getLanguageCode(_availableLanguages.first.toString())
        : null;
  }

  String? _getSelectedVoice(String? currentVoice, String? currentVoiceLocale, String selectedLanguage) {
    if (currentVoice == null || currentVoice.isEmpty) {
      return null;
    }
    
    // Get the current voice dropdown items for this language
    final currentItems = _getVoiceDropdownItems(selectedLanguage);
    
    // Look for exact match with voice name and locale
    if (currentVoiceLocale != null) {
      final expectedValue = '$currentVoice|$currentVoiceLocale';
      for (final item in currentItems) {
        if (item.value == expectedValue) {
          return expectedValue;
        }
      }
    }
    
    // If not found, try to find any voice with the same name
    for (final item in currentItems) {
      if (item.value != null && item.value!.startsWith('$currentVoice|')) {
        return item.value;
      }
    }
    
    // If still not found, return null (will show "Default Voice")
    return null;
  }

  void _testTTS(AppSettings settings) async {
    final testText = _ttsTestController.text.trim();
    if (testText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text to test speech'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    debugPrint('Test TTS button pressed');
    debugPrint('TTS Enabled: ${settings.ttsEnabled}');
    debugPrint('TTS Rate: ${settings.ttsRate}');
    debugPrint('TTS Language: ${settings.ttsLanguage}');
    debugPrint('TTS Voice: ${settings.ttsVoice}');
    debugPrint('Test Text: $testText');
    
    await TTSService.speak(
      testText,
      settings,
    );
    debugPrint('TTS speak call completed');
  }

  // Import/Export Methods

  Future<void> _importRoutineFromFile() async {
    try {
      final routine = await RoutineImportExportService.instance.pickAndImportRoutine();
      
      if (routine != null && mounted) {
        final routineProvider = Provider.of<RoutineProvider>(context, listen: false);
        await routineProvider.importRoutine(routine);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported "${routine.name}"'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to import routine. Please check the file format.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importRoutineFromClipboard() async {
    try {
      final routine = await RoutineImportExportService.instance.importRoutineFromClipboard();
      
      if (routine != null && mounted) {
        final routineProvider = Provider.of<RoutineProvider>(context, listen: false);
        await routineProvider.importRoutine(routine);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported "${routine.name}" from clipboard'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No valid routine found in clipboard. Make sure you copied a routine JSON.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clipboard import error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _exportAllRoutines() async {
    try {
      final routineProvider = Provider.of<RoutineProvider>(context, listen: false);
      final routines = routineProvider.routines;
      
      if (routines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No routines to export')),
        );
        return;
      }
      
      final result = await RoutineImportExportService.instance.shareRoutines(
        routines, 
        'my_routines'
      );
      
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared ${routines.length} routines successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to share routines. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // result == null means user cancelled, so we don't show any message
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showFormatInfo() {
    final documentation = RoutineImportExportService.instance.getFormatDocumentation();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Routine Format Documentation'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              documentation,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              final sample = RoutineImportExportService.instance.createSampleExport();
              _showSampleExport(sample);
            },
            child: const Text('View Sample'),
          ),
        ],
      ),
    );
  }

  void _showSampleExport(String sample) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sample Routine Export'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              sample,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _generateLLMPrompt() {
    // Show dialog to optionally get user request
    showDialog(
      context: context,
      builder: (context) => _LLMPromptDialog(),
    );
  }

}

class _LLMPromptDialog extends StatefulWidget {
  @override
  State<_LLMPromptDialog> createState() => _LLMPromptDialogState();
}

class _LLMPromptDialogState extends State<_LLMPromptDialog> {
  final _requestController = TextEditingController();
  String? _generatedPrompt;

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  void _generatePrompt() {
    final userRequest = _requestController.text.trim();
    final prompt = RoutineImportExportService.instance.generateLLMPrompt(
      userRequest: userRequest.isEmpty ? null : userRequest,
    );
    
    setState(() {
      _generatedPrompt = prompt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('LLM Prompt Generator'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: double.maxFinite,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate a comprehensive prompt for an LLM to create ADHD-friendly routines. Optionally describe what kind of routine you want:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _requestController,
              decoration: const InputDecoration(
                labelText: 'Routine Request (Optional)',
                hintText: 'e.g., "Create a morning routine for someone with ADHD who struggles with time management"',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _generatePrompt,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Generate Prompt'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_generatedPrompt != null) ...[
              const Text(
                'Generated Prompt:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _generatedPrompt!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Text(
                    'Click "Generate Prompt" to create a comprehensive LLM prompt with schema and context.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        if (_generatedPrompt != null)
          FilledButton.icon(
            onPressed: () async {
              if (!mounted) return;
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: _generatedPrompt!));
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Prompt copied to clipboard!')),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
          ),
      ],
    );
  }
}