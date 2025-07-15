import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AttributionScreen extends StatelessWidget {
  const AttributionScreen({super.key});

  static const List<Attribution> _attributions = [
    Attribution(
      title: 'Roll Dice Sounds',
      author: 'Bw2801',
      url: 'https://freesound.org/people/bw2801/',
      fileUrls: [
        'https://freesound.org/s/647921/',
        'https://freesound.org/s/647922/',
        'https://freesound.org/s/647923/',
        'https://freesound.org/s/647924/',
      ],
      license: 'Creative Commons Attribution 4.0',
      licenseUrl: 'https://creativecommons.org/licenses/by/4.0/',
      description: 'Dice roll sound effects used in random choice steps',
    ),
    Attribution(
      title: 'EDM Myst Soundscape Cinematic',
      author: 'szegvari',
      url: 'https://freesound.org/people/szegvari/',
      fileUrls: ['https://freesound.org/s/593786/'],
      license: 'Creative Commons Zero (CC0)',
      licenseUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
      description: 'Focus background music for concentration',
    ),
    Attribution(
      title: 'Button Click Sound',
      author: 'Mellau',
      url: 'https://freesound.org/people/Mellau/',
      fileUrls: ['https://freesound.org/s/506054/'],
      license: 'Creative Commons Attribution NonCommercial 4.0',
      licenseUrl: 'https://creativecommons.org/licenses/by-nc/4.0/',
      description: 'UI button interaction sound',
      isNonCommercial: false, // Legal for our non-commercial app
    ),
    Attribution(
      title: 'Binaural Beats Alpha to Delta',
      author: 'WIM',
      url: 'https://freesound.org/people/WIM/',
      fileUrls: ['https://freesound.org/s/676878/'],
      license: 'Creative Commons Attribution NonCommercial 4.0',
      licenseUrl: 'https://creativecommons.org/licenses/by-nc/4.0/',
      description: 'Binaural beats background music for focus',
      isNonCommercial: false, // Legal for our non-commercial app
    ),
    Attribution(
      title: 'Meditation',
      author: 'SergeQuadrado',
      url: 'https://freesound.org/people/SergeQuadrado/',
      fileUrls: ['https://freesound.org/s/655395/'],
      license: 'Creative Commons Attribution NonCommercial 4.0',
      licenseUrl: 'https://creativecommons.org/licenses/by-nc/4.0/',
      description: 'Calm meditation background music',
      isNonCommercial: false, // Legal for our non-commercial app
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attributions & Licenses'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Open Source Notice
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.code,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Open Source & Non-Commercial',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TwocanDooit is a free, open-source app with no ads, purchases, or monetization. All audio content is used in compliance with Creative Commons licenses.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Introduction
            Text(
              'Audio & Music Credits',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TwocanDooit uses audio content from talented creators. We are grateful for their contributions to the open-source and creative commons community.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            
            // Attribution cards
            ..._attributions.map((attribution) => _buildAttributionCard(context, attribution)),
            
            const SizedBox(height: 32),
            
            // Legal note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legal Compliance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All audio content is used in accordance with their respective Creative Commons licenses. '
                    'For any questions about usage rights, please contact the original creators through the links provided above.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributionCard(BuildContext context, Attribution attribution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    attribution.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'By ${attribution.author}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              attribution.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            
            // License
            InkWell(
              onTap: () => _launchUrl(attribution.licenseUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  attribution.license,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Links
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _launchUrl(attribution.url),
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text('Creator'),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                ...attribution.fileUrls.map((url) => TextButton.icon(
                  onPressed: () => _launchUrl(url),
                  icon: const Icon(Icons.audio_file, size: 16),
                  label: const Text('Source'),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class Attribution {
  final String title;
  final String author;
  final String url;
  final List<String> fileUrls;
  final String license;
  final String licenseUrl;
  final String description;
  final bool isNonCommercial;

  const Attribution({
    required this.title,
    required this.author,
    required this.url,
    required this.fileUrls,
    required this.license,
    required this.licenseUrl,
    required this.description,
    this.isNonCommercial = false,
  });
}