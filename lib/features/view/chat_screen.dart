import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:ecomerceapp/controller/chat_controller.dart';

class AIChatScreen extends StatelessWidget {
  AIChatScreen({super.key});

  final ChatController controller = Get.put(ChatController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.blue),
            SizedBox(width: 8),
            Text("Trợ lý mua sắm AI"),
          ],
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        return DashChat(
          currentUser: controller.currentUser,
          onSend: (ChatMessage m) => controller.handleSendMessage(m),
          messages: controller.messages.toList(),
          typingUsers: controller.isTyping.value ? [controller.geminiBot] : [],
          inputOptions: const InputOptions(
            inputDecoration: InputDecoration(
              hintText: "Hỏi về sản phẩm...",
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
          messageOptions: const MessageOptions(
            showOtherUsersAvatar: true,
            showTime: true,
            containerColor: Colors.blueAccent,
            currentUserContainerColor: Colors.black87,
          ),
        );
      }),
    );
  }
}