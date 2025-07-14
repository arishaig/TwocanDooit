import 'dart:io';
import 'package:flutter/foundation.dart';

/// Development helper to copy model chunks to device for testing
/// Run this script to copy your downloaded model chunks to the Android device
Future<void> main() async {
  debugPrint('=== Local Model Setup for Development ===');
  
  const sourceDir = '/home/isaac/Downloads/gemma-gemmacpp-2b-it-v3';
  const modelFileName = 'gemma-2b-it-gpu-int8.bin';
  
  // Check if source files exist
  final sourceModel = File('$sourceDir/$modelFileName');
  if (!await sourceModel.exists()) {
    debugPrint('❌ Source model not found at: ${sourceModel.path}');
    debugPrint('Make sure you have downloaded and renamed the model file.');
    return;
  }
  
  final sourceSize = await sourceModel.length();
  debugPrint('✅ Found source model: ${(sourceSize / 1024 / 1024).toStringAsFixed(1)} MB');
  
  // Get the device app data directory
  const targetDir = '/data/data/com.arishaig.twocandooit/cache/twocandooit_models';
  
  debugPrint('\n📱 To set up the model on your Android device:');
  debugPrint('1. Push the model file to device:');
  debugPrint('   adb push "$sourceDir/$modelFileName" "$targetDir/$modelFileName"');
  debugPrint('');
  debugPrint('2. Set proper permissions:');
  debugPrint('   adb shell "run-as com.arishaig.twocandooit chmod 644 /data/data/com.arishaig.twocandooit/cache/twocandooit_models/$modelFileName"');
  debugPrint('');
  debugPrint('3. Restart your Flutter app');
  debugPrint('');
  debugPrint('🔧 Run these commands in your terminal to set up the model for testing.');
}