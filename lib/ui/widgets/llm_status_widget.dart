// import 'package:flutter/material.dart';
// import '../../services/llm/local_llm_service.dart';

/*

/// Widget that shows Local AI availability
class LLMStatusWidget extends StatefulWidget {
  const LLMStatusWidget({super.key});

  @override
  State<LLMStatusWidget> createState() => _LLMStatusWidgetState();
}

class _LLMStatusWidgetState extends State<LLMStatusWidget> {
  bool? _isAvailable;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    setState(() => _isLoading = true);
    
    try {
      final aiService = LocalLLMService.instance;
      setState(() {
        _isAvailable = aiService.isAvailable;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Checking AI availability...'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isAvailable == true ? Icons.smart_toy : Icons.smart_toy_outlined,
                  color: _isAvailable == true 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Local AI (Gemma)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_isAvailable == true 
                ? 'AI features powered by local Gemma model are available for enhanced routine suggestions and ADHD-focused assistance. All processing happens on your device for complete privacy.'
                : _isAvailable == false 
                    ? 'Local AI features are currently unavailable. Core app functionality works normally.'
                    : 'Unable to check local AI availability'),
            const SizedBox(height: 12),
            if (_isAvailable == true) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'On-Device',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Fallback Mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            const ModelDownloadWidget(),
          ],
        ),
      ),
    );
  }

}

/// Simple demo widget showing Firebase AI functionality
class LLMDemoWidget extends StatefulWidget {
  const LLMDemoWidget({super.key});

  @override
  State<LLMDemoWidget> createState() => _LLMDemoWidgetState();
}

class _LLMDemoWidgetState extends State<LLMDemoWidget> {
  final _controller = TextEditingController();
  String? _response;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final aiService = LocalLLMService.instance;
    
    if (!aiService.isAvailable) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('AI features not available. Local AI model is not initialized.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Try AI Assistant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Ask about routines or ADHD tips...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _generateResponse,
                child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ask AI'),
              ),
            ),
            if (_response != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_response!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateResponse() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = null;
    });

    try {
      final response = await LocalLLMService.instance.generateADHDFocusedText(_controller.text);
      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Widget for downloading the Gemma model
class ModelDownloadWidget extends StatefulWidget {
  const ModelDownloadWidget({super.key});

  @override
  State<ModelDownloadWidget> createState() => _ModelDownloadWidgetState();
}

class _ModelDownloadWidgetState extends State<ModelDownloadWidget> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final llmService = LocalLLMService.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.download,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Gemma 2B Model',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (llmService.hasModel) ...[
          // Model already downloaded
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              const Text('Model downloaded and ready'),
            ],
          ),
        ] else if (_isDownloading) ...[
          // Download in progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: _downloadProgress / 100,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Downloading... ${_downloadProgress.toStringAsFixed(1)}%'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _downloadProgress / 100,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ],
          ),
        ] else ...[
          // Download instructions
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Download Gemma 2B (~2GB) for true local AI inference',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Model Download Info',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gemma models require Kaggle authentication. Visit kaggle.com/models/google/gemma to download gemma-2b-it-gpu-int8.bin',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _downloadModel,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Try Download'),
                ),
              ),
            ],
          ),
        ],
        
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _downloadModel() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      // Listen to download progress
      await for (final progress in LocalLLMService.instance.downloadModel()) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Download failed: ${e.toString()}';
        });
      }
    }
  }
}
*/