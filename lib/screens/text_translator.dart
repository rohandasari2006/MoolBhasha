import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../theme/app_theme.dart';
import '../services/indictrans_translator.dart';

class TextTranslatorScreen extends StatefulWidget {
  const TextTranslatorScreen({super.key});

  @override
  State<TextTranslatorScreen> createState() => _TextTranslatorScreenState();
}

class _TextTranslatorScreenState extends State<TextTranslatorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  final ScrollController _sourceScrollController = ScrollController();
  final ScrollController _targetScrollController = ScrollController();

  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeakingSource = false;
  bool _isSpeakingTarget = false;

  bool _showSanthaliKeyboard = true;
  IndicTransTranslator? _translator;

  bool _modelLoading = false;
  bool _translating = false;
  bool _modelInitialized = false;
  // ============================================================
  // DEFAULT LANGUAGES
  // ============================================================

  String _sourceLanguage = 'Hindi';
  String _targetLanguage = 'Santhali';

  String _translatedText = '';
  @override
  void initState() {
    super.initState();

    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _isSpeakingSource = false;
        _isSpeakingTarget = false;
      });
    });

    _flutterTts.setCancelHandler(() {
      if (!mounted) return;
      setState(() {
        _isSpeakingSource = false;
        _isSpeakingTarget = false;
      });
    });

    _flutterTts.setErrorHandler((message) {
      debugPrint('TTS error: $message');
      if (!mounted) return;
      setState(() {
        _isSpeakingSource = false;
        _isSpeakingTarget = false;
      });
    });
  }

  Future<void> _initializeTranslationModel() async {
    if (_modelInitialized) return;

    if (mounted) {
      setState(() {
        _modelLoading = true;
      });
    }

    try {
      _translator ??= IndicTransTranslator();

      await _translator!.initialize();
      _modelInitialized = true;

      debugPrint('IndicTrans2 model loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('Model initialization error: $e');

      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _modelLoading = false;
        });
      }
    }
  }
  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _flutterTts.stop();

    _inputController.dispose();
    _outputController.dispose();
    _sourceScrollController.dispose();
    _targetScrollController.dispose();
    _translator?.dispose();

    super.dispose();
  }

  // ============================================================
  // LANGUAGES
  // ============================================================

  List<String> get _sourceLanguages {
    return const ['Hindi', 'Santhali', 'Mundari'];
  }

  List<String> get _targetLanguages {
    return _sourceLanguages
        .where((language) => language != _sourceLanguage)
        .where((language) {
      if (_sourceLanguage == 'Hindi') {
        return language == 'Santhali' || language == 'Mundari';
      }

      return language == 'Hindi';
    })
        .toList();
  }

  // ============================================================
  // ============================================================
  // SWAP LANGUAGES
  // ============================================================

  void _swapLanguages() {
    final String oldSource = _sourceLanguage;
    final String oldTarget = _targetLanguage;

    if (oldSource == 'Hindi' && oldTarget == 'Santhali') {
      _sourceLanguage = 'Santhali';
      _targetLanguage = 'Hindi';
    } else if (oldSource == 'Santhali' && oldTarget == 'Hindi') {
      _sourceLanguage = 'Hindi';
      _targetLanguage = 'Santhali';
    } else if (oldSource == 'Hindi' && oldTarget == 'Mundari') {
      _sourceLanguage = 'Mundari';
      _targetLanguage = 'Hindi';
    } else if (oldSource == 'Mundari' && oldTarget == 'Hindi') {
      _sourceLanguage = 'Hindi';
      _targetLanguage = 'Mundari';
    } else {
      return;
    }

    final String previousTranslation = _outputController.text;
    _inputController.text = previousTranslation;
    _outputController.clear();

    setState(() {
      _translatedText = '';
      _showSanthaliKeyboard = _sourceLanguage == 'Santhali';
    });

    FocusScope.of(context).unfocus();
  }

  // TRANSLATE
  // ============================================================

  Future<void> _translateText() async {
    final text = _inputController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text to translate.')),
      );
      return;
    }

    if (_modelLoading || _translating) {
      return;
    }

    setState(() {
      _translating = true;
      _translatedText = '';
      _outputController.clear();
    });

    try {
      // Load the ONNX model only when the user presses Translate.
      await _initializeTranslationModel();

      String sourceLanguage;
      String targetLanguage;

      if (_sourceLanguage == 'Hindi') {
        sourceLanguage = 'hin_Deva';

        if (_targetLanguage == 'Santhali') {
          targetLanguage = 'sat_Olck';
        } else if (_targetLanguage == 'Mundari') {
          targetLanguage = 'unr_Deva';
        } else {
          throw Exception('Unsupported target language: $_targetLanguage');
        }
      } else if (_sourceLanguage == 'Santhali') {
        sourceLanguage = 'sat_Olck';
        targetLanguage = 'hin_Deva';
      } else if (_sourceLanguage == 'Mundari') {
        sourceLanguage = 'unr_Deva';
        targetLanguage = 'hin_Deva';
      } else {
        throw Exception('Unsupported source language: $_sourceLanguage');
      }

      debugPrint('====================================');
      debugPrint('TRANSLATION REQUEST');
      debugPrint('Source: $sourceLanguage');
      debugPrint('Target: $targetLanguage');
      debugPrint('Text: $text');
      debugPrint('====================================');

      final result = await _translator!.translate(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );

      debugPrint('TRANSLATION RESULT: $result');

      if (!mounted) return;

      setState(() {
        _translatedText = result;
        _outputController.text = result;
      });
    } catch (e, stackTrace) {
      debugPrint('====================================');
      debugPrint('TRANSLATION ERROR');
      debugPrint('====================================');
      debugPrint('$e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Translation failed: $e')));
    } finally {
      if (!mounted) return;

      setState(() {
        _translating = false;
      });
    }
  }
  // ============================================================
  // CLEAR INPUT
  // ============================================================

  void _clearInput() {
    _inputController.clear();
    _outputController.clear();

    setState(() {
      _translatedText = '';
    });
  }

  // ============================================================
  // COPY TRANSLATION
  // ============================================================

  void _copyTranslation() {
    final text = _outputController.text.trim();

    if (text.isEmpty) {
      return;
    }

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Translation copied.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // TEXT TO SPEECH
  // ============================================================
  Future<void> _speakText({
    required String text,
    required String language,
    required bool isSource,
  }) async {
    final value = text.trim();

    if (value.isEmpty) {
      return;
    }

    final alreadySpeaking = isSource
        ? _isSpeakingSource
        : _isSpeakingTarget;

    if (alreadySpeaking) {
      await _flutterTts.stop();

      if (!mounted) return;

      setState(() {
        _isSpeakingSource = false;
        _isSpeakingTarget = false;
      });

      return;
    }

    try {
      await _flutterTts.stop();

      String ttsLanguage;

      switch (language) {
        case 'Hindi':
          ttsLanguage = 'hi-IN';
          break;

        case 'Santhali':
          ttsLanguage = 'sat-IN';
          break;

        case 'Mundari':
          ttsLanguage = 'unr-IN';
          break;

        default:
          ttsLanguage = 'en-IN';
      }

      final result = await _flutterTts.setLanguage(ttsLanguage);

      debugPrint('TTS language: $ttsLanguage');
      debugPrint('TTS setLanguage result: $result');

      // ------------------------------------------------------------
      // SPEECH SPEED
      // ------------------------------------------------------------

      if (language == 'Santhali') {
        // Santhali - slower speed
        await _flutterTts.setSpeechRate(0.25);
      } else {
        // Hindi / Mundari
        await _flutterTts.setSpeechRate(0.45);
      }

      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      if (!mounted) return;

      setState(() {
        _isSpeakingSource = isSource;
        _isSpeakingTarget = !isSource;
      });

      await _flutterTts.speak(value);
    } catch (e) {
      debugPrint('TTS error: $e');

      if (!mounted) return;

      setState(() {
        _isSpeakingSource = false;
        _isSpeakingTarget = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech failed: $e')),
      );
    }
  }

  // ============================================================
  // SPEAKER BUTTON
  // ============================================================

  Widget _buildSpeakerButton({
    required bool isSpeaking,
    required bool enabled,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isSpeaking
            ? AppColors.green
            : AppColors.green.withOpacity(0.08),
        shape: BoxShape.circle,
        boxShadow: isSpeaking
            ? [
          BoxShadow(
            color: AppColors.green.withOpacity(0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          Icons.volume_up_rounded,
          size: 28,
          color: !enabled
              ? AppColors.textMuted
              : isSpeaking
              ? Colors.white
              : AppColors.green,
        ),
      ),
    );
  }

  // ============================================================
  // SANTHALI KEYBOARD
  // ============================================================

  void _insertSanthaliCharacter(String character) {
    final String text = _inputController.text;
    final TextSelection selection = _inputController.selection;

    final int start = selection.start < 0 ? text.length : selection.start;

    final int end = selection.end < 0 ? text.length : selection.end;

    final String newText = text.replaceRange(start, end, character);

    _inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + character.length),
    );

    setState(() {});
  }

  void _deleteSanthaliCharacter() {
    final String text = _inputController.text;

    if (text.isEmpty) {
      return;
    }

    final TextSelection selection = _inputController.selection;

    final int start = selection.start < 0 ? text.length : selection.start;

    final int end = selection.end < 0 ? text.length : selection.end;

    if (start != end) {
      final String newText = text.replaceRange(start, end, '');

      _inputController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    } else if (start > 0) {
      final String newText = text.replaceRange(start - 1, start, '');

      _inputController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 1),
      );
    }

    setState(() {});
  }

  void _clearSanthaliKeyboardText() {
    _inputController.clear();

    setState(() {});
  }

  Widget _buildSanthaliKeyboard() {
    final List<List<String>> keyboardRows = [
      // Row 1
      ['ᱚ', 'ᱛ', 'ᱜ', 'ᱝ', 'ᱞ', 'ᱟ', 'ᱠ', 'ᱡ'],

      // Row 2
      ['ᱢ', 'ᱣ', 'ᱤ', 'ᱥ', 'ᱦ', 'ᱧ', 'ᱨ', 'ᱩ'],

      // Row 3
      ['ᱪ', 'ᱫ', 'ᱬ', 'ᱭ', 'ᱮ', 'ᱯ', 'ᱰ', 'ᱱ'],

      // Row 4
      ['ᱲ', 'ᱳ', 'ᱴ', 'ᱵ', 'ᱶ', 'ᱷ', 'ᱸ', 'ᱹ'],

      // Row 5
      ['ᱺ', 'ᱻ', 'ᱽ', '᱾', '᱿'],
    ];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.green.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          // ======================================================
          // KEYBOARD HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.keyboard_rounded,
                  size: 18,
                  color: AppColors.green,
                ),
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  'Santhali Keyboard • Ol Chiki',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ),

              GestureDetector(
                onTap: _clearSanthaliKeyboardText,
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iconPeachText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ======================================================
          // CHARACTER ROWS
          // ======================================================
          ...keyboardRows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: row.map((character) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _buildSanthaliKey(character),
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          const SizedBox(height: 1),

          // ======================================================
          // SPECIAL KEYS
          // ======================================================
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSanthaliSpecialKey(
                  icon: Icons.backspace_outlined,
                  onTap: _deleteSanthaliCharacter,
                ),
              ),

              const SizedBox(width: 5),

              Expanded(flex: 5, child: _buildSanthaliSpaceKey()),

              const SizedBox(width: 5),

              Expanded(
                flex: 2,
                child: _buildSanthaliSpecialKey(
                  icon: Icons.keyboard_return_rounded,
                  onTap: () {
                    _insertSanthaliCharacter('\n');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SANTHALI CHARACTER KEY
  // ============================================================

  Widget _buildSanthaliKey(String character) {
    return SizedBox(
      height: 43,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            _insertSanthaliCharacter(character);
          },
          child: Center(
            child: Text(
              character,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SPECIAL KEY
  // ============================================================

  Widget _buildSanthaliSpecialKey({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 43,
      child: Material(
        color: AppColors.cardMint,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(child: Icon(icon, size: 19, color: AppColors.green)),
        ),
      ),
    );
  }

  // ============================================================
  // SPACE KEY
  // ============================================================

  Widget _buildSanthaliSpaceKey() {
    return SizedBox(
      height: 43,
      child: Material(
        color: AppColors.cardMint,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            _insertSanthaliCharacter(' ');
          },
          child: const Center(
            child: Text(
              'SPACE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Text Translator',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.green),
            onPressed: () {
              // History will be added later.
            },
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // PAGE TITLE
              // ==================================================

              const Text(
                'Translate Text',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Translate between Hindi, Santhali and Mundari.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // SOURCE LANGUAGE CARD
              // ==================================================
              _LanguageCard(
                language: _sourceLanguage,
                languages: _sourceLanguages,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _sourceLanguage = value;

                    if (value == 'Hindi') {
                      if (_targetLanguage != 'Santhali' &&
                          _targetLanguage != 'Mundari') {
                        _targetLanguage = 'Santhali';
                      }
                    } else {
                      _targetLanguage = 'Hindi';
                    }

                    _translatedText = '';
                    _outputController.clear();

                    // Remove focus so Android keyboard
                    // does not appear when switching.
                    FocusScope.of(context).unfocus();
                  });
                },

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 145,
                      child: Scrollbar(
                        controller: _sourceScrollController,
                        thumbVisibility: true,
                        radius: const Radius.circular(10),
                        child: TextField(
                          controller: _inputController,
                          scrollController: _sourceScrollController,

                          // Prevent Android keyboard for Santhali.
                          // The custom Ol Chiki keyboard is used instead.
                          readOnly: _sourceLanguage == 'Santhali',

                          minLines: 1,
                          maxLines: null,
                          maxLength: 500,
                          textInputAction: TextInputAction.newline,

                          decoration: InputDecoration(
                            hintText: _sourceLanguage == 'Santhali'
                                ? 'Type using the Santhali keyboard...'
                                : 'Enter text here...',
                            hintStyle: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            suffixIcon: _sourceLanguage == 'Santhali'
                                ? IconButton(
                              icon: Icon(
                                _showSanthaliKeyboard
                                    ? Icons.keyboard_hide_rounded
                                    : Icons.keyboard_rounded,
                                size: 22,
                                color: AppColors.green,
                              ),
                              tooltip: _showSanthaliKeyboard
                                  ? 'Hide keyboard'
                                  : 'Show keyboard',
                              onPressed: () {
                                setState(() {
                                  _showSanthaliKeyboard =
                                  !_showSanthaliKeyboard;
                                });
                              },
                            )
                                : null,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppColors.textDark,
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),
                      ),
                    ),

                    // ==================================================
                    // SANTHALI KEYBOARD
                    // ==================================================
                    if (_sourceLanguage == 'Santhali' && _showSanthaliKeyboard)
                      _buildSanthaliKeyboard(),

                    // Show keyboard button when it is hidden.
                    if (_sourceLanguage == 'Santhali' && !_showSanthaliKeyboard)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showSanthaliKeyboard = true;
                            });
                          },
                          icon: const Icon(
                            Icons.keyboard_rounded,
                            size: 18,
                            color: AppColors.green,
                          ),
                          label: const Text(
                            'Show Santhali Keyboard',
                            style: TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                bottomRow: Row(
                  children: [
                    Text(
                      '${_inputController.text.length}/500',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),

                    const Spacer(),

                    // Source speaker is deliberately placed in the
                    // bottom action row so it does not overlap the text.
                    _buildSpeakerButton(
                      isSpeaking: _isSpeakingSource,
                      enabled: _inputController.text.trim().isNotEmpty,
                      tooltip: _isSpeakingSource
                          ? 'Stop speaking'
                          : 'Speak source text',
                      onPressed: () {
                        _speakText(
                          text: _inputController.text,
                          language: _sourceLanguage,
                          isSource: true,
                        );
                      },
                    ),

                    const SizedBox(width: 8),

                    if (_inputController.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: _clearInput,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 24,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),

              // ==================================================
              // SWAP BUTTON
              // ==================================================
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _swapLanguages,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.green.withOpacity(0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          color: AppColors.green,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ==================================================
              // TARGET LANGUAGE CARD
              // ==================================================
              _LanguageCard(
                language: _targetLanguage,
                languages: _targetLanguages,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _targetLanguage = value;
                    _translatedText = '';
                    _outputController.clear();
                  });
                },

                child: SizedBox(
                  width: double.infinity,
                  height: 145,
                  child: _outputController.text.isEmpty
                      ? const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Translation will appear here...',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                      : Scrollbar(
                    controller: _targetScrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(10),
                    child: SingleChildScrollView(
                      controller: _targetScrollController,
                      padding: const EdgeInsets.only(
                        top: 4,
                        right: 8,
                        bottom: 4,
                      ),
                      child: Text(
                        _outputController.text,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),

                bottomRow: Row(
                  children: [
                    const Spacer(),

                    _buildSpeakerButton(
                      isSpeaking: _isSpeakingTarget,
                      enabled: _outputController.text.trim().isNotEmpty,
                      tooltip: _isSpeakingTarget
                          ? 'Stop speaking'
                          : 'Speak translation',
                      onPressed: () {
                        _speakText(
                          text: _outputController.text,
                          language: _targetLanguage,
                          isSource: false,
                        );
                      },
                    ),

                    const SizedBox(width: 8),

                    IconButton(
                      tooltip: 'Copy translation',
                      onPressed: _outputController.text.trim().isEmpty
                          ? null
                          : _copyTranslation,
                      icon: Icon(
                        Icons.copy_rounded,
                        color: _outputController.text.trim().isEmpty
                            ? AppColors.textMuted
                            : AppColors.green,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // TRANSLATE BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: (_translating || _modelLoading)
                      ? null
                      : _translateText,

                  icon: _translating
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.translate_rounded, size: 21),

                  label: Text(
                    _modelLoading
                        ? 'Loading model...'
                        : _translating
                        ? 'Translating...'
                        : 'Translate Text',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.green,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ==================================================
              // RECENT TRANSLATIONS
              // ==================================================
              const Text(
                'Recent Translations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.green.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppColors.green,
                        size: 24,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'No recent translations',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Your translated texts will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// LANGUAGE CARD
// =================================================================

class _LanguageCard extends StatelessWidget {
  final String language;
  final List<String> languages;
  final ValueChanged<String?> onChanged;
  final Widget child;
  final Widget bottomRow;

  const _LanguageCard({
    required this.language,
    required this.languages,
    required this.onChanged,
    required this.child,
    required this.bottomRow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // =======================================================
          // LANGUAGE SELECTOR
          // =======================================================

          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppColors.green,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: language,
                    isExpanded: true,

                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.green,
                    ),

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),

                    items: languages.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),

                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =======================================================
          // CONTENT
          // =======================================================
          Align(alignment: Alignment.centerLeft, child: child),

          // =======================================================
          // BOTTOM ACTIONS
          // =======================================================
          SizedBox(height: 34, child: bottomRow),
        ],
      ),
    );
  }
}
