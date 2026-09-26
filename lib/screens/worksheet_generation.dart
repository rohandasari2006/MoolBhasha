import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sih_2026/screens/worksheet_preview_screen.dart';

import '../worksheet_generation/controllers/worksheet_controller.dart';
import '../worksheet_generation/models/enums.dart';
import '../worksheet_generation/utils/moolbhasha_theme.dart';
import '../worksheet_generation/widgets/generate_worksheet_button.dart';
import '../worksheet_generation/widgets/moolbhasha_dropdown_field.dart';
import '../worksheet_generation/widgets/pdf_upload_card.dart';
import '../screens/worksheet_preview_screen.dart';

class WorksheetGeneratorScreen extends ConsumerWidget {
  const WorksheetGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(worksheetFormProvider);
    final formController =
    ref.read(worksheetFormProvider.notifier);

    final generation =
    ref.watch(worksheetGenerationProvider);

    final generationController =
    ref.read(worksheetGenerationProvider.notifier);

    final isLoading =
        generation.status == GenerationStatus.processingPdf ||
            generation.status == GenerationStatus.generating ||
            generation.status == GenerationStatus.translating;

    ref.listen<WorksheetGenerationState>(
      worksheetGenerationProvider,
          (previous, next) {
        if (next.status == GenerationStatus.done &&
            next.worksheet != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
              const WorksheetPreviewScreen(),
            ),
          );
        }

        if (next.status == GenerationStatus.error &&
            next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: MoolBhashaTheme.cream,
      appBar: AppBar(
        backgroundColor: MoolBhashaTheme.cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: MoolBhashaTheme.textPrimary,
          ),
        ),
        title: const Text(
          'Worksheet Generator',
          style: TextStyle(
            color: MoolBhashaTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Worksheet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: MoolBhashaTheme.darkGreen,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Create a worksheet based on grade, '
                    'question type and syllabus.',
                style: TextStyle(
                  fontSize: 14,
                  color: MoolBhashaTheme.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // ---------------------------
              // FORM CARD
              // ---------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: MoolBhashaTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Worksheet Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color:
                        MoolBhashaTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Grade
                    MoolBhashaDropdownField<Grade>(
                      label: 'Grade',
                      value: form.grade,
                      options: const [
                        Grade.grade1,
                        Grade.grade2,
                        Grade.grade3,
                      ],
                      labelBuilder: (value) =>
                      value.label,
                      onChanged:
                      formController.setGrade,
                    ),

                    // Worksheet type
                    MoolBhashaDropdownField<
                        WorksheetType>(
                      label: 'Worksheet Type',
                      value: form.worksheetType,
                      options: WorksheetType.values,
                      labelBuilder: (value) =>
                      value.label,
                      onChanged:
                      formController
                          .setWorksheetType,
                    ),

                    // Question count
                    MoolBhashaDropdownField<int>(
                      label: 'Number of Questions',
                      value: form.questionCount,
                      options:
                      kAllowedQuestionCounts,
                      labelBuilder: (value) =>
                          value.toString(),
                      onChanged:
                      formController
                          .setQuestionCount,
                    ),

                    // Question type
                    MoolBhashaDropdownField<
                        QuestionType>(
                      label: 'Question Type',
                      value: form.questionType,
                      options: QuestionType.values,
                      labelBuilder: (value) =>
                      value.label,
                      onChanged:
                      formController
                          .setQuestionType,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------------------------
              // PDF
              // ---------------------------

              PdfUploadCard(
                selectedFile: form.selectedPdf,
                onFileSelected:
                formController.setPdf,
                onClear: form.selectedPdf == null
                    ? null
                    : formController.clearPdf,
              ),

              const SizedBox(height: 24),

              // ---------------------------
              // GENERATE
              // ---------------------------

              GenerateWorksheetButton(
                isLoading: isLoading,
                onPressed: () async {
                  await _generateWorksheet(
                    context: context,
                    ref: ref,
                  );
                },
              ),

              if (isLoading) ...[
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    _statusText(
                      generation.status,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color:
                      MoolBhashaTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateWorksheet({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final form =
    ref.read(worksheetFormProvider);

    final controller =
    ref.read(
      worksheetGenerationProvider.notifier,
    );

    // PDF is optional according to the controller.
    // If you want PDF to be mandatory, uncomment:
    //
    // if (form.selectedPdf == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text(
    //         'Please upload the syllabus PDF first.',
    //       ),
    //     ),
    //   );
    //   return;
    // }

    await controller.generate(form);
  }

  String _statusText(GenerationStatus status) {
    switch (status) {
      case GenerationStatus.processingPdf:
        return 'Reading syllabus...';

      case GenerationStatus.generating:
        return 'Generating questions...';

      case GenerationStatus.translating:
        return 'Translating to Santali...';

      case GenerationStatus.done:
        return 'Worksheet ready';

      case GenerationStatus.error:
        return 'Generation failed';

      case GenerationStatus.idle:
        return '';
    }
  }
}