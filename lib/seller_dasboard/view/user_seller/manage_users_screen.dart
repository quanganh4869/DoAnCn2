import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (ctx, i) => const Divider(),
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, color: Colors.grey[600]),
          ),
          title: Text("Customer Name $index", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("customer$index@email.com"),
          trailing: IconButton(
            icon: const Icon(Icons.message_outlined, color: Colors.blue),
            onPressed: () {
              // Mở chat với khách hàng
            },
          ),
        );
      },
    );
  }
}