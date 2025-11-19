import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomerceapp/features/shippingaddress/models/address.dart';

class AddressSupabaseService {
  final _supabase = Supabase.instance.client;
  final String _tableName = 'addresses'; // Tên bảng trong Supabase

  // Lấy danh sách địa chỉ của User hiện tại
  Future<List<Address>> getAddresses() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId) // Giả sử bảng có cột user_id
          .order('created_at', ascending: false); // Sắp xếp mới nhất

      return (response as List).map((e) => Address.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Thêm địa chỉ mới
  Future<void> addAddress(Address address) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not logged in");

    final data = address.toJson();
    data['user_id'] = userId; // Gán user_id
    data.remove('id'); // Xóa ID để DB tự sinh

    await _supabase.from(_tableName).insert(data);
  }

  // Cập nhật địa chỉ
  Future<void> updateAddress(Address address) async {
    if (address.id == null) return;
    await _supabase
        .from(_tableName)
        .update(address.toJson())
        .eq('id', address.id!);
  }

  // Xóa địa chỉ
  Future<void> deleteAddress(String id) async {
    await _supabase.from(_tableName).delete().eq('id', id);
  }
}