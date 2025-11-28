import 'package:get/get.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:ecomerceapp/supabase/chat_service.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';

class ChatController extends GetxController {
  final ChatService _chatService = ChatService();
  final AuthController _authController = Get.find<AuthController>();

  var messages = <ChatMessage>[].obs;
  var isTyping = false.obs;

  late ChatUser currentUser;
  final ChatUser geminiBot = ChatUser(
    id: 'gemini',
    firstName: 'Trợ lý AI',
    profileImage: 'https://www.gstatic.com/lamda/images/gemini_sparkle_v002_d4735304ff6292a690345.svg',
  );

  @override
  void onInit() {
    super.onInit();
    final profile = _authController.userProfile;
    currentUser = ChatUser(
      id: profile?.id ?? 'user',
      firstName: profile?.fullName ?? 'Bạn',
      profileImage: profile?.userImage,
    );

    messages.add(
      ChatMessage(
        text: "Xin chào! Mình là trợ lý ảo. Bạn cần tìm sản phẩm gì hôm nay?",
        user: geminiBot,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> handleSendMessage(ChatMessage m) async {
    // 1. Hiển thị tin nhắn người dùng ngay lập tức
    messages.insert(0, m);
    isTyping.value = true;

    // 2. Gọi AI xử lý
    final responseText = await _chatService.sendMessage(m.text);

    // 3. Hiển thị tin nhắn trả lời của Bot
    if (responseText != null) {
      final botMessage = ChatMessage(
        text: responseText,
        user: geminiBot,
        createdAt: DateTime.now(),
      );
      messages.insert(0, botMessage);
    }

    isTyping.value = false;
  }
}