import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../utils/moolbhasha_theme.dart';

/// "Syllabus / Upload Syllabus PDF / Choose PDF" card from the reference
/// screenshots. Only handles local file selection via file_picker — never
/// uploads anywhere. Parsing happens later in PdfProcessor, off the UI
/// thread's concern.
class PdfUploadCard extends StatelessWidget {
  final File? selectedFile;
  final ValueChanged<File> onFileSelected;
  final VoidCallback? onClear;

  const PdfUploadCard({
    super.key,
    required this.selectedFile,
    required this.onFileSelected,
    this.onClear,
  });

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false, // stream from disk locally, avoid duplicate in-memory copy
    );
    if (result != null && result.files.single.path != null) {
      onFileSelected(File(result.files.single.path!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: MoolBhashaTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Syllabus',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MoolBhashaTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: MoolBhashaTheme.fieldBackground,
              borderRadius: BorderRadius.circular(MoolBhashaTheme.fieldRadius),
              border: Border.all(color: MoolBhashaTheme.divider),
            ),
            child: Column(
              children: [
                const Icon(Icons.picture_as_pdf_outlined,
                    size: 32, color: MoolBhashaTheme.mediumGreen),
                const SizedBox(height: 10),
                Text(
                  selectedFile != null
                      ? selectedFile!.path.split(Platform.pathSeparator).last
                      : 'Upload Syllabus PDF',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: MoolBhashaTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap to select your syllabus PDF',
                  style: TextStyle(fontSize: 12, color: MoolBhashaTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _pickPdf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MoolBhashaTheme.darkGreen,
                    side: const BorderSide(color: MoolBhashaTheme.mediumGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MoolBhashaTheme.fieldRadius),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Choose PDF'),
                ),
                if (selectedFile != null && onClear != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Remove PDF',
                        style: TextStyle(color: MoolBhashaTheme.textSecondary)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
