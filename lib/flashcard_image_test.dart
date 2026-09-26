import 'package:flutter/material.dart';

class FlashcardImageTestScreen extends StatelessWidget {
  const FlashcardImageTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const images = <String>[
      // Big Animate
      'assets/flashcards/images/animacy_size/big_animate/elephant1.jpg',
      'assets/flashcards/images/animacy_size/big_animate/horse.jpg',
      'assets/flashcards/images/animacy_size/big_animate/camel.jpg',

      // Big Inanimate
      'assets/flashcards/images/animacy_size/big_inanimate/chair.jpg',
      'assets/flashcards/images/animacy_size/big_inanimate/bookcase.jpg',

      // Small Animate
      'assets/flashcards/images/animacy_size/small_animate/bat.jpg',
      'assets/flashcards/images/animacy_size/small_animate/bunny.jpg',
      'assets/flashcards/images/animacy_size/small_animate/cat.jpg',

      // Small Inanimate
      'assets/flashcards/images/animacy_size/small_inanimate/lightbulb.jpg',
      'assets/flashcards/images/animacy_size/small_inanimate/sponge.jpg',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Image Test'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final imagePath = images[index];

          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    fit: BoxFit.contain,

                    // Shows the exact error if the image cannot load.
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                        'IMAGE ERROR: $imagePath',
                      );
                      debugPrint(
                        'ERROR: $error',
                      );

                      return Container(
                        width: double.infinity,
                        color: Colors.red.shade100,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Image failed',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    imagePath.split('/').last,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}