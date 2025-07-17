import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/routine_provider.dart';
import '../../services/tts_service.dart';
import '../../services/routine_import_export_service.dart';
import 'onboarding_screen.dart';
import 'attribution_screen.dart';

class SettingsScreenTabbed extends StatefulWidget {
  const SettingsScreenTabbed({super.key});

  @override
  State<SettingsScreenTabbed> createState() => _SettingsScreenTabbedState();
}

class _SettingsScreenTabbedState extends State<SettingsScreenTabbed> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // TTS variables
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
    _tabController = TabController(length: 4, vsync: this);
    _loadLanguages();
    _loadVoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.accessibility), text: 'Accessibility'),
            Tab(icon: Icon(Icons.record_voice_over), text: 'Speech'),
            Tab(icon: Icon(Icons.palette), text: 'Appearance'),
            Tab(icon: Icon(Icons.import_export), text: 'Data'),
          ],
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = settingsProvider.settings;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAccessibilityTab(context, settings, settingsProvider),
              _buildSpeechTab(context, settings, settingsProvider),
              _buildAppearanceTab(context, settings, settingsProvider),
              _buildDataTab(context, settings, settingsProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccessibilityTab(BuildContext context, AppSettings settings, SettingsProvider settingsProvider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.accessibility,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Comfort & Focus',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Adjust the app to feel more comfortable and less overwhelming',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                
                SwitchListTile(
                  title: const Text('Reduced Animations'),
                  subtitle: const Text('Minimize moving elements and transitions'),
                  value: settings.reducedAnimations,
                  onChanged: (value) {
                    settingsProvider.updateReducedAnimations(value);
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Focus Mode'),
                  subtitle: const Text('Hide distracting elements during routines'),
                  value: settings.focusMode,
                  onChanged: (value) {
                    settingsProvider.updateFocusMode(value);
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Simplified Interface'),
                  subtitle: const Text('Use larger text and simpler layouts'),
                  value: settings.simplifiedUI,
                  onChanged: (value) {
                    settingsProvider.updateSimplifiedUI(value);
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Notifications Section
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
                      'Gentle Reminders',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Get helpful nudges when you need them',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                
                SwitchListTile(
                  title: const Text('Enable Gentle Nudges'),
                  subtitle: const Text('Get reminded if you stay on a step too long'),
                  value: settings.nudgeEnabled,
                  onChanged: (value) {
                    settingsProvider.updateNudgeEnabled(value);
                  },
                ),
                
                if (settings.nudgeEnabled) ...[
                  const SizedBox(height: 16),
                  
                  Text(
                    'Nudge me every ${settings.nudgeIntervalMinutes} minutes',
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
                  
                  Text(
                    'Maximum nudges: ${settings.maxNudgeCount}',
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
        
        const SizedBox(height: 16),
        
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
                      'Touch & Sound',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Feedback when you interact with the app',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                
                SwitchListTile(
                  title: const Text('Sound Effects'),
                  subtitle: const Text('Play sounds for button clicks and completions'),
                  value: settings.audioFeedbackEnabled,
                  onChanged: (value) {
                    settingsProvider.updateAudioFeedbackEnabled(value);
                  },
                ),
                
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
      ],
    );
  }

  Widget _buildSpeechTab(BuildContext context, AppSettings settings, SettingsProvider settingsProvider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                  'Have steps read aloud to help you stay focused',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                
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
                  
                  Text(
                    'Speed: ${settings.ttsRate.toStringAsFixed(1)}',
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
                  
                  Text(
                    'Pitch: ${settings.ttsPitch.toStringAsFixed(1)}',
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
                  
                  Text(
                    'Volume: ${(settings.ttsVolume * 100).round()}%',
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
                  
                  // Test TTS
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
      ],
    );
  }

  Widget _buildAppearanceTab(BuildContext context, AppSettings settings, SettingsProvider settingsProvider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                      'Visual Style',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize how the app looks and feels',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme colors'),
                  value: settings.isDarkMode,
                  onChanged: (value) {
                    settingsProvider.updateThemeMode(value);
                  },
                ),
                
                const SizedBox(height: 16),
                
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
        
        const SizedBox(height: 16),
        
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
                      'About TwocanDooit',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AttributionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copyright),
                  label: const Text('Audio & Music Credits'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTab(BuildContext context, AppSettings settings, SettingsProvider settingsProvider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
      ],
    );
  }

  // TTS Helper methods (copied from original settings screen)
  List<DropdownMenuItem<String>> _getLanguageDropdownItems() {
    final languageMap = <String, String>{};
    
    for (final language in _availableLanguages) {
      final languageCode = _getLanguageCode(language.toString());
      final displayName = _getLanguageDisplayName(language.toString());
      
      if (!languageMap.containsKey(languageCode)) {
        languageMap[languageCode] = displayName;
      }
    }
    
    final items = languageMap.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value),
      );
    }).toList();
    
    items.sort((a, b) => (a.child as Text).data!.compareTo((b.child as Text).data!));
    
    return items;
  }

  String _getLanguageCode(String locale) {
    return locale.split('-').first;
  }
  
  String _getLanguageDisplayName(String locale) {
    final languageCode = _getLanguageCode(locale);
    
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

  List<DropdownMenuItem<String>> _getVoiceDropdownItems(String selectedLanguage) {
    final items = <DropdownMenuItem<String>>[];
    final voiceData = <Map<String, String>>[];
    
    for (final voice in _availableVoices) {
      if (voice is Map) {
        final name = voice['name']?.toString();
        final locale = voice['locale']?.toString();
        final quality = voice['quality']?.toString();
        final networkRequired = voice['network_required']?.toString();
        
        if (name != null && name.isNotEmpty && locale != null) {
          final voiceLanguageCode = _getLanguageCode(locale);
          if (voiceLanguageCode == selectedLanguage) {
            if (quality == 'low') continue;
            
            final isLocal = networkRequired == '0' || networkRequired == 'false';
            final isHighQuality = quality == 'high';
            
            String displayName = _createVoiceDisplayName(name, locale, isLocal);
            
            voiceData.add({
              'name': name,
              'locale': locale,
              'displayName': displayName,
              'isLocal': isLocal.toString(),
              'isHighQuality': isHighQuality.toString(),
            });
          }
        }
      }
    }

    // Sort by quality and locality
    voiceData.sort((a, b) {
      final aLocal = a['isLocal'] == 'true';
      final bLocal = b['isLocal'] == 'true';
      if (aLocal != bLocal) return aLocal ? -1 : 1;
      
      final aHigh = a['isHighQuality'] == 'true';
      final bHigh = b['isHighQuality'] == 'true';
      if (aHigh != bHigh) return aHigh ? -1 : 1;
      
      return a['displayName']!.compareTo(b['displayName']!);
    });

    for (final voice in voiceData.take(10)) { // Limit to 10 voices
      items.add(DropdownMenuItem<String>(
        value: '${voice['name']}|${voice['locale']}',
        child: Text(voice['displayName']!),
      ));
    }
    
    return items;
  }

  String _createVoiceDisplayName(String voiceName, String locale, bool isLocal) {
    final parts = locale.split('-');
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
      };
      regionName = regionNames[regionCode] ?? regionCode;
    }

    final voiceType = isLocal ? 'Local' : 'Online';
    return regionName.isNotEmpty ? '$regionName $voiceType' : voiceType;
  }

  String? _getSelectedLanguageCode(String currentLanguage) {
    if (currentLanguage.isEmpty) {
      return _availableLanguages.isNotEmpty 
          ? _getLanguageCode(_availableLanguages.first.toString())
          : null;
    }
    
    if (currentLanguage.contains('x-') || currentLanguage.contains('-network') || currentLanguage.contains('-local')) {
      final parts = currentLanguage.split('-');
      if (parts.length >= 2) {
        final languageCode = parts[0];
        final hasLanguageCode = _availableLanguages.any((lang) => 
            _getLanguageCode(lang.toString()) == languageCode);
        if (hasLanguageCode) {
          return languageCode;
        }
      }
    }
    
    if (currentLanguage.length == 2) {
      final hasLanguageCode = _availableLanguages.any((lang) => 
          _getLanguageCode(lang.toString()) == currentLanguage);
      if (hasLanguageCode) {
        return currentLanguage;
      }
    }
    
    final languageCode = _getLanguageCode(currentLanguage);
    final hasLanguageCode = _availableLanguages.any((lang) => 
        _getLanguageCode(lang.toString()) == languageCode);
    
    if (hasLanguageCode) {
      return languageCode;
    }
    
    return _availableLanguages.isNotEmpty 
        ? _getLanguageCode(_availableLanguages.first.toString())
        : null;
  }

  String? _getSelectedVoice(String? currentVoice, String? currentVoiceLocale, String selectedLanguage) {
    if (currentVoice == null || currentVoice.isEmpty) {
      return null;
    }
    
    final currentItems = _getVoiceDropdownItems(selectedLanguage);
    
    if (currentVoiceLocale != null) {
      final expectedValue = '$currentVoice|$currentVoiceLocale';
      for (final item in currentItems) {
        if (item.value == expectedValue) {
          return expectedValue;
        }
      }
    }
    
    for (final item in currentItems) {
      if (item.value != null && item.value!.startsWith('$currentVoice|')) {
        return item.value;
      }
    }
    
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
    
    await TTSService.speak(testText, settings);
  }

  // Import/Export methods (copied from original settings screen)
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
        ],
      ),
    );
  }

  void _generateLLMPrompt() {
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
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate a prompt for an LLM to create ADHD-friendly routines:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _requestController,
              decoration: const InputDecoration(
                labelText: 'What kind of routine? (Optional)',
                hintText: 'e.g., "morning routine for time management"',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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