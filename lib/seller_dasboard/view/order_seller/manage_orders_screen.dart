import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_textstyles.dart';

class ManageOrdersScreen extends StatelessWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> orders = [
      {'id': 'ORD-001', 'total': 45.50, 'status': 'Active', 'user': 'Nguyen Van A'},
      {'id': 'ORD-002', 'total': 120.00, 'status': 'Completed', 'user': 'Tran Thi B'},
      {'id': 'ORD-003', 'total': 32.00, 'status': 'Active', 'user': 'Le Van C'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isCompleted = order['status'] == 'Completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order['status'],
                      style: TextStyle(
                        color: isCompleted ? Colors.green : Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("Customer: ${order['user']}"),
              const SizedBox(height: 4),
              Text("Total: \$${order['total']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isCompleted)
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text("Mark as Completed"),
                    ),
                   if (!isCompleted) const SizedBox(width: 8),
                   OutlinedButton(
                    onPressed: () {},
                    child: const Text("Details"),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}