import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/features/shippingaddress/widgets/address_card.dart';
import 'package:ecomerceapp/features/shippingaddress/repository/address_repository.dart';

class ShippingAddressScreen extends StatelessWidget {
  final AddressRepository _repository = AddressRepository();
  ShippingAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Shipping Address',
          style: AppTextStyles.withColor(
            AppTextStyles.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.add_circle_outline,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _repository.getAddresses().length,
        itemBuilder: (context, index) => _buildAddressCard(context, (index)),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, int index) {
    final address = _repository.getAddresses()[index];
    return AddressCard(
      address: address,
      onDelete: () => _showEditAddressBottomSheet(context, address),
      onEdit: () => _showDeleteAddressDialog(context),
    );
  }

  void _showEditAddressBottomSheet(BuildContext context, address) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Address',
                  style: AppTextStyles.withColor(
                    AppTextStyles.h3,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buiidTextField(
              context,
              'Label (e.g., Home, Office)',
              Icons.label_outline,
              initialValue: address.label,
            ),
            const SizedBox(height: 16),
            _buiidTextField(
              context,
              'Full Address',
              Icons.location_on_outlined,
              initialValue: address.fullAddress,
            ),
            const SizedBox(height: 16),
            _buiidTextField(
              context,
              'City',
              Icons.location_city_outlined,
              initialValue: address.fullAddress,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buiidTextField(
                    context,
                    'State',
                    Icons.map_outlined,
                    initialValue: address.state,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buiidTextField(
                    context,
                    'Zip Code',
                    Icons.pin_outlined,
                    initialValue: address.zipCode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:Text(
                    "Updated Address ",
                    style: AppTextStyles.withColor(
                      AppTextStyles.h3,
                      Theme.of(context).textTheme.bodyLarge!.color!,
                    ),
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showDeleteAddressDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Delete Address',
          style: AppTextStyles.withColor(
            AppTextStyles.h3,
            Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this address?',
          style: AppTextStyles.withColor(
            AppTextStyles.bodyMedium,
            Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyles.withColor(
                AppTextStyles.bodyMedium,
                isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(
              'Delete',
              style: AppTextStyles.withColor(
                AppTextStyles.bodyMedium,
                Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buiidTextField(
    BuildContext context,
    String label,
    IconData icon, {
    String? initialValue,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}
