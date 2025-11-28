import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/product_controller.dart';
import 'package:ecomerceapp/controller/category_controller.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryController = Get.find<CategoryController>();
    final productController = Get.find<ProductController>();

    return Obx(() {
      if (categoryController.isLoading) {
        return SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (categoryController.hasError) {
        return SizedBox(
          height: 50,
          child: Center(
            child: Text(
              categoryController.errorMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        );
      }

      final categories = categoryController.getCategoriesWithfallBack();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((categoryName) {
            final isSelected = categoryController.isCategorySelected(
              categoryName,
            );

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(
                  categoryName,
                  style: AppTextStyles.withColor(
                    AppTextStyles.bodySmall.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    isSelected
                        ? Colors.white
                        : isDark
                        ? Colors.grey[300]!
                        : Colors.grey[600]!,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    categoryController.selectCategory(
                      categoryName,
                    );
                    final selectedCategory = categoryController
                        .getCategoryByName(categoryName);
                    productController.filterByCategory(
                      selectedCategory?.name ?? categoryName,
                    );
                  }
                },

                selectedColor: Theme.of(context).primaryColor,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: isSelected ? 2 : 0,
                pressElevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : isDark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}
