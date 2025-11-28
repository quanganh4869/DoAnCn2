import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/view/widgets/product_grid.dart';
import 'package:ecomerceapp/features/view/widgets/category_chips.dart';
import 'package:ecomerceapp/features/view/widgets/search_result_screen.dart';
import 'package:ecomerceapp/features/view/widgets/fillter_bottom_sheet.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});


  @override
  Widget build(BuildContext context) {
final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Tất cả sản phẩm",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 24,
          )
        ),
        actions: [
          IconButton(
            onPressed: (){
              Get.to(SearchResultScreen());
            },
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
      body: const Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top:16),
            child: CategoryChips(),
          ),
          Expanded(
            child: ProductGrid(),
          )
        ],
      ),
    );
  }
}

