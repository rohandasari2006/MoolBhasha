import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Result of local syllabus PDF processing.
class PdfProcessingResult {
  final String documentName;
  final List<String> topics;
  final List<String> concepts;
  final List<String> learningObjectives;
  final bool hadSelectableText;

  const PdfProcessingResult({
    required this.documentName,
    required this.topics,
    required this.concepts,
    required this.learningObjectives,
    required this.hadSelectableText,
  });

  Map<String, dynamic> toJson() => {
        'document_name': documentName,
        'topics': topics,
        'concepts': concepts,
        'learning_objectives': learningObjectives,
      };

  static const empty = PdfProcessingResult(
    documentName: '',
    topics: [],
    concepts: [],
    learningObjectives: [],
    hadSelectableText: false,
  );
}

/// Abstraction point for a future offline OCR engine. Scanned/image-only
/// PDFs are NOT sent to any cloud OCR service — instead this interface can
/// be implemented later by an on-device OCR model without touching the
/// rest of the pipeline. It is intentionally NOT wired up as a mandatory
/// dependency in v1.
abstract class OfflineOcrEngine {
  Future<String> extractText(File pdfFile);
}

/// Reads a local syllabus PDF entirely on-device: text extraction,
/// cleaning, then lightweight heading/topic/concept identification.
/// Loaded lazily — only instantiated when the user selects a PDF.
class PdfProcessor {
  final OfflineOcrEngine? ocrEngine; // null in v1 — see class doc above

  PdfProcessor({this.ocrEngine});

  Future<PdfProcessingResult> process(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final rawText = extractor.extractText();
      document.dispose();

      final hasSelectableText = rawText.trim().isNotEmpty;

      if (!hasSelectableText) {
        if (ocrEngine == null) {
          // No OCR wired up in v1 — return an empty-but-valid result so the
          // caller can fall back to NIPUN-only generation, never crash and
          // never call a cloud OCR service.
          return PdfProcessingResult(
            documentName: _fileName(pdfFile.path),
            topics: const [],
            concepts: const [],
            learningObjectives: const [],
            hadSelectableText: false,
          );
        }
        final ocrText = await ocrEngine!.extractText(pdfFile);
        return _fromCleanedText(pdfFile.path, ocrText, hadSelectableText: false);
      }

      return _fromCleanedText(pdfFile.path, rawText, hadSelectableText: true);
    } catch (_) {
      document.dispose();
      // PDF parsing failure — degrade gracefully, never crash, no online
      // fallback (see spec sections 35 / 45).
      return PdfProcessingResult(
        documentName: _fileName(pdfFile.path),
        topics: const [],
        concepts: const [],
        learningObjectives: const [],
        hadSelectableText: false,
      );
    }
  }

  PdfProcessingResult _fromCleanedText(
    String path,
    String rawText, {
    required bool hadSelectableText,
  }) {
    final cleaned = _cleanText(rawText);
    final lines = cleaned.split('\n').where((l) => l.trim().isNotEmpty).toList();

    final headings = _identifyHeadings(lines);
    final topics = _identifyTopics(headings, lines);
    final concepts = _identifyConcepts(lines);
    final objectives = _identifyLearningObjectives(lines);

    return PdfProcessingResult(
      documentName: _fileName(path),
      topics: topics,
      concepts: concepts,
      learningObjectives: objectives,
      hadSelectableText: hadSelectableText,
    );
  }

  String _cleanText(String raw) {
    return raw
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Heuristic: short lines (<= 6 words), no trailing punctuation, often
  /// capitalized or numbered — treated as headings/topics. Kept simple and
  /// deterministic so it runs cheaply on low-end CPUs.
  List<String> _identifyHeadings(List<String> lines) {
    return lines.where((line) {
      final words = line.trim().split(RegExp(r'\s+'));
      final endsWithSentencePunct = RegExp(r'[.!?।]$').hasMatch(line.trim());
      return words.length <= 6 && !endsWithSentencePunct;
    }).toList();
  }

  List<String> _identifyTopics(List<String> headings, List<String> lines) {
    final topics = <String>{};
    for (final h in headings) {
      final cleaned = h.replaceAll(RegExp(r'^[\d.\)\s-]+'), '').trim();
      if (cleaned.isNotEmpty) topics.add(cleaned);
    }
    return topics.take(30).toList();
  }

  List<String> _identifyConcepts(List<String> lines) {
    // Very lightweight keyword frequency — no NLP model, deterministic.
    final freq = <String, int>{};
    for (final line in lines) {
      for (final word in line.split(RegExp(r'\s+'))) {
        final w = word.trim();
        if (w.length < 3) continue;
        freq[w] = (freq[w] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(20).map((e) => e.key).toList();
  }

  List<String> _identifyLearningObjectives(List<String> lines) {
    return lines
        .where((l) =>
            l.contains('सीखेंगे') ||
            l.contains('उद्देश्य') ||
            l.toLowerCase().contains('objective') ||
            l.toLowerCase().contains('learning outcome'))
        .take(20)
        .toList();
  }

  String _fileName(String path) => path.split(Platform.pathSeparator).last;
}
