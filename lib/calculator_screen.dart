import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'calculator_utils.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  bool isDarkMode = false;
  bool isDegreeMode = true;
  String expression = '';
  String result = '0';
  final List<Map<String, String>> history = [];

  final FlutterTts flutterTts = FlutterTts();

  void showHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final foregroundColor = isDarkMode ? Colors.white : Colors.black87;
        final secondaryColor = isDarkMode ? Colors.white70 : Colors.black54;

        return Container(
          height: 400,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2A2B2B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Calculation History',
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: secondaryColor),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: secondaryColor.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: history.isEmpty
                      ? Center(
                          child: Text(
                            'No calculations yet',
                            style: TextStyle(color: secondaryColor),
                          ),
                        )
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final calculation = history[index];
                            return ListTile(
                              title: Text(
                                calculation['expression']!.replaceAll('*', '×'),
                                style: TextStyle(color: foregroundColor),
                              ),
                              subtitle: Text(
                                '= ${calculation['result']}',
                                style: TextStyle(color: secondaryColor),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color getButtonColor(String button) {
    if (['+', '-', '×', '/', '=', '%', 'c'].contains(button)) {
      return isDarkMode
          ? const Color.fromARGB(255, 17, 145, 7)
          : const Color.fromARGB(255, 250, 75, 0);
    }

    if (['sin', 'cos', 'tan', '(', ')'].contains(button)) {
      return isDarkMode
          ? const Color.fromARGB(255, 254, 255, 254)
          : const Color.fromARGB(255, 0, 0, 0);
    }

    return isDarkMode
        ? const Color.fromARGB(255, 255, 255, 255)
        : const Color.fromARGB(255, 68, 67, 67);
  }

  void handleButton(String button) {
    setState(() {
      if (button == 'c') {
        expression = '';
        result = '0';
      } else if (button == '=') {
        calculate();
        if (expression.trim().isNotEmpty && result != 'Error') {
          history.insert(0, {'expression': expression, 'result': result});
        }
      } else if (button == 'sin' || button == 'cos' || button == 'tan') {
        expression += '$button(';
      } else if (button == 'x') {
        expression += '*';
      } else if (button == '⌫') {
        if (expression.isNotEmpty) {
          expression = expression.substring(0, expression.length - 1);
        }
      } else {
        expression += button;
      }
    });
  }

  void calculate() {
    try {
      final parser = GrammarParser();
      parser.functions1
        ..remove('sin')
        ..remove('cos')
        ..remove('tan');
      double toRadians(double value) =>
          isDegreeMode ? value * math.pi / 180 : value;
      double cleanTrigResult(double value) => value.abs() < 1e-12 ? 0 : value;
      parser.functionsC.addAll({
        'sin': (arguments) =>
            cleanTrigResult(math.sin(toRadians(arguments.single))),
        'cos': (arguments) =>
            cleanTrigResult(math.cos(toRadians(arguments.single))),
        'tan': (arguments) {
          final radians = toRadians(arguments.single);
          if (math.cos(radians).abs() < 1e-12) return double.nan;
          return cleanTrigResult(math.tan(radians));
        },
      });

      final parsedExpression = parser.parse(expression.replaceAll('×', '*'));

      final evaluator = RealEvaluator(ContextModel());

      final answer = evaluator.evaluate(parsedExpression);

      result = formatCalculationResult(answer);
    } catch (e) {
      result = 'Error';
    }
  }

  void translateAnswer() {
    if (expression.trim().isNotEmpty) {
      setState(calculate);
    }
    if (result == 'Error') {
      showConvertedNumberDialog('The current calculation has no valid answer.');
      return;
    }
    showConvertedNumberDialog(numberToEnglish(result));
  }

  void showConvertedNumberDialog(String convertedText) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode
              ? Color.fromARGB(255, 42, 43, 43)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          title: Text(
            'Converted Number',
            style: TextStyle(
              color: isDarkMode ? Colors.green : Colors.deepOrange,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          scrollable: true,
          content: SelectableText(
            convertedText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 20,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: isDarkMode ? Colors.green : Colors.deepOrange,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await speakText(convertedText);
              },
              child: Text(
                'Speak',
                style: TextStyle(
                  color: isDarkMode ? Colors.green : Colors.deepOrange,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> speakAnswer() async {
    await speakText(result);
  }

  Future<void> speakText(String text) async {
    try {
      if (text == 'Error' || text.isEmpty) {
        debugPrint('There is no valid answer to speak.');
        return;
      }

      await flutterTts.setLanguage('en-US');
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);

      await flutterTts.stop();

      final response = await flutterTts.speak(text);

      debugPrint('TTS response: $response');
    } catch (e) {
      debugPrint('Voice error: $e');
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color.fromARGB(255, 42, 43, 43)
          : const Color(0xFFF5F5F5),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),

          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shadowColor: Colors.grey,
                      backgroundColor: isDarkMode
                          ? Color.fromARGB(255, 32, 31, 31)
                          : Colors.white,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isDarkMode = false;
                            });
                          },
                          icon: Icon(
                            Icons.sunny,
                            color: isDarkMode ? Colors.grey : Colors.deepOrange,
                            size: 28,
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            setState(() {
                              isDarkMode = true;
                            });
                          },
                          icon: Icon(
                            Icons.dark_mode,
                            color: isDarkMode ? Colors.green : Colors.grey,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isDegreeMode = !isDegreeMode;
                      });
                    },
                    child: Text(isDegreeMode ? 'DEG' : 'RAD'),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Calculation History',
                    onPressed: showHistory,
                    icon: Icon(
                      Icons.history,
                      size: 28,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.translate),
                        iconSize: 28,
                        color: isDarkMode ? Colors.white : Colors.black,
                        onPressed: () {
                          translateAnswer();
                        },
                      ),
                      SizedBox(width: 25),
                      IconButton(
                        onPressed: () async {
                          await speakAnswer();
                        },
                        icon: Icon(
                          Icons.volume_up,
                          size: 28,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // DISPLAY SECTION
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildDisplayText(
                        result,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: isDarkMode ? Colors.white : Colors.deepOrange,
                      ),
                      _buildDisplayText(
                        expression.isEmpty ? '0' : expression,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ],
                  ),
                  // child: Text(
                  //   '0',
                  //   style: TextStyle(
                  //     fontSize: 48,
                  //     fontWeight: FontWeight.bold,
                  //     color: isDarkMode ? Colors.green : Colors.deepOrange,
                  //   ),
                  // ),
                ),
              ),

              // KEYPAD SECTION
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    buildButtonRow(['sin', 'cos', 'tan', '%']),
                    buildButtonRow(['c', '(', ')', '/']),
                    buildButtonRow(['7', '8', '9', '×']),
                    buildButtonRow(['4', '5', '6', '-']),
                    buildButtonRow(['1', '2', '3', '+']),
                    buildButtonRow(['0', '.', '⌫', '=']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayText(
    String text, {
    required double fontSize,
    required Color color,
    FontWeight? fontWeight,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((button) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: AspectRatio(
                aspectRatio: 1,

                child: ElevatedButton(
                  onPressed: () {
                    handleButton(button);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),

                    backgroundColor: isDarkMode
                        ? const Color.fromARGB(255, 32, 31, 31)
                        : Colors.white,

                    foregroundColor: getButtonColor(button),
                    elevation: 2,
                    shadowColor: Colors.grey,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.center,
                  ),

                  child: Center(
                    child: button == '⌫'
                        ? Icon(
                            Icons.backspace_outlined,
                            size: 25,
                            color: getButtonColor(button),
                          )
                        : Text(
                            button,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                    ),
                ),
                // child: ElevatedButton(
                //   onPressed: () {
                //     debugPrint(button);
                //   },
                //   child: Text(button, style: const TextStyle(fontSize: 17)),
                // ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
