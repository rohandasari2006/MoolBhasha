import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';

import '../models/enums.dart';
import 'translation_provider.dart';

/// On-device Hindi (hin_Deva) -> Santali (sat_Olck)
///
/// Uses three ONNX models:
///
///   encoder_model.onnx
///   decoder_initial.onnx
///   decoder_with_past.onnx
///
/// Assets:
///
/// assets/models/SanthaliMT/
///   encoder_model.onnx
///   decoder_initial.onnx
///   decoder_with_past.onnx
///   config.json
///   generation_config.json
///   special_tokens_map.json
///   tokenizer_config.json
///   dict.SRC.json
///   dict.TGT.json
///   model.SRC
///   model.TGT
///
class SanthaliMtOnnxProvider implements TranslationProvider {
  static const String _modelDir =
      'assets/Models';

  static const String _encoderPath =
      '$_modelDir/encoder_model.onnx';

  static const String _decoderInitialPath =
      '$_modelDir/decoder_initial.onnx';

  static const String _decoderWithPastPath =
      '$_modelDir/decoder_with_past.onnx';

  static const String _configPath =
      '$_modelDir/config.json';

  static const String _generationConfigPath =
      '$_modelDir/generation_config.json';

  static const String _specialTokensPath =
      '$_modelDir/special_tokens_map.json';

  static const String _tokenizerConfigPath =
      '$_modelDir/tokenizer_config.json';

  static const String _dictSrcPath =
      '$_modelDir/dict.SRC.json';

  static const String _dictTgtPath =
      '$_modelDir/dict.TGT.json';

  static const String _spmSrcPath =
      '$_modelDir/model.SRC';

  static const String _spmTgtPath =
      '$_modelDir/model.TGT';

  static const int _maxNewTokens = 128;

  // -----------------------------------------------------------------------
  // ONNX Runtime
  // -----------------------------------------------------------------------

  final OnnxRuntime _ort = OnnxRuntime();

  OrtSession? _encoderSession;
  OrtSession? _decoderInitialSession;
  OrtSession? _decoderWithPastSession;

  // -----------------------------------------------------------------------
  // Tokenizers
  // -----------------------------------------------------------------------

  SentencePieceTokenizer? _spmSrc;
  SentencePieceTokenizer? _spmTgt;

  // -----------------------------------------------------------------------
  // Vocabulary
  // -----------------------------------------------------------------------

  Map<String, int>? _dictSrc;
  Map<int, String>? _dictTgtInv;

  // -----------------------------------------------------------------------
  // Special token IDs
  // -----------------------------------------------------------------------

  int _bosId = 0;
  int _eosId = 2;
  int _padId = 1;
  int _decoderStartId = 2;

  String? _srcLangTag;
  String? _tgtLangTag;

  int _numLayers = 0;

  bool _loaded = false;

  // -----------------------------------------------------------------------
  // KV cache
  // -----------------------------------------------------------------------

  final Map<String, OrtValue> _pastCache = {};

  List<String> _pastInputNames = [];

  // -----------------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------------

  @override
  bool get isReady => _loaded;

  // -----------------------------------------------------------------------
  // LOAD MODEL
  // -----------------------------------------------------------------------

  @override
  Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }

    try {
      // ---------------------------------------------------------------
      // Load encoder
      // ---------------------------------------------------------------

      _encoderSession =
      await _ort.createSessionFromAsset(
        _encoderPath,
      );

      // ---------------------------------------------------------------
      // Load initial decoder
      // ---------------------------------------------------------------

      _decoderInitialSession =
      await _ort.createSessionFromAsset(
        _decoderInitialPath,
      );

      // ---------------------------------------------------------------
      // Load decoder with past
      // ---------------------------------------------------------------

      _decoderWithPastSession =
      await _ort.createSessionFromAsset(
        _decoderWithPastPath,
      );

      // ---------------------------------------------------------------
      // Read config
      // ---------------------------------------------------------------

      final config =
      await _loadJson(_configPath);

      _numLayers =
      (config['decoder_layers'] ??
          config['num_hidden_layers'] ??
          config['n_layer'] ??
          6)
      as int;

      // ---------------------------------------------------------------
      // Generation config
      // ---------------------------------------------------------------

      final generationConfig =
      await _loadJson(
        _generationConfigPath,
      );

      _bosId =
      (generationConfig['bos_token_id'] ??
          _bosId)
      as int;

      _eosId =
      (generationConfig['eos_token_id'] ??
          _eosId)
      as int;

      _padId =
      (generationConfig['pad_token_id'] ??
          _padId)
      as int;

      _decoderStartId =
      (generationConfig[
      'decoder_start_token_id'] ??
          _decoderStartId)
      as int;

      // ---------------------------------------------------------------
      // Tokenizer config
      // ---------------------------------------------------------------

      final tokenizerConfig =
      await _loadJson(
        _tokenizerConfigPath,
      );

      _srcLangTag =
          tokenizerConfig['src_lang']
          as String? ??
              kSourceLang;

      _tgtLangTag =
          tokenizerConfig['tgt_lang']
          as String? ??
              kTargetLang;

      // ---------------------------------------------------------------
      // Source vocabulary
      // ---------------------------------------------------------------

      _dictSrc =
      Map<String, int>.from(
        await _loadJson(_dictSrcPath),
      );

      // ---------------------------------------------------------------
      // Target vocabulary
      // ---------------------------------------------------------------

      final dictTgt =
      Map<String, int>.from(
        await _loadJson(_dictTgtPath),
      );

      _dictTgtInv = {
        for (final entry in dictTgt.entries)
          entry.value: entry.key,
      };

      // ---------------------------------------------------------------
      // SentencePiece source model
      // ---------------------------------------------------------------

      final srcModelBytes =
      await _loadAssetBytes(
        _spmSrcPath,
      );

      _spmSrc =
          SentencePieceTokenizer.fromBytes(
            srcModelBytes,
          );

      // ---------------------------------------------------------------
      // SentencePiece target model
      // ---------------------------------------------------------------

      final tgtModelBytes =
      await _loadAssetBytes(
        _spmTgtPath,
      );

      _spmTgt =
          SentencePieceTokenizer.fromBytes(
            tgtModelBytes,
          );

      // ---------------------------------------------------------------
      // Detect decoder cache inputs
      // ---------------------------------------------------------------

      _pastInputNames =
          _decoderWithPastSession!.inputNames
              .where(
                (name) =>
            name.contains('past') ||
                name.contains('cache'),
          )
              .toList();

      // ---------------------------------------------------------------
      // Print model information
      // ---------------------------------------------------------------

      print(
        'SanthaliMT loaded successfully',
      );

      print(
        'Encoder inputs: '
            '${_encoderSession!.inputNames}',
      );

      print(
        'Encoder outputs: '
            '${_encoderSession!.outputNames}',
      );

      print(
        'Initial decoder inputs: '
            '${_decoderInitialSession!.inputNames}',
      );

      print(
        'Initial decoder outputs: '
            '${_decoderInitialSession!.outputNames}',
      );

      print(
        'Past decoder inputs: '
            '${_decoderWithPastSession!.inputNames}',
      );

      print(
        'Past decoder outputs: '
            '${_decoderWithPastSession!.outputNames}',
      );

      _loaded = true;
    } catch (e) {
      await release();

      throw TranslationUnavailableException(
        'Failed to load local SanthaliMT model: $e',
      );
    }
  }

  // -----------------------------------------------------------------------
  // RELEASE
  // -----------------------------------------------------------------------

  @override
  Future<void> release() async {
    for (final tensor in _pastCache.values) {
      await tensor.dispose();
    }

    _pastCache.clear();

    _pastInputNames.clear();

    if (_encoderSession != null) {
      await _encoderSession!.close();
    }

    if (_decoderInitialSession != null) {
      await _decoderInitialSession!.close();
    }

    if (_decoderWithPastSession != null) {
      await _decoderWithPastSession!.close();
    }

    _encoderSession = null;
    _decoderInitialSession = null;
    _decoderWithPastSession = null;

    _spmSrc = null;
    _spmTgt = null;

    _dictSrc = null;
    _dictTgtInv = null;

    _loaded = false;
  }

  // -----------------------------------------------------------------------
  // TRANSLATE
  // -----------------------------------------------------------------------

  @override
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (!_loaded) {
      throw TranslationUnavailableException(
        'Translation model has not been loaded.',
      );
    }

    if (text.trim().isEmpty) {
      return '';
    }

    if (sourceLanguage != kSourceLang ||
        targetLanguage != kTargetLang) {
      throw TranslationUnavailableException(
        'SanthaliMtOnnxProvider supports only '
            '$kSourceLang -> $kTargetLang.',
      );
    }

    try {
      // ---------------------------------------------------------------
      // Hindi text -> source IDs
      // ---------------------------------------------------------------

      final inputIds =
      _encodeSource(text);

      // ---------------------------------------------------------------
      // Encoder
      // ---------------------------------------------------------------

      final encoderResult =
      await _runEncoder(inputIds);

      // ---------------------------------------------------------------
      // Decoder
      // ---------------------------------------------------------------

      final outputIds =
      await _decodeGreedy(
        encoderResult.hiddenStates,
        encoderResult.attentionMask,
      );

      // ---------------------------------------------------------------
      // Target IDs -> Santali text
      // ---------------------------------------------------------------

      return _decodeTarget(outputIds);
    } catch (e, stackTrace) {
      print('================================================');
      print('SANTALI TRANSLATION ERROR');
      print('Input: $text');
      print('Source: $sourceLanguage');
      print('Target: $targetLanguage');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      print('================================================');

      throw TranslationUnavailableException(
        'Inference failed: $e',
      );
    }
  }

  // -----------------------------------------------------------------------
  // SOURCE TOKENIZATION
  // -----------------------------------------------------------------------

  List<int> _encodeSource(
      String text,
      ) {
    if (_spmSrc == null) {
      throw StateError(
        'Source tokenizer is not loaded.',
      );
    }

    if (_dictSrc == null) {
      throw StateError(
        'Source dictionary is not loaded.',
      );
    }

    final encoding =
    _spmSrc!.encode(
      text,
      addSpecialTokens: false,
    );

    final pieces = encoding.tokens;

    final ids = <int>[];

    // Source language tag
    if (_srcLangTag != null &&
        _dictSrc!.containsKey(
          _srcLangTag,
        )) {
      ids.add(
        _dictSrc![_srcLangTag]!,
      );
    }

    // SentencePiece pieces -> Fairseq dictionary IDs
    for (final piece in pieces) {
      ids.add(
        _dictSrc![piece] ??
            _dictSrc!['<unk>'] ??
            _bosId,
      );
    }

    // EOS
    ids.add(_eosId);

    return ids;
  }

  // -----------------------------------------------------------------------
  // TARGET DETOKENIZATION
  // -----------------------------------------------------------------------

  String _decodeTarget(
      List<int> ids,
      ) {
    if (_spmTgt == null) {
      throw StateError(
        'Target tokenizer is not loaded.',
      );
    }

    if (_dictTgtInv == null) {
      throw StateError(
        'Target dictionary is not loaded.',
      );
    }

    final pieces = <String>[];

    for (final id in ids) {
      if (id == _eosId ||
          id == _padId) {
        continue;
      }

      final token =
      _dictTgtInv![id];

      if (token == null) {
        continue;
      }

      if (token == _tgtLangTag) {
        continue;
      }

      pieces.add(token);
    }

    if (pieces.isEmpty) {
      throw StateError(
        'ONNX decoder produced no Santali tokens. '
            'Generated IDs: $ids',
      );
    }

    final targetIds =
    _spmTgt!.convertTokensToIds(
      pieces,
    );

    return _spmTgt!.decode(
      targetIds,
      skipSpecialTokens: true,
    ).trim();
  }

  // -----------------------------------------------------------------------
  // ENCODER
  // -----------------------------------------------------------------------

  Future<_EncoderResult> _runEncoder(
      List<int> inputIds,
      ) async {
    if (_encoderSession == null) {
      throw StateError(
        'Encoder session is not loaded.',
      );
    }

    final seqLength =
        inputIds.length;

    final inputTensor =
    await OrtValue.fromList(
      Int64List.fromList(
        inputIds,
      ),
      [1, seqLength],
    );

    final attentionMask =
    await OrtValue.fromList(
      Int64List.fromList(
        List.filled(
          seqLength,
          1,
        ),
      ),
      [1, seqLength],
    );

    // Your encoder expects decoder_input_ids.
    final decoderInputIds =
    await OrtValue.fromList(
      Int64List.fromList(
        [_decoderStartId],
      ),
      [1, 1],
    );

    final inputs =
    <String, OrtValue>{
      'input_ids': inputTensor,
      'attention_mask': attentionMask,
      'decoder_input_ids':
      decoderInputIds,
    };

    final outputs =
    await _encoderSession!.run(
      inputs,
    );

    await inputTensor.dispose();
    await attentionMask.dispose();
    await decoderInputIds.dispose();

    if (outputs.isEmpty) {
      throw StateError(
        'encoder_model.onnx returned no outputs.',
      );
    }

    final outputName =
    _findEncoderHiddenOutput(
      outputs,
    );

    final hiddenTensor =
    outputs[outputName];

    if (hiddenTensor == null) {
      throw StateError(
        'Encoder hidden state output not found.',
      );
    }

    final raw =
    await hiddenTensor.asList();

    final hiddenStates =
    _convertHiddenStates(raw);

    // Keep outputs only long enough to read them.
    for (final entry in outputs.entries) {
      if (entry.value != hiddenTensor) {
        await entry.value.dispose();
      }
    }

    await hiddenTensor.dispose();

    return _EncoderResult(
      hiddenStates: hiddenStates,
      attentionMask:
      List<int>.filled(
        seqLength,
        1,
      ),
    );
  }

  // -----------------------------------------------------------------------
  // FIND ENCODER OUTPUT
  // -----------------------------------------------------------------------

  String _findEncoderHiddenOutput(
      Map<String, OrtValue> outputs,
      ) {
    for (final name in outputs.keys) {
      final lower =
      name.toLowerCase();

      if (lower.contains(
        'encoder_hidden',
      ) ||
          lower.contains(
            'hidden_state',
          ) ||
          lower.contains(
            'last_hidden',
          )) {
        return name;
      }
    }

    // If the model only has one output,
    // use that.
    if (outputs.length == 1) {
      return outputs.keys.first;
    }

    // Otherwise use first output.
    return outputs.keys.first;
  }

  // -----------------------------------------------------------------------
  // CONVERT ENCODER HIDDEN STATE
  // -----------------------------------------------------------------------

  List<List<double>> _convertHiddenStates(
      List raw,
      ) {
    dynamic data = raw;

    // [1, seq, hidden]
    if (data is List &&
        data.length == 1) {
      data = data.first;
    }

    if (data is! List) {
      throw StateError(
        'Unexpected encoder output type: '
            '${data.runtimeType}',
      );
    }

    final result =
    <List<double>>[];

    for (final row in data) {
      if (row is! List) {
        continue;
      }

      result.add(
        row.map<double>(
              (value) =>
              (value as num).toDouble(),
        ).toList(),
      );
    }

    return result;
  }

  // -----------------------------------------------------------------------
  // GREEDY DECODING
  // -----------------------------------------------------------------------

  Future<List<int>> _decodeGreedy(
      List<List<double>> encoderHidden,
      List<int> encoderAttentionMask,
      ) async {
    await _clearPastCache();

    final generated =
    <int>[];

    // First decoder token
    var nextId =
    await _decoderInitialStep(
      encoderHidden,
      encoderAttentionMask,
    );

    generated.add(nextId);

    if (nextId == _eosId) {
      return generated;
    }

    for (var step = 1;
    step < _maxNewTokens;
    step++) {
      nextId =
      await _decoderWithPastStep(
        nextId,
        encoderHidden,
        encoderAttentionMask,
      );

      generated.add(nextId);

      if (nextId == _eosId) {
        break;
      }
    }

    return generated;
  }

  // -----------------------------------------------------------------------
  // INITIAL DECODER
  // -----------------------------------------------------------------------

  Future<int> _decoderInitialStep(
      List<List<double>> encoderHidden,
      List<int> encoderAttentionMask,
      ) async {
    if (_decoderInitialSession == null) {
      throw StateError(
        'Initial decoder session is not loaded.',
      );
    }

    final encoderHiddenTensor =
    await _encoderHiddenToTensor(
      encoderHidden,
    );

    final encoderAttentionTensor =
    await OrtValue.fromList(
      Int64List.fromList(
        encoderAttentionMask,
      ),
      [1, encoderAttentionMask.length],
    );

    final decoderInputIds =
    await OrtValue.fromList(
      Int64List.fromList(
        [_decoderStartId],
      ),
      [1, 1],
    );

    final decoderAttentionMask =
    await OrtValue.fromList(
      Int64List.fromList(
        [1],
      ),
      [1, 1],
    );

    final inputs =
    <String, OrtValue>{
      'decoder_input_ids':
      decoderInputIds,
      'decoder_attention_mask':
      decoderAttentionMask,
      'encoder_hidden_states':
      encoderHiddenTensor,
      'encoder_attention_mask':
      encoderAttentionTensor,
    };

    final outputs =
    await _decoderInitialSession!.run(
      inputs,
    );

    await decoderInputIds.dispose();
    await decoderAttentionMask.dispose();
    await encoderHiddenTensor.dispose();
    await encoderAttentionTensor.dispose();

    if (outputs.isEmpty) {
      throw StateError(
        'decoder_initial.onnx returned no outputs.',
      );
    }

    // ---------------------------------------------------------------
    // First output = logits
    // ---------------------------------------------------------------

    final logitsName =
        outputs.keys.first;

    final logitsTensor =
    outputs[logitsName];

    if (logitsTensor == null) {
      throw StateError(
        'Decoder logits output not found.',
      );
    }

    final rawLogits =
    await logitsTensor.asList();

    final nextId =
    _argmaxLastStep(
      rawLogits,
    );

    // ---------------------------------------------------------------
    // Save KV cache
    // ---------------------------------------------------------------

    await _clearPastCache();

    final outputNames =
    outputs.keys.toList();

    final cacheOutputNames =
    outputNames.skip(1).toList();

    _pastInputNames =
        _decoderWithPastSession!
            .inputNames
            .where(
              (name) =>
          name.contains('past') ||
              name.contains('cache'),
        )
            .toList();

    final count =
    cacheOutputNames.length <
        _pastInputNames.length
        ? cacheOutputNames.length
        : _pastInputNames.length;

    for (var i = 0; i < count; i++) {
      final outputName =
      cacheOutputNames[i];

      final inputName =
      _pastInputNames[i];

      final value =
      outputs[outputName];

      if (value != null) {
        _pastCache[inputName] =
            value;
      }
    }

    // Dispose only logits.
    await logitsTensor.dispose();

    return nextId;
  }

  // -----------------------------------------------------------------------
  // DECODER WITH PAST
  // -----------------------------------------------------------------------

  Future<int> _decoderWithPastStep(
      int lastToken,
      List<List<double>> encoderHidden,
      List<int> encoderAttentionMask,
      ) async {
    if (_decoderWithPastSession == null) {
      throw StateError(
        'Past decoder session is not loaded.',
      );
    }

    final encoderHiddenTensor =
    await _encoderHiddenToTensor(
      encoderHidden,
    );

    final encoderAttentionTensor =
    await OrtValue.fromList(
      Int64List.fromList(
        encoderAttentionMask,
      ),
      [1, encoderAttentionMask.length],
    );

    final decoderInputIds =
    await OrtValue.fromList(
      Int64List.fromList(
        [lastToken],
      ),
      [1, 1],
    );

    // The decoder-with-past receives
    // only the newest token.
    final decoderAttentionMask =
    await OrtValue.fromList(
      Int64List.fromList(
        [1],
      ),
      [1, 1],
    );

    final inputs =
    <String, OrtValue>{
      'decoder_input_ids':
      decoderInputIds,
      'decoder_attention_mask':
      decoderAttentionMask,
      'encoder_hidden_states':
      encoderHiddenTensor,
      'encoder_attention_mask':
      encoderAttentionTensor,
    };

    // ---------------------------------------------------------------
    // Add KV cache
    // ---------------------------------------------------------------

    for (final entry
    in _pastCache.entries) {
      inputs[entry.key] =
          entry.value;
    }

    final outputs =
    await _decoderWithPastSession!.run(
      inputs,
    );

    await decoderInputIds.dispose();
    await decoderAttentionMask.dispose();
    await encoderHiddenTensor.dispose();
    await encoderAttentionTensor.dispose();

    if (outputs.isEmpty) {
      throw StateError(
        'decoder_with_past.onnx returned no outputs.',
      );
    }

    // ---------------------------------------------------------------
    // Logits
    // ---------------------------------------------------------------

    final logitsName =
        outputs.keys.first;

    final logitsTensor =
    outputs[logitsName];

    if (logitsTensor == null) {
      throw StateError(
        'Decoder logits output not found.',
      );
    }

    final rawLogits =
    await logitsTensor.asList();

    final nextId =
    _argmaxLastStep(
      rawLogits,
    );

    // ---------------------------------------------------------------
    // Replace old cache
    // ---------------------------------------------------------------

    await _clearPastCache();

    final outputNames =
    outputs.keys.toList();

    final cacheOutputNames =
    outputNames.skip(1).toList();

    final currentPastInputNames =
    _decoderWithPastSession!
        .inputNames
        .where(
          (name) =>
      name.contains('past') ||
          name.contains('cache'),
    )
        .toList();

    final count =
    cacheOutputNames.length <
        currentPastInputNames.length
        ? cacheOutputNames.length
        : currentPastInputNames.length;

    for (var i = 0; i < count; i++) {
      final outputName =
      cacheOutputNames[i];

      final inputName =
      currentPastInputNames[i];

      final value =
      outputs[outputName];

      if (value != null) {
        _pastCache[inputName] =
            value;
      }
    }

    // Dispose logits only.
    await logitsTensor.dispose();

    return nextId;
  }

  // -----------------------------------------------------------------------
  // ENCODER HIDDEN -> ORT VALUE
  // -----------------------------------------------------------------------

  Future<OrtValue>
  _encoderHiddenToTensor(
      List<List<double>> encoderHidden,
      ) async {
    final seqLength =
        encoderHidden.length;

    final hiddenSize =
    encoderHidden.isEmpty
        ? 0
        : encoderHidden.first.length;

    final flat =
    Float32List(
      seqLength * hiddenSize,
    );

    for (var i = 0;
    i < seqLength;
    i++) {
      for (var j = 0;
      j < hiddenSize;
      j++) {
        flat[
        i * hiddenSize +
            j] =
        encoderHidden[i][j];
      }
    }

    return OrtValue.fromList(
      flat,
      [
        1,
        seqLength,
        hiddenSize,
      ],
    );
  }

  // -----------------------------------------------------------------------
  // ARGMAX
  // -----------------------------------------------------------------------

  int _argmaxLastStep(
      dynamic logits,
      ) {
    if (logits == null) {
      throw StateError(
        'Logits are null.',
      );
    }

    dynamic values =
        logits;

    // Remove batch dimension.
    //
    // [1, 1, vocab]
    //       ↓
    // [1, vocab]
    if (values is List &&
        values.length == 1) {
      values = values[0];
    }

    // Remove sequence dimension.
    //
    // [1, vocab]
    //       ↓
    // [vocab]
    if (values is List &&
        values.length == 1) {
      values = values[0];
    }

    if (values is! List) {
      throw StateError(
        'Unexpected logits format: '
            '${values.runtimeType}',
      );
    }

    var bestIndex = 0;

    var bestValue =
        double.negativeInfinity;

    for (var i = 0;
    i < values.length;
    i++) {
      final value =
      values[i];

      if (value is num) {
        final score =
        value.toDouble();

        if (score > bestValue) {
          bestValue = score;
          bestIndex = i;
        }
      }
    }

    if (bestValue ==
        double.negativeInfinity) {
      throw StateError(
        'No valid values found in logits.',
      );
    }

    return bestIndex;
  }

  // -----------------------------------------------------------------------
  // CLEAR KV CACHE
  // -----------------------------------------------------------------------

  Future<void>
  _clearPastCache() async {
    for (final tensor
    in _pastCache.values) {
      await tensor.dispose();
    }

    _pastCache.clear();
  }

  // -----------------------------------------------------------------------
  // ASSET LOADING
  // -----------------------------------------------------------------------

  Future<Uint8List>
  _loadAssetBytes(
      String path,
      ) async {
    final data =
    await rootBundle.load(
      path,
    );

    return data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
  }

  Future<Map<String, dynamic>>
  _loadJson(
      String path,
      ) async {
    final raw =
    await rootBundle.loadString(
      path,
    );

    return jsonDecode(raw)
    as Map<String, dynamic>;
  }
}

// ===========================================================================
// ENCODER RESULT
// ===========================================================================

class _EncoderResult {
  final List<List<double>>
  hiddenStates;

  final List<int>
  attentionMask;

  const _EncoderResult({
    required this.hiddenStates,
    required this.attentionMask,
  });
}