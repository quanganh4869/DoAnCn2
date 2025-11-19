import 'package:get/get.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/supabase/product_supabase_services.dart';

class ProductController extends GetxController {
  // Danh sách sản phẩm
  final RxList<Products> _allProducts = <Products>[].obs;
  final RxList<Products> _filteredProducts = <Products>[].obs;
  final RxList<Products> _featuredProducts = <Products>[].obs;
  final RxList<Products> _saleProducts = <Products>[].obs;
  final RxList<String> _categories = <String>[].obs;

  // Trạng thái
  final RxBool _isLoading = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = "".obs;
  final RxString _selectedCategory = "".obs;
  final RxString _searchQuery = "".obs;

  // THÊM: Biến lưu trữ khoảng giá lọc
  final Rx<double?> _minPriceFilter = Rx<double?>(null);
  final Rx<double?> _maxPriceFilter = Rx<double?>(null);

  // Getters
  List<Products> get allProducts => _allProducts;
  List<Products> get filteredProducts => _filteredProducts;
  List<Products> get featuredProducts => _featuredProducts;
  List<Products> get saleProducts => _saleProducts;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading.value;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;
  String get selectedCategory => _selectedCategory.value;
  String get searchQuery => _searchQuery.value;
  // THÊM: Getters cho Price Filter
  double? get minPriceFilter => _minPriceFilter.value;
  double? get maxPriceFilter => _maxPriceFilter.value;

  @override
  void onInit() {
    super.onInit();
    _selectedCategory.value = "All";
    loadProducts();
  }

  /// Load toàn bộ sản phẩm
  Future<void> loadProducts() async {
    _isLoading.value = true;
    _hasError.value = false;

    try {
      final products = await ProductSupabaseServices.getAllProducts();

      _allProducts.value = products;
      _filteredProducts.value = products;

      await _loadFeaturedProducts();
      await _loadSaleProducts();
      await _loadCategories();
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = "Failed to load products. Please try again.";
      print("Error loading products: $e");
      _allProducts.clear();
      _filteredProducts.clear();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load sản phẩm nổi bật
  Future<void> _loadFeaturedProducts() async {
    try {
      final products = await ProductSupabaseServices.getFeaturedProducts();
      _featuredProducts.value = products;
    } catch (e) {
      print("Error loading featured products: $e");
    }
  }

  /// Load sản phẩm đang giảm giá
  Future<void> _loadSaleProducts() async {
    try {
      final products = await ProductSupabaseServices.getSaleProducts();
      _saleProducts.value = products;
    } catch (e) {
      print("Error loading sale products: $e");
    }
  }

  /// Load danh mục sản phẩm
  Future<void> _loadCategories() async {
    try {
      final categories = await ProductSupabaseServices.getAllCategories();
      _categories.value = categories;
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  // SỬA: Thay thế filterByCategory bằng hàm đa tiêu chí
  void applyFilters({String? category, double? minPrice, double? maxPrice}) {
    // 1. Cập nhật trạng thái Filter
    _selectedCategory.value = category ?? _selectedCategory.value;
    _minPriceFilter.value = minPrice;
    _maxPriceFilter.value = maxPrice;

    // 2. Thực hiện lọc
    _applyFilter();
    update();
  }

  void filterByCategory(String category) {
    _selectedCategory.value = category;
    _applyFilter();
    update();
  }

  void searchProducts(String query) {
    _searchQuery.value = query;
    _applyFilter();
    update();
  }

  void resetFilters() {
    _selectedCategory.value = "All";
    _searchQuery.value = "";
    _minPriceFilter.value = null; // RESET GIÁ
    _maxPriceFilter.value = null; // RESET GIÁ
    _filteredProducts.value = _allProducts;
    _applyFilter();
    update();
  }

  void clearSearch() {
    _searchQuery.value = "";
    _applyFilter();
    update();
  }

  // SỬA: Tích hợp logic lọc giá vào hàm _applyFilter
  void _applyFilter() {
    List<Products> filtered = List.from(_allProducts);

    // 1. LỌC THEO CATEGORY
    if (_selectedCategory.value != "All" &&
        _selectedCategory.value.isNotEmpty) {
      final selectedCat = _selectedCategory.value.toLowerCase();
      filtered = filtered.where((product) {
        final productCat = product.category.toLowerCase();
        if (selectedCat == "home & living" || selectedCat == "home") {
          return productCat == "home" || productCat == "home & living";
        }
        if (selectedCat == "sports & fitness" || selectedCat == "sports") {
          return productCat == "sports" || productCat == "sports & fitness";
        }
        return productCat == selectedCat ||
            productCat.contains(selectedCat) ||
            selectedCat.contains(productCat);
      }).toList();

      print("Filtering by category: ${_selectedCategory.value}");
      print("Found ${filtered.length} products in category");
      print(
        "Available categories in products: ${_allProducts.map((p) => p.category).toSet()}",
      );
    } else {
      print("Showing all products: ${_allProducts.length}");
    }

    // 2. LỌC THEO PRICE RANGE
    final min = _minPriceFilter.value;
    final max = _maxPriceFilter.value;

    if (min != null) {
      filtered = filtered.where((product) => product.price >= min).toList();
      print("Filtering: Price >= $min");
    }
    if (max != null) {
      filtered = filtered.where((product) => product.price <= max).toList();
      print("Filtering: Price <= $max");
    }

    // 3. LỌC THEO SEARCH QUERY
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered
          .where(
            (product) =>
                product.name.toLowerCase().contains(query) ||
                product.category.toLowerCase().contains(query) ||
                product.description.toLowerCase().contains(query) ||
                (product.brand?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    _filteredProducts.value = filtered;
    print("Total filtered products: ${_filteredProducts.length}");
  }

  // Tìm kiếm sản phẩm theo danh mục
  Future<List<Products>> getProductsByCategory(String category) async {
    try {
      return await ProductSupabaseServices.getProductsByCategory(category);
    } catch (e) {
      print("Error getting products by category: $e");
      return [];
    }
  }

  // Tìm sản phẩm trong Supabase
  Future<List<Products>> searchProductsInSupaBase(String searchTerm) async {
    try {
      return await ProductSupabaseServices.searchProducts(searchTerm);
    } catch (e) {
      print("Error searching products in Supabase: $e");
      return [];
    }
  }

  // Lấy sản phẩm theo id
  Future<Products?> getProductById(String productID) async {
    try {
      return await ProductSupabaseServices.getProductById(productID);
    } catch (e) {
      print("Error getting product by ID: $e");
      return null;
    }
  }

  // Load lại sản phẩm
  Future<void> refreshProduct() async {
    await loadProducts();
    update();
  }

  // Xóa lọc sản phẩm
  void clearFilters() {
    _selectedCategory.value = "All";
    _searchQuery.value = "";
    _minPriceFilter.value = null;
    _maxPriceFilter.value = null;
    _filteredProducts.value = _allProducts;
  }

  // Lấy sản phẩm để hiển thị
  List<Products> getDisplayProducts() {
    if (_selectedCategory.value == "All" || _selectedCategory.value.isEmpty) {
      return _allProducts;
    }
    return _filteredProducts;
  }
}
