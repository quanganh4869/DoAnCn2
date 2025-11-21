import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/models/product.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/controller/category_controller.dart';
import 'package:flutter/services.dart'; // Import để dùng TextInputFormatter
import 'package:ecomerceapp/seller_dasboard/controller/seller_controller.dart';

class AddProductScreen extends StatefulWidget {
  final Products? productToEdit;

  const AddProductScreen({super.key, this.productToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final SellerController sellerController = Get.find<SellerController>();
  final AuthController authController = Get.find<AuthController>();

  final CategoryController categoryController =
      Get.isRegistered<CategoryController>()
      ? Get.find<CategoryController>()
      : Get.put(CategoryController());

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _oldPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  String? _selectedCategory;

  // Format số kiểu Việt Nam (1.000.000)
  final _formatter = NumberFormat.decimalPattern('vi');

  @override
  void initState() {
    super.initState();

    if (widget.productToEdit != null) {
      final p = widget.productToEdit!;
      _nameController.text = p.name;
      _descController.text = p.description ?? "";
      // Format giá khi hiển thị lên form edit
      _priceController.text = _formatter.format(p.price);
      _stockController.text = p.stock.toString();
      _oldPriceController.text = p.oldPrice != null
          ? _formatter.format(p.oldPrice)
          : "";

      _selectedCategory = p.category;

      if (p.images != null && p.images!.isNotEmpty) {
        _imageController.text = p.images![0];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _oldPriceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputColor = isDark ? Colors.grey[800] : Colors.grey[100];

    final title = widget.productToEdit != null
        ? "Cập nhật Sản Phẩm"
        : "Thêm Sản Phẩm Mới";
    final btnText = widget.productToEdit != null
        ? "Lưu Thay Đổi"
        : "Đăng Bán Ngay";

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Get.back(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Thông tin cơ bản"),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      "Tên sản phẩm",
                      Icons.shopping_bag,
                      inputColor,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Nhập tên sản phẩm" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      "Mô tả chi tiết",
                      Icons.description,
                      inputColor,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Nhập mô tả" : null,
                  ),
                  const SizedBox(height: 16),

                  Obx(() {
                    if (categoryController.categories.isEmpty) {
                      return InkWell(
                        onTap: () => categoryController.onInit(),
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            "Đang tải danh mục...",
                            Icons.category,
                            inputColor,
                          ),
                          child: const Text(
                            "Đang tải hoặc chưa có danh mục...",
                          ),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputDecoration(
                        "Chọn danh mục",
                        Icons.category,
                        inputColor,
                      ),
                      items: categoryController.categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.name,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
                      validator: (v) =>
                          v == null ? "Vui lòng chọn danh mục" : null,
                    );
                  }),

                  const SizedBox(height: 24),

                  _buildSectionTitle("Giá & Kho hàng"),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    decoration: _inputDecoration(
                      "Giá bán",
                      Icons.attach_money,
                      inputColor,
                      suffix: "VND",
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Nhập giá" : null,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _oldPriceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    decoration: _inputDecoration(
                      "Giá cũ (Tùy chọn)",
                      Icons.money_off,
                      inputColor,
                      suffix: "VND",
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      "Kho hàng",
                      Icons.inventory,
                      inputColor,
                    ),
                    validator: (v) => (v == null || int.tryParse(v) == null)
                        ? "Nhập số lượng"
                        : null,
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle("Hình ảnh"),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _imageController,
                    decoration: _inputDecoration(
                      "Link hình ảnh (URL)",
                      Icons.image,
                      inputColor,
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: sellerController.isLoading.value
                            ? null
                            : _submitProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: sellerController.isLoading.value
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                btnText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitProduct() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final desc = _descController.text.trim();

      // ✅ QUAN TRỌNG: Xóa dấu chấm trước khi parse sang double
      final priceString = _priceController.text.replaceAll('.', '');
      final price = double.parse(priceString);

      final stock = int.parse(_stockController.text.trim());
      final category = _selectedCategory!;

      final oldPriceText = _oldPriceController.text.trim().replaceAll('.', '');
      final oldPrice = oldPriceText.isNotEmpty
          ? double.tryParse(oldPriceText)
          : null;

      final imageUrl = _imageController.text.trim();

      bool success;

      if (widget.productToEdit != null) {
        success = await sellerController.updateProduct(
          productId: widget.productToEdit!.id,
          name: name,
          description: desc,
          price: price,
          stock: stock,
          category: category,
          oldPrice: oldPrice,
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        );
      } else {
        success = await sellerController.addProduct(
          name: name,
          description: desc,
          price: price,
          stock: stock,
          category: category,
          oldPrice: oldPrice,
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        );
      }

      if (success) {
        await Future.delayed(const Duration(milliseconds: 1500));
        Get.back();
      }
    } else {
      Get.rawSnackbar(
        title: "Thiếu thông tin",
        message: "Vui lòng kiểm tra lại các trường bắt buộc",
        backgroundColor: Colors.orange,
        snackPosition: SnackPosition.TOP,
        borderRadius: 10,
        margin: const EdgeInsets.all(10),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // Hàm decoration hỗ trợ suffix text
  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
    Color? fillColor, {
    String? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      suffixText: suffix, // Hiển thị 'đ' ở cuối
      suffixStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ✅ CLASS FORMATTER: Tự động thêm dấu chấm khi gõ
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 1. Xóa hết ký tự không phải số
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. Parse sang số nguyên
    int value = int.tryParse(newText) ?? 0;

    // 3. Format lại có dấu chấm
    final formatter = NumberFormat('#,###', 'vi');
    String newString = formatter.format(value);

    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
