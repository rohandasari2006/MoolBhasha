import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
class VoiceTranslatorScreen extends StatefulWidget {
  const VoiceTranslatorScreen({super.key});

  @override
  State<VoiceTranslatorScreen> createState() =>
      _VoiceTranslatorScreenState();
}

class _VoiceTranslatorScreenState
    extends State<VoiceTranslatorScreen> {
  // ------------------------------------------------------------
  // LANGUAGE STATE
  // ------------------------------------------------------------

  String _sourceLanguage = 'Hindi';
  String _targetLanguage = 'Santhali';

  // ------------------------------------------------------------
  // LIVE TRANSLATION STATE
  // ------------------------------------------------------------

  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;

  String _spokenText = '';
  String _translatedText = '';

  // ------------------------------------------------------------
  // SUPPORTED LANGUAGES
  // ------------------------------------------------------------

  List<String> get _sourceLanguages {
    return const [
      'Hindi',
      'Santhali',
      'Mundari',
    ];
  }

  List<String> get _targetLanguages {
    return _sourceLanguages
        .where((language) => language != _sourceLanguage)
        .where((language) {
      if (_sourceLanguage == 'Hindi') {
        return language == 'Santhali' ||
            language == 'Mundari';
      }

      return language == 'Hindi';
    }).toList();
  }

  // ------------------------------------------------------------
  // START LISTENING
  // ------------------------------------------------------------

  Future<void> _startListening() async {
    PermissionStatus permission =
    await Permission.microphone.status;

    if (permission.isDenied) {
      permission =
      await Permission.microphone.request();
    }

    if (permission.isGranted) {
      setState(() {
        _isListening = true;
        _isProcessing = false;
        _isSpeaking = false;
        _spokenText = '';
        _translatedText = '';
      });

      print('Microphone permission granted');

    } else if (permission.isPermanentlyDenied) {
      await openAppSettings();

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone permission is required.',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // STOP LISTENING
  // ------------------------------------------------------------

  void _stopListening() {
    setState(() {
      _isListening = false;
      _isProcessing = false;
      _isSpeaking = false;
    });

    /*
      FUTURE IMPLEMENTATION:

      Stop Speech-to-Text.
    */
  }

  // ------------------------------------------------------------
  // MICROPHONE BUTTON
  // ------------------------------------------------------------

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  // ------------------------------------------------------------
  // SWAP LANGUAGES
  // ------------------------------------------------------------

  void _swapLanguages() {
    setState(() {
      final String oldSource = _sourceLanguage;

      _sourceLanguage = _targetLanguage;
      _targetLanguage = oldSource;

      // Hindi can translate to Santhali or Mundari.
      if (_sourceLanguage == 'Hindi') {
        if (_targetLanguage != 'Santhali' &&
            _targetLanguage != 'Mundari') {
          _targetLanguage = 'Santhali';
        }
      }

      // Tribal language can translate only to Hindi.
      else {
        _targetLanguage = 'Hindi';
      }

      _spokenText = '';
      _translatedText = '';

      _isListening = false;
      _isProcessing = false;
      _isSpeaking = false;
    });
  }

  // ------------------------------------------------------------
  // CLEAR
  // ------------------------------------------------------------

  void _clearTranslation() {
    setState(() {
      _spokenText = '';
      _translatedText = '';

      _isProcessing = false;
      _isSpeaking = false;
    });
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Voice Translator',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: true,
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              const Text(
                'Voice Translation',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Speak naturally and translate instantly.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 22),

              // ------------------------------------------------
              // LANGUAGE SELECTION
              // ------------------------------------------------

              _buildLanguageSection(),

              const SizedBox(height: 22),

              // ------------------------------------------------
              // MICROPHONE SECTION
              // ------------------------------------------------

              _buildMicrophoneSection(),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // LIVE TRANSLATION TITLE
              // ------------------------------------------------

              Row(
                children: [
                  const Text(
                    'Live Translation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),

                  const Spacer(),

                  if (_isProcessing)
                    const SizedBox(
                      width: 17,
                      height: 17,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.green,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------
              // SPOKEN TEXT
              // ------------------------------------------------

              _buildSpokenTextCard(),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // TRANSLATED TEXT
              // ------------------------------------------------

              _buildTranslationCard(),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // LIVE STATUS
              // ------------------------------------------------

              _buildStatusCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LANGUAGE SECTION
  // ============================================================

  Widget _buildLanguageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color:
          AppColors.green.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          const Text(
            'Translation Language',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [

              // FROM
              Expanded(
                child: _LanguageSelector(
                  label: 'From',
                  language:
                  _sourceLanguage,
                  languages:
                  _sourceLanguages,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _sourceLanguage =
                          value;

                      if (value == 'Hindi') {
                        if (_targetLanguage !=
                            'Santhali' &&
                            _targetLanguage !=
                                'Mundari') {
                          _targetLanguage =
                          'Santhali';
                        }
                      } else {
                        _targetLanguage =
                        'Hindi';
                      }

                      _spokenText = '';
                      _translatedText = '';
                    });
                  },
                ),
              ),

              const SizedBox(width: 8),

              // SWAP
              GestureDetector(
                onTap: _swapLanguages,
                child: Container(
                  width: 42,
                  height: 42,
                  margin:
                  const EdgeInsets.only(
                    top: 18,
                  ),
                  decoration:
                  BoxDecoration(
                    color: AppColors.green
                        .withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color:
                    AppColors.green,
                    size: 22,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // TO
              Expanded(
                child: _LanguageSelector(
                  label: 'To',
                  language:
                  _targetLanguage,
                  languages:
                  _targetLanguages,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _targetLanguage =
                          value;

                      _spokenText = '';
                      _translatedText = '';
                    });
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
  // MICROPHONE SECTION
  // ============================================================

  Widget _buildMicrophoneSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color:
          AppColors.green.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

          // STATUS
          Text(
            _isListening
                ? 'Listening...'
                : 'Ready to listen',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _isListening
                  ? AppColors.green
                  : AppColors.textDark,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _isListening
                ? 'Speak in $_sourceLanguage'
                : 'Tap the microphone and start speaking',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: 22),

          // MICROPHONE
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration:
              const Duration(
                milliseconds: 250,
              ),
              width: 96,
              height: 96,
              decoration:
              BoxDecoration(
                color: _isListening
                    ? AppColors.greenDark
                    : AppColors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green
                        .withOpacity(
                      _isListening
                          ? 0.30
                          : 0.18,
                    ),
                    blurRadius:
                    _isListening
                        ? 25
                        : 14,
                    spreadRadius:
                    _isListening
                        ? 6
                        : 1,
                  ),
                ],
              ),
              child: Icon(
                _isListening
                    ? Icons.stop_rounded
                    : Icons.mic_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _isListening
                ? 'Tap to Stop'
                : 'Tap to Speak',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SPOKEN TEXT CARD
  // ============================================================

  Widget _buildSpokenTextCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        10,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          AppColors.green.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Container(
                width: 34,
                height: 34,
                decoration:
                BoxDecoration(
                  color: AppColors.green
                      .withOpacity(0.08),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color:
                  AppColors.green,
                  size: 19,
                ),
              ),

              const SizedBox(width: 9),

              Text(
                'You said • $_sourceLanguage',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  AppColors.textDark,
                ),
              ),

              const Spacer(),

              if (_spokenText.isNotEmpty)
                IconButton(
                  onPressed:
                  _clearTranslation,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                    color:
                    AppColors.textMuted,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _spokenText.isEmpty
                ? 'Your spoken words will appear here...'
                : _spokenText,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: _spokenText.isEmpty
                  ? AppColors.textMuted
                  : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSLATION CARD
  // ============================================================

  Widget _buildTranslationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        10,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          AppColors.green.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Container(
                width: 34,
                height: 34,
                decoration:
                BoxDecoration(
                  color: AppColors.green
                      .withOpacity(0.08),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color:
                  AppColors.green,
                  size: 19,
                ),
              ),

              const SizedBox(width: 9),

              Text(
                '$_targetLanguage Translation',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  AppColors.textDark,
                ),
              ),

              const Spacer(),

              if (_isSpeaking)
                const Icon(
                  Icons.volume_up_rounded,
                  color:
                  AppColors.green,
                  size: 21,
                ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _translatedText.isEmpty
                ? 'Translation will appear here...'
                : _translatedText,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color:
              _translatedText.isEmpty
                  ? AppColors.textMuted
                  : AppColors.textDark,
            ),
          ),

          if (_isSpeaking) ...[
            const SizedBox(height: 12),

            Row(
              children: const [
                Icon(
                  Icons.volume_up_rounded,
                  size: 17,
                  color: AppColors.green,
                ),
                SizedBox(width: 7),
                Text(
                  'Speaking translation...',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    AppColors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _buildStatusCard() {
    String statusText;
    IconData statusIcon;

    if (_isListening) {
      statusText =
      'Listening to $_sourceLanguage...';
      statusIcon =
          Icons.graphic_eq_rounded;
    } else if (_isProcessing) {
      statusText =
      'Translating to $_targetLanguage...';
      statusIcon =
          Icons.sync_rounded;
    } else if (_isSpeaking) {
      statusText =
      'Speaking in $_targetLanguage...';
      statusIcon =
          Icons.volume_up_rounded;
    } else {
      statusText =
      'Tap the microphone to start live translation.';
      statusIcon =
          Icons.mic_none_rounded;
    }

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.green
            .withOpacity(0.06),
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          Icon(
            statusIcon,
            color: AppColors.green,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color:
                AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// LANGUAGE SELECTOR
// ================================================================

class _LanguageSelector
    extends StatelessWidget {
  final String label;
  final String language;
  final List<String> languages;
  final ValueChanged<String?>
  onChanged;

  const _LanguageSelector({
    required this.label,
    required this.language,
    required this.languages,
    required this.onChanged,
  });

  @override
  Widget build(
      BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight:
            FontWeight.w600,
            color:
            AppColors.textMuted,
          ),
        ),

        const SizedBox(height: 5),

        Container(
          height: 48,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          decoration:
          BoxDecoration(
            color:
            AppColors.background,
            borderRadius:
            BorderRadius.circular(13),
          ),
          child:
          DropdownButtonHideUnderline(
            child:
            DropdownButton<String>(
              value: language,
              isExpanded: true,
              icon: const Icon(
                Icons
                    .keyboard_arrow_down_rounded,
                color:
                AppColors.green,
                size: 20,
              ),
              style:
              const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w700,
                color:
                AppColors.textDark,
              ),
              items: languages
                  .map((item) {
                return DropdownMenuItem<
                    String>(
                  value: item,
                  child:
                  Text(item),
                );
              }).toList(),
              onChanged:
              onChanged,
            ),
          ),
        ),
      ],
    );
  }
}