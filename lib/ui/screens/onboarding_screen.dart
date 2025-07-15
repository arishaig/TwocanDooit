import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/starter_routines_service.dart';
import '../../services/routine_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool canSkip;
  
  const OnboardingScreen({super.key, this.canSkip = true});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  
  // Temporary settings for onboarding
  bool _tempTtsEnabled = false;
  bool _tempNudgeEnabled = true;
  bool _tempAudioFeedback = true;
  bool _tempHapticFeedback = true;
  bool _tempDarkMode = true;
  
  // Starter routines selection
  List<StarterCategory> _availableCategories = [];
  List<StarterCategory> _additionalCategories = [];
  final Set<String> _selectedCategories = {};
  bool _loadingCategories = true;
  bool _showingAdditionalCategories = false;

  @override
  void initState() {
    super.initState();
    _loadStarterCategories();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    // Apply all the temporary settings
    await settingsProvider.updateSettings(
      settingsProvider.settings.copyWith(
        userName: _nameController.text.trim(),
        ttsEnabled: _tempTtsEnabled,
        nudgeEnabled: _tempNudgeEnabled,
        audioFeedbackEnabled: _tempAudioFeedback,
        hapticFeedbackEnabled: _tempHapticFeedback,
        isDarkMode: _tempDarkMode,
        hasCompletedOnboarding: true,
      ),
    );
    
    // Load selected starter routines
    if (_selectedCategories.isNotEmpty) {
      try {
        final starterRoutines = await StarterRoutinesService.instance
            .loadRoutinesForCategories(_selectedCategories.toList());
        if (starterRoutines.isNotEmpty) {
          // Save the starter routines to storage
          await RoutineService.saveStarterRoutines(starterRoutines);
        }
      } catch (e) {
        debugPrint('Error loading starter routines: $e');
        // Continue with onboarding even if starter routines fail to load
      }
    }
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _skipOnboarding() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.completeOnboarding();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _loadStarterCategories() async {
    try {
      final topLevelCategories = await StarterRoutinesService.instance.loadTopLevelCategories();
      final additionalCategories = await StarterRoutinesService.instance.loadAdditionalCategories();
      if (mounted) {
        setState(() {
          _availableCategories = topLevelCategories;
          _additionalCategories = additionalCategories;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading starter categories: $e');
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
      }
    }
  }

  void _toggleShowMore() {
    setState(() {
      _showingAdditionalCategories = !_showingAdditionalCategories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (widget.canSkip)
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: const Text('Skip'),
                    ),
                  const Spacer(),
                  Text(
                    '${_currentPage + 1} of 6',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            // Linear progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 6,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  // Dismiss keyboard when navigating to settings hierarchy page (index 3)
                  // but only when coming from the name page (index 2)
                  if (page == 3 && _currentPage == 2) {
                    FocusScope.of(context).unfocus();
                  }
                  
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildThemeSettingsPage(),
                  _buildNamePage(),
                  _buildSettingsHierarchyPage(),
                  _buildFeedbackSettingsPage(),
                  _buildAccessibilitySettingsPage(),
                  _buildStarterRoutinesPage(),
                ],
              ),
            ),
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _currentPage == 6 ? _completeOnboarding : _nextPage,
                      child: Text(_currentPage == 6 ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.waving_hand,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to TwocanDooit! 🐦',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Hi! I\'m Twocan, and together we can Dooit!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your ADHD-friendly routine companion. Let\'s set up the app to work perfectly for you.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Personalized settings for your needs'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('ADHD-friendly design and features'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Step-by-step routine guidance'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.person,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'What should we call you?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'We\'ll use your name to personalize your experience and make encouragement more meaningful. Providing your name is optional.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your name',
              hintText: 'Enter your first name or nickname',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _nextPage(),
          ),
          const SizedBox(height: 16),
          Text(
            'Don\'t worry, this stays private on your device.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHierarchyPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(
            Icons.settings,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'How Settings Work',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'I have smart settings that work at different levels:',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHierarchyItem(
                    Icons.public,
                    'Global Settings',
                    'Apply to everything (what we\'re setting up now)',
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),
                  _buildHierarchyItem(
                    Icons.list,
                    'Routine Settings',
                    'Override globals for specific routines',
                  ),
                  const SizedBox(height: 12),
                  _buildHierarchyItem(
                    Icons.looks_one,
                    'Step Settings',
                    'Override everything for individual steps',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Start with globals, then customize as needed!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchyItem(IconData icon, String title, String description, {bool isPrimary = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPrimary 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isPrimary 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.feedback,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Feedback & Notifications',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s choose how I can help keep you on track:',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.volume_up),
                    title: const Text('Audio Feedback'),
                    subtitle: const Text('Sounds for buttons and completions'),
                    value: _tempAudioFeedback,
                    onChanged: (value) {
                      setState(() {
                        _tempAudioFeedback = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.vibration),
                    title: const Text('Haptic Feedback'),
                    subtitle: const Text('Vibration for interactions'),
                    value: _tempHapticFeedback,
                    onChanged: (value) {
                      setState(() {
                        _tempHapticFeedback = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.notifications_active),
                    title: const Text('Nudge Notifications'),
                    subtitle: const Text('Gentle reminders when stuck'),
                    value: _tempNudgeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _tempNudgeEnabled = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.accessibility,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Accessibility Features',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Perfect for hands-free routines like workouts, cooking, or cleaning:',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.record_voice_over),
                    title: const Text('Text-to-Speech'),
                    subtitle: const Text('Read step instructions aloud when hands are busy'),
                    value: _tempTtsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _tempTtsEnabled = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'More TTS Options',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can fine-tune speech rate, pitch, voice, and language in Settings. You can also enable TTS for specific routines or individual steps only.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Perfect! You\'re all set up. Let\'s start building some routines!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.palette,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Choose Your Theme',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Pick the appearance that works best for you:',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  children: [
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.dark_mode, size: 20),
                          const SizedBox(width: 8),
                          const Text('Dark Mode'),
                        ],
                      ),
                      selected: _tempDarkMode == true,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _tempDarkMode = true;
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.light_mode, size: 20),
                          const SizedBox(width: 8),
                          const Text('Light Mode'),
                        ],
                      ),
                      selected: _tempDarkMode == false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _tempDarkMode = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Easier on the eyes, better for focus (Dark) vs Bright and energetic (Light)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can always change this later in Settings.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStarterRoutinesPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.auto_awesome,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Choose Your Starter Routines',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Select categories that interest you. We\'ll add sample routines to help you get started:',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _loadingCategories 
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          // Top-level categories
                          ..._availableCategories.map((category) => _buildCategoryCard(category)),
                          
                          // Show More button
                          if (_additionalCategories.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: OutlinedButton.icon(
                                onPressed: _toggleShowMore,
                                icon: Icon(_showingAdditionalCategories 
                                    ? Icons.expand_less 
                                    : Icons.expand_more),
                                label: Text(_showingAdditionalCategories 
                                    ? 'Show Less' 
                                    : 'Show More (${_additionalCategories.length} more)'),
                              ),
                            ),
                          
                          // Additional categories (when expanded)
                          if (_showingAdditionalCategories)
                            ..._additionalCategories.map((category) => _buildCategoryCard(category)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You can skip this and start with a blank canvas.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Selected: ${_selectedCategories.length} categories',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(StarterCategory category) {
    final isSelected = _selectedCategories.contains(category.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedCategories.add(category.id);
            } else {
              _selectedCategories.remove(category.id);
            }
          });
        },
        title: Row(
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(category.description),
            const SizedBox(height: 4),
            Text(
              'Includes: ${category.highlights.join(", ")}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}