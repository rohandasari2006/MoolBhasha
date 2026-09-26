import 'package:flutter/material.dart';
import '../utils/moolbhasha_theme.dart';

/// Rounded cream dropdown field with a green arrow, matching the reference
/// screenshots (Grade / Worksheet Type / Number of Questions / Question
/// Type selectors). Purely presentational — selection state lives in the
/// controller.
class MoolBhashaDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const MoolBhashaDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MoolBhashaTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: MoolBhashaTheme.fieldBackground,
            borderRadius: BorderRadius.circular(MoolBhashaTheme.fieldRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: MoolBhashaTheme.mediumGreen),
              borderRadius: BorderRadius.circular(MoolBhashaTheme.fieldRadius),
              items: options
                  .map((o) => DropdownMenuItem<T>(
                        value: o,
                        child: Text(
                          labelBuilder(o),
                          style: const TextStyle(
                            fontSize: 15,
                            color: MoolBhashaTheme.textPrimary,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
