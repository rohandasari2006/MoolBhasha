import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/worksheet.dart';
import '../repositories/content_bank_repository.dart';
import '../repositories/nipun_repository.dart';
import '../repositories/template_repository.dart';
import '../services/pdf_processor.dart';
import '../services/question_planner.dart';
import '../services/santali_mt_onnx_provider.dart';
import '../services/translation_provider.dart';
import '../services/worksheet_builder.dart';
import '../services/worksheet_pdf_service.dart';

/// ===============================================================
/// WORKSHEET FORM STATE
/// ===============================================================

class WorksheetFormState {
  final Grade grade;
  final WorksheetType worksheetType;
  final int questionCount;
  final QuestionType questionType;
  final File? selectedPdf;

  const WorksheetFormState({
    this.grade = Grade.grade1,
    this.worksheetType = WorksheetType.practice,
    this.questionCount = 10,
    this.questionType = QuestionType.mixed,
    this.selectedPdf,
  });

  WorksheetFormState copyWith({
    Grade? grade,
    WorksheetType? worksheetType,
    int? questionCount,
    QuestionType? questionType,
    File? selectedPdf,
    bool clearPdf = false,
  }) {
    return WorksheetFormState(
      grade: grade ?? this.grade,
      worksheetType: worksheetType ?? this.worksheetType,
      questionCount: questionCount ?? this.questionCount,
      questionType: questionType ?? this.questionType,
      selectedPdf: clearPdf
          ? null
          : (selectedPdf ?? this.selectedPdf),
    );
  }
}

/// ===============================================================
/// GENERATION STATUS
/// ===============================================================

enum GenerationStatus {
  idle,
  processingPdf,
  generating,
  translating,
  done,
  error,
}

/// ===============================================================
/// WORKSHEET GENERATION STATE
/// ===============================================================

class WorksheetGenerationState {
  final GenerationStatus status;
  final Worksheet? worksheet;
  final TranslationOutcome? translationOutcome;
  final String? errorMessage;

  const WorksheetGenerationState({
    this.status = GenerationStatus.idle,
    this.worksheet,
    this.translationOutcome,
    this.errorMessage,
  });

  WorksheetGenerationState copyWith({
    GenerationStatus? status,
    Worksheet? worksheet,
    TranslationOutcome? translationOutcome,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WorksheetGenerationState(
      status: status ?? this.status,
      worksheet: worksheet ?? this.worksheet,
      translationOutcome:
      translationOutcome ?? this.translationOutcome,
      errorMessage: clearError
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

/// ===============================================================
/// FORM PROVIDER
/// ===============================================================

final worksheetFormProvider =
StateNotifierProvider<
    WorksheetFormController,
    WorksheetFormState>(
      (ref) => WorksheetFormController(),
);

/// ===============================================================
/// FORM CONTROLLER
/// ===============================================================

class WorksheetFormController
    extends StateNotifier<WorksheetFormState> {
  WorksheetFormController()
      : super(const WorksheetFormState());

  /// Set grade
  void setGrade(Grade grade) {
    state = state.copyWith(
      grade: grade,
    );
  }

  /// Set worksheet type
  void setWorksheetType(
      WorksheetType type,
      ) {
    state = state.copyWith(
      worksheetType: type,
    );
  }

  /// Set number of questions
  void setQuestionCount(
      int count,
      ) {
    if (!kAllowedQuestionCounts.contains(count)) {
      return;
    }

    state = state.copyWith(
      questionCount: count,
    );
  }

  /// Set question type
  void setQuestionType(
      QuestionType type,
      ) {
    state = state.copyWith(
      questionType: type,
    );
  }

  /// Set PDF
  void setPdf(File file) {
    state = state.copyWith(
      selectedPdf: file,
    );
  }

  /// Clear PDF
  void clearPdf() {
    state = state.copyWith(
      clearPdf: true,
    );
  }

  /// Set the complete form at once.
  void setForm({
    required Grade grade,
    required WorksheetType worksheetType,
    required int questionCount,
    required QuestionType questionType,
    File? selectedPdf,
  }) {
    state = WorksheetFormState(
      grade: grade,
      worksheetType: worksheetType,
      questionCount: questionCount,
      questionType: questionType,
      selectedPdf: selectedPdf,
    );
  }

  /// Reset everything
  void reset() {
    state = const WorksheetFormState();
  }
}

/// ===============================================================
/// GENERATION PROVIDER
/// ===============================================================

final worksheetGenerationProvider =
StateNotifierProvider<
    WorksheetGenerationController,
    WorksheetGenerationState>(
      (ref) => WorksheetGenerationController(),
);

/// ===============================================================
/// GENERATION CONTROLLER
/// ===============================================================

class WorksheetGenerationController
    extends StateNotifier<WorksheetGenerationState> {
  WorksheetGenerationController()
      : super(const WorksheetGenerationState());

  // =============================================================
  // REPOSITORIES
  // =============================================================

  final _nipunRepo = NipunRepository();

  final _contentBankRepo =
  ContentBankRepository();

  final _templateRepo =
  TemplateRepository();

  // =============================================================
  // QUESTION PLANNER
  // =============================================================

  late final _planner = QuestionPlanner(
    nipunRepository: _nipunRepo,
    contentBankRepository: _contentBankRepo,
    templateRepository: _templateRepo,
  );

  // =============================================================
  // TRANSLATION PROVIDER
  // =============================================================

  final TranslationProvider
  _translationProvider =
  SanthaliMtOnnxProvider();

  // =============================================================
  // PDF PROCESSOR
  // =============================================================

  final _pdfProcessor = PdfProcessor();

  // =============================================================
  // PDF EXPORT SERVICE
  // =============================================================

  final _pdfExportService =
  WorksheetPdfService();

  // =============================================================
  // GENERATE WORKSHEET
  // =============================================================

  Future<void> generate(
      WorksheetFormState form,
      ) async {
    try {
      state = const WorksheetGenerationState(
        status: GenerationStatus.processingPdf,
      );

      PdfProcessingResult? pdfResult;

      if (form.selectedPdf != null) {
        pdfResult = await _pdfProcessor.process(
          form.selectedPdf!,
        );
      }

      state = state.copyWith(
        status: GenerationStatus.generating,
      );

      final builder = WorksheetBuilder(
        planner: _planner,
        translationProvider:
        _translationProvider,
      );

      state = state.copyWith(
        status: GenerationStatus.translating,
      );

      final result = await builder.generate(
        grade: form.grade,
        worksheetType: form.worksheetType,
        requestedType: form.questionType,
        questionCount: form.questionCount,
        pdfResult: pdfResult,
      );

      state = WorksheetGenerationState(
        status: GenerationStatus.done,
        worksheet: result.worksheet,
        translationOutcome:
        result.translationOutcome,
      );
    } catch (e) {
      state = WorksheetGenerationState(
        status: GenerationStatus.error,
        errorMessage: _friendlyErrorMessage(e),
      );
    }
  }
  // =============================================================
  // EXPORT WORKSHEET TO PDF
  // =============================================================

  Future<String?> exportCurrentWorksheetToPdf() async {
    final worksheet = state.worksheet;

    if (worksheet == null) {
      return null;
    }

    try {
      return await _pdfExportService.exportToFile(
        worksheet,
      );
    } on WorksheetPdfExportException catch (e) {
      state = state.copyWith(
        status: GenerationStatus.error,
        errorMessage: e.message,
      );

      return null;
    }
  }

  // =============================================================
  // FRIENDLY ERROR
  // =============================================================

  String _friendlyErrorMessage(
      Object error,
      ) {
    if (error
    is TranslationUnavailableException) {
      return 'The Hindi–Santali translation model '
          'could not be loaded on this device. '
          'Your worksheet could not be completed '
          'in both languages. Please free up memory '
          'and try again.';
    }

    return 'Something went wrong while generating '
        'the worksheet. Please try again.';
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _translationProvider.release();
    super.dispose();
  }
}