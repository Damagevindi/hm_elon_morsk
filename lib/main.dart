import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'dart:typed_data';

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

class _MorseHomePageState extends State<MorseHomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  String _morseCode = '';
  bool _isPlaying = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _waveController;

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
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    _waveController.dispose();
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

  /// Generates a simple sine wave tone as WAV bytes
  Uint8List _generateTone(int frequency, int durationMs, {double volume = 0.8}) {
    final int sampleRate = 44100;
    final int numSamples = (sampleRate * durationMs / 1000).round();
    final int numChannels = 1;
    final int bitsPerSample = 16;

    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = numSamples * blockAlign;

    final bytes = BytesBuilder();

    // WAV Header
    bytes.add('RIFF'.codeUnits);
    bytes.add(_intToBytes(36 + dataSize, 4));
    bytes.add('WAVE'.codeUnits);
    bytes.add('fmt '.codeUnits);
    bytes.add(_intToBytes(16, 4));
    bytes.add(_intToBytes(1, 2)); // PCM
    bytes.add(_intToBytes(numChannels, 2));
    bytes.add(_intToBytes(sampleRate, 4));
    bytes.add(_intToBytes(byteRate, 4));
    bytes.add(_intToBytes(blockAlign, 2));
    bytes.add(_intToBytes(bitsPerSample, 2));
    bytes.add('data'.codeUnits);
    bytes.add(_intToBytes(dataSize, 4));

    // Generate sine wave samples
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double value = sin(2 * pi * frequency * t) * volume;
      final int sample = (value * 32767).round().clamp(-32768, 32767);
      bytes.add(_intToBytes(sample, 2, signed: true));
    }

    return bytes.toBytes();
  }

  List<int> _intToBytes(int value, int byteCount, {bool signed = false}) {
    final bytes = <int>[];
    for (int i = 0; i < byteCount; i++) {
      if (signed) {
        bytes.add((value >> (8 * i)) & 0xFF);
      } else {
        bytes.add((value >> (8 * i)) & 0xFF);
      }
    }
    return bytes;
  }

  Future<void> _playBeep(bool isDash) async {
    final frequency = isDash ? 650 : 850; // Dash = lower, Dot = higher
    final duration = isDash ? 600 : 180;

    final wavBytes = _generateTone(frequency, duration);

    await _audioPlayer.play(BytesSource(wavBytes));
    await Future.delayed(Duration(milliseconds: duration + 80));
  }

  Future<void> _playMorse() async {
    if (_morseCode.isEmpty || _isPlaying) return;

    setState(() {
      _isPlaying = true;
    });
    _waveController.repeat();

    final symbols = _morseCode.split(' ');

    for (final symbol in symbols) {
      if (!_isPlaying) break;

      if (symbol == ' ') {
        await Future.delayed(const Duration(milliseconds: 400));
        continue;
      }

      for (int i = 0; i < symbol.length; i++) {
        if (!_isPlaying) break;

        final isDash = symbol[i] == '-';
        await _playBeep(isDash);
      }

      await Future.delayed(const Duration(milliseconds: 350));
    }

    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
      _waveController.stop();
    }
  }

  void _stopPlayback() {
    setState(() {
      _isPlaying = false;
    });
    _waveController.stop();
    _audioPlayer.stop();
  }

  void _clearAll() {
    _textController.clear();
    setState(() {
      _morseCode = '';
      _isPlaying = false;
    });
    _waveController.stop();
    _audioPlayer.stop();
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
            const SizedBox(height: 24),

            // Oszilloskop-ähnliche Wellenform
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade700, width: 2),
              ),
              child: _isPlaying
                  ? AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: OscilloscopePainter(
                            animationValue: _waveController.value,
                            isPlaying: _isPlaying,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'Oszilloskop',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isPlaying ? _stopPlayback : _playMorse,
              icon: _isPlaying
                  ? const Icon(Icons.stop, size: 28)
                  : const Icon(Icons.play_arrow, size: 28),
              label: Text(
                _isPlaying ? 'Abbrechen' : 'Morse abspielen',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isPlaying ? Colors.red : Colors.deepPurple,
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

/// Oszilloskop-Style Waveform Painter
class OscilloscopePainter extends CustomPainter {
  final double animationValue;
  final bool isPlaying;

  OscilloscopePainter({
    required this.animationValue,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    final amplitude = isPlaying ? 35.0 : 8.0;
    final frequency = 3.5;

    for (double x = 0; x < width; x += 1.5) {
      final phase = animationValue * 2 * pi * frequency;
      final y = centerY +
          amplitude * sin((x / width * 2 * pi * frequency) + phase);

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Glow effect
    final glowPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.3)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Horizontal grid lines (classic oscilloscope look)
    final gridPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.15)
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OscilloscopePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isPlaying != isPlaying;
  }
}