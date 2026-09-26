import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
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
          'About MoolBhasha',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            children: [
              // ------------------------------------------------
              // APP LOGO / HEADER
              // ------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 82,
                      width: 82,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.translate_rounded,
                        size: 44,
                        color: AppColors.green,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'MoolBhasha',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Connecting Languages • Empowering Learning',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // ABOUT
              // ------------------------------------------------
              _buildSectionCard(
                icon: Icons.info_outline_rounded,
                title: 'About the App',
                child: const Text(
                  'MoolBhasha is a learning and language-support application '
                      'designed to help bridge the communication gap between '
                      'mainstream languages and tribal languages.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // MAIN PURPOSE
              // ------------------------------------------------
              _buildSectionCard(
                icon: Icons.translate_rounded,
                title: 'Our Purpose',
                child: const Text(
                  'The main purpose of MoolBhasha is to support tribal '
                      'language translation and make learning more accessible '
                      'for tribal children. The app provides language-learning '
                      'resources that can help teachers explain concepts and '
                      'communicate with students in their familiar language.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // FOR TEACHERS
              // ------------------------------------------------
              _buildSectionCard(
                icon: Icons.school_rounded,
                title: 'For Teachers',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MoolBhasha can assist teachers in:',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBullet(
                      'Understanding and translating tribal languages',
                    ),
                    _buildBullet(
                      'Explaining learning material in a familiar language',
                    ),
                    _buildBullet(
                      'Teaching basic vocabulary and alphabets',
                    ),
                    _buildBullet(
                      'Supporting classroom communication',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // FOR CHILDREN
              // ------------------------------------------------
              _buildSectionCard(
                icon: Icons.child_care_rounded,
                title: 'For Tribal Children',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The app is designed to make language learning '
                          'simple, familiar and engaging.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBullet(
                      'Learn Hindi and tribal languages together',
                    ),
                    _buildBullet(
                      'Learn vocabulary and Varnamala',
                    ),
                    _buildBullet(
                      'Listen to word pronunciations',
                    ),
                    _buildBullet(
                      'Learn through simple and accessible content',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // LANGUAGE SUPPORT
              // ------------------------------------------------
              _buildSectionCard(
                icon: Icons.language_rounded,
                title: 'Language Support',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildLanguageChip('Hindi'),
                    _buildLanguageChip('Santhali'),
                    _buildLanguageChip('Mundari'),
                    _buildLanguageChip('Ho'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // VISION
              // ------------------------------------------------
              _buildSectionCard(
                icon: Icons.lightbulb_outline_rounded,
                title: 'Our Vision',
                child: const Text(
                  'To use technology to preserve, support and promote '
                      'tribal languages while helping teachers provide '
                      'better learning experiences for tribal children.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'MoolBhasha',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Language • Learning • Inclusion',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.green.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.cardMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.green,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // BULLET
  // ============================================================

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.circle,
              size: 7,
              color: AppColors.green,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LANGUAGE CHIP
  // ============================================================

  Widget _buildLanguageChip(String language) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardMint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        language,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.green,
        ),
      ),
    );
  }
}