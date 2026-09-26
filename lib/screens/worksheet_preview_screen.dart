import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../worksheet_generation/controllers/worksheet_controller.dart';
import '../worksheet_generation/models/question.dart';
import '../worksheet_generation/services/worksheet_builder.dart';
import '../worksheet_generation/utils/moolbhasha_theme.dart';

class WorksheetPreviewScreen extends ConsumerWidget {
  const WorksheetPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generation = ref.watch(worksheetGenerationProvider);
    final controller = ref.read(worksheetGenerationProvider.notifier);
    final worksheet = generation.worksheet;

    return Scaffold(
      backgroundColor: MoolBhashaTheme.cream,
      appBar: AppBar(
        backgroundColor: MoolBhashaTheme.cream,
        elevation: 0,
        title: const Text(
          'Worksheet Preview',
          style: TextStyle(
            color: MoolBhashaTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: worksheet == null
          ? const Center(child: Text('No worksheet generated yet.'))
          : Column(
              children: [
                if (generation.translationOutcome != TranslationOutcome.success)
                  _TranslationBanner(outcome: generation.translationOutcome),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: worksheet.questions.length,
                    itemBuilder: (context, index) => _QuestionPreviewCard(
                      index: index + 1,
                      question: worksheet.questions[index],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MoolBhashaTheme.darkGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MoolBhashaTheme.buttonRadius,
                            ),
                          ),
                        ),
                        onPressed: () async {
                          final savedLocation =
                          await controller.exportCurrentWorksheetToPdf();

                          if (savedLocation != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'PDF saved to Downloads',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Export as PDF',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TranslationBanner extends StatelessWidget {
  final TranslationOutcome? outcome;
  const _TranslationBanner({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final message = switch (outcome) {
      TranslationOutcome.unavailable =>
        'Santali translation could not be completed on this device. '
            'Showing Hindi content only.',
      TranslationOutcome.partial =>
        'Some questions could not be translated to Santali.',
      _ => '',
    };
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF7A5B00), fontSize: 13),
      ),
    );
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  final int index;
  final Question question;
  const _QuestionPreviewCard({required this.index, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: MoolBhashaTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${question.instruction.hindi}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (question.instruction.santali != null)
            Text(
              question.instruction.santali!,
              style: const TextStyle(color: MoolBhashaTheme.textSecondary),
            ),
          const SizedBox(height: 6),
          ..._buildBody(),
        ],
      ),
    );
  }

  List<Widget> _buildBody() {
    if (question is McqQuestion) {
      final q = question as McqQuestion;
      return [
        Text(q.question.hindi),
        if (q.question.santali != null)
          Text(
            q.question.santali!,
            style: const TextStyle(color: MoolBhashaTheme.textSecondary),
          ),
        const SizedBox(height: 6),
        ...q.options.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${o.id}. ${o.text.hindi}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (o.text.santali != null)
                  Text(
                    o.text.santali!,
                    style: const TextStyle(
                      color: MoolBhashaTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ];
    } else if (question is FillBlankQuestion) {
      final q = question as FillBlankQuestion;
      return [Text(q.question.hindi)];
    } else if (question is TrueFalseQuestion) {
      final q = question as TrueFalseQuestion;
      return [Text(q.statement.hindi)];
    } else if (question is ShortAnswerQuestion) {
      final q = question as ShortAnswerQuestion;
      return [Text(q.question.hindi)];
    } else if (question is MatchFollowingQuestion) {
      final q = question as MatchFollowingQuestion;
      return [
        const Text(
          'Match the Following',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 8),

        ...q.left.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          final right = index < q.right.length ? q.right[index] : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.text.hindi),
                      if (item.text.santali != null)
                        Text(
                          item.text.santali!,
                          style: const TextStyle(
                            color: MoolBhashaTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (right != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(right.text.hindi),
                        if (right.text.santali != null)
                          Text(
                            right.text.santali!,
                            style: const TextStyle(
                              color: MoolBhashaTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),
      ];
    }
    return const [];
  }
}
