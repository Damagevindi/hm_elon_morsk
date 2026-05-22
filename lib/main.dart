import 'package:flutter/material.dart';
import 'dart:js' as js;

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
  String _currentSymbol = '';

  // Reusable AudioContext (fixes the "stops after ~9 tones" bug)
  js.JsObject? _audioContext;

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
      _currentSymbol = '';
    });

    final symbols = _morseCode.split(' ');

    for (final symbol in symbols) {
      if (!_isPlaying) break;

      if (symbol == ' ') {
        setState(() => _currentSymbol = '⎵');
        await Future.delayed(const Duration(milliseconds: 350));
        continue;
      }

      for (int i = 0; i < symbol.length; i++) {
        if (!_isPlaying) break;

        final char = symbol[i];
        final isDash = char == '-';

        setState(() {
          _currentSymbol = char;
        });

        await _playSoftBeep(isDash);

        final duration = isDash ? 580 : 180;
        await Future.delayed(Duration(milliseconds: duration));
        await Future.delayed(const Duration(milliseconds: 120));
      }

      await Future.delayed(const Duration(milliseconds: 280));
    }

    setState(() {
      _isPlaying = false;
      _currentSymbol = '';
    });
  }

  /// Reusable soft Morse tone (one AudioContext for the whole session)
  Future<void> _playSoftBeep(bool isDash) async {
    try {
      // Create AudioContext only once
      _audioContext ??= js.JsObject(js.context['AudioContext'] as js.JsFunction);

      // Resume context if suspended (important on mobile browsers)
      final state = _audioContext!['state']?.toString();
      if (state == 'suspended') {
        await _audioContext!.callMethod('resume');
      }

      final oscillator = _audioContext!.callMethod('createOscillator');
      final gainNode = _audioContext!.callMethod('createGain');

      final frequency = 650.0;
      final durationSec = isDash ? 0.58 : 0.18;
      final now = _audioContext!['currentTime'] as num;

      oscillator['type'] = 'sine';
      oscillator['frequency']['value'] = frequency;

      // Soft attack + release envelope
      gainNode['gain']['value'] = 0.0;
      gainNode['gain'].callMethod('setValueAtTime', [0.0, now]);
      gainNode['gain'].callMethod('linearRampToValueAtTime', [0.75, now + 0.012]);
      gainNode['gain'].callMethod('linearRampToValueAtTime', [0.0, now + durationSec]);

      final destination = _audioContext!['destination'];
      oscillator.callMethod('connect', [gainNode]);
      gainNode.callMethod('connect', [destination]);

      oscillator.callMethod('start', [now]);
      oscillator.callMethod('stop', [now + durationSec + 0.06]);
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  void _clearAll() {
    _textController.clear();
    setState(() {
      _morseCode = '';
      _isPlaying = false;
      _currentSymbol = '';
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
            if (_currentSymbol.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Aktuell: $_currentSymbol',
                style: const TextStyle(fontSize: 16, color: Colors.deepPurple),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            const Text(
              'v0.2.1 – Fixed AudioContext reuse (unlimited tones)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}