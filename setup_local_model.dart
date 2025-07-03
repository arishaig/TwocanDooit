import 'dart:io';

/// Development helper to copy model chunks to device for testing
/// Run this script to copy your downloaded model chunks to the Android device
Future<void> main() async {
  print('=== Local Model Setup for Development ===');
  
  const sourceDir = '/home/isaac/Downloads/gemma-gemmacpp-2b-it-v3';
  const modelFileName = 'gemma-2b-it-gpu-int8.bin';
  
  // Check if source files exist
  final sourceModel = File('$sourceDir/$modelFileName');
  if (!await sourceModel.exists()) {
    print('❌ Source model not found at: ${sourceModel.path}');
    print('Make sure you have downloaded and renamed the model file.');
    return;
  }
  
  final sourceSize = await sourceModel.length();
  print('✅ Found source model: ${(sourceSize / 1024 / 1024).toStringAsFixed(1)} MB');
  
  // Get the device app data directory
  const targetDir = '/data/data/com.arishaig.twocandooit/cache/twocandooit_models';
  
  print('\n📱 To set up the model on your Android device:');
  print('1. Push the model file to device:');
  print('   adb push "$sourceDir/$modelFileName" "$targetDir/$modelFileName"');
  print('');
  print('2. Set proper permissions:');
  print('   adb shell "run-as com.arishaig.twocandooit chmod 644 /data/data/com.arishaig.twocandooit/cache/twocandooit_models/$modelFileName"');
  print('');
  print('3. Restart your Flutter app');
  print('');
  print('🔧 Run these commands in your terminal to set up the model for testing.');
}