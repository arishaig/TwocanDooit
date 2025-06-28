import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/routine.dart';
import '../../services/audio_service.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
      context.read<RoutineProvider>().loadRoutines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dooit!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            Text(
              'ADHD Routine Helper',
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
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
                    'Error loading routines',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    routineProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      routineProvider.clearError();
                      routineProvider.loadRoutines();
                    },
                    child: const Text('Retry'),
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
                  Icon(
                    Icons.schedule,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No routines yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first routine to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _createNewRoutine(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Routine'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => routineProvider.loadRoutines(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88), // Extra bottom padding for FAB
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return RoutineCard(
                  routine: routine,
                  onTap: () => _startRoutine(context, routine),
                  onEdit: () => _editRoutine(context, routine),
                  onDelete: () => _deleteRoutine(context, routine),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewRoutine(context),
        icon: const Icon(Icons.add),
        label: const Text('New Routine'),
      ),
    );
  }

  void _createNewRoutine(BuildContext context) async {
    final settings = context.read<SettingsProvider>().settings;
    await AudioService.playButtonClick(settings);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RoutineEditorScreen(),
      ),
    );
  }

  void _editRoutine(BuildContext context, Routine routine) async {
    final settings = context.read<SettingsProvider>().settings;
    await AudioService.playButtonClick(settings);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoutineEditorScreen(routine: routine),
      ),
    );
  }

  void _startRoutine(BuildContext context, Routine routine) async {
    final settings = context.read<SettingsProvider>().settings;
    await AudioService.playButtonClick(settings);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExecutionScreen(routine: routine),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) async {
    final settings = context.read<SettingsProvider>().settings;
    await AudioService.playButtonClick(settings);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _deleteRoutine(BuildContext context, Routine routine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Routine'),
          content: Text('Are you sure you want to delete "${routine.name}"?'),
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