import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/features/shippingaddress/models/address.dart';
import 'package:ecomerceapp/supabase/shippingaddress_supabase_services.dart';


class AddressController extends GetxController {
  final AddressSupabaseService _service = AddressSupabaseService();

  var addresses = <Address>[].obs;
  var isLoading = false.obs;
  final _supabase = Supabase.instance.client;

  final labelController = TextEditingController();
  final fullAddressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipCodeController = TextEditingController();

String? editingId;
  StreamSubscription<AuthState>? _authSubscription;
  @override
  void onInit() {
    super.onInit();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      // Nếu đã có session (đã đăng nhập/khôi phục xong), tải dữ liệu
      if (session != null) {
        fetchAddresses();
      }
    });

    // Vẫn gọi 1 lần cho trường hợp Mobile (đã có session sẵn)
    if (_supabase.auth.currentUser != null) {
      fetchAddresses();
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel(); // Hủy lắng nghe khi thoát
    labelController.dispose();
    fullAddressController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipCodeController.dispose();
    super.onClose();
  }

  Future<void> fetchAddresses() async {
    try {
      isLoading.value = true;
      addresses.value = await _service.getAddresses();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load addresses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void clearControllers() {
    editingId = null;
    labelController.clear();
    fullAddressController.clear();
    cityController.clear();
    stateController.clear();
    zipCodeController.clear();
  }

  void fillControllers(Address address) {
    editingId = address.id;
    labelController.text = address.label;
    fullAddressController.text = address.fullAddress;
    cityController.text = address.city;
    stateController.text = address.state;
    zipCodeController.text = address.zipCode;
  }

  Future<void> saveAddress() async {
    if (labelController.text.isEmpty || fullAddressController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in required fields');
      return;
    }

    try {
      isLoading.value = true;
      bool isFirstAddress = addresses.isEmpty;

      final newAddress = Address(
        id: editingId,
        label: labelController.text,
        fullAddress: fullAddressController.text,
        city: cityController.text,
        state: stateController.text,
        zipCode: zipCodeController.text,
        type: AddressType.home,
        isDefault: isFirstAddress ? true : false,
      );

      if (editingId == null) {
        await _service.addAddress(newAddress);
        Get.snackbar('Success', 'Address added successfully');
      } else {
        await _service.updateAddress(newAddress);
        Get.snackbar('Success', 'Address updated successfully');
      }

      await fetchAddresses();
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to save address: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      isLoading.value = true;
      await _service.deleteAddress(id);
      await fetchAddresses();
      Get.back();
      Get.snackbar('Success', 'Address deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // --- HÀM MỚI: SET DEFAULT ---
  Future<void> setDefaultAddress(String id) async {
    try {
      isLoading.value = true;

      final address = addresses.firstWhereOrNull((e) => e.id == id);
      if (address == null) return;

      // Tạo bản copy với isDefault = true
      final updatedAddress = Address(
        id: address.id,
        label: address.label,
        fullAddress: address.fullAddress,
        city: address.city,
        state: address.state,
        zipCode: address.zipCode,
        type: address.type,
        isDefault: true, // Trigger DB sẽ lo phần còn lại
      );

      await _service.updateAddress(updatedAddress);
      await fetchAddresses(); // Reload để cập nhật UI

      Get.snackbar('Success', 'Default address updated');
    } catch (e) {
      Get.snackbar('Error', 'Failed to set default: $e');
    } finally {
      isLoading.value = false;
    }
  }


}