import 'dart:io';
import 'lib/services/llm/model_asset_service.dart';

/// Test script to verify model chunk reassembly works correctly
void main() async {
  print('Testing model chunk reassembly...');
  
  final service = ModelAssetService.instance;
  
  // Test if chunks are available
  print('Checking if model is available...');
  final isAvailable = await service.isModelAvailable();
  print('Model available: $isAvailable');
  
  // Test getting model path (this triggers reassembly if needed)
  print('Getting model path...');
  final modelPath = await service.getModelPath();
  print('Model path: $modelPath');
  
  if (modelPath != null) {
    final file = File(modelPath);
    if (await file.exists()) {
      final size = await file.length();
      print('Reassembled model size: ${(size / 1024 / 1024).toStringAsFixed(1)} MB');
      print('✅ Model reassembly test PASSED');
    } else {
      print('❌ Model file not found after reassembly');
    }
  } else {
    print('❌ Could not get model path');
  }
}