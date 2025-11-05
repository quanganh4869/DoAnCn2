import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:get_storage/get_storage.dart';
class ThemeController extends GetxController {
  final _box = GetStorage();

  final _key = 'isDarkMode';

  ThemeMode get theme =>
      _loadTheme() ? ThemeMode.dark : ThemeMode.light;
      bool get isDarkMode => _loadTheme();

  bool _loadTheme() => _box.read(_key) ?? false;
  
  void saveTheme(bool isDarkMode) => _box.write(_key, isDarkMode);

  void toggleTheme() {
    Get.changeThemeMode(_loadTheme() ? ThemeMode.light : ThemeMode.dark);
    saveTheme(!_loadTheme());
    update();
  }
}