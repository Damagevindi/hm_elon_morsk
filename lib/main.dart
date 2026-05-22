import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const ElonMorskApp());
}

class ElonMorskApp extends StatelessWidget {
  const ElonMorskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elon Morsk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MorseHomePage(),
    );
  }
}

class MorseHomePage extends StatefulWidget {
  const MorseHomePage({super.key});

  @override
  State<MorseHomePage> createState() => _MorseHomePageState();
}

class _MorseHomePageState extends State<MorseHomePage> {
  final TextEditingController _textController = TextEditingController();
  String _morseCode = '';
  bool _isPlaying = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // International Morse Code
  final Map<String, String> _morseMap = {
    'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.',
    'F': '..-.', 'G': '--.', 'H': '....', 'I': '..', 'J': '.---',
    'K': '-.-', 'L': '.-..', 'M': '--', 'N': '-.', 'O': '---',
    'P': '.--.', 'Q': '--.-', 'R': '.-.', 'S': '...', 'T': '-',
    'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-', 'Y': '-.--',
    'Z': '--..',
    '0': '-----', '1': '.----', '2': '..---', '3': '...--', '4': '....-',
    '5': '.....', '6': '-....', '7': '--...', '8': '---..', '9': '----.',
    ' ': ' ',
  };

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateMorse);
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateMorse() {
    final text = _textController.text.toUpperCase();
    final morse = text.split('').map((char) {
      return _morseMap[char] ?? '?';
    }).join(' ');
    setState(() {
      _morseCode = morse.trim();
    });
  }

  Future<void> _playMorse() async {
    if (_morseCode.isEmpty || _isPlaying) return;

    setState(() {
      _isPlaying = true;
    });

    final symbols = _morseCode.split(' ');

    for (final symbol in symbols) {
      if (!_isPlaying) break;

      if (symbol == ' ') {
        await Future.delayed(const Duration(milliseconds: 350));
        continue;
      }

      for (int i = 0; i < symbol.length; i++) {
        if (!_isPlaying) break;

        final isDash = symbol[i] == '-';
        final duration = isDash
            ? const Duration(milliseconds: 600)
            : const Duration(milliseconds: 200);

        // Visual feedback
        setState(() {});

        // TODO: Hier echten Ton abspielen (siehe unten)
        // await _playBeep(isDash);

        await Future.delayed(duration);

        // Pause between symbols
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Pause between letters
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      _isPlaying = false;
    });
  }

  // Platzhalter für echten Ton (mit audioplayers + kurzer WAV oder Asset)
  Future<void> _playBeep(bool isDash) async {
    // Beispiel: kurzer 800Hz Ton über Asset oder generierten WAV
    // Für schnellen Start nutzen wir erstmal nur Timing + Visual
    // Später: kurze MP3/WAV für Dot und Dash in assets/ hinzufügen
  }

  void _clearAll() {
    _textController.clear();
    setState(() {
      _morseCode = '';
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elon Morsk'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Text eingeben:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Hier Text schreiben...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearAll,
                ),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 30),
            const Text(
              'Morse-Code:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              constraints: const BoxConstraints(minHeight: 80),
              child: SelectableText(
                _morseCode.isEmpty ? 'Morse-Code erscheint hier...' : _morseCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isPlaying ? null : _playMorse,
              icon: _isPlaying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow, size: 28),
              label: Text(
                _isPlaying ? 'Wird abgespielt...' : 'Morse abspielen',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tip: Lange Töne = Bindestrich (-), kurze Töne = Punkt (.)',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}