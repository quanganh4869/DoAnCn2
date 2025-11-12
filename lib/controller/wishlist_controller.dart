// import 'package:get/get.dart';
// import 'package:get/get_rx/get_rx.dart';
// import 'package:ecomerceapp/models/product.dart';
// import 'package:ecomerceapp/models/wishlist.dart';
// import 'package:ecomerceapp/controller/auth_controller.dart';
// import 'package:ecomerceapp/supabase/wishlist_supabase_service.dart';

// class WishlistController {
//   final RxList<Wishlist> _wishListItems = <Wishlist>[].obs;
//   final RxBool _isLoading = false.obs;
//   final RxBool _hasError = false.obs;
//   final RxString _errorMessage = "".obs;
//   final RxString _itemcount = "".obs;

//   // Lấy id user
//   String? get _userId {
//     final authController = Get.find<AuthController>();
//     return authController.user?.uid;
//   }

//   List<Wishlist> get Wishlist => _wishListItems;
//   bool get isLoading => _isLoading.value;
//   bool get hasError => _hasError.value;
//   String get errorMessage => _errorMessage.value;
//   int get itemCount => _itemcount.value;
//   bool get isEmpty => _wishListItems.isEmpty;


//   @override
//   void onInit(){
//     super.onInit();
//     loadWishListItems();
//     _listenToAuthChanges();
//   }
//   void _listenToAuthChanges(){
//     final authController = Get.find<AuthController>();
//     ever(authController.isLoggedIn.obs,(bool isLoggedIn){
//         if(isLoggedIn){
//           loadWishListItems();
//         }else{
//           _wishListItems.clear();
//           _itemcount.value = 0;
//           update();
//         }
//     });
//   }
//   Future<void> loadWishListItems()async{
//     _isLoading.value = true;
//     _hasError.value = false;

//     try {
//       final userId = _userId;
//       if (userId == null){
//         _wishListItems.clear();
//         _itemcount.value = 0;
//         _hasError.value= true;
//         _errorMessage.value = "Please sign in to view your wishlish";
//         return;
//       }
//       final items = await WishlistSupabaseService.getUserWishlist(userId);
//       _wishListItems.value = items;
//       _itemcount.value = items.length;
//       update();
//     } catch (e) {
//       _hasError.value = true;
//       _errorMessage.value ="Failed to load wishlist items. Please try again. ";
//       print("Error loading wishlist items: $e");
//     }finally{
//       _isLoading.value = false;
//     }
//   }
//   Future<bool> addToWishlist(Products product)async{
//     try {
//       final userId = _userId;
//       if(userId == null){
//         Get.snackbar("Authentication requied",
//                      "Please sign in to add items to your wishList",
//                      snackPosition: SnackPosition.BOTTOM,
//                      duration: const Duration(seconds: 2),
//         );
//         return false;
//       }
//     } catch (e) {
//       final success = await WishlistSupabaseService.addToWishlist(userId: userId, product: product);
//       if(success){
//         await loadWishListItems();
//         update();
//         Get.snackbar("Added to WishList",
//                      "P${product.name} added to your wishlist",
//                      snackPosition: SnackPosition.BOTTOM,
//                      duration: const Duration(seconds: 2),
//         );
//       }else{
//         Get.snackbar("Error",
//                      "Failed to add item to wishlist",
//                      snackPosition: SnackPosition.BOTTOM,
//                      duration: const Duration(seconds: 2),
//         );
//       }
//       return success;
//     }catch(e){
//       print("Error adding to wishlist: $e");
//       Get.snackbar("Error",
//                      "Failed to add item to wishlist",
//                      snackPosition: SnackPosition.BOTTOM,
//                      duration: const Duration(seconds: 2),
//         );
//         return false;
//     }
//   }
// }
