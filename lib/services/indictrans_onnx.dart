import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

class IndicTransOnnx {
  // ============================================================
  // ONNX RUNTIME
  // ============================================================

  final OnnxRuntime _ort = OnnxRuntime();

  OrtSession? _encoder;
  OrtSession? _decoderInitial;

  bool _initialized = false;

  Future<void>? _initializationFuture;

  // ============================================================
  // MODEL CONSTANTS
  // ============================================================

  static const int vocabSize = 122672;

  // ============================================================
  // MODEL PATHS
  // ============================================================

  static const String _modelDirectory = 'assets/Models';

  static const String _encoderAsset =
      '$_modelDirectory/encoder_model.onnx';

  static const String _decoderInitialAsset =
      '$_modelDirectory/decoder_initial.onnx';

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isInitialized => _initialized;

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

    _initializationFuture = _initializeInternal();

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
      print('INDIC TRANS ONNX INITIALIZATION');
      print('==========================================');

      // ========================================================
      // COPY MODELS TO REAL FILESYSTEM
      // ========================================================

      print('Preparing ONNX model files...');

      final encoderPath = await _copyAssetToLocalFile(
        _encoderAsset,
        'encoder_model.onnx',
      );

      final decoderInitialPath =
      await _copyAssetToLocalFile(
        _decoderInitialAsset,
        'decoder_initial.onnx',
      );

      print(
        'Encoder local path: $encoderPath',
      );

      print(
        'Initial decoder local path: '
            '$decoderInitialPath',
      );

      // ========================================================
      // LOAD ENCODER
      // ========================================================

      print(
        'Loading encoder_model.onnx...',
      );

      _encoder = await _ort.createSession(
        encoderPath,
      );

      print(
        'Encoder loaded.',
      );

      print(
        'Encoder inputs: '
            '${_encoder!.inputNames}',
      );

      print(
        'Encoder outputs: '
            '${_encoder!.outputNames}',
      );

      // ========================================================
      // LOAD INITIAL DECODER
      // ========================================================

      print(
        'Loading decoder_initial.onnx...',
      );

      _decoderInitial =
      await _ort.createSession(
        decoderInitialPath,
      );

      print(
        'Initial decoder loaded.',
      );

      print(
        'Initial decoder inputs: '
            '${_decoderInitial!.inputNames}',
      );

      print(
        'Initial decoder outputs: '
            '${_decoderInitial!.outputNames}',
      );

      _initialized = true;

      print('==========================================');
      print('INDIC TRANS ONNX READY');
      print('==========================================');
    } catch (e, stackTrace) {
      print('==========================================');
      print('ONNX INITIALIZATION FAILED');
      print('==========================================');

      print(
        'ERROR: $e',
      );

      print(
        stackTrace,
      );

      await dispose();

      rethrow;
    }
  }

  // ============================================================
  // COPY FLUTTER ASSET TO REAL FILE
  // ============================================================

  Future<String> _copyAssetToLocalFile(
      String assetPath,
      String fileName,
      ) async {
    final directory =
    await getApplicationSupportDirectory();

    final modelDirectory = Directory(
      '${directory.path}/indictrans_models',
    );

    if (!await modelDirectory.exists()) {
      await modelDirectory.create(
        recursive: true,
      );
    }

    final file = File(
      '${modelDirectory.path}/$fileName',
    );

    // ==========================================================
    // FILE ALREADY EXISTS
    // ==========================================================

    if (await file.exists()) {
      final size = await file.length();

      if (size > 0) {
        print(
          'Model already exists: '
              '${file.path}',
        );

        return file.path;
      }

      await file.delete();
    }

    // ==========================================================
    // LOAD FLUTTER ASSET
    // ==========================================================

    print(
      'Copying asset to: '
          '${file.path}',
    );

    final ByteData data =
    await rootBundle.load(assetPath);

    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    if (bytes.isEmpty) {
      throw StateError(
        'Asset is empty: $assetPath',
      );
    }

    // ==========================================================
    // WRITE FILE
    // ==========================================================

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    // ==========================================================
    // VERIFY FILE
    // ==========================================================

    if (!await file.exists()) {
      throw StateError(
        'Failed to create model file: '
            '${file.path}',
      );
    }

    final writtenSize =
    await file.length();

    if (writtenSize != bytes.length) {
      throw StateError(
        'Model file size mismatch for '
            '$fileName. '
            'Expected ${bytes.length}, '
            'got $writtenSize.',
      );
    }

    print(
      'Model copied successfully: '
          '${file.path} '
          '($writtenSize bytes)',
    );

    return file.path;
  }

  // ============================================================
  // RUN ENCODER
  // ============================================================

  Future<OrtValue> runEncoder({
    required List<int> inputIds,
    required List<int> attentionMask,
  }) async {
    if (_encoder == null) {
      throw StateError(
        'Encoder is not initialized.',
      );
    }

    if (inputIds.isEmpty) {
      throw ArgumentError(
        'inputIds cannot be empty.',
      );
    }

    if (inputIds.length !=
        attentionMask.length) {
      throw ArgumentError(
        'inputIds and attentionMask '
            'must have the same length.',
      );
    }

    final sourceLength =
        inputIds.length;

    print('==========================================');
    print('RUNNING ENCODER');
    print('==========================================');

    print(
      'Input shape: [1, $sourceLength]',
    );

    // ==========================================================
    // INPUT IDS
    // ==========================================================

    final inputIdsTensor =
    await OrtValue.fromList(
      Int64List.fromList(inputIds),
      [
        1,
        sourceLength,
      ],
    );

    // ==========================================================
    // ATTENTION MASK
    // ==========================================================

    final attentionMaskTensor =
    await OrtValue.fromList(
      Int64List.fromList(
        attentionMask,
      ),
      [
        1,
        sourceLength,
      ],
    );

    try {
      final outputs =
      await _encoder!.run({
        'input_ids':
        inputIdsTensor,
        'attention_mask':
        attentionMaskTensor,
      });

      final hiddenStates =
      outputs[
      'encoder_hidden_states'];

      if (hiddenStates == null) {
        throw StateError(
          'encoder_hidden_states was not '
              'returned by encoder_model.onnx.',
        );
      }

      print(
        'Encoder output received.',
      );

      return hiddenStates;
    } finally {
      await inputIdsTensor.dispose();
      await attentionMaskTensor.dispose();
    }
  }

  // ============================================================
  // RUN DECODER
  //
  // NO KV CACHE
  //
  // The entire decoder sequence is sent every time.
  // ============================================================

  Future<int> runDecoderFullSequence({
    required List<int> decoderInputIds,
    required List<int> sourceAttentionMask,
    required OrtValue encoderHiddenStates,
  }) async {
    if (_decoderInitial == null) {
      throw StateError(
        'Initial decoder is not initialized.',
      );
    }

    if (decoderInputIds.isEmpty) {
      throw ArgumentError(
        'decoderInputIds cannot be empty.',
      );
    }

    if (sourceAttentionMask.isEmpty) {
      throw ArgumentError(
        'sourceAttentionMask cannot be empty.',
      );
    }

    final decoderLength =
        decoderInputIds.length;

    final sourceLength =
        sourceAttentionMask.length;

    print('------------------------------------------');

    print(
      'Running decoder with '
          'decoder length: $decoderLength',
    );

    // ==========================================================
    // DECODER INPUT IDS
    // ==========================================================

    final decoderInputIdsTensor =
    await OrtValue.fromList(
      Int64List.fromList(
        decoderInputIds,
      ),
      [
        1,
        decoderLength,
      ],
    );

    // ==========================================================
    // DECODER ATTENTION MASK
    // ==========================================================

    final decoderAttentionMaskTensor =
    await OrtValue.fromList(
      Int64List.fromList(
        List<int>.filled(
          decoderLength,
          1,
        ),
      ),
      [
        1,
        decoderLength,
      ],
    );

    // ==========================================================
    // ENCODER ATTENTION MASK
    // ==========================================================

    final encoderAttentionMaskTensor =
    await OrtValue.fromList(
      Int64List.fromList(
        sourceAttentionMask,
      ),
      [
        1,
        sourceLength,
      ],
    );

    try {
      // ========================================================
      // RUN DECODER
      // ========================================================

      final outputs =
      await _decoderInitial!.run({
        'decoder_input_ids':
        decoderInputIdsTensor,

        'decoder_attention_mask':
        decoderAttentionMaskTensor,

        'encoder_hidden_states':
        encoderHiddenStates,

        'encoder_attention_mask':
        encoderAttentionMaskTensor,
      });

      // ========================================================
      // GET LOGITS
      // ========================================================

      final logits =
      outputs['logits'];

      if (logits == null) {
        throw StateError(
          'decoder_initial.onnx did not '
              'return logits.',
        );
      }

      // ========================================================
      // CONVERT LOGITS
      // ========================================================

      final rawLogits =
      await logits.asList();

      print(
        'Logits received.',
      );

      // ========================================================
      // GET NEXT TOKEN
      // ========================================================

      final nextToken =
      _argmaxLastStep(
        rawLogits,
      );

      print(
        'Next token: $nextToken',
      );

      await logits.dispose();

      return nextToken;
    } finally {
      await decoderInputIdsTensor.dispose();
      await decoderAttentionMaskTensor.dispose();
      await encoderAttentionMaskTensor.dispose();
    }
  }

  // ============================================================
  // ARGMAX
  //
  // Expected logits structure:
  //
  // [
  //   [
  //     [vocab values],
  //     [vocab values],
  //     ...
  //   ]
  // ]
  //
  // Shape:
  //
  // [batch, decoder_length, vocab_size]
  //
  // We take:
  //
  // batch 0
  // last decoder position
  //
  // ============================================================

  int _argmaxLastStep(
      dynamic raw,
      ) {
    dynamic current = raw;

    // ==========================================================
    // REMOVE BATCH DIMENSION
    // ==========================================================

    if (current is List &&
        current.isNotEmpty) {
      current = current.first;
    }

    // ==========================================================
    // GET LAST DECODER POSITION
    // ==========================================================

    if (current is List &&
        current.isNotEmpty) {
      current = current.last;
    }

    // ==========================================================
    // CHECK FINAL VECTOR
    // ==========================================================

    if (current is! List) {
      throw StateError(
        'Unexpected logits structure: '
            '${raw.runtimeType}',
      );
    }

    if (current.isEmpty) {
      throw StateError(
        'Logits are empty.',
      );
    }

    // ==========================================================
    // ARGMAX
    // ==========================================================

    double bestValue =
        double.negativeInfinity;

    int bestIndex = 0;

    for (
    int i = 0;
    i < current.length;
    i++
    ) {
      final item = current[i];

      if (item is! num) {
        throw StateError(
          'Logit at index $i is not numeric. '
              'Found: ${item.runtimeType}',
        );
      }

      final value =
      item.toDouble();

      if (value > bestValue) {
        bestValue = value;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    print(
      'Disposing IndicTrans ONNX...',
    );

    try {
      await _encoder?.close();
    } catch (_) {}

    try {
      await _decoderInitial?.close();
    } catch (_) {}

    _encoder = null;
    _decoderInitial = null;

    _initialized = false;

    print(
      'IndicTrans ONNX disposed.',
    );
  }
}