import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
// ignore: deprecated_member_use
import 'package:share_plus/share_plus.dart';
import '../models/routine.dart';
import '../models/step.dart';
import '../models/step_type.dart';

/// Service for importing and exporting routines as JSON files
/// Enables external LLM generation and routine sharing
class RoutineImportExportService {
  static const String _fileExtension = '.routine.json';
  static const String _exportFormatVersion = '1.0';
  
  static RoutineImportExportService? _instance;
  static RoutineImportExportService get instance => _instance ??= RoutineImportExportService._();
  RoutineImportExportService._();

  /// Export a single routine to JSON string
  String exportRoutineToJson(Routine routine) {
    final exportData = {
      'format': 'TwocanDooit-Routine',
      'version': _exportFormatVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'routine': routine.toJson(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Export multiple routines to JSON string
  String exportRoutinesToJson(List<Routine> routines) {
    final exportData = {
      'format': 'TwocanDooit-Routines',
      'version': _exportFormatVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'routines': routines.map((r) => r.toJson()).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Import a routine from JSON string
  /// Returns null if parsing fails
  Routine? importRoutineFromJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Check format
      if (data['format'] != 'TwocanDooit-Routine' && data['format'] != 'TwocanDooit-Routines') {
        throw FormatException('Invalid format: expected TwocanDooit-Routine, got ${data['format']}');
      }
      
      // Handle single routine format
      if (data['format'] == 'TwocanDooit-Routine') {
        final routineData = data['routine'] as Map<String, dynamic>;
        return _sanitizeAndCreateRoutine(routineData);
      }
      
      // Handle multiple routines format - return first routine
      if (data['format'] == 'TwocanDooit-Routines') {
        final routines = data['routines'] as List<dynamic>;
        if (routines.isEmpty) {
          throw FormatException('No routines found in file');
        }
        final routineData = routines.first as Map<String, dynamic>;
        return _sanitizeAndCreateRoutine(routineData);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error importing routine: $e');
      return null;
    }
  }

  /// Import multiple routines from JSON string
  List<Routine> importRoutinesFromJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Check format
      if (data['format'] != 'TwocanDooit-Routines' && data['format'] != 'TwocanDooit-Routine') {
        throw FormatException('Invalid format: expected TwocanDooit-Routines, got ${data['format']}');
      }
      
      final routines = <Routine>[];
      
      // Handle multiple routines format
      if (data['format'] == 'TwocanDooit-Routines') {
        final routinesList = data['routines'] as List<dynamic>;
        for (final routineData in routinesList) {
          final routine = _sanitizeAndCreateRoutine(routineData as Map<String, dynamic>);
          if (routine != null) {
            routines.add(routine);
          }
        }
      }
      
      // Handle single routine format
      if (data['format'] == 'TwocanDooit-Routine') {
        final routineData = data['routine'] as Map<String, dynamic>;
        final routine = _sanitizeAndCreateRoutine(routineData);
        if (routine != null) {
          routines.add(routine);
        }
      }
      
      return routines;
    } catch (e) {
      debugPrint('Error importing routines: $e');
      return [];
    }
  }

  /// Sanitize and create routine from JSON data
  /// Ensures data integrity and handles missing fields gracefully
  Routine? _sanitizeAndCreateRoutine(Map<String, dynamic> routineData) {
    try {
      // Generate new ID to avoid conflicts with existing routines
      final sanitizedData = Map<String, dynamic>.from(routineData);
      sanitizedData.remove('id'); // Let Routine generate new ID
      
      // Reset completion state for imported routines
      sanitizedData['updatedAt'] = DateTime.now().toIso8601String();
      
      // Sanitize steps
      if (sanitizedData['steps'] is List) {
        final steps = sanitizedData['steps'] as List<dynamic>;
        sanitizedData['steps'] = steps.map((stepData) {
          final sanitizedStep = Map<String, dynamic>.from(stepData as Map<String, dynamic>);
          sanitizedStep.remove('id'); // Let Step generate new ID
          sanitizedStep['isCompleted'] = false; // Reset completion
          sanitizedStep['repsCompleted'] = 0; // Reset progress
          sanitizedStep.remove('selectedChoice'); // Reset random selections
          sanitizedStep.remove('selectedVariable'); // Reset variable selections
          return sanitizedStep;
        }).toList();
      }
      
      return Routine.fromJson(sanitizedData);
    } catch (e) {
      debugPrint('Error creating routine from data: $e');
      return null;
    }
  }

  /// Save routine to device downloads folder and optionally show in file picker
  Future<String?> saveRoutineToFile(Routine routine, {bool showInFilePicker = true}) async {
    try {
      final jsonString = exportRoutineToJson(routine);
      final fileName = _sanitizeFileName('${routine.name}$_fileExtension');
      
      if (kIsWeb) {
        // Web platform - trigger download
        return _downloadFileWeb(jsonString, fileName);
      } else {
        // Mobile/Desktop - save to downloads
        if (showInFilePicker) {
          return _saveFileWithPicker(jsonString, fileName);
        } else {
          return _saveFileToDownloads(jsonString, fileName);
        }
      }
    } catch (e) {
      debugPrint('Error saving routine to file: $e');
      return null;
    }
  }

  /// Save multiple routines to device downloads folder and optionally show in file picker
  Future<String?> saveRoutinesToFile(List<Routine> routines, String fileName, {bool showInFilePicker = true}) async {
    try {
      final jsonString = exportRoutinesToJson(routines);
      final sanitizedFileName = _sanitizeFileName('$fileName$_fileExtension');
      
      if (kIsWeb) {
        // Web platform - trigger download
        return _downloadFileWeb(jsonString, sanitizedFileName);
      } else {
        // Mobile/Desktop - save to downloads
        if (showInFilePicker) {
          return _saveFileWithPicker(jsonString, sanitizedFileName);
        } else {
          return _saveFileToDownloads(jsonString, sanitizedFileName);
        }
      }
    } catch (e) {
      debugPrint('Error saving routines to file: $e');
      return null;
    }
  }

  /// Share a single routine using the device's native share menu
  /// Returns: true if shared successfully, false if error, null if cancelled
  Future<bool?> shareRoutine(Routine routine) async {
    try {
      final jsonString = exportRoutineToJson(routine);
      final fileName = _sanitizeFileName('${routine.name}$_fileExtension');
      
      if (kIsWeb) {
        // For web, share as text content
        // ignore: deprecated_member_use
        await Share.share(
          jsonString,
          subject: 'TwocanDooit Routine: ${routine.name}',
        );
        return true;
      } else {
        // For mobile/desktop, create a temporary file and share it
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonString);
        
        // ignore: deprecated_member_use
        final result = await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'TwocanDooit Routine: ${routine.name}',
          text: 'Check out this routine I created with TwocanDooit!',
        );
        
        // Handle different share result statuses
        switch (result.status) {
          case ShareResultStatus.success:
            return true;
          case ShareResultStatus.dismissed:
            return null; // User cancelled
          case ShareResultStatus.unavailable:
            return null; // User cancelled or no app available
        }
      }
    } catch (e) {
      debugPrint('Error sharing routine: $e');
      return false;
    }
  }

  /// Share multiple routines using the device's native share menu
  /// Returns: true if shared successfully, false if error, null if cancelled
  Future<bool?> shareRoutines(List<Routine> routines, String fileName) async {
    try {
      final jsonString = exportRoutinesToJson(routines);
      final sanitizedFileName = _sanitizeFileName('$fileName$_fileExtension');
      
      if (kIsWeb) {
        // For web, share as text content
        // ignore: deprecated_member_use
        await Share.share(
          jsonString,
          subject: 'TwocanDooit Routines Collection: $fileName',
        );
        return true;
      } else {
        // For mobile/desktop, create a temporary file and share it
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$sanitizedFileName');
        await file.writeAsString(jsonString);
        
        // ignore: deprecated_member_use
        final result = await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'TwocanDooit Routines Collection: $fileName',
          text: 'Check out these ${routines.length} routines I created with TwocanDooit!',
        );
        
        // Handle different share result statuses
        switch (result.status) {
          case ShareResultStatus.success:
            return true;
          case ShareResultStatus.dismissed:
            return null; // User cancelled
          case ShareResultStatus.unavailable:
            return null; // User cancelled or no app available
        }
      }
    } catch (e) {
      debugPrint('Error sharing routines: $e');
      return false;
    }
  }

  /// Pick and import routine from file
  Future<Routine?> pickAndImportRoutine() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Import Routine',
      );

      if (result?.files.single.path != null) {
        final file = File(result!.files.single.path!);
        final jsonString = await file.readAsString();
        return importRoutineFromJson(jsonString);
      } else if (result?.files.single.bytes != null) {
        // Web platform
        final bytes = result!.files.single.bytes!;
        final jsonString = utf8.decode(bytes);
        return importRoutineFromJson(jsonString);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error picking and importing routine: $e');
      return null;
    }
  }

  /// Pick and import multiple routines from file
  Future<List<Routine>> pickAndImportRoutines() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Import Routines',
      );

      if (result?.files.single.path != null) {
        final file = File(result!.files.single.path!);
        final jsonString = await file.readAsString();
        return importRoutinesFromJson(jsonString);
      } else if (result?.files.single.bytes != null) {
        // Web platform
        final bytes = result!.files.single.bytes!;
        final jsonString = utf8.decode(bytes);
        return importRoutinesFromJson(jsonString);
      }
      
      return [];
    } catch (e) {
      debugPrint('Error picking and importing routines: $e');
      return [];
    }
  }

  /// Import routine from clipboard
  Future<Routine?> importRoutineFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
        return null;
      }
      
      return importRoutineFromJson(clipboardData.text!);
    } catch (e) {
      debugPrint('Error importing routine from clipboard: $e');
      return null;
    }
  }

  /// Import multiple routines from clipboard
  Future<List<Routine>> importRoutinesFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
        return [];
      }
      
      return importRoutinesFromJson(clipboardData.text!);
    } catch (e) {
      debugPrint('Error importing routines from clipboard: $e');
      return [];
    }
  }

  /// Create a sample routine export for LLM reference
  String createSampleExport() {
    final sampleRoutine = Routine(
      name: 'Morning Routine',
      description: 'A productive start to the day',
      category: 'Daily',
      steps: [
        Step(
          title: 'Drink water',
          description: 'Hydrate after sleep',
          type: StepType.basic,
          voiceEnabled: true,
        ),
        Step(
          title: 'Exercise',
          description: 'Get the blood flowing',
          type: StepType.timer,
          timerDuration: 300, // 5 minutes
          voiceEnabled: true,
        ),
        Step(
          title: 'Choose breakfast',
          description: 'Pick a healthy option',
          type: StepType.randomChoice,
          choices: ['Oatmeal', 'Yogurt', 'Fruit', 'Toast'],
          voiceEnabled: true,
        ),
      ],
      voiceEnabled: true,
      musicEnabled: false,
    );
    
    return exportRoutineToJson(sampleRoutine);
  }

  /// Generate a comprehensive LLM prompt for routine creation
  String generateLLMPrompt({String? userRequest}) {
    final userContext = userRequest != null ? '''

## User Request
$userRequest

Please create a routine that addresses this specific request.
''' : '';

    return '''
# TwocanDooit Routine Generator

You are an AI assistant helping to create ADHD-friendly routines for the TwocanDooit app. This app is specifically designed to support executive function and help users with ADHD manage their daily tasks through structured, step-by-step routines.

## About TwocanDooit

TwocanDooit is an executive function support app that helps people with ADHD break down complex tasks into manageable, sequential steps. The app features:

- **Step-by-step guidance**: Each routine consists of individual steps that guide users through tasks
- **Multiple step types**: Basic instructions, timers, rep counting, random choices, and variable parameters
- **Voice announcements**: Text-to-speech support for hands-free operation
- **Progress tracking**: Visual feedback and completion tracking
- **Flexible execution**: Support for randomization and personalization

## Target Users

- Adults and teens with ADHD
- People with executive function challenges
- Anyone who benefits from structured, step-by-step task guidance
- Users who need external motivation and prompting

## Design Principles

1. **Break it down**: Complex tasks should be divided into small, actionable steps
2. **Be specific**: Each step should have clear, unambiguous instructions
3. **Add structure**: Use timers and rep counts to provide external structure
4. **Include variety**: Use random choices to prevent boredom and maintain engagement
5. **Consider energy levels**: Order steps logically, considering mental/physical energy requirements
6. **Build habits**: Create consistent patterns that can become automatic over time

## Step Types Available

### 1. Basic Step
Simple instruction or task
- **Text limits**: Title ~30 chars, description ~150 chars for optimal display
- Use for: Reading, checking items, simple actions
- Example: "Put on your shoes"

### 2. Timer Step  
Timed activity with countdown
- **Text limits**: Title ~25 chars, description ~100 chars (timer display takes space)
- Use for: Focus work, breaks, timed activities
- Duration: Specify in seconds (60 = 1 minute)
- Example: "Work on project" (timerDuration: 1500)

### 3. Reps Step
Countable repetitions
- **Text limits**: Title ~20 chars, description ~80 chars (rep counter takes significant space)
- **Important**: Keep text concise - rep steps have the most constrained display space
- Use for: Exercise, repeated actions, countable tasks
- Can be manual completion or auto-timed per rep
- Example: "Push-ups" (repsTarget: 10)

### 4. Random Choice Step
Randomly select from options (with optional weights)
- **Text limits**: Title ~25 chars, description ~120 chars, choice names ~15 chars each
- Use for: Decision-making, variety, reducing choice paralysis
- Weights: Higher numbers = more likely to be chosen
- Example: Choose workout from ["Cardio", "Strength", "Yoga"]

### 5. Variable Parameter Step
User selects from predefined options
- **Text limits**: Title ~25 chars, description ~120 chars, option names ~15 chars each
- Use for: Customization, user preferences, context-dependent choices
- Example: Set temperature from ["Cool", "Warm", "Hot"]

## Common ADHD-Friendly Routine Patterns

### Morning Routines
- Start with low-energy tasks (drinking water)
- Build momentum with quick wins
- Include timer steps for time-awareness
- Add random choices for variety

### Work/Study Sessions  
- Use timer steps for Pomodoro technique
- Break large tasks into 15-25 minute chunks
- Include movement breaks
- Add variety through random choice steps

### Evening Routines
- Wind-down activities with timers
- Preparation for next day
- Calming, low-energy tasks
- Consistent structure for better sleep

### Exercise Routines
- Warm-up, main activity, cool-down structure
- Use rep steps for counting
- Random choices for exercise variety
- Timers for rest periods

## JSON Export Format

Your response should be valid JSON in this exact format:

```json
{
  "format": "TwocanDooit-Routine",
  "version": "1.0", 
  "exported_at": "${DateTime.now().toIso8601String()}",
  "routine": {
    "name": "Routine Name (clear, descriptive)",
    "description": "Brief description of purpose and benefits",
    "category": "Category (e.g., Morning, Work, Exercise, Evening, Health, Productivity)",
    "voiceEnabled": true,
    "musicEnabled": false,
    "musicTrack": null,
    "isBuiltInTrack": true,
    "steps": [
      {
        "title": "Step title (action-oriented, clear)",
        "description": "Detailed instructions or helpful context",
        "type": "basic|timer|reps|randomChoice|variableParameter",
        "voiceEnabled": true,
        "timerDuration": 60,
        "repsTarget": 1,
        "repsCompleted": 0,
        "repDurationSeconds": null,
        "randomizeReps": false,
        "repsMin": 1,
        "repsMax": 10,
        "choices": [],
        "choiceWeights": null,
        "selectedChoice": null,
        "variableName": "",
        "variableOptions": [],
        "selectedVariable": null,
        "isCompleted": false
      }
    ]
  }
}
```

## Step Configuration Examples

### Basic Step
```json
{
  "title": "Drink water",
  "description": "Hydration helps with focus",
  "type": "basic",
  "voiceEnabled": true,
  "isCompleted": false
}
```

### Timer Step (25-minute work session)
```json
{
  "title": "Focus work",
  "description": "Work on top priority task",
  "type": "timer", 
  "timerDuration": 1500,
  "voiceEnabled": true,
  "isCompleted": false
}
```

### Reps Step (Push-ups)
```json
{
  "title": "Push-ups",
  "description": "Keep core tight",
  "type": "reps",
  "repsTarget": 10,
  "voiceEnabled": true,
  "isCompleted": false
}
```

### Random Choice (Breakfast options)
```json
{
  "title": "Choose breakfast",
  "description": "Pick healthy option",
  "type": "randomChoice",
  "choices": ["Oatmeal", "Yogurt", "Smoothie", "Eggs"],
  "choiceWeights": [1.0, 1.5, 1.0, 2.0],
  "voiceEnabled": true,
  "isCompleted": false
}
```

### Variable Parameter (Music volume)
```json
{
  "title": "Set music volume",
  "description": "Choose volume level",
  "type": "variableParameter", 
  "variableName": "volume",
  "variableOptions": ["Off", "Low", "Medium", "High"],
  "voiceEnabled": true,
  "isCompleted": false
}
```

## Important Guidelines

**Note**: Only include fields that are relevant to each step type. The examples above show the minimum required fields - additional fields will be ignored or use sensible defaults.

### Text Length Best Practices
- **Mobile-first design**: The app is designed for mobile screens with limited space
- **Reps steps need shortest text**: Rep counting UI takes significant screen space
- **Prioritize clarity over completeness**: Better to be concise and clear than comprehensive but cluttered
- **Test your text**: Consider how it would look on a phone screen during execution

### Content Guidelines
1. **Keep steps actionable**: Each step should be a concrete action, not just information
2. **Use encouraging language**: Frame instructions positively and supportively  
3. **Be concise**: Respect the text limits for each step type - users see this on mobile screens
4. **Consider executive function**: Break complex decisions into simpler choices
5. **Add helpful context**: Include "why" information in descriptions when helpful, but keep it brief
6. **Logical flow**: Order steps in a way that makes sense practically and energetically
7. **Appropriate timing**: Timer durations should be realistic for the task and user energy
8. **Variety without overwhelm**: Use random choices strategically, not excessively
9. **Voice-friendly**: Write titles and descriptions that sound natural when spoken aloud
10. **Mobile-optimized**: Remember users will see this on phone screens during task execution

## Categories to Consider

- **Morning**: Wake-up routines, breakfast prep, getting ready
- **Work**: Productivity, focus sessions, meetings
- **Exercise**: Workouts, stretching, movement breaks  
- **Evening**: Wind-down, preparation for tomorrow
- **Health**: Medication, self-care, medical appointments
- **Productivity**: Task management, organization, planning
- **Social**: Relationship maintenance, social activities
- **Creative**: Art, writing, music, creative projects
- **Household**: Cleaning, maintenance, organization
- **Learning**: Study sessions, skill development$userContext

Please create a routine that follows these guidelines and would be genuinely helpful for someone with ADHD. Focus on practical value, clear structure, and supportive guidance.
''';
  }

  /// Get format documentation for external LLM generation
  String getFormatDocumentation() {
    return '''
# TwocanDooit Routine Format Documentation

## File Format
- Extension: .routine.json
- Content-Type: application/json
- Encoding: UTF-8

## Structure
```json
{
  "format": "TwocanDooit-Routine",
  "version": "1.0",
  "exported_at": "2024-01-01T12:00:00.000Z",
  "routine": {
    "name": "Routine Name",
    "description": "Optional description",
    "category": "Category name",
    "voiceEnabled": true,
    "musicEnabled": false,
    "musicTrack": null,
    "isBuiltInTrack": true,
    "steps": [
      {
        "title": "Step title",
        "description": "Step description",
        "type": "basic|timer|reps|randomChoice|variableParameter",
        "voiceEnabled": true,
        // Type-specific properties below
      }
    ]
  }
}
```

## Step Types

### Basic Step
```json
{
  "type": "basic",
  "title": "Do something",
  "description": "Simple instruction"
}
```

### Timer Step  
```json
{
  "type": "timer",
  "title": "Meditate",
  "timerDuration": 300
}
```

### Reps Step
```json
{
  "type": "reps",
  "title": "Push-ups",
  "repsTarget": 10,
  "repDurationSeconds": null,
  "randomizeReps": false,
  "repsMin": 5,
  "repsMax": 15
}
```

### Random Choice Step
```json
{
  "type": "randomChoice", 
  "title": "Choose activity",
  "choices": ["Option A", "Option B", "Option C"],
  "choiceWeights": [1.0, 2.0, 1.0]
}
```

### Variable Parameter Step
```json
{
  "type": "variableParameter",
  "title": "Set temperature",
  "variableName": "temperature",
  "variableOptions": ["Hot", "Warm", "Cool"]
}
```
''';
  }

  /// Sanitize filename for cross-platform compatibility
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  /// Save file using system file picker
  Future<String?> _saveFileWithPicker(String content, String fileName) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Routine Export',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(content);
        return result;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error saving with file picker: $e');
      // Fallback to downloads folder
      return _saveFileToDownloads(content, fileName);
    }
  }

  /// Save file to downloads folder (mobile/desktop)
  Future<String?> _saveFileToDownloads(String content, String fileName) async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        // Fallback to documents directory
        final docDir = await getApplicationDocumentsDirectory();
        final file = File('${docDir.path}/$fileName');
        await file.writeAsString(content);
        return file.path;
      }
      
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      debugPrint('Error saving to downloads: $e');
      return null;
    }
  }

  /// Trigger download on web platform
  String? _downloadFileWeb(String content, String fileName) {
    // For web, we'll return the content and let the UI handle the download
    // This would need platform-specific implementation
    debugPrint('Web download not implemented - would download: $fileName');
    return content;
  }
}