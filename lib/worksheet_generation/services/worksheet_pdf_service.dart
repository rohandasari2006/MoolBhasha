import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/question.dart';
import '../models/worksheet.dart';

/// Renders a Worksheet to a real, printable PDF.
///
/// Hindi uses Devanagari font.
/// Santali uses Ol Chiki font.
///
/// On Android, the PDF is saved to the public Downloads folder
/// using Android MediaStore through a MethodChannel.
class WorksheetPdfService {
  pw.Font? _devanagariRegular;
  pw.Font? _devanagariBold;
  pw.Font? _olChikiRegular;

  static const MethodChannel _downloadChannel =
  MethodChannel('moolbhasha/downloads');

  // ------------------------------------------------------------
  // FONT LOADING
  // ------------------------------------------------------------

  Future<void> _ensureFontsLoaded() async {
    _devanagariRegular ??= await _loadFont(
      'assets/fonts/NotoSansDevanagari-Regular.ttf',
    );

    // If Bold font is not available, use Regular font.
    if (_devanagariBold == null) {
      try {
        _devanagariBold = await _loadFont(
          'assets/fonts/NotoSansDevanagari-Bold.ttf',
        );
      } catch (_) {
        _devanagariBold = _devanagariRegular;
      }
    }

    _olChikiRegular ??= await _loadFont(
      'assets/fonts/NotoSansOlChiki-Regular.ttf',
    );
  }

  Future<pw.Font> _loadFont(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return pw.Font.ttf(data);
  }

  // ------------------------------------------------------------
  // PDF EXPORT
  // ------------------------------------------------------------

  /// Exports the worksheet PDF.
  ///
  /// Android:
  /// Saves the PDF into the public Download folder using
  /// Android MediaStore.
  ///
  /// Other platforms:
  /// Saves the PDF into the system temporary directory.
  Future<String> exportToFile(Worksheet worksheet) async {
    try {
      // Load Hindi + Santali fonts.
      await _ensureFontsLoaded();

      // Build PDF.
      final doc = _buildDocument(worksheet);

      // Generate PDF bytes.
      final bytes = await doc.save();

      // Generate file name.
      final shortId = worksheet.worksheetId.length >= 8
          ? worksheet.worksheetId.substring(0, 8)
          : worksheet.worksheetId;

      final fileName =
          'moolbhasha_worksheet_'
          '${worksheet.grade.assetKey}_'
          '$shortId.pdf';

      // --------------------------------------------------------
      // ANDROID
      // --------------------------------------------------------

      if (!kIsWeb && Platform.isAndroid) {
        final result =
        await _downloadChannel.invokeMethod<String>(
          'savePdfToDownloads',
          {
            'fileName': fileName,
            'bytes': bytes,
          },
        );

        if (result == null || result.isEmpty) {
          throw Exception(
            'Android did not return the saved PDF location.',
          );
        }

        return result;
      }

      // --------------------------------------------------------
      // NON-ANDROID FALLBACK
      // --------------------------------------------------------

      final tempDir = Directory.systemTemp;

      final file = File(
        '${tempDir.path}/$fileName',
      );

      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      throw WorksheetPdfExportException(
        'Failed to export worksheet PDF: $e',
      );
    }
  }

  // ------------------------------------------------------------
  // BUILD PDF DOCUMENT
  // ------------------------------------------------------------

  pw.Document _buildDocument(Worksheet worksheet) {
    final doc = pw.Document();

    final hindiStyle = pw.TextStyle(
      font: _devanagariRegular,
      fontSize: 12,
    );

    final hindiBoldStyle = pw.TextStyle(
      font: _devanagariBold,
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );

    final santaliStyle = pw.TextStyle(
      font: _olChikiRegular,
      fontSize: 12,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),

        // ------------------------------------------------------
        // HEADER
        // ------------------------------------------------------

        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MoolBhasha — '
                    '${worksheet.grade.label} · '
                    '${worksheet.worksheetType.assetKey}',
                style: hindiBoldStyle,
              ),
              pw.SizedBox(height: 4),
              pw.Divider(),
            ],
          );
        },

        // ------------------------------------------------------
        // FOOTER
        // ------------------------------------------------------

        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          );
        },

        // ------------------------------------------------------
        // QUESTIONS
        // ------------------------------------------------------

        build: (context) {
          return [
            for (var i = 0; i < worksheet.questions.length; i++)
              _buildQuestionBlock(
                index: i + 1,
                question: worksheet.questions[i],
                hindiStyle: hindiStyle,
                hindiBoldStyle: hindiBoldStyle,
                santaliStyle: santaliStyle,
              ),
          ];
        },
      ),
    );

    return doc;
  }

  // ------------------------------------------------------------
  // QUESTION BLOCK
  // ------------------------------------------------------------

  pw.Widget _buildQuestionBlock({
    required int index,
    required Question question,
    required pw.TextStyle hindiStyle,
    required pw.TextStyle hindiBoldStyle,
    required pw.TextStyle santaliStyle,
  }) {
    final children = <pw.Widget>[
      // Question number
      pw.Text(
        '$index.',
        style: hindiBoldStyle,
      ),

      pw.SizedBox(height: 2),

      // Instruction - Hindi
      pw.Text(
        question.instruction.hindi,
        style: hindiStyle,
      ),

      // Instruction - Santali
      if (question.instruction.santali != null &&
          question.instruction.santali!.trim().isNotEmpty)
        pw.Text(
          question.instruction.santali!,
          style: santaliStyle,
        ),

      pw.SizedBox(height: 4),
    ];

    // ----------------------------------------------------------
    // MCQ
    // ----------------------------------------------------------

    if (question is McqQuestion) {
      children.add(
        pw.Text(
          question.question.hindi,
          style: hindiStyle,
        ),
      );

      if (question.question.santali != null &&
          question.question.santali!.trim().isNotEmpty) {
        children.add(
          pw.Text(
            question.question.santali!,
            style: santaliStyle,
          ),
        );
      }

      for (final option in question.options) {
        final hindi = option.text.hindi;
        final santali = option.text.santali;

        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(
              left: 12,
              top: 2,
            ),
            child: pw.Text(
              santali != null && santali.trim().isNotEmpty
                  ? '${option.id}. $hindi / $santali'
                  : '${option.id}. $hindi',
              style: hindiStyle,
            ),
          ),
        );
      }
    }

    // ----------------------------------------------------------
    // FILL IN THE BLANK
    // ----------------------------------------------------------

    else if (question is FillBlankQuestion) {
      children.add(
        pw.Text(
          question.question.hindi,
          style: hindiStyle,
        ),
      );

      if (question.question.santali != null &&
          question.question.santali!.trim().isNotEmpty) {
        children.add(
          pw.Text(
            question.question.santali!,
            style: santaliStyle,
          ),
        );
      }

      children.add(
        pw.SizedBox(height: 18),
      );

      children.add(
        pw.Container(
          height: 0.5,
          color: PdfColors.grey400,
        ),
      );
    }

    // ----------------------------------------------------------
    // MATCH THE FOLLOWING
    // ----------------------------------------------------------

    else if (question is MatchFollowingQuestion) {
      children.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment:
                pw.CrossAxisAlignment.start,
                children: [
                  for (final item in question.left)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(
                        bottom: 6,
                      ),
                      child: pw.Column(
                        crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${item.id}. ${item.text.hindi}',
                            style: hindiStyle,
                          ),
                          if (item.text.santali != null &&
                              item.text.santali!
                                  .trim()
                                  .isNotEmpty)
                            pw.Text(
                              item.text.santali!,
                              style: santaliStyle,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            pw.SizedBox(width: 20),

            // RIGHT COLUMN
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment:
                pw.CrossAxisAlignment.start,
                children: [
                  for (final item in question.right)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(
                        bottom: 6,
                      ),
                      child: pw.Column(
                        crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${item.id}. ${item.text.hindi}',
                            style: hindiStyle,
                          ),
                          if (item.text.santali != null &&
                              item.text.santali!
                                  .trim()
                                  .isNotEmpty)
                            pw.Text(
                              item.text.santali!,
                              style: santaliStyle,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------------
    // TRUE / FALSE
    // ----------------------------------------------------------

    else if (question is TrueFalseQuestion) {
      children.add(
        pw.Text(
          question.statement.hindi,
          style: hindiStyle,
        ),
      );

      if (question.statement.santali != null &&
          question.statement.santali!.trim().isNotEmpty) {
        children.add(
          pw.Text(
            question.statement.santali!,
            style: santaliStyle,
          ),
        );
      }

      children.add(
        pw.SizedBox(height: 6),
      );

      children.add(
        pw.Text(
          '[ True / False ]',
          style: hindiStyle,
        ),
      );
    }

    // ----------------------------------------------------------
    // SHORT ANSWER
    // ----------------------------------------------------------

    else if (question is ShortAnswerQuestion) {
      children.add(
        pw.Text(
          question.question.hindi,
          style: hindiStyle,
        ),
      );

      if (question.question.santali != null &&
          question.question.santali!.trim().isNotEmpty) {
        children.add(
          pw.Text(
            question.question.santali!,
            style: santaliStyle,
          ),
        );
      }

      children.add(
        pw.SizedBox(height: 18),
      );

      children.add(
        pw.Container(
          height: 0.5,
          color: PdfColors.grey400,
        ),
      );
    }

    children.add(
      pw.SizedBox(height: 14),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }
}

// --------------------------------------------------------------
// EXPORT EXCEPTION
// --------------------------------------------------------------

class WorksheetPdfExportException implements Exception {
  final String message;

  WorksheetPdfExportException(this.message);

  @override
  String toString() => message;
}