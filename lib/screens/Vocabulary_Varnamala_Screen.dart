import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../theme/app_theme.dart';

class VocabularyVarnamalaScreen extends StatefulWidget {
  const VocabularyVarnamalaScreen({super.key});

  @override
  State<VocabularyVarnamalaScreen> createState() =>
      _VocabularyVarnamalaScreenState();
}

class _VocabularyVarnamalaScreenState
    extends State<VocabularyVarnamalaScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  int _selectedGrade = 1;
  int _selectedTab = 0;

  final Random _random = Random();

  List<Map<String, String>> _vocabulary = [];

  // ============================================================
  // HINDI - SANTHALI VOCABULARY
  // Replace these sample words with your verified vocabulary.
  // ============================================================

  final Map<int, List<Map<String, String>>> _gradeVocabulary = {
    1: [
      {'hindi': 'माँ', 'santhali': 'ᱟᱭᱚ'},
      {'hindi': 'पिता', 'santhali': 'ᱵᱟᱵᱟ'},
      {'hindi': 'भाई', 'santhali': 'ᱵᱷᱟᱭ'},
      {'hindi': 'बहन', 'santhali': 'ᱵᱟᱦᱤᱱ'},
      {'hindi': 'घर', 'santhali': 'ᱚᱲᱟᱜ'},
      {'hindi': 'पानी', 'santhali': 'ᱫᱟᱜ'},
      {'hindi': 'आम', 'santhali': 'ᱡᱚᱢ'},
      {'hindi': 'चावल', 'santhali': 'ᱡᱚᱢ'},
      {'hindi': 'सूरज', 'santhali': 'ᱥᱤᱧ'},
      {'hindi': 'चाँद', 'santhali': 'ᱪᱟᱸᱫᱚ'},
      {'hindi': 'पेड़', 'santhali': 'ᱫᱟᱨᱮ'},
      {'hindi': 'फूल', 'santhali': 'ᱵᱟᱦᱟ'},
      {'hindi': 'फल', 'santhali': 'ᱡᱟᱹᱛ'},
      {'hindi': 'गाय', 'santhali': 'ᱜᱚᱨᱩ'},
      {'hindi': 'कुत्ता', 'santhali': 'ᱥᱮᱛᱟ'},
      {'hindi': 'बिल्ली', 'santhali': 'ᱵᱤᱞᱟᱹᱛᱤ'},
      {'hindi': 'पक्षी', 'santhali': 'ᱪᱮᱫᱮ'},
      {'hindi': 'मछली', 'santhali': 'ᱢᱟᱪᱷᱤ'},
      {'hindi': 'स्कूल', 'santhali': 'ᱤᱥᱠᱩᱞ'},
      {'hindi': 'किताब', 'santhali': 'ᱯᱚᱛᱚᱵ'},
    ],

    2: [
      {'hindi': 'परिवार', 'santhali': 'ᱯᱟᱹᱨᱤᱵᱟᱨ'},
      {'hindi': 'दोस्त', 'santhali': 'ᱥᱟᱹᱦᱟᱹᱭ'},
      {'hindi': 'शिक्षक', 'santhali': 'ᱜᱩᱨᱩ'},
      {'hindi': 'बच्चा', 'santhali': 'ᱦᱚᱲ'},
      {'hindi': 'लड़का', 'santhali': 'ᱠᱚᱲᱟ'},
      {'hindi': 'लड़की', 'santhali': 'ᱠᱩᱲᱤ'},
      {'hindi': 'खाना', 'santhali': 'ᱡᱚᱢ'},
      {'hindi': 'दूध', 'santhali': 'ᱫᱩᱫᱷ'},
      {'hindi': 'आकाश', 'santhali': 'ᱥᱟᱹᱨᱤ'},
      {'hindi': 'धरती', 'santhali': 'ᱡᱟᱢᱤᱱ'},
      {'hindi': 'नदी', 'santhali': 'ᱜᱟᱹᱫᱟ'},
      {'hindi': 'पहाड़', 'santhali': 'ᱵᱩᱨᱩ'},
      {'hindi': 'जंगल', 'santhali': 'ᱵᱤᱨ'},
      {'hindi': 'बारिश', 'santhali': 'ᱜᱟᱹᱲᱟᱹ'},
      {'hindi': 'हवा', 'santhali': 'ᱦᱟᱹᱣᱟ'},
      {'hindi': 'आग', 'santhali': 'ᱥᱮᱫ'},
      {'hindi': 'दिन', 'santhali': 'ᱢᱟᱦᱟ'},
      {'hindi': 'रात', 'santhali': 'ᱱᱤᱫᱟᱹ'},
      {'hindi': 'सुबह', 'santhali': 'ᱥᱮᱛᱟᱜ'},
      {'hindi': 'खेल', 'santhali': 'ᱠᱷᱮᱞ'},
    ],

    3: [
      {'hindi': 'प्रकृति', 'santhali': 'ᱯᱨᱚᱠᱨᱤᱛᱤ'},
      {'hindi': 'पर्यावरण', 'santhali': 'ᱯᱟᱹᱨᱤᱵᱮᱥ'},
      {'hindi': 'किसान', 'santhali': 'ᱠᱤᱥᱟᱱ'},
      {'hindi': 'खेत', 'santhali': 'ᱠᱷᱮᱛ'},
      {'hindi': 'बीज', 'santhali': 'ᱵᱤᱡ'},
      {'hindi': 'फसल', 'santhali': 'ᱯᱷᱟᱥᱚᱞ'},
      {'hindi': 'पेड़', 'santhali': 'ᱫᱟᱨᱮ'},
      {'hindi': 'पत्ता', 'santhali': 'ᱥᱟᱠᱟᱢ'},
      {'hindi': 'फूल', 'santhali': 'ᱵᱟᱦᱟ'},
      {'hindi': 'आसमान', 'santhali': 'ᱥᱟᱹᱨᱤ'},
      {'hindi': 'बादल', 'santhali': 'ᱛᱩᱞᱩᱪ'},
      {'hindi': 'सूर्य', 'santhali': 'ᱥᱤᱧ'},
      {'hindi': 'चंद्रमा', 'santhali': 'ᱪᱟᱸᱫᱚ'},
      {'hindi': 'तारा', 'santhali': 'ᱥᱮᱛᱟᱨ'},
      {'hindi': 'नदी', 'santhali': 'ᱜᱟᱹᱫᱟ'},
      {'hindi': 'तालाब', 'santhali': 'ᱵᱟᱹᱱᱟ'},
      {'hindi': 'पहाड़', 'santhali': 'ᱵᱩᱨᱩ'},
      {'hindi': 'गाँव', 'santhali': 'ᱜᱟᱶ'},
      {'hindi': 'बाजार', 'santhali': 'ᱦᱟᱹᱴ'},
      {'hindi': 'रास्ता', 'santhali': 'ᱦᱚᱨ'},
    ],
  };

  // ============================================================
  // OL CHIKI VARNAMALA
  // ============================================================

  final List<Map<String, String>> _varnamala = [
    {'hindi': 'अ', 'santhali': 'ᱚ'},
    {'hindi': 'आ', 'santhali': 'ᱟ'},
    {'hindi': 'इ', 'santhali': 'ᱤ'},
    {'hindi': 'ई', 'santhali': 'ᱤ'},
    {'hindi': 'उ', 'santhali': 'ᱩ'},
    {'hindi': 'ऊ', 'santhali': 'ᱩ'},
    {'hindi': 'ए', 'santhali': 'ᱮ'},
    {'hindi': 'ऐ', 'santhali': 'ᱮ'},
    {'hindi': 'ओ', 'santhali': 'ᱚ'},
    {'hindi': 'औ', 'santhali': 'ᱚ'},
    {'hindi': 'क', 'santhali': 'ᱠ'},
    {'hindi': 'ख', 'santhali': 'ᱠᱷ'},
    {'hindi': 'ग', 'santhali': 'ᱜ'},
    {'hindi': 'घ', 'santhali': 'ᱜᱷ'},
    {'hindi': 'ङ', 'santhali': 'ᱝ'},
    {'hindi': 'च', 'santhali': 'ᱪ'},
    {'hindi': 'छ', 'santhali': 'ᱫᱷ'},
    {'hindi': 'ज', 'santhali': 'ᱡ'},
    {'hindi': 'झ', 'santhali': 'ᱡᱷ'},
    {'hindi': 'ञ', 'santhali': 'ᱧ'},
    {'hindi': 'ट', 'santhali': 'ᱴ'},
    {'hindi': 'ठ', 'santhali': 'ᱴᱷ'},
    {'hindi': 'ड', 'santhali': 'ᱰ'},
    {'hindi': 'ढ', 'santhali': 'ᱰᱷ'},
    {'hindi': 'ण', 'santhali': 'ᱬ'},
    {'hindi': 'त', 'santhali': 'ᱛ'},
    {'hindi': 'थ', 'santhali': 'ᱛᱷ'},
    {'hindi': 'द', 'santhali': 'ᱫ'},
    {'hindi': 'ध', 'santhali': 'ᱫᱷ'},
    {'hindi': 'न', 'santhali': 'ᱱ'},
    {'hindi': 'प', 'santhali': 'ᱯ'},
    {'hindi': 'फ', 'santhali': 'ᱯᱷ'},
    {'hindi': 'ब', 'santhali': 'ᱵ'},
    {'hindi': 'भ', 'santhali': 'ᱵᱷ'},
    {'hindi': 'म', 'santhali': 'ᱢ'},
    {'hindi': 'य', 'santhali': 'ᱭ'},
    {'hindi': 'र', 'santhali': 'ᱨ'},
    {'hindi': 'ल', 'santhali': 'ᱞ'},
    {'hindi': 'व', 'santhali': 'ᱣ'},
    {'hindi': 'श', 'santhali': 'ᱥ'},
    {'hindi': 'ष', 'santhali': 'ᱥ'},
    {'hindi': 'स', 'santhali': 'ᱥ'},
    {'hindi': 'ह', 'santhali': 'ᱦ'},
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadVocabulary();

    _flutterTts.setSpeechRate(0.45);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
  }

  // ============================================================
  // SHUFFLE VOCABULARY
  // ============================================================

  void _loadVocabulary() {
    final words = List<Map<String, String>>.from(
      _gradeVocabulary[_selectedGrade] ?? [],
    );

    words.shuffle(_random);

    setState(() {
      _vocabulary = words;
    });
  }

  // ============================================================
  // CHANGE GRADE
  // ============================================================

  void _changeGrade(int? grade) {
    if (grade == null) return;

    setState(() {
      _selectedGrade = grade;
    });

    _loadVocabulary();
  }

  // ============================================================
  // TEXT TO SPEECH
  // ============================================================

  Future<void> _speakHindi(String text) async {
    await _flutterTts.stop();

    await _flutterTts.setLanguage('hi-IN');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    await _flutterTts.speak(text);
  }

  Future<void> _speakSanthali(String text) async {
    await _flutterTts.stop();

    try {
      await _flutterTts.setLanguage('sat-IN');

      // Slower speed for Santhali
      await _flutterTts.setSpeechRate(0.25);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      await _flutterTts.speak(text);
    } catch (_) {
      // Fallback if Santhali TTS is unavailable
      await _flutterTts.setLanguage('hi-IN');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      await _flutterTts.speak(text);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Vocabulary & Varnamala',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildGradeSelector(),
            _buildTabs(),
            Expanded(
              child: _selectedTab == 0
                  ? _buildVarnamala()
                  : _buildVocabulary(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GRADE SELECTOR
  // ============================================================

  Widget _buildGradeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.green.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.cardMint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Select Grade',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedGrade,
                borderRadius: BorderRadius.circular(14),
                items: const [
                  DropdownMenuItem(
                    value: 1,
                    child: Text('Grade 1'),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text('Grade 2'),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text('Grade 3'),
                  ),
                ],
                onChanged: _changeGrade,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Container(
        height: 95,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.green.withOpacity(0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                title: 'वर्णमाला',
                icon: Icons.translate_rounded,
                index: 0,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                title: 'शब्दावली',
                icon: Icons.menu_book_rounded,
                index: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAB BUTTON
  // ============================================================

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final selected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green
              : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 25,
              color: selected
                  ? Colors.white
                  : AppColors.textMuted,
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: selected
                    ? Colors.white
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VARNAMALA
  // ============================================================

  Widget _buildVarnamala() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            14,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'वर्णमाला',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Hindi → Ol Chiki',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_varnamala.length} letters',
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              20,
              6,
              20,
              28,
            ),
            itemCount: _varnamala.length,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 18,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              final item = _varnamala[index];

              return _buildLetterCard(
                hindi: item['hindi']!,
                santhali: item['santhali']!,
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LETTER CARD
  // ============================================================

  Widget _buildLetterCard({
    required String hindi,
    required String santhali,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.green.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Text(
                  hindi,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  santhali,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          _buildSpeakerButton(
            onHindiTap: () => _speakHindi(hindi),
            onSanthaliTap: () =>
                _speakSanthali(santhali),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VOCABULARY
  // ============================================================

  Widget _buildVocabulary() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            12,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'शब्दावली',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Hindi ↔ Santhali',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _loadVocabulary,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardMint,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shuffle_rounded,
                        size: 19,
                        color: AppColors.green,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Shuffle',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              20,
              6,
              20,
              24,
            ),
            itemCount: _vocabulary.length,
            itemBuilder: (context, index) {
              final item = _vocabulary[index];

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 14,
                ),
                child: _buildVocabularyCard(
                  number: index + 1,
                  hindi: item['hindi']!,
                  santhali: item['santhali']!,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VOCABULARY CARD
  // ============================================================

  Widget _buildVocabularyCard({
    required int number,
    required String hindi,
    required String santhali,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.green.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildWordColumn(
                    title: 'हिंदी',
                    word: hindi,
                    color: AppColors.textDark,
                  ),
                ),

                Container(
                  width: 1,
                  height: 52,
                  color: AppColors.divider,
                ),

                Expanded(
                  child: _buildWordColumn(
                    title: 'Santhali',
                    word: santhali,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          _buildSpeakerButton(
            onHindiTap: () => _speakHindi(hindi),
            onSanthaliTap: () =>
                _speakSanthali(santhali),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WORD COLUMN
  // ============================================================

  Widget _buildWordColumn({
    required String title,
    required String word,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            word,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SPEAKER BUTTON
  // ============================================================

  Widget _buildSpeakerButton({
    required VoidCallback onHindiTap,
    required VoidCallback onSanthaliTap,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'Listen',

      onSelected: (value) {
        if (value == 'hindi') {
          onHindiTap();
        } else {
          onSanthaliTap();
        }
      },

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: 'hindi',
            child: Row(
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.green,
                ),
                SizedBox(width: 10),
                Text('Listen Hindi'),
              ],
            ),
          ),

          PopupMenuItem(
            value: 'santhali',
            child: Row(
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.green,
                ),
                SizedBox(width: 10),
                Text('Listen Santhali'),
              ],
            ),
          ),
        ];
      },

      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(
          Icons.volume_up_rounded,
          color: Colors.white,
          size: 21,
        ),
      ),
    );
  }
}