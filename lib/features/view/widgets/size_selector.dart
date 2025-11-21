import 'package:flutter/material.dart';

class SizeSelector extends StatelessWidget {
  final List<String> sizes;
  final String? selectedSize;
  final Function(String) onSizeSelected;

  const SizeSelector({
    super.key,
    required this.sizes,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sizes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final size = sizes[index];
          final isSelected = size == selectedSize;

          return GestureDetector(
            onTap: () => onSizeSelected(size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.grey[800] : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  width: 1.5,
                ),
                boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2)
                      )
                    ]
                  : null,
              ),
              child: Text(
                size,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}