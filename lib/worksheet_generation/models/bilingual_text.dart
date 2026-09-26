/// Holds paired Hindi (hin_Deva) and Santali (sat_Olck) text for a single
/// semantic field. Fields are translated independently — never as one block
/// — so a question's instruction, question text, options and answer each
/// carry their own BilingualText instance.
class BilingualText {
  final String hindi;
  final String? santali; // null until translated

  const BilingualText({required this.hindi, this.santali});

  bool get isTranslated => santali != null && santali!.trim().isNotEmpty;

  BilingualText withSantali(String value) =>
      BilingualText(hindi: hindi, santali: value);

  Map<String, dynamic> toJson() => {
        'hindi': hindi,
        'santali': santali,
      };

  factory BilingualText.fromJson(Map<String, dynamic> json) => BilingualText(
        hindi: json['hindi'] as String,
        santali: json['santali'] as String?,
      );

  @override
  String toString() => 'BilingualText(hi: $hindi, sat: $santali)';
}
