import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/product_controller.dart';

// --- MAIN BOTTOM SHEET WIDGET ---
class FillterBottomSheet extends StatelessWidget {
  const FillterBottomSheet({super.key});
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Sử dụng Padding widget để bao bọc, thêm MediaQuery để tránh bàn phím che UI
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: const _FillterBottomSheetContent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
// --- STATEFUL CONTENT WIDGET ---
class _FillterBottomSheetContent extends StatefulWidget {
  const _FillterBottomSheetContent();
  @override
  State<_FillterBottomSheetContent> createState() =>
      _FillterBottomSheetContentState();
}
class _FillterBottomSheetContentState
    extends State<_FillterBottomSheetContent> {
  final ProductController _productController = Get.find<ProductController>();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final NumberFormat _priceFormatter = NumberFormat("#,##0", "vi_VN");
  late String _selectedCategory;
  @override
  void initState() {
    super.initState();
    _selectedCategory =
        _productController.selectedCategory.isEmpty ||
            _productController.selectedCategory == "All"
        ? 'All'
        : _productController.selectedCategory;
    if (_productController.minPriceFilter != null) {
      _minPriceController.text = _priceFormatter.format(
        _productController.minPriceFilter!,
      );
    }
    if (_productController.maxPriceFilter != null) {
      _maxPriceController.text = _priceFormatter.format(
        _productController.maxPriceFilter!,
      );
    }
  }
  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
  void _formatNumberInput(TextEditingController controller, String value) {
    final rawValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    final number = int.tryParse(rawValue);
    setState(() {
      if (number != null) {
        final formattedText = _priceFormatter.format(number);
        if (controller.text != formattedText) {
          controller.value = controller.value.copyWith(
            text: formattedText,
            selection: TextSelection.collapsed(offset: formattedText.length),
          );
        }
      } else if (value.isNotEmpty && rawValue.isEmpty) {
        controller.clear();
      }
    });
  }
  // HÀM XỬ LÝ LỌC
  void _applyCategoryAndPriceFilter() {
    double? minInput = double.tryParse(
      _minPriceController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    double? maxInput = double.tryParse(
      _maxPriceController.text.replaceAll('.', '').replaceAll(',', ''),
    );
    double? finalMinPrice = minInput;
    double? finalMaxPrice = maxInput;
    if (finalMinPrice != null &&
        finalMaxPrice != null &&
        finalMinPrice > finalMaxPrice) {
      Get.snackbar(
        "Lỗi",
        "Giá Min không được lớn hơn giá Max.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(10),
      );
      return;
    }
    // GỌI HÀM LỌC ĐA TIÊU CHÍ (applyFilters)
    _productController.applyFilters(
      category: _selectedCategory,
      minPrice: finalMinPrice,
      maxPrice: finalMaxPrice,
    );
    Get.back();
  }
  // Hàm xóa lọc và đóng BottomSheet
  void _clearAndClose() {
    _productController.clearFilters();
    Get.back();
  }
  // --- BUILD WIDGETS ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(isDark: isDark),
          const SizedBox(height: 24),
          Text("Price Range", style: AppTextStyles.h3),
          const SizedBox(height: 16),
          _PriceRangeInputs(
            minController: _minPriceController,
            maxController: _maxPriceController,
            formatInput: _formatNumberInput,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          Text("Categories", style: AppTextStyles.h3),
          const SizedBox(height: 16),
          _CategoryChips(
            productController: _productController,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _ClearFilterButton(onPressed: _clearAndClose, isDark: isDark),
              const SizedBox(width: 16),
              Expanded(
                child: _ApplyFilterButton(
                  onPressed: _applyCategoryAndPriceFilter,
                  primaryColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
// --- WIDGET TRỢ GIÚP: HEADER ---
class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Filter Product",
          style: AppTextStyles.h3.copyWith(
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
        ),
      ],
    );
  }
}
// --- WIDGET TRỢ GIÚP: PRICE RANGE INPUTS ---
class _PriceRangeInputs extends StatelessWidget {
  final TextEditingController minController;
  final TextEditingController maxController;
  final void Function(TextEditingController, String) formatInput;
  final bool isDark;
  const _PriceRangeInputs({
    required this.minController,
    required this.maxController,
    required this.formatInput,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PriceInputField(
            controller: minController,
            hintText: "Min",
            isDark: isDark,
            onChanged: (value) => formatInput(minController, value),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _PriceInputField(
            controller: maxController,
            hintText: "Max",
            isDark: isDark,
            onChanged: (value) => formatInput(maxController, value),
          ),
        ),
      ],
    );
  }
}
// Widget trợ giúp để tạo layout Price Input với hậu tố sát nhau
class _PriceInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isDark;
  final void Function(String) onChanged;
  const _PriceInputField({
    required this.controller,
    required this.hintText,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
                
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            textAlign: TextAlign.left, 
            style: AppTextStyles.bodyMedium, 
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            " VND",
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}
// --- WIDGET TRỢ GIÚP: CATEGORY CHIPS ---
class _CategoryChips extends StatelessWidget {
  final ProductController productController;
  final String selectedCategory;
  final void Function(String) onCategorySelected;
  const _CategoryChips({
    required this.productController,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Obx(() {
      final allCategories = ['All', ...productController.categories];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allCategories
            .map(
              (category) => FilterChip(
                label: Text(category),
                selected: category == selectedCategory,
                onSelected: (selected) {
                  if (selected) {
                    onCategorySelected(category);
                  }
                },
                backgroundColor: Theme.of(context).cardColor,
                selectedColor: primaryColor.withOpacity(0.2),
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: category == selectedCategory
                      ? primaryColor
                      : Theme.of(context).textTheme.bodyLarge!.color,
                ),
                showCheckmark: false,
                side: BorderSide(
                  color: category == selectedCategory
                      ? primaryColor
                      : Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            )
            .toList(),
      );
    });
  }
}
// --- WIDGET TRỢ GIÚP: APPLY BUTTON ---
class _ApplyFilterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color primaryColor;
  const _ApplyFilterButton({
    required this.onPressed,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      child: Text(
        "Apply Filters",
        style: AppTextStyles.h3.copyWith(color: Colors.white),
      ),
    );
  }
}
// --- WIDGET TRỢ GIÚP: CLEAR FILTER BUTTON ---
class _ClearFilterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDark;
  const _ClearFilterButton({required this.onPressed, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Text(
          "Clear Filter",
          style: AppTextStyles.h3.copyWith(
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
      ),
    );
  }
}
