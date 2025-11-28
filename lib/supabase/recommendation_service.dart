import 'dart:convert';
import 'package:ecomerceapp/models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecommendationService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Products>> getSimilarProducts(String currentProductId) async {
    try {
      // 1. Lấy vector 384 chiều từ DB
      final currentProductRes = await _supabase
          .from('products')
          .select('embedding')
          .eq('id', currentProductId)
          .single();

      final dynamic embeddingRaw = currentProductRes['embedding'];
      if (embeddingRaw == null) return [];

      List<double> queryVector = [];

      // Parse vector từ string hoặc list
      if (embeddingRaw is String) {
        final List<dynamic> parsed = jsonDecode(embeddingRaw);
        queryVector = parsed.map((e) => (e as num).toDouble()).toList();
      } else if (embeddingRaw is List) {
        queryVector = embeddingRaw.map((e) => (e as num).toDouble()).toList();
      } else {
        return [];
      }

      // Kiểm tra kích thước vector (Debug)
      // print("Vector size: ${queryVector.length}"); // Phải là 384

      // 2. Gọi hàm RPC
      final response = await _supabase.rpc(
        'match_products',
        params: {
          'query_embedding': queryVector,
          'match_threshold': 0.1, // Hạ thấp xuống để dễ ra kết quả khi test
          'match_count': 6,
          'ignore_id': int.tryParse(currentProductId) ?? 0,
        },
      );

      if (response is List) {
        return response.map((e) => Products.fromSupabaseJson(e, e['id'].toString())).toList();
      }

      return [];
    } catch (e) {
      print("❌ Lỗi Recommendation Service: $e");
      return [];
    }
  }
}