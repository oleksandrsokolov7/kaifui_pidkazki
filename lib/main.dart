import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle, DeviceOrientation, SystemChrome;
import 'package:kaifui_pidkazki/recipe_image_screen.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:translator/translator.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Голосовий пошук рецептів',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RecipeSearchScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  _RecipeSearchScreenState createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  final TextEditingController _controller = TextEditingController();
  List<String> _availableImages = [];
  bool _micPermissionGranted = false;
  List<String> _matches = [];
  final translator = GoogleTranslator();
  final bool _doubleTapExit = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadImageList();
    _requestMicPermission();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.request();
    setState(() {
      _micPermissionGranted = status.isGranted;
    });
  }

  Future<void> _loadImageList() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      setState(() {
        _availableImages = manifestMap.keys
            .where((String key) => key.startsWith('assets/images/'))
            .map((String key) => key.split('/').last)
            .toList();
      });
    } catch (e) {
      print('Помилка завантаження списку зображень: $e');
    }
  }

  String normalizeText(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+|-'), '');
  }

  void _startListening() async {
    if (!_micPermissionGranted) return;

    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) async {
        if (result.recognizedWords.isNotEmpty) {
          try {
            String translatedText =
                (await translator.translate(result.recognizedWords, to: 'uk'))
                    .text;
            setState(() {
              _recognizedText = translatedText;
              _controller.text = _recognizedText;
              _isListening = false;
            });
          } catch (e) {
            print("Ошибка перевода: $e");
          }
        }
      });
    }
  }

  void _searchRecipe() {
    String query = normalizeText(_controller.text.trim());
    if (query.isEmpty) return;

    _matches = _availableImages
        .where((image) => normalizeText(image).contains(query))
        .toList();

    if (_matches.length == 1) {
      _openRecipe(_matches.first, true);
    } else {
      setState(() {});
    }
  }

  void _openRecipe(String image, bool fullScreen) {
    if (fullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeImageScreen(
          imagePath: 'assets/images/$image',
          fullScreen: fullScreen,
        ),
      ),
    ).then((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      setState(() {
        _controller.clear();
        _matches.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Голосовий пошук рецептів')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Введіть назву рецепта',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startListening,
              child: Text(
                  _isListening ? '🎤 Слухаю...' : '🎤 Почати голосовий ввід'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _searchRecipe,
              child: const Text('🔍 Знайти рецепт'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_matches[index]),
                    onTap: () => _openRecipe(_matches[index], true),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class RecipeImageScreen extends StatelessWidget {
//   final String imagePath;
//   final bool fullScreen;

//   const RecipeImageScreen({
//     required this.imagePath,
//     required this.fullScreen,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: fullScreen
//           ? null // Если экран на весь экран, убираем AppBar
//           : AppBar(title: const Text('Рецепт')),
//       body: Center(
//         child: GestureDetector(
//           onTap: () {
//             if (fullScreen) {
//               Navigator.pop(
//                   context); // Возвращаемся, если это полноэкранный режим
//             }
//           },
//           child: InteractiveViewer(
//             child: Image.asset(imagePath),
//           ),
//         ),
//       ),
//     );
//   }
// }
