import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/routine.dart';
import '../../services/audio_service.dart';
import '../../services/routine_import_export_service.dart';
import '../../services/storage_service.dart';
import '../widgets/routine_card.dart';
import 'routine_editor_screen.dart';
import 'execution_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtTop = true;
  bool _isUpdating = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
      context.read<RoutineProvider>().loadRoutines();
    });
    
    // Listen to scroll changes
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_scrollController.hasClients && !_isUpdating) {
      final currentScroll = _scrollController.position.pixels;
      final isAtTop = currentScroll <= 50; // 50px threshold from top
      
      if (_isAtTop != isAtTop) {
        _isUpdating = true;
        // Use post-frame callback to avoid setState during layout
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isAtTop = isAtTop;
            });
            _isUpdating = false;
          }
        });
      }
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        title: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            final userName = settingsProvider.settings.userName;
            final displayName = userName.isNotEmpty ? userName : 'Friend';
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hi $displayName, I\'m Twocan,',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                Text(
                  'and together we can Dooit!',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            );
          },
        ),
        centerTitle: true,
        toolbarHeight: 80,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 32),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: Consumer<RoutineProvider>(
        builder: (context, routineProvider, child) {
          if (routineProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (routineProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Oops! Something got mixed up',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'I had trouble loading our routines, but don\'t worry - let\'s try again together!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      routineProvider.clearError();
                      routineProvider.loadRoutines();
                    },
                    child: const Text('Let\'s Try Again'),
                  ),
                ],
              ),
            );
          }

          final routines = routineProvider.routines;

          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/twocan/twocan_happy.png',
                        width: 80,
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to emoji if image fails to load
                          return Text(
                            '🐦',
                            style: TextStyle(fontSize: 64),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ready for our first routine?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Let\'s create something together!\nI\'ll help you break it down step by step.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _createNewRoutine(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Let\'s Create One!'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => routineProvider.loadRoutines(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 88), // Extra bottom padding for FAB
                  itemCount: routines.length,
                  itemBuilder: (context, index) {
                    final routine = routines[index];
                    return RoutineCard(
                      routine: routine,
                      onTap: () => _startRoutine(context, routine),
                      onEdit: () => _editRoutine(context, routine),
                      onExport: () => _shareRoutine(context, routine),
                      onClearRunData: () => _clearRunData(context, routine),
                      onDelete: () => _deleteRoutine(context, routine),
                    );
                  },
                ),
              ),
              // Animated Twocan thumbs up
              AnimatedPositioned(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutBack,
                bottom: _isAtTop ? 20 : null,
                top: _isAtTop ? null : 20,
                left: 20,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/twocan/twocan_thumbs_up.png',
                      width: 160,
                      height: 160,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.thumb_up,
                          size: 160,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewRoutine(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Together'),
      ),
    );
  }

  void _createNewRoutine(BuildContext context) async {
    final settings = context.read<SettingsProvider>().settings;
    await AudioService.playButtonClick(settings);
    
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const RoutineEditorScreen(),
        ),
      );
    }
  }

  void _editRoutine(BuildContext context, Routine routine) async {
    final settings = context.read<SettingsProvider>().settings;
    await AudioService.playButtonClick(settings);
    
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RoutineEditorScreen(routine: routine),
        ),
      );
    }
  }

  void _startRoutine(BuildContext context, Routine routine) async {
    final settings = context.read<SettingsProvider>().settings;
    await AudioService.playButtonClick(settings);
    
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ExecutionScreen(routine: routine),
        ),
      );
    }
  }

  void _navigateToSettings(BuildContext context) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _shareRoutine(BuildContext context, Routine routine) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    
    try {
      final exportService = RoutineImportExportService.instance;
      final result = await exportService.shareRoutine(routine);
      
      if (result == true && mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Routine "${routine.name}" shared successfully!'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result == false && mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Failed to share routine. Please try again.'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // result == null means user cancelled, so we don't show any message
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error sharing routine: ${e.toString()}'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearRunData(BuildContext context, Routine routine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Run Data'),
          content: Text('Clear all run history for "${routine.name}"?\n\nThis will remove all tracking data including run times, completion stats, and last run information. The routine itself will remain unchanged.\n\nThis action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!mounted) return;
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final theme = Theme.of(context);
                
                navigator.pop();
                
                final success = await StorageService.clearRoutineRunData(routine.id);
                
                if (mounted) {
                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Run data cleared for "${routine.name}"'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: const Text('Failed to clear run data. Please try again.'),
                        backgroundColor: theme.colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Clear Data'),
            ),
          ],
        );
      },
    );
  }

  void _deleteRoutine(BuildContext context, Routine routine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Routine'),
          content: Text('Should we remove "${routine.name}" from our list?\n\nNo worries if you change your mind - we can always make it again later!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<RoutineProvider>().deleteRoutine(routine.id);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}


