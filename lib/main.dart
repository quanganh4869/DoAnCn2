import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ecomerceapp/utils/app_themes.dart';
import 'package:ecomerceapp/supabase/connect.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ecomerceapp/controller/cart_controller.dart';
import 'package:ecomerceapp/utils/supabase_data_seeder.dart';
import 'package:ecomerceapp/controller/auth_controller.dart';
import 'package:ecomerceapp/features/view/splash_screen.dart';
import 'package:ecomerceapp/controller/theme_controller.dart';
import 'package:ecomerceapp/controller/product_controller.dart';
import 'package:ecomerceapp/controller/wishlist_controller.dart';
import 'package:ecomerceapp/controller/category_controller.dart';
import 'package:ecomerceapp/controller/navigation_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseService().init();

  Get.put(ThemeController());
  Get.put(AuthController());
  Get.put(NavigationController());
  Get.put(ProductController());
  Get.put(CategoryController());
  Get.put(WishlistController());
  Get.put(CartController());
  await SupabaseDataSeeder.seedAllData();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    return GetMaterialApp(
      title: 'Ecommerce App',
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: themeController.theme,
      defaultTransition: Transition.fade,
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
