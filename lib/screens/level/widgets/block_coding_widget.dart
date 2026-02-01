import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_blockly/flutter_blockly.dart' as blockly;
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/monokai-sublime.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:lottie/lottie.dart'; // Import Lottie for animation

class BlocklyCodingWidget extends StatefulWidget {
  final String challengeDescription;
  final String expectedOutput;
  final Function(bool isCorrect) onChallengeCompleted;

  const BlocklyCodingWidget({
    super.key,
    required this.challengeDescription,
    required this.expectedOutput,
    required this.onChallengeCompleted,
  });

  @override
  State<BlocklyCodingWidget> createState() => _BlocklyCodingWidgetState();
}

class _BlocklyCodingWidgetState extends State<BlocklyCodingWidget>
    with WidgetsBindingObserver {
  late final blockly.BlocklyEditor editor;
  String? pythonCode;
  String? executionOutput;
  bool isDarkMode = false;
  String? errorMessage;
  String? savedWorkspaceXml; // To save workspace state
  bool _showSuccessAnimation = false; // State for green tick animation
  bool _showFailureAnimation = false; // State for red X animation
  bool _showNextButton = false; // State for showing the "Next" button
  bool _isBottomSheetOpen = false; // Track bottom sheet state

  static const Duration debounceDuration = Duration(milliseconds: 500);
  static DateTime? lastGenerationTime;

  final blockly.BlocklyOptions workspaceConfiguration =
      const blockly.BlocklyOptions(
    theme: blockly.Theme(
      name: 'pythonTheme',
      blockStyles: {
        'logic_blocks': blockly.BlocklyBlockStyle(
          colourPrimary: '#0288D1',
          colourSecondary: '#4FC3F7',
          colourTertiary: '#01579B',
          hat: 'none',
        ),
        'control_blocks': blockly.BlocklyBlockStyle(
          colourPrimary: '#FBC02D',
          colourSecondary: '#FFEE58',
          colourTertiary: '#F9A825',
          hat: 'none',
        ),
        'math_blocks': blockly.BlocklyBlockStyle(
          colourPrimary: '#4CAF50',
          colourSecondary: '#81C784',
          colourTertiary: '#388E3C',
          hat: 'none',
        ),
        'text_blocks': blockly.BlocklyBlockStyle(
          colourPrimary: '#E91E63',
          colourSecondary: '#F06292',
          colourTertiary: '#C2185B',
          hat: 'none',
        ),
        'list_blocks': blockly.BlocklyBlockStyle(
          colourPrimary: '#FF7043',
          colourSecondary: '#FFAB91',
          colourTertiary: '#F4511E',
          hat: 'none',
        ),
        'dict_blocks': blockly.BlocklyBlockStyle(
          colourPrimary: '#8E24AA',
          colourSecondary: '#CE93D8',
          colourTertiary: '#6A1B9A',
          hat: 'none',
        ),
        'tuple_blocks': blockly.BlocklyBlockStyle(
          colourPrimary: '#D81B60',
          colourSecondary: '#F06292',
          colourTertiary: '#B71C1C',
          hat: 'none',
        ),
        'input_blocks': blockly.BlocklyBlockStyle(
          colourPrimary: '#1976D2',
          colourSecondary: '#64B5F6',
          colourTertiary: '#1565C0',
          hat: 'none',
        ),
        'variable_blocks': blockly.BlocklyBlockStyle(
          colourPrimary: '#FF5722',
          colourSecondary: '#FF8A65',
          colourTertiary: '#E64A19',
          hat: 'none',
        ),
      },
      categoryStyles: {
        'logic_category': blockly.BlocklyCategoryStyle(colour: '#0288D1'),
        'control_category': blockly.BlocklyCategoryStyle(colour: '#FBC02D'),
        'math_category': blockly.BlocklyCategoryStyle(colour: '#4CAF50'),
        'text_category': blockly.BlocklyCategoryStyle(colour: '#E91E63'),
        'list_category': blockly.BlocklyCategoryStyle(colour: '#FF7043'),
        'dict_category': blockly.BlocklyCategoryStyle(colour: '#8E24AA'),
        'tuple_category': blockly.BlocklyCategoryStyle(colour: '#D81B60'),
        'input_category': blockly.BlocklyCategoryStyle(colour: '#1976D2'),
        'variable_category': blockly.BlocklyCategoryStyle(colour: '#FF5722'),
      },
      componentStyles: blockly.BlocklyComponentStyle(
        workspaceBackgroundColour: '#E0F7FA',
        toolboxBackgroundColour: '#37474F',
        flyoutBackgroundColour: '#B0BEC5',
        scrollbarColour: '#78909C',
        scrollbarOpacity: 0.7,
        insertionMarkerColour: '#FFCA28',
        insertionMarkerOpacity: 0.5,
        cursorColour: '#FF5722',
      ),
      fontStyle: blockly.BlocklyFontStyle(
        family: 'Inter, sans-serif',
        weight: '500',
        size: 12,
      ),
    ),
    grid: blockly.GridOptions(
      spacing: 25,
      length: 2,
      colour: '#B0BEC5',
      snap: true,
    ),
    toolbox: blockly.ToolboxInfo(
      kind: 'categoryToolbox',
      contents: [
        {
          'kind': 'category',
          'name': 'Variables',
          'contents': [
            {'kind': 'block', 'type': 'variables_get'},
            {'kind': 'block', 'type': 'variables_set'},
          ],
        },
        {
          'kind': 'category',
          'name': 'Control',
          'contents': [
            {'kind': 'block', 'type': 'controls_if'},
            {'kind': 'block', 'type': 'controls_if_else'},
            {'kind': 'block', 'type': 'controls_ifelseif'},
            {'kind': 'block', 'type': 'controls_for'},
            {'kind': 'block', 'type': 'controls_whileUntil'},
            {'kind': 'block', 'type': 'import_statement'},
          ],
        },
        {
          'kind': 'category',
          'name': 'Logic',
          'contents': [
            {'kind': 'block', 'type': 'logic_compare'},
            {'kind': 'block', 'type': 'logic_operation'},
            {'kind': 'block', 'type': 'logic_boolean'},
          ],
        },
        {
          'kind': 'category',
          'name': 'Math',
          'contents': [
            {
              'kind': 'block',
              'type': 'math_number',
              'fields': {
                'NUM': 0,
              },
            },
            {'kind': 'block', 'type': 'math_arithmetic'},
            {'kind': 'block', 'type': 'math_round'},
          ],
        },
        {
          'kind': 'category',
          'name': 'Text',
          'contents': [
            {
              'kind': 'block',
              'type': 'text',
              'fields': {
                'TEXT': '',
              },
            },
            {'kind': 'block', 'type': 'text_print'},
          ],
        },
        {
          'kind': 'category',
          'name': 'Lists',
          'contents': [
            {'kind': 'block', 'type': 'lists_create_with'},
            {'kind': 'block', 'type': 'lists_getIndex'},
            {'kind': 'block', 'type': 'lists_setIndex'},
          ],
        },
        {
          'kind': 'category',
          'name': 'Dictionaries',
          'contents': [
            {'kind': 'block', 'type': 'dict_create'},
            {'kind': 'block', 'type': 'dict_get'},
            {'kind': 'block', 'type': 'dict_set'},
          ],
        },
        {
          'kind': 'category',
          'name': 'Tuples',
          'contents': [
            {'kind': 'block', 'type': 'tuple_create'},
            {'kind': 'block', 'type': 'tuple_get'},
          ],
        },
        {
          'kind': 'category',
          'name': 'Input',
          'contents': [
            {'kind': 'block', 'type': 'input_text'},
          ],
        },
      ],
    ),
    trashcan: true,
    toolboxPosition: 'start',
    maxBlocks: 100,
    zoom: blockly.ZoomOptions(
      controls: true,
      maxScale: 3,
      minScale: 0.3,
      pinch: true,
      wheel: true,
      startScale: 1.0,
      scaleSpeed: 1.2,
    ),
    collapse: false, // Disable collapsible toolbox
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer

    editor = blockly.BlocklyEditor(
      workspaceConfiguration: workspaceConfiguration,
      initial:
          savedWorkspaceXml ?? '{}', // Restore saved workspace if available
      onInject: onInject,
      onChange: onChange,
      onDispose: onDispose,
      onError: onError,
    );

    editor.blocklyController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PythonChannel',
        onMessageReceived: (message) {
          debugPrint('PythonChannel message received at: ${DateTime.now()}');
          debugPrint('Raw message: ${message.message}');
          try {
            final decoded = jsonDecode(message.message);
            if (decoded['type'] == 'python') {
              debugPrint('Setting pythonCode to: ${decoded['code']}');
              setState(() {
                pythonCode = decoded['code']?.toString().trim() ??
                    'No Python code generated.';
              });
              debugPrint('Python Code updated: $pythonCode');
            } else if (decoded['type'] == 'error') {
              debugPrint('JS Error: ${decoded['message']}');
              setState(() {
                pythonCode = 'Error: ${decoded['message']}';
                errorMessage = decoded['message'];
              });
            } else {
              debugPrint('Unknown message type: ${decoded['type']}');
            }
          } catch (e) {
            debugPrint('Error decoding PythonChannel message: $e');
            setState(() {
              pythonCode = 'Error decoding message: $e';
              errorMessage = 'Error decoding message: $e';
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            debugPrint('WebView page finished loading: $url');
            editor.init();
            try {
              final jsCode = await DefaultAssetBundle.of(context)
                  .loadString('assets/js/blockly_init.js');
              await editor.blocklyController.runJavaScript(jsCode);
              debugPrint('blockly_init.js loaded and executed successfully');

              await Future.delayed(Duration(seconds: 5));
              await editor.blocklyController.runJavaScript('''
                const loadingContainer = document.querySelector('.loading-container');
                if (loadingContainer) {
                  loadingContainer.style.display = 'none';
                  console.log("Loading container hidden via fallback");
                }
              ''');

              await editor.blocklyController.runJavaScript('''
                function resizeWorkspace() {
                  const workspace = Blockly.getMainWorkspace();
                  if (workspace) {
                    const blocklyDiv = document.getElementById('blocklyEditor');
                    const toolboxWidth = document.querySelector('.blocklyToolboxDiv')?.offsetWidth || 0;
                    
                    workspace.setMetrics({
                      viewWidth: blocklyDiv.offsetWidth - toolboxWidth,
                      viewHeight: blocklyDiv.offsetHeight,
                      absoluteLeft: toolboxWidth,
                      absoluteTop: 0,
                      contentWidth: blocklyDiv.offsetWidth * 2,
                      contentHeight: blocklyDiv.offsetHeight * 2
                    });
                    
                    workspace.scrollbar.setOrigin(0, 0);
                    Blockly.svgResize(workspace);
                  }
                }
                
                resizeWorkspace();
                new ResizeObserver(resizeWorkspace).observe(document.body);
                window.addEventListener('resize', function() {
                  resizeWorkspace();
                  Blockly.svgResize(Blockly.getMainWorkspace());
                });
              ''');
            } catch (e) {
              debugPrint('Error loading blockly_init.js: $e');
              setState(() {
                errorMessage = 'Error loading blockly_init.js: $e';
              });
            }
          },
          onWebResourceError: (error) {
            debugPrint('WebView Error: ${error.description}');
            setState(() {
              errorMessage = 'WebView Error: ${error.description}';
            });
          },
        ),
      );

    _loadHtmlContent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Save the workspace state when the app is paused
      editor.blocklyController.runJavaScriptReturningResult('''
        if (typeof Blockly !== "undefined") {
          const workspace = Blockly.getMainWorkspace();
          if (workspace) {
            return Blockly.Xml.domToText(Blockly.Xml.workspaceToDom(workspace));
          }
        }
        return '{}';
      ''').then((result) {
        setState(() {
          savedWorkspaceXml = result.toString();
        });
        debugPrint('Workspace saved: $savedWorkspaceXml');
      });
    } else if (state == AppLifecycleState.resumed) {
      // Restore the workspace state when the app is resumed
      if (savedWorkspaceXml != null) {
        editor.blocklyController.runJavaScript('''
          if (typeof Blockly !== "undefined") {
            const workspace = Blockly.getMainWorkspace();
            if (workspace) {
              const xml = Blockly.Xml.textToDom('$savedWorkspaceXml');
              Blockly.Xml.clearWorkspaceAndLoadFromXml(xml, workspace);
              Blockly.svgResize(workspace);
            }
          }
        ''');
        debugPrint('Workspace restored');
      }
    }
  }

  Future<void> _loadHtmlContent() async {
    try {
      final htmlString = await editor.htmlRender(
        style: '''
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

  html, body, .wrapper, .wrap-container, #blocklyEditor {
    margin: 0;
    padding: 0;
    height: 100% !important;
    width: 100% !important;
    overflow: hidden;
    font-family: 'Inter', sans-serif;
    position: absolute;
    top: 0;
    left: 0;
    box-sizing: border-box;
  }

  .blocklySvg, .blocklyWorkspace, .blocklyBlockCanvas, .blocklyBubbleCanvas {
    position: absolute !important;
    top: 0 !important;
    left: 0 !important;
    height: 100% !important;
    width: 100% !important;
    z-index: 1;
  }

  .blocklyMainBackground {
    fill: transparent !important;
  }

  .blocklyScrollbarHandle {
    fill: #78909C !important;
  }

  .blocklyWidgetDiv {
    position: absolute !important;
    z-index: 9999 !important;
  }

  .blocklyDraggable {
    touch-action: none !important;
  }

  /* Fixed Toolbox Styles */
  .blocklyToolboxDiv {
    background: rgba(55, 71, 79, 0.95);
    backdrop-filter: blur(8px);
    color: #FFFFFF;
    font-family: 'Inter', sans-serif;
    border-right: 1px solid rgba(2, 136, 209, 0.3);
    position: absolute;
    left: 0;
    top: 0;
    height: 100%;
    width: 150px; /* Reduced toolbox width */
    z-index: 2;
    box-shadow: 3px 0 8px rgba(0, 0, 0, 0.15);
    border-radius: 0 12px 12px 0;
  }

  .blocklyTreeRow {
    display: flex;
    align-items: center;
    padding: 6px 10px; /* Adjusted padding for smaller toolbox */
    margin: 2px 6px; /* Adjusted margin */
    height: 36px; /* Reduced height */
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.05);
    border-bottom: 1px solid rgba(84, 110, 122, 0.3);
  }

  .blocklyTreeRow:hover {
    background: rgba(255, 255, 255, 0.15);
    transform: translateX(3px);
    transition: background 0.3s ease, transform 0.2s ease;
  }

  .fa-icon {
    font-size: 16px; /* Reduced icon size */
    color: #FFFFFF;
    margin-right: 8px;
    width: 20px; /* Adjusted icon width */
    height: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .blocklyTreeRow:hover .fa-icon {
    color: #FFCA28;
  }

  .blocklyTreeLabel {
    font-size: 13px; /* Reduced font size */
    font-weight: 500;
    display: inline !important;
  }

  /* Other Styles */
  .blocklyTreeSeparator {
    margin: 0;
    padding: 0;
    height: 1px;
    background: rgba(84, 110, 122, 0.2);
  }

  .blocklyTrash {
    background: #FFCA28 !important;
    border-radius: 16px;
    padding: 10px;
    bottom: 20px;
    right: 20px;
    box-shadow: 0 3px 6px rgba(0, 0, 0, 0.2);
    transition: transform 0.2s ease;
    z-index: 3;
  }

  .blocklyTrash:hover {
    transform: scale(1.1);
  }

  .loading-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    width: 100%;
    color: #888;
    background: linear-gradient(135deg, #E0F7FA 0%, #B2EBF2 100%);
    position: absolute;
    top: 0;
    left: 0;
    z-index: 10;
    transition: opacity 0.3s ease;
  }

  .loading-container[style*="display: none"] {
    opacity: 0;
    pointer-events: none;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 5px solid #0288D1;
    border-top: 5px solid transparent;
    border-radius: 50%;
    animation: spin 1.2s cubic-bezier(0.68, -0.55, 0.27, 1.55) infinite;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
''',
        editor: '''
          <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
          <div class='wrapper'>
            <div id='blocklyEditor' class='wrap-container'>
              <div class='loading-container'>
                <div class='spinner'></div>
                <p style='margin-top: 20px; font-size: 16px; font-weight: 500;'>Loading Blockly Editor...</p>
              </div>
            </div>
          </div>
        ''',
        packages: '''
          <script src='https://unpkg.com/blockly/blockly.min.js' defer></script>
          <script src="https://unpkg.com/blockly/python_compressed.js" defer></script>
        ''',
      );
      editor.blocklyController.loadHtmlString(htmlString);
      debugPrint('HTML loaded successfully');
    } catch (e) {
      debugPrint('Error loading HTML: $e');
      setState(() {
        errorMessage = 'Error loading HTML: $e';
      });
    }
  }

  Future<String> executeCode(String code) async {
    final String clientId = "c10063b1d10094ca9776222cb879b9d1";
    final String clientSecret =
        "baaf710a1c70c95de7a5a26bd519ed54ec7aa74b6cdffc7337a1fd560aa3639c";

    const String apiUrl = 'https://api.jdoodle.com/v1/execute';

    // Replace input() calls with a mock value since JDoodle doesn't support interactive input
    String modifiedCode = code.replaceAllMapped(
      RegExp(r'input\(".*?"\)'),
      (match) => '"mock_input"', // Replace input() with a static string
    );

    try {
      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'clientId': clientId,
          'clientSecret': clientSecret,
          'script': modifiedCode,
          'language': 'python3',
          'versionIndex': '3',
        }),
      )
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('JDoodle API request timed out');
      });

      debugPrint('JDoodle API Response Status: ${response.statusCode}');
      debugPrint('JDoodle API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['error'] != null && result['error'].isNotEmpty) {
          return 'JDoodle Error: ${result['error']}';
        }
        String output = result['output']?.trim() ?? 'No output';
        if (output.isEmpty) {
          output = result['memory'] != null || result['cpuTime'] != null
              ? 'Execution completed (no output).\nMemory: ${result['memory']}, CPU Time: ${result['cpuTime']}'
              : 'No output';
        }
        return output;
      } else {
        return 'Failed to execute code: HTTP ${response.statusCode}\n${response.body}';
      }
    } catch (e) {
      debugPrint('JDoodle API Error: $e');
      return 'Error executing code: $e';
    }
  }

  void onInject(blockly.BlocklyData data) {
    debugPrint('onInject: ${data.xml}\n${jsonEncode(data.json)}');
  }

  void onChange(blockly.BlocklyData data) {
    debugPrint('onChange triggered at: ${DateTime.now()}');
    final now = DateTime.now();
    if (lastGenerationTime == null ||
        now.difference(lastGenerationTime!).inMilliseconds >=
            debounceDuration.inMilliseconds) {
      lastGenerationTime = now;
      debugPrint('Running JS to generate Python code');
      editor.blocklyController.runJavaScript('''
        if (typeof Blockly !== "undefined" && typeof Blockly.Python !== "undefined") {
          var workspace = Blockly.getMainWorkspace();
          if (workspace) {
            Blockly.Python.init(workspace);
            var pythonCode = Blockly.Python.workspaceToCode(workspace);
            console.log("Generated Python Code:", pythonCode); // Debug log
            if (window.PythonChannel) {
              window.PythonChannel.postMessage(JSON.stringify({type: "python", code: pythonCode}));
            }
          } else {
            console.error("Workspace not found");
          }
        } else {
          console.error("Blockly or Blockly.Python not defined");
        }
      ''');
    } else {
      debugPrint('Debounce active, skipping JS execution');
    }
  }

  void onDispose(blockly.BlocklyData data) {
    debugPrint('onDispose: ${data.xml}\n${jsonEncode(data.json)}');
  }

  void onError(dynamic err) {
    debugPrint('onError: $err');
    setState(() {
      errorMessage = 'Blockly Error: $err';
    });
  }

  void _showPythonCodeBottomSheet(BuildContext context) {
    if (_isBottomSheetOpen) {
      debugPrint('Bottom sheet already open, updating content');
      setState(() {}); // Trigger rebuild to update content
      return;
    }

    _isBottomSheetOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter sheetSetState) {
            // Parse the code into sections
            String imports = '';
            String loops = '';
            String others = '';
            if (pythonCode != null &&
                pythonCode!.isNotEmpty &&
                pythonCode != 'No Python code generated.') {
              final lines = pythonCode!.split('\n');
              for (var line in lines) {
                if (line.trim().isEmpty) continue; // Skip empty lines
                if (line.startsWith('[import]')) {
                  imports += line.replaceFirst('[import]', '') + '\n';
                } else if (line.startsWith('[loop]')) {
                  loops += line.replaceFirst('[loop]', '') + '\n';
                } else if (line.startsWith('[other]')) {
                  others += line.replaceFirst('[other]', '') + '\n';
                } else {
                  // If no tag is present, assume it's an 'other' statement
                  others += line + '\n';
                }
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 6,
                            margin: const EdgeInsets.symmetric(vertical: 12.0),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF0288D1),
                                const Color(0xFF4FC3F7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Python Output',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: pythonCode != null
                                        ? () {
                                            Clipboard.setData(ClipboardData(
                                                text: pythonCode!));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Code copied to clipboard',
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                                backgroundColor: isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.grey[200],
                                              ),
                                            );
                                          }
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Icon(
                                        Icons.copy,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        pythonCode = null;
                                        executionOutput = null;
                                      });
                                      sheetSetState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Icon(
                                        Icons.clear,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Import Statements Section
                        if (imports.isNotEmpty) ...[
                          Text(
                            'Import Statements',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[900]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: HighlightView(
                              imports,
                              language: 'python',
                              theme: isDarkMode
                                  ? monokaiSublimeTheme
                                  : monokaiSublimeTheme,
                              padding: const EdgeInsets.all(12.0),
                              textStyle: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Loop Statements Section
                        if (loops.isNotEmpty) ...[
                          Text(
                            'Loop Statements',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[900]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: HighlightView(
                              loops,
                              language: 'python',
                              theme: isDarkMode
                                  ? monokaiSublimeTheme
                                  : monokaiSublimeTheme,
                              padding: const EdgeInsets.all(12.0),
                              textStyle: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Other Statements Section
                        if (others.isNotEmpty) ...[
                          Text(
                            'Other Statements',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[900]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: HighlightView(
                              others,
                              language: 'python',
                              theme: isDarkMode
                                  ? monokaiSublimeTheme
                                  : monokaiSublimeTheme,
                              padding: const EdgeInsets.all(12.0),
                              textStyle: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Execution Output Section
                        if (executionOutput != null) ...[
                          Text(
                            'Execution Output',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[900]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              executionOutput!,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                height: 1.5,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                        if (pythonCode == null ||
                            pythonCode!.isEmpty ||
                            pythonCode == 'No Python code generated.')
                          Text(
                            'No Python code generated yet.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        _isBottomSheetOpen = false;
      });
      debugPrint('Bottom sheet closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkMode
          ? ThemeData.dark().copyWith(
              primaryColor: const Color(0xFF0288D1),
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              cardColor: const Color(0xFF1E1E1E),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(fontFamily: 'Inter'),
                bodyMedium: TextStyle(fontFamily: 'Inter'),
              ),
            )
          : ThemeData.light().copyWith(
              primaryColor: const Color(0xFF0288D1),
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              cardColor: Colors.grey[100],
              textTheme: const TextTheme(
                bodyLarge: TextStyle(fontFamily: 'Inter'),
                bodyMedium: TextStyle(fontFamily: 'Inter'),
              ),
            ),
      child: Column(
        children: [
          // Challenge Description
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Text(
              widget.challengeDescription,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Blockly Editor
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child:
                          WebViewWidget(controller: editor.blocklyController),
                    ),
                  ),
                ),
                if (errorMessage != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: Colors.red.withOpacity(0.9),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () =>
                                setState(() => errorMessage = null),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => _showPythonCodeBottomSheet(context),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? const Color(0xFF263238) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(-2, -2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.code,
                        color: Color(0xFF0288D1),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                // Run Button
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: GestureDetector(
                    onTap: pythonCode != null &&
                            pythonCode!.isNotEmpty &&
                            pythonCode != 'No Python code generated.'
                        ? () async {
                            debugPrint('Run button clicked');
                            String cleanCode = pythonCode!
                                .replaceAll('[import]', '')
                                .replaceAll('[loop]', '')
                                .replaceAll('[other]', '')
                                .trim();
                            setState(() {
                              executionOutput = 'Executing...';
                            });
                            try {
                              final output = await executeCode(cleanCode);
                              setState(() {
                                executionOutput = output;
                              });
                              debugPrint('Execution output: $output');
                              _showPythonCodeBottomSheet(context);
                            } catch (e) {
                              setState(() {
                                executionOutput = 'Error executing code: $e';
                              });
                              debugPrint('Execution error: $e');
                              _showPythonCodeBottomSheet(context);
                            }
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: pythonCode != null &&
                                pythonCode!.isNotEmpty &&
                                pythonCode != 'No Python code generated.'
                            ? (isDarkMode
                                ? const Color(0xFF263238)
                                : Colors.white)
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(-2, -2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Color(0xFF0288D1),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                // Submit Button (Tick Icon)
                Positioned(
                  bottom: 20,
                  left: 90, // Adjusted to place it next to the Run button
                  child: GestureDetector(
                    onTap: pythonCode != null &&
                            pythonCode!.isNotEmpty &&
                            pythonCode != 'No Python code generated.'
                        ? () async {
                            debugPrint('Submit button clicked');
                            String cleanCode = pythonCode!
                                .replaceAll('[import]', '')
                                .replaceAll('[loop]', '')
                                .replaceAll('[other]', '')
                                .trim();
                            setState(() {
                              executionOutput = 'Executing...';
                              _showSuccessAnimation = false;
                              _showFailureAnimation = false;
                              _showNextButton =
                                  false; // Reset Next button visibility
                            });
                            try {
                              final output = await executeCode(cleanCode);
                              setState(() {
                                executionOutput = output;
                              });
                              debugPrint('Submit output: $output');
                              // Check if the output matches the expected output
                              bool isCorrect =
                                  output.trim() == widget.expectedOutput;
                              if (isCorrect) {
                                // Show the green tick animation
                                setState(() {
                                  _showSuccessAnimation = true;
                                });
                                // Delay to show the animation, then proceed
                                await Future.delayed(Duration(seconds: 2));
                                setState(() {
                                  _showSuccessAnimation =
                                      false; // Reset animation
                                });
                                debugPrint('Navigating to next section');
                                // Navigate to the next section
                                widget.onChallengeCompleted(isCorrect);
                              } else {
                                // Show the red X animation
                                setState(() {
                                  _showFailureAnimation = true;
                                });
                                // Delay to show the animation, then reset
                                await Future.delayed(Duration(seconds: 2));
                                setState(() {
                                  _showFailureAnimation =
                                      false; // Reset animation
                                  _showNextButton =
                                      true; // Show the Next button
                                });
                                _showPythonCodeBottomSheet(context);
                              }
                            } catch (e) {
                              setState(() {
                                executionOutput = 'Error executing code: $e';
                                _showFailureAnimation =
                                    false; // Ensure animation is reset
                                _showNextButton =
                                    true; // Show the Next button on error
                              });
                              debugPrint('Submit error: $e');
                              _showPythonCodeBottomSheet(context);
                            }
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: pythonCode != null &&
                                pythonCode!.isNotEmpty &&
                                pythonCode != 'No Python code generated.'
                            ? (isDarkMode
                                ? const Color(0xFF263238)
                                : Colors.white)
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(-2, -2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF0288D1),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                // Next Button (Appears after incorrect answer)
                if (_showNextButton)
                  Positioned(
                    bottom: 20,
                    left: 160, // Adjusted to place it next to the Submit button
                    child: GestureDetector(
                      onTap: () {
                        debugPrint('Next button clicked');
                        setState(() {
                          _showNextButton = false; // Hide the Next button
                          _showFailureAnimation =
                              false; // Ensure animation is reset
                          pythonCode = null; // Reset code to allow retry
                          executionOutput = null; // Reset output
                        });
                        widget.onChallengeCompleted(
                            false); // Proceed to next section
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF263238)
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            ),
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(-2, -2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF0288D1),
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                // Green Tick Animation Overlay
                if (_showSuccessAnimation)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Lottie.asset(
                          'assets/lottie/success.json', // Path to your green tick animation
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                          repeat: false,
                          onLoaded: (composition) {
                            // Ensure the animation is hidden after it completes
                            Future.delayed(Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() {
                                  _showSuccessAnimation = false;
                                });
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                // Red X Animation Overlay
                if (_showFailureAnimation)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Lottie.asset(
                          'assets/lottie/failure.json', // Path to your red X animation
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                          repeat: false,
                          onLoaded: (composition) {
                            // Ensure the animation is hidden after it completes
                            Future.delayed(Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() {
                                  _showFailureAnimation = false;
                                  _showNextButton =
                                      true; // Show the Next button
                                });
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    editor.dispose();
    super.dispose();
  }
}
