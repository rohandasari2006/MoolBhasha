# MoolBhasha

### Offline AI-Powered Multilingual Learning Platform for Tribal Classrooms

MoolBhasha is an **offline-first AI-powered Android learning platform** designed to reduce language barriers in tribal and multilingual classrooms.

It combines **Hindi–Tribal voice translation, bilingual worksheets, visual flashcards, lessons, assessment, and local progress tracking** into a single application designed for low-resource environments.

---

## Problem Statement

Children in multilingual and tribal classrooms may face a language gap between the language used in educational resources and the language they understand at home.

Many existing AI translation and learning solutions depend on:

- Continuous internet connectivity
- Cloud APIs
- Remote inference
- High-end hardware
- Online databases
- Limited support for low-resource Indian languages

MoolBhasha addresses this challenge through an **offline-first, on-device AI architecture**.

---

# Solution

MoolBhasha performs the core learning and AI workflow locally on the Android device.

```text
Hindi / Hinglish Speech
          |
          v
   Speech Recognition
      Whisper Small
          |
          v
    Phrase Buffer
          |
          v
 Hindi -> Santali MT
     IndicTrans2
        320M
          |
          v
   Santali Text
     Ol Chiki
          |
          v
     Santali TTS
    Indic-Speak
          |
          v
    Santali Speech
```

The core educational workflow is designed to operate without continuous internet connectivity.

---

# Key Features

## 1. Offline AI Voice Translation

Teachers and students can speak Hindi/Hinglish and receive Santali output.

```text
Voice
  |
  v
ASR
  |
  v
Hindi Text
  |
  v
Hindi -> Santali
  |
  v
Santali Text
  |
  v
Santali Speech
```

The translation system targets phrase-level interaction with a target latency of:

```text
< 3 seconds
```

> Latency is an engineering target and may vary by device.

---

## 2. Hindi -> Santali Machine Translation

MoolBhasha uses the AI4Bharat IndicTrans2 320M model.

```text
Source Language : hin_Deva
Target Language : sat_Olck
```

The model is deployed as an ONNX inference pipeline:

```text
encoder_model.onnx
        |
        v
decoder_initial.onnx
        |
        v
decoder_with_past.onnx
```

### Dynamic KV Cache

The cached decoder supports dynamically growing self-attention KV cache:

```text
1 -> 2 -> 3 -> 4 -> 5 -> ... -> N
```

---

## 3. Santali / Ol Chiki Support

MoolBhasha supports Santali using the Ol Chiki script.

### Hindi

```text
आज हम जानवरों के बारे में सीखेंगे।
```

### Santali

```text
ᱛᱮᱦᱮᱧ ᱟᱢ ᱵᱤᱨᱤᱭᱟᱹ ᱠᱚ ᱤᱫᱤ ᱠᱟᱛᱮ
ᱵᱟᱰᱟᱭ ᱧᱟᱢᱼᱟ ᱾
```

---

## 4. Bilingual Worksheets

Supported worksheet types:

- Fill in the blanks
- Match the following
- True / False
- Short answer
- Mixed questions

Content can be presented in:

```text
Hindi + Santali
```

Worksheets are designed for printable A4 output.

---

## 5. Visual Flashcards

Target levels:

```text
Balvatika
Grade 1
Grade 2
Grade 3
```

Flashcards can contain:

- Images
- Hindi text
- Santali text
- Learning categories
- Learning-outcome mappings

Current content includes:

```text
Big Animate
Big Inanimate
Small Animate
Small Inanimate
```

---

## 6. Lessons and Assessment

```text
Lessons
   |
   v
Activities
   |
   v
Assessment
   |
   v
Score
   |
   v
Local Progress
```

Student progress can be stored locally using SQLite.

---

# Technology Stack

| Layer | Technology |
|---|---|
| Application | Flutter |
| Language | Dart |
| Platform | Android |
| Minimum Android | Android 9 / API 28+ |
| Architecture | Offline-first |
| Database | SQLite |
| ASR | Whisper Small |
| Machine Translation | AI4Bharat IndicTrans2 320M |
| ML Runtime | ONNX Runtime |
| TTS | Indic-Speak |
| Script | Ol Chiki |
| Fonts | Noto Sans Devanagari / Ol Chiki |

---

# ONNX Translation Architecture

```text
                 Hindi Tokens
                      |
                      v
          +-----------------------+
          |   encoder_model.onnx  |
          +-----------+-----------+
                      |
                      v
             Encoder Hidden States
                      |
                      v
          +-----------------------+
          |  decoder_initial.onnx |
          +-----------+-----------+
                      |
                      v
                  First Token
                      |
                      v
          +-----------------------+
          | decoder_with_past.onnx|
          +-----------+-----------+
                      |
                      v
                 KV Cache
                      |
            +---------+---------+
            |                   |
            v                   v
       Next Token          Updated KV
            |                   |
            +---------+---------+
                      |
                      v
                     EOS
                      |
                      v
              Santali Text
```
---

# Target Hardware

```text
Android 9+
API 28+
ARM64
~2 GB RAM
Offline operation
Local model inference
```

The core learning workflow is designed without requiring:

- Cloud inference
- External translation APIs
- Continuous internet
- Cloud databases
- High-end GPU hardware

---

# Educational Scope

MoolBhasha focuses on foundational learning for:

```text
Balvatika
   |
Grade 1
   |
Grade 2
   |
Grade 3
```

The educational workflow can incorporate NIPUN Bharat-aligned foundational literacy and numeracy learning outcomes.

---

# Project Structure

```text
MoolBhasha/
|
├── lib/
|   ├── features/
|   |   ├── translation/
|   |   ├── flashcards/
|   |   ├── worksheet_generator/
|   |   ├── lessons/
|   |   └── assessment/
|   |
|   ├── services/
|   └── main.dart
|
├── assets/
|   ├── models/
|   |   └── SanthaliMT/
|   |       ├── encoder_model.onnx
|   |       ├── decoder_initial.onnx
|   |       ├── decoder_with_past.onnx
|   |       ├── config.json
|   |       ├── generation_config.json
|   |       ├── dict.SRC.json
|   |       ├── dict.TGT.json
|   |       ├── model.SRC
|   |       ├── model.TGT
|   |       ├── tokenizer_config.json
|   |       └── special_tokens_map.json
|   |
|   ├── fonts/
|   |   ├── NotoSansDevanagari-Regular.ttf
|   |   └── NotoSansOlChiki-Regular.ttf
|   |
|   └── flashcards/
|       ├── data/
|       └── images/
|
├── pubspec.yaml
└── README.md
```

---

# Innovation

### Offline AI Voice Translation
On-device AI translation is designed to work without a cloud translation API.

### Low-Resource Language Focus
The system focuses on Hindi–Santali educational communication using Ol Chiki.

### Phrase-Level Interaction
Phrase buffering enables smaller classroom speech units.

### Integrated Learning Platform

```text
Translation
     +
Lessons
     +
Flashcards
     +
Worksheets
     +
Assessment
     +
Progress
```

---

# Impact

MoolBhasha aims to support:

- Tribal-language inclusion in early education
- Teacher–student communication
- Local-language educational material
- Offline learning in low-connectivity schools
- Reduced dependence on cloud AI services
- Digital educational resources for Santali learners

---

# Performance Targets

```text
Phrase translation target : < 3 seconds
Offline core functionality: 100%
Minimum Android           : Android 9 / API 28+
Architecture              : ARM64
Target RAM                : ~2 GB
```

These are engineering targets and may vary by device.

---

# Model and Technology Attribution

MoolBhasha builds upon open-source research and technologies including:

- AI4Bharat
- IndicTrans2
- IndicWhisper / Whisper
- Indic-Speak
- ONNX Runtime
- Flutter
- SQLite
- Noto Fonts

All upstream model, dataset, font, and software licenses should be retained and followed according to their respective licenses.

---
