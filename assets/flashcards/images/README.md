# Flashcard images — not bundled yet

No image files are included in this scaffold. `Flashcard.imageAsset` in a
handful of the starter JSON entries (e.g. `assets/flashcards/images/animals/cow.webp`)
points at paths that don't exist on disk yet — this mirrors how
`assets/models/*.onnx` is referenced in `pubspec.yaml` without being bundled
(see the main README). `FlashcardPdfService` already degrades gracefully:
a missing image asset is caught and the card falls back to text-only rather
than crashing the export.

Before shipping, add real local .webp/.png images under subfolders such as
`animals/`, `objects/`, `shapes/` and keep them small (low-end-device target,
~2GB RAM) — do not bundle full-resolution photography.
