import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/languages/python.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class PythonEditorScreen extends StatefulWidget {
  const PythonEditorScreen({Key? key}) : super(key: key);

  @override
  State<PythonEditorScreen> createState() => _PythonEditorScreenState();
}

class _PythonEditorScreenState extends State<PythonEditorScreen> {
  late CodeController _controller;
  String _output = "";
  bool _isMounted = false;
  bool _isLayoutReady = false;
  bool _showOutput = false;
  bool _isExecuting = false;

  final String _clientId = "c10063b1d10094ca9776222cb879b9d1";
  final String _clientSecret =
      "baaf710a1c70c95de7a5a26bd519ed54ec7aa74b6cdffc7337a1fd560aa3639c";
  //Demo API
  /*
        final String clientId = "c808056d1f8482a432023254299651de";
    final String clientSecret =
        "7717e956467ba2a2927747780ff5db76788fc5f1b1cf3cc69a6a93a4062afacf";*/
  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      language: python,
    );

    _controller.addListener(() {
      if (_isMounted && _isLayoutReady && _controller.text.isEmpty) {
        setState(() {
          _output = "";
          _showOutput = false;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _controller.text = '''
# Python Practice Area
# Write and test your Python code here!

def factorial(n):
    if n == 0:
        return 1
    else:
        return n * factorial(n-1)

print(factorial(5))
          ''';
          _isMounted = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isLayoutReady = true;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _executeCode() async {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _output = "Error: No code to execute!";
        _showOutput = true;
      });
      return;
    }

    setState(() {
      _isExecuting = true;
      _output = "Executing...";
      _showOutput = true;
    });

    final url = Uri.parse("https://api.jdoodle.com/v1/execute");

    final payload = {
      "clientId": _clientId,
      "clientSecret": _clientSecret,
      "script": _controller.text,
      "language": "python3",
      "versionIndex": "3"
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _output = data["output"] ?? "No output returned";
          _isExecuting = false;
        });
      } else {
        setState(() {
          _output = "Error: ${response.body}";
          _isExecuting = false;
        });
      }
    } catch (e) {
      setState(() {
        _output = "Error: $e";
        _isExecuting = false;
      });
    }
  }

  void _clearCode() {
    setState(() {
      _controller.text = '';
      _output = '';
      _showOutput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.7),
                Colors.teal.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: const Border(
              bottom: BorderSide(
                color: Colors.white24,
                width: 1,
              ),
            ),
          ),
        ),
        leading: FadeInLeft(
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(
          'Practice Coding',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          FadeInRight(
            duration: const Duration(milliseconds: 300),
            child: IconButton(
              icon: _isExecuting
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.white),
              onPressed: _isExecuting ? null : _executeCode,
              tooltip: 'Run Code',
            ),
          ),
          FadeInRight(
            duration: const Duration(milliseconds: 400),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _clearCode,
              tooltip: 'Clear Code',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade50.withOpacity(0.8),
              Colors.teal.shade50.withOpacity(0.8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Full-screen Code Editor with Border and Shadow
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CodeTheme(
                    data: CodeThemeData(
                      styles: {
                        ...githubTheme,
                        'root': const TextStyle(
                          backgroundColor: Colors.white,
                        ),
                      },
                    ),
                    child: CodeField(
                      controller: _controller,
                      gutterStyle: GutterStyle(
                        showLineNumbers: true,
                        showErrors: true,
                        textStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        background: Colors.grey[100]!,
                        margin: 4.0,
                        width: 24.0,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'monospace',
                        color: Colors.black,
                      ),
                      expands: true,
                    ),
                  ),
                ),
              ),
            ),
            // Output Panel with Animated Border
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showOutput ? 0 : -220,
              left: 0,
              right: 0,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with Gradient
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.7),
                            Colors.teal.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Output',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _output = '';
                                    _showOutput = false;
                                  });
                                },
                                tooltip: 'Clear Output',
                              ),
                              IconButton(
                                icon: Icon(
                                  _showOutput
                                      ? Icons.expand_more
                                      : Icons.expand_less,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showOutput = !_showOutput;
                                  });
                                },
                                tooltip: 'Toggle Output',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Output content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _output.isEmpty
                              ? "Run your code to see the output!"
                              : _output,
                          style: TextStyle(
                            color: _output.startsWith("Error")
                                ? Colors.redAccent
                                : Colors.black87,
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
