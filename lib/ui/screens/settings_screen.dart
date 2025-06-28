import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/tts_service.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<dynamic> _availableLanguages = [];
  bool _isLoadingLanguages = false;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    setState(() => _isLoadingLanguages = true);
    try {
      _availableLanguages = await TTSService.getLanguages();
    } catch (e) {
      print('Failed to load TTS languages: $e');
    } finally {
      setState(() => _isLoadingLanguages = false);
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
                            value: _availableLanguages.contains(settings.ttsLanguage) 
                                ? settings.ttsLanguage 
                                : _availableLanguages.isNotEmpty ? _availableLanguages.first : null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _availableLanguages.map<DropdownMenuItem<String>>((language) {
                              return DropdownMenuItem<String>(
                                value: language.toString(),
                                child: Text(language.toString()),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                settingsProvider.updateTTSLanguage(newValue);
                              }
                            },
                          ),
                        ] else if (_isLoadingLanguages) ...[
                          const Center(child: CircularProgressIndicator()),
                        ],
                        
                        const SizedBox(height: 20),
                        
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
                        'Dooit - ADHD Routine Helper',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'An executive function support app designed to help with routine management and step-by-step guidance.',
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

  void _testTTS(settings) async {
    print('Test TTS button pressed');
    print('TTS Enabled: ${settings.ttsEnabled}');
    print('TTS Rate: ${settings.ttsRate}');
    print('TTS Language: ${settings.ttsLanguage}');
    
    await TTSService.speak(
      'This is a test of the text to speech feature. Your current settings sound like this.',
      settings,
    );
    print('TTS speak call completed');
  }

}