import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/product_controller.dart';
import 'package:ecomerceapp/features/view/widgets/product_details_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchResultScreen({super.key, this.initialQuery});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final ProductController _productController = Get.find<ProductController>();
  final TextEditingController _searchController = TextEditingController();
  final RxList<Products> _searchResults = <Products>[].obs;
  final RxBool _isSearching = false.obs;

  Timer? _debounce;
  static const int _debounceDuration = 500;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      return;
    }
    _isSearching.value = true;
    final results = await _productController.searchProductsInSupaBase(query);

    _searchResults.value = results;
    _isSearching.value = false;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceDuration), () {
      _performSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Kết quả tùm kiếm', style: AppTextStyles.h3),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              autofocus:
                  widget.initialQuery == null || widget.initialQuery!.isEmpty,

              onSubmitted: (query) => _performSearch(query),
              onChanged: _onSearchChanged,

              style: AppTextStyles.withColor(
                AppTextStyles.buttonMedium,
                Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              ),
              decoration: InputDecoration(
                hintText: "Tim kiếm...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchResults.clear();
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Obx(() {
            final count = _searchResults.length;
            final currentQuery = _searchController.text.trim();

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                _isSearching.value
                    ? 'Đang tìm kiếm...'
                    : '$count kết quả về "$currentQuery"',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            );
          }),
          const Divider(),
          Expanded(
            child: Obx(() {
              if (_isSearching.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_searchResults.isEmpty) {
                return Center(
                  child: Text(
                    'Không tìm thấy sản phẩm nào.',
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  return ListTile(
                    leading: SizedBox(
                      width: 50,
                      height: 50,
                      child: Image.network(
                        product.primaryImage.isNotEmpty
                            ? product.primaryImage
                            : 'https://via.placeholder.com/150',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 30),
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: AppTextStyles.buttonMedium,
                    ),
                    subtitle: Text(
                      '${product.price.toStringAsFixed(0)} ${product.currency}',
                    ),
                    onTap: () {
                      Get.to(() => ProductDetailsScreen(product: product));
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
