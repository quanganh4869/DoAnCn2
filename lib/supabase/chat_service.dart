import 'package:ecomerceapp/models/product.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;

  // Lấy API Key từ file .env với tên biến là 'apiKey'
  static String get apiKey {
    final key = dotenv.env['apiKey'];
    if (key == null || key.isEmpty) {
      print("⚠️ LỖI: Chưa tìm thấy biến 'apiKey' trong file .env");
      return "";
    }
    return key;
  }

  late final GenerativeModel _model;
  late final ChatSession _chat;

  ChatService() {
    // Khởi tạo model với API Key lấy từ .env
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
      systemInstruction: Content.text("""
        Bạn là nhân viên tư vấn bán hàng nhiệt tình của ứng dụng E-commerce.
        Nhiệm vụ của bạn là trả lời câu hỏi của khách hàng dựa trên danh sách sản phẩm được cung cấp.
        - Nếu có sản phẩm phù hợp: Giới thiệu tên, giá và ưu điểm ngắn gọn.
        - Nếu không có: Xin lỗi và gợi ý họ xem danh mục khác.
        - Luôn trả lời ngắn gọn, thân thiện, xưng hô "mình" hoặc "shop".
        - Đừng bịa ra sản phẩm không có trong danh sách.
      """),
    );
    _chat = _model.startChat();
  }

  // Hàm xử lý tin nhắn
  Future<String?> sendMessage(String userMessage) async {
    if (apiKey.isEmpty) return "Lỗi cấu hình: Thiếu API Key trong .env";

    try {
      // 1. Tìm kiếm sản phẩm liên quan trong Database (Keyword Search)
      // (Dùng text search đơn giản để lấy bối cảnh)
      final products = await _searchRelatedProducts(userMessage);

      // 2. Tạo ngữ cảnh (Context) cho AI
      String contextData = "";
      if (products.isNotEmpty) {
        contextData = "Dữ liệu sản phẩm hiện có của shop:\n";
        for (var p in products) {
          contextData += "- ${p.name}: Giá ${p.price} VND. Tình trạng: ${p.stock > 0 ? 'Còn hàng' : 'Hết hàng'}.\n";
        }
      } else {
        contextData = "Hiện tại shop không tìm thấy sản phẩm nào khớp với từ khóa trong câu hỏi.";
      }

      // 3. Gửi cho Gemini
      final prompt = "$contextData\n\nKhách hàng hỏi: $userMessage";
      final response = await _chat.sendMessage(Content.text(prompt));

      return response.text;
    } catch (e) {
      print("Chat Error: $e");
      return "Xin lỗi, hệ thống đang bận. Bạn thử lại sau nhé!";
    }
  }

  // Hàm tìm kiếm sản phẩm (Full-text search đơn giản)
  Future<List<Products>> _searchRelatedProducts(String query) async {
    try {
      // Lấy các từ khóa chính từ câu hỏi (Ví dụ: "Laptop", "Giày", "Asus")
      // Sử dụng textSearch như code của bạn
      final response = await _supabase
          .from('products')
          .select('*, users(shop_name)')
          .textSearch('description', query, config: 'english') // Hoặc dùng ilike nếu textSearch không ra kết quả mong muốn
          .limit(5); // Chỉ lấy 5 sản phẩm liên quan nhất để tiết kiệm token

      final data = response as List<dynamic>;
      return data.map((e) => Products.fromSupabaseJson(e, e['id'].toString())).toList();
    } catch (e) {
      // print("Search Error: $e");
      return [];
    }
  }
}