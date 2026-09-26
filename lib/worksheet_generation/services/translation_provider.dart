import 'dart:async';

/// Thrown when the local translation model cannot be used (missing files,
/// failed load, insufficient memory). There is NO online fallback — callers
/// must handle this by reporting that bilingual generation could not be
/// completed (spec sections 35 & 45).
class TranslationUnavailableException implements Exception {
  final String reason;
  TranslationUnavailableException(this.reason);
  @override
  String toString() => 'TranslationUnavailableException: $reason';
}

abstract class TranslationProvider {
  /// True once the model is loaded and ready for inference.
  bool get isReady;

  /// Loads the model lazily. Safe to call multiple times (idempotent).
  Future<void> ensureLoaded();

  /// Releases model resources from memory. Called after a worksheet's
  /// translation pass completes, or when memory pressure is detected.
  Future<void> release();

  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  });
}

// The old `IndicTrans2LocalProvider` that used to live here was a single-
// file INT8 combined-model placeholder whose `_createOnnxSession`/
// `_tokenize`/etc. were all `UnimplementedError` stubs — it could never
// actually translate. It has been removed. The real implementation is
// `SanthaliMtOnnxProvider` in `santali_mt_onnx_provider.dart`, which uses
// the SanthaliMT export's separate encoder + two-stage (initial /
// with-past KV-cache) decoder instead of one combined model. Update any
// import of the old class to that file.
