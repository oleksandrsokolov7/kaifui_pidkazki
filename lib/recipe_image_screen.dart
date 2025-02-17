import 'package:flutter/material.dart';

class RecipeImageScreen extends StatelessWidget {
  final String imagePath;
  final bool fullScreen;

  const RecipeImageScreen({
    required this.imagePath,
    required this.fullScreen,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: fullScreen
          ? null // Если экран на весь экран, убираем AppBar
          : AppBar(title: const Text('Рецепт')),
      body: Center(
        child: GestureDetector(
          onTap: () {
            if (fullScreen) {
              Navigator.pop(
                  context); // Возвращаемся, если это полноэкранный режим
            }
          },
          child: InteractiveViewer(
            child: Image.asset(imagePath),
          ),
        ),
      ),
    );
  }
}
