import 'package:flutter/material.dart';
import 'package:ecomerceapp/admin_dashboard/view/admin_dasboard.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text(
          "Setting"
        ),
      ),
    );
  }
}