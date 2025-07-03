import 'dart:io';
import 'package:asset_delivery/asset_delivery.dart';

/// Simple test script to check if model chunks are accessible
void main() async {
  print('=== Testing Model Asset Access ===');
  
  // Test 1: Check if chunks exist in the asset directory
  print('\n1. Checking asset chunks in android/gemma_model/...');
  final assetChunks = [
    'android/gemma_model/src/main/assets/models/gemma_chunk_1.bin',
    'android/gemma_model/src/main/assets/models/gemma_chunk_2.bin',
    'android/gemma_model/src/main/assets/models/gemma_chunk_3.bin',
    'android/gemma_model/src/main/assets/models/gemma_chunk_4.bin',
  ];
  
  for (final chunkPath in assetChunks) {
    final file = File(chunkPath);
    if (await file.exists()) {
      final size = await file.length();
      print('✓ Found: $chunkPath (${(size / 1024 / 1024).toStringAsFixed(1)} MB)');
    } else {
      print('✗ Missing: $chunkPath');
    }
  }
  
  // Test 2: Try to access via Asset Delivery API
  print('\n2. Testing Asset Delivery API...');
  try {
    final path = await AssetDelivery.getAssetPackPath(
      assetPackName: 'gemma_model',
      count: 4,
      namingPattern: 'gemma_chunk_{0}',
      fileExtension: 'bin',
    );
    
    if (path != null) {
      print('✓ Asset pack path: $path');
      
      // Check each chunk via Asset Delivery
      for (int i = 1; i <= 4; i++) {
        final chunkFile = File('$path/gemma_chunk_$i.bin');
        if (await chunkFile.exists()) {
          final size = await chunkFile.length();
          print('✓ Chunk $i: ${(size / 1024 / 1024).toStringAsFixed(1)} MB');
        } else {
          print('✗ Chunk $i: Not found at ${chunkFile.path}');
        }
      }
    } else {
      print('✗ Asset pack path is null - asset pack not available');
    }
  } catch (e) {
    print('✗ Asset Delivery error: $e');
  }
  
  print('\n=== Test Complete ===');
}