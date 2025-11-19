import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';
import 'package:ecomerceapp/controller/address_controller.dart';
import 'package:ecomerceapp/features/shippingaddress/models/address.dart';
import 'package:ecomerceapp/features/shippingaddress/widgets/shipping_address_screen.dart';

class CheckoutAddressCard extends StatelessWidget {
  CheckoutAddressCard({super.key});

  // Tìm AddressController đã được put từ trước
  final AddressController controller = Get.find<AddressController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      // LOGIC: Lấy địa chỉ mặc định, nếu không có thì lấy cái đầu tiên, nếu list rỗng thì null
      Address? displayAddress;
      if (controller.addresses.isNotEmpty) {
        displayAddress = controller.addresses.firstWhereOrNull((e) => e.isDefault) ?? controller.addresses.first;
      }

      // Nếu chưa có địa chỉ nào
      if (displayAddress == null) {
        return InkWell(
          onTap: () => Get.to(() => ShippingAddressScreen()),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey, style: BorderStyle.solid),
            ),
            child: Center(
              child: Text(
                "+ Add Shipping Address",
                style: AppTextStyles.withColor(
                  AppTextStyles.h3,
                  isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      }

      // Nếu đã có địa chỉ
      return InkWell(
        onTap: () => Get.to(() => ShippingAddressScreen()),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayAddress.label, // Ví dụ: Home, Office
                          style: AppTextStyles.withColor(
                            AppTextStyles.h3,
                            Theme.of(context).textTheme.bodyLarge!.color!,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${displayAddress.fullAddress}, ${displayAddress.city}",
                          style: AppTextStyles.withColor(
                            AppTextStyles.bodyMedium,
                            isDark ? Colors.grey[400]! : Colors.grey[700]!,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${displayAddress.state} - ${displayAddress.zipCode}",
                          style: AppTextStyles.withColor(
                            AppTextStyles.bodyMedium,
                            isDark ? Colors.grey[400]! : Colors.grey[700]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.to(() => ShippingAddressScreen()),
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}