import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/controller/product_controller.dart';
import 'package:ecomerceapp/features/view/widgets/product_card.dart';
import 'package:ecomerceapp/features/view/widgets/product_details_screen.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refreshProduct,
                  child: const Text("Refresh"),
                ),
              ],
            ),
          );
        }

        final displayProducts = controller.getDisplayProducts();

        if (displayProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  "No products available",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refreshProduct,
                  child: const Text("Refresh"),
                ),
              ],
            ),
          );
        }

        double screenWidth = MediaQuery.of(context).size.width;

        int crossAxisCount;
        double childAspectRatio;

        if (screenWidth > 1200) {
          crossAxisCount = 5;
          childAspectRatio = 0.65;
        } else if (screenWidth > 900) {
          crossAxisCount = 4;
          childAspectRatio = 0.65;
        } else if (screenWidth > 600) {
          crossAxisCount = 3;
          childAspectRatio = 0.62;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 0.58;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: displayProducts.length,
          itemBuilder: (context, index) {
            final product = displayProducts[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: product),
                ),
              ),
              child: ProductCard(product: product),
            );
          },
        );
      },
    );
  }
}