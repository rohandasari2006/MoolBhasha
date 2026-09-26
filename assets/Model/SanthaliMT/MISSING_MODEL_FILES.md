# SanthaliMT model assets — NOT bundled here

`SanthaliMtOnnxProvider` (lib/features/worksheet_generator/services/
santali_mt_onnx_provider.dart) expects the following files in this
directory at build time:

    encoder_model.onnx
    decoder_initial.onnx
    decoder_with_past.onnx
    config.json
    generation_config.json
    dict.SRC.json
    dict.TGT.json
    model.SRC
    model.TGT
    tokenizer_config.json
    special_tokens_map.json

None of these were included in the asset drop this integration was built
from (only AnimacySize.zip and the two NotoSans .ttf files were supplied
alongside the project zip) — they were referenced only in the task
specification's directory listing, not attached as real files. They are
NOT fabricated here: the provider code is complete and matches the
documented hin_Deva -> sat_Olck encoder / decoder_initial / decoder_with_past
(KV-cache) pipeline, but it cannot run, and `flutter pub get` / a release
build will fail on the missing assets, until the real files above are
copied into this folder.

Do not quantize, retrain, or otherwise modify encoder_model.onnx,
decoder_initial.onnx or decoder_with_past.onnx once supplied (spec
section 9) — drop them in as-is.
