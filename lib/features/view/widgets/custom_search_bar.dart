import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/view/widgets/search_result_screen.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          Get.to(() => SearchResultScreen());
        },
        child: AbsorbPointer(
          absorbing: true,
          child: TextField(
            style: AppTextStyles.withColor(
              AppTextStyles.buttonMedium,
              Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
            decoration: InputDecoration(
              hintText: "Tìm kiém",
              hintStyle: AppTextStyles.withColor(
                AppTextStyles.buttonMedium,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              suffixIcon: Icon(
                Icons.tune,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                  width: 1
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}