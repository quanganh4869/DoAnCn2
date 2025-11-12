import 'package:flutter/material.dart';

class SizeSelector extends StatefulWidget {
  final List<String> sizes;
  final Function(String)? onSizeSelected;
  final String? initialSize;

  const SizeSelector({
    super.key,
    this.sizes = const ["S", "M", "L", "XL", "XXL"],
    this.onSizeSelected,
    this.initialSize,
  });

  @override
  State<SizeSelector> createState() => _SizeSelectorState();
}

class _SizeSelectorState extends State<SizeSelector> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialSize != null) {
      final index = widget.sizes.indexOf(widget.initialSize!);
      if (index != -1) {
        _selectedIndex = index;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.sizes.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = index);
              if (widget.onSizeSelected != null) {
                widget.onSizeSelected!(widget.sizes[index]);
              }
            },
            child: Container(
              width: 50,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : isDark
                          ? Colors.grey[700]!
                          : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Text(
                  widget.sizes[index],
                  style: TextStyle(
                    color: isSelected ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
