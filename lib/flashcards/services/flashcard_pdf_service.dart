import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

// import '../../worksheet_generator/models/enums.dart' show Grade, Domain;
import '../../worksheet_generation/models/enums.dart';
import '../models/flashcard.dart';
import '../models/flashcard_topic.dart';

/// Renders a set of [Flashcard]s to a printable A4 PDF: 4 cards per page in
/// a 2x2 grid with cut lines, Hindi + Santali text and an optional local
/// image. Genuine PDF text (not a screenshot) — reuses the same bundled
/// Devanagari/Ol Chiki fonts as WorksheetPdfService.
class FlashcardPdfService {
  pw.Font? _devanagariRegular;
  pw.Font? _devanagariBold;
  pw.Font? _olChikiRegular;

  Future<void> _ensureFontsLoaded() async {
    _devanagariRegular ??= await _loadFont('assets/fonts/NotoSansDevanagari-Regular.ttf');
    // No bold ttf was supplied with this asset drop — degrade to regular
    // weight instead of throwing on a bundled file that doesn't exist.
    _devanagariBold ??= await _loadFont('assets/fonts/NotoSansDevanagari-Bold.ttf')
        .catchError((_) => _devanagariRegular!);
    _olChikiRegular ??= await _loadFont('assets/fonts/NotoSansOlChiki-Regular.ttf');
  }

  Future<pw.Font> _loadFont(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return pw.Font.ttf(data);
  }

  Future<File> exportToFile({
    required List<Flashcard> cards,
    required Grade grade,
    required Domain domain,
    FlashcardTopic? topic,
  }) async {
    if (cards.isEmpty) {
      throw FlashcardPdfExportException('No flashcards to export.');
    }
    try {
      await _ensureFontsLoaded();
      final doc = await _buildDocument(cards);

      final dir = await getApplicationDocumentsDirectory();
      final topicPart = topic != null ? '_${topic.assetKey}' : '';
      final fileName =
          'MoolBhasha_${grade.label.replaceAll(' ', '')}_${domain.assetKey}$topicPart.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await doc.save());
      return file;
    } catch (e) {
      throw FlashcardPdfExportException('Failed to export flashcard PDF: $e');
    }
  }

  Future<pw.Document> _buildDocument(List<Flashcard> cards) async {
    final doc = pw.Document();
    final hindiStyle = pw.TextStyle(font: _devanagariRegular, fontSize: 14);
    final hindiBoldStyle = pw.TextStyle(
        font: _devanagariBold, fontSize: 16, fontWeight: pw.FontWeight.bold);
    final santaliStyle = pw.TextStyle(font: _olChikiRegular, fontSize: 13);

    // Images are loaded once up front (not per-page-build) so a missing or
    // corrupt asset never fails mid-render — a card just falls back to
    // text-only, it never blocks the rest of the export.
    final images = <String, pw.MemoryImage>{};
    for (final card in cards) {
      final path = card.imageAsset;
      if (path == null || images.containsKey(path)) continue;
      try {
        final data = await rootBundle.load(path);
        images[path] = pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {
        // Asset not bundled yet — degrade to text-only for this card.
      }
    }

    for (var pageStart = 0; pageStart < cards.length; pageStart += 4) {
      final pageCards = cards.skip(pageStart).take(4).toList();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (context) => pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            children: [
              for (final card in pageCards)
                _buildCard(
                  card,
                  hindiStyle,
                  hindiBoldStyle,
                  santaliStyle,
                  image: card.imageAsset != null ? images[card.imageAsset] : null,
                ),
            ],
          ),
        ),
      );
    }
    return doc;
  }

  pw.Widget _buildCard(
    Flashcard card,
    pw.TextStyle hindiStyle,
    pw.TextStyle hindiBoldStyle,
    pw.TextStyle santaliStyle, {
    pw.MemoryImage? image,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.75, style: pw.BorderStyle.dashed),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (image != null) ...[
            pw.SizedBox(height: 48, child: pw.Image(image, fit: pw.BoxFit.contain)),
            pw.SizedBox(height: 6),
          ],
          pw.Text(card.word.hindi, style: hindiBoldStyle, textAlign: pw.TextAlign.center),
          if (card.word.santali != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(card.word.santali!, style: santaliStyle, textAlign: pw.TextAlign.center),
          ],
          if (card.description != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(card.description!.hindi, style: hindiStyle, textAlign: pw.TextAlign.center),
            if (card.description!.santali != null)
              pw.Text(card.description!.santali!,
                  style: santaliStyle, textAlign: pw.TextAlign.center),
          ],
        ],
      ),
    );
  }
}

class FlashcardPdfExportException implements Exception {
  final String message;
  FlashcardPdfExportException(this.message);
  @override
  String toString() => message;
}
