import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';

class TTSWidget extends StatefulWidget {
  final List<Map<String, dynamic>> content;
  final TextStyle paragraphStyle;
  final Color progressColor;
  final VoidCallback onContentCompleted;
  final bool isTTSEnabled;
  final bool showMic;
  final Function(double) onProgressUpdate; // New callback for progress

  const TTSWidget({
    super.key,
    required this.content,
    required this.paragraphStyle,
    required this.progressColor,
    required this.onContentCompleted,
    required this.isTTSEnabled,
    this.showMic = true,
    required this.onProgressUpdate,
  });

  @override
  _TTSWidgetState createState() => _TTSWidgetState();
}

class _TTSWidgetState extends State<TTSWidget> {
  final FlutterTts _flutterTts = FlutterTts();
  int _currentIndex = 0;
  List<int> _displayedIndices = [];
  bool _isTTSEnabled = true;
  String _voice = 'en-us-x-sfg#male';
  double _speechRate = 0.5;
  String _accent = 'US';

  @override
  void initState() {
    super.initState();
    _isTTSEnabled = widget.isTTSEnabled;
    _initializeTts();
    _requestPermissions();
    if (widget.content.isNotEmpty) {
      _addNextItem();
    }
  }

  @override
  void didUpdateWidget(TTSWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTTSEnabled != _isTTSEnabled) {
      setState(() {
        _isTTSEnabled = widget.isTTSEnabled;
        if (!_isTTSEnabled) {
          _flutterTts.stop();
        }
      });
    }
  }

  void _initializeTts() {
    _flutterTts.setLanguage('en-US');
    _flutterTts.setVoice({"name": _voice, "locale": "en-US"});
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(_speechRate);
    _flutterTts.setCompletionHandler(() {
      // No auto-advance, just complete silently
    });
    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
      if (msg.contains("permission")) {
        _showPermissionDialog();
      }
    });
  }

  Future<void> _requestPermissions() async {
    try {
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      print("Permission or initialization error: $e");
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TTS Permission Required'),
        content: const Text('Please grant audio permissions in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _speak(String text) async {
    if (_isTTSEnabled) {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    }
  }

  void _speakCurrentItem() {
    if (_currentIndex > 0 && _currentIndex <= widget.content.length) {
      final item = widget.content[_currentIndex - 1];
      if (item['type'] == 'text' && _isTTSEnabled) {
        _speak(item['value']?.toString() ?? '');
      }
    }
  }

  void _addNextItem() {
    if (_currentIndex >= widget.content.length) {
      widget.onContentCompleted();
      return;
    }
    setState(() {
      _displayedIndices.add(_currentIndex);
      _currentIndex++;
      widget.onProgressUpdate(_currentIndex / widget.content.length);
      _speakCurrentItem();
    });
  }

  bool _isScreenFull(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return false;
    final size = renderBox.size;
    double totalHeight = 0;
    for (int index in _displayedIndices) {
      final item = widget.content[index];
      if (item['type'] == 'text') {
        final textPainter = TextPainter(
          text: TextSpan(
              text: item['value']?.toString() ?? '',
              style: widget.paragraphStyle),
          maxLines: null,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: size.width - 48.0);
        totalHeight += textPainter.height + 16.0;
      } else if (item['type'] == 'animation') {
        totalHeight += 216.0 + 16.0;
      }
    }
    return totalHeight > (screenHeight * 0.8) - 100.0;
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex > widget.content.length && _displayedIndices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (renderObjectReady(context)) {
                  if (!_isScreenFull(context)) {
                    _addNextItem();
                  } else {
                    setState(() {
                      _displayedIndices.clear();
                      if (_currentIndex < widget.content.length) {
                        _displayedIndices.add(_currentIndex);
                        _currentIndex++;
                        widget.onProgressUpdate(
                            _currentIndex / widget.content.length);
                        _speakCurrentItem();
                      } else {
                        widget.onContentCompleted();
                      }
                    });
                  }
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxHeight: constraints.maxHeight),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _displayedIndices.length,
                        itemBuilder: (context, index) {
                          final item = widget.content[_displayedIndices[index]];
                          if (item['type'] == 'text') {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                item['value']?.toString() ?? '',
                                style: widget.paragraphStyle,
                                textAlign: TextAlign.left,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          } else if (item['type'] == 'animation') {
                            final animationData = item['value'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Lottie.asset(
                                    animationData['asset'],
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.contain,
                                    frameRate: FrameRate.max,
                                    animate: true,
                                    repeat: false,
                                    onLoaded: (composition) {
                                      Future.delayed(
                                          Duration(
                                              milliseconds:
                                                  animationData['duration']),
                                          () {
                                        if (mounted) _addNextItem();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.showMic)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isTTSEnabled = !_isTTSEnabled;
                });
                if (!_isTTSEnabled) {
                  _flutterTts.stop();
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isTTSEnabled ? Colors.green : Colors.red,
                ),
                child: Center(
                  child: Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool renderObjectReady(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox != null && renderBox.hasSize;
  }
}
