import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/view/widgets/product_grid.dart';
import 'package:ecomerceapp/features/view/widgets/fillter_bottom_sheet.dart';

class AllProductsScreen extends StatelessWidget {
  const AllProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          "Tất cả sản phẩm",
          style: AppTextStyles.withColor(
            AppTextStyles.bodyLarge,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: (){},
           icon: Icon(
            Icons.search,
            color: isDark ? Colors.white : Colors.black,
           )
           ),
           IconButton(
            onPressed: () => FillterBottomSheet.show(context),
           icon: Icon(
            Icons.filter_list,
            color: isDark ? Colors.white : Colors.black,
           )
           )
        ],
      ),
      body: const ProductGrid(),
    );
  }
}
