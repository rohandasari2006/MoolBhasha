import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';

class IndicTransEncoded {
  final List<int> inputIds;
  final List<int> attentionMask;

  const IndicTransEncoded({
    required this.inputIds,
    required this.attentionMask,
  });
}

class IndicTransTokenizer {
  SentencePieceTokenizer? _srcTokenizer;
  SentencePieceTokenizer? _tgtTokenizer;

  Map<String, int> _srcVocab = {};
  Map<String, int> _tgtVocab = {};

  Map<int, String> _tgtReverseVocab = {};

  int _unkId = 0;
  int _padId = 1;
  int _eosId = 2;
  int _bosId = 0;

  /*
   * IndicTrans2:
   *
   * bos_token_id = 0
   * decoder_start_token_id = 2
   *
   * These are NOT necessarily the same.
   */
  int _decoderStartId = 2;

  bool _initialized = false;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isInitialized => _initialized;

  int get padId => _padId;

  int get eosId => _eosId;

  int get bosId => _bosId;

  int get decoderStartId => _decoderStartId;

  int get unkId => _unkId;

  // ============================================================
  // INITIALIZE TOKENIZER
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    print('==========================================');
    print('INITIALIZING INDIC TRANS TOKENIZER');
    print('==========================================');

    // ----------------------------------------------------------
    // SOURCE SENTENCEPIECE
    // ----------------------------------------------------------

    print('Loading model.SRC...');

    final srcModelData = await rootBundle.load(
      'assets/Models/model.SRC',
    );

    _srcTokenizer =
    await SentencePieceTokenizer.fromBytes(
      srcModelData.buffer.asUint8List(),
    );

    print('model.SRC loaded.');

    // ----------------------------------------------------------
    // TARGET SENTENCEPIECE
    // ----------------------------------------------------------

    print('Loading model.TGT...');

    final tgtModelData = await rootBundle.load(
      'assets/Models/model.TGT',
    );

    _tgtTokenizer =
    await SentencePieceTokenizer.fromBytes(
      tgtModelData.buffer.asUint8List(),
    );

    print('model.TGT loaded.');

    // ----------------------------------------------------------
    // SOURCE DICTIONARY
    // ----------------------------------------------------------

    print('Loading dict.SRC.json...');

    final srcDictString =
    await rootBundle.loadString(
      'assets/Models/dict.SRC.json',
    );

    // ----------------------------------------------------------
    // TARGET DICTIONARY
    // ----------------------------------------------------------

    print('Loading dict.TGT.json...');

    final tgtDictString =
    await rootBundle.loadString(
      'assets/Models/dict.TGT.json',
    );

    final dynamic srcJson =
    jsonDecode(srcDictString);

    final dynamic tgtJson =
    jsonDecode(tgtDictString);

    _srcVocab =
        _convertVocabulary(srcJson);

    _tgtVocab =
        _convertVocabulary(tgtJson);

    _tgtReverseVocab = {
      for (final entry in _tgtVocab.entries)
        entry.value: entry.key,
    };

    // ----------------------------------------------------------
    // SPECIAL TOKENS
    // ----------------------------------------------------------

    if (_srcVocab.containsKey('<unk>')) {
      _unkId = _srcVocab['<unk>']!;
    }

    if (_srcVocab.containsKey('<pad>')) {
      _padId = _srcVocab['<pad>']!;
    }

    if (_srcVocab.containsKey('</s>')) {
      _eosId = _srcVocab['</s>']!;
    }

    if (_srcVocab.containsKey('<s>')) {
      _bosId = _srcVocab['<s>']!;
    } else {
      _bosId = 0;
    }

    /*
     * Your Python model uses:
     *
     * DECODER_START_ID = 2
     *
     * Therefore keep it separate from BOS.
     */
    _decoderStartId = 2;

    // ----------------------------------------------------------
    // DEBUG
    // ----------------------------------------------------------

    print('========== INDIC TRANS TOKENIZER ==========');

    print(
      'hin_Deva -> '
          '${_srcVocab['hin_Deva']}',
    );

    print(
      'sat_Olck -> '
          '${_srcVocab['sat_Olck']}',
    );

    print(
      '<s> -> '
          '${_srcVocab['<s>']}',
    );

    print(
      '<pad> -> '
          '${_srcVocab['<pad>']}',
    );

    print(
      '</s> -> '
          '${_srcVocab['</s>']}',
    );

    print(
      '<unk> -> '
          '${_srcVocab['<unk>']}',
    );

    print('BOS ID: $_bosId');
    print('Decoder Start ID: $_decoderStartId');
    print('EOS ID: $_eosId');
    print('PAD ID: $_padId');

    print(
      'SRC vocab size: '
          '${_srcVocab.length}',
    );

    print(
      'TGT vocab size: '
          '${_tgtVocab.length}',
    );

    print('==========================================');

    _initialized = true;
  }

  // ============================================================
  // CONVERT JSON VOCABULARY
  // ============================================================

  Map<String, int> _convertVocabulary(
      dynamic json,
      ) {
    final result = <String, int>{};

    if (json is Map<String, dynamic>) {
      for (final entry in json.entries) {
        final value = entry.value;

        if (value is int) {
          result[entry.key] = value;
        } else if (value is num) {
          result[entry.key] = value.toInt();
        }
      }
    }

    return result;
  }

  // ============================================================
  // LANGUAGE ID
  // ============================================================

  int languageId(
      String languageTag,
      ) {
    if (!_initialized) {
      throw StateError(
        'Tokenizer must be initialized first.',
      );
    }

    final id =
    _srcVocab[languageTag];

    if (id == null) {
      throw StateError(
        'Unknown language tag: $languageTag',
      );
    }

    return id;
  }

  // ============================================================
  // ENCODE SOURCE
  // ============================================================

  Future<IndicTransEncoded> encodeSource({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    await initialize();

    if (_srcTokenizer == null) {
      throw StateError(
        'Source tokenizer is not initialized.',
      );
    }

    final tokenizer =
    _srcTokenizer!;

    // ----------------------------------------------------------
    // SENTENCEPIECE
    // ----------------------------------------------------------

    final encoded =
    tokenizer.encode(text);

    final pieces =
        encoded.tokens;

    print('==========================================');
    print('SOURCE TOKENIZATION');
    print('==========================================');

    print('SOURCE TEXT: $text');

    print(
      'SOURCE PIECES: $pieces',
    );

    // ----------------------------------------------------------
    // LANGUAGE IDS
    // ----------------------------------------------------------

    final sourceLanguageId =
    _srcVocab[sourceLanguage];

    final targetLanguageId =
    _srcVocab[targetLanguage];

    if (sourceLanguageId == null) {
      throw StateError(
        'Unknown source language: '
            '$sourceLanguage',
      );
    }

    if (targetLanguageId == null) {
      throw StateError(
        'Unknown target language: '
            '$targetLanguage',
      );
    }

    // ----------------------------------------------------------
    // BUILD SOURCE IDS
    //
    // Keep the same format as your Python test:
    //
    // [source language]
    // [target language]
    // [sentence pieces]
    // [EOS]
    // ----------------------------------------------------------

    final ids = <int>[
      sourceLanguageId,
      targetLanguageId,
    ];

    for (final piece in pieces) {
      final id =
      _srcVocab[piece];

      if (id != null) {
        ids.add(id);
      } else {
        ids.add(_unkId);
      }
    }

    ids.add(_eosId);

    final attentionMask =
    List<int>.filled(
      ids.length,
      1,
    );

    print(
      'SOURCE LANGUAGE ID: '
          '$sourceLanguageId',
    );

    print(
      'TARGET LANGUAGE ID: '
          '$targetLanguageId',
    );

    print(
      'SOURCE IDS: $ids',
    );

    print(
      'SOURCE LENGTH: '
          '${ids.length}',
    );

    print('==========================================');

    return IndicTransEncoded(
      inputIds: ids,
      attentionMask: attentionMask,
    );
  }

  // ============================================================
  // TARGET ENCODING
  // ============================================================

  List<int> encodeTargetText(
      String text,
      ) {
    if (_tgtTokenizer == null) {
      throw StateError(
        'Tokenizer is not initialized.',
      );
    }

    final encoded =
    _tgtTokenizer!.encode(text);

    final pieces =
        encoded.tokens;

    final ids = <int>[];

    for (final piece in pieces) {
      ids.add(
        _tgtVocab[piece] ??
            _unkId,
      );
    }

    return ids;
  }

  // ============================================================
  // DECODE TARGET
  // ============================================================

  String decodeTarget(
      List<int> ids,
      ) {
    if (_tgtTokenizer == null) {
      throw StateError(
        'Target tokenizer is not initialized.',
      );
    }

    final pieces = <String>[];

    print('==========================================');
    print('TARGET DECODING');
    print('==========================================');

    print(
      'Generated IDs: $ids',
    );

    for (final id in ids) {
      // --------------------------------------------------------
      // SPECIAL TOKENS
      // --------------------------------------------------------

      if (id == _eosId ||
          id == _padId ||
          id == _bosId ||
          id == _decoderStartId) {
        continue;
      }

      final piece =
      _tgtReverseVocab[id];

      print(
        'ID $id -> '
            '${piece ?? "NOT FOUND"}',
      );

      if (piece != null) {
        pieces.add(piece);
      }
    }

    print(
      'Target pieces: $pieces',
    );

    /*
     * Do not use the source tokenizer here.
     *
     * Target vocabulary IDs are converted back to
     * target SentencePiece pieces using dict.TGT.json.
     */

    final result = pieces
        .join()
        .replaceAll(
      '▁',
      ' ',
    )
        .trim();

    print(
      'Decoded result: $result',
    );

    print('==========================================');

    return result;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _srcTokenizer = null;
    _tgtTokenizer = null;

    _srcVocab.clear();
    _tgtVocab.clear();
    _tgtReverseVocab.clear();

    _initialized = false;
  }
}