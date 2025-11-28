import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/address_controller.dart';
import 'package:ecomerceapp/features/shippingaddress/models/address.dart';
import 'package:ecomerceapp/features/shippingaddress/widgets/address_card.dart';

class ShippingAddressScreen extends StatelessWidget {
  ShippingAddressScreen({super.key});

  final AddressController controller = Get.put(AddressController());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Địa chỉ ship",
          style: AppTextStyles.h3.copyWith(
             color: isDark ? Colors.white : Colors.black
          )
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.addresses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.addresses.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: controller.addresses.length,
          itemBuilder: (context, index) {
            final address = controller.addresses[index];
            return AddressCard(
              address: address,
              onEdit: () => _handleEditAddress(context, address),
              onDelete: () => _handleDeleteAddress(context, address.id!),
              onSetDefault: () => controller.setDefaultAddress(address.id!),
            );
          },
        );
      }),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAddAddressBottomSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "Add New Address",
                    style: AppTextStyles.withColor(
                      AppTextStyles.h3,
                      Colors.white,
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No addresses found",
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            "Add a new address to start shipping",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _handleEditAddress(BuildContext context, Address address) {
    controller.fillControllers(address);
    _showAddressBottomSheet(context, title: "Edit Address", isEdit: true);
  }

  void _handleDeleteAddress(BuildContext context, String addressId) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Address"),
        content: const Text("Are you sure you want to remove this address?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              controller.deleteAddress(addressId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddAddressBottomSheet(BuildContext context) {
    controller.clearControllers();
    _showAddressBottomSheet(context, title: "Add New Address");
  }

  void _showAddressBottomSheet(BuildContext context, {required String title, bool isEdit = false}) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.h3),
              const SizedBox(height: 16),

              _buildTextField(controller.labelController, 'Label (Home, Office)', Icons.label),
              const SizedBox(height: 12),
              _buildTextField(controller.fullAddressController, 'Full Address', Icons.location_on),
              const SizedBox(height: 12),
              _buildTextField(controller.cityController, 'City', Icons.location_city),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller.stateController, 'State', Icons.map)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(controller.zipCodeController, 'Zip Code', Icons.pin)),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.saveAddress(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEdit ? "Update Address" : "Add Address",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}