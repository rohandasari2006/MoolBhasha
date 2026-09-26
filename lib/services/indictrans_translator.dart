import 'indictrans_onnx.dart';
import 'indictrans_tokenizer.dart';

class IndicTransTranslator {
  // ============================================================
  // COMPONENTS
  // ============================================================

  final IndicTransTokenizer tokenizer =
  IndicTransTokenizer();

  final IndicTransOnnx onnx =
  IndicTransOnnx();

  // ============================================================
  // STATE
  // ============================================================

  bool _initialized = false;

  Future<void>? _initializationFuture;

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int maxLength = 64;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (_initializationFuture != null) {
      return _initializationFuture!;
    }

    _initializationFuture =
        _initializeInternal();

    try {
      await _initializationFuture!;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<void> _initializeInternal() async {
    if (_initialized) {
      return;
    }

    try {
      print('==========================================');
      print('MOOLBHASHA INDIC TRANS INITIALIZATION');
      print('==========================================');

      // ========================================================
      // TOKENIZER
      // ========================================================

      print(
        'Initializing tokenizer...',
      );

      await tokenizer.initialize();

      print(
        'Tokenizer initialized.',
      );

      // ========================================================
      // ONNX
      // ========================================================

      print(
        'Initializing ONNX models...',
      );

      await onnx.initialize();

      print(
        'ONNX models initialized.',
      );

      _initialized = true;

      print('==========================================');
      print('INDIC TRANS READY');
      print('==========================================');
    } catch (e, stackTrace) {
      print('==========================================');
      print(
        'INDIC TRANS INITIALIZATION FAILED',
      );
      print('==========================================');

      print(
        'ERROR: $e',
      );

      print(
        stackTrace,
      );

      _initialized = false;

      rethrow;
    }
  }

  // ============================================================
  // TRANSLATE
  // ============================================================

  Future<String> translate({
    required String text,
    String sourceLanguage = 'hin_Deva',
    String targetLanguage = 'sat_Olck',
  }) async {
    await initialize();

    if (text.trim().isEmpty) {
      return '';
    }

    print('==========================================');
    print('MOOLBHASHA TEXT TRANSLATION');
    print('==========================================');

    print(
      'Source language: $sourceLanguage',
    );

    print(
      'Target language: $targetLanguage',
    );

    print(
      'Input text: $text',
    );

    // ==========================================================
    // 1. TOKENIZER
    // ==========================================================

    final encoded =
    await tokenizer.encodeSource(
      text: text,
      sourceLanguage:
      sourceLanguage,
      targetLanguage:
      targetLanguage,
    );

    final sourceIds =
        encoded.inputIds;

    final sourceAttentionMask =
        encoded.attentionMask;

    print('------------------------------------------');

    print(
      'Source IDs: $sourceIds',
    );

    print(
      'Source mask: '
          '$sourceAttentionMask',
    );

    // ==========================================================
    // 2. ENCODER
    // ==========================================================

    final encoderHiddenStates =
    await onnx.runEncoder(
      inputIds: sourceIds,
      attentionMask:
      sourceAttentionMask,
    );

    print(
      'Encoder completed.',
    );

    try {
      // ========================================================
      // 3. DECODER
      // ========================================================
      //
      // Start with:
      //
      // [decoderStartId]
      //
      // Then:
      //
      // [decoderStartId, token1]
      //
      // Then:
      //
      // [decoderStartId, token1, token2]
      //
      // etc.
      //
      // No KV cache is used.
      //
      // ========================================================

      final generatedIds =
      <int>[];

      final decoderInputIds =
      <int>[
        tokenizer.decoderStartId,
      ];

      while (
      generatedIds.length <
          maxLength) {
        print('------------------------------------------');

        print(
          'Decoder input: '
              '$decoderInputIds',
        );

        // ======================================================
        // RUN DECODER
        // ======================================================

        final nextToken =
        await onnx.runDecoderFullSequence(
          decoderInputIds:
          decoderInputIds,
          sourceAttentionMask:
          sourceAttentionMask,
          encoderHiddenStates:
          encoderHiddenStates,
        );

        print(
          'Generated token: '
              '$nextToken',
        );

        // ======================================================
        // EOS
        // ======================================================

        if (nextToken ==
            tokenizer.eosId) {
          print(
            'EOS reached.',
          );

          break;
        }

        // ======================================================
        // SAVE GENERATED TOKEN
        // ======================================================

        generatedIds.add(
          nextToken,
        );

        // ======================================================
        // ADD TO NEXT DECODER INPUT
        // ======================================================

        decoderInputIds.add(
          nextToken,
        );
      }

      // ========================================================
      // 4. DETOKENIZE
      // ========================================================

      print('==========================================');
      print(
        'FINAL SANTALI TOKEN IDS',
      );

      print(
        generatedIds,
      );

      print('==========================================');

      final translatedText =
      tokenizer.decodeTarget(
        generatedIds,
      );

      // ========================================================
      // 5. RESULT
      // ========================================================

      print('==========================================');
      print(
        'TRANSLATION RESULT',
      );
      print('==========================================');

      print(
        'Hindi: $text',
      );

      print(
        'Santali: '
            '$translatedText',
      );

      print('==========================================');

      return translatedText;
    } finally {
      // ========================================================
      // RELEASE ENCODER OUTPUT
      // ========================================================

      try {
        await encoderHiddenStates.dispose();
      } catch (_) {}
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    try {
      await onnx.dispose();
    } catch (_) {}

    tokenizer.dispose();

    _initialized = false;
    _initializationFuture = null;
  }
}