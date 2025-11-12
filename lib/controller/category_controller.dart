import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:ecomerceapp/models/category.dart';
import 'package:ecomerceapp/supabase/category_supabase_services.dart';

class CategoryController extends GetxController {
  final RxList<Category> _categories = <Category>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = "".obs;
  final Rx<Category?> _selectedCategory = Rx<Category?>(null);
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading.value;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;
  Category? get selectedCategory => _selectedCategory.value;
  RxList<Category> get rxCategories => _categories;

  List<String> get categoryNames {
    final names = ["All"];
    names.addAll(_categories.map((category) => category.displayName));
    return names;
  }

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  // Load danh mục từ supabase
  Future<void> loadCategories() async {
    _isLoading.value = true;
    _hasError.value = false;

    try {
      final categories = await CategorySupabaseServices.getAllCategories();
      _categories.value = categories;
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = "Failed to load categories. Please try again.";
      print("Error loading categories: $e");

      _categories.value = [];
    } finally {
      _isLoading.value = false;
    }
  }

  // Chọn danh mục
  void selectCategory(String categoryName) {
    if (categoryName == "All") {
      _selectedCategory.value = null;
    } else {
      final category = _categories.firstWhereOrNull(
        (cat) => cat.displayName == categoryName || cat.name == categoryName,
      );
      _selectedCategory.value = category;
    }
    update();
  }

  // Chọn danh mục theo tên
  Category? getCategoryByName(String categoryName) {
    return _categories.firstWhereOrNull(
      (cat) => cat.displayName == categoryName || cat.name == categoryName,
    );
  }

  // Chọn danh mục theo ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      return await CategorySupabaseServices.getCategoryById(categoryId);
    } catch (e) {
      print("Error getting category by ID: $e");
      return null;
    }
  }

  // Load lại trang danh mục
  String get selectedCategoryName {
    return _selectedCategory.value?.displayName ?? "All";
  }

  // Kiểm tra nếu thư mục đươc chọn
  bool isCategorySelected(String CategoryName) {
    if (CategoryName == "All") {
      return _selectedCategory.value == null;
    }
    return _selectedCategory.value?.displayName == CategoryName ||
        _selectedCategory.value?.name == CategoryName;
  }

  // Đặt lựa chọn danh mục mặc định để hiển thị
  String get selectedCategoryDisplayName {
    return _selectedCategory.value?.displayName ?? "All";
  }

  // Stream realtime từ Supabase
  Stream<List<Category>> getCategoryRealtimeStream() {
    return CategorySupabaseServices.getCategoryStream();
  }

  // Đặt danh mục dự phòng
  List<String> getCategoriesWithfallBack() {
    if (_categories.isNotEmpty) {
      return categoryNames;
    } else {
      return [
        "All",
        "Electronics",
        "Footwear",
        "Clothing",
        "Accessories",
        "Sports",
      ];
    }
  }
}
